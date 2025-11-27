#!/usr/bin/env bash
# test_workflow_initialization.sh - Unit tests for workflow-initialization.sh
# Coverage target: >80%

set -euo pipefail

# Get script directory
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
CLAUDE_ROOT="${CLAUDE_PROJECT_DIR}/.claude"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test utilities
pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  TESTS_PASSED=$((TESTS_PASSED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  echo "  Reason: $2"
  TESTS_FAILED=$((TESTS_FAILED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
}

# Setup test environment
setup() {
  # Create temporary directory for test
  TEST_DIR=$(mktemp -d)
  export TEST_CLAUDE_ROOT="$TEST_DIR"

  # Create required directory structure
  mkdir -p "$TEST_DIR/.claude/specs"
  mkdir -p "$TEST_DIR/.claude/lib"

  # Copy required library files
  if [[ -f "${CLAUDE_ROOT}/lib/plan/topic-utils.sh" ]]; then
    cp "${CLAUDE_ROOT}/lib/plan/topic-utils.sh" "$TEST_DIR/.claude/lib/"
  fi
  if [[ -f "${CLAUDE_ROOT}/lib/core/detect-project-dir.sh" ]]; then
    cp "${CLAUDE_ROOT}/lib/core/detect-project-dir.sh" "$TEST_DIR/.claude/lib/"
  fi

  # Set CLAUDE_PROJECT_DIR for tests
  export CLAUDE_PROJECT_DIR="$TEST_DIR"
}

# Cleanup test environment
teardown() {
  if [[ -n "${TEST_DIR:-}" ]] && [[ -d "$TEST_DIR" ]]; then
    rm -rf "$TEST_DIR"
  fi
  unset CLAUDE_PROJECT_DIR
}

# Test 1: Research-only workflow path calculation
test_research_only_workflow() {
  local test_name="Research-only workflow path calculation"

  setup

  # Source the library
  if source "${CLAUDE_ROOT}/lib/workflow/workflow-initialization.sh"; then
    # Call the function
    if initialize_workflow_paths "test research topic" "research-only" >/dev/null 2>&1; then
      # Verify exported variables
      local all_vars_set=true

      if [[ -z "${TOPIC_PATH:-}" ]]; then all_vars_set=false; fi
      if [[ -z "${TOPIC_NUM:-}" ]]; then all_vars_set=false; fi
      if [[ -z "${TOPIC_NAME:-}" ]]; then all_vars_set=false; fi
      if [[ -z "${PROJECT_ROOT:-}" ]]; then all_vars_set=false; fi
      if [[ -z "${SPECS_ROOT:-}" ]]; then all_vars_set=false; fi

      # Verify topic directory was created
      if [[ ! -d "$TOPIC_PATH" ]]; then all_vars_set=false; fi

      # Verify workflow scope is correct
      if [[ "$all_vars_set" == "true" ]]; then
        pass "$test_name"
      else
        fail "$test_name" "Not all required variables set or topic directory not created"
      fi
    else
      fail "$test_name" "initialize_workflow_paths returned non-zero"
    fi
  else
    fail "$test_name" "Failed to source workflow-initialization.sh"
  fi

  teardown
}

# Test 2: Research+planning workflow path calculation
test_research_and_plan_workflow() {
  local test_name="Research+planning workflow path calculation"

  setup

  # Source the library
  if source "${CLAUDE_ROOT}/lib/workflow/workflow-initialization.sh"; then
    # Call the function
    if initialize_workflow_paths "test feature" "research-and-plan" >/dev/null 2>&1; then
      # Verify plan path is set
      if [[ -n "${PLAN_PATH:-}" ]] && [[ "$PLAN_PATH" == *"/plans/"* ]]; then
        pass "$test_name"
      else
        fail "$test_name" "PLAN_PATH not set correctly: ${PLAN_PATH:-<empty>}"
      fi
    else
      fail "$test_name" "initialize_workflow_paths returned non-zero"
    fi
  else
    fail "$test_name" "Failed to source workflow-initialization.sh"
  fi

  teardown
}

# Test 3: Full workflow path calculation
test_full_workflow() {
  local test_name="Full workflow path calculation"

  setup

  # Source the library
  if source "${CLAUDE_ROOT}/lib/workflow/workflow-initialization.sh"; then
    # Call the function
    if initialize_workflow_paths "implement authentication" "full-implementation" >/dev/null 2>&1; then
      # Verify all artifact paths are set
      local all_paths_set=true

      if [[ -z "${PLAN_PATH:-}" ]]; then all_paths_set=false; fi
      if [[ -z "${IMPL_ARTIFACTS:-}" ]]; then all_paths_set=false; fi
      if [[ -z "${SUMMARY_PATH:-}" ]]; then all_paths_set=false; fi

      if [[ "$all_paths_set" == "true" ]]; then
        pass "$test_name"
      else
        fail "$test_name" "Not all artifact paths set"
      fi
    else
      fail "$test_name" "initialize_workflow_paths returned non-zero"
    fi
  else
    fail "$test_name" "Failed to source workflow-initialization.sh"
  fi

  teardown
}

# Test 4: Topic directory numbering (gets next available number)
test_topic_directory_numbering() {
  local test_name="Topic directory numbering (gets next available number)"

  setup

  # Create some existing topic directories
  mkdir -p "$TEST_DIR/.claude/specs/001_existing_topic"
  mkdir -p "$TEST_DIR/.claude/specs/002_another_topic"

  # Source the library
  if source "${CLAUDE_ROOT}/lib/workflow/workflow-initialization.sh"; then
    # Call the function
    if initialize_workflow_paths "new topic" "research-only" >/dev/null 2>&1; then
      # Verify topic number is 003
      if [[ "$TOPIC_NUM" == "003" ]]; then
        pass "$test_name"
      else
        fail "$test_name" "Expected TOPIC_NUM=003, got $TOPIC_NUM"
      fi
    else
      fail "$test_name" "initialize_workflow_paths returned non-zero"
    fi
  else
    fail "$test_name" "Failed to source workflow-initialization.sh"
  fi

  teardown
}

# Test 5: Path pre-calculation produces absolute paths
test_absolute_paths() {
  local test_name="Path pre-calculation produces absolute paths"

  setup

  # Source the library
  if source "${CLAUDE_ROOT}/lib/workflow/workflow-initialization.sh"; then
    # Call the function
    if initialize_workflow_paths "test topic" "full-implementation" >/dev/null 2>&1; then
      # Verify all paths are absolute (start with /)
      local all_absolute=true

      if [[ ! "$TOPIC_PATH" =~ ^/ ]]; then all_absolute=false; fi
      if [[ ! "$PLAN_PATH" =~ ^/ ]]; then all_absolute=false; fi
      if [[ ! "$SUMMARY_PATH" =~ ^/ ]]; then all_absolute=false; fi

      # Check report paths
      reconstruct_report_paths_array
      for report_path in "${REPORT_PATHS[@]}"; do
        if [[ ! "$report_path" =~ ^/ ]]; then
          all_absolute=false
          break
        fi
      done

      if [[ "$all_absolute" == "true" ]]; then
        pass "$test_name"
      else
        fail "$test_name" "Some paths are not absolute"
      fi
    else
      fail "$test_name" "initialize_workflow_paths returned non-zero"
    fi
  else
    fail "$test_name" "Failed to source workflow-initialization.sh"
  fi

  teardown
}

# Test 6: Lazy directory creation (only topic root created initially)
test_lazy_directory_creation() {
  local test_name="Lazy directory creation (only topic root created initially)"

  setup

  # Source the library
  if source "${CLAUDE_ROOT}/lib/workflow/workflow-initialization.sh"; then
    # Call the function
    if initialize_workflow_paths "test topic" "full-implementation" >/dev/null 2>&1; then
      # Verify topic root exists
      if [[ ! -d "$TOPIC_PATH" ]]; then
        fail "$test_name" "Topic root directory not created"
        teardown
        return
      fi

      # Verify subdirectories do NOT exist yet (lazy creation)
      local lazy_creation=true

      # These should NOT exist yet
      if [[ -d "${TOPIC_PATH}/plans" ]]; then lazy_creation=false; fi
      if [[ -d "${TOPIC_PATH}/summaries" ]]; then lazy_creation=false; fi
      if [[ -d "${TOPIC_PATH}/debug" ]]; then lazy_creation=false; fi
      if [[ -d "${TOPIC_PATH}/artifacts" ]]; then lazy_creation=false; fi

      if [[ "$lazy_creation" == "true" ]]; then
        pass "$test_name"
      else
        fail "$test_name" "Subdirectories created prematurely (should be lazy)"
      fi
    else
      fail "$test_name" "initialize_workflow_paths returned non-zero"
    fi
  else
    fail "$test_name" "Failed to source workflow-initialization.sh"
  fi

  teardown
}

# Test 7: Missing WORKFLOW_DESCRIPTION parameter
test_missing_workflow_description() {
  local test_name="Missing WORKFLOW_DESCRIPTION parameter"

  setup

  # Source the library
  if source "${CLAUDE_ROOT}/lib/workflow/workflow-initialization.sh"; then
    # Call function without first parameter (should fail)
    if initialize_workflow_paths "" "research-only" >/dev/null 2>&1; then
      fail "$test_name" "Should have failed with empty WORKFLOW_DESCRIPTION"
    else
      pass "$test_name"
    fi
  else
    fail "$test_name" "Failed to source workflow-initialization.sh"
  fi

  teardown
}

# Test 8: Invalid workflow scope
test_invalid_workflow_scope() {
  local test_name="Invalid workflow scope"

  setup

  # Source the library
  if source "${CLAUDE_ROOT}/lib/workflow/workflow-initialization.sh"; then
    # Call function with invalid scope
    if initialize_workflow_paths "test topic" "invalid-scope" >/dev/null 2>&1; then
      fail "$test_name" "Should have failed with invalid workflow scope"
    else
      pass "$test_name"
    fi
  else
    fail "$test_name" "Failed to source workflow-initialization.sh"
  fi

  teardown
}

# Test 9: Debug-only workflow path calculation
test_debug_only_workflow() {
  local test_name="Debug-only workflow path calculation"

  setup

  # Source the library
  if source "${CLAUDE_ROOT}/lib/workflow/workflow-initialization.sh"; then
    # Call the function
    if initialize_workflow_paths "debug auth issue" "debug-only" >/dev/null 2>&1; then
      # Verify debug report path is set
      if [[ -n "${DEBUG_REPORT:-}" ]] && [[ "$DEBUG_REPORT" == *"/debug/"* ]]; then
        pass "$test_name"
      else
        fail "$test_name" "DEBUG_REPORT not set correctly: ${DEBUG_REPORT:-<empty>}"
      fi
    else
      fail "$test_name" "initialize_workflow_paths returned non-zero"
    fi
  else
    fail "$test_name" "Failed to source workflow-initialization.sh"
  fi

  teardown
}

# Test 9a: Research-and-revise workflow validation (Issue #661 regression test)
test_research_and_revise_workflow() {
  local test_name="Research-and-revise workflow validation"

  setup

  # Create mock plan file for revision workflow
  # Note: Topic name is calculated from description, so create directory matching calculated name
  mkdir -p "${TEST_DIR}/.claude/specs/657_revise_test_topic/plans"
  local mock_plan="${TEST_DIR}/.claude/specs/657_revise_test_topic/plans/001_existing_plan.md"
  echo "# Test Plan" > "$mock_plan"

  # Source the library
  if source "${CLAUDE_ROOT}/lib/workflow/workflow-initialization.sh"; then
    # Simulate scope detection: export EXISTING_PLAN_PATH as scope detection would
    export EXISTING_PLAN_PATH="$mock_plan"

    # Call the function with revision workflow description
    if initialize_workflow_paths "Revise the plan $mock_plan to accommodate changes" "research-and-revise" >/dev/null 2>&1; then
      # Verify EXISTING_PLAN_PATH is still set (specific to revision workflows)
      if [[ -n "${EXISTING_PLAN_PATH:-}" ]] && [[ -f "${EXISTING_PLAN_PATH}" ]]; then
        pass "$test_name"
      else
        fail "$test_name" "EXISTING_PLAN_PATH not set or file doesn't exist: ${EXISTING_PLAN_PATH:-<empty>}"
      fi
    else
      fail "$test_name" "initialize_workflow_paths returned non-zero for research-and-revise scope"
    fi
  else
    fail "$test_name" "Failed to source workflow-initialization.sh"
  fi

  teardown
}

# Test 10: Report paths array reconstruction
test_report_paths_reconstruction() {
  local test_name="Report paths array reconstruction"

  setup

  # Source the library
  if source "${CLAUDE_ROOT}/lib/workflow/workflow-initialization.sh"; then
    # Call the function with research_complexity=4
    if initialize_workflow_paths "test topic" "research-only" 4 >/dev/null 2>&1; then
      # Reconstruct array
      reconstruct_report_paths_array

      # Verify array has 4 elements (specified research_complexity)
      if [[ "${#REPORT_PATHS[@]}" -eq 4 ]]; then
        pass "$test_name"
      else
        fail "$test_name" "Expected 4 report paths, got ${#REPORT_PATHS[@]}"
      fi
    else
      fail "$test_name" "initialize_workflow_paths returned non-zero"
    fi
  else
    fail "$test_name" "Failed to source workflow-initialization.sh"
  fi

  teardown
}

# Test 11: Topic name sanitization
test_topic_name_sanitization() {
  local test_name="Topic name sanitization"

  setup

  # Source the library
  if source "${CLAUDE_ROOT}/lib/workflow/workflow-initialization.sh"; then
    # Call function with special characters in description
    if initialize_workflow_paths "Test Topic With Spaces & Special!@#" "research-only" >/dev/null 2>&1; then
      # Verify topic name is sanitized (lowercase, underscores, no special chars)
      if [[ "$TOPIC_NAME" =~ ^[a-z0-9_]+$ ]]; then
        pass "$test_name"
      else
        fail "$test_name" "Topic name not properly sanitized: $TOPIC_NAME"
      fi
    else
      fail "$test_name" "initialize_workflow_paths returned non-zero"
    fi
  else
    fail "$test_name" "Failed to source workflow-initialization.sh"
  fi

  teardown
}

# Test 12: Tracking variables initialized
test_tracking_variables() {
  local test_name="Tracking variables initialized"

  setup

  # Source the library
  if source "${CLAUDE_ROOT}/lib/workflow/workflow-initialization.sh"; then
    # Call the function
    if initialize_workflow_paths "test topic" "full-implementation" >/dev/null 2>&1; then
      # Verify tracking variables are set
      local all_tracking_set=true

      if [[ -z "${SUCCESSFUL_REPORT_COUNT:-}" ]]; then all_tracking_set=false; fi
      if [[ -z "${TESTS_PASSING:-}" ]]; then all_tracking_set=false; fi
      if [[ -z "${IMPLEMENTATION_OCCURRED:-}" ]]; then all_tracking_set=false; fi

      # Verify initial values
      if [[ "$SUCCESSFUL_REPORT_COUNT" != "0" ]]; then all_tracking_set=false; fi
      if [[ "$TESTS_PASSING" != "unknown" ]]; then all_tracking_set=false; fi
      if [[ "$IMPLEMENTATION_OCCURRED" != "false" ]]; then all_tracking_set=false; fi

      if [[ "$all_tracking_set" == "true" ]]; then
        pass "$test_name"
      else
        fail "$test_name" "Tracking variables not initialized correctly"
      fi
    else
      fail "$test_name" "initialize_workflow_paths returned non-zero"
    fi
  else
    fail "$test_name" "Failed to source workflow-initialization.sh"
  fi

  teardown
}

# ==============================================================================
# Phase 4: Comprehensive Regression Tests for Issue #661
# ==============================================================================

# Test: extract_topic_from_plan_path() with valid path
test_extract_topic_valid_path() {
  local test_name="extract_topic_from_plan_path with valid path"

  setup

  # Create mock plan file
  mkdir -p "${TEST_DIR}/.claude/specs/657_test_topic/plans"
  local mock_plan="${TEST_DIR}/.claude/specs/657_test_topic/plans/001_test_plan.md"
  echo "# Test Plan" > "$mock_plan"

  # Source the library
  if source "${CLAUDE_ROOT}/lib/workflow/workflow-initialization.sh"; then
    # Call extraction function
    local extracted_topic
    extracted_topic=$(extract_topic_from_plan_path "$mock_plan" 2>/dev/null)

    if [[ "$extracted_topic" == "657_test_topic" ]]; then
      pass "$test_name"
    else
      fail "$test_name" "Expected '657_test_topic', got '$extracted_topic'"
    fi
  else
    fail "$test_name" "Failed to source workflow-initialization.sh"
  fi

  teardown
}

# Test: extract_topic_from_plan_path() with non-existent path
test_extract_topic_nonexistent_path() {
  local test_name="extract_topic_from_plan_path with non-existent path"

  setup

  # Source the library
  if source "${CLAUDE_ROOT}/lib/workflow/workflow-initialization.sh"; then
    # Call extraction function with non-existent path (should fail)
    if extract_topic_from_plan_path "/nonexistent/path/specs/657_topic/plans/001_plan.md" >/dev/null 2>&1; then
      fail "$test_name" "Function should fail for non-existent path"
    else
      pass "$test_name"
    fi
  else
    fail "$test_name" "Failed to source workflow-initialization.sh"
  fi

  teardown
}

# Test: extract_topic_from_plan_path() with malformed path
test_extract_topic_malformed_path() {
  local test_name="extract_topic_from_plan_path with malformed path"

  setup

  # Create mock file with wrong structure
  mkdir -p "${TEST_DIR}/.claude/specs/invalid_name"
  local mock_plan="${TEST_DIR}/.claude/specs/invalid_name/001_plan.md"
  echo "# Test Plan" > "$mock_plan"

  # Source the library
  if source "${CLAUDE_ROOT}/lib/workflow/workflow-initialization.sh"; then
    # Call extraction function with malformed path (should fail)
    if extract_topic_from_plan_path "$mock_plan" >/dev/null 2>&1; then
      fail "$test_name" "Function should fail for malformed path"
    else
      pass "$test_name"
    fi
  else
    fail "$test_name" "Failed to source workflow-initialization.sh"
  fi

  teardown
}

# Test: Revision workflow with full plan path
test_revision_full_plan_path() {
  local test_name="Revision workflow with full plan path"

  setup

  # Create mock plan file
  mkdir -p "${TEST_DIR}/.claude/specs/657_full_path_test/plans"
  local mock_plan="${TEST_DIR}/.claude/specs/657_full_path_test/plans/001_test_plan.md"
  echo "# Test Plan" > "$mock_plan"

  # Source the library
  if source "${CLAUDE_ROOT}/lib/workflow/workflow-initialization.sh"; then
    # Simulate scope detection
    export EXISTING_PLAN_PATH="$mock_plan"

    # Call initialization with full path
    if initialize_workflow_paths "Revise $mock_plan to accommodate changes" "research-and-revise" >/dev/null 2>&1; then
      # Verify topic path uses extracted directory (not creates new one)
      if [[ "$TOPIC_PATH" == *"657_full_path_test"* ]] && [[ "$TOPIC_NAME" == "657_full_path_test" ]]; then
        pass "$test_name"
      else
        fail "$test_name" "Expected extracted topic '657_full_path_test', got TOPIC_PATH='$TOPIC_PATH' TOPIC_NAME='$TOPIC_NAME'"
      fi
    else
      fail "$test_name" "initialize_workflow_paths returned non-zero"
    fi
  else
    fail "$test_name" "Failed to source workflow-initialization.sh"
  fi

  teardown
}

# Test: Revision workflow with "the plan" syntax
test_revision_the_plan_syntax() {
  local test_name="Revision workflow with 'the plan' syntax"

  setup

  # Create mock plan file
  mkdir -p "${TEST_DIR}/.claude/specs/658_the_plan_test/plans"
  local mock_plan="${TEST_DIR}/.claude/specs/658_the_plan_test/plans/001_test_plan.md"
  echo "# Test Plan" > "$mock_plan"

  # Source the library
  if source "${CLAUDE_ROOT}/lib/workflow/workflow-initialization.sh"; then
    # Simulate scope detection
    export EXISTING_PLAN_PATH="$mock_plan"

    # Call initialization with "the plan" syntax
    if initialize_workflow_paths "Revise the plan $mock_plan to accommodate new features" "research-and-revise" >/dev/null 2>&1; then
      # Verify topic path uses extracted directory
      if [[ "$TOPIC_PATH" == *"658_the_plan_test"* ]] && [[ "$TOPIC_NAME" == "658_the_plan_test" ]]; then
        pass "$test_name"
      else
        fail "$test_name" "Expected extracted topic '658_the_plan_test', got TOPIC_PATH='$TOPIC_PATH' TOPIC_NAME='$TOPIC_NAME'"
      fi
    else
      fail "$test_name" "initialize_workflow_paths returned non-zero"
    fi
  else
    fail "$test_name" "Failed to source workflow-initialization.sh"
  fi

  teardown
}

# Test: Revision workflow without plan path (should fail)
test_revision_without_plan_path() {
  local test_name="Revision workflow without plan path (should fail)"

  setup

  # Source the library
  if source "${CLAUDE_ROOT}/lib/workflow/workflow-initialization.sh"; then
    # Don't set EXISTING_PLAN_PATH (simulates missing path)
    unset EXISTING_PLAN_PATH

    # Call initialization without plan path (should fail with clear error)
    if initialize_workflow_paths "Revise some plan to accommodate changes" "research-and-revise" 2>/dev/null; then
      fail "$test_name" "Function should fail when EXISTING_PLAN_PATH not set"
    else
      # Verify it failed as expected
      pass "$test_name"
    fi
  else
    fail "$test_name" "Failed to source workflow-initialization.sh"
  fi

  teardown
}

# Test: Revision workflow with non-existent plan (should fail with diagnostic)
test_revision_nonexistent_plan() {
  local test_name="Revision workflow with non-existent plan (should fail with diagnostic)"

  setup

  # Source the library
  if source "${CLAUDE_ROOT}/lib/workflow/workflow-initialization.sh"; then
    # Set EXISTING_PLAN_PATH to non-existent file
    export EXISTING_PLAN_PATH="/nonexistent/specs/657_topic/plans/001_plan.md"

    # Call initialization (should fail with diagnostic info)
    if initialize_workflow_paths "Revise /nonexistent/specs/657_topic/plans/001_plan.md" "research-and-revise" 2>/dev/null; then
      fail "$test_name" "Function should fail when plan file doesn't exist"
    else
      # Verify it failed as expected
      pass "$test_name"
    fi
  else
    fail "$test_name" "Failed to source workflow-initialization.sh"
  fi

  teardown
}

# Test: Verify error messages contain diagnostic information
test_revision_error_messages() {
  local test_name="Verify error messages contain diagnostic information"

  setup

  # Source the library
  if source "${CLAUDE_ROOT}/lib/workflow/workflow-initialization.sh"; then
    # Don't set EXISTING_PLAN_PATH
    unset EXISTING_PLAN_PATH

    # Capture error output
    local error_output
    error_output=$(initialize_workflow_paths "Revise plan" "research-and-revise" 2>&1 || true)

    # Verify error message contains diagnostic information (Root cause + Solution)
    if echo "$error_output" | grep -qi "Root cause" && echo "$error_output" | grep -qi "Solution"; then
      pass "$test_name"
    else
      fail "$test_name" "Error message missing diagnostic information. Got: $error_output"
    fi
  else
    fail "$test_name" "Failed to source workflow-initialization.sh"
  fi

  teardown
}

# Run all tests
echo "Running workflow-initialization.sh unit tests..."
echo "================================================="

test_research_only_workflow
test_research_and_plan_workflow
test_full_workflow
test_topic_directory_numbering
test_absolute_paths
test_lazy_directory_creation
test_missing_workflow_description
test_invalid_workflow_scope
test_debug_only_workflow
test_research_and_revise_workflow
test_report_paths_reconstruction
test_topic_name_sanitization
test_tracking_variables

# Phase 4 regression tests
test_extract_topic_valid_path
test_extract_topic_nonexistent_path
test_extract_topic_malformed_path
test_revision_full_plan_path
test_revision_the_plan_syntax
test_revision_without_plan_path
test_revision_nonexistent_plan
test_revision_error_messages

# Summary
echo ""
echo "================================================="
echo "Test Summary:"
echo "  Total: $TESTS_RUN"
echo -e "  ${GREEN}Passed${NC}: $TESTS_PASSED"
echo -e "  ${RED}Failed${NC}: $TESTS_FAILED"

# Calculate coverage
if [[ $TESTS_RUN -gt 0 ]]; then
  coverage=$((TESTS_PASSED * 100 / TESTS_RUN))
  echo "  Coverage: ${coverage}%"

  if [[ $coverage -ge 80 ]]; then
    echo -e "  ${GREEN}✓ Coverage target met (≥80%)${NC}"
  else
    echo -e "  ${YELLOW}⚠ Coverage below target (<80%)${NC}"
  fi
fi

# Exit with appropriate code
if [[ $TESTS_FAILED -gt 0 ]]; then
  exit 1
else
  exit 0
fi
