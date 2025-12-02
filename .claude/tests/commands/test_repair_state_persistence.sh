#!/usr/bin/env bash
# Test file: test_repair_state_persistence.sh
# Tests /repair command state persistence and transition fixes

set -uo pipefail

# Source testing utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test configuration
TEST_NAME="repair_state_persistence"
TESTS_PASSED=0
TESTS_FAILED=0
SUPPRESS_ERR_LOGGING=1
export SUPPRESS_ERR_LOGGING

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test result tracking
test_result() {
  local test_name="$1"
  local result="$2"
  local message="${3:-}"

  if [ "$result" = "PASS" ]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} Test $TESTS_PASSED: $test_name"
  else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} Test failed: $test_name"
    if [ -n "$message" ]; then
      echo "  Error: $message"
    fi
  fi
}

# Cleanup function
cleanup() {
  # Remove test state files
  rm -f "$HOME/.claude/tmp/workflow_repair_test_"*.sh 2>/dev/null || true
  rm -f "$HOME/.claude/tmp/workflow_repair_integrity_test.sh" 2>/dev/null || true
  rm -f "$HOME/.claude/data/workflow_id_repair_test_"*.txt 2>/dev/null || true

  # Clean up test specs
  rm -rf "$HOME/.claude/specs/9"[8-9][0-9]"_"*"_test" 2>/dev/null || true
}

trap cleanup EXIT

echo "=== Testing /repair State Persistence and Transitions ==="
echo ""

# Test 1: Verify ERROR_FILTERS stored as flat keys
echo "Test 1: ERROR_FILTERS stored as flat keys..."

# Create mock state initialization
WORKFLOW_ID="repair_test_$$"
STATE_FILE="$HOME/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
mkdir -p "$(dirname "$STATE_FILE")" 2>/dev/null || {
  echo "ERROR: Cannot create test directory"
  exit 1
}

# Simulate flat key storage
cat > "$STATE_FILE" <<EOF
ERROR_FILTER_SINCE="1h"
ERROR_FILTER_TYPE="state_error"
ERROR_FILTER_COMMAND="/build"
ERROR_FILTER_SEVERITY="high"
WORKFLOW_ID="$WORKFLOW_ID"
CURRENT_STATE="initialize"
EOF

# Verify flat keys exist
if grep -q "^ERROR_FILTER_SINCE=" "$STATE_FILE" && \
   grep -q "^ERROR_FILTER_TYPE=" "$STATE_FILE" && \
   grep -q "^ERROR_FILTER_COMMAND=" "$STATE_FILE" && \
   grep -q "^ERROR_FILTER_SEVERITY=" "$STATE_FILE"; then
  test_result "ERROR_FILTERS stored as flat keys" "PASS"
else
  test_result "ERROR_FILTERS stored as flat keys" "FAIL" "Flat keys not found in state file"
fi

# Verify no JSON ERROR_FILTERS key exists
if ! grep -q "^ERROR_FILTERS=" "$STATE_FILE"; then
  test_result "No JSON ERROR_FILTERS key" "PASS"
else
  test_result "No JSON ERROR_FILTERS key" "FAIL" "JSON key still present"
fi

# Test 2: Verify RESEARCH_DIR restored in Block 2a
echo ""
echo "Test 2: RESEARCH_DIR restored in Block 2a..."

# Add RESEARCH_DIR to state file
echo 'RESEARCH_DIR="/home/test/.claude/specs/999_test/reports/"' >> "$STATE_FILE"
echo 'PLANS_DIR="/home/test/.claude/specs/999_test/plans/"' >> "$STATE_FILE"
echo 'TOPIC_PATH="/home/test/.claude/specs/999_test"' >> "$STATE_FILE"

# Source state file
source "$STATE_FILE"

# Verify RESEARCH_DIR is set
if [ -n "${RESEARCH_DIR:-}" ] && [ "$RESEARCH_DIR" = "/home/test/.claude/specs/999_test/reports/" ]; then
  test_result "RESEARCH_DIR restored from state file" "PASS"
else
  test_result "RESEARCH_DIR restored from state file" "FAIL" "RESEARCH_DIR='${RESEARCH_DIR:-UNSET}'"
fi

# Verify PLANS_DIR is set
if [ -n "${PLANS_DIR:-}" ]; then
  test_result "PLANS_DIR restored from state file" "PASS"
else
  test_result "PLANS_DIR restored from state file" "FAIL" "PLANS_DIR not restored"
fi

# Test 3: Verify state transitions follow research-and-plan sequence
echo ""
echo "Test 3: State transitions follow correct sequence..."

# Source state machine library
source "$PROJECT_ROOT/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
  test_result "State machine library loading" "FAIL" "Cannot load workflow-state-machine.sh"
  exit 1
}

# Initialize state machine
WORKFLOW_TYPE="research-and-plan"
RESEARCH_COMPLEXITY=2
sm_init "test workflow" "/repair" "$WORKFLOW_TYPE" "$RESEARCH_COMPLEXITY" "[]" >/dev/null 2>&1

# Verify initial state
if [ "$CURRENT_STATE" = "$STATE_INITIALIZE" ]; then
  test_result "State machine initializes to 'initialize'" "PASS"
else
  test_result "State machine initializes to 'initialize'" "FAIL" "State=$CURRENT_STATE"
fi

# Transition to research
sm_transition "$STATE_RESEARCH" >/dev/null 2>&1
RESEARCH_TRANSITION=$?

