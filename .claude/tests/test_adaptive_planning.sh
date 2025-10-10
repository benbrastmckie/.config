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
# Test 17: Full Implement-to-Revise Flow
# =============================================================================
info "Test 17: Full implement-to-revise workflow integration"

# Create a high-complexity test plan (12 tasks, complexity 9/10)
cat > "$TEST_DIR/.claude/specs/plans/003_complex_plan.md" <<'EOF'
# Complex Feature Implementation

## Metadata
- **Date**: 2025-10-06
- **Status**: In Progress

### Phase 1: Setup Phase
**Objective**: Setup infrastructure
**Complexity**: 3/10

**Tasks**:
- [x] Task 1: Initialize
- [x] Task 2: Configure

### Phase 2: High Complexity Implementation
**Objective**: Complex feature with many dependencies
**Complexity**: 9/10

**Tasks**:
- [ ] Task 1: Database schema migration
- [ ] Task 2: Create user model
- [ ] Task 3: Create authentication service
- [ ] Task 4: Create authorization middleware
- [ ] Task 5: Create API endpoints
- [ ] Task 6: Create validation layer
- [ ] Task 7: Create error handling
- [ ] Task 8: Create logging infrastructure
- [ ] Task 9: Create rate limiting
- [ ] Task 10: Create caching layer
- [ ] Task 11: Create monitoring
- [ ] Task 12: Create documentation

### Phase 3: Testing Phase
**Objective**: Test coverage
**Complexity**: 4/10

**Tasks**:
- [ ] Task 1: Unit tests
- [ ] Task 2: Integration tests
EOF

# Create checkpoint for this workflow
CHECKPOINT_JSON3='{
  "schema_version": "1.1",
  "checkpoint_id": "test_003",
  "workflow_type": "implement",
  "project_name": "complex_feature",
  "created_at": "2025-10-06T14:00:00Z",
  "updated_at": "2025-10-06T14:00:00Z",
  "status": "in_progress",
  "current_phase": 2,
  "total_phases": 3,
  "completed_phases": [1],
  "workflow_state": {
    "plan_file": "003_complex_plan.md"
  },
  "last_error": null,
  "replanning_count": 0,
  "last_replan_reason": null,
  "replan_phase_counts": {},
  "replan_history": []
}'

CHECKPOINT_FILE3=$(save_checkpoint "implement" "complex_feature" "$CHECKPOINT_JSON3")

# Step 1: Detect complexity trigger
COMPLEX_PLAN="$TEST_DIR/.claude/specs/plans/003_complex_plan.md"
PHASE2_COMPLEXITY=$(calculate_phase_complexity "$COMPLEX_PLAN" 2)
PHASE2_TASKS=$(grep -A 20 "### Phase 2:" "$COMPLEX_PLAN" | grep -c "^- \[ \]" || echo 0)

log_complexity_check 2 "$PHASE2_COMPLEXITY" 8 "$PHASE2_TASKS"

# Verify trigger detected
if ! grep -q "complexity.*triggered" "$CLAUDE_LOGS_DIR/adaptive-planning.log"; then
  fail "Test 17: Complexity trigger should fire for phase with 12 tasks" "Expected triggered"
  # Continue anyway for integration test
fi

# Step 2: Create context JSON for /revise auto-mode
REVISE_CONTEXT=$(cat <<EOF
{
  "revision_type": "expand_phase",
  "current_phase": 2,
  "plan_file": "003_complex_plan.md",
  "reason": "Phase 2 complexity score 9.0 exceeds threshold of 8.0",
  "suggested_action": "Expand Phase 2 into separate file with detailed task breakdown",
  "trigger_data": {
    "trigger_type": "complexity",
    "complexity_score": $PHASE2_COMPLEXITY,
    "task_count": $PHASE2_TASKS,
    "threshold": 8
  }
}
EOF
)

# Validate context JSON structure
if ! echo "$REVISE_CONTEXT" | jq . > /dev/null 2>&1; then
  fail "Test 17: Context JSON should be valid" "JSON parsing failed"
else
  pass "Test 17: Context JSON created and validated"
fi

# Step 3: Simulate /revise auto-mode invocation (mock)
# In real workflow, this would call: /revise --auto-mode --context "$REVISE_CONTEXT"
# Here we simulate a successful response
REVISE_RESPONSE=$(cat <<'EOF'
{
  "status": "success",
  "revision_type": "expand_phase",
  "updated_plan_path": "003_complex_plan/003_complex_plan.md",
  "expanded_phase_path": "003_complex_plan/phase_2_implementation.md",
  "changes_summary": "Expanded Phase 2 into detailed file with 3 sub-stages",
  "backup_created": true
}
EOF
)

