---
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob, Write
argument-hint: <feature-description> [--file <path>] [--complexity 1-4]
description: Research and create new implementation plan workflow
command-type: primary
dependent-agents:
  - research-coordinator
  - topic-naming-agent
  - topic-detection-agent
  - plan-architect
library-requirements:
  - workflow-state-machine.sh: ">=2.0.0"
  - state-persistence.sh: ">=1.5.0"
documentation: See .claude/docs/guides/commands/create-plan-command-guide.md for complete usage guide
---

# /create-plan - Research-and-Plan Workflow Command

YOU ARE EXECUTING a research-and-plan workflow that creates comprehensive research reports and then generates a new implementation plan based on those findings.

**Workflow Type**: research-and-plan
**Terminal State**: plan (after planning phase complete)
**Expected Output**: Research reports + implementation plan in .claude/specs/NNN_topic/

## Block 1a: Initial Setup and State Initialization

**EXECUTE NOW**: The user invoked `/create-plan "<feature-description>"`. Capture that description.

In the **bash block below**, replace `YOUR_FEATURE_DESCRIPTION_HERE` with the actual feature description (keeping the quotes).

**Example**: If user ran `/create-plan "implement user authentication with JWT tokens"`, change:
- FROM: `echo "YOUR_FEATURE_DESCRIPTION_HERE" > "$TEMP_FILE"`
- TO: `echo "implement user authentication with JWT tokens" > "$TEMP_FILE"`

Execute this bash block with your substitution:

```bash
set +H  # CRITICAL: Disable history expansion

# === CAPTURE FEATURE DESCRIPTION ===
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
TEMP_FILE="${HOME}/.claude/tmp/plan_arg_$(date +%s%N).txt"
# SUBSTITUTE THE FEATURE DESCRIPTION IN THE LINE BELOW
echo "YOUR_FEATURE_DESCRIPTION_HERE" > "$TEMP_FILE"
echo "$TEMP_FILE" > "${HOME}/.claude/tmp/plan_arg_path.txt"

# === READ AND VALIDATE ===
FEATURE_DESCRIPTION=$(cat "$TEMP_FILE" 2>/dev/null || echo "")

if [ -z "$FEATURE_DESCRIPTION" ]; then
  echo "ERROR: Feature description is empty" >&2
  echo "Usage: /create-plan \"<feature description>\"" >&2
  exit 1
fi

# Parse optional --complexity flag (default: 3 for research-and-plan)
DEFAULT_COMPLEXITY=3
RESEARCH_COMPLEXITY="$DEFAULT_COMPLEXITY"

if [[ "$FEATURE_DESCRIPTION" =~ --complexity[[:space:]]+([1-4]) ]]; then
  RESEARCH_COMPLEXITY="${BASH_REMATCH[1]}"
  FEATURE_DESCRIPTION=$(echo "$FEATURE_DESCRIPTION" | sed 's/--complexity[[:space:]]*[1-4]//' | xargs)
fi

echo "$RESEARCH_COMPLEXITY" | grep -Eq "^[1-4]$"
COMPLEXITY_VALID=$?
if [ $COMPLEXITY_VALID -ne 0 ]; then
  echo "ERROR: Invalid research complexity: $RESEARCH_COMPLEXITY (must be 1-4)" >&2
  exit 1
fi

# Parse optional --file flag for long prompts
ORIGINAL_PROMPT_FILE_PATH=""
if [[ "$FEATURE_DESCRIPTION" =~ --file[[:space:]]+([^[:space:]]+) ]]; then
  ORIGINAL_PROMPT_FILE_PATH="${BASH_REMATCH[1]}"
  # Convert to absolute path if relative (preprocessing-safe pattern)
  [[ "${ORIGINAL_PROMPT_FILE_PATH:-}" = /* ]]
  IS_ABSOLUTE_PATH=$?
  if [ $IS_ABSOLUTE_PATH -ne 0 ]; then
    ORIGINAL_PROMPT_FILE_PATH="$(pwd)/${ORIGINAL_PROMPT_FILE_PATH:-}"
  fi
  # Validate file exists
  if [ ! -f "${ORIGINAL_PROMPT_FILE_PATH:-}" ]; then
    echo "ERROR: Prompt file not found: ${ORIGINAL_PROMPT_FILE_PATH:-}" >&2
    exit 1
  fi
  # Read file content into FEATURE_DESCRIPTION
  FEATURE_DESCRIPTION=$(cat "${ORIGINAL_PROMPT_FILE_PATH:-}")
  if [ -z "$FEATURE_DESCRIPTION" ]; then
    echo "WARNING: Prompt file is empty: ${ORIGINAL_PROMPT_FILE_PATH:-}" >&2
  fi
elif [[ "$FEATURE_DESCRIPTION" =~ --file ]]; then
  echo "ERROR: --file flag requires a path argument" >&2
  echo "Usage: /create-plan --file /path/to/prompt.md" >&2
  exit 1
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

# === PRE-TRAP ERROR BUFFER ===
# Initialize error buffer BEFORE any library sourcing to capture early errors
declare -a _EARLY_ERROR_BUFFER=()

# === SOURCE LIBRARIES (Three-Tier Pattern) ===
# Tier 1: Critical Foundation (fail-fast required)
# NOTE: error-handling.sh MUST be sourced first to enable _buffer_early_error
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Now use _source_with_diagnostics for remaining libraries
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" || exit 1
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/library-version-check.sh" || exit 1

# Tier 2: Workflow Support (graceful degradation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh" 2>/dev/null || true
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || true

# Tier 3: Helper utilities (graceful degradation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/validation-utils.sh" 2>/dev/null || {
  echo "ERROR: Cannot load validation-utils.sh - required for workflow validation" >&2
  exit 1
}

# Verify library versions
check_library_requirements "$(cat <<'EOF'
workflow-state-machine.sh: ">=2.0.0"
state-persistence.sh: ">=1.5.0"
EOF
)" || exit 1

# === PRE-FLIGHT FUNCTION VALIDATION ===
# Verify required functions are available before using them (prevents exit 127 errors)
validate_library_functions "state-persistence" || exit 1
validate_library_functions "workflow-state-machine" || exit 1
validate_library_functions "error-handling" || exit 1

# === INITIALIZE ERROR LOGGING ===
ensure_error_log_exists

# === SETUP EARLY BASH ERROR TRAP ===
# Trap must be set BEFORE variable initialization to catch early failures
setup_bash_error_trap "/create-plan" "plan_early_$(date +%s)" "early_init"

# === INITIALIZE STATE ===
WORKFLOW_TYPE="research-and-plan"
TERMINAL_STATE="plan"
COMMAND_NAME="/create-plan"
USER_ARGS="$FEATURE_DESCRIPTION"
export COMMAND_NAME USER_ARGS

WORKFLOW_ID="plan_$(date +%s)"
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path (matches state file location)
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
mkdir -p "$(dirname "$STATE_ID_FILE")"
echo "$WORKFLOW_ID" > "$STATE_ID_FILE"
export WORKFLOW_ID

# === CLEANUP TERMINAL STATE FROM PREVIOUS RUNS ===
# Check if state file from previous workflow run exists in terminal state
EXISTING_STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
if [ -f "$EXISTING_STATE_FILE" ]; then
  source "$EXISTING_STATE_FILE" 2>/dev/null || true
  if [[ "${CURRENT_STATE:-}" =~ ^(complete|abandoned)$ ]]; then
    echo "Cleaning stale terminal state: $CURRENT_STATE"
    rm -f "$EXISTING_STATE_FILE"
  fi
fi

# === UPDATE BASH ERROR TRAP WITH ACTUAL VALUES ===
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# === FLUSH PRE-TRAP ERROR BUFFER ===
# Transfer any early errors buffered before trap was initialized to errors.jsonl
_flush_early_errors

# Capture state file path for append_workflow_state
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")

# CRITICAL: Export STATE_FILE immediately to make it available for append_workflow_state
# This prevents "command not found" (exit 127) errors in subsequent blocks
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

# NEW: Verify state file contains required variables
grep -q "WORKFLOW_ID=" "$STATE_FILE" 2>/dev/null
GREP_EXIT=$?
if [ $GREP_EXIT -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "State file missing WORKFLOW_ID - file creation incomplete" \
    "bash_block_1" \
    "$(jq -n --arg path "$STATE_FILE" '{state_file: $path}')"

  echo "ERROR: State file missing WORKFLOW_ID - file creation incomplete" >&2
  echo "State file: $STATE_FILE" >&2
  exit 1
fi

# NEW: Final checkpoint before Block 1 completes
echo "✓ State file validated: $STATE_FILE"

sm_init "$FEATURE_DESCRIPTION" "$COMMAND_NAME" "$WORKFLOW_TYPE" "$RESEARCH_COMPLEXITY" "[]" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
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
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State transition to RESEARCH failed" \
    "bash_block_1a" \
    "$(jq -n --arg state "$STATE_RESEARCH" '{target_state: $state}')"

  echo "ERROR: State transition to RESEARCH failed" >&2
  exit 1
fi

# Persist FEATURE_DESCRIPTION for topic naming agent
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
TOPIC_NAMING_INPUT_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/topic_naming_input_${WORKFLOW_ID}.txt"
echo "$FEATURE_DESCRIPTION" > "$TOPIC_NAMING_INPUT_FILE"
export TOPIC_NAMING_INPUT_FILE

echo "✓ Setup complete, ready for topic naming"
```

## Block 1b: Topic Name File Path Pre-Calculation

**EXECUTE NOW**: Pre-calculate the absolute topic name output file path BEFORE invoking topic-naming-agent.

This implements the **Hard Barrier Pattern** - the output path is calculated BEFORE agent invocation, passed as an explicit contract, and validated AFTER return.

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
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)

if [ -z "$WORKFLOW_ID" ]; then
  echo "ERROR: Failed to restore WORKFLOW_ID from Block 1a" >&2
  exit 1
fi

# Restore workflow state file
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE"
else
  echo "ERROR: State file not found: $STATE_FILE" >&2
  exit 1
fi

COMMAND_NAME="/create-plan"
USER_ARGS="${FEATURE_DESCRIPTION:-}"
export COMMAND_NAME USER_ARGS

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

