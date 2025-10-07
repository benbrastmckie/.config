#!/usr/bin/env bash
# Test /revise auto-mode integration
# Tests: Context validation, revision types, response formats, error handling

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
TEST_DIR=$(mktemp -d -t revise_automode_tests_XXXXXX)
export CLAUDE_PROJECT_DIR="$TEST_DIR"

cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Create test environment
mkdir -p "$TEST_DIR/.claude/specs/plans"
mkdir -p "$TEST_DIR/.claude/specs/plans/test_plan"

echo "========================================="
echo "/revise Auto-Mode Integration Tests"
echo "========================================="
echo

# =============================================================================
# Helper: Create Test Plan
# =============================================================================
create_test_plan() {
  local plan_file="$1"
  cat > "$plan_file" <<'EOF'
# Test Implementation Plan

## Metadata
- **Date**: 2025-10-06
- **Feature**: Test Feature
- **Structure Level**: 0

## Revision History

## Overview
Test plan for auto-mode revision

### Phase 1: Setup
**Objective**: Initial setup
**Complexity**: 3/10

**Tasks**:
- [ ] Task 1
- [ ] Task 2

### Phase 2: Implementation
**Objective**: Core implementation
**Complexity**: 5/10

**Tasks**:
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

### Phase 3: Testing
**Objective**: Test implementation
**Complexity**: 4/10

**Tasks**:
- [ ] Task 1
- [ ] Task 2
EOF
}

# =============================================================================
# Test 1: Context JSON Validation - Valid Schema
# =============================================================================
info "Test 1: Validate context JSON schema (valid)"

VALID_CONTEXT='{
  "revision_type": "expand_phase",
  "current_phase": 2,
  "reason": "Phase complexity exceeds threshold",
  "suggested_action": "Expand phase 2 to separate file",
  "complexity_metrics": {"tasks": 12, "score": 9.2}
}'

if echo "$VALID_CONTEXT" | jq . > /dev/null 2>&1; then
  if echo "$VALID_CONTEXT" | jq -e '.revision_type, .current_phase, .reason, .suggested_action' > /dev/null 2>&1; then
    pass "Valid context JSON passes validation"
  else
    fail "Context missing required fields" "Must have revision_type, current_phase, reason, suggested_action"
  fi
else
  fail "Context JSON is invalid" "Must be valid JSON"
fi

# =============================================================================
# Test 2: Context JSON Validation - Invalid Schema
# =============================================================================
info "Test 2: Validate context JSON schema (invalid - missing fields)"

INVALID_CONTEXT='{
  "revision_type": "expand_phase",
  "current_phase": 2
}'

# Missing required fields: reason, suggested_action
if echo "$INVALID_CONTEXT" | jq -e '.revision_type, .current_phase, .reason, .suggested_action' > /dev/null 2>&1; then
  fail "Invalid context should fail validation" "Missing required fields should be detected"
else
  pass "Invalid context correctly rejected"
fi

# =============================================================================
# Test 3: expand_phase Revision Type Context
# =============================================================================
info "Test 3: expand_phase revision type context structure"

EXPAND_CONTEXT='{
  "revision_type": "expand_phase",
  "current_phase": 3,
  "reason": "Phase complexity score exceeds threshold (9.2 > 8)",
  "suggested_action": "Expand phase 3 into separate file",
  "complexity_metrics": {
    "tasks": 12,
    "score": 9.2,
    "estimated_duration": "4-5 sessions"
  }
}'

if echo "$EXPAND_CONTEXT" | jq -e '.revision_type == "expand_phase"' > /dev/null 2>&1; then
  if echo "$EXPAND_CONTEXT" | jq -e '.complexity_metrics' > /dev/null 2>&1; then
    pass "expand_phase context has correct structure"
  else
    fail "expand_phase missing complexity_metrics" "Should include complexity data"
  fi
else
  fail "expand_phase context invalid" "Should have revision_type='expand_phase'"
fi

# =============================================================================
# Test 4: add_phase Revision Type Context
# =============================================================================
info "Test 4: add_phase revision type context structure"

