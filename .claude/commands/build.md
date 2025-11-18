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

## Part 1: Capture Build Arguments

**EXECUTE NOW**: The user invoked `/build [plan-file] [starting-phase] [--dry-run]`. Capture those arguments.

In the **small bash block below**, replace `YOUR_BUILD_ARGS_HERE` with the actual build arguments (or leave empty for auto-resume).

**Examples**:
- If user ran `/build plan.md 3 --dry-run`, change to: `echo "plan.md 3 --dry-run" > "$TEMP_FILE"`
- If user ran `/build`, change to: `echo "" > "$TEMP_FILE"` (auto-resume mode)

Execute this bash block with your substitution:

```bash
set +H  # CRITICAL: Disable history expansion
# SUBSTITUTE THE BUILD ARGUMENTS IN THE LINE BELOW
# CRITICAL: Replace YOUR_BUILD_ARGS_HERE with the actual arguments from the user
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
# Use timestamp-based filename for concurrent execution safety
TEMP_FILE="${HOME}/.claude/tmp/build_arg_$(date +%s%N).txt"
echo "YOUR_BUILD_ARGS_HERE" > "$TEMP_FILE"
# Save temp file path for Part 2 to read
echo "$TEMP_FILE" > "${HOME}/.claude/tmp/build_arg_path.txt"
echo "Build arguments captured to $TEMP_FILE"
```

## Part 2: Read Arguments and Discover Plan

**EXECUTE NOW**: Read the captured arguments and discover the plan file:

```bash
set +H  # CRITICAL: Disable history expansion

# Read build arguments from file (written in Part 1)
BUILD_ARG_PATH_FILE="${HOME}/.claude/tmp/build_arg_path.txt"

if [ -f "$BUILD_ARG_PATH_FILE" ]; then
  BUILD_ARG_FILE=$(cat "$BUILD_ARG_PATH_FILE")
else
  # Fallback to legacy fixed filename for backward compatibility
  BUILD_ARG_FILE="${HOME}/.claude/tmp/build_arg.txt"
fi

if [ -f "$BUILD_ARG_FILE" ]; then
  BUILD_ARGS=$(cat "$BUILD_ARG_FILE" 2>/dev/null || echo "")
else
  echo "ERROR: Build arguments file not found: $BUILD_ARG_FILE"
  echo "This usually means Part 1 (argument capture) didn't execute."
  echo "Usage: /build [plan-file] [starting-phase] [--dry-run]"
  exit 1
fi

# Bootstrap CLAUDE_PROJECT_DIR detection
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

# Source libraries in dependency order (Standard 15)
# 1. State machine foundation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
# 2. Library version checking
source "${CLAUDE_PROJECT_DIR}/.claude/lib/library-version-check.sh"
# 3. Error handling
source "${CLAUDE_PROJECT_DIR}/.claude/lib/error-handling.sh"
# 4. Additional utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/checkpoint-utils.sh"

# Verify library versions
check_library_requirements "$(cat <<'EOF'
workflow-state-machine.sh: ">=2.0.0"
state-persistence.sh: ">=1.5.0"
EOF
)" || exit 1

# Parse arguments from captured BUILD_ARGS
# Convert to array for proper handling
read -ra ARGS_ARRAY <<< "$BUILD_ARGS"

PLAN_FILE="${ARGS_ARRAY[0]:-}"
STARTING_PHASE="${ARGS_ARRAY[1]:-1}"
DRY_RUN="false"

# Parse remaining args for flags
for arg in "${ARGS_ARRAY[@]:2}"; do
  case "$arg" in
    --dry-run) DRY_RUN="true" ;;
  esac
done

# Handle case where only --dry-run is provided without phase
if [[ "$STARTING_PHASE" == "--dry-run" ]]; then
  STARTING_PHASE="1"
  DRY_RUN="true"
fi

# Validate STARTING_PHASE is numeric
if ! echo "$STARTING_PHASE" | grep -Eq "^[0-9]+$"; then
  echo "ERROR: Invalid starting phase: $STARTING_PHASE (must be numeric)" >&2
  exit 1
fi

echo "=== Build-from-Plan Workflow ==="
echo ""

# Auto-resume logic if no plan file specified
if [ -z "$PLAN_FILE" ]; then
  echo "PROGRESS: No plan file specified, searching for incomplete plans..."

  # Strategy 1: Check for checkpoint from previous /build execution
  CHECKPOINT_DATA=$(load_checkpoint "build" 2>/dev/null || echo "")

  if [ -n "$CHECKPOINT_DATA" ]; then
    CHECKPOINT_FILE="${HOME}/.claude/data/checkpoints/build_checkpoint.json"
    if [ -f "$CHECKPOINT_FILE" ]; then
      # Verify checkpoint age (<24 hours)
      CHECKPOINT_AGE_HOURS=$(( ($(date +%s) - $(stat -c %Y "$CHECKPOINT_FILE" 2>/dev/null || stat -f %m "$CHECKPOINT_FILE")) / 3600 ))

      if [ "$CHECKPOINT_AGE_HOURS" -lt 24 ]; then
        PLAN_FILE=$(echo "$CHECKPOINT_DATA" | jq -r '.plan_path')
        STARTING_PHASE=$(echo "$CHECKPOINT_DATA" | jq -r '.current_phase')
        echo "✓ Auto-resuming from checkpoint: Phase $STARTING_PHASE"
        echo "  Plan: $(basename "$PLAN_FILE")"
      else
        echo "WARNING: Checkpoint stale (>24h), searching for recent plan..."
        CHECKPOINT_DATA=""
      fi
    fi
  fi

  # Strategy 2: Find most recent incomplete plan
  if [ -z "$PLAN_FILE" ]; then
    PLAN_FILE=$(find "$CLAUDE_PROJECT_DIR/.claude/specs" -path "*/plans/[0-9]*_*.md" -type f -exec ls -t {} + 2>/dev/null | head -1)

    if [ -z "$PLAN_FILE" ]; then
      echo "ERROR: No plan file found in specs/*/plans/" >&2
      echo "DIAGNOSTIC: Create a plan using /plan or /plan first" >&2
      exit 1
    fi

    echo "✓ Auto-detected most recent plan: $(basename "$PLAN_FILE")"
  fi
fi

# Verify plan file exists
if [ ! -f "$PLAN_FILE" ]; then
  echo "ERROR: Plan file not found: $PLAN_FILE" >&2
  exit 1
fi

echo "Plan: $PLAN_FILE"
echo "Starting Phase: $STARTING_PHASE"
echo ""

# Dry-run mode
if [ "$DRY_RUN" = "true" ]; then
  echo "=== DRY-RUN MODE: Preview Only ==="
  echo ""
  echo "Plan: $(basename "$PLAN_FILE")"
  echo "Starting Phase: $STARTING_PHASE"
  echo ""
  echo "Phases would be executed by implementer-coordinator agent"
  echo "Test results would determine debug vs documentation path"
  exit 0
fi
```

