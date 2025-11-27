#!/usr/bin/env bash
# Test suite for smart checkpoint auto-resume functionality
# Tests check_safe_resume_conditions() and get_skip_reason() functions

set -euo pipefail

# Source the checkpoint utilities
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
source "$CLAUDE_LIB/workflow/checkpoint-utils.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test helper functions
setup_test_env() {
  # Create temporary test directory
  TEST_DIR=$(mktemp -d)

  # Use the actual CHECKPOINTS_DIR but create a subdirectory for testing
  TEST_CHECKPOINT_SUBDIR="test_$$"
  mkdir -p "$CHECKPOINTS_DIR/$TEST_CHECKPOINT_SUBDIR"

  # Create test plan file
  TEST_PLAN_FILE="$TEST_DIR/test_plan.md"
  echo "# Test Plan" > "$TEST_PLAN_FILE"
}

cleanup_test_env() {
  if [ -n "${TEST_DIR:-}" ] && [ -d "$TEST_DIR" ]; then
    rm -rf "$TEST_DIR"
  fi

  # Clean up test checkpoint subdirectory
  if [ -n "${TEST_CHECKPOINT_SUBDIR:-}" ] && [ -d "$CHECKPOINTS_DIR/$TEST_CHECKPOINT_SUBDIR" ]; then
    rm -rf "$CHECKPOINTS_DIR/$TEST_CHECKPOINT_SUBDIR"
  fi
}

create_test_checkpoint() {
  local tests_passing="${1:-true}"
  local last_error="${2:-null}"
  local status="${3:-in_progress}"
  local age_days="${4:-1}"
  local plan_modified="${5:-false}"

  # Calculate checkpoint timestamp (age_days in the past)
  local checkpoint_timestamp
  if [[ "$OSTYPE" == "darwin"* ]]; then
    checkpoint_timestamp=$(date -u -v-${age_days}d +%Y-%m-%dT%H:%M:%SZ)
  else
    checkpoint_timestamp=$(date -u -d "$age_days days ago" +%Y-%m-%dT%H:%M:%SZ)
  fi

  # Get plan modification time
  local plan_mtime
  plan_mtime=$(stat -c %Y "$TEST_PLAN_FILE" 2>/dev/null || stat -f %m "$TEST_PLAN_FILE" 2>/dev/null || echo "0")

  # If plan should appear modified, change its timestamp
  if [ "$plan_modified" = "true" ]; then
    # Touch the plan file to make it appear newer than checkpoint
    sleep 1
    touch "$TEST_PLAN_FILE"
    # Use old mtime in checkpoint (before the touch)
  fi

  local checkpoint_file="$CHECKPOINTS_DIR/$TEST_CHECKPOINT_SUBDIR/test_checkpoint.json"

  # Create checkpoint JSON
  jq -n \
    --arg schema_version "1.2" \
    --arg checkpoint_id "test_checkpoint_001" \
    --arg workflow_type "implement" \
    --arg project "test_project" \
    --arg created "$checkpoint_timestamp" \
    --arg status "$status" \
    --argjson tests_passing "$tests_passing" \
    --argjson last_error "$last_error" \
    --arg plan_path "$TEST_PLAN_FILE" \
    --argjson plan_mtime "$plan_mtime" \
    '{
      schema_version: $schema_version,
      checkpoint_id: $checkpoint_id,
      workflow_type: $workflow_type,
      project_name: $project,
      workflow_description: "Test workflow",
      created_at: $created,
      updated_at: $created,
      status: $status,
      current_phase: 2,
      total_phases: 5,
      completed_phases: [1],
      workflow_state: {
        plan_path: $plan_path,
        current_phase: 2
      },
      last_error: $last_error,
      tests_passing: $tests_passing,
      plan_modification_time: $plan_mtime,
      replanning_count: 0,
      last_replan_reason: null,
      replan_phase_counts: {},
      replan_history: [],
      debug_report_path: null,
      user_last_choice: null,
      debug_iteration_count: 0
    }' > "$checkpoint_file"

  echo "$checkpoint_file"
}

