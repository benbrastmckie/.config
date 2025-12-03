---
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob
argument-hint: [plan-file] [starting-phase] [--dry-run]
description: Build-from-plan workflow - Implementation, testing, debug, and documentation phases
command-type: primary
dependent-agents:
  - implementer-coordinator
  - debug-analyst
library-requirements:
  - workflow-state-machine.sh: ">=2.0.0"
  - state-persistence.sh: ">=1.5.0"
documentation: See .claude/docs/guides/commands/build-command-guide.md for complete usage guide
---

# /build - Build-from-Plan Workflow Command

YOU ARE EXECUTING a build-from-plan workflow that takes an existing implementation plan and executes it through implementation, testing, debugging (if needed), and documentation phases.

**Workflow Type**: full-implementation
**Terminal State**: complete (after all phases complete)
**Expected Input**: Existing plan file path
**Expected Output**: Implemented features with passing tests and updated documentation

## Block 1a: Implementation Phase Setup

**EXECUTE NOW**: The user invoked `/build [plan-file] [starting-phase] [--dry-run]`. This block captures arguments, initializes workflow state, and prepares for implementer-coordinator invocation.

In the **bash block below**, replace `YOUR_BUILD_ARGS_HERE` with the actual build arguments (or leave empty for auto-resume).

**Examples**:
- If user ran `/build plan.md 3 --dry-run`, change to: `echo "plan.md 3 --dry-run" > "$TEMP_FILE"`
- If user ran `/build`, change to: `echo "" > "$TEMP_FILE"` (auto-resume mode)

