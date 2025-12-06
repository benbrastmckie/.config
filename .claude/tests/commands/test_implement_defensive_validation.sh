#!/usr/bin/env bash
# test_implement_defensive_validation.sh - Test defensive validation of continuation signals
# Tests the defensive override logic that enforces work_remaining / requires_continuation invariant

set -uo pipefail
# Note: Not using set -e because test functions return non-zero on failure
# but we want to continue running all tests

# Source test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect CLAUDE_PROJECT_DIR (go up to git root)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Initialize test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
pass() {
  echo "✓ $1"
  ((TESTS_PASSED++))
  ((TESTS_RUN++))
}

fail() {
  echo "✗ $1"
  echo "  $2"
  ((TESTS_FAILED++))
  ((TESTS_RUN++))
}

# Helper function: Check if work_remaining is truly empty
# This replicates the function from Block 1c in /implement
is_work_remaining_empty() {
  local work_remaining="${1:-}"

  # Empty string
  [ -z "$work_remaining" ] && return 0

  # Literal "0"
  [ "$work_remaining" = "0" ] && return 0

  # Empty JSON array "[]"
  [ "$work_remaining" = "[]" ] && return 0

  # Contains only whitespace
  [[ "$work_remaining" =~ ^[[:space:]]*$ ]] && return 0

  # Work remains
  return 1
}

# Test 1: is_work_remaining_empty - empty string
test_is_work_remaining_empty_string() {
  if is_work_remaining_empty ""; then
    pass "is_work_remaining_empty - empty string"
    return 0
  else
    fail "is_work_remaining_empty - empty string" "Expected true (0), got false (1)"
    return 1
  fi
}

# Test 2: is_work_remaining_empty - literal "0"
test_is_work_remaining_empty_zero() {
  if is_work_remaining_empty "0"; then
    pass "is_work_remaining_empty - literal 0"
    return 0
  else
    fail "is_work_remaining_empty - literal 0" "Expected true (0), got false (1)"
    return 1
  fi
}

# Test 3: is_work_remaining_empty - empty array "[]"
test_is_work_remaining_empty_array() {
  if is_work_remaining_empty "[]"; then
    pass "is_work_remaining_empty - empty array []"
    return 0
  else
    fail "is_work_remaining_empty - empty array []" "Expected true (0), got false (1)"
    return 1
  fi
}

# Test 4: is_work_remaining_empty - whitespace only
test_is_work_remaining_empty_whitespace() {
  if is_work_remaining_empty "   "; then
    pass "is_work_remaining_empty - whitespace only"
    return 0
  else
    fail "is_work_remaining_empty - whitespace only" "Expected true (0), got false (1)"
    return 1
  fi
}

# Test 5: is_work_remaining_empty - work remains
test_is_work_remaining_not_empty() {
  if ! is_work_remaining_empty "Phase_4 Phase_5 Phase_6"; then
    pass "is_work_remaining_empty - work remains"
    return 0
  else
    fail "is_work_remaining_empty - work remains" "Expected false (1), got true (0)"
    return 1
  fi
}

# Test 6: Defensive override - agent bug (work remains but requires_continuation=false)
test_defensive_override_agent_bug() {
  local WORK_REMAINING="Phase_4 Phase_5 Phase_6"
  local REQUIRES_CONTINUATION="false"
  local override_triggered=0

  # Apply defensive validation logic (from Block 1c)
  if ! is_work_remaining_empty "$WORK_REMAINING"; then
    # Work remains - continuation is MANDATORY
    if [ "$REQUIRES_CONTINUATION" != "true" ]; then
      override_triggered=1
      REQUIRES_CONTINUATION="true"
    fi
  fi

  # Verify override occurred and REQUIRES_CONTINUATION is now "true"
  if [ $override_triggered -eq 1 ] && [ "$REQUIRES_CONTINUATION" = "true" ]; then
    pass "Defensive override - agent bug detected and overridden"
    return 0
  else
    fail "Defensive override - agent bug" "Expected override (override_triggered=1, REQUIRES_CONTINUATION=true), got override_triggered=$override_triggered, REQUIRES_CONTINUATION=$REQUIRES_CONTINUATION"
    return 1
  fi
}

