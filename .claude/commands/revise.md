---
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob, Edit
argument-hint: <revision-description-with-plan-path> [--file <path>] [--complexity 1-4] [--dry-run]
description: Research and revise existing implementation plan workflow
command-type: primary
dependent-agents:
  - research-specialist
  - research-sub-supervisor
  - plan-architect
library-requirements:
  - workflow-state-machine.sh: ">=2.0.0"
  - state-persistence.sh: ">=1.5.0"
documentation: See .claude/docs/guides/commands/revise-command-guide.md for complete usage guide
---

# /revise - Research-and-Revise Workflow Command

YOU ARE EXECUTING a research-and-revise workflow that creates research reports based on new insights and then revises an existing implementation plan.

**Workflow Type**: research-and-revise
**Terminal State**: plan (after plan revision complete)
**Expected Output**: Research reports + revised plan (with backup of original)

## Block 1: Capture Revision Description

**EXECUTE NOW**: The user invoked `/revise "<revision-description-with-plan-path>"`. Capture that description.

In the **small bash block below**, replace `YOUR_REVISION_DESCRIPTION_HERE` with the actual revision description (keeping the quotes).

**Example**: If user ran `/revise "revise plan at .claude/specs/123_auth/plans/001_plan.md based on new security requirements"`, change:
- FROM: `echo "YOUR_REVISION_DESCRIPTION_HERE" > "$TEMP_FILE"`
- TO: `echo "revise plan at .claude/specs/123_auth/plans/001_plan.md based on new security requirements" > "$TEMP_FILE"`

Execute this bash block with your substitution:

```bash
set +H  # CRITICAL: Disable history expansion
set -e  # Fail-fast per code-standards.md

# Minimal error handling for argument capture block
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  if [ -f "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" ]; then
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
      echo "ERROR: Failed to source error-handling.sh" >&2
      exit 1
    }
    ensure_error_log_exists 2>/dev/null
    setup_bash_error_trap "/revise" "revise_capture_$(date +%s)" "argument_capture" 2>/dev/null || true
  fi
fi

# SUBSTITUTE THE REVISION DESCRIPTION IN THE LINE BELOW
# CRITICAL: Replace YOUR_REVISION_DESCRIPTION_HERE with the actual revision description from the user
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
# Use timestamp-based filename for concurrent execution safety
TEMP_FILE="${HOME}/.claude/tmp/revise_arg_$(date +%s%N).txt"
echo "YOUR_REVISION_DESCRIPTION_HERE" > "$TEMP_FILE"
# Save temp file path for Part 2 to read
echo "$TEMP_FILE" > "${HOME}/.claude/tmp/revise_arg_path.txt"
echo "Revision description captured to $TEMP_FILE"
```

## Block 2: Read and Validate Revision Description

**EXECUTE NOW**: Read the captured description, extract plan path, and validate:

```bash
set +H  # CRITICAL: Disable history expansion
set -e  # Fail-fast per code-standards.md

# Detect project directory for error logging
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    [ -d "$current_dir/.claude" ] && { CLAUDE_PROJECT_DIR="$current_dir"; break; }
    current_dir="$(dirname "$current_dir")"
  done
fi

# Source error handling early for trap setup
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
ensure_error_log_exists

# Set initial command metadata for error logging
WORKFLOW_ID="revise_init_$(date +%s)"
COMMAND_NAME="/revise"
USER_ARGS="$*"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# Setup bash error trap
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# Read revision description from file (written in Part 1)
REVISE_DESC_PATH_FILE="${HOME}/.claude/tmp/revise_arg_path.txt"

if [ -f "$REVISE_DESC_PATH_FILE" ]; then
  REVISE_DESC_FILE=$(cat "$REVISE_DESC_PATH_FILE")
else
  # Fallback to legacy fixed filename for backward compatibility
  REVISE_DESC_FILE="${HOME}/.claude/tmp/revise_arg.txt"
fi

if [ -f "$REVISE_DESC_FILE" ]; then
  REVISION_DESCRIPTION=$(cat "$REVISE_DESC_FILE" 2>/dev/null || echo "")
else
  echo "ERROR: Revision description file not found: $REVISE_DESC_FILE"
  echo "This usually means Part 1 (argument capture) didn't execute."
  echo "Usage: /revise \"revise plan at /path/to/plan.md based on INSIGHTS\""
  exit 1
fi

if [ -z "$REVISION_DESCRIPTION" ]; then
  echo "ERROR: Revision description is empty"
  echo "File exists but contains no content: $REVISE_DESC_FILE"
  echo "Usage: /revise \"revise plan at /path/to/plan.md based on INSIGHTS\""
  exit 1
fi

# Parse optional --complexity flag (default: 2 for research-and-revise)
DEFAULT_COMPLEXITY=2
RESEARCH_COMPLEXITY="$DEFAULT_COMPLEXITY"

# Support both embedded and explicit flag formats
if [[ "$REVISION_DESCRIPTION" =~ --complexity[[:space:]]+([1-4]) ]]; then
  RESEARCH_COMPLEXITY="${BASH_REMATCH[1]}"
  # Strip flag from revision description
  # Use bash parameter expansion instead of xargs for quote-safe trimming
  REVISION_DESCRIPTION=$(echo "$REVISION_DESCRIPTION" | sed 's/--complexity[[:space:]]*[1-4]//')
  REVISION_DESCRIPTION="${REVISION_DESCRIPTION#"${REVISION_DESCRIPTION%%[![:space:]]*}"}"
  REVISION_DESCRIPTION="${REVISION_DESCRIPTION%"${REVISION_DESCRIPTION##*[![:space:]]}"}"
fi

# Validation: reject invalid complexity values
echo "$RESEARCH_COMPLEXITY" | grep -Eq "^[1-4]$"
COMPLEXITY_VALID=$?
if [ $COMPLEXITY_VALID -ne 0 ]; then
  echo "ERROR: Invalid research complexity: $RESEARCH_COMPLEXITY (must be 1-4)" >&2
  exit 1
fi

# Parse optional --dry-run flag
DRY_RUN="false"
if [[ "$REVISION_DESCRIPTION" =~ --dry-run ]]; then
  DRY_RUN="true"
  # Strip flag from revision description
  # Use bash parameter expansion instead of xargs for quote-safe trimming
  REVISION_DESCRIPTION=$(echo "$REVISION_DESCRIPTION" | sed 's/--dry-run//')
  REVISION_DESCRIPTION="${REVISION_DESCRIPTION#"${REVISION_DESCRIPTION%%[![:space:]]*}"}"
  REVISION_DESCRIPTION="${REVISION_DESCRIPTION%"${REVISION_DESCRIPTION##*[![:space:]]}"}"
fi

# Parse optional --file flag for long prompt handling
ORIGINAL_PROMPT_FILE_PATH=""
if [[ "$REVISION_DESCRIPTION" =~ --file[[:space:]]+([^[:space:]]+) ]]; then
  ORIGINAL_PROMPT_FILE_PATH="${BASH_REMATCH[1]}"
  # Strip --file flag and path from description
  # Use bash parameter expansion instead of xargs for quote-safe trimming
  REVISION_DESCRIPTION=$(echo "$REVISION_DESCRIPTION" | sed 's/--file[[:space:]]*[^[:space:]]*//')
  REVISION_DESCRIPTION="${REVISION_DESCRIPTION#"${REVISION_DESCRIPTION%%[![:space:]]*}"}"
  REVISION_DESCRIPTION="${REVISION_DESCRIPTION%"${REVISION_DESCRIPTION##*[![:space:]]}"}"

  # Convert relative path to absolute (preprocessing-safe pattern)
  [[ "${ORIGINAL_PROMPT_FILE_PATH:-}" = /* ]]
  IS_ABSOLUTE_PATH=$?
  if [ $IS_ABSOLUTE_PATH -ne 0 ]; then
    ORIGINAL_PROMPT_FILE_PATH="$(pwd)/${ORIGINAL_PROMPT_FILE_PATH:-}"
  fi

  # Validate file exists
  if [ ! -f "${ORIGINAL_PROMPT_FILE_PATH:-}" ]; then
    echo "ERROR: Prompt file not found: ${ORIGINAL_PROMPT_FILE_PATH:-}" >&2
    echo "DIAGNOSTIC: Ensure --file path is correct and file exists" >&2
    exit 1
  fi

  # Read file content as revision description
  FILE_CONTENT=$(cat "${ORIGINAL_PROMPT_FILE_PATH:-}")
  if [ -z "$FILE_CONTENT" ]; then
    echo "ERROR: Prompt file is empty: ${ORIGINAL_PROMPT_FILE_PATH:-}" >&2
    echo "DIAGNOSTIC: The prompt file must contain both the plan path and revision details" >&2
    exit 1
  fi

  REVISION_DESCRIPTION="$FILE_CONTENT"
  echo "Loaded revision description from file: ${ORIGINAL_PROMPT_FILE_PATH:-}"
elif [[ "$REVISION_DESCRIPTION" =~ --file$ ]] || [[ "$REVISION_DESCRIPTION" =~ --file[[:space:]]*$ ]]; then
  echo "ERROR: --file flag requires a path argument" >&2
  echo "USAGE: /revise \"--file /path/to/prompt.md\"" >&2
  exit 1
fi

# Extract existing plan path from revision description
# Matches: /path/to/file.md or ./relative/path.md or ../relative/path.md or .claude/path.md
EXISTING_PLAN_PATH=$(echo "$REVISION_DESCRIPTION" | grep -oE '[./][^ ]+\.md' | head -1)

# Validate plan path exists
if [ -z "${EXISTING_PLAN_PATH:-}" ]; then
  echo "ERROR: No plan path found in revision description" >&2
  echo "USAGE: /revise \"revise plan at /path/to/plan.md based on INSIGHTS\"" >&2
  exit 1
fi

if [ ! -f "$EXISTING_PLAN_PATH" ]; then
  echo "ERROR: Existing plan not found: $EXISTING_PLAN_PATH" >&2
  echo "DIAGNOSTIC: Ensure plan file exists before revision" >&2
  exit 1
fi

# Extract revision details (everything after plan path)
# Escape regex special characters in plan path for safe sed processing
ESCAPED_PLAN_PATH=$(printf '%s\n' "$EXISTING_PLAN_PATH" | sed 's/[[\.*^$()+?{|]/\\&/g')
# Use bash parameter expansion instead of xargs for quote-safe trimming
REVISION_DETAILS=$(echo "$REVISION_DESCRIPTION" | sed "s|.*$ESCAPED_PLAN_PATH||") || true
REVISION_DETAILS="${REVISION_DETAILS#"${REVISION_DETAILS%%[![:space:]]*}"}"
REVISION_DETAILS="${REVISION_DETAILS%"${REVISION_DETAILS##*[![:space:]]}"}"

# Validate revision details are not empty after extraction
if [ -z "$REVISION_DETAILS" ]; then
  echo "WARNING: Could not extract revision details after plan path" >&2
  echo "Using full description as revision context" >&2
  REVISION_DETAILS="$REVISION_DESCRIPTION"
fi

echo "=== Research-and-Revise Workflow ==="
echo "Existing Plan: $EXISTING_PLAN_PATH"
echo "Revision Details: $REVISION_DETAILS"
echo "Research Complexity: $RESEARCH_COMPLEXITY"
echo "Dry Run: $DRY_RUN"
echo ""

# Dry-run execution gate - preview and exit before state machine
if [ "$DRY_RUN" = "true" ]; then
  echo "=== DRY-RUN MODE ==="
  echo ""
  echo "Would perform the following actions:"
  echo ""
  echo "1. Initialize state machine for research-and-revise workflow"
  echo "2. Execute research phase:"
  echo "   - Analyze revision requirements: $REVISION_DETAILS"
  echo "   - Create research reports in: $(dirname "$(dirname "$EXISTING_PLAN_PATH")")/reports/"
  echo "   - Research complexity level: $RESEARCH_COMPLEXITY"
  echo "3. Execute plan revision phase:"
  echo "   - Create backup of existing plan"
  echo "   - Revise plan based on research insights"
  echo "   - Verify plan modifications"
  echo "4. Complete workflow and display summary"
  echo ""
  echo "No changes were made (dry-run mode)"
  exit 0
fi
```

## Block 3: State Machine Initialization

**EXECUTE NOW**: Initialize the state machine and source required libraries:

```bash
set +H  # CRITICAL: Disable history expansion
# Detect project directory (bootstrap pattern)
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  # Fallback: search upward for .claude/ directory
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
  echo "DIAGNOSTIC: No git repository found and no .claude/ directory in parent tree" >&2
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

# === INITIALIZE ERROR LOGGING ===
ensure_error_log_exists

# Set command metadata for error logging
COMMAND_NAME="/revise"
USER_ARGS="$REVISION_DETAILS"
export COMMAND_NAME USER_ARGS

# Verify library versions
check_library_requirements "$(cat <<'EOF'
workflow-state-machine.sh: ">=2.0.0"
state-persistence.sh: ">=1.5.0"
EOF
)" || exit 1

# === PRE-FLIGHT FUNCTION VALIDATION ===
# Verify required functions are available before using them (prevents exit 127 errors)
declare -f append_workflow_state >/dev/null 2>&1
FUNCTION_CHECK=$?
if [ $FUNCTION_CHECK -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "revise_preflight" \
    "$USER_ARGS" \
    "execution_error" \
    "append_workflow_state function not available - library sourcing failed" \
    "bash_block_1" \
    "$(jq -n '{library: "state-persistence.sh", function: "append_workflow_state"}')"
  echo "ERROR: append_workflow_state function not available after sourcing state-persistence.sh" >&2
  exit 1
fi

# === DEFINE STATE VERIFICATION HELPER ===
# Validates state load success and required variables
verify_state_loaded() {
  local required_vars="$1"  # Space-separated list

  if [ -z "${STATE_FILE:-}" ]; then
    echo "ERROR: STATE_FILE not set after load_workflow_state" >&2
    return 1
  fi

  if [ ! -f "$STATE_FILE" ]; then
    echo "ERROR: State file not found: $STATE_FILE" >&2
    return 1
  fi

  for var in $required_vars; do
    local var_value="${!var:-}"
    if [ -z "$var_value" ]; then
      echo "ERROR: Required variable $var not restored after state load" >&2
      return 1
    fi
  done

  return 0
}

# Hardcode workflow type
WORKFLOW_TYPE="research-and-revise"
TERMINAL_STATE="plan"
COMMAND_NAME="revise"

# Generate WORKFLOW_ID with nanosecond-precision for concurrent execution safety
WORKFLOW_ID="revise_$(date +%s%N)"
export WORKFLOW_ID

# Capture state file path for append_workflow_state
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
export STATE_FILE

# === PERSIST ERROR LOGGING CONTEXT ===
append_workflow_state "COMMAND_NAME" "${COMMAND_NAME:-}"
append_workflow_state "USER_ARGS" "${USER_ARGS:-}"
append_workflow_state "WORKFLOW_ID" "${WORKFLOW_ID:-}"

# === SETUP BASH ERROR TRAP ===
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# Validate state file creation
if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "Failed to initialize workflow state file" \
    "bash_block_3" \
    "$(jq -n --arg path "${STATE_FILE:-UNDEFINED}" '{expected_path: $path}')"

  echo "ERROR: Failed to initialize workflow state" >&2
  exit 1
fi

# Initialize state machine with return code verification
sm_init \
  "$REVISION_DESCRIPTION" \
  "$COMMAND_NAME" \
  "$WORKFLOW_TYPE" \
  "$RESEARCH_COMPLEXITY" \
  "[]" 2>&1
SM_INIT_EXIT=$?
if [ $SM_INIT_EXIT -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State machine initialization failed" \
    "bash_block_3" \
    "$(jq -n --arg type "$WORKFLOW_TYPE" --argjson complexity "$RESEARCH_COMPLEXITY" \
       '{workflow_type: $type, complexity: $complexity}')"

  echo "ERROR: State machine initialization failed" >&2
  echo "DIAGNOSTIC Information:" >&2
  echo "  - Revision Description: $REVISION_DESCRIPTION" >&2
  echo "  - Command Name: $COMMAND_NAME" >&2
  echo "  - Workflow Type: $WORKFLOW_TYPE" >&2
  echo "  - Research Complexity: $RESEARCH_COMPLEXITY" >&2
  echo "POSSIBLE CAUSES:" >&2
  echo "  - Library version incompatibility (require workflow-state-machine.sh >=2.0.0)" >&2
  echo "  - State file corruption in ~/.claude/data/state/" >&2
  exit 1
fi

echo "✓ State machine initialized (WORKFLOW_ID: $WORKFLOW_ID)"
echo ""
```

## Block 3a: State Machine Initialization Verification

**HARD BARRIER**: Validate state machine initialized before proceeding to research phase.

**EXECUTE NOW**: This verification block ensures state machine was properly initialized. Workflow CANNOT proceed without valid state.

```bash
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e  # Fail-fast per code-standards.md

# === DETECT PROJECT DIRECTORY ===
if [ -z "$CLAUDE_PROJECT_DIR" ]; then
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
fi

# Re-source libraries (three-tier sourcing pattern)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Cannot load state-persistence library" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Cannot load error-handling library" >&2
  exit 1
}

ensure_error_log_exists

# Restore state from previous block
STATE_FILE=$(discover_latest_state_file "revise")
if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  log_command_error \
    "/revise" \
    "unknown" \
    "${USER_ARGS:-}" \
    "state_error" \
    "HARD BARRIER FAILED: State file discovery failed" \
    "bash_block_3a" \
    "$(jq -n '{pattern: "workflow_revise_*.sh"}')"

  echo "ERROR: HARD BARRIER FAILED - Failed to discover state file from previous block" >&2
  echo "DIAGNOSTIC: Block 3 should have created state file" >&2
  echo "CAUSE: State machine initialization was skipped or failed" >&2
  exit 1
fi

source "$STATE_FILE"  # WORKFLOW_ID restored
export WORKFLOW_ID

# Validate state file still exists after sourcing
if [ ! -f "$STATE_FILE" ]; then
  log_command_error \
    "/revise" \
    "$WORKFLOW_ID" \
    "${USER_ARGS:-}" \
    "state_error" \
    "HARD BARRIER FAILED: State file not found" \
    "bash_block_3a" \
    "$(jq -n --arg expected "$STATE_FILE" '{expected_file: $expected}')"

  echo "ERROR: HARD BARRIER FAILED - State file not found: $STATE_FILE" >&2
  echo "DIAGNOSTIC: Block 3 should have initialized state machine" >&2
  exit 1
fi

# Setup error trap with restored context
COMMAND_NAME="/revise"
USER_ARGS="${USER_ARGS:-}"
export COMMAND_NAME USER_ARGS
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

echo "[CHECKPOINT] Hard barrier passed: State machine initialized"
echo "Workflow ID: $WORKFLOW_ID"
echo "State file: $STATE_FILE"
echo ""
```

## Block 4a: Research Phase Setup

**CRITICAL BARRIER**: This bash block creates a hard context barrier enforcing research-specialist delegation. The block MUST be executed BEFORE the research-specialist Task invocation in Block 4b.

**EXECUTE NOW**: Transition to research state and prepare research directory:

```bash
set +H  # CRITICAL: Disable history expansion

# Re-source libraries for subprocess isolation
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

# Restore state from previous block (fail-fast pattern)
STATE_FILE=$(discover_latest_state_file "revise")
if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  echo "ERROR: Failed to discover state file from previous block" >&2
  echo "DIAGNOSTIC: Part 3 (State Machine Initialization) may not have executed" >&2
  exit 1
fi
source "$STATE_FILE"  # WORKFLOW_ID restored
export WORKFLOW_ID

# Load workflow state (subprocess isolation)
load_workflow_state "$WORKFLOW_ID" false

# === RESTORE ERROR LOGGING CONTEXT ===
if [ -z "${COMMAND_NAME:-}" ]; then
  COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "/revise")
fi
if [ -z "${USER_ARGS:-}" ]; then
  USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "")
fi
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# === SETUP BASH ERROR TRAP ===
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

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
    echo "WHERE: Block 4, research phase"
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
    "bash_block_4" \
    "$(jq -n --arg path "$STATE_FILE" '{expected_path: $path}')"

  {
    echo "[$(date)] ERROR: State file not found"
    echo "WHICH: load_workflow_state"
    echo "WHAT: File does not exist at expected path"
    echo "WHERE: Block 4, research phase"
    echo "PATH: $STATE_FILE"
  } >> "$DEBUG_LOG"
  echo "ERROR: State file not found (see $DEBUG_LOG)" >&2
  exit 1
fi

# Validate critical variables
if [ -z "${EXISTING_PLAN_PATH:-}" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "Critical variable EXISTING_PLAN_PATH not restored after state load" \
    "bash_block_4" \
    "$(jq -n --arg var "EXISTING_PLAN_PATH" '{missing_variable: $var}')"

  {
    echo "[$(date)] ERROR: Critical variables not restored"
    echo "WHICH: load_workflow_state"
    echo "WHAT: EXISTING_PLAN_PATH missing after load"
    echo "WHERE: Block 4, research phase"
    echo "EXISTING_PLAN_PATH: ${EXISTING_PLAN_PATH:-MISSING}"
  } >> "$DEBUG_LOG"
  echo "ERROR: Critical variables not restored (see $DEBUG_LOG)" >&2
  exit 1
fi

# Validate STATE_FILE is set before state transition (defensive check)
if [ -z "${STATE_FILE:-}" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "STATE_FILE not set before sm_transition" \
    "bash_block_4a" \
    "$(jq -n --arg workflow "${WORKFLOW_ID:-unknown}" '{workflow_id: $workflow}')"
  echo "ERROR: STATE_FILE not set. Call load_workflow_state first." >&2
  exit 1
fi

# Transition to research state with return code verification
sm_transition "$STATE_RESEARCH" 2>&1
SM_TRANSITION_EXIT=$?
if [ $SM_TRANSITION_EXIT -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State transition to RESEARCH failed" \
    "bash_block_4" \
    "$(jq -n --arg state "RESEARCH" '{target_state: $state}')"

  echo "ERROR: State transition to RESEARCH failed" >&2
  echo "DIAGNOSTIC Information:" >&2
  echo "  - Current State: $(sm_current_state 2>/dev/null || echo 'unknown')" >&2
  echo "  - Attempted Transition: → RESEARCH" >&2
  echo "  - Workflow Type: research-and-revise" >&2
  echo "  - Command Name: research-revise" >&2
  echo "POSSIBLE CAUSES:" >&2
  echo "  - State machine not initialized properly" >&2
  echo "  - Invalid transition from current state" >&2
  echo "  - State file corruption in ~/.claude/data/state/" >&2
  echo "TROUBLESHOOTING:" >&2
  echo "  - Verify sm_init was called successfully" >&2
  echo "  - Check state machine logs for details" >&2
  exit 1
fi
echo "=== Phase 1: Research ==="
echo ""

# Derive specs directory from existing plan path
SPECS_DIR=$(dirname "$(dirname "$EXISTING_PLAN_PATH")")
RESEARCH_DIR="${SPECS_DIR}/reports"

# Generate unique research topic for revision insights
REVISION_TOPIC_SLUG=$(echo "$REVISION_DETAILS" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//' | cut -c1-30)
REVISION_NUMBER=$(find "$RESEARCH_DIR" -name 'revision_*.md' 2>/dev/null | wc -l | xargs)
REVISION_NUMBER=$((REVISION_NUMBER + 1))

# Pre-calculate expected report path (Hard Barrier Pattern)
EXPECTED_REPORT_PATH="${RESEARCH_DIR}/${REVISION_NUMBER}-${REVISION_TOPIC_SLUG}.md"

# Validate path is absolute
[[ "$EXPECTED_REPORT_PATH" = /* ]]
IS_ABSOLUTE=$?
if [ $IS_ABSOLUTE -ne 0 ]; then
  log_command_error "/revise" "$WORKFLOW_ID" "$USER_ARGS" \
    "validation_error" \
    "EXPECTED_REPORT_PATH is not absolute" \
    "bash_block_4a" \
    "$(jq -n --arg path "$EXPECTED_REPORT_PATH" '{calculated_path: $path}')"
  echo "ERROR: Expected report path is not absolute: $EXPECTED_REPORT_PATH" >&2
  exit 1
fi

echo "Pre-calculated expected report path: $EXPECTED_REPORT_PATH"

# Persist variables for Block 4b and 4c (subprocess isolation)
append_workflow_state "SPECS_DIR" "${SPECS_DIR:-}"
append_workflow_state "RESEARCH_DIR" "${RESEARCH_DIR:-}"
append_workflow_state "REVISION_TOPIC_SLUG" "${REVISION_TOPIC_SLUG:-}"
append_workflow_state "REVISION_NUMBER" "${REVISION_NUMBER:-}"
append_workflow_state "EXISTING_PLAN_PATH" "${EXISTING_PLAN_PATH:-}"
append_workflow_state "REVISION_DETAILS" "${REVISION_DETAILS:-}"
append_workflow_state "RESEARCH_COMPLEXITY" "${RESEARCH_COMPLEXITY:-}"
append_workflow_state "EXPECTED_REPORT_PATH" "${EXPECTED_REPORT_PATH:-}"

# Removed: save_completed_states_to_state does not exist in library
# State machine already persists completed states via sm_transition

# CHECKPOINT REPORTING
echo ""
echo "CHECKPOINT: Research phase setup complete"
echo "- State transition: RESEARCH ✓"
echo "- Research directory: $RESEARCH_DIR"
echo "- Revision topic: $REVISION_TOPIC_SLUG"
echo "- Expected report path: $EXPECTED_REPORT_PATH"
echo "- Variables persisted: ✓"
echo "- Ready for: research-specialist invocation (Block 4b)"
echo ""
```

## Block 4b: Research Phase Execution [CRITICAL BARRIER]

**HARD BARRIER - Research-Specialist Invocation**

**CRITICAL BARRIER**: This block MUST invoke research-specialist via Task tool. The Task invocation is MANDATORY and CANNOT be bypassed. The verification block (Block 4c) will FAIL if research report is not created at the pre-calculated path.

**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent. DO NOT perform research work directly. This Task invocation CANNOT be bypassed - the bash verification block enforces mandatory delegation.

Task {
  subagent_type: "general-purpose"
  description: "Research revision insights for ${REVISION_DETAILS} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are conducting research for: revise workflow

    **Input Contract (Hard Barrier Pattern)**:
    - Research Topic: Plan revision insights for: ${REVISION_DETAILS}
    - Research Complexity: ${RESEARCH_COMPLEXITY}
    - Output Directory: ${RESEARCH_DIR}
    - Output Path: ${EXPECTED_REPORT_PATH}
    - Workflow Type: research-and-revise
    - Existing Plan: ${EXISTING_PLAN_PATH}

    **CRITICAL**: You MUST write the research report to the EXACT path specified above:
    ${EXPECTED_REPORT_PATH}

    The orchestrator has pre-calculated this path and will validate it exists after you return.
    Do NOT derive or calculate your own path.

    Execute research according to behavioral guidelines and return completion signal:
    REPORT_CREATED: ${EXPECTED_REPORT_PATH}
  "
}

## Block 4c: Research Phase Verification (Hard Barrier)

**HARD BARRIER**: This bash block verifies that the research-specialist agent completed successfully by checking for research report at the EXACT pre-calculated path. If the report is missing, the block MUST fail with exit code 1 and detailed error logging.

**EXECUTE NOW**: Validate that research-specialist created the report at the expected path.