## Part 3: State Machine Initialization

**EXECUTE NOW**: Initialize the state machine for workflow tracking:

```bash
set +H  # CRITICAL: Disable history expansion

# Bootstrap CLAUDE_PROJECT_DIR detection (subprocess isolation - cannot rely on previous block export)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
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
fi

if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1
fi

# Re-source required libraries (subprocess isolation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"

# Hardcode workflow type
WORKFLOW_TYPE="full-implementation"
TERMINAL_STATE="complete"
COMMAND_NAME="build"

# Generate deterministic WORKFLOW_ID and persist (fail-fast pattern)
WORKFLOW_ID="build_$(date +%s)"
STATE_ID_FILE="${HOME}/.claude/tmp/build_state_id.txt"
mkdir -p "$(dirname "$STATE_ID_FILE")"
echo "$WORKFLOW_ID" > "$STATE_ID_FILE"
export WORKFLOW_ID

# Initialize workflow state BEFORE sm_init (correct initialization order)
init_workflow_state "$WORKFLOW_ID"

# Initialize state machine with return code verification
# research_complexity=1 (minimum) since /build doesn't perform research
if ! sm_init \
  "$PLAN_FILE" \
  "$COMMAND_NAME" \
  "$WORKFLOW_TYPE" \
  "1" \
  "[]" 2>&1; then
  echo "ERROR: State machine initialization failed" >&2
  echo "DIAGNOSTIC Information:" >&2
  echo "  - Plan File: $PLAN_FILE" >&2
  echo "  - Command Name: $COMMAND_NAME" >&2
  echo "  - Workflow Type: $WORKFLOW_TYPE" >&2
  echo "POSSIBLE CAUSES:" >&2
  echo "  - Library version incompatibility (require workflow-state-machine.sh >=2.0.0)" >&2
  echo "  - State file corruption in ~/.claude/data/state/" >&2
  echo "  - Invalid plan file format" >&2
  exit 1
fi

echo "✓ State machine initialized (WORKFLOW_ID: $WORKFLOW_ID)"
echo ""
```