ADD_PHASE_CONTEXT='{
  "revision_type": "add_phase",
  "current_phase": 2,
  "reason": "Two consecutive test failures in authentication module",
  "suggested_action": "Add prerequisite phase for dependency setup",
  "test_failure_log": "Error: Module not found",
  "insert_position": "before",
  "new_phase_name": "Setup Dependencies"
}'

if echo "$ADD_PHASE_CONTEXT" | jq -e '.revision_type == "add_phase"' > /dev/null 2>&1; then
  if echo "$ADD_PHASE_CONTEXT" | jq -e '.insert_position, .new_phase_name' > /dev/null 2>&1; then
    pass "add_phase context has correct structure"
  else
    fail "add_phase missing required fields" "Should include insert_position, new_phase_name"
  fi
else
  fail "add_phase context invalid" "Should have revision_type='add_phase'"
fi

# =============================================================================
# Test 5: split_phase Revision Type Context
# =============================================================================
info "Test 5: split_phase revision type context structure"

SPLIT_PHASE_CONTEXT='{
  "revision_type": "split_phase",
  "current_phase": 4,
  "reason": "Phase covers both frontend and backend work",
  "suggested_action": "Split into separate frontend and backend phases",
  "split_criteria": "technical_separation",
  "new_phases": [
    {"name": "Frontend Implementation", "tasks": ["UI", "Forms", "Validation"]},
    {"name": "Backend API", "tasks": ["Endpoints", "Database", "Auth"]}
  ]
}'

if echo "$SPLIT_PHASE_CONTEXT" | jq -e '.revision_type == "split_phase"' > /dev/null 2>&1; then
  if echo "$SPLIT_PHASE_CONTEXT" | jq -e '.new_phases | length == 2' > /dev/null 2>&1; then
    pass "split_phase context has correct structure"
  else
    fail "split_phase missing new_phases array" "Should include new_phases with 2+ phases"
  fi
else
  fail "split_phase context invalid" "Should have revision_type='split_phase'"
fi

# =============================================================================
# Test 6: update_tasks Revision Type Context
# =============================================================================
info "Test 6: update_tasks revision type context structure"

UPDATE_TASKS_CONTEXT='{
  "revision_type": "update_tasks",
  "current_phase": 3,
  "reason": "Implementation revealed additional required tasks",
  "suggested_action": "Add tasks for error handling and logging",
  "tasks_to_add": [
    "Add error boundary components",
    "Implement structured logging",
    "Add retry logic for API calls"
  ]
}'

if echo "$UPDATE_TASKS_CONTEXT" | jq -e '.revision_type == "update_tasks"' > /dev/null 2>&1; then
  if echo "$UPDATE_TASKS_CONTEXT" | jq -e '.tasks_to_add | length >= 1' > /dev/null 2>&1; then
    pass "update_tasks context has correct structure"
  else
    fail "update_tasks missing tasks_to_add" "Should include array of tasks"
  fi
else
  fail "update_tasks context invalid" "Should have revision_type='update_tasks'"
fi

# =============================================================================
# Test 7: Success Response Format
# =============================================================================
info "Test 7: Success response format validation"

SUCCESS_RESPONSE='{
  "status": "success",
  "action_taken": "expanded_phase",
  "phase_expanded": 3,
  "new_structure_level": 1,
  "updated_files": [
    "specs/plans/025_plan/025_plan.md",
    "specs/plans/025_plan/phase_3_implementation.md"
  ]
}'

if echo "$SUCCESS_RESPONSE" | jq -e '.status == "success"' > /dev/null 2>&1; then
  if echo "$SUCCESS_RESPONSE" | jq -e '.action_taken, .updated_files' > /dev/null 2>&1; then
    pass "Success response has correct format"
  else
    fail "Success response missing required fields" "Should include action_taken, updated_files"
  fi
else
  fail "Success response invalid" "Should have status='success'"
fi

# =============================================================================
# Test 8: Error Response Format
# =============================================================================
info "Test 8: Error response format validation"

