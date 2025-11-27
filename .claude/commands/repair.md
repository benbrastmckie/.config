---
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob, Write
argument-hint: [--since TIME] [--type TYPE] [--command CMD] [--severity LEVEL] [--complexity 1-4] [--file PATH]
description: Research error patterns and create implementation plan to fix them
command-type: utility
dependent-agents:
  - repair-analyst
  - plan-architect
library-requirements:
  - workflow-state-machine.sh: ">=2.0.0"
  - state-persistence.sh: ">=1.5.0"
documentation: See .claude/docs/guides/commands/repair-command-guide.md for complete usage guide
---

# /repair - Error Analysis and Repair Planning Workflow Command

YOU ARE EXECUTING an error analysis workflow that reads error logs, groups them by patterns, identifies root causes, and creates an implementation plan to fix them.

**Workflow Type**: research-and-plan
**Terminal State**: plan (after planning phase complete)
**Expected Output**: Error analysis reports + fix implementation plan in .claude/specs/NNN_topic/

## Block 1: Consolidated Setup

**EXECUTE NOW**: The user invoked `/repair` with optional filters. Parse arguments and initialize workflow.

Execute this bash block:

```bash
set +H  # CRITICAL: Disable history expansion

# === CAPTURE ERROR FILTERS ===
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
TEMP_FILE="${HOME}/.claude/tmp/repair_arg_$(date +%s%N).txt"
# SUBSTITUTE THE FULL COMMAND ARGUMENTS IN THE LINE BELOW (if user provided filters)
echo "error analysis and repair" > "$TEMP_FILE"
echo "$TEMP_FILE" > "${HOME}/.claude/tmp/repair_arg_path.txt"

# === READ AND PARSE ARGUMENTS ===
ARGS_STRING=$(cat "$TEMP_FILE" 2>/dev/null || echo "error analysis and repair")

# Parse optional flags
ERROR_SINCE=""
ERROR_TYPE=""
ERROR_COMMAND=""
ERROR_SEVERITY=""

if [[ "$ARGS_STRING" =~ --since[[:space:]]+([^[:space:]]+) ]]; then
  ERROR_SINCE="${BASH_REMATCH[1]}"
  ARGS_STRING=$(echo "$ARGS_STRING" | sed 's/--since[[:space:]]*[^[:space:]]*//' | xargs)
fi

if [[ "$ARGS_STRING" =~ --type[[:space:]]+([^[:space:]]+) ]]; then
  ERROR_TYPE="${BASH_REMATCH[1]}"
  ARGS_STRING=$(echo "$ARGS_STRING" | sed 's/--type[[:space:]]*[^[:space:]]*//' | xargs)
fi

if [[ "$ARGS_STRING" =~ --command[[:space:]]+([^[:space:]]+) ]]; then
  ERROR_COMMAND="${BASH_REMATCH[1]}"
  ARGS_STRING=$(echo "$ARGS_STRING" | sed 's/--command[[:space:]]*[^[:space:]]*//' | xargs)
fi

if [[ "$ARGS_STRING" =~ --severity[[:space:]]+([^[:space:]]+) ]]; then
  ERROR_SEVERITY="${BASH_REMATCH[1]}"
  ARGS_STRING=$(echo "$ARGS_STRING" | sed 's/--severity[[:space:]]*[^[:space:]]*//' | xargs)
fi

# Parse --complexity flag (default: 2 for error analysis)
DEFAULT_COMPLEXITY=2
RESEARCH_COMPLEXITY="$DEFAULT_COMPLEXITY"

if [[ "$ARGS_STRING" =~ --complexity[[:space:]]+([1-4]) ]]; then
  RESEARCH_COMPLEXITY="${BASH_REMATCH[1]}"
  ARGS_STRING=$(echo "$ARGS_STRING" | sed 's/--complexity[[:space:]]*[1-4]//' | xargs)
fi

# Parse --file flag for workflow output file analysis
# This passes the file path to repair-analyst for direct reading and pattern detection
WORKFLOW_OUTPUT_FILE=""
if [[ "$ARGS_STRING" =~ --file[[:space:]]+([^[:space:]]+) ]]; then
  WORKFLOW_OUTPUT_FILE="${BASH_REMATCH[1]}"
  # Convert to absolute path if relative
  [[ "$WORKFLOW_OUTPUT_FILE" = /* ]]
  IS_ABSOLUTE_PATH=$?
  if [ $IS_ABSOLUTE_PATH -ne 0 ]; then
    WORKFLOW_OUTPUT_FILE="$(pwd)/$WORKFLOW_OUTPUT_FILE"
  fi
  ARGS_STRING=$(echo "$ARGS_STRING" | sed 's/--file[[:space:]]*[^[:space:]]*//' | xargs)

  # Validate file exists (warning only, allow workflow to continue)
  if [ ! -f "$WORKFLOW_OUTPUT_FILE" ]; then
    echo "WARNING: Workflow output file not found: $WORKFLOW_OUTPUT_FILE" >&2
    WORKFLOW_OUTPUT_FILE=""
  fi
fi

echo "$RESEARCH_COMPLEXITY" | grep -Eq "^[1-4]$"
COMPLEXITY_VALID=$?
if [ $COMPLEXITY_VALID -ne 0 ]; then
  # Log via log_early_error after error-handling.sh loaded below
  echo "ERROR: Invalid research complexity: $RESEARCH_COMPLEXITY (must be 1-4)" >&2
  exit 1
fi

# Create error filters JSON
ERROR_FILTERS=$(jq -n \
  --arg since "$ERROR_SINCE" \
  --arg type "$ERROR_TYPE" \
  --arg command "$ERROR_COMMAND" \
  --arg severity "$ERROR_SEVERITY" \
  '{since: $since, type: $type, command: $command, severity: $severity}')

# Create description for workflow
ERROR_DESCRIPTION="error analysis and repair"
if [ -n "$ERROR_TYPE" ]; then
  ERROR_DESCRIPTION="$ERROR_TYPE errors repair"
elif [ -n "$ERROR_COMMAND" ]; then
  ERROR_DESCRIPTION="$ERROR_COMMAND errors repair"
fi

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
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/library-version-check.sh" 2>/dev/null || true
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh" 2>/dev/null || {
  echo "ERROR: Failed to source unified-location-detection.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-initialization.sh" >&2
  exit 1
}

# Verify library versions
check_library_requirements "$(cat <<'EOF'
workflow-state-machine.sh: ">=2.0.0"
state-persistence.sh: ">=1.5.0"
EOF
)" || exit 1

# === INITIALIZE ERROR LOGGING ===
ensure_error_log_exists

# === SETUP EARLY BASH ERROR TRAP ===
# Trap must be set BEFORE variable initialization to catch early failures
setup_bash_error_trap "/repair" "repair_early_$(date +%s)" "early_init"

# === INITIALIZE STATE ===
WORKFLOW_TYPE="research-and-plan"
TERMINAL_STATE="plan"
COMMAND_NAME="/repair"
USER_ARGS="$(printf '%s' "$@")"
export COMMAND_NAME USER_ARGS

WORKFLOW_ID="repair_$(date +%s)"
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path (matches state file location)
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/repair_state_id.txt"
mkdir -p "$(dirname "$STATE_ID_FILE")"
echo "$WORKFLOW_ID" > "$STATE_ID_FILE"
export WORKFLOW_ID

# === UPDATE BASH ERROR TRAP WITH ACTUAL VALUES ===
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# Capture state file path for append_workflow_state
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
export STATE_FILE

# Validate state file creation
if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "Failed to initialize workflow state file" \
    "bash_block_1" \
    "$(jq -n --arg path "${STATE_FILE:-UNDEFINED}" '{expected_path: $path}')"

  echo "ERROR: Failed to initialize workflow state" >&2
  exit 1
fi

sm_init "$ERROR_DESCRIPTION" "$COMMAND_NAME" "$WORKFLOW_TYPE" "$RESEARCH_COMPLEXITY" "[]" 2>&1
SM_INIT_EXIT=$?
if [ $SM_INIT_EXIT -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State machine initialization failed" \
    "bash_block_1" \
    "$(jq -n --arg type "$WORKFLOW_TYPE" --argjson complexity "$RESEARCH_COMPLEXITY" \
       '{workflow_type: $type, complexity: $complexity}')"

  echo "ERROR: State machine initialization failed" >&2
  exit 1
fi

# === TRANSITION TO RESEARCH AND SETUP PATHS ===
sm_transition "$STATE_RESEARCH" 2>&1
SM_TRANSITION_EXIT=$?
if [ $SM_TRANSITION_EXIT -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State transition to RESEARCH failed" \
    "bash_block_1" \
    "$(jq -n --arg state "$STATE_RESEARCH" '{target_state: $state}')"

  echo "ERROR: State transition to RESEARCH failed" >&2
  exit 1
fi

# Verify state was updated
if [ "$CURRENT_STATE" != "$STATE_RESEARCH" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State not updated after transition: expected $STATE_RESEARCH, got $CURRENT_STATE" \
    "bash_block_1" \
    "$(jq -n --arg expected "$STATE_RESEARCH" --arg actual "${CURRENT_STATE:-UNSET}" \
       '{expected_state: $expected, actual_state: $actual}')"

  echo "ERROR: State machine state not updated" >&2
  exit 1
fi

# Explicitly persist CURRENT_STATE (belt and suspenders)
append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"

# Persist ERROR_DESCRIPTION for topic naming agent
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
TOPIC_NAMING_INPUT_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/topic_naming_input_${WORKFLOW_ID}.txt"
echo "$ERROR_DESCRIPTION" > "$TOPIC_NAMING_INPUT_FILE"
export TOPIC_NAMING_INPUT_FILE

echo "Ready for topic naming"
```

