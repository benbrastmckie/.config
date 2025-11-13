#!/usr/bin/env bash
# Test: sm_init exports persist via state persistence
# Validates: sm_init export persistence fix

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

# Source required libraries
if [ ! -f "${LIB_DIR}/workflow-state-machine.sh" ]; then
  echo "ERROR: workflow-state-machine.sh not found"
  exit 1
fi

if [ ! -f "${LIB_DIR}/state-persistence.sh" ]; then
  echo "ERROR: state-persistence.sh not found"
  exit 1
fi

source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

test_count=0
pass_count=0
fail_count=0

echo "=== Test: sm_init Export Persistence ==="
echo ""

# Setup test environment
TEST_WORKFLOW_ID="test_sm_init_$(date +%s)_$$"
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
export WORKFLOW_CLASSIFICATION_MODE="regex-only"

# Create temp directory
mkdir -p "${CLAUDE_PROJECT_DIR}/.claude/tmp"

# Test 1: sm_init variables exist immediately after call
echo "Test 1: sm_init sets variables in current subprocess..."
test_count=$((test_count + 1))

# Initialize workflow state
init_workflow_state "$TEST_WORKFLOW_ID" >/dev/null 2>&1 || true

# Call sm_init
sm_init "Research authentication patterns" "test_command" >/dev/null 2>&1

# Check if variables exist
if [[ -n "${WORKFLOW_SCOPE:-}" ]] && [[ -n "${RESEARCH_COMPLEXITY:-}" ]] && [[ -n "${RESEARCH_TOPICS_JSON:-}" ]]; then
  echo "PASS: All three variables set after sm_init"
  pass_count=$((pass_count + 1))
else
  echo "FAIL: Missing variables after sm_init"
  echo "  WORKFLOW_SCOPE=${WORKFLOW_SCOPE:-unset}"
  echo "  RESEARCH_COMPLEXITY=${RESEARCH_COMPLEXITY:-unset}"
  echo "  RESEARCH_TOPICS_JSON=${RESEARCH_TOPICS_JSON:-unset}"
  fail_count=$((fail_count + 1))
fi

# Test 2: Variables persist when saved to state file
echo ""
echo "Test 2: Variables persist via state persistence..."
test_count=$((test_count + 1))

# Save variables to state
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"
append_workflow_state "RESEARCH_TOPICS_JSON" "$RESEARCH_TOPICS_JSON"

# Clear variables to simulate subprocess boundary
unset WORKFLOW_SCOPE RESEARCH_COMPLEXITY RESEARCH_TOPICS_JSON

# Load state (simulates new bash block)
load_workflow_state "$TEST_WORKFLOW_ID" >/dev/null 2>&1

# Check if variables restored
if [[ -n "${WORKFLOW_SCOPE:-}" ]] && [[ -n "${RESEARCH_COMPLEXITY:-}" ]] && [[ -n "${RESEARCH_TOPICS_JSON:-}" ]]; then
  echo "PASS: All three variables restored from state"
  pass_count=$((pass_count + 1))
else
  echo "FAIL: Missing variables after state load"
  echo "  WORKFLOW_SCOPE=${WORKFLOW_SCOPE:-unset}"
  echo "  RESEARCH_COMPLEXITY=${RESEARCH_COMPLEXITY:-unset}"
  echo "  RESEARCH_TOPICS_JSON=${RESEARCH_TOPICS_JSON:-unset}"
  fail_count=$((fail_count + 1))
fi

# Test 3: State file contains all three variables
echo ""
echo "Test 3: State file contains all required variables..."
test_count=$((test_count + 1))

STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${TEST_WORKFLOW_ID}.sh"

if [ ! -f "$STATE_FILE" ]; then
  echo "FAIL: State file not found: $STATE_FILE"
  fail_count=$((fail_count + 1))
else
  missing_vars=()
  grep -q "WORKFLOW_SCOPE=" "$STATE_FILE" || missing_vars+=("WORKFLOW_SCOPE")
  grep -q "RESEARCH_COMPLEXITY=" "$STATE_FILE" || missing_vars+=("RESEARCH_COMPLEXITY")
  grep -q "RESEARCH_TOPICS_JSON=" "$STATE_FILE" || missing_vars+=("RESEARCH_TOPICS_JSON")

  if [ ${#missing_vars[@]} -eq 0 ]; then
    echo "PASS: State file contains all three variables"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: State file missing variables: ${missing_vars[*]}"
    echo "State file contents:"
    cat "$STATE_FILE"
    fail_count=$((fail_count + 1))
  fi
fi

# Cleanup
rm -f "$STATE_FILE" 2>/dev/null || true

# Summary
echo ""
echo "=== Test Summary ==="
echo "Tests run: $test_count"
echo "Tests passed: $pass_count"
echo "Tests failed: $fail_count"

if [ "$fail_count" -gt 0 ]; then
  echo ""
  echo "TEST_FAILED"
  exit 1
else
  echo ""
  echo "TEST_PASSED"
  exit 0
fi
