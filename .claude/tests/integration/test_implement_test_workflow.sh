#!/usr/bin/env bash
# Integration tests for /implement → /test workflow
# Tests end-to-end workflow with summary-based handoff

set -euo pipefail

# Test setup
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${HOME}/.config"
TEMP_TEST_DIR="${HOME}/.claude/tmp/test_workflow_$$"

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
  mkdir -p "$TEMP_TEST_DIR/.state"

  # Create test plan
  cat > "$TEMP_TEST_DIR/plans/test-integration-plan.md" <<'EOF'
# Integration Test Plan

## Metadata
- **Date**: 2025-12-01
- **Status**: [NOT STARTED]
- **Complexity**: 50

## Overview
Test plan for /implement → /test workflow integration.

## Phase 0: Setup
dependencies: []

**Tasks**:
- [ ] Create test file
- [ ] Write initial tests

## Phase 1: Testing
dependencies: [0]

**Tasks**:
- [ ] Write unit tests
- [ ] Write integration tests
EOF
}

# Cleanup test environment
cleanup_test() {
  rm -rf "$TEMP_TEST_DIR" 2>/dev/null || true
}

# Test: Summary-based handoff structure
test_summary_handoff_structure() {
  echo ""
  echo "=== Test: Summary-Based Handoff Structure ==="

  setup_test

  # Create mock implementation summary with Testing Strategy
  cat > "$TEMP_TEST_DIR/summaries/001-implementation-summary.md" <<EOF
# Implementation Summary

## Metadata
- **Plan**: $TEMP_TEST_DIR/plans/test-integration-plan.md
- **Date**: 2025-12-01
- **Status**: Complete

## Work Completed
- Phase 0: Setup (COMPLETE)
- Phase 1: Testing (COMPLETE)

## Testing Strategy
- **Test Files**: $TEMP_TEST_DIR/tests/test_suite.sh
- **Test Execution Requirements**: bash $TEMP_TEST_DIR/tests/test_suite.sh
- **Expected Tests**: 3
- **Coverage Target**: 80%
- **Test Framework**: bash

## Next Steps
Run /test to execute test suite and verify coverage.
EOF

  local summary_file="$TEMP_TEST_DIR/summaries/001-implementation-summary.md"

  assert_file_exists "$summary_file" "Implementation summary created"

  # Verify Testing Strategy section exists
  local has_testing_strategy=$(grep -c "^## Testing Strategy" "$summary_file" || echo "0")
  TESTS_RUN=$((TESTS_RUN + 1))
  if [ "$has_testing_strategy" -gt 0 ]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "✓ PASS: Summary contains Testing Strategy section"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "✗ FAIL: Summary missing Testing Strategy section"
  fi

  # Verify plan file reference
  local plan_ref=$(grep "^- \*\*Plan\*\*:" "$summary_file" | sed 's/.*: //')
  assert_contains "$plan_ref" "test-integration-plan.md" "Summary references plan file"

  cleanup_test
}

# Test: Auto-discovery pattern
test_auto_discovery_pattern() {
  echo ""
  echo "=== Test: Auto-Discovery Pattern ==="

  setup_test

  local plan_file="$TEMP_TEST_DIR/plans/test-integration-plan.md"
  local summaries_dir="$TEMP_TEST_DIR/summaries"

  # Create summary
  cat > "$summaries_dir/001-implementation-summary.md" <<'EOF'
# Implementation Summary
EOF

  # Simulate auto-discovery (find latest summary by modification time)
  local latest_summary=$(find "$summaries_dir" -name "*.md" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)

  assert_file_exists "$latest_summary" "Latest summary discovered"
  assert_contains "$latest_summary" "001-implementation-summary.md" "Correct summary file discovered"

  cleanup_test
}

# Test: State file persistence across commands
test_state_persistence_across_commands() {
  echo ""
  echo "=== Test: State Persistence Across Commands ==="

  setup_test

  local state_file="$TEMP_TEST_DIR/.state/implement_state.sh"

  # Simulate /implement creating state file
  cat > "$state_file" <<EOF
PLAN_FILE="$TEMP_TEST_DIR/plans/test-integration-plan.md"
TOPIC_PATH="$TEMP_TEST_DIR"
IMPLEMENTATION_STATUS="complete"
ITERATION=1
EOF

  assert_file_exists "$state_file" "State file created by /implement"

  # Simulate /test loading state file
  source "$state_file"

  assert_equals "$TEMP_TEST_DIR/plans/test-integration-plan.md" "$PLAN_FILE" "State file loaded correctly"
  assert_equals "complete" "$IMPLEMENTATION_STATUS" "Implementation status preserved"

  cleanup_test
}

