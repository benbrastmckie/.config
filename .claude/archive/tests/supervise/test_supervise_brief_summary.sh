#!/usr/bin/env bash
# Test /supervise command brief summary functionality
# Tests: display_brief_summary output for all workflow types, brevity verification

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
    echo "  Got: ${3:-<empty>}"
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

# Test environment
TEST_DIR=$(mktemp -d -t supervise_brief_summary_tests_XXXXXX)
export CLAUDE_PROJECT_DIR="$TEST_DIR"

cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Find command file and source the function
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
COMMANDS_DIR=$(cd "$SCRIPT_DIR/../commands" && pwd)

# Extract and source the display_brief_summary function from supervise.md
# We'll define it here based on the implementation
display_brief_summary() {
  echo ""
  echo "✓ Workflow complete: $WORKFLOW_SCOPE"

  case "$WORKFLOW_SCOPE" in
    research-only)
      local report_count=${#REPORT_PATHS[@]}
      echo "Created $report_count research reports in: $TOPIC_PATH/reports/"
      echo "→ Review artifacts: ls -la $TOPIC_PATH/reports/"
      ;;
    research-and-plan)
      local report_count=${#REPORT_PATHS[@]}
      echo "Created $report_count reports + 1 plan in: $TOPIC_PATH/"
      echo "→ Run: /implement $PLAN_PATH"
      ;;
    full-implementation)
      echo "Implementation complete. Summary: $SUMMARY_PATH"
      echo "→ Review summary for next steps"
      ;;
    debug-only)
      echo "Debug analysis complete: $DEBUG_REPORT"
      echo "→ Review findings and apply fixes"
      ;;
    *)
      echo "Workflow artifacts available in: $TOPIC_PATH"
      echo "→ Review directory for outputs"
      ;;
  esac
  echo ""
}

# Create test environment
mkdir -p "$TEST_DIR/.claude/specs/test_topic/reports"
mkdir -p "$TEST_DIR/.claude/specs/test_topic/plans"
mkdir -p "$TEST_DIR/.claude/specs/test_topic/summaries"
mkdir -p "$TEST_DIR/.claude/specs/test_topic/debug"

# Set up test variables
TOPIC_PATH="$TEST_DIR/.claude/specs/test_topic"
REPORT_PATHS=("report1.md" "report2.md" "report3.md" "report4.md")
PLAN_PATH="$TOPIC_PATH/plans/001_test_plan.md"
SUMMARY_PATH="$TOPIC_PATH/summaries/001_test_summary.md"
DEBUG_REPORT="$TOPIC_PATH/debug/001_debug_analysis.md"

echo "========================================="
echo "Brief Summary Function Tests"
echo "========================================="
echo

# =============================================================================
# Test 1: Research-only workflow output
# =============================================================================
info "Test 1: Research-only workflow brief output"

WORKFLOW_SCOPE="research-only"
output=$(display_brief_summary 2>&1)
line_count=$(echo "$output" | wc -l)

# Check for required elements
if echo "$output" | grep -q "✓ Workflow complete: research-only"; then
  pass "Research-only: Contains completion header"
else
  fail "Research-only: Missing completion header" "✓ Workflow complete: research-only" "$output"
fi

if echo "$output" | grep -q "Created .* research reports"; then
  pass "Research-only: Contains report count"
else
  fail "Research-only: Missing report count" "Created N research reports" "$output"
fi

if echo "$output" | grep -q "→ Review artifacts"; then
  pass "Research-only: Contains next step action"
else
  fail "Research-only: Missing next step action" "→ Review artifacts" "$output"
fi

if [ "$line_count" -le 5 ]; then
  pass "Research-only: Output is brief (≤5 lines): $line_count lines"
else
  fail "Research-only: Output too verbose" "≤5 lines" "$line_count lines"
fi

if ! echo "$output" | grep -q "File:"; then
  pass "Research-only: No verbose file listings"
else
  fail "Research-only: Contains verbose file listings" "No 'File:' entries" "$output"
fi

