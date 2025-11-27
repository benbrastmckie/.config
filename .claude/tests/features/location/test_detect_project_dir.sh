#!/usr/bin/env bash
# Test suite for detect-project-dir.sh utility
# Tests all detection scenarios: git repo, worktree, fallback, manual override

set -euo pipefail

# Test framework setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect project root using git for this test file
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  TEST_CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  TEST_CLAUDE_PROJECT_DIR="$SCRIPT_DIR"
  while [ "$TEST_CLAUDE_PROJECT_DIR" != "/" ]; do
    if [ -d "$TEST_CLAUDE_PROJECT_DIR/.claude" ]; then
      break
    fi
    TEST_CLAUDE_PROJECT_DIR="$(dirname "$TEST_CLAUDE_PROJECT_DIR")"
  done
fi
CLAUDE_LIB="${TEST_CLAUDE_PROJECT_DIR}/.claude/lib"

TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test helper functions
pass() {
  echo -e "${GREEN}✓${NC} $1"
  ((TESTS_PASSED++)) || true
}

fail() {
  echo -e "${RED}✗${NC} $1"
  ((TESTS_FAILED++)) || true
}

info() {
  echo -e "${YELLOW}ℹ${NC} $1"
}

# Clean environment before each test
reset_env() {
  unset CLAUDE_PROJECT_DIR
}

echo "========================================"
echo "Test Suite: detect-project-dir.sh"
echo "========================================"
echo ""

# Test 1: Detection in main git repository
echo "Test 1: Detection in main git repository"
reset_env
cd "$SCRIPT_DIR/.."  # Go to .claude directory (inside git repo)
source "$CLAUDE_LIB/core/detect-project-dir.sh"

EXPECTED_ROOT="$(git rev-parse --show-toplevel)"
if [ "$CLAUDE_PROJECT_DIR" = "$EXPECTED_ROOT" ]; then
  pass "Detects git repository root correctly"
else
  fail "Expected: $EXPECTED_ROOT, Got: $CLAUDE_PROJECT_DIR"
fi

# Test 2: CLAUDE_PROJECT_DIR is exported
echo "Test 2: CLAUDE_PROJECT_DIR is exported"
reset_env
cd "$SCRIPT_DIR/.."
source "$CLAUDE_LIB/core/detect-project-dir.sh"

EXPORT_TEST=$(bash -c 'echo ${CLAUDE_PROJECT_DIR:-}')
if [ -n "$EXPORT_TEST" ]; then
  pass "CLAUDE_PROJECT_DIR is exported to child processes"
else
  fail "CLAUDE_PROJECT_DIR not exported"
fi

# Test 3: Respect pre-set CLAUDE_PROJECT_DIR
echo "Test 3: Respect pre-set CLAUDE_PROJECT_DIR"
reset_env
export CLAUDE_PROJECT_DIR="/custom/override/path"
source "$CLAUDE_LIB/core/detect-project-dir.sh"

if [ "$CLAUDE_PROJECT_DIR" = "/custom/override/path" ]; then
  pass "Respects manually set CLAUDE_PROJECT_DIR"
else
  fail "Override not respected. Got: $CLAUDE_PROJECT_DIR"
fi

# Test 4: Fallback to pwd when not in git repo
echo "Test 4: Fallback to pwd when not in git repo"
reset_env

# Create temporary directory outside git
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Source detection utility (should fallback to pwd)
source "$CLAUDE_LIB/core/detect-project-dir.sh"

if [ "$CLAUDE_PROJECT_DIR" = "$TEST_DIR" ]; then
  pass "Falls back to pwd outside git repository"
else
  fail "Expected: $TEST_DIR, Got: $CLAUDE_PROJECT_DIR"
fi

# Cleanup
cd "$SCRIPT_DIR"
rm -rf "$TEST_DIR"

# Test 5: Detection works when git command available
echo "Test 5: Git command availability check"
reset_env

