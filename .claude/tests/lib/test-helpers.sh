#!/usr/bin/env bash
# Test Helper Library - Standardized output functions for all tests
#
# Usage:
#   source "${SCRIPT_DIR}/../lib/test-helpers.sh" 2>/dev/null || source "$(dirname "$0")/../lib/test-helpers.sh"
#
# Functions:
#   pass "test_name"      - Mark test as passed
#   fail "test_name"      - Mark test as failed (returns 1)
#   skip "test_name"      - Mark test as skipped
#   assert_equals expected actual "test_name"
#   assert_contains needle haystack "test_name"
#   assert_file_exists path "test_name"
#   assert_not_empty value "test_name"
#   setup_test            - Initialize counters (call at start)
#   teardown_test         - Report summary (call at end)

# Test counters (global for accumulation)
TESTS_PASSED=${TESTS_PASSED:-0}
TESTS_FAILED=${TESTS_FAILED:-0}
TESTS_SKIPPED=${TESTS_SKIPPED:-0}

# Store failed test names for reporting
declare -a FAILED_TESTS=()

# Color codes (optional, disabled if NO_COLOR is set)
if [[ -z "${NO_COLOR:-}" ]]; then
  _GREEN='\033[0;32m'
  _RED='\033[0;31m'
  _YELLOW='\033[0;33m'
  _NC='\033[0m'
else
  _GREEN=''
  _RED=''
  _YELLOW=''
  _NC=''
fi

# Initialize test counters
# Call at the start of each test file
setup_test() {
  TESTS_PASSED=0
  TESTS_FAILED=0
  TESTS_SKIPPED=0
  FAILED_TESTS=()
}

# Report test summary
# Call at the end of each test file
teardown_test() {
  local total=$((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))
  echo ""
  echo "----------------------------------------"
  echo "Test Summary: ${total} total"
  echo "  Passed:  ${TESTS_PASSED}"
  echo "  Failed:  ${TESTS_FAILED}"
  echo "  Skipped: ${TESTS_SKIPPED}"

  if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
    echo ""
    echo "Failed tests:"
    for test_name in "${FAILED_TESTS[@]}"; do
      echo "  - ${test_name}"
    done
  fi

  echo "----------------------------------------"

  # Return exit code based on failures
  [[ ${TESTS_FAILED} -eq 0 ]]
}

# Mark test as passed
# Usage: pass "test_name"
pass() {
  local test_name="${1:-unnamed_test}"
  echo -e "${_GREEN}✓ PASS${_NC}: ${test_name}"
  ((TESTS_PASSED++))
}

# Mark test as failed
# Usage: fail "test_name" ["optional message"]
# Returns: 1 (for use in conditionals)
fail() {
  local test_name="${1:-unnamed_test}"
  local message="${2:-}"
  if [[ -n "${message}" ]]; then
    echo -e "${_RED}✗ FAIL${_NC}: ${test_name} - ${message}"
  else
    echo -e "${_RED}✗ FAIL${_NC}: ${test_name}"
  fi
  ((TESTS_FAILED++))
  FAILED_TESTS+=("${test_name}")
  return 1
}

# Mark test as skipped
# Usage: skip "test_name" ["reason"]
skip() {
  local test_name="${1:-unnamed_test}"
  local reason="${2:-}"
  if [[ -n "${reason}" ]]; then
    echo -e "${_YELLOW}⊘ SKIP${_NC}: ${test_name} - ${reason}"
  else
    echo -e "${_YELLOW}⊘ SKIP${_NC}: ${test_name}"
  fi
  ((TESTS_SKIPPED++))
}

# Assert two values are equal
# Usage: assert_equals expected actual "test_name"
assert_equals() {
  local expected="$1"
  local actual="$2"
  local test_name="${3:-assert_equals}"

  if [[ "${expected}" == "${actual}" ]]; then
    pass "${test_name}"
  else
    fail "${test_name}" "Expected '${expected}', got '${actual}'"
  fi
}

# Assert haystack contains needle
# Usage: assert_contains needle haystack "test_name"
assert_contains() {
  local needle="$1"
  local haystack="$2"
  local test_name="${3:-assert_contains}"

  if [[ "${haystack}" == *"${needle}"* ]]; then
    pass "${test_name}"
  else
    fail "${test_name}" "Expected to contain '${needle}'"
  fi
}

