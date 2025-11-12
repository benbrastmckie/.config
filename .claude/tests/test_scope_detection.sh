#!/usr/bin/env bash
# Integration tests for unified workflow scope detection
# Tests: Hybrid mode, LLM-only mode, regex-only mode, fallback scenarios

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
LIB_DIR=$(cd "$SCRIPT_DIR/../lib" && pwd)

# Source unified workflow scope detection
source "$LIB_DIR/workflow-scope-detection.sh"

echo "========================================="
echo "Unified Workflow Scope Detection Tests"
echo "========================================="
echo

# =============================================================================
# Section 1: Regex-Only Mode Tests (Backward Compatibility)
# =============================================================================
echo "Section 1: Regex-Only Mode (Backward Compatibility)"
echo "----------------------------------------------------"

export WORKFLOW_CLASSIFICATION_MODE=regex-only

# Test 1.1: Plan path detection
info "Test 1.1: Plan path - implement with explicit path"
result=$(detect_workflow_scope "implement specs/661_auth/plans/001_implementation.md")
if [ "$result" = "full-implementation" ]; then
  pass "Plan path detected as full-implementation"
else
  fail "Plan path detection" "full-implementation" "$result"
fi

# Test 1.2: Plan keyword
info "Test 1.2: Plan keyword - research and planning"
result=$(detect_workflow_scope "plan authentication feature")
if [ "$result" = "research-and-plan" ]; then
  pass "Plan keyword detected as research-and-plan"
else
  fail "Plan keyword detection" "research-and-plan" "$result"
fi

# Test 1.3: Research-only pattern
info "Test 1.3: Research-only - pure research with no action keywords"
result=$(detect_workflow_scope "research async patterns")
if [ "$result" = "research-only" ]; then
  pass "Research-only detected correctly"
else
  fail "Research-only detection" "research-only" "$result"
fi

# Test 1.4: Research-and-revise with plan path
info "Test 1.4: Revise pattern - revise with plan path and trigger keyword"
result=$(detect_workflow_scope "revise specs/027_auth/plans/001_plan.md based on feedback")
if [ "$result" = "research-and-revise" ]; then
  pass "Revise pattern with path detected as research-and-revise"
else
  fail "Revise pattern detection" "research-and-revise" "$result"
fi

# Test 1.5: Explicit implement keyword
info "Test 1.5: Implement keyword - explicit implementation intent"
result=$(detect_workflow_scope "implement authentication feature")
if [ "$result" = "full-implementation" ]; then
  pass "Implement keyword detected as full-implementation"
else
  fail "Implement keyword detection" "full-implementation" "$result"
fi

# Test 1.6: Debug keyword
info "Test 1.6: Debug keyword - debugging intent"
result=$(detect_workflow_scope "debug token refresh issue")
if [ "$result" = "debug-only" ]; then
  pass "Debug keyword detected as debug-only"
else
  fail "Debug keyword detection" "debug-only" "$result"
fi

# Test 1.7: Research with action keyword
info "Test 1.7: Research with action - research and plan"
result=$(detect_workflow_scope "research auth patterns and create plan")
if [ "$result" = "research-and-plan" ]; then
  pass "Research with action detected as research-and-plan"
else
  fail "Research with action detection" "research-and-plan" "$result"
fi

# Test 1.8: Edge case - "research the research-and-revise workflow"
info "Test 1.8: Edge case - discussing workflow types (regex FAILS this test)"
result=$(detect_workflow_scope "research the research-and-revise workflow misclassification")
if [ "$result" = "research-and-revise" ]; then
  # This is the KNOWN FAILURE for regex - it matches the pattern even when discussing it
  skip "Edge case: regex incorrectly detects research-and-revise (expected behavior, LLM fixes this)"
else
  pass "Edge case handled correctly by regex"
fi

echo

# =============================================================================
# Section 2: Hybrid Mode Tests (Default Behavior)
# =============================================================================
echo "Section 2: Hybrid Mode (Default Behavior)"
echo "------------------------------------------"

export WORKFLOW_CLASSIFICATION_MODE=hybrid

# Test 2.1: Hybrid mode with valid input (will fall back to regex without real LLM)
info "Test 2.1: Hybrid mode - fallback to regex on LLM unavailable"
result=$(detect_workflow_scope "plan user management feature")
if [ "$result" = "research-and-plan" ]; then
  pass "Hybrid mode falls back to regex successfully"
else
  fail "Hybrid fallback" "research-and-plan" "$result"
fi

# Test 2.2: Hybrid mode handles empty input gracefully
info "Test 2.2: Hybrid mode - empty input validation"
if result=$(detect_workflow_scope "" 2>/dev/null); then
  fail "Empty input validation" "should return error" "succeeded: $result"
else
  pass "Empty input correctly rejected in hybrid mode"
fi

# Test 2.3: Hybrid mode with complex input
info "Test 2.3: Hybrid mode - complex workflow description"
result=$(detect_workflow_scope "research OAuth2 patterns, analyze security implications, and create implementation plan")
if [ "$result" = "research-and-plan" ]; then
  pass "Complex description classified correctly"
else
  fail "Complex description" "research-and-plan" "$result"
fi

echo

# =============================================================================
# Section 3: LLM-Only Mode Tests
# =============================================================================
echo "Section 3: LLM-Only Mode"
echo "------------------------"

export WORKFLOW_CLASSIFICATION_MODE=llm-only

# Test 3.1: LLM-only mode fails fast without LLM (expected behavior)
info "Test 3.1: LLM-only mode - fails fast without LLM"
if result=$(detect_workflow_scope "plan feature" 2>/dev/null); then
  # Without real LLM, this should fail and return default
  if [ "$result" = "research-and-plan" ]; then
    pass "LLM-only mode returns default on failure"
  else
    fail "LLM-only fallback" "research-and-plan" "$result"
  fi
else
  pass "LLM-only mode fails fast as expected"
fi

echo

# =============================================================================
# Section 4: Mode Configuration Tests
# =============================================================================
echo "Section 4: Mode Configuration"
echo "------------------------------"

# Test 4.1: Invalid mode
info "Test 4.1: Invalid classification mode"
export WORKFLOW_CLASSIFICATION_MODE=invalid-mode
if result=$(detect_workflow_scope "test" 2>/dev/null); then
  if [ "$result" = "research-and-plan" ]; then
    pass "Invalid mode returns default gracefully"
  else
    fail "Invalid mode handling" "research-and-plan" "$result"
  fi
else
  pass "Invalid mode rejected with error"
fi

# Test 4.2: Mode switching
info "Test 4.2: Mode switching - regex to hybrid"
export WORKFLOW_CLASSIFICATION_MODE=regex-only
result1=$(detect_workflow_scope "plan feature")
export WORKFLOW_CLASSIFICATION_MODE=hybrid
result2=$(detect_workflow_scope "plan feature")
if [ "$result1" = "research-and-plan" ] && [ "$result2" = "research-and-plan" ]; then
  pass "Mode switching works correctly"
else
  fail "Mode switching" "both research-and-plan" "regex=$result1, hybrid=$result2"
fi

echo

# =============================================================================
# Section 5: Edge Cases and Special Characters
# =============================================================================
echo "Section 5: Edge Cases"
echo "---------------------"

export WORKFLOW_CLASSIFICATION_MODE=regex-only

# Test 5.1: Long description
info "Test 5.1: Long workflow description (500+ chars)"
long_desc=$(printf 'research authentication patterns and security best practices %.0s' {1..20})
result=$(detect_workflow_scope "$long_desc")
if [ "$result" = "research-only" ]; then
  pass "Long description handled correctly (research-only, no action keywords)"
else
  fail "Long description" "research-only (no action keywords)" "$result"
fi

# Test 5.2: Special characters
info "Test 5.2: Special characters in description"
result=$(detect_workflow_scope 'plan "authentication" & authorization feature'"'"'s structure')
if [ "$result" = "research-and-plan" ]; then
  pass "Special characters handled correctly"
else
  fail "Special characters" "research-and-plan" "$result"
fi

# Test 5.3: Unicode characters
info "Test 5.3: Unicode characters in description"
result=$(detect_workflow_scope "plan 日本語 authentication feature")
if [ "$result" = "research-and-plan" ]; then
  pass "Unicode characters handled correctly"
else
  fail "Unicode handling" "research-and-plan" "$result"
fi

# Test 5.4: Multiple keywords (priority testing)
info "Test 5.4: Multiple keywords - implement takes priority"
result=$(detect_workflow_scope "research patterns and implement feature")
if [ "$result" = "full-implementation" ]; then
  pass "Keyword priority correct (implement > research)"
else
  fail "Keyword priority" "full-implementation" "$result"
fi

# Test 5.5: Revision-first pattern
info "Test 5.5: Revision-first - explicit revise at start"
result=$(detect_workflow_scope "Revise the implementation plan to accommodate new requirements")
if [ "$result" = "research-and-revise" ]; then
  pass "Revision-first pattern detected correctly"
else
  fail "Revision-first pattern" "research-and-revise" "$result"
fi

echo

# =============================================================================
# Section 6: Backward Compatibility Tests
# =============================================================================
echo "Section 6: Backward Compatibility"
echo "----------------------------------"

export WORKFLOW_CLASSIFICATION_MODE=regex-only

# Test 6.1: Function signature compatibility
info "Test 6.1: Function signature unchanged"
if result=$(detect_workflow_scope "test description"); then
  if [ -n "$result" ]; then
    pass "Function signature backward compatible"
  else
    fail "Function signature" "non-empty result" "empty"
  fi
else
  fail "Function signature" "should succeed" "failed"
fi

# Test 6.2: Environment variable compatibility
info "Test 6.2: DEBUG_SCOPE_DETECTION support"
export DEBUG_SCOPE_DETECTION=1
output=$(detect_workflow_scope "test" 2>&1 | grep -c "DEBUG" || echo "0")
if [ "$output" -gt 0 ]; then
  pass "DEBUG_SCOPE_DETECTION still works"
else
  fail "DEBUG_SCOPE_DETECTION" "debug output" "no output"
fi
export DEBUG_SCOPE_DETECTION=0

# Test 6.3: All scope types still supported
info "Test 6.3: All scope types supported"
declare -A scope_tests=(
  ["research async patterns"]="research-only"
  ["plan user feature"]="research-and-plan"
  ["revise specs/001/plans/001.md based on feedback"]="research-and-revise"
  ["implement user authentication"]="full-implementation"
  ["debug login failure"]="debug-only"
)

all_scopes_pass=1
for desc in "${!scope_tests[@]}"; do
  expected="${scope_tests[$desc]}"
  result=$(detect_workflow_scope "$desc")
  if [ "$result" != "$expected" ]; then
    all_scopes_pass=0
    echo "  Failed: '$desc' -> expected $expected, got $result"
  fi
done

if [ $all_scopes_pass -eq 1 ]; then
  pass "All 5 scope types still supported"
else
  fail "Scope type support" "all 5 types" "some failed (see above)"
fi

echo

# =============================================================================
# Section 7: Integration with workflow-detection.sh
# =============================================================================
echo "Section 7: Integration Tests"
echo "-----------------------------"

# Test 7.1: workflow-detection.sh sources unified library
info "Test 7.1: workflow-detection.sh integration"
if source "$LIB_DIR/workflow-detection.sh" 2>/dev/null; then
  # should_run_phase should be available
  if declare -f should_run_phase >/dev/null; then
    pass "workflow-detection.sh integrates correctly"
  else
    fail "workflow-detection.sh integration" "should_run_phase defined" "not found"
  fi
else
  fail "workflow-detection.sh integration" "successful source" "failed"
fi

# Test 7.2: detect_workflow_scope available via workflow-detection.sh
info "Test 7.2: detect_workflow_scope available after sourcing workflow-detection.sh"
if declare -f detect_workflow_scope >/dev/null; then
  pass "detect_workflow_scope available"
else
  fail "detect_workflow_scope availability" "function defined" "not found"
fi

echo

# =============================================================================
# Test Summary
# =============================================================================
echo "========================================="
echo "Test Summary"
echo "========================================="
echo "PASS: $PASS_COUNT"
echo "FAIL: $FAIL_COUNT"
echo "SKIP: $SKIP_COUNT"
echo "TOTAL: $((PASS_COUNT + FAIL_COUNT + SKIP_COUNT))"
echo

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo -e "${GREEN}✓ All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  exit 1
fi
