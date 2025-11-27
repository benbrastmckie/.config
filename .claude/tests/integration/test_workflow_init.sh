#!/usr/bin/env bash
# test_workflow_init.sh - Unit tests for workflow-init.sh library
#
# Tests the consolidated initialization library functions:
# - init_workflow()
# - load_workflow_context()
# - finalize_workflow()
# - workflow_error()

set -uo pipefail

# Get script directory for relative paths
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
PROJECT_ROOT="$CLAUDE_PROJECT_DIR"
CLAUDE_ROOT="${CLAUDE_PROJECT_DIR}/.claude"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test helper functions
pass() {
  ((TESTS_PASSED++))
  echo -e "${GREEN}PASS${NC}: $1"
}

fail() {
  ((TESTS_FAILED++))
  echo -e "${RED}FAIL${NC}: $1"
  [ -n "${2:-}" ] && echo "  Details: $2"
}

run_test() {
  local test_name="$1"
  ((TESTS_RUN++))
  echo -n "Running: $test_name... "
}

# ==============================================================================
# Setup and Teardown
# ==============================================================================

setup() {
  # Create temporary test directory
  TEST_TMP="${TMPDIR:-/tmp}/workflow_init_test_$$"
  mkdir -p "$TEST_TMP"

  # Clear any existing state files
  rm -f "${HOME}/.claude/tmp/test_*" 2>/dev/null || true

  # Set CLAUDE_PROJECT_DIR for testing
  export CLAUDE_PROJECT_DIR="$PROJECT_ROOT"
}

teardown() {
  # Clean up test artifacts
  rm -rf "$TEST_TMP" 2>/dev/null || true
  rm -f "${HOME}/.claude/tmp/test_*" 2>/dev/null || true
}

# ==============================================================================
# Test Cases
# ==============================================================================

test_library_sourcing() {
  run_test "Library can be sourced without errors"

  # Source in subshell to avoid polluting test environment
  if (source "$PROJECT_ROOT/.claude/lib/workflow/workflow-init.sh" 2>&1); then
    pass "Library sourced successfully"
  else
    fail "Library sourcing failed"
  fi
}

test_source_guard() {
  run_test "Source guard prevents duplicate sourcing"

  # Source twice and check it doesn't error
  if (
    source "$PROJECT_ROOT/.claude/lib/workflow/workflow-init.sh"
    source "$PROJECT_ROOT/.claude/lib/workflow/workflow-init.sh"
    [ "$WORKFLOW_INIT_VERSION" = "1.0.0" ]
  ); then
    pass "Source guard works correctly"
  else
    fail "Source guard failed"
  fi
}

test_init_workflow_creates_state() {
  run_test "init_workflow creates WORKFLOW_ID and STATE_FILE"

  local output
  output=$(
    source "$PROJECT_ROOT/.claude/lib/workflow/workflow-init.sh"
    init_workflow "test" "test description" "research-only" 2
    echo "WORKFLOW_ID=$WORKFLOW_ID"
    echo "STATE_FILE=$STATE_FILE"
  )

  if echo "$output" | grep -q "WORKFLOW_ID=test_"; then
    if echo "$output" | grep -q "STATE_FILE="; then
      pass "WORKFLOW_ID and STATE_FILE created"
    else
      fail "STATE_FILE not set" "$output"
    fi
  else
    fail "WORKFLOW_ID not set" "$output"
  fi
}

test_init_workflow_summary_line() {
  run_test "init_workflow outputs single summary line"

  local output
  output=$(
    source "$PROJECT_ROOT/.claude/lib/workflow/workflow-init.sh"
    init_workflow "test" "test description" "research-only" 2 2>&1
  )

  if echo "$output" | grep -q "Setup complete: test_"; then
    pass "Summary line output correctly"
  else
    fail "Expected 'Setup complete' summary line" "$output"
  fi
}

