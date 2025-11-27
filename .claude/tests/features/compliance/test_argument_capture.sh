#!/usr/bin/env bash
# test_argument_capture.sh - Test suite for argument-capture.sh library
#
# Tests the two-step argument capture pattern library functions.
#
# Usage:
#   .claude/tests/test_argument_capture.sh

set -uo pipefail

# Test isolation: Use temp directories
export CLAUDE_SPECS_ROOT="/tmp/test_specs_$$"
export CLAUDE_PROJECT_DIR="/tmp/test_project_$$"
export HOME="/tmp/test_home_$$"

# Create test directories
mkdir -p "$CLAUDE_SPECS_ROOT"
mkdir -p "$CLAUDE_PROJECT_DIR/.claude/lib"
mkdir -p "$HOME/.claude/tmp"

# Cleanup function
cleanup() {
  rm -rf "/tmp/test_specs_$$"
  rm -rf "/tmp/test_project_$$"
  rm -rf "/tmp/test_home_$$"
}
trap cleanup EXIT

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result arrays
declare -a FAILED_TESTS=()

# Helper functions
pass() {
  ((TESTS_PASSED++))
  echo "✓ PASS: $1"
}

fail() {
  ((TESTS_FAILED++))
  FAILED_TESTS+=("$1")
  echo "✗ FAIL: $1"
  if [ -n "${2:-}" ]; then
    echo "      Reason: $2"
  fi
}

# Find the actual library location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect project root using git or walk-up pattern
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_ROOT="$(git rev-parse --show-toplevel)"
else
  CLAUDE_PROJECT_ROOT="$SCRIPT_DIR"
  while [ "$CLAUDE_PROJECT_ROOT" != "/" ]; do
    if [ -d "$CLAUDE_PROJECT_ROOT/.claude" ]; then
      break
    fi
    CLAUDE_PROJECT_ROOT="$(dirname "$CLAUDE_PROJECT_ROOT")"
  done
fi
REAL_LIB_DIR="${CLAUDE_PROJECT_ROOT}/.claude/lib"

# Check if library exists
if [ ! -f "$REAL_LIB_DIR/workflow/argument-capture.sh" ]; then
  echo "ERROR: argument-capture.sh not found at $REAL_LIB_DIR/workflow/argument-capture.sh"
  exit 1
fi

echo "=== Test Suite: argument-capture.sh ==="
echo ""

# Test 1: Library sources successfully
test_library_sources() {
  ((TESTS_RUN++))
  # Source library (unset source guard first)
  unset ARGUMENT_CAPTURE_SOURCED
  source "$REAL_LIB_DIR/workflow/argument-capture.sh"

  if [ -n "${ARGUMENT_CAPTURE_SOURCED:-}" ]; then
    pass "test_library_sources"
  else
    fail "test_library_sources" "ARGUMENT_CAPTURE_SOURCED not set"
  fi
}

# Test 2: Version variable is set
test_version_variable() {
  ((TESTS_RUN++))
  unset ARGUMENT_CAPTURE_SOURCED
  source "$REAL_LIB_DIR/workflow/argument-capture.sh"

  if [ "${ARGUMENT_CAPTURE_VERSION:-}" = "1.0.0" ]; then
    pass "test_version_variable"
  else
    fail "test_version_variable" "Expected version 1.0.0, got ${ARGUMENT_CAPTURE_VERSION:-unset}"
  fi
}

# Test 3: Part 1 creates files
test_capture_part1_creates_files() {
  ((TESTS_RUN++))
  unset ARGUMENT_CAPTURE_SOURCED
  source "$REAL_LIB_DIR/workflow/argument-capture.sh"

  # Clean up any existing files
  rm -f "${HOME}/.claude/tmp/testcmd_arg"*.txt

  # Run Part 1
  capture_argument_part1 "testcmd" "test argument value"

  # Check path file exists
  local path_file="${HOME}/.claude/tmp/testcmd_arg_path.txt"
  if [ -f "$path_file" ]; then
    # Check temp file exists
    local temp_file=$(cat "$path_file")
    if [ -f "$temp_file" ]; then
      pass "test_capture_part1_creates_files"
    else
      fail "test_capture_part1_creates_files" "Temp file not found: $temp_file"
    fi
  else
    fail "test_capture_part1_creates_files" "Path file not found: $path_file"
  fi
}

# Test 4: Part 2 reads content
test_capture_part2_reads_content() {
  ((TESTS_RUN++))
  unset ARGUMENT_CAPTURE_SOURCED
  source "$REAL_LIB_DIR/workflow/argument-capture.sh"

  # Clean up and setup
  rm -f "${HOME}/.claude/tmp/testcmd2_arg"*.txt
  capture_argument_part1 "testcmd2" "hello world"

  # Run Part 2
  capture_argument_part2 "testcmd2" "TEST_VAR"

  if [ "${TEST_VAR:-}" = "hello world" ]; then
    pass "test_capture_part2_reads_content"
  else
    fail "test_capture_part2_reads_content" "Expected 'hello world', got '${TEST_VAR:-unset}'"
  fi
}

