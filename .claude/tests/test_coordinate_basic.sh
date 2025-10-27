#!/usr/bin/env bash
# Test suite for /coordinate command basic functionality
# Tests Phase 1 baseline requirements

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Test counter
TESTS_RUN=0
TESTS_PASSED=0

# Helper functions
pass() {
  echo -e "${GREEN}✓${NC} $1"
  ((TESTS_PASSED++))
  ((TESTS_RUN++))
}

fail() {
  echo -e "${RED}✗${NC} $1"
  ((TESTS_RUN++))
  return 1
}

echo "========================================"
echo "  /coordinate Basic Tests (Phase 1)"
echo "========================================"
echo ""

# Test 1: Command file exists
echo "Test 1: Command file exists"
if [ -f ".claude/commands/coordinate.md" ]; then
  pass "Command file exists at .claude/commands/coordinate.md"
else
  fail "Command file missing"
fi

# Test 2: Command file is parseable (has front matter)
echo "Test 2: Command metadata present"
if grep -q "allowed-tools:" .claude/commands/coordinate.md; then
  pass "Command has allowed-tools metadata"
else
  fail "Command missing allowed-tools metadata"
fi

# Test 3: Line count verification (baseline ~2,177 lines)
echo "Test 3: File size verification"
LINE_COUNT=$(wc -l < .claude/commands/coordinate.md)
if [ "$LINE_COUNT" -ge 2000 ] && [ "$LINE_COUNT" -le 2500 ]; then
  pass "File size within expected range: $LINE_COUNT lines (baseline ~2,177)"
else
  fail "File size unexpected: $LINE_COUNT lines (expected 2000-2500)"
fi

# Test 4: No references to /supervise remain
echo "Test 4: All /supervise references updated to /coordinate"
SUPERVISE_COUNT=$(grep -c "/supervise" .claude/commands/coordinate.md || true)
if [ "$SUPERVISE_COUNT" -eq 0 ]; then
  pass "No /supervise references remain"
else
  fail "Found $SUPERVISE_COUNT /supervise references (should be 0)"
fi

# Test 5: /coordinate references present
echo "Test 5: /coordinate references present"
COORDINATE_COUNT=$(grep -c "/coordinate" .claude/commands/coordinate.md || true)
if [ "$COORDINATE_COUNT" -gt 10 ]; then
  pass "Found $COORDINATE_COUNT /coordinate references"
else
  fail "Insufficient /coordinate references: $COORDINATE_COUNT (expected >10)"
fi

# Test 6: Command description updated
echo "Test 6: Command description mentions wave-based execution"
if grep -q "wave-based\|Wave-Based" .claude/commands/coordinate.md; then
  pass "Description mentions wave-based execution"
else
  fail "Description missing wave-based execution reference"
fi

echo ""
echo "========================================"
echo "  Test Results"
echo "========================================"
echo "Tests run: $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $((TESTS_RUN - TESTS_PASSED))"

if [ "$TESTS_PASSED" -eq "$TESTS_RUN" ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed.${NC}"
  exit 1
fi
