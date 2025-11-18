# State Machine Persistence Bug Fix Plan - Multi-Command

## Metadata
- **Date**: 2025-11-17
- **Feature**: State Machine Persistence Bug Fix (build.md, debug.md, revise.md)
- **Scope**: Fix STATE_FILE and CURRENT_STATE persistence across bash subprocess boundaries in /build, /debug, and /revise commands
- **Estimated Phases**: 3
- **Estimated Hours**: 3-4
- **Structure Level**: 0
- **Complexity Score**: 24
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [State Persistence Analysis](/home/benjamin/.config/.claude/specs/787_state_machine_persistence_bug/reports/001_state_persistence_analysis.md)
  - [State Persistence Bug Analysis](/home/benjamin/.config/.claude/specs/787_state_machine_persistence_bug/reports/001_state_persistence_bug_analysis.md)

## Overview

This plan addresses critical bugs in three orchestration commands (/build, /debug, /revise) where state machine transitions succeed in memory but fail across bash subprocess boundaries. The research identified:

1. **build.md Part 4** (HIGH PRIORITY): Missing `load_workflow_state()` before `sm_transition($STATE_IMPLEMENT)`
2. **debug.md Part 3** (MEDIUM PRIORITY): Missing `load_workflow_state()` before `sm_transition($STATE_RESEARCH)`
3. **revise.md Part 3** (MEDIUM PRIORITY): Missing `load_workflow_state()` before `sm_transition($STATE_RESEARCH)`
4. **workflow-state-machine.sh** (ALL COMMANDS): `sm_transition()` updates CURRENT_STATE in memory but does not persist to state file

The combined effect causes subsequent Parts to read stale state from the state file, resulting in "Invalid transition" errors even though the in-memory state was correctly updated.

## Research Summary

Key findings from both research reports:

### From State Persistence Analysis Report
- **Root Cause 1**: Part 4 sources libraries but never calls `load_workflow_state()` to restore STATE_FILE variable. Parts 5, 6, and 7 correctly call this function.
- **Root Cause 2**: `sm_transition()` at line 625 updates CURRENT_STATE in memory but does not persist it. In contrast, `sm_init()` (lines 497-503) correctly persists both TERMINAL_STATE and CURRENT_STATE.
- **Impact**: Part 4 transitions to "implement" in memory but fails to write to state file. Part 5 loads stale "initialize" state and fails transition.
- **Evidence**: Error messages "STATE_FILE not set" and "Invalid transition: initialize -> test"

### From State Persistence Bug Analysis Report
- **Additional Commands Affected**: Analysis of 6 orchestration commands revealed debug.md Part 3 and revise.md Part 3 have the same missing `load_workflow_state()` bug pattern
- **Pattern**: All affected commands source libraries but fail to call `load_workflow_state()` before `sm_transition()`
- **Commands Already Correct**: coordinate.md, plan.md, and research.md properly implement the pattern throughout

Recommended approach: Fix all three commands together with the sm_transition() persistence fix since they are interdependent.

## Success Criteria

- [ ] Part 4 of build.md correctly loads workflow state before calling `sm_transition()`
- [ ] Part 3 of debug.md correctly loads workflow state before calling `sm_transition()`
- [ ] Part 3 of revise.md correctly loads workflow state before calling `sm_transition()`
- [ ] `sm_transition()` persists CURRENT_STATE to state file after updating in memory
- [ ] STATE_FILE variable is defined in all affected subprocess when `sm_transition()` is called
- [ ] Complete /build workflow executes without state transition errors
- [ ] Complete /debug workflow executes without state transition errors
- [ ] Complete /revise workflow executes without state transition errors
- [ ] Subsequent Parts in all commands read correct CURRENT_STATE from state file
- [ ] Error message "STATE_FILE not set" no longer appears in output
- [ ] Error message "Invalid transition" no longer appears
- [ ] All existing tests pass after changes

## Technical Design

### Architecture Overview

The orchestration commands use bash subprocess isolation, where each Part runs in a separate shell context. State is shared via a file-based persistence mechanism:

```
Part N (sm_transition before)    Part N+1 (sm_transition after)
┌─────────────────────────┐      ┌─────────────────────────┐
│ source libraries        │      │ source libraries        │
│ load_state() [MISSING]  │      │ load_state()            │
│ sm_transition()         │ ──>  │ sm_transition()         │
│ persist STATE [MISSING] │      │ persist STATE           │
└─────────────────────────┘      └─────────────────────────┘
        │                                │
        v                                v
   STATE_FILE:                      STATE_FILE:
   CURRENT_STATE=stale             CURRENT_STATE=correct
```

### Affected Commands Summary

| Command | Part | Line Numbers | State Transition | Priority |
|---------|------|-------------|------------------|----------|
| build.md | Part 4 | 305-310 | $STATE_IMPLEMENT | HIGH |
| debug.md | Part 3 | 216-224 | $STATE_RESEARCH | MEDIUM |
| revise.md | Part 3 | 213-216 | $STATE_RESEARCH | MEDIUM |

### Fix Strategy

**Fix 1 - Load State in build.md Part 4**:
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

**Fix 2 - Load State in debug.md Part 3**:
Add workflow state loading after sourcing libraries:
```bash
# After sourcing libraries in Part 3
STATE_ID_FILE="${HOME}/.claude/tmp/debug_state_id.txt"
if [ -f "$STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$STATE_ID_FILE")
  export WORKFLOW_ID
  load_workflow_state "$WORKFLOW_ID" false
fi
```

