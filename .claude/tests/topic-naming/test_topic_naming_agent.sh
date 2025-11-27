#!/usr/bin/env bash
# test_topic_naming_agent.sh - Unit tests for topic-naming-agent integration
# Tests agent invocation, completion signal parsing, and validation

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
echo "TEST SUITE: Topic Naming Agent Integration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ==============================================================================
# Test 1: validate_topic_name_format - Valid names
# ==============================================================================
echo "Test 1: Validate topic name format - Valid names"

# Test valid names from agent specification examples
valid_names=(
  "jwt_token_expiration_fix"
  "oauth_auth_refresh_tokens"
  "state_machine_refactor"
  "auth_patterns_migration"
  "optimize_response_bash_blocks"
)

for name in "${valid_names[@]}"; do
  if validate_topic_name_format "$name"; then
    pass "Valid name accepted: $name"
  else
    fail "Valid name rejected: $name" "Should pass validation"
  fi
done

# ==============================================================================
# Test 2: validate_topic_name_format - Invalid names
# ==============================================================================
echo ""
echo "Test 2: Validate topic name format - Invalid names"

# Test invalid formats
if ! validate_topic_name_format "Invalid-Name!"; then
  pass "Rejected name with hyphens and special chars"
else
  fail "Accepted invalid name: Invalid-Name!" "Should reject"
fi

if ! validate_topic_name_format "JWT_Auth_Fix"; then
  pass "Rejected name with uppercase"
else
  fail "Accepted invalid name: JWT_Auth_Fix" "Should reject uppercase"
fi

if ! validate_topic_name_format "jwt"; then
  pass "Rejected name too short (3 chars, min 5)"
else
  fail "Accepted invalid name: jwt" "Should reject <5 chars"
fi

if ! validate_topic_name_format "implement_comprehensive_jwt_authentication_with_refresh_tokens"; then
  pass "Rejected name too long (62 chars, max 40)"
else
  fail "Accepted invalid name (62 chars)" "Should reject >40 chars"
fi

if ! validate_topic_name_format "jwt__auth__fix"; then
  pass "Rejected name with consecutive underscores"
else
  fail "Accepted invalid name: jwt__auth__fix" "Should reject consecutive underscores"
fi

if ! validate_topic_name_format "_jwt_auth_fix"; then
  pass "Rejected name with leading underscore"
else
  fail "Accepted invalid name: _jwt_auth_fix" "Should reject leading underscore"
fi

if ! validate_topic_name_format "jwt_auth_fix_"; then
  pass "Rejected name with trailing underscore"
else
  fail "Accepted invalid name: jwt_auth_fix_" "Should reject trailing underscore"
fi

# ==============================================================================
# Test 3: Agent transformation examples validation
# ==============================================================================
echo ""
echo "Test 3: Agent transformation examples from specification"

# Test that all example outputs from agent specification are valid
example_outputs=(
  "jwt_token_expiration_fix"
  "oauth_auth_refresh_tokens"
  "state_machine_refactor"
  "auth_patterns_migration"
  "optimize_response_bash_blocks"
  "phase_checkbox_update_debug"
  "opentelemetry_tracing_integration"
  "user_session_redis"
  "api_gateway_error_handling"
  "database_connection_logging"
)

for output in "${example_outputs[@]}"; do
  if validate_topic_name_format "$output"; then
    pass "Example output valid: $output"
  else
    fail "Example output invalid: $output" "All agent examples should be valid"
  fi
done

# ==============================================================================
# Test 4: Edge case names from agent specification
# ==============================================================================
echo ""
echo "Test 4: Edge case handling from agent specification"

# Edge case: Very long prompt should produce concise name
edge_case_names=(
  "oauth_jwt_auth_system"           # Long prompt condensed
  "topic_utils_sanitize_fix"        # File path ignored
  "improve_performance"             # Vague description
  "haiku_topic_naming_refactor"     # Technical jargon
  "auth_session_fixes_logging"      # Multiple actions
  "jwt_authentication"              # Artifact reference ignored
)

for name in "${edge_case_names[@]}"; do
  if validate_topic_name_format "$name"; then
    pass "Edge case valid: $name"
  else
    fail "Edge case invalid: $name" "Should handle edge case properly"
  fi
done

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
  echo "✓ All agent unit tests passed"
  exit 0
else
  echo "✗ Some agent unit tests failed"
  exit 1
fi
