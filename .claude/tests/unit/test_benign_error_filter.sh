#!/usr/bin/env bash
# Unit tests for _is_benign_bash_error filter function
# Tests that bashrc/profile sourcing errors are properly filtered

# Note: Do NOT use set -e since we're testing functions that return non-zero
set -uo pipefail

# Source the error handling library
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
CLAUDE_LIB="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Disable errexit before sourcing to prevent error-handling.sh's set -e from affecting us
set +e
source "$CLAUDE_LIB/core/error-handling.sh" 2>/dev/null
if [ $? -ne 0 ]; then
  echo "✗ FAIL: Cannot source error-handling.sh"
  exit 1
fi

PASSED=0
FAILED=0

# Test helper
test_filter() {
  local test_name="$1"
  local command="$2"
  local exit_code="$3"
  local expected_benign="$4"  # true or false

  local is_benign
  if _is_benign_bash_error "$command" "$exit_code"; then
    is_benign="true"
  else
    is_benign="false"
  fi

  if [ "$is_benign" = "$expected_benign" ]; then
    echo "✓ PASS: $test_name"
    PASSED=$((PASSED + 1))
  else
    echo "✗ FAIL: $test_name (got benign=$is_benign, expected=$expected_benign)"
    FAILED=$((FAILED + 1))
  fi
}

echo "=== Benign Error Filter Unit Tests ==="
echo ""

# Test bashrc sourcing commands (should be filtered)
echo "--- Bashrc sourcing commands (should be filtered) ---"
test_filter "Direct bashrc source" ". /etc/bashrc" 127 true
test_filter "Source bashrc explicit" "source /etc/bashrc" 127 true
test_filter "Tilde bashrc" "source ~/.bashrc" 1 true
test_filter "Relative bashrc" "source .bashrc" 1 true
test_filter "Bash.bashrc path" ". /etc/bash.bashrc" 127 true

# Test exit code 127 with bashrc/profile patterns (should be filtered)
echo ""
echo "--- Exit 127 with system init patterns (should be filtered) ---"
test_filter "Bashrc exit 127" "some_bashrc_function" 127 true
test_filter "Profile exit 127" "profile_init" 127 true
test_filter "Bash completion 127" "bash_completion_setup" 127 true

# Test non-bashrc commands (should NOT be filtered)
echo ""
echo "--- Non-bashrc commands (should NOT be filtered) ---"
test_filter "Regular command exit 1" "ls -la /nonexistent" 1 false
test_filter "Unknown command 127" "nonexistent_command_xyz" 127 false
test_filter "User script failure" "my_script.sh" 1 false
test_filter "Append workflow state" "append_workflow_state" 127 false

# Test return statements (context-dependent - filtered only from core libraries)
# Note: These tests run outside library context, so return statements are NOT filtered
echo ""
echo "--- Return statements (outside library context - NOT filtered) ---"
test_filter "Return 1 outside lib" "return 1" 1 false
test_filter "Return 0 outside lib" "return 0" 0 false

# Edge cases
echo ""
echo "--- Edge cases ---"
test_filter "Empty command" "" 1 false
test_filter "Exit code 0" "some_command" 0 false

echo ""
echo "=== Results ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [ $FAILED -gt 0 ]; then
  exit 1
fi
echo "All tests passed!"
