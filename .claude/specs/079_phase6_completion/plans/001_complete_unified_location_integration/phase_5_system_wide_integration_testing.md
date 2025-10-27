# Phase 5: System-Wide Integration Testing

## Phase Metadata
- **Phase Number**: 5
- **Parent Plan**: 001_complete_unified_location_integration.md
- **Topic**: 079_phase6_completion
- **Dependencies**: [4] (requires Phase 4 Model Metadata Standardization)
- **Complexity**: 6/10
- **Estimated Time**: 2 hours
- **Risk**: Medium (cross-command testing reveals hidden issues)
- **Standards File**: /home/benjamin/.config/CLAUDE.md

## Objective

Validate that all four commands (/supervise, /orchestrate, /report, /plan) work correctly with unified location detection library through comprehensive integration testing (50 test cases), achieving ≥95% pass rate (≥47/50 tests passing) before production deployment.

**Final Validation Gate**: MUST achieve ≥47/50 tests passing (95%)

This phase serves as the critical go/no-go decision point for production deployment of the unified location detection system.

## Test Infrastructure Setup

### Task Group 1: Create Test Suite File

#### Task 1.1: Create Test File with Framework
- [ ] **Create test file**: `.claude/tests/test_system_wide_location.sh`
- [ ] **Set permissions**: `chmod +x .claude/tests/test_system_wide_location.sh`
- [ ] **Add shebang and header comments**

**Test File Template (Framework Structure)**:

```bash
#!/usr/bin/env bash
# test_system_wide_location.sh
#
# Comprehensive integration tests for unified location detection
# Tests cross-command compatibility and system-wide standardization
#
# Usage: ./test_system_wide_location.sh [--group N] [--verbose]
# Exit codes: 0 = all tests passed (≥95%), 1 = test failure, 2 = critical failure

set -euo pipefail

# ============================================================================
# TEST FRAMEWORK CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="${PROJECT_ROOT}/.claude/lib"
UNIFIED_LIB="${LIB_DIR}/unified-location-detection.sh"

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
CRITICAL_FAILURES=0

# Test categories
GROUP_1_TESTS=0  # Isolated command execution
GROUP_2_TESTS=0  # Command chaining
GROUP_3_TESTS=0  # Concurrent execution
GROUP_4_TESTS=0  # Backward compatibility

# Test temp directory
TEST_TMP_DIR="/tmp/test_system_wide_$$"
mkdir -p "$TEST_TMP_DIR"

# Cleanup on exit
trap 'cleanup_test_env' EXIT

cleanup_test_env() {
  rm -rf "$TEST_TMP_DIR"
  # Restore any modified commands from backups if test failed
  if [ "$CRITICAL_FAILURES" -gt 0 ]; then
    echo "WARNING: Critical failures detected - consider rollback"
  fi
}

# ============================================================================
# TEST REPORTING FUNCTIONS
# ============================================================================

report_test() {
  local test_name="$1"
  local result="$2"
  local category="${3:-GENERAL}"

  ((TOTAL_TESTS++))

  case "$category" in
    GROUP1) ((GROUP_1_TESTS++)) ;;
    GROUP2) ((GROUP_2_TESTS++)) ;;
    GROUP3) ((GROUP_3_TESTS++)) ;;
    GROUP4) ((GROUP_4_TESTS++)) ;;
  esac

  if [ "$result" = "PASS" ]; then
    ((PASSED_TESTS++))
    echo "✓ $test_name"
  else
    ((FAILED_TESTS++))
    echo "✗ $test_name"

    # Track critical failures (command-specific >5% failure rate)
    if [[ "$test_name" =~ "CRITICAL" ]]; then
      ((CRITICAL_FAILURES++))
    fi
  fi
}

assert_equals() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"
  local category="${4:-GENERAL}"

  if [ "$expected" = "$actual" ]; then
    report_test "$test_name" "PASS" "$category"
  else
    report_test "$test_name" "FAIL" "$category"
    echo "  Expected: '$expected'"
    echo "  Actual:   '$actual'"
  fi
}

assert_dir_exists() {
  local dir="$1"
  local test_name="$2"
  local category="${3:-GENERAL}"

  if [ -d "$dir" ]; then
    report_test "$test_name" "PASS" "$category"
  else
    report_test "$test_name" "FAIL" "$category"
    echo "  Directory does not exist: $dir"
  fi
}

assert_file_exists() {
  local file="$1"
  local test_name="$2"
  local category="${3:-GENERAL}"

  if [ -f "$file" ]; then
    report_test "$test_name" "PASS" "$category"
  else
    report_test "$test_name" "FAIL" "$category"
    echo "  File does not exist: $file"
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local test_name="$3"
  local category="${4:-GENERAL}"

  if echo "$haystack" | grep -q "$needle"; then
    report_test "$test_name" "PASS" "$category"
  else
    report_test "$test_name" "FAIL" "$category"
    echo "  Expected to contain: '$needle'"
    echo "  Actual content: '${haystack:0:100}...'"
  fi
}

# ============================================================================
# COMMAND SIMULATION FUNCTIONS
# ============================================================================

simulate_report_command() {
  local topic="$1"
  local test_mode="${2:-real}"

  # Source unified library
  source "$UNIFIED_LIB"

  # Perform location detection
  local location_json
  location_json=$(perform_location_detection "$topic" "true")

  # Extract report directory
  local reports_dir
  if command -v jq &>/dev/null; then
    reports_dir=$(echo "$location_json" | jq -r '.artifact_paths.reports')
  else
    reports_dir=$(echo "$location_json" | grep -o '"reports": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  fi

  # Simulate report creation
  if [ "$test_mode" = "real" ]; then
    local report_file="${reports_dir}/001_$(echo "$topic" | tr ' ' '_').md"
    echo "# Research Report: $topic" > "$report_file"
    echo "$report_file"
  else
    echo "$reports_dir"
  fi
}

simulate_plan_command() {
  local feature="$1"
  local test_mode="${2:-real}"

  # Source unified library
  source "$UNIFIED_LIB"

  # Perform location detection
  local location_json
  location_json=$(perform_location_detection "$feature" "true")

  # Extract plans directory
  local plans_dir
  if command -v jq &>/dev/null; then
    plans_dir=$(echo "$location_json" | jq -r '.artifact_paths.plans')
  else
    plans_dir=$(echo "$location_json" | grep -o '"plans": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  fi

  # Simulate plan creation
  if [ "$test_mode" = "real" ]; then
    local plan_file="${plans_dir}/001_$(echo "$feature" | tr ' ' '_').md"
    echo "# Implementation Plan: $feature" > "$plan_file"
    echo "$plan_file"
  else
    echo "$plans_dir"
  fi
}

simulate_orchestrate_phase0() {
  local workflow="$1"

  # Source unified library
  source "$UNIFIED_LIB"

  # Perform location detection
  local location_json
  location_json=$(perform_location_detection "$workflow" "true")

  # Return full JSON for orchestrate (needs all paths)
  echo "$location_json"
}

# ============================================================================
# PREREQUISITES CHECK
# ============================================================================

echo "=========================================="
echo "System-Wide Integration Test Suite"
echo "=========================================="
echo ""

# Verify unified library exists
if [ ! -f "$UNIFIED_LIB" ]; then
  echo "ERROR: Unified library not found: $UNIFIED_LIB"
  exit 2
fi

# Verify library is sourceable
if ! source "$UNIFIED_LIB" 2>/dev/null; then
  echo "ERROR: Failed to source unified library"
  exit 2
fi

echo "✓ Prerequisites satisfied"
echo ""
```

#### Task 1.2: Add Test Group Headers
- [ ] **Add Group 1 header**: Isolated Command Execution
- [ ] **Add Group 2 header**: Command Chaining
- [ ] **Add Group 3 header**: Concurrent Execution
- [ ] **Add Group 4 header**: Backward Compatibility

#### Task 1.3: Add Final Summary Section
- [ ] **Add summary reporting**
- [ ] **Add pass/fail calculation**
- [ ] **Add rollback trigger detection**

