# Implementation Plan: Repair Error State Machine Fix

## Metadata

| Field | Value |
|-------|-------|
| Plan Number | 001 |
| Description | Fix state machine transition errors in /repair command |
| Complexity | 2 |
| Workflow Type | research-and-plan |
| Error Analysis | .claude/specs/915_repair_error_state_machine_fix/reports/001_error_analysis.md |
| Created | 2025-11-21 |

## Overview

### Problem Description

The `/repair` command is experiencing state machine transition failures with 5 cascading errors within a single workflow (`repair_1763769515`). The errors indicate:

1. **Primary Issue**: Attempted invalid state transition from `initialize` directly to `plan`
2. **Secondary Issues**: `CURRENT_STATE` not being set (uninitialized state machine)
3. **Cascading Failures**: Execution errors triggered by failed state transitions

### Root Cause Analysis

The state machine transition table defines:
```
[initialize] -> research, implement  (valid)
[research]   -> plan, complete       (valid)
```

The `/repair` command's workflow is `research-and-plan`:
- Block 1: `initialize -> research` (valid)
- Block 2: `research -> plan` (valid)

However, the errors show `initialize -> plan` was attempted, indicating:
1. **State persistence failure**: The `CURRENT_STATE` variable is not being persisted correctly between bash blocks
2. **State loading failure**: Block 2 is not loading the updated state from Block 1
3. **Missing STATE_FILE**: The `append_workflow_state` call for `CURRENT_STATE` in `sm_transition()` may be failing silently

### Solution Approach

1. **Phase 1**: Add missing `plan` transition to the state machine for `initialize` state OR ensure proper state persistence
2. **Phase 2**: Add defensive validation to detect and handle state persistence failures
3. **Phase 3**: Add tests to verify the fix

After analysis, the correct fix is to ensure state persistence is working correctly, NOT to add `initialize -> plan` to the transition table (that would violate the intended workflow semantics).

---

## Phase 1: Fix State Persistence in /repair Command

The actual issue is that the state machine's `CURRENT_STATE` is not being properly persisted and loaded between bash blocks in the `/repair` command.

### Stage 1.1: Verify State File Export Before sm_transition

**File**: `/home/benjamin/.config/.claude/commands/repair.md`

**Analysis**: The state machine's `sm_transition()` function requires `STATE_FILE` to be exported and valid. Block 1 initializes `STATE_FILE` but Block 2 may not be loading it correctly.

**Changes**:
1. In Block 2, after `load_workflow_state`, explicitly verify that `CURRENT_STATE` was loaded
2. Add diagnostic logging to understand the state before transition

**Code Change in Block 2** (approximately line 332-345):

Replace the state loading section with enhanced validation:

```bash
load_workflow_state "$WORKFLOW_ID" false

# === VERIFY CURRENT_STATE LOADED ===
# The state machine's CURRENT_STATE must be restored from state file
if [ -z "${CURRENT_STATE:-}" ]; then
  # Attempt to read directly from state file
  if [ -n "${STATE_FILE:-}" ] && [ -f "$STATE_FILE" ]; then
    CURRENT_STATE=$(grep "^CURRENT_STATE=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "")
  fi
fi

# Final validation - if still empty, we have a persistence problem
if [ -z "${CURRENT_STATE:-}" ]; then
  log_command_error \
    "${COMMAND_NAME:-/repair}" \
    "${WORKFLOW_ID:-unknown}" \
    "${USER_ARGS:-}" \
    "state_error" \
    "CURRENT_STATE not restored from workflow state - state persistence failure" \
    "bash_block_2" \
    "$(jq -n --arg file "${STATE_FILE:-MISSING}" '{state_file: $file}')"

  echo "ERROR: State machine state not persisted from Block 1" >&2
  echo "DIAGNOSTIC: STATE_FILE=${STATE_FILE:-MISSING}" >&2
  exit 1
fi

echo "DEBUG: Current state after load: ${CURRENT_STATE:-NOT_SET}" >&2
```

### Stage 1.2: Ensure CURRENT_STATE is Persisted After Transition

