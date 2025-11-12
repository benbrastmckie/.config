#!/bin/bash
# Fix duplicate absolute paths in active documentation only

set -e

DIRS=(
  ".claude/docs"
  ".claude/commands"
  ".claude/agents"
)

for dir in "${DIRS[@]}"; do
  if [[ -d "$dir" ]]; then
    echo "Processing $dir..."
    find "$dir" -name "*.md" -type f -exec sed -i \
      's|/home/benjamin/\.config/home/benjamin/\.config/|/home/benjamin/.config/|g' \
      {} \;
  fi
done

echo "Duplicate path fixes complete"
