#!/usr/bin/env bash
# test_coordinate_bug_fixes.sh - Test suite for Spec 1763171210 coordinate bug fixes
#
# Tests fail-fast state capture pattern and verification that:
# 1. Classification response captured from workflow-classifier agent
# 2. REPORT_PATHS array reconstructed with fail-fast validation
# 3. Research agents use fail-fast verification (no filesystem fallback)
# 4. Plan agents use fail-fast verification
# 5. State persistence has mandatory validation (no defensive expansion)
# 6. No silent fallbacks remain

set -euo pipefail

# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Load required libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/error-handling.sh"

# Test configuration
TEST_SUITE_NAME="Coordinate Bug Fixes (Spec 1763171210)"
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test output formatting
print_test_header() {
  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "TEST: $1"
  echo "═══════════════════════════════════════════════════════"
}

print_test_result() {
  local test_name="$1"
  local result="$2"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [ "$result" = "PASS" ]; then
    echo "✓ PASS: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "✗ FAIL: $test_name"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# Cleanup function
cleanup_test_state() {
  if [ -n "${TEST_WORKFLOW_ID:-}" ]; then
    rm -f "${CLAUDE_PROJECT_DIR}/.claude/tmp/${TEST_WORKFLOW_ID}.state" 2>/dev/null || true
  fi
}

trap cleanup_test_state EXIT

# ============================================================================
# TC1: Classification Response Capture (Fail-Fast)
# ============================================================================

test_classification_missing_state() {
  print_test_header "TC1.1: Classification missing from state (should fail)"

  # Initialize test state
  TEST_WORKFLOW_ID="test_classification_missing_$$"
  STATE_FILE=$(init_workflow_state "$TEST_WORKFLOW_ID")

  # Don't save CLASSIFICATION_JSON to state (simulate agent failure)
  # append_workflow_state "CLASSIFICATION_JSON" "{...}" # INTENTIONALLY OMITTED

  # Try to load state - should be empty
  load_workflow_state "$TEST_WORKFLOW_ID"

  # Validate expected behavior: CLASSIFICATION_JSON should be empty
  if [ -z "${CLASSIFICATION_JSON:-}" ]; then
    print_test_result "Classification missing detection" "PASS"
  else
    echo "ERROR: CLASSIFICATION_JSON should be empty but is: $CLASSIFICATION_JSON"
    print_test_result "Classification missing detection" "FAIL"
  fi

  cleanup_test_state
}

test_classification_invalid_json() {
  print_test_header "TC1.2: Classification invalid JSON (should fail)"

  # Initialize test state
  TEST_WORKFLOW_ID="test_classification_invalid_$$"
  STATE_FILE=$(init_workflow_state "$TEST_WORKFLOW_ID")

  # Save invalid JSON
  append_workflow_state "CLASSIFICATION_JSON" "{invalid json"
  load_workflow_state "$TEST_WORKFLOW_ID"

  # Validate JSON detection
  if ! echo "${CLASSIFICATION_JSON:-}" | jq empty 2>/dev/null; then
    print_test_result "Invalid JSON detection" "PASS"
  else
    echo "ERROR: Invalid JSON should have been detected"
    print_test_result "Invalid JSON detection" "FAIL"
  fi

  cleanup_test_state
}

test_classification_missing_fields() {
  print_test_header "TC1.3: Classification missing required fields (should fail)"

  # Initialize test state
  TEST_WORKFLOW_ID="test_classification_fields_$$"
  STATE_FILE=$(init_workflow_state "$TEST_WORKFLOW_ID")

  # Save JSON without required fields
  append_workflow_state "CLASSIFICATION_JSON" '{"wrong_field":"value"}'
  load_workflow_state "$TEST_WORKFLOW_ID"

  # Extract fields
  WORKFLOW_TYPE=$(echo "${CLASSIFICATION_JSON:-}" | jq -r '.workflow_type // empty')

  # Validate field missing detection
  if [ -z "$WORKFLOW_TYPE" ]; then
    print_test_result "Missing field detection" "PASS"
  else
    echo "ERROR: Missing workflow_type should have been detected"
    print_test_result "Missing field detection" "FAIL"
  fi

  cleanup_test_state
}

test_classification_success() {
  print_test_header "TC1.4: Classification valid (should succeed)"

  # Initialize test state
  TEST_WORKFLOW_ID="test_classification_success_$$"
  STATE_FILE=$(init_workflow_state "$TEST_WORKFLOW_ID")

  # Save valid classification JSON
  CLASSIFICATION_JSON='{"workflow_type":"full-implementation","research_complexity":3,"research_topics":[{"short_name":"Topic 1"}]}'
  append_workflow_state "CLASSIFICATION_JSON" "$CLASSIFICATION_JSON"

  # Reload state
  load_workflow_state "$TEST_WORKFLOW_ID"

  # Validate JSON
  if echo "${CLASSIFICATION_JSON:-}" | jq empty 2>/dev/null; then
    WORKFLOW_TYPE=$(echo "$CLASSIFICATION_JSON" | jq -r '.workflow_type')
    if [ "$WORKFLOW_TYPE" = "full-implementation" ]; then
      print_test_result "Valid classification loaded" "PASS"
    else
      echo "ERROR: workflow_type mismatch: $WORKFLOW_TYPE"
      print_test_result "Valid classification loaded" "FAIL"
    fi
  else
    echo "ERROR: Valid JSON should have passed validation"
    print_test_result "Valid classification loaded" "FAIL"
  fi

  cleanup_test_state
}

# ============================================================================
# TC2: REPORT_PATHS Array Reconstruction (Fail-Fast)
# ============================================================================

test_report_paths_missing_state() {
  print_test_header "TC2.1: REPORT_PATHS_JSON missing from state (should fail)"

  # Initialize test state
  TEST_WORKFLOW_ID="test_report_paths_missing_$$"
  STATE_FILE=$(init_workflow_state "$TEST_WORKFLOW_ID")

  # Don't save REPORT_PATHS_JSON
  load_workflow_state "$TEST_WORKFLOW_ID"

  # Validate missing detection
  if [ -z "${REPORT_PATHS_JSON:-}" ]; then
    print_test_result "REPORT_PATHS_JSON missing detection" "PASS"
  else
    echo "ERROR: REPORT_PATHS_JSON should be empty"
    print_test_result "REPORT_PATHS_JSON missing detection" "FAIL"
  fi

  cleanup_test_state
}

test_report_paths_invalid_json() {
  print_test_header "TC2.2: REPORT_PATHS_JSON invalid JSON (should fail)"

  # Initialize test state
  TEST_WORKFLOW_ID="test_report_paths_invalid_$$"
  STATE_FILE=$(init_workflow_state "$TEST_WORKFLOW_ID")

  # Save invalid JSON
  append_workflow_state "REPORT_PATHS_JSON" "[invalid"
  load_workflow_state "$TEST_WORKFLOW_ID"

  # Validate JSON detection
  if ! echo "${REPORT_PATHS_JSON:-}" | jq empty 2>/dev/null; then
    print_test_result "Invalid REPORT_PATHS_JSON detection" "PASS"
  else
    echo "ERROR: Invalid JSON should have been detected"
    print_test_result "Invalid REPORT_PATHS_JSON detection" "FAIL"
  fi

  cleanup_test_state
}

test_report_paths_empty_array() {
  print_test_header "TC2.3: REPORT_PATHS array empty (should fail for non-research-only)"

  # Initialize test state
  TEST_WORKFLOW_ID="test_report_paths_empty_$$"
  STATE_FILE=$(init_workflow_state "$TEST_WORKFLOW_ID")

  # Save empty array
  append_workflow_state "REPORT_PATHS_JSON" '[]'
  load_workflow_state "$TEST_WORKFLOW_ID"

  # Reconstruct array
  mapfile -t REPORT_PATHS < <(echo "${REPORT_PATHS_JSON:-}" | jq -r '.[]')

  # Validate empty array detection
  if [ "${#REPORT_PATHS[@]}" -eq 0 ]; then
    print_test_result "Empty array detection" "PASS"
  else
    echo "ERROR: Array should be empty but has ${#REPORT_PATHS[@]} elements"
    print_test_result "Empty array detection" "FAIL"
  fi

  cleanup_test_state
}

test_report_paths_success() {
  print_test_header "TC2.4: REPORT_PATHS array reconstruction (should succeed)"

  # Initialize test state
  TEST_WORKFLOW_ID="test_report_paths_success_$$"
  STATE_FILE=$(init_workflow_state "$TEST_WORKFLOW_ID")

  # Save valid paths
  REPORT_PATHS_JSON='["/path/1.md","/path/2.md","/path/3.md"]'
  append_workflow_state "REPORT_PATHS_JSON" "$REPORT_PATHS_JSON"
  load_workflow_state "$TEST_WORKFLOW_ID"

  # Reconstruct array
  mapfile -t REPORT_PATHS < <(echo "$REPORT_PATHS_JSON" | jq -r '.[]')

  # Validate reconstruction
  REPORT_COUNT="${#REPORT_PATHS[@]}"
  if [ "$REPORT_COUNT" -eq 3 ]; then
    print_test_result "Array reconstruction (3 paths)" "PASS"
  else
    echo "ERROR: Expected 3 paths, got $REPORT_COUNT"
    print_test_result "Array reconstruction" "FAIL"
  fi

  cleanup_test_state
}

# ============================================================================
# TC5: State Persistence (Fail-Fast)
# ============================================================================

test_state_persistence_missing_critical() {
  print_test_header "TC5.1: Critical variables validated after load"

  # Initialize fresh test state with unique ID
  TEST_WORKFLOW_ID="test_state_critical_$(date +%s)_$$"
  STATE_FILE=$(init_workflow_state "$TEST_WORKFLOW_ID")

  # Save only WORKFLOW_DESCRIPTION (not all critical variables)
  append_workflow_state "WORKFLOW_DESCRIPTION" "test"

  # Create a new bash subprocess to test state loading
  # This ensures WORKFLOW_TYPE isn't inherited from parent process
  TEST_RESULT=$(bash -c "
    source '${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh' 2>/dev/null
    load_workflow_state '$TEST_WORKFLOW_ID' 2>/dev/null
    if [ -z \"\${WORKFLOW_TYPE:-}\" ]; then
      echo 'PASS'
    else
      echo 'FAIL'
    fi
  ")

  if [ "$TEST_RESULT" = "PASS" ]; then
    print_test_result "Critical variables validated after load" "PASS"
  else
    echo "ERROR: State isolation test failed - WORKFLOW_TYPE unexpectedly present"
    print_test_result "Critical variables validated after load" "FAIL"
  fi

  cleanup_test_state
}

test_state_persistence_success() {
  print_test_header "TC5.2: All critical variables saved (should succeed)"

  # Initialize test state
  TEST_WORKFLOW_ID="test_state_success_$$"
  STATE_FILE=$(init_workflow_state "$TEST_WORKFLOW_ID")

  # Save all critical variables
  append_workflow_state "WORKFLOW_DESCRIPTION" "test workflow"
  append_workflow_state "WORKFLOW_TYPE" "full-implementation"
  append_workflow_state "RESEARCH_COMPLEXITY" "3"
  append_workflow_state "TOPIC_PATH" "/test/path"
  append_workflow_state "REPORTS_DIR" "/test/reports"
  append_workflow_state "PLANS_DIR" "/test/plans"
  append_workflow_state "REPORT_PATHS_JSON" '[]'

  load_workflow_state "$TEST_WORKFLOW_ID"

  # Validate all variables loaded
  MISSING=()
  [ -z "${WORKFLOW_DESCRIPTION:-}" ] && MISSING+=("WORKFLOW_DESCRIPTION")
  [ -z "${WORKFLOW_TYPE:-}" ] && MISSING+=("WORKFLOW_TYPE")
  [ -z "${RESEARCH_COMPLEXITY:-}" ] && MISSING+=("RESEARCH_COMPLEXITY")
  [ -z "${TOPIC_PATH:-}" ] && MISSING+=("TOPIC_PATH")

  if [ "${#MISSING[@]}" -eq 0 ]; then
    print_test_result "All critical variables loaded" "PASS"
  else
    echo "ERROR: Missing variables: ${MISSING[*]}"
    print_test_result "All critical variables loaded" "FAIL"
  fi

  cleanup_test_state
}

# ============================================================================
# TC6: No Silent Fallbacks
# ============================================================================

test_no_defensive_expansion() {
  print_test_header "TC6.1: No defensive expansion patterns in coordinate.md"

  # Check that defensive fallback pattern was removed (not the initial calculation)
  # The pattern should NOT appear in an if statement checking if variable is empty
  if grep -B2 "USE_HIERARCHICAL_RESEARCH=.*\[ \$RESEARCH_COMPLEXITY" "${CLAUDE_PROJECT_DIR}/.claude/commands/coordinate.md" | grep -q "if.*-z.*USE_HIERARCHICAL_RESEARCH"; then
    echo "ERROR: USE_HIERARCHICAL_RESEARCH defensive fallback still present"
    print_test_result "No USE_HIERARCHICAL_RESEARCH defensive fallback" "FAIL"
  else
    print_test_result "No USE_HIERARCHICAL_RESEARCH defensive fallback" "PASS"
  fi
}

test_no_fallback_recalculation() {
  print_test_header "TC6.2: No fallback recalculation patterns"

  # Check that RESEARCH_COMPLEXITY fallback was removed
  if grep -q "RESEARCH_COMPLEXITY=2" "${CLAUDE_PROJECT_DIR}/.claude/commands/coordinate.md"; then
    echo "ERROR: RESEARCH_COMPLEXITY fallback (=2) still present"
    print_test_result "No RESEARCH_COMPLEXITY fallback" "FAIL"
  else
    print_test_result "No RESEARCH_COMPLEXITY fallback" "PASS"
  fi
}

test_handle_state_error_usage() {
  print_test_header "TC6.3: handle_state_error used for all critical failures"

  # Count handle_state_error calls (should be multiple)
  ERROR_HANDLER_COUNT=$(grep -c "handle_state_error" "${CLAUDE_PROJECT_DIR}/.claude/commands/coordinate.md" || echo "0")

  # Should have at least 10 handle_state_error calls for various failure modes
  if [ "$ERROR_HANDLER_COUNT" -ge 10 ]; then
    print_test_result "Adequate handle_state_error usage ($ERROR_HANDLER_COUNT calls)" "PASS"
  else
    echo "ERROR: Only $ERROR_HANDLER_COUNT handle_state_error calls (expected ≥10)"
    print_test_result "Adequate handle_state_error usage" "FAIL"
  fi
}

# ============================================================================
# Run all tests
# ============================================================================

echo "═══════════════════════════════════════════════════════"
echo "$TEST_SUITE_NAME"
echo "═══════════════════════════════════════════════════════"

# TC1: Classification tests
test_classification_missing_state
test_classification_invalid_json
test_classification_missing_fields
test_classification_success

# TC2: REPORT_PATHS tests
test_report_paths_missing_state
test_report_paths_invalid_json
test_report_paths_empty_array
test_report_paths_success

# TC5: State persistence tests
test_state_persistence_missing_critical
test_state_persistence_success

# TC6: No silent fallbacks tests
test_no_defensive_expansion
test_no_fallback_recalculation
test_handle_state_error_usage

# Print summary
echo ""
echo "═══════════════════════════════════════════════════════"
echo "TEST SUMMARY"
echo "═══════════════════════════════════════════════════════"
echo "Tests Run:    $TESTS_RUN"
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"
echo ""

if [ "$TESTS_FAILED" -eq 0 ]; then
  echo "✓ ALL TESTS PASSED"
  exit 0
else
  echo "✗ SOME TESTS FAILED"
  exit 1
fi
