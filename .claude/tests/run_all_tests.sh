#!/usr/bin/env bash
# Run all test suites and aggregate results
# Usage: ./run_all_tests.sh [--verbose]

set -euo pipefail

# Enable test mode to avoid real LLM API calls during testing
# This returns canned responses from workflow-llm-classifier.sh
# Following best practices: mock LLM calls at function level for fast, deterministic tests
export WORKFLOW_CLASSIFICATION_TEST_MODE=1

VERBOSE=false
if [ "${1:-}" = "--verbose" ]; then
  VERBOSE=true
fi

# Test directory
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Track results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_SUITES=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "════════════════════════════════════════════════"
echo "  Claude Code Test Suite Runner"
echo "════════════════════════════════════════════════"
echo ""

# Find all test files
TEST_FILES=$(find "$TEST_DIR" -name "test_*.sh" -not -name "run_all_tests.sh" | sort)

# Find all validation scripts
VALIDATION_FILES=$(find "$TEST_DIR" -name "validate_*.sh" | sort)

# Combine test and validation files
ALL_TEST_FILES="$TEST_FILES $VALIDATION_FILES"

if [ -z "$ALL_TEST_FILES" ]; then
  echo "No test files found!"
  exit 1
fi

# Run each test file
for test_file in $ALL_TEST_FILES; do
  test_name=$(basename "$test_file" .sh)

  # Check if test should be skipped
  if [ -f "${test_file}.skip" ]; then
    skip_reason=$(cat "${test_file}.skip" 2>/dev/null || echo "No reason provided")
    echo -e "${YELLOW}⊘ SKIPPING: $test_name${NC}"
    echo "  Reason: $skip_reason"
    echo ""
    SKIPPED_SUITES=$((SKIPPED_SUITES + 1))
    continue
  fi

  echo -e "${BLUE}Running: $test_name${NC}"
  echo "────────────────────────────────────────────────"

  # Run test and capture output
  if [ "$VERBOSE" = true ]; then
    if bash "$test_file"; then
      echo -e "${GREEN}✓ $test_name PASSED${NC}"
      PASSED_TESTS=$((PASSED_TESTS + 1))
    else
      echo -e "${RED}✗ $test_name FAILED${NC}"
      FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
  else
    # Capture output
    test_output=$(bash "$test_file" 2>&1 || echo "TEST_FAILED")

    if echo "$test_output" | grep -q "TEST_FAILED"; then
      echo -e "${RED}✗ $test_name FAILED${NC}"
      echo "$test_output" | tail -20
      FAILED_TESTS=$((FAILED_TESTS + 1))
    else
      # Count passes from output (grep -c returns 0 on no match but exits with 1)
      # For FAIL, exclude summary lines (e.g., "✗ FAIL: 0") by filtering out lines ending with ": [number]"
      local_passed=$(echo "$test_output" | grep -c "✓ PASS" || true)
      local_failed=$(echo "$test_output" | grep "✗ FAIL" | grep -v "✗ FAIL: [0-9]\+$" | wc -l || true)
      local_skipped=$(echo "$test_output" | grep -c "⊘ SKIP" || true)

      # Ensure values are numeric (grep -c always outputs a number, but double-check)
      [ -z "$local_passed" ] && local_passed=0
      [ -z "$local_failed" ] && local_failed=0
      [ -z "$local_skipped" ] && local_skipped=0

      TOTAL_TESTS=$((TOTAL_TESTS + local_passed + local_failed + local_skipped))

      if [ "$local_failed" -eq 0 ]; then
        echo -e "${GREEN}✓ $test_name PASSED${NC} ($local_passed tests)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
      else
        echo -e "${RED}✗ $test_name FAILED${NC} ($local_failed/$((local_passed + local_failed)) tests failed)"
        echo "$test_output" | grep "✗ FAIL"
        FAILED_TESTS=$((FAILED_TESTS + 1))
      fi
    fi
  fi

  echo ""
done

# Summary
echo "════════════════════════════════════════════════"
echo "  Test Results Summary"
echo "════════════════════════════════════════════════"
echo -e "Test Suites Passed:  ${GREEN}${PASSED_TESTS}${NC}"
echo -e "Test Suites Failed:  ${RED}${FAILED_TESTS}${NC}"
if [ $SKIPPED_SUITES -gt 0 ]; then
  echo -e "Test Suites Skipped: ${YELLOW}${SKIPPED_SUITES}${NC}"
fi
echo -e "Total Individual Tests: ${TOTAL_TESTS}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
  echo -e "${GREEN}✓ ALL TESTS PASSED!${NC}"
  exit 0
else
  echo -e "${RED}✗ SOME TESTS FAILED${NC}"
  exit 1
fi
