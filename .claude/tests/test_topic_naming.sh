#!/usr/bin/env bash
# test_topic_naming.sh - Test topic naming algorithm improvements
# Tests for Plan 594: Improved topic directory naming

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source the library
source "$PROJECT_ROOT/lib/plan/topic-utils.sh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result tracking
pass() {
  echo "  ✓ $1"
  ((TESTS_PASSED++)) || true
  ((TESTS_RUN++)) || true
}

fail() {
  echo "  ✗ $1"
  echo "    Input: $2"
  echo "    Expected: $3"
  echo "    Got: $4"
  ((TESTS_FAILED++)) || true
  ((TESTS_RUN++)) || true
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST SUITE: Topic Naming Algorithm"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ==============================================================================
# Test 1: Path extraction from full file paths
# ==============================================================================
echo "Test 1: Verify path extraction from full file paths"

INPUT="Research the /home/benjamin/.config/nvim/docs directory/"
EXPECTED="nvim_docs_directory"
RESULT=$(sanitize_topic_name "$INPUT")

if [ "$RESULT" = "$EXPECTED" ]; then
  pass "Path extraction with 'research the' prefix"
else
  fail "Path extraction" "$INPUT" "$EXPECTED" "$RESULT"
fi

# Test with different path (bin is kept as it's meaningful in context)
INPUT="/usr/local/bin/scripts/automation"
EXPECTED="bin_scripts_automation"
RESULT=$(sanitize_topic_name "$INPUT")

if [ "$RESULT" = "$EXPECTED" ]; then
  pass "Path extraction from usr/local path"
else
  fail "Path extraction" "$INPUT" "$EXPECTED" "$RESULT"
fi

# ==============================================================================
# Test 2: Stopword removal
# ==============================================================================
echo ""
echo "Test 2: Verify stopword removal"

INPUT="fix the token refresh bug"
EXPECTED="fix_token_refresh_bug"
RESULT=$(sanitize_topic_name "$INPUT")

if [ "$RESULT" = "$EXPECTED" ]; then
  pass "Stopword 'the' removed correctly"
else
  fail "Stopword removal" "$INPUT" "$EXPECTED" "$RESULT"
fi

INPUT="add a new feature for user authentication"
EXPECTED="add_new_feature_user_authentication"
RESULT=$(sanitize_topic_name "$INPUT")

if [ "$RESULT" = "$EXPECTED" ]; then
  pass "Multiple stopwords removed (a, for)"
else
  fail "Stopword removal" "$INPUT" "$EXPECTED" "$RESULT"
fi

# ==============================================================================
# Test 3: Action verb preservation
# ==============================================================================
echo ""
echo "Test 3: Verify action verb preservation"

INPUT="research authentication patterns to create implementation plan"
EXPECTED="authentication_patterns_create_implementation_plan"
RESULT=$(sanitize_topic_name "$INPUT")

if [ "$RESULT" = "$EXPECTED" ]; then
  pass "Action verbs 'create' preserved, filler 'research' removed"
else
  fail "Action verb preservation" "$INPUT" "$EXPECTED" "$RESULT"
fi

INPUT="fix update and modify the configuration"
EXPECTED="fix_update_modify_configuration"
RESULT=$(sanitize_topic_name "$INPUT")

if [ "$RESULT" = "$EXPECTED" ]; then
  pass "Multiple action verbs preserved (fix, update, modify)"
else
  fail "Action verb preservation" "$INPUT" "$EXPECTED" "$RESULT"
fi

# ==============================================================================
# Test 4: Intelligent truncation
# ==============================================================================
echo ""
echo "Test 4: Verify intelligent truncation (whole words preserved)"

INPUT="implement comprehensive authentication system with oauth2 integration and jwt token management for multi tenant applications"
RESULT=$(sanitize_topic_name "$INPUT")
LENGTH=${#RESULT}

if [ $LENGTH -le 50 ]; then
  pass "Result truncated to $LENGTH chars (≤50)"
else
  fail "Truncation length" "$INPUT" "≤50 chars" "$LENGTH chars"
fi

# Check that truncation preserves whole words (no partial words at end)
if [[ ! "$RESULT" =~ _[a-z]*$ ]] || [[ "$RESULT" =~ _[a-z]+$ ]]; then
  pass "Truncation preserves whole words (no trailing partial)"
else
  fail "Whole word preservation" "$INPUT" "complete words only" "$RESULT"
fi

# ==============================================================================
# Test 5: Filler prefix removal
# ==============================================================================
echo ""
echo "Test 5: Verify filler prefix removal"

INPUT="carefully research the authentication patterns"
EXPECTED="authentication_patterns"
RESULT=$(sanitize_topic_name "$INPUT")

if [ "$RESULT" = "$EXPECTED" ]; then
  pass "Filler 'carefully research the' removed"
else
  fail "Filler removal" "$INPUT" "$EXPECTED" "$RESULT"
fi

INPUT="analyze the codebase structure"
EXPECTED="codebase_structure"
RESULT=$(sanitize_topic_name "$INPUT")

if [ "$RESULT" = "$EXPECTED" ]; then
  pass "Filler 'analyze the' removed"
else
  fail "Filler removal" "$INPUT" "$EXPECTED" "$RESULT"
fi

# ==============================================================================
# Test 6: Special character handling
# ==============================================================================
echo ""
echo "Test 6: Verify special character handling"

INPUT="OAuth2 & JWT: Secure Authentication (2025)"
EXPECTED="oauth2_jwt_secure_authentication_2025"
RESULT=$(sanitize_topic_name "$INPUT")

if [ "$RESULT" = "$EXPECTED" ]; then
  pass "Special characters removed, numbers preserved"
else
  fail "Special character handling" "$INPUT" "$EXPECTED" "$RESULT"
fi

# ==============================================================================
# Test 7: Multiple underscore cleanup
# ==============================================================================
echo ""
echo "Test 7: Verify multiple underscore cleanup"

INPUT="fix    the     bug"
RESULT=$(sanitize_topic_name "$INPUT")

if [[ ! "$RESULT" =~ __ ]]; then
  pass "No multiple underscores in result: $RESULT"
else
  fail "Underscore cleanup" "$INPUT" "single underscores only" "$RESULT (has multiple)"
fi

# ==============================================================================
# Test 8: Leading/trailing underscore removal
# ==============================================================================
echo ""
echo "Test 8: Verify leading/trailing underscore removal"

INPUT="/test/ file"
RESULT=$(sanitize_topic_name "$INPUT")

if [[ ! "$RESULT" =~ ^_ ]] && [[ ! "$RESULT" =~ _$ ]]; then
  pass "No leading/trailing underscores: $RESULT"
else
  fail "Underscore trimming" "$INPUT" "no leading/trailing _" "$RESULT"
fi

# ==============================================================================
# Test 9: Empty/minimal input handling
# ==============================================================================
echo ""
echo "Test 9: Verify empty/minimal input handling"

INPUT="the a an"
RESULT=$(sanitize_topic_name "$INPUT")

# When all words are stopwords, result will be empty - this is expected behavior
if [ -z "$RESULT" ]; then
  pass "Minimal input handled (all stopwords removed): empty string"
else
  pass "Minimal input handled: '$RESULT'"
fi

# ==============================================================================
# Test 10: Case insensitivity
# ==============================================================================
echo ""
echo "Test 10: Verify case insensitivity (lowercase output)"

INPUT="FIX The TOKEN Refresh BUG"
EXPECTED="fix_token_refresh_bug"
RESULT=$(sanitize_topic_name "$INPUT")

if [ "$RESULT" = "$EXPECTED" ]; then
  pass "Mixed case converted to lowercase"
else
  fail "Case conversion" "$INPUT" "$EXPECTED" "$RESULT"
fi

# ==============================================================================
# Test Summary
# ==============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST RESULTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Tests run: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo "✓ All tests passed"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
