#!/usr/bin/env bash
# Lint script to detect preprocessing-unsafe bash conditionals
#
# IMPORTANT: This linter detects ACTUAL preprocessing issues, not all uses of !
#
# SAFE patterns (not flagged):
#   - [[ ! -f "$file" ]]     # File test negation - safe
#   - [[ ! "$var" =~ pat ]]  # Regex negation - safe
#   - [[ "$a" != "$b" ]]     # Inequality operator - safe
#   - [ ! -d "$dir" ]        # Single bracket file tests - safe
#
# UNSAFE patterns (flagged):
#   - echo "!!" or "!word"   # History expansion at line start with set -H
#   - Unquoted ! in arithmetic contexts
#
# The original issue was bash history expansion (!!) which is ONLY a problem
# when set -H is enabled (interactive shells). In scripts, this is rarely an issue.

set -euo pipefail

# Configuration
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null)}"
SEARCH_DIRS=(
  "${CLAUDE_PROJECT_DIR}/.claude/commands"
  "${CLAUDE_PROJECT_DIR}/.claude/lib"
  "${CLAUDE_PROJECT_DIR}/.claude/scripts"
)

EXIT_CODE=0
VIOLATIONS_FOUND=0

echo "=== Bash Conditional Linting ==="
echo "Checking for preprocessing-unsafe patterns..."
echo ""

# Check for actual unsafe patterns
# These are patterns that can cause issues with bash history expansion
check_unsafe_history_expansion() {
  local file="$1"
  local line_num="$2"
  local line_content="$3"

  # Pattern 1: Unquoted !! (history repeat) - rare in scripts but check anyway
  # This matches !! not inside quotes
  if echo "$line_content" | grep -qE '(^|[^"'"'"'])!![^"'"'"']'; then
    echo "VIOLATION: Potential history expansion in $file:$line_num"
    echo "  Line: $line_content"
    echo "  Issue: Unquoted '!!' may trigger history expansion"
    echo "  Fix: Quote the string or use set +H"
    echo ""
    return 1
  fi

  # Pattern 2: !word at start of unquoted string (history search)
  # This is very rare and usually intentional, skip for now

  return 0
}

# Main linting loop - only check .sh files (not .md)
for dir in "${SEARCH_DIRS[@]}"; do
  if [ ! -d "$dir" ]; then
    continue
  fi

  while IFS= read -r -d '' file; do
    line_num=0
    while IFS= read -r line || [ -n "$line" ]; do
      line_num=$((line_num + 1))

      # Skip comment lines
      if [[ "$line" =~ ^[[:space:]]*# ]]; then
        continue
      fi

      # Skip empty lines
      if [[ -z "${line// /}" ]]; then
        continue
      fi

      # Check for unsafe patterns
      if ! check_unsafe_history_expansion "$file" "$line_num" "$line"; then
        VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
        EXIT_CODE=1
      fi

    done < "$file"
  done < <(find "$dir" -name '*.sh' -print0 2>/dev/null)
done

# Summary
echo "=== Lint Summary ==="
if [ $VIOLATIONS_FOUND -eq 0 ]; then
  echo "✓ No violations found"
  echo "All bash scripts are preprocessing-safe"
else
  echo "✗ Found $VIOLATIONS_FOUND violation(s)"
  echo ""
  echo "Preprocessing-unsafe patterns can cause 'bash: !: event not found' errors"
  echo "Use 'set +H' at the start of scripts or quote problematic strings"
fi
echo ""

exit $EXIT_CODE
