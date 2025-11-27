#!/usr/bin/env bash
#
# test_convert_docs_concurrency.sh - Test concurrency protection for convert-core.sh
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Script path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SCRIPT_PATH="$CLAUDE_ROOT/lib/convert/convert-core.sh"

# Test directories
TEST_BASE_DIR="/tmp/convert-docs-concurrency-test-$$"
TEST_INPUT="$TEST_BASE_DIR/input"
TEST_OUTPUT="$TEST_BASE_DIR/output"

#
# setup_test_env - Create test environment
#
setup_test_env() {
  mkdir -p "$TEST_INPUT"
  mkdir -p "$TEST_OUTPUT"
}

#
# cleanup_test_env - Remove test environment
#
cleanup_test_env() {
  rm -rf "$TEST_BASE_DIR"
}

#
# create_test_docx - Create a minimal test DOCX file
#
create_test_docx() {
  local filename="$1"
  local filepath="$TEST_INPUT/$filename.docx"

  # Create minimal ZIP (DOCX) file with PK header
  # This creates a valid but minimal DOCX structure
  if command -v zip &>/dev/null; then
    echo "Test content" > "$TEST_INPUT/test.txt"
    (cd "$TEST_INPUT" && zip -q "$filename.docx" test.txt)
    rm "$TEST_INPUT/test.txt"
  else
    # Fallback: Create file with PK header (minimal DOCX signature)
    printf 'PK\x03\x04' > "$filepath"
    echo "test content" >> "$filepath"
  fi
}

#
# run_test - Run a single test
#
# Arguments:
#   $1 - Test description
#   $2 - Test function name
#
run_test() {
  local description="$1"
  local test_func="$2"

  TESTS_RUN=$((TESTS_RUN + 1))

  # Clean output directory between tests
  rm -rf "$TEST_OUTPUT"
  mkdir -p "$TEST_OUTPUT"

  if $test_func; then
    echo -e "${GREEN}✓${NC} PASS: $description"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} FAIL: $description"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

#
# test_concurrent_execution_blocked - Test that concurrent executions are blocked
#
test_concurrent_execution_blocked() {
  # Create test file
  create_test_docx "test1"

  # Start first conversion in background
  "$SCRIPT_PATH" "$TEST_INPUT" "$TEST_OUTPUT" &
  local first_pid=$!

  # Give it time to acquire lock
  sleep 0.5

  # Try second conversion (should be blocked)
  local output
  output=$("$SCRIPT_PATH" "$TEST_INPUT" "$TEST_OUTPUT" 2>&1 || true)

  # Check that second instance reported the lock
  if echo "$output" | grep -q "Another conversion is already running"; then
    # Kill first process and wait for cleanup
    kill "$first_pid" 2>/dev/null || true
    wait "$first_pid" 2>/dev/null || true
    return 0
  else
    # Kill first process and wait for cleanup
    kill "$first_pid" 2>/dev/null || true
    wait "$first_pid" 2>/dev/null || true
    return 1
  fi
}

#
# test_lock_file_created - Test that lock file is created
#
test_lock_file_created() {
  # Create test file
  create_test_docx "test2"

  # Start conversion in background
  "$SCRIPT_PATH" "$TEST_INPUT" "$TEST_OUTPUT" &
  local pid=$!

  # Give it time to create lock
  sleep 0.5

  # Check lock file exists and contains PID
  local lock_file="$TEST_OUTPUT/.convert-docs.lock"
  if [[ -f "$lock_file" ]]; then
    local lock_pid
    lock_pid=$(cat "$lock_file")

    # Kill process and wait
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true

    # Check that lock contained the PID
    if [[ "$lock_pid" == "$pid" ]]; then
      return 0
    fi
  else
    # Kill process and wait
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  fi

  return 1
}

#
# test_lock_released_on_completion - Test that lock is released when script completes
#
test_lock_released_on_completion() {
  # Create test file
  create_test_docx "test3"

  # Run conversion (synchronously)
  "$SCRIPT_PATH" "$TEST_INPUT" "$TEST_OUTPUT" >/dev/null 2>&1 || true

  # Check lock file is removed
  local lock_file="$TEST_OUTPUT/.convert-docs.lock"
  if [[ ! -f "$lock_file" ]]; then
    return 0
  fi

  return 1
}

#
# test_lock_released_on_interrupt - Test that lock is released on interrupt
#
test_lock_released_on_interrupt() {
  # Create test file
  create_test_docx "test4"

  # Start conversion in background
  "$SCRIPT_PATH" "$TEST_INPUT" "$TEST_OUTPUT" >/dev/null 2>&1 &
  local pid=$!

  # Give it time to acquire lock
  sleep 0.5

  # Send interrupt signal
  kill -INT "$pid" 2>/dev/null || true

  # Wait for cleanup
  wait "$pid" 2>/dev/null || true
  sleep 0.5

  # Check lock file is removed
  local lock_file="$TEST_OUTPUT/.convert-docs.lock"
  if [[ ! -f "$lock_file" ]]; then
    return 0
  fi

  return 1
}

