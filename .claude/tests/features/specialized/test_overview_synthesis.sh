#!/bin/bash
# test_overview_synthesis.sh
# Unit tests for overview synthesis decision logic
#
# Tests the should_synthesize_overview() function from overview-synthesis.sh
# across all workflow scopes and report count scenarios

# Source the library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect project root using git or walk-up pattern
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  CLAUDE_PROJECT_DIR="$SCRIPT_DIR"
  while [ "$CLAUDE_PROJECT_DIR" != "/" ]; do
    if [ -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
      break
    fi
    CLAUDE_PROJECT_DIR="$(dirname "$CLAUDE_PROJECT_DIR")"
  done
fi
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
source "$LIB_DIR/artifact/overview-synthesis.sh"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

echo "=================================================="
echo "Testing Overview Synthesis Decision Logic"
echo "=================================================="
echo

# Test 1: research-only workflow with sufficient reports (should synthesize)
echo "Test: research-only with 2 reports"
set +e
should_synthesize_overview "research-only" 2
result=$?
set -e
if [ $result -eq 0 ]; then
  echo "✓ PASS"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "✗ FAIL (expected 0, got $result)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo "Test: research-only with 3 reports"
set +e
should_synthesize_overview "research-only" 3
result=$?
set -e
if [ $result -eq 0 ]; then
  echo "✓ PASS"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "✗ FAIL (expected 0, got $result)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 2: research-only workflow with insufficient reports (should NOT synthesize)
echo "Test: research-only with 1 report"
set +e
should_synthesize_overview "research-only" 1
result=$?
set -e
if [ $result -eq 1 ]; then
  echo "✓ PASS"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "✗ FAIL (expected 1, got $result)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 3: research-and-plan workflow (should NEVER synthesize)
echo "Test: research-and-plan with 2 reports"
set +e
should_synthesize_overview "research-and-plan" 2
result=$?
set -e
if [ $result -eq 1 ]; then
  echo "✓ PASS"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "✗ FAIL (expected 1, got $result)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo "Test: research-and-plan with 5 reports"
set +e
should_synthesize_overview "research-and-plan" 5
result=$?
set -e
if [ $result -eq 1 ]; then
  echo "✓ PASS"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "✗ FAIL (expected 1, got $result)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 4: full-implementation workflow (should NEVER synthesize)
echo "Test: full-implementation with 2 reports"
set +e
should_synthesize_overview "full-implementation" 2
result=$?
set -e
if [ $result -eq 1 ]; then
  echo "✓ PASS"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "✗ FAIL (expected 1, got $result)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 5: debug-only workflow (should NEVER synthesize)
echo "Test: debug-only with 2 reports"
set +e
should_synthesize_overview "debug-only" 2
result=$?
set -e
if [ $result -eq 1 ]; then
  echo "✓ PASS"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "✗ FAIL (expected 1, got $result)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 6: unknown workflow scope (should default to no synthesis)
echo "Test: unknown-workflow with 2 reports"
set +e
should_synthesize_overview "unknown-workflow" 2
result=$?
set -e
if [ $result -eq 1 ]; then
  echo "✓ PASS"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "✗ FAIL (expected 1, got $result)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo
echo "=================================================="
echo "Testing Path Calculation"
echo "=================================================="
echo

# Test path calculation
echo "Test: Standard path format"
set +e
actual_path=$(calculate_overview_path "/path/to/specs/042_auth/reports/001_auth_research" 2>&1)
result=$?
set -e
expected_path="/path/to/specs/042_auth/reports/001_auth_research/OVERVIEW.md"
if [ $result -eq 0 ] && [ "$actual_path" = "$expected_path" ]; then
  echo "✓ PASS"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "✗ FAIL (expected '$expected_path', got '$actual_path', exit code: $result)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo "Test: Relative path"
set +e
actual_path=$(calculate_overview_path "./specs/042_auth/reports/001_auth_research" 2>&1)
result=$?
set -e
expected_path="./specs/042_auth/reports/001_auth_research/OVERVIEW.md"
if [ $result -eq 0 ] && [ "$actual_path" = "$expected_path" ]; then
  echo "✓ PASS"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "✗ FAIL (expected '$expected_path', got '$actual_path', exit code: $result)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test empty path (should fail gracefully)
echo "Test: Empty path returns error"
set +e
calculate_overview_path "" 2>/dev/null
result=$?
set -e
if [ $result -ne 0 ]; then
  echo "✓ PASS"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "✗ FAIL (empty path should return non-zero exit code)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo
echo "=================================================="
echo "Testing Skip Reason Messages"
echo "=================================================="
echo

# Test skip reason messages
echo "Test: Insufficient reports message"
set +e
reason=$(get_synthesis_skip_reason "research-only" 1)
set -e
if [[ "$reason" == *"Insufficient reports"* ]]; then
  echo "✓ PASS"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "✗ FAIL (expected 'Insufficient reports', got '$reason')"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo "Test: Research-and-plan message"
set +e
reason=$(get_synthesis_skip_reason "research-and-plan" 3)
set -e
if [[ "$reason" == *"plan-architect"* ]]; then
  echo "✓ PASS"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "✗ FAIL (expected 'plan-architect', got '$reason')"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo "Test: Full-implementation message"
set +e
reason=$(get_synthesis_skip_reason "full-implementation" 3)
set -e
if [[ "$reason" == *"plan-architect"* ]]; then
  echo "✓ PASS"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "✗ FAIL (expected 'plan-architect', got '$reason')"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo "Test: Debug-only message"
set +e
reason=$(get_synthesis_skip_reason "debug-only" 3)
set -e
if [[ "$reason" == *"Debug workflow"* ]]; then
  echo "✓ PASS"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "✗ FAIL (expected 'Debug workflow', got '$reason')"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo "Test: Unknown scope message"
set +e
reason=$(get_synthesis_skip_reason "unknown-scope" 3)
set -e
if [[ "$reason" == *"Unknown workflow scope"* ]]; then
  echo "✓ PASS"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "✗ FAIL (expected 'Unknown workflow scope', got '$reason')"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo
echo "=================================================="
echo "Test Summary"
echo "=================================================="
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"
echo "=================================================="

if [ $TESTS_FAILED -eq 0 ]; then
  echo "✓ All tests passed!"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
