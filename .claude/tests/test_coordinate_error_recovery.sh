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

  # Force LLM classification failure by unsetting API key and TEST_MODE
  unset ANTHROPIC_API_KEY
  unset WORKFLOW_CLASSIFICATION_TEST_MODE

  # Simulate the error path
  OUTPUT=$(bash -c '
    unset WORKFLOW_CLASSIFICATION_TEST_MODE
    unset ANTHROPIC_API_KEY
    CLAUDE_PROJECT_DIR="'"$PROJECT_ROOT"'"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-scope-detection.sh"

    sm_init "test workflow" "coordinate" 2>&1 || true
  ')

  # Verify error message components (LLM-only architecture)
  CHECKS_PASSED=0

  if echo "$OUTPUT" | grep -q "CRITICAL ERROR"; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  fi

  if echo "$OUTPUT" | grep -q "TROUBLESHOOTING:"; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  fi

  # Check for helpful troubleshooting steps
  if echo "$OUTPUT" | grep -q "Check network connection"; then
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
# Test 2: Fail-Fast Behavior Without API Access
# ==============================================================================

test_fail_fast_behavior_without_api() {
  echo "Test 2: Fail-fast behavior when API is unavailable"

  # Remove API key and TEST_MODE to simulate offline scenario
  unset ANTHROPIC_API_KEY
  unset WORKFLOW_CLASSIFICATION_TEST_MODE

  # Attempt classification without API access
  set +e
  OUTPUT=$(bash -c '
    unset WORKFLOW_CLASSIFICATION_TEST_MODE
    unset ANTHROPIC_API_KEY
    CLAUDE_PROJECT_DIR="'"$PROJECT_ROOT"'"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-scope-detection.sh"

    sm_init "research auth patterns" "coordinate" 2>&1
  ')
  EXIT_CODE=$?
  set -e

  # Verify fail-fast behavior (non-zero exit code)
  if [ $EXIT_CODE -ne 0 ]; then
    pass "Fail-fast behavior: Classification fails immediately without API (exit code: $EXIT_CODE)"
    return 0
  else
    fail "Fail-fast behavior" "Should have failed without API access (exit code: $EXIT_CODE)"
    return 1
  fi
}

# ==============================================================================
# Test 3: Error Message Provides Actionable Suggestions
# ==============================================================================

test_error_provides_actionable_suggestions() {
  echo "Test 3: Error message provides actionable suggestions"

  # Force failure by unsetting API key and TEST_MODE
  unset ANTHROPIC_API_KEY
  unset WORKFLOW_CLASSIFICATION_TEST_MODE

  OUTPUT=$(bash -c '
    unset WORKFLOW_CLASSIFICATION_TEST_MODE
    unset ANTHROPIC_API_KEY
    CLAUDE_PROJECT_DIR="'"$PROJECT_ROOT"'"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-scope-detection.sh"

    sm_init "test" "coordinate" 2>&1 || true
  ')

  # Check for actionable suggestions
  CHECKS_PASSED=0

  if echo "$OUTPUT" | grep -q "Suggestion:"; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  fi

  if echo "$OUTPUT" | grep -q "Alternative:"; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  fi

  if [ $CHECKS_PASSED -ge 1 ]; then
    pass "Error message provides actionable suggestions ($CHECKS_PASSED found)"
    return 0
  else
    fail "Actionable suggestions" "No suggestions found in error message"
    return 1
  fi
}

# ==============================================================================
# Test 4: Numbered Troubleshooting Steps Present
# ==============================================================================

test_numbered_troubleshooting_steps() {
  echo "Test 4: Error message includes numbered troubleshooting steps"

  unset ANTHROPIC_API_KEY
  unset WORKFLOW_CLASSIFICATION_TEST_MODE

  OUTPUT=$(bash -c '
    unset WORKFLOW_CLASSIFICATION_TEST_MODE
    unset ANTHROPIC_API_KEY
    CLAUDE_PROJECT_DIR="'"$PROJECT_ROOT"'"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-scope-detection.sh"

    sm_init "test" "coordinate" 2>&1 || true
  ')

  # Check for numbered steps (LLM-only architecture)
  STEP_COUNT=0

  if echo "$OUTPUT" | grep -qE "1\..*network"; then
    STEP_COUNT=$((STEP_COUNT + 1))
  fi

  if echo "$OUTPUT" | grep -qE "2\..*timeout"; then
    STEP_COUNT=$((STEP_COUNT + 1))
  fi

  if echo "$OUTPUT" | grep -qE "[34]\."; then
    STEP_COUNT=$((STEP_COUNT + 1))
  fi

  if [ $STEP_COUNT -ge 3 ]; then
    pass "Error message includes numbered troubleshooting steps (found $STEP_COUNT)"
    return 0
  else
    fail "Troubleshooting steps" "Only found $STEP_COUNT numbered steps (need 3+)"
    return 1
  fi
}

# Run tests
test_classification_failure_shows_helpful_error
test_fail_fast_behavior_without_api
test_error_provides_actionable_suggestions
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
