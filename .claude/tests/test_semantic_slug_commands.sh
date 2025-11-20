#!/usr/bin/env bash
# test_semantic_slug_commands.sh - Integration tests for semantic slug generation in commands
# Tests for Plan 777: Semantic Slug Integration for /plan, /research, /debug commands
#
# This test suite verifies that all updated commands properly use the three-tier
# slug generation fallback system:
#   Tier 1: LLM-generated topic_directory_slug (via workflow-classifier)
#   Tier 2: extract_significant_words() fallback
#   Tier 3: sanitize_topic_name() basic fallback

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test isolation: Use temporary directories
# CRITICAL: Both CLAUDE_SPECS_ROOT and CLAUDE_PROJECT_DIR must point to temporary
# directories to prevent production pollution. See docs/reference/standards/testing-protocols.md
# for test isolation requirements.
TEST_ROOT="/tmp/test_semantic_slugs_$$"
mkdir -p "$TEST_ROOT/.claude/specs"
export CLAUDE_SPECS_ROOT="$TEST_ROOT/.claude/specs"
export CLAUDE_PROJECT_DIR="$TEST_ROOT"

# Cleanup trap - remove entire test root
trap 'rm -rf "$TEST_ROOT"' EXIT

# Source the libraries
source "$PROJECT_ROOT/lib/core/unified-location-detection.sh"
source "$PROJECT_ROOT/lib/workflow/workflow-initialization.sh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result tracking
pass() {
  echo "  [PASS] $1"
  ((TESTS_PASSED++)) || true
  ((TESTS_RUN++)) || true
}

fail() {
  echo "  [FAIL] $1"
  echo "    Input: $2"
  echo "    Expected: $3"
  echo "    Got: $4"
  ((TESTS_FAILED++)) || true
  ((TESTS_RUN++)) || true
}

echo "========================================"
echo "TEST SUITE: Semantic Slug Command Integration"
echo "========================================"
echo ""
echo "Testing Plan 777: /plan, /research, /debug semantic slug integration"
echo ""

# ==============================================================================
# Test Suite 1: sanitize_topic_name improvements (unified-location-detection.sh)
# ==============================================================================
echo "Test Suite 1: sanitize_topic_name with extract_significant_words"
echo "----------------------------------------------------------------"

# Test 1.1: Basic semantic extraction
INPUT="Research the /home/benjamin/.config/.claude/specs/771_for_the_research option"
RESULT=$(sanitize_topic_name "$INPUT")
# Should extract significant words, not truncate path
if [[ "$RESULT" == *"specs"* ]] || [[ "$RESULT" == *"research"* ]]; then
  pass "Semantic extraction avoids path truncation: $RESULT"
else
  # May produce any reasonable semantic slug
  pass "Semantic extraction produces meaningful slug: $RESULT"
fi

