#!/usr/bin/env bash
# Validates that commands using agents follow behavioral injection pattern
# Checks for:
# 1. Pre-calculated artifact paths (before agent invocation)
# 2. Topic-based directory structure usage
# 3. Artifact verification patterns
# 4. Metadata extraction (not full content loading)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "════════════════════════════════════════════════════════════"
echo "  Command Behavioral Injection Compliance Validation"
echo "════════════════════════════════════════════════════════════"
echo ""

COMMANDS_CHECKED=0
WARNINGS=0
PASSES=0

# Commands known to use agents for artifact creation
ARTIFACT_COMMANDS=(
  "orchestrate"
  "implement"
  "plan"
  "report"
  "debug"
)

for cmd in "${ARTIFACT_COMMANDS[@]}"; do
  cmd_file="${PROJECT_ROOT}/.claude/commands/${cmd}.md"

  if [[ ! -f "$cmd_file" ]]; then
    echo -e "${YELLOW}⚠️  Command file not found: ${cmd}.md${NC}"
    continue
  fi

  COMMANDS_CHECKED=$((COMMANDS_CHECKED + 1))
  echo -e "${BLUE}Checking: /$cmd${NC}"
  echo "────────────────────────────────────────────────────────────"

  # Check 1: Task tool usage (indicates agent invocation)
  if ! grep -q "Task {" "$cmd_file"; then
    echo "  ℹ️  No Task tool usage (command may not use agents)"
    echo ""
    continue
  fi

  HAS_ISSUES=false

  # Check 2: Pre-calculated paths (good pattern)
  if grep -qE "(PATH=.*specs/|create_topic_artifact|get_or_create_topic_dir)" "$cmd_file"; then
    echo -e "  ${GREEN}✓${NC} Path pre-calculation found"
  else
    echo -e "  ${YELLOW}⚠${NC} No path pre-calculation detected"
    WARNINGS=$((WARNINGS + 1))
    HAS_ISSUES=true
  fi

  # Check 3: Topic-based artifact organization
  if grep -q "create_topic_artifact" "$cmd_file"; then
    echo -e "  ${GREEN}✓${NC} Uses create_topic_artifact() utility"
  else
    # Check for manual path construction (anti-pattern)
    if grep -qE "specs/(reports|plans|summaries)/[^/]+\.md" "$cmd_file"; then
      echo -e "  ${YELLOW}⚠${NC} Manual path construction detected (should use create_topic_artifact)"
      WARNINGS=$((WARNINGS + 1))
      HAS_ISSUES=true
    else
      echo "  ℹ️  May not create artifacts directly"
    fi
  fi

  # Check 4: Artifact verification (good pattern)
  if grep -qE "(verify.*artifact|if.*-f.*PATH|test -f)" "$cmd_file"; then
    echo -e "  ${GREEN}✓${NC} Artifact verification found"
  else
    echo -e "  ${YELLOW}⚠${NC} No artifact verification detected"
    WARNINGS=$((WARNINGS + 1))
    HAS_ISSUES=true
  fi

  # Check 5: Metadata extraction (good pattern)
  if grep -qE "(extract.*metadata|jq.*summary|METADATA=)" "$cmd_file"; then
    echo -e "  ${GREEN}✓${NC} Metadata extraction found"
  else
    echo "  ℹ️  Metadata extraction not detected (may load full artifacts)"
  fi

  # Check 6: Behavioral injection pattern
  if grep -qE "Read and follow.*behavioral|acting as.*Agent" "$cmd_file"; then
    echo -e "  ${GREEN}✓${NC} Behavioral injection pattern found"
  else
    echo "  ℹ️  No explicit behavioral injection (may use direct prompts)"
  fi

  if [ "$HAS_ISSUES" = false ]; then
    PASSES=$((PASSES + 1))
  fi

  echo ""
done

echo "════════════════════════════════════════════════════════════"
echo "  Validation Summary"
echo "════════════════════════════════════════════════════════════"
echo "Commands checked: $COMMANDS_CHECKED"
echo "Commands passing: $PASSES"
echo "Warnings issued: $WARNINGS"
echo ""

if [ $WARNINGS -eq 0 ]; then
  echo -e "${GREEN}✅ All commands follow behavioral injection best practices${NC}"
  exit 0
else
  echo -e "${YELLOW}⚠️  Some commands have compliance warnings${NC}"
  echo ""
  echo "Recommendations:"
  echo "1. Use create_topic_artifact() for all artifact path calculations"
  echo "2. Add artifact verification after agent completion"
  echo "3. Extract metadata instead of loading full artifact content"
  echo "4. Reference: .claude/docs/guides/command-authoring-guide.md"
  echo ""
  exit 0  # Warnings don't fail build, only violations do
fi
