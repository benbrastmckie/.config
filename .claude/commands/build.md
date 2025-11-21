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

## Block 1: Consolidated Setup

**EXECUTE NOW**: The user invoked `/build [plan-file] [starting-phase] [--dry-run]`. Capture those arguments.

In the **bash block below**, replace `YOUR_BUILD_ARGS_HERE` with the actual build arguments (or leave empty for auto-resume).

**Examples**:
- If user ran `/build plan.md 3 --dry-run`, change to: `echo "plan.md 3 --dry-run" > "$TEMP_FILE"`
- If user ran `/build`, change to: `echo "" > "$TEMP_FILE"` (auto-resume mode)

Execute this bash block with your substitution:

```bash
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e  # Fail-fast per code-standards.md

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

# === SOURCE LIBRARIES ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/library-version-check.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null

# === INITIALIZE ERROR LOGGING ===
ensure_error_log_exists

source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/checkpoint-utils.sh" 2>/dev/null

check_library_requirements "$(cat <<'EOF'
workflow-state-machine.sh: ">=2.0.0"
state-persistence.sh: ">=1.5.0"
EOF
)" || exit 1

# === PARSE ARGUMENTS ===
read -ra ARGS_ARRAY <<< "$BUILD_ARGS"
PLAN_FILE="${ARGS_ARRAY[0]:-}"
STARTING_PHASE="${ARGS_ARRAY[1]:-1}"
DRY_RUN="false"

for arg in "${ARGS_ARRAY[@]:2}"; do
  case "$arg" in
    --dry-run) DRY_RUN="true" ;;
  esac
done

if [[ "$STARTING_PHASE" == "--dry-run" ]]; then
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
    PLAN_FILE=$(find "$CLAUDE_PROJECT_DIR/.claude/specs" -path "*/plans/[0-9]*_*.md" -type f -exec ls -t {} + 2>/dev/null | head -1)

    if [ -z "$PLAN_FILE" ]; then
      echo "ERROR: No plan file found in specs/*/plans/" >&2
      exit 1
    fi

    echo "Auto-detected most recent plan: $(basename "$PLAN_FILE")"
  fi
fi

if [ ! -f "$PLAN_FILE" ]; then
  echo "ERROR: Plan file not found: $PLAN_FILE" >&2
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

# === SETUP BASH ERROR TRAP ===
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
sm_transition "$STATE_IMPLEMENT" 2>&1
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

# === PERSIST FOR BLOCK 2 ===
append_workflow_state "COMMAND_NAME" "$COMMAND_NAME"
append_workflow_state "USER_ARGS" "$USER_ARGS"
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"
append_workflow_state "CLAUDE_PROJECT_DIR" "$CLAUDE_PROJECT_DIR"
append_workflow_state "PLAN_FILE" "$PLAN_FILE"
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
append_workflow_state "STARTING_PHASE" "$STARTING_PHASE"

echo "Setup complete: $WORKFLOW_ID"
echo "Topic path: $TOPIC_PATH"
```

**EXECUTE NOW**: USE the Task tool to invoke the implementer-coordinator agent.

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with wave-based parallelization"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    You are executing the implementation phase for: build workflow

    Input:
    - plan_path: $PLAN_FILE
    - topic_path: $TOPIC_PATH
    - artifact_paths:
      - reports: ${TOPIC_PATH}/reports/
      - plans: ${TOPIC_PATH}/plans/
      - summaries: ${TOPIC_PATH}/summaries/
      - debug: ${TOPIC_PATH}/debug/
      - outputs: ${TOPIC_PATH}/outputs/
      - checkpoints: ${HOME}/.claude/data/checkpoints/

    Workflow-Specific Context:
    - Starting Phase: ${STARTING_PHASE}
    - Workflow Type: full-implementation
    - Execution Mode: wave-based (parallel where possible)

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
    summary_path: /path/to/summary
    work_remaining: 0 or list of incomplete phases
  "
}

**EXECUTE NOW**: After implementer-coordinator completes, parse the phase count and invoke spec-updater agent to mark completed phases in the plan hierarchy.

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
  while [ "$current_dir" != "/" ]; then
    [ -d "$current_dir/.claude" ] && { CLAUDE_PROJECT_DIR="$current_dir"; break; }
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
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh" 2>/dev/null

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

# === RESTORE ERROR LOGGING CONTEXT ===
if [ -z "${COMMAND_NAME:-}" ]; then
  COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "/build")
fi
if [ -z "${USER_ARGS:-}" ]; then
  USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "")
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
    "bash_block_1b" \
    "$(jq -n --arg workflow "$WORKFLOW_ID" '{workflow_id: $workflow}')"

  {
    echo "[$(date)] ERROR: State file path not set"
    echo "WHICH: load_workflow_state"
    echo "WHAT: STATE_FILE variable empty after load"
    echo "WHERE: Phase update block"
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
    "bash_block_1b" \
    "$(jq -n --arg path "$STATE_FILE" '{state_file_path: $path}')"

  {
    echo "[$(date)] ERROR: State file not found"
    echo "WHICH: load_workflow_state"
    echo "WHAT: File does not exist at expected path"
    echo "WHERE: Phase update block"
    echo "PATH: $STATE_FILE"
  } >> "$DEBUG_LOG"
  echo "ERROR: State file not found (see $DEBUG_LOG)" >&2
  exit 1
fi

[ "${DEBUG:-}" = "1" ] && echo "DEBUG: Loaded state from: $STATE_FILE" >&2
echo "Phase update: State validated"

echo ""
echo "=== Phase Update: Marking Completed Phases ==="
echo ""

# Extract phase count from implementer-coordinator output
# Default to detecting from plan file if not explicitly provided
if [ -z "${COMPLETED_PHASE_COUNT:-}" ]; then
  # Count phases in plan file
  COMPLETED_PHASE_COUNT=$(grep -c "^### Phase" "$PLAN_FILE" 2>/dev/null || echo "0")
fi

if [ "$COMPLETED_PHASE_COUNT" -gt 0 ]; then
  echo "Phases to mark complete: $COMPLETED_PHASE_COUNT"
  echo ""

  # Store completed phases for state persistence
  COMPLETED_PHASES=""

  # Track phases that need fallback
  FALLBACK_NEEDED=""

  for phase_num in $(seq 1 "$COMPLETED_PHASE_COUNT"); do
    echo "Marking Phase $phase_num complete..."

    # Try to mark phase complete using checkbox-utils.sh
    if mark_phase_complete "$PLAN_FILE" "$phase_num" 2>/dev/null; then
      echo "  ✓ Checkboxes marked complete"

      # Add [COMPLETE] marker to phase heading
      # Note: add_complete_marker automatically removes [NOT STARTED] and [IN PROGRESS] markers
      if add_complete_marker "$PLAN_FILE" "$phase_num" 2>/dev/null; then
        echo "  ✓ [COMPLETE] marker added"
      else
        echo "  ⚠ [COMPLETE] marker failed"
        FALLBACK_NEEDED="${FALLBACK_NEEDED}${phase_num},"
      fi

      COMPLETED_PHASES="${COMPLETED_PHASES}${phase_num},"
    else
      echo "  ⚠ Phase $phase_num update failed (will use fallback)"
      FALLBACK_NEEDED="${FALLBACK_NEEDED}${phase_num},"
    fi
  done

  # Persist fallback tracking
  append_workflow_state "FALLBACK_NEEDED" "$FALLBACK_NEEDED"

  # Verify checkbox consistency
  if verify_checkbox_consistency "$PLAN_FILE" 1 2>/dev/null; then
    echo ""
    echo "✓ Checkbox hierarchy synchronized"
  else
    echo ""
    echo "⚠ Checkbox hierarchy may need manual verification"
  fi

  # Persist completed phases
  append_workflow_state "COMPLETED_PHASES" "$COMPLETED_PHASES"
  append_workflow_state "COMPLETED_PHASE_COUNT" "$COMPLETED_PHASE_COUNT"
else
  echo "No phases to mark complete"
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
export CLAUDE_PROJECT_DIR

source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null

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

# Extract paths from state
PLAN_FILE=$(grep "^PLAN_FILE=" "$STATE_FILE" | cut -d'=' -f2-)
TOPIC_PATH=$(grep "^TOPIC_PATH=" "$STATE_FILE" | cut -d'=' -f2-)

# Pre-calculate test output path
TEST_OUTPUT_PATH="${TOPIC_PATH}/outputs/test_results_$(date +%s).md"
mkdir -p "${TOPIC_PATH}/outputs" 2>/dev/null || true

# Output paths for Task tool
echo "PLAN_FILE=$PLAN_FILE"
echo "TOPIC_PATH=$TOPIC_PATH"
echo "TEST_OUTPUT_PATH=$TEST_OUTPUT_PATH"
```

Now invoke test-executor subagent via Task tool:

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

# === SOURCE LIBRARIES ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null
ensure_error_log_exists

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
  COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "/build")
fi
if [ -z "${USER_ARGS:-}" ]; then
  USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "")
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
    "bash_block_2" \
    "$(jq -n --arg workflow "$WORKFLOW_ID" '{workflow_id: $workflow}')"

  {
    echo "[$(date)] ERROR: State file path not set"
    echo "WHICH: load_workflow_state"
    echo "WHAT: STATE_FILE variable empty after load"
    echo "WHERE: Block 2, testing phase initialization"
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
    "bash_block_2" \
    "$(jq -n --arg path "$STATE_FILE" '{state_file_path: $path}')"

  {
    echo "[$(date)] ERROR: State file not found"
    echo "WHICH: load_workflow_state"
    echo "WHAT: File does not exist at expected path"
    echo "WHERE: Block 2, testing phase initialization"
    echo "PATH: $STATE_FILE"
  } >> "$DEBUG_LOG"
  echo "ERROR: State file not found (see $DEBUG_LOG)" >&2
  exit 1
fi

if [ -z "${CURRENT_STATE:-}" ] || [ "$CURRENT_STATE" = "initialize" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State restoration failed - CURRENT_STATE invalid" \
    "bash_block_2" \
    "$(jq -n --arg state "${CURRENT_STATE:-empty}" \
       '{current_state: $state, expected: "implement"}')"

  {
    echo "[$(date)] ERROR: State restoration failed"
    echo "WHICH: load_workflow_state"
    echo "WHAT: CURRENT_STATE not properly restored (expected: implement, got: ${CURRENT_STATE:-empty})"
    echo "WHERE: Block 2, testing phase initialization"
    echo "PATH: $STATE_FILE"
  } >> "$DEBUG_LOG"
  echo "ERROR: State restoration failed (see $DEBUG_LOG)" >&2
  exit 1
fi

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
sm_transition "$STATE_TEST" 2>&1
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
# The test-executor subagent was invoked before this block
# It should have created a test artifact at ${TOPIC_PATH}/outputs/test_results_*.md
# Find the most recent test result artifact
TEST_OUTPUT_PATH=$(ls -t "${TOPIC_PATH}/outputs/test_results_"*.md 2>/dev/null | head -1 || echo "")

if [ -z "$TEST_OUTPUT_PATH" ] || [ ! -f "$TEST_OUTPUT_PATH" ]; then
  echo "WARNING: Test artifact not found, test-executor may have failed"
  echo "Attempting fallback: inline test execution"

  # Fallback to inline testing
  TEST_COMMAND=$(grep -oE "(npm test|pytest|\.\/run_all_tests\.sh|:TestSuite)" "$PLAN_FILE" | head -1 || echo "")

  if [ -z "$TEST_COMMAND" ]; then
    if [ -f "package.json" ] && grep -q '"test"' package.json; then
      TEST_COMMAND="npm test"
    elif [ -f "pytest.ini" ] || [ -f "setup.py" ]; then
      TEST_COMMAND="pytest"
    elif [ -f ".claude/run_all_tests.sh" ]; then
      TEST_COMMAND="./.claude/run_all_tests.sh"
    else
      TEST_COMMAND=""
    fi
  fi

  if [ -n "$TEST_COMMAND" ]; then
    echo "Running tests: $TEST_COMMAND"
    TEST_OUTPUT=$($TEST_COMMAND 2>&1)
    TEST_EXIT_CODE=$?
    echo "$TEST_OUTPUT"

    if [ $TEST_EXIT_CODE -ne 0 ]; then
      echo "Tests failed (exit code: $TEST_EXIT_CODE)"
      TESTS_PASSED=false
    else
      echo "Tests passed"
      TESTS_PASSED=true
    fi
  else
    echo "Test phase skipped (no test command)"
    TESTS_PASSED=true
    TEST_EXIT_CODE=0
  fi
else
  echo "Loading test results from: $TEST_OUTPUT_PATH"
  echo ""

  # Extract metadata from test artifact
  TEST_EXIT_CODE=$(grep "^- \*\*Exit Code\*\*:" "$TEST_OUTPUT_PATH" | grep -oE '[0-9]+' | head -1 || echo "0")
  TEST_FRAMEWORK=$(grep "^- \*\*Test Framework\*\*:" "$TEST_OUTPUT_PATH" | cut -d':' -f2- | xargs || echo "unknown")
  TEST_COMMAND=$(grep "^- \*\*Test Command\*\*:" "$TEST_OUTPUT_PATH" | cut -d':' -f2- | xargs || echo "")
  TESTS_FAILED=$(grep "^- \*\*Failed\*\*:" "$TEST_OUTPUT_PATH" | grep -oE '[0-9]+' | head -1 || echo "0")
  TESTS_PASSED_COUNT=$(grep "^- \*\*Passed\*\*:" "$TEST_OUTPUT_PATH" | grep -oE '[0-9]+' | head -1 || echo "0")
  EXECUTION_TIME=$(grep "^- \*\*Execution Time\*\*:" "$TEST_OUTPUT_PATH" | cut -d':' -f2- | xargs || echo "N/A")

  # Display test summary
  echo "Test Framework: $TEST_FRAMEWORK"
  echo "Test Command: $TEST_COMMAND"
  echo "Exit Code: $TEST_EXIT_CODE"
  echo "Tests Passed: $TESTS_PASSED_COUNT"
  echo "Tests Failed: $TESTS_FAILED"
  echo "Execution Time: $EXECUTION_TIME"
  echo ""

  # Determine overall test status
  if [ "$TEST_EXIT_CODE" -ne 0 ] || [ "$TESTS_FAILED" -gt 0 ]; then
    echo "Tests failed"
    TESTS_PASSED=false

    # Display failed test details if available
    if [ "$TESTS_FAILED" -gt 0 ]; then
      echo ""
      echo "Failed Tests:"
      sed -n '/^## Failed Tests/,/^## /p' "$TEST_OUTPUT_PATH" | grep -E '^[0-9]+\.' | head -10 || true
      echo ""
    fi
  else
    echo "Tests passed"
    TESTS_PASSED=true
  fi

  # Store artifact path for potential debugging
  TEST_ARTIFACT_PATH="$TEST_OUTPUT_PATH"
fi

# === PERSIST FOR BLOCK 3 ===
append_workflow_state "TESTS_PASSED" "$TESTS_PASSED"
append_workflow_state "TEST_COMMAND" "$TEST_COMMAND"
append_workflow_state "TEST_EXIT_CODE" "${TEST_EXIT_CODE:-0}"
append_workflow_state "TEST_ARTIFACT_PATH" "${TEST_ARTIFACT_PATH:-}"
append_workflow_state "COMMIT_COUNT" "$COMMIT_COUNT"

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
echo "Proceeding to: $([ "$TESTS_PASSED" = "true" ] && echo "Documentation" || echo "Debug")"
```

## Block 3: Conditional Debug or Documentation

**EXECUTE NOW**: Handle debug (if tests failed) or documentation (if tests passed):

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

# === SOURCE LIBRARIES ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/checkpoint-utils.sh" 2>/dev/null
ensure_error_log_exists

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
  COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "/build")
fi
if [ -z "${USER_ARGS:-}" ]; then
  USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "")
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
    "bash_block_3" \
    "$(jq -n --arg workflow "$WORKFLOW_ID" '{workflow_id: $workflow}')"

  {
    echo "[$(date)] ERROR: State file path not set"
    echo "WHICH: load_workflow_state"
    echo "WHAT: STATE_FILE variable empty after load"
    echo "WHERE: Block 3, debug/document phase initialization"
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
    "bash_block_3" \
    "$(jq -n --arg path "$STATE_FILE" '{state_file_path: $path}')"

  {
    echo "[$(date)] ERROR: State file not found"
    echo "WHICH: load_workflow_state"
    echo "WHAT: File does not exist at expected path"
    echo "WHERE: Block 3, debug/document phase initialization"
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
    "bash_block_3" \
    "$(jq -n '{current_state: "empty"}')"

  {
    echo "[$(date)] ERROR: State restoration failed"
    echo "WHICH: load_workflow_state"
    echo "WHAT: CURRENT_STATE not properly restored (got: empty)"
    echo "WHERE: Block 3, debug/document phase initialization"
    echo "PATH: $STATE_FILE"
  } >> "$DEBUG_LOG"
  echo "ERROR: State restoration failed (see $DEBUG_LOG)" >&2
  exit 1
fi

[ "${DEBUG:-}" = "1" ] && echo "DEBUG: Loaded state: $CURRENT_STATE" >&2
echo "Block 3: State validated ($CURRENT_STATE)"

# === CONDITIONAL BRANCHING ===
if [ "$TESTS_PASSED" = "false" ]; then
  # Tests failed -> Debug phase
  sm_transition "$STATE_DEBUG" 2>&1
  EXIT_CODE=$?
  if [ $EXIT_CODE -ne 0 ]; then
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "state_error" \
      "State transition to DEBUG failed" \
      "bash_block_3" \
      "$(jq -n --arg state "DEBUG" '{target_state: $state}')"

    echo "ERROR: State transition to DEBUG failed" >&2
    exit 1
  fi

  echo "=== Phase 3: Debug (Tests Failed) ==="
  echo ""

  DEBUG_DIR="${TOPIC_PATH}/debug"

  echo "Debug directory: $DEBUG_DIR"
  echo "Test command: $TEST_COMMAND"
  echo "Exit code: $TEST_EXIT_CODE"
  echo ""
  echo "NOTE: After debug, re-run /build to retry tests"

  append_workflow_state "DEBUG_DIR" "$DEBUG_DIR"
else
  # Tests passed -> Documentation phase
  sm_transition "$STATE_DOCUMENT" 2>&1
  EXIT_CODE=$?
  if [ $EXIT_CODE -ne 0 ]; then
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "state_error" \
      "State transition to DOCUMENT failed" \
      "bash_block_3" \
      "$(jq -n --arg state "DOCUMENT" '{target_state: $state}')"

    echo "ERROR: State transition to DOCUMENT failed" >&2
    exit 1
  fi

  echo "=== Phase 3: Documentation ==="
  echo ""

  if git diff --name-only HEAD~${COMMIT_COUNT}..HEAD 2>/dev/null | grep -qE '(\.py|\.js|\.ts|\.go|\.rs)$'; then
    echo "NOTE: Code files modified, documentation update recommended"
  fi

  echo "Documentation phase complete"
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

# === SOURCE LIBRARIES ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/checkpoint-utils.sh" 2>/dev/null
ensure_error_log_exists

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
  COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "/build")
fi
if [ -z "${USER_ARGS:-}" ]; then
  USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "")
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

# === VALIDATE PREDECESSOR STATE ===
case "$CURRENT_STATE" in
  document|debug)
    # Valid - can transition to complete
    ;;
  test)
    {
      echo "[$(date)] ERROR: Invalid predecessor state for completion"
      echo "WHICH: sm_transition to complete"
      echo "WHAT: Cannot transition to complete from test state - Block 3 did not execute"
      echo "WHERE: Block 4, workflow completion"
      echo "CURRENT_STATE: $CURRENT_STATE"
      echo ""
      echo "TROUBLESHOOTING:"
      echo "1. Check Block 3 for errors (debug/document phase)"
      echo "2. Verify state file contains expected transitions"
      echo "3. Check for history expansion errors in previous blocks"
    } >> "$DEBUG_LOG"
    echo "ERROR: Invalid predecessor state - Block 3 did not complete (see $DEBUG_LOG)" >&2
    exit 1
    ;;
  implement)
    {
      echo "[$(date)] ERROR: Invalid predecessor state for completion"
      echo "WHICH: sm_transition to complete"
      echo "WHAT: Cannot transition to complete from implement state - Blocks 2 and 3 did not execute"
      echo "WHERE: Block 4, workflow completion"
      echo "CURRENT_STATE: $CURRENT_STATE"
      echo ""
      echo "TROUBLESHOOTING:"
      echo "1. Check Block 2 for errors (testing phase)"
      echo "2. Check Block 3 for errors (debug/document phase)"
      echo "3. Verify state file contains expected transitions"
    } >> "$DEBUG_LOG"
    echo "ERROR: Invalid predecessor state - Blocks 2 and 3 did not complete (see $DEBUG_LOG)" >&2
    exit 1
    ;;
  *)
    {
      echo "[$(date)] ERROR: Unexpected predecessor state"
      echo "WHICH: sm_transition to complete"
      echo "WHAT: Unrecognized state before completion"
      echo "WHERE: Block 4, workflow completion"
      echo "CURRENT_STATE: $CURRENT_STATE"
    } >> "$DEBUG_LOG"
    echo "ERROR: Unexpected predecessor state '$CURRENT_STATE' (see $DEBUG_LOG)" >&2
    exit 1
    ;;
esac

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
    "bash_block_4" \
    "$(jq -n --arg state "COMPLETE" '{target_state: $state}')"

  echo "ERROR: State transition to COMPLETE failed" >&2
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
  • Review plan updates: cat $PLAN_FILE"
else
  NEXT_STEPS="  • Review debug output: cat $LATEST_SUMMARY
  • Fix remaining issues and re-run: /build $PLAN_FILE
  • Check test failures: see summary for details"
fi

# Print standardized summary
print_artifact_summary "Build" "$SUMMARY_TEXT" "$PHASES" "$ARTIFACTS" "$NEXT_STEPS"

# Update metadata status if all phases complete
if type check_all_phases_complete &>/dev/null && type update_plan_status &>/dev/null; then
  if check_all_phases_complete "$PLAN_FILE"; then
    if update_plan_status "$PLAN_FILE" "COMPLETE" 2>/dev/null; then
      echo ""
      echo "✓ Plan metadata status updated to [COMPLETE]"
    fi
  fi
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
