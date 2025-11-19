#!/usr/bin/env bash
# Test: Complete Test Suite for /coordinate Command
# Runs all test categories and reports comprehensive coverage

set -e

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test suite tracker
SUITES_RUN=0
SUITES_PASSED=0
SUITES_FAILED=0

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   /coordinate Command Test Suite      ${NC}"
echo -e "${BLUE}========================================${NC}"

# Helper function to run a test suite
run_test_suite() {
  local suite_name="$1"
  local test_script="$2"

  echo -e "\n${YELLOW}Running: $suite_name${NC}"
  echo "----------------------------------------"

  SUITES_RUN=$((SUITES_RUN + 1))

  if bash "$test_script"; then
    echo -e "${GREEN}✓ $suite_name PASSED${NC}"
    SUITES_PASSED=$((SUITES_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗ $suite_name FAILED${NC}"
    SUITES_FAILED=$((SUITES_FAILED + 1))
    return 1
  fi
}

# Run all test suites
run_test_suite "Basic Tests" "$SCRIPT_DIR/test_coordinate_basic.sh"
run_test_suite "Agent Delegation Tests" "$SCRIPT_DIR/test_coordinate_delegation.sh"
run_test_suite "Wave Execution Tests" "$SCRIPT_DIR/test_coordinate_waves.sh"
run_test_suite "Standards Compliance Tests" "$SCRIPT_DIR/test_coordinate_standards.sh"

# Calculate total test count
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}   Test Coverage Summary                ${NC}"
echo -e "${BLUE}========================================${NC}"

TOTAL_TESTS=0
for test_file in "$SCRIPT_DIR"/test_coordinate_*.sh; do
  if [ -f "$test_file" ] && [ "$test_file" != "$SCRIPT_DIR/test_coordinate_all.sh" ]; then
    test_count=$(grep -c "TESTS_RUN=\$((TESTS_RUN + 1))" "$test_file" || echo 0)
    test_name=$(basename "$test_file" .sh)
    echo "  $test_name: ~$test_count tests"
    TOTAL_TESTS=$((TOTAL_TESTS + test_count))
  fi
done

echo ""
echo "Total tests across all suites: ~$TOTAL_TESTS"
echo "Target test count: ≥20"

if [ $TOTAL_TESTS -ge 20 ]; then
  echo -e "${GREEN}✓ Test coverage target met${NC}"
else
  echo -e "${RED}✗ Test coverage below target${NC}"
fi

# Final summary
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}   Final Results                        ${NC}"
echo -e "${BLUE}========================================${NC}"
echo "Test suites run:    $SUITES_RUN"
echo -e "Test suites passed: ${GREEN}$SUITES_PASSED${NC}"
echo -e "Test suites failed: ${RED}$SUITES_FAILED${NC}"

if [ $SUITES_FAILED -eq 0 ]; then
  echo -e "\n${GREEN}🎉 All test suites passed!${NC}"
  exit 0
else
  echo -e "\n${RED}❌ Some test suites failed.${NC}"
  exit 1
fi