```bash
# === PREPROCESSING SAFETY ===
# Disable history expansion to prevent preprocessing-unsafe syntax errors
# (e.g., [[ ! ... ]] → [[ \! ... ]] causing exit code 2)
# This must be set BEFORE any bash conditionals with ! operator
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e  # Fail-fast per code-standards.md

# === PRE-TRAP ERROR BUFFER ===
# Initialize error buffer BEFORE any library sourcing
declare -a _EARLY_ERROR_BUFFER=()

# DEBUG_LOG initialization per spec 778
DEBUG_LOG="${HOME}/.claude/tmp/workflow_debug.log"
mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null

# === CAPTURE BUILD ARGUMENTS ===
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
TEMP_FILE="${HOME}/.claude/tmp/build_arg_$(date +%s%N).txt"
# SUBSTITUTE THE BUILD ARGUMENTS IN THE LINE BELOW
echo "YOUR_BUILD_ARGS_HERE" > "$TEMP_FILE"
echo "$TEMP_FILE" > "${HOME}/.claude/tmp/build_arg_path.txt"

# === READ AND PARSE ARGUMENTS ===
BUILD_ARGS=$(cat "$TEMP_FILE" 2>/dev/null || echo "")

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

# Source error-handling.sh FIRST to enable diagnostic functions
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Replace remaining library sourcing with diagnostic wrapper
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" || exit 1
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/library-version-check.sh" || exit 1

# === INITIALIZE ERROR LOGGING ===
ensure_error_log_exists

# === SETUP EARLY BASH ERROR TRAP ===
# Trap must be set BEFORE variable initialization to catch early failures
setup_bash_error_trap "/build" "build_early_$(date +%s)" "early_init"

# Flush any early errors captured before trap was active
_flush_early_errors

# Tier 2: Workflow Support (graceful degradation)
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/checkpoint-utils.sh" || true

check_library_requirements "$(cat <<'EOF'
workflow-state-machine.sh: ">=2.0.0"
state-persistence.sh: ">=1.5.0"
EOF
)" || exit 1

# === PRE-FLIGHT VALIDATION ===
# Validates prerequisites before workflow execution
validate_build_prerequisites() {
  local validation_errors=0

  # Check library sourcing (critical functions)
  if ! declare -F save_completed_states_to_state >/dev/null 2>&1; then
    echo "ERROR: Required function 'save_completed_states_to_state' not found" >&2
    echo "  This indicates workflow-state-machine.sh was not sourced correctly" >&2
    echo "  Troubleshooting: Check library sourcing in Block 1" >&2
    validation_errors=$((validation_errors + 1))
  fi

  if ! declare -F append_workflow_state >/dev/null 2>&1; then
    echo "ERROR: Required function 'append_workflow_state' not found" >&2
    echo "  This indicates state-persistence.sh was not sourced correctly" >&2
    echo "  Troubleshooting: Check library sourcing in Block 1" >&2
    validation_errors=$((validation_errors + 1))
  fi

  if ! declare -F log_command_error >/dev/null 2>&1; then
    echo "ERROR: Required function 'log_command_error' not found" >&2
    echo "  This indicates error-handling.sh was not sourced correctly" >&2
    echo "  Troubleshooting: Check library sourcing in Block 1" >&2
    validation_errors=$((validation_errors + 1))
  fi

  # Return validation result
  if [ $validation_errors -gt 0 ]; then
    echo "Pre-flight validation failed: $validation_errors error(s) detected" >&2
    return 1
  fi

  return 0
}

# Run pre-flight validation immediately after library sourcing
if ! validate_build_prerequisites; then
  echo "FATAL: Pre-flight validation failed - cannot proceed" >&2
  exit 1
fi

echo "Pre-flight validation passed"
echo ""

# === PARSE ARGUMENTS ===
read -ra ARGS_ARRAY <<< "$BUILD_ARGS"
PLAN_FILE="${ARGS_ARRAY[0]:-}"
STARTING_PHASE="${ARGS_ARRAY[1]:-1}"
DRY_RUN="false"

MAX_ITERATIONS=5  # Default, configurable via --max-iterations
CONTEXT_THRESHOLD=90  # Default 90%, configurable via --context-threshold
RESUME_CHECKPOINT=""  # Path to checkpoint file for resumption

for arg in "${ARGS_ARRAY[@]:2}"; do
  case "$arg" in
    --dry-run) DRY_RUN="true" ;;
    --max-iterations=*) MAX_ITERATIONS="${arg#*=}" ;;
    --context-threshold=*) CONTEXT_THRESHOLD="${arg#*=}" ;;
    --resume=*) RESUME_CHECKPOINT="${arg#*=}" ;;
    --resume)
      # Next argument is the checkpoint path
      # Handled below in checkpoint processing
      ;;
  esac
done

# Handle --resume with separate argument
for i in "${!ARGS_ARRAY[@]}"; do
  if [ "${ARGS_ARRAY[$i]}" = "--resume" ]; then
    RESUME_CHECKPOINT="${ARGS_ARRAY[$((i+1))]:-}"
    break
  fi
done

if [ "$STARTING_PHASE" = "--dry-run" ]; then
  STARTING_PHASE="1"
  DRY_RUN="true"
fi

echo "$STARTING_PHASE" | grep -Eq "^[0-9]+$"
PHASE_VALID=$?
if [ $PHASE_VALID -ne 0 ]; then
  echo "ERROR: Invalid starting phase: $STARTING_PHASE (must be numeric)" >&2
  exit 1
fi

echo "=== Build-from-Plan Workflow ==="
echo ""

# === CHECKPOINT RESUMPTION (--resume flag) ===
if [ -n "$RESUME_CHECKPOINT" ]; then
  if [ ! -f "$RESUME_CHECKPOINT" ]; then
    echo "ERROR: Checkpoint file not found: $RESUME_CHECKPOINT" >&2
    exit 1
  fi

  echo "Resuming from checkpoint: $RESUME_CHECKPOINT"

  # Load and validate checkpoint (v2.1 schema with iteration fields)
  CHECKPOINT_JSON=$(cat "$RESUME_CHECKPOINT")
  CHECKPOINT_VERSION=$(echo "$CHECKPOINT_JSON" | jq -r '.version // "1.0"')

  if [ "$CHECKPOINT_VERSION" != "2.1" ]; then
    echo "WARNING: Checkpoint version $CHECKPOINT_VERSION (expected 2.1)" >&2
  fi

  # Extract fields from checkpoint
  PLAN_FILE=$(echo "$CHECKPOINT_JSON" | jq -r '.plan_path')
  TOPIC_PATH=$(echo "$CHECKPOINT_JSON" | jq -r '.topic_path')
  STARTING_PHASE=$(echo "$CHECKPOINT_JSON" | jq -r '.iteration // 1')
  MAX_ITERATIONS=$(echo "$CHECKPOINT_JSON" | jq -r '.max_iterations // 5')
  CONTINUATION_CONTEXT=$(echo "$CHECKPOINT_JSON" | jq -r '.continuation_context // ""')
  LAST_WORK_REMAINING=$(echo "$CHECKPOINT_JSON" | jq -r '.last_work_remaining // ""')
  CHECKPOINT_ITERATION=$(echo "$CHECKPOINT_JSON" | jq -r '.iteration // 1')

  # Validate plan file exists
  if [ ! -f "$PLAN_FILE" ]; then
    echo "ERROR: Plan file from checkpoint not found: $PLAN_FILE" >&2
    exit 1
  fi

  # Validate continuation context exists if specified
  if [ -n "$CONTINUATION_CONTEXT" ] && [ "$CONTINUATION_CONTEXT" != "null" ] && [ ! -f "$CONTINUATION_CONTEXT" ]; then
    echo "WARNING: Continuation context file not found: $CONTINUATION_CONTEXT" >&2
    echo "Proceeding without continuation context"
    CONTINUATION_CONTEXT=""
  fi

  echo "Checkpoint loaded:"
  echo "  Plan: $PLAN_FILE"
  echo "  Iteration: $CHECKPOINT_ITERATION"
  echo "  Max iterations: $MAX_ITERATIONS"
  if [ -n "$CONTINUATION_CONTEXT" ] && [ "$CONTINUATION_CONTEXT" != "null" ]; then
    echo "  Continuation context: $CONTINUATION_CONTEXT"
  fi
  echo ""
fi

# === AUTO-RESUME LOGIC ===
if [ -z "$PLAN_FILE" ]; then
  echo "PROGRESS: No plan file specified, searching for incomplete plans..."

  CHECKPOINT_DATA=$(load_checkpoint "build" 2>/dev/null || echo "")

  if [ -n "$CHECKPOINT_DATA" ]; then
    CHECKPOINT_FILE="${HOME}/.claude/data/checkpoints/build_checkpoint.json"
    if [ -f "$CHECKPOINT_FILE" ]; then
      CHECKPOINT_AGE_HOURS=$(( ($(date +%s) - $(stat -c %Y "$CHECKPOINT_FILE" 2>/dev/null || stat -f %m "$CHECKPOINT_FILE")) / 3600 ))

      if [ "$CHECKPOINT_AGE_HOURS" -lt 24 ]; then
        PLAN_FILE=$(echo "$CHECKPOINT_DATA" | jq -r '.plan_path')
        STARTING_PHASE=$(echo "$CHECKPOINT_DATA" | jq -r '.current_phase')
        echo "Auto-resuming from checkpoint: Phase $STARTING_PHASE"
      else
        CHECKPOINT_DATA=""
      fi
    fi
  fi

  if [ -z "$PLAN_FILE" ]; then
    PLAN_FILE=$(find "$CLAUDE_PROJECT_DIR/.claude/specs" -path "*/plans/[0-9]*_*.md" -type f -exec ls -t {} + 2>/dev/null | head -1 || true)

    if [ -z "$PLAN_FILE" ]; then
      echo "ERROR: No plan file found in specs/*/plans/" >&2
      exit 1
    fi

    echo "Auto-detected most recent plan: $(basename "$PLAN_FILE")"
  fi
fi

# Validate PLAN_FILE exists and is readable
if [ -z "$PLAN_FILE" ]; then
  echo "ERROR: No plan file specified and auto-detection failed" >&2
  echo "  Usage: /build <plan-file> [starting-phase] [--dry-run]" >&2
  exit 1
fi

if [ ! -f "$PLAN_FILE" ]; then
  echo "ERROR: Plan file not found: $PLAN_FILE" >&2
  echo "  Troubleshooting:" >&2
  echo "    1. Verify the file path is correct" >&2
  echo "    2. Check if file exists: ls -l $PLAN_FILE" >&2
  echo "    3. Ensure file is in specs/*/plans/ directory" >&2
  exit 1
fi

if [ ! -r "$PLAN_FILE" ]; then
  echo "ERROR: Plan file exists but is not readable: $PLAN_FILE" >&2
  echo "  Fix permissions: chmod +r $PLAN_FILE" >&2
  exit 1
fi

echo "Plan: $PLAN_FILE"
echo "Starting Phase: $STARTING_PHASE"
echo ""

# === DRY-RUN MODE ===
if [ "$DRY_RUN" = "true" ]; then
  echo "=== DRY-RUN MODE: Preview Only ==="
  echo "Plan: $(basename "$PLAN_FILE")"
  echo "Starting Phase: $STARTING_PHASE"
  echo "Phases would be executed by implementer-coordinator agent"
  exit 0
fi

# === MARK STARTING PHASE IN PROGRESS ===
# Source checkbox-utils if not already sourced
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh" 2>/dev/null || true

# Check for legacy plan (no status markers) and add [NOT STARTED] markers
if type add_not_started_markers &>/dev/null; then
  # Check if any phase heading lacks a status marker
  if grep -qE "^### Phase [0-9]+:" "$PLAN_FILE" && ! grep -qE "^### Phase [0-9]+:.*\[(NOT STARTED|IN PROGRESS|COMPLETE|BLOCKED|SKIPPED)\]" "$PLAN_FILE"; then
    echo "Legacy plan detected (no status markers), adding [NOT STARTED] markers..."
    add_not_started_markers "$PLAN_FILE" 2>/dev/null || true
  fi
fi

# Mark the starting phase as [IN PROGRESS] for visibility
if type add_in_progress_marker &>/dev/null; then
  if add_in_progress_marker "$PLAN_FILE" "$STARTING_PHASE" 2>/dev/null; then
    echo "Marked Phase $STARTING_PHASE as [IN PROGRESS]"
  else
    echo "NOTE: Could not add progress marker (non-fatal)"
  fi
fi

# Update plan metadata status to IN PROGRESS
if type update_plan_status &>/dev/null; then
  if update_plan_status "$PLAN_FILE" "IN PROGRESS" 2>/dev/null; then
    echo "Plan metadata status updated to [IN PROGRESS]"
  fi
fi
echo ""

# === INITIALIZE STATE MACHINE ===
WORKFLOW_TYPE="full-implementation"
TERMINAL_STATE="complete"
COMMAND_NAME="build"

# Generate workflow ID with timestamp
WORKFLOW_ID="build_$(date +%s)"

# Use persistent state ID file with atomic write for cross-block accessibility
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/build_state_id.txt"
mkdir -p "$(dirname "$STATE_ID_FILE")"

# Atomic write using temp file + mv pattern
TEMP_STATE_ID="${STATE_ID_FILE}.tmp.$$"
echo "$WORKFLOW_ID" > "$TEMP_STATE_ID"
mv "$TEMP_STATE_ID" "$STATE_ID_FILE"

# Verify state ID file was created
if [ ! -f "$STATE_ID_FILE" ]; then
  echo "ERROR: Failed to create state ID file at $STATE_ID_FILE" >&2
  exit 1
fi

export WORKFLOW_ID

# Set command metadata for error logging
COMMAND_NAME="/build"
USER_ARGS="$PLAN_FILE"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# === UPDATE BASH ERROR TRAP WITH ACTUAL VALUES ===
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# Initialize workflow state file (creates .claude/tmp/workflow_${WORKFLOW_ID}.sh)
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

sm_init "$PLAN_FILE" "$COMMAND_NAME" "$WORKFLOW_TYPE" "1" "[]" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State machine initialization failed" \
    "bash_block_1" \
    "$(jq -n --arg type "$WORKFLOW_TYPE" --arg plan "$PLAN_FILE" \
       '{workflow_type: $type, plan_file: $plan}')"

  echo "ERROR: State machine initialization failed" >&2
  exit 1
fi

# === TRANSITION TO IMPLEMENT ===
sm_transition "$STATE_IMPLEMENT" "plan loaded, starting implementation" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State transition to IMPLEMENT failed" \
    "bash_block_1" \
    "$(jq -n --arg state "IMPLEMENT" '{target_state: $state}')"

  echo "ERROR: State transition to IMPLEMENT failed" >&2
  exit 1
fi

TOPIC_PATH=$(dirname "$(dirname "$PLAN_FILE")")

# === PERSIST FOR NEXT BLOCK ===
# Defensive check: Verify append_workflow_state function available before first call
type append_workflow_state &>/dev/null || {
  echo "ERROR: append_workflow_state function not found" >&2
  exit 1
}

append_workflow_state "COMMAND_NAME" "$COMMAND_NAME"
append_workflow_state "USER_ARGS" "$USER_ARGS"
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"
append_workflow_state "CLAUDE_PROJECT_DIR" "$CLAUDE_PROJECT_DIR"
append_workflow_state "PLAN_FILE" "$PLAN_FILE"
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
append_workflow_state "STARTING_PHASE" "$STARTING_PHASE"

# === ITERATION LOOP VARIABLES ===
# These enable persistent iteration for large plans
ITERATION=1
CONTINUATION_CONTEXT=""
LAST_WORK_REMAINING=""
STUCK_COUNT=0

# Persist iteration variables for cross-block accessibility
append_workflow_state "MAX_ITERATIONS" "$MAX_ITERATIONS"
append_workflow_state "CONTEXT_THRESHOLD" "$CONTEXT_THRESHOLD"
append_workflow_state "ITERATION" "$ITERATION"
append_workflow_state "CONTINUATION_CONTEXT" "$CONTINUATION_CONTEXT"
append_workflow_state "LAST_WORK_REMAINING" "$LAST_WORK_REMAINING"
append_workflow_state "STUCK_COUNT" "$STUCK_COUNT"

# Create build workspace directory for iteration summaries
BUILD_WORKSPACE="${CLAUDE_PROJECT_DIR}/.claude/tmp/build_${WORKFLOW_ID}"
mkdir -p "$BUILD_WORKSPACE"
append_workflow_state "BUILD_WORKSPACE" "$BUILD_WORKSPACE"

# Prepare summaries directory for verification
SUMMARIES_DIR="${TOPIC_PATH}/summaries"
mkdir -p "$SUMMARIES_DIR"
append_workflow_state "SUMMARIES_DIR" "$SUMMARIES_DIR"

# Source barrier utilities for verification
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/barrier-utils.sh" 2>/dev/null || {
  echo "WARNING: barrier-utils.sh not found, verification will use basic checks" >&2
}

# CHECKPOINT REPORTING
echo ""
echo "CHECKPOINT: Implementation phase setup complete"
echo "- State transition: IMPLEMENT [OK]"
echo "- Plan file: $PLAN_FILE"
echo "- Topic path: $TOPIC_PATH"
echo "- Iteration: ${ITERATION}/${MAX_ITERATIONS}"
echo "- Variables persisted: [OK]"
echo "- Ready for: implementer-coordinator invocation (Block 1b)"
echo ""
```

