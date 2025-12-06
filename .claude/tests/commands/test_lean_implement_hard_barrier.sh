#!/usr/bin/env bash
# test_lean_implement_hard_barrier.sh
#
# Integration tests for /lean-implement hard barrier pattern
# Tests coordinator delegation enforcement and routing logic

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source test utilities
source "$PROJECT_ROOT/lib/core/base-utils.sh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result tracking
declare -a FAILED_TESTS=()

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test helper functions
pass() {
  echo -e "${GREEN}✓${NC} $1"
  TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
  echo -e "${RED}✗${NC} $1"
  TESTS_FAILED=$((TESTS_FAILED + 1))
  FAILED_TESTS+=("$1")
}

run_test() {
  local test_name="$1"
  TESTS_RUN=$((TESTS_RUN + 1))
  echo ""
  echo -e "${YELLOW}Running:${NC} $test_name"
}

# Setup test environment
setup_test_env() {
  TEST_WORKSPACE="${PROJECT_ROOT}/.claude/tmp/test_lean_implement_$$"
  mkdir -p "$TEST_WORKSPACE"

  TEST_TOPIC="${TEST_WORKSPACE}/test_topic"
  mkdir -p "$TEST_TOPIC"/{plans,summaries,reports,outputs,debug}

  export TEST_WORKSPACE TEST_TOPIC
}

# Cleanup test environment
cleanup_test_env() {
  if [ -d "$TEST_WORKSPACE" ]; then
    rm -rf "$TEST_WORKSPACE"
  fi
}

# Test 1: Verify Block 1b has hard barrier marker
test_block_1b_structure() {
  run_test "Test Case 1: Verify Block 1b hard barrier structure"

  local lean_implement_file="$PROJECT_ROOT/commands/lean-implement.md"

  # Check for HARD BARRIER marker in Block 1b
  if grep -q "\[HARD BARRIER\]" "$lean_implement_file"; then
    pass "Block 1b has [HARD BARRIER] marker"
  else
    fail "Block 1b missing [HARD BARRIER] marker"
  fi

  # Check for coordinator name determination
  if grep -q "COORDINATOR_NAME=" "$lean_implement_file"; then
    pass "Block 1b determines coordinator name"
  else
    fail "Block 1b does not determine coordinator name"
  fi

  # Check for coordinator name persistence
  if grep -q 'append_workflow_state "COORDINATOR_NAME"' "$lean_implement_file"; then
    pass "Block 1b persists coordinator name to state"
  else
    fail "Block 1b does not persist coordinator name"
  fi

  # Count Task invocations (should be 2: one for each coordinator)
  local task_count=$(grep -c '^Task {' "$lean_implement_file" || echo "0")
  if [ "$task_count" -eq 2 ]; then
    pass "Block 1b has exactly 2 Task invocations (lean + software)"
  else
    fail "Block 1b has $task_count Task invocations (expected 2)"
  fi
}

# Test 2: Verify Block 1c has hard barrier verification
test_block_1c_verification() {
  run_test "Test Case 2: Verify Block 1c hard barrier verification"

  local lean_implement_file="$PROJECT_ROOT/commands/lean-implement.md"

  # Check for summary existence validation
  if grep -q "HARD BARRIER FAILED" "$lean_implement_file"; then
    pass "Block 1c has hard barrier failure message"
  else
    fail "Block 1c missing hard barrier failure message"
  fi

  # Check for file size validation (≥100 bytes)
  if grep -q "SUMMARY_SIZE.*100" "$lean_implement_file"; then
    pass "Block 1c validates summary file size"
  else
    fail "Block 1c does not validate summary file size"
  fi

  # Check for error logging integration
  if grep -q "log_command_error" "$lean_implement_file"; then
    pass "Block 1c integrates error logging"
  else
    fail "Block 1c does not integrate error logging"
  fi

  # Check for coordinator name in error messages
  if grep -q '\$COORDINATOR_NAME' "$lean_implement_file"; then
    pass "Block 1c uses coordinator name in error messages"
  else
    fail "Block 1c does not use coordinator name in error messages"
  fi
}

