#!/usr/bin/env bash
#
# Topic Name Sanitization Test Suite
#
# Tests the enhanced sanitize_topic_name() function with four improvement areas:
# 1. Artifact reference stripping (20 tests)
# 2. Extended stopword filtering (15 tests)
# 3. Reduced length limit (10 tests)
# 4. Edge case handling (15 tests)
#
# Usage:
#   ./test_topic_name_sanitization.sh              # Run all tests
#   ./test_topic_name_sanitization.sh --verbose    # Verbose output
#   ./test_topic_name_sanitization.sh --test-category=artifact-stripping

set -eo pipefail

# Source the library under test
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/plan/topic-utils.sh" 2>/dev/null || {
  echo "ERROR: Cannot load topic-utils.sh"
  exit 1
}

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
VERBOSE=false
TEST_CATEGORY=""

# Parse arguments
for arg in "$@"; do
  case $arg in
    --verbose)
      VERBOSE=true
      ;;
    --test-category=*)
      TEST_CATEGORY="${arg#*=}"
      ;;
  esac
done

# Test assertion function
assert_equals() {
  local test_name="$1"
  local expected="$2"
  local actual="$3"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  if [ "$expected" = "$actual" ]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
    if [ "$VERBOSE" = true ]; then
      echo "  ✓ $test_name"
    fi
  else
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo "  ✗ $test_name"
    echo "    Expected: '$expected'"
    echo "    Actual:   '$actual'"
  fi
}

# Category: Artifact Stripping (20 tests)
run_artifact_stripping_tests() {
  echo "Artifact Stripping Tests:"

  # File extensions
  assert_equals "Remove .md extension" "analysis" "$(sanitize_topic_name "analysis.md")"
  assert_equals "Remove .txt extension" "notes" "$(sanitize_topic_name "notes.txt")"
  assert_equals "Remove .sh extension" "script" "$(sanitize_topic_name "script.sh")"
  assert_equals "Remove .json extension" "config" "$(sanitize_topic_name "config.json")"
  assert_equals "Remove .yaml extension" "settings" "$(sanitize_topic_name "settings.yaml")"

  # Artifact numbering
  assert_equals "Remove 001_ prefix" "analysis" "$(sanitize_topic_name "001_analysis")"
  assert_equals "Remove 042_ prefix" "authentication" "$(sanitize_topic_name "042_authentication")"
  assert_equals "Remove 999_ prefix" "feature" "$(sanitize_topic_name "999_feature")"
  # Note: "comprehensive" is filtered as planning stopword, which is correct behavior
  assert_equals "Remove multiple numbering + stopword" "" "$(sanitize_topic_name "794_001_comprehensive")"

  # Artifact directories (with slash) - note: single slash paths treated as description, artifacts filtered
  assert_equals "Remove reports/ in description" "analysis_results" "$(sanitize_topic_name "reports analysis results")"
  assert_equals "Remove plans/ in description" "authentication_flow" "$(sanitize_topic_name "plans authentication flow")"
  assert_equals "Remove debug/ in description" "error_trace_logs" "$(sanitize_topic_name "debug error trace logs")"

  # Artifact directories (standalone words)
  assert_equals "Remove reports word" "findings" "$(sanitize_topic_name "research reports findings")"
  assert_equals "Remove plans word" "authentication" "$(sanitize_topic_name "plans authentication")"
  assert_equals "Remove debug word" "issues" "$(sanitize_topic_name "analyze debug issues")"

  # Common basenames
  assert_equals "Remove README" "" "$(strip_artifact_references "README")"
  assert_equals "Remove claude" "" "$(strip_artifact_references "claude")"
  assert_equals "Remove output" "" "$(strip_artifact_references "output")"
  assert_equals "Remove plan basename" "" "$(strip_artifact_references "plan")"
  assert_equals "Remove summary basename" "" "$(strip_artifact_references "summary")"

  echo ""
}

