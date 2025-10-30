#!/usr/bin/env bash
# test_unified_location_simple.sh
#
# Simplified unit tests for unified-location-detection.sh library
# Focuses on core functionality without complex setup
#
# Usage: ./test_unified_location_simple.sh

# Use relaxed error mode to allow library functions to handle expected failures gracefully
set -eo pipefail

# Source the library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"
source "${LIB_DIR}/unified-location-detection.sh"

# Test temp directory
TEST_TMP_DIR="/tmp/test_unified_simple_$$"
mkdir -p "$TEST_TMP_DIR"
trap 'rm -rf "$TEST_TMP_DIR"' EXIT

PASSED=0
FAILED=0

test_pass() {
  echo "✓ $1"
  PASSED=$((PASSED + 1))
}

test_fail() {
  echo "✗ $1"
  echo "  $2"
  FAILED=$((FAILED + 1))
}

echo "Unified Location Detection - Core Function Tests"
echo "================================================="
echo ""

# Test 1: sanitize_topic_name
echo "Test 1: Topic Name Sanitization"
RESULT=$(sanitize_topic_name "Research: Authentication Patterns")
if [ "$RESULT" = "research_authentication_patterns" ]; then
  test_pass "Sanitization: spaces and special chars"
else
  test_fail "Sanitization failed" "Expected: research_authentication_patterns, Got: $RESULT"
fi

# Test 2: get_next_topic_number (empty directory)
echo ""
echo "Test 2: Topic Number Calculation"
mkdir -p "$TEST_TMP_DIR/empty_specs"
RESULT=$(get_next_topic_number "$TEST_TMP_DIR/empty_specs")
if [ "$RESULT" = "001" ]; then
  test_pass "Empty directory returns 001"
else
  test_fail "Empty directory test failed" "Expected: 001, Got: $RESULT"
fi

# Test 3: get_next_topic_number (with existing topics)
mkdir -p "$TEST_TMP_DIR/specs_with_topics/005_existing"
RESULT=$(get_next_topic_number "$TEST_TMP_DIR/specs_with_topics")
if [ "$RESULT" = "006" ]; then
  test_pass "Sequential numbering (005 → 006)"
else
  test_fail "Sequential numbering failed" "Expected: 006, Got: $RESULT"
fi

# Test 4: create_topic_structure (lazy creation pattern)
echo ""
echo "Test 3: Directory Structure Creation"
TOPIC_PATH="$TEST_TMP_DIR/test_topic/001_test"
if create_topic_structure "$TOPIC_PATH"; then
  # Test lazy creation: only topic root should exist, not subdirectories
  if [ -d "$TOPIC_PATH" ]; then
    test_pass "Topic root created (lazy subdirectory creation)"
  else
    test_fail "Topic root creation failed" "Directory does not exist: $TOPIC_PATH"
  fi

  # Verify lazy creation works by creating a report
  REPORT_PATH="$TOPIC_PATH/reports/001_test_report.md"
  if ensure_artifact_directory "$REPORT_PATH"; then
    if [ -d "$TOPIC_PATH/reports" ]; then
      test_pass "Lazy creation: reports/ created on-demand"
    else
      test_fail "Lazy creation failed" "reports/ not created by ensure_artifact_directory"
    fi
  else
    test_fail "ensure_artifact_directory failed" "Function returned non-zero"
  fi
else
  test_fail "create_topic_structure failed" "Function returned non-zero"
fi

# Test 5: detect_project_root with override
echo ""
echo "Test 4: Project Root Detection"
export CLAUDE_PROJECT_DIR="/custom/project/path"
RESULT=$(detect_project_root)
unset CLAUDE_PROJECT_DIR
if [ "$RESULT" = "/custom/project/path" ]; then
  test_pass "CLAUDE_PROJECT_DIR override works"
else
  test_fail "Override failed" "Expected: /custom/project/path, Got: $RESULT"
fi

# Test 6: detect_specs_directory (prefer .claude/specs)
echo ""
echo "Test 5: Specs Directory Detection"
TEST_ROOT="$TEST_TMP_DIR/test_project"
mkdir -p "$TEST_ROOT/.claude/specs"
mkdir -p "$TEST_ROOT/specs"
RESULT=$(detect_specs_directory "$TEST_ROOT")
if [ "$RESULT" = "$TEST_ROOT/.claude/specs" ]; then
  test_pass "Prefers .claude/specs over specs"
else
  test_fail "Specs detection failed" "Expected: $TEST_ROOT/.claude/specs, Got: $RESULT"
fi

# Test 7: perform_location_detection (full workflow)
echo ""
echo "Test 6: Full Location Detection Workflow"
export CLAUDE_PROJECT_DIR="$TEST_TMP_DIR/full_test"
mkdir -p "$TEST_TMP_DIR/full_test/.claude/specs"
RESULT=$(perform_location_detection "test workflow" "true")

if echo "$RESULT" | grep -q '"topic_number"'; then
  if echo "$RESULT" | grep -q '"topic_path"'; then
    if echo "$RESULT" | grep -q '"artifact_paths"'; then
      test_pass "Full workflow generates complete JSON"
    else
      test_fail "Full workflow missing artifact_paths" "JSON: $RESULT"
    fi
  else
    test_fail "Full workflow missing topic_path" "JSON: $RESULT"
  fi
else
  test_fail "Full workflow missing topic_number" "JSON: $RESULT"
fi
unset CLAUDE_PROJECT_DIR

# Summary
echo ""
echo "================================================="
echo "Test Summary"
echo "================================================="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo ""

if [ "$FAILED" -eq 0 ]; then
  echo "✓ All tests passed!"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