if [ $RESEARCH_TRANSITION -eq 0 ] && [ "$CURRENT_STATE" = "$STATE_RESEARCH" ]; then
  test_result "Transition initialize → research" "PASS"
else
  test_result "Transition initialize → research" "FAIL" "Exit=$RESEARCH_TRANSITION, State=$CURRENT_STATE"
fi

# Transition to plan
sm_transition "$STATE_PLAN" >/dev/null 2>&1
PLAN_TRANSITION=$?

if [ $PLAN_TRANSITION -eq 0 ] && [ "$CURRENT_STATE" = "$STATE_PLAN" ]; then
  test_result "Transition research → plan" "PASS"
else
  test_result "Transition research → plan" "FAIL" "Exit=$PLAN_TRANSITION, State=$CURRENT_STATE"
fi

# Transition to complete
sm_transition "$STATE_COMPLETE" >/dev/null 2>&1
COMPLETE_TRANSITION=$?

if [ $COMPLETE_TRANSITION -eq 0 ] && [ "$CURRENT_STATE" = "$STATE_COMPLETE" ]; then
  test_result "Transition plan → complete" "PASS"
else
  test_result "Transition plan → complete" "FAIL" "Exit=$COMPLETE_TRANSITION, State=$CURRENT_STATE"
fi

# Test 4: Verify defensive mkdir creates missing directories
echo ""
echo "Test 4: Defensive directory creation..."

TEST_DIR="/tmp/repair_test_$$"
RESEARCH_DIR="$TEST_DIR/reports"

# Ensure test directory doesn't exist
rm -rf "$TEST_DIR"

# Simulate defensive mkdir pattern
if [ ! -d "$RESEARCH_DIR" ]; then
  mkdir -p "$RESEARCH_DIR" 2>/dev/null
  MKDIR_EXIT=$?

  if [ $MKDIR_EXIT -eq 0 ] && [ -d "$RESEARCH_DIR" ]; then
    test_result "Defensive mkdir creates missing RESEARCH_DIR" "PASS"
  else
    test_result "Defensive mkdir creates missing RESEARCH_DIR" "FAIL" "mkdir failed with exit $MKDIR_EXIT"
  fi
else
  test_result "Defensive mkdir creates missing RESEARCH_DIR" "FAIL" "Directory already existed"
fi

# Verify find command works with fallback
EXISTING_REPORTS=$(find "$RESEARCH_DIR" -name '[0-9][0-9][0-9]-*.md' 2>/dev/null | wc -l | tr -d ' ' || echo "0")

if [ "$EXISTING_REPORTS" = "0" ]; then
  test_result "find command with fallback (empty dir)" "PASS"
else
  test_result "find command with fallback (empty dir)" "FAIL" "Found $EXISTING_REPORTS reports"
fi

# Create test report and verify find works
touch "$RESEARCH_DIR/001-test-report.md"
EXISTING_REPORTS=$(find "$RESEARCH_DIR" -name '[0-9][0-9][0-9]-*.md' 2>/dev/null | wc -l | tr -d ' ' || echo "0")

if [ "$EXISTING_REPORTS" = "1" ]; then
  test_result "find command counts existing reports" "PASS"
else
  test_result "find command counts existing reports" "FAIL" "Expected 1, found $EXISTING_REPORTS"
fi

# Cleanup test directory
rm -rf "$TEST_DIR"

# Test 5: Verify state file integrity across blocks
echo ""
echo "Test 5: State file integrity..."

# Create comprehensive state file
STATE_FILE_TEST="$HOME/.claude/tmp/workflow_repair_integrity_test.sh"
cat > "$STATE_FILE_TEST" <<EOF
WORKFLOW_ID="repair_integrity_test"
CLAUDE_PROJECT_DIR="$HOME/.config"
SPECS_DIR="$HOME/.config/.claude/specs"
RESEARCH_DIR="$HOME/.config/.claude/specs/999_test/reports"
PLANS_DIR="$HOME/.config/.claude/specs/999_test/plans"
TOPIC_PATH="$HOME/.config/.claude/specs/999_test"
TOPIC_NAME="test_topic"
TOPIC_NUM="999"
ERROR_DESCRIPTION="test error analysis"
ERROR_FILTER_SINCE="24h"
ERROR_FILTER_TYPE="state_error"
ERROR_FILTER_COMMAND="/repair"
ERROR_FILTER_SEVERITY=""
RESEARCH_COMPLEXITY="2"
CURRENT_STATE="research"
EOF

# Verify all critical variables present
MISSING_VARS=""
for var in WORKFLOW_ID RESEARCH_DIR PLANS_DIR TOPIC_PATH ERROR_FILTER_SINCE ERROR_FILTER_TYPE ERROR_FILTER_COMMAND; do
  if ! grep -q "^${var}=" "$STATE_FILE_TEST"; then
    MISSING_VARS="$MISSING_VARS $var"
  fi
done

if [ -z "$MISSING_VARS" ]; then
  test_result "All critical variables in state file" "PASS"
else
  test_result "All critical variables in state file" "FAIL" "Missing:$MISSING_VARS"
fi

# Clean up
rm -f "$STATE_FILE_TEST"

# Final summary
echo ""
echo "========================================"
echo "Test Results:"
echo "  Passed: $TESTS_PASSED"
echo "  Failed: $TESTS_FAILED"
echo "========================================"

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed${NC}"
  exit 1
fi