```bash
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e  # Fail-fast per code-standards.md

# === DETECT PROJECT DIRECTORY (subprocess isolation) ===
if [ -z "$CLAUDE_PROJECT_DIR" ]; then
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
fi

# Re-source libraries for subprocess isolation (Three-Tier Pattern)
# Tier 1: Critical Foundation (state-persistence.sh, workflow-state-machine.sh, error-handling.sh)
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

# Restore state from previous block
STATE_FILE=$(discover_latest_state_file "revise")
if [ -n "$STATE_FILE" ] && [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE"  # WORKFLOW_ID restored
  export WORKFLOW_ID
  load_workflow_state "$WORKFLOW_ID" false

  # Restore error logging context
  if [ -z "${COMMAND_NAME:-}" ]; then
    COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "/revise")
  fi
  if [ -z "${USER_ARGS:-}" ]; then
    USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "")
  fi
  export COMMAND_NAME USER_ARGS WORKFLOW_ID

  # Setup bash error trap
  setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
else
  echo "ERROR: Failed to discover state file from previous block" >&2
  exit 1
fi

echo ""
echo "=== Hard Barrier Verification: Research Report ==="
echo ""

echo "Expected report path: $EXPECTED_REPORT_PATH"

# HARD BARRIER: Report file MUST exist at pre-calculated path
if [ ! -f "$EXPECTED_REPORT_PATH" ]; then
  # Enhanced diagnostics: Search for file in alternate locations
  REPORT_NAME=$(basename "$EXPECTED_REPORT_PATH")
  FOUND_FILES=$(find "$RESEARCH_DIR" -name "*.md" -type f 2>/dev/null | head -5 || true)

  if [ -n "$FOUND_FILES" ]; then
    echo "❌ HARD BARRIER FAILED - Report at wrong location" >&2
    echo "Expected: $EXPECTED_REPORT_PATH" >&2
    echo "Found files in $RESEARCH_DIR:" >&2
    echo "$FOUND_FILES" | while read -r file; do
      echo "  - $file" >&2
    done
    log_command_error "/revise" "$WORKFLOW_ID" "$USER_ARGS" \
      "agent_error" \
      "research-specialist created report at wrong location" \
      "bash_block_4c" \
      "$(jq -n --arg expected "$EXPECTED_REPORT_PATH" --arg found "$FOUND_FILES" \
         '{expected: $expected, found_files: $found}')"
  else
    echo "❌ HARD BARRIER FAILED - Report file not found anywhere" >&2
    echo "Expected: $EXPECTED_REPORT_PATH" >&2
    echo "Search directory: $RESEARCH_DIR" >&2
    log_command_error "/revise" "$WORKFLOW_ID" "$USER_ARGS" \
      "agent_error" \
      "research-specialist failed to create report file" \
      "bash_block_4c" \
      "$(jq -n --arg expected "$EXPECTED_REPORT_PATH" --arg dir "$RESEARCH_DIR" \
         '{expected: $expected, search_dir: $dir}')"
  fi

  echo "" >&2
  echo "DIAGNOSTIC: research-specialist agent should have created report in Block 4b" >&2
  echo "RECOVERY: Re-run /revise command, check research-specialist logs" >&2
  exit 1
fi

# Validate report is not empty or too small
REPORT_SIZE=$(wc -c < "$EXPECTED_REPORT_PATH" 2>/dev/null || echo 0)
if [ "$REPORT_SIZE" -lt 100 ]; then
  log_command_error "/revise" "$WORKFLOW_ID" "$USER_ARGS" \
    "validation_error" \
    "Report file too small ($REPORT_SIZE bytes)" \
    "bash_block_4c" \
    "$(jq -n --argjson size "$REPORT_SIZE" --arg path "$EXPECTED_REPORT_PATH" \
       '{size_bytes: $size, report_path: $path}')"
  echo "ERROR: Report file suspiciously small: $REPORT_SIZE bytes" >&2
  exit 1
fi

echo "[OK] Research report validated at expected path"
echo "  Path: $EXPECTED_REPORT_PATH"
echo "  Size: $REPORT_SIZE bytes"
echo ""

# Count total reports for summary
TOTAL_REPORT_COUNT=$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null | wc -l || echo 1)
NEW_REPORT_COUNT=1  # We just created one

# CHECKPOINT REPORTING
echo "[CHECKPOINT] Hard barrier passed: Research report validated"
echo "- Report path: $EXPECTED_REPORT_PATH"
echo "- Report size: $REPORT_SIZE bytes"
echo "- Total reports: $TOTAL_REPORT_COUNT"
echo "- Proceeding to: Plan revision phase"
echo ""

# Persist variables across bash blocks (subprocess isolation)
append_workflow_state "EXISTING_PLAN_PATH" "${EXISTING_PLAN_PATH:-}"
append_workflow_state "RESEARCH_DIR" "${RESEARCH_DIR:-}"
append_workflow_state "SPECS_DIR" "${SPECS_DIR:-}"
append_workflow_state "TOTAL_REPORT_COUNT" "${TOTAL_REPORT_COUNT:-}"
append_workflow_state "NEW_REPORT_COUNT" "${NEW_REPORT_COUNT:-}"
append_workflow_state "REVISION_DETAILS" "${REVISION_DETAILS:-}"
append_workflow_state "EXPECTED_REPORT_PATH" "${EXPECTED_REPORT_PATH:-}"

# Removed: save_completed_states_to_state does not exist in library
# State machine already persists completed states via sm_transition

if [ -n "${STATE_FILE:-}" ] && [ ! -f "$STATE_FILE" ]; then
  echo "WARNING: State file not found after save: $STATE_FILE" >&2
fi
```

## Block 4d: Extract Project Standards

**EXECUTE NOW**: Extract project standards for plan-architect agent.

```bash
set +H  # CRITICAL: Disable history expansion

# Re-source libraries for subprocess isolation (Three-Tier Pattern)
# Tier 1: Critical Foundation (state-persistence.sh, workflow-state-machine.sh, error-handling.sh)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Restore state from previous block
STATE_FILE=$(discover_latest_state_file "revise")
if [ -n "$STATE_FILE" ] && [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE"  # WORKFLOW_ID restored
  export WORKFLOW_ID
  load_workflow_state "$WORKFLOW_ID" false

  # Restore error logging context
  if [ -z "${COMMAND_NAME:-}" ]; then
    COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "/revise")
  fi
  if [ -z "${USER_ARGS:-}" ]; then
    USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "")
  fi
  export COMMAND_NAME USER_ARGS WORKFLOW_ID

  # Setup bash error trap
  setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
fi

# === EXTRACT PROJECT STANDARDS ===
# Source standards extraction library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/standards-extraction.sh" 2>/dev/null || {
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "Failed to source standards-extraction library" \
    "bash_block_4d" \
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
      "bash_block_4d" \
      "{}"
    echo "WARNING: Standards extraction failed, proceeding without standards" >&2
    FORMATTED_STANDARDS=""
  }
fi

# Persist standards for Block 5b
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

## Block 5a: Plan Revision Setup

**CRITICAL BARRIER**: This bash block creates a hard context barrier enforcing plan-architect delegation. The block MUST be executed BEFORE the plan-architect Task invocation in Block 5b.

**EXECUTE NOW**: Transition to planning state and create backup:

```bash
set +H  # CRITICAL: Disable history expansion
# Load WORKFLOW_ID from file (fail-fast pattern - no fallback)
# Restore state from previous block
STATE_FILE=$(discover_latest_state_file "revise")
if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  echo "ERROR: Failed to discover state file from previous block" >&2
  echo "DIAGNOSTIC: Part 3 (State Machine Initialization) may not have executed" >&2
  exit 1
