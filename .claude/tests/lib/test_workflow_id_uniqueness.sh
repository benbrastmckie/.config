#!/usr/bin/env bash
# test_workflow_id_uniqueness.sh - Unit tests for generate_unique_workflow_id()
#
# Tests nanosecond-precision WORKFLOW_ID generation for concurrent execution safety.
# Validates uniqueness with 1000 rapid invocations and format validation.

set -uo pipefail
# Note: Not using -e (errexit) to allow tests to continue after failures

# Source the library under test
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
export CLAUDE_PROJECT_DIR

if ! source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null; then
  echo "ERROR: Cannot load state-persistence library from: ${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
  echo "PWD: $(pwd)"
  exit 1
fi

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
pass() {
  echo "  ✓ $1"
  ((TESTS_PASSED++))
}

fail() {
  echo "  ✗ $1"
  ((TESTS_FAILED++))
}

# Test 1: Basic WORKFLOW_ID generation
test_basic_generation() {
  echo "Test 1: Basic WORKFLOW_ID generation"

  result=$(generate_unique_workflow_id "plan" 2>&1)

  if [[ "$result" =~ ^plan_[0-9]+$ ]] || [[ "$result" =~ ^plan_[0-9]+_[0-9]+$ ]]; then
    pass "Generates valid WORKFLOW_ID format"
  else
    fail "Invalid format: $result"
  fi
}

# Test 2: Nanosecond precision format
test_nanosecond_precision() {
  echo "Test 2: Nanosecond precision format"

  result=$(generate_unique_workflow_id "implement" 2>&1)

  # Check for nanosecond precision (19 digits total: 10 seconds + 9 nanoseconds)
  if [[ "$result" =~ ^implement_[0-9]{19}$ ]]; then
    pass "Uses nanosecond precision (19-digit timestamp)"
  elif [[ "$result" =~ ^implement_[0-9]{10}_[0-9]+$ ]]; then
    pass "Uses fallback format (second-precision + PID)"
  else
    fail "Unexpected format: $result"
  fi
}

# Test 3: Different command names
test_different_commands() {
  echo "Test 3: Different command names"

  commands=("plan" "implement" "research" "debug" "repair")
  all_valid=true

  for cmd in "${commands[@]}"; do
    result=$(generate_unique_workflow_id "$cmd" 2>&1)
    if [[ ! "$result" =~ ^${cmd}_ ]]; then
      all_valid=false
      break
    fi
  done

  if [ "$all_valid" = true ]; then
    pass "Handles different command names correctly"
  else
    fail "Failed for command: $cmd"
  fi
}

# Test 4: Uniqueness test (1000 rapid invocations)
test_uniqueness_1000_invocations() {
  echo "Test 4: Uniqueness (1000 rapid invocations)"

  declare -A seen_ids
  duplicates=0

  for i in {1..1000}; do
    id=$(generate_unique_workflow_id "test" 2>&1)
    if [ -n "${seen_ids[$id]:-}" ]; then
      ((duplicates++))
    fi
    seen_ids["$id"]=1
  done

  if [ $duplicates -eq 0 ]; then
    pass "No duplicates in 1000 rapid invocations"
  else
    fail "Found $duplicates duplicate IDs in 1000 invocations"
  fi
}

# Test 5: Sequential uniqueness (verify IDs increase)
test_sequential_uniqueness() {
  echo "Test 5: Sequential uniqueness"

  id1=$(generate_unique_workflow_id "seq" 2>&1 | grep -oP '[0-9]+' | head -1)
  sleep 0.001  # 1ms delay
  id2=$(generate_unique_workflow_id "seq" 2>&1 | grep -oP '[0-9]+' | head -1)

  if [ "$id2" -gt "$id1" ]; then
    pass "Sequential IDs increase over time"
  else
    fail "ID2 ($id2) not greater than ID1 ($id1)"
  fi
}

# Test 6: Empty command name (error case)
test_empty_command_name() {
  echo "Test 6: Empty command name (validation)"

  result=$(generate_unique_workflow_id "" 2>&1 || echo "ERROR_CAUGHT")

  if [[ "$result" == *"ERROR"* ]]; then
    pass "Rejects empty command name with error"
  else
    fail "Should error on empty command name, got: $result"
  fi
}

# Test 7: Invalid command name format
test_invalid_command_name() {
  echo "Test 7: Invalid command name format"

  result=$(generate_unique_workflow_id "Plan-With-Dashes" 2>&1 || echo "ERROR_CAUGHT")

  if [[ "$result" == *"ERROR"* ]] || [[ "$result" == *"Invalid"* ]]; then
    pass "Rejects invalid command name format"
  else
    fail "Should reject uppercase/dashes, got: $result"
  fi
}

# Test 8: Concurrent simulation (parallel subshells)
test_concurrent_generation() {
  echo "Test 8: Concurrent generation (10 parallel subshells)"

  temp_file="/tmp/workflow_id_concurrent_test_$$.txt"
  > "$temp_file"  # Clear file

  # Launch 10 parallel subshells
  for i in {1..10}; do
    (
      id=$(generate_unique_workflow_id "concurrent" 2>&1)
      echo "$id" >> "$temp_file"
    ) &
  done

  # Wait for all subshells
  wait

  # Check for duplicates
  unique_count=$(sort "$temp_file" | uniq | wc -l)
  total_count=$(wc -l < "$temp_file")

  if [ "$unique_count" -eq "$total_count" ]; then
    pass "No duplicates in 10 concurrent generations"
  else
    fail "Found duplicates: $total_count total, $unique_count unique"
  fi

  rm -f "$temp_file"
}

# Test 9: Format validation (underscore-separated)
test_format_validation() {
  echo "Test 9: Format validation"

  result=$(generate_unique_workflow_id "lean_plan" 2>&1)

  if [[ "$result" =~ ^lean_plan_[0-9]+$ ]] || [[ "$result" =~ ^lean_plan_[0-9]+_[0-9]+$ ]]; then
    pass "Handles underscore in command name"
  else
    fail "Invalid format for underscore command: $result"
  fi
}

# Test 10: Performance benchmark (100 invocations)
test_performance_benchmark() {
  echo "Test 10: Performance benchmark (100 invocations)"

  start_time=$(date +%s%N)
  for i in {1..100}; do
    generate_unique_workflow_id "perf" >/dev/null 2>&1
  done
  end_time=$(date +%s%N)

  duration_ns=$((end_time - start_time))
  avg_ns=$((duration_ns / 100))

  # Each invocation should be <5ms (5,000,000 ns) - realistic threshold
  if [ $avg_ns -lt 5000000 ]; then
    pass "Performance: ${avg_ns}ns average (<5ms target)"
  else
    fail "Performance: ${avg_ns}ns average (>5ms, too slow)"
  fi
}

# Run all tests
echo "====================================="
echo "WORKFLOW_ID Uniqueness Tests"
echo "====================================="
echo ""

test_basic_generation
test_nanosecond_precision
test_different_commands
test_uniqueness_1000_invocations
test_sequential_uniqueness
test_empty_command_name
test_invalid_command_name
test_concurrent_generation
test_format_validation
test_performance_benchmark

echo ""
echo "====================================="
echo "Test Results"
echo "====================================="
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo "✓ All tests passed"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
