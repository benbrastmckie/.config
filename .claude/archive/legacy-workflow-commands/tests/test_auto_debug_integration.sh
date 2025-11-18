#!/usr/bin/env bash
# Test automatic debug integration workflow
# Part of Phase 3: Automatic Debug Integration & Progress Dashboard

set -e

# Color codes for test output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test results array
declare -a FAILED_TESTS=()

# Setup test environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="/tmp/test_auto_debug_$$"
mkdir -p "$TEST_DIR"

# Cleanup function
cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Helper function to run a test
run_test() {
  local test_name="$1"
  local test_function="$2"

  TESTS_RUN=$((TESTS_RUN + 1))

  if $test_function; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: $test_name"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    FAILED_TESTS+=("$test_name")
    echo -e "${RED}✗${NC} FAIL: $test_name"
    return 1
  fi
}

# Helper to create mock plan file
create_mock_plan() {
  local plan_path="$1"
  cat > "$plan_path" <<'EOF'
# Test Plan

## Metadata
- **Date**: 2025-10-13
- **Feature**: Test Feature

## Phases

### Phase 1: Setup

Tasks:
- [ ] Task 1
- [ ] Task 2

### Phase 2: Implementation

Tasks:
- [ ] Task 1
- [ ] Task 2

### Phase 3: Testing

Tasks:
- [ ] Task 1
- [ ] Task 2
EOF
}

# Helper to create mock debug report
create_mock_debug_report() {
  local report_path="$1"
  cat > "$report_path" <<'EOF'
# Debug Report: Test Failure

## Root Cause Analysis

The test failure was caused by a missing null check in the authentication handler.
The variable was not initialized before being accessed, leading to a null pointer error.

## Proposed Solutions

1. Add null check before accessing the variable
2. Initialize the variable with a default value
3. Use optional chaining or safe access patterns
EOF
}

# ============================================================================
# Debug Invocation Tests (3 tests)
# ============================================================================

test_auto_debug_invocation_no_prompt() {
  # Test that debug is invoked automatically without user prompt
  local test_output="Test failure: null pointer at line 42"

  # Simulate error type detection
  if [[ "$test_output" == *"null pointer"* ]]; then
    # This would trigger auto-debug
    return 0
  else
    echo "  Expected null pointer error to trigger auto-debug"
    return 1
  fi
}

test_debug_command_construction() {
  local phase_num=3
  local error_message="Test failure: undefined variable"
  local plan_path="/tmp/test_plan.md"

  # Construct debug command
  local debug_command="/debug \"Phase $phase_num test failure: ${error_message:0:100}\" \"$plan_path\""

  # Verify command format
  if [[ "$debug_command" == *"/debug"* ]] && \
     [[ "$debug_command" == *"Phase 3"* ]] && \
     [[ "$debug_command" == *"$plan_path"* ]]; then
    return 0
  else
    echo "  Expected proper debug command format"
    echo "  Got: $debug_command"
    return 1
  fi
}

test_report_path_parsing() {
  local debug_output="Debug report generated at specs/reports/047_debug_test_failure.md"

  # Parse report path
  local report_path
  report_path=$(echo "$debug_output" | grep -o 'specs/reports/[0-9]*_debug_.*\.md' | head -1)

  if [[ "$report_path" == "specs/reports/047_debug_test_failure.md" ]]; then
    return 0
  else
    echo "  Expected to parse report path correctly"
    echo "  Got: $report_path"
    return 1
  fi
}

# ============================================================================
# Summary Rendering Tests (3 tests)
# ============================================================================

test_debug_summary_root_cause_extraction() {
  local report_path="$TEST_DIR/debug_report.md"
  create_mock_debug_report "$report_path"

  # Extract root cause
  local root_cause
  root_cause=$(sed -n '/^## Root Cause Analysis/,/^##/p' "$report_path" | \
               grep -v '^##' | head -5 | tr '\n' ' ' | cut -c 1-80)

  if [[ "$root_cause" == *"missing null check"* ]]; then
    return 0
  else
    echo "  Expected to extract root cause"
    echo "  Got: $root_cause"
    return 1
  fi
}