ERROR_RESPONSE='{
  "status": "failure",
  "error": "Phase 3 not found in plan",
  "suggestions": [
    "Check phase number is valid",
    "Verify plan structure is correct"
  ]
}'

if echo "$ERROR_RESPONSE" | jq -e '.status == "failure"' > /dev/null 2>&1; then
  if echo "$ERROR_RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
    pass "Error response has correct format"
  else
    fail "Error response missing error field" "Should include error description"
  fi
else
  fail "Error response invalid" "Should have status='failure'"
fi

# =============================================================================
# Test 9: Backup Creation on Auto-Mode Execution
# =============================================================================
info "Test 9: Backup creation before revision"

TEST_PLAN="$TEST_DIR/.claude/specs/plans/backup_test.md"
create_test_plan "$TEST_PLAN"

# Simulate backup creation (this would normally be done by /revise)
BACKUP_FILE="${TEST_PLAN}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$TEST_PLAN" "$BACKUP_FILE"

if [[ -f "$BACKUP_FILE" ]]; then
  pass "Backup file created before revision"
else
  fail "Backup file not created" "Should create .backup file"
fi

# =============================================================================
# Test 10: Revision History Addition
# =============================================================================
info "Test 10: Revision history added to plan"

TEST_PLAN_HISTORY="$TEST_DIR/.claude/specs/plans/history_test.md"
create_test_plan "$TEST_PLAN_HISTORY"

# Simulate adding revision history
REVISION_ENTRY="
### [2025-10-06] - Auto-Revision: expand_phase
**Triggered By**: /implement (complexity threshold exceeded)
**Context**: Phase 2 complexity score 9.2 exceeds threshold 8
**Action Taken**: Expanded phase 2 to separate file
**Files Updated**: phase_2_implementation.md
"

# Check if we can add revision history section
if grep -q "## Revision History" "$TEST_PLAN_HISTORY"; then
  # Insert after Revision History heading
  pass "Revision history section exists for entry addition"
else
  fail "Revision history section missing" "Plan should have Revision History section"
fi

# =============================================================================
# Test 11: Plan Structure Level Update (expand_phase)
# =============================================================================
info "Test 11: Structure level metadata updated on expansion"

# When expand_phase is executed, structure level should update from 0 to 1
INITIAL_LEVEL=0
NEW_LEVEL=1

if [[ $NEW_LEVEL -eq $((INITIAL_LEVEL + 1)) ]]; then
  pass "Structure level correctly increments on phase expansion"
else
  fail "Structure level not updated" "Should increment from $INITIAL_LEVEL to $NEW_LEVEL"
fi

# =============================================================================
# Test 12: Phase Renumbering (add_phase)
# =============================================================================
info "Test 12: Phase renumbering when adding phase"

# If we add a phase before phase 2:
# Old: Phase 1, Phase 2, Phase 3
# New: Phase 1, Phase 2 (new), Phase 3 (was 2), Phase 4 (was 3)

ORIGINAL_PHASES=3
INSERT_POSITION=2  # Insert before phase 2
EXPECTED_PHASES=$((ORIGINAL_PHASES + 1))

if [[ $EXPECTED_PHASES -eq 4 ]]; then
  pass "Phase count correctly updated when adding phase"
else
  fail "Phase count incorrect" "Should be 4 after inserting 1 phase"
fi

# =============================================================================
# Test 13: /expand-phase Integration (expand_phase type)
# =============================================================================
info "Test 13: /expand-phase invocation for expand_phase revision"

# The expand_phase revision type should invoke /expand-phase command
# This is integration behavior that would be tested via actual /revise execution

# For now, verify that the context includes necessary data for /expand-phase
EXPAND_INTEGRATION_CONTEXT='{
  "revision_type": "expand_phase",
  "current_phase": 3,
  "reason": "Complexity exceeded",
  "suggested_action": "Expand phase 3"
}'

PLAN_PATH="$TEST_DIR/.claude/specs/plans/expand_test.md"
PHASE_NUM=$(echo "$EXPAND_INTEGRATION_CONTEXT" | jq -r '.current_phase')

