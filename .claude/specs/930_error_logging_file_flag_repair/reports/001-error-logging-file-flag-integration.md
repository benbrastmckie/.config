# Error Logging File Flag Integration Research Report

## Metadata
- **Date**: 2025-11-23
- **Agent**: research-specialist
- **Topic**: Improve error logging throughout commands to support --file flag for /repair
- **Report Type**: codebase analysis and pattern recognition
- **Complexity**: 3

## Implementation Status
- **Status**: Planning Complete
- **Plan**: [001-error-logging-file-flag-repair-plan.md](../plans/001-error-logging-file-flag-repair-plan.md)
- **Implementation**: [Will be updated by build]
- **Date**: 2025-11-23

## Executive Summary

The current `/repair` command has a `--file` flag that appends file content to the error description, but this is underutilized. The gap analysis report (002-repair-command-gap-analysis.md) identifies a critical limitation: the repair-analyst agent only reads the `errors.jsonl` log file and misses actual runtime failures visible in workflow output files. Three key improvements are recommended: (1) enhance the `--file` flag to pass workflow output files for comprehensive error analysis, (2) ensure all commands consistently capture general errors to the centralized log via bash traps, and (3) add workflow context (CLAUDE_PROJECT_DIR, HOME) to error log entries for path mismatch debugging.

## Findings

### 1. Current --file Flag Implementation

The `--file` flag is already implemented in `/repair` command (repair.md:77-97) and follows the same pattern used in `/plan`, `/debug`, and `/research` commands:

**Current Pattern** (repair.md:77-97):
```bash
# Parse --file flag for long prompts (following debug.md pattern)
ORIGINAL_PROMPT_FILE_PATH=""
if [[ "$ARGS_STRING" =~ --file[[:space:]]+([^[:space:]]+) ]]; then
  ORIGINAL_PROMPT_FILE_PATH="${BASH_REMATCH[1]}"
  # Convert to absolute path if relative
  [[ "$ORIGINAL_PROMPT_FILE_PATH" = /* ]]
  IS_ABSOLUTE_PATH=$?
  if [ $IS_ABSOLUTE_PATH -ne 0 ]; then
    ORIGINAL_PROMPT_FILE_PATH="$(pwd)/$ORIGINAL_PROMPT_FILE_PATH"
  fi
  ARGS_STRING=$(echo "$ARGS_STRING" | sed 's/--file[[:space:]]*[^[:space:]]*//' | xargs)

  # Read additional filters from file if it exists
  if [ -f "$ORIGINAL_PROMPT_FILE_PATH" ]; then
    FILE_CONTENT=$(cat "$ORIGINAL_PROMPT_FILE_PATH" 2>/dev/null || echo "")
    # Append file content to description for comprehensive analysis
    if [ -n "$FILE_CONTENT" ]; then
      ARGS_STRING="${ARGS_STRING} ${FILE_CONTENT}"
    fi
  fi
fi
```

**Limitation**: The file content is appended to `ARGS_STRING` (the error description), not passed to the repair-analyst agent as a separate workflow output file for analysis. This means the agent cannot inspect actual runtime errors from workflow execution output.

### 2. Gap Analysis Findings (from 002-repair-command-gap-analysis.md)

The gap analysis report (lines 1-247) identifies four fundamental gaps in the `/repair` command:

| Gap | Description | Impact |
|-----|-------------|--------|
| **Error Capture Gap** | repair-analyst only reads `errors.jsonl`, missing runtime errors in workflow output | Major failures invisible |
| **Context Gap** | Path mismatch bugs (HOME vs CLAUDE_PROJECT_DIR) not logged | Root cause missed |
| **Plan Targeting Gap** | Plans target logged symptoms, not actual root cause | Ineffective fixes |
| **No Validation Gap** | No reproduction of actual failure before planning | Wrong problems fixed |

**Key Example** (gap-analysis:47-58):
The PATH MISMATCH bug (`${HOME}/.claude/tmp/` vs `${CLAUDE_PROJECT_DIR}/.claude/tmp/`) only appeared in workflow debugging output, never in `errors.jsonl`. The repair plan targeted symptoms instead of the root cause.

### 3. Current Error Logging Infrastructure

The error-handling.sh library (1780 lines) provides comprehensive error logging:

**Core Functions** (error-handling.sh:410-514):
- `log_command_error()` - Main logging function accepting: command, workflow_id, user_args, error_type, message, source, context_json
- `parse_subagent_error()` - Parse TASK_ERROR signals from agents
- `query_errors()` - Filter and retrieve logged errors
- `setup_bash_error_trap()` - Register ERR/EXIT traps for automatic error capture

