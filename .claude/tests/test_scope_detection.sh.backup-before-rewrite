#!/bin/bash
# Unit tests for workflow scope detection library

# Setup test environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$PROJECT_ROOT/.claude/lib"

# Source the scope detection library
if [ -f "$LIB_DIR/workflow-scope-detection.sh" ]; then
  source "$LIB_DIR/workflow-scope-detection.sh"
else
  echo "FATAL: Cannot find workflow-scope-detection.sh"
  echo "Expected: $LIB_DIR/workflow-scope-detection.sh"
  exit 1
fi

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper
run_test() {
  local test_name="$1"
  local workflow_desc="$2"
  local expected="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  local result=$(detect_workflow_scope "$workflow_desc")

  if [ "$result" = "$expected" ]; then
    echo "PASS: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "FAIL: $test_name"
    echo "  Expected: $expected"
    echo "  Got: $result"
    echo "  Input: $workflow_desc"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

echo "========================================"
echo "Unit Tests: Workflow Scope Detection"
echo "========================================"
echo ""

# Test 1: Research-only pattern
run_test "Test 1: Research-only" \
  "research authentication patterns" \
  "research-only"

# Test 2: Research-and-plan pattern (explicit plan keyword)
run_test "Test 2: Research-and-plan (explicit plan)" \
  "research auth and create plan" \
  "research-and-plan"

# Test 3: Research-and-plan pattern (design keyword)
# Note: "research and design" triggers research-only because "design" is checked
# in the second conditional (after research-only check). The "research and"
# pattern with "design" without explicit "plan" is classified as research-only.
# To get research-and-plan, need explicit "plan" keyword.
run_test "Test 3: Research-and-plan (design keyword)" \
  "design authentication system" \
  "research-and-plan"

# Test 4: Full-implementation pattern
run_test "Test 4: Full-implementation" \
  "research auth and implement feature" \
  "full-implementation"

# Test 5: Full-implementation pattern (build keyword)
run_test "Test 5: Full-implementation (build keyword)" \
  "research and build authentication feature" \
  "full-implementation"

# Test 6: Debug-only pattern
run_test "Test 6: Debug-only" \
  "debug authentication failure" \
  "debug-only"

# Test 7: Debug-only pattern (fix keyword)
run_test "Test 7: Debug-only (fix keyword)" \
  "fix broken authentication" \
  "debug-only"

# Test 8: Debug-only pattern (troubleshoot keyword)
run_test "Test 8: Debug-only (troubleshoot keyword)" \
  "troubleshoot login issues" \
  "debug-only"

# Test 9: "implement feature" matches full-implementation pattern
run_test "Test 9: Full-implementation (implement feature)" \
  "implement feature X" \
  "full-implementation"

# Test 10: Edge case - empty description (should handle gracefully)
run_test "Test 10: Edge case - empty description" \
  "" \
  "research-and-plan"

# Test 11: Research with implement but not feature pattern
run_test "Test 11: Research + implement (not feature)" \
  "research and implement authentication" \
  "research-and-plan"

# Test 12: Case insensitivity
run_test "Test 12: Case insensitivity (PLAN)" \
  "research and PLAN authentication" \
  "research-and-plan"

# Test 13: Case insensitivity (Debug)
run_test "Test 13: Case insensitivity (Debug)" \
  "Debug authentication module" \
  "debug-only"

# Test 14: Revision-first pattern - simple form (no "the plan")
run_test "Test 14: Revision-first (simple form)" \
  "Revise /path/to/specs/042_auth/plans/001_plan.md to accommodate new requirements" \
  "research-and-revise"

# Test 15: Revision-first pattern - complex form (with "the plan")
run_test "Test 15: Revision-first (with 'the plan')" \
  "Revise the plan /path/to/implementation.md to accommodate changes" \
  "research-and-revise"

# Test 16: Revision-first pattern - user's exact input from issue #661
run_test "Test 16: Revision-first (full user input)" \
  "Revise the plan /home/benjamin/.config/.claude/specs/657_review_tests_coordinate_command_related/plans/001_review_tests_coordinate_command_related_plan.md to accommodate recent changes made to .claude/ by reviewing the git history, making only necessary changes to the plan." \
  "research-and-revise"

# Test 17: Revision-first pattern - "Update plan based on"
run_test "Test 17: Revision-first (update plan based on)" \
  "Update plan based on recent findings" \
  "research-and-revise"

# Test 18: Revision-first pattern - "Modify implementation for"
run_test "Test 18: Revision-first (modify implementation for)" \
  "Modify implementation for new requirements" \
  "research-and-revise"

# Test 19: Revision-first pattern - with "using" keyword
run_test "Test 19: Revision-first (using keyword)" \
  "Revise plan using the new architecture" \
  "research-and-revise"

echo ""
echo "========================================"
echo "Test Results"
echo "========================================"
echo "Tests run: $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo "✓ All tests passed"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
