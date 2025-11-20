#!/bin/bash
# Validate markdown links in active documentation

set -e

CONFIG_FILE=".claude/scripts/markdown-link-check.json"
OUTPUT_DIR=".claude/tmp/link-validation"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="$OUTPUT_DIR/validation_${TIMESTAMP}.log"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Markdown Link Validation"
echo "========================"
echo "Started: $(date)"
echo "Config: $CONFIG_FILE"
echo "Output: $OUTPUT_FILE"
echo ""

# Directories to check (active documentation only)
DIRS=(
  ".claude/docs"
  ".claude/commands"
  ".claude/agents"
  "README.md"
  "docs"
  "nvim/docs"
)

total_files=0
total_errors=0
files_with_errors=0

for dir in "${DIRS[@]}"; do
  if [[ -e "$dir" ]]; then
    echo -e "${YELLOW}Checking: $dir${NC}"

    if [[ -f "$dir" ]]; then
      # Single file
      files=("$dir")
    else
      # Directory
      readarray -t files < <(find "$dir" -name "*.md" -type f)
    fi

    for file in "${files[@]}"; do
      # Skip specs and archive directories
      if [[ "$file" =~ /specs/ ]] || [[ "$file" =~ /archive/ ]]; then
        continue
      fi

      ((total_files++))

      # Run link check
      if npx markdown-link-check "$file" --config "$CONFIG_FILE" >> "$OUTPUT_FILE" 2>&1; then
        echo -e "  ${GREEN}✓${NC} $file"
      else
        echo -e "  ${RED}✗${NC} $file"
        ((total_errors++))
        ((files_with_errors++))
      fi
    done
  fi
done

echo ""
echo "Summary"
echo "======="
echo "Files checked: $total_files"
echo "Files with errors: $files_with_errors"

if [[ $total_errors -eq 0 ]]; then
  echo -e "${GREEN}✓ All links valid!${NC}"
  exit 0
else
  echo -e "${RED}✗ Found $total_errors broken links${NC}"
  echo "See details in: $OUTPUT_FILE"
  exit 1
fi
