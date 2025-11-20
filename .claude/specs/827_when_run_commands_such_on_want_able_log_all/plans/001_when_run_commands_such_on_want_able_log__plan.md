# Error Logging System Implementation Plan

## Metadata
- **Date**: 2025-11-19
- **Feature**: Centralized Error Logging for Commands and Subagents
- **Scope**: Full-stack error logging infrastructure with command context and subagent capture
- **Estimated Phases**: 5
- **Estimated Hours**: 12-16
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 71.5
- **Research Reports**:
  - [Error Logging Research](../reports/001_error_logging_research.md)

## Overview

This plan implements a centralized error logging system that captures errors from commands (/plan, /build, /debug, /research) and their subagents with full context association including command name, user prompt, workflow state, and stack trace. The system provides JSONL-based storage for efficient querying and includes a dedicated /errors command for error lookup and analysis.

## Research Summary

Key findings from the research report:
- **Existing Infrastructure**: `log_error_context()` exists in error-handling.sh but is not widely used and lacks command/prompt context
- **Gap Identified**: Errors are scattered across individual files and workflow-specific debug logs without centralized, queryable storage
- **Recommended Pattern**: JSONL log file at `.claude/data/logs/errors.jsonl` using `append_jsonl_log()` pattern from state-persistence.sh
- **Integration Points**: workflow-init.sh for USER_PROMPT capture, error-handling.sh for logging functions, agent guidelines for subagent error returns

Recommended approach: Create a centralized JSONL error log with structured entries containing timestamp, command, workflow_id, user_prompt, error_type, message, source, and context. Integrate with existing workflow initialization and state persistence patterns.

## Success Criteria
- [ ] All errors from /plan, /build, /debug, /research commands are logged to centralized errors.jsonl
- [ ] Error entries include command name, user prompt, workflow ID, error type, message, and context
- [ ] Subagent errors are captured via standardized TASK_ERROR return protocol
- [ ] /errors command can query errors by command, time window, and error type
- [ ] Existing commands work without regression after integration
- [ ] Error log rotation prevents unbounded growth (10MB limit)
- [ ] Human-readable error display with recent_errors() utility

## Technical Design

### Architecture Overview

```
+------------------+     +-------------------+     +------------------+
|   /build, etc.   | --> |  log_command_error| --> |  errors.jsonl    |
+------------------+     +-------------------+     +------------------+
        |                         ^                        |
        v                         |                        v
+------------------+     +-------------------+     +------------------+
|   init_workflow  |     | parse_subagent_   |     |  /errors query   |
|  (USER_PROMPT)   |     |  error()          |     |  recent_errors() |
+------------------+     +-------------------+     +------------------+
        |                         ^
        v                         |
+------------------+     +-------------------+
|   Subagent       | --> |  TASK_ERROR:      |
|   (Task tool)    |     |  return protocol  |
+------------------+     +-------------------+
```

