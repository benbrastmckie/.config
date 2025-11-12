#!/usr/bin/env bash
# Test suite for workflow-state-machine.sh
# Tests state initialization, transitions, validation, scope integration

set -euo pipefail

# Setup test environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the state machine library
source "$PROJECT_ROOT/lib/workflow-state-machine.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
assert_equals() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [ "$expected" = "$actual" ]; then
    echo "✓ PASS: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo "✗ FAIL: $test_name"
    echo "  Expected: $expected"
    echo "  Actual:   $actual"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if echo "$haystack" | grep -q "$needle"; then
    echo "✓ PASS: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo "✗ FAIL: $test_name"
    echo "  Expected to find: $needle"
    echo "  In: $haystack"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_success() {
  local test_name="$1"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [ $? -eq 0 ]; then
    echo "✓ PASS: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo "✗ FAIL: $test_name (command failed)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_failure() {
  local test_name="$1"
  local exit_code="$2"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [ "$exit_code" -ne 0 ]; then
    echo "✓ PASS: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo "✗ FAIL: $test_name (command should have failed)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# ==============================================================================
# Test Suite 1: State Initialization
# ==============================================================================

echo "=== Test Suite 1: State Initialization ==="

# Test 1.1: State constants defined
assert_equals "initialize" "$STATE_INITIALIZE" "State constant STATE_INITIALIZE defined"
assert_equals "research" "$STATE_RESEARCH" "State constant STATE_RESEARCH defined"
assert_equals "plan" "$STATE_PLAN" "State constant STATE_PLAN defined"
assert_equals "implement" "$STATE_IMPLEMENT" "State constant STATE_IMPLEMENT defined"
assert_equals "test" "$STATE_TEST" "State constant STATE_TEST defined"
assert_equals "debug" "$STATE_DEBUG" "State constant STATE_DEBUG defined"
assert_equals "document" "$STATE_DOCUMENT" "State constant STATE_DOCUMENT defined"
assert_equals "complete" "$STATE_COMPLETE" "State constant STATE_COMPLETE defined"

# Test 1.2: Transition table defined
assert_equals "research" "${STATE_TRANSITIONS[initialize]}" "Transition from initialize defined"
assert_contains "${STATE_TRANSITIONS[research]}" "plan" "Transition from research includes plan"
assert_contains "${STATE_TRANSITIONS[research]}" "complete" "Transition from research includes complete"

# Test 1.3: State machine initialization (research-only)
sm_init "Research authentication patterns" "coordinate" 2>/dev/null
assert_equals "initialize" "$CURRENT_STATE" "Initial state is initialize"
assert_equals "research-only" "$WORKFLOW_SCOPE" "Workflow scope detected as research-only"
assert_equals "research" "$TERMINAL_STATE" "Terminal state set to research for research-only"

# Test 1.4: State machine initialization (research-and-plan)
sm_init "Research authentication to create plan" "coordinate" 2>/dev/null
assert_equals "research-and-plan" "$WORKFLOW_SCOPE" "Workflow scope detected as research-and-plan"
assert_equals "plan" "$TERMINAL_STATE" "Terminal state set to plan for research-and-plan"

# Test 1.5: State machine initialization (full-implementation)
sm_init "Implement authentication system" "coordinate" 2>/dev/null
assert_equals "full-implementation" "$WORKFLOW_SCOPE" "Workflow scope detected as full-implementation"
assert_equals "complete" "$TERMINAL_STATE" "Terminal state set to complete for full-implementation"

# ==============================================================================
# Test Suite 2: State Transitions
# ==============================================================================

echo ""
echo "=== Test Suite 2: State Transitions ==="

# Test 2.1: Valid transition (initialize → research)
sm_init "Research authentication patterns" "coordinate" 2>/dev/null
sm_transition "$STATE_RESEARCH" 2>/dev/null
assert_success "Valid transition: initialize → research"
assert_equals "research" "$CURRENT_STATE" "Current state updated to research"

# Test 2.2: Invalid transition rejection (initialize → implement)
sm_init "Implement authentication" "coordinate" 2>/dev/null
exit_code=0
sm_transition "$STATE_IMPLEMENT" 2>/dev/null || exit_code=$?
assert_failure "Invalid transition rejected: initialize → implement" $exit_code

# Test 2.3: State history tracking
sm_init "Research authentication patterns" "coordinate" 2>/dev/null
sm_transition "$STATE_RESEARCH" 2>/dev/null
completed_count=$(sm_get_completed_count)
assert_equals "1" "$completed_count" "Completed states count incremented"

# Test 2.4: Multiple valid transitions
sm_init "Implement authentication system" "coordinate" 2>/dev/null
sm_transition "$STATE_RESEARCH" 2>/dev/null
sm_transition "$STATE_PLAN" 2>/dev/null
sm_transition "$STATE_IMPLEMENT" 2>/dev/null
assert_equals "implement" "$CURRENT_STATE" "Multiple transitions successful"
completed_count=$(sm_get_completed_count)
assert_equals "3" "$completed_count" "All transitions tracked in history"

# Test 2.5: Conditional transition (test → debug)
sm_init "Implement authentication system" "coordinate" 2>/dev/null
sm_transition "$STATE_RESEARCH" 2>/dev/null
sm_transition "$STATE_PLAN" 2>/dev/null
sm_transition "$STATE_IMPLEMENT" 2>/dev/null
sm_transition "$STATE_TEST" 2>/dev/null
sm_transition "$STATE_DEBUG" 2>/dev/null
assert_success "Conditional transition: test → debug"

# Test 2.6: Conditional transition (test → document)
sm_init "Implement authentication system" "coordinate" 2>/dev/null
sm_transition "$STATE_RESEARCH" 2>/dev/null
sm_transition "$STATE_PLAN" 2>/dev/null
sm_transition "$STATE_IMPLEMENT" 2>/dev/null
sm_transition "$STATE_TEST" 2>/dev/null
sm_transition "$STATE_DOCUMENT" 2>/dev/null
assert_success "Conditional transition: test → document"

# ==============================================================================
# Test Suite 3: Workflow Scope Configuration
# ==============================================================================

echo ""
echo "=== Test Suite 3: Workflow Scope Configuration ==="

# Test 3.1: Research-only scope limits transitions
sm_init "Research authentication patterns" "coordinate" 2>/dev/null
sm_transition "$STATE_RESEARCH" 2>/dev/null
is_terminal=$(sm_is_terminal && echo "yes" || echo "no")
assert_equals "yes" "$is_terminal" "Research state is terminal for research-only scope"

# Test 3.2: Research-and-plan scope terminates at plan
sm_init "Research authentication to create plan" "coordinate" 2>/dev/null
sm_transition "$STATE_RESEARCH" 2>/dev/null
sm_transition "$STATE_PLAN" 2>/dev/null
is_terminal=$(sm_is_terminal && echo "yes" || echo "no")
assert_equals "yes" "$is_terminal" "Plan state is terminal for research-and-plan scope"

# Test 3.3: Full-implementation scope terminates at complete
sm_init "Implement authentication system" "coordinate" 2>/dev/null
sm_transition "$STATE_RESEARCH" 2>/dev/null
sm_transition "$STATE_PLAN" 2>/dev/null
is_terminal=$(sm_is_terminal && echo "yes" || echo "no")
assert_equals "no" "$is_terminal" "Plan state is NOT terminal for full-implementation scope"

# ==============================================================================
# Test Suite 4: Checkpoint Save and Load
# ==============================================================================

echo ""
echo "=== Test Suite 4: Checkpoint Save and Load ==="

# Setup temp directory for checkpoints
TEST_CHECKPOINT_DIR=$(mktemp -d)
trap "rm -rf $TEST_CHECKPOINT_DIR" EXIT

# Test 4.1: Save state machine checkpoint
sm_init "Implement authentication system" "coordinate" 2>/dev/null
sm_transition "$STATE_RESEARCH" 2>/dev/null
sm_save "$TEST_CHECKPOINT_DIR/test_checkpoint.json" 2>/dev/null
[ -f "$TEST_CHECKPOINT_DIR/test_checkpoint.json" ]
assert_success "State machine checkpoint saved"

# Test 4.2: Checkpoint contains state machine fields
if command -v jq &> /dev/null; then
  current_state=$(jq -r '.current_state' "$TEST_CHECKPOINT_DIR/test_checkpoint.json")
  assert_equals "research" "$current_state" "Checkpoint contains current_state"

  workflow_scope=$(jq -r '.workflow_config.scope' "$TEST_CHECKPOINT_DIR/test_checkpoint.json")
  assert_equals "full-implementation" "$workflow_scope" "Checkpoint contains workflow scope"
fi

# Test 4.3: Load state machine checkpoint
# Reset state variables before loading checkpoint
CURRENT_STATE=""
WORKFLOW_SCOPE=""
COMPLETED_STATES=()
sm_load "$TEST_CHECKPOINT_DIR/test_checkpoint.json" 2>/dev/null
assert_equals "research" "$CURRENT_STATE" "State machine loaded from checkpoint"
assert_equals "full-implementation" "$WORKFLOW_SCOPE" "Workflow scope restored from checkpoint"

# ==============================================================================
# Test Suite 5: Phase-to-State Mapping (v1.3 Migration)
# ==============================================================================

echo ""
echo "=== Test Suite 5: Phase-to-State Mapping ==="

# Test 5.1: Phase number to state name mapping
assert_equals "initialize" "$(map_phase_to_state 0)" "Phase 0 maps to initialize"
assert_equals "research" "$(map_phase_to_state 1)" "Phase 1 maps to research"
assert_equals "plan" "$(map_phase_to_state 2)" "Phase 2 maps to plan"
assert_equals "implement" "$(map_phase_to_state 3)" "Phase 3 maps to implement"
assert_equals "test" "$(map_phase_to_state 4)" "Phase 4 maps to test"
assert_equals "debug" "$(map_phase_to_state 5)" "Phase 5 maps to debug"
assert_equals "document" "$(map_phase_to_state 6)" "Phase 6 maps to document"
assert_equals "complete" "$(map_phase_to_state 7)" "Phase 7 maps to complete"

# Test 5.2: State name to phase number mapping
assert_equals "0" "$(map_state_to_phase "$STATE_INITIALIZE")" "initialize maps to phase 0"
assert_equals "1" "$(map_state_to_phase "$STATE_RESEARCH")" "research maps to phase 1"
assert_equals "2" "$(map_state_to_phase "$STATE_PLAN")" "plan maps to phase 2"
assert_equals "3" "$(map_state_to_phase "$STATE_IMPLEMENT")" "implement maps to phase 3"
assert_equals "4" "$(map_state_to_phase "$STATE_TEST")" "test maps to phase 4"
assert_equals "5" "$(map_state_to_phase "$STATE_DEBUG")" "debug maps to phase 5"
assert_equals "6" "$(map_state_to_phase "$STATE_DOCUMENT")" "document maps to phase 6"
assert_equals "7" "$(map_state_to_phase "$STATE_COMPLETE")" "complete maps to phase 7"

# ==============================================================================
# Test Summary
# ==============================================================================

echo ""
echo "==================================="
echo "Test Summary"
echo "==================================="
echo "Tests Run:    $TESTS_RUN"
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"
echo "==================================="

if [ "$TESTS_FAILED" -eq 0 ]; then
  echo "✓ All tests passed!"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
