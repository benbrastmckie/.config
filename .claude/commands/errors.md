---
allowed-tools: Task, Write, Glob, Bash, Read
description: Query error logs and generate error analysis reports via errors-analyst agent
argument-hint: [--command CMD] [--since TIME] [--type TYPE] [--status STATUS] [--limit N] [--query] [--summary]
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
- `--status STATUS` - Filter by error status (ERROR, FIX_PLANNED, RESOLVED)
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

# Filter by status (ERROR, FIX_PLANNED, RESOLVED)
/errors --query --status ERROR --limit 10
/errors --query --status FIX_PLANNED
/errors --query --status RESOLVED --command /build
```

## EXECUTE NOW: Block 1 - Setup and Mode Detection

```bash
set +H  # CRITICAL: Disable history expansion

# === PRE-TRAP ERROR BUFFER ===
# Initialize error buffer BEFORE any library sourcing
declare -a _EARLY_ERROR_BUFFER=()

# === PARSE ARGUMENTS ===
COMMAND_FILTER=""
SINCE_FILTER=""
TYPE_FILTER=""
STATUS_FILTER=""
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
    --status)
      STATUS_FILTER="$2"
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

# === SOURCE LIBRARIES (Three-Tier Pattern) ===
# Tier 1: Critical Foundation (fail-fast required)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/todo/todo-functions.sh" 2>/dev/null || {
  echo "ERROR: Failed to source todo-functions.sh" >&2
  exit 1
}

# === INITIALIZE ERROR LOGGING ===
ensure_error_log_exists

# === SETUP EARLY BASH ERROR TRAP ===
# CRITICAL FIX: Add early trap to catch errors in the 194-line gap before full trap setup
# This trap uses temporary metadata, will be replaced with actual values later
setup_bash_error_trap "/errors" "errors_early_$(date +%s)" "early_init"

# Flush any early errors captured before trap was active
_flush_early_errors

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
    [ -n "$STATUS_FILTER" ] && QUERY_ARGS="$QUERY_ARGS --status $STATUS_FILTER"
    [ -n "$WORKFLOW_FILTER" ] && QUERY_ARGS="$QUERY_ARGS --workflow-id $WORKFLOW_FILTER"
    [ -n "$LOG_FILE_ARG" ] && QUERY_ARGS="$QUERY_ARGS --log-file $LOG_FILE_ARG"
    [ -n "$LIMIT" ] && QUERY_ARGS="$QUERY_ARGS --limit $LIMIT"

    query_errors $QUERY_ARGS
  else
    # Check for filters
    if [ -n "$COMMAND_FILTER" ] || [ -n "$SINCE_FILTER" ] || [ -n "$TYPE_FILTER" ] || [ -n "$STATUS_FILTER" ] || [ -n "$WORKFLOW_FILTER" ] || [ -n "$LOG_FILE_ARG" ]; then
      # Use query_errors with filters
      QUERY_ARGS=""
      [ -n "$COMMAND_FILTER" ] && QUERY_ARGS="$QUERY_ARGS --command $COMMAND_FILTER"
      [ -n "$SINCE_FILTER" ] && QUERY_ARGS="$QUERY_ARGS --since $SINCE_FILTER"
      [ -n "$TYPE_FILTER" ] && QUERY_ARGS="$QUERY_ARGS --type $TYPE_FILTER"
      [ -n "$STATUS_FILTER" ] && QUERY_ARGS="$QUERY_ARGS --status $STATUS_FILTER"
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
            status=$(echo "$line" | jq -r '.status // "ERROR"' 2>/dev/null)
            repair_plan=$(echo "$line" | jq -r '.repair_plan_path // ""' 2>/dev/null)

            echo ""
            echo "[$timestamp] $command"
            echo "  Type: $error_type"
            echo "  Status: $status"
            echo "  Message: $message"
            echo "  Workflow: $workflow_id"
            if [ -n "$repair_plan" ] && [ "$repair_plan" != "null" ]; then
              echo "  Repair Plan: $repair_plan"
            fi
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

# === SOURCE ADDITIONAL LIBRARIES (Three-Tier Pattern) ===
# Tier 1: Critical Foundation (fail-fast required)
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" || exit 1

# Tier 2: Workflow Support (fail-fast for report mode)
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh" || exit 1
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" || exit 1

# === INITIALIZE STATE ===
COMMAND_NAME="/errors"
USER_ARGS="$(printf '%s' "$@")"
export COMMAND_NAME USER_ARGS

WORKFLOW_ID="errors_$(date +%s)"
export WORKFLOW_ID

# Setup bash error trap with actual metadata (replaces early trap)
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# Flush any errors captured during library sourcing
_flush_early_errors

