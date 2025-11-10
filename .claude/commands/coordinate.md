---
allowed-tools: Task, TodoWrite, Bash, Read
argument-hint: <workflow-description>
description: Coordinate multi-agent workflows with wave-based parallel implementation (state machine architecture)
command-type: primary
dependent-commands: research, plan, implement, debug, test, document
---

# /coordinate - Multi-Agent Workflow Orchestration (State Machine)

YOU ARE EXECUTING AS the /coordinate command.

**Documentation**: See `.claude/docs/guides/coordinate-command-guide.md` for architecture, usage patterns, troubleshooting, and examples.

---

## State Machine Initialization - Part 1: Capture Workflow Description

[EXECUTION-CRITICAL: Two-step execution pattern to avoid positional parameter issues]

**STEP 1**: The user invoked `/coordinate "<workflow-description>"`. You need to capture that description.

In the **tiny bash block below**, replace `YOUR_WORKFLOW_DESCRIPTION_HERE` with the actual workflow description (keeping the quotes).

**Example**: If user ran `/coordinate "research auth patterns"`, change:
- FROM: `echo "YOUR_WORKFLOW_DESCRIPTION_HERE" > /tmp/coordinate_workflow_$$.txt`
- TO: `echo "research auth patterns" > /tmp/coordinate_workflow_$$.txt`

Execute this **small** bash block with your substitution:

```bash
# SUBSTITUTE THE WORKFLOW DESCRIPTION IN THE LINE BELOW
echo "YOUR_WORKFLOW_DESCRIPTION_HERE" > /tmp/coordinate_workflow_$$.txt
echo "✓ Workflow description captured"
```

---

## State Machine Initialization - Part 2: Main Logic

Now execute the main initialization (this reads from the file created above):

```bash
set +H  # Explicitly disable history expansion (workaround for Bash tool preprocessing issues)
set -euo pipefail  # Fail-fast error handling

echo "=== State Machine Workflow Orchestration ==="
echo ""

# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Read workflow description from file (written in Part 1)
WORKFLOW_DESCRIPTION=$(cat /tmp/coordinate_workflow_$$.txt 2>/dev/null || echo "")

if [ -z "$WORKFLOW_DESCRIPTION" ]; then
  echo "ERROR: Workflow description required"
  echo "Usage: /coordinate \"<workflow description>\""
  exit 1
fi

export WORKFLOW_DESCRIPTION

# Source state machine and state persistence libraries
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Avoid ! operator due to Bash tool preprocessing issues
if [ -f "${LIB_DIR}/workflow-state-machine.sh" ]; then
  source "${LIB_DIR}/workflow-state-machine.sh"
else
  echo "ERROR: workflow-state-machine.sh not found"
  exit 1
fi

if [ -f "${LIB_DIR}/state-persistence.sh" ]; then
  : # File exists, continue
else
  echo "ERROR: state-persistence.sh not found"
  exit 1
fi
source "${LIB_DIR}/state-persistence.sh"

# Initialize workflow state (GitHub Actions pattern)
STATE_FILE=$(init_workflow_state "coordinate_$$")
trap "rm -f '$STATE_FILE'" EXIT

# Save workflow ID and description for subsequent blocks
append_workflow_state "WORKFLOW_ID" "coordinate_$$"
append_workflow_state "WORKFLOW_DESCRIPTION" "$WORKFLOW_DESCRIPTION"

# Initialize state machine
sm_init "$WORKFLOW_DESCRIPTION" "coordinate"

# Save state machine configuration to workflow state
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
append_workflow_state "TERMINAL_STATE" "$TERMINAL_STATE"
append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"

# Source required libraries based on scope
source "${LIB_DIR}/library-sourcing.sh"

case "$WORKFLOW_SCOPE" in
  research-only)
    REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "error-handling.sh")
    ;;
  research-and-plan)
    REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "metadata-extraction.sh" "checkpoint-utils.sh" "error-handling.sh")
    ;;
  full-implementation)
    REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "metadata-extraction.sh" "checkpoint-utils.sh" "dependency-analyzer.sh" "context-pruning.sh" "error-handling.sh")
    ;;
  debug-only)
    REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "metadata-extraction.sh" "checkpoint-utils.sh" "error-handling.sh")
    ;;
esac

# Avoid ! operator due to Bash tool preprocessing issues
if source_required_libraries "${REQUIRED_LIBS[@]}"; then
  : # Success - libraries loaded
else
  echo "ERROR: Failed to source required libraries"
  exit 1
fi

# Source workflow initialization and initialize paths
if [ -f "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-initialization.sh" ]; then
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-initialization.sh"
else
  echo "ERROR: workflow-initialization.sh not found"
  exit 1
fi

if initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE"; then
  : # Success - paths initialized
else
  handle_state_error "Workflow initialization failed" 1
fi

# Validate TOPIC_PATH was set by initialization
if [ -z "${TOPIC_PATH:-}" ]; then
  handle_state_error "TOPIC_PATH not set after workflow initialization (bug in initialize_workflow_paths)" 1
fi

# Save paths to workflow state
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"

# Source verification helpers
if [ -f "${CLAUDE_PROJECT_DIR}/.claude/lib/verification-helpers.sh" ]; then
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/verification-helpers.sh"
fi

# Define completion summary helper
display_brief_summary() {
  echo ""
  echo "✓ Workflow complete: $WORKFLOW_SCOPE"
  case "$WORKFLOW_SCOPE" in
    research-only)
      local report_count=${#REPORT_PATHS[@]}
      echo "Created $report_count research reports in: $TOPIC_PATH/reports/"
      ;;
    research-and-plan)
      local report_count=${#REPORT_PATHS[@]}
      echo "Created $report_count reports + 1 plan in: $TOPIC_PATH/"
      echo "→ Run: /implement $PLAN_PATH"
      ;;
    full-implementation)
      echo "Implementation complete. Summary: $SUMMARY_PATH"
      ;;
    debug-only)
      echo "Debug analysis complete: $DEBUG_REPORT"
      ;;
    *)
      echo "Workflow artifacts available in: $TOPIC_PATH"
      ;;
  esac
  echo ""
}
export -f display_brief_summary

# Note: handle_state_error() is now defined in .claude/lib/error-handling.sh
# It will be available via library sourcing in all bash blocks

# Transition to research state
sm_transition "$STATE_RESEARCH"

echo ""
echo "State Machine Initialized:"
echo "  Scope: $WORKFLOW_SCOPE"
echo "  Current State: $CURRENT_STATE"
echo "  Terminal State: $TERMINAL_STATE"
echo "  Topic Path: ${TOPIC_PATH:-<not set>}"
echo ""
```