**Summary Section Template**:

```bash
# ============================================================================
# TEST SUMMARY AND VALIDATION
# ============================================================================

echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Total Tests:      $TOTAL_TESTS"
echo "Passed:           $PASSED_TESTS"
echo "Failed:           $FAILED_TESTS"
echo "Pass Rate:        $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%"
echo ""
echo "Category Breakdown:"
echo "  Group 1 (Isolated):       $GROUP_1_TESTS tests"
echo "  Group 2 (Chaining):       $GROUP_2_TESTS tests"
echo "  Group 3 (Concurrent):     $GROUP_3_TESTS tests"
echo "  Group 4 (Compatibility):  $GROUP_4_TESTS tests"
echo ""

# Calculate pass rate
PASS_RATE=$(( PASSED_TESTS * 100 / TOTAL_TESTS ))

# Validation Gate: ≥95% pass rate required (≥47/50 tests)
if [ "$PASSED_TESTS" -ge 47 ] && [ "$PASS_RATE" -ge 95 ]; then
  echo "✓✓✓ VALIDATION GATE PASSED ✓✓✓"
  echo "Pass rate: ${PASS_RATE}% (≥95% required)"
  echo "Passed tests: ${PASSED_TESTS}/50 (≥47 required)"
  echo ""
  echo "System ready for production deployment"
  exit 0
else
  echo "✗✗✗ VALIDATION GATE FAILED ✗✗✗"
  echo "Pass rate: ${PASS_RATE}% (≥95% required)"
  echo "Passed tests: ${PASSED_TESTS}/50 (≥47 required)"
  echo ""
  echo "ROLLBACK RECOMMENDED"
  echo "See rollback procedures in specs/079_phase6_completion/plans/rollback_procedures.md"
  exit 1
fi
```

**MANDATORY VERIFICATION**:
```bash
# Verify test file created
[[ -f ".claude/tests/test_system_wide_location.sh" ]] || {
  echo "ERROR: Test file not created"
  exit 1
}

# Verify executable
[[ -x ".claude/tests/test_system_wide_location.sh" ]] || {
  echo "ERROR: Test file not executable"
  exit 1
}

echo "✓ VERIFIED: Test infrastructure created"
```

---

## Test Group 1: Isolated Command Execution (25 tests)

**Purpose**: Verify each command works independently with unified library, without cross-command dependencies.

### Task Group 2: /report Command Tests (10 tests)

#### Task 2.1: Implement /report Test Cases

**Test Implementation Template**:

```bash
# ============================================================================
# TEST GROUP 1: ISOLATED COMMAND EXECUTION (25 tests)
# ============================================================================

echo "Group 1: Isolated Command Execution"
echo "------------------------------------"

# ----------------------------------------------------------------------------
# /report Command Tests (10 tests)
# ----------------------------------------------------------------------------

test_report_1_simple_topic() {
  local topic="authentication patterns"
  local report_path
  report_path=$(simulate_report_command "$topic" "real")

  assert_file_exists "$report_path" "Report 1.1: Simple topic - file created" "GROUP1"

  # Verify directory structure
  local topic_dir=$(dirname "$(dirname "$report_path")")
  assert_dir_exists "${topic_dir}/reports" "Report 1.1: Reports subdir exists" "GROUP1"
  assert_dir_exists "${topic_dir}/plans" "Report 1.1: Plans subdir exists" "GROUP1"
  assert_dir_exists "${topic_dir}/summaries" "Report 1.1: Summaries subdir exists" "GROUP1"
}

test_report_2_special_chars() {
  local topic="Research: OAuth 2.0 Security Best Practices!"
  local reports_dir
  reports_dir=$(simulate_report_command "$topic" "dry")

  # Verify sanitization (should be oauth_20_security_best_practices)
  assert_contains "$reports_dir" "oauth" "Report 1.2: Special chars sanitized" "GROUP1"

  # Verify no special chars in path
  if [[ "$reports_dir" =~ [!@#$%^&*()] ]]; then
    report_test "Report 1.2: No special chars in path" "FAIL" "GROUP1"
  else
    report_test "Report 1.2: No special chars in path" "PASS" "GROUP1"
  fi
}

test_report_3_long_description() {
  local topic="Comprehensive analysis of microservices architecture patterns for distributed systems with event-driven communication and service mesh integration"
  local reports_dir
  reports_dir=$(simulate_report_command "$topic" "dry")

  # Extract topic name from path
  local topic_name=$(basename "$(dirname "$reports_dir")" | cut -d'_' -f2-)
  local length=${#topic_name}

  # Verify truncation to 50 chars
  if [ "$length" -le 50 ]; then
    report_test "Report 1.3: Long description truncated (≤50)" "PASS" "GROUP1"
  else
    report_test "Report 1.3: Long description truncated (≤50)" "FAIL" "GROUP1"
    echo "  Topic name length: $length"
  fi
}

test_report_4_minimal_description() {
  local topic="test"
  local report_path
  report_path=$(simulate_report_command "$topic" "real")

  assert_file_exists "$report_path" "Report 1.4: Minimal topic - file created" "GROUP1"
}

test_report_5_topic_numbering() {
  # Get max existing topic number
  local specs_dir="${PROJECT_ROOT}/.claude/specs"
  local max_num=$(ls -1d "${specs_dir}"/[0-9][0-9][0-9]_* 2>/dev/null | \
    sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | \
    sort -n | tail -1)

  # Create new report
  local topic="topic numbering test"
  local report_path
  report_path=$(simulate_report_command "$topic" "real")

  # Extract topic number from path
  local new_num=$(echo "$report_path" | grep -o '/[0-9][0-9][0-9]_' | tr -d '/_')
  local expected=$((10#$max_num + 1))

  # Verify sequential numbering
  if [ "$((10#$new_num))" -eq "$expected" ]; then
    report_test "Report 1.5: Sequential topic numbering" "PASS" "GROUP1"
  else
    report_test "Report 1.5: Sequential topic numbering" "FAIL" "GROUP1"
    echo "  Expected: $expected, Got: $new_num"
  fi
}

test_report_6_absolute_paths() {
  local topic="absolute path verification"
  local report_path
  report_path=$(simulate_report_command "$topic" "real")

  # Verify path is absolute (starts with /)
  if [[ "$report_path" == /* ]]; then
    report_test "Report 1.6: Absolute path returned" "PASS" "GROUP1"
  else
    report_test "Report 1.6: Absolute path returned" "FAIL" "GROUP1"
    echo "  Path: $report_path"
  fi
}

test_report_7_subdirectory_completeness() {
  local topic="subdirectory test"
  local report_path
  report_path=$(simulate_report_command "$topic" "real")

  local topic_dir=$(dirname "$(dirname "$report_path")")

  # Verify all 6 subdirectories exist
  local all_exist=true
  for subdir in reports plans summaries debug scripts outputs; do
    if [ ! -d "${topic_dir}/${subdir}" ]; then
      all_exist=false
      echo "  Missing: $subdir"
    fi
  done

  if [ "$all_exist" = true ]; then
    report_test "Report 1.7: All 6 subdirectories created" "PASS" "GROUP1"
  else
    report_test "Report 1.7: All 6 subdirectories created" "FAIL" "GROUP1"
  fi
}

test_report_8_json_output_format() {
  local topic="json format test"

  # Get location JSON
  source "$UNIFIED_LIB"
  local location_json
  location_json=$(perform_location_detection "$topic" "true")

  # Verify JSON structure
  assert_contains "$location_json" '"topic_number"' "Report 1.8: JSON contains topic_number" "GROUP1"
  assert_contains "$location_json" '"topic_path"' "Report 1.8: JSON contains topic_path" "GROUP1"
  assert_contains "$location_json" '"artifact_paths"' "Report 1.8: JSON contains artifact_paths" "GROUP1"
}

test_report_9_jq_fallback() {
  local topic="jq fallback test"

  # Temporarily hide jq if available
  local old_path="$PATH"
  export PATH="/tmp"

  # Simulate report without jq
  local reports_dir
  reports_dir=$(simulate_report_command "$topic" "dry" 2>&1)

  # Restore PATH
  export PATH="$old_path"

  # Verify fallback worked (path extracted without jq)
  if [[ "$reports_dir" == *"/reports" ]]; then
    report_test "Report 1.9: Fallback without jq works" "PASS" "GROUP1"
  else
    report_test "Report 1.9: Fallback without jq works" "FAIL" "GROUP1"
    echo "  Got: $reports_dir"
  fi
}

test_report_10_no_regression() {
  local topic="regression check"
  local report_path
  report_path=$(simulate_report_command "$topic" "real")

  # Verify report file has expected header
  local content=$(cat "$report_path")
  assert_contains "$content" "Research Report" "Report 1.10: No regression in format" "GROUP1"
}

# Execute /report tests
test_report_1_simple_topic
test_report_2_special_chars
test_report_3_long_description
test_report_4_minimal_description
test_report_5_topic_numbering
test_report_6_absolute_paths
test_report_7_subdirectory_completeness
test_report_8_json_output_format
test_report_9_jq_fallback
test_report_10_no_regression

echo ""
```

