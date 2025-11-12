#!/bin/bash
# Convert absolute paths to relative paths in markdown links

set -e

# Pattern: /home/benjamin/.config/CLAUDE.md -> ../CLAUDE.md (from .claude/ subdirs)
# Pattern: /home/benjamin/.config/nvim/CLAUDE.md -> ../nvim/CLAUDE.md

find .claude/docs .claude/commands .claude/agents -name "*.md" -type f 2>/dev/null | while read -r file; do
  # Calculate depth (number of parent directories to reach .config/)
  depth=$(echo "$file" | grep -o "/" | wc -l)
  depth=$((depth - 1))  # Subtract 1 for .config itself

  # Build relative prefix (../ repeated)
  prefix=""
  for ((i=0; i<depth; i++)); do
    prefix="../$prefix"
  done

  # Replace absolute paths with relative
  sed -i "s|](/home/benjamin/\\.config/|](${prefix}|g" "$file"
  sed -i "s|(\\/home/benjamin/\\.config/|(${prefix}|g" "$file"
done

echo "Absolute to relative path conversion complete"
