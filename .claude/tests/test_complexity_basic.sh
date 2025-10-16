#!/usr/bin/env bash
# test_complexity_basic.sh - Basic complexity evaluation tests
# Simplified test suite focusing on core functionality

set -euo pipefail

# Detect project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CLAUDE_PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$CLAUDE_PROJECT_DIR/.claude/lib/complexity-utils.sh" 2>/dev/null || {
  echo "ERROR: Failed to source complexity-utils.sh"
  exit 1
}

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

pass_test() {
  local test_name="$1"
  echo -e "${GREEN}✓${NC} $test_name"
  ((TESTS_PASSED++))
  ((TESTS_RUN++))
}

fail_test() {
  local test_name="$1"
  local reason="${2:-}"
  echo -e "${RED}✗${NC} $test_name"
  [ -n "$reason" ] && echo "  Reason: $reason"
  ((TESTS_FAILED++))
  ((TESTS_RUN++))
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Complexity Evaluation Basic Test Suite"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: get_complexity_level function
if [ "$(get_complexity_level 1)" = "trivial" ]; then
  pass_test "Complexity level mapping: score=1 → trivial"
else
  fail_test "Complexity level mapping failed for score=1"
fi

if [ "$(get_complexity_level 5)" = "medium" ]; then
  pass_test "Complexity level mapping: score=5 → medium"
else
  fail_test "Complexity level mapping failed for score=5"
fi

if [ "$(get_complexity_level 9)" = "high" ]; then
  pass_test "Complexity level mapping: score=9 → high"
else
  fail_test "Complexity level mapping failed for score=9"
fi

# Test 2: detect_complexity_triggers
if [ "$(detect_complexity_triggers 9 8)" = "true" ]; then
  pass_test "Complexity trigger: high score (9)"
else
  fail_test "Complexity trigger not detected for high score"
fi

if [ "$(detect_complexity_triggers 5 12)" = "true" ]; then
  pass_test "Complexity trigger: high task count (12)"
else
  fail_test "Complexity trigger not detected for high task count"
fi

if [ "$(detect_complexity_triggers 5 8)" = "false" ]; then
  pass_test "No complexity trigger for moderate values"
else
  fail_test "False positive complexity trigger"
fi

# Test 3: JSON output validation for reconcile_scores
result=$(reconcile_scores 7 8 "high" "Test reasoning")
if echo "$result" | jq empty 2>/dev/null; then
  pass_test "reconcile_scores returns valid JSON"

  method=$(echo "$result" | jq -r '.reconciliation_method')
  if [ "$method" = "threshold" ]; then
    pass_test "Reconciliation uses threshold for agreeing scores"
  else
    fail_test "Reconciliation method incorrect" "Expected 'threshold', got '$method'"
  fi
else
  fail_test "reconcile_scores JSON invalid"
fi

# Test 4: High confidence reconciliation
result=$(reconcile_scores 5 9 "high" "Agent reasoning")
if echo "$result" | jq empty 2>/dev/null; then
  method=$(echo "$result" | jq -r '.reconciliation_method')
  score=$(echo "$result" | jq -r '.final_score')

  if [ "$method" = "agent" ] && [ "$score" = "9" ]; then
    pass_test "High confidence: uses agent score"
  else
    fail_test "High confidence reconciliation failed"
  fi
else
  fail_test "High confidence reconciliation JSON invalid"
fi

# Test 5: Medium confidence averaging
result=$(reconcile_scores 5 9 "medium" "Agent reasoning")
if echo "$result" | jq empty 2>/dev/null; then
  method=$(echo "$result" | jq -r '.reconciliation_method')
  score=$(echo "$result" | jq -r '.final_score')

  if [ "$method" = "hybrid" ]; then
    # Should be around 7.0
    if awk -v s="$score" 'BEGIN {exit !(s >= 6.5 && s <= 7.5)}'; then
      pass_test "Medium confidence: averages scores (~7.0)"
    else
      fail_test "Medium confidence average incorrect" "Got $score"
    fi
  else
    fail_test "Medium confidence method incorrect"
  fi
else
  fail_test "Medium confidence reconciliation JSON invalid"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Results"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}✓ All tests passed${NC}"
  echo ""
  echo "NOTE: Comprehensive testing (including agent invocation,"
  echo "      phase complexity calculation, and expansion accuracy)"
  echo "      will be completed in Phase 6 end-to-end testing."
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  exit 1
fi
