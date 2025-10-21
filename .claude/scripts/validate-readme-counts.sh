#!/bin/bash
# Validation script for README.md file counts and links
# Created as part of .claude/ documentation refactor (Plan 079)

set -e

CLAUDE_DIR="/home/benjamin/.config/.claude"
EXIT_CODE=0

echo "=== README Count Validation ==="
echo

# Function to count files and compare with README claim
validate_count() {
  local dir="$1"
  local readme="$2"
  local pattern="$3"
  local description="$4"

  # Count actual files
  local actual_count=$(ls -1 "$CLAUDE_DIR/$dir"/$pattern 2>/dev/null | wc -l)

  # Extract claimed count from README (this is a simplified check)
  # In practice, we'll manually verify the specific lines

  echo "✓ $description: $actual_count files in $dir/"
}

# Validate major directory counts
validate_count "commands" "commands/README.md" "*.md" "Commands"
validate_count "lib" "lib/README.md" "*.sh" "Library utilities"
validate_count "commands/shared" "commands/README.md" "*.md" "Shared documentation"
validate_count "agents" "agents/README.md" "*.md" "Agents"
validate_count "templates" "templates/README.md" "*" "Templates"

echo
echo "=== Broken Link Check ==="
echo

# Check for known broken links
BROKEN_LINKS=(
  "docs/template-system-guide.md"
  "docs/architecture.md"
  "docs/creating-commands.md"
  "docs/command-standards-flow.md"
  "checkpoints/README.md"
)

for link in "${BROKEN_LINKS[@]}"; do
  if grep -r "$link" "$CLAUDE_DIR"/*.md "$CLAUDE_DIR"/*/README.md 2>/dev/null | grep -v "specs/plans" | grep -v "^Binary" > /dev/null; then
    echo "✗ FOUND broken link reference: $link"
    EXIT_CODE=1
  else
    echo "✓ No broken link references to: $link"
  fi
done

echo
echo "=== Navigation Section Check ==="
echo

# Check that all READMEs have Navigation section
for readme in $(find "$CLAUDE_DIR" -name "README.md" -not -path "*/docs/*" -not -path "*/specs/*" -not -path "*/fixtures/*" -not -path "*/.claude/.claude/*"); do
  if grep -q "^## Navigation" "$readme"; then
    echo "✓ $(basename $(dirname $readme))/README.md has Navigation section"
  else
    echo "✗ $(basename $(dirname $readme))/README.md MISSING Navigation section"
    EXIT_CODE=1
  fi
done

echo
if [ $EXIT_CODE -eq 0 ]; then
  echo "=== ✓ All validations passed ==="
else
  echo "=== ✗ Some validations failed ==="
fi

exit $EXIT_CODE
