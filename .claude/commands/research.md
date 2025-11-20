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

## Block 1: Consolidated Setup

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

if ! echo "$RESEARCH_COMPLEXITY" | grep -Eq "^[1-4]$"; then
  echo "ERROR: Invalid research complexity: $RESEARCH_COMPLEXITY (must be 1-4)" >&2
  exit 1
fi

# Parse optional --file flag for long prompts
ORIGINAL_PROMPT_FILE_PATH=""
if [[ "$WORKFLOW_DESCRIPTION" =~ --file[[:space:]]+([^[:space:]]+) ]]; then
  ORIGINAL_PROMPT_FILE_PATH="${BASH_REMATCH[1]}"
  # Convert to absolute path if relative
  if [[ ! "$ORIGINAL_PROMPT_FILE_PATH" = /* ]]; then
    ORIGINAL_PROMPT_FILE_PATH="$(pwd)/$ORIGINAL_PROMPT_FILE_PATH"
  fi
  # Validate file exists
  if [ ! -f "$ORIGINAL_PROMPT_FILE_PATH" ]; then
    echo "ERROR: Prompt file not found: $ORIGINAL_PROMPT_FILE_PATH" >&2
    exit 1
  fi
  # Read file content into WORKFLOW_DESCRIPTION
  WORKFLOW_DESCRIPTION=$(cat "$ORIGINAL_PROMPT_FILE_PATH")
  if [ -z "$WORKFLOW_DESCRIPTION" ]; then
    echo "WARNING: Prompt file is empty: $ORIGINAL_PROMPT_FILE_PATH" >&2
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
WORKFLOW_TYPE="research-only"
TERMINAL_STATE="research"
COMMAND_NAME="/research"
USER_ARGS="$WORKFLOW_DESCRIPTION"
export COMMAND_NAME USER_ARGS

WORKFLOW_ID="research_$(date +%s)"
STATE_ID_FILE="${HOME}/.claude/tmp/research_state_id.txt"
mkdir -p "$(dirname "$STATE_ID_FILE")"
echo "$WORKFLOW_ID" > "$STATE_ID_FILE"
export WORKFLOW_ID

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

if ! sm_init "$WORKFLOW_DESCRIPTION" "$COMMAND_NAME" "$WORKFLOW_TYPE" "$RESEARCH_COMPLEXITY" "[]" 2>&1; then
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
    "bash_block_1" \
    "$(jq -n --arg state "$STATE_RESEARCH" '{target_state: $state}')"

  echo "ERROR: State transition to RESEARCH failed" >&2
  exit 1
fi

# Initialize workflow paths (uses fallback slug generation)
if ! initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "research-only" "$RESEARCH_COMPLEXITY" ""; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "Failed to initialize workflow paths" \
    "bash_block_1" \
    "$(jq -n --arg desc "$WORKFLOW_DESCRIPTION" '{description: $desc}')"

  echo "ERROR: Failed to initialize workflow paths" >&2
  exit 1
fi

RESEARCH_DIR="${TOPIC_PATH}/reports"
mkdir -p "$RESEARCH_DIR"

# === ARCHIVE PROMPT FILE (if --file was used) ===
ARCHIVED_PROMPT_PATH=""
if [ -n "$ORIGINAL_PROMPT_FILE_PATH" ] && [ -f "$ORIGINAL_PROMPT_FILE_PATH" ]; then
  mkdir -p "${TOPIC_PATH}/prompts"
  ARCHIVED_PROMPT_PATH="${TOPIC_PATH}/prompts/$(basename "$ORIGINAL_PROMPT_FILE_PATH")"
  mv "$ORIGINAL_PROMPT_FILE_PATH" "$ARCHIVED_PROMPT_PATH"
  echo "Prompt file archived: $ARCHIVED_PROMPT_PATH"
fi

# === PERSIST FOR BLOCK 2 ===
append_workflow_state "CLAUDE_PROJECT_DIR" "$CLAUDE_PROJECT_DIR"
append_workflow_state "RESEARCH_DIR" "$RESEARCH_DIR"
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
append_workflow_state "TOPIC_NAME" "$TOPIC_NAME"
append_workflow_state "WORKFLOW_DESCRIPTION" "$WORKFLOW_DESCRIPTION"
append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"
append_workflow_state "ORIGINAL_PROMPT_FILE_PATH" "$ORIGINAL_PROMPT_FILE_PATH"
append_workflow_state "ARCHIVED_PROMPT_PATH" "${ARCHIVED_PROMPT_PATH:-}"

echo "Setup complete: $WORKFLOW_ID (research-only, complexity: $RESEARCH_COMPLEXITY)"
echo "Research directory: $RESEARCH_DIR"
```

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

# === LOAD STATE ===
STATE_ID_FILE="${HOME}/.claude/tmp/research_state_id.txt"
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
if ! sm_transition "$STATE_COMPLETE" 2>&1; then
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

save_completed_states_to_state 2>/dev/null

echo ""
echo "=== Research Complete ==="
echo "Workflow Type: research-only"
echo "Reports Directory: $RESEARCH_DIR"
echo "Report Count: $REPORT_COUNT"
echo ""
echo "Next Steps:"
echo "- Review reports in: $RESEARCH_DIR"
echo "- Use /plan to create implementation plan from research"
echo "- Use /coordinate for full workflow (research + plan + implement)"

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
