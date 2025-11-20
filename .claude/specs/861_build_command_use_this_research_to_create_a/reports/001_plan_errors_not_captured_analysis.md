# Plan Command Errors Not Captured by /errors - Root Cause Analysis

## Metadata
- **Date**: 2025-11-20
- **Agent**: research-specialist
- **Topic**: Plan command error logging gap analysis and comparison with build command
- **Report Type**: Root cause analysis and refactor requirements

## Executive Summary

The /plan command encountered "unbound variable" errors (`USER_ARGS: unbound variable` at line 316 in Block 2, and `PLAN_PATH: unbound variable` at line 248 in Block 3) that were not captured by the /errors command. Root cause analysis reveals **three critical issues**: (1) Block 1 variables `COMMAND_NAME` and `USER_ARGS` are exported but never persisted to state, causing reference errors when Blocks 2 and 3 attempt to use them in `log_command_error()` calls after loading state, (2) early validation errors in Block 1 (lines 49-91) bypass error logging entirely, and (3) the errors manifest as bash "unbound variable" errors (exit code 127) rather than being logged through the centralized error logging system. The /build command exhibits identical state persistence issues, indicating a systemic pattern across all multi-block workflow commands.

## Findings

### 1. Unbound Variable Errors in /plan Output

**Location**: `/home/benjamin/.config/.claude/plan-output.md`

**Error 1** (Block 2, line 29):
```
● Bash(set +H  # CRITICAL: Disable history expansion…)
  ⎿  Error: Exit code 127
     /run/current-system/sw/bin/bash: line 316: USER_ARGS: unbound variable
```

**Error 2** (Block 3, line 199):
```
● Bash(set +H  # CRITICAL: Disable history expansion…)
  ⎿  Error: Exit code 127
     /run/current-system/sw/bin/bash: line 248: PLAN_PATH: unbound variable
```

**Context**: These errors occurred during error logging attempts - the commands tried to call `log_command_error()` with undefined variables after state restoration, causing bash to exit with code 127 (command not found / unbound variable).

### 2. Root Cause: Missing State Persistence for Error Logging Variables

**Analysis of Block 1** (`/home/benjamin/.config/.claude/commands/plan.md`, lines 139-143):

```bash
WORKFLOW_TYPE="research-and-plan"
TERMINAL_STATE="plan"
COMMAND_NAME="/plan"
USER_ARGS="$FEATURE_DESCRIPTION"
export COMMAND_NAME USER_ARGS
```

**Problem Identified**:
- Variables are **exported** for use within Block 1
- Variables are **NOT persisted** to state file via `append_workflow_state()`
- Subsequent blocks (2, 3) call `load_workflow_state()` which does NOT restore exported variables
- When errors occur in Blocks 2/3, `log_command_error()` references undefined `$COMMAND_NAME` and `$USER_ARGS`

**Verification** - State persistence calls in Block 1 (lines 250-260):
```bash
append_workflow_state "CLAUDE_PROJECT_DIR" "$CLAUDE_PROJECT_DIR"
append_workflow_state "SPECS_DIR" "$SPECS_DIR"
append_workflow_state "RESEARCH_DIR" "$RESEARCH_DIR"
append_workflow_state "PLANS_DIR" "$PLANS_DIR"
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
append_workflow_state "TOPIC_NAME" "$TOPIC_NAME"
append_workflow_state "TOPIC_NUM" "$TOPIC_NUM"
append_workflow_state "FEATURE_DESCRIPTION" "$FEATURE_DESCRIPTION"
append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"
append_workflow_state "ORIGINAL_PROMPT_FILE_PATH" "$ORIGINAL_PROMPT_FILE_PATH"
append_workflow_state "ARCHIVED_PROMPT_PATH" "${ARCHIVED_PROMPT_PATH:-}"
```

**Gap**: `COMMAND_NAME` and `USER_ARGS` are missing from persistence calls.

### 3. Error Logging Attempts with Unbound Variables

**Block 2 Example** (`plan.md`, lines 332-341):

