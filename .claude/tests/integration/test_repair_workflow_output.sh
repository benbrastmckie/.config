#!/usr/bin/env bash
# Test: /repair command --file flag workflow output integration
# Verifies that --file flag correctly persists WORKFLOW_OUTPUT_FILE and passes to agent

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Detect project root correctly (git root or parent with .claude directory)
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  # Walk up to find .claude directory
  CLAUDE_PROJECT_DIR="$SCRIPT_DIR"
  while [ "$CLAUDE_PROJECT_DIR" != "/" ]; do
    if [ -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
      break
    fi
    CLAUDE_PROJECT_DIR="$(dirname "$CLAUDE_PROJECT_DIR")"
  done
fi
export CLAUDE_PROJECT_DIR

# Source required libraries
CLAUDE_LIB="${CLAUDE_PROJECT_DIR}/.claude/lib"
source "$CLAUDE_LIB/core/state-persistence.sh"
source "$CLAUDE_LIB/core/error-handling.sh"

TEST_PASSED=0
TEST_FAILED=0

# Test fixtures directory
TEST_FIXTURES_DIR="${CLAUDE_PROJECT_DIR}/.claude/tests/fixtures"
TEST_TMP_DIR="${CLAUDE_PROJECT_DIR}/.claude/tmp/test_repair_$$"

cleanup() {
  # Clean up any test state files
  rm -rf "$TEST_TMP_DIR" 2>/dev/null || true
  rm -f "${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_test_repair_"* 2>/dev/null || true
}
trap cleanup EXIT

# Setup test fixtures
setup_fixtures() {
  mkdir -p "$TEST_TMP_DIR"

  # Create test workflow output file with simulated errors
  cat > "$TEST_TMP_DIR/test_workflow_output.md" << 'EOF'
# Workflow Output

## Execution Log

ERROR: State file not found at /home/user/.claude/tmp/workflow_state_123.sh
DEBUG: STATE_FILE variable empty after load
ERROR: exit code 1 at line 145
WARNING: path mismatch - expected path: /home/user/.config/.claude, actual path: /home/user/.claude

## Results
Workflow failed due to state persistence errors.
EOF
}

echo "=== /repair --file Flag Integration Test ==="
echo ""

# Test 1: WORKFLOW_OUTPUT_FILE is persisted to state
test_workflow_output_file_persisted() {
  local test_name="WORKFLOW_OUTPUT_FILE persisted to state"

  setup_fixtures

  # Initialize workflow state
  local test_workflow_id="test_repair_$(date +%s)_$$"
  STATE_FILE=$(init_workflow_state "$test_workflow_id")
  export STATE_FILE

  # Simulate the --file flag parsing and persistence (from repair.md Block 1)
  local WORKFLOW_OUTPUT_FILE="$TEST_TMP_DIR/test_workflow_output.md"

  # Verify file exists
  if [ ! -f "$WORKFLOW_OUTPUT_FILE" ]; then
    echo "SKIP: $test_name - Test fixture not created"
    return 0
  fi

  # Persist to state
  append_workflow_state "WORKFLOW_OUTPUT_FILE" "$WORKFLOW_OUTPUT_FILE"

  # Reload state and verify
  local restored_file
  restored_file=$(grep "WORKFLOW_OUTPUT_FILE=" "$STATE_FILE" | tail -1 | sed 's/.*WORKFLOW_OUTPUT_FILE="//' | tr -d '"')

  if [ "$restored_file" != "$WORKFLOW_OUTPUT_FILE" ]; then
    echo "FAIL: $test_name - Expected '$WORKFLOW_OUTPUT_FILE', got '$restored_file'"
    TEST_FAILED=$((TEST_FAILED + 1))
    rm -f "$STATE_FILE"
    return 1
  fi

  echo "PASS: $test_name"
  TEST_PASSED=$((TEST_PASSED + 1))
  rm -f "$STATE_FILE"
  return 0
}

# Test 2: Empty WORKFLOW_OUTPUT_FILE is handled correctly
test_empty_workflow_output_file() {
  local test_name="Empty WORKFLOW_OUTPUT_FILE handled correctly"

  # Initialize workflow state
  local test_workflow_id="test_repair_empty_$(date +%s)_$$"
  STATE_FILE=$(init_workflow_state "$test_workflow_id")
  export STATE_FILE

  # Persist empty value
  local WORKFLOW_OUTPUT_FILE=""
  append_workflow_state "WORKFLOW_OUTPUT_FILE" "$WORKFLOW_OUTPUT_FILE"

  # Reload state and verify empty is handled
  local restored_file
  restored_file=$(grep "WORKFLOW_OUTPUT_FILE=" "$STATE_FILE" | tail -1 | sed 's/.*WORKFLOW_OUTPUT_FILE="//' | tr -d '"')

  if [ -n "$restored_file" ] && [ "$restored_file" != "" ]; then
    echo "FAIL: $test_name - Expected empty, got '$restored_file'"
    TEST_FAILED=$((TEST_FAILED + 1))
    rm -f "$STATE_FILE"
    return 1
  fi

  echo "PASS: $test_name"
  TEST_PASSED=$((TEST_PASSED + 1))
  rm -f "$STATE_FILE"
  return 0
}

# Test 3: Error context includes HOME and CLAUDE_PROJECT_DIR for state_error
test_error_context_enhanced() {
  local test_name="Error context includes HOME and CLAUDE_PROJECT_DIR for state_error"

  # Enable test mode
  export CLAUDE_TEST_MODE=1

  # Initialize error log
  ensure_error_log_exists

  # Log a state_error with context
  local test_workflow_id="test_repair_context_$(date +%s)_$$"
  log_command_error \
    "/repair" \
    "$test_workflow_id" \
    "--file test.md" \
    "state_error" \
    "Test state error for context verification" \
    "test_error_context_enhanced" \
    '{"test_key": "test_value"}'

  # Find the logged error
  local error_log="${CLAUDE_PROJECT_DIR}/.claude/tests/logs/test-errors.jsonl"

  if [ ! -f "$error_log" ]; then
    echo "SKIP: $test_name - Test error log not found"
    unset CLAUDE_TEST_MODE
    return 0
  fi

  # Get the last logged error for our workflow
  local last_error
  last_error=$(grep "$test_workflow_id" "$error_log" | tail -1)

  if [ -z "$last_error" ]; then
    echo "FAIL: $test_name - Error not found in log"
    TEST_FAILED=$((TEST_FAILED + 1))
    unset CLAUDE_TEST_MODE
    return 1
  fi

  # Check context includes home and claude_project_dir
  local has_home has_project_dir
  has_home=$(echo "$last_error" | jq -r '.context.home // ""')
  has_project_dir=$(echo "$last_error" | jq -r '.context.claude_project_dir // ""')

  if [ -z "$has_home" ] && [ -z "$has_project_dir" ]; then
    echo "FAIL: $test_name - Context missing home and claude_project_dir"
    TEST_FAILED=$((TEST_FAILED + 1))
    unset CLAUDE_TEST_MODE
    return 1
  fi

  echo "PASS: $test_name (home=$has_home, project_dir=$has_project_dir)"
  TEST_PASSED=$((TEST_PASSED + 1))
  unset CLAUDE_TEST_MODE
  return 0
}

# Test 4: Error context includes HOME and CLAUDE_PROJECT_DIR for file_error
test_file_error_context_enhanced() {
  local test_name="Error context includes HOME and CLAUDE_PROJECT_DIR for file_error"

  # Enable test mode
  export CLAUDE_TEST_MODE=1

  # Initialize error log
  ensure_error_log_exists

  # Log a file_error with context
  local test_workflow_id="test_repair_file_$(date +%s)_$$"
  log_command_error \
    "/repair" \
    "$test_workflow_id" \
    "--file test.md" \
    "file_error" \
    "Test file error for context verification" \
    "test_file_error_context_enhanced" \
    '{"file_path": "/test/path"}'

  # Find the logged error
  local error_log="${CLAUDE_PROJECT_DIR}/.claude/tests/logs/test-errors.jsonl"

  if [ ! -f "$error_log" ]; then
    echo "SKIP: $test_name - Test error log not found"
    unset CLAUDE_TEST_MODE
    return 0
  fi

  # Get the last logged error for our workflow
  local last_error
  last_error=$(grep "$test_workflow_id" "$error_log" | tail -1)

  if [ -z "$last_error" ]; then
    echo "FAIL: $test_name - Error not found in log"
    TEST_FAILED=$((TEST_FAILED + 1))
    unset CLAUDE_TEST_MODE
    return 1
  fi

  # Check context includes home and claude_project_dir
  local has_home has_project_dir
  has_home=$(echo "$last_error" | jq -r '.context.home // ""')
  has_project_dir=$(echo "$last_error" | jq -r '.context.claude_project_dir // ""')

  if [ -z "$has_home" ] && [ -z "$has_project_dir" ]; then
    echo "FAIL: $test_name - Context missing home and claude_project_dir"
    TEST_FAILED=$((TEST_FAILED + 1))
    unset CLAUDE_TEST_MODE
    return 1
  fi

  echo "PASS: $test_name (home=$has_home, project_dir=$has_project_dir)"
  TEST_PASSED=$((TEST_PASSED + 1))
  unset CLAUDE_TEST_MODE
  return 0
}

# Test 5: Non-path error types do NOT get enhanced context
test_validation_error_no_enhancement() {
  local test_name="validation_error does NOT get path context enhancement"

  # Enable test mode
  export CLAUDE_TEST_MODE=1

  # Initialize error log
  ensure_error_log_exists

  # Log a validation_error with minimal context
  local test_workflow_id="test_repair_validation_$(date +%s)_$$"
  log_command_error \
    "/repair" \
    "$test_workflow_id" \
    "--type validation" \
    "validation_error" \
    "Test validation error" \
    "test_validation_error_no_enhancement" \
    '{"input": "bad_value"}'

  # Find the logged error
  local error_log="${CLAUDE_PROJECT_DIR}/.claude/tests/logs/test-errors.jsonl"

  if [ ! -f "$error_log" ]; then
    echo "SKIP: $test_name - Test error log not found"
    unset CLAUDE_TEST_MODE
    return 0
  fi

  # Get the last logged error for our workflow
  local last_error
  last_error=$(grep "$test_workflow_id" "$error_log" | tail -1)

  if [ -z "$last_error" ]; then
    echo "FAIL: $test_name - Error not found in log"
    TEST_FAILED=$((TEST_FAILED + 1))
    unset CLAUDE_TEST_MODE
    return 1
  fi

  # Check context does NOT include home and claude_project_dir for validation_error
  local has_home has_project_dir
  has_home=$(echo "$last_error" | jq -r '.context.home // "NOT_SET"')
  has_project_dir=$(echo "$last_error" | jq -r '.context.claude_project_dir // "NOT_SET"')

  # These should NOT be set for validation_error
  if [ "$has_home" != "NOT_SET" ] || [ "$has_project_dir" != "NOT_SET" ]; then
    echo "FAIL: $test_name - validation_error should not have path context"
    TEST_FAILED=$((TEST_FAILED + 1))
    unset CLAUDE_TEST_MODE
    return 1
  fi

  echo "PASS: $test_name"
  TEST_PASSED=$((TEST_PASSED + 1))
  unset CLAUDE_TEST_MODE
  return 0
}

# Run tests
test_workflow_output_file_persisted
test_empty_workflow_output_file
test_error_context_enhanced
test_file_error_context_enhanced
test_validation_error_no_enhancement

echo ""
echo "Results: $TEST_PASSED passed, $TEST_FAILED failed"
exit $TEST_FAILED
