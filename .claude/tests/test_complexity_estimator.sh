#!/usr/bin/env bash
# test_complexity_estimator.sh - Test complexity evaluation utilities
# Tests complexity-utils.sh functions for accuracy and reliability

set -euo pipefail

# Detect project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CLAUDE_PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$CLAUDE_PROJECT_DIR/.claude/lib/complexity-utils.sh" 2>/dev/null || {
  echo "ERROR: Failed to source complexity-utils.sh"
  exit 1
}
source "$CLAUDE_PROJECT_DIR/.claude/lib/base-utils.sh" 2>/dev/null || true

# Test fixtures directory
FIXTURES_DIR="$SCRIPT_DIR/fixtures/complexity_evaluation"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test result reporting
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
  if [ -n "$reason" ]; then
    echo "  Reason: $reason"
  fi
  ((TESTS_FAILED++))
  ((TESTS_RUN++))
}

# Test: calculate_phase_complexity with simple phase
test_simple_phase_complexity() {
  local phase_name="Update Configuration Files"
  local task_list="- [ ] Add feature_x flag to config.yaml
- [ ] Add feature_y flag to config.yaml
- [ ] Update config schema documentation"

  local score
  score=$(calculate_phase_complexity "$phase_name" "$task_list")

  # Simple phase should have low complexity (0-4)
  if [ "$score" -le 4 ]; then
    pass_test "Simple phase complexity score ($score) is in expected range (0-4)"
  else
    fail_test "Simple phase complexity score ($score) exceeds expected range" "Expected ≤4, got $score"
  fi
}

# Test: calculate_phase_complexity with medium phase
test_medium_phase_complexity() {
  local phase_name="API Endpoints Implementation"
  local task_list="- [ ] Create GET /api/profile endpoint
- [ ] Create PUT /api/profile endpoint
- [ ] Add authentication middleware
- [ ] Implement validation logic
- [ ] Add rate limiting
- [ ] Write integration tests"

  local score
  score=$(calculate_phase_complexity "$phase_name" "$task_list")

  # Medium phase should have medium complexity (4-7)
  if [ "$score" -ge 4 ] && [ "$score" -le 7 ]; then
    pass_test "Medium phase complexity score ($score) is in expected range (4-7)"
  else
    fail_test "Medium phase complexity score ($score) outside expected range" "Expected 4-7, got $score"
  fi
}

# Test: calculate_phase_complexity with complex phase
test_complex_phase_complexity() {
  local phase_name="Microservices Architecture Design and Refactor"
  local task_list="- [ ] Analyze current monolith dependencies
- [ ] Identify service boundaries using domain-driven design
- [ ] Design inter-service communication patterns
- [ ] Define API contracts and schemas
- [ ] Design event bus architecture
- [ ] Create migration strategy document
- [ ] Review with architecture team
- [ ] Design database per service strategy
- [ ] Plan for distributed transactions
- [ ] Design service discovery mechanism
- [ ] Plan for distributed logging and monitoring
- [ ] Create rollback strategy"

  local score
  score=$(calculate_phase_complexity "$phase_name" "$task_list")

  # Complex phase should have high complexity (≥8)
  if [ "$score" -ge 8 ]; then
    pass_test "Complex phase complexity score ($score) is in expected range (≥8)"
  else
    fail_test "Complex phase complexity score ($score) below expected threshold" "Expected ≥8, got $score"
  fi
}

# Test: analyze_task_structure JSON output
test_task_structure_json() {
  local task_list="- [ ] Task 1
  - [ ] Subtask 1.1
  - [ ] Subtask 1.2
- [ ] Task 2"

  local json_output
  json_output=$(analyze_task_structure "$task_list")

  # Validate JSON structure
  if echo "$json_output" | jq empty 2>/dev/null; then
    pass_test "analyze_task_structure returns valid JSON"

    # Check for required fields
    local total_tasks nested_tasks max_depth
    total_tasks=$(echo "$json_output" | jq -r '.total_tasks')
    nested_tasks=$(echo "$json_output" | jq -r '.nested_tasks')
    max_depth=$(echo "$json_output" | jq -r '.max_depth')

    if [ "$total_tasks" = "2" ] && [ "$nested_tasks" = "2" ] && [ "$max_depth" = "2" ]; then
      pass_test "Task structure metrics are correct"
    else
      fail_test "Task structure metrics incorrect" "total:$total_tasks nested:$nested_tasks depth:$max_depth"
    fi
  else
    fail_test "analyze_task_structure JSON is invalid"
  fi
}