```bash
load_workflow_state "$WORKFLOW_ID" false

# === VALIDATE STATE AFTER LOAD ===
if [ -z "$STATE_FILE" ]; then
  # Log to centralized error log
  log_command_error \
    "$COMMAND_NAME" \    # ← UNBOUND! Not restored from state
    "$WORKFLOW_ID" \
    "$USER_ARGS" \       # ← UNBOUND! Not restored from state
    "state_error" \
    "State file path not set after load" \
    "bash_block_2" \
    "$(jq -n --arg workflow "$WORKFLOW_ID" '{workflow_id: $workflow}')"
```

**Trigger Sequence**:
1. Block 2 calls `load_workflow_state "$WORKFLOW_ID" false`
2. State file contains no `COMMAND_NAME` or `USER_ARGS` assignments
3. Bash reaches `log_command_error "$COMMAND_NAME" ...` call
4. With `set -u` semantics (or strict mode), bash throws "unbound variable" error
5. Block exits with code 127 before `log_command_error()` executes
6. Error is never logged to centralized error log

**Block 3 Example** (`plan.md`, lines 604-613):

```bash
# Validate PLAN_PATH was set by Block 2
if [ -z "$PLAN_PATH" ]; then
  # Log to centralized error log
  log_command_error \
    "$COMMAND_NAME" \    # ← UNBOUND! Not restored from state
    "$WORKFLOW_ID" \
    "$USER_ARGS" \       # ← UNBOUND! Not restored from state
    "state_error" \
    "PLAN_PATH not found in state" \
    "bash_block_3" \
    "$(jq -n '{message: "PLAN_PATH not set by Block 2"}')"
```

### 4. Comparison with /build Command

**Analysis**: The /build command (`/home/benjamin/.config/.claude/commands/build.md`) exhibits the **exact same pattern**.

**Block 1 Initialization** (lines 211-213):
```bash
COMMAND_NAME="/build"
USER_ARGS="$PLAN_FILE"
export COMMAND_NAME USER_ARGS
```

**State Persistence** - Grep search for `append_workflow_state.*COMMAND_NAME|append_workflow_state.*USER_ARGS`:
```
No matches found
```

**Block 1b Error Logging** (lines 362-369):
```bash
load_workflow_state "$WORKFLOW_ID" false

if [ -z "$STATE_FILE" ]; then
  log_command_error \
    "$COMMAND_NAME" \    # ← Same issue: UNBOUND after load
    "$WORKFLOW_ID" \
    "$USER_ARGS" \       # ← Same issue: UNBOUND after load
    "state_error" \
```

**Conclusion**: This is a **systemic issue** affecting all multi-block workflow commands (/plan, /build, likely /debug, /repair, /research, /revise).

### 5. Early Validation Errors Not Logged

**Block 1 Early Exits** (`plan.md`, lines 49-91) - **NO error logging**:

**Error Case 1** (line 49-52): Empty feature description
```bash
if [ -z "$FEATURE_DESCRIPTION" ]; then
  echo "ERROR: Feature description is empty" >&2
  echo "Usage: /plan \"<feature description>\"" >&2
  exit 1  # ← NO log_command_error() call
fi
```

**Error Case 2** (line 64-66): Invalid complexity
```bash
if ! echo "$RESEARCH_COMPLEXITY" | grep -Eq "^[1-4]$"; then
  echo "ERROR: Invalid research complexity: $RESEARCH_COMPLEXITY (must be 1-4)" >&2
  exit 1  # ← NO log_command_error() call
fi
```

**Error Case 3** (line 78-80): File not found
```bash
if [ ! -f "$ORIGINAL_PROMPT_FILE_PATH" ]; then
  echo "ERROR: Prompt file not found: $ORIGINAL_PROMPT_FILE_PATH" >&2
  exit 1  # ← NO log_command_error() call
fi
```

**Error Case 4** (line 88-90): Invalid --file flag
```bash
elif [[ "$FEATURE_DESCRIPTION" =~ --file ]]; then
  echo "ERROR: --file flag requires a path argument" >&2
  echo "Usage: /plan --file /path/to/prompt.md" >&2
  exit 1  # ← NO log_command_error() call
fi
```

**Error Case 5** (line 107-110): Project directory detection failure
```bash
if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1  # ← NO log_command_error() call
fi
```

