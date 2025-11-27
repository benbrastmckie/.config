#!/usr/bin/env bash
# test_topic_naming_integration.sh - Integration tests for topic naming workflow
# Tests end-to-end command integration with topic naming agent

set -euo pipefail

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
CLAUDE_LIB="${CLAUDE_PROJECT_DIR}/.claude/lib"
PROJECT_ROOT="${CLAUDE_PROJECT_DIR}/.claude"

# Source required libraries
source "$CLAUDE_LIB/plan/topic-utils.sh" 2>/dev/null || {
  echo "ERROR: Cannot load topic-utils library"
  exit 1
}

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result tracking
pass() {
  echo "  ✓ $1"
  ((TESTS_PASSED++)) || true
  ((TESTS_RUN++)) || true
}

fail() {
  echo "  ✗ $1"
  if [ $# -ge 2 ]; then
    echo "    Reason: $2"
  fi
  ((TESTS_FAILED++)) || true
  ((TESTS_RUN++)) || true
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST SUITE: Topic Naming Integration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ==============================================================================
# Test 1: Verify agent file exists and is readable
# ==============================================================================
echo "Test 1: Agent file existence and accessibility"

AGENT_FILE="$PROJECT_ROOT/agents/topic-naming-agent.md"
if [ -f "$AGENT_FILE" ]; then
  pass "Agent file exists: $AGENT_FILE"
else
  fail "Agent file missing: $AGENT_FILE" "Integration requires agent file"
fi

if [ -r "$AGENT_FILE" ]; then
  pass "Agent file is readable"
else
  fail "Agent file not readable: $AGENT_FILE" "Check file permissions"
fi

# ==============================================================================
# Test 2: Verify agent file structure
# ==============================================================================
echo ""
echo "Test 2: Agent file structure validation"

# Check for required sections
if grep -q "^# Topic Naming Agent" "$AGENT_FILE"; then
  pass "Agent file has proper title"
else
  fail "Agent file missing title" "Should have '# Topic Naming Agent'"
fi

if grep -q "STEP 1" "$AGENT_FILE"; then
  pass "Agent has STEP 1 defined"
else
  fail "Agent missing STEP 1" "Required for execution workflow"
fi

if grep -q "STEP 2" "$AGENT_FILE"; then
  pass "Agent has STEP 2 defined"
else
  fail "Agent missing STEP 2" "Required for execution workflow"
fi

if grep -q "STEP 3" "$AGENT_FILE"; then
  pass "Agent has STEP 3 defined"
else
  fail "Agent missing STEP 3" "Required for execution workflow"
fi

if grep -q "STEP 4" "$AGENT_FILE"; then
  pass "Agent has STEP 4 defined"
else
  fail "Agent missing STEP 4" "Required for execution workflow"
fi

# ==============================================================================
# Test 3: Verify validation function integration
# ==============================================================================
echo ""
echo "Test 3: Validation function integration"

# Test that validation function exists and works
if type validate_topic_name_format &>/dev/null; then
  pass "validate_topic_name_format function exists"
else
  fail "validate_topic_name_format not found" "Required for integration"
fi

# Test validation works correctly
if validate_topic_name_format "test_name"; then
  pass "Validation function works for valid name"
else
  fail "Validation function fails for valid name" "Function may be broken"
fi

if ! validate_topic_name_format "Invalid-Name"; then
  pass "Validation function rejects invalid name"
else
  fail "Validation function accepts invalid name" "Function may be broken"
fi

# ==============================================================================
# Test 4: Verify error handling library integration
# ==============================================================================
echo ""
echo "Test 4: Error handling library integration"

ERROR_HANDLING_LIB="$PROJECT_ROOT/lib/core/error-handling.sh"
if [ -f "$ERROR_HANDLING_LIB" ]; then
  pass "Error handling library exists"
else
  fail "Error handling library missing" "Required for error logging"
fi

# Source error handling library
if source "$ERROR_HANDLING_LIB" 2>/dev/null; then
  pass "Error handling library sources successfully"
else
  fail "Error handling library has errors" "Check library syntax"
fi

# Check for required functions
if type ensure_error_log_exists &>/dev/null; then
  pass "ensure_error_log_exists function available"
else
  fail "ensure_error_log_exists not found" "Required for error logging"
fi

if type log_command_error &>/dev/null; then
  pass "log_command_error function available"
else
  fail "log_command_error not found" "Required for error logging"
fi

# ==============================================================================
# Test 5: Command integration points
# ==============================================================================
echo ""
echo "Test 5: Command integration points"

# Check that commands reference the topic-naming-agent
for cmd in plan research debug optimize-claude; do
  CMD_FILE="$PROJECT_ROOT/commands/${cmd}.md"
  if [ -f "$CMD_FILE" ]; then
    if grep -q "topic-naming-agent" "$CMD_FILE"; then
      pass "/${cmd} command integrated with topic-naming-agent"
    else
      fail "/${cmd} command missing agent integration" "Should reference topic-naming-agent.md"
    fi
  else
    fail "/${cmd} command file not found" "Expected at $CMD_FILE"
  fi
done

# ==============================================================================
# Test 6: Topic allocation function availability
# ==============================================================================
echo ""
echo "Test 6: Topic allocation function availability"

# Check for topic number allocation function
if grep -q "get_next_topic_number" "$PROJECT_ROOT/lib/plan/topic-utils.sh"; then
  pass "get_next_topic_number function defined"
else
  fail "get_next_topic_number not found" "Required for topic creation"
fi

if grep -q "get_or_create_topic_number" "$PROJECT_ROOT/lib/plan/topic-utils.sh"; then
  pass "get_or_create_topic_number function defined"
else
  fail "get_or_create_topic_number not found" "Required for idempotent topic creation"
fi

# ==============================================================================
# Test 7: Agent completion signal format
# ==============================================================================
echo ""
echo "Test 7: Agent completion signal format"

# Verify agent documentation describes correct signal
if grep -q "TOPIC_NAME_GENERATED:" "$AGENT_FILE"; then
  pass "Agent uses TOPIC_NAME_GENERATED completion signal"
else
  fail "Agent missing completion signal" "Should return TOPIC_NAME_GENERATED:"
fi

# Verify error signal format
if grep -q "TASK_ERROR:" "$AGENT_FILE"; then
  pass "Agent defines TASK_ERROR signal for failures"
else
  fail "Agent missing error signal" "Should define TASK_ERROR format"
fi

# ==============================================================================
# Test Summary
# ==============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST RESULTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Tests run: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo "✓ All integration tests passed"
  exit 0
else
  echo "✗ Some integration tests failed"
  exit 1
fi
