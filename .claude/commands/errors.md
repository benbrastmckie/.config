---
allowed-tools: Bash, Read
description: Query and display error logs from commands and subagents
argument-hint: [--command CMD] [--since TIME] [--type TYPE] [--limit N] [--summary]
---

# /errors Command

**YOUR ROLE**: Query and display error logs from the centralized error logging system.

**YOU MUST** parse the provided options and filters to query the error log database.

Query and display error logs from centralized error logging system.

## Usage

```
/errors [options]
```

## Options

- `--command CMD` - Filter by command name (e.g., /build, /plan)
- `--since TIME` - Filter errors since timestamp (ISO 8601 format, e.g., 2025-11-19)
- `--type TYPE` - Filter by error type (state_error, validation_error, agent_error, etc.)
- `--limit N` - Limit number of results (default: 10)
- `--workflow-id ID` - Filter by workflow ID
- `--summary` - Show error summary instead of individual errors
- `--raw` - Output raw JSONL entries

## Examples

```bash
# Show recent errors
/errors

# Show last 5 errors
/errors --limit 5

# Filter by command
/errors --command /build

# Show errors since date
/errors --since 2025-11-19

# Show error summary
/errors --summary

# Combine filters
/errors --command /build --type state_error --limit 3
```

## EXECUTE NOW: Implementation

```bash
# Parse arguments
COMMAND_FILTER=""
SINCE_FILTER=""
TYPE_FILTER=""
WORKFLOW_FILTER=""
LIMIT="10"
SHOW_SUMMARY="false"
SHOW_RAW="false"

while [ $# -gt 0 ]; do
  case "$1" in
    --command)
      COMMAND_FILTER="$2"
      shift 2
      ;;
    --since)
      SINCE_FILTER="$2"
      shift 2
      ;;
    --type)
      TYPE_FILTER="$2"
      shift 2
      ;;
    --limit)
      LIMIT="$2"
      shift 2
      ;;
    --workflow-id)
      WORKFLOW_FILTER="$2"
      shift 2
      ;;
    --summary)
      SHOW_SUMMARY="true"
      shift
      ;;
    --raw)
      SHOW_RAW="true"
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# Detect project directory
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi

# Source error handling library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null

# Show summary or errors
if [ "$SHOW_SUMMARY" = "true" ]; then
  error_summary
elif [ "$SHOW_RAW" = "true" ]; then
  # Build query arguments
  QUERY_ARGS=""
  [ -n "$COMMAND_FILTER" ] && QUERY_ARGS="$QUERY_ARGS --command $COMMAND_FILTER"
  [ -n "$SINCE_FILTER" ] && QUERY_ARGS="$QUERY_ARGS --since $SINCE_FILTER"
  [ -n "$TYPE_FILTER" ] && QUERY_ARGS="$QUERY_ARGS --type $TYPE_FILTER"
  [ -n "$WORKFLOW_FILTER" ] && QUERY_ARGS="$QUERY_ARGS --workflow-id $WORKFLOW_FILTER"
  [ -n "$LIMIT" ] && QUERY_ARGS="$QUERY_ARGS --limit $LIMIT"

  query_errors $QUERY_ARGS
else
  # Check for filters
  if [ -n "$COMMAND_FILTER" ] || [ -n "$SINCE_FILTER" ] || [ -n "$TYPE_FILTER" ] || [ -n "$WORKFLOW_FILTER" ]; then
    # Use query_errors with filters
    QUERY_ARGS=""
    [ -n "$COMMAND_FILTER" ] && QUERY_ARGS="$QUERY_ARGS --command $COMMAND_FILTER"
    [ -n "$SINCE_FILTER" ] && QUERY_ARGS="$QUERY_ARGS --since $SINCE_FILTER"
    [ -n "$TYPE_FILTER" ] && QUERY_ARGS="$QUERY_ARGS --type $TYPE_FILTER"
    [ -n "$WORKFLOW_FILTER" ] && QUERY_ARGS="$QUERY_ARGS --workflow-id $WORKFLOW_FILTER"
    [ -n "$LIMIT" ] && QUERY_ARGS="$QUERY_ARGS --limit $LIMIT"

    # Query and format results
    RESULTS=$(query_errors $QUERY_ARGS)

    if [ -z "$RESULTS" ]; then
      echo "No errors found matching filters."
    else
      echo "Filtered Errors:"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "$RESULTS" | while IFS= read -r line; do
        if [ -n "$line" ]; then
          timestamp=$(echo "$line" | jq -r '.timestamp // "unknown"' 2>/dev/null)
          command=$(echo "$line" | jq -r '.command // "unknown"' 2>/dev/null)
          error_type=$(echo "$line" | jq -r '.error_type // "unknown"' 2>/dev/null)
          message=$(echo "$line" | jq -r '.error_message // "No message"' 2>/dev/null)
          workflow_id=$(echo "$line" | jq -r '.workflow_id // "unknown"' 2>/dev/null)

          echo ""
          echo "[$timestamp] $command"
          echo "  Type: $error_type"
          echo "  Message: $message"
          echo "  Workflow: $workflow_id"
        fi
      done
      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    fi
  else
    # Show recent errors
    recent_errors "$LIMIT"
  fi
fi
```

## Error Types

Common error types you can filter by:

- `state_error` - Workflow state persistence issues
- `validation_error` - Input validation failures
- `agent_error` - Subagent execution failures
- `parse_error` - Output parsing failures
- `file_error` - File system operations failures
- `timeout_error` - Operation timeout errors
- `execution_error` - General execution failures

## Output Format

### Recent Errors (default)

```
Recent Errors (last 10):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[2025-11-19T14:30:00Z] /build
  Type: state_error
  Message: State file not found
  Args: plan.md 3
  Workflow: build_1732023400

[2025-11-19T14:25:00Z] /plan
  Type: validation_error
  Message: Invalid complexity value
  Args: desc --complexity 10
  Workflow: plan_1732023100

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Summary Output

```
Error Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total Errors: 42

By Command:
  /build              18
  /plan               12
  /research            8
  /debug               4

By Type:
  state_error         15
  validation_error    12
  agent_error          8
  execution_error      7

Time Range:
  First: 2025-11-15T10:00:00Z
  Last:  2025-11-19T14:30:00Z
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Log Location

Error logs are stored at:
```
.claude/data/logs/errors.jsonl
```

Log rotation occurs automatically at 10MB with 5 backup files retained.
