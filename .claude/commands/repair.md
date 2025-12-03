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

## Block 1a: Initial Setup

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

# Store error filters as flat keys for state persistence
# (State persistence library rejects JSON; use individual keys instead)
ERROR_FILTER_SINCE="$ERROR_SINCE"
ERROR_FILTER_TYPE="$ERROR_TYPE"
ERROR_FILTER_COMMAND="$ERROR_COMMAND"
ERROR_FILTER_SEVERITY="$ERROR_SEVERITY"

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
source "${CLAUDE_PROJECT_DIR}/.claude/lib/todo/todo-functions.sh" 2>/dev/null || {
  echo "ERROR: Failed to source todo-functions.sh" >&2
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

# === CHECK FOR STALE STATE FILE ===
# Detect and clean terminal state from previous workflow instances
EXPECTED_STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
if [ -f "$EXPECTED_STATE_FILE" ]; then
  EXISTING_STATE=$(grep "^CURRENT_STATE=" "$EXPECTED_STATE_FILE" 2>/dev/null | tail -1 | cut -d'=' -f2- | tr -d '"' || echo "")
  if [ "$EXISTING_STATE" = "complete" ] || [ "$EXISTING_STATE" = "failed" ]; then
    echo "WARNING: Previous workflow already in terminal state ($EXISTING_STATE), reinitializing..." >&2
    rm -f "$EXPECTED_STATE_FILE"  # Clean stale state
  fi
fi

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

# === VERIFY INITIALIZATION ===
# Defensive check: Ensure CURRENT_STATE is set before attempting transition
if [ -z "${CURRENT_STATE:-}" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State machine not initialized - CURRENT_STATE unset" \
    "bash_block_1a" \
    "$(jq -n --arg state_file "${STATE_FILE:-MISSING}" '{state_file: $state_file}')"
  echo "ERROR: State machine not initialized" >&2
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

echo "Ready for topic naming"

# === GENERATE TIMESTAMP-BASED TOPIC NAME ===
# Generate timestamp-based topic name directly (bypasses topic-naming-agent)
# This ensures unique allocation for each /repair run (historical error tracking)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

if [ -n "$ERROR_COMMAND" ]; then
  # Include command context: /repair --command /build → repair_build_20251129_143022
  COMMAND_SLUG=$(echo "$ERROR_COMMAND" | sed 's:^/::' | tr '-' '_')
  TOPIC_NAME="repair_${COMMAND_SLUG}_${TIMESTAMP}"
elif [ -n "$ERROR_TYPE" ]; then
  # Include error type: /repair --type state_error → repair_state_error_20251129_143022
  ERROR_TYPE_SLUG=$(echo "$ERROR_TYPE" | tr '-' '_')
  TOPIC_NAME="repair_${ERROR_TYPE_SLUG}_${TIMESTAMP}"
else
  # Generic repair: /repair → repair_20251129_143022
  TOPIC_NAME="repair_${TIMESTAMP}"
fi

NAMING_STRATEGY="timestamp_direct"
echo "Topic name: $TOPIC_NAME (strategy: $NAMING_STRATEGY)"
```

**EXECUTE NOW**: Initialize workflow paths with timestamp-based topic name.

```bash
set +H  # CRITICAL: Disable history expansion

# Create classification result JSON for initialize_workflow_paths
CLASSIFICATION_JSON=$(jq -n --arg slug "$TOPIC_NAME" '{topic_directory_slug: $slug}')

# Initialize workflow paths with timestamp-based name
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
append_workflow_state "ERROR_FILTER_SINCE" "$ERROR_FILTER_SINCE"
append_workflow_state "ERROR_FILTER_TYPE" "$ERROR_FILTER_TYPE"
append_workflow_state "ERROR_FILTER_COMMAND" "$ERROR_FILTER_COMMAND"
append_workflow_state "ERROR_FILTER_SEVERITY" "$ERROR_FILTER_SEVERITY"
append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"
append_workflow_state "WORKFLOW_OUTPUT_FILE" "$WORKFLOW_OUTPUT_FILE"

echo "Setup complete: $WORKFLOW_ID (research-and-plan, complexity: $RESEARCH_COMPLEXITY)"
if [ -n "$WORKFLOW_OUTPUT_FILE" ]; then
  echo "Workflow output file: $WORKFLOW_OUTPUT_FILE"
fi
echo "Research directory: $RESEARCH_DIR"
echo "Plans directory: $PLANS_DIR"
echo ""
echo "[CHECKPOINT] Block 1a setup complete"
```

## Block 1b: Report Path Pre-Calculation

**EXECUTE NOW**: Pre-calculate the absolute report path before invoking repair-analyst.

This implements the **hard barrier pattern** - the report path is calculated BEFORE subagent invocation, passed as an explicit contract, and validated AFTER return.

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

# === RESTORE STATE FROM BLOCK 1A ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/repair_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)

if [ -z "$WORKFLOW_ID" ]; then
  echo "ERROR: Failed to restore WORKFLOW_ID from Block 1a" >&2
  exit 1
fi

# Restore workflow state
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE"
else
  echo "ERROR: State file not found: $STATE_FILE" >&2
  exit 1
fi

COMMAND_NAME="/repair"
USER_ARGS="${ERROR_DESCRIPTION:-}"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}

# Setup bash error trap
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# === CALCULATE REPORT PATH ===
# Validate RESEARCH_DIR is set
if [ -z "${RESEARCH_DIR:-}" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "RESEARCH_DIR not set from Block 1a" \
    "bash_block_1b" \
    "$(jq -n '{research_dir: "missing"}')"
  echo "ERROR: RESEARCH_DIR not set" >&2
  exit 1
fi

# Defensive: Ensure RESEARCH_DIR exists before find command
if [ ! -d "$RESEARCH_DIR" ]; then
  mkdir -p "$RESEARCH_DIR" || {
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "file_error" \
      "Failed to create RESEARCH_DIR" \
      "bash_block_1b" \
      "$(jq -n --arg dir "$RESEARCH_DIR" '{research_dir: $dir}')"
    echo "ERROR: Failed to create $RESEARCH_DIR" >&2
    exit 1
  }
  echo "Created research directory: $RESEARCH_DIR"
fi

# Calculate report number (001, 002, 003...)
EXISTING_REPORTS=$(find "$RESEARCH_DIR" -name '[0-9][0-9][0-9]-*.md' 2>/dev/null | wc -l | tr -d ' ' || echo "0")
REPORT_NUMBER=$(printf "%03d" $((EXISTING_REPORTS + 1)))

# Generate report slug from error description or filters (max 40 chars, kebab-case)
if [ -n "$ERROR_COMMAND" ]; then
  # Use command filter for slug: /repair --command /build → build-errors-repair
  COMMAND_SLUG=$(echo "$ERROR_COMMAND" | sed 's:^/::' | tr '_' '-')
  REPORT_SLUG="${COMMAND_SLUG}-errors-repair"
elif [ -n "$ERROR_TYPE" ]; then
  # Use type filter for slug: /repair --type state_error → state-error-repair
  TYPE_SLUG=$(echo "$ERROR_TYPE" | tr '_' '-')
  REPORT_SLUG="${TYPE_SLUG}-repair"
else
  # Generic: error-analysis
  REPORT_SLUG="error-analysis"
fi

# Truncate to 40 chars and sanitize
REPORT_SLUG=$(echo "$REPORT_SLUG" | head -c 40 | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')

# Fallback if slug is empty after sanitization
if [ -z "$REPORT_SLUG" ]; then
  REPORT_SLUG="error-analysis"
fi

# Construct absolute report path
REPORT_PATH="${RESEARCH_DIR}/${REPORT_NUMBER}-${REPORT_SLUG}.md"

# Validate path is absolute
if [[ "$REPORT_PATH" =~ ^/ ]]; then
  : # Path is absolute, continue
else
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Calculated REPORT_PATH is not absolute" \
    "bash_block_1b" \
    "$(jq -n --arg path "$REPORT_PATH" '{report_path: $path}')"
  echo "ERROR: REPORT_PATH is not absolute: $REPORT_PATH" >&2
  exit 1
fi

# Ensure parent directory exists
mkdir -p "$(dirname "$REPORT_PATH")" 2>/dev/null || true

# Persist for Block 1c validation
append_workflow_state "REPORT_PATH" "$REPORT_PATH"
append_workflow_state "REPORT_NUMBER" "$REPORT_NUMBER"
append_workflow_state "REPORT_SLUG" "$REPORT_SLUG"

echo ""
echo "=== Report Path Pre-Calculation ==="
echo "  Report Number: $REPORT_NUMBER"
echo "  Report Slug: $REPORT_SLUG"
echo "  Report Path: $REPORT_PATH"
echo ""
echo "[CHECKPOINT] Report path pre-calculated"
```

## Block 1b-exec: Repair Analysis Delegation

**HARD BARRIER - Repair Analysis Delegation**

**EXECUTE NOW**: USE the Task tool to invoke the repair-analyst agent. This invocation is MANDATORY. The orchestrator MUST NOT perform error analysis directly. After the agent returns, Block 1c will verify the report was created at the pre-calculated path.

**WARNING**: Block 1c will FAIL if report not created at pre-calculated path.

Task {
  subagent_type: "general-purpose"
  description: "Analyze error logs and create report with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/repair-analyst.md

    You are conducting error analysis for: repair workflow

    **Input Contract (Hard Barrier Pattern)**:
    - Report Path: ${REPORT_PATH}
    - Output Directory: ${RESEARCH_DIR}
    - Error Filters: ${ERROR_FILTERS}
    - Research Complexity: ${RESEARCH_COMPLEXITY}
    - Workflow Type: research-and-plan
    - Error Log Path: ${CLAUDE_PROJECT_DIR}/.claude/data/logs/errors.jsonl
    - Workflow Output File: ${WORKFLOW_OUTPUT_FILE}

    **CRITICAL**: You MUST create the report file at the EXACT path specified above.
    The orchestrator has pre-calculated this path and will validate it exists after you return.

    If WORKFLOW_OUTPUT_FILE is provided and non-empty, read and analyze it for runtime errors,
    path mismatches, state file errors, and bash execution errors in addition to the error log.

    Execute error analysis according to behavioral guidelines and return completion signal:
    REPORT_CREATED: ${REPORT_PATH}
  "
}

## Block 1c: Error Analysis Verification

**EXECUTE NOW**: Validate that repair-analyst created the report at the pre-calculated path.

This is the **hard barrier** - the workflow CANNOT proceed to Block 2a unless the report file exists. This architectural enforcement prevents the primary agent from bypassing subagent delegation.

```bash
set +H  # CRITICAL: Disable history expansion

# === PRE-TRAP ERROR BUFFER ===
declare -a _EARLY_ERROR_BUFFER=()

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

# === RESTORE STATE FROM BLOCK 1B ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/repair_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)

if [ -z "$WORKFLOW_ID" ]; then
  echo "ERROR: Failed to restore WORKFLOW_ID" >&2
  exit 1
fi

# Restore workflow state
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE"
else
  echo "ERROR: State file not found: $STATE_FILE" >&2
  exit 1
fi

COMMAND_NAME="/repair"
USER_ARGS="${ERROR_DESCRIPTION:-}"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Setup bash error trap
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

echo ""
echo "=== Agent Output Validation (Hard Barrier) ==="
echo ""

# === HARD BARRIER VALIDATION ===
# Validate REPORT_PATH is set (from Block 1b)
if [ -z "${REPORT_PATH:-}" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "REPORT_PATH not restored from Block 1b state" \
    "bash_block_1c" \
    "$(jq -n '{report_path: "missing"}')"
  echo "ERROR: REPORT_PATH not set - state restoration failed" >&2
  echo "RECOVERY: Re-run /repair with same filters" >&2
  exit 1
fi

echo "Expected report path: $REPORT_PATH"

# HARD BARRIER: Report file MUST exist
if [ ! -f "$REPORT_PATH" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "repair-analyst failed to create report file" \
    "bash_block_1c" \
    "$(jq -n --arg path "$REPORT_PATH" '{expected_path: $path}')"

  echo "ERROR: HARD BARRIER FAILED - Report file not found at: $REPORT_PATH" >&2
  echo "RECOVERY: Check repair-analyst agent output for errors" >&2
  exit 1
fi

# Validate file size (minimum 100 bytes)
REPORT_SIZE=$(wc -c < "$REPORT_PATH" 2>/dev/null || echo "0")
if [ "$REPORT_SIZE" -lt 100 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "Report file too small (< 100 bytes)" \
    "bash_block_1c" \
    "$(jq -n --arg path "$REPORT_PATH" --argjson size "$REPORT_SIZE" '{report_path: $path, file_size: $size}')"

  echo "ERROR: Report file too small: $REPORT_SIZE bytes" >&2
  echo "RECOVERY: Check repair-analyst agent for partial output" >&2
  exit 1
fi

echo "Report validated: $REPORT_SIZE bytes"
echo ""
echo "[CHECKPOINT] Agent output validated"
```

## Block 2a: Planning Setup

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
echo "[CHECKPOINT] Block 2a planning setup complete"
```

## Block 2a-standards: Extract Project Standards

**EXECUTE NOW**: Extract project standards for plan-architect agent.

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

# === RESTORE STATE FROM BLOCK 2A ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/repair_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)

if [ -z "$WORKFLOW_ID" ]; then
  echo "ERROR: Failed to restore WORKFLOW_ID from Block 2a" >&2
  exit 1
fi

# Restore workflow state
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE"
else
  echo "ERROR: State file not found: $STATE_FILE" >&2
  exit 1
fi

COMMAND_NAME="/repair"
USER_ARGS="${ERROR_DESCRIPTION:-}"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}

# Setup bash error trap
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# === EXTRACT PROJECT STANDARDS ===
# Source standards extraction library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/standards-extraction.sh" 2>/dev/null || {
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "Failed to source standards-extraction library" \
    "bash_block_2a_standards" \
    "$(jq -n --arg path "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/standards-extraction.sh" '{library_path: $path}')"
  echo "WARNING: Standards extraction unavailable, proceeding without standards" >&2
  FORMATTED_STANDARDS=""
}

# Extract and format standards for prompt injection
if [ -z "${FORMATTED_STANDARDS:-}" ]; then
  FORMATTED_STANDARDS=$(format_standards_for_prompt 2>/dev/null) || {
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "execution_error" \
      "Standards extraction failed" \
      "bash_block_2a_standards" \
      "{}"
    echo "WARNING: Standards extraction failed, proceeding without standards" >&2
    FORMATTED_STANDARDS=""
  }
fi

# Persist standards for Block 2b-exec
append_workflow_state "FORMATTED_STANDARDS<<STANDARDS_EOF
$FORMATTED_STANDARDS
STANDARDS_EOF"

if [ -n "$FORMATTED_STANDARDS" ]; then
  STANDARDS_COUNT=$(echo "$FORMATTED_STANDARDS" | grep -c "^###" || echo 0)
  echo "Extracted $STANDARDS_COUNT standards sections for plan-architect"
else
  echo "No standards extracted (graceful degradation)"
fi

echo ""
echo "[CHECKPOINT] Standards extraction complete"
```

## Block 2b: Plan Path Pre-Calculation

**EXECUTE NOW**: Pre-calculate the absolute plan path before invoking plan-architect.

This implements the **hard barrier pattern** - the plan path is calculated BEFORE subagent invocation, passed as an explicit contract, and validated AFTER return.

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

# === RESTORE STATE FROM BLOCK 2A ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/repair_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)

if [ -z "$WORKFLOW_ID" ]; then
  echo "ERROR: Failed to restore WORKFLOW_ID from Block 2a" >&2
  exit 1
fi

# Restore workflow state
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE"
else
  echo "ERROR: State file not found: $STATE_FILE" >&2
  exit 1
fi

COMMAND_NAME="/repair"
USER_ARGS="${ERROR_DESCRIPTION:-}"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}

# Setup bash error trap
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# === CALCULATE PLAN PATH ===
# Validate PLANS_DIR and TOPIC_NAME are set
if [ -z "${PLANS_DIR:-}" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "PLANS_DIR not set from Block 2a" \
    "bash_block_2b" \
    "$(jq -n '{plans_dir: "missing"}')"
  echo "ERROR: PLANS_DIR not set" >&2
  exit 1
fi

if [ -z "${TOPIC_NAME:-}" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "TOPIC_NAME not set from Block 2a" \
    "bash_block_2b" \
    "$(jq -n '{topic_name: "missing"}')"
  echo "ERROR: TOPIC_NAME not set" >&2
  exit 1
fi

# Calculate plan number (always 001 for repair)
PLAN_NUMBER="001"

# Generate plan filename from topic name (kebab-case, max 40 chars)
PLAN_FILENAME="${PLAN_NUMBER}-$(echo "$TOPIC_NAME" | tr '_' '-' | cut -c1-40)-plan.md"

# Construct absolute plan path
PLAN_PATH="${PLANS_DIR}/${PLAN_FILENAME}"

# Validate path is absolute
if [[ "$PLAN_PATH" =~ ^/ ]]; then
  : # Path is absolute, continue
else
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Calculated PLAN_PATH is not absolute" \
    "bash_block_2b" \
    "$(jq -n --arg path "$PLAN_PATH" '{plan_path: $path}')"
  echo "ERROR: PLAN_PATH is not absolute: $PLAN_PATH" >&2
  exit 1
fi

# Collect research report paths for plan creation
REPORT_PATHS=$(find "$RESEARCH_DIR" -name '*.md' -type f | sort)
# Convert to space-separated format matching /plan command
REPORT_PATHS_LIST=$(echo "$REPORT_PATHS" | tr '\n' ' ')

# Build error filters context for plan metadata
ERROR_FILTERS=""
[ -n "$ERROR_SINCE" ] && ERROR_FILTERS+="--since $ERROR_SINCE "
[ -n "$ERROR_TYPE" ] && ERROR_FILTERS+="--type $ERROR_TYPE "
[ -n "$ERROR_COMMAND" ] && ERROR_FILTERS+="--command $ERROR_COMMAND "
ERROR_FILTERS=$(echo "$ERROR_FILTERS" | sed 's/ $//')  # Trim trailing space

# Ensure parent directory exists
mkdir -p "$(dirname "$PLAN_PATH")" 2>/dev/null || true

# Persist for Block 2c validation
append_workflow_state "PLAN_PATH" "$PLAN_PATH"
append_workflow_state "PLAN_NUMBER" "$PLAN_NUMBER"
append_workflow_state "PLAN_FILENAME" "$PLAN_FILENAME"
append_workflow_state "REPORT_PATHS_LIST" "$REPORT_PATHS_LIST"
append_workflow_state "ERROR_FILTERS" "$ERROR_FILTERS"

# Persist state transitions
save_completed_states_to_state
SAVE_EXIT=$?
if [ $SAVE_EXIT -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "Failed to persist state transitions" \
    "bash_block_2b" \
    "$(jq -n --arg file "${STATE_FILE:-unknown}" '{state_file: $file}')"
  echo "ERROR: State persistence failed" >&2
  exit 1
fi

echo ""
echo "=== Plan Path Pre-Calculation ==="
echo "  Plan Number: $PLAN_NUMBER"
echo "  Plan Filename: $PLAN_FILENAME"
echo "  Plan Path: $PLAN_PATH"
echo "  Using $REPORT_COUNT research reports"
echo ""
echo "[CHECKPOINT] Plan path pre-calculated"
```

## Block 2b-exec: Plan Creation Delegation

**HARD BARRIER - Plan Creation Delegation**

**EXECUTE NOW**: USE the Task tool to invoke the plan-architect agent. This invocation is MANDATORY. The orchestrator MUST NOT create plans directly. After the agent returns, Block 2c will verify the plan was created at the pre-calculated path.

**WARNING**: Block 2c will FAIL if plan not created at pre-calculated path.

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan for ${ERROR_DESCRIPTION} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are creating an implementation plan for: repair workflow

    **Input Contract (Hard Barrier Pattern)**:
    - Plan Path: ${PLAN_PATH}
    - Feature Description: ${ERROR_DESCRIPTION}
    - Research Reports: ${REPORT_PATHS_LIST}
    - Command Context: repair
    - Workflow Type: research-and-plan
    - Operation Mode: new plan creation
    - Error Log Query: ${ERROR_FILTERS}

    **Project Standards**:
    ${FORMATTED_STANDARDS}

    **CRITICAL**: You MUST create the plan file at the EXACT path specified above.
    The orchestrator has pre-calculated this path and will validate it exists after you return.

    **REPAIR-SPECIFIC REQUIREMENT**:
    Since this is a repair plan addressing logged errors, you MUST include a final phase
    titled 'Update Error Log Status' as the last phase (after all fix phases) with:

    dependencies: [all previous phases]

    **Objective**: Update error log entries from FIX_PLANNED to RESOLVED

    Tasks:
    - [ ] Verify all fixes are working (tests pass, no new errors generated)
    - [ ] Update error log entries to RESOLVED status:
      \`\`\`bash
      source .claude/lib/core/error-handling.sh
      RESOLVED_COUNT=\$(mark_errors_resolved_for_plan \"\${PLAN_PATH}\")
      echo \"Resolved \$RESOLVED_COUNT error log entries\"
      \`\`\`
    - [ ] Verify no FIX_PLANNED errors remain for this plan:
      \`\`\`bash
      REMAINING=\$(query_errors --status FIX_PLANNED | jq -r '.repair_plan_path' | grep -c \"\$(basename \"\$(dirname \"\$(dirname \"\${PLAN_PATH}\")\")\" )\" || echo \"0\")
      [ \"\$REMAINING\" -eq 0 ] && echo \"All errors resolved\" || echo \"WARNING: \$REMAINING errors still FIX_PLANNED\"
      \`\`\`

    Execute planning according to behavioral guidelines and return completion signal:
    PLAN_CREATED: ${PLAN_PATH}
  "
}

## Block 2c: Plan Verification

**EXECUTE NOW**: Validate that plan-architect created the plan at the pre-calculated path.

This is the **hard barrier** - the workflow CANNOT proceed to Block 3 unless the plan file exists. This architectural enforcement prevents the primary agent from bypassing subagent delegation.

```bash
set +H  # CRITICAL: Disable history expansion

# === PRE-TRAP ERROR BUFFER ===
declare -a _EARLY_ERROR_BUFFER=()

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

# === RESTORE STATE FROM BLOCK 2B ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/repair_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)

if [ -z "$WORKFLOW_ID" ]; then
  echo "ERROR: Failed to restore WORKFLOW_ID" >&2
  exit 1
fi

# Restore workflow state
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE"
else
  echo "ERROR: State file not found: $STATE_FILE" >&2
  exit 1
fi

COMMAND_NAME="/repair"
USER_ARGS="${ERROR_DESCRIPTION:-}"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Setup bash error trap
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

echo ""
echo "=== Plan Verification (Hard Barrier) ==="
echo ""

# === HARD BARRIER VALIDATION ===
# Validate PLAN_PATH is set (from Block 2b)
if [ -z "${PLAN_PATH:-}" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "PLAN_PATH not restored from Block 2b state" \
    "bash_block_2c" \
    "$(jq -n '{plan_path: "missing"}')"
  echo "ERROR: PLAN_PATH not set - state restoration failed" >&2
  echo "RECOVERY: Re-run /repair with same filters" >&2
  exit 1
fi

echo "Expected plan path: $PLAN_PATH"

# HARD BARRIER: Plan file MUST exist
if [ ! -f "$PLAN_PATH" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "plan-architect failed to create plan file" \
    "bash_block_2c" \
    "$(jq -n --arg path "$PLAN_PATH" '{expected_path: $path}')"

  echo "ERROR: HARD BARRIER FAILED - Plan file not found at: $PLAN_PATH" >&2
  echo "RECOVERY: Check plan-architect agent output for errors" >&2
  exit 1
fi

# Validate file size (minimum 500 bytes)
FILE_SIZE=$(wc -c < "$PLAN_PATH" 2>/dev/null || echo "0")
if [ "$FILE_SIZE" -lt 500 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "Plan file too small (< 500 bytes)" \
    "bash_block_2c" \
    "$(jq -n --arg path "$PLAN_PATH" --argjson size "$FILE_SIZE" '{plan_path: $path, file_size: $size}')"

  echo "ERROR: Plan file too small: $FILE_SIZE bytes" >&2
  echo "RECOVERY: Check plan-architect agent for partial output" >&2
  exit 1
fi

echo "Plan validated: $FILE_SIZE bytes"
echo ""
echo "[CHECKPOINT] Plan verification complete"
```

## Block 3: Error Log Update and Completion

**EXECUTE NOW**: Update error log status and complete workflow:

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

# Load error filters from persisted flat keys (restored from state file)
# Variables restored: ERROR_FILTER_SINCE, ERROR_FILTER_TYPE, ERROR_FILTER_COMMAND, ERROR_FILTER_SEVERITY

# Build filter arguments from flat keys
FILTER_ARGS=""
[ -n "$ERROR_FILTER_COMMAND" ] && FILTER_ARGS="$FILTER_ARGS --command $ERROR_FILTER_COMMAND"
[ -n "$ERROR_FILTER_TYPE" ] && FILTER_ARGS="$FILTER_ARGS --type $ERROR_FILTER_TYPE"
[ -n "$ERROR_FILTER_SINCE" ] && FILTER_ARGS="$FILTER_ARGS --since $ERROR_FILTER_SINCE"

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
  • Implement fixes: /build $PLAN_PATH
  • Run /todo to update TODO.md (adds repair plan to tracking)"

# Print standardized summary (no phases for repair command)
print_artifact_summary "Repair" "$SUMMARY_TEXT" "" "$ARTIFACTS" "$NEXT_STEPS"

# Emit completion reminder
echo ""
echo "📋 Next Step: Run /todo to update TODO.md with this repair plan"
echo ""

# === RETURN PLAN_CREATED SIGNAL ===
# Signal enables buffer-opener hook and orchestrator detection
if [ -n "$PLAN_PATH" ] && [ -f "$PLAN_PATH" ]; then
  echo ""
  echo "PLAN_CREATED: $PLAN_PATH"
  echo ""
fi
```
