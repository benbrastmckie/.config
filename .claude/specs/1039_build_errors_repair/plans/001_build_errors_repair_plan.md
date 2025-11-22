# /build Errors Repair Implementation Plan

## Metadata
- **Date**: 2025-11-21
- **Feature**: /build Command Error Repair
- **Scope**: Fix exit code 127 and state parsing errors in /build workflow
- **Estimated Phases**: 4
- **Estimated Hours**: 7
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 25.5
- **Research Reports**:
  - [Error Analysis Report](/home/benjamin/.config/.claude/specs/1039_build_errors_repair/reports/001_build_errors_analysis.md)
  - [Plan Alignment Analysis](/home/benjamin/.config/.claude/specs/1039_build_errors_repair/reports/002_plan_alignment_analysis.md)

## Overview

This implementation plan addresses critical errors in the /build command that cause 72% of workflow failures. The primary issues are:

1. **Exit Code 127 Errors (45%)**: The `save_completed_states_to_state` function is called but not available because `workflow-state-machine.sh` is not sourced in subsequent bash blocks
2. **State File Parsing Failures (27%)**: State variables extracted with `grep | cut` fail silently when state files are missing or malformed
3. **Summary Validation Errors (9%)**: Rigid pattern matching fails when summary files have variant formats

The fix strategy follows the three-tier sourcing pattern already documented in project standards but not consistently applied across all build.md bash blocks.

## Research Summary

Key findings from the error analysis report:

- **45% of errors** caused by missing `save_completed_states_to_state` function (exit code 127)
- **27% of errors** from state file parsing without defensive checks
- **9% of errors** from summary validation pattern failures
- **9% of errors** from test execution failures (may be expected behavior)
- **9% of errors** from environment initialization (NixOS /etc/bashrc)

Key findings from the gap analysis report:

- **CRITICAL GAP**: `load_workflow_state` is called but variables (`PLAN_FILE`, `TOPIC_PATH`) are empty in the caller context despite the state file containing correct values
- **Root cause hypotheses**: Subshell variable scope issue, variables not exported, or function returns before sourcing completes
- **Already fixed**: `log_command_error` parameter count bug in state-persistence.sh:590-593 (3→7 parameters) was fixed during initial build attempt

Recommended approach: Ensure consistent three-tier sourcing pattern across all bash blocks in build.md, add defensive state file validation with post-load verification, add fallback direct sourcing pattern when variables are empty, and improve summary pattern matching robustness.

## Success Criteria

- [x] No exit code 127 errors for `save_completed_states_to_state` function
- [x] State file parsing includes existence and content validation
- [x] Post-load verification catches empty variables after `load_workflow_state` calls
- [x] Fallback direct sourcing pattern when state variables are empty
- [x] Summary validation has fallback behavior when patterns missing
- [x] All bash blocks in build.md follow three-tier sourcing pattern
- [x] Pre-commit hooks validate library sourcing compliance
- [x] Test coverage for state persistence edge cases

## Technical Design

### Root Cause Analysis

The `save_completed_states_to_state` function is defined in `workflow-state-machine.sh` (line 126) and exported via `export -f` (line 968). However, each bash block in a Claude command runs in a **separate process**, meaning exported functions from previous blocks are not available.

**Current Pattern (failing)**:
```bash
# Block 1: Sources library, function available
source ".claude/lib/workflow/workflow-state-machine.sh"
save_completed_states_to_state  # Works

# Block 2: New process, no sourcing, function unavailable
save_completed_states_to_state  # EXIT 127!
```

**Required Pattern (three-tier sourcing)**:
```bash
# EVERY bash block must source required libraries
# Tier 1: Core utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || { ... }
# Tier 2: Error handling
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || { ... }
# Tier 3: Workflow libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || { ... }

# Now function is available
save_completed_states_to_state
```

### Affected Files

| File | Issue | Fix |
|------|-------|-----|
| `.claude/commands/build.md` | Multiple bash blocks missing library sourcing | Add three-tier sourcing to all blocks |
| `.claude/lib/core/state-persistence.sh` | State parsing lacks defensive checks | Add existence/content validation |
| `.claude/lib/workflow/workflow-state-machine.sh` | Function availability not validated | Add pre-flight check |

