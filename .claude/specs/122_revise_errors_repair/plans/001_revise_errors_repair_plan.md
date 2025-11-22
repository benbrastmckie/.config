# /revise Command Error Repair Plan

## Metadata
- **Date**: 2025-11-21
- **Feature**: Fix all /revise command errors (library sourcing and input validation)
- **Scope**: Add workflow-state-machine.sh sourcing to verification blocks and add input validation for sed command
- **Estimated Phases**: 4
- **Estimated Hours**: 1.25
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Complexity Score**: 9 (Tier 1)
- **Structure Level**: 0
- **Research Reports**:
  - [/revise Error Analysis Report](/home/benjamin/.config/.claude/specs/122_revise_errors_repair/reports/001_revise_error_analysis.md)
  - [Gap Analysis Report](/home/benjamin/.config/.claude/specs/122_revise_errors_repair/reports/002_gap_analysis.md)

## Overview

The `/revise` command experiences exit code 127 errors when executing verification bash blocks. The root cause is that two verification blocks source `state-persistence.sh` and `error-handling.sh` but NOT `workflow-state-machine.sh`, yet call `save_completed_states_to_state` which is defined in `workflow-state-machine.sh`.

**Impact**: 4 of 5 recent `/revise` errors are caused by this missing sourcing. Workflow completes partially but state persistence fails. The remaining 1/5 errors are caused by input parsing failures in sed command processing.

**Solution**:
1. Add the missing `workflow-state-machine.sh` sourcing statement to both affected verification blocks, following the three-tier sourcing pattern required by code standards
2. Add input validation and regex escaping for the sed command to handle edge cases gracefully

## Research Summary

Key findings from the error analysis report:
- **5 total errors** between 2025-11-21T17:40 and 2025-11-21T22:04 UTC
- **4 errors** have exit code 127 (command not found) for `save_completed_states_to_state`
- **1 error** has exit code 1 (general failure) for sed command input parsing
- **Root cause 1**: Missing library sourcing in verification blocks at lines 554-637 and 823-906
- **Root cause 2**: Unescaped regex characters and missing input validation in sed command at line 207
- **Affected function**: `save_completed_states_to_state` defined in `workflow-state-machine.sh`
- Each bash block runs as isolated subprocess - libraries must be re-sourced in each block

Key findings from the gap analysis report:
- **80% of errors (4/5)** are addressed by the original plan (exit code 127)
- **20% of errors (1/5)** represent a gap requiring input validation (exit code 1)
- Alternative fix option: Remove unnecessary `save_completed_states_to_state` calls if state persistence is redundant in verification blocks

## Success Criteria

- [ ] Both verification blocks source `workflow-state-machine.sh` correctly
- [ ] `/revise` command executes without exit code 127 errors
- [ ] Exit code 1 input parsing errors produce clean error messages
- [ ] Empty or malformed revision descriptions are handled gracefully
- [ ] No new errors logged in test execution
- [ ] Three-tier sourcing pattern compliance verified
- [ ] All 5 documented errors are addressed (100% coverage)

## Technical Design

### Current State (Broken)

**Research Verification Block** (lines 554-566):
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || ...
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || ...
# MISSING: workflow-state-machine.sh
# Line 626 calls: save_completed_states_to_state 2>&1 -> EXIT CODE 127
```

**Plan Revision Verification Block** (lines 823-835):
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || ...
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || ...
# MISSING: workflow-state-machine.sh
# Line 895 calls: save_completed_states_to_state 2>&1 -> EXIT CODE 127
```

### Target State (Fixed)

Both blocks will follow the three-tier sourcing pattern:
```bash
# Tier 1: Critical Foundation (state-persistence.sh, workflow-state-machine.sh, error-handling.sh)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
```

## Implementation Phases

### Phase 1: Add Missing Library Sourcing [COMPLETE]
dependencies: []

**Objective**: Add `workflow-state-machine.sh` sourcing to both verification blocks in `/revise` command.

**Complexity**: Low

Tasks:
- [x] Add `workflow-state-machine.sh` sourcing after `state-persistence.sh` at line 566 in Research Verification Block (file: /home/benjamin/.config/.claude/commands/revise.md)
- [x] Add `workflow-state-machine.sh` sourcing after `state-persistence.sh` at line 835 in Plan Revision Verification Block (file: /home/benjamin/.config/.claude/commands/revise.md)
- [x] Ensure fail-fast error handling pattern is used for new sourcing statements

Testing:
```bash
# Verify sourcing pattern is correct
grep -A3 "source.*state-persistence.sh" /home/benjamin/.config/.claude/commands/revise.md | head -20
grep "source.*workflow-state-machine.sh" /home/benjamin/.config/.claude/commands/revise.md
```

**Expected Duration**: 0.25 hours

### Phase 2: Add Input Validation [COMPLETE]
dependencies: []

**Objective**: Add defensive checks for input parsing in the argument processing block to handle exit code 1 errors.

**Complexity**: Low