---

## State Handler: Research Phase

[EXECUTION-CRITICAL: Parallel research agent invocation]

**State Handler Function**: This section executes when `CURRENT_STATE == "research"`

USE the Bash tool:

```bash
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Load workflow state
load_workflow_state "coordinate_$$"

# Check if we should skip this state (already at terminal)
if [ "$CURRENT_STATE" = "$TERMINAL_STATE" ]; then
  echo "✓ Workflow complete at terminal state: $TERMINAL_STATE"
  display_brief_summary
  exit 0
fi

# Verify we're in research state
if [ "$CURRENT_STATE" != "$STATE_RESEARCH" ]; then
  echo "ERROR: Expected state '$STATE_RESEARCH' but current state is '$CURRENT_STATE'"
  exit 1
fi

if command -v emit_progress &>/dev/null; then
  emit_progress "1" "State: Research (parallel agent invocation)"
fi

# Determine research complexity (1-4 topics)
RESEARCH_COMPLEXITY=2

if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "integrate|migration|refactor|architecture"; then
  RESEARCH_COMPLEXITY=3
fi

if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "multi-.*system|cross-.*platform|distributed|microservices"; then
  RESEARCH_COMPLEXITY=4
fi

if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "^(fix|update|modify).*(one|single|small)"; then
  RESEARCH_COMPLEXITY=1
fi

echo "Research Complexity Score: $RESEARCH_COMPLEXITY topics"

# Reconstruct REPORT_PATHS array
reconstruct_report_paths_array

# Determine if hierarchical supervision is needed
USE_HIERARCHICAL_RESEARCH=$([ $RESEARCH_COMPLEXITY -ge 4 ] && echo "true" || echo "false")

if [ "$USE_HIERARCHICAL_RESEARCH" = "true" ]; then
  echo "Using hierarchical research supervision (≥4 topics)"
  emit_progress "1" "Invoking research-sub-supervisor for $RESEARCH_COMPLEXITY topics"
else
  echo "Using flat research coordination (<4 topics)"
  emit_progress "1" "Invoking $RESEARCH_COMPLEXITY research agents in parallel"
fi
```

