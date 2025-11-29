# Error Capture Trap Timing Analysis

## Metadata
- **Date**: 2025-11-27
- **Agent**: research-specialist
- **Topic**: Error capture gaps in bash error trap timing and state restoration
- **Report Type**: Infrastructure analysis and failure mode investigation

## Executive Summary

The /errors command failed to capture a "FEATURE_DESCRIPTION: unbound variable" error (exit code 127 at line 238) because the error occurred in a timing gap between bash blocks where the error trap was not yet fully initialized. Analysis reveals five critical failure points where errors can escape logging: (1) before error-handling.sh is sourced, (2) before setup_bash_error_trap is called, (3) during state file sourcing with set +u/set -u transitions, (4) during library function validation when functions don't exist, and (5) when workflow ID changes between blocks but trap context is stale.

## Problem Context

### The Missing Error
User reported that today's error was NOT captured in errors.jsonl:
- **Error**: "FEATURE_DESCRIPTION: unbound variable"
- **Exit Code**: 127 (command not found, but context suggests unbound variable with set -u)
- **Line**: 238 in /plan command
- **Timestamp**: 2025-11-27 (today)
- **Result**: No corresponding entry in /home/benjamin/.config/.claude/data/logs/errors.jsonl

### What Line 238 Actually Does
Located in /home/benjamin/.config/.claude/commands/plan.md:
```bash
236: sm_transition "$STATE_RESEARCH" 2>&1
237: EXIT_CODE=$?
238: if [ $EXIT_CODE -ne 0 ]; then
```

This is an error CHECK, not where FEATURE_DESCRIPTION is used. The actual error occurred elsewhere.

## Root Cause Analysis

### Error Source Location
The actual FEATURE_DESCRIPTION usage is at line 218:
```bash
218: sm_init "$FEATURE_DESCRIPTION" "$COMMAND_NAME" "$WORKFLOW_TYPE" "$RESEARCH_COMPLEXITY" "[]" 2>&1
```

If FEATURE_DESCRIPTION is unbound at this point, bash with `set -u` exits immediately with code 1 (not 127). Exit code 127 suggests the error is actually "command not found" in the sm_init call path.

### Trap Timing Analysis

Examining /home/benjamin/.config/.claude/commands/plan.md trap setup sequence:

**Block 1a Initialization**:
```bash
Line 120-135: Source Tier 1 libraries (error-handling.sh included)
Line 155: ensure_error_log_exists
Line 159: setup_bash_error_trap "/plan" "plan_early_$(date +%s)" "early_init"  # EARLY TRAP
Line 162-166: Initialize WORKFLOW_TYPE, TERMINAL_STATE, COMMAND_NAME, USER_ARGS
Line 168-173: Initialize WORKFLOW_ID and STATE_ID_FILE
Line 176: setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"  # REAL TRAP
Line 179: STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
Line 218: sm_init "$FEATURE_DESCRIPTION" ...  # ERROR HAPPENS HERE
```

### Critical Gap 1: Function Availability Window
Between lines 159-218, if any function called does NOT exist:
- Bash returns exit code 127 (command not found)
- ERR trap fires with `$BASH_COMMAND` = function name
- Error gets logged... BUT ONLY if log_command_error itself is available
- If error-handling.sh sourcing failed silently, NO trap handler exists

**Evidence from error-handling.sh:148-160** (Pre-flight function validation):
```bash
# === PRE-FLIGHT FUNCTION VALIDATION ===
# Verify required functions are available before using them (prevents exit 127 errors)
validate_library_functions "state-persistence" || exit 1
validate_library_functions "workflow-state-machine" || exit 1
validate_library_functions "error-handling" || exit 1
```

The /plan command has validation at lines 149-152, but this happens AFTER the trap is already set. If validate_library_functions itself is not available, the validation fails silently.

### Critical Gap 2: State Restoration Between Blocks