assert_equals() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [ "$expected" = "$actual" ]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} $test_name"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} $test_name"
    echo -e "  Expected: $expected"
    echo -e "  Actual:   $actual"
    return 1
  fi
}

assert_true() {
  local condition="$1"
  local test_name="$2"

  if $condition; then
    assert_equals "true" "true" "$test_name"
  else
    assert_equals "true" "false" "$test_name"
  fi
}

assert_false() {
  local condition="$1"
  local test_name="$2"

  if $condition; then
    assert_equals "false" "true" "$test_name"
  else
    assert_equals "false" "false" "$test_name"
  fi
}

assert_contains() {
  local substring="$1"
  local text="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ "$text" == *"$substring"* ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} $test_name"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} $test_name"
    echo -e "  Expected to contain: $substring"
    echo -e "  Actual text:         $text"
    return 1
  fi
}

# ==============================================================================
# Test Cases
# ==============================================================================

test_safe_resume_all_conditions_met() {
  echo ""
  echo "Test: Safe resume - all conditions met"

  setup_test_env

  # Create checkpoint with all safe conditions
  local checkpoint=$(create_test_checkpoint true null in_progress 1 false)

  # Should return 0 (safe to auto-resume)
  local result=0
  check_safe_resume_conditions "$checkpoint" || result=$?
  assert_equals "0" "$result" "Auto-resume allowed when all conditions met"

  cleanup_test_env
}

test_unsafe_resume_tests_failing() {
  echo ""
  echo "Test: Unsafe resume - tests failing"

  setup_test_env

  # Create checkpoint with tests failing
  local checkpoint=$(create_test_checkpoint false null in_progress 1 false)

  # Should return 1 (interactive prompt needed)
  local result=0
  check_safe_resume_conditions "$checkpoint" || result=$?
  assert_equals "1" "$result" "Interactive prompt required when tests failing"

  # Check skip reason
  local reason=$(get_skip_reason "$checkpoint")
  assert_contains "Tests failing" "$reason" "Skip reason mentions test failures"

  cleanup_test_env
}

test_unsafe_resume_last_error() {
  echo ""
  echo "Test: Unsafe resume - last error present"

  setup_test_env

  # Create checkpoint with last error
  local checkpoint=$(create_test_checkpoint true '"Agent invocation failed"' in_progress 1 false)

  # Should return 1 (interactive prompt needed)
  local result=0
  check_safe_resume_conditions "$checkpoint" || result=$?
  assert_equals "1" "$result" "Interactive prompt required when last error present"

  # Check skip reason
  local reason=$(get_skip_reason "$checkpoint")
  assert_contains "errors" "$reason" "Skip reason mentions errors"

  cleanup_test_env
}

test_unsafe_resume_wrong_status() {
  echo ""
  echo "Test: Unsafe resume - wrong status"

  setup_test_env

  # Create checkpoint with completed status
  local checkpoint=$(create_test_checkpoint true null completed 1 false)

  # Should return 1 (interactive prompt needed)
  local result=0
  check_safe_resume_conditions "$checkpoint" || result=$?
  assert_equals "1" "$result" "Interactive prompt required for non-in_progress status"

  # Check skip reason
  local reason=$(get_skip_reason "$checkpoint")
  assert_contains "status" "$reason" "Skip reason mentions status"

  cleanup_test_env
}

test_unsafe_resume_checkpoint_too_old() {
  echo ""
  echo "Test: Unsafe resume - checkpoint too old"

  setup_test_env

  # Create checkpoint 8 days old (exceeds 7 day limit)
  local checkpoint=$(create_test_checkpoint true null in_progress 8 false)

  # Should return 1 (interactive prompt needed)
  local result=0
  check_safe_resume_conditions "$checkpoint" || result=$?
  assert_equals "1" "$result" "Interactive prompt required for old checkpoint"

  # Check skip reason
  local reason=$(get_skip_reason "$checkpoint")
  assert_contains "days old" "$reason" "Skip reason mentions checkpoint age"

  cleanup_test_env
}

