#!/usr/bin/env bash
# lint-array-iteration.sh - Linter for array iteration anti-patterns
# Version: 1.0.0
#
# Detects preprocessing-unsafe indirect array expansion syntax ${!ARRAY[@]}
# that causes "bad substitution" errors during bash preprocessing.
#
# Usage:
#   bash .claude/scripts/lint/lint-array-iteration.sh [file1.md file2.md ...]
#   bash .claude/scripts/lint/lint-array-iteration.sh  # Check all commands
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

# Check a single file
check_file() {
  local file="$1"

  # Determine severity based on file type
  local severity="ERROR"
  if [[ "$file" =~ \.claude/agents/ ]]; then
    severity="WARNING"
  fi

  # Search for indirect array expansion pattern
  while IFS= read -r line; do
    local line_num=$(echo "$line" | cut -d: -f1)
    local content=$(echo "$line" | cut -d: -f2-)

    # Check for ${!ARRAY[@]} or ${!ARRAY[*]} patterns
    if [[ "$content" =~ \$\{![^}]*\[[@*]\]\} ]]; then
      local message="Indirect array expansion '${!ARRAY[@]}' causes preprocessing corruption"
      message="$message\n  Anti-pattern: ${content}"
      message="$message\n  Fix: Use 'for i in \$(seq 0 \$((#\${#ARRAY[@]} - 1)))' instead"
      message="$message\n  See: .claude/docs/troubleshooting/bash-tool-limitations.md#array-iteration-patterns"

      if [ "$severity" = "ERROR" ]; then
        print_error "$file" "$line_num" "$message"
      else
        print_warning "$file" "$line_num" "$message"
      fi
    fi
  done < <(grep -n '\${!.*\[@\]\}\|\${!.*\[\*\]\}' "$file" 2>/dev/null || true)
}

# Main execution
main() {
  local files=("$@")

  # If no files specified, check all command files
  if [ ${#files[@]} -eq 0 ]; then
    files=(.claude/commands/*.md)
  fi

  echo "Checking ${#files[@]} files for array iteration anti-patterns..."
  echo ""

  for file in "${files[@]}"; do
    if [ ! -f "$file" ]; then
      continue
    fi

    check_file "$file"
  done

  # Print summary
  echo "----------------------------------------"
  if [ $ERROR_COUNT -eq 0 ] && [ $WARNING_COUNT -eq 0 ]; then
    echo -e "${GREEN}PASS${NC}: No array iteration anti-patterns found"
    exit 0
  else
    echo -e "${RED}FAIL${NC}: Found $ERROR_COUNT errors, $WARNING_COUNT warnings"
    echo ""
    echo "Array iteration anti-pattern detected!"
    echo "Replace indirect expansion with seq-based iteration:"
    echo "  BAD:  for i in \"\${!ARRAY[@]}\"; do"
    echo "  GOOD: for i in \$(seq 0 \$((#\${#ARRAY[@]} - 1))); do"
    echo ""
    echo "See documentation:"
    echo "  .claude/docs/troubleshooting/bash-tool-limitations.md#array-iteration-patterns"

    # Return error only if ERROR severity violations found
    if [ $ERROR_COUNT -gt 0 ]; then
      exit 1
    else
      exit 0
    fi
  fi
}

main "$@"
