#!/usr/bin/env bash
# Test suite for /errors command report generation functionality

set -euo pipefail

# Setup directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Go up to .config directory (tests/features/commands -> tests -> .claude -> .config)
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

# Test suite metadata
TEST_SUITE="errors_report_generation"
TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

# Setup test environment
setup_test_env() {
  TEST_TMP_DIR=$(mktemp -d)
  TEST_ERROR_LOG="${TEST_TMP_DIR}/test-errors.jsonl"
  TEST_SPECS_DIR="${TEST_TMP_DIR}/.claude/specs"

  mkdir -p "${TEST_SPECS_DIR}"

  # Create sample error log entries
  cat > "$TEST_ERROR_LOG" << 'EOF'
{"timestamp":"2025-11-20T10:00:00Z","environment":"production","command":"/build","workflow_id":"build_001","user_args":"plan.md","error_type":"execution_error","error_message":"Bash error at line 100: exit code 1","source":"bash_trap","stack":["100 main script.sh"],"context":{"line":100,"exit_code":1}}
{"timestamp":"2025-11-20T10:05:00Z","environment":"production","command":"/build","workflow_id":"build_002","user_args":"plan.md","error_type":"execution_error","error_message":"Bash error at line 100: exit code 1","source":"bash_trap","stack":["100 main script.sh"],"context":{"line":100,"exit_code":1}}
{"timestamp":"2025-11-20T10:10:00Z","environment":"production","command":"/plan","workflow_id":"plan_001","user_args":"feature desc","error_type":"agent_error","error_message":"Agent failed to complete","source":"bash_block_1","stack":[],"context":{}}
{"timestamp":"2025-11-20T10:15:00Z","environment":"production","command":"/build","workflow_id":"build_003","user_args":"plan.md","error_type":"state_error","error_message":"State file not found","source":"bash_block_2","stack":[],"context":{"path":"/missing/state.sh"}}
{"timestamp":"2025-11-20T10:20:00Z","environment":"production","command":"/repair","workflow_id":"repair_001","user_args":"--command /build","error_type":"validation_error","error_message":"Invalid argument","source":"bash_block_1","stack":[],"context":{}}
EOF

  export TEST_ERROR_LOG
  export TEST_SPECS_DIR
  export CLAUDE_PROJECT_DIR="$PROJECT_ROOT"
}

# Cleanup test environment
cleanup_test_env() {
  if [ -n "${TEST_TMP_DIR:-}" ] && [ -d "$TEST_TMP_DIR" ]; then
    rm -rf "$TEST_TMP_DIR"
  fi
}

# Test: errors-analyst agent file exists
test_agent_exists() {
  local test_name="errors-analyst agent file exists"
  TEST_COUNT=$((TEST_COUNT + 1))

  if [ -f "${PROJECT_ROOT}/.claude/agents/errors-analyst.md" ]; then
    echo "✓ PASS: $test_name"
    PASS_COUNT=$((PASS_COUNT + 1))
    return 0
  else
    echo "✗ FAIL: $test_name - Agent file not found"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi
}

# Test: errors-analyst agent has correct frontmatter
test_agent_frontmatter() {
  local test_name="errors-analyst agent frontmatter"
  TEST_COUNT=$((TEST_COUNT + 1))

  local agent_file="${PROJECT_ROOT}/.claude/agents/errors-analyst.md"

  if ! grep -q "model: claude-3-5-haiku-20241022" "$agent_file"; then
    echo "✗ FAIL: $test_name - Missing or incorrect model field"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  if ! grep -q "allowed-tools: Read, Write, Grep, Glob, Bash" "$agent_file"; then
    echo "✗ FAIL: $test_name - Missing or incorrect allowed-tools"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  echo "✓ PASS: $test_name"
  PASS_COUNT=$((PASS_COUNT + 1))
  return 0
}

# Test: errors-analyst agent has 4-step process
test_agent_process() {
  local test_name="errors-analyst agent 4-step process"
  TEST_COUNT=$((TEST_COUNT + 1))

  local agent_file="${PROJECT_ROOT}/.claude/agents/errors-analyst.md"

  if ! grep -q "### STEP 1" "$agent_file"; then
    echo "✗ FAIL: $test_name - Missing STEP 1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  if ! grep -q "### STEP 2" "$agent_file"; then
    echo "✗ FAIL: $test_name - Missing STEP 2"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  if ! grep -q "### STEP 3" "$agent_file"; then
    echo "✗ FAIL: $test_name - Missing STEP 3"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  if ! grep -q "### STEP 4" "$agent_file"; then
    echo "✗ FAIL: $test_name - Missing STEP 4"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  echo "✓ PASS: $test_name"
  PASS_COUNT=$((PASS_COUNT + 1))
  return 0
}