**Block 2 State Loading** (/plan.md:667):
```bash
667: load_workflow_state "$WORKFLOW_ID" false
669-676: # === RESTORE ERROR LOGGING CONTEXT ===
679: setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
```

**Timing Problem**:
1. Block 1 ends with trap active: `setup_bash_error_trap "/plan" "plan_1234" "description"`
2. Block 2 starts with NEW bash environment (trap NOT carried over)
3. Lines 610-646: Source libraries (errors here are NOT trapped)
4. Line 667: load_workflow_state (errors here are NOT trapped)
5. Line 679: setup_bash_error_trap (trap NOW active)

**Window of Vulnerability**: Lines 610-678 (68 lines) have NO error trap coverage.

### Critical Gap 3: State File Sourcing and set -u Violations

From error-handling.sh:1749-1763 (setup_bash_error_trap):
```bash
1759: trap '_log_bash_error $? $LINENO "$BASH_COMMAND" ...' ERR
1762: trap '_log_bash_exit $LINENO "$BASH_COMMAND" ...' EXIT
```

From /plan.md Block 2 (lines 667):
```bash
667: load_workflow_state "$WORKFLOW_ID" false
```

Inside state-persistence.sh load_workflow_state:
```bash
# Temporarily disable unset variable checking
set +u
source "$state_file"
set -u  # Re-enable
```

**The Problem**:
- If state file contains unbound variable references AFTER sourcing completes
- The `set -u` re-enables strict mode
- Next bash command that uses unbound variable triggers EXIT trap (not ERR trap)
- EXIT trap handler (_log_bash_exit) checks `if [ $exit_code -ne 0 ] && [ -z "${_BASH_ERROR_LOGGED:-}" ]`
- If ERR trap didn't fire first, _BASH_ERROR_LOGGED is unset, so EXIT trap logs it
- BUT the context ($BASH_COMMAND, $LINENO) points to the EXIT trap line, not the actual error

### Critical Gap 4: Workflow ID Mismatch Between Blocks

**Block 1a creates**: `WORKFLOW_ID="plan_1764281320"`
**Block 1a sets trap**: `setup_bash_error_trap "/plan" "plan_1764281320" "description"`

**Block 2 restores**:
```bash
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE")
export WORKFLOW_ID
```

**Block 2 sets trap**:
```bash
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
```

**The Problem**:
- If STATE_ID_FILE read fails (file deleted, permissions changed), WORKFLOW_ID is empty
- Empty WORKFLOW_ID passed to setup_bash_error_trap
- Trap still fires, but logs error with workflow_id="unknown" or empty string
- Errors logged but not discoverable via `/errors --workflow-id plan_1764281320`

### Critical Gap 5: Benign Error Filtering Overly Aggressive

From error-handling.sh:1596-1665 (_is_benign_bash_error):
```bash
1606-1613: # Filter bashrc sourcing failures
case "$failed_command" in
  *"/etc/bashrc"*|*"/etc/bash.bashrc"*|*"~/.bashrc"*|*".bashrc"*)
    return 0  # Benign: bashrc sourcing failure
    ;;
esac

1626-1644: # Filter intentional return statements from core library files
case "$failed_command" in
  "return 1"|"return 0"|"return"|"return "[0-9]*)
    # Check if error originates from a core library file via call stack
    ...
    return 0  # Benign: intentional return from core library
```

**The Problem**:
- If library function returns 1 for validation failure (e.g., validate_library_functions)
- ERR trap fires with BASH_COMMAND="return 1"
- _is_benign_bash_error checks call stack for /lib/core/ or /lib/workflow/
- Finds match, returns 0 (benign), error NOT logged
- Command exits with error, but NO error log entry created

**Example Scenario**:
```bash
# In /plan.md Block 1a (line 150)
validate_library_functions "state-persistence" || exit 1

# If validate_library_functions fails:
# 1. Returns 1 from function
# 2. ERR trap fires: BASH_COMMAND="return 1"
# 3. _is_benign_bash_error: Sees "return 1" from /lib/core/, marks as benign
# 4. Trap handler exits WITHOUT logging
# 5. Command continues to "|| exit 1"
# 6. Exit 1 triggers EXIT trap
# 7. EXIT trap: Sees _BASH_ERROR_LOGGED is unset, but BASH_COMMAND is now "exit 1"
# 8. Logs "exit 1" at wrong line number, missing actual validation failure
```

