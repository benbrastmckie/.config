---
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob
argument-hint: <workflow-description> [--file <path>] [--complexity 1-4]
description: Research-only workflow - Creates comprehensive research reports without planning or implementation
command-type: primary
dependent-agents:
  - research-coordinator
library-requirements:
  - workflow-state-machine.sh: ">=2.0.0"
  - state-persistence.sh: ">=1.5.0"
documentation: See .claude/docs/guides/commands/research-command-guide.md for complete usage guide
---

# /research - Research-Only Workflow Command

YOU ARE EXECUTING a research-only workflow that creates comprehensive research reports without planning or implementation phases.

**Workflow Type**: research-only
**Terminal State**: research (after research phase complete)
**Expected Output**: Research reports in .claude/specs/NNN_topic/reports/

## Block 1a: Initial Setup and State Initialization

**EXECUTE NOW**: The user invoked `/research "<workflow-description>"`. Capture that description.

In the **bash block below**, replace `YOUR_WORKFLOW_DESCRIPTION_HERE` with the actual workflow description (keeping the quotes).

**Example**: If user ran `/research "authentication patterns in codebase"`, change:
- FROM: `echo "YOUR_WORKFLOW_DESCRIPTION_HERE" > "$TEMP_FILE"`
- TO: `echo "authentication patterns in codebase" > "$TEMP_FILE"`

Execute this bash block with your substitution:

```bash
set +H  # CRITICAL: Disable history expansion
shopt -u histexpand 2>/dev/null || true  # Additional protection against history expansion

# === PRE-TRAP ERROR BUFFER ===
# Initialize error buffer BEFORE any library sourcing
declare -a _EARLY_ERROR_BUFFER=()

# === CAPTURE WORKFLOW DESCRIPTION ===
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
TEMP_FILE="${HOME}/.claude/tmp/research_arg_$(date +%s%N).txt"
# SUBSTITUTE THE WORKFLOW DESCRIPTION IN THE LINE BELOW
echo "YOUR_WORKFLOW_DESCRIPTION_HERE" > "$TEMP_FILE"
echo "$TEMP_FILE" > "${HOME}/.claude/tmp/research_arg_path.txt"

# === READ AND VALIDATE ===
WORKFLOW_DESCRIPTION=$(cat "$TEMP_FILE" 2>/dev/null || echo "")

if [ -z "$WORKFLOW_DESCRIPTION" ]; then
  echo "ERROR: Workflow description is empty" >&2
  echo "Usage: /research \"<workflow description>\"" >&2
  exit 1
fi

# Parse optional --complexity flag (default: 2 for research-only)
DEFAULT_COMPLEXITY=2
RESEARCH_COMPLEXITY="$DEFAULT_COMPLEXITY"

if [[ "$WORKFLOW_DESCRIPTION" =~ --complexity[[:space:]]+([1-4]) ]]; then
  RESEARCH_COMPLEXITY="${BASH_REMATCH[1]}"
  WORKFLOW_DESCRIPTION=$(echo "$WORKFLOW_DESCRIPTION" | sed 's/--complexity[[:space:]]*[1-4]//' | xargs)
fi

echo "$RESEARCH_COMPLEXITY" | grep -Eq "^[1-4]$"
COMPLEXITY_VALID=$?
if [ $COMPLEXITY_VALID -ne 0 ]; then
  echo "ERROR: Invalid research complexity: $RESEARCH_COMPLEXITY (must be 1-4)" >&2
  exit 1
fi

# Parse optional --file flag for long prompts
ORIGINAL_PROMPT_FILE_PATH=""
if [[ "$WORKFLOW_DESCRIPTION" =~ --file[[:space:]]+([^[:space:]]+) ]]; then
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
  # Read file content into WORKFLOW_DESCRIPTION
  WORKFLOW_DESCRIPTION=$(cat "${ORIGINAL_PROMPT_FILE_PATH:-}")
  if [ -z "$WORKFLOW_DESCRIPTION" ]; then
    echo "WARNING: Prompt file is empty: ${ORIGINAL_PROMPT_FILE_PATH:-}" >&2
  fi
elif [[ "$WORKFLOW_DESCRIPTION" =~ --file ]]; then
  echo "ERROR: --file flag requires a path argument" >&2
  echo "Usage: /research --file /path/to/prompt.md" >&2
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

# === SOURCE LIBRARIES (Three-Tier Pattern) ===
# Tier 1: Critical Foundation (fail-fast required)
# Source error-handling.sh FIRST to enable diagnostic functions
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Source remaining Tier 1 libraries with diagnostics
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

# === INITIALIZE ERROR LOGGING ===
ensure_error_log_exists

# === SETUP EARLY BASH ERROR TRAP ===
# Trap must be set BEFORE variable initialization to catch early failures
setup_bash_error_trap "/research" "research_early_$(date +%s)" "early_init"

# Flush any early errors captured before trap was active
_flush_early_errors

# === INITIALIZE STATE ===
WORKFLOW_TYPE="research-only"
TERMINAL_STATE="research"
COMMAND_NAME="/research"
USER_ARGS="$WORKFLOW_DESCRIPTION"
export COMMAND_NAME USER_ARGS

WORKFLOW_ID="research_$(date +%s)"
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path (matches state file location)
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/research_state_id.txt"
mkdir -p "$(dirname "$STATE_ID_FILE")"
echo "$WORKFLOW_ID" > "$STATE_ID_FILE"
export WORKFLOW_ID

# === UPDATE BASH ERROR TRAP WITH ACTUAL VALUES ===
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

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

sm_init "$WORKFLOW_DESCRIPTION" "$COMMAND_NAME" "$WORKFLOW_TYPE" "$RESEARCH_COMPLEXITY" "[]" 2>&1
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
    "bash_block_1a" \
    "$(jq -n --arg state "$STATE_RESEARCH" '{target_state: $state}')"

  echo "ERROR: State transition to RESEARCH failed" >&2
  exit 1
fi

# Persist WORKFLOW_DESCRIPTION for topic naming agent
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path (matches Block 1c)
TOPIC_NAMING_INPUT_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/topic_naming_input_${WORKFLOW_ID}.txt"
echo "$WORKFLOW_DESCRIPTION" > "$TOPIC_NAMING_INPUT_FILE"
export TOPIC_NAMING_INPUT_FILE

echo "✓ Setup complete, ready for topic naming"
```

