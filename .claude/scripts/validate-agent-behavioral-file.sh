#!/usr/bin/env bash
# validate-agent-behavioral-file.sh - Validate agent behavioral files for contradictions
#
# Spec: 752 Phase 8
# Purpose: Detect contradictions between allowed-tools frontmatter and behavioral instructions
#
# Usage: bash validate-agent-behavioral-file.sh <agent-file.md>

set -euo pipefail

AGENT_FILE="${1:-}"

if [ -z "$AGENT_FILE" ]; then
  echo "Usage: $0 <agent-behavioral-file.md>" >&2
  exit 1
fi

if [ ! -f "$AGENT_FILE" ]; then
  echo "ERROR: File not found: $AGENT_FILE" >&2
  exit 1
fi

AGENT_NAME=$(basename "$AGENT_FILE" .md)
ERRORS=0
WARNINGS=0

echo "Validating agent behavioral file: $AGENT_FILE"
echo ""

# Extract frontmatter
FRONTMATTER=$(awk '/^---$/{flag=!flag; next} flag' "$AGENT_FILE")

# Extract allowed-tools
ALLOWED_TOOLS=$(echo "$FRONTMATTER" | grep "^allowed-tools:" | sed 's/allowed-tools: *//' | tr -d ' ')

# Extract model
MODEL=$(echo "$FRONTMATTER" | grep "^model:" | sed 's/model: *//')

# Extract timeout (if present)
TIMEOUT=$(echo "$FRONTMATTER" | grep "^timeout:" | sed 's/timeout: *//' || echo "")

echo "Agent Configuration:"
echo "  Name: $AGENT_NAME"
echo "  Allowed Tools: ${ALLOWED_TOOLS:-<not set>}"
echo "  Model: ${MODEL:-<not set>}"
echo "  Timeout: ${TIMEOUT:-<not set>}"
echo ""

# Validation 1: allowed-tools matches bash execution instructions
echo "=== Validation 1: Bash Tool Configuration ==="

if [ "$ALLOWED_TOOLS" = "None" ] || [ -z "$ALLOWED_TOOLS" ]; then
  # Agent should NOT have bash execution instructions
  if grep -q "USE the Bash tool" "$AGENT_FILE"; then
    echo "❌ ERROR: Agent configured with 'allowed-tools: None' but contains 'USE the Bash tool' instruction"
    ERRORS=$((ERRORS + 1))
  fi

  if grep -q '```bash' "$AGENT_FILE"; then
    # Check if bash blocks are just examples (in backticks) or actual instructions
    BASH_BLOCK_COUNT=$(grep -c '```bash' "$AGENT_FILE")
    echo "⚠️  WARNING: Agent has $BASH_BLOCK_COUNT bash code blocks but 'allowed-tools: None'"
    echo "   Verify these are examples only, not execution instructions"
    WARNINGS=$((WARNINGS + 1))
  fi

  if [ $ERRORS -eq 0 ]; then
    echo "✓ PASS: No bash execution instructions found (consistent with allowed-tools: None)"
  fi
else
  # Agent has tools - verify they're used appropriately
  echo "✓ Agent has allowed-tools: $ALLOWED_TOOLS"

  # Check if agent claims to have bash but doesn't use it
  if echo "$ALLOWED_TOOLS" | grep -qi "bash"; then
    if ! grep -q '```bash' "$AGENT_FILE"; then
      echo "⚠️  WARNING: Agent has Bash tool but no bash code blocks found"
      echo "   Consider removing Bash from allowed-tools if not needed"
      WARNINGS=$((WARNINGS + 1))
    else
      echo "✓ Bash tool configured and bash blocks present"
    fi
  fi
fi

echo ""

# Validation 2: Model appropriate for allowed tools
echo "=== Validation 2: Model Appropriateness ==="