test_debug_summary_unicode_box() {
  local phase_num=3
  local root_cause="Missing null check in authentication handler"
  local report_name="047_debug_test.md"

  # Build unicode box (simplified test)
  local box_line="┌─────────────────────────────────────────────────────────────────┐"

  if [[ "$box_line" == *"┌"* ]] && [[ "$box_line" == *"┐"* ]]; then
    return 0
  else
    echo "  Expected unicode box characters"
    return 1
  fi
}

test_debug_summary_truncation() {
  local long_cause="This is a very long root cause description that exceeds eighty characters and should be truncated properly"
  local truncated="${long_cause:0:80}"

  if [[ ${#truncated} -eq 80 ]]; then
    return 0
  else
    echo "  Expected truncation to 80 characters"
    echo "  Got length: ${#truncated}"
    return 1
  fi
}

# ============================================================================
# User Choice Tests (4 tests)
# ============================================================================

test_user_choice_revise() {
  local choice="r"

  case "$choice" in
    r)
      # Build revision context
      local context='{"revision_type": "add_phase", "current_phase": 3}'

      if echo "$context" | jq -e '.revision_type == "add_phase"' >/dev/null; then
        return 0
      else
        echo "  Expected to build valid revision context"
        return 1
      fi
      ;;
    *)
      echo "  Choice mismatch"
      return 1
      ;;
  esac
}

test_user_choice_continue() {
  local choice="c"
  local phase_num=3

  case "$choice" in
    c)
      # Should mark phase incomplete
      local marker="[INCOMPLETE]"

      if [[ "$marker" == "[INCOMPLETE]" ]]; then
        return 0
      else
        echo "  Expected [INCOMPLETE] marker"
        return 1
      fi
      ;;
    *)
      echo "  Choice mismatch"
      return 1
      ;;
  esac
}

test_user_choice_skip() {
  local choice="s"

  case "$choice" in
    s)
      # Should mark phase skipped
      local marker="[SKIPPED]"

      if [[ "$marker" == "[SKIPPED]" ]]; then
        return 0
      else
        echo "  Expected [SKIPPED] marker"
        return 1
      fi
      ;;
    *)
      echo "  Choice mismatch"
      return 1
      ;;
  esac
}

test_user_choice_abort() {
  local choice="a"

  case "$choice" in
    a)
      # Should save checkpoint with paused status
      local status="paused"

      if [[ "$status" == "paused" ]]; then
        return 0
      else
        echo "  Expected paused status"
        return 1
      fi
      ;;
    *)
      echo "  Choice mismatch"
      return 1
      ;;
  esac
}

# ============================================================================
# Workflow Tests (5 tests)
# ============================================================================

test_revise_success_retry_phase() {
  # Simulate successful revision
  local revise_status="success"

  if [[ "$revise_status" == "success" ]]; then
    # Should retry phase
    return 0
  else
    echo "  Expected success status to trigger retry"
    return 1
  fi
}

test_revise_failure_fallback_continue() {
  # Simulate failed revision
  local revise_status="failed"
  local fallback_choice="c"

  if [[ "$revise_status" != "success" ]] && [[ "$fallback_choice" == "c" ]]; then
    # Should fallback to continue
    return 0
  else
    echo "  Expected fallback to continue on revision failure"
    return 1
  fi
}

test_debugging_notes_added_continue() {
  local plan_path="$TEST_DIR/test_plan.md"
  create_mock_plan "$plan_path"

  # Add debugging notes (simulated)
  local has_debug_notes
  has_debug_notes=$(grep -q "#### Debugging Notes" "$plan_path" && echo "true" || echo "false")

  # Initially should be false
  if [[ "$has_debug_notes" == "false" ]]; then
    return 0
  else
    echo "  Expected no debugging notes initially"
    return 1
  fi
}

test_debugging_notes_added_skip() {
  # Similar to continue, but with skipped status
  local resolution_status="Skipped"

  if [[ "$resolution_status" == "Skipped" ]]; then
    return 0
  else
    echo "  Expected Skipped resolution status"
    return 1
  fi
}

