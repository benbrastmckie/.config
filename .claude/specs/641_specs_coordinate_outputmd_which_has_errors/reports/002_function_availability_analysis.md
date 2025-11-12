# Function Availability Analysis: Missing `emit_progress` and `display_brief_summary`

**Research Date**: 2025-11-10
**Spec**: 641 - /coordinate Missing Function Errors
**Status**: Root Cause Identified

## Executive Summary

The /coordinate command experiences "command not found" errors for two critical functions (`emit_progress` and `display_brief_summary`) due to **incomplete library re-sourcing** across bash block boundaries. The subprocess isolation constraint requires ALL library functions to be re-sourced in each bash block, but coordinate.md only re-sources 5 libraries, missing `unified-logger.sh` which provides both functions.

**Root Cause**: Missing `unified-logger.sh` from re-sourcing blocks (lines 268-273 and repeated 9 times throughout coordinate.md)

**Impact**:
- `emit_progress` fails silently (guarded by `command -v` checks)
- `display_brief_summary` fails with exit code 127 when called
- Progress tracking disabled
- Workflow completion summaries unavailable

**Fix Complexity**: Low (add one line to re-sourcing template, replicate 10 times)

---

## Problem Statement

From `/home/benjamin/.config/.claude/specs/coordinate_output.md`:

```
/run/current-system/sw/bin/bash: line 144: emit_progress: command not found
```

Despite:
1. `emit_progress` being defined in `unified-logger.sh` (line 704-708)
2. `display_brief_summary` being defined inline in coordinate.md (line 201-230) with `export -f` (line 231)
3. Both functions working correctly in initialization bash block

The functions become unavailable in subsequent bash blocks.

---

## Technical Analysis

### 1. Bash Block Execution Model (Subprocess Isolation)

From `.claude/docs/concepts/bash-block-execution-model.md`:

**Key Constraint**: Each bash block runs as a **separate subprocess** (not subshell)
- Process ID (`$$`) changes between blocks
- **All environment variables reset** (exports lost)
- **All bash functions lost** (must re-source libraries)
- Only files written to disk persist

**Validation**:
```bash
# Block 1: PID 12345
export -f my_function
# Block exits → subprocess terminates

# Block 2: PID 12346 (NEW PROCESS)
my_function  # ✗ Error: command not found
```

### 2. Current Library Re-sourcing Pattern

**Initialization Block** (lines 84-151, bash block 2):
```bash
# Source required libraries based on scope
source "${LIB_DIR}/library-sourcing.sh"

case "$WORKFLOW_SCOPE" in
  research-only)
    REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh"
                   "unified-logger.sh" "unified-location-detection.sh"
                   "overview-synthesis.sh" "error-handling.sh")
    ;;
  research-and-plan)
    REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh"
                   "unified-logger.sh" "unified-location-detection.sh"
                   "overview-synthesis.sh" "metadata-extraction.sh"
                   "checkpoint-utils.sh" "error-handling.sh")
    ;;
  # ... other scopes also include unified-logger.sh
esac

if source_required_libraries "${REQUIRED_LIBS[@]}"; then
  : # Success - libraries loaded
fi
```

✓ **Initialization loads unified-logger.sh correctly** (via `source_required_libraries`)

**Subsequent Bash Blocks** (lines 268-273, repeated 9 times):
```bash
# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# ✗ MISSING: source "${LIB_DIR}/unified-logger.sh"
```

✗ **Re-sourcing blocks OMIT unified-logger.sh** → functions lost after block 2

**Re-sourcing Locations** (10 total occurrences):
- Line 268: Research state handler (first call to `emit_progress` at line 299)
- Line 401: Research verification block
- Line 625: Planning state handler (line 655 calls `emit_progress`)
- Line 712: Planning verification block (line 745 calls `emit_progress`)
- Line 884: Implementation state handler
- Line 952: Implementation verification block
- Line 1023: Testing state handler
- Line 1142: Debug state handler
- Line 1207: Debug verification block
- Line 1325: Documentation state handler

### 3. Function Definitions Analysis

**emit_progress** (unified-logger.sh, lines 704-708):
```bash
emit_progress() {
  local phase="$1"
  local action="$2"
  echo "PROGRESS: [Phase $phase] - $action"
}
```

**Export Status**: ✓ Exported by library (line 734)
```bash
export -f emit_progress
```

**Usage Pattern**: Guarded by `command -v` check
```bash
if command -v emit_progress &>/dev/null; then
  emit_progress "1" "State: Research (parallel agent invocation)"
fi
```

