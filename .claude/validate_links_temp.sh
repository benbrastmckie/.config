#!/bin/bash
# Validate markdown links in .claude/docs/

cd .claude/docs || exit 1

broken_count=0
checked_count=0

find . -name "*.md" -type f | while read -r file; do
  # Extract markdown links to .md files
  grep -o '\[.*\](.*\.md[^)]*)' "$file" 2>/dev/null | sed 's/\[.*\](\(.*\.md[^)]*\))/\1/' | while read -r link; do
    # Remove anchor
    target="${link%%#*}"

    # Skip absolute URLs
    [[ "$target" =~ ^https?: ]] && continue

    # Get directory of current file
    dir=$(dirname "$file")

    # Build full path
    if [[ "$target" == /* ]]; then
      fullpath=".${target}"
    else
      fullpath="$dir/$target"
    fi

    # Normalize path
    fullpath=$(cd "$(dirname "$fullpath")" 2>/dev/null && pwd)/$(basename "$fullpath") 2>/dev/null

    checked_count=$((checked_count + 1))

    # Check if file exists
    if [ ! -f "$fullpath" ]; then
      echo "BROKEN: $file -> $target (expected: $fullpath)"
      broken_count=$((broken_count + 1))
    fi
  done
done

echo ""
echo "Validation complete: Checked $checked_count links, found $broken_count broken"