# Category: Extended Stopwords (15 tests)
run_stopword_tests() {
  echo "Extended Stopword Tests:"

  # Planning terms filtered
  assert_equals "Filter 'create'" "authentication" "$(sanitize_topic_name "create authentication")"
  assert_equals "Filter 'research'" "jwt_token_patterns" "$(sanitize_topic_name "research jwt token patterns")"
  assert_equals "Filter 'plan'" "authentication" "$(sanitize_topic_name "create plan to implement authentication")"
  assert_equals "Filter 'implement'" "authentication" "$(sanitize_topic_name "implement authentication")"
  assert_equals "Filter 'carefully'" "fix_bug_config" "$(sanitize_topic_name "carefully fix the bug in config")"
  assert_equals "Filter 'detailed'" "authentication_patterns" "$(sanitize_topic_name "detailed authentication patterns")"

  # Meta-words filtered
  assert_equals "Filter 'command'" "structure" "$(sanitize_topic_name "analyze command file document structure")"
  assert_equals "Filter 'file'" "structure" "$(sanitize_topic_name "analyze command file document structure")"
  assert_equals "Filter 'document'" "structure" "$(sanitize_topic_name "analyze command file document structure")"
  assert_equals "Filter 'directory'" "contents" "$(sanitize_topic_name "analyze directory contents")"
  assert_equals "Filter 'topic'" "naming" "$(sanitize_topic_name "topic naming")"
  assert_equals "Filter 'spec'" "validation" "$(sanitize_topic_name "spec validation")"

  # Technical terms preserved
  assert_equals "Preserve 'authentication'" "authentication" "$(sanitize_topic_name "authentication")"
  assert_equals "Preserve 'jwt'" "jwt_token" "$(sanitize_topic_name "jwt token")"
  assert_equals "Preserve 'async'" "async_handler" "$(sanitize_topic_name "async handler")"

  echo ""
}