if [ "$MODEL" = "haiku" ] || [ "$MODEL" = "haiku-4.5" ]; then
  # Haiku is fast/cheap - good for classification, not complex execution
  if echo "$ALLOWED_TOOLS" | grep -Eq "Write|Edit"; then
    echo "⚠️  WARNING: Haiku model configured with Write/Edit tools"
    echo "   Haiku is optimized for fast classification, not code generation"
    echo "   Consider using sonnet-4.5 for implementation tasks"
    WARNINGS=$((WARNINGS + 1))
  else
    echo "✓ Haiku model appropriate for tool configuration"
  fi
elif [ "$MODEL" = "sonnet-4.5" ]; then
  echo "✓ Sonnet model supports all tool configurations"
fi

echo ""

# Validation 3: Timeout alignment with expected tool usage
echo "=== Validation 3: Timeout Configuration ==="

if [ -n "$TIMEOUT" ]; then
  TIMEOUT_MS=$(echo "$TIMEOUT" | tr -d 'ms' | tr -d ' ')

  if [ "$ALLOWED_TOOLS" = "None" ]; then
    # Classification agents should have short timeouts (< 30000ms)
    if [ "$TIMEOUT_MS" -gt 30000 ]; then
      echo "⚠️  WARNING: Classification agent (no tools) has timeout > 30s"
      echo "   Current: ${TIMEOUT_MS}ms"
      echo "   Recommended: <30000ms for fast classification"
      WARNINGS=$((WARNINGS + 1))
    else
      echo "✓ Timeout appropriate for classification agent (${TIMEOUT_MS}ms)"
    fi
  else
    # Execution agents may need longer timeouts
    if [ "$TIMEOUT_MS" -lt 60000 ]; then
      echo "⚠️  WARNING: Execution agent has timeout < 60s"
      echo "   Current: ${TIMEOUT_MS}ms"
      echo "   May be too short for code generation/execution tasks"
      WARNINGS=$((WARNINGS + 1))
    else
      echo "✓ Timeout appropriate for execution agent (${TIMEOUT_MS}ms)"
    fi
  fi
else
  echo "ℹ️  No timeout configured (using defaults)"
fi

echo ""

# Validation 4: State persistence patterns
echo "=== Validation 4: State Persistence Patterns ==="

if [ "$ALLOWED_TOOLS" = "None" ]; then
  # Agent should NOT try to persist state directly
  if grep -q "append_workflow_state" "$AGENT_FILE"; then
    echo "❌ ERROR: Agent with 'allowed-tools: None' contains append_workflow_state() call"
    echo "   Agent cannot execute bash commands to persist state"
    echo "   Use output-based pattern: return structured data for parent to persist"
    ERRORS=$((ERRORS + 1))
  else
    echo "✓ PASS: No state persistence instructions (consistent with no tools)"
  fi

  if grep -q "save_.*_checkpoint" "$AGENT_FILE"; then
    echo "❌ ERROR: Agent with 'allowed-tools: None' contains checkpoint save instructions"
    echo "   Agent cannot execute bash commands"
    ERRORS=$((ERRORS + 1))
  fi

  if [ $ERRORS -eq 0 ]; then
    echo "✓ PASS: Agent uses output-based pattern (no direct state persistence)"
  fi
else
  # Agent with tools can persist state
  if echo "$ALLOWED_TOOLS" | grep -qi "bash"; then
    echo "✓ Agent has Bash tool - can persist state if needed"
  fi
fi

echo ""

# Summary
echo "═══════════════════════════════════════════════════════"
echo "VALIDATION SUMMARY"
echo "═══════════════════════════════════════════════════════"
echo "Agent: $AGENT_NAME"
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo "Status: ✓ PASS (no issues)"
  exit 0
elif [ $ERRORS -eq 0 ]; then
  echo "Status: ⚠️  PASS WITH WARNINGS"
  exit 0
else
  echo "Status: ❌ FAIL ($ERRORS critical errors)"
  exit 1
fi
