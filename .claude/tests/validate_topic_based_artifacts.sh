#!/usr/bin/env bash
# Validates that all artifacts follow topic-based organization standard
# Reference: .claude/docs/README.md lines 114-138
#
# Topic-based structure: specs/{NNN_topic}/reports/, specs/{NNN_topic}/plans/, etc.
# Flat structure (WRONG): specs/reports/001_topic.md, specs/plans/001_plan.md

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
echo "  Topic-Based Artifact Organization Validation"
echo "════════════════════════════════════════════════════════════"
echo ""

VIOLATIONS=0
TOPIC_DIRS_FOUND=0
ARTIFACTS_VALIDATED=0

# Check 1: Detect flat directory structure violations (WRONG)
echo -e "${BLUE}[1/4] Checking for flat directory structure violations...${NC}"
echo ""

FLAT_REPORTS=$(find "${PROJECT_ROOT}/specs" -maxdepth 2 -path "*/reports/*.md" -not -path "*/[0-9][0-9][0-9]_*/reports/*" 2>/dev/null || true)
FLAT_PLANS=$(find "${PROJECT_ROOT}/specs" -maxdepth 2 -path "*/plans/*.md" -not -path "*/[0-9][0-9][0-9]_*/plans/*" 2>/dev/null || true)

if [ -n "$FLAT_REPORTS" ]; then
  echo -e "${RED}✗ VIOLATION: Found reports in flat structure${NC}"
  echo "  Location: specs/reports/ (should be specs/{NNN_topic}/reports/)"
  echo "  Files:"
  echo "$FLAT_REPORTS" | head -5 | sed 's/^/    /'
  if [ $(echo "$FLAT_REPORTS" | wc -l) -gt 5 ]; then
    echo "    ... and $(($(echo "$FLAT_REPORTS" | wc -l) - 5)) more"
  fi
  VIOLATIONS=$((VIOLATIONS + 1))
  echo ""
fi

if [ -n "$FLAT_PLANS" ]; then
  echo -e "${RED}✗ VIOLATION: Found plans in flat structure${NC}"
  echo "  Location: specs/plans/ (should be specs/{NNN_topic}/plans/)"
  echo "  Files:"
  echo "$FLAT_PLANS" | head -5 | sed 's/^/    /'
  if [ $(echo "$FLAT_PLANS" | wc -l) -gt 5 ]; then
    echo "    ... and $(($(echo "$FLAT_PLANS" | wc -l) - 5)) more"
  fi
  VIOLATIONS=$((VIOLATIONS + 1))
  echo ""
fi

if [ -z "$FLAT_REPORTS" ] && [ -z "$FLAT_PLANS" ]; then
  echo -e "${GREEN}✓ No flat directory structure violations${NC}"
  echo ""
fi

# Check 2: Validate topic-based directories exist and are properly structured
echo -e "${BLUE}[2/4] Validating topic-based directory structure...${NC}"
echo ""

if [ ! -d "${PROJECT_ROOT}/specs" ]; then
  echo -e "${YELLOW}⚠️  No specs/ directory found (may be new project)${NC}"
  echo ""
else
  TOPIC_DIRS=$(find "${PROJECT_ROOT}/specs" -maxdepth 1 -type d -name "[0-9][0-9][0-9]_*" 2>/dev/null || true)

  if [ -z "$TOPIC_DIRS" ]; then
    echo -e "${YELLOW}⚠️  No topic-based directories found${NC}"
    echo "   Expected format: specs/{NNN_topic}/ (e.g., specs/027_authentication/)"
    echo ""
  else
    TOPIC_DIRS_FOUND=$(echo "$TOPIC_DIRS" | wc -l)
    echo -e "${GREEN}✓ Found $TOPIC_DIRS_FOUND topic-based directories${NC}"
    echo ""

    # Validate structure of each topic directory
    for topic_dir in $TOPIC_DIRS; do
      topic_name=$(basename "$topic_dir")

      # Count artifacts in each subdirectory
      for subdir in reports plans summaries debug scripts outputs; do
        if [ -d "$topic_dir/$subdir" ]; then
          count=$(find "$topic_dir/$subdir" -name "*.md" -o -name "*.sh" 2>/dev/null | wc -l)
          ARTIFACTS_VALIDATED=$((ARTIFACTS_VALIDATED + count))
          if [ $count -gt 0 ]; then
            echo "  ✓ $topic_name/$subdir/: $count artifacts"
          fi
        fi
      done
    done
    echo ""
  fi
fi