# Test: errors-analyst agent has 28 completion criteria
test_agent_completion_criteria() {
  local test_name="errors-analyst agent 28 completion criteria"
  TEST_COUNT=$((TEST_COUNT + 1))

  local agent_file="${PROJECT_ROOT}/.claude/agents/errors-analyst.md"

  # Count checklist items (lines starting with "- [ ] N.")
  local criteria_count=$(grep -cP '^\s*-\s*\[\s*\]\s*\d+\.' "$agent_file" || echo "0")

  if [ "$criteria_count" -ge 28 ]; then
    echo "✓ PASS: $test_name (found $criteria_count criteria)"
    PASS_COUNT=$((PASS_COUNT + 1))
    return 0
  else
    echo "✗ FAIL: $test_name - Found $criteria_count criteria, expected 28"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi
}

# Test: /errors command updated frontmatter
test_command_frontmatter() {
  local test_name="/errors command frontmatter updated"
  TEST_COUNT=$((TEST_COUNT + 1))

  local cmd_file="${PROJECT_ROOT}/.claude/commands/errors.md"

  if ! grep -q "dependent-agents:" "$cmd_file"; then
    echo "✗ FAIL: $test_name - Missing dependent-agents field"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  if ! grep -q "errors-analyst" "$cmd_file"; then
    echo "✗ FAIL: $test_name - Missing errors-analyst in dependent-agents"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  if ! grep -q "allowed-tools: Task" "$cmd_file"; then
    echo "✗ FAIL: $test_name - Missing Task in allowed-tools"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  echo "✓ PASS: $test_name"
  PASS_COUNT=$((PASS_COUNT + 1))
  return 0
}

# Test: /errors command has --query flag
test_command_query_flag() {
  local test_name="/errors command --query flag support"
  TEST_COUNT=$((TEST_COUNT + 1))

  local cmd_file="${PROJECT_ROOT}/.claude/commands/errors.md"

  if ! grep -q "QUERY_MODE" "$cmd_file"; then
    echo "✗ FAIL: $test_name - Missing QUERY_MODE variable"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  if ! grep -q "\-\-query)" "$cmd_file"; then
    echo "✗ FAIL: $test_name - Missing --query case statement"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  echo "✓ PASS: $test_name"
  PASS_COUNT=$((PASS_COUNT + 1))
  return 0
}

# Test: /errors command has dual mode logic
test_command_dual_mode() {
  local test_name="/errors command dual mode logic"
  TEST_COUNT=$((TEST_COUNT + 1))

  local cmd_file="${PROJECT_ROOT}/.claude/commands/errors.md"

  if ! grep -q "QUERY MODE (LEGACY BEHAVIOR)" "$cmd_file"; then
    echo "✗ FAIL: $test_name - Missing query mode section"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  if ! grep -q "REPORT GENERATION MODE (DEFAULT)" "$cmd_file"; then
    echo "✗ FAIL: $test_name - Missing report mode section"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  echo "✓ PASS: $test_name"
  PASS_COUNT=$((PASS_COUNT + 1))
  return 0
}

# Test: agent-reference.md updated
test_agent_reference() {
  local test_name="agent-reference.md includes errors-analyst"
  TEST_COUNT=$((TEST_COUNT + 1))

  local ref_file="${PROJECT_ROOT}/.claude/docs/reference/standards/agent-reference.md"

  if ! grep -q "### errors-analyst" "$ref_file"; then
    echo "✗ FAIL: $test_name - Missing errors-analyst section"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  if ! grep -q "claude-3-5-haiku-20241022" "$ref_file"; then
    echo "✗ FAIL: $test_name - Missing model specification"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  echo "✓ PASS: $test_name"
  PASS_COUNT=$((PASS_COUNT + 1))
  return 0
}

