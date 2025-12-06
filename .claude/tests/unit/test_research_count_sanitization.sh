#!/usr/bin/env bash
# Unit Test: Research Command Count Sanitization
# Tests 4-step sanitization pattern prevents empty string errors
# Reference: defensive-programming.md Section 6

set -euo pipefail

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper
assert_equals() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [ "$expected" = "$actual" ]; then
    echo "✓ PASS: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo "✗ FAIL: $test_name"
    echo "  Expected: '$expected'"
    echo "  Actual:   '$actual'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Apply 4-step sanitization pattern
sanitize_count() {
  local count="$1"
  # Step 1: Capture output (already done by caller)
  # Step 2: Strip newlines and spaces
  count=$(echo "$count" | tr -d '\n' | tr -d ' ')
  # Step 3: Apply default if empty
  count=${count:-0}
  # Step 4: Validate numeric and reset if invalid
  [[ "$count" =~ ^[0-9]+$ ]] || count=0
  echo "$count"
}

echo "=========================================="
echo "Unit Test: Count Sanitization Pattern"
echo "=========================================="
echo ""

# Test 1: Normal case - simple number
result=$(sanitize_count "5")
assert_equals "5" "$result" "Normal case (5)"

# Test 2: Empty string
result=$(sanitize_count "")
assert_equals "0" "$result" "Empty string"

# Test 3: Newline corruption (0\n0)
result=$(sanitize_count "0
0")
assert_equals "00" "$result" "Newline corruption (0\\n0 → 00)"

# Test 4: Newline corruption (3\n0)
result=$(sanitize_count "3
0")
assert_equals "30" "$result" "Newline corruption (3\\n0 → 30)"

# Test 5: Whitespace padding
result=$(sanitize_count " 5 ")
assert_equals "5" "$result" "Whitespace padding"

# Test 6: Non-numeric (error)
result=$(sanitize_count "error")
assert_equals "0" "$result" "Non-numeric (error)"

# Test 7: Non-numeric (grep: file)
result=$(sanitize_count "grep: file")
assert_equals "0" "$result" "Non-numeric (grep: file)"

# Test 8: Zero
result=$(sanitize_count "0")
assert_equals "0" "$result" "Zero"

# Test 9: Large number
result=$(sanitize_count "1234")
assert_equals "1234" "$result" "Large number"

# Test 10: Multiple spaces
result=$(sanitize_count "  1 2 3  ")
assert_equals "123" "$result" "Multiple spaces"

echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Tests run:    $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo "✓ ALL TESTS PASSED"
  exit 0
else
  echo "✗ SOME TESTS FAILED"
  exit 1
fi