## Block 1b: Implementer-Coordinator Invocation [CRITICAL BARRIER]

**HARD BARRIER - Implementer-Coordinator Invocation**

**CRITICAL BARRIER**: This block MUST invoke implementer-coordinator via Task tool. The Task invocation is MANDATORY and CANNOT be bypassed. The verification block (Block 1c) will FAIL if implementation summary is not created by the subagent.

**EXECUTE NOW**: USE the Task tool to invoke the implementer-coordinator agent. DO NOT perform implementation work directly. This Task invocation CANNOT be bypassed - the bash verification block enforces mandatory delegation. After the agent returns, Block 1c will verify artifacts were created.

**Iteration Context**: The coordinator will be passed iteration parameters. After it returns, Block 1c verification will check work_remaining to determine if another iteration is needed.

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with wave-based parallelization (iteration ${ITERATION}/${MAX_ITERATIONS})"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    You are executing the implementation phase for: build workflow

    **Input Contract (Hard Barrier Pattern)**:
    - plan_path: $PLAN_FILE
    - topic_path: $TOPIC_PATH
    - summaries_dir: ${TOPIC_PATH}/summaries/
    - artifact_paths:
      - reports: ${TOPIC_PATH}/reports/
      - plans: ${TOPIC_PATH}/plans/
      - summaries: ${TOPIC_PATH}/summaries/
      - debug: ${TOPIC_PATH}/debug/
      - outputs: ${TOPIC_PATH}/outputs/
      - checkpoints: ${HOME}/.claude/data/checkpoints/
    - continuation_context: ${CONTINUATION_CONTEXT:-null}
    - iteration: ${ITERATION}

    **CRITICAL**: You MUST create implementation summary at ${TOPIC_PATH}/summaries/
    The orchestrator will validate the summary exists after you return.

    Workflow-Specific Context:
    - Starting Phase: ${STARTING_PHASE}
    - Workflow Type: full-implementation
    - Execution Mode: wave-based (parallel where possible)
    - Current Iteration: ${ITERATION}/${MAX_ITERATIONS}
    - Max Iterations: ${MAX_ITERATIONS}
    - Context Threshold: ${CONTEXT_THRESHOLD}%

    Progress Tracking Instructions:
    - Source checkbox-utils.sh: source ${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh
    - Before starting each phase: add_in_progress_marker '$PLAN_FILE' <phase_num>
    - After completing each phase: mark_phase_complete '$PLAN_FILE' <phase_num> && add_complete_marker '$PLAN_FILE' <phase_num>
    - This creates visible progress: [NOT STARTED] -> [IN PROGRESS] -> [COMPLETE]

    Execute all implementation phases according to the plan.

    IMPORTANT: After completing all phases or if context exhaustion detected:
    - Create a summary in summaries/ directory
    - Summary must have Work Status at TOP showing completion percentage
    - Return summary path in completion signal

    Return: IMPLEMENTATION_COMPLETE: {PHASE_COUNT}
    plan_file: $PLAN_FILE
    topic_path: $TOPIC_PATH
    summary_path: /path/to/summary
    work_remaining: 0 or list of incomplete phases
    context_exhausted: true|false
    context_usage_percent: N%
    checkpoint_path: /path/to/checkpoint (if created)
    requires_continuation: true|false
    stuck_detected: true|false
  "
}

## Block 1c: Implementation Phase Verification (Hard Barrier)

**EXECUTE NOW**: Validate that implementer-coordinator created the summary at the expected path.

This is the **hard barrier** - the workflow CANNOT proceed unless the summary file exists. This architectural enforcement prevents the primary agent from bypassing subagent delegation.

