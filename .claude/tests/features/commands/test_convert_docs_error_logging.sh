#!/usr/bin/env bash
# Test suite for /convert-docs error logging integration

set -euo pipefail

# Setup directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

# Test suite metadata
TEST_SUITE="convert_docs_error_logging"
TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

# Setup test environment
setup_test_env() {
  TEST_TMP_DIR=$(mktemp -d)
  TEST_ERROR_LOG="${TEST_TMP_DIR}/test-errors.jsonl"
  TEST_INPUT_DIR="${TEST_TMP_DIR}/input"
  TEST_OUTPUT_DIR="${TEST_TMP_DIR}/output"

  mkdir -p "${TEST_INPUT_DIR}"
  mkdir -p "${TEST_OUTPUT_DIR}"

  export CLAUDE_PROJECT_DIR="$PROJECT_ROOT"
  export CLAUDE_DATA_DIR="${TEST_TMP_DIR}/.claude/data"
  mkdir -p "${CLAUDE_DATA_DIR}/logs"
  export ERROR_LOG="${CLAUDE_DATA_DIR}/logs/errors.jsonl"
}

# Cleanup test environment
cleanup_test_env() {
  if [ -n "${TEST_TMP_DIR:-}" ] && [ -d "$TEST_TMP_DIR" ]; then
    rm -rf "$TEST_TMP_DIR"
  fi
  unset CLAUDE_DATA_DIR ERROR_LOG
}

# Test helper: Assert contains
assert_contains() {
  local haystack="$1"
  local needle="$2"
  local test_name="$3"

  if echo "$haystack" | grep -q "$needle"; then
    echo "  ✓ $test_name"
    PASS_COUNT=$((PASS_COUNT + 1))
    return 0
  else
    echo "  ✗ $test_name"
    echo "    Expected to find: $needle"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi
}

# Test helper: Assert file exists
assert_file_exists() {
  local file="$1"
  local test_name="$2"

  if [ -f "$file" ]; then
    echo "  ✓ $test_name"
    PASS_COUNT=$((PASS_COUNT + 1))
    return 0
  else
    echo "  ✗ $test_name"
    echo "    File not found: $file"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi
}

# Test helper: Assert log entry exists
assert_log_entry_exists() {
  local error_type="$1"
  local message_pattern="$2"
  local test_name="$3"

  if [ ! -f "$ERROR_LOG" ]; then
    echo "  ✗ $test_name"
    echo "    Error log not found: $ERROR_LOG"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  if grep -q "\"error_type\":\"$error_type\"" "$ERROR_LOG" && \
     grep -q "$message_pattern" "$ERROR_LOG"; then
    echo "  ✓ $test_name"
    PASS_COUNT=$((PASS_COUNT + 1))
    return 0
  else
    echo "  ✗ $test_name"
    echo "    Expected error_type: $error_type"
    echo "    Expected message pattern: $message_pattern"
    echo "    Actual log contents:"
    cat "$ERROR_LOG" 2>/dev/null || echo "    (empty or missing)"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi
}

