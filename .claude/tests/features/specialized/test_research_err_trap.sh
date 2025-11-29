#!/usr/bin/env bash
# Test suite for /research ERR trap error logging validation
# Tests 6 scenarios for bash-level error capture

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect project root
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  PROJECT_ROOT="$(git rev-parse --show-toplevel)"
else
  current_dir="$SCRIPT_DIR"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      PROJECT_ROOT="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi

# Use centralized test log directory (matches error-handling.sh)
# When running with test_ workflow IDs, errors go to test-errors.jsonl not errors.jsonl
TEST_LOG_DIR="${PROJECT_ROOT}/.claude/tests/logs"
ERROR_LOG_DIR="${PROJECT_ROOT}/.claude/data/logs"
ERROR_LOG_FILE="${TEST_LOG_DIR}/test-errors.jsonl"

# Create test log directory
mkdir -p "$TEST_LOG_DIR"

# Test mode: baseline (current implementation) or with-traps (new implementation)
TEST_MODE="${1:-with-traps}"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result tracker
declare -a TEST_RESULTS

# Print test header
print_header() {
  echo "=================================="
  echo "ERR Trap Validation Test Suite"
  echo "Mode: $TEST_MODE"
  echo "=================================="
  echo ""
}

# Print test result
print_test_result() {
  local test_num=$1
  local test_name=$2
  local result=$3
  local details=$4

  if [ "$result" = "PASS" ]; then
    echo -e "${GREEN}✓${NC} T${test_num}: ${test_name}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} T${test_num}: ${test_name}"
    echo "  Details: ${details}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
  TEST_RESULTS+=("T${test_num}:${result}")
}

# Check if error was logged to centralized error log
check_error_logged() {
  local search_pattern=$1
  local error_type=${2:-}

  if [ ! -f "$ERROR_LOG_FILE" ]; then
    echo "ERROR_LOG_FILE_NOT_FOUND"
    return 1
  fi

  # Check if error with pattern exists in last 10 entries
  local found=$(tail -10 "$ERROR_LOG_FILE" | grep -c "$search_pattern" || true)

  if [ "$found" -gt 0 ]; then
    # If error_type specified, validate it
    if [ -n "$error_type" ]; then
      local type_found=$(tail -10 "$ERROR_LOG_FILE" | jq -r "select(.error_message | contains(\"$search_pattern\")) | .error_type" | grep -c "$error_type" || true)
      if [ "$type_found" -gt 0 ]; then
        echo "FOUND_WITH_TYPE"
        return 0
      else
        echo "FOUND_WRONG_TYPE"
        return 1
      fi
    else
      echo "FOUND"
      return 0
    fi
  else
    echo "NOT_FOUND"
    return 1
  fi
}

# T1: Syntax error capture (exit code 2)
test_t1_syntax_error() {
  echo ""
  echo "Running T1: Syntax error capture..."

  # Create temporary test file with syntax error
  local test_file=$(mktemp)
  cat > "$test_file" << EOF
#!/usr/bin/env bash
cd "$PROJECT_ROOT"
source ./.claude/lib/core/error-handling.sh 2>/dev/null
ensure_error_log_exists
setup_bash_error_trap "/test-t1" "test_t1_\$\$" "syntax test"

# Intentional syntax error
for i in 1 2 3
  echo \$i
done
EOF

  chmod +x "$test_file"

  # Run test file (expect exit code 2)
  set +e
  "$test_file" 2>/dev/null
  local exit_code=$?
  set -e

  rm -f "$test_file"

  # Check if error was logged
  local check_result=$(check_error_logged "Bash error" "parse_error")

  if [ "$TEST_MODE" = "baseline" ]; then
    # Baseline: expect NOT to capture syntax errors
    if [ "$check_result" = "NOT_FOUND" ]; then
      print_test_result 1 "Syntax error capture" "FAIL" "Expected (baseline has no trap)"
    else
      print_test_result 1 "Syntax error capture" "FAIL" "Unexpected capture in baseline"
    fi
  else
    # With traps: expect to capture syntax errors
    if [ "$check_result" = "FOUND_WITH_TYPE" ]; then
      print_test_result 1 "Syntax error capture" "PASS" "Error logged with parse_error type"
    else
      print_test_result 1 "Syntax error capture" "FAIL" "Error not logged: $check_result"
    fi
  fi
}

