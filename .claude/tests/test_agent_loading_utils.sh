#!/usr/bin/env bash
# Test agent-loading-utils.sh

set -euo pipefail

# Test framework
PASS_COUNT=0
FAIL_COUNT=0

pass() {
  echo "✓ PASS: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo "✗ FAIL: $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

# Test environment
TEST_DIR=$(mktemp -d -t agent_loading_tests_XXXXXX)
export CLAUDE_PROJECT_DIR="$TEST_DIR"

cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Setup test directories
mkdir -p "$TEST_DIR/.claude/agents"
mkdir -p "$TEST_DIR/.claude/lib"

# Copy actual base-utils.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTUAL_PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cp "$ACTUAL_PROJECT_DIR/lib/base-utils.sh" "$TEST_DIR/.claude/lib/"

# Copy agent-loading-utils.sh to test environment
cp "$ACTUAL_PROJECT_DIR/lib/agent-loading-utils.sh" "$TEST_DIR/.claude/lib/"

# Source the utility
source "$TEST_DIR/.claude/lib/agent-loading-utils.sh"

echo "════════════════════════════════════════════════"
echo "Agent Loading Utilities Test Suite"
echo "════════════════════════════════════════════════"

# ============================================================================
# Test 1: load_agent_behavioral_prompt - with frontmatter
# ============================================================================

echo ""
echo "Test 1: load_agent_behavioral_prompt (with frontmatter)"

cat > "$TEST_DIR/.claude/agents/test-agent.md" <<'EOF'
---
name: test-agent
version: 1.0
---

# Test Agent Behavioral Guidelines

You are a test agent. Follow these instructions:
1. Do something
2. Do something else
EOF

RESULT=$(load_agent_behavioral_prompt "test-agent")

if echo "$RESULT" | grep -q "# Test Agent Behavioral Guidelines"; then
  if echo "$RESULT" | grep -q "name: test-agent"; then
    fail "Frontmatter not stripped (still contains 'name: test-agent')"
  else
    pass "Frontmatter stripped correctly"
  fi
else
  fail "Behavioral content missing"
fi

# ============================================================================
# Test 2: load_agent_behavioral_prompt - without frontmatter
# ============================================================================

echo ""
echo "Test 2: load_agent_behavioral_prompt (without frontmatter)"

cat > "$TEST_DIR/.claude/agents/simple-agent.md" <<'EOF'
# Simple Agent

No frontmatter here, just content.
EOF

RESULT=$(load_agent_behavioral_prompt "simple-agent")

if echo "$RESULT" | grep -q "# Simple Agent"; then
  pass "Agent without frontmatter loaded correctly"
else
  fail "Agent content missing"
fi

# ============================================================================
# Test 3: load_agent_behavioral_prompt - non-existent agent
# ============================================================================

echo ""
echo "Test 3: load_agent_behavioral_prompt (non-existent agent)"

if load_agent_behavioral_prompt "nonexistent" 2>/dev/null; then
  fail "Should have failed for non-existent agent"
else
  pass "Error handling for non-existent agent"
fi

# ============================================================================
# Test 4: get_next_artifact_number - empty directory
# ============================================================================

echo ""
echo "Test 4: get_next_artifact_number (empty directory)"

mkdir -p "$TEST_DIR/specs/test/reports"

NEXT_NUM=$(get_next_artifact_number "$TEST_DIR/specs/test/reports")

if [ "$NEXT_NUM" = "001" ]; then
  pass "Empty directory returns 001"
else
  fail "Expected 001, got $NEXT_NUM"
fi

# ============================================================================
# Test 5: get_next_artifact_number - with existing files
# ============================================================================

echo ""
echo "Test 5: get_next_artifact_number (with existing files)"

touch "$TEST_DIR/specs/test/reports/001_first.md"
touch "$TEST_DIR/specs/test/reports/002_second.md"
touch "$TEST_DIR/specs/test/reports/005_fifth.md"  # Gap in numbering

NEXT_NUM=$(get_next_artifact_number "$TEST_DIR/specs/test/reports")

if [ "$NEXT_NUM" = "006" ]; then
  pass "Next number after max (005) is 006"
else
  fail "Expected 006, got $NEXT_NUM"
fi

# ============================================================================
# Test 6: get_next_artifact_number - non-existent directory
# ============================================================================

echo ""
echo "Test 6: get_next_artifact_number (non-existent directory)"

NEXT_NUM=$(get_next_artifact_number "$TEST_DIR/specs/nonexistent/reports")

if [ "$NEXT_NUM" = "001" ]; then
  pass "Non-existent directory returns 001"
else
  fail "Expected 001, got $NEXT_NUM"
fi

# ============================================================================
# Test 7: verify_artifact_or_recover - exact path match
# ============================================================================

echo ""
echo "Test 7: verify_artifact_or_recover (exact path match)"

mkdir -p "$TEST_DIR/specs/auth/reports"
touch "$TEST_DIR/specs/auth/reports/042_authentication.md"

RESULT=$(verify_artifact_or_recover \
  "$TEST_DIR/specs/auth/reports/042_authentication.md" \
  "authentication")

if [ "$RESULT" = "$TEST_DIR/specs/auth/reports/042_authentication.md" ]; then
  pass "Exact path match verified"
else
  fail "Expected exact path, got $RESULT"
fi

# ============================================================================
# Test 8: verify_artifact_or_recover - recovery with path mismatch
# ============================================================================

echo ""
echo "Test 8: verify_artifact_or_recover (recovery with path mismatch)"

# Agent created file at different number
touch "$TEST_DIR/specs/auth/reports/043_auth_security.md"

RESULT=$(verify_artifact_or_recover \
  "$TEST_DIR/specs/auth/reports/042_security.md" \
  "security" 2>/dev/null)

if echo "$RESULT" | grep -q "043_auth_security.md"; then
  pass "Recovery found artifact with matching slug"
else
  fail "Recovery failed, expected file with 'security' in name"
fi

# ============================================================================
# Test 9: verify_artifact_or_recover - recovery failure
# ============================================================================

echo ""
echo "Test 9: verify_artifact_or_recover (recovery failure)"

if verify_artifact_or_recover \
  "$TEST_DIR/specs/auth/reports/999_nonexistent.md" \
  "nonexistent" 2>/dev/null; then
  fail "Should have failed when artifact not found"
else
  pass "Error handling when artifact not found"
fi

# ============================================================================
# Test 10: Integration - complete workflow
# ============================================================================

echo ""
echo "Test 10: Integration (complete workflow)"

# Create agent behavioral file
cat > "$TEST_DIR/.claude/agents/plan-architect.md" <<'EOF'
---
agent: plan-architect
role: planning
---

# Plan Architect Agent

Create implementation plans at specified paths.
EOF

# Load behavioral prompt
AGENT_PROMPT=$(load_agent_behavioral_prompt "plan-architect")

if ! echo "$AGENT_PROMPT" | grep -q "# Plan Architect Agent"; then
  fail "Integration: Failed to load agent prompt"
fi

# Calculate next artifact number
mkdir -p "$TEST_DIR/specs/042_feature/plans"
touch "$TEST_DIR/specs/042_feature/plans/042_implementation.md"

NEXT_NUM=$(get_next_artifact_number "$TEST_DIR/specs/042_feature/plans")

if [ "$NEXT_NUM" = "043" ]; then
  pass "Integration: Next number calculated correctly"
else
  fail "Integration: Expected 043, got $NEXT_NUM"
fi

# Verify artifact
VERIFIED=$(verify_artifact_or_recover \
  "$TEST_DIR/specs/042_feature/plans/042_implementation.md" \
  "implementation")

if [ $? -eq 0 ]; then
  pass "Integration: Artifact verified"
else
  fail "Integration: Verification failed"
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo "════════════════════════════════════════════════"
echo "Test Results"
echo "════════════════════════════════════════════════"
echo "PASSED: $PASS_COUNT"
echo "FAILED: $FAIL_COUNT"

if [ $FAIL_COUNT -eq 0 ]; then
  echo "✓ All tests passed"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