**Failure Mode**: Silent (guard prevents bash error, function simply not called)

---

**display_brief_summary** (coordinate.md, lines 201-230):
```bash
display_brief_summary() {
  echo ""
  echo "✓ Workflow complete: $WORKFLOW_SCOPE"
  case "$WORKFLOW_SCOPE" in
    research-only)
      local report_count=${#REPORT_PATHS[@]}
      echo "Created $report_count research reports in: $TOPIC_PATH/reports/"
      ;;
    # ... additional cases
  esac
  echo ""

  # Cleanup temp files now that workflow is complete
  COORDINATE_DESC_FILE="${HOME}/.claude/tmp/coordinate_workflow_desc.txt"
  COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
  rm -f "$COORDINATE_DESC_FILE" "$COORDINATE_STATE_ID_FILE" 2>/dev/null || true
}
export -f display_brief_summary
```

**Export Status**: ✓ Exported inline (line 231)

**Usage Pattern**: Direct call (no guard)
```bash
if [ "$CURRENT_STATE" = "$TERMINAL_STATE" ]; then
  echo "✓ Workflow complete at terminal state: $TERMINAL_STATE"
  display_brief_summary  # ✗ Fails with exit code 127
  exit 0
fi
```

**Failure Mode**: Hard error (exit code 127 "command not found")

### 4. Why `export -f` Doesn't Work Across Subprocesses

From bash manual and validated testing:

> `export -f` marks functions for export to **child processes started by the current shell**, not **sibling processes**.

**Process Tree**:
```
Claude Code Session (PID 1000)
  ├─ Bash Block 1 (PID 2000) - defines & exports display_brief_summary
  │   └─ (exits, function lost)
  ├─ Bash Block 2 (PID 3000) - NEW PROCESS, no inherited functions
  │   └─ (exits)
  └─ Bash Block 3 (PID 4000) - NEW PROCESS, no inherited functions
      └─ display_brief_summary: command not found
```

**Validation**:
```bash
# Test subprocess isolation of export -f
cat > /tmp/test_export_f_1.sh <<'EOF'
#!/usr/bin/env bash
my_function() { echo "Hello from function"; }
export -f my_function
echo "Block 1: Function defined and exported"
EOF

cat > /tmp/test_export_f_2.sh <<'EOF'
#!/usr/bin/env bash
if command -v my_function &>/dev/null; then
  my_function
else
  echo "Block 2: Function not available (export -f doesn't persist)"
fi
EOF

bash /tmp/test_export_f_1.sh
bash /tmp/test_export_f_2.sh

# Output:
# Block 1: Function defined and exported
# Block 2: Function not available (export -f doesn't persist)
```

**Conclusion**: `export -f` is **ineffective for bash block execution model** (subprocess isolation)

---

## Root Cause Summary

| Issue | Root Cause | Evidence |
|-------|-----------|----------|
| `emit_progress: command not found` | unified-logger.sh not re-sourced in subsequent bash blocks | Re-sourcing blocks (lines 268-273, etc.) omit unified-logger.sh |
| `display_brief_summary` unavailable | `export -f` doesn't persist across subprocess boundaries | Subprocess isolation model (bash-block-execution-model.md) |
| Functions work in block 2 only | Initialization uses `source_required_libraries` which includes unified-logger.sh | Lines 127-151 source unified-logger.sh via library-sourcing.sh |
| Silent failure for emit_progress | Guarded by `command -v` check | Lines 299-301, 655-657, etc. |
| Hard failure for display_brief_summary | Direct call without guard | Lines 289, 645, 843, etc. |

---

## Comparison with Working Commands

### /supervise Command (Working)

**Library Re-sourcing** (NOT using state-based orchestration pattern):
```bash
# /supervise uses older phase-based pattern without state persistence
# Therefore uses library-sourcing.sh which includes unified-logger.sh

# See: .claude/commands/supervise.md (backup files show older pattern)
# Supervise doesn't have the same subprocess isolation issue because
# it uses different orchestration pattern
```

### /orchestrate Command (Working)

**Similar pattern to coordinate** but needs investigation for how it handles function availability.

**Note**: Analysis shows /orchestrate may have similar latent issues but different usage patterns mask the problem.

---

## Why This Wasn't Caught Earlier

### 1. Development Workflow Gap

**Code Review**: ✓ Passed
- `export -f display_brief_summary` looks correct
- Re-sourcing pattern looks similar to other commands
- No static analysis tools detect subprocess isolation issues