**CONDITIONAL EXECUTION**: Choose hierarchical or flat coordination based on topic count.

### Option A: Hierarchical Research Supervision (≥4 topics)

**EXECUTE IF** `USE_HIERARCHICAL_RESEARCH == "true"`:

USE the Task tool to invoke research-sub-supervisor:

Task {
  subagent_type: "general-purpose"
  description: "Coordinate research across 4+ topics with 95% context reduction"
  timeout: 600000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-sub-supervisor.md

    **Supervisor Inputs**:
    - Topics: [comma-separated list of $RESEARCH_COMPLEXITY topics]
    - Output directory: $TOPIC_PATH/reports
    - State file: $STATE_FILE
    - Supervisor ID: research_sub_supervisor_$(date +%s)

    **CRITICAL**: Invoke all research-specialist workers in parallel, aggregate metadata, save supervisor checkpoint.

    Return: SUPERVISOR_COMPLETE: {supervisor_id, aggregated_metadata}
  "
}

### Option B: Flat Research Coordination (<4 topics)

**EXECUTE IF** `USE_HIERARCHICAL_RESEARCH == "false"`:

**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent for EACH research topic (1 to $RESEARCH_COMPLEXITY):

Task {
  subagent_type: "general-purpose"
  description: "Research [topic name] with mandatory artifact creation"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: [actual topic name]
    - Report Path: [REPORT_PATHS[$i-1] for topic $i]
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Complexity Level: [RESEARCH_COMPLEXITY value]

    **CRITICAL**: Create report file at EXACT path provided above.

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [exact absolute path to report file]
  "
}

USE the Bash tool:

```bash
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

load_workflow_state "coordinate_$$"

emit_progress "1" "Research phase completion - verifying results"

# Handle hierarchical vs flat coordination differently
if [ "$USE_HIERARCHICAL_RESEARCH" = "true" ]; then
  echo "Hierarchical research supervision mode"

  # Load supervisor checkpoint to get aggregated metadata
  SUPERVISOR_CHECKPOINT=$(load_json_checkpoint "research_supervisor")

  # Extract report paths from supervisor checkpoint
  SUPERVISOR_REPORTS=$(echo "$SUPERVISOR_CHECKPOINT" | jq -r '.aggregated_metadata.reports_created[]')

  # Verify reports exist (supervisor should have created them)
  VERIFICATION_FAILURES=0
  SUCCESSFUL_REPORT_PATHS=()

  REPORT_INDEX=0
  for REPORT_PATH in $SUPERVISOR_REPORTS; do
    REPORT_INDEX=$((REPORT_INDEX + 1))
    if verify_file_created "$REPORT_PATH" "Supervisor report $REPORT_INDEX" "Hierarchical Research"; then
      SUCCESSFUL_REPORT_PATHS+=("$REPORT_PATH")
    else
      VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
    fi
  done

  if [ $VERIFICATION_FAILURES -gt 0 ]; then
    handle_state_error "Hierarchical research failed - $VERIFICATION_FAILURES supervisor reports missing" 1
  fi

  # Display supervisor summary (95% context reduction benefit)
  SUPERVISOR_SUMMARY=$(echo "$SUPERVISOR_CHECKPOINT" | jq -r '.aggregated_metadata.summary')
  CONTEXT_TOKENS=$(echo "$SUPERVISOR_CHECKPOINT" | jq -r '.aggregated_metadata.context_tokens')
  echo "✓ Supervisor summary: $SUPERVISOR_SUMMARY"
  echo "✓ Context reduction: ${#SUCCESSFUL_REPORT_PATHS[@]} reports → $CONTEXT_TOKENS tokens (95%)"

else
  echo "Flat research coordination mode"

  # Verify all research reports created (original flat pattern)
  echo -n "Verifying research reports ($RESEARCH_COMPLEXITY): "

  VERIFICATION_FAILURES=0
  SUCCESSFUL_REPORT_PATHS=()

  for i in $(seq 1 $RESEARCH_COMPLEXITY); do
    REPORT_PATH="${REPORT_PATHS[$i-1]}"
    # Avoid ! operator due to Bash tool preprocessing issues
    if verify_file_created "$REPORT_PATH" "Research report $i/$RESEARCH_COMPLEXITY" "Research"; then
      SUCCESSFUL_REPORT_PATHS+=("$REPORT_PATH")
    else
      VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
    fi
  done

  if [ $VERIFICATION_FAILURES -gt 0 ]; then
    echo "❌ FAILED: $VERIFICATION_FAILURES research reports not created"
    handle_state_error "Research phase failed verification - $VERIFICATION_FAILURES reports not created" 1
  fi

  echo "✓ All reports verified"
fi

# Save report paths to workflow state (same for both modes)
append_workflow_state "REPORT_PATHS_JSON" "$(printf '%s\n' "${SUCCESSFUL_REPORT_PATHS[@]}" | jq -R . | jq -s .)"

# Determine next state based on workflow scope
case "$WORKFLOW_SCOPE" in
  research-only)
    # Terminal state reached
    sm_transition "$STATE_COMPLETE"
    append_workflow_state "CURRENT_STATE" "$STATE_COMPLETE"
    echo ""
    echo "✓ Research-only workflow complete"
    display_brief_summary
    exit 0
    ;;
  research-and-plan|full-implementation|debug-only)
    # Continue to planning
    sm_transition "$STATE_PLAN"
    append_workflow_state "CURRENT_STATE" "$STATE_PLAN"
    ;;
  *)
    echo "ERROR: Unknown workflow scope: $WORKFLOW_SCOPE"
    exit 1
    ;;
esac

emit_progress "2" "Research complete, transitioning to Planning"
```

