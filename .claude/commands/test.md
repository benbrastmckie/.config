---
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob
argument-hint: [plan-file] [--file <summary>] [--coverage-threshold=N] [--max-iterations=N]
description: Test and debug workflow - Execute test suite with coverage loop
command-type: primary
dependent-agents:
  - test-executor
  - debug-analyst
library-requirements:
  - workflow-state-machine.sh: ">=2.0.0"
  - state-persistence.sh: ">=1.5.0"
documentation: See .claude/docs/guides/commands/test-command-guide.md for complete usage guide
---

# /test - Test Execution and Debug Workflow Command

YOU ARE EXECUTING a test-and-debug workflow that takes test files (written by /implement) and executes them with a coverage loop until quality threshold is met.

**Workflow Type**: test-and-debug
**Terminal State**: complete
**Expected Input**: Plan file path OR summary file path (via --file)
**Expected Output**: Test results with coverage metrics, optional debug reports

## Block 1: Test Phase Setup and Summary Discovery

**EXECUTE NOW**: The user invoked `/test [plan-file] [--file <summary>] [--coverage-threshold=N] [--max-iterations=N]`. This block captures arguments, discovers or loads implementation summary, and initializes workflow state.

In the **bash block below**, replace `YOUR_TEST_ARGS_HERE` with the actual test arguments.

**Examples**:
- If user ran `/test plan.md --coverage-threshold 90`, change to: `echo "plan.md --coverage-threshold 90" > "$TEMP_FILE"`
- If user ran `/test --file summary.md`, change to: `echo "--file summary.md" > "$TEMP_FILE"`

```bash
# === PREPROCESSING SAFETY ===
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e

# === PRE-TRAP ERROR BUFFER ===
declare -a _EARLY_ERROR_BUFFER=()

# DEBUG_LOG initialization
DEBUG_LOG="${HOME}/.claude/tmp/workflow_debug.log"
mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null

# === CAPTURE TEST ARGUMENTS ===
TEMP_FILE="${HOME}/.claude/tmp/test_arg_$(date +%s%N).txt"
PATH_FILE="${HOME}/.claude/tmp/test_arg_path.txt"

# USER ACTION REQUIRED: Replace YOUR_TEST_ARGS_HERE with actual arguments
echo "YOUR_TEST_ARGS_HERE" > "$TEMP_FILE"
echo "$TEMP_FILE" > "$PATH_FILE"

# Checkpoint: Argument file created
ls -lh "$TEMP_FILE"
```

**EXECUTE NOW**: Load arguments, source libraries, discover summary, initialize state machine, and prepare for test execution.

