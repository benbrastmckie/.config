#!/usr/bin/env bash
# Integration Test: ERR Trap Test Context Suppression
# Verifies that is_test_context function correctly detects test execution contexts

set -euo pipefail

# Setup test environment
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_ROOT="$(cd "$TEST_DIR/../.." && pwd)"

# Source error handling library
source "$CLAUDE_ROOT/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh"
  echo "Tried path: $CLAUDE_ROOT/.claude/lib/core/error-handling.sh"
  exit 1
}

# Test counter
TESTS_RUN=0
TESTS_PASSED=0

# Test helper functions
log_test() {
  echo "TEST: $1"
  ((TESTS_RUN++))
}

assert_true() {
  local message="$1"
  if [ $? -eq 0 ]; then
    echo "  ✓ PASS: $message"
    ((TESTS_PASSED++))
  else
    echo "  ✗ FAIL: $message"
  fi
}

assert_false() {
  local message="$1"
  if [ $? -ne 0 ]; then
    echo "  ✓ PASS: $message"
    ((TESTS_PASSED++))
  else
    echo "  ✗ FAIL: $message"
  fi
}

echo "=========================================="
echo "ERR Trap Test Context Detection Tests"
echo "=========================================="
echo

# Test 1: WORKFLOW_ID pattern detection (test_*)
log_test "Test context detection via WORKFLOW_ID=test_*"
WORKFLOW_ID="test_12345"
if is_test_context; then
  echo "  ✓ PASS: test_* workflow ID detected"
  ((TESTS_PASSED++))
else
  echo "  ✗ FAIL: test_* workflow ID not detected"
fi

# Test 2: Normal workflow ID should not be detected
log_test "Normal workflow ID should not be test context"
WORKFLOW_ID="normal_workflow_$$"
if ! is_test_context; then
  echo "  ✓ PASS: Normal workflow ID not detected as test"
  ((TESTS_PASSED++))
else
  echo "  ✗ FAIL: Normal workflow ID incorrectly detected as test"
fi

# Test 3: Environment variable override (SUPPRESS_ERR_LOGGING=1)
log_test "Test context detection via SUPPRESS_ERR_LOGGING=1"
unset WORKFLOW_ID
export SUPPRESS_ERR_LOGGING=1
if is_test_context; then
  echo "  ✓ PASS: SUPPRESS_ERR_LOGGING=1 detected"
  ((TESTS_PASSED++))
else
  echo "  ✗ FAIL: SUPPRESS_ERR_LOGGING=1 not detected"
fi
unset SUPPRESS_ERR_LOGGING

# Test 4: SUPPRESS_ERR_LOGGING=0 should not trigger
log_test "SUPPRESS_ERR_LOGGING=0 should not be test context"
export SUPPRESS_ERR_LOGGING=0
if ! is_test_context; then
  echo "  ✓ PASS: SUPPRESS_ERR_LOGGING=0 not detected as test"
  ((TESTS_PASSED++))
else
  echo "  ✗ FAIL: SUPPRESS_ERR_LOGGING=0 incorrectly detected as test"
fi
unset SUPPRESS_ERR_LOGGING

# Test 5: No test indicators should not be detected
log_test "No test indicators should not be test context"
unset WORKFLOW_ID
unset SUPPRESS_ERR_LOGGING
if ! is_test_context; then
  echo "  ✓ PASS: No indicators not detected as test"
  ((TESTS_PASSED++))
else
  echo "  ✗ FAIL: No indicators incorrectly detected as test"
fi

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
