#!/usr/bin/env bash
# Test code-writer agent does not invoke slash commands (prevents recursion)

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

# Find project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CODE_WRITER_FILE="$PROJECT_ROOT/agents/code-writer.md"

echo "════════════════════════════════════════════════"
echo "Code Writer Anti-Recursion Test Suite"
echo "════════════════════════════════════════════════"
echo ""
echo "Testing: $CODE_WRITER_FILE"
echo ""

# ============================================================================
# Test 1: No /implement invocation instructions
# ============================================================================

echo "Test 1: Verify no /implement invocation instructions"

if grep -q "USE /implement command" "$CODE_WRITER_FILE"; then
  fail "Found 'USE /implement command' instruction (recursion risk)"
else
  pass "No 'USE /implement command' instruction found"
fi

# ============================================================================
# Test 2: No SlashCommand tool usage for /implement
# ============================================================================

echo ""
echo "Test 2: Verify no SlashCommand(/implement) pattern"

if grep -q "SlashCommand.*\/implement" "$CODE_WRITER_FILE"; then
  fail "Found 'SlashCommand' usage for /implement (recursion risk)"
else
  pass "No SlashCommand(/implement) pattern found"
fi

# ============================================================================
# Test 3: No "Type A: Plan-Based Implementation" section
# ============================================================================

echo ""
echo "Test 3: Verify 'Type A: Plan-Based Implementation' section removed"

if grep -q "Type A: Plan-Based Implementation" "$CODE_WRITER_FILE"; then
  fail "Found 'Type A: Plan-Based Implementation' section (should be removed)"
else
  pass "'Type A: Plan-Based Implementation' section removed"
fi

# ============================================================================
# Test 4: Anti-pattern warning section exists
# ============================================================================

echo ""
echo "Test 4: Verify anti-pattern warning section exists"

if grep -q "CRITICAL: Do NOT Invoke Slash Commands" "$CODE_WRITER_FILE"; then
  pass "Anti-pattern warning section exists"
else
  fail "Anti-pattern warning section missing"
fi

# ============================================================================
# Test 5: Verify NEVER invoke /implement is documented
# ============================================================================

echo ""
echo "Test 5: Verify explicit /implement recursion warning"

if grep -q "Recursion risk.*YOU are invoked BY /implement" "$CODE_WRITER_FILE"; then
  pass "Explicit /implement recursion warning found"
else
  fail "No explicit /implement recursion warning"
fi

# ============================================================================
# Test 6: Verify STEP 1 clarifies agent receives TASKS
# ============================================================================

echo ""
echo "Test 6: Verify STEP 1 clarifies receiving TASKS (not plans)"

if grep -q "YOU receive specific code change TASKS" "$CODE_WRITER_FILE"; then
  pass "STEP 1 clarifies agent receives TASKS"
else
  fail "STEP 1 does not clarify receiving TASKS"
fi

# ============================================================================
# Test 7: Verify no plan file path instructions
# ============================================================================

echo ""
echo "Test 7: Verify no instructions to receive plan file paths"

if grep -q "Plan file path (absolute path to implementation plan)" "$CODE_WRITER_FILE"; then
  fail "Found instructions to receive plan file paths (should be removed)"
else
  pass "No instructions to receive plan file paths"
fi

# ============================================================================
# Test 8: Verify Read/Write/Edit tools emphasized
# ============================================================================

echo ""
echo "Test 8: Verify Read/Write/Edit tools are emphasized"

if grep -q "ALWAYS.*use Read/Write/Edit tools" "$CODE_WRITER_FILE"; then
  pass "Read/Write/Edit tools emphasized correctly"
else
  fail "Read/Write/Edit tools not properly emphasized"
fi

# ============================================================================
# Test 9: Verify no other slash command invocations
# ============================================================================

echo ""
echo "Test 9: Verify no instructions to invoke /plan, /report, /orchestrate"

SLASH_CMDS_FOUND=0

if grep -q "use.*\/plan" "$CODE_WRITER_FILE" | grep -v "NEVER" | grep -v "Do NOT"; then
  echo "  Found /plan invocation instruction"
  SLASH_CMDS_FOUND=1
fi

if grep -q "use.*\/report" "$CODE_WRITER_FILE" | grep -v "NEVER" | grep -v "Do NOT"; then
  echo "  Found /report invocation instruction"
  SLASH_CMDS_FOUND=1
fi

if grep -q "invoke.*\/orchestrate" "$CODE_WRITER_FILE" | grep -v "NEVER" | grep -v "Do NOT"; then
  echo "  Found /orchestrate invocation instruction"
  SLASH_CMDS_FOUND=1
fi

if [ $SLASH_CMDS_FOUND -eq 0 ]; then
  pass "No instructions to invoke other slash commands"
else
  fail "Found instructions to invoke other slash commands"
fi

# ============================================================================
# Test 10: Verify NEVER invoke slash commands in critical instructions
# ============================================================================

echo ""
echo "Test 10: Verify 'NEVER invoke slash commands' in critical instructions"

if grep -q "NEVER invoke slash commands" "$CODE_WRITER_FILE"; then
  pass "'NEVER invoke slash commands' found in critical instructions"
else
  fail "'NEVER invoke slash commands' not in critical instructions"
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo "════════════════════════════════════════════════"
echo "Test Summary"
echo "════════════════════════════════════════════════"
echo "PASS: $PASS_COUNT"
echo "FAIL: $FAIL_COUNT"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
  echo "✓ All tests passed!"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
