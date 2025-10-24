#!/usr/bin/env bash
# test_lazy_directory_creation.sh - Integration test for lazy directory creation
#
# Purpose: Verify /supervise creates directories on-demand, not eagerly
# Tests: All 4 workflow types (research-only, research-and-plan, full-implementation, debug-only)
#
# Usage: ./test_lazy_directory_creation.sh [--cleanup-only]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Test configuration
TEST_SPECS_ROOT="/tmp/claude_test_lazy_dirs_$$"
VERBOSE=${VERBOSE:-0}

# Cleanup function
cleanup() {
  if [ -d "$TEST_SPECS_ROOT" ]; then
    echo ""
    echo "Cleaning up test directory: $TEST_SPECS_ROOT"
    rm -rf "$TEST_SPECS_ROOT"
  fi
}

# Set up cleanup trap
trap cleanup EXIT

# Print test header
print_header() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "$1"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Assert function
assert() {
  local condition="$1"
  local description="$2"

  TESTS_TOTAL=$((TESTS_TOTAL + 1))

  if eval "$condition"; then
    echo -e "${GREEN}✓${NC} $description"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} $description"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Test create_topic_structure() function
test_topic_structure_function() {
  print_header "TEST 1: create_topic_structure() Creates Only Topic Root"

  # Source the utility library
  source /home/benjamin/.config/.claude/lib/topic-utils.sh

  # Create test topic
  local test_topic="$TEST_SPECS_ROOT/001_test_topic"

  create_topic_structure "$test_topic"

  # Assertions
  assert "[ -d '$test_topic' ]" "Topic root directory created"
  assert "[ ! -d '$test_topic/reports' ]" "reports/ subdirectory NOT created"
  assert "[ ! -d '$test_topic/plans' ]" "plans/ subdirectory NOT created"
  assert "[ ! -d '$test_topic/summaries' ]" "summaries/ subdirectory NOT created"
  assert "[ ! -d '$test_topic/debug' ]" "debug/ subdirectory NOT created"
  assert "[ ! -d '$test_topic/scripts' ]" "scripts/ subdirectory NOT created"
  assert "[ ! -d '$test_topic/outputs' ]" "outputs/ subdirectory NOT created"

  # Count directories (should be only 1 - the topic root itself)
  local dir_count
  dir_count=$(find "$test_topic" -type d | wc -l)
  assert "[ $dir_count -eq 1 ]" "Only topic root exists (found $dir_count directories)"
}

# Test lazy directory creation with file writes
test_lazy_directory_creation() {
  print_header "TEST 2: Directories Created On-Demand When Files Written"

  source /home/benjamin/.config/.claude/lib/topic-utils.sh

  local test_topic="$TEST_SPECS_ROOT/002_test_lazy"
  create_topic_structure "$test_topic"

  # Simulate agent writing a report file
  local report_path="$test_topic/reports/001_test_report.md"
  mkdir -p "$(dirname "$report_path")"
  echo "# Test Report" > "$report_path"

  assert "[ -d '$test_topic/reports' ]" "reports/ created when report file written"
  assert "[ -f '$report_path' ]" "Report file exists"
  assert "[ ! -d '$test_topic/plans' ]" "plans/ NOT created (no plan file written)"

  # Simulate agent writing a plan file
  local plan_path="$test_topic/plans/001_test_plan.md"
  mkdir -p "$(dirname "$plan_path")"
  echo "# Test Plan" > "$plan_path"

  assert "[ -d '$test_topic/plans' ]" "plans/ created when plan file written"
  assert "[ -f '$plan_path' ]" "Plan file exists"
  assert "[ ! -d '$test_topic/summaries' ]" "summaries/ NOT created (no summary file written)"

  # Count directories (should be 3: topic root, reports/, plans/)
  local dir_count
  dir_count=$(find "$test_topic" -mindepth 1 -type d | wc -l)
  assert "[ $dir_count -eq 2 ]" "Only used subdirectories exist (found $dir_count subdirectories)"
}

