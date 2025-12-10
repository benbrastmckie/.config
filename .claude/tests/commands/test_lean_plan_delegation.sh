#!/usr/bin/env bash
# Test: /lean-plan delegation enforcement
# Validates that the command properly enforces lean-plan-architect agent delegation

set -euo pipefail

# === DETECT PROJECT ROOT ===
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  CLAUDE_PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi

# === TEST METADATA ===
TEST_NAME="lean-plan-delegation-enforcement"
TEST_DESCRIPTION="Verify /lean-plan enforces lean-plan-architect agent delegation"
TESTS_PASSED=0
TESTS_FAILED=0

# === HELPER FUNCTIONS ===
run_test() {
  local test_func="$1"
  if $test_func; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

print_test_summary() {
  echo ""
  echo "============================================"
  echo "Test Summary: $TEST_NAME"
  echo "============================================"
  echo "Passed: $TESTS_PASSED"
  echo "Failed: $TESTS_FAILED"
  echo "Total:  $((TESTS_PASSED + TESTS_FAILED))"
  echo "============================================"

  if [ $TESTS_FAILED -eq 0 ]; then
    echo "Result: ALL TESTS PASSED"
    exit 0
  else
    echo "Result: SOME TESTS FAILED"
    exit 1
  fi
}

# === TEST 1: Verify PLAN_CREATED signal validation ===
test_plan_created_signal() {
  echo "Test 1: Verify PLAN_CREATED signal validation"

  # Read lean-plan command to verify signal check exists
  if ! grep -q "PLAN_CREATED:" "${CLAUDE_PROJECT_DIR}/.claude/commands/lean-plan.md"; then
    echo "FAIL: lean-plan.md missing PLAN_CREATED signal check"
    return 1
  fi

  # Verify signal extraction logic exists
  if ! grep -q "grep \"PLAN_CREATED:\"" "${CLAUDE_PROJECT_DIR}/.claude/commands/lean-plan.md"; then
    echo "FAIL: lean-plan.md missing signal extraction logic"
    return 1
  fi

  # Verify path matching validation exists
  if ! grep -q "SIGNAL_PATH.*PLAN_PATH" "${CLAUDE_PROJECT_DIR}/.claude/commands/lean-plan.md"; then
    echo "FAIL: lean-plan.md missing signal path validation"
    return 1
  fi

  echo "PASS: PLAN_CREATED signal validation logic present"
  return 0
}

# === TEST 2: Verify Phase Routing Summary validation ===
test_phase_routing_validation() {
  echo "Test 2: Verify Phase Routing Summary validation"

  # Verify Phase Routing Summary check exists
  if ! grep -q "Phase Routing Summary" "${CLAUDE_PROJECT_DIR}/.claude/commands/lean-plan.md"; then
    echo "FAIL: lean-plan.md missing Phase Routing Summary check"
    return 1
  fi

  # Verify implementer field count exists
  if ! grep -q "implementer:" "${CLAUDE_PROJECT_DIR}/.claude/commands/lean-plan.md"; then
    echo "FAIL: lean-plan.md missing implementer field validation"
    return 1
  fi

  echo "PASS: Phase Routing Summary validation logic present"
  return 0
}

# === TEST 3: Verify delegation warning in Block 2b-exec ===
test_delegation_warning() {
  echo "Test 3: Verify delegation warning in Block 2b-exec"

  # Verify warning against Write tool exists
  if ! grep -q "DO NOT use Write tool directly" "${CLAUDE_PROJECT_DIR}/.claude/commands/lean-plan.md"; then
    echo "FAIL: lean-plan.md missing Write tool warning"
    return 1
  fi

  # Verify bypass warning exists
  if ! grep -q "DO NOT bypass agent delegation" "${CLAUDE_PROJECT_DIR}/.claude/commands/lean-plan.md"; then
    echo "FAIL: lean-plan.md missing delegation bypass warning"
    return 1
  fi

  # Verify explanation exists
  if ! grep -q "performs theorem dependency analysis" "${CLAUDE_PROJECT_DIR}/.claude/commands/lean-plan.md"; then
    echo "FAIL: lean-plan.md missing delegation rationale"
    return 1
  fi

  echo "PASS: Delegation warning present in Block 2b-exec"
  return 0
}

# === TEST 4: Verify documentation exists ===
test_documentation_exists() {
  echo "Test 4: Verify delegation pattern documentation exists"

  DOC_PATH="${CLAUDE_PROJECT_DIR}/.claude/docs/guides/commands/lean-plan-command-guide.md"

  # Verify documentation file exists
  if [ ! -f "$DOC_PATH" ]; then
    echo "FAIL: lean-plan-command-guide.md not found"
    return 1
  fi

  # Verify Agent Delegation Pattern section exists
  if ! grep -q "## Architecture" "$DOC_PATH"; then
    echo "FAIL: Documentation missing Architecture section"
    return 1
  fi

  if ! grep -q "### Agent Delegation Pattern" "$DOC_PATH"; then
    echo "FAIL: Documentation missing Agent Delegation Pattern section"
    return 1
  fi

  # Verify delegation flow diagram exists
  if ! grep -q "Delegation Flow" "$DOC_PATH"; then
    echo "FAIL: Documentation missing delegation flow diagram"
    return 1
  fi

  # Verify anti-patterns documented
  if ! grep -q "Common Bypass Anti-Patterns" "$DOC_PATH"; then
    echo "FAIL: Documentation missing anti-patterns section"
    return 1
  fi

  echo "PASS: Delegation pattern documentation complete"
  return 0
}

# === TEST 5: Verify error logging integration ===
test_error_logging() {
  echo "Test 5: Verify error logging for delegation violations"

  # Verify log_command_error called for missing signal
  if ! grep -q "PLAN_CREATED signal missing" "${CLAUDE_PROJECT_DIR}/.claude/commands/lean-plan.md"; then
    echo "FAIL: lean-plan.md missing error log for missing signal"
    return 1
  fi

  # Verify log_command_error exists in delegation section
  if ! grep -B5 -A5 "PLAN_CREATED signal missing" "${CLAUDE_PROJECT_DIR}/.claude/commands/lean-plan.md" | grep -q "log_command_error"; then
    echo "FAIL: log_command_error not called for missing signal"
    return 1
  fi

  # Verify log_command_error called for path mismatch
  if ! grep -q "mismatched path" "${CLAUDE_PROJECT_DIR}/.claude/commands/lean-plan.md"; then
    echo "FAIL: lean-plan.md missing error log for path mismatch"
    return 1
  fi

  # Verify log_command_error called for missing metadata
  if ! grep -q "Phase Routing Summary" "${CLAUDE_PROJECT_DIR}/.claude/commands/lean-plan.md"; then
    echo "FAIL: lean-plan.md missing error log for missing metadata"
    return 1
  fi

  echo "PASS: Error logging integrated for delegation violations"
  return 0
}

# === RUN TESTS ===
run_test test_plan_created_signal
run_test test_phase_routing_validation
run_test test_delegation_warning
run_test test_documentation_exists
run_test test_error_logging

# === REPORT ===
print_test_summary "$TEST_NAME"
