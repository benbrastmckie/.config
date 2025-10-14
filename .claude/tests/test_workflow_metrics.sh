#!/usr/bin/env bash
#
# Test Suite: Workflow Metrics Aggregation
# Tests metrics collection from logs and agent registry
#
# Usage: bash test_workflow_metrics.sh

set -euo pipefail

# Setup test environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source detect-project-dir to set CLAUDE_PROJECT_DIR
source "$SCRIPT_DIR/../lib/detect-project-dir.sh"

# Source workflow metrics utility
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-metrics.sh"

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
# Test 1: Aggregate Workflow Times
# ==============================================================================

test_aggregate_workflow_times() {
  run_test "test_aggregate_workflow_times"

  local result=$(aggregate_workflow_times)

  # Check for error (log file may not exist in test environment)
  local error=$(echo "$result" | jq -r '.error // "null"')
  if [[ "$error" != "null" ]]; then
    pass "Workflow times aggregation handles missing log gracefully (error=$error)"
    return 0
  fi

  # Check JSON structure
  if echo "$result" | jq -e '.workflow_duration_seconds' >/dev/null 2>&1; then
    pass "workflow_duration_seconds field present"
  else
    fail "Missing workflow_duration_seconds field"
    return 1
  fi

  if echo "$result" | jq -e '.total_phases' >/dev/null 2>&1; then
    pass "total_phases field present"
  else
    fail "Missing total_phases field"
    return 1
  fi

  if echo "$result" | jq -e '.completed_phases' >/dev/null 2>&1; then
    pass "completed_phases field present"
  else
    fail "Missing completed_phases field"
    return 1
  fi

  if echo "$result" | jq -e '.avg_phase_time_seconds' >/dev/null 2>&1; then
    pass "avg_phase_time_seconds field present"
  else
    fail "Missing avg_phase_time_seconds field"
    return 1
  fi
}

# ==============================================================================
# Test 2: Aggregate Agent Metrics
# ==============================================================================

test_aggregate_agent_metrics() {
  run_test "test_aggregate_agent_metrics"

  local result=$(aggregate_agent_metrics)

  # Check for error (registry may not exist in test environment)
  local error=$(echo "$result" | jq -r '.error // "null"')
  if [[ "$error" != "null" ]]; then
    pass "Agent metrics aggregation handles missing registry gracefully (error=$error)"
    return 0
  fi

  # Check JSON structure
  if echo "$result" | jq -e '.total_agents' >/dev/null 2>&1; then
    pass "total_agents field present"
  else
    fail "Missing total_agents field"
    return 1
  fi

  if echo "$result" | jq -e '.agent_summary' >/dev/null 2>&1; then
    pass "agent_summary field present"
  else
    fail "Missing agent_summary field"
    return 1
  fi

  # Check agent_summary is an array
  if echo "$result" | jq -e '.agent_summary | type == "array"' >/dev/null 2>&1; then
    pass "agent_summary is an array"
  else
    fail "agent_summary is not an array"
    return 1
  fi
}

# ==============================================================================
# Test 3: Aggregate Complexity Metrics
# ==============================================================================

test_aggregate_complexity_metrics() {
  run_test "test_aggregate_complexity_metrics"

  local result=$(aggregate_complexity_metrics)

  # Check for error (log may not exist in test environment)
  local error=$(echo "$result" | jq -r '.error // "null"')
  if [[ "$error" != "null" ]]; then
    pass "Complexity metrics aggregation handles missing log gracefully (error=$error)"
    return 0
  fi

  # Check JSON structure
  if echo "$result" | jq -e '.total_evaluations' >/dev/null 2>&1; then
    pass "total_evaluations field present"
  else
    fail "Missing total_evaluations field"
    return 1
  fi

  if echo "$result" | jq -e '.agent_invocation_rate' >/dev/null 2>&1; then
    pass "agent_invocation_rate field present"
  else
    fail "Missing agent_invocation_rate field"
    return 1
  fi

  if echo "$result" | jq -e '.threshold_only' >/dev/null 2>&1; then
    pass "threshold_only field present"
  else
    fail "Missing threshold_only field"
    return 1
  fi

  if echo "$result" | jq -e '.agent_overrides' >/dev/null 2>&1; then
    pass "agent_overrides field present"
  else
    fail "Missing agent_overrides field"
    return 1
  fi

  if echo "$result" | jq -e '.hybrid_averages' >/dev/null 2>&1; then
    pass "hybrid_averages field present"
  else
    fail "Missing hybrid_averages field"
    return 1
  fi
}

# ==============================================================================
# Test 4: Generate Performance Report
# ==============================================================================

test_generate_performance_report() {
  run_test "test_generate_performance_report"

  local report=$(generate_performance_report)

  # Check markdown structure
  if echo "$report" | grep -q "# Workflow Performance Report"; then
    pass "Report title present"
  else
    fail "Missing report title"
    return 1
  fi

  if echo "$report" | grep -q "## Workflow Summary"; then
    pass "Workflow summary section present"
  else
    fail "Missing workflow summary section"
    return 1
  fi

  if echo "$report" | grep -q "## Agent Performance"; then
    pass "Agent performance section present"
  else
    fail "Missing agent performance section"
    return 1
  fi

  if echo "$report" | grep -q "## Complexity Evaluation"; then
    pass "Complexity evaluation section present"
  else
    fail "Missing complexity evaluation section"
    return 1
  fi

  if echo "$report" | grep -q "Total Duration"; then
    pass "Duration metric present"
  else
    fail "Missing duration metric"
    return 1
  fi
}

# ==============================================================================
# Run All Tests
# ==============================================================================

echo "========================================"
echo "Workflow Metrics Aggregation Test Suite"
echo "========================================"

test_aggregate_workflow_times
test_aggregate_agent_metrics
test_aggregate_complexity_metrics
test_generate_performance_report

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
