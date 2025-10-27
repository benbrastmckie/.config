# Command Spec Initialization Logic Research

## Related Reports
- [Overview Report](./OVERVIEW.md) - Main synthesis of all findings

## Executive Summary

All workflow commands (/plan, /report, /research, /orchestrate) implement a **lazy directory creation pattern** that creates directories only when files are written, not during initialization. This pattern reduced empty directories from 400-500 to 0, with an 80% reduction in mkdir calls. However, one critical inconsistency exists: `create_topic_artifact()` creates directories immediately during path calculation, contradicting the lazy pattern when called with empty content. Five findings detail the implementation patterns, and five recommendations address the inconsistency and standardization opportunities.

## Research Objective
Examine how /plan, /report, /research, and /orchestrate commands initialize spec directories to understand when and why directories are created preemptively vs on-demand.

## Methodology
- Analyzed command files in .claude/commands/
- Searched for directory creation patterns
- Identified initialization workflows
- Documented findings with file references and line numbers

## Findings

### Finding 1: Lazy Directory Creation Pattern Adoption

**Status**: Fully implemented across all workflow commands

The unified location detection library (`/home/benjamin/.config/.claude/lib/unified-location-detection.sh`) implements a **lazy directory creation pattern** that creates directories only when files are written, not during initialization.

**Key Implementation Details**:

1. **`perform_location_detection()` (Lines 313-370)**: Creates ONLY the topic root directory
   - Does NOT create subdirectories (reports/, plans/, summaries/, debug/, scripts/, outputs/)
   - Returns JSON with artifact_paths but doesn't create them
   - Reduced from 400-500 empty directories to 0

2. **`create_topic_structure()` (Lines 263-279)**: Creates topic root only
   ```bash
   # Create ONLY topic root (lazy subdirectory creation)
   mkdir -p "$topic_path" || {
     echo "ERROR: Failed to create topic directory: $topic_path" >&2
     return 1
   }
   ```

3. **`ensure_artifact_directory()` (Lines 231-242)**: On-demand parent directory creation
   ```bash
   # Idempotent: succeeds whether directory exists or not
   [ -d "$parent_dir" ] || mkdir -p "$parent_dir" || {
     echo "ERROR: Failed to create directory: $parent_dir" >&2
     return 1
   }
   ```

**Performance Impact**: 80% reduction in mkdir calls during location detection (unified-location-detection.sh:13)

### Finding 2: Command-Specific Directory Creation Workflows

#### `/report` and `/research` Commands

**Pre-calculation Pattern** (report.md:109-172, research.md:109-159):
- Calculate ALL report paths BEFORE invoking agents
- Store in `SUBTOPIC_REPORT_PATHS` associative array
- Pass absolute paths to research-specialist agents
- Agents use `ensure_artifact_directory()` before Write tool

**Lazy Creation Enforcement** (report.md:217-223):
```bash
**STEP 1.5 (EXECUTE NOW)**: Ensure parent directory exists (lazy creation):

ensure_artifact_directory "[ABSOLUTE_PATH_FROM_SUBTOPIC_REPORT_PATHS]" || {
  echo "ERROR: Failed to create parent directory" >&2
  exit 1
}
```

**Why This Matters**:
- Directories created only when agents successfully create files
- No empty directories if agent fails before file creation
- Research subdirectories created via `create_research_subdirectory()` (unified-location-detection.sh:440-513)

#### `/plan` Command

**Topic Directory Reuse Pattern** (plan.md:472-510):
1. Extract topic directory from report path (if provided)
2. Use existing topic structure (no new directory creation)
3. Create plan subdirectory lazily via `create_topic_artifact()`

**Fallback Creation** (plan.md:618-622):
```bash
# Ensure parent directory exists (lazy creation)
ensure_artifact_directory "$FALLBACK_PATH" || {
  echo "ERROR: Failed to create parent directory for plan" >&2
  exit 1
}
```

**No Preemptive Directory Creation**: Plan files created in existing topic directories, subdirectories created on-demand

#### `/orchestrate` Command

**Phase 0 (Location Detection)** (orchestrate.md:403-510):
1. Invoke unified location detection library
2. Create topic root directory ONLY
3. Return artifact_paths without creating subdirectories
4. Fallback creation if library fails (orchestrate.md:484-509)