# Test: detect_complexity_triggers
test_complexity_triggers() {
  # Test high complexity trigger
  if [ "$(detect_complexity_triggers 9 8)" = "true" ]; then
    pass_test "Complexity trigger detected for score=9"
  else
    fail_test "Complexity trigger not detected for score=9"
  fi

  # Test high task count trigger
  if [ "$(detect_complexity_triggers 5 12)" = "true" ]; then
    pass_test "Complexity trigger detected for task_count=12"
  else
    fail_test "Complexity trigger not detected for task_count=12"
  fi

  # Test no trigger
  if [ "$(detect_complexity_triggers 5 8)" = "false" ]; then
    pass_test "No complexity trigger for score=5, tasks=8"
  else
    fail_test "False complexity trigger for score=5, tasks=8"
  fi
}

# Test: generate_complexity_report JSON structure
test_complexity_report_json() {
  local phase_name="Test Phase"
  local task_list="- [ ] Task 1
- [ ] Task 2
- [ ] Task 3"

  local report
  report=$(generate_complexity_report "$phase_name" "$task_list")

  # Validate JSON
  if echo "$report" | jq empty 2>/dev/null; then
    pass_test "Complexity report returns valid JSON"

    # Check required fields
    local has_phase_name has_score has_trigger has_action
    has_phase_name=$(echo "$report" | jq 'has("phase_name")')
    has_score=$(echo "$report" | jq 'has("complexity_score")')
    has_trigger=$(echo "$report" | jq 'has("trigger_detected")')
    has_action=$(echo "$report" | jq 'has("recommended_action")')

    if [ "$has_phase_name" = "true" ] && [ "$has_score" = "true" ] && \
       [ "$has_trigger" = "true" ] && [ "$has_action" = "true" ]; then
      pass_test "Complexity report has all required fields"
    else
      fail_test "Complexity report missing required fields"
    fi
  else
    fail_test "Complexity report JSON is invalid"
  fi
}

# Test: get_complexity_level mapping
test_complexity_level_mapping() {
  if [ "$(get_complexity_level 1)" = "trivial" ]; then
    pass_test "Complexity level for score=1 is 'trivial'"
  else
    fail_test "Complexity level mapping incorrect for score=1"
  fi

  if [ "$(get_complexity_level 5)" = "medium" ]; then
    pass_test "Complexity level for score=5 is 'medium'"
  else
    fail_test "Complexity level mapping incorrect for score=5"
  fi

  if [ "$(get_complexity_level 9)" = "high" ]; then
    pass_test "Complexity level for score=9 is 'high'"
  else
    fail_test "Complexity level mapping incorrect for score=9"
  fi
}

# Test: analyze_plan_complexity with test fixtures
test_analyze_plan_complexity() {
  local simple_plan="$FIXTURES_DIR/test_plan_simple.md"

  if [ -f "$simple_plan" ]; then
    local plan_json
    plan_json=$(analyze_plan_complexity "$simple_plan")

    if echo "$plan_json" | jq empty 2>/dev/null; then
      pass_test "analyze_plan_complexity returns valid JSON"

      local phase_count
      phase_count=$(echo "$plan_json" | jq -r '.total_phases')

      if [ "$phase_count" = "2" ]; then
        pass_test "Plan analysis detects correct phase count (2)"
      else
        fail_test "Plan analysis phase count incorrect" "Expected 2, got $phase_count"
      fi
    else
      fail_test "analyze_plan_complexity JSON invalid"
    fi
  else
    fail_test "Test fixture not found" "$simple_plan"
  fi
}