# === PRE-FLIGHT FUNCTION VALIDATION (Block 1b) ===
# Verify required functions are available before using them (prevents exit 127 errors)
declare -f append_workflow_state >/dev/null 2>&1
FUNCTION_CHECK=$?
if [ $FUNCTION_CHECK -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "execution_error" \
    "append_workflow_state function not available - library sourcing failed" \
    "bash_block_1b" \
    "$(jq -n '{library: "state-persistence.sh", function: "append_workflow_state"}')"
  echo "ERROR: append_workflow_state function not available after sourcing state-persistence.sh" >&2
  exit 1
fi

# === PRE-CALCULATE TOPIC NAME FILE PATH ===
# CRITICAL: Calculate exact path BEFORE agent invocation (Hard Barrier Pattern)
# This path will be passed as literal text to the agent and validated after
TOPIC_NAME_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/topic_name_${WORKFLOW_ID}.txt"

# Validate path is absolute
if [[ "$TOPIC_NAME_FILE" =~ ^/ ]]; then
  : # Path is absolute, continue
else
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Calculated TOPIC_NAME_FILE is not absolute" \
    "bash_block_1b" \
    "$(jq -n --arg path "$TOPIC_NAME_FILE" '{topic_name_file: $path}')"
  echo "ERROR: TOPIC_NAME_FILE is not absolute: $TOPIC_NAME_FILE" >&2
  exit 1
fi

# Ensure parent directory exists
mkdir -p "$(dirname "$TOPIC_NAME_FILE")" 2>/dev/null || true

# === PATH MISMATCH DIAGNOSTIC ===
# Verify STATE_FILE uses CLAUDE_PROJECT_DIR (not HOME) to prevent exit 127 errors
# Skip PATH MISMATCH check when PROJECT_DIR is subdirectory of HOME (valid configuration)
if [[ "$CLAUDE_PROJECT_DIR" =~ ^${HOME}/ ]]; then
  # PROJECT_DIR legitimately under HOME - skip PATH MISMATCH validation
  :
elif [[ "$STATE_FILE" =~ ^${HOME}/ ]]; then
  # Only flag as error if PROJECT_DIR is NOT under HOME but STATE_FILE uses HOME
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "PATH MISMATCH detected: STATE_FILE uses HOME instead of CLAUDE_PROJECT_DIR" \
    "bash_block_1b" \
    "$(jq -n --arg state_file "$STATE_FILE" --arg home "$HOME" --arg project_dir "$CLAUDE_PROJECT_DIR" \
       '{state_file: $state_file, home: $home, project_dir: $project_dir, issue: "STATE_FILE must use CLAUDE_PROJECT_DIR"}')"

  echo "ERROR: PATH MISMATCH - STATE_FILE uses HOME instead of CLAUDE_PROJECT_DIR" >&2
  echo "  Current: $STATE_FILE" >&2
  echo "  Expected: ${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh" >&2
  exit 1
fi

# Persist for Block 1b-exec and Block 1c
append_workflow_state "TOPIC_NAME_FILE" "$TOPIC_NAME_FILE" || {
  echo "export TOPIC_NAME_FILE=\"$TOPIC_NAME_FILE\"" >> "$STATE_FILE"
}

echo ""
echo "=== Topic Name File Path Pre-Calculation ==="
echo "  Topic Name File: $TOPIC_NAME_FILE"
echo "  Workflow ID: $WORKFLOW_ID"
echo ""
echo "Ready for topic-naming-agent invocation"
```

## Block 1b-exec: Topic Name Generation (Hard Barrier Invocation)

**EXECUTE NOW**: USE the Task tool to invoke the topic-naming-agent for semantic topic directory naming.

You MUST use the Task tool with these EXACT parameters:
- **subagent_type**: "general-purpose"
- **description**: "Generate semantic topic directory name"
- **prompt**:
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/topic-naming-agent.md

    You are generating a topic directory name for: /create-plan command

    **Input Contract (Hard Barrier Pattern)**:
    - Output Path: ${TOPIC_NAME_FILE}
    - User Prompt: ${FEATURE_DESCRIPTION}
    - Command Name: /create-plan

    **CRITICAL**: You MUST write the topic name to the EXACT path specified above.
    The orchestrator has pre-calculated this path and will validate it exists after you return.
    Do NOT derive or calculate your own path.

    Execute topic naming according to behavioral guidelines:
    1. Generate semantic topic name from user prompt
    2. Validate format (^[a-z0-9_]{5,40}$)
    3. Write topic name to the Output Path specified above using Write tool
    4. Return completion signal: TOPIC_NAME_GENERATED: <generated_name>

    If you encounter an error, return:
    TASK_ERROR: <error_type> - <error_message>

The Task tool invocation is MANDATORY.

## Block 1c: Hard Barrier Validation

**EXECUTE NOW**: Validate that topic-naming-agent created the output file at the pre-calculated path.

This is the **hard barrier** - the workflow CANNOT proceed unless the topic name file exists. This prevents path mismatch issues.

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

# === RESTORE STATE FROM BLOCK 1B ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
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

COMMAND_NAME="/create-plan"
USER_ARGS="${FEATURE_DESCRIPTION:-}"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Source validation utilities for agent artifact validation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/validation-utils.sh" 2>/dev/null || {
  echo "ERROR: Cannot load validation-utils.sh - required for workflow validation" >&2
  exit 1
}

# Setup bash error trap
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

echo ""
echo "=== Topic Name Hard Barrier Validation ==="
echo ""

# === HARD BARRIER VALIDATION ===
# Validate TOPIC_NAME_FILE is set (from Block 1b)
if [ -z "${TOPIC_NAME_FILE:-}" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "TOPIC_NAME_FILE not restored from Block 1b state" \
    "bash_block_1c" \
    "$(jq -n '{topic_name_file: "missing"}')"
  echo "ERROR: TOPIC_NAME_FILE not set - state restoration failed" >&2
  exit 1
fi

echo "Expected topic name file: $TOPIC_NAME_FILE"

# HARD BARRIER: Validate agent artifact using validation-utils.sh
# validate_agent_artifact checks file existence and minimum size (10 bytes)
if ! validate_agent_artifact "$TOPIC_NAME_FILE" 10 "topic name"; then
  # Error already logged by validate_agent_artifact
  echo "ERROR: HARD BARRIER FAILED - Topic naming agent validation failed" >&2
  echo "" >&2
  echo "This indicates the topic-naming-agent did not create valid output." >&2
  echo "The workflow will fall back to 'no_name_error' directory." >&2
  echo "" >&2
  echo "To retry: Re-run the /create-plan command with the same arguments" >&2
  echo "" >&2

  # Unlike research reports, topic naming failure is non-fatal
  # Continue with fallback but log the error
  echo "Falling back to no_name_error directory..." >&2
else
  echo "✓ Hard barrier passed - topic name file validated"
fi

echo ""
```

## Block 1d: Topic Path Initialization

**EXECUTE NOW**: Parse topic name from agent output and initialize workflow paths.

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

# === RESTORE STATE FROM BLOCK 1C ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
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

COMMAND_NAME="/create-plan"
USER_ARGS="${FEATURE_DESCRIPTION:-}"
export COMMAND_NAME USER_ARGS

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Set workflow metadata for error logging
COMMAND_NAME="/create-plan"
USER_ARGS="${FEATURE_DESCRIPTION:-}"
export COMMAND_NAME USER_ARGS

# Initialize error log
ensure_error_log_exists

# Setup bash error trap for this validation block
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# Validate topic naming agent output with retry logic
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
TOPIC_NAME_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/topic_name_${WORKFLOW_ID}.txt"

# Use validate_agent_output_with_retry with format validator
# - 3 retries with 10-second timeout each (30 seconds total + backoff)
# - Increased from 5s to 10s to allow Haiku agent more time for completion
# - validate_topic_name_format checks content format after file creation
validate_agent_output_with_retry "topic-naming-agent" "$TOPIC_NAME_FILE" "validate_topic_name_format" 10 3
VALIDATION_RESULT=$?
if [ $VALIDATION_RESULT -ne 0 ]; then
  echo "WARNING: Topic naming agent failed to create valid output file after 3 attempts" >&2
  echo "         Falling back to 'no_name' directory structure" >&2
  echo "         Expected output: $TOPIC_NAME_FILE" >&2
  echo "         Workflow ID: $WORKFLOW_ID" >&2
  echo "         Check error log for diagnostic details: /errors --type agent_error --limit 5" >&2
fi

echo "Agent output validation complete"
```

## Block 1c: Topic Path Initialization

**EXECUTE NOW**: Parse topic name from agent output and initialize workflow paths.

```bash
set +H  # CRITICAL: Disable history expansion

# === DETECT PROJECT DIRECTORY FIRST ===
# CRITICAL: Initialize CLAUDE_PROJECT_DIR BEFORE any reference to it
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

# === RESTORE STATE FROM BLOCK 1A ===
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path (now guaranteed to be set)
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)

if [ -z "$WORKFLOW_ID" ]; then
  echo "ERROR: Failed to restore WORKFLOW_ID from Block 1a" >&2
  exit 1
fi

# Restore workflow state file (naming convention: workflow_${WORKFLOW_ID}.sh)
# CRITICAL: Use CLAUDE_PROJECT_DIR to match init_workflow_state() path
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
if [ -f "$STATE_FILE" ]; then
  set +u  # Allow unbound variables during source
  source "$STATE_FILE"
  set -u  # Re-enable strict mode
else
  echo "ERROR: State file not found: $STATE_FILE" >&2
  exit 1
fi

# === DEFENSIVE VARIABLE INITIALIZATION ===
# Initialize potentially unbound variables with defaults to prevent unbound variable errors
# These variables may not be set in state file depending on user input (e.g., --file flag not used)
ORIGINAL_PROMPT_FILE_PATH="${ORIGINAL_PROMPT_FILE_PATH:-}"
RESEARCH_COMPLEXITY="${RESEARCH_COMPLEXITY:-3}"

# FEATURE_DESCRIPTION should be in state file, but also check temp file as backup
# CRITICAL: Initialize BEFORE any reference to prevent unbound variable error with set -u
FEATURE_DESCRIPTION="${FEATURE_DESCRIPTION:-}"