```bash
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e

# === ARGUMENT RECOVERY ===
PATH_FILE="${HOME}/.claude/tmp/test_arg_path.txt"
TEMP_FILE=$(cat "$PATH_FILE" 2>/dev/null || echo "")

if [ -z "$TEMP_FILE" ] || [ ! -f "$TEMP_FILE" ]; then
  echo "ERROR: Cannot recover argument file. Re-invoke /test with arguments." >&2
  exit 1
fi

TEST_ARGS=$(cat "$TEMP_FILE")

# === THREE-TIER LIBRARY SOURCING (MANDATORY) ===
# Tier 1: error-handling.sh (foundational error logging)
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-${HOME}/.config}"
CLAUDE_LIB="${CLAUDE_PROJECT_DIR}/.claude/lib"

source "${CLAUDE_LIB}/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Cannot load error-handling library from ${CLAUDE_LIB}/core/error-handling.sh" >&2
  exit 1
}

# Tier 2: state-persistence.sh (state management)
source "${CLAUDE_LIB}/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Cannot load state-persistence library" >&2
  exit 1
}

# Tier 2.5: unified-location-detection.sh (artifact directory management)
source "${CLAUDE_LIB}/core/unified-location-detection.sh" 2>/dev/null || {
  echo "ERROR: Cannot load unified-location-detection library" >&2
  exit 1
}

# Tier 3: workflow-state-machine.sh (workflow orchestration)
source "${CLAUDE_LIB}/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Cannot load workflow-state-machine library" >&2
  exit 1
}

# === ERROR LOGGING INITIALIZATION ===
ensure_error_log_exists
setup_bash_error_trap

# Set workflow metadata for error logging
COMMAND_NAME="/test"
WORKFLOW_ID="test_$(date +%s)"
USER_ARGS="$TEST_ARGS"

# === PRE-FLIGHT VALIDATION ===
# Verify critical functions available
REQUIRED_FUNCTIONS=(
  "sm_init"
  "sm_transition"
  "append_workflow_state"
  "load_workflow_state"
  "ensure_artifact_directory"
  "log_command_error"
)

for func in "${REQUIRED_FUNCTIONS[@]}"; do
  if ! declare -f "$func" >/dev/null 2>&1; then
    log_command_error "validation_error" \
      "Required function $func not available" \
      "Library sourcing may have failed"
    exit 1
  fi
done

# === ARGUMENT PARSING ===
PLAN_FILE=""
SUMMARY_FILE=""
COVERAGE_THRESHOLD=80
MAX_TEST_ITERATIONS=5
TEST_CONTEXT="unknown"

# Parse --file flag for explicit summary path
if [[ "$TEST_ARGS" =~ --file[[:space:]]+([^[:space:]]+) ]]; then
  SUMMARY_FILE="${BASH_REMATCH[1]}"

  # Validate summary file exists
  if [ ! -f "$SUMMARY_FILE" ]; then
    log_command_error "validation_error" \
      "Summary file not found" \
      "Path: $SUMMARY_FILE"
    echo "ERROR: Summary file not found: $SUMMARY_FILE" >&2
    exit 1
  fi

  # Extract PLAN_FILE from summary metadata
  PLAN_FILE=$(grep "^- \*\*Plan\*\*:" "$SUMMARY_FILE" 2>/dev/null | sed 's/.*: //' || echo "")

  if [ -z "$PLAN_FILE" ]; then
    log_command_error "parse_error" \
      "Cannot extract plan path from summary" \
      "Summary: $SUMMARY_FILE"
    echo "ERROR: Cannot extract plan path from summary metadata" >&2
    exit 1
  fi

  TEST_CONTEXT="summary"
fi

# Parse positional plan file argument if --file not provided
if [ -z "$SUMMARY_FILE" ]; then
  PLAN_FILE=$(echo "$TEST_ARGS" | grep -oE '[^[:space:]]+\.md' | head -1)

  if [ -z "$PLAN_FILE" ]; then
    log_command_error "validation_error" \
      "No plan file or summary file provided" \
      "Usage: /test plan.md [--file summary.md] [--coverage-threshold N] [--max-iterations N]"
    echo "ERROR: No plan file or summary file provided" >&2
    echo "Usage: /test plan.md [--file summary.md] [--coverage-threshold N] [--max-iterations N]" >&2
    exit 1
  fi
fi

# Parse --coverage-threshold flag
if [[ "$TEST_ARGS" =~ --coverage-threshold[=[:space:]]+([0-9]+) ]]; then
  COVERAGE_THRESHOLD="${BASH_REMATCH[1]}"
fi

# Parse --max-iterations flag
if [[ "$TEST_ARGS" =~ --max-iterations[=[:space:]]+([0-9]+) ]]; then
  MAX_TEST_ITERATIONS="${BASH_REMATCH[1]}"
fi

# === PLAN FILE VALIDATION ===
# Make plan file absolute if relative
result=0
[[ "$PLAN_FILE" =~ ^/ ]] || result=1
if [ "$result" -eq 0 ]; then
  : # Already absolute, continue
else
  PLAN_FILE="$(pwd)/$PLAN_FILE"
fi

# Validate plan file exists
if [ ! -f "$PLAN_FILE" ]; then
  log_command_error "validation_error" \
    "Plan file not found" \
    "Path: $PLAN_FILE"
  echo "ERROR: Plan file not found: $PLAN_FILE" >&2
  exit 1
fi

# === TOPIC PATH DERIVATION ===
# Topic path is parent of plan directory
TOPIC_PATH=$(dirname "$(dirname "$PLAN_FILE")")
SUMMARIES_DIR="${TOPIC_PATH}/summaries"
OUTPUTS_DIR="${TOPIC_PATH}/outputs"
DEBUG_DIR="${TOPIC_PATH}/debug"

# === SUMMARY AUTO-DISCOVERY ===
if [ -z "$SUMMARY_FILE" ] && [ -d "$SUMMARIES_DIR" ]; then
  # Find latest summary by modification time
  LATEST_SUMMARY=$(find "$SUMMARIES_DIR" -name "*.md" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)

  if [ -n "$LATEST_SUMMARY" ]; then
    SUMMARY_FILE="$LATEST_SUMMARY"
    TEST_CONTEXT="auto-discovered"
  else
    echo "WARNING: No summary found in $SUMMARIES_DIR (proceeding without summary context)"
    TEST_CONTEXT="no-summary"
  fi
fi

# === TESTING STRATEGY PARSING (FROM SUMMARY) ===
# Extract test execution requirements from summary Testing Strategy section
TEST_FILES=""
TEST_COMMAND=""
EXPECTED_TESTS=""

if [ -n "$SUMMARY_FILE" ] && [ -f "$SUMMARY_FILE" ]; then
  # Check if summary has Testing Strategy section
  if grep -q "^## Testing Strategy" "$SUMMARY_FILE" 2>/dev/null; then
    # Extract test files (paths to test scripts/suites)
    TEST_FILES=$(sed -n '/^## Testing Strategy/,/^## /p' "$SUMMARY_FILE" | grep -E "^- \*\*Test Files\*\*:" | sed 's/.*: //' || echo "")

    # Extract test command
    TEST_COMMAND=$(sed -n '/^## Testing Strategy/,/^## /p' "$SUMMARY_FILE" | grep -E "^- \*\*Test Execution Requirements\*\*:" | sed 's/.*: //' || echo "")

    # Extract expected test count
    EXPECTED_TESTS=$(sed -n '/^## Testing Strategy/,/^## /p' "$SUMMARY_FILE" | grep -E "^- \*\*Expected Tests\*\*:" | sed 's/.*: //' || echo "")

    if [ -n "$TEST_FILES" ] && [ -n "$TEST_COMMAND" ]; then
      echo "INFO: Testing Strategy found in summary"
      echo "  Test Files: $TEST_FILES"
      echo "  Test Command: $TEST_COMMAND"
      echo "  Expected Tests: ${EXPECTED_TESTS:-N/A}"
    else
      echo "WARNING: Testing Strategy section incomplete in summary"
    fi
  else
    echo "WARNING: No Testing Strategy section in summary (tests may need manual discovery)"
  fi
fi

# === STATE FILE LOADING (OPTIONAL) ===
STATE_FILE="${TOPIC_PATH}/.state/implement_state.sh"

if [ -f "$STATE_FILE" ]; then
  # Load implementation state if available
  source "$STATE_FILE" 2>/dev/null || {
    echo "WARNING: Failed to load implementation state from $STATE_FILE"
  }
else
  echo "INFO: No implementation state file found (not required, continuing)"
fi

# === ARTIFACT DIRECTORIES ===
ensure_artifact_directory "$OUTPUTS_DIR"
ensure_artifact_directory "$DEBUG_DIR"

# === WORKFLOW STATE INITIALIZATION ===
# Initialize state file before sm_init (required for append_workflow_state)
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")

# === STATE MACHINE INITIALIZATION ===
sm_init \
  "Test execution for $(basename "$PLAN_FILE")" \
  "/test" \
  "test-and-debug" \
  "2" \
  "[]" \
  2>/dev/null || {
    log_command_error "state_error" \
      "State machine initialization failed" \
      "Plan: $PLAN_FILE, Type: test-and-debug"
    exit 1
  }

# Verify terminal state set correctly
if [ "$TERMINAL_STATE" != "complete" ]; then
  log_command_error "state_error" \
    "Terminal state incorrect" \
    "Expected: complete, Got: $TERMINAL_STATE"
  exit 1
fi

# === STATE TRANSITIONS (VALID PATH: initialize -> implement -> test) ===
# Transition to implement (test discovery phase)
sm_transition "$STATE_IMPLEMENT" "entering implement phase for test discovery" 2>/dev/null || {
  log_command_error "state_error" \
    "State transition to IMPLEMENT failed" \
    "Current state: $(sm_get_state)"
  exit 1
}

# Now transition to test
sm_transition "$STATE_TEST" "starting test execution phase" 2>/dev/null || {
  log_command_error "state_error" \
    "State transition to TEST failed" \
    "Current state: $(sm_get_state)"
  exit 1
}

# === ITERATION INITIALIZATION ===
ITERATION=1
PREVIOUS_COVERAGE=0
STUCK_COUNT=0

# === STATE PERSISTENCE ===
# STATE_FILE already initialized by init_workflow_state above

append_workflow_state "PLAN_FILE" "$PLAN_FILE"
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
append_workflow_state "SUMMARY_FILE" "${SUMMARY_FILE:-none}"
append_workflow_state "TEST_CONTEXT" "$TEST_CONTEXT"
append_workflow_state "COVERAGE_THRESHOLD" "$COVERAGE_THRESHOLD"
append_workflow_state "MAX_TEST_ITERATIONS" "$MAX_TEST_ITERATIONS"
append_workflow_state "ITERATION" "$ITERATION"
append_workflow_state "PREVIOUS_COVERAGE" "$PREVIOUS_COVERAGE"
append_workflow_state "STUCK_COUNT" "$STUCK_COUNT"
append_workflow_state "TEST_FILES" "${TEST_FILES:-}"
append_workflow_state "TEST_COMMAND" "${TEST_COMMAND:-}"
append_workflow_state "EXPECTED_TESTS" "${EXPECTED_TESTS:-}"

# Checkpoint: Setup complete
echo "Test phase initialized: plan=$PLAN_FILE, summary=$TEST_CONTEXT, threshold=${COVERAGE_THRESHOLD}%, max_iterations=$MAX_TEST_ITERATIONS"
```