# Test: Confidence-based reconciliation logic
test_reconcile_scores() {
  # Test case 1: Scores agree (diff < 2)
  local result1
  result1=$(reconcile_scores 7 8 "high" "Agent reasoning")

  if echo "$result1" | jq empty 2>/dev/null; then
    local method1
    method1=$(echo "$result1" | jq -r '.reconciliation_method')
    if [ "$method1" = "threshold" ]; then
      pass_test "Reconciliation uses threshold when scores agree (diff=1)"
    else
      fail_test "Reconciliation method incorrect for agreeing scores" "Expected 'threshold', got '$method1'"
    fi
  else
    fail_test "Reconciliation JSON invalid for test case 1"
  fi

  # Test case 2: Scores disagree, high confidence
  local result2
  result2=$(reconcile_scores 5 9 "high" "Agent reasoning")

  if echo "$result2" | jq empty 2>/dev/null; then
    local method2 final_score2
    method2=$(echo "$result2" | jq -r '.reconciliation_method')
    final_score2=$(echo "$result2" | jq -r '.final_score')

    if [ "$method2" = "agent" ] && [ "$final_score2" = "9" ]; then
      pass_test "Reconciliation uses agent score for high confidence disagreement"
    else
      fail_test "Reconciliation incorrect for high confidence" "method=$method2, score=$final_score2"
    fi
  else
    fail_test "Reconciliation JSON invalid for test case 2"
  fi

  # Test case 3: Scores disagree, medium confidence
  local result3
  result3=$(reconcile_scores 5 9 "medium" "Agent reasoning")

  if echo "$result3" | jq empty 2>/dev/null; then
    local method3 final_score3
    method3=$(echo "$result3" | jq -r '.reconciliation_method')
    final_score3=$(echo "$result3" | jq -r '.final_score')

    if [ "$method3" = "hybrid" ]; then
      # Average should be 7.0
      if awk -v score="$final_score3" 'BEGIN {exit !(score >= 6.5 && score <= 7.5)}'; then
        pass_test "Reconciliation averages scores for medium confidence"
      else
        fail_test "Reconciliation average incorrect" "Expected ~7.0, got $final_score3"
      fi
    else
      fail_test "Reconciliation method incorrect for medium confidence" "Expected 'hybrid', got '$method3'"
    fi
  else
    fail_test "Reconciliation JSON invalid for test case 3"
  fi
}

# Test: hybrid_complexity_evaluation threshold-only path
test_hybrid_evaluation_threshold_only() {
  local phase_name="Simple Phase"
  local task_list="- [ ] Task 1
- [ ] Task 2
- [ ] Task 3"
  local plan_file="$FIXTURES_DIR/test_plan_simple.md"

  if [ -f "$plan_file" ]; then
    local result
    result=$(hybrid_complexity_evaluation "$phase_name" "$task_list" "$plan_file")

    if echo "$result" | jq empty 2>/dev/null; then
      local eval_method
      eval_method=$(echo "$result" | jq -r '.evaluation_method')

      if [ "$eval_method" = "threshold" ]; then
        pass_test "Hybrid evaluation uses threshold-only for low complexity"
      else
        fail_test "Hybrid evaluation method incorrect" "Expected 'threshold', got '$eval_method'"
      fi
    else
      fail_test "Hybrid evaluation JSON invalid"
    fi
  else
    fail_test "Test fixture not found for hybrid evaluation"
  fi
}

# Test: Expansion accuracy with test fixtures
test_expansion_accuracy() {
  local complex_plan="$FIXTURES_DIR/test_plan_complex.md"

  if [ ! -f "$complex_plan" ]; then
    fail_test "Complex test fixture not found" "$complex_plan"
    return
  fi

  # Extract Phase 1 from complex plan
  local phase1_content
  phase1_content=$(sed -n '/^### Phase 1:/,/^### Phase 2:/p' "$complex_plan" | head -n -1)

  local phase1_name
  phase1_name=$(echo "$phase1_content" | grep "^### Phase 1:" | sed 's/^### Phase 1: //')

  local phase1_tasks
  phase1_tasks=$(echo "$phase1_content" | grep "^- \[ \]")

  local score
  score=$(calculate_phase_complexity "$phase1_name" "$phase1_tasks")

  # Phase 1 of complex plan should trigger expansion (score ≥8 or tasks >10)
  local task_count
  task_count=$(echo "$phase1_tasks" | wc -l)

  if [ "$score" -ge 8 ] || [ "$task_count" -gt 10 ]; then
    pass_test "Complex phase correctly identified for expansion (score=$score, tasks=$task_count)"
  else
    fail_test "Complex phase not identified for expansion" "score=$score, tasks=$task_count"
  fi
}

# Run all tests
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Complexity Estimator Test Suite"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

test_simple_phase_complexity
test_medium_phase_complexity
test_complex_phase_complexity
test_task_structure_json
test_complexity_triggers
test_complexity_report_json
test_complexity_level_mapping
test_analyze_plan_complexity
test_reconcile_scores
test_hybrid_evaluation_threshold_only
test_expansion_accuracy

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
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  exit 1
fi
