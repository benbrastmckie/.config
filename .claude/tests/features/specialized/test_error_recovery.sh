#!/usr/bin/env bash
# Test suite for error recovery functionality
# Tests retry_with_timeout, retry_with_fallback, handle_partial_failure, escalate_to_user_parallel

set -euo pipefail

# Source test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect project root using git or walk-up pattern
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  CLAUDE_PROJECT_DIR="$SCRIPT_DIR"
  while [ "$CLAUDE_PROJECT_DIR" != "/" ]; do
    if [ -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
      break
    fi
    CLAUDE_PROJECT_DIR="$(dirname "$CLAUDE_PROJECT_DIR")"
  done
fi
CLAUDE_LIB="${CLAUDE_PROJECT_DIR}/.claude/lib"
source "$CLAUDE_LIB/core/detect-project-dir.sh"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Source the library under test
source "$CLAUDE_PROJECT_DIR/.claude/lib/core/error-handling.sh"

# Helper function to run a test
run_test() {
  local test_name="$1"
  local test_func="$2"

  TESTS_RUN=$((TESTS_RUN + 1))
  echo -n "  Testing: $test_name ... "

  if $test_func; then
    echo -e "${GREEN}PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}FAIL${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# ============================================================================
# Test Cases
# ============================================================================

# Test: retry_with_timeout function exists
test_retry_with_timeout_exists() {
  if declare -f retry_with_timeout > /dev/null; then
    return 0
  else
    echo "Function retry_with_timeout not found" >&2
    return 1
  fi
}

# Test: retry_with_timeout requires operation_name argument
test_retry_with_timeout_args() {
  local output
  output=$(retry_with_timeout "" 0 2>&1 || true)
  if echo "$output" | grep -q "requires operation_name"; then
    return 0
  else
    return 1
  fi
}

# Test: retry_with_timeout returns JSON with increased timeout
test_retry_with_timeout_json_output() {
  local result
  result=$(retry_with_timeout "test_operation" 0 2>/dev/null || true)

  # Should return JSON with new_timeout field
  if echo "$result" | jq -e '.new_timeout' > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# Test: retry_with_timeout increases timeout by 1.5x
test_retry_with_timeout_calculation() {
  local result
  result=$(retry_with_timeout "test_operation" 1 2>/dev/null || true)

  local new_timeout
  new_timeout=$(echo "$result" | jq -r '.new_timeout')

  # First retry (attempt 1) should be 180000 (1.5x base timeout of 120000)
  if [[ "$new_timeout" == "180000" ]]; then
    return 0
  else
    echo "Expected 180000, got $new_timeout" >&2
    return 1
  fi
}

# Test: retry_with_timeout respects max attempts
test_retry_with_timeout_max_attempts() {
  local result
  result=$(retry_with_timeout "test_operation" 3 2>/dev/null || true)

  local should_retry
  should_retry=$(echo "$result" | jq -r '.should_retry')

  # Should not retry after 3 attempts
  if [[ "$should_retry" == "false" ]]; then
    return 0
  else
    echo "Expected should_retry=false after 3 attempts" >&2
    return 1
  fi
}

# Test: retry_with_fallback function exists
test_retry_with_fallback_exists() {
  if declare -f retry_with_fallback > /dev/null; then
    return 0
  else
    echo "Function retry_with_fallback not found" >&2
    return 1
  fi
}

# Test: retry_with_fallback returns reduced toolset
test_retry_with_fallback_reduced_tools() {
  local result
  result=$(retry_with_fallback "test_operation" 1 2>/dev/null || true)

  # Should return JSON with reduced_toolset field
  if echo "$result" | jq -e '.reduced_toolset' > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# Test: handle_partial_failure function exists
test_handle_partial_failure_exists() {
  if declare -f handle_partial_failure > /dev/null; then
    return 0
  else
    echo "Function handle_partial_failure not found" >&2
    return 1
  fi
}

# Test: handle_partial_failure processes aggregation JSON
test_handle_partial_failure_json_processing() {
  local aggregation_json='{"total":5,"successful":3,"failed":2,"artifacts":[{"status":"success"},{"status":"success"},{"status":"success"},{"status":"failed"},{"status":"failed"}]}'

  local result
  result=$(handle_partial_failure "$aggregation_json" 2>/dev/null || true)

  # Should return JSON with successful_operations field
  if echo "$result" | jq -e '.successful_operations' > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# Test: handle_partial_failure sets can_continue flag
test_handle_partial_failure_can_continue() {
  local aggregation_json='{"total":5,"successful":3,"failed":2,"artifacts":[{"status":"success"},{"status":"success"},{"status":"success"},{"status":"failed"},{"status":"failed"}]}'

  local result
  result=$(handle_partial_failure "$aggregation_json" 2>/dev/null || true)

  local can_continue
  can_continue=$(echo "$result" | jq -r '.can_continue')

  # Should be able to continue with 3 successful operations
  if [[ "$can_continue" == "true" ]]; then
    return 0
  else
    return 1
  fi
}

# Test: escalate_to_user_parallel function exists
test_escalate_to_user_parallel_exists() {
  if declare -f escalate_to_user_parallel > /dev/null; then
    return 0
  else
    echo "Function escalate_to_user_parallel not found" >&2
    return 1
  fi
}

# Test: escalate_to_user_parallel formats message with options
test_escalate_to_user_parallel_message_format() {
  local error_context='{"operation":"expand","failed":2,"total":5}'

  local result
  result=$(escalate_to_user_parallel "$error_context" "retry,skip,abort" 2>/dev/null || true)

  # Should return an option choice (non-interactive mode returns first option)
  if [[ "$result" == "retry" ]]; then
    return 0
  else
    echo "Expected 'retry', got '$result'" >&2
    return 1
  fi
}

# ============================================================================
# Run All Tests
# ============================================================================

echo "Testing Error Recovery Functions"
echo "========================================"
echo ""

run_test "retry_with_timeout exists" test_retry_with_timeout_exists
run_test "retry_with_timeout requires arguments" test_retry_with_timeout_args
run_test "retry_with_timeout returns JSON with new timeout" test_retry_with_timeout_json_output
run_test "retry_with_timeout increases timeout by 1.5x" test_retry_with_timeout_calculation
run_test "retry_with_timeout respects max attempts" test_retry_with_timeout_max_attempts
run_test "retry_with_fallback exists" test_retry_with_fallback_exists
run_test "retry_with_fallback returns reduced toolset" test_retry_with_fallback_reduced_tools
run_test "handle_partial_failure exists" test_handle_partial_failure_exists
run_test "handle_partial_failure processes aggregation JSON" test_handle_partial_failure_json_processing
run_test "handle_partial_failure sets can_continue flag" test_handle_partial_failure_can_continue
run_test "escalate_to_user_parallel exists" test_escalate_to_user_parallel_exists
run_test "escalate_to_user_parallel formats message with options" test_escalate_to_user_parallel_message_format

# ============================================================================
# Print Results
# ============================================================================

echo ""
echo "========================================"
echo "Test Results:"
echo "  Total: $TESTS_RUN"
echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
echo "========================================"

if [[ $TESTS_FAILED -eq 0 ]]; then
  exit 0
else
  exit 1
fi
