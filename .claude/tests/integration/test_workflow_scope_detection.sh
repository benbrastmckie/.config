#!/usr/bin/env bash
# Test workflow scope detection logic
# Tests: Plan path detection, keyword priority, revise patterns, all scope types

set -euo pipefail

# Test framework
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  if [ -n "${2:-}" ]; then
    echo "  Expected: $2"
    echo "  Got: ${3:-<not provided>}"
  fi
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

skip() {
  echo -e "${YELLOW}⊘ SKIP${NC}: $1"
  SKIP_COUNT=$((SKIP_COUNT + 1))
}

info() {
  echo -e "${BLUE}ℹ INFO${NC}: $1"
}

# Find lib directory
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

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

# Source workflow scope detection
source "$LIB_DIR/workflow/workflow-scope-detection.sh"

echo "========================================="
echo "Workflow Scope Detection Tests"
echo "========================================="
echo

# =============================================================================
# Test 1: Plan Path Detection (PRIORITY 2)
# =============================================================================
info "Test 1: Plan path - implement with explicit path"
result=$(detect_workflow_scope "implement specs/661_auth/plans/001_implementation.md")
if [ "$result" = "full-implementation" ]; then
  pass "Plan path detected as full-implementation"
else
  fail "Plan path detection" "full-implementation" "$result"
fi

# =============================================================================
# Test 2: Plan Keyword
# =============================================================================
info "Test 2: Plan keyword - research and planning"
result=$(detect_workflow_scope "plan authentication feature")
if [ "$result" = "research-and-plan" ]; then
  pass "Plan keyword detected as research-and-plan"
else
  fail "Plan keyword detection" "research-and-plan" "$result"
fi

# =============================================================================
# Test 3: Research-Only Pattern
# =============================================================================
info "Test 3: Research-only - pure research with no action keywords"
result=$(detect_workflow_scope "research async patterns")
if [ "$result" = "research-only" ]; then
  pass "Research-only detected correctly"
else
  fail "Research-only detection" "research-only" "$result"
fi

# =============================================================================
# Test 4: Research-and-Revise with Plan Path (PRIORITY 1)
# =============================================================================
info "Test 4: Revise pattern - revise with plan path and trigger keyword"
result=$(detect_workflow_scope "revise specs/027_auth/plans/001_plan.md based on feedback")
if [ "$result" = "research-and-revise" ]; then
  pass "Revise pattern with path detected as research-and-revise"
else
  fail "Revise pattern detection" "research-and-revise" "$result"
fi

# =============================================================================
# Test 5: Explicit Implement Keyword (PRIORITY 4)
# =============================================================================
info "Test 5: Implement keyword - explicit implementation intent"
result=$(detect_workflow_scope "implement new feature")
if [ "$result" = "full-implementation" ]; then
  pass "Implement keyword detected as full-implementation"
else
  fail "Implement keyword detection" "full-implementation" "$result"
fi

# =============================================================================
# Test 6: Debug Pattern
# =============================================================================
info "Test 6: Debug pattern - fix/debug/troubleshoot"
result=$(detect_workflow_scope "debug authentication issue")
if [ "$result" = "debug-only" ]; then
  pass "Debug pattern detected as debug-only"
else
  fail "Debug pattern detection" "debug-only" "$result"
fi

# =============================================================================
# Test 7: Execute Keyword with Plan Path
# =============================================================================
info "Test 7: Execute keyword - plan path execution"
result=$(detect_workflow_scope "execute the plan at specs/042_test/plans/001_plan.md")
if [ "$result" = "full-implementation" ]; then
  pass "Execute with plan path detected as full-implementation"
else
  fail "Execute keyword detection" "full-implementation" "$result"
fi

# =============================================================================
# Test 8: Ambiguous Input - Default Fallback
# =============================================================================
info "Test 8: Ambiguous input - should default to research-and-plan"
result=$(detect_workflow_scope "do something with the codebase")
if [ "$result" = "research-and-plan" ]; then
  pass "Ambiguous input defaults to research-and-plan"
else
  fail "Ambiguous input default" "research-and-plan" "$result"
fi

# =============================================================================
# Test 9: Research with Implement Keyword (should be full-implementation)
# =============================================================================
info "Test 9: Research with implement keyword - should be full-implementation"
result=$(detect_workflow_scope "research async patterns and implement solution")
if [ "$result" = "full-implementation" ]; then
  pass "Research with implement keyword detected as full-implementation"
else
  fail "Research with implement keyword" "full-implementation" "$result"
fi

# =============================================================================
# Test 10: Plan Path with Absolute Path
# =============================================================================
info "Test 10: Plan path - absolute path starting with /"
result=$(detect_workflow_scope "implement /home/user/.config/.claude/specs/042_auth/plans/001_plan.md")
if [ "$result" = "full-implementation" ]; then
  pass "Absolute plan path detected as full-implementation"