# Assert file exists
# Usage: assert_file_exists path "test_name"
assert_file_exists() {
  local path="$1"
  local test_name="${2:-assert_file_exists}"

  if [[ -f "${path}" ]]; then
    pass "${test_name}"
  else
    fail "${test_name}" "File not found: ${path}"
  fi
}

# Assert directory exists
# Usage: assert_dir_exists path "test_name"
assert_dir_exists() {
  local path="$1"
  local test_name="${2:-assert_dir_exists}"

  if [[ -d "${path}" ]]; then
    pass "${test_name}"
  else
    fail "${test_name}" "Directory not found: ${path}"
  fi
}

# Assert value is not empty
# Usage: assert_not_empty value "test_name"
assert_not_empty() {
  local value="$1"
  local test_name="${2:-assert_not_empty}"

  if [[ -n "${value}" ]]; then
    pass "${test_name}"
  else
    fail "${test_name}" "Value is empty"
  fi
}

# Assert value is empty
# Usage: assert_empty value "test_name"
assert_empty() {
  local value="$1"
  local test_name="${2:-assert_empty}"

  if [[ -z "${value}" ]]; then
    pass "${test_name}"
  else
    fail "${test_name}" "Expected empty, got '${value}'"
  fi
}

# Assert command succeeds (exit code 0)
# Usage: assert_success "command" "test_name"
assert_success() {
  local cmd="$1"
  local test_name="${2:-assert_success}"

  if eval "${cmd}" >/dev/null 2>&1; then
    pass "${test_name}"
  else
    fail "${test_name}" "Command failed: ${cmd}"
  fi
}

# Assert command fails (exit code non-zero)
# Usage: assert_failure "command" "test_name"
assert_failure() {
  local cmd="$1"
  local test_name="${2:-assert_failure}"

  if ! eval "${cmd}" >/dev/null 2>&1; then
    pass "${test_name}"
  else
    fail "${test_name}" "Command should have failed: ${cmd}"
  fi
}

# Assert numeric comparison
# Usage: assert_greater_than value threshold "test_name"
assert_greater_than() {
  local value="$1"
  local threshold="$2"
  local test_name="${3:-assert_greater_than}"

  if [[ "${value}" -gt "${threshold}" ]]; then
    pass "${test_name}"
  else
    fail "${test_name}" "Expected ${value} > ${threshold}"
  fi
}

# Assert numeric comparison
# Usage: assert_less_than value threshold "test_name"
assert_less_than() {
  local value="$1"
  local threshold="$2"
  local test_name="${3:-assert_less_than}"

  if [[ "${value}" -lt "${threshold}" ]]; then
    pass "${test_name}"
  else
    fail "${test_name}" "Expected ${value} < ${threshold}"
  fi
}

# Run a test function and catch errors
# Usage: run_test test_function_name
run_test() {
  local test_func="$1"

  if declare -f "${test_func}" >/dev/null 2>&1; then
    if "${test_func}"; then
      : # Test passed or already reported
    else
      : # Test failed or already reported
    fi
  else
    fail "${test_func}" "Test function not found"
  fi
}

# Log debug message (only shown if DEBUG=1)
debug_log() {
  if [[ "${DEBUG:-0}" == "1" ]]; then
    echo "[DEBUG] $*" >&2
  fi
}

# Detect project paths for test scripts
# Usage: detect_project_paths
# Sets: CLAUDE_PROJECT_DIR, CLAUDE_LIB
detect_project_paths() {
  local script_dir="${1:-$SCRIPT_DIR}"

  # Try git-based detection first
  if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    # Walk up to find .claude directory
    CLAUDE_PROJECT_DIR="$script_dir"
    while [ "$CLAUDE_PROJECT_DIR" != "/" ]; do
      if [ -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
        break
      fi
      CLAUDE_PROJECT_DIR="$(dirname "$CLAUDE_PROJECT_DIR")"
    done
  fi

  # Set library path
  CLAUDE_LIB="${CLAUDE_PROJECT_DIR}/.claude/lib"

  # Export for subshells
  export CLAUDE_PROJECT_DIR CLAUDE_LIB
}

# Export all functions for subshells
export -f setup_test teardown_test pass fail skip
export -f assert_equals assert_contains assert_file_exists assert_dir_exists
export -f assert_not_empty assert_empty assert_success assert_failure
export -f assert_greater_than assert_less_than run_test debug_log detect_project_paths
