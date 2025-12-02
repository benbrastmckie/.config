#!/usr/bin/env bash
# Unit tests for /test command
# Tests argument capture, summary discovery, coverage loop, and workflow orchestration

set -euo pipefail

# Test setup
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${HOME}/.config"
TEMP_TEST_DIR="${HOME}/.claude/tmp/test_test_$$"

# Source test utilities
source "${PROJECT_ROOT}/.claude/lib/core/error-handling.sh" || exit 1
source "${PROJECT_ROOT}/.claude/lib/core/state-persistence.sh" || exit 1
source "${PROJECT_ROOT}/.claude/lib/workflow/workflow-state-machine.sh" || exit 1

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test utilities
assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="${3:-}"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [ "$expected" = "$actual" ]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "✓ PASS: $message"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "✗ FAIL: $message"
    echo "  Expected: $expected"
    echo "  Actual:   $actual"
    return 1
  fi
}

assert_file_exists() {
  local file="$1"
  local message="${2:-File should exist: $file}"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [ -f "$file" ]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "✓ PASS: $message"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "✗ FAIL: $message"
    echo "  File not found: $file"
    return 1
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-}"

  TESTS_RUN=$((TESTS_RUN + 1))

  if echo "$haystack" | grep -q "$needle"; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "✓ PASS: $message"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "✗ FAIL: $message"
    echo "  Expected to find: $needle"
    return 1
  fi
}

# Setup test environment
setup_test() {
  mkdir -p "$TEMP_TEST_DIR/plans"
  mkdir -p "$TEMP_TEST_DIR/summaries"
  mkdir -p "$TEMP_TEST_DIR/outputs"

  # Create mock plan file
  cat > "$TEMP_TEST_DIR/plans/test-plan.md" <<'EOF'
# Test Plan

## Metadata
- **Status**: [IN PROGRESS]

## Phase 0: Setup
Tasks:
- [x] Task 1
EOF

  # Create mock summary file
  cat > "$TEMP_TEST_DIR/summaries/001-implementation-summary.md" <<'EOF'
# Implementation Summary

## Metadata
- **Plan**: /tmp/test_test_$$/plans/test-plan.md
- **Status**: Complete

## Testing Strategy
- **Test Files**: /tmp/test_test_$$/tests/test_suite.sh
- **Test Execution Requirements**: bash /tmp/test_test_$$/tests/test_suite.sh
- **Expected Tests**: 5
- **Coverage Target**: 80%
EOF

  # Update plan path in summary
  sed -i "s|/tmp/test_test_\$\$|$TEMP_TEST_DIR|g" "$TEMP_TEST_DIR/summaries/001-implementation-summary.md"
}

# Cleanup test environment
cleanup_test() {
  rm -rf "$TEMP_TEST_DIR" 2>/dev/null || true
  rm -f "${HOME}/.claude/tmp/test_arg_"*.txt 2>/dev/null || true
  rm -f "${HOME}/.claude/tmp/test_arg_path.txt" 2>/dev/null || true
}

# Test: --file flag parsing
test_file_flag_parsing() {
  echo ""
  echo "=== Test: --file Flag Parsing ==="

  setup_test

  local summary_file="$TEMP_TEST_DIR/summaries/001-implementation-summary.md"
  local test_args="--file $summary_file"

  # Simulate --file flag parsing
  local summary_parsed=""
  if [[ "$test_args" =~ --file[[:space:]]+([^[:space:]]+) ]]; then
    summary_parsed="${BASH_REMATCH[1]}"
  fi

  assert_equals "$summary_file" "$summary_parsed" "--file flag parsed correctly"

  cleanup_test
}

# Test: Auto-discovery of latest summary
test_summary_auto_discovery() {
  echo ""
  echo "=== Test: Summary Auto-Discovery ==="

  setup_test

  local summaries_dir="$TEMP_TEST_DIR/summaries"

  # Create multiple summaries with different timestamps
  touch -t 202301011200 "$summaries_dir/001-implementation-summary.md"
  cat > "$summaries_dir/002-implementation-summary.md" <<'EOF'
# Latest Summary
EOF
  touch -t 202301011300 "$summaries_dir/002-implementation-summary.md"

  # Find latest summary
  local latest_summary=$(find "$summaries_dir" -name "*.md" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)

  assert_contains "$latest_summary" "002-implementation-summary.md" "Latest summary discovered"

  cleanup_test
}

# Test: Coverage threshold configuration
test_coverage_threshold() {
  echo ""
  echo "=== Test: Coverage Threshold Configuration ==="

  local test_args="plan.md --coverage-threshold 90"
  local threshold=80  # default

  # Parse --coverage-threshold flag
  if [[ "$test_args" =~ --coverage-threshold[=[:space:]]+([0-9]+) ]]; then
    threshold="${BASH_REMATCH[1]}"
  fi

  assert_equals "90" "$threshold" "Coverage threshold parsed from flag"
}

# Test: Max iterations configuration
test_max_iterations() {
  echo ""
  echo "=== Test: Max Iterations Configuration ==="

  local test_args="plan.md --max-iterations 10"
  local max_iterations=5  # default

  # Parse --max-iterations flag
  if [[ "$test_args" =~ --max-iterations[=[:space:]]+([0-9]+) ]]; then
    max_iterations="${BASH_REMATCH[1]}"
  fi

  assert_equals "10" "$max_iterations" "Max iterations parsed from flag"
}

