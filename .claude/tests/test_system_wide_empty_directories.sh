#!/usr/bin/env bash
# test_system_wide_empty_directories.sh
#
# System-wide validation script to detect empty directories in specs/
# Reports any empty subdirectories (excluding .gitkeep files)
#
# Usage: ./test_system_wide_empty_directories.sh
# Exit codes: 0 = no empty dirs found, 1 = empty dirs detected

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SPECS_DIR="${PROJECT_ROOT}/.claude/specs"

# Counters
EMPTY_DIR_COUNT=0
CHECKED_DIR_COUNT=0
TOPIC_COUNT=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "==========================================="
echo "System-Wide Empty Directory Validation"
echo "==========================================="
echo ""
echo "Checking: $SPECS_DIR"
echo ""

# Check if specs directory exists
if [ ! -d "$SPECS_DIR" ]; then
  echo "Warning: Specs directory not found: $SPECS_DIR"
  exit 0
fi

# Find all topic directories (NNN_* pattern)
echo "Scanning topic directories..."
echo ""

for topic_dir in "$SPECS_DIR"/[0-9][0-9][0-9]_*; do
  # Skip if no matching directories found
  [ -d "$topic_dir" ] || continue

  ((TOPIC_COUNT++))
  topic_name=$(basename "$topic_dir")

  # Check standard subdirectories
  for subdir_name in reports plans summaries debug scripts outputs; do
    subdir_path="${topic_dir}/${subdir_name}"

    # Skip if subdirectory doesn't exist
    [ -d "$subdir_path" ] || continue

    ((CHECKED_DIR_COUNT++))

    # Check if directory is empty (excluding .gitkeep and .artifact-registry)
    # Use find to check for files/dirs excluding hidden files
    file_count=$(find "$subdir_path" -mindepth 1 -maxdepth 1 \
      ! -name ".gitkeep" \
      ! -name ".artifact-registry" \
      ! -name ".DS_Store" \
      2>/dev/null | wc -l)

    if [ "$file_count" -eq 0 ]; then
      ((EMPTY_DIR_COUNT++))
      echo -e "${RED}✗${NC} Empty directory: ${topic_name}/${subdir_name}"
    fi
  done
done

echo ""
echo "==========================================="
echo "Validation Results"
echo "==========================================="
echo "Topics scanned:       $TOPIC_COUNT"
echo "Subdirectories checked: $CHECKED_DIR_COUNT"

if [ "$EMPTY_DIR_COUNT" -eq 0 ]; then
  echo -e "${GREEN}Empty directories:     0${NC}"
  echo ""
  echo -e "${GREEN}✓ SUCCESS: No empty directories detected!${NC}"
  echo ""
  echo "Lazy directory creation is working correctly."
  exit 0
else
  echo -e "${RED}Empty directories:     $EMPTY_DIR_COUNT${NC}"
  echo ""
  echo -e "${RED}✗ FAILURE: Found $EMPTY_DIR_COUNT empty directories${NC}"
  echo ""
  echo "Empty directories indicate that lazy creation is not working"
  echo "correctly. Directories should only be created when files are written."
  echo ""
  echo "Troubleshooting steps:"
  echo "1. Check if ensure_artifact_directory() is called before all file writes"
  echo "2. Verify unified-location-detection.sh has lazy creation enabled"
  echo "3. Check command and agent templates for mkdir -p calls"
  exit 1
fi
