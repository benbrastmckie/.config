---
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob, Write
argument-hint: "<feature-description>" [--complexity 1-4] [--project <path>] OR --file <path> [--complexity 1-4] [--project <path>]
description: Create Lean-specific implementation plan for theorem proving projects with Mathlib research and proof strategies
command-type: primary
dependent-agents:
  - topic-naming-agent
  - research-coordinator
  - lean-plan-architect
library-requirements:
  - workflow-state-machine.sh: ">=2.0.0"
  - state-persistence.sh: ">=1.5.0"
documentation: See .claude/docs/guides/commands/lean-plan-command-guide.md for complete usage guide
---

# /lean-plan - Lean Theorem Proving Research-and-Plan Workflow Command

YOU ARE EXECUTING a Lean-specific research-and-plan workflow that creates comprehensive Mathlib research reports and theorem-level implementation plans for Lean 4 formalization projects.

**Workflow Type**: research-and-plan (Lean specialization)
**Terminal State**: plan (after planning phase complete)
**Expected Output**: Research reports + Lean implementation plan in .claude/specs/NNN_topic/

## Block 1a: Initial Setup and State Initialization

**EXECUTE NOW**: The user invoked `/lean-plan "<feature-description>"`. Capture that description.

In the **bash block below**, replace `YOUR_FEATURE_DESCRIPTION_HERE` with the actual feature description (keeping the quotes).

**Example**: If user ran `/lean-plan "formalize group homomorphism properties"`, change:
- FROM: `echo "YOUR_FEATURE_DESCRIPTION_HERE" > "$TEMP_FILE"`
- TO: `echo "formalize group homomorphism properties" > "$TEMP_FILE"`

Execute this bash block with your substitution:

```bash
set +H  # CRITICAL: Disable history expansion

# === CAPTURE FEATURE DESCRIPTION ===
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
TEMP_FILE="${HOME}/.claude/tmp/lean_plan_arg_$(date +%s%N).txt"
# SUBSTITUTE THE FEATURE DESCRIPTION IN THE LINE BELOW
echo "YOUR_FEATURE_DESCRIPTION_HERE" > "$TEMP_FILE"
echo "$TEMP_FILE" > "${HOME}/.claude/tmp/lean_plan_arg_path.txt"

# === READ AND VALIDATE ===
FEATURE_DESCRIPTION=$(cat "$TEMP_FILE" 2>/dev/null || echo "")

if [ -z "$FEATURE_DESCRIPTION" ]; then
  echo "ERROR: Feature description is empty" >&2
  echo "Usage: /lean-plan \"<feature description>\"" >&2
  echo "   or: /lean-plan --file /path/to/requirements.md" >&2
  exit 1
fi

# === DETECT META-INSTRUCTION PATTERNS ===
# Warn if user provided indirect instructions instead of direct formalization goals
if [[ "$FEATURE_DESCRIPTION" =~ [Uu]se.*to.*(create|make|generate) ]] || \
   [[ "$FEATURE_DESCRIPTION" =~ [Rr]ead.*and.*(create|make|generate) ]]; then
  echo "WARNING: Feature description appears to be a meta-instruction" >&2
  echo "Did you mean to use --file flag instead?" >&2
  echo "Example: /lean-plan --file /path/to/requirements.md" >&2
  echo "" >&2
  echo "Proceeding with provided description, but delegation may be affected." >&2
  # Note: log_command_error not yet available (error-handling.sh not sourced yet)
  # Will be logged after libraries are loaded
  _EARLY_ERROR_BUFFER+=("validation_error|Meta-instruction pattern detected|User provided: $FEATURE_DESCRIPTION")
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
  echo "Usage: /lean-plan --file /path/to/prompt.md" >&2
  exit 1
fi

# Parse optional --project flag for Lean project path
LEAN_PROJECT_PATH=""
if [[ "$FEATURE_DESCRIPTION" =~ --project[[:space:]]+([^[:space:]]+) ]]; then
  LEAN_PROJECT_PATH="${BASH_REMATCH[1]}"
  # Convert to absolute path if relative
  [[ "${LEAN_PROJECT_PATH:-}" = /* ]]
  IS_ABSOLUTE_PATH=$?
  if [ $IS_ABSOLUTE_PATH -ne 0 ]; then
    LEAN_PROJECT_PATH="$(pwd)/${LEAN_PROJECT_PATH:-}"
  fi
  # Strip --project flag from feature description
  FEATURE_DESCRIPTION=$(echo "$FEATURE_DESCRIPTION" | sed 's/--project[[:space:]]*[^[:space:]]*//' | xargs)
elif [[ "$FEATURE_DESCRIPTION" =~ --project ]]; then
  echo "ERROR: --project flag requires a path argument" >&2
  echo "Usage: /lean-plan \"formalize theorems\" --project ~/ProofChecker" >&2
  exit 1
fi

# === LEAN PROJECT DETECTION ===
# If --project not provided, auto-detect from current directory
if [ -z "${LEAN_PROJECT_PATH:-}" ]; then
  # Search upward for lakefile.toml
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -f "$current_dir/lakefile.toml" ] || [ -f "$current_dir/lakefile.lean" ]; then
      LEAN_PROJECT_PATH="$current_dir"
      echo "Auto-detected Lean project: $LEAN_PROJECT_PATH"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi

# Validate Lean project structure
if [ -z "${LEAN_PROJECT_PATH:-}" ]; then
  echo "ERROR: No Lean project found" >&2
  echo "No lakefile.toml detected in current directory or parent directories" >&2
  echo "Use --project flag to specify Lean project path:" >&2
  echo "  /lean:plan \"formalize theorems\" --project ~/ProofChecker" >&2
  exit 1
fi

if [ ! -f "${LEAN_PROJECT_PATH}/lakefile.toml" ] && [ ! -f "${LEAN_PROJECT_PATH}/lakefile.lean" ]; then
  echo "ERROR: Invalid Lean project structure: ${LEAN_PROJECT_PATH}" >&2
  echo "No lakefile.toml or lakefile.lean found in project directory" >&2
  exit 1
fi

echo "Lean project validated: $LEAN_PROJECT_PATH"

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
  echo "ERROR: Failed to detect .claude project directory" >&2
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
setup_bash_error_trap "/lean:plan" "lean_plan_early_$(date +%s)" "early_init"

# === INITIALIZE STATE ===
WORKFLOW_TYPE="research-and-plan"
TERMINAL_STATE="plan"
COMMAND_NAME="/lean-plan"
USER_ARGS="$FEATURE_DESCRIPTION"
export COMMAND_NAME USER_ARGS

WORKFLOW_ID="lean_plan_$(date +%s)"
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path (matches state file location)
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/lean_plan_state_id.txt"
mkdir -p "$(dirname "$STATE_ID_FILE")"
echo "$WORKFLOW_ID" > "$STATE_ID_FILE"
export WORKFLOW_ID

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

# Persist FEATURE_DESCRIPTION and LEAN_PROJECT_PATH for topic naming agent
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
TOPIC_NAMING_INPUT_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/topic_naming_input_${WORKFLOW_ID}.txt"
echo "$FEATURE_DESCRIPTION" > "$TOPIC_NAMING_INPUT_FILE"
export TOPIC_NAMING_INPUT_FILE

# Persist Lean project path for research and planning phases
append_workflow_state "LEAN_PROJECT_PATH" "$LEAN_PROJECT_PATH"

echo "✓ Setup complete, ready for topic naming"
echo "  Lean Project: $LEAN_PROJECT_PATH"
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
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/lean_plan_state_id.txt"
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

COMMAND_NAME="/lean-plan"
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

Task {
  subagent_type: "general-purpose"
  description: "Generate semantic topic directory name for Lean formalization"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/topic-naming-agent.md

    You are generating a topic directory name for: /lean-plan command

    **Input Contract (Hard Barrier Pattern)**:
    - Output Path: ${TOPIC_NAME_FILE}
    - User Prompt: ${FEATURE_DESCRIPTION}
    - Command Name: /lean-plan
    - Context: Lean 4 theorem proving formalization

    **CRITICAL**: You MUST write the topic name to the EXACT path specified above.
    The orchestrator has pre-calculated this path and will validate it exists after you return.
    Do NOT derive or calculate your own path.

    Execute topic naming according to behavioral guidelines:
    1. Generate semantic topic name from user prompt (emphasize theorem/proof context)
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
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/lean_plan_state_id.txt"
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

COMMAND_NAME="/lean-plan"
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
  echo "To retry: Re-run the /lean:plan command with the same arguments" >&2
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
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/lean_plan_state_id.txt"
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
LEAN_PROJECT_PATH="${LEAN_PROJECT_PATH:-}"

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
COMMAND_NAME="/lean-plan"
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
LEAN_PROJECT_PATH=${LEAN_PROJECT_PATH:-}
EOF

echo "Setup complete: $WORKFLOW_ID (Lean research-and-plan, complexity: $RESEARCH_COMPLEXITY)"
echo "Research directory: $RESEARCH_DIR"
echo "Plans directory: $PLANS_DIR"
echo "Topic name: $TOPIC_NAME (strategy: $NAMING_STRATEGY)"
echo "Lean project: $LEAN_PROJECT_PATH"
```

