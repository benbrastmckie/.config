#!/usr/bin/env bash
# test_lint_task_invocation.sh
# Test suite for lint-task-invocation-pattern.sh linter

set -eo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LINTER_SCRIPT="$PROJECT_DIR/scripts/lint-task-invocation-pattern.sh"
TEMP_DIR=$(mktemp -d)

# Counters
PASS_COUNT=0
FAIL_COUNT=0

# Cleanup
cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Test helpers
assert_error() {
  local test_name="$1"
  local test_file="$2"
  local exit_code=0

  bash "$LINTER_SCRIPT" "$test_file" >/dev/null 2>&1 || exit_code=$?

  if [ $exit_code -eq 0 ]; then
    echo -e "${RED}FAIL${NC}: $test_name - Expected error but linter passed (exit $exit_code)"
    bash "$LINTER_SCRIPT" "$test_file" 2>&1 | tail -10
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  else
    echo -e "${GREEN}PASS${NC}: $test_name (detected error, exit $exit_code)"
    PASS_COUNT=$((PASS_COUNT + 1))
    return 0
  fi
}

assert_pass() {
  local test_name="$1"
  local test_file="$2"
  local exit_code=0

  bash "$LINTER_SCRIPT" "$test_file" >/dev/null 2>&1 || exit_code=$?

  if [ $exit_code -eq 0 ]; then
    echo -e "${GREEN}PASS${NC}: $test_name (no errors, exit $exit_code)"
    PASS_COUNT=$((PASS_COUNT + 1))
    return 0
  else
    echo -e "${RED}FAIL${NC}: $test_name - Expected pass but linter failed (exit $exit_code)"
    bash "$LINTER_SCRIPT" "$test_file" 2>&1 | head -20
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi
}

# Test 1: Detect naked Task block
test_naked_task_block() {
  local test_file="$TEMP_DIR/test_naked_task.md"
  cat > "$test_file" << 'EOF'
# Test Command

## Block 1a: Setup

Some setup text.

## Block 1b: Execute

Task {
  subagent_type: "general-purpose"
  description: "Test agent"
  prompt: "Do something"
}
EOF

  assert_error "Naked Task block detection" "$test_file"
}

# Test 2: Accept properly prefixed Task block (EXECUTE NOW)
test_valid_execute_now() {
  local test_file="$TEMP_DIR/test_valid_execute_now.md"
  cat > "$test_file" << 'EOF'
# Test Command

## Block 1a: Setup

Some setup text.

## Block 1b: Execute

**EXECUTE NOW**: USE the Task tool with these parameters:

Task {
  subagent_type: "general-purpose"
  description: "Test agent"
  prompt: "Do something"
}
EOF

  assert_pass "Valid EXECUTE NOW Task block" "$test_file"
}

# Test 3: Accept conditional Task block (EXECUTE IF)
test_valid_execute_if() {
  local test_file="$TEMP_DIR/test_valid_execute_if.md"
  cat > "$test_file" << 'EOF'
# Test Command

## Block 1a: Setup

Some setup text.

## Block 1b: Execute

**EXECUTE IF** tests fail: USE the Task tool with these parameters:

Task {
  subagent_type: "general-purpose"
  description: "Debug agent"
  prompt: "Debug the failure"
}
EOF

  assert_pass "Valid EXECUTE IF Task block" "$test_file"
}

# Test 4: Detect instructional text without Task block
test_instructional_text() {
  local test_file="$TEMP_DIR/test_instructional.md"
  cat > "$test_file" << 'EOF'
# Test Command

## Block 1a: Setup

Some setup text.

## Block 1b: Execute

Use the Task tool to invoke the test-executor agent with the following parameters:
- subagent_type: "general-purpose"
- description: "Run tests"

But no actual Task block follows within 10 lines.

Some other content here.
EOF

  assert_error "Instructional text without Task block" "$test_file"
}

