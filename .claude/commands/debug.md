---
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob
argument-hint: <issue-description> [--file <path>] [--complexity 1-4]
description: Debug-focused workflow - Root cause analysis and bug fixing
command-type: primary
dependent-agents:
  - research-specialist
  - plan-architect
  - debug-analyst
library-requirements:
  - workflow-state-machine.sh: ">=2.0.0"
  - state-persistence.sh: ">=1.5.0"
documentation: See .claude/docs/guides/commands/debug-command-guide.md for complete usage guide
---

# /debug - Debug-Focused Workflow Command

YOU ARE EXECUTING a debug-focused workflow that investigates issues through research, creates a debug strategy plan, and performs root cause analysis with fixes.

**Workflow Type**: debug-only
**Terminal State**: debug (after debug analysis complete)
**Expected Output**: Debug reports, strategy plan, and root cause analysis

## Block 1: Capture Issue Description

**EXECUTE NOW**: Capture and validate the issue description:

```bash
set +H  # CRITICAL: Disable history expansion
set -e  # Fail-fast per code-standards.md

# Detect project directory for error logging
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; then
    [ -d "$current_dir/.claude" ] && { CLAUDE_PROJECT_DIR="$current_dir"; break; }
    current_dir="$(dirname "$current_dir")"
  done
fi

# Source error handling early for trap setup
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Cannot load error-handling library" >&2
  exit 1
}
ensure_error_log_exists

# Set initial command metadata for error logging
WORKFLOW_ID="debug_init_$(date +%s)"
COMMAND_NAME="/debug"
USER_ARGS="$*"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# Setup bash error trap
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

ISSUE_DESCRIPTION="$1"

if [ -z "$ISSUE_DESCRIPTION" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Issue description is required" \
    "bash_block_1" \
    "$(jq -n --arg args "${*:-}" --argjson count ${#:-0} \
       '{user_args: $args, provided_args_count: $count}')"

  cat <<'EOF' >&2
ERROR: Issue description required

USAGE: /debug <issue-description> [--file <path>] [--complexity 1-4]

EXAMPLES:
  /debug "Build command fails with exit code 127"
  /debug "Agent not returning expected output" --complexity 3
  /debug "Parser error in test suite" --file tests/parser-test.sh
EOF
  exit 1
fi

# Parse optional --complexity flag (default: 2 for debug-only)
DEFAULT_COMPLEXITY=2
RESEARCH_COMPLEXITY="$DEFAULT_COMPLEXITY"

if [[ "$ISSUE_DESCRIPTION" =~ --complexity[[:space:]]+([1-4]) ]]; then
  RESEARCH_COMPLEXITY="${BASH_REMATCH[1]}"
  ISSUE_DESCRIPTION=$(echo "$ISSUE_DESCRIPTION" | sed 's/--complexity[[:space:]]*[1-4]//' | xargs)
fi

echo "$RESEARCH_COMPLEXITY" | grep -Eq "^[1-4]$"
COMPLEXITY_VALID=$?
if [ $COMPLEXITY_VALID -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Invalid research complexity value" \
    "bash_block_1" \
    "$(jq -n --arg value "$RESEARCH_COMPLEXITY" --arg valid "1-4" \
       '{provided_value: $value, valid_range: $valid}')"

  echo "ERROR: Invalid research complexity: $RESEARCH_COMPLEXITY (must be 1-4)" >&2
  exit 1
fi

# Parse optional --file flag for long prompts
ORIGINAL_PROMPT_FILE_PATH=""
if [[ "$ISSUE_DESCRIPTION" =~ --file[[:space:]]+([^[:space:]]+) ]]; then
  ORIGINAL_PROMPT_FILE_PATH="${BASH_REMATCH[1]}"
  # Convert to absolute path if relative (preprocessing-safe pattern)
  [[ "${ORIGINAL_PROMPT_FILE_PATH:-}" = /* ]]
  IS_ABSOLUTE_PATH=$?
  if [ $IS_ABSOLUTE_PATH -ne 0 ]; then
    ORIGINAL_PROMPT_FILE_PATH="$(pwd)/${ORIGINAL_PROMPT_FILE_PATH:-}"
  fi
  # Validate file exists
  if [ ! -f "${ORIGINAL_PROMPT_FILE_PATH:-}" ]; then
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "validation_error" \
      "Prompt file not found" \
      "bash_block_1" \
      "$(jq -n --arg path "${ORIGINAL_PROMPT_FILE_PATH:-}" \
         '{file_path: $path, error: "file_not_found"}')"

    echo "ERROR: Prompt file not found: ${ORIGINAL_PROMPT_FILE_PATH:-}" >&2
    exit 1
  fi
  # Read file content into ISSUE_DESCRIPTION
  ISSUE_DESCRIPTION=$(cat "${ORIGINAL_PROMPT_FILE_PATH:-}")
  if [ -z "$ISSUE_DESCRIPTION" ]; then
    echo "WARNING: Prompt file is empty: ${ORIGINAL_PROMPT_FILE_PATH:-}" >&2
  fi
elif [[ "$ISSUE_DESCRIPTION" =~ --file ]]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "--file flag requires a path argument" \
    "bash_block_1" \
    "$(jq -n --arg args "${ISSUE_DESCRIPTION}" \
       '{user_args: $args, error: "missing_file_path"}')"

  echo "ERROR: --file flag requires a path argument" >&2
  echo "Usage: /debug --file /path/to/issue.md" >&2
  exit 1
fi

echo "=== Debug-Focused Workflow ==="
echo "Issue: $ISSUE_DESCRIPTION"
echo "Research Complexity: $RESEARCH_COMPLEXITY"
echo ""
```

## Block 2: State Machine Initialization

**EXECUTE NOW**: Initialize state machine and source required libraries:

```bash
set +H  # CRITICAL: Disable history expansion

# Initialize pre-trap error buffer BEFORE library sourcing
declare -a _EARLY_ERROR_BUFFER=()

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

if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1
fi

export CLAUDE_PROJECT_DIR

# Source error-handling.sh FIRST to enable diagnostic functions
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/todo/todo-functions.sh" 2>/dev/null || {
  echo "ERROR: Failed to source todo-functions.sh" >&2
  exit 1
}

# Source remaining libraries with diagnostics
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" || exit 1
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/library-version-check.sh" || exit 1

# === INITIALIZE ERROR LOGGING ===
ensure_error_log_exists

# === SETUP EARLY BASH ERROR TRAP ===
# CRITICAL FIX: Add early trap to catch errors in the 85-line gap before full trap setup
# This trap uses temporary metadata, will be replaced with actual values later
setup_bash_error_trap "/debug" "debug_early_$(date +%s)" "early_init"

# Flush any early errors captured before trap was active
_flush_early_errors

_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh" || exit 1
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" || exit 1

# Verify library versions
check_library_requirements "$(cat <<'EOF'
workflow-state-machine.sh: ">=2.0.0"
state-persistence.sh: ">=1.5.0"
EOF
)" || exit 1

# Hardcode workflow type
WORKFLOW_TYPE="debug-only"
TERMINAL_STATE="debug"
COMMAND_NAME="debug"

# Generate WORKFLOW_ID for state persistence
WORKFLOW_ID="debug_$(date +%s)"
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path (matches state file location)
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/debug_state_id.txt"
mkdir -p "$(dirname "$STATE_ID_FILE")"
echo "$WORKFLOW_ID" > "$STATE_ID_FILE"
export WORKFLOW_ID

# Set command metadata for error logging
COMMAND_NAME="/debug"
USER_ARGS="$ISSUE_DESCRIPTION"
export COMMAND_NAME USER_ARGS

# Capture state file path for append_workflow_state
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
export STATE_FILE

# === PERSIST ERROR LOGGING CONTEXT ===
append_workflow_state "COMMAND_NAME" "$COMMAND_NAME"
append_workflow_state "USER_ARGS" "$USER_ARGS"
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"

# === SETUP BASH ERROR TRAP ===
# Replace early trap with actual metadata
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# Flush any errors captured during initialization
_flush_early_errors

# Validate state file creation
if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "Failed to initialize workflow state file" \
    "bash_block_2" \
    "$(jq -n --arg path "${STATE_FILE:-UNDEFINED}" '{expected_path: $path}')"

  echo "ERROR: Failed to initialize workflow state" >&2
  exit 1
fi

# Initialize state machine with return code verification
sm_init \
  "$ISSUE_DESCRIPTION" \
  "$COMMAND_NAME" \
  "$WORKFLOW_TYPE" \
  "$RESEARCH_COMPLEXITY" \
  "[]" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State machine initialization failed" \
    "bash_block_2" \
    "$(jq -n --arg type "$WORKFLOW_TYPE" --argjson complexity "$RESEARCH_COMPLEXITY" \
       '{workflow_type: $type, complexity: $complexity}')"

  echo "ERROR: State machine initialization failed" >&2
  echo "DIAGNOSTIC Information:" >&2
  echo "  - Issue Description: $ISSUE_DESCRIPTION" >&2
  echo "  - Command Name: $COMMAND_NAME" >&2
  echo "  - Workflow Type: $WORKFLOW_TYPE" >&2
  echo "  - Research Complexity: $RESEARCH_COMPLEXITY" >&2
  echo "POSSIBLE CAUSES:" >&2
  echo "  - Library version incompatibility (require workflow-state-machine.sh >=2.0.0)" >&2
  echo "  - State file corruption in ~/.claude/data/state/" >&2
  exit 1
fi

echo "State machine initialized (WORKFLOW_ID: $WORKFLOW_ID)"
echo ""

# Persist CLAUDE_PROJECT_DIR and ISSUE_DESCRIPTION for subsequent bash blocks
append_workflow_state "CLAUDE_PROJECT_DIR" "$CLAUDE_PROJECT_DIR"
append_workflow_state "ISSUE_DESCRIPTION" "$ISSUE_DESCRIPTION"
append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"
```

## Block 2a: Topic Name Generation

**EXECUTE NOW**: USE the Task tool to invoke the topic-naming-agent for semantic topic directory naming.

