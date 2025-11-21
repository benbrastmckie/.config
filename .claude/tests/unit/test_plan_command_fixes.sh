#!/usr/bin/env bash
# Unit tests for /plan command fixes (Phase 1)

set -uo pipefail  # Don't use -e so tests can continue on individual failures

# Test framework setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# CLAUDE_PROJECT_DIR should be /home/benjamin/.config (parent of .claude/)
CLAUDE_PROJECT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
export CLAUDE_PROJECT_DIR

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
pass() {
  echo "  PASS: $1"
  TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
  echo "  FAIL: $1"
  TESTS_FAILED=$((TESTS_FAILED + 1))
}

test_header() {
  echo ""
  echo "TEST: $1"
  echo "----------------------------------------"
}

# ==============================================================================
# Test 1: append_workflow_state Available in Block 1c
# ==============================================================================
test_append_workflow_state_available() {
  test_header "append_workflow_state available after state block sourcing"

  # Mock environment
  export WORKFLOW_ID="test_$RANDOM"
  export COMMAND_NAME="/plan"
  export USER_ARGS="test feature"

  # Simulate Block 1c library sourcing (with new fix)
  if ! source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>&1; then
    fail "Failed to source error-handling.sh"
    return 1
  fi

  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
    fail "Failed to source state-persistence.sh"
    return 1
  }

  source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || {
    fail "Failed to source workflow-initialization.sh"
    return 1
  }

  # Verify append_workflow_state function exists
  if declare -f append_workflow_state >/dev/null 2>&1; then
    pass "append_workflow_state function defined"
  else
    fail "append_workflow_state function not defined after sourcing"
    return 1
  fi

  # Test function can be called
  STATE_FILE="${HOME}/.claude/tmp/state_${WORKFLOW_ID}.sh"
  if init_workflow_state "$WORKFLOW_ID"; then
    pass "init_workflow_state succeeded"
  else
    fail "Cannot initialize workflow state"
    return 1
  fi

  if append_workflow_state "TEST_VAR" "test_value"; then
    pass "append_workflow_state callable"
  else
    fail "Cannot call append_workflow_state"
    rm -f "$STATE_FILE"
    return 1
  fi

  # Verify state persisted
  if grep -q "TEST_VAR=" "$STATE_FILE" 2>/dev/null; then
    pass "State persisted to file"
  else
    fail "State not persisted to file"
    rm -f "$STATE_FILE"
    return 1
  fi

  # Cleanup
  rm -f "$STATE_FILE"
  pass "Test cleanup complete"
}

# ==============================================================================
# Test 2: Agent Output Validation Detects Missing File
# ==============================================================================
test_agent_validation_detects_missing() {
  test_header "Agent output validation detects missing file"

  # Setup
  export COMMAND_NAME="/plan"
  export WORKFLOW_ID="test_$RANDOM"
  export USER_ARGS="test"

  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
    fail "Failed to source error-handling.sh"
    return 1
  }

  ensure_error_log_exists

  # Mock missing agent output file
  local test_file="/tmp/nonexistent_agent_output_$RANDOM.txt"

  # Validate should fail and log error
  if validate_agent_output "test-agent" "$test_file" 1 2>/dev/null; then
    fail "Validation should fail for missing file"
    return 1
  else
    pass "Validation correctly failed for missing file"
  fi

  # Check error log for agent_error
  local error_log="${CLAUDE_PROJECT_DIR}/.claude/data/logs/errors.jsonl"
  if [ -f "$error_log" ]; then
    if grep -q "\"error_type\":\"agent_error\"" "$error_log" 2>/dev/null; then
      pass "Error logged to error log"
    else
      fail "Error not logged to error log"
      return 1
    fi
  else
    fail "Error log not found"
    return 1
  fi

  pass "Test complete"
}

# ==============================================================================
# Test 3: State Variable Validation Detects Missing
# ==============================================================================
test_state_validation_detects_missing() {
  test_header "State validation detects missing variables"

  # Setup
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
    fail "Failed to source state-persistence.sh"
    return 1
  }

  # Set some variables, omit others
  export WORKFLOW_ID="test_123"
  export CLAUDE_PROJECT_DIR_TEST="/test"
  # Intentionally omit FEATURE_DESCRIPTION

  # Validation should fail
  if validate_state_variables "FEATURE_DESCRIPTION" "WORKFLOW_ID" "CLAUDE_PROJECT_DIR_TEST" 2>/dev/null; then
    fail "Should detect missing FEATURE_DESCRIPTION"
    return 1
  else
    pass "Detected missing FEATURE_DESCRIPTION"
  fi

  # Now set all variables
  export FEATURE_DESCRIPTION="test"

  # Validation should pass
  if validate_state_variables "FEATURE_DESCRIPTION" "WORKFLOW_ID" "CLAUDE_PROJECT_DIR_TEST" 2>/dev/null; then
    pass "Validation passed with all variables set"
  else
    fail "Validation failed even with all variables set"
    return 1
  fi

  pass "Test complete"
}

# ==============================================================================
# Test 4: Library Sourcing Helper Works
# ==============================================================================
test_library_sourcing_helper() {
  test_header "Library sourcing helper function works"

  # Source the helper
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/source-libraries.sh" 2>/dev/null || {
    fail "Failed to source source-libraries.sh"
    return 1
  }

  pass "source-libraries.sh sourced successfully"

  # Test sourcing for 'state' block type
  if source_libraries_for_block "state" 2>/dev/null; then
    pass "source_libraries_for_block succeeded for 'state' type"
  else
    fail "source_libraries_for_block failed for 'state' type"
    return 1
  fi

  # Verify required functions are available
  local required_funcs=("log_command_error" "append_workflow_state")
  for func in "${required_funcs[@]}"; do
    if declare -f "$func" >/dev/null 2>&1; then
      pass "Function $func available"
    else
      fail "Function $func not available"
      return 1
    fi
  done

  pass "Test complete"
}

# ==============================================================================
# Run all tests
# ==============================================================================
main() {
  echo "========================================"
  echo "Unit Tests: /plan Command Fixes"
  echo "========================================"

  test_append_workflow_state_available
  test_agent_validation_detects_missing
  test_state_validation_detects_missing
  test_library_sourcing_helper

  echo ""
  echo "========================================"
  echo "TEST RESULTS"
  echo "========================================"
  echo "Passed: $TESTS_PASSED"
  echo "Failed: $TESTS_FAILED"
  echo ""

  if [ $TESTS_FAILED -eq 0 ]; then
    echo "All tests PASSED"
    exit 0
  else
    echo "Some tests FAILED"
    exit 1
  fi
}

main "$@"