test_unsafe_resume_plan_modified() {
  echo ""
  echo "Test: Unsafe resume - plan modified"

  setup_test_env

  # Create checkpoint with plan modified after checkpoint
  local checkpoint=$(create_test_checkpoint true null in_progress 1 true)

  # Should return 1 (interactive prompt needed)
  local result=0
  check_safe_resume_conditions "$checkpoint" || result=$?
  assert_equals "1" "$result" "Interactive prompt required when plan modified"

  # Check skip reason
  local reason=$(get_skip_reason "$checkpoint")
  assert_contains "modified" "$reason" "Skip reason mentions plan modification"

  cleanup_test_env
}

test_safe_resume_edge_case_exactly_7_days() {
  echo ""
  echo "Test: Safe resume - exactly 7 days old (boundary)"

  setup_test_env

  # Create checkpoint exactly 7 days old
  local checkpoint=$(create_test_checkpoint true null in_progress 7 false)

  # Should return 0 (safe to auto-resume - within 7 day window)
  local result=0
  check_safe_resume_conditions "$checkpoint" || result=$?
  assert_equals "0" "$result" "Auto-resume allowed for 7-day-old checkpoint"

  cleanup_test_env
}

test_safe_resume_no_plan_modification_time() {
  echo ""
  echo "Test: Safe resume - no plan_modification_time field"

  setup_test_env

  # Create checkpoint without plan_modification_time (old schema)
  local checkpoint="$CHECKPOINTS_DIR/$TEST_CHECKPOINT_SUBDIR/test_checkpoint_no_mtime.json"

  jq -n \
    --arg checkpoint_id "test_checkpoint_no_mtime" \
    --arg created "$(date -u -d '1 day ago' +%Y-%m-%dT%H:%M:%SZ)" \
    '{
      schema_version: "1.0",
      checkpoint_id: $checkpoint_id,
      workflow_type: "implement",
      project_name: "test",
      created_at: $created,
      updated_at: $created,
      status: "in_progress",
      current_phase: 2,
      workflow_state: {},
      tests_passing: true,
      last_error: null
    }' > "$checkpoint"

  # Should return 0 (safe to auto-resume - plan modification check skipped)
  local result=0
  check_safe_resume_conditions "$checkpoint" || result=$?
  assert_equals "0" "$result" "Auto-resume allowed without plan_modification_time field"

  cleanup_test_env
}

test_get_skip_reason_all_conditions_met() {
  echo ""
  echo "Test: Get skip reason - all conditions met"

  setup_test_env

  # Create checkpoint with all safe conditions
  local checkpoint=$(create_test_checkpoint true null in_progress 1 false)

  # Reason should indicate all conditions met
  local reason=$(get_skip_reason "$checkpoint")
  assert_equals "All conditions met" "$reason" "Skip reason indicates all conditions met"

  cleanup_test_env
}

test_missing_checkpoint_file() {
  echo ""
  echo "Test: Missing checkpoint file"

  setup_test_env

  local nonexistent_checkpoint="$CHECKPOINTS_DIR/$TEST_CHECKPOINT_SUBDIR/nonexistent.json"

  # Should return 1 (error)
  local result=0
  check_safe_resume_conditions "$nonexistent_checkpoint" 2>/dev/null || result=$?
  assert_equals "1" "$result" "Error returned for missing checkpoint file"

  cleanup_test_env
}

test_invalid_json_checkpoint() {
  echo ""
  echo "Test: Invalid JSON checkpoint"

  setup_test_env

  local invalid_checkpoint="$CHECKPOINTS_DIR/$TEST_CHECKPOINT_SUBDIR/invalid.json"
  echo "{ invalid json" > "$invalid_checkpoint"

  # Should return 1 (error)
  local result=0
  check_safe_resume_conditions "$invalid_checkpoint" 2>/dev/null || result=$?
  assert_equals "1" "$result" "Error returned for invalid JSON"

  cleanup_test_env
}