Task {
  subagent_type: "general-purpose"
  description: "Generate semantic topic directory name"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/topic-naming-agent.md

    You are generating a topic directory name for: /debug command

    **Input**:
    - User Prompt: ${ISSUE_DESCRIPTION}
    - Command Name: /debug
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

**EXECUTE NOW**: Parse the topic name from agent output:

```bash
set +H  # CRITICAL: Disable history expansion

# Initialize pre-trap error buffer BEFORE library sourcing
declare -a _EARLY_ERROR_BUFFER=()

# === DEFENSIVE TRAP SETUP ===
# Set minimal trap BEFORE library sourcing to catch sourcing failures
trap 'echo "ERROR: Library sourcing failed at line $LINENO: $BASH_COMMAND" >&2; exit 1' ERR
trap 'if [ $? -ne 0 ]; then echo "ERROR: Block initialization failed" >&2; fi' EXIT

# Source error-handling.sh FIRST to enable diagnostic functions
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Replace remaining library sourcing with diagnostic wrapper
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" || exit 1
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" || exit 1

# Load WORKFLOW_ID from file
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/debug_state_id.txt"
if [ -f "$STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$STATE_ID_FILE")

  # Validate WORKFLOW_ID format
  validate_workflow_id "$WORKFLOW_ID" "/debug" || {
    WORKFLOW_ID="debug_$(date +%s)_recovered"
  }

  export WORKFLOW_ID
  load_workflow_state "$WORKFLOW_ID" false

  # Validate critical variables restored from state
  validate_state_restoration "COMMAND_NAME" "USER_ARGS" "STATE_FILE" || {
    echo "ERROR: State restoration failed - critical variables missing" >&2
    exit 1
  }

  export COMMAND_NAME USER_ARGS WORKFLOW_ID

  # === CLEAR DEFENSIVE TRAP ===
  _clear_defensive_trap

  # === SETUP BASH ERROR TRAP ===
  setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

  # Flush any early errors captured before trap was active
  _flush_early_errors

  # Initialize DEBUG_LOG using CLAUDE_PROJECT_DIR for consistent path
  DEBUG_LOG="${DEBUG_LOG:-${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_debug.log}"
  mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null
fi

# === DEFENSIVE CHECK: Verify initialize_workflow_paths available ===
type initialize_workflow_paths &>/dev/null
TYPE_CHECK=$?
if [ $TYPE_CHECK -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "dependency_error" \
    "initialize_workflow_paths function not available" \
    "bash_block_2a" \
    "$(jq -n '{missing_function: "initialize_workflow_paths", expected_library: "workflow-initialization.sh"}')"

  echo "ERROR: initialize_workflow_paths function not available" >&2
  echo "DIAGNOSTIC: workflow-initialization.sh library not properly sourced" >&2
  exit 1
fi

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
        "bash_block_2a" \
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
    "bash_block_2a" \
    "$(jq -n --arg desc "$ISSUE_DESCRIPTION" --arg strategy "$NAMING_STRATEGY" \
       '{issue: $desc, fallback_reason: $strategy}')"
fi

# Clean up temp file
rm -f "$TOPIC_NAME_FILE" 2>/dev/null || true

# Create classification result JSON for initialize_workflow_paths
CLASSIFICATION_JSON=$(jq -n --arg slug "$TOPIC_NAME" '{topic_directory_slug: $slug}')

# Persist classification for initialize_workflow_paths
append_workflow_state "CLASSIFICATION_JSON" "$CLASSIFICATION_JSON"
append_workflow_state "TOPIC_NAME" "$TOPIC_NAME"
append_workflow_state "NAMING_STRATEGY" "$NAMING_STRATEGY"

echo "✓ Topic naming complete: $TOPIC_NAME (strategy: $NAMING_STRATEGY)"
echo ""
```

## Block 3: Research Phase (Issue Investigation)

**EXECUTE NOW**: Transition to research state and allocate topic directory:

```bash
set +H  # CRITICAL: Disable history expansion

# Initialize pre-trap error buffer BEFORE library sourcing
declare -a _EARLY_ERROR_BUFFER=()

# === DEFENSIVE TRAP SETUP ===
# Set minimal trap BEFORE library sourcing to catch sourcing failures
trap 'echo "ERROR: Library sourcing failed at line $LINENO: $BASH_COMMAND" >&2; exit 1' ERR
trap 'if [ $? -ne 0 ]; then echo "ERROR: Block initialization failed" >&2; fi' EXIT

# Source error-handling.sh FIRST to enable diagnostic functions
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Replace remaining library sourcing with diagnostic wrapper
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" || exit 1
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh" || exit 1
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" || exit 1

# Load WORKFLOW_ID from file (fail-fast pattern)
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/debug_state_id.txt"
if [ -f "$STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$STATE_ID_FILE")

  # Validate WORKFLOW_ID format
  validate_workflow_id "$WORKFLOW_ID" "/debug" || {
    WORKFLOW_ID="debug_$(date +%s)_recovered"
  }

  export WORKFLOW_ID
  load_workflow_state "$WORKFLOW_ID" false

  # Validate critical variables restored from state
  validate_state_restoration "COMMAND_NAME" "USER_ARGS" "STATE_FILE" "ISSUE_DESCRIPTION" || {
    echo "ERROR: State restoration failed - critical variables missing" >&2
    exit 1
  }

  export COMMAND_NAME USER_ARGS WORKFLOW_ID

  # === CLEAR DEFENSIVE TRAP ===
  _clear_defensive_trap

  # === SETUP BASH ERROR TRAP ===
  setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

  # Flush any early errors captured before trap was active
  _flush_early_errors

  # Initialize DEBUG_LOG using CLAUDE_PROJECT_DIR for consistent path
  DEBUG_LOG="${DEBUG_LOG:-${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_debug.log}"
  mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null
fi

# Transition to research state with return code verification
sm_transition "$STATE_RESEARCH" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State transition to RESEARCH failed" \
    "bash_block_3" \
    "$(jq -n --arg state "RESEARCH" '{target_state: $state}')"

  echo "ERROR: State transition to RESEARCH failed" >&2
  echo "DIAGNOSTIC Information:" >&2
  echo "  - Current State: $(sm_current_state 2>/dev/null || echo 'unknown')" >&2
  echo "  - Attempted Transition: → RESEARCH" >&2
  echo "  - Workflow Type: debug-only" >&2
  echo "  - Issue: $ISSUE_DESCRIPTION" >&2
  echo "POSSIBLE CAUSES:" >&2
  echo "  - State machine not initialized properly" >&2
  echo "  - Workflow type misconfigured" >&2
  echo "  - State file corruption" >&2
  echo "TROUBLESHOOTING:" >&2
  echo "  - Verify sm_init called with debug-only workflow type" >&2
  echo "  - Check ~/.claude/data/state/ for corruption" >&2
  exit 1
fi
echo "=== Phase 1: Research (Issue Investigation) ==="
echo ""

# Load classification result from state (persisted in Part 2a)
CLASSIFICATION_JSON="${CLASSIFICATION_JSON:-}"

# === DEFENSIVE CHECK: Verify initialize_workflow_paths available ===
type initialize_workflow_paths &>/dev/null
TYPE_CHECK=$?
if [ $TYPE_CHECK -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "dependency_error" \
    "initialize_workflow_paths function not available" \
    "bash_block_3" \
    "$(jq -n '{missing_function: "initialize_workflow_paths", expected_library: "workflow-initialization.sh"}')"

  echo "ERROR: initialize_workflow_paths function not available" >&2
  echo "DIAGNOSTIC: workflow-initialization.sh library not properly sourced" >&2
  exit 1
fi

# Initialize workflow paths using semantic slug generation (Plan 777)
# This uses the three-tier fallback: LLM slug -> extract_significant_words -> sanitize_topic_name
initialize_workflow_paths "$ISSUE_DESCRIPTION" "debug-only" "$RESEARCH_COMPLEXITY" "$CLASSIFICATION_JSON"
INIT_EXIT=$?
if [ $INIT_EXIT -ne 0 ]; then
  echo "ERROR: Failed to initialize workflow paths"
  echo "DIAGNOSTIC: Check initialize_workflow_paths() in workflow-initialization.sh"
  exit 1
fi

# Map initialize_workflow_paths exports to expected variables
# The function exports: TOPIC_PATH, TOPIC_NAME, TOPIC_NUM, SPECS_ROOT, etc.
SPECS_DIR="$TOPIC_PATH"
RESEARCH_DIR="${TOPIC_PATH}/reports"
DEBUG_DIR="${TOPIC_PATH}/debug"
TOPIC_SLUG="$TOPIC_NAME"

# === ARCHIVE PROMPT FILE (if --file was used) ===
ARCHIVED_PROMPT_PATH=""
if [ -n "${ORIGINAL_PROMPT_FILE_PATH:-}" ] && [ -f "${ORIGINAL_PROMPT_FILE_PATH:-}" ]; then
  mkdir -p "${TOPIC_PATH}/prompts"
  ARCHIVED_PROMPT_PATH="${TOPIC_PATH}/prompts/$(basename "${ORIGINAL_PROMPT_FILE_PATH:-}")"
  mv "${ORIGINAL_PROMPT_FILE_PATH:-}" "$ARCHIVED_PROMPT_PATH"
  echo "Prompt file archived: $ARCHIVED_PROMPT_PATH"
fi

# Persist variables for next block and agent (legacy format for compatibility)
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
echo "SPECS_DIR=$SPECS_DIR" > "${CLAUDE_PROJECT_DIR}/.claude/tmp/debug_state_$$.txt"
echo "RESEARCH_DIR=$RESEARCH_DIR" >> "${CLAUDE_PROJECT_DIR}/.claude/tmp/debug_state_$$.txt"
echo "DEBUG_DIR=$DEBUG_DIR" >> "${CLAUDE_PROJECT_DIR}/.claude/tmp/debug_state_$$.txt"
echo "ISSUE_DESCRIPTION=$ISSUE_DESCRIPTION" >> "${CLAUDE_PROJECT_DIR}/.claude/tmp/debug_state_$$.txt"
echo "RESEARCH_COMPLEXITY=$RESEARCH_COMPLEXITY" >> "${CLAUDE_PROJECT_DIR}/.claude/tmp/debug_state_$$.txt"

# Also persist to workflow state for better isolation
append_workflow_state "SPECS_DIR" "$SPECS_DIR"
append_workflow_state "RESEARCH_DIR" "$RESEARCH_DIR"
append_workflow_state "DEBUG_DIR" "$DEBUG_DIR"
append_workflow_state "TOPIC_SLUG" "$TOPIC_SLUG"
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
append_workflow_state "ORIGINAL_PROMPT_FILE_PATH" "${ORIGINAL_PROMPT_FILE_PATH:-}"
append_workflow_state "ARCHIVED_PROMPT_PATH" "${ARCHIVED_PROMPT_PATH:-}"
```

**CRITICAL BARRIER - Research Delegation**

**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent. This invocation is MANDATORY. The orchestrator MUST NOT perform research work directly. Verification blocks will FAIL if research artifacts are not created by the specialist.

Task {
  subagent_type: "general-purpose"
  description: "Research root cause for $ISSUE_DESCRIPTION"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are conducting research for: debug workflow (root cause analysis)

    Input:
    - Research Topic: Root cause analysis for: $ISSUE_DESCRIPTION
    - Research Complexity: $RESEARCH_COMPLEXITY
    - Output Directory: $RESEARCH_DIR
    - Workflow Type: debug-only
    - Context Mode: root cause analysis
    - Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH:-none}
    - Archived Prompt File: ${ARCHIVED_PROMPT_PATH:-none}

    If an archived prompt file is provided (not 'none'), read it for complete context.

    Execute research according to behavioral guidelines.

    Return: REPORT_CREATED: {report_path}
  "
}

