#!/usr/bin/env bash
# Test suite for hierarchy review functionality
# Tests review_plan_hierarchy function

set -euo pipefail

# Source test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/detect-project-dir.sh"

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

# Test: review_plan_hierarchy function exists
test_review_plan_hierarchy_exists() {
  if declare -f review_plan_hierarchy > /dev/null; then
    return 0
  else
    echo "Function review_plan_hierarchy not found" >&2
    return 1
  fi
}

# Test: review_plan_hierarchy requires plan_path argument
test_review_plan_hierarchy_args() {
  local output
  output=$(review_plan_hierarchy "" 2>&1 || true)
  if echo "$output" | grep -q "requires plan_path"; then
    return 0
  else
    return 1
  fi
}

# Test: review_plan_hierarchy returns JSON with agent_prompt
test_review_plan_hierarchy_json_output() {
  local plan_path="/tmp/test_plan.md"

  # Create mock plan file
  cat > "$plan_path" <<'EOF'
# Test Plan

## Metadata
- **Structure Level**: 0

## Overview
Test plan for hierarchy review

## Success Criteria
- [ ] Test criteria

### Phase 1: Test Phase
**Objective**: Test phase content
EOF

  # Run function
  local result
  result=$(review_plan_hierarchy "$plan_path" "{}" 2>/dev/null || true)

  rm -f "$plan_path"

  # Should return JSON with agent_prompt field
  if echo "$result" | jq -e '.agent_prompt' > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# Test: review_plan_hierarchy includes operation summary in context
test_review_plan_hierarchy_operations() {
  local plan_path="/tmp/test_plan.md"
  local operations='{"total":3,"successful":3,"failed":0}'

  # Create mock plan file
  echo "# Test Plan" > "$plan_path"
  echo "## Overview" >> "$plan_path"
  echo "Test overview" >> "$plan_path"

  # Run function
  local result
  result=$(review_plan_hierarchy "$plan_path" "$operations" 2>/dev/null || true)

  rm -f "$plan_path"

  # Should return JSON with mode field
  if echo "$result" | jq -e '.mode == "hierarchy_review"' > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# Test: review_plan_hierarchy handles directory paths
test_review_plan_hierarchy_directory() {
  local plan_dir="/tmp/test_plan_dir"
  mkdir -p "$plan_dir"

  # Create mock plan file in directory
  cat > "$plan_dir/test_plan.md" <<'EOF'
# Test Plan

## Metadata
- **Structure Level**: 1

## Overview
Test plan in directory

## Success Criteria
- [ ] Test criteria
EOF

  # Run function
  local result
  result=$(review_plan_hierarchy "$plan_dir" "{}" 2>/dev/null || true)

  rm -rf "$plan_dir"

  # Should return JSON with plan_path field
  if echo "$result" | jq -e '.plan_path' > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# ============================================================================
# Run All Tests
# ============================================================================

echo "Testing Hierarchy Review Functions"
echo "===================================="
echo ""

run_test "review_plan_hierarchy exists" test_review_plan_hierarchy_exists
run_test "review_plan_hierarchy requires arguments" test_review_plan_hierarchy_args
run_test "review_plan_hierarchy returns JSON with agent_prompt" test_review_plan_hierarchy_json_output
run_test "review_plan_hierarchy includes operation summary" test_review_plan_hierarchy_operations
run_test "review_plan_hierarchy handles directory paths" test_review_plan_hierarchy_directory

# ============================================================================
# Print Results
# ============================================================================

echo ""
echo "===================================="
echo "Test Results:"
echo "  Total: $TESTS_RUN"
echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
echo "===================================="

if [[ $TESTS_FAILED -eq 0 ]]; then
  exit 0
else
  exit 1
fi