## Block 1b: Topic Name File Path Pre-Calculation

**EXECUTE NOW**: Pre-calculate the absolute topic name output file path BEFORE invoking topic-naming-agent.

This implements the **Hard Barrier Pattern** - the output path is calculated BEFORE agent invocation, passed as an explicit contract, and validated AFTER return.

```bash
set +H  # CRITICAL: Disable history expansion
shopt -u histexpand 2>/dev/null || true  # Additional protection against history expansion

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
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/research_state_id.txt"
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

COMMAND_NAME="/research"
USER_ARGS="${WORKFLOW_DESCRIPTION:-}"
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

# Verify critical functions are available after sourcing
type append_workflow_state >/dev/null 2>&1 || {
  echo "ERROR: append_workflow_state function not defined after sourcing state-persistence.sh" >&2
  exit 1
}
type setup_bash_error_trap >/dev/null 2>&1 || {
  echo "ERROR: setup_bash_error_trap function not defined after sourcing error-handling.sh" >&2
  exit 1
}

# Setup bash error trap
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

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
# Updated logic: Check if STATE_FILE is under CLAUDE_PROJECT_DIR (handles PROJECT_DIR under HOME correctly)
if [[ "$STATE_FILE" == "$CLAUDE_PROJECT_DIR"* ]]; then
  # STATE_FILE is under PROJECT_DIR - valid configuration
  :
elif [[ "$STATE_FILE" == "$HOME"* ]] && [[ "$STATE_FILE" != "$CLAUDE_PROJECT_DIR"* ]]; then
  # STATE_FILE uses HOME but not PROJECT_DIR - invalid configuration
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

Task {
  subagent_type: "general-purpose"
  description: "Generate semantic topic directory name"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/topic-naming-agent.md

    You are generating a topic directory name for: /research command

    **Input Contract (Hard Barrier Pattern)**:
    - Output Path: ${TOPIC_NAME_FILE}
    - User Prompt: ${WORKFLOW_DESCRIPTION}
    - Command Name: /research

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
  "
}

## Block 1c: Hard Barrier Validation

**EXECUTE NOW**: Validate that topic-naming-agent created the output file at the pre-calculated path.

This is the **hard barrier** - the workflow CANNOT proceed unless the topic name file exists. This prevents path mismatch issues.

```bash
set +H  # CRITICAL: Disable history expansion
shopt -u histexpand 2>/dev/null || true  # Additional protection against history expansion

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
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/research_state_id.txt"
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

COMMAND_NAME="/research"
USER_ARGS="${WORKFLOW_DESCRIPTION:-}"
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
  # Log additional context for debugging agent failures
  AGENT_OUTPUT_EXISTS="false"
  AGENT_FILE_SIZE=0
  if [ -f "$TOPIC_NAME_FILE" ]; then
    AGENT_OUTPUT_EXISTS="true"
    AGENT_FILE_SIZE=$(wc -c < "$TOPIC_NAME_FILE" 2>/dev/null || echo 0)
  fi

  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "Topic naming agent failed to create valid output file" \
    "bash_block_1c" \
    "$(jq -n --arg path "$TOPIC_NAME_FILE" \
             --arg exists "$AGENT_OUTPUT_EXISTS" \
             --argjson size "$AGENT_FILE_SIZE" \
             --arg min_size "10" \
       '{expected_path: $path, file_exists: $exists, file_size_bytes: $size, min_required_bytes: $min_size, fallback: "no_name_error"}')"

  echo "ERROR: HARD BARRIER FAILED - Topic naming agent validation failed" >&2
  echo "" >&2
  echo "This indicates the topic-naming-agent did not create valid output." >&2
  echo "  Expected path: $TOPIC_NAME_FILE" >&2
  echo "  File exists: $AGENT_OUTPUT_EXISTS" >&2
  echo "  File size: $AGENT_FILE_SIZE bytes (minimum: 10 bytes)" >&2
  echo "" >&2
  echo "The workflow will fall back to 'no_name_error' directory." >&2
  echo "" >&2
  echo "To retry: Re-run the /research command with the same arguments" >&2
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
shopt -u histexpand 2>/dev/null || true  # Additional protection against history expansion

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