## Block 1d-topics: Research Topics Classification

**EXECUTE NOW**: Classify research into focused topics based on complexity level.

```bash
set +H  # CRITICAL: Disable history expansion

# === DETECT PROJECT DIRECTORY ===
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

# === LOAD STATE ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/lean_plan_state_id.txt"
if [ ! -f "$STATE_ID_FILE" ]; then
  echo "ERROR: State ID file not found: $STATE_ID_FILE" >&2
  exit 1
fi

WORKFLOW_ID=$(cat "$STATE_ID_FILE")
if [ -z "$WORKFLOW_ID" ]; then
  echo "ERROR: STATE_ID_FILE exists but is empty" >&2
  exit 1
fi

STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
if [ ! -f "$STATE_FILE" ]; then
  echo "ERROR: Workflow state file not found: $STATE_FILE" >&2
  exit 1
fi

source "$STATE_FILE" || {
  echo "ERROR: Failed to restore workflow state from $STATE_FILE" >&2
  exit 1
}

# === RESTORE ERROR LOGGING CONTEXT ===
# Ensure error logging variables are set after state restoration
COMMAND_NAME="${COMMAND_NAME:-/lean-plan}"
USER_ARGS="${USER_ARGS:-$FEATURE_DESCRIPTION}"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# === SOURCE LIBRARIES ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1

# === SETUP ERROR TRAP ===
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "${USER_ARGS:-}"

# === COMPLEXITY-BASED TOPIC COUNT ===
# Map research complexity to topic count for Lean research
case "$RESEARCH_COMPLEXITY" in
  1|2) TOPIC_COUNT=2 ;;
  3)   TOPIC_COUNT=3 ;;
  4)   TOPIC_COUNT=4 ;;
  *)   TOPIC_COUNT=3 ;;  # Default fallback
esac

# === LEAN-SPECIFIC RESEARCH TOPICS ===
# Define focused research areas for Lean formalization
LEAN_TOPICS=(
  "Mathlib Theorems"
  "Proof Strategies"
  "Project Structure"
  "Style Guide"
)

# Select topics based on count (take first N topics)
TOPICS=()
for i in $(seq 0 $((TOPIC_COUNT - 1))); do
  if [ $i -lt ${#LEAN_TOPICS[@]} ]; then
    TOPICS+=("${LEAN_TOPICS[$i]}")
  fi
done

# === CALCULATE REPORT PATHS ===
# Pre-calculate absolute paths for each research topic
REPORT_PATHS=()
REPORT_INDEX=1

for TOPIC in "${TOPICS[@]}"; do
  # Convert topic to slug (lowercase, spaces to hyphens)
  SLUG=$(echo "$TOPIC" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

  # Zero-pad index to 3 digits
  PADDED_INDEX=$(printf "%03d" $REPORT_INDEX)

  # Calculate absolute report path
  REPORT_FILE="${RESEARCH_DIR}/${PADDED_INDEX}-${SLUG}.md"

  # Validate path is absolute
  [[ "${REPORT_FILE:-}" = /* ]]
  IS_ABSOLUTE_REPORT_PATH=$?
  if [ $IS_ABSOLUTE_REPORT_PATH -ne 0 ]; then
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "validation_error" \
      "Report path is not absolute" \
      "bash_block_1d_topics" \
      "$(jq -n --arg path "$REPORT_FILE" '{report_file: $path, expected: "absolute path starting with /"}')"
    echo "ERROR: Report path must be absolute: $REPORT_FILE" >&2
    exit 1
  fi

  REPORT_PATHS+=("$REPORT_FILE")
  REPORT_INDEX=$((REPORT_INDEX + 1))
done

# Create parent directory
mkdir -p "$RESEARCH_DIR" || {
  echo "ERROR: Failed to create research directory: $RESEARCH_DIR" >&2
  exit 1
}

# === PERSIST TOPICS AND PATHS ===
# Use bulk append for efficiency
{
  echo "TOPIC_COUNT=$TOPIC_COUNT"
  echo "TOPICS=("
  for TOPIC in "${TOPICS[@]}"; do
    echo "  \"$TOPIC\""
  done
  echo ")"
  echo "REPORT_PATHS=("
  for PATH in "${REPORT_PATHS[@]}"; do
    echo "  \"$PATH\""
  done
  echo ")"
} >> "$STATE_FILE"

echo ""
echo "=== Research Topics Classification ==="
echo "Research Complexity: $RESEARCH_COMPLEXITY"
echo "Topic Count: $TOPIC_COUNT"
echo ""
echo "Research Topics:"
for i in "${!TOPICS[@]}"; do
  echo "  $((i + 1)). ${TOPICS[$i]} -> ${REPORT_PATHS[$i]}"
done
echo ""
echo "Ready for research-coordinator invocation"
echo ""
```

## Block 1e-exec: Research Coordination (research-coordinator Invocation)

**EXECUTE NOW**: USE the Task tool to invoke the research-coordinator agent for parallel multi-topic research.

