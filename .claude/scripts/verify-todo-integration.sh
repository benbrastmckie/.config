#!/bin/bash
# verify-todo-integration.sh
# Purpose: Systematically verify TODO.md updates after command execution
# Usage: bash verify-todo-integration.sh [--command CMD]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
SKIPPED=0

# Parse arguments
SPECIFIC_COMMAND=""
if [[ "$1" == "--command" && -n "$2" ]]; then
  SPECIFIC_COMMAND="$2"
fi

# Helper: Print test result
print_result() {
  local status="$1"
  local command="$2"
  local message="$3"

  case "$status" in
    "PASS")
      echo -e "${GREEN}✓${NC} $command: $message"
      ((PASSED++))
      ;;
    "FAIL")
      echo -e "${RED}✗${NC} $command: $message"
      ((FAILED++))
      ;;
    "SKIP")
      echo -e "${YELLOW}⊘${NC} $command: $message"
      ((SKIPPED++))
      ;;
  esac
}

# Helper: Verify command updates TODO.md
verify_command_updates_todo() {
  local command="$1"
  local test_args="$2"
  local search_pattern="$3"

  # Skip if specific command requested and this isn't it
  if [[ -n "$SPECIFIC_COMMAND" && "$SPECIFIC_COMMAND" != "$command" ]]; then
    print_result "SKIP" "$command" "not requested (--command $SPECIFIC_COMMAND)"
    return 0
  fi

  # Backup TODO.md
  if [[ -f ".claude/TODO.md" ]]; then
    cp .claude/TODO.md .claude/TODO.md.backup.$$
  fi

  # Capture before hash
  BEFORE_HASH=""
  if [[ -f ".claude/TODO.md" ]]; then
    BEFORE_HASH=$(md5sum .claude/TODO.md | cut -d' ' -f1)
  fi

  # Execute command (suppress output)
  if eval "$command $test_args" >/dev/null 2>&1; then
    # Capture after hash
    AFTER_HASH=""
    if [[ -f ".claude/TODO.md" ]]; then
      AFTER_HASH=$(md5sum .claude/TODO.md | cut -d' ' -f1)
    fi

    # Check if TODO.md changed
    if [[ "$BEFORE_HASH" != "$AFTER_HASH" ]]; then
      # Verify entry exists if search pattern provided
      if [[ -n "$search_pattern" ]]; then
        if grep -q "$search_pattern" .claude/TODO.md 2>/dev/null; then
          print_result "PASS" "$command" "TODO.md updated with expected entry"
        else
          print_result "FAIL" "$command" "TODO.md updated but entry not found: $search_pattern"
        fi
      else
        print_result "PASS" "$command" "TODO.md updated"
      fi
    else
      print_result "FAIL" "$command" "TODO.md not updated (hash unchanged)"
    fi
  else
    print_result "FAIL" "$command" "command execution failed"
  fi

  # Restore backup
  if [[ -f ".claude/TODO.md.backup.$$" ]]; then
    mv .claude/TODO.md.backup.$$ .claude/TODO.md
  fi
}

# Header
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TODO.md Integration Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verify CLAUDE_PROJECT_DIR
if [[ -z "$CLAUDE_PROJECT_DIR" ]]; then
  export CLAUDE_PROJECT_DIR="${HOME}/.config"
fi

cd "$CLAUDE_PROJECT_DIR" || {
  echo "ERROR: Cannot cd to $CLAUDE_PROJECT_DIR"
  exit 1
}

# Test 1: /plan command
echo "Testing /plan command integration..."
verify_command_updates_todo "/plan" "\"verify-todo-integration-test-plan\"" "verify-todo-integration-test-plan"

# Test 2: /research command
echo "Testing /research command integration..."
verify_command_updates_todo "/research" "\"verify-todo-integration-test-research\"" "verify-todo-integration-test-research"

# Test 3: /repair command
echo "Testing /repair command integration..."
verify_command_updates_todo "/repair" "\"--since 1h\"" ""

# Test 4: /debug command (requires existing plan with failing tests)
echo "Testing /debug command integration..."
print_result "SKIP" "/debug" "requires existing plan with test failures (manual test)"

# Test 5: /errors command (report mode)
echo "Testing /errors command integration..."
verify_command_updates_todo "/errors" "\"--summary\"" ""

# Test 6: /revise command (requires existing plan)
echo "Testing /revise command integration..."
print_result "SKIP" "/revise" "requires existing plan (manual test)"

# Test 7: /build command (requires existing plan)
echo "Testing /build command integration..."
print_result "SKIP" "/build" "requires existing plan (manual test)"

# Test 8: /implement command (requires existing plan)
echo "Testing /implement command integration..."
print_result "SKIP" "/implement" "requires existing plan (manual test)"

# Test 9: /test command (requires existing plan with tests)
echo "Testing /test command integration..."
print_result "SKIP" "/test" "requires existing plan with test files (manual test)"

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Verification Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}Passed:${NC}  $PASSED"
echo -e "${RED}Failed:${NC}  $FAILED"
echo -e "${YELLOW}Skipped:${NC} $SKIPPED"
echo ""

# Exit code
if [[ $FAILED -gt 0 ]]; then
  exit 1
else
  exit 0
fi