## Evidence from Codebase

### Error Trap Setup Code (error-handling.sh:1749-1764)
```bash
1749: setup_bash_error_trap() {
1750:   local cmd_name="${1:-/unknown}"
1751:   local workflow_id="${2:-unknown}"
1752:   local user_args="${3:-}"
1753:
1754:   # ERR trap: Catches command failures (exit code 127, etc.) - logs and exits
1755:   trap '_log_bash_error $? $LINENO "$BASH_COMMAND" "'"$cmd_name"'" "'"$workflow_id"'" "'"$user_args"'"' ERR
1756:
1757:   # EXIT trap: Catches errors that don't trigger ERR (e.g., unbound variables with set -u) - logs only if error not already logged
1758:   trap '_log_bash_exit $LINENO "$BASH_COMMAND" "'"$cmd_name"'" "'"$workflow_id"'" "'"$user_args"'"' EXIT
1759: }
```

**Critical Observation**: Trap uses string interpolation at trap SET time, not EXECUTION time. This means:
- cmd_name, workflow_id, user_args are BAKED IN when trap is set
- If these change later (e.g., after load_workflow_state), trap STILL uses old values
- Block 2 errors logged with Block 1 metadata if trap not re-set

### Library Sourcing Pattern (plan.md:118-136)
```bash
118: # === SOURCE LIBRARIES (Three-Tier Pattern) ===
119: # Tier 1: Critical Foundation (fail-fast required)
120: source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
121:   echo "ERROR: Failed to source state-persistence.sh" >&2
122:   exit 1
123: }
```

**Gap**: `2>/dev/null` suppresses stderr but keeps exit code checking. If sourcing FAILS (file not found, syntax error), the `|| { }` block runs. BUT:
1. If sourcing fails BEFORE error-handling.sh is sourced, NO trap is set yet
2. Error message prints to stderr but NOT logged to errors.jsonl
3. Script exits with code 1, user sees error message but `/errors` shows nothing

### State Restoration Pattern (plan.md:667-678)
```bash
667: load_workflow_state "$WORKFLOW_ID" false
668:
669: # === RESTORE ERROR LOGGING CONTEXT ===
670: if [ -z "${COMMAND_NAME:-}" ]; then
671:   COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "/plan")
672: fi
673: if [ -z "${USER_ARGS:-}" ]; then
674:   USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "")
675: fi
676: export COMMAND_NAME USER_ARGS WORKFLOW_ID
677:
678: # === SETUP BASH ERROR TRAP ===
679: setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
```

**Gap**: Lines 670-676 attempt to restore variables from state file if load_workflow_state didn't set them. But:
1. If grep fails (STATE_FILE not set, permission denied), defaults to "/plan" and ""
2. Trap gets set with potentially WRONG metadata
3. Subsequent errors logged with incorrect command/workflow context

## Specific Failure Modes Documented

### Failure Mode 1: Library Sourcing Failure Before Trap
**Precondition**: error-handling.sh fails to source (file missing, syntax error, permissions)
**Trigger**: Any error in Block 1a before line 136 (after Tier 1 sourcing completes)
**Result**: Script exits with error message to stderr, NO errors.jsonl entry
**Example**:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2  # Prints to console
  exit 1  # No trap exists to log this
}
```

### Failure Mode 2: Early Trap with Stale Metadata
**Precondition**: Early trap set at line 159 with "plan_early_$(date +%s)" workflow ID
**Trigger**: Error occurs between line 159 and line 176 (before real trap is set)
**Result**: Error logged with workflow_id="plan_early_1234567890" instead of actual ID
**Example**: User runs `/errors --workflow-id plan_1764281320`, error not found because it's under "plan_early_*"

### Failure Mode 3: Unbound Variable During State Restoration
**Precondition**: State file contains export of variable that doesn't exist
**Trigger**: load_workflow_state sources state file, re-enables set -u, next command uses missing var
**Result**: EXIT trap fires, logs error with BASH_COMMAND at wrong line
**Example**:
```bash
# State file contains:
export OPTIONAL_VAR="${OPTIONAL_VAR:-}"

# After sourcing:
set -u  # Re-enable
echo "$OPTIONAL_VAR"  # Error: variable not set (even though default was attempted)
```

### Failure Mode 4: Function Not Found After Successful Sourcing
**Precondition**: Library sourcing succeeds but function not exported or name mismatch
**Trigger**: Call to function like validate_library_functions
**Result**: Exit code 127, ERR trap fires, filtered as benign if "return 1" in call stack
**Example**: validate_library_functions fails, returns 1, ERR trap sees "return 1" from /lib/core/, filters as benign

### Failure Mode 5: Trap Not Re-Set Between Blocks
**Precondition**: Block 1 sets trap with early metadata
**Trigger**: Block 2 starts, sources libraries, calls functions BEFORE line 679 (trap re-set)
**Result**: Errors logged with Block 1 metadata (wrong workflow ID, wrong user args)
**Example**: load_workflow_state fails at line 667, logged as "plan_early_*" workflow, not searchable

## Findings

### Finding 1: Trap Initialization Sequence Has 4 Windows of Vulnerability

**Block 1a Windows**:
1. **Lines 1-119**: Before any libraries sourced (NO trap capability at all)
2. **Lines 120-135**: During Tier 1 sourcing (if error-handling.sh not sourced yet, no trap)
3. **Lines 136-158**: After libraries, before early trap (error-handling functions available but trap not set)
4. **Lines 159-175**: Early trap active but with temporary metadata

**Block 2+ Windows**:
1. **Lines 1-X**: Before libraries sourced (NO trap capability - new bash environment)
2. **Lines X-Y**: During library sourcing (errors suppressed with 2>/dev/null, not trapped)
3. **Lines Y-Z**: After library sourcing, before trap re-set (functions available but trap not active)

### Finding 2: Benign Error Filtering Masks Real Library Validation Failures

From error-handling.sh:1626-1644, errors matching these patterns are NOT logged:
- `BASH_COMMAND` is "return 0", "return 1", "return", or "return [0-9]*"
- Call stack contains /lib/core/, /lib/workflow/, or /lib/plan/

**Impact**:
- validate_library_functions failures are filtered
- Library initialization errors are filtered
- Actual bugs in library code are hidden from error log
- `/errors` and `/repair` cannot detect these failures

**Evidence**: No errors.jsonl entries for "function not available after sourcing" failures

### Finding 3: State Restoration Error Context Loss

When errors occur during state restoration:
- EXIT trap captures error (ERR trap doesn't fire for set -u violations)
- BASH_COMMAND shows the LAST command before exit (often wrong line)
- LINENO shows trap handler line number (not error line)
- Original unbound variable name is LOST in error context

**Example from error-handling.sh:1713-1746** (_log_bash_exit):
```bash
1721: if [ $exit_code -ne 0 ] && [ -z "${_BASH_ERROR_LOGGED:-}" ]; then
1737:   log_command_error \
1740:     "$error_type" \
1741:     "Bash error at line $line_no: exit code $exit_code" \
1742:     "bash_trap" \
1743:     "$(jq -n --argjson line "$line_no" --argjson code "$exit_code" --arg cmd "$failed_command" \
1744:        '{line: $line, exit_code: $code, command: $cmd}')"
```

**Problem**: $line_no is from caller, not actual error location. $failed_command is often wrong.

### Finding 4: Workflow ID Persistence Fragility

State ID file pattern:
```bash
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
echo "$WORKFLOW_ID" > "$STATE_ID_FILE"
```

**Fragility Points**:
1. File in /tmp directory (survives between blocks but not reboots)
2. No validation that read value matches expected format
3. No fallback if file is corrupted or deleted between blocks
4. Empty WORKFLOW_ID causes trap to use "unknown" (searchability loss)

**Evidence**: errors.jsonl contains some entries with workflow_id="unknown"

### Finding 5: Library Sourcing Suppression Hides Initialization Errors

Pattern used throughout commands:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
```