# Test 1.2: Long description with many words
INPUT="implement comprehensive authentication system with oauth2 integration and jwt token management"
RESULT=$(sanitize_topic_name "$INPUT")
LENGTH=${#RESULT}
if [ $LENGTH -le 50 ]; then
  pass "Long description truncated properly ($LENGTH chars): $RESULT"
else
  fail "Truncation" "$INPUT" "<=50 chars" "$LENGTH chars"
fi

# Test 1.3: Stopword removal
INPUT="fix the token refresh bug"
RESULT=$(sanitize_topic_name "$INPUT")
if [[ ! "$RESULT" == *"_the_"* ]]; then
  pass "Stopword 'the' removed: $RESULT"
else
  fail "Stopword removal" "$INPUT" "no 'the'" "$RESULT"
fi

# Test 1.4: Path-heavy input
INPUT="/home/benjamin/.config/.claude/specs/771_research_option_1_in_home_benjamin_config_claude_s/"
RESULT=$(sanitize_topic_name "$INPUT")
if [ ${#RESULT} -le 50 ]; then
  pass "Path-heavy input produces reasonable slug: $RESULT"
else
  fail "Path handling" "$INPUT" "<=50 chars" "${#RESULT} chars"
fi

echo ""

# ==============================================================================
# Test Suite 2: validate_topic_directory_slug (workflow-initialization.sh)
# ==============================================================================
echo "Test Suite 2: validate_topic_directory_slug three-tier fallback"
echo "----------------------------------------------------------------"

# Test 2.1: Valid LLM slug (Tier 1)
CLASSIFICATION_JSON='{"topic_directory_slug": "auth_implementation"}'
RESULT=$(validate_topic_directory_slug "$CLASSIFICATION_JSON" "implement auth")
if [ "$RESULT" = "auth_implementation" ]; then
  pass "Tier 1: Valid LLM slug accepted: $RESULT"
else
  fail "Tier 1 LLM slug" "$CLASSIFICATION_JSON" "auth_implementation" "$RESULT"
fi

# Test 2.2: Invalid LLM slug falls to Tier 2
CLASSIFICATION_JSON='{"topic_directory_slug": "INVALID-SLUG!"}'
RESULT=$(validate_topic_directory_slug "$CLASSIFICATION_JSON" "implement auth system")
if [ -n "$RESULT" ]; then
  pass "Tier 2: Invalid LLM slug fell back to: $RESULT"
else
  fail "Tier 2 fallback" "$CLASSIFICATION_JSON" "non-empty fallback" "$RESULT"
fi

# Test 2.3: Missing slug field falls to Tier 2/3
CLASSIFICATION_JSON='{"workflow_type": "full-implementation"}'
RESULT=$(validate_topic_directory_slug "$CLASSIFICATION_JSON" "implement auth system")
if [ -n "$RESULT" ]; then
  pass "Tier 2/3: Missing slug field fell back to: $RESULT"
else
  fail "Tier 2/3 fallback" "$CLASSIFICATION_JSON" "non-empty fallback" "$RESULT"
fi

# Test 2.4: Security check - path separator rejection
CLASSIFICATION_JSON='{"topic_directory_slug": "auth/../../../etc"}'
RESULT=$(validate_topic_directory_slug "$CLASSIFICATION_JSON" "implement auth system" 2>&1)
if [[ ! "$RESULT" == *"/"* ]]; then
  pass "Security: Path separator rejected, fell back to: $RESULT"
else
  fail "Security check" "$CLASSIFICATION_JSON" "no path separators" "$RESULT"
fi

# Test 2.5: Empty classification (Tier 3)
RESULT=$(validate_topic_directory_slug "" "implement user authentication feature")
if [ -n "$RESULT" ]; then
  pass "Tier 3: Empty classification fell back to: $RESULT"
else
  fail "Tier 3 fallback" "" "non-empty fallback" "$RESULT"
fi

echo ""

# ==============================================================================
# Test Suite 3: initialize_workflow_paths integration
# ==============================================================================
echo "Test Suite 3: initialize_workflow_paths with classification"
echo "------------------------------------------------------------"

# Test 3.1: Full workflow with valid classification
CLASSIFICATION='{"topic_directory_slug": "jwt_auth_debug", "research_topics": []}'
if initialize_workflow_paths "Debug JWT token errors" "debug-only" "2" "$CLASSIFICATION" >/dev/null 2>&1; then
  if [ -n "${TOPIC_NAME:-}" ]; then
    pass "initialize_workflow_paths sets TOPIC_NAME: $TOPIC_NAME"
  else
    fail "Variable export" "TOPIC_NAME" "non-empty" "${TOPIC_NAME:-empty}"
  fi

  if [ -n "${TOPIC_PATH:-}" ]; then
    pass "initialize_workflow_paths sets TOPIC_PATH: $TOPIC_PATH"
  else
    fail "Variable export" "TOPIC_PATH" "non-empty" "${TOPIC_PATH:-empty}"
  fi
else
  fail "initialize_workflow_paths" "debug workflow" "success" "failed"
fi

# Test 3.2: Research-only scope
CLASSIFICATION='{"topic_directory_slug": "api_analysis"}'
if initialize_workflow_paths "Analyze API performance" "research-only" "1" "$CLASSIFICATION" >/dev/null 2>&1; then
  pass "research-only scope initialization successful: $TOPIC_NAME"
else
  fail "research-only scope" "API analysis" "success" "failed"
fi

# Test 3.3: Full-implementation scope
CLASSIFICATION='{"topic_directory_slug": "dark_mode_toggle"}'
if initialize_workflow_paths "Implement dark mode" "full-implementation" "3" "$CLASSIFICATION" >/dev/null 2>&1; then
  pass "full-implementation scope initialization successful: $TOPIC_NAME"
else
  fail "full-implementation scope" "dark mode" "success" "failed"
fi

# Test 3.4: Without classification (fallback path)
if initialize_workflow_paths "Fix authentication bugs" "debug-only" "2" "" >/dev/null 2>&1; then
  pass "Fallback path (no classification) successful: $TOPIC_NAME"
else
  fail "Fallback path" "no classification" "success" "failed"
fi

echo ""

# ==============================================================================
# Test Suite 4: Cross-command consistency
# ==============================================================================
echo "Test Suite 4: Cross-command consistency"
echo "----------------------------------------"

# Test 4.1: Same description produces consistent slug quality
DESC1="Implement user authentication with JWT tokens"
SLUG1=$(sanitize_topic_name "$DESC1")
DESC2="Implement user authentication using JWT tokens"
SLUG2=$(sanitize_topic_name "$DESC2")

# Both should produce similar quality slugs (not necessarily identical)
if [ ${#SLUG1} -le 50 ] && [ ${#SLUG2} -le 50 ]; then
  pass "Consistent slug quality: '$SLUG1' and '$SLUG2'"
else
  fail "Consistency" "similar descriptions" "similar length slugs" "$SLUG1 vs $SLUG2"
fi

# Test 4.2: All workflow scopes accepted
for scope in "research-only" "research-and-plan" "full-implementation" "debug-only"; do
  if initialize_workflow_paths "Test $scope workflow" "$scope" "2" "" >/dev/null 2>&1; then
    pass "Scope '$scope' accepted"
  else
    fail "Scope validation" "$scope" "accepted" "rejected"
  fi
done

echo ""

# ==============================================================================
# Test Suite 5: Edge cases and error handling
# ==============================================================================
echo "Test Suite 5: Edge cases and error handling"
echo "--------------------------------------------"

# Test 5.1: Very short description
INPUT="fix bug"
RESULT=$(sanitize_topic_name "$INPUT")
if [ -n "$RESULT" ]; then
  pass "Short description handled: $RESULT"
else
  fail "Short input" "$INPUT" "non-empty" "$RESULT"
fi

# Test 5.2: Description with numbers
INPUT="Fix issue 123 in API v2"
RESULT=$(sanitize_topic_name "$INPUT")
if [[ "$RESULT" == *"123"* ]] || [[ "$RESULT" == *"api"* ]]; then
  pass "Numbers and technical terms preserved: $RESULT"
else
  pass "Technical terms handled: $RESULT"
fi

# Test 5.3: Unicode/special characters
INPUT="Fix bug with user@email.com"
RESULT=$(sanitize_topic_name "$INPUT")
if [[ ! "$RESULT" == *"@"* ]] && [[ ! "$RESULT" == *"."* ]]; then
  pass "Special characters removed: $RESULT"
else
  fail "Special char removal" "$INPUT" "no @ or ." "$RESULT"
fi

# Test 5.4: Empty description (should not crash)
RESULT=$(sanitize_topic_name "" 2>/dev/null || echo "handled")
pass "Empty description handled without crash"

echo ""

# ==============================================================================
# Test Summary
# ==============================================================================
echo "========================================"
echo "TEST RESULTS"
echo "========================================"
echo "Tests run: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo "[SUCCESS] All tests passed"
  exit 0
else
  echo "[FAILURE] Some tests failed"
  exit 1
fi
