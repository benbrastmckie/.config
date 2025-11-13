#!/usr/bin/env bash
# Integration tests for /coordinate error recovery
# Spec 698: Verify end-to-end error handling behavior

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

TEST_SUITE="Coordinate Error Recovery Integration"
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

echo "=== $TEST_SUITE ==="
echo ""

# Test helper functions
pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  ((TESTS_PASSED++)) || true
  ((TESTS_RUN++)) || true
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  echo "  Reason: $2"
  ((TESTS_FAILED++)) || true
  ((TESTS_RUN++)) || true
}

# ==============================================================================
# Test 1: Classification Failure Shows Helpful Error
# ==============================================================================

test_classification_failure_shows_helpful_error() {
  echo "Test 1: Classification failure shows helpful error with recovery steps"

  # Force LLM classification failure
  export WORKFLOW_CLASSIFICATION_MODE=llm-only
  unset ANTHROPIC_API_KEY

  # Simulate the error path
  OUTPUT=$(bash -c '
    CLAUDE_PROJECT_DIR="'"$PROJECT_ROOT"'"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-scope-detection.sh"

    sm_init "test workflow" "coordinate" 2>&1 || true
  ')

  # Verify error message components
  CHECKS_PASSED=0

  if echo "$OUTPUT" | grep -q "CRITICAL ERROR"; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  fi

  if echo "$OUTPUT" | grep -q "TROUBLESHOOTING:"; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  fi

  if echo "$OUTPUT" | grep -q "Classification Mode"; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  fi

  if [ $CHECKS_PASSED -eq 3 ]; then
    pass "Error message contains all required components (3/3)"
    return 0
  else
    fail "Error message completeness" "Error message missing components ($CHECKS_PASSED/3 found)"
    return 1
  fi
}

# ==============================================================================
# Test 2: User Can Recover by Switching to regex-only Mode
# ==============================================================================

test_user_can_recover_with_regex_mode() {
  echo "Test 2: User can recover by switching to regex-only mode"

  # Attempt 1: Fail with LLM mode
  export WORKFLOW_CLASSIFICATION_MODE=llm-only
  unset ANTHROPIC_API_KEY

  OUTPUT1=$(bash -c '
    CLAUDE_PROJECT_DIR="'"$PROJECT_ROOT"'"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-scope-detection.sh"

    sm_init "research auth patterns" "coordinate" 2>&1 || echo "ATTEMPT1_FAILED"
  ')

  if ! echo "$OUTPUT1" | grep -q "ATTEMPT1_FAILED"; then
    fail "Recovery test setup" "First attempt should have failed"
    return 1
  fi

  # Attempt 2: Succeed with regex mode (following troubleshooting advice)
  export WORKFLOW_CLASSIFICATION_MODE=regex-only

  OUTPUT2=$(bash -c '
    CLAUDE_PROJECT_DIR="'"$PROJECT_ROOT"'"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-scope-detection.sh"

    sm_init "research auth patterns" "coordinate" 2>&1 && echo "ATTEMPT2_SUCCESS"
  ')

  EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ] && echo "$OUTPUT2" | grep -q "ATTEMPT2_SUCCESS"; then
    pass "User successfully recovered using regex-only mode"
    return 0
  else
    fail "Recovery with regex mode" "Regex mode recovery failed"
    return 1
  fi
}

# ==============================================================================
# Test 3: Error Message Shows Current Mode
# ==============================================================================

test_error_shows_current_mode() {
  echo "Test 3: Error message displays current classification mode"

  # Force failure with explicit mode setting
  export WORKFLOW_CLASSIFICATION_MODE=llm-only
  unset ANTHROPIC_API_KEY

  OUTPUT=$(bash -c '
    CLAUDE_PROJECT_DIR="'"$PROJECT_ROOT"'"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-scope-detection.sh"

    sm_init "test" "coordinate" 2>&1 || true
  ')

  if echo "$OUTPUT" | grep -q "Classification Mode:.*llm-only"; then
    pass "Error message shows current classification mode"
    return 0
  else
    fail "Mode display test" "Current mode not shown in error message"
    return 1
  fi
}

# ==============================================================================
# Test 4: Numbered Troubleshooting Steps Present
# ==============================================================================

test_numbered_troubleshooting_steps() {
  echo "Test 4: Error message includes numbered troubleshooting steps"

  export WORKFLOW_CLASSIFICATION_MODE=llm-only
  unset ANTHROPIC_API_KEY

  OUTPUT=$(bash -c '
    CLAUDE_PROJECT_DIR="'"$PROJECT_ROOT"'"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-scope-detection.sh"

    sm_init "test" "coordinate" 2>&1 || true
  ')

  # Check for numbered steps
  STEP_COUNT=0

  if echo "$OUTPUT" | grep -q "1\..*network"; then
    STEP_COUNT=$((STEP_COUNT + 1))
  fi

  if echo "$OUTPUT" | grep -q "2\..*timeout"; then
    STEP_COUNT=$((STEP_COUNT + 1))
  fi

  if echo "$OUTPUT" | grep -q "3\..*offline.*regex-only"; then
    STEP_COUNT=$((STEP_COUNT + 1))
  fi

  if [ $STEP_COUNT -ge 3 ]; then
    pass "Error message includes numbered troubleshooting steps (found $STEP_COUNT)"
    return 0
  else
    fail "Troubleshooting steps" "Only found $STEP_COUNT numbered steps"
    return 1
  fi
}

# Run tests
test_classification_failure_shows_helpful_error
test_user_can_recover_with_regex_mode
test_error_shows_current_mode
test_numbered_troubleshooting_steps

# Summary
echo ""
echo "=== Test Summary ==="
echo "Tests run: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}✓ All integration tests passed${NC}"
  exit 0
else
  echo -e "${RED}✗ $TESTS_FAILED test(s) failed${NC}"
  exit 1
fi