# T2: Unbound variable capture
test_t2_unbound_variable() {
  echo ""
  echo "Running T2: Unbound variable capture..."

  local test_file=$(mktemp)
  cat > "$test_file" << EOF
#!/usr/bin/env bash
set -u
source $PROJECT_ROOT/.claude/lib/core/error-handling.sh 2>/dev/null
ensure_error_log_exists
setup_bash_error_trap "/test-t2" "test_t2_\$\$" "unbound test"

# Reference unbound variable
echo "\$UNDEFINED_VARIABLE"
EOF

  chmod +x "$test_file"

  set +e
  "$test_file" 2>/dev/null
  local exit_code=$?
  set -e

  rm -f "$test_file"

  local check_result=$(check_error_logged "Bash error")

  if [ "$TEST_MODE" = "baseline" ]; then
    if [ "$check_result" = "NOT_FOUND" ]; then
      print_test_result 2 "Unbound variable capture" "FAIL" "Expected (baseline has no trap)"
    else
      print_test_result 2 "Unbound variable capture" "FAIL" "Unexpected capture"
    fi
  else
    if [ "$check_result" = "FOUND" ] || [ "$check_result" = "FOUND_WITH_TYPE" ]; then
      print_test_result 2 "Unbound variable capture" "PASS" "Error logged"
    else
      print_test_result 2 "Unbound variable capture" "FAIL" "Error not logged: $check_result"
    fi
  fi
}

# T3: Command not found (exit code 127)
test_t3_command_not_found() {
  echo ""
  echo "Running T3: Command not found capture..."

  local test_file=$(mktemp)
  cat > "$test_file" << EOF
#!/usr/bin/env bash
set -e
source $PROJECT_ROOT/.claude/lib/core/error-handling.sh 2>/dev/null
ensure_error_log_exists
setup_bash_error_trap "/test-t3" "test_t3_\$\$" "cmd-not-found test"

# Call nonexistent command
nonexistent_command_xyz123
EOF

  chmod +x "$test_file"

  set +e
  "$test_file" 2>/dev/null
  local exit_code=$?
  set -e

  rm -f "$test_file"

  local check_result=$(check_error_logged "Bash error" "execution_error")

  if [ "$TEST_MODE" = "baseline" ]; then
    if [ "$check_result" = "NOT_FOUND" ]; then
      print_test_result 3 "Command not found capture" "FAIL" "Expected (baseline has no trap)"
    else
      print_test_result 3 "Command not found capture" "FAIL" "Unexpected capture"
    fi
  else
    if [ "$check_result" = "FOUND_WITH_TYPE" ]; then
      print_test_result 3 "Command not found capture" "PASS" "Error logged with execution_error type"
    else
      print_test_result 3 "Command not found capture" "FAIL" "Error not logged: $check_result"
    fi
  fi
}

# T4: Function not found
test_t4_function_not_found() {
  echo ""
  echo "Running T4: Function not found capture..."

  local test_file=$(mktemp)
  cat > "$test_file" << EOF
#!/usr/bin/env bash
set -e
source $PROJECT_ROOT/.claude/lib/core/error-handling.sh 2>/dev/null
ensure_error_log_exists
setup_bash_error_trap "/test-t4" "test_t4_\$\$" "func-not-found test"

# Call nonexistent function
nonexistent_function_abc789
EOF

  chmod +x "$test_file"

  set +e
  "$test_file" 2>/dev/null
  local exit_code=$?
  set -e

  rm -f "$test_file"

  local check_result=$(check_error_logged "Bash error")

  if [ "$TEST_MODE" = "baseline" ]; then
    if [ "$check_result" = "NOT_FOUND" ]; then
      print_test_result 4 "Function not found capture" "FAIL" "Expected (baseline has no trap)"
    else
      print_test_result 4 "Function not found capture" "FAIL" "Unexpected capture"
    fi
  else
    if [ "$check_result" = "FOUND" ] || [ "$check_result" = "FOUND_WITH_TYPE" ]; then
      print_test_result 4 "Function not found capture" "PASS" "Error logged"
    else
      print_test_result 4 "Function not found capture" "FAIL" "Error not logged: $check_result"
    fi
  fi
}

