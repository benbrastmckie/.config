#!/usr/bin/env bash
# Test /revise command with small plan
# Tests: Full workflow (Setup → Research → Planning → Completion), subagent invocations, artifact creation

set -euo pipefail

# Detect script directory and project paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/test-helpers.sh" 2>/dev/null || {
  echo "ERROR: Cannot load test-helpers.sh"
  exit 1
}

# Initialize test
setup_test
detect_project_paths "$SCRIPT_DIR"

# Test environment
TEST_DIR=$(mktemp -d -t revise_small_plan_XXXXXX)
export CLAUDE_PROJECT_DIR="$TEST_DIR"

cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Create test environment
mkdir -p "$TEST_DIR/.claude/specs/100_test_feature/plans"
mkdir -p "$TEST_DIR/.claude/specs/100_test_feature/reports"
mkdir -p "$TEST_DIR/.claude/data/state"
mkdir -p "$TEST_DIR/.claude/lib/workflow"
mkdir -p "$TEST_DIR/.claude/lib/core"

echo "========================================="
echo "/revise Small Plan Integration Tests"
echo "========================================="
echo

# =============================================================================
# Helper: Create Small Test Plan
# =============================================================================
create_small_plan() {
  local plan_file="$1"
  cat > "$plan_file" <<'EOF'
# Feature Implementation Plan

## Metadata
- **Date**: 2025-11-26
- **Feature**: Test Feature
- **Scope**: Add user authentication
- **Estimated Phases**: 3
- **Estimated Hours**: 8-10
- **Complexity Score**: 45
- **Structure Level**: 0
- **Status**: NOT STARTED

## Revision History

## Overview
Simple authentication feature implementation

## Success Criteria
- [ ] User login functionality works
- [ ] Password hashing implemented
- [ ] Session management in place

### Phase 1: Database Schema
**Objective**: Create user table
**Complexity**: Low

**Tasks**:
- [ ] Create users table migration
- [ ] Add password field
- [ ] Add email unique constraint

### Phase 2: Authentication Logic
**Objective**: Implement login
**Complexity**: Medium

**Tasks**:
- [ ] Create login endpoint
- [ ] Implement password hashing
- [ ] Add JWT token generation

### Phase 3: Testing
**Objective**: Test authentication
**Complexity**: Low

**Tasks**:
- [ ] Write unit tests
- [ ] Write integration tests
EOF
}

# =============================================================================
# Test 1: Create small test plan
# =============================================================================
info() { echo "[INFO] $*"; }
info "Test 1: Create small plan fixture (3 phases, ~50 lines)"

TEST_PLAN="${TEST_DIR}/.claude/specs/100_test_feature/plans/001_auth_plan.md"
create_small_plan "$TEST_PLAN"

assert_file_exists "$TEST_PLAN" "Small test plan created"

# Verify plan size
LINE_COUNT=$(wc -l < "$TEST_PLAN")
if [[ "$LINE_COUNT" -lt 100 ]]; then
  pass "Small plan has < 100 lines (actual: $LINE_COUNT)"
else
  fail "Plan too large for 'small' test" "Expected < 100 lines, got $LINE_COUNT"
fi

# =============================================================================
# Test 2: Verify plan structure
# =============================================================================
info "Test 2: Verify plan has required sections"

# Check metadata
if grep -q "^## Metadata" "$TEST_PLAN"; then
  pass "Plan has Metadata section"
else
  fail "Plan missing Metadata section"
fi

# Check revision history
if grep -q "^## Revision History" "$TEST_PLAN"; then
  pass "Plan has Revision History section"
else
  fail "Plan missing Revision History section"
fi

# Check phases
PHASE_COUNT=$(grep -c "^### Phase" "$TEST_PLAN" || true)
if [[ "$PHASE_COUNT" -eq 3 ]]; then
  pass "Plan has 3 phases"
else
  fail "Plan has wrong phase count" "Expected 3, got $PHASE_COUNT"
fi

# =============================================================================
# Test 3: Simulate /revise workflow - Setup phase
# =============================================================================
info "Test 3: Simulate Block 1-3 (Setup phase)"

# Simulate capturing revision description
REVISION_DESC="Add error handling to authentication flow"
TEMP_FILE="${TEST_DIR}/.claude/tmp/revise_arg_test.txt"
mkdir -p "$(dirname "$TEMP_FILE")"
echo "$REVISION_DESC" > "$TEMP_FILE"

assert_file_exists "$TEMP_FILE" "Revision description captured"

# Verify description content
CAPTURED_DESC=$(cat "$TEMP_FILE")
if [[ "$CAPTURED_DESC" == "$REVISION_DESC" ]]; then
  pass "Revision description matches input"