# Test 5: Accept instructional text WITH Task block nearby
test_instructional_with_task() {
  local test_file="$TEMP_DIR/test_instructional_ok.md"
  cat > "$test_file" << 'EOF'
# Test Command

## Block 1a: Setup

Some setup text.

## Block 1b: Execute

**EXECUTE NOW**: USE the Task tool to invoke the test-executor agent.

Task {
  subagent_type: "general-purpose"
  description: "Run tests"
  prompt: "Execute tests"
}
EOF

  assert_pass "Instructional text with Task block" "$test_file"
}

# Test 6: Detect incomplete EXECUTE NOW (missing "USE the Task tool")
test_incomplete_execute() {
  local test_file="$TEMP_DIR/test_incomplete_execute.md"
  cat > "$test_file" << 'EOF'
# Test Command

## Block 1a: Setup

Some setup text.

## Block 1b: Execute

**EXECUTE NOW**: Invoke the test-executor agent.

Task {
  subagent_type: "general-purpose"
  description: "Run tests"
  prompt: "Execute tests"
}
EOF

  assert_error "Incomplete EXECUTE NOW directive" "$test_file"
}

# Test 7: Skip README.md files
test_skip_readme() {
  local test_file="$TEMP_DIR/README.md"
  cat > "$test_file" << 'EOF'
# README

This is a README with example code:

Task {
  subagent_type: "general-purpose"
  description: "Example only"
}
EOF

  assert_pass "Skip README.md files" "$test_file"
}

# Test 8: Multiple Task blocks - some valid, some not
test_mixed_task_blocks() {
  local test_file="$TEMP_DIR/test_mixed.md"
  cat > "$test_file" << 'EOF'
# Test Command

## Block 1b: Execute

**EXECUTE NOW**: USE the Task tool.

Task {
  subagent_type: "general-purpose"
  description: "Valid agent"
  prompt: "Do something"
}

## Block 2b: Execute

Task {
  subagent_type: "general-purpose"
  description: "Invalid agent"
  prompt: "Missing directive"
}
EOF

  assert_error "Mixed valid/invalid Task blocks" "$test_file"
}

# Test 9: Iteration loop pattern (multiple valid Task blocks)
test_iteration_loop() {
  local test_file="$TEMP_DIR/test_iteration.md"
  cat > "$test_file" << 'EOF'
# Test Command

## Block 1b: Execute - Initial Invocation

**EXECUTE NOW**: USE the Task tool to invoke implementer-coordinator.

Task {
  subagent_type: "general-purpose"
  description: "Initial implementation"
  prompt: "Implement phase 1"
}

## Block 2b: Execute - Iteration Loop

**EXECUTE NOW**: USE the Task tool to re-invoke implementer-coordinator.

Task {
  subagent_type: "general-purpose"
  description: "Continue implementation"
  prompt: "Continue from checkpoint"
}
EOF

  assert_pass "Iteration loop pattern" "$test_file"
}

# Test 10: Empty file
test_empty_file() {
  local test_file="$TEMP_DIR/test_empty.md"
  touch "$test_file"

  assert_pass "Empty file" "$test_file"
}

# Main execution
echo "=========================================="
echo "Task Invocation Pattern Linter Test Suite"
echo "=========================================="
echo ""

if [ ! -f "$LINTER_SCRIPT" ]; then
  echo -e "${RED}ERROR${NC}: Linter script not found: $LINTER_SCRIPT"
  exit 1
fi

echo "Running tests..."
echo ""

# Run all tests
test_naked_task_block
test_valid_execute_now
test_valid_execute_if
test_instructional_text
test_instructional_with_task
test_incomplete_execute
test_skip_readme
test_mixed_task_blocks
test_iteration_loop
test_empty_file

# Summary
echo ""
echo "=========================================="
echo "Test Results"
echo "=========================================="
echo -e "Passed: ${GREEN}${PASS_COUNT}${NC}"
echo -e "Failed: ${RED}${FAIL_COUNT}${NC}"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed${NC}"
  exit 1
fi
