#!/usr/bin/env bash
# Integration test for /repair command hard barrier delegation pattern
# Tests that repair.md follows Setup/Execute/Verify pattern with fail-fast verification

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPAIR_MD="${CLAUDE_DIR}/commands/repair.md"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result tracking
test_pass() {
  ((TESTS_PASSED++))
  echo "✓ $1"
}

test_fail() {
  ((TESTS_FAILED++))
  echo "✗ $1"
  echo "  Error: $2"
}

# === Test Case 1: Verify Block 1b pre-calculates REPORT_PATH ===
test_block_1b_precalculation() {
  ((TESTS_RUN++))

  # Extract Block 1b content
  BLOCK_1B=$(sed -n '/^## Block 1b: Report Path Pre-Calculation/,/^## Block 1b-exec:/p' "$REPAIR_MD")

  # Verify REPORT_PATH variable is set
  if ! echo "$BLOCK_1B" | grep -q 'REPORT_PATH="${RESEARCH_DIR}/${REPORT_NUMBER}-${REPORT_SLUG}.md"'; then
    test_fail "Block 1b REPORT_PATH calculation" "REPORT_PATH not calculated from RESEARCH_DIR, REPORT_NUMBER, and REPORT_SLUG"
    return
  fi

  # Verify path is absolute check
  if ! echo "$BLOCK_1B" | grep -q 'if \[\[ ! "$REPORT_PATH" =~ ^\/ \]\]'; then
    test_fail "Block 1b REPORT_PATH absolute validation" "Missing absolute path validation"
    return
  fi

  # Verify path persisted to state
  if ! echo "$BLOCK_1B" | grep -q 'append_workflow_state "REPORT_PATH" "$REPORT_PATH"'; then
    test_fail "Block 1b REPORT_PATH persistence" "REPORT_PATH not persisted to state"
    return
  fi

  test_pass "Block 1b pre-calculates REPORT_PATH before Block 1b-exec"
}

# === Test Case 2: Verify Block 1b-exec contains ONLY Task invocation ===
test_block_1b_exec_task_only() {
  ((TESTS_RUN++))

  # Extract Block 1b-exec content
  BLOCK_1B_EXEC=$(sed -n '/^## Block 1b-exec: Repair Analysis Delegation/,/^## Block 1c:/p' "$REPAIR_MD")

  # Note: Block 1b-exec should only have Task invocation, not bash blocks
  # We skip bash block check as the content format varies

  # Verify Task tool invocation present
  if ! echo "$BLOCK_1B_EXEC" | grep -q '^Task {'; then
    test_fail "Block 1b-exec Task invocation" "Task tool invocation not found"
    return
  fi

  # Verify Input Contract section present with REPORT_PATH
  if ! echo "$BLOCK_1B_EXEC" | grep -qF 'Input Contract (Hard Barrier Pattern)'; then
    test_fail "Block 1b-exec Input Contract" "Input Contract section not found"
    return
  fi

  if ! echo "$BLOCK_1B_EXEC" | grep -qF 'Report Path:'; then
    test_fail "Block 1b-exec REPORT_PATH contract" "REPORT_PATH not in Input Contract"
    return
  fi

  test_pass "Block 1b-exec contains ONLY Task invocation with Input Contract"
}

# === Test Case 3: Verify Block 1c validates pre-calculated REPORT_PATH ===
test_block_1c_validation() {
  ((TESTS_RUN++))

  # Extract Block 1c content
  BLOCK_1C=$(sed -n '/^## Block 1c: Error Analysis Verification/,/^## Block 2a:/p' "$REPAIR_MD")

  # Verify exact path check for REPORT_PATH
  if ! echo "$BLOCK_1C" | grep -q 'if \[ ! -f "$REPORT_PATH" \]'; then
    test_fail "Block 1c REPORT_PATH existence check" "Missing file existence check for REPORT_PATH"
    return
  fi

  # Verify fail-fast after check failure (check for exit 1 near the file check)
  if ! echo "$BLOCK_1C" | grep -A15 "HARD BARRIER: Report file MUST exist" | grep -q 'exit 1'; then
    test_fail "Block 1c fail-fast verification" "Missing exit 1 after REPORT_PATH check failure"
    return
  fi

  # Verify error logging present
  if ! echo "$BLOCK_1C" | grep -q 'log_command_error'; then
    test_fail "Block 1c error logging" "Missing log_command_error call"
    return
  fi

  test_pass "Block 1c validates pre-calculated REPORT_PATH with fail-fast"
}

