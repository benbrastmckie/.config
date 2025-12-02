#!/usr/bin/env bash
# Integration Test: Legacy Complexity Score Handling
# Verifies that workflow state machine correctly normalizes legacy complexity scores

set -euo pipefail

# Setup test environment
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_ROOT="$(cd "$TEST_DIR/../.." && pwd)"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0

# Test helper functions
log_test() {
  echo "TEST: $1"
  ((TESTS_RUN++))
}

assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="$3"

  if [ "$expected" = "$actual" ]; then
    echo "  ✓ PASS: $message"
    ((TESTS_PASSED++))
  else
    echo "  ✗ FAIL: $message"
    echo "    Expected: $expected"
    echo "    Actual: $actual"
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"

  if echo "$haystack" | grep -q "$needle"; then
    echo "  ✓ PASS: $message"
    ((TESTS_PASSED++))
  else
    echo "  ✗ FAIL: $message"
    echo "    Expected to find: $needle"
    echo "    In: $haystack"
  fi
}

echo "=========================================="
echo "Legacy Complexity Score Handling Tests"
echo "=========================================="
echo

# Source the workflow state machine library
source "$CLAUDE_ROOT/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh"
  exit 1
}

# Test 1: Normalize legacy score 78.5 -> 4
log_test "Normalize legacy complexity score 78.5"
OUTPUT=$(normalize_complexity "78.5" 2>&1)
NORMALIZED=$(echo "$OUTPUT" | tail -1)
assert_equals "4" "$NORMALIZED" "78.5 should normalize to 4"
assert_contains "$OUTPUT" "INFO: Normalized complexity 78.5" "Should emit normalization message"

# Test 2: Normalize score 25 -> 1
log_test "Normalize low complexity score 25"
OUTPUT=$(normalize_complexity "25" 2>&1)
NORMALIZED=$(echo "$OUTPUT" | tail -1)
assert_equals "1" "$NORMALIZED" "25 should normalize to 1"
assert_contains "$OUTPUT" "INFO: Normalized complexity 25" "Should emit normalization message"

# Test 3: Normalize score 45 -> 2
log_test "Normalize medium complexity score 45"
OUTPUT=$(normalize_complexity "45" 2>&1)
NORMALIZED=$(echo "$OUTPUT" | tail -1)
assert_equals "2" "$NORMALIZED" "45 should normalize to 2"
assert_contains "$OUTPUT" "INFO: Normalized complexity 45" "Should emit normalization message"

# Test 4: Normalize score 65 -> 3
log_test "Normalize high complexity score 65"
OUTPUT=$(normalize_complexity "65" 2>&1)
NORMALIZED=$(echo "$OUTPUT" | tail -1)
assert_equals "3" "$NORMALIZED" "65 should normalize to 3"
assert_contains "$OUTPUT" "INFO: Normalized complexity 65" "Should emit normalization message"

# Test 5: Valid scores 1-4 should pass through unchanged (no INFO message)
log_test "Valid complexity score 2 unchanged"
OUTPUT=$(normalize_complexity "2" 2>&1)
NORMALIZED=$(echo "$OUTPUT" | tail -1)
assert_equals "2" "$NORMALIZED" "2 should remain 2"
if ! echo "$OUTPUT" | grep -q "INFO:"; then
  echo "  ✓ PASS: No normalization message for valid score"
  ((TESTS_PASSED++))
  ((TESTS_RUN++))
else
  echo "  ✗ FAIL: Should not emit normalization message for valid score"
  ((TESTS_RUN++))
fi

# Test 6: Invalid input should default to 2 with warning
log_test "Invalid complexity score 'invalid'"
OUTPUT=$(normalize_complexity "invalid" 2>&1)
NORMALIZED=$(echo "$OUTPUT" | tail -1)
assert_equals "2" "$NORMALIZED" "Invalid input should default to 2"
assert_contains "$OUTPUT" "WARNING: Invalid complexity" "Should emit warning for invalid input"

# Test 7: sm_init should accept and normalize legacy complexity
log_test "sm_init with legacy complexity score"

