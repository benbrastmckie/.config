#!/usr/bin/env bash
# Test suite for enhanced topic filename generation
# Tests: LLM enhanced topics, filename slug validation, three-tier validation fallback

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
  echo -e "${GREEN}✓ PASS${NC}: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  if [ -n "${2:-}" ]; then
    echo "  Expected: $2"
    echo "  Got: ${3:-<not provided>}"
  fi
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

skip() {
  echo -e "${YELLOW}⊘ SKIP${NC}: $1"
  SKIP_COUNT=$((SKIP_COUNT + 1))
}

info() {
  echo -e "${BLUE}ℹ INFO${NC}: $1"
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
source "$LIB_DIR/workflow/workflow-llm-classifier.sh"
source "$LIB_DIR/workflow/workflow-initialization.sh"

echo "========================================="
echo "Enhanced Topic Filename Generation Tests"
echo "========================================="
echo

# =============================================================================
# Section 1: Enhanced Topic Structure Validation
# =============================================================================
echo "Section 1: Enhanced Topic Structure Validation"
echo "-----------------------------------------------"

# Test 1.1: Valid enhanced topics with all required fields
info "Test 1.1: Valid enhanced topics - all fields present"
valid_topics_json=$(cat <<'EOF'
{
  "workflow_type": "research-and-plan",
  "confidence": 0.95,
  "research_complexity": 2,
  "research_topics": [
    {
      "short_name": "Implementation architecture",
      "detailed_description": "Analyze current implementation patterns, identify architectural decisions, evaluate scalability approaches, and document integration points with existing systems. This research will provide comprehensive understanding of system design.",
      "filename_slug": "implementation_architecture",
      "research_focus": "Key questions: How is the current system architected? What patterns are used? Areas to investigate: module structure, dependency management, state handling."
    },
    {
      "short_name": "Integration patterns",
      "detailed_description": "Research best practices for integrating new features with existing codebase, identify common integration patterns, and analyze potential conflicts or compatibility issues that may arise during implementation.",
      "filename_slug": "integration_patterns",
      "research_focus": "Key questions: How should new features integrate? What are the extension points? Areas to investigate: API design, event handling, plugin architecture."
    }
  ],
  "reasoning": "test"
}
EOF
)

# Parse and validate
if output=$(parse_llm_classifier_response "$valid_topics_json" "comprehensive" 2>&1); then
  # Check that subtopics array was created (backwards compatibility)
  subtopics_count=$(echo "$output" | jq -r '.subtopics | length')
  if [ "$subtopics_count" -eq 2 ]; then
    pass "Valid enhanced topics parsed successfully"
  else
    fail "Valid topics parsing" "2 subtopics" "got $subtopics_count"
  fi
else
  fail "Valid topics validation" "should succeed" "failed: $output"
fi

# Test 1.2: Missing detailed_description field
info "Test 1.2: Missing detailed_description - should fail validation"
missing_description_json=$(cat <<'EOF'
{
  "workflow_type": "research-only",
  "confidence": 0.95,
  "research_complexity": 1,
  "research_topics": [
    {
      "short_name": "Auth patterns",
      "filename_slug": "auth_patterns",
      "research_focus": "Key questions about auth"
    }
  ],
  "reasoning": "test"
}
EOF
)

if parse_llm_classifier_response "$missing_description_json" "comprehensive" 2>/dev/null; then
  fail "Missing detailed_description" "should fail validation" "succeeded"
else
  pass "Missing detailed_description correctly rejected"
fi

# Test 1.3: detailed_description too short (<50 chars)
info "Test 1.3: Short detailed_description - should fail validation"
short_description_json=$(cat <<'EOF'
{
  "workflow_type": "research-only",
  "confidence": 0.95,
  "research_complexity": 1,
  "research_topics": [
    {
      "short_name": "Auth patterns",
      "detailed_description": "Short description.",
      "filename_slug": "auth_patterns",
      "research_focus": "Key questions about auth"
    }
  ],
  "reasoning": "test"
}
EOF
)

if parse_llm_classifier_response "$short_description_json" "comprehensive" 2>/dev/null; then
  fail "Short detailed_description" "should fail validation" "succeeded"
else
  pass "Short detailed_description correctly rejected"
fi

# Test 1.4: detailed_description too long (>500 chars)
info "Test 1.4: Long detailed_description - should fail validation"
long_desc=$(printf 'a%.0s' {1..501})
long_description_json=$(cat <<EOF
{
  "workflow_type": "research-only",
  "confidence": 0.95,
  "research_complexity": 1,
  "research_topics": [
    {
      "short_name": "Auth patterns",
      "detailed_description": "$long_desc",
      "filename_slug": "auth_patterns",
      "research_focus": "Key questions about auth"
    }
  ],
  "reasoning": "test"
}
EOF
)

if parse_llm_classifier_response "$long_description_json" "comprehensive" 2>/dev/null; then
  fail "Long detailed_description" "should fail validation" "succeeded"
else
  pass "Long detailed_description correctly rejected"
fi

# Test 1.5: Missing research_focus field
info "Test 1.5: Missing research_focus - should fail validation"
missing_focus_json=$(cat <<'EOF'
{
  "workflow_type": "research-only",
  "confidence": 0.95,
  "research_complexity": 1,
  "research_topics": [
    {
      "short_name": "Auth patterns",
      "detailed_description": "Comprehensive analysis of authentication patterns including OAuth2, JWT, and session-based approaches with security considerations.",
      "filename_slug": "auth_patterns"
    }
  ],
  "reasoning": "test"
}
EOF
)

if parse_llm_classifier_response "$missing_focus_json" "comprehensive" 2>/dev/null; then
  fail "Missing research_focus" "should fail validation" "succeeded"
else
  pass "Missing research_focus correctly rejected"
fi

echo

# =============================================================================
# Section 2: Filename Slug Validation
# =============================================================================
echo "Section 2: Filename Slug Validation"
echo "------------------------------------"

# Test 2.1: Valid LLM slugs (lowercase alphanumeric + underscores)
info "Test 2.1: Valid LLM slugs - should be accepted"
valid_slug_json=$(cat <<'EOF'
{
  "workflow_type": "research-only",
  "confidence": 0.95,
  "research_complexity": 2,
  "research_topics": [
    {
      "short_name": "Implementation architecture",
      "detailed_description": "Comprehensive analysis of system architecture including module structure, dependency management, and design patterns used throughout the codebase.",
      "filename_slug": "implementation_architecture",
      "research_focus": "Key architectural decisions and patterns"
    },
    {
      "short_name": "Integration patterns",
      "detailed_description": "Research best practices for feature integration including API design, event handling, and plugin architecture approaches for extensibility.",
      "filename_slug": "integration_patterns_v2",
      "research_focus": "Integration approaches and extension points"
    }
  ],
  "reasoning": "test"
}
EOF
)

if parse_llm_classifier_response "$valid_slug_json" "comprehensive" 2>/dev/null; then
  pass "Valid LLM slugs accepted"
else
  fail "Valid slug validation" "should succeed" "failed"
fi

# Test 2.2: Invalid slugs - uppercase characters
info "Test 2.2: Invalid slugs (uppercase) - should be rejected"
uppercase_slug_json=$(cat <<'EOF'
{
  "workflow_type": "research-only",
  "confidence": 0.95,
  "research_complexity": 1,
  "research_topics": [
    {
      "short_name": "Auth patterns",
      "detailed_description": "Comprehensive analysis of authentication patterns including OAuth2, JWT, and session-based approaches with security considerations.",
      "filename_slug": "Auth_Patterns",
      "research_focus": "Authentication approaches and security"
    }
  ],
  "reasoning": "test"
}
EOF
)

if parse_llm_classifier_response "$uppercase_slug_json" "comprehensive" 2>/dev/null; then
  fail "Uppercase slug validation" "should be rejected" "accepted"
else
  pass "Uppercase slugs correctly rejected"
fi

# Test 2.3: Invalid slugs - special characters
info "Test 2.3: Invalid slugs (special chars) - should be rejected"
special_char_slug_json=$(cat <<'EOF'
{
  "workflow_type": "research-only",
  "confidence": 0.95,
  "research_complexity": 1,
  "research_topics": [
    {
      "short_name": "Auth patterns",
      "detailed_description": "Comprehensive analysis of authentication patterns including OAuth2, JWT, and session-based approaches with security considerations.",
      "filename_slug": "auth-patterns!",
      "research_focus": "Authentication approaches and security"
    }
  ],
  "reasoning": "test"
}
EOF
)

if parse_llm_classifier_response "$special_char_slug_json" "comprehensive" 2>/dev/null; then
  fail "Special char slug validation" "should be rejected" "accepted"
else
  pass "Special character slugs correctly rejected"
fi

# Test 2.4: Invalid slugs - too long (>50 chars)
info "Test 2.4: Invalid slugs (too long) - should be rejected"
long_slug=$(printf 'a%.0s' {1..51})
long_slug_json=$(cat <<EOF
{
  "workflow_type": "research-only",
  "confidence": 0.95,
  "research_complexity": 1,
  "research_topics": [
    {
      "short_name": "Auth patterns",
      "detailed_description": "Comprehensive analysis of authentication patterns including OAuth2, JWT, and session-based approaches with security considerations.",
      "filename_slug": "$long_slug",
      "research_focus": "Authentication approaches and security"
    }
  ],
  "reasoning": "test"
}
EOF
)

if parse_llm_classifier_response "$long_slug_json" "comprehensive" 2>/dev/null; then
  fail "Long slug validation" "should be rejected" "accepted"
else
  pass "Long slugs correctly rejected"
fi

# Test 2.5: Empty filename_slug
info "Test 2.5: Empty filename_slug - should be rejected"
empty_slug_json=$(cat <<'EOF'
{
  "workflow_type": "research-only",
  "confidence": 0.95,
  "research_complexity": 1,
  "research_topics": [
    {
      "short_name": "Auth patterns",
      "detailed_description": "Comprehensive analysis of authentication patterns including OAuth2, JWT, and session-based approaches with security considerations.",
      "filename_slug": "",
      "research_focus": "Authentication approaches and security"
    }
  ],
  "reasoning": "test"
}
EOF
)

if parse_llm_classifier_response "$empty_slug_json" "comprehensive" 2>/dev/null; then
  fail "Empty slug validation" "should be rejected" "accepted"
else
  pass "Empty slugs correctly rejected"
fi

echo

# =============================================================================
# Section 3: Backwards Compatibility (short_name extraction)
# =============================================================================
echo "Section 3: Backwards Compatibility"
echo "-----------------------------------"

# Test 3.1: RESEARCH_TOPICS_JSON contains short_name values
info "Test 3.1: RESEARCH_TOPICS_JSON populated with short_name values"
backwards_compat_json=$(cat <<'EOF'
{
  "workflow_type": "research-and-plan",
  "confidence": 0.95,
  "research_complexity": 2,
  "research_topics": [
    {
      "short_name": "Topic A",
      "detailed_description": "Comprehensive analysis of topic A including detailed investigation of patterns, approaches, and best practices.",
      "filename_slug": "topic_a",
      "research_focus": "Key questions about topic A"
    },
    {
      "short_name": "Topic B",
      "detailed_description": "Comprehensive analysis of topic B including detailed investigation of patterns, approaches, and best practices.",
      "filename_slug": "topic_b",
      "research_focus": "Key questions about topic B"
    }
  ],
  "reasoning": "test"
}
EOF
)

if output=$(parse_llm_classifier_response "$backwards_compat_json" "comprehensive" 2>&1); then
  # Check subtopics array contains the short_name values (backwards compatibility)
  subtopics_value=$(echo "$output" | jq -c '.subtopics')
  if [ "$subtopics_value" = '["Topic A","Topic B"]' ]; then
    pass "Subtopics array contains short_name values for backwards compatibility"
  else
    fail "Backwards compatibility" '["Topic A","Topic B"]' "$subtopics_value"
  fi
else
  fail "Backwards compatibility test" "should parse successfully" "failed"
fi

echo

# =============================================================================
# Section 4: Array Count Validation
# =============================================================================
echo "Section 4: Array Count Validation"
echo "----------------------------------"

# Test 4.1: research_topics count matches research_complexity
info "Test 4.1: Count match - research_topics.length == research_complexity"
count_match_json=$(cat <<'EOF'
{
  "workflow_type": "research-only",
  "confidence": 0.95,
  "research_complexity": 3,
  "research_topics": [
    {
      "short_name": "Topic 1",
      "detailed_description": "Comprehensive analysis of topic 1 including detailed investigation of patterns, approaches, and best practices.",
      "filename_slug": "topic_1",
      "research_focus": "Key questions about topic 1"
    },
    {
      "short_name": "Topic 2",
      "detailed_description": "Comprehensive analysis of topic 2 including detailed investigation of patterns, approaches, and best practices.",
      "filename_slug": "topic_2",
      "research_focus": "Key questions about topic 2"
    },
    {
      "short_name": "Topic 3",
      "detailed_description": "Comprehensive analysis of topic 3 including detailed investigation of patterns, approaches, and best practices.",
      "filename_slug": "topic_3",
      "research_focus": "Key questions about topic 3"
    }
  ],
  "reasoning": "test"
}
EOF
)

if parse_llm_classifier_response "$count_match_json" "comprehensive" 2>/dev/null; then
  pass "Count matching validation passed"
else
  fail "Count match validation" "should succeed" "failed"
fi

# Test 4.2: research_topics count mismatch (too few)
info "Test 4.2: Count mismatch - too few topics"
count_mismatch_few_json=$(cat <<'EOF'
{
  "workflow_type": "research-only",
  "confidence": 0.95,
  "research_complexity": 3,
  "research_topics": [
    {
      "short_name": "Topic 1",
      "detailed_description": "Comprehensive analysis of topic 1 including detailed investigation of patterns, approaches, and best practices.",
      "filename_slug": "topic_1",
      "research_focus": "Key questions about topic 1"
    },
    {
      "short_name": "Topic 2",
      "detailed_description": "Comprehensive analysis of topic 2 including detailed investigation of patterns, approaches, and best practices.",
      "filename_slug": "topic_2",
      "research_focus": "Key questions about topic 2"
    }
  ],
  "reasoning": "test"
}
EOF
)

if parse_llm_classifier_response "$count_mismatch_few_json" "comprehensive" 2>/dev/null; then
  fail "Count mismatch (too few)" "should be rejected" "accepted"
else
  pass "Count mismatch (too few) correctly rejected"
fi

# Test 4.3: research_topics count mismatch (too many)
info "Test 4.3: Count mismatch - too many topics"
count_mismatch_many_json=$(cat <<'EOF'
{
  "workflow_type": "research-only",
  "confidence": 0.95,
  "research_complexity": 1,
  "research_topics": [
    {
      "short_name": "Topic 1",
      "detailed_description": "Comprehensive analysis of topic 1 including detailed investigation of patterns, approaches, and best practices.",
      "filename_slug": "topic_1",
      "research_focus": "Key questions about topic 1"
    },
    {
      "short_name": "Topic 2",
      "detailed_description": "Comprehensive analysis of topic 2 including detailed investigation of patterns, approaches, and best practices.",
      "filename_slug": "topic_2",
      "research_focus": "Key questions about topic 2"
    }
  ],
  "reasoning": "test"
}
EOF
)

if parse_llm_classifier_response "$count_mismatch_many_json" "comprehensive" 2>/dev/null; then
  fail "Count mismatch (too many)" "should be rejected" "accepted"
else
  pass "Count mismatch (too many) correctly rejected"
fi

echo

# =============================================================================
# Test Summary
# =============================================================================
echo "========================================="
echo "Test Summary"
echo "========================================="
echo "✓ PASS: $PASS_COUNT"
echo "✗ FAIL: $FAIL_COUNT"
echo "⊘ SKIP: $SKIP_COUNT"
echo "TOTAL: $((PASS_COUNT + FAIL_COUNT + SKIP_COUNT))"
echo

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo -e "${GREEN}✓ All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  exit 1
fi