test_init_workflow_missing_args() {
  run_test "init_workflow fails with missing arguments"

  local exit_code=0
  (
    source "$PROJECT_ROOT/.claude/lib/workflow/workflow-init.sh"
    init_workflow "" "" 2>/dev/null
  ) || exit_code=$?

  if [ $exit_code -ne 0 ]; then
    pass "Correctly fails with missing arguments"
  else
    fail "Should fail with missing arguments"
  fi
}

test_init_workflow_state_id_file() {
  run_test "init_workflow creates state ID file for subprocess recovery"

  (
    source "$PROJECT_ROOT/.claude/lib/workflow/workflow-init.sh"
    init_workflow "testcmd" "test description" "research-only" 2
  ) >/dev/null 2>&1

  local state_id_file="${HOME}/.claude/tmp/testcmd_state_id.txt"

  if [ -f "$state_id_file" ]; then
    local workflow_id
    workflow_id=$(cat "$state_id_file")
    if [[ "$workflow_id" == testcmd_* ]]; then
      pass "State ID file created correctly"
    else
      fail "State ID file has wrong content" "$workflow_id"
    fi
    rm -f "$state_id_file"
  else
    fail "State ID file not created" "$state_id_file"
  fi
}

test_load_workflow_context() {
  run_test "load_workflow_context restores state from previous init"

  # Initialize workflow
  (
    source "$PROJECT_ROOT/.claude/lib/workflow/workflow-init.sh"
    init_workflow "loadtest" "test description" "research-only" 2
  ) >/dev/null 2>&1

  # Load context in new subshell
  local output
  output=$(
    source "$PROJECT_ROOT/.claude/lib/workflow/workflow-init.sh"
    load_workflow_context "loadtest"
    echo "WORKFLOW_ID=$WORKFLOW_ID"
    echo "CLAUDE_PROJECT_DIR=$CLAUDE_PROJECT_DIR"
  )

  if echo "$output" | grep -q "WORKFLOW_ID=loadtest_"; then
    pass "load_workflow_context restored state"
  else
    fail "Failed to restore WORKFLOW_ID" "$output"
  fi

  # Cleanup
  rm -f "${HOME}/.claude/tmp/loadtest_state_id.txt"
}

test_load_workflow_context_missing_state() {
  run_test "load_workflow_context fails gracefully with missing state"

  local exit_code=0
  (
    source "$PROJECT_ROOT/.claude/lib/workflow/workflow-init.sh"
    load_workflow_context "nonexistent" 2>/dev/null
  ) || exit_code=$?

  if [ $exit_code -ne 0 ]; then
    pass "Correctly fails with missing state"
  else
    fail "Should fail with missing state"
  fi
}

test_workflow_error_output() {
  run_test "workflow_error outputs formatted error message"

  local output
  output=$(
    source "$PROJECT_ROOT/.claude/lib/workflow/workflow-init.sh"
    workflow_error "Test error" "Test diagnostic" 2>&1
  )

  if echo "$output" | grep -q "ERROR: Test error"; then
    if echo "$output" | grep -q "DIAGNOSTIC: Test diagnostic"; then
      pass "Error message formatted correctly"
    else
      fail "Missing DIAGNOSTIC in output" "$output"
    fi
  else
    fail "Missing ERROR in output" "$output"
  fi
}

test_exports_available() {
  run_test "Functions are exported correctly"

  local output
  output=$(
    source "$PROJECT_ROOT/.claude/lib/workflow/workflow-init.sh"
    declare -F | grep -E "init_workflow|load_workflow_context|finalize_workflow|workflow_error" | wc -l
  )

  if [ "$output" -ge 4 ]; then
    pass "All functions exported"
  else
    fail "Expected 4 exported functions, got $output"
  fi
}

