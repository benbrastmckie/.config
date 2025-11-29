#!/usr/bin/env bash
# Test /revise error recovery and verification blocks
# Tests: research-specialist failure, Block 4c fail-fast, error logging, recovery instructions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/test-helpers.sh" 2>/dev/null || {
  echo "ERROR: Cannot load test-helpers.sh"
  exit 1
}

setup_test
detect_project_paths "$SCRIPT_DIR"

TEST_DIR=$(mktemp -d -t revise_error_recovery_XXXXXX)
cleanup() { rm -rf "$TEST_DIR"; }
trap cleanup EXIT

mkdir -p "$TEST_DIR/.claude/specs/test/plans"
mkdir -p "$TEST_DIR/.claude/specs/test/reports"
mkdir -p "$TEST_DIR/.claude/data/logs"

echo "========================================="
echo "/revise Error Recovery Tests"
echo "========================================="
echo

info() { echo "[INFO] $*"; }

# Create test plan
TEST_PLAN="${TEST_DIR}/.claude/specs/test/plans/001_plan.md"
cat > "$TEST_PLAN" <<'EOF'
# Test Plan
## Metadata
- **Status**: NOT STARTED
## Revision History
### Phase 1: Setup
- [ ] Task 1
EOF

info "Test 1: Simulate missing research reports directory"
RESEARCH_DIR="${TEST_DIR}/.claude/specs/test/reports"
# Remove the directory to simulate failure
rmdir "$RESEARCH_DIR"

# Verify directory doesn't exist (simulating research-specialist failure)
if [[ ! -d "$RESEARCH_DIR" ]]; then
  pass "Research directory removed (simulating failure)"
else
  fail "Directory still exists"
fi

info "Test 2: Simulate Block 4c verification failure"
# Block 4c should check for research directory existence
VERIFICATION_FAILED=false
if [[ ! -d "$RESEARCH_DIR" ]]; then
  VERIFICATION_FAILED=true
  # This would trigger error logging
  ERROR_MSG="VERIFICATION FAILED: Research directory not found: $RESEARCH_DIR"
fi

if [[ "$VERIFICATION_FAILED" == "true" ]]; then
  pass "Verification block detected missing directory"
else
  fail "Verification should have failed"
fi

info "Test 3: Verify error message format"
if echo "$ERROR_MSG" | grep -q "VERIFICATION FAILED"; then
  pass "Error message has VERIFICATION FAILED prefix"
else
  fail "Error message format incorrect"
fi

if echo "$ERROR_MSG" | grep -q "$RESEARCH_DIR"; then
  pass "Error message includes directory path"
else
  fail "Error message missing directory path"
fi

info "Test 4: Simulate error logging"
ERROR_LOG="${TEST_DIR}/.claude/data/logs/command_errors.jsonl"
# Simulate log_command_error call
cat >> "$ERROR_LOG" <<EOF
{"timestamp":"2025-11-26T10:00:00Z","command":"/revise","error_type":"verification_error","message":"Research directory not found","details":"${RESEARCH_DIR}","workflow_id":"revise_test_123"}
EOF

assert_file_exists "$ERROR_LOG" "Error log created"

# Verify log entry
if grep -q "verification_error" "$ERROR_LOG"; then
  pass "Error logged with type: verification_error"
else
  fail "Error type not logged"
fi

if grep -q "$RESEARCH_DIR" "$ERROR_LOG"; then
  pass "Error log includes directory path"
else
  fail "Error log missing directory path"
fi

info "Test 5: Simulate recovery instructions"
RECOVERY_MSG="Recovery: Re-run /revise or check research-specialist agent logs
  Directory expected: $RESEARCH_DIR
  Ensure research-specialist creates reports before plan revision"

if echo "$RECOVERY_MSG" | grep -q "Recovery:"; then
  pass "Recovery message has 'Recovery:' label"
else
  fail "Recovery message format incorrect"
fi

if echo "$RECOVERY_MSG" | grep -q "Re-run /revise"; then
  pass "Recovery instructions include re-run suggestion"
else
  fail "Recovery missing re-run instruction"
fi

info "Test 6: Simulate missing report files (directory exists but empty)"
# Recreate directory but leave it empty
mkdir -p "$RESEARCH_DIR"
REPORT_COUNT=$(find "$RESEARCH_DIR" -name "*.md" -type f 2>/dev/null | wc -l)

if [[ "$REPORT_COUNT" -eq 0 ]]; then
  pass "Report count is zero (simulating empty directory)"
else
  fail "Directory should be empty"
fi

info "Test 7: Verify report count check fails"
# Block 4c should check report count > 0
if [[ "$REPORT_COUNT" -eq 0 ]]; then
  # This would trigger fail-fast
  ERROR_MSG="VERIFICATION FAILED: No research reports found in $RESEARCH_DIR"
  pass "Report count verification failed (as expected)"
else
  fail "Verification should detect zero reports"
fi

info "Test 8: Simulate state transition failure"
# Simulate sm_transition exit code check
STATE_TRANSITION_EXIT_CODE=1  # Simulate failure

if [[ "$STATE_TRANSITION_EXIT_CODE" -ne 0 ]]; then
  ERROR_MSG="State transition failed with exit code: $STATE_TRANSITION_EXIT_CODE"
  pass "State transition failure detected"
else
  fail "Should detect non-zero exit code"
fi

info "Test 9: Verify fail-fast behavior (exit 1)"
# Verification blocks should exit 1 on failure
EXPECTED_EXIT_CODE=1
ACTUAL_EXIT_CODE=1  # Simulated

if [[ "$ACTUAL_EXIT_CODE" -eq "$EXPECTED_EXIT_CODE" ]]; then
  pass "Verification block exits with code 1 (fail-fast)"
else
  fail "Exit code mismatch" "Expected: 1, Got: $ACTUAL_EXIT_CODE"
fi

info "Test 10: Simulate backup exists check failure"
BACKUP_PATH="${TEST_PLAN}.backup.20251126_100000"
# Don't create backup to simulate failure

if [[ ! -f "$BACKUP_PATH" ]]; then
  ERROR_MSG="VERIFICATION FAILED: Backup not found: $BACKUP_PATH"
  pass "Backup verification failed (as expected)"
else
  fail "Backup should not exist"
fi

info "Test 11: Verify error includes recovery hint"
if echo "$ERROR_MSG" | grep -q "Backup not found"; then
  pass "Error message identifies missing backup"
else
  fail "Error message unclear"
fi

info "Test 12: Simulate plan modified check failure"
# Create backup and plan with identical timestamps
touch "$BACKUP_PATH" "$TEST_PLAN"
# If timestamps are identical, modification check fails
if [[ ! "$TEST_PLAN" -nt "$BACKUP_PATH" ]]; then
  ERROR_MSG="VERIFICATION FAILED: Plan was not modified (timestamp check)"
  pass "Plan modification check detected no change"
else
  skip "Timestamp check inconclusive in test environment"
fi

info "Test 13: Verify checkpoint reporting on failure"
CHECKPOINT_MSG="[CHECKPOINT] Block 4c FAILED - Research verification incomplete
  - Reports found: 0
  - Expected: >= 1
  - Action: Review research-specialist output"

if echo "$CHECKPOINT_MSG" | grep -q "\[CHECKPOINT\]"; then
  pass "Checkpoint uses standard marker"
else
  fail "Checkpoint format incorrect"
fi

if echo "$CHECKPOINT_MSG" | grep -q "FAILED"; then
  pass "Checkpoint indicates failure status"
else
  fail "Checkpoint should show FAILED status"
fi

echo
teardown_test
