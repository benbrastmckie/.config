#!/usr/bin/env bash
#
# Test: /todo command hard barrier pattern compliance
#
# Validates that /todo command follows hard barrier subagent delegation pattern:
# - Block 2b uses Task tool (not pseudo-code)
# - Block 2c exists (verification block)
# - No fallback logic in Block 3
# - State transitions present
# - CRITICAL BARRIER label exists

set -e

# Detect project paths
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  CLAUDE_PROJECT_DIR="${HOME}/.config"
fi
export CLAUDE_PROJECT_DIR

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/test-helpers.sh" 2>/dev/null || {
  echo "ERROR: Failed to source test-helpers.sh" >&2
  exit 1
}

# Setup test
setup_test

echo "=== /todo Command Hard Barrier Compliance Test ==="
echo ""

# Test 1: Verify Block 2a/2b/2c structure exists
echo "Test 1: Verify Block 2a/2b/2c sub-block structure"
TODO_CMD="${CLAUDE_PROJECT_DIR}/.claude/commands/todo.md"

if [ ! -f "$TODO_CMD" ]; then
  fail "todo.md not found: $TODO_CMD"
fi

# Check for Block 2a
if ! grep -q "## Block 2a: Status Classification Setup" "$TODO_CMD"; then
  fail "Block 2a (Setup) not found in todo.md"
fi
echo "✓ Block 2a (Setup) present"

# Check for Block 2b
if ! grep -q "## Block 2b: Status Classification Execution" "$TODO_CMD"; then
  fail "Block 2b (Execute) not found in todo.md"
fi
echo "✓ Block 2b (Execute) present"

# Check for Block 2c
if ! grep -q "## Block 2c: Status Classification Verification" "$TODO_CMD"; then
  fail "Block 2c (Verify) not found in todo.md"
fi
echo "✓ Block 2c (Verify) present"

echo ""

# Test 2: Verify Block 2b uses Task tool (not pseudo-code)
echo "Test 2: Verify Block 2b uses proper Task tool invocation"
if ! grep -A 50 "## Block 2b:" "$TODO_CMD" | grep -q "Task {"; then
  fail "Block 2b does not contain Task tool invocation"
fi
echo "✓ Block 2b contains Task tool invocation"

# Verify it's not just guidance text
if grep -A 50 "## Block 2b:" "$TODO_CMD" | grep -q "prompt: |"; then
  echo "✓ Task invocation uses proper format (prompt: |)"
else
  fail "Task invocation format incorrect (should use 'prompt: |')"
fi

echo ""

# Test 3: Verify CRITICAL BARRIER label exists
echo "Test 3: Verify CRITICAL BARRIER label present"
if ! grep -q "CRITICAL BARRIER.*todo-analyzer" "$TODO_CMD"; then
  fail "CRITICAL BARRIER label not found in todo.md"
fi
echo "✓ CRITICAL BARRIER label present"

echo ""

# Test 4: Verify no fallback logic in Block 3
echo "Test 4: Verify fallback logic removed from Block 3"
if grep -q "fallback.*direct metadata" "$TODO_CMD"; then
  fail "Fallback logic still present in todo.md"
fi
echo "✓ Fallback logic removed"

if grep -q "extract_plan_metadata" "$TODO_CMD"; then
  fail "Direct plan processing found (extract_plan_metadata)"
fi
echo "✓ No direct plan processing in Block 3"

echo ""

# Test 5: Verify state transitions present
echo "Test 5: Verify state machine integration"
if ! grep -q 'source.*workflow-state-machine.sh' "$TODO_CMD"; then
  fail "workflow-state-machine.sh not sourced"
fi
echo "✓ workflow-state-machine.sh sourced"

if ! grep -q 'sm_init.*"/todo"' "$TODO_CMD"; then
  fail "sm_init not called with /todo"
fi
echo "✓ sm_init call present"

TRANSITION_COUNT=$(grep -c 'sm_transition' "$TODO_CMD" || echo "0")
if [ "$TRANSITION_COUNT" -lt 3 ]; then
  fail "Expected at least 3 state transitions, found $TRANSITION_COUNT"
fi
echo "✓ State transitions present (count: $TRANSITION_COUNT)"

echo ""

# Test 6: Verify verification block has fail-fast checks
echo "Test 6: Verify Block 2c has fail-fast verification"
if ! grep -A 100 "## Block 2c:" "$TODO_CMD" | grep -q "VERIFICATION FAILED"; then
  fail "Block 2c missing VERIFICATION FAILED error messages"
fi
echo "✓ Block 2c has fail-fast error messages"

if ! grep -A 100 "## Block 2c:" "$TODO_CMD" | grep -q "log_command_error.*verification_error"; then
  fail "Block 2c missing error logging"
fi
echo "✓ Block 2c has error logging"

echo ""

# Test 7: Verify checkpoint markers
echo "Test 7: Verify checkpoint markers present"
if ! grep -q '\[CHECKPOINT\].*Setup complete.*todo-analyzer' "$TODO_CMD"; then
  fail "Block 2a checkpoint marker missing"
fi
echo "✓ Block 2a checkpoint present"

if ! grep -q '\[CHECKPOINT\].*Verification complete' "$TODO_CMD"; then
  fail "Block 2c checkpoint marker missing"
fi
echo "✓ Block 2c checkpoint present"

echo ""

# Test 8: Verify variable persistence
echo "Test 8: Verify variable persistence in Block 2a"
if ! grep -A 80 "## Block 2a:" "$TODO_CMD" | grep -q "append_workflow_state"; then
  fail "Block 2a missing variable persistence (append_workflow_state)"
fi
echo "✓ Block 2a persists variables"

if ! grep -A 80 "## Block 2c:" "$TODO_CMD" | grep -q 'source.*STATE_FILE'; then
  fail "Block 2c missing state restoration"
fi
echo "✓ Block 2c restores state"

echo ""

# All tests passed
pass "All hard barrier compliance checks passed"

# Cleanup
teardown_test
