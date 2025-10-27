# Path Resolution Simplification Strategies for /research Command

## Metadata
- **Date**: 2025-10-23
- **Agent**: research-specialist
- **Topic**: Path resolution simplification strategies
- **Report Type**: Codebase analysis and architectural recommendation

## Executive Summary

The /research command currently uses complex inline bash scripts (50+ lines in STEP 2) to calculate topic directories and subtopic report paths. Analysis reveals three primary simplification strategies: (1) extracting path calculation to a unified library function, (2) consolidating pattern from orchestrate.md, and (3) using behavioral injection with skill-based delegation. The most maintainable approach is Strategy 1 (unified library function) which reduces command file complexity by 70% while maintaining execution clarity and follows established architectural patterns from artifact-creation.sh.

## Current State Analysis

### Existing Path Resolution Pattern (Lines 77-154)

The /research command implements path resolution through a multi-step inline bash sequence:

**File**: `/home/benjamin/.config/.claude/commands/research.md` (Lines 77-154)

**Current Implementation**:
```bash
# Step 1: Get or Create Main Topic Directory
TOPIC_DESC=$(extract_topic_from_question "$RESEARCH_TOPIC")
EXISTING_TOPIC=$(find_matching_topic "$TOPIC_DESC")

if [ -n "$EXISTING_TOPIC" ]; then
  TOPIC_DIR="$EXISTING_TOPIC"
else
  TOPIC_DIR=$(get_or_create_topic_dir "$TOPIC_DESC" ".claude/specs")
fi

# Step 2: Calculate Subtopic Report Paths
declare -A SUBTOPIC_REPORT_PATHS
RESEARCH_SUBDIR="${TOPIC_DIR}/reports/$(printf "%03d" $(get_next_artifact_number "${TOPIC_DIR}/reports"))_research"
mkdir -p "$RESEARCH_SUBDIR"

for subtopic in "${SUBTOPICS[@]}"; do
  NEXT_NUM=$(get_next_artifact_number "$RESEARCH_SUBDIR")
  REPORT_PATH="${RESEARCH_SUBDIR}/$(printf "%03d" "$NEXT_NUM")_${subtopic}.md"
  SUBTOPIC_REPORT_PATHS["$subtopic"]="$REPORT_PATH"
  echo "  Subtopic: $subtopic"
  echo "  Path: $REPORT_PATH"
done
```

**Complexity Metrics**:
- Total lines: 78 lines (including verification)
- Bash code blocks: 3 separate blocks
- Functions called: 4 utility functions
- Manual validation: 15 lines of path verification
- Error handling: Embedded in inline code

### Utility Functions Already Available

**File**: `/home/benjamin/.config/.claude/lib/artifact-creation.sh`

Analysis reveals these existing utilities (lines 14-157):

1. **`create_topic_artifact()`** (Lines 14-84)
   - Creates numbered artifacts in topic subdirectories
   - Handles artifact numbering automatically
   - Validates artifact types
   - Supports: debug, scripts, outputs, artifacts, backups, reports, plans

2. **`get_next_artifact_number()`** (Lines 134-157)
   - Finds highest existing NNN_ number
   - Returns zero-padded next number (001, 002, 003...)
   - Handles edge cases (empty directory, leading zeros)

3. **Pattern NOT implemented**: Hierarchical research subdirectory creation
   - Current utilities assume flat structure: `topic/reports/NNN_report.md`
   - /research needs nested structure: `topic/reports/NNN_research/001_subtopic.md`

### Similar Patterns in Other Commands

**Orchestrate Command** (Lines 701-750):

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"

# Simple topic directory creation
TOPIC_DIR=$(get_or_create_topic_dir "$WORKFLOW_DESC" ".claude/specs")

# Direct path calculation for flat reports
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "pattern_analysis" "")
```

**Key Differences from /research**:
- /orchestrate creates flat report structure (one level)
- /research creates hierarchical structure (subdirectory with multiple subtopic reports)
- /orchestrate passes empty content ("") to pre-create paths
- /research needs to calculate paths before agent invocation

**Plan Command** (Similar pattern, simpler):

Uses same `get_or_create_topic_dir()` pattern but creates single plan file, not multiple reports.

## Findings

### Strategy 1: Unified Library Function

**Approach**: Extract path calculation logic to `.claude/lib/research-path-utils.sh`

**Proposed Function Signature**:
```bash
calculate_research_paths() {
  local research_topic="$1"
  local subtopics_array_name="$2"  # Name of array variable (e.g., "SUBTOPICS")

  # Returns JSON structure:
  # {
  #   "topic_dir": "/absolute/path/to/.claude/specs/042_topic",
  #   "research_subdir": "/absolute/path/to/.claude/specs/042_topic/reports/001_research",
  #   "subtopic_paths": {
  #     "subtopic_1": "/absolute/.../001_subtopic_1.md",
  #     "subtopic_2": "/absolute/.../002_subtopic_2.md"
  #   }
  # }
}
```

**Usage in /research Command** (Simplified to ~15 lines):
```bash
# STEP 2: Calculate all paths
source "${CLAUDE_PROJECT_DIR}/.claude/lib/research-path-utils.sh"

