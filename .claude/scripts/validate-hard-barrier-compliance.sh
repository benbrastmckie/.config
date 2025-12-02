#!/usr/bin/env bash
# validate-hard-barrier-compliance.sh
# Automated compliance validator for hard barrier subagent delegation pattern
# Usage: bash validate-hard-barrier-compliance.sh [--verbose] [--command CMD]

set -uo pipefail

# === CONFIGURATION ===
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
COMMANDS_DIR="${CLAUDE_PROJECT_DIR}/.claude/commands"
PATTERN_DOC="${CLAUDE_PROJECT_DIR}/.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md"

# Parse arguments
VERBOSE=false
SINGLE_COMMAND=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --verbose)
      VERBOSE=true
      shift
      ;;
    --command)
      SINGLE_COMMAND="$2"
      shift 2
      ;;
    *)
      echo "Usage: $0 [--verbose] [--command CMD]" >&2
      exit 1
      ;;
  esac
done

# === UTILITY FUNCTIONS ===

log_verbose() {
  if [ "$VERBOSE" = true ]; then
    echo "$@"
  fi
}

log_error() {
  echo "  ✗ $*" >&2
}

log_success() {
  echo "  ✓ $*"
}

# === DISCOVER COMMANDS ===

discover_commands() {
  local commands=()

  # Parse hard-barrier-subagent-delegation.md for commands list
  if [ -f "$PATTERN_DOC" ]; then
    log_verbose "Reading commands from: $PATTERN_DOC"

    # Extract commands from "Commands Requiring Hard Barriers" section
    # Pattern: - `/command` (agents)
    while IFS= read -r line; do
      if [[ "$line" =~ ^-[[:space:]]*\`/([a-z-]+)\` ]]; then
        local cmd="${BASH_REMATCH[1]}"
        commands+=("$cmd")
      fi
    done < <(sed -n '/\*\*Commands Requiring Hard Barriers\*\*:/,/^---$/p' "$PATTERN_DOC")
  else
    echo "ERROR: Pattern documentation not found: $PATTERN_DOC" >&2
    exit 1
  fi

  if [ ${#commands[@]} -eq 0 ]; then
    echo "ERROR: No commands found in documentation" >&2
    exit 1
  fi

  log_verbose "Discovered ${#commands[@]} commands: ${commands[*]}"
  printf '%s\n' "${commands[@]}"
}

# === VALIDATION FUNCTIONS ===

validate_command() {
  local cmd="$1"
  local cmd_file="${COMMANDS_DIR}/${cmd}.md"

  if [ ! -f "$cmd_file" ]; then
    log_error "Command file not found: $cmd_file"
    return 1
  fi

  log_verbose ""
  log_verbose "Validating: /$cmd"
  log_verbose "File: $cmd_file"

  local failures=0

  # Check 1: Block structure (Na/Nb/Nc pattern)
  log_verbose "  Checking block structure..."
  local block_pattern='^## Block [0-9]+[abc]:'
  if ! grep -E -q "$block_pattern" "$cmd_file"; then
    log_error "Missing block structure (Na/Nb/Nc pattern)"
    failures=$((failures + 1))
  else
    log_verbose "    ✓ Block structure found"
  fi

  # Check 2: CRITICAL BARRIER labels in Execute blocks
  log_verbose "  Checking CRITICAL BARRIER labels..."
  local barrier_count
  barrier_count=$(grep -o "CRITICAL BARRIER" "$cmd_file" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$barrier_count" -eq 0 ]; then
    log_error "No CRITICAL BARRIER labels found"
    failures=$((failures + 1))
  else
    log_verbose "    ✓ Found $barrier_count CRITICAL BARRIER labels"
  fi

  # Check 3: Task invocations (Execute blocks)
  log_verbose "  Checking Task invocations..."
  if ! grep -q "^Task {" "$cmd_file"; then
    log_error "No Task invocations found"
    failures=$((failures + 1))
  else
    log_verbose "    ✓ Task invocations found"
  fi

  # Check 4: Fail-fast verification (exit 1)
  log_verbose "  Checking fail-fast verification..."
  local exit_count
  exit_count=$(grep -o "exit 1" "$cmd_file" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$exit_count" -lt 2 ]; then
    log_error "Insufficient fail-fast verification (found $exit_count, expected >= 2)"
    failures=$((failures + 1))
  else
    log_verbose "    ✓ Found $exit_count fail-fast verification points"
  fi

  # Check 5: Error logging calls
  log_verbose "  Checking error logging..."
  if ! grep -q "log_command_error" "$cmd_file"; then
    log_error "No error logging calls found"
    failures=$((failures + 1))
  else
    log_verbose "    ✓ Error logging calls found"
  fi

  # Check 6: Checkpoint reporting
  log_verbose "  Checking checkpoint reporting..."
  local checkpoint_count
  checkpoint_count=$(grep -o "CHECKPOINT:" "$cmd_file" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$checkpoint_count" -eq 0 ]; then
    log_error "No checkpoint reporting found"
    failures=$((failures + 1))
  else
    log_verbose "    ✓ Found $checkpoint_count checkpoint reports"
  fi

  # Check 7: State transitions (Setup blocks)
  log_verbose "  Checking state transitions..."
  if ! grep -q "sm_transition" "$cmd_file"; then
    # Some commands may not use state machine (e.g., /errors in query mode)
    log_verbose "    ⚠ No state transitions found (may be acceptable for utility commands)"
  else
    log_verbose "    ✓ State transitions found"
  fi

  # Check 8: Variable persistence
  log_verbose "  Checking variable persistence..."
  if ! grep -q "append_workflow_state" "$cmd_file"; then
    # Some commands may use alternative persistence methods
    log_verbose "    ⚠ No append_workflow_state calls found (may use alternative persistence)"
  else
    log_verbose "    ✓ Variable persistence found"
  fi

  # Check 9: Recovery instructions
  log_verbose "  Checking recovery instructions..."
  local recovery_count
  recovery_count=$(grep -o "RECOVERY:" "$cmd_file" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$recovery_count" -eq 0 ]; then
    log_error "No recovery instructions found"
    failures=$((failures + 1))
  else
    log_verbose "    ✓ Found $recovery_count recovery instructions"
  fi

  # Check 10: "CANNOT be bypassed" warning
  log_verbose "  Checking delegation warnings..."
  if ! grep -q "CANNOT be bypassed" "$cmd_file"; then
    log_error "Missing 'CANNOT be bypassed' warning in Execute block"
    failures=$((failures + 1))
  else
    log_verbose "    ✓ Delegation warning found"
  fi

  # Check 11: Imperative Task Directives
  log_verbose "  Checking imperative Task directives..."
  local task_line_numbers=$(grep -n '^Task {' "$cmd_file" 2>/dev/null | cut -d: -f1 || true)
  local missing_directive=false

  for line_num in $task_line_numbers; do
    # Check lines [line_num-5 to line_num-1] for EXECUTE NOW or EXECUTE IF
    local start_line=$((line_num - 5))
    if [ $start_line -lt 1 ]; then
      start_line=1
    fi

    local has_execute=$(sed -n "${start_line},$((line_num-1))p" "$cmd_file" | \
                       grep -c -E 'EXECUTE (NOW|IF).*Task tool' 2>/dev/null || echo 0)

    if [ "$has_execute" -eq 0 ]; then
      log_error "Task block at line $line_num missing imperative directive (EXECUTE NOW/IF)"
      failures=$((failures + 1))
      missing_directive=true
    fi
  done

  if [ "$missing_directive" = false ] && [ -n "$task_line_numbers" ]; then
    log_verbose "    ✓ All Task blocks have imperative directives"
  elif [ -z "$task_line_numbers" ]; then
    log_verbose "    ⚠ No Task blocks found (may be acceptable for utility commands)"
  fi

  # Check 12: No Instructional Text Patterns
  log_verbose "  Checking for instructional text patterns..."
  local instructional_lines=$(grep -n 'Use the Task tool to invoke' "$cmd_file" 2>/dev/null | cut -d: -f1 || true)

  for line_num in $instructional_lines; do
    # Check if there's a Task block within 10 lines after this line
    local end_line=$((line_num + 10))
    local has_task=$(sed -n "${line_num},${end_line}p" "$cmd_file" | \
                    grep -c '^Task {' 2>/dev/null || echo 0)

    if [ "$has_task" -eq 0 ]; then
      log_error "Instructional text at line $line_num without actual Task invocation"
      failures=$((failures + 1))
    fi
  done

  if [ -z "$instructional_lines" ]; then
    log_verbose "    ✓ No instructional text patterns found"
  fi

  if [ "$failures" -eq 0 ]; then
    log_success "/$cmd - COMPLIANT (all checks passed)"
    return 0
  else
    log_error "/$cmd - NON-COMPLIANT ($failures checks failed)"
    return 1
  fi
}

# === MAIN EXECUTION ===

main() {
  echo ""
  echo "════════════════════════════════════════════════════════════════"
  echo "  Hard Barrier Subagent Delegation Compliance Validator"
  echo "════════════════════════════════════════════════════════════════"
  echo ""

  # Discover or use single command
  local commands
  if [ -n "$SINGLE_COMMAND" ]; then
    commands=("$SINGLE_COMMAND")
    echo "Validating single command: /$SINGLE_COMMAND"
  else
    mapfile -t commands < <(discover_commands)
    echo "Discovered ${#commands[@]} commands to validate"
  fi

  echo ""

  local total=0
  local passed=0
  local failed=0

  for cmd in "${commands[@]}"; do
    total=$((total + 1))
    if validate_command "$cmd"; then
      passed=$((passed + 1))
    else
      failed=$((failed + 1))
    fi
  done

  # Summary
  echo ""
  echo "════════════════════════════════════════════════════════════════"
  echo "  Compliance Report"
  echo "════════════════════════════════════════════════════════════════"
  echo ""
  echo "Total Commands: $total"
  echo "Passed: $passed"
  echo "Failed: $failed"

  local compliance_percentage=0
  if [ "$total" -gt 0 ]; then
    compliance_percentage=$((passed * 100 / total))
  fi

  echo "Compliance: ${compliance_percentage}%"
  echo ""

  if [ "$failed" -eq 0 ]; then
    echo "✓ All commands are COMPLIANT"
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    exit 0
  else
    echo "✗ $failed command(s) NON-COMPLIANT"
    echo ""
    echo "Run with --verbose for detailed check results"
    echo "Run with --command <name> to validate specific command"
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    exit 1
  fi
}

main