---

## State Handler: Planning Phase

[EXECUTION-CRITICAL: Plan creation with complexity analysis]

**State Handler Function**: This section executes when `CURRENT_STATE == "plan"`

USE the Bash tool:

```bash
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

load_workflow_state "coordinate_$$"

# Check if we should skip this state
if [ "$CURRENT_STATE" = "$TERMINAL_STATE" ]; then
  echo "✓ Workflow complete at terminal state: $TERMINAL_STATE"
  display_brief_summary
  exit 0
fi

# Verify we're in plan state
if [ "$CURRENT_STATE" != "$STATE_PLAN" ]; then
  echo "ERROR: Expected state '$STATE_PLAN' but current state is '$CURRENT_STATE'"
  exit 1
fi

if command -v emit_progress &>/dev/null; then
  emit_progress "2" "State: Planning (implementation plan creation)"
fi

# Reconstruct report paths from state
if [ -n "${REPORT_PATHS_JSON:-}" ]; then
  mapfile -t REPORT_PATHS < <(echo "$REPORT_PATHS_JSON" | jq -r '.[]')
fi

# Build report references for /plan
REPORT_ARGS=""
for report in "${REPORT_PATHS[@]}"; do
  REPORT_ARGS="$REPORT_ARGS \"$report\""
done

echo "Creating implementation plan with ${#REPORT_PATHS[@]} research reports..."
```

**EXECUTE NOW**: USE the Task tool to invoke /plan command:

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan guided by research reports"
  timeout: 300000
  prompt: "
    Execute the /plan slash command with the following arguments:

    /plan \"$WORKFLOW_DESCRIPTION\" $REPORT_ARGS

    This will create an implementation plan guided by the research reports.
    The plan will be saved to: $TOPIC_PATH/plans/

    Return: PLAN_CREATED: [absolute path to plan file]
  "
}

USE the Bash tool:

```bash
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

load_workflow_state "coordinate_$$"

emit_progress "2" "Plan creation invoked - awaiting completion"

# Verify plan was created
PLAN_PATH="${TOPIC_PATH}/plans/001_implementation.md"

# Avoid ! operator due to Bash tool preprocessing issues
if verify_file_created "$PLAN_PATH" "Implementation plan" "Planning"; then
  echo "✓ Plan verified: $PLAN_PATH"
else
  handle_state_error "Plan file not created at expected path: $PLAN_PATH" 1
fi

# Save plan path to workflow state
append_workflow_state "PLAN_PATH" "$PLAN_PATH"

# Determine next state based on workflow scope
case "$WORKFLOW_SCOPE" in
  research-and-plan)
    # Terminal state reached
    sm_transition "$STATE_COMPLETE"
    append_workflow_state "CURRENT_STATE" "$STATE_COMPLETE"
    echo ""
    echo "✓ Research-and-plan workflow complete"
    display_brief_summary
    exit 0
    ;;
  full-implementation)
    # Continue to implementation
    sm_transition "$STATE_IMPLEMENT"
    append_workflow_state "CURRENT_STATE" "$STATE_IMPLEMENT"
    ;;
  debug-only)
    # Skip to debug
    sm_transition "$STATE_DEBUG"
    append_workflow_state "CURRENT_STATE" "$STATE_DEBUG"
    ;;
  *)
    echo "ERROR: Unknown workflow scope: $WORKFLOW_SCOPE"
    exit 1
    ;;
esac

emit_progress "3" "Planning complete, transitioning to Implementation"
```

