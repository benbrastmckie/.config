#!/usr/bin/env bash
# Integration test for /repair workflow fixes (Spec 024)
# Tests all five fixed error patterns

set -euo pipefail

# Detect project directory
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  CLAUDE_PROJECT_DIR="${HOME}/.config"
fi

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test 1: State Transition Sequence
test_state_transition_sequence() {
  local test_name="State Transition Sequence (initialize -> research -> plan)"
  TESTS_RUN=$((TESTS_RUN + 1))

  echo "Running: $test_name"

  # Verify repair.md has correct transition at line 236
  if grep -q 'sm_transition "\$STATE_RESEARCH"' "${CLAUDE_PROJECT_DIR}/.claude/commands/repair.md"; then
    echo "  ✓ Block 1a transitions to STATE_RESEARCH"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  ✗ FAIL: Block 1a should transition to STATE_RESEARCH"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi

  # Verify Block 2a transitions to STATE_PLAN
  if grep -q 'sm_transition "\$STATE_PLAN"' "${CLAUDE_PROJECT_DIR}/.claude/commands/repair.md"; then
    echo "  ✓ Block 2a transitions to STATE_PLAN"
  else
    echo "  ✗ FAIL: Block 2a should transition to STATE_PLAN"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi

  return 0
}

# Test 2: Preprocessing-Safe Conditionals
test_preprocessing_safe_conditionals() {
  local test_name="Preprocessing-Safe Conditionals (no escaped negation)"
  TESTS_RUN=$((TESTS_RUN + 1))

  echo "Running: $test_name"

  # Run conditional validator
  if bash "${CLAUDE_PROJECT_DIR}/.claude/scripts/validate-all-standards.sh" --conditionals 2>&1 | grep -q "PASSED"; then
    echo "  ✓ No preprocessing-unsafe conditionals found"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo "  ✗ FAIL: Conditional validator found violations"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Test 3: Structured Data Support
test_structured_data_support() {
  local test_name="Structured Data Support (JSON allowlist)"
  TESTS_RUN=$((TESTS_RUN + 1))

  echo "Running: $test_name"

  # Verify ERROR_FILTERS is in allowlist
  if grep -q '"ERROR_FILTERS"' "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"; then
    echo "  ✓ ERROR_FILTERS in JSON allowlist"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  ✗ FAIL: ERROR_FILTERS not in allowlist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi

  # Verify /repair uses flat keys
  if grep -q 'ERROR_FILTER_SINCE="\$ERROR_SINCE"' "${CLAUDE_PROJECT_DIR}/.claude/commands/repair.md"; then
    echo "  ✓ /repair uses flat keys for filters"
  else
    echo "  ✗ FAIL: /repair should use flat keys"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi

  return 0
}

# Test 4: State Machine Initialization Guards
test_initialization_guards() {
  local test_name="State Machine Initialization Guards"
  TESTS_RUN=$((TESTS_RUN + 1))

  echo "Running: $test_name"

  # Verify CURRENT_STATE check exists
  if grep -q 'if \[ -z "\${CURRENT_STATE:-}" \]; then' "${CLAUDE_PROJECT_DIR}/.claude/commands/repair.md"; then
    echo "  ✓ CURRENT_STATE initialization guard present"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  ✗ FAIL: Missing CURRENT_STATE initialization guard"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi

  # Verify terminal state detection exists
  if grep -q 'EXPECTED_STATE_FILE="\${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_\${WORKFLOW_ID}.sh"' "${CLAUDE_PROJECT_DIR}/.claude/commands/repair.md"; then
    echo "  ✓ Terminal state detection present"
  else
    echo "  ✗ FAIL: Missing terminal state detection"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi

  return 0
}

# Test 5: Parameter Validation
test_parameter_validation() {
  local test_name="Parameter Validation in State Persistence"
  TESTS_RUN=$((TESTS_RUN + 1))

  echo "Running: $test_name"

  # Verify append_workflow_state has parameter count check
  if grep -q 'if \[ \$# -lt 2 \]; then' "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"; then
    echo "  ✓ Parameter count validation present"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo "  ✗ FAIL: Missing parameter count validation"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Run all tests
echo "=========================================="
echo "Testing /repair Workflow Fixes (Spec 024)"
echo "=========================================="
echo ""

test_state_transition_sequence
test_preprocessing_safe_conditionals
test_structured_data_support
test_initialization_guards
test_parameter_validation

# Summary
echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Tests Run:    $TESTS_RUN"
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo "✓ All tests passed"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