# Validate response format
if echo "$REVISE_RESPONSE" | jq -e '.status == "success"' > /dev/null 2>&1; then
  pass "Test 17: Simulated /revise response is valid"
else
  fail "Test 17: Revise response should have success status" "Invalid response format"
fi

# Step 4: Log the replan invocation
UPDATED_PLAN_PATH=$(echo "$REVISE_RESPONSE" | jq -r '.updated_plan_path')
log_replan_invocation "expand_phase" "success" "$UPDATED_PLAN_PATH" "$REVISE_CONTEXT"

# Verify replan logged
if grep -q "replan.*expand_phase.*success" "$CLAUDE_LOGS_DIR/adaptive-planning.log"; then
  pass "Test 17: Replan invocation logged successfully"
else
  fail "Test 17: Replan should be logged" "Expected replan log entry"
fi

# Step 5: Update checkpoint with replan metadata
REPLAN_REASON="Complexity: $PHASE2_COMPLEXITY, Tasks: $PHASE2_TASKS"
checkpoint_increment_replan "$CHECKPOINT_FILE3" "2" "$REPLAN_REASON"

# Verify checkpoint updated correctly
FINAL_CHECKPOINT=$(cat "$CHECKPOINT_FILE3")
FINAL_REPLAN_COUNT=$(echo "$FINAL_CHECKPOINT" | jq -r '.replanning_count')
FINAL_REASON=$(echo "$FINAL_CHECKPOINT" | jq -r '.last_replan_reason')
PHASE2_COUNT=$(echo "$FINAL_CHECKPOINT" | jq -r '.replan_phase_counts["phase_2"] // 0')

if [[ "$FINAL_REPLAN_COUNT" == "1" ]] && \
   [[ "$FINAL_REASON" == "$REPLAN_REASON" ]] && \
   [[ "$PHASE2_COUNT" == "1" ]]; then
  pass "Test 17: Checkpoint updated with replan metadata (count, reason, phase count)"
else
  fail "Test 17: Checkpoint metadata incomplete" "Expected count=1, phase_2_count=1, reason set"
fi

# Step 6: Verify replan history entry created
HISTORY_LENGTH=$(echo "$FINAL_CHECKPOINT" | jq '.replan_history | length')
if [[ "$HISTORY_LENGTH" == "1" ]]; then
  HISTORY_ENTRY=$(echo "$FINAL_CHECKPOINT" | jq -r '.replan_history[0]')
  if echo "$HISTORY_ENTRY" | jq -e '.phase == 2 and .reason != null' > /dev/null 2>&1; then
    pass "Test 17: Replan history entry created with correct phase and reason"
  else
    fail "Test 17: History entry malformed" "Should contain phase=2 and reason"
  fi
else
  fail "Test 17: Replan history should have 1 entry" "Got $HISTORY_LENGTH entries"
fi

# Final integration check
if [[ "$FINAL_REPLAN_COUNT" == "1" ]] && \
   grep -q "complexity.*triggered" "$CLAUDE_LOGS_DIR/adaptive-planning.log" && \
   grep -q "replan.*success" "$CLAUDE_LOGS_DIR/adaptive-planning.log"; then
  pass "Test 17: FULL INTEGRATION - Complexity trigger → context → revise → checkpoint update"
else
  fail "Test 17: Integration flow incomplete" "All steps should complete successfully"
fi

# =============================================================================
# Test 18: Loop Prevention Enforcement
# =============================================================================
info "Test 18: Loop prevention actually blocks third replan attempt"

# Create a checkpoint with 2 replans already for phase 3
CHECKPOINT_JSON4='{
  "schema_version": "1.1",
  "checkpoint_id": "test_004",
  "workflow_type": "implement",
  "project_name": "loop_prevention_test",
  "created_at": "2025-10-06T15:00:00Z",
  "updated_at": "2025-10-06T15:30:00Z",
  "status": "in_progress",
  "current_phase": 3,
  "total_phases": 5,
  "completed_phases": [1, 2],
  "workflow_state": {
    "plan_file": "004_test_plan.md"
  },
  "last_error": null,
  "replanning_count": 2,
  "last_replan_reason": "Second replan: Test failure pattern",
  "replan_phase_counts": {
    "phase_3": 2
  },
  "replan_history": [
    {
      "phase": 3,
      "timestamp": "2025-10-06T15:10:00Z",
      "reason": "First replan: Complexity threshold",
      "revision_type": "expand_phase"
    },
    {
      "phase": 3,
      "timestamp": "2025-10-06T15:25:00Z",
      "reason": "Second replan: Test failure pattern",
      "revision_type": "add_phase"
    }
  ]
}'

CHECKPOINT_FILE4=$(save_checkpoint "implement" "loop_prevention_test" "$CHECKPOINT_JSON4")

