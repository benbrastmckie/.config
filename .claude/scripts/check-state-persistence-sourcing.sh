#!/usr/bin/env bash
# State Persistence Sourcing Linter
# Validates that state persistence functions are called only after proper library sourcing
#
# Usage:
#   bash check-state-persistence-sourcing.sh [file1.md file2.md ...]
#   bash check-state-persistence-sourcing.sh --all  # Check all command/agent files
#
# Exit codes:
#   0 - All checks passed
#   1 - Sourcing violations detected (ERROR level)

set -euo pipefail

# Detect project directory
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi

# State persistence functions to check
STATE_FUNCTIONS=(
  "append_workflow_state"
  "append_workflow_state_bulk"
  "restore_workflow_state"
  "init_workflow_state"
  "save_completed_states_to_state"
)

# Color codes for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Counters
TOTAL_FILES=0
TOTAL_VIOLATIONS=0
TOTAL_WARNINGS=0

# Extract bash blocks from markdown file
# Returns: List of bash blocks with block numbers
extract_bash_blocks() {
  local file="$1"
  local in_bash_block=false
  local block_num=0
  local block_content=""
  local block_start_line=0

  while IFS= read -r line; do
    if [[ "$line" =~ ^\`\`\`bash ]]; then
      in_bash_block=true
      block_num=$((block_num + 1))
      block_content=""
      block_start_line=$((block_start_line + 1))
    elif [[ "$line" == "\`\`\`" ]] && [ "$in_bash_block" = true ]; then
      # Process completed block
      echo "BLOCK_START:$block_num:$block_start_line"
      echo "$block_content"
      echo "BLOCK_END:$block_num"
      in_bash_block=false
    elif [ "$in_bash_block" = true ]; then
      block_content="${block_content}${line}"$'\n'
    fi
    block_start_line=$((block_start_line + 1))
  done < "$file"
}

# Check if block sources state-persistence.sh
has_state_persistence_sourcing() {
  local block_content="$1"

  # Check for state-persistence.sh sourcing patterns
  if echo "$block_content" | grep -qE "(source|\\.).*state-persistence\\.sh"; then
    return 0
  fi

  return 1
}

# Check if block has pre-flight validation
has_preflight_validation() {
  local block_content="$1"

  # Check for validate_library_functions "state-persistence" pattern
  if echo "$block_content" | grep -qE 'validate_library_functions.*"state-persistence"'; then
    return 0
  fi

  return 1
}

# Check a single file
check_file() {
  local file="$1"
  local file_violations=0
  local file_warnings=0

  TOTAL_FILES=$((TOTAL_FILES + 1))

  # Skip non-markdown files
  if [[ ! "$file" =~ \.md$ ]]; then
    return 0
  fi

  # Extract bash blocks
  local blocks
  blocks=$(extract_bash_blocks "$file")

  # Process each block
  local current_block=""
  local current_block_num=0
  local current_block_start=0
  local in_block=false

  while IFS= read -r line; do
    if [[ "$line" =~ ^BLOCK_START:([0-9]+):([0-9]+) ]]; then
      current_block_num="${BASH_REMATCH[1]}"
      current_block_start="${BASH_REMATCH[2]}"
      current_block=""
      in_block=true
    elif [[ "$line" =~ ^BLOCK_END:([0-9]+) ]]; then
      # Check block for violations
      check_block "$file" "$current_block_num" "$current_block_start" "$current_block"
      file_violations=$((file_violations + $?))
      in_block=false
    elif [ "$in_block" = true ]; then
      current_block="${current_block}${line}"$'\n'
    fi
  done <<< "$blocks"

  return $file_violations
}

# Check a single bash block
check_block() {
  local file="$1"
  local block_num="$2"
  local block_start="$3"
  local block_content="$4"

  local has_functions=false
  local has_sourcing=false
  local has_validation=false
  local violations=0

  # Check if block uses state persistence functions
  for func in "${STATE_FUNCTIONS[@]}"; do
    if echo "$block_content" | grep -qE "\\b${func}\\b"; then
      has_functions=true
      break
    fi
  done

  # If no functions used, no checks needed
  if [ "$has_functions" = false ]; then
    return 0
  fi

  # Check if block sources state-persistence.sh
  if has_state_persistence_sourcing "$block_content"; then
    has_sourcing=true
  fi

  # Check if block has pre-flight validation
  if has_preflight_validation "$block_content"; then
    has_validation=true
  fi

  # Report violations
  if [ "$has_sourcing" = false ]; then
    echo -e "${RED}ERROR${NC}: $file (block $block_num, line ~$block_start)"
    echo "  State persistence functions used without sourcing state-persistence.sh"
    echo "  Add: source \"\${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh\" 2>/dev/null || { echo \"ERROR: Cannot load state-persistence library\" >&2; exit 1; }"
    echo ""
    violations=$((violations + 1))
    TOTAL_VIOLATIONS=$((TOTAL_VIOLATIONS + 1))
  fi

  if [ "$has_sourcing" = true ] && [ "$has_validation" = false ]; then
    echo -e "${YELLOW}WARNING${NC}: $file (block $block_num, line ~$block_start)"
    echo "  State persistence library sourced but missing pre-flight validation"
    echo "  Consider adding: validate_library_functions \"state-persistence\" || exit 1"
    echo ""
    TOTAL_WARNINGS=$((TOTAL_WARNINGS + 1))
  fi

  return $violations
}

# Main execution
main() {
  local files=()

  # Parse arguments
  if [ $# -eq 0 ] || [ "$1" = "--all" ]; then
    # Check all command and agent files
    mapfile -t files < <(find "$PROJECT_DIR/.claude/commands" "$PROJECT_DIR/.claude/agents" -type f -name "*.md" 2>/dev/null || true)
  else
    files=("$@")
  fi

  if [ ${#files[@]} -eq 0 ]; then
    echo "No files to check"
    exit 0
  fi

  echo "Checking state persistence sourcing in ${#files[@]} files..."
  echo ""

  # Check each file
  for file in "${files[@]}"; do
    check_file "$file"
  done

  # Summary
  echo "================================"
  echo "State Persistence Sourcing Check"
  echo "================================"
  echo "Files checked: $TOTAL_FILES"
  echo -e "Violations (ERROR): ${RED}${TOTAL_VIOLATIONS}${NC}"
  echo -e "Warnings: ${YELLOW}${TOTAL_WARNINGS}${NC}"
  echo ""

  if [ $TOTAL_VIOLATIONS -gt 0 ]; then
    echo -e "${RED}FAILED${NC}: State persistence sourcing violations detected"
    echo "Violations must be fixed before committing"
    exit 1
  else
    echo -e "${GREEN}PASSED${NC}: All state persistence functions properly sourced"
    exit 0
  fi
}

main "$@"
