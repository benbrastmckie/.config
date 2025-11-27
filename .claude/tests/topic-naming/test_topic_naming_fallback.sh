#!/usr/bin/env bash
# test_topic_naming_fallback.sh - Tests for topic naming fallback mechanisms
# Tests "no_name" fallback triggers and error logging integration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect project root using git or walk-up pattern
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  CLAUDE_PROJECT_DIR="$SCRIPT_DIR"
  while [ "$CLAUDE_PROJECT_DIR" != "/" ]; do
    if [ -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
      break
    fi
    CLAUDE_PROJECT_DIR="$(dirname "$CLAUDE_PROJECT_DIR")"
  done
fi
CLAUDE_LIB="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Source required libraries
source "$CLAUDE_LIB/plan/topic-utils.sh" 2>/dev/null || {
  echo "ERROR: Cannot load topic-utils library"
  exit 1
}

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
  if [ $# -ge 2 ]; then
    echo "    Reason: $2"
  fi
  ((TESTS_FAILED++)) || true
  ((TESTS_RUN++)) || true
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST SUITE: Topic Naming Fallback Mechanisms"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ==============================================================================
# Test 1: "no_name" is valid fallback format
# ==============================================================================
echo "Test 1: Verify 'no_name' fallback is valid format"

if validate_topic_name_format "no_name"; then
  pass "no_name is valid fallback (7 chars, lowercase, underscores)"
else
  fail "no_name rejected" "Fallback sentinel must be valid format"
fi

# ==============================================================================
# Test 2: Validation edge cases that should trigger fallback
# ==============================================================================
echo ""
echo "Test 2: Validation edge cases requiring fallback"

# Test various invalid formats that should trigger fallback
invalid_formats=(
  ""                    # Empty string
  "a"                   # Too short (1 char)
  "ab"                  # Too short (2 chars)
  "abc"                 # Too short (3 chars)
  "abcd"                # Too short (4 chars)
  "JWT-Auth"            # Contains hyphens
  "JWT_Auth"            # Contains uppercase
  "jwt auth"            # Contains spaces
  "jwt@auth"            # Contains special chars
  "_jwt_auth"           # Leading underscore
  "jwt_auth_"           # Trailing underscore
  "jwt__auth"           # Consecutive underscores
  "this_is_an_extremely_long_topic_name_that_exceeds_forty_characters"  # >40 chars
)

for invalid in "${invalid_formats[@]}"; do
  if ! validate_topic_name_format "$invalid"; then
    pass "Invalid format rejected (would fallback): '${invalid:-<empty>}'"
  else
    fail "Invalid format accepted: '${invalid:-<empty>}'" "Should trigger fallback"
  fi
done

# ==============================================================================
# Test 3: Minimum valid length boundary
# ==============================================================================
echo ""
echo "Test 3: Length boundary testing (5 char minimum)"

# Test 5 chars (minimum, should pass)
if validate_topic_name_format "abcde"; then
  pass "5 character name accepted (minimum length)"
else
  fail "5 character name rejected: abcde" "Minimum is 5 chars"
fi

# Test 6 chars (should pass)
if validate_topic_name_format "abcdef"; then
  pass "6 character name accepted"
else
  fail "6 character name rejected: abcdef" "Should be valid"
fi

# ==============================================================================
# Test 4: Maximum valid length boundary
# ==============================================================================
echo ""
echo "Test 4: Length boundary testing (40 char maximum)"

# Test 40 chars (maximum, should pass) - exactly 40 chars
forty_chars="aaaaaaaaaa_bbbbbbbbbb_cccccccccc_ddddddd"
if [ ${#forty_chars} -eq 40 ]; then
  if validate_topic_name_format "$forty_chars"; then
    pass "40 character name accepted (maximum length)"
  else
    fail "40 character name rejected" "Maximum is 40 chars"
  fi
else
  fail "Test setup error" "forty_chars is ${#forty_chars} chars, not 40"
fi

# Test 41 chars (should fail) - exactly 41 chars
forty_one_chars="aaaaaaaaaa_bbbbbbbbbb_cccccccccc_dddddddx"
if [ ${#forty_one_chars} -eq 41 ]; then
  if ! validate_topic_name_format "$forty_one_chars"; then
    pass "41 character name rejected (exceeds maximum)"
  else
    fail "41 character name accepted" "Should reject >40 chars"
  fi
else
  fail "Test setup error" "forty_one_chars is ${#forty_one_chars} chars, not 41"
fi

# ==============================================================================
# Test 5: Character set validation
# ==============================================================================
echo ""
echo "Test 5: Character set validation (a-z, 0-9, _ only)"

# Test valid character combinations
valid_chars=(
  "abc123"
  "test_name"
  "test_123_name"
  "abc_def_ghi_jkl"
  "name_with_numbers_123"
  "all_lowercase_letters"
  "mix_123_test_456_end"
)

for valid in "${valid_chars[@]}"; do
  if validate_topic_name_format "$valid"; then
    pass "Valid character set accepted: $valid"
  else
    fail "Valid character set rejected: $valid" "Should accept a-z, 0-9, _"
  fi
done

# Test invalid characters
invalid_chars=(
  "Test_Name"           # Uppercase
  "test-name"           # Hyphen
  "test.name"           # Dot
  "test name"           # Space
  "test@name"           # Special char
  "test!name"           # Special char
  "test#name"           # Special char
)

for invalid in "${invalid_chars[@]}"; do
  if ! validate_topic_name_format "$invalid"; then
    pass "Invalid character set rejected: $invalid"
  else
    fail "Invalid character set accepted: $invalid" "Should reject non a-z0-9_"
  fi
done

# ==============================================================================
# Test 6: Underscore edge cases
# ==============================================================================
echo ""
echo "Test 6: Underscore edge cases"

# Valid underscore usage
if validate_topic_name_format "a_b_c_d"; then
  pass "Single underscores between words accepted"
else
  fail "Single underscores rejected: a_b_c_d" "Should be valid"
fi

# Invalid: consecutive underscores
if ! validate_topic_name_format "a__b"; then
  pass "Consecutive underscores rejected: a__b"
else
  fail "Consecutive underscores accepted: a__b" "Should reject __"
fi

# Invalid: triple underscores
if ! validate_topic_name_format "a___b"; then
  pass "Triple underscores rejected: a___b"
else
  fail "Triple underscores accepted: a___b" "Should reject ___"
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
  echo "✓ All fallback tests passed"
  exit 0
else
  echo "✗ Some fallback tests failed"
  exit 1
fi