# CLAUDE_PROJECT_DIR already initialized at block start, use directly
TOPIC_NAMING_INPUT_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/topic_naming_input_${WORKFLOW_ID}.txt"
if [ -z "$FEATURE_DESCRIPTION" ] && [ -f "$TOPIC_NAMING_INPUT_FILE" ]; then
  FEATURE_DESCRIPTION=$(cat "$TOPIC_NAMING_INPUT_FILE" 2>/dev/null)
fi

if [ -z "$FEATURE_DESCRIPTION" ]; then
  echo "ERROR: Failed to restore FEATURE_DESCRIPTION from Block 1a" >&2
  exit 1
fi

# CLAUDE_PROJECT_DIR already initialized at block start, set command context
COMMAND_NAME="/create-plan"
USER_ARGS="$FEATURE_DESCRIPTION"
export COMMAND_NAME USER_ARGS CLAUDE_PROJECT_DIR

# Source libraries (Three-Tier Pattern)
# Tier 1: Critical Foundation (fail-fast required)
# NOTE: error-handling.sh MUST be sourced first to enable _source_with_diagnostics
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1

# Tier 2: Workflow Support (graceful degradation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || true

# === PRE-FLIGHT FUNCTION VALIDATION ===
# Verify required functions are available before using them (prevents exit 127 errors)
declare -f append_workflow_state >/dev/null 2>&1
FUNCTION_CHECK=$?
if [ $FUNCTION_CHECK -ne 0 ]; then
  echo "ERROR: append_workflow_state function not available after sourcing state-persistence.sh" >&2
  exit 1
fi

# === SETUP BASH ERROR TRAP ===
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# === READ TOPIC NAME FROM AGENT OUTPUT FILE ===
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
TOPIC_NAME_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/topic_name_${WORKFLOW_ID}.txt"

# Improved fallback naming: timestamp + sanitized prompt prefix (max 30 chars)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SANITIZED_PROMPT=$(echo "$FEATURE_DESCRIPTION" | head -c 30 | tr -cs '[:alnum:]_' '_' | sed 's/_*$//')
TOPIC_NAME="${TIMESTAMP}_${SANITIZED_PROMPT}"
NAMING_STRATEGY="fallback"

# Check if agent wrote output file
if [ -f "$TOPIC_NAME_FILE" ]; then
  # Read topic name from file (agent writes only the name, one line)
  TOPIC_NAME=$(cat "$TOPIC_NAME_FILE" 2>/dev/null | tr -d '\n' | tr -d ' ')

  if [ -z "$TOPIC_NAME" ]; then
    # File exists but is empty - agent failed, use fallback
    NAMING_STRATEGY="agent_empty_output"
    TOPIC_NAME="${TIMESTAMP}_${SANITIZED_PROMPT}"
  else
    # Validate topic name format (exit code capture pattern)
    echo "$TOPIC_NAME" | grep -Eq '^[a-z0-9_]{5,40}$'
    IS_VALID=$?
    if [ $IS_VALID -ne 0 ]; then
      # Invalid format - log and fall back
      log_command_error \
        "$COMMAND_NAME" \
        "$WORKFLOW_ID" \
        "$USER_ARGS" \
        "validation_error" \
        "Topic naming agent returned invalid format" \
        "bash_block_1c" \
        "$(jq -n --arg name "$TOPIC_NAME" '{invalid_name: $name}')"

      NAMING_STRATEGY="validation_failed"
      TOPIC_NAME="${TIMESTAMP}_${SANITIZED_PROMPT}"
    else
      # Valid topic name from LLM
      NAMING_STRATEGY="llm_generated"
    fi
  fi
else
  # File doesn't exist - agent failed to write
  NAMING_STRATEGY="agent_no_output_file"
fi

# Log naming failure if we used fallback (not LLM-generated)
if [ "$NAMING_STRATEGY" != "llm_generated" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "Topic naming agent failed, using fallback naming: $TOPIC_NAME" \
    "bash_block_1c" \
    "$(jq -n --arg desc "$FEATURE_DESCRIPTION" --arg strategy "$NAMING_STRATEGY" --arg fallback "$TOPIC_NAME" \
       '{feature: $desc, fallback_reason: $strategy, fallback_name: $fallback}')"

  # Diagnostic output for troubleshooting
  echo "DEBUG: Topic naming agent fallback reason: $NAMING_STRATEGY (using: $TOPIC_NAME)" >&2
  echo "DEBUG: Expected file: $TOPIC_NAME_FILE" >&2
  ls -la "${CLAUDE_PROJECT_DIR}/.claude/tmp/topic_name_"* 2>/dev/null || echo "DEBUG: No topic name files found" >&2
fi

# Clean up temp file
rm -f "$TOPIC_NAME_FILE" 2>/dev/null || true

# Create classification result JSON for initialize_workflow_paths
CLASSIFICATION_JSON=$(jq -n --arg slug "$TOPIC_NAME" '{topic_directory_slug: $slug}')

# Initialize workflow paths with LLM-generated name (or fallback)
initialize_workflow_paths "$FEATURE_DESCRIPTION" "research-and-plan" "$RESEARCH_COMPLEXITY" "$CLASSIFICATION_JSON"
INIT_EXIT=$?
if [ $INIT_EXIT -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "Failed to initialize workflow paths" \
    "bash_block_1c" \
    "$(jq -n --arg desc "$FEATURE_DESCRIPTION" '{feature: $desc}')"

  echo "ERROR: Failed to initialize workflow paths" >&2
  exit 1
fi

SPECS_DIR="$TOPIC_PATH"
RESEARCH_DIR="${TOPIC_PATH}/reports"
PLANS_DIR="${TOPIC_PATH}/plans"

# === ARCHIVE PROMPT FILE (if --file was used) ===
ARCHIVED_PROMPT_PATH=""
if [ -n "${ORIGINAL_PROMPT_FILE_PATH:-}" ] && [ -f "${ORIGINAL_PROMPT_FILE_PATH:-}" ]; then
  mkdir -p "${TOPIC_PATH}/prompts"
  ARCHIVED_PROMPT_PATH="${TOPIC_PATH}/prompts/$(basename "${ORIGINAL_PROMPT_FILE_PATH:-}")"
  mv "${ORIGINAL_PROMPT_FILE_PATH:-}" "$ARCHIVED_PROMPT_PATH"
  echo "Prompt file archived: $ARCHIVED_PROMPT_PATH"
fi

# === PERSIST FOR BLOCK 2 (BULK OPERATION) ===
# Use bulk append to reduce I/O overhead from 14 writes to 1 write
append_workflow_state_bulk <<EOF
COMMAND_NAME=$COMMAND_NAME
USER_ARGS=$USER_ARGS
WORKFLOW_ID=$WORKFLOW_ID
CLAUDE_PROJECT_DIR=$CLAUDE_PROJECT_DIR
SPECS_DIR=$SPECS_DIR
RESEARCH_DIR=$RESEARCH_DIR
PLANS_DIR=$PLANS_DIR
TOPIC_PATH=$TOPIC_PATH
TOPIC_NAME=$TOPIC_NAME
TOPIC_NUM=$TOPIC_NUM
FEATURE_DESCRIPTION=$FEATURE_DESCRIPTION
RESEARCH_COMPLEXITY=$RESEARCH_COMPLEXITY
ORIGINAL_PROMPT_FILE_PATH=${ORIGINAL_PROMPT_FILE_PATH:-}
ARCHIVED_PROMPT_PATH=${ARCHIVED_PROMPT_PATH:-}
EOF

echo "Setup complete: $WORKFLOW_ID (research-and-plan, complexity: $RESEARCH_COMPLEXITY)"
echo "Research directory: $RESEARCH_DIR"
echo "Plans directory: $PLANS_DIR"
echo "Topic name: $TOPIC_NAME (strategy: $NAMING_STRATEGY)"
```

## Block 1d-topics-auto: Topic Detection Agent Invocation (Optional)

**EXECUTE NOW**: If RESEARCH_COMPLEXITY >= 3, optionally invoke topic-detection-agent for automated semantic decomposition.

**Condition**: This block should ONLY be executed when:
- RESEARCH_COMPLEXITY >= 3 (multi-topic threshold)
- User wants automated topic detection (default behavior for complexity >= 3)

If RESEARCH_COMPLEXITY < 3, SKIP this block and proceed directly to Block 1d-topics.

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

# === RESTORE STATE FROM BLOCK 1C ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
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

COMMAND_NAME="/create-plan"
USER_ARGS="${FEATURE_DESCRIPTION:-}"
export COMMAND_NAME USER_ARGS

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

# === PRE-FLIGHT FUNCTION VALIDATION (Block 1d-topics-auto) ===
# Verify required functions are available before using them (prevents exit 127 errors)
declare -f append_workflow_state >/dev/null 2>&1
FUNCTION_CHECK=$?
if [ $FUNCTION_CHECK -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "execution_error" \
    "append_workflow_state function not available - library sourcing failed" \
    "bash_block_1d_topics_auto" \
    "$(jq -n '{library: "state-persistence.sh", function: "append_workflow_state"}')"
  echo "ERROR: append_workflow_state function not available after sourcing state-persistence.sh" >&2
  exit 1
fi

echo ""
echo "=== Topic Detection Agent (Optional) ==="
echo ""

# === CHECK COMPLEXITY THRESHOLD ===
if [ "${RESEARCH_COMPLEXITY:-3}" -lt 3 ]; then
  echo "Complexity ${RESEARCH_COMPLEXITY} < 3: Skipping automated topic detection"
  echo "Using heuristic decomposition in Block 1d-topics"
  echo ""

  # Signal that topic detection was skipped
  append_workflow_state "TOPIC_DETECTION_SKIPPED" "true"

  # Exit this block, proceed to Block 1d-topics
  exit 0
fi

echo "Complexity ${RESEARCH_COMPLEXITY} >= 3: Running automated topic detection"

# === PRE-CALCULATE TOPIC DETECTION OUTPUT PATH ===
# CRITICAL: Calculate path BEFORE agent invocation (Hard Barrier Pattern)
TOPICS_JSON_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/topics_${WORKFLOW_ID}.json"

# Ensure parent directory exists
mkdir -p "$(dirname "$TOPICS_JSON_FILE")" 2>/dev/null || true

# Persist for validation block
append_workflow_state "TOPICS_JSON_FILE" "$TOPICS_JSON_FILE"

echo "Topic detection output: $TOPICS_JSON_FILE"
echo ""
echo "CHECKPOINT: Ready for topic-detection-agent invocation"
```

## Block 1d-topics-auto-exec: Topic Detection Agent Task Invocation

**EXECUTE NOW**: USE the Task tool to invoke the topic-detection-agent for automated semantic decomposition.

**Condition**: Only execute if RESEARCH_COMPLEXITY >= 3 (check Block 1d-topics-auto outcome).

You MUST use the Task tool with these EXACT parameters:
- **subagent_type**: "general-purpose"
- **description**: "Detect research topics for ${FEATURE_DESCRIPTION}"
- **prompt**:
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/topic-detection-agent.md

    You are analyzing a feature description for topic decomposition in: /create-plan workflow

    **Input Contract (Hard Barrier Pattern)**:
    - FEATURE_DESCRIPTION: "${FEATURE_DESCRIPTION}"
    - COMPLEXITY: ${RESEARCH_COMPLEXITY}
    - OUTPUT_PATH: ${TOPICS_JSON_FILE}

    **CRITICAL**: You MUST write the topic detection JSON to the EXACT path specified above.
    The orchestrator has pre-calculated this path and will validate it exists after you return.
    Do NOT derive or calculate your own path.

    Execute topic detection according to behavioral guidelines:
    1. Analyze FEATURE_DESCRIPTION for distinct research themes
    2. Determine topic count based on COMPLEXITY (1-5 topics)
    3. Generate topic definitions with title, scope, and slug
    4. Validate topics or apply fallback if decomposition unclear
    5. Write JSON output to OUTPUT_PATH using Write tool
    6. Return completion signal: TOPIC_DETECTION_COMPLETE: <topic_count>

    If you encounter an error, return:
    TASK_ERROR: <error_type> - <error_message>

The Task tool invocation is MANDATORY.

## Block 1d-topics-auto-validate: Topic Detection Output Validation

**EXECUTE NOW**: Validate that topic-detection-agent created valid JSON output at the pre-calculated path.

This is the **hard barrier** - if the JSON file doesn't exist or is invalid, fall back to heuristic decomposition in Block 1d-topics.

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

# === RESTORE STATE FROM BLOCK 1D-TOPICS-AUTO ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
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

COMMAND_NAME="/create-plan"
USER_ARGS="${FEATURE_DESCRIPTION:-}"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Cannot load state-persistence library" >&2
  exit 1
}

source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/validation-utils.sh" 2>/dev/null || {
  echo "ERROR: Cannot load validation-utils.sh - required for workflow validation" >&2
  exit 1
}