else
  fail "Absolute plan path detection" "full-implementation" "$result"
fi

# =============================================================================
# Test 11: Plan Path with Relative Path
# =============================================================================
info "Test 11: Plan path - relative path starting with ./"
result=$(detect_workflow_scope "implement ./.claude/specs/042_auth/plans/001_plan.md")
if [ "$result" = "full-implementation" ]; then
  pass "Relative plan path detected as full-implementation"
else
  fail "Relative plan path detection" "full-implementation" "$result"
fi

# =============================================================================
# Test 12: Revise Without Plan Path
# =============================================================================
info "Test 12: Revise pattern - revise plan without explicit path"
result=$(detect_workflow_scope "revise the authentication plan to accommodate new requirements")
if [ "$result" = "research-and-revise" ]; then
  pass "Revise without path detected as research-and-revise"
else
  fail "Revise without path" "research-and-revise" "$result"
fi

# =============================================================================
# Test 13: Update Plan Pattern (synonym for revise)
# =============================================================================
info "Test 13: Update pattern - update plan synonym"
result=$(detect_workflow_scope "update the implementation plan based on review")
if [ "$result" = "research-and-revise" ]; then
  pass "Update plan pattern detected as research-and-revise"
else
  fail "Update plan pattern" "research-and-revise" "$result"
fi

# =============================================================================
# Test 14: Modify Plan Pattern (synonym for revise)
# =============================================================================
info "Test 14: Modify pattern - modify plan synonym"
result=$(detect_workflow_scope "modify specs/042_test/plans/001_plan.md for new requirements")
if [ "$result" = "research-and-revise" ]; then
  pass "Modify plan pattern detected as research-and-revise"
else
  fail "Modify plan pattern" "research-and-revise" "$result"
fi

# =============================================================================
# Test 15: Build Feature Pattern
# =============================================================================
info "Test 15: Build feature - should be full-implementation"
result=$(detect_workflow_scope "build authentication feature")
if [ "$result" = "full-implementation" ]; then
  pass "Build feature detected as full-implementation"
else
  fail "Build feature detection" "full-implementation" "$result"
fi

# =============================================================================
# Test 16: Create Feature Pattern
# =============================================================================
info "Test 16: Create feature - should be full-implementation"
result=$(detect_workflow_scope "create logging feature")
if [ "$result" = "full-implementation" ]; then
  pass "Create feature detected as full-implementation"
else
  fail "Create feature detection" "full-implementation" "$result"
fi

# =============================================================================
# Test 17: Fix Pattern (debug-only)
# =============================================================================
info "Test 17: Fix pattern - should be debug-only"
result=$(detect_workflow_scope "fix the broken authentication flow")
if [ "$result" = "debug-only" ]; then
  pass "Fix pattern detected as debug-only"
else
  fail "Fix pattern detection" "debug-only" "$result"
fi

# =============================================================================
# Test 18: Troubleshoot Pattern (debug-only)
# =============================================================================
info "Test 18: Troubleshoot pattern - should be debug-only"
result=$(detect_workflow_scope "troubleshoot performance issues")
if [ "$result" = "debug-only" ]; then
  pass "Troubleshoot pattern detected as debug-only"
else
  fail "Troubleshoot pattern detection" "debug-only" "$result"
fi

# =============================================================================
# Test 19: Design Pattern (research-and-plan)
# =============================================================================
info "Test 19: Design pattern - should be research-and-plan"
result=$(detect_workflow_scope "design the authentication architecture")
if [ "$result" = "research-and-plan" ]; then
  pass "Design pattern detected as research-and-plan"
else
  fail "Design pattern detection" "research-and-plan" "$result"
fi

# =============================================================================
# Test 20: Create Plan Pattern (research-and-plan)
# =============================================================================
info "Test 20: Create plan - should be research-and-plan"
result=$(detect_workflow_scope "create plan for authentication feature")
if [ "$result" = "research-and-plan" ]; then
  pass "Create plan detected as research-and-plan"
else
  fail "Create plan detection" "research-and-plan" "$result"
fi

# =============================================================================
# Summary
# =============================================================================
echo
echo "========================================="
echo "Test Summary"
echo "========================================="
echo -e "${GREEN}Passed${NC}: $PASS_COUNT"
echo -e "${RED}Failed${NC}: $FAIL_COUNT"
echo -e "${YELLOW}Skipped${NC}: $SKIP_COUNT"
echo "========================================="
echo

if [ $FAIL_COUNT -eq 0 ]; then
  echo -e "${GREEN}✓ All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  exit 1
fi