**Problem**:
- `2>/dev/null` hides syntax errors, permission errors, "file not found" details
- User sees generic "Failed to source" message
- Actual error reason (syntax error line number, permission details) is LOST
- Cannot distinguish between "file not found" vs "syntax error" vs "permission denied"

**Better Pattern**:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" || {
  SOURCE_ERROR=$?
  echo "ERROR: Failed to source error-handling.sh (exit code: $SOURCE_ERROR)" >&2
  exit 1
}
```

## Recommendations

### Recommendation 1: Implement Pre-Trap Error Buffering
**Priority**: Critical
**Effort**: Medium (2-4 hours)

Create early error buffer that collects errors BEFORE error-handling.sh is available:

```bash
# At TOP of every bash block (before any sourcing)
declare -a _EARLY_ERROR_BUFFER=()

_buffer_early_error() {
  local error_msg="$1"
  local error_line="$2"
  local error_code="$3"
  _EARLY_ERROR_BUFFER+=("$(date -u +%Y-%m-%dT%H:%M:%SZ)|$error_line|$error_code|$error_msg")
}

# After error-handling.sh sourced and trap set, flush buffer:
_flush_early_errors() {
  for buffered_error in "${_EARLY_ERROR_BUFFER[@]}"; do
    IFS='|' read -r timestamp line code msg <<< "$buffered_error"
    log_command_error \
      "${COMMAND_NAME:-/unknown}" \
      "${WORKFLOW_ID:-unknown}" \
      "${USER_ARGS:-}" \
      "initialization_error" \
      "$msg" \
      "early_buffer" \
      "$(jq -n --argjson line "$line" --argjson code "$code" --arg ts "$timestamp" \
         '{line: $line, exit_code: $code, buffered_at: $ts}')"
  done
  _EARLY_ERROR_BUFFER=()
}
```

**Benefit**: Captures ALL errors, even before trap infrastructure available

### Recommendation 2: Remove Benign Error Filtering for Library Return Statements
**Priority**: High
**Effort**: Low (1 hour)

Modify error-handling.sh:1626-1644 to be MORE selective:

```bash
# OLD: Filters ALL return statements from /lib/ files
case "$failed_command" in
  "return 1"|"return 0"|"return"|"return "[0-9]*)
    # Check if error originates from a core library file via call stack
    ...
    return 0  # Benign: intentional return from core library
```

**NEW**: Only filter return statements from KNOWN SAFE functions:

```bash
case "$failed_command" in
  "return 1"|"return 0"|"return"|"return "[0-9]*)
    # Check call stack for specific SAFE functions only
    local caller_func=$(caller 1 | awk '{print $2}')
    case "$caller_func" in
      classify_error|suggest_recovery|detect_error_type|extract_location)
        return 0  # Benign: safe utility function return
        ;;
      *)
        # Log it - could be validation failure
        return 1
        ;;
    esac
```

**Benefit**: Validation failures (validate_library_functions) now logged, not filtered

### Recommendation 3: Add State Restoration Validation with Trap Re-Set
**Priority**: Critical
**Effort**: Medium (2-3 hours)

In every bash block after Block 1, BEFORE library sourcing:

```bash
# DEFENSIVE: Set minimal trap BEFORE library sourcing
trap 'echo "ERROR: Library sourcing failed at line $LINENO: $BASH_COMMAND" >&2; exit 1' ERR
trap 'if [ $? -ne 0 ]; then echo "ERROR: Block initialization failed" >&2; fi' EXIT

