#!/usr/bin/env bash
# Test test-executor agent behavioral compliance
# Verifies agent follows documented behavioral guidelines

set -uo pipefail

# Test setup
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
PROJECT_ROOT="${CLAUDE_PROJECT_DIR}/.claude"
TEST_AGENT_FILE="${PROJECT_ROOT}/agents/test-executor.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helpers
pass() {
  ((TESTS_PASSED++))
  echo -e "${GREEN}PASS${NC}: $1"
}

fail() {
  ((TESTS_FAILED++))
  echo -e "${RED}FAIL${NC}: $1"
}

info() {
  echo -e "${YELLOW}INFO${NC}: $1"
}

run_test() {
  ((TESTS_RUN++))
  "$@"
}

# Test 1: Agent file exists
test_agent_file_exists() {
  if [ -f "$TEST_AGENT_FILE" ]; then
    pass "test-executor.md agent file exists"
  else
    fail "test-executor.md agent file not found at $TEST_AGENT_FILE"
  fi
}

# Test 2: Agent has required frontmatter
test_agent_frontmatter() {
  if grep -q "^---" "$TEST_AGENT_FILE" && \
     grep -q "^allowed-tools:" "$TEST_AGENT_FILE" && \
     grep -q "^model:" "$TEST_AGENT_FILE" && \
     grep -q "^description:" "$TEST_AGENT_FILE"; then
    pass "Agent has required frontmatter fields"
  else
    fail "Agent missing required frontmatter (allowed-tools, model, description)"
  fi
}

# Test 3: Agent uses haiku-4.5 model
test_agent_model() {
  if grep -q "^model: haiku-4.5" "$TEST_AGENT_FILE"; then
    pass "Agent uses haiku-4.5 model (deterministic execution)"
  else
    fail "Agent does not use haiku-4.5 model"
  fi
}

# Test 4: Agent has 6-STEP execution process
test_agent_steps() {
  local step_count=0
  for i in {1..6}; do
    if grep -q "### STEP $i:" "$TEST_AGENT_FILE"; then
      ((step_count++))
    fi
  done

  if [ "$step_count" -eq 6 ]; then
    pass "Agent has complete 6-STEP execution process"
  else
    fail "Agent has $step_count steps, expected 6"
  fi
}

# Test 5: Agent has artifact creation in STEP 1
test_step1_artifact_creation() {
  if grep -A 5 "### STEP 1:" "$TEST_AGENT_FILE" | grep -q "Create Test Output Artifact"; then
    pass "STEP 1 documents artifact creation"
  else
    fail "STEP 1 missing artifact creation documentation"
  fi
}

# Test 6: Agent has framework detection in STEP 2
test_step2_framework_detection() {
  if grep -A 10 "### STEP 2:" "$TEST_AGENT_FILE" | grep -q "detect-testing.sh"; then
    pass "STEP 2 documents detect-testing.sh integration"
  else
    fail "STEP 2 missing detect-testing.sh integration"
  fi
}

# Test 7: Agent has retry logic in STEP 3
test_step3_retry_logic() {
  if grep -A 20 "### STEP 3:" "$TEST_AGENT_FILE" | grep -q "Retry Logic"; then
    pass "STEP 3 documents retry logic"
  else
    fail "STEP 3 missing retry logic documentation"
  fi
}

# Test 8: Agent has result parsing in STEP 4
test_step4_result_parsing() {
  if grep -A 10 "### STEP 4:" "$TEST_AGENT_FILE" | grep -q "Parse Test Results"; then
    pass "STEP 4 documents result parsing"
  else
    fail "STEP 4 missing result parsing documentation"
  fi
}

# Test 9: Agent has artifact update in STEP 5
test_step5_artifact_update() {
  if grep -A 10 "### STEP 5:" "$TEST_AGENT_FILE" | grep -q "Update Artifact"; then
    pass "STEP 5 documents artifact update"
  else
    fail "STEP 5 missing artifact update documentation"
  fi
}

# Test 10: Agent has TEST_COMPLETE signal in STEP 6
test_step6_completion_signal() {
  if grep -A 10 "### STEP 6:" "$TEST_AGENT_FILE" | grep -q "TEST_COMPLETE"; then
    pass "STEP 6 documents TEST_COMPLETE signal"
  else
    fail "STEP 6 missing TEST_COMPLETE signal"
  fi
}

# Test 11: Agent has error return protocol
test_error_return_protocol() {
  if grep -q "## Error Return Protocol" "$TEST_AGENT_FILE" && \
     grep -q "ERROR_CONTEXT" "$TEST_AGENT_FILE" && \
     grep -q "TASK_ERROR" "$TEST_AGENT_FILE"; then
    pass "Agent has error return protocol documented"
  else
    fail "Agent missing error return protocol"
  fi
}

# Test 12: Agent has error types documented
test_error_types() {
  local error_types=("execution_error" "timeout_error" "dependency_error" "validation_error" "parse_error")
  local missing_types=()

  for error_type in "${error_types[@]}"; do
    if ! grep -q "$error_type" "$TEST_AGENT_FILE"; then
      missing_types+=("$error_type")
    fi
  done

  if [ ${#missing_types[@]} -eq 0 ]; then
    pass "All required error types documented"
  else
    fail "Missing error types: ${missing_types[*]}"
  fi
}

# Test 13: Agent has completion criteria
test_completion_criteria() {
  if grep -q "## Completion Criteria" "$TEST_AGENT_FILE"; then
    pass "Agent has completion criteria checklist"
  else
    fail "Agent missing completion criteria section"
  fi
}

# Test 14: Agent has context efficiency notes
test_context_efficiency() {
  if grep -q "Context Efficiency" "$TEST_AGENT_FILE" && \
     grep -q "96%" "$TEST_AGENT_FILE"; then
    pass "Agent documents context efficiency (96% reduction)"
  else
    fail "Agent missing context efficiency documentation"
  fi
}

# Run all tests
main() {
  info "Starting test-executor behavioral compliance tests"
  echo ""

  run_test test_agent_file_exists
  run_test test_agent_frontmatter
  run_test test_agent_model
  run_test test_agent_steps
  run_test test_step1_artifact_creation
  run_test test_step2_framework_detection
  run_test test_step3_retry_logic
  run_test test_step4_result_parsing
  run_test test_step5_artifact_update
  run_test test_step6_completion_signal
  run_test test_error_return_protocol
  run_test test_error_types
  run_test test_completion_criteria
  run_test test_context_efficiency

  echo ""
  echo "========================================="
  echo "Test Results:"
  echo "  Total:  $TESTS_RUN"
  echo "  Passed: $TESTS_PASSED"
  echo "  Failed: $TESTS_FAILED"
  echo "========================================="

  if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
  else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
  fi
}

main
