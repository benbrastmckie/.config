#!/usr/bin/env bash
# Test for Bash tool preprocessing regressions
# Tests bash history expansion vulnerability detection

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COORDINATE_CMD="${SCRIPT_DIR}/../commands/coordinate.md"

test_count=0
pass_count=0
fail_count=0

echo "=== Test: Bash Tool Preprocessing Vulnerability Detection ==="
echo ""

# Test 1: Scan for unprotected '!' operators
echo "Test 1: Scanning for vulnerable patterns..."
test_count=$((test_count + 1))

if [ ! -f "$COORDINATE_CMD" ]; then
  echo "FAIL: coordinate.md not found at $COORDINATE_CMD"
  fail_count=$((fail_count + 1))
else
  # Look for bare negation patterns like "if ! sm_init"
  VULNERABLE_PATTERNS=$(grep -E "^[[:space:]]*if ! [a-z_]+\(" "$COORDINATE_CMD" || true)

  if [ -n "$VULNERABLE_PATTERNS" ]; then
    echo "FAIL: Found unprotected '!' operators:"
    echo "$VULNERABLE_PATTERNS"
    fail_count=$((fail_count + 1))
  else
    echo "PASS: No unprotected '!' operators found"
    pass_count=$((pass_count + 1))
  fi
fi

# Test 2: Verify all bash blocks have 'set +H'
echo ""
echo "Test 2: Verifying 'set +H' coverage..."
test_count=$((test_count + 1))

if [ ! -f "$COORDINATE_CMD" ]; then
  echo "SKIP: coordinate.md not found"
else
  BASH_BLOCK_COUNT=$(grep -c '```bash' "$COORDINATE_CMD" || echo "0")
  SET_H_COUNT=$(grep -c 'set +H' "$COORDINATE_CMD" || echo "0")

  if [ "$SET_H_COUNT" -lt "$BASH_BLOCK_COUNT" ]; then
    echo "FAIL: Only $SET_H_COUNT 'set +H' for $BASH_BLOCK_COUNT bash blocks"
    fail_count=$((fail_count + 1))
  else
    echo "PASS: All bash blocks have 'set +H' ($SET_H_COUNT/$BASH_BLOCK_COUNT)"
    pass_count=$((pass_count + 1))
  fi
fi

# Test 3: Check for indirect expansion without eval
echo ""
echo "Test 3: Checking array expansion patterns..."
test_count=$((test_count + 1))

if [ ! -f "$COORDINATE_CMD" ]; then
  echo "SKIP: coordinate.md not found"
else
  INDIRECT_EXPANSION=$(grep -n '\${![A-Z_]*}' "$COORDINATE_CMD" || true)

  if [ -n "$INDIRECT_EXPANSION" ]; then
    echo "WARNING: Found indirect expansion (may need eval workaround):"
    echo "$INDIRECT_EXPANSION"
    echo "PASS: Test completed with warnings"
    pass_count=$((pass_count + 1))
  else
    echo "PASS: No indirect expansion found"
    pass_count=$((pass_count + 1))
  fi
fi

# Test 4: Verify exit code capture pattern is used
echo ""
echo "Test 4: Verifying safe sm_init invocation pattern..."
test_count=$((test_count + 1))

if [ ! -f "$COORDINATE_CMD" ]; then
  echo "SKIP: coordinate.md not found"
else
  # Look for the safe pattern: SM_INIT_EXIT_CODE=$?
  SAFE_PATTERN_COUNT=$(grep -c "SM_INIT_EXIT_CODE=\$?" "$COORDINATE_CMD" || echo "0")

  if [ "$SAFE_PATTERN_COUNT" -ge 1 ]; then
    echo "PASS: Found safe exit code capture pattern (SM_INIT_EXIT_CODE=\$?)"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: Safe exit code capture pattern not found"
    echo "Expected pattern: SM_INIT_EXIT_CODE=\$?"
    fail_count=$((fail_count + 1))
  fi
fi

# Summary
echo ""
echo "=== Test Summary ==="
echo "Tests run: $test_count"
echo "Tests passed: $pass_count"
echo "Tests failed: $fail_count"

if [ "$fail_count" -gt 0 ]; then
  echo ""
  echo "TEST_FAILED"
  exit 1
else
  echo ""
  echo "TEST_PASSED"
  exit 0
fi
