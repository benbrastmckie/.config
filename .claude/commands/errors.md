---
allowed-tools: Task, Write, Glob, Bash, Read
description: Query error logs and generate error analysis reports via errors-analyst agent
argument-hint: [--command CMD] [--since TIME] [--type TYPE] [--limit N] [--query] [--summary]
command-type: utility
dependent-agents:
  - errors-analyst
library-requirements:
  - workflow-state-machine.sh: ">=2.0.0"
  - error-handling.sh: ">=1.0.0"
  - unified-location-detection.sh: ">=1.0.0"
documentation: See .claude/docs/guides/commands/errors-command-guide.md for complete usage guide
---

# /errors Command

**YOUR ROLE**: Generate error analysis reports via errors-analyst agent, or query error logs directly.

**YOU MUST** determine the operation mode based on flags provided:
- **Default Mode** (no --query flag): Generate error analysis report via errors-analyst agent
- **Query Mode** (--query flag): Display error logs directly using query functions

Generate structured error analysis reports or query error logs from centralized error logging system.

## Usage

```
/errors [options]
```

## Modes

### Default Mode (Report Generation)
When invoked without `--query` flag, generates structured error analysis report via errors-analyst agent.

### Query Mode (Legacy)
When invoked with `--query` flag, displays error logs directly (backward compatible).

## Options

- `--command CMD` - Filter by command name (e.g., /build, /plan)
- `--since TIME` - Filter errors since timestamp (ISO 8601 format, e.g., 2025-11-19)
- `--type TYPE` - Filter by error type (state_error, validation_error, agent_error, etc.)
- `--limit N` - Limit number of results (default: 10 for query mode, all for report mode)
- `--workflow-id ID` - Filter by workflow ID
- `--log-file PATH` - Log file path (default: .claude/data/logs/errors.jsonl)
- `--query` - Use query mode (legacy behavior, display errors directly)
- `--summary` - Show error summary instead of individual errors (query mode only)
- `--raw` - Output raw JSONL entries (query mode only)

## Examples

```bash
# Generate error analysis report (default mode)
/errors

# Generate report with filters
/errors --command /build --type execution_error

# Generate report for errors since yesterday
/errors --since 2025-11-20

# Query mode: Show recent errors directly
/errors --query

# Query mode: Show last 5 errors
/errors --query --limit 5

# Query mode: Filter by command
/errors --query --command /build

# Query mode: Show error summary
/errors --query --summary

# Query mode: Combine filters
/errors --query --command /build --type state_error --limit 3
```

## EXECUTE NOW: Block 1 - Setup and Mode Detection

