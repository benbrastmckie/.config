#!/usr/bin/env bash
# Test: Build command state transitions
# Coverage: State machine transition validation for build workflow
# Created for: spec 790 - Fix state machine transition error
# Updated for: spec 947 - Idempotent state transitions

set -e

# Disable history expansion for exclamation marks
set +H 2>/dev/null || true

# Test isolation pattern per testing-protocols.md
setup_test_environment() {
  local test_dir
  test_dir="$(mktemp -d)"
  export CLAUDE_SPECS_ROOT="$test_dir"
  export CLAUDE_PROJECT_DIR="$test_dir"

  # Create minimal test structure with subdirectories
  mkdir -p "$test_dir/.claude/lib/core"
  mkdir -p "$test_dir/.claude/lib/workflow"
  mkdir -p "$test_dir/.claude/tmp"

  # Copy required libraries to correct subdirectories
  cp /home/benjamin/.config/.claude/lib/core/state-persistence.sh "$test_dir/.claude/lib/core/"
  cp /home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh "$test_dir/.claude/lib/workflow/"

  # Copy detect-project-dir.sh (required by workflow-state-machine.sh)
  if [ -f "/home/benjamin/.config/.claude/lib/core/detect-project-dir.sh" ]; then
    cp /home/benjamin/.config/.claude/lib/core/detect-project-dir.sh "$test_dir/.claude/lib/core/"
  fi

  # Copy checkpoint-utils if it exists
  if [ -f "/home/benjamin/.config/.claude/lib/workflow/checkpoint-utils.sh" ]; then
    cp /home/benjamin/.config/.claude/lib/workflow/checkpoint-utils.sh "$test_dir/.claude/lib/workflow/"
  fi

  # Copy error-handling if it exists (dependency)
  if [ -f "/home/benjamin/.config/.claude/lib/core/error-handling.sh" ]; then
    cp /home/benjamin/.config/.claude/lib/core/error-handling.sh "$test_dir/.claude/lib/core/"
  fi

  echo "$test_dir"
}

cleanup() {
  if [ -n "${TEST_DIR:-}" ] && [ -d "$TEST_DIR" ]; then
    rm -rf "$TEST_DIR"
  fi
  unset CLAUDE_SPECS_ROOT CLAUDE_PROJECT_DIR
}

trap cleanup EXIT

# Test: Valid state transitions (full workflow)
test_valid_state_transitions() {
  local test_dir
  test_dir=$(setup_test_environment)
  TEST_DIR="$test_dir"

  # Source libraries
  source "$test_dir/.claude/lib/core/state-persistence.sh"
  source "$test_dir/.claude/lib/workflow/workflow-state-machine.sh"

  # Initialize workflow
  export WORKFLOW_ID="test_workflow_valid"
  init_workflow_state "$WORKFLOW_ID" >/dev/null 2>&1
  sm_init "test workflow" "build" "full-implementation" "1" "[]" >/dev/null 2>&1

  # Test transitions
  sm_transition "$STATE_IMPLEMENT" >/dev/null 2>&1 || { echo "✗ FAIL: initialize -> implement"; return 1; }
  sm_transition "$STATE_TEST" >/dev/null 2>&1 || { echo "✗ FAIL: implement -> test"; return 1; }
  sm_transition "$STATE_DOCUMENT" >/dev/null 2>&1 || { echo "✗ FAIL: test -> document"; return 1; }
  sm_transition "$STATE_COMPLETE" >/dev/null 2>&1 || { echo "✗ FAIL: document -> complete"; return 1; }

  echo "✓ PASS: Valid state transitions"
  return 0
}

# Test: Invalid transition (implement -> complete)
test_invalid_implement_to_complete() {
  local test_dir
  test_dir=$(setup_test_environment)
  TEST_DIR="$test_dir"

  # Source libraries
  source "$test_dir/.claude/lib/core/state-persistence.sh"
  source "$test_dir/.claude/lib/workflow/workflow-state-machine.sh"

  # Initialize workflow
  export WORKFLOW_ID="test_workflow_impl_complete"
  init_workflow_state "$WORKFLOW_ID" >/dev/null 2>&1
  sm_init "test workflow" "build" "full-implementation" "1" "[]" >/dev/null 2>&1
  sm_transition "$STATE_IMPLEMENT" >/dev/null 2>&1

  # Attempt invalid transition - should fail
  if sm_transition "$STATE_COMPLETE" >/dev/null 2>&1; then
    echo "✗ FAIL: implement -> complete should have failed"
    return 1
  fi

  echo "✓ PASS: Invalid transition implement -> complete correctly rejected"
  return 0
}