---

## State Handler: Implementation Phase

[EXECUTION-CRITICAL: Wave-based parallel implementation]

**State Handler Function**: This section executes when `CURRENT_STATE == "implement"`

USE the Bash tool:

```bash
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

load_workflow_state "coordinate_$$"

# Check if we should skip this state
if [ "$CURRENT_STATE" = "$TERMINAL_STATE" ]; then
  echo "✓ Workflow complete at terminal state: $TERMINAL_STATE"
  display_brief_summary
  exit 0
fi

# Verify we're in implement state
if [ "$CURRENT_STATE" != "$STATE_IMPLEMENT" ]; then
  echo "ERROR: Expected state '$STATE_IMPLEMENT' but current state is '$CURRENT_STATE'"
  exit 1
fi

if command -v emit_progress &>/dev/null; then
  emit_progress "3" "State: Implementation (wave-based parallel execution)"
fi

echo "Executing implementation plan: $PLAN_PATH"
```

**EXECUTE NOW**: USE the Task tool to invoke /implement command:

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with automated testing and commits"
  timeout: 600000
  prompt: "
    Execute the /implement slash command with the following arguments:

    /implement \"$PLAN_PATH\"

    This will execute the implementation plan phase-by-phase with:
    - Automated testing after each phase
    - Git commits for completed phases
    - Progress tracking and checkpoints

    Return: IMPLEMENTATION_COMPLETE: [summary or status]
  "
}

USE the Bash tool:

```bash
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

load_workflow_state "coordinate_$$"

emit_progress "3" "Implementation complete - transitioning to Testing"

# Transition to testing
sm_transition "$STATE_TEST"
append_workflow_state "CURRENT_STATE" "$STATE_TEST"

emit_progress "4" "Implementation complete, transitioning to Testing"
```

---

## State Handler: Testing Phase

[EXECUTION-CRITICAL: Comprehensive test execution]

**State Handler Function**: This section executes when `CURRENT_STATE == "test"`

USE the Bash tool:

```bash
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

load_workflow_state "coordinate_$$"

# Check if we should skip this state
if [ "$CURRENT_STATE" = "$TERMINAL_STATE" ]; then
  echo "✓ Workflow complete at terminal state: $TERMINAL_STATE"
  display_brief_summary
  exit 0
fi

# Verify we're in test state
if [ "$CURRENT_STATE" != "$STATE_TEST" ]; then
  echo "ERROR: Expected state '$STATE_TEST' but current state is '$CURRENT_STATE'"
  exit 1
fi

if command -v emit_progress &>/dev/null; then
  emit_progress "4" "State: Testing (comprehensive test suite execution)"
fi

echo "Running comprehensive test suite..."

# Run test suite
if command -v run_test_suite &>/dev/null; then
  TEST_RESULT=$(run_test_suite)
  TEST_EXIT_CODE=$?
else
  # Fallback: use /test-all
  bash "${CLAUDE_PROJECT_DIR}/.claude/tests/run_all_tests.sh"
  TEST_EXIT_CODE=$?
fi

# Save test result to workflow state
append_workflow_state "TEST_EXIT_CODE" "$TEST_EXIT_CODE"

# Determine next state based on test results
if [ $TEST_EXIT_CODE -eq 0 ]; then
  echo "✓ All tests passed"

  # Transition to documentation
  sm_transition "$STATE_DOCUMENT"
  append_workflow_state "CURRENT_STATE" "$STATE_DOCUMENT"

  emit_progress "6" "Tests passed, transitioning to Documentation"
else
  echo "❌ Tests failed"

  # Transition to debug
  sm_transition "$STATE_DEBUG"
  append_workflow_state "CURRENT_STATE" "$STATE_DEBUG"

  emit_progress "5" "Tests failed, transitioning to Debug"
fi
```

