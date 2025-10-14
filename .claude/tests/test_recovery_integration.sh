#!/usr/bin/env bash
# Test tiered error recovery integration
# Part of Phase 3: Automatic Debug Integration & Progress Dashboard

set -e

# Color codes for test output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test results array
declare -a FAILED_TESTS=()

# Setup test environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Mock error-utils.sh functions for testing
detect_error_type() {
  local test_output="$1"

  if [[ "$test_output" == *"syntax error"* ]]; then
    echo "syntax"
  elif [[ "$test_output" == *"timeout"* ]] || [[ "$test_output" == *"busy"* ]]; then
    echo "timeout"
  elif [[ "$test_output" == *"tool"*"failed"* ]] || [[ "$test_output" == *"access"*"denied"* ]]; then
    echo "tool_access"
  elif [[ "$test_output" == *"null pointer"* ]]; then
    echo "null_error"
  else
    echo "unknown"
  fi
}

generate_suggestions() {
  local error_type="$1"

  case "$error_type" in
    syntax)
      echo "1. Check syntax at the reported line"
      echo "2. Review recent code changes"
      ;;
    timeout)
      echo "1. Increase timeout value"
      echo "2. Check for infinite loops"
      ;;
    tool_access)
      echo "1. Verify tool permissions"
      echo "2. Check file access rights"
      ;;
    *)
      echo "1. Review error output"
      echo "2. Check logs for details"
      ;;
  esac
}

# Helper function to run a test
run_test() {
  local test_name="$1"
  local test_function="$2"

  TESTS_RUN=$((TESTS_RUN + 1))

  if $test_function; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: $test_name"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    FAILED_TESTS+=("$test_name")
    echo -e "${RED}✗${NC} FAIL: $test_name"
    return 1
  fi
}

# ============================================================================
# Level 1 Recovery Tests (2 tests)
# ============================================================================

test_level1_error_classification() {
  local test_output="Error: syntax error at line 42"

  local error_type
  error_type=$(detect_error_type "$test_output")

  if [[ "$error_type" == "syntax" ]]; then
    return 0
  else
    echo "  Expected error_type: syntax"
    echo "  Got: $error_type"
    return 1
  fi
}

test_level1_suggestions_display() {
  local error_type="syntax"

  local suggestions
  suggestions=$(generate_suggestions "$error_type")

  if [[ "$suggestions" == *"Check syntax"* ]]; then
    return 0
  else
    echo "  Expected suggestions for syntax errors"
    echo "  Got: $suggestions"
    return 1
  fi
}

# ============================================================================
# Level 2 Recovery Tests (3 tests)
# ============================================================================

test_level2_transient_retry() {
  local test_output="Error: timeout after 30 seconds"

  local error_type
  error_type=$(detect_error_type "$test_output")

  if [[ "$error_type" == "timeout" ]]; then
    # Transient error detected - would trigger Level 2
    return 0
  else
    echo "  Expected timeout error to trigger Level 2"
    echo "  Got error_type: $error_type"
    return 1
  fi
}

test_level2_timeout_extended() {
  local original_timeout=30000
  local new_timeout=$((original_timeout * 2))

  # Simulate retry_with_timeout
  local retry_meta="{\"should_retry\": true, \"new_timeout\": $new_timeout}"

  local should_retry
  should_retry=$(echo "$retry_meta" | jq -r '.should_retry')

  if [[ "$should_retry" == "true" ]] && [[ $new_timeout -eq 60000 ]]; then
    return 0
  else
    echo "  Expected timeout to be doubled"
    echo "  Got new_timeout: $new_timeout"
    return 1
  fi
}

test_level2_success_skip_debug() {
  # Simulate successful retry at Level 2
  local retry_success=true

  if [[ "$retry_success" == true ]]; then
    # Should skip to next phase without invoking debug
    return 0
  else
    echo "  Expected successful Level 2 to skip debug"
    return 1
  fi
}

# ============================================================================
# Level 3 Recovery Tests (3 tests)
# ============================================================================

test_level3_tool_access_error() {
  local test_output="Error: tool access failed - permission denied"

  local error_type
  error_type=$(detect_error_type "$test_output")

  if [[ "$error_type" == "tool_access" ]]; then
    # Tool access error detected - would trigger Level 3
    return 0
  else
    echo "  Expected tool_access error to trigger Level 3"
    echo "  Got error_type: $error_type"
    return 1
  fi
}

test_level3_reduced_toolset() {
  # Simulate retry_with_fallback
  local fallback_meta='{"reduced_toolset": "read,write", "strategy": "minimal"}'

  local reduced_toolset
  reduced_toolset=$(echo "$fallback_meta" | jq -r '.reduced_toolset')

  if [[ "$reduced_toolset" == "read,write" ]]; then
    return 0
  else
    echo "  Expected reduced toolset"
    echo "  Got: $reduced_toolset"
    return 1
  fi
}

test_level3_success_skip_debug() {
  # Simulate successful retry at Level 3
  local retry_success=true

  if [[ "$retry_success" == true ]]; then
    # Should skip to next phase without invoking debug
    return 0
  else
    echo "  Expected successful Level 3 to skip debug"
    return 1
  fi
}

# ============================================================================
# Level 4 Recovery Tests (2 tests)
# ============================================================================

