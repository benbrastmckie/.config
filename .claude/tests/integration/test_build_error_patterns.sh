#!/usr/bin/env bash
# test_build_error_patterns.sh - Regression tests for /build command error patterns
# Spec: 976_repair_build_20251129_180227
#
# This test suite prevents recurrence of resolved error patterns identified in error log analysis.
# Each test case corresponds to a specific error pattern that was previously encountered and fixed.

# Set test mode to prevent library initialization issues
export CLAUDE_TEST_MODE=1

# Test framework setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Go up from .claude/tests/integration to project root (.config)
PROJECT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Color output for test results
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helpers
test_passed() {
  local test_name="$1"
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo -e "${GREEN}✓${NC} Test $TESTS_RUN: $test_name"
}

test_failed() {
  local test_name="$1"
  local reason="${2:-Test function returned non-zero exit code}"
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo -e "${RED}✗${NC} Test $TESTS_RUN: $test_name"
  echo "  Reason: $reason"
}

run_test() {
  local test_name="$1"
  shift
  TESTS_RUN=$((TESTS_RUN + 1))
  echo ""
  echo "Running Test $TESTS_RUN: $test_name..."
  if "$@"; then
    test_passed "$test_name"
  else
    test_failed "$test_name"
  fi
}

# ==============================================================================
# Test Cases
# ==============================================================================

test_1() {
  grep -q "save_completed_states_to_state()" "$PROJECT_DIR/.claude/lib/workflow/workflow-state-machine.sh"
}

test_2() {
  grep -q 'STATE_FILE not set' "$PROJECT_DIR/.claude/lib/workflow/workflow-state-machine.sh"
}

test_3() {
  local transitions=$(grep '\[implement\]=' "$PROJECT_DIR/.claude/lib/workflow/workflow-state-machine.sh" | head -1)
  [[ "$transitions" == *'"test"'* ]] && [[ "$transitions" != *'"complete"'* ]]
}

test_4() {
  local transitions=$(grep '\[debug\]=' "$PROJECT_DIR/.claude/lib/workflow/workflow-state-machine.sh" | head -1)
  [[ "$transitions" == *"document"* ]]
}

test_5() {
  # Test defensive pattern in build.md
  grep -q 'find.*2>/dev/null.*wc -l' "$PROJECT_DIR/.claude/commands/build.md"
}

test_6() {
  # Test variable validation pattern
  grep -q 'if \[ -z.*\]; then' "$PROJECT_DIR/.claude/commands/build.md"
}

test_7() {
  # Test parameter count validation in log_command_error
  grep -q 'if \[ \$# -lt 6 \]; then' "$PROJECT_DIR/.claude/lib/core/error-handling.sh"
}

test_8() {
  # Test 7th parameter has default value
  grep -q 'context_json="${7:-}"' "$PROJECT_DIR/.claude/lib/core/error-handling.sh"
}

test_9() {
  # Test pre-flight validation function exists
  grep -q 'validate_build_prerequisites()' "$PROJECT_DIR/.claude/commands/build.md"
}

test_10() {
  # Test plan file validation with error messages
  grep -q 'Plan file not found' "$PROJECT_DIR/.claude/commands/build.md"
}

# ==============================================================================
# Test Execution
# ==============================================================================

main() {
  echo "=========================================="
  echo "Build Error Patterns Regression Test Suite"
  echo "=========================================="
  echo ""
  echo "Spec: 976_repair_build_20251129_180227"
  echo "Purpose: Prevent recurrence of resolved error patterns"
  echo ""

  run_test "save_completed_states_to_state function exists" test_1
  run_test "STATE_FILE validation in sm_transition" test_2
  run_test "implement→test sequence enforced (no direct complete)" test_3
  run_test "debug→document transition allowed" test_4
  run_test "Defensive find pattern with error suppression" test_5
  run_test "Variable validation checks" test_6
  run_test "log_command_error parameter count validation" test_7
  run_test "log_command_error 7th parameter optional" test_8
  run_test "Pre-flight validation function exists" test_9
  run_test "Plan file validation with error messages" test_10

  # Print summary
  echo ""
  echo "=========================================="
  echo "Test Summary"
  echo "=========================================="
  echo "Total tests run: $TESTS_RUN"
  echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
  echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
  echo ""

  if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}ALL REGRESSION TESTS PASSED${NC}"
    exit 0
  else
    echo -e "${RED}REGRESSION TESTS FAILED${NC}"
    exit 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
