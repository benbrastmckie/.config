#!/usr/bin/env bash
# Test suite for parallel expansion functionality
# Tests invoke_expansion_agents_parallel, aggregate_expansion_artifacts, coordinate_metadata_updates

set -euo pipefail

# Source test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect project root using git or walk-up pattern
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  CLAUDE_PROJECT_DIR="$SCRIPT_DIR"
  while [ "$CLAUDE_PROJECT_DIR" != "/" ]; do
    if [ -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
      break
    fi
    CLAUDE_PROJECT_DIR="$(dirname "$CLAUDE_PROJECT_DIR")"
  done
fi
CLAUDE_LIB="${CLAUDE_PROJECT_DIR}/.claude/lib"
source "$CLAUDE_LIB/core/detect-project-dir.sh"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Source the library under test
source "$CLAUDE_PROJECT_DIR/.claude/lib/plan/auto-analysis-utils.sh"

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

# Test: invoke_expansion_agents_parallel function exists
test_invoke_expansion_agents_parallel_exists() {
  if declare -f invoke_expansion_agents_parallel > /dev/null; then
    return 0
  else
    echo "Function invoke_expansion_agents_parallel not found" >&2
    return 1
  fi
}

# Test: invoke_expansion_agents_parallel requires arguments
test_invoke_expansion_agents_parallel_args() {
  local output
  output=$(invoke_expansion_agents_parallel "" "" 2>&1 || true)
  if echo "$output" | grep -q "requires plan_path"; then
    return 0
  else
    return 1
  fi
}

# Test: invoke_expansion_agents_parallel accepts valid JSON
test_invoke_expansion_agents_parallel_json() {
  local plan_path="/tmp/test_plan.md"
  local recommendations='[{"item_id":"phase_1","recommendation":"expand","complexity_level":8}]'

  # Create mock plan file with proper structure
  mkdir -p "$(dirname "$plan_path")"
  cat > "$plan_path" <<'EOF'
# Test Plan

## Metadata
- **Structure Level**: 0

## Overview
Test plan for parallel expansion

### Phase 1: Test Phase
**Objective**: Test phase content
EOF

  # Redirect stderr to /dev/null to capture only stdout (the JSON output)
  local result
  result=$(invoke_expansion_agents_parallel "$plan_path" "$recommendations" 2>/dev/null || true)

  rm -f "$plan_path"

  # Should return JSON array
  if echo "$result" | jq -e 'type == "array"' >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# Test: aggregate_expansion_artifacts function exists
test_aggregate_expansion_artifacts_exists() {
  if declare -f aggregate_expansion_artifacts > /dev/null; then
    return 0
  else
    echo "Function aggregate_expansion_artifacts not found" >&2
    return 1
  fi
}

# Test: aggregate_expansion_artifacts requires arguments
test_aggregate_expansion_artifacts_args() {
  local output
  output=$(aggregate_expansion_artifacts "" "" 2>&1 || true)
  if echo "$output" | grep -q "requires plan_path"; then
    return 0
  else
    return 1
  fi
}

# Test: aggregate_expansion_artifacts validates artifacts
test_aggregate_expansion_artifacts_validation() {
  local plan_path="/tmp/test_plan.md"
  local artifact_refs='[{"item_id":"phase_1","artifact_path":"specs/artifacts/test_plan/expansion_1.md"}]'

  # Create mock plan file
  echo "# Test Plan" > "$plan_path"

  # Redirect stderr to /dev/null to capture only JSON output
  local result
  result=$(aggregate_expansion_artifacts "$plan_path" "$artifact_refs" 2>/dev/null || true)

  rm -f "$plan_path"

  # Should return JSON with total field
  if echo "$result" | jq -e '.total' > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# Test: coordinate_metadata_updates function exists
test_coordinate_metadata_updates_exists() {
  if declare -f coordinate_metadata_updates > /dev/null; then
    return 0
  else
    echo "Function coordinate_metadata_updates not found" >&2
    return 1
  fi
}

# Test: coordinate_metadata_updates requires arguments
test_coordinate_metadata_updates_args() {
  local output
  output=$(coordinate_metadata_updates "" "" 2>&1 || true)
  if echo "$output" | grep -q "requires plan_path"; then
    return 0
  else
    return 1
  fi
}

# Test: coordinate_metadata_updates handles empty results
test_coordinate_metadata_updates_empty() {
  local plan_path="/tmp/test_plan.md"
  local aggregation_json='{"total":0,"successful":0,"failed":0,"artifacts":[]}'

  # Create mock plan file
  echo "# Test Plan" > "$plan_path"

  local result
  if coordinate_metadata_updates "$plan_path" "$aggregation_json" 2>&1; then
    rm -f "$plan_path"
    return 0
  else
    rm -f "$plan_path"
    return 1
  fi
}

# ============================================================================
# Run All Tests
# ============================================================================

echo "Testing Parallel Expansion Functions"
echo "======================================"
echo ""

run_test "invoke_expansion_agents_parallel exists" test_invoke_expansion_agents_parallel_exists
run_test "invoke_expansion_agents_parallel requires arguments" test_invoke_expansion_agents_parallel_args
run_test "invoke_expansion_agents_parallel accepts valid JSON" test_invoke_expansion_agents_parallel_json
run_test "aggregate_expansion_artifacts exists" test_aggregate_expansion_artifacts_exists
run_test "aggregate_expansion_artifacts requires arguments" test_aggregate_expansion_artifacts_args
run_test "aggregate_expansion_artifacts validates artifacts" test_aggregate_expansion_artifacts_validation
run_test "coordinate_metadata_updates exists" test_coordinate_metadata_updates_exists
run_test "coordinate_metadata_updates requires arguments" test_coordinate_metadata_updates_args
run_test "coordinate_metadata_updates handles empty results" test_coordinate_metadata_updates_empty

# ============================================================================
# Print Results
# ============================================================================

echo ""
echo "======================================"
echo "Test Results:"
echo "  Total: $TESTS_RUN"
echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
echo "======================================"

if [[ $TESTS_FAILED -eq 0 ]]; then
  exit 0
else
  exit 1
fi