# Create topic description based on filters
ERROR_DESCRIPTION="error analysis"
if [ -n "$COMMAND_FILTER" ]; then
  ERROR_DESCRIPTION="${COMMAND_FILTER} error analysis"
elif [ -n "$TYPE_FILTER" ]; then
  ERROR_DESCRIPTION="${TYPE_FILTER} error analysis"
fi

# Persist ERROR_DESCRIPTION for topic naming agent
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
TOPIC_NAMING_INPUT_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/topic_naming_input_${WORKFLOW_ID}.txt"
echo "$ERROR_DESCRIPTION" > "$TOPIC_NAMING_INPUT_FILE"
export TOPIC_NAMING_INPUT_FILE

echo "Ready for topic naming"
```

**EXECUTE NOW**: USE the Task tool to invoke the topic-naming-agent for semantic topic directory naming.

Task {
  subagent_type: "general-purpose"
  description: "Generate semantic topic directory name"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/topic-naming-agent.md

    You are generating a topic directory name for: /errors command

    **Input**:
    - User Prompt: ${ERROR_DESCRIPTION}
    - Command Name: /errors
    - OUTPUT_FILE_PATH: ${CLAUDE_PROJECT_DIR}/.claude/tmp/topic_name_${WORKFLOW_ID}.txt

    Execute topic naming according to behavioral guidelines:
    1. Generate semantic topic name from user prompt
    2. Validate format (^[a-z0-9_]{5,40}$)
    3. Write topic name to OUTPUT_FILE_PATH using Write tool
    4. Return completion signal: TOPIC_NAME_GENERATED: <generated_name>

    If you encounter an error, return:
    TASK_ERROR: <error_type> - <error_message>
  "
}

**EXECUTE NOW**: Validate agent output file and initialize workflow paths.

```bash
set +H  # CRITICAL: Disable history expansion

# === PRE-TRAP ERROR BUFFER ===
# Initialize error buffer BEFORE any library sourcing
declare -a _EARLY_ERROR_BUFFER=()

# === DEFENSIVE TRAP SETUP ===
# Set minimal trap BEFORE library sourcing to catch early errors
trap 'echo "ERROR: Block 2 initialization failed at line $LINENO: $BASH_COMMAND (exit code: $?)" >&2; exit 1' ERR
trap 'local exit_code=$?; if [ $exit_code -ne 0 ]; then echo "ERROR: Block 2 initialization exited with code $exit_code" >&2; fi' EXIT

# === RESTORE STATE FROM PREVIOUS BLOCK ===
# Detect project directory
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
export CLAUDE_PROJECT_DIR

# Source error handling library FIRST to enable validation and diagnostics
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Cannot load error-handling library" >&2
  exit 1
}

# Source remaining libraries with diagnostics
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" || exit 1

# Restore state - find most recent errors workflow state
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
WORKFLOW_ID=$(ls -t "${CLAUDE_PROJECT_DIR}/.claude/tmp/topic_naming_input_errors_"* 2>/dev/null | head -1 | sed 's/.*input_//' | sed 's/\.txt//')
if [ -z "$WORKFLOW_ID" ]; then
  # Fallback: find by topic name file
  WORKFLOW_ID=$(ls -t "${CLAUDE_PROJECT_DIR}/.claude/tmp/topic_name_errors_"* 2>/dev/null | head -1 | sed 's/.*name_//' | sed 's/\.txt//')
fi

# If still empty, use a fresh ID (shouldn't happen)
if [ -z "$WORKFLOW_ID" ]; then
  WORKFLOW_ID="errors_$(date +%s)"
fi

# Validate and correct WORKFLOW_ID if needed
WORKFLOW_ID=$(validate_workflow_id "$WORKFLOW_ID" "errors")

COMMAND_NAME="/errors"
export COMMAND_NAME WORKFLOW_ID

# Initialize error log
ensure_error_log_exists

# Setup bash error trap for automatic error logging
# Clear defensive trap before setting up full trap
_clear_defensive_trap

setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "${USER_ARGS:-}"

# Flush any early errors captured before trap was active
_flush_early_errors

# Restore ERROR_DESCRIPTION from temp file
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
TOPIC_NAMING_INPUT_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/topic_naming_input_${WORKFLOW_ID}.txt"
ERROR_DESCRIPTION=$(cat "$TOPIC_NAMING_INPUT_FILE" 2>/dev/null || echo "error analysis")

# === READ TOPIC NAME FROM AGENT OUTPUT FILE ===
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
TOPIC_NAME_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/topic_name_${WORKFLOW_ID}.txt"
TOPIC_NAME="no_name_error"
NAMING_STRATEGY="fallback"