# === RESTORE STATE FROM BLOCK 1A ===
# Use CLAUDE_PROJECT_DIR for consistent path (matches init_workflow_state)
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/research_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)

if [ -z "$WORKFLOW_ID" ]; then
  echo "ERROR: Failed to restore WORKFLOW_ID from Block 1a" >&2
  exit 1
fi

# Restore workflow state file (naming convention: workflow_${WORKFLOW_ID}.sh)
# CRITICAL: Use CLAUDE_PROJECT_DIR to match init_workflow_state() path
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE"
else
  echo "ERROR: State file not found: $STATE_FILE" >&2
  exit 1
fi

# === DEFENSIVE VARIABLE INITIALIZATION ===
# Initialize potentially unbound variables with defaults to prevent unbound variable errors
# These variables may not be set in state file depending on user input
ORIGINAL_PROMPT_FILE_PATH="${ORIGINAL_PROMPT_FILE_PATH:-}"
RESEARCH_COMPLEXITY="${RESEARCH_COMPLEXITY:-2}"
WORKFLOW_DESCRIPTION="${WORKFLOW_DESCRIPTION:-}"

# WORKFLOW_DESCRIPTION should be in state file, but also check temp file as backup
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
# NOTE: Use ${WORKFLOW_DESCRIPTION:-} pattern to prevent unbound variable error
TOPIC_NAMING_INPUT_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/topic_naming_input_${WORKFLOW_ID}.txt"
if [ -z "${WORKFLOW_DESCRIPTION:-}" ] && [ -f "$TOPIC_NAMING_INPUT_FILE" ]; then
  WORKFLOW_DESCRIPTION=$(cat "$TOPIC_NAMING_INPUT_FILE" 2>/dev/null)
fi

if [ -z "${WORKFLOW_DESCRIPTION:-}" ]; then
  echo "ERROR: WHICH: WORKFLOW_DESCRIPTION | WHAT: Variable not restored from state file or backup | WHERE: /research Block 1c" >&2
  exit 1
fi

COMMAND_NAME="/research"
USER_ARGS="$WORKFLOW_DESCRIPTION"
export COMMAND_NAME USER_ARGS

# Source libraries (three-tier pattern)
# Tier 1: Critical Foundation (fail-fast required)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}

# Tier 2: Workflow Support (graceful degradation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || true

# Validate append_workflow_state is available (fail-fast)
type append_workflow_state >/dev/null 2>&1 || {
  echo "ERROR: append_workflow_state function not available after sourcing state-persistence.sh" >&2
  exit 1
}

# Setup bash error trap
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

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
        "$USER_ARGS" \
        "validation_error" \
        "Topic naming agent returned invalid format" \
        "bash_block_1c" \
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

