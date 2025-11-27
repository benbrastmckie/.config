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
CLAUDE_LIB="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Source the unified location detection library
source "${CLAUDE_LIB}/core/unified-location-detection.sh"

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
  local test_name="Sequential allocation (000-009)"
  local test_root="/tmp/test_specs_seq_$$"

  # Setup
  mkdir -p "$test_root"

  # Execute: create 10 topics sequentially
  local failed=false
  for i in {0..9}; do
    local result
    result=$(allocate_and_create_topic "$test_root" "topic_$i")
    local topic_num="${result%|*}"
    local topic_path="${result#*|}"

    # Verify number matches expected (now starts from 000)
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
  local test_name="Empty specs directory (first topic = 000)"
  local test_root="/tmp/test_empty_$$"

  # Setup: create empty directory
  mkdir -p "$test_root"

  # Execute: allocate first topic
  local result
  result=$(allocate_and_create_topic "$test_root" "first_topic")
  local topic_num="${result%|*}"

  # Verify: first topic is 000
  if [ "$topic_num" = "000" ]; then
    pass "$test_name"
  else
    fail "$test_name - Expected 000, got $topic_num"
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

  # Verify: path format (first topic is now 000)
  local expected_path="${test_root}/000_my_topic"
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

# Test 10: Concurrent first allocation (race for 000)
test_concurrent_first_allocation() {
  local test_name="Concurrent first allocation (race for 000)"
  local test_root="/tmp/test_first_$$"

  # Setup: empty directory
  mkdir -p "$test_root"

  # Execute: Launch 5 parallel processes racing for first topic
  for i in {1..5}; do
    (allocate_and_create_topic "$test_root" "first_race_$i" > /dev/null) &
  done
  wait

  # Verify: 5 unique directories (000-004)
  local count
  count=$(ls -1d "$test_root"/[0-9][0-9][0-9]_* 2>/dev/null | wc -l)

  if [ "$count" -ne 5 ]; then
    fail "$test_name - Expected 5 directories, got $count"
    rm -rf "$test_root"
    return
  fi

  # Check that 000 exists (someone won the race)
  if ls -d "$test_root"/000_* > /dev/null 2>&1; then
    pass "$test_name"
  else
    fail "$test_name - 000 directory not created"
  fi

  # Cleanup
  rm -rf "$test_root"
}

# Test 11: Rollover from 999 to 000
test_rollover() {
  local test_name="Rollover from 999 to 000"
  local test_root="/tmp/test_rollover_$$"

  # Setup: create directory with topic 999
  mkdir -p "$test_root/999_existing"

  # Execute: allocate next topic
  local result
  result=$(allocate_and_create_topic "$test_root" "after_999")
  local topic_num="${result%|*}"

  # Verify: next topic is 000 (rollover)
  if [ "$topic_num" = "000" ]; then
    pass "$test_name"
  else
    fail "$test_name - Expected 000 after 999, got $topic_num"
  fi

  # Cleanup
  rm -rf "$test_root"
}

# Test 12: Collision detection after rollover
test_collision_detection() {
  local test_name="Collision detection after rollover"
  local test_root="/tmp/test_collision_$$"

  # Setup: create topics 999 and 000
  mkdir -p "$test_root/999_existing"
  mkdir -p "$test_root/000_existing"

  # Execute: allocate next topic (should skip 000 and go to 001)
  local result
  result=$(allocate_and_create_topic "$test_root" "collision_test")
  local topic_num="${result%|*}"

  # Verify: skipped collision, got 001
  if [ "$topic_num" = "001" ]; then
    pass "$test_name"
  else
    fail "$test_name - Expected 001 (skip collision), got $topic_num"
  fi

  # Cleanup
  rm -rf "$test_root"
}

# Test 13: Multiple consecutive collisions
test_multiple_collisions() {
  local test_name="Multiple consecutive collisions"
  local test_root="/tmp/test_multi_collision_$$"

  # Setup: create topics 999, 000, 001, 002
  mkdir -p "$test_root/999_existing"
  mkdir -p "$test_root/000_existing"
  mkdir -p "$test_root/001_existing"
  mkdir -p "$test_root/002_existing"

  # Execute: allocate next topic (should skip 000, 001, 002 and go to 003)
  local result
  result=$(allocate_and_create_topic "$test_root" "multi_collision")
  local topic_num="${result%|*}"

  # Verify: skipped all collisions, got 003
  if [ "$topic_num" = "003" ]; then
    pass "$test_name"
  else
    fail "$test_name - Expected 003 (skip collisions), got $topic_num"
  fi

  # Cleanup
  rm -rf "$test_root"
}

# Test 14: Increment past duplicate numbered directories (Spec 933 regression test)
# This test simulates the production bug where duplicate-numbered directories existed
# (e.g., 923_topic_a and 923_topic_b created due to race conditions).
# The fix ensures new allocations correctly skip past ALL existing numbered directories.
test_increment_past_duplicates() {
  local test_name="Increment past duplicate numbers (Spec 933 bug)"
  local test_root="/tmp/test_dups_$$"

  # Setup: simulate existing duplicates like production bug (923_topic_a and 923_topic_b)
  # This scenario occurred when race conditions caused same topic number to be allocated twice
  mkdir -p "$test_root/921_topic_before"
  mkdir -p "$test_root/923_topic_a"        # First directory with number 923
  mkdir -p "$test_root/923_topic_b"        # Duplicate! Same number, different name
  mkdir -p "$test_root/924_topic_c"

  # Execute: allocate next topic using atomic function
  local result
  result=$(allocate_and_create_topic "$test_root" "new_topic")
  local topic_num="${result%|*}"
  local topic_path="${result#*|}"

  # Verify: next topic is 925 (incremented past ALL existing directories including duplicates)
  # The atomic function finds max as 924, increments to 925
  if [ "$topic_num" = "925" ]; then
    pass "$test_name"
  else
    fail "$test_name - Expected 925, got $topic_num (should skip past duplicate 923s)"
  fi

  # Additional verification: directory was created
  if [ ! -d "$topic_path" ]; then
    fail "$test_name - Directory not created: $topic_path"
  fi

  # Cleanup
  rm -rf "$test_root"
}

# Run all tests
run_all_tests() {
  echo "=== Atomic Topic Allocation Test Suite ==="
  echo ""
  echo "Testing allocate_and_create_topic() for race condition elimination"
  echo "and rollover behavior (000-999 with collision detection)"
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
  test_rollover
  test_collision_detection
  test_multiple_collisions
  test_increment_past_duplicates

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
