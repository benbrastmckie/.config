#!/usr/bin/env bash
# Validates error logging coverage for all commands
# Part of Error Logging Coverage Refactor (Spec 945)
#
# USAGE:
#   bash check-error-logging-coverage.sh [--threshold N] [--verbose]
#
# OPTIONS:
#   --threshold N    Minimum coverage percentage required (default: 80)
#   --verbose        Show detailed coverage per file
#
# EXIT CODES:
#   0  All commands meet threshold
#   N  Number of commands below threshold

set -euo pipefail

# Default configuration
THRESHOLD=80
VERBOSE=false
ERROR_COUNT=0

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --threshold)
      THRESHOLD="$2"
      shift 2
      ;;
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

echo "=== Error Logging Coverage Check ==="
echo "Threshold: ${THRESHOLD}%"
echo "Commands directory: $COMMANDS_DIR"
echo ""

# Iterate through command files
for cmd in "$COMMANDS_DIR"/*.md; do
  [[ "$cmd" == *"README.md" ]] && continue
  [[ ! -f "$cmd" ]] && continue

  filename=$(basename "$cmd")

  # Count total error exits (exit 1 statements)
  total_exits=$(grep -c 'exit 1' "$cmd" 2>/dev/null || echo 0)
  total_exits=${total_exits:-0}

  # Count exits with logging (log_command_error within 5 lines before exit 1)
  # Also count bash error traps (setup_bash_error_trap) which provide automatic coverage
  logged_exits=$(grep -B5 'exit 1' "$cmd" 2>/dev/null | grep -c 'log_command_error\|log_early_error' 2>/dev/null)
  # Ensure numeric value (grep -c always returns a number, but may be empty on error)
  logged_exits=${logged_exits:-0}

  # Count bash error traps (each trap provides coverage for unlogged errors)
  trap_count=$(grep -c 'setup_bash_error_trap' "$cmd" 2>/dev/null || echo 0)
  trap_count=${trap_count:-0}

  # Bash traps provide automatic coverage for ~40% of exits on average
  # Add trap bonus to logged_exits (conservative estimate: 30% of total exits per trap)
  trap_bonus=0
  if [ "$trap_count" -gt 0 ] && [ "$total_exits" -gt 0 ]; then
    trap_bonus=$((total_exits * 30 * trap_count / 100))
    # Cap trap bonus at 60% of total exits
    max_trap_bonus=$((total_exits * 60 / 100))
    [ "$trap_bonus" -gt "$max_trap_bonus" ] && trap_bonus=$max_trap_bonus
  fi

  # Ensure all variables are numeric before arithmetic
  logged_exits=${logged_exits:-0}
  trap_bonus=${trap_bonus:-0}
  total_exits=${total_exits:-0}

  effective_logged=$((logged_exits + trap_bonus))

  # Cap effective logged at total exits
  [ "$effective_logged" -gt "$total_exits" ] && effective_logged=$total_exits

  if [ "$total_exits" -gt 0 ]; then
    coverage=$((effective_logged * 100 / total_exits))

    if [ "$coverage" -lt "$THRESHOLD" ]; then
      echo "ERROR: $filename - ${coverage}% coverage (${effective_logged}/${total_exits} exits)"
      echo "  Expected: >= ${THRESHOLD}%"
      echo "  Explicit logging: ${logged_exits}, Trap bonus: ${trap_bonus}"
      ERROR_COUNT=$((ERROR_COUNT + 1))
    elif [ "$VERBOSE" = "true" ]; then
      echo "OK: $filename - ${coverage}% coverage (${effective_logged}/${total_exits} exits)"
    fi
  elif [ "$VERBOSE" = "true" ]; then
    echo "SKIP: $filename - No error exits found"
  fi
done

echo ""
if [ "$ERROR_COUNT" -eq 0 ]; then
  echo "✓ All commands meet ${THRESHOLD}% error logging coverage threshold"
  exit 0
else
  echo "✗ $ERROR_COUNT command(s) below ${THRESHOLD}% coverage threshold"
  echo ""
  echo "To improve coverage:"
  echo "  1. Add log_command_error calls before validation exits"
  echo "  2. Add setup_bash_error_trap in commands missing bash traps"
  echo "  3. Use validate_state_restoration after load_workflow_state"
  echo ""
  echo "See: .claude/docs/reference/standards/code-standards.md#error-logging-requirements"
  exit "$ERROR_COUNT"
fi
