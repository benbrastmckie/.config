---
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob, Write
argument-hint: <feature-description> [--file <path>] [--complexity 1-4]
description: Research and create new implementation plan workflow
command-type: primary
dependent-agents:
  - research-specialist
  - research-sub-supervisor
  - plan-architect
library-requirements:
  - workflow-state-machine.sh: ">=2.0.0"
  - state-persistence.sh: ">=1.5.0"
documentation: See .claude/docs/guides/commands/plan-command-guide.md for complete usage guide
---

# /plan - Research-and-Plan Workflow Command

YOU ARE EXECUTING a research-and-plan workflow that creates comprehensive research reports and then generates a new implementation plan based on those findings.

**Workflow Type**: research-and-plan
**Terminal State**: plan (after planning phase complete)
**Expected Output**: Research reports + implementation plan in .claude/specs/NNN_topic/

## Block 1a: Initial Setup and State Initialization

**EXECUTE NOW**: The user invoked `/plan "<feature-description>"`. Capture that description.

In the **bash block below**, replace `YOUR_FEATURE_DESCRIPTION_HERE` with the actual feature description (keeping the quotes).

**Example**: If user ran `/plan "implement user authentication with JWT tokens"`, change:
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
  echo "Usage: /plan \"<feature description>\"" >&2
  exit 1
fi

# Parse optional --complexity flag (default: 3 for research-and-plan)
DEFAULT_COMPLEXITY=3
RESEARCH_COMPLEXITY="$DEFAULT_COMPLEXITY"

if [[ "$FEATURE_DESCRIPTION" =~ --complexity[[:space:]]+([1-4]) ]]; then
  RESEARCH_COMPLEXITY="${BASH_REMATCH[1]}"
  FEATURE_DESCRIPTION=$(echo "$FEATURE_DESCRIPTION" | sed 's/--complexity[[:space:]]*[1-4]//' | xargs)
fi

if ! echo "$RESEARCH_COMPLEXITY" | grep -Eq "^[1-4]$"; then
  echo "ERROR: Invalid research complexity: $RESEARCH_COMPLEXITY (must be 1-4)" >&2
  exit 1
fi

# Parse optional --file flag for long prompts
ORIGINAL_PROMPT_FILE_PATH=""
if [[ "$FEATURE_DESCRIPTION" =~ --file[[:space:]]+([^[:space:]]+) ]]; then
  ORIGINAL_PROMPT_FILE_PATH="${BASH_REMATCH[1]}"
  # Convert to absolute path if relative (preprocessing-safe pattern)
  [[ "$ORIGINAL_PROMPT_FILE_PATH" = /* ]]
  IS_ABSOLUTE_PATH=$?
  if [ $IS_ABSOLUTE_PATH -ne 0 ]; then
    ORIGINAL_PROMPT_FILE_PATH="$(pwd)/$ORIGINAL_PROMPT_FILE_PATH"
  fi
  # Validate file exists
  if [ ! -f "$ORIGINAL_PROMPT_FILE_PATH" ]; then
    echo "ERROR: Prompt file not found: $ORIGINAL_PROMPT_FILE_PATH" >&2
    exit 1
  fi
  # Read file content into FEATURE_DESCRIPTION
  FEATURE_DESCRIPTION=$(cat "$ORIGINAL_PROMPT_FILE_PATH")
  if [ -z "$FEATURE_DESCRIPTION" ]; then
    echo "WARNING: Prompt file is empty: $ORIGINAL_PROMPT_FILE_PATH" >&2
  fi
elif [[ "$FEATURE_DESCRIPTION" =~ --file ]]; then
  echo "ERROR: --file flag requires a path argument" >&2
  echo "Usage: /plan --file /path/to/prompt.md" >&2
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

# === SOURCE LIBRARIES ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/library-version-check.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null
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

# === INITIALIZE STATE ===
WORKFLOW_TYPE="research-and-plan"
TERMINAL_STATE="plan"
COMMAND_NAME="/plan"
USER_ARGS="$FEATURE_DESCRIPTION"
export COMMAND_NAME USER_ARGS

WORKFLOW_ID="plan_$(date +%s)"
STATE_ID_FILE="${HOME}/.claude/tmp/plan_state_id.txt"
mkdir -p "$(dirname "$STATE_ID_FILE")"
echo "$WORKFLOW_ID" > "$STATE_ID_FILE"
export WORKFLOW_ID

# === SETUP BASH ERROR TRAP ===
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

# NEW: Verify state file contains required variables
if ! grep -q "WORKFLOW_ID=" "$STATE_FILE" 2>/dev/null; then
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

if ! sm_init "$FEATURE_DESCRIPTION" "$COMMAND_NAME" "$WORKFLOW_TYPE" "$RESEARCH_COMPLEXITY" "[]" 2>&1; then
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
if ! sm_transition "$STATE_RESEARCH" 2>&1; then
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
TOPIC_NAMING_INPUT_FILE="${HOME}/.claude/tmp/topic_naming_input_${WORKFLOW_ID}.txt"
echo "$FEATURE_DESCRIPTION" > "$TOPIC_NAMING_INPUT_FILE"
export TOPIC_NAMING_INPUT_FILE

echo "✓ Setup complete, ready for topic naming"
```

## Block 1b: Topic Name Generation

**EXECUTE NOW**: Invoke the topic-naming-agent to generate a semantic directory name.

Task {
  subagent_type: "general-purpose"
  description: "Generate semantic topic directory name"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/topic-naming-agent.md

    You are generating a topic directory name for: /plan command

    **Input**:
    - User Prompt: ${FEATURE_DESCRIPTION}
    - Command Name: /plan
    - OUTPUT_FILE_PATH: ${HOME}/.claude/tmp/topic_name_${WORKFLOW_ID}.txt

    Execute topic naming according to behavioral guidelines:
    1. Generate semantic topic name from user prompt
    2. Validate format (^[a-z0-9_]{5,40}$)
    3. Write topic name to OUTPUT_FILE_PATH using Write tool
    4. Return completion signal: TOPIC_NAME_GENERATED: <generated_name>

    If you encounter an error, return:
    TASK_ERROR: <error_type> - <error_message>
  "
}

## Block 1c: Topic Path Initialization

**EXECUTE NOW**: Parse topic name from agent output and initialize workflow paths.

```bash
set +H  # CRITICAL: Disable history expansion

# === RESTORE STATE FROM BLOCK 1A ===
STATE_ID_FILE="${HOME}/.claude/tmp/plan_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)

if [ -z "$WORKFLOW_ID" ]; then
  echo "ERROR: Failed to restore WORKFLOW_ID from Block 1a" >&2
  exit 1
fi

# Restore workflow state file
STATE_FILE="${HOME}/.claude/tmp/state_${WORKFLOW_ID}.sh"
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE"
else
  echo "ERROR: State file not found: $STATE_FILE" >&2
  exit 1
fi

# FEATURE_DESCRIPTION should be in state file, but also check temp file as backup
TOPIC_NAMING_INPUT_FILE="${HOME}/.claude/tmp/topic_naming_input_${WORKFLOW_ID}.txt"
if [ -z "$FEATURE_DESCRIPTION" ] && [ -f "$TOPIC_NAMING_INPUT_FILE" ]; then
  FEATURE_DESCRIPTION=$(cat "$TOPIC_NAMING_INPUT_FILE" 2>/dev/null)
fi

if [ -z "$FEATURE_DESCRIPTION" ]; then
  echo "ERROR: Failed to restore FEATURE_DESCRIPTION from Block 1a" >&2
  exit 1
fi

# Restore environment
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
COMMAND_NAME="/plan"
USER_ARGS="$FEATURE_DESCRIPTION"
export COMMAND_NAME USER_ARGS

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null

# === SETUP BASH ERROR TRAP ===
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# === READ TOPIC NAME FROM AGENT OUTPUT FILE ===
TOPIC_NAME_FILE="${HOME}/.claude/tmp/topic_name_${WORKFLOW_ID}.txt"
TOPIC_NAME="no_name"
NAMING_STRATEGY="fallback"

# Check if agent wrote output file
if [ -f "$TOPIC_NAME_FILE" ]; then
  # Read topic name from file (agent writes only the name, one line)
  TOPIC_NAME=$(cat "$TOPIC_NAME_FILE" 2>/dev/null | tr -d '\n' | tr -d ' ')

  if [ -z "$TOPIC_NAME" ]; then
    # File exists but is empty - agent failed
    NAMING_STRATEGY="agent_empty_output"
    TOPIC_NAME="no_name"
  elif ! echo "$TOPIC_NAME" | grep -Eq '^[a-z0-9_]{5,40}$'; then
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
    TOPIC_NAME="no_name"
  else
    # Valid topic name from LLM
    NAMING_STRATEGY="llm_generated"
  fi
else
  # File doesn't exist - agent failed to write
  NAMING_STRATEGY="agent_no_output_file"
fi

# Log naming failure if we fell back to no_name
if [ "$TOPIC_NAME" = "no_name" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "Topic naming agent failed or returned invalid name" \
    "bash_block_1c" \
    "$(jq -n --arg desc "$FEATURE_DESCRIPTION" --arg strategy "$NAMING_STRATEGY" \
       '{feature: $desc, fallback_reason: $strategy}')"
fi

# Clean up temp file
rm -f "$TOPIC_NAME_FILE" 2>/dev/null || true

# Create classification result JSON for initialize_workflow_paths
CLASSIFICATION_JSON=$(jq -n --arg slug "$TOPIC_NAME" '{topic_directory_slug: $slug}')

# Initialize workflow paths with LLM-generated name (or fallback)
if ! initialize_workflow_paths "$FEATURE_DESCRIPTION" "research-and-plan" "$RESEARCH_COMPLEXITY" "$CLASSIFICATION_JSON"; then
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
if [ -n "$ORIGINAL_PROMPT_FILE_PATH" ] && [ -f "$ORIGINAL_PROMPT_FILE_PATH" ]; then
  mkdir -p "${TOPIC_PATH}/prompts"
  ARCHIVED_PROMPT_PATH="${TOPIC_PATH}/prompts/$(basename "$ORIGINAL_PROMPT_FILE_PATH")"
  mv "$ORIGINAL_PROMPT_FILE_PATH" "$ARCHIVED_PROMPT_PATH"
  echo "Prompt file archived: $ARCHIVED_PROMPT_PATH"
fi

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
append_workflow_state "FEATURE_DESCRIPTION" "$FEATURE_DESCRIPTION"
append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"
append_workflow_state "ORIGINAL_PROMPT_FILE_PATH" "$ORIGINAL_PROMPT_FILE_PATH"
append_workflow_state "ARCHIVED_PROMPT_PATH" "${ARCHIVED_PROMPT_PATH:-}"

echo "Setup complete: $WORKFLOW_ID (research-and-plan, complexity: $RESEARCH_COMPLEXITY)"
echo "Research directory: $RESEARCH_DIR"
echo "Plans directory: $PLANS_DIR"
echo "Topic name: $TOPIC_NAME (strategy: $NAMING_STRATEGY)"
```

## Block 1d: Research Initiation

**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${FEATURE_DESCRIPTION} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are conducting research for: plan workflow

    **Workflow-Specific Context**:
    - Research Topic: ${FEATURE_DESCRIPTION}
    - Research Complexity: ${RESEARCH_COMPLEXITY}
    - Output Directory: ${RESEARCH_DIR}
    - Workflow Type: research-and-plan
    - Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH:-none}
    - Archived Prompt File: ${ARCHIVED_PROMPT_PATH:-none}

    If an archived prompt file is provided (not 'none'), read it for complete context.

    Execute research according to behavioral guidelines and return completion signal:
    REPORT_CREATED: [path to created report]
  "
}

## Block 2: Research Verification and Planning Setup

**EXECUTE NOW**: Verify research artifacts and prepare for planning:

```bash
set +H  # CRITICAL: Disable history expansion

# === LOAD STATE ===
STATE_ID_FILE="${HOME}/.claude/tmp/plan_state_id.txt"
if [ ! -f "$STATE_ID_FILE" ]; then
  echo "ERROR: WORKFLOW_ID file not found" >&2
  exit 1
fi
WORKFLOW_ID=$(cat "$STATE_ID_FILE")
export WORKFLOW_ID

# Detect project directory
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

source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null

# Initialize DEBUG_LOG if not already set
DEBUG_LOG="${DEBUG_LOG:-${HOME}/.claude/tmp/workflow_debug.log}"
mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null

load_workflow_state "$WORKFLOW_ID" false

# === RESTORE ERROR LOGGING CONTEXT ===
if [ -z "${COMMAND_NAME:-}" ]; then
  COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "/plan")
fi
if [ -z "${USER_ARGS:-}" ]; then
  USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "")
fi
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# === SETUP BASH ERROR TRAP ===
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

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

# Validate critical variables from Block 1
if [ -z "$TOPIC_PATH" ] || [ -z "$RESEARCH_DIR" ]; then
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
if ! sm_transition "$STATE_PLAN" 2>&1; then
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
PLAN_FILENAME="${PLAN_NUMBER}_$(echo "$TOPIC_NAME" | cut -c1-40)_plan.md"
PLAN_PATH="${PLANS_DIR}/${PLAN_FILENAME}"

# Collect research report paths
REPORT_PATHS=$(find "$RESEARCH_DIR" -name '*.md' -type f | sort)
REPORT_PATHS_JSON=$(echo "$REPORT_PATHS" | jq -R . | jq -s .)

# === PERSIST FOR BLOCK 3 ===
append_workflow_state "PLAN_PATH" "$PLAN_PATH"
append_workflow_state "REPORT_PATHS_JSON" "$REPORT_PATHS_JSON"

if ! save_completed_states_to_state; then
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
  description: "Create implementation plan for ${FEATURE_DESCRIPTION} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are creating an implementation plan for: plan workflow

    **Workflow-Specific Context**:
    - Feature Description: ${FEATURE_DESCRIPTION}
    - Output Path: ${PLAN_PATH}
    - Research Reports: ${REPORT_PATHS_JSON}
    - Workflow Type: research-and-plan
    - Operation Mode: new plan creation
    - Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH:-none}
    - Archived Prompt File: ${ARCHIVED_PROMPT_PATH:-none}

    If an archived prompt file is provided (not 'none'), reference it for complete context.

    Execute planning according to behavioral guidelines and return completion signal:
    PLAN_CREATED: ${PLAN_PATH}
  "
}

## Block 3: Plan Verification and Completion

**EXECUTE NOW**: Verify plan artifacts and complete workflow:

```bash
set +H  # CRITICAL: Disable history expansion

# === LOAD STATE ===
STATE_ID_FILE="${HOME}/.claude/tmp/plan_state_id.txt"
if [ ! -f "$STATE_ID_FILE" ]; then
  echo "ERROR: WORKFLOW_ID file not found" >&2
  exit 1
fi
WORKFLOW_ID=$(cat "$STATE_ID_FILE")
export WORKFLOW_ID

# Detect project directory
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

source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null

# Initialize DEBUG_LOG if not already set
DEBUG_LOG="${DEBUG_LOG:-${HOME}/.claude/tmp/workflow_debug.log}"
mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null

load_workflow_state "$WORKFLOW_ID" false

# === RESTORE ERROR LOGGING CONTEXT ===
if [ -z "${COMMAND_NAME:-}" ]; then
  COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "/plan")
fi
if [ -z "${USER_ARGS:-}" ]; then
  USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "")
fi
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# === SETUP BASH ERROR TRAP ===
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

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

# Validate PLAN_PATH was set by Block 2
if [ -z "$PLAN_PATH" ]; then
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
echo ""

# === COMPLETE WORKFLOW ===
if ! sm_transition "$STATE_COMPLETE" 2>&1; then
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

if ! save_completed_states_to_state; then
  log_command_error "state_error" "Failed to persist state transitions" "$(jq -n --arg file "${STATE_FILE:-unknown}" '{state_file: $file}')"
  echo "ERROR: State persistence failed" >&2
  exit 1
fi

if [ -n "${STATE_FILE:-}" ] && [ ! -f "$STATE_FILE" ]; then
  echo "WARNING: State file not found after save: $STATE_FILE" >&2
fi

echo "=== Research-and-Plan Complete ==="
echo ""
echo "Workflow Type: research-and-plan"
echo "Specs Directory: $SPECS_DIR"
echo "Research Reports: $REPORT_COUNT reports in $RESEARCH_DIR"
echo "Implementation Plan: $PLAN_PATH"
echo ""
echo "Next Steps:"
echo "- Review plan: cat $PLAN_PATH"
echo "- Implement plan: /build $PLAN_PATH"

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