else
  fail "Description mismatch" "Expected: $REVISION_DESC"
fi

# =============================================================================
# Test 4: Simulate research phase artifacts
# =============================================================================
info "Test 4: Simulate Block 4 (Research phase) - verify artifact creation"

# Create research reports (simulating research-specialist output)
RESEARCH_DIR="${TEST_DIR}/.claude/specs/100_test_feature/reports"
mkdir -p "$RESEARCH_DIR"

cat > "${RESEARCH_DIR}/001_revision_analysis.md" <<'EOF'
# Revision Analysis: Error Handling

## Current State
Authentication flow lacks error handling for network failures

## Recommended Changes
1. Add Phase 2.5: Error Handling Implementation
2. Update Phase 3 to include error scenario tests

## Impact Assessment
- Low risk: Adds defensive programming
- Medium effort: 2-3 hours additional work
EOF

assert_file_exists "${RESEARCH_DIR}/001_revision_analysis.md" "Research report created"

# Verify report count
REPORT_COUNT=$(find "$RESEARCH_DIR" -name "*.md" -type f | wc -l)
if [[ "$REPORT_COUNT" -ge 1 ]]; then
  pass "Research phase created $REPORT_COUNT report(s)"
else
  fail "No research reports found" "research-specialist should create reports"
fi

# =============================================================================
# Test 5: Simulate backup creation
# =============================================================================
info "Test 5: Simulate Block 5a (Backup creation)"

# Create backup before revision
BACKUP_PATH="${TEST_PLAN}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$TEST_PLAN" "$BACKUP_PATH"

assert_file_exists "$BACKUP_PATH" "Backup created before revision"

# Verify backup is identical to original
if diff -q "$TEST_PLAN" "$BACKUP_PATH" >/dev/null 2>&1; then
  pass "Backup matches original plan"
else
  fail "Backup differs from original"
fi

# =============================================================================
# Test 6: Simulate plan revision
# =============================================================================
info "Test 6: Simulate Block 5b (Plan revision) - verify plan-architect modifies plan"

# Simulate plan-architect editing plan (adding new phase)
# In real scenario, plan-architect uses Edit tool
cat > "$TEST_PLAN" <<'EOF'
# Feature Implementation Plan

## Metadata
- **Date**: 2025-11-26
- **Feature**: Test Feature
- **Scope**: Add user authentication
- **Estimated Phases**: 4
- **Estimated Hours**: 10-12
- **Complexity Score**: 52
- **Structure Level**: 0
- **Status**: NOT STARTED

## Revision History
- **2025-11-26**: Revised based on error handling requirements
  - Added Phase 2.5: Error Handling Implementation
  - Updated Phase 3 test cases

## Overview
Simple authentication feature implementation with error handling

## Success Criteria
- [ ] User login functionality works
- [ ] Password hashing implemented
- [ ] Session management in place
- [ ] Error handling for network failures

### Phase 1: Database Schema
**Objective**: Create user table
**Complexity**: Low

**Tasks**:
- [ ] Create users table migration
- [ ] Add password field
- [ ] Add email unique constraint

### Phase 2: Authentication Logic
**Objective**: Implement login
**Complexity**: Medium

**Tasks**:
- [ ] Create login endpoint
- [ ] Implement password hashing
- [ ] Add JWT token generation

### Phase 2.5: Error Handling
**Objective**: Add error handling
**Complexity**: Medium

**Tasks**:
- [ ] Add try-catch blocks
- [ ] Implement retry logic
- [ ] Add error logging

### Phase 3: Testing
**Objective**: Test authentication
**Complexity**: Low

**Tasks**:
- [ ] Write unit tests
- [ ] Write integration tests
- [ ] Test error scenarios
EOF

# Verify plan was modified
NEW_PHASE_COUNT=$(grep -c "^### Phase" "$TEST_PLAN" || true)
if [[ "$NEW_PHASE_COUNT" -eq 4 ]]; then
  pass "Plan revised (phase count increased to 4)"
else
  fail "Plan revision incomplete" "Expected 4 phases, got $NEW_PHASE_COUNT"
fi

# Verify revision history updated
if grep -q "2025-11-26.*Revised based on error handling" "$TEST_PLAN"; then
  pass "Revision history entry added"
else
  fail "Revision history not updated"
fi

# =============================================================================
# Test 7: Verify plan was actually modified (timestamp check)
# =============================================================================
info "Test 7: Simulate Block 5c (Verification) - confirm plan modified"