# Setup bash error trap
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# === PRE-FLIGHT FUNCTION VALIDATION (Block 1d-topics-auto-validate) ===
# Verify required functions are available before using them (prevents exit 127 errors)
declare -f append_workflow_state >/dev/null 2>&1
FUNCTION_CHECK=$?
if [ $FUNCTION_CHECK -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "execution_error" \
    "append_workflow_state function not available - library sourcing failed" \
    "bash_block_1d_topics_auto_validate" \
    "$(jq -n '{library: "state-persistence.sh", function: "append_workflow_state"}')"
  echo "ERROR: append_workflow_state function not available after sourcing state-persistence.sh" >&2
  exit 1
fi

echo ""
echo "=== Topic Detection Output Validation ==="
echo ""

# === CHECK IF TOPIC DETECTION WAS SKIPPED ===
if [ "${TOPIC_DETECTION_SKIPPED:-false}" = "true" ]; then
  echo "Topic detection was skipped (complexity < 3)"
  echo "Proceeding to heuristic decomposition in Block 1d-topics"
  echo ""
  exit 0
fi

# === HARD BARRIER VALIDATION ===
# Validate TOPICS_JSON_FILE is set (from Block 1d-topics-auto)
if [ -z "${TOPICS_JSON_FILE:-}" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "TOPICS_JSON_FILE not restored from Block 1d-topics-auto state" \
    "bash_block_1d_topics_auto_validate" \
    "$(jq -n '{topics_json_file: "missing"}')"
  echo "ERROR: TOPICS_JSON_FILE not set - state restoration failed" >&2
  echo "Falling back to heuristic decomposition" >&2
  append_workflow_state "TOPIC_DETECTION_FAILED" "true"
  exit 0  # Non-fatal, proceed to Block 1d-topics with fallback
fi

echo "Expected topics JSON file: $TOPICS_JSON_FILE"

# HARD BARRIER: Validate agent artifact using validation-utils.sh
# validate_agent_artifact checks file existence and minimum size (50 bytes for JSON)
if ! validate_agent_artifact "$TOPICS_JSON_FILE" 50 "topics JSON"; then
  # Error already logged by validate_agent_artifact
  echo "WARNING: HARD BARRIER FAILED - Topic detection agent validation failed" >&2
  echo "" >&2
  echo "This indicates the topic-detection-agent did not create valid output." >&2
  echo "Falling back to heuristic decomposition in Block 1d-topics" >&2
  echo "" >&2

  # Mark fallback for Block 1d-topics
  append_workflow_state "TOPIC_DETECTION_FAILED" "true"
  exit 0  # Non-fatal, proceed to Block 1d-topics
fi

# Validate JSON format
if ! jq empty "$TOPICS_JSON_FILE" 2>/dev/null; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "parse_error" \
    "Topic detection agent returned invalid JSON" \
    "bash_block_1d_topics_auto_validate" \
    "$(jq -n --arg path "$TOPICS_JSON_FILE" '{json_file: $path}')"

  echo "WARNING: Invalid JSON format in topics file" >&2
  echo "Falling back to heuristic decomposition" >&2
  append_workflow_state "TOPIC_DETECTION_FAILED" "true"
  exit 0  # Non-fatal, proceed to Block 1d-topics
fi

# Validate required JSON fields
if ! jq -e '.topics | length > 0' "$TOPICS_JSON_FILE" >/dev/null 2>&1; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Topics JSON missing required 'topics' array or array is empty" \
    "bash_block_1d_topics_auto_validate" \
    "$(jq -n --arg path "$TOPICS_JSON_FILE" '{json_file: $path}')"

  echo "WARNING: Topics array missing or empty in JSON" >&2
  echo "Falling back to heuristic decomposition" >&2
  append_workflow_state "TOPIC_DETECTION_FAILED" "true"
  exit 0  # Non-fatal, proceed to Block 1d-topics
fi

echo "✓ Hard barrier passed - topics JSON file validated"

# Mark success for Block 1d-topics to use
append_workflow_state "TOPIC_DETECTION_SUCCESS" "true"

echo ""
echo "CHECKPOINT: Topic detection complete, ready for Block 1d-topics parsing"
```

## Block 1d-topics: Topic Decomposition

**EXECUTE NOW**: Parse topics from topic-detection-agent JSON (if available) or use heuristic decomposition, then prepare topic array for research coordinator.

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

# === RESTORE STATE FROM BLOCK 1D-TOPICS-AUTO-VALIDATE ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
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

COMMAND_NAME="/create-plan"
USER_ARGS="${FEATURE_DESCRIPTION:-}"
export COMMAND_NAME USER_ARGS

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

# === PRE-FLIGHT FUNCTION VALIDATION (Block 1d-topics) ===
# Verify required functions are available before using them (prevents exit 127 errors)
declare -f append_workflow_state_bulk >/dev/null 2>&1
FUNCTION_CHECK=$?
if [ $FUNCTION_CHECK -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "execution_error" \
    "append_workflow_state_bulk function not available - library sourcing failed" \
    "bash_block_1d_topics" \
    "$(jq -n '{library: "state-persistence.sh", function: "append_workflow_state_bulk"}')"
  echo "ERROR: append_workflow_state_bulk function not available after sourcing state-persistence.sh" >&2
  exit 1
fi

echo ""
echo "=== Topic Decomposition ==="
echo ""

TOPIC_COUNT=1
declare -a TOPICS_ARRAY=()
declare -a REPORT_PATHS_ARRAY=()

# === CHECK IF TOPIC DETECTION SUCCEEDED ===
if [ "${TOPIC_DETECTION_SUCCESS:-false}" = "true" ] && [ -n "${TOPICS_JSON_FILE:-}" ] && [ -f "${TOPICS_JSON_FILE:-}" ]; then
  echo "Using automated topic detection (topic-detection-agent)"

  # Parse JSON to extract topics
  TOPIC_COUNT=$(jq -r '.topic_count' "$TOPICS_JSON_FILE" 2>/dev/null || echo "0")

  if [ "$TOPIC_COUNT" -eq 0 ]; then
    echo "WARNING: topic_count is 0 in JSON, falling back to heuristic" >&2
    # Will continue to heuristic decomposition below
  else
    echo "Detected $TOPIC_COUNT topics from JSON"

    # Build TOPICS_ARRAY from JSON
    for i in $(seq 0 $((TOPIC_COUNT - 1))); do
      # Extract topic title and scope for comprehensive topic description
      TITLE=$(jq -r ".topics[$i].title" "$TOPICS_JSON_FILE" 2>/dev/null || echo "")
      SCOPE=$(jq -r ".topics[$i].scope" "$TOPICS_JSON_FILE" 2>/dev/null || echo "")
      SLUG=$(jq -r ".topics[$i].slug" "$TOPICS_JSON_FILE" 2>/dev/null || echo "")

      if [ -n "$TITLE" ] && [ -n "$SCOPE" ]; then
        # Use title and scope for research-specialist context
        TOPICS_ARRAY+=("$TITLE: $SCOPE")
      else
        echo "WARNING: Missing title or scope for topic $i, using generic" >&2
        TOPICS_ARRAY+=("${FEATURE_DESCRIPTION} - Topic $((i + 1))")
      fi

      # Calculate report paths using slugs
      REPORT_NUM=$(printf "%03d" $((i + 1)))
      if [ -n "$SLUG" ]; then
        REPORT_FILENAME="${REPORT_NUM}-${SLUG}.md"
      else
        REPORT_FILENAME="${REPORT_NUM}-$(echo "${TOPIC_NAME:-no_name}" | tr '_' '-' | cut -c1-40)-part$((i + 1)).md"
      fi
      REPORT_PATHS_ARRAY+=("${RESEARCH_DIR}/${REPORT_FILENAME}")
    done

    echo "✓ Topics parsed from automated detection"
  fi
fi

# === FALLBACK: HEURISTIC DECOMPOSITION ===
# If topic detection was skipped, failed, or returned 0 topics
if [ "${#TOPICS_ARRAY[@]}" -eq 0 ]; then
  echo "Using heuristic decomposition (fallback mode)"

  # Complexity-based topic allocation
  # Complexity 1-2 → 1 topic (single focus)
  # Complexity 3 → 2-3 topics (moderate breadth)
  # Complexity 4 → 4-5 topics (comprehensive)

  if [ "${RESEARCH_COMPLEXITY:-3}" -le 2 ]; then
    TOPIC_COUNT=1
    echo "Complexity ${RESEARCH_COMPLEXITY}: Using single-topic mode"
  elif [ "${RESEARCH_COMPLEXITY:-3}" -eq 3 ]; then
    # Check for multi-topic indicators
    if echo "$FEATURE_DESCRIPTION" | grep -qiE '\b(and|or|with|including)\b|,'; then
      TOPIC_COUNT=2
      echo "Complexity 3 with conjunctions: Using 2-topic mode"
    else
      TOPIC_COUNT=1
      echo "Complexity 3 without conjunctions: Using single-topic mode"
    fi
  else
    # Complexity 4 → multi-topic
    TOPIC_COUNT=3
    echo "Complexity 4: Using 3-topic mode"
  fi

  # === PRE-CALCULATE TOPICS AND REPORT PATHS ===
  if [ "$TOPIC_COUNT" -eq 1 ]; then
    # Single topic mode (backward compatibility)
    TOPICS_ARRAY=("${FEATURE_DESCRIPTION}")

    # Calculate report path
    REPORT_NUMBER="001"
    REPORT_FILENAME="${REPORT_NUMBER}-$(echo "${TOPIC_NAME:-no_name}" | tr '_' '-' | cut -c1-40)-analysis.md"
    REPORT_PATHS_ARRAY=("${RESEARCH_DIR}/${REPORT_FILENAME}")
  else
    # Multi-topic mode (heuristic decomposition)
    # Simple heuristic decomposition (less sophisticated than topic-detection-agent)

    if [ "$TOPIC_COUNT" -eq 2 ]; then
      # Split on conjunctions or commas
      TOPICS_ARRAY=(
        "${FEATURE_DESCRIPTION} - Part 1"
        "${FEATURE_DESCRIPTION} - Part 2"
      )
    else
      # 3 topics
      TOPICS_ARRAY=(
        "${FEATURE_DESCRIPTION} - Core Implementation"
        "${FEATURE_DESCRIPTION} - Integration Patterns"
        "${FEATURE_DESCRIPTION} - Best Practices"
      )
    fi

    # Calculate report paths for each topic
    for i in "${!TOPICS_ARRAY[@]}"; do
      REPORT_NUM=$(printf "%03d" $((i + 1)))
      REPORT_FILENAME="${REPORT_NUM}-$(echo "${TOPIC_NAME:-no_name}" | tr '_' '-' | cut -c1-40)-part$((i + 1)).md"
      REPORT_PATHS_ARRAY+=("${RESEARCH_DIR}/${REPORT_FILENAME}")
    done
  fi
fi

# === PERSIST TOPICS AND REPORT PATHS TO STATE FILE ===
# Convert arrays to space-separated strings for state persistence
TOPICS_STRING="${TOPICS_ARRAY[*]}"
REPORT_PATHS_STRING="${REPORT_PATHS_ARRAY[*]}"

append_workflow_state_bulk <<EOF
TOPIC_COUNT=$TOPIC_COUNT
TOPICS_STRING=$TOPICS_STRING
REPORT_PATHS_STRING=$REPORT_PATHS_STRING
EOF

echo "Topic count: $TOPIC_COUNT"
echo "Topics prepared for research coordinator"
for i in "${!TOPICS_ARRAY[@]}"; do
  echo "  Topic $((i + 1)): ${TOPICS_ARRAY[$i]}"
  echo "  Report: ${REPORT_PATHS_ARRAY[$i]}"
done
echo ""
echo "CHECKPOINT: Topic decomposition complete, ready for research coordinator invocation"
```

## Block 1e-exec: Research Coordinator Invocation

**CRITICAL BARRIER**: The topic decomposition block (Block 1d-topics) MUST complete before proceeding.

**EXECUTE NOW**: USE the Task tool to invoke the research-coordinator agent.

This agent will orchestrate parallel research-specialist invocations based on the topics array prepared in Block 1d-topics.

You MUST use the Task tool with these EXACT parameters:
- **subagent_type**: "general-purpose"
- **description**: "Coordinate multi-topic research for ${FEATURE_DESCRIPTION}"
- **prompt**:
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-coordinator.md

    You are coordinating research for: /create-plan workflow

    **Input Contract (Hard Barrier Pattern - Mode 2: Manual Pre-Decomposition)**:
    - research_request: "${FEATURE_DESCRIPTION}"
    - research_complexity: ${RESEARCH_COMPLEXITY}
    - report_dir: ${RESEARCH_DIR}
    - topic_path: ${TOPIC_PATH}
    - topics: ${TOPICS_STRING}
    - report_paths: ${REPORT_PATHS_STRING}
    - context:
        feature_description: "${FEATURE_DESCRIPTION}"
        workflow_type: "research-and-plan"
        original_prompt_file: "${ORIGINAL_PROMPT_FILE_PATH:-none}"
        archived_prompt_file: "${ARCHIVED_PROMPT_PATH:-none}"

    **CRITICAL**: You are receiving pre-calculated topics and report paths from the primary agent.
    Use Mode 2 (Manual Pre-Decomposition) workflow:
    - SKIP topic decomposition (topics already provided)
    - SKIP report path calculation (paths already provided)
    - Parse topics and report_paths from the input above
    - Invoke research-specialist for each topic in parallel
    - Validate all reports exist at pre-calculated paths (hard barrier)
    - Extract metadata from each report (title, findings count, recommendations count)
    - Return aggregated metadata

    Execute research coordination according to behavioral guidelines and return:
    RESEARCH_COMPLETE: {REPORT_COUNT}
    reports: [JSON array of report metadata]
    total_findings: {N}
    total_recommendations: {N}

DO NOT perform research directly. DO NOT use Read/Grep/Glob for research purposes.
DO NOT use Write to create research reports directly.
The Task tool invocation is MANDATORY.

## Block 1f: Research Output Verification

**EXECUTE NOW**: Validate that research-specialist created the output file at the pre-calculated path.

This is the **hard barrier** - the workflow CANNOT proceed unless the research report exists.

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

# === RESTORE STATE FROM BLOCK 1E ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
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

COMMAND_NAME="/create-plan"
USER_ARGS="${FEATURE_DESCRIPTION:-}"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# Source libraries (three-tier pattern)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Tier 2: state-persistence.sh (required for append_workflow_state at line 1573)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Cannot load state-persistence library" >&2
  exit 1
}

# Source validation utilities for agent artifact validation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/validation-utils.sh" 2>/dev/null || {
  echo "ERROR: Cannot load validation-utils.sh - required for workflow validation" >&2
  exit 1
}

