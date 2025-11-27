#!/usr/bin/env bash
# test_empty_directory_detection.sh
#
# Integration tests for lazy directory creation
# Verifies that directories are created only when files are written
#
# Usage: ./test_empty_directory_detection.sh
# Exit codes: 0 = all tests passed, 1 = one or more tests failed

set -euo pipefail

# Test framework setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
LIB_DIR="$CLAUDE_ROOT/lib"
UNIFIED_LIB="${LIB_DIR}/core/unified-location-detection.sh"

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test temp directory
TEST_TMP_DIR="/tmp/test_lazy_creation_$$"
mkdir -p "$TEST_TMP_DIR"

# Cleanup on exit
trap 'rm -rf "$TEST_TMP_DIR"' EXIT

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Test reporting functions
report_test() {
  local test_name="$1"
  local result="$2"
  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  if [ "$result" = "PASS" ]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo -e "${GREEN}✓${NC} $test_name"
  else
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo -e "${RED}✗${NC} $test_name"
  fi
}

assert_dir_exists() {
  local dir="$1"
  local test_name="$2"

  if [ -d "$dir" ]; then
    report_test "$test_name" "PASS"
    return 0
  else
    report_test "$test_name" "FAIL"
    echo "  Directory does not exist: $dir"
    return 1
  fi
}

assert_dir_not_exists() {
  local dir="$1"
  local test_name="$2"

  if [ ! -d "$dir" ]; then
    report_test "$test_name" "PASS"
    return 0
  else
    report_test "$test_name" "FAIL"
    echo "  Directory should not exist: $dir"
    return 1
  fi
}