**EXECUTE NOW**: Verify research artifacts were created:

```bash
set +H  # CRITICAL: Disable history expansion
set -e  # Fail-fast per code-standards.md

# Re-source libraries for subprocess isolation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Load WORKFLOW_ID from file
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/debug_state_id.txt"
if [ -f "$STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$STATE_ID_FILE")
  export WORKFLOW_ID
  load_workflow_state "$WORKFLOW_ID" false

  # Restore error logging context
  if [ -z "${COMMAND_NAME:-}" ]; then
    COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "/debug")
  fi
  if [ -z "${USER_ARGS:-}" ]; then
    USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "")
  fi
  export COMMAND_NAME USER_ARGS WORKFLOW_ID

  # Setup bash error trap
  setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
fi

# Load state from previous block
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
source "${CLAUDE_PROJECT_DIR}/.claude/tmp/debug_state_$$.txt" 2>/dev/null || true

# MANDATORY VERIFICATION
echo "Verifying research artifacts..."

if [ ! -d "$RESEARCH_DIR" ]; then
  echo "ERROR: Research phase failed to create reports directory" >&2
  echo "DIAGNOSTIC: Expected directory: $RESEARCH_DIR" >&2
  echo "SOLUTION: Check research-specialist agent logs for failures" >&2
  exit 1
fi

# File-level verification (not directory-level)
if [ -z "$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null)" ]; then
  echo "ERROR: Research phase failed to create report files" >&2
  echo "DIAGNOSTIC: Directory exists but no .md files found: $RESEARCH_DIR" >&2
  echo "SOLUTION: Check research-specialist agent behavioral file compliance" >&2
  exit 1
fi

# Verify file size (minimum 100 bytes)
UNDERSIZED_FILES=$(find "$RESEARCH_DIR" -name '*.md' -type f -size -100c 2>/dev/null)
if [ -n "$UNDERSIZED_FILES" ]; then
  echo "ERROR: Research report(s) too small (< 100 bytes)" >&2
  echo "DIAGNOSTIC: Files: $UNDERSIZED_FILES" >&2
  exit 1
fi

REPORT_COUNT=$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null | wc -l)

# CHECKPOINT REPORTING
echo ""
echo "CHECKPOINT: Research phase complete"
echo "- Workflow type: debug-only"
echo "- Issue: $ISSUE_DESCRIPTION"
echo "- Reports created: $REPORT_COUNT in $RESEARCH_DIR"
echo "- All files verified: ✓"
echo "- Proceeding to: Planning phase"
echo ""

# Persist variables across bash blocks (subprocess isolation)
append_workflow_state "SPECS_DIR" "$SPECS_DIR"
append_workflow_state "RESEARCH_DIR" "$RESEARCH_DIR"
append_workflow_state "DEBUG_DIR" "$DEBUG_DIR"
append_workflow_state "REPORT_COUNT" "$REPORT_COUNT"
append_workflow_state "ISSUE_DESCRIPTION" "$ISSUE_DESCRIPTION"

# Persist completed state with return code verification
save_completed_states_to_state 2>&1
SAVE_EXIT=$?
if [ $SAVE_EXIT -ne 0 ]; then
  log_command_error "state_error" "Failed to persist state transitions" "$(jq -n --arg file "${STATE_FILE:-unknown}" '{state_file: $file}')"
  echo "ERROR: Failed to persist completed state" >&2
  exit 1
fi

if [ -n "${STATE_FILE:-}" ] && [ ! -f "$STATE_FILE" ]; then
  echo "WARNING: State file not found after save: $STATE_FILE" >&2
fi
```

