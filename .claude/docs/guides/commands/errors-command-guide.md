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

The `/errors` command provides two modes for working with the centralized error logging system:

1. **Report Generation Mode** (default): Delegates to the errors-analyst agent to generate structured error analysis reports with pattern detection, statistics, and recommendations
2. **Query Mode** (`--query` flag): Directly queries and displays error logs with filtering capabilities (backward compatible with previous behavior)

### When to Use

- **Report Mode**: Generate comprehensive error analysis reports for documentation or /repair workflow integration
- **Error pattern analysis**: Identify recurring error patterns across commands and workflows
- **Debugging workflows**: Investigate why a command or workflow failed
- **Workflow troubleshooting**: Track errors for specific workflow IDs
- **Post-mortem analysis**: Create detailed analysis reports for time periods
- **Query Mode**: Quick ad-hoc error queries when full report is not needed

### When NOT to Use

- **Creating error logs**: Errors are logged automatically by commands
- **Debugging code directly**: Use `/debug` for active debugging workflows
- **Live error monitoring**: This queries historical logs, not live streams

---

## Architecture

### Design Principles

1. **Dual-Mode Operation**: Report generation (default) and query mode (--query flag)
2. **Agent Delegation**: Haiku model for context-efficient error analysis
3. **Centralized Logging**: All errors stored in single JSONL file
4. **Rich Context**: Includes command, workflow_id, timestamp, stack trace, error type
5. **Query Interface**: Filter by command, time, type, workflow ID
6. **Multiple Views**: Structured reports, recent errors, filtered queries, summary statistics, raw JSONL
7. **Automatic Rotation**: 10MB log rotation with 5 backup files
8. **Comprehensive Coverage**: 80%+ error logging coverage enforced via linters (Spec 945)

### Error Logging Coverage

As of Spec 945 (Error Logging Coverage Refactor), all commands maintain 80%+ error logging coverage:

- **Bash Error Traps**: Automatic logging of unhandled errors (exit 127, command failures)
- **State Restoration Validation**: `validate_state_restoration()` logs missing variables
- **Explicit Logging**: `log_command_error` calls before validation exits
- **Enforcement**: Pre-commit hooks prevent coverage regressions below 80%

This ensures the `/errors` command captures the vast majority of errors that occur in practice, making error analysis and repair workflows highly effective.

### Patterns Used

- **Agent Delegation**: errors-analyst agent handles report generation (Haiku model)
- **JSONL Format**: One JSON object per line for easy streaming/parsing
- **Structured Logging**: Consistent schema for all error entries
- **Time-Series Data**: ISO 8601 timestamps for chronological queries
- **Error Taxonomy**: Standardized error types for classification
- **Topic-Based Artifacts**: Reports stored in `.claude/specs/{NNN_topic}/reports/`

### Integration Points

- **Agents**: errors-analyst (claude-3-5-haiku-20241022)
- **Error Handling Library**: `.claude/lib/core/error-handling.sh` (>=1.0.0)
- **State Machine Library**: `.claude/lib/workflow/workflow-state-machine.sh` (>=2.0.0)
- **Location Detection**: `.claude/lib/core/unified-location-detection.sh` (>=1.0.0)
- **Log Storage**: `.claude/data/logs/errors.jsonl`
- **Report Artifacts**: `.claude/specs/{NNN_error_analysis}/reports/001_error_report.md`
- **Commands**: All commands can log errors via `log_command_error`
- **Workflow Context**: Integrates with workflow-init.sh for context extraction

### Data Flow

**Report Mode (Default)**:
1. **Input**: User provides filter options (command, time, type, etc.)
2. **Setup**: Create topic-based directory structure for artifacts
3. **Invocation**: Invoke errors-analyst agent via Task tool
4. **Analysis**: Agent reads error log, parses JSONL, groups by patterns
5. **Report**: Agent generates structured markdown report with findings
6. **Verification**: Command verifies report exists and extracts summary
7. **Output**: Displays report path and key statistics

**Query Mode (--query flag)**:
1. **Input**: User provides filter options (command, time, type, etc.)
2. **Query**: `query_errors` function filters JSONL log file
3. **Format**: Results formatted as human-readable or raw JSON
4. **Output**: Displays filtered errors or summary statistics

---

## Usage Examples

### Report Generation (Default Mode)

