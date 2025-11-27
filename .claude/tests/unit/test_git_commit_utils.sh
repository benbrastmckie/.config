#!/usr/bin/env bash
# test_git_commit_utils.sh - Unit tests for git-commit-utils.sh library
#
# Tests commit message generation for phase, stage, and plan completions
# Verifies validation logic and error handling

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect project root using git or walk-up pattern
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  CLAUDE_PROJECT_DIR="$SCRIPT_DIR"
  while [ "$CLAUDE_PROJECT_DIR" != "/" ]; do
    if [ -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
      break
    fi
    CLAUDE_PROJECT_DIR="$(dirname "$CLAUDE_PROJECT_DIR")"
  done
fi
CLAUDE_LIB="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Source the library under test
source "$CLAUDE_LIB/util/git-commit-utils.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test helper functions
assert_equals() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ "$expected" == "$actual" ]]; then
    echo -e "${GREEN}✓${NC} ${test_name}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} ${test_name}"
    echo "  Expected: ${expected}"
    echo "  Got:      ${actual}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_contains() {
  local substring="$1"
  local actual="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ "$actual" == *"$substring"* ]]; then
    echo -e "${GREEN}✓${NC} ${test_name}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} ${test_name}"
    echo "  Expected substring: ${substring}"
    echo "  In:                 ${actual}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_return_code() {
  local expected_code="$1"
  local actual_code="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ "$expected_code" -eq "$actual_code" ]]; then
    echo -e "${GREEN}✓${NC} ${test_name}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} ${test_name}"
    echo "  Expected return code: ${expected_code}"
    echo "  Got return code:      ${actual_code}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Test Suite
echo "================================================"
echo "Git Commit Utils Test Suite"
echo "================================================"
echo ""

# Test 1: Stage completion
echo "Test Group: Stage Completion"
echo "----------------------------"

MSG=$(generate_commit_message "027" "stage" "2" "1" "Database Schema" "")
assert_equals "feat(027): complete Phase 2 Stage 1 - Database Schema" "$MSG" "Stage completion format"

MSG=$(generate_commit_message "042" "stage" "3" "2" "API Endpoints" "")
assert_equals "feat(042): complete Phase 3 Stage 2 - API Endpoints" "$MSG" "Stage completion with different numbers"

echo ""

# Test 2: Phase completion
echo "Test Group: Phase Completion"
echo "----------------------------"

MSG=$(generate_commit_message "042" "phase" "3" "" "Backend Implementation" "")
assert_equals "feat(042): complete Phase 3 - Backend Implementation" "$MSG" "Phase completion format"

MSG=$(generate_commit_message "027" "phase" "5" "" "Testing and Validation" "")
assert_equals "feat(027): complete Phase 5 - Testing and Validation" "$MSG" "Phase completion with different numbers"

echo ""

# Test 3: Plan completion
echo "Test Group: Plan Completion"
echo "-----------------------------"

MSG=$(generate_commit_message "080" "plan" "" "" "" "authentication system")
assert_equals "feat(080): complete authentication system" "$MSG" "Plan completion format"

MSG=$(generate_commit_message "123" "plan" "" "" "" "orchestrate command enhancement")
assert_equals "feat(123): complete orchestrate command enhancement" "$MSG" "Plan completion with different feature name"

echo ""

# Test 4: Validation - missing required inputs
echo "Test Group: Validation - Missing Inputs"
echo "---------------------------------------"

MSG=$(generate_commit_message "" "phase" "3" "" "Backend" "" 2>&1)
RETCODE=$?
assert_contains "ERROR: topic_number required" "$MSG" "Missing topic_number"
assert_return_code 1 $RETCODE "Missing topic_number returns error code"

MSG=$(generate_commit_message "027" "" "3" "" "Backend" "" 2>&1)
RETCODE=$?
assert_contains "ERROR: completion_type required" "$MSG" "Missing completion_type"
assert_return_code 1 $RETCODE "Missing completion_type returns error code"

MSG=$(generate_commit_message "027" "phase" "" "" "Backend" "" 2>&1)
RETCODE=$?
assert_contains "ERROR: phase_number required" "$MSG" "Missing phase_number for phase completion"
assert_return_code 1 $RETCODE "Missing phase_number returns error code"