test_debug_log_creation() {
  run_test "Debug log is created during init"

  (
    source "$PROJECT_ROOT/.claude/lib/workflow/workflow-init.sh"
    init_workflow "debugtest" "test description" "research-only" 2
  ) >/dev/null 2>&1

  local debug_log="${HOME}/.claude/tmp/workflow_debug.log"

  if [ -f "$debug_log" ]; then
    if grep -q "init_workflow: debugtest" "$debug_log"; then
      pass "Debug log contains init entry"
    else
      fail "Debug log missing init entry"
    fi
  else
    fail "Debug log not created"
  fi

  # Cleanup
  rm -f "${HOME}/.claude/tmp/debugtest_state_id.txt"
}

test_workflow_type_default() {
  run_test "init_workflow uses full-implementation as default workflow type"

  local output
  output=$(
    source "$PROJECT_ROOT/.claude/lib/workflow/workflow-init.sh"
    # Call without workflow_type argument
    init_workflow "defaulttest" "test description" 2>&1
  )

  # Check the summary line contains the default
  if echo "$output" | grep -q "full-implementation"; then
    pass "Default workflow type is full-implementation"
  else
    fail "Expected full-implementation as default" "$output"
  fi

  # Cleanup
  rm -f "${HOME}/.claude/tmp/defaulttest_state_id.txt"
}

test_complexity_default() {
  run_test "init_workflow uses 2 as default complexity"

  local output
  output=$(
    source "$PROJECT_ROOT/.claude/lib/workflow/workflow-init.sh"
    init_workflow "complextest" "test description" "research-only" 2>&1
  )

  if echo "$output" | grep -q "complexity: 2"; then
    pass "Default complexity is 2"
  else
    fail "Expected complexity 2" "$output"
  fi

  # Cleanup
  rm -f "${HOME}/.claude/tmp/complextest_state_id.txt"
}

test_state_persistence_variables() {
  run_test "init_workflow persists variables to state file"

  # Initialize workflow
  (
    source "$PROJECT_ROOT/.claude/lib/workflow/workflow-init.sh"
    init_workflow "persisttest" "my test workflow" "research-only" 3
  ) >/dev/null 2>&1

  # Check state file contains expected variables
  local state_id
  state_id=$(cat "${HOME}/.claude/tmp/persisttest_state_id.txt" 2>/dev/null)
  local state_file="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${state_id}.sh"

  if [ -f "$state_file" ]; then
    local check_count=0
    grep -q "CLAUDE_PROJECT_DIR" "$state_file" && ((check_count++))
    grep -q "WORKFLOW_DESCRIPTION" "$state_file" && ((check_count++))
    grep -q "WORKFLOW_TYPE" "$state_file" && ((check_count++))
    grep -q "COMMAND_NAME" "$state_file" && ((check_count++))

    if [ $check_count -ge 4 ]; then
      pass "All critical variables persisted to state file"
    else
      fail "Only $check_count/4 variables found in state file"
    fi

    rm -f "$state_file"
  else
    fail "State file not found: $state_file"
  fi

  # Cleanup
  rm -f "${HOME}/.claude/tmp/persisttest_state_id.txt"
}

# ==============================================================================
# Main Test Runner
# ==============================================================================

main() {
  echo "====================================="
  echo "workflow-init.sh Unit Tests"
  echo "====================================="
  echo ""

  setup

  # Run all tests
  test_library_sourcing
  test_source_guard
  test_init_workflow_creates_state
  test_init_workflow_summary_line
  test_init_workflow_missing_args
  test_init_workflow_state_id_file
  test_load_workflow_context
  test_load_workflow_context_missing_state
  test_workflow_error_output
  test_exports_available
  test_debug_log_creation
  test_workflow_type_default
  test_complexity_default
  test_state_persistence_variables

  teardown

  # Summary
  echo ""
  echo "====================================="
  echo "Test Summary"
  echo "====================================="
  echo "Total:  $TESTS_RUN"
  echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
  echo -e "Failed: ${RED}$TESTS_FAILED${NC}"

  if [ $TESTS_FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
  else
    echo ""
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
  fi
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi
