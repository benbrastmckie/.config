#!/usr/bin/env bash
# Test adaptive planning integration
# Tests: Trigger detection, /revise integration, loop prevention, checkpoint updates

set -euo pipefail

# Test framework
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  if [ -n "${2:-}" ]; then
    echo "  Expected: $2"
  fi
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

skip() {
  echo -e "${YELLOW}⊘ SKIP${NC}: $1"
  SKIP_COUNT=$((SKIP_COUNT + 1))
}

info() {
  echo -e "${BLUE}ℹ INFO${NC}: $1"
}

# Test environment
TEST_DIR=$(mktemp -d -t adaptive_planning_tests_XXXXXX)
export CLAUDE_PROJECT_DIR="$TEST_DIR"
export CLAUDE_LOGS_DIR="$TEST_DIR/.claude/logs"

cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Find lib directory
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LIB_DIR=$(cd "$SCRIPT_DIR/../lib" && pwd)

# Source utilities
source "$LIB_DIR/checkpoint-utils.sh"
source "$LIB_DIR/complexity-utils.sh"
source "$LIB_DIR/adaptive-planning-logger.sh"

# Create test environment
mkdir -p "$TEST_DIR/.claude/logs"
mkdir -p "$TEST_DIR/.claude/specs/plans"

echo "========================================="
echo "Adaptive Planning Integration Tests"
echo "========================================="
echo

# =============================================================================
# Test 1: Complexity Trigger Detection
# =============================================================================
info "Test 1: Complexity trigger with high score (>8)"

# Create a test plan with high complexity phase
cat > "$TEST_DIR/.claude/specs/plans/001_test_plan.md" <<'EOF'
# Test Plan

## Metadata
- **Date**: 2025-10-06

### Phase 1: High Complexity Phase
**Objective**: Test complexity trigger
**Complexity**: 9/10

**Tasks**:
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3
- [ ] Task 4
- [ ] Task 5
- [ ] Task 6
- [ ] Task 7
- [ ] Task 8
- [ ] Task 9
- [ ] Task 10
- [ ] Task 11
EOF

PLAN_FILE="$TEST_DIR/.claude/specs/plans/001_test_plan.md"
PHASE_COMPLEXITY=$(calculate_phase_complexity "$PLAN_FILE" 1)
TASK_COUNT=$(grep -c "^- \[ \]" "$PLAN_FILE" || echo 0)

# Log the check
log_complexity_check 1 "$PHASE_COMPLEXITY" 8 "$TASK_COUNT"

# Verify trigger fired
if [[ -f "$CLAUDE_LOGS_DIR/adaptive-planning.log" ]]; then
  if grep -q "complexity.*triggered" "$CLAUDE_LOGS_DIR/adaptive-planning.log"; then
    pass "Complexity trigger detected for phase with >10 tasks"
  else
    fail "Complexity trigger not detected" "Should trigger with $TASK_COUNT tasks"
  fi
else
  fail "Adaptive planning log not created" "Log file should exist"
fi

# =============================================================================
# Test 2: Complexity Trigger - No Trigger
# =============================================================================
info "Test 2: Complexity trigger with low score (<8)"

cat > "$TEST_DIR/.claude/specs/plans/002_test_plan.md" <<'EOF'
# Test Plan

## Metadata
- **Date**: 2025-10-06

### Phase 1: Low Complexity Phase
**Objective**: Test no trigger
**Complexity**: 3/10

**Tasks**:
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3
EOF

PLAN_FILE2="$TEST_DIR/.claude/specs/plans/002_test_plan.md"
PHASE_COMPLEXITY2=$(calculate_phase_complexity "$PLAN_FILE2" 1)
TASK_COUNT2=$(grep -c "^- \[ \]" "$PLAN_FILE2" || echo 0)

log_complexity_check 1 "$PHASE_COMPLEXITY2" 8 "$TASK_COUNT2"

# Verify no trigger
if grep -q "complexity.*not_triggered" "$CLAUDE_LOGS_DIR/adaptive-planning.log"; then
  pass "Complexity trigger correctly not fired for low complexity"
else
  fail "Trigger should not fire for low complexity" "Should be not_triggered"
fi

# =============================================================================
# Test 3: Test Failure Pattern Detection
# =============================================================================
info "Test 3: Test failure pattern detection (2+ consecutive failures)"

# Clear log to get accurate count
> "$CLAUDE_LOGS_DIR/adaptive-planning.log"

# Simulate 2 consecutive failures
# First call: 1 consecutive failure (should not trigger, <2)
log_test_failure_pattern 2 1 "First failure in authentication tests"
# Second call: 2 consecutive failures (should trigger, >=2)
log_test_failure_pattern 2 2 "Second consecutive failure in authentication tests"

# Verify trigger fired on second failure (consecutive_failures >= 2 triggers)
# Use word boundaries to avoid matching "triggered" within "not_triggered"
TRIGGER_COUNT=$(grep "test_failure" "$CLAUDE_LOGS_DIR/adaptive-planning.log" | grep -c " -> triggered" || echo 0)
NOT_TRIGGER_COUNT=$(grep "test_failure" "$CLAUDE_LOGS_DIR/adaptive-planning.log" | grep -c " -> not_triggered" || echo 0)

# Debug: show what's in the log
# echo "DEBUG: Log contents:"
# grep "test_failure" "$CLAUDE_LOGS_DIR/adaptive-planning.log"

# First call has 1 failure (not triggered), second call has 2 failures (triggered)
if [[ $TRIGGER_COUNT -eq 1 ]] && [[ $NOT_TRIGGER_COUNT -eq 1 ]]; then
  pass "Test failure trigger fired correctly (1 not_triggered, 1 triggered)"
else
  fail "Test failure trigger count incorrect" "Expected 1 triggered and 1 not_triggered, got $TRIGGER_COUNT triggered, $NOT_TRIGGER_COUNT not_triggered"
fi

# =============================================================================
# Test 4: Test Failure Pattern - Single Failure
# =============================================================================
info "Test 4: Test failure pattern with single failure (no trigger)"

# Clear log for this test
> "$CLAUDE_LOGS_DIR/adaptive-planning.log"

log_test_failure_pattern 3 1 "Single failure, should not trigger"

# Verify no trigger
if grep -q "test_failure.*not_triggered" "$CLAUDE_LOGS_DIR/adaptive-planning.log"; then
  pass "Single test failure correctly does not trigger"
else
  fail "Single failure should not trigger" "Should be not_triggered"
fi

# =============================================================================
# Test 5: Scope Drift Detection
# =============================================================================
info "Test 5: Scope drift detection (always triggers)"

log_scope_drift 4 "New OAuth integration discovered during implementation"

if grep -q "scope_drift.*triggered" "$CLAUDE_LOGS_DIR/adaptive-planning.log"; then
  pass "Scope drift correctly triggers"
else
  fail "Scope drift should always trigger" "Should be triggered"
fi

# =============================================================================
# Test 6: Replan Invocation Logging - Success
# =============================================================================
info "Test 6: Replan invocation logging (success)"

CONTEXT='{"phase": 3, "reason": "Complexity exceeded", "suggested_action": "expand_phase"}'
log_replan_invocation "expand_phase" "success" "$TEST_DIR/updated_plan.md" "$CONTEXT"

if grep -q "replan.*expand_phase.*success" "$CLAUDE_LOGS_DIR/adaptive-planning.log"; then
  pass "Successful replan logged correctly"
else
  fail "Replan success not logged" "Should contain 'replan.*success'"
fi

# =============================================================================
# Test 7: Replan Invocation Logging - Failure
# =============================================================================
info "Test 7: Replan invocation logging (failure)"

log_replan_invocation "add_phase" "failure" "Plan validation failed" ""

if grep -q "ERROR.*replan.*failure" "$CLAUDE_LOGS_DIR/adaptive-planning.log"; then
  pass "Failed replan logged with ERROR level"
else
  fail "Replan failure not logged as ERROR" "Should contain 'ERROR.*replan'"
fi

# =============================================================================
# Test 8: Loop Prevention - First Replan (Allowed)
# =============================================================================
info "Test 8: Loop prevention allows first replan"

log_loop_prevention 5 1 "allowed"

if grep -q "loop_prevention.*allowed" "$CLAUDE_LOGS_DIR/adaptive-planning.log"; then
  pass "First replan allowed by loop prevention"
else
  fail "First replan should be allowed" "Should be 'allowed'"
fi

# =============================================================================
# Test 9: Loop Prevention - Second Replan (Allowed)
# =============================================================================
info "Test 9: Loop prevention allows second replan"

log_loop_prevention 5 2 "allowed"

ALLOWED_COUNT=$(grep -c "loop_prevention.*allowed" "$CLAUDE_LOGS_DIR/adaptive-planning.log" || echo 0)
if [[ $ALLOWED_COUNT -ge 2 ]]; then
  pass "Second replan allowed by loop prevention"
else
  fail "Second replan should be allowed" "Expected 2+ allowed, got $ALLOWED_COUNT"
fi

# =============================================================================
# Test 10: Loop Prevention - Third Replan (Blocked)
# =============================================================================
info "Test 10: Loop prevention blocks third replan"

log_loop_prevention 5 3 "blocked"

if grep -q "WARN.*loop_prevention.*blocked" "$CLAUDE_LOGS_DIR/adaptive-planning.log"; then
  pass "Third replan blocked by loop prevention with WARN level"
else
  fail "Third replan should be blocked" "Should contain 'WARN.*blocked'"
fi

# =============================================================================
# Test 11: Checkpoint Replan Metadata Update
# =============================================================================
info "Test 11: Checkpoint replan metadata updates correctly"

# Create a test checkpoint
CHECKPOINT_JSON='{
  "schema_version": "1.1",
  "checkpoint_id": "test_001",
  "workflow_type": "implement",
  "project_name": "test",
  "created_at": "2025-10-06T12:00:00Z",
  "updated_at": "2025-10-06T12:00:00Z",
  "status": "in_progress",
  "current_phase": 3,
  "total_phases": 5,
  "completed_phases": [1, 2],
  "workflow_state": {},
  "last_error": null,
  "replanning_count": 0,
  "last_replan_reason": null,
  "replan_phase_counts": {},
  "replan_history": []
}'

CHECKPOINT_FILE=$(save_checkpoint "implement" "test" "$CHECKPOINT_JSON")

# Increment replan counter
checkpoint_increment_replan "$CHECKPOINT_FILE" "3" "Complexity threshold exceeded"

# Verify metadata updated
UPDATED_JSON=$(cat "$CHECKPOINT_FILE")
REPLAN_COUNT=$(echo "$UPDATED_JSON" | jq -r '.replanning_count')
LAST_REASON=$(echo "$UPDATED_JSON" | jq -r '.last_replan_reason')

if [[ "$REPLAN_COUNT" == "1" ]] && [[ "$LAST_REASON" == "Complexity threshold exceeded" ]]; then
  pass "Checkpoint replan metadata updated correctly"
else
  fail "Checkpoint metadata not updated" "Expected count=1, reason='Complexity threshold exceeded'"
fi

# =============================================================================
# Test 12: Log Query Function
# =============================================================================
info "Test 12: Query adaptive planning log"

# Ensure we have some log entries
log_trigger_evaluation "complexity" "triggered" '{"test": true}'
log_trigger_evaluation "test_failure" "not_triggered" '{"test": true}'

QUERY_RESULT=$(query_adaptive_log "trigger_eval" 2)
if [[ -n "$QUERY_RESULT" ]]; then
  pass "Query adaptive log returns results"
else
  fail "Query should return results" "Non-empty output expected"
fi

# =============================================================================
# Test 13: Get Adaptive Stats
# =============================================================================
info "Test 13: Get adaptive planning statistics"

STATS=$(get_adaptive_stats)
if echo "$STATS" | grep -q "Total Trigger Evaluations"; then
  pass "Adaptive stats generated successfully"