**File**: `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh`

**Analysis**: The `sm_transition()` function already calls `append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"` (line 694). However, this may be failing silently if `append_workflow_state` is not available.

**Changes**: Make the state persistence mandatory and fail if it doesn't work.

**Code Change** (approximately lines 692-696):

Replace:
```bash
  # Persist CURRENT_STATE to state file (following sm_init pattern)
  # This ensures subsequent bash blocks can read the correct state
  if command -v append_workflow_state &> /dev/null; then
    append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"
  fi
```

With:
```bash
  # Persist CURRENT_STATE to state file (following sm_init pattern)
  # This ensures subsequent bash blocks can read the correct state
  if command -v append_workflow_state &> /dev/null; then
    append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"
  else
    echo "WARNING: append_workflow_state not available - state may not persist across blocks" >&2
  fi

  # Export for immediate use in current block
  export CURRENT_STATE
```

### Stage 1.3: Add State Verification After Block 1 Transition

**File**: `/home/benjamin/.config/.claude/commands/repair.md`

**Changes**: After the `sm_transition "$STATE_RESEARCH"` call in Block 1, add verification:

**Code Change** (approximately lines 207-221):

After the existing transition code, add:
```bash
# Verify state was updated
if [ "$CURRENT_STATE" != "$STATE_RESEARCH" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State not updated after transition: expected $STATE_RESEARCH, got $CURRENT_STATE" \
    "bash_block_1" \
    "$(jq -n --arg expected "$STATE_RESEARCH" --arg actual "${CURRENT_STATE:-UNSET}" \
       '{expected_state: $expected, actual_state: $actual}')"

  echo "ERROR: State machine state not updated" >&2
  exit 1
fi

# Explicitly persist CURRENT_STATE (belt and suspenders)
append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"
```

---

## Phase 2: Add Defensive Validation

### Stage 2.1: Add Pre-Transition State Validation Function

**File**: `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh`

**Changes**: Add a helper function to validate state before transition:

**New Function** (add after `sm_transition` function, approximately line 722):

```bash
# sm_validate_state: Validate state machine is properly initialized
# Usage: sm_validate_state || exit 1
# Returns: 0 if valid, 1 if invalid
sm_validate_state() {
  local errors=0

  if [ -z "${STATE_FILE:-}" ]; then
    echo "ERROR: STATE_FILE not set" >&2
    errors=$((errors + 1))
  elif [ ! -f "$STATE_FILE" ]; then
    echo "ERROR: STATE_FILE does not exist: $STATE_FILE" >&2
    errors=$((errors + 1))
  fi

  if [ -z "${CURRENT_STATE:-}" ]; then
    echo "ERROR: CURRENT_STATE not set" >&2
    errors=$((errors + 1))
  fi

  if [ -z "${WORKFLOW_SCOPE:-}" ]; then
    echo "WARNING: WORKFLOW_SCOPE not set" >&2
    # Not a hard error, but worth noting
  fi

  if [ "$errors" -gt 0 ]; then
    echo "State validation failed with $errors errors" >&2
    return 1
  fi

  return 0
}

# Export the new function
export -f sm_validate_state
```

### Stage 2.2: Update Block 2 to Use State Validation

**File**: `/home/benjamin/.config/.claude/commands/repair.md`

**Changes**: Before the `sm_transition "$STATE_PLAN"` call in Block 2, add validation:

**Code Change** (approximately line 440, before the transition):

```bash
# Validate state machine before transition
if ! sm_validate_state; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State machine validation failed before PLAN transition" \
    "bash_block_2" \
    "$(jq -n --arg current "${CURRENT_STATE:-UNSET}" --arg state_file "${STATE_FILE:-UNSET}" \
       '{current_state: $current, state_file: $state_file}')"

  echo "ERROR: State machine not properly initialized" >&2
  exit 1
fi
```

### Stage 2.3: Improve Error Messages in sm_transition

**File**: `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh`

**Changes**: Enhance the error message for invalid transitions to include diagnostic suggestions:

**Code Change** (approximately lines 678-680):

