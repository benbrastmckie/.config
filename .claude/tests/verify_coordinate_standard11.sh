#!/usr/bin/env bash
# Verify coordinate.md follows Standard 11 (Imperative Agent Invocation Pattern)

set -euo pipefail

echo "=== Standard 11 Compliance Verification for coordinate.md ==="
echo ""

PASS=0
FAIL=0

# Check 1: No SlashCommand usage
echo "Check 1: No SlashCommand usage"
if grep -q "SlashCommand" .claude/commands/coordinate.md; then
  echo "  ❌ FAIL: Found SlashCommand usage"
  FAIL=$((FAIL + 1))
else
  echo "  ✓ PASS: No SlashCommand usage found"
  PASS=$((PASS + 1))
fi

# Check 2: Uses Task tool for agent invocation
echo ""
echo "Check 2: Uses Task tool for agent invocation"
if grep -q "Task {" .claude/commands/coordinate.md; then
  TASK_COUNT=$(grep -c "Task {" .claude/commands/coordinate.md || echo "0")
  echo "  ✓ PASS: Uses Task tool ($TASK_COUNT invocations)"
  PASS=$((PASS + 1))
else
  echo "  ❌ FAIL: No Task tool usage found"
  FAIL=$((FAIL + 1))
fi

# Check 3: References behavioral agent files
echo ""
echo "Check 3: References behavioral agent files"
if grep -q ".claude/agents" .claude/commands/coordinate.md; then
  echo "  ✓ PASS: References behavioral agent files"
  echo "  Agents used:"
  grep -o ".claude/agents/[^\"]*\.md" .claude/commands/coordinate.md | sort -u | sed 's/^/    - /'
  PASS=$((PASS + 1))
else
  echo "  ❌ FAIL: No behavioral agent references found"
  FAIL=$((FAIL + 1))
fi

# Check 4: Includes EXECUTE NOW directives
echo ""
echo "Check 4: Includes EXECUTE NOW directives"
if grep -q "EXECUTE NOW" .claude/commands/coordinate.md; then
  EXEC_COUNT=$(grep -c "EXECUTE NOW" .claude/commands/coordinate.md || echo "0")
  echo "  ✓ PASS: Includes EXECUTE NOW directives ($EXEC_COUNT found)"
  PASS=$((PASS + 1))
else
  echo "  ⚠ WARNING: No EXECUTE NOW directives (recommended but not required)"
fi

# Check 5: No direct file operations (should delegate to agents)
echo ""
echo "Check 5: No direct file operations in implementation phase"
if grep -A 50 "State Handler: Implementation" .claude/commands/coordinate.md | grep -qE "Write tool|Edit tool|Read tool.*implementation"; then
  echo "  ⚠ WARNING: Found direct file operations (should delegate to agents)"
else
  echo "  ✓ PASS: No direct file operations in implementation (delegates to agents)"
  PASS=$((PASS + 1))
fi

echo ""
echo "=== Summary ==="
echo "Passed: $PASS checks"
echo "Failed: $FAIL checks"
echo ""

if [ $FAIL -eq 0 ]; then
  echo "✓ coordinate.md follows Standard 11 (Imperative Agent Invocation Pattern)"
  echo "  All critical requirements met."
  exit 0
else
  echo "✗ coordinate.md has Standard 11 violations"
  echo "  Review failed checks above."
  exit 1
fi
