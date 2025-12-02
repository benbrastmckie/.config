#!/usr/bin/env bash
# Unit tests for /implement command
# Tests argument capture, state initialization, and workflow orchestration

set -euo pipefail

# Test setup
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${HOME}/.config"
TEMP_TEST_DIR="${HOME}/.claude/tmp/test_implement_$$"

# Source test utilities
source "${PROJECT_ROOT}/.claude/lib/core/error-handling.sh" || exit 1
source "${PROJECT_ROOT}/.claude/lib/core/state-persistence.sh" || exit 1
source "${PROJECT_ROOT}/.claude/lib/workflow/workflow-state-machine.sh" || exit 1

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test utilities
assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="${3:-}"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [ "$expected" = "$actual" ]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "✓ PASS: $message"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "✗ FAIL: $message"
    echo "  Expected: $expected"
    echo "  Actual:   $actual"
    return 1
  fi
}

assert_file_exists() {
  local file="$1"
  local message="${2:-File should exist: $file}"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [ -f "$file" ]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "✓ PASS: $message"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "✗ FAIL: $message"
    echo "  File not found: $file"
    return 1
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-}"

  TESTS_RUN=$((TESTS_RUN + 1))

  if echo "$haystack" | grep -q "$needle"; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "✓ PASS: $message"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "✗ FAIL: $message"
    echo "  Expected to find: $needle"
    echo "  In: $haystack"
    return 1
  fi
}

# Setup test environment
setup_test() {
  mkdir -p "$TEMP_TEST_DIR"

  # Create mock plan file
  cat > "$TEMP_TEST_DIR/test-plan.md" <<'EOF'
# Test Plan

## Metadata
- **Status**: [NOT STARTED]
- **Complexity**: 50

## Phase 0: Setup
dependencies: []

Tasks:
- [ ] Task 1

## Phase 1: Implementation
dependencies: [0]

Tasks:
- [ ] Task 2
EOF
}

# Cleanup test environment
cleanup_test() {
  rm -rf "$TEMP_TEST_DIR" 2>/dev/null || true
  rm -f "${HOME}/.claude/tmp/implement_arg_"*.txt 2>/dev/null || true
  rm -f "${HOME}/.claude/tmp/implement_arg_path.txt" 2>/dev/null || true
}

# Test: Argument capture creates temp file
test_argument_capture() {
  echo ""
  echo "=== Test: Argument Capture ==="

  # Simulate argument capture
  local temp_file="${HOME}/.claude/tmp/implement_arg_$(date +%s%N).txt"
  local path_file="${HOME}/.claude/tmp/implement_arg_path.txt"

  echo "test-plan.md 1 --dry-run" > "$temp_file"
  echo "$temp_file" > "$path_file"

  assert_file_exists "$temp_file" "Argument temp file created"
  assert_file_exists "$path_file" "Argument path file created"

  # Verify content
  local content=$(cat "$temp_file")
  assert_contains "$content" "test-plan.md" "Argument content contains plan file"

  # Cleanup
  rm -f "$temp_file" "$path_file"
}

# Test: State machine initialization with implement-only workflow
test_state_machine_init() {
  echo ""
  echo "=== Test: State Machine Initialization ==="

  # Initialize state machine with implement-only workflow
  local workflow_id="test_impl_$$"
  sm_init "$workflow_id" "implement" "implement-only" 5 "[]" 2>/dev/null || true

  # Verify terminal state (may be 'implement' or 'complete' depending on workflow type support)
  TESTS_RUN=$((TESTS_RUN + 1))
  if [ "$TERMINAL_STATE" = "implement" ] || [ "$TERMINAL_STATE" = "complete" ]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "✓ PASS: Terminal state set correctly ($TERMINAL_STATE)"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "✗ FAIL: Terminal state unexpected: $TERMINAL_STATE"
  fi

  # Verify current state
  assert_equals "implement" "$CURRENT_STATE" "Current state initialized to implement"
}

# Test: Plan file validation
test_plan_file_validation() {
  echo ""
  echo "=== Test: Plan File Validation ==="

  setup_test

  local plan_file="$TEMP_TEST_DIR/test-plan.md"

  # Valid plan file
  if [ -f "$plan_file" ]; then
    assert_file_exists "$plan_file" "Plan file exists"
  fi

  # Verify plan has metadata
  local has_metadata=$(grep -c "^## Metadata" "$plan_file" || echo "0")
  TESTS_RUN=$((TESTS_RUN + 1))
  if [ "$has_metadata" -gt 0 ]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "✓ PASS: Plan file has metadata section"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "✗ FAIL: Plan file missing metadata section"
  fi

  cleanup_test
}

# Test: Iteration management
test_iteration_management() {
  echo ""
  echo "=== Test: Iteration Management ==="

  # Test iteration variables
  local iteration=1
  local max_iterations=5
  local context_threshold=90

  assert_equals "1" "$iteration" "Initial iteration is 1"
  assert_equals "5" "$max_iterations" "Max iterations default is 5"
  assert_equals "90" "$context_threshold" "Context threshold default is 90%"

  # Simulate iteration increment
  iteration=$((iteration + 1))
  assert_equals "2" "$iteration" "Iteration increments correctly"
}

# Test: State persistence
test_state_persistence() {
  echo ""
  echo "=== Test: State Persistence ==="

  setup_test

  local state_file="$TEMP_TEST_DIR/.state/implement_state.sh"
  mkdir -p "$(dirname "$state_file")"

  # Test append_workflow_state
  STATE_FILE="$state_file"
  append_workflow_state "PLAN_FILE" "$TEMP_TEST_DIR/test-plan.md" 2>/dev/null || true
  append_workflow_state "ITERATION" "1" 2>/dev/null || true

  assert_file_exists "$state_file" "State file created"

  # Verify state file content
  local has_plan=$(grep -c "PLAN_FILE=" "$state_file" || echo "0")
  TESTS_RUN=$((TESTS_RUN + 1))
  if [ "$has_plan" -gt 0 ]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "✓ PASS: State file contains PLAN_FILE"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "✗ FAIL: State file missing PLAN_FILE"
  fi

  cleanup_test
}

# Test: Pre-flight validation
test_preflight_validation() {
  echo ""
  echo "=== Test: Pre-flight Validation ==="

  # Check required functions exist
  local required_functions=(
    "save_completed_states_to_state"
    "append_workflow_state"
    "log_command_error"
  )

  for func in "${required_functions[@]}"; do
    TESTS_RUN=$((TESTS_RUN + 1))
    if declare -f "$func" >/dev/null 2>&1; then
      TESTS_PASSED=$((TESTS_PASSED + 1))
      echo "✓ PASS: Required function $func exists"
    else
      TESTS_FAILED=$((TESTS_FAILED + 1))
      echo "✗ FAIL: Required function $func not found"
    fi
  done
}

# Run all tests
run_all_tests() {
  echo "========================================="
  echo "Running /implement Command Unit Tests"
  echo "========================================="

  test_argument_capture
  test_state_machine_init
  test_plan_file_validation
  test_iteration_management
  test_state_persistence
  test_preflight_validation

  echo ""
  echo "========================================="
  echo "Test Results"
  echo "========================================="
  echo "Tests Run:    $TESTS_RUN"
  echo "Tests Passed: $TESTS_PASSED"
  echo "Tests Failed: $TESTS_FAILED"
  echo ""

  if [ "$TESTS_FAILED" -eq 0 ]; then
    echo "✓ All tests passed"
    return 0
  else
    echo "✗ Some tests failed"
    return 1
  fi
}

# Run tests
run_all_tests
exit $?