**EXECUTE NOW**: Invoke the topic-naming-agent to generate a semantic directory name.

Task {
  subagent_type: "general-purpose"
  description: "Generate semantic topic directory name"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/topic-naming-agent.md

    You are generating a topic directory name for: /repair command

    **Input**:
    - User Prompt: ${ERROR_DESCRIPTION}
    - Command Name: /repair
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

# === DETECT PROJECT DIRECTORY FIRST (required for state file path) ===
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

# === RESTORE STATE FROM PREVIOUS BLOCK ===
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path (matches Block 1a)
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/repair_state_id.txt"
if [ ! -f "$STATE_ID_FILE" ]; then
  echo "ERROR: WORKFLOW_ID file not found" >&2
  exit 1
fi
WORKFLOW_ID=$(cat "$STATE_ID_FILE")
export WORKFLOW_ID

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Cannot load error-handling library" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || {
  echo "ERROR: Cannot load workflow-initialization library" >&2
  exit 1
}

COMMAND_NAME="/repair"
export COMMAND_NAME

# Initialize error log
ensure_error_log_exists

# Load workflow state
load_workflow_state "$WORKFLOW_ID" false

# Restore ERROR_DESCRIPTION from temp file
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
TOPIC_NAMING_INPUT_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/topic_naming_input_${WORKFLOW_ID}.txt"
ERROR_DESCRIPTION=$(cat "$TOPIC_NAMING_INPUT_FILE" 2>/dev/null || echo "error analysis and repair")

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
        "${USER_ARGS:-}" \
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
    "${USER_ARGS:-}" \
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
initialize_workflow_paths "$ERROR_DESCRIPTION" "research-and-plan" "$RESEARCH_COMPLEXITY" "$CLASSIFICATION_JSON"
INIT_EXIT=$?
if [ $INIT_EXIT -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "${USER_ARGS:-}" \
    "file_error" \
    "Failed to initialize workflow paths" \
    "bash_block_1" \
    "$(jq -n --arg desc "$ERROR_DESCRIPTION" '{description: $desc}')"

  echo "ERROR: Failed to initialize workflow paths" >&2
  exit 1
fi

SPECS_DIR="$TOPIC_PATH"
RESEARCH_DIR="${TOPIC_PATH}/reports"
PLANS_DIR="${TOPIC_PATH}/plans"

echo "Topic name: $TOPIC_NAME (strategy: $NAMING_STRATEGY)"

# === PERSIST FOR BLOCK 2 ===
append_workflow_state "COMMAND_NAME" "$COMMAND_NAME"
append_workflow_state "USER_ARGS" "$USER_ARGS"
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"
append_workflow_state "CLAUDE_PROJECT_DIR" "$CLAUDE_PROJECT_DIR"
append_workflow_state "SPECS_DIR" "$SPECS_DIR"
append_workflow_state "RESEARCH_DIR" "$RESEARCH_DIR"
append_workflow_state "PLANS_DIR" "$PLANS_DIR"
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
append_workflow_state "TOPIC_NAME" "$TOPIC_NAME"
append_workflow_state "TOPIC_NUM" "$TOPIC_NUM"
append_workflow_state "ERROR_DESCRIPTION" "$ERROR_DESCRIPTION"
append_workflow_state "ERROR_FILTERS" "$ERROR_FILTERS"
append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"
append_workflow_state "WORKFLOW_OUTPUT_FILE" "$WORKFLOW_OUTPUT_FILE"

echo "Setup complete: $WORKFLOW_ID (research-and-plan, complexity: $RESEARCH_COMPLEXITY)"
if [ -n "$WORKFLOW_OUTPUT_FILE" ]; then
  echo "Workflow output file: $WORKFLOW_OUTPUT_FILE"
fi
echo "Research directory: $RESEARCH_DIR"
echo "Plans directory: $PLANS_DIR"
```

**EXECUTE NOW**: USE the Task tool to invoke the repair-analyst agent.

Task {
  subagent_type: "general-purpose"
  description: "Analyze error logs and create report with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/repair-analyst.md

    You are conducting error analysis for: repair workflow

    **Workflow-Specific Context**:
    - Error Filters: ${ERROR_FILTERS}
    - Research Complexity: ${RESEARCH_COMPLEXITY}
    - Output Directory: ${RESEARCH_DIR}
    - Workflow Type: research-and-plan
    - Error Log Path: ${CLAUDE_PROJECT_DIR}/.claude/data/logs/errors.jsonl
    - Workflow Output File: ${WORKFLOW_OUTPUT_FILE}

    If WORKFLOW_OUTPUT_FILE is provided and non-empty, read and analyze it for runtime errors,
    path mismatches, state file errors, and bash execution errors in addition to the error log.

    Execute error analysis according to behavioral guidelines and return completion signal:
    REPORT_CREATED: [path to created report]
  "
}

## Block 2: Research Verification and Planning Setup

**EXECUTE NOW**: Verify research artifacts and prepare for planning:

```bash
set +H  # CRITICAL: Disable history expansion

# === DETECT PROJECT DIRECTORY FIRST (required for state file path) ===
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    [ -d "$current_dir/.claude" ] && { CLAUDE_PROJECT_DIR="$current_dir"; break; }
    current_dir="$(dirname "$current_dir")"
  done
fi

if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1
fi

export CLAUDE_PROJECT_DIR

# === LOAD STATE ===
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/repair_state_id.txt"
if [ ! -f "$STATE_ID_FILE" ]; then
  echo "ERROR: WORKFLOW_ID file not found" >&2
  exit 1
fi
WORKFLOW_ID=$(cat "$STATE_ID_FILE")
export WORKFLOW_ID

source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Initialize DEBUG_LOG if not already set
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
DEBUG_LOG="${DEBUG_LOG:-${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_debug.log}"
mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null

load_workflow_state "$WORKFLOW_ID" false

# === VERIFY CURRENT_STATE LOADED ===
# The state machine's CURRENT_STATE must be restored from state file
if [ -z "${CURRENT_STATE:-}" ]; then
  # Attempt to read directly from state file
  if [ -n "${STATE_FILE:-}" ] && [ -f "$STATE_FILE" ]; then
    CURRENT_STATE=$(grep "^CURRENT_STATE=" "$STATE_FILE" 2>/dev/null | tail -1 | cut -d'=' -f2- | tr -d '"' || echo "")
  fi
fi

# Final validation - if still empty, we have a persistence problem
if [ -z "${CURRENT_STATE:-}" ]; then
  log_command_error \
    "${COMMAND_NAME:-/repair}" \
    "${WORKFLOW_ID:-unknown}" \
    "${USER_ARGS:-}" \
    "state_error" \
    "CURRENT_STATE not restored from workflow state - state persistence failure" \
    "bash_block_2" \
    "$(jq -n --arg file "${STATE_FILE:-MISSING}" '{state_file: $file}')"

  echo "ERROR: State machine state not persisted from Block 1" >&2
  echo "DIAGNOSTIC: STATE_FILE=${STATE_FILE:-MISSING}" >&2
  exit 1
fi

echo "DEBUG: Current state after load: ${CURRENT_STATE:-NOT_SET}" >&2

# === RESTORE ERROR LOGGING CONTEXT ===
if [ -z "${COMMAND_NAME:-}" ]; then
  COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "/repair")
