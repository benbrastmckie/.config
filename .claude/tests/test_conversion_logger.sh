#!/usr/bin/env bash
#
# test_conversion_logger.sh - Test conversion-logger.sh library
#

set -euo pipefail

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
LIBRARY_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/conversion-logger.sh"

# Test directory
TEST_DIR="/tmp/conversion-logger-test-$$"
TEST_LOG="$TEST_DIR/test.log"

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
# test_library_sources - Test that library can be sourced
#
test_library_sources() {
  source "$LIBRARY_PATH"
  return 0
}

#
# test_init_conversion_log - Test log initialization
#
test_init_conversion_log() {
  source "$LIBRARY_PATH"

  init_conversion_log "$TEST_LOG" "/input" "/output"

  [[ -f "$TEST_LOG" ]] && grep -q "Document Conversion Log" "$TEST_LOG"
}

#
# test_log_conversion_success - Test success logging
#
test_log_conversion_success() {
  source "$LIBRARY_PATH"

  init_conversion_log "$TEST_LOG"
  log_conversion_success "/input/test.docx" "/output/test.md" "markitdown" 1500

  grep -q "SUCCESS: test.docx" "$TEST_LOG" && \
  grep -q "Tool: markitdown" "$TEST_LOG" && \
  grep -q "Duration: 1500ms" "$TEST_LOG"
}

#
# test_log_conversion_failure - Test failure logging
#
test_log_conversion_failure() {
  source "$LIBRARY_PATH"

  init_conversion_log "$TEST_LOG"
  log_conversion_failure "/input/fail.pdf" "Tool not available" "marker_pdf"

  grep -q "FAILURE: fail.pdf" "$TEST_LOG" && \
  grep -q "Tool: marker_pdf" "$TEST_LOG" && \
  grep -q "Error: Tool not available" "$TEST_LOG"
}

#
# test_log_validation_check - Test validation logging
#
test_log_validation_check() {
  source "$LIBRARY_PATH"

  init_conversion_log "$TEST_LOG"
  log_validation_check "/input/test.docx" "magic_number" "pass" "Valid DOCX signature"

  grep -q "VALIDATION" "$TEST_LOG" && \
  grep -q "magic_number" "$TEST_LOG" && \
  grep -q "Valid DOCX signature" "$TEST_LOG"
}

#
# test_log_summary - Test summary logging
#
test_log_summary() {
  source "$LIBRARY_PATH"

  init_conversion_log "$TEST_LOG"
  log_summary 10 8 2 0

  grep -q "CONVERSION SUMMARY" "$TEST_LOG" && \
  grep -q "Total Files Processed: 10" "$TEST_LOG" && \
  grep -q "Successful: 8" "$TEST_LOG" && \
  grep -q "Failed: 2" "$TEST_LOG"
}

#
# test_log_phase_tracking - Test phase start/end logging
#
test_log_phase_tracking() {
  source "$LIBRARY_PATH"

  init_conversion_log "$TEST_LOG"
  log_phase_start "TOOL DETECTION"
  log_phase_end "TOOL DETECTION"

  grep -q "TOOL DETECTION PHASE" "$TEST_LOG" && \
  grep -q "END: TOOL DETECTION PHASE" "$TEST_LOG"
}

#
# test_log_fallback - Test fallback logging
#
test_log_fallback() {
  source "$LIBRARY_PATH"

  init_conversion_log "$TEST_LOG"
  log_conversion_fallback "/input/test.pdf" "marker_pdf" "pymupdf4llm"

  grep -q "FALLBACK: test.pdf" "$TEST_LOG" && \
  grep -q "marker_pdf failed" "$TEST_LOG" && \
  grep -q "trying pymupdf4llm" "$TEST_LOG"
}

#
# test_log_tool_detection - Test tool detection logging
#
test_log_tool_detection() {
  source "$LIBRARY_PATH"

  init_conversion_log "$TEST_LOG"
  log_tool_detection "markitdown" "true" "1.0.0"
  log_tool_detection "pandoc" "false"

  grep -q "TOOL DETECTION: markitdown - AVAILABLE (1.0.0)" "$TEST_LOG" && \
  grep -q "TOOL DETECTION: pandoc - NOT AVAILABLE" "$TEST_LOG"
}

#
# test_format_consistency - Test log format consistency
#
test_format_consistency() {
  source "$LIBRARY_PATH"

  init_conversion_log "$TEST_LOG"
  log_phase_start "TEST PHASE"
  log_conversion_start "/input/test.docx" "markdown"
  log_conversion_success "/input/test.docx" "/output/test.md" "markitdown" 1000
  log_phase_end "TEST PHASE"

  # Check for section separators
  grep -q "========================================" "$TEST_LOG" && \
  # Check for timestamps
  grep -q "\[20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]" "$TEST_LOG"
}

#
# main - Run all tests
#
main() {
  echo "========================================"
  echo "Conversion Logger Library Tests"
  echo "========================================"
  echo ""

  # Setup
  setup_test_env
  trap cleanup_test_env EXIT

  # Test 1: Library sources
  run_test "Library can be sourced" test_library_sources

  # Test 2: Log initialization
  run_test "Log initialization" test_init_conversion_log

  # Test 3: Success logging
  run_test "Success logging" test_log_conversion_success

  # Test 4: Failure logging
  run_test "Failure logging" test_log_conversion_failure

  # Test 5: Validation logging
  run_test "Validation logging" test_log_validation_check

  # Test 6: Summary logging
  run_test "Summary logging" test_log_summary

  # Test 7: Phase tracking
  run_test "Phase start/end logging" test_log_phase_tracking

  # Test 8: Fallback logging
  run_test "Fallback logging" test_log_fallback

  # Test 9: Tool detection logging
  run_test "Tool detection logging" test_log_tool_detection

  # Test 10: Format consistency
  run_test "Log format consistency" test_format_consistency

  # Summary
  echo ""
  echo "========================================"
  echo "Test Summary"
  echo "========================================"
  echo "Tests run:    $TESTS_RUN"
  echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    exit 1
  else
    echo -e "Tests failed: $TESTS_FAILED"
    echo ""
    echo -e "${GREEN}All conversion logger tests passed!${NC}"
    exit 0
  fi
}

# Check if library exists
if [[ ! -f "$LIBRARY_PATH" ]]; then
  echo "Error: conversion-logger.sh not found at $LIBRARY_PATH"
  exit 1
fi

# Run tests
main
