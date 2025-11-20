#!/usr/bin/env bash
# test_plan_updates.sh - Test suite for plan update integration in /build command
#
# Tests:
# - mark_phase_complete() functionality
# - add_complete_marker() functionality
# - verify_phase_complete() functionality
# - Level 0/1/2 plan structure handling
# - State persistence for completed phases
#
# Usage: bash .claude/tests/test_plan_updates.sh

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

# Detect project directory
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  CLAUDE_PROJECT_DIR="$(pwd)"
fi
export CLAUDE_PROJECT_DIR

# Source required libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh" 2>/dev/null || {
  echo -e "${RED}ERROR: Could not source checkbox-utils.sh${NC}"
  exit 1
}

source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo -e "${RED}ERROR: Could not source state-persistence.sh${NC}"
  exit 1
}

# Test helper functions
log_test() {
  echo -e "${YELLOW}TEST: $1${NC}"
  TESTS_RUN=$((TESTS_RUN + 1))
}

pass_test() {
  echo -e "${GREEN}  PASS: $1${NC}"
  TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail_test() {
  echo -e "${RED}  FAIL: $1${NC}"
  TESTS_FAILED=$((TESTS_FAILED + 1))
}

# Create temporary test directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "=== Plan Update Integration Tests ==="
echo "Test directory: $TEMP_DIR"
echo ""

# ============================================================================
# Test 1: mark_phase_complete with Level 0 plan
# ============================================================================
log_test "mark_phase_complete with Level 0 plan"

# Create test plan
cat > "$TEMP_DIR/test_level0.md" << 'EOF'
# Test Plan

## Overview
Test plan for unit testing.

### Phase 1: Setup
dependencies: []

Tasks:
- [ ] Create test file
- [ ] Run initial setup
- [ ] Verify configuration

### Phase 2: Implementation
dependencies: [1]

Tasks:
- [ ] Implement feature A
- [ ] Implement feature B
- [ ] Add unit tests
EOF

# Run mark_phase_complete
if mark_phase_complete "$TEMP_DIR/test_level0.md" 1; then
  # Verify checkboxes are marked
  if grep -q '\[x\] Create test file' "$TEMP_DIR/test_level0.md" && \
     grep -q '\[x\] Run initial setup' "$TEMP_DIR/test_level0.md" && \
     grep -q '\[x\] Verify configuration' "$TEMP_DIR/test_level0.md"; then
    pass_test "Phase 1 checkboxes marked complete"
  else
    fail_test "Phase 1 checkboxes not properly marked"
  fi

  # Verify Phase 2 unchanged
  if grep -q '\[ \] Implement feature A' "$TEMP_DIR/test_level0.md"; then
    pass_test "Phase 2 checkboxes unchanged"
  else
    fail_test "Phase 2 checkboxes incorrectly modified"
  fi
else
  fail_test "mark_phase_complete returned error"
fi

# ============================================================================
# Test 2: add_complete_marker
# ============================================================================
log_test "add_complete_marker to phase heading"

# Add [COMPLETE] marker
if add_complete_marker "$TEMP_DIR/test_level0.md" 1; then
  if grep -q '### Phase 1: Setup \[COMPLETE\]' "$TEMP_DIR/test_level0.md"; then
    pass_test "[COMPLETE] marker added to Phase 1"
  else
    fail_test "[COMPLETE] marker not found in Phase 1 heading"
  fi
else
  fail_test "add_complete_marker returned error"
fi

# Test idempotency - adding again should not duplicate
add_complete_marker "$TEMP_DIR/test_level0.md" 1
MARKER_COUNT=$(grep -c '\[COMPLETE\]' "$TEMP_DIR/test_level0.md" || echo 0)
if [ "$MARKER_COUNT" -eq 1 ]; then
  pass_test "add_complete_marker is idempotent"
else
  fail_test "add_complete_marker added duplicate markers"
fi

# ============================================================================
# Test 3: verify_phase_complete
# ============================================================================
log_test "verify_phase_complete functionality"

# Phase 1 should be complete
if verify_phase_complete "$TEMP_DIR/test_level0.md" 1; then
  pass_test "Phase 1 verified as complete"
else
  fail_test "Phase 1 should be complete but verification failed"
fi

# Phase 2 should be incomplete
if verify_phase_complete "$TEMP_DIR/test_level0.md" 2; then
  fail_test "Phase 2 should be incomplete"
else
  pass_test "Phase 2 verified as incomplete"
fi

# ============================================================================
# Test 4: update_checkbox with fuzzy matching
# ============================================================================
log_test "update_checkbox with fuzzy matching"

# Create test file
cat > "$TEMP_DIR/test_fuzzy.md" << 'EOF'
# Task List
- [ ] Create authentication module
- [ ] Add user registration
- [ ] Implement login flow
EOF

# Fuzzy match should work
if update_checkbox "$TEMP_DIR/test_fuzzy.md" "authentication" "x"; then
  if grep -q '\[x\] Create authentication module' "$TEMP_DIR/test_fuzzy.md"; then
    pass_test "Fuzzy matching works for 'authentication'"
  else
    fail_test "Fuzzy matching failed to update checkbox"
  fi
else
  fail_test "update_checkbox returned error with fuzzy match"
fi

# ============================================================================
# Test 5: State persistence for completed phases
# ============================================================================
log_test "State persistence for completed phases"

# Initialize workflow state
TEST_WORKFLOW_ID="test_plan_updates_$$"
init_workflow_state "$TEST_WORKFLOW_ID" > /dev/null

# Append completed phases
append_workflow_state "COMPLETED_PHASES" "1,2,3,"
append_workflow_state "COMPLETED_PHASE_COUNT" "3"

# Load and verify
load_workflow_state "$TEST_WORKFLOW_ID" false

if [ "${COMPLETED_PHASES:-}" = "1,2,3," ]; then
  pass_test "COMPLETED_PHASES persisted correctly"
else
  fail_test "COMPLETED_PHASES not persisted: got '${COMPLETED_PHASES:-}'"
fi

if [ "${COMPLETED_PHASE_COUNT:-}" = "3" ]; then
  pass_test "COMPLETED_PHASE_COUNT persisted correctly"
else
  fail_test "COMPLETED_PHASE_COUNT not persisted: got '${COMPLETED_PHASE_COUNT:-}'"
fi

# Cleanup state file
rm -f "${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${TEST_WORKFLOW_ID}.sh"

# ============================================================================
# Test 6: Multiple phases marked complete
# ============================================================================
log_test "Mark multiple phases complete"

# Create test plan with 3 phases
cat > "$TEMP_DIR/test_multi.md" << 'EOF'
# Multi-Phase Test

### Phase 1: First
- [ ] Task 1.1
- [ ] Task 1.2

### Phase 2: Second
- [ ] Task 2.1
- [ ] Task 2.2

### Phase 3: Third
- [ ] Task 3.1
- [ ] Task 3.2
EOF

# Mark all phases complete
for i in 1 2 3; do
  mark_phase_complete "$TEMP_DIR/test_multi.md" "$i"
  add_complete_marker "$TEMP_DIR/test_multi.md" "$i"
done

# Verify all phases complete
ALL_COMPLETE=true
for i in 1 2 3; do
  if ! verify_phase_complete "$TEMP_DIR/test_multi.md" "$i"; then
    ALL_COMPLETE=false
    fail_test "Phase $i not complete"
  fi
done

if [ "$ALL_COMPLETE" = "true" ]; then
  pass_test "All 3 phases marked complete"
fi

# Count [COMPLETE] markers
MARKER_COUNT=$(grep -c '\[COMPLETE\]' "$TEMP_DIR/test_multi.md" || echo 0)
if [ "$MARKER_COUNT" -eq 3 ]; then
  pass_test "All 3 phases have [COMPLETE] markers"
else
  fail_test "Expected 3 [COMPLETE] markers, got $MARKER_COUNT"
fi

# ============================================================================
# Test 7: verify_checkbox_consistency
# ============================================================================
log_test "verify_checkbox_consistency"

# For Level 0, consistency should always pass (no hierarchy)
if verify_checkbox_consistency "$TEMP_DIR/test_level0.md" 1; then
  pass_test "Level 0 plan consistency verification passes"
else
  fail_test "Level 0 plan consistency verification failed"
fi

# ============================================================================
# Test Results Summary
# ============================================================================
echo ""
echo "=== Test Results ==="
echo "Tests Run: $TESTS_RUN"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ "$TESTS_FAILED" -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed.${NC}"
  exit 1
fi