```bash
# Generate error analysis report for all errors
/errors

# Generate report for specific command errors
/errors --command /build

# Generate report for specific error type
/errors --type execution_error

# Generate report for errors since yesterday
/errors --since 2025-11-20

# Generate report with multiple filters
/errors --command /build --type state_error --since 2025-11-19
```

### Query Mode (Legacy Behavior)

```bash
# Show last 10 errors directly
/errors --query

# Show last 5 errors
/errors --query --limit 5

# Show error summary statistics
/errors --query --summary
```

### Query Mode - Filtering by Command

```bash
# Show errors from /build command
/errors --query --command /build

# Show errors from /plan command
/errors --query --command /plan --limit 20
```

### Query Mode - Filtering by Time

```bash
# Show errors since a specific date
/errors --query --since 2025-11-19

# Show errors since a specific timestamp
/errors --query --since 2025-11-19T10:00:00Z

# Combine with command filter
/errors --query --command /build --since 2025-11-19 --limit 10
```

### Query Mode - Filtering by Error Type

```bash
# Show validation errors only
/errors --query --type validation_error

# Show state errors from /build
/errors --query --command /build --type state_error

# Show agent errors
/errors --query --type agent_error --limit 15
```

### Query Mode - Filtering by Workflow

```bash
# Show errors for specific workflow ID
/errors --query --workflow-id build_1732023400

# Combine with error type
/errors --query --workflow-id plan_1732023100 --type validation_error
```

### Query Mode - Raw Output

```bash
# Get raw JSONL for processing
/errors --query --raw --limit 5

# Filter and get raw output
/errors --query --command /build --type state_error --raw
```

### Query Mode - Complex Filters

```bash
# Multiple filters combined
/errors --query --command /build --type state_error --since 2025-11-19 --limit 5

# Recent errors of specific type
/errors --query --type validation_error --limit 10

# Workflow-specific errors since date
/errors --query --workflow-id build_123 --since 2025-11-18
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
  "stack_trace": ["caller1", "caller2", "..."],
  "status": "ERROR",
  "status_updated_at": null,
  "repair_plan_path": null
}
```

### Error Status Lifecycle

Error entries track their resolution status:

| Status | Description | When Set |
|--------|-------------|----------|
| `ERROR` | New error, not yet addressed | When error is first logged |
| `FIX_PLANNED` | Repair plan created for this error | After `/repair` creates a plan |
| `RESOLVED` | Error has been fixed | After `/build` completes repair plan |

**Filter by status**:
```bash
# View new errors that need attention
/errors --query --status ERROR --limit 10

# View errors with repair plans in progress
/errors --query --status FIX_PLANNED

# View resolved errors (for verification)
/errors --query --status RESOLVED --since 24h
```

**Note**: Entries without a status field (created before this feature) default to "ERROR" when queried.

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

**2. Error Analysis (/errors)**
- Generate structured error analysis reports via errors-analyst agent (default mode)
- View and filter logged errors by time, type, command, or severity (--query mode)
- Identify error patterns with frequency statistics and grouping
- Export filtered results for further analysis or /repair workflow integration

**3. Fix Planning (/repair)**
- Group errors by pattern and root cause
- Create repair analysis reports in `specs/{NNN_topic}/reports/`
- Generate implementation plans with fix phases

**4. Fix Implementation (/build)**
- Execute repair plans with automatic testing
- Create git commits for each fix phase
- Verify fixes resolve logged errors

### Example Workflow

After a failed `/build` command execution:

```bash
# Step 1: Generate error analysis report
/errors --command /build --since 1h

# Output:
# - Report: /path/.claude/specs/887_build_error_analysis/reports/001_error_report.md
# - Total Errors Analyzed: 5
# - Most Frequent Type: state_error

# Step 2: Review report and create fix plan
cat /path/.claude/specs/887_build_error_analysis/reports/001_error_report.md
/repair --command /build --type state_error --complexity 2

# Creates:
# - specs/888_build_state_errors/reports/001_build_state_error_analysis.md
# - specs/888_build_state_errors/plans/001_build_state_error_fix_plan.md

# Step 3: Review plan and implement fixes
/build specs/888_build_state_errors/plans/001_build_state_error_fix_plan.md

# Step 4: Verify fixes resolved errors
/errors --query --command /build --since 10m

# Output: No errors found (confirmation)

# Alternative: Use report mode to verify
/errors --command /build --since 10m
# Report shows 0 errors analyzed
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