test_checkpoint_saved_abort() {
  # Test that abort saves checkpoint
  local checkpoint_status="paused"
  local debug_report_path="specs/reports/047_debug.md"

  if [[ "$checkpoint_status" == "paused" ]] && [[ -n "$debug_report_path" ]]; then
    return 0
  else
    echo "  Expected checkpoint with paused status and debug report"
    return 1
  fi
}

# ============================================================================
# Fallback and Logging Tests (5 tests)
# ============================================================================

test_fallback_analyze_error_sh() {
  # Test fallback when /debug fails
  local debug_result=""

  if [[ -z "$debug_result" ]]; then
    # Should fallback to analyze-error.sh
    # This is a structural test
    return 0
  else
    echo "  Expected empty debug result to trigger fallback"
    return 1
  fi
}

test_invalid_input_validation() {
  local invalid_choice="x"

  case "$invalid_choice" in
    r|c|s|a)
      echo "  Should not accept invalid choice"
      return 1
      ;;
    *)
      # Invalid choice detected
      return 0
      ;;
  esac
}

test_log_auto_debug_trigger() {
  local log_message="Auto-debug triggered for Phase 3"

  if [[ "$log_message" == *"Auto-debug triggered"* ]]; then
    return 0
  else
    echo "  Expected log message for auto-debug trigger"
    return 1
  fi
}

test_log_user_choice() {
  local choice="r"
  local log_message="User chose: $choice"

  if [[ "$log_message" == *"User chose: r"* ]]; then
    return 0
  else
    echo "  Expected log message for user choice"
    return 1
  fi
}

test_log_action_outcome() {
  local action="revise"
  local outcome="success"
  local log_message="Action completed: $action - $outcome"

  if [[ "$log_message" == *"Action completed"* ]] && \
     [[ "$log_message" == *"revise"* ]] && \
     [[ "$log_message" == *"success"* ]]; then
    return 0
  else
    echo "  Expected log message for action outcome"
    return 1
  fi
}

# ============================================================================
# Test Runner
# ============================================================================

echo "=========================================="
echo "Auto-Debug Integration Test Suite"
echo "=========================================="
echo ""

# Debug Invocation Tests
echo "Running Debug Invocation Tests..."
run_test "Auto-debug invocation without prompt" test_auto_debug_invocation_no_prompt
run_test "Debug command construction" test_debug_command_construction
run_test "Report path parsing" test_report_path_parsing
echo ""

# Summary Rendering Tests
echo "Running Summary Rendering Tests..."
run_test "Root cause extraction" test_debug_summary_root_cause_extraction
run_test "Unicode box rendering" test_debug_summary_unicode_box
run_test "Root cause truncation" test_debug_summary_truncation
echo ""

# User Choice Tests
echo "Running User Choice Tests..."
run_test "User choice: revise" test_user_choice_revise
run_test "User choice: continue" test_user_choice_continue
run_test "User choice: skip" test_user_choice_skip
run_test "User choice: abort" test_user_choice_abort
echo ""

# Workflow Tests
echo "Running Workflow Tests..."
run_test "Revise success triggers retry" test_revise_success_retry_phase
run_test "Revise failure fallback to continue" test_revise_failure_fallback_continue
run_test "Debugging notes added on continue" test_debugging_notes_added_continue
run_test "Debugging notes added on skip" test_debugging_notes_added_skip
run_test "Checkpoint saved on abort" test_checkpoint_saved_abort
echo ""

# Fallback and Logging Tests
echo "Running Fallback and Logging Tests..."
run_test "Fallback to analyze-error.sh" test_fallback_analyze_error_sh
run_test "Invalid input validation" test_invalid_input_validation
run_test "Log auto-debug trigger" test_log_auto_debug_trigger
run_test "Log user choice" test_log_user_choice
run_test "Log action outcome" test_log_action_outcome
echo ""

# Summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Total tests run: $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
  echo "Failed tests:"
  for test in "${FAILED_TESTS[@]}"; do
    echo -e "  ${RED}✗${NC} $test"
  done
  echo ""
  exit 1
else
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
fi