```bash
set +H  # CRITICAL: Disable history expansion

# === PARSE ARGUMENTS ===
COMMAND_FILTER=""
SINCE_FILTER=""
TYPE_FILTER=""
WORKFLOW_FILTER=""
LOG_FILE_ARG=""
LIMIT="10"
SHOW_SUMMARY="false"
SHOW_RAW="false"
QUERY_MODE="false"

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
    --log-file)
      LOG_FILE_ARG="$2"
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
    --query)
      QUERY_MODE="true"
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# === DETECT PROJECT DIRECTORY ===
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi

if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1
fi

export CLAUDE_PROJECT_DIR

# === SOURCE LIBRARIES ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# === MODE DETECTION AND EXECUTION ===

# If --query flag is set, use legacy query mode
if [ "$QUERY_MODE" = "true" ]; then
  # === QUERY MODE (LEGACY BEHAVIOR) ===
  if [ "$SHOW_SUMMARY" = "true" ]; then
    error_summary
  elif [ "$SHOW_RAW" = "true" ]; then
    # Build query arguments
    QUERY_ARGS=""
    [ -n "$COMMAND_FILTER" ] && QUERY_ARGS="$QUERY_ARGS --command $COMMAND_FILTER"
    [ -n "$SINCE_FILTER" ] && QUERY_ARGS="$QUERY_ARGS --since $SINCE_FILTER"
    [ -n "$TYPE_FILTER" ] && QUERY_ARGS="$QUERY_ARGS --type $TYPE_FILTER"
    [ -n "$WORKFLOW_FILTER" ] && QUERY_ARGS="$QUERY_ARGS --workflow-id $WORKFLOW_FILTER"
    [ -n "$LOG_FILE_ARG" ] && QUERY_ARGS="$QUERY_ARGS --log-file $LOG_FILE_ARG"
    [ -n "$LIMIT" ] && QUERY_ARGS="$QUERY_ARGS --limit $LIMIT"

    query_errors $QUERY_ARGS
  else
    # Check for filters
    if [ -n "$COMMAND_FILTER" ] || [ -n "$SINCE_FILTER" ] || [ -n "$TYPE_FILTER" ] || [ -n "$WORKFLOW_FILTER" ] || [ -n "$LOG_FILE_ARG" ]; then
      # Use query_errors with filters
      QUERY_ARGS=""
      [ -n "$COMMAND_FILTER" ] && QUERY_ARGS="$QUERY_ARGS --command $COMMAND_FILTER"
      [ -n "$SINCE_FILTER" ] && QUERY_ARGS="$QUERY_ARGS --since $SINCE_FILTER"
      [ -n "$TYPE_FILTER" ] && QUERY_ARGS="$QUERY_ARGS --type $TYPE_FILTER"
      [ -n "$WORKFLOW_FILTER" ] && QUERY_ARGS="$QUERY_ARGS --workflow-id $WORKFLOW_FILTER"
      [ -n "$LOG_FILE_ARG" ] && QUERY_ARGS="$QUERY_ARGS --log-file $LOG_FILE_ARG"
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

  exit 0
fi

# === REPORT GENERATION MODE (DEFAULT) ===

# Source additional libraries for report generation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh" 2>/dev/null || {
  echo "ERROR: Failed to source unified-location-detection.sh" >&2
  exit 1
}

# Initialize error logging
ensure_error_log_exists

# === INITIALIZE STATE ===
COMMAND_NAME="/errors"
USER_ARGS="$(printf '%s' "$@")"
export COMMAND_NAME USER_ARGS

WORKFLOW_ID="errors_$(date +%s)"
export WORKFLOW_ID

# Setup bash error trap
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# Create topic description based on filters
ERROR_DESCRIPTION="error analysis"
if [ -n "$COMMAND_FILTER" ]; then
  ERROR_DESCRIPTION="${COMMAND_FILTER} error analysis"
elif [ -n "$TYPE_FILTER" ]; then
  ERROR_DESCRIPTION="${TYPE_FILTER} error analysis"
fi

# Get topic number and directory using LLM agent
TOPIC_NUMBER=$(get_next_topic_number)
TOPIC_NAME=$(generate_topic_name "$ERROR_DESCRIPTION")
TOPIC_DIR="${CLAUDE_PROJECT_DIR}/.claude/specs/${TOPIC_NUMBER}_${TOPIC_NAME}"

# Create topic directory structure
mkdir -p "${TOPIC_DIR}/reports" 2>/dev/null

# Determine report path
REPORT_PATH="${TOPIC_DIR}/reports/001_error_report.md"

# Build filter arguments for agent
FILTER_ARGS=""
[ -n "$COMMAND_FILTER" ] && FILTER_ARGS="${FILTER_ARGS}--command ${COMMAND_FILTER} "
[ -n "$SINCE_FILTER" ] && FILTER_ARGS="${FILTER_ARGS}--since ${SINCE_FILTER} "
[ -n "$TYPE_FILTER" ] && FILTER_ARGS="${FILTER_ARGS}--type ${TYPE_FILTER} "
[ -n "$WORKFLOW_FILTER" ] && FILTER_ARGS="${FILTER_ARGS}--workflow-id ${WORKFLOW_FILTER} "
[ -n "$LOG_FILE_ARG" ] && FILTER_ARGS="${FILTER_ARGS}--log-file ${LOG_FILE_ARG} "

# Persist variables for Block 2
STATE_FILE="${HOME}/.claude/tmp/errors_state_${WORKFLOW_ID}.sh"
mkdir -p "$(dirname "$STATE_FILE")"
cat > "$STATE_FILE" << EOF
REPORT_PATH="${REPORT_PATH}"
TOPIC_DIR="${TOPIC_DIR}"
FILTER_ARGS="${FILTER_ARGS}"
COMMAND_FILTER="${COMMAND_FILTER}"
SINCE_FILTER="${SINCE_FILTER}"
TYPE_FILTER="${TYPE_FILTER}"
WORKFLOW_ID="${WORKFLOW_ID}"
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR}"
EOF

echo "Generating error analysis report..."
```