```bash
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e  # Fail-fast per code-standards.md

# === PRE-TRAP ERROR BUFFER ===
declare -a _EARLY_ERROR_BUFFER=()

# DEBUG_LOG initialization per spec 778
DEBUG_LOG="${HOME}/.claude/tmp/workflow_debug.log"
mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null

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

# === SOURCE CRITICAL LIBRARIES (Tier 1 - fail-fast required) ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
ensure_error_log_exists

# === RESTORE VARIABLES FROM BLOCK 1a STATE ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/build_state_id.txt"
if [ -f "$STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)
  validate_workflow_id "$WORKFLOW_ID" "/build" || {
    WORKFLOW_ID="build_$(date +%s)_recovered"
  }
else
  echo "ERROR: State ID file not found: $STATE_ID_FILE" >&2
  exit 1
fi
export WORKFLOW_ID

load_workflow_state "$WORKFLOW_ID" false
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to load workflow state" >&2
  exit 1
fi

# Validate critical variables restored
validate_state_restoration "PLAN_FILE" "TOPIC_PATH" "MAX_ITERATIONS" "SUMMARIES_DIR" || {
  echo "ERROR: State restoration failed - critical variables missing" >&2
  exit 1
}

# Restore error logging context
COMMAND_NAME="${COMMAND_NAME:-/build}"
USER_ARGS="${USER_ARGS:-}"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# === MANDATORY VERIFICATION (hard barrier pattern) ===
echo ""
echo "=== Hard Barrier Verification: Implementation Summary ==="
echo ""

# Defensive: Validate SUMMARIES_DIR variable is set
if [ -z "$SUMMARIES_DIR" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "SUMMARIES_DIR variable not set" \
    "bash_block_1c" \
    "$(jq -n '{error: "SUMMARIES_DIR empty after state load"}')"
  echo "ERROR: SUMMARIES_DIR not set - state restoration failed"
  exit 1
fi

# Verify summaries directory exists (with mkdir fallback)
if [ ! -d "$SUMMARIES_DIR" ]; then
  echo "WARNING: Summaries directory not found, creating: $SUMMARIES_DIR"
  mkdir -p "$SUMMARIES_DIR" 2>/dev/null || {
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "file_error" \
      "Cannot create summaries directory: $SUMMARIES_DIR" \
      "bash_block_1c" \
      "$(jq -n --arg dir "$SUMMARIES_DIR" '{summaries_dir: $dir}')"
    echo "ERROR: Cannot create summaries directory"
    exit 1
  }
fi

# HARD BARRIER: Summary file MUST exist
LATEST_SUMMARY=$(find "$SUMMARIES_DIR" -name "*.md" -type f -exec ls -t {} + 2>/dev/null | head -1 || echo "")
if [ -z "$LATEST_SUMMARY" ] || [ ! -f "$LATEST_SUMMARY" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "implementer-coordinator failed to create summary file" \
    "bash_block_1c" \
    "$(jq -n --arg dir "${SUMMARIES_DIR}" '{expected_directory: $dir}')"

  echo "ERROR: HARD BARRIER FAILED - Implementation summary not found" >&2
  echo "" >&2
  echo "This indicates the implementer-coordinator subagent did not create the expected artifact." >&2
  echo "The workflow cannot proceed without the implementation summary." >&2
  echo "" >&2
  echo "Troubleshooting:" >&2
  echo "  1. Check implementer-coordinator agent output for errors" >&2
  echo "  2. Verify Task invocation in Block 1b executed correctly" >&2
  echo "  3. Run /errors --command /build for detailed error logs" >&2
  exit 1
fi

# Validate summary is not empty or too small
SUMMARY_SIZE=$(wc -c < "$LATEST_SUMMARY" 2>/dev/null || echo 0)
if [ "$SUMMARY_SIZE" -lt 100 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Summary file too small (agent may have failed during write)" \
    "bash_block_1c" \
    "$(jq -n --arg path "$LATEST_SUMMARY" --argjson size "$SUMMARY_SIZE" \
       '{summary_path: $path, size_bytes: $size, min_required: 100}')"

  echo "ERROR: Summary file exists but is too small ($SUMMARY_SIZE bytes)" >&2
  echo "  Expected: >100 bytes for valid summary" >&2
  exit 1
fi

# Count total summary files
SUMMARY_COUNT=$(find "$SUMMARIES_DIR" -name "*.md" -type f 2>/dev/null | wc -l || echo "0")

echo "[OK] Agent output validated: Summary file exists ($SUMMARY_SIZE bytes)"
echo "  Path: $LATEST_SUMMARY"
echo ""

# Persist summary path
append_workflow_state "LATEST_SUMMARY" "$LATEST_SUMMARY"
append_workflow_state "SUMMARY_COUNT" "$SUMMARY_COUNT"

# CHECKPOINT REPORTING
echo ""
echo "CHECKPOINT: Implementation phase verification complete"
echo "  [OK] Summary file exists: $LATEST_SUMMARY"
echo "  [OK] Summary size valid: $SUMMARY_SIZE bytes"
echo "  [OK] Hard barrier passed"
echo ""
echo "Ready for: Iteration check and workflow continuation"
echo ""

echo "=== Iteration Check (${ITERATION}/${MAX_ITERATIONS}) ==="
echo ""

# NOTE: Context estimation and checkpoint saving delegated to implementer-coordinator
# The coordinator returns requires_continuation, context_usage_percent, and checkpoint_path
# We trust the subagent's assessment instead of re-parsing

# === CHECK IMPLEMENTER-COORDINATOR OUTPUT ===
# The agent should have returned work_remaining in its output
# Parse from the latest summary or direct signal

# Parse all fields from agent return signal
WORK_REMAINING="${AGENT_WORK_REMAINING:-}"  # Captured from agent output
CONTEXT_EXHAUSTED="${AGENT_CONTEXT_EXHAUSTED:-false}"
SUMMARY_PATH="${AGENT_SUMMARY_PATH:-}"
CONTEXT_USAGE_PERCENT="${AGENT_CONTEXT_USAGE_PERCENT:-0}"
CHECKPOINT_PATH="${AGENT_CHECKPOINT_PATH:-}"
REQUIRES_CONTINUATION="${AGENT_REQUIRES_CONTINUATION:-false}"
STUCK_DETECTED="${AGENT_STUCK_DETECTED:-false}"

# Parse state variables from agent return to avoid state persistence failures
AGENT_PLAN_FILE="${AGENT_PLAN_FILE:-}"
AGENT_TOPIC_PATH="${AGENT_TOPIC_PATH:-}"

# If agent provided plan_file and topic_path, use them instead of state file
if [ -n "$AGENT_PLAN_FILE" ]; then
  PLAN_FILE="$AGENT_PLAN_FILE"
  echo "Using plan_file from agent return: $PLAN_FILE"
  append_workflow_state "PLAN_FILE" "$PLAN_FILE"
fi
if [ -n "$AGENT_TOPIC_PATH" ]; then
  TOPIC_PATH="$AGENT_TOPIC_PATH"
  echo "Using topic_path from agent return: $TOPIC_PATH"
  append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
fi

# Display iteration management status from agent
echo "Context usage: ${CONTEXT_USAGE_PERCENT}%"
echo "Work remaining: ${WORK_REMAINING:-none}"
echo "Requires continuation: $REQUIRES_CONTINUATION"
if [ "$STUCK_DETECTED" = "true" ]; then
  echo "WARNING: Stuck detected - work_remaining unchanged across iterations"
fi
if [ -n "$CHECKPOINT_PATH" ]; then
  echo "Checkpoint created: $CHECKPOINT_PATH"
  append_workflow_state "CHECKPOINT_PATH" "$CHECKPOINT_PATH"
fi

# Fallback: Check summary file for work_remaining if not directly captured
if [ -z "$WORK_REMAINING" ] && [ -n "$SUMMARY_PATH" ] && [ -f "$SUMMARY_PATH" ]; then
  WORK_REMAINING=$(grep -oP 'work_remaining:\s*\K.*' "$SUMMARY_PATH" 2>/dev/null | head -1 || echo "")
fi

# === COMPLETION CHECK ===
# Trust the implementer-coordinator's requires_continuation signal
if [ "$REQUIRES_CONTINUATION" = "true" ]; then
  echo "Coordinator reports continuation required"

  # Prepare for next iteration
  NEXT_ITERATION=$((ITERATION + 1))
  CONTINUATION_CONTEXT="${BUILD_WORKSPACE}/iteration_${ITERATION}_summary.md"

  echo "Preparing iteration $NEXT_ITERATION..."

  # Update state for next iteration
  append_workflow_state "ITERATION" "$NEXT_ITERATION"
  append_workflow_state "WORK_REMAINING" "$WORK_REMAINING"
  append_workflow_state "CONTINUATION_CONTEXT" "$CONTINUATION_CONTEXT"
  append_workflow_state "IMPLEMENTATION_STATUS" "continuing"

  # Save current summary if exists
  if [ -n "$SUMMARY_PATH" ] && [ -f "$SUMMARY_PATH" ]; then
    cp "$SUMMARY_PATH" "$CONTINUATION_CONTEXT" 2>/dev/null || true
  fi

  echo "Next iteration will use continuation context: $CONTINUATION_CONTEXT"
else
  # No continuation required - implementation complete or halted
  if [ -z "$WORK_REMAINING" ] || [ "$WORK_REMAINING" = "0" ] || [ "$WORK_REMAINING" = "[]" ]; then
    echo "Implementation complete - all phases done"
    append_workflow_state "IMPLEMENTATION_STATUS" "complete"
  elif [ "$STUCK_DETECTED" = "true" ]; then
    echo "Implementation halted - stuck detected by coordinator"
    append_workflow_state "IMPLEMENTATION_STATUS" "stuck"
    append_workflow_state "HALT_REASON" "stuck"
  else
    echo "Implementation halted - max iterations or other limit reached"
    append_workflow_state "IMPLEMENTATION_STATUS" "max_iterations"
    append_workflow_state "HALT_REASON" "max_iterations"
  fi

  append_workflow_state "WORK_REMAINING" "$WORK_REMAINING"
fi

echo ""
echo "Iteration check complete"
```

**ITERATION DECISION**:
- If IMPLEMENTATION_STATUS is "continuing", repeat the Task invocation above with updated ITERATION
- If IMPLEMENTATION_STATUS is "complete", "stuck", or "max_iterations", proceed to phase update block

**EXECUTE NOW**: Validate phase markers and recover any missing [COMPLETE] markers after executor updates.