## Block 4: Planning Phase (Debug Strategy)

**EXECUTE NOW**: Transition to planning state and prepare for plan creation:

```bash
set +H  # CRITICAL: Disable history expansion

# Initialize pre-trap error buffer BEFORE library sourcing
declare -a _EARLY_ERROR_BUFFER=()

# === DEFENSIVE TRAP SETUP ===
# Set minimal trap BEFORE library sourcing to catch sourcing failures
trap 'echo "ERROR: Library sourcing failed at line $LINENO: $BASH_COMMAND" >&2; exit 1' ERR
trap 'if [ $? -ne 0 ]; then echo "ERROR: Block initialization failed" >&2; fi' EXIT

# Source error-handling.sh FIRST to enable diagnostic functions
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Replace remaining library sourcing with diagnostic wrapper
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" || exit 1

# Load WORKFLOW_ID from file
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/debug_state_id.txt"
if [ -f "$STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$STATE_ID_FILE")

  # Validate WORKFLOW_ID format
  validate_workflow_id "$WORKFLOW_ID" "/debug" || {
    WORKFLOW_ID="debug_$(date +%s)_recovered"
  }

  export WORKFLOW_ID
  load_workflow_state "$WORKFLOW_ID" false

  # Validate critical variables restored from state
  validate_state_restoration "COMMAND_NAME" "USER_ARGS" "STATE_FILE" || {
    echo "ERROR: State restoration failed - critical variables missing" >&2
    exit 1
  }

  export COMMAND_NAME USER_ARGS WORKFLOW_ID

  # === CLEAR DEFENSIVE TRAP ===
  _clear_defensive_trap

  # === SETUP BASH ERROR TRAP ===
  setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

  # Flush any early errors captured before trap was active
  _flush_early_errors
fi

# === VALIDATE STATE AFTER LOAD ===
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
DEBUG_LOG="${DEBUG_LOG:-${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_debug.log}"
mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null

if [ -z "$STATE_FILE" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State file path not set after load" \
    "bash_block_4" \
    "$(jq -n --arg workflow "$WORKFLOW_ID" '{workflow_id: $workflow}')"

  {
    echo "[$(date)] ERROR: State file path not set"
    echo "WHICH: load_workflow_state"
    echo "WHAT: STATE_FILE variable empty after load"
    echo "WHERE: Block 4, planning phase"
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
    "State file not found after load" \
    "bash_block_4" \
    "$(jq -n --arg path "$STATE_FILE" '{state_file_path: $path}')"

  {
    echo "[$(date)] ERROR: State file not found"
    echo "WHICH: load_workflow_state"
    echo "WHAT: File does not exist at expected path"
    echo "WHERE: Block 4, planning phase"
    echo "PATH: $STATE_FILE"
  } >> "$DEBUG_LOG"
  echo "ERROR: State file not found (see $DEBUG_LOG)" >&2
  exit 1
fi

# Re-export state machine variables (restored by load_workflow_state)
export CURRENT_STATE
export TERMINAL_STATE
export WORKFLOW_SCOPE
export RESEARCH_COMPLEXITY
export RESEARCH_TOPICS_JSON

# Transition to plan state with return code verification
sm_transition "$STATE_PLAN" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State transition to PLAN failed" \
    "bash_block_4" \
    "$(jq -n --arg state "PLAN" '{target_state: $state}')"

  echo "ERROR: State transition to PLAN failed" >&2
  echo "DIAGNOSTIC Information:" >&2
  echo "  - Current State: $(sm_current_state 2>/dev/null || echo 'unknown')" >&2
  echo "  - Attempted Transition: → PLAN" >&2
  echo "  - Workflow Type: debug-only" >&2
  echo "  - Reports created: $REPORT_COUNT" >&2
  echo "POSSIBLE CAUSES:" >&2
  echo "  - Research phase did not complete" >&2
  echo "  - No reports created (check REPORT_COUNT)" >&2
  echo "  - State not persisted after research" >&2
  echo "TROUBLESHOOTING:" >&2
  echo "  - Check research checkpoint output" >&2
  echo "  - Verify reports exist in $RESEARCH_DIR" >&2
  exit 1
fi
echo "=== Phase 2: Planning (Debug Strategy) ==="
echo ""

# Pre-calculate plan path
PLANS_DIR="${SPECS_DIR}/plans"
PLAN_NUMBER="001"
PLAN_FILENAME="${PLAN_NUMBER}-debug-strategy.md"
PLAN_PATH="${PLANS_DIR}/${PLAN_FILENAME}"

# Collect research report paths
REPORT_PATHS=$(find "$RESEARCH_DIR" -name '*.md' -type f | sort)
REPORT_PATHS_JSON=$(echo "$REPORT_PATHS" | jq -R . | jq -s .)

# Persist additional state for agent
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
echo "PLAN_PATH=$PLAN_PATH" >> "${CLAUDE_PROJECT_DIR}/.claude/tmp/debug_state_$$.txt"
echo "REPORT_PATHS_JSON='$REPORT_PATHS_JSON'" >> "${CLAUDE_PROJECT_DIR}/.claude/tmp/debug_state_$$.txt"
```

**CRITICAL BARRIER - Planning Delegation**

**EXECUTE NOW**: USE the Task tool to invoke the plan-architect agent. This invocation is MANDATORY. The orchestrator MUST NOT create plans directly. Verification blocks will FAIL if plan artifacts are not created by the architect.