Replace:
```bash
    echo "ERROR: Invalid transition: $CURRENT_STATE -> $next_state" >&2
    echo "Valid transitions from $CURRENT_STATE: $valid_transitions" >&2
    return 1
```

With:
```bash
    echo "ERROR: Invalid transition: $CURRENT_STATE -> $next_state" >&2
    echo "Valid transitions from $CURRENT_STATE: $valid_transitions" >&2
    echo "DIAGNOSTIC: If CURRENT_STATE seems wrong, check state persistence between blocks" >&2
    echo "DIAGNOSTIC: Verify load_workflow_state() was called and STATE_FILE is set" >&2
    return 1
```

---

## Phase 3: Testing

### Stage 3.1: Create Unit Test for State Persistence

**File**: `/home/benjamin/.config/.claude/tests/unit/test_state_persistence_across_blocks.sh`

**Changes**: Create a new test file to verify state persistence:

```bash
#!/usr/bin/env bash
# Test: State persistence across bash blocks
# Verifies that CURRENT_STATE persists correctly between blocks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/core/state-persistence.sh"
source "$SCRIPT_DIR/../../lib/workflow/workflow-state-machine.sh"

TEST_PASSED=0
TEST_FAILED=0

test_state_persists_after_transition() {
  local test_name="State persists after sm_transition"

  # Setup
  local test_workflow_id="test_$(date +%s)"
  STATE_FILE=$(init_workflow_state "$test_workflow_id")
  export STATE_FILE

  # Initialize state machine
  sm_init "test workflow" "test_command" "research-and-plan" "2" "[]" >/dev/null 2>&1

  # Verify initial state
  if [ "$CURRENT_STATE" != "initialize" ]; then
    echo "FAIL: $test_name - Initial state not 'initialize': $CURRENT_STATE"
    TEST_FAILED=$((TEST_FAILED + 1))
    return 1
  fi

  # Transition to research
  sm_transition "$STATE_RESEARCH" >/dev/null 2>&1

  # Verify state updated
  if [ "$CURRENT_STATE" != "research" ]; then
    echo "FAIL: $test_name - State not updated to 'research': $CURRENT_STATE"
    TEST_FAILED=$((TEST_FAILED + 1))
    return 1
  fi

  # Verify state persisted to file
  local persisted_state
  persisted_state=$(grep "^CURRENT_STATE=" "$STATE_FILE" | tail -1 | cut -d'=' -f2-)

  if [ "$persisted_state" != "research" ]; then
    echo "FAIL: $test_name - State not persisted correctly: $persisted_state"
    TEST_FAILED=$((TEST_FAILED + 1))
    return 1
  fi

  # Simulate new block by clearing and reloading
  CURRENT_STATE=""
  load_workflow_state "$test_workflow_id" false

  # Verify state restored
  if [ "${CURRENT_STATE:-}" != "research" ]; then
    echo "FAIL: $test_name - State not restored after load: ${CURRENT_STATE:-EMPTY}"
    TEST_FAILED=$((TEST_FAILED + 1))
    return 1
  fi

  echo "PASS: $test_name"
  TEST_PASSED=$((TEST_PASSED + 1))

  # Cleanup
  rm -f "$STATE_FILE"
  return 0
}

# Run tests
echo "=== State Persistence Tests ==="
test_state_persists_after_transition

echo ""
echo "Results: $TEST_PASSED passed, $TEST_FAILED failed"
exit $TEST_FAILED
```

### Stage 3.2: Integration Test for /repair Workflow

**File**: `/home/benjamin/.config/.claude/tests/integration/test_repair_state_transitions.sh`

**Changes**: Create an integration test that verifies the full workflow:

```bash
#!/usr/bin/env bash
# Test: /repair command state transitions
# Verifies that /repair properly transitions through states

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
export CLAUDE_PROJECT_DIR

source "$CLAUDE_PROJECT_DIR/lib/core/state-persistence.sh"
source "$CLAUDE_PROJECT_DIR/lib/workflow/workflow-state-machine.sh"

echo "=== /repair State Transition Integration Test ==="

# Test the state machine transition sequence for research-and-plan workflow
test_research_and_plan_transitions() {
  local test_name="/repair research-and-plan transition sequence"

  # Setup
  local test_workflow_id="repair_test_$(date +%s)"
  STATE_FILE=$(init_workflow_state "$test_workflow_id")
  export STATE_FILE

  # Initialize (simulating Block 1)
  sm_init "test error repair" "/repair" "research-and-plan" "2" "[]" >/dev/null 2>&1

  if [ "$CURRENT_STATE" != "initialize" ]; then
    echo "FAIL: $test_name - Expected initialize, got $CURRENT_STATE"
    return 1
  fi

  # Transition to research (Block 1 end)
  if ! sm_transition "$STATE_RESEARCH" 2>&1; then
    echo "FAIL: $test_name - Failed transition initialize -> research"
    return 1
  fi

  if [ "$CURRENT_STATE" != "research" ]; then
    echo "FAIL: $test_name - Expected research, got $CURRENT_STATE"
    return 1
  fi

  # Simulate Block 2 - reload state
  CURRENT_STATE=""
  load_workflow_state "$test_workflow_id" false

  if [ "${CURRENT_STATE:-}" != "research" ]; then
    echo "FAIL: $test_name - State not restored: expected research, got ${CURRENT_STATE:-EMPTY}"
    return 1
  fi

  # Transition to plan (Block 2)
  if ! sm_transition "$STATE_PLAN" 2>&1; then
    echo "FAIL: $test_name - Failed transition research -> plan"
    return 1
  fi

  if [ "$CURRENT_STATE" != "plan" ]; then
    echo "FAIL: $test_name - Expected plan, got $CURRENT_STATE"
    return 1
  fi

  # Transition to complete (Block 3)
  if ! sm_transition "$STATE_COMPLETE" 2>&1; then
    echo "FAIL: $test_name - Failed transition plan -> complete"
    return 1
  fi

  echo "PASS: $test_name"

  # Cleanup
  rm -f "$STATE_FILE"
  return 0
}

# Test invalid transition is rejected
test_invalid_transition_rejected() {
  local test_name="Invalid initialize -> plan transition rejected"

  # Setup
  local test_workflow_id="repair_invalid_$(date +%s)"
  STATE_FILE=$(init_workflow_state "$test_workflow_id")
  export STATE_FILE

  sm_init "test" "/repair" "research-and-plan" "2" "[]" >/dev/null 2>&1

  # Attempt invalid transition (this should fail)
  if sm_transition "$STATE_PLAN" 2>/dev/null; then
    echo "FAIL: $test_name - Invalid transition was allowed"
    rm -f "$STATE_FILE"
    return 1
  fi

  echo "PASS: $test_name"

  # Cleanup
  rm -f "$STATE_FILE"
  return 0
}

# Run tests
test_research_and_plan_transitions || exit 1
test_invalid_transition_rejected || exit 1

echo ""
echo "All tests passed"
```

---

## Verification Checklist

After implementing all phases, verify:

- [ ] Block 1 of `/repair` transitions `initialize -> research` and state persists
- [ ] Block 2 of `/repair` loads state correctly and `CURRENT_STATE` is "research"
- [ ] Block 2 of `/repair` transitions `research -> plan` successfully
- [ ] Block 3 of `/repair` transitions `plan -> complete` successfully
- [ ] Unit tests pass (`test_state_persistence_across_blocks.sh`)
- [ ] Integration tests pass (`test_repair_state_transitions.sh`)
- [ ] Run `/repair --command /repair` with no state transition errors

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| State file corruption | Low | High | Added validation and backup reads |
| Breaking other commands | Low | Medium | Changes scoped to /repair and defensive additions |
| Test environment differences | Low | Low | Tests use isolated workflow IDs |

## Rollback Plan

If issues arise:
1. Revert changes to `repair.md`
2. Revert changes to `workflow-state-machine.sh` (specifically the sm_validate_state function)
3. Remove new test files

The core state machine logic remains unchanged - all modifications are defensive additions.
