#!/usr/bin/env bash
# Unit tests for lib/core/summary-formatting.sh
#
# Tests the print_artifact_summary function for console output formatting

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/../.."

# Source test helpers
source "${SCRIPT_DIR}/../lib/test-helpers.sh" 2>/dev/null || \
  { echo "Cannot load test helpers"; exit 1; }

# Source library under test
LIB_PATH="${PROJECT_ROOT}/lib/core/summary-formatting.sh"
source "$LIB_PATH" 2>/dev/null || { echo "Cannot load summary-formatting"; exit 1; }

setup_test

# Test: print_artifact_summary requires command_name
test_requires_command_name() {
  local output exit_code=0
  output=$(print_artifact_summary "" "summary" "" "artifacts" "next" 2>&1) || exit_code=$?

  if [[ $exit_code -ne 0 && "$output" == *"requires command_name"* ]]; then
    pass "requires_command_name_parameter"
  else
    fail "requires_command_name_parameter" "Expected error for missing command_name"
  fi
}

# Test: print_artifact_summary requires summary_text
test_requires_summary_text() {
  local output exit_code=0
  output=$(print_artifact_summary "Test" "" "" "artifacts" "next" 2>&1) || exit_code=$?

  if [[ $exit_code -ne 0 && "$output" == *"requires summary_text"* ]]; then
    pass "requires_summary_text_parameter"
  else
    fail "requires_summary_text_parameter" "Expected error for missing summary_text"
  fi
}

# Test: print_artifact_summary requires artifacts
test_requires_artifacts() {
  local output exit_code=0
  output=$(print_artifact_summary "Test" "summary" "" "" "next" 2>&1) || exit_code=$?

  if [[ $exit_code -ne 0 && "$output" == *"requires artifacts"* ]]; then
    pass "requires_artifacts_parameter"
  else
    fail "requires_artifacts_parameter" "Expected error for missing artifacts"
  fi
}

# Test: print_artifact_summary requires next_steps
test_requires_next_steps() {
  local output exit_code=0
  output=$(print_artifact_summary "Test" "summary" "" "artifacts" "" 2>&1) || exit_code=$?

  if [[ $exit_code -ne 0 && "$output" == *"requires next_steps"* ]]; then
    pass "requires_next_steps_parameter"
  else
    fail "requires_next_steps_parameter" "Expected error for missing next_steps"
  fi
}

# Test: print_artifact_summary outputs command name header
test_outputs_header() {
  local output
  output=$(print_artifact_summary "Research" "Test summary." "" "Test artifact" "Test step")

  assert_contains "=== Research Complete ===" "$output" "outputs_command_header"
}

# Test: print_artifact_summary outputs Summary section
test_outputs_summary_section() {
  local output
  output=$(print_artifact_summary "Test" "This is the summary text." "" "Artifact" "Step")

  assert_contains "Summary: This is the summary text." "$output" "outputs_summary_section"
}

# Test: print_artifact_summary outputs Artifacts section
test_outputs_artifacts_section() {
  local output
  output=$(print_artifact_summary "Test" "Summary" "" "📊 Reports: /path/to/file" "Step")

  if [[ "$output" == *"Artifacts:"* && "$output" == *"Reports: /path/to/file"* ]]; then
    pass "outputs_artifacts_section"
  else
    fail "outputs_artifacts_section" "Expected Artifacts section with content"
  fi
}

# Test: print_artifact_summary outputs Next Steps section
test_outputs_next_steps_section() {
  local output
  output=$(print_artifact_summary "Test" "Summary" "" "Artifact" "• Run /plan")

  if [[ "$output" == *"Next Steps:"* && "$output" == *"Run /plan"* ]]; then
    pass "outputs_next_steps_section"
  else
    fail "outputs_next_steps_section" "Expected Next Steps section"
  fi
}

# Test: print_artifact_summary omits Phases when empty
test_omits_phases_when_empty() {
  local output
  output=$(print_artifact_summary "Test" "Summary" "" "Artifact" "Step")

  if [[ "$output" != *"Phases:"* ]]; then
    pass "omits_phases_when_empty"
  else
    fail "omits_phases_when_empty" "Phases section should be omitted when empty"
  fi
}

# Test: print_artifact_summary includes Phases when provided
test_includes_phases_when_provided() {
  local output
  output=$(print_artifact_summary "Build" "Summary" "• Phase 1: Setup
• Phase 2: Implement" "Artifact" "Step")

  if [[ "$output" == *"Phases:"* && "$output" == *"Phase 1: Setup"* ]]; then
    pass "includes_phases_when_provided"
  else
    fail "includes_phases_when_provided" "Expected Phases section with content"
  fi
}

# Test: print_artifact_summary returns 0 on success
test_returns_success() {
  local exit_code=0
  print_artifact_summary "Test" "Summary" "" "Artifact" "Step" >/dev/null 2>&1 || exit_code=$?

  assert_equals "0" "$exit_code" "returns_success_code"
}

# Test: print_artifact_summary returns 1 on failure
test_returns_failure() {
  local exit_code=0
  print_artifact_summary "" "" "" "" "" >/dev/null 2>&1 || exit_code=$?

  assert_equals "1" "$exit_code" "returns_failure_code"
}

# Test: print_artifact_summary handles multi-line artifacts
test_multiline_artifacts() {
  local output
  output=$(print_artifact_summary "Test" "Summary" "" "📊 Report: /path/report.md
📋 Plan: /path/plan.md" "Step")

  if [[ "$output" == *"Report: /path/report.md"* && "$output" == *"Plan: /path/plan.md"* ]]; then
    pass "handles_multiline_artifacts"
  else
    fail "handles_multiline_artifacts" "Expected both artifact lines in output"
  fi
}

# Test: print_artifact_summary handles multi-line next_steps
test_multiline_next_steps() {
  local output
  output=$(print_artifact_summary "Test" "Summary" "" "Artifact" "• First step
• Second step
• Third step")

  if [[ "$output" == *"First step"* && "$output" == *"Third step"* ]]; then
    pass "handles_multiline_next_steps"
  else
    fail "handles_multiline_next_steps" "Expected all next steps in output"
  fi
}

# Run all tests
test_requires_command_name
test_requires_summary_text
test_requires_artifacts
test_requires_next_steps
test_outputs_header
test_outputs_summary_section
test_outputs_artifacts_section
test_outputs_next_steps_section
test_omits_phases_when_empty
test_includes_phases_when_provided
test_returns_success
test_returns_failure
test_multiline_artifacts
test_multiline_next_steps

teardown_test
