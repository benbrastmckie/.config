#!/usr/bin/env bash
# test_state_persistence_discovery.sh - Unit tests for discover_latest_state_file()
#
# Tests state file discovery mechanism for concurrent execution safety.
# Validates discovery with 0, 1, 5, 10 state files and concurrent creation edge cases.

set -uo pipefail
# Note: Not using -e (errexit) to allow tests to continue after failures

# Source the library under test
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
export CLAUDE_PROJECT_DIR

if ! source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null; then
  echo "ERROR: Cannot load state-persistence library from: ${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
  echo "PWD: $(pwd)"
  exit 1
fi

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
pass() {
  echo "  ✓ $1"
  ((TESTS_PASSED++))
}

fail() {
  echo "  ✗ $1"
  ((TESTS_FAILED++))
}

setup_test_dir() {
  TEST_TMP="${CLAUDE_PROJECT_DIR}/.claude/tmp/test_discovery_$$"
  mkdir -p "$TEST_TMP"
  # Don't modify CLAUDE_PROJECT_DIR - the library functions will use the correct path
}

cleanup_test_dir() {
  if [ -d "${TEST_TMP:-}" ]; then
    rm -rf "$TEST_TMP"
  fi
}

# Test 1: No state files (empty directory)
test_no_state_files() {
  echo "Test 1: No state files"
  setup_test_dir

  # Use a unique test prefix that won't match real state files
  result=$(discover_latest_state_file "testnonexistent" 2>/dev/null || echo "")

  if [ -z "$result" ]; then
    pass "Returns empty string when no state files exist"
  else
    fail "Should return empty string, got: $result"
  fi

  cleanup_test_dir
}

# Test 2: Single state file
test_single_state_file() {
  echo "Test 2: Single state file"

  # Create single state file in .claude/tmp with unique prefix
  local test_file="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_testunique1_1732741234567890123.sh"
  touch "$test_file"

  result=$(discover_latest_state_file "testunique1" 2>/dev/null)

  if [[ "$result" == *"workflow_testunique1_1732741234567890123.sh" ]]; then
    pass "Discovers single state file"
  else
    fail "Should discover single file, got: $result"
  fi

  # Cleanup
  rm -f "$test_file"
}

# Test 3: Multiple state files (5) - should return most recent
test_multiple_state_files() {
  echo "Test 3: Multiple state files (5)"

  local tmp_dir="${CLAUDE_PROJECT_DIR}/.claude/tmp"
  local files=()

  # Create 5 state files with different mtimes
  for i in {0..4}; do
    local file="${tmp_dir}/workflow_testunique2_173274123456789010${i}.sh"
    touch -t "20231101010${i}" "$file"
    files+=("$file")
  done

  result=$(discover_latest_state_file "testunique2" 2>/dev/null)

  if [[ "$result" == *"workflow_testunique2_1732741234567890104.sh" ]]; then
    pass "Discovers most recent of 5 state files"
  else
    fail "Should discover file ending in 104, got: $result"
  fi

  # Cleanup
  rm -f "${files[@]}"
}

# Test 4: 10 state files - stress test
test_ten_state_files() {
  echo "Test 4: 10 state files (stress test)"

  local tmp_dir="${CLAUDE_PROJECT_DIR}/.claude/tmp"
  local files=()

  # Create 10 state files
  for i in {0..9}; do
    local timestamp="173274123456789010${i}"
    local file="${tmp_dir}/workflow_testunique3_${timestamp}.sh"
    touch -t "20231101010${i}" "$file"
    files+=("$file")
  done

  result=$(discover_latest_state_file "testunique3" 2>/dev/null)

  if [[ "$result" == *"workflow_testunique3_"*"109.sh" ]]; then
    pass "Discovers most recent of 10 state files"
  else
    fail "Should discover file ending in 109, got: $result"
  fi

  # Cleanup
  rm -f "${files[@]}"
}

# Test 5: Concurrent file creation (simulated with same mtime)
test_concurrent_creation() {
  echo "Test 5: Concurrent file creation (same mtime)"

  local tmp_dir="${CLAUDE_PROJECT_DIR}/.claude/tmp"

  # Create 2 files with same mtime (simulates concurrent creation)
  local file1="${tmp_dir}/workflow_testunique4_1732741234567890200.sh"
  local file2="${tmp_dir}/workflow_testunique4_1732741234567890201.sh"
  touch -t 202311010105 "$file1"
  touch -t 202311010105 "$file2"

  result=$(discover_latest_state_file "testunique4" 2>/dev/null)

  # Should return one of them (either is acceptable for same mtime)
  if [[ "$result" == *"workflow_testunique4_"* ]]; then
    pass "Handles concurrent creation (same mtime)"
  else
    fail "Should discover one of the files, got: $result"
  fi

  # Cleanup
  rm -f "$file1" "$file2"
}

# Test 6: Command prefix filtering
test_command_prefix_filtering() {
  echo "Test 6: Command prefix filtering"

  local tmp_dir="${CLAUDE_PROJECT_DIR}/.claude/tmp"

  # Create state files for different commands with unique test prefixes
  local file1="${tmp_dir}/workflow_testunique5a_1732741234567890300.sh"
  local file2="${tmp_dir}/workflow_testunique5b_1732741234567890301.sh"
  local file3="${tmp_dir}/workflow_testunique5c_1732741234567890302.sh"

  touch -t 202311010100 "$file1"
  touch -t 202311010101 "$file2"
  touch -t 202311010102 "$file3"

  result=$(discover_latest_state_file "testunique5b" 2>/dev/null)

  if [[ "$result" == *"workflow_testunique5b_1732741234567890301.sh" ]]; then
    pass "Filters by command prefix correctly"
  else
    fail "Should discover only 'testunique5b' file, got: $result"
  fi

  # Cleanup
  rm -f "$file1" "$file2" "$file3"
}

# Test 7: Missing .claude/tmp directory
test_missing_tmp_dir() {
  echo "Test 7: Missing .claude/tmp directory"

  # Temporarily point to non-existent directory
  ORIG_CLAUDE_PROJECT_DIR="$CLAUDE_PROJECT_DIR"
  CLAUDE_PROJECT_DIR="/tmp/nonexistent_claude_test_$$"

  result=$(discover_latest_state_file "plan" 2>/dev/null || echo "")

  if [ -z "$result" ]; then
    pass "Handles missing .claude/tmp directory gracefully"
  else
    fail "Should return empty for missing directory, got: $result"
  fi

  CLAUDE_PROJECT_DIR="$ORIG_CLAUDE_PROJECT_DIR"
}

# Test 8: Empty command prefix (error case)
test_empty_command_prefix() {
  echo "Test 8: Empty command prefix (validation)"
  setup_test_dir

  result=$(discover_latest_state_file "" 2>&1 || echo "ERROR_CAUGHT")

  if [[ "$result" == *"ERROR"* ]]; then
    pass "Rejects empty command prefix with error"
  else
    fail "Should error on empty prefix, got: $result"
  fi

  cleanup_test_dir
}

# Run all tests
echo "====================================="
echo "State File Discovery Tests"
echo "====================================="
echo ""

test_no_state_files
test_single_state_file
test_multiple_state_files
test_ten_state_files
test_concurrent_creation
test_command_prefix_filtering
test_missing_tmp_dir
test_empty_command_prefix

echo ""
echo "====================================="
echo "Test Results"
echo "====================================="
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo "✓ All tests passed"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
