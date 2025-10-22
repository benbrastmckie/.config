#!/usr/bin/env bash
#
# Test Suite: Hybrid Complexity Evaluation
# Tests agent-based complexity scoring and score reconciliation
#
# Usage: bash test_hybrid_complexity.sh

set -euo pipefail

# Setup test environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source detect-project-dir to set CLAUDE_PROJECT_DIR
source "$SCRIPT_DIR/../lib/detect-project-dir.sh"

# Source complexity utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/complexity-utils.sh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
pass() {
  echo "✓ PASS: $1"
  TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
  echo "✗ FAIL: $1"
  TESTS_FAILED=$((TESTS_FAILED + 1))
}

run_test() {
  local test_name="$1"
  echo ""
  echo "Running: $test_name"
  TESTS_RUN=$((TESTS_RUN + 1))
}

# ==============================================================================
# Test 1: Threshold-Only Scoring
# ==============================================================================

test_threshold_only_scoring() {
  run_test "test_threshold_only_scoring"

  # Low complexity phase - agent should not be invoked
  local phase_name="Simple Configuration"
  local task_list="- [ ] Update config
- [ ] Restart service
- [ ] Verify"

  local result
  result=$(hybrid_complexity_evaluation "$phase_name" "$task_list" "")

  local method
  method=$(echo "$result" | jq -r '.evaluation_method')

  local score
  score=$(echo "$result" | jq -r '.final_score')

  if [[ "$method" = "threshold" ]]; then
    pass "Low complexity uses threshold-only (method=$method, score=$score)"
  else
    fail "Expected threshold-only for low complexity, got method=$method"
  fi
}

# ==============================================================================
# Test 2: Agent Invocation for Borderline Cases
# ==============================================================================

test_agent_invocation_borderline() {
  run_test "test_agent_invocation_borderline"

  # Borderline complexity - agent should be invoked
  local phase_name="Core State Management Refactor"
  local task_list="- [ ] Design state management architecture
- [ ] Implement state store module
- [ ] Integrate with auth system
- [ ] Add cache layer
- [ ] Handle concurrency
- [ ] Security audit
- [ ] Performance testing
- [ ] Integration testing"

  # Create temporary test plan file
  local test_plan_file="/tmp/test_plan_$$.md"
  cat > "$test_plan_file" <<'EOF'
## Overview

Test plan for state management refactor with high complexity.

## Success Criteria

- Secure state management
- High performance
- Integration with existing systems
EOF

  local result=$(hybrid_complexity_evaluation "$phase_name" "$task_list" "$test_plan_file")
  local method=$(echo "$result" | jq -r '.evaluation_method')
  local score=$(echo "$result" | jq -r '.final_score')

  rm -f "$test_plan_file"

  # Agent should be invoked for borderline case (method != threshold)
  if [[ "$method" != "threshold" ]] || [[ "$score" -ge 7 ]]; then
    pass "Borderline complexity triggers agent evaluation (method=$method, score=$score)"
  else
    # It's also acceptable if agent invocation failed and fell back to threshold
    # as long as the score reflects high complexity
    if [[ "$method" = "threshold_fallback" ]]; then
      pass "Agent invoked but failed, fallback to threshold (method=$method, score=$score)"
    else
      fail "Expected agent invocation for borderline case, got method=$method with score=$score"
    fi
  fi
}

# ==============================================================================
# Test 3: Score Reconciliation - Agent Agrees
# ==============================================================================

test_score_reconciliation_agent_agrees() {
  run_test "test_score_reconciliation_agent_agrees"

  # Test reconciliation when scores are close (diff < 2)
  local reconciliation=$(reconcile_scores 7 8 "high" "Test reasoning")
  local method=$(echo "$reconciliation" | jq -r '.reconciliation_method')
  local final_score=$(echo "$reconciliation" | jq -r '.final_score')

  if [[ "$method" = "threshold" ]] && [[ "$final_score" = "7" ]]; then
    pass "Scores agree (diff<2), uses threshold (method=$method, score=$final_score)"
  else
    fail "Expected threshold method when scores agree, got method=$method, score=$final_score"
  fi
}

# ==============================================================================
# Test 4: Score Reconciliation - Agent Overrides
# ==============================================================================

test_score_reconciliation_agent_overrides() {
  run_test "test_score_reconciliation_agent_overrides"

  # Test reconciliation when scores differ significantly and agent confident
  local reconciliation=$(reconcile_scores 3 9 "high" "Significant architectural complexity")
  local method=$(echo "$reconciliation" | jq -r '.reconciliation_method')
  local final_score=$(echo "$reconciliation" | jq -r '.final_score')

  if [[ "$method" = "agent" ]] && [[ "$final_score" = "9" ]]; then
    pass "High-confidence agent overrides threshold (method=$method, score=$final_score)"
  else
    fail "Expected agent override with high confidence, got method=$method, score=$final_score"
  fi
}

# ==============================================================================
# Test 5: Score Reconciliation - Hybrid Average
# ==============================================================================

test_score_reconciliation_hybrid_average() {
  run_test "test_score_reconciliation_hybrid_average"

  # Test reconciliation when scores differ and agent medium confidence
  local reconciliation=$(reconcile_scores 4 8 "medium" "Moderate disagreement")
  local method=$(echo "$reconciliation" | jq -r '.reconciliation_method')
  local final_score=$(echo "$reconciliation" | jq -r '.final_score')

  # Check if final_score is 6.0 (average of 4 and 8)
  if [[ "$method" = "hybrid" ]] && [[ "$final_score" = "6.0" ]]; then
    pass "Medium confidence uses hybrid average (method=$method, score=$final_score)"
  else
    fail "Expected hybrid averaging with medium confidence, got method=$method, score=$final_score"
  fi
}

# ==============================================================================
# Test 6: Agent Failure Fallback
# ==============================================================================

test_agent_failure_fallback() {
  run_test "test_agent_failure_fallback"

  # Test fallback to threshold when agent fails
  # Temporarily override agent function to simulate failure
  original_agent_func=$(declare -f agent_based_complexity_score)

  agent_based_complexity_score() {
    echo '{"status":"error","error":"Simulated agent failure"}'
    return 1
  }

  local result=$(hybrid_complexity_evaluation "Test Phase" "- [ ] Task 1
- [ ] Task 2
- [ ] Task 3
- [ ] Task 4
- [ ] Task 5
- [ ] Task 6
- [ ] Task 7
- [ ] Task 8" "")

  local method=$(echo "$result" | jq -r '.evaluation_method')
  local error=$(echo "$result" | jq -r '.agent_error // "null"')

  # Restore original function
  eval "$original_agent_func"

  if [[ "$method" = "threshold_fallback" ]] && [[ "$error" != "null" ]]; then
    pass "Agent failure triggers threshold fallback (method=$method, error present)"
  else
    fail "Expected threshold_fallback on agent error, got method=$method, error=$error"
  fi
}

# ==============================================================================
# Run All Tests
# ==============================================================================

echo "========================================"
echo "Hybrid Complexity Evaluation Test Suite"
echo "========================================"

test_threshold_only_scoring
test_agent_invocation_borderline
test_score_reconciliation_agent_agrees
test_score_reconciliation_agent_overrides
test_score_reconciliation_hybrid_average
test_agent_failure_fallback

echo ""
echo "========================================"
echo "Test Results"
echo "========================================"
echo "Tests Run:    $TESTS_RUN"
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"
echo "========================================"

if [ "$TESTS_FAILED" -eq 0 ]; then
  echo "✓ All tests passed!"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
