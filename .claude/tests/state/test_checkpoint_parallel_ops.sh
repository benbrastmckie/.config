#!/usr/bin/env bash
# Test suite for parallel operations checkpoint functionality
# Tests save_parallel_operation_checkpoint, restore_from_checkpoint, validate_checkpoint_integrity

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

# Setup test checkpoint directory BEFORE sourcing library
TEST_CHECKPOINT_DIR="/tmp/test_checkpoints"
export CHECKPOINTS_DIR="$TEST_CHECKPOINT_DIR"

# Source the library under test
source "$CLAUDE_PROJECT_DIR/.claude/lib/workflow/checkpoint-utils.sh"

# Cleanup function
cleanup_test_checkpoints() {
  rm -rf "$TEST_CHECKPOINT_DIR"
}

# Setup before tests
mkdir -p "$TEST_CHECKPOINT_DIR/parallel_ops"
trap cleanup_test_checkpoints EXIT

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

# Test: save_parallel_operation_checkpoint function exists
test_save_parallel_operation_checkpoint_exists() {
  if declare -f save_parallel_operation_checkpoint > /dev/null; then
    return 0
  else
    echo "Function save_parallel_operation_checkpoint not found" >&2
    return 1
  fi
}

# Test: save_parallel_operation_checkpoint requires arguments
test_save_parallel_operation_checkpoint_args() {
  local output
  output=$(save_parallel_operation_checkpoint "" "" 2>&1 || true)
  if echo "$output" | grep -q "requires plan_path"; then
    return 0
  else
    return 1
  fi
}

# Test: save_parallel_operation_checkpoint creates checkpoint file
test_save_parallel_operation_checkpoint_creates_file() {
  local plan_path="/tmp/test_plan.md"
  local operation_type="expansion"
  local operations_json='[{"phase":1,"complexity":8}]'

  # Create mock plan
  echo "# Test Plan" > "$plan_path"

  local checkpoint_file
  checkpoint_file=$(save_parallel_operation_checkpoint "$plan_path" "$operation_type" "$operations_json" 2>/dev/null)

  rm -f "$plan_path"

  # Should create checkpoint file
  if [[ -f "$checkpoint_file" ]]; then
    rm -f "$checkpoint_file"
    return 0
  else
    return 1
  fi
}

# Test: save_parallel_operation_checkpoint creates valid JSON
test_save_parallel_operation_checkpoint_valid_json() {
  local plan_path="/tmp/test_plan.md"
  local operation_type="expansion"
  local operations_json='[{"phase":1,"complexity":8}]'

  # Create mock plan
  echo "# Test Plan" > "$plan_path"

  local checkpoint_file
  checkpoint_file=$(save_parallel_operation_checkpoint "$plan_path" "$operation_type" "$operations_json" 2>/dev/null)

  rm -f "$plan_path"

  # Should be valid JSON
  if [[ -f "$checkpoint_file" ]] && jq empty "$checkpoint_file" 2>/dev/null; then
    rm -f "$checkpoint_file"
    return 0
  else
    rm -f "$checkpoint_file"
    return 1
  fi
}

# Test: save_parallel_operation_checkpoint includes required fields
test_save_parallel_operation_checkpoint_required_fields() {
  local plan_path="/tmp/test_plan.md"
  local operation_type="expansion"
  local operations_json='[{"phase":1,"complexity":8}]'

  # Create mock plan
  echo "# Test Plan" > "$plan_path"

  local checkpoint_file
  checkpoint_file=$(save_parallel_operation_checkpoint "$plan_path" "$operation_type" "$operations_json" 2>/dev/null)

  rm -f "$plan_path"

  # Should have checkpoint_id, operation_type, plan_path, created_at, operations, status
  local has_fields
  has_fields=$(jq -e 'has("checkpoint_id") and has("operation_type") and has("plan_path") and has("created_at") and has("operations") and has("status")' "$checkpoint_file" 2>/dev/null || echo "false")

  rm -f "$checkpoint_file"

  if [[ "$has_fields" == "true" ]]; then
    return 0
  else
    return 1
  fi
}

# Test: restore_from_checkpoint function exists
test_restore_from_checkpoint_exists() {
  if declare -f restore_from_checkpoint > /dev/null; then
    return 0
  else
    echo "Function restore_from_checkpoint not found" >&2
    return 1
  fi
}

