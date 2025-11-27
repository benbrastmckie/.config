#!/usr/bin/env bash
# test_collision_detection.sh
#
# Unit tests for collision detection in allocate_and_create_topic()

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/../.."

# Source test helpers
source "${SCRIPT_DIR}/../lib/test-helpers.sh" 2>/dev/null || \
  { echo "Cannot load test helpers"; exit 1; }

# Source library under test
LIB_PATH="${PROJECT_ROOT}/lib/core/unified-location-detection.sh"

setup_test

# Test: Sequential allocation from max (doesn't fill gaps)
test_sequential_allocation() {
  local test_specs="/tmp/test_collision_$$"
  mkdir -p "$test_specs/000_first" "$test_specs/001_second" "$test_specs/003_fourth"

  local result
  result=$(bash -c "
    source '$LIB_PATH' 2>/dev/null
    allocate_and_create_topic '$test_specs' 'next' 2>&1
  ")

  local topic_num="${result%|*}"

  # Should be max+1 = 004 (doesn't fill gap at 002)
  if [[ "$topic_num" == "004" ]]; then
    pass "sequential_allocation"
  else
    fail "sequential_allocation" "Expected: 004, Got: $topic_num"
  fi

  rm -rf "$test_specs"
}

# Test: Collision detection when number exists
test_collision_detection() {
  local test_specs="/tmp/test_collision_$$"
  mkdir -p "$test_specs/000_first"

  # Manually create what would be the next number
  mkdir -p "$test_specs/001_manual"

  local result
  result=$(bash -c "
    source '$LIB_PATH' 2>/dev/null
    allocate_and_create_topic '$test_specs' 'auto' 2>&1
  ")

  local topic_num="${result%|*}"

  # Should skip to 002
  if [[ "$topic_num" == "002" ]]; then
    pass "collision_detection"
  else
    fail "collision_detection" "Expected: 002, Got: $topic_num"
  fi

  rm -rf "$test_specs"
}

# Test: Multiple collisions resolved
test_multiple_collisions() {
  local test_specs="/tmp/test_collision_$$"
  mkdir -p "$test_specs/000_a" "$test_specs/001_b" "$test_specs/002_c" "$test_specs/003_d"

  local result
  result=$(bash -c "
    source '$LIB_PATH' 2>/dev/null
    allocate_and_create_topic '$test_specs' 'next' 2>&1
  ")

  local topic_num="${result%|*}"

  if [[ "$topic_num" == "004" ]]; then
    pass "multiple_collisions"
  else
    fail "multiple_collisions" "Expected: 004, Got: $topic_num"
  fi

  rm -rf "$test_specs"
}

# Test: Rollover collision detection
test_rollover_collision() {
  local test_specs="/tmp/test_collision_rollover_$$"
  mkdir -p "$test_specs/999_last" "$test_specs/000_first"

  # Call directly (not in subshell to avoid variable expansion issues)
  source "$LIB_PATH" 2>/dev/null
  local result
  result=$(allocate_and_create_topic "$test_specs" "rollover" 2>&1)

  local topic_num="${result%|*}"

  # Should rollover from 999 to 000, then detect collision and go to 001
  if [[ "$topic_num" == "001" ]]; then
    pass "rollover_collision"
  else
    fail "rollover_collision" "Expected: 001, Got: $topic_num (full result: $result)"
  fi

  rm -rf "$test_specs"
}

# Run all tests
echo "Running Collision Detection Tests..."
test_sequential_allocation
test_collision_detection
test_multiple_collisions
test_rollover_collision

teardown_test
