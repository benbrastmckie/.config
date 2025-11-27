#!/usr/bin/env bash
# Detects unsafe variable expansions without default syntax
# Part of Error Logging Coverage Refactor (Spec 945)
#
# USAGE:
#   bash check-unbound-variables.sh [--verbose]
#
# CHECKS:
#   - Variables in append_workflow_state without ${VAR:-} syntax
#   - Variables in critical contexts (state persistence, error logging)
#   - Common unbound variable patterns that cause exit 127
#
# EXIT CODES:
#   0  No unsafe variable expansions found
#   N  Number of files with unsafe expansions

set -euo pipefail

# Configuration
VERBOSE=false
ERROR_COUNT=0

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --verbose)
      VERBOSE=true
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# Detect project directory
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi

if [ -z "${CLAUDE_PROJECT_DIR:-}" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Cannot detect project directory with .claude/ subdirectory" >&2
  exit 1
fi

COMMANDS_DIR="${CLAUDE_PROJECT_DIR}/.claude/commands"

if [ ! -d "$COMMANDS_DIR" ]; then
  echo "ERROR: Commands directory not found: $COMMANDS_DIR" >&2
  exit 1
fi

echo "=== Unbound Variable Check ==="
echo "Commands directory: $COMMANDS_DIR"
echo ""

# Iterate through command files
for cmd in "$COMMANDS_DIR"/*.md; do
  [[ "$cmd" == *"README.md" ]] && continue
  [[ ! -f "$cmd" ]] && continue

  filename=$(basename "$cmd")
  file_errors=0

  # Pattern 1: append_workflow_state with unsafe variable expansions
  # Look for "$VAR" not "${VAR:-}" in append_workflow_state calls
  unsafe_append=$(grep -n 'append_workflow_state.*"\$[A-Z_][A-Z_0-9]*"' "$cmd" | \
    grep -v ':-' | \
    grep -v '\${' || true)

  if [ -n "$unsafe_append" ]; then
    echo "ERROR: $filename has unsafe variable expansions in append_workflow_state:"
    echo "$unsafe_append" | sed 's/^/  Line /'
    echo ""
    file_errors=$((file_errors + 1))
  fi

  # Pattern 2: log_command_error with unsafe USER_ARGS
  # Look for log_command_error calls with "$USER_ARGS" not "${USER_ARGS:-}"
  unsafe_log=$(grep -n 'log_command_error.*"\$USER_ARGS"' "$cmd" | \
    grep -v ':-' | \
    grep -v '\${' || true)

  if [ -n "$unsafe_log" ]; then
    echo "ERROR: $filename has unsafe USER_ARGS in log_command_error:"
    echo "$unsafe_log" | sed 's/^/  Line /'
    echo ""
    file_errors=$((file_errors + 1))
  fi

  # Pattern 3: Variable assignment from state file without defaults
  # Look for VAR=$(grep "^VAR=" without default in variable expansion)
  unsafe_state_var=$(grep -n '=[A-Z_][A-Z_0-9]*=$(grep' "$cmd" | \
    grep -v 'echo ""' | \
    grep -v '|| echo' || true)

  if [ -n "$unsafe_state_var" ]; then
    echo "WARNING: $filename may have unsafe state variable extraction:"
    echo "$unsafe_state_var" | sed 's/^/  Line /'
    echo "  Consider: VAR=\$(grep \"^VAR=\" ... || echo \"\")"
    echo ""
    # Don't increment error count for warnings
  fi

  # Pattern 4: Conditionals with unquoted variables (can cause unbound errors)
  unsafe_conditional=$(grep -n '\[ -[zn] \$[A-Z_][A-Z_0-9]* \]' "$cmd" | \
    grep -v ':-' | \
    grep -v '\${' || true)

  if [ -n "$unsafe_conditional" ]; then
    echo "ERROR: $filename has unquoted variables in conditionals:"
    echo "$unsafe_conditional" | sed 's/^/  Line /'
    echo "  Use: [ -z \"\${VAR:-}\" ] instead of [ -z \$VAR ]"
    echo ""
    file_errors=$((file_errors + 1))
  fi

  if [ "$file_errors" -gt 0 ]; then
    ERROR_COUNT=$((ERROR_COUNT + 1))
  elif [ "$VERBOSE" = "true" ]; then
    echo "OK: $filename - No unsafe variable expansions found"
  fi
done

echo ""
if [ "$ERROR_COUNT" -eq 0 ]; then
  echo "✓ No unsafe variable expansions found"
  exit 0
else
  echo "✗ $ERROR_COUNT file(s) have unsafe variable expansions"
  echo ""
  echo "To fix unsafe expansions:"
  echo "  1. Use \${VAR:-} or \${VAR:-default} syntax"
  echo "  2. Add || echo \"\" fallback for state variable extraction"
  echo "  3. Quote variables in conditionals: [ -z \"\${VAR:-}\" ]"
  echo ""
  echo "See: .claude/docs/concepts/patterns/error-handling.md#defensive-variable-expansion"
  exit "$ERROR_COUNT"
fi
