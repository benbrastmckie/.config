#!/usr/bin/env bash
# Test suite for topic-based spec organization utilities
# Tests functions from .claude/lib/template-integration.sh and .claude/lib/artifact-operations.sh

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$CLAUDE_DIR/.." && pwd)"

# Source utilities
source "$CLAUDE_DIR/lib/template-integration.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Helper functions
pass() {
  echo -e "${GREEN}[PASS]${NC} $1"
  ((TESTS_PASSED++))
}

fail() {
  echo -e "${RED}[FAIL]${NC} $1"
  ((TESTS_FAILED++))
}

# Test extract_topic_from_question
test_extract_topic_from_question() {
  echo "Testing extract_topic_from_question..."
  ((TESTS_RUN++))

  local test_cases=(
    "Implement OAuth2 with Google|oauth2_google"
    "Add user authentication with JWT|user_authentication_jwt"
    "Fix the database connection issue|database_connection_issue"
    "Refactor code for better performance|refactor_code_performance"
    "Research best practices for API design|api_design"
  )

  local all_passed=true

  for test_case in "${test_cases[@]}"; do
    IFS='|' read -r input expected <<< "$test_case"
    local result=$(extract_topic_from_question "$input")

    if [[ "$result" == "$expected" ]]; then
      echo "  ✓ '$input' → '$result'"
    else
      echo "  ✗ '$input' → expected '$expected', got '$result'"
      all_passed=false
    fi
  done

  if $all_passed; then
    pass "extract_topic_from_question handles various inputs correctly"
  else
    fail "extract_topic_from_question produced unexpected results"
  fi
}

# Test find_matching_topic
test_find_matching_topic() {
  echo "Testing find_matching_topic..."
  ((TESTS_RUN++))

  # Create test topics
  local test_dir="$CLAUDE_DIR/specs/999_test_authentication"
  mkdir -p "$test_dir"

  # Test finding existing topic
  local match=$(find_matching_topic "auth")

  if [[ "$match" == *"999_test_authentication"* ]]; then
    pass "find_matching_topic finds existing topic by keyword"
  else
    fail "find_matching_topic did not find topic (got: '$match')"
  fi

  # Cleanup
  rmdir "$test_dir"

  # Test not finding non-existent topic
  ((TESTS_RUN++))
  local no_match=$(find_matching_topic "nonexistent_topic_xyz")

  if [[ -z "$no_match" ]]; then
    pass "find_matching_topic returns empty for non-existent topic"
  else
    fail "find_matching_topic should return empty for non-existent topic (got: '$no_match')"
  fi
}

# Test get_next_topic_number
test_get_next_topic_number() {
  echo "Testing get_next_topic_number..."
  ((TESTS_RUN++))

  # Create test topics with specific numbers
  local specs_dir="$CLAUDE_DIR/specs"
  mkdir -p "$specs_dir/060_test_topic_a"
  mkdir -p "$specs_dir/061_test_topic_b"

  local next_num=$(get_next_topic_number "$specs_dir")

  # Should return 062 (next after 061)
  if [[ "$next_num" == "062" ]]; then
    pass "get_next_topic_number returns correct next number"
  else
    fail "get_next_topic_number expected '062', got '$next_num'"
  fi

  # Cleanup
  rmdir "$specs_dir/060_test_topic_a"
  rmdir "$specs_dir/061_test_topic_b"
}

# Test get_or_create_topic_dir
test_get_or_create_topic_dir() {
  echo "Testing get_or_create_topic_dir..."
  ((TESTS_RUN++))

  local specs_dir="$CLAUDE_DIR/specs"
  local topic_name="test_feature_xyz"

  # Create topic directory
  local topic_dir=$(get_or_create_topic_dir "$topic_name" "$specs_dir")

  # Check topic directory exists
  if [[ -d "$topic_dir" ]]; then
    pass "get_or_create_topic_dir creates topic directory"
  else
    fail "get_or_create_topic_dir did not create topic directory"
    return
  fi

  # Check standard subdirectories exist
  ((TESTS_RUN++))
  local required_subdirs=("plans" "reports" "summaries" "debug" "scripts" "outputs" "artifacts" "backups")
  local all_exist=true

  for subdir in "${required_subdirs[@]}"; do
    if [[ ! -d "$topic_dir/$subdir" ]]; then
      echo "  ✗ Missing subdirectory: $subdir"
      all_exist=false
    fi
  done

  if $all_exist; then
    pass "get_or_create_topic_dir creates all standard subdirectories"
  else
    fail "get_or_create_topic_dir missing some subdirectories"
  fi

  # Test calling again returns same directory
  ((TESTS_RUN++))
  local topic_dir2=$(get_or_create_topic_dir "$topic_name" "$specs_dir")

  if [[ "$topic_dir" == "$topic_dir2" ]]; then
    pass "get_or_create_topic_dir returns existing topic on second call"
  else
    fail "get_or_create_topic_dir should return same directory (got '$topic_dir2')"
  fi

  # Cleanup
  rm -rf "$topic_dir"
}

