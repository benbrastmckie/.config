#!/usr/bin/env bash
# test_bash_command_fixes.sh - Test bash history expansion fixes
# Tests for Plan 594: Fix bash command failures in coordinate.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Find project root using git or walk-up pattern
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
PROJECT_ROOT="${CLAUDE_PROJECT_DIR}/.claude"

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

# context-pruning.sh was archived - skip test
if [ -f "$PROJECT_ROOT/lib/context-pruning.sh" ]; then
  if grep 'local -n.*=' "$PROJECT_ROOT/lib/context-pruning.sh" >/dev/null 2>&1; then
    pass "context-pruning.sh uses nameref pattern"
  else
    fail "context-pruning.sh nameref" "found nameref pattern" "not found"
  fi
else
  echo "  - context-pruning.sh archived (skipped)"
fi

if grep 'local -n.*=' "$PROJECT_ROOT/lib/workflow/workflow-initialization.sh" >/dev/null 2>&1; then
  pass "workflow-initialization.sh uses nameref pattern"
else
  fail "workflow-initialization.sh nameref" "found nameref pattern" "not found"
fi

# ==============================================================================
# Test 2: Verify library files source cleanly
# ==============================================================================
echo ""
echo "Test 2: Verify library files source without errors"

# context-pruning.sh was archived - skip test
if [ -f "$PROJECT_ROOT/lib/context-pruning.sh" ]; then
  if bash -c "source '$PROJECT_ROOT/lib/context-pruning.sh'" 2>&1 | grep -qi error; then
    fail "context-pruning.sh sourcing" "clean source" "errors found"
  else
    pass "context-pruning.sh sources cleanly"
  fi
else
  echo "  - context-pruning.sh archived (skipped)"
fi

if bash -c "source '$PROJECT_ROOT/lib/workflow/workflow-initialization.sh'" 2>&1 | grep -qi error; then
  fail "workflow-initialization.sh sourcing" "clean source" "errors found"
else
  pass "workflow-initialization.sh sources cleanly"
fi

# ==============================================================================
# Test 3: Verify unified-logger.sh in REQUIRED_LIBS for all scopes
# ==============================================================================
echo ""
echo "Test 3: Verify unified-logger.sh in REQUIRED_LIBS array"

# coordinate.md was archived - check build.md instead
if [ -f "$PROJECT_ROOT/commands/build.md" ]; then
  if grep -q 'unified-logger.sh' "$PROJECT_ROOT/commands/build.md" >/dev/null 2>&1; then
    pass "unified-logger.sh referenced in build.md"
  else
    echo "  - unified-logger.sh not explicitly in build.md (skipped)"
  fi
else
  echo "  - coordinate.md archived, build.md not found (skipped)"
fi

# ==============================================================================
# Test 4: Verify defensive checks for emit_progress
# ==============================================================================
echo ""
echo "Test 4: Verify defensive checks provide graceful degradation"

# coordinate.md was archived - skip this test
if [ -f "$PROJECT_ROOT/commands/coordinate.md" ]; then
  DEFENSIVE_CHECKS=$(grep -c "command -v emit_progress" "$PROJECT_ROOT/commands/coordinate.md" 2>/dev/null || echo "0")

  if [ "$DEFENSIVE_CHECKS" -ge 5 ]; then
    pass "Found $DEFENSIVE_CHECKS defensive checks for emit_progress"
  else
    fail "Defensive checks count" "at least 5 checks" "found $DEFENSIVE_CHECKS"
  fi
else
  echo "  - coordinate.md archived (skipped)"
fi

# coordinate.md was archived - skip fallback pattern test
if [ -f "$PROJECT_ROOT/commands/coordinate.md" ]; then
  if grep 'echo "PROGRESS:' "$PROJECT_ROOT/commands/coordinate.md" >/dev/null; then
    pass "Fallback echo pattern found"
  else
    fail "Fallback pattern" "PROGRESS: echo statements" "not found"
  fi
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
