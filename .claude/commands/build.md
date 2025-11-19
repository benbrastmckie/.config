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
documentation: See .claude/docs/guides/build-command-guide.md for complete usage guide
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
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/library-version-check.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/error-handling.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/checkpoint-utils.sh" 2>/dev/null

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

if ! echo "$STARTING_PHASE" | grep -Eq "^[0-9]+$"; then
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
source "${CLAUDE_PROJECT_DIR}/.claude/lib/checkbox-utils.sh" 2>/dev/null || true

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
echo ""

# === INITIALIZE STATE MACHINE ===
WORKFLOW_TYPE="full-implementation"
TERMINAL_STATE="complete"
COMMAND_NAME="build"

WORKFLOW_ID="build_$(date +%s)"
STATE_ID_FILE="${HOME}/.claude/tmp/build_state_id.txt"
mkdir -p "$(dirname "$STATE_ID_FILE")"
echo "$WORKFLOW_ID" > "$STATE_ID_FILE"
export WORKFLOW_ID

init_workflow_state "$WORKFLOW_ID"

if ! sm_init "$PLAN_FILE" "$COMMAND_NAME" "$WORKFLOW_TYPE" "1" "[]" 2>&1; then
  echo "ERROR: State machine initialization failed" >&2
  exit 1
fi

# === TRANSITION TO IMPLEMENT ===
if ! sm_transition "$STATE_IMPLEMENT" 2>&1; then
  echo "ERROR: State transition to IMPLEMENT failed" >&2
  exit 1
fi

TOPIC_PATH=$(dirname "$(dirname "$PLAN_FILE")")

# === PERSIST FOR BLOCK 2 ===
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
    - Source checkbox-utils.sh: source ${CLAUDE_PROJECT_DIR}/.claude/lib/checkbox-utils.sh
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

# === LOAD STATE ===
STATE_ID_FILE="${HOME}/.claude/tmp/build_state_id.txt"
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

source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/checkbox-utils.sh" 2>/dev/null

load_workflow_state "$WORKFLOW_ID" false

# === VALIDATE STATE AFTER LOAD ===
if [ -z "$STATE_FILE" ]; then
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

save_completed_states_to_state 2>/dev/null || true

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
    1. Source checkbox utilities: source .claude/lib/checkbox-utils.sh
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

## Block 2: Testing Phase

**EXECUTE NOW**: Verify implementation and run tests:

```bash
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e  # Fail-fast per code-standards.md

# DEBUG_LOG initialization per spec 778
DEBUG_LOG="${HOME}/.claude/tmp/workflow_debug.log"
mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null

# === LOAD STATE ===
STATE_ID_FILE="${HOME}/.claude/tmp/build_state_id.txt"
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

source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh" 2>/dev/null

load_workflow_state "$WORKFLOW_ID" false

# === VALIDATE STATE AFTER LOAD ===
if [ -z "$STATE_FILE" ]; then
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
if ! sm_transition "$STATE_TEST" 2>&1; then
  echo "ERROR: State transition to TEST failed" >&2
  exit 1
fi

echo "=== Phase 2: Testing ==="
echo ""

# === RUN TESTS ===
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
  echo ""

  TEST_OUTPUT=$($TEST_COMMAND 2>&1)
  TEST_EXIT_CODE=$?

  echo "$TEST_OUTPUT"
  echo ""

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

# === PERSIST FOR BLOCK 3 ===
append_workflow_state "TESTS_PASSED" "$TESTS_PASSED"
append_workflow_state "TEST_COMMAND" "$TEST_COMMAND"
append_workflow_state "TEST_EXIT_CODE" "${TEST_EXIT_CODE:-0}"
append_workflow_state "COMMIT_COUNT" "$COMMIT_COUNT"

save_completed_states_to_state 2>/dev/null

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

# === LOAD STATE ===
STATE_ID_FILE="${HOME}/.claude/tmp/build_state_id.txt"
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

source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/checkpoint-utils.sh" 2>/dev/null

load_workflow_state "$WORKFLOW_ID" false

# === VALIDATE STATE AFTER LOAD ===
if [ -z "$STATE_FILE" ]; then
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
  if ! sm_transition "$STATE_DEBUG" 2>&1; then
    echo "ERROR: State transition to DEBUG failed" >&2
    exit 1
  fi

  echo "=== Phase 3: Debug (Tests Failed) ==="
  echo ""

  DEBUG_DIR="${TOPIC_PATH}/debug"
  mkdir -p "$DEBUG_DIR"

  echo "Debug directory: $DEBUG_DIR"
  echo "Test command: $TEST_COMMAND"
  echo "Exit code: $TEST_EXIT_CODE"
  echo ""
  echo "NOTE: After debug, re-run /build to retry tests"

  append_workflow_state "DEBUG_DIR" "$DEBUG_DIR"
else
  # Tests passed -> Documentation phase
  if ! sm_transition "$STATE_DOCUMENT" 2>&1; then
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

save_completed_states_to_state 2>/dev/null
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

# === LOAD STATE ===
STATE_ID_FILE="${HOME}/.claude/tmp/build_state_id.txt"
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

source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/checkpoint-utils.sh" 2>/dev/null

load_workflow_state "$WORKFLOW_ID" false

# === VALIDATE STATE AFTER LOAD ===
if [ -z "$STATE_FILE" ]; then
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
if ! sm_transition "$STATE_COMPLETE" 2>&1; then
  echo "ERROR: State transition to COMPLETE failed" >&2
  exit 1
fi

echo ""
echo "=== Build Complete ==="
echo "Workflow Type: full-implementation"
echo "Plan: $PLAN_FILE"
echo "Phases Completed: ${COMPLETED_PHASE_COUNT:-0}"
echo "Implementation: Complete"
echo "Testing: $([ "$TESTS_PASSED" = "true" ] && echo "Passed" || echo "Failed (debugged)")"
echo ""

# Show completed phases summary
if [ -n "${COMPLETED_PHASES:-}" ]; then
  echo "Phase Summary:"
  # Parse comma-separated list of completed phases
  IFS=',' read -ra PHASE_ARRAY <<< "${COMPLETED_PHASES%,}"
  for phase in "${PHASE_ARRAY[@]}"; do
    if [ -n "$phase" ]; then
      echo "  ✓ Phase $phase: Complete"
    fi
  done
  echo ""
fi

if [ "$TESTS_PASSED" = "true" ]; then
  echo "Next Steps:"
  echo "- Review changes: git log --oneline -$COMMIT_COUNT"
  echo "- Create PR: gh pr create"
  delete_checkpoint "build" 2>/dev/null || true
else
  echo "Next Steps:"
  echo "- Review debug analysis above"
  echo "- Apply fixes and re-run: /build $PLAN_FILE"
fi

# Cleanup
rm -f "${HOME}/.claude/tmp/build_state_${WORKFLOW_ID}.txt" 2>/dev/null
rm -f "${HOME}/.claude/tmp/build_state_id.txt" 2>/dev/null

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
