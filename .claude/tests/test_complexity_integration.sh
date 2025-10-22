#!/usr/bin/env bash
#
# test_complexity_integration.sh - Integration tests for complexity evaluation system
#
# Purpose: Verify end-to-end functionality of calibrated complexity system
# Coverage: Analyzer, thresholds, correlation, performance
#
# Usage: ./test_complexity_integration.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Utilities
pass() {
  echo -e "${GREEN}✓${NC} $1"
  ((TESTS_PASSED++))
  ((TESTS_RUN++))
}

fail() {
  echo -e "${RED}✗${NC} $1"
  ((TESTS_FAILED++))
  ((TESTS_RUN++))
}

skip() {
  echo -e "${YELLOW}⊘${NC} $1 (skipped)"
}

section() {
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "$1"
  echo "═══════════════════════════════════════════════════════════"
}

# Test 1: Analyzer exists and is executable
test_analyzer_exists() {
  section "Test 1: Analyzer Availability"

  local analyzer="$PROJECT_ROOT/.claude/lib/analyze-phase-complexity.sh"

  if [ -f "$analyzer" ] && [ -x "$analyzer" ]; then
    pass "Analyzer script exists and is executable"
  else
    fail "Analyzer script not found or not executable: $analyzer"
  fi
}

# Test 2: Analyzer produces valid output
test_analyzer_basic_output() {
  section "Test 2: Analyzer Basic Output"

  local analyzer="$PROJECT_ROOT/.claude/lib/analyze-phase-complexity.sh"
  local test_content="
- [ ] Task 1 (file1.ts)
- [ ] Task 2 (file2.ts)
- [ ] Write tests
"

  local output=$("$analyzer" "Test Phase" "$test_content" 2>/dev/null || echo "ERROR")

  if echo "$output" | grep -q "COMPLEXITY_SCORE="; then
    local score=$(echo "$output" | grep -oE '[0-9]+\.[0-9]+')
    pass "Analyzer produces valid output (score: $score)"
  else
    fail "Analyzer output invalid: $output"
  fi
}

# Test 3: Calibrated normalization factor
test_calibrated_normalization() {
  section "Test 3: Calibrated Normalization Factor"

  local analyzer="$PROJECT_ROOT/.claude/lib/analyze-phase-complexity.sh"

  # Check if 411/1000 normalization is present
  if grep -q "411 / 1000" "$analyzer"; then
    pass "Calibrated normalization factor (0.411) is present"
  else
    fail "Calibrated normalization factor not found in analyzer"
  fi
}

# Test 4: Ground truth dataset exists
test_ground_truth_exists() {
  section "Test 4: Ground Truth Dataset"

  local ground_truth="$SCRIPT_DIR/fixtures/complexity/plan_080_ground_truth.yaml"

  if [ -f "$ground_truth" ]; then
    local phase_count=$(grep -c "phase_number:" "$ground_truth" || echo "0")
    if [ "$phase_count" -eq 8 ]; then
      pass "Ground truth dataset exists with 8 phases"
    else
      fail "Ground truth dataset has wrong phase count: $phase_count (expected 8)"
    fi
  else
    fail "Ground truth dataset not found: $ground_truth"
  fi
}

# Test 5: Calibration report exists
test_calibration_report_exists() {
  section "Test 5: Calibration Documentation"

  local report="$PROJECT_ROOT/.claude/docs/reference/complexity-calibration-report.md"

  if [ -f "$report" ]; then
    local line_count=$(wc -l < "$report")
    if [ "$line_count" -gt 500 ]; then
      pass "Calibration report exists ($line_count lines)"
    else
      fail "Calibration report too short: $line_count lines"
    fi
  else
    fail "Calibration report not found: $report"
  fi
}

# Test 6: Performance - single phase analysis
test_performance_single_phase() {
  section "Test 6: Performance - Single Phase"

  local analyzer="$PROJECT_ROOT/.claude/lib/analyze-phase-complexity.sh"
  local test_content="$(for i in {1..50}; do echo "- [ ] Task $i (file$i.ts)"; done)"

  local start_time=$(date +%s%N)
  "$analyzer" "Performance Test" "$test_content" >/dev/null 2>&1
  local end_time=$(date +%s%N)

  local duration_ms=$(( (end_time - start_time) / 1000000 ))

  if [ "$duration_ms" -lt 1000 ]; then
    pass "Single phase analysis completes in ${duration_ms}ms (<1s)"
  else
    fail "Single phase analysis too slow: ${duration_ms}ms (>1s)"
  fi
}

# Test 7: Correlation validation script exists
test_calibration_script_exists() {
  section "Test 7: Calibration Scripts"

  local calibration_script="$SCRIPT_DIR/test_complexity_calibration_v2.py"

  if [ -f "$calibration_script" ] && [ -x "$calibration_script" ]; then
    pass "Calibration validation script exists"
  else
    fail "Calibration validation script not found: $calibration_script"
  fi
}

