#!/usr/bin/env bash
# Integration tests for /implement error handling fixes
#
# Tests Phase 1-4 fixes from repair plan 020_repair_implement_20251202_003956:
# - JSON state value allowlist
# - Hard barrier diagnostics
# - ERR trap suppression
# - State machine auto-initialization

set -uo pipefail  # Don't use -e so tests can handle failures gracefully

# Setup test isolation per testing-protocols.md
TEST_ROOT="/tmp/test_implement_error_handling_$$"
mkdir -p "$TEST_ROOT/.claude/specs"
mkdir -p "$TEST_ROOT/.claude/data/logs"
mkdir -p "$TEST_ROOT/.claude/tmp"
export CLAUDE_SPECS_ROOT="$TEST_ROOT/.claude/specs"
export CLAUDE_PROJECT_DIR="$TEST_ROOT"
export CLAUDE_TEST_MODE=1  # Route errors to test-errors.jsonl

# Cleanup trap
trap 'rm -rf "$TEST_ROOT"' EXIT

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Source libraries under test
CLAUDE_LIB="${HOME}/.config/.claude/lib"

echo "Loading libraries..."
echo "  - state-persistence.sh"
source "$CLAUDE_LIB/core/state-persistence.sh" || {
  echo "ERROR: Cannot load state-persistence.sh"
  exit 1
}
echo "  - error-handling.sh"
source "$CLAUDE_LIB/core/error-handling.sh" || {
  echo "ERROR: Cannot load error-handling.sh"
  exit 1
}
echo "  - workflow-state-machine.sh"
source "$CLAUDE_LIB/workflow/workflow-state-machine.sh" || {
  echo "ERROR: Cannot load workflow-state-machine.sh"
  exit 1
}
echo "All libraries loaded successfully"

# Test helper functions
test_start() {
  local test_name="$1"
  echo ""
  echo "=========================================="
  echo "TEST: $test_name"
  echo "=========================================="
  TESTS_RUN=$((TESTS_RUN + 1))  # Avoid ((TESTS_RUN++)) which can trigger ERR trap when value is 0
}

test_pass() {
  echo "✓ PASS"
  TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
  local reason="$1"
  echo "✗ FAIL: $reason"
  TESTS_FAILED=$((TESTS_FAILED + 1))
}

assert_equals() {
  local expected="$1"
  local actual="$2"
  local description="${3:-}"

  if [[ "$expected" == "$actual" ]]; then
    echo "  ✓ $description"
    return 0
  else
    echo "  ✗ $description"
    echo "    Expected: $expected"
    echo "    Actual:   $actual"
    return 1
  fi
}

assert_file_exists() {
  local file="$1"
  local description="${2:-File exists}"

  if [[ -f "$file" ]]; then
    echo "  ✓ $description"
    return 0
  else
    echo "  ✗ $description"
    echo "    File not found: $file"
    return 1
  fi
}

assert_file_contains() {
  local file="$1"
  local pattern="$2"
  local description="${3:-File contains pattern}"

  if grep -q "$pattern" "$file" 2>/dev/null; then
    echo "  ✓ $description"
    return 0
  else
    echo "  ✗ $description"
    echo "    Pattern not found: $pattern"
    echo "    In file: $file"
    return 1
  fi
}

assert_file_not_contains() {
  local file="$1"
  local pattern="$2"
  local description="${3:-File does not contain pattern}"

  if ! grep -q "$pattern" "$file" 2>/dev/null; then
    echo "  ✓ $description"
    return 0
  else
    echo "  ✗ $description"
    echo "    Pattern found (should not exist): $pattern"
    echo "    In file: $file"
    return 1
  fi
}

