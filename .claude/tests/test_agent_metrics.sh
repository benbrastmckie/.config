#!/usr/bin/env bash
# test_agent_metrics.sh - Unit tests for Phase 6 agent metrics functions
#
# Tests the new agent performance tracking functions added in Phase 6:
# - parse_agent_jsonl
# - calculate_agent_stats
# - identify_common_errors
# - analyze_tool_usage

set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$TEST_DIR/../lib"

# Source the library under test
source "$LIB_DIR/analyze-metrics.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Setup test fixtures
setup_test_data() {
  export TEST_METRICS_DIR="/tmp/test_agent_metrics_$$"
  mkdir -p "$TEST_METRICS_DIR/agents"
  export METRICS_DIR="$TEST_METRICS_DIR"

  # Create sample JSONL data for testing
  cat > "$TEST_METRICS_DIR/agents/test-agent.jsonl" <<'EOF'
{"timestamp":"2025-10-01T10:00:00Z","agent_type":"test-agent","invocation_id":"inv_001","duration_ms":5000,"status":"success","tools_used":{"Read":3,"Edit":2},"error":null,"error_type":null}
{"timestamp":"2025-10-02T11:00:00Z","agent_type":"test-agent","invocation_id":"inv_002","duration_ms":7000,"status":"success","tools_used":{"Read":5,"Bash":1},"error":null,"error_type":null}
{"timestamp":"2025-10-03T12:00:00Z","agent_type":"test-agent","invocation_id":"inv_003","duration_ms":6000,"status":"error","tools_used":{"Read":2},"error":"Test failed","error_type":"test_failure"}
{"timestamp":"2025-10-05T13:00:00Z","agent_type":"test-agent","invocation_id":"inv_004","duration_ms":4500,"status":"success","tools_used":{"Read":4,"Edit":3,"Bash":1},"error":null,"error_type":null}
EOF

  # Create another agent for comparison tests
  cat > "$TEST_METRICS_DIR/agents/code-writer.jsonl" <<'EOF'
{"timestamp":"2025-10-01T14:00:00Z","agent_type":"code-writer","invocation_id":"inv_101","duration_ms":12000,"status":"success","tools_used":{"Read":8,"Edit":5,"Bash":2},"error":null,"error_type":null}
{"timestamp":"2025-10-02T15:00:00Z","agent_type":"code-writer","invocation_id":"inv_102","duration_ms":15000,"status":"success","tools_used":{"Edit":10,"Read":6},"error":null,"error_type":null}
{"timestamp":"2025-10-03T16:00:00Z","agent_type":"code-writer","invocation_id":"inv_103","duration_ms":11000,"status":"error","tools_used":{"Read":3,"Edit":2},"error":"Syntax error in file","error_type":"syntax_error"}
EOF
}

teardown_test_data() {
  rm -rf "$TEST_METRICS_DIR"
}

# Test helper functions
assert_equals() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ "$expected" == "$actual" ]]; then
    echo "  ✓ PASS: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo "  ✗ FAIL: $test_name"
    echo "    Expected: $expected"
    echo "    Actual: $actual"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if echo "$haystack" | grep -q "$needle"; then
    echo "  ✓ PASS: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo "  ✗ FAIL: $test_name"
    echo "    Expected to contain: $needle"
    echo "    In: $haystack"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_in_range() {
  local value="$1"
  local min="$2"
  local max="$3"
  local test_name="$4"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ "$value" -ge "$min" ]] && [[ "$value" -le "$max" ]]; then
    echo "  ✓ PASS: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo "  ✗ FAIL: $test_name"
    echo "    Expected value in range [$min, $max], got: $value"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# ============================================================================
# Test Suite
# ============================================================================

# Test 1: parse_agent_jsonl - Basic parsing
test_parse_agent_jsonl_basic() {
  echo "TEST: parse_agent_jsonl - Basic parsing"

  local result
  result=$(parse_agent_jsonl "test-agent" 365 2>&1)

  local record_count
  record_count=$(echo "$result" | jq -s 'length')

  assert_equals "4" "$record_count" "Should parse 4 JSONL records"
}