# Check if agent wrote output file
if [ -f "$TOPIC_NAME_FILE" ]; then
  # Read topic name from file (agent writes only the name, one line)
  TOPIC_NAME=$(cat "$TOPIC_NAME_FILE" 2>/dev/null | tr -d '\n' | tr -d ' ')

  if [ -z "$TOPIC_NAME" ]; then
    # File exists but is empty - agent failed
    NAMING_STRATEGY="agent_empty_output"
    TOPIC_NAME="no_name_error"
  else
    # Validate topic name format (exit code capture pattern)
    echo "$TOPIC_NAME" | grep -Eq '^[a-z0-9_]{5,40}$'
    IS_VALID=$?
    if [ $IS_VALID -ne 0 ]; then
      # Invalid format - log and fall back
      log_command_error \
        "$COMMAND_NAME" \
        "$WORKFLOW_ID" \
        "" \
        "validation_error" \
        "Topic naming agent returned invalid format" \
        "topic_validation" \
        "$(jq -n --arg name "$TOPIC_NAME" '{invalid_name: $name}')"

      NAMING_STRATEGY="validation_failed"
      TOPIC_NAME="no_name_error"
    else
      # Valid topic name from LLM
      NAMING_STRATEGY="llm_generated"
    fi
  fi
else
  # File doesn't exist - agent failed to write
  NAMING_STRATEGY="agent_no_output_file"
fi

