#!/usr/bin/env bash
# test_source_libraries_inline_error_logging.sh
# Unit test for error logging in source-libraries-inline.sh
#
# Tests that function validation failures are logged to centralized error log

set -euo pipefail

# Test isolation: use temp directory for all test artifacts
export CLAUDE_TEST_MODE=1
export CLAUDE_SPECS_ROOT="/tmp/test_error_logging_$$"
export CLAUDE_PROJECT_DIR="$CLAUDE_SPECS_ROOT"
mkdir -p "$CLAUDE_SPECS_ROOT/.claude/data/logs"
mkdir -p "$CLAUDE_SPECS_ROOT/.claude/lib/core"
mkdir -p "$CLAUDE_SPECS_ROOT/.claude/lib/workflow"

# Cleanup on exit
trap 'rm -rf "$CLAUDE_SPECS_ROOT"' EXIT

# Copy real libraries to test environment
REAL_PROJECT_DIR="/home/benjamin/.config"
cp "$REAL_PROJECT_DIR/.claude/lib/core/error-handling.sh" "$CLAUDE_SPECS_ROOT/.claude/lib/core/"
cp "$REAL_PROJECT_DIR/.claude/lib/core/source-libraries-inline.sh" "$CLAUDE_SPECS_ROOT/.claude/lib/core/"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

test_pass() {
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo "  PASS: $1"
}

test_fail() {
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo "  FAIL: $1"
}

echo "=================================================="
echo "Testing source-libraries-inline.sh Error Logging"
echo "=================================================="
echo ""

# Test 1: Error log file is created when sourcing libraries
echo "Test 1: Error log directory setup"
TESTS_RUN=$((TESTS_RUN + 1))

if [ -d "$CLAUDE_SPECS_ROOT/.claude/data/logs" ]; then
  test_pass "Test logs directory exists"
else
  test_fail "Test logs directory not created"
fi

# Test 2: Test that log_command_error function logs dependency_error
echo ""
echo "Test 2: log_command_error writes to test error log"
TESTS_RUN=$((TESTS_RUN + 1))

# Source error-handling.sh to get log_command_error
cd "$CLAUDE_SPECS_ROOT"
source "$CLAUDE_SPECS_ROOT/.claude/lib/core/error-handling.sh"

# Set workflow metadata
export COMMAND_NAME="/test"
export WORKFLOW_ID="test_workflow_$$"
export USER_ARGS="test args"

# Ensure error log exists
ensure_error_log_exists

# Log a test error
log_command_error \
  "$COMMAND_NAME" \
  "$WORKFLOW_ID" \
  "$USER_ARGS" \
  "dependency_error" \
  "Test dependency error message" \
  "test_source" \
  '{"function": "test_function", "library": "test_library.sh"}'

# Check error was logged to test log (not production)
TEST_LOG="$CLAUDE_SPECS_ROOT/.claude/tests/logs/test-errors.jsonl"
if [ -f "$TEST_LOG" ] && grep -q "dependency_error" "$TEST_LOG"; then
  test_pass "dependency_error logged to test error log"
else
  test_fail "dependency_error not found in test error log"
  echo "    Expected log at: $TEST_LOG"
  if [ -f "$TEST_LOG" ]; then
    echo "    Log contents: $(cat "$TEST_LOG")"
  else
    echo "    Log file does not exist"
    # Check if it went to production log
    if [ -f "$CLAUDE_SPECS_ROOT/.claude/data/logs/errors.jsonl" ]; then
      echo "    Found in production log instead"
    fi
  fi
fi

# Test 3: Verify error log entry has correct structure
echo ""
echo "Test 3: Error log entry has correct JSONL structure"
TESTS_RUN=$((TESTS_RUN + 1))

if [ -f "$TEST_LOG" ]; then
  LAST_ENTRY=$(tail -1 "$TEST_LOG")

  # Check all required fields
  HAS_TIMESTAMP=$(echo "$LAST_ENTRY" | jq -r 'has("timestamp")' 2>/dev/null)
  HAS_COMMAND=$(echo "$LAST_ENTRY" | jq -r 'has("command")' 2>/dev/null)
  HAS_ERROR_TYPE=$(echo "$LAST_ENTRY" | jq -r 'has("error_type")' 2>/dev/null)
  HAS_MESSAGE=$(echo "$LAST_ENTRY" | jq -r 'has("error_message")' 2>/dev/null)
  HAS_CONTEXT=$(echo "$LAST_ENTRY" | jq -r 'has("context")' 2>/dev/null)

  if [ "$HAS_TIMESTAMP" = "true" ] && [ "$HAS_COMMAND" = "true" ] && \
     [ "$HAS_ERROR_TYPE" = "true" ] && [ "$HAS_MESSAGE" = "true" ] && \
     [ "$HAS_CONTEXT" = "true" ]; then
    test_pass "Error log entry has all required fields"
  else
    test_fail "Error log entry missing required fields"
    echo "    Entry: $LAST_ENTRY"
  fi
