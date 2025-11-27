#!/bin/bash
# Test Suite: State Machine Variable Persistence Across Library Re-sourcing
#
# Tests conditional initialization pattern (Pattern 5) for workflow state variables
# that must persist across bash subprocess boundaries and library re-sourcing.

set -euo pipefail

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/test-helpers.sh" ]; then
  source "$SCRIPT_DIR/test-helpers.sh"
else
  # Minimal test helpers if file doesn't exist
  test_count=0
  pass_count=0
  fail_count=0

  assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"
    test_count=$((test_count + 1))

    if [ "$expected" = "$actual" ]; then
      echo "  ✓ PASS: $message"
      pass_count=$((pass_count + 1))
      return 0
    else
      echo "  ✗ FAIL: $message"
      echo "    Expected: '$expected'"
      echo "    Actual:   '$actual'"
      fail_count=$((fail_count + 1))
      return 1
    fi
  }

  run_test_suite() {
    echo
    echo "=== Test Summary ==="
    echo "Total:  $test_count tests"
    echo "Passed: $pass_count tests"
    echo "Failed: $fail_count tests"
    echo
    if [ $fail_count -eq 0 ]; then
      echo "✓ All tests passed!"
      return 0
    else
      echo "✗ Some tests failed"
      return 1
    fi
  }
fi

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

# Locate the library
LIB_FILE="$CLAUDE_LIB/workflow/workflow-state-machine.sh"
if [ ! -f "$LIB_FILE" ]; then
  echo "ERROR: Cannot find workflow-state-machine.sh at $LIB_FILE"
  exit 1
fi

echo "=== State Machine Persistence Test Suite ==="
echo "Testing: $LIB_FILE"
echo

# Test 1: WORKFLOW_SCOPE preservation across re-sourcing
test_workflow_scope_preservation() {
  echo "Test 1: WORKFLOW_SCOPE preservation"
  (
    source "$LIB_FILE"
    WORKFLOW_SCOPE="research-and-plan"

    source "$LIB_FILE"  # Re-source

    assert_equals "research-and-plan" "$WORKFLOW_SCOPE" "WORKFLOW_SCOPE preserved after re-source"
  )
}

# Test 2: WORKFLOW_DESCRIPTION preservation
test_workflow_description_preservation() {
  echo "Test 2: WORKFLOW_DESCRIPTION preservation"
  (
    source "$LIB_FILE"
    WORKFLOW_DESCRIPTION="Test workflow description"

    source "$LIB_FILE"  # Re-source

    assert_equals "Test workflow description" "$WORKFLOW_DESCRIPTION" "WORKFLOW_DESCRIPTION preserved"
  )
}

# Test 3: CURRENT_STATE preservation with default fallback
test_current_state_preservation() {
  echo "Test 3: CURRENT_STATE preservation"
  (
    source "$LIB_FILE"
    CURRENT_STATE="research"

    source "$LIB_FILE"  # Re-source

    assert_equals "research" "$CURRENT_STATE" "CURRENT_STATE preserved"
  )
}

# Test 4: All 4 workflow scopes
test_all_workflow_scopes() {
  echo "Test 4: All workflow scopes"

  # research-only
  (
    source "$LIB_FILE"
    WORKFLOW_SCOPE="research-only"
    source "$LIB_FILE"
    assert_equals "research-only" "$WORKFLOW_SCOPE" "research-only scope preserved"
  )

  # research-and-plan
  (
    source "$LIB_FILE"
    WORKFLOW_SCOPE="research-and-plan"
    source "$LIB_FILE"
    assert_equals "research-and-plan" "$WORKFLOW_SCOPE" "research-and-plan scope preserved"
  )

  # full-implementation
  (
    source "$LIB_FILE"
    WORKFLOW_SCOPE="full-implementation"
    source "$LIB_FILE"
    assert_equals "full-implementation" "$WORKFLOW_SCOPE" "full-implementation scope preserved"
  )

  # debug-only
  (
    source "$LIB_FILE"
    WORKFLOW_SCOPE="debug-only"
    source "$LIB_FILE"
    assert_equals "debug-only" "$WORKFLOW_SCOPE" "debug-only scope preserved"
  )
}

# Test 5: Initial load (unset variables get defaults)
test_initial_defaults() {
  echo "Test 5: Initial load defaults"
  (
    unset WORKFLOW_SCOPE CURRENT_STATE TERMINAL_STATE 2>/dev/null || true
    source "$LIB_FILE"

    assert_equals "" "$WORKFLOW_SCOPE" "WORKFLOW_SCOPE defaults to empty"
    assert_equals "initialize" "$CURRENT_STATE" "CURRENT_STATE defaults to STATE_INITIALIZE"
    assert_equals "complete" "$TERMINAL_STATE" "TERMINAL_STATE defaults to STATE_COMPLETE"
  )
}

# Test 6: Multiple re-sourcing cycles (3+ times)
test_multiple_resourcing_cycles() {
  echo "Test 6: Multiple re-sourcing cycles"
  (
    source "$LIB_FILE"
    WORKFLOW_SCOPE="full-implementation"
    CURRENT_STATE="implement"

    # Re-source 3 times
    source "$LIB_FILE"
    source "$LIB_FILE"
    source "$LIB_FILE"

    assert_equals "full-implementation" "$WORKFLOW_SCOPE" "WORKFLOW_SCOPE preserved after 3 re-sources"
    assert_equals "implement" "$CURRENT_STATE" "CURRENT_STATE preserved after 3 re-sources"
  )
}

# Test 7: Subprocess isolation (simulates /coordinate behavior)
test_subprocess_isolation() {
  echo "Test 7: Subprocess isolation"

  # Subprocess 1: Set values
  (
    source "$LIB_FILE"
    WORKFLOW_SCOPE="research-and-plan"
    echo "$WORKFLOW_SCOPE" > /tmp/test_wf_scope_$$.txt
  )

  # Subprocess 2: Load and verify preservation
  (
    # Load saved value
    WORKFLOW_SCOPE=$(cat /tmp/test_wf_scope_$$.txt)

    # Re-source library (should preserve WORKFLOW_SCOPE)
    source "$LIB_FILE"

    assert_equals "research-and-plan" "$WORKFLOW_SCOPE" "WORKFLOW_SCOPE preserved across subprocess boundary"
    rm -f /tmp/test_wf_scope_$$.txt
  )
}

# Test 8: Interaction with load_workflow_state() pattern
test_state_loading_pattern() {
  echo "Test 8: State loading pattern"
  (
    # Simulate /coordinate pattern: source, set values, re-source
    source "$LIB_FILE"

    # Simulate loading from state file
    WORKFLOW_SCOPE="research-and-plan"
    WORKFLOW_DESCRIPTION="Research authentication patterns"
    CURRENT_STATE="research"

    # Re-source libraries (happens in subsequent bash blocks)
    source "$LIB_FILE"

    # Values should be preserved
    assert_equals "research-and-plan" "$WORKFLOW_SCOPE" "WORKFLOW_SCOPE preserved in state loading pattern"
    assert_equals "Research authentication patterns" "$WORKFLOW_DESCRIPTION" "WORKFLOW_DESCRIPTION preserved"
    assert_equals "research" "$CURRENT_STATE" "CURRENT_STATE preserved"
  )
}

# Run all tests
echo "Running tests..."
echo
test_workflow_scope_preservation
echo
test_workflow_description_preservation
echo
test_current_state_preservation
echo
test_all_workflow_scopes
echo
test_initial_defaults
echo
test_multiple_resourcing_cycles
echo
test_subprocess_isolation
echo
test_state_loading_pattern
echo

# Summary
run_test_suite