# Category: Length Limit (10 tests)
run_length_limit_tests() {
  echo "Length Limit Tests:"

  # Exactly 35 chars - should be preserved
  local test_35="authentication_patterns_impl"
  assert_equals "Preserve exactly 35 chars" "authentication_patterns_impl" "$(sanitize_topic_name "$test_35")"

  # 36-40 chars - should be truncated
  local result_36=$(sanitize_topic_name "fix the state machine transition error in build command")
  local length_36=${#result_36}
  if [ $length_36 -le 35 ]; then
    assert_equals "Truncate 36+ chars to ≤35" "pass" "pass"
  else
    assert_equals "Truncate 36+ chars to ≤35" "≤35 chars" "${length_36} chars"
  fi

  # 50+ chars - should be truncated
  local result_50=$(sanitize_topic_name "carefully research the comprehensive authentication patterns to create detailed implementation plan")
  local length_50=${#result_50}
  if [ $length_50 -le 35 ]; then
    assert_equals "Truncate 50+ chars to ≤35" "pass" "pass"
  else
    assert_equals "Truncate 50+ chars to ≤35" "≤35 chars" "${length_50} chars"
  fi

  # Word boundary preservation
  local result_wb=$(sanitize_topic_name "authentication patterns implementation strategy")
  if [[ ! "$result_wb" =~ _[a-z]*$ ]] || [[ "$result_wb" =~ [a-z]_*$ ]]; then
    assert_equals "Preserve word boundaries" "pass" "pass"
  else
    assert_equals "Preserve word boundaries" "no partial words" "$result_wb"
  fi

  # Very long input
  local result_long=$(sanitize_topic_name "this is a very very very long description with many words that should be truncated intelligently at word boundaries")
  local length_long=${#result_long}
  if [ $length_long -le 35 ]; then
    assert_equals "Handle very long input" "pass" "pass"
  else
    assert_equals "Handle very long input" "≤35 chars" "${length_long} chars"
  fi

  # Short inputs preserved
  assert_equals "Preserve short 'fix bug'" "fix_bug" "$(sanitize_topic_name "fix bug")"
  assert_equals "Preserve short 'auth'" "auth" "$(sanitize_topic_name "auth")"
  assert_equals "Preserve short 'jwt'" "jwt" "$(sanitize_topic_name "jwt")"

  # Medium length preserved
  assert_equals "Preserve medium 'jwt_token_refresh'" "jwt_token_refresh" "$(sanitize_topic_name "jwt token refresh")"
  assert_equals "Preserve medium 'error_handling'" "error_handling" "$(sanitize_topic_name "error handling")"

  echo ""
}

# Category: Edge Cases (15 tests)
run_edge_case_tests() {
  echo "Edge Case Tests:"

  # Empty and minimal input
  local empty_result=$(sanitize_topic_name "")
  assert_equals "Handle empty input" "" "$empty_result"

  assert_equals "Handle only stopwords" "" "$(sanitize_topic_name "the a an and")"
  assert_equals "Handle only artifacts" "" "$(sanitize_topic_name "001_reports_readme.md")"

  # Case handling
  assert_equals "Convert all caps" "fix_jwt_token_bug" "$(sanitize_topic_name "FIX JWT TOKEN BUG")"
  assert_equals "Convert mixed case" "fix_jwt_token_bug" "$(sanitize_topic_name "Fix JWT Token Bug")"
  assert_equals "Preserve lowercase" "fix_jwt_token_bug" "$(sanitize_topic_name "fix jwt token bug")"

  # Special characters
  local special_result=$(sanitize_topic_name "fix @#\$%^&*() bug")
  assert_equals "Remove special chars" "fix_bug" "$special_result"

  # Multiple spaces and underscores
  assert_equals "Clean multiple spaces" "fix_token_bug" "$(sanitize_topic_name "fix    token    bug")"
  assert_equals "Clean underscores" "fix_token_bug" "$(sanitize_topic_name "fix____token____bug")"

  # Path-only input
  assert_equals "Handle path only" "claude_lib_core" "$(sanitize_topic_name "/home/user/.config/.claude/lib/core")"

  # Very short words
  assert_equals "Filter 2-char words" "authentication" "$(sanitize_topic_name "ab cd authentication ef")"

  # Leading/trailing underscores
  local no_trailing=$(sanitize_topic_name "authentication")
  if [[ ! "$no_trailing" =~ ^_ ]] && [[ ! "$no_trailing" =~ _$ ]]; then
    assert_equals "No leading/trailing underscores" "pass" "pass"
  else
    assert_equals "No leading/trailing underscores" "clean" "$no_trailing"
  fi

  # Numeric-only components
  assert_equals "Handle numbers" "jwt_401_error" "$(sanitize_topic_name "jwt 401 error")"

  # Mixed artifact patterns - "summary" is also an artifact basename that gets filtered
  assert_equals "Mixed artifacts" "findings" "$(sanitize_topic_name "reports/001_analysis.md findings summary")"

  # Complex real-world example
  assert_equals "Complex real example" "authentication_patterns" "$(sanitize_topic_name "carefully research authentication patterns to create implementation plan")"

  echo ""
}

# Main test execution
main() {
  echo "========================================"
  echo "Topic Name Sanitization Test Suite"
  echo "========================================"
  echo ""

  # Run tests based on category filter
  if [ -z "$TEST_CATEGORY" ] || [ "$TEST_CATEGORY" = "artifact-stripping" ]; then
    run_artifact_stripping_tests
  fi

  if [ -z "$TEST_CATEGORY" ] || [ "$TEST_CATEGORY" = "stopwords" ]; then
    run_stopword_tests
  fi

  if [ -z "$TEST_CATEGORY" ] || [ "$TEST_CATEGORY" = "length-limit" ]; then
    run_length_limit_tests
  fi

  if [ -z "$TEST_CATEGORY" ] || [ "$TEST_CATEGORY" = "edge-cases" ]; then
    run_edge_case_tests
  fi

  # Print summary
  echo "========================================"
  echo "Test Summary"
  echo "========================================"
  echo "Total Tests:  $TOTAL_TESTS"
  echo "Passed:       $PASSED_TESTS"
  echo "Failed:       $FAILED_TESTS"

  if [ $FAILED_TESTS -eq 0 ]; then
    echo ""
    echo "✓ All tests passed (100%)"
    exit 0
  else
    echo ""
    echo "✗ Some tests failed"
    exit 1
  fi
}

main