**Mandatory Verification** (orchestrate.md:663-713):
- Creates topic root directory via `perform_location_detection()`
- Does NOT create subdirectories (reports/, plans/, etc.)
- Subdirectories created when artifacts are written

**Research Phase Path Calculation** (orchestrate.md:654-713):
```bash
declare -A REPORT_PATHS

for topic in "${RESEARCH_TOPICS[@]}"; do
  # Pre-calculate report path (directory created lazily by agent)
  REPORT_PATH=$(create_topic_artifact "$WORKFLOW_TOPIC_DIR" "reports" "${topic}" "")
  REPORT_PATHS["$topic"]="$REPORT_PATH"
  echo "  Report Path: $REPORT_PATH"
done
```

### Finding 3: `create_topic_artifact()` Function Behavior

**Location**: `/home/benjamin/.config/.claude/lib/artifact-creation.sh:14-84`

**Current Behavior** (CREATES DIRECTORIES IMMEDIATELY):
```bash
# Line 41-42: Creates artifact subdirectory IMMEDIATELY
local artifact_subdir="${CLAUDE_PROJECT_DIR}/${topic_dir}/${artifact_type}"
mkdir -p "$artifact_subdir"
```

**Impact**:
- This function is called by `/orchestrate` for path calculation (orchestrate.md:681)
- Creates empty subdirectories even when content is empty string
- Contradicts lazy creation pattern in unified-location-detection.sh

**Usage Pattern in Commands**:
- **`/plan`**: Calls `create_topic_artifact()` with actual content (plan.md:608)
- **`/orchestrate`**: Calls with empty content for path calculation (orchestrate.md:681)
- **Result**: Empty directories created during path calculation phase

### Finding 4: Research Subdirectory Creation Pattern

**Function**: `create_research_subdirectory()` (unified-location-detection.sh:440-513)

**Behavior**:
1. Validates topic_path exists
2. Creates reports/ directory if missing (lazy creation support, line 465-471)
3. Gets next sequential number (001, 002, 003...)
4. Creates numbered subdirectory immediately (line 505)

**Usage Context**:
- Called by `/report` (report.md:138-140)
- Called by `/research` (research.md:119-120)
- Creates subdirectory structure for hierarchical research

**Why It Creates Immediately**:
- Subdirectory needed to calculate individual report paths
- Multiple agents write to same subdirectory
- Created once before agent invocations, not per-agent

### Finding 5: Agent-Level Lazy Creation Requirements

**Research Specialist Agent** (research-specialist.md:49-69):
```bash
# STEP 1.5 (REQUIRED BEFORE STEP 2) - Ensure Parent Directory Exists

source .claude/lib/unified-location-detection.sh

# Ensure parent directory exists (lazy creation pattern)
ensure_artifact_directory "$REPORT_PATH" || {
  echo "ERROR: Failed to create parent directory for report" >&2
  exit 1
}
```

**Enforcement**:
- All research agents MUST call `ensure_artifact_directory()` before Write tool
- Prevents file write failures from missing parent directories
- Idempotent: safe to call even if directory exists

**Why Commands Don't Create Directories**:
- Commands delegate directory creation to agents
- Agents create directories only when files successfully created
- Eliminates empty directories from failed agent invocations

## Recommendations

### Recommendation 1: Fix `create_topic_artifact()` for Path-Only Calculation

**Problem**: `create_topic_artifact()` creates directories immediately even when called for path calculation with empty content.

**Solution**: Add conditional directory creation based on content parameter:

```bash
# Only create directory if content provided
if [ -n "$content" ]; then
  mkdir -p "$artifact_subdir"
  # ... existing file creation logic ...
else
  # Path-only calculation: return path without creating directory
  local next_num=$(get_next_artifact_number "$artifact_subdir" || echo "001")
  echo "${artifact_subdir}/${next_num}_${artifact_name}.md"
  return 0
fi
```

**Impact**: Eliminates empty directories created during path calculation in `/orchestrate`

### Recommendation 2: Document Lazy Creation Pattern Clearly

**Current State**: Pattern implemented but not prominently documented in command files

