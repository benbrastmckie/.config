#!/usr/bin/env bash
# test_implement_work_remaining.sh - Regression test for WORK_REMAINING format
# Tests defensive conversion from JSON array to space-separated string

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

# Test 1: JSON array conversion
test_json_array_conversion() {
  # Simulate JSON array input from agent
  WORK_REMAINING="[Phase 4, Phase 5, Phase 6, Phase 7]"

  # Apply conversion logic (same as Block 1c in /implement)
  if [[ "$WORK_REMAINING" =~ ^[[:space:]]*\[ ]]; then
    WORK_REMAINING_CLEAN="${WORK_REMAINING#[}"
    WORK_REMAINING_CLEAN="${WORK_REMAINING_CLEAN%]}"
    WORK_REMAINING_CLEAN="${WORK_REMAINING_CLEAN//,/}"
    WORK_REMAINING_CLEAN=$(echo "$WORK_REMAINING_CLEAN" | tr -s ' ')
    WORK_REMAINING="$WORK_REMAINING_CLEAN"
  fi

  # Verify conversion
  if [[ "$WORK_REMAINING" == "Phase 4 Phase 5 Phase 6 Phase 7" ]]; then
    # Verify no brackets or commas remain
    if [[ ! "$WORK_REMAINING" =~ [\[\],] ]]; then
      pass "JSON array conversion"
      return 0
    else
      fail "JSON array conversion" "Brackets or commas still present: '$WORK_REMAINING'"
      return 1
    fi
  else
    fail "JSON array conversion" "Expected 'Phase 4 Phase 5 Phase 6 Phase 7', got '$WORK_REMAINING'"
    return 1
  fi
}

# Test 2: Scalar passthrough (no conversion)
test_scalar_passthrough() {
  # Simulate space-separated input (correct format)
  WORK_REMAINING="Phase_4 Phase_5 Phase_6"

  # Apply conversion logic (should be no-op)
  if [[ "$WORK_REMAINING" =~ ^[[:space:]]*\[ ]]; then
    WORK_REMAINING_CLEAN="${WORK_REMAINING#[}"
    WORK_REMAINING_CLEAN="${WORK_REMAINING_CLEAN%]}"
    WORK_REMAINING_CLEAN="${WORK_REMAINING_CLEAN//,/}"
    WORK_REMAINING="$WORK_REMAINING_CLEAN"
  fi

  # Verify unchanged
  if [[ "$WORK_REMAINING" == "Phase_4 Phase_5 Phase_6" ]]; then
    pass "Scalar passthrough"
    return 0
  else
    fail "Scalar passthrough" "Expected 'Phase_4 Phase_5 Phase_6', got '$WORK_REMAINING'"
    return 1
  fi
}

# Test 3: Empty string handling
test_empty_string() {
  WORK_REMAINING=""

  # Apply conversion logic
  if [[ "$WORK_REMAINING" =~ ^[[:space:]]*\[ ]]; then
    WORK_REMAINING_CLEAN="${WORK_REMAINING#[}"
    WORK_REMAINING_CLEAN="${WORK_REMAINING_CLEAN%]}"
    WORK_REMAINING_CLEAN="${WORK_REMAINING_CLEAN//,/}"
    WORK_REMAINING="$WORK_REMAINING_CLEAN"
  fi

  # Verify empty string persists
  if [[ -z "$WORK_REMAINING" ]]; then
    pass "Empty string handling"
    return 0
  else
    fail "Empty string handling" "Expected empty string, got '$WORK_REMAINING'"
    return 1
  fi
}

# Test 4: Zero value handling
test_zero_value() {
  WORK_REMAINING="0"

  # Apply conversion logic
  if [[ "$WORK_REMAINING" =~ ^[[:space:]]*\[ ]]; then
    WORK_REMAINING_CLEAN="${WORK_REMAINING#[}"
    WORK_REMAINING_CLEAN="${WORK_REMAINING_CLEAN%]}"
    WORK_REMAINING_CLEAN="${WORK_REMAINING_CLEAN//,/}"
    WORK_REMAINING="$WORK_REMAINING_CLEAN"
  fi

  # Verify zero value persists
  if [[ "$WORK_REMAINING" == "0" ]]; then
    pass "Zero value handling"
    return 0
  else
    fail "Zero value handling" "Expected '0', got '$WORK_REMAINING'"
    return 1
  fi
}

# Test 5: State persistence validation
test_state_persistence() {
  # Source state-persistence library
  if ! source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null; then
    fail "State persistence validation" "Failed to source state-persistence.sh"
    return 1
  fi

  # Initialize state file
  STATE_FILE=$(init_workflow_state "test_$$")
  trap "rm -f '$STATE_FILE'" EXIT

  # Test scalar value persistence
  if ! append_workflow_state "WORK_REMAINING" "Phase_4 Phase_5" 2>/dev/null; then
    fail "State persistence validation" "Failed to append scalar value"
    rm -f "$STATE_FILE"
    return 1
  fi

  # Verify state file contains valid export
  if grep -q '^export WORK_REMAINING="Phase_4 Phase_5"$' "$STATE_FILE"; then
    # Test JSON array rejection
    if append_workflow_state "WORK_REMAINING_JSON" "[Phase 4, Phase 5]" 2>/dev/null; then
      # Should NOT succeed
      fail "State persistence validation" "JSON array was NOT rejected (expected failure)"
      rm -f "$STATE_FILE"
      return 1
    else
      # JSON array correctly rejected
      pass "State persistence validation"
      rm -f "$STATE_FILE"
      return 0
    fi
  else
    fail "State persistence validation" "State file export format incorrect"
    rm -f "$STATE_FILE"
    return 1
  fi
}

# Test 6: Multiple spaces normalization
test_space_normalization() {
  # Simulate JSON array with extra spaces
  WORK_REMAINING="[Phase 4,  Phase 5,   Phase 6]"

  # Apply conversion logic
  if [[ "$WORK_REMAINING" =~ ^[[:space:]]*\[ ]]; then
    WORK_REMAINING_CLEAN="${WORK_REMAINING#[}"
    WORK_REMAINING_CLEAN="${WORK_REMAINING_CLEAN%]}"
    WORK_REMAINING_CLEAN="${WORK_REMAINING_CLEAN//,/}"
    WORK_REMAINING_CLEAN=$(echo "$WORK_REMAINING_CLEAN" | tr -s ' ')
    WORK_REMAINING="$WORK_REMAINING_CLEAN"
  fi

  # Verify space normalization (multiple spaces -> single space)
  if [[ "$WORK_REMAINING" == "Phase 4 Phase 5 Phase 6" ]]; then
    pass "Space normalization"
    return 0
  else
    fail "Space normalization" "Expected 'Phase 4 Phase 5 Phase 6', got '$WORK_REMAINING'"
    return 1
  fi
}

# Run all tests
echo "========================================"
echo "WORK_REMAINING Format Regression Tests"
echo "========================================"
echo ""

test_json_array_conversion
test_scalar_passthrough
test_empty_string
test_zero_value
test_state_persistence
test_space_normalization

echo ""
echo "========================================"
echo "Test Results"
echo "========================================"
echo "Tests Run:    $TESTS_RUN"
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"
echo "========================================"

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo "✓ ALL TESTS PASSED"
  exit 0
else
  echo "✗ SOME TESTS FAILED"
  exit 1
fi