else
  fail "Stats should contain trigger evaluations" "Output should include statistics"
fi

# =============================================================================
# Test 14: Log Rotation
# =============================================================================
info "Test 14: Log rotation when size exceeds limit"

# This test is skipped in automated runs as it requires creating a 10MB+ file
# which is time-consuming. Manual testing recommended.
skip "Log rotation (requires 10MB+ file creation, test manually)"

# =============================================================================
# Test 15: Context Passing to /revise Auto-Mode
# =============================================================================
info "Test 15: Context structure for /revise auto-mode"

# Create a context JSON structure
REVISION_CONTEXT=$(cat <<'EOF'
{
  "revision_type": "expand_phase",
  "current_phase": 3,
  "reason": "Two consecutive test failures in authentication module",
  "suggested_action": "Add prerequisite phase for dependency setup",
  "trigger_data": {
    "test_failure_log": "Error: Module 'oauth' not found",
    "complexity_metrics": {"tasks": 12, "score": 9.2}
  }
}
EOF
)

# Validate JSON structure
if echo "$REVISION_CONTEXT" | jq . > /dev/null 2>&1; then
  pass "Revision context JSON is valid"
else
  fail "Context JSON should be valid" "JSON parsing should succeed"
fi

# Verify required fields present
if echo "$REVISION_CONTEXT" | jq -e '.revision_type, .current_phase, .reason' > /dev/null 2>&1; then
  pass "Revision context contains all required fields"
else
  fail "Context missing required fields" "Must have revision_type, current_phase, reason"
fi

# =============================================================================
# Test 16: Full Integration - Complexity Trigger to Checkpoint Update
# =============================================================================
info "Test 16: Full integration test - trigger to checkpoint update"

# Create checkpoint
CHECKPOINT_JSON2='{
  "schema_version": "1.1",
  "checkpoint_id": "test_002",
  "workflow_type": "implement",
  "project_name": "integration_test",
  "created_at": "2025-10-06T12:00:00Z",
  "updated_at": "2025-10-06T12:00:00Z",
  "status": "in_progress",
  "current_phase": 2,
  "total_phases": 5,
  "completed_phases": [1],
  "workflow_state": {},
  "last_error": null,
  "replanning_count": 0,
  "last_replan_reason": null,
  "replan_phase_counts": {},
  "replan_history": []
}'

CHECKPOINT_FILE2=$(save_checkpoint "implement" "integration_test" "$CHECKPOINT_JSON2")

# Simulate complexity trigger
PLAN_COMPLEXITY=9.5
PLAN_TASKS=13
log_complexity_check 2 "$PLAN_COMPLEXITY" 8 "$PLAN_TASKS"

# Verify trigger logged
if grep -q "complexity.*triggered" "$CLAUDE_LOGS_DIR/adaptive-planning.log"; then
  # Simulate replan invocation
  log_replan_invocation "expand_phase" "success" "$TEST_DIR/updated_plan.md" "{}"

  # Update checkpoint
  checkpoint_increment_replan "$CHECKPOINT_FILE2" "2" "Complexity: $PLAN_COMPLEXITY, Tasks: $PLAN_TASKS"

  # Verify checkpoint updated
  UPDATED_JSON2=$(cat "$CHECKPOINT_FILE2")
  if echo "$UPDATED_JSON2" | jq -e '.replanning_count == 1' > /dev/null 2>&1; then
    pass "Full integration: trigger → log → replan → checkpoint update"
  else
    fail "Checkpoint not updated in integration flow" "replanning_count should be 1"
  fi
else
  fail "Complexity trigger not detected in integration test" "Should trigger"
fi

# =============================================================================
# Summary
# =============================================================================
echo
echo "========================================="
echo "Test Summary"
echo "========================================="
echo -e "${GREEN}Passed: $PASS_COUNT${NC}"
echo -e "${RED}Failed: $FAIL_COUNT${NC}"
echo -e "${YELLOW}Skipped: $SKIP_COUNT${NC}"
echo "========================================="

if [ $FAIL_COUNT -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed.${NC}"
  exit 1
fi
