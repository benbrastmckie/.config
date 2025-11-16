#!/bin/bash
# Migration script to update sub-supervisor-template.md references
# From: .claude/agents/templates/sub-supervisor-template.md
# To: .claude/agents/templates/sub-supervisor-template.md

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

OLD_PATH=".claude/agents/templates/sub-supervisor-template.md"
NEW_PATH=".claude/agents/templates/sub-supervisor-template.md"

DRY_RUN=0
VERBOSE=0

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --verbose|-v)
      VERBOSE=1
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [--dry-run] [--verbose]"
      echo ""
      echo "Options:"
      echo "  --dry-run    Show what would be changed without modifying files"
      echo "  --verbose    Show detailed progress"
      echo "  --help       Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

cd "$PROJECT_ROOT"

echo "Template Reference Migration Script"
echo "===================================="
echo "Old path: $OLD_PATH"
echo "New path: $NEW_PATH"
echo ""

if [[ $DRY_RUN -eq 1 ]]; then
  echo "DRY RUN MODE - No files will be modified"
  echo ""
fi

# Find all files with references
echo "Searching for files with references..."
mapfile -t FILES < <(grep -rl "$OLD_PATH" . \
  --include="*.md" \
  --include="*.sh" \
  --exclude-dir=".git" \
  --exclude-dir="archive" \
  2>/dev/null)

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "No references found. Migration complete!"
  exit 0
fi

echo "Found ${#FILES[@]} files with references"
echo ""

UPDATED_COUNT=0
ERROR_COUNT=0

for file in "${FILES[@]}"; do
  # Count occurrences in this file
  COUNT=$(grep -c "$OLD_PATH" "$file" 2>/dev/null || true)

  if [[ $COUNT -eq 0 ]]; then
    continue
  fi

  if [[ $VERBOSE -eq 1 ]] || [[ $DRY_RUN -eq 1 ]]; then
    echo "File: $file ($COUNT occurrence(s))"
  fi

  if [[ $DRY_RUN -eq 0 ]]; then
    # Perform the replacement
    if sed -i.bak "s|$OLD_PATH|$NEW_PATH|g" "$file" && rm -f "${file}.bak"; then
      UPDATED_COUNT=$((UPDATED_COUNT + 1))
      [[ $VERBOSE -eq 1 ]] && echo "  ✓ Updated"
    else
      ERROR_COUNT=$((ERROR_COUNT + 1))
      echo "  ✗ Error updating $file"
    fi
  else
    # Dry run - show what would change
    echo "  Would replace $COUNT occurrence(s)"
    if [[ $VERBOSE -eq 1 ]]; then
      grep -n "$OLD_PATH" "$file" | head -3
    fi
  fi
done

echo ""
echo "Summary"
echo "======="
if [[ $DRY_RUN -eq 1 ]]; then
  echo "Files that would be updated: ${#FILES[@]}"
else
  echo "Files updated: $UPDATED_COUNT"
  echo "Errors: $ERROR_COUNT"

  # Verification
  echo ""
  echo "Verification"
  echo "============"
  REMAINING=$(grep -r "$OLD_PATH" . \
    --include="*.md" \
    --include="*.sh" \
    --exclude-dir=".git" \
    --exclude-dir="archive" \
    2>/dev/null | wc -l)

  if [[ $REMAINING -eq 0 ]]; then
    echo "✓ All references successfully updated"
  else
    echo "⚠ Warning: $REMAINING reference(s) still remain"
    echo ""
    echo "Remaining references:"
    grep -r "$OLD_PATH" . \
      --include="*.md" \
      --include="*.sh" \
      --exclude-dir=".git" \
      --exclude-dir="archive" \
      2>/dev/null | head -10
  fi
fi

exit 0