### Error Entry Structure

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
  "phase": "implement",
  "state": "implement",
  "stack": ["load_workflow_state", "Block 3"],
  "context": {
    "state_file": "/path/to/state.sh",
    "plan_file": "/path/to/plan.md"
  }
}
```

### Component Responsibilities

1. **error-handling.sh**: Core logging functions (`log_command_error`, `parse_subagent_error`, `query_errors`, `recent_errors`)
2. **workflow-init.sh**: Capture and persist USER_PROMPT in workflow state
3. **Agent guidelines**: Define TASK_ERROR return protocol for subagent errors
4. **Commands**: Integrate error logging in bash blocks
5. **/errors command**: User-facing query interface

### Integration Strategy

- Non-breaking changes: Add optional error logging without modifying existing behavior
- Graceful degradation: Commands continue to work if error logging fails
- Backward compatibility: Existing error handling patterns preserved

## Implementation Phases

### Phase 1: Core Error Logging Infrastructure [COMPLETE]

**Dependencies**: []

**Objective**: Create the foundational error logging library functions and JSONL log file infrastructure

**Complexity**: Medium

**Tasks**:
- [x] Add `log_command_error()` function to `/home/benjamin/.config/.claude/lib/core/error-handling.sh`
  - Parameters: command, workflow_id, user_prompt, error_type, message, source, context_json
  - Generate timestamp in ISO 8601 format
  - Build JSON entry with jq
  - Append to errors.jsonl using `append_jsonl_log()` pattern
- [x] Add `parse_subagent_error()` function to error-handling.sh
  - Parse TASK_ERROR return signal from subagent output
  - Extract error_type and message from signal
  - Return structured error data for logging
- [x] Add `rotate_error_log()` function to error-handling.sh
  - Check errors.jsonl size (10MB threshold)
  - Rotate with 5-file retention (errors.jsonl.1, .2, etc.)
  - Preserve most recent errors
- [x] Create error log directory structure
  - Ensure `.claude/data/logs/` exists
  - Initialize empty errors.jsonl if not present
- [x] Add error type constants for consistency
  - STATE_ERROR, VALIDATION_ERROR, AGENT_ERROR, PARSE_ERROR, FILE_ERROR, TIMEOUT_ERROR

**Testing**:
```bash
# Source library and test logging
source .claude/lib/core/error-handling.sh
log_command_error "/test" "test_123" "test args" "test_error" "Test message" "bash_block" '{"key": "value"}'
# Verify: tail -1 .claude/data/logs/errors.jsonl | jq .
```

**Expected Duration**: 2-3 hours

---

### Phase 2: User Prompt Capture in Workflow Initialization [COMPLETE]

**Dependencies**: [1]

**Objective**: Modify workflow initialization to capture and persist the original user prompt for error context

**Complexity**: Low

**Tasks**:
- [x] Update `init_workflow()` in `/home/benjamin/.config/.claude/lib/workflow/workflow-init.sh`
  - Add new parameter: `$6 - user_args` (original command arguments)
  - Export `USER_ARGS` environment variable
  - Persist to state file: `append_workflow_state "USER_ARGS" "$user_args"`
- [x] Update `load_workflow_context()` in workflow-init.sh
  - Restore USER_ARGS from state file
  - Export for use in error logging
- [x] Update documentation in workflow-init.sh
  - Document new user_args parameter
  - Add example usage
- [x] Add helper function `get_error_context()`
  - Returns JSON with workflow context for error logging
  - Includes: COMMAND_NAME, WORKFLOW_ID, USER_ARGS, CURRENT_STATE, TOPIC_PATH

**Testing**:
```bash
# Test init_workflow with user args
source .claude/lib/workflow/workflow-init.sh
init_workflow "test" "test workflow" "full-implementation" 2 "[]" "arg1 arg2 --flag"
# Verify: grep USER_ARGS "$STATE_FILE"
```

**Expected Duration**: 1-2 hours

---

### Phase 3: Error Query Utilities and /errors Command [COMPLETE]

**Dependencies**: [1]

**Objective**: Implement error querying utilities and create the /errors command for user-facing error lookup

**Complexity**: Medium

**Tasks**:
- [x] Add `query_errors()` function to error-handling.sh
  - Parameters: --command, --since, --type, --limit, --workflow-id
  - Build jq filter from parameters
  - Return filtered JSONL entries
- [x] Add `recent_errors()` function to error-handling.sh
  - Parameter: count (default 10)
  - Format errors in human-readable output
  - Include: timestamp, command, workflow_id, error_type, message, user prompt (truncated)
- [x] Add `error_summary()` function to error-handling.sh
  - Aggregate errors by command and type
  - Return summary with counts
- [x] Create `/home/benjamin/.config/.claude/commands/errors.md`
  - allowed-tools: Bash, Read
  - argument-hint: [--command CMD] [--since TIME] [--type TYPE] [--limit N] [--summary]
  - description: Query and display error logs from commands and subagents
  - Parse arguments and invoke query utilities
  - Display results with formatting

**Testing**:
```bash
# Test query functions
source .claude/lib/core/error-handling.sh

# Log some test errors
log_command_error "/build" "build_1" "plan.md" "state_error" "Test 1" "bash_block" '{}'
log_command_error "/plan" "plan_1" "desc" "validation_error" "Test 2" "bash_block" '{}'