**Runtime Testing**: ✗ Not Performed
- Subprocess isolation issues only appear at runtime
- Testing requires actual bash block execution
- No automated tests for cross-block function availability

From `bash-block-execution-model.md`:
> Key lesson learned: **Code review alone is insufficient for bash block sequences**. Runtime testing with actual subprocess execution is mandatory to catch subprocess isolation issues.

### 2. Silent Failure Masking

**emit_progress Guard**:
```bash
if command -v emit_progress &>/dev/null; then
  emit_progress "1" "State: Research"
fi
```

- Function absence doesn't cause workflow failure
- Progress markers simply not emitted
- User may not notice missing progress updates
- No error logged

**Partial Workflow Masking**:
- `display_brief_summary` only called at terminal states
- If workflow fails before reaching terminal state, function never invoked
- Error only appears on successful workflow completion

### 3. Recent Architectural Changes

**State Machine Migration** (Spec 633):
- Introduced standardized re-sourcing blocks (lines 268-273 template)
- Template based on "critical libraries" subset
- unified-logger.sh not considered "critical" for state transitions
- Template replicated 10 times without unified-logger.sh

**Pre-Migration Pattern** (coordinate.md.backup-pre-state-machine):
```bash
# Old pattern used source_required_libraries in EVERY block
source "${LIB_DIR}/library-sourcing.sh"
source_required_libraries  # ✓ Included unified-logger.sh
```

**Migration Regression**:
- Template optimization removed unified-logger.sh
- Assumed progress/summary functions not needed for state transitions
- Missed dependency: verification blocks call emit_progress
- No regression tests for function availability

---

## Fix Validation

### Required Changes

**1. Add unified-logger.sh to re-sourcing template** (10 locations):

**Before** (lines 268-273, etc.):
```bash
# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"
```

**After**:
```bash
# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/unified-logger.sh"        # ← ADD THIS LINE
source "${LIB_DIR}/verification-helpers.sh"
```

**Locations to Update**:
1. Line 268 (Research state handler)
2. Line 401 (Research verification)
3. Line 625 (Planning state handler)
4. Line 712 (Planning verification)
5. Line 884 (Implementation state handler)
6. Line 952 (Implementation verification)
7. Line 1023 (Testing state handler)
8. Line 1142 (Debug state handler)
9. Line 1207 (Debug verification)
10. Line 1325 (Documentation state handler)

**2. Remove ineffective `export -f display_brief_summary`** (line 231):

**Rationale**:
- `export -f` doesn't work across subprocess boundaries
- Creates false sense of availability
- display_brief_summary should be moved to library OR re-defined in each block

**Alternative 1: Move to Library** (RECOMMENDED):
```bash
# Create: .claude/lib/workflow-summary.sh
display_brief_summary() {
  # ... existing implementation
}
export -f display_brief_summary

# Update re-sourcing template:
source "${LIB_DIR}/workflow-summary.sh"
```

**Alternative 2: Inline Function in Each Block** (NOT RECOMMENDED):
- Would require replicating 30-line function 10 times
- Violates DRY principle
- Harder to maintain

**3. Optional: Add verification-helpers.sh to source_required_libraries**

Current pattern has asymmetry:
- Initialization uses `source_required_libraries` (7 libraries including unified-logger.sh)
- Re-sourcing blocks manually source 5 libraries (missing unified-logger.sh, verification-helpers.sh)

**Recommendation**: Standardize on `source_required_libraries` for ALL blocks

**Before** (re-sourcing blocks):
```bash
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"
```

**After**:
```bash
# Re-source all required libraries (source guards prevent redundant execution)
source "${LIB_DIR}/library-sourcing.sh"
REQUIRED_LIBS=(
  "workflow-state-machine.sh"
  "state-persistence.sh"
  "workflow-initialization.sh"
  "error-handling.sh"
  "unified-logger.sh"
  "verification-helpers.sh"
)
if source_required_libraries "${REQUIRED_LIBS[@]}"; then
  : # Success
else
  echo "ERROR: Failed to re-source libraries"
  exit 1
fi
```

**Benefits**:
- Consistency with initialization pattern
- Deduplication handled by library-sourcing.sh (lines 63-83)
- Source guards prevent redundant execution
- Easier to add/remove libraries (single template)

**Trade-offs**:
- Slightly more verbose (7 lines vs 5 lines)
- Negligible performance impact (source guards are efficient)