# Test 7: No override - agent correct (work remains and requires_continuation=true)
test_no_override_agent_correct() {
  local WORK_REMAINING="Phase_4 Phase_5"
  local REQUIRES_CONTINUATION="true"
  local override_triggered=0

  # Apply defensive validation logic
  if ! is_work_remaining_empty "$WORK_REMAINING"; then
    # Work remains - continuation is MANDATORY
    if [ "$REQUIRES_CONTINUATION" != "true" ]; then
      override_triggered=1
      REQUIRES_CONTINUATION="true"
    fi
  fi

  # Verify no override occurred and REQUIRES_CONTINUATION remains "true"
  if [ $override_triggered -eq 0 ] && [ "$REQUIRES_CONTINUATION" = "true" ]; then
    pass "No override - agent correct (work remains, requires_continuation=true)"
    return 0
  else
    fail "No override - agent correct" "Expected no override (override_triggered=0, REQUIRES_CONTINUATION=true), got override_triggered=$override_triggered, REQUIRES_CONTINUATION=$REQUIRES_CONTINUATION"
    return 1
  fi
}

# Test 8: No override - work complete (no work remains, requires_continuation=false)
test_no_override_work_complete() {
  local WORK_REMAINING=""
  local REQUIRES_CONTINUATION="false"
  local override_triggered=0

  # Apply defensive validation logic
  if ! is_work_remaining_empty "$WORK_REMAINING"; then
    # Work remains - continuation is MANDATORY
    if [ "$REQUIRES_CONTINUATION" != "true" ]; then
      override_triggered=1
      REQUIRES_CONTINUATION="true"
    fi
  fi

  # Verify no override occurred and REQUIRES_CONTINUATION remains "false"
  if [ $override_triggered -eq 0 ] && [ "$REQUIRES_CONTINUATION" = "false" ]; then
    pass "No override - work complete (no work remains, requires_continuation=false)"
    return 0
  else
    fail "No override - work complete" "Expected no override (override_triggered=0, REQUIRES_CONTINUATION=false), got override_triggered=$override_triggered, REQUIRES_CONTINUATION=$REQUIRES_CONTINUATION"
    return 1
  fi
}

# Test 9: Edge case - "0" as work_remaining with requires_continuation=false
test_edge_case_zero_work_remaining() {
  local WORK_REMAINING="0"
  local REQUIRES_CONTINUATION="false"
  local override_triggered=0

  # Apply defensive validation logic
  if ! is_work_remaining_empty "$WORK_REMAINING"; then
    # Work remains - continuation is MANDATORY
    if [ "$REQUIRES_CONTINUATION" != "true" ]; then
      override_triggered=1
      REQUIRES_CONTINUATION="true"
    fi
  fi

  # Verify no override occurred (0 is treated as empty)
  if [ $override_triggered -eq 0 ] && [ "$REQUIRES_CONTINUATION" = "false" ]; then
    pass "Edge case - 0 as work_remaining treated as empty"
    return 0
  else
    fail "Edge case - 0 as work_remaining" "Expected no override (0 should be treated as empty), got override_triggered=$override_triggered, REQUIRES_CONTINUATION=$REQUIRES_CONTINUATION"
    return 1
  fi
}

# Test 10: Edge case - "[]" as work_remaining with requires_continuation=false
test_edge_case_empty_array_work_remaining() {
  local WORK_REMAINING="[]"
  local REQUIRES_CONTINUATION="false"
  local override_triggered=0

  # Apply defensive validation logic
  if ! is_work_remaining_empty "$WORK_REMAINING"; then
    # Work remains - continuation is MANDATORY
    if [ "$REQUIRES_CONTINUATION" != "true" ]; then
      override_triggered=1
      REQUIRES_CONTINUATION="true"
    fi
  fi

  # Verify no override occurred ([] is treated as empty)
  if [ $override_triggered -eq 0 ] && [ "$REQUIRES_CONTINUATION" = "false" ]; then
    pass "Edge case - [] as work_remaining treated as empty"
    return 0
  else
    fail "Edge case - [] as work_remaining" "Expected no override ([] should be treated as empty), got override_triggered=$override_triggered, REQUIRES_CONTINUATION=$REQUIRES_CONTINUATION"
    return 1
  fi
}

# Run all tests
echo ""
echo "Running defensive validation tests..."
echo "===================================="
echo ""

test_is_work_remaining_empty_string
test_is_work_remaining_empty_zero
test_is_work_remaining_empty_array
test_is_work_remaining_empty_whitespace
test_is_work_remaining_not_empty
test_defensive_override_agent_bug
test_no_override_agent_correct
test_no_override_work_complete
test_edge_case_zero_work_remaining
test_edge_case_empty_array_work_remaining

# Print summary
echo ""
echo "===================================="
echo "Test Summary"
echo "===================================="
echo "Tests run: $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo ""

# Exit with appropriate code
if [ $TESTS_FAILED -eq 0 ]; then
  echo "All tests passed! ✓"
  exit 0
else
  echo "Some tests failed! ✗"
  exit 1
fi