# Setup bash error trap
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# === PRE-FLIGHT FUNCTION VALIDATION (Block 1f) ===
# Verify required functions are available before using them (prevents exit 127 errors)
declare -f append_workflow_state >/dev/null 2>&1
FUNCTION_CHECK=$?
if [ $FUNCTION_CHECK -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "execution_error" \
    "append_workflow_state function not available - library sourcing failed" \
    "bash_block_1f" \
    "$(jq -n '{library: "state-persistence.sh", function: "append_workflow_state"}')"
  echo "ERROR: append_workflow_state function not available after sourcing state-persistence.sh" >&2
  exit 1
fi

echo ""
echo "=== Research Output Hard Barrier Validation ==="
echo ""

# === HARD BARRIER VALIDATION - MULTI-REPORT MODE ===
# Restore REPORT_PATHS_STRING from Block 1d-topics (space-separated paths)
if [ -z "${REPORT_PATHS_STRING:-}" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "REPORT_PATHS_STRING not restored from Block 1d-topics state" \
    "bash_block_1f" \
    "$(jq -n '{report_paths_string: "missing"}')"
  echo "ERROR: REPORT_PATHS_STRING not set - state restoration failed" >&2
  exit 1
fi

# Reconstruct array from space-separated string
IFS=' ' read -ra REPORT_PATHS_ARRAY <<< "$REPORT_PATHS_STRING"

echo "Expected reports: ${#REPORT_PATHS_ARRAY[@]}"

# Validate each report (fail-fast hard barrier)
VALIDATION_FAILED=false
for REPORT_PATH in "${REPORT_PATHS_ARRAY[@]}"; do
  echo "  Validating: $REPORT_PATH"

  # HARD BARRIER: Validate agent artifact using validation-utils.sh
  # validate_agent_artifact checks file existence and minimum size (100 bytes)
  if ! validate_agent_artifact "$REPORT_PATH" 100 "research report"; then
    # Error already logged by validate_agent_artifact
    echo "ERROR: HARD BARRIER FAILED - Report validation failed: $REPORT_PATH" >&2
    VALIDATION_FAILED=true
    break
  fi

  # Content validation: Check for findings section (flexible header format)
  if ! grep -qE "^## (Findings|Executive Summary|Analysis)" "$REPORT_PATH"; then
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "validation_error" \
      "Research report missing required findings section (accepts: Findings, Executive Summary, Analysis)" \
      "bash_block_1f" \
      "$(jq -n --arg path "$REPORT_PATH" '{report_path: $path}')"
    echo "ERROR: Research report missing required findings section: $REPORT_PATH" >&2
    echo "Accepted section headers: ## Findings, ## Executive Summary, ## Analysis" >&2
    VALIDATION_FAILED=true
    break
  fi

  echo "  ✓ Validated"
done

if [ "$VALIDATION_FAILED" = "true" ]; then
  echo "" >&2
  echo "This indicates the research-coordinator did not create valid output." >&2
  echo "" >&2
  echo "Recovery steps:" >&2
  echo "1. Check research-coordinator agent log for errors" >&2
  echo "2. Verify research-coordinator.md behavioral file compliance" >&2
  echo "3. Re-run: /create-plan \"${FEATURE_DESCRIPTION}\"" >&2
  echo "" >&2
  exit 1
fi

# === EXTRACT METADATA FROM REPORTS ===
# Build aggregated metadata for plan-architect (metadata-only context passing)
declare -a METADATA_ARRAY=()

for REPORT_PATH in "${REPORT_PATHS_ARRAY[@]}"; do
  # Extract report title (first # heading)
  REPORT_TITLE=$(grep "^# " "$REPORT_PATH" | head -1 | sed 's/^# //' || echo "$(basename "$REPORT_PATH")")

  # Extract findings count (count ## Findings bullet points)
  FINDINGS_COUNT=$(grep -A 1000 "^## Findings" "$REPORT_PATH" | grep -c "^- " || echo "0")

  # Extract recommendations count (count ## Recommendations bullet points)
  RECOMMENDATIONS_COUNT=$(grep -A 1000 "^## Recommendations" "$REPORT_PATH" | grep -c "^- " || echo "0")

  # Build metadata entry (110 tokens per report format)
  METADATA_ENTRY="Report: $REPORT_TITLE | Findings: $FINDINGS_COUNT | Recommendations: $RECOMMENDATIONS_COUNT | Path: $REPORT_PATH"
  METADATA_ARRAY+=("$METADATA_ENTRY")

  echo "  Metadata extracted: $REPORT_TITLE ($FINDINGS_COUNT findings, $RECOMMENDATIONS_COUNT recommendations)"
done

# Aggregate metadata into single variable for state persistence
AGGREGATED_METADATA=$(printf "%s\n" "${METADATA_ARRAY[@]}")

# Persist aggregated metadata for Block 2 (planning phase)
append_workflow_state "AGGREGATED_METADATA<<METADATA_EOF
$AGGREGATED_METADATA
METADATA_EOF"

echo ""
echo "✓ Hard barrier passed - ${#REPORT_PATHS_ARRAY[@]} reports validated with metadata extracted"
echo ""
```

## Block 2: Research Verification and Planning Setup

**EXECUTE NOW**: Verify research artifacts and prepare for planning:

```bash
set +H  # CRITICAL: Disable history expansion

# === PRE-TRAP ERROR BUFFER ===
# Initialize error buffer BEFORE any library sourcing
declare -a _EARLY_ERROR_BUFFER=()

# === DETECT PROJECT DIRECTORY ===
# CRITICAL: Detect project directory FIRST before using CLAUDE_PROJECT_DIR
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    current_dir="$(pwd)"
    while [ "$current_dir" != "/" ]; do
      [ -d "$current_dir/.claude" ] && { CLAUDE_PROJECT_DIR="$current_dir"; break; }
      current_dir="$(dirname "$current_dir")"
    done
  fi
  export CLAUDE_PROJECT_DIR
fi

# === SOURCE LIBRARIES IN CORRECT ORDER ===
# CRITICAL: Source libraries BEFORE any function calls or trap setup
# Order matters: error-handling -> state-persistence -> workflow-state-machine

# 1. Source error-handling.sh FIRST (provides setup_bash_error_trap and logging)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# 2. Source state-persistence.sh SECOND (provides validate_workflow_id, append_workflow_state)
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1

# 3. Source workflow-state-machine.sh THIRD (depends on state-persistence.sh)
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" || exit 1

# === LOAD STATE ===
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path (now guaranteed to be set)
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
if [ ! -f "$STATE_ID_FILE" ]; then
  echo "ERROR: WORKFLOW_ID file not found" >&2
  exit 1
fi
WORKFLOW_ID=$(cat "$STATE_ID_FILE")

# === VALIDATE WORKFLOW_ID ===
# CRITICAL: Call validate_workflow_id AFTER state-persistence.sh is sourced
WORKFLOW_ID=$(validate_workflow_id "$WORKFLOW_ID" "plan")
export WORKFLOW_ID

# === SETUP BASH ERROR TRAP ===
# CRITICAL: Setup trap AFTER libraries loaded (replaces broken defensive trap pattern)
COMMAND_NAME="/create-plan"
USER_ARGS="${FEATURE_DESCRIPTION:-plan_workflow}"
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# === PRE-FLIGHT FUNCTION VALIDATION (Block 2) ===
# Verify required functions are available before using them (prevents exit 127 errors)
declare -f append_workflow_state >/dev/null 2>&1
FUNCTION_CHECK=$?
if [ $FUNCTION_CHECK -ne 0 ]; then
  echo "ERROR: append_workflow_state function not available after sourcing state-persistence.sh" >&2
  exit 1
fi
declare -f save_completed_states_to_state >/dev/null 2>&1
FUNCTION_CHECK=$?
if [ $FUNCTION_CHECK -ne 0 ]; then
  echo "ERROR: save_completed_states_to_state function not available after sourcing state-persistence.sh" >&2
  exit 1
fi

# Initialize DEBUG_LOG if not already set
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
DEBUG_LOG="${DEBUG_LOG:-${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_debug.log}"
mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null

load_workflow_state "$WORKFLOW_ID" false

# Validate critical variables restored from state
validate_state_restoration "COMMAND_NAME" "USER_ARGS" "STATE_FILE" "PLAN_FILE" "TOPIC_PATH" "RESEARCH_DIR" || {
  echo "ERROR: State restoration failed - critical variables missing" >&2
  exit 1
}

# === RESTORE ERROR LOGGING CONTEXT ===
if [ -z "${COMMAND_NAME:-}" ]; then
  COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "/create-plan")
fi
if [ -z "${USER_ARGS:-}" ]; then
  USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "")