MSG=$(generate_commit_message "027" "phase" "3" "" "" "" 2>&1)
RETCODE=$?
assert_contains "ERROR: name required" "$MSG" "Missing name for phase completion"
assert_return_code 1 $RETCODE "Missing name returns error code"

MSG=$(generate_commit_message "027" "stage" "3" "" "Backend" "" 2>&1)
RETCODE=$?
assert_contains "ERROR: stage_number required" "$MSG" "Missing stage_number for stage completion"
assert_return_code 1 $RETCODE "Missing stage_number returns error code"

MSG=$(generate_commit_message "080" "plan" "" "" "" "" 2>&1)
RETCODE=$?
assert_contains "ERROR: feature_name required" "$MSG" "Missing feature_name for plan completion"
assert_return_code 1 $RETCODE "Missing feature_name returns error code"

echo ""

# Test 5: Validation - invalid formats
echo "Test Group: Validation - Invalid Formats"
echo "----------------------------------------"

MSG=$(generate_commit_message "27" "phase" "3" "" "Backend" "" 2>&1)
RETCODE=$?
assert_contains "ERROR: topic_number must be 3-digit format" "$MSG" "Topic number not 3 digits"
assert_return_code 1 $RETCODE "Invalid topic_number format returns error code"

MSG=$(generate_commit_message "1234" "phase" "3" "" "Backend" "" 2>&1)
RETCODE=$?
assert_contains "ERROR: topic_number must be 3-digit format" "$MSG" "Topic number too long"
assert_return_code 1 $RETCODE "Topic number too long returns error code"

MSG=$(generate_commit_message "abc" "phase" "3" "" "Backend" "" 2>&1)
RETCODE=$?
assert_contains "ERROR: topic_number must be 3-digit format" "$MSG" "Topic number not numeric"
assert_return_code 1 $RETCODE "Non-numeric topic_number returns error code"

MSG=$(generate_commit_message "027" "invalid" "3" "" "Backend" "" 2>&1)
RETCODE=$?
assert_contains "ERROR: completion_type must be phase, stage, or plan" "$MSG" "Invalid completion_type"
assert_return_code 1 $RETCODE "Invalid completion_type returns error code"

echo ""

# Test 6: Validate commit message function
echo "Test Group: Commit Message Validation"
echo "-------------------------------------"

validate_commit_message "feat(027): complete Phase 3 - Backend Implementation"
assert_return_code 0 $? "Valid commit message passes validation"

validate_commit_message "" 2>&1 > /dev/null
assert_return_code 1 $? "Empty commit message fails validation"

validate_commit_message "feat(027): complete Phase 3 ✓ Backend" 2>&1 > /dev/null
assert_return_code 1 $? "Commit message with emoji fails validation"

validate_commit_message "fix(027): complete Phase 3 - Backend" 2>&1 > /dev/null
assert_return_code 1 $? "Commit message without feat prefix fails validation"

validate_commit_message "feat(27): complete Phase 3 - Backend" 2>&1 > /dev/null
assert_return_code 1 $? "Commit message with 2-digit topic fails validation"

echo ""

# Test 7: Edge cases
echo "Test Group: Edge Cases"
echo "---------------------"

MSG=$(generate_commit_message "001" "phase" "1" "" "Initial Setup" "")
assert_equals "feat(001): complete Phase 1 - Initial Setup" "$MSG" "Topic 001 (minimum)"

MSG=$(generate_commit_message "999" "phase" "10" "" "Final Phase" "")
assert_equals "feat(999): complete Phase 10 - Final Phase" "$MSG" "Topic 999 (maximum)"

MSG=$(generate_commit_message "042" "phase" "3" "" "Phase with Special-Characters_123" "")
assert_equals "feat(042): complete Phase 3 - Phase with Special-Characters_123" "$MSG" "Name with special characters"

echo ""

# Final Summary
echo "================================================"
echo "Test Summary"
echo "================================================"
echo -e "Tests Run:    ${TESTS_RUN}"
echo -e "Passed:       ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Failed:       ${RED}${TESTS_FAILED}${NC}"

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo -e "\n${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "\n${RED}Some tests failed!${NC}"
  exit 1
fi
