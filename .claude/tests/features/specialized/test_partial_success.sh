#!/usr/bin/env bash
# Test suite for partial failure scenarios
# Tests handling of operations where some succeed and some fail

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

# Test: All operations succeed
test_all_operations_succeed() {
  local aggregation_json='{"total":5,"successful":5,"failed":0,"artifacts":[{"status":"success"},{"status":"success"},{"status":"success"},{"status":"success"},{"status":"success"}]}'

  local result
  result=$(handle_partial_failure "$aggregation_json" 2>/dev/null || true)

  local failed_count
  failed_count=$(echo "$result" | jq -r '.failed')

  # Should have 0 failed operations
  if [[ "$failed_count" == "0" ]]; then
    return 0
  else
    return 1
  fi
}

# Test: All operations fail
test_all_operations_fail() {
  local aggregation_json='{"total":5,"successful":0,"failed":5,"artifacts":[{"status":"failed"},{"status":"failed"},{"status":"failed"},{"status":"failed"},{"status":"failed"}]}'

  local result
  result=$(handle_partial_failure "$aggregation_json" 2>/dev/null || true)

  local can_continue
  can_continue=$(echo "$result" | jq -r '.can_continue')

  # Should not be able to continue (no successful operations)
  if [[ "$can_continue" == "false" ]]; then
    return 0
  else
    return 1
  fi
}

# Test: Mixed success and failure - majority succeed
test_partial_success_majority() {
  local aggregation_json='{"total":5,"successful":4,"failed":1,"artifacts":[{"status":"success"},{"status":"success"},{"status":"success"},{"status":"success"},{"status":"failed"}]}'

  local result
  result=$(handle_partial_failure "$aggregation_json" 2>/dev/null || true)

  local can_continue requires_retry
  can_continue=$(echo "$result" | jq -r '.can_continue')
  requires_retry=$(echo "$result" | jq -r '.requires_retry')

  # Should be able to continue (4 successful) and require retry (1 failed)
  if [[ "$can_continue" == "true" ]] && [[ "$requires_retry" == "true" ]]; then
    return 0
  else
    return 1
  fi
}

# Test: Mixed success and failure - majority fail
test_partial_success_minority() {
  local aggregation_json='{"total":5,"successful":1,"failed":4,"artifacts":[{"status":"success"},{"status":"failed"},{"status":"failed"},{"status":"failed"},{"status":"failed"}]}'

  local result
  result=$(handle_partial_failure "$aggregation_json" 2>/dev/null || true)

  local can_continue requires_retry
  can_continue=$(echo "$result" | jq -r '.can_continue')
  requires_retry=$(echo "$result" | jq -r '.requires_retry')

  # Should be able to continue (1 successful) but requires retry (4 failed)
  if [[ "$can_continue" == "true" ]] && [[ "$requires_retry" == "true" ]]; then
    return 0
  else
    return 1
  fi
}

# Test: Successful operations are correctly separated
test_successful_operations_separation() {
  local aggregation_json='{"total":5,"successful":3,"failed":2,"artifacts":[{"id":"op1","status":"success"},{"id":"op2","status":"success"},{"id":"op3","status":"success"},{"id":"op4","status":"failed"},{"id":"op5","status":"failed"}]}'

  local result
  result=$(handle_partial_failure "$aggregation_json" 2>/dev/null || true)

  local successful_count
  successful_count=$(echo "$result" | jq -r '.successful_operations | length')

  # Should have 3 successful operations
  if [[ "$successful_count" == "3" ]]; then
    return 0
  else
    return 1
  fi
}

# Test: Failed operations are correctly separated
test_failed_operations_separation() {
  local aggregation_json='{"total":5,"successful":3,"failed":2,"artifacts":[{"id":"op1","status":"success"},{"id":"op2","status":"success"},{"id":"op3","status":"success"},{"id":"op4","status":"failed"},{"id":"op5","status":"failed"}]}'

  local result
  result=$(handle_partial_failure "$aggregation_json" 2>/dev/null || true)

  local failed_count
  failed_count=$(echo "$result" | jq -r '.failed_operations | length')

  # Should have 2 failed operations
  if [[ "$failed_count" == "2" ]]; then
    return 0
  else
    return 1
  fi
}

# Test: Single operation success
test_single_operation_success() {
  local aggregation_json='{"total":1,"successful":1,"failed":0,"artifacts":[{"id":"op1","status":"success"}]}'

  local result
  result=$(handle_partial_failure "$aggregation_json" 2>/dev/null || true)

  local can_continue requires_retry
  can_continue=$(echo "$result" | jq -r '.can_continue')
  requires_retry=$(echo "$result" | jq -r '.requires_retry')

  # Should be able to continue and not require retry
  if [[ "$can_continue" == "true" ]] && [[ "$requires_retry" == "false" ]]; then
    return 0
  else
    return 1
  fi
}

# Test: Single operation failure
test_single_operation_failure() {
  local aggregation_json='{"total":1,"successful":0,"failed":1,"artifacts":[{"id":"op1","status":"failed"}]}'

  local result
  result=$(handle_partial_failure "$aggregation_json" 2>/dev/null || true)

  local can_continue requires_retry
  can_continue=$(echo "$result" | jq -r '.can_continue')
  requires_retry=$(echo "$result" | jq -r '.requires_retry')

  # Should not be able to continue but requires retry
  if [[ "$can_continue" == "false" ]] && [[ "$requires_retry" == "true" ]]; then
    return 0
  else
    return 1
  fi
}

# Test: Empty operations
test_empty_operations() {
  local aggregation_json='{"total":0,"successful":0,"failed":0,"artifacts":[]}'

  local result
  result=$(handle_partial_failure "$aggregation_json" 2>/dev/null || true)

  local failed_count
  failed_count=$(echo "$result" | jq -r '.failed')

  # Should have 0 failed operations
  if [[ "$failed_count" == "0" ]]; then
    return 0
  else
    return 1
  fi
}

# Test: Invalid JSON handling
test_invalid_json_handling() {
  local output
  output=$(handle_partial_failure "not valid json" 2>&1 || true)

  # Should produce error message
  if echo "$output" | grep -q "Invalid JSON"; then
    return 0
  else
    return 1
  fi
}

# ============================================================================
# Run All Tests
# ============================================================================

echo "Testing Partial Failure Scenarios"
echo "=================================="
echo ""

run_test "All operations succeed" test_all_operations_succeed
run_test "All operations fail" test_all_operations_fail
run_test "Partial success - majority succeed" test_partial_success_majority
run_test "Partial success - minority succeed" test_partial_success_minority
run_test "Successful operations correctly separated" test_successful_operations_separation
run_test "Failed operations correctly separated" test_failed_operations_separation
run_test "Single operation success" test_single_operation_success
run_test "Single operation failure" test_single_operation_failure
run_test "Empty operations" test_empty_operations
run_test "Invalid JSON handling" test_invalid_json_handling

# ============================================================================
# Print Results
# ============================================================================

echo ""
echo "=================================="
echo "Test Results:"
echo "  Total: $TESTS_RUN"
echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
echo "=================================="

if [[ $TESTS_FAILED -eq 0 ]]; then
  exit 0
else
  exit 1
fi
