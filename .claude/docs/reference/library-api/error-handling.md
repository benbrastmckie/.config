# Library API Reference - Error Handling

Centralized error logging, classification, and recovery utilities.

## Navigation

This document is part of the library API reference:
- [Overview](overview.md) - Purpose, quick index, core utilities
- [State Machine](state-machine.md) - Workflow classification and scope detection
- [Persistence](persistence.md) - State persistence and checkpoint utilities
- [Utilities](utilities.md) - Agent support, workflow support, analysis
- **Error Handling** (this file) - Error logging, classification, and recovery

---

## Purpose

The `error-handling.sh` library provides a centralized JSONL-based error logging system with structured query interface, error classification, retry logic, and recovery patterns. It enables commands to log errors with full workflow context for later analysis via the `/errors` command.

**Key Features**:
- Centralized JSONL error log with automatic rotation
- Structured error logging with workflow context
- Error classification and recovery suggestions
- Query interface with filters (command, type, workflow ID, time range)
- Integration with state machine for retry tracking
- Subagent error parsing for hierarchical workflows

**Commands using this library**: `/build`, `/plan`, `/research`, `/debug`, `/revise`, all orchestrators

---

## Error Logging

### log_command_error()

Log command error to environment-specific JSONL error log with automatic test/production routing.

**Usage**:
```bash
log_command_error <command> <workflow_id> <user_args> <error_type> <message> <source> [context_json]
```

**Arguments**:
- `command` (string): Command name (e.g., `/build`, `/plan`)
- `workflow_id` (string): Unique workflow identifier
- `user_args` (string): User-provided command arguments
- `error_type` (string): Error type constant (see Error Type Constants)
- `message` (string): Human-readable error description
- `source` (string): Error source (e.g., `bash_block`, `agent`, `validation`)
- `context_json` (optional, string): Additional context as JSON object (default: `{}`)

**Returns**: Nothing (appends to environment-specific log file)

**Exit Codes**:
- `0`: Success
- `1`: Failure (log directory creation failed)

**Environment Detection**:
The function automatically detects the execution environment and routes errors accordingly:
- **Test environment**: Errors from scripts in `.claude/tests/` directory → `.claude/tests/logs/test-errors.jsonl`
- **Production environment**: All other errors → `.claude/data/logs/errors.jsonl`

**Usage Example**:
```bash
# Production error (logged to .claude/data/logs/errors.jsonl)
log_command_error \
  "/build" \
  "build_20251019_153045" \
  "plan.md 3" \
  "$ERROR_TYPE_STATE" \
  "State file not found at /path/to/state.sh" \
  "bash_block" \
  '{"expected_path": "/path/to/state.sh", "phase": 3}'

# Test error (logged to .claude/tests/logs/test-errors.jsonl when called from test script)
log_command_error \
  "/test" \
  "test_123" \
  "test_suite" \
  "$ERROR_TYPE_VALIDATION" \
  "Test validation failed" \
  "test_script" \
  '{"test_name": "test_error_logging"}'
```

**JSONL Schema**:
```json
{
  "timestamp": "2025-10-19T15:30:45Z",
  "environment": "production",
  "command": "/build",
  "workflow_id": "build_20251019_153045",
  "user_args": "plan.md 3",
  "error_type": "state_error",
  "error_message": "State file not found",
  "source": "bash_block",
  "stack": ["line1", "line2"],
  "context": {"expected_path": "/path", "phase": 3}
}
```

The `environment` field is set to `"test"` or `"production"` based on automatic detection.

---

### parse_subagent_error()

Parse `TASK_ERROR` signal from subagent output.

**Usage**:
```bash
error_json=$(parse_subagent_error "$output")
```

**Arguments**:
- `output` (string): Full subagent output text

**Returns**: JSON with error_type, message, context, and found flag

**Exit Codes**: `0` (always succeeds)

**Signal Format**:
```
ERROR_CONTEXT: {
  "error_type": "validation_error",
  "message": "Schema mismatch",
  "details": {"field": "user_id"}
}

TASK_ERROR: validation_error - Schema mismatch in user_id field
```

**Usage Example**:
```bash
# Invoke subagent and check for errors
output=$(invoke_agent "plan-architect" "Create plan")

# Parse error signal
error_json=$(parse_subagent_error "$output")

if [ "$(echo "$error_json" | jq -r '.found')" = "true" ]; then
  error_type=$(echo "$error_json" | jq -r '.error_type')
  message=$(echo "$error_json" | jq -r '.message')

  # Log to centralized error log
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "$error_type" \
    "$message" \
    "subagent" \
    "$(echo "$error_json" | jq -c '.context')"
fi
```