# Create temporary state directory for test
TMP_STATE_DIR="/tmp/state_test_$$"
mkdir -p "$TMP_STATE_DIR"
export STATE_FILE="$TMP_STATE_DIR/workflow.state"

# Mock append_workflow_state function (since we're testing in isolation)
append_workflow_state() {
  echo "export $1=\"$2\"" >> "$STATE_FILE"
}

# Test sm_init with legacy complexity
OUTPUT=$(sm_init "Test workflow" "/test" "implement-only" "78.5" '["test"]' 2>&1)
SM_INIT_RESULT=$?

# Check that sm_init succeeded
if [ $SM_INIT_RESULT -eq 0 ]; then
  echo "  ✓ PASS: sm_init succeeded with legacy complexity"
  ((TESTS_PASSED++))
else
  echo "  ✗ FAIL: sm_init failed with legacy complexity"
fi
((TESTS_RUN++))

# Check that complexity was normalized to 4
if [ "${RESEARCH_COMPLEXITY:-}" = "4" ]; then
  echo "  ✓ PASS: Complexity normalized to 4"
  ((TESTS_PASSED++))
else
  echo "  ✗ FAIL: Complexity not normalized correctly (got: ${RESEARCH_COMPLEXITY:-none})"
fi
((TESTS_RUN++))

# Check normalization message was emitted
if echo "$OUTPUT" | grep -q "INFO: Normalized complexity 78"; then
  echo "  ✓ PASS: Normalization message emitted"
  ((TESTS_PASSED++))
else
  echo "  ✗ FAIL: No normalization message found"
fi
((TESTS_RUN++))

# Cleanup
rm -rf "$TMP_STATE_DIR"
unset STATE_FILE

# Test 8: sm_init graceful degradation with impossible invalid value
log_test "sm_init graceful degradation with invalid normalized value"

# This test verifies the defensive check in sm_init works
# We'll mock normalize_complexity to return invalid value

# Create temporary state directory for test
TMP_STATE_DIR="/tmp/state_test_2_$$"
mkdir -p "$TMP_STATE_DIR"
export STATE_FILE="$TMP_STATE_DIR/workflow.state"

# Override normalize_complexity to return invalid value (for testing degradation)
normalize_complexity() {
  echo "INVALID"
}

OUTPUT=$(sm_init "Test workflow" "/test" "implement-only" "anything" '["test"]' 2>&1)
SM_INIT_RESULT=$?

# Check that sm_init succeeded despite invalid normalization
if [ $SM_INIT_RESULT -eq 0 ]; then
  echo "  ✓ PASS: sm_init succeeded with graceful degradation"
  ((TESTS_PASSED++))
else
  echo "  ✗ FAIL: sm_init failed (should have degraded gracefully)"
fi
((TESTS_RUN++))

# Check that complexity was set to default 2
if [ "${RESEARCH_COMPLEXITY:-}" = "2" ]; then
  echo "  ✓ PASS: Complexity degraded to default 2"
  ((TESTS_PASSED++))
else
  echo "  ✗ FAIL: Complexity not degraded correctly (got: ${RESEARCH_COMPLEXITY:-none})"
fi
((TESTS_RUN++))

# Check warning message was emitted
if echo "$OUTPUT" | grep -q "WARNING: Complexity validation failed"; then
  echo "  ✓ PASS: Degradation warning emitted"
  ((TESTS_PASSED++))
else
  echo "  ✗ FAIL: No degradation warning found"
fi
((TESTS_RUN++))

# Cleanup
rm -rf "$TMP_STATE_DIR"
unset STATE_FILE

# Restore normalize_complexity function by re-sourcing
source "$CLAUDE_ROOT/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null

# Test summary
echo
echo "=========================================="
echo "Test Results"
echo "=========================================="
echo "Tests run: $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $((TESTS_RUN - TESTS_PASSED))"
echo

if [ $TESTS_PASSED -eq $TESTS_RUN ]; then
  echo "✓ All tests passed"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