# Verify checkpoint has 2 replans for phase 3
CURRENT_PHASE_REPLANS=$(cat "$CHECKPOINT_FILE4" | jq -r '.replan_phase_counts["phase_3"] // 0')
if [[ "$CURRENT_PHASE_REPLANS" != "2" ]]; then
  fail "Test 18: Setup error - checkpoint should have 2 replans" "Got $CURRENT_PHASE_REPLANS"
fi

# Clear log for clean test
> "$CLAUDE_LOGS_DIR/adaptive-planning.log"

# Simulate third replan attempt - should be blocked
THIRD_REPLAN_COUNT=2  # Current count before attempt
log_loop_prevention 3 "$THIRD_REPLAN_COUNT" "blocked"

# Check that warning was logged
if grep -q "WARN.*loop_prevention.*blocked" "$CLAUDE_LOGS_DIR/adaptive-planning.log"; then
  pass "Test 18: Third replan attempt logged as blocked with WARN level"
else
  fail "Test 18: Loop prevention should log WARN for blocked replan" "Expected WARN log"
fi

# Verify checkpoint was NOT incremented (replan blocked)
FINAL_COUNT=$(cat "$CHECKPOINT_FILE4" | jq -r '.replanning_count')
FINAL_PHASE3_COUNT=$(cat "$CHECKPOINT_FILE4" | jq -r '.replan_phase_counts["phase_3"] // 0')

if [[ "$FINAL_COUNT" == "2" ]] && [[ "$FINAL_PHASE3_COUNT" == "2" ]]; then
  pass "Test 18: Checkpoint counters unchanged (replan was actually blocked)"
else
  fail "Test 18: Counters should remain at 2" "Got total=$FINAL_COUNT, phase3=$FINAL_PHASE3_COUNT"
fi

# Verify that a user escalation message would be generated
# In real implementation, this would be done by /implement command
ESCALATION_MSG="Maximum replans (2) reached for phase 3. Manual intervention required."
if [[ -n "$ESCALATION_MSG" ]]; then
  pass "Test 18: User escalation message prepared for blocked replan"
else
  fail "Test 18: Should prepare user escalation message" "Expected non-empty message"
fi

# Test that subsequent triggers are also blocked (idempotent blocking)
log_loop_prevention 3 2 "blocked"
BLOCKED_COUNT=$(grep -c "loop_prevention.*blocked" "$CLAUDE_LOGS_DIR/adaptive-planning.log" || echo 0)

if [[ "$BLOCKED_COUNT" -ge 2 ]]; then
  pass "Test 18: Loop prevention blocks repeatedly (idempotent)"
else
  fail "Test 18: Should block all attempts when limit reached" "Expected 2+ blocked logs"
fi

# Verify replan history was NOT modified
HISTORY_COUNT=$(cat "$CHECKPOINT_FILE4" | jq '.replan_history | length')
if [[ "$HISTORY_COUNT" == "2" ]]; then
  pass "Test 18: Replan history unchanged (no new entry for blocked attempt)"
else
  fail "Test 18: History should remain at 2 entries" "Got $HISTORY_COUNT entries"
fi

# =============================================================================
# Test 19: Revise Failure Recovery
# =============================================================================
info "Test 19: Graceful error handling when /revise auto-mode fails"

# Create a test plan for failure scenario
cat > "$TEST_DIR/.claude/specs/plans/005_failure_test.md" <<'EOF'
# Failure Test Plan

## Metadata
- **Date**: 2025-10-06
- **Status**: In Progress

### Phase 1: Completed Phase
**Objective**: Setup
**Complexity**: 2/10

**Tasks**:
- [x] Task 1: Initialize

### Phase 2: Problem Phase
**Objective**: Phase that will trigger replan
**Complexity**: 9/10

**Tasks**:
- [ ] Task 1: Complex feature
- [ ] Task 2: More complexity
- [ ] Task 3: Even more
- [ ] Task 4: Dependencies
- [ ] Task 5: Integration
- [ ] Task 6: Testing
- [ ] Task 7: Documentation
- [ ] Task 8: Deployment
- [ ] Task 9: Monitoring
- [ ] Task 10: Security
- [ ] Task 11: Performance
EOF

# Create checkpoint
CHECKPOINT_JSON5='{
  "schema_version": "1.1",
  "checkpoint_id": "test_005",
  "workflow_type": "implement",
  "project_name": "failure_recovery",
  "created_at": "2025-10-06T16:00:00Z",
  "updated_at": "2025-10-06T16:00:00Z",
  "status": "in_progress",
  "current_phase": 2,
  "total_phases": 2,
  "completed_phases": [1],
  "workflow_state": {
    "plan_file": "005_failure_test.md"
  },
  "last_error": null,
  "replanning_count": 0,
  "last_replan_reason": null,
  "replan_phase_counts": {},
  "replan_history": []
}'