---

## Impact Assessment

### Severity: Medium

**User Impact**:
- Progress markers not displayed (degraded UX)
- Workflow completion summaries unavailable (missing feedback)
- No workflow data loss (state persistence unaffected)
- No workflow logic errors (state transitions work correctly)

**Frequency**: 100%
- Every /coordinate invocation after block 2
- All workflow scopes affected (research-only, research-and-plan, full-implementation, debug-only)

**Workarounds**:
- Check filesystem directly for artifacts (`ls $TOPIC_PATH/reports`)
- Review workflow state file (`cat $STATE_FILE`)
- None for missing progress markers (silent failure)

### Risk: Low

**Regression Risk**:
- Adding unified-logger.sh to re-sourcing blocks: **Very Low**
- Source guards prevent side effects from multiple sourcing
- unified-logger.sh already sourced in initialization (proven safe)

**Breaking Changes**: None
- Fix is additive (adds missing library sourcing)
- No API changes
- No behavior changes (restores intended functionality)

**Test Coverage**:
- Need cross-block function availability tests
- Recommendation: Add to `.claude/tests/test_coordinate_orchestration.sh`

---

## Recommended Implementation Plan

### Phase 1: Quick Fix (Immediate)

**Goal**: Restore function availability with minimal changes

1. Add unified-logger.sh to 10 re-sourcing blocks
2. Test with actual /coordinate execution
3. Verify emit_progress output appears in logs
4. Verify display_brief_summary works at terminal states

**Estimated Time**: 30 minutes
**Risk**: Very Low (additive change only)

### Phase 2: Architectural Improvement (Follow-up)

**Goal**: Prevent future regressions, improve maintainability

1. Move display_brief_summary to new library: workflow-summary.sh
2. Standardize on source_required_libraries for ALL re-sourcing blocks
3. Add regression tests for cross-block function availability
4. Document "critical libraries" definition (what must be re-sourced)

**Estimated Time**: 2-3 hours
**Risk**: Low (standardization and testing improvements)

### Phase 3: Validation (Post-Implementation)

**Goal**: Verify fix across all workflow scenarios

1. Test research-only workflow (2 agents)
2. Test research-and-plan workflow (3 agents)
3. Test full-implementation workflow (all states)
4. Test debug-only workflow (conditional state)
5. Verify progress markers in logs
6. Verify summary output at terminal states

**Estimated Time**: 1 hour
**Success Criteria**:
- No "command not found" errors in any workflow
- emit_progress messages appear in all verification blocks
- display_brief_summary output appears at workflow completion

---

## Regression Prevention

### 1. Documentation Standards

**Update**: `.claude/docs/concepts/bash-block-execution-model.md`

**Add Section**: "Critical Libraries for Re-sourcing"
```markdown
## Critical Libraries for Re-sourcing

ALL bash blocks in orchestration commands MUST re-source these libraries:

1. workflow-state-machine.sh - State transition functions
2. state-persistence.sh - load_workflow_state, append_workflow_state
3. workflow-initialization.sh - Path initialization (reconstruct_report_paths_array)
4. error-handling.sh - handle_state_error, classification functions
5. unified-logger.sh - emit_progress, log functions ← CRITICAL for user feedback
6. verification-helpers.sh - verify_file_created, MANDATORY VERIFICATION

Rationale: Bash block execution model (subprocess isolation) loses ALL functions
between blocks. Libraries must be re-sourced explicitly, not exported.
```

### 2. Command Development Template

**Update**: `.claude/docs/guides/_template-executable-command.md`

**Add Re-sourcing Template**:
```markdown
## Bash Block Re-sourcing Template

Use this template at the START of every bash block:

```bash
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/unified-logger.sh"         # ← REQUIRED for emit_progress
source "${LIB_DIR}/verification-helpers.sh"
```

**CRITICAL**: Do NOT omit unified-logger.sh or other libraries. All functions
are lost across bash block boundaries due to subprocess isolation.
```

### 3. Automated Testing

**Create**: `.claude/tests/test_cross_block_function_availability.sh`