# Test queries
query_errors --command /build
recent_errors 5
error_summary
```

**Expected Duration**: 3-4 hours

---

### Phase 4: Command Integration [COMPLETE]

**Dependencies**: [1, 2, 3]

**Objective**: Integrate error logging into major commands (/build, /plan, /debug, /research)

**Complexity**: High

**Tasks**:
- [x] Update `/home/benjamin/.config/.claude/commands/build.md`
  - Pass user arguments to init_workflow() as 6th parameter
  - Add error logging in critical bash blocks (state loading, phase execution, completion)
  - Log errors with full context before returning error exit codes
  - Parse TASK_ERROR returns from implementer-coordinator subagent
- [x] Update `/home/benjamin/.config/.claude/commands/plan.md`
  - Pass user arguments to init_workflow()
  - Add error logging in classification, planning, and output blocks
  - Log errors from plan-architect subagent via TASK_ERROR
- [x] Update `/home/benjamin/.config/.claude/commands/debug.md`
  - Pass user arguments to init_workflow()
  - Add error logging in debug analysis and fix application
  - Log errors from debug-analyst subagent
- [x] Update `/home/benjamin/.config/.claude/commands/research.md`
  - Pass user arguments to init_workflow()
  - Add error logging in research orchestration
  - Log errors from research-specialist subagents
- [x] Create error logging wrapper pattern for consistent integration
  - Template for bash block error handling with logging

**Pattern for each command**:
```bash
# Error trap pattern for commands
trap_error() {
  local exit_code=$?
  if [ $exit_code -ne 0 ]; then
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "execution_error" \
      "Command failed with exit code $exit_code" \
      "bash_block" \
      "$(get_error_context)"
  fi
  return $exit_code
}
```

**Testing**:
```bash
# Test build command error logging
/build nonexistent.md
# Verify: recent_errors 1 | grep "/build"

# Test plan command error logging
/plan "" --complexity 5  # Invalid complexity
# Verify: query_errors --command /plan
```

**Expected Duration**: 4-5 hours

---

### Phase 5: Subagent Error Protocol and Agent Guidelines [COMPLETE]

**Dependencies**: [1, 4]

**Objective**: Define and implement standardized error return protocol for subagents

**Complexity**: Medium

**Tasks**:
- [x] Update `/home/benjamin/.config/.claude/agents/implementer-coordinator.md`
  - Add "Error Return Protocol" section
  - Define TASK_ERROR signal format: `TASK_ERROR: {error_type} - {message}`
  - Document when to return errors vs complete normally
  - Add error context logging before return
- [x] Update `/home/benjamin/.config/.claude/agents/research-specialist.md`
  - Add "Error Return Protocol" section
  - Standardize error returns for research failures
- [x] Update `/home/benjamin/.config/.claude/agents/debug-analyst.md`
  - Add "Error Return Protocol" section
  - Standardize error returns for debug failures
- [x] Update `/home/benjamin/.config/.claude/agents/plan-architect.md`
  - Add "Error Return Protocol" section
  - Standardize error returns for planning failures
- [x] Add `parse_task_output_for_error()` function to error-handling.sh
  - Scan Task tool output for TASK_ERROR signal
  - Extract and parse error details
  - Return structured error for parent command logging
- [x] Document error return protocol in hierarchical-agents.md
  - Add section explaining the standardized protocol
  - Include examples of proper error returns

**Error Return Protocol Format**:
```markdown
## Error Return Protocol

If your task cannot be completed due to an error:

1. Output error context (for logging):
   ```
   ERROR_CONTEXT: {
     "error_type": "file_not_found",
     "message": "Required file not found",
     "details": {"path": "/expected/path"}
   }
   ```

2. Return error signal:
   ```
   TASK_ERROR: file_not_found - Required file not found at /expected/path
   ```

3. Parent command will log this to errors.jsonl with full workflow context.
```

**Testing**:
```bash
# Test subagent error parsing
output="Some output...
TASK_ERROR: validation_error - Schema mismatch
More output..."

