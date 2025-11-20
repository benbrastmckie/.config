#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_PROJECT_DIR="$(dirname "$TEST_DIR")"
export CLAUDE_PROJECT_DIR

echo "DEBUG: TEST_DIR=$TEST_DIR"
echo "DEBUG: CLAUDE_PROJECT_DIR=$CLAUDE_PROJECT_DIR"

# Source library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh"
echo "DEBUG: Library sourced"

# Setup
mkdir -p "${CLAUDE_PROJECT_DIR}/.claude/data/logs"
echo "" > "${CLAUDE_PROJECT_DIR}/.claude/data/logs/errors.jsonl"

echo "DEBUG: About to call log_command_error"

log_command_error \
  "/build" \
  "build_test_123" \
  "plan.md 3" \
  "state_error" \
  "Test state error" \
  "bash_block" \
  '{"plan_file": "/path/to/plan.md"}'

echo "DEBUG: log_command_error returned"