Task {
  subagent_type: "general-purpose"
  description: "Coordinate parallel Lean research across ${TOPIC_COUNT} topics: ${TOPICS[@]}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-coordinator.md

    You are coordinating parallel research for: lean-plan workflow

    **Input Contract (Hard Barrier Pattern - Mode 2: Pre-Decomposed)**:
    - research_request: ${FEATURE_DESCRIPTION}
    - research_complexity: ${RESEARCH_COMPLEXITY}
    - report_dir: ${RESEARCH_DIR}
    - topic_path: ${TOPIC_PATH}
    - topics: [$(printf '\"%s\" ' \"${TOPICS[@]}\")]
    - report_paths: [$(printf '\"%s\" ' \"${REPORT_PATHS[@]}\")]
    - context:
        feature_description: ${FEATURE_DESCRIPTION}
        lean_project_path: ${LEAN_PROJECT_PATH}
        workflow_type: research-and-plan (Lean specialization)
        original_prompt_file: ${ORIGINAL_PROMPT_FILE_PATH:-none}
        archived_prompt_file: ${ARCHIVED_PROMPT_PATH:-none}

    **CRITICAL**:
    - Topics and report paths have been PRE-CALCULATED by orchestrator (Mode 2: Manual Pre-Decomposition)
    - You MUST use the provided report_paths EXACTLY as specified
    - You MUST invoke research-specialist for EACH topic in parallel
    - Each research-specialist receives Lean-specific context (LEAN_PROJECT_PATH, Mathlib focus)
    - Validate ALL reports exist at pre-calculated paths after delegation
    - Return aggregated metadata (title, findings_count, recommendations_count) for each report

    **Expected Topics** (${TOPIC_COUNT} total):
$(for i in \"\${!TOPICS[@]}\"; do
  echo \"    \$((i + 1)). \${TOPICS[\$i]} -> \${REPORT_PATHS[\$i]}\"
done)

    **Lean-Specific Research Context**:
    - Lean Project: ${LEAN_PROJECT_PATH}
    - Research Focus: Mathlib theorems, proof strategies, project structure, style guide
    - Each research-specialist should perform:
      1. Mathlib theorem discovery (WebSearch, grep local project)
      2. Proof pattern analysis (tactic sequences, common approaches)
      3. Project architecture review (module structure, naming conventions)
      4. Documentation survey (LEAN_STYLE_GUIDE.md if exists)

    Execute research coordination according to behavioral guidelines and return completion signal:
    RESEARCH_COMPLETE: ${TOPIC_COUNT}
    reports: [{\"path\": \"...\", \"title\": \"...\", \"findings_count\": N, \"recommendations_count\": M}, ...]
  "
}

## Block 1e-validate: Coordinator Output Signal Validation

**EXECUTE NOW**: Validate research-coordinator output signal before hard barrier file checks.

This validation catches coordinator failures early (before wasting time on file checks).

```bash
set +H  # CRITICAL: Disable history expansion

# === DETECT PROJECT DIRECTORY ===
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
fi

if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1
fi

export CLAUDE_PROJECT_DIR

# === RESTORE STATE ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
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

COMMAND_NAME="/lean-plan"
USER_ARGS="${FEATURE_DESCRIPTION:-}"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

echo ""
echo "=== Coordinator Output Signal Validation ==="
echo ""

# Validate reports directory exists and has content
REPORT_DIR="${REPORT_DIR:-}"
if [ -z "$REPORT_DIR" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "REPORT_DIR not restored from state - cannot validate coordinator output" \
    "bash_block_1e_validate" \
    "$(jq -n '{report_dir: "missing"}')"
  echo "ERROR: REPORT_DIR not set - state restoration failed" >&2
  exit 1
fi

# Count expected vs actual reports (Lean: always 4 topics)
EXPECTED_LEAN_REPORTS=4
ACTUAL_REPORT_COUNT=$(find "$REPORT_DIR" -name "[0-9][0-9][0-9]-*.md" -type f 2>/dev/null | wc -l)

echo "Expected reports: $EXPECTED_LEAN_REPORTS (Lean standard topics)"
echo "Found reports: $ACTUAL_REPORT_COUNT"

# Early detection: If reports directory is empty, coordinator failed
if [ "$ACTUAL_REPORT_COUNT" -eq 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "research-coordinator failed - no reports created (empty directory detected)" \
    "bash_block_1e_validate" \
    "$(jq -n --arg dir "$REPORT_DIR" --argjson expected "$EXPECTED_LEAN_REPORTS" \
       '{report_dir: $dir, expected_reports: $expected, actual_reports: 0}')"

  echo "" >&2
  echo "ERROR: Coordinator failure detected - reports directory is empty" >&2
  echo "" >&2
  echo "Root Cause Analysis:" >&2
  echo "  - research-coordinator completed but created no reports" >&2
  echo "  - This indicates Task tool invocations were skipped or failed" >&2
  echo "" >&2
  echo "Diagnostic Steps:" >&2
  echo "  1. Review research-coordinator.md STEP 3 Task invocation patterns" >&2
  echo "  2. Verify Task blocks have 'EXECUTE NOW: USE the Task tool' directives" >&2
  echo "  3. Check for pseudo-code patterns or code block wrappers" >&2
  echo "  4. Verify coordinator self-validation checkpoint (STEP 3.5)" >&2
  echo "" >&2
  echo "Recovery Action:" >&2
  echo "  Re-run: /lean-plan \"${FEATURE_DESCRIPTION}\"" >&2
  echo "" >&2
  exit 1
fi

# Partial success detection
if [ "$ACTUAL_REPORT_COUNT" -lt "$EXPECTED_LEAN_REPORTS" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "research-coordinator partial failure - missing Lean reports (expected: $EXPECTED_LEAN_REPORTS, actual: $ACTUAL_REPORT_COUNT)" \
    "bash_block_1e_validate" \
    "$(jq -n --arg dir "$REPORT_DIR" --argjson expected "$EXPECTED_LEAN_REPORTS" --argjson actual "$ACTUAL_REPORT_COUNT" \
       '{report_dir: $dir, expected_reports: $expected, actual_reports: $actual}')"

  echo "" >&2
  echo "WARNING: Partial coordinator failure - some Lean reports missing" >&2
  echo "Expected: $EXPECTED_LEAN_REPORTS reports" >&2
  echo "Found: $ACTUAL_REPORT_COUNT reports" >&2
  echo "" >&2
fi

# Success case
if [ "$ACTUAL_REPORT_COUNT" -ge "$EXPECTED_LEAN_REPORTS" ]; then
  echo "[OK] Coordinator output validation passed"
  echo "     All expected Lean reports present in directory"
fi

echo ""
```

## Block 1f: Research Reports Hard Barrier Validation and Metadata Extraction

**EXECUTE NOW**: Validate all research reports and extract metadata from coordinator return signal:

```bash
set +H  # CRITICAL: Disable history expansion

# === DETECT PROJECT DIRECTORY ===
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

# === LOAD STATE ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/lean_plan_state_id.txt"
if [ ! -f "$STATE_ID_FILE" ]; then
  echo "ERROR: State ID file not found: $STATE_ID_FILE" >&2
  exit 1
fi

WORKFLOW_ID=$(cat "$STATE_ID_FILE")
if [ -z "$WORKFLOW_ID" ]; then
  echo "ERROR: STATE_ID_FILE exists but is empty" >&2
  exit 1
fi

STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
if [ ! -f "$STATE_FILE" ]; then
  echo "ERROR: Workflow state file not found: $STATE_FILE" >&2
  exit 1
fi

source "$STATE_FILE" || {
  echo "ERROR: Failed to restore workflow state from $STATE_FILE" >&2
  exit 1
}

# === RESTORE ERROR LOGGING CONTEXT ===
COMMAND_NAME="${COMMAND_NAME:-/lean-plan}"
USER_ARGS="${USER_ARGS:-$FEATURE_DESCRIPTION}"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# === SOURCE LIBRARIES ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/validation-utils.sh" || exit 1
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1

# === SETUP ERROR TRAP ===
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "${USER_ARGS:-}"

# === HARD BARRIER VALIDATION ===
echo ""
echo "=== Research Reports Hard Barrier Validation ==="

# Validate REPORT_PATHS array was set by Block 1d-topics
if [ -z "${REPORT_PATHS:-}" ] || [ ${#REPORT_PATHS[@]} -eq 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "REPORT_PATHS not found in workflow state" \
    "bash_block_1f" \
    "$(jq -n '{error: "Block 1d-topics must persist REPORT_PATHS before Block 1f validation"}')"
  echo "ERROR: REPORT_PATHS not found in workflow state" >&2
  exit 1
fi

echo "Expected ${#REPORT_PATHS[@]} research reports:"
for i in "${!REPORT_PATHS[@]}"; do
  echo "  $((i + 1)). ${REPORT_PATHS[$i]}"
done
echo ""

# === LAYER 1: Empty Directory Detection ===
if [ ${#REPORT_PATHS[@]} -eq 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "CRITICAL ERROR: Reports directory is empty (0 reports expected)" \
    "bash_block_1f" \
    "$(jq -n '{error: "No reports in REPORT_PATHS array"}')"
  echo "CRITICAL ERROR: Reports directory is empty" >&2
  exit 1
fi

# === MULTI-LAYER VALIDATION FOR EACH REPORT ===
SUCCESSFUL_REPORTS=0
FAILED_REPORTS=()
VALIDATION_DETAILS=()

for REPORT_PATH in "${REPORT_PATHS[@]}"; do
  REPORT_NAME=$(basename "$REPORT_PATH")
  VALIDATION_PASS=true
  FAILURE_REASON=""

  # === LAYER 2: File Existence Check ===
  if [ ! -f "$REPORT_PATH" ]; then
    VALIDATION_PASS=false
    FAILURE_REASON="File does not exist"
  fi

  # === LAYER 3: Minimum Size Validation (500 bytes) ===
  if [ "$VALIDATION_PASS" = true ]; then
    FILE_SIZE=$(wc -c < "$REPORT_PATH" 2>/dev/null || echo "0")
    if [ "$FILE_SIZE" -lt 500 ]; then
      VALIDATION_PASS=false
      FAILURE_REASON="File too small (${FILE_SIZE} bytes < 500 bytes)"
    fi
  fi

  # === LAYER 4: Required Sections Check ===
  if [ "$VALIDATION_PASS" = true ]; then
    # Check for at least one required section marker (## Findings or ## Executive Summary or ## Analysis)
    if ! grep -q "^## Findings" "$REPORT_PATH" 2>/dev/null && \
       ! grep -q "^## Executive Summary" "$REPORT_PATH" 2>/dev/null && \
       ! grep -q "^## Analysis" "$REPORT_PATH" 2>/dev/null; then
      VALIDATION_PASS=false
      FAILURE_REASON="Missing required sections (## Findings, ## Executive Summary, or ## Analysis)"
    fi
  fi

  # === RECORD RESULTS ===
  if [ "$VALIDATION_PASS" = false ]; then
    FAILED_REPORTS+=("$REPORT_PATH")
    VALIDATION_DETAILS+=("$REPORT_NAME: $FAILURE_REASON")
    echo "  ✗ Failed: $REPORT_NAME ($FAILURE_REASON)"
  else
    SUCCESSFUL_REPORTS=$((SUCCESSFUL_REPORTS + 1))
    echo "  ✓ Validated: $REPORT_NAME"
  fi
done

# === PARTIAL SUCCESS MODE ===
# Calculate success percentage
TOTAL_REPORTS=${#REPORT_PATHS[@]}
SUCCESS_PERCENTAGE=$((SUCCESSFUL_REPORTS * 100 / TOTAL_REPORTS))

echo ""
echo "Validation Results: $SUCCESSFUL_REPORTS/$TOTAL_REPORTS reports (${SUCCESS_PERCENTAGE}%)"

# Fail if <50% success
if [ $SUCCESS_PERCENTAGE -lt 50 ]; then
  # Build diagnostic context with failure details
  FAILED_REPORTS_JSON="["
  for i in "${!FAILED_REPORTS[@]}"; do
    if [ $i -gt 0 ]; then
      FAILED_REPORTS_JSON+=","
    fi
    FAILED_REPORTS_JSON+="\"${FAILED_REPORTS[$i]}\""
  done
  FAILED_REPORTS_JSON+="]"

  VALIDATION_DETAILS_JSON="["
  for i in "${!VALIDATION_DETAILS[@]}"; do
    if [ $i -gt 0 ]; then
      VALIDATION_DETAILS_JSON+=","
    fi
    VALIDATION_DETAILS_JSON+="\"${VALIDATION_DETAILS[$i]}\""
  done
  VALIDATION_DETAILS_JSON+="]"

  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Research validation failed: <50% success rate" \
    "bash_block_1f" \
    "$(jq -n \
       --argjson success "$SUCCESSFUL_REPORTS" \
       --argjson total "$TOTAL_REPORTS" \
       --argjson pct "$SUCCESS_PERCENTAGE" \
       --argjson failed "$FAILED_REPORTS_JSON" \
       --argjson details "$VALIDATION_DETAILS_JSON" \
       '{
         successful_reports: $success,
         total_reports: $total,
         success_percentage: $pct,
         failed_reports: $failed,
         validation_details: $details,
         recovery_hint: "Check research-coordinator output for errors. Retry with --complexity flag adjustment."
       }')"

  echo "ERROR: HARD BARRIER FAILED - Less than 50% of reports created" >&2
  echo "Failed reports:" >&2
  for DETAIL in "${VALIDATION_DETAILS[@]}"; do
    echo "  - $DETAIL" >&2
  done
  echo "" >&2
  echo "Recovery hint: Check research-coordinator output for errors." >&2
  echo "Consider retrying with --complexity flag adjustment." >&2
  exit 1
fi

# Warn if 50-99% success
if [ $SUCCESS_PERCENTAGE -lt 100 ]; then
  echo "WARNING: Partial research success (${SUCCESS_PERCENTAGE}%)" >&2
  echo "Failed reports:" >&2
  for DETAIL in "${VALIDATION_DETAILS[@]}"; do
    echo "  - $DETAIL" >&2
  done
  echo "" >&2
  echo "Proceeding with $SUCCESSFUL_REPORTS/$TOTAL_REPORTS reports..." >&2
fi

echo "✓ Hard barrier passed - research reports validated"

# === CONTEXT USAGE TRACKING (Phase 3 Enhancement) ===
# Parse context_usage_percent from research-coordinator return signal (if available)
# This enables iteration tracking and workflow state monitoring

# Check if coordinator returned context metrics
if [ -n "${COORDINATOR_OUTPUT:-}" ]; then
  # Parse context_usage_percent field
  CONTEXT_USAGE_PERCENT=$(echo "$COORDINATOR_OUTPUT" | grep "^context_usage_percent:" | cut -d: -f2 | tr -d ' ' || echo "")

  # Parse checkpoint_path field (optional)
  CHECKPOINT_PATH=$(echo "$COORDINATOR_OUTPUT" | grep "^checkpoint_path:" | cut -d: -f2- | tr -d ' ' || echo "")

  if [ -n "$CONTEXT_USAGE_PERCENT" ]; then
    echo ""
    echo "Context Usage: ${CONTEXT_USAGE_PERCENT}%"

    # Log warning if approaching limit (≥85%)
    if [ "$CONTEXT_USAGE_PERCENT" -ge 85 ]; then
      echo "WARNING: Context usage approaching limit (${CONTEXT_USAGE_PERCENT}% ≥ 85%)" >&2

      if [ -n "$CHECKPOINT_PATH" ] && [ -f "$CHECKPOINT_PATH" ]; then
        echo "Checkpoint saved: $CHECKPOINT_PATH" >&2
        # Persist checkpoint path in workflow state for iteration tracking
        append_workflow_state "CONTEXT_CHECKPOINT_PATH" "$CHECKPOINT_PATH"
      fi
    fi

    # Persist context metrics in workflow state
    append_workflow_state "RESEARCH_CONTEXT_USAGE_PERCENT" "$CONTEXT_USAGE_PERCENT"
  fi

  # === DEFENSIVE VALIDATION (Phase 4 Enhancement) ===
  # Validate coordinator return signal contract invariants
  # Invariant: topics_remaining non-empty → requires_continuation MUST be true

  # Helper function: Check if topics_remaining is empty
  is_topics_remaining_empty() {
    local topics_remaining="$1"

    # Check for empty string
    [ -z "$topics_remaining" ] && return 0

    # Check for literal "0"
    [ "$topics_remaining" = "0" ] && return 0

    # Check for empty array "[]"
    [ "$topics_remaining" = "[]" ] && return 0

    # Check for whitespace-only
    [[ "$topics_remaining" =~ ^[[:space:]]*$ ]] && return 0

    # Non-empty
    return 1
  }

  # Parse continuation fields (for future iteration loop support)
  TOPICS_REMAINING=$(echo "$COORDINATOR_OUTPUT" | grep "^topics_remaining:" | cut -d: -f2- || echo "[]")
  REQUIRES_CONTINUATION=$(echo "$COORDINATOR_OUTPUT" | grep "^requires_continuation:" | cut -d: -f2 | tr -d ' ' || echo "false")

  # Validate invariant and apply defensive override if violated
  if ! is_topics_remaining_empty "$TOPICS_REMAINING" && [ "$REQUIRES_CONTINUATION" = "false" ]; then
    echo "WARNING: Coordinator contract violation detected" >&2
    echo "  topics_remaining: $TOPICS_REMAINING" >&2
    echo "  requires_continuation: $REQUIRES_CONTINUATION" >&2
    echo "  OVERRIDING: Forcing continuation=true" >&2

    # Log contract violation
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "validation_error" \
      "Coordinator return signal contract violation" \
      "bash_block_1f" \
      "$(jq -n \
         --arg topics "$TOPICS_REMAINING" \
         --arg cont "$REQUIRES_CONTINUATION" \
         '{
           topics_remaining: $topics,
           requires_continuation: $cont,
           violation: "topics_remaining non-empty but requires_continuation=false",
           action: "Overriding requires_continuation to true"
         }')"

    # Apply override
    REQUIRES_CONTINUATION="true"
    append_workflow_state "REQUIRES_CONTINUATION" "$REQUIRES_CONTINUATION"
  fi
fi

echo ""
```

## Block 1f-metadata: Extract Report Metadata

**EXECUTE NOW**: Extract metadata from coordinator return signal for metadata-only context passing:

```bash
set +H  # CRITICAL: Disable history expansion

# === DETECT PROJECT DIRECTORY ===
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

# === LOAD STATE ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/lean_plan_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
source "$STATE_FILE" 2>/dev/null || {
  echo "ERROR: Failed to restore workflow state" >&2
  exit 1
}

# === RESTORE ERROR LOGGING CONTEXT ===
COMMAND_NAME="${COMMAND_NAME:-/lean-plan}"
USER_ARGS="${USER_ARGS:-$FEATURE_DESCRIPTION}"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# === SOURCE LIBRARIES ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1

# === SETUP ERROR TRAP ===
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "${USER_ARGS:-}"

echo ""
echo "=== Report Metadata Extraction ==="

# === EXTRACT METADATA FROM YAML FRONTMATTER ===
# Primary pattern: Extract structured metadata from YAML frontmatter (96% context reduction)
# Fallback pattern: Extract metadata from section headers (legacy reports without frontmatter)

REPORT_METADATA_JSON="["

for i in "${!REPORT_PATHS[@]}"; do
  REPORT_PATH="${REPORT_PATHS[$i]}"

  # Skip if report doesn't exist (partial success mode)
  if [ ! -f "$REPORT_PATH" ]; then
    continue
  fi

  # === PRIMARY: Extract from YAML frontmatter (first 10 lines) ===
  YAML_BLOCK=$(head -10 "$REPORT_PATH" 2>/dev/null || echo "")

  # Check if YAML frontmatter exists (starts with ---)
  if echo "$YAML_BLOCK" | grep -q "^---$"; then
    # Extract report_type field
    REPORT_TYPE=$(echo "$YAML_BLOCK" | grep "^report_type:" | sed 's/^report_type:[[:space:]]*//' || echo "unknown")

    # Extract topic field (remove quotes if present)
    TOPIC=$(echo "$YAML_BLOCK" | grep "^topic:" | sed 's/^topic:[[:space:]]*//' | tr -d '"' || echo "Untitled Report")

    # Extract findings_count field
    FINDINGS_COUNT=$(echo "$YAML_BLOCK" | grep "^findings_count:" | sed 's/^findings_count:[[:space:]]*//' || echo "0")

    # Extract recommendations_count field
    RECOMMENDATIONS_COUNT=$(echo "$YAML_BLOCK" | grep "^recommendations_count:" | sed 's/^recommendations_count:[[:space:]]*//' || echo "0")

    TITLE="$TOPIC"
  else
    # === FALLBACK: Extract from report content (legacy pattern) ===
    # Extract title from report (first # heading)
    TITLE=$(grep -m 1 "^# " "$REPORT_PATH" 2>/dev/null | sed 's/^# //' || echo "Untitled Report")

    REPORT_TYPE="legacy"

    # Extract findings count (count ### Finding lines)
    FINDINGS_COUNT=$(grep -c "^### Finding [0-9]" "$REPORT_PATH" 2>/dev/null || echo "0")

    # Extract recommendations count (count numbered items in Recommendations section)
    RECOMMENDATIONS_COUNT=$(awk '/^## Recommendations$/,/^## [^R]/ {if (/^[0-9]+\./) count++} END {print count}' "$REPORT_PATH" 2>/dev/null || echo "0")
  fi

  # Build JSON entry
  if [ $i -gt 0 ]; then
    REPORT_METADATA_JSON+=","
  fi

  REPORT_METADATA_JSON+="{\"path\":\"$REPORT_PATH\",\"title\":\"$TITLE\",\"report_type\":\"$REPORT_TYPE\",\"findings_count\":$FINDINGS_COUNT,\"recommendations_count\":$RECOMMENDATIONS_COUNT}"

  echo "  Report $((i + 1)): $TITLE ($FINDINGS_COUNT findings, $RECOMMENDATIONS_COUNT recommendations)"
done

REPORT_METADATA_JSON+="]"

# === FORMAT METADATA FOR PLANNING PHASE ===
# Convert to brief summary format for plan-architect prompt (metadata-only, 80 tokens per report)
FORMATTED_METADATA="Research Reports: ${#REPORT_PATHS[@]} reports created

"
for i in "${!REPORT_PATHS[@]}"; do
  REPORT_PATH="${REPORT_PATHS[$i]}"

  if [ ! -f "$REPORT_PATH" ]; then
    continue
  fi

  # Extract metadata from YAML frontmatter (primary) or fallback to content parsing
  YAML_BLOCK=$(head -10 "$REPORT_PATH" 2>/dev/null || echo "")

  if echo "$YAML_BLOCK" | grep -q "^---$"; then
    # Primary: YAML metadata
    TOPIC=$(echo "$YAML_BLOCK" | grep "^topic:" | sed 's/^topic:[[:space:]]*//' | tr -d '"' || echo "Untitled Report")
    REPORT_TYPE=$(echo "$YAML_BLOCK" | grep "^report_type:" | sed 's/^report_type:[[:space:]]*//' || echo "unknown")
    FINDINGS_COUNT=$(echo "$YAML_BLOCK" | grep "^findings_count:" | sed 's/^findings_count:[[:space:]]*//' || echo "0")
    RECOMMENDATIONS_COUNT=$(echo "$YAML_BLOCK" | grep "^recommendations_count:" | sed 's/^recommendations_count:[[:space:]]*//' || echo "0")
    TITLE="$TOPIC"
  else
    # Fallback: Content parsing
    TITLE=$(grep -m 1 "^# " "$REPORT_PATH" 2>/dev/null | sed 's/^# //' || echo "Untitled Report")
    REPORT_TYPE="legacy"
    FINDINGS_COUNT=$(grep -c "^### Finding [0-9]" "$REPORT_PATH" 2>/dev/null || echo "0")
    RECOMMENDATIONS_COUNT=$(awk '/^## Recommendations$/,/^## [^R]/ {if (/^[0-9]+\./) count++} END {print count}' "$REPORT_PATH" 2>/dev/null || echo "0")
  fi

  FORMATTED_METADATA+="Report $((i + 1)): $TITLE
  - Type: $REPORT_TYPE
  - Findings: $FINDINGS_COUNT
  - Recommendations: $RECOMMENDATIONS_COUNT
  - Path: $REPORT_PATH (use Read tool to access full content)

"
done

# === PERSIST METADATA ===
append_workflow_state "REPORT_METADATA_JSON<<METADATA_EOF
$REPORT_METADATA_JSON
METADATA_EOF"

append_workflow_state "FORMATTED_METADATA<<FORMATTED_EOF
$FORMATTED_METADATA
FORMATTED_EOF"

echo ""
echo "Metadata extraction complete"
echo "Context reduction: ~110 tokens per report (vs ~2,500 tokens full content)"
echo ""
```

## Block 2a: Research Verification and Planning Setup

**EXECUTE NOW**: Verify research artifacts and prepare for planning:

**[SETUP]**: This block validates research completion and pre-calculates PLAN_PATH for the hard barrier pattern.

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
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/lean_plan_state_id.txt"
if [ ! -f "$STATE_ID_FILE" ]; then
  echo "ERROR: WORKFLOW_ID file not found" >&2
  exit 1
fi
WORKFLOW_ID=$(cat "$STATE_ID_FILE")

# === VALIDATE WORKFLOW_ID ===
# CRITICAL: Call validate_workflow_id AFTER state-persistence.sh is sourced
WORKFLOW_ID=$(validate_workflow_id "$WORKFLOW_ID" "lean_plan")
export WORKFLOW_ID

# === SETUP BASH ERROR TRAP ===
# CRITICAL: Setup trap AFTER libraries loaded (replaces broken defensive trap pattern)
COMMAND_NAME="/lean-plan"
USER_ARGS="${FEATURE_DESCRIPTION:-lean_plan_workflow}"
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
validate_state_restoration "COMMAND_NAME" "USER_ARGS" "STATE_FILE" "TOPIC_PATH" "RESEARCH_DIR" || {
  echo "ERROR: State restoration failed - critical variables missing" >&2
  exit 1
}

# === RESTORE ERROR LOGGING CONTEXT ===
if [ -z "${COMMAND_NAME:-}" ]; then
  COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "/lean:plan")
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
LEAN_PROJECT_PATH="${LEAN_PROJECT_PATH:-}"

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
    "State transition to PLAN failed - research validation incomplete" \
    "bash_block_2a" \
    "$(jq -n --arg state "$STATE_PLAN" '{target_state: $state}')"

  echo "ERROR: State transition to PLAN failed - research validation incomplete" >&2
  echo "Cannot proceed to planning phase until research reports are validated" >&2
  exit 1
fi

echo ""
echo "=== State Transition Gating ==="
echo "  Research Phase: COMPLETE"
echo "  Planning Phase: STARTING"
echo "  State: RESEARCH → PLAN"
echo ""
echo ""

# === PREPARE PLAN PATH (Hard Barrier Pattern) ===
PLAN_NUMBER="001"
PLAN_FILENAME="${PLAN_NUMBER}-$(echo "$TOPIC_NAME" | tr '_' '-' | cut -c1-40)-plan.md"
PLAN_PATH="${PLANS_DIR}/${PLAN_FILENAME}"

# Validate PLAN_PATH is absolute (defensive programming)
[[ "${PLAN_PATH:-}" = /* ]]
IS_ABSOLUTE_PLAN_PATH=$?
if [ $IS_ABSOLUTE_PLAN_PATH -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "PLAN_PATH is not absolute" \
    "bash_block_2" \
    "$(jq -n --arg path "$PLAN_PATH" '{plan_path: $path, expected: "absolute path starting with /"}')"
  echo "ERROR: PLAN_PATH must be absolute path: $PLAN_PATH" >&2
  exit 1
fi

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
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "Failed to persist state transitions" \
    "bash_block_state_save" \
    "$(jq -n --arg file "${STATE_FILE:-unknown}" '{state_file: $file}')"
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
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "Failed to source standards-extraction library" \
    "bash_block_2_standards" \
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
      "bash_block_2_standards" \
      "{}"
    echo "WARNING: Standards extraction failed, proceeding without standards" >&2
    FORMATTED_STANDARDS=""
  }
fi

# === EXTRACT LEAN PROJECT STANDARDS ===
# Check for Lean-specific style guide in project
LEAN_STYLE_GUIDE=""
if [ -n "${LEAN_PROJECT_PATH:-}" ] && [ -f "${LEAN_PROJECT_PATH}/LEAN_STYLE_GUIDE.md" ]; then
  LEAN_STYLE_GUIDE=$(cat "${LEAN_PROJECT_PATH}/LEAN_STYLE_GUIDE.md" 2>/dev/null || echo "")
  if [ -n "$LEAN_STYLE_GUIDE" ]; then
    echo "Extracted Lean style guide from project"
  fi
fi

# === EXTRACT NON-INTERACTIVE TESTING STANDARDS ===
# Extract testing standards for Lean proof validation automation
TESTING_STANDARD_PATH="${CLAUDE_PROJECT_DIR}/.claude/docs/reference/standards/non-interactive-testing-standard.md"
if [ -f "$TESTING_STANDARD_PATH" ]; then
  TESTING_STANDARDS=$(extract_testing_standards "$TESTING_STANDARD_PATH" 2>/dev/null) || {
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "execution_error" \
      "Testing standards extraction failed" \
      "bash_block_2_testing_standards" \
      "{}"
    echo "WARNING: Testing standards extraction failed, proceeding without testing standards" >&2
    TESTING_STANDARDS=""
  }

  if [ -n "$TESTING_STANDARDS" ]; then
    echo "Injecting non-interactive testing standards (Lean-specific patterns)"
  fi
else
  echo "Non-interactive testing standard not found, proceeding without testing standards"
  TESTING_STANDARDS=""
fi

# Persist standards for Block 3 divergence detection
append_workflow_state "FORMATTED_STANDARDS<<STANDARDS_EOF
$FORMATTED_STANDARDS
STANDARDS_EOF"

append_workflow_state "LEAN_STYLE_GUIDE<<LEAN_STYLE_EOF
$LEAN_STYLE_GUIDE
LEAN_STYLE_EOF"

if ! save_completed_states_to_state; then
  echo "WARNING: Failed to persist COMPLETED_STATES to state file" >&2
fi

if [ -n "$FORMATTED_STANDARDS" ]; then
  STANDARDS_COUNT=$(echo "$FORMATTED_STANDARDS" | grep -c "^###" || echo 0)
  echo "Extracted $STANDARDS_COUNT standards sections for lean-plan-architect"
else
  echo "No standards extracted (graceful degradation)"
fi

echo ""
echo "=== Planning Setup Complete ==="
echo "  Plan Path: $PLAN_PATH"
echo "  Standards Sections: ${STANDARDS_COUNT:-0}"
echo "  Research Reports: $REPORT_COUNT"
echo ""
echo "Ready for lean-plan-architect invocation"
```

## Block 2b-exec: Plan Creation (Hard Barrier Invocation)

**EXECUTE NOW**: USE the Task tool to invoke the lean-plan-architect agent.

**[HARD BARRIER]**: This is a MANDATORY delegation point. The orchestrator has pre-calculated PLAN_PATH and will validate the artifact exists after you return. Bypassing this Task invocation will cause hard barrier failure in Block 2c.

**CRITICAL DELEGATION REQUIREMENTS**:
- You MUST use the Task tool to invoke lean-plan-architect
- DO NOT use Write tool directly to create the plan file
- DO NOT bypass agent delegation with direct file creation
- The agent performs theorem dependency analysis, phase metadata generation, and standards validation
- Direct plan creation bypasses critical workflow steps and will fail validation

Task {
  subagent_type: "general-purpose"
  description: "Create Lean implementation plan for ${FEATURE_DESCRIPTION} with theorem-level granularity"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-plan-architect.md

    You are creating a Lean formalization implementation plan for: lean-plan workflow

    **Input Contract (Hard Barrier Pattern)**:
    - PLAN_PATH: ${PLAN_PATH}
    - FEATURE_DESCRIPTION: ${FEATURE_DESCRIPTION}
    - LEAN_PROJECT_PATH: ${LEAN_PROJECT_PATH}

    **CRITICAL**: You MUST write the implementation plan to the EXACT path specified in PLAN_PATH.
    The orchestrator has pre-calculated this path and will validate the file exists after you return.
    DO NOT calculate your own output path - use PLAN_PATH exactly as provided.

    **Workflow-Specific Context**:
    - Feature Description: ${FEATURE_DESCRIPTION}
    - Workflow Type: research-and-plan (Lean specialization)
    - Operation Mode: new plan creation
    - Lean Project Path: ${LEAN_PROJECT_PATH}
    - Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH:-none}
    - Archived Prompt File: ${ARCHIVED_PROMPT_PATH:-none}

    **Research Reports Metadata (Metadata-Only Context Passing)**:
    ${FORMATTED_METADATA}

    **CRITICAL INSTRUCTION**:
    - The above is METADATA ONLY (not full report content)
    - You have Read tool access to full reports at specified paths
    - Use Read tool to access full research content when needed for planning
    - DO NOT expect full report content in this prompt (95% context reduction)

    **Project Standards**:
    ${FORMATTED_STANDARDS}

    **Testing Automation Standards (Lean Compiler Validation)**:
    ${TESTING_STANDARDS}

    **Lean Project Standards**:
    ${LEAN_STYLE_GUIDE}

    If an archived prompt file is provided (not 'none'), reference it for complete context.

    IMPORTANT: If your planned approach conflicts with provided standards for well-motivated reasons, include Phase 0 to revise standards with clear justification and user warning. See Standards Divergence Protocol in lean-plan-architect.md.

    **CRITICAL FORMAT REQUIREMENTS FOR NEW PLANS**:
    This is a NEW Lean plan creation (not revision). You MUST follow these format rules:

    1. Metadata Status Field:
       - MUST be exactly: **Status**: [NOT STARTED]
       - Do NOT use [IN PROGRESS], [COMPLETE], or [BLOCKED]

    2. Phase Heading Format:
       - ALL phases MUST include [NOT STARTED] marker
       - Format: ### Phase N: Name [NOT STARTED]
       - Do NOT use [COMPLETE], [PARTIAL], or [IN PROGRESS]

    3. Checkbox Format:
       - ALL Success Criteria MUST use: - [ ] (unchecked)
       - ALL theorem tasks MUST use: - [ ] (unchecked)
       - Do NOT pre-mark checkboxes as [x] or [~]

    4. Theorem Phase Format:
       - Each theorem MUST have Goal specification (Lean 4 type)
       - Each theorem MUST have Strategy (proof approach)
       - Each theorem MUST have Complexity (Simple/Medium/Complex)
       - Use dependencies: [] for phase dependency tracking

    5. Lean Metadata Fields:
       - Include **Lean File** field (absolute path for Tier 1 discovery)
       - Include **Lean Project** field (lakefile.toml location)

    **WHY THIS MATTERS**:
    - /lean depends on theorem specifications with goals and strategies
    - Wave-based parallel execution requires dependency tracking
    - Proper metadata enables Tier 1 Lean file discovery

    Execute Lean planning according to behavioral guidelines and return completion signal:
    PLAN_CREATED: ${PLAN_PATH}
  "
}

## Block 2c: Plan Hard Barrier Validation

**EXECUTE NOW**: Validate that lean-plan-architect created the plan file at the pre-calculated path.

This is the **hard barrier** - the workflow CANNOT proceed unless the plan file exists and meets minimum size requirements.

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

# === RESTORE STATE ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/lean_plan_state_id.txt"
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

COMMAND_NAME="/lean-plan"
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
echo "=== Plan Hard Barrier Validation ==="
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
    "bash_block_2c" \
    "$(jq -n '{plan_path: "missing"}')"
  echo "ERROR: PLAN_PATH not set - state restoration failed" >&2
  exit 1
fi

echo "Expected plan file: $PLAN_PATH"

# === AGENT DELEGATION VERIFICATION ===
# Verify lean-plan-architect returned PLAN_CREATED signal
# This ensures the plan was created by the agent, not via direct Write bypass
AGENT_OUTPUT_PATH="${CLAUDE_PROJECT_DIR}/.claude/output/lean-plan-output.md"
AGENT_SIGNAL=""

if [ -f "$AGENT_OUTPUT_PATH" ]; then
  # Extract PLAN_CREATED signal from agent output
  AGENT_SIGNAL=$(grep "PLAN_CREATED:" "$AGENT_OUTPUT_PATH" 2>/dev/null | tail -1)

  if [ -n "$AGENT_SIGNAL" ]; then
    # Extract path from signal
    SIGNAL_PATH=$(echo "$AGENT_SIGNAL" | sed 's/PLAN_CREATED: *//')

    # Verify signal path matches expected PLAN_PATH
    if [ "$SIGNAL_PATH" = "$PLAN_PATH" ]; then
      echo "✓ Agent delegation verified - PLAN_CREATED signal received"
    else
      log_command_error \
        "$COMMAND_NAME" \
        "$WORKFLOW_ID" \
        "$USER_ARGS" \
        "validation_error" \
        "Agent returned PLAN_CREATED with mismatched path" \
        "delegation_verification" \
        "$(jq -n --arg expected "$PLAN_PATH" --arg received "$SIGNAL_PATH" '{expected: $expected, received: $received}')"
      echo "WARNING: Agent signal path mismatch (expected: $PLAN_PATH, received: $SIGNAL_PATH)" >&2
    fi
  else
    # No PLAN_CREATED signal found - possible delegation bypass
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "validation_error" \
      "PLAN_CREATED signal missing from agent output" \
      "delegation_verification" \
      "$(jq -n --arg path "$PLAN_PATH" '{expected_signal: "PLAN_CREATED", plan_path: $path}')"
    echo "WARNING: PLAN_CREATED signal not found in agent output" >&2
    echo "This may indicate the agent bypassed Task invocation" >&2
  fi
else
  echo "⚠ Agent output file not found at $AGENT_OUTPUT_PATH, skipping signal verification"
fi

# HARD BARRIER: Validate agent artifact using validation-utils.sh
# validate_agent_artifact checks file existence and minimum size (500 bytes for plans)
if ! validate_agent_artifact "$PLAN_PATH" 500 "implementation plan"; then
  # Error already logged by validate_agent_artifact
  echo "ERROR: HARD BARRIER FAILED - Plan creation validation failed" >&2
  echo "" >&2
  echo "This indicates the lean-plan-architect did not create valid output." >&2
  echo "The plan file is either missing or too small (< 500 bytes)." >&2
  echo "" >&2
  echo "To retry: Re-run the /lean-plan command with the same arguments" >&2
  echo "" >&2
  exit 1
fi

echo "✓ Hard barrier passed - plan file validated"

# === VALIDATE PHASE METADATA PRESENCE ===
# Check for Phase Routing Summary (proves agent-created plan with proper metadata)
if grep -q "### Phase Routing Summary" "$PLAN_PATH"; then
  IMPLEMENTER_COUNT=$(grep -c "^implementer:" "$PLAN_PATH" || echo 0)
  echo "✓ Phase metadata verified - $IMPLEMENTER_COUNT phases with implementer field"
else
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Plan missing Phase Routing Summary table" \
    "phase_metadata_verification" \
    "$(jq -n --arg path "$PLAN_PATH" '{plan_path: $path, missing: "Phase Routing Summary"}')"
  echo "WARNING: Plan missing Phase Routing Summary" >&2
  echo "This indicates the plan may not have proper phase metadata" >&2
fi

# === VALIDATE PLAN METADATA ===
# Validate phase metadata format (non-blocking)
echo "Validating plan metadata format..."

VALIDATOR_PATH="${CLAUDE_PROJECT_DIR}/.claude/scripts/lint/validate-plan-metadata.sh"
if [ -f "$VALIDATOR_PATH" ]; then
  VALIDATION_OUTPUT=$("$VALIDATOR_PATH" "$PLAN_PATH" 2>&1)
  VALIDATION_EXIT=$?

  if [ $VALIDATION_EXIT -ne 0 ]; then
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "validation_error" \
      "Generated plan failed metadata validation" \
      "plan_validation" \
      "$(jq -n --arg path "$PLAN_PATH" --arg output "$VALIDATION_OUTPUT" '{plan_path: $path, validation_output: $output}')"

    echo "WARNING: Plan metadata validation failed (exit code $VALIDATION_EXIT)" >&2
    echo "$VALIDATION_OUTPUT" >&2
    echo "Plan created but may not meet metadata standards" >&2
    # Don't exit - allow workflow to complete with warning
  else
    echo "✓ Plan metadata validation passed"
  fi
else
  echo "⚠ Plan metadata validator not found at $VALIDATOR_PATH, skipping validation"
fi

echo ""
```

## Block 3: Plan Verification and Completion

**EXECUTE NOW**: Verify plan artifacts with Lean-specific validation and complete workflow:

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
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/lean_plan_state_id.txt"
if [ ! -f "$STATE_ID_FILE" ]; then
  echo "ERROR: WORKFLOW_ID file not found" >&2
  exit 1
fi
WORKFLOW_ID=$(cat "$STATE_ID_FILE")

# === VALIDATE WORKFLOW_ID ===
# CRITICAL: Call validate_workflow_id AFTER state-persistence.sh is sourced
WORKFLOW_ID=$(validate_workflow_id "$WORKFLOW_ID" "lean_plan")
export WORKFLOW_ID

# === SETUP BASH ERROR TRAP ===
# CRITICAL: Setup trap AFTER libraries loaded (replaces broken defensive trap pattern)
COMMAND_NAME="/lean-plan"
USER_ARGS="${FEATURE_DESCRIPTION:-lean_plan_workflow}"
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
validate_state_restoration "COMMAND_NAME" "USER_ARGS" "STATE_FILE" "TOPIC_PATH" "RESEARCH_DIR" || {
  echo "ERROR: State restoration failed - critical variables missing" >&2
  exit 1
}

# === RESTORE ERROR LOGGING CONTEXT ===
if [ -z "${COMMAND_NAME:-}" ]; then
  COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "/lean:plan")
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

# === LEAN-SPECIFIC VALIDATION ===
echo "Running Lean-specific validation..."

# 1. Theorem count validation
THEOREM_COUNT=$(grep -c "^- \[ \] \`theorem_" "$PLAN_PATH" || echo "0")
if [ "$THEOREM_COUNT" -eq 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Plan has no theorem specifications" \
    "bash_block_3" \
    "$(jq -n --arg path "$PLAN_PATH" '{plan_path: $path}')"

  echo "ERROR: Plan has no theorem specifications" >&2
  exit 1
fi

echo "  ✓ Theorem count: $THEOREM_COUNT"

# 2. Goal specification validation
GOAL_COUNT=$(grep -c "  - Goal:" "$PLAN_PATH" || echo "0")
if [ "$GOAL_COUNT" -lt "$THEOREM_COUNT" ]; then
  echo "  WARNING: Not all theorems have goal specifications ($GOAL_COUNT/$THEOREM_COUNT)"
fi

# 3. Lean file metadata validation
if ! grep -q "^\- \*\*Lean File\*\*:" "$PLAN_PATH"; then
  echo "  WARNING: Plan missing **Lean File** metadata (Tier 1 discovery will fail)"
fi

echo "Lean-specific validation complete"

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
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "Failed to persist state transitions" \
    "bash_block_state_save" \
    "$(jq -n --arg file "${STATE_FILE:-unknown}" '{state_file: $file}')"
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
SUMMARY_TEXT="Created Lean implementation plan with $PHASE_COUNT phases ($THEOREM_COUNT theorems, estimated $ESTIMATED_HOURS hours) based on $REPORT_COUNT research reports. Plan provides theorem-level roadmap for formalizing ${FEATURE_DESCRIPTION}."

# Build artifacts section
ARTIFACTS="  📊 Reports: $RESEARCH_DIR/ ($REPORT_COUNT files)
  📄 Plan: $PLAN_PATH
  🔍 Theorems: $THEOREM_COUNT total"

# Build next steps
NEXT_STEPS="  • Review plan: cat $PLAN_PATH
  • Begin proving: /lean $PLAN_PATH --prove-all
  • Review research: ls -lh $RESEARCH_DIR/
  • Check theorems: grep -c 'theorem_' $PLAN_PATH"

# Print standardized summary (no phases for plan command)
print_artifact_summary "Lean Plan" "$SUMMARY_TEXT" "" "$ARTIFACTS" "$NEXT_STEPS"

# Emit completion reminder
echo ""
echo "📋 Next Step: Execute plan with /lean $PLAN_PATH --prove-all"
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

- **Lean project not found**: Ensure lakefile.toml exists, or use --project flag
- **Research fails**: Check lean-research-specialist agent behavioral file compliance
- **Planning fails**: Check lean-plan-architect agent behavioral file
- **Plan file empty**: Verify feature description is clear and research reports exist
- **No theorems in plan**: Verify research reports contain theorem information
- **Circular dependencies**: Check plan dependencies using dependency-analyzer.sh
- **Missing Lean File metadata**: Plan won't work with /lean Tier 1 discovery