RESEARCH_PATHS=$(calculate_research_paths "$RESEARCH_TOPIC" "SUBTOPICS")

TOPIC_DIR=$(echo "$RESEARCH_PATHS" | jq -r '.topic_dir')
RESEARCH_SUBDIR=$(echo "$RESEARCH_PATHS" | jq -r '.research_subdir')

# Extract subtopic paths into associative array
declare -A SUBTOPIC_REPORT_PATHS
while IFS= read -r subtopic; do
  SUBTOPIC_REPORT_PATHS["$subtopic"]=$(echo "$RESEARCH_PATHS" | jq -r ".subtopic_paths[\"$subtopic\"]")
done < <(echo "$RESEARCH_PATHS" | jq -r '.subtopic_paths | keys[]')

echo "✓ Calculated paths for ${#SUBTOPIC_REPORT_PATHS[@]} subtopics"
```

**Pros**:
- ✅ Reduces command file from 78 lines to ~15 lines (80% reduction)
- ✅ Centralizes path logic for reuse across commands
- ✅ Maintains testability (function can be unit tested)
- ✅ Follows established pattern (artifact-creation.sh provides similar utilities)
- ✅ Preserves command file execution clarity (source + single function call)
- ✅ Aligns with Command Architecture Standards (Standard 1: execution instructions inline, complex calculations in library)

**Cons**:
- ⚠️ Adds dependency on external function (but mitigated by inline fallback option)
- ⚠️ Requires jq for JSON parsing (already used extensively in codebase)
- ⚠️ New utility file to maintain (but reduces duplication if pattern used elsewhere)

**Alignment with Standards**:

From `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` (Lines 1148-1149):

> **✅ Safe to Extract** (Move to reference files):
> 8. **Parsing patterns**: Regex patterns, jq queries, grep commands

Path calculation qualifies as "parsing pattern" - it's a complex bash calculation that can be extracted to library without violating execution-critical requirements. The command file retains the execution steps (source library, call function, verify results).

### Strategy 2: Inline Consolidation (Pattern Reuse)

**Approach**: Keep logic inline but consolidate with orchestrate.md pattern

**Proposed Simplification**:
```bash
# STEP 2: Calculate paths (consolidated pattern)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"

TOPIC_DIR=$(get_or_create_topic_dir "$RESEARCH_TOPIC" ".claude/specs")
RESEARCH_SUBDIR="${TOPIC_DIR}/reports/$(printf "%03d" $(get_next_artifact_number "${TOPIC_DIR}/reports"))_research"
mkdir -p "$RESEARCH_SUBDIR"

declare -A SUBTOPIC_REPORT_PATHS
for subtopic in "${SUBTOPICS[@]}"; do
  SUBTOPIC_REPORT_PATHS["$subtopic"]=$(create_topic_artifact "$RESEARCH_SUBDIR" "." "$subtopic" "")
done

echo "✓ Calculated ${#SUBTOPIC_REPORT_PATHS[@]} report paths in $RESEARCH_SUBDIR"
```

**Key Changes**:
- Uses `create_topic_artifact()` instead of manual path construction
- Passes `"."` as artifact_type for flat subdirectory structure
- Eliminates manual `get_next_artifact_number()` loop
- Removes explicit verification (function handles it)

**Pros**:
- ✅ Reduces from 78 lines to ~12 lines (85% reduction)
- ✅ No new dependencies (uses existing artifact-creation.sh)
- ✅ Maintains execution clarity (all logic visible inline)
- ✅ Reuses proven pattern from orchestrate.md

**Cons**:
- ⚠️ Requires modifying `create_topic_artifact()` to support "." as artifact_type
- ⚠️ Less explicit than current implementation (some magic in artifact-creation.sh)
- ⚠️ May not handle hierarchical subdirectory case correctly without modification

**Modification Required**:

`artifact-creation.sh` (Lines 30-38) currently validates artifact types against whitelist:
```bash
case "$artifact_type" in
  debug|scripts|outputs|artifacts|backups|data|logs|notes|reports|plans)
    ;;
  *)
    echo "Error: Invalid artifact type '$artifact_type'" >&2
    return 1
    ;;
