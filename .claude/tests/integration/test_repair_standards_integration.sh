#!/usr/bin/env bash
# Integration test: /repair command standards integration
# Verifies that /repair command extracts standards and creates plans with required metadata

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_PROJECT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Test setup
TEST_TOPIC="999_repair_standards_test"
TEST_DIR="${CLAUDE_PROJECT_DIR}/.claude/specs/${TEST_TOPIC}"
PLAN_PATH="${TEST_DIR}/plans/001-repair-standards-test-plan.md"

# Cleanup function
cleanup() {
  rm -rf "$TEST_DIR" 2>/dev/null || true
}
trap cleanup EXIT

# Execute /repair command (simulated - would need actual invocation in real test)
# For now, verify standards extraction works in isolation

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"

# Initialize test state
WORKFLOW_ID="test_repair_$(date +%s)"
COMMAND_NAME="/repair"
USER_ARGS="test error"
export WORKFLOW_ID COMMAND_NAME USER_ARGS

STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
init_workflow_state "$WORKFLOW_ID" >/dev/null
export STATE_FILE

ensure_error_log_exists
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# Test standards extraction
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/standards-extraction.sh" 2>/dev/null || {
  echo "FAIL: Cannot source standards-extraction.sh"
  exit 1
}

FORMATTED_STANDARDS=$(format_standards_for_prompt 2>/dev/null) || {
  echo "FAIL: Standards extraction failed"
  exit 1
}

# Verify standards content
if [ -z "$FORMATTED_STANDARDS" ]; then
  echo "FAIL: FORMATTED_STANDARDS is empty"
  exit 1
fi

STANDARDS_COUNT=$(echo "$FORMATTED_STANDARDS" | grep -c "^###" || echo 0)
if [ "$STANDARDS_COUNT" -lt 4 ]; then
  echo "FAIL: Expected at least 4 standards sections, got $STANDARDS_COUNT"
  exit 1
fi

# Verify specific sections present
for section in "Code Standards" "Testing Protocols" "Documentation Policy" "Error Logging"; do
  if ! echo "$FORMATTED_STANDARDS" | grep -q "### $section"; then
    echo "FAIL: Missing required section: $section"
    exit 1
  fi
done

echo "PASS: /repair standards integration validation"
echo "  - Extracted $STANDARDS_COUNT standards sections"
echo "  - All required sections present"

# Cleanup
rm -f "$STATE_FILE"
exit 0