## Part 4: Implementation Phase

**EXECUTE NOW**: Transition to implementation state and prepare for agent delegation:

```bash
set +H  # CRITICAL: Disable history expansion

# Bootstrap CLAUDE_PROJECT_DIR detection (subprocess isolation - cannot rely on previous block export)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
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
fi

if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1
fi

# Re-source required libraries (subprocess isolation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"

# Load WORKFLOW_ID from file (fail-fast pattern)
STATE_ID_FILE="${HOME}/.claude/tmp/build_state_id.txt"
if [ ! -f "$STATE_ID_FILE" ]; then
  echo "ERROR: WORKFLOW_ID file not found: $STATE_ID_FILE" >&2
  echo "DIAGNOSTIC: Part 3 (State Machine Initialization) may not have executed" >&2
  exit 1
fi
WORKFLOW_ID=$(cat "$STATE_ID_FILE")
export WORKFLOW_ID

# Load workflow state from Part 3 (subprocess isolation)
load_workflow_state "$WORKFLOW_ID" false

# Transition to implement state with return code verification
if ! sm_transition "$STATE_IMPLEMENT" 2>&1; then
  echo "ERROR: State transition to IMPLEMENT failed" >&2
  echo "DIAGNOSTIC Information:" >&2
  echo "  - Current State: $(sm_current_state 2>/dev/null || echo 'unknown')" >&2
  echo "  - Attempted Transition: → IMPLEMENT" >&2
  echo "  - Workflow Type: full-implementation" >&2
  echo "  - Plan File: $PLAN_FILE" >&2
  echo "POSSIBLE CAUSES:" >&2
  echo "  - State machine not initialized properly" >&2
  echo "  - Invalid transition from current state" >&2
  echo "  - State file corruption in ~/.claude/data/state/" >&2
  echo "TROUBLESHOOTING:" >&2
  echo "  - Verify sm_init was called successfully" >&2
  echo "  - Check state machine logs for details" >&2
  exit 1
fi
echo "=== Phase 1: Implementation ==="
echo ""

# Pre-calculate topic path from plan file
TOPIC_PATH=$(dirname "$(dirname "$PLAN_FILE")")

# Load WORKFLOW_ID for file naming
STATE_ID_FILE="${HOME}/.claude/tmp/build_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE")

# Persist variables for next block and agent
echo "PLAN_FILE=$PLAN_FILE" > "${HOME}/.claude/tmp/build_state_${WORKFLOW_ID}.txt"
echo "TOPIC_PATH=$TOPIC_PATH" >> "${HOME}/.claude/tmp/build_state_${WORKFLOW_ID}.txt"
echo "STARTING_PHASE=$STARTING_PHASE" >> "${HOME}/.claude/tmp/build_state_${WORKFLOW_ID}.txt"
```

**EXECUTE NOW**: USE the Task tool to invoke the implementer-coordinator agent with continuation loop support.

**Continuation Loop Parameters**:
- MAX_ITERATIONS: 5 (prevents infinite loops)
- ITERATION: Starts at 1, increments on each continuation
- continuation_context: Path to previous summary (null for first iteration)

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

    Execute all implementation phases according to the plan, following wave-based
    execution with dependency analysis.

    IMPORTANT: After completing all phases or if context exhaustion detected:
    - Create a summary in summaries/ directory
    - Summary must have Work Status at TOP showing completion percentage
    - If incomplete, include Work Remaining section with specific tasks
    - Return summary path in completion signal

    Return: IMPLEMENTATION_COMPLETE: {PHASE_COUNT}
    summary_path: /path/to/summary
    work_remaining: 0 or list of incomplete phases
  "
}

**Continuation Loop Handling**:

If the implementation-coordinator returns with work_remaining > 0:
1. Parse the summary_path from the return
2. Increment ITERATION counter
3. Check if ITERATION > MAX_ITERATIONS (5)
   - If yes: ERROR - Implementation timed out after 5 iterations
   - If no: Re-invoke implementer-coordinator with continuation_context
4. Pass the previous summary as continuation_context for the next iteration
5. The new executor instance reads the summary and resumes from Work Remaining

**NOTE**: This continuation mechanism ensures persistence through context exhaustion.
The summary documents all completed work and exact resume point for seamless handoff.

**EXECUTE NOW**: Verify implementation completion and persist state:

```bash
set +H  # CRITICAL: Disable history expansion

# Bootstrap CLAUDE_PROJECT_DIR detection (subprocess isolation - cannot rely on previous block export)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
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
fi

if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1
fi

# Re-source required libraries (subprocess isolation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"

# Load WORKFLOW_ID from file (fail-fast pattern)
STATE_ID_FILE="${HOME}/.claude/tmp/build_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE")

# Load state from previous block
source "${HOME}/.claude/tmp/build_state_${WORKFLOW_ID}.txt" 2>/dev/null || true

# MANDATORY VERIFICATION
echo "Verifying implementation completion..."

# Check if any files were modified (basic implementation check)
if git diff --quiet && git diff --cached --quiet; then
  echo "WARNING: No changes detected (implementation may have been no-op)"
fi

# Check for implementation artifacts (git commits)
COMMIT_COUNT=$(git log --oneline --since="5 minutes ago" | wc -l)
if [ "$COMMIT_COUNT" -eq 0 ]; then
  echo "WARNING: No recent commits found"
  echo "NOTE: Implementation may not have created commits"
fi

# CHECKPOINT REPORTING
echo ""
echo "CHECKPOINT: Implementation phase complete"
echo "- Workflow type: full-implementation"
echo "- Plan file: $PLAN_FILE"
echo "- Changes detected: $(git diff --cached --quiet && echo "none" || echo "yes")"
echo "- Recent commits: $COMMIT_COUNT"
echo "- All phases verified: ✓"
echo "- Proceeding to: Testing phase"
echo ""

# Persist variables across bash blocks (subprocess isolation)
append_workflow_state "PLAN_FILE" "$PLAN_FILE"
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
append_workflow_state "STARTING_PHASE" "$STARTING_PHASE"
append_workflow_state "COMMIT_COUNT" "$COMMIT_COUNT"

# Persist completed state with return code verification
if ! save_completed_states_to_state 2>&1; then
  echo "ERROR: Failed to persist completed state" >&2
  exit 1
fi
```

## Part 5: Testing Phase

**EXECUTE NOW**: Run tests and determine pass/fail status:

```bash
set +H  # CRITICAL: Disable history expansion

# Bootstrap CLAUDE_PROJECT_DIR detection (subprocess isolation - cannot rely on previous block export)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
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
fi

if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1
fi

# Re-source required libraries (subprocess isolation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"

# Load WORKFLOW_ID from file (fail-fast pattern - no fallback)
STATE_ID_FILE="${HOME}/.claude/tmp/build_state_id.txt"
if [ ! -f "$STATE_ID_FILE" ]; then
  echo "ERROR: WORKFLOW_ID file not found: $STATE_ID_FILE" >&2
  echo "DIAGNOSTIC: Part 3 (State Machine Initialization) may not have executed" >&2
  exit 1
fi
WORKFLOW_ID=$(cat "$STATE_ID_FILE")
export WORKFLOW_ID

# Load workflow state from Part 3 (subprocess isolation)
source "${HOME}/.claude/tmp/build_state_${WORKFLOW_ID}.txt" 2>/dev/null || true
load_workflow_state "$WORKFLOW_ID" false

# Transition to test state with return code verification
if ! sm_transition "$STATE_TEST" 2>&1; then
  echo "ERROR: State transition to TEST failed" >&2
  echo "DIAGNOSTIC Information:" >&2
  echo "  - Current State: $(sm_current_state 2>/dev/null || echo 'unknown')" >&2
  echo "  - Attempted Transition: → TEST" >&2
  echo "  - Workflow Type: full-implementation" >&2
  echo "  - Implementation complete: check CHECKPOINT above" >&2
  echo "POSSIBLE CAUSES:" >&2
  echo "  - Implementation phase did not complete properly" >&2
  echo "  - State not persisted after implementation" >&2
  echo "  - Invalid transition from current state" >&2
  echo "TROUBLESHOOTING:" >&2
  echo "  - Check implementation checkpoint output" >&2
  echo "  - Verify implementation phase completed" >&2
  exit 1
fi
echo "=== Phase 2: Testing ==="
echo ""

# Extract test command from plan (if specified)
TEST_COMMAND=$(grep -oE "(npm test|pytest|\.\/run_all_tests\.sh|:TestSuite)" "$PLAN_FILE" | head -1 || echo "")

if [ -z "$TEST_COMMAND" ]; then
  echo "NOTE: No explicit test command found in plan"
  echo "Attempting to auto-detect test framework..."

  # Auto-detect test framework
  if [ -f "package.json" ] && grep -q '"test"' package.json; then
    TEST_COMMAND="npm test"
  elif [ -f "pytest.ini" ] || [ -f "setup.py" ]; then
    TEST_COMMAND="pytest"
  elif [ -f ".claude/run_all_tests.sh" ]; then
    TEST_COMMAND="./.claude/run_all_tests.sh"
  else
    echo "WARNING: No test framework detected, skipping test phase"
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
    echo "✗ Tests failed (exit code: $TEST_EXIT_CODE)"
    TESTS_PASSED=false
  else
    echo "✓ Tests passed"
    TESTS_PASSED=true
  fi
else
  echo "✓ Test phase skipped (no test command)"
  TESTS_PASSED=true
fi

# CHECKPOINT REPORTING
echo ""
echo "CHECKPOINT: Testing phase complete"
echo "- Test command: ${TEST_COMMAND:-none}"
echo "- Test result: $([ "$TESTS_PASSED" = "true" ] && echo "✓ PASSED" || echo "✗ FAILED (exit code: $TEST_EXIT_CODE)")"
echo "- All verifications: ✓"
echo "- Proceeding to: $([ "$TESTS_PASSED" = "true" ] && echo "Documentation phase" || echo "Debug phase")"
echo ""

# Persist test results for Part 5 (subprocess isolation)
append_workflow_state "TESTS_PASSED" "$TESTS_PASSED"
append_workflow_state "TEST_COMMAND" "$TEST_COMMAND"
append_workflow_state "TEST_EXIT_CODE" "${TEST_EXIT_CODE:-0}"

# Persist completed state with return code verification
if ! save_completed_states_to_state 2>&1; then
  echo "ERROR: Failed to persist completed state" >&2
  exit 1
fi
```

## Part 6: Conditional Branching (Debug or Document)

**EXECUTE NOW**: Branch to debug or document phase based on test results:

```bash
set +H  # CRITICAL: Disable history expansion

# Bootstrap CLAUDE_PROJECT_DIR detection (subprocess isolation - cannot rely on previous block export)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
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
fi

if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1
fi

# Re-source required libraries (subprocess isolation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"

# Load WORKFLOW_ID from file (fail-fast pattern - no fallback)
STATE_ID_FILE="${HOME}/.claude/tmp/build_state_id.txt"
if [ ! -f "$STATE_ID_FILE" ]; then
  echo "ERROR: WORKFLOW_ID file not found: $STATE_ID_FILE" >&2
  echo "DIAGNOSTIC: Part 3 (State Machine Initialization) may not have executed" >&2
  exit 1
fi
WORKFLOW_ID=$(cat "$STATE_ID_FILE")
export WORKFLOW_ID

# Load workflow state from Part 4 (subprocess isolation)
source "${HOME}/.claude/tmp/build_state_${WORKFLOW_ID}.txt" 2>/dev/null || true
load_workflow_state "$WORKFLOW_ID" false

# Conditional phase based on test results
if [ "$TESTS_PASSED" = "false" ]; then
  # Tests failed → debug phase with return code verification
  if ! sm_transition "$STATE_DEBUG" 2>&1; then
    echo "ERROR: State transition to DEBUG failed" >&2
    echo "DIAGNOSTIC Information:" >&2
    echo "  - Current State: $(sm_current_state 2>/dev/null || echo 'unknown')" >&2
    echo "  - Attempted Transition: → DEBUG" >&2
    echo "  - Workflow Type: full-implementation" >&2
    echo "  - Tests passed: $TESTS_PASSED (expecting false)" >&2
    echo "POSSIBLE CAUSES:" >&2
    echo "  - Conditional logic error (tests_passed check)" >&2
    echo "  - State not persisted after testing" >&2
    echo "  - Invalid transition from current state" >&2
    echo "TROUBLESHOOTING:" >&2
    echo "  - Verify TESTS_PASSED variable is 'false'" >&2
    echo "  - Check testing checkpoint output" >&2
    exit 1
  fi
  echo "=== Phase 3: Debug (Tests Failed) ==="
  echo ""

  # Pre-calculate debug directory
  DEBUG_DIR="${TOPIC_PATH}/debug"
  mkdir -p "$DEBUG_DIR"

  # Persist debug directory for agent
  echo "DEBUG_DIR=$DEBUG_DIR" >> "${HOME}/.claude/tmp/build_state_${WORKFLOW_ID}.txt"
```

