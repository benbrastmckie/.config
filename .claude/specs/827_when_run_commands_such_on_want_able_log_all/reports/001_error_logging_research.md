# Error Logging System Research Report

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: Error Logging for Commands and Subagents
- **Report Type**: codebase analysis

## Executive Summary

The current .claude/ system has foundational error handling capabilities but lacks centralized error logging with command/prompt context association. Errors are logged in scattered locations without consistent correlation to the triggering command and user prompt. A unified error logging system should integrate with existing state-persistence.sh and error-handling.sh libraries, capturing errors from both bash blocks and Task tool subagent invocations with full command context.

## Findings

### 1. Current Error Handling Architecture

#### error-handling.sh (Lines 1-881)

**Location**: `/home/benjamin/.config/.claude/lib/core/error-handling.sh`

This is the primary error handling library with several capabilities:

**Error Classification** (Lines 29-55):
- Classifies errors as transient, permanent, or fatal
- LLM-specific error types (timeout, API error, low confidence, parse error)

**Error Logging Function** (Lines 354-393):
```bash
log_error_context() {
  local error_type="${1:-unknown}"
  local location="${2:-unknown}"
  local message="${3:-}"
  local context_data="${4:-{}}"

  # Logs to: .claude/data/logs/error_{timestamp}.log
  # Includes timestamp, error type, location, message, context data
  # Also captures basic stack trace via caller
}
```

**Key Gap**: The `log_error_context` function exists but:
- Is not widely used across commands
- Does not capture the original command name or user prompt
- Creates individual files per error (not searchable)
- Stack trace is bash-only, not useful for subagent context

**Orchestrate-Specific Error Contexts** (Lines 639-742):
- `format_orchestrate_agent_failure()` - Formats agent invocation failures
- `format_orchestrate_test_failure()` - Formats test failures with workflow context
- These format messages but don't persistently log them

### 2. Current Logging Infrastructure

#### unified-logger.sh (Lines 1-825)

**Location**: `/home/benjamin/.config/.claude/lib/core/unified-logger.sh`

**Log Files**:
- `.claude/data/logs/adaptive-planning.log` - Primary workflow log
- `.claude/data/logs/conversion.log` - Document conversion specific

**Existing Logging Functions**:
- `write_log_entry()` (Lines 115-136) - Structured logging with level, event type, message, data
- `log_trigger_evaluation()` (Lines 141-153) - Logs trigger evaluations
- `log_replan_invocation()` (Lines 231-257) - Logs replanning with success/failure status
- `rotate_log_file()` (Lines 72-100) - Log rotation at 10MB with 5 file retention

**Key Gap**: Current logging is focused on workflow state transitions and adaptive planning triggers, not on capturing command execution errors with prompt context.

### 3. Existing Log Directory Structure

**Location**: `/home/benjamin/.config/.claude/data/logs/`

Current logs found:
- `hook-debug.log` (429KB) - Hook execution debugging
- `tts.log` (270KB) - Text-to-speech operations
- `complexity-debug.log` (18KB) - Complexity assessment debugging
- `subagent-outputs.log` (1.3KB) - Subagent outputs (nearly empty)
- `phase-handoffs.log` (1.7KB) - Phase handoff records
- `approval-decisions.log` (3.5KB) - User approval tracking

**Key Gap**: No centralized error log exists. `subagent-outputs.log` exists but is barely used and doesn't capture errors specifically.

### 4. Command Execution Patterns

#### Task Tool Subagent Invocations

**Example from build.md** (Lines 241-283):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with wave-based parallelization"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md
    ...
    Return: IMPLEMENTATION_COMPLETE: {PHASE_COUNT}
  "
}
```

**Error Capture Gap**: When Task tool subagents fail:
- No mechanism to capture the error message
- No association with the parent command
- No way to retrieve the prompt that was sent
- Subagent context is lost when it exits

#### Bash Block Error Patterns

Commands use `set -e` for fail-fast but errors are:
- Printed to stderr without logging
- Lost when bash block exits
- Not associated with workflow context

**Example from build.md** (Lines 793-805):
```bash
if [ ! -f "$STATE_FILE" ]; then
  {
    echo "[$(date)] ERROR: State file not found"
    echo "WHICH: load_workflow_state"
    echo "WHAT: File does not exist at expected path"
    echo "WHERE: Block 4, workflow completion"
    echo "PATH: $STATE_FILE"
  } >> "$DEBUG_LOG"
  echo "ERROR: State file not found (see $DEBUG_LOG)" >&2
  exit 1