# Test: Valid transition (test -> complete) - for workflows that skip documentation
test_valid_test_to_complete() {
  local test_dir
  test_dir=$(setup_test_environment)
  TEST_DIR="$test_dir"

  # Source libraries
  source "$test_dir/.claude/lib/core/state-persistence.sh"
  source "$test_dir/.claude/lib/workflow/workflow-state-machine.sh"

  # Initialize workflow
  export WORKFLOW_ID="test_workflow_test_complete"
  init_workflow_state "$WORKFLOW_ID" >/dev/null 2>&1
  sm_init "test workflow" "build" "full-implementation" "1" "[]" >/dev/null 2>&1
  sm_transition "$STATE_IMPLEMENT" >/dev/null 2>&1
  sm_transition "$STATE_TEST" >/dev/null 2>&1

  # Test -> complete should now be valid (skip documentation)
  if ! sm_transition "$STATE_COMPLETE" >/dev/null 2>&1; then
    echo "✗ FAIL: test -> complete should succeed (allows skipping documentation)"
    return 1
  fi

  echo "✓ PASS: Valid transition test -> complete (skip documentation)"
  return 0
}

# Test: Valid transition (debug -> complete)
test_valid_debug_to_complete() {
  local test_dir
  test_dir=$(setup_test_environment)
  TEST_DIR="$test_dir"

  # Source libraries
  source "$test_dir/.claude/lib/core/state-persistence.sh"
  source "$test_dir/.claude/lib/workflow/workflow-state-machine.sh"

  # Initialize workflow
  export WORKFLOW_ID="test_workflow_debug_complete"
  init_workflow_state "$WORKFLOW_ID" >/dev/null 2>&1
  sm_init "test workflow" "build" "full-implementation" "1" "[]" >/dev/null 2>&1
  sm_transition "$STATE_IMPLEMENT" >/dev/null 2>&1
  sm_transition "$STATE_TEST" >/dev/null 2>&1
  sm_transition "$STATE_DEBUG" >/dev/null 2>&1

  # Debug -> complete should be valid
  if ! sm_transition "$STATE_COMPLETE" >/dev/null 2>&1; then
    echo "✗ FAIL: debug -> complete should succeed"
    return 1
  fi

  echo "✓ PASS: Valid transition debug -> complete"
  return 0
}

# Test: State persistence and load
test_state_persistence() {
  local test_dir
  test_dir=$(setup_test_environment)
  TEST_DIR="$test_dir"

  # Source libraries
  source "$test_dir/.claude/lib/core/state-persistence.sh"
  source "$test_dir/.claude/lib/workflow/workflow-state-machine.sh"

  # Initialize and transition
  export WORKFLOW_ID="test_workflow_persist"
  init_workflow_state "$WORKFLOW_ID" >/dev/null 2>&1
  sm_init "test workflow" "build" "full-implementation" "1" "[]" >/dev/null 2>&1
  sm_transition "$STATE_IMPLEMENT" >/dev/null 2>&1
  sm_transition "$STATE_TEST" >/dev/null 2>&1

  # Save state
  save_completed_states_to_state 2>/dev/null || true

  # Verify state file exists
  if [ ! -f "$STATE_FILE" ]; then
    echo "✗ FAIL: State file not created"
    return 1
  fi

  # Load state in new context
  local loaded_state=""
  load_workflow_state "$WORKFLOW_ID" false
  loaded_state="$CURRENT_STATE"

  if [ "$loaded_state" != "test" ]; then
    echo "✗ FAIL: State not properly loaded (expected: test, got: $loaded_state)"
    return 1
  fi

  echo "✓ PASS: State persistence and load"
  return 0
}

