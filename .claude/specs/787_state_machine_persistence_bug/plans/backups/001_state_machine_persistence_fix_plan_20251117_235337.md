# State Machine Persistence Bug Fix Plan

## Metadata
- **Date**: 2025-11-17
- **Feature**: State Machine Persistence Bug Fix
- **Scope**: Fix STATE_FILE and CURRENT_STATE persistence across bash subprocess boundaries in /build command
- **Estimated Phases**: 3
- **Estimated Hours**: 2-3
- **Structure Level**: 0
- **Complexity Score**: 15
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [State Persistence Analysis](/home/benjamin/.config/.claude/specs/787_state_machine_persistence_bug/reports/001_state_persistence_analysis.md)

## Overview

This plan addresses a critical bug in the /build command's state machine persistence mechanism. Two interrelated issues cause state machine transitions to succeed in memory but fail across bash subprocess boundaries:

1. **Bug 1**: Part 4 of build.md (lines 281-340) is missing the `load_workflow_state()` call, leaving STATE_FILE undefined when attempting state transitions
2. **Bug 2**: The `sm_transition()` function in workflow-state-machine.sh updates CURRENT_STATE in memory but does not persist it to the state file

The combined effect causes subsequent Parts (5, 6, 7) to read stale state ("initialize") from the state file, resulting in "Invalid transition: initialize -> test" errors even though Part 4's in-memory state was correctly updated to "implement".

## Research Summary

Key findings from the state persistence analysis report:

- **Root Cause 1**: Part 4 sources libraries but never calls `load_workflow_state()` to restore STATE_FILE variable from workflow state file. Parts 5, 6, and 7 correctly call this function (lines 522, 651, 897).
- **Root Cause 2**: `sm_transition()` at line 625 updates CURRENT_STATE in memory but does not persist it. In contrast, `sm_init()` (lines 497-503) correctly persists both TERMINAL_STATE and CURRENT_STATE using `append_workflow_state()`.
- **Impact**: Part 4 transitions to "implement" in memory but fails to write to state file. Part 5 loads stale "initialize" state and fails transition to "test".
- **Evidence**: Error messages in build-output.md lines 37 ("STATE_FILE not set") and 68-69 ("Invalid transition: initialize -> test").

Recommended approach: Apply both fixes together since they are interdependent - fixing only one would still result in failures.

## Success Criteria

- [ ] Part 4 of build.md correctly loads workflow state before calling `sm_transition()`
- [ ] `sm_transition()` persists CURRENT_STATE to state file after updating in memory
- [ ] STATE_FILE variable is defined in Part 4 subprocess when `sm_transition()` is called
- [ ] Complete /build workflow executes without state transition errors
- [ ] Subsequent Parts (5, 6, 7) read correct CURRENT_STATE from state file
- [ ] Error message "STATE_FILE not set" no longer appears in output
- [ ] Error message "Invalid transition: initialize -> test" no longer appears
- [ ] All existing tests pass after changes

## Technical Design

### Architecture Overview

The /build command uses bash subprocess isolation, where each Part runs in a separate shell context. State is shared via a file-based persistence mechanism:

```
Part 3 (sm_init)          Part 4 (sm_transition)        Part 5 (sm_transition)
┌─────────────────┐       ┌─────────────────────┐       ┌─────────────────────┐
│ init_state()    │       │ load_state() [MISSING]     │ load_state()        │
│ sm_init()       │ ──>   │ sm_transition()     │ ──>   │ sm_transition()     │
│ persist STATE   │       │ persist STATE [MISSING]    │ persist STATE       │
└─────────────────┘       └─────────────────────┘       └─────────────────────┘
        │                          │                            │
        v                          v                            v
   STATE_FILE:               STATE_FILE:                  STATE_FILE:
   CURRENT_STATE=initialize  CURRENT_STATE=??? (stale)    CURRENT_STATE=implement
```

### Fix Strategy

**Fix 1 - Load State in Part 4** (build.md):
Add workflow state loading after sourcing libraries, following the pattern used in Parts 5, 6, and 7:
```bash
# After line 307 in Part 4
STATE_ID_FILE="${HOME}/.claude/tmp/build_state_id.txt"
if [ ! -f "$STATE_ID_FILE" ]; then
  echo "ERROR: WORKFLOW_ID file not found: $STATE_ID_FILE" >&2
  exit 1
fi
WORKFLOW_ID=$(cat "$STATE_ID_FILE")
export WORKFLOW_ID
load_workflow_state "$WORKFLOW_ID" false
```

**Fix 2 - Persist CURRENT_STATE in sm_transition()** (workflow-state-machine.sh):
Add persistence call after updating CURRENT_STATE, following the pattern used in sm_init():
```bash
# After line 625 in sm_transition()
CURRENT_STATE="$next_state"

# Persist CURRENT_STATE to state file (following sm_init pattern)
if command -v append_workflow_state &> /dev/null; then
  append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"
fi
```