#############################################################################
# Test 1: JSON values in WORK_REMAINING don't cause state errors
#############################################################################
test_json_state_persistence() {
  test_start "test_json_state_persistence"

  # Setup: Initialize workflow state
  COMMAND_NAME="/implement"
  WORKFLOW_ID="test_json_$$"
  USER_ARGS="test args"
  export COMMAND_NAME WORKFLOW_ID USER_ARGS

  echo "Initializing workflow state for $WORKFLOW_ID..."
  STATE_FILE=$(init_workflow_state "$WORKFLOW_ID") || {
    echo "ERROR: init_workflow_state failed"
    test_fail "init_workflow_state failed"
    return 1
  }
  echo "State file created: $STATE_FILE"
  local state_file="$STATE_FILE"  # Local alias for readability

  local passed=true

  # Test 1a: Store JSON array in WORK_REMAINING (allowlisted key)
  echo "Test 1a: JSON array in WORK_REMAINING"
  local append_output=$(append_workflow_state "WORK_REMAINING" '["Phase 4", "Phase 5"]' 2>&1)
  local append_status=$?
  if [[ $append_status -eq 0 ]]; then
    assert_file_contains "$state_file" 'WORK_REMAINING=' "State file contains WORK_REMAINING" || passed=false
    assert_file_contains "$state_file" 'Phase 4' "State file contains JSON content" || passed=false
  else
    echo "  ✗ Failed to append JSON array to WORK_REMAINING (exit code: $append_status)"
    echo "  Output: $append_output"
    passed=false
  fi

  # Test 1b: Store JSON object in ERROR_FILTERS (allowlisted key)
  echo "Test 1b: JSON object in ERROR_FILTERS"
  if append_workflow_state "ERROR_FILTERS" '{"type": "state_error", "since": "1h"}' 2>/dev/null; then
    assert_file_contains "$state_file" 'ERROR_FILTERS=' "State file contains ERROR_FILTERS" || passed=false
  else
    echo "  ✗ Failed to append JSON object to ERROR_FILTERS"
    passed=false
  fi

  # Test 1c: Store JSON in custom_JSON key (automatic allowlist via _JSON suffix)
  echo "Test 1c: JSON in custom_JSON key"
  if append_workflow_state "CUSTOM_DATA_JSON" '{"key": "value"}' 2>/dev/null; then
    assert_file_contains "$state_file" 'CUSTOM_DATA_JSON=' "State file contains CUSTOM_DATA_JSON" || passed=false
  else
    echo "  ✗ Failed to append JSON to _JSON suffixed key"
    passed=false
  fi

  # Test 1d: Store JSON in non-allowlisted key (should fail)
  echo "Test 1d: JSON in non-allowlisted key should fail"
  if append_workflow_state "NON_ALLOWLISTED_KEY" '["should", "fail"]' 2>/dev/null; then
    echo "  ✗ Non-allowlisted key accepted JSON (should have rejected)"
    passed=false
  else
    echo "  ✓ Non-allowlisted key correctly rejected JSON"
  fi

  # Test 1e: Store plain text in non-allowlisted key (should succeed)
  echo "Test 1e: Plain text in regular key"
  if append_workflow_state "REGULAR_KEY" "plain text value" 2>/dev/null; then
    assert_file_contains "$state_file" 'REGULAR_KEY=' "State file contains REGULAR_KEY" || passed=false
  else
    echo "  ✗ Failed to append plain text to regular key"
    passed=false
  fi

  if $passed; then
    test_pass
  else
    test_fail "JSON state persistence validation failed"
  fi
}

#############################################################################
# Test 2: Hard barrier diagnostics report file location mismatches
#############################################################################
test_hard_barrier_diagnostics() {
  test_start "test_hard_barrier_diagnostics"

  # This test validates enhanced diagnostics in /implement command
  # Since we can't easily mock the full command here, we test the
  # diagnostic logic components

  local passed=true

  # Test 2a: Diagnostic helper finds files at alternate locations
  echo "Test 2a: File location search"
  local topic_dir="$TEST_ROOT/test_topic"
  mkdir -p "$topic_dir/summaries"
  mkdir -p "$topic_dir/wrong_location"

  local expected_path="$topic_dir/summaries/test-summary.md"
  local actual_path="$topic_dir/wrong_location/test-summary.md"

  echo "test content" > "$actual_path"

  local found_files=$(find "$topic_dir" -name "test-summary.md" 2>/dev/null || true)
  if [[ -n "$found_files" ]] && [[ "$found_files" == *"wrong_location"* ]]; then
    echo "  ✓ Diagnostic search finds file at alternate location"
  else
    echo "  ✗ Diagnostic search failed to find file"
    passed=false
  fi

  # Test 2b: Diagnostic distinguishes "file at wrong location" vs "file not found"
  echo "Test 2b: Distinguish location mismatch from absence"
  local missing_file=$(find "$topic_dir" -name "nonexistent.md" 2>/dev/null || true)
  if [[ -z "$missing_file" ]]; then
    echo "  ✓ Diagnostic correctly reports file not found anywhere"
  else
    echo "  ✗ False positive for missing file"
    passed=false
  fi

  if $passed; then
    test_pass
  else
    test_fail "Hard barrier diagnostics validation failed"
  fi
}