# Test: command-reference.md updated
test_command_reference() {
  local test_name="command-reference.md includes report mode"
  TEST_COUNT=$((TEST_COUNT + 1))

  local ref_file="${PROJECT_ROOT}/.claude/docs/reference/standards/command-reference.md"

  if ! grep -q "Report Mode" "$ref_file"; then
    echo "✗ FAIL: $test_name - Missing Report Mode documentation"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  if ! grep -q "errors-analyst" "$ref_file"; then
    echo "✗ FAIL: $test_name - Missing errors-analyst reference"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  echo "✓ PASS: $test_name"
  PASS_COUNT=$((PASS_COUNT + 1))
  return 0
}

# Test: errors-command-guide.md updated
test_errors_guide() {
  local test_name="errors-command-guide.md includes report generation"
  TEST_COUNT=$((TEST_COUNT + 1))

  local guide_file="${PROJECT_ROOT}/.claude/docs/guides/commands/errors-command-guide.md"

  if ! grep -q "Report Generation (Default Mode)" "$guide_file"; then
    echo "✗ FAIL: $test_name - Missing report generation section"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  if ! grep -q "Agent Delegation" "$guide_file"; then
    echo "✗ FAIL: $test_name - Missing agent delegation documentation"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  echo "✓ PASS: $test_name"
  PASS_COUNT=$((PASS_COUNT + 1))
  return 0
}

# Test: Backward compatibility - query mode preserved
test_backward_compatibility() {
  local test_name="backward compatibility with query mode"
  TEST_COUNT=$((TEST_COUNT + 1))

  local cmd_file="${PROJECT_ROOT}/.claude/commands/errors.md"

  # Check that query_errors function is still called in query mode
  if ! grep -q "query_errors" "$cmd_file"; then
    echo "✗ FAIL: $test_name - Missing query_errors function calls"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  # Check that recent_errors function is still available
  if ! grep -q "recent_errors" "$cmd_file"; then
    echo "✗ FAIL: $test_name - Missing recent_errors function call"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  echo "✓ PASS: $test_name"
  PASS_COUNT=$((PASS_COUNT + 1))
  return 0
}

# Test: Report structure requirements
test_report_structure() {
  local test_name="report structure requirements in agent"
  TEST_COUNT=$((TEST_COUNT + 1))

  local agent_file="${PROJECT_ROOT}/.claude/agents/errors-analyst.md"

  # Check for required report sections
  if ! grep -q "## Metadata" "$agent_file"; then
    echo "✗ FAIL: $test_name - Missing Metadata section"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  if ! grep -q "## Executive Summary" "$agent_file"; then
    echo "✗ FAIL: $test_name - Missing Executive Summary section"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  if ! grep -q "## Error Overview" "$agent_file"; then
    echo "✗ FAIL: $test_name - Missing Error Overview section"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  if ! grep -q "## Top Errors by Frequency" "$agent_file"; then
    echo "✗ FAIL: $test_name - Missing Top Errors section"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  if ! grep -q "## Error Distribution" "$agent_file"; then
    echo "✗ FAIL: $test_name - Missing Error Distribution section"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  if ! grep -q "## Recommendations" "$agent_file"; then
    echo "✗ FAIL: $test_name - Missing Recommendations section"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  echo "✓ PASS: $test_name"
  PASS_COUNT=$((PASS_COUNT + 1))
  return 0
}

# Run all tests
run_tests() {
  echo "======================================"
  echo "Test Suite: $TEST_SUITE"
  echo "======================================"
  echo ""

  setup_test_env

  # Agent tests
  test_agent_exists
  test_agent_frontmatter
  test_agent_process
  test_agent_completion_criteria
  test_report_structure

  # Command tests
  test_command_frontmatter
  test_command_query_flag
  test_command_dual_mode
  test_backward_compatibility

  # Documentation tests
  test_agent_reference
  test_command_reference
  test_errors_guide

  cleanup_test_env

  echo ""
  echo "======================================"
  echo "Test Results"
  echo "======================================"
  echo "Total Tests: $TEST_COUNT"
  echo "Passed: $PASS_COUNT"
  echo "Failed: $FAIL_COUNT"
  echo ""

  if [ $FAIL_COUNT -eq 0 ]; then
    echo "All tests passed!"
    return 0
  else
    echo "Some tests failed."
    return 1
  fi
}

# Execute tests
run_tests
exit $?
