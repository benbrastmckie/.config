#!/usr/bin/env bash
# test_trigger_todo_removal.sh - Regression test to ensure trigger_todo_update is completely removed

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== Trigger TODO Update Removal Test ==="
echo ""

FAIL_COUNT=0

# Test 1: No references in commands/
echo "Test 1: No trigger_todo_update in commands/"
if grep -r "trigger_todo_update" "$PROJECT_ROOT/commands/" 2>/dev/null; then
  echo "  ✗ FAIL: Found trigger_todo_update references in commands/"
  ((FAIL_COUNT++))
else
  echo "  ✓ PASS: No trigger_todo_update references in commands/"
fi

# Test 2: No references in lib/todo/todo-functions.sh
echo "Test 2: No trigger_todo_update in todo-functions.sh"
if grep "trigger_todo_update" "$PROJECT_ROOT/lib/todo/todo-functions.sh" 2>/dev/null; then
  echo "  ✗ FAIL: Found trigger_todo_update in library"
  ((FAIL_COUNT++))
else
  echo "  ✓ PASS: No trigger_todo_update in library"
fi

# Test 3: Reminder messages present in all commands
echo "Test 3: Reminder messages present in commands"
COMMANDS=(build plan implement revise research repair errors debug test)
for cmd in "${COMMANDS[@]}"; do
  if grep -q "Run /todo to update TODO.md" "$PROJECT_ROOT/commands/${cmd}.md" 2>/dev/null; then
    echo "  ✓ PASS: $cmd has reminder message"
  else
    echo "  ✗ FAIL: $cmd missing reminder message"
    ((FAIL_COUNT++))
  fi
done

# Test 4: Library sources without errors
echo "Test 4: Library sources successfully"
if source "$PROJECT_ROOT/lib/todo/todo-functions.sh" 2>/dev/null; then
  echo "  ✓ PASS: Library sources without errors"
else
  echo "  ✗ FAIL: Library failed to source"
  ((FAIL_COUNT++))
fi

echo ""
echo "=== Test Summary ==="
if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "All tests passed"
  exit 0
else
  echo "Failed: $FAIL_COUNT tests"
  exit 1
fi