if command -v git &>/dev/null; then
  pass "Git command is available"

  # Test git detection
  cd "$SCRIPT_DIR/.."
  source "$CLAUDE_LIB/core/detect-project-dir.sh"

  if [ -n "$CLAUDE_PROJECT_DIR" ]; then
    pass "Detection succeeds with git available"
  else
    fail "Detection failed despite git being available"
  fi
else
  info "Git not available (fallback will be used)"
fi

# Test 6: Detection in git worktree (if worktree exists)
echo "Test 6: Detection in git worktree"
reset_env

# Check if we can create a test worktree
cd "$SCRIPT_DIR/.."
MAIN_ROOT="$(git rev-parse --show-toplevel)"
TEST_WORKTREE="/tmp/test-worktree-detection-$$"

if git worktree add "$TEST_WORKTREE" HEAD &>/dev/null 2>&1; then
  # Worktree created successfully
  cd "$TEST_WORKTREE"
  source "$CLAUDE_LIB/core/detect-project-dir.sh"

  if [ "$CLAUDE_PROJECT_DIR" = "$TEST_WORKTREE" ]; then
    pass "Detects worktree root (not main repo root)"

    # Verify it's different from main root
    if [ "$CLAUDE_PROJECT_DIR" != "$MAIN_ROOT" ]; then
      pass "Worktree root differs from main repo root"
    else
      fail "Worktree root same as main repo root"
    fi
  else
    fail "Expected: $TEST_WORKTREE, Got: $CLAUDE_PROJECT_DIR"
  fi

  # Cleanup worktree
  cd "$SCRIPT_DIR"
  git worktree remove "$TEST_WORKTREE" --force &>/dev/null
else
  info "Cannot create test worktree (skipping worktree test)"
fi

# Test 7: Repeated sourcing doesn't change value
echo "Test 7: Idempotent behavior (repeated sourcing)"
reset_env
cd "$SCRIPT_DIR/.."
source "$CLAUDE_LIB/core/detect-project-dir.sh"
FIRST_VALUE="$CLAUDE_PROJECT_DIR"

source "$CLAUDE_LIB/core/detect-project-dir.sh"
SECOND_VALUE="$CLAUDE_PROJECT_DIR"

if [ "$FIRST_VALUE" = "$SECOND_VALUE" ]; then
  pass "Repeated sourcing produces consistent result"
else
  fail "Inconsistent detection: $FIRST_VALUE vs $SECOND_VALUE"
fi

# Test 8: Absolute path returned
echo "Test 8: Detection returns absolute path"
reset_env
cd "$SCRIPT_DIR/.."
source "$CLAUDE_LIB/core/detect-project-dir.sh"

if [[ "$CLAUDE_PROJECT_DIR" = /* ]]; then
  pass "Returns absolute path"
else
  fail "Path is not absolute: $CLAUDE_PROJECT_DIR"
fi

# Test 9: No trailing slash
echo "Test 9: No trailing slash in path"
reset_env
cd "$SCRIPT_DIR/.."
source "$CLAUDE_LIB/core/detect-project-dir.sh"

if [[ ! "$CLAUDE_PROJECT_DIR" =~ /$ ]]; then
  pass "No trailing slash in path"
else
  fail "Path has trailing slash: $CLAUDE_PROJECT_DIR"
fi

# Test 10: Detection from subdirectory
echo "Test 10: Detection from subdirectory"
reset_env
cd "$SCRIPT_DIR"  # tests/ subdirectory
source "$CLAUDE_LIB/core/detect-project-dir.sh"

EXPECTED_ROOT="$(git rev-parse --show-toplevel)"
if [ "$CLAUDE_PROJECT_DIR" = "$EXPECTED_ROOT" ]; then
  pass "Detects root from subdirectory"
else
  fail "Expected: $EXPECTED_ROOT, Got: $CLAUDE_PROJECT_DIR"
fi

# Summary
echo ""
echo "========================================"
echo "Test Results"
echo "========================================"
echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
echo -e "${RED}Failed:${NC} $TESTS_FAILED"
echo "Total:  $((TESTS_PASSED + TESTS_FAILED))"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed.${NC}"
  exit 1
fi
