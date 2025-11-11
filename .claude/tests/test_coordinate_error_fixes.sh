#!/usr/bin/env bash
# Test suite for coordinate error fixes (Spec 652)
# Tests the three critical error scenarios fixed in this implementation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

TESTS_PASSED=0
TESTS_FAILED=0

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "${PROJECT_ROOT}/.claude/lib/state-persistence.sh"
source "${PROJECT_ROOT}/.claude/lib/verification-helpers.sh"

print_test_header() {
  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "Test: $1"
  echo "═══════════════════════════════════════════════════════"
}

pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  TESTS_FAILED=$((TESTS_FAILED + 1))
}

# ==============================================================================
# Test 1: Empty Report Paths (JSON Creation)
# ==============================================================================
test_empty_report_paths_creation() {
  print_test_header "Empty Report Paths (JSON Creation)"

  # Test empty array case
  SUCCESSFUL_REPORT_PATHS=()

  # Execute JSON creation code (from coordinate.md line 605-609)
  if [ ${#SUCCESSFUL_REPORT_PATHS[@]} -eq 0 ]; then
    REPORT_PATHS_JSON="[]"
  else
    REPORT_PATHS_JSON="$(printf '%s\n' "${SUCCESSFUL_REPORT_PATHS[@]}" | jq -R . | jq -s .)"
  fi

  # Verify result
  if [ "$REPORT_PATHS_JSON" = "[]" ]; then
    pass "Empty array creates valid JSON '[]'"
  else
    fail "Empty array did not create '[]', got: $REPORT_PATHS_JSON"
  fi

  # Test with actual paths
  SUCCESSFUL_REPORT_PATHS=("/path/to/report1.md" "/path/to/report2.md")
  REPORT_PATHS_JSON="$(printf '%s\n' "${SUCCESSFUL_REPORT_PATHS[@]}" | jq -R . | jq -s .)"

  if echo "$REPORT_PATHS_JSON" | jq empty 2>/dev/null; then
    pass "Valid paths create parseable JSON"
  else
    fail "Valid paths did not create parseable JSON"
  fi
}

# ==============================================================================
# Test 2: Empty Report Paths (JSON Loading)
# ==============================================================================
test_empty_report_paths_loading() {
  print_test_header "Empty Report Paths (JSON Loading)"

  # Test with empty JSON
  REPORT_PATHS_JSON="[]"
  if [ -n "${REPORT_PATHS_JSON:-}" ]; then
    if echo "$REPORT_PATHS_JSON" | jq empty 2>/dev/null; then
      mapfile -t REPORT_PATHS < <(echo "$REPORT_PATHS_JSON" | jq -r '.[]')
    else
      REPORT_PATHS=()
    fi
  else
    REPORT_PATHS=()
  fi

  if [ ${#REPORT_PATHS[@]} -eq 0 ]; then
    pass "Empty JSON array loads as empty bash array"
  else
    fail "Empty JSON array did not load correctly"
  fi
}

# ==============================================================================
# Test 3: Malformed JSON Recovery
# ==============================================================================
test_malformed_json_recovery() {
  print_test_header "Malformed JSON Recovery"

  # Test malformed JSON
  REPORT_PATHS_JSON="invalid json {not valid"

  if [ -n "${REPORT_PATHS_JSON:-}" ]; then
    if echo "$REPORT_PATHS_JSON" | jq empty 2>/dev/null; then
      mapfile -t REPORT_PATHS < <(echo "$REPORT_PATHS_JSON" | jq -r '.[]')
    else
      REPORT_PATHS=()
    fi
  else
    REPORT_PATHS=()
  fi

  if [ ${#REPORT_PATHS[@]} -eq 0 ]; then
    pass "Malformed JSON falls back to empty array"
  else
    fail "Malformed JSON did not fall back correctly"
  fi

  # Test unset JSON
  unset REPORT_PATHS_JSON
  if [ -n "${REPORT_PATHS_JSON:-}" ]; then
    if echo "$REPORT_PATHS_JSON" | jq empty 2>/dev/null; then
      mapfile -t REPORT_PATHS < <(echo "$REPORT_PATHS_JSON" | jq -r '.[]')
    else
      REPORT_PATHS=()
    fi
  else
    REPORT_PATHS=()
  fi

  if [ ${#REPORT_PATHS[@]} -eq 0 ]; then
    pass "Unset REPORT_PATHS_JSON falls back to empty array"
  else
    fail "Unset REPORT_PATHS_JSON did not fall back correctly"
  fi
}

# ==============================================================================
# Test 4: Missing State File
# ==============================================================================
test_missing_state_file() {
  print_test_header "Missing State File Detection"

  # Test with nonexistent state file
  NONEXISTENT_FILE="/tmp/test_nonexistent_state_file_$$.state"
  VARS_TO_CHECK=("TEST_VAR1" "TEST_VAR2")

  # This should fail gracefully with error message
  if verify_state_variables "$NONEXISTENT_FILE" "${VARS_TO_CHECK[@]}" 2>/dev/null; then
    fail "verify_state_variables should have failed for missing file"
  else
    pass "verify_state_variables correctly detects missing state file"
  fi
}

# ==============================================================================
# Test 5: State Transitions
# ==============================================================================
test_state_transitions() {
  print_test_header "State Transitions"

  # Source state machine library
  source "${PROJECT_ROOT}/.claude/lib/workflow-state-machine.sh"

  # Initialize state machine
  sm_init "Test workflow" "coordinate"

  if [ "$CURRENT_STATE" = "initialize" ]; then
    pass "State machine initializes to 'initialize' state"
  else
    fail "State machine did not initialize correctly, got: $CURRENT_STATE"
  fi

  # Test research transition
  sm_transition "$STATE_RESEARCH"
  if [ "$CURRENT_STATE" = "$STATE_RESEARCH" ]; then
    pass "Transition to research state works"
  else
    fail "Research transition failed, current state: $CURRENT_STATE"
  fi

  # Test plan transition
  sm_transition "$STATE_PLAN"
  if [ "$CURRENT_STATE" = "$STATE_PLAN" ]; then
    pass "Transition to plan state works"
  else
    fail "Plan transition failed, current state: $CURRENT_STATE"
  fi

  # Test implement transition
  sm_transition "$STATE_IMPLEMENT"
  if [ "$CURRENT_STATE" = "$STATE_IMPLEMENT" ]; then
    pass "Transition to implement state works"
  else
    fail "Implement transition failed, current state: $CURRENT_STATE"
  fi
}

# ==============================================================================
# Test 6: State File Existence Check
# ==============================================================================
test_state_file_with_content() {
  print_test_header "State File with Content"

  # Create temporary state file
  TEMP_STATE_FILE="/tmp/test_state_file_$$.state"
  cat > "$TEMP_STATE_FILE" <<EOF
export TEST_VAR1="value1"
export TEST_VAR2="value2"
export TEST_VAR3="value3"
EOF

  VARS_TO_CHECK=("TEST_VAR1" "TEST_VAR2" "TEST_VAR3")

  # This should succeed
  if verify_state_variables "$TEMP_STATE_FILE" "${VARS_TO_CHECK[@]}" >/dev/null 2>&1; then
    pass "verify_state_variables works with valid state file"
  else
    fail "verify_state_variables failed with valid state file"
  fi

  # Test missing variable
  VARS_TO_CHECK=("TEST_VAR1" "MISSING_VAR")
  if verify_state_variables "$TEMP_STATE_FILE" "${VARS_TO_CHECK[@]}" >/dev/null 2>&1; then
    fail "verify_state_variables should have failed for missing variable"
  else
    pass "verify_state_variables correctly detects missing variable"
  fi

  # Cleanup
  rm -f "$TEMP_STATE_FILE"
}

# ==============================================================================
# Run All Tests
# ==============================================================================
echo "Running Coordinate Error Fixes Test Suite"
echo "=========================================="

test_empty_report_paths_creation
test_empty_report_paths_loading
test_malformed_json_recovery
test_missing_state_file
test_state_transitions
test_state_file_with_content

# ==============================================================================
# Summary
# ==============================================================================
echo ""
echo "═══════════════════════════════════════════════════════"
echo "Test Summary"
echo "═══════════════════════════════════════════════════════"
echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
echo -e "${RED}Failed:${NC} $TESTS_FAILED"
echo "Total: $((TESTS_PASSED + TESTS_FAILED))"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}✓ All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  exit 1
fi