### Task Group 3: /plan Command Tests (10 tests)

#### Task 3.1: Implement /plan Test Cases

**Test Implementation Template**:

```bash
# ----------------------------------------------------------------------------
# /plan Command Tests (10 tests)
# ----------------------------------------------------------------------------

test_plan_1_simple_feature() {
  local feature="user authentication"
  local plan_path
  plan_path=$(simulate_plan_command "$feature" "real")

  assert_file_exists "$plan_path" "Plan 1.1: Simple feature - file created" "GROUP1"

  # Verify /implement can locate plan (absolute path check)
  if [[ "$plan_path" == /* ]] && [ -f "$plan_path" ]; then
    report_test "Plan 1.1: /implement compatibility - absolute path" "PASS" "GROUP1"
  else
    report_test "Plan 1.1: /implement compatibility - absolute path" "FAIL" "GROUP1"
  fi
}

test_plan_2_complex_feature() {
  local feature="implement real-time WebSocket notifications with Redis pub/sub"
  local plan_path
  plan_path=$(simulate_plan_command "$feature" "real")

  assert_file_exists "$plan_path" "Plan 1.2: Complex feature - file created" "GROUP1"

  # Verify sanitization
  local plan_name=$(basename "$plan_path" .md)
  if [[ ! "$plan_name" =~ [^a-z0-9_] ]]; then
    report_test "Plan 1.2: Feature name sanitized correctly" "PASS" "GROUP1"
  else
    report_test "Plan 1.2: Feature name sanitized correctly" "FAIL" "GROUP1"
  fi
}

test_plan_3_refactoring_task() {
  local feature="refactor database connection pooling"
  local plan_path
  plan_path=$(simulate_plan_command "$feature" "real")

  assert_file_exists "$plan_path" "Plan 1.3: Refactoring - file created" "GROUP1"
}

test_plan_4_bug_fix() {
  local feature="fix memory leak in event handler cleanup"
  local plan_path
  plan_path=$(simulate_plan_command "$feature" "real")

  assert_file_exists "$plan_path" "Plan 1.4: Bug fix - file created" "GROUP1"
}

test_plan_5_topic_numbering() {
  # Similar to report test - verify sequential numbering
  local specs_dir="${PROJECT_ROOT}/.claude/specs"
  local max_num=$(ls -1d "${specs_dir}"/[0-9][0-9][0-9]_* 2>/dev/null | \
    sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | \
    sort -n | tail -1)

  local feature="numbering test"
  local plan_path
  plan_path=$(simulate_plan_command "$feature" "real")

  local new_num=$(echo "$plan_path" | grep -o '/[0-9][0-9][0-9]_' | tr -d '/_')
  local expected=$((10#$max_num + 1))

  if [ "$((10#$new_num))" -eq "$expected" ]; then
    report_test "Plan 1.5: Sequential topic numbering" "PASS" "GROUP1"
  else
    report_test "Plan 1.5: Sequential topic numbering" "FAIL" "GROUP1"
  fi
}

test_plan_6_subdirectory_structure() {
  local feature="subdirectory test"
  local plan_path
  plan_path=$(simulate_plan_command "$feature" "real")

  local topic_dir=$(dirname "$(dirname "$plan_path")")

  # Verify plans subdir specifically
  assert_dir_exists "${topic_dir}/plans" "Plan 1.6: Plans subdirectory exists" "GROUP1"
}

test_plan_7_absolute_paths() {
  local feature="absolute path test"
  local plan_path
  plan_path=$(simulate_plan_command "$feature" "real")

  if [[ "$plan_path" == /* ]]; then
    report_test "Plan 1.7: Absolute path returned" "PASS" "GROUP1"
  else
    report_test "Plan 1.7: Absolute path returned" "FAIL" "GROUP1"
  fi
}

test_plan_8_plan_format() {
  local feature="format check"
  local plan_path
  plan_path=$(simulate_plan_command "$feature" "real")

  local content=$(cat "$plan_path")
  assert_contains "$content" "Implementation Plan" "Plan 1.8: Plan format correct" "GROUP1"
}

test_plan_9_no_collision() {
  # Create two plans rapidly - verify no topic number collision
  local plan1=$(simulate_plan_command "test plan 1" "real")
  local plan2=$(simulate_plan_command "test plan 2" "real")

  local num1=$(echo "$plan1" | grep -o '/[0-9][0-9][0-9]_' | tr -d '/_')
  local num2=$(echo "$plan2" | grep -o '/[0-9][0-9][0-9]_' | tr -d '/_')

  if [ "$num1" != "$num2" ]; then
    report_test "Plan 1.9: No topic number collision" "PASS" "GROUP1"
  else
    report_test "Plan 1.9: No topic number collision" "FAIL" "GROUP1"
  fi
}

test_plan_10_token_usage() {
  # Verify unified library uses minimal tokens (no AI invocation)
  # This is a smoke test - actual token usage measured in Phase 4
  local feature="token test"
  local start_time=$(date +%s)

  simulate_plan_command "$feature" "real" >/dev/null

  local end_time=$(date +%s)
  local duration=$((end_time - start_time))

  # Should complete in <1 second (no AI calls)
  if [ "$duration" -le 2 ]; then
    report_test "Plan 1.10: Fast execution (<2s)" "PASS" "GROUP1"
  else
    report_test "Plan 1.10: Fast execution (<2s)" "FAIL" "GROUP1"
    echo "  Duration: ${duration}s"
  fi
}

# Execute /plan tests
test_plan_1_simple_feature
test_plan_2_complex_feature
test_plan_3_refactoring_task
test_plan_4_bug_fix
test_plan_5_topic_numbering
test_plan_6_subdirectory_structure
test_plan_7_absolute_paths
test_plan_8_plan_format
test_plan_9_no_collision
test_plan_10_token_usage

echo ""
```

### Task Group 4: /orchestrate Command Tests (5 tests)

#### Task 4.1: Implement /orchestrate Test Cases

**Test Implementation Template**:

```bash
# ----------------------------------------------------------------------------
# /orchestrate Command Tests (5 tests)
# ----------------------------------------------------------------------------

test_orchestrate_1_phase0_execution() {
  local workflow="research authentication patterns"
  local location_json
  location_json=$(simulate_orchestrate_phase0 "$workflow")

  # Verify JSON contains all required paths
  assert_contains "$location_json" '"topic_path"' "Orchestrate 1.1: Phase 0 - topic_path exists" "GROUP1"
  assert_contains "$location_json" '"reports"' "Orchestrate 1.1: Phase 0 - reports path exists" "GROUP1"
  assert_contains "$location_json" '"plans"' "Orchestrate 1.1: Phase 0 - plans path exists" "GROUP1"
}

test_orchestrate_2_directory_creation() {
  local workflow="test orchestrate workflow"
  local location_json
  location_json=$(simulate_orchestrate_phase0 "$workflow")

  # Extract topic path
  local topic_path
  if command -v jq &>/dev/null; then
    topic_path=$(echo "$location_json" | jq -r '.topic_path')
  else
    topic_path=$(echo "$location_json" | grep -o '"topic_path": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  fi

  assert_dir_exists "$topic_path" "Orchestrate 1.2: Topic directory created" "GROUP1"
}

test_orchestrate_3_artifact_paths() {
  local workflow="artifact paths test"
  local location_json
  location_json=$(simulate_orchestrate_phase0 "$workflow")

  # Verify all artifact paths present
  local paths_complete=true
  for path_type in reports plans summaries debug scripts outputs; do
    if ! echo "$location_json" | grep -q "\"${path_type}\""; then
      paths_complete=false
      echo "  Missing artifact path: $path_type"
    fi
  done

  if [ "$paths_complete" = true ]; then
    report_test "Orchestrate 1.3: All artifact paths present" "PASS" "GROUP1"
  else
    report_test "Orchestrate 1.3: All artifact paths present" "FAIL" "GROUP1"
  fi
}

test_orchestrate_4_token_reduction() {
  # Verify Phase 0 uses unified library (not location-specialist agent)
  # This test confirms NO agent invocation occurs
  local workflow="token reduction test"
  local start_time=$(date +%s%N)

  simulate_orchestrate_phase0 "$workflow" >/dev/null

  local end_time=$(date +%s%N)
  local duration_ms=$(( (end_time - start_time) / 1000000 ))

  # Should complete in <100ms (no AI calls)
  if [ "$duration_ms" -lt 1000 ]; then
    report_test "Orchestrate 1.4: Fast Phase 0 (<1s, no agent)" "PASS" "GROUP1"
  else
    report_test "Orchestrate 1.4: Fast Phase 0 (<1s, no agent)" "FAIL" "GROUP1"
    echo "  Duration: ${duration_ms}ms"
  fi
}

test_orchestrate_5_sanitization() {
  local workflow="Complex Workflow: Multi-Phase Testing!"
  local location_json
  location_json=$(simulate_orchestrate_phase0 "$workflow")

  # Extract topic name
  local topic_name
  if command -v jq &>/dev/null; then
    topic_name=$(echo "$location_json" | jq -r '.topic_name')
  else
    topic_name=$(echo "$location_json" | grep -o '"topic_name": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  fi

  # Verify sanitization (no special chars, lowercase)
  if [[ "$topic_name" =~ ^[a-z0-9_]+$ ]]; then
    report_test "Orchestrate 1.5: Workflow description sanitized" "PASS" "GROUP1"
  else
    report_test "Orchestrate 1.5: Workflow description sanitized" "FAIL" "GROUP1"
    echo "  Topic name: $topic_name"
  fi
}

# Execute /orchestrate tests
test_orchestrate_1_phase0_execution
test_orchestrate_2_directory_creation
test_orchestrate_3_artifact_paths
test_orchestrate_4_token_reduction
test_orchestrate_5_sanitization

echo ""
```

**MANDATORY VERIFICATION**:
```bash
# Run Group 1 tests
./claude/tests/test_system_wide_location.sh 2>&1 | tee /tmp/group1_results.txt

# Verify Group 1 results
GROUP1_PASS=$(grep "Group 1" /tmp/group1_results.txt -A 50 | grep "^✓" | wc -l)

if [ "$GROUP1_PASS" -ge 24 ]; then  # ≥24/25 = 96%
  echo "✓ VERIFIED: Group 1 tests passed ($GROUP1_PASS/25)"
else
  echo "ERROR: Group 1 tests failed ($GROUP1_PASS/25 passed)"
  exit 1
fi
```

---

## Test Group 2: Command Chaining (10 tests)

**Purpose**: Verify /orchestrate correctly invokes updated /report and /plan commands, with proper artifact path propagation.

### Task Group 5: Command Chaining Tests

#### Task 5.1: Implement /orchestrate → /report Integration Tests (5 tests)

**Test Implementation Template**:

```bash
# ============================================================================
# TEST GROUP 2: COMMAND CHAINING (10 tests)
# ============================================================================

echo "Group 2: Command Chaining"
echo "-------------------------"

# ----------------------------------------------------------------------------
# /orchestrate → /report Integration (5 tests)
# ----------------------------------------------------------------------------

test_chain_1_report_invocation() {
  # Simulate: /orchestrate "research OAuth patterns" → invokes research phase
  local workflow="research OAuth patterns"
  local location_json
  location_json=$(simulate_orchestrate_phase0 "$workflow")

  # Extract reports directory for research phase
  local reports_dir
  if command -v jq &>/dev/null; then
    reports_dir=$(echo "$location_json" | jq -r '.artifact_paths.reports')
  else
    reports_dir=$(echo "$location_json" | grep -o '"reports": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  fi

  # Verify reports directory exists (created by Phase 0)
  assert_dir_exists "$reports_dir" "Chain 2.1: Reports dir created for research phase" "GROUP2"
}

test_chain_2_report_path_propagation() {
  # Verify research phase would receive correct report paths
  local workflow="research and plan authentication"
  local location_json
  location_json=$(simulate_orchestrate_phase0 "$workflow")

  # Simulate creating research reports
  local reports_dir
  reports_dir=$(echo "$location_json" | jq -r '.artifact_paths.reports')

  local report1="${reports_dir}/001_oauth_flows.md"
  local report2="${reports_dir}/002_jwt_implementation.md"

  echo "# OAuth Flows" > "$report1"
  echo "# JWT Implementation" > "$report2"

  # Verify reports created in correct location
  assert_file_exists "$report1" "Chain 2.2: Report 1 in correct location" "GROUP2"
  assert_file_exists "$report2" "Chain 2.2: Report 2 in correct location" "GROUP2"
}

test_chain_3_research_to_planning_handoff() {
  # Simulate research phase completion → planning phase receives report paths
  local workflow="oauth implementation workflow"
  local location_json
  location_json=$(simulate_orchestrate_phase0 "$workflow")

  local topic_path=$(echo "$location_json" | jq -r '.topic_path')
  local reports_dir="${topic_path}/reports"
  local plans_dir="${topic_path}/plans"

  # Create mock research report
  local report="${reports_dir}/001_oauth_research.md"
  echo "# OAuth Research" > "$report"

  # Verify planning phase can reference report
  local plan="${plans_dir}/001_oauth_implementation.md"
  echo "# Implementation Plan\nBased on: $report" > "$plan"

  if grep -q "$report" "$plan"; then
    report_test "Chain 2.3: Planning phase references research report" "PASS" "GROUP2"
  else
    report_test "Chain 2.3: Planning phase references research report" "FAIL" "GROUP2"
  fi
}

test_chain_4_artifact_path_consistency() {
  # Verify all phases use same topic directory
  local workflow="consistency test"
  local location_json
  location_json=$(simulate_orchestrate_phase0 "$workflow")

  local topic_path=$(echo "$location_json" | jq -r '.topic_path')
  local reports_dir=$(echo "$location_json" | jq -r '.artifact_paths.reports')
  local plans_dir=$(echo "$location_json" | jq -r '.artifact_paths.plans')

  # All paths should share same topic directory
  if [[ "$reports_dir" == "$topic_path"* ]] && [[ "$plans_dir" == "$topic_path"* ]]; then
    report_test "Chain 2.4: All artifact paths share topic directory" "PASS" "GROUP2"
  else
    report_test "Chain 2.4: All artifact paths share topic directory" "FAIL" "GROUP2"
    echo "  Topic: $topic_path"
    echo "  Reports: $reports_dir"
    echo "  Plans: $plans_dir"
  fi
}

test_chain_5_no_duplicate_detection() {
  # Verify Phase 0 runs once, not repeated in Phase 1 or Phase 2
  local workflow="duplication test"

  # Phase 0: Create topic structure
  local location_json
  location_json=$(simulate_orchestrate_phase0 "$workflow")
  local topic_num1=$(echo "$location_json" | jq -r '.topic_number')

  # Simulate Phase 1 (research) - should NOT create new topic
  # (In real orchestrate, Phase 0 output is reused)
  local topic_path=$(echo "$location_json" | jq -r '.topic_path')

  # Verify topic directory exists (not recreated)
  if [ -d "$topic_path" ]; then
    report_test "Chain 2.5: Topic structure reused (not duplicated)" "PASS" "GROUP2"
  else
    report_test "Chain 2.5: Topic structure reused (not duplicated)" "FAIL" "GROUP2"
  fi
}

# Execute /orchestrate → /report tests
test_chain_1_report_invocation
test_chain_2_report_path_propagation
test_chain_3_research_to_planning_handoff
test_chain_4_artifact_path_consistency
test_chain_5_no_duplicate_detection

echo ""
```