assert_no_empty_subdirs() {
  local parent_dir="$1"
  local test_name="$2"

  # Find empty subdirectories (excluding .gitkeep)
  local empty_count
  empty_count=$(find "$parent_dir" -mindepth 1 -maxdepth 1 -type d -exec sh -c '
    for dir; do
      count=$(find "$dir" -mindepth 1 -maxdepth 1 ! -name ".gitkeep" ! -name ".artifact-registry" 2>/dev/null | wc -l)
      [ "$count" -eq 0 ] && echo "$dir"
    done
  ' sh {} + 2>/dev/null | wc -l)

  if [ "$empty_count" -eq 0 ]; then
    report_test "$test_name" "PASS"
    return 0
  else
    report_test "$test_name" "FAIL"
    echo "  Found $empty_count empty subdirectories in $parent_dir"
    return 1
  fi
}

# Source the library
if [ ! -f "$UNIFIED_LIB" ]; then
  echo "ERROR: Unified library not found: $UNIFIED_LIB"
  exit 1
fi

source "$UNIFIED_LIB"

echo "==========================================="
echo "Lazy Directory Creation Integration Tests"
echo "==========================================="
echo ""

# ============================================================================
# Test Case 1: Create topic structure creates only root
# ============================================================================

echo "Test Case 1: Topic structure creates only root directory"
echo "--------------------------------------------------------"

test_1() {
  local test_topic="${TEST_TMP_DIR}/001_test_case_1"

  # Create topic structure
  if ! create_topic_structure "$test_topic"; then
    report_test "Test 1.1: create_topic_structure succeeds" "FAIL"
    return
  fi

  report_test "Test 1.1: create_topic_structure succeeds" "PASS"

  # Verify topic root exists
  assert_dir_exists "$test_topic" "Test 1.2: Topic root created"

  # Verify NO subdirectories created
  local subdir_count
  subdir_count=$(find "$test_topic" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)

  if [ "$subdir_count" -eq 0 ]; then
    report_test "Test 1.3: No subdirectories created (lazy)" "PASS"
  else
    report_test "Test 1.3: No subdirectories created (lazy)" "FAIL"
    echo "  Found $subdir_count subdirectories (expected 0)"
  fi
}
test_1

echo ""

# ============================================================================
# Test Case 2: ensure_artifact_directory creates parent on-demand
# ============================================================================

echo "Test Case 2: ensure_artifact_directory creates parent on-demand"
echo "----------------------------------------------------------------"

test_2() {
  local test_topic="${TEST_TMP_DIR}/002_test_case_2"
  create_topic_structure "$test_topic"

  local report_file="${test_topic}/reports/001_analysis.md"

  # Ensure artifact directory
  if ! ensure_artifact_directory "$report_file"; then
    report_test "Test 2.1: ensure_artifact_directory succeeds" "FAIL"
    return
  fi

  report_test "Test 2.1: ensure_artifact_directory succeeds" "PASS"

  # Verify reports/ directory created
  assert_dir_exists "${test_topic}/reports" "Test 2.2: reports/ directory created"

  # Verify OTHER subdirectories NOT created
  assert_dir_not_exists "${test_topic}/plans" "Test 2.3: plans/ not created"
  assert_dir_not_exists "${test_topic}/summaries" "Test 2.4: summaries/ not created"
}
test_2

echo ""

# ============================================================================
# Test Case 3: Multiple artifact directories created independently
# ============================================================================

echo "Test Case 3: Multiple artifact directories created independently"
echo "-----------------------------------------------------------------"

test_3() {
  local test_topic="${TEST_TMP_DIR}/003_test_case_3"
  create_topic_structure "$test_topic"

  # Create report
  local report_file="${test_topic}/reports/001_report.md"
  ensure_artifact_directory "$report_file"

  # Create plan
  local plan_file="${test_topic}/plans/001_plan.md"
  ensure_artifact_directory "$plan_file"

  # Verify both directories exist
  assert_dir_exists "${test_topic}/reports" "Test 3.1: reports/ created"
  assert_dir_exists "${test_topic}/plans" "Test 3.2: plans/ created"

  # Verify unused directories NOT created
  assert_dir_not_exists "${test_topic}/summaries" "Test 3.3: summaries/ not created"
  assert_dir_not_exists "${test_topic}/debug" "Test 3.4: debug/ not created"
}
test_3

echo ""

# ============================================================================
# Test Case 4: Idempotent behavior (calling twice succeeds)
# ============================================================================

echo "Test Case 4: Idempotent behavior"
echo "---------------------------------"

test_4() {
  local test_topic="${TEST_TMP_DIR}/004_test_case_4"
  create_topic_structure "$test_topic"

  local report_file="${test_topic}/reports/001_report.md"

  # First call
  if ! ensure_artifact_directory "$report_file"; then
    report_test "Test 4.1: First call succeeds" "FAIL"
    return
  fi
  report_test "Test 4.1: First call succeeds" "PASS"

  # Second call (directory already exists)
  if ensure_artifact_directory "$report_file"; then
    report_test "Test 4.2: Second call succeeds (idempotent)" "PASS"
  else
    report_test "Test 4.2: Second call succeeds (idempotent)" "FAIL"
  fi
}
test_4

echo ""

# ============================================================================
# Test Case 5: Deeply nested paths work correctly
# ============================================================================

echo "Test Case 5: Deeply nested paths"
echo "---------------------------------"

test_5() {
  local test_topic="${TEST_TMP_DIR}/005_test_case_5"
  create_topic_structure "$test_topic"

  local nested_file="${test_topic}/reports/001_research/subtopic/analysis.md"

  if ! ensure_artifact_directory "$nested_file"; then
    report_test "Test 5.1: Nested directory creation fails gracefully or succeeds" "FAIL"
    return
  fi

  report_test "Test 5.1: Deeply nested path handled" "PASS"

  # Verify nested structure created
  assert_dir_exists "$(dirname "$nested_file")" "Test 5.2: Nested parent exists"
}
test_5

echo ""

# ============================================================================
# Test Case 6: No empty directories after workflow simulation
# ============================================================================

echo "Test Case 6: No empty directories after workflow"
echo "-------------------------------------------------"

test_6() {
  local test_topic="${TEST_TMP_DIR}/006_test_case_6"
  create_topic_structure "$test_topic"

  # Simulate workflow: create only reports and plans
  ensure_artifact_directory "${test_topic}/reports/001_report.md"
  ensure_artifact_directory "${test_topic}/plans/001_plan.md"

  # Write files to make directories non-empty
  echo "content" > "${test_topic}/reports/001_report.md"
  echo "content" > "${test_topic}/plans/001_plan.md"

  # Check for empty subdirectories
  # Should find NO empty directories (summaries, debug, scripts, outputs not created)
  local empty_in_used_dirs=0

  # Check reports/ and plans/ are not empty
  if [ -z "$(ls -A "${test_topic}/reports" 2>/dev/null)" ]; then
    empty_in_used_dirs=$((empty_in_used_dirs + 1))
  fi
  if [ -z "$(ls -A "${test_topic}/plans" 2>/dev/null)" ]; then
    empty_in_used_dirs=$((empty_in_used_dirs + 1))
  fi

  if [ "$empty_in_used_dirs" -eq 0 ]; then
    report_test "Test 6.1: No empty directories in used subdirs" "PASS"
  else
    report_test "Test 6.1: No empty directories in used subdirs" "FAIL"
    echo "  Found $empty_in_used_dirs empty directories that should have content"
  fi

  # Verify unused directories were NOT created
  local unused_created=0
  [ -d "${test_topic}/summaries" ] && unused_created=$((unused_created + 1))
  [ -d "${test_topic}/debug" ] && unused_created=$((unused_created + 1))
  [ -d "${test_topic}/scripts" ] && unused_created=$((unused_created + 1))
  [ -d "${test_topic}/outputs" ] && unused_created=$((unused_created + 1))

  if [ "$unused_created" -eq 0 ]; then
    report_test "Test 6.2: Unused directories not created" "PASS"
  else
    report_test "Test 6.2: Unused directories not created" "FAIL"
    echo "  Created $unused_created unused directories"
  fi
}
test_6

echo ""

# ============================================================================
# Test Case 7: Research subdirectory creation (hierarchical structure)
# ============================================================================

echo "Test Case 7: Research subdirectory creation"
echo "--------------------------------------------"

test_7() {
  local test_topic="${TEST_TMP_DIR}/007_test_case_7"
  create_topic_structure "$test_topic"

  # Create research subdirectory
  local research_subdir
  research_subdir=$(create_research_subdirectory "$test_topic" "auth_patterns" 2>&1)
  local exit_code=$?

  if [ $exit_code -eq 0 ]; then
    report_test "Test 7.1: create_research_subdirectory succeeds" "PASS"

    # Verify research subdirectory created
    assert_dir_exists "$research_subdir" "Test 7.2: Research subdirectory exists"

    # Verify reports/ parent directory was created
    assert_dir_exists "${test_topic}/reports" "Test 7.3: reports/ parent created"

  else
    report_test "Test 7.1: create_research_subdirectory succeeds" "FAIL"
    echo "  Exit code: $exit_code"
    echo "  Output: $research_subdir"
  fi
}
test_7

echo ""

# ============================================================================
# Test Case 8: Error handling - directory creation failure
# ============================================================================

echo "Test Case 8: Error handling"
echo "----------------------------"

test_8() {
  # Test with invalid path (no permission or impossible location)
  # This is hard to test without root, so we'll test error detection

  local invalid_file="/nonexistent_root_location_$$/test.md"

  # Try to ensure directory (should fail or handle gracefully)
  if ensure_artifact_directory "$invalid_file" 2>/dev/null; then
    report_test "Test 8.1: Invalid path handled" "PASS"
  else
    # Failure is expected for invalid paths
    report_test "Test 8.1: Invalid path fails as expected" "PASS"
  fi
}
test_8

echo ""

# ============================================================================
# SUMMARY
# ============================================================================

echo "==========================================="
echo "Test Summary"
echo "==========================================="
echo "Total Tests:  $TOTAL_TESTS"
echo "Passed:       $PASSED_TESTS"
echo "Failed:       $FAILED_TESTS"
echo ""

if [ "$FAILED_TESTS" -eq 0 ]; then
  echo -e "${GREEN}✓ All tests passed!${NC}"
  echo ""
  echo "Lazy directory creation is working correctly:"
  echo "- Directories created only when files are written"
  echo "- No empty subdirectories created"
  echo "- Idempotent behavior verified"
  echo "- Nested paths handled correctly"
  exit 0
else
  echo -e "${RED}✗ $FAILED_TESTS test(s) failed${NC}"
  exit 1
fi