**JSONL Schema** (error-handling.sh:484-509):
```json
{
  "timestamp": "...",
  "environment": "production|test",
  "command": "/repair",
  "workflow_id": "...",
  "user_args": "...",
  "error_type": "state_error|validation_error|...",
  "error_message": "...",
  "source": "bash_trap|bash_block|subagent_*",
  "stack": ["..."],
  "context": {...},
  "status": "ERROR|FIX_PLANNED|RESOLVED",
  "status_updated_at": null,
  "repair_plan_path": null
}
```

**Bash Error Trap** (error-handling.sh:1548-1641):
```bash
setup_bash_error_trap() {
  local cmd_name="${1:-/unknown}"
  local workflow_id="${2:-unknown}"
  local user_args="${3:-}"

  # ERR trap: Catches command failures
  trap '_log_bash_error $? $LINENO "$BASH_COMMAND" "'"$cmd_name"'" "'"$workflow_id"'" "'"$user_args"'"' ERR

  # EXIT trap: Catches errors not caught by ERR (e.g., unbound variables)
  trap '_log_bash_exit $LINENO "$BASH_COMMAND" "'"$cmd_name"'" "'"$workflow_id"'" "'"$user_args"'"' EXIT
}
```

### 4. --file Flag Pattern Across Commands

All four commands implement `--file` identically:

| Command | Lines | Purpose |
|---------|-------|---------|
| /plan | plan.md:71-95 | Read feature description from file |
| /debug | debug.md:112-155 | Read issue description from file |
| /research | research.md:70-94 | Read workflow description from file |
| /repair | repair.md:77-97 | Read additional filters/description from file |

**Commonalities**:
1. Convert relative paths to absolute using `$(pwd)/$path`
2. Validate file exists before reading
3. Replace/append description with file content
4. Archive prompt file to `${TOPIC_PATH}/prompts/` (plan/debug/research only, not repair)

### 5. Commands With Comprehensive Error Logging

All examined commands (/plan, /debug, /research, /repair) follow the error logging integration pattern:

**Block 1 Pattern** (all commands):
```bash
# Source error handling
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Initialize error log
ensure_error_log_exists

# Set command metadata
COMMAND_NAME="/command"
USER_ARGS="$DESCRIPTION"
export COMMAND_NAME USER_ARGS

# Initialize workflow state
WORKFLOW_ID="command_$(date +%s)"
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
export WORKFLOW_ID STATE_FILE

# Setup bash error trap
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
```

**Error Types Used**:
- `state_error` - State file missing/corrupted
- `validation_error` - Invalid user input
- `agent_error` - Subagent invocation failure
- `file_error` - File I/O failure
- `parse_error` - Output parsing failure
- `execution_error` - General execution failure
- `dependency_error` - Missing dependencies

### 6. Workflow Output Analysis Gap

The gap analysis (lines 104-151) identifies that runtime errors from workflow output are **not captured** in `errors.jsonl`:

**Missing from error log**:
- Bash block stdout/stderr on failure
- Path construction errors (HOME vs CLAUDE_PROJECT_DIR)
- Agent task output errors
- State file path mismatches
- Directory creation failures

**Currently only captured**:
- Errors explicitly logged via `log_command_error()`
- Bash ERR trap errors (exit codes)
- TASK_ERROR signals from agents (if parsed)

### 7. Benign Error Filtering

The error handling library includes sophisticated filtering to avoid logging benign errors (error-handling.sh:1473-1542):

```bash
_is_benign_bash_error() {
  local failed_command="${1:-}"
  local exit_code="${2:-0}"

  # Filter bashrc sourcing failures
  case "$failed_command" in
    *"/etc/bashrc"*|*".bashrc"*)
      return 0  # Benign
      ;;
  esac

  # Filter intentional returns from core libraries
  case "$failed_command" in
    "return 1"|"return 0"|"return")
      # Check if from core library
      ...
      ;;
  esac

  return 1  # Not benign: should be logged
}
```

## Recommendations

### 1. Enhance --file Flag for Workflow Output Analysis (High Priority)

**Problem**: The `--file` flag currently appends file content to the description but doesn't pass it to repair-analyst as a separate analysis source.

**Solution**: Modify `/repair` to pass the file path to repair-analyst agent prompt context, enabling the agent to read and analyze workflow output files alongside `errors.jsonl`.

**Implementation**:
```bash
# In repair.md Block 1
if [ -n "$ORIGINAL_PROMPT_FILE_PATH" ] && [ -f "$ORIGINAL_PROMPT_FILE_PATH" ]; then
  WORKFLOW_OUTPUT_FILE="$ORIGINAL_PROMPT_FILE_PATH"
  append_workflow_state "WORKFLOW_OUTPUT_FILE" "$WORKFLOW_OUTPUT_FILE"
fi

# In repair.md Task invocation
Task {
  prompt: "
    ...
    - Workflow Output File: ${WORKFLOW_OUTPUT_FILE:-none}

    If a workflow output file is provided, read it to analyze
    runtime errors that may not be in errors.jsonl.
  "
}
```