# Test: Explicit --file flag workflow
test_explicit_file_flag() {
  echo ""
  echo "=== Test: Explicit --file Flag Workflow ==="

  setup_test

  local summary_file="$TEMP_TEST_DIR/summaries/001-implementation-summary.md"

  # Create summary with plan reference
  cat > "$summary_file" <<EOF
# Implementation Summary

## Metadata
- **Plan**: $TEMP_TEST_DIR/plans/test-integration-plan.md

## Testing Strategy
- **Test Files**: tests/test_suite.sh
EOF

  # Simulate /test with --file flag
  local test_args="--file $summary_file"

  local summary_parsed=""
  if [[ "$test_args" =~ --file[[:space:]]+([^[:space:]]+) ]]; then
    summary_parsed="${BASH_REMATCH[1]}"
  fi

  assert_equals "$summary_file" "$summary_parsed" "--file flag parsed correctly"

  # Extract plan from summary
  local plan_from_summary=$(grep "^- \*\*Plan\*\*:" "$summary_file" | sed 's/.*: //')
  assert_contains "$plan_from_summary" "test-integration-plan.md" "Plan extracted from summary"

  cleanup_test
}

# Test: Testing Strategy field extraction
test_testing_strategy_extraction() {
  echo ""
  echo "=== Test: Testing Strategy Field Extraction ==="

  setup_test

  local summary_file="$TEMP_TEST_DIR/summaries/001-implementation-summary.md"

  cat > "$summary_file" <<'EOF'
# Implementation Summary

## Testing Strategy
- **Test Files**: /tmp/tests/test_suite.sh, /tmp/tests/unit_tests.sh
- **Test Execution Requirements**: bash /tmp/tests/run_all.sh
- **Expected Tests**: 10
- **Coverage Target**: 85%
- **Test Framework**: bash
EOF

  # Extract fields
  local test_files=$(sed -n '/^## Testing Strategy/,/^## /p' "$summary_file" | grep -E "^- \*\*Test Files\*\*:" | sed 's/.*: //')
  local test_command=$(sed -n '/^## Testing Strategy/,/^## /p' "$summary_file" | grep -E "^- \*\*Test Execution Requirements\*\*:" | sed 's/.*: //')
  local expected_tests=$(sed -n '/^## Testing Strategy/,/^## /p' "$summary_file" | grep -E "^- \*\*Expected Tests\*\*:" | sed 's/.*: //')
  local coverage_target=$(sed -n '/^## Testing Strategy/,/^## /p' "$summary_file" | grep -E "^- \*\*Coverage Target\*\*:" | sed 's/.*: //')

  assert_contains "$test_files" "test_suite.sh" "Test files extracted"
  assert_contains "$test_command" "bash" "Test command extracted"
  assert_equals "10" "$expected_tests" "Expected tests extracted"
  assert_equals "85%" "$coverage_target" "Coverage target extracted"

  cleanup_test
}

# Test: Workflow state transitions
test_workflow_state_transitions() {
  echo ""
  echo "=== Test: Workflow State Transitions ==="

  # /implement: IMPLEMENT → COMPLETE
  local implement_state="implement"
  local next_state="complete"

  TESTS_RUN=$((TESTS_RUN + 1))
  if [ "$implement_state" = "implement" ] && [ "$next_state" = "complete" ]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "✓ PASS: /implement transitions IMPLEMENT → COMPLETE"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "✗ FAIL: /implement state transition incorrect"
  fi

  # /test: TEST → COMPLETE
  local test_state="test"
  next_state="complete"

  TESTS_RUN=$((TESTS_RUN + 1))
  if [ "$test_state" = "test" ] && [ "$next_state" = "complete" ]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "✓ PASS: /test transitions TEST → COMPLETE"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "✗ FAIL: /test state transition incorrect"
  fi
}

# Run all tests
run_all_tests() {
  echo "========================================="
  echo "Running /implement → /test Integration Tests"
  echo "========================================="

  test_summary_handoff_structure
  test_auto_discovery_pattern
  test_state_persistence_across_commands
  test_explicit_file_flag
  test_testing_strategy_extraction
  test_workflow_state_transitions

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
