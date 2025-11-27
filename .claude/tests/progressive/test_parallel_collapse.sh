#!/usr/bin/env bash
# Test suite for parallel collapse functionality
# Tests invoke_collapse_agents_parallel, aggregate_collapse_artifacts, coordinate_collapse_metadata_updates

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

# Test: invoke_collapse_agents_parallel function exists
test_invoke_collapse_agents_parallel_exists() {
  if declare -f invoke_collapse_agents_parallel > /dev/null; then
    return 0
  else
    echo "Function invoke_collapse_agents_parallel not found" >&2
    return 1
  fi
}

# Test: invoke_collapse_agents_parallel requires arguments
test_invoke_collapse_agents_parallel_args() {
  local output
  output=$(invoke_collapse_agents_parallel "" "" 2>&1 || true)
  if echo "$output" | grep -q "requires plan_path"; then
    return 0
  else
    return 1
  fi
}

# Test: invoke_collapse_agents_parallel accepts valid JSON
test_invoke_collapse_agents_parallel_json() {
  local plan_path="/tmp/test_plan"
  local recommendations='[{"item_id":"phase_1","recommendation":"collapse","complexity_level":3}]'

  # Create mock plan directory with proper structure
  mkdir -p "$plan_path"
  cat > "$plan_path/test_plan.md" <<'EOF'
# Test Plan

## Metadata
- **Structure Level**: 1
- **Expanded Phases**: [1]

## Overview
Test plan for parallel collapse

### Phase 1: Test Phase [See: phase_1_test.md]
EOF

  # Create mock phase file
  cat > "$plan_path/phase_1_test.md" <<'EOF'
# Phase 1: Test Phase

## Objective
Test phase content
EOF

  # Redirect stderr to /dev/null to capture only stdout (the JSON output)
  local result
  result=$(invoke_collapse_agents_parallel "$plan_path" "$recommendations" 2>/dev/null || true)

  rm -rf "$plan_path"

  # Should return JSON array
  if echo "$result" | jq -e 'type == "array"' >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# Test: aggregate_collapse_artifacts function exists
test_aggregate_collapse_artifacts_exists() {
  if declare -f aggregate_collapse_artifacts > /dev/null; then
    return 0
  else
    echo "Function aggregate_collapse_artifacts not found" >&2
    return 1
  fi
}

# Test: aggregate_collapse_artifacts requires arguments
test_aggregate_collapse_artifacts_args() {
  local output
  output=$(aggregate_collapse_artifacts "" "" 2>&1 || true)
  if echo "$output" | grep -q "requires plan_path"; then
    return 0
  else
    return 1
  fi
}

# Test: aggregate_collapse_artifacts validates artifacts
test_aggregate_collapse_artifacts_validation() {
  local plan_path="/tmp/test_plan"
  local artifact_refs='[{"item_id":"phase_1","artifact_path":"specs/artifacts/test_plan/collapse_1.md"}]'

  # Create mock plan directory
  mkdir -p "$plan_path"
  echo "# Test Plan" > "$plan_path/test_plan.md"

  # Redirect stderr to /dev/null to capture only JSON output
  local result
  result=$(aggregate_collapse_artifacts "$plan_path" "$artifact_refs" 2>/dev/null || true)

  rm -rf "$plan_path"

  # Should return JSON with total field
  if echo "$result" | jq -e '.total' > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# Test: coordinate_collapse_metadata_updates function exists
test_coordinate_collapse_metadata_updates_exists() {
  if declare -f coordinate_collapse_metadata_updates > /dev/null; then
    return 0
  else
    echo "Function coordinate_collapse_metadata_updates not found" >&2
    return 1
  fi
}

# Test: coordinate_collapse_metadata_updates requires arguments
test_coordinate_collapse_metadata_updates_args() {
  local output
  output=$(coordinate_collapse_metadata_updates "" "" 2>&1 || true)
  if echo "$output" | grep -q "requires plan_path"; then
    return 0
  else
    return 1
  fi
}

# Test: coordinate_collapse_metadata_updates handles empty results
test_coordinate_collapse_metadata_updates_empty() {
  local plan_path="/tmp/test_plan"
  local aggregation_json='{"total":0,"successful":0,"failed":0,"artifacts":[]}'

  # Create mock plan directory
  mkdir -p "$plan_path"
  echo "# Test Plan" > "$plan_path/test_plan.md"

  local result
  if coordinate_collapse_metadata_updates "$plan_path" "$aggregation_json" 2>&1 >/dev/null; then
    rm -rf "$plan_path"
    return 0
  else
    rm -rf "$plan_path"
    return 1
  fi
}

# ============================================================================
# Run All Tests
# ============================================================================

echo "Testing Parallel Collapse Functions"
echo "======================================"
echo ""

run_test "invoke_collapse_agents_parallel exists" test_invoke_collapse_agents_parallel_exists
run_test "invoke_collapse_agents_parallel requires arguments" test_invoke_collapse_agents_parallel_args
run_test "invoke_collapse_agents_parallel accepts valid JSON" test_invoke_collapse_agents_parallel_json
run_test "aggregate_collapse_artifacts exists" test_aggregate_collapse_artifacts_exists
run_test "aggregate_collapse_artifacts requires arguments" test_aggregate_collapse_artifacts_args
run_test "aggregate_collapse_artifacts validates artifacts" test_aggregate_collapse_artifacts_validation
run_test "coordinate_collapse_metadata_updates exists" test_coordinate_collapse_metadata_updates_exists
run_test "coordinate_collapse_metadata_updates requires arguments" test_coordinate_collapse_metadata_updates_args
run_test "coordinate_collapse_metadata_updates handles empty results" test_coordinate_collapse_metadata_updates_empty

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
