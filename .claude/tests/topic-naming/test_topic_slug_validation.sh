#!/usr/bin/env bash
# Test suite for topic directory slug validation (Spec 771)
# Tests: extract_significant_words(), validate_topic_directory_slug(), three-tier fallback

set -euo pipefail

# Test framework
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

pass() {
  echo -e "${GREEN}PASS${NC}: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo -e "${RED}FAIL${NC}: $1"
  if [ -n "${2:-}" ]; then
    echo "  Expected: $2"
    echo "  Got: ${3:-<not provided>}"
  fi
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

skip() {
  echo -e "${YELLOW}SKIP${NC}: $1"
  SKIP_COUNT=$((SKIP_COUNT + 1))
}

info() {
  echo -e "${BLUE}INFO${NC}: $1"
}

# Find lib directory
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

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
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Source libraries
source "$LIB_DIR/plan/topic-utils.sh"
source "$LIB_DIR/workflow/workflow-initialization.sh"

echo "========================================="
echo "Topic Directory Slug Validation Tests"
echo "========================================="
echo

# =============================================================================
# Section 1: extract_significant_words() Tests
# =============================================================================
echo "Section 1: extract_significant_words() Tests"
echo "----------------------------------------------"

# Test 1.1: Basic extraction
info "Test 1.1: Basic significant word extraction"
result=$(extract_significant_words "I see that in the project directories the names are odd")
expected="see_project_directories_names"
if [[ "$result" == "$expected" ]]; then
  pass "Basic extraction"
else
  fail "Basic extraction" "$expected" "$result"
fi

# Test 1.2: Long verbose description
info "Test 1.2: Long verbose description"
result=$(extract_significant_words "I would like you to carefully research and thoroughly analyze the existing authentication patterns")
# Should extract first 4 significant words
if echo "$result" | grep -Eq '^[a-z0-9_]{1,40}$'; then
  pass "Long verbose description - valid format"
else
  fail "Long verbose description" "valid slug format" "$result"
fi

# Test 1.3: Path-heavy description
info "Test 1.3: Path-heavy description (ignores paths)"
result=$(extract_significant_words "Research the /home/user/.config/nvim/ directory structure")
if echo "$result" | grep -qv '/'; then
  pass "Path-heavy description - no path chars"
else
  fail "Path-heavy description" "no path separators" "$result"
fi

# Test 1.4: Single word input
info "Test 1.4: Single word input"
result=$(extract_significant_words "authentication")
if [[ "$result" == "authentication" ]]; then
  pass "Single word input"
else
  fail "Single word input" "authentication" "$result"
fi

# Test 1.5: Stopword-only input
info "Test 1.5: Stopword-only input"
result=$(extract_significant_words "the a an and or but to for")
if [[ "$result" == "topic" ]]; then
  pass "Stopword-only input defaults to 'topic'"
else
  fail "Stopword-only input" "topic" "$result"
fi

# Test 1.6: Special characters
info "Test 1.6: Special characters stripped"
result=$(extract_significant_words 'Research! the @patterns# and $test% cases')
if echo "$result" | grep -Eq '^[a-z0-9_]+$'; then
  pass "Special characters stripped"
else
  fail "Special characters" "alphanumeric_underscores" "$result"
fi

# Test 1.7: Length limit (40 chars)
info "Test 1.7: Length limit enforced"
result=$(extract_significant_words "investigate thoroughly comprehensive authentication authorization session management token validation")
if [ ${#result} -le 40 ]; then
  pass "Length limit (${#result} chars)"
else
  fail "Length limit" "<=40 chars" "${#result} chars"
fi

echo

# =============================================================================
# Section 2: validate_topic_directory_slug() Three-Tier Fallback Tests
# =============================================================================
echo "Section 2: validate_topic_directory_slug() Three-Tier Fallback Tests"
echo "--------------------------------------------------------------------"

# Test 2.1: Tier 1 - Valid LLM slug passthrough
info "Test 2.1: Tier 1 - Valid LLM slug passthrough"
json='{"topic_directory_slug": "auth_patterns_implementation"}'
result=$(validate_topic_directory_slug "$json" "test workflow")
if [[ "$result" == "auth_patterns_implementation" ]]; then
  pass "Tier 1 - Valid LLM slug passthrough"
else
  fail "Tier 1 - Valid LLM slug" "auth_patterns_implementation" "$result"
fi

# Test 2.2: Tier 2 - Invalid LLM slug triggers extract fallback
info "Test 2.2: Tier 2 - Invalid LLM slug triggers extract fallback"
json='{"topic_directory_slug": "invalid-with-hyphens"}'
result=$(validate_topic_directory_slug "$json" "research authentication patterns" 2>&1)
if echo "$result" | grep -qv '-'; then
  pass "Tier 2 - Extract fallback (no hyphens)"
else
  fail "Tier 2 - Extract fallback" "no hyphens" "$result"
fi

# Test 2.3: Tier 3 - Empty classification triggers sanitize fallback
info "Test 2.3: Tier 3 - Empty classification triggers sanitize fallback"
result=$(validate_topic_directory_slug "" "research authentication patterns")
if [ -n "$result" ]; then
  pass "Tier 3 - Sanitize fallback"
else
  fail "Tier 3 - Sanitize fallback" "non-empty result" "$result"
fi

# Test 2.4: Security check - Path separator injection blocked
info "Test 2.4: Security check - Path separator injection blocked"
json='{"topic_directory_slug": "auth/../etc/passwd"}'
result=$(validate_topic_directory_slug "$json" "test workflow" 2>&1)
# Should reject and fall back
if echo "$result" | grep -qv '/'; then
  pass "Security - Path separator blocked"
else
  fail "Security - Path separator" "no path separators" "$result"
fi

# Test 2.5: Length limit enforced (40 chars)
info "Test 2.5: Length limit enforced"
json='{"topic_directory_slug": "this_is_a_very_long_slug_that_exceeds_forty_characters"}'
result=$(validate_topic_directory_slug "$json" "test" 2>/dev/null)
# Should reject invalid slug and fall back
if [ ${#result} -le 40 ]; then
  pass "Length limit enforced (${#result} chars)"
else
  fail "Length limit" "<=40 chars" "${#result} chars"
fi

# Test 2.6: Missing topic_directory_slug field
info "Test 2.6: Missing topic_directory_slug field"
json='{"workflow_type": "research-only"}'
result=$(validate_topic_directory_slug "$json" "test workflow description")
if [ -n "$result" ]; then
  pass "Missing field - fallback works"
else
  fail "Missing field" "non-empty fallback" "$result"
fi

# Test 2.7: Empty topic_directory_slug value
info "Test 2.7: Empty topic_directory_slug value"
json='{"topic_directory_slug": ""}'
result=$(validate_topic_directory_slug "$json" "research patterns")
if [ -n "$result" ]; then
  pass "Empty value - fallback works"
else
  fail "Empty value" "non-empty fallback" "$result"
fi

echo

# =============================================================================
# Section 3: Edge Case Tests from Haiku Integration Design
# =============================================================================
echo "Section 3: Edge Case Tests"
echo "--------------------------"

# Test 3.1: Verbose description
info "Test 3.1: Verbose description"
json='{"topic_directory_slug": "jwt_token_validation_microservices"}'
result=$(validate_topic_directory_slug "$json" "I would like you to carefully research JWT tokens")
if [[ "$result" == "jwt_token_validation_microservices" ]]; then
  pass "Verbose description"
else
  fail "Verbose description" "jwt_token_validation_microservices" "$result"
fi

# Test 3.2: Multiple topics unified
info "Test 3.2: Multiple topics unified"
json='{"topic_directory_slug": "user_portal_auth_system"}'
result=$(validate_topic_directory_slug "$json" "authentication, authorization, sessions")
if [[ "$result" == "user_portal_auth_system" ]]; then
  pass "Multiple topics unified"
else
  fail "Multiple topics" "user_portal_auth_system" "$result"
fi

# Test 3.3: Action-focused description
info "Test 3.3: Action-focused description"
json='{"topic_directory_slug": "login_password_reset_bug"}'
result=$(validate_topic_directory_slug "$json" "Fix the login bug")
if [[ "$result" == "login_password_reset_bug" ]]; then
  pass "Action-focused description"
else
  fail "Action-focused" "login_password_reset_bug" "$result"
fi

# Test 3.4: Numbers allowed in slug
info "Test 3.4: Numbers allowed in slug"
json='{"topic_directory_slug": "oauth2_auth_flow"}'
result=$(validate_topic_directory_slug "$json" "OAuth2 auth")
if [[ "$result" == "oauth2_auth_flow" ]]; then
  pass "Numbers in slug"
else
  fail "Numbers in slug" "oauth2_auth_flow" "$result"
fi

echo

# =============================================================================
# Section 4: Format Validation Tests
# =============================================================================
echo "Section 4: Format Validation Tests"
echo "-----------------------------------"

# Test 4.1: Uppercase rejected
info "Test 4.1: Uppercase rejected"
json='{"topic_directory_slug": "Auth_Patterns"}'
result=$(validate_topic_directory_slug "$json" "test" 2>&1)
if echo "$result" | grep -Eq '^[a-z0-9_]+$'; then
  pass "Uppercase rejected - lowercase returned"
else
  fail "Uppercase rejected" "lowercase only" "$result"
fi

# Test 4.2: Spaces rejected
info "Test 4.2: Spaces rejected"
json='{"topic_directory_slug": "auth patterns"}'
result=$(validate_topic_directory_slug "$json" "test" 2>&1)
if echo "$result" | grep -qv ' '; then
  pass "Spaces rejected"
else
  fail "Spaces rejected" "no spaces" "$result"
fi

# Test 4.3: Valid regex match
info "Test 4.3: Valid regex match"
json='{"topic_directory_slug": "valid_slug_123"}'
result=$(validate_topic_directory_slug "$json" "test")
if [[ "$result" == "valid_slug_123" ]]; then
  pass "Valid regex match"
else
  fail "Valid regex" "valid_slug_123" "$result"
fi

echo

# =============================================================================
# Summary
# =============================================================================
echo "========================================="
echo "Test Summary"
echo "========================================="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"
echo "Skipped: $SKIP_COUNT"
echo

if [ $FAIL_COUNT -gt 0 ]; then
  echo -e "${RED}Some tests failed!${NC}"
  exit 1
else
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
fi