```bash
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e  # Fail-fast per code-standards.md

# DEBUG_LOG initialization per spec 778
DEBUG_LOG="${HOME}/.claude/tmp/workflow_debug.log"
mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null

# === DETECT PROJECT DIRECTORY FIRST ===
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
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Tier 3: Command-Specific (graceful degradation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh" 2>/dev/null || true

ensure_error_log_exists

# === LOAD WORKFLOW STATE WITH RECOVERY ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/build_state_id.txt"

# Attempt to read WORKFLOW_ID from state ID file
if [ -f "$STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)
else
  # Recovery: Find most recent build workflow state file
  LATEST_STATE=$(find "${CLAUDE_PROJECT_DIR}/.claude/tmp" -name "workflow_build_*.sh" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)

  if [ -n "$LATEST_STATE" ] && [ -f "$LATEST_STATE" ]; then
    # Extract WORKFLOW_ID from state file name
    WORKFLOW_ID=$(basename "$LATEST_STATE" .sh | sed 's/^workflow_//')
    echo "RECOVERY: State ID file missing, restored from most recent state file" >&2
    echo "WORKFLOW_ID: $WORKFLOW_ID" >&2
  else
    echo "ERROR: Cannot recover WORKFLOW_ID - no state ID file and no workflow state files found" >&2
    echo "Expected: $STATE_ID_FILE" >&2
    echo "Search path: ${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_build_*.sh" >&2
    exit 1
  fi
fi

if [ -z "$WORKFLOW_ID" ]; then
  echo "ERROR: WORKFLOW_ID is empty after state recovery attempt" >&2
  exit 1
fi

export WORKFLOW_ID

# Load workflow state (fail-fast if state file missing - indicates persistence failure)
load_workflow_state "$WORKFLOW_ID" false
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  echo "ERROR: Failed to load workflow state for WORKFLOW_ID: $WORKFLOW_ID" >&2
  echo "Exit code: $EXIT_CODE" >&2
  exit $EXIT_CODE
fi

# Validate critical variables restored from state
validate_state_restoration "COMMAND_NAME" "USER_ARGS" "STATE_FILE" "PLAN_FILE" "TOPIC_PATH" || {
  echo "ERROR: State restoration failed - critical variables missing" >&2
  log_command_error "state_error" "State restoration validation failed in Block 1d" \
    "$(jq -n --arg cmd "${COMMAND_NAME:-}" --arg plan "${PLAN_FILE:-}" --arg topic "${TOPIC_PATH:-}" \
    '{command: $cmd, plan_file: $plan, topic_path: $topic}')"
  exit 1
}

export COMMAND_NAME USER_ARGS WORKFLOW_ID

# === SETUP BASH ERROR TRAP ===
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

[ "${DEBUG:-}" = "1" ] && echo "DEBUG: Loaded state from: $STATE_FILE" >&2
echo "Phase marker validation: State validated"

echo ""
echo "=== Phase Marker Validation and Recovery ==="
echo ""

# Count total phases and phases with [COMPLETE] marker
TOTAL_PHASES=$(grep -c "^### Phase" "$PLAN_FILE" 2>/dev/null || echo "0")
PHASES_WITH_MARKER=$(grep -c "^### Phase.*\[COMPLETE\]" "$PLAN_FILE" 2>/dev/null || echo "0")

echo "Total phases: $TOTAL_PHASES"
echo "Phases with [COMPLETE] marker: $PHASES_WITH_MARKER"
echo ""

if [ "$TOTAL_PHASES" -eq 0 ]; then
  echo "No phases found in plan (unexpected)"
elif [ "$PHASES_WITH_MARKER" -eq "$TOTAL_PHASES" ]; then
  echo "✓ All phases marked complete by executors"
else
  echo "⚠ Detecting phases missing [COMPLETE] marker..."
  echo ""

  # Recovery: Find phases with all checkboxes complete but missing [COMPLETE] marker
  RECOVERED_COUNT=0
  for phase_num in $(seq 1 "$TOTAL_PHASES"); do
    # Check if phase already has [COMPLETE] marker
    if grep -q "^### Phase ${phase_num}:.*\[COMPLETE\]" "$PLAN_FILE"; then
      continue  # Already marked by executor
    fi

    # Check if all tasks in phase are complete (no [ ] checkboxes)
    if verify_phase_complete "$PLAN_FILE" "$phase_num" 2>/dev/null; then
      echo "Recovering Phase $phase_num (all tasks complete but marker missing)..."

      # Mark all tasks complete (idempotent operation)
      mark_phase_complete "$PLAN_FILE" "$phase_num" 2>/dev/null || {
        echo "  ⚠ Task marking failed for Phase $phase_num" >&2
      }

      # Add [COMPLETE] marker to phase heading
      if add_complete_marker "$PLAN_FILE" "$phase_num" 2>/dev/null; then
        echo "  ✓ [COMPLETE] marker added"
        ((RECOVERED_COUNT++))
      else
        echo "  ⚠ [COMPLETE] marker failed for Phase $phase_num" >&2
      fi
    else
      echo "  Phase $phase_num: Incomplete tasks (expected for partial completion)"
    fi
  done

  if [ "$RECOVERED_COUNT" -gt 0 ]; then
    echo ""
    echo "✓ Recovered $RECOVERED_COUNT phase marker(s)"
  fi
fi

# Defensive check: Verify append_workflow_state function available
type append_workflow_state &>/dev/null
TYPE_CHECK=$?
if [ $TYPE_CHECK -ne 0 ]; then
  echo "ERROR: append_workflow_state function not found" >&2
  echo "DIAGNOSTIC: state-persistence.sh library not sourced in this block" >&2
  exit 1
fi

# Verify checkbox consistency
if verify_checkbox_consistency "$PLAN_FILE" 1 2>/dev/null; then
  echo ""
  echo "✓ Checkbox hierarchy synchronized"
else
  echo ""
  echo "⚠ Checkbox hierarchy may need manual verification"
fi

# Persist validation results (phases_with_marker count for reporting)
append_workflow_state "PHASES_WITH_MARKER" "$PHASES_WITH_MARKER"
append_workflow_state "TOTAL_PHASES" "$TOTAL_PHASES"

# Defensive check: Verify save_completed_states_to_state function available
type save_completed_states_to_state &>/dev/null
TYPE_CHECK=$?
if [ $TYPE_CHECK -ne 0 ]; then
  echo "ERROR: save_completed_states_to_state function not found" >&2
  echo "DIAGNOSTIC: workflow-state-machine.sh library not sourced in this block" >&2
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

echo ""
echo "Phase update complete"

# Update plan status to COMPLETE if all phases done
# checkbox-utils.sh already sourced in this block (line 891)
if type check_all_phases_complete &>/dev/null && type update_plan_status &>/dev/null; then
  if check_all_phases_complete "$PLAN_FILE"; then
    update_plan_status "$PLAN_FILE" "COMPLETE" 2>/dev/null && \
      echo "Plan metadata status updated to [COMPLETE]"
  fi
fi
```

If the above checkbox-utils approach failed for any phase, **EXECUTE NOW**: USE the Task tool to invoke the spec-updater agent as a fallback for more comprehensive plan hierarchy updates.

Task {
  subagent_type: "general-purpose"
  description: "Update plan hierarchy after implementation completion"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/spec-updater.md

    You are acting as a Spec Updater Agent.

    Update plan hierarchy checkboxes after implementation completion.

    Plan: ${PLAN_FILE}
    Total Phases: ${COMPLETED_PHASE_COUNT}
    All phases have been completed successfully.

    Steps:
    1. Source checkbox utilities: source .claude/lib/plan/checkbox-utils.sh
    2. For each phase (1 to ${COMPLETED_PHASE_COUNT}): mark_phase_complete '${PLAN_FILE}' <phase_num>
    3. Verify consistency: verify_checkbox_consistency '${PLAN_FILE}' (each phase)
    4. Add [COMPLETE] marker to phase headings if not present
    5. Report: List all files updated (stage → phase → main plan)

    Expected output:
    - Confirmation of hierarchy update
    - List of updated files at each level
    - Verification that all levels are synchronized
  "
}

## Testing Phase: Invoke Test-Executor Subagent

**EXECUTE NOW**: Before Block 2, invoke test-executor subagent to run tests with framework detection and structured reporting.

First, read state to get paths:

```bash
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

# Validate CLAUDE_PROJECT_DIR before use
if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1
fi

export CLAUDE_PROJECT_DIR

# Source state-persistence library with fail-fast
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Load workflow state with recovery
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/build_state_id.txt"
if [ -f "$STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)
else
  # Recovery: Find most recent build workflow state file
  LATEST_STATE=$(find "${CLAUDE_PROJECT_DIR}/.claude/tmp" -name "workflow_build_*.sh" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
  if [ -n "$LATEST_STATE" ]; then
    WORKFLOW_ID=$(basename "$LATEST_STATE" .sh | sed 's/^workflow_//')
  fi
fi

load_workflow_state "$WORKFLOW_ID" false

# Setup bash error trap
COMMAND_NAME="${COMMAND_NAME:-/build}"
USER_ARGS="${USER_ARGS:-}"
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# Defensive: Validate STATE_FILE exists and is not empty before extraction
if [ -z "$STATE_FILE" ]; then
  echo "ERROR: STATE_FILE variable not set" >&2
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "STATE_FILE not set before extraction" \
    "block_2a" \
    "$(jq -n '{error: "STATE_FILE empty after load"}')"
  exit 1
fi

if [ ! -f "$STATE_FILE" ]; then
  echo "ERROR: STATE_FILE does not exist: $STATE_FILE" >&2
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "STATE_FILE not found: $STATE_FILE" \
    "block_2a" \
    "$(jq -n --arg file "$STATE_FILE" '{state_file: $file}')"
  exit 1
fi

# Extract paths from state with fail-fast validation
if [ -s "$STATE_FILE" ]; then
  PLAN_FILE=$(grep "^PLAN_FILE=" "$STATE_FILE" | cut -d'=' -f2- 2>/dev/null || echo "")
  TOPIC_PATH=$(grep "^TOPIC_PATH=" "$STATE_FILE" | cut -d'=' -f2- 2>/dev/null || echo "")
else
  echo "WARNING: STATE_FILE exists but is empty: $STATE_FILE" >&2
  PLAN_FILE=""
  TOPIC_PATH=""
fi

# Fail-fast validation: PLAN_FILE and TOPIC_PATH are critical for test execution
validate_state_restoration "PLAN_FILE" "TOPIC_PATH" "WORKFLOW_ID" || {
  echo "ERROR: State restoration failed - PLAN_FILE or TOPIC_PATH missing" >&2
  echo "PLAN_FILE: ${PLAN_FILE:-<empty>}" >&2
  echo "TOPIC_PATH: ${TOPIC_PATH:-<empty>}" >&2
  log_command_error "state_error" \
    "State restoration failed in Block 2a - critical variables missing" \
    "$(jq -n --arg plan "${PLAN_FILE:-}" --arg topic "${TOPIC_PATH:-}" \
    '{plan_file: $plan, topic_path: $topic, state_file: "'"$STATE_FILE"'"}')"
  exit 1
}

# Pre-calculate test output path (ensure absolute path)
if [[ ! "$TOPIC_PATH" = /* ]]; then
  echo "ERROR: TOPIC_PATH is not an absolute path: $TOPIC_PATH" >&2
  log_command_error "validation_error" \
    "TOPIC_PATH must be absolute path" \
    "$(jq -n --arg path "$TOPIC_PATH" '{topic_path: $path}')"
  exit 1
fi

TEST_OUTPUT_PATH="${TOPIC_PATH}/outputs/test_results_$(date +%s).md"
mkdir -p "${TOPIC_PATH}/outputs" 2>/dev/null || true

# Validate TEST_OUTPUT_PATH is absolute
if [[ ! "$TEST_OUTPUT_PATH" = /* ]]; then
  echo "ERROR: TEST_OUTPUT_PATH is not an absolute path: $TEST_OUTPUT_PATH" >&2
  log_command_error "validation_error" \
    "TEST_OUTPUT_PATH must be absolute path" \
    "$(jq -n --arg path "$TEST_OUTPUT_PATH" '{test_output_path: $path}')"
  exit 1
fi

# Output paths for Task tool
echo "PLAN_FILE=$PLAN_FILE"
echo "TOPIC_PATH=$TOPIC_PATH"
echo "TEST_OUTPUT_PATH=$TEST_OUTPUT_PATH"
```

**EXECUTE NOW**: USE the Task tool to invoke the test-executor agent for test suite execution.

Task {
  subagent_type: "general-purpose"
  description: "Execute test suite with framework detection and structured reporting"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/test-executor.md

    You are acting as a Test-Executor Agent.

    Execute test suite with automatic framework detection and create structured test result artifact.

    Input:
    - plan_path: ${PLAN_FILE}
    - topic_path: ${TOPIC_PATH}
    - artifact_paths:
        outputs: ${TOPIC_PATH}/outputs/
        debug: ${TOPIC_PATH}/debug/
    - test_config:
        test_command: null  # Auto-detect framework
        retry_on_failure: false
        isolation_mode: true
        max_retries: 2
        timeout_minutes: 30
    - output_path: ${TEST_OUTPUT_PATH}

    Follow the 6-STEP execution process:
    1. Create test output artifact at output_path
    2. Detect test framework using detect-testing.sh utility
    3. Execute tests with isolation and capture output
    4. Parse test results and extract failures
    5. Update artifact with structured results
    6. Return TEST_COMPLETE signal with metadata only

    Expected return format:
    TEST_COMPLETE:
      status: passed|failed|error
      framework: <detected_framework>
      test_command: <executed_command>
      tests_run: N
      tests_passed: N
      tests_failed: N
      tests_skipped: N
      test_output_path: <artifact_path>
      failed_tests: [list if any]
      exit_code: N
      execution_time: <duration>
      coverage: N%|N/A
      retry_count: N
      next_state: DEBUG|DOCUMENT  # DEBUG if failures, DOCUMENT if passed

    Valid next_state values:
    - DEBUG: Tests failed or errored (transition from TEST to DEBUG)
    - DOCUMENT: All tests passed (transition from TEST to DOCUMENT)

    On error, return:
    ERROR_CONTEXT: {error details JSON}
    TASK_ERROR: <error_type> - <error_message>
  "
}

## Block 2: Testing Phase - Load Test Results

**EXECUTE NOW**: Load test results from test-executor artifact and persist state:

```bash
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e  # Fail-fast per code-standards.md

# === PRE-TRAP ERROR BUFFER ===
declare -a _EARLY_ERROR_BUFFER=()

# DEBUG_LOG initialization per spec 778
DEBUG_LOG="${HOME}/.claude/tmp/workflow_debug.log"
mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null

# === DETECT PROJECT DIRECTORY ===
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    [ -d "$current_dir/.claude" ] && { CLAUDE_PROJECT_DIR="$current_dir"; break; }
    current_dir="$(dirname "$current_dir")"
  done
fi

if [ -z "$CLAUDE_PROJECT_DIR" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1
fi
export CLAUDE_PROJECT_DIR

# === DEFENSIVE TRAP SETUP ===
trap 'echo "ERROR: Library sourcing failed at line $LINENO: $BASH_COMMAND" >&2; exit 1' ERR
trap 'if [ $? -ne 0 ]; then echo "ERROR: Block initialization failed" >&2; fi' EXIT

# Source error-handling.sh FIRST
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" || exit 1
ensure_error_log_exists

# === LOAD STATE WITH RECOVERY ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/build_state_id.txt"
if [ -f "$STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)
  validate_workflow_id "$WORKFLOW_ID" "/build" || {
    WORKFLOW_ID="build_$(date +%s)_recovered"
  }
else
  # Recovery: Find most recent build workflow state file
  LATEST_STATE=$(find "${CLAUDE_PROJECT_DIR}/.claude/tmp" -name "workflow_build_*.sh" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
  if [ -n "$LATEST_STATE" ]; then
    WORKFLOW_ID=$(basename "$LATEST_STATE" .sh | sed 's/^workflow_//')
  else
    echo "ERROR: Cannot recover WORKFLOW_ID" >&2
    exit 1
  fi
fi
export WORKFLOW_ID

load_workflow_state "$WORKFLOW_ID" false
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  echo "ERROR: Failed to load workflow state" >&2
  exit $EXIT_CODE
fi

# Validate critical variables restored from state
validate_state_restoration "COMMAND_NAME" "USER_ARGS" "STATE_FILE" "CURRENT_STATE" "PLAN_FILE" || {
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

[ "${DEBUG:-}" = "1" ] && echo "DEBUG: Loaded state: $CURRENT_STATE" >&2
echo "Block 2: State validated ($CURRENT_STATE)"

# === VERIFY IMPLEMENTATION ===
echo "Verifying implementation completion..."

COMMIT_COUNT=$(git log --oneline --since="5 minutes ago" | wc -l)
if [ "$COMMIT_COUNT" -eq 0 ]; then
  echo "NOTE: No recent commits found"
fi

echo "Implementation checkpoint: $COMMIT_COUNT recent commits"
echo ""

# === TRANSITION TO TEST ===
sm_transition "$STATE_TEST" "implementation complete, running tests" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State transition to TEST failed" \
    "bash_block_2" \
    "$(jq -n --arg state "TEST" '{target_state: $state}')"

  echo "ERROR: State transition to TEST failed" >&2
  exit 1
fi

echo "=== Phase 2: Testing - Parse Results ==="
echo ""

# === PARSE TEST-EXECUTOR RESPONSE ===
# The test-executor subagent should have returned metadata in TEST_COMPLETE signal
# Parse all fields from agent return (trust subagent, no re-parsing)
TEST_STATUS="${AGENT_TEST_STATUS:-unknown}"
TEST_EXIT_CODE="${AGENT_TEST_EXIT_CODE:-1}"
TEST_FRAMEWORK="${AGENT_TEST_FRAMEWORK:-unknown}"
TEST_COMMAND="${AGENT_TEST_COMMAND:-}"
TESTS_FAILED="${AGENT_TESTS_FAILED:-0}"
TESTS_PASSED_COUNT="${AGENT_TESTS_PASSED:-0}"
EXECUTION_TIME="${AGENT_EXECUTION_TIME:-N/A}"
TEST_ARTIFACT_PATH="${AGENT_TEST_OUTPUT_PATH:-}"
NEXT_STATE="${AGENT_NEXT_STATE:-DEBUG}"  # Default to DEBUG for safety
RETRY_COUNT="${AGENT_RETRY_COUNT:-0}"

# Validate next_state value (must be DEBUG or DOCUMENT)
if [ "$NEXT_STATE" != "DEBUG" ] && [ "$NEXT_STATE" != "DOCUMENT" ]; then
  echo "ERROR: Invalid next_state from test-executor: $NEXT_STATE" >&2
  log_command_error "validation_error" \
    "test-executor returned invalid next_state" \
    "$(jq -n --arg state "$NEXT_STATE" '{next_state: $state, expected: ["DEBUG", "DOCUMENT"]}')"
  exit 1
fi

# Verify test artifact exists
if [ -z "$TEST_ARTIFACT_PATH" ] || [ ! -f "$TEST_ARTIFACT_PATH" ]; then
  echo "ERROR: Test artifact not found: ${TEST_ARTIFACT_PATH:-<empty>}" >&2
  log_command_error "verification_error" \
    "test-executor did not create expected artifact" \
    "$(jq -n --arg path "${TEST_ARTIFACT_PATH:-}" '{test_output_path: $path}')"
  exit 1
fi

# Display test summary from agent return
echo "Loading test results from: $TEST_ARTIFACT_PATH"
echo ""
echo "Test Framework: $TEST_FRAMEWORK"
echo "Test Command: $TEST_COMMAND"
echo "Status: $TEST_STATUS"
echo "Exit Code: $TEST_EXIT_CODE"
echo "Tests Passed: $TESTS_PASSED_COUNT"
echo "Tests Failed: $TESTS_FAILED"
echo "Execution Time: $EXECUTION_TIME"
echo "Retry Count: $RETRY_COUNT"
echo "Recommended Next State: $NEXT_STATE"
echo ""

# Determine TESTS_PASSED for backward compatibility
if [ "$TEST_STATUS" = "passed" ]; then
  TESTS_PASSED=true
else
  TESTS_PASSED=false
fi

# === PERSIST FOR BLOCK 3 ===
# Defensive check: Verify append_workflow_state function available
type append_workflow_state &>/dev/null
TYPE_CHECK=$?
if [ $TYPE_CHECK -ne 0 ]; then
  echo "ERROR: append_workflow_state function not found" >&2
  echo "DIAGNOSTIC: state-persistence.sh library not sourced in this block" >&2
  exit 1
fi

append_workflow_state "TESTS_PASSED" "$TESTS_PASSED"
append_workflow_state "TEST_COMMAND" "$TEST_COMMAND"
append_workflow_state "TEST_EXIT_CODE" "${TEST_EXIT_CODE:-0}"
append_workflow_state "TEST_ARTIFACT_PATH" "${TEST_ARTIFACT_PATH:-}"
append_workflow_state "COMMIT_COUNT" "$COMMIT_COUNT"

# Defensive check: Verify save_completed_states_to_state function available
type save_completed_states_to_state &>/dev/null
TYPE_CHECK=$?
if [ $TYPE_CHECK -ne 0 ]; then
  echo "ERROR: save_completed_states_to_state function not found" >&2
  echo "DIAGNOSTIC: workflow-state-machine.sh library not sourced in this block" >&2
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

echo ""
echo "Test result: $([ "$TESTS_PASSED" = "true" ] && echo "PASSED" || echo "FAILED")"
echo "Proceeding to: $NEXT_STATE (recommended by test-executor)"

# === STATE-DRIVEN TRANSITION (Phase 2 Simplification) ===
# Trust test-executor's next_state recommendation instead of inline conditionals
# This prevents invalid transitions (e.g., TEST → DOCUMENT when tests failed)

# Map next_state string to state machine constant
if [ "$NEXT_STATE" = "DEBUG" ]; then
  TARGET_STATE="$STATE_DEBUG"
  PHASE_NAME="Debug (Tests Failed)"
elif [ "$NEXT_STATE" = "DOCUMENT" ]; then
  TARGET_STATE="$STATE_DOCUMENT"
  PHASE_NAME="Documentation"
else
  echo "ERROR: Unknown next_state: $NEXT_STATE" >&2
  exit 1
fi

# Single state transition using recommended next_state
sm_transition "$TARGET_STATE" "test-executor recommendation" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State transition to $NEXT_STATE failed" \
    "bash_block_2c" \
    "$(jq -n --arg state "$NEXT_STATE" --arg reason "test-executor recommendation" '{target_state: $state, transition_reason: $reason}')"

  echo "ERROR: State transition to $NEXT_STATE failed" >&2
  exit 1
fi

echo "=== Phase 3: $PHASE_NAME ==="
echo ""

# Phase-specific setup based on target state
if [ "$NEXT_STATE" = "DEBUG" ]; then
  DEBUG_DIR="${TOPIC_PATH}/debug"
  echo "Debug directory: $DEBUG_DIR"
  echo "Test command: $TEST_COMMAND"
  echo "Exit code: $TEST_EXIT_CODE"
  echo "Test artifact: $TEST_ARTIFACT_PATH"
  echo ""
  echo "NOTE: After debug, re-run /build to retry tests"

  append_workflow_state "DEBUG_DIR" "$DEBUG_DIR"
elif [ "$NEXT_STATE" = "DOCUMENT" ]; then
  if git diff --name-only HEAD~${COMMIT_COUNT}..HEAD 2>/dev/null | grep -qE '(\.py|\.js|\.ts|\.go|\.rs)$'; then
    echo "NOTE: Code files modified, documentation update recommended"
  fi

  echo "Documentation phase complete"
fi

# Defensive check: Verify save_completed_states_to_state function available
type save_completed_states_to_state &>/dev/null
TYPE_CHECK=$?
if [ $TYPE_CHECK -ne 0 ]; then
  echo "ERROR: save_completed_states_to_state function not found" >&2
  echo "DIAGNOSTIC: workflow-state-machine.sh library not sourced in this block" >&2
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

echo ""
echo "Conditional branching complete"
```

If tests failed, **EXECUTE NOW**: USE the Task tool to invoke the debug-analyst agent.

Task {
  subagent_type: "general-purpose"
  description: "Debug failed tests in build workflow"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md

    You are conducting debugging analysis for: build workflow

    Input:
    - Issue Description: Tests failed with exit code ${TEST_EXIT_CODE}
    - Failed Phase: testing
    - Test Command: ${TEST_COMMAND}
    - Test Exit Code: ${TEST_EXIT_CODE}
    - Debug Directory: ${DEBUG_DIR}
    - Workflow Type: full-implementation-debug

    Execute debugging analysis according to behavioral guidelines.

    Return: DEBUG_COMPLETE: {report_path}
  "
}

## Block 4: Completion

**EXECUTE NOW**: Complete workflow and cleanup:

```bash
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e  # Fail-fast per code-standards.md

# DEBUG_LOG initialization per spec 778
DEBUG_LOG="${HOME}/.claude/tmp/workflow_debug.log"
mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null

# === DETECT PROJECT DIRECTORY ===
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    [ -d "$current_dir/.claude" ] && { CLAUDE_PROJECT_DIR="$current_dir"; break; }
    current_dir="$(dirname "$current_dir")"
  done
fi

if [ -z "$CLAUDE_PROJECT_DIR" ]; then
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
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Tier 2: Workflow Support (graceful degradation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/checkpoint-utils.sh" 2>/dev/null || true
ensure_error_log_exists

# Tier 3: Command-Specific (graceful degradation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh" 2>/dev/null || true

# === LOAD STATE WITH RECOVERY ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/build_state_id.txt"
if [ -f "$STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)
else
  # Recovery: Find most recent build workflow state file
  LATEST_STATE=$(find "${CLAUDE_PROJECT_DIR}/.claude/tmp" -name "workflow_build_*.sh" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
  if [ -n "$LATEST_STATE" ]; then
    WORKFLOW_ID=$(basename "$LATEST_STATE" .sh | sed 's/^workflow_//')
  else
    echo "ERROR: Cannot recover WORKFLOW_ID" >&2
    exit 1
  fi
fi
export WORKFLOW_ID

load_workflow_state "$WORKFLOW_ID" false
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  echo "ERROR: Failed to load workflow state" >&2
  exit $EXIT_CODE
fi

# === RESTORE ERROR LOGGING CONTEXT ===
if [ -z "${COMMAND_NAME:-}" ]; then
  if [ -f "$STATE_FILE" ] && [ -s "$STATE_FILE" ]; then
    COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" | cut -d'=' -f2- || echo "/build")
  else
    COMMAND_NAME="/build"
  fi
fi
if [ -z "${USER_ARGS:-}" ]; then
  if [ -f "$STATE_FILE" ] && [ -s "$STATE_FILE" ]; then
    USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" | cut -d'=' -f2- || echo "")
  else
    USER_ARGS=""
  fi
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
    "bash_block_4" \
    "$(jq -n --arg workflow "$WORKFLOW_ID" '{workflow_id: $workflow}')"

  {
    echo "[$(date)] ERROR: State file path not set"
    echo "WHICH: load_workflow_state"
    echo "WHAT: STATE_FILE variable empty after load"
    echo "WHERE: Block 4, workflow completion"
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
    echo "WHERE: Block 4, workflow completion"
    echo "PATH: $STATE_FILE"
  } >> "$DEBUG_LOG"
  echo "ERROR: State file not found (see $DEBUG_LOG)" >&2
  exit 1
fi

if [ -z "${CURRENT_STATE:-}" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State restoration failed - CURRENT_STATE empty" \
    "bash_block_4" \
    "$(jq -n '{current_state: "empty"}')"

  {
    echo "[$(date)] ERROR: State restoration failed"
    echo "WHICH: load_workflow_state"
    echo "WHAT: CURRENT_STATE not properly restored (got: empty)"
    echo "WHERE: Block 4, workflow completion"
    echo "PATH: $STATE_FILE"
  } >> "$DEBUG_LOG"
  echo "ERROR: State restoration failed (see $DEBUG_LOG)" >&2
  exit 1
fi

[ "${DEBUG:-}" = "1" ] && echo "DEBUG: Loaded state: $CURRENT_STATE" >&2
echo "Block 4: State validated ($CURRENT_STATE)"

# === COMPLETE WORKFLOW ===
# NOTE: State machine validates predecessor states automatically
# Valid transitions to complete: debug → complete, document → complete
# Invalid transitions will be rejected by sm_transition with descriptive error
sm_transition "$STATE_COMPLETE" "all phases successful" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State transition to COMPLETE failed - invalid predecessor state $CURRENT_STATE" \
    "bash_block_4" \
    "$(jq -n --arg state "COMPLETE" --arg current "$CURRENT_STATE" '{target_state: $state, current_state: $current}')"

  echo "ERROR: State transition to COMPLETE failed" >&2
  echo "DIAGNOSTIC: State machine rejected transition from $CURRENT_STATE to COMPLETE" >&2
  echo "DIAGNOSTIC: Check that Block 3 (debug/document phase) completed successfully" >&2
  exit 1
fi

# === PERSIST STATE TRANSITIONS ===
# CRITICAL: Save state before any cleanup operations (matches plan.md pattern)
# Defensive check: Verify save_completed_states_to_state function available
type save_completed_states_to_state &>/dev/null
TYPE_CHECK=$?
if [ $TYPE_CHECK -ne 0 ]; then
  echo "ERROR: save_completed_states_to_state function not found" >&2
  echo "DIAGNOSTIC: workflow-state-machine.sh library not sourced in this block" >&2
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
    "bash_block_4" \
    "$(jq -n --arg file "${STATE_FILE:-unknown}" '{state_file: $file}')"
  echo "ERROR: State persistence failed" >&2
  exit 1
fi

# === VALIDATE SUMMARY PLAN LINK ===
# Check if summary was created and includes plan link
SUMMARIES_DIR="${TOPIC_PATH}/summaries"
if [ -d "$SUMMARIES_DIR" ]; then
  # Find most recent summary file (by modification time)
  LATEST_SUMMARY=$(ls -t "$SUMMARIES_DIR"/*.md 2>/dev/null | head -n 1)
  if [ -n "$LATEST_SUMMARY" ] && [ -f "$LATEST_SUMMARY" ]; then
    grep -q '^\*\*Plan\*\*:' "$LATEST_SUMMARY" 2>/dev/null
    GREP1_EXIT=$?
    grep -q '^- \*\*Plan\*\*:' "$LATEST_SUMMARY" 2>/dev/null
    GREP2_EXIT=$?
    if [ $GREP1_EXIT -ne 0 ] && [ $GREP2_EXIT -ne 0 ]; then
      echo "⚠ WARNING: Summary missing plan link" >&2
      echo "  Summary: $LATEST_SUMMARY" >&2
      echo "  Add plan link to Metadata section for traceability" >&2
    fi
  fi
fi

# === CONSOLE SUMMARY ===
# Source summary formatting library
source "${CLAUDE_LIB}/core/summary-formatting.sh" 2>/dev/null || {
  echo "ERROR: Failed to load summary-formatting library" >&2
  exit 1
}

# Build summary text
TESTS_STATUS=$([ "$TESTS_PASSED" = "true" ] && echo "all tests passing" || echo "tests debugged")
SUMMARY_TEXT="Completed implementation of ${COMPLETED_PHASE_COUNT:-0} phases with $TESTS_STATUS. Implementation summary includes phase breakdown, test results, and git commit history."

# Build phases section
PHASES=""
if [ -n "${COMPLETED_PHASES:-}" ]; then
  IFS=',' read -ra PHASE_ARRAY <<< "${COMPLETED_PHASES%,}"
  for phase in "${PHASE_ARRAY[@]}"; do
    if [ -n "$phase" ]; then
      PHASES="${PHASES}  • Phase $phase: Complete
"
    fi
  done
fi

# Build artifacts section
ARTIFACTS="  📄 Plan: $PLAN_FILE"
if [ -d "$SUMMARIES_DIR" ]; then
  LATEST_SUMMARY=$(ls -t "$SUMMARIES_DIR"/*.md 2>/dev/null | head -n 1)
  if [ -n "$LATEST_SUMMARY" ]; then
    ARTIFACTS="${ARTIFACTS}
  ✅ Summary: $LATEST_SUMMARY"
  fi
fi

# Build next steps
if [ "$TESTS_PASSED" = "true" ]; then
  NEXT_STEPS="  • Review summary: cat $LATEST_SUMMARY
  • Check git commits: git log --oneline -5
  • Review plan updates: cat $PLAN_FILE
  • Run /todo to update TODO.md (adds completed plan to tracking)"
else
  NEXT_STEPS="  • Review debug output: cat $LATEST_SUMMARY
  • Fix remaining issues and re-run: /build $PLAN_FILE
  • Check test failures: see summary for details
  • Run /todo to update TODO.md when complete"
fi

# Print standardized summary
print_artifact_summary "Build" "$SUMMARY_TEXT" "$PHASES" "$ARTIFACTS" "$NEXT_STEPS"

# Emit completion reminder
echo ""
echo "📋 Next Step: Run /todo to update TODO.md with this build"
echo ""

# === RETURN IMPLEMENTATION_COMPLETE SIGNAL ===
# Signal enables buffer-opener hook to open summary
if [ -n "$LATEST_SUMMARY" ] && [ -f "$LATEST_SUMMARY" ]; then
  echo ""
  echo "IMPLEMENTATION_COMPLETE"
  echo "  summary_path: $LATEST_SUMMARY"
  echo ""
fi

# Cleanup checkpoints if tests passed
if [ "$TESTS_PASSED" = "true" ]; then
  delete_checkpoint "build" 2>/dev/null || true
fi

# Cleanup
rm -f "${HOME}/.claude/tmp/build_state_${WORKFLOW_ID}.txt" 2>/dev/null
rm -f "${CLAUDE_PROJECT_DIR}/.claude/tmp/build_state_id.txt" 2>/dev/null
# Also clean up workflow state file if it exists
if [ -n "${STATE_FILE:-}" ] && [ -f "$STATE_FILE" ]; then
  rm -f "$STATE_FILE" 2>/dev/null
fi

exit 0
```

---

**Troubleshooting**:

- **No plan found**: Create a plan first using `/plan`
- **Tests failing**: Use debug output above, or invoke `/debug` for dedicated debugging
- **Implementation incomplete**: Check implementer-coordinator agent logs
- **Checkpoint issues**: Delete stale checkpoint: `rm ~/.claude/data/checkpoints/build_checkpoint.json`
- **State machine errors**: Ensure library versions compatible (workflow-state-machine.sh >=2.0.0)

**Usage Examples**:

```bash
# Auto-resume from most recent plan
/build

# Build specific plan
/build .claude/specs/123_auth/plans/001_implementation.md

# Resume from specific phase (e.g., phase 3)
/build .claude/specs/123_auth/plans/001_implementation.md 3

# Dry-run preview
/build --dry-run
```