---

### rotate_error_log()

Rotate error log file if it exceeds size threshold.

**Usage**:
```bash
rotate_error_log
```

**Arguments**: None

**Returns**: Nothing

**Exit Codes**: `0` (always succeeds)

**Rotation Policy**:
- **Threshold**: 10MB file size
- **Retention**: 5 backup files (`errors.jsonl.1` through `errors.jsonl.5`)
- **Automatic**: Called by `log_command_error()` before each write

---

### ensure_error_log_exists()

Ensure error log directory and file exist.

**Usage**:
```bash
ensure_error_log_exists
```

**Arguments**: None

**Returns**: Nothing

**Exit Codes**: `0` (always succeeds)

---

## Error Querying

### query_errors()

Query errors from JSONL log with filters (supports both production and test logs).

**Usage**:
```bash
query_errors [--command CMD] [--since TIME] [--type TYPE] [--limit N] [--workflow-id ID] [--log-file PATH]
```

**Arguments**:
- `--command <cmd>` (optional): Filter by command name
- `--since <time>` (optional): Filter by timestamp (ISO 8601)
- `--type <type>` (optional): Filter by error type
- `--limit <N>` (optional): Limit results (default: 50)
- `--workflow-id <id>` (optional): Filter by workflow ID
- `--log-file <path>` (optional): Log file path (default: production log)

**Returns**: Filtered JSONL entries on stdout

**Exit Codes**: `0` (always succeeds)

**Usage Example**:
```bash
# Query recent /build errors (production log, default)
query_errors --command /build --limit 10

# Query test log errors
query_errors --log-file .claude/tests/logs/test-errors.jsonl --limit 10

# Query state errors in last hour
query_errors --type state_error --since "2025-10-19T14:00:00Z"

# Query specific workflow
query_errors --workflow-id "build_20251019_153045"
```

---

### recent_errors()

Display recent errors in human-readable format.

**Usage**:
```bash
recent_errors [count]
```

**Arguments**:
- `count` (optional, integer): Number of errors to display (default: 10)

**Returns**: Formatted error list on stdout

**Exit Codes**: `0` (always succeeds)

**Output Format**:
```
Recent Errors (last 10):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[2025-10-19T15:30:45Z] /build
  Type: state_error
  Message: State file not found
  Args: plan.md 3
  Workflow: build_20251019_153045

[2025-10-19T15:28:12Z] /plan
  Type: agent_error
  Message: plan-architect timeout
  Args: add user auth
  Workflow: plan_20251019_154000

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### error_summary()

Display error summary with counts by command and type.

**Usage**:
```bash
error_summary
```

**Arguments**: None

**Returns**: Formatted summary on stdout

**Exit Codes**: `0` (always succeeds)

**Output Format**:
```
Error Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total Errors: 42

By Command:
  /build               15
  /plan                12
  /research            8
  /debug               7

By Type:
  state_error          18
  agent_error          12
  validation_error     8
  parse_error          4

Time Range:
  First: 2025-10-15T10:00:00Z
  Last:  2025-10-19T15:30:45Z
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Error Classification

### classify_error()

Classify error based on error message.

**Usage**:
```bash
error_type=$(classify_error "$error_message")
```

**Arguments**:
- `error_message` (string): Error message text

**Returns**: Error type (transient, permanent, fatal)

**Exit Codes**: `0` (always succeeds)

**Classification Rules**:
- **Transient**: Keywords like `locked`, `busy`, `timeout`, `temporary`, `unavailable`
- **Fatal**: Keywords like `out of space`, `disk full`, `permission denied`, `corrupted`
- **Permanent**: Default (code-level issues requiring fixes)

**Usage Example**:
```bash
error_msg="Database connection timeout"
error_type=$(classify_error "$error_msg")
# Returns: "transient"
```

---

### suggest_recovery()

Suggest recovery action based on error type and message.

**Usage**:
```bash
suggest_recovery "$error_type" "$error_message"
```

**Arguments**:
- `error_type` (string): Error type (transient, permanent, fatal)
- `error_message` (string): Error message text

**Returns**: Recovery suggestion text on stdout

**Exit Codes**: `0` (always succeeds)

