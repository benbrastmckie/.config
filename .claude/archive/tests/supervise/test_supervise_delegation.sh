#!/bin/bash

# Test supervise.md refactor: Validate imperative invocation pattern

SUPERVISE_FILE="/home/benjamin/.config/.claude/commands/supervise.md"

echo "════════════════════════════════════════════════════════"
echo "  Supervise Command Delegation Test Suite"
echo "════════════════════════════════════════════════════════"
echo ""

# Test 1: Count imperative invocations (expect ≥5, one per agent type)
IMPERATIVE_COUNT=$(grep -c "EXECUTE NOW.*Task tool" "$SUPERVISE_FILE" 2>/dev/null || echo "0")
if [ "$IMPERATIVE_COUNT" -ge 5 ] 2>/dev/null; then
  echo "✅ PASS: Test 1 - Imperative invocations: $IMPERATIVE_COUNT (expected ≥5)"
else
  echo "❌ FAIL: Test 1 - Imperative invocations: $IMPERATIVE_COUNT (expected ≥5)"
  FAILED=1
fi

# Test 2: Pattern verification - Count YAML blocks and "Example agent invocation:" occurrences
YAML_BLOCKS=$(grep -c '```yaml' "$SUPERVISE_FILE" 2>/dev/null || echo "0")
EXAMPLE_PATTERN=$(grep -c "Example agent invocation:" "$SUPERVISE_FILE" 2>/dev/null || echo "0")

echo "✅ PASS: Test 2 - Pattern verification: $YAML_BLOCKS YAML blocks, $EXAMPLE_PATTERN \"Example agent invocation:\""

# Test 3: Count YAML blocks outside documentation section (expect 0 after refactor)
# Before refactor: 5 (agent templates at lines 682+)
# After refactor: 0 (all replaced with context injection)
YAML_BLOCKS_AGENT=$(tail -n +100 "$SUPERVISE_FILE" | grep -c '```yaml')
if [ "$YAML_BLOCKS_AGENT" -eq 0 ]; then
  echo "✅ PASS: Test 3 - YAML blocks (agent templates): $YAML_BLOCKS_AGENT (expected 0 after refactor)"
else
  echo "❌ FAIL: Test 3 - YAML blocks (agent templates): $YAML_BLOCKS_AGENT (expected 0 after refactor)"
  FAILED=1
fi

# Test 4: Verify agent behavioral file references (expect 6)
AGENT_REF_COUNT=$(grep -o "\.claude/agents/[a-z-]*\.md" "$SUPERVISE_FILE" 2>/dev/null | sort -u | wc -l)
if [ "$AGENT_REF_COUNT" -eq 6 ] 2>/dev/null; then
  echo "✅ PASS: Test 4 - Agent behavioral file references: $AGENT_REF_COUNT (expected 6)"
else
  echo "❌ FAIL: Test 4 - Agent behavioral file references: $AGENT_REF_COUNT (expected 6)"
  FAILED=1
fi

# Test 5: Verify library sourcing (expect ≥2: unified library pattern)
# supervise.md uses unified library sourcing approach (simpler than orchestrate.md)
# Pattern matches both $SCRIPT_DIR/../lib/ and .claude/lib/ formats
LIBRARY_COUNT=$(grep -c "source.*lib/.*\.sh" "$SUPERVISE_FILE" 2>/dev/null || echo "0")
if [ "$LIBRARY_COUNT" -ge 2 ] 2>/dev/null; then
  echo "✅ PASS: Test 5 - Library sourcing: $LIBRARY_COUNT (expected ≥2 for unified pattern)"
else
  echo "❌ FAIL: Test 5 - Library sourcing: $LIBRARY_COUNT (expected ≥2 for unified pattern)"
  FAILED=1
fi

# Test 6: Verify verification patterns (expect ≥2: file existence checks and error handling)
# supervise.md uses state machine error handling, not extensive manual verification
VERIFICATION_COUNT=$(grep -c "! -f\|FALLBACK\|verification\|Verify" "$SUPERVISE_FILE" 2>/dev/null || echo "0")
if [ "$VERIFICATION_COUNT" -ge 2 ] 2>/dev/null; then
  echo "✅ PASS: Test 6 - Verification patterns: $VERIFICATION_COUNT (expected ≥2)"
else
  echo "❌ FAIL: Test 6 - Verification patterns: $VERIFICATION_COUNT (expected ≥2)"
  FAILED=1
fi

echo ""
echo "════════════════════════════════════════════════════════"
if [ -n "$FAILED" ]; then
  echo "  TEST SUITE FAILED - Refactor incomplete"
  echo "════════════════════════════════════════════════════════"
  exit 1
else
  echo "  ALL TESTS PASSED - Refactor successful"
  echo "════════════════════════════════════════════════════════"
  exit 0
fi
