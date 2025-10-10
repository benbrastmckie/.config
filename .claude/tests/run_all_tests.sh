#!/usr/bin/env bash
# Run all test suites and aggregate results
# Usage: ./run_all_tests.sh [--verbose]

set -euo pipefail

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
SKIPPED_TESTS=0

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

if [ -z "$TEST_FILES" ]; then
  echo "No test files found!"
  exit 1
fi

# Run each test file
for test_file in $TEST_FILES; do
  test_name=$(basename "$test_file" .sh)

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
      # Count passes from output
      local_passed=$(echo "$test_output" | grep -c "✓ PASS" || echo "0")
      local_failed=$(echo "$test_output" | grep -c "✗ FAIL" || echo "0")
      local_skipped=$(echo "$test_output" | grep -c "⊘ SKIP" || echo "0")

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
echo -e "Total Individual Tests: ${TOTAL_TESTS}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
  echo -e "${GREEN}✓ ALL TESTS PASSED!${NC}"
  exit 0
else
  echo -e "${RED}✗ SOME TESTS FAILED${NC}"
  exit 1
fi