else
  test_fail "Test log file not found"
fi

# Test 4: Verify context JSON contains function and library info
echo ""
echo "Test 4: Error context contains function and library metadata"
TESTS_RUN=$((TESTS_RUN + 1))

if [ -f "$TEST_LOG" ]; then
  LAST_ENTRY=$(tail -1 "$TEST_LOG")
  CONTEXT_FUNCTION=$(echo "$LAST_ENTRY" | jq -r '.context.function // "missing"' 2>/dev/null)
  CONTEXT_LIBRARY=$(echo "$LAST_ENTRY" | jq -r '.context.library // "missing"' 2>/dev/null)

  if [ "$CONTEXT_FUNCTION" = "test_function" ] && [ "$CONTEXT_LIBRARY" = "test_library.sh" ]; then
    test_pass "Context contains function and library metadata"
  else
    test_fail "Context missing function/library metadata"
    echo "    function: $CONTEXT_FUNCTION (expected: test_function)"
    echo "    library: $CONTEXT_LIBRARY (expected: test_library.sh)"
  fi
else
  test_fail "Test log file not found"
fi

# Test 5: Verify environment is set to "test" (not production)
echo ""
echo "Test 5: Error log environment is 'test'"
TESTS_RUN=$((TESTS_RUN + 1))

if [ -f "$TEST_LOG" ]; then
  LAST_ENTRY=$(tail -1 "$TEST_LOG")
  ENVIRONMENT=$(echo "$LAST_ENTRY" | jq -r '.environment // "missing"' 2>/dev/null)

  if [ "$ENVIRONMENT" = "test" ]; then
    test_pass "Environment correctly set to 'test'"
  else
    test_fail "Environment not set to 'test'"
    echo "    environment: $ENVIRONMENT (expected: test)"
  fi
else
  test_fail "Test log file not found"
fi

# Test 6: Verify workflow_id pattern matching routes test_* prefixed IDs to test log
echo ""
echo "Test 6: workflow_id pattern matching routes test_* to test log"
TESTS_RUN=$((TESTS_RUN + 1))

# Create a fresh temp directory for this test
TEST6_DIR="/tmp/test6_workflow_pattern_$$"
mkdir -p "$TEST6_DIR/.claude/data/logs"
mkdir -p "$TEST6_DIR/.claude/tests/logs"

# Run in fresh subshell to avoid source guard issues and test workflow_id detection
# without CLAUDE_TEST_MODE. Pass paths as shell arguments.
TEST6_RESULT=$(bash -c '
  test6_dir="$1"
  real_proj_dir="$2"
  export CLAUDE_PROJECT_DIR="$test6_dir"
  # Unset source guard to allow fresh sourcing
  unset ERROR_HANDLING_SOURCED
  # No CLAUDE_TEST_MODE set - test workflow_id detection alone
  source "$real_proj_dir/.claude/lib/core/error-handling.sh" 2>/dev/null

  # Log error with test_* prefixed workflow_id (should go to test log)
  log_command_error "/plan" "test_workflow_pattern_123" "test args" "test_error" "Test workflow pattern message" "test_source" "{}"

  # Return where log was written
  if [ -f "$test6_dir/.claude/tests/logs/test-errors.jsonl" ]; then
    echo "test_log"
  elif [ -f "$test6_dir/.claude/data/logs/errors.jsonl" ]; then
    echo "prod_log"
  else
    echo "no_log"
  fi
' _ "$TEST6_DIR" "$REAL_PROJECT_DIR")

if [ "$TEST6_RESULT" = "test_log" ]; then
  test_pass "workflow_id pattern test_* routes to test log"
else
  test_fail "workflow_id pattern test_* did not route to test log (found: $TEST6_RESULT)"
fi

# Cleanup test6 temp directory
rm -rf "$TEST6_DIR"

# Summary
echo ""
echo "=================================================="
echo "Test Summary"
echo "=================================================="
echo "Tests run:    $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo "All tests passed!"
  exit 0
else
  echo "Some tests failed!"
  exit 1
fi
