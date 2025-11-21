#!/usr/bin/env bash
# Lint script to detect preprocessing-unsafe bash conditionals
# Detects patterns like: if [[ ! condition ]]
# These are unsafe because bash preprocessing interprets ! before runtime

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

# Pattern 1: if [[ ! with negated test
# UNSAFE: if [[ ! "$VAR" = value ]]
# SAFE: [[ "$VAR" = value ]]; IS_MATCH=$?; if [ $IS_MATCH -ne 0 ]
check_negated_double_bracket() {
  local file="$1"
  local line_num="$2"
  local line_content="$3"

  # Check if line contains: if [[ !
  if echo "$line_content" | grep -q 'if \[\[.*!'; then
    echo "VIOLATION: Unsafe negated conditional in $file:$line_num"
    echo "  Line: $line_content"
    echo "  Issue: '!' in [[ ]] is interpreted during preprocessing, before runtime"
    echo "  Fix: Use exit code capture pattern:"
    echo "    [[ \"\$VAR\" = /* ]]"
    echo "    IS_MATCH=\$?"
    echo "    if [ \$IS_MATCH -ne 0 ]; then"
    echo ""
    return 1
  fi
  return 0
}

# Pattern 2: if [ ! with file tests (these are safe but document for consistency)
# These are actually safe but we want to document them
check_single_bracket_negation() {
  local file="$1"
  local line_num="$2"
  local line_content="$3"

  # Check if line contains: if [ ! -f or if [ ! -d
  if echo "$line_content" | grep -qE 'if \[ !.*-[fdrwxe]'; then
    # This is actually SAFE - file test operators with [ ] work fine
    # But document for awareness
    return 0
  fi
  return 0
}

# Main linting loop
for dir in "${SEARCH_DIRS[@]}"; do
  if [ ! -d "$dir" ]; then
    continue
  fi

  while IFS= read -r file; do
    line_num=0
    while IFS= read -r line; do
      ((line_num++))

      # Skip comment lines
      if echo "$line" | grep -q '^[[:space:]]*#'; then
        continue
      fi

      # Check for unsafe patterns
      if ! check_negated_double_bracket "$file" "$line_num" "$line"; then
        ((VIOLATIONS_FOUND++))
        EXIT_CODE=1
      fi

    done < "$file"
  done < <(find "$dir" -name '*.sh' -o -name '*.md' 2>/dev/null)
done

# Summary
echo "=== Lint Summary ==="
if [ $VIOLATIONS_FOUND -eq 0 ]; then
  echo "✓ No violations found"
  echo "All bash conditionals are preprocessing-safe"
else
  echo "✗ Found $VIOLATIONS_FOUND violation(s)"
  echo ""
  echo "Preprocessing-unsafe conditionals can cause 'bash: !: event not found' errors"
  echo "Use the exit code capture pattern documented in:"
  echo "  .claude/docs/troubleshooting/bash-tool-limitations.md"
fi
echo ""

exit $EXIT_CODE
