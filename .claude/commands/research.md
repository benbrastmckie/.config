---
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob
argument-hint: <workflow-description> [--file <path>] [--complexity 1-4]
description: Research-only workflow - Creates comprehensive research reports without planning or implementation
command-type: primary
dependent-agents:
  - research-specialist
  - research-sub-supervisor
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
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/library-version-check.sh" 2>/dev/null || {
  echo "ERROR: Failed to source library-version-check.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Tier 2: Workflow Support (graceful degradation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh" 2>/dev/null || true
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || true

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

## Block 1b: Topic Name Generation

**EXECUTE NOW**: Invoke the topic-naming-agent to generate a semantic directory name.

Task {
  subagent_type: "general-purpose"
  description: "Generate semantic topic directory name"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/topic-naming-agent.md

    You are generating a topic directory name for: /research command

    **Input**:
    - User Prompt: ${WORKFLOW_DESCRIPTION}
    - Command Name: /research
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

## Block 1c: Topic Path Initialization

**EXECUTE NOW**: Parse topic name from agent output and initialize workflow paths.

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

# WORKFLOW_DESCRIPTION should be in state file, but also check temp file as backup
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
TOPIC_NAMING_INPUT_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/topic_naming_input_${WORKFLOW_ID}.txt"
if [ -z "$WORKFLOW_DESCRIPTION" ] && [ -f "$TOPIC_NAMING_INPUT_FILE" ]; then
  WORKFLOW_DESCRIPTION=$(cat "$TOPIC_NAMING_INPUT_FILE" 2>/dev/null)
fi

if [ -z "$WORKFLOW_DESCRIPTION" ]; then
  echo "ERROR: Failed to restore WORKFLOW_DESCRIPTION from Block 1a" >&2
  exit 1
fi

COMMAND_NAME="/research"
USER_ARGS="$WORKFLOW_DESCRIPTION"
export COMMAND_NAME USER_ARGS

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || true

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

## Block 1d: Research Initiation

**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${WORKFLOW_DESCRIPTION} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are conducting research for: research workflow

    **Workflow-Specific Context**:
    - Research Topic: ${WORKFLOW_DESCRIPTION}
    - Research Complexity: ${RESEARCH_COMPLEXITY}
    - Output Directory: ${RESEARCH_DIR}
    - Workflow Type: research-only
    - Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH:-none}
    - Archived Prompt File: ${ARCHIVED_PROMPT_PATH:-none}

    If an archived prompt file is provided (not 'none'), read it for complete context.

    Execute research according to behavioral guidelines and return completion signal:
    REPORT_CREATED: [path to created report]
  "
}

## Block 2: Verification and Completion

**EXECUTE NOW**: Verify research artifacts and complete workflow:

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
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path (matches Block 1a)
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/research_state_id.txt"
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

# Validate critical variables restored from state
validate_state_restoration "COMMAND_NAME" "USER_ARGS" "STATE_FILE" "RESEARCH_DIR" || {
  echo "ERROR: State restoration failed - critical variables missing" >&2
  exit 1
}

export COMMAND_NAME USER_ARGS WORKFLOW_ID

# === SETUP BASH ERROR TRAP ===
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

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

# === VERIFY ARTIFACTS ===
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
    "Research report(s) too small" \
    "bash_block_2" \
    "$(jq -n --arg files "$UNDERSIZED_FILES" '{undersized_files: $files, min_size: 100}')"

  echo "ERROR: Research report(s) too small (< 100 bytes)" >&2
  exit 1
fi

REPORT_COUNT=$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null | wc -l)

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
  • Run full workflow: /coordinate \"${WORKFLOW_DESCRIPTION}\""

# Print standardized summary (no phases for research command)
print_artifact_summary "Research" "$SUMMARY_TEXT" "" "$ARTIFACTS" "$NEXT_STEPS"

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
