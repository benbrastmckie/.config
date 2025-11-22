#!/usr/bin/env bash
# rename_no_name_directory.sh - Interactive helper to rename no_name_error topic directories
# Purpose: Fix topic naming failures by renaming directories to semantic names
# Usage: rename_no_name_directory.sh <no_name_error_directory> <new_name>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source required libraries
source "$PROJECT_ROOT/.claude/lib/plan/topic-utils.sh" 2>/dev/null || {
  echo "ERROR: Cannot load topic-utils library"
  exit 1
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Usage information
usage() {
  cat <<EOF
Usage: $(basename "$0") <no_name_error_directory> <new_name>

Rename a no_name_error topic directory to a semantic name.

ARGUMENTS:
  no_name_error_directory  Path to directory ending in _no_name_error
  new_name                 New semantic name (5-40 chars, a-z0-9_ only)

EXAMPLES:
  # Rename topic 867_no_name_error to 867_jwt_auth_fix
  $0 /path/to/specs/867_no_name_error jwt_auth_fix

  # Rename with relative path
  $0 .claude/specs/867_no_name_error oauth_integration

VALIDATION:
  - New name must match format: ^[a-z0-9_]{5,40}$
  - Directory must exist and end with _no_name_error
  - Preserves topic number from original directory

EXIT CODES:
  0  Rename successful
  1  Validation error or rename failed
EOF
}

# Check arguments
if [ $# -ne 2 ]; then
  echo "ERROR: Expected 2 arguments, got $#"
  echo ""
  usage
  exit 1
fi

NO_NAME_DIR="$1"
NEW_NAME="$2"

# Validate no_name directory exists
if [ ! -d "$NO_NAME_DIR" ]; then
  echo -e "${RED}ERROR: Directory not found: $NO_NAME_DIR${NC}"
  exit 1
fi

# Validate directory ends with _no_name_error
if [[ ! "$NO_NAME_DIR" =~ _no_name_error$ ]]; then
  echo -e "${RED}ERROR: Directory must end with _no_name_error${NC}"
  echo "Got: $NO_NAME_DIR"
  exit 1
fi

# Validate new name format
if ! validate_topic_name_format "$NEW_NAME"; then
  echo -e "${RED}ERROR: Invalid topic name format: $NEW_NAME${NC}"
  echo ""
  echo "Format requirements:"
  echo "  - Lowercase letters (a-z), numbers (0-9), underscores (_) only"
  echo "  - Length: 5-40 characters"
  echo "  - No consecutive underscores"
  echo "  - No leading/trailing underscores"
  echo ""
  echo "Examples of valid names:"
  echo "  - jwt_auth_fix"
  echo "  - oauth_integration"
  echo "  - database_migration"
  exit 1
fi

# Extract topic number from directory name
TOPIC_NUM=$(basename "$NO_NAME_DIR" | sed 's/_no_name_error$//')

# Validate topic number format (NNN)
if [[ ! "$TOPIC_NUM" =~ ^[0-9]{3}$ ]]; then
  echo -e "${RED}ERROR: Could not extract valid topic number from: $NO_NAME_DIR${NC}"
  echo "Expected format: NNN_no_name_error"
  exit 1
fi

# Build new directory path
PARENT_DIR=$(dirname "$NO_NAME_DIR")
NEW_DIR="${PARENT_DIR}/${TOPIC_NUM}_${NEW_NAME}"

# Check if new directory already exists
if [ -d "$NEW_DIR" ]; then
  echo -e "${RED}ERROR: Target directory already exists: $NEW_DIR${NC}"
  exit 1
fi

# Display rename plan
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Topic Directory Rename Plan"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Topic Number: $TOPIC_NUM"
echo "Current Name: $(basename "$NO_NAME_DIR")"
echo "New Name:     ${TOPIC_NUM}_${NEW_NAME}"
echo ""
echo "From: $NO_NAME_DIR"
echo "To:   $NEW_DIR"
echo ""

# Check directory contents
CONTENT_COUNT=$(find "$NO_NAME_DIR" -type f 2>/dev/null | wc -l)
echo "Directory contains: $CONTENT_COUNT file(s)"
if [ $CONTENT_COUNT -gt 0 ]; then
  echo ""
  echo "Files to be moved:"
  find "$NO_NAME_DIR" -type f 2>/dev/null | sed 's/^/  - /'
  echo ""
fi

# Confirm rename
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
read -p "Proceed with rename? [y/N] " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Rename cancelled."
  exit 0
fi

# Perform rename
echo ""
echo "Renaming directory..."
if mv "$NO_NAME_DIR" "$NEW_DIR"; then
  echo -e "${GREEN}✓ Rename successful${NC}"
  echo ""
  echo "New location: $NEW_DIR"

  # Update any plan files that might reference the old name
  # (This is a simple implementation - could be extended to update cross-references)
  if [ -d "$NEW_DIR/plans" ]; then
    PLAN_FILES=$(find "$NEW_DIR/plans" -name "*.md" 2>/dev/null || true)
    if [ -n "$PLAN_FILES" ]; then
      echo ""
      echo "Note: Plan files found in renamed directory."
      echo "Review these files for any references to 'no_name_error' that should be updated:"
      echo "$PLAN_FILES" | sed 's/^/  - /'
    fi
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Rename Complete"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
else
  echo -e "${RED}ERROR: Rename failed${NC}"
  echo "Check permissions and try again."
  exit 1
fi