# Test: restore_from_checkpoint loads checkpoint data
test_restore_from_checkpoint_loads_data() {
  local plan_path="/tmp/test_plan.md"
  local operation_type="expansion"
  local operations_json='[{"phase":1,"complexity":8}]'

  # Create mock plan
  echo "# Test Plan" > "$plan_path"

  # Save checkpoint
  local checkpoint_file
  checkpoint_file=$(save_parallel_operation_checkpoint "$plan_path" "$operation_type" "$operations_json" 2>/dev/null)

  rm -f "$plan_path"

  # Restore checkpoint
  local restored_data
  restored_data=$(restore_from_checkpoint "$checkpoint_file" 2>/dev/null || true)

  rm -f "$checkpoint_file"

  # Should return checkpoint data as JSON
  if echo "$restored_data" | jq -e '.checkpoint_id' > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# Test: validate_checkpoint_integrity function exists
test_validate_checkpoint_integrity_exists() {
  if declare -f validate_checkpoint_integrity > /dev/null; then
    return 0
  else
    echo "Function validate_checkpoint_integrity not found" >&2
    return 1
  fi
}

# Test: validate_checkpoint_integrity accepts valid checkpoint
test_validate_checkpoint_integrity_valid() {
  local plan_path="/tmp/test_plan.md"
  local operation_type="expansion"
  local operations_json='[{"phase":1,"complexity":8}]'

  # Create mock plan
  echo "# Test Plan" > "$plan_path"

  # Save checkpoint
  local checkpoint_file
  checkpoint_file=$(save_parallel_operation_checkpoint "$plan_path" "$operation_type" "$operations_json" 2>/dev/null)

  rm -f "$plan_path"

  # Validate checkpoint
  local result
  result=$(validate_checkpoint_integrity "$checkpoint_file" 2>/dev/null || echo "invalid")

  rm -f "$checkpoint_file"

  # Should return valid JSON with valid=true
  if echo "$result" | jq -e '.valid == true' > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# Test: validate_checkpoint_integrity rejects invalid checkpoint
test_validate_checkpoint_integrity_invalid() {
  local checkpoint_file="$TEST_CHECKPOINT_DIR/parallel_ops/invalid_checkpoint.json"

  # Create invalid checkpoint (missing required fields)
  echo '{"invalid":"checkpoint"}' > "$checkpoint_file"

  # Validate checkpoint
  local result
  result=$(validate_checkpoint_integrity "$checkpoint_file" 2>/dev/null || echo '{"valid":false}')

  rm -f "$checkpoint_file"

  # Should return valid=false
  if echo "$result" | jq -e '.valid == false' > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# ============================================================================
# Run All Tests
# ============================================================================

echo "Testing Checkpoint Functions for Parallel Operations"
echo "===================================================="
echo ""

run_test "save_parallel_operation_checkpoint exists" test_save_parallel_operation_checkpoint_exists
run_test "save_parallel_operation_checkpoint requires arguments" test_save_parallel_operation_checkpoint_args
run_test "save_parallel_operation_checkpoint creates checkpoint file" test_save_parallel_operation_checkpoint_creates_file
run_test "save_parallel_operation_checkpoint creates valid JSON" test_save_parallel_operation_checkpoint_valid_json
run_test "save_parallel_operation_checkpoint includes required fields" test_save_parallel_operation_checkpoint_required_fields
run_test "restore_from_checkpoint exists" test_restore_from_checkpoint_exists
run_test "restore_from_checkpoint loads checkpoint data" test_restore_from_checkpoint_loads_data
run_test "validate_checkpoint_integrity exists" test_validate_checkpoint_integrity_exists
run_test "validate_checkpoint_integrity accepts valid checkpoint" test_validate_checkpoint_integrity_valid
run_test "validate_checkpoint_integrity rejects invalid checkpoint" test_validate_checkpoint_integrity_invalid

# ============================================================================
# Print Results
# ============================================================================

echo ""
echo "===================================================="
echo "Test Results:"
echo "  Total: $TESTS_RUN"
echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
echo "===================================================="

if [[ $TESTS_FAILED -eq 0 ]]; then
  exit 0
else
  exit 1
fi
