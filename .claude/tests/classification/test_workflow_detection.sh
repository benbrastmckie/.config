#!/usr/bin/env bash
# Test suite for workflow detection patterns
# Validates that detect_workflow_scope() correctly classifies all edge cases

set -euo pipefail

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
CLAUDE_LIB="${CLAUDE_PROJECT_DIR}/.claude/lib"
source "$CLAUDE_LIB/workflow/workflow-detection.sh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Assert function
assert_equals() {
  local expected="$1"
  local actual="$2"
  local description="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [ "$expected" = "$actual" ]; then
    echo "✓ PASS: $description"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "✗ FAIL: $description"
    echo "  Expected: $expected"
    echo "  Actual: $actual"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

echo "=========================================="
echo "Workflow Detection Test Suite"
echo "=========================================="
echo ""

# Test 1: Pure research (no plan or implement)
assert_equals "research-only" \
  "$(detect_workflow_scope "research API authentication patterns")" \
  "Pure research without planning"

# Test 2: Research to create a plan
assert_equals "research-and-plan" \
  "$(detect_workflow_scope "research authentication approaches to create a plan")" \
  "Research to create plan"

# Test 3: Research and implement (should be full-implementation)
assert_equals "full-implementation" \
  "$(detect_workflow_scope "research auth and implement OAuth2")" \
  "Research and implement"

# Test 4: Direct implementation request
assert_equals "full-implementation" \
  "$(detect_workflow_scope "implement OAuth2 authentication for the API")" \
  "Direct implementation"

# Test 5: Build feature
assert_equals "full-implementation" \
  "$(detect_workflow_scope "build a new user registration feature")" \
  "Build feature"

# Test 6: User's actual prompt (the bug case)
assert_equals "full-implementation" \
  "$(detect_workflow_scope "research my current configuration and then conduct research online for how to provide a elegant configuration given the plugins I am using. then create and implement a plan to fix this problem.")" \
  "User's actual prompt (implement a plan)"

# Test 7: Fix bug (debug-only)
assert_equals "debug-only" \
  "$(detect_workflow_scope "fix the token refresh bug in auth.js")" \
  "Fix existing bug"

# Test 8: Add feature with plan mention (should prioritize implementation)
assert_equals "full-implementation" \
  "$(detect_workflow_scope "research database options to plan and implement user profiles")" \
  "Plan and implement (implementation wins)"

# Test 9: Analyze for planning only
assert_equals "research-and-plan" \
  "$(detect_workflow_scope "analyze current architecture for planning refactor")" \
  "Analyze for planning"

# Test 10: Create code component
assert_equals "full-implementation" \
  "$(detect_workflow_scope "create a new authentication module")" \
  "Create code component"

echo ""
echo "=========================================="
echo "Multi-Intent Tests (Smart Matching)"
echo "=========================================="
echo ""

# Test 11: Multi-intent - Research + Plan + Implement (all 3 patterns match)
assert_equals "full-implementation" \
  "$(detect_workflow_scope "research authentication approaches to create a plan and implement OAuth2")" \
  "Multi-intent: research + plan + implement (phases 0,1,2,3,4,6)"

# Test 12: Multi-intent - Plan + Debug (should choose larger workflow)
assert_equals "research-and-plan" \
  "$(detect_workflow_scope "analyze architecture for planning and troubleshoot any issues")" \
  "Multi-intent: plan + debug keywords (plan wins, phases 0,1,2)"

echo ""
echo "=========================================="
echo "Test Results"
echo "=========================================="
echo "Tests run: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo "✓ All tests passed"
  exit 0
else
  echo "✗ $TESTS_FAILED test(s) failed"
  exit 1
fi