esac
```

Would need to add special case for "." (current directory) or create new function variant.

### Strategy 3: Skill-Based Delegation

**Approach**: Create path-calculator skill that encapsulates logic

**NOT RECOMMENDED** based on codebase analysis.

**Reasoning**:
- Skills (`.claude/skills/`) not found in current directory structure
- No evidence of skill system in CLAUDE.md or command files
- Grep for "skill" pattern (excluding "Skills" heading) found no skill invocation patterns
- Would introduce architectural complexity not justified by 78-line simplification

**Conclusion**: Strategy 3 dismissed - no skill system infrastructure exists.

### Strategy 4: Behavioral Injection with Subagent

**Approach**: Delegate path calculation to specialized subagent

**Implementation**:
```bash
# STEP 2: Delegate path calculation to path-calculator agent
Task {
  subagent_type: "general-purpose"
  description: "Calculate research artifact paths"
  prompt: |
    Calculate absolute paths for hierarchical research structure.

    Research Topic: $RESEARCH_TOPIC
    Subtopics: ${SUBTOPICS[@]}

    Return JSON:
    {
      "topic_dir": "/absolute/path",
      "research_subdir": "/absolute/path",
      "subtopic_paths": { "subtopic_1": "/path", ... }
    }
}

# Extract results from agent output
RESEARCH_PATHS=$(extract_json_from_agent_output "$AGENT_OUTPUT")
```

**Pros**:
- ✅ Completely removes path logic from command file
- ✅ Agent can handle edge cases with LLM reasoning
- ✅ Follows behavioral injection pattern

**Cons**:
- ❌ Massive overkill for deterministic calculation (no LLM reasoning needed)
- ❌ Adds agent invocation overhead (300-1000ms)
- ❌ Increases context usage unnecessarily
- ❌ Path calculation is deterministic, not requiring LLM capabilities
- ❌ Violates principle: use agents for research/analysis, not for math

**Alignment with Standards**:

From command_architecture_standards.md (Lines 324-418, Phase 0 requirements):

> **Orchestrator Role** (coordinates workflow):
> - Pre-calculates all artifact paths (topic-based organization)
> - Invokes specialized subagents via Task tool (NOT SlashCommand)

Path calculation is ORCHESTRATOR responsibility, not subagent task. Delegating to agent violates role separation.

**Conclusion**: Strategy 4 dismissed - inappropriate use of behavioral injection.

## Recommendations

### Recommendation 1: Implement Strategy 1 (Unified Library Function) - PRIMARY

**Implementation Steps**:

1. **Create new utility file**: `.claude/lib/research-path-utils.sh`

   ```bash
   #!/usr/bin/env bash
   # Research Path Utilities
   # Provides hierarchical path resolution for /research command

   set -euo pipefail

   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   source "${SCRIPT_DIR}/artifact-creation.sh"

   calculate_research_paths() {
     local research_topic="$1"
     local -n subtopics_ref="$2"  # nameref to array

     # Get or create topic directory
     local topic_desc=$(extract_topic_from_question "$research_topic")
     local existing_topic=$(find_matching_topic "$topic_desc" 2>/dev/null || true)

     local topic_dir
     if [ -n "$existing_topic" ]; then
       topic_dir="$existing_topic"
     else
       topic_dir=$(get_or_create_topic_dir "$topic_desc" ".claude/specs")
     fi

     # Create research subdirectory
     local next_research_num=$(get_next_artifact_number "${topic_dir}/reports")
     local research_subdir="${topic_dir}/reports/$(printf "%03d" "$next_research_num")_research"
     mkdir -p "$research_subdir"

     # Calculate subtopic paths
     local subtopic_paths_json="{"
     local first=true
     for subtopic in "${subtopics_ref[@]}"; do
       local next_num=$(get_next_artifact_number "$research_subdir")
       local report_path="${research_subdir}/$(printf "%03d" "$next_num")_${subtopic}.md"

       [ "$first" = false ] && subtopic_paths_json+=","
       subtopic_paths_json+="\"$subtopic\":\"$report_path\""
       first=false
     done
     subtopic_paths_json+="}"

     # Return JSON structure
     jq -n \
       --arg topic_dir "$topic_dir" \
       --arg research_subdir "$research_subdir" \
       --argjson subtopic_paths "$subtopic_paths_json" \
       '{topic_dir: $topic_dir, research_subdir: $research_subdir, subtopic_paths: $subtopic_paths}'
   }

   export -f calculate_research_paths
   ```

2. **Update /research command** (Lines 77-154 replacement):

   ```markdown
   ### STEP 2 (REQUIRED BEFORE STEP 3) - Path Pre-Calculation

   **EXECUTE NOW - Calculate Absolute Paths for All Subtopic Reports**

   ```bash
   source "${CLAUDE_PROJECT_DIR}/.claude/lib/research-path-utils.sh"

   # Calculate all paths in single function call
   RESEARCH_PATHS=$(calculate_research_paths "$RESEARCH_TOPIC" "SUBTOPICS")

   # Extract results
   TOPIC_DIR=$(echo "$RESEARCH_PATHS" | jq -r '.topic_dir')
   RESEARCH_SUBDIR=$(echo "$RESEARCH_PATHS" | jq -r '.research_subdir')

   # Populate subtopic paths associative array
   declare -A SUBTOPIC_REPORT_PATHS
   while IFS= read -r subtopic; do
     SUBTOPIC_REPORT_PATHS["$subtopic"]=$(echo "$RESEARCH_PATHS" | jq -r ".subtopic_paths[\"$subtopic\"]")
   done < <(echo "$RESEARCH_PATHS" | jq -r '.subtopic_paths | keys[]')

   echo "Main topic directory: $TOPIC_DIR"
   echo "Research subdirectory: $RESEARCH_SUBDIR"
   echo "✓ Calculated paths for ${#SUBTOPIC_REPORT_PATHS[@]} subtopics"
   ```

   **MANDATORY VERIFICATION - Path Pre-Calculation Complete**:

   ```bash
   # Verify all paths are absolute
   for subtopic in "${!SUBTOPIC_REPORT_PATHS[@]}"; do
     if [[ ! "${SUBTOPIC_REPORT_PATHS[$subtopic]}" =~ ^/ ]]; then
       echo "CRITICAL ERROR: Path for '$subtopic' is not absolute"
       exit 1
     fi
   done

   echo "✓ VERIFIED: All paths are absolute"
   echo "✓ VERIFIED: ${#SUBTOPIC_REPORT_PATHS[@]} report paths calculated"
   ```
   ```

3. **Add unit tests**: `.claude/tests/test_research_path_utils.sh`

   ```bash
   #!/usr/bin/env bash
   # Test research path utilities

   source .claude/lib/research-path-utils.sh

   test_calculate_research_paths() {
     SUBTOPICS=("jwt_patterns" "oauth_flows" "session_mgmt")

     RESULT=$(calculate_research_paths "Authentication patterns" "SUBTOPICS")

     # Verify JSON structure
     echo "$RESULT" | jq -e '.topic_dir' >/dev/null || fail "Missing topic_dir"
     echo "$RESULT" | jq -e '.research_subdir' >/dev/null || fail "Missing research_subdir"
     echo "$RESULT" | jq -e '.subtopic_paths.jwt_patterns' >/dev/null || fail "Missing subtopic path"

     echo "✓ calculate_research_paths returns valid JSON"
   }

   run_tests
   ```

**Estimated Impact**:
- Command file size reduction: 78 lines → 25 lines (68% reduction)
- Maintainability improvement: Path logic centralized, single source of truth
- Reusability: Function available for future hierarchical research patterns
- Testing: Path calculation logic unit-testable in isolation

**Rationale**:
- Follows established codebase pattern (artifact-creation.sh provides similar utilities)
- Maintains command file execution clarity (visible source + function call)
- Complies with Command Architecture Standards (calculation logic extraction permitted)
- Reduces duplication if /orchestrate or /plan adopt hierarchical research pattern

### Recommendation 2: Add Inline Fallback for Robustness - SECONDARY

Even with Strategy 1 implementation, add inline fallback for cases where library unavailable:

```bash
# STEP 2: Calculate paths (with fallback)
if [ -f "${CLAUDE_PROJECT_DIR}/.claude/lib/research-path-utils.sh" ]; then
  # Primary: Use unified library function
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/research-path-utils.sh"
  RESEARCH_PATHS=$(calculate_research_paths "$RESEARCH_TOPIC" "SUBTOPICS")
  # ... extract results ...
else
  # Fallback: Inline calculation
  echo "⚠ Warning: research-path-utils.sh not found, using inline fallback"

  # [Original 78-line inline implementation here]
fi
```

**Pros**:
- ✅ Guarantees execution even if library file missing
- ✅ Provides backward compatibility during migration
- ✅ Documents complete calculation logic for debugging

**Cons**:
- ⚠️ Increases command file size (but only in fallback section)
- ⚠️ Maintains duplication (but clearly marked as fallback)

**Decision**: Include fallback only if command criticality requires guaranteed execution. For /research, library dependency acceptable.

### Recommendation 3: Document Pattern in Directory Protocols - TERTIARY

Update `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md` to document hierarchical research pattern:

**Add Section** (After line 83):

```markdown
### Hierarchical Research Subdirectories (Lines 86-91)

**Pattern**: `/research` command creates nested structure for multi-subtopic investigations

**Structure**:
```
specs/042_topic/reports/
  ├── 001_single_report.md              # Flat report (/report command)
  └── 002_research/                     # Hierarchical research (/research command)
      ├── 001_subtopic_1.md
      ├── 002_subtopic_2.md
      ├── 003_subtopic_3.md
      └── OVERVIEW.md                   # Final synthesis (ALL CAPS)
```

**Utilities**: Use `calculate_research_paths()` from `.claude/lib/research-path-utils.sh`

**Example**:
```bash
source .claude/lib/research-path-utils.sh
SUBTOPICS=("jwt" "oauth" "session")
PATHS=$(calculate_research_paths "Authentication" "SUBTOPICS")
# Returns: {topic_dir, research_subdir, subtopic_paths{}}
```
```

**Rationale**: Documents the pattern for future maintainers and ensures consistency if other commands adopt hierarchical structure.

## Implementation Guidance

### Phase 1: Create Utility Function (1-2 hours)

1. Create `.claude/lib/research-path-utils.sh` with `calculate_research_paths()` function
2. Add unit tests to `.claude/tests/test_research_path_utils.sh`
3. Run tests: `bash .claude/tests/test_research_path_utils.sh`
4. Verify function returns valid JSON for various inputs

### Phase 2: Update /research Command (1 hour)

1. Back up current research.md: `cp .claude/commands/research.md .claude/commands/research.md.backup`
2. Replace lines 77-154 with simplified implementation (Recommendation 1, Step 2)
3. Test command with sample research topic: `/research "Test topic with subtopics"`
4. Verify paths calculated correctly and agents invoked successfully
5. Compare output behavior with backup version

### Phase 3: Documentation Update (30 minutes)

1. Update directory-protocols.md with hierarchical research pattern documentation
2. Add cross-reference from research.md to directory-protocols.md
3. Document `calculate_research_paths()` in research-path-utils.sh header comments

### Phase 4: Testing and Validation (1 hour)

1. Run full /research workflow with 2-4 subtopics
2. Verify all subtopic reports created at correct paths
3. Verify OVERVIEW.md created in correct location
4. Check git status confirms directory-protocols compliance (reports gitignored)
5. Test edge cases: existing topic reuse, topic with special characters

**Total Estimated Time**: 3.5-4.5 hours

## References

### Codebase Files Analyzed

- `/home/benjamin/.config/.claude/commands/research.md` (Lines 1-300, path resolution logic)
- `/home/benjamin/.config/.claude/commands/orchestrate.md` (Lines 701-750, similar pattern)
- `/home/benjamin/.config/.claude/lib/artifact-creation.sh` (Lines 14-267, utility functions)
- `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md` (Lines 1-1021, directory structure standards)
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` (Lines 1-1760, command design standards)

### Key Utility Functions

- `get_or_create_topic_dir()` - Creates numbered topic directories (artifact-creation.sh dependency)
- `create_topic_artifact()` - Creates numbered artifacts with automatic numbering (artifact-creation.sh:14-84)
- `get_next_artifact_number()` - Calculates next sequential number (artifact-creation.sh:134-157)

### Standards Alignment

- **Standard 1** (Command Architecture Standards:931-951): Executable instructions inline, complex calculations may be extracted to library
- **Phase 0 Requirements** (Command Architecture Standards:310-418): Orchestrators pre-calculate artifact paths before agent invocation
- **Directory Protocols** (directory-protocols.md:1-1021): Topic-based artifact organization with hierarchical report support

### Implementation Dependencies

- **jq**: JSON parsing (already used extensively in codebase, verified in artifact-creation.sh)
- **bash 4.3+**: Nameref support for array passing (`local -n` syntax)
- **Existing utilities**: artifact-creation.sh must be sourced before research-path-utils.sh