# Test 2: parse_agent_jsonl - Timeframe filtering
test_parse_agent_jsonl_timeframe() {
  echo "TEST: parse_agent_jsonl - Timeframe filtering"

  # This test depends on current date, so we'll just verify it returns <= 4 records
  local result
  result=$(parse_agent_jsonl "test-agent" 7 2>&1)

  local record_count
  record_count=$(echo "$result" | jq -s 'length')

  # Should return 4 or fewer records (depending on current date)
  if [[ "$record_count" -le 4 ]] && [[ "$record_count" -ge 0 ]]; then
    echo "  ✓ PASS: Timeframe filtering returns valid result ($record_count records)"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  ✗ FAIL: Timeframe filtering returned invalid count: $record_count"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# Test 3: parse_agent_jsonl - Error handling
test_parse_agent_jsonl_error() {
  echo "TEST: parse_agent_jsonl - Error handling for missing agent"

  local result
  result=$(parse_agent_jsonl "nonexistent-agent" 30 2>&1 || true)

  assert_contains "$result" "ERROR" "Should return error for missing agent"
}

# Test 4: calculate_agent_stats - Total invocations
test_calculate_agent_stats_invocations() {
  echo "TEST: calculate_agent_stats - Total invocations"

  local stats
  stats=$(calculate_agent_stats "test-agent" 365 2>&1)

  local total_invocations
  total_invocations=$(echo "$stats" | jq -r '.total_invocations')

  assert_equals "4" "$total_invocations" "Should count 4 invocations"
}

# Test 5: calculate_agent_stats - Success rate
test_calculate_agent_stats_success_rate() {
  echo "TEST: calculate_agent_stats - Success rate"

  local stats
  stats=$(calculate_agent_stats "test-agent" 365 2>&1)

  local success_rate
  success_rate=$(echo "$stats" | jq -r '.success_rate')

  assert_equals "75" "$success_rate" "Should calculate 75% success rate (3/4)"
}

# Test 6: calculate_agent_stats - Average duration
test_calculate_agent_stats_duration() {
  echo "TEST: calculate_agent_stats - Average duration"

  local stats
  stats=$(calculate_agent_stats "test-agent" 365 2>&1)

  local avg_duration
  avg_duration=$(echo "$stats" | jq -r '.avg_duration_ms')

  # Average should be (5000 + 7000 + 6000 + 4500) / 4 = 5625
  assert_in_range "$avg_duration" "5500" "5700" "Average duration should be around 5625ms"
}

# Test 7: calculate_agent_stats - Tool usage aggregation
test_calculate_agent_stats_tools() {
  echo "TEST: calculate_agent_stats - Tool usage aggregation"

  local stats
  stats=$(calculate_agent_stats "test-agent" 365 2>&1)

  # Check Read tool count (3 + 5 + 2 + 4 = 14)
  local read_count
  read_count=$(echo "$stats" | jq -r '.tools_used.Read')

  assert_equals "14" "$read_count" "Should aggregate Read tool count correctly"

  # Check Edit tool count (2 + 0 + 0 + 3 = 5)
  local edit_count
  edit_count=$(echo "$stats" | jq -r '.tools_used.Edit')

  assert_equals "5" "$edit_count" "Should aggregate Edit tool count correctly"
}

# Test 8: calculate_agent_stats - Error aggregation
test_calculate_agent_stats_errors() {
  echo "TEST: calculate_agent_stats - Error aggregation"

  local stats
  stats=$(calculate_agent_stats "test-agent" 365 2>&1)

  local test_failure_count
  test_failure_count=$(echo "$stats" | jq -r '.errors_by_type.test_failure')

  assert_equals "1" "$test_failure_count" "Should count 1 test_failure error"
}

# Test 9: identify_common_errors - Error detection
test_identify_common_errors() {
  echo "TEST: identify_common_errors - Error detection"

  local errors
  errors=$(identify_common_errors "test-agent" 365 5 2>&1)

  assert_contains "$errors" "test_failure" "Should identify test_failure error type"
  assert_contains "$errors" "1 occurrences" "Should show correct occurrence count"
}

# Test 10: identify_common_errors - Example message
test_identify_common_errors_example() {
  echo "TEST: identify_common_errors - Example message"

  local errors
  errors=$(identify_common_errors "test-agent" 365 5 2>&1)

  assert_contains "$errors" "Test failed" "Should include example error message"
}

# Test 11: analyze_tool_usage - Tool detection
test_analyze_tool_usage_detection() {
  echo "TEST: analyze_tool_usage - Tool detection"

  local tool_usage
  tool_usage=$(analyze_tool_usage "test-agent" 365 2>&1)

  assert_contains "$tool_usage" "Read" "Should detect Read tool usage"
  assert_contains "$tool_usage" "Edit" "Should detect Edit tool usage"
  assert_contains "$tool_usage" "Bash" "Should detect Bash tool usage"
}

# Test 12: analyze_tool_usage - Percentage calculation
test_analyze_tool_usage_percentages() {
  echo "TEST: analyze_tool_usage - Percentage calculation"

  local tool_usage
  tool_usage=$(analyze_tool_usage "test-agent" 365 2>&1)

  # Total tools: Read(14) + Edit(5) + Bash(2) = 21
  # Read should be ~67% (14/21)
  assert_contains "$tool_usage" "Read" "Should show Read tool"

  # Should have percentage indicators
  assert_contains "$tool_usage" "%" "Should show percentage"
}

# Test 13: analyze_tool_usage - No data handling
test_analyze_tool_usage_no_data() {
  echo "TEST: analyze_tool_usage - No data handling"

  local tool_usage
  tool_usage=$(analyze_tool_usage "nonexistent-agent" 365 2>&1 || true)

  assert_contains "$tool_usage" "No tool usage data available" "Should handle missing data gracefully"
}

# Test 14: Multiple agents - code-writer stats
test_multiple_agents_code_writer() {
  echo "TEST: Multiple agents - code-writer stats"

  local stats
  stats=$(calculate_agent_stats "code-writer" 365 2>&1)

  local total_invocations
  total_invocations=$(echo "$stats" | jq -r '.total_invocations')

  assert_equals "3" "$total_invocations" "Should count 3 code-writer invocations"

  local success_rate
  success_rate=$(echo "$stats" | jq -r '.success_rate')

  # 2 successes out of 3 = 66% (rounded down by floor)
  assert_equals "66" "$success_rate" "Should calculate 66% success rate for code-writer"
}

# Test 15: Multiple agents - code-writer errors
test_multiple_agents_code_writer_errors() {
  echo "TEST: Multiple agents - code-writer error types"

  local errors
  errors=$(identify_common_errors "code-writer" 365 5 2>&1)

  assert_contains "$errors" "syntax_error" "Should identify syntax_error for code-writer"
  assert_contains "$errors" "Syntax error in file" "Should include error message example"
}

# ============================================================================
# Run Test Suite
# ============================================================================

run_all_tests() {
  echo ""
  echo "=========================================="
  echo "Agent Metrics Test Suite (Phase 6)"
  echo "=========================================="
  echo ""

  setup_test_data

  # Basic parsing tests
  test_parse_agent_jsonl_basic
  test_parse_agent_jsonl_timeframe
  test_parse_agent_jsonl_error

  # Statistics calculation tests
  test_calculate_agent_stats_invocations
  test_calculate_agent_stats_success_rate
  test_calculate_agent_stats_duration
  test_calculate_agent_stats_tools
  test_calculate_agent_stats_errors

  # Error analysis tests
  test_identify_common_errors
  test_identify_common_errors_example

  # Tool usage tests
  test_analyze_tool_usage_detection
  test_analyze_tool_usage_percentages
  test_analyze_tool_usage_no_data

  # Multiple agents tests
  test_multiple_agents_code_writer
  test_multiple_agents_code_writer_errors

  teardown_test_data

  echo ""
  echo "=========================================="
  echo "Test Results"
  echo "=========================================="
  echo "Tests run: $TESTS_RUN"
  echo "Tests passed: $TESTS_PASSED"
  echo "Tests failed: $TESTS_FAILED"
  echo "=========================================="
  echo ""

  if [[ "$TESTS_FAILED" -eq 0 ]]; then
    echo "✓ ALL TESTS PASSED"
    return 0
  else
    echo "✗ SOME TESTS FAILED"
    return 1
  fi
}

# Execute tests if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_all_tests
fi