**Usage Example**:
```bash
error_type="transient"
error_msg="Database connection timeout"
suggest_recovery "$error_type" "$error_msg"
# Output:
# Retry with exponential backoff (2-3 attempts)
# Check system resources and try again
```

---

### detect_error_type()

Detect specific error type from error message.

**Usage**:
```bash
specific_type=$(detect_error_type "$error_message")
```

**Arguments**:
- `error_message` (string): Error message text

**Returns**: Specific error type (syntax, test_failure, file_not_found, import_error, null_error, timeout, permission, unknown)

**Exit Codes**: `0` (always succeeds)

---

### extract_location()

Extract file location from error message.

**Usage**:
```bash
location=$(extract_location "$error_message")
```

**Arguments**:
- `error_message` (string): Error message text

**Returns**: File location in format `file:line` (or empty if not found)

**Exit Codes**: `0` (always succeeds)

**Usage Example**:
```bash
error_msg="Error in test.lua:42: syntax error"
location=$(extract_location "$error_msg")
# Returns: "test.lua:42"
```

---

### generate_suggestions()

Generate error-specific suggestions.

**Usage**:
```bash
generate_suggestions "$error_type" "$error_output" "$location"
```

**Arguments**:
- `error_type` (string): Specific error type (from detect_error_type)
- `error_output` (string): Full error output
- `location` (string): File location (from extract_location)

**Returns**: Formatted suggestions on stdout

**Exit Codes**: `0` (always succeeds)

---

## Retry Logic

### retry_with_backoff()

Retry command with exponential backoff.

**Usage**:
```bash
retry_with_backoff <max_attempts> <base_delay_ms> <command> [args...]
```

**Arguments**:
- `max_attempts` (integer): Maximum retry attempts
- `base_delay_ms` (integer): Base delay in milliseconds
- `command` (string): Command to retry
- `args` (optional, strings): Command arguments

**Returns**: Nothing (command output suppressed)

**Exit Codes**:
- `0`: Command succeeded
- `1`: All retries exhausted

**Usage Example**:
```bash
# Retry curl with 3 attempts, starting at 500ms delay
if retry_with_backoff 3 500 curl "https://api.example.com/data"; then
  echo "API call succeeded"
else
  echo "API call failed after 3 attempts"
fi
```

**Backoff Schedule**:
- Attempt 1: 0ms (immediate)
- Attempt 2: 500ms delay
- Attempt 3: 1000ms delay
- Attempt 4: 2000ms delay (if max_attempts >= 4)

---

### retry_with_timeout()

Generate retry metadata with extended timeout.

**Usage**:
```bash
retry_metadata=$(retry_with_timeout "$operation_name" "$attempt_number")
```

**Arguments**:
- `operation_name` (string): Operation being retried
- `attempt_number` (integer): Current attempt number (0-indexed)

**Returns**: JSON with retry metadata

**Exit Codes**:
- `0`: Success
- `1`: Missing operation_name

**Metadata Fields**:
- `operation` (string): Operation name
- `attempt` (integer): Current attempt
- `new_timeout` (integer): Timeout in milliseconds (1.5x increase per attempt)
- `should_retry` (boolean): Whether to retry (false after 3 attempts)
- `max_attempts` (integer): Maximum attempts (3)

**Usage Example**:
```bash
attempt=0
metadata=$(retry_with_timeout "Agent invocation" $attempt)
new_timeout=$(echo "$metadata" | jq -r '.new_timeout')
should_retry=$(echo "$metadata" | jq -r '.should_retry')

# Use new timeout for next attempt
if [ "$should_retry" = "true" ]; then
  invoke_agent "plan-architect" --timeout "$new_timeout"
fi
```

---

### retry_with_fallback()

Generate fallback retry metadata with reduced toolset.

**Usage**:
```bash
fallback_metadata=$(retry_with_fallback "$operation_name" "$attempt_number")
```

**Arguments**:
- `operation_name` (string): Operation being retried
- `attempt_number` (integer): Current attempt number

**Returns**: JSON with reduced toolset recommendation

**Exit Codes**:
- `0`: Success
- `1`: Missing operation_name

**Metadata Fields**:
- `operation` (string): Operation name
- `attempt` (integer): Current attempt
- `full_toolset` (string): Full tool list (`Read,Write,Edit,Bash`)
- `reduced_toolset` (string): Reduced tool list (`Read,Write`)
- `strategy` (string): Always `fallback`
- `recommendation` (string): Human-readable recommendation

---

## Error Type Constants

### Standard Error Types