fi
if [ -z "${USER_ARGS:-}" ]; then
  USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "")
fi
if [ -z "${WORKFLOW_ID:-}" ]; then
  WORKFLOW_ID=$(grep "^WORKFLOW_ID=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "repair_$(date +%s)")
fi
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# === SETUP BASH ERROR TRAP ===
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# === VALIDATE STATE AFTER LOAD ===
if [ -z "$STATE_FILE" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State file path not set after load" \
    "bash_block_2" \
    "$(jq -n --arg workflow "$WORKFLOW_ID" '{workflow_id: $workflow}')"

  {
    echo "[$(date)] ERROR: State file path not set"
    echo "WHICH: load_workflow_state"
    echo "WHAT: STATE_FILE variable empty after load"
    echo "WHERE: Block 2, research verification"
  } >> "$DEBUG_LOG"
  echo "ERROR: State file path not set (see $DEBUG_LOG)" >&2
  exit 1
fi

if [ ! -f "$STATE_FILE" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "State file not found at expected path" \
    "bash_block_2" \
    "$(jq -n --arg path "$STATE_FILE" '{expected_path: $path}')"

  {
    echo "[$(date)] ERROR: State file not found"
    echo "WHICH: load_workflow_state"
    echo "WHAT: File does not exist at expected path"
    echo "WHERE: Block 2, research verification"
    echo "PATH: $STATE_FILE"
  } >> "$DEBUG_LOG"
  echo "ERROR: State file not found (see $DEBUG_LOG)" >&2
  exit 1
fi

# Validate critical variables from Block 1
if [ -z "${TOPIC_PATH:-}" ] || [ -z "${RESEARCH_DIR:-}" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "Critical variables not restored from state" \
    "bash_block_2" \
    "$(jq -n --arg topic "${TOPIC_PATH:-MISSING}" --arg research "${RESEARCH_DIR:-MISSING}" \
       '{topic_path: $topic, research_dir: $research}')"

  {
    echo "[$(date)] ERROR: Critical variables not restored"
    echo "WHICH: load_workflow_state"
    echo "WHAT: TOPIC_PATH or RESEARCH_DIR missing after load"
    echo "WHERE: Block 2, research verification"
    echo "TOPIC_PATH: ${TOPIC_PATH:-MISSING}"
    echo "RESEARCH_DIR: ${RESEARCH_DIR:-MISSING}"
  } >> "$DEBUG_LOG"
  echo "ERROR: Critical variables not restored (see $DEBUG_LOG)" >&2
  exit 1
fi

# === VERIFY RESEARCH ARTIFACTS ===
echo "Verifying research artifacts..."

if [ ! -d "$RESEARCH_DIR" ]; then
  echo "ERROR: Research phase failed to create reports directory" >&2
  exit 1
fi

if [ -z "$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null)" ]; then
  echo "ERROR: Research phase failed to create report files" >&2
  exit 1
fi

UNDERSIZED_FILES=$(find "$RESEARCH_DIR" -name '*.md' -type f -size -100c 2>/dev/null)
if [ -n "$UNDERSIZED_FILES" ]; then
  echo "ERROR: Research report(s) too small (< 100 bytes)" >&2
  exit 1
fi

REPORT_COUNT=$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null | wc -l)
append_workflow_state "REPORT_COUNT" "$REPORT_COUNT"

echo "Research verified: $REPORT_COUNT reports"
echo ""

# === VALIDATE STATE MACHINE BEFORE TRANSITION ===
sm_validate_state
VALIDATE_RESULT=$?
if [ $VALIDATE_RESULT -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State machine validation failed before PLAN transition" \
    "bash_block_2" \
    "$(jq -n --arg current "${CURRENT_STATE:-UNSET}" --arg state_file "${STATE_FILE:-UNSET}" \
       '{current_state: $current, state_file: $state_file}')"

  echo "ERROR: State machine not properly initialized" >&2
  exit 1
fi

# === TRANSITION TO PLAN ===
sm_transition "$STATE_PLAN" 2>&1
SM_TRANSITION_EXIT=$?
if [ $SM_TRANSITION_EXIT -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State transition to PLAN failed" \
    "bash_block_2" \
    "$(jq -n --arg state "$STATE_PLAN" '{target_state: $state}')"

  echo "ERROR: State transition to PLAN failed" >&2
  exit 1
fi

echo "=== Phase 2: Planning ==="
echo ""

# === PREPARE PLAN PATH ===
PLAN_NUMBER="001"
PLAN_FILENAME="${PLAN_NUMBER}-$(echo "$TOPIC_NAME" | tr '_' '-' | cut -c1-40)-plan.md"
PLAN_PATH="${PLANS_DIR}/${PLAN_FILENAME}"

# Collect research report paths
REPORT_PATHS=$(find "$RESEARCH_DIR" -name '*.md' -type f | sort)
REPORT_PATHS_JSON=$(echo "$REPORT_PATHS" | jq -R . | jq -s .)

# === PERSIST FOR BLOCK 3 ===
append_workflow_state "PLAN_PATH" "$PLAN_PATH"
append_workflow_state "REPORT_PATHS_JSON" "$REPORT_PATHS_JSON"

save_completed_states_to_state
SAVE_EXIT=$?
if [ $SAVE_EXIT -ne 0 ]; then
  log_command_error "state_error" "Failed to persist state transitions" "$(jq -n --arg file "${STATE_FILE:-unknown}" '{state_file: $file}')"
  echo "ERROR: State persistence failed" >&2
  exit 1
fi

if [ -n "${STATE_FILE:-}" ] && [ ! -f "$STATE_FILE" ]; then
  echo "WARNING: State file not found after save: $STATE_FILE" >&2
fi

echo "Plan will be created at: $PLAN_PATH"
echo "Using $REPORT_COUNT research reports"
```

**EXECUTE NOW**: USE the Task tool to invoke the plan-architect agent.

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan for ${ERROR_DESCRIPTION} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are creating an implementation plan for: repair workflow

    **Workflow-Specific Context**:
    - Feature Description: ${ERROR_DESCRIPTION}
    - Output Path: ${PLAN_PATH}
    - Research Reports: ${REPORT_PATHS_JSON}
    - Workflow Type: research-and-plan
    - Operation Mode: new plan creation

    Execute planning according to behavioral guidelines and return completion signal:
    PLAN_CREATED: ${PLAN_PATH}
  "
}

## Block 3: Plan Verification and Completion

**EXECUTE NOW**: Verify plan artifacts and complete workflow:

```bash
set +H  # CRITICAL: Disable history expansion

# === DETECT PROJECT DIRECTORY FIRST (required for state file path) ===
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    [ -d "$current_dir/.claude" ] && { CLAUDE_PROJECT_DIR="$current_dir"; break; }
    current_dir="$(dirname "$current_dir")"
  done
fi

if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1
fi

export CLAUDE_PROJECT_DIR

# === LOAD STATE ===
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/repair_state_id.txt"
if [ ! -f "$STATE_ID_FILE" ]; then
  echo "ERROR: WORKFLOW_ID file not found" >&2
  exit 1
fi
WORKFLOW_ID=$(cat "$STATE_ID_FILE")
export WORKFLOW_ID

source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Initialize DEBUG_LOG if not already set
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
DEBUG_LOG="${DEBUG_LOG:-${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_debug.log}"
mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null

load_workflow_state "$WORKFLOW_ID" false

# === RESTORE ERROR LOGGING CONTEXT ===
if [ -z "${COMMAND_NAME:-}" ]; then
  COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "/repair")
fi
if [ -z "${USER_ARGS:-}" ]; then
  USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "")
fi
if [ -z "${WORKFLOW_ID:-}" ]; then
  WORKFLOW_ID=$(grep "^WORKFLOW_ID=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "repair_$(date +%s)")
fi
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# === SETUP BASH ERROR TRAP ===
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# === VALIDATE STATE AFTER LOAD ===
if [ -z "$STATE_FILE" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State file path not set after load" \
    "bash_block_3" \
    "$(jq -n --arg workflow "$WORKFLOW_ID" '{workflow_id: $workflow}')"

  {
    echo "[$(date)] ERROR: State file path not set"
    echo "WHICH: load_workflow_state"
    echo "WHAT: STATE_FILE variable empty after load"
    echo "WHERE: Block 3, planning verification"
  } >> "$DEBUG_LOG"
  echo "ERROR: State file path not set (see $DEBUG_LOG)" >&2
  exit 1
fi

if [ ! -f "$STATE_FILE" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "State file not found at expected path" \
    "bash_block_3" \
    "$(jq -n --arg path "$STATE_FILE" '{expected_path: $path}')"

  {
    echo "[$(date)] ERROR: State file not found"
    echo "WHICH: load_workflow_state"
    echo "WHAT: File does not exist at expected path"
    echo "WHERE: Block 3, planning verification"
    echo "PATH: $STATE_FILE"
  } >> "$DEBUG_LOG"
  echo "ERROR: State file not found (see $DEBUG_LOG)" >&2
  exit 1
fi

# Validate PLAN_PATH was set by Block 2
if [ -z "${PLAN_PATH:-}" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "PLAN_PATH not found in state" \
    "bash_block_3" \
    "$(jq -n '{message: "PLAN_PATH not set by Block 2"}')"

  {
    echo "[$(date)] ERROR: PLAN_PATH not found in state"
    echo "WHICH: load_workflow_state"
    echo "WHAT: PLAN_PATH not set by Block 2"
    echo "WHERE: Block 3, planning verification"
    echo "State file contents:"
    cat "$STATE_FILE" 2>&1 | sed 's/^/  /'
  } >> "$DEBUG_LOG"
  echo "ERROR: PLAN_PATH not found in state (see $DEBUG_LOG)" >&2
  exit 1
fi

# === VERIFY PLAN ARTIFACTS ===
echo "Verifying plan artifacts..."

if [ ! -f "$PLAN_PATH" ]; then
  echo "ERROR: Planning phase failed to create plan file" >&2
  exit 1
fi

FILE_SIZE=$(wc -c < "$PLAN_PATH")
if [ "$FILE_SIZE" -lt 500 ]; then
  echo "ERROR: Plan file too small ($FILE_SIZE bytes)" >&2
  exit 1
fi

echo "Plan verified: $FILE_SIZE bytes"
echo ""

# === UPDATE ERROR LOG STATUS (Block 3.5) ===
echo "Updating error log entries..."

# Load error filters from persisted state
ERROR_FILTERS_JSON=$(grep "^ERROR_FILTERS=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo '{}')
if [ -z "$ERROR_FILTERS_JSON" ] || [ "$ERROR_FILTERS_JSON" = '{}' ]; then
  ERROR_FILTERS_JSON='{"since":"","type":"","command":"","severity":""}'
fi

# Build filter arguments from JSON
FILTER_ARGS=""
ERROR_COMMAND_FILTER=$(echo "$ERROR_FILTERS_JSON" | jq -r '.command // ""' 2>/dev/null || echo "")
ERROR_TYPE_FILTER=$(echo "$ERROR_FILTERS_JSON" | jq -r '.type // ""' 2>/dev/null || echo "")
ERROR_SINCE_FILTER=$(echo "$ERROR_FILTERS_JSON" | jq -r '.since // ""' 2>/dev/null || echo "")

[ -n "$ERROR_COMMAND_FILTER" ] && FILTER_ARGS="$FILTER_ARGS --command $ERROR_COMMAND_FILTER"
[ -n "$ERROR_TYPE_FILTER" ] && FILTER_ARGS="$FILTER_ARGS --type $ERROR_TYPE_FILTER"
[ -n "$ERROR_SINCE_FILTER" ] && FILTER_ARGS="$FILTER_ARGS --since $ERROR_SINCE_FILTER"

# Mark matching errors as FIX_PLANNED with plan path
ERRORS_UPDATED=$(mark_errors_fix_planned "$PLAN_PATH" $FILTER_ARGS)

echo "Updated $ERRORS_UPDATED error entries with FIX_PLANNED status"
append_workflow_state "ERRORS_UPDATED" "$ERRORS_UPDATED"

# === COMPLETE WORKFLOW ===
sm_transition "$STATE_COMPLETE" 2>&1
SM_TRANSITION_EXIT=$?
if [ $SM_TRANSITION_EXIT -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State transition to COMPLETE failed" \
    "bash_block_3" \
    "$(jq -n --arg state "$STATE_COMPLETE" '{target_state: $state}')"

  echo "ERROR: State transition to COMPLETE failed" >&2
  exit 1
fi

save_completed_states_to_state
SAVE_EXIT=$?
if [ $SAVE_EXIT -ne 0 ]; then
  log_command_error "state_error" "Failed to persist state transitions" "$(jq -n --arg file "${STATE_FILE:-unknown}" '{state_file: $file}')"
  echo "ERROR: State persistence failed" >&2
  exit 1
fi

if [ -n "${STATE_FILE:-}" ] && [ ! -f "$STATE_FILE" ]; then
  echo "WARNING: State file not found after save: $STATE_FILE" >&2
fi

# === CONSOLE SUMMARY ===
# Source summary formatting library
source "${CLAUDE_LIB}/core/summary-formatting.sh" 2>/dev/null || {
  echo "ERROR: Failed to load summary-formatting library" >&2
  exit 1
}

# Restore ERRORS_UPDATED from state (may have been persisted)
if [ -z "${ERRORS_UPDATED:-}" ]; then
  ERRORS_UPDATED=$(grep "^ERRORS_UPDATED=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "0")
fi

# Build summary text with error update count
SUMMARY_TEXT="Analyzed error patterns and created $REPORT_COUNT analysis reports with fix implementation plan. Marked $ERRORS_UPDATED error log entries as FIX_PLANNED."

# Build artifacts section
ARTIFACTS="  📊 Reports: $RESEARCH_DIR/ ($REPORT_COUNT files)
  📄 Plan: $PLAN_PATH
  📝 Errors Updated: $ERRORS_UPDATED entries marked as FIX_PLANNED"

# Build next steps
NEXT_STEPS="  • Review fix plan: cat $PLAN_PATH
  • Review error analysis: ls -lh $RESEARCH_DIR/
  • Check updated errors: /errors --status FIX_PLANNED
  • Implement fixes: /build $PLAN_PATH"

# Print standardized summary (no phases for repair command)
print_artifact_summary "Repair" "$SUMMARY_TEXT" "" "$ARTIFACTS" "$NEXT_STEPS"
```