# Test 1: convert-core.sh library sources without errors
test_library_sources() {
  local test_name="convert-core.sh sources without errors"
  TEST_COUNT=$((TEST_COUNT + 1))

  echo "Test: $test_name"

  if bash -c "source '${PROJECT_ROOT}/.claude/lib/convert/convert-core.sh' 2>/dev/null"; then
    echo "  ✓ Library sources successfully"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  ✗ Library failed to source"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

# Test 2: Error logging available when CLAUDE_PROJECT_DIR is set
test_error_logging_available() {
  local test_name="Error logging available with CLAUDE_PROJECT_DIR"
  TEST_COUNT=$((TEST_COUNT + 1))

  echo "Test: $test_name"

  local output
  output=$(bash -c "
    export CLAUDE_PROJECT_DIR='${PROJECT_ROOT}'
    source '${PROJECT_ROOT}/.claude/lib/convert/convert-core.sh' 2>/dev/null
    echo \$ERROR_LOGGING_AVAILABLE
  ")

  assert_contains "$output" "true" "ERROR_LOGGING_AVAILABLE is true"
}

# Test 3: Error logging unavailable when CLAUDE_PROJECT_DIR is unset
test_error_logging_unavailable() {
  local test_name="Error logging unavailable without CLAUDE_PROJECT_DIR"
  TEST_COUNT=$((TEST_COUNT + 1))

  echo "Test: $test_name"

  local output
  output=$(bash -c "
    unset CLAUDE_PROJECT_DIR
    source '${PROJECT_ROOT}/.claude/lib/convert/convert-core.sh' 2>/dev/null
    echo \$ERROR_LOGGING_AVAILABLE
  ")

  assert_contains "$output" "false" "ERROR_LOGGING_AVAILABLE is false"
}

# Test 4: Validation error logged for invalid input directory
test_validation_error_logging() {
  local test_name="Validation error logged for invalid input directory"
  TEST_COUNT=$((TEST_COUNT + 1))

  echo "Test: $test_name"

  # Call main_conversion with invalid directory in a subshell
  (
    export CLAUDE_PROJECT_DIR="${PROJECT_ROOT}"
    export CLAUDE_DATA_DIR="${CLAUDE_DATA_DIR}"
    export ERROR_LOG="${ERROR_LOG}"
    export COMMAND_NAME="/convert-docs"
    export WORKFLOW_ID="test_validation"
    export USER_ARGS="/nonexistent/directory"

    set +e  # Allow errors to continue
    source "${PROJECT_ROOT}/.claude/lib/convert/convert-core.sh" 2>/dev/null
    main_conversion '/nonexistent/directory' "${TEST_OUTPUT_DIR}" 2>&1
    exit 0
  ) >/dev/null 2>&1

  # Give a moment for file I/O to complete
  sleep 0.1

  assert_log_entry_exists "validation_error" "Input directory not found" "Validation error logged"
}

# Test 5: log_conversion_error wrapper function exists
test_wrapper_function_exists() {
  local test_name="log_conversion_error wrapper function exists"
  TEST_COUNT=$((TEST_COUNT + 1))

  echo "Test: $test_name"

  local output
  output=$(bash -c "
    export CLAUDE_PROJECT_DIR='${PROJECT_ROOT}'
    source '${PROJECT_ROOT}/.claude/lib/convert/convert-core.sh' 2>/dev/null
    type log_conversion_error
  " 2>&1)

  assert_contains "$output" "log_conversion_error is a function" "Wrapper function defined"
}

# Test 6: Backward compatibility - library works without error logging
test_backward_compatibility() {
  local test_name="Backward compatibility without error logging"
  TEST_COUNT=$((TEST_COUNT + 1))

  echo "Test: $test_name"

  # Create a valid test file
  echo "# Test document" > "${TEST_INPUT_DIR}/test.md"

  # Call with unset CLAUDE_PROJECT_DIR (should not crash)
  local output
  output=$(bash -c "
    unset CLAUDE_PROJECT_DIR
    source '${PROJECT_ROOT}/.claude/lib/convert/convert-core.sh' 2>/dev/null
    # Just verify library loads and wrapper exists
    type log_conversion_error && echo 'SUCCESS'
  " 2>&1 || echo "FAILED")

  assert_contains "$output" "SUCCESS" "Library works without error logging"
}

# Test 7: Error log entry has required fields
test_log_entry_structure() {
  local test_name="Error log entry has required fields"
  TEST_COUNT=$((TEST_COUNT + 1))

  echo "Test: $test_name"

  # Trigger validation error in a subshell
  (
    export CLAUDE_PROJECT_DIR="${PROJECT_ROOT}"
    export CLAUDE_DATA_DIR="${CLAUDE_DATA_DIR}"
    export ERROR_LOG="${ERROR_LOG}"
    export COMMAND_NAME="/convert-docs"
    export WORKFLOW_ID="test_workflow"
    export USER_ARGS="/test/path"

    set +e  # Allow errors to continue
    source "${PROJECT_ROOT}/.claude/lib/convert/convert-core.sh" 2>/dev/null
    main_conversion '/nonexistent/directory' "${TEST_OUTPUT_DIR}" 2>&1
    exit 0
  ) >/dev/null 2>&1

  # Give a moment for file I/O to complete
  sleep 0.1

  if [ -f "$ERROR_LOG" ]; then
    local log_content
    log_content=$(cat "$ERROR_LOG")

    # Check for required fields
    local all_pass=true
    assert_contains "$log_content" '"timestamp"' "Has timestamp field" || all_pass=false
    assert_contains "$log_content" '"command"' "Has command field" || all_pass=false
    assert_contains "$log_content" '"error_type"' "Has error_type field" || all_pass=false
    assert_contains "$log_content" '"error_message"' "Has error_message field" || all_pass=false

    if [ "$all_pass" = true ]; then
      echo "  ✓ All required fields present"
    fi
  else
    echo "  ✗ Error log not created"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

# Run all tests
run_all_tests() {
  echo "═══════════════════════════════════════════════════════"
  echo "Test Suite: $TEST_SUITE"
  echo "═══════════════════════════════════════════════════════"
  echo ""

  setup_test_env

  test_library_sources
  echo ""

  test_error_logging_available
  echo ""

  test_error_logging_unavailable
  echo ""

  test_wrapper_function_exists
  echo ""

  test_backward_compatibility
  echo ""

  test_validation_error_logging
  echo ""

  test_log_entry_structure
  echo ""

  cleanup_test_env

  echo "═══════════════════════════════════════════════════════"
  echo "Test Results"
  echo "═══════════════════════════════════════════════════════"
  echo "Total Tests: $TEST_COUNT"
  echo "Passed: $PASS_COUNT"
  echo "Failed: $FAIL_COUNT"
  echo ""

  if [ $FAIL_COUNT -eq 0 ]; then
    echo "✓ All tests passed"
    exit 0
  else
    echo "✗ Some tests failed"
    exit 1
  fi
}

# Run tests if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  run_all_tests
fi