# Check 3: Validate commands use create_topic_artifact() utility
echo -e "${BLUE}[3/4] Checking commands use create_topic_artifact()...${NC}"
echo ""

COMMANDS_WITH_AGENTS=("orchestrate" "plan" "report" "debug" "implement")
MANUAL_CONSTRUCTION_FOUND=0

for cmd in "${COMMANDS_WITH_AGENTS[@]}"; do
  cmd_file="${PROJECT_ROOT}/.claude/commands/${cmd}.md"

  if [[ ! -f "$cmd_file" ]]; then
    continue
  fi

  # Check if command creates artifacts
  if grep -q "Task {" "$cmd_file"; then
    # Check if it uses create_topic_artifact
    if grep -q "create_topic_artifact" "$cmd_file"; then
      echo -e "  ${GREEN}✓${NC} /$cmd: Uses create_topic_artifact()"
    else
      # Check if it manually constructs FLAT paths (anti-pattern)
      # Flat paths: specs/reports/NNN_*.md (no topic directory)
      # Topic paths: specs/NNN_topic/reports/NNN_*.md (correct)
      if grep -qE "PATH=[\"']?specs/(reports|plans|summaries)/[0-9]{3}_" "$cmd_file"; then
        echo -e "  ${RED}✗${NC} /$cmd: Manual FLAT path construction detected"
        echo "     Should use: create_topic_artifact()"
        VIOLATIONS=$((VIOLATIONS + 1))
        MANUAL_CONSTRUCTION_FOUND=1
      else
        echo "  ℹ️  /$cmd: May not create artifacts directly"
      fi
    fi
  fi
done

if [ $MANUAL_CONSTRUCTION_FOUND -eq 0 ]; then
  echo -e "${GREEN}✓ All commands use proper artifact creation utilities${NC}"
fi
echo ""

# Check 4: Validate artifact numbering consistency
echo -e "${BLUE}[4/4] Validating artifact numbering consistency...${NC}"
echo ""

NUMBERING_ISSUES=0

if [ -n "$TOPIC_DIRS" ]; then
  for topic_dir in $TOPIC_DIRS; do
    topic_name=$(basename "$topic_dir")
    topic_num=$(echo "$topic_name" | grep -oE '^[0-9]{3}')

    # Check that artifacts in topic directory start with same number
    for subdir in reports plans summaries; do
      if [ -d "$topic_dir/$subdir" ]; then
        MISMATCHED=$(find "$topic_dir/$subdir" -name "*.md" ! -name "${topic_num}_*.md" 2>/dev/null || true)
        if [ -n "$MISMATCHED" ]; then
          echo -e "  ${YELLOW}⚠${NC} $topic_name/$subdir/: Found artifacts not starting with $topic_num"
          echo "$MISMATCHED" | head -3 | sed 's/^/     /'
          NUMBERING_ISSUES=$((NUMBERING_ISSUES + 1))
        fi
      fi
    done
  done

  if [ $NUMBERING_ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓ All artifacts use consistent numbering${NC}"
  fi
else
  echo "  ℹ️  No topic directories to validate"
fi
echo ""

# Summary
echo "════════════════════════════════════════════════════════════"
echo "  Validation Summary"
echo "════════════════════════════════════════════════════════════"
echo "Topic directories found: $TOPIC_DIRS_FOUND"
echo "Artifacts validated: $ARTIFACTS_VALIDATED"
echo "Violations detected: $VIOLATIONS"
echo ""

if [ $VIOLATIONS -eq 0 ]; then
  echo -e "${GREEN}✅ Topic-based artifact organization validated${NC}"
  echo "   All artifacts follow proper directory structure"
  echo ""
  exit 0
else
  echo -e "${RED}❌ Found $VIOLATIONS organization violations${NC}"
  echo ""
  echo "────────────────────────────────────────────────────────────"
  echo -e "${YELLOW}Fix Instructions:${NC}"
  echo "1. Move flat artifacts to topic-based structure:"
  echo "   specs/reports/001_topic.md → specs/{NNN_topic}/reports/001_topic.md"
  echo ""
  echo "2. Update commands to use create_topic_artifact():"
  echo "   source \"\${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh\""
  echo "   TOPIC_DIR=\$(get_or_create_topic_dir \"\$DESCRIPTION\" \"specs\")"
  echo "   REPORT_PATH=\$(create_topic_artifact \"\$TOPIC_DIR\" \"reports\" \"topic\" \"\")"
  echo ""
  echo "3. Reference: .claude/docs/README.md lines 114-138"
  echo ""
  exit 1
fi
