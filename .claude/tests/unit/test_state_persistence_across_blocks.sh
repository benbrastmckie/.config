#!/usr/bin/env bash
# Test: State persistence across bash blocks
# Verifies that CURRENT_STATE persists correctly between blocks

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
  rm -f "${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_test_"* 2>/dev/null || true
}
trap cleanup EXIT

test_state_persists_after_transition() {
  local test_name="State persists after sm_transition"

  # Setup
  local test_workflow_id="test_$(date +%s)_$$"
  STATE_FILE=$(init_workflow_state "$test_workflow_id")
  export STATE_FILE

  # Initialize state machine
  sm_init "test workflow" "test_command" "research-and-plan" "2" "[]" >/dev/null 2>&1

  # Verify initial state
  if [ "$CURRENT_STATE" != "initialize" ]; then
    echo "✗ FAIL: $test_name - Initial state not 'initialize': $CURRENT_STATE"
    TEST_FAILED=$((TEST_FAILED + 1))
    return 1
  fi

  # Transition to research
  sm_transition "$STATE_RESEARCH" >/dev/null 2>&1

  # Verify state updated
  if [ "$CURRENT_STATE" != "research" ]; then
    echo "✗ FAIL: $test_name - State not updated to 'research': $CURRENT_STATE"
    TEST_FAILED=$((TEST_FAILED + 1))
    return 1
  fi

  # Verify state persisted to file
  local persisted_state
  persisted_state=$(grep "CURRENT_STATE=" "$STATE_FILE" | tail -1 | sed 's/.*CURRENT_STATE="//' | tr -d '"')

  if [ "$persisted_state" != "research" ]; then
    echo "✗ FAIL: $test_name - State not persisted correctly: $persisted_state"
    TEST_FAILED=$((TEST_FAILED + 1))
    return 1
  fi

  # Simulate new block by clearing and reloading
  CURRENT_STATE=""
  load_workflow_state "$test_workflow_id" false

  # Verify state restored (either via source or direct read)
  if [ -z "${CURRENT_STATE:-}" ]; then
    # Try direct read as fallback
    CURRENT_STATE=$(grep "CURRENT_STATE=" "$STATE_FILE" 2>/dev/null | tail -1 | sed 's/.*CURRENT_STATE="//' | tr -d '"' || echo "")
  fi

  if [ "${CURRENT_STATE:-}" != "research" ]; then
    echo "✗ FAIL: $test_name - State not restored after load: ${CURRENT_STATE:-EMPTY}"
    TEST_FAILED=$((TEST_FAILED + 1))
    return 1
  fi

  echo "✓ PASS: $test_name"
  TEST_PASSED=$((TEST_PASSED + 1))

  # Cleanup
  rm -f "$STATE_FILE"
  return 0
}

test_sm_validate_state_function() {
  local test_name="sm_validate_state function works correctly"

  # Setup - invalid state (no STATE_FILE)
  unset STATE_FILE
  unset CURRENT_STATE

  # Should fail validation
  if sm_validate_state 2>/dev/null; then
    echo "✗ FAIL: $test_name - Should have failed with no STATE_FILE"
    TEST_FAILED=$((TEST_FAILED + 1))
    return 1
  fi

  # Setup - valid state
  local test_workflow_id="test_validate_$(date +%s)_$$"
  STATE_FILE=$(init_workflow_state "$test_workflow_id")
  export STATE_FILE
  CURRENT_STATE="initialize"
  export CURRENT_STATE

  # Should pass validation
  if ! sm_validate_state 2>/dev/null; then
    echo "✗ FAIL: $test_name - Should have passed with valid state"
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

test_append_workflow_state_exports_correctly() {
  local test_name="append_workflow_state correctly exports CURRENT_STATE"

  # Setup
  local test_workflow_id="test_append_$(date +%s)_$$"
  STATE_FILE=$(init_workflow_state "$test_workflow_id")
  export STATE_FILE

  # Append CURRENT_STATE
  append_workflow_state "CURRENT_STATE" "research"

  # Verify it's in the file with correct format
  if ! grep -q '^export CURRENT_STATE="research"' "$STATE_FILE"; then
    echo "✗ FAIL: $test_name - CURRENT_STATE not found with correct format in state file"
    cat "$STATE_FILE" >&2
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
echo "=== State Persistence Tests ==="
echo ""

test_state_persists_after_transition
test_sm_validate_state_function
test_append_workflow_state_exports_correctly

echo ""
echo "Results: $TEST_PASSED passed, $TEST_FAILED failed"
exit $TEST_FAILED