Tasks:
- [x] Add validation check for empty REVISION_DESCRIPTION before sed processing (file: /home/benjamin/.config/.claude/commands/revise.md, line ~207)
- [x] Add regex escaping for EXISTING_PLAN_PATH before sed command to handle special characters
- [x] Add fallback with `|| true` to prevent sed pipeline failures from stopping execution
- [x] Add user-friendly error message for empty/invalid revision description

**Implementation Pattern**:
```bash
# Validate REVISION_DESCRIPTION is not empty
if [ -z "$REVISION_DESCRIPTION" ]; then
  echo "ERROR: Revision description is empty" >&2
  exit 1
fi

# Escape special regex characters in plan path
ESCAPED_PLAN_PATH=$(printf '%s\n' "$EXISTING_PLAN_PATH" | sed 's/[[\.*^$()+?{|]/\\&/g')

# Extract revision details with escaped path
REVISION_DETAILS=$(echo "$REVISION_DESCRIPTION" | sed "s|.*$ESCAPED_PLAN_PATH||" | xargs) || true
```

Testing:
```bash
# Test with empty input (should produce clean error)
# /revise ""

# Verify escaping logic handles special characters
echo "/path/with.dots/and(parens)" | sed 's/[[\.*^$()+?{|]/\\&/g'
```

**Expected Duration**: 0.25 hours

### Phase 3: Test Fix Execution [COMPLETE]
dependencies: [1, 2]

**Objective**: Verify the fix resolves both exit code 127 and exit code 1 errors by running `/revise` command.

**Complexity**: Low

Tasks:
- [x] Create a minimal test plan file for revision testing
- [x] Execute `/revise` command with test plan to trigger verification blocks
- [x] Verify no "command not found" errors for `save_completed_states_to_state`
- [x] Test with empty revision description to verify graceful error handling
- [x] Test with plan path containing special characters (if applicable)
- [x] Confirm workflow completes successfully through both verification checkpoints

Testing:
```bash
# Create test plan
mkdir -p /home/benjamin/.config/.claude/specs/test_revise/plans
echo "# Test Plan" > /home/benjamin/.config/.claude/specs/test_revise/plans/001_test_plan.md

# Run /revise with valid input (manual verification via Claude Code)
# /revise "revise plan at .claude/specs/test_revise/plans/001_test_plan.md based on test"

# Test empty input handling (should produce clean error)
# /revise ""
```

**Expected Duration**: 0.25 hours

### Phase 4: Verify No New Errors [COMPLETE]
dependencies: [3]

**Objective**: Confirm no new errors logged after fix implementation.

**Complexity**: Low

Tasks:
- [x] Query error log for /revise command errors since fix
- [x] Verify no exit code 127 errors related to `save_completed_states_to_state`
- [x] Verify no exit code 1 errors related to sed input parsing
- [x] Confirm all 5 documented errors are resolved (100% coverage)
- [x] Clean up test artifacts if applicable
- [x] Document fix completion in error analysis report

Testing:
```bash
# Query recent errors for /revise command
grep "/revise" /home/benjamin/.config/.claude/tests/logs/test-errors.jsonl | tail -5

# Check for exit code 127 errors specifically
grep "exit_code.*127" /home/benjamin/.config/.claude/tests/logs/test-errors.jsonl | grep "/revise" | tail -5

# Check for exit code 1 errors specifically
grep "exit_code.*1" /home/benjamin/.config/.claude/tests/logs/test-errors.jsonl | grep "/revise" | tail -5
```

**Expected Duration**: 0.5 hours

## Testing Strategy

1. **Static Verification**: Grep for sourcing patterns to confirm library is sourced before function call
2. **Input Validation Verification**: Verify empty input produces clean error message
3. **Dynamic Testing**: Execute `/revise` command to trigger affected code paths
4. **Error Log Verification**: Query error logs to confirm no new exit code 127 or exit code 1 errors
5. **Regression Check**: Ensure other bash blocks continue to function correctly

## Documentation Requirements

- [ ] Update error analysis report with fix status
- [ ] No new documentation files needed (fix is internal)

## Dependencies

- No external dependencies
- Requires: `workflow-state-machine.sh` library exists at expected path
- Requires: `save_completed_states_to_state` function exported by library

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Sourcing order matters | Low | Medium | Follow existing patterns in Part 3 block |
| Other blocks affected | Low | Low | Only modify identified blocks |
| Function signature changed | Very Low | Medium | Verify function exists before edit |
| Regex escaping edge cases | Low | Low | Test with various special characters |
| Empty input false positives | Low | Low | Only validate when sed command would fail |

## Rollback Procedure

If fix causes issues:
1. Remove added sourcing lines from both verification blocks
2. Alternatively, remove `save_completed_states_to_state` calls if state persistence not needed in verification blocks
3. For input validation issues: Revert to original sed command without escaping (one-line change)

## Alternative Approaches

The error analysis report proposed "Fix 2: Remove Unnecessary Function Calls" as a simpler alternative to adding library sourcing. This approach:
- Removes `save_completed_states_to_state` calls from verification blocks (lines 626-632 and 895-901)
- Reduces library dependencies in verification blocks
- May improve block execution speed

This alternative should be considered if state persistence in verification blocks proves redundant after investigation.
