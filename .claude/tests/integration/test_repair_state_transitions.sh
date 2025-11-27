#!/usr/bin/env bash
# Test: /repair command state transitions
# Verifies that /repair properly transitions through states

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Detect project root correctly (git root or parent with .claude directory)
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  # Walk up to find .claude directory
  CLAUDE_PROJECT_DIR="$SCRIPT_DIR"
  while [ "$CLAUDE_PROJECT_DIR" != "/" ]; do
    if [ -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
      break
    fi
    CLAUDE_PROJECT_DIR="$(dirname "$CLAUDE_PROJECT_DIR")"
  done
fi
export CLAUDE_PROJECT_DIR

# Source required libraries
CLAUDE_LIB="${CLAUDE_PROJECT_DIR}/.claude/lib"
source "$CLAUDE_LIB/core/state-persistence.sh"
source "$CLAUDE_LIB/workflow/workflow-state-machine.sh"

TEST_PASSED=0
TEST_FAILED=0

cleanup() {
  # Clean up any test state files
  rm -f "${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_repair_"* 2>/dev/null || true
}
trap cleanup EXIT

echo "=== /repair State Transition Integration Test ==="
echo ""

# Test the state machine transition sequence for research-and-plan workflow
test_research_and_plan_transitions() {
  local test_name="/repair research-and-plan transition sequence"

  # Setup
  local test_workflow_id="repair_test_$(date +%s)_$$"
  STATE_FILE=$(init_workflow_state "$test_workflow_id")
  export STATE_FILE

  # Initialize (simulating Block 1)
  sm_init "test error repair" "/repair" "research-and-plan" "2" "[]" >/dev/null 2>&1

  if [ "$CURRENT_STATE" != "initialize" ]; then
    echo "✗ FAIL: $test_name - Expected initialize, got $CURRENT_STATE"
    TEST_FAILED=$((TEST_FAILED + 1))
    rm -f "$STATE_FILE"
    return 1
  fi

  # Transition to research (Block 1 end)
  if ! sm_transition "$STATE_RESEARCH" 2>&1; then
    echo "✗ FAIL: $test_name - Failed transition initialize -> research"
    TEST_FAILED=$((TEST_FAILED + 1))
    rm -f "$STATE_FILE"
    return 1
  fi

  if [ "$CURRENT_STATE" != "research" ]; then
    echo "✗ FAIL: $test_name - Expected research, got $CURRENT_STATE"
    TEST_FAILED=$((TEST_FAILED + 1))
    rm -f "$STATE_FILE"
    return 1
  fi

  # Verify state persisted
  local persisted_state
  persisted_state=$(grep "CURRENT_STATE=" "$STATE_FILE" | tail -1 | sed 's/.*CURRENT_STATE="//' | tr -d '"')
  if [ "$persisted_state" != "research" ]; then
    echo "✗ FAIL: $test_name - State not persisted after initialize->research transition"
    TEST_FAILED=$((TEST_FAILED + 1))
    rm -f "$STATE_FILE"
    return 1
  fi

  # Simulate Block 2 - reload state
  CURRENT_STATE=""
  load_workflow_state "$test_workflow_id" false

  # Read CURRENT_STATE from file if not set by load_workflow_state
  if [ -z "${CURRENT_STATE:-}" ]; then
    CURRENT_STATE=$(grep "CURRENT_STATE=" "$STATE_FILE" 2>/dev/null | tail -1 | sed 's/.*CURRENT_STATE="//' | tr -d '"' || echo "")
  fi

  if [ "${CURRENT_STATE:-}" != "research" ]; then
    echo "✗ FAIL: $test_name - State not restored: expected research, got ${CURRENT_STATE:-EMPTY}"
    TEST_FAILED=$((TEST_FAILED + 1))
    rm -f "$STATE_FILE"
    return 1
  fi

  # Transition to plan (Block 2)
  if ! sm_transition "$STATE_PLAN" 2>&1; then
    echo "✗ FAIL: $test_name - Failed transition research -> plan"
    TEST_FAILED=$((TEST_FAILED + 1))
    rm -f "$STATE_FILE"
    return 1
  fi

  if [ "$CURRENT_STATE" != "plan" ]; then
    echo "✗ FAIL: $test_name - Expected plan, got $CURRENT_STATE"
    TEST_FAILED=$((TEST_FAILED + 1))
    rm -f "$STATE_FILE"
    return 1
  fi

  # Transition to complete (Block 3)
  if ! sm_transition "$STATE_COMPLETE" 2>&1; then
    echo "✗ FAIL: $test_name - Failed transition plan -> complete"
    TEST_FAILED=$((TEST_FAILED + 1))
    rm -f "$STATE_FILE"
    return 1
  fi

  echo "✓ PASS: $test_name"
  TEST_PASSED=$((TEST_PASSED + 1))

  # Cleanup
  rm -f "$STATE_FILE"
  return 0
}

# Test invalid transition is rejected
test_invalid_transition_rejected() {
  local test_name="Invalid initialize -> plan transition rejected"

  # Setup
  local test_workflow_id="repair_invalid_$(date +%s)_$$"
  STATE_FILE=$(init_workflow_state "$test_workflow_id")
  export STATE_FILE

  sm_init "test" "/repair" "research-and-plan" "2" "[]" >/dev/null 2>&1

  # Attempt invalid transition (this should fail)
  if sm_transition "$STATE_PLAN" 2>/dev/null; then
    echo "✗ FAIL: $test_name - Invalid transition was allowed"
    rm -f "$STATE_FILE"
    TEST_FAILED=$((TEST_FAILED + 1))
    return 1
  fi

  echo "✓ PASS: $test_name"
  TEST_PASSED=$((TEST_PASSED + 1))

  # Cleanup
  rm -f "$STATE_FILE"
  return 0
}

# Test sm_validate_state integration
test_sm_validate_state_integration() {
  local test_name="sm_validate_state correctly validates state machine"

  # Setup - properly initialized state
  local test_workflow_id="repair_validate_$(date +%s)_$$"
  STATE_FILE=$(init_workflow_state "$test_workflow_id")
  export STATE_FILE

  sm_init "test" "/repair" "research-and-plan" "2" "[]" >/dev/null 2>&1

  # Should pass validation
  if ! sm_validate_state 2>/dev/null; then
    echo "✗ FAIL: $test_name - Validation should pass for initialized state machine"
    rm -f "$STATE_FILE"
    TEST_FAILED=$((TEST_FAILED + 1))
    return 1
  fi

  # Simulate corrupted state (CURRENT_STATE empty)
  local saved_state="$CURRENT_STATE"
  unset CURRENT_STATE

  # Should fail validation
  if sm_validate_state 2>/dev/null; then
    echo "✗ FAIL: $test_name - Validation should fail with empty CURRENT_STATE"
    CURRENT_STATE="$saved_state"
    rm -f "$STATE_FILE"
    TEST_FAILED=$((TEST_FAILED + 1))
    return 1
  fi

  echo "✓ PASS: $test_name"
  TEST_PASSED=$((TEST_PASSED + 1))

  # Cleanup
  rm -f "$STATE_FILE"
  return 0
}

# Run tests
test_research_and_plan_transitions
test_invalid_transition_rejected
test_sm_validate_state_integration

echo ""
echo "Results: $TEST_PASSED passed, $TEST_FAILED failed"
exit $TEST_FAILED
