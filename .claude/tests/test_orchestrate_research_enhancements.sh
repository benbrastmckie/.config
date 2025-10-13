#!/usr/bin/env bash
#
# Test Suite: Orchestrate Research Phase Enhancements
#
# Tests absolute path specification, path validation, verification, and retry logic
# for /orchestrate research phase improvements (Plan 046).
#
# Test Categories:
# - Absolute Path Tests (CRITICAL - Report 004)
# - Happy Path Tests
# - Error Recovery Tests
# - Error Classification Tests
# - State Management Tests
# - Integration Tests
#
# Usage:
#   ./test_orchestrate_research_enhancements.sh [test_name]
#   ./test_orchestrate_research_enhancements.sh          # Run all tests
#   ./test_orchestrate_research_enhancements.sh test_absolute_path_specification
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ORCHESTRATE_DOC="${PROJECT_ROOT}/.claude/commands/orchestrate.md"

# Mock directories for testing (not needed for documentation tests)
TEST_TMP_DIR="/tmp/test_orchestrate_$$"

# Helper functions
pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  ((TESTS_PASSED++))
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  echo -e "  Reason: $2"
  ((TESTS_FAILED++))
}

info() {
  echo -e "${YELLOW}ℹ${NC} $1"
}

run_test() {
  local test_name="$1"
  ((TESTS_RUN++))
  echo ""
  echo -e "${YELLOW}ℹ${NC} Running: $test_name"
  "$test_name" || true  # Test function handles pass/fail internally
}

# ============================================================================
# Absolute Path Tests (CRITICAL - Report 004)
# ============================================================================

test_absolute_path_specification() {
  # Verify orchestrate.md documents absolute path requirement
  if grep -q "CRITICAL.*ABSOLUTE" "$ORCHESTRATE_DOC" && \
     grep -q "Step 2: Determine Absolute Report Paths" "$ORCHESTRATE_DOC"; then
    pass "Absolute path specification documented"
  else
    fail "Absolute path specification" "Step 2 not found or not marked CRITICAL"
  fi
}

test_path_determination_logic() {
  # Verify path determination logic is documented
  if grep -q "PROJECT_ROOT=" "$ORCHESTRATE_DOC" && \
     grep -q "SPECS_DIR=" "$ORCHESTRATE_DOC" && \
     grep -q "REPORT_PATH=" "$ORCHESTRATE_DOC"; then
    pass "Path determination logic documented"
  else
    fail "Path determination logic" "Required variables not documented"
  fi
}

test_absolute_path_placeholder() {
  # Verify ABSOLUTE_REPORT_PATH placeholder in prompt template
  if grep -q "\[ABSOLUTE_REPORT_PATH\]" "$ORCHESTRATE_DOC"; then
    pass "ABSOLUTE_REPORT_PATH placeholder in prompt template"
  else
    fail "ABSOLUTE_REPORT_PATH placeholder" "Not found in prompt template"
  fi
}

test_expected_location() {
  # Verify documentation of expected absolute path format
  if grep -q "/home/.*/.claude/specs/reports/" "$ORCHESTRATE_DOC"; then
    pass "Expected absolute path format documented"
  else
    fail "Expected path format" "Absolute path example not found"
  fi
}

# ============================================================================
# Happy Path Tests
# ============================================================================

test_progress_markers_documented() {
  # Verify progress marker standards documented
  if grep -q "PROGRESS:" "$ORCHESTRATE_DOC" && \
     grep -q "REPORT_CREATED:" "$ORCHESTRATE_DOC" && \
     grep -q "\[Agent N/M: topic\]" "$ORCHESTRATE_DOC"; then
    pass "Progress marker standards documented"
  else
    fail "Progress markers" "Standards not fully documented"
  fi
}

test_report_verification_step() {
  # Verify Step 4.5 exists for report verification
  if grep -q "#### Step 4.5: Verify Report Files" "$ORCHESTRATE_DOC"; then
    pass "Step 4.5 (Verify Report Files) exists"
  else
    fail "Step 4.5" "Report verification step not found"
  fi
}

test_planning_phase_integration() {
  # Verify planning phase still receives report paths
  if grep -q "research_reports.*array" "$ORCHESTRATE_DOC" && \
     grep -q "Planning Phase" "$ORCHESTRATE_DOC"; then
    pass "Planning phase integration documented"
  else
    fail "Planning phase integration" "Report path passing not documented"
  fi
}