# Log naming failure if we fell back to no_name
if [ "$TOPIC_NAME" = "no_name_error" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "Topic naming agent failed or returned invalid name" \
    "bash_block_1c" \
    "$(jq -n --arg desc "$WORKFLOW_DESCRIPTION" --arg strategy "$NAMING_STRATEGY" \
       '{description: $desc, fallback_reason: $strategy}')"
fi

# Clean up temp file
rm -f "$TOPIC_NAME_FILE" 2>/dev/null || true

# Create classification result JSON for initialize_workflow_paths
CLASSIFICATION_JSON=$(jq -n --arg slug "$TOPIC_NAME" '{topic_directory_slug: $slug}')

# Initialize workflow paths with LLM-generated name (or fallback)
initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "research-only" "$RESEARCH_COMPLEXITY" "$CLASSIFICATION_JSON"
INIT_EXIT=$?
if [ $INIT_EXIT -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "Failed to initialize workflow paths" \
    "bash_block_1c" \
    "$(jq -n --arg desc "$WORKFLOW_DESCRIPTION" '{description: $desc}')"

  echo "ERROR: Failed to initialize workflow paths" >&2
  exit 1
fi

RESEARCH_DIR="${TOPIC_PATH}/reports"

# === ARCHIVE PROMPT FILE (if --file was used) ===
ARCHIVED_PROMPT_PATH=""
if [ -n "${ORIGINAL_PROMPT_FILE_PATH:-}" ] && [ -f "${ORIGINAL_PROMPT_FILE_PATH:-}" ]; then
  mkdir -p "${TOPIC_PATH}/prompts"
  ARCHIVED_PROMPT_PATH="${TOPIC_PATH}/prompts/$(basename "${ORIGINAL_PROMPT_FILE_PATH:-}")"
  mv "${ORIGINAL_PROMPT_FILE_PATH:-}" "$ARCHIVED_PROMPT_PATH"
  echo "Prompt file archived: $ARCHIVED_PROMPT_PATH"
fi

# === PERSIST FOR BLOCK 2 ===
append_workflow_state "CLAUDE_PROJECT_DIR" "$CLAUDE_PROJECT_DIR"
append_workflow_state "RESEARCH_DIR" "$RESEARCH_DIR"
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
append_workflow_state "TOPIC_NAME" "$TOPIC_NAME"
append_workflow_state "WORKFLOW_DESCRIPTION" "$WORKFLOW_DESCRIPTION"
append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"
append_workflow_state "ORIGINAL_PROMPT_FILE_PATH" "${ORIGINAL_PROMPT_FILE_PATH:-}"
append_workflow_state "ARCHIVED_PROMPT_PATH" "${ARCHIVED_PROMPT_PATH:-}"
append_workflow_state "COMMAND_NAME" "$COMMAND_NAME"
append_workflow_state "USER_ARGS" "$USER_ARGS"
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"

echo "Setup complete: $WORKFLOW_ID (research-only, complexity: $RESEARCH_COMPLEXITY)"
echo "Research directory: $RESEARCH_DIR"
echo "Topic name: $TOPIC_NAME (strategy: $NAMING_STRATEGY)"
```

## Block 1d-topics: Topic Decomposition

**EXECUTE NOW**: Analyze research request for multi-topic indicators and decompose if needed.

```bash
set +H  # CRITICAL: Disable history expansion
shopt -u histexpand 2>/dev/null || true  # Additional protection against history expansion

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

# === RESTORE STATE ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/research_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)

if [ -z "$WORKFLOW_ID" ]; then
  echo "ERROR: Failed to restore WORKFLOW_ID" >&2
  exit 1
fi

STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE"
else
  echo "ERROR: State file not found: $STATE_FILE" >&2
  exit 1
fi

COMMAND_NAME="/research"
USER_ARGS="${WORKFLOW_DESCRIPTION:-}"
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

echo ""
echo "=== Topic Decomposition ==="
echo ""

# === ANALYZE RESEARCH REQUEST FOR MULTI-TOPIC INDICATORS ===
# Use complexity to determine if multi-topic decomposition is warranted
USE_MULTI_TOPIC=false
TOPIC_COUNT=1

# Complexity-based topic count mapping
if [ "${RESEARCH_COMPLEXITY:-2}" -ge 3 ]; then
  USE_MULTI_TOPIC=true
  if [ "${RESEARCH_COMPLEXITY:-2}" -eq 3 ]; then
    TOPIC_COUNT=2  # 2-3 topics for complexity 3
  else
    TOPIC_COUNT=3  # 3-4 topics for complexity 4
  fi
fi

# Additional heuristic checks for multi-topic indicators
if [ "$USE_MULTI_TOPIC" = "false" ]; then
  # Check for conjunctions or multi-topic patterns in description
  if echo "$WORKFLOW_DESCRIPTION" | grep -qiE " and | or |, .+ and |, .+ or "; then
    USE_MULTI_TOPIC=true
    TOPIC_COUNT=2
    echo "Detected multi-topic pattern in description (conjunctions found)"
  fi
fi

echo "Research complexity: $RESEARCH_COMPLEXITY"
echo "Multi-topic decomposition: $USE_MULTI_TOPIC"
echo "Target topic count: $TOPIC_COUNT"

# === DECOMPOSE TOPICS (simple heuristic-based) ===
if [ "$USE_MULTI_TOPIC" = "true" ]; then
  echo ""
  echo "Decomposing research request into $TOPIC_COUNT topics..."

  # Simple decomposition based on conjunctions and commas
  # Convert to array by splitting on " and ", " or ", ","
  TOPICS_ARRAY=()

  # Split on common delimiters
  IFS=',' read -ra PARTS <<< "$WORKFLOW_DESCRIPTION"
  for part in "${PARTS[@]}"; do
    # Further split on " and " and " or "
    IFS=' and ' read -ra SUB_PARTS <<< "$part"
    for subpart in "${SUB_PARTS[@]}"; do
      IFS=' or ' read -ra SUB_SUB_PARTS <<< "$subpart"
      for topic in "${SUB_SUB_PARTS[@]}"; do
        # Trim whitespace and add to array
        topic=$(echo "$topic" | xargs)
        if [ -n "$topic" ] && [ ${#TOPICS_ARRAY[@]} -lt "$TOPIC_COUNT" ]; then
          TOPICS_ARRAY+=("$topic")
        fi
      done
    done
  done

  # If decomposition produced fewer topics than target, use single topic
  if [ ${#TOPICS_ARRAY[@]} -lt 2 ]; then
    echo "Decomposition produced ${#TOPICS_ARRAY[@]} topics (less than 2), falling back to single-topic mode"
    USE_MULTI_TOPIC=false
    TOPICS_ARRAY=("$WORKFLOW_DESCRIPTION")
  else
    echo "Decomposed into ${#TOPICS_ARRAY[@]} topics:"
    for i in "${!TOPICS_ARRAY[@]}"; do
      echo "  $((i+1)). ${TOPICS_ARRAY[$i]}"
    done
  fi
else
  # Single topic mode
  TOPICS_ARRAY=("$WORKFLOW_DESCRIPTION")
  echo "Using single-topic mode (complexity ${RESEARCH_COMPLEXITY:-2})"
fi

# === PRE-CALCULATE REPORT PATHS FOR EACH TOPIC ===
echo ""
echo "Pre-calculating report paths..."

# Find existing reports to determine starting number
EXISTING_REPORTS=$(find "$RESEARCH_DIR" -name '[0-9][0-9][0-9]-*.md' 2>/dev/null | wc -l)
START_NUM=$((EXISTING_REPORTS + 1))

REPORT_PATHS_ARRAY=()
for i in "${!TOPICS_ARRAY[@]}"; do
  TOPIC="${TOPICS_ARRAY[$i]}"
  REPORT_NUM=$(printf "%03d" $((START_NUM + i)))

  # Generate slug from topic (max 40 chars, kebab-case)
  REPORT_SLUG=$(echo "$TOPIC" | head -c 40 | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')

  # Fallback if slug is empty
  if [ -z "$REPORT_SLUG" ]; then
    REPORT_SLUG="research-topic-$((i+1))"
  fi

  REPORT_PATH="${RESEARCH_DIR}/${REPORT_NUM}-${REPORT_SLUG}.md"
  REPORT_PATHS_ARRAY+=("$REPORT_PATH")

  echo "  $REPORT_NUM: $REPORT_PATH"
done

# === PERSIST FOR BLOCK 1d-exec ===
# Save topics and paths to state
append_workflow_state "USE_MULTI_TOPIC" "$USE_MULTI_TOPIC"
append_workflow_state "TOPIC_COUNT" "${#TOPICS_ARRAY[@]}"

# Save topics array (space-separated for state file)
TOPICS_LIST=$(printf "%s|" "${TOPICS_ARRAY[@]}")
TOPICS_LIST="${TOPICS_LIST%|}"  # Remove trailing pipe
append_workflow_state "TOPICS_LIST" "$TOPICS_LIST"

# Save report paths array (space-separated for state file)
REPORT_PATHS_LIST=$(printf "%s|" "${REPORT_PATHS_ARRAY[@]}")
REPORT_PATHS_LIST="${REPORT_PATHS_LIST%|}"  # Remove trailing pipe
append_workflow_state "REPORT_PATHS_LIST" "$REPORT_PATHS_LIST"

echo ""
echo "✓ Topic decomposition complete (${#TOPICS_ARRAY[@]} topics, ${#REPORT_PATHS_ARRAY[@]} reports)"
```

## Block 1d: Report Path Pre-Calculation

**EXECUTE NOW**: Pre-calculate the absolute report path before invoking research-specialist.

This implements the **hard barrier pattern** - the report path is calculated BEFORE subagent invocation, passed as an explicit contract, and validated AFTER return.

```bash
set +H  # CRITICAL: Disable history expansion
shopt -u histexpand 2>/dev/null || true  # Additional protection against history expansion

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
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/research_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)

if [ -z "$WORKFLOW_ID" ]; then
  echo "ERROR: Failed to restore WORKFLOW_ID from Block 1c" >&2
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

COMMAND_NAME="/research"
USER_ARGS="${WORKFLOW_DESCRIPTION:-}"
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

# Verify critical functions are available after sourcing
type append_workflow_state >/dev/null 2>&1 || {
  echo "ERROR: append_workflow_state function not defined after sourcing state-persistence.sh" >&2
  exit 1
}
type setup_bash_error_trap >/dev/null 2>&1 || {
  echo "ERROR: setup_bash_error_trap function not defined after sourcing error-handling.sh" >&2
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
    "RESEARCH_DIR not set from Block 1c" \
    "bash_block_1d" \
    "$(jq -n '{research_dir: "missing"}')"
  echo "ERROR: RESEARCH_DIR not set" >&2
  exit 1
fi

# Calculate report number (001, 002, 003...)
# Lazy directory creation: Create RESEARCH_DIR before find command to prevent exit code 1 errors
mkdir -p "$RESEARCH_DIR" 2>/dev/null || {
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "Failed to create RESEARCH_DIR" \
    "bash_block_1d" \
    "$(jq -n --arg dir "$RESEARCH_DIR" '{research_dir: $dir}')"
  echo "WARNING: Failed to create RESEARCH_DIR: $RESEARCH_DIR" >&2
  EXISTING_REPORTS=0
}

# Validate directory exists before find command
if ! validate_directory_var "RESEARCH_DIR" "research reports"; then
  EXISTING_REPORTS=0
else
  # Apply 4-step sanitization pattern (defensive-programming.md Section 6)
  EXISTING_REPORTS=$(find "$RESEARCH_DIR" -name '[0-9][0-9][0-9]-*.md' 2>/dev/null | wc -l)
  EXISTING_REPORTS=$(echo "$EXISTING_REPORTS" | tr -d '\n' | tr -d ' ')
  EXISTING_REPORTS=${EXISTING_REPORTS:-0}
  [[ "$EXISTING_REPORTS" =~ ^[0-9]+$ ]] || EXISTING_REPORTS=0
fi
REPORT_NUMBER=$(printf "%03d" $((EXISTING_REPORTS + 1)))

# Generate report slug from workflow description (max 40 chars, kebab-case)
REPORT_SLUG=$(echo "${WORKFLOW_DESCRIPTION:-research}" | head -c 40 | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')

# Fallback if slug is empty after sanitization
if [ -z "$REPORT_SLUG" ]; then
  REPORT_SLUG="research-report"
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
    "bash_block_1d" \
    "$(jq -n --arg path "$REPORT_PATH" '{report_path: $path}')"
  echo "ERROR: REPORT_PATH is not absolute: $REPORT_PATH" >&2
  exit 1
fi

# Ensure parent directory exists
mkdir -p "$(dirname "$REPORT_PATH")" 2>/dev/null || true

# Persist for Block 1e validation
append_workflow_state "REPORT_PATH" "$REPORT_PATH"
append_workflow_state "REPORT_NUMBER" "$REPORT_NUMBER"
append_workflow_state "REPORT_SLUG" "$REPORT_SLUG"

echo ""
echo "=== Report Path Pre-Calculation ==="
echo "  Report Number: $REPORT_NUMBER"
echo "  Report Slug: $REPORT_SLUG"
echo "  Report Path: $REPORT_PATH"
echo ""
echo "Ready for research-specialist invocation"
```

## Block 1d-exec: Research Coordinator Invocation

**HARD BARRIER - Research Coordinator Invocation**

**EXECUTE NOW**: USE the Task tool to invoke the research-coordinator agent. This invocation is MANDATORY. The orchestrator MUST NOT perform research work directly. After the agent returns, Block 1e will verify all reports were created at the pre-calculated paths.

Task {
  subagent_type: "general-purpose"
  description: "Coordinate multi-topic research for ${WORKFLOW_DESCRIPTION} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-coordinator.md

    You are coordinating research for: research workflow

    **Input Contract (Hard Barrier Pattern - Mode 2: Pre-Decomposed)**:
    - research_request: ${WORKFLOW_DESCRIPTION}
    - research_complexity: ${RESEARCH_COMPLEXITY}
    - report_dir: ${RESEARCH_DIR}
    - topic_path: ${TOPIC_PATH}
    - topics: ${TOPICS_LIST}
    - report_paths: ${REPORT_PATHS_LIST}
    - Workflow Type: research-only
    - Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH:-none}
    - Archived Prompt File: ${ARCHIVED_PROMPT_PATH:-none}

    **CRITICAL**: Topics and report paths have been pre-calculated by the primary agent.
    Use Mode 2 (Pre-Decomposed) - parse TOPICS_LIST and REPORT_PATHS_LIST (pipe-separated).
    You MUST coordinate research-specialist invocation for each topic and ensure report files
    are created at the EXACT paths specified above.

    The orchestrator has pre-calculated these paths and will validate they exist after you return.

    If an archived prompt file is provided (not 'none'), pass it to research-specialist for complete context.

    Execute research coordination according to behavioral guidelines:
    1. Parse topics and report_paths from pipe-separated lists
    2. Invoke research-specialist for each topic (parallel execution)
    3. Validate all reports created (hard barrier)
    4. Extract metadata from each report
    5. Return completion signal with aggregated metadata

    Return completion signal:
    RESEARCH_COMPLETE: ${TOPIC_COUNT} reports created
  "
}

## Block 1e: Agent Output Validation (Hard Barrier)

**EXECUTE NOW**: Validate that research-coordinator created all reports at the pre-calculated paths.

This is the **hard barrier** - the workflow CANNOT proceed to Block 2 unless ALL report files exist. This architectural enforcement prevents the primary agent from bypassing subagent delegation.

```bash
set +H  # CRITICAL: Disable history expansion
shopt -u histexpand 2>/dev/null || true  # Additional protection against history expansion

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

# === RESTORE STATE FROM BLOCK 1D ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/research_state_id.txt"
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

COMMAND_NAME="/research"
USER_ARGS="${WORKFLOW_DESCRIPTION:-}"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Setup bash error trap
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# Flush any early errors
_flush_early_errors

echo ""
echo "=== Agent Output Validation (Hard Barrier) ==="
echo ""

# === HARD BARRIER VALIDATION (MULTI-REPORT) ===
# Validate REPORT_PATHS_LIST is set (from Block 1d-topics)
if [ -z "${REPORT_PATHS_LIST:-}" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "REPORT_PATHS_LIST not restored from Block 1d-topics state" \
    "bash_block_1e" \
    "$(jq -n '{report_paths_list: "missing"}')"
  echo "ERROR: REPORT_PATHS_LIST not set - state restoration failed" >&2
  exit 1
fi

# Parse report paths from pipe-separated list
IFS='|' read -ra REPORT_PATHS_ARRAY <<< "$REPORT_PATHS_LIST"

echo "Expected ${#REPORT_PATHS_ARRAY[@]} report file(s):"
for path in "${REPORT_PATHS_ARRAY[@]}"; do
  echo "  - $path"
done
echo ""

# === VALIDATE EACH REPORT (LOOP) ===
VALIDATION_FAILED=false
FAILED_REPORTS=()
TOTAL_SIZE=0

for REPORT_PATH in "${REPORT_PATHS_ARRAY[@]}"; do
  echo "Validating: $REPORT_PATH"

  # HARD BARRIER: Report file MUST exist
  if [ ! -f "$REPORT_PATH" ]; then
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "agent_error" \
      "research-coordinator failed to create report file" \
      "bash_block_1e" \
      "$(jq -n --arg path "$REPORT_PATH" '{expected_path: $path}')"

    echo "  ✗ ERROR: Report file not found" >&2
    VALIDATION_FAILED=true
    FAILED_REPORTS+=("$REPORT_PATH")
    continue
  fi

  # Validate report is not empty or too small
  REPORT_SIZE=$(wc -c < "$REPORT_PATH" 2>/dev/null || echo 0)
  if [ "$REPORT_SIZE" -lt 100 ]; then
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "validation_error" \
      "Report file too small (agent may have failed during write)" \
      "bash_block_1e" \
      "$(jq -n --arg path "$REPORT_PATH" --argjson size "$REPORT_SIZE" '{report_path: $path, size_bytes: $size, min_required: 100}')"

    echo "  ✗ ERROR: Report file too small ($REPORT_SIZE bytes, expected >100)" >&2
    VALIDATION_FAILED=true
    FAILED_REPORTS+=("$REPORT_PATH")
    continue
  fi

  # Validate report contains required sections (basic content check)
  if ! grep -q "## Findings" "$REPORT_PATH" 2>/dev/null; then
    echo "  ⚠ WARNING: Report missing '## Findings' section (may be incomplete)" >&2
    # Non-fatal: continue but log warning
  fi

  TOTAL_SIZE=$((TOTAL_SIZE + REPORT_SIZE))
  echo "  ✓ Valid ($REPORT_SIZE bytes)"
done

# === FAIL-FAST IF ANY REPORTS MISSING ===
if [ "$VALIDATION_FAILED" = "true" ]; then
  echo "" >&2
  echo "ERROR: HARD BARRIER FAILED - ${#FAILED_REPORTS[@]} report(s) missing or invalid" >&2
  echo "" >&2
  echo "Failed reports:" >&2
  for failed in "${FAILED_REPORTS[@]}"; do
    echo "  - $failed" >&2
  done
  echo "" >&2
  echo "This indicates the research-coordinator did not create all expected artifacts." >&2
  echo "The workflow cannot proceed without all research reports." >&2
  echo "" >&2
  echo "Troubleshooting:" >&2
  echo "  1. Check research-coordinator agent output for errors" >&2
  echo "  2. Verify Task invocation in Block 1d-exec executed correctly" >&2
  echo "  3. Run /errors --command /research for detailed error logs" >&2
  exit 1
fi

echo ""
echo "✓ All reports validated: ${#REPORT_PATHS_ARRAY[@]} files ($TOTAL_SIZE bytes total)"
echo ""
echo "Hard barrier passed - proceeding to Block 2"
```

## Block 2: Verification and Completion

**EXECUTE NOW**: Verify research artifacts and complete workflow:

```bash
set +H  # CRITICAL: Disable history expansion
shopt -u histexpand 2>/dev/null || true  # Additional protection against history expansion

# === PRE-TRAP ERROR BUFFER ===
# Initialize error buffer BEFORE any library sourcing
declare -a _EARLY_ERROR_BUFFER=()

# === DEFENSIVE TRAP SETUP ===
# Set minimal trap BEFORE library sourcing to catch early errors
trap 'echo "ERROR: Block 2 initialization failed at line $LINENO: $BASH_COMMAND (exit code: $?)" >&2; exit 1' ERR
trap 'local exit_code=$?; if [ $exit_code -ne 0 ]; then echo "ERROR: Block 2 initialization exited with code $exit_code" >&2; fi' EXIT

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
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path (matches Block 1a)
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/research_state_id.txt"
if [ ! -f "$STATE_ID_FILE" ]; then
  echo "ERROR: WORKFLOW_ID file not found" >&2
  exit 1
fi
WORKFLOW_ID=$(cat "$STATE_ID_FILE")

# Source error-handling.sh FIRST to enable validation functions
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Validate and correct WORKFLOW_ID if needed
WORKFLOW_ID=$(validate_workflow_id "$WORKFLOW_ID" "research")
export WORKFLOW_ID

# Source remaining libraries with diagnostics
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" || exit 1

# Initialize DEBUG_LOG if not already set
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
DEBUG_LOG="${DEBUG_LOG:-${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_debug.log}"
mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null

load_workflow_state "$WORKFLOW_ID" false

# Validate critical variables restored from state
validate_state_restoration "COMMAND_NAME" "USER_ARGS" "STATE_FILE" "RESEARCH_DIR" || {
  echo "ERROR: State restoration failed - critical variables missing" >&2
  exit 1
}

# === RESTORE ERROR LOGGING CONTEXT ===
if [ -z "${COMMAND_NAME:-}" ]; then
  if [[ -f "$STATE_FILE" && -s "$STATE_FILE" ]]; then
    COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" | cut -d'=' -f2- || echo "/research")
  else
    COMMAND_NAME="/research"
  fi
fi
if [ -z "${USER_ARGS:-}" ]; then
  if [[ -f "$STATE_FILE" && -s "$STATE_FILE" ]]; then
    USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" | cut -d'=' -f2- || echo "")
  else
    USER_ARGS=""
  fi
fi
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# === SETUP BASH ERROR TRAP ===
# Clear defensive trap before setting up full trap
_clear_defensive_trap

setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# Flush any early errors captured before trap was active
_flush_early_errors

# Validate RESEARCH_DIR is non-empty (additional check beyond state restoration)
if [ -z "$RESEARCH_DIR" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "Critical variables not restored from state" \
    "bash_block_2" \
    "$(jq -n --arg dir "${RESEARCH_DIR:-MISSING}" '{research_dir: $dir}')"

  {
    echo "[$(date)] ERROR: Critical variables not restored"
    echo "WHICH: load_workflow_state"
    echo "WHAT: RESEARCH_DIR missing after load"
    echo "WHERE: Block 2, research verification"
    echo "RESEARCH_DIR: ${RESEARCH_DIR:-MISSING}"
  } >> "$DEBUG_LOG"
  echo "ERROR: Critical variables not restored (see $DEBUG_LOG)" >&2
  exit 1
fi

# === VERIFY ARTIFACTS (Defensive Validation) ===
# NOTE: Block 1e provides primary hard barrier validation for REPORT_PATH.
# This block provides secondary defensive checks for edge cases and directory-level verification.
echo "Verifying research artifacts (defensive validation)..."

# Defensive: Directory existence check
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

# Defensive: General file existence check (Block 1e validated specific REPORT_PATH)
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

# Defensive: Undersized file check (catches edge cases Block 1e might miss)
UNDERSIZED_FILES=$(find "$RESEARCH_DIR" -name '*.md' -type f -size -100c 2>/dev/null)
if [ -n "$UNDERSIZED_FILES" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Research report(s) too small" \
    "bash_block_2" \
    "$(jq -n --arg files "$UNDERSIZED_FILES" '{undersized_files: $files, min_size: 100}')"

  echo "ERROR: Research report(s) too small (< 100 bytes)" >&2
  exit 1
fi

# Apply 4-step sanitization pattern (defensive-programming.md Section 6)
REPORT_COUNT=$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null | wc -l)
REPORT_COUNT=$(echo "$REPORT_COUNT" | tr -d '\n' | tr -d ' ')
REPORT_COUNT=${REPORT_COUNT:-0}
[[ "$REPORT_COUNT" =~ ^[0-9]+$ ]] || REPORT_COUNT=0

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
    "bash_block_2" \
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

# Build summary text
SUMMARY_TEXT="Analyzed codebase and created $REPORT_COUNT research report(s) investigating ${WORKFLOW_DESCRIPTION}. Research provides foundation for creating implementation plan with evidence-based strategy selection."

# Build artifacts section
ARTIFACTS="  📊 Reports: $RESEARCH_DIR/ ($REPORT_COUNT files)"

# Build next steps
NEXT_STEPS="  • Review reports: ls -lh $RESEARCH_DIR/
  • Create implementation plan: /plan \"${WORKFLOW_DESCRIPTION}\"
  • Run full workflow: /coordinate \"${WORKFLOW_DESCRIPTION}\"
  • Run /todo to update TODO.md (adds research to tracking)"

# Print standardized summary (no phases for research command)
print_artifact_summary "Research" "$SUMMARY_TEXT" "" "$ARTIFACTS" "$NEXT_STEPS"

# Emit completion reminder
echo ""
echo "📋 Next Step: Run /todo to update TODO.md with this research"
echo ""

# === RETURN REPORT_CREATED SIGNAL ===
# Signal enables buffer-opener hook and orchestrator detection
# Get most recent report from research directory
LATEST_REPORT=$(ls -t "$RESEARCH_DIR"/*.md 2>/dev/null | head -1)
if [ -n "$LATEST_REPORT" ] && [ -f "$LATEST_REPORT" ]; then
  echo ""
  echo "REPORT_CREATED: $LATEST_REPORT"
  echo ""
fi

exit 0
```

---

**Troubleshooting**:

- **Research fails**: Check research-specialist agent behavioral file (`.claude/agents/research-specialist.md`) for compliance issues
- **No reports created**: Verify workflow description is clear and actionable
- **State machine errors**: Ensure library versions are compatible (workflow-state-machine.sh >=2.0.0)
- **Complexity too low**: Use `--complexity 3` or `--complexity 4` for more comprehensive research
- **File not found error**: Ensure --file path is correct and file exists; relative paths are resolved from current directory
- **Empty file warning**: The prompt file exists but has no content; add content to the file
- **State file not found (path mismatch)**: This error occurs when CLAUDE_PROJECT_DIR differs from HOME. All STATE_FILE paths must use `${CLAUDE_PROJECT_DIR}/.claude/tmp/`, not `${HOME}/.claude/tmp/`. Ensure CLAUDE_PROJECT_DIR detection happens before STATE_FILE path construction.