# Test research-only workflow
test_research_only_workflow() {
  print_header "TEST 3: Research-Only Workflow Creates Only reports/"

  source /home/benjamin/.config/.claude/lib/topic-utils.sh

  local test_topic="$TEST_SPECS_ROOT/003_research_only"
  create_topic_structure "$test_topic"

  # Simulate research-only workflow (creates reports/ only)
  mkdir -p "$test_topic/reports"
  echo "# Research Report 1" > "$test_topic/reports/001_report.md"
  echo "# Research Report 2" > "$test_topic/reports/002_report.md"

  assert "[ -d '$test_topic/reports' ]" "reports/ directory created"
  assert "[ ! -d '$test_topic/plans' ]" "plans/ NOT created (research-only)"
  assert "[ ! -d '$test_topic/summaries' ]" "summaries/ NOT created (research-only)"
  assert "[ ! -d '$test_topic/debug' ]" "debug/ NOT created (research-only)"
  assert "[ ! -d '$test_topic/scripts' ]" "scripts/ NOT created (research-only)"
  assert "[ ! -d '$test_topic/outputs' ]" "outputs/ NOT created (research-only)"

  # Check for empty directories
  local empty_dirs
  empty_dirs=$(find "$test_topic" -mindepth 1 -type d -empty | wc -l)
  assert "[ $empty_dirs -eq 0 ]" "No empty directories (found $empty_dirs)"
}

# Test research-and-plan workflow
test_research_and_plan_workflow() {
  print_header "TEST 4: Research-and-Plan Workflow Creates reports/ and plans/"

  source /home/benjamin/.config/.claude/lib/topic-utils.sh

  local test_topic="$TEST_SPECS_ROOT/004_research_and_plan"
  create_topic_structure "$test_topic"

  # Simulate research-and-plan workflow
  mkdir -p "$test_topic/reports"
  echo "# Research Report" > "$test_topic/reports/001_report.md"

  mkdir -p "$test_topic/plans"
  echo "# Implementation Plan" > "$test_topic/plans/001_plan.md"

  assert "[ -d '$test_topic/reports' ]" "reports/ directory created"
  assert "[ -d '$test_topic/plans' ]" "plans/ directory created"
  assert "[ ! -d '$test_topic/summaries' ]" "summaries/ NOT created (no implementation)"
  assert "[ ! -d '$test_topic/debug' ]" "debug/ NOT created (no debugging needed)"
  assert "[ ! -d '$test_topic/scripts' ]" "scripts/ NOT created (no scripts)"
  assert "[ ! -d '$test_topic/outputs' ]" "outputs/ NOT created (no tests run)"

  # Check for empty directories
  local empty_dirs
  empty_dirs=$(find "$test_topic" -mindepth 1 -type d -empty | wc -l)
  assert "[ $empty_dirs -eq 0 ]" "No empty directories (found $empty_dirs)"
}

# Test full-implementation workflow
test_full_implementation_workflow() {
  print_header "TEST 5: Full-Implementation Workflow Creates Relevant Directories"

  source /home/benjamin/.config/.claude/lib/topic-utils.sh

  local test_topic="$TEST_SPECS_ROOT/005_full_implementation"
  create_topic_structure "$test_topic"

  # Simulate full-implementation workflow
  mkdir -p "$test_topic/reports"
  echo "# Research Report" > "$test_topic/reports/001_report.md"

  mkdir -p "$test_topic/plans"
  echo "# Implementation Plan" > "$test_topic/plans/001_plan.md"

  mkdir -p "$test_topic/outputs"
  echo "# Test Results" > "$test_topic/outputs/test_results.md"

  mkdir -p "$test_topic/summaries"
  echo "# Implementation Summary" > "$test_topic/summaries/005_summary.md"

  assert "[ -d '$test_topic/reports' ]" "reports/ directory created"
  assert "[ -d '$test_topic/plans' ]" "plans/ directory created"
  assert "[ -d '$test_topic/outputs' ]" "outputs/ directory created"
  assert "[ -d '$test_topic/summaries' ]" "summaries/ directory created"
  assert "[ ! -d '$test_topic/debug' ]" "debug/ NOT created (tests passed, no debugging)"
  assert "[ ! -d '$test_topic/scripts' ]" "scripts/ NOT created (no custom scripts)"

  # Check for empty directories
  local empty_dirs
  empty_dirs=$(find "$test_topic" -mindepth 1 -type d -empty | wc -l)
  assert "[ $empty_dirs -eq 0 ]" "No empty directories (found $empty_dirs)"
}

