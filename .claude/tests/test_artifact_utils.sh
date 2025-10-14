#!/usr/bin/env bash
# Test artifact utility functions
# Tests parallel operation artifact management

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
export CLAUDE_PROJECT_DIR="$PROJECT_ROOT"

# Source artifact utilities
source "$PROJECT_ROOT/.claude/lib/artifact-operations.sh"

# Test directory
TEST_DIR="$PROJECT_ROOT/.claude/tests/test_data"
mkdir -p "$TEST_DIR"

# Cleanup function
cleanup() {
  rm -rf "$TEST_DIR/test_plan.md"
  rm -rf "$PROJECT_ROOT/specs/artifacts/test_plan"
}

# Test function
test_case() {
  local description="$1"
  shift
  TESTS_RUN=$((TESTS_RUN + 1))

  echo -n "  Testing: $description... "

  if "$@" 2>&1; then
    echo -e "${GREEN}PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}FAIL${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Test setup
setup_test_plan() {
  cat > "$TEST_DIR/test_plan.md" <<'EOF'
# Test Plan

## Metadata
- **Structure Level**: 0
- **Expanded Phases**: []

## Phase 1: Setup
Tasks here
EOF
}

# Test functions
test_create_artifact_directory() {
  setup_test_plan
  local artifact_dir
  artifact_dir=$(create_artifact_directory "$TEST_DIR/test_plan.md")

  # Check directory was created
  [ -d "$artifact_dir" ] && [ "$artifact_dir" = "$PROJECT_ROOT/specs/artifacts/test_plan" ]
}

test_save_operation_artifact() {
  setup_test_plan
  create_artifact_directory "$TEST_DIR/test_plan.md" >/dev/null

  local content="# Expansion Artifact\nOperation: phase_1\nStatus: success"
  local artifact_file
  artifact_file=$(save_operation_artifact "test_plan" "expansion" "phase_1" "$content")

  # Check file was created with content
  [ -f "$artifact_file" ] && grep -q "Expansion Artifact" "$artifact_file"
}

test_load_artifact_references() {
  setup_test_plan
  create_artifact_directory "$TEST_DIR/test_plan.md" >/dev/null
  save_operation_artifact "test_plan" "expansion" "phase_1" "content1" >/dev/null
  save_operation_artifact "test_plan" "expansion" "phase_2" "content2" >/dev/null

  local refs
  refs=$(load_artifact_references "test_plan" "expansion")

  # Check JSON array has 2 items
  local count
  count=$(echo "$refs" | jq 'length')
  [ "$count" = "2" ]
}

test_load_artifact_references_empty() {
  local refs
  refs=$(load_artifact_references "nonexistent_plan" "expansion")

  # Check empty array returned
  [ "$refs" = "[]" ]
}

test_cleanup_operation_artifacts() {
  setup_test_plan
  create_artifact_directory "$TEST_DIR/test_plan.md" >/dev/null
  save_operation_artifact "test_plan" "expansion" "phase_1" "content" >/dev/null
  save_operation_artifact "test_plan" "expansion" "phase_2" "content" >/dev/null

  local count
  count=$(cleanup_operation_artifacts "test_plan" "expansion")

  # Check 2 artifacts were deleted
  [ "$count" = "2" ] && [ ! -d "$PROJECT_ROOT/specs/artifacts/test_plan" ]
}

test_artifact_references_item_id() {
  setup_test_plan
  create_artifact_directory "$TEST_DIR/test_plan.md" >/dev/null
  save_operation_artifact "test_plan" "expansion" "phase_1" "content" >/dev/null

  local refs
  refs=$(load_artifact_references "test_plan" "expansion")

  local item_id
  item_id=$(echo "$refs" | jq -r '.[0].item_id')

  [ "$item_id" = "phase_1" ]
}

test_artifact_references_path() {
  setup_test_plan
  create_artifact_directory "$TEST_DIR/test_plan.md" >/dev/null
  save_operation_artifact "test_plan" "expansion" "phase_1" "content" >/dev/null

  local refs
  refs=$(load_artifact_references "test_plan" "expansion")

  local path
  path=$(echo "$refs" | jq -r '.[0].path')

  [[ "$path" == *"specs/artifacts/test_plan/expansion_phase_1.md" ]]
}

test_artifact_references_size() {
  setup_test_plan
  create_artifact_directory "$TEST_DIR/test_plan.md" >/dev/null
  save_operation_artifact "test_plan" "expansion" "phase_1" "test content" >/dev/null

  local refs
  refs=$(load_artifact_references "test_plan" "expansion")

  local size
  size=$(echo "$refs" | jq -r '.[0].size')

  # Size should be greater than 0
  [ "$size" -gt 0 ]
}

test_cleanup_partial_artifacts() {
  setup_test_plan
  create_artifact_directory "$TEST_DIR/test_plan.md" >/dev/null
  save_operation_artifact "test_plan" "expansion" "phase_1" "content" >/dev/null
  save_operation_artifact "test_plan" "collapse" "phase_2" "content" >/dev/null

  local count
  count=$(cleanup_operation_artifacts "test_plan" "expansion")

  # Check only expansion artifacts deleted
  [ "$count" = "1" ] && [ -f "$PROJECT_ROOT/specs/artifacts/test_plan/collapse_phase_2.md" ]
}

# Main test execution
main() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Artifact Utilities Tests"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  echo "Testing artifact directory management:"
  test_case "Create artifact directory" test_create_artifact_directory
  cleanup
  echo ""

  echo "Testing artifact save/load:"
  test_case "Save operation artifact" test_save_operation_artifact
  cleanup
  test_case "Load artifact references" test_load_artifact_references
  cleanup
  test_case "Load empty artifact references" test_load_artifact_references_empty
  echo ""

  echo "Testing artifact cleanup:"
  test_case "Cleanup operation artifacts" test_cleanup_operation_artifacts
  cleanup
  test_case "Cleanup partial artifacts" test_cleanup_partial_artifacts
  cleanup
  echo ""

  echo "Testing artifact reference structure:"
  test_case "Artifact reference has item_id" test_artifact_references_item_id
  cleanup
  test_case "Artifact reference has path" test_artifact_references_path
  cleanup
  test_case "Artifact reference has size" test_artifact_references_size
  cleanup
  echo ""

  # Final cleanup
  rm -rf "$TEST_DIR"

  # Summary
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Test Summary"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Total tests:  $TESTS_RUN"
  echo -e "Passed:       ${GREEN}$TESTS_PASSED${NC}"

  if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "Failed:       ${RED}$TESTS_FAILED${NC}"
    echo ""
    exit 1
  else
    echo "Failed:       0"
    echo ""
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
  fi
}

# Run tests
main "$@"