### Error Handling Enhancements

**Enhancement 1 - STATE_FILE Validation Guard** (workflow-state-machine.sh):
Add fail-fast validation at the beginning of `sm_transition()`:
```bash
if [ -z "${STATE_FILE:-}" ]; then
  echo "ERROR: STATE_FILE not set in sm_transition()" >&2
  echo "DIAGNOSTIC: Call load_workflow_state() before sm_transition()" >&2
  return 1
fi
```

## Implementation Phases

### Phase 1: Core Bug Fixes
dependencies: []

**Objective**: Apply the two critical fixes to resolve state persistence bug

**Complexity**: Medium

Tasks:
- [ ] Add WORKFLOW_ID loading to Part 4 of build.md after line 307
- [ ] Add load_workflow_state() call to Part 4 of build.md
- [ ] Add CURRENT_STATE persistence to sm_transition() after line 625
- [ ] Ensure persistence call follows same pattern as sm_init() (lines 497-503)

**Expected Duration**: 30-45 minutes

Testing:
```bash
# Verify syntax after edits
bash -n /home/benjamin/.config/.claude/commands/build.md 2>&1 | head -20
bash -n /home/benjamin/.config/.claude/lib/workflow-state-machine.sh

# Create simple test plan to validate /build execution
echo "Simple test plan" > /tmp/test_plan.md
```

### Phase 2: Error Handling and Diagnostics
dependencies: [1]

**Objective**: Add validation guards and diagnostic output for better error detection

**Complexity**: Low

Tasks:
- [ ] Add STATE_FILE validation guard at beginning of sm_transition()
- [ ] Add diagnostic message when STATE_FILE is undefined
- [ ] Ensure guard returns 1 to propagate error properly

**Expected Duration**: 15-20 minutes

Testing:
```bash
# Verify syntax after edits
bash -n /home/benjamin/.config/.claude/lib/workflow-state-machine.sh

# Test that guard works when STATE_FILE is not set
(
  unset STATE_FILE
  source /home/benjamin/.config/.claude/lib/workflow-state-machine.sh
  sm_transition "implement" 2>&1 | grep -q "STATE_FILE not set"
)
```

### Phase 3: Integration Testing and Validation
dependencies: [1, 2]

**Objective**: Verify complete fix through integration testing

**Complexity**: Low

Tasks:
- [ ] Run existing state machine tests to ensure no regressions
- [ ] Test complete /build workflow with simple plan
- [ ] Verify state transitions succeed across all Parts (3, 4, 5, 6, 7)
- [ ] Verify no "STATE_FILE not set" errors in output
- [ ] Verify no "Invalid transition" errors in output
- [ ] Document fix in any relevant test output or debug reports

**Expected Duration**: 30-45 minutes

Testing:
```bash
# Run any existing state machine tests
if [ -f /home/benjamin/.config/.claude/tests/test_workflow_state_machine.sh ]; then
  bash /home/benjamin/.config/.claude/tests/test_workflow_state_machine.sh
fi

# Run any existing state persistence tests
if [ -f /home/benjamin/.config/.claude/tests/test_state_persistence.sh ]; then
  bash /home/benjamin/.config/.claude/tests/test_state_persistence.sh
fi

# Manual integration test: execute /build with minimal plan
# Verify output does not contain error messages
```

## Testing Strategy

### Unit Testing
- Test sm_transition() persists CURRENT_STATE correctly
- Test load_workflow_state() restores STATE_FILE variable
- Test STATE_FILE validation guard triggers on undefined variable

### Integration Testing
- Execute complete /build workflow with test plan
- Verify state transitions succeed: initialize -> implement -> test -> document -> complete
- Verify each Part loads correct state from previous Part

### Regression Testing
- Run all existing tests in .claude/tests/
- Verify no breaking changes to other commands using state machine

### Validation Criteria
- Zero "STATE_FILE not set" errors
- Zero "Invalid transition" errors
- All state transitions succeed
- Complete /build workflow succeeds

## Documentation Requirements

- [ ] Update any inline comments in modified code sections
- [ ] Add diagnostic comments explaining the subprocess isolation pattern
- [ ] No external documentation changes required (this is a bug fix)

## Dependencies

### Internal Dependencies
- state-persistence.sh: append_workflow_state(), load_workflow_state()
- workflow-state-machine.sh: sm_transition(), sm_init()
- build.md: Parts 3, 4, 5, 6, 7

### External Dependencies
- None

### Prerequisites
- Research report reviewed (001_state_persistence_analysis.md)
- Understanding of bash subprocess isolation pattern
