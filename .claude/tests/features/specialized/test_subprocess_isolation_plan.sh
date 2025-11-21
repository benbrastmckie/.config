#!/usr/bin/env bash
# test_subprocess_isolation_plan.sh
# Regression test for bash block variable scope in /plan command
#
# This test verifies that variables set in Part 3 (research phase) are correctly
# persisted and restored in Part 4 (planning phase) and Part 5 (completion).
#
# Expected behavior:
# - SPECS_DIR, RESEARCH_DIR, PLANS_DIR, TOPIC_SLUG, REPORT_COUNT set in Part 3
# - All variables correctly restored in Part 4 via load_workflow_state
# - All variables correctly restored in Part 5 via load_workflow_state
# - Completion summary shows populated values (not empty)
#
# Success criteria:
# - 100% variable restoration accuracy across bash blocks
# - No empty values in completion summary
#
# Usage:
#   bash /home/benjamin/.config/.claude/tests/test_subprocess_isolation_plan.sh

set -euo pipefail

# Detect project directory
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  echo "ERROR: Not in a git repository"
  exit 1
fi

export CLAUDE_PROJECT_DIR

# Source state-persistence library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"

echo "=== Subprocess Isolation Test: /plan ==="
echo ""

# Simulate Part 3: Set variables and persist state
echo "Test 1: Simulating Part 3 (Research Phase)"
WORKFLOW_ID="test_plan_$$"
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
trap "rm -f '$STATE_FILE'" EXIT

# Simulate variables set in Part 3
SPECS_DIR="${CLAUDE_PROJECT_DIR}/.claude/specs/999_test_feature"
RESEARCH_DIR="${SPECS_DIR}/reports"
PLANS_DIR="${SPECS_DIR}/plans"
TOPIC_SLUG="test_feature"
REPORT_COUNT="3"

# Persist variables (as done in Part 3)
append_workflow_state "SPECS_DIR" "$SPECS_DIR"
append_workflow_state "RESEARCH_DIR" "$RESEARCH_DIR"
append_workflow_state "PLANS_DIR" "$PLANS_DIR"
append_workflow_state "TOPIC_SLUG" "$TOPIC_SLUG"
append_workflow_state "REPORT_COUNT" "$REPORT_COUNT"

echo "✓ Variables persisted to state file"
echo ""

# Simulate Part 4: Load state in new subprocess
echo "Test 2: Simulating Part 4 (Planning Phase - New Subprocess)"
(
  # Source library in subprocess (simulating new bash block)
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"

  # Load workflow state (as done in Part 4)
  load_workflow_state "$WORKFLOW_ID" false

  # Verify all variables restored
  if [ -z "${SPECS_DIR:-}" ]; then
    echo "✗ FAIL: SPECS_DIR not restored" >&2
    exit 1
  fi

  if [ -z "${RESEARCH_DIR:-}" ]; then
    echo "✗ FAIL: RESEARCH_DIR not restored" >&2
    exit 1
  fi

  if [ -z "${PLANS_DIR:-}" ]; then
    echo "✗ FAIL: PLANS_DIR not restored" >&2
    exit 1
  fi

  if [ -z "${TOPIC_SLUG:-}" ]; then
    echo "✗ FAIL: TOPIC_SLUG not restored" >&2
    exit 1
  fi

  if [ -z "${REPORT_COUNT:-}" ]; then
    echo "✗ FAIL: REPORT_COUNT not restored" >&2
    exit 1
  fi

  # Verify values match
  if [ "$SPECS_DIR" != "${CLAUDE_PROJECT_DIR}/.claude/specs/999_test_feature" ]; then
    echo "✗ FAIL: SPECS_DIR value mismatch" >&2
    exit 1
  fi

  if [ "$REPORT_COUNT" != "3" ]; then
    echo "✗ FAIL: REPORT_COUNT value mismatch" >&2
    exit 1
  fi

  echo "✓ All variables restored correctly in Part 4"

  # Persist PLAN_PATH for Part 5
  PLAN_PATH="${PLANS_DIR}/001_test_feature_plan.md"
  append_workflow_state "PLAN_PATH" "$PLAN_PATH"

  exit 0
)

if [ $? -ne 0 ]; then
  echo "✗ Test 2 FAILED" >&2
  exit 1
fi
echo ""

# Simulate Part 5: Load state in another new subprocess
echo "Test 3: Simulating Part 5 (Completion - New Subprocess)"
(
  # Source library in subprocess (simulating new bash block)
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"

  # Load workflow state (as done in Part 5)
  load_workflow_state "$WORKFLOW_ID" false

  # Verify all variables restored (including PLAN_PATH from Part 4)
  if [ -z "${SPECS_DIR:-}" ]; then
    echo "✗ FAIL: SPECS_DIR not restored in Part 5" >&2
    exit 1
  fi

  if [ -z "${REPORT_COUNT:-}" ]; then
    echo "✗ FAIL: REPORT_COUNT not restored in Part 5" >&2
    exit 1
  fi

  if [ -z "${PLAN_PATH:-}" ]; then
    echo "✗ FAIL: PLAN_PATH not restored in Part 5" >&2
    exit 1
  fi

  # Verify completion summary format (no empty values)
  if [ -z "$SPECS_DIR" ] || [ -z "$RESEARCH_DIR" ] || [ -z "$PLAN_PATH" ]; then
    echo "✗ FAIL: Completion summary would have empty values" >&2
    exit 1
  fi

  echo "✓ All variables restored correctly in Part 5"
  echo "✓ Completion summary format valid (no empty values)"

  # Display simulated completion summary
  echo ""
  echo "Simulated Completion Summary:"
  echo "  Workflow Type: research-and-plan"
  echo "  Specs Directory: $SPECS_DIR"
  echo "  Research Reports: $REPORT_COUNT reports in $RESEARCH_DIR"
  echo "  Implementation Plan: $PLAN_PATH"

  exit 0
)

if [ $? -ne 0 ]; then
  echo "✗ Test 3 FAILED" >&2
  exit 1
fi
echo ""

echo "=== All Tests Passed ==="
echo "✓ 100% variable restoration accuracy"
echo "✓ Completion summary format valid"
echo ""
exit 0