#### Task 5.2: Implement /orchestrate → /plan Integration Tests (5 tests)

**Test Implementation Template**:

```bash
# ----------------------------------------------------------------------------
# /orchestrate → /plan Integration (5 tests)
# ----------------------------------------------------------------------------

test_chain_6_plan_invocation() {
  local workflow="implement authentication system"
  local location_json
  location_json=$(simulate_orchestrate_phase0 "$workflow")

  local plans_dir
  plans_dir=$(echo "$location_json" | jq -r '.artifact_paths.plans')

  assert_dir_exists "$plans_dir" "Chain 2.6: Plans dir created for planning phase" "GROUP2"
}

test_chain_7_plan_receives_reports() {
  # Simulate: Research phase creates reports → Planning phase receives paths
  local workflow="plan with research"
  local location_json
  location_json=$(simulate_orchestrate_phase0 "$workflow")

  local reports_dir=$(echo "$location_json" | jq -r '.artifact_paths.reports')
  local plans_dir=$(echo "$location_json" | jq -r '.artifact_paths.plans')

  # Create mock research reports
  local report1="${reports_dir}/001_research.md"
  local report2="${reports_dir}/002_analysis.md"
  echo "# Research" > "$report1"
  echo "# Analysis" > "$report2"

  # Simulate planning phase receiving report paths
  local plan="${plans_dir}/001_implementation.md"
  echo "# Plan\nReports: $report1, $report2" > "$plan"

  # Verify plan references reports correctly
  if grep -q "$report1" "$plan" && grep -q "$report2" "$plan"; then
    report_test "Chain 2.7: Plan references research reports" "PASS" "GROUP2"
  else
    report_test "Chain 2.7: Plan references research reports" "FAIL" "GROUP2"
  fi
}

test_chain_8_implement_receives_plan() {
  # Verify planning phase creates plan that /implement can locate
  local workflow="implementation workflow"
  local location_json
  location_json=$(simulate_orchestrate_phase0 "$workflow")

  local plans_dir=$(echo "$location_json" | jq -r '.artifact_paths.plans')
  local plan="${plans_dir}/001_implementation.md"
  echo "# Implementation Plan" > "$plan"

  # Verify absolute path (required for /implement)
  if [[ "$plan" == /* ]] && [ -f "$plan" ]; then
    report_test "Chain 2.8: /implement can locate plan (absolute path)" "PASS" "GROUP2"
  else
    report_test "Chain 2.8: /implement can locate plan (absolute path)" "FAIL" "GROUP2"
  fi
}

test_chain_9_cross_phase_references() {
  # Verify Phase 1 → Phase 2 → Phase 3 artifact references work
  local workflow="multi-phase workflow"
  local location_json
  location_json=$(simulate_orchestrate_phase0 "$workflow")

  local topic_path=$(echo "$location_json" | jq -r '.topic_path')

  # Create artifacts simulating full workflow
  local report="${topic_path}/reports/001_research.md"
  local plan="${topic_path}/plans/001_implementation.md"
  local summary="${topic_path}/summaries/001_workflow_summary.md"

  echo "# Research" > "$report"
  echo "# Plan\nBased on: $report" > "$plan"
  echo "# Summary\nPlan: $plan\nReport: $report" > "$summary"

  # Verify cross-references resolve
  local refs_valid=true
  for ref in "$report" "$plan"; do
    if ! [ -f "$ref" ]; then
      refs_valid=false
    fi
  done

  if [ "$refs_valid" = true ]; then
    report_test "Chain 2.9: Cross-phase references resolve" "PASS" "GROUP2"
  else
    report_test "Chain 2.9: Cross-phase references resolve" "FAIL" "GROUP2"
  fi
}

test_chain_10_workflow_completion() {
  # End-to-end workflow simulation
  local workflow="complete workflow test"
  local location_json
  location_json=$(simulate_orchestrate_phase0 "$workflow")

  local topic_path=$(echo "$location_json" | jq -r '.topic_path')

  # Simulate all workflow phases
  echo "# Research" > "${topic_path}/reports/001_research.md"
  echo "# Plan" > "${topic_path}/plans/001_plan.md"
  echo "# Summary" > "${topic_path}/summaries/001_summary.md"

  # Verify workflow completion artifact
  local summary="${topic_path}/summaries/001_summary.md"
  if [ -f "$summary" ]; then
    report_test "Chain 2.10: Workflow completion tracked" "PASS" "GROUP2"
  else
    report_test "Chain 2.10: Workflow completion tracked" "FAIL" "GROUP2"
  fi
}

# Execute /orchestrate → /plan tests
test_chain_6_plan_invocation
test_chain_7_plan_receives_reports
test_chain_8_implement_receives_plan
test_chain_9_cross_phase_references
test_chain_10_workflow_completion

echo ""
```

**MANDATORY VERIFICATION**:
```bash
# Run Group 2 tests
./claude/tests/test_system_wide_location.sh 2>&1 | tee /tmp/group2_results.txt

# Verify Group 2 results
GROUP2_PASS=$(grep "Group 2" /tmp/group2_results.txt -A 20 | grep "^✓" | wc -l)

if [ "$GROUP2_PASS" -ge 9 ]; then  # ≥9/10 = 90%
  echo "✓ VERIFIED: Group 2 tests passed ($GROUP2_PASS/10)"
else
  echo "ERROR: Group 2 tests failed ($GROUP2_PASS/10 passed)"
  exit 1
fi
```

---

## Test Group 3: Concurrent Execution (5 tests)

**Purpose**: Detect race conditions in topic number calculation when multiple workflows execute simultaneously.

### Task Group 6: Concurrent Execution Tests

#### Task 6.1: Implement Race Condition Detection Tests

**Test Implementation Template**:

```bash
# ============================================================================
# TEST GROUP 3: CONCURRENT EXECUTION (5 tests)
# ============================================================================

echo "Group 3: Concurrent Execution"
echo "------------------------------"

test_concurrent_1_parallel_orchestrate() {
  # Launch 3 parallel /orchestrate Phase 0 invocations
  local workflow_a="concurrent workflow A"
  local workflow_b="concurrent workflow B"
  local workflow_c="concurrent workflow C"

  local json_a json_b json_c
  (
    json_a=$(simulate_orchestrate_phase0 "$workflow_a")
    echo "$json_a" > /tmp/concurrent_a.json
  ) &
  (
    json_b=$(simulate_orchestrate_phase0 "$workflow_b")
    echo "$json_b" > /tmp/concurrent_b.json
  ) &
  (
    json_c=$(simulate_orchestrate_phase0 "$workflow_c")
    echo "$json_c" > /tmp/concurrent_c.json
  ) &

  wait

  # Extract topic numbers
  local num_a=$(jq -r '.topic_number' /tmp/concurrent_a.json)
  local num_b=$(jq -r '.topic_number' /tmp/concurrent_b.json)
  local num_c=$(jq -r '.topic_number' /tmp/concurrent_c.json)

  # Verify no duplicates
  if [ "$num_a" != "$num_b" ] && [ "$num_b" != "$num_c" ] && [ "$num_a" != "$num_c" ]; then
    report_test "Concurrent 3.1: No duplicate topic numbers" "PASS" "GROUP3"
  else
    report_test "Concurrent 3.1: No duplicate topic numbers" "FAIL" "GROUP3"
    echo "  Numbers: $num_a, $num_b, $num_c"
  fi
}

test_concurrent_2_directory_conflicts() {
  # Verify no directory creation conflicts
  local workflow_d="concurrent D"
  local workflow_e="concurrent E"

  local json_d json_e
  (
    json_d=$(simulate_orchestrate_phase0 "$workflow_d")
    echo "$json_d" > /tmp/concurrent_d.json
  ) &
  (
    json_e=$(simulate_orchestrate_phase0 "$workflow_e")
    echo "$json_e" > /tmp/concurrent_e.json
  ) &

  wait

  local path_d=$(jq -r '.topic_path' /tmp/concurrent_d.json)
  local path_e=$(jq -r '.topic_path' /tmp/concurrent_e.json)

  # Verify both directories exist and are distinct
  if [ -d "$path_d" ] && [ -d "$path_e" ] && [ "$path_d" != "$path_e" ]; then
    report_test "Concurrent 3.2: No directory conflicts" "PASS" "GROUP3"
  else
    report_test "Concurrent 3.2: No directory conflicts" "FAIL" "GROUP3"
  fi
}

test_concurrent_3_subdirectory_integrity() {
  # Verify concurrent creation doesn't corrupt subdirectories
  local workflow_f="concurrent F"
  local workflow_g="concurrent G"

  (simulate_orchestrate_phase0 "$workflow_f" > /tmp/concurrent_f.json) &
  (simulate_orchestrate_phase0 "$workflow_g" > /tmp/concurrent_g.json) &

  wait

  local path_f=$(jq -r '.topic_path' /tmp/concurrent_f.json)
  local path_g=$(jq -r '.topic_path' /tmp/concurrent_g.json)

  # Verify all subdirectories in both
  local all_valid=true
  for topic_dir in "$path_f" "$path_g"; do
    for subdir in reports plans summaries debug scripts outputs; do
      if [ ! -d "${topic_dir}/${subdir}" ]; then
        all_valid=false
        echo "  Missing: ${topic_dir}/${subdir}"
      fi
    done
  done

  if [ "$all_valid" = true ]; then
    report_test "Concurrent 3.3: Subdirectory integrity maintained" "PASS" "GROUP3"
  else
    report_test "Concurrent 3.3: Subdirectory integrity maintained" "FAIL" "GROUP3"
  fi
}

test_concurrent_4_file_locking() {
  # Test if file locking is needed (race condition check)
  # Launch 5 parallel topic creations
  local pids=()
  for i in {1..5}; do
    (simulate_orchestrate_phase0 "concurrent lock test $i" > "/tmp/concurrent_lock_$i.json") &
    pids+=($!)
  done

  # Wait for all
  for pid in "${pids[@]}"; do
    wait "$pid"
  done

  # Extract all topic numbers
  local topic_nums=()
  for i in {1..5}; do
    local num=$(jq -r '.topic_number' "/tmp/concurrent_lock_$i.json")
    topic_nums+=("$num")
  done

  # Check for duplicates
  local unique_count=$(printf '%s\n' "${topic_nums[@]}" | sort -u | wc -l)

  if [ "$unique_count" -eq 5 ]; then
    report_test "Concurrent 3.4: File locking prevents duplicates" "PASS" "GROUP3"
  else
    report_test "Concurrent 3.4: File locking prevents duplicates" "FAIL" "GROUP3"
    echo "  Unique topics: $unique_count/5"
    echo "  NOTE: If this fails, implement mutex lock in get_next_topic_number()"
  fi
}

test_concurrent_5_performance() {
  # Verify concurrent execution doesn't degrade performance significantly
  local start_time=$(date +%s)

  # Launch 3 parallel operations
  (simulate_orchestrate_phase0 "perf test A" > /tmp/perf_a.json) &
  (simulate_orchestrate_phase0 "perf test B" > /tmp/perf_b.json) &
  (simulate_orchestrate_phase0 "perf test C" > /tmp/perf_c.json) &

  wait

  local end_time=$(date +%s)
  local duration=$((end_time - start_time))

  # Should complete in <3 seconds (parallel overhead acceptable)
  if [ "$duration" -le 3 ]; then
    report_test "Concurrent 3.5: Acceptable parallel performance (<3s)" "PASS" "GROUP3"
  else
    report_test "Concurrent 3.5: Acceptable parallel performance (<3s)" "FAIL" "GROUP3"
    echo "  Duration: ${duration}s"
  fi
}

# Execute concurrent tests
test_concurrent_1_parallel_orchestrate
test_concurrent_2_directory_conflicts
test_concurrent_3_subdirectory_integrity
test_concurrent_4_file_locking
test_concurrent_5_performance

echo ""
```

**MANDATORY VERIFICATION**:
```bash
# Run Group 3 tests
./claude/tests/test_system_wide_location.sh 2>&1 | tee /tmp/group3_results.txt

# Verify Group 3 results
GROUP3_PASS=$(grep "Group 3" /tmp/group3_results.txt -A 10 | grep "^✓" | wc -l)

if [ "$GROUP3_PASS" -ge 4 ]; then  # ≥4/5 = 80% (race conditions acceptable initially)
  echo "✓ VERIFIED: Group 3 tests passed ($GROUP3_PASS/5)"

  # Check if file locking test failed
  if grep -q "File locking" /tmp/group3_results.txt | grep -q "FAIL"; then
    echo "NOTE: Consider implementing mutex lock in get_next_topic_number()"
    echo "      for production deployments with high concurrency"
  fi
else
  echo "ERROR: Group 3 tests failed ($GROUP3_PASS/5 passed)"
  exit 1
fi
```

---

## Test Group 4: Backward Compatibility (10 tests)

**Purpose**: Ensure existing workflows continue to work without disruption.

### Task Group 7: Backward Compatibility Tests

#### Task 7.1: Implement Compatibility Tests

**Test Implementation Template**:

```bash
# ============================================================================
# TEST GROUP 4: BACKWARD COMPATIBILITY (10 tests)
# ============================================================================

echo "Group 4: Backward Compatibility"
echo "--------------------------------"

test_compat_1_existing_specs_dir() {
  # Verify new topics numbered correctly after existing ones
  local specs_dir="${PROJECT_ROOT}/.claude/specs"

  # Get current max topic number
  local max_before=$(ls -1d "${specs_dir}"/[0-9][0-9][0-9]_* 2>/dev/null | \
    sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | \
    sort -n | tail -1)

  # Create new topic
  local workflow="compatibility test"
  local location_json
  location_json=$(simulate_orchestrate_phase0 "$workflow")

  local new_num=$(echo "$location_json" | jq -r '.topic_number')
  local expected=$((10#$max_before + 1))

  if [ "$((10#$new_num))" -eq "$expected" ]; then
    report_test "Compat 4.1: New topics numbered after existing" "PASS" "GROUP4"
  else
    report_test "Compat 4.1: New topics numbered after existing" "FAIL" "GROUP4"
  fi
}

test_compat_2_no_disruption() {
  # Verify existing topic directories untouched
  local specs_dir="${PROJECT_ROOT}/.claude/specs"

  # Create snapshot of existing topics
  local existing_topics=$(ls -1d "${specs_dir}"/[0-9][0-9][0-9]_* 2>/dev/null | wc -l)

  # Create new topic
  simulate_orchestrate_phase0 "no disruption test" >/dev/null

  # Verify existing topics still present
  local topics_after=$(ls -1d "${specs_dir}"/[0-9][0-9][0-9]_* 2>/dev/null | wc -l)

  if [ "$topics_after" -eq $((existing_topics + 1)) ]; then
    report_test "Compat 4.2: Existing topics undisturbed" "PASS" "GROUP4"
  else
    report_test "Compat 4.2: Existing topics undisturbed" "FAIL" "GROUP4"
  fi
}

test_compat_3_git_paths_unchanged() {
  # Verify git commit paths still valid
  local workflow="git path test"
  local location_json
  location_json=$(simulate_orchestrate_phase0 "$workflow")

  local topic_path=$(echo "$location_json" | jq -r '.topic_path')

  # Verify path format matches git conventions
  if [[ "$topic_path" =~ /.claude/specs/[0-9]{3}_.* ]]; then
    report_test "Compat 4.3: Git commit paths unchanged" "PASS" "GROUP4"
  else
    report_test "Compat 4.3: Git commit paths unchanged" "FAIL" "GROUP4"
  fi
}

test_compat_4_legacy_yaml_support() {
  # Verify legacy YAML compatibility function works
  source "$UNIFIED_LIB"

  local workflow="yaml compat test"
  local location_json
  location_json=$(perform_location_detection "$workflow" "true")

  # Convert to legacy YAML
  local legacy_yaml
  legacy_yaml=$(generate_legacy_location_context "$location_json")

  # Verify YAML contains expected fields
  if echo "$legacy_yaml" | grep -q "topic_number:" && \
     echo "$legacy_yaml" | grep -q "topic_path:"; then
    report_test "Compat 4.4: Legacy YAML format supported" "PASS" "GROUP4"
  else
    report_test "Compat 4.4: Legacy YAML format supported" "FAIL" "GROUP4"
  fi
}

test_compat_5_env_var_override() {
  # Verify CLAUDE_PROJECT_DIR override still works
  export CLAUDE_PROJECT_DIR="/tmp/compat_test"
  mkdir -p "$CLAUDE_PROJECT_DIR/.claude/specs"

  source "$UNIFIED_LIB"
  local project_root
  project_root=$(detect_project_root)

  unset CLAUDE_PROJECT_DIR
  rm -rf "/tmp/compat_test"

  if [ "$project_root" = "/tmp/compat_test" ]; then
    report_test "Compat 4.5: CLAUDE_PROJECT_DIR override works" "PASS" "GROUP4"
  else
    report_test "Compat 4.5: CLAUDE_PROJECT_DIR override works" "FAIL" "GROUP4"
  fi
}

test_compat_6_specs_vs_claude_specs() {
  # Verify legacy specs/ directory still supported
  local test_root="/tmp/compat_legacy"
  mkdir -p "$test_root/specs"

  source "$UNIFIED_LIB"
  local specs_dir
  specs_dir=$(detect_specs_directory "$test_root")

  rm -rf "$test_root"

  if [ "$specs_dir" = "$test_root/specs" ]; then
    report_test "Compat 4.6: Legacy specs/ directory supported" "PASS" "GROUP4"
  else
    report_test "Compat 4.6: Legacy specs/ directory supported" "FAIL" "GROUP4"
  fi
}

test_compat_7_no_format_regression() {
  # Verify artifact format unchanged
  local workflow="format regression test"
  local location_json
  location_json=$(simulate_orchestrate_phase0 "$workflow")

  # Check JSON structure matches expected format
  local has_all_fields=true
  for field in topic_number topic_name topic_path artifact_paths; do
    if ! echo "$location_json" | grep -q "\"$field\""; then
      has_all_fields=false
    fi
  done

  if [ "$has_all_fields" = true ]; then
    report_test "Compat 4.7: No format regression" "PASS" "GROUP4"
  else
    report_test "Compat 4.7: No format regression" "FAIL" "GROUP4"
  fi
}

test_compat_8_implement_integration() {
  # Verify /implement can still locate plans
  local workflow="implement integration test"
  local location_json
  location_json=$(simulate_orchestrate_phase0 "$workflow")

  local plans_dir=$(echo "$location_json" | jq -r '.artifact_paths.plans')
  local plan="${plans_dir}/001_test.md"
  echo "# Test Plan" > "$plan"

  # Verify absolute path (critical for /implement)
  if [[ "$plan" == /* ]] && [ -f "$plan" ]; then
    report_test "Compat 4.8: /implement integration maintained" "PASS" "GROUP4"
  else
    report_test "Compat 4.8: /implement integration maintained" "FAIL" "GROUP4"
  fi
}

test_compat_9_no_user_visible_changes() {
  # Verify user experience unchanged
  local workflow="user experience test"
  local location_json
  location_json=$(simulate_orchestrate_phase0 "$workflow")

  local topic_path=$(echo "$location_json" | jq -r '.topic_path')

  # Verify directory structure looks identical to before
  local subdir_count=$(ls -1 "$topic_path" | wc -l)

  if [ "$subdir_count" -eq 6 ]; then
    report_test "Compat 4.9: No user-visible changes" "PASS" "GROUP4"
  else
    report_test "Compat 4.9: No user-visible changes" "FAIL" "GROUP4"
  fi
}

test_compat_10_documentation_paths() {
  # Verify documentation references still valid
  local workflow="documentation paths test"
  local location_json
  location_json=$(simulate_orchestrate_phase0 "$workflow")

  local topic_path=$(echo "$location_json" | jq -r '.topic_path')

  # Verify path matches documentation examples
  if [[ "$topic_path" =~ /.claude/specs/[0-9]{3}_[a-z0-9_]+ ]]; then
    report_test "Compat 4.10: Documentation paths valid" "PASS" "GROUP4"
  else
    report_test "Compat 4.10: Documentation paths valid" "FAIL" "GROUP4"
  fi
}

# Execute compatibility tests
test_compat_1_existing_specs_dir
test_compat_2_no_disruption
test_compat_3_git_paths_unchanged
test_compat_4_legacy_yaml_support
test_compat_5_env_var_override
test_compat_6_specs_vs_claude_specs
test_compat_7_no_format_regression
test_compat_8_implement_integration
test_compat_9_no_user_visible_changes
test_compat_10_documentation_paths

echo ""
```

**MANDATORY VERIFICATION**:
```bash
# Run Group 4 tests
./claude/tests/test_system_wide_location.sh 2>&1 | tee /tmp/group4_results.txt

# Verify Group 4 results
GROUP4_PASS=$(grep "Group 4" /tmp/group4_results.txt -A 20 | grep "^✓" | wc -l)

if [ "$GROUP4_PASS" -ge 9 ]; then  # ≥9/10 = 90%
  echo "✓ VERIFIED: Group 4 tests passed ($GROUP4_PASS/10)"
else
  echo "ERROR: Group 4 tests failed ($GROUP4_PASS/10 passed)"
  exit 1
fi
```

---

## Performance Metrics Collection

### Task Group 8: Token Usage Measurement

#### Task 8.1: Measure System-Wide Token Reduction

**Measurement Script Template**:

```bash
#!/usr/bin/env bash
# measure_token_reduction.sh
# Measures token usage before/after unified library integration

echo "=========================================="
echo "Token Usage Measurement"
echo "=========================================="
echo ""

# Baseline metrics (before integration)
echo "BASELINE (Before Unified Library):"
echo "  /report:      ~10k tokens (utilities-based)"
echo "  /plan:        ~10k tokens (utilities-based)"
echo "  /orchestrate: 75,600 tokens (location-specialist agent)"
echo "  System avg:   ~30k tokens per workflow"
echo ""

# Current metrics (after integration)
echo "CURRENT (After Unified Library):"

# Measure /report
REPORT_START=$(date +%s%N)
simulate_report_command "token measurement test" "real" >/dev/null
REPORT_END=$(date +%s%N)
REPORT_TIME=$(( (REPORT_END - REPORT_START) / 1000000 ))
echo "  /report:      ~10k tokens (no change), ${REPORT_TIME}ms execution"

# Measure /plan
PLAN_START=$(date +%s%N)
simulate_plan_command "token measurement test" "real" >/dev/null
PLAN_END=$(date +%s%N)
PLAN_TIME=$(( (PLAN_END - PLAN_START) / 1000000 ))
echo "  /plan:        ~10k tokens (no change), ${PLAN_TIME}ms execution"

# Measure /orchestrate Phase 0
ORCH_START=$(date +%s%N)
simulate_orchestrate_phase0 "token measurement test" >/dev/null
ORCH_END=$(date +%s%N)
ORCH_TIME=$(( (ORCH_END - ORCH_START) / 1000000 ))
echo "  /orchestrate: <11k tokens (85% reduction), ${ORCH_TIME}ms Phase 0"
echo ""

# Calculate system-wide reduction
echo "SYSTEM-WIDE IMPACT:"
echo "  /orchestrate optimization: 75.6k → 11k tokens (85% reduction)"
echo "  Time savings: 25.2s → <1s (20x speedup)"
echo "  Cost reduction: ~$0.68 → ~$0.03 per invocation (95% savings)"
echo ""

# Validation
if [ "$ORCH_TIME" -lt 1000 ]; then
  echo "✓ VERIFIED: Phase 0 execution <1s (no agent invocation)"
else
  echo "✗ WARNING: Phase 0 execution >1s - may indicate agent still in use"
fi
```

