# Error Handling Pattern

**Path**: docs → concepts → patterns → error-handling.md

[Used by: all commands, all orchestrators, hierarchical agents, workflow state machine]

Centralized JSONL-based error logging with structured query interface, enabling post-mortem analysis, debugging workflows, and error trend identification across the entire .claude system.

## Definition

The Error Handling Pattern provides a centralized, structured logging system where commands and agents log errors to environment-specific JSONL files with full workflow context. The system automatically routes test errors to `.claude/tests/logs/test-errors.jsonl` and production errors to `.claude/data/logs/errors.jsonl`, enabling clean test isolation while maintaining a single source of truth for production error analysis.

The pattern separates:
- **Error Production**: Commands/agents log structured errors with environment detection
- **Error Consumption**: `/errors` command queries and analyzes log entries from both logs
- **Error Recovery**: Classification and retry logic based on error types
- **Test Isolation**: Automatic segregation prevents test pollution of production logs

## Rationale

### Why This Pattern Matters

Distributed error logging creates three critical problems:

1. **Context Loss**: When errors are logged to separate files per command, workflow context is fragmented. You can't see that a `/build` failure was preceded by 3 `/plan` agent timeout errors.

2. **Discovery Difficulty**: Finding relevant errors requires knowing which log file to check. Did the error happen in research phase? Planning? Implementation? Each requires checking different locations.

3. **Trend Blindness**: Without centralized aggregation, you can't identify patterns like "state_error occurs in 40% of /build runs" or "agent timeouts spike on Fridays".

Environment-based error logging solves these problems by:
- Capturing full workflow context (command, workflow ID, user args, phase, state, environment)
- Routing test errors to test directory, production errors to data directory
- Providing unified query interface with filters (command, type, time range, workflow ID, log file)
- Enabling trend analysis and summary statistics per environment
- Supporting post-mortem debugging with complete error history
- Preventing test pollution of production error logs

### Problems Solved

- **100% error capture rate** through mandatory `log_command_error()` integration in all commands
- **Automatic test isolation** routes errors from test scripts to separate log file
- **Sub-second query performance** with JSONL format and jq filtering
- **10MB rotation threshold** prevents unbounded log growth while maintaining history
- **Zero configuration** - environment detection works automatically based on script location

## Implementation

### Core Mechanism

**Error Classification Taxonomy**

All errors are classified into standardized types for consistent handling:

```bash
# Workflow-level error types
ERROR_TYPE_STATE="state_error"          # State file missing/corrupted
ERROR_TYPE_VALIDATION="validation_error" # Invalid user input
ERROR_TYPE_AGENT="agent_error"          # Subagent invocation failure
ERROR_TYPE_PARSE="parse_error"          # Output parsing failure
ERROR_TYPE_FILE="file_error"            # File I/O failure
ERROR_TYPE_TIMEOUT_ERR="timeout_error"  # Operation timeout
ERROR_TYPE_EXECUTION="execution_error"  # General execution failure

# Recovery classification (for retry logic)
ERROR_TYPE_TRANSIENT="transient"        # Retry recommended
ERROR_TYPE_PERMANENT="permanent"        # Code fix required
ERROR_TYPE_FATAL="fatal"                # User intervention required
```

**JSONL Schema**

Every error logged to environment-specific log files follows this schema:

```json
{
  "timestamp": "2025-10-19T15:30:45Z",
  "environment": "production",
  "command": "/build",
  "workflow_id": "build_20251019_153045",
  "user_args": "plan.md 3",
  "error_type": "state_error",
  "error_message": "State file not found at /path/to/state.sh",
  "source": "bash_block",
  "stack": ["lib/workflow-state-machine.sh:42", "commands/build.md:156"],
  "context": {
    "expected_path": "/path/to/state.sh",
    "phase": 3,
    "retry_count": 1
  },
  "status": "ERROR",
  "status_updated_at": null,
  "repair_plan_path": null
}
```

**Error Lifecycle Status**

Error entries include status tracking for repair workflow integration:

| Status | Description |
|--------|-------------|
| `ERROR` | New error, default status when logged |
| `FIX_PLANNED` | Set by `/repair` when plan created for this error |
| `RESOLVED` | Set when repair plan completes successfully |

The `/repair` command updates matching error entries with `FIX_PLANNED` status and links them to the generated repair plan via `repair_plan_path`.

The `environment` field is automatically set to `"test"` when errors are logged from scripts in `.claude/tests/`, and `"production"` for all other contexts.

**Test Environment Separation**

The error logging system automatically detects test vs production environments and routes errors to separate log files:

1. **Test Log**: `.claude/tests/logs/test-errors.jsonl` - Errors from test scripts
2. **Production Log**: `.claude/data/logs/errors.jsonl` - Errors from commands and agents

**Environment Detection Methods**:

1. **Explicit Test Mode** (Recommended for test suites):
   ```bash
   # Set in test script initialization
   export CLAUDE_TEST_MODE=1
   ```
   This ensures all errors generated by the test script and its subprocesses are routed to the test log, regardless of script location.

2. **Automatic Path Detection** (Fallback):
   ```bash
   # Automatic detection based on script path
   if [[ "${BASH_SOURCE[2]:-}" =~ /tests/ ]] || [[ "$0" =~ /tests/ ]]; then
     environment="test"
   fi
   ```
   Works for scripts located in `.claude/tests/` directory.

**When to Use CLAUDE_TEST_MODE**:
- Integration test suites that create temporary test scripts (e.g., `/tmp/test_*.sh`)
- Test scripts that invoke production commands
- Any test that needs guaranteed log isolation

**Benefits**:
- **Clean Test Isolation**: Test errors never pollute production logs
- **Separate Analysis**: Query test and production errors independently
- **Easy Cleanup**: Clear test logs without affecting production history
- **Environment Tracking**: Every log entry tagged with environment for auditing

**Dual Trap Setup Pattern**

Commands use a **dual trap setup pattern** to ensure continuous error coverage from initialization through execution:

1. **Early Trap**: Set immediately after sourcing error-handling.sh with placeholder values
2. **Late Trap**: Update trap with actual workflow context once WORKFLOW_ID is available

This pattern eliminates coverage gaps during initialization and ensures all errors are logged.

```bash
#!/usr/bin/env bash
# Source error handling library
source "${CLAUDE_CONFIG}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# EARLY TRAP: Capture errors during initialization before WORKFLOW_ID is available
setup_bash_error_trap "/build" "build_early_$(date +%s)" "early_init"

# Flush any errors that occurred before error-handling.sh was sourced
_flush_early_errors

# Validate trap is active - fail fast if error logging is broken
if ! trap -p ERR | grep -q "_log_bash_error"; then
  echo "ERROR: ERR trap not active - error logging will fail" >&2
  exit 1
fi

# ... initialization code with full error coverage ...

# Ensure error log exists
ensure_error_log_exists

# Generate actual workflow context
COMMAND_NAME="/build"
WORKFLOW_ID="build_$(date +%Y%m%d_%H%M%S)"
USER_ARGS="$*"

# LATE TRAP: Update trap with actual workflow context
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
```

**Why Dual Trap Setup?**

Without dual trap setup, errors during initialization (between sourcing error-handling.sh and setting the trap) are not captured. This creates coverage gaps of 50-80 lines where critical errors like:
- Library sourcing failures
- Path validation errors
- Argument parsing issues
- State file initialization problems

...go unlogged and are lost when the script exits.

The dual trap pattern solves this by:
1. Establishing error capture immediately after error-handling.sh is available
2. Using placeholder values (e.g., `"command_early_$(date +%s)"`) for early trap context
3. Flushing pre-trap buffered errors with `_flush_early_errors`
4. Validating trap is active before continuing (fail-fast on broken setup)
5. Updating trap with actual workflow context once WORKFLOW_ID is generated

**Pattern Compliance**:
- `/build`, `/plan`, `/repair`, `/todo` - Full dual trap implementation
- All new commands MUST implement dual trap setup for 100% coverage

**Logging Integration in Commands**

Every command must integrate error logging in three places:

1. **Initialization**: Source error-handling.sh and ensure log exists
2. **Error Points**: Log errors with full context when operations fail
3. **Subagent Errors**: Parse TASK_ERROR signals and log to centralized log

```bash
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

# Example: Log agent error with retry context
output=$(invoke_agent "plan-architect" "Create plan") || {
  error_json=$(parse_subagent_error "$output")

  if [ "$(echo "$error_json" | jq -r '.found')" = "true" ]; then
    error_type=$(echo "$error_json" | jq -r '.error_type')
    message=$(echo "$error_json" | jq -r '.message')
    context=$(echo "$error_json" | jq -c '.context')

    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "$error_type" \
      "$message" \
      "subagent_plan-architect" \
      "$context"
  fi

  exit 1
}
```

**Query Interface via /errors Command**

Users query errors through the `/errors` command with support for both production and test logs:

```bash
# Query recent /build errors (production log, default)
/errors --command /build --limit 10

# Query test errors
/errors --log-file .claude/tests/logs/test-errors.jsonl --limit 10

# Query state errors in last hour
/errors --type state_error --since "2025-10-19T14:00:00Z"

# Query specific workflow
/errors --workflow-id "build_20251019_153045"

# Show error summary statistics (production)
/errors --summary

# Show test log summary
/errors --log-file .claude/tests/logs/test-errors.jsonl --summary
```

**State Persistence Integration for Error Context**

To maintain error context across bash blocks (subprocess isolation), commands must persist error logging variables in Block 1 and restore them in subsequent blocks:

```bash
# === BLOCK 1: Initialize and Persist ===
# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null

# Ensure error log exists
ensure_error_log_exists

# Set command metadata for error logging
COMMAND_NAME="/command-name"
USER_ARGS="$FEATURE_DESCRIPTION"  # or relevant user input
export COMMAND_NAME USER_ARGS

# Initialize workflow state
WORKFLOW_ID="command_$(date +%s)"
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
export STATE_FILE WORKFLOW_ID

# Persist for subsequent blocks (automatic via init_workflow_state)
# These variables are automatically available after load_workflow_state in later blocks

# === BLOCKS 2+: Restore and Use ===
# Re-source libraries for subprocess isolation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null

# Load workflow state (automatically restores COMMAND_NAME, USER_ARGS, WORKFLOW_ID)
load_workflow_state "$WORKFLOW_ID" false

# Variables are now available for error logging
if [ ! -f "$PLAN_FILE" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "Plan file not found" \
    "bash_block_2" \
    "$(jq -n --arg path "$PLAN_FILE" '{expected_path: $path}')"

  exit 1
fi
```

**Key Requirements for Error Context Persistence:**

1. **Block 1**: Export COMMAND_NAME and USER_ARGS immediately after `ensure_error_log_exists`
2. **Block 1**: Initialize WORKFLOW_ID and STATE_FILE before any error logging calls
3. **Blocks 2+**: Load workflow state BEFORE any error logging calls
4. **All Blocks**: Variables (COMMAND_NAME, USER_ARGS, WORKFLOW_ID) are automatically restored by `load_workflow_state`

This pattern ensures all error logs have complete context regardless of which bash block encounters the error, enabling accurate post-mortem analysis and debugging.

**Error Analysis via /repair Command**

The `/repair` command provides systematic error pattern analysis and fix plan generation:

```bash
# Analyze recent errors and create fix plan
/repair --since 1h --complexity 2

# Analyze specific error type patterns
/repair --type state_error

# Analyze command-specific failures
/repair --command /build --complexity 3
```

The `/repair` workflow:
1. Queries errors matching specified filters (same filters as `/errors`)
2. Groups errors by pattern and root cause
3. Creates error analysis report in `specs/{NNN_topic}/reports/`
4. Generates implementation plan with fix phases in `specs/{NNN_topic}/plans/`
5. Returns plan path for execution via `/build`

See [Repair Command Guide](../../guides/commands/repair-command-guide.md) for complete workflow details.

**Automatic Log Rotation**

Prevents unbounded log growth through size-based rotation for both production and test logs:

```bash
# Rotation policy (applies to both logs)
MAX_SIZE_BYTES=10485760  # 10MB
MAX_BACKUPS=5            # Keep .1 through .5

# Production log rotation structure (.claude/data/logs/)
errors.jsonl       # Current production log
errors.jsonl.1     # First backup (most recent)
errors.jsonl.2     # Second backup
errors.jsonl.3     # Third backup
errors.jsonl.4     # Fourth backup
errors.jsonl.5     # Fifth backup (oldest, deleted on next rotation)

# Test log rotation structure (.claude/tests/logs/)
test-errors.jsonl       # Current test log
test-errors.jsonl.1     # First backup (most recent)
test-errors.jsonl.2-5   # Additional backups

# Automatic rotation on every write
# Called by log_command_error() before appending to selected log file
```

### Integration with State Machine

The workflow state machine integrates error logging for retry tracking:

```bash
# handle_state_error() from error-handling.sh
handle_state_error() {
  local error_message="$1"
  local current_state="${CURRENT_STATE:-unknown}"
  local exit_code="${2:-1}"

  # Save failed state to workflow state
  append_workflow_state "FAILED_STATE" "$current_state"
  append_workflow_state "LAST_ERROR" "$error_message"

  # Increment retry counter for this state
  RETRY_COUNT_VAR="RETRY_COUNT_${current_state}"
  RETRY_COUNT=$(eval echo "\${${RETRY_COUNT_VAR}:-0}")
  RETRY_COUNT=$((RETRY_COUNT + 1))
  append_workflow_state "$RETRY_COUNT_VAR" "$RETRY_COUNT"

  # Log to centralized error log
  log_command_error \
    "${COMMAND_NAME:-/unknown}" \
    "${WORKFLOW_ID:-unknown}" \
    "${USER_ARGS:-}" \
    "$ERROR_TYPE_STATE" \
    "$error_message" \
    "state_machine" \
    "$(jq -n --arg state "$current_state" --argjson retry "$RETRY_COUNT" '{state: $state, retry: $retry}')"

  # Check retry limit
  if [ $RETRY_COUNT -ge 2 ]; then
    echo "Max retries (2) reached for state '$current_state'"
    echo "Review error log: /errors --workflow-id ${WORKFLOW_ID}"
    exit $exit_code
  fi
}
```

### Integration with Hierarchical Agents

Agents return `TASK_ERROR` signals that parent commands parse and log:

**Agent Error Return Format**:
```markdown
ERROR_CONTEXT: {
  "error_type": "validation_error",
  "message": "Schema mismatch in user_id field",
  "details": {
    "field": "user_id",
    "expected": "string",
    "actual": "integer"
  }
}

TASK_ERROR: validation_error - Schema mismatch in user_id field
```

**Parent Command Processing**:
```bash
# Invoke agent and capture output
output=$(invoke_agent "research-specialist" "Research auth patterns")

# Parse error signal
error_json=$(parse_subagent_error "$output")

if [ "$(echo "$error_json" | jq -r '.found')" = "true" ]; then
  error_type=$(echo "$error_json" | jq -r '.error_type')
  message=$(echo "$error_json" | jq -r '.message')
  context=$(echo "$error_json" | jq -c '.context')

  # Log with subagent attribution
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "$error_type" \
    "Agent research-specialist failed: $message" \
    "subagent_research-specialist" \
    "$context"

  # Determine recovery based on error type
  if [ "$error_type" = "timeout_error" ]; then
    # Retry with increased timeout
    retry_metadata=$(retry_with_timeout "research-specialist" 1)
    new_timeout=$(echo "$retry_metadata" | jq -r '.new_timeout')
    # ... retry logic
  else
    # Permanent error - escalate to user
    exit 1
  fi
fi
```

### Recovery Patterns

**Transient Error Recovery (Automatic Retry)**:
```bash
# Classify error and determine recovery
error_type=$(classify_error "$error_message")

if [ "$error_type" = "transient" ]; then
  # Retry with exponential backoff
  if retry_with_backoff 3 500 perform_operation; then
    echo "Operation succeeded after retry"
  else
    # Log failure after all retries
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "$ERROR_TYPE_EXECUTION" \
      "Operation failed after 3 retries: $error_message" \
      "retry_exhausted" \
      "$(jq -n --argjson attempts 3 '{max_attempts: $attempts}')"
    exit 1
  fi
fi
```

**Permanent Error Recovery (User Fix Required)**:
```bash
if [ "$error_type" = "permanent" ]; then
  # Log error
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "$ERROR_TYPE_EXECUTION" \
    "$error_message" \
    "bash_block" \
    '{}'

  # Provide recovery suggestions
  suggest_recovery "$error_type" "$error_message"

  # Exit with error - user must fix code
  exit 1
fi
```

**Fatal Error Recovery (System Intervention)**:
```bash
if [ "$error_type" = "fatal" ]; then
  # Log error
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "$ERROR_TYPE_EXECUTION" \
    "$error_message" \
    "bash_block" \
    '{}'

  # Provide system-level recovery suggestions
  echo "Fatal error - system intervention required:"
  suggest_recovery "$error_type" "$error_message"

  # Exit immediately - cannot proceed
  exit 1
fi
```

### ERR Trap Suppression for Validation Failures

**Purpose**: Prevent cascading execution_error log entries for expected validation failures that are already logged with specific error types (state_error, validation_error).

**Problem**: Library functions that perform validation (e.g., append_workflow_state, sm_transition) log errors with descriptive types and then return 1. The ERR trap catches this return and logs an additional execution_error entry, creating duplicate log entries for the same underlying issue.

**Solution**: Set `SUPPRESS_ERR_TRAP=1` flag before returning from validation functions to prevent the ERR trap from logging.

**Implementation Pattern**:
```bash
# In library validation functions (e.g., state-persistence.sh)
some_validation_function() {
  # ... validation logic ...

  if validation_fails; then
    echo "ERROR: Validation failed" >&2

    # Suppress ERR trap for this expected validation failure
    # Prevents cascading execution_error log entry
    SUPPRESS_ERR_TRAP=1

    # Log specific error type
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "validation_error" \
      "Descriptive error message" \
      "function_name" \
      "$(jq -n '{context: "details"}')"

    return 1  # ERR trap will see flag and skip logging
  fi
}
```

**ERR Trap Handler** (in error-handling.sh):
```bash
_log_bash_error() {
  local exit_code=$1
  local line_no=$2
  local failed_command=$3
  # ... other args ...

  # Check suppression flag
  if [[ "${SUPPRESS_ERR_TRAP:-0}" == "1" ]]; then
    SUPPRESS_ERR_TRAP=0  # Auto-reset flag
    return 0  # Skip logging and exit
  fi

  # Normal ERR trap logging continues...
  log_command_error "$error_type" "Bash error at line $line_no" ...
  exit $exit_code
}
```

**When to Use**:
- ✅ **Use** for validation failures in library functions (type checks, state checks, etc.)
- ✅ **Use** when error is already logged with specific error type (state_error, validation_error)
- ❌ **Don't use** for unexpected errors (file I/O failures, permission errors, etc.)
- ❌ **Don't use** outside library functions (commands should let ERR trap handle errors)

**Best Practices**:
1. Set flag immediately before `return 1` to minimize scope
2. Always log specific error type before setting flag
3. Flag auto-resets in trap handler to prevent suppressing subsequent errors
4. Document why suppression is needed (comment explaining expected validation failure)

**Impact**: Reduces error log noise by 20-30% by eliminating duplicate entries for validation failures.

---

### Helper Functions (Spec 945)

The error-handling library provides specialized helper functions for common error scenarios:

**log_early_error()**

Logs errors before error logging infrastructure is fully initialized (e.g., before COMMAND_NAME, WORKFLOW_ID, USER_ARGS available):

```bash
# Early initialization error (before workflow metadata)
log_early_error "Failed to source required library" \
  '{"library": "state-persistence.sh", "path": "/path/to/lib"}'

# Returns 0 (silent failure) to avoid breaking initialization
# Automatically creates error log directory if missing
# Uses placeholder workflow_id: "unknown_<timestamp>"
```

**validate_state_restoration()**

Validates required variables restored from state file after `load_workflow_state`:

```bash
# Load state from previous bash block
load_workflow_state "$WORKFLOW_ID" false

# Validate critical variables restored
validate_state_restoration "COMMAND_NAME" "USER_ARGS" "STATE_FILE" "PLAN_PATH" || {
  echo "ERROR: State restoration failed" >&2
  exit 1
}

# Now safe to use variables - guaranteed to be set
echo "Processing: $PLAN_PATH"
```

Function behavior:
- Temporarily disables `set -u` for safe variable checking
- Logs `state_error` with missing variable list if any variables unset
- Returns 0 if all variables set, 1 if any missing
- Includes JSON context with comma-separated list of missing variables

**check_unbound_vars()**

Checks if variables are set before use (defensive pattern for optional variables):

```bash
# Check optional variable without logging error
check_unbound_vars "OPTIONAL_FILE" || OPTIONAL_FILE=""

# Check multiple optional variables
check_unbound_vars "DEBUG_MODE" "VERBOSE" || {
  DEBUG_MODE=false
  VERBOSE=false
}

# Returns 0 if all variables set, 1 if any missing (does NOT log error)
```

## Usage Examples

### Example 1: /build Command Error Logging

```bash
# /build command implementation
COMMAND_NAME="/build"
WORKFLOW_ID="build_$(date +%Y%m%d_%H%M%S)"
USER_ARGS="$*"

# Source error handling
source "${CLAUDE_CONFIG}/.claude/lib/core/error-handling.sh" 2>/dev/null
ensure_error_log_exists

# Validate plan file exists
if [ ! -f "$PLAN_FILE" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "$ERROR_TYPE_FILE" \
    "Plan file not found: $PLAN_FILE" \
    "bash_block" \
    "$(jq -n --arg path "$PLAN_FILE" '{plan_path: $path}')"

  echo "Error: Plan file not found"
  echo "Use: /build <plan-file>"
  exit 1
fi

# Invoke implementer-coordinator agent
output=$(invoke_agent "implementer-coordinator" "Execute plan")

# Check for agent errors
error_json=$(parse_subagent_error "$output")
if [ "$(echo "$error_json" | jq -r '.found')" = "true" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "$(echo "$error_json" | jq -r '.error_type')" \
    "$(echo "$error_json" | jq -r '.message')" \
    "subagent_implementer-coordinator" \
    "$(echo "$error_json" | jq -c '.context')"

  echo "Implementation failed - check /errors for details"
  exit 1
fi
```

### Example 2: Querying Errors for Debugging

```bash
# User workflow
$ /build plan.md
Error: State file not found

# Query recent errors to diagnose
$ /errors --command /build --limit 5

[2025-10-19T15:30:45Z] /build
  Type: state_error
  Message: State file not found at /path/to/state.sh
  Args: plan.md 3
  Workflow: build_20251019_153045

# Check if this is a pattern
$ /errors --type state_error --summary

Error Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total Errors: 42

By Command:
  /build               15
  /plan                12

By Type:
  state_error          18  ← Recurring issue
  agent_error          12
  validation_error     8
```

### Example 3: Agent Retry with Error Logging

```bash
# Invoke agent with retry logic
attempt=0
max_attempts=3

while [ $attempt -lt $max_attempts ]; do
  output=$(invoke_agent "plan-architect" "Create plan")

  # Check for errors
  error_json=$(parse_subagent_error "$output")

  if [ "$(echo "$error_json" | jq -r '.found')" = "false" ]; then
    # Success
    echo "Plan created successfully"
    break
  fi

  # Log error
  error_type=$(echo "$error_json" | jq -r '.error_type')
  message=$(echo "$error_json" | jq -r '.message')

  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "$error_type" \
    "Attempt $((attempt + 1))/$max_attempts failed: $message" \
    "subagent_plan-architect" \
    "$(jq -n --argjson attempt $attempt '{attempt: $attempt}')"

  # Retry with increased timeout
  if [ "$error_type" = "timeout_error" ]; then
    retry_metadata=$(retry_with_timeout "plan-architect" $attempt)
    new_timeout=$(echo "$retry_metadata" | jq -r '.new_timeout')
    # Update timeout for next attempt
    AGENT_TIMEOUT=$new_timeout
  fi

  attempt=$((attempt + 1))
done

if [ $attempt -eq $max_attempts ]; then
  echo "Failed after $max_attempts attempts"
  echo "Check errors: /errors --workflow-id $WORKFLOW_ID"
  exit 1
fi
```

## Anti-Patterns

### Anti-Pattern 1: Per-Command Log Files

**Problem**: Each command writes to its own log file

```bash
# DON'T: Create separate log files per command
ERROR_LOG="/tmp/build_errors.log"
echo "$error_message" >> "$ERROR_LOG"
```

**Why**: Fragments error context, prevents cross-command analysis, requires knowing which file to check.

**Solution**: Use centralized `log_command_error()`

```bash
# DO: Use centralized error logging
log_command_error \
  "$COMMAND_NAME" \
  "$WORKFLOW_ID" \
  "$USER_ARGS" \
  "$ERROR_TYPE_EXECUTION" \
  "$error_message" \
  "bash_block" \
  '{}'
```

### Anti-Pattern 2: Unstructured Error Messages

**Problem**: Free-form error strings without context

```bash
# DON'T: Log unstructured errors
echo "Error: something went wrong" >&2
```

**Why**: Cannot filter, aggregate, or analyze errors programmatically.

**Solution**: Use structured JSONL with error type and context

```bash
# DO: Use structured error logging
log_command_error \
  "$COMMAND_NAME" \
  "$WORKFLOW_ID" \
  "$USER_ARGS" \
  "$ERROR_TYPE_VALIDATION" \
  "Plan file path required" \
  "bash_block" \
  "$(jq -n --arg provided "$*" '{provided_args: $provided}')"
```

### Anti-Pattern 3: Ignoring Subagent Errors

**Problem**: Don't parse or log subagent `TASK_ERROR` signals

```bash
# DON'T: Ignore agent errors
output=$(invoke_agent "research-specialist" "Research topic")
# Just check exit code, don't log structured error
if [ $? -ne 0 ]; then
  echo "Agent failed"
  exit 1
fi
```

**Why**: Loses error context, can't diagnose which agent failed or why.

**Solution**: Parse `TASK_ERROR` and log with subagent attribution

```bash
# DO: Parse and log subagent errors
output=$(invoke_agent "research-specialist" "Research topic")

error_json=$(parse_subagent_error "$output")
if [ "$(echo "$error_json" | jq -r '.found')" = "true" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "$(echo "$error_json" | jq -r '.error_type')" \
    "$(echo "$error_json" | jq -r '.message')" \
    "subagent_research-specialist" \
    "$(echo "$error_json" | jq -c '.context')"
  exit 1
fi
```

### Anti-Pattern 4: Logging Sensitive Data

**Problem**: Log user credentials, API keys, or PII

```bash
# DON'T: Log sensitive data
log_command_error \
  "$COMMAND_NAME" \
  "$WORKFLOW_ID" \
  "$USER_ARGS" \
  "$ERROR_TYPE_EXECUTION" \
  "API call failed with key: sk-abc123xyz" \  # SENSITIVE!
  "bash_block" \
  "$(jq -n --arg password "$USER_PASSWORD" '{password: $password}')"  # NO!
```

**Why**: Exposes secrets in plaintext log files.

**Solution**: Sanitize context before logging

```bash
# DO: Sanitize sensitive data
sanitized_context=$(jq -n \
  --arg api_key "sk-***" \
  --arg user "user@example.com" \
  '{api_key: $api_key, user: $user}')

log_command_error \
  "$COMMAND_NAME" \
  "$WORKFLOW_ID" \
  "$USER_ARGS" \
  "$ERROR_TYPE_EXECUTION" \
  "API call failed - check credentials" \
  "bash_block" \
  "$sanitized_context"
```

## Performance Characteristics

| Operation | Time | Notes |
|-----------|------|-------|
| `log_command_error()` | <10ms | Atomic append with rotation check |
| `query_errors()` (50 results) | <100ms | Linear scan with jq filtering |
| `recent_errors()` (10 results) | <50ms | tail + jq (no full file scan) |
| `error_summary()` | <200ms | Full file scan with aggregation |
| `parse_subagent_error()` | <1ms | Regex pattern matching only |

**Log File Size**: ~1KB per error entry, ~1MB for 1000 errors

**Rotation**: 10MB threshold = ~10,000 errors before rotation

## See Also

- [Error Handling API Reference](../../reference/library-api/error-handling.md) - Function signatures and usage
- [/errors Command Guide](../../guides/commands/errors-command-guide.md) - User guide for querying errors
- [/repair Command Guide](../../guides/commands/repair-command-guide.md) - User guide for error analysis and fix plans
- [Workflow State Machine](../../architecture/workflow-state-machine.md) - State machine error integration
- [Hierarchical Agents](../hierarchical-agents.md) - Agent error signaling protocol
- [Behavioral Injection](behavioral-injection.md) - Context injection patterns
