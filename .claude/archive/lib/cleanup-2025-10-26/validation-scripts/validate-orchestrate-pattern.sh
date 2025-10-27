#!/usr/bin/env bash
# Validate /orchestrate follows architectural pattern
# CRITICAL: Prevent command-to-command invocations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORCHESTRATE_FILE="${SCRIPT_DIR}/../commands/orchestrate.md"

echo "Validating /orchestrate architectural pattern..."

# Check 1: No SlashCommand tool usage (excluding comments and documentation)
# We look for actual tool usage, not mentions in comments or documentation
# Pattern: We want to catch uses like SlashCommand("/plan") but NOT comments
if grep -v "^<!--" "$ORCHESTRATE_FILE" | grep -v "^#" | grep -E "SlashCommand\(|SlashCommand\s*{" | grep -v "(not SlashCommand)" | grep -v "NOT.*SlashCommand" | grep -v "without.*SlashCommand" > /dev/null; then
  echo "✗ FAIL: SlashCommand tool invocation detected in orchestrate.md"
  echo ""
  echo "Violations found (excluding comments):"
  grep -v "^<!--" "$ORCHESTRATE_FILE" | grep -v "^#" | grep -n -E "SlashCommand\(|SlashCommand\s*{" | grep -v "(not SlashCommand)" | grep -v "NOT.*SlashCommand" | grep -v "without.*SlashCommand"
  echo ""
  echo "ARCHITECTURAL VIOLATION: /orchestrate must NOT invoke other slash commands"
  echo "Use Task tool with direct agent invocations instead"
  exit 1
else
  echo "✓ PASS: No SlashCommand tool invocations detected"
fi

# Check 2: Task tool used for all agents
TASK_COUNT=$(grep -c "Task {" "$ORCHESTRATE_FILE" || true)
if [ "$TASK_COUNT" -lt 5 ]; then
  echo "✗ FAIL: Expected at least 5 Task tool invocations (research, plan, implement, debug, doc)"
  echo "Found: $TASK_COUNT"
  exit 1
else
  echo "✓ PASS: Task tool usage detected ($TASK_COUNT invocations)"
fi

# Check 3: Artifact path injection present
if ! grep -q "artifact_paths\|WORKFLOW_TOPIC_DIR" "$ORCHESTRATE_FILE"; then
  echo "✗ FAIL: No artifact path injection detected"
  echo "Agents must receive artifact paths from location-specialist"
  exit 1
else
  echo "✓ PASS: Artifact path injection present"
fi

# Check 4: No direct command names in Task prompts
FORBIDDEN_PATTERNS=("/plan " "/implement " "/debug " "/document ")
for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
  if grep "Task {" -A 20 "$ORCHESTRATE_FILE" | grep -q "$pattern"; then
    echo "✗ FAIL: Slash command '$pattern' found in Task prompt"
    echo "This might indicate command invocation instead of agent invocation"
    exit 1
  fi
done
echo "✓ PASS: No slash command invocations in Task prompts"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "✓ ALL CHECKS PASSED - Architectural pattern validated"
echo "═══════════════════════════════════════════════════════"
exit 0
