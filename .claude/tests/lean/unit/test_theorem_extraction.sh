#!/usr/bin/env bash
# Unit test: Theorem extraction from Lean files

set -euo pipefail

TEST_NAME="Theorem Extraction from Lean Files"
PASS_COUNT=0
FAIL_COUNT=0

echo "═══════════════════════════════════════════════════════════"
echo " TEST: $TEST_NAME"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Test fixture directory
FIXTURE_DIR="$(dirname "$0")/../fixtures"
TEST_FILE="$FIXTURE_DIR/six_theorem_test.lean"

# Test 1: Count total theorems
echo "Test 1: Count total theorems with sorry markers"
expected_count=6
actual_count=$(grep -c "sorry" "$TEST_FILE" || echo "0")

if [ "$actual_count" -eq "$expected_count" ]; then
  echo "  ✅ PASS: Found $actual_count theorems (expected $expected_count)"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "  ❌ FAIL: Found $actual_count theorems (expected $expected_count)"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# Test 2: Extract theorem names
echo ""
echo "Test 2: Extract theorem names"
expected_theorems="add_comm_test mul_comm_test add_zero_test add_assoc_test mul_one_test zero_mul_test"
actual_theorems=$(grep "^theorem" "$TEST_FILE" | awk '{print $2}' | tr '\n' ' ')

if [ "$actual_theorems" = "$expected_theorems " ]; then
  echo "  ✅ PASS: Extracted correct theorem names"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "  ❌ FAIL: Theorem name mismatch"
  echo "    Expected: $expected_theorems"
  echo "    Actual: $actual_theorems"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# Test 3: Extract theorem line numbers
echo ""
echo "Test 3: Extract theorem line numbers"
expected_lines="9 12 15 20 23 26"
actual_lines=$(grep -n "^theorem" "$TEST_FILE" | cut -d':' -f1 | tr '\n' ' ')

if [ "$actual_lines" = "$expected_lines " ]; then
  echo "  ✅ PASS: Extracted correct line numbers"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "  ❌ FAIL: Line number mismatch"
  echo "    Expected: $expected_lines"
  echo "    Actual: $actual_lines"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# Test 4: Extract sorry line numbers
echo ""
echo "Test 4: Extract sorry marker line numbers"
expected_sorry_lines="10 13 16 21 24 27"
actual_sorry_lines=$(grep -n "sorry" "$TEST_FILE" | cut -d':' -f1 | tr '\n' ' ')

if [ "$actual_sorry_lines" = "$expected_sorry_lines " ]; then
  echo "  ✅ PASS: Extracted correct sorry line numbers"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "  ❌ FAIL: Sorry line number mismatch"
  echo "    Expected: $expected_sorry_lines"
  echo "    Actual: $actual_sorry_lines"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# Test 5: Theorem-Sorry pairing
echo ""
echo "Test 5: Verify theorem-sorry pairing (sorry on next line after theorem)"
PAIRING_PASS=true

for theorem_line in $expected_lines; do
  sorry_line=$((theorem_line + 1))
  if ! echo "$actual_sorry_lines" | grep -q "$sorry_line"; then
    echo "  ❌ FAIL: Theorem at line $theorem_line does not have sorry on next line"
    PAIRING_PASS=false
  fi
done

if [ "$PAIRING_PASS" = true ]; then
  echo "  ✅ PASS: All theorems have sorry on next line"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# Summary
echo ""
echo "═══════════════════════════════════════════════════════════"
echo " TEST SUMMARY"
echo "═══════════════════════════════════════════════════════════"
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"
echo "Total: $((PASS_COUNT + FAIL_COUNT))"
echo ""

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "Result: ✅ ALL TESTS PASSED"
  exit 0
else
  echo "Result: ❌ SOME TESTS FAILED"
  exit 1
fi
