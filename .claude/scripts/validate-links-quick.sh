#!/bin/bash
# Quick link validation for recently modified files only

set -e

CONFIG_FILE=".claude/scripts/markdown-link-check.json"
DAYS="${1:-7}"  # Default: files modified in last 7 days

echo "Quick Link Validation (files modified in last $DAYS days)"
echo "=========================================================="

# Find recently modified markdown files
readarray -t recent_files < <(
  find .claude/docs .claude/commands .claude/agents README.md docs nvim/docs \
    -name "*.md" -type f -mtime -"$DAYS" 2>/dev/null || true
)

if [[ ${#recent_files[@]} -eq 0 ]]; then
  echo "No recently modified markdown files found"
  exit 0
fi

echo "Checking ${#recent_files[@]} recently modified files..."
echo ""

errors=0
for file in "${recent_files[@]}"; do
  if npx markdown-link-check "$file" --config "$CONFIG_FILE" --quiet; then
    echo "✓ $file"
  else
    echo "✗ $file"
    ((errors++))
  fi
done

echo ""
if [[ $errors -eq 0 ]]; then
  echo "✓ All recent files have valid links"
  exit 0
else
  echo "✗ Found errors in $errors files"
  exit 1
fi
