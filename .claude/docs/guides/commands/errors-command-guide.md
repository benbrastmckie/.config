# /errors Command - Complete Guide

**Executable**: `.claude/commands/errors.md`

**Quick Start**: Run `/errors` to view recent errors, or `/errors --summary` for error statistics.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Usage Examples](#usage-examples)
4. [Advanced Topics](#advanced-topics)
5. [Troubleshooting](#troubleshooting)
6. [See Also](#see-also)

---

## Overview

### Purpose

The `/errors` command provides access to the centralized error logging system, allowing you to query, filter, and analyze errors from all commands and subagents. It displays error logs with detailed context including timestamps, error types, workflow IDs, and stack traces.

### When to Use

- **Debugging workflows**: Investigate why a command or workflow failed
- **Error analysis**: Analyze patterns in errors across commands
- **Workflow troubleshooting**: Track errors for specific workflow IDs
- **Post-mortem analysis**: Review errors that occurred during a time period
- **Error monitoring**: Check for recent errors or error trends

### When NOT to Use

- **Creating error logs**: Errors are logged automatically by commands
- **Debugging code directly**: Use `/debug` for active debugging workflows
- **Live error monitoring**: This queries historical logs, not live streams

---

## Architecture

### Design Principles

1. **Centralized Logging**: All errors stored in single JSONL file
2. **Rich Context**: Includes command, workflow_id, timestamp, stack trace, error type
3. **Query Interface**: Filter by command, time, type, workflow ID
4. **Multiple Views**: Recent errors, filtered queries, summary statistics, raw JSONL
5. **Automatic Rotation**: 10MB log rotation with 5 backup files

### Patterns Used

- **JSONL Format**: One JSON object per line for easy streaming/parsing
- **Structured Logging**: Consistent schema for all error entries
- **Time-Series Data**: ISO 8601 timestamps for chronological queries
- **Error Taxonomy**: Standardized error types for classification

### Integration Points

- **Error Handling Library**: `.claude/lib/core/error-handling.sh` (>=1.0.0)
- **Log Storage**: `.claude/data/logs/errors.jsonl`
- **Commands**: All commands can log errors via `log_command_error`
- **Workflow Context**: Integrates with workflow-init.sh for context extraction

### Data Flow

1. **Input**: User provides filter options (command, time, type, etc.)
2. **Query**: `query_errors` function filters JSONL log file
3. **Format**: Results formatted as human-readable or raw JSON
4. **Output**: Displays filtered errors or summary statistics

---

## Usage Examples

### Basic Usage

```bash
# Show last 10 errors (default)
/errors

# Show last 5 errors
/errors --limit 5

# Show error summary statistics
/errors --summary
```

### Filtering by Command

```bash
# Show errors from /build command
/errors --command /build

# Show errors from /plan command
/errors --command /plan --limit 20
```

### Filtering by Time

```bash
# Show errors since a specific date
/errors --since 2025-11-19

# Show errors since a specific timestamp
/errors --since 2025-11-19T10:00:00Z

# Combine with command filter
/errors --command /build --since 2025-11-19 --limit 10
```

### Filtering by Error Type

```bash
# Show validation errors only
/errors --type validation_error

# Show state errors from /build
/errors --command /build --type state_error

# Show agent errors
/errors --type agent_error --limit 15
```

### Filtering by Workflow

```bash
# Show errors for specific workflow ID
/errors --workflow-id build_1732023400

# Combine with error type
/errors --workflow-id plan_1732023100 --type validation_error
```

### Raw Output

```bash
# Get raw JSONL for processing
/errors --raw --limit 5

# Filter and get raw output
/errors --command /build --type state_error --raw
```

### Complex Filters

```bash
# Multiple filters combined
/errors --command /build --type state_error --since 2025-11-19 --limit 5

# Recent errors of specific type
/errors --type validation_error --limit 10

# Workflow-specific errors since date
/errors --workflow-id build_123 --since 2025-11-18
```

---

## Advanced Topics

### Error Types

The system recognizes these standard error types:

| Error Type | Description | Common Causes |
|------------|-------------|---------------|
| `state_error` | Workflow state persistence issues | Missing state files, corrupted state |
| `validation_error` | Input validation failures | Invalid arguments, schema mismatches |
| `agent_error` | Subagent execution failures | Agent crashes, timeout, bad output |
| `parse_error` | Output parsing failures | Malformed JSON, missing fields |
| `file_error` | File system operation failures | Missing files, permission errors |
| `timeout_error` | Operation timeout errors | Long-running operations, hangs |
| `execution_error` | General execution failures | Command failures, unexpected errors |

### Log Entry Schema

Each error log entry contains:

```json
{
  "timestamp": "2025-11-19T14:30:00Z",
  "command": "/build",
  "workflow_id": "build_1732023400",
  "user_args": "plan.md 3",
  "error_type": "state_error",
  "error_message": "State file not found",
  "execution_context": "bash_block",
  "additional_context": {"plan_file": "/path/to/plan.md"},
  "stack_trace": ["caller1", "caller2", "..."]
}
```

### Output Format Options

1. **Recent Errors** (default): Human-readable format with timestamps, command, type, message
2. **Filtered Errors**: Same format as recent, but with query filters applied
3. **Summary**: Statistics by command, error type, and time range
4. **Raw**: JSONL output for scripting/processing

### Log Rotation

- Automatic rotation at 10MB
- Keeps 5 backup files (errors.jsonl.1 through errors.jsonl.5)
- Rotation preserves chronological order
- Backups compressed with gzip (optional)

### Integration with Commands

Commands log errors using the error-handling library:

```bash
# Source library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh"

# Log an error
log_command_error \
  "$COMMAND_NAME" \
  "$WORKFLOW_ID" \
  "$USER_ARGS" \
  "validation_error" \
  "Invalid complexity value: must be 1-4" \
  "bash_block" \
  '{"complexity": "10"}'
```

---

## Complete Error Management Workflow

The `/errors` command is part of a comprehensive error management lifecycle that supports systematic error resolution. Understanding this workflow helps you effectively use error logging for debugging and continuous improvement.

### Error Lifecycle Phases

**1. Error Production (Automatic)**
- Commands and agents automatically log errors via `log_command_error()`
- Errors stored in `~/.claude/data/logs/errors.jsonl` with full context
- No manual intervention required

**2. Error Querying (/errors)**
- View and filter logged errors by time, type, command, or severity
- Generate summary reports to identify patterns
- Export filtered results for further analysis

**3. Error Analysis (/repair)**
- Group errors by pattern and root cause
- Create error analysis reports in `specs/{NNN_topic}/reports/`
- Generate implementation plans with fix phases

**4. Fix Implementation (/build)**
- Execute repair plans with automatic testing
- Create git commits for each fix phase
- Verify fixes resolve logged errors

### Example Workflow

After a failed `/build` command execution:

```bash
# Step 1: Query recent build errors
/errors --command /build --since 1h --summary

# Output shows 5 state_error instances in phase execution

# Step 2: Analyze error patterns
/repair --command /build --type state_error --complexity 2

# Creates:
# - specs/856_build_state_errors/reports/001_build_state_error_analysis.md
# - specs/856_build_state_errors/plans/001_build_state_error_fix_plan.md

# Step 3: Review plan and implement fixes
/build specs/856_build_state_errors/plans/001_build_state_error_fix_plan.md

# Step 4: Verify fixes resolved errors
/errors --command /build --since 10m

# Output: No errors found (confirmation)
```

### Integration Points

- **Error Handling Pattern**: See [Error Handling Pattern](../../concepts/patterns/error-handling.md) for technical integration details
- **Repair Command**: See [Repair Command Guide](repair-command-guide.md) for systematic error analysis workflow
- **Build Command**: See [Build Command Guide](build-command-guide.md) for executing repair plans

---

## Troubleshooting

### No Errors Displayed

**Problem**: `/errors` shows "No errors found"

**Solutions**:
- Check if log file exists: `ls -l .claude/data/logs/errors.jsonl`
- Verify log file has content: `wc -l .claude/data/logs/errors.jsonl`
- Try `--raw` option to see if filtering is too strict
- Check time filter - try `--since` with earlier date

### Invalid JSON Errors

**Problem**: "Entry is not valid JSON" warnings

**Solutions**:
- Check for corrupted log entries: `jq empty < .claude/data/logs/errors.jsonl`
- Manually inspect problematic lines
- Rotate log to start fresh: `rm .claude/data/logs/errors.jsonl`

### Performance Issues

**Problem**: `/errors` is slow with large logs

**Solutions**:
- Use `--limit` to reduce results: `/errors --limit 10`
- Filter by time: `/errors --since 2025-11-19`
- Filter by command: `/errors --command /build`
- Consider rotating old logs manually

### Missing Workflow Context

**Problem**: Errors show "unknown" for workflow_id or command

**Solutions**:
- Ensure commands source workflow-init.sh before error-handling.sh
- Check that COMMAND_NAME and WORKFLOW_ID are exported
- Use `get_error_context` function for automatic context extraction

### Summary Shows Zero Errors

**Problem**: `/errors --summary` shows 0 errors but errors exist

**Solutions**:
- Check log file permissions: `ls -l .claude/data/logs/errors.jsonl`
- Verify error_summary function: `source .claude/lib/core/error-handling.sh && error_summary`
- Check for jq availability: `which jq`

---

## See Also

### Related Documentation

- [Error Handling Library API](../../reference/library-api/error-handling.md)
- [Workflow State Machine](../../architecture/workflow-state-machine.md)
- [Debugging Guide](../../workflows/debugging-guide.md)

### Related Commands

- `/repair` - Error analysis and repair planning workflow
- `/debug` - Debug workflow with root cause analysis
- `/build` - Build workflow (uses error logging)
- `/plan` - Planning workflow (uses error logging)

### Related Patterns

- [Error Handling Patterns](../../concepts/patterns/error-handling.md)
- [Logging Best Practices](../../guides/patterns/logging-patterns.md)
- [Workflow Context Management](../../concepts/patterns/context-management.md)

### Standards References

- [Command Authoring Standards](../../reference/standards/command-authoring.md)
- [Testing Protocols](../../reference/standards/testing-protocols.md)
- [Output Formatting Standards](../../reference/standards/output-formatting.md)