## Block 2: Test Path Pre-Calculation (Hard Barrier Setup)

**EXECUTE NOW**: Calculate test output path for current iteration, validate path is absolute, and persist to state.

```bash
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e

# === THREE-TIER LIBRARY SOURCING ===
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-${HOME}/.config}"
CLAUDE_LIB="${CLAUDE_PROJECT_DIR}/.claude/lib"

source "${CLAUDE_LIB}/core/error-handling.sh" 2>/dev/null || { echo "ERROR: Cannot load error-handling library" >&2; exit 1; }
source "${CLAUDE_LIB}/core/state-persistence.sh" 2>/dev/null || { echo "ERROR: Cannot load state-persistence library" >&2; exit 1; }
source "${CLAUDE_LIB}/workflow/workflow-state-machine.sh" 2>/dev/null || { echo "ERROR: Cannot load workflow-state-machine library" >&2; exit 1; }

setup_bash_error_trap

# === STATE RESTORATION ===
# Load workflow state using standard pattern
# Find most recent test workflow state file
WORKFLOW_ID=$(ls -t "${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_test_"*.sh 2>/dev/null | head -1 | sed 's/.*workflow_\(.*\)\.sh/\1/')

if [ -z "$WORKFLOW_ID" ]; then
  echo "ERROR: Cannot find workflow state file for test command" >&2
  exit 1
fi

load_workflow_state "$WORKFLOW_ID" false PLAN_FILE TOPIC_PATH ITERATION || {
  echo "ERROR: Failed to load workflow state" >&2
  exit 1
}

# === TEST OUTPUT PATH CALCULATION ===
TIMESTAMP=$(date +%s)
TEST_OUTPUT_PATH="${OUTPUTS_DIR}/test_results_iter${ITERATION}_${TIMESTAMP}.md"

# === PATH VALIDATION ===
# Verify path is absolute
result=0
[[ "$TEST_OUTPUT_PATH" =~ ^/ ]] || result=1

if [ "$result" -ne 0 ]; then
  log_command_error "validation_error" \
    "Test output path not absolute" \
    "Path: $TEST_OUTPUT_PATH"
  echo "ERROR: Test output path must be absolute: $TEST_OUTPUT_PATH" >&2
  exit 1
fi

# === STATE PERSISTENCE ===
append_workflow_state "TEST_OUTPUT_PATH" "$TEST_OUTPUT_PATH"

# Checkpoint: Test path calculated
echo "Test iteration $ITERATION/$MAX_TEST_ITERATIONS: $TEST_OUTPUT_PATH"
```

