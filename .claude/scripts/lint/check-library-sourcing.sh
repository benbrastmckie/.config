#!/usr/bin/env bash
# check-library-sourcing.sh - Linter for bash library sourcing patterns
# Version: 1.0.0
#
# Validates that bash blocks in .claude/commands/ follow the three-tier sourcing pattern:
# - Tier 1: Critical libraries with fail-fast handlers
# - Tier 2: Workflow libraries with graceful degradation
# - Tier 3: Command-specific libraries (optional)
#
# Usage:
#   bash .claude/scripts/lint/check-library-sourcing.sh [file1.md file2.md ...]
#   bash .claude/scripts/lint/check-library-sourcing.sh  # Check all commands
#
# Exit codes:
#   0 - No errors
#   1 - Errors found (violations that must be fixed)

# Colors for output (if terminal supports them)
if [ -t 1 ]; then
  RED='\033[0;31m'
  YELLOW='\033[0;33m'
  GREEN='\033[0;32m'
  NC='\033[0m' # No Color
else
  RED=''
  YELLOW=''
  GREEN=''
  NC=''
fi

# Critical libraries that MUST have fail-fast handlers
CRITICAL_LIBRARIES=(
  "state-persistence.sh"
  "workflow-state-machine.sh"
  "error-handling.sh"
)

# Counters
ERROR_COUNT=0
WARNING_COUNT=0

# Print error
print_error() {
  local file="$1"
  local line_num="$2"
  local message="$3"
  echo -e "${RED}ERROR${NC}: $file:$line_num"
  echo "  $message"
  echo ""
  ERROR_COUNT=$((ERROR_COUNT + 1))
}

# Print warning
print_warning() {
  local file="$1"
  local line_num="$2"
  local message="$3"
  echo -e "${YELLOW}WARNING${NC}: $file:$line_num"
  echo "  $message"
  echo ""
  WARNING_COUNT=$((WARNING_COUNT + 1))
}

# Check for bare error suppression on critical libraries
check_bare_suppression() {
  local file="$1"

  # Use grep to find lines with source and 2>/dev/null but no || handler
  # Pattern: source ... critical_lib ... 2>/dev/null without ||
  for lib in "${CRITICAL_LIBRARIES[@]}"; do
    # Find lines that source the library with 2>/dev/null but no fail-fast handler
    local results
    results=$(grep -n "source.*${lib}.*2>/dev/null" "$file" 2>/dev/null || true)

    if [ -n "$results" ]; then
      while IFS=: read -r line_num line_content; do
        # Check if this line has a fail-fast handler (|| { or || exit)
        if ! echo "$line_content" | grep -qE '\|\|'; then
          print_error "$file" "$line_num" \
            "Bare error suppression on critical library: $lib"
          echo "  Found:   $line_content"
          echo "  Fix:     Add fail-fast handler: || { echo \"ERROR: ...\"; exit 1; }"
        fi
      done <<< "$results"
    fi
  done
}

# Check for function calls without defensive checks
check_defensive_checks() {
  local file="$1"

  # Functions that need defensive type checks
  local critical_funcs=(
    "save_completed_states_to_state"
    "append_workflow_state"
    "load_workflow_state"
    "init_workflow_state"
  )

  for func in "${critical_funcs[@]}"; do
    # Find lines that call the function (as standalone command, not in type check)
    local func_calls
    func_calls=$(grep -nE "^[[:space:]]*${func}[[:space:]]|^[[:space:]]*${func}\$" "$file" 2>/dev/null || true)

    if [ -n "$func_calls" ]; then
      while IFS=: read -r line_num _; do
        # Check if there's a defensive type check within 10 lines before
        local start_line=$((line_num - 10))
        [ "$start_line" -lt 1 ] && start_line=1

        local context
        context=$(sed -n "${start_line},${line_num}p" "$file" 2>/dev/null || true)

        if ! echo "$context" | grep -qE "type[[:space:]]+${func}"; then
          print_warning "$file" "$line_num" \
            "Missing defensive check before $func"
          echo "  Fix: Add 'if ! type $func &>/dev/null; then exit 1; fi'"
        fi
      done <<< "$func_calls"
    fi
  done
}

# Main function
main() {
  local files=("$@")

  # If no files specified, check all commands
  if [ ${#files[@]} -eq 0 ]; then
    # Find project root
    local claude_dir
    if [ -d ".claude/commands" ]; then
      claude_dir=".claude"
    elif [ -d "../.claude/commands" ]; then
      claude_dir="../.claude"
    else
      echo "ERROR: Cannot find .claude/commands directory" >&2
      exit 1
    fi

    # Get all command files
    while IFS= read -r -d '' f; do
      files+=("$f")
    done < <(find "$claude_dir/commands" -name "*.md" -type f -print0 2>/dev/null)

    if [ ${#files[@]} -eq 0 ]; then
      echo "No command files found to check"
      exit 0
    fi
  fi

  echo "Checking library sourcing patterns in ${#files[@]} file(s)..."
  echo ""

  for file in "${files[@]}"; do
    if [ ! -f "$file" ]; then
      echo "WARNING: File not found: $file"
      continue
    fi

    echo "Checking: $file"

    check_bare_suppression "$file"
    check_defensive_checks "$file"
  done

  echo ""
  echo "=========================================="
  echo "SUMMARY"
  echo "=========================================="
  echo -e "Errors:   ${RED}${ERROR_COUNT}${NC}"
  echo -e "Warnings: ${YELLOW}${WARNING_COUNT}${NC}"
  echo ""

  if [ "$ERROR_COUNT" -gt 0 ]; then
    echo -e "${RED}FAILED${NC}: $ERROR_COUNT error(s) must be fixed"
    exit 1
  elif [ "$WARNING_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}PASSED${NC} with $WARNING_COUNT warning(s)"
    exit 0
  else
    echo -e "${GREEN}PASSED${NC}: All checks passed"
    exit 0
  fi
}

main "$@"