fi
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# === BASH ERROR TRAP ALREADY ACTIVE ===
# Trap was setup earlier in this block - no need to setup again
# Flush any early errors captured before trap was active
_flush_early_errors

# === VALIDATE STATE AFTER LOAD ===
if [ -z "$STATE_FILE" ]; then
  # Log to centralized error log
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State file path not set after load" \
    "bash_block_2" \
    "$(jq -n --arg workflow "$WORKFLOW_ID" '{workflow_id: $workflow}')"

  # Also log to DEBUG_LOG
  {
    echo "[$(date)] ERROR: State file path not set"
    echo "WHICH: load_workflow_state"
    echo "WHAT: STATE_FILE variable empty after load"
    echo "WHERE: Block 2, research phase"
  } >> "$DEBUG_LOG"
  echo "ERROR: State file path not set (see $DEBUG_LOG)" >&2
  exit 1
fi

if [ ! -f "$STATE_FILE" ]; then
  # Log to centralized error log
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "State file not found at expected path" \
    "bash_block_2" \
    "$(jq -n --arg path "$STATE_FILE" '{expected_path: $path}')"

  # Also log to DEBUG_LOG
  {
    echo "[$(date)] ERROR: State file not found"
    echo "WHICH: load_workflow_state"
    echo "WHAT: File does not exist at expected path"
    echo "WHERE: Block 2, research phase"
    echo "PATH: $STATE_FILE"
  } >> "$DEBUG_LOG"
  echo "ERROR: State file not found (see $DEBUG_LOG)" >&2
  exit 1
fi

# === DEFENSIVE VARIABLE INITIALIZATION ===
# Initialize potentially unbound variables with defaults to prevent unbound variable errors
TOPIC_PATH="${TOPIC_PATH:-}"
RESEARCH_DIR="${RESEARCH_DIR:-}"
PLANS_DIR="${PLANS_DIR:-}"
TOPIC_NAME="${TOPIC_NAME:-no_name}"
FEATURE_DESCRIPTION="${FEATURE_DESCRIPTION:-}"
ORIGINAL_PROMPT_FILE_PATH="${ORIGINAL_PROMPT_FILE_PATH:-}"
ARCHIVED_PROMPT_PATH="${ARCHIVED_PROMPT_PATH:-}"

# Validate critical variables from Block 1
if [ -z "${TOPIC_PATH:-}" ] || [ -z "${RESEARCH_DIR:-}" ]; then
  # Log to centralized error log
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "Critical variables not restored from state" \
    "bash_block_2" \
    "$(jq -n --arg topic "${TOPIC_PATH:-MISSING}" --arg research "${RESEARCH_DIR:-MISSING}" \
       '{TOPIC_PATH: $topic, RESEARCH_DIR: $research}')"

  # Also log to DEBUG_LOG
  {
    echo "[$(date)] ERROR: Critical variables not restored"
    echo "WHICH: load_workflow_state"
    echo "WHAT: TOPIC_PATH or RESEARCH_DIR missing after load"
    echo "WHERE: Block 2, research phase"
    echo "TOPIC_PATH: ${TOPIC_PATH:-MISSING}"
    echo "RESEARCH_DIR: ${RESEARCH_DIR:-MISSING}"
  } >> "$DEBUG_LOG"
  echo "ERROR: Critical variables not restored (see $DEBUG_LOG)" >&2
  exit 1
fi

# === VERIFY RESEARCH ARTIFACTS ===
echo "Verifying research artifacts..."