# Test validate_gitignore_compliance
test_validate_gitignore_compliance() {
  echo "Testing validate_gitignore_compliance..."
  ((TESTS_RUN++))

  local specs_dir="$CLAUDE_DIR/specs"
  local topic_dir=$(get_or_create_topic_dir "test_gitignore_check" "$specs_dir")

  # Run validation
  local compliance=$(validate_gitignore_compliance "$topic_dir")

  # Check if returns valid JSON
  if echo "$compliance" | jq empty 2>/dev/null; then
    pass "validate_gitignore_compliance returns valid JSON"
  else
    fail "validate_gitignore_compliance did not return valid JSON"
    rm -rf "$topic_dir"
    return
  fi

  # Check debug_committed field
  ((TESTS_RUN++))
  local debug_committed=$(echo "$compliance" | jq -r '.debug_committed')

  # debug/ should NOT be gitignored (committed)
  if [[ "$debug_committed" == "true" ]]; then
    pass "validate_gitignore_compliance correctly identifies debug/ as committed"
  else
    fail "validate_gitignore_compliance should show debug/ as committed (got: $debug_committed)"
  fi

  # Cleanup
  rm -rf "$topic_dir"
}

# Test get_next_artifact_number
test_get_next_artifact_number() {
  echo "Testing get_next_artifact_number..."
  ((TESTS_RUN++))

  local specs_dir="$CLAUDE_DIR/specs"
  local topic_dir=$(get_or_create_topic_dir "test_artifact_numbering" "$specs_dir")

  # Create some test artifacts
  touch "$topic_dir/plans/001_first_plan.md"
  touch "$topic_dir/plans/002_second_plan.md"

  # Get next number
  local next_num=$(get_next_artifact_number "$topic_dir/plans")

  if [[ "$next_num" == "003" ]]; then
    pass "get_next_artifact_number returns correct next number"
  else
    fail "get_next_artifact_number expected '003', got '$next_num'"
  fi

  # Test with empty directory
  ((TESTS_RUN++))
  local next_num_empty=$(get_next_artifact_number "$topic_dir/reports")

  if [[ "$next_num_empty" == "001" ]]; then
    pass "get_next_artifact_number returns '001' for empty directory"
  else
    fail "get_next_artifact_number expected '001' for empty dir, got '$next_num_empty'"
  fi

  # Cleanup
  rm -rf "$topic_dir"
}

# Test create_topic_artifact
test_create_topic_artifact() {
  echo "Testing create_topic_artifact..."
  ((TESTS_RUN++))

  local specs_dir="$CLAUDE_DIR/specs"
  local topic_dir=$(get_or_create_topic_dir "test_artifact_creation" "$specs_dir")

  # Create an artifact
  local content="# Test Plan\n\nThis is a test plan."
  local artifact_path=$(create_topic_artifact "$topic_dir" "plans" "test_plan" "$content")

  # Check artifact was created
  if [[ -f "$artifact_path" ]]; then
    pass "create_topic_artifact creates artifact file"
  else
    fail "create_topic_artifact did not create file at '$artifact_path'"
    rm -rf "$topic_dir"
    return
  fi

  # Check file has correct content
  ((TESTS_RUN++))
  if grep -q "Test Plan" "$artifact_path"; then
    pass "create_topic_artifact writes correct content"
  else
    fail "create_topic_artifact content does not match"
  fi

  # Check numbering
  ((TESTS_RUN++))
  if [[ "$artifact_path" == *"/001_test_plan.md" ]]; then
    pass "create_topic_artifact uses correct numbering (001)"
  else
    fail "create_topic_artifact numbering incorrect (got: $artifact_path)"
  fi

  # Create second artifact, check it gets 002
  ((TESTS_RUN++))
  local artifact_path2=$(create_topic_artifact "$topic_dir" "plans" "second_plan" "# Second Plan")

  if [[ "$artifact_path2" == *"/002_second_plan.md" ]]; then
    pass "create_topic_artifact increments numbering correctly (002)"
  else
    fail "create_topic_artifact should use 002 (got: $artifact_path2)"
  fi

  # Cleanup
  rm -rf "$topic_dir"
}

# Test edge cases
test_edge_cases() {
  echo "Testing edge cases..."

  # Test extract_topic_from_question with empty input
  ((TESTS_RUN++))
  local empty_result=$(extract_topic_from_question "")
  if [[ -z "$empty_result" ]]; then
    pass "extract_topic_from_question handles empty input"
  else
    fail "extract_topic_from_question should return empty for empty input"
  fi

  # Test extract_topic_from_question with special characters
  ((TESTS_RUN++))
  local special_result=$(extract_topic_from_question "Test! @#$ %^& *()")
  if [[ -n "$special_result" ]]; then
    pass "extract_topic_from_question handles special characters"
  else
    fail "extract_topic_from_question failed with special characters"
  fi

  # Test find_matching_topic with no topics
  ((TESTS_RUN++))
  local no_topics_result=$(find_matching_topic "xyz_nonexistent")
  if [[ -z "$no_topics_result" ]]; then
    pass "find_matching_topic handles no topics gracefully"
  else
    fail "find_matching_topic should return empty when no topics exist"
  fi
}

# Run all tests
main() {
  echo "============================================"
  echo "Topic Utilities Test Suite"
  echo "============================================"
  echo ""

  test_extract_topic_from_question
  echo ""

  test_find_matching_topic
  echo ""

  test_get_next_topic_number
  echo ""

  test_get_or_create_topic_dir
  echo ""

  test_validate_gitignore_compliance
  echo ""

  test_get_next_artifact_number
  echo ""

  test_create_topic_artifact
  echo ""

  test_edge_cases
  echo ""

  # Summary
  echo "============================================"
  echo "Test Summary"
  echo "============================================"
  echo "Tests run:    $TESTS_RUN"
  echo "Tests passed: $TESTS_PASSED"
  echo "Tests failed: $TESTS_FAILED"

  if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    return 0
  else
    echo -e "${RED}Some tests failed${NC}"
    return 1
  fi
}

# Run tests
main "$@"
