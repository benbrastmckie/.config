#!/bin/bash
# test_command_references.sh
#
# Validates all markdown reference links in commands and shared documentation.
#
# Usage: ./test_command_references.sh

set -euo pipefail

CLAUDE_DIR="/home/benjamin/.config/.claude"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SHARED_DIR="$COMMANDS_DIR/shared"

TOTAL_LINKS=0
VALID_LINKS=0
BROKEN_LINKS=0
BROKEN_LINK_LIST=()

echo "═══════════════════════════════════════════════════════════"
echo "Reference Validation Test"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Function: validate_link <source-file> <link-text> <link-path>
validate_link() {
  local source_file=$1
  local link_text=$2
  local link_path=$3

  TOTAL_LINKS=$((TOTAL_LINKS + 1))

  # Resolve link path relative to source file directory
  local source_dir=$(dirname "$source_file")
  local resolved_path="$source_dir/$link_path"

  if [ -f "$resolved_path" ]; then
    VALID_LINKS=$((VALID_LINKS + 1))
    echo "  ✓ $link_text → $link_path"
  else
    BROKEN_LINKS=$((BROKEN_LINKS + 1))
    BROKEN_LINK_LIST+=("$source_file: [$link_text]($link_path) → $resolved_path NOT FOUND")
    echo "  ✗ $link_text → $link_path [BROKEN]"
  fi
}

# Test 1: Validate command → shared references
echo "Test 1: Validating command → shared references"
echo "──────────────────────────────────────────────"

for cmd_file in "$COMMANDS_DIR"/*.md; do
  if [ ! -f "$cmd_file" ]; then continue; fi

  cmd_name=$(basename "$cmd_file")
  echo ""
  echo "Checking: $cmd_name"

  # Use grep to extract markdown links to shared/
  grep -oP '\[([^\]]+)\]\(shared/([^)]+)\)' "$cmd_file" 2>/dev/null || true | while read -r match; do
    link_text=$(echo "$match" | grep -oP '\[\K[^\]]+')
    link_path=$(echo "$match" | grep -oP 'shared/\K[^)]+')
    validate_link "$cmd_file" "$link_text" "shared/$link_path"
  done
done

# Test 2: Validate shared → shared cross-references
echo ""
echo ""
echo "Test 2: Validating shared → shared cross-references"
echo "────────────────────────────────────────────────────"

for shared_file in "$SHARED_DIR"/*.md; do
  if [ ! -f "$shared_file" ]; then continue; fi

  shared_name=$(basename "$shared_file")
  echo ""
  echo "Checking: $shared_name"

  # Extract markdown links to other files (skip http/https)
  grep -oP '\[([^\]]+)\]\(([^)]+\.md[^)]*)\)' "$shared_file" 2>/dev/null || true | while read -r match; do
    link_text=$(echo "$match" | grep -oP '\[\K[^\]]+')
    link_path=$(echo "$match" | grep -oP '\(\K[^)]+')

    # Skip external links
    if echo "$link_path" | grep -q '^https\?://'; then
      continue
    fi

    validate_link "$shared_file" "$link_text" "$link_path"
  done
done

# Test 3: Validate shared → command back-references
echo ""
echo ""
echo "Test 3: Validating shared → command back-references"
echo "────────────────────────────────────────────────────"

for shared_file in "$SHARED_DIR"/*.md; do
  if [ ! -f "$shared_file" ]; then continue; fi

  shared_name=$(basename "$shared_file")
  echo ""
  echo "Checking: $shared_name"

  # Look for "Part of: /command" patterns
  if grep -q "Part of.*:.*/" "$shared_file" 2>/dev/null; then
    COMMANDS=$(grep "Part of:" "$shared_file" | grep -oP '/\w+' | tr '\n' ',' | sed 's/,$//')
    echo "  Referenced by: $COMMANDS"
  fi

  # Extract markdown links back to parent directory
  grep -oP '\[([^\]]+)\]\(\.\./([^)]+\.md[^)]*)\)' "$shared_file" 2>/dev/null || true | while read -r match; do
    link_text=$(echo "$match" | grep -oP '\[\K[^\]]+')
    link_path=$(echo "$match" | grep -oP '\(\K[^)]+')
    validate_link "$shared_file" "$link_text" "$link_path"
  done
done

# Test 4: Validate README references
echo ""
echo ""
echo "Test 4: Validating README references"
echo "─────────────────────────────────────"

for readme in "$COMMANDS_DIR/README.md" "$SHARED_DIR/README.md" "$CLAUDE_DIR/lib/README.md"; do
  if [ ! -f "$readme" ]; then continue; fi

  readme_name=$(basename "$(dirname "$readme")")/README.md
  echo ""
  echo "Checking: $readme_name"

  grep -oP '\[([^\]]+)\]\(([^)]+\.md[^)]*)\)' "$readme" 2>/dev/null || true | while read -r match; do
    link_text=$(echo "$match" | grep -oP '\[\K[^\]]+')
    link_path=$(echo "$match" | grep -oP '\(\K[^)]+')

    # Skip external links
    if echo "$link_path" | grep -q '^https\?://'; then
      continue
    fi

    validate_link "$readme" "$link_text" "$link_path"
  done
done

# Summary
echo ""
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Validation Summary"
echo "═══════════════════════════════════════════════════════════"
echo "Total links checked: $TOTAL_LINKS"
echo "Valid links: $VALID_LINKS"
echo "Broken links: $BROKEN_LINKS"
echo ""

if [ $BROKEN_LINKS -gt 0 ]; then
  echo "BROKEN LINKS FOUND:"
  echo "───────────────────"
  for broken in "${BROKEN_LINK_LIST[@]}"; do
    echo "  • $broken"
  done
  echo ""
  echo "RESULT: FAIL"
  exit 1
else
  echo "RESULT: PASS - All reference links valid"
  exit 0
fi
