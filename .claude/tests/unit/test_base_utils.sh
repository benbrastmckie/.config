#!/usr/bin/env bash
# Unit tests for lib/core/base-utils.sh
#
# Tests the core utility functions used across the codebase:
#   - error, warn, info, debug message functions
#   - require_command, require_file, require_dir validators

# Use set -u for undefined variables but allow command failures
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/../.."

# Source test helpers
source "${SCRIPT_DIR}/../lib/test-helpers.sh" 2>/dev/null || \
  { echo "Cannot load test helpers"; exit 1; }

# Source library under test (in subshell to avoid exit)
LIB_PATH="${PROJECT_ROOT}/lib/core/base-utils.sh"

setup_test

# Test: warn function outputs to stderr
test_warn_output() {
  local output
  output=$(bash -c "
    set +e
    source '$LIB_PATH' 2>/dev/null
    warn 'test warning message' 2>&1
  ")

  if [[ "$output" == *"Warning: test warning message"* ]]; then
    pass "warn_outputs_warning_prefix"
  else
    fail "warn_outputs_warning_prefix" "Expected 'Warning:' prefix, got: $output"
  fi
}

# Test: info function outputs to stdout
test_info_output() {
  local output
  output=$(bash -c "
    source '$LIB_PATH' 2>/dev/null
    info 'test info message'
  ")

  assert_contains "Info: test info message" "$output" "info_outputs_info_prefix"
}

# Test: debug function silent when DEBUG unset
test_debug_silent() {
  local output
  output=$(bash -c "
    unset DEBUG
    source '$LIB_PATH' 2>/dev/null
    debug 'should not appear' 2>&1
  ")

  if [[ -z "$output" || "$output" != *"should not appear"* ]]; then
    pass "debug_silent_when_unset"
  else
    fail "debug_silent_when_unset" "Debug output appeared when DEBUG unset"
  fi
}

# Test: debug function outputs when DEBUG=1
test_debug_active() {
  local output
  output=$(bash -c "
    export DEBUG=1
    source '$LIB_PATH' 2>/dev/null
    debug 'debug message' 2>&1
  ")

  assert_contains "Debug: debug message" "$output" "debug_active_when_set"
}

# Test: require_command succeeds for bash
test_require_command_exists() {
  local exit_code
  bash -c "
    source '$LIB_PATH' 2>/dev/null
    require_command bash
  " >/dev/null 2>&1
  exit_code=$?

  assert_equals "0" "$exit_code" "require_command_exists_succeeds"
}

# Test: require_command fails for nonexistent command
test_require_command_missing() {
  local exit_code
  bash -c "
    source '$LIB_PATH' 2>/dev/null
    require_command nonexistent_cmd_12345
  " >/dev/null 2>&1 || exit_code=$?

  if [[ "${exit_code:-0}" -ne 0 ]]; then
    pass "require_command_missing_fails"
  else
    fail "require_command_missing_fails" "Expected non-zero exit code"
  fi
}

# Test: require_file succeeds for existing file
test_require_file_exists() {
  local exit_code
  bash -c "
    source '$LIB_PATH' 2>/dev/null
    require_file '$LIB_PATH'
  " >/dev/null 2>&1
  exit_code=$?

  assert_equals "0" "$exit_code" "require_file_exists_succeeds"
}

# Test: require_file fails for nonexistent file
test_require_file_missing() {
  local exit_code
  bash -c "
    source '$LIB_PATH' 2>/dev/null
    require_file '/nonexistent/path/file.txt'
  " >/dev/null 2>&1 || exit_code=$?

  if [[ "${exit_code:-0}" -ne 0 ]]; then
    pass "require_file_missing_fails"
  else
    fail "require_file_missing_fails" "Expected non-zero exit code"
  fi
}

# Test: require_dir succeeds for existing directory
test_require_dir_exists() {
  local exit_code
  bash -c "
    source '$LIB_PATH' 2>/dev/null
    require_dir '${PROJECT_ROOT}/lib'
  " >/dev/null 2>&1
  exit_code=$?

  assert_equals "0" "$exit_code" "require_dir_exists_succeeds"
}

# Test: require_dir fails for nonexistent directory
test_require_dir_missing() {
  local exit_code
  bash -c "
    source '$LIB_PATH' 2>/dev/null
    require_dir '/nonexistent/directory'
  " >/dev/null 2>&1 || exit_code=$?

  if [[ "${exit_code:-0}" -ne 0 ]]; then
    pass "require_dir_missing_fails"
  else
    fail "require_dir_missing_fails" "Expected non-zero exit code"
  fi
}

# Test: error function exits with code 1
test_error_exits() {
  local exit_code
  bash -c "
    source '$LIB_PATH' 2>/dev/null
    error 'test error'
  " >/dev/null 2>&1 || exit_code=$?

  assert_equals "1" "${exit_code:-0}" "error_exits_with_code_1"
}

# Test: error function outputs error message
test_error_message() {
  local output
  output=$(bash -c "
    source '$LIB_PATH' 2>/dev/null
    error 'test error message' 2>&1
  " 2>&1 || true)

  assert_contains "Error: test error message" "$output" "error_outputs_error_prefix"
}

# Run all tests
test_warn_output
test_info_output
test_debug_silent
test_debug_active
test_require_command_exists
test_require_command_missing
test_require_file_exists
test_require_file_missing
test_require_dir_exists
test_require_dir_missing
test_error_exits
test_error_message

teardown_test
