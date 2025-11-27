#!/bin/bash
# .claude/tests/test_topic_decomposition.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$CLAUDE_ROOT/lib/plan/topic-decomposition.sh"

echo "========================================="
echo "Testing Topic Decomposition Utility"
echo "========================================="
echo ""

test_validate_subtopic_name() {
  echo "Test 1: Subtopic Name Validation"
  echo "----------------------------"

  # Valid names
  validate_subtopic_name "jwt_patterns" || { echo "ERROR: Valid name rejected: jwt_patterns"; exit 1; }
  validate_subtopic_name "oauth2_flows" || { echo "ERROR: Valid name rejected: oauth2_flows"; exit 1; }
  validate_subtopic_name "a" || { echo "ERROR: Valid single char rejected: a"; exit 1; }
  validate_subtopic_name "test_123_name" || { echo "ERROR: Valid name with numbers rejected: test_123_name"; exit 1; }

  echo "✓ Valid names accepted"

  # Invalid names (should fail)
  if validate_subtopic_name "JWT Patterns" 2>/dev/null; then
    echo "ERROR: Invalid name accepted: JWT Patterns (uppercase/spaces)"
    exit 1
  fi

  if validate_subtopic_name "oauth-flows" 2>/dev/null; then
    echo "ERROR: Invalid name accepted: oauth-flows (hyphens)"
    exit 1
  fi

  if validate_subtopic_name "123_starts_with_number" 2>/dev/null; then
    echo "ERROR: Invalid name accepted: 123_starts_with_number (starts with number)"
    exit 1
  fi

  if validate_subtopic_name "a_very_long_subtopic_name_that_exceeds_fifty_characters_limit" 2>/dev/null; then
    echo "ERROR: Invalid name accepted: too long (>50 chars)"
    exit 1
  fi

  echo "✓ Invalid names rejected"
  echo "✓ Subtopic validation tests passed"
  echo ""
}

test_calculate_subtopic_count() {
  echo "Test 2: Subtopic Count Calculation"
  echo "----------------------------"

  local count

  # 1-3 words → 2 subtopics
  count=$(calculate_subtopic_count "authentication patterns")
  if [ "$count" -ne 2 ]; then
    echo "ERROR: Expected 2 subtopics for 'authentication patterns', got $count"
    exit 1
  fi
  echo "✓ 2 words → 2 subtopics"

  count=$(calculate_subtopic_count "api design patterns")
  if [ "$count" -ne 2 ]; then
    echo "ERROR: Expected 2 subtopics for 'api design patterns', got $count"
    exit 1
  fi
  echo "✓ 3 words → 2 subtopics"

  # 4-6 words → 3 subtopics
  count=$(calculate_subtopic_count "authentication patterns and security best")
  if [ "$count" -ne 3 ]; then
    echo "ERROR: Expected 3 subtopics for 5-word topic, got $count"
    exit 1
  fi
  echo "✓ 5 words → 3 subtopics"

  # 7+ words → 4 subtopics
  count=$(calculate_subtopic_count "authentication patterns and security best practices for modern applications")
  if [ "$count" -ne 4 ]; then
    echo "ERROR: Expected 4 subtopics for 10-word topic, got $count"
    exit 1
  fi
  echo "✓ 10 words → 4 subtopics"

  echo "✓ Subtopic count calculation tests passed"
  echo ""
}

test_decomposition_prompt_generation() {
  echo "Test 3: Decomposition Prompt Generation"
  echo "----------------------------"

  local prompt
  prompt=$(decompose_research_topic "authentication patterns")

  # Check prompt contains key elements
  if ! echo "$prompt" | grep -q "Research Topic: authentication patterns"; then
    echo "ERROR: Prompt missing research topic"
    exit 1
  fi
  echo "✓ Prompt contains research topic"

  if ! echo "$prompt" | grep -q "one per line"; then
    echo "ERROR: Prompt missing output format instructions"
    exit 1
  fi
  echo "✓ Prompt contains output format instructions"

  if ! echo "$prompt" | grep -q "focused and specific"; then
    echo "ERROR: Prompt missing quality requirements"
    exit 1
  fi
  echo "✓ Prompt contains quality requirements"

  if ! echo "$prompt" | grep -q "Example for"; then
    echo "ERROR: Prompt missing example"
    exit 1
  fi
  echo "✓ Prompt contains example"

  echo "✓ Decomposition prompt generation tests passed"
  echo ""
}

test_error_handling() {
  echo "Test 4: Error Handling"
  echo "----------------------------"

  # Test empty research topic
  if decompose_research_topic "" 2>/dev/null; then
    echo "ERROR: Empty research topic should fail"
    exit 1
  fi
  echo "✓ Empty research topic rejected"

  # Test edge cases for subtopic count
  count=$(calculate_subtopic_count "a")
  if [ "$count" -ne 2 ]; then
    echo "ERROR: Single word should produce 2 subtopics, got $count"
    exit 1
  fi
  echo "✓ Single word handled correctly"

  echo "✓ Error handling tests passed"
  echo ""
}

# Run all tests
test_validate_subtopic_name
test_calculate_subtopic_count
test_decomposition_prompt_generation
test_error_handling

echo "========================================="
echo "All topic decomposition tests passed!"
echo "========================================="

exit 0