# Log naming failure if we fell back to no_name_error
if [ "$TOPIC_NAME" = "no_name_error" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "" \
    "agent_error" \
    "Topic naming agent failed or returned invalid name" \
    "topic_naming" \
    "$(jq -n --arg desc "$ERROR_DESCRIPTION" --arg strategy "$NAMING_STRATEGY" \
       '{description: $desc, fallback_reason: $strategy}')"
fi

# Clean up temp files
rm -f "$TOPIC_NAME_FILE" 2>/dev/null || true
rm -f "$TOPIC_NAMING_INPUT_FILE" 2>/dev/null || true

# Create classification result JSON for initialize_workflow_paths
CLASSIFICATION_JSON=$(jq -n --arg slug "$TOPIC_NAME" '{topic_directory_slug: $slug}')

# Initialize workflow paths with LLM-generated name (or fallback)
initialize_workflow_paths "$ERROR_DESCRIPTION" "research-only" "2" "$CLASSIFICATION_JSON"
INIT_EXIT=$?
if [ $INIT_EXIT -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "" \
    "file_error" \
    "Failed to initialize workflow paths" \
    "bash_block_1" \
    "$(jq -n --arg desc "$ERROR_DESCRIPTION" '{description: $desc}')"
  echo "ERROR: Failed to initialize workflow paths" >&2
  exit 1
fi

# Use exported TOPIC_PATH from initialize_workflow_paths()
# Directory creation is lazy - handled by agent using ensure_artifact_directory()
TOPIC_DIR="${TOPIC_PATH}"
REPORT_PATH="${TOPIC_DIR}/reports/001-error-report.md"

echo "Topic name: $TOPIC_NAME (strategy: $NAMING_STRATEGY)"

# Build filter arguments for agent
FILTER_ARGS=""
[ -n "$COMMAND_FILTER" ] && FILTER_ARGS="${FILTER_ARGS}--command ${COMMAND_FILTER} "
[ -n "$SINCE_FILTER" ] && FILTER_ARGS="${FILTER_ARGS}--since ${SINCE_FILTER} "
[ -n "$TYPE_FILTER" ] && FILTER_ARGS="${FILTER_ARGS}--type ${TYPE_FILTER} "
[ -n "$WORKFLOW_FILTER" ] && FILTER_ARGS="${FILTER_ARGS}--workflow-id ${WORKFLOW_FILTER} "
[ -n "$LOG_FILE_ARG" ] && FILTER_ARGS="${FILTER_ARGS}--log-file ${LOG_FILE_ARG} "

# Persist variables for Block 2
# CRITICAL: Use CLAUDE_PROJECT_DIR to match init_workflow_state() path
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/errors_state_${WORKFLOW_ID}.sh"
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

# Source barrier utilities for verification
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/barrier-utils.sh" 2>/dev/null || {
  echo "WARNING: barrier-utils.sh not found, verification will use basic checks" >&2
}

# Checkpoint reporting
echo ""
echo "[CHECKPOINT] Error analysis setup complete - ready for errors-analyst invocation"
echo "  Workflow ID: $WORKFLOW_ID"
echo "  Topic directory: $TOPIC_DIR"
echo "  Report path: $REPORT_PATH"
echo "  Filters: ${FILTER_ARGS:-none}"
echo "  State file: $STATE_FILE"
echo "  Variables persisted: ✓"
echo "  Ready for: errors-analyst invocation (Block 1b)"
echo ""
```

## Block 1b: Error Analysis Execute

**CRITICAL BARRIER**: This block MUST invoke errors-analyst via Task tool.
Verification block (Block 2) will FAIL if error report not created.

**EXECUTE NOW**: USE the Task tool to invoke the errors-analyst agent for error log analysis and report generation.

Task {
  subagent_type: "general-purpose"
  description: "Generate error analysis report"
  prompt: "
    You are the errors-analyst agent. Generate an error analysis report.

    REPORT_PATH: ${REPORT_PATH}
    FILTERS: ${FILTER_ARGS}

    Instructions:
    1. Create error analysis report at: ${REPORT_PATH}
    2. Apply filters: ${FILTER_ARGS}
    3. Read error log from: .claude/data/logs/errors.jsonl
    4. Parse JSONL format and analyze error patterns
    5. Group by error type, command, and frequency
    6. Generate structured report with metadata, executive summary, error overview, top patterns, distribution, and recommendations
    7. Return: REPORT_CREATED: [absolute_path]

    Follow your 4-step process with 28 completion criteria verification.
  "
}

## Block 2: Error Report Verification and Summary

**EXECUTE NOW**: Verify errors-analyst created error report and display summary.

```bash
set +H  # CRITICAL: Disable history expansion

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

# === SOURCE LIBRARIES (Three-Tier Pattern) ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
ensure_error_log_exists

# === RESTORE STATE ===
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
WORKFLOW_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/errors_state_*.sh"
LATEST_STATE=$(ls -t $WORKFLOW_ID_FILE 2>/dev/null | head -1)

if [ -z "$LATEST_STATE" ] || [ ! -f "$LATEST_STATE" ]; then
  echo "ERROR: State file not found" >&2
  log_command_error "verification_error" \
    "State file not found in .claude/tmp/" \
    "Expected errors_state_*.sh file"
  exit 1
fi

source "$LATEST_STATE"

# === VERIFY ERRORS-ANALYST EXECUTION ===
# This verification block ensures errors-analyst was invoked via Task
# and created the expected artifacts (error analysis report)

echo ""
echo "=== Error Report Verification ==="
echo ""

# Check if topic directory exists
if [[ ! -d "$TOPIC_DIR" ]]; then
  log_command_error "verification_error" \
    "Topic directory not found: $TOPIC_DIR" \
    "errors-analyst should have created this directory"
  echo "ERROR: VERIFICATION FAILED - Topic directory missing" >&2
  echo "DIAGNOSTIC: Expected directory: $TOPIC_DIR" >&2
  echo "RECOVERY: Check errors-analyst delegation, verify Block 1b Task invocation occurred" >&2
  exit 1
fi

# Verify report file exists
if [ ! -f "$REPORT_PATH" ]; then
  log_command_error "verification_error" \
    "Report file not created at expected path: $REPORT_PATH" \
    "errors-analyst should have created error analysis report"
  echo "ERROR: VERIFICATION FAILED - Error report not found" >&2
  echo "DIAGNOSTIC: Expected report: $REPORT_PATH" >&2
  echo "RECOVERY: Verify errors-analyst completed successfully, check for agent errors" >&2
  exit 1
fi

# Verify report file has minimum content (not empty)
REPORT_SIZE=$(stat -f%z "$REPORT_PATH" 2>/dev/null || stat -c%s "$REPORT_PATH" 2>/dev/null || echo "0")
if [[ "$REPORT_SIZE" -lt 100 ]]; then
  log_command_error "verification_error" \
    "Report file too small: $REPORT_PATH ($REPORT_SIZE bytes)" \
    "errors-analyst may have created empty or minimal report"
  echo "ERROR: VERIFICATION FAILED - Report file too small ($REPORT_SIZE bytes)" >&2
  echo "DIAGNOSTIC: Expected minimum 100 bytes, got $REPORT_SIZE bytes" >&2
  echo "RECOVERY: Re-run with higher --limit, check if error log has sufficient data" >&2
  exit 1
fi

echo ""
echo "[CHECKPOINT] Error analysis verification complete - report created"
echo "  Report created: ✓"
echo "  Report path: $REPORT_PATH"
echo "  Report size: $REPORT_SIZE bytes"
echo "  Topic directory: $TOPIC_DIR"
echo "  All verifications: ✓"
echo "  Proceeding to: Summary display"
echo ""

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
echo "Use with /repair: /repair --file $REPORT_PATH"
echo ""
echo "📋 Next Step: Run /todo to update TODO.md with this error analysis"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# === RETURN REPORT_CREATED SIGNAL ===
# Signal enables buffer-opener hook and orchestrator detection
if [ -n "$REPORT_PATH" ] && [ -f "$REPORT_PATH" ]; then
  echo ""
  echo "REPORT_CREATED: $REPORT_PATH"
  echo ""
fi

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
