#!/usr/bin/env bash
# Integration test for BASH_SOURCE bootstrap fixes (Spec 736)
# Tests implement, expand, and collapse commands with inline CLAUDE_PROJECT_DIR detection

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test results array
declare -a FAILURES

log_test() {
  echo -e "${YELLOW}[TEST]${NC} $1"
  ((TOTAL_TESTS++))
}

log_pass() {
  echo -e "${GREEN}[PASS]${NC} $1"
  ((PASSED_TESTS++))
}

log_fail() {
  echo -e "${RED}[FAIL]${NC} $1"
  FAILURES+=("$1")
  ((FAILED_TESTS++))
}

# Test function: Verify command bootstrap works from project root
test_from_project_root() {
  local cmd="$1"
  log_test "Testing /$cmd from project root"

  cd /home/benjamin/.config

  # The commands are markdown files processed by Claude Code, not executable scripts
  # We'll verify the bootstrap pattern exists and is correct instead
  if grep -q "CLAUDE_PROJECT_DIR=\"\$(git rev-parse --show-toplevel)\"" ".claude/commands/${cmd}.md"; then
    log_pass "/$cmd has correct git-based bootstrap"
  else
    log_fail "/$cmd missing git-based bootstrap pattern"
    return 1
  fi

  if grep -q "Export for use by sourced libraries" ".claude/commands/${cmd}.md"; then
    log_pass "/$cmd exports CLAUDE_PROJECT_DIR"
  else
    log_fail "/$cmd missing CLAUDE_PROJECT_DIR export"
    return 1
  fi
}

# Test function: Verify directory traversal fallback exists
test_fallback_logic() {
  local cmd="$1"
  log_test "Testing /$cmd has directory traversal fallback"

  if grep -q "while \[ \"\$current_dir\" != \"/\" \]" ".claude/commands/${cmd}.md"; then
    log_pass "/$cmd has directory traversal fallback"
  else
    log_fail "/$cmd missing directory traversal fallback"
    return 1
  fi
}

# Test function: Verify error handling
test_error_handling() {
  local cmd="$1"
  log_test "Testing /$cmd has proper error handling"

  if grep -q "Failed to detect project directory" ".claude/commands/${cmd}.md"; then
    log_pass "/$cmd has error message for failed detection"
  else
    log_fail "/$cmd missing error message"
    return 1
  fi

  if grep -q "DIAGNOSTIC:" ".claude/commands/${cmd}.md"; then
    log_pass "/$cmd has diagnostic information"
  else
    log_fail "/$cmd missing diagnostic information"
    return 1
  fi
}

# Test function: Verify no BASH_SOURCE patterns remain
test_no_bash_source() {
  local cmd="$1"
  log_test "Testing /$cmd has no BASH_SOURCE patterns"

  if grep -q "BASH_SOURCE" ".claude/commands/${cmd}.md"; then
    log_fail "/$cmd still contains BASH_SOURCE pattern"
    return 1
  else
    log_pass "/$cmd has no BASH_SOURCE patterns"
  fi
}

# Test function: Verify library sourcing uses absolute paths
test_absolute_paths() {
  local cmd="$1"
  log_test "Testing /$cmd uses absolute paths for library sourcing"

  if grep -q "source \"\$CLAUDE_PROJECT_DIR/.claude/lib/" ".claude/commands/${cmd}.md" || \
     grep -q "UTILS_DIR=\"\$CLAUDE_PROJECT_DIR/.claude/lib\"" ".claude/commands/${cmd}.md"; then
    log_pass "/$cmd uses absolute paths via CLAUDE_PROJECT_DIR"
  else
    log_fail "/$cmd not using absolute paths for library sourcing"
    return 1
  fi
}

# Test function: Count bootstrap occurrences (should match expected count)
test_bootstrap_count() {
  local cmd="$1"
  local expected="$2"
  log_test "Testing /$cmd has $expected bootstrap block(s)"

  local count=$(grep -c "Bootstrap CLAUDE_PROJECT_DIR detection" ".claude/commands/${cmd}.md" || echo "0")

  if [ "$count" -eq "$expected" ]; then
    log_pass "/$cmd has exactly $expected bootstrap block(s)"
  else
    log_fail "/$cmd has $count bootstrap blocks, expected $expected"
    return 1
  fi
}

# Main test execution
main() {
  echo "========================================"
  echo "Spec 736: Integration Test Suite"
  echo "BASH_SOURCE Bootstrap Fixes"
  echo "========================================"
  echo ""

  # Test implement command (1 bootstrap block)
  echo "Testing /implement command..."
  test_from_project_root "implement" || true
  test_fallback_logic "implement" || true
  test_error_handling "implement" || true
  test_no_bash_source "implement" || true
  test_absolute_paths "implement" || true
  test_bootstrap_count "implement" 1 || true
  echo ""

  # Test expand command (2 bootstrap blocks)
  echo "Testing /expand command..."
  test_from_project_root "expand" || true
  test_fallback_logic "expand" || true
  test_error_handling "expand" || true
  test_no_bash_source "expand" || true
  test_absolute_paths "expand" || true
  test_bootstrap_count "expand" 2 || true
  echo ""

  # Test collapse command (2 bootstrap blocks)
  echo "Testing /collapse command..."
  test_from_project_root "collapse" || true
  test_fallback_logic "collapse" || true
  test_error_handling "collapse" || true
  test_no_bash_source "collapse" || true
  test_absolute_paths "collapse" || true
  test_bootstrap_count "collapse" 2 || true
  echo ""

  # Print summary
  echo "========================================"
  echo "Test Summary"
  echo "========================================"
  echo "Total Tests:  $TOTAL_TESTS"
  echo -e "Passed:       ${GREEN}$PASSED_TESTS${NC}"
  echo -e "Failed:       ${RED}$FAILED_TESTS${NC}"
  echo ""

  if [ $FAILED_TESTS -gt 0 ]; then
    echo "Failed Tests:"
    for failure in "${FAILURES[@]}"; do
      echo "  - $failure"
    done
    exit 1
  else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
  fi
}

main "$@"