# Test: History expansion handling (strings with exclamation marks)
test_history_expansion_handling() {
  local test_dir
  test_dir=$(setup_test_environment)
  TEST_DIR="$test_dir"

  # Disable history expansion
  set +H 2>/dev/null || true
  set +o histexpand 2>/dev/null || true

  # Test that exclamation marks in strings don't cause issues
  local test_string="This is a test! With exclamation!"

  if [ "$test_string" != "This is a test! With exclamation!" ]; then
    echo "✗ FAIL: History expansion altered string with exclamation marks"
    return 1
  fi

  # Test in echo command
  local echoed
  echoed=$(echo "Test message! Important!")
  if [ "$echoed" != "Test message! Important!" ]; then
    echo "✗ FAIL: Echo with exclamation marks failed"
    return 1
  fi

  echo "✓ PASS: History expansion handling"
  return 0
}

# Test: Missing state file detection
test_missing_state_file() {
  local test_dir
  test_dir=$(setup_test_environment)
  TEST_DIR="$test_dir"

  # Source libraries
  source "$test_dir/.claude/lib/core/state-persistence.sh"
  source "$test_dir/.claude/lib/workflow/workflow-state-machine.sh"

  # Try to load a non-existent workflow
  local result
  if load_workflow_state "nonexistent_workflow_12345" false 2>/dev/null; then
    # Function succeeded, but state file should not exist
    if [ -n "$STATE_FILE" ] && [ -f "$STATE_FILE" ]; then
      echo "✗ FAIL: State file should not exist for non-existent workflow"
      return 1
    fi
  fi

  echo "✓ PASS: Missing state file detection"
  return 0
}

# Test: Idempotent same-state transition
test_idempotent_transition() {
  local test_dir
  test_dir=$(setup_test_environment)
  TEST_DIR="$test_dir"

  # Source libraries
  source "$test_dir/.claude/lib/core/state-persistence.sh"
  source "$test_dir/.claude/lib/workflow/workflow-state-machine.sh"

  # Initialize workflow
  export WORKFLOW_ID="test_workflow_idempotent"
  init_workflow_state "$WORKFLOW_ID" >/dev/null 2>&1
  sm_init "test workflow" "build" "full-implementation" "1" "[]" >/dev/null 2>&1

  # Transition to implement state
  sm_transition "$STATE_IMPLEMENT" >/dev/null 2>&1 || { echo "✗ FAIL: initial transition failed"; return 1; }

  # Attempt same-state transition (should succeed)
  if ! sm_transition "$STATE_IMPLEMENT" 2>/dev/null; then
    echo "✗ FAIL: Same-state transition should succeed"
    return 1
  fi

  # Verify current state is still implement
  local current=$(sm_current_state)
  if [ "$current" != "implement" ]; then
    echo "✗ FAIL: Current state changed (expected: implement, got: $current)"
    return 1
  fi

  echo "✓ PASS: Idempotent same-state transition"
  return 0
}

# Test: Idempotent transition logging
test_idempotent_logging() {
  local test_dir
  test_dir=$(setup_test_environment)
  TEST_DIR="$test_dir"

  # Source libraries
  source "$test_dir/.claude/lib/core/state-persistence.sh"
  source "$test_dir/.claude/lib/workflow/workflow-state-machine.sh"

  # Initialize workflow
  export WORKFLOW_ID="test_workflow_logging"
  init_workflow_state "$WORKFLOW_ID" >/dev/null 2>&1
  sm_init "test workflow" "build" "full-implementation" "1" "[]" >/dev/null 2>&1

  # Transition to test state (via implement first)
  sm_transition "$STATE_IMPLEMENT" >/dev/null 2>&1 || { echo "✗ FAIL: transition to implement failed"; return 1; }
  sm_transition "$STATE_TEST" >/dev/null 2>&1 || { echo "✗ FAIL: transition to test failed"; return 1; }

  # Capture stderr from same-state transition
  local stderr_output
  stderr_output=$(sm_transition "$STATE_TEST" 2>&1 >/dev/null)

  # Check for INFO message (not ERROR)
  if ! echo "$stderr_output" | grep -q "INFO.*Already in state.*test.*idempotent"; then
    echo "✗ FAIL: Expected INFO message for same-state transition"
    echo "Got: $stderr_output"
    return 1
  fi

  # Verify no ERROR message
  if echo "$stderr_output" | grep -q "ERROR"; then
    echo "✗ FAIL: Should not log ERROR for same-state transition"
    return 1
  fi

  echo "✓ PASS: Idempotent transition logging"
  return 0
}