# Test 8: Robust scaling utility exists
test_robust_scaling_exists() {
  section "Test 8: Robust Scaling Utility"

  local scaling_util="$PROJECT_ROOT/.claude/lib/robust-scaling.sh"

  if [ -f "$scaling_util" ] && [ -x "$scaling_util" ]; then
    pass "Robust scaling utility exists"

    # Test basic function
    if source "$scaling_util" && declare -f sigmoid_map >/dev/null; then
      pass "Robust scaling functions are available"
    else
      fail "Robust scaling functions not loadable"
    fi
  else
    fail "Robust scaling utility not found: $scaling_util"
  fi
}

# Test 9: Verify correlation improvement
test_correlation_improvement() {
  section "Test 9: Correlation Validation"

  local calibration_results="$PROJECT_ROOT/.claude/data/complexity_calibration/calibration_results.yaml"

  if [ -f "$calibration_results" ]; then
    local correlation=$(grep "best_correlation:" "$calibration_results" | grep -oE '[0-9]+\.[0-9]+' | head -1)

    if [ -n "$correlation" ]; then
      # Check if correlation >= 0.70 (substantial improvement)
      if awk -v c="$correlation" 'BEGIN {exit !(c >= 0.70)}'; then
        pass "Correlation is acceptable: $correlation (>= 0.70)"
      else
        fail "Correlation below acceptable threshold: $correlation (< 0.70)"
      fi
    else
      fail "Could not extract correlation from results"
    fi
  else
    skip "Calibration results file not found (run calibration first)"
  fi
}

# Test 10: Threshold loading from CLAUDE.md
test_threshold_loading() {
  section "Test 10: Threshold Configuration"

  local claude_md="$PROJECT_ROOT/CLAUDE.md"

  if [ -f "$claude_md" ]; then
    if grep -q "adaptive_planning_config" "$claude_md"; then
      pass "CLAUDE.md contains adaptive planning configuration"

      # Check for specific thresholds
      if grep -q "Expansion Threshold" "$claude_md"; then
        pass "Expansion threshold configured in CLAUDE.md"
      else
        fail "Expansion threshold not found in CLAUDE.md"
      fi
    else
      fail "Adaptive planning config section not found in CLAUDE.md"
    fi
  else
    fail "CLAUDE.md not found: $claude_md"
  fi
}

# Test 11: Edge case - empty phase
test_edge_case_empty_phase() {
  section "Test 11: Edge Case - Empty Phase"

  local analyzer="$PROJECT_ROOT/.claude/lib/analyze-phase-complexity.sh"

  local output=$("$analyzer" "Empty Phase" "" 2>/dev/null || echo "ERROR")

  if echo "$output" | grep -q "COMPLEXITY_SCORE="; then
    local score=$(echo "$output" | grep -oE '[0-9]+\.[0-9]+')
    pass "Handles empty phase (score: $score)"
  else
    fail "Fails on empty phase: $output"
  fi
}

# Test 12: Edge case - very complex phase
test_edge_case_complex_phase() {
  section "Test 12: Edge Case - Very Complex Phase"

  local analyzer="$PROJECT_ROOT/.claude/lib/analyze-phase-complexity.sh"
  local complex_content="depends_on: [phase_1, phase_2, phase_3]
$(for i in {1..100}; do echo "- [ ] Task $i (file$i.ts)"; done)
- [ ] Security audit
- [ ] Database migration
- [ ] API integration tests
- [ ] Coverage tests
"

  local output=$("$analyzer" "Complex Phase" "$complex_content" 2>/dev/null || echo "ERROR")

  if echo "$output" | grep -q "COMPLEXITY_SCORE="; then
    local score=$(echo "$output" | grep -oE '[0-9]+\.[0-9]+')
    # Should be capped at 15.0
    if awk -v s="$score" 'BEGIN {exit !(s <= 15.0)}'; then
      pass "Handles complex phase with proper capping (score: $score <= 15.0)"
    else
      fail "Score exceeds maximum: $score > 15.0"
    fi
  else
    fail "Fails on complex phase: $output"
  fi
}

# Main test execution
main() {
  echo "══════════════════════════════════════════════════════════════════"
  echo "  Complexity Evaluation System - Integration Tests"
  echo "══════════════════════════════════════════════════════════════════"
  echo "  Project: $(basename "$PROJECT_ROOT")"
  echo "  Date: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "══════════════════════════════════════════════════════════════════"

  # Run all tests
  test_analyzer_exists
  test_analyzer_basic_output
  test_calibrated_normalization
  test_ground_truth_exists
  test_calibration_report_exists
  test_performance_single_phase
  test_calibration_script_exists
  test_robust_scaling_exists
  test_correlation_improvement
  test_threshold_loading
  test_edge_case_empty_phase
  test_edge_case_complex_phase

  # Summary
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "  Test Summary"
  echo "═══════════════════════════════════════════════════════════"
  echo "  Total tests:  $TESTS_RUN"
  echo -e "  ${GREEN}Passed:       $TESTS_PASSED${NC}"
  echo -e "  ${RED}Failed:       $TESTS_FAILED${NC}"
  echo "═══════════════════════════════════════════════════════════"

  if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    return 0
  else
    echo -e "${RED}✗ Some tests failed${NC}"
    return 1
  fi
}

# Execute main function
main
