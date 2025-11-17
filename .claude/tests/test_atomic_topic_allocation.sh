#!/bin/bash
# Test atomic topic allocation under concurrent load
#
# This test suite verifies that allocate_and_create_topic() handles concurrent
# access correctly and eliminates race conditions that caused 40-60% collision
# rates under the old count+increment pattern.
#
# Test Isolation:
# All tests use CLAUDE_SPECS_ROOT override to prevent production directory pollution.
# Temporary directories are created in /tmp and cleaned up on exit.

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source the unified location detection library
source "${PROJECT_ROOT}/.claude/lib/unified-location-detection.sh"

# Reset error handling after sourcing library (library sets -e)
set +e

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Color output helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

pass() {
  echo -e "${GREEN}PASS${NC}: $1"
  ((TESTS_PASSED++))
}

fail() {
  echo -e "${RED}FAIL${NC}: $1"
  ((TESTS_FAILED++))
}

warn() {
  echo -e "${YELLOW}WARN${NC}: $1"
}

# Test 1: Sequential allocation
test_sequential_allocation() {
  local test_name="Sequential allocation (001-010)"
  local test_root="/tmp/test_specs_seq_$$"

  # Setup
  mkdir -p "$test_root"

  # Execute: create 10 topics sequentially
  local failed=false
  for i in {1..10}; do
    local result
    result=$(allocate_and_create_topic "$test_root" "topic_$i")
    local topic_num="${result%|*}"
    local topic_path="${result#*|}"

    # Verify number matches expected
    local expected
    expected=$(printf "%03d" "$i")
    if [ "$topic_num" != "$expected" ]; then
      fail "$test_name - Expected $expected, got $topic_num"
      failed=true
      break
    fi

    # Verify directory was created
    if [ ! -d "$topic_path" ]; then
      fail "$test_name - Directory not created: $topic_path"
      failed=true
      break
    fi
  done

  # Cleanup
  rm -rf "$test_root"

  if [ "$failed" = false ]; then
    pass "$test_name"
  fi
}

# Test 2: Concurrent allocation
test_concurrent_allocation() {
  local test_name="Concurrent allocation (10 parallel, no collisions)"
  local test_root="/tmp/test_concurrent_$$"

  # Setup
  mkdir -p "$test_root"

  # Execute: Launch 10 parallel processes
  for i in {1..10}; do
    (allocate_and_create_topic "$test_root" "parallel_$i" > /dev/null) &
  done
  wait

  # Verify: Count directories created
  local count
  count=$(ls -1d "$test_root"/[0-9][0-9][0-9]_* 2>/dev/null | wc -l)

  if [ "$count" -ne 10 ]; then
    fail "$test_name - Expected 10 directories, got $count (collision detected)"
    rm -rf "$test_root"
    return
  fi

  # Check for duplicate numbers
  local duplicates
  duplicates=$(ls -1 "$test_root" | cut -d_ -f1 | sort | uniq -d)

  if [ -n "$duplicates" ]; then
    fail "$test_name - Duplicate numbers found: $duplicates"
    rm -rf "$test_root"
    return
  fi

  # Cleanup
  rm -rf "$test_root"

  pass "$test_name"
}

# Test 3: Stress test (100 allocations)
test_stress_allocation() {
  local test_name="Stress test (100 allocations, 10 parallel)"
  local test_root="/tmp/test_stress_$$"

  # Setup
  mkdir -p "$test_root"

  local start_time
  start_time=$(date +%s)

  # Execute: 100 allocations (10 iterations x 10 parallel processes)
  for iteration in {1..10}; do
    for proc in {1..10}; do
      (allocate_and_create_topic "$test_root" "stress_${iteration}_${proc}" > /dev/null) &
    done
    wait
  done

  local end_time
  end_time=$(date +%s)
  local duration=$((end_time - start_time))

  # Verify: 100 directories created
  local count
  count=$(ls -1d "$test_root"/[0-9][0-9][0-9]_* 2>/dev/null | wc -l)

  if [ "$count" -ne 100 ]; then
    fail "$test_name - Expected 100 directories, got $count (collision rate: $((100 - count))%)"
    rm -rf "$test_root"
    return
  fi

  # Check for duplicates
  local duplicates
  duplicates=$(ls -1 "$test_root" | cut -d_ -f1 | sort | uniq -d | wc -l)

  if [ "$duplicates" -gt 0 ]; then
    fail "$test_name - Found $duplicates duplicate numbers"
    rm -rf "$test_root"
    return
  fi

  # Cleanup
  rm -rf "$test_root"

  pass "$test_name (100 allocations, 0% collision rate, ${duration}s total)"
}

# Test 4: Lock file creation
test_lock_file_creation() {
  local test_name="Lock file creation"
  local test_root="/tmp/test_lock_$$"

  # Setup
  mkdir -p "$test_root"

  # Execute: allocate one topic
  allocate_and_create_topic "$test_root" "test_topic" > /dev/null

  # Verify: lock file exists
  if [ -f "${test_root}/.topic_number.lock" ]; then
    pass "$test_name"
  else
    fail "$test_name - Lock file not created"
  fi

  # Cleanup
  rm -rf "$test_root"
}