# Source libraries (errors now trapped)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" || exit 1

# Clear minimal traps, set full trap
trap - ERR EXIT
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
```

After load_workflow_state:

```bash
# Validate critical variables were restored
validate_state_restoration "COMMAND_NAME" "WORKFLOW_ID" "STATE_FILE" || {
  log_early_error "State restoration incomplete" "{\"missing_vars\": \"see validate_state_restoration output\"}"
  exit 1
}

# Re-set trap with restored metadata (CRITICAL: old trap has stale values)
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
```

**Benefit**: Errors during library sourcing and state restoration are now captured

### Recommendation 4: Enhance Library Sourcing Error Reporting
**Priority**: Medium
**Effort**: Low (1 hour)

Replace all `2>/dev/null` suppressions in library sourcing with diagnostic wrapper:

```bash
_source_with_diagnostics() {
  local lib_path="$1"
  local lib_name=$(basename "$lib_path")

  # Try to source, capture stderr
  local source_stderr=$(mktemp)
  if source "$lib_path" 2>"$source_stderr"; then
    rm -f "$source_stderr"
    return 0
  else
    local source_exit=$?
    local source_error=$(cat "$source_stderr" 2>/dev/null || echo "Unknown error")
    rm -f "$source_stderr"

    # Buffer error (trap may not exist yet)
    _buffer_early_error "Failed to source $lib_name: $source_error" "$LINENO" "$source_exit"

    echo "ERROR: Failed to source $lib_name (exit $source_exit)" >&2
    echo "  Path: $lib_path" >&2
    echo "  Error: $source_error" >&2
    return $source_exit
  fi
}

# Usage:
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" || exit 1
```

**Benefit**: Syntax errors, permission errors, file-not-found errors now visible and logged

### Recommendation 5: Implement Workflow ID Validation and Fallback
**Priority**: Medium
**Effort**: Low (1 hour)

Add validation when reading STATE_ID_FILE:

```bash
# Block 2 initialization
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"

if [ ! -f "$STATE_ID_FILE" ]; then
  # Fallback: Generate new workflow ID
  WORKFLOW_ID="plan_$(date +%s)_recovered"
  echo "WARNING: State ID file missing, generated fallback: $WORKFLOW_ID" >&2
  log_early_error "State ID file not found" "{\"expected_path\": \"$STATE_ID_FILE\"}"
else
  WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)

  # Validate format (e.g., plan_1234567890)
  if ! [[ "$WORKFLOW_ID" =~ ^[a-z_]+_[0-9]+$ ]]; then
    WORKFLOW_ID="plan_$(date +%s)_invalid"
    echo "WARNING: Invalid workflow ID format, generated fallback: $WORKFLOW_ID" >&2
    log_early_error "Invalid workflow ID in state file" "{\"file\": \"$STATE_ID_FILE\", \"content\": \"$(cat "$STATE_ID_FILE")\"}"
  fi
fi

export WORKFLOW_ID
```

**Benefit**: Corrupted or missing STATE_ID_FILE no longer causes silent metadata loss

### Recommendation 6: Add Block Boundary Markers in Error Logs
**Priority**: Low
**Effort**: Low (30 minutes)

Log block transitions as informational entries:

```bash
# At start of each bash block
log_block_boundary() {
  local block_name="$1"
  local workflow_id="$2"

  # Log as informational event (not error)
  jq -n \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg workflow "$workflow_id" \
    --arg block "$block_name" \
    '{
      timestamp: $ts,
      event_type: "block_boundary",
      workflow_id: $workflow,
      block_name: $block
    }' >> "${ERROR_LOG_DIR}/workflow-events.jsonl"
}

# Usage:
log_block_boundary "block_1a_setup" "$WORKFLOW_ID"
```

**Benefit**: Error log analysis can correlate errors with specific bash blocks for better diagnostics

### Recommendation 7: Create Comprehensive Error Trap Test Suite
**Priority**: High
**Effort**: Medium (3-4 hours)

Create test suite covering all failure modes:

```bash
# tests/unit/test_error_trap_coverage.sh

