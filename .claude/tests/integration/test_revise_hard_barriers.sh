#!/usr/bin/env bash

# Test: /revise command hard barrier enforcement
# Validates that hard barrier blocks prevent workflow bypass

set -euo pipefail

# === TEST CONFIGURATION ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Navigate to .config (PROJECT_ROOT is ~/.config, not ~/.config/.claude)
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CLAUDE_PROJECT_DIR="$PROJECT_ROOT"
export CLAUDE_PROJECT_DIR

# Source test utilities if available
if [ -f "$PROJECT_ROOT/.claude/tests/test_utils.sh" ]; then
  source "$PROJECT_ROOT/.claude/tests/test_utils.sh"
fi

# === TEST COUNTERS ===
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# === HELPER FUNCTIONS ===
log_test() {
  echo "[TEST] $1"
}

log_pass() {
  echo "[PASS] $1"
  TESTS_PASSED=$((TESTS_PASSED + 1))
}

log_fail() {
  echo "[FAIL] $1"
  TESTS_FAILED=$((TESTS_FAILED + 1))
}

run_test() {
  local test_name="$1"
  local test_function="$2"

  TESTS_RUN=$((TESTS_RUN + 1))
  log_test "$test_name"

  if $test_function; then
    log_pass "$test_name"
    return 0
  else
    log_fail "$test_name"
    return 0  # Continue running tests even on failure
  fi
}

# === TEST FIXTURES ===
setup_test_fixtures() {
  TEST_DIR=$(mktemp -d)
  TEST_PLAN="$TEST_DIR/test_plan.md"

  # Create a minimal test plan
  cat > "$TEST_PLAN" <<'EOF'
# Test Implementation Plan

## Metadata

**Date**: 2025-12-09
**Feature**: Test feature for hard barrier validation
**Status**: [NOT STARTED]
**Estimated Hours**: 1-2 hours
**Standards File**: /home/benjamin/.config/CLAUDE.md
**Research Reports**: none

---

### Phase 1: Test Phase [NOT STARTED]

**Objective**: Test phase for validation

**Success Criteria**:
- [ ] Test task 1
- [ ] Test task 2

#### Task 1.1: Test Task
- [ ] Subtask A
- [ ] Subtask B

EOF

  echo "$TEST_DIR"
}

cleanup_test_fixtures() {
  local test_dir="$1"
  if [ -d "$test_dir" ]; then
    rm -rf "$test_dir"
  fi
}

# === TEST CASES ===

# Test 1: Verify Block 3a state machine barrier exists
test_state_machine_barrier_block_exists() {
  local revise_cmd="$PROJECT_ROOT/.claude/commands/revise.md"

  # Check for Block 3a heading
  if ! grep -q "## Block 3a: State Machine Initialization Verification" "$revise_cmd"; then
    echo "  Block 3a heading not found"
    return 1
  fi

  # Check for HARD BARRIER label
  if ! grep -q "HARD BARRIER FAILED: State ID file not found" "$revise_cmd"; then
    echo "  State ID validation not found"
    return 1
  fi

  # Check for exit 1 on failure
  if ! grep -A5 "State ID file not found" "$revise_cmd" | grep -q "exit 1"; then
    echo "  Fail-fast exit not found"
    return 1
  fi

  return 0
}

# Test 2: Verify research phase hard barrier pattern (Block 4a-4c)
test_research_phase_hard_barrier() {
  local revise_cmd="$PROJECT_ROOT/.claude/commands/revise.md"

  # Check for path pre-calculation in Block 4a
  if ! grep -q "EXPECTED_REPORT_PATH=" "$revise_cmd"; then
    echo "  EXPECTED_REPORT_PATH pre-calculation not found"
    return 1
  fi

  # Check for imperative directive in Block 4b
  if ! grep -q "EXECUTE NOW.*USE the Task tool.*research-specialist" "$revise_cmd"; then
    echo "  Imperative Task directive not found in Block 4b"
    return 1
  fi

  # Check for fail-fast verification in Block 4c
  if ! grep -q 'if \[ ! -f "\$EXPECTED_REPORT_PATH" \]' "$revise_cmd"; then
    echo "  Fail-fast report validation not found in Block 4c"
    return 1
  fi

  return 0
}

# Test 3: Verify plan revision phase hard barrier pattern (Block 5a-5c)
test_plan_revision_hard_barrier() {
  local revise_cmd="$PROJECT_ROOT/.claude/commands/revise.md"

  # Check for backup path pre-calculation in Block 5a
  if ! grep -q "Pre-calculate backup path" "$revise_cmd"; then
    echo "  Backup path pre-calculation not found"
    return 1
  fi

  # Check for imperative directive in Block 5b
  if ! grep -q "EXECUTE NOW.*USE the Task tool.*plan-architect" "$revise_cmd"; then
    echo "  Imperative Task directive not found in Block 5b"
    return 1
  fi

  # Check for backup verification in Block 5c
  if ! grep -q 'if \[ ! -f "\$BACKUP_PATH" \]' "$revise_cmd"; then
    echo "  Backup existence validation not found in Block 5c"
    return 1
  fi

  # Check for plan modification verification
  if ! grep -q 'cmp -s "\$EXISTING_PLAN_PATH" "\$BACKUP_PATH"' "$revise_cmd"; then
    echo "  Plan modification validation not found"
    return 1
  fi

  return 0
}