**Expected Result**: `/repair --file .claude/research-output.md` would allow repair-analyst to analyze both logged errors AND runtime output.

### 2. Add Environment Context to Error Logs (Medium Priority)

**Problem**: Path mismatch bugs (HOME vs CLAUDE_PROJECT_DIR) are invisible in error logs.

**Solution**: Add `CLAUDE_PROJECT_DIR` and `HOME` to error context when logging state/file errors.

**Implementation** (error-handling.sh enhancement):
```bash
# In log_command_error(), enhance context for path-related errors
if [[ "$error_type" =~ ^(state_error|file_error)$ ]]; then
  context_json=$(echo "$context_json" | jq \
    --arg home "$HOME" \
    --arg proj "${CLAUDE_PROJECT_DIR:-}" \
    '. + {home: $home, claude_project_dir: $proj}')
fi
```

**Expected Result**: Error logs would include path context for debugging path mismatch issues.

### 3. Capture Workflow Output to Dedicated Files (Medium Priority)

**Problem**: Workflow runtime output (stdout/stderr) is lost after execution.

**Solution**: Workflow commands should write their output to a dedicated file in the topic directory for later analysis.

**Implementation**:
```bash
# In workflow commands (plan, research, build)
WORKFLOW_OUTPUT_FILE="${TOPIC_PATH}/outputs/workflow_output_${WORKFLOW_ID}.md"
mkdir -p "$(dirname "$WORKFLOW_OUTPUT_FILE")"

# Redirect output to file while displaying
exec > >(tee -a "$WORKFLOW_OUTPUT_FILE") 2>&1
```

**Expected Result**: Each workflow execution produces an output file that can be analyzed with `/repair --file`.

### 4. Ensure Consistent Bash Trap Setup Across All Blocks (Low Priority)

**Problem**: The `setup_bash_error_trap()` function requires COMMAND_NAME, WORKFLOW_ID, and USER_ARGS to be set before being called. Some blocks may not restore these variables before setting up traps.

**Solution**: Each bash block should verify error logging context before calling `setup_bash_error_trap()`:

```bash
# Defensive pattern for all blocks after Block 1
if [ -z "${COMMAND_NAME:-}" ]; then
  COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" | cut -d'=' -f2-)
fi
if [ -z "${USER_ARGS:-}" ]; then
  USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" | cut -d'=' -f2-)
fi
export COMMAND_NAME USER_ARGS

setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
```

**Note**: This pattern is already implemented in /repair command blocks 2 and 3. Verify all commands follow this pattern.

### 5. Document --file Usage for Workflow Output Analysis (Low Priority)

**Problem**: The documentation doesn't explain that `--file` can be used to provide workflow output for analysis.

**Solution**: Update repair-command-guide.md to explain the enhanced usage:

```markdown
#### --file PATH (Enhanced)

Provide workflow output or additional context for comprehensive error analysis.

**Primary Use Cases**:
1. **Additional context**: Long error descriptions or analysis requirements
2. **Workflow output analysis**: Pass workflow output files (e.g., research-output.md) for runtime error inspection

**Examples**:
```bash
# Provide analysis context
/repair --file ./error_details.txt

# Analyze workflow output for runtime errors
/repair --file .claude/research-output.md --type state_error
```
```

## References

### Files Analyzed

- `/home/benjamin/.config/.claude/specs/921_no_name_error/reports/002-repair-command-gap-analysis.md` (lines 1-247)
- `/home/benjamin/.config/.claude/lib/core/error-handling.sh` (lines 1-1780)
- `/home/benjamin/.config/.claude/commands/repair.md` (lines 1-1006)
- `/home/benjamin/.config/.claude/commands/plan.md` (lines 1-1137)
- `/home/benjamin/.config/.claude/commands/debug.md` (lines 1-1496)
- `/home/benjamin/.config/.claude/commands/research.md` (lines 1-709)
- `/home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md` (lines 1-780)
- `/home/benjamin/.config/.claude/docs/guides/commands/repair-command-guide.md` (lines 1-603)

### Key Code Locations

| Location | Description |
|----------|-------------|
| error-handling.sh:410-514 | `log_command_error()` implementation |
| error-handling.sh:1548-1641 | `setup_bash_error_trap()` implementation |
| error-handling.sh:1473-1542 | `_is_benign_bash_error()` filter |
| repair.md:77-97 | --file flag parsing |
| repair.md:153-161 | error-handling.sh sourcing |
| repair.md:191 | setup_bash_error_trap call |
| gap-analysis:47-58 | PATH MISMATCH bug example |
| gap-analysis:104-151 | Gap analysis detail |
