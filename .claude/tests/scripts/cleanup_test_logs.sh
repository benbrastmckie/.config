#!/usr/bin/env bash
# Cleanup script for test error logs
# Clears test logs and optionally backs up production logs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_DIR="$(dirname "$TESTS_DIR")"

TEST_LOG_DIR="${TESTS_DIR}/logs"
TEST_LOG_FILE="${TEST_LOG_DIR}/test-errors.jsonl"
PROD_LOG_DIR="${CLAUDE_DIR}/data/logs"
PROD_LOG_FILE="${PROD_LOG_DIR}/errors.jsonl"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Test Log Cleanup Utility"
echo "========================"
echo ""

# Clear test logs
if [ -f "$TEST_LOG_FILE" ]; then
  ENTRY_COUNT=$(wc -l < "$TEST_LOG_FILE")
  echo -e "${YELLOW}Clearing test log:${NC} $TEST_LOG_FILE ($ENTRY_COUNT entries)"

  # Backup before delete
  BACKUP_FILE="${TEST_LOG_FILE}.backup_$(date +%s)"
  cp "$TEST_LOG_FILE" "$BACKUP_FILE"
  echo "  Backup created: $BACKUP_FILE"

  # Clear log file
  > "$TEST_LOG_FILE"
  echo -e "${GREEN}  Test log cleared${NC}"
else
  echo "Test log not found: $TEST_LOG_FILE"
fi

echo ""
echo "Cleanup complete"
