#!/usr/bin/env bash
# Test: Verify no empty artifact directories after workflow execution
#
# Purpose: Ensure the lazy directory creation pattern is followed.
# Directories should be created ONLY when files are written, never pre-created.
#
# This test fails CI if empty artifact directories are detected.

set -e

CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || echo "$HOME/.config")}"
SPECS_DIR="${CLAUDE_PROJECT_DIR}/.claude/specs"

echo "=== Test: No Empty Artifact Directories ==="
echo ""

# Check if specs directory exists
if [ ! -d "$SPECS_DIR" ]; then
  echo "SKIP: No specs directory found at $SPECS_DIR"
  exit 0
fi

# Find empty artifact subdirectories
# These subdirectory types should NEVER be empty - they should only exist when they contain files
EMPTY_DIRS=""

for subdir_type in reports plans debug summaries outputs; do
  while IFS= read -r dir; do
    if [ -n "$dir" ]; then
      EMPTY_DIRS="${EMPTY_DIRS}${dir}\n"
    fi
  done < <(find "$SPECS_DIR" -type d -name "$subdir_type" -empty 2>/dev/null)
done

if [ -n "$EMPTY_DIRS" ]; then
  echo "ERROR: Empty artifact directories detected:"
  echo ""
  echo -e "$EMPTY_DIRS" | while read -r dir; do
    if [ -n "$dir" ]; then
      echo "  - $dir"
    fi
  done
  echo ""
  echo "This indicates a lazy directory creation violation."
  echo "Directories should be created ONLY when files are written."
  echo ""
  echo "Fix: Ensure agents call ensure_artifact_directory() before writing files."
  echo "     Do NOT pre-create empty directories in commands."
  echo ""
  echo "See: .claude/docs/reference/standards/code-standards.md#directory-creation-anti-patterns"
  exit 1
fi

# Count total topics and artifact directories for visibility
TOPIC_COUNT=$(find "$SPECS_DIR" -maxdepth 1 -type d -name '[0-9]*_*' 2>/dev/null | wc -l)
ARTIFACT_DIR_COUNT=$(find "$SPECS_DIR" -type d \( -name "reports" -o -name "plans" -o -name "debug" -o -name "summaries" -o -name "outputs" \) 2>/dev/null | wc -l)

echo "✓ PASS: No empty artifact directories found"
echo ""
echo "Statistics:"
echo "  - Topic directories: $TOPIC_COUNT"
echo "  - Artifact directories (with files): $ARTIFACT_DIR_COUNT"
echo ""

exit 0