#
# test_stale_lock_cleanup - Test that stale locks are cleaned up
#
test_stale_lock_cleanup() {
  # Create test file
  create_test_docx "test5"

  # Create stale lock with non-existent PID
  local lock_file="$TEST_OUTPUT/.convert-docs.lock"
  echo "999999" > "$lock_file"

  # Run conversion (should clean up stale lock and proceed)
  local output
  output=$("$SCRIPT_PATH" "$TEST_INPUT" "$TEST_OUTPUT" 2>&1 || true)

  # Check that script reported stale lock removal
  if echo "$output" | grep -q "Removing stale lock file"; then
    return 0
  fi

  return 1
}

#
# test_lock_with_our_pid - Test that script doesn't block itself with its own PID
#
test_lock_with_our_pid() {
  # This test verifies the lock contains the correct PID

  # Create test file
  create_test_docx "test6"

  # Start conversion in background
  "$SCRIPT_PATH" "$TEST_INPUT" "$TEST_OUTPUT" >/dev/null 2>&1 &
  local pid=$!

  # Give it time to create lock
  sleep 0.5

  # Read lock file
  local lock_file="$TEST_OUTPUT/.convert-docs.lock"
  if [[ -f "$lock_file" ]]; then
    local lock_pid
    lock_pid=$(cat "$lock_file")

    # Kill process
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true

    # Verify lock had correct PID
    if [[ "$lock_pid" == "$pid" ]]; then
      return 0
    fi
  else
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  fi

  return 1
}

#
# test_lock_survives_directory_creation - Test lock works even if directory doesn't exist
#
test_lock_survives_directory_creation() {
  # Create test file
  create_test_docx "test7"

  # Remove output directory
  rm -rf "$TEST_OUTPUT"

  # Run conversion (should create directory and lock)
  "$SCRIPT_PATH" "$TEST_INPUT" "$TEST_OUTPUT" >/dev/null 2>&1 || true

  # Check that directory was created and lock was cleaned up
  if [[ -d "$TEST_OUTPUT" ]] && [[ ! -f "$TEST_OUTPUT/.convert-docs.lock" ]]; then
    return 0
  fi

  return 1
}

#
# test_parallel_mode_uses_lock - Test that parallel mode also uses lock
#
test_parallel_mode_uses_lock() {
  # Create test files
  create_test_docx "test8a"
  create_test_docx "test8b"

  # Start parallel conversion in background
  "$SCRIPT_PATH" "$TEST_INPUT" "$TEST_OUTPUT" --parallel 2 >/dev/null 2>&1 &
  local first_pid=$!

  # Give it time to acquire lock
  sleep 0.5

  # Try second conversion (should be blocked even in parallel mode)
  local output
  output=$("$SCRIPT_PATH" "$TEST_INPUT" "$TEST_OUTPUT" 2>&1 || true)

  # Check that second instance reported the lock
  if echo "$output" | grep -q "Another conversion is already running"; then
    kill "$first_pid" 2>/dev/null || true
    wait "$first_pid" 2>/dev/null || true
    return 0
  else
    kill "$first_pid" 2>/dev/null || true
    wait "$first_pid" 2>/dev/null || true
    return 1
  fi
}

#
# main - Run all tests
#
main() {
  echo "========================================"
  echo "Concurrency Protection Tests"
  echo "========================================"
  echo ""

  # Check if script exists
  if [[ ! -f "$SCRIPT_PATH" ]]; then
    echo -e "${RED}Error: convert-core.sh not found at $SCRIPT_PATH${NC}"
    exit 1
  fi

  # Setup
  setup_test_env
  trap cleanup_test_env EXIT

  # Test 1: Concurrent execution blocked
  run_test "Concurrent execution blocked" test_concurrent_execution_blocked

  # Test 2: Lock file created
  run_test "Lock file created with PID" test_lock_file_created

  # Test 3: Lock released on completion
  run_test "Lock released on normal completion" test_lock_released_on_completion

  # Test 4: Lock released on interrupt
  run_test "Lock released on interrupt (SIGINT)" test_lock_released_on_interrupt

  # Test 5: Stale lock cleanup
  run_test "Stale lock cleaned up automatically" test_stale_lock_cleanup

  # Test 6: Lock contains correct PID
  run_test "Lock file contains correct PID" test_lock_with_our_pid

  # Test 7: Lock works with directory creation
  run_test "Lock survives directory creation" test_lock_survives_directory_creation

  # Test 8: Parallel mode uses lock
  run_test "Parallel mode also uses lock" test_parallel_mode_uses_lock

  # Summary
  echo ""
  echo "========================================"
  echo "Test Summary"
  echo "========================================"
  echo "Tests run:    $TESTS_RUN"
  echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    exit 1
  else
    echo -e "Tests failed: $TESTS_FAILED"
    echo ""
    echo -e "${GREEN}All concurrency tests passed!${NC}"
    exit 0
  fi
}

# Run tests
main
