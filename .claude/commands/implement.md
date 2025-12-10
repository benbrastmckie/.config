---
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob
argument-hint: [plan-file] [starting-phase] [--dry-run] [--max-iterations=N]
description: Implementation-only workflow - Execute plan phases without testing
command-type: primary
dependent-agents:
  - implementer-coordinator
library-requirements:
  - workflow-state-machine.sh: ">=2.0.0"
  - state-persistence.sh: ">=1.5.0"
documentation: See .claude/docs/guides/commands/implement-command-guide.md for complete usage guide
---

# /implement - Implementation-Only Workflow Command

YOU ARE EXECUTING an implementation-only workflow that takes an existing implementation plan and executes it through implementation phases only (no testing/debugging phases).

**Workflow Type**: implement-only
**Terminal State**: implement (with option to continue to complete)
**Expected Input**: Existing plan file path
**Expected Output**: Implemented features with tests written (but not executed)

## Block 1a: Implementation Phase Setup

**EXECUTE NOW**: The user invoked `/implement [plan-file] [starting-phase] [--dry-run] [--max-iterations=N]`. This block captures arguments, initializes workflow state, and prepares for implementer-coordinator invocation.

In the **bash block below**, replace `YOUR_IMPLEMENT_ARGS_HERE` with the actual implement arguments (or leave empty for auto-resume).

**Examples**:
- If user ran `/implement plan.md 3 --dry-run`, change to: `echo "plan.md 3 --dry-run" > "$TEMP_FILE"`
- If user ran `/implement`, change to: `echo "" > "$TEMP_FILE"` (auto-resume mode)

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

# === CAPTURE IMPLEMENT ARGUMENTS ===
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
TEMP_FILE="${HOME}/.claude/tmp/implement_arg_$(date +%s%N).txt"
# SUBSTITUTE THE IMPLEMENT ARGUMENTS IN THE LINE BELOW
echo "YOUR_IMPLEMENT_ARGS_HERE" > "$TEMP_FILE"
echo "$TEMP_FILE" > "${HOME}/.claude/tmp/implement_arg_path.txt"

# === READ AND PARSE ARGUMENTS ===
IMPLEMENT_ARGS=$(cat "$TEMP_FILE" 2>/dev/null || echo "")

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
setup_bash_error_trap "/implement" "implement_early_$(date +%s)" "early_init"

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
validate_implement_prerequisites() {
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
if ! validate_implement_prerequisites; then
  echo "FATAL: Pre-flight validation failed - cannot proceed" >&2
  exit 1
fi

echo "Pre-flight validation passed"
echo ""

# === PARSE ARGUMENTS ===
read -ra ARGS_ARRAY <<< "$IMPLEMENT_ARGS"
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
for i in $(seq 0 $((${#ARGS_ARRAY[@]} - 1))); do
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

echo "=== Implementation-Only Workflow ==="
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

  CHECKPOINT_DATA=$(load_checkpoint "implement" 2>/dev/null || echo "")

  if [ -n "$CHECKPOINT_DATA" ]; then
    CHECKPOINT_FILE="${HOME}/.claude/data/checkpoints/implement_checkpoint.json"
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
  echo "  Usage: /implement <plan-file> [starting-phase] [--dry-run]" >&2
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

# === DETECT LOWEST INCOMPLETE PHASE ===
# If no starting phase argument provided, find the lowest incomplete phase
if [ "${ARGS_ARRAY[1]:-}" = "" ]; then
  # Extract all phase numbers from plan file
  PHASE_NUMBERS=$(grep -oE "^### Phase ([0-9]+):" "$PLAN_FILE" | grep -oE "[0-9]+" | sort -n)

  # Find first phase without [COMPLETE] marker
  LOWEST_INCOMPLETE_PHASE=""
  for phase_num in $PHASE_NUMBERS; do
    if ! grep -q "^### Phase ${phase_num}:.*\[COMPLETE\]" "$PLAN_FILE"; then
      LOWEST_INCOMPLETE_PHASE="$phase_num"
      break
    fi
  done

  # Use lowest incomplete phase, or default to 1 if all complete
  if [ -n "$LOWEST_INCOMPLETE_PHASE" ]; then
    STARTING_PHASE="$LOWEST_INCOMPLETE_PHASE"
    echo "Auto-detected starting phase: $STARTING_PHASE (lowest incomplete)"
  else
    # All phases complete - default to 1 (likely resumption scenario)
    STARTING_PHASE="1"
  fi
else
  # Explicit phase argument provided
  STARTING_PHASE="${ARGS_ARRAY[1]}"
fi

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
WORKFLOW_TYPE="implement-only"
TERMINAL_STATE="$STATE_IMPLEMENT"
COMMAND_NAME="implement"

# Generate workflow ID with nanosecond-precision timestamp for concurrent execution safety
WORKFLOW_ID="implement_$(date +%s%N)"
export WORKFLOW_ID

# Set command metadata for error logging
COMMAND_NAME="/implement"
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

append_workflow_state "COMMAND_NAME" "${COMMAND_NAME:-}"
append_workflow_state "USER_ARGS" "${USER_ARGS:-}"
append_workflow_state "WORKFLOW_ID" "${WORKFLOW_ID:-}"
append_workflow_state "CLAUDE_PROJECT_DIR" "${CLAUDE_PROJECT_DIR:-}"
append_workflow_state "PLAN_FILE" "${PLAN_FILE:-}"
append_workflow_state "TOPIC_PATH" "${TOPIC_PATH:-}"
append_workflow_state "STARTING_PHASE" "${STARTING_PHASE:-}"

# === ITERATION LOOP VARIABLES ===
# These enable persistent iteration for large plans
ITERATION=1
CONTINUATION_CONTEXT=""
LAST_WORK_REMAINING=""
STUCK_COUNT=0

# Persist iteration variables for cross-block accessibility
append_workflow_state "MAX_ITERATIONS" "${MAX_ITERATIONS:-}"
append_workflow_state "CONTEXT_THRESHOLD" "${CONTEXT_THRESHOLD:-}"
append_workflow_state "ITERATION" "${ITERATION:-}"
append_workflow_state "CONTINUATION_CONTEXT" "${CONTINUATION_CONTEXT:-}"
append_workflow_state "LAST_WORK_REMAINING" "${LAST_WORK_REMAINING:-}"
append_workflow_state "STUCK_COUNT" "${STUCK_COUNT:-}"

# Create implement workspace directory for iteration summaries
IMPLEMENT_WORKSPACE="${CLAUDE_PROJECT_DIR}/.claude/tmp/implement_${WORKFLOW_ID}"
mkdir -p "$IMPLEMENT_WORKSPACE"
append_workflow_state "IMPLEMENT_WORKSPACE" "${IMPLEMENT_WORKSPACE:-}"

# Prepare summaries directory for verification
SUMMARIES_DIR="${TOPIC_PATH}/summaries"
mkdir -p "$SUMMARIES_DIR"
append_workflow_state "SUMMARIES_DIR" "${SUMMARIES_DIR:-}"

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

    You are executing the implementation phase for: implement workflow

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
    - Workflow Type: implement-only
    - Execution Mode: wave-based (parallel where possible)
    - Current Iteration: ${ITERATION}/${MAX_ITERATIONS}
    - Max Iterations: ${MAX_ITERATIONS}
    - Context Threshold: ${CONTEXT_THRESHOLD}%

    Progress Tracking Instructions:
    - Source checkbox utilities: source ${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh
    - Before starting each phase: add_in_progress_marker '$PLAN_FILE' <phase_num>
    - After completing each phase: mark_phase_complete '$PLAN_FILE' <phase_num> && add_complete_marker '$PLAN_FILE' <phase_num>
    - This creates visible progress: [NOT STARTED] -> [IN PROGRESS] -> [COMPLETE]

    Execute all implementation phases according to the plan.

    IMPORTANT: After completing all phases or if context exhaustion detected:
    - Create a summary in summaries/ directory
    - Summary must have Work Status at TOP showing completion percentage
    - Summary MUST include Testing Strategy section with:
      - Test Files Created (list of test files written during Testing phases)
      - Test Execution Requirements (how to run tests, framework used)
      - Coverage Target (expected coverage percentage)
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
STATE_FILE=$(discover_latest_state_file "implement")
if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  echo "ERROR: Failed to discover state file from previous block" >&2
  exit 1
fi
source "$STATE_FILE"  # WORKFLOW_ID restored from state file
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
COMMAND_NAME="${COMMAND_NAME:-/implement}"
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
  echo "❌ HARD BARRIER FAILED - Implementation summary not found" >&2
  echo "" >&2
  echo "Expected: Summary file in $SUMMARIES_DIR" >&2
  echo "" >&2

  # Enhanced diagnostics: Search for file in parent and topic directories
  local summary_pattern="*implement*summary*.md"
  local topic_dir="$TOPIC_PATH"
  local found_files=$(find "$topic_dir" -name "$summary_pattern" -type f 2>/dev/null || true)

  if [[ -n "$found_files" ]]; then
    echo "📍 Found summary file(s) at alternate location(s):" >&2
    echo "$found_files" | while read -r file; do
      echo "  - $file" >&2
    done
    echo "" >&2
    echo "⚠️  This indicates implementer-coordinator created the file but not in the expected directory." >&2

    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "agent_error" \
      "implementer-coordinator created file at wrong location" \
      "bash_block_1c" \
      "$(jq -n --arg expected "${SUMMARIES_DIR}" --arg found "$found_files" \
         '{expected_directory: $expected, found_locations: $found}')"
  else
    echo "❌ Summary file not found anywhere in topic directory: $topic_dir" >&2
    echo "" >&2
    echo "⚠️  This indicates implementer-coordinator failed to create the summary file." >&2

    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "agent_error" \
      "implementer-coordinator failed to create summary file" \
      "bash_block_1c" \
      "$(jq -n --arg expected "${SUMMARIES_DIR}" --arg topic "$topic_dir" \
         '{expected_directory: $expected, topic_directory: $topic, searched_pattern: "'"$summary_pattern"'"}')"
  fi

  echo "" >&2
  echo "The workflow cannot proceed without the implementation summary." >&2
  echo "" >&2
  echo "Troubleshooting:" >&2
  echo "  1. Check implementer-coordinator agent output for errors" >&2
  echo "  2. Verify Task invocation in Block 1b executed correctly" >&2
  echo "  3. Verify agent has write permissions to $SUMMARIES_DIR" >&2
  echo "  4. Run /errors --command /implement --since 1h for detailed error logs" >&2
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
append_workflow_state "LATEST_SUMMARY" "${LATEST_SUMMARY:-}"
append_workflow_state "SUMMARY_COUNT" "${SUMMARY_COUNT:-}"

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

# Find the most recent summary file (agent should have created it)
LATEST_SUMMARY=""
if [ -d "$SUMMARIES_DIR" ]; then
  LATEST_SUMMARY=$(ls -t "$SUMMARIES_DIR"/*.md 2>/dev/null | head -1)
fi

# Parse all fields from agent return signal (from summary file metadata)
if [ -n "$LATEST_SUMMARY" ] && [ -f "$LATEST_SUMMARY" ]; then
  echo "Parsing agent return signal from: $LATEST_SUMMARY"

  # Extract fields from summary metadata (lines before first markdown heading)
  WORK_REMAINING=$(grep "^work_remaining:" "$LATEST_SUMMARY" | sed 's/work_remaining:[[:space:]]*//' | head -1 || echo "")
  CONTEXT_EXHAUSTED=$(grep "^context_exhausted:" "$LATEST_SUMMARY" | sed 's/context_exhausted:[[:space:]]*//' | head -1 || echo "false")
  SUMMARY_PATH="$LATEST_SUMMARY"
  CONTEXT_USAGE_PERCENT=$(grep "^context_usage_percent:" "$LATEST_SUMMARY" | sed 's/context_usage_percent:[[:space:]]*//' | sed 's/%//' | head -1 || echo "0")
  CHECKPOINT_PATH=$(grep "^checkpoint_path:" "$LATEST_SUMMARY" | sed 's/checkpoint_path:[[:space:]]*//' | head -1 || echo "")
  REQUIRES_CONTINUATION=$(grep "^requires_continuation:" "$LATEST_SUMMARY" | sed 's/requires_continuation:[[:space:]]*//' | head -1 || echo "false")
  STUCK_DETECTED=$(grep "^stuck_detected:" "$LATEST_SUMMARY" | sed 's/stuck_detected:[[:space:]]*//' | head -1 || echo "false")
  AGENT_PLAN_FILE=$(grep "^plan_file:" "$LATEST_SUMMARY" | sed 's/plan_file:[[:space:]]*//' | head -1 || echo "")
  AGENT_TOPIC_PATH=$(grep "^topic_path:" "$LATEST_SUMMARY" | sed 's/topic_path:[[:space:]]*//' | head -1 || echo "")

  # Defensive: Log if any critical field missing
  if [ -z "$SUMMARY_PATH" ]; then
    echo "WARNING: Agent return missing summary_path (using discovered: $LATEST_SUMMARY)" >&2
  fi

  echo "✓ Agent return signal parsed successfully"
else
  echo "WARNING: No summary file found, using legacy detection" >&2

  # Fallback to legacy behavior with defaults
  WORK_REMAINING=""
  CONTEXT_EXHAUSTED="false"
  SUMMARY_PATH=""
  CONTEXT_USAGE_PERCENT="0"
  CHECKPOINT_PATH=""
  REQUIRES_CONTINUATION="false"
  STUCK_DETECTED="false"
  AGENT_PLAN_FILE=""
  AGENT_TOPIC_PATH=""
fi

# === VALIDATE AGENT RETURN SIGNAL ===
PARSING_ERRORS=0

if [ -z "$SUMMARY_PATH" ] || [ ! -f "$SUMMARY_PATH" ]; then
  echo "ERROR: Agent return missing valid summary_path" >&2
  ((PARSING_ERRORS++))
fi

if ! [[ "$CONTEXT_USAGE_PERCENT" =~ ^[0-9]+$ ]]; then
  echo "WARNING: Agent return context_usage_percent invalid format: '$CONTEXT_USAGE_PERCENT'" >&2
  CONTEXT_USAGE_PERCENT=0
fi

if [ "$REQUIRES_CONTINUATION" != "true" ] && [ "$REQUIRES_CONTINUATION" != "false" ]; then
  echo "WARNING: Agent return requires_continuation invalid format: '$REQUIRES_CONTINUATION'" >&2
  REQUIRES_CONTINUATION="false"
fi

if [ $PARSING_ERRORS -gt 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "implementer-coordinator return signal parsing failed" \
    "bash_block_1c" \
    "$(jq -n --argjson errors "$PARSING_ERRORS" '{parsing_errors: $errors}')"
fi

# If agent provided plan_file and topic_path, use them instead of state file
if [ -n "$AGENT_PLAN_FILE" ]; then
  PLAN_FILE="$AGENT_PLAN_FILE"
  echo "Using plan_file from agent return: $PLAN_FILE"
  append_workflow_state "PLAN_FILE" "${PLAN_FILE:-}"
fi
if [ -n "$AGENT_TOPIC_PATH" ]; then
  TOPIC_PATH="$AGENT_TOPIC_PATH"
  echo "Using topic_path from agent return: $TOPIC_PATH"
  append_workflow_state "TOPIC_PATH" "${TOPIC_PATH:-}"
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
  append_workflow_state "CHECKPOINT_PATH" "${CHECKPOINT_PATH:-}"
fi

# Fallback: Check summary file for work_remaining if not directly captured
if [ -z "$WORK_REMAINING" ] && [ -n "$SUMMARY_PATH" ] && [ -f "$SUMMARY_PATH" ]; then
  WORK_REMAINING=$(grep -oP 'work_remaining:\s*\K.*' "$SUMMARY_PATH" 2>/dev/null | head -1 || echo "")
fi

# === DEFENSIVE WORK_REMAINING FORMAT CONVERSION ===
# Convert JSON-style array to space-separated scalar if needed
# This handles legacy agent outputs and prevents state_error
# See: .claude/specs/998_repair_implement_20251201_154205/plans/001-repair-implement-20251201-154205-plan.md
if [ -n "$WORK_REMAINING" ] && [[ "$WORK_REMAINING" =~ ^[[:space:]]*\[ ]]; then
  echo "INFO: Converting WORK_REMAINING from JSON array to space-separated string" >&2

  # Strip brackets and commas, normalize spaces
  # Example: "[Phase 4, Phase 5, Phase 6]" -> "Phase 4 Phase 5 Phase 6"
  WORK_REMAINING_CLEAN="${WORK_REMAINING#[}"    # Remove leading [
  WORK_REMAINING_CLEAN="${WORK_REMAINING_CLEAN%]}"  # Remove trailing ]
  WORK_REMAINING_CLEAN="${WORK_REMAINING_CLEAN//,/}"  # Remove commas
  WORK_REMAINING_CLEAN=$(echo "$WORK_REMAINING_CLEAN" | tr -s ' ')  # Normalize spaces
  WORK_REMAINING="$WORK_REMAINING_CLEAN"
fi

# === DEFENSIVE VALIDATION: Override requires_continuation if work remains ===
# Contract invariant: If work_remaining is non-empty, continuation MUST be required
# This defends against agent bugs where requires_continuation=false with work remaining

echo ""
echo "=== Defensive Validation: Continuation Signal ==="
echo ""

# Helper function: Check if work_remaining is truly empty
is_work_remaining_empty() {
  local work_remaining="${1:-}"

  # Empty string
  [ -z "$work_remaining" ] && return 0

  # Literal "0"
  [ "$work_remaining" = "0" ] && return 0

  # Empty JSON array "[]"
  [ "$work_remaining" = "[]" ] && return 0

  # Contains only whitespace
  [[ "$work_remaining" =~ ^[[:space:]]*$ ]] && return 0

  # Work remains
  return 1
}

# Check if work truly remains
if ! is_work_remaining_empty "$WORK_REMAINING"; then
  # Work remains - continuation is MANDATORY
  if [ "$REQUIRES_CONTINUATION" != "true" ]; then
    echo "WARNING: Agent returned requires_continuation=false with non-empty work_remaining" >&2
    echo "  work_remaining: $WORK_REMAINING" >&2
    echo "  OVERRIDING: Forcing continuation due to incomplete work" >&2

    # Log agent contract violation for diagnostics
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "validation_error" \
      "Agent contract violation: requires_continuation=false with work_remaining non-empty" \
      "bash_block_1c_defensive_validation" \
      "$(jq -n --arg work "$WORK_REMAINING" --arg cont "$REQUIRES_CONTINUATION" \
         '{work_remaining: $work, requires_continuation: $cont, override: "forced_true"}')"

    # Override agent signal
    REQUIRES_CONTINUATION="true"
    echo "Continuation requirement: OVERRIDDEN TO TRUE (defensive validation)" >&2
  else
    echo "Continuation requirement: TRUE (work remains, agent agrees)" >&2
  fi
else
  # No work remains - trust agent signal
  echo "Continuation requirement: $REQUIRES_CONTINUATION (no work remaining, agent decision accepted)" >&2
fi

echo ""

# === COMPLETION CHECK ===
# Trust the implementer-coordinator's requires_continuation signal (now validated)
if [ "$REQUIRES_CONTINUATION" = "true" ]; then
  echo "Coordinator reports continuation required"

  # Prepare for next iteration
  NEXT_ITERATION=$((ITERATION + 1))
  CONTINUATION_CONTEXT="${IMPLEMENT_WORKSPACE}/iteration_${ITERATION}_summary.md"

  echo "Preparing iteration $NEXT_ITERATION..."

  # Update state for next iteration
  append_workflow_state "ITERATION" "${NEXT_ITERATION:-}"
  append_workflow_state "WORK_REMAINING" "${WORK_REMAINING:-}"
  append_workflow_state "CONTINUATION_CONTEXT" "${CONTINUATION_CONTEXT:-}"
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

  append_workflow_state "WORK_REMAINING" "${WORK_REMAINING:-}"
fi

echo ""
echo "Iteration check complete"
```

**ITERATION DECISION**:

Check the IMPLEMENTATION_STATUS from Block 1c iteration check:

**If IMPLEMENTATION_STATUS is "continuing"**: Work remains and context available. Loop back to Block 1b.

**EXECUTE NOW**: The implementer-coordinator reported work remaining and sufficient context. Repeat the Task invocation from Block 1b with updated iteration variables:

- ITERATION = ${ITERATION} (updated by Block 1c)
- CONTINUATION_CONTEXT = ${CONTINUATION_CONTEXT}
- WORK_REMAINING = ${WORK_REMAINING}

Before proceeding, load state and verify iteration variables:

```bash
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e

# Load state to get updated ITERATION value (Block 1c saved NEXT_ITERATION as ITERATION)
source "${HOME}/.config/.claude/lib/core/state-persistence.sh" 2>/dev/null || exit 1
STATE_FILE=$(discover_latest_state_file "implement")
if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  echo "ERROR: Failed to discover state file from previous block" >&2
  exit 1
fi
source "$STATE_FILE"  # WORKFLOW_ID restored
source "${HOME}/.config/.claude/lib/core/error-handling.sh" 2>/dev/null || exit 1
ensure_error_log_exists

COMMAND_NAME="/implement"
load_workflow_state "$WORKFLOW_ID" false

# Validate iteration counter was restored
if [ -z "$ITERATION" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "" \
    "state_error" \
    "ITERATION variable not restored from state during continuation" \
    "bash_block_iteration_decision" \
    "$(jq -n '{status: "state_restoration_failed", variable: "ITERATION"}')"

  echo "ERROR: Iteration state restoration failed" >&2
  exit 1
fi

# Check if max iterations exceeded
if [ "$ITERATION" -gt "$MAX_ITERATIONS" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "" \
    "execution_error" \
    "Max iterations exceeded during continuation" \
    "bash_block_iteration_decision" \
    "$(jq -n --argjson iter "$ITERATION" --argjson max "$MAX_ITERATIONS" \
       '{iteration: $iter, max_iterations: $max, status: "exceeded"}')"

  echo "ERROR: Max iterations ($MAX_ITERATIONS) exceeded" >&2
  exit 1
fi

echo "Continuing to iteration $ITERATION/$MAX_ITERATIONS..."
```

**EXECUTE NOW**: USE the Task tool to invoke the implementer-coordinator agent for implementation execution (iteration loop re-invocation).

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with wave-based parallelization (iteration ${ITERATION}/${MAX_ITERATIONS})"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    You are executing the implementation phase for: implement workflow

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
    - continuation_context: ${CONTINUATION_CONTEXT}
    - iteration: ${ITERATION}

    **CRITICAL**: You MUST create implementation summary at ${TOPIC_PATH}/summaries/
    The orchestrator will validate the summary exists after you return.

    Workflow-Specific Context:
    - Starting Phase: ${STARTING_PHASE}
    - Workflow Type: implement-only
    - Execution Mode: wave-based (parallel where possible)
    - Current Iteration: ${ITERATION}/${MAX_ITERATIONS}
    - Max Iterations: ${MAX_ITERATIONS}
    - Context Threshold: ${CONTEXT_THRESHOLD}%
    - Continuation Context: ${CONTINUATION_CONTEXT}
    - Work Remaining: ${WORK_REMAINING}

    Progress Tracking Instructions:
    - Source checkbox utilities: source ${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh
    - Before starting each phase: add_in_progress_marker '$PLAN_FILE' <phase_num>
    - After completing each phase: mark_phase_complete '$PLAN_FILE' <phase_num> && add_complete_marker '$PLAN_FILE' <phase_num>
    - This creates visible progress: [NOT STARTED] -> [IN PROGRESS] -> [COMPLETE]

    Execute remaining implementation phases according to the plan.

    IMPORTANT: After completing phases or if context exhaustion detected:
    - Create a summary in summaries/ directory
    - Summary must have Work Status at TOP showing completion percentage
    - Summary MUST include Testing Strategy section with:
      - Test Files Created (list of test files written during Testing phases)
      - Test Execution Requirements (how to run tests, framework used)
      - Coverage Target (expected coverage percentage)
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

After the Task returns, **proceed to Block 1c verification** to check for further continuation needs or completion.

---

**If IMPLEMENTATION_STATUS is "complete", "stuck", or "max_iterations"**: Proceed to Block 1d.

## Block 1d: Phase Marker Validation and Recovery

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

# === LOAD WORKFLOW STATE ===
STATE_FILE=$(discover_latest_state_file "implement")
if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  echo "ERROR: Failed to discover state file from previous block" >&2
  echo "Search path: ${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_implement_*.sh" >&2
  exit 1
fi
source "$STATE_FILE"  # WORKFLOW_ID restored

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

# Force filesystem sync to ensure implementer-coordinator writes are visible
# (Defensive pattern: prevents reading plan file before writes are fully synced)
sync 2>/dev/null || true
sleep 0.1  # 100ms delay for filesystem consistency

# Count total phases and phases with [COMPLETE] marker
# Apply defensive sanitization pattern to prevent bash conditional syntax errors
# from grep output containing embedded newlines (Pattern from complexity-utils.sh)
TOTAL_PHASES=$(grep -c "^### Phase [0-9]" "$PLAN_FILE" 2>/dev/null || echo "0")
TOTAL_PHASES=$(echo "$TOTAL_PHASES" | tr -d '\n' | tr -d ' ')
TOTAL_PHASES=${TOTAL_PHASES:-0}
[[ "$TOTAL_PHASES" =~ ^[0-9]+$ ]] || TOTAL_PHASES=0

PHASES_WITH_MARKER=$(grep -c "^### Phase [0-9].*\[COMPLETE\]" "$PLAN_FILE" 2>/dev/null || echo "0")
PHASES_WITH_MARKER=$(echo "$PHASES_WITH_MARKER" | tr -d '\n' | tr -d ' ')
PHASES_WITH_MARKER=${PHASES_WITH_MARKER:-0}
[[ "$PHASES_WITH_MARKER" =~ ^[0-9]+$ ]] || PHASES_WITH_MARKER=0

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
        # Defensive: Propagate marker to expanded phase file if exists
        propagate_progress_marker "$PLAN_FILE" "$phase_num" "COMPLETE" 2>/dev/null || true
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

# === SUCCESS CRITERIA VALIDATION ===
echo ""
echo "=== Success Criteria Validation ==="
echo ""

# Check if all phases complete
if type check_all_phases_complete &>/dev/null && check_all_phases_complete "$PLAN_FILE"; then
  echo "All phases complete, validating success criteria..."

  # Attempt to mark success criteria complete
  if type mark_success_criteria_complete &>/dev/null; then
    mark_success_criteria_complete "$PLAN_FILE" 2>/dev/null && \
      echo "✓ Success criteria marked complete" || \
      echo "⚠ Could not update success criteria (non-fatal)"
  else
    echo "⚠ Success criteria update function not available"
  fi
else
  echo "Phases incomplete, skipping success criteria validation"
fi

echo ""

# === PLAN CONSISTENCY VALIDATION ===
echo ""
echo "=== Plan Consistency Validation ==="
echo ""

# Validate metadata status matches phase completion
if type check_all_phases_complete &>/dev/null; then
  if check_all_phases_complete "$PLAN_FILE"; then
    # All phases complete, metadata should be COMPLETE
    METADATA_STATUS=$(grep "^- \*\*Status\*\*:" "$PLAN_FILE" | grep -oE "\[(NOT STARTED|IN PROGRESS|COMPLETE|BLOCKED)\]" || echo "[UNKNOWN]")

    if [ "$METADATA_STATUS" != "[COMPLETE]" ]; then
      echo "⚠ Inconsistency detected: All phases COMPLETE but metadata shows $METADATA_STATUS"

      # Auto-repair: Update metadata to match phase state
      if type update_plan_status &>/dev/null; then
        echo "Auto-repairing: Updating metadata status to COMPLETE..."
        update_plan_status "$PLAN_FILE" "COMPLETE" 2>/dev/null && \
          echo "✓ Metadata status updated to [COMPLETE]" || \
          echo "✗ Failed to update metadata status"
      fi
    else
      echo "✓ Metadata status consistent with phase completion"
    fi
  else
    # Some phases incomplete
    METADATA_STATUS=$(grep "^- \*\*Status\*\*:" "$PLAN_FILE" | grep -oE "\[(NOT STARTED|IN PROGRESS|COMPLETE|BLOCKED)\]" || echo "[UNKNOWN]")

    if [ "$METADATA_STATUS" = "[COMPLETE]" ]; then
      echo "⚠ Inconsistency detected: Phases incomplete but metadata shows COMPLETE"
      echo "This indicates manual metadata modification or state corruption"

      # Log error but don't auto-repair
      log_command_error \
        "$COMMAND_NAME" \
        "$WORKFLOW_ID" \
        "$USER_ARGS" \
        "validation_error" \
        "Plan metadata shows COMPLETE but phases remain incomplete" \
        "bash_block_1d_consistency" \
        "$(jq -n --arg status "$METADATA_STATUS" --argjson phases "$PHASES_WITH_MARKER" --argjson total "$TOTAL_PHASES" \
           '{metadata_status: $status, complete_phases: $phases, total_phases: $total}')"
    else
      echo "✓ Metadata status consistent with incomplete phases"
    fi
  fi
else
  echo "⚠ Consistency validation skipped (check_all_phases_complete function unavailable)"
fi

echo ""

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
append_workflow_state "PHASES_WITH_MARKER" "${PHASES_WITH_MARKER:-}"
append_workflow_state "TOTAL_PHASES" "${TOTAL_PHASES:-}"

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
# checkbox-utils.sh already sourced in this block (line 34)
if type check_all_phases_complete &>/dev/null && type update_plan_status &>/dev/null; then
  if check_all_phases_complete "$PLAN_FILE"; then
    update_plan_status "$PLAN_FILE" "COMPLETE" 2>/dev/null && \
      echo "Plan metadata status updated to [COMPLETE]"
  fi
fi
```

## Block 2: Completion

**EXECUTE NOW**: Complete workflow, create console summary with /test next step, and cleanup.

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
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh" 2>/dev/null || true
ensure_error_log_exists

# === LOAD STATE ===
STATE_FILE=$(discover_latest_state_file "implement")
if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  echo "ERROR: Failed to discover state file from previous block" >&2
  exit 1
fi
source "$STATE_FILE"  # WORKFLOW_ID restored
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
    COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" | cut -d'=' -f2- || echo "/implement")
  else
    COMMAND_NAME="/implement"
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

[ "${DEBUG:-}" = "1" ] && echo "DEBUG: Loaded state: $CURRENT_STATE" >&2
echo "Block 2: State validated ($CURRENT_STATE)"

# === COMPLETE WORKFLOW ===
# State transition to COMPLETE (implement-only terminal state allows implement → complete)
sm_transition "$STATE_COMPLETE" "implementation complete (no testing)" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State transition to COMPLETE failed" \
    "bash_block_2" \
    "$(jq -n --arg state "COMPLETE" '{target_state: $state}')"

  echo "ERROR: State transition to COMPLETE failed" >&2
  exit 1
fi

# === UPDATE METADATA STATUS ===
# Update plan metadata status to COMPLETE if all phases done
if type check_all_phases_complete &>/dev/null && type update_plan_status &>/dev/null; then
  if check_all_phases_complete "$PLAN_FILE"; then
    update_plan_status "$PLAN_FILE" "COMPLETE" 2>/dev/null && \
      echo "Plan metadata status updated to [COMPLETE]"
  fi
fi

# === PERSIST STATE TRANSITIONS ===
# CRITICAL: Save state before any cleanup operations
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
    "bash_block_2" \
    "$(jq -n --arg file "${STATE_FILE:-unknown}" '{state_file: $file}')"
  echo "ERROR: State persistence failed" >&2
  exit 1
fi

# === CONSOLE SUMMARY (PLAN-DERIVED) ===
# Source summary formatting library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/summary-formatting.sh" 2>/dev/null || {
  echo "ERROR: Failed to load summary-formatting library" >&2
  exit 1
}

# Determine actual completion state from plan file
TOTAL_PHASES=$(grep -E -c "^##+ Phase [0-9]" "$PLAN_FILE" 2>/dev/null || echo "0")
COMPLETE_PHASES=$(grep -E -c "^##+ Phase [0-9].*\[COMPLETE\]" "$PLAN_FILE" 2>/dev/null || echo "0")

# Build summary text based on actual completion
if [ "$COMPLETE_PHASES" -eq "$TOTAL_PHASES" ]; then
  SUMMARY_TEXT="Completed implementation of all $TOTAL_PHASES phases. Tests are written but NOT executed. Run /test to execute test suite."
  COMPLETION_STATUS="complete"
else
  SUMMARY_TEXT="Completed implementation of $COMPLETE_PHASES/$TOTAL_PHASES phases. Remaining work: ${WORK_REMAINING:-unknown}. Run /test to execute tests for completed phases."
  COMPLETION_STATUS="partial"
fi

# Build phases section with actual markers from plan
PHASES=""
for phase_num in $(seq 1 "$TOTAL_PHASES"); do
  PHASE_HEADING=$(grep -E "^##+ Phase ${phase_num}:" "$PLAN_FILE" | head -1)
  PHASE_STATUS=$(echo "$PHASE_HEADING" | grep -oE "\[(NOT STARTED|IN PROGRESS|COMPLETE|BLOCKED)\]" || echo "[UNKNOWN]")
  PHASE_NAME=$(echo "$PHASE_HEADING" | sed -E 's/^##+ Phase [0-9]+: ([^[]+).*/\1/' | sed 's/[[:space:]]*$//')

  PHASES="${PHASES}  • Phase $phase_num: $PHASE_NAME $PHASE_STATUS
"
done

# Build artifacts section
SUMMARIES_DIR="${TOPIC_PATH}/summaries"
ARTIFACTS="  📄 Plan: $PLAN_FILE"
if [ -d "$SUMMARIES_DIR" ]; then
  LATEST_SUMMARY=$(ls -t "$SUMMARIES_DIR"/*.md 2>/dev/null | head -n 1)
  if [ -n "$LATEST_SUMMARY" ]; then
    ARTIFACTS="${ARTIFACTS}
  ✅ Summary: $LATEST_SUMMARY"
  fi
fi

# Build next steps - emphasize running /test
NEXT_STEPS="  • Review implementation: cat $LATEST_SUMMARY
  • Run tests: /test $PLAN_FILE
  • Run tests with summary: /test --file $LATEST_SUMMARY
  • Run /todo to update TODO.md (adds implementation to tracking)"

# Print standardized summary
print_artifact_summary "Implementation" "$SUMMARY_TEXT" "$PHASES" "$ARTIFACTS" "$NEXT_STEPS"

# Emit completion reminder
echo ""
echo "📋 Next Step: Run /todo to update TODO.md with this implementation"
echo ""

# === RETURN IMPLEMENTATION_COMPLETE SIGNAL ===
# Signal enables buffer-opener hook to open summary
if [ -n "$LATEST_SUMMARY" ] && [ -f "$LATEST_SUMMARY" ]; then
  echo ""
  echo "IMPLEMENTATION_COMPLETE"
  echo "  summary_path: $LATEST_SUMMARY"
  echo "  plan_path: $PLAN_FILE"
  echo "  next_command: /test $PLAN_FILE"
  echo ""
fi

# Cleanup checkpoints
delete_checkpoint "implement" 2>/dev/null || true

# Cleanup temp files but NOT state file (needed by /test)
rm -f "${CLAUDE_PROJECT_DIR}/.claude/tmp/implement_state_id.txt" 2>/dev/null
# NOTE: Do NOT remove STATE_FILE - /test needs it for plan/topic path restoration

exit 0
```

---

**Phase 0 Auto-Detection**:

As of 2025-12-09, `/implement` automatically detects the lowest incomplete phase when no explicit starting phase is provided:

- **Auto-Detection**: Scans plan for first phase without `[COMPLETE]` marker
- **Includes Phase 0**: Previously skipped phases (e.g., Phase 0: Standards Revision) now execute automatically
- **Override**: Explicit phase argument overrides auto-detection
- **Example**: Plan with Phase 0 incomplete starts at Phase 0, not Phase 1

See `/lean-implement` documentation for complete auto-detection examples and checkpoint resume workflow patterns.

**Troubleshooting**:

- **No plan found**: Create a plan first using `/plan`
- **Implementation incomplete**: Check implementer-coordinator agent logs
- **Checkpoint issues**: Delete stale checkpoint: `rm ~/.claude/data/checkpoints/implement_checkpoint.json`
- **State machine errors**: Ensure library versions compatible (workflow-state-machine.sh >=2.0.0)
- **Phase 0 skipped**: Verify plan has phase headers with status markers ([NOT STARTED], [COMPLETE])

**Usage Examples**:

```bash
# Auto-resume from most recent plan
/implement

# Implement specific plan
/implement .claude/specs/123_auth/plans/001_implementation.md

# Resume from specific phase (e.g., phase 3)
/implement .claude/specs/123_auth/plans/001_implementation.md 3

# Dry-run preview
/implement --dry-run

# Custom iterations/threshold
/implement plan.md --max-iterations=10 --context-threshold=85
```