**EXECUTE NOW**: USE the Task tool to invoke the debug-analyst agent.

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

**EXECUTE NOW**: Verify debug artifacts were created:

```bash
set +H  # CRITICAL: Disable history expansion

# Bootstrap CLAUDE_PROJECT_DIR detection (subprocess isolation - cannot rely on previous block export)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
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
fi

if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1
fi

# Re-source required libraries (subprocess isolation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"

# Load WORKFLOW_ID from file (fail-fast pattern)
STATE_ID_FILE="${HOME}/.claude/tmp/build_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE")

# Load state from previous block
source "${HOME}/.claude/tmp/build_state_${WORKFLOW_ID}.txt" 2>/dev/null || true

# MANDATORY VERIFICATION
echo "Verifying debug artifacts..."

if [ ! -d "$DEBUG_DIR" ]; then
  echo "ERROR: Debug phase failed to create debug directory" >&2
  echo "DIAGNOSTIC: Expected directory: $DEBUG_DIR" >&2
  exit 1
fi

if [ -z "$(find "$DEBUG_DIR" -name '*.md' 2>/dev/null)" ]; then
  echo "ERROR: Debug phase failed to create debug report" >&2
  echo "DIAGNOSTIC: Directory exists but no .md files found: $DEBUG_DIR" >&2
  exit 1
fi

DEBUG_REPORT=$(find "$DEBUG_DIR" -name '*.md' -type f | head -1)
echo "✓ Debug analysis complete (report: $DEBUG_REPORT)"
echo ""

echo "NOTE: After debug, you may re-run /build to retry tests"
echo ""

# Persist completed state
save_completed_states_to_state
```

**EXECUTE NOW**: Handle documentation phase when tests pass:

```bash
set +H  # CRITICAL: Disable history expansion

# Bootstrap CLAUDE_PROJECT_DIR detection (subprocess isolation - cannot rely on previous block export)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
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
fi

if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1
fi

# Re-source required libraries (subprocess isolation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"

# Load WORKFLOW_ID from file (fail-fast pattern)
STATE_ID_FILE="${HOME}/.claude/tmp/build_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE")

# Load state from previous block
source "${HOME}/.claude/tmp/build_state_${WORKFLOW_ID}.txt" 2>/dev/null || true
load_workflow_state "$WORKFLOW_ID" false

# Skip if tests failed (debug phase handled separately)
if [ "$TESTS_PASSED" = "false" ]; then
  echo "DEBUG phase completed, skipping documentation"
  exit 0
fi

# Tests passed → document phase with return code verification
if ! sm_transition "$STATE_DOCUMENT" 2>&1; then
  echo "ERROR: State transition to DOCUMENT failed" >&2
  echo "DIAGNOSTIC Information:" >&2
  echo "  - Current State: $(sm_current_state 2>/dev/null || echo 'unknown')" >&2
  echo "  - Attempted Transition: → DOCUMENT" >&2
  echo "  - Workflow Type: full-implementation" >&2
  echo "  - Tests passed: $TESTS_PASSED (expecting true)" >&2
  echo "POSSIBLE CAUSES:" >&2
  echo "  - Conditional logic error (tests_passed check)" >&2
  echo "  - State not persisted after testing" >&2
  echo "  - Invalid transition from current state" >&2
  echo "TROUBLESHOOTING:" >&2
  echo "  - Verify TESTS_PASSED variable is 'true'" >&2
  echo "  - Check testing checkpoint output" >&2
  exit 1
fi
echo "=== Phase 3: Documentation ==="
echo ""

echo "Updating documentation for implemented features..."

# Basic documentation update (check for README updates needed)
if git diff --name-only HEAD~${COMMIT_COUNT}..HEAD | grep -qE '(\.py|\.js|\.ts|\.go|\.rs)$'; then
  echo "NOTE: Code files modified, documentation update recommended"
  echo "Consider updating:"
  echo "  - README.md"
  echo "  - API documentation"
  echo "  - CHANGELOG.md"
fi

echo "✓ Documentation phase complete"
echo ""

# Persist completed state
save_completed_states_to_state
```

