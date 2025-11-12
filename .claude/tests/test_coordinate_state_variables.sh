#!/usr/bin/env bash
# Test suite for coordinate-specific state variable persistence (Spec 661 Phase 4)
# Tests that critical coordinate variables persist across bash block boundaries:
# - WORKFLOW_SCOPE
# - WORKFLOW_ID
# - COORDINATE_STATE_ID_FILE
# - REPORT_PATHS (array)
#
# Reference: Report 004 Recommendation 7

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

source "${PROJECT_ROOT}/.claude/lib/state-persistence.sh"
source "${PROJECT_ROOT}/.claude/lib/workflow-state-machine.sh"

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
# Test 1: WORKFLOW_SCOPE Persistence Across Blocks
# ==============================================================================
test_workflow_scope_persistence() {
  print_test_header "WORKFLOW_SCOPE Persistence Across Blocks"

  # Create test workflow
  WORKFLOW_ID="test_scope_$$_$(date +%s)"
  STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")

  # Block 1: Set WORKFLOW_SCOPE
  bash -c "
    source '${PROJECT_ROOT}/.claude/lib/state-persistence.sh'
    source '${PROJECT_ROOT}/.claude/lib/workflow-state-machine.sh'

    STATE_FILE='$STATE_FILE'
    WORKFLOW_SCOPE='research-and-plan'

    # Save to state using echo (simpler than function call in subshell)
    echo \"export WORKFLOW_SCOPE='research-and-plan'\" >> '$STATE_FILE'

    echo 'Block 1 complete'
  "

  # Block 2: Load and verify WORKFLOW_SCOPE
  RESULT=$(bash -c "
    source '${PROJECT_ROOT}/.claude/lib/state-persistence.sh'

    export STATE_FILE='$STATE_FILE'

    # Load workflow state
    if [ -f '$STATE_FILE' ]; then
      source '$STATE_FILE'
    fi

    # Verify WORKFLOW_SCOPE loaded
    if [ \"\${WORKFLOW_SCOPE:-}\" = 'research-and-plan' ]; then
      echo 'SUCCESS'
    else
      echo 'FAIL: WORKFLOW_SCOPE=\${WORKFLOW_SCOPE:-empty}'
    fi
  ")

  # Cleanup
  rm -f "$STATE_FILE"

  if echo "$RESULT" | grep -q "SUCCESS"; then
    pass "WORKFLOW_SCOPE persists across bash blocks (research-and-plan)"
  else
    fail "WORKFLOW_SCOPE not persisted: $RESULT"
  fi
}

# ==============================================================================
# Test 2: WORKFLOW_ID Persistence Across Blocks
# ==============================================================================
test_workflow_id_persistence() {
  print_test_header "WORKFLOW_ID Persistence Across Blocks"

  WORKFLOW_ID="test_wfid_$$_$(date +%s)"
  STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")

  # Verify WORKFLOW_ID in state file
  if grep -q "export WORKFLOW_ID=\"$WORKFLOW_ID\"" "$STATE_FILE"; then
    pass "WORKFLOW_ID saved to state file during initialization"
  else
    fail "WORKFLOW_ID not found in state file"
    rm -f "$STATE_FILE"
    return
  fi

  # Block 2: Load and verify WORKFLOW_ID
  RESULT=$(bash -c "
    source '${PROJECT_ROOT}/.claude/lib/state-persistence.sh'

    if [ -f '$STATE_FILE' ]; then
      source '$STATE_FILE'
    fi

    if [ \"\${WORKFLOW_ID:-}\" = '$WORKFLOW_ID' ]; then
      echo 'SUCCESS'
    else
      echo 'FAIL'
    fi
  ")

  # Cleanup
  rm -f "$STATE_FILE"

  if echo "$RESULT" | grep -q "SUCCESS"; then
    pass "WORKFLOW_ID persists across bash blocks"
  else
    fail "WORKFLOW_ID not persisted"
  fi
}

# ==============================================================================
# Test 3: COORDINATE_STATE_ID_FILE Persistence
# ==============================================================================
test_coordinate_state_id_file_persistence() {
  print_test_header "COORDINATE_STATE_ID_FILE Persistence"

  WORKFLOW_ID="test_csif_$$_$(date +%s)"
  STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
  COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id_test_$$.txt"

  # Block 1: Create and save state ID file path
  bash -c "
    source '${PROJECT_ROOT}/.claude/lib/state-persistence.sh'

    STATE_FILE='$STATE_FILE'
    COORDINATE_STATE_ID_FILE='$COORDINATE_STATE_ID_FILE'

    # Create state ID file
    echo '$WORKFLOW_ID' > '$COORDINATE_STATE_ID_FILE'

    # Save path to state
    echo \"export COORDINATE_STATE_ID_FILE='$COORDINATE_STATE_ID_FILE'\" >> '$STATE_FILE'
  "

  # Block 2: Load and use state ID file
  RESULT=$(bash -c "
    source '${PROJECT_ROOT}/.claude/lib/state-persistence.sh'

    if [ -f '$STATE_FILE' ]; then
      source '$STATE_FILE'
    fi

    # Verify variable loaded
    if [ -z \"\${COORDINATE_STATE_ID_FILE:-}\" ]; then
      echo 'FAIL: Variable not loaded'
      exit 1
    fi

    # Verify file exists and contains correct ID
    if [ -f \"\$COORDINATE_STATE_ID_FILE\" ]; then
      LOADED_ID=\$(cat \"\$COORDINATE_STATE_ID_FILE\")
      if [ \"\$LOADED_ID\" = '$WORKFLOW_ID' ]; then
        echo 'SUCCESS'
      else
        echo 'FAIL: Wrong ID'
      fi
    else
      echo 'FAIL: File not found'
    fi
  ")

  # Cleanup
  rm -f "$STATE_FILE" "$COORDINATE_STATE_ID_FILE"

  if echo "$RESULT" | grep -q "SUCCESS"; then
    pass "COORDINATE_STATE_ID_FILE path and file persist across blocks"
  else
    fail "COORDINATE_STATE_ID_FILE persistence failed: $RESULT"
  fi
}

# ==============================================================================
# Test 4: REPORT_PATHS Array Persistence
# ==============================================================================
test_report_paths_array_persistence() {
  print_test_header "REPORT_PATHS Array Persistence"

  WORKFLOW_ID="test_rp_$$_$(date +%s)"
  STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")

  # Block 1: Create and save REPORT_PATHS array
  bash -c "
    source '${PROJECT_ROOT}/.claude/lib/state-persistence.sh'

    STATE_FILE='$STATE_FILE'
    REPORT_PATHS=('/tmp/report1.md' '/tmp/report2.md' '/tmp/report3.md')

    # Save as indexed variables (coordinate pattern)
    echo \"export REPORT_PATH_0='/tmp/report1.md'\" >> '$STATE_FILE'
    echo \"export REPORT_PATH_1='/tmp/report2.md'\" >> '$STATE_FILE'
    echo \"export REPORT_PATH_2='/tmp/report3.md'\" >> '$STATE_FILE'
    echo \"export REPORT_PATHS_COUNT='3'\" >> '$STATE_FILE'
  "

  # Block 2: Load and reconstruct REPORT_PATHS array
  RESULT=$(bash -c "
    source '${PROJECT_ROOT}/.claude/lib/state-persistence.sh'
    source '${PROJECT_ROOT}/.claude/lib/workflow-initialization.sh'

    if [ -f '$STATE_FILE' ]; then
      source '$STATE_FILE'
    fi

    # Reconstruct array using defensive pattern
    reconstruct_report_paths_array

    # Verify array
    if [ \${#REPORT_PATHS[@]} -eq 3 ] && \
       [ \"\${REPORT_PATHS[0]}\" = '/tmp/report1.md' ] && \
       [ \"\${REPORT_PATHS[1]}\" = '/tmp/report2.md' ] && \
       [ \"\${REPORT_PATHS[2]}\" = '/tmp/report3.md' ]; then
      echo 'SUCCESS'
    else
      echo 'FAIL: Array size=\${#REPORT_PATHS[@]}'
    fi
  ")

  # Cleanup
  rm -f "$STATE_FILE"

  if echo "$RESULT" | grep -q "SUCCESS"; then
    pass "REPORT_PATHS array persists across bash blocks (3 elements)"
  else
    fail "REPORT_PATHS array not persisted correctly: $RESULT"
  fi
}

# ==============================================================================
# Test 5: Multiple Variables Persist Together
# ==============================================================================
test_multiple_variables_persistence() {
  print_test_header "Multiple Coordinate Variables Persist Together"

  WORKFLOW_ID="test_multi_$$_$(date +%s)"
  STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")

  # Block 1: Set all variables
  bash -c "
    source '${PROJECT_ROOT}/.claude/lib/state-persistence.sh'

    STATE_FILE='$STATE_FILE'

    # Save multiple variables
    echo \"export WORKFLOW_SCOPE='full-implementation'\" >> '$STATE_FILE'
    echo \"export WORKFLOW_ID='$WORKFLOW_ID'\" >> '$STATE_FILE'
    echo \"export COORDINATE_STATE_ID_FILE='/tmp/test.txt'\" >> '$STATE_FILE'
    echo \"export REPORT_PATH_0='/tmp/r1.md'\" >> '$STATE_FILE'
    echo \"export REPORT_PATHS_COUNT='1'\" >> '$STATE_FILE'
  "

  # Block 2: Load and verify all variables
  RESULT=$(bash -c "
    source '${PROJECT_ROOT}/.claude/lib/state-persistence.sh'

    if [ -f '$STATE_FILE' ]; then
      source '$STATE_FILE'
    fi

    # Check all variables
    failures=0

    if [ \"\${WORKFLOW_SCOPE:-}\" != 'full-implementation' ]; then
      echo 'FAIL: WORKFLOW_SCOPE'
      failures=\$((failures + 1))
    fi

    if [ \"\${WORKFLOW_ID:-}\" != '$WORKFLOW_ID' ]; then
      echo 'FAIL: WORKFLOW_ID'
      failures=\$((failures + 1))
    fi

    if [ \"\${COORDINATE_STATE_ID_FILE:-}\" != '/tmp/test.txt' ]; then
      echo 'FAIL: COORDINATE_STATE_ID_FILE'
      failures=\$((failures + 1))
    fi

    if [ \"\${REPORT_PATH_0:-}\" != '/tmp/r1.md' ]; then
      echo 'FAIL: REPORT_PATH_0'
      failures=\$((failures + 1))
    fi

    if [ \"\${REPORT_PATHS_COUNT:-}\" != '1' ]; then
      echo 'FAIL: REPORT_PATHS_COUNT'
      failures=\$((failures + 1))
    fi

    if [ \$failures -eq 0 ]; then
      echo 'SUCCESS'
    fi
  ")

  # Cleanup
  rm -f "$STATE_FILE"

  if echo "$RESULT" | grep -q "SUCCESS"; then
    pass "All coordinate variables persist together (5/5)"
  else
    fail "Some variables not persisted: $RESULT"
  fi
}

# ==============================================================================
# Run All Tests
# ==============================================================================
echo "Running Coordinate State Variables Test Suite (Spec 661 Phase 4)"
echo "================================================================="

test_workflow_scope_persistence
test_workflow_id_persistence
test_coordinate_state_id_file_persistence
test_report_paths_array_persistence
test_multiple_variables_persistence

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