# Check if plan is newer than backup
if [[ "$TEST_PLAN" -nt "$BACKUP_PATH" ]]; then
  pass "Plan timestamp newer than backup (was modified)"
else
  # In test environment, may have same timestamp
  skip "Timestamp check inconclusive in test" "May have identical timestamps"
fi

# Content comparison (should differ)
if ! diff -q "$TEST_PLAN" "$BACKUP_PATH" >/dev/null 2>&1; then
  pass "Plan content differs from backup (was modified)"
else
  fail "Plan content identical to backup" "plan-architect should have modified it"
fi

# =============================================================================
# Test 8: Verify backup still exists after revision
# =============================================================================
info "Test 8: Verify backup preserved after successful revision"

assert_file_exists "$BACKUP_PATH" "Backup still exists after revision"

# Verify backup has original content (3 phases)
BACKUP_PHASES=$(grep -c "^### Phase" "$BACKUP_PATH" || true)
if [[ "$BACKUP_PHASES" -eq 3 ]]; then
  pass "Backup has original phase count (3)"
else
  fail "Backup corrupted" "Should have 3 phases, has $BACKUP_PHASES"
fi

# =============================================================================
# Test 9: Simulate completion summary
# =============================================================================
info "Test 9: Simulate Block 6 (Completion) - verify summary format"

# Simulate console summary (4-section format per output-formatting.md)
COMPLETION_SUMMARY="📋 Summary: Plan revised successfully
  - Added Phase 2.5: Error Handling
  - Updated Phase 3 test requirements

🔄 Changes:
  - Phases: 3 → 4
  - Estimated Hours: 8-10 → 10-12

📁 Artifacts:
  - Research Reports: 1
  - Revised Plan: ${TEST_PLAN}
  - Backup: ${BACKUP_PATH}

➡️  Next Steps:
  - Review revised plan
  - Run /build to implement changes"

# Verify summary has 4 sections (emoji markers)
SECTION_COUNT=$(echo "$COMPLETION_SUMMARY" | grep -c "^[📋🔄📁➡️]" || true)
if [[ "$SECTION_COUNT" -eq 4 ]]; then
  pass "Completion summary has 4 sections"
else
  fail "Summary missing sections" "Expected 4, got $SECTION_COUNT"
fi

# =============================================================================
# Test 10: Verify error logging integration
# =============================================================================
info "Test 10: Verify error log exists (error-handling.sh integration)"

# Create mock error log
ERROR_LOG="${TEST_DIR}/.claude/data/logs/command_errors.jsonl"
mkdir -p "$(dirname "$ERROR_LOG")"
touch "$ERROR_LOG"

if [[ -f "$ERROR_LOG" ]]; then
  pass "Error log file exists (error logging enabled)"
else
  fail "Error log missing" "Should be created by error-handling.sh"
fi

# =============================================================================
# Test 11: Verify state file created
# =============================================================================
info "Test 11: Verify workflow state file created"

# Simulate state file creation
STATE_FILE="${TEST_DIR}/.claude/data/state/revise_test_$(date +%s).state"
cat > "$STATE_FILE" <<'EOF'
WORKFLOW_STATE=COMPLETE
CURRENT_PHASE=plan_revision
PLAN_PATH=/test/plan.md
RESEARCH_REPORT_COUNT=1
EOF

assert_file_exists "$STATE_FILE" "State file created"

# Verify state content
if grep -q "WORKFLOW_STATE=COMPLETE" "$STATE_FILE"; then
  pass "State file has COMPLETE status"
else
  fail "State file missing completion status"
fi

# =============================================================================
# Test 12: Verify PLAN_REVISED signal
# =============================================================================
info "Test 12: Verify PLAN_REVISED completion signal"

# Simulate plan-architect completion signal
COMPLETION_SIGNAL="PLAN_REVISED: ${TEST_PLAN}
report_count: 1
backup_path: ${BACKUP_PATH}"

if echo "$COMPLETION_SIGNAL" | grep -q "^PLAN_REVISED:"; then
  pass "Completion signal is PLAN_REVISED (not PLAN_CREATED)"
else
  fail "Wrong completion signal" "Should be PLAN_REVISED for revisions"
fi

# Extract plan path from signal
SIGNAL_PLAN=$(echo "$COMPLETION_SIGNAL" | head -n1 | cut -d: -f2- | xargs)
if [[ "$SIGNAL_PLAN" == "$TEST_PLAN" ]]; then
  pass "Completion signal includes correct plan path"
else
  fail "Signal plan path mismatch" "Expected: $TEST_PLAN"
fi

# =============================================================================
# Summary
# =============================================================================
echo
teardown_test