## Block 3: Test Execution [CRITICAL BARRIER]

**EXECUTE NOW**: USE the Task tool to invoke the test-executor agent for test suite execution. This is a CRITICAL BARRIER: the agent MUST create the test output file at the pre-calculated path.

Task {
  subagent_type: "general-purpose"
  description: "Execute test suite with framework detection and structured reporting"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/test-executor.md

    You are executing the test execution phase for: test workflow

    **Input Contract (Hard Barrier Pattern)**:
    - plan_path: ${PLAN_FILE}
    - topic_path: ${TOPIC_PATH}
    - summary_file: ${SUMMARY_FILE:-none}
    - artifact_paths:
      - outputs: ${OUTPUTS_DIR}
      - debug: ${DEBUG_DIR}
    - test_config:
      - coverage_threshold: ${COVERAGE_THRESHOLD}
      - iteration: ${ITERATION}
      - max_iterations: ${MAX_TEST_ITERATIONS}
    - output_path: ${TEST_OUTPUT_PATH}

    **CRITICAL**: You MUST create test results file at: ${TEST_OUTPUT_PATH}

    Execute test suite, measure coverage, and analyze results.

    Return: TEST_COMPLETE: {STATUS}
    status: \"passed\" | \"failed\" | \"error\"
    framework: \"bash\" | \"pytest\" | etc
    test_command: \"bash test.sh\"
    tests_passed: N
    tests_failed: M
    coverage: N% (or \"N/A\")
    next_state: \"complete\" | \"debug\" | \"continue\"
    output_path: ${TEST_OUTPUT_PATH}
  "
}

**Note**: While Block 3 appears as instructional text, the actual test-executor agent invocation happens via Claude's Task tool during command execution. The test-executor agent will parse this contract and execute the test suite accordingly.

## Block 4: Test Verification and Loop Decision (Hard Barrier Verification)

**EXECUTE NOW**: Verify test output file exists (hard barrier check), parse test results, check loop exit conditions, and decide next action (success → complete, stuck/max → debug, continue → loop).

```bash
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e

# === THREE-TIER LIBRARY SOURCING ===
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-${HOME}/.config}"
CLAUDE_LIB="${CLAUDE_PROJECT_DIR}/.claude/lib"

source "${CLAUDE_LIB}/core/error-handling.sh" 2>/dev/null || { echo "ERROR: Cannot load error-handling library" >&2; exit 1; }
source "${CLAUDE_LIB}/core/state-persistence.sh" 2>/dev/null || { echo "ERROR: Cannot load state-persistence library" >&2; exit 1; }
source "${CLAUDE_LIB}/workflow/workflow-state-machine.sh" 2>/dev/null || { echo "ERROR: Cannot load workflow-state-machine library" >&2; exit 1; }

setup_bash_error_trap

# === STATE RESTORATION ===
# Find most recent test workflow state file
WORKFLOW_ID=$(ls -t "${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_test_"*.sh 2>/dev/null | head -1 | sed 's/.*workflow_\(.*\)\.sh/\1/')

if [ -z "$WORKFLOW_ID" ]; then
  echo "ERROR: Cannot find workflow state file for test command" >&2
  exit 1
fi

load_workflow_state "$WORKFLOW_ID" false TEST_OUTPUT_PATH COVERAGE_THRESHOLD ITERATION || {
  echo "ERROR: Failed to load workflow state" >&2
  exit 1
}

# === HARD BARRIER VERIFICATION ===
result=0
[ -f "$TEST_OUTPUT_PATH" ] || result=1

if [ "$result" -ne 0 ]; then
  log_command_error "agent_error" \
    "test-executor failed to create output file" \
    "Expected path: $TEST_OUTPUT_PATH"
  echo "ERROR: test-executor did not create test output file at $TEST_OUTPUT_PATH" >&2
  exit 1
fi

# === PARSE TEST RESULTS ===
# Extract from TEST_COMPLETE signal (from previous agent invocation)
# These variables should be set by agent return parsing

# Placeholder: In real execution, these come from agent return signal
# For now, parse from test output file as fallback

TESTS_PASSED=$(grep "^tests_passed:" "$TEST_OUTPUT_PATH" 2>/dev/null | cut -d: -f2 | tr -d ' ' || echo "0")
TESTS_FAILED=$(grep "^tests_failed:" "$TEST_OUTPUT_PATH" 2>/dev/null | cut -d: -f2 | tr -d ' ' || echo "0")
COVERAGE=$(grep "^coverage:" "$TEST_OUTPUT_PATH" 2>/dev/null | cut -d: -f2 | tr -d ' %' || echo "0")

# Handle N/A coverage
if [ "$COVERAGE" = "N/A" ]; then
  COVERAGE=0
else
  result=0
  [[ "$COVERAGE" =~ ^[0-9]+$ ]] || result=1
  if [ "$result" -eq 0 ]; then
    : # Valid numeric coverage, continue
  else
    COVERAGE=0
  fi
fi

# === CHECK SUCCESS CRITERIA ===
ALL_PASSED=false
result=0
[ "$TESTS_FAILED" -eq 0 ] || result=1
if [ "$result" -eq 0 ]; then
  ALL_PASSED=true
fi

COVERAGE_MET=false
result=0
[ "$COVERAGE" -ge "$COVERAGE_THRESHOLD" ] || result=1
if [ "$result" -eq 0 ]; then
  COVERAGE_MET=true
fi

# === CHECK PROGRESS ===
COVERAGE_DELTA=$((COVERAGE - PREVIOUS_COVERAGE))

if [ "$COVERAGE_DELTA" -le 0 ]; then
  STUCK_COUNT=$((STUCK_COUNT + 1))
else
  STUCK_COUNT=0
fi

# === LOOP DECISION LOGIC ===
NEXT_STATE="unknown"

# Exit Condition 1: Success (all passed AND coverage met)
if [ "$ALL_PASSED" = "true" ] && [ "$COVERAGE_MET" = "true" ]; then
  NEXT_STATE="complete"
  echo "SUCCESS: All tests passed with ${COVERAGE}% coverage after ${ITERATION} iteration(s)"

# Exit Condition 2: Stuck (no progress for 2 iterations)
elif [ "$STUCK_COUNT" -ge 2 ]; then
  NEXT_STATE="debug"
  echo "STUCK: Coverage loop stuck (no progress for 2 iterations). Final coverage: ${COVERAGE}%"

# Exit Condition 3: Max iterations reached
elif [ "$ITERATION" -ge "$MAX_TEST_ITERATIONS" ]; then
  NEXT_STATE="debug"
  echo "MAX_ITERATIONS: Max iterations ($MAX_TEST_ITERATIONS) reached. Final coverage: ${COVERAGE}%"

# Continue: Increment iteration and loop back
else
  NEXT_STATE="continue"
  ITERATION=$((ITERATION + 1))
  PREVIOUS_COVERAGE=$COVERAGE

  # Generate improvement hints (uncovered modules)
  IMPROVEMENT_HINTS="Iteration $ITERATION: Previous coverage ${PREVIOUS_COVERAGE}% → ${COVERAGE}%. Increase test coverage to reach ${COVERAGE_THRESHOLD}% threshold."

  echo "CONTINUE: Iteration $ITERATION/$MAX_TEST_ITERATIONS (coverage: ${COVERAGE}%, target: ${COVERAGE_THRESHOLD}%)"
fi

# === STATE PERSISTENCE ===
append_workflow_state "TEST_STATUS" "${ALL_PASSED}"
append_workflow_state "NEXT_STATE" "$NEXT_STATE"
append_workflow_state "ITERATION" "$ITERATION"
append_workflow_state "PREVIOUS_COVERAGE" "$PREVIOUS_COVERAGE"
append_workflow_state "STUCK_COUNT" "$STUCK_COUNT"
append_workflow_state "FINAL_COVERAGE" "$COVERAGE"
append_workflow_state "FINAL_TESTS_PASSED" "$TESTS_PASSED"
append_workflow_state "FINAL_TESTS_FAILED" "$TESTS_FAILED"

# === LOOP CONTROL ===
if [ "$NEXT_STATE" = "continue" ]; then
  # DESIGN NOTE: Coverage loop implementation
  # The current block-based architecture executes blocks sequentially.
  # For a true coverage loop, Blocks 2-4 would need to be consolidated into
  # a single block with a while loop structure.
  #
  # Current approach: Exit with signal indicating continuation needed.
  # User can re-invoke /test to continue iterations.
  #
  # Future enhancement: Consolidate Blocks 2-4 into single looping block.

  echo "Iteration $ITERATION incomplete. Coverage: ${COVERAGE}% (target: ${COVERAGE_THRESHOLD}%)"
  echo "Re-run /test to continue coverage loop, or proceed to Block 5/6 for completion."
fi

# Checkpoint: Test verification complete
echo "Test results parsed: passed=$TESTS_PASSED, failed=$TESTS_FAILED, coverage=${COVERAGE}%, next=$NEXT_STATE"
```

## Block 5: Debug Phase [CONDITIONAL]

**EXECUTE NOW**: If NEXT_STATE is "debug", invoke debug-analyst agent with iteration summary and test failure details. Skip this block if NEXT_STATE is "complete".

```bash
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e

# === THREE-TIER LIBRARY SOURCING ===
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-${HOME}/.config}"
CLAUDE_LIB="${CLAUDE_PROJECT_DIR}/.claude/lib"

source "${CLAUDE_LIB}/core/error-handling.sh" 2>/dev/null || { echo "ERROR: Cannot load error-handling library" >&2; exit 1; }
source "${CLAUDE_LIB}/core/state-persistence.sh" 2>/dev/null || { echo "ERROR: Cannot load state-persistence library" >&2; exit 1; }
source "${CLAUDE_LIB}/workflow/workflow-state-machine.sh" 2>/dev/null || { echo "ERROR: Cannot load workflow-state-machine library" >&2; exit 1; }

setup_bash_error_trap

# === STATE RESTORATION ===
# Find most recent test workflow state file
WORKFLOW_ID=$(ls -t "${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_test_"*.sh 2>/dev/null | head -1 | sed 's/.*workflow_\(.*\)\.sh/\1/')

if [ -z "$WORKFLOW_ID" ]; then
  echo "ERROR: Cannot find workflow state file for test command" >&2
  exit 1
fi

load_workflow_state "$WORKFLOW_ID" false NEXT_STATE DEBUG_DIR || {
  echo "ERROR: Failed to load workflow state" >&2
  exit 1
}

# === CONDITIONAL CHECK ===
if [ "$NEXT_STATE" != "debug" ]; then
  echo "Skipping debug phase (NEXT_STATE=$NEXT_STATE)"
  exit 0
fi

# === DEBUG INVOCATION ===
# Invoke debug-analyst.md via Task tool

ISSUE_DESCRIPTION="Test coverage loop failure: "

if [ "$STUCK_COUNT" -ge 2 ]; then
  ISSUE_DESCRIPTION+="Coverage stuck at ${FINAL_COVERAGE}% for 2 iterations (no progress). "
elif [ "$ITERATION" -ge "$MAX_TEST_ITERATIONS" ]; then
  ISSUE_DESCRIPTION+="Max iterations ($MAX_TEST_ITERATIONS) reached with ${FINAL_COVERAGE}% coverage (target: ${COVERAGE_THRESHOLD}%). "
else
  ISSUE_DESCRIPTION+="Test failures: ${FINAL_TESTS_FAILED} failed, ${FINAL_TESTS_PASSED} passed. "
fi

ISSUE_DESCRIPTION+="Iteration summary: ${ITERATION} iteration(s) executed. Final coverage: ${FINAL_COVERAGE}%."

DEBUG_OUTPUT_PATH="${DEBUG_DIR}/debug_report_$(date +%s).md"

# Persist debug path for completion block
append_workflow_state "DEBUG_REPORT_PATH" "$DEBUG_OUTPUT_PATH"

echo "Invoking debug-analyst for test failure analysis..."
```

**EXECUTE NOW**: USE the Task tool to invoke the debug-analyst agent for test failure analysis.

Task {
  subagent_type: "general-purpose"
  description: "Analyze test failures and provide debugging guidance"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md

    You are debugging: test workflow failures

    **Input Contract**:
    - issue_description: ${ISSUE_DESCRIPTION}
    - failed_phase: \"test\"
    - test_output_path: ${TEST_OUTPUT_PATH}
    - debug_directory: ${DEBUG_DIR}
    - output_path: ${DEBUG_OUTPUT_PATH}

    Analyze test failures, coverage gaps, and provide actionable debugging guidance.

    Return: DEBUG_COMPLETE: {PATH}
    debug_report_path: ${DEBUG_OUTPUT_PATH}
  "
}

```bash
# Checkpoint: Debug phase complete (or skipped)
echo "Debug phase: ${NEXT_STATE}"
```

## Block 6: Completion

**EXECUTE NOW**: Transition to COMPLETE state, create console summary with iteration-aware messaging, emit TEST_COMPLETE signal, and cleanup state files.

```bash
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e

# === THREE-TIER LIBRARY SOURCING ===
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-${HOME}/.config}"
CLAUDE_LIB="${CLAUDE_PROJECT_DIR}/.claude/lib"

source "${CLAUDE_LIB}/core/error-handling.sh" 2>/dev/null || { echo "ERROR: Cannot load error-handling library" >&2; exit 1; }
source "${CLAUDE_LIB}/core/state-persistence.sh" 2>/dev/null || { echo "ERROR: Cannot load state-persistence library" >&2; exit 1; }
source "${CLAUDE_LIB}/workflow/workflow-state-machine.sh" 2>/dev/null || { echo "ERROR: Cannot load workflow-state-machine library" >&2; exit 1; }

setup_bash_error_trap

# === STATE RESTORATION ===
# Find most recent test workflow state file
WORKFLOW_ID=$(ls -t "${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_test_"*.sh 2>/dev/null | head -1 | sed 's/.*workflow_\(.*\)\.sh/\1/')

if [ -z "$WORKFLOW_ID" ]; then
  echo "ERROR: Cannot find workflow state file for test command" >&2
  exit 1
fi

load_workflow_state "$WORKFLOW_ID" false PLAN_FILE TEST_OUTPUT_PATH NEXT_STATE || {
  echo "ERROR: Failed to load workflow state" >&2
  exit 1
}

# === STATE TRANSITION TO COMPLETE ===
sm_transition "$STATE_COMPLETE" "test phase complete" 2>/dev/null || {
  log_command_error "state_error" \
    "State transition to COMPLETE failed" \
    "Current state: $CURRENT_STATE"
  exit 1
}

# === CONSOLE SUMMARY ===
echo ""
echo "═══════════════════════════════════════════════════════"
echo "TEST EXECUTION COMPLETE"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "## Summary"
echo ""

if [ "$NEXT_STATE" = "complete" ]; then
  echo "All tests passed with ${FINAL_COVERAGE}% coverage after ${ITERATION} iteration(s)."
  echo "Coverage threshold ${COVERAGE_THRESHOLD}% met successfully."
elif [ "$STUCK_COUNT" -ge 2 ]; then
  echo "Coverage loop stuck (no progress for 2 iterations)."
  echo "Final coverage: ${FINAL_COVERAGE}% (target: ${COVERAGE_THRESHOLD}%)."
  echo "Debug report: ${DEBUG_REPORT_PATH:-not created}"
else
  echo "Max iterations (${MAX_TEST_ITERATIONS}) reached."
  echo "Final coverage: ${FINAL_COVERAGE}% (target: ${COVERAGE_THRESHOLD}%)."
  echo "Debug report: ${DEBUG_REPORT_PATH:-not created}"
fi

echo ""
echo "## Test Results"
echo ""
echo "- Tests Passed: $FINAL_TESTS_PASSED"
echo "- Tests Failed: $FINAL_TESTS_FAILED"
echo "- Coverage: ${FINAL_COVERAGE}%"
echo "- Iterations: ${ITERATION}"
echo ""
echo "## Artifacts"
echo ""
echo "- Plan: $PLAN_FILE"
echo "- Test Results: $TEST_OUTPUT_PATH"
if [ -n "${DEBUG_REPORT_PATH:-}" ]; then
  echo "- Debug Report: $DEBUG_REPORT_PATH"
fi
echo ""
echo "## Next Steps"
echo ""

if [ "$NEXT_STATE" = "complete" ]; then
  echo "• Review test results: cat $TEST_OUTPUT_PATH"
  echo "• Verify coverage meets project requirements"
  echo "• Run /todo to update TODO.md (adds completed tests to tracking)"
else
  echo "• Review debug report: cat ${DEBUG_REPORT_PATH:-no debug report}"
  echo "• Address failing tests or coverage gaps"
  echo "• Re-run /test after fixes"
  echo "• Run /todo to update TODO.md when complete"
fi

echo ""
echo "📋 Next Step: Run /todo to update TODO.md with test results"
echo ""
echo "═══════════════════════════════════════════════════════"

# === TEST_COMPLETE SIGNAL ===
echo ""
echo "TEST_COMPLETE:"
echo "  test_artifact_paths:"
echo "    - $TEST_OUTPUT_PATH"
if [ -n "${DEBUG_REPORT_PATH:-}" ]; then
  echo "  debug_report_path: $DEBUG_REPORT_PATH"
fi
echo "  coverage: ${FINAL_COVERAGE}%"
echo "  status: ${NEXT_STATE}"
echo "  iterations: ${ITERATION}"
echo ""

# === CLEANUP ===
# Remove state file (workflow complete)
if [ -f "$STATE_FILE" ]; then
  rm -f "$STATE_FILE" 2>/dev/null || true
fi

# Remove argument files
rm -f "${HOME}/.claude/tmp/test_arg_"*.txt 2>/dev/null || true

# Checkpoint: Cleanup complete
echo "Test workflow complete"
```