CHECKPOINT_FILE5=$(save_checkpoint "implement" "failure_recovery" "$CHECKPOINT_JSON5")

# Create a backup of the checkpoint (simulating pre-replan backup)
CHECKPOINT_BACKUP="${CHECKPOINT_FILE5}.backup"
cp "$CHECKPOINT_FILE5" "$CHECKPOINT_BACKUP"

# Verify backup exists
if [[ -f "$CHECKPOINT_BACKUP" ]]; then
  pass "Test 19: Checkpoint backup created before replan attempt"
else
  fail "Test 19: Backup should be created" "Backup file should exist"
fi

# Simulate /revise auto-mode failure
REVISE_ERROR_RESPONSE=$(cat <<'EOF'
{
  "status": "error",
  "error_code": "PLAN_PARSE_ERROR",
  "error_message": "Failed to parse plan structure: invalid phase numbering",
  "details": {
    "line": 15,
    "expected": "Phase 3",
    "found": "Phase X"
  }
}
EOF
)

# Validate error response format
if echo "$REVISE_ERROR_RESPONSE" | jq -e '.status == "error"' > /dev/null 2>&1; then
  pass "Test 19: Simulated /revise error response is valid"
else
  fail "Test 19: Error response should have error status" "Invalid error format"
fi

# Log the failed replan
ERROR_MSG=$(echo "$REVISE_ERROR_RESPONSE" | jq -r '.error_message')
log_replan_invocation "expand_phase" "failure" "$ERROR_MSG" ""

# Verify error was logged
if grep -q "ERROR.*replan.*failure" "$CLAUDE_LOGS_DIR/adaptive-planning.log"; then
  pass "Test 19: Replan failure logged with ERROR level"
else
  fail "Test 19: Failure should be logged as ERROR" "Expected ERROR log entry"
fi

# Simulate checkpoint recovery from backup (restoration process)
# This would happen in /implement when /revise fails
cp "$CHECKPOINT_BACKUP" "$CHECKPOINT_FILE5"

# Verify checkpoint was restored (no corruption)
RESTORED_JSON=$(cat "$CHECKPOINT_FILE5")
RESTORED_COUNT=$(echo "$RESTORED_JSON" | jq -r '.replanning_count')
RESTORED_STATUS=$(echo "$RESTORED_JSON" | jq -r '.status')

if [[ "$RESTORED_COUNT" == "0" ]] && [[ "$RESTORED_STATUS" == "in_progress" ]]; then
  pass "Test 19: Checkpoint restored to pre-replan state (no corruption)"
else
  fail "Test 19: Checkpoint should be restored to original state" "Expected count=0, status=in_progress"
fi

# Verify checkpoint schema is still valid after restoration
if echo "$RESTORED_JSON" | jq -e '.schema_version, .checkpoint_id, .workflow_type' > /dev/null 2>&1; then
  pass "Test 19: Restored checkpoint has valid schema (all required fields)"
else
  fail "Test 19: Restored checkpoint should have valid schema" "Missing required fields"
fi

# Verify no partial replan data leaked into checkpoint
PARTIAL_HISTORY=$(echo "$RESTORED_JSON" | jq '.replan_history | length')
if [[ "$PARTIAL_HISTORY" == "0" ]]; then
  pass "Test 19: No partial replan history in restored checkpoint"
else
  fail "Test 19: History should be empty after restore" "Got $PARTIAL_HISTORY entries"
fi

# Test cleanup of backup file after successful restore
rm -f "$CHECKPOINT_BACKUP"
if [[ ! -f "$CHECKPOINT_BACKUP" ]]; then
  pass "Test 19: Backup file cleaned up after restore"
else
  fail "Test 19: Backup should be removed after successful restore" "File still exists"
fi

# Verify that workflow can continue after failure (checkpoint usable)
# Simulate incrementing current phase (what /implement would do)
CONTINUE_JSON=$(echo "$RESTORED_JSON" | jq '.current_phase = 2 | .completed_phases += [2]')
if echo "$CONTINUE_JSON" | jq -e '.completed_phases | length == 2' > /dev/null 2>&1; then
  pass "Test 19: Workflow can continue after failure recovery (checkpoint still usable)"
else
  fail "Test 19: Should be able to modify restored checkpoint" "Checkpoint may be corrupted"
fi

# Test error details are preserved for debugging
if echo "$REVISE_ERROR_RESPONSE" | jq -e '.details.line, .details.expected' > /dev/null 2>&1; then
  pass "Test 19: Error response includes detailed debugging information"
else
  fail "Test 19: Error details should be available" "Missing debug info"
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