```bash
# For centralized error logging
ERROR_TYPE_STATE="state_error"          # Workflow state persistence issues
ERROR_TYPE_VALIDATION="validation_error" # Input validation failures
ERROR_TYPE_AGENT="agent_error"          # Subagent execution failures
ERROR_TYPE_PARSE="parse_error"          # Output parsing failures
ERROR_TYPE_FILE="file_error"            # File system operations failures
ERROR_TYPE_TIMEOUT_ERR="timeout_error"  # Operation timeout errors
ERROR_TYPE_EXECUTION="execution_error"  # General execution failures
```

### Legacy Error Types (for classify_error)

```bash
ERROR_TYPE_TRANSIENT="transient"        # Temporary issues (retry)
ERROR_TYPE_PERMANENT="permanent"        # Code-level issues (fix required)
ERROR_TYPE_FATAL="fatal"                # System-level issues (user intervention)
```

### LLM-Specific Error Types

```bash
ERROR_TYPE_LLM_TIMEOUT="llm_timeout"            # LLM request timeout
ERROR_TYPE_LLM_API_ERROR="llm_api_error"        # LLM API failure
ERROR_TYPE_LLM_LOW_CONFIDENCE="llm_low_confidence" # Low confidence response
ERROR_TYPE_LLM_PARSE_ERROR="llm_parse_error"    # LLM output parsing failure
ERROR_TYPE_INVALID_MODE="invalid_mode"          # Invalid LLM mode
```

---

## Integration Patterns

### Command Error Logging Pattern

```bash
#!/usr/bin/env bash
# Source error handling library
source "${CLAUDE_CONFIG}/.claude/lib/core/error-handling.sh" 2>/dev/null

# Command metadata
COMMAND_NAME="/build"
WORKFLOW_ID="build_$(date +%Y%m%d_%H%M%S)"
USER_ARGS="$*"

# Ensure error log exists
ensure_error_log_exists

# Perform operation with error handling
if ! perform_operation; then
  # Log error with context
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "$ERROR_TYPE_EXECUTION" \
    "Operation failed: $(get_error_details)" \
    "bash_block" \
    "$(jq -n --arg phase "$PHASE" '{phase: $phase}')"

  exit 1
fi
```

### Subagent Error Handling Pattern

```bash
# Invoke subagent and capture output
output=$(invoke_agent "plan-architect" "Create plan")

# Check for TASK_ERROR signal
error_json=$(parse_subagent_error "$output")

if [ "$(echo "$error_json" | jq -r '.found')" = "true" ]; then
  error_type=$(echo "$error_json" | jq -r '.error_type')
  message=$(echo "$error_json" | jq -r '.message')
  context=$(echo "$error_json" | jq -c '.context')

  # Log to centralized error log
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "$error_type" \
    "$message" \
    "subagent_plan-architect" \
    "$context"

  # Handle error based on type
  if [ "$error_type" = "timeout_error" ]; then
    # Retry with increased timeout
    retry_metadata=$(retry_with_timeout "plan-architect invocation" 1)
    # ... retry logic
  fi
fi
```

### Query and Analysis Pattern

```bash
# Check for recent errors before operation
recent_build_errors=$(query_errors --command /build --limit 5)

if [ -n "$recent_build_errors" ]; then
  echo "Warning: Recent /build errors detected"
  echo "$recent_build_errors" | jq -r '.error_message'
fi

# Display error summary after batch operations
error_summary
```

---

## Performance Characteristics

| Function | Execution Time | Disk I/O | Notes |
|----------|---------------|----------|-------|
| log_command_error() | <10ms | Append-only | Atomic writes with rotation check |
| query_errors() | <100ms | Read-only | Linear scan with jq filtering |
| recent_errors() | <50ms | Read-only | tail + jq for last N entries |
| error_summary() | <200ms | Read-only | Full file scan with aggregation |
| classify_error() | <1ms | None | Pure regex matching |
| retry_with_backoff() | Variable | None | Depends on command being retried |

**Log File Size**: Typically <1MB for 1000 errors, rotates at 10MB

---

## See Also

- [Error Handling Pattern](../../concepts/patterns/error-handling.md) - Architecture and rationale
- [/errors Command Guide](../../guides/commands/errors-command-guide.md) - User guide for querying errors
- [Workflow State Machine](../../architecture/workflow-state-machine.md) - State machine integration
- [Utilities](utilities.md) - Other workflow support utilities
- [State Machine](state-machine.md) - State-based orchestration patterns