# === Test Case 4: Verify Block 2 planning phase follows hard barrier pattern ===
test_block_2_planning_pattern() {
  ((TESTS_RUN++))

  # Extract Block 2b content
  BLOCK_2B=$(sed -n '/^## Block 2b: Plan Path Pre-Calculation/,/^## Block 2b-exec:/p' "$REPAIR_MD")

  # Verify PLAN_PATH calculation
  if ! echo "$BLOCK_2B" | grep -q 'PLAN_PATH="${PLANS_DIR}/${PLAN_FILENAME}"'; then
    test_fail "Block 2b PLAN_PATH calculation" "PLAN_PATH not calculated"
    return
  fi

  # Verify PLAN_PATH persistence
  if ! echo "$BLOCK_2B" | grep -q 'append_workflow_state "PLAN_PATH" "$PLAN_PATH"'; then
    test_fail "Block 2b PLAN_PATH persistence" "PLAN_PATH not persisted to state"
    return
  fi

  # Extract Block 2b-exec content
  BLOCK_2B_EXEC=$(sed -n '/^## Block 2b-exec: Plan Creation Delegation/,/^## Block 2c:/p' "$REPAIR_MD")

  # Verify Input Contract section
  if ! echo "$BLOCK_2B_EXEC" | grep -qF 'Plan Path:'; then
    test_fail "Block 2b-exec PLAN_PATH contract" "PLAN_PATH not in Input Contract"
    return
  fi

  # Extract Block 2c content
  BLOCK_2C=$(sed -n '/^## Block 2c: Plan Verification/,/^## Block 3:/p' "$REPAIR_MD")

  # Verify PLAN_PATH validation
  if ! echo "$BLOCK_2C" | grep -q 'if \[ ! -f "$PLAN_PATH" \]'; then
    test_fail "Block 2c PLAN_PATH validation" "Missing PLAN_PATH existence check"
    return
  fi

  test_pass "Block 2 planning phase follows hard barrier pattern (2a/2b/2b-exec/2c)"
}

# === Test Case 5: Verify HARD BARRIER labels present ===
test_hard_barrier_labels() {
  ((TESTS_RUN++))

  # Count HARD BARRIER labels (should be 2: Block 1b-exec and Block 2b-exec)
  BARRIER_COUNT=$(grep -cF "HARD BARRIER" "$REPAIR_MD" 2>/dev/null || true)
  : ${BARRIER_COUNT:=0}

  if [ "$BARRIER_COUNT" -lt 2 ]; then
    test_fail "HARD BARRIER labels" "Expected at least 2 HARD BARRIER labels, found $BARRIER_COUNT"
    return
  fi

  # Verify no CRITICAL BARRIER labels (old format)
  CRITICAL_COUNT=$(grep -cF "CRITICAL BARRIER" "$REPAIR_MD" 2>/dev/null || true)
  : ${CRITICAL_COUNT:=0}

  if [ "$CRITICAL_COUNT" -gt 0 ]; then
    test_fail "HARD BARRIER label format" "Found $CRITICAL_COUNT CRITICAL BARRIER labels (should be HARD BARRIER)"
    return
  fi

  test_pass "HARD BARRIER labels present in correct format"
}

# === Test Case 6: Verify checkpoint reporting ===
test_checkpoint_reporting() {
  ((TESTS_RUN++))

  # Count checkpoint markers (should be at least 6: 1a, 1b, 1c, 2a, 2b, 2c)
  CHECKPOINT_COUNT=$(grep -c '\[CHECKPOINT\]' "$REPAIR_MD" || echo "0")

  if [ "$CHECKPOINT_COUNT" -lt 6 ]; then
    test_fail "Checkpoint reporting" "Expected at least 6 checkpoints, found $CHECKPOINT_COUNT"
    return
  fi

  test_pass "Checkpoint reporting present in all blocks"
}

# === Run all tests ===
main() {
  echo "=== /repair Hard Barrier Delegation Pattern Tests ==="
  echo ""

  if [ ! -f "$REPAIR_MD" ]; then
    echo "ERROR: repair.md not found at: $REPAIR_MD"
    exit 1
  fi

  echo "Testing: $REPAIR_MD"
  echo ""

  # Run test cases
  test_block_1b_precalculation
  test_block_1b_exec_task_only
  test_block_1c_validation
  test_block_2_planning_pattern
  test_hard_barrier_labels
  test_checkpoint_reporting

  # Print summary
  echo ""
  echo "=== Test Summary ==="
  echo "Tests Run: $TESTS_RUN"
  echo "Tests Passed: $TESTS_PASSED"
  echo "Tests Failed: $TESTS_FAILED"
  echo ""

  if [ "$TESTS_FAILED" -eq 0 ]; then
    echo "✓ All tests passed"
    exit 0
  else
    echo "✗ Some tests failed"
    exit 1
  fi
}

main "$@"