# Test 5: Part 2 exports variable
test_capture_part2_exports_variable() {
  ((TESTS_RUN++))
  unset ARGUMENT_CAPTURE_SOURCED
  source "$REAL_LIB_DIR/workflow/argument-capture.sh"

  # Clean up and setup
  rm -f "${HOME}/.claude/tmp/testcmd3_arg"*.txt
  capture_argument_part1 "testcmd3" "export test"

  # Run Part 2 in subshell and check if variable is exported
  (
    capture_argument_part2 "testcmd3" "EXPORTED_VAR"
    # Export status is set by the function
    if [ "${EXPORTED_VAR:-}" = "export test" ]; then
      exit 0
    else
      exit 1
    fi
  )

  if [ $? -eq 0 ]; then
    pass "test_capture_part2_exports_variable"
  else
    fail "test_capture_part2_exports_variable" "Variable not properly exported"
  fi
}

# Test 6: Cleanup removes files
test_cleanup_removes_files() {
  ((TESTS_RUN++))
  unset ARGUMENT_CAPTURE_SOURCED
  source "$REAL_LIB_DIR/workflow/argument-capture.sh"

  # Clean up and setup
  rm -f "${HOME}/.claude/tmp/testcmd4_arg"*.txt
  capture_argument_part1 "testcmd4" "cleanup test"

  # Verify files exist before cleanup
  local path_file="${HOME}/.claude/tmp/testcmd4_arg_path.txt"
  if [ ! -f "$path_file" ]; then
    fail "test_cleanup_removes_files" "Path file not created for cleanup test"
    return
  fi

  local temp_file=$(cat "$path_file")

  # Run cleanup
  cleanup_argument_files "testcmd4"

  # Verify files removed
  if [ ! -f "$path_file" ] && [ ! -f "$temp_file" ]; then
    pass "test_cleanup_removes_files"
  else
    fail "test_cleanup_removes_files" "Files not removed after cleanup"
  fi
}

# Test 7: Part 2 fails without Part 1
test_part2_fails_without_part1() {
  ((TESTS_RUN++))
  unset ARGUMENT_CAPTURE_SOURCED
  source "$REAL_LIB_DIR/workflow/argument-capture.sh"

  # Clean up any existing files
  rm -f "${HOME}/.claude/tmp/nopart1_arg"*.txt

  # Run Part 2 without Part 1 (should fail)
  if capture_argument_part2 "nopart1" "SOME_VAR" 2>/dev/null; then
    fail "test_part2_fails_without_part1" "Part 2 should have failed"
  else
    pass "test_part2_fails_without_part1"
  fi
}

# Test 8: Part 2 fails with empty content
test_part2_fails_with_empty_content() {
  ((TESTS_RUN++))
  unset ARGUMENT_CAPTURE_SOURCED
  source "$REAL_LIB_DIR/workflow/argument-capture.sh"

  # Clean up and create empty file
  rm -f "${HOME}/.claude/tmp/emptycmd_arg"*.txt
  capture_argument_part1 "emptycmd" ""

  # Run Part 2 with empty content (should fail)
  if capture_argument_part2 "emptycmd" "EMPTY_VAR" 2>/dev/null; then
    fail "test_part2_fails_with_empty_content" "Part 2 should have failed with empty content"
  else
    pass "test_part2_fails_with_empty_content"
  fi
}

# Test 9: Handles special characters
test_handles_special_characters() {
  ((TESTS_RUN++))
  unset ARGUMENT_CAPTURE_SOURCED
  source "$REAL_LIB_DIR/workflow/argument-capture.sh"

  # Clean up and setup with special characters
  rm -f "${HOME}/.claude/tmp/specialcmd_arg"*.txt
  local special_string='test with $VAR, "quotes", and `backticks`'
  capture_argument_part1 "specialcmd" "$special_string"

  # Run Part 2
  capture_argument_part2 "specialcmd" "SPECIAL_VAR"

  if [ "${SPECIAL_VAR:-}" = "$special_string" ]; then
    pass "test_handles_special_characters"
  else
    fail "test_handles_special_characters" "Special characters not preserved"
  fi
}

# Test 10: Legacy fallback works
test_legacy_fallback() {
  ((TESTS_RUN++))
  unset ARGUMENT_CAPTURE_SOURCED
  source "$REAL_LIB_DIR/workflow/argument-capture.sh"

  # Clean up and create legacy file directly (without path file)
  rm -f "${HOME}/.claude/tmp/legacycmd_arg"*.txt
  local legacy_file="${HOME}/.claude/tmp/legacycmd_arg.txt"
  echo "legacy content" > "$legacy_file"

  # Run Part 2 (should fall back to legacy file)
  capture_argument_part2 "legacycmd" "LEGACY_VAR"

  if [ "${LEGACY_VAR:-}" = "legacy content" ]; then
    pass "test_legacy_fallback"
  else
    fail "test_legacy_fallback" "Legacy fallback did not work, got '${LEGACY_VAR:-unset}'"
  fi
}

# Run all tests
echo "Running tests..."
echo ""

test_library_sources
test_version_variable
test_capture_part1_creates_files
test_capture_part2_reads_content
test_capture_part2_exports_variable
test_cleanup_removes_files
test_part2_fails_without_part1
test_part2_fails_with_empty_content
test_handles_special_characters
test_legacy_fallback

# Print summary
echo ""
echo "=== Test Results ==="
echo "Total: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"

if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
  echo ""
  echo "Failed tests:"
  for test in "${FAILED_TESTS[@]}"; do
    echo "  - $test"
  done
fi

echo ""

# Exit with appropriate code
if [ $TESTS_FAILED -eq 0 ]; then
  echo "All tests passed!"
  exit 0
else
  echo "Some tests failed!"
  exit 1
fi