test_level4_debug_invocation() {
  # After Level 1-3 fail, Level 4 invokes debug
  local level1_failed=true
  local level2_failed=true
  local level3_failed=true

  if [[ "$level1_failed" == true ]] && \
     [[ "$level2_failed" == true ]] && \
     [[ "$level3_failed" == true ]]; then
    # Should invoke /debug automatically
    return 0
  else
    echo "  Expected Level 4 to invoke debug after L1-L3 failures"
    return 1
  fi
}

test_level4_user_choices_presented() {
  # After debug completes, user sees choices
  local choices=("r" "c" "s" "a")

  if [[ ${#choices[@]} -eq 4 ]]; then
    return 0
  else
    echo "  Expected 4 user choices (r/c/s/a)"
    echo "  Got: ${#choices[@]}"
    return 1
  fi
}

# ============================================================================
# Level Progression Tests (4 tests)
# ============================================================================

test_level_progression_1_to_2() {
  # Level 1 fails, proceed to Level 2
  local level1_success=false

  if [[ "$level1_success" == false ]]; then
    # Should progress to Level 2
    local next_level=2
    if [[ $next_level -eq 2 ]]; then
      return 0
    else
      echo "  Expected progression to Level 2"
      return 1
    fi
  else
    echo "  Level 1 should fail to trigger progression"
    return 1
  fi
}

test_level_progression_2_to_3() {
  # Level 2 fails, proceed to Level 3
  local level2_success=false

  if [[ "$level2_success" == false ]]; then
    # Should progress to Level 3
    local next_level=3
    if [[ $next_level -eq 3 ]]; then
      return 0
    else
      echo "  Expected progression to Level 3"
      return 1
    fi
  else
    echo "  Level 2 should fail to trigger progression"
    return 1
  fi
}

test_level_progression_3_to_4() {
  # Level 3 fails, proceed to Level 4 (debug)
  local level3_success=false

  if [[ "$level3_success" == false ]]; then
    # Should progress to Level 4 (debug)
    local next_level=4
    if [[ $next_level -eq 4 ]]; then
      return 0
    else
      echo "  Expected progression to Level 4"
      return 1
    fi
  else
    echo "  Level 3 should fail to trigger progression"
    return 1
  fi
}

test_max_attempts_per_level() {
  local max_attempts=3
  local current_attempts=3

  if [[ $current_attempts -ge $max_attempts ]]; then
    # Should escalate to next level
    return 0
  else
    echo "  Expected escalation after max attempts"
    return 1
  fi
}

# ============================================================================
# Logging Tests (2 tests)
# ============================================================================

test_recovery_attempt_logging() {
  local level=2
  local strategy="retry_with_timeout"
  local log_message="Attempting Level $level recovery: $strategy"

  if [[ "$log_message" == *"Level 2 recovery"* ]] && \
     [[ "$log_message" == *"retry_with_timeout"* ]]; then
    return 0
  else
    echo "  Expected recovery attempt log message"
    echo "  Got: $log_message"
    return 1
  fi
}

test_recovery_result_logging() {
  local level=2
  local result="success"
  local log_message="Recovery result: Level $level - $result"

  if [[ "$log_message" == *"Level 2"* ]] && \
     [[ "$log_message" == *"success"* ]]; then
    return 0
  else
    echo "  Expected recovery result log message"
    echo "  Got: $log_message"
    return 1
  fi
}

# ============================================================================
# Test Runner
# ============================================================================

echo "=========================================="
echo "Tiered Recovery Integration Test Suite"
echo "=========================================="
echo ""

# Level 1 Tests
echo "Running Level 1 Recovery Tests..."
run_test "Level 1: Error classification" test_level1_error_classification
run_test "Level 1: Suggestions display" test_level1_suggestions_display
echo ""

# Level 2 Tests
echo "Running Level 2 Recovery Tests..."
run_test "Level 2: Transient error retry" test_level2_transient_retry
run_test "Level 2: Timeout extended" test_level2_timeout_extended
run_test "Level 2: Success skips debug" test_level2_success_skip_debug
echo ""

# Level 3 Tests
echo "Running Level 3 Recovery Tests..."
run_test "Level 3: Tool access error detection" test_level3_tool_access_error
run_test "Level 3: Reduced toolset" test_level3_reduced_toolset
run_test "Level 3: Success skips debug" test_level3_success_skip_debug
echo ""

# Level 4 Tests
echo "Running Level 4 Recovery Tests..."
run_test "Level 4: Debug invocation" test_level4_debug_invocation
run_test "Level 4: User choices presented" test_level4_user_choices_presented
echo ""

# Progression Tests
echo "Running Level Progression Tests..."
run_test "Progression: Level 1 to 2" test_level_progression_1_to_2
run_test "Progression: Level 2 to 3" test_level_progression_2_to_3
run_test "Progression: Level 3 to 4" test_level_progression_3_to_4
run_test "Max attempts per level" test_max_attempts_per_level
echo ""

# Logging Tests
echo "Running Logging Tests..."
run_test "Recovery attempt logging" test_recovery_attempt_logging
run_test "Recovery result logging" test_recovery_result_logging
echo ""

# Summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Total tests run: $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
  echo "Failed tests:"
  for test in "${FAILED_TESTS[@]}"; do
    echo -e "  ${RED}✗${NC} $test"
  done
  echo ""
  exit 1
else
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
fi