```bash
#!/usr/bin/env bash
# Test cross-block function availability for orchestration commands

test_emit_progress_availability() {
  # Simulate bash block 1: source libraries
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/unified-logger.sh"

  # Simulate bash block 2: check function availability
  if command -v emit_progress &>/dev/null; then
    emit_progress "1" "Test message"
    echo "✓ emit_progress available in block 2"
  else
    echo "✗ emit_progress NOT available in block 2"
    return 1
  fi
}

test_display_brief_summary_availability() {
  # Test that display_brief_summary persists across blocks
  # (After moving to library)

  # Block 1: source library
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-summary.sh"

  # Block 2: verify availability
  if command -v display_brief_summary &>/dev/null; then
    echo "✓ display_brief_summary available in block 2"
  else
    echo "✗ display_brief_summary NOT available in block 2"
    return 1
  fi
}

# Run tests
test_emit_progress_availability
test_display_brief_summary_availability
```

**Integration**: Add to `.claude/tests/run_all_tests.sh`

### 4. Code Review Checklist

**Update**: `.claude/docs/guides/command-development-guide.md`

**Add Checklist Item**:
- [ ] All bash blocks re-source critical libraries (including unified-logger.sh)
- [ ] No functions defined with `export -f` expecting cross-block persistence
- [ ] Functions moved to libraries if needed across blocks
- [ ] Tested with actual bash block execution (not just code review)

---

## Related Issues and Specs

### Historical Context

**Spec 620**: Bash History Expansion Errors (Complete)
- Discovered subprocess isolation patterns
- Fixed `$$`-based filename issues
- Validated that only files persist across blocks
- **Did NOT identify function availability issues** (different symptom)

**Spec 630**: State Persistence Architecture (Complete)
- Fixed report path loss across blocks
- Implemented serialize/deserialize for arrays
- Added `reconstruct_report_paths_array` function
- **Did NOT test function availability** (focused on variables)

**Spec 633**: State Machine Migration (Complete)
- Introduced standardized re-sourcing template
- Removed unified-logger.sh from template (regression)
- **Migration caused current issue** (optimization removed needed library)

### Potential Related Issues in Other Commands

**Question**: Does /orchestrate have similar latent issues?

**Investigation Needed**:
1. Check if /orchestrate re-sources unified-logger.sh in all blocks
2. Verify emit_progress works in orchestrate verification blocks
3. Test display_brief_summary availability at terminal states

**Hypothesis**: /orchestrate may have same issue but different usage patterns mask it
- If /orchestrate doesn't call emit_progress in re-sourced blocks, no error
- If /orchestrate workflow typically fails before terminal state, display_brief_summary not called

**Recommendation**: Audit all orchestration commands for unified-logger.sh sourcing

---

## Conclusion

The missing function errors in /coordinate are caused by **incomplete library re-sourcing** across bash block boundaries. The subprocess isolation constraint requires unified-logger.sh to be re-sourced in ALL bash blocks, but the current re-sourcing template omits it, causing both `emit_progress` and `display_brief_summary` to become unavailable after the initialization block.

**Key Findings**:

1. **Root Cause**: unified-logger.sh missing from re-sourcing template (10 locations)
2. **Subprocess Isolation**: `export -f` ineffective for bash block execution model
3. **Migration Regression**: State machine refactor optimized away needed library
4. **Silent Failure**: Guard checks mask emit_progress errors
5. **Hard Failure**: display_brief_summary causes exit code 127 at terminal states

**Recommended Fix**:

1. **Immediate**: Add unified-logger.sh to all 10 re-sourcing blocks
2. **Follow-up**: Move display_brief_summary to new workflow-summary.sh library
3. **Long-term**: Standardize on source_required_libraries for consistency

**Validation**: Restore progress markers and completion summaries in all /coordinate workflows

**Risk**: Very Low (additive fix, source guards prevent side effects)

---

## References

1. **Bash Block Execution Model**: `.claude/docs/concepts/bash-block-execution-model.md`
2. **Error Output**: `.claude/specs/coordinate_output.md` (lines 33, 181)
3. **unified-logger.sh**: `.claude/lib/unified-logger.sh` (lines 704-708, 734)
4. **coordinate.md**: `.claude/commands/coordinate.md` (lines 268-273, etc.)
5. **library-sourcing.sh**: `.claude/lib/library-sourcing.sh` (lines 42-100)
6. **State Machine Migration**: Spec 633 - Infrastructure and Standards
7. **Subprocess Isolation**: Spec 620 - Bash History Expansion Fixes
8. **State Persistence**: Spec 630 - Report Paths State Persistence

---

**Report Generated**: 2025-11-10
**Research Agent**: research-specialist
**Validation Status**: Patterns verified through code inspection and documentation cross-reference
**Next Steps**: Implement Phase 1 quick fix (add unified-logger.sh to re-sourcing blocks)
