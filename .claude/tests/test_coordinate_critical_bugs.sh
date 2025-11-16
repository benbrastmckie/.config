#!/usr/bin/env bash
# Regression tests for Spec 683 coordinate critical bug fixes
# Test file: test_coordinate_critical_bugs.sh
# Reference: test_coordinate_error_fixes.sh (existing pattern)

set -euo pipefail

# Standard test initialization
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Standard test output functions (matches run_all_tests.sh format)
pass() { echo "✓ PASS: $1"; }
fail() { echo "✗ FAIL: $1"; return 1; }

echo "=== Testing Coordinate Critical Bug Fixes (Spec 683) ==="

# Test 1: sm_init export behavior (Bug #1 fix)
echo "Test 1: sm_init exports to parent shell"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
sm_init "test workflow" "coordinate" >/dev/null 2>&1
[ -n "$WORKFLOW_SCOPE" ] && pass "WORKFLOW_SCOPE exported" || fail "WORKFLOW_SCOPE not exported"
[ -n "$RESEARCH_COMPLEXITY" ] && pass "RESEARCH_COMPLEXITY exported" || fail "RESEARCH_COMPLEXITY not exported"

# Test 2: JSON escaping in state files (Bug #2 fix)
echo "Test 2: JSON escaping in workflow state"
WORKFLOW_ID="test_$$"
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
append_workflow_state "TEST_JSON" '["Topic 1","Topic 2"]'
bash -n "$STATE_FILE" && pass "State file syntax valid" || fail "State file has syntax errors"
rm -f "$STATE_FILE"

# Test 3: Descriptive topic names (Bug #3 fix)
echo "Test 3: Descriptive topic generation"
WORKFLOW_DESC="I implemented plan .claude/specs/678_coordinate/plans/001.md and want to revise .claude/specs/677_agent/plans/001.md"
sm_init "$WORKFLOW_DESC" "coordinate" >/dev/null 2>&1
# Check if topics are NOT generic (no "Topic N" pattern)
if echo "$RESEARCH_TOPICS_JSON" | jq -e '.[] | select(test("^Topic [0-9]+$"))' >/dev/null 2>&1; then
  fail "Topics still generic (Bug #3 not yet fixed)"
else
  pass "Topics descriptive"
fi

# Test 4: Topic directory for research-and-revise (Bug #4 fix)
echo "Test 4: research-and-revise topic directory"
export EXISTING_PLAN_PATH="/home/benjamin/.config/.claude/specs/678_coordinate_haiku_classification/plans/001_comprehensive_classification_implementation.md"
if [ -f "$EXISTING_PLAN_PATH" ]; then
  source .claude/lib/workflow-initialization.sh
  initialize_workflow_paths "revise plan" "research-and-revise" 2 2>/dev/null
  [[ "$TOPIC_PATH" == *"678_coordinate"* ]] && pass "Topic directory reused" || fail "Topic directory not reused"
else
  echo "⊘ SKIP: Test plan file not found (cannot test Bug #4 fix)"
fi

# Test 5: research-and-revise scope in research phase transition (Spec 684 Phase 1)
echo "Test 5: research-and-revise in research phase case statements"
# Verify research-and-revise appears in both research phase case statements
COORDINATE_FILE=".claude/commands/coordinate.md"
if [ -f "$COORDINATE_FILE" ]; then
  # Check "Next Action" display (around line 876)
  if grep -A 20 "echo \"  Next Action:\"" "$COORDINATE_FILE" | grep -q "research-and-revise)"; then
    pass "research-and-revise in research phase 'Next Action' display"
  else
    fail "research-and-revise missing from research phase 'Next Action' display"
  fi

  # Check state transition case pattern (around line 900)
  if grep -A 1 "research-and-plan|research-and-revise|full-implementation|debug-only)" "$COORDINATE_FILE" | grep -q "Continue to planning"; then
    pass "research-and-revise in research phase state transition"
  else
    fail "research-and-revise missing from research phase state transition"
  fi
else
  fail "coordinate.md not found"
fi

# Test 6: research-and-revise scope in planning phase transition (Spec 684 Phase 2)
echo "Test 6: research-and-revise in planning phase case statements"
if [ -f "$COORDINATE_FILE" ]; then
  # Check "Next Action" display in planning phase (around line 1311)
  if grep -B 5 "Terminal state (revision complete)" "$COORDINATE_FILE" | grep -q "research-and-revise)"; then
    pass "research-and-revise in planning phase 'Next Action' display"
  else
    fail "research-and-revise missing from planning phase 'Next Action' display"
  fi

  # Check terminal state case pattern (around line 1326)
  if grep -A 1 "research-and-plan|research-and-revise)" "$COORDINATE_FILE" | grep -q "Terminal state reached"; then
    pass "research-and-revise in planning phase terminal state"
  else
    fail "research-and-revise missing from planning phase terminal state"
  fi
else
  fail "coordinate.md not found"
fi

# Test 7: Completeness of workflow scope coverage
echo "Test 7: Complete workflow scope coverage"
if [ -f "$COORDINATE_FILE" ]; then
  # Count occurrences of research-and-revise in coordinate.md
  OCCURRENCE_COUNT=$(grep -c "research-and-revise" "$COORDINATE_FILE" || echo 0)
  if [ "$OCCURRENCE_COUNT" -ge 6 ]; then
    pass "research-and-revise appears $OCCURRENCE_COUNT times (≥6)"
  else
    fail "research-and-revise appears only $OCCURRENCE_COUNT times (<6)"
  fi
else
  fail "coordinate.md not found"
fi

echo "=== All Tests Complete ==="
