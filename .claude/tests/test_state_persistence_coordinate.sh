#!/usr/bin/env bash
# Test state persistence for coordinate command variables
# Validates that all cross-block variables are correctly persisted

set -euo pipefail

CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"

# Test initialization
STATE_FILE=$(init_workflow_state "test_$$")
trap "rm -f '$STATE_FILE'" EXIT

echo "Test 1: Basic state persistence"
append_workflow_state "TEST_VAR" "test_value"
if grep -q "^export TEST_VAR=\"test_value\"" "$STATE_FILE"; then
  echo "✓ PASS: Basic persistence works"
else
  echo "✗ FAIL: Basic persistence failed"
  exit 1
fi

echo "Test 2: USE_HIERARCHICAL_RESEARCH persistence"
append_workflow_state "USE_HIERARCHICAL_RESEARCH" "false"
if grep -q "^export USE_HIERARCHICAL_RESEARCH=" "$STATE_FILE"; then
  echo "✓ PASS: USE_HIERARCHICAL_RESEARCH persisted"
else
  echo "✗ FAIL: USE_HIERARCHICAL_RESEARCH not persisted"
  exit 1
fi

echo "Test 3: RESEARCH_COMPLEXITY persistence"
append_workflow_state "RESEARCH_COMPLEXITY" "3"
if grep -q "^export RESEARCH_COMPLEXITY=" "$STATE_FILE"; then
  echo "✓ PASS: RESEARCH_COMPLEXITY persisted"
else
  echo "✗ FAIL: RESEARCH_COMPLEXITY not persisted"
  exit 1
fi

echo "Test 4: WORKFLOW_SCOPE persistence"
append_workflow_state "WORKFLOW_SCOPE" "research-only"
if grep -q "^export WORKFLOW_SCOPE=" "$STATE_FILE"; then
  echo "✓ PASS: WORKFLOW_SCOPE persisted"
else
  echo "✗ FAIL: WORKFLOW_SCOPE not persisted"
  exit 1
fi

echo "Test 5: Load workflow state"
# Clear current environment
unset TEST_VAR USE_HIERARCHICAL_RESEARCH RESEARCH_COMPLEXITY WORKFLOW_SCOPE 2>/dev/null || true

# Load state
WORKFLOW_ID="test_$$"
load_workflow_state "$WORKFLOW_ID"

# Verify variables loaded
if [ "${TEST_VAR:-}" = "test_value" ]; then
  echo "✓ PASS: State loaded correctly (TEST_VAR)"
else
  echo "✗ FAIL: State not loaded correctly (TEST_VAR=${TEST_VAR:-unset})"
  exit 1
fi

if [ "${USE_HIERARCHICAL_RESEARCH:-}" = "false" ]; then
  echo "✓ PASS: State loaded correctly (USE_HIERARCHICAL_RESEARCH)"
else
  echo "✗ FAIL: State not loaded correctly (USE_HIERARCHICAL_RESEARCH=${USE_HIERARCHICAL_RESEARCH:-unset})"
  exit 1
fi

echo ""
echo "All state persistence tests passed (5/5)"