Task {
  subagent_type: "general-purpose"
  description: "Create debug strategy plan for $ISSUE_DESCRIPTION"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are creating a debug strategy plan for: debug workflow

    Input:
    - Feature Description: Debug strategy for: $ISSUE_DESCRIPTION
    - Output Path: $PLAN_PATH
    - Research Reports: $REPORT_PATHS_JSON
    - Workflow Type: debug-only
    - Plan Mode: debug strategy
    - Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH:-none}
    - Archived Prompt File: ${ARCHIVED_PROMPT_PATH:-none}

    If an archived prompt file is provided (not 'none'), reference it for complete context.

    Execute planning according to behavioral guidelines.

    Return: PLAN_CREATED: {plan_path}
  "
}

**EXECUTE NOW**: Verify plan artifacts were created:

```bash
set +H  # CRITICAL: Disable history expansion
set -e  # Fail-fast per code-standards.md

# Re-source libraries for subprocess isolation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Load WORKFLOW_ID from file
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/debug_state_id.txt"
if [ -f "$STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$STATE_ID_FILE")
  export WORKFLOW_ID
  load_workflow_state "$WORKFLOW_ID" false

  # Restore error logging context
  if [ -z "${COMMAND_NAME:-}" ]; then
    COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "/debug")
  fi
  if [ -z "${USER_ARGS:-}" ]; then
    USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "")
  fi
  export COMMAND_NAME USER_ARGS WORKFLOW_ID

  # Setup bash error trap
  setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
fi

# Load state from previous block
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
source "${CLAUDE_PROJECT_DIR}/.claude/tmp/debug_state_$$.txt" 2>/dev/null || true

# MANDATORY VERIFICATION
echo "Verifying plan artifacts..."

if [ ! -f "$PLAN_PATH" ]; then
  echo "ERROR: Planning phase failed to create plan file" >&2
  echo "DIAGNOSTIC: Expected file: $PLAN_PATH" >&2
  exit 1
fi

FILE_SIZE=$(wc -c < "$PLAN_PATH")
if [ "$FILE_SIZE" -lt 200 ]; then
  echo "ERROR: Plan file too small ($FILE_SIZE bytes)" >&2
  exit 1
fi

# CHECKPOINT REPORTING
echo ""
echo "CHECKPOINT: Planning phase complete"
echo "- Plan file: $PLAN_PATH"
echo "- Plan size: $(wc -c < "$PLAN_PATH") bytes"
echo "- Research reports used: $REPORT_COUNT"
echo "- All verifications: ✓"
echo "- Proceeding to: Debug phase"
echo ""

# Persist variables for Part 5 (subprocess isolation)
append_workflow_state "PLANS_DIR" "$PLANS_DIR"
append_workflow_state "PLAN_PATH" "$PLAN_PATH"
append_workflow_state "REPORT_PATHS_JSON" "$REPORT_PATHS_JSON"

# Persist completed state with return code verification
save_completed_states_to_state 2>&1
SAVE_EXIT=$?
if [ $SAVE_EXIT -ne 0 ]; then
  log_command_error "state_error" "Failed to persist state transitions" "$(jq -n --arg file "${STATE_FILE:-unknown}" '{state_file: $file}')"
  echo "ERROR: Failed to persist completed state" >&2
  exit 1
fi

if [ -n "${STATE_FILE:-}" ] && [ ! -f "$STATE_FILE" ]; then
  echo "WARNING: State file not found after save: $STATE_FILE" >&2
fi
```

## Block 5: Debug Phase (Root Cause Analysis)

**EXECUTE NOW**: Transition to debug state and prepare for root cause analysis:

```bash
set +H  # CRITICAL: Disable history expansion

# Initialize pre-trap error buffer BEFORE library sourcing
declare -a _EARLY_ERROR_BUFFER=()

# === DEFENSIVE TRAP SETUP ===
# Set minimal trap BEFORE library sourcing to catch sourcing failures
trap 'echo "ERROR: Library sourcing failed at line $LINENO: $BASH_COMMAND" >&2; exit 1' ERR
trap 'if [ $? -ne 0 ]; then echo "ERROR: Block initialization failed" >&2; fi' EXIT

# Source error-handling.sh FIRST to enable diagnostic functions
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Replace remaining library sourcing with diagnostic wrapper
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" || exit 1

# Load WORKFLOW_ID from file
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/debug_state_id.txt"
if [ -f "$STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$STATE_ID_FILE")

  # Validate WORKFLOW_ID format
  validate_workflow_id "$WORKFLOW_ID" "/debug" || {
    WORKFLOW_ID="debug_$(date +%s)_recovered"
  }

  export WORKFLOW_ID
  load_workflow_state "$WORKFLOW_ID" false

  # Validate critical variables restored from state
  validate_state_restoration "COMMAND_NAME" "USER_ARGS" "STATE_FILE" || {
    echo "ERROR: State restoration failed - critical variables missing" >&2
    exit 1
  }

  export COMMAND_NAME USER_ARGS WORKFLOW_ID

  # === CLEAR DEFENSIVE TRAP ===
  _clear_defensive_trap

  # === SETUP BASH ERROR TRAP ===
  setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

  # Flush any early errors captured before trap was active
  _flush_early_errors
fi

# === VALIDATE STATE AFTER LOAD ===
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
DEBUG_LOG="${DEBUG_LOG:-${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_debug.log}"
mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null

if [ -z "$STATE_FILE" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State file path not set after load" \
    "bash_block_5" \
    "$(jq -n --arg workflow "$WORKFLOW_ID" '{workflow_id: $workflow}')"

  {
    echo "[$(date)] ERROR: State file path not set"
    echo "WHICH: load_workflow_state"
    echo "WHAT: STATE_FILE variable empty after load"
    echo "WHERE: Block 5, debug phase"
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
    "State file not found after load" \
    "bash_block_5" \
    "$(jq -n --arg path "$STATE_FILE" '{state_file_path: $path}')"

  {
    echo "[$(date)] ERROR: State file not found"
    echo "WHICH: load_workflow_state"
    echo "WHAT: File does not exist at expected path"
    echo "WHERE: Block 5, debug phase"
    echo "PATH: $STATE_FILE"
  } >> "$DEBUG_LOG"
  echo "ERROR: State file not found (see $DEBUG_LOG)" >&2
  exit 1
fi

# Re-export state machine variables (restored by load_workflow_state)
export CURRENT_STATE
export TERMINAL_STATE
export WORKFLOW_SCOPE
export RESEARCH_COMPLEXITY
export RESEARCH_TOPICS_JSON

# Transition to debug state with return code verification
sm_transition "$STATE_DEBUG" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State transition to DEBUG failed" \
    "bash_block_5" \
    "$(jq -n --arg state "DEBUG" '{target_state: $state}')"

  echo "ERROR: State transition to DEBUG failed" >&2
  echo "DIAGNOSTIC Information:" >&2
  echo "  - Current State: $(sm_current_state 2>/dev/null || echo 'unknown')" >&2
  echo "  - Attempted Transition: → DEBUG" >&2
  echo "  - Workflow Type: debug-only" >&2
  echo "  - Plan file: $PLAN_PATH" >&2
  echo "POSSIBLE CAUSES:" >&2
  echo "  - Planning phase did not complete" >&2
  echo "  - Plan file missing or invalid" >&2
  echo "  - State not persisted after planning" >&2
  echo "TROUBLESHOOTING:" >&2
  echo "  - Check planning checkpoint output" >&2
  echo "  - Verify plan exists: $PLAN_PATH" >&2
  exit 1
fi
echo "=== Phase 3: Debug (Root Cause Analysis) ==="
echo ""
```