# Test 3: Verify routing enhancement (Tier 1 discovery)
test_routing_enhancement() {
  run_test "Test Case 3: Verify routing enhancement with implementer field"

  local lean_implement_file="$PROJECT_ROOT/commands/lean-implement.md"

  # Check for implementer field detection in detect_phase_type
  if grep -q 'implementer:' "$lean_implement_file"; then
    pass "detect_phase_type() reads implementer field"
  else
    fail "detect_phase_type() does not read implementer field"
  fi

  # Check for routing map enhancement (phase_num:type:lean_file:implementer)
  if grep -q 'IMPLEMENTER_NAME' "$lean_implement_file"; then
    pass "Routing map includes implementer field"
  else
    fail "Routing map does not include implementer field"
  fi

  # Check for validation of implementer values
  if grep -q 'Invalid implementer value' "$lean_implement_file"; then
    pass "Routing validates implementer field values"
  else
    fail "Routing does not validate implementer field values"
  fi
}

# Test 4: Verify progress tracking integration
test_progress_tracking() {
  run_test "Test Case 4: Verify progress tracking integration"

  local lean_implement_file="$PROJECT_ROOT/commands/lean-implement.md"

  # Count progress tracking sections (should be 2: one for each coordinator)
  local progress_count=$(grep -c "Progress Tracking Instructions:" "$lean_implement_file" || echo "0")
  if [ "$progress_count" -ge 2 ]; then
    pass "Progress tracking instructions present in both coordinator prompts"
  else
    fail "Progress tracking instructions missing (found $progress_count, expected ≥2)"
  fi

  # Check for checkbox utilities sourcing
  if grep -q "checkbox-utils.sh" "$lean_implement_file"; then
    pass "Progress tracking includes checkbox utilities sourcing"
  else
    fail "Progress tracking missing checkbox utilities sourcing"
  fi

  # Check for graceful degradation note
  if grep -q "gracefully degrades" "$lean_implement_file"; then
    pass "Progress tracking includes graceful degradation note"
  else
    fail "Progress tracking missing graceful degradation note"
  fi
}

# Test 5: Verify error signal parsing
test_error_signal_parsing() {
  run_test "Test Case 5: Verify error signal parsing (TASK_ERROR)"

  local lean_implement_file="$PROJECT_ROOT/commands/lean-implement.md"

  # Check for TASK_ERROR detection
  if grep -q "TASK_ERROR:" "$lean_implement_file"; then
    pass "Block 1c parses TASK_ERROR signals"
  else
    fail "Block 1c does not parse TASK_ERROR signals"
  fi

  # Check for coordinator error variable
  if grep -q "COORDINATOR_ERROR" "$lean_implement_file"; then
    pass "Block 1c extracts coordinator error details"
  else
    fail "Block 1c does not extract coordinator error details"
  fi
}

# Main test execution
main() {
  echo "========================================"
  echo "lean-implement Hard Barrier Tests"
  echo "========================================"

  setup_test_env
  trap cleanup_test_env EXIT

  # Run all test cases
  test_block_1b_structure
  test_block_1c_verification
  test_routing_enhancement
  test_progress_tracking
  test_error_signal_parsing

  # Print summary
  echo ""
  echo "========================================"
  echo "Test Summary"
  echo "========================================"
  echo "Tests run: $TESTS_RUN"
  echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
  if [ "$TESTS_FAILED" -gt 0 ]; then
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    echo ""
    echo "Failed tests:"
    for test in "${FAILED_TESTS[@]}"; do
      echo -e "  ${RED}✗${NC} $test"
    done
    exit 1
  else
    echo ""
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
  fi
}

# Run tests
main "$@"