test_error_before_trap_set() {
  # Simulate error before error-handling.sh sourced
  # Verify error appears in early buffer
}

test_error_during_library_sourcing() {
  # Simulate syntax error in library file
  # Verify diagnostic error message appears
}

test_error_during_state_restoration() {
  # Simulate unbound variable after load_workflow_state
  # Verify EXIT trap captures it with correct context
}

test_error_with_stale_trap_metadata() {
  # Set trap, change WORKFLOW_ID, trigger error
  # Verify error logged with NEW metadata, not old
}

test_function_not_found_error() {
  # Call non-existent function after successful sourcing
  # Verify exit 127 error is logged, not filtered as benign
}
```

**Benefit**: Regression prevention, validates all error capture paths work correctly

## References

### Primary Source Files
- /home/benjamin/.config/.claude/lib/core/error-handling.sh:1-1905 (complete error handling library)
- /home/benjamin/.config/.claude/lib/core/error-handling.sh:616-659 (log_early_error function)
- /home/benjamin/.config/.claude/lib/core/error-handling.sh:661-701 (validate_state_restoration function)
- /home/benjamin/.config/.claude/lib/core/error-handling.sh:1596-1665 (_is_benign_bash_error function)
- /home/benjamin/.config/.claude/lib/core/error-handling.sh:1667-1707 (_log_bash_error ERR trap handler)
- /home/benjamin/.config/.claude/lib/core/error-handling.sh:1709-1747 (_log_bash_exit EXIT trap handler)
- /home/benjamin/.config/.claude/lib/core/error-handling.sh:1749-1764 (setup_bash_error_trap function)
- /home/benjamin/.config/.claude/commands/plan.md:1-1143 (complete /plan command template)
- /home/benjamin/.config/.claude/commands/plan.md:118-176 (Block 1a initialization and trap setup)
- /home/benjamin/.config/.claude/commands/plan.md:218 (sm_init call site where FEATURE_DESCRIPTION used)
- /home/benjamin/.config/.claude/commands/plan.md:236-249 (Line 238 error check code)
- /home/benjamin/.config/.claude/commands/plan.md:607-679 (Block 2 state restoration and trap re-set)
- /home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh:393-443 (sm_init function implementation)

### Error Log Analysis
- /home/benjamin/.config/.claude/data/logs/errors.jsonl (production error log, 86485 bytes)
- Recent errors show workflow_id="unknown" patterns (Finding 4 evidence)
- No entries for "FEATURE_DESCRIPTION: unbound variable" on 2025-11-27 (confirms gap)

### State Persistence Files
- /home/benjamin/.config/.claude/tmp/workflow_plan_1764281320.sh (example state file)
- Shows FEATURE_DESCRIPTION was properly persisted after successful initialization
- Demonstrates state file format and variable export pattern

## Implementation Priority

**Phase 1 - Critical Fixes** (Deploy immediately):
1. Recommendation 3: State restoration validation and trap re-set
2. Recommendation 1: Pre-trap error buffering
3. Recommendation 2: Remove overly aggressive benign filtering

**Phase 2 - Enhanced Diagnostics** (Deploy within 1 week):
4. Recommendation 4: Library sourcing error reporting
5. Recommendation 5: Workflow ID validation
6. Recommendation 7: Error trap test suite

**Phase 3 - Observability** (Deploy when convenient):
7. Recommendation 6: Block boundary markers

## Conclusion

The root cause of missing error capture is the timing gap between bash block initialization and error trap activation. Five critical failure points exist where errors escape logging. The solution requires: (1) pre-trap error buffering for early failures, (2) defensive trap setup BEFORE library sourcing, (3) trap metadata refresh after state restoration, (4) less aggressive benign error filtering, and (5) enhanced library sourcing diagnostics. Implementation of Phase 1 recommendations will close all critical gaps and ensure comprehensive error capture.