**CRITICAL BARRIER - Debug Analysis Delegation**

**EXECUTE NOW**: USE the Task tool to invoke the debug-analyst agent. This invocation is MANDATORY. The orchestrator MUST NOT perform debug analysis directly. Verification blocks will FAIL if debug artifacts are not created by the analyst.

Task {
  subagent_type: "general-purpose"
  description: "Root cause analysis for $ISSUE_DESCRIPTION"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md

    You are conducting root cause analysis for: debug workflow

    Input:
    - Issue Description: $ISSUE_DESCRIPTION
    - Debug Strategy Plan: $PLAN_PATH
    - Research Reports: $REPORT_PATHS_JSON
    - Debug Directory: $DEBUG_DIR
    - Workflow Type: debug-only

    Execute root cause analysis according to behavioral guidelines.

    Return: DEBUG_COMPLETE: {analysis_path}
  "
}

**EXECUTE NOW**: Verify debug artifacts were created:

```bash
set +H  # CRITICAL: Disable history expansion
set -e  # Fail-fast per code-standards.md

# Re-source libraries for subprocess isolation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Load WORKFLOW_ID from file
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/debug_state_id.txt"
if [ -f "$STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$STATE_ID_FILE")
  export WORKFLOW_ID
  load_workflow_state "$WORKFLOW_ID" false

  # Restore error logging context
  if [ -z "${COMMAND_NAME:-}" ]; then
    COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "/debug")
  fi
  if [ -z "${USER_ARGS:-}" ]; then
    USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "")
  fi
  export COMMAND_NAME USER_ARGS WORKFLOW_ID

  # Setup bash error trap
  setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
fi

# Load state from previous block
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
source "${CLAUDE_PROJECT_DIR}/.claude/tmp/debug_state_$$.txt" 2>/dev/null || true

# MANDATORY VERIFICATION
echo "Verifying debug artifacts..."

if [ ! -d "$DEBUG_DIR" ]; then
  echo "WARNING: Debug directory not created" >&2
fi

# Check for any debug artifacts (logs, analysis files)
DEBUG_ARTIFACT_COUNT=$(find "$DEBUG_DIR" -type f 2>/dev/null | wc -l)

if [ "$DEBUG_ARTIFACT_COUNT" -eq 0 ]; then
  echo "NOTE: No debug artifacts created (analysis may be in plan or reports)"
fi

# CHECKPOINT REPORTING
echo ""
echo "CHECKPOINT: Debug phase complete"
echo "- Debug artifacts: $DEBUG_ARTIFACT_COUNT in $DEBUG_DIR"
echo "- Analysis complete: ✓"
echo "- All verifications: ✓"
echo "- Proceeding to: Completion"
echo ""

# Persist variables for Part 6 (subprocess isolation)
append_workflow_state "DEBUG_ARTIFACT_COUNT" "$DEBUG_ARTIFACT_COUNT"

# Persist completed state with return code verification
save_completed_states_to_state 2>&1
SAVE_EXIT=$?
if [ $SAVE_EXIT -ne 0 ]; then
  log_command_error "state_error" "Failed to persist state transitions" "$(jq -n --arg file "${STATE_FILE:-unknown}" '{state_file: $file}')"
  echo "ERROR: Failed to persist completed state" >&2
  exit 1
fi

if [ -n "${STATE_FILE:-}" ] && [ ! -f "$STATE_FILE" ]; then
  echo "WARNING: State file not found after save: $STATE_FILE" >&2
fi
```

## Block 6: Completion & Cleanup

**EXECUTE NOW**: Complete workflow and cleanup state:

```bash
set +H  # CRITICAL: Disable history expansion

# Initialize pre-trap error buffer BEFORE library sourcing
declare -a _EARLY_ERROR_BUFFER=()

# === DEFENSIVE TRAP SETUP ===
# Set minimal trap BEFORE library sourcing to catch sourcing failures
trap 'echo "ERROR: Library sourcing failed at line $LINENO: $BASH_COMMAND" >&2; exit 1' ERR
trap 'if [ $? -ne 0 ]; then echo "ERROR: Block initialization failed" >&2; fi' EXIT

# Source error-handling.sh FIRST to enable diagnostic functions
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Replace remaining library sourcing with diagnostic wrapper
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" || exit 1

# Load WORKFLOW_ID from file
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/debug_state_id.txt"
if [ -f "$STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$STATE_ID_FILE")

  # Validate WORKFLOW_ID format
  validate_workflow_id "$WORKFLOW_ID" "/debug" || {
    WORKFLOW_ID="debug_$(date +%s)_recovered"
  }

  export WORKFLOW_ID
  load_workflow_state "$WORKFLOW_ID" false

  # Validate critical variables restored from state
  validate_state_restoration "COMMAND_NAME" "USER_ARGS" "STATE_FILE" || {
    echo "ERROR: State restoration failed - critical variables missing" >&2
    exit 1
  }

  export COMMAND_NAME USER_ARGS WORKFLOW_ID

  # === CLEAR DEFENSIVE TRAP ===
  _clear_defensive_trap

  # === SETUP BASH ERROR TRAP ===
  setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

  # Flush any early errors captured before trap was active
  _flush_early_errors
fi

# === VALIDATE STATE AFTER LOAD ===
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
DEBUG_LOG="${DEBUG_LOG:-${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_debug.log}"
mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null

if [ -z "$STATE_FILE" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State file path not set after load" \
    "bash_block_6" \
    "$(jq -n --arg workflow "$WORKFLOW_ID" '{workflow_id: $workflow}')"

  {
    echo "[$(date)] ERROR: State file path not set"
    echo "WHICH: load_workflow_state"
    echo "WHAT: STATE_FILE variable empty after load"
    echo "WHERE: Block 6, completion phase"
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
    "State file not found after load" \
    "bash_block_6" \
    "$(jq -n --arg path "$STATE_FILE" '{state_file_path: $path}')"

  {
    echo "[$(date)] ERROR: State file not found"
    echo "WHICH: load_workflow_state"
    echo "WHAT: File does not exist at expected path"
    echo "WHERE: Block 6, completion phase"
    echo "PATH: $STATE_FILE"
  } >> "$DEBUG_LOG"
  echo "ERROR: State file not found (see $DEBUG_LOG)" >&2
  exit 1
fi

# Re-export state machine variables (restored by load_workflow_state)
export CURRENT_STATE
export TERMINAL_STATE
export WORKFLOW_SCOPE
export RESEARCH_COMPLEXITY
export RESEARCH_TOPICS_JSON

# Debug-only workflow: terminate after debug phase with return code verification
sm_transition "$STATE_COMPLETE" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State transition to COMPLETE failed" \
    "bash_block_6" \
    "$(jq -n --arg state "COMPLETE" '{target_state: $state}')"

  echo "ERROR: State transition to COMPLETE failed" >&2
  echo "DIAGNOSTIC Information:" >&2
  echo "  - Current State: $(sm_current_state 2>/dev/null || echo 'unknown')" >&2
  echo "  - Attempted Transition: → COMPLETE" >&2
  echo "  - Workflow Type: debug-only" >&2
  echo "  - Terminal State: complete" >&2
  echo "POSSIBLE CAUSES:" >&2
  echo "  - Debug phase did not complete" >&2
  echo "  - State not persisted properly" >&2
  echo "  - Terminal state misconfigured" >&2
  echo "TROUBLESHOOTING:" >&2
  echo "  - Check debug checkpoint output" >&2
  echo "  - Verify workflow_type is debug-only" >&2
  exit 1
fi

# === CONSOLE SUMMARY ===
# Source summary formatting library
source "${CLAUDE_LIB}/core/summary-formatting.sh" 2>/dev/null || {
  echo "ERROR: Failed to load summary-formatting library" >&2
  exit 1
}

# Build summary text
SUMMARY_TEXT="Analyzed issue through root cause investigation with $REPORT_COUNT research reports and created debug strategy plan. Debug artifacts include analysis findings and recommended resolution approach."
# Build artifacts section
ARTIFACTS="  📊 Reports: $RESEARCH_DIR/ ($REPORT_COUNT files)
  📄 Plan: $PLAN_PATH"
if [ "$DEBUG_ARTIFACT_COUNT" -gt 0 ]; then
  ARTIFACTS="${ARTIFACTS}
  🔧 Debug: $DEBUG_DIR/ ($DEBUG_ARTIFACT_COUNT files)"
fi
# Build next steps
NEXT_STEPS="  • Review debug strategy: cat $PLAN_PATH
  • Review debug artifacts: ls -lh $DEBUG_DIR/
  • Apply fixes identified in analysis
  • Re-run tests to verify fix
  • Run /todo to update TODO.md (adds debug report to tracking)"
# Print standardized summary (no phases for debug command)
print_artifact_summary "Debug" "$SUMMARY_TEXT" "" "$ARTIFACTS" "$NEXT_STEPS"

# Emit completion reminder
echo ""
echo "📋 Next Step: Run /todo to update TODO.md with this debug report"
echo ""

# === RETURN DEBUG_REPORT_CREATED SIGNAL ===
# Signal enables buffer-opener hook and orchestrator detection
if [ -n "$PLAN_PATH" ] && [ -f "$PLAN_PATH" ]; then
  echo ""
  echo "DEBUG_REPORT_CREATED: $PLAN_PATH"
  echo ""
fi

# === STATUS MESSAGE ===
# Handle standalone debug (no plan) case with context-aware message
TOPIC_PATH=$(dirname "$(dirname "$PLAN_PATH")")
PLAN_FILE=$(find "$TOPIC_PATH/plans" -name '*.md' -type f 2>/dev/null | head -1)

if [ -n "$PLAN_FILE" ] && [ -f "$PLAN_FILE" ]; then
  echo "Debug report linked to plan: $(basename "$PLAN_FILE")"
else
  echo "Debug report is standalone (no plan in topic)"
fi

# Cleanup temp state file
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
rm -f "${CLAUDE_PROJECT_DIR}/.claude/tmp/debug_state_$$.txt"

exit 0
```

**Troubleshooting**:

- **Research fails**: Ensure issue description is specific enough for investigation
- **No debug artifacts**: Analysis may be in plan file or reports directory
- **Root cause unclear**: Increase complexity with --complexity 3 or --complexity 4
- **State machine errors**: Ensure library versions compatible (workflow-state-machine.sh >=2.0.0)
- **File not found error**: Ensure --file path is correct and file exists; relative paths are resolved from current directory
- **Empty file warning**: The prompt file exists but has no content; add content to the file

**Usage Examples**:

```bash
# Basic debugging
/debug "authentication timeout errors in production"

# Higher complexity investigation
/debug "intermittent database connection failures --complexity 3"

# Performance issue
/debug "API endpoint latency exceeds 2s on POST /api/users"
```