fi
source "$STATE_FILE"  # WORKFLOW_ID restored
export WORKFLOW_ID

# Load workflow state from Part 3 (subprocess isolation)
load_workflow_state "$WORKFLOW_ID" false

# === RESTORE ERROR LOGGING CONTEXT ===
if [ -z "${COMMAND_NAME:-}" ]; then
  COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "/revise")
fi
if [ -z "${USER_ARGS:-}" ]; then
  USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "")
fi
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# === SETUP BASH ERROR TRAP ===
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

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
    echo "WHERE: Block 5, planning phase"
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
    "bash_block_5" \
    "$(jq -n --arg path "$STATE_FILE" '{expected_path: $path}')"

  {
    echo "[$(date)] ERROR: State file not found"
    echo "WHICH: load_workflow_state"
    echo "WHAT: File does not exist at expected path"
    echo "WHERE: Block 5, planning phase"
    echo "PATH: $STATE_FILE"
  } >> "$DEBUG_LOG"
  echo "ERROR: State file not found (see $DEBUG_LOG)" >&2
  exit 1
fi

# Validate critical variables
if [ -z "${EXISTING_PLAN_PATH:-}" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "Critical variable EXISTING_PLAN_PATH not restored after state load" \
    "bash_block_5" \
    "$(jq -n --arg var "EXISTING_PLAN_PATH" '{missing_variable: $var}')"

  {
    echo "[$(date)] ERROR: Critical variables not restored"
    echo "WHICH: load_workflow_state"
    echo "WHAT: EXISTING_PLAN_PATH missing after load"
    echo "WHERE: Block 5, planning phase"
    echo "EXISTING_PLAN_PATH: ${EXISTING_PLAN_PATH:-MISSING}"
  } >> "$DEBUG_LOG"
  echo "ERROR: Critical variables not restored (see $DEBUG_LOG)" >&2
  exit 1
fi

# Validate STATE_FILE is set before state transition (defensive check)
if [ -z "${STATE_FILE:-}" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "STATE_FILE not set before sm_transition" \
    "bash_block_5a" \
    "$(jq -n --arg workflow "${WORKFLOW_ID:-unknown}" '{workflow_id: $workflow}')"
  echo "ERROR: STATE_FILE not set. Call load_workflow_state first." >&2
  exit 1
fi

# Transition to plan state with return code verification
sm_transition "$STATE_PLAN" 2>&1
SM_TRANSITION_EXIT=$?
if [ $SM_TRANSITION_EXIT -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State transition to PLAN failed" \
    "bash_block_5" \
    "$(jq -n --arg state "PLAN" '{target_state: $state}')"

  echo "ERROR: State transition to PLAN failed" >&2
  echo "DIAGNOSTIC Information:" >&2
  echo "  - Current State: $(sm_current_state 2>/dev/null || echo 'unknown')" >&2
  echo "  - Attempted Transition: → PLAN" >&2
  echo "  - Workflow Type: research-and-revise" >&2
  echo "  - Research complete: check CHECKPOINT above" >&2
  echo "POSSIBLE CAUSES:" >&2
  echo "  - Research phase did not complete properly" >&2
  echo "  - State not persisted after research" >&2
  echo "  - Invalid transition from current state" >&2
  echo "TROUBLESHOOTING:" >&2
  echo "  - Check research checkpoint output" >&2
  echo "  - Verify research phase completed" >&2
  exit 1
fi
echo "=== Phase 2: Plan Revision ==="
echo ""

# Pre-calculate backup path (Hard Barrier Pattern)
BACKUP_DIR="${SPECS_DIR}/backups"
mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PLAN_BASENAME=$(basename "$EXISTING_PLAN_PATH" .md)
BACKUP_PATH="${BACKUP_DIR}/${PLAN_BASENAME}_backup_${TIMESTAMP}.md"

# Validate backup path is absolute
[[ "$BACKUP_PATH" = /* ]]
IS_ABSOLUTE=$?
if [ $IS_ABSOLUTE -ne 0 ]; then
  log_command_error "/revise" "$WORKFLOW_ID" "$USER_ARGS" \
    "validation_error" \
    "BACKUP_PATH is not absolute" \
    "bash_block_5a" \
    "$(jq -n --arg path "$BACKUP_PATH" '{calculated_path: $path}')"
  echo "ERROR: Backup path is not absolute: $BACKUP_PATH" >&2
  exit 1
fi

echo "Pre-calculated backup path: $BACKUP_PATH"

# NOTE: Backup will be created by plan-architect agent in Block 5b
# This allows verification block to confirm agent created the backup
# Do NOT create backup here - agent creates it to enforce delegation

# Collect research report paths
REPORT_PATHS=$(find "$RESEARCH_DIR" -name '*.md' -type f | sort)
REPORT_PATHS_JSON=$(echo "$REPORT_PATHS" | jq -R . | jq -s .)

# Persist variables for Block 5b and 5c (subprocess isolation)
append_workflow_state "EXISTING_PLAN_PATH" "${EXISTING_PLAN_PATH:-}"
append_workflow_state "BACKUP_PATH" "${BACKUP_PATH:-}"
append_workflow_state "BACKUP_DIR" "${BACKUP_DIR:-}"
append_workflow_state "REVISION_DETAILS" "${REVISION_DETAILS:-}"
append_workflow_state "RESEARCH_DIR" "${RESEARCH_DIR:-}"
append_workflow_state "REPORT_PATHS_JSON" "${REPORT_PATHS_JSON:-}"

# Removed: save_completed_states_to_state does not exist in library
# State machine already persists completed states via sm_transition

# CHECKPOINT REPORTING
echo ""
echo "CHECKPOINT: Plan revision setup complete"
echo "- State transition: PLAN ✓"
echo "- Pre-calculated backup path: $BACKUP_PATH"
echo "- Research reports collected: $(echo "$REPORT_PATHS" | wc -l)"
echo "- Variables persisted: ✓"
echo "- Ready for: plan-architect invocation (Block 5b)"
echo ""
```

## Block 5b: Plan Revision Execution [CRITICAL BARRIER]

**HARD BARRIER - Plan-Architect Invocation**

**CRITICAL BARRIER**: This block MUST invoke plan-architect via Task tool. The Task invocation is MANDATORY and CANNOT be bypassed. The verification block (Block 5c) will FAIL if backup is not created at the pre-calculated path AND if the plan is not modified.

**EXECUTE NOW**: USE the Task tool to invoke the plan-architect agent. DO NOT perform plan revisions directly. This Task invocation CANNOT be bypassed - the bash verification block enforces mandatory delegation.

Task {
  subagent_type: "general-purpose"
  description: "Revise implementation plan based on ${REVISION_DETAILS} with mandatory file modification"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are revising an implementation plan for: revise workflow

    **Input Contract (Hard Barrier Pattern)**:
    - Existing Plan Path: ${EXISTING_PLAN_PATH}
    - Backup Path: ${BACKUP_PATH}
    - Revision Details: ${REVISION_DETAILS}
    - Research Reports: ${REPORT_PATHS_JSON}
    - Workflow Type: research-and-revise
    - Operation Mode: plan revision
    - Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH:-none}

    **Project Standards** (from CLAUDE.md):
    ${FORMATTED_STANDARDS}

    **CRITICAL INSTRUCTIONS FOR PLAN REVISION**:
    1. Use STEP 1-REV → STEP 2-REV → STEP 3-REV → STEP 4-REV workflow (revision flow)
    2. Create backup at ${BACKUP_PATH} BEFORE making any changes
       - Use Bash: cp '${EXISTING_PLAN_PATH}' '${BACKUP_PATH}'
       - This is MANDATORY - verification block will fail if backup not created
    3. Use Edit tool (NEVER Write) for all modifications to existing plan file
    4. Preserve all [COMPLETE] phases unchanged (do not modify completed work)
    5. Update plan metadata (Date, Estimated Hours, Phase count) to reflect revisions
    6. **METADATA NORMALIZATION**: If metadata uses non-standard fields (Plan ID, Created, Revised, Workflow Type), convert to standard format (Date, Feature, Status, Standards File)
    7. Maintain /implement compatibility (checkbox format, phase markers, dependency syntax)

    The orchestrator has pre-calculated the backup path and will validate:
    1. Backup exists at ${BACKUP_PATH}
    2. Plan file has been modified (differs from backup)

    Execute plan revision according to behavioral guidelines and return completion signal:
    PLAN_REVISED: ${EXISTING_PLAN_PATH}
    BACKUP_CREATED: ${BACKUP_PATH}
  "
}

## Block 5c: Plan Revision Verification (Hard Barrier)

**HARD BARRIER**: This bash block verifies that the plan-architect agent completed successfully by checking:
1. Backup was created at the pre-calculated path
2. Plan file was modified (differs from backup)

If either check fails, the block MUST fail with exit code 1 and detailed error logging.

**EXECUTE NOW**: Validate that plan-architect created backup and modified plan.

```bash
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e  # Fail-fast per code-standards.md

# === DETECT PROJECT DIRECTORY (subprocess isolation) ===
if [ -z "$CLAUDE_PROJECT_DIR" ]; then
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
fi

# Re-source libraries for subprocess isolation (Three-Tier Pattern)
# Tier 1: Critical Foundation (state-persistence.sh, workflow-state-machine.sh, error-handling.sh)
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

# Restore state from previous block
STATE_FILE=$(discover_latest_state_file "revise")
if [ -n "$STATE_FILE" ] && [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE"  # WORKFLOW_ID restored
  export WORKFLOW_ID
  load_workflow_state "$WORKFLOW_ID" false

  # Restore error logging context
  if [ -z "${COMMAND_NAME:-}" ]; then
    COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "/revise")
  fi
  if [ -z "${USER_ARGS:-}" ]; then
    USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "")
  fi
  export COMMAND_NAME USER_ARGS WORKFLOW_ID

  # Setup bash error trap
  setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
else
  echo "ERROR: Failed to discover state file from previous block" >&2
  exit 1
fi

echo ""
echo "=== Hard Barrier Verification: Plan Revision ==="
echo ""

echo "Expected backup path: $BACKUP_PATH"

# HARD BARRIER 1: Backup file MUST exist at pre-calculated path
if [ ! -f "$BACKUP_PATH" ]; then
  log_command_error "/revise" "$WORKFLOW_ID" "$USER_ARGS" \
    "agent_error" \
    "plan-architect failed to create backup before modification" \
    "bash_block_5c" \
    "$(jq -n --arg expected "$BACKUP_PATH" '{expected_backup: $expected}')"

  echo "❌ HARD BARRIER FAILED - Backup not found: $BACKUP_PATH" >&2
  echo "DIAGNOSTIC: plan-architect must create backup in STEP 1-REV" >&2
  echo "RECOVERY: Re-run /revise command, ensure plan-architect creates backup" >&2
  exit 1
fi

BACKUP_SIZE=$(wc -c < "$BACKUP_PATH" 2>/dev/null || echo 0)
echo "[OK] Backup file exists at expected path"
echo "  Path: $BACKUP_PATH"
echo "  Size: $BACKUP_SIZE bytes"

# HARD BARRIER 2: Plan file MUST still exist
if [ ! -f "$EXISTING_PLAN_PATH" ]; then
  log_command_error "/revise" "$WORKFLOW_ID" "$USER_ARGS" \
    "agent_error" \
    "Plan-architect caused plan file to disappear" \
    "bash_block_5c" \
    "$(jq -n --arg path "$EXISTING_PLAN_PATH" --arg backup "$BACKUP_PATH" '{plan_path: $path, backup_path: $backup}')"

  echo "❌ HARD BARRIER FAILED - Plan file disappeared during revision: $EXISTING_PLAN_PATH" >&2
  echo "DIAGNOSTIC: Restore from backup: $BACKUP_PATH" >&2
  echo "RECOVERY: cp \"$BACKUP_PATH\" \"$EXISTING_PLAN_PATH\"" >&2
  exit 1
fi

# HARD BARRIER 3: Plan MUST be different from backup (changes were made)
if cmp -s "$EXISTING_PLAN_PATH" "$BACKUP_PATH"; then
  log_command_error "/revise" "$WORKFLOW_ID" "$USER_ARGS" \
    "agent_error" \
    "plan-architect created backup but made no modifications to plan" \
    "bash_block_5c" \
    "$(jq -n --arg plan "$EXISTING_PLAN_PATH" --arg backup "$BACKUP_PATH" \
       '{plan_path: $plan, backup_path: $backup, status: "identical"}')"

  echo "❌ HARD BARRIER FAILED - Plan unchanged after revision" >&2
  echo "DIAGNOSTIC: Plan file identical to backup (no modifications made)" >&2
  echo "RECOVERY: Re-run /revise command with more specific revision instructions" >&2
  exit 1
fi

echo "[OK] Plan file modified (differs from backup)"

# Validate plan file size is reasonable
PLAN_SIZE=$(wc -c < "$EXISTING_PLAN_PATH" 2>/dev/null || echo 0)
if [ "$PLAN_SIZE" -lt 500 ]; then
  log_command_error "/revise" "$WORKFLOW_ID" "$USER_ARGS" \
    "validation_error" \
    "Revised plan suspiciously small ($PLAN_SIZE bytes)" \
    "bash_block_5c" \
    "$(jq -n --argjson size "$PLAN_SIZE" --arg backup "$BACKUP_PATH" \
       '{plan_size_bytes: $size, backup_path: $backup}')"
  echo "ERROR: Revised plan too small: $PLAN_SIZE bytes" >&2
  echo "RECOVERY: Restore from backup: cp \"$BACKUP_PATH\" \"$EXISTING_PLAN_PATH\"" >&2
  exit 1
fi

echo "[OK] Plan file size valid: $PLAN_SIZE bytes"

# Verify plan has valid structure (at least one phase heading)
PHASE_COUNT=$(grep -c "^### Phase [0-9]" "$EXISTING_PLAN_PATH" || echo "0")
if [ "$PHASE_COUNT" -lt 1 ]; then
  log_command_error "/revise" "$WORKFLOW_ID" "$USER_ARGS" \
    "validation_error" \
    "Plan-architect produced plan with no phase headings" \
    "bash_block_5c" \
    "$(jq -n --arg path "$EXISTING_PLAN_PATH" --arg backup "$BACKUP_PATH" \
       '{plan_path: $path, backup_path: $backup}')"

  echo "ERROR: Plan file has no phase headings (invalid structure)" >&2
  echo "RECOVERY: Restore from backup: cp \"$BACKUP_PATH\" \"$EXISTING_PLAN_PATH\"" >&2
  exit 1
fi

echo "[OK] Plan structure valid: $PHASE_COUNT phases"
echo ""

# CHECKPOINT REPORTING
echo "[CHECKPOINT] Hard barrier passed: Plan revision validated"
echo "- Backup path: $BACKUP_PATH"
echo "- Plan path: $EXISTING_PLAN_PATH"
echo "- Plan size: $PLAN_SIZE bytes"
echo "- Phase count: $PHASE_COUNT"
echo "- Proceeding to: Completion"
echo ""

# Persist variables for Block 6 (subprocess isolation)
append_workflow_state "BACKUP_PATH" "${BACKUP_PATH:-}"
append_workflow_state "EXISTING_PLAN_PATH" "${EXISTING_PLAN_PATH:-}"
append_workflow_state "PLAN_SIZE" "${PLAN_SIZE:-}"
append_workflow_state "PHASE_COUNT" "${PHASE_COUNT:-}"

# Removed: save_completed_states_to_state does not exist in library
# State machine already persists completed states via sm_transition

if [ -n "${STATE_FILE:-}" ] && [ ! -f "$STATE_FILE" ]; then
  echo "WARNING: State file not found after save: $STATE_FILE" >&2
fi
```

## Block 6: Completion & Cleanup

**EXECUTE NOW**: Complete the workflow and display summary:

```bash
set +H  # CRITICAL: Disable history expansion

# Load WORKFLOW_ID from file (fail-fast pattern - no fallback)
# Restore state from previous block
STATE_FILE=$(discover_latest_state_file "revise")
if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  echo "ERROR: Failed to discover state file from previous block" >&2
  echo "DIAGNOSTIC: Part 3 (State Machine Initialization) may not have executed" >&2
  exit 1
fi
source "$STATE_FILE"  # WORKFLOW_ID restored
export WORKFLOW_ID

# Re-source required libraries for subprocess isolation
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

# Load workflow state from Part 4 (subprocess isolation)
load_workflow_state "$WORKFLOW_ID" false

# === RESTORE ERROR LOGGING CONTEXT ===
if [ -z "${COMMAND_NAME:-}" ]; then
  COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "/revise")
fi
if [ -z "${USER_ARGS:-}" ]; then
  USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "")
fi
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# === SETUP BASH ERROR TRAP ===
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# Validate STATE_FILE is set before state transition (defensive check)
if [ -z "${STATE_FILE:-}" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "STATE_FILE not set before sm_transition" \
    "bash_block_6" \
    "$(jq -n --arg workflow "${WORKFLOW_ID:-unknown}" '{workflow_id: $workflow}')"
  echo "ERROR: STATE_FILE not set. Call load_workflow_state first." >&2
  exit 1
fi

# Research-and-revise workflow: terminate after plan revision with return code verification
sm_transition "$STATE_COMPLETE" 2>&1
SM_TRANSITION_EXIT=$?
if [ $SM_TRANSITION_EXIT -ne 0 ]; then
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
  echo "  - Workflow Type: research-and-revise" >&2
  echo "  - Terminal State: plan" >&2
  echo "POSSIBLE CAUSES:" >&2
  echo "  - Plan revision phase did not complete properly" >&2
  echo "  - State not persisted after plan revision" >&2
  echo "  - Invalid transition from current state" >&2
  echo "TROUBLESHOOTING:" >&2
  echo "  - Check plan revision checkpoint output" >&2
  echo "  - Verify revised plan file exists and differs from backup" >&2
  exit 1
fi

# === CONSOLE SUMMARY ===
# Source summary formatting library
source "${CLAUDE_LIB}/core/summary-formatting.sh" 2>/dev/null || {
  echo "ERROR: Failed to load summary-formatting library" >&2
  exit 1
}

# Build summary text
SUMMARY_TEXT="Revised implementation plan based on $NEW_REPORT_COUNT new research reports (total: $TOTAL_REPORT_COUNT). Updated plan incorporates new insights while preserving existing structure."

# Build artifacts section
ARTIFACTS="  📊 Reports: $RESEARCH_DIR/ ($TOTAL_REPORT_COUNT files, $NEW_REPORT_COUNT new)
  📄 Plan: $EXISTING_PLAN_PATH (revised)
  📁 Backup: $BACKUP_PATH"

# Build next steps
NEXT_STEPS="  • Review revised plan: cat $EXISTING_PLAN_PATH
  • Compare with backup: diff $BACKUP_PATH $EXISTING_PLAN_PATH
  • Implement revised plan: /implement $EXISTING_PLAN_PATH
  • Run /todo to update TODO.md (adds revised plan to tracking)"

# Print standardized summary (no phases for revise command)
print_artifact_summary "Revise" "$SUMMARY_TEXT" "" "$ARTIFACTS" "$NEXT_STEPS"

# Emit completion reminder
echo ""
echo "📋 Next Step: Run /todo to update TODO.md with this revised plan"
echo ""

# === CLEANUP TEMP FILES ===
# State files cleaned up by state-persistence library TTL mechanism
# No manual cleanup required

# Clean up argument file if it exists
REVISE_ARG_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/revise_arg.txt"
if [ -f "$REVISE_ARG_FILE" ]; then
  rm -f "$REVISE_ARG_FILE" 2>/dev/null || true
fi

# Note: State file preserved in ~/.claude/data/state/ for debugging

# === RETURN PLAN_REVISED SIGNAL ===
# This signal allows orchestrator commands to recognize plan revision success
echo ""
echo "PLAN_REVISED: $EXISTING_PLAN_PATH"
echo ""

exit 0
```

---

**Troubleshooting**:

- **Plan path not found**: Ensure path format correct (/path/to/plan.md or ./relative/path.md)
- **Backup failed**: Check write permissions in plans/backups/ directory
- **Plan not modified**: Agent may determine no revision needed based on research
- **Plan corrupted**: Restore from backup in plans/backups/ directory
- **State machine errors**: Ensure library versions compatible (workflow-state-machine.sh >=2.0.0)
- **File not found error**: Ensure --file path is correct and file exists; relative paths are resolved from current directory
- **Empty file error**: The prompt file must contain both the plan path and revision details
- **Dry-run mode**: Use --dry-run to preview what would be done without executing
