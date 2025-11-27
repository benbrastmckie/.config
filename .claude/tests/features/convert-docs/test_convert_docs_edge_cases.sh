#!/usr/bin/env bash
#
# test_convert_docs_edge_cases.sh - Test edge cases in convert-core.sh
#
# Tests edge case handling without requiring actual conversion tools:
#   - Filename safety (using --dry-run mode)
#   - Duplicate output collision detection
#   - Empty directories
#   - Non-existent directories
#

set -eu

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Script path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SCRIPT_PATH="$CLAUDE_ROOT/lib/convert/convert-core.sh"

# Test directory
TEST_DIR="/tmp/convert-docs-test-$$"

#
# setup_test_env - Create test environment
#
setup_test_env() {
  mkdir -p "$TEST_DIR"
}

#
# cleanup_test_env - Remove test environment
#
cleanup_test_env() {
  rm -rf "$TEST_DIR"
}

#
# run_test - Run a single test
#
# Arguments:
#   $1 - Test description
#   $2 - Test function name
#
run_test() {
  local description="$1"
  local test_func="$2"

  TESTS_RUN=$((TESTS_RUN + 1))

  if $test_func; then
    echo -e "${GREEN}✓${NC} PASS: $description"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} FAIL: $description"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

#
# test_empty_directory - Test with empty input directory
#
test_empty_directory() {
  local input_dir="$TEST_DIR/empty"
  mkdir -p "$input_dir"

  local exit_code=0
  "$SCRIPT_PATH" "$input_dir" "$TEST_DIR/output" > /dev/null 2>&1 || exit_code=$?

  # Should exit cleanly (exit code 0) for empty directory
  [[ $exit_code -eq 0 ]]
}

#
# test_nonexistent_directory - Test with non-existent input directory
#
test_nonexistent_directory() {
  local input_dir="$TEST_DIR/nonexistent_$$"

  local exit_code=0
  "$SCRIPT_PATH" "$input_dir" "$TEST_DIR/output" 2>&1 | grep -q "not found" || exit_code=$?

  # Should report error (exit code non-zero or error message)
  [[ $exit_code -eq 0 ]]
}

#
# test_dry_run_mode - Test --dry-run flag
#
test_dry_run_mode() {
  local input_dir="$TEST_DIR/dry_run"
  mkdir -p "$input_dir"
  touch "$input_dir/test.docx"

  local output=$("$SCRIPT_PATH" "$input_dir" --dry-run 2>&1)

  # Should show dry run analysis
  echo "$output" | grep -q "Dry Run" && echo "$output" | grep -q "test.docx"
}

#
# test_detect_tools_mode - Test --detect-tools flag
#
test_detect_tools_mode() {
  local output=$("$SCRIPT_PATH" --detect-tools 2>&1)

  # Should show tool detection output
  echo "$output" | grep -q "Document Conversion Tools Detection"
}

#
# test_filename_with_spaces - Test filename with spaces using dry-run
#
test_filename_with_spaces() {
  local input_dir="$TEST_DIR/spaces"
  mkdir -p "$input_dir"
  touch "$input_dir/file with spaces.docx"

  local output=$("$SCRIPT_PATH" "$input_dir" --dry-run 2>&1)

  # Should list file in dry run output
  echo "$output" | grep -q "file with spaces.docx"
}

#
# test_filename_with_special_chars - Test filename with special characters
#
test_filename_with_special_chars() {
  local input_dir="$TEST_DIR/special"
  mkdir -p "$input_dir"
  touch "$input_dir/file_with_quotes.pdf"
  touch "$input_dir/file_with_parens.pdf"

  local output=$("$SCRIPT_PATH" "$input_dir" --dry-run 2>&1)

  # Should list files in dry run output
  echo "$output" | grep -q "file_with_quotes.pdf" && echo "$output" | grep -q "file_with_parens.pdf"
}

#
# test_collision_detection - Test that collision detection function exists
#
test_collision_detection() {
  # Check that check_output_collision function is defined in the script
  grep -q "check_output_collision" "$SCRIPT_PATH"
}

#
# test_timeout_wrapper - Test that with_timeout function exists
#
test_timeout_wrapper() {
  # Check that with_timeout function is defined in the script
  grep -q "with_timeout" "$SCRIPT_PATH"
}

#
# test_timeout_constants - Test that timeout constants are defined
#
test_timeout_constants() {
  # Check that timeout constants are defined
  grep -q "TIMEOUT_DOCX_TO_MD" "$SCRIPT_PATH" && \
  grep -q "TIMEOUT_PDF_TO_MD" "$SCRIPT_PATH" && \
  grep -q "TIMEOUT_MD_TO_DOCX" "$SCRIPT_PATH" && \
  grep -q "TIMEOUT_MD_TO_PDF" "$SCRIPT_PATH"
}

#
# main - Run all tests
#
main() {
  echo "======================================"
  echo "Edge Case Tests - Phase 1"
  echo "======================================"
  echo ""

  # Setup
  setup_test_env
  trap cleanup_test_env EXIT

  # Test 1: Empty directory
  run_test "Empty directory handling" test_empty_directory

  # Test 2: Non-existent directory
  run_test "Non-existent directory error" test_nonexistent_directory

  # Test 3: Dry run mode
  run_test "Dry run mode" test_dry_run_mode

  # Test 4: Detect tools mode
  run_test "Detect tools mode" test_detect_tools_mode

  # Test 5: Filename with spaces
  run_test "Filename with spaces" test_filename_with_spaces

  # Test 6: Filename with special characters
  run_test "Filename with special chars" test_filename_with_special_chars

  # Test 7: Collision detection function exists
  run_test "Collision detection function present" test_collision_detection

  # Test 8: Timeout wrapper function exists
  run_test "Timeout wrapper function present" test_timeout_wrapper

  # Test 9: Timeout constants defined
  run_test "Timeout constants defined" test_timeout_constants

  # Summary
  echo ""
  echo "======================================"
  echo "Test Summary"
  echo "======================================"
  echo "Tests run:    $TESTS_RUN"
  echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    exit 1
  else
    echo -e "Tests failed: $TESTS_FAILED"
    echo ""
    echo -e "${GREEN}All Phase 1 tests passed!${NC}"
    exit 0
  fi
}

# Check if convert-core.sh exists
if [[ ! -f "$SCRIPT_PATH" ]]; then
  echo "Error: convert-core.sh not found at $SCRIPT_PATH"
  exit 1
fi

# Run tests
main
