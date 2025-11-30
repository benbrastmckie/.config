# Runtime Error Analysis: /todo Command Execution

**Report ID**: 002-runtime-error-analysis
**Created**: 2025-11-29
**Analysis Date**: 2025-11-29
**Complexity**: 2
**Research Topic**: Analyze runtime errors from /todo command execution to improve repair plan

## Executive Summary

The /todo command execution produced 3 distinct runtime errors during the setup phase (Block 1). These errors cascade from architectural mismatches and missing error handling integration:

1. **Library Path Error** (Exit 1): state-persistence.sh sourced from wrong directory
2. **Workflow Type Error** (Exit 127): "utility" passed to sm_init() not in valid enum
3. **Unbound Variable Error** (Exit 127): `$7` accessed in error-handling.sh with insufficient parameters

The errors were NOT captured in the error log because error logging initialization failed to complete before the crashes occurred. This analysis provides root causes and recommendations for each error.

---

## Detailed Error Analysis

### Error 1: Library Path Error - "Failed to source state-persistence.sh"

**Exit Code**: 1
**Message**: `ERROR: Failed to source state-persistence.sh`
**Location**: `/home/benjamin/.config/.claude/commands/todo.md` line 124
**Severity**: Critical (blocks execution)

#### Root Cause

The /todo command attempts to source state-persistence.sh from the wrong directory:

```bash
# Line 124 in todo.md - INCORRECT PATH
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
```

However, the actual file location is:

```
/home/benjamin/.config/.claude/lib/core/state-persistence.sh
```

The library is in `.claude/lib/core/` NOT `.claude/lib/workflow/`.

#### Verification

```bash
$ find /home/benjamin/.config/.claude/lib -name "state-persistence.sh"
/home/benjamin/.config/.claude/lib/core/state-persistence.sh
```

The workflow-state-machine.sh file IS correctly located in workflow/:

```bash
$ find /home/benjamin/.config/.claude/lib -name "workflow-state-machine.sh"
/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh
```

#### Why This Matters

- Line 120 correctly sources workflow-state-machine.sh from `.claude/lib/workflow/`
- Line 124 incorrectly mirrors that path for state-persistence.sh
- This is a copy-paste error: state-persistence.sh is a CORE library, not a WORKFLOW library
- The error message is silenced with `2>/dev/null`, masking the actual failure

#### Impact Chain

1. source fails silently due to 2>/dev/null
2. Exit 1 prevents any error logging from occurring
3. Subsequent script blocks never execute
4. Error is not recorded in error log (error logging not initialized yet)

---

### Error 2: Workflow Type Validation - "Invalid workflow_type: utility"

**Exit Code**: 127
**Message**: `ERROR: Invalid workflow_type: utility` followed by unbound variable error
**Location**: `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh` lines 425-427
**Severity**: Critical (blocks state machine)

#### Root Cause

The /todo command calls sm_init() with "utility" as the workflow_type:

```bash
# Line 211 in todo.md
sm_init "$WORKFLOW_DESC" "/todo" "utility" "1" "[]" || {
  ...
}
```

The sm_init() function only accepts these valid workflow types (line 421):

```bash
case "$workflow_type" in
  research-only|research-and-plan|research-and-revise|full-implementation|debug-only)
    : # Valid
    ;;
  *)
    echo "ERROR: Invalid workflow_type: $workflow_type" >&2
    echo "  Valid types: research-only, research-and-plan, research-and-revise, full-implementation, debug-only" >&2
    return 1
    ;;
esac
```

#### Why "utility" Is Invalid

The state machine was designed for **research-driven workflows** with:
- research_complexity (1-4) parameter
- research_topics_json classification
- Workflow progression through research/implementation phases

