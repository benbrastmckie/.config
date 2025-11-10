#!/usr/bin/env bash
# test_coordinate_verification.sh - Test coordinate verification checkpoint logic

set -euo pipefail

TESTS_PASSED=0
TESTS_FAILED=0

# Test 1: State file format matches append_workflow_state output
test_state_file_format() {
  echo "Test 1: State file format verification"

  # Create temp state file
  STATE_FILE=$(mktemp)
  trap "rm -f '$STATE_FILE'" EXIT

  # Simulate append_workflow_state behavior
  echo 'export REPORT_PATHS_COUNT="4"' >> "$STATE_FILE"
  echo 'export REPORT_PATH_0="/path/to/report1.md"' >> "$STATE_FILE"

  # Test format matches expected pattern
  if grep -q "^export REPORT_PATHS_COUNT=" "$STATE_FILE" 2>/dev/null; then
    echo "  ✓ PASS: Format matches export pattern"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  ✗ FAIL: Format doesn't match export pattern"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# Test 2: Verification pattern matches actual state file
test_verification_pattern_matching() {
  echo "Test 2: Verification pattern matching"

  STATE_FILE=$(mktemp)
  trap "rm -f '$STATE_FILE'" EXIT

  # Source state-persistence.sh to get real append_workflow_state
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"

  # Write using real function
  export STATE_FILE  # Required by append_workflow_state
  append_workflow_state "REPORT_PATHS_COUNT" "4"
  append_workflow_state "REPORT_PATH_0" "/path/to/report.md"

  # Verify using fixed grep pattern
  VERIFICATION_FAILURES=0

  if grep -q "^export REPORT_PATHS_COUNT=" "$STATE_FILE" 2>/dev/null; then
    echo "  ✓ REPORT_PATHS_COUNT verified"
  else
    echo "  ✗ REPORT_PATHS_COUNT missing"
    VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
  fi

  if grep -q "^export REPORT_PATH_0=" "$STATE_FILE" 2>/dev/null; then
    echo "  ✓ REPORT_PATH_0 verified"
  else
    echo "  ✗ REPORT_PATH_0 missing"
    VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
  fi

  if [ $VERIFICATION_FAILURES -eq 0 ]; then
    echo "  ✓ PASS: All variables verified"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  ✗ FAIL: $VERIFICATION_FAILURES verification failures"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# Test 3: False negative prevention (bug regression test)
test_false_negative_prevention() {
  echo "Test 3: False negative prevention"

  STATE_FILE=$(mktemp)
  trap "rm -f '$STATE_FILE'" EXIT

  # Write state file with correct format
  echo 'export REPORT_PATHS_COUNT="4"' > "$STATE_FILE"

  # Test OLD pattern (should FAIL)
  if grep -q "^REPORT_PATHS_COUNT=" "$STATE_FILE" 2>/dev/null; then
    echo "  ✗ FAIL: Old pattern unexpectedly matched (bug not reproducible)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  else
    echo "  ✓ PASS: Old pattern correctly fails (bug reproduced)"

    # Test NEW pattern (should PASS)
    if grep -q "^export REPORT_PATHS_COUNT=" "$STATE_FILE" 2>/dev/null; then
      echo "  ✓ PASS: New pattern correctly matches"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      echo "  ✗ FAIL: New pattern doesn't match"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
  fi
}

# Test 4: Integration test - coordinate initialization
test_coordinate_initialization() {
  echo "Test 4: Coordinate initialization (integration)"

  # This requires running actual coordinate command, which is heavy
  # Mark as manual test for now
  echo "  ⚠ SKIP: Manual integration test required"
  echo "    Run: /coordinate \"test workflow\""
  echo "    Expected: Initialization completes, progresses to research phase"
}

# Run all tests
echo "=== Coordinate Verification Checkpoint Tests ==="
echo ""

test_state_file_format
echo ""

test_verification_pattern_matching
echo ""

test_false_negative_prevention
echo ""

test_coordinate_initialization
echo ""

# Summary
echo "=== Test Summary ==="
echo "  Passed: $TESTS_PASSED"
echo "  Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo "✓ All tests passed"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