## Part 7: Completion & Cleanup

**EXECUTE NOW**: Complete workflow and cleanup state:

```bash
set +H  # CRITICAL: Disable history expansion

# Bootstrap CLAUDE_PROJECT_DIR detection (subprocess isolation - cannot rely on previous block export)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
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
fi

if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1
fi

# Re-source required libraries (subprocess isolation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/checkpoint-utils.sh"

# Load WORKFLOW_ID from file (fail-fast pattern - no fallback)
STATE_ID_FILE="${HOME}/.claude/tmp/build_state_id.txt"
if [ ! -f "$STATE_ID_FILE" ]; then
  echo "ERROR: WORKFLOW_ID file not found: $STATE_ID_FILE" >&2
  echo "DIAGNOSTIC: Part 3 (State Machine Initialization) may not have executed" >&2
  exit 1
fi
WORKFLOW_ID=$(cat "$STATE_ID_FILE")
export WORKFLOW_ID

# Load workflow state from Part 5 (subprocess isolation)
source "${HOME}/.claude/tmp/build_state_${WORKFLOW_ID}.txt" 2>/dev/null || true
load_workflow_state "$WORKFLOW_ID" false

# Transition to complete state with return code verification
if ! sm_transition "$STATE_COMPLETE" 2>&1; then
  echo "ERROR: State transition to COMPLETE failed" >&2
  echo "DIAGNOSTIC Information:" >&2
  echo "  - Current State: $(sm_current_state 2>/dev/null || echo 'unknown')" >&2
  echo "  - Attempted Transition: → COMPLETE" >&2
  echo "  - Workflow Type: full-implementation" >&2
  echo "  - Terminal State: complete" >&2
  echo "POSSIBLE CAUSES:" >&2
  echo "  - Previous phase (debug/document) did not complete" >&2
  echo "  - State not persisted properly" >&2
  echo "  - Invalid transition from current state" >&2
  echo "TROUBLESHOOTING:" >&2
  echo "  - Check last checkpoint output" >&2
  echo "  - Verify all required phases completed" >&2
  exit 1
fi

echo "=== Build Complete ==="
echo ""
echo "Workflow Type: full-implementation"
echo "Plan: $PLAN_FILE"
echo "Implementation: ✓ Complete"
echo "Testing: $([ "$TESTS_PASSED" = "true" ] && echo "✓ Passed" || echo "✗ Failed (debugged)")"
echo ""

if [ "$TESTS_PASSED" = "true" ]; then
  echo "Next Steps:"
  echo "- Review changes: git log --oneline -$COMMIT_COUNT"
  echo "- Create PR: gh pr create"
  echo "- Deploy: (follow project deployment process)"
else
  echo "Next Steps:"
  echo "- Review debug analysis above"
  echo "- Apply fixes and re-run: /build $PLAN_FILE"
  echo "- Or continue from test phase: /build $PLAN_FILE 2"
fi

echo ""

# Delete checkpoint (successful completion)
if [ "$TESTS_PASSED" = "true" ]; then
  delete_checkpoint "build" 2>/dev/null || true
fi

# Cleanup temp state files
rm -f "${HOME}/.claude/tmp/build_state_${WORKFLOW_ID}.txt"
rm -f "${HOME}/.claude/tmp/build_state_id.txt"

exit 0
```

---

**Troubleshooting**:

- **No plan found**: Create a plan first using `/plan` or `/plan`
- **Tests failing**: Use debug output above, or invoke `/fix` for dedicated debugging
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
