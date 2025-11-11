#!/usr/bin/env bash
# Test verification-helpers.sh functions
# Tests verify_state_variable() and verify_state_variables() functions

set -euo pipefail

# Setup test environment
TEST_DIR=$(mktemp -d)
trap "rm -rf '$TEST_DIR'" EXIT

# Source the verification helpers library
LIB_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/lib"
source "$LIB_DIR/verification-helpers.sh"

# Create test state file path
STATE_FILE="$TEST_DIR/test_state.sh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0

# Helper function to run a test
run_test() {
  local test_name="$1"
  echo ""
  echo "Test $((TESTS_RUN + 1)): $test_name"
  TESTS_RUN=$((TESTS_RUN + 1))
}

# Helper function to mark test as passed
pass_test() {
  echo "✓ PASS"
  TESTS_PASSED=$((TESTS_PASSED + 1))
}

# Helper function to mark test as failed
fail_test() {
  local reason="$1"
  echo "✗ FAIL: $reason"
  exit 1
}

# ============================================================================
# Test Suite 1: verify_state_variable() - Basic Functionality
# ============================================================================

run_test "verify_state_variable() with STATE_FILE not set"
unset STATE_FILE || true
if ! verify_state_variable "TEST_VAR" >/dev/null 2>&1; then
  # Should fail - check error message
  output=$(verify_state_variable "TEST_VAR" 2>&1 || true)
  if echo "$output" | grep -q "STATE_FILE not set"; then
    pass_test
  else
    fail_test "Should output correct error message"
  fi
else
  fail_test "Should fail when STATE_FILE not set"
fi

run_test "verify_state_variable() with non-existent state file"
export STATE_FILE="$TEST_DIR/nonexistent.sh"
if ! verify_state_variable "TEST_VAR" >/dev/null 2>&1; then
  # Should fail - check error message
  output=$(verify_state_variable "TEST_VAR" 2>&1 || true)
  if echo "$output" | grep -q "State file does not exist"; then
    pass_test
  else
    fail_test "Should output correct error message"
  fi
else
  fail_test "Should fail when state file doesn't exist"
fi

# Create a test state file with correct format
cat > "$STATE_FILE" <<'INNER_EOF'
#!/usr/bin/env bash
export WORKFLOW_SCOPE="research-only"
export REPORT_PATHS_COUNT="2"
export REPORT_PATH_0="/path/to/report1.md"
export REPORT_PATH_1="/path/to/report2.md"
export EXISTING_PLAN_PATH="/path/to/plan.md"
INNER_EOF

run_test "verify_state_variable() with existing variable (WORKFLOW_SCOPE)"
if verify_state_variable "WORKFLOW_SCOPE" >/dev/null 2>&1; then
  pass_test
else
  fail_test "Should succeed when variable exists"
fi

run_test "verify_state_variable() with existing variable (REPORT_PATHS_COUNT)"
if verify_state_variable "REPORT_PATHS_COUNT" >/dev/null 2>&1; then
  pass_test
else
  fail_test "Should succeed when variable exists"
fi

run_test "verify_state_variable() with existing variable (EXISTING_PLAN_PATH)"
if verify_state_variable "EXISTING_PLAN_PATH" >/dev/null 2>&1; then
  pass_test
else
  fail_test "Should succeed when variable exists"
fi

run_test "verify_state_variable() with non-existent variable"
if ! verify_state_variable "NONEXISTENT_VAR" >/dev/null 2>&1; then
  # Should fail
  output=$(verify_state_variable "NONEXISTENT_VAR" 2>&1 || true)
  if echo "$output" | grep -q "Variable not found in state file"; then
    pass_test
  else
    fail_test "Should output correct error message"
  fi
else
  fail_test "Should fail when variable doesn't exist"
fi

# ============================================================================
# Test Suite 2: verify_state_variable() - Export Format Matching
# ============================================================================

run_test "verify_state_variable() with correct export format"
# Variable should be in format: export VAR_NAME="value"
if grep -q "^export WORKFLOW_SCOPE=" "$STATE_FILE"; then
  pass_test
else
  fail_test "State file should contain correct export format"
fi

run_test "verify_state_variable() export format pattern matching"
# Create state file with incorrect format (missing export)
cat > "$TEST_DIR/bad_format.sh" <<'INNER_EOF'
#!/usr/bin/env bash
WORKFLOW_SCOPE="research-only"
INNER_EOF

export STATE_FILE="$TEST_DIR/bad_format.sh"
if ! verify_state_variable "WORKFLOW_SCOPE" >/dev/null 2>&1; then
  pass_test
else
  fail_test "Should fail when export prefix is missing"
fi

# ============================================================================
# Test Suite 3: verify_state_variable() - Diagnostic Output
# ============================================================================