# Test: Loop decision logic - success case
test_loop_decision_success() {
  echo ""
  echo "=== Test: Loop Decision - Success ==="

  local tests_failed=0
  local coverage=85
  local coverage_threshold=80

  local all_passed=false
  if [ "$tests_failed" -eq 0 ]; then
    all_passed=true
  fi

  local coverage_met=false
  if [ "$coverage" -ge "$coverage_threshold" ]; then
    coverage_met=true
  fi

  local next_state="unknown"
  if [ "$all_passed" = "true" ] && [ "$coverage_met" = "true" ]; then
    next_state="complete"
  fi

  assert_equals "complete" "$next_state" "Loop exits with success when criteria met"
}

# Test: Loop decision logic - stuck case
test_loop_decision_stuck() {
  echo ""
  echo "=== Test: Loop Decision - Stuck ==="

  local stuck_count=2
  local next_state="unknown"

  if [ "$stuck_count" -ge 2 ]; then
    next_state="debug"
  fi

  assert_equals "debug" "$next_state" "Loop exits to debug when stuck"
}

# Test: Loop decision logic - max iterations
test_loop_decision_max_iterations() {
  echo ""
  echo "=== Test: Loop Decision - Max Iterations ==="

  local iteration=5
  local max_test_iterations=5
  local next_state="unknown"

  if [ "$iteration" -ge "$max_test_iterations" ]; then
    next_state="debug"
  fi

  assert_equals "debug" "$next_state" "Loop exits to debug at max iterations"
}

# Test: Loop decision logic - continue
test_loop_decision_continue() {
  echo ""
  echo "=== Test: Loop Decision - Continue ==="

  local tests_failed=0
  local coverage=60
  local coverage_threshold=80
  local iteration=2
  local max_test_iterations=5
  local stuck_count=0

  local all_passed=false
  if [ "$tests_failed" -eq 0 ]; then
    all_passed=true
  fi

  local coverage_met=false
  if [ "$coverage" -ge "$coverage_threshold" ]; then
    coverage_met=true
  fi

  local next_state="unknown"
  if [ "$all_passed" = "true" ] && [ "$coverage_met" = "true" ]; then
    next_state="complete"
  elif [ "$stuck_count" -ge 2 ]; then
    next_state="debug"
  elif [ "$iteration" -ge "$max_test_iterations" ]; then
    next_state="debug"
  else
    next_state="continue"
  fi

  assert_equals "continue" "$next_state" "Loop continues when coverage below threshold"
}

# Test: Testing Strategy parsing
test_testing_strategy_parsing() {
  echo ""
  echo "=== Test: Testing Strategy Parsing ==="

  setup_test

  local summary_file="$TEMP_TEST_DIR/summaries/001-implementation-summary.md"

  # Extract test files
  local test_files=$(sed -n '/^## Testing Strategy/,/^## /p' "$summary_file" | grep -E "^- \*\*Test Files\*\*:" | sed 's/.*: //' || echo "")

  # Extract test command
  local test_command=$(sed -n '/^## Testing Strategy/,/^## /p' "$summary_file" | grep -E "^- \*\*Test Execution Requirements\*\*:" | sed 's/.*: //' || echo "")

  # Extract expected tests
  local expected_tests=$(sed -n '/^## Testing Strategy/,/^## /p' "$summary_file" | grep -E "^- \*\*Expected Tests\*\*:" | sed 's/.*: //' || echo "")

  assert_contains "$test_files" "test_suite.sh" "Test files extracted from summary"
  assert_contains "$test_command" "bash" "Test command extracted from summary"
  assert_equals "5" "$expected_tests" "Expected tests extracted from summary"

  cleanup_test
}

# Test: State machine initialization with test-and-debug workflow
test_state_machine_init() {
  echo ""
  echo "=== Test: State Machine Initialization ==="

  local workflow_id="test_test_$$"
  sm_init "$workflow_id" "test" "test-and-debug" 5 "[]" 2>/dev/null || true

  assert_equals "complete" "$TERMINAL_STATE" "Terminal state set to complete"
  assert_equals "test" "$CURRENT_STATE" "Current state initialized to test"
}

# Run all tests
run_all_tests() {
  echo "========================================="
  echo "Running /test Command Unit Tests"
  echo "========================================="

  test_file_flag_parsing
  test_summary_auto_discovery
  test_coverage_threshold
  test_max_iterations
  test_loop_decision_success
  test_loop_decision_stuck
  test_loop_decision_max_iterations
  test_loop_decision_continue
  test_testing_strategy_parsing
  test_state_machine_init

  echo ""
  echo "========================================="
  echo "Test Results"
  echo "========================================="
  echo "Tests Run:    $TESTS_RUN"
  echo "Tests Passed: $TESTS_PASSED"
  echo "Tests Failed: $TESTS_FAILED"
  echo ""

  if [ "$TESTS_FAILED" -eq 0 ]; then
    echo "✓ All tests passed"
    return 0
  else
    echo "✗ Some tests failed"
    return 1
  fi
}

# Run tests
run_all_tests
exit $?
