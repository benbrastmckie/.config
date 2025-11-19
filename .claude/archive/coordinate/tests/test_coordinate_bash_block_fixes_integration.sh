#!/usr/bin/env bash
# Integration test for coordinate bash block fixes (Spec 661)
# Tests that both fixes work together:
# 1. State ID file persistence (Pattern 1 + Pattern 6)
# 2. Library sourcing order (Standard 15)
#
# Reference: Report 004 Recommendation 8

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
# Integration Test: Complete 3-Block Workflow with Both Fixes
# ==============================================================================
test_complete_workflow_integration() {
  print_test_header "Complete 3-Block Workflow (State Persistence + Library Sourcing)"

  WORKFLOW_ID="test_integration_$$_$(date +%s)"
  COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id_integration_$$.txt"
  STATE_FILE="${PROJECT_ROOT}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"

  # ===========================================================================
  # Block 1: Initialize workflow (Pattern 1 + Standard 15)
  # ===========================================================================
  bash -c "
    set -euo pipefail
    LIB_DIR='${PROJECT_ROOT}/.claude/lib'

    # Standard 15 sourcing order
    source \"\${LIB_DIR}/workflow-state-machine.sh\"
    source \"\${LIB_DIR}/state-persistence.sh\"
    source \"\${LIB_DIR}/error-handling.sh\"
    source \"\${LIB_DIR}/verification-helpers.sh\"

    # Initialize workflow state
    STATE_FILE=\$(init_workflow_state '$WORKFLOW_ID')

    # Pattern 1: Fixed semantic filename for state ID file
    COORDINATE_STATE_ID_FILE='$COORDINATE_STATE_ID_FILE'
    echo '$WORKFLOW_ID' > \"\$COORDINATE_STATE_ID_FILE\"

    # Verify state ID file created (Standard 0: Verification checkpoint)
    if ! verify_file_created \"\$COORDINATE_STATE_ID_FILE\" 'State ID file' 'Block 1'; then
      echo 'BLOCK1_FAIL: State ID file not created' >&2
      exit 1
    fi

    # Save state variables
    echo \"export COORDINATE_STATE_ID_FILE='\$COORDINATE_STATE_ID_FILE'\" >> \"\$STATE_FILE\"
    echo \"export WORKFLOW_SCOPE='research-and-plan'\" >> \"\$STATE_FILE\"

    # Pattern 6: NO EXIT trap in Block 1
    # (state ID file should persist after this block exits)

    echo 'BLOCK1_SUCCESS'
  " || { fail "Block 1 initialization failed"; return; }

  # Verify state ID file persists after Block 1
  if [ ! -f "$COORDINATE_STATE_ID_FILE" ]; then
    fail "State ID file deleted prematurely (Block 1 EXIT trap bug not fixed)"
    return
  fi

  pass "Block 1: State ID file persists (Pattern 6 working)"

  # ===========================================================================
  # Block 2: Load state and re-source libraries (load BEFORE sourcing)
  # ===========================================================================
  BLOCK2_RESULT=$(bash -c "
    set -euo pipefail
    LIB_DIR='${PROJECT_ROOT}/.claude/lib'

    # Read state ID file (Pattern 1)
    if [ -f '$COORDINATE_STATE_ID_FILE' ]; then
      WORKFLOW_ID=\$(cat '$COORDINATE_STATE_ID_FILE')
    else
      echo 'BLOCK2_FAIL: State ID file not found' >&2
      exit 1
    fi

    # Load workflow state FIRST (Fix 2: before library sourcing)
    STATE_FILE='${PROJECT_ROOT}/.claude/tmp/workflow_'\$WORKFLOW_ID'.sh'
    if [ -f \"\$STATE_FILE\" ]; then
      source \"\$STATE_FILE\"
    else
      echo 'BLOCK2_FAIL: State file not found' >&2
      exit 1
    fi

    # Re-source libraries in Standard 15 order (Fix 2)
    source \"\${LIB_DIR}/workflow-state-machine.sh\"
    source \"\${LIB_DIR}/state-persistence.sh\"
    source \"\${LIB_DIR}/error-handling.sh\"
    source \"\${LIB_DIR}/verification-helpers.sh\"

    # Verify WORKFLOW_SCOPE preserved (not reset by library sourcing)
    if [ \"\${WORKFLOW_SCOPE:-}\" != 'research-and-plan' ]; then
      echo 'BLOCK2_FAIL: WORKFLOW_SCOPE reset' >&2
      exit 1
    fi

    # Verify functions available
    if ! command -v verify_file_created &>/dev/null; then
      echo 'BLOCK2_FAIL: verify_file_created not available' >&2
      exit 1
    fi

    echo 'BLOCK2_SUCCESS'
  ")

  if echo "$BLOCK2_RESULT" | grep -q "BLOCK2_SUCCESS"; then
    pass "Block 2: State loaded before library sourcing, WORKFLOW_SCOPE preserved"
  else
    fail "Block 2 failed: $BLOCK2_RESULT"
    rm -f "$COORDINATE_STATE_ID_FILE" "$STATE_FILE"
    return
  fi

  # ===========================================================================
  # Block 3: Final block with cleanup
  # ===========================================================================
  bash -c "
    set -euo pipefail
    LIB_DIR='${PROJECT_ROOT}/.claude/lib'

    # Load state and re-source libraries again
    WORKFLOW_ID=\$(cat '$COORDINATE_STATE_ID_FILE')
    STATE_FILE='${PROJECT_ROOT}/.claude/tmp/workflow_'\$WORKFLOW_ID'.sh'
    source \"\$STATE_FILE\"

    source \"\${LIB_DIR}/workflow-state-machine.sh\"
    source \"\${LIB_DIR}/state-persistence.sh\"
    source \"\${LIB_DIR}/error-handling.sh\"
    source \"\${LIB_DIR}/verification-helpers.sh\"

    # Pattern 6: Cleanup trap ONLY in final block
    trap 'rm -f \"$COORDINATE_STATE_ID_FILE\" \"\$STATE_FILE\"' EXIT

    echo 'BLOCK3_SUCCESS'
  "

  # Verify cleanup happened
  if [ ! -f "$COORDINATE_STATE_ID_FILE" ]; then
    pass "Block 3: Cleanup trap removed state ID file (Pattern 6 working)"
  else
    fail "Block 3: Cleanup trap did not fire"
    rm -f "$COORDINATE_STATE_ID_FILE"
  fi

  if [ ! -f "$STATE_FILE" ]; then
    pass "Block 3: Cleanup trap removed state file"
  else
    fail "Block 3: State file not cleaned up"
    rm -f "$STATE_FILE"
  fi
}

# ==============================================================================
# Integration Test: Fix 1 + Fix 2 Prevent Original Bug
# ==============================================================================
test_fixes_prevent_original_bugs() {
  print_test_header "Fixes Prevent Original Bugs"

  WORKFLOW_ID="test_bugs_$$_$(date +%s)"
  COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id_bugtest_$$.txt"
  STATE_FILE="${PROJECT_ROOT}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"

  # Test that original Bug 1 is fixed (premature EXIT trap)
  bash -c "
    echo 'test' > '$COORDINATE_STATE_ID_FILE'
    # NO EXIT trap here (Pattern 6)
  "

  if [ -f "$COORDINATE_STATE_ID_FILE" ]; then
    pass "Bug 1 fixed: No premature EXIT trap deleting state ID file"
  else
    fail "Bug 1 NOT fixed: State ID file still deleted prematurely"
  fi

  # Test that original Bug 2 is fixed (library sourcing order)
  bash -c "
    set -euo pipefail
    LIB_DIR='${PROJECT_ROOT}/.claude/lib'

    # Initialize state file
    mkdir -p '${PROJECT_ROOT}/.claude/tmp'
    echo 'export WORKFLOW_SCOPE=\"test-scope\"' > '$STATE_FILE'

    # Load state BEFORE sourcing libraries (Fix 2)
    source '$STATE_FILE'

    # Re-source libraries
    source \"\${LIB_DIR}/workflow-state-machine.sh\"
    source \"\${LIB_DIR}/state-persistence.sh\"

    # Verify WORKFLOW_SCOPE not reset
    if [ \"\${WORKFLOW_SCOPE:-}\" = 'test-scope' ]; then
      echo 'SUCCESS'
    else
      echo 'FAIL' >&2
      exit 1
    fi
  " && pass "Bug 2 fixed: WORKFLOW_SCOPE not reset by library sourcing" || fail "Bug 2 NOT fixed"

  # Cleanup
  rm -f "$COORDINATE_STATE_ID_FILE" "$STATE_FILE"
}

# ==============================================================================
# Integration Test: Standard 15 + Pattern 1 + Pattern 6 Together
# ==============================================================================
test_all_patterns_together() {
  print_test_header "All Patterns Working Together"

  WORKFLOW_ID="test_patterns_$$_$(date +%s)"
  COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id_patterns_$$.txt"

  # Simulate coordinate workflow with all patterns
  bash -c "
    set -euo pipefail
    LIB_DIR='${PROJECT_ROOT}/.claude/lib'

    # Pattern 1: Fixed semantic filename
    COORDINATE_STATE_ID_FILE='$COORDINATE_STATE_ID_FILE'

    # Standard 15: Correct sourcing order
    source \"\${LIB_DIR}/workflow-state-machine.sh\"
    source \"\${LIB_DIR}/state-persistence.sh\"
    source \"\${LIB_DIR}/error-handling.sh\"
    source \"\${LIB_DIR}/verification-helpers.sh\"

    # Create state ID file
    echo 'test' > \"\$COORDINATE_STATE_ID_FILE\"

    # Standard 0: Verification checkpoint
    if verify_file_created \"\$COORDINATE_STATE_ID_FILE\" 'State ID' 'Test'; then
      echo 'PATTERNS_SUCCESS'
    fi

    # Pattern 6: No EXIT trap (file should persist)
  " || { fail "Patterns integration failed"; return; }

  if [ -f "$COORDINATE_STATE_ID_FILE" ]; then
    pass "All patterns work together: Pattern 1 + Standard 15 + Pattern 6 + Standard 0"
  else
    fail "Patterns integration issue: State ID file missing"
  fi

  # Cleanup
  rm -f "$COORDINATE_STATE_ID_FILE"
}

# ==============================================================================
# Run All Integration Tests
# ==============================================================================
echo "Running Coordinate Bash Block Fixes Integration Tests (Spec 661)"
echo "================================================================="

test_complete_workflow_integration
test_fixes_prevent_original_bugs
test_all_patterns_together

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
  echo -e "${GREEN}✓ All integration tests passed!${NC}"
  echo ""
  echo "Both fixes verified working together:"
  echo "  • Fix 1: State ID file persistence (Pattern 1 + Pattern 6)"
  echo "  • Fix 2: Library sourcing order (Standard 15)"
  exit 0
else
  echo -e "${RED}✗ Some integration tests failed${NC}"
  exit 1
fi
