#!/usr/bin/env bash
# Test suite for EXIT trap timing in bash block execution model (Spec 661)
# Tests critical bash block execution patterns:
# - EXIT trap fires at bash block exit (subprocess termination), not workflow end
# - State ID file persistence across bash block boundaries
# - Cleanup trap placement (completion function only)
#
# Reference: bash-block-execution-model.md Pattern 6 (lines 382-399)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TESTS_PASSED=0
TESTS_FAILED=0

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

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
# Test 1: EXIT Trap Fires at Bash Block Exit (Subprocess Termination)
# ==============================================================================
test_exit_trap_fires_at_block_exit() {
  print_test_header "EXIT Trap Fires at Bash Block Exit"

  # Create temporary test file
  TEST_FILE="/tmp/test_exit_trap_$$"
  rm -f "$TEST_FILE"

  # Simulate bash block with EXIT trap (subprocess context)
  bash -c "
    trap 'echo \"TRAP_FIRED\" > \"$TEST_FILE\"' EXIT
    echo \"Block executing\"
  "

  # Verify trap fired after block exit
  if [ -f "$TEST_FILE" ] && grep -q "TRAP_FIRED" "$TEST_FILE"; then
    pass "EXIT trap fires at bash block exit (subprocess termination)"
  else
    fail "EXIT trap did not fire at block exit"
  fi

  # Cleanup
  rm -f "$TEST_FILE"
}

# ==============================================================================
# Test 2: State ID File Survives First Bash Block (No Premature Cleanup)
# ==============================================================================
test_state_id_file_persists_across_blocks() {
  print_test_header "State ID File Persists Across Bash Blocks"

  # Create state ID file with fixed semantic filename (Pattern 1)
  COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id_test_$$.txt"
  WORKFLOW_ID="test_workflow_$$_$(date +%s)"

  # Simulate first bash block creating state ID file
  bash -c "
    echo '$WORKFLOW_ID' > '$COORDINATE_STATE_ID_FILE'
    echo 'Block 1 complete'
  "

  # Verify state ID file still exists after first block exits
  if [ -f "$COORDINATE_STATE_ID_FILE" ]; then
    pass "State ID file persists after first bash block exit"
  else
    fail "State ID file deleted prematurely after first block"
  fi

  # Verify contents correct
  if [ "$(cat "$COORDINATE_STATE_ID_FILE")" = "$WORKFLOW_ID" ]; then
    pass "State ID file contents preserved correctly"
  else
    fail "State ID file contents corrupted"
  fi

  # Cleanup
  rm -f "$COORDINATE_STATE_ID_FILE"
}

# ==============================================================================
# Test 3: Premature EXIT Trap Causes State ID File Deletion (Anti-Pattern)
# ==============================================================================
test_premature_exit_trap_deletes_state_file() {
  print_test_header "Premature EXIT Trap Deletes State File (Anti-Pattern)"

  # Create state ID file
  COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id_antipattern_$$.txt"
  WORKFLOW_ID="test_workflow_$$_$(date +%s)"

  # Simulate FLAWED first bash block with premature EXIT trap
  bash -c "
    echo '$WORKFLOW_ID' > '$COORDINATE_STATE_ID_FILE'
    trap 'rm -f \"$COORDINATE_STATE_ID_FILE\" 2>/dev/null || true' EXIT
    echo 'Block 1 with premature trap complete'
  "

  # Verify state ID file was deleted (demonstrating the bug)
  if [ ! -f "$COORDINATE_STATE_ID_FILE" ]; then
    pass "Anti-pattern demonstration: Premature EXIT trap deletes state ID file"
  else
    fail "Expected state ID file to be deleted by premature trap"
    # Cleanup if test failed
    rm -f "$COORDINATE_STATE_ID_FILE"
  fi
}

# ==============================================================================
# Test 4: Fixed Pattern - No EXIT Trap in First Block
# ==============================================================================
test_fixed_pattern_no_trap_in_first_block() {
  print_test_header "Fixed Pattern: No EXIT Trap in First Block"

  # Create state ID file using fixed pattern
  COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id_fixed_$$.txt"
  WORKFLOW_ID="test_workflow_$$_$(date +%s)"

  # Simulate FIXED first bash block (Pattern 1 + Pattern 6)
  bash -c "
    # Pattern 1: Fixed Semantic Filename
    echo '$WORKFLOW_ID' > '$COORDINATE_STATE_ID_FILE'

    # Pattern 6: NO EXIT trap in initialization block
    echo 'Block 1 complete - no cleanup trap'
  "

  # Verify state ID file persists
  if [ -f "$COORDINATE_STATE_ID_FILE" ]; then
    pass "Fixed pattern: State ID file persists without EXIT trap in first block"
  else
    fail "State ID file missing - fixed pattern not working"
  fi

  # Simulate second bash block loading state
  bash -c "
    if [ -f '$COORDINATE_STATE_ID_FILE' ]; then
      LOADED_WORKFLOW_ID=\$(cat '$COORDINATE_STATE_ID_FILE')
      if [ \"\$LOADED_WORKFLOW_ID\" = '$WORKFLOW_ID' ]; then
        echo 'SUCCESS' > '${COORDINATE_STATE_ID_FILE}.result'
      fi
    fi
  "

  # Verify second block successfully loaded state
  if [ -f "${COORDINATE_STATE_ID_FILE}.result" ] && grep -q "SUCCESS" "${COORDINATE_STATE_ID_FILE}.result"; then
    pass "Second bash block successfully loads state from persisted file"
  else
    fail "Second bash block could not load state"
  fi

  # Cleanup
  rm -f "$COORDINATE_STATE_ID_FILE" "${COORDINATE_STATE_ID_FILE}.result"
}

# ==============================================================================
# Test 5: Cleanup Trap Only in Final Completion Function
# ==============================================================================
test_cleanup_trap_in_completion_function_only() {
  print_test_header "Cleanup Trap Only in Final Completion Function"

  # Create state ID file
  COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id_completion_$$.txt"
  WORKFLOW_ID="test_workflow_$$_$(date +%s)"

  # Simulate complete workflow with cleanup in final function only
  bash -c "
    # Block 1: Initialize state
    echo '$WORKFLOW_ID' > '$COORDINATE_STATE_ID_FILE'
    echo 'Block 1 complete (no trap)'
  "

  # Verify state persists after block 1
  if [ -f "$COORDINATE_STATE_ID_FILE" ]; then
    pass "State ID file persists after Block 1 (no trap)"
  else
    fail "State ID file missing after Block 1"
  fi

  # Simulate intermediate blocks
  bash -c "
    if [ -f '$COORDINATE_STATE_ID_FILE' ]; then
      echo 'Block 2 using state (no trap)'
    fi
  "

  # Verify state still persists
  if [ -f "$COORDINATE_STATE_ID_FILE" ]; then
    pass "State ID file persists through intermediate blocks"
  else
    fail "State ID file deleted prematurely"
  fi

  # Simulate final completion function with cleanup trap
  bash -c "
    # Pattern 6: Cleanup trap ONLY in final completion function
    trap 'rm -f \"$COORDINATE_STATE_ID_FILE\" 2>/dev/null || true' EXIT
    echo 'Final block with cleanup trap'
  "

  # Verify state cleaned up after final block
  if [ ! -f "$COORDINATE_STATE_ID_FILE" ]; then
    pass "State ID file cleaned up after final completion function"
  else
    fail "State ID file not cleaned up - trap did not fire"
    # Manual cleanup
    rm -f "$COORDINATE_STATE_ID_FILE"
  fi
}

# ==============================================================================
# Run All Tests
# ==============================================================================
echo "Running EXIT Trap Timing Test Suite (Spec 661)"
echo "=============================================="

test_exit_trap_fires_at_block_exit
test_state_id_file_persists_across_blocks
test_premature_exit_trap_deletes_state_file
test_fixed_pattern_no_trap_in_first_block
test_cleanup_trap_in_completion_function_only

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
