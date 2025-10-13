#!/usr/bin/env bash
# Simple documentation verification test for orchestrate research enhancements

set -euo pipefail

ORCHESTRATE_DOC=".claude/commands/orchestrate.md"
PASSED=0
FAILED=0

pass() {
  echo "✓ PASS: $1"
  ((PASSED++))
}

fail() {
  echo "✗ FAIL: $1"
  ((FAILED++))
}

# Test 1: Absolute path specification documented
if grep -q "CRITICAL.*ABSOLUTE" "$ORCHESTRATE_DOC" && \
   grep -q "Step 2: Determine Absolute Report Paths" "$ORCHESTRATE_DOC"; then
  pass "Absolute path specification documented"
else
  fail "Absolute path specification not documented"
fi

# Test 2: Progress markers documented
if grep -q "PROGRESS:" "$ORCHESTRATE_DOC" && grep -q "REPORT_CREATED:" "$ORCHESTRATE_DOC"; then
  pass "Progress marker standards documented"
else
  fail "Progress markers not documented"
fi

# Test 3: Verification step exists
if grep -q "#### Step 4.5: Verify Report Files" "$ORCHESTRATE_DOC"; then
  pass "Step 4.5 (Verify Report Files) exists"
else
  fail "Step 4.5 not found"
fi

# Test 4: Retry step exists
if grep -q "#### Step 4.6: Retry Failed Reports" "$ORCHESTRATE_DOC"; then
  pass "Step 4.6 (Retry Failed Reports) exists"
else
  fail "Step 4.6 not found"
fi

# Test 5: Path mismatch classification
if grep -q "path_mismatch" "$ORCHESTRATE_DOC"; then
  pass "path_mismatch error classification exists"
else
  fail "path_mismatch classification not found"
fi

# Test 6: Troubleshooting section
if grep -q "Troubleshooting.*Research Phase" "$ORCHESTRATE_DOC"; then
  pass "Troubleshooting section exists"
else
  fail "Troubleshooting section not found"
fi

echo ""
echo "Tests Run: $((PASSED + FAILED))"
echo "Passed: $PASSED"
echo "Failed: $FAILED"

[ $FAILED -eq 0 ] && exit 0 || exit 1
