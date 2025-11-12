#!/bin/bash
# test_library_sourcing_order.sh
# Validates that library functions are sourced before being called
# Prevents "command not found" errors in orchestration commands

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test result tracking
total_tests=0
passed_tests=0
failed_tests=0

# Test helper function
run_test() {
  local test_name="$1"
  local test_result="$2"

  total_tests=$((total_tests + 1))

  if [ "$test_result" -eq 0 ]; then
    echo "✓ PASS: $test_name"
    passed_tests=$((passed_tests + 1))
  else
    echo "✗ FAIL: $test_name"
    failed_tests=$((failed_tests + 1))
  fi
}

# Test /coordinate command for library sourcing order violations
test_coordinate_sourcing_order() {
  local violations=0
  local cmd_file="${CLAUDE_PROJECT_DIR}/.claude/commands/coordinate.md"

  # Check verify_state_variable (from verification-helpers.sh)
  local first_source=$(grep -n "source.*verification-helpers" "$cmd_file" | head -1 | cut -d: -f1)
  local first_call=$(grep -n "verify_state_variable\|verify_file_created" "$cmd_file" | grep -v "^[0-9]*:#" | grep -v "provides verify_" | head -1 | cut -d: -f1)

  if [ "$first_call" -gt "$first_source" ]; then
    echo "  ✓ verify_state_variable sourced at line $first_source, first call at line $first_call"
  else
    echo "  ✗ verify_state_variable called at line $first_call before sourcing at $first_source"
    violations=$((violations + 1))
  fi

  # Check handle_state_error (from error-handling.sh)
  first_source=$(grep -n "source.*error-handling" "$cmd_file" | head -1 | cut -d: -f1)
  first_call=$(grep -n "handle_state_error" "$cmd_file" | grep -v "^[0-9]*:#" | grep -v "provides handle_" | head -1 | cut -d: -f1)

  if [ "$first_call" -gt "$first_source" ]; then
    echo "  ✓ handle_state_error sourced at line $first_source, first call at line $first_call"
  else
    echo "  ✗ handle_state_error called at line $first_call before sourcing at $first_source"
    violations=$((violations + 1))
  fi

  return $violations
}

# Test that source guards exist in libraries
test_source_guards() {
  local violations=0

  # Check error-handling.sh
  if grep -q "ERROR_HANDLING_SOURCED" "${CLAUDE_PROJECT_DIR}/.claude/lib/error-handling.sh"; then
    echo "  ✓ error-handling.sh has source guard"
  else
    echo "  ✗ error-handling.sh missing source guard"
    violations=$((violations + 1))
  fi

  # Check verification-helpers.sh
  if grep -q "VERIFICATION_HELPERS_SOURCED" "${CLAUDE_PROJECT_DIR}/.claude/lib/verification-helpers.sh"; then
    echo "  ✓ verification-helpers.sh has source guard"
  else
    echo "  ✗ verification-helpers.sh missing source guard"
    violations=$((violations + 1))
  fi

  return $violations
}

# Test that libraries are sourced early in initialization
test_early_sourcing() {
  local violations=0
  local cmd_file="${CLAUDE_PROJECT_DIR}/.claude/commands/coordinate.md"

  # Check that error-handling.sh is sourced within first 150 lines
  local error_handling_line=$(grep -n "source.*error-handling" "$cmd_file" | head -1 | cut -d: -f1)
  if [ "$error_handling_line" -lt 150 ]; then
    echo "  ✓ error-handling.sh sourced early (line $error_handling_line)"
  else
    echo "  ✗ error-handling.sh sourced too late (line $error_handling_line, should be < 150)"
    violations=$((violations + 1))
  fi

  # Check that verification-helpers.sh is sourced within first 150 lines
  local verification_line=$(grep -n "source.*verification-helpers" "$cmd_file" | head -1 | cut -d: -f1)
  if [ "$verification_line" -lt 150 ]; then
    echo "  ✓ verification-helpers.sh sourced early (line $verification_line)"
  else
    echo "  ✗ verification-helpers.sh sourced too late (line $verification_line, should be < 150)"
    violations=$((violations + 1))
  fi

  return $violations
}

# Test that state-persistence is sourced before error-handling/verification
test_dependency_order() {
  local violations=0
  local cmd_file="${CLAUDE_PROJECT_DIR}/.claude/commands/coordinate.md"

  local state_persist_line=$(grep -n "^source.*state-persistence" "$cmd_file" | head -1 | cut -d: -f1)
  local error_handling_line=$(grep -n "source.*error-handling" "$cmd_file" | head -1 | cut -d: -f1)
  local verification_line=$(grep -n "source.*verification-helpers" "$cmd_file" | head -1 | cut -d: -f1)

  if [ "$state_persist_line" -lt "$error_handling_line" ]; then
    echo "  ✓ state-persistence.sh (line $state_persist_line) before error-handling.sh (line $error_handling_line)"
  else
    echo "  ✗ state-persistence.sh must be sourced before error-handling.sh"
    violations=$((violations + 1))
  fi

  if [ "$state_persist_line" -lt "$verification_line" ]; then
    echo "  ✓ state-persistence.sh (line $state_persist_line) before verification-helpers.sh (line $verification_line)"
  else
    echo "  ✗ state-persistence.sh must be sourced before verification-helpers.sh"
    violations=$((violations + 1))
  fi

  return $violations
}

# Run tests
echo "========================================="
echo "Testing library sourcing order"
echo "========================================="
echo ""

echo "Test 1: /coordinate sourcing order"
test_coordinate_sourcing_order
run_test "Coordinate command sourcing order" $?
echo ""

echo "Test 2: Source guards"
test_source_guards
run_test "Library source guards present" $?
echo ""

echo "Test 3: Early sourcing"
test_early_sourcing
run_test "Libraries sourced early in initialization" $?
echo ""

echo "Test 4: Dependency order"
test_dependency_order
run_test "state-persistence sourced before dependent libraries" $?
echo ""

# Summary
echo "========================================="
echo "Test Summary"
echo "========================================="
echo "Total tests: $total_tests"
echo "Passed: $passed_tests"
echo "Failed: $failed_tests"
echo ""

if [ $failed_tests -eq 0 ]; then
  echo "✓ All library sourcing order tests passed"
  exit 0
else
  echo "✗ Some library sourcing order tests failed"
  exit 1
fi