error_json=$(parse_task_output_for_error "$output")
echo "$error_json" | jq .
# Should return: {"error_type": "validation_error", "message": "Schema mismatch"}
```

**Expected Duration**: 2-3 hours

---

## Testing Strategy

### Unit Tests
- Test individual functions: `log_command_error`, `query_errors`, `recent_errors`, `parse_subagent_error`
- Test error entry JSON structure validity
- Test log rotation behavior
- Test query filter combinations

### Integration Tests
- Test full error flow: init_workflow -> error -> log_command_error -> query_errors
- Test subagent error capture: Task tool -> TASK_ERROR -> parse -> log
- Test /errors command with various filter combinations
- Test error logging doesn't break existing command behavior

### Regression Tests
- Verify /build, /plan, /debug, /research commands complete successfully
- Verify error logging is non-blocking (commands continue on log failure)
- Verify workflow state persistence unaffected

### Test Commands
```bash
# Run error handling library tests
bash .claude/tests/test_error_logging.sh

# Test /errors command
/errors --limit 5
/errors --command /build
/errors --since 2025-11-19
/errors --summary

# Integration test: trigger and query error
/build nonexistent.md 2>&1 || true
/errors --command /build --limit 1
```

## Documentation Requirements

- [ ] Update `/home/benjamin/.config/.claude/docs/reference/library-api/overview.md`
  - Add error-handling.sh new functions documentation
  - Include function signatures, parameters, return values
  - Add usage examples
- [ ] Update `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents.md`
  - Add "Error Return Protocol" section
  - Document TASK_ERROR signal format
  - Add examples for each agent type
- [ ] Create `/home/benjamin/.config/.claude/docs/guides/patterns/error-logging-integration.md`
  - Document how to integrate error logging in new commands
  - Provide code templates
  - List error types and when to use them
- [ ] Update `/home/benjamin/.config/.claude/docs/troubleshooting/bash-tool-limitations.md`
  - Add section on error logging for debugging
  - Document how to query errors after failures

## Dependencies

### External Dependencies
- jq (JSON processing) - already available
- Standard bash utilities (date, tail, wc) - already available

### Internal Dependencies
- `/home/benjamin/.config/.claude/lib/core/error-handling.sh` - existing library to extend
- `/home/benjamin/.config/.claude/lib/core/state-persistence.sh` - `append_jsonl_log()` pattern
- `/home/benjamin/.config/.claude/lib/workflow/workflow-init.sh` - workflow initialization
- `/home/benjamin/.config/.claude/commands/build.md` - primary integration target
- Agent markdown files - subagent protocol integration

### Prerequisites
- Research report reviewed and recommendations incorporated
- Existing error-handling.sh library functional
- Workflow initialization working correctly

## Risks and Mitigations

### Risk 1: Performance Impact
- **Concern**: Error logging adds overhead to command execution
- **Mitigation**: Use append-only JSONL for fast writes, log rotation to prevent file growth, async logging if needed

### Risk 2: Log Rotation Data Loss
- **Concern**: Important errors lost during rotation
- **Mitigation**: Rotate only when file exceeds 10MB, keep 5 backup files, rotate least-recent first

### Risk 3: Subagent Error Capture
- **Concern**: Subagent errors may not follow protocol
- **Mitigation**: Make error protocol optional (graceful degradation), detect common error patterns, provide clear documentation

### Risk 4: Breaking Existing Commands
- **Concern**: Integration changes break working commands
- **Mitigation**: Non-breaking additions only, error logging wrapped in try-catch, full regression testing

## Rollback Plan

If implementation causes issues:
1. Remove error logging calls from commands (grep for `log_command_error`)
2. Remove /errors command file
3. Keep library functions (no harm if unused)
4. Restore original command versions from git

## Notes

- **Phase dependencies**: Enable wave-based execution for Phase 2 and Phase 3 (parallel after Phase 1)
- **Error types**: Use constants for consistency across codebase
- **Log format**: JSONL chosen for streaming and incremental analysis
- **Query performance**: For large logs, consider adding index file with timestamps

**Expansion Hint**: If Phase 4 (Command Integration) proves complex during implementation, use `/expand-phase 4` to break it into per-command stages.