# ============================================================================
# Error Recovery Tests
# ============================================================================

test_retry_step_exists() {
  # Verify Step 4.6 exists for retry logic
  if grep -q "#### Step 4.6: Retry Failed Reports" "$ORCHESTRATE_DOC"; then
    pass "Step 4.6 (Retry Failed Reports) exists"
  else
    fail "Step 4.6" "Retry step not found"
  fi
}

test_max_retry_enforcement() {
  # Verify max retry limit documented
  if grep -q "max.*1.*retry" "$ORCHESTRATE_DOC" || \
     grep -q "retry_count >= 1" "$ORCHESTRATE_DOC"; then
    pass "Max retry limit (1) enforced"
  else
    fail "Max retry enforcement" "Retry limit not documented"
  fi
}

test_path_mismatch_recovery() {
  # Verify path mismatch recovery logic exists
  if grep -q "path_mismatch" "$ORCHESTRATE_DOC" && \
     grep -q "mv.*actual_path.*expected_path" "$ORCHESTRATE_DOC"; then
    pass "Path mismatch recovery (file move) documented"
  else
    fail "Path mismatch recovery" "File move logic not documented"
  fi
}

# ============================================================================
# Error Classification Tests
# ============================================================================

test_file_not_found_classification() {
  # Verify file_not_found error classification
  if grep -q "file_not_found" "$ORCHESTRATE_DOC"; then
    pass "file_not_found error classification exists"
  else
    fail "file_not_found classification" "Not documented"
  fi
}

test_path_mismatch_classification() {
  # Verify path_mismatch error classification (CRITICAL - Report 004)
  if grep -q "path_mismatch" "$ORCHESTRATE_DOC"; then
    pass "path_mismatch error classification exists (CRITICAL)"
  else
    fail "path_mismatch classification" "Not documented (CRITICAL for Report 004)"
  fi
}

test_invalid_metadata_classification() {
  # Verify invalid_metadata error classification
  if grep -q "invalid_metadata" "$ORCHESTRATE_DOC"; then
    pass "invalid_metadata error classification exists"
  else
    fail "invalid_metadata classification" "Not documented"
  fi
}

test_permission_denied_classification() {
  # Verify permission_denied error classification
  if grep -q "permission_denied" "$ORCHESTRATE_DOC"; then
    pass "permission_denied error classification exists"
  else
    fail "permission_denied classification" "Not documented"
  fi
}

# ============================================================================
# State Management Tests
# ============================================================================

test_agent_to_report_mapping() {
  # Verify agent-to-report mapping structure documented
  if grep -q "agent_index" "$ORCHESTRATE_DOC" && \
     grep -q "expected_path" "$ORCHESTRATE_DOC" && \
     grep -q "actual_path" "$ORCHESTRATE_DOC"; then
    pass "Agent-to-report mapping structure documented"
  else
    fail "Agent-to-report mapping" "Structure not fully documented"
  fi
}

test_workflow_state_structure() {
  # Verify workflow_state.research_reports structure
  if grep -q "workflow_state.research_reports" "$ORCHESTRATE_DOC"; then
    pass "workflow_state.research_reports structure documented"
  else
    fail "workflow_state structure" "research_reports not documented"
  fi
}

test_verification_summary_tracking() {
  # Verify verification summary structure
  if grep -q "verification_summary" "$ORCHESTRATE_DOC" && \
     grep -q "verified_success" "$ORCHESTRATE_DOC"; then
    pass "Verification summary tracking documented"
  else
    fail "Verification summary" "Structure not documented"
  fi
}

# ============================================================================
# Integration Tests
# ============================================================================

test_backward_compatibility() {
  # Verify no breaking changes to existing workflow structure
  # Planning phase should still work with report paths array
  if grep -q "report_paths.*array" "$ORCHESTRATE_DOC" || \
     grep -q "research_reports.*array" "$ORCHESTRATE_DOC"; then
    pass "Backward compatibility maintained (report paths array)"
  else
    fail "Backward compatibility" "Report paths array format not maintained"
  fi
}

test_error_utils_integration() {
  # Verify error-utils.sh integration documented
  if grep -q "error-utils.sh" "$ORCHESTRATE_DOC"; then
    pass "error-utils.sh integration documented"
  else
    fail "error-utils integration" "error-utils.sh not referenced"
  fi
}