**Why These Errors Aren't Logged**:
1. Error logging library sourced at line 118 (AFTER validation errors)
2. `ensure_error_log_exists` called at line 136 (AFTER validation errors)
3. `COMMAND_NAME` and `USER_ARGS` set at lines 141-142 (AFTER validation errors)
4. Early validation errors exit before error logging infrastructure is initialized

**Paradox**: Cannot log errors that occur before error logging is initialized, BUT error logging cannot be initialized before project directory is detected.

### 6. Comparison with /build Command - Identical Early Validation Gap

**Build Command Analysis** (`build.md`, lines 83-150):

The /build command has the same early validation structure:

**Block 1 Structure**:
1. Lines 83-100: Argument validation (NO error logging)
2. Lines 102-127: Project directory detection (NO error logging)
3. Lines 129-141: Library sourcing including error-handling.sh
4. Line 154: `ensure_error_log_exists`
5. Lines 211-213: Set `COMMAND_NAME` and `USER_ARGS`

**Early Exit Examples**:

Line 90-93 (plan file argument missing):
```bash
if [ -z "$PLAN_FILE" ]; then
  echo "ERROR: Plan file path required" >&2
  echo "Usage: /build <plan-file> [starting-phase]" >&2
  exit 1  # ← NO error logging
fi
```

Line 98-100 (plan file not found):
```bash
if [ ! -f "$PLAN_FILE" ]; then
  echo "ERROR: Plan file not found: $PLAN_FILE" >&2
  exit 1  # ← NO error logging
fi
```

Line 115-117 (project directory not found):
```bash
if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1  # ← NO error logging
fi
```

### 7. Error Logging Standards Documentation

**Reference**: `/home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md`

**Expected Pattern** (lines 104-129):
```bash
# Source error handling library
source "${CLAUDE_CONFIG}/.claude/lib/core/error-handling.sh" 2>/dev/null

# Command metadata
COMMAND_NAME="/build"
WORKFLOW_ID="build_$(date +%Y%m%d_%H%M%S)"
USER_ARGS="$*"

# Ensure error log exists
ensure_error_log_exists

# Example: Log validation error
if [ -z "$PLAN_FILE" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "$ERROR_TYPE_VALIDATION" \
    "Plan file path required" \
    "bash_block" \
    '{"provided_args": "'"$*"'"}'

  exit 1
fi
```

**Current Implementation Gap**: Commands perform validation BEFORE sourcing error-handling.sh and setting COMMAND_NAME/USER_ARGS.

### 8. Why Errors Weren't Captured by /errors Command

**Analysis**:

1. **Unbound Variable Errors**: Bash exits with code 127 when encountering undefined variables, preventing `log_command_error()` from executing
2. **Early Validation Errors**: Exit before error logging is initialized
3. **State Persistence Gap**: `COMMAND_NAME` and `USER_ARGS` not persisted to state file
4. **Catch-22 Scenario**: Cannot log project detection errors because error logging requires project directory to be detected first

**Result**: None of these error paths wrote to `/home/benjamin/.config/.claude/data/logs/errors.jsonl`.

**Verification** - Build Command Report Finding (lines 11-12):
> "The root cause is that **validation errors written directly to stderr with `echo` statements are not automatically logged** - only errors explicitly logged via `log_command_error()` function calls appear in the queryable error log."

This applies equally to /plan command.

## Recommendations

### 1. Persist COMMAND_NAME and USER_ARGS to State

**Action**: Add state persistence for error logging variables in all workflow commands.

**Implementation Pattern**:

```bash
# In Block 1, after setting COMMAND_NAME and USER_ARGS:
COMMAND_NAME="/plan"
USER_ARGS="$FEATURE_DESCRIPTION"
export COMMAND_NAME USER_ARGS

# NEW: Persist to state
append_workflow_state "COMMAND_NAME" "$COMMAND_NAME"
append_workflow_state "USER_ARGS" "$USER_ARGS"
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"
```

**Files Affected**:
- `/home/benjamin/.config/.claude/commands/plan.md` (after line 143)
- `/home/benjamin/.config/.claude/commands/build.md` (after line 213)
- `/home/benjamin/.config/.claude/commands/debug.md` (verify and add)
- `/home/benjamin/.config/.claude/commands/repair.md` (verify and add)
- `/home/benjamin/.config/.claude/commands/research.md` (verify and add)
- `/home/benjamin/.config/.claude/commands/revise.md` (verify and add)

**Verification Check**: After implementation, grep for `export COMMAND_NAME USER_ARGS` should be followed within 5 lines by `append_workflow_state "COMMAND_NAME"` and `append_workflow_state "USER_ARGS"`.

### 2. Add Early Validation Error Logging with Bootstrap Pattern

**Problem**: Cannot log errors before error logging is initialized.

**Solution**: Use bootstrap error logging pattern with fallback.

**Implementation Pattern**:

```bash
# === BOOTSTRAP ERROR LOGGING ===
# Minimal initialization before validation - use fallback if project dir unknown
COMMAND_NAME="/plan"
TEMP_ERROR_LOG="${HOME}/.claude/data/logs/errors.jsonl"
mkdir -p "$(dirname "$TEMP_ERROR_LOG")" 2>/dev/null

# Bootstrap log function (fallback before full initialization)
log_bootstrap_error() {
  local error_type="$1"
  local message="$2"
  local context="$3"

  local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local json_entry=$(jq -c -n \
    --arg timestamp "$timestamp" \
    --arg command "$COMMAND_NAME" \
    --arg error_type "$error_type" \
    --arg message "$message" \
    --arg context "$context" \
    '{
      timestamp: $timestamp,
      environment: "production",
      command: $command,
      workflow_id: "bootstrap",
      user_args: "",
      error_type: $error_type,
      error_message: $message,
      source: "bootstrap",
      stack: [],
      context: {raw: $context}
    }')

  echo "$json_entry" >> "$TEMP_ERROR_LOG" 2>/dev/null || true
}

# === EARLY VALIDATION WITH ERROR LOGGING ===
FEATURE_DESCRIPTION=$(cat "$TEMP_FILE" 2>/dev/null || echo "")

if [ -z "$FEATURE_DESCRIPTION" ]; then
  log_bootstrap_error "validation_error" "Feature description is empty" "temp_file: $TEMP_FILE"
  echo "ERROR: Feature description is empty" >&2
  echo "Usage: /plan \"<feature description>\"" >&2
  exit 1
fi

# ... rest of validations with log_bootstrap_error calls ...

# === FULL ERROR LOGGING INITIALIZATION ===
# Now that project dir is detected, source full error-handling library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null
ensure_error_log_exists

# Set full command metadata
WORKFLOW_ID="plan_$(date +%s)"
USER_ARGS="$FEATURE_DESCRIPTION"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# From this point, use full log_command_error() function
```

**Alternative (Simpler)**: Accept that early validation errors cannot be logged, document this limitation, and focus on ensuring post-initialization errors are logged.

### 3. Restore Error Logging Variables After State Load

**Action**: In Blocks 2 and 3, restore `COMMAND_NAME`, `USER_ARGS`, and `WORKFLOW_ID` from state before attempting error logging.

**Implementation Pattern**:

```bash
# Block 2/3 after load_workflow_state
load_workflow_state "$WORKFLOW_ID" false

# === RESTORE ERROR LOGGING CONTEXT ===
# CRITICAL: Restore these before any log_command_error() calls
if [ -z "$COMMAND_NAME" ]; then
  COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2-)
fi
if [ -z "$USER_ARGS" ]; then
  USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2-)
fi
if [ -z "$WORKFLOW_ID" ]; then
  # Workflow ID should be available from STATE_ID_FILE, but verify
  WORKFLOW_ID=$(grep "^WORKFLOW_ID=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2-)
fi

# Export for subprocess access
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# === NOW SAFE TO USE log_command_error() ===
if [ -z "$STATE_FILE" ]; then
  log_command_error \
    "$COMMAND_NAME" \    # ← Now defined
    "$WORKFLOW_ID" \
    "$USER_ARGS" \       # ← Now defined
    "state_error" \
    "State file path not set after load" \
    "bash_block_2" \
    "$(jq -n --arg workflow "$WORKFLOW_ID" '{workflow_id: $workflow}')"
  # ...
fi
```

**Files Affected**: All blocks in /plan, /build, /debug, /repair, /research, /revise that call `load_workflow_state()`.

### 4. Update Error Logging Standards Documentation

**Action**: Enhance error logging pattern documentation to explicitly address:
1. State persistence requirements for error logging variables
2. Bootstrap error logging pattern for pre-initialization errors
3. Variable restoration pattern after state load
4. Anti-pattern: Using error logging variables before persistence/restoration

**File**: `/home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md`

**New Section to Add**:

```markdown
### State Persistence for Multi-Block Commands

**Requirement**: Commands with multiple bash blocks MUST persist error logging variables to state.

**Critical Variables**:
- `COMMAND_NAME`: Command identifier (e.g., "/plan", "/build")
- `USER_ARGS`: User-provided arguments (for error context)
- `WORKFLOW_ID`: Unique workflow identifier

**Pattern**:

```bash
# Block 1: Set and persist
COMMAND_NAME="/plan"
USER_ARGS="$FEATURE_DESCRIPTION"
WORKFLOW_ID="plan_$(date +%s)"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

append_workflow_state "COMMAND_NAME" "$COMMAND_NAME"
append_workflow_state "USER_ARGS" "$USER_ARGS"
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"

# Blocks 2+: Restore after load
load_workflow_state "$WORKFLOW_ID" false

# Restore error logging context
COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" | cut -d'=' -f2-)
USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" | cut -d'=' -f2-)
WORKFLOW_ID=$(grep "^WORKFLOW_ID=" "$STATE_FILE" | cut -d'=' -f2-)
export COMMAND_NAME USER_ARGS WORKFLOW_ID
```

**Anti-Pattern**:
```bash
# DON'T: Use error logging variables without restoration
load_workflow_state "$WORKFLOW_ID" false
# $COMMAND_NAME and $USER_ARGS are UNBOUND here!
log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" ...
```
```

### 5. Create Compliance Test for Error Logging Variable Persistence

**Action**: Create automated test to verify all multi-block commands properly persist and restore error logging variables.

**Test File**: `/home/benjamin/.config/.claude/tests/test_error_logging_state_persistence.sh`

**Test Logic**:
1. Parse each workflow command for bash blocks
2. Verify Block 1 includes `append_workflow_state "COMMAND_NAME"`
3. Verify Block 1 includes `append_workflow_state "USER_ARGS"`
4. Verify Block 1 includes `append_workflow_state "WORKFLOW_ID"`
5. Verify Blocks 2+ restore these variables after `load_workflow_state()`
6. Verify restoration happens BEFORE first `log_command_error()` call
7. Flag violations for manual review

**Success Criteria**: All multi-block commands properly persist and restore error logging context.

### 6. Standardize Error Logging Variable Names

**Action**: Document standard variable names for error logging across all commands.

**Standard Variables**:
- `COMMAND_NAME`: Always starts with "/" (e.g., "/plan", "/build")
- `USER_ARGS`: Original user input (description, file path, etc.)
- `WORKFLOW_ID`: Pattern: `{command_name}_$(date +%s)` (e.g., "plan_1732125045")

**Update**: `/home/benjamin/.config/.claude/docs/reference/standards/code-standards.md`

**Add Section**:
```markdown
## Error Logging Variable Standards

**Required Variables** (all commands):
- `COMMAND_NAME`: Command identifier with leading slash (e.g., "/plan")
- `USER_ARGS`: User-provided arguments (empty string if none)
- `WORKFLOW_ID`: Unique workflow identifier with timestamp

**Naming Convention**:
- `WORKFLOW_ID` format: `{command_basename}_{unix_timestamp}`
- Example: `plan_1732125045`, `build_1732125123`

**Persistence Requirement**:
All multi-block commands MUST persist these variables to state via `append_workflow_state()`.
```

### 7. Add Defensive Coding Pattern for Unbound Variables

**Action**: Add fallback defaults for error logging variables to prevent unbound variable errors.

**Pattern**:

```bash
# After load_workflow_state, set defaults if restoration fails
COMMAND_NAME="${COMMAND_NAME:-/unknown}"
USER_ARGS="${USER_ARGS:-}"
WORKFLOW_ID="${WORKFLOW_ID:-unknown_$(date +%s)}"

# Now safe to use in log_command_error() even if state restoration failed
log_command_error \
  "$COMMAND_NAME" \    # Will be "/unknown" if not restored
  "$WORKFLOW_ID" \     # Will be "unknown_timestamp" if not restored
  "$USER_ARGS" \       # Will be "" if not restored
  "state_error" \
  "State file path not set after load" \
  "bash_block_2" \
  '{}'
```

**Benefit**: Ensures errors are logged even if state persistence/restoration fails.

### 8. Update Command Development Guide

**Action**: Add error logging variable persistence to command development fundamentals.

**File**: `/home/benjamin/.config/.claude/docs/guides/development/command-development/command-development-fundamentals.md`

**Section to Add**:

```markdown
## Error Logging Variable Persistence

**Requirement**: Multi-block commands MUST persist error logging variables to state.

**Block 1 Pattern**:
```bash
# Set command metadata
COMMAND_NAME="/your-command"
USER_ARGS="$user_input"
WORKFLOW_ID="your_command_$(date +%s)"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# CRITICAL: Persist to state
append_workflow_state "COMMAND_NAME" "$COMMAND_NAME"
append_workflow_state "USER_ARGS" "$USER_ARGS"
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"
```

**Blocks 2+ Pattern**:
```bash
# Load state
load_workflow_state "$WORKFLOW_ID" false

# CRITICAL: Restore error logging context BEFORE error logging calls
COMMAND_NAME="${COMMAND_NAME:-$(grep "^COMMAND_NAME=" "$STATE_FILE" | cut -d'=' -f2-)}"
USER_ARGS="${USER_ARGS:-$(grep "^USER_ARGS=" "$STATE_FILE" | cut -d'=' -f2-)}"
WORKFLOW_ID="${WORKFLOW_ID:-$(grep "^WORKFLOW_ID=" "$STATE_FILE" | cut -d'=' -f2-)}"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# NOW safe to call log_command_error()
```

**Why This Matters**: Without persistence, subsequent blocks cannot log errors because `log_command_error()` requires these variables.
```

## References

### Primary Files Analyzed
- `/home/benjamin/.config/.claude/plan-output.md` (lines 1-238) - Plan command execution output showing unbound variable errors
- `/home/benjamin/.config/.claude/commands/plan.md` (full file) - Plan command implementation showing missing state persistence
- `/home/benjamin/.config/.claude/commands/build.md` (lines 83-400) - Build command implementation showing identical pattern
- `/home/benjamin/.config/.claude/lib/core/error-handling.sh` (lines 410-506) - Error logging function requiring COMMAND_NAME and USER_ARGS
- `/home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md` (full file) - Error logging pattern documentation
- `/home/benjamin/.config/.claude/specs/860_claude_buildoutputmd_which_i_want_you_to_research/reports/001_build_errors_not_captured_analysis.md` (full file) - Build command error analysis report

### Supporting Analysis
- Grep results showing absence of `append_workflow_state.*COMMAND_NAME|USER_ARGS` in both /plan and /build
- Error logging standards from error-handling.md lines 96-152 (command integration requirements)
- State persistence pattern from plan.md lines 250-260 (showing other variables persisted but not error logging variables)
- Unbound variable errors from plan-output.md lines 29 and 199

### Error Types Referenced
- `validation_error` - Input validation failures (early validation in Block 1)
- `state_error` - Workflow state persistence/validation issues (Blocks 2 and 3)
- `file_error` - File I/O failures (state file not found)
- Exit code 127 - Bash unbound variable / command not found error

### Cross-Command Pattern
This analysis reveals a **systemic issue** affecting all multi-block workflow commands:
- `/plan` - Confirmed affected (primary analysis subject)
- `/build` - Confirmed affected (comparison analysis)
- `/debug` - Likely affected (needs verification)
- `/repair` - Likely affected (needs verification)
- `/research` - Likely affected (needs verification)
- `/revise` - Likely affected (needs verification)

All commands following the multi-block pattern must be audited and updated to persist/restore error logging variables.
