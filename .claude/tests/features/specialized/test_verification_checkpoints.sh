#!/usr/bin/env bash
# test_verification_checkpoints.sh - Validate VERIFICATION CHECKPOINT patterns
#
# PURPOSE:
#   Validates that commands have MANDATORY VERIFICATION checkpoints after
#   file creation per Standard 0.
#
# USAGE:
#   ./test_verification_checkpoints.sh

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Detect project directory
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
COMMANDS_DIR="${CLAUDE_PROJECT_DIR}/.claude/commands"

echo "================================================================"
echo "Verification Checkpoint Validation"
echo "================================================================"
echo ""

# Commands that create files and MUST have verification checkpoints
FILE_CREATING_COMMANDS=(
  "debug"
  "plan"
  "research"
  "coordinate"
  "setup"
  "document"
  "expand"
  "collapse"
  "revise"
)

for cmd_file in "${COMMANDS_DIR}"/*.md; do
  if [ ! -f "$cmd_file" ] || [ "$(basename "$cmd_file")" = "README.md" ]; then
    continue
  fi

  cmd_name=$(basename "$cmd_file" .md)

  # Check if command is in the file-creating list
  is_file_creator=false
  for creator in "${FILE_CREATING_COMMANDS[@]}"; do
    if [ "$cmd_name" = "$creator" ]; then
      is_file_creator=true
      break
    fi
  done

  # Count verification patterns
  mandatory_checkpoints=$(grep -c "MANDATORY VERIFICATION\|VERIFICATION CHECKPOINT" "$cmd_file" 2>/dev/null || echo "0")
  verify_calls=$(grep -c "verify_file_created\|verify_state_variable" "$cmd_file" 2>/dev/null || echo "0")
  file_exists_checks=$(grep -c '\[ -f "\|[ ! -f "\|test -f' "$cmd_file" 2>/dev/null || echo "0")

  total_verifications=$((mandatory_checkpoints + verify_calls + file_exists_checks))

  if [ "$is_file_creator" = true ]; then
    if [ "$mandatory_checkpoints" -gt 0 ] || [ "$verify_calls" -gt 0 ]; then
      echo -e "${GREEN}PASS${NC} $cmd_name: Has verification checkpoints ($mandatory_checkpoints explicit, $verify_calls function calls)"
      PASSED=$((PASSED + 1))
    elif [ "$file_exists_checks" -gt 1 ]; then
      echo -e "${YELLOW}WARN${NC} $cmd_name: Uses file checks but no formal VERIFICATION CHECKPOINT ($file_exists_checks checks)"
      WARNINGS=$((WARNINGS + 1))
    else
      echo -e "${RED}FAIL${NC} $cmd_name: Creates files but missing VERIFICATION CHECKPOINT"
      FAILED=$((FAILED + 1))
    fi
  else
    if [ "$total_verifications" -gt 0 ]; then
      echo -e "${GREEN}PASS${NC} $cmd_name: Has verification patterns ($total_verifications total)"
    else
      echo -e "${GREEN}PASS${NC} $cmd_name: No file creation (verification not required)"
    fi
    PASSED=$((PASSED + 1))
  fi
done

echo ""
echo "================================================================"
echo "Summary: $PASSED passed, $FAILED failed, $WARNINGS warnings"
echo "================================================================"

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
exit 0