# Test 4: Verify error logging integration
test_error_logging_integration() {
  local revise_cmd="$PROJECT_ROOT/.claude/commands/revise.md"

  # Count log_command_error calls in verification blocks
  local error_log_calls
  error_log_calls=$(grep -c "log_command_error" "$revise_cmd" 2>/dev/null || echo 0)

  if [ "$error_log_calls" -lt 5 ]; then
    echo "  Insufficient error logging calls (found: $error_log_calls, expected: >= 5)"
    return 1
  fi

  # Check for agent_error type
  if ! grep -q '"agent_error"' "$revise_cmd"; then
    echo "  agent_error type not found"
    return 1
  fi

  # Check for validation_error type
  if ! grep -q '"validation_error"' "$revise_cmd"; then
    echo "  validation_error type not found"
    return 1
  fi

  return 0
}

# Test 5: Verify checkpoint reporting
test_checkpoint_reporting() {
  local revise_cmd="$PROJECT_ROOT/.claude/commands/revise.md"

  # Check for checkpoint labels
  local checkpoint_count
  checkpoint_count=$(grep -c "\[CHECKPOINT\]" "$revise_cmd" 2>/dev/null || echo 0)

  if [ "$checkpoint_count" -lt 3 ]; then
    echo "  Insufficient checkpoint reports (found: $checkpoint_count, expected: >= 3)"
    return 1
  fi

  # Check for hard barrier passed messages
  if ! grep -q "Hard barrier passed" "$revise_cmd"; then
    echo "  Hard barrier passed message not found"
    return 1
  fi

  return 0
}

# Test 6: Verify recovery instructions in error messages
test_recovery_instructions() {
  local revise_cmd="$PROJECT_ROOT/.claude/commands/revise.md"

  # Check for RECOVERY labels
  local recovery_count
  recovery_count=$(grep -c "RECOVERY:" "$revise_cmd" 2>/dev/null || echo 0)

  if [ "$recovery_count" -lt 3 ]; then
    echo "  Insufficient recovery instructions (found: $recovery_count, expected: >= 3)"
    return 1
  fi

  # Check for DIAGNOSTIC labels
  if ! grep -q "DIAGNOSTIC:" "$revise_cmd"; then
    echo "  DIAGNOSTIC labels not found"
    return 1
  fi

  return 0
}

# Test 7: Verify all Task blocks have imperative directives
test_all_task_blocks_have_directives() {
  local revise_cmd="$PROJECT_ROOT/.claude/commands/revise.md"

  # Run the Task invocation pattern linter
  local lint_output
  lint_output=$(bash "$PROJECT_ROOT/.claude/scripts/lint-task-invocation-pattern.sh" "$revise_cmd" 2>&1)

  if echo "$lint_output" | grep -q "ERROR violations: 0"; then
    return 0
  else
    echo "  Task invocation pattern linter found violations:"
    echo "$lint_output"
    return 1
  fi
}

# Test 8: Verify full hard barrier compliance
test_full_hard_barrier_compliance() {
  local revise_cmd="$PROJECT_ROOT/.claude/commands/revise.md"

  # Run the hard barrier compliance validator
  local compliance_output
  compliance_output=$(bash "$PROJECT_ROOT/.claude/scripts/validate-hard-barrier-compliance.sh" --command revise 2>&1)

  if echo "$compliance_output" | grep -q "Compliance: 100%"; then
    return 0
  else
    echo "  Hard barrier compliance check failed:"
    echo "$compliance_output"
    return 1
  fi
}

# === MAIN TEST RUNNER ===
main() {
  echo "═══════════════════════════════════════════════════════════════"
  echo "  /revise Command Hard Barrier Integration Tests"
  echo "═══════════════════════════════════════════════════════════════"
  echo ""

  # Run tests
  run_test "Block 3a state machine barrier exists" test_state_machine_barrier_block_exists
  run_test "Research phase hard barrier pattern (Block 4a-4c)" test_research_phase_hard_barrier
  run_test "Plan revision hard barrier pattern (Block 5a-5c)" test_plan_revision_hard_barrier
  run_test "Error logging integration" test_error_logging_integration
  run_test "Checkpoint reporting" test_checkpoint_reporting
  run_test "Recovery instructions" test_recovery_instructions
  run_test "All Task blocks have imperative directives" test_all_task_blocks_have_directives
  run_test "Full hard barrier compliance" test_full_hard_barrier_compliance

  echo ""
  echo "═══════════════════════════════════════════════════════════════"
  echo "  Test Results"
  echo "═══════════════════════════════════════════════════════════════"
  echo "  Total:  $TESTS_RUN"
  echo "  Passed: $TESTS_PASSED"
  echo "  Failed: $TESTS_FAILED"
  echo "═══════════════════════════════════════════════════════════════"

  if [ "$TESTS_FAILED" -gt 0 ]; then
    exit 1
  fi

  exit 0
}

# Run main function
main "$@"
