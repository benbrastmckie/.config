#!/usr/bin/env bash
# Test suite for coordinate error fixes (Spec 652, 665)
# Tests critical error scenarios:
# - Spec 652: JSON parsing, state verification, state transitions
# - Spec 665: research-and-revise workflow, EXISTING_PLAN_PATH persistence, agent delegation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

TESTS_PASSED=0
TESTS_FAILED=0

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "${PROJECT_ROOT}/.claude/lib/state-persistence.sh"
source "${PROJECT_ROOT}/.claude/lib/verification-helpers.sh"

print_test_header() {
  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "Test: $1"
  echo "═══════════════════════════════════════════════════════"
}

pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  TESTS_FAILED=$((TESTS_FAILED + 1))
}

# ==============================================================================
# Test 1: Empty Report Paths (JSON Creation)
# ==============================================================================
test_empty_report_paths_creation() {
  print_test_header "Empty Report Paths (JSON Creation)"

  # Test empty array case
  SUCCESSFUL_REPORT_PATHS=()

  # Execute JSON creation code (from coordinate.md line 605-609)
  if [ ${#SUCCESSFUL_REPORT_PATHS[@]} -eq 0 ]; then
    REPORT_PATHS_JSON="[]"
  else
    REPORT_PATHS_JSON="$(printf '%s\n' "${SUCCESSFUL_REPORT_PATHS[@]}" | jq -R . | jq -s .)"
  fi

  # Verify result
  if [ "$REPORT_PATHS_JSON" = "[]" ]; then
    pass "Empty array creates valid JSON '[]'"
  else
    fail "Empty array did not create '[]', got: $REPORT_PATHS_JSON"
  fi

  # Test with actual paths
  SUCCESSFUL_REPORT_PATHS=("/path/to/report1.md" "/path/to/report2.md")
  REPORT_PATHS_JSON="$(printf '%s\n' "${SUCCESSFUL_REPORT_PATHS[@]}" | jq -R . | jq -s .)"

  if echo "$REPORT_PATHS_JSON" | jq empty 2>/dev/null; then
    pass "Valid paths create parseable JSON"
  else
    fail "Valid paths did not create parseable JSON"
  fi
}

# ==============================================================================
# Test 2: Empty Report Paths (JSON Loading)
# ==============================================================================
test_empty_report_paths_loading() {
  print_test_header "Empty Report Paths (JSON Loading)"

  # Test with empty JSON
  REPORT_PATHS_JSON="[]"
  if [ -n "${REPORT_PATHS_JSON:-}" ]; then
    if echo "$REPORT_PATHS_JSON" | jq empty 2>/dev/null; then
      mapfile -t REPORT_PATHS < <(echo "$REPORT_PATHS_JSON" | jq -r '.[]')
    else
      REPORT_PATHS=()
    fi
  else
    REPORT_PATHS=()
  fi

  if [ ${#REPORT_PATHS[@]} -eq 0 ]; then
    pass "Empty JSON array loads as empty bash array"
  else
    fail "Empty JSON array did not load correctly"
  fi
}

# ==============================================================================
# Test 3: Malformed JSON Recovery
# ==============================================================================
test_malformed_json_recovery() {
  print_test_header "Malformed JSON Recovery"

  # Test malformed JSON
  REPORT_PATHS_JSON="invalid json {not valid"

  if [ -n "${REPORT_PATHS_JSON:-}" ]; then
    if echo "$REPORT_PATHS_JSON" | jq empty 2>/dev/null; then
      mapfile -t REPORT_PATHS < <(echo "$REPORT_PATHS_JSON" | jq -r '.[]')
    else
      REPORT_PATHS=()
    fi
  else
    REPORT_PATHS=()
  fi

  if [ ${#REPORT_PATHS[@]} -eq 0 ]; then
    pass "Malformed JSON falls back to empty array"
  else
    fail "Malformed JSON did not fall back correctly"
  fi

  # Test unset JSON
  unset REPORT_PATHS_JSON
  if [ -n "${REPORT_PATHS_JSON:-}" ]; then
    if echo "$REPORT_PATHS_JSON" | jq empty 2>/dev/null; then
      mapfile -t REPORT_PATHS < <(echo "$REPORT_PATHS_JSON" | jq -r '.[]')
    else
      REPORT_PATHS=()
    fi
  else
    REPORT_PATHS=()
  fi

  if [ ${#REPORT_PATHS[@]} -eq 0 ]; then
    pass "Unset REPORT_PATHS_JSON falls back to empty array"
  else
    fail "Unset REPORT_PATHS_JSON did not fall back correctly"
  fi
}

# ==============================================================================
# Test 4: Missing State File
# ==============================================================================
test_missing_state_file() {
  print_test_header "Missing State File Detection"

  # Test with nonexistent state file
  NONEXISTENT_FILE="/tmp/test_nonexistent_state_file_$$.state"
  VARS_TO_CHECK=("TEST_VAR1" "TEST_VAR2")

  # This should fail gracefully with error message
  if verify_state_variables "$NONEXISTENT_FILE" "${VARS_TO_CHECK[@]}" 2>/dev/null; then
    fail "verify_state_variables should have failed for missing file"
  else
    pass "verify_state_variables correctly detects missing state file"
  fi
}

# ==============================================================================
# Test 5: State Transitions
# ==============================================================================
test_state_transitions() {
  print_test_header "State Transitions"

  # Source state machine library
  source "${PROJECT_ROOT}/.claude/lib/workflow-state-machine.sh"

  # Initialize state machine
  sm_init "Test workflow" "coordinate"

  if [ "$CURRENT_STATE" = "initialize" ]; then
    pass "State machine initializes to 'initialize' state"
  else
    fail "State machine did not initialize correctly, got: $CURRENT_STATE"
  fi

  # Test research transition
  sm_transition "$STATE_RESEARCH"
  if [ "$CURRENT_STATE" = "$STATE_RESEARCH" ]; then
    pass "Transition to research state works"
  else
    fail "Research transition failed, current state: $CURRENT_STATE"
  fi

  # Test plan transition
  sm_transition "$STATE_PLAN"
  if [ "$CURRENT_STATE" = "$STATE_PLAN" ]; then
    pass "Transition to plan state works"
  else
    fail "Plan transition failed, current state: $CURRENT_STATE"
  fi

  # Test implement transition
  sm_transition "$STATE_IMPLEMENT"
  if [ "$CURRENT_STATE" = "$STATE_IMPLEMENT" ]; then
    pass "Transition to implement state works"
  else
    fail "Implement transition failed, current state: $CURRENT_STATE"
  fi
}

# ==============================================================================
# Test 6: State File Existence Check
# ==============================================================================
test_state_file_with_content() {
  print_test_header "State File with Content"

  # Create temporary state file
  TEMP_STATE_FILE="/tmp/test_state_file_$$.state"
  cat > "$TEMP_STATE_FILE" <<EOF
export TEST_VAR1="value1"
export TEST_VAR2="value2"
export TEST_VAR3="value3"
EOF

  VARS_TO_CHECK=("TEST_VAR1" "TEST_VAR2" "TEST_VAR3")

  # This should succeed
  if verify_state_variables "$TEMP_STATE_FILE" "${VARS_TO_CHECK[@]}" >/dev/null 2>&1; then
    pass "verify_state_variables works with valid state file"
  else
    fail "verify_state_variables failed with valid state file"
  fi

  # Test missing variable
  VARS_TO_CHECK=("TEST_VAR1" "MISSING_VAR")
  if verify_state_variables "$TEMP_STATE_FILE" "${VARS_TO_CHECK[@]}" >/dev/null 2>&1; then
    fail "verify_state_variables should have failed for missing variable"
  else
    pass "verify_state_variables correctly detects missing variable"
  fi

  # Cleanup
  rm -f "$TEMP_STATE_FILE"
}

# ==============================================================================
# Test 7: Scope Detection for research-and-revise (Spec 665)
# ==============================================================================
test_scope_detection_research_and_revise() {
  print_test_header "Scope Detection: research-and-revise"

  source "${PROJECT_ROOT}/.claude/lib/workflow-scope-detection.sh"

  # Test research-and-revise pattern
  workflow_desc="Revise the plan /path/to/specs/042_auth/plans/001_plan.md to accommodate research findings"
  scope=$(detect_workflow_scope "$workflow_desc")

  if [ "$scope" = "research-and-revise" ]; then
    pass "Scope detection identifies research-and-revise pattern"
  else
    fail "Expected 'research-and-revise', got '$scope'"
  fi

  # Test research-and-plan (should not match revise)
  workflow_desc="Research authentication patterns and create implementation plan"
  scope=$(detect_workflow_scope "$workflow_desc")

  if [ "$scope" != "research-and-revise" ]; then
    pass "Scope detection distinguishes research-and-plan from research-and-revise"
  else
    fail "Incorrectly detected research-and-plan as research-and-revise"
  fi
}

# ==============================================================================
# Test 8: Path Extraction from Workflow Description (Spec 665)
# ==============================================================================
test_path_extraction_from_description() {
  print_test_header "Path Extraction from Workflow Description"

  # Create test plan for realistic path
  TEST_PLAN_PATH="/tmp/test_specs_$$/042_test/plans/001_test_plan.md"
  mkdir -p "$(dirname "$TEST_PLAN_PATH")"
  touch "$TEST_PLAN_PATH"

  workflow_desc="Revise the plan ${TEST_PLAN_PATH} to accommodate changes"
  extracted_path=$(echo "$workflow_desc" | grep -oE "/[^ ]+\.md" | head -1)

  if [ "$extracted_path" = "$TEST_PLAN_PATH" ]; then
    pass "Path extraction works for full absolute paths"
  else
    fail "Expected '$TEST_PLAN_PATH', got '$extracted_path'"
  fi

  # Cleanup
  rm -rf "/tmp/test_specs_$$"
}

# ==============================================================================
# Test 9: EXISTING_PLAN_PATH Persistence to State (Spec 665)
# ==============================================================================
test_existing_plan_path_in_state() {
  print_test_header "EXISTING_PLAN_PATH Persistence to State"

  # Create test state
  WORKFLOW_DESC="Revise the plan /tmp/test_plan.md to accommodate changes"
  WORKFLOW_ID="test_coordinate_$$"
  STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")

  # Simulate extraction and persistence (from coordinate.md Phase 1 fix)
  EXISTING_PLAN_PATH=$(echo "$WORKFLOW_DESC" | grep -oE "/[^ ]+\.md" | head -1)
  append_workflow_state "EXISTING_PLAN_PATH" "$EXISTING_PLAN_PATH"

  # Verify state file contains variable (check for export format)
  if grep -q "export EXISTING_PLAN_PATH=\"/tmp/test_plan.md\"" "$STATE_FILE" || \
     grep -q "EXISTING_PLAN_PATH=/tmp/test_plan.md" "$STATE_FILE"; then
    pass "EXISTING_PLAN_PATH successfully saved to workflow state"
  else
    fail "EXISTING_PLAN_PATH not found in state file"
    echo "State file contents:" >&2
    cat "$STATE_FILE" >&2
  fi

  # Cleanup
  rm -f "$STATE_FILE"
}

# ==============================================================================
# Test 10: Agent Delegation (Task tool vs SlashCommand) (Spec 665)
# ==============================================================================
test_planning_phase_uses_agent_delegation() {
  print_test_header "Agent Delegation Pattern (Standard 11 Compliance)"

  # Read planning phase section from coordinate.md
  PLANNING_SECTION=$(sed -n '/## State Handler: Planning Phase/,/## State Handler: Implementation Phase/p' \
    "${PROJECT_ROOT}/.claude/commands/coordinate.md")

  # Test 1: Verify Task invocation exists
  if echo "$PLANNING_SECTION" | grep -q "Task {"; then
    pass "Planning phase contains Task tool invocation"
  else
    fail "Task tool invocation not found in planning phase"
  fi

  # Test 2: Verify references revision-specialist.md
  if echo "$PLANNING_SECTION" | grep -q "revision-specialist.md"; then
    pass "Planning phase references revision-specialist.md behavioral file"
  else
    fail "revision-specialist.md reference missing"
  fi

  # Test 3: Verify does NOT invoke /revise SlashCommand
  # Check for actual invocation (not just warning text about NOT using it)
  if ! echo "$PLANNING_SECTION" | grep -E "USE.*SlashCommand|invoke.*revise|SlashCommand.*\{.*revise" | grep -v "NOT.*SlashCommand" | grep -q "."; then
    pass "No /revise SlashCommand invocation (uses Task tool instead)"
  else
    fail "Found /revise SlashCommand invocation (violates Standard 11)"
    echo "Matched lines:" >&2
    echo "$PLANNING_SECTION" | grep -E "USE.*SlashCommand|invoke.*revise|SlashCommand.*\{.*revise" | grep -v "NOT.*SlashCommand" >&2
  fi

  # Test 4: Verify CRITICAL enforcement language present
  if echo "$PLANNING_SECTION" | grep -q "CRITICAL.*MUST use Task tool"; then
    pass "CRITICAL enforcement language present for Standard 11"
  else
    fail "CRITICAL enforcement language missing"
  fi
}

# ==============================================================================
# Test 11: research-and-revise in Library Sourcing (Spec 665)
# ==============================================================================
test_research_and_revise_library_sourcing() {
  print_test_header "research-and-revise Scope in Library Sourcing"

  # Check coordinate.md has research-and-revise in library sourcing case statement
  SOURCING_SECTION=$(sed -n '/case "$WORKFLOW_SCOPE" in/,/esac/p' \
    "${PROJECT_ROOT}/.claude/commands/coordinate.md" | head -20)

  if echo "$SOURCING_SECTION" | grep -q "research-and-plan|research-and-revise"; then
    pass "research-and-revise scope included in library sourcing"
  else
    fail "research-and-revise scope missing from library sourcing case statement"
  fi
}

# ==============================================================================
# Run All Tests
# ==============================================================================
echo "Running Coordinate Error Fixes Test Suite"
echo "=========================================="

test_empty_report_paths_creation
test_empty_report_paths_loading
test_malformed_json_recovery
test_missing_state_file
test_state_transitions
test_state_file_with_content
test_scope_detection_research_and_revise
test_path_extraction_from_description
test_existing_plan_path_in_state
test_planning_phase_uses_agent_delegation
test_research_and_revise_library_sourcing

# ==============================================================================
# Test Suite: Phase 1 - Defensive Array Reconstruction Pattern (Spec 672)
# ==============================================================================

# Source workflow-initialization.sh for Phase 1 functions
source "${PROJECT_ROOT}/.claude/lib/workflow-initialization.sh"

test_phase1_basic_array_reconstruction() {
  print_test_header "Phase 1.1: Basic Array Reconstruction"

  # Setup test state
  export TEST_ARRAY_0="value0"
  export TEST_ARRAY_1="value1"
  export TEST_ARRAY_2="value2"
  export TEST_ARRAY_COUNT=3

  # Execute function
  reconstruct_array_from_indexed_vars "TEST_ARRAY" "TEST_ARRAY_COUNT"

  # Verify results
  if [ "${#TEST_ARRAY[@]}" -eq 3 ] && \
     [ "${TEST_ARRAY[0]}" = "value0" ] && \
     [ "${TEST_ARRAY[1]}" = "value1" ] && \
     [ "${TEST_ARRAY[2]}" = "value2" ]; then
    pass "Basic array reconstruction with all variables present"
  else
    fail "Basic array reconstruction failed (expected 3 elements)"
  fi

  # Cleanup
  unset TEST_ARRAY TEST_ARRAY_0 TEST_ARRAY_1 TEST_ARRAY_2 TEST_ARRAY_COUNT
}

test_phase1_missing_count_variable() {
  print_test_header "Phase 1.2: Missing Count Variable"

  # Setup: NO count variable set
  export TEST_ARRAY_0="value0"

  # Execute function (should not crash) - capture stderr to temp file to avoid subshell
  local temp_output="/tmp/test_array_output_$$.txt"
  reconstruct_array_from_indexed_vars "TEST_ARRAY" "MISSING_COUNT" 2>"$temp_output" || true

  # Verify warning message present
  if grep -q "WARNING.*MISSING_COUNT not set" "$temp_output"; then
    pass "Missing count variable triggers warning"
  else
    fail "Missing count variable should trigger warning"
  fi
  rm -f "$temp_output"

  # Verify array is empty (defensive default)
  if declare -p TEST_ARRAY &>/dev/null && [ "${#TEST_ARRAY[@]}" -eq 0 ]; then
    pass "Missing count variable defaults to empty array"
  else
    fail "Expected empty array, array not properly initialized"
  fi

  # Cleanup
  unset TEST_ARRAY TEST_ARRAY_0
}

test_phase1_missing_indexed_variable() {
  print_test_header "Phase 1.3: Missing Indexed Variable"

  # Setup: Skip index 1
  export TEST_ARRAY_0="value0"
  # TEST_ARRAY_1 intentionally not set
  export TEST_ARRAY_2="value2"
  export TEST_ARRAY_COUNT=3

  # Execute function - capture stderr to temp file to avoid subshell
  local temp_output="/tmp/test_array_output_$$.txt"
  reconstruct_array_from_indexed_vars "TEST_ARRAY" "TEST_ARRAY_COUNT" 2>"$temp_output" || true

  # Verify warning for missing variable
  if grep -q "WARNING.*TEST_ARRAY_1 not set" "$temp_output"; then
    pass "Missing indexed variable triggers warning"
  else
    fail "Missing indexed variable should trigger warning"
  fi
  rm -f "$temp_output"

  # Verify array contains only present values (skips missing index)
  if [ "${#TEST_ARRAY[@]}" -eq 2 ] && \
     [ "${TEST_ARRAY[0]}" = "value0" ] && \
     [ "${TEST_ARRAY[1]}" = "value2" ]; then
    pass "Missing indexed variable skipped gracefully"
  else
    fail "Array reconstruction should skip missing variables (expected 2 elements, got ${#TEST_ARRAY[@]})"
  fi

  # Cleanup
  unset TEST_ARRAY TEST_ARRAY_0 TEST_ARRAY_2 TEST_ARRAY_COUNT
}

test_phase1_report_paths_integration() {
  print_test_header "Phase 1.6: REPORT_PATHS Integration"

  # Setup state variables for REPORT_PATHS
  export REPORT_PATH_0="/path/to/report1.md"
  export REPORT_PATH_1="/path/to/report2.md"
  export REPORT_PATHS_COUNT=2

  # Execute the refactored function
  reconstruct_report_paths_array

  # Verify array populated correctly
  if [ "${#REPORT_PATHS[@]}" -eq 2 ] && \
     [ "${REPORT_PATHS[0]}" = "/path/to/report1.md" ] && \
     [ "${REPORT_PATHS[1]}" = "/path/to/report2.md" ]; then
    pass "REPORT_PATHS array integration with generic reconstruction"
  else
    fail "REPORT_PATHS integration failed (expected 2 elements)"
  fi

  # Cleanup
  unset REPORT_PATHS REPORT_PATH_0 REPORT_PATH_1 REPORT_PATHS_COUNT
}

# Run Phase 1 tests
test_phase1_basic_array_reconstruction
test_phase1_missing_count_variable
test_phase1_missing_indexed_variable
test_phase1_report_paths_integration

# ==============================================================================
# Test Suite: Phase 2 - COMPLETED_STATES Array Persistence (Spec 672)
# ==============================================================================

# Source workflow-state-machine.sh for Phase 2 functions
source "${PROJECT_ROOT}/.claude/lib/workflow-state-machine.sh"

test_phase2_save_completed_states() {
  print_test_header "Phase 2.1: Save COMPLETED_STATES to State"

  # Setup: Initialize test state file
  local test_state_file="/tmp/test_state_$$.txt"
  export STATE_FILE="$test_state_file"

  # Create minimal append_workflow_state function for testing
  append_workflow_state() {
    local key="$1"
    local value="$2"
    echo "export ${key}='${value}'" >> "$STATE_FILE"
  }
  export -f append_workflow_state

  # Setup COMPLETED_STATES array
  COMPLETED_STATES=("initialize" "research" "plan")

  # Execute save function
  save_completed_states_to_state

  # Verify state file contains JSON and count
  if grep -q 'COMPLETED_STATES_JSON' "$test_state_file" && \
     grep -q 'COMPLETED_STATES_COUNT' "$test_state_file"; then
    pass "COMPLETED_STATES saved to state file"
  else
    fail "COMPLETED_STATES not saved to state file"
  fi

  # Verify JSON content
  if grep -q '["initialize","research","plan"]' "$test_state_file"; then
    pass "COMPLETED_STATES JSON content correct"
  else
    fail "COMPLETED_STATES JSON content incorrect"
  fi

  # Cleanup
  rm -f "$test_state_file"
  unset STATE_FILE append_workflow_state
  COMPLETED_STATES=()
}

test_phase2_load_completed_states() {
  print_test_header "Phase 2.2: Load COMPLETED_STATES from State"

  # Setup: Create test state with COMPLETED_STATES
  export COMPLETED_STATES_JSON='["initialize","research"]'
  export COMPLETED_STATES_COUNT=2

  # Clear current array
  COMPLETED_STATES=()

  # Execute load function
  load_completed_states_from_state

  # Verify array reconstructed correctly
  if [ "${#COMPLETED_STATES[@]}" -eq 2 ] && \
     [ "${COMPLETED_STATES[0]}" = "initialize" ] && \
     [ "${COMPLETED_STATES[1]}" = "research" ]; then
    pass "COMPLETED_STATES loaded from state correctly"
  else
    fail "COMPLETED_STATES load failed (expected 2 elements: initialize, research)"
  fi

  # Cleanup
  unset COMPLETED_STATES_JSON COMPLETED_STATES_COUNT
  COMPLETED_STATES=()
}

test_phase2_empty_array_handling() {
  print_test_header "Phase 2.3: Empty COMPLETED_STATES Array"

  # Setup: Initialize test state file
  local test_state_file="/tmp/test_state_$$.txt"
  export STATE_FILE="$test_state_file"

  append_workflow_state() {
    local key="$1"
    local value="$2"
    echo "export ${key}='${value}'" >> "$STATE_FILE"
  }
  export -f append_workflow_state

  # Setup empty array
  COMPLETED_STATES=()

  # Execute save function
  save_completed_states_to_state

  # Verify empty array JSON
  if grep -q 'COMPLETED_STATES_JSON=.\[\]' "$test_state_file"; then
    pass "Empty COMPLETED_STATES array saved as []"
  else
    fail "Empty array not saved correctly"
  fi

  # Cleanup
  rm -f "$test_state_file"
  unset STATE_FILE append_workflow_state
}

test_phase2_state_machine_integration() {
  print_test_header "Phase 2.4: State Machine Integration"

  # Setup: Initialize minimal state file infrastructure
  local test_state_file="/tmp/test_state_$$.txt"
  export STATE_FILE="$test_state_file"

  append_workflow_state() {
    local key="$1"
    local value="$2"
    echo "export ${key}='${value}'" >> "$STATE_FILE"
  }
  export -f append_workflow_state

  # Initialize state machine
  sm_init "test workflow" "coordinate"

  # Perform state transition (should save COMPLETED_STATES)
  sm_transition "$STATE_RESEARCH"

  # Verify COMPLETED_STATES was saved to state file
  if grep -q 'COMPLETED_STATES_JSON' "$test_state_file"; then
    pass "State transition saves COMPLETED_STATES to state"
  else
    fail "State transition did not save COMPLETED_STATES"
  fi

  # Cleanup
  rm -f "$test_state_file"
  unset STATE_FILE append_workflow_state
  COMPLETED_STATES=()
}

# Run Phase 2 tests
test_phase2_save_completed_states
test_phase2_load_completed_states
test_phase2_empty_array_handling
test_phase2_state_machine_integration

# ==============================================================================
# Test Suite: Phase 3 - Fail-Fast State Validation (Spec 672)
# ==============================================================================

test_phase3_first_block_graceful_init() {
  print_test_header "Phase 3.1: First Block - Graceful Initialization"

  # Setup: Ensure CLAUDE_PROJECT_DIR is set
  if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
    CLAUDE_PROJECT_DIR="${PROJECT_ROOT}"
    export CLAUDE_PROJECT_DIR
  fi

  # Create unique workflow ID that doesn't have a state file
  local test_workflow_id="test_workflow_$$_$(date +%s)"
  local test_state_file="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${test_workflow_id}.sh"

  # Ensure state file doesn't exist
  rm -f "$test_state_file"

  # Execute load with is_first_block=true (should gracefully initialize)
  local exit_code
  load_workflow_state "$test_workflow_id" true
  exit_code=$?

  # Verify it returned 1 (initialized new state)
  if [ "$exit_code" -eq 1 ]; then
    pass "First block with missing state initializes gracefully (exit code 1)"
  else
    fail "First block should return 1, got $exit_code"
  fi

  # Verify state file was created
  if [ -f "$test_state_file" ]; then
    pass "First block created new state file"
  else
    fail "State file not created by first block"
  fi

  # Cleanup
  rm -f "$test_state_file"
}

test_phase3_subsequent_block_success() {
  print_test_header "Phase 3.2: Subsequent Block - Successful Load"

  # Setup: Ensure CLAUDE_PROJECT_DIR is set
  if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
    CLAUDE_PROJECT_DIR="${PROJECT_ROOT}"
    export CLAUDE_PROJECT_DIR
  fi

  # Create workflow with existing state file
  local test_workflow_id="test_workflow_$$_$(date +%s)"
  local test_state_file="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${test_workflow_id}.sh"

  # Create state file with test data
  echo 'export TEST_VAR="test_value"' > "$test_state_file"

  # Execute load with is_first_block=false (should load successfully)
  local exit_code
  load_workflow_state "$test_workflow_id" false
  exit_code=$?

  # Verify it returned 0 (loaded successfully)
  if [ "$exit_code" -eq 0 ]; then
    pass "Subsequent block loads existing state successfully (exit code 0)"
  else
    fail "Subsequent block should return 0, got $exit_code"
  fi

  # Verify variable was loaded
  if [ "${TEST_VAR:-}" = "test_value" ]; then
    pass "Subsequent block restored variables from state"
  else
    fail "Variable not restored from state"
  fi

  # Cleanup
  rm -f "$test_state_file"
  unset TEST_VAR
}

test_phase3_subsequent_block_fail_fast() {
  print_test_header "Phase 3.3: Subsequent Block - Fail-Fast on Missing State"

  # Setup: Ensure CLAUDE_PROJECT_DIR is set
  if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
    CLAUDE_PROJECT_DIR="${PROJECT_ROOT}"
    export CLAUDE_PROJECT_DIR
  fi

  # Create unique workflow ID without state file
  local test_workflow_id="test_workflow_$$_$(date +%s)"
  local test_state_file="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${test_workflow_id}.sh"

  # Ensure state file doesn't exist
  rm -f "$test_state_file"

  # Execute load with is_first_block=false (should fail-fast)
  local exit_code
  local error_output
  error_output=$(load_workflow_state "$test_workflow_id" false 2>&1)
  exit_code=$?

  # Verify it returned 2 (CRITICAL ERROR)
  if [ "$exit_code" -eq 2 ]; then
    pass "Subsequent block with missing state returns exit code 2 (CRITICAL ERROR)"
  else
    fail "Expected exit code 2, got $exit_code"
  fi

  # Verify diagnostic output contains key messages
  if echo "$error_output" | grep -q "CRITICAL ERROR"; then
    pass "Fail-fast produces CRITICAL ERROR message"
  else
    fail "CRITICAL ERROR message not found in output"
  fi

  if echo "$error_output" | grep -q "TROUBLESHOOTING"; then
    pass "Fail-fast includes troubleshooting guidance"
  else
    fail "Troubleshooting guidance not found in output"
  fi

  # Cleanup
  rm -f "$test_state_file"
}

test_phase3_default_parameter_behavior() {
  print_test_header "Phase 3.4: Default Parameter (is_first_block=false)"

  # Setup: Ensure CLAUDE_PROJECT_DIR is set
  if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
    CLAUDE_PROJECT_DIR="${PROJECT_ROOT}"
    export CLAUDE_PROJECT_DIR
  fi

  # Create unique workflow ID without state file
  local test_workflow_id="test_workflow_$$_$(date +%s)"
  local test_state_file="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${test_workflow_id}.sh"

  # Ensure state file doesn't exist
  rm -f "$test_state_file"

  # Execute load WITHOUT second parameter (should default to false)
  local exit_code
  load_workflow_state "$test_workflow_id" 2>/dev/null
  exit_code=$?

  # Verify default behavior is fail-fast (exit code 2)
  if [ "$exit_code" -eq 2 ]; then
    pass "Default parameter behavior is fail-fast (is_first_block=false)"
  else
    fail "Expected default to fail-fast (exit code 2), got $exit_code"
  fi

  # Cleanup
  rm -f "$test_state_file"
}

# Run Phase 3 tests
test_phase3_first_block_graceful_init
test_phase3_subsequent_block_success
test_phase3_subsequent_block_fail_fast
test_phase3_default_parameter_behavior

# ==============================================================================
# Test Suite: Phase 4 - State ID File Persistence (Spec 661)
# ==============================================================================

test_phase4_state_id_file_fixed_location() {
  print_test_header "Phase 4.1: State ID File Uses Fixed Semantic Filename"

  # Simulate coordinate.md Block 1 creating state ID file
  WORKFLOW_ID="test_coordinate_$$_$(date +%s)"
  COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id_test_$$.txt"

  # Execute pattern from coordinate.md lines 136-138
  echo "$WORKFLOW_ID" > "$COORDINATE_STATE_ID_FILE"

  # Verify file created
  if [ -f "$COORDINATE_STATE_ID_FILE" ]; then
    pass "State ID file created at fixed semantic location"
  else
    fail "State ID file not created"
  fi

  # Verify contents
  if [ "$(cat "$COORDINATE_STATE_ID_FILE")" = "$WORKFLOW_ID" ]; then
    pass "State ID file contains correct WORKFLOW_ID"
  else
    fail "State ID file contents incorrect"
  fi

  # Cleanup
  rm -f "$COORDINATE_STATE_ID_FILE"
}

test_phase4_state_id_file_survives_bash_block() {
  print_test_header "Phase 4.2: State ID File Survives First Bash Block Exit"

  WORKFLOW_ID="test_coordinate_$$_$(date +%s)"
  COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id_block_$$.txt"

  # Simulate Block 1 execution (subprocess context)
  bash -c "
    echo '$WORKFLOW_ID' > '$COORDINATE_STATE_ID_FILE'
    echo 'Block 1 complete'
  "

  # Verify file persists after subprocess exit
  if [ -f "$COORDINATE_STATE_ID_FILE" ]; then
    pass "State ID file persists after first bash block exit"
  else
    fail "State ID file deleted prematurely"
  fi

  # Cleanup
  rm -f "$COORDINATE_STATE_ID_FILE"
}

test_phase4_no_exit_trap_in_block_1() {
  print_test_header "Phase 4.3: No EXIT Trap in Block 1 (Pattern 6)"

  COORDINATE_FILE="${PROJECT_ROOT}/.claude/commands/coordinate.md"

  # Check first 200 lines for EXIT trap
  if head -200 "$COORDINATE_FILE" | grep -q 'trap.*EXIT.*coordinate_state_id'; then
    fail "coordinate.md Block 1 contains premature EXIT trap (violates Pattern 6)"
  else
    pass "coordinate.md Block 1 does not contain premature EXIT trap"
  fi

  # Verify fixed semantic filename used
  if grep -q 'COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"' "$COORDINATE_FILE"; then
    pass "coordinate.md uses fixed semantic filename (Pattern 1)"
  else
    fail "coordinate.md does not use fixed semantic filename"
  fi
}

test_phase4_verification_checkpoint_exists() {
  print_test_header "Phase 4.4: Verification Checkpoint After State ID File Creation"

  COORDINATE_FILE="${PROJECT_ROOT}/.claude/commands/coordinate.md"

  # Check for verification checkpoint after state ID file creation
  # Should be within 10 lines of coordinate_state_id.txt creation
  if grep -A10 'coordinate_state_id.txt' "$COORDINATE_FILE" | head -15 | grep -q 'verify_file_created.*State ID file'; then
    pass "Verification checkpoint exists after state ID file creation (Standard 0)"
  else
    fail "Missing verification checkpoint for state ID file"
  fi
}

# Run Phase 4 tests
test_phase4_state_id_file_fixed_location
test_phase4_state_id_file_survives_bash_block
test_phase4_no_exit_trap_in_block_1
test_phase4_verification_checkpoint_exists

# ==============================================================================
# Test Suite: Phase 5 - Backward Compatibility and Error Messages (Spec 661)
# ==============================================================================

test_phase5_backward_compatibility_removed() {
  print_test_header "Phase 5.1: Backward Compatibility Pattern Removed (Fail-Fast)"

  COORDINATE_FILE="${PROJECT_ROOT}/.claude/commands/coordinate.md"

  # Check that old timestamp-based pattern is not referenced
  # Old pattern: coordinate_state_id_${timestamp}.txt
  if grep -q 'coordinate_state_id_\${.*timestamp' "$COORDINATE_FILE"; then
    fail "Old timestamp-based pattern still present (should be removed for fail-fast)"
  else
    pass "Old timestamp-based pattern removed (fail-fast compliance)"
  fi

  # Verify no silent fallback logic
  if grep -i 'fallback.*coordinate_state_id' "$COORDINATE_FILE"; then
    fail "Silent fallback logic present (violates fail-fast policy)"
  else
    pass "No silent fallback logic (fail-fast compliance)"
  fi
}

test_phase5_error_message_state_id_missing() {
  print_test_header "Phase 5.2: Error Message When State ID File Missing"

  # Simulate Block 2+ with missing state ID file
  COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id_missing_$$.txt"

  # Ensure file does not exist
  rm -f "$COORDINATE_STATE_ID_FILE"

  # Execute state loading attempt (should produce error)
  ERROR_OUTPUT=$(bash -c "
    source '${PROJECT_ROOT}/.claude/lib/state-persistence.sh'
    source '${PROJECT_ROOT}/.claude/lib/verification-helpers.sh'

    # Try to verify missing file
    if verify_file_created '$COORDINATE_STATE_ID_FILE' 'State ID file' 'Test' 2>&1; then
      echo 'UNEXPECTED_SUCCESS'
    fi
  " 2>&1)

  # Verify error message produced
  if echo "$ERROR_OUTPUT" | grep -iq 'state.*id.*file\|verification.*failed'; then
    pass "Error message produced when state ID file missing"
  else
    fail "No error message when state ID file missing"
  fi
}

test_phase5_diagnostic_message_quality() {
  print_test_header "Phase 5.3: Diagnostic Message Quality"

  COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id_diagnostic_$$.txt"
  rm -f "$COORDINATE_STATE_ID_FILE"

  # Test diagnostic output from verification function
  ERROR_OUTPUT=$(bash -c "
    source '${PROJECT_ROOT}/.claude/lib/verification-helpers.sh'
    verify_file_created '$COORDINATE_STATE_ID_FILE' 'State ID file' 'Initialization' 2>&1 || true
  " 2>&1)

  # Check for helpful diagnostic elements
  if echo "$ERROR_OUTPUT" | grep -q "$COORDINATE_STATE_ID_FILE"; then
    pass "Diagnostic includes file path for troubleshooting"
  else
    fail "Diagnostic missing file path"
  fi

  if echo "$ERROR_OUTPUT" | grep -iq 'state.*id\|initialization'; then
    pass "Diagnostic includes context (State ID file / Initialization)"
  else
    fail "Diagnostic missing context"
  fi
}

# Run Phase 5 tests
test_phase5_backward_compatibility_removed
test_phase5_error_message_state_id_missing
test_phase5_diagnostic_message_quality

# ==============================================================================
# Summary
# ==============================================================================
echo ""
echo "═══════════════════════════════════════════════════════"
echo "Test Summary"
echo "═══════════════════════════════════════════════════════"
echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
echo -e "${RED}Failed:${NC} $TESTS_FAILED"
echo "Total: $((TESTS_PASSED + TESTS_FAILED))"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}✓ All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  exit 1
fi