---

## State Handler: Debug Phase (Conditional)

[EXECUTION-CRITICAL: Debug test failures]

**State Handler Function**: This section executes when `CURRENT_STATE == "debug"`

USE the Bash tool:

```bash
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

load_workflow_state "coordinate_$$"

# Check if we should skip this state
if [ "$CURRENT_STATE" = "$TERMINAL_STATE" ]; then
  echo "✓ Workflow complete at terminal state: $TERMINAL_STATE"
  display_brief_summary
  exit 0
fi

# Verify we're in debug state
if [ "$CURRENT_STATE" != "$STATE_DEBUG" ]; then
  echo "ERROR: Expected state '$STATE_DEBUG' but current state is '$CURRENT_STATE'"
  exit 1
fi

if command -v emit_progress &>/dev/null; then
  emit_progress "5" "State: Debug (analyzing test failures)"
fi

echo "Analyzing test failures..."
```

**EXECUTE NOW**: USE the Task tool to invoke /debug command:

Task {
  subagent_type: "general-purpose"
  description: "Analyze and debug test failures"
  timeout: 300000
  prompt: "
    Execute the /debug slash command with the following context:

    /debug \"Analyze test failures from implementation of: $WORKFLOW_DESCRIPTION\"

    This will create a debug report with root cause analysis and proposed fixes.

    Return: DEBUG_REPORT_CREATED: [absolute path to debug report]
  "
}

USE the Bash tool:

```bash
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

load_workflow_state "coordinate_$$"

emit_progress "5" "Debug analysis complete"

# Save debug report path
# Note: In a real implementation, this would be extracted from agent response
append_workflow_state "DEBUG_REPORT" "${TOPIC_PATH}/debug/001_debug_report.md"

# Transition to complete (user must fix issues manually)
sm_transition "$STATE_COMPLETE"
append_workflow_state "CURRENT_STATE" "$STATE_COMPLETE"

echo ""
echo "✓ Debug analysis complete"
echo "Debug report: $DEBUG_REPORT"
echo ""
echo "NOTE: Please review debug report and fix issues manually"
echo "Then re-run: /coordinate \"$WORKFLOW_DESCRIPTION\""
echo ""
```

---

## State Handler: Documentation Phase (Conditional)

[EXECUTION-CRITICAL: Update documentation]

**State Handler Function**: This section executes when `CURRENT_STATE == "document"`

USE the Bash tool:

```bash
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

load_workflow_state "coordinate_$$"

# Check if we should skip this state
if [ "$CURRENT_STATE" = "$TERMINAL_STATE" ]; then
  echo "✓ Workflow complete at terminal state: $TERMINAL_STATE"
  display_brief_summary
  exit 0
fi

# Verify we're in document state
if [ "$CURRENT_STATE" != "$STATE_DOCUMENT" ]; then
  echo "ERROR: Expected state '$STATE_DOCUMENT' but current state is '$CURRENT_STATE'"
  exit 1
fi

if command -v emit_progress &>/dev/null; then
  emit_progress "6" "State: Documentation (updating relevant docs)"
fi

echo "Updating documentation for implementation changes..."
```

**EXECUTE NOW**: USE the Task tool to invoke /document command:

Task {
  subagent_type: "general-purpose"
  description: "Update documentation based on implementation changes"
  timeout: 300000
  prompt: "
    Execute the /document slash command with the following context:

    /document \"Update docs for: $WORKFLOW_DESCRIPTION\"

    This will update all relevant documentation files based on the implementation changes.

    Return: DOCUMENTATION_UPDATED: [list of updated files]
  "
}

USE the Bash tool:

```bash
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

load_workflow_state "coordinate_$$"

emit_progress "6" "Documentation updated"

# Transition to complete
sm_transition "$STATE_COMPLETE"
append_workflow_state "CURRENT_STATE" "$STATE_COMPLETE"

echo ""
echo "✓ Documentation phase complete"
display_brief_summary
```

---

## Workflow Completion

This section is reached when the state machine reaches `STATE_COMPLETE`.

The workflow has successfully completed all phases based on the detected scope.
Summary and artifacts are available via the `display_brief_summary` function.
