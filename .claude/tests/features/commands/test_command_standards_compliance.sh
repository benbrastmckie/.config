#!/usr/bin/env bash
# test_command_standards_compliance.sh - Validate commands against architectural standards
#
# PURPOSE:
#   Validates all command files against the 16 architectural standards defined in
#   .claude/docs/reference/architecture/overview.md
#
# USAGE:
#   ./test_command_standards_compliance.sh [command.md]
#   ./test_command_standards_compliance.sh  # Test all commands
#
# STANDARDS TESTED:
#   Standard 0: Imperative language (MUST, WILL, EXECUTE NOW)
#   Standard 13: Project directory detection (CLAUDE_PROJECT_DIR)
#   Standard 14: Guide file exists
#   Standard 15: Library sourcing order
#   Standard 16: Return code verification

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNINGS=0

# Test results array
declare -a RESULTS=()

# Detect project directory
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$CLAUDE_PROJECT_DIR" ]; then
  if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    CLAUDE_PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  fi
fi

COMMANDS_DIR="${CLAUDE_PROJECT_DIR}/.claude/commands"
GUIDES_DIR="${CLAUDE_PROJECT_DIR}/.claude/docs/guides"

# Helper function to log results
log_result() {
  local status="$1"
  local standard="$2"
  local command="$3"
  local message="$4"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  case "$status" in
    PASS)
      PASSED_TESTS=$((PASSED_TESTS + 1))
      echo -e "${GREEN}PASS${NC} [$standard] $command: $message"
      ;;
    FAIL)
      FAILED_TESTS=$((FAILED_TESTS + 1))
      echo -e "${RED}FAIL${NC} [$standard] $command: $message"
      RESULTS+=("FAIL [$standard] $command: $message")
      ;;
    WARN)
      WARNINGS=$((WARNINGS + 1))
      echo -e "${YELLOW}WARN${NC} [$standard] $command: $message"
      ;;
  esac
}

# Standard 0: Imperative Language
# Check for YOU MUST, EXECUTE NOW, critical imperative patterns
test_standard_0() {
  local cmd_file="$1"
  local cmd_name=$(basename "$cmd_file" .md)

  local must_count=$(grep -E "YOU MUST|MUST|WILL|SHALL" "$cmd_file" 2>/dev/null | wc -l)
  must_count=${must_count:-0}
  local execute_now=$(grep -c "EXECUTE NOW" "$cmd_file" 2>/dev/null)
  execute_now=${execute_now:-0}
  local role_statement=$(grep -E "YOU ARE EXECUTING|YOUR ROLE" "$cmd_file" 2>/dev/null | wc -l)
  role_statement=${role_statement:-0}

  if [ "$role_statement" -gt 0 ] && [ "$execute_now" -gt 0 ]; then
    log_result "PASS" "Standard 0" "$cmd_name" "Has role statement and EXECUTE NOW directives ($must_count imperative markers)"
  elif [ "$must_count" -gt 5 ]; then
    log_result "PASS" "Standard 0" "$cmd_name" "Strong imperative language ($must_count markers)"
  elif [ "$must_count" -gt 0 ]; then
    log_result "WARN" "Standard 0" "$cmd_name" "Weak imperative language ($must_count markers, recommend adding YOU MUST)"
  else
    log_result "FAIL" "Standard 0" "$cmd_name" "Missing imperative language patterns"
  fi
}

# Standard 13: Project Directory Detection
# Check for CLAUDE_PROJECT_DIR detection pattern
test_standard_13() {
  local cmd_file="$1"
  local cmd_name=$(basename "$cmd_file" .md)

  # Check if command has bash blocks (some commands are pure markdown)
  local has_bash=$(grep -c '```bash' "$cmd_file" 2>/dev/null)
  has_bash=${has_bash:-0}

  if [ "$has_bash" -eq 0 ]; then
    log_result "PASS" "Standard 13" "$cmd_name" "No bash blocks (pure markdown command)"
    return
  fi

  local has_detection=$(grep -c "CLAUDE_PROJECT_DIR" "$cmd_file" 2>/dev/null)
  has_detection=${has_detection:-0}
  local has_git_detect=$(grep -E "git rev-parse|\.claude" "$cmd_file" 2>/dev/null | wc -l)
  has_git_detect=${has_git_detect:-0}

  if [ "$has_detection" -gt 0 ] && [ "$has_git_detect" -gt 0 ]; then
    log_result "PASS" "Standard 13" "$cmd_name" "Project directory detection implemented"
  elif [ "$has_detection" -gt 0 ]; then
    log_result "WARN" "Standard 13" "$cmd_name" "Uses CLAUDE_PROJECT_DIR but may lack fallback detection"
  else
    log_result "FAIL" "Standard 13" "$cmd_name" "Missing project directory detection"
  fi
}

# Standard 14: Guide File Exists
# Check for companion guide file
test_standard_14() {
  local cmd_file="$1"
  local cmd_name=$(basename "$cmd_file" .md)

  # Skip special files
  if [ "$cmd_name" = "README" ]; then
    return
  fi

  local guide_file="${GUIDES_DIR}/commands/${cmd_name}-command-guide.md"

  # Check for alternative guide patterns
  local alt_guide_1="${GUIDES_DIR}/commands/${cmd_name}-guide.md"
  local alt_guide_2="${GUIDES_DIR}/commands/${cmd_name}-usage-guide.md"

  if [ -f "$guide_file" ]; then
    log_result "PASS" "Standard 14" "$cmd_name" "Guide file exists"
  elif [ -f "$alt_guide_1" ] || [ -f "$alt_guide_2" ]; then
    log_result "PASS" "Standard 14" "$cmd_name" "Alternative guide file exists"
  else
    # Check if command references a guide
    local has_guide_ref=$(grep -c "guide\|Guide" "$cmd_file" 2>/dev/null)
    has_guide_ref=${has_guide_ref:-0}
    if [ "$has_guide_ref" -gt 0 ]; then
      log_result "WARN" "Standard 14" "$cmd_name" "References guide but file not found at $guide_file"
    else
      log_result "FAIL" "Standard 14" "$cmd_name" "Missing guide file"
    fi
  fi
}

# Standard 15: Library Sourcing Order
# Check for proper library sourcing pattern
test_standard_15() {
  local cmd_file="$1"
  local cmd_name=$(basename "$cmd_file" .md)

  # Check if command sources libraries
  local has_source=$(grep -E "^source|source \"|source '" "$cmd_file" 2>/dev/null | wc -l)
  has_source=${has_source:-0}

  if [ "$has_source" -eq 0 ]; then
    # Check if command has bash blocks that might need libraries
    local has_bash=$(grep -c '```bash' "$cmd_file" 2>/dev/null)
    has_bash=${has_bash:-0}
    if [ "$has_bash" -gt 0 ]; then
      local has_functions=$(grep -E "sm_init|sm_transition|verify_file_created|handle_state_error" "$cmd_file" 2>/dev/null | wc -l)
      has_functions=${has_functions:-0}
      if [ "$has_functions" -gt 0 ]; then
        log_result "FAIL" "Standard 15" "$cmd_name" "Uses library functions but no source statements"
      else
        log_result "PASS" "Standard 15" "$cmd_name" "No library dependencies"
      fi
    else
      log_result "PASS" "Standard 15" "$cmd_name" "No bash blocks"
    fi
    return
  fi

  # Check for proper ordering (state-persistence before workflow-state-machine)
  local sp_line=$(grep -n "state-persistence.sh" "$cmd_file" | head -1 | cut -d: -f1 || echo "999")
  local wsm_line=$(grep -n "workflow-state-machine.sh" "$cmd_file" | head -1 | cut -d: -f1 || echo "0")

  if [ "$wsm_line" -gt 0 ] && [ "$sp_line" -gt "$wsm_line" ]; then
    log_result "WARN" "Standard 15" "$cmd_name" "Library sourcing order may be incorrect (state-persistence should come before workflow-state-machine)"
  else
    log_result "PASS" "Standard 15" "$cmd_name" "Library sourcing present"
  fi
}

# Standard 16: Return Code Verification
# Check for return code verification patterns
test_standard_16() {
  local cmd_file="$1"
  local cmd_name=$(basename "$cmd_file" .md)

  # Check if command has bash blocks
  local has_bash=$(grep -c '```bash' "$cmd_file" 2>/dev/null)
  has_bash=${has_bash:-0}

  if [ "$has_bash" -eq 0 ]; then
    log_result "PASS" "Standard 16" "$cmd_name" "No bash blocks"
    return
  fi

  # Check for return code verification patterns
  local has_if_not=$(grep -E "if ! |if !" "$cmd_file" 2>/dev/null | wc -l)
  has_if_not=${has_if_not:-0}
  local has_pipe_or=$(grep -E " \|\| |exit 1" "$cmd_file" 2>/dev/null | wc -l)
  has_pipe_or=${has_pipe_or:-0}

  # Check for critical function calls without verification
  local critical_calls=$(grep -E "sm_init|sm_transition|source \"" "$cmd_file" 2>/dev/null | wc -l)
  critical_calls=${critical_calls:-0}

  if [ "$has_if_not" -gt 0 ] || [ "$has_pipe_or" -gt 2 ]; then
    log_result "PASS" "Standard 16" "$cmd_name" "Return code verification present ($has_if_not if-not patterns, $has_pipe_or error checks)"
  elif [ "$critical_calls" -gt 0 ]; then
    log_result "WARN" "Standard 16" "$cmd_name" "Has critical calls but limited verification ($critical_calls calls, $has_if_not checks)"
  else
    log_result "PASS" "Standard 16" "$cmd_name" "No critical function calls requiring verification"
  fi
}

# Run all tests for a single command
test_command() {
  local cmd_file="$1"
  local cmd_name=$(basename "$cmd_file" .md)

  echo ""
  echo "=== Testing: $cmd_name ==="

  test_standard_0 "$cmd_file"
  test_standard_13 "$cmd_file"
  test_standard_14 "$cmd_file"
  test_standard_15 "$cmd_file"
  test_standard_16 "$cmd_file"
}

# Main execution
main() {
  echo "================================================================"
  echo "Command Standards Compliance Test Suite"
  echo "================================================================"
  echo ""
  echo "Project: $CLAUDE_PROJECT_DIR"
  echo "Commands: $COMMANDS_DIR"
  echo "Guides: $GUIDES_DIR"
  echo ""

  # Check if testing single command
  if [ $# -gt 0 ]; then
    local cmd_file="$1"
    if [ ! -f "$cmd_file" ]; then
      cmd_file="${COMMANDS_DIR}/$1"
    fi
    if [ -f "$cmd_file" ]; then
      test_command "$cmd_file"
    else
      echo "ERROR: Command file not found: $1"
      exit 1
    fi
  else
    # Test all commands
    for cmd_file in "${COMMANDS_DIR}"/*.md; do
      if [ -f "$cmd_file" ] && [ "$(basename "$cmd_file")" != "README.md" ]; then
        test_command "$cmd_file"
      fi
    done
  fi

  # Summary
  echo ""
  echo "================================================================"
  echo "COMPLIANCE SUMMARY"
  echo "================================================================"
  echo ""
  echo "Total Tests: $TOTAL_TESTS"
  echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
  echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
  echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
  echo ""

  local compliance_rate=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
  echo "Compliance Rate: ${compliance_rate}%"
  echo ""

  if [ ${#RESULTS[@]} -gt 0 ]; then
    echo "FAILURES:"
    for result in "${RESULTS[@]}"; do
      echo "  - $result"
    done
    echo ""
  fi

  # Exit code based on failures
  if [ "$FAILED_TESTS" -gt 0 ]; then
    echo "Status: FAILING"
    exit 1
  else
    echo "Status: PASSING"
    exit 0
  fi
}

main "$@"
