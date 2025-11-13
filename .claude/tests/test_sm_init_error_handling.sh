#!/usr/bin/env bash
# Test sm_init() error handling in coordinate and orchestrate commands
# Spec 698: Error handling fixes for classification failures

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Test suite metadata
TEST_SUITE="sm_init Error Handling"
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
# Test 1: sm_init() Failure Causes Immediate Exit
# ==============================================================================

test_sm_init_failure_exits_immediately() {
  echo "Test 1: sm_init() failure causes immediate exit"

  # Setup: Force classification failure
  export WORKFLOW_CLASSIFICATION_MODE=llm-only
  unset ANTHROPIC_API_KEY

  # Execute sm_init and check it fails
  OUTPUT=$(bash -c '
    set -e
    CLAUDE_PROJECT_DIR="'"$PROJECT_ROOT"'"
    export CLAUDE_PROJECT_DIR

    # Source libraries
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/error-handling.sh"

    # Attempt sm_init (should fail)
    if ! sm_init "test workflow" "coordinate" 2>&1; then
      echo "SM_INIT_FAILED"
      exit 1
    fi

    echo "REACHED_AFTER_SM_INIT"
  ' 2>&1 || true)

  # Verify: Should NOT reach line after sm_init
  if echo "$OUTPUT" | grep -q "REACHED_AFTER_SM_INIT"; then
    fail "sm_init failure test" "Execution continued after sm_init failure"
    return 1
  fi

  # Verify: Error message should be present
  if echo "$OUTPUT" | grep -q "SM_INIT_FAILED"; then
    pass "sm_init failure causes immediate exit"
    return 0
  else
    fail "sm_init failure test" "Error message not found in output"
    return 1
  fi
}

# ==============================================================================
# Test 2: sm_init() Success Exports Required Variables
# ==============================================================================

test_sm_init_success_exports_variables() {
  echo "Test 2: sm_init() success exports required variables"

  # Setup: Use regex-only mode (reliable offline)
  export WORKFLOW_CLASSIFICATION_MODE=regex-only

  # Execute sm_init and check exports
  OUTPUT=$(bash -c '
    set -e
    CLAUDE_PROJECT_DIR="'"$PROJECT_ROOT"'"
    export CLAUDE_PROJECT_DIR

    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-scope-detection.sh"

    # Call sm_init
    sm_init "research authentication patterns" "coordinate"

    # Check exports
    if [ -z "${WORKFLOW_SCOPE:-}" ]; then
      echo "ERROR: WORKFLOW_SCOPE not exported"
      exit 1
    fi

    if [ -z "${RESEARCH_COMPLEXITY:-}" ]; then
      echo "ERROR: RESEARCH_COMPLEXITY not exported"
      exit 1
    fi

    if [ -z "${RESEARCH_TOPICS_JSON:-}" ]; then
      echo "ERROR: RESEARCH_TOPICS_JSON not exported"
      exit 1
    fi

    echo "SUCCESS: All variables exported"
    echo "  WORKFLOW_SCOPE=$WORKFLOW_SCOPE"
    echo "  RESEARCH_COMPLEXITY=$RESEARCH_COMPLEXITY"
  ' 2>&1)

  EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ] && echo "$OUTPUT" | grep -q "SUCCESS: All variables exported"; then
    pass "sm_init success exports all required variables"
    return 0
  else
    fail "sm_init export test" "Variables not exported correctly: $OUTPUT"
    return 1
  fi
}

# ==============================================================================
# Test 3: Verification Checkpoints Detect Missing Exports
# ==============================================================================

test_verification_checkpoints_detect_missing_exports() {
  echo "Test 3: Verification checkpoints detect missing exports"

  # Mock sm_init that returns 0 but doesn't export
  OUTPUT=$(bash -c '
    set -e
    CLAUDE_PROJECT_DIR="'"$PROJECT_ROOT"'"
    export CLAUDE_PROJECT_DIR

    source "${CLAUDE_PROJECT_DIR}/.claude/lib/error-handling.sh"

    # Mock sm_init (returns success without exporting)
    sm_init() {
      return 0
    }

    # Call mock sm_init
    if ! sm_init "test" "coordinate" 2>&1; then
      echo "ERROR: sm_init failed"
      exit 1
    fi

    # Verification checkpoint (should catch missing export)
    if [ -z "${WORKFLOW_SCOPE:-}" ]; then
      echo "CHECKPOINT_CAUGHT_MISSING_EXPORT"
      exit 1
    fi

    echo "CHECKPOINT_MISSED_ISSUE"
  ' 2>&1 || true)

  if echo "$OUTPUT" | grep -q "CHECKPOINT_CAUGHT_MISSING_EXPORT"; then
    pass "Verification checkpoint catches missing export"
    return 0
  else
    fail "Verification checkpoint test" "Checkpoint did not catch missing export"
    return 1
  fi
}

# ==============================================================================
# Test 4: Error Messages Include Troubleshooting Steps
# ==============================================================================

test_error_messages_include_troubleshooting() {
  echo "Test 4: Error messages include troubleshooting steps"

  # Setup: Force classification failure
  export WORKFLOW_CLASSIFICATION_MODE=llm-only
  unset ANTHROPIC_API_KEY

  # Attempt classification
  OUTPUT=$(bash -c '
    set -e
    CLAUDE_PROJECT_DIR="'"$PROJECT_ROOT"'"
    export CLAUDE_PROJECT_DIR

    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-scope-detection.sh"

    sm_init "test workflow" "coordinate"
  ' 2>&1 || true)

  # Verify error message contains troubleshooting section
  if echo "$OUTPUT" | grep -q "TROUBLESHOOTING:"; then
    pass "Error message includes troubleshooting steps"
    return 0
  else
    fail "Error message test" "Error message missing TROUBLESHOOTING section"
    return 1
  fi
}

# ==============================================================================
# Test 5: Offline Mode (regex-only) Works Without Network
# ==============================================================================

test_offline_mode_works_without_network() {
  echo "Test 5: Offline mode (regex-only) works without network"

  # Setup: Use regex-only mode, no API key
  export WORKFLOW_CLASSIFICATION_MODE=regex-only
  unset ANTHROPIC_API_KEY

  # Execute classification
  OUTPUT=$(bash -c '
    set -e
    CLAUDE_PROJECT_DIR="'"$PROJECT_ROOT"'"
    export CLAUDE_PROJECT_DIR

    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-scope-detection.sh"

    sm_init "research authentication patterns" "coordinate"

    echo "CLASSIFICATION_SUCCESS: WORKFLOW_SCOPE=$WORKFLOW_SCOPE"
  ' 2>&1)

  EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ] && echo "$OUTPUT" | grep -q "CLASSIFICATION_SUCCESS"; then
    pass "Regex-only mode works without network"
    return 0
  else
    fail "Offline mode test" "Regex-only mode failed: $OUTPUT"
    return 1
  fi
}

# ==============================================================================
# Test 6: Classification Mode Shown in Error Message
# ==============================================================================

test_classification_mode_shown_in_error() {
  echo "Test 6: Classification mode shown in error message"

  # Setup: Force classification failure
  export WORKFLOW_CLASSIFICATION_MODE=llm-only
  unset ANTHROPIC_API_KEY

  # Attempt classification
  OUTPUT=$(bash -c '
    set -e
    CLAUDE_PROJECT_DIR="'"$PROJECT_ROOT"'"
    export CLAUDE_PROJECT_DIR

    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-scope-detection.sh"

    sm_init "test workflow" "coordinate"
  ' 2>&1 || true)

  # Verify error message shows classification mode
  if echo "$OUTPUT" | grep -q "Classification Mode:.*llm-only"; then
    pass "Error message shows classification mode"
    return 0
  else
    fail "Classification mode display test" "Classification mode not shown in error"
    return 1
  fi
}

# ==============================================================================
# Run All Tests
# ==============================================================================

test_sm_init_failure_exits_immediately
test_sm_init_success_exports_variables
test_verification_checkpoints_detect_missing_exports
test_error_messages_include_troubleshooting
test_offline_mode_works_without_network
test_classification_mode_shown_in_error

# Print summary
echo ""
echo "=== Test Summary ==="
echo "Tests run: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}✓ All tests passed${NC}"
  exit 0
else
  echo -e "${RED}✗ $TESTS_FAILED test(s) failed${NC}"
  exit 1
fi