# Test: COMPLETED_STATES array doesn't duplicate same-state
test_completed_states_idempotent() {
  local test_dir
  test_dir=$(setup_test_environment)
  TEST_DIR="$test_dir"

  # Source libraries
  source "$test_dir/.claude/lib/core/state-persistence.sh"
  source "$test_dir/.claude/lib/workflow/workflow-state-machine.sh"

  # Initialize workflow
  export WORKFLOW_ID="test_workflow_completed_states"
  init_workflow_state "$WORKFLOW_ID" >/dev/null 2>&1
  sm_init "test workflow" "build" "full-implementation" "1" "[]" >/dev/null 2>&1

  # Transition to implement state
  sm_transition "$STATE_IMPLEMENT" >/dev/null 2>&1

  # Get initial COMPLETED_STATES count
  local initial_count=${#COMPLETED_STATES[@]}

  # Perform same-state transition
  sm_transition "$STATE_IMPLEMENT" >/dev/null 2>&1

  # Get final COMPLETED_STATES count
  local final_count=${#COMPLETED_STATES[@]}

  # Count should be same (no duplicate)
  if [ "$final_count" -ne "$initial_count" ]; then
    echo "✗ FAIL: COMPLETED_STATES array duplicated (initial: $initial_count, final: $final_count)"
    return 1
  fi

  echo "✓ PASS: COMPLETED_STATES array doesn't duplicate"
  return 0
}

# Test: Checkpoint resume with same state
test_checkpoint_resume_same_state() {
  local test_dir
  test_dir=$(setup_test_environment)
  TEST_DIR="$test_dir"

  # Source libraries
  source "$test_dir/.claude/lib/core/state-persistence.sh"
  source "$test_dir/.claude/lib/workflow/workflow-state-machine.sh"

  # Initialize workflow
  export WORKFLOW_ID="test_workflow_checkpoint_resume"
  init_workflow_state "$WORKFLOW_ID" >/dev/null 2>&1
  sm_init "test workflow" "build" "full-implementation" "1" "[]" >/dev/null 2>&1

  # Transition to implement state (simulating checkpoint state)
  sm_transition "$STATE_IMPLEMENT" >/dev/null 2>&1

  # Save current state
  local checkpoint_state="$CURRENT_STATE"

  # Simulate checkpoint resume by transitioning to same state
  # This would occur when resuming from checkpoint with --starting-phase
  if ! sm_transition "$checkpoint_state" 2>/dev/null; then
    echo "✗ FAIL: Checkpoint resume with same state should succeed"
    return 1
  fi

  # Verify state unchanged
  local current=$(sm_current_state)
  if [ "$current" != "$checkpoint_state" ]; then
    echo "✗ FAIL: State changed during checkpoint resume"
    return 1
  fi

  echo "✓ PASS: Checkpoint resume with same state"
  return 0
}

# Run all tests
main() {
  local failed=0
  local passed=0

  echo "Running build state transition tests..."
  echo "======================================="
  echo ""

  if test_valid_state_transitions; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  if test_invalid_implement_to_complete; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  if test_valid_test_to_complete; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  if test_valid_debug_to_complete; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  if test_state_persistence; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  if test_history_expansion_handling; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  if test_missing_state_file; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  if test_idempotent_transition; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  if test_idempotent_logging; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  if test_completed_states_idempotent; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  if test_checkpoint_resume_same_state; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  echo ""
  echo "======================================="
  echo "Results: $passed passed, $failed failed"
  echo ""

  if [ "$failed" -gt 0 ]; then
    echo "✗ FAILED: $failed test(s) failed"
    exit 1
  fi

  echo "All tests passed"
  exit 0
}

main "$@"