Now invoke the errors-analyst agent using Task tool with the following prompt:

```
You are the errors-analyst agent. Generate an error analysis report.

REPORT_PATH="${REPORT_PATH}"

FILTERS="${FILTER_ARGS}"

Instructions:
1. Create error analysis report at: ${REPORT_PATH}
2. Apply filters: ${FILTER_ARGS}
3. Read error log from: .claude/data/logs/errors.jsonl
4. Parse JSONL format and analyze error patterns
5. Group by error type, command, and frequency
6. Generate structured report with metadata, executive summary, error overview, top patterns, distribution, and recommendations
7. Return: REPORT_CREATED: [absolute_path]

Follow your 4-step process with 28 completion criteria verification.
```

Wait for agent to return REPORT_CREATED signal, then proceed to Block 2.

## Block 2: Verification and Summary

**EXECUTE NOW**: After errors-analyst agent returns REPORT_CREATED signal, verify the report and display summary.

```bash
# === RESTORE STATE ===
WORKFLOW_ID_FILE="${HOME}/.claude/tmp/errors_state_*.sh"
LATEST_STATE=$(ls -t $WORKFLOW_ID_FILE 2>/dev/null | head -1)

if [ -z "$LATEST_STATE" ] || [ ! -f "$LATEST_STATE" ]; then
  echo "ERROR: State file not found" >&2
  exit 1
fi

source "$LATEST_STATE"

# === VERIFY REPORT EXISTS ===
if [ ! -f "$REPORT_PATH" ]; then
  echo "ERROR: Report file not created at expected path: $REPORT_PATH" >&2
  log_command_error \
    "/errors" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "Report file not found after agent completion" \
    "bash_block_2" \
    "$(jq -n --arg path "$REPORT_PATH" '{expected_path: $path}')"
  exit 1
fi

# Verify file size
FILE_SIZE=$(stat -c%s "$REPORT_PATH" 2>/dev/null || stat -f%z "$REPORT_PATH" 2>/dev/null)
if [ "$FILE_SIZE" -lt 500 ]; then
  echo "WARNING: Report file is suspiciously small ($FILE_SIZE bytes)" >&2
fi

# === EXTRACT SUMMARY STATISTICS ===
# Read report file and extract key statistics
TOTAL_ERRORS=$(grep -oP 'Total Errors.*?\|\s*\K\d+' "$REPORT_PATH" 2>/dev/null | head -1)
TOP_ERROR_TYPE=$(grep -oP 'Most Frequent Type.*?\|\s*\K[a-z_]+' "$REPORT_PATH" 2>/dev/null | head -1)

# === DISPLAY SUMMARY ===
echo ""
echo "Error Analysis Report Generated"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Report: $REPORT_PATH"
echo ""
if [ -n "$TOTAL_ERRORS" ]; then
  echo "Total Errors Analyzed: $TOTAL_ERRORS"
fi
if [ -n "$TOP_ERROR_TYPE" ]; then
  echo "Most Frequent Type: $TOP_ERROR_TYPE"
fi
if [ -n "$COMMAND_FILTER" ]; then
  echo "Command Filter: $COMMAND_FILTER"
fi
if [ -n "$TYPE_FILTER" ]; then
  echo "Type Filter: $TYPE_FILTER"
fi
if [ -n "$SINCE_FILTER" ]; then
  echo "Since: $SINCE_FILTER"
fi
echo ""
echo "View full report: cat $REPORT_PATH"
echo "Use with /repair: /repair --report $REPORT_PATH"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Cleanup temporary state file
rm -f "$LATEST_STATE" 2>/dev/null
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

## Log Locations

Error logs are stored in environment-specific locations:

**Production Log**:
```
.claude/data/logs/errors.jsonl
```

**Test Log**:
```
.claude/tests/logs/test-errors.jsonl
```

Log rotation occurs automatically at 10MB with 5 backup files retained for both logs. The system automatically routes errors based on execution context (test scripts in `.claude/tests/` → test log, all others → production log).
