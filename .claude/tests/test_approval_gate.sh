#!/usr/bin/env bash
# Test suite for approval gate functionality
# Tests present_recommendations_for_approval and generate_recommendations_report functions

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
# Test Cases for present_recommendations_for_approval
# ============================================================================

# Test: present_recommendations_for_approval function exists
test_present_recommendations_for_approval_exists() {
  if declare -f present_recommendations_for_approval > /dev/null; then
    return 0
  else
    echo "Function present_recommendations_for_approval not found" >&2
    return 1
  fi
}

# Test: present_recommendations_for_approval requires arguments
test_present_recommendations_for_approval_args() {
  local output
  output=$(present_recommendations_for_approval "" 2>&1 || true)
  if echo "$output" | grep -q "requires recommendations_json"; then
    return 0
  else
    return 1
  fi
}

# Test: present_recommendations_for_approval handles empty recommendations
test_present_recommendations_for_approval_empty() {
  local recommendations='[]'

  # Run function (should return success for empty list)
  if present_recommendations_for_approval "$recommendations" "Test" 2>/dev/null; then
    return 0
  else
    return 1
  fi
}

# Test: present_recommendations_for_approval parses recommendations
test_present_recommendations_for_approval_parse() {
  local recommendations='[{"type":"expand","target":"phase_1","reasoning":"Test","confidence":"high"}]'

  # Since function requires user input, we test the parsing by checking if
  # it processes the JSON without errors (will fail on read, but that's expected)
  local output
  output=$(echo "n" | present_recommendations_for_approval "$recommendations" "Test" 2>&1 || true)

  # Should show the recommendation details in output
  if echo "$output" | grep -q "Action: expand"; then
    return 0
  else
    return 1
  fi
}

# ============================================================================
# Test Cases for generate_recommendations_report
# ============================================================================

# Test: generate_recommendations_report function exists
test_generate_recommendations_report_exists() {
  if declare -f generate_recommendations_report > /dev/null; then
    return 0
  else
    echo "Function generate_recommendations_report not found" >&2
    return 1
  fi
}

# Test: generate_recommendations_report requires plan_path argument
test_generate_recommendations_report_args() {
  local output
  output=$(generate_recommendations_report "" 2>&1 || true)
  if echo "$output" | grep -q "requires plan_path"; then
    return 0
  else
    return 1
  fi
}

# Test: generate_recommendations_report creates report file
test_generate_recommendations_report_creates_file() {
  local plan_path="/tmp/test_plan.md"

  # Create mock plan file
  echo "# Test Plan" > "$plan_path"

  # Run function
  local report_path
  report_path=$(generate_recommendations_report "$plan_path" "" "" "" 2>/dev/null || true)

  rm -f "$plan_path"

  # Check if report file was created
  if [[ -n "$report_path" ]] && [[ -f "$report_path" ]]; then
    rm -f "$report_path"
    return 0
  else
    return 1
  fi
}

# Test: generate_recommendations_report includes operations data
test_generate_recommendations_report_operations() {
  local plan_path="/tmp/test_plan.md"
  local operations='{"total":3,"successful":3,"failed":0}'

  # Create mock plan file
  echo "# Test Plan" > "$plan_path"

  # Run function
  local report_path
  report_path=$(generate_recommendations_report "$plan_path" "" "" "$operations" 2>/dev/null || true)

  rm -f "$plan_path"

  # Check if report contains operations data
  if [[ -f "$report_path" ]] && grep -q "Total Operations" "$report_path"; then
    rm -f "$report_path"
    return 0
  else
    [[ -f "$report_path" ]] && rm -f "$report_path"
    return 1
  fi
}

# Test: generate_recommendations_report includes hierarchy review
test_generate_recommendations_report_hierarchy() {
  local plan_path="/tmp/test_plan.md"
  local hierarchy='{"overall_assessment":"Test assessment","balance_score":8}'

  # Create mock plan file
  echo "# Test Plan" > "$plan_path"

  # Run function
  local report_path
  report_path=$(generate_recommendations_report "$plan_path" "$hierarchy" "" "" 2>/dev/null || true)

  rm -f "$plan_path"

  # Check if report contains hierarchy data
  if [[ -f "$report_path" ]] && grep -q "Balance Score" "$report_path"; then
    rm -f "$report_path"
    return 0
  else
    [[ -f "$report_path" ]] && rm -f "$report_path"
    return 1
  fi
}

# Test: generate_recommendations_report includes second-round analysis
test_generate_recommendations_report_second_round() {
  local plan_path="/tmp/test_plan.md"
  local second_round='{"current_level":"1","comparison_available":true}'

  # Create mock plan file
  echo "# Test Plan" > "$plan_path"

  # Run function
  local report_path
  report_path=$(generate_recommendations_report "$plan_path" "" "$second_round" "" 2>/dev/null || true)

  rm -f "$plan_path"

  # Check if report contains second-round data
  if [[ -f "$report_path" ]] && grep -q "Second-Round Analysis" "$report_path"; then
    rm -f "$report_path"
    return 0
  else
    [[ -f "$report_path" ]] && rm -f "$report_path"
    return 1
  fi
}

# ============================================================================
# Run All Tests
# ============================================================================

echo "Testing Approval Gate and Report Functions"
echo "==========================================="
echo ""

run_test "present_recommendations_for_approval exists" test_present_recommendations_for_approval_exists
run_test "present_recommendations_for_approval requires arguments" test_present_recommendations_for_approval_args
run_test "present_recommendations_for_approval handles empty recommendations" test_present_recommendations_for_approval_empty
run_test "present_recommendations_for_approval parses recommendations" test_present_recommendations_for_approval_parse
run_test "generate_recommendations_report exists" test_generate_recommendations_report_exists
run_test "generate_recommendations_report requires arguments" test_generate_recommendations_report_args
run_test "generate_recommendations_report creates report file" test_generate_recommendations_report_creates_file
run_test "generate_recommendations_report includes operations data" test_generate_recommendations_report_operations
run_test "generate_recommendations_report includes hierarchy review" test_generate_recommendations_report_hierarchy
run_test "generate_recommendations_report includes second-round analysis" test_generate_recommendations_report_second_round

# ============================================================================
# Print Results
# ============================================================================

echo ""
echo "==========================================="
echo "Test Results:"
echo "  Total: $TESTS_RUN"
echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
echo "==========================================="

if [[ $TESTS_FAILED -eq 0 ]]; then
  exit 0
else
  exit 1
fi