# T5: Library sourcing failure (expected to NOT capture - occurs before trap)
test_t5_library_sourcing_failure() {
  echo ""
  echo "Running T5: Library sourcing failure (expected limitation)..."

  local test_file=$(mktemp)
  cat > "$test_file" << EOF
#!/usr/bin/env bash
set -e

# This will fail before trap can be set up
source /nonexistent/path/to/library.sh

# Trap setup would happen here, but we never get here
source $PROJECT_ROOT/.claude/lib/core/error-handling.sh 2>/dev/null
setup_bash_error_trap "/test-t5" "test_t5_\$\$" "sourcing test"
EOF

  chmod +x "$test_file"

  set +e
  "$test_file" 2>/dev/null
  local exit_code=$?
  set -e

  rm -f "$test_file"

  # Check for test_t5 specifically (not just any "Bash error")
  local check_result=$(grep -c "test_t5" "$ERROR_LOG_FILE" 2>/dev/null || true)

  # This test validates the known limitation is correctly demonstrated
  if [ "$check_result" -eq 0 ]; then
    print_test_result 5 "Library sourcing failure" "PASS" "Expected limitation (error before trap setup)"
  else
    print_test_result 5 "Library sourcing failure" "FAIL" "Unexpected capture (should be impossible)"
  fi
}

# T6: State file missing (existing conditional check)
test_t6_state_file_missing() {
  echo ""
  echo "Running T6: State file missing (existing error handling)..."

  # This test validates existing error handling still works
  # We'll check if conditional error checks still function

  local test_file=$(mktemp)
  cat > "$test_file" << EOF
#!/usr/bin/env bash
set -e
source $PROJECT_ROOT/.claude/lib/core/error-handling.sh 2>/dev/null
ensure_error_log_exists

COMMAND_NAME="/test-t6"
WORKFLOW_ID="test_t6_\$\$"
USER_ARGS="state-missing test"

setup_bash_error_trap "\$COMMAND_NAME" "\$WORKFLOW_ID" "\$USER_ARGS"

# Simulate state file check (existing error handling)
STATE_FILE="/nonexistent/state.sh"

if [ ! -f "\$STATE_FILE" ]; then
  log_command_error \\
    "\$COMMAND_NAME" \\
    "\$WORKFLOW_ID" \\
    "\$USER_ARGS" \\
    "file_error" \\
    "State file not found" \\
    "test" \\
    '{"path": "'\$STATE_FILE'"}'
  exit 1
fi
EOF

  chmod +x "$test_file"

  set +e
  "$test_file" 2>/dev/null
  local exit_code=$?
  set -e

  rm -f "$test_file"

  local check_result=$(check_error_logged "State file not found")

  # This should ALWAYS pass (existing error handling)
  if [ "$check_result" = "FOUND" ] || [ "$check_result" = "FOUND_WITH_TYPE" ]; then
    print_test_result 6 "State file missing (existing check)" "PASS" "Conditional error logging works"
  else
    print_test_result 6 "State file missing (existing check)" "FAIL" "Existing error handling broken: $check_result"
  fi
}

# Print summary
print_summary() {
  echo ""
  echo "=================================="
  echo "Test Summary"
  echo "=================================="
  echo "Mode: $TEST_MODE"
  echo "Tests Run: $TESTS_RUN"
  echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
  echo -e "${RED}Failed: $TESTS_FAILED${NC}"

  local capture_rate=0
  if [ $TESTS_RUN -gt 0 ]; then
    capture_rate=$((TESTS_PASSED * 100 / TESTS_RUN))
  fi
  echo ""
  echo "Error Capture Rate: ${capture_rate}%"
  echo ""

  # Expected results
  if [ "$TEST_MODE" = "baseline" ]; then
    echo "Expected baseline: 1/6 tests (17%) - only T6 (existing conditional check)"
  else
    echo "Expected with traps: 5/6 tests (83%) - all except T5 (pre-trap error)"
  fi
  echo "=================================="
  echo ""

  # Save results to log
  local log_file="${TEST_LOG_DIR}/${TEST_MODE}-results.log"
  {
    echo "Test Results - $(date)"
    echo "Mode: $TEST_MODE"
    echo "Tests Run: $TESTS_RUN"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    echo "Capture Rate: ${capture_rate}%"
    echo ""
    echo "Individual Results:"
    for result in "${TEST_RESULTS[@]}"; do
      echo "  $result"
    done
  } > "$log_file"

  echo "Results saved to: $log_file"
}

# Main execution
main() {
  print_header

  # Run all tests
  test_t1_syntax_error
  test_t2_unbound_variable
  test_t3_command_not_found
  test_t4_function_not_found
  test_t5_library_sourcing_failure
  test_t6_state_file_missing

  print_summary

  # Exit with non-zero if any tests failed
  if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
  fi
  exit 0
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi
