# Preserved Elements from Plan 884: Research Report

## Overview

This report documents the valuable elements preserved from Plan 884 (Build Error Logging Discrepancy - System-Wide Debug Strategy) that were not covered by the existing High Priority plans.

## Context

Plan 884 was created on 2025-11-20 to address system-wide error logging gaps. During the 2025-11-21 plan relevance review, several findings emerged:

1. **Plan 884 Phase 0 is OBSOLETE**: The core premise that `save_completed_states_to_state` doesn't exist was incorrect - the function exists in `workflow-state-machine.sh:126`

2. **Plan 884 Phase 2 DUPLICATES Plan 2**: Both add error logging to expand.md and collapse.md

3. **Valuable elements remain**: Three components provide unique value not covered elsewhere

## Preserved Elements

### 1. `validate_required_functions()` Helper

**Source**: Plan 884 Phase 1

**Purpose**: Defensive function validation after library sourcing to catch missing functions early with proper error logging.

**Value Proposition**:
- Catches "command not found" errors before runtime
- Provides actionable error messages with function names
- Logs to centralized error system for queryability
- Reusable across all commands

**Implementation Pattern** (from Plan 884):
```bash
validate_required_functions() {
  local required_functions="$1"
  local missing_functions=""
  for func in $required_functions; do
    if ! type "$func" &>/dev/null; then
      missing_functions="$missing_functions $func"
    fi
  done
  if [ -n "$missing_functions" ]; then
    log_command_error \
      "${COMMAND_NAME:-unknown}" \
      "${WORKFLOW_ID:-unknown}" \
      "${USER_ARGS:-}" \
      "dependency_error" \
      "Missing required functions:$missing_functions" \
      "function_validation" \
      "$(jq -n --arg funcs "$missing_functions" '{missing_functions: $funcs}')"
    echo "ERROR: Missing functions:$missing_functions" >&2
    exit 1
  fi
}
```

### 2. Error Logging for convert-docs.md

**Source**: Plan 884 Phase 2

**Gap**: Plan 2 (Error Logging Infrastructure Migration) covers expand.md and collapse.md but does NOT include convert-docs.md

**Value Proposition**:
- Completes orchestrator command coverage
- convert-docs.md is a user-facing command that should log errors
- Achieves 100% error logging coverage for orchestrator commands

**Required Integration**:
- Source error-handling.sh after project directory detection
- Initialize error log with `ensure_error_log_exists`
- Set COMMAND_NAME, WORKFLOW_ID, USER_ARGS
- Setup bash error trap
- Add log_command_error at failure points

### 3. `execute_with_logging()` Wrapper

**Source**: Plan 884 Phase 3

**Purpose**: Reduces boilerplate error handling code across commands by wrapping operations with automatic error logging.

**Value Proposition**:
- Turns 6-8 lines of error handling into 1 line
- Standardizes error logging pattern
- Reduces copy-paste errors
- Makes commands more readable

**Implementation Pattern** (from Plan 884):
```bash
execute_with_logging() {
  local operation="$1"
  shift
  local output
  local exit_code

  output=$("$@" 2>&1)
  exit_code=$?

  if [ $exit_code -ne 0 ]; then
    log_command_error \
      "${COMMAND_NAME:-unknown}" \
      "${WORKFLOW_ID:-unknown}" \
      "${USER_ARGS:-}" \
      "execution_error" \
      "$operation failed: $(echo "$output" | head -1)" \
      "execute_wrapper" \
      "$(jq -n --argjson code "$exit_code" --arg op "$operation" \
         '{exit_code: $code, operation: $op}')"
    echo "$output" >&2
  fi

  return $exit_code
}
```

**Usage Example**:
```bash
# Before (6-8 lines):
critical_operation
OP_EXIT=$?
if [ $OP_EXIT -ne 0 ]; then
  log_command_error ...
  exit 1
fi

# After (1 line):
execute_with_logging "Critical operation" critical_operation || exit 1
```

## Relationship to Existing Plans

| Element | Plan 2 Coverage | This Plan |
|---------|----------------|-----------|
| expand.md error logging | Covered | Skip |
| collapse.md error logging | Covered | Skip |
| convert-docs.md error logging | NOT covered | Include |
| validate_required_functions() | NOT covered | Include |
| execute_with_logging() | NOT covered | Include |

## Implementation Priority

1. **validate_required_functions()** - High value, low effort, prevents runtime errors
2. **execute_with_logging()** - Medium value, low effort, reduces boilerplate
3. **convert-docs.md error logging** - Medium value, medium effort, completes coverage

## Success Criteria

- [ ] `validate_required_functions()` exported from error-handling.sh
- [ ] `execute_with_logging()` exported from error-handling.sh
- [ ] convert-docs.md has full error logging integration
- [ ] All new functions have unit tests
- [ ] Documentation updated
