#!/usr/bin/env bash
# test_error_logging.sh - Test centralized error logging system
#
# Tests:
# - log_command_error function
# - parse_subagent_error function
# - query_errors function
# - recent_errors function
# - error_summary function
# - rotate_error_log function

set -euo pipefail

# Test configuration
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
export CLAUDE_PROJECT_DIR
CLAUDE_LIB="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Source library
source "${CLAUDE_LIB}/core/error-handling.sh"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper
assert_equals() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"

  if [ "$expected" = "$actual" ]; then
    echo "✓ PASS: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "✗ FAIL: $test_name"
    echo "  Expected: $expected"
    echo "  Actual:   $actual"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_contains() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"

  if echo "$actual" | grep -q "$expected"; then
    echo "✓ PASS: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "✗ FAIL: $test_name"
    echo "  Expected to contain: $expected"
    echo "  Actual: $actual"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_not_empty() {
  local actual="$1"
  local test_name="$2"

  if [ -n "$actual" ]; then
    echo "✓ PASS: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "✗ FAIL: $test_name"
    echo "  Expected non-empty value"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# Setup: Create clean test log
setup() {
  mkdir -p "${CLAUDE_PROJECT_DIR}/.claude/tests/logs"
  echo "" > "${CLAUDE_PROJECT_DIR}/.claude/tests/logs/test-errors.jsonl"
}

# Test 1: log_command_error creates valid JSONL entry
test_log_command_error() {
  echo "Test 1: log_command_error creates valid JSONL entry"

  log_command_error \
    "/build" \
    "build_test_123" \
    "plan.md 3" \
    "state_error" \
    "Test state error" \
    "bash_block" \
    '{"plan_file": "/path/to/plan.md"}'

  # Verify entry was added
  local line_count
  line_count=$(wc -l < "${CLAUDE_PROJECT_DIR}/.claude/tests/logs/test-errors.jsonl")

  # Should have at least 1 line (may have extra from setup)
  if [ "$line_count" -ge 1 ]; then
    echo "✓ PASS: log_command_error adds entry to log"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "✗ FAIL: log_command_error should add entry"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # Verify JSON is valid
  local last_entry
  last_entry=$(tail -1 "${CLAUDE_PROJECT_DIR}/.claude/tests/logs/test-errors.jsonl")

  if echo "$last_entry" | jq empty 2>/dev/null; then
    echo "✓ PASS: Entry is valid JSON"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "✗ FAIL: Entry is not valid JSON"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # Verify fields
  local command_val
  command_val=$(echo "$last_entry" | jq -r '.command')
  assert_equals "/build" "$command_val" "Command field correct"

  local error_type_val
  error_type_val=$(echo "$last_entry" | jq -r '.error_type')
  assert_equals "state_error" "$error_type_val" "Error type field correct"

  local workflow_id_val
  workflow_id_val=$(echo "$last_entry" | jq -r '.workflow_id')
  assert_equals "build_test_123" "$workflow_id_val" "Workflow ID field correct"

  local environment_val
  environment_val=$(echo "$last_entry" | jq -r '.environment')
  assert_equals "test" "$environment_val" "Environment field correct"
}

# Test 2: parse_subagent_error extracts error info
test_parse_subagent_error() {
  echo ""
  echo "Test 2: parse_subagent_error extracts error info"

  local output="Some output
TASK_ERROR: validation_error - Schema mismatch detected
More output"

  local result
  result=$(parse_subagent_error "$output")

  local found
  found=$(echo "$result" | jq -r '.found')
  assert_equals "true" "$found" "Error found in output"

  local error_type
  error_type=$(echo "$result" | jq -r '.error_type')
  assert_equals "validation_error" "$error_type" "Error type extracted"

  local message
  message=$(echo "$result" | jq -r '.message')
  assert_contains "Schema mismatch" "$message" "Message extracted"
}

# Test 3: parse_subagent_error returns found=false when no error
test_parse_subagent_error_no_error() {
  echo ""
  echo "Test 3: parse_subagent_error returns found=false when no error"

  local output="Normal output without errors"

  local result
  result=$(parse_subagent_error "$output")

  local found
  found=$(echo "$result" | jq -r '.found')
  assert_equals "false" "$found" "No error found in clean output"
}

# Test 4: query_errors filters by command
test_query_errors_filter() {
  echo ""
  echo "Test 4: query_errors filters by command"

  # Add test entries
  log_command_error "/plan" "plan_1" "desc" "validation_error" "Plan error" "bash_block" "{}"
  log_command_error "/debug" "debug_1" "issue" "agent_error" "Debug error" "bash_block" "{}"

  # Query for /build only
  local results
  results=$(query_errors --command /build --limit 10)

  # All results should be /build
  local non_build_count
  non_build_count=$(echo "$results" | jq -r '.command' | { grep -v "/build" || true; } | wc -l)
  non_build_count=$(echo "$non_build_count" | tr -d ' ' | head -1)

  if [ "$non_build_count" -eq 0 ]; then
    echo "✓ PASS: Filter returns only /build errors"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "✗ FAIL: Filter returned non-/build errors"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# Test 5: recent_errors shows formatted output
test_recent_errors() {
  echo ""
  echo "Test 5: recent_errors shows formatted output"

  local output
  output=$(recent_errors 3)

  assert_contains "Recent Errors" "$output" "Header present"
  assert_contains "/build" "$output" "Command shown"
  assert_contains "state_error" "$output" "Error type shown"
}

# Test 6: error_summary shows counts
test_error_summary() {
  echo ""
  echo "Test 6: error_summary shows counts"

  local output
  output=$(error_summary)

  assert_contains "Error Summary" "$output" "Summary header"
  assert_contains "Total Errors" "$output" "Total count shown"
  assert_contains "By Command" "$output" "Command breakdown"
  assert_contains "By Type" "$output" "Type breakdown"
}

# Test 7: Error type constants are defined
test_error_type_constants() {
  echo ""
  echo "Test 7: Error type constants are defined"

  assert_not_empty "$ERROR_TYPE_STATE" "ERROR_TYPE_STATE defined"
  assert_not_empty "$ERROR_TYPE_VALIDATION" "ERROR_TYPE_VALIDATION defined"
  assert_not_empty "$ERROR_TYPE_AGENT" "ERROR_TYPE_AGENT defined"
  assert_not_empty "$ERROR_TYPE_PARSE" "ERROR_TYPE_PARSE defined"
  assert_not_empty "$ERROR_TYPE_FILE" "ERROR_TYPE_FILE defined"
}

# Test 8: get_error_context from workflow-init.sh
test_get_error_context() {
  echo ""
  echo "Test 8: get_error_context returns workflow context"

  # Source workflow-init for get_error_context
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-init.sh" 2>/dev/null

  # Set some workflow variables
  export COMMAND_NAME="/build"
  export WORKFLOW_ID="build_test_456"
  export USER_ARGS="plan.md 3"
  export CURRENT_STATE="implement"

  local context
  context=$(get_error_context)

  local command_val
  command_val=$(echo "$context" | jq -r '.command_name')
  assert_equals "/build" "$command_val" "get_error_context returns command"

  local workflow_val
  workflow_val=$(echo "$context" | jq -r '.workflow_id')
  assert_equals "build_test_456" "$workflow_val" "get_error_context returns workflow_id"
}

# Run tests
echo "========================================"
echo "Error Logging System Tests"
echo "========================================"
echo ""

setup

test_log_command_error
test_parse_subagent_error
test_parse_subagent_error_no_error
test_query_errors_filter
test_recent_errors
test_error_summary
test_error_type_constants
test_get_error_context

# Cleanup: Remove test log file
rm -f "${CLAUDE_PROJECT_DIR}/.claude/tests/logs/test-errors.jsonl"

echo ""
echo "========================================"
echo "Test Results"
echo "========================================"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo ""

if [ "$TESTS_FAILED" -eq 0 ]; then
  echo "All tests passed!"
  exit 0
else
  echo "Some tests failed."
  exit 1
fi