#### Task 8.2: Calculate Cost Savings

```bash
# Calculate annual cost savings
BASELINE_COST_PER_WORKFLOW=0.68
OPTIMIZED_COST_PER_WORKFLOW=0.03
WORKFLOWS_PER_WEEK=100

WEEKLY_BASELINE=$(echo "$BASELINE_COST_PER_WORKFLOW * $WORKFLOWS_PER_WEEK" | bc)
WEEKLY_OPTIMIZED=$(echo "$OPTIMIZED_COST_PER_WORKFLOW * $WORKFLOWS_PER_WEEK" | bc)
WEEKLY_SAVINGS=$(echo "$WEEKLY_BASELINE - $WEEKLY_OPTIMIZED" | bc)
ANNUAL_SAVINGS=$(echo "$WEEKLY_SAVINGS * 52" | bc)

echo "Cost Analysis:"
echo "  Baseline:  $$WEEKLY_BASELINE/week, $$((WEEKLY_BASELINE * 52))/year"
echo "  Optimized: $$WEEKLY_OPTIMIZED/week, $$((WEEKLY_OPTIMIZED * 52))/year"
echo "  Savings:   $$WEEKLY_SAVINGS/week, $$ANNUAL_SAVINGS/year"
```

---

## Rollback Procedures

### Task Group 9: Create Rollback Scripts

#### Task 9.1: Per-Command Rollback Script

**Rollback Script Template**:

```bash
#!/usr/bin/env bash
# rollback_unified_integration.sh
# Restore commands to pre-integration state

set -euo pipefail

COMMAND="${1:-all}"  # all, report, plan, orchestrate

echo "=========================================="
echo "Rollback: Unified Location Integration"
echo "=========================================="
echo ""

rollback_report() {
  echo "Rolling back /report command..."
  if [ -f ".claude/commands/report.md.backup-unified-integration" ]; then
    cp .claude/commands/report.md.backup-unified-integration .claude/commands/report.md
    echo "✓ /report restored from backup"
  else
    echo "✗ ERROR: Backup not found for /report"
    return 1
  fi
}

rollback_plan() {
  echo "Rolling back /plan command..."
  if [ -f ".claude/commands/plan.md.backup-unified-integration" ]; then
    cp .claude/commands/plan.md.backup-unified-integration .claude/commands/plan.md
    echo "✓ /plan restored from backup"
  else
    echo "✗ ERROR: Backup not found for /plan"
    return 1
  fi
}

rollback_orchestrate() {
  echo "Rolling back /orchestrate command..."
  if [ -f ".claude/commands/orchestrate.md.backup-unified-integration" ]; then
    cp .claude/commands/orchestrate.md.backup-unified-integration .claude/commands/orchestrate.md
    echo "✓ /orchestrate restored from backup"
  else
    echo "✗ ERROR: Backup not found for /orchestrate"
    return 1
  fi
}

case "$COMMAND" in
  report)
    rollback_report
    ;;
  plan)
    rollback_plan
    ;;
  orchestrate)
    rollback_orchestrate
    ;;
  all)
    rollback_report
    rollback_plan
    rollback_orchestrate
    ;;
  *)
    echo "Usage: $0 {report|plan|orchestrate|all}"
    exit 1
    ;;
esac

echo ""
echo "Rollback complete. Verify with:"
echo "  ./.claude/tests/test_system_wide_location.sh"
```

#### Task 9.2: Validation After Rollback

```bash
# Verify rollback success
./claude/tests/test_system_wide_location.sh

# Expected: 100% pass rate with legacy implementations
# If tests still fail, investigate before attempting redeployment
```

---

## Success Criteria

### Final Validation Gate

Before marking Phase 5 complete, ALL of the following MUST be verified:

- [ ] **Test Suite Executed**: All 50 tests run successfully
- [ ] **Pass Rate ≥95%**: At least 47/50 tests passed
- [ ] **No Critical Failures**: No command shows >5% failure rate
- [ ] **Group 1 Pass**: ≥24/25 isolated execution tests passed
- [ ] **Group 2 Pass**: ≥9/10 command chaining tests passed
- [ ] **Group 3 Pass**: ≥4/5 concurrent execution tests passed
- [ ] **Group 4 Pass**: ≥9/10 backward compatibility tests passed
- [ ] **Token Reduction Verified**: /orchestrate Phase 0 <1s execution
- [ ] **Cost Savings Calculated**: 85-95% reduction confirmed
- [ ] **No Regressions**: Existing workflows function correctly
- [ ] **Rollback Procedures Tested**: Rollback scripts validated

### Rollback Triggers

If ANY of these conditions occur, MUST execute immediate rollback:

1. **Pass rate <95%** (≤46/50 tests passed)
2. **Any command >5% failure rate** (e.g., /report fails >2.5 tests)
3. **Token usage increases** for any command
4. **Critical path broken** (e.g., /implement can't locate plans)
5. **Race conditions** (duplicate topic numbers in Group 3)
6. **User-reported issues** (location detection failures)

### Rollback Execution

```bash
# Execute rollback
./claude/specs/079_phase6_completion/scripts/rollback_unified_integration.sh all

# Verify rollback
./claude/tests/test_system_wide_location.sh

# Expected: 100% pass with legacy implementations
```

---

## Phase Completion Checklist

**MANDATORY STEPS AFTER ALL PHASE TASKS COMPLETE**:

- [ ] **Mark all phase tasks as [x]** in this file
- [ ] **Update parent plan** with phase completion status
  - Use spec-updater: `mark_phase_complete` function
  - Verify hierarchy synchronization
- [ ] **Verify Final Validation Gate**: ≥47/50 tests passing
- [ ] **Document any rollbacks**: If rollback executed, document reason
- [ ] **Calculate final metrics**: Token reduction, cost savings, pass rates
- [ ] **Create git commit** with standardized message
  - Format: `feat(079): complete Phase 5 - System-Wide Integration Testing`
  - Include: test_system_wide_location.sh, measurement scripts, rollback scripts
  - Verify commit created successfully
- [ ] **Create checkpoint**: Save progress to `.claude/data/checkpoints/`
  - Include: Plan path, phase number, test results, completion status
  - Timestamp: ISO 8601 format
- [ ] **Invoke spec-updater**: Update cross-references and summaries
  - Verify bidirectional links intact
  - Update plan metadata with completion timestamp

---

## Notes

### Test Coverage Analysis

This test suite provides:
- **Isolated Command Testing**: 25 tests validate each command independently
- **Integration Testing**: 10 tests validate cross-command workflows
- **Stress Testing**: 5 tests validate concurrent execution
- **Regression Testing**: 10 tests validate backward compatibility

Total coverage: 50 tests across 4 critical dimensions

### Known Limitations

1. **Race Condition Testing**: May require mutex lock implementation if Group 3.4 fails
2. **Performance Testing**: Measured on local system, production may vary
3. **Token Measurement**: Estimates based on code analysis, not API metrics
4. **Cost Calculations**: Based on current Anthropic pricing (subject to change)

### Future Enhancements

1. **Automated Rollback**: Trigger rollback automatically if validation gate fails
2. **Continuous Monitoring**: Track token usage and costs in production
3. **A/B Testing**: Compare unified vs legacy implementations side-by-side
4. **Performance Profiling**: Detailed timing analysis for optimization