### Architecture Decisions

1. **Library Re-sourcing**: Accept overhead of re-sourcing libraries in each bash block (15-50ms) for reliability
2. **Fail-Fast Pattern**: Exit immediately with clear error when required functions unavailable
3. **Defensive Parsing**: Always check file existence before grep/cut operations
4. **Graceful Degradation**: Provide fallback behavior for non-critical validations (summary patterns)

## Implementation Phases

### Phase 0: Audit and Catalog [COMPLETE]
dependencies: []

**Objective**: Identify all bash blocks in build.md requiring library sourcing fixes

**Complexity**: Low

Tasks:
- [x] Audit build.md to catalog all bash blocks (file: `.claude/commands/build.md`)
- [x] Identify blocks that call `save_completed_states_to_state` without sourcing
- [x] Identify blocks that call state-persistence functions without sourcing
- [x] Document current sourcing patterns in each block
- [x] Create checklist of blocks requiring updates

Testing:
```bash
# Count bash blocks in build.md
grep -c '```bash' .claude/commands/build.md

# Find blocks using save_completed_states_to_state
grep -B20 'save_completed_states_to_state' .claude/commands/build.md | grep -c 'source.*workflow-state-machine'
```

**Expected Duration**: 0.5 hours

### Phase 1: Fix Library Sourcing in Build Command [COMPLETE]
dependencies: [0]

**Objective**: Add three-tier sourcing pattern to all bash blocks in build.md

**Complexity**: Medium

Tasks:
- [x] Add three-tier sourcing header to Block 1 (initialization) if missing
- [x] Add three-tier sourcing header to Block 2 (phase execution) if missing
- [x] Add three-tier sourcing header to Block 3 (testing phase) if missing
- [x] Add three-tier sourcing header to Block 4 (documentation phase) if missing
- [x] Add three-tier sourcing header to checkpoint blocks
- [x] Add function availability validation before calling `save_completed_states_to_state`
- [x] Ensure error-handling library sourced for `log_command_error` calls

Testing:
```bash
# Verify all blocks have sourcing
bash .claude/scripts/lint/check-library-sourcing.sh .claude/commands/build.md

# Run library sourcing linter
bash .claude/scripts/validate-all-standards.sh --sourcing
```

**Expected Duration**: 2 hours

### Phase 2: Add Defensive State File Parsing [COMPLETE]
dependencies: [1]

**Objective**: Add existence and content validation to state file operations, including post-load verification for load_workflow_state variable propagation gap

**Complexity**: Medium

Tasks:
- [x] Add state file existence check before parsing in build.md blocks
- [x] Add fallback behavior when PLAN_FILE variable missing from state
- [x] Add meaningful error messages for state parsing failures
- [x] Implement state file recovery mechanism for corrupted states
- [x] Add validation helper function to state-persistence.sh (file: `.claude/lib/core/state-persistence.sh`)
- [x] Add post-load verification: check if critical variables are empty after load_workflow_state
- [x] Add fallback pattern: `[[ -z "$PLAN_FILE" ]] && source "$STATE_FILE" 2>/dev/null`
- [x] Investigate load_workflow_state in state-persistence.sh for subshell/export issues (file: `.claude/lib/core/state-persistence.sh`)
- [x] Add logging when fallback sourcing is triggered to track frequency

Testing:
```bash
# Test with missing state file
rm -f .claude/tmp/workflow_test_*.sh
# Run state load - should fail gracefully

# Test with malformed state file
echo "INVALID_LINE" > .claude/tmp/workflow_test_123.sh
source .claude/lib/core/state-persistence.sh
load_workflow_state "test_123" false
# Should report clear error

