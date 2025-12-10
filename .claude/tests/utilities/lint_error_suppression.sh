#!/usr/bin/env bash
# lint_error_suppression.sh - Detect error suppression anti-patterns in commands
#
# This test detects error suppression patterns that hide failures and reduce
# error visibility. Part of Phase 4: Error Visibility remediation (Plan 864).
#
# Usage:
#   ./lint_error_suppression.sh
#
# Exit Codes:
#   0 - No anti-patterns detected
#   1 - Anti-patterns found
#   2 - Script error

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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
PROJECT_ROOT="$CLAUDE_PROJECT_DIR"
COMMANDS_DIR="${CLAUDE_PROJECT_DIR}/.claude/commands"

# Track violations
VIOLATION_COUNT=0
TOTAL_FILES=0

echo "═══════════════════════════════════════════════════════"
echo "Error Suppression Anti-Pattern Detection"
echo "═══════════════════════════════════════════════════════"
echo ""

# Pattern 1: save_completed_states_to_state with error suppression
check_state_persistence_suppression() {
  local file="$1"
  local violations=0

  # Check for error suppression without explicit error handling
  # ANTI-PATTERN: save_completed_states_to_state 2>/dev/null
  # ACCEPTABLE: if ! save_completed_states_to_state 2>&1; then ... fi

  if grep -n "save_completed_states_to_state 2>/dev/null" "$file" 2>/dev/null; then
    echo -e "${RED}✗ FAIL${NC}: $file"
    echo "  Anti-pattern: save_completed_states_to_state 2>/dev/null"
    echo "  Fix: Replace with explicit error handling and logging"
    echo ""
    violations=$((violations + 1))
  fi

  # Check for || true suppression
  if grep -n "save_completed_states_to_state.*|| true" "$file" 2>/dev/null; then
    echo -e "${RED}✗ FAIL${NC}: $file"
    echo "  Anti-pattern: save_completed_states_to_state ... || true"
    echo "  Fix: Replace with explicit error handling and logging"
    echo ""
    violations=$((violations + 1))
  fi

  return $violations
}

# Pattern 2: Library sourcing with error suppression (critical operations)
check_library_sourcing_suppression() {
  local file="$1"
  local violations=0

  # ANTI-PATTERN: source ... 2>/dev/null without error handling
  # ACCEPTABLE: source ... 2>/dev/null || { echo "Error: ..."; exit 1; }

  # Look for library sourcing that suppresses errors without fallback
  if grep -Pzo 'source\s+.*\s+2>/dev/null\s*\n(?!.*\|\|)' "$file" 2>/dev/null | grep -q "source"; then
    echo -e "${YELLOW}⚠ WARNING${NC}: $file"
    echo "  Potential issue: Library sourcing with error suppression"
    echo "  Review: Ensure sourcing has proper fallback handling"
    echo ""
  fi

  return $violations
}

# Pattern 3: Missing state file verification after save
check_state_file_verification() {
  local file="$1"
  local violations=0

  # Check if save_completed_states_to_state is used without verification
  if grep -q "save_completed_states_to_state" "$file" 2>/dev/null; then
    # Count how many times it's used (ensure single numeric value)
    save_count=$(grep -c "save_completed_states_to_state" "$file" 2>/dev/null | head -1 || echo "0")

    # Count how many times we verify STATE_FILE exists after save
    # Relaxed pattern: accept any conditional check around STATE_FILE after save
    verify_count=$(grep -c -E "(if.*STATE_FILE|test.*STATE_FILE|\[ .* STATE_FILE)" "$file" 2>/dev/null | head -1 || echo "0")

    # Ensure numeric values for comparison
    save_count=${save_count:-0}
    verify_count=${verify_count:-0}

    if [ "$save_count" -gt "$verify_count" ]; then
      echo -e "${YELLOW}⚠ WARNING${NC}: $file"
      echo "  Potential issue: State persistence without verification ($save_count saves, $verify_count verifications)"
      echo "  Recommendation: Add verification after each save_completed_states_to_state call"
      echo ""
    fi
  fi

  return $violations
}

# Pattern 4: Deprecated state file paths
check_deprecated_state_paths() {
  local file="$1"
  local violations=0

  # DEPRECATED: .claude/data/states/
  # DEPRECATED: .claude/data/workflows/
  # STANDARD: .claude/tmp/workflow_*.sh

  if grep -n "\.claude/data/states/" "$file" 2>/dev/null; then
    echo -e "${RED}✗ FAIL${NC}: $file"
    echo "  Anti-pattern: Using deprecated state path .claude/data/states/"
    echo "  Fix: Use .claude/tmp/workflow_*.sh instead"
    echo ""
    violations=$((violations + 1))
  fi

  if grep -n "\.claude/data/workflows/" "$file" 2>/dev/null; then
    echo -e "${RED}✗ FAIL${NC}: $file"
    echo "  Anti-pattern: Using deprecated state path .claude/data/workflows/"
    echo "  Fix: Use .claude/tmp/workflow_*.sh instead"
    echo ""
    violations=$((violations + 1))
  fi

  return $violations
}

# Check all command files
for cmd_file in "$COMMANDS_DIR"/*.md; do
  if [ ! -f "$cmd_file" ]; then
    continue
  fi

  TOTAL_FILES=$((TOTAL_FILES + 1))
  file_violations=0

  # Run all checks
  check_state_persistence_suppression "$cmd_file" || file_violations=$((file_violations + $?))
  check_library_sourcing_suppression "$cmd_file" || file_violations=$((file_violations + $?))
  check_state_file_verification "$cmd_file" || file_violations=$((file_violations + $?))
  check_deprecated_state_paths "$cmd_file" || file_violations=$((file_violations + $?))

  VIOLATION_COUNT=$((VIOLATION_COUNT + file_violations))
done

# Summary
echo "═══════════════════════════════════════════════════════"
echo "Summary"
echo "═══════════════════════════════════════════════════════"
echo "Files checked: $TOTAL_FILES"
echo "Violations found: $VIOLATION_COUNT"
echo ""

if [ $VIOLATION_COUNT -eq 0 ]; then
  echo -e "${GREEN}✓ PASS${NC}: No error suppression anti-patterns detected"
  exit 0
else
  echo -e "${RED}✗ FAIL${NC}: $VIOLATION_COUNT error suppression anti-patterns detected"
  echo ""
  echo "Fix these issues before committing. See Phase 4 of Plan 864 for remediation patterns."
  exit 1
fi