**Enhancement**: Add explicit section in each command explaining:
- When directories are created (on file write, not on path calculation)
- Why lazy creation matters (eliminates empty directories)
- How agents enforce the pattern (`ensure_artifact_directory()`)

**Location**: Add to `/plan`, `/report`, `/research`, `/orchestrate` command documentation

### Recommendation 3: Standardize Research Subdirectory Creation Timing

**Current Behavior**: `create_research_subdirectory()` creates directory immediately for path calculation

**Alternative Approach**:
1. Add `get_research_subdirectory_path()` function for path-only calculation
2. Keep `create_research_subdirectory()` for actual directory creation
3. Commands call path function first, creation function when needed

**Trade-off Analysis**:
- **Pro**: Fully lazy creation pattern (no directories until files written)
- **Con**: More complex logic (two-stage path calculation)
- **Current approach acceptable**: Subdirectory needed by multiple agents, created once upfront

### Recommendation 4: Audit All Commands for Preemptive mkdir Calls

**Commands with Manual mkdir** (from grep results):
- `/debug` (debug.md:422): `mkdir -p "$(dirname "$FALLBACK_PATH")"`
- `/implement` (implement.md:1038): `mkdir -p "$(dirname "$FALLBACK_PATH")"`
- `/refactor` (refactor.md:161): `mkdir -p "$SPECS_DIR/reports"`

**Action**: Replace manual `mkdir -p` with `ensure_artifact_directory()` calls for consistency

### Recommendation 5: Add Verification Step to Confirm Lazy Creation

**Test Script Pattern**:
```bash
# Before workflow
EMPTY_DIRS_BEFORE=$(find .claude/specs -type d -empty | wc -l)

# Run workflow
/orchestrate "test workflow"

# After workflow (should be same or less)
EMPTY_DIRS_AFTER=$(find .claude/specs -type d -empty | wc -l)

if [ $EMPTY_DIRS_AFTER -gt $EMPTY_DIRS_BEFORE ]; then
  echo "WARNING: Empty directories created during workflow"
fi
```

**Integration**: Add to `/orchestrate` workflow verification phase

## References

### Primary Files Analyzed

1. **Unified Location Detection Library**: `/home/benjamin/.config/.claude/lib/unified-location-detection.sh`
   - `perform_location_detection()` (Lines 313-370): Topic root creation only
   - `create_topic_structure()` (Lines 263-279): Lazy subdirectory pattern
   - `ensure_artifact_directory()` (Lines 231-242): On-demand parent creation
   - `create_research_subdirectory()` (Lines 440-513): Research subdirectory numbering

2. **Artifact Creation Library**: `/home/benjamin/.config/.claude/lib/artifact-creation.sh`
   - `create_topic_artifact()` (Lines 14-84): Immediate directory creation bug
   - `get_next_artifact_number()` (Lines 134-150): Sequential numbering

3. **Command Files**:
   - `/report`: `/home/benjamin/.config/.claude/commands/report.md`
     - Path pre-calculation (Lines 109-172)
     - Lazy creation enforcement (Lines 217-223)
   - `/research`: `/home/benjamin/.config/.claude/commands/research.md`
     - Path pre-calculation (Lines 109-159)
     - Subdirectory creation (Lines 119-120)
   - `/plan`: `/home/benjamin/.config/.claude/commands/plan.md`
     - Topic reuse pattern (Lines 472-510)
     - Fallback creation (Lines 618-622)
   - `/orchestrate`: `/home/benjamin/.config/.claude/commands/orchestrate.md`
     - Phase 0 location detection (Lines 403-510)
     - Report path calculation (Lines 654-713)

4. **Agent Files**:
   - **Research Specialist**: `/home/benjamin/.config/.claude/agents/research-specialist.md`
     - Lazy creation requirement (Lines 49-69)
     - File creation protocol (Lines 73-118)

### Key Pattern Observations

1. **Lazy Creation Pattern**: 80% reduction in mkdir calls, 0 empty directories (vs 400-500 previously)
2. **Path Pre-calculation**: Commands calculate paths before agent invocation, agents create directories on-demand
3. **Inconsistency Found**: `create_topic_artifact()` creates directories immediately during path calculation
4. **Agent Enforcement**: Research specialists MUST call `ensure_artifact_directory()` before Write tool