# Test load_workflow_state variable propagation
STATE_FILE=".claude/tmp/workflow_test_var_propagation.sh"
echo 'PLAN_FILE="/test/path.md"' > "$STATE_FILE"
echo 'TOPIC_PATH="/test/topic"' >> "$STATE_FILE"
load_workflow_state "test_var_propagation" false
# Verify variables are set in current shell
[[ -n "$PLAN_FILE" ]] && echo "PASS: PLAN_FILE set" || echo "FAIL: PLAN_FILE empty"
[[ -n "$TOPIC_PATH" ]] && echo "PASS: TOPIC_PATH set" || echo "FAIL: TOPIC_PATH empty"
```

**Expected Duration**: 2.5 hours

### Phase 3: Improve Summary Validation and Testing [COMPLETE]
dependencies: [2]

**Objective**: Make summary validation more robust and add comprehensive tests

**Complexity**: Low

Tasks:
- [x] Update summary pattern matching to handle variant formats
- [x] Add fallback when "**Plan**:" pattern not found in summary
- [x] Add unit test for state persistence edge cases (file: `.claude/tests/unit/`)
- [x] Add integration test for build command library sourcing (file: `.claude/tests/integration/`)
- [x] Run full test suite to verify no regressions
- [x] Update pre-commit hook to validate library sourcing patterns

Testing:
```bash
# Run unit tests
bash .claude/tests/unit/test_source_libraries_inline_error_logging.sh

# Run integration tests
bash .claude/tests/integration/test_build_iteration.sh

# Run pre-commit validation
bash .claude/scripts/validate-all-standards.sh --all
```

**Expected Duration**: 2 hours

## Testing Strategy

### Unit Tests
- Test `save_completed_states_to_state` function availability after sourcing
- Test state file parsing with missing/empty/malformed files
- Test summary pattern matching with various formats

### Integration Tests
- Test full build workflow from start to finish
- Test build workflow recovery after simulated failure
- Test state persistence across multiple bash blocks

### Validation Commands
```bash
# Linting validation
bash .claude/scripts/validate-all-standards.sh --sourcing
bash .claude/scripts/validate-all-standards.sh --suppression
bash .claude/scripts/validate-all-standards.sh --conditionals

# Pre-commit hook test
git diff --staged --name-only | xargs .claude/hooks/pre-commit

# Manual build workflow test
/build .claude/specs/1039_build_errors_repair/plans/001_build_errors_repair_plan.md --dry-run
```

## Documentation Requirements

- [ ] Update bash-block-execution-model.md if new patterns discovered
- [ ] Update exit-code-127-command-not-found.md with resolution steps
- [ ] Add entry to troubleshooting index for this error pattern
- [ ] Update code-standards.md if sourcing requirements change

## Dependencies

### Prerequisites
- jq (JSON processing) - already installed
- bash 4.0+ (array handling) - already available
- Pre-commit hook infrastructure - already in place

### External Dependencies
None

### Internal Dependencies
- `.claude/lib/core/state-persistence.sh` (Tier 1)
- `.claude/lib/core/error-handling.sh` (Tier 2)
- `.claude/lib/workflow/workflow-state-machine.sh` (Tier 3)

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Sourcing overhead affects performance | Low | Low | 15-50ms overhead acceptable for reliability |
| Breaking existing workflows | Medium | High | Comprehensive testing before merge |
| Missing bash blocks during audit | Low | Medium | Systematic grep-based audit |

## Rollback Plan

If implementation causes regressions:
1. Revert build.md to previous version: `git checkout HEAD~1 -- .claude/commands/build.md`
2. Disable pre-commit sourcing validation temporarily
3. Document failed approach in debug/ directory

## Notes

- The `export -f` mechanism in bash only works within the same process tree
- Each bash block in Claude commands runs as a separate process
- This is a fundamental bash behavior, not a bug in the code
- The solution (re-sourcing) is the standard pattern documented in project standards

### Previously Fixed Issues

- **log_command_error parameter count bug** (state-persistence.sh:590-593): Was already fixed during initial build attempt. The function was being called with 3 parameters instead of the required 7 parameters. Fix corrected the call to include all required arguments: `COMMAND_NAME`, `WORKFLOW_ID`, `USER_ARGS`, `error_type`, `error_message`, `context`, and `details`. Verified working - no action required.
