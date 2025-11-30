#!/usr/bin/env bash
# Compliance audit script for ERR trap integration across all commands
# Verifies that every bash block has setup_bash_error_trap() call

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect project root using git or walk-up pattern
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  CLAUDE_PROJECT_DIR="$SCRIPT_DIR"
  while [ "$CLAUDE_PROJECT_DIR" != "/" ]; do
    if [ -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
      break
    fi
    CLAUDE_PROJECT_DIR="$(dirname "$CLAUDE_PROJECT_DIR")"
  done
fi
CLAUDE_DIR="${CLAUDE_PROJECT_DIR}/.claude"
COMMANDS_DIR="${CLAUDE_DIR}/commands"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Expected block counts from plan (total blocks including documentation/usage examples)
# Note: build.md was consolidated from 8 to 7 blocks (Block 1a/1b/1c -> Block 1)
declare -A EXPECTED_BLOCKS=(
  ["plan"]=5
  ["build"]=7
  ["debug"]=11
  ["repair"]=4
  ["revise"]=8
  ["research"]=3
)

# Expected documentation blocks (usage examples that don't need traps)
declare -A DOC_BLOCKS=(
  ["plan"]=0
  ["build"]=1
  ["debug"]=1
  ["repair"]=0
  ["revise"]=0
  ["research"]=0
)

# Track overall stats
TOTAL_COMMANDS=0
COMPLIANT_COMMANDS=0
TOTAL_BLOCKS=0
TOTAL_TRAPS=0
MISSING_TRAPS=0

print_header() {
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║       ERR TRAP COMPLIANCE AUDIT                          ║"
  echo "╠══════════════════════════════════════════════════════════╣"
  echo "║ Verifying trap integration across all commands          ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo ""
}

check_command_compliance() {
  local cmd_name=$1
  local expected_blocks=${EXPECTED_BLOCKS[$cmd_name]}
  local expected_doc_blocks=${DOC_BLOCKS[$cmd_name]:-0}
  local expected_executable=$((expected_blocks - expected_doc_blocks))
  local cmd_file="${COMMANDS_DIR}/${cmd_name}.md"

  if [ ! -f "$cmd_file" ]; then
    echo -e "${RED}✗${NC} /${cmd_name}: FILE NOT FOUND"
    return 1
  fi

  # Count bash blocks
  local bash_blocks=$(grep -c '```bash' "$cmd_file" 2>/dev/null || echo "0")

  # Count blocks with at least one trap (not total trap calls - a block may have multiple)
  local trap_calls=$(awk '
    /```bash/ { in_block=1; has_trap=0; next }
    in_block && /setup_bash_error_trap/ { has_trap=1 }
    in_block && /^```$/ {
      if (has_trap) count++
      in_block=0
      next
    }
    END { print count+0 }
  ' "$cmd_file" 2>/dev/null || echo "0")

  TOTAL_COMMANDS=$((TOTAL_COMMANDS + 1))
  TOTAL_BLOCKS=$((TOTAL_BLOCKS + bash_blocks))
  TOTAL_TRAPS=$((TOTAL_TRAPS + trap_calls))

  # Check if all executable blocks have traps (accounting for doc blocks)
  local missing=$((bash_blocks - trap_calls - expected_doc_blocks))

  if [ $missing -eq 0 ] && [ $bash_blocks -eq $expected_blocks ]; then
    if [ $expected_doc_blocks -gt 0 ]; then
      echo -e "${GREEN}✓${NC} /${cmd_name}: ${trap_calls}/${bash_blocks} blocks (100% coverage, ${expected_doc_blocks} doc block(s))"
    else
      echo -e "${GREEN}✓${NC} /${cmd_name}: ${trap_calls}/${bash_blocks} blocks (100% coverage)"
    fi
    COMPLIANT_COMMANDS=$((COMPLIANT_COMMANDS + 1))
    return 0
  elif [ $missing -eq 0 ]; then
    echo -e "${YELLOW}⚠${NC} /${cmd_name}: ${trap_calls}/${bash_blocks} blocks (100% coverage, but expected ${expected_blocks} blocks)"
    COMPLIANT_COMMANDS=$((COMPLIANT_COMMANDS + 1))
    return 0
  else
    echo -e "${RED}✗${NC} /${cmd_name}: ${trap_calls}/${bash_blocks} blocks (${missing} executable blocks missing traps)"
    MISSING_TRAPS=$((MISSING_TRAPS + missing))

    # Find blocks without traps
    find_missing_traps "$cmd_file" "$cmd_name"
    return 1
  fi
}

find_missing_traps() {
  local cmd_file=$1
  local cmd_name=$2

  # Extract bash blocks and check for trap calls
  local block_num=0
  local in_bash_block=false
  local has_trap=false
  local is_example_block=false
  local line_num=0
  local block_start_line=0

  while IFS= read -r line; do
    line_num=$((line_num + 1))

    if [[ "$line" == '```bash'* ]]; then
      block_num=$((block_num + 1))
      block_start_line=$line_num
      in_bash_block=true
      has_trap=false
      is_example_block=false
    elif [ "$in_bash_block" = true ]; then
      # Check if this is an example/usage block (contains usage examples or starts with command invocations)
      # Patterns: "# Example", "# Usage", lines starting with "/$cmd_name" (command calls)
      if [[ "$line" =~ ^#.*(Example|Usage|example|usage) ]] || [[ "$line" =~ ^/[a-z]+ ]] || [[ "$line" =~ ^#.*[Aa]uto-resume ]]; then
        is_example_block=true
      fi

      if [[ "$line" == *"setup_bash_error_trap"* ]]; then
        has_trap=true
      elif [[ "$line" == '```' ]]; then
        in_bash_block=false
        # Only report missing trap if not an example block and block has substantial content
        if [ "$has_trap" = false ] && [ "$is_example_block" = false ] && [ $((line_num - block_start_line)) -gt 5 ]; then
          echo -e "  ${YELLOW}→${NC} Block ${block_num} (line ~${line_num}): Missing setup_bash_error_trap()"
        fi
      fi
    fi
  done < "$cmd_file"
}

calculate_coverage() {
  local coverage=0
  if [ $TOTAL_BLOCKS -gt 0 ]; then
    coverage=$(( (TOTAL_TRAPS * 100) / TOTAL_BLOCKS ))
  fi
  echo $coverage
}

print_summary() {
  local coverage=$(calculate_coverage)

  echo ""
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║       COMPLIANCE AUDIT SUMMARY                           ║"
  echo "╠══════════════════════════════════════════════════════════╣"
  echo "║ Commands Audited:  ${TOTAL_COMMANDS}/6                            ║"
  echo "║ Compliant Commands: ${COMPLIANT_COMMANDS}/6                            ║"
  echo "║ Total Bash Blocks:  ${TOTAL_BLOCKS}                               ║"
  echo "║ Blocks with Traps:  ${TOTAL_TRAPS}                               ║"
  echo "║ Missing Traps:      ${MISSING_TRAPS}                                ║"
  echo "║ Coverage:           ${coverage}%                              ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo ""

  if [ $MISSING_TRAPS -eq 0 ] && [ $COMPLIANT_COMMANDS -eq 6 ]; then
    echo -e "${GREEN}✓ COMPLIANCE CHECK PASSED${NC}"
    echo "All commands have 100% ERR trap coverage."
    return 0
  else
    echo -e "${RED}✗ COMPLIANCE CHECK FAILED${NC}"
    echo "Some commands are missing ERR trap integration."
    return 1
  fi
}

# Main execution
main() {
  print_header

  # Check each command
  for cmd in plan build debug repair revise research; do
    check_command_compliance "$cmd"
  done

  # Print summary
  print_summary
}

main "$@"