# Test 5: Empty specs directory (first topic)
test_empty_specs_directory() {
  local test_name="Empty specs directory (first topic = 001)"
  local test_root="/tmp/test_empty_$$"

  # Setup: create empty directory
  mkdir -p "$test_root"

  # Execute: allocate first topic
  local result
  result=$(allocate_and_create_topic "$test_root" "first_topic")
  local topic_num="${result%|*}"

  # Verify: first topic is 001
  if [ "$topic_num" = "001" ]; then
    pass "$test_name"
  else
    fail "$test_name - Expected 001, got $topic_num"
  fi

  # Cleanup
  rm -rf "$test_root"
}

# Test 6: Existing directories (increment from max)
test_existing_directories() {
  local test_name="Existing directories (increment from max)"
  local test_root="/tmp/test_existing_$$"

  # Setup: create directory with existing topics
  mkdir -p "$test_root/005_topic_a"
  mkdir -p "$test_root/010_topic_b"
  mkdir -p "$test_root/003_topic_c"

  # Execute: allocate next topic
  local result
  result=$(allocate_and_create_topic "$test_root" "new_topic")
  local topic_num="${result%|*}"

  # Verify: next topic is 011 (max was 010)
  if [ "$topic_num" = "011" ]; then
    pass "$test_name"
  else
    fail "$test_name - Expected 011, got $topic_num"
  fi

  # Cleanup
  rm -rf "$test_root"
}

# Test 7: Topic path format
test_topic_path_format() {
  local test_name="Topic path format (NNN_name)"
  local test_root="/tmp/test_format_$$"

  # Setup
  mkdir -p "$test_root"

  # Execute: allocate topic
  local result
  result=$(allocate_and_create_topic "$test_root" "my_topic")
  local topic_path="${result#*|}"

  # Verify: path format
  local expected_path="${test_root}/001_my_topic"
  if [ "$topic_path" = "$expected_path" ]; then
    pass "$test_name"
  else
    fail "$test_name - Expected $expected_path, got $topic_path"
  fi

  # Cleanup
  rm -rf "$test_root"
}

# Test 8: Return format (pipe-delimited)
test_return_format() {
  local test_name="Return format (number|path)"
  local test_root="/tmp/test_return_$$"

  # Setup
  mkdir -p "$test_root"

  # Execute: allocate topic
  local result
  result=$(allocate_and_create_topic "$test_root" "test_return")

  # Verify: pipe-delimited format
  if [[ "$result" =~ ^[0-9]{3}\| ]]; then
    pass "$test_name"
  else
    fail "$test_name - Invalid format: $result"
  fi

  # Cleanup
  rm -rf "$test_root"
}

# Test 9: Directory creation verification
test_directory_creation() {
  local test_name="Directory creation verification"
  local test_root="/tmp/test_dir_$$"

  # Setup
  mkdir -p "$test_root"

  # Execute: allocate topic
  local result
  result=$(allocate_and_create_topic "$test_root" "verify_dir")
  local topic_path="${result#*|}"

  # Verify: directory exists
  if [ -d "$topic_path" ]; then
    pass "$test_name"
  else
    fail "$test_name - Directory not created: $topic_path"
  fi

  # Cleanup
  rm -rf "$test_root"
}

# Test 10: Concurrent first allocation (race for 001)
test_concurrent_first_allocation() {
  local test_name="Concurrent first allocation (race for 001)"
  local test_root="/tmp/test_first_$$"

  # Setup: empty directory
  mkdir -p "$test_root"

  # Execute: Launch 5 parallel processes racing for first topic
  for i in {1..5}; do
    (allocate_and_create_topic "$test_root" "first_race_$i" > /dev/null) &
  done
  wait

  # Verify: 5 unique directories (001-005)
  local count
  count=$(ls -1d "$test_root"/[0-9][0-9][0-9]_* 2>/dev/null | wc -l)

  if [ "$count" -ne 5 ]; then
    fail "$test_name - Expected 5 directories, got $count"
    rm -rf "$test_root"
    return
  fi

  # Check that 001 exists (someone won the race)
  if ls -d "$test_root"/001_* > /dev/null 2>&1; then
    pass "$test_name"
  else
    fail "$test_name - 001 directory not created"
  fi

  # Cleanup
  rm -rf "$test_root"
}

# Run all tests
run_all_tests() {
  echo "=== Atomic Topic Allocation Test Suite ==="
  echo ""
  echo "Testing allocate_and_create_topic() for race condition elimination"
  echo ""

  test_sequential_allocation
  test_concurrent_allocation
  test_stress_allocation
  test_lock_file_creation
  test_empty_specs_directory
  test_existing_directories
  test_topic_path_format
  test_return_format
  test_directory_creation
  test_concurrent_first_allocation

  echo ""
  echo "=== Test Summary ==="
  echo "Passed: $TESTS_PASSED"
  echo "Failed: $TESTS_FAILED"
  echo ""

  if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed${NC}"
    return 0
  else
    echo -e "${RED}$TESTS_FAILED test(s) failed${NC}"
    return 1
  fi
}

# Run tests
run_all_tests
