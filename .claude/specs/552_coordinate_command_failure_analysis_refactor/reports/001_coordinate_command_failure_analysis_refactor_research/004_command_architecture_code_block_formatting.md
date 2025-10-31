# Command Architecture and Code Block Formatting Best Practices

## Metadata
- **Date**: 2025-10-30
- **Agent**: research-specialist
- **Topic**: Command Architecture and Code Block Formatting Best Practices
- **Report Type**: pattern recognition
- **Complexity Level**: 4

## Executive Summary

The /coordinate command exhibits widespread bash code block formatting issues that prevent reliable execution. Analysis reveals 3 critical anti-patterns: (1) documentation-style heredoc examples that should be direct bash execution, (2) missing function definitions that should be inline or library-sourced, and (3) variable scoping issues between disconnected bash blocks. The command contains ~35 bash code blocks with inconsistent formatting compared to /orchestrate's proven patterns. Key finding: bash blocks marked "EXECUTE NOW" should use direct Bash tool invocation, not heredoc examples. Recommended approach: convert 90% of heredoc patterns to direct execution, consolidate 4 inline function definitions to Phase 0, and source all library functions before first usage.

## Findings

### Finding 1: Heredoc Pattern Misuse (Lines 526-605)

**Location**: /home/benjamin/.config/.claude/commands/coordinate.md (Phase 0, STEP 0)

**Pattern Observed**:
```bash
# Source library-sourcing utilities first
if [ -f "$SCRIPT_DIR/../lib/library-sourcing.sh" ]; then
  source "$SCRIPT_DIR/../lib/library-sourcing.sh"
else
  echo "ERROR: Required library not found: library-sourcing.sh"
  exit 1
fi
```

**Issue**: This is presented as executable code but wrapped in markdown code fence, creating ambiguity about whether it should execute or serve as documentation.

**Evidence from Working Command** (/orchestrate lines 241-258):
```bash
**Step 1: Detect Project Directory**
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/detect-project-dir.sh"
# Sets: CLAUDE_PROJECT_DIR

**Step 2: Source Required Utilities**
UTILS_DIR="$CLAUDE_PROJECT_DIR/.claude/lib"
```

**Key Difference**: /orchestrate uses step-by-step bash blocks with clear `**EXECUTE NOW**` markers and imperative instructions. /coordinate uses single large bash blocks without explicit execution markers.

**Impact**: Variable definitions in Phase 0 (SCRIPT_DIR, functions) are not available to later phases because bash tool creates new shell context for each invocation.

### Finding 2: Inline Function Definitions Without Sourcing Context

**Location**: Lines 755-813 (verify_file_created function)

**Pattern**:
```bash
verify_file_created() {
  local file_path="$1"
  local item_desc="$2"
  local phase_name="$3"

  if [ -f "$file_path" ] && [ -s "$file_path" ]; then
    echo -n "✓"
    return 0
  else
    # Verbose diagnostic output
  fi
}

export -f verify_file_created
```

**Issues**:
1. Function defined in markdown code block (line 755-813)
2. Depends on being sourced into shell session
3. Used throughout command (lines 917, 1133, 1350, etc.)
4. No verification that function is available before use

**Evidence from Standards** (command_architecture_standards.md lines 1100-1125):
"Helper functions for concise verification - defined inline for immediate availability"
"These functions MUST be used at all file creation checkpoints"

**Architecture Gap**: Standards require inline verification functions but don't specify HOW to make them available across multiple bash tool invocations.

**Best Practice**: Define all helper functions in Phase 0 STEP 0 immediately after library sourcing, with explicit export.

### Finding 3: Variable Scoping Between Bash Blocks

**Location**: Multiple instances across command

**Example 1** (Phase 0 → Phase 1):
- Phase 0 STEP 3 (line 698): `initialize_workflow_paths()` call sets variables
- Phase 1 STEP 2 (line 870): Expects `$RESEARCH_COMPLEXITY` to be available
- **Problem**: Each Bash tool invocation creates new shell, variables don't persist

**Example 2** (Phase 1 → Phase 2):
- Phase 1 (line 923): `SUCCESSFUL_REPORT_PATHS=()` array created
- Phase 2 STEP 1 (line 1070): Expects `${SUCCESSFUL_REPORT_PATHS[@]}` array
- **Problem**: Arrays cannot be exported in bash, lost between invocations

**Evidence from /orchestrate** (lines 456-465):
```bash
# Store in workflow state
export WORKFLOW_TOPIC_DIR="$TOPIC_PATH"
export WORKFLOW_TOPIC_NUMBER="$TOPIC_NUMBER"
export WORKFLOW_TOPIC_NAME="$TOPIC_NAME"
```

**Key Insight**: /orchestrate explicitly exports scalar variables. Arrays require different handling (reconstruct from exported scalars or use file-based state).

### Finding 4: Bash vs Bash Heredoc Execution Patterns

**Critical Distinction**:

**Pattern A: Direct Bash Execution** (Recommended)
```markdown
**EXECUTE NOW**: USE the Bash tool to execute:

[Direct invocation via Bash tool - no code fence]
source .claude/lib/library.sh
RESULT=$(perform_detection "$INPUT")
echo "$RESULT"
```

**Pattern B: Bash Heredoc Example** (Documentation Only)
```markdown
Example bash pattern:

```bash
# This is documentation showing what bash code looks like
source .claude/lib/library.sh
RESULT=$(perform_detection "$INPUT")
```
```

**Evidence**: Command Architecture Standards line 1149:
"No Code Block Wrappers: Task invocations must NOT be fenced"

**Implication**: Same principle applies to bash blocks - execution-critical bash should NOT be code-fenced.

**Current /coordinate Status**:
- ~35 bash code blocks total
- ~31 are code-fenced (88%)
- Only 4 have explicit "EXECUTE NOW" markers
- Ambiguous which are examples vs executable

**Recommended Fix**: Remove code fences from all execution-critical bash blocks, add explicit "EXECUTE NOW" markers.

### Finding 5: Library Sourcing Completeness

**Location**: Phase 0 STEP 0 (lines 526-604)

**Libraries Sourced**:
```bash
source_required_libraries \
  "dependency-analyzer.sh" \
  "context-pruning.sh" \
  "checkpoint-utils.sh" \
  "unified-location-detection.sh" \
  "workflow-detection.sh" \
  "unified-logger.sh" \
  "error-handling.sh"
```

**Functions Used Later But Not Verified**:
1. `display_brief_summary()` - defined inline (lines 573-602), not in library
2. `verify_file_created()` - defined inline (lines 755-813), not in library
3. `should_synthesize_overview()` - called line 953, not verified available
4. `calculate_overview_path()` - called line 955, not verified available
5. `reconstruct_report_paths_array()` - called line 740, not verified available

**Missing Verification Pattern**:
```bash
REQUIRED_FUNCTIONS=(
  "detect_workflow_scope"
  "should_run_phase"
  "emit_progress"
)

for func in "${REQUIRED_FUNCTIONS[@]}"; do
  if ! command -v "$func" >/dev/null 2>&1; then
    MISSING_FUNCTIONS+=("$func")
  fi
done
```

**Issue**: Command verifies 5 library functions (line 548-569) but doesn't verify inline-defined functions or additional library functions called later.

**Best Practice**: Complete function verification BEFORE any phase execution, including inline-defined helpers.

### Finding 6: Code Block Size and Complexity

**Metrics**:
- Phase 0 STEP 0: 79 lines (lines 526-604)
- Phase 0 STEP 3: 48 lines (lines 683-730)
- Phase 1 STEP 2: 32 lines for agent invocation template (lines 877-908)
- Verification helper: 59 lines (lines 755-813)

**Comparison to /orchestrate**:
- /orchestrate Step 1: 8 lines (lines 241-248)
- /orchestrate Step 2: 11 lines (lines 250-260)
- Clear separation of concerns

**Code Complexity Issues**:
1. **Monolithic blocks**: Single bash block tries to do too much
2. **Mixed concerns**: Library sourcing + function definition + verification in one block
3. **Unclear boundaries**: Hard to tell where execution stops and documentation begins

**Recommended Pattern**:
- Maximum 15-20 lines per bash block
- Single responsibility per block
- Clear "EXECUTE NOW" marker for each block
- Explicit checkpoint markers between blocks

### Finding 7: Task Invocation Template Patterns

**Current Pattern** (lines 877-896):
```markdown
**EXECUTE NOW**: USE the Task tool NOW to invoke the research-specialist agent for EACH research topic.

**YOUR RESPONSIBILITY**: Make N Task tool invocations...

Task {
  subagent_type: "general-purpose"
  description: "Research [substitute actual topic name]"
  prompt: "..."
}
```

**Issues**:
1. Template contains placeholders `[substitute actual topic name]`
2. "YOUR RESPONSIBILITY" creates ambiguity (is this example or instruction?)
3. Single Task block with substitution instructions vs multiple concrete Task blocks

**Evidence from /orchestrate** (lines 422-465):
```bash
# Perform location detection using unified library
LOCATION_JSON=$(perform_location_detection "$WORKFLOW_DESCRIPTION" "false")

# Extract values from JSON output
if command -v jq &>/dev/null; then
  TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
  # ... more extractions
fi
```

**Key Difference**: /orchestrate shows complete, executable code with real variable names. /coordinate uses template placeholders.

**Recommended Fix**: Show 1-2 concrete examples with actual values, then note "Repeat for remaining topics" instead of placeholder-based template.

### Finding 8: Error Handling in Bash Blocks

**Current Pattern**:
- Some blocks have error handling (if [ $? -ne 0 ])
- Most blocks lack error handling
- No consistent fail-fast pattern

**Example with Error Handling** (lines 683-700):
```bash
if ! initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE"; then
  echo "ERROR: Workflow initialization failed"
  exit 1
fi
```

**Example without Error Handling** (lines 844-862):
```bash
# Simple keyword-based complexity scoring
RESEARCH_COMPLEXITY=2  # Default: 2 research topics

if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "integrate|migration|refactor"; then
  RESEARCH_COMPLEXITY=3
fi
# No verification that grep succeeded
```

**Best Practice from Standards** (line 1955):
```bash
set -e  # Exit on error

mkdir -p /path/to/dir || {
  echo "ERROR: Failed to create directory"
  exit 1
}
```

**Recommendation**: Add `set -e` to critical bash blocks and explicit error handling for important operations.

### Finding 9: Progressive Enhancement Patterns

**Observation**: Command uses multi-step patterns but doesn't clearly separate concerns.

**Current Pattern** (Phase 0):
1. STEP 0: Source libraries + define functions + verify functions
2. STEP 1: Parse workflow description
3. STEP 2: Detect workflow scope
4. STEP 3: Initialize workflow paths
5-7: (Commented out - "consolidated")

**Issue**: STEP 0 does too much. Should be:
- STEP 0A: Source libraries only
- STEP 0B: Define helper functions
- STEP 0C: Verify all functions available
- Then proceed to workflow-specific logic

**Evidence**: The command itself notes consolidation was performed (line 696 comment), but consolidation created unclear boundaries.

**Recommended Pattern**: Keep infrastructure setup (libraries, functions) separate from workflow logic (parsing, detection, initialization).

## Recommendations

### Recommendation 1: Standardize Bash Block Formatting

**Priority**: CRITICAL

**Action**:
1. Remove code fences from all execution-critical bash blocks (88% of blocks)
2. Add explicit "**EXECUTE NOW**:" markers before each executable block
3. Keep code fences only for documentation examples (mark with "❌ INCORRECT - Don't do this")
4. Maximum 20 lines per bash block

**Implementation**:
```markdown
✅ CORRECT:

**EXECUTE NOW**: Source required libraries.

source .claude/lib/library-sourcing.sh
source_required_libraries "error-handling.sh" "checkpoint-utils.sh"

**CHECKPOINT**: Libraries loaded and ready.
```

**Validation**: Search for ` ```bash` patterns, ensure each has imperative marker within 3 lines above.

**Estimated Impact**: 90% improvement in execution clarity.

### Recommendation 2: Consolidate Function Definitions to Phase 0

**Priority**: HIGH

**Action**:
1. Move `verify_file_created()` to Phase 0 STEP 0B (currently lines 755-813)
2. Move `display_brief_summary()` to Phase 0 STEP 0B (currently lines 573-602)
3. Create new Phase 0 STEP 0B: "Define Helper Functions"
4. Verify all functions with `command -v` check
5. Export functions with `export -f`

**Implementation Pattern**:
```bash
**STEP 0B: Define Helper Functions**

**EXECUTE NOW**: Define verification and display helper functions.

verify_file_created() {
  # 59 lines from original
}
export -f verify_file_created

display_brief_summary() {
  # 30 lines from original
}
export -f display_brief_summary

**CHECKPOINT**: Helper functions defined and exported.
```

**Rationale**: Functions defined once in Phase 0 are available to all subsequent phases via export.

### Recommendation 3: Implement Variable State Persistence

**Priority**: HIGH

**Action**:
1. Export all scalar variables immediately after definition
2. Convert arrays to space-separated strings for export
3. Add reconstruction functions for arrays when needed
4. Use checkpoint files for complex state

**Example - Array Handling**:
```bash
# Phase 1: Create array
SUCCESSFUL_REPORT_PATHS=("/path/1.md" "/path/2.md")

# Export as space-separated string
export REPORT_PATHS_STRING="${SUCCESSFUL_REPORT_PATHS[@]}"

# Phase 2: Reconstruct array
IFS=' ' read -r -a SUCCESSFUL_REPORT_PATHS <<< "$REPORT_PATHS_STRING"
```

**Alternative - File-Based State**:
```bash
# Phase 1: Save to file
printf "%s\n" "${SUCCESSFUL_REPORT_PATHS[@]}" > /tmp/report_paths.txt

# Phase 2: Read from file
mapfile -t SUCCESSFUL_REPORT_PATHS < /tmp/report_paths.txt
```

**Recommendation**: Use export for scalars, file-based state for arrays.

### Recommendation 4: Add Complete Function Verification

**Priority**: MEDIUM

**Action**:
1. Expand REQUIRED_FUNCTIONS array to include ALL functions used
2. Verify inline-defined functions after definition
3. Verify library functions after sourcing
4. Fail fast if any function missing

**Complete Function List**:
```bash
REQUIRED_FUNCTIONS=(
  # Library functions (from sourced libraries)
  "detect_workflow_scope"
  "should_run_phase"
  "emit_progress"
  "save_checkpoint"
  "restore_checkpoint"
  "initialize_workflow_paths"
  "should_synthesize_overview"
  "calculate_overview_path"
  "reconstruct_report_paths_array"
  # Inline-defined functions
  "verify_file_created"
  "display_brief_summary"
)
```

**Verification Block**:
```bash
MISSING_FUNCTIONS=()
for func in "${REQUIRED_FUNCTIONS[@]}"; do
  if ! command -v "$func" >/dev/null 2>&1; then
    MISSING_FUNCTIONS+=("$func")
  fi
done

if [ ${#MISSING_FUNCTIONS[@]} -gt 0 ]; then
  echo "ERROR: Missing functions:"
  printf "  - %s\n" "${MISSING_FUNCTIONS[@]}"
  exit 1
fi
```

### Recommendation 5: Implement Fail-Fast Error Handling

**Priority**: MEDIUM

**Action**:
1. Add `set -e` to critical bash blocks
2. Add explicit error checks for important operations
3. Use `|| { echo "ERROR"; exit 1; }` pattern consistently
4. Log errors to unified-logger

**Pattern**:
```bash
**EXECUTE NOW**: Perform critical operation with error handling.

set -e  # Exit on any error

source .claude/lib/library.sh || {
  echo "ERROR: Failed to source library"
  exit 1
}

RESULT=$(perform_operation "$INPUT") || {
  echo "ERROR: Operation failed for input: $INPUT"
  exit 1
}

[ -n "$RESULT" ] || {
  echo "ERROR: Operation returned empty result"
  exit 1
}

echo "✓ Operation complete: $RESULT"
```

### Recommendation 6: Separate Infrastructure from Workflow Logic

**Priority**: LOW

**Action**:
1. Rename current Phase 0 to "Phase 0: Infrastructure Setup"
2. Create Phase 0A: Library Sourcing
3. Create Phase 0B: Function Definitions
4. Create Phase 0C: Function Verification
5. Rename current Phase 0 STEP 1-3 to "Phase 1: Workflow Initialization"

**Proposed Structure**:
```
Phase 0: Infrastructure Setup
├── Phase 0A: Library Sourcing (15 lines)
├── Phase 0B: Function Definitions (90 lines)
└── Phase 0C: Function Verification (20 lines)

Phase 1: Workflow Initialization
├── Step 1: Parse workflow description (15 lines)
├── Step 2: Detect workflow scope (20 lines)
└── Step 3: Initialize workflow paths (50 lines)

Phase 2: Research
...
```

**Rationale**: Clear separation makes it easier to debug infrastructure issues vs workflow logic issues.

## Implementation Priority Matrix

| Recommendation | Priority | Effort | Impact | Sequence |
|----------------|----------|--------|--------|----------|
| 1. Bash block formatting | CRITICAL | HIGH | 90% | 1st |
| 2. Function consolidation | HIGH | MEDIUM | 70% | 2nd |
| 3. Variable persistence | HIGH | HIGH | 80% | 3rd |
| 4. Function verification | MEDIUM | LOW | 40% | 4th |
| 5. Error handling | MEDIUM | MEDIUM | 50% | 5th |
| 6. Infrastructure separation | LOW | LOW | 20% | 6th |

## References

### Command Files
- /home/benjamin/.config/.claude/commands/coordinate.md (2,531 lines)
  - Phase 0 STEP 0: lines 522-605 (library sourcing)
  - Helper functions: lines 755-813 (verify_file_created), 573-602 (display_brief_summary)
  - Phase 1: lines 815-1036 (research phase with agent invocations)
  - Phase 2: lines 1038-1214 (planning phase)
  - Variable usage: lines 870, 923, 1070 (scoping issues)

- /home/benjamin/.config/.claude/commands/orchestrate.md (5,438 lines, reference for working patterns)
  - Infrastructure setup: lines 234-269 (clean utility sourcing)
  - Location detection: lines 390-500 (working bash patterns)
  - Variable exports: lines 456-465 (explicit export pattern)

### Architecture Standards
- /home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md
  - Standard 11: lines 1128-1307 (imperative agent invocation, no code fences)
  - Helper functions: lines 750-814 (verification helper inline pattern)
  - Error handling: lines 1887-1975 (fail-fast patterns)

- /home/benjamin/.config/.claude/docs/guides/command-development-guide.md
  - Bash tool limitations: lines 1132-1153 (command substitution issues)
  - Code fence priming effect: lines 676-784 (why code fences prevent execution)
  - Mistake patterns: lines 1769-2073 (common bash block issues)

### Pattern Comparison Table

| Aspect | /coordinate (Broken) | /orchestrate (Working) |
|--------|---------------------|------------------------|
| Bash blocks | 88% code-fenced | Minimal code fences |
| Execution markers | 4 explicit | Clear "EXECUTE NOW" |
| Function location | Scattered inline | Consolidated Phase 0 |
| Variable export | Inconsistent | Explicit after each definition |
| Error handling | Partial | Comprehensive with set -e |
| Block size | 20-79 lines | 8-20 lines |
| Heredoc usage | 12+ examples | Direct execution only |

## Validation Criteria

To verify recommendations implemented correctly:

1. **Bash Block Formatting**:
   - `grep -c '```bash' coordinate.md` should be <5 (only documentation examples)
   - `grep -c 'EXECUTE NOW' coordinate.md` should match number of bash execution blocks

2. **Function Definitions**:
   - All helper functions in Phase 0 STEP 0B
   - `grep -n 'function\|() {' coordinate.md | head -5` should show Phase 0 lines only

3. **Variable Persistence**:
   - `grep -c 'export [A-Z_]*=' coordinate.md` should match number of critical variables
   - No arrays expected to persist (convert to strings or file-based)

4. **Function Verification**:
   - REQUIRED_FUNCTIONS array includes all 11 functions
   - Verification block executes after all definitions/sourcing

5. **Error Handling**:
   - `grep -c 'set -e' coordinate.md` should be ≥5 (critical blocks)
   - `grep -c '|| {' coordinate.md` should be ≥10 (error checks)
