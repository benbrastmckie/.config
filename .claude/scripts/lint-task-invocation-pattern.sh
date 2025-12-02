#!/usr/bin/env bash
# lint-task-invocation-pattern.sh
#
# Linter to detect incorrect Task invocation patterns in command and agent files.
# Enforces the imperative "EXECUTE NOW: USE the Task tool" pattern.
#
# Usage:
#   bash lint-task-invocation-pattern.sh [--staged] [file...]
#
# Exit Codes:
#   0 - No violations found
#   1 - ERROR-level violations found (naked Task blocks or instructional text)
#
# Patterns Detected:
#   1. Naked Task blocks (Task { without EXECUTE NOW within 5 lines before)
#   2. Instructional text ("Use the Task tool to invoke..." without actual Task block)
#   3. Incomplete EXECUTE NOW (missing "USE the Task tool")

set -e

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_LIB="${SCRIPT_DIR}/../lib"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
ERROR_COUNT=0
WARN_COUNT=0

# Parse arguments
STAGED_MODE=false
FILES=()

for arg in "$@"; do
  case "$arg" in
    --staged)
      STAGED_MODE=true
      ;;
    *)
      FILES+=("$arg")
      ;;
  esac
done

# Get files to check
if [ "$STAGED_MODE" = true ]; then
  # Check only staged files
  mapfile -t FILES < <(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(md|sh)$' || true)
fi

# If no files specified, check all command and agent files
if [ ${#FILES[@]} -eq 0 ]; then
  mapfile -t FILES < <(find "${SCRIPT_DIR}/../commands" "${SCRIPT_DIR}/../agents" -name "*.md" 2>/dev/null || true)
fi

# Function to check a file for violations
check_file() {
  local file="$1"
  local basename_file=$(basename "$file")

  # Skip README files and documentation files
  if [[ "$basename_file" == "README.md" ]] || [[ "$file" =~ /docs/ ]]; then
    return 0
  fi

  local file_errors=0

  # Pattern 1: Find Task blocks and check for EXECUTE NOW within 5 lines before
  local task_line_numbers=$(grep -n '^Task {' "$file" 2>/dev/null | cut -d: -f1 || true)

  for line_num in $task_line_numbers; do
    # Check lines [line_num-5 to line_num-1] for EXECUTE NOW
    local start_line=$((line_num - 5))
    if [ $start_line -lt 1 ]; then
      start_line=1
    fi

    # Check if EXECUTE NOW with "Task tool" is present
    if sed -n "${start_line},$((line_num-1))p" "$file" | grep -q 'EXECUTE.*NOW.*Task tool' 2>/dev/null; then
      continue
    fi

    # Also check for conditional EXECUTE (EXECUTE IF)
    if sed -n "${start_line},$((line_num-1))p" "$file" | grep -q 'EXECUTE IF.*Task tool' 2>/dev/null; then
      continue
    fi

    # No directive found
    echo -e "${RED}ERROR${NC}: $file:$line_num - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)"
    ERROR_COUNT=$((ERROR_COUNT + 1))
    file_errors=$((file_errors + 1))
  done

  # Pattern 2: Find instructional text without actual Task blocks nearby
  local instructional_lines=$(grep -n 'Use the Task tool to invoke' "$file" 2>/dev/null | cut -d: -f1 || true)

  for line_num in $instructional_lines; do
    # Check if there's a Task block within 10 lines after this line
    local end_line=$((line_num + 10))

    if sed -n "${line_num},${end_line}p" "$file" | grep -q '^Task {' 2>/dev/null; then
      continue
    fi

    # No Task block found
    echo -e "${RED}ERROR${NC}: $file:$line_num - Instructional text pattern without actual Task invocation"
    ERROR_COUNT=$((ERROR_COUNT + 1))
    file_errors=$((file_errors + 1))
  done

  # Pattern 3: Find EXECUTE NOW without "USE the Task tool"
  local incomplete_execute=$(grep -n 'EXECUTE NOW.*Invoke' "$file" 2>/dev/null | \
                            grep -v 'USE the Task tool' || true)

  if [ -n "$incomplete_execute" ]; then
    while IFS= read -r line; do
      local line_num=$(echo "$line" | cut -d: -f1)
      echo -e "${RED}ERROR${NC}: $file:$line_num - Incomplete EXECUTE NOW (missing 'USE the Task tool')"
      ERROR_COUNT=$((ERROR_COUNT + 1))
      file_errors=$((file_errors + 1))
    done <<< "$incomplete_execute"
  fi

  if [ $file_errors -gt 0 ]; then
    return 1
  else
    return 0
  fi
}

# Main execution
total_files=0
failed_files=0

for file in "${FILES[@]}"; do
  if [ ! -f "$file" ]; then
    continue
  fi

  total_files=$((total_files + 1))

  # Don't let check_file exit code trigger set -e
  if ! check_file "$file"; then
    failed_files=$((failed_files + 1))
  fi
done

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Task Invocation Pattern Linter Results"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Files checked: $total_files"
echo "Files with errors: $failed_files"
echo ""
echo -e "${RED}ERROR violations: $ERROR_COUNT${NC}"
echo -e "${YELLOW}WARN violations: $WARN_COUNT${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Exit with error if violations found
if [ "$ERROR_COUNT" -gt 0 ]; then
  echo ""
  echo "Fix ERROR-level violations before committing."
  exit 1
fi

exit 0