# Restore good state file
export STATE_FILE="$TEST_DIR/test_state.sh"
cat > "$STATE_FILE" <<'INNER_EOF'
#!/usr/bin/env bash
export WORKFLOW_SCOPE="research-only"
export REPORT_PATHS_COUNT="2"
export REPORT_PATH_0="/path/to/report1.md"
export REPORT_PATH_1="/path/to/report2.md"
export EXISTING_PLAN_PATH="/path/to/plan.md"
INNER_EOF

run_test "verify_state_variable() diagnostic output includes expected format"
output=$(verify_state_variable "MISSING_VAR" 2>&1 || true)
if echo "$output" | grep -q 'EXPECTED FORMAT:' && echo "$output" | grep -q 'export MISSING_VAR'; then
  pass_test
else
  fail_test "Diagnostic output should show expected format"
fi

run_test "verify_state_variable() diagnostic output includes state file path"
output=$(verify_state_variable "MISSING_VAR" 2>&1 || true)
if echo "$output" | grep -q "State file: $STATE_FILE"; then
  pass_test
else
  fail_test "Diagnostic output should show state file path"
fi

run_test "verify_state_variable() diagnostic output includes troubleshooting steps"
output=$(verify_state_variable "MISSING_VAR" 2>&1 || true)
if echo "$output" | grep -q "TROUBLESHOOTING:"; then
  pass_test
else
  fail_test "Diagnostic output should include troubleshooting section"
fi

# ============================================================================
# Test Suite 4: verify_state_variables() - Multiple Variables
# ============================================================================

run_test "verify_state_variables() with all variables existing"
if verify_state_variables "$STATE_FILE" WORKFLOW_SCOPE REPORT_PATHS_COUNT EXISTING_PLAN_PATH >/dev/null 2>&1; then
  pass_test
else
  fail_test "Should succeed when all variables exist"
fi

run_test "verify_state_variables() with one missing variable"
if ! verify_state_variables "$STATE_FILE" WORKFLOW_SCOPE MISSING_VAR >/dev/null 2>&1; then
  output=$(verify_state_variables "$STATE_FILE" WORKFLOW_SCOPE MISSING_VAR 2>&1 || true)
  if echo "$output" | grep -q "MISSING_VAR"; then
    pass_test
  else
    fail_test "Should list missing variable in output"
  fi
else
  fail_test "Should fail when one variable is missing"
fi

run_test "verify_state_variables() with multiple missing variables"
if ! verify_state_variables "$STATE_FILE" MISSING_VAR1 MISSING_VAR2 >/dev/null 2>&1; then
  output=$(verify_state_variables "$STATE_FILE" MISSING_VAR1 MISSING_VAR2 2>&1 || true)
  if echo "$output" | grep -q "MISSING_VAR1" && echo "$output" | grep -q "MISSING_VAR2"; then
    pass_test
  else
    fail_test "Should list all missing variables in output"
  fi
else
  fail_test "Should fail when multiple variables are missing"
fi

# ============================================================================
# Test Suite 5: Integration with Coordinate Command Patterns
# ============================================================================

run_test "Integration: WORKFLOW_SCOPE verification pattern"
# Simulate the coordinate.md pattern
if verify_state_variable "WORKFLOW_SCOPE" >/dev/null 2>&1; then
  pass_test
else
  fail_test "Should work with WORKFLOW_SCOPE as used in coordinate.md"
fi

run_test "Integration: REPORT_PATHS_COUNT verification pattern"
# Simulate the coordinate.md pattern for array export
if verify_state_variable "REPORT_PATHS_COUNT" >/dev/null 2>&1; then
  pass_test
else
  fail_test "Should work with REPORT_PATHS_COUNT as used in coordinate.md"
fi

run_test "Integration: EXISTING_PLAN_PATH verification pattern"
# Simulate the coordinate.md pattern for research-and-revise workflow
if verify_state_variable "EXISTING_PLAN_PATH" >/dev/null 2>&1; then
  pass_test
else
  fail_test "Should work with EXISTING_PLAN_PATH as used in coordinate.md"
fi

run_test "Integration: Error handling with exit code"
# Test the pattern: verify_state_variable "VAR" || exit 1
set +e  # Temporarily disable exit on error for this test
(
  verify_state_variable "MISSING_VAR" >/dev/null 2>&1 || exit 99
)
exit_code=$?
set -e  # Re-enable exit on error
if [ $exit_code -eq 99 ]; then
  pass_test
else
  fail_test "Should propagate exit code for error handling"
fi

# ============================================================================
# Test Summary
# ============================================================================

echo ""
echo "============================================"
echo "Test Summary"
echo "============================================"
echo "Tests run: $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $((TESTS_RUN - TESTS_PASSED))"

if [ $TESTS_PASSED -eq $TESTS_RUN ]; then
  echo ""
  echo "✓ All tests passed ($TESTS_PASSED/$TESTS_RUN)"
  exit 0
else
  echo ""
  echo "✗ Some tests failed ($((TESTS_RUN - TESTS_PASSED)) failures)"
  exit 1
fi