if [ ! -d "$RESEARCH_DIR" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "Research phase failed to create reports directory" \
    "bash_block_2" \
    "$(jq -n --arg dir "$RESEARCH_DIR" '{expected_dir: $dir}')"

  echo "ERROR: Research phase failed to create reports directory" >&2
  exit 1
fi

if [ -z "$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null)" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Research phase failed to create report files" \
    "bash_block_2" \
    "$(jq -n --arg dir "$RESEARCH_DIR" '{research_dir: $dir}')"

  echo "ERROR: Research phase failed to create report files" >&2
  exit 1
fi

UNDERSIZED_FILES=$(find "$RESEARCH_DIR" -name '*.md' -type f -size -100c 2>/dev/null)
if [ -n "$UNDERSIZED_FILES" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Research report(s) too small (< 100 bytes)" \
    "bash_block_2" \
    "$(jq -n --arg files "$UNDERSIZED_FILES" '{undersized_files: $files}')"

  echo "ERROR: Research report(s) too small (< 100 bytes)" >&2
  exit 1
fi

REPORT_COUNT=$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null | wc -l)
append_workflow_state "REPORT_COUNT" "$REPORT_COUNT"

echo "Research verified: $REPORT_COUNT reports"
echo ""

# === TRANSITION TO PLAN ===
sm_transition "$STATE_PLAN" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
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
# Convert to space-separated format for state persistence (append_workflow_state_bulk expects KEY=value format)
REPORT_PATHS_LIST=$(echo "$REPORT_PATHS" | tr '\n' ' ')

# === PERSIST FOR BLOCK 3 (BULK OPERATION) ===
# Use bulk append to reduce I/O overhead from 2 writes to 1 write
append_workflow_state_bulk <<EOF
PLAN_PATH=$PLAN_PATH
REPORT_PATHS_LIST=$REPORT_PATHS_LIST
EOF

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

# === EXTRACT PROJECT STANDARDS ===
# Source standards extraction library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/standards-extraction.sh" 2>/dev/null || {
  log_command_error "file_error" "Failed to source standards-extraction library" "$(jq -n --arg path "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/standards-extraction.sh" '{library_path: $path}')"
  echo "WARNING: Standards extraction unavailable, proceeding without standards" >&2
  FORMATTED_STANDARDS=""
}

# Extract and format standards for prompt injection
if [ -z "${FORMATTED_STANDARDS:-}" ]; then
  FORMATTED_STANDARDS=$(format_standards_for_prompt 2>/dev/null) || {
    log_command_error "execution_error" "Standards extraction failed" "{}"
    echo "WARNING: Standards extraction failed, proceeding without standards" >&2
    FORMATTED_STANDARDS=""
  }
fi

# === EXTRACT NON-INTERACTIVE TESTING STANDARDS ===
# Extract testing standards for test phase automation requirements
TESTING_STANDARD_PATH="${CLAUDE_PROJECT_DIR}/.claude/docs/reference/standards/non-interactive-testing-standard.md"
if [ -f "$TESTING_STANDARD_PATH" ]; then
  TESTING_STANDARDS=$(extract_testing_standards "$TESTING_STANDARD_PATH" 2>/dev/null) || {
    log_command_error "execution_error" "Testing standards extraction failed" "{}"
    echo "WARNING: Testing standards extraction failed, proceeding without testing standards" >&2
    TESTING_STANDARDS=""
  }

  if [ -n "$TESTING_STANDARDS" ]; then
    echo "Injecting non-interactive testing standards into plan generation workflow"
  fi
else
  echo "Non-interactive testing standard not found, proceeding without testing standards"
  TESTING_STANDARDS=""
fi

# Persist standards for Block 3 divergence detection
append_workflow_state "FORMATTED_STANDARDS<<STANDARDS_EOF
$FORMATTED_STANDARDS
STANDARDS_EOF"

if ! save_completed_states_to_state; then
  echo "WARNING: Failed to persist COMPLETED_STATES to state file" >&2
fi

if [ -n "$FORMATTED_STANDARDS" ]; then
  STANDARDS_COUNT=$(echo "$FORMATTED_STANDARDS" | grep -c "^###" || echo 0)
  echo "Extracted $STANDARDS_COUNT standards sections for plan-architect"
else
  echo "No standards extracted (graceful degradation)"
fi

echo ""
echo "CHECKPOINT: Planning setup complete, ready for Task invocation"
```

## Block 2-exec: Plan-Architect Invocation

**CRITICAL BARRIER**: The bash block above MUST complete before proceeding.

**EXECUTE NOW**: USE the Task tool to invoke the plan-architect agent.

You MUST use the Task tool with these EXACT parameters:
- **subagent_type**: "general-purpose"
- **description**: "Create implementation plan for ${FEATURE_DESCRIPTION} with mandatory file creation"
- **prompt**:
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are creating an implementation plan for: plan workflow

    **Workflow-Specific Context**:
    - Feature Description: ${FEATURE_DESCRIPTION}
    - Output Path: ${PLAN_PATH}
    - Research Reports: ${REPORT_PATHS_LIST}
    - Workflow Type: research-and-plan
    - Operation Mode: new plan creation
    - Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH:-none}
    - Archived Prompt File: ${ARCHIVED_PROMPT_PATH:-none}

    **Research Metadata** (110 tokens per report format):
    ${AGGREGATED_METADATA}

    **IMPORTANT**: You have received metadata summaries for each research report (title, findings count, recommendations count, path). This is metadata-only context passing for 95% context reduction. You MUST use the Read tool to access full report content at the paths provided above. Do NOT attempt to create the plan from metadata alone - read the full reports for comprehensive analysis.

    **Project Standards**:
    ${FORMATTED_STANDARDS}

    **Testing Automation Standards**:
    ${TESTING_STANDARDS}

    **CRITICAL**: You MUST write the plan to the EXACT path specified above.
    The orchestrator has pre-calculated this path and will validate it exists after you return.
    Do NOT derive or calculate your own path.

    If an archived prompt file is provided (not 'none'), reference it for complete context.

    IMPORTANT: If your planned approach conflicts with provided standards for well-motivated reasons, include Phase 0 to revise standards with clear justification and user warning. See Standards Divergence Protocol in plan-architect.md.

    **CRITICAL FORMAT REQUIREMENTS FOR NEW PLANS**:
    This is a NEW plan creation (not revision). You MUST follow these format rules:

    1. Metadata Status Field:
       - MUST be exactly: **Status**: [NOT STARTED]
       - Do NOT use [IN PROGRESS], [COMPLETE], or [BLOCKED]

    2. Phase Heading Format:
       - ALL phases MUST include [NOT STARTED] marker
       - Format: ### Phase N: Name [NOT STARTED]
       - Do NOT use [COMPLETE], [PARTIAL], or [IN PROGRESS]

    3. Checkbox Format:
       - ALL Success Criteria MUST use: - [ ] (unchecked)
       - ALL tasks MUST use: - [ ] (unchecked)
       - Do NOT pre-mark checkboxes as [x] or [~]

    4. Status vs Findings Distinction:
       - Research findings describe WHAT EXISTS in the codebase
       - Plan status describes WHAT NEEDS TO BE DONE
       - Even if research shows partial implementation, the plan status is [NOT STARTED]
       - The plan tracks future work, not past accomplishments

    5. Metadata Field Restriction:
       - Only use standard metadata fields from plan-architect.md template
       - Do NOT add workflow-specific fields (e.g., **Lean File**)
       - Required fields: Date, Feature, Status, Estimated Hours, Standards File, Research Reports

    **WHY THIS MATTERS**:
    - /implement depends on [NOT STARTED] markers to track progress
    - Pre-completed checkboxes break automated task tracking
    - Invalid status markers confuse progress detection
    - This is a plan for FUTURE work, not a report of PAST work

    Execute planning according to behavioral guidelines and return completion signal:
    PLAN_CREATED: ${PLAN_PATH}

DO NOT write the plan file directly. DO NOT use Write tool for plan creation.
The Task tool invocation is MANDATORY.

## Block 3a: Planning Output Verification

**EXECUTE NOW**: Validate that plan-architect created the output file at the pre-calculated path.

This is the **hard barrier** - the workflow CANNOT proceed unless the plan file exists.

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

# === RESTORE STATE FROM BLOCK 2 ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
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

COMMAND_NAME="/create-plan"
USER_ARGS="${FEATURE_DESCRIPTION:-}"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Source validation utilities for agent artifact validation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/validation-utils.sh" 2>/dev/null || {
  echo "ERROR: Cannot load validation-utils.sh - required for workflow validation" >&2
  exit 1
}

# Setup bash error trap
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

echo ""
echo "=== Planning Output Hard Barrier Validation ==="
echo ""

# === HARD BARRIER VALIDATION ===
# Validate PLAN_PATH is set (from Block 2)
if [ -z "${PLAN_PATH:-}" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "PLAN_PATH not restored from Block 2 state" \
    "bash_block_3a" \
    "$(jq -n '{plan_path: "missing"}')"
  echo "ERROR: PLAN_PATH not set - state restoration failed" >&2
  exit 1
fi

echo "Expected plan file: $PLAN_PATH"

# HARD BARRIER: Validate agent artifact using validation-utils.sh
# validate_agent_artifact checks file existence and minimum size (500 bytes)
if ! validate_agent_artifact "$PLAN_PATH" 500 "implementation plan"; then
  # Error already logged by validate_agent_artifact
  echo "ERROR: HARD BARRIER FAILED - Plan-architect validation failed" >&2
  echo "" >&2
  echo "This indicates the plan-architect did not create valid output." >&2
  echo "" >&2
  echo "Recovery steps:" >&2
  echo "1. Check plan-architect agent log for errors" >&2
  echo "2. Verify plan-architect.md behavioral file compliance" >&2
  echo "3. Re-run: /create-plan \"${FEATURE_DESCRIPTION}\"" >&2
  echo "" >&2
  exit 1
fi

# Structure validation: Check for ## Metadata section
if ! grep -q "^## Metadata" "$PLAN_PATH"; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Plan file missing required ## Metadata section" \
    "bash_block_3a" \
    "$(jq -n --arg path "$PLAN_PATH" '{plan_path: $path}')"
  echo "ERROR: Plan file missing ## Metadata section" >&2
  echo "Plan path: $PLAN_PATH" >&2
  exit 1
fi

# Structure validation: Check for phase headings
if ! grep -q "^### Phase [0-9]" "$PLAN_PATH"; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Plan file missing phase headings" \
    "bash_block_3a" \
    "$(jq -n --arg path "$PLAN_PATH" '{plan_path: $path}')"
  echo "ERROR: Plan file missing phase headings" >&2
  echo "Plan path: $PLAN_PATH" >&2
  exit 1
fi

echo "✓ Hard barrier passed - plan file validated"
echo ""
```

## Block 3: Plan Verification and Completion

**EXECUTE NOW**: Verify plan artifacts and complete workflow:

```bash
set +H  # CRITICAL: Disable history expansion

# === PRE-TRAP ERROR BUFFER ===
# Initialize error buffer BEFORE any library sourcing
declare -a _EARLY_ERROR_BUFFER=()

# === DETECT PROJECT DIRECTORY ===
# CRITICAL: Detect project directory FIRST before using CLAUDE_PROJECT_DIR
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    current_dir="$(pwd)"
    while [ "$current_dir" != "/" ]; do
      [ -d "$current_dir/.claude" ] && { CLAUDE_PROJECT_DIR="$current_dir"; break; }
      current_dir="$(dirname "$current_dir")"
    done
  fi
  export CLAUDE_PROJECT_DIR
fi

# === SOURCE LIBRARIES IN CORRECT ORDER ===
# CRITICAL: Source libraries BEFORE any function calls or trap setup
# Order matters: error-handling -> state-persistence -> workflow-state-machine

# 1. Source error-handling.sh FIRST (provides setup_bash_error_trap and logging)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# 2. Source state-persistence.sh SECOND (provides validate_workflow_id, save_completed_states_to_state)
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1

# 3. Source workflow-state-machine.sh THIRD (depends on state-persistence.sh)
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" || exit 1

# === LOAD STATE ===
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path (now guaranteed to be set)
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
if [ ! -f "$STATE_ID_FILE" ]; then
  echo "ERROR: WORKFLOW_ID file not found" >&2
  exit 1
fi
WORKFLOW_ID=$(cat "$STATE_ID_FILE")

# === VALIDATE WORKFLOW_ID ===
# CRITICAL: Call validate_workflow_id AFTER state-persistence.sh is sourced
WORKFLOW_ID=$(validate_workflow_id "$WORKFLOW_ID" "plan")
export WORKFLOW_ID

# === SETUP BASH ERROR TRAP ===
# CRITICAL: Setup trap AFTER libraries loaded (replaces broken defensive trap pattern)
COMMAND_NAME="/create-plan"
USER_ARGS="${FEATURE_DESCRIPTION:-plan_workflow}"
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# === PRE-FLIGHT FUNCTION VALIDATION (Block 3) ===
# Verify required functions are available before using them (prevents exit 127 errors)
declare -f save_completed_states_to_state >/dev/null 2>&1
FUNCTION_CHECK=$?
if [ $FUNCTION_CHECK -ne 0 ]; then
  echo "ERROR: save_completed_states_to_state function not available after sourcing state-persistence.sh" >&2
  exit 1
fi

# Initialize DEBUG_LOG if not already set
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
DEBUG_LOG="${DEBUG_LOG:-${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_debug.log}"
mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null

load_workflow_state "$WORKFLOW_ID" false

# Validate critical variables restored from state
validate_state_restoration "COMMAND_NAME" "USER_ARGS" "STATE_FILE" "PLAN_FILE" "TOPIC_PATH" "RESEARCH_DIR" || {
  echo "ERROR: State restoration failed - critical variables missing" >&2
  exit 1
}

# === RESTORE ERROR LOGGING CONTEXT ===
if [ -z "${COMMAND_NAME:-}" ]; then
  COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "/create-plan")
fi
if [ -z "${USER_ARGS:-}" ]; then
  USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "")
fi
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# === BASH ERROR TRAP ALREADY ACTIVE ===
# Trap was setup earlier in this block - no need to setup again
# Flush any early errors captured before trap was active
_flush_early_errors

# === VALIDATE STATE AFTER LOAD ===
if [ -z "$STATE_FILE" ]; then
  # Log to centralized error log
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State file path not set after load" \
    "bash_block_3" \
    "$(jq -n --arg workflow "$WORKFLOW_ID" '{workflow_id: $workflow}')"

  # Also log to DEBUG_LOG
  {
    echo "[$(date)] ERROR: State file path not set"
    echo "WHICH: load_workflow_state"
    echo "WHAT: STATE_FILE variable empty after load"
    echo "WHERE: Block 3, planning phase"
  } >> "$DEBUG_LOG"
  echo "ERROR: State file path not set (see $DEBUG_LOG)" >&2
  exit 1
fi

if [ ! -f "$STATE_FILE" ]; then
  # Log to centralized error log
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "State file not found at expected path" \
    "bash_block_3" \
    "$(jq -n --arg path "$STATE_FILE" '{expected_path: $path}')"

  # Also log to DEBUG_LOG
  {
    echo "[$(date)] ERROR: State file not found"
    echo "WHICH: load_workflow_state"
    echo "WHAT: File does not exist at expected path"
    echo "WHERE: Block 3, planning phase"
    echo "PATH: $STATE_FILE"
  } >> "$DEBUG_LOG"
  echo "ERROR: State file not found (see $DEBUG_LOG)" >&2
  exit 1
fi

# === DEFENSIVE VARIABLE INITIALIZATION ===
# Initialize potentially unbound variables with defaults to prevent unbound variable errors
PLAN_PATH="${PLAN_PATH:-}"
REPORT_COUNT="${REPORT_COUNT:-0}"
FEATURE_DESCRIPTION="${FEATURE_DESCRIPTION:-}"

# Validate PLAN_PATH was set by Block 2
if [ -z "${PLAN_PATH:-}" ]; then
  # Log to centralized error log
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "PLAN_PATH not found in state" \
    "bash_block_3" \
    "$(jq -n '{message: "PLAN_PATH not set by Block 2"}')"

  # Also log to DEBUG_LOG
  {
    echo "[$(date)] ERROR: PLAN_PATH not found in state"
    echo "WHICH: load_workflow_state"
    echo "WHAT: PLAN_PATH not set by Block 2"
    echo "WHERE: Block 3, planning phase"
    echo "State file contents:"
    cat "$STATE_FILE" 2>&1 | sed 's/^/  /'
  } >> "$DEBUG_LOG"
  echo "ERROR: PLAN_PATH not found in state (see $DEBUG_LOG)" >&2
  exit 1
fi

# === VERIFY PLAN ARTIFACTS ===
echo "Verifying plan artifacts..."

if [ ! -f "$PLAN_PATH" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "Planning phase failed to create plan file" \
    "bash_block_3" \
    "$(jq -n --arg path "$PLAN_PATH" '{expected_path: $path}')"

  echo "ERROR: Planning phase failed to create plan file" >&2
  exit 1
fi

FILE_SIZE=$(wc -c < "$PLAN_PATH")
if [ "$FILE_SIZE" -lt 500 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Plan file too small" \
    "bash_block_3" \
    "$(jq -n --argjson size "$FILE_SIZE" '{file_size: $size, min_size: 500}')"

  echo "ERROR: Plan file too small ($FILE_SIZE bytes)" >&2
  exit 1
fi

echo "Plan verified: $FILE_SIZE bytes"

# === DETECT PHASE 0 (STANDARDS DIVERGENCE) ===
PHASE_0_DETECTED=false
if grep -q "^### Phase 0: Standards Revision" "$PLAN_PATH" 2>/dev/null; then
  PHASE_0_DETECTED=true

  # Extract divergence metadata
  DIVERGENCE_JUSTIFICATION=$(grep "^\- \*\*Divergence Justification\*\*:" "$PLAN_PATH" | sed 's/.*: //' || echo "See Phase 0 for details")
  AFFECTED_SECTIONS=$(grep "^\- \*\*Standards Sections Affected\*\*:" "$PLAN_PATH" | sed 's/.*: //' || echo "See Phase 0")

  echo ""
  echo "⚠️  STANDARDS DIVERGENCE DETECTED"
  echo "This plan proposes changes to project standards (see Phase 0)."
  echo "Review carefully before proceeding with implementation."
  echo ""
  echo "Affected Sections: $AFFECTED_SECTIONS"
  echo "Justification: $DIVERGENCE_JUSTIFICATION"
  echo ""

  # Persist divergence flag for summary
  append_workflow_state "PHASE_0_DETECTED=true"
  append_workflow_state "DIVERGENCE_JUSTIFICATION=$DIVERGENCE_JUSTIFICATION"
  if ! save_completed_states_to_state; then
    echo "WARNING: Failed to persist COMPLETED_STATES to state file" >&2
  fi
fi

echo ""

# === COMPLETE WORKFLOW ===
sm_transition "$STATE_COMPLETE" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
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
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/summary-formatting.sh" 2>/dev/null || {
  echo "ERROR: Failed to load summary-formatting library" >&2
  exit 1
}

# Extract phase count and estimated hours from plan
PHASE_COUNT=$(grep -c "^### Phase [0-9]" "$PLAN_PATH" 2>/dev/null || echo "0")
ESTIMATED_HOURS=$(grep "Estimated Hours:" "$PLAN_PATH" | head -1 | sed 's/.*: //' 2>/dev/null || echo "unknown")

# Build summary text
SUMMARY_TEXT="Created implementation plan with $PHASE_COUNT phases (estimated $ESTIMATED_HOURS hours) based on $REPORT_COUNT research reports. Plan provides structured roadmap for implementing ${FEATURE_DESCRIPTION}."

# Build artifacts section
ARTIFACTS="  📊 Reports: $RESEARCH_DIR/ ($REPORT_COUNT files)
  📄 Plan: $PLAN_PATH"

# Build next steps
NEXT_STEPS="  • Review plan: cat $PLAN_PATH
  • Begin implementation: /implement $PLAN_PATH
  • Review research: ls -lh $RESEARCH_DIR/
  • Run /todo to update TODO.md (adds plan to tracking)"

# Print standardized summary (no phases for plan command)
print_artifact_summary "Plan" "$SUMMARY_TEXT" "" "$ARTIFACTS" "$NEXT_STEPS"

# Emit completion reminder
echo ""
echo "📋 Next Step: Run /todo to update TODO.md with this plan"
echo ""

# === RETURN PLAN_CREATED SIGNAL ===
# Signal enables buffer-opener hook and orchestrator detection
if [ -n "$PLAN_PATH" ] && [ -f "$PLAN_PATH" ]; then
  echo ""
  echo "PLAN_CREATED: $PLAN_PATH"
  echo ""
fi

exit 0
```

---

**Troubleshooting**:

- **Research fails**: Check research-specialist agent behavioral file compliance
- **Planning fails**: Check plan-architect agent behavioral file (`.claude/agents/plan-architect.md`)
- **Plan file empty**: Verify feature description is clear and research reports exist
- **State machine errors**: Ensure library versions compatible (workflow-state-machine.sh >=2.0.0)
- **File not found error**: Ensure --file path is correct and file exists; relative paths are resolved from current directory
- **Empty file warning**: The prompt file exists but has no content; add content to the file
