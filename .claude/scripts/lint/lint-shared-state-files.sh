#!/usr/bin/env bash
# lint-shared-state-files.sh - Detect shared state ID file anti-pattern
# Version: 1.0.0
#
# Detects the shared state ID file anti-pattern that causes concurrent execution
# interference. Commands must use state file discovery pattern instead.
#
# Usage:
#   bash lint-shared-state-files.sh <file1> <file2> ...
#   bash lint-shared-state-files.sh .claude/commands/*.md
#
# Exit codes:
#   0 - No violations found
#   1 - ERROR-level violations found
#   2 - Script error
#
# See: .claude/docs/reference/standards/concurrent-execution-safety.md

set -euo pipefail

# Colors for output (with terminal detection)
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  NC='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  NC=''
fi

# Patterns to detect shared state ID files
PATTERNS=(
  'STATE_ID_FILE=.*state_id\.txt'
  'echo.*>.*state_id\.txt'
  'cat.*state_id\.txt'
  '\$\(cat.*state_id\.txt'
)

# Violation tracking
VIOLATIONS_FOUND=0
FILES_CHECKED=0
FILES_WITH_VIOLATIONS=0

# Check if any files provided
if [ $# -eq 0 ]; then
  printf "%b%s%b: No files specified\n" "${RED}" "ERROR" "${NC}" >&2
  printf "Usage: bash lint-shared-state-files.sh <file1> <file2> ...\n" >&2
  exit 2
fi

# Check each file
for file in "$@"; do
  # Skip non-existent files
  if [ ! -f "$file" ]; then
    continue
  fi

  FILES_CHECKED=$((FILES_CHECKED + 1))

  FILE_HAS_VIOLATION=false

  # Check each pattern
  for pattern in "${PATTERNS[@]}"; do
    # Search for pattern in file
    matches=$(grep -n -E "$pattern" "$file" 2>/dev/null || true)

    if [ -n "$matches" ]; then
      # First violation for this file
      if [ "$FILE_HAS_VIOLATION" = false ]; then
        printf "%b%s%b: Shared state ID file anti-pattern detected in %s\n" "${RED}" "ERROR" "${NC}" "$file"
        FILE_HAS_VIOLATION=true
        FILES_WITH_VIOLATIONS=$((FILES_WITH_VIOLATIONS + 1))
      fi

      # Report each violation
      while IFS= read -r match; do
        line_num=$(echo "$match" | cut -d: -f1)
        line_content=$(echo "$match" | cut -d: -f2-)
        printf "  Line %s: %s\n" "$line_num" "$line_content"
        VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
      done <<< "$matches"
    fi
  done

  if [ "$FILE_HAS_VIOLATION" = true ]; then
    printf "\n"
    printf "  Fix: Use concurrent-safe pattern:\n"
    printf "    Block 1: WORKFLOW_ID=\$(generate_unique_workflow_id \"command_name\")\n"
    printf "    Block 2+: STATE_FILE=\$(discover_latest_state_file \"command_name\")\n"
    printf "\n"
    printf "  See: .claude/docs/reference/standards/concurrent-execution-safety.md\n"
    printf "\n"
  fi
done

# Summary
if [ $FILES_CHECKED -eq 0 ]; then
  printf "%b%s%b: No files checked (all files non-existent or inaccessible)\n" "${YELLOW}" "WARNING" "${NC}" >&2
  exit 0
fi

if [ $VIOLATIONS_FOUND -eq 0 ]; then
  printf "%b✓%b Concurrent execution safety: No shared state ID files detected (%d files checked)\n" "${GREEN}" "${NC}" "$FILES_CHECKED"
  exit 0
else
  printf "%b✗%b Concurrent execution safety: %d violation(s) in %d file(s)\n" "${RED}" "${NC}" "$VIOLATIONS_FOUND" "$FILES_WITH_VIOLATIONS"
  printf "\n"
  printf "SUMMARY:\n"
  printf "  Files checked: %d\n" "$FILES_CHECKED"
  printf "  Files with violations: %d\n" "$FILES_WITH_VIOLATIONS"
  printf "  Total violations: %d\n" "$VIOLATIONS_FOUND"
  printf "\n"
  printf "ACTION: Update commands to use concurrent-safe state file discovery pattern\n"
  exit 1
fi
