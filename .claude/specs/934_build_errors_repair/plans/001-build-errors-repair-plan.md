# Build Command Errors Repair Plan

## Metadata
- **Date**: 2025-11-26
- **Feature**: /build command error repair
- **Scope**: Fix 12 remaining logged errors in /build command (state persistence, state machine transitions, defensive coding)
- **Estimated Phases**: 4
- **Estimated Hours**: 4.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [IN PROGRESS]
- **Structure Level**: 0
- **Complexity Score**: 32.5
- **Research Reports**:
  - [Error Analysis Report](/home/benjamin/.config/.claude/specs/934_build_errors_repair/reports/001_repair_analysis.md)
  - [Revision Verification Report](/home/benjamin/.config/.claude/specs/934_build_errors_repair/reports/002_revision_verification.md) - Notes task 947 completion

## Overview

This plan addresses 12 remaining errors logged for the /build command, identified through centralized error log analysis. Originally 16 errors were identified, but 4 have been resolved by external work:

- **3 errors resolved by task 947**: Same-state transition errors (test->test) fixed by idempotent state transition standard
- **1 error resolved pre-existing**: bashrc sourcing already covered by benign error filter

The remaining errors fall into three primary categories:

1. **Missing Function Calls** (37.5%): `save_completed_states_to_state` function not found (exit code 127)
2. **State Machine Transitions** (remaining): Invalid transitions (implement->complete, test->document, test->complete)
3. **State File Parsing** (12.5%): Grep failures on empty or missing state file keys

The repair approach prioritizes high-impact fixes first, targeting the root causes identified in the research report.

## Research Summary

From the error analysis report (001_repair_analysis.md):

- **Root Cause 1**: Incomplete library sourcing in build workflow - `save_completed_states_to_state` called before `workflow-state-machine.sh` sourced (6 errors)
- **Root Cause 2**: State machine workflow mismatch - transitions not defined for actual workflow needs (3 errors)
  - **NOTE**: Same-state transition issues (test->test) were resolved by task 947 (idempotent state transitions standard)
  - Remaining work: Add test->document and test->complete transitions
- **Root Cause 3**: Defensive coding missing for state file operations - grep failures on empty files (2 errors)
- **Additional Issues**: `estimate_context_usage` function undefined (1 error), bashrc sourcing benign errors (1 error - already covered by pre-existing benign filter), test execution failures (1 error)

Recommended approach: Fix library sourcing patterns first (highest impact), then address state machine transitions, then add defensive coding patterns.

## Success Criteria
- [ ] All 12 remaining /build errors have corresponding fixes
- [ ] `save_completed_states_to_state` function available in all bash blocks that call it
- [x] State machine allows same-state transitions (completed via task 947)
- [ ] State machine allows test->document and test->complete transitions
- [ ] State file parsing handles empty files and missing keys gracefully
- [ ] Test suite passes with no new regressions
- [ ] Error log shows reduced error count after fixes applied

## Technical Design

### Architecture Overview

The /build command uses a multi-block bash structure with cross-block state persistence:

```
Block 1 (Setup) -> Block 1b (Phase Update) -> Block 2 (Testing) -> Block 3 (Debug/Document) -> Block 4 (Completion)
```

State persistence relies on:
1. `state-persistence.sh` - Core state file operations (`append_workflow_state`, `load_workflow_state`)
2. `workflow-state-machine.sh` - State transitions and `save_completed_states_to_state`
3. `error-handling.sh` - Error logging and bash error traps

**Current Issue**: Some bash blocks source `state-persistence.sh` but not `workflow-state-machine.sh`, causing `save_completed_states_to_state` (defined in `workflow-state-machine.sh`) to fail with exit code 127.

### Fix Strategy

1. **Library Sourcing**: Ensure all bash blocks that call `save_completed_states_to_state` also source `workflow-state-machine.sh`
2. **State Transitions**: Add missing transitions or idempotent handling for edge cases
3. **Defensive Patterns**: Add existence checks before grep operations on state files

## Implementation Phases

### Phase 1: Library Sourcing Fixes [IN PROGRESS]
dependencies: []

**Objective**: Ensure all bash blocks in build.md properly source workflow-state-machine.sh before calling save_completed_states_to_state

**Complexity**: Low

Tasks:
- [x] Audit build.md for all locations that call `save_completed_states_to_state`
- [x] For each location, verify `workflow-state-machine.sh` is sourced earlier in the same bash block
- [x] Add missing sourcing statements following three-tier pattern (fail-fast for critical libraries)
- [x] Add defensive function existence check before calling `save_completed_states_to_state`:
  ```bash
  type save_completed_states_to_state &>/dev/null
  TYPE_CHECK=$?
  if [ $TYPE_CHECK -ne 0 ]; then
    echo "ERROR: save_completed_states_to_state function not found" >&2
    echo "DIAGNOSTIC: workflow-state-machine.sh library not sourced in this block" >&2
    exit 1
  fi
  ```
- [x] Verify `estimate_context_usage` function is defined before use in iteration check block (or wrap in conditional)

Testing:
```bash
# Verify function availability in each block
bash -c 'source .claude/lib/workflow/workflow-state-machine.sh && type save_completed_states_to_state'

# Run build command tests
bash .claude/tests/integration/test_build_iteration.sh
```

**Expected Duration**: 1.5 hours

### Phase 2: State Machine Transition Fixes [NOT STARTED]
dependencies: [1]

**Objective**: Fix state machine to support all valid /build workflow transition patterns

**Complexity**: Medium