A utility command like /todo:
- Is not research-driven (it's a maintenance task)
- Has no research complexity
- Has no research topics
- Doesn't fit the workflow model

#### Architectural Mismatch

The /todo command is trying to use the state machine for what is essentially a utility/housekeeping task. The state machine is overengineered for this use case, designed for complex research-and-implementation workflows.

#### Parameter Analysis

When /todo calls `sm_init "$WORKFLOW_DESC" "/todo" "utility" "1" "[]"`:
- $1 (workflow_desc): ✓ Valid string
- $2 (command_name): ✓ Valid string
- $3 (workflow_type): ✗ **"utility" not in enum**
- $4 (research_complexity): ✓ "1" is valid integer 1-4
- $5 (research_topics_json): ✓ "[]" is valid JSON

The function returns 1 (failure) before reaching the next steps.

---

### Error 3: Unbound Variable - "$7 unbound variable"

**Exit Code**: 127
**Message**: `/home/benjamin/.config/.claude/lib/core/error-handling.sh: line 592: $7: unbound variable`
**Location**: `/home/benjamin/.config/.claude/lib/core/error-handling.sh` line 592
**Severity**: Medium (secondary error cascading from Error 2)

#### Root Cause

The error occurs in the log_command_error() function:

```bash
# Line 585-592 in error-handling.sh
log_command_error() {
  local command="${1:-unknown}"
  local workflow_id="${2:-unknown}"
  local user_args="${3:-}"
  local error_type="${4:-unknown}"
  local message="${5:-}"
  local source="${6:-unknown}"
  local context_json="$7"  # LINE 592 - PROBLEM HERE
  ...
}
```

The function is called with only 3 parameters (line 212-214 in todo.md):

```bash
log_command_error "state_error" \
  "Failed to initialize state machine" \
  '{"workflow_id":"'"$WORKFLOW_ID"'","command":"/todo"}'
```

This passes:
- $1 = "state_error"
- $2 = "Failed to initialize state machine"
- $3 = JSON object
- $4-$7 = unset (expected error_type, message, source, context_json)

#### Function Signature Mismatch

The call at line 212 treats parameters differently than the function expects:

```bash
# What the call provides:
log_command_error ERROR_TYPE MESSAGE CONTEXT_JSON
                  $1          $2       $3

# What the function expects:
log_command_error COMMAND WORKFLOW_ID USER_ARGS ERROR_TYPE MESSAGE SOURCE CONTEXT_JSON
                  $1      $2           $3        $4         $5      $6     $7
```

#### Why This Happens

The error trap setup (line 145) calls setup_bash_error_trap() which should initialize error handling, but since sm_init() fails before reaching that line, the error handling context is never established. The manual call to log_command_error() uses incomplete parameters.

#### set -u Impact

The script uses `set -u` (fail on unbound variables), so accessing $7 without it being set causes immediate exit with code 127.

---

## Error Capture Analysis: Why Errors Weren't Logged

### Error Log Infrastructure

The error logging system is defined in error-handling.sh (lines 529-535):

```bash
readonly ERROR_LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/data/logs"
# ... validation code ...
ERROR_LOG_FILE="${ERROR_LOG_DIR}/errors.jsonl"
```

Error logging requires:
1. CLAUDE_PROJECT_DIR to be set
2. ERROR_LOG_DIR to be created
3. ERROR_LOG_FILE to exist (created by ensure_error_log_exists)
4. Successful sourcing of error-handling.sh

### Why Errors Weren't Captured

**Error 1 Prevention**: Library sourcing fails at line 124, exits with code 1
- Error logging never initialized
- No error log entry possible
- Script terminates before any logging functions available

**Error 2 Prevention**: sm_init() fails, but this happens AFTER error-handling.sh is sourced
- The manual log_command_error() call at line 212 attempts recovery
- However, the call signature is incorrect (3 params instead of 7)

**Error 3 Prevention**: The incorrect log_command_error() call triggers the unbound variable error
- Script exits with code 127
- Error handling system crashes
- Error is never logged

### Key Missing Components

1. **No error buffering for pre-initialization errors**: The _EARLY_ERROR_BUFFER (line 65) is declared but errors aren't added to it before library sourcing
2. **No fallback for library sourcing failures**: When critical libraries fail to source, script immediately exits without logging
3. **No parameter validation before log_command_error() calls**: The manual call at line 212 uses wrong parameter order

---

## Root Cause Summary

| Error | Root Cause | Category | Preventable |
|-------|-----------|----------|-------------|
| State-persistence path | Copy-paste from workflow template | Configuration | Yes - code review |
| "utility" workflow type | Design mismatch (utility command using research state machine) | Architectural | Yes - separate path for utilities |
| Unbound variable $7 | Function signature mismatch in error handling call | Integration | Yes - parameter validation |

---

## Recommendations

### Priority 1: Fix Library Path (Critical)

**File**: `/home/benjamin/.config/.claude/commands/todo.md` line 124
**Change**: Update to correct directory

```bash
# BEFORE:
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/state-persistence.sh" 2>/dev/null || {

# AFTER:
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
```

**Verification**: Confirm state-persistence.sh is in core directory, not workflow directory

---

### Priority 2: Handle Utility Workflow Type (Critical)

**File**: `/home/benjamin/.config/.claude/commands/todo.md` lines 208-226
**Problem**: /todo is not a research workflow; it shouldn't use sm_init()

**Solution Options**:

**Option A - Remove state machine** (Recommended for utility commands)
```bash
# Remove the entire sm_init() and sm_transition() calls
# These are unnecessary for a utility command that doesn't fit the workflow model
# Keep the script simple and focused on the actual task

# Delete lines 208-226
```

**Option B - Use valid workflow type**
```bash
# If state tracking is truly needed, use "debug-only" as closest match
# But this is dishonest and pollutes the state machine with non-workflow tasks

sm_init "$WORKFLOW_DESC" "/todo" "debug-only" "1" "[]" || {
  # ... still problematic
}
```

**Recommendation**: Option A - Remove state machine entirely for /todo
- /todo is a utility command, not a research workflow
- State machine adds complexity without benefit
- Error handling can work without state machine

---

### Priority 3: Add Parameter Validation (Medium)

**File**: `/home/benjamin/.config/.claude/lib/core/error-handling.sh` lines 585-602
**Problem**: log_command_error() doesn't validate parameter count

**Solution**: Add parameter validation with helpful error message

```bash
log_command_error() {
  # Validate minimum parameters
  if [ $# -lt 1 ]; then
    echo "ERROR: log_command_error requires at least 1 parameter" >&2
    echo "Usage: log_command_error <error_type> [message] [source] [context_json]" >&2
    return 1
  fi

  # Handle variable-length parameters gracefully
  local error_type="${1:-unknown}"
  local message="${2:-}"
  local source="${3:-}"
  local context_json="${4:-{}}"

  # ... rest of function
}
```

---

### Priority 4: Improve Error Buffering (Medium)

**File**: `/home/benjamin/.config/.claude/commands/todo.md` lines 64-112
**Problem**: Errors before library sourcing aren't captured

**Solution**: Use the existing _EARLY_ERROR_BUFFER consistently

```bash
# Line 102: Add error to buffer instead of just echoing
_EARLY_ERROR_BUFFER+=("validation_error|Project directory not found or unset|CLAUDE_PROJECT_DIR environment variable must be set")
echo "ERROR: Failed to detect project directory" >&2
exit 1
```

Then after error logging is initialized (line 136), flush the buffer:

```bash
# After ensure_error_log_exists
for error_entry in "${_EARLY_ERROR_BUFFER[@]}"; do
  IFS='|' read -r err_type err_msg err_details <<< "$error_entry"
  log_command_error "$err_type" "$err_msg" "$err_details"
done
```

---

### Priority 5: Add Library Path Validation (Low)

**File**: All command files with library sourcing
**Problem**: Wrong library paths only discovered at runtime

**Solution**: Add validation step before sourcing

```bash
# After CLAUDE_PROJECT_DIR detection
validate_library_path() {
  local lib_path="$1"
  local lib_name="$(basename "$lib_path")"
  if [ ! -f "$lib_path" ]; then
    echo "ERROR: Library not found: $lib_name" >&2
    echo "  Expected at: $lib_path" >&2
    echo "  Please verify .claude/lib structure" >&2
    return 1
  fi
  return 0
}

# Before sourcing
validate_library_path "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1
```

---

## Error Logging Improvement Framework

To prevent similar errors in the future:

### 1. **Multi-Stage Error Capture**

```
Stage 1: Pre-initialization (errors before libraries load)
  → Buffer in _EARLY_ERROR_BUFFER array

Stage 2: Post-core initialization (after error-handling.sh)
  → Log via log_early_error()

Stage 3: Post-full initialization (after COMMAND_NAME/WORKFLOW_ID)
  → Log via log_command_error()

Stage 4: Command recovery (trap/error handlers)
  → Automatic logging via trap handlers
```

### 2. **Library Sourcing Safety**

Each critical library source should:
- Validate file exists before sourcing
- Capture error with context
- Exit with specific error code
- Buffer error for later logging

### 3. **Function Signature Documentation**

Every function that logs errors should have:
- Clear parameter documentation
- Validation of parameter count
- Examples of correct usage
- Default values for optional params

---

## Test Cases for Validation

After implementing fixes, test:

1. **Library Path Fix**
   ```bash
   /todo
   # Should run successfully without "Failed to source state-persistence.sh" error
   ```

2. **Error Capture**
   ```bash
   # Break library sourcing intentionally
   # Verify error is captured in error log
   cat .claude/data/logs/errors.jsonl | jq '.error_type'
   ```

3. **Parameter Validation**
   ```bash
   # Call log_command_error with different parameter counts
   # Verify graceful handling or helpful error messages
   ```

---

## Conclusion

The /todo command failures cascade from three issues:

1. **Configuration Error**: Wrong library path (fixable with one-line change)
2. **Design Mismatch**: Utility command using research workflow infrastructure (fixable by removing unnecessary state machine calls)
3. **Integration Gap**: Function signature mismatch in error handling (fixable with parameter validation)

All three issues are preventable with:
- Code review before commit (catches path errors)
- Architectural alignment (utility commands shouldn't use research state machine)
- Defensive parameter validation (log_command_error should validate inputs)

The error logging system itself is well-designed but never got a chance to activate because initialization failed. Once the library path and workflow type issues are resolved, error capture should work correctly for future failures.

