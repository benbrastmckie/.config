#!/usr/bin/env bash
# Validates that NO agent behavioral files contain slash command invocations
# This prevents the anti-pattern where agents delegate artifact creation
# to slash commands instead of creating files directly.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Navigate up to project root (from tests/utilities to project root)
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "════════════════════════════════════════════════════════════"
echo "  Agent Behavioral Files: Anti-Pattern Detection"
echo "════════════════════════════════════════════════════════════"
echo ""

VIOLATIONS=0
AGENTS_SCANNED=0
VIOLATION_DETAILS=""

# Get all agent behavioral files
AGENT_FILES=$(find "${PROJECT_ROOT}/.claude/agents" -name "*.md" -type f 2>/dev/null || true)

if [ -z "$AGENT_FILES" ]; then
  echo -e "${RED}ERROR: No agent files found in .claude/agents/${NC}"
  exit 1
fi

# Scan each agent file
for agent_file in $AGENT_FILES; do
  agent_name=$(basename "$agent_file" .md)
  AGENTS_SCANNED=$((AGENTS_SCANNED + 1))

  echo -n "Scanning: ${agent_name}... "

  # Anti-pattern: Explicit artifact-creation slash command invocation instructions
  # Only check for slash commands that create artifacts (not utility commands like /expand, /collapse)
  # Look for patterns like "invoke /plan", "use /report", "call /implement"
  ARTIFACT_SLASH_COMMANDS=("/plan" "/report" "/debug" "/implement" "/orchestrate")
  FOUND_VIOLATION=false

  for cmd in "${ARTIFACT_SLASH_COMMANDS[@]}"; do
    # Match patterns: "invoke /plan", "use /plan", "call /plan", "run /plan"
    if grep -qiE "(invoke|use|call|run|execute)\s+${cmd}" "$agent_file" 2>/dev/null; then
      if [ "$FOUND_VIOLATION" = false ]; then
        echo -e "${RED}VIOLATION${NC}"
        VIOLATIONS=$((VIOLATIONS + 1))
        VIOLATION_DETAILS="${VIOLATION_DETAILS}
${RED}✗ ${agent_name}.md${NC}
  Anti-pattern: Instructions to invoke '${cmd}' slash command
  Lines:"
        FOUND_VIOLATION=true
      fi
      VIOLATION_DETAILS="${VIOLATION_DETAILS}
$(grep -niE "(invoke|use|call|run|execute)\s+${cmd}" "$agent_file" | head -3)"
    fi
  done

  if [ "$FOUND_VIOLATION" = false ]; then
    echo -e "${GREEN}✓ CLEAN${NC}"
  fi
done

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Scan Results"
echo "════════════════════════════════════════════════════════════"
echo "Agents scanned: $AGENTS_SCANNED"
echo "Violations found: $VIOLATIONS"
echo ""

if [ $VIOLATIONS -gt 0 ]; then
  echo -e "${RED}VIOLATIONS DETECTED:${NC}"
  echo -e "$VIOLATION_DETAILS"
  echo ""
  echo "────────────────────────────────────────────────────────────"
  echo -e "${YELLOW}Fix Instructions:${NC}"
  echo "1. Remove SlashCommand tool invocations from agent files"
  echo "2. Update agents to create artifacts directly using Write/Edit tools"
  echo "3. Ensure commands pre-calculate paths and inject them into agent prompts"
  echo "4. Reference: .claude/docs/guides/agent-authoring-guide.md"
  echo ""
  exit 1
else
  echo -e "${GREEN}✅ All agent behavioral files are CLEAN${NC}"
  echo "   No slash command anti-patterns detected"
  echo ""
  exit 0
fi
