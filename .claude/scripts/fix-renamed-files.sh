#!/bin/bash
set -e

DIRS=(".claude/docs" ".claude/commands" ".claude/agents")

for dir in "${DIRS[@]}"; do
  if [[ -d "$dir" ]]; then
    echo "Fixing renamed file references in $dir..."

    find "$dir" -name "*.md" -type f -exec sed -i \
      -e 's|command-authoring-guide\.md|command-development-guide.md|g' \
      -e 's|agent-authoring-guide\.md|agent-development-guide.md|g' \
      -e 's|hierarchical_agents\.md|hierarchical-agents.md|g' \
      -e 's|docs/using-agents\.md|docs/guides/using-agents.md|g' \
      -e 's|docs/creating-agents\.md|docs/guides/agent-development-guide.md|g' \
      {} \;
  fi
done

echo "Renamed file reference fixes complete"