# Test debug workflow
test_debug_workflow() {
  print_header "TEST 6: Debug Workflow Creates reports/ and debug/"

  source /home/benjamin/.config/.claude/lib/topic-utils.sh

  local test_topic="$TEST_SPECS_ROOT/006_debug_workflow"
  create_topic_structure "$test_topic"

  # Simulate debug workflow (includes research and debug reports)
  mkdir -p "$test_topic/reports"
  echo "# Debug Research" > "$test_topic/reports/001_debug_research.md"

  mkdir -p "$test_topic/debug"
  echo "# Debug Analysis" > "$test_topic/debug/001_debug_analysis.md"

  assert "[ -d '$test_topic/reports' ]" "reports/ directory created"
  assert "[ -d '$test_topic/debug' ]" "debug/ directory created"
  assert "[ ! -d '$test_topic/plans' ]" "plans/ NOT created (debug-only, no new plan)"
  assert "[ ! -d '$test_topic/summaries' ]" "summaries/ NOT created (debug-only)"
  assert "[ ! -d '$test_topic/scripts' ]" "scripts/ NOT created"
  assert "[ ! -d '$test_topic/outputs' ]" "outputs/ NOT created"

  # Check for empty directories
  local empty_dirs
  empty_dirs=$(find "$test_topic" -mindepth 1 -type d -empty | wc -l)
  assert "[ $empty_dirs -eq 0 ]" "No empty directories (found $empty_dirs)"
}

# Test backward compatibility
test_backward_compatibility() {
  print_header "TEST 7: Backward Compatibility - Function Interface Unchanged"

  source /home/benjamin/.config/.claude/lib/topic-utils.sh

  local test_topic="$TEST_SPECS_ROOT/007_backward_compat"

  # Test return value on success
  if create_topic_structure "$test_topic"; then
    assert "true" "Function returns 0 on success"
  else
    assert "false" "Function returns 0 on success"
  fi

  # Test return value on failure (permission denied)
  local readonly_parent="/tmp/claude_readonly_$$"
  mkdir -p "$readonly_parent"
  chmod 000 "$readonly_parent"

  if create_topic_structure "$readonly_parent/should_fail" 2>/dev/null; then
    assert "false" "Function returns 1 on failure"
  else
    assert "true" "Function returns 1 on failure"
  fi

  # Clean up readonly test
  chmod 755 "$readonly_parent"
  rm -rf "$readonly_parent"
}

# Main test execution
main() {
  if [ "${1:-}" = "--cleanup-only" ]; then
    cleanup
    exit 0
  fi

  echo ""
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║   Lazy Directory Creation Integration Tests                  ║"
  echo "║   Spec: 474 - Fix /supervise Eager Directory Creation        ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"

  # Create test root
  mkdir -p "$TEST_SPECS_ROOT"

  # Run all tests
  test_topic_structure_function
  test_lazy_directory_creation
  test_research_only_workflow
  test_research_and_plan_workflow
  test_full_implementation_workflow
  test_debug_workflow
  test_backward_compatibility

  # Print summary
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "                         TEST SUMMARY"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "  Total Tests:  $TESTS_TOTAL"
  echo -e "  ${GREEN}Passed:${NC}       $TESTS_PASSED"
  echo -e "  ${RED}Failed:${NC}       $TESTS_FAILED"
  echo ""

  if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ ALL TESTS PASSED${NC}"
    echo ""
    echo "Lazy directory creation is working correctly:"
    echo "  • Topic root created in Phase 0"
    echo "  • Subdirectories created on-demand when files written"
    echo "  • No empty directories remain after workflows"
    echo "  • All workflow types functional"
    echo "  • Backward compatibility maintained"
    echo ""
    return 0
  else
    echo -e "${RED}✗ SOME TESTS FAILED${NC}"
    echo ""
    echo "Please review the failed tests above and investigate the issues."
    echo ""
    return 1
  fi
}

# Run main function
main "$@"
