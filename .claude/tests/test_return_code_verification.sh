#!/usr/bin/env bash
# test_return_code_verification.sh - Validate return code verification patterns
#
# PURPOSE:
#   Validates that commands verify return codes for critical function calls
#   per Standard 16.
#
# USAGE:
#   ./test_return_code_verification.sh

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Detect project directory
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
COMMANDS_DIR="${CLAUDE_PROJECT_DIR}/.claude/commands"

echo "================================================================"
echo "Return Code Verification Validation"
echo "================================================================"
echo ""

# Critical functions that MUST have return code verification
CRITICAL_FUNCTIONS=(
  "sm_init"
  "sm_transition"
  "verify_file_created"
  "perform_location_detection"
  "create_topic_structure"
  "source \""
)

for cmd_file in "${COMMANDS_DIR}"/*.md; do
  if [ ! -f "$cmd_file" ] || [ "$(basename "$cmd_file")" = "README.md" ]; then
    continue
  fi

  cmd_name=$(basename "$cmd_file" .md)

  # Count critical function calls
  total_critical_calls=0
  verified_calls=0
  unverified_calls=0

  for func in "${CRITICAL_FUNCTIONS[@]}"; do
    # Count total calls of this function
    call_count=$(grep -c "$func" "$cmd_file" 2>/dev/null || echo "0")
    total_critical_calls=$((total_critical_calls + call_count))

    # Count verified calls (preceded by 'if ! ' or followed by '|| exit')
    verified_count=$(grep -c "if ! $func\|$func.*|| exit\|$func.*; then" "$cmd_file" 2>/dev/null || echo "0")
    verified_calls=$((verified_calls + verified_count))
  done

  unverified_calls=$((total_critical_calls - verified_calls))

  # Calculate verification rate
  if [ "$total_critical_calls" -eq 0 ]; then
    echo -e "${GREEN}PASS${NC} $cmd_name: No critical function calls"
    PASSED=$((PASSED + 1))
  elif [ "$unverified_calls" -eq 0 ]; then
    echo -e "${GREEN}PASS${NC} $cmd_name: All $total_critical_calls critical calls verified"
    PASSED=$((PASSED + 1))
  elif [ "$verified_calls" -gt 0 ]; then
    rate=$((verified_calls * 100 / total_critical_calls))
    echo -e "${YELLOW}WARN${NC} $cmd_name: ${rate}% verified ($verified_calls/$total_critical_calls critical calls)"
    WARNINGS=$((WARNINGS + 1))
  else
    echo -e "${RED}FAIL${NC} $cmd_name: No return code verification ($total_critical_calls critical calls)"
    FAILED=$((FAILED + 1))
  fi
done

echo ""
echo "================================================================"
echo "Summary: $PASSED passed, $FAILED failed, $WARNINGS warnings"
echo "================================================================"

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
exit 0