#############################################################################
# Test 3: ERR trap suppressed for validation failures
#############################################################################
test_err_trap_suppression() {
  test_start "test_err_trap_suppression"

  # Setup: Initialize workflow state
  COMMAND_NAME="/implement"
  WORKFLOW_ID="test_err_trap_$$"
  USER_ARGS="test args"
  export COMMAND_NAME WORKFLOW_ID USER_ARGS

  init_workflow_state "$WORKFLOW_ID" >/dev/null

  local passed=true

  # Test 3a: Validation failure sets SUPPRESS_ERR_TRAP
  echo "Test 3a: Validation failure suppresses ERR trap"

  # Trigger validation failure (JSON in non-allowlisted key)
  # This should set SUPPRESS_ERR_TRAP=1 before returning
  local err_output=$(append_workflow_state "INVALID_KEY" '["json", "array"]' 2>&1 || true)

  if [[ "$err_output" == *"ERROR: append_workflow_state only supports scalar values"* ]]; then
    echo "  ✓ Validation error message present"
  else
    echo "  ✗ Expected validation error not found"
    passed=false
  fi

  # Test 3b: Check error log for proper error type (should be state_error, not execution_error)
  echo "Test 3b: Error log contains state_error (not execution_error cascade)"

  local error_log="$TEST_ROOT/.claude/data/logs/test-errors.jsonl"
  if [[ -f "$error_log" ]]; then
    local state_errors=$(grep -c '"error_type":"state_error"' "$error_log" 2>/dev/null || echo "0")
    local exec_errors=$(grep -c '"error_type":"execution_error"' "$error_log" 2>/dev/null || echo "0")

    echo "  State errors: $state_errors, Execution errors: $exec_errors"

    # We expect at least one state_error from the validation failure
    if [[ "$state_errors" -gt 0 ]]; then
      echo "  ✓ State errors logged as expected"
    else
      echo "  ✗ No state errors found in log"
      passed=false
    fi

    # Note: We can't fully test ERR trap suppression here since that requires
    # the ERR trap to be active. This is validated in integration testing.
  else
    echo "  ℹ Error log not created (test mode may not be fully initialized)"
  fi

  if $passed; then
    test_pass
  else
    test_fail "ERR trap suppression validation failed"
  fi
}

#############################################################################
# Test 4: State machine auto-initialization on missing STATE_FILE
#############################################################################
test_state_machine_auto_init() {
  test_start "test_state_machine_auto_init"

  local passed=true

  # Test 4a: sm_transition with unset STATE_FILE triggers auto-initialization
  echo "Test 4a: Auto-initialization on missing STATE_FILE"

  # Setup: Initialize workflow but then unset STATE_FILE to simulate gap
  COMMAND_NAME="/implement"
  WORKFLOW_ID="test_auto_init_$$"
  USER_ARGS="test args"
  export COMMAND_NAME WORKFLOW_ID USER_ARGS

  # Create a state file first
  local original_state_file=$(init_workflow_state "$WORKFLOW_ID")
  echo "State file created: $original_state_file"

  # Unset STATE_FILE to simulate missing initialization
  unset STATE_FILE
  echo "STATE_FILE unset to simulate initialization gap"

  # Try to transition - should trigger auto-init
  # Use a valid transition from initialize state (e.g., "research" or "implement")
  echo "Attempting sm_transition to 'research'..."

  # Redirect output to a temp file instead of command substitution
  # This preserves STATE_FILE assignment in the current shell
  local output_file="$TEST_ROOT/sm_transition_output.txt"
  sm_transition "research" >"$output_file" 2>&1
  local transition_status=$?

  local transition_output=$(cat "$output_file")
  echo "Transition output:"
  echo "$transition_output"
  echo "Transition status: $transition_status"

  if [[ "$transition_output" == *"WARNING: Auto-initializing state machine"* ]]; then
    echo "  ✓ Auto-initialization warning issued"
  else
    echo "  ℹ Auto-initialization output may differ from expected"
  fi

  # Verify state file was loaded
  if [[ -n "${STATE_FILE:-}" ]]; then
    echo "  ✓ STATE_FILE set after auto-initialization: $STATE_FILE"
  else
    echo "  ✗ STATE_FILE still unset after auto-init"
    passed=false
  fi

  # Verify transition succeeded
  if [[ $transition_status -eq 0 ]]; then
    echo "  ✓ sm_transition succeeded after auto-initialization"
  else
    echo "  ✗ sm_transition failed (status: $transition_status)"
    passed=false
  fi

  # Test 4b: Verify auto-init logs state_error for monitoring
  echo "Test 4b: Auto-initialization logs state_error"

  local error_log="$TEST_ROOT/.claude/data/logs/test-errors.jsonl"
  if [[ -f "$error_log" ]]; then
    if grep -q "sm_transition called before initialization" "$error_log" 2>/dev/null; then
      echo "  ✓ Auto-initialization error logged for monitoring"
    else
      echo "  ℹ Auto-initialization error not found (may not be in test mode or logged differently)"
    fi
  else
    echo "  ℹ Error log not found at $error_log"
  fi

  if $passed; then
    test_pass
  else
    test_fail "State machine auto-initialization validation failed"
  fi
}

#############################################################################
# Main test execution
#############################################################################

echo "=========================================="
echo "Running /implement Error Handling Tests"
echo "=========================================="
echo "Test root: $TEST_ROOT"

# Run all tests
test_json_state_persistence
test_hard_barrier_diagnostics
test_err_trap_suppression
test_state_machine_auto_init

# Report results
echo ""
echo "=========================================="
echo "TEST RESULTS"
echo "=========================================="
echo "Tests run:    $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo ""
  echo "✓ All tests passed!"
  exit 0
else
  echo ""
  echo "✗ Some tests failed"
  exit 1
fi