test_checkpoint_integration() {
  # Verify checkpoint integration for state preservation
  if grep -q "checkpoint" "$ORCHESTRATE_DOC" && \
     grep -q "workflow_state" "$ORCHESTRATE_DOC"; then
    pass "Checkpoint integration documented"
  else
    fail "Checkpoint integration" "Not documented"
  fi
}

# ============================================================================
# Troubleshooting Tests
# ============================================================================

test_troubleshooting_section_exists() {
  # Verify troubleshooting section added
  if grep -q "Troubleshooting.*Research Phase" "$ORCHESTRATE_DOC"; then
    pass "Troubleshooting section exists"
  else
    fail "Troubleshooting section" "Not found"
  fi
}

test_path_inconsistency_troubleshooting() {
  # Verify Issue 1 (path inconsistency) documented
  if grep -q "Issue 1.*Path Inconsistency" "$ORCHESTRATE_DOC" || \
     grep -q "Reports Created in Wrong Location" "$ORCHESTRATE_DOC"; then
    pass "Path inconsistency troubleshooting documented"
  else
    fail "Path inconsistency troubleshooting" "Issue 1 not documented"
  fi
}

# ============================================================================
# Documentation Quality Tests
# ============================================================================

test_step_numbering_consistency() {
  # Verify all steps properly numbered (1, 1.5, 2, 2.5, 3, 3a, 4, 4.5, 4.6, 5, 6)
  local steps_found=0
  grep -o "#### Step [0-9]" "$ORCHESTRATE_DOC" | wc -l > /tmp/steps_count_$$
  steps_found=$(cat /tmp/steps_count_$$)
  rm /tmp/steps_count_$$

  if [ "$steps_found" -ge 8 ]; then
    pass "Step numbering consistent ($steps_found steps found)"
  else
    fail "Step numbering" "Expected at least 8 steps, found $steps_found"
  fi
}

test_critical_markers_present() {
  # Verify CRITICAL markers for Report 004 findings
  local critical_count
  critical_count=$(grep -c "CRITICAL" "$ORCHESTRATE_DOC" || echo "0")

  if [ "$critical_count" -ge 5 ]; then
    pass "CRITICAL markers present ($critical_count occurrences)"
  else
    fail "CRITICAL markers" "Expected at least 5, found $critical_count"
  fi
}

# ============================================================================
# Main Test Runner
# ============================================================================

main() {
  echo "========================================="
  echo "Orchestrate Research Enhancements Tests"
  echo "========================================="
  echo ""
  info "Testing documentation: $ORCHESTRATE_DOC"

  if [ ! -f "$ORCHESTRATE_DOC" ]; then
    echo -e "${RED}ERROR${NC}: orchestrate.md not found at $ORCHESTRATE_DOC"
    exit 1
  fi

  # If specific test provided, run only that test
  if [ $# -gt 0 ]; then
    run_test "$1"
  else
    # Run all test categories
    echo ""
    info "=== Absolute Path Tests (CRITICAL - Report 004) ==="
    run_test test_absolute_path_specification
    run_test test_path_determination_logic
    run_test test_absolute_path_placeholder
    run_test test_expected_location

    echo ""
    info "=== Happy Path Tests ==="
    run_test test_progress_markers_documented
    run_test test_report_verification_step
    run_test test_planning_phase_integration

    echo ""
    info "=== Error Recovery Tests ==="
    run_test test_retry_step_exists
    run_test test_max_retry_enforcement
    run_test test_path_mismatch_recovery

    echo ""
    info "=== Error Classification Tests ==="
    run_test test_file_not_found_classification
    run_test test_path_mismatch_classification
    run_test test_invalid_metadata_classification
    run_test test_permission_denied_classification

    echo ""
    info "=== State Management Tests ==="
    run_test test_agent_to_report_mapping
    run_test test_workflow_state_structure
    run_test test_verification_summary_tracking

    echo ""
    info "=== Integration Tests ==="
    run_test test_backward_compatibility
    run_test test_error_utils_integration
    run_test test_checkpoint_integration

    echo ""
    info "=== Troubleshooting Tests ==="
    run_test test_troubleshooting_section_exists
    run_test test_path_inconsistency_troubleshooting

    echo ""
    info "=== Documentation Quality Tests ==="
    run_test test_step_numbering_consistency
    run_test test_critical_markers_present
  fi

  # Print summary
  echo ""
  echo "========================================="
  echo "Test Summary"
  echo "========================================="
  echo "Tests Run:    $TESTS_RUN"
  echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
  echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
  echo ""

  if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
  else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
  fi
}

main "$@"
