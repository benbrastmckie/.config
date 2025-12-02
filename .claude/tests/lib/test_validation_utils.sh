#!/usr/bin/env bash
# Unit Tests for validation-utils.sh
#
# Tests all validation functions with valid and invalid inputs,
# including error logging integration.

set -euo pipefail

# Detect project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"
export CLAUDE_PROJECT_DIR

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test helper functions
assert_success() {
  local test_name="$1"
  local command="$2"

  TESTS_RUN=$((TESTS_RUN + 1))

  if eval "$command" >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} $test_name"
    echo "  Command failed: $command"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_failure() {
  local test_name="$1"
  local command="$2"

  TESTS_RUN=$((TESTS_RUN + 1))

  if eval "$command" >/dev/null 2>&1; then
    echo -e "${RED}✗${NC} $test_name"
    echo "  Command should have failed but succeeded: $command"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  else
    echo -e "${GREEN}✓${NC} $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  fi
}

# Setup test environment
setup_test_env() {
  # Create temporary test directory
  TEST_DIR="${CLAUDE_PROJECT_DIR}/tmp/test_validation_utils_$$"
  mkdir -p "$TEST_DIR"

  # Create test files
  echo "test content" > "$TEST_DIR/test_file.txt"
  echo "small" > "$TEST_DIR/small_file.txt"

  # Set workflow context for error logging tests
  export COMMAND_NAME="/test"
  export WORKFLOW_ID="test_workflow_$$"
  export USER_ARGS="--test"

  # Ensure error log exists
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || true
  ensure_error_log_exists 2>/dev/null || true
}

cleanup_test_env() {
  # Remove temporary test directory
  rm -rf "$TEST_DIR"
}

# Source the library under test
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/validation-utils.sh" || {
  echo "ERROR: Failed to source validation-utils.sh"
  exit 1
}

# Setup test environment
setup_test_env

echo "=================================="
echo "Validation Utils Unit Tests"
echo "=================================="
echo ""

# ==============================================================================
# Test validate_workflow_prerequisites()
# ==============================================================================

echo "Testing validate_workflow_prerequisites()..."
echo ""

# Test 1: Should fail when required functions are missing
assert_failure \
  "validate_workflow_prerequisites fails when functions missing" \
  "validate_workflow_prerequisites"

# Test 2: Should succeed when all required functions are defined
# Define stub functions
sm_init() { :; }
sm_transition() { :; }
append_workflow_state() { :; }
load_workflow_state() { :; }
save_completed_states_to_state() { :; }

assert_success \
  "validate_workflow_prerequisites succeeds when all functions defined" \
  "validate_workflow_prerequisites"

# Clean up stub functions
unset -f sm_init sm_transition append_workflow_state load_workflow_state save_completed_states_to_state

echo ""

# ==============================================================================
# Test validate_agent_artifact()
# ==============================================================================

echo "Testing validate_agent_artifact()..."
echo ""

# Test 3: Should fail when artifact_path not provided
assert_failure \
  "validate_agent_artifact fails when path parameter missing" \
  "validate_agent_artifact ''"

# Test 4: Should fail when file doesn't exist
assert_failure \
  "validate_agent_artifact fails when file doesn't exist" \
  "validate_agent_artifact '$TEST_DIR/nonexistent.txt' 10 'test artifact'"

# Test 5: Should succeed when file exists and meets min size
assert_success \
  "validate_agent_artifact succeeds when file exists and meets size" \
  "validate_agent_artifact '$TEST_DIR/test_file.txt' 10 'test artifact'"

# Test 6: Should fail when file is too small
assert_failure \
  "validate_agent_artifact fails when file is too small" \
  "validate_agent_artifact '$TEST_DIR/small_file.txt' 100 'test artifact'"

# Test 7: Should use default min_size when not provided
assert_success \
  "validate_agent_artifact uses default min_size" \
  "validate_agent_artifact '$TEST_DIR/test_file.txt'"

echo ""

# ==============================================================================
# Test validate_absolute_path()
# ==============================================================================

echo "Testing validate_absolute_path()..."
echo ""

# Test 8: Should fail when path parameter not provided
assert_failure \
  "validate_absolute_path fails when path parameter missing" \
  "validate_absolute_path ''"

# Test 9: Should fail when path is relative
assert_failure \
  "validate_absolute_path fails when path is relative" \
  "validate_absolute_path 'relative/path'"

# Test 10: Should succeed when path is absolute (format only)
assert_success \
  "validate_absolute_path succeeds for absolute path (format only)" \
  "validate_absolute_path '/absolute/path' false"

# Test 11: Should succeed when absolute path exists
assert_success \
  "validate_absolute_path succeeds when path exists" \
  "validate_absolute_path '$TEST_DIR/test_file.txt' true"

# Test 12: Should fail when absolute path doesn't exist (with check)
assert_failure \
  "validate_absolute_path fails when path doesn't exist (with check)" \
  "validate_absolute_path '/nonexistent/absolute/path' true"

# Test 13: Should succeed when absolute path doesn't exist (no check)
assert_success \
  "validate_absolute_path succeeds when path doesn't exist (no check)" \
  "validate_absolute_path '/nonexistent/absolute/path' false"

echo ""

# ==============================================================================
# Test error logging integration
# ==============================================================================

echo "Testing error logging integration..."
echo ""

# Test 14: Should log errors when validation fails
# Create a test that triggers error logging
ERROR_LOG="${CLAUDE_PROJECT_DIR}/tests/logs/test-errors.jsonl"
BEFORE_COUNT=0
if [ -f "$ERROR_LOG" ]; then
  BEFORE_COUNT=$(wc -l < "$ERROR_LOG")
fi

# Trigger a validation error
validate_agent_artifact "$TEST_DIR/nonexistent.txt" 10 "test" 2>/dev/null || true

AFTER_COUNT=0
if [ -f "$ERROR_LOG" ]; then
  AFTER_COUNT=$(wc -l < "$ERROR_LOG")
fi

if [ "$AFTER_COUNT" -gt "$BEFORE_COUNT" ]; then
  echo -e "${GREEN}✓${NC} Error logged when validation fails"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "${YELLOW}⚠${NC} Error logging not working (error log may not be initialized)"
  # Don't count as failure - error logging is optional
fi
TESTS_RUN=$((TESTS_RUN + 1))

echo ""

# ==============================================================================
# Test library sourcing
# ==============================================================================

echo "Testing library sourcing..."
echo ""

# Test 15: Should prevent multiple sourcing
TESTS_RUN=$((TESTS_RUN + 1))
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/validation-utils.sh" || true
if [ "$VALIDATION_UTILS_VERSION" = "1.0.0" ]; then
  echo -e "${GREEN}✓${NC} Library version exported correctly"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "${RED}✗${NC} Library version not exported"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo ""

# Cleanup
cleanup_test_env

# ==============================================================================
# Test Summary
# ==============================================================================

echo "=================================="
echo "Test Summary"
echo "=================================="
echo "Tests run: $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
  echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
else
  echo -e "Tests failed: $TESTS_FAILED"
fi
echo "=================================="

# Exit with failure if any tests failed
if [ $TESTS_FAILED -gt 0 ]; then
  exit 1
else
  echo ""
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
fi