test_checkpoint_age_calculation() {
  echo ""
  echo "Test: Checkpoint age calculation"

  setup_test_env

  # Create checkpoints of varying ages
  local checkpoint_1day=$(create_test_checkpoint true null in_progress 1 false)
  local checkpoint_3days=$(create_test_checkpoint true null in_progress 3 false)
  local checkpoint_6days=$(create_test_checkpoint true null in_progress 6 false)

  # All should be safe to resume (< 7 days)
  local result=0
  check_safe_resume_conditions "$checkpoint_1day" || result=$?
  assert_equals "0" "$result" "1-day-old checkpoint is safe"

  result=0
  check_safe_resume_conditions "$checkpoint_3days" || result=$?
  assert_equals "0" "$result" "3-day-old checkpoint is safe"

  result=0
  check_safe_resume_conditions "$checkpoint_6days" || result=$?
  assert_equals "0" "$result" "6-day-old checkpoint is safe"

  cleanup_test_env
}

test_plan_modification_detection() {
  echo ""
  echo "Test: Plan modification detection"

  setup_test_env

  # Create checkpoint with current plan mtime
  local checkpoint1=$(create_test_checkpoint true null in_progress 1 false)

  # Should be safe to resume
  local result=0
  check_safe_resume_conditions "$checkpoint1" || result=$?
  assert_equals "0" "$result" "Safe to resume with unmodified plan"

  # Now modify the plan after creating checkpoint
  sleep 1
  touch "$TEST_PLAN_FILE"

  # Should now be unsafe to resume (plan modified)
  result=0
  check_safe_resume_conditions "$checkpoint1" || result=$?
  assert_equals "1" "$result" "Unsafe to resume after plan modification"

  cleanup_test_env
}

test_multiple_conditions_failing() {
  echo ""
  echo "Test: Multiple conditions failing"

  setup_test_env

  # Create checkpoint with multiple failures (tests failing + old + error)
  local checkpoint_timestamp=$(date -u -d "10 days ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-10d +%Y-%m-%dT%H:%M:%SZ)
  local checkpoint="$CHECKPOINTS_DIR/$TEST_CHECKPOINT_SUBDIR/multi_fail.json"

  jq -n \
    --arg created "$checkpoint_timestamp" \
    '{
      schema_version: "1.2",
      checkpoint_id: "multi_fail",
      workflow_type: "implement",
      project_name: "test",
      created_at: $created,
      updated_at: $created,
      status: "in_progress",
      current_phase: 2,
      workflow_state: {},
      tests_passing: false,
      last_error: "Agent failed"
    }' > "$checkpoint"

  # Should be unsafe to resume
  local result=0
  check_safe_resume_conditions "$checkpoint" || result=$?
  assert_equals "1" "$result" "Unsafe with multiple condition failures"

  # Skip reason should mention first failure (tests)
  local reason=$(get_skip_reason "$checkpoint")
  assert_contains "Tests failing" "$reason" "Skip reason mentions first failure"

  cleanup_test_env
}

# ==============================================================================
# Run All Tests
# ==============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Smart Checkpoint Auto-Resume Test Suite"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Run all test functions
test_safe_resume_all_conditions_met
test_unsafe_resume_tests_failing
test_unsafe_resume_last_error
test_unsafe_resume_wrong_status
test_unsafe_resume_checkpoint_too_old
test_unsafe_resume_plan_modified
test_safe_resume_edge_case_exactly_7_days
test_safe_resume_no_plan_modification_time
test_get_skip_reason_all_conditions_met
test_missing_checkpoint_file
test_invalid_json_checkpoint
test_checkpoint_age_calculation
test_plan_modification_detection
test_multiple_conditions_failing

# Print summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Total:  $TESTS_RUN"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
  echo -e "${RED}Failed: $TESTS_FAILED${NC}"
else
  echo -e "Failed: $TESTS_FAILED"
fi
echo ""

# Exit with failure if any tests failed
if [ $TESTS_FAILED -gt 0 ]; then
  exit 1
fi

exit 0