fi
```

This is the closest pattern to structured error logging but:
- Logs to `DEBUG_LOG` (workflow-specific debug log)
- Doesn't include command name or user prompt
- Not centralized or easily queryable

### 5. State Persistence Architecture

#### state-persistence.sh (Lines 1-498)

**Location**: `/home/benjamin/.config/.claude/lib/core/state-persistence.sh`

**Relevant Functions**:
- `append_workflow_state()` (Lines 321-336) - Append key-value to state file
- `save_json_checkpoint()` (Lines 359-377) - Atomic JSON checkpoint writes
- `append_jsonl_log()` (Lines 483-498) - Append JSON entries to JSONL log

**Key Insight**: The `append_jsonl_log()` function provides an ideal pattern for error logging:
```bash
append_jsonl_log() {
  local log_name="$1"
  local json_entry="$2"
  # Appends to .claude/tmp/${log_name}.jsonl
  # Enables streaming and incremental analysis
}
```

This could be extended for error logging with command context.

### 6. Workflow State Machine

#### workflow-state-machine.sh (Lines 1-923)

**Location**: `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh`

**Error Handler** (Lines 767-858):
```bash
handle_state_error() {
  local error_message="$1"
  local current_state="${CURRENT_STATE:-unknown}"
  local exit_code="${2:-1}"

  # Five-component error format:
  # 1. What failed
  # 2. Expected state/behavior
  # 3. Diagnostic commands
  # 4. Context (workflow phase, state)
  # 5. Recommended action
}
```

**Key Gap**: This function provides excellent diagnostic output but:
- Only prints to stderr
- Doesn't persist errors
- Doesn't capture the original user prompt

### 7. Subagent Communication Patterns

From hierarchical-agents.md (Lines 1-200):

Subagents communicate via return signals like:
- `IMPLEMENTATION_COMPLETE: {PHASE_COUNT}`
- `REPORT_CREATED: {path}`
- `DEBUG_COMPLETE: {report_path}`

**Key Gap**: There's no standardized error return signal. When subagents fail:
- They may exit without returning anything
- Error context is lost
- Parent command can't log the specific failure

## Gaps Analysis

### Gap 1: No Command Context in Error Logs
- Errors don't include which command invoked them
- User's original prompt not captured
- Subagent prompts not logged

### Gap 2: Scattered Error Logging
- `DEBUG_LOG` per-workflow
- `log_error_context()` creates individual files
- No single queryable error log

### Gap 3: No Subagent Error Capture
- Task tool failures not captured
- Subagent stderr not logged
- No error return protocol

### Gap 4: No Query/Lookup Mechanism
- Can't search errors by command
- Can't filter by time window
- Can't correlate errors across workflows

### Gap 5: No Error Aggregation
- Per-workflow errors isolated
- No cross-workflow error patterns
- No error frequency analysis

## Recommendations

### Recommendation 1: Create Centralized Error Log

Create a new JSONL error log at `.claude/data/logs/errors.jsonl` with structured entries:

```json
{
  "timestamp": "2025-11-19T14:30:00Z",
  "command": "/build",
  "workflow_id": "build_1732023400",
  "user_prompt": "plan.md 3 --dry-run",
  "error_type": "state_restoration",
  "error_message": "State file not found",
  "source": "bash_block",
  "block_number": 3,
  "state": "implement",
  "stack": ["load_workflow_state", "Block 3"],
  "context": {
    "state_file": "/path/to/state.sh",
    "plan_file": "/path/to/plan.md"
  }
}
```

### Recommendation 2: Implement log_command_error() Function

Add to error-handling.sh:

```bash
# log_command_error: Log error with full command context
# Usage: log_command_error <command> <workflow_id> <user_prompt> <error_type> <message> [context_json]
log_command_error() {
  local command="${1:-unknown}"
  local workflow_id="${2:-unknown}"
  local user_prompt="${3:-}"
  local error_type="${4:-unknown}"
  local message="${5:-}"
  local context_json="${6:-{}}"

  local error_entry
  error_entry=$(jq -n \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg command "$command" \
    --arg workflow_id "$workflow_id" \
    --arg user_prompt "$user_prompt" \
    --arg error_type "$error_type" \
    --arg message "$message" \
    --argjson context "$context_json" \
    '{
      timestamp: $timestamp,
      command: $command,
      workflow_id: $workflow_id,
      user_prompt: $user_prompt,
      error_type: $error_type,
      message: $message,
      context: $context
    }')

  mkdir -p "${CLAUDE_PROJECT_DIR}/.claude/data/logs"
  echo "$error_entry" >> "${CLAUDE_PROJECT_DIR}/.claude/data/logs/errors.jsonl"
}
```

### Recommendation 3: Capture User Prompt at Command Start

Modify workflow-init.sh `init_workflow()` to:
1. Accept and persist the original user arguments
2. Export `USER_PROMPT` for use in error logging
3. Persist to state file for subagent access

```bash
# In init_workflow()
export USER_PROMPT="$*"
append_workflow_state "USER_PROMPT" "$USER_PROMPT"
append_workflow_state "COMMAND_NAME" "$command_name"
```

### Recommendation 4: Standardize Subagent Error Returns

Add error return protocol to agent guidelines:

```markdown
## Error Return Protocol

If your task cannot be completed due to an error:

1. Log the error context:
   ```
   ERROR_CONTEXT: {
     "error_type": "file_not_found",
     "message": "Report template not found",
     "details": {"expected_path": "..."}
   }
   ```

2. Return error signal:
   ```
   TASK_ERROR: {error_type} - {brief_message}
   ```

3. Parent command will log this to errors.jsonl with full context.
```

### Recommendation 5: Create Error Query Utility

Add to error-handling.sh or create new file `.claude/lib/core/error-query.sh`:

```bash
# query_errors: Query error log with filters
# Usage: query_errors [--command CMD] [--since TIME] [--type TYPE] [--limit N]
query_errors() {
  local error_log="${CLAUDE_PROJECT_DIR}/.claude/data/logs/errors.jsonl"
  local jq_filter="."
  local limit=20

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --command) jq_filter="$jq_filter | select(.command == \"$2\")"; shift 2 ;;
      --since) jq_filter="$jq_filter | select(.timestamp >= \"$2\")"; shift 2 ;;
      --type) jq_filter="$jq_filter | select(.error_type == \"$2\")"; shift 2 ;;
      --limit) limit="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  jq -c "$jq_filter" "$error_log" | tail -n "$limit"
}

# recent_errors: Show recent errors in human-readable format
# Usage: recent_errors [N]
recent_errors() {
  local count="${1:-10}"
  local error_log="${CLAUDE_PROJECT_DIR}/.claude/data/logs/errors.jsonl"

  tail -n "$count" "$error_log" | jq -r '
    "[" + .timestamp + "] " + .command + " (" + .workflow_id + ")\n" +
    "  Type: " + .error_type + "\n" +
    "  Message: " + .message + "\n" +
    "  Prompt: " + .user_prompt + "\n"
  '
}
```

### Recommendation 6: Add /errors Command

Create `.claude/commands/errors.md` for easy error lookup:

```markdown
---
allowed-tools: Bash, Read
argument-hint: [--command CMD] [--since TIME] [--type TYPE] [--limit N]
description: Query and display error logs from commands and subagents
---

# /errors - Error Log Query Command

Query the centralized error log to view recent errors.

## Usage Examples

```bash
# Show last 10 errors
/errors

# Show errors from /build command
/errors --command /build

# Show errors from today
/errors --since 2025-11-19

# Show only state restoration errors
/errors --type state_restoration
```
```

### Recommendation 7: Integration Points

**Commands to update**:
1. `/plan` - Add error logging in bash blocks
2. `/build` - Add error logging in bash blocks
3. `/debug` - Add error logging in bash blocks
4. `/research` - Add error logging in bash blocks

**Libraries to update**:
1. `workflow-init.sh` - Persist USER_PROMPT
2. `error-handling.sh` - Add log_command_error()
3. `workflow-state-machine.sh` - Log state errors

**Agent guidelines to update**:
1. `research-specialist.md` - Error return protocol
2. `implementer-coordinator.md` - Error return protocol
3. `debug-analyst.md` - Error return protocol

## Implementation Priority

1. **Phase 1** (Core Infrastructure):
   - Create errors.jsonl log file
   - Implement log_command_error() function
   - Add query_errors() utility

2. **Phase 2** (Command Integration):
   - Update init_workflow() to capture USER_PROMPT
   - Add error logging to major commands (/build, /plan)
   - Test error capture flow

3. **Phase 3** (Subagent Integration):
   - Define error return protocol
   - Update agent guidelines
   - Parse and log subagent errors

4. **Phase 4** (Query Interface):
   - Create /errors command
   - Add recent_errors() human-readable format
   - Add error statistics/aggregation

## References

### Files Analyzed

- `/home/benjamin/.config/.claude/lib/core/error-handling.sh` (Lines 1-881)
- `/home/benjamin/.config/.claude/lib/core/unified-logger.sh` (Lines 1-825)
- `/home/benjamin/.config/.claude/lib/core/state-persistence.sh` (Lines 1-498)
- `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh` (Lines 1-923)
- `/home/benjamin/.config/.claude/lib/workflow/workflow-init.sh` (Lines 1-415)
- `/home/benjamin/.config/.claude/commands/build.md` (Lines 1-949)
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents.md` (Lines 1-200)

### Key Functions Referenced

- `log_error_context()` - error-handling.sh:364
- `write_log_entry()` - unified-logger.sh:115
- `append_jsonl_log()` - state-persistence.sh:483
- `handle_state_error()` - workflow-state-machine.sh:767
- `init_workflow()` - workflow-init.sh:114
- `format_orchestrate_agent_failure()` - error-handling.sh:646

### Existing Log Locations

- `.claude/data/logs/adaptive-planning.log`
- `.claude/data/logs/errors.jsonl` (proposed)
- `.claude/tmp/workflow_debug.log`

## Implementation Status
- **Status**: Planning Complete
- **Plan**: [../plans/001_when_run_commands_such_on_want_able_log__plan.md](../plans/001_when_run_commands_such_on_want_able_log__plan.md)
- **Implementation**: [Will be updated by orchestrator]
- **Date**: 2025-11-19
