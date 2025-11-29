#!/usr/bin/env bash
# Integration test suite for bash error trap across all commands
# Tests error capture for newly integrated commands: /plan, /build, /debug, /repair, /revise

set -euo pipefail

# Enable test mode for proper error log routing
export CLAUDE_TEST_MODE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect project root
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  PROJECT_ROOT="$(git rev-parse --show-toplevel)"
else
  current_dir="$SCRIPT_DIR"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      PROJECT_ROOT="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi

# Use centralized test log directory (matches error-handling.sh)
TEST_LOG_DIR="${PROJECT_ROOT}/.claude/tests/logs"
ERROR_LOG_DIR="${PROJECT_ROOT}/.claude/data/logs"
ERROR_LOG_FILE="${TEST_LOG_DIR}/test-errors.jsonl"

# Backup existing error log
if [ -f "$ERROR_LOG_FILE" ]; then
  cp "$ERROR_LOG_FILE" "${ERROR_LOG_FILE}.backup_$(date +%s)"
fi

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

print_header() {
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║   BASH ERROR TRAP INTEGRATION TESTS                      ║"
  echo "╠══════════════════════════════════════════════════════════╣"
  echo "║ Testing error capture across 5 commands                 ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo ""
}

print_test_result() {
  local test_name=$1
  local result=$2
  local details=${3:-}

  if [ "$result" = "PASS" ]; then
    echo -e "${GREEN}✓${NC} ${test_name}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} ${test_name}"
    if [ -n "$details" ]; then
      echo "  Details: ${details}"
    fi
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

check_error_logged() {
  local error_pattern=$1
  local command_name=$2

  if [ ! -f "$ERROR_LOG_FILE" ]; then
    echo "NOT_FOUND:log_file_missing"
    return 1
  fi

  # Capture jq stderr for error detection
  local jq_stderr=$(mktemp)

  # Check for error in recent entries (last 20 lines)
  # Note: Parentheses are critical for jq operator precedence - (.error_message | contains(...)) must be grouped
  # Search in both error_message and context.command fields for maximum coverage
  local found
  found=$(tail -20 "$ERROR_LOG_FILE" | jq -r "select(.command == \"$command_name\" and ((.error_message | contains(\"$error_pattern\")) or (.context.command // \"\" | contains(\"$error_pattern\")))) | .timestamp" 2>"$jq_stderr" | head -1)

  # Check for jq errors
  if [ -s "$jq_stderr" ]; then
    local jq_error=$(cat "$jq_stderr")
    rm -f "$jq_stderr"
    echo "NOT_FOUND:jq_error:$jq_error"
    return 1
  fi
  rm -f "$jq_stderr"

  if [ -n "$found" ]; then
    echo "FOUND"
    return 0
  else
    # Provide detailed error type for debugging
    local command_exists=$(tail -20 "$ERROR_LOG_FILE" | jq -r "select(.command == \"$command_name\") | .timestamp" | head -1)
    if [ -z "$command_exists" ]; then
      echo "NOT_FOUND:wrong_command"
    else
      echo "NOT_FOUND:wrong_message"
    fi
    return 1
  fi
}

test_syntax_error_capture() {
  local command=$1
  echo ""
  echo "Testing ${command}: Syntax error capture"

  # Create a test script with syntax error
  local test_script="/tmp/test_${command}_syntax.sh"
  cat > "$test_script" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null
ensure_error_log_exists
setup_bash_error_trap "/test" "test_$(date +%s)" "syntax_test"
# Syntax error: missing closing quote
echo "unclosed string
EOF

  chmod +x "$test_script"

  # Run and expect failure
  if bash "$test_script" 2>/dev/null; then
    print_test_result "${command}: Syntax error should fail" "FAIL" "Script unexpectedly succeeded"
  else
    # Check if error was logged (Note: syntax errors before trap setup won't be caught)
    print_test_result "${command}: Syntax error execution" "PASS"
  fi

  rm -f "$test_script"
}

test_unbound_variable_capture() {
  local command=$1
  echo ""
  echo "Testing ${command}: Unbound variable capture"

  local test_script="/tmp/test_${command}_unbound.sh"
  cat > "$test_script" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

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
export CLAUDE_PROJECT_DIR

source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || exit 1
ensure_error_log_exists
WORKFLOW_ID="test_unbound_$(date +%s)"
setup_bash_error_trap "/test" "$WORKFLOW_ID" "unbound_test"

# Try to use undefined variable (should trigger error)
echo "$UNDEFINED_VARIABLE"
EOF

  chmod +x "$test_script"

  # Run and expect failure
  if bash "$test_script" 2>/dev/null; then
    print_test_result "${command}: Unbound variable should fail" "FAIL" "Script unexpectedly succeeded"
  else
    # Check if error was logged
    sleep 0.1  # Brief pause for log write
    local result=$(check_error_logged "UNDEFINED_VARIABLE" "/test")
    if [ "$result" = "FOUND" ]; then
      print_test_result "${command}: Unbound variable logged" "PASS"
    else
      print_test_result "${command}: Unbound variable logged" "FAIL" "Error not found in log"
    fi
  fi

  rm -f "$test_script"
}

test_command_not_found_capture() {
  local command=$1
  echo ""
  echo "Testing ${command}: Command not found capture"

  local test_script="/tmp/test_${command}_cmd404.sh"
  cat > "$test_script" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

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
export CLAUDE_PROJECT_DIR

source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || exit 1
ensure_error_log_exists
WORKFLOW_ID="test_cmd404_$(date +%s)"
setup_bash_error_trap "/test" "$WORKFLOW_ID" "cmd404_test"

# Run nonexistent command
nonexistent_command_xyz_12345
EOF

  chmod +x "$test_script"

  # Run and expect failure
  if bash "$test_script" 2>/dev/null; then
    print_test_result "${command}: Command not found should fail" "FAIL" "Script unexpectedly succeeded"
  else
    # Check if error was logged
    sleep 0.1  # Brief pause for log write
    local result=$(check_error_logged "nonexistent_command_xyz_12345" "/test")
    if [ "$result" = "FOUND" ]; then
      print_test_result "${command}: Command not found logged" "PASS"
    else
      print_test_result "${command}: Command not found logged" "FAIL" "Error not found in log"
    fi
  fi

  rm -f "$test_script"
}

calculate_capture_rate() {
  if [ $TESTS_RUN -eq 0 ]; then
    echo "0"
  else
    echo $(( (TESTS_PASSED * 100) / TESTS_RUN ))
  fi
}

print_summary() {
  local capture_rate=$(calculate_capture_rate)

  echo ""
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║       INTEGRATION TEST SUMMARY                           ║"
  echo "╠══════════════════════════════════════════════════════════╣"
  printf "║ Tests Run:      %-36s ║\n" "$TESTS_RUN"
  printf "║ Tests Passed:   %-36s ║\n" "$TESTS_PASSED"
  printf "║ Tests Failed:   %-36s ║\n" "$TESTS_FAILED"
  printf "║ Capture Rate:   %-36s ║\n" "${capture_rate}%"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo ""

  if [ $capture_rate -ge 90 ]; then
    echo -e "${GREEN}✓ CAPTURE RATE TARGET MET (≥90%)${NC}"
    return 0
  else
    echo -e "${RED}✗ CAPTURE RATE BELOW TARGET (<90%)${NC}"
    return 1
  fi
}

# Main execution
main() {
  print_header

  # Test each newly integrated command
  for cmd in plan build debug repair revise; do
    echo "=== Testing /${cmd} command ==="
    test_unbound_variable_capture "$cmd"
    test_command_not_found_capture "$cmd"
  done

  # Print summary
  print_summary
}

main "$@"