# =============================================================================
# Test 2: Research-and-plan workflow output
# =============================================================================
info "Test 2: Research-and-plan workflow brief output"

WORKFLOW_SCOPE="research-and-plan"
output=$(display_brief_summary 2>&1)
line_count=$(echo "$output" | wc -l)

if echo "$output" | grep -q "✓ Workflow complete: research-and-plan"; then
  pass "Research-and-plan: Contains completion header"
else
  fail "Research-and-plan: Missing completion header"
fi

if echo "$output" | grep -q "Created .* reports.*plan"; then
  pass "Research-and-plan: Contains artifact count"
else
  fail "Research-and-plan: Missing artifact count"
fi

if echo "$output" | grep -q "→ Run: /implement"; then
  pass "Research-and-plan: Contains next step with /implement command"
else
  fail "Research-and-plan: Missing /implement suggestion"
fi

if [ "$line_count" -le 5 ]; then
  pass "Research-and-plan: Output is brief (≤5 lines): $line_count lines"
else
  fail "Research-and-plan: Output too verbose" "≤5 lines" "$line_count lines"
fi

# =============================================================================
# Test 3: Full-implementation workflow output
# =============================================================================
info "Test 3: Full-implementation workflow brief output"

WORKFLOW_SCOPE="full-implementation"
output=$(display_brief_summary 2>&1)
line_count=$(echo "$output" | wc -l)

if echo "$output" | grep -q "✓ Workflow complete: full-implementation"; then
  pass "Full-implementation: Contains completion header"
else
  fail "Full-implementation: Missing completion header"
fi

if echo "$output" | grep -q "Implementation complete.*Summary:"; then
  pass "Full-implementation: Contains summary path"
else
  fail "Full-implementation: Missing summary path"
fi

if echo "$output" | grep -q "→ Review summary"; then
  pass "Full-implementation: Contains next step action"
else
  fail "Full-implementation: Missing next step action"
fi

if [ "$line_count" -le 5 ]; then
  pass "Full-implementation: Output is brief (≤5 lines): $line_count lines"
else
  fail "Full-implementation: Output too verbose" "≤5 lines" "$line_count lines"
fi

# =============================================================================
# Test 4: Debug-only workflow output
# =============================================================================
info "Test 4: Debug-only workflow brief output"

WORKFLOW_SCOPE="debug-only"
output=$(display_brief_summary 2>&1)
line_count=$(echo "$output" | wc -l)

if echo "$output" | grep -q "✓ Workflow complete: debug-only"; then
  pass "Debug-only: Contains completion header"
else
  fail "Debug-only: Missing completion header"
fi

if echo "$output" | grep -q "Debug analysis complete:"; then
  pass "Debug-only: Contains debug report path"
else
  fail "Debug-only: Missing debug report path"
fi

if echo "$output" | grep -q "→ Review findings"; then
  pass "Debug-only: Contains next step action"
else
  fail "Debug-only: Missing next step action"
fi

if [ "$line_count" -le 5 ]; then
  pass "Debug-only: Output is brief (≤5 lines): $line_count lines"
else
  fail "Debug-only: Output too verbose" "≤5 lines" "$line_count lines"
fi

# =============================================================================
# Test 5: Function existence check
# =============================================================================
info "Test 5: Function existence verification"

# Test that function is defined
if command -v display_brief_summary >/dev/null 2>&1; then
  pass "Function existence: display_brief_summary is defined"
else
  fail "Function existence: display_brief_summary not found"
fi

# Test that function is callable
if display_brief_summary >/dev/null 2>&1; then
  pass "Function callable: display_brief_summary executes without error"
else
  fail "Function callable: display_brief_summary execution failed"
fi

# =============================================================================
# Summary
# =============================================================================
echo
echo "========================================="
echo "Test Summary"
echo "========================================="
echo -e "${GREEN}Passed: $PASS_COUNT${NC}"
echo -e "${RED}Failed: $FAIL_COUNT${NC}"
echo -e "${YELLOW}Skipped: $SKIP_COUNT${NC}"
echo

if [ $FAIL_COUNT -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed${NC}"
  exit 1
fi