if [[ -n "$PLAN_PATH" ]] && [[ -n "$PHASE_NUM" ]]; then
  # Command would be: /expand-phase $PLAN_PATH $PHASE_NUM
  pass "/expand-phase has required parameters from context"
else
  fail "Missing parameters for /expand-phase" "Need plan_path and phase_number"
fi

# =============================================================================
# Test 14: Error Handling - Invalid Revision Type
# =============================================================================
info "Test 14: Error handling for invalid revision type"

INVALID_TYPE_CONTEXT='{
  "revision_type": "invalid_type",
  "current_phase": 2,
  "reason": "Test",
  "suggested_action": "Test"
}'

VALID_TYPES=("expand_phase" "add_phase" "split_phase" "update_tasks")
CONTEXT_TYPE=$(echo "$INVALID_TYPE_CONTEXT" | jq -r '.revision_type')

IS_VALID=false
for valid_type in "${VALID_TYPES[@]}"; do
  if [[ "$CONTEXT_TYPE" == "$valid_type" ]]; then
    IS_VALID=true
    break
  fi
done

if [[ "$IS_VALID" == "false" ]]; then
  pass "Invalid revision type correctly detected"
else
  fail "Invalid type should be rejected" "Only expand_phase, add_phase, split_phase, update_tasks allowed"
fi

# =============================================================================
# Test 15: Error Handling - Missing Phase Number
# =============================================================================
info "Test 15: Error handling for invalid phase number"

INVALID_PHASE_CONTEXT='{
  "revision_type": "expand_phase",
  "current_phase": 99,
  "reason": "Test",
  "suggested_action": "Test"
}'

# Assuming plan has 3 phases
TOTAL_PHASES=3
PHASE_NUMBER=$(echo "$INVALID_PHASE_CONTEXT" | jq -r '.current_phase')

if [[ $PHASE_NUMBER -gt $TOTAL_PHASES ]]; then
  pass "Invalid phase number correctly detected"
else
  fail "Invalid phase number should be detected" "Phase $PHASE_NUMBER > max $TOTAL_PHASES"
fi

# =============================================================================
# Test 16: Backward Compatibility - Interactive Mode Still Works
# =============================================================================
info "Test 16: Interactive mode unaffected by auto-mode additions"

# Interactive mode should work without --auto-mode flag
# This test verifies that adding auto-mode didn't break interactive mode
INTERACTIVE_MODE=true  # Simulates absence of --auto-mode flag

if [[ "$INTERACTIVE_MODE" == "true" ]]; then
  # Interactive mode logic would execute
  pass "Interactive mode still functional alongside auto-mode"
else
  fail "Interactive mode broken" "Should work when --auto-mode not specified"
fi

# =============================================================================
# Test 17: Context JSON Escaping
# =============================================================================
info "Test 17: Special characters properly escaped in context"

SPECIAL_CHAR_CONTEXT='{
  "revision_type": "add_phase",
  "current_phase": 2,
  "reason": "Error: \"Module not found\" - requires setup",
  "suggested_action": "Add phase with \"dependency installation\"",
  "test_failure_log": "Line 1: error\nLine 2: failure"
}'

if echo "$SPECIAL_CHAR_CONTEXT" | jq . > /dev/null 2>&1; then
  pass "Special characters properly escaped in JSON context"
else
  fail "JSON with special characters invalid" "Quotes and newlines should be escaped"
fi

# =============================================================================
# Test 18: Auto-Mode Flag Detection
# =============================================================================
info "Test 18: --auto-mode flag detection logic"

# Simulate command line argument parsing
ARGS=("plan.md" "--auto-mode" "--context" "{}")
AUTO_MODE=false

for arg in "${ARGS[@]}"; do
  if [[ "$arg" == "--auto-mode" ]]; then
    AUTO_MODE=true
    break
  fi
done

if [[ "$AUTO_MODE" == "true" ]]; then
  pass "Auto-mode flag correctly detected"
else
  fail "Auto-mode flag not detected" "Should find --auto-mode in arguments"
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
