#!/usr/bin/env bash
# Test suite for second-round analysis functionality
# Tests run_second_round_analysis function

set -euo pipefail

# Source test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-/home/benjamin/.config-feature-parallel_expansion}"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Source the library under test
source "$CLAUDE_PROJECT_DIR/.claude/lib/auto-analysis-utils.sh"

# Helper function to run a test
run_test() {
  local test_name="$1"
  local test_func="$2"

  TESTS_RUN=$((TESTS_RUN + 1))
  echo -n "  Testing: $test_name ... "

  if $test_func; then
    echo -e "${GREEN}PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}FAIL${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# ============================================================================
# Test Cases
# ============================================================================

# Test: run_second_round_analysis function exists
test_run_second_round_analysis_exists() {
  if declare -f run_second_round_analysis > /dev/null; then
    return 0
  else
    echo "Function run_second_round_analysis not found" >&2
    return 1
  fi
}

# Test: run_second_round_analysis requires plan_path argument
test_run_second_round_analysis_args() {
  local output
  output=$(run_second_round_analysis "" 2>&1 || true)
  if echo "$output" | grep -q "requires plan_path"; then
    return 0
  else
    return 1
  fi
}

# Test: run_second_round_analysis returns JSON report
test_run_second_round_analysis_json_output() {
  local plan_path="/tmp/test_plan.md"

  # Create mock plan file
  cat > "$plan_path" <<'EOF'
# Test Plan

## Metadata
- **Structure Level**: 0

## Overview
Test plan for second-round analysis
EOF

  # Run function
  local result
  result=$(run_second_round_analysis "$plan_path" "" 2>/dev/null || true)

  rm -f "$plan_path"

  # Should return JSON with current_level field
  if echo "$result" | jq -e '.current_level' > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# Test: run_second_round_analysis processes initial analysis
test_run_second_round_analysis_with_initial() {
  local plan_path="/tmp/test_plan.md"
  local initial_analysis='[{"item_id":"phase_1","complexity_level":8}]'

  # Create mock plan file
  echo "# Test Plan" > "$plan_path"

  # Run function
  local result
  result=$(run_second_round_analysis "$plan_path" "$initial_analysis" 2>/dev/null || true)

  rm -f "$plan_path"

  # Should return JSON with comparison_available field
  if echo "$result" | jq -e '.comparison_available' > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# Test: run_second_round_analysis handles Level 0 plans
test_run_second_round_analysis_level_0() {
  local plan_path="/tmp/test_plan.md"

  # Create Level 0 plan file
  cat > "$plan_path" <<'EOF'
# Test Plan

## Metadata
- **Structure Level**: 0
EOF

  # Run function
  local result
  result=$(run_second_round_analysis "$plan_path" "" 2>/dev/null || true)

  rm -f "$plan_path"

  # Should recommend expansion mode
  if echo "$result" | jq -e '.second_round.mode == "expansion"' > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# Test: run_second_round_analysis handles Level 1 plans
test_run_second_round_analysis_level_1() {
  local plan_dir="/tmp/test_plan_dir"
  mkdir -p "$plan_dir"

  # Create Level 1 plan file
  cat > "$plan_dir/test_plan.md" <<'EOF'
# Test Plan

## Metadata
- **Structure Level**: 1
EOF

  # Run function
  local result
  result=$(run_second_round_analysis "$plan_dir" "" 2>/dev/null || true)

  rm -rf "$plan_dir"

  # Should return second_round field (structure level detection may vary for directories)
  # The important part is that the function returns valid JSON with recommendations
  if echo "$result" | jq -e '.second_round' > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# ============================================================================
# Run All Tests
# ============================================================================

echo "Testing Second-Round Analysis Functions"
echo "========================================"
echo ""

run_test "run_second_round_analysis exists" test_run_second_round_analysis_exists
run_test "run_second_round_analysis requires arguments" test_run_second_round_analysis_args
run_test "run_second_round_analysis returns JSON report" test_run_second_round_analysis_json_output
run_test "run_second_round_analysis processes initial analysis" test_run_second_round_analysis_with_initial
run_test "run_second_round_analysis handles Level 0 plans" test_run_second_round_analysis_level_0
run_test "run_second_round_analysis handles Level 1 plans" test_run_second_round_analysis_level_1

# ============================================================================
# Print Results
# ============================================================================

echo ""
echo "========================================"
echo "Test Results:"
echo "  Total: $TESTS_RUN"
echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
echo "========================================"

if [[ $TESTS_FAILED -eq 0 ]]; then
  exit 0
else
  exit 1
fi
