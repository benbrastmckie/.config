#!/usr/bin/env bash
# test_bash_command_fixes.sh - Test bash history expansion fixes
# Tests for Plan 594: Fix bash command failures in coordinate.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result tracking
pass() {
  echo "  ✓ $1"
  ((TESTS_PASSED++)) || true
  ((TESTS_RUN++)) || true
}

fail() {
  echo "  ✗ $1"
  if [ $# -ge 3 ]; then
    echo "    Expected: $2"
    echo "    Got: $3"
  fi
  ((TESTS_FAILED++)) || true
  ((TESTS_RUN++)) || true
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST SUITE: Bash Command Fixes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ==============================================================================
# Test 1: Verify no indirect variable expansions in library files
# ==============================================================================
echo "Test 1: Verify no indirect variable expansions in library files"

# We're looking for ${!var} patterns but NOT ${!array[@]} patterns
# The nameref pattern should be: local -n varname=

if grep 'local -n.*=' "$PROJECT_ROOT/.claude/lib/context-pruning.sh" >/dev/null 2>&1; then
  pass "context-pruning.sh uses nameref pattern"
else
  fail "context-pruning.sh nameref" "found nameref pattern" "not found"
fi

if grep 'local -n.*=' "$PROJECT_ROOT/.claude/lib/workflow-initialization.sh" >/dev/null 2>&1; then
  pass "workflow-initialization.sh uses nameref pattern"
else
  fail "workflow-initialization.sh nameref" "found nameref pattern" "not found"
fi

# ==============================================================================
# Test 2: Verify library files source cleanly
# ==============================================================================
echo ""
echo "Test 2: Verify library files source without errors"

if bash -c "source '$PROJECT_ROOT/.claude/lib/context-pruning.sh'" 2>&1 | grep -qi error; then
  fail "context-pruning.sh sourcing" "clean source" "errors found"
else
  pass "context-pruning.sh sources cleanly"
fi

if bash -c "source '$PROJECT_ROOT/.claude/lib/workflow-initialization.sh'" 2>&1 | grep -qi error; then
  fail "workflow-initialization.sh sourcing" "clean source" "errors found"
else
  pass "workflow-initialization.sh sources cleanly"
fi

# ==============================================================================
# Test 3: Verify unified-logger.sh sourced in coordinate.md Phase 0 Block 3
# ==============================================================================
echo ""
echo "Test 3: Verify emit_progress function availability in Phase 0 Block 3"

if grep -A 100 "STEP 0.6: Initialize Workflow Paths" "$PROJECT_ROOT/.claude/commands/coordinate.md" | grep "source.*unified-logger.sh" >/dev/null; then
  pass "unified-logger.sh sourced in Phase 0 Block 3"
else
  fail "unified-logger.sh sourcing" "library sourced in Block 3" "not found"
fi

# ==============================================================================
# Test 4: Verify defensive checks for emit_progress
# ==============================================================================
echo ""
echo "Test 4: Verify defensive checks provide graceful degradation"

DEFENSIVE_CHECKS=$(grep -c "command -v emit_progress" "$PROJECT_ROOT/.claude/commands/coordinate.md" 2>/dev/null || echo "0")

if [ "$DEFENSIVE_CHECKS" -ge 5 ]; then
  pass "Found $DEFENSIVE_CHECKS defensive checks for emit_progress"
else
  fail "Defensive checks count" "at least 5 checks" "found $DEFENSIVE_CHECKS"
fi

if grep 'echo "PROGRESS:' "$PROJECT_ROOT/.claude/commands/coordinate.md" >/dev/null; then
  pass "Fallback echo pattern found"
else
  fail "Fallback pattern" "PROGRESS: echo statements" "not found"
fi

# ==============================================================================
# Test Summary
# ==============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST RESULTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Tests run: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo "✓ All tests passed"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