Tasks:
- [x] Review STATE_TRANSITIONS table in workflow-state-machine.sh for /build workflow needs
- [x] Add test->document transition (tests passed, proceed to documentation)
- [x] Add test->complete transition for workflows that skip documentation
- [x] Consider implement->test validation (ensure test phase is mandatory)
- [x] Add idempotent handling for same-state transitions (test->test returns success, not error) - **[COMPLETE via task 947]**
- [x] Add proper handling for operations on terminal "complete" state (no-op or graceful return) - **[COMPLETE via task 947]**
- [x] Update sm_transition function to provide clearer error messages when transition is invalid

**Note**: Task 947 implemented idempotent state transitions standard, resolving same-state transition errors. See `/home/benjamin/.config/.claude/docs/reference/standards/idempotent-state-transitions.md` for implementation details.

Testing:
```bash
# Test valid transitions
bash .claude/tests/state/test_build_state_transitions.sh

# Manual transition tests
source .claude/lib/workflow/workflow-state-machine.sh
sm_init "/tmp/test_plan.md" "/build" "full-implementation" 1 "[]"
sm_transition "implement"  # Should succeed
sm_transition "test"       # Should succeed
sm_transition "document"   # Should succeed (new transition)
sm_transition "complete"   # Should succeed
```

**Expected Duration**: 1 hour (reduced from 2 hours due to task 947 completion)

### Phase 3: Defensive State File Operations [NOT STARTED]
dependencies: [1]

**Objective**: Add defensive coding patterns for state file parsing to prevent grep failures

**Complexity**: Low

Tasks:
- [x] Add file existence and non-empty checks before state file grep operations:
  ```bash
  if [[ -f "$STATE_FILE" && -s "$STATE_FILE" ]]; then
    PLAN_FILE=$(grep "^PLAN_FILE=" "$STATE_FILE" | cut -d'=' -f2- || echo "")
  else
    PLAN_FILE=""
  fi
  ```
- [x] Use default values when grep finds no matches: `grep ... || echo ""`
- [x] Add validation after state variable extraction with meaningful error messages
- [x] Update load_workflow_state to handle empty state files gracefully (already exists, verify)
- [x] Verify `estimate_context_usage` function is defined or add conditional check before use
- [x] Add /etc/bashrc sourcing failures to benign error filter - **[COMPLETE - Pre-existing]**
  - Verified: /etc/bashrc patterns already covered in error-handling.sh lines 1606-1612
  - No additional work needed for bashrc benign error handling

Testing:
```bash
# Test with empty state file
rm -f .claude/tmp/workflow_test.sh
touch .claude/tmp/workflow_test.sh
bash .claude/tests/state/test_state_persistence.sh

# Test benign error filter
bash .claude/tests/unit/test_benign_error_filter.sh
```

**Expected Duration**: 0.5 hours (reduced from 1 hour due to pre-existing bashrc filter coverage)

### Phase 4: Validation and Documentation [NOT STARTED]
dependencies: [1, 2, 3]

**Objective**: Validate all fixes work together and update relevant documentation

**Complexity**: Low

Tasks:
- [ ] Run full test suite to verify no regressions
- [ ] Run /build command on test plan to verify end-to-end workflow
- [ ] Query error log to verify error count reduction: `/errors --command /build --since 2025-11-23`
- [ ] Update build.md inline comments to explain library sourcing requirements
- [ ] Update troubleshooting section in build.md with new error patterns and solutions
- [ ] Mark related errors in error log as FIX_PLANNED with this plan path

Testing:
```bash
# Full test suite
bash .claude/tests/run_all_tests.sh

# Integration test
/build .claude/specs/934_build_errors_repair/plans/001-build-errors-repair-plan.md --dry-run

# Error log verification
bash -c 'source .claude/lib/core/error-handling.sh && query_errors --command /build --since 2025-11-23T00:00:00Z'
```

**Expected Duration**: 1.5 hours

**Note**: Phase dependencies enable sequential execution. Phase 1 must complete before Phases 2-3 can begin (library sourcing is foundational). Phase 4 depends on all prior phases.

## Testing Strategy

### Unit Testing
- Run existing state persistence tests: `bash .claude/tests/state/test_state_persistence.sh`
- Run benign error filter tests: `bash .claude/tests/unit/test_benign_error_filter.sh`
- Run state transition tests: `bash .claude/tests/state/test_build_state_transitions.sh`

### Integration Testing
- Run build iteration tests: `bash .claude/tests/integration/test_build_iteration.sh`
- Run full workflow tests: `bash .claude/tests/integration/test_build_workflow.sh` (if exists)
- Manual /build invocation on test plan with --dry-run flag

### Validation
- Query error log before and after fixes to measure reduction
- Verify no new errors introduced during fix implementation

## Documentation Requirements

1. **build.md**: Update inline comments explaining library sourcing requirements for each bash block
2. **Troubleshooting section**: Add entries for new error patterns with solutions
3. **workflow-state-machine.sh**: Document new transitions (test->document, test->complete)
4. **Reference existing documentation**: Link to idempotent-state-transitions.md standard created by task 947
5. **error-handling.sh**: No additional documentation needed (bashrc filter already exists)

## Dependencies

### Prerequisites
- Access to error log at `.claude/data/logs/errors.jsonl`
- All library files present and syntactically valid
- Test infrastructure functional

### External Dependencies
- jq (for JSON processing in state machine)
- bash 4.0+ (for associative arrays in state transitions)

### Files to Modify
1. `/home/benjamin/.config/.claude/commands/build.md` - Main fix target
2. `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh` - State transitions
3. `/home/benjamin/.config/.claude/lib/core/error-handling.sh` - Benign error filter
4. `/home/benjamin/.config/.claude/lib/core/state-persistence.sh` - Defensive patterns (if needed)