**Fix 3 - Load State in revise.md Part 3**:
Add workflow state loading after sourcing libraries:
```bash
# After sourcing libraries in Part 3
STATE_ID_FILE="${HOME}/.claude/tmp/revise_state_id.txt"
if [ ! -f "$STATE_ID_FILE" ]; then
  echo "ERROR: WORKFLOW_ID file not found: $STATE_ID_FILE" >&2
  exit 1
fi
WORKFLOW_ID=$(cat "$STATE_ID_FILE")
export WORKFLOW_ID
load_workflow_state "$WORKFLOW_ID" false
```

**Fix 4 - Persist CURRENT_STATE in sm_transition()** (workflow-state-machine.sh):
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

### Phase 1: Core Bug Fixes - All Commands
dependencies: []

**Objective**: Apply the critical fixes to resolve state persistence bugs in all three affected commands

**Complexity**: Medium

Tasks:
- [ ] Add WORKFLOW_ID loading to Part 4 of build.md after line 307
- [ ] Add load_workflow_state() call to Part 4 of build.md
- [ ] Add WORKFLOW_ID loading to Part 3 of debug.md after sourcing libraries (around line 219)
- [ ] Add load_workflow_state() call to Part 3 of debug.md
- [ ] Add WORKFLOW_ID loading to Part 3 of revise.md after line 213
- [ ] Add load_workflow_state() call to Part 3 of revise.md
- [ ] Add CURRENT_STATE persistence to sm_transition() after line 625
- [ ] Ensure persistence call follows same pattern as sm_init() (lines 497-503)

**Expected Duration**: 45-60 minutes

Testing:
```bash
# Verify syntax after edits
bash -n /home/benjamin/.config/.claude/commands/build.md 2>&1 | head -20
bash -n /home/benjamin/.config/.claude/commands/debug.md 2>&1 | head -20
bash -n /home/benjamin/.config/.claude/commands/revise.md 2>&1 | head -20
bash -n /home/benjamin/.config/.claude/lib/workflow-state-machine.sh
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

**Objective**: Verify complete fix through integration testing for all three commands

**Complexity**: Medium

Tasks:
- [ ] Run existing state machine tests to ensure no regressions
- [ ] Test complete /build workflow with simple plan
- [ ] Verify state transitions succeed across all Parts in /build (3, 4, 5, 6, 7)
- [ ] Test /debug workflow to verify state transitions
- [ ] Test /revise workflow to verify state transitions
- [ ] Verify no "STATE_FILE not set" errors in output for any command
- [ ] Verify no "Invalid transition" errors in output for any command
- [ ] Document fix results in debug report if created

**Expected Duration**: 45-60 minutes

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

# Test /debug workflow
# Verify state transitions succeed

# Test /revise workflow
# Verify state transitions succeed
```

## Testing Strategy

### Unit Testing
- Test sm_transition() persists CURRENT_STATE correctly
- Test load_workflow_state() restores STATE_FILE variable
- Test STATE_FILE validation guard triggers on undefined variable

### Integration Testing
- Execute complete /build workflow with test plan
- Verify state transitions succeed: initialize -> implement -> test -> document -> complete
- Execute /debug workflow and verify state transitions
- Execute /revise workflow and verify state transitions
- Verify each Part in each command loads correct state from previous Part

### Regression Testing
- Run all existing tests in .claude/tests/
- Verify no breaking changes to other commands using state machine
- Verify coordinate.md, plan.md, and research.md still work correctly

### Validation Criteria
- Zero "STATE_FILE not set" errors in any command
- Zero "Invalid transition" errors in any command
- All state transitions succeed in all three commands
- Complete workflows succeed for /build, /debug, /revise

## Documentation Requirements

- [ ] Update any inline comments in modified code sections
- [ ] Add diagnostic comments explaining the subprocess isolation pattern
- [ ] Document the standard state loading pattern for future reference
- [ ] No external documentation changes required (this is a bug fix)

## Dependencies

### Internal Dependencies
- state-persistence.sh: append_workflow_state(), load_workflow_state()
- workflow-state-machine.sh: sm_transition(), sm_init()
- build.md: Parts 3, 4, 5, 6, 7
- debug.md: Parts 2a, 3, 4, 5, 6
- revise.md: Parts 3, 4, 5

### External Dependencies
- None

### Prerequisites
- Research reports reviewed (001_state_persistence_analysis.md, 001_state_persistence_bug_analysis.md)
- Understanding of bash subprocess isolation pattern

## Risk Management

### Identified Risks

1. **Modification of multiple commands**: Changes to three commands increases risk of introducing new bugs
   - Mitigation: Use identical pattern from already-working Parts in each command

2. **State file corruption**: Appending CURRENT_STATE multiple times could cause issues
   - Mitigation: append_workflow_state() handles overwrites correctly for existing variables

3. **Backward compatibility**: Other parts of commands may rely on current behavior
   - Mitigation: All later Parts already follow the pattern we're adding

### Rollback Strategy

If issues occur:
1. Restore from backup at /home/benjamin/.config/.claude/specs/787_state_machine_persistence_bug/plans/backups/001_state_machine_persistence_fix_plan_20251117_235337.md
2. Use git to revert changes to command files
3. Re-run tests to verify original behavior restored
