#!/usr/bin/env bash
set -euo pipefail

# Test error logging compliance across all commands
# Verifies that all commands integrate centralized error logging

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect project root using git or walk-up pattern
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  CLAUDE_PROJECT_DIR="$SCRIPT_DIR"
  while [ "$CLAUDE_PROJECT_DIR" != "/" ]; do
    if [ -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
      break
    fi
    CLAUDE_PROJECT_DIR="$(dirname "$CLAUDE_PROJECT_DIR")"
  done
fi
COMMANDS_DIR="${CLAUDE_PROJECT_DIR}/.claude/commands"

compliant_count=0
non_compliant_count=0
total_count=0

echo "=========================================="
echo "Error Logging Compliance Audit"
echo "=========================================="
echo

# Check each command file
for cmd_file in "$COMMANDS_DIR"/*.md; do
  cmd_name=$(basename "$cmd_file" .md)
  total_count=$((total_count + 1))

  # Check for error-handling.sh sourcing
  has_sourcing=false
  if grep -q "error-handling.sh" "$cmd_file"; then
    has_sourcing=true
  fi

  # Check for log_command_error usage
  has_logging=false
  if grep -q "log_command_error" "$cmd_file"; then
    has_logging=true
  fi

  # Determine compliance
  if [ "$has_sourcing" = true ] && [ "$has_logging" = true ]; then
    echo "✅ /$cmd_name - Compliant"
    compliant_count=$((compliant_count + 1))
  else
    echo "❌ /$cmd_name - Non-compliant"
    non_compliant_count=$((non_compliant_count + 1))

    if [ "$has_sourcing" = false ]; then
      echo "   - Missing: error-handling.sh sourcing"
    fi
    if [ "$has_logging" = false ]; then
      echo "   - Missing: log_command_error() usage"
    fi
  fi
done

echo
echo "=========================================="
echo "Summary"
echo "=========================================="
echo "Compliant:     $compliant_count/$total_count commands"
echo "Non-compliant: $non_compliant_count/$total_count commands"

if [ $non_compliant_count -gt 0 ]; then
  echo
  echo "⚠️  Some commands are missing error logging integration."
  echo
  echo "Integration steps:"
  echo "1. Source error-handling library"
  echo "2. Set workflow metadata (COMMAND_NAME, WORKFLOW_ID, USER_ARGS)"
  echo "3. Initialize error log with ensure_error_log_exists"
  echo "4. Log errors with log_command_error at all error points"
  echo "5. Parse subagent errors with parse_subagent_error"
  echo
  echo "See: .claude/docs/concepts/patterns/error-handling.md"
  echo "See: .claude/docs/reference/architecture/error-handling.md#standard-17"
  echo
  exit 1
else
  echo
  echo "✅ All commands are compliant!"
  exit 0
fi
