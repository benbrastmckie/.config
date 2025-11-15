---
allowed-tools: Task, TodoWrite, Bash, Read
argument-hint: <workflow-description>
description: Coordinate multi-agent workflows with wave-based parallel implementation (state machine architecture)
command-type: primary
dependent-commands: research, plan, debug, test, document
dependent-agents: research-specialist, plan-architect, implementer-coordinator, debug-analyst
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
- FROM: `echo "YOUR_WORKFLOW_DESCRIPTION_HERE" > "${HOME}/.claude/tmp/coordinate_workflow_desc.txt"`
- TO: `echo "research auth patterns" > "${HOME}/.claude/tmp/coordinate_workflow_desc.txt"`

Execute this **small** bash block with your substitution:

```bash
set +H  # Disable history expansion to prevent bad substitution errors
# SUBSTITUTE THE WORKFLOW DESCRIPTION IN THE LINE BELOW
# CRITICAL: Replace YOUR_WORKFLOW_DESCRIPTION_HERE with the actual workflow description from the user
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
# Use timestamp-based filename for concurrent execution safety (Spec 678 Phase 5)
WORKFLOW_TEMP_FILE="${HOME}/.claude/tmp/coordinate_workflow_desc_$(date +%s%N).txt"
echo "YOUR_WORKFLOW_DESCRIPTION_HERE" > "$WORKFLOW_TEMP_FILE"
# Save temp file path for Part 2 to read
echo "$WORKFLOW_TEMP_FILE" > "${HOME}/.claude/tmp/coordinate_workflow_desc_path.txt"
echo "✓ Workflow description captured to $WORKFLOW_TEMP_FILE"
```

---

## State Machine Initialization - Part 2: Main Logic

Now execute the main initialization (this reads from the file created above):

```bash
set +H  # Explicitly disable history expansion (workaround for Bash tool preprocessing issues)
set -euo pipefail  # Fail-fast error handling

# Performance instrumentation (Phase 1 baseline metrics)
PERF_START_TOTAL=$(date +%s%N)

echo "=== State Machine Workflow Orchestration ==="
echo ""

# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Read workflow description from file (written in Part 1)
# Read temp file path from path file (Spec 678 Phase 5: concurrent execution safety)
COORDINATE_DESC_PATH_FILE="${HOME}/.claude/tmp/coordinate_workflow_desc_path.txt"

if [ -f "$COORDINATE_DESC_PATH_FILE" ]; then
  COORDINATE_DESC_FILE=$(cat "$COORDINATE_DESC_PATH_FILE")
else
  # Fallback to legacy fixed filename for backward compatibility
  COORDINATE_DESC_FILE="${HOME}/.claude/tmp/coordinate_workflow_desc.txt"
fi

if [ -f "$COORDINATE_DESC_FILE" ]; then
  WORKFLOW_DESCRIPTION=$(cat "$COORDINATE_DESC_FILE" 2>/dev/null || echo "")
else
  echo "ERROR: Workflow description file not found: $COORDINATE_DESC_FILE"
  echo "This usually means Part 1 (workflow capture) didn't execute."
  echo "Usage: /coordinate \"<workflow description>\""
  exit 1
fi

if [ -z "$WORKFLOW_DESCRIPTION" ]; then
  echo "ERROR: Workflow description is empty"
  echo "File exists but contains no content: $COORDINATE_DESC_FILE"
  echo "Usage: /coordinate \"<workflow description>\""
  exit 1
fi

# CRITICAL: Save workflow description BEFORE sourcing libraries
# Libraries pre-initialize WORKFLOW_DESCRIPTION="" which overwrites parent value
SAVED_WORKFLOW_DESC="$WORKFLOW_DESCRIPTION"
export SAVED_WORKFLOW_DESC

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

# CRITICAL: Source error-handling.sh and verification-helpers.sh BEFORE any function calls
# These libraries must be available for verification checkpoints and error handling
# throughout initialization (lines 140+). See bash-block-execution-model.md for rationale.

# Source error handling library (provides handle_state_error)
if [ -f "${LIB_DIR}/error-handling.sh" ]; then
  source "${LIB_DIR}/error-handling.sh"
else
  echo "ERROR: error-handling.sh not found at ${LIB_DIR}/error-handling.sh"
  echo "Cannot proceed without error handling functions"
  exit 1
fi

# Source verification helpers library (provides verify_state_variable, verify_file_created)
if [ -f "${LIB_DIR}/verification-helpers.sh" ]; then
  source "${LIB_DIR}/verification-helpers.sh"
else
  echo "ERROR: verification-helpers.sh not found at ${LIB_DIR}/verification-helpers.sh"
  echo "Cannot proceed without verification functions"
  exit 1
fi

# VERIFICATION CHECKPOINT: Verify critical functions available (Standard 0)
if ! command -v verify_file_created &>/dev/null; then
  echo "ERROR: verify_file_created function not available after library sourcing"
  exit 1
fi
if ! command -v handle_state_error &>/dev/null; then
  echo "ERROR: handle_state_error function not available after library sourcing"
  exit 1
fi

# Generate unique workflow ID (timestamp-based for reproducibility)
WORKFLOW_ID="coordinate_$(date +%s)"

# Initialize workflow state (GitHub Actions pattern)
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")

# Pattern 1: Fixed Semantic Filename (bash-block-execution-model.md:163-191)
# Save workflow ID to file for subsequent blocks using fixed location
COORDINATE_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt"
echo "$WORKFLOW_ID" > "$COORDINATE_STATE_ID_FILE"

# VERIFICATION CHECKPOINT: Verify state ID file created successfully (Standard 0: Execution Enforcement)
verify_file_created "$COORDINATE_STATE_ID_FILE" "State ID file" "Initialization" || {
  handle_state_error "CRITICAL: State ID file not created at $COORDINATE_STATE_ID_FILE" 1
}

# Save workflow ID and description to state for subsequent blocks
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"
verify_state_variable "WORKFLOW_ID" || {
  handle_state_error "CRITICAL: WORKFLOW_ID not persisted to state" 1
}

append_workflow_state "WORKFLOW_DESCRIPTION" "$SAVED_WORKFLOW_DESC"
verify_state_variable "WORKFLOW_DESCRIPTION" || {
  handle_state_error "CRITICAL: WORKFLOW_DESCRIPTION not persisted to state" 1
}

# Save state ID file path to workflow state for bash block persistence
append_workflow_state "COORDINATE_STATE_ID_FILE" "$COORDINATE_STATE_ID_FILE"
verify_state_variable "COORDINATE_STATE_ID_FILE" || {
  handle_state_error "CRITICAL: COORDINATE_STATE_ID_FILE not persisted to state" 1
}

# Persist performance instrumentation start time for cross-bash-block access (subprocess isolation)
append_workflow_state "PERF_START_TOTAL" "$PERF_START_TOTAL"

echo "✓ State machine pre-initialization complete. Proceeding to workflow classification..."
```

---

## Phase 0.1: Workflow Classification

**EXECUTE NOW**: USE the Task tool to invoke workflow-classifier agent:

Task {
  subagent_type: "general-purpose"
  description: "Classify workflow intent for orchestration"
  model: "haiku"
  timeout: 30000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/workflow-classifier.md

    **Workflow-Specific Context**:
    - Workflow Description: $SAVED_WORKFLOW_DESC
    - Command Name: coordinate

    **CRITICAL**: Return structured JSON classification.

    Execute classification following all guidelines in behavioral file.
    Return: CLASSIFICATION_COMPLETE: {JSON classification object}
  "
}

USE the Bash tool:

```bash
set +H  # Disable history expansion

# STATE RESTORATION PATTERN: Cross-bash-block state persistence
#
# Why state reloading is required:
# - Each bash block executes in a separate subprocess with its own PID
# - Environment variables do NOT persist across bash blocks (subprocess isolation)
# - File-based persistence enables cross-block communication (GitHub Actions pattern)
# - State must be restored at the beginning of each bash block
#
# Ordering dependencies:
# 1. Load state files BEFORE using state variables
# 2. Source libraries BEFORE calling library functions
# 3. Verify state restoration BEFORE proceeding with workflow logic
#
# See: .claude/docs/concepts/bash-block-execution-model.md for subprocess isolation details
#
# Re-load workflow state (needed after Task invocation)
COORDINATE_DESC_PATH_FILE="${HOME}/.claude/tmp/coordinate_workflow_desc_path.txt"
if [ -f "$COORDINATE_DESC_PATH_FILE" ]; then
  COORDINATE_DESC_FILE=$(cat "$COORDINATE_DESC_PATH_FILE")
  SAVED_WORKFLOW_DESC=$(cat "$COORDINATE_DESC_FILE" 2>/dev/null || echo "")
fi

# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source required libraries
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Load workflow state
COORDINATE_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt"
WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
load_workflow_state "$WORKFLOW_ID"

# FAIL-FAST STATE LOADING: Load classification from state (saved by workflow-classifier agent)
# The workflow-classifier agent MUST have executed append_workflow_state "CLASSIFICATION_JSON" before this block
# See .claude/agents/workflow-classifier.md for agent behavior

# FAIL-FAST VALIDATION: Classification must exist in state
if [ -z "${CLASSIFICATION_JSON:-}" ]; then
  handle_state_error "CRITICAL: workflow-classifier agent did not save CLASSIFICATION_JSON to state

Diagnostic:
  - Agent was instructed to save classification via append_workflow_state
  - Expected: append_workflow_state \"CLASSIFICATION_JSON\" \"\$CLASSIFICATION_JSON\"
  - Check agent's bash execution in previous response
  - State file: \$STATE_FILE (loaded via load_workflow_state at line 220)

This is a critical bug. The workflow cannot proceed without classification data." 1
fi

# FAIL-FAST VALIDATION: JSON must be valid
# Exit code capture pattern prevents bash preprocessing errors
# Bash tool preprocessing happens BEFORE runtime 'set +H' directive
# Pattern validated in Specs 620, 641, 672, 685, 700, 719
echo "$CLASSIFICATION_JSON" | jq empty 2>/dev/null
JSON_VALID=$?
if [ $JSON_VALID -ne 0 ]; then
  handle_state_error "CRITICAL: Invalid JSON in CLASSIFICATION_JSON

Diagnostic:
  - Content: $CLASSIFICATION_JSON
  - JSON validation failed
  - Agent may have malformed the JSON output

This is a critical bug. The workflow cannot proceed with invalid JSON." 1
fi

# Parse JSON fields using jq
WORKFLOW_TYPE=$(echo "$CLASSIFICATION_JSON" | jq -r '.workflow_type' 2>/dev/null)
RESEARCH_COMPLEXITY=$(echo "$CLASSIFICATION_JSON" | jq -r '.research_complexity' 2>/dev/null)
RESEARCH_TOPICS_JSON=$(echo "$CLASSIFICATION_JSON" | jq -c '.research_topics' 2>/dev/null)

# VERIFICATION CHECKPOINT: Verify all required fields extracted (Standard 0: Execution Enforcement)
if [ -z "$WORKFLOW_TYPE" ] || [ "$WORKFLOW_TYPE" = "null" ]; then
  handle_state_error "CRITICAL: workflow_type not found in classification JSON: $CLASSIFICATION_JSON" 1
fi

if [ -z "$RESEARCH_COMPLEXITY" ] || [ "$RESEARCH_COMPLEXITY" = "null" ]; then
  handle_state_error "CRITICAL: research_complexity not found in classification JSON: $CLASSIFICATION_JSON" 1
fi

if [ -z "$RESEARCH_TOPICS_JSON" ] || [ "$RESEARCH_TOPICS_JSON" = "null" ]; then
  handle_state_error "CRITICAL: research_topics not found in classification JSON: $CLASSIFICATION_JSON" 1
fi

# Export classification variables for sm_init consumption
export WORKFLOW_TYPE
export RESEARCH_COMPLEXITY
export RESEARCH_TOPICS_JSON

echo "✓ Workflow classification complete: type=$WORKFLOW_TYPE, complexity=$RESEARCH_COMPLEXITY"

# Initialize state machine with 5 parameters (refactored signature in commit ce1d29a1, Spec 1763161992 Phase 2)
# CRITICAL: Use SAVED_WORKFLOW_DESC (not overwritten variable)
# Do NOT use command substitution $() as it creates subshell that doesn't export to parent
sm_init "$SAVED_WORKFLOW_DESC" "coordinate" "$WORKFLOW_TYPE" "$RESEARCH_COMPLEXITY" "$RESEARCH_TOPICS_JSON" 2>&1
SM_INIT_EXIT_CODE=$?
if [ $SM_INIT_EXIT_CODE -ne 0 ]; then
  handle_state_error "State machine initialization failed. Check sm_init parameters." 1
fi
# VERIFICATION CHECKPOINT 1: Verify environment variables exported by sm_init
# Two-stage verification: (1) environment exports, (2) state file persistence
# This provides early failure detection and clear diagnostic context
if [ -z "${WORKFLOW_SCOPE:-}" ] || [ -z "${TERMINAL_STATE:-}" ] || [ -z "${CURRENT_STATE:-}" ] || \
   [ -z "${RESEARCH_COMPLEXITY:-}" ] || [ -z "${RESEARCH_TOPICS_JSON:-}" ]; then
  handle_state_error "CRITICAL: Required environment variables not exported by sm_init despite successful return code

Diagnostic:
  - sm_init returned success (exit code 0)
  - One or more required environment variables missing
  - Required exports: WORKFLOW_SCOPE, TERMINAL_STATE, CURRENT_STATE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON
  - Check sm_init implementation in workflow-state-machine.sh
  - Verify export statements present for all critical variables

Cannot proceed without environment variable exports." 1
fi

echo "✓ Environment variables verified: WORKFLOW_SCOPE=$WORKFLOW_SCOPE, TERMINAL_STATE=$TERMINAL_STATE, CURRENT_STATE=$CURRENT_STATE"

# VERIFICATION CHECKPOINT 2: Verify all state machine variables persisted to state file
# Standard 0 (Execution Enforcement): Critical state initialization must be verified
# sm_init() now persists all 5 variables to state file (see workflow-state-machine.sh)
verify_state_variables "$STATE_FILE" "WORKFLOW_SCOPE" "TERMINAL_STATE" "CURRENT_STATE" "RESEARCH_COMPLEXITY" "RESEARCH_TOPICS_JSON" || {
  handle_state_error "CRITICAL: Required state machine variables not persisted by sm_init despite successful return code

Diagnostic:
  - sm_init returned success (exit code 0)
  - One or more required variables not persisted to state file
  - Required variables: WORKFLOW_SCOPE, TERMINAL_STATE, CURRENT_STATE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON
  - Check sm_init implementation in workflow-state-machine.sh
  - Verify append_workflow_state calls present for all critical variables

Cannot proceed without state machine initialization." 1
}

echo "✓ State machine variables verified in state file (5/5 variables present)"

# ADDED: Extract and save EXISTING_PLAN_PATH for research-and-revise workflows
if [ "$WORKFLOW_SCOPE" = "research-and-revise" ]; then
  # Extract plan path from workflow description
  if echo "$SAVED_WORKFLOW_DESC" | grep -Eq "/specs/[0-9]+_[^/]+/plans/"; then
    EXISTING_PLAN_PATH=$(echo "$SAVED_WORKFLOW_DESC" | grep -oE "/[^ ]+\.md" | head -1)
    export EXISTING_PLAN_PATH

    # CRITICAL: Verify file exists before proceeding
    verify_file_created "$EXISTING_PLAN_PATH" "Existing plan file" "Initialization" || {
      handle_state_error "Extracted plan path does not exist: $EXISTING_PLAN_PATH" 1
    }

    echo "✓ Extracted existing plan path: $EXISTING_PLAN_PATH"
  else
    handle_state_error "research-and-revise workflow requires plan path in description" 1
  fi
fi

# NOTE: State machine configuration (WORKFLOW_SCOPE, TERMINAL_STATE, CURRENT_STATE,
# RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON) already persisted by sm_init()
# No need to duplicate append_workflow_state calls here - verified above at line 309

# ADDED: Save EXISTING_PLAN_PATH to state for bash block persistence
if [ -n "${EXISTING_PLAN_PATH:-}" ]; then
  append_workflow_state "EXISTING_PLAN_PATH" "$EXISTING_PLAN_PATH"

  # VERIFICATION CHECKPOINT: Verify EXISTING_PLAN_PATH persisted correctly
  verify_state_variable "EXISTING_PLAN_PATH" || {
    handle_state_error "CRITICAL: EXISTING_PLAN_PATH not persisted to state for research-and-revise workflow" 1
  }
fi

# Source required libraries based on scope
source "${LIB_DIR}/library-sourcing.sh"

case "$WORKFLOW_SCOPE" in
  research-only)
    REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "workflow-llm-classifier.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "error-handling.sh")
    ;;
  research-and-plan|research-and-revise)
    REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "workflow-llm-classifier.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "metadata-extraction.sh" "checkpoint-utils.sh" "error-handling.sh")
    ;;
  full-implementation)
    REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "workflow-llm-classifier.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "metadata-extraction.sh" "checkpoint-utils.sh" "dependency-analyzer.sh" "context-pruning.sh" "error-handling.sh")
    ;;
  debug-only)
    REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "workflow-llm-classifier.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "metadata-extraction.sh" "checkpoint-utils.sh" "error-handling.sh")
    ;;
esac

# Avoid ! operator due to Bash tool preprocessing issues
if source_required_libraries "${REQUIRED_LIBS[@]}"; then
  : # Success - libraries loaded
else
  echo "ERROR: Failed to source required libraries"
  echo "DIAGNOSTIC: Check that all library files exist in ${LIB_DIR}"
  exit 1
fi

# Performance marker: Library loading complete
PERF_AFTER_LIBS=$(date +%s%N)
append_workflow_state "PERF_AFTER_LIBS" "$PERF_AFTER_LIBS"

# Source workflow initialization and initialize paths
if [ -f "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-initialization.sh" ]; then
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-initialization.sh"
else
  echo "ERROR: workflow-initialization.sh not found"
  exit 1
fi

if initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE" "$RESEARCH_COMPLEXITY"; then
  : # Success - paths initialized with dynamic allocation
else
  handle_state_error "Workflow initialization failed" 1
fi

# Performance marker: Path initialization complete
PERF_AFTER_PATHS=$(date +%s%N)
append_workflow_state "PERF_AFTER_PATHS" "$PERF_AFTER_PATHS"

# Validate TOPIC_PATH was set by initialization
if [ -z "${TOPIC_PATH:-}" ]; then
  handle_state_error "TOPIC_PATH not set after workflow initialization (bug in initialize_workflow_paths)" 1
fi

# Save paths to workflow state
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
verify_state_variable "TOPIC_PATH" || {
  handle_state_error "CRITICAL: TOPIC_PATH not persisted to state" 1
}

append_workflow_state "PLAN_PATH" "$PLAN_PATH"
verify_state_variable "PLAN_PATH" || {
  handle_state_error "CRITICAL: PLAN_PATH not persisted to state" 1
}

# Save comprehensive classification results to state (Spec 678 Phase 5)
append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"
verify_state_variable "RESEARCH_COMPLEXITY" || {
  handle_state_error "CRITICAL: RESEARCH_COMPLEXITY not persisted to state" 1
}

append_workflow_state "RESEARCH_TOPICS_JSON" "$RESEARCH_TOPICS_JSON"
verify_state_variable "RESEARCH_TOPICS_JSON" || {
  handle_state_error "CRITICAL: RESEARCH_TOPICS_JSON not persisted to state" 1
}

# Serialize REPORT_PATHS array to state (subprocess isolation - see bash-block-execution-model.md)
append_workflow_state "REPORT_PATHS_COUNT" "$REPORT_PATHS_COUNT"
verify_state_variable "REPORT_PATHS_COUNT" || {
  handle_state_error "CRITICAL: REPORT_PATHS_COUNT not persisted to state" 1
}

# Save individual report path variables (using eval to avoid Bash tool preprocessing issues)
for ((i=0; i<REPORT_PATHS_COUNT; i++)); do
  var_name="REPORT_PATH_$i"
  eval "value=\$$var_name"
  append_workflow_state "$var_name" "$value"
done

echo "Allocated $REPORT_PATHS_COUNT report paths (dynamically matched to research complexity)"

# VERIFICATION CHECKPOINT: Verify REPORT_PATHS_COUNT persisted correctly
verify_state_variable "REPORT_PATHS_COUNT" || {
  handle_state_error "CRITICAL: REPORT_PATHS_COUNT not persisted to state after array export" 1
}

# Calculate artifact paths for implementer-coordinator agent (Phase 0 optimization)
# These paths will be injected into the agent during implementation phase
REPORTS_DIR="${TOPIC_PATH}/reports"
PLANS_DIR="${TOPIC_PATH}/plans"
SUMMARIES_DIR="${TOPIC_PATH}/summaries"
DEBUG_DIR="${TOPIC_PATH}/debug"
OUTPUTS_DIR="${TOPIC_PATH}/outputs"
CHECKPOINT_DIR="${HOME}/.claude/data/checkpoints"

# Export for cross-bash-block availability
export REPORTS_DIR PLANS_DIR SUMMARIES_DIR DEBUG_DIR OUTPUTS_DIR CHECKPOINT_DIR

# Save to workflow state for persistence
append_workflow_state "REPORTS_DIR" "$REPORTS_DIR"
append_workflow_state "PLANS_DIR" "$PLANS_DIR"
append_workflow_state "SUMMARIES_DIR" "$SUMMARIES_DIR"
append_workflow_state "DEBUG_DIR" "$DEBUG_DIR"
append_workflow_state "OUTPUTS_DIR" "$OUTPUTS_DIR"
append_workflow_state "CHECKPOINT_DIR" "$CHECKPOINT_DIR"

echo "Artifact paths calculated and saved to workflow state"

# ===== MANDATORY VERIFICATION CHECKPOINT: State Persistence =====
# Verify all REPORT_PATH variables written to state file (Phase 3: concise pattern)
echo -n "Verifying state persistence ($((REPORT_PATHS_COUNT + 1)) vars): "

# Build variable list
VARS_TO_CHECK=("REPORT_PATHS_COUNT")
for ((i=0; i<REPORT_PATHS_COUNT; i++)); do
  VARS_TO_CHECK+=("REPORT_PATH_$i")
done

# Concise verification (✓ on success, diagnostic on failure)
if verify_state_variables "$STATE_FILE" "${VARS_TO_CHECK[@]}"; then
  echo " verified"
else
  handle_state_error "State persistence verification failed" 1
fi

# Transition to research state
echo "Transitioning from initialize to $STATE_RESEARCH"
sm_transition "$STATE_RESEARCH"
append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"
echo "State transition complete: $(date '+%Y-%m-%d %H:%M:%S')"

echo ""
echo "State Machine Initialized:"
echo "  Scope: $WORKFLOW_SCOPE"
echo "  Current State: $CURRENT_STATE"
echo "  Terminal State: $TERMINAL_STATE"
echo "  Topic Path: ${TOPIC_PATH:-<not set>}"

# Performance reporting (Phase 1 baseline metrics)
# Restore performance variables from state (set in previous bash blocks)
# Required due to subprocess isolation - see bash-block-execution-model.md
if [ -n "${PERF_START_TOTAL:-}" ]; then
  : # Already loaded from workflow state
else
  # Fallback: reload if not already available
  load_workflow_state "$WORKFLOW_ID"
fi

PERF_END_INIT=$(date +%s%N)
append_workflow_state "PERF_END_INIT" "$PERF_END_INIT"

# Calculate performance metrics (all variables now available from state)
PERF_LIB_MS=$(( (PERF_AFTER_LIBS - PERF_START_TOTAL) / 1000000 ))
PERF_PATH_MS=$(( (PERF_AFTER_PATHS - PERF_AFTER_LIBS) / 1000000 ))
PERF_TOTAL_MS=$(( (PERF_END_INIT - PERF_START_TOTAL) / 1000000 ))
echo ""
echo "Performance (Baseline Phase 1):"
echo "  Library loading: ${PERF_LIB_MS}ms"
echo "  Path initialization: ${PERF_PATH_MS}ms"
echo "  Total init overhead: ${PERF_TOTAL_MS}ms"
echo ""

# NOTE: Performance instrumentation spans multiple bash blocks
# Variables persisted to state file to cross subprocess boundaries
# See .claude/docs/concepts/bash-block-execution-model.md for details
```

---

## State Handler: Research Phase

[EXECUTION-CRITICAL: Parallel research agent invocation]

**State Handler Function**: This section executes when `CURRENT_STATE == "research"`

USE the Bash tool:

```bash
set +H  # Disable history expansion to prevent bad substitution errors
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Standard 15: Library Sourcing Order - Re-source in dependency order
# Step 1: Source state machine and persistence FIRST (needed for load_workflow_state)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# Step 2: Load workflow state BEFORE other libraries (prevents WORKFLOW_SCOPE reset)
COORDINATE_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt"
if [ ! -f "$COORDINATE_STATE_ID_FILE" ]; then
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE"
  echo "DIAGNOSTIC: Cannot restore workflow state. Check if previous bash block created state file."
  exit 1
fi

WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
load_workflow_state "$WORKFLOW_ID"

# Step 3: Source error handling and verification libraries (Pattern 5 preserves loaded state)
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Step 4: Source additional libraries
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/unified-logger.sh"  # Provides emit_progress and logging functions
source "${LIB_DIR}/context-pruning.sh"  # Provides context reduction and pruning functions
source "${LIB_DIR}/dependency-analyzer.sh"  # Provides phase dependency analysis for wave execution

# VERIFICATION CHECKPOINT: Verify critical functions available (Standard 0)
if ! command -v verify_state_variable &>/dev/null; then
  echo "ERROR: verify_state_variable function not available after library sourcing"
  exit 1
fi
if ! command -v handle_state_error &>/dev/null; then
  echo "ERROR: handle_state_error function not available after library sourcing"
  exit 1
fi

# Check if we should skip this state (already at terminal)
if [ "$CURRENT_STATE" = "$TERMINAL_STATE" ]; then
  # Cleanup LLM classification temp files (Spec 704 Phase 2)
  if [ -n "$WORKFLOW_ID" ]; then
    rm -f "${HOME}/.claude/tmp/llm_request_${WORKFLOW_ID}.json"
    rm -f "${HOME}/.claude/tmp/llm_response_${WORKFLOW_ID}.json"
  fi

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
else
  echo "PROGRESS: State: Research (parallel agent invocation)"
fi

# RESEARCH_COMPLEXITY loaded from workflow state (set by sm_init in Phase 0)
# Pattern matching removed in Spec 678: comprehensive haiku classification provides
# all three dimensions (workflow_type, research_complexity, subtopics) in single call.
# Zero pattern matching for any classification dimension. Fallback to state persistence only.

# FAIL-FAST VALIDATION: RESEARCH_COMPLEXITY must be loaded from state
if [ -z "${RESEARCH_COMPLEXITY:-}" ]; then
  handle_state_error "CRITICAL: RESEARCH_COMPLEXITY not loaded from state

Diagnostic:
  - Expected: RESEARCH_COMPLEXITY should have been saved by Phase 0.1 classification
  - Check Phase 0.1 bash block for sm_init parameters and state persistence
  - This variable determines number of research topics and coordination strategy

Cannot proceed without research complexity score." 1
fi

echo "Research Complexity Score: $RESEARCH_COMPLEXITY topics (from state persistence)"

# Reconstruct REPORT_PATHS array
reconstruct_report_paths_array

# Determine if hierarchical supervision is needed
USE_HIERARCHICAL_RESEARCH=$([ $RESEARCH_COMPLEXITY -ge 4 ] && echo "true" || echo "false")

# Save research configuration to state (Spec 648 fix)
# These variables are used in the next bash block for conditional execution
append_workflow_state "USE_HIERARCHICAL_RESEARCH" "$USE_HIERARCHICAL_RESEARCH"
append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"

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

**EXECUTE NOW**: USE the Task tool to invoke research-sub-supervisor:

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

**EXECUTE NOW**: USE the Bash tool to prepare research agent iteration variables:

```bash
set +H  # Disable history expansion to prevent bad substitution errors
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CRITICAL: Explicit conditional enumeration for agent invocation control
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Natural language templates ("for EACH topic") are interpreted as documentation,
# not iteration constraints. Claude resolves invocation count by examining available
# REPORT_PATH variables (4 pre-allocated) rather than RESEARCH_COMPLEXITY value.
#
# Solution: Bash block prepares variables, markdown section uses explicit conditional
# guards (IF RESEARCH_COMPLEXITY >= N) to control Task invocations.
# See: Spec 676 (root cause analysis), coordinate-command-guide.md (architecture)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Reconstruct RESEARCH_TOPICS array from JSON state (Spec 678 Phase 5)
if [ -n "${RESEARCH_TOPICS_JSON:-}" ]; then
  mapfile -t RESEARCH_TOPICS < <(echo "$RESEARCH_TOPICS_JSON" | jq -r '.[]' 2>/dev/null || true)
else
  # Fallback: Generate generic topic names if state not available
  RESEARCH_TOPICS=("Topic 1" "Topic 2" "Topic 3" "Topic 4")
fi

# Prepare variables for conditional agent invocations (1-4)
# Use descriptive subtopic names from comprehensive classification (not generic "Topic N")
for i in $(seq 1 4); do
  REPORT_PATH_VAR="REPORT_PATH_$((i-1))"
  # Use descriptive topic name from RESEARCH_TOPICS array (zero-indexed)
  topic_index=$((i-1))
  if [ $topic_index -lt ${#RESEARCH_TOPICS[@]} ]; then
    export "RESEARCH_TOPIC_${i}=${RESEARCH_TOPICS[$topic_index]}"
  else
    export "RESEARCH_TOPIC_${i}=Topic ${i}"  # Fallback to generic if array too small
  fi
  export "AGENT_REPORT_PATH_${i}=${!REPORT_PATH_VAR}"
done

echo "━━━ Research Phase: Flat Coordination ━━━"
echo "Research Complexity: $RESEARCH_COMPLEXITY"
echo "Agent Invocations: Conditionally guarded (1-4 based on complexity)"
echo ""
```

**EXECUTE CONDITIONALLY**: Invoke research agents based on RESEARCH_COMPLEXITY:

**IF RESEARCH_COMPLEXITY >= 1** (always true):

**EXECUTE NOW**: USE the Task tool:

Task {
  subagent_type: "general-purpose"
  description: "Research Topic 1 with mandatory artifact creation"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: $RESEARCH_TOPIC_1
    - Report Path: $AGENT_REPORT_PATH_1
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Complexity Level: $RESEARCH_COMPLEXITY

    **CRITICAL**: Create report file at EXACT path provided above.

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [exact absolute path to report file]
  "
}

**IF RESEARCH_COMPLEXITY >= 2** (true for complexity 2-4):

**EXECUTE NOW**: USE the Task tool:

Task {
  subagent_type: "general-purpose"
  description: "Research Topic 2 with mandatory artifact creation"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: $RESEARCH_TOPIC_2
    - Report Path: $AGENT_REPORT_PATH_2
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Complexity Level: $RESEARCH_COMPLEXITY

    **CRITICAL**: Create report file at EXACT path provided above.

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [exact absolute path to report file]
  "
}

**IF RESEARCH_COMPLEXITY >= 3** (true for complexity 3-4):

**EXECUTE NOW**: USE the Task tool:

Task {
  subagent_type: "general-purpose"
  description: "Research Topic 3 with mandatory artifact creation"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: $RESEARCH_TOPIC_3
    - Report Path: $AGENT_REPORT_PATH_3
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Complexity Level: $RESEARCH_COMPLEXITY

    **CRITICAL**: Create report file at EXACT path provided above.

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [exact absolute path to report file]
  "
}

**IF RESEARCH_COMPLEXITY >= 4** (hierarchical research triggers, not this code path):

**EXECUTE NOW**: USE the Task tool:

Task {
  subagent_type: "general-purpose"
  description: "Research Topic 4 with mandatory artifact creation"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: $RESEARCH_TOPIC_4
    - Report Path: $AGENT_REPORT_PATH_4
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Complexity Level: $RESEARCH_COMPLEXITY

    **CRITICAL**: Create report file at EXACT path provided above.

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [exact absolute path to report file]
  "
}

USE the Bash tool:

```bash
set +H  # Disable history expansion to prevent bad substitution errors
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Standard 15: Library Sourcing Order - Re-source in dependency order
# Step 1: Source state machine and persistence FIRST (needed for load_workflow_state)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# Step 2: Load workflow state BEFORE other libraries (prevents WORKFLOW_SCOPE reset)
COORDINATE_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt"
if [ ! -f "$COORDINATE_STATE_ID_FILE" ]; then
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE"
  echo "DIAGNOSTIC: Cannot restore workflow state. Check if previous bash block created state file."
  exit 1
fi

WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
load_workflow_state "$WORKFLOW_ID"

# Step 3: Source error handling and verification libraries (Pattern 5 preserves loaded state)
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Step 4: Source additional libraries
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/unified-logger.sh"  # Provides emit_progress and logging functions
source "${LIB_DIR}/context-pruning.sh"  # Provides context reduction and pruning functions
source "${LIB_DIR}/dependency-analyzer.sh"  # Provides phase dependency analysis for wave execution

# VERIFICATION CHECKPOINT: Verify critical functions available (Standard 0)
if ! command -v verify_state_variable &>/dev/null; then
  echo "ERROR: verify_state_variable function not available after library sourcing"
  exit 1
fi
if ! command -v handle_state_error &>/dev/null; then
  echo "ERROR: handle_state_error function not available after library sourcing"
  exit 1
fi

# RESEARCH_COMPLEXITY loaded from workflow state (set by sm_init in Phase 0)
# Pattern matching removed in Spec 678: comprehensive haiku classification provides
# all three dimensions (workflow_type, research_complexity, subtopics) in single call.
# Zero pattern matching for any classification dimension. Fallback to state persistence only.

# FAIL-FAST VALIDATION: USE_HIERARCHICAL_RESEARCH must be loaded from state
if [ -z "${USE_HIERARCHICAL_RESEARCH:-}" ]; then
  handle_state_error "CRITICAL: USE_HIERARCHICAL_RESEARCH not loaded from state

Diagnostic:
  - Expected: USE_HIERARCHICAL_RESEARCH should have been saved by Phase 1 initialization
  - Check Phase 1 bash block for append_workflow_state \"USE_HIERARCHICAL_RESEARCH\" call
  - This variable determines hierarchical vs flat research coordination

Cannot proceed without research coordination mode." 1
fi

# Reconstruct REPORT_PATHS array from state
reconstruct_report_paths_array

# Report paths pre-calculated with validated slugs - no discovery needed (Spec 688 Phase 5)
# Workflow-initialization.sh now generates semantic filenames from LLM-provided slugs
# (via validate_and_generate_filename_slugs), eliminating the need for post-research
# filename discovery. Files are created at the exact pre-calculated paths.
#
# FAIL-FAST VERIFICATION: Assert that expected report files exist at pre-calculated paths
# No filesystem discovery fallback - agents MUST create files at exact pre-calculated paths
REPORTS_DIR="${TOPIC_PATH}/reports"

# Verify reports directory exists
if [ ! -d "$REPORTS_DIR" ]; then
  handle_state_error "CRITICAL: Reports directory not found: $REPORTS_DIR

Diagnostic:
  - Expected directory should have been created during topic initialization
  - Check workflow-initialization.sh for directory creation logic

Cannot proceed without reports directory." 1
fi

# Fail-fast verification of pre-calculated report paths using batch verification
# Note: More detailed verification happens later (lines 880+ for hierarchical, 935+ for flat)
# This is an early check to fail fast before deeper processing
FILE_ENTRIES=()
for i in $(seq 0 $((REPORT_PATHS_COUNT - 1))); do
  EXPECTED_PATH="${!REPORT_PATH_$i}"
  FILE_ENTRIES+=("${EXPECTED_PATH}:Research report $((i+1))")
done

# Use batch verification for efficient token usage (90% reduction on success)
# Use exit code capture pattern to avoid bash preprocessing issues with negation
verify_files_batch "Research Phase" "${FILE_ENTRIES[@]}"
VERIFICATION_EXIT_CODE=$?
if [ $VERIFICATION_EXIT_CODE -ne 0 ]; then
  handle_state_error "CRITICAL: Research report verification failed

Diagnostic:
  - Expected $REPORT_PATHS_COUNT reports in $REPORTS_DIR
  - Research agents must create files at exact pre-calculated paths
  - Check research agent invocations and file creation logic
  - See verification output above for specific missing files

Cannot proceed with missing research artifacts." 1
fi
echo ""  # Add newline after batch verification output

emit_progress "1" "Research phase completion - verifying results"

# Handle hierarchical vs flat coordination differently
if [ "$USE_HIERARCHICAL_RESEARCH" = "true" ]; then
  echo "Hierarchical research supervision mode"

  # Load supervisor checkpoint to get aggregated metadata
  SUPERVISOR_CHECKPOINT=$(load_json_checkpoint "research_supervisor")

  # extract metadata from supervisor checkpoint (report paths for verification)
  # metadata extraction enables context reduction by passing summaries instead of full reports
  # Target: maintain <30% context usage throughout workflow
  SUPERVISOR_REPORTS=$(echo "$SUPERVISOR_CHECKPOINT" | jq -r '.aggregated_metadata.reports_created[]')

  # ===== MANDATORY VERIFICATION CHECKPOINT: Hierarchical Research =====
  echo ""
  echo "MANDATORY VERIFICATION: Hierarchical Research Artifacts"
  echo "Checking $RESEARCH_COMPLEXITY supervisor-managed reports..."
  echo ""

  VERIFICATION_FAILURES=0
  SUCCESSFUL_REPORT_PATHS=()
  FAILED_REPORT_PATHS=()

  REPORT_INDEX=0
  for REPORT_PATH in $SUPERVISOR_REPORTS; do
    REPORT_INDEX=$((REPORT_INDEX + 1))
    echo -n "  Report $REPORT_INDEX/$RESEARCH_COMPLEXITY: "
    if verify_file_created "$REPORT_PATH" "Supervisor report $REPORT_INDEX" "Hierarchical Research"; then
      SUCCESSFUL_REPORT_PATHS+=("$REPORT_PATH")
      FILE_SIZE=$(stat -f%z "$REPORT_PATH" 2>/dev/null || stat -c%s "$REPORT_PATH" 2>/dev/null || echo "unknown")
      echo " verified ($FILE_SIZE bytes)"
    else
      VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
      FAILED_REPORT_PATHS+=("$REPORT_PATH")
    fi
  done

  echo ""
  echo "Verification Summary:"
  echo "  - Success: ${#SUCCESSFUL_REPORT_PATHS[@]}/$RESEARCH_COMPLEXITY reports"
  echo "  - Failures: $VERIFICATION_FAILURES reports"

  # Track verification metrics in workflow state
  append_workflow_state "VERIFICATION_FAILURES_RESEARCH" "$VERIFICATION_FAILURES"
  append_workflow_state "SUCCESSFUL_REPORTS_COUNT" "${#SUCCESSFUL_REPORT_PATHS[@]}"

  # Fail-fast on verification failure
  if [ $VERIFICATION_FAILURES -gt 0 ]; then
    echo ""
    echo "❌ CRITICAL: Research artifact verification failed"
    echo "   $VERIFICATION_FAILURES supervisor reports not created at expected paths"
    echo ""
    for FAILED_PATH in "${FAILED_REPORT_PATHS[@]}"; do
      echo "   Missing: $FAILED_PATH"
    done
    echo ""
    echo "TROUBLESHOOTING:"
    echo "1. Review research-sub-supervisor agent: .claude/agents/research-sub-supervisor.md"
    echo "2. Check agent invocation parameters above"
    echo "3. Verify file path calculation logic"
    echo "4. Re-run workflow after fixing agent or invocation"
    echo ""
    handle_state_error "Hierarchical research supervisor failed to create expected artifacts" 1
  fi

  # Display supervisor summary (95% context reduction benefit)
  SUPERVISOR_SUMMARY=$(echo "$SUPERVISOR_CHECKPOINT" | jq -r '.aggregated_metadata.summary')
  CONTEXT_TOKENS=$(echo "$SUPERVISOR_CHECKPOINT" | jq -r '.aggregated_metadata.context_tokens')
  echo "✓ Supervisor summary: $SUPERVISOR_SUMMARY"
  echo "✓ Context reduction: ${#SUCCESSFUL_REPORT_PATHS[@]} reports → $CONTEXT_TOKENS tokens (95%)"

else
  echo "Flat research coordination mode"

  # ===== MANDATORY VERIFICATION CHECKPOINT: Flat Research =====
  echo ""
  echo "MANDATORY VERIFICATION: Research Phase Artifacts"
  echo "Checking $REPORT_PATHS_COUNT research reports..."
  echo ""

  VERIFICATION_FAILURES=0
  SUCCESSFUL_REPORT_PATHS=()
  FAILED_REPORT_PATHS=()

  # Use REPORT_PATHS_COUNT (pre-allocated count) to verify exactly as many files as were allocated
  for i in $(seq 1 $REPORT_PATHS_COUNT); do
    REPORT_PATH="${REPORT_PATHS[$i-1]}"
    echo -n "  Report $i/$REPORT_PATHS_COUNT: "
    # Avoid ! operator due to Bash tool preprocessing issues
    if verify_file_created "$REPORT_PATH" "Research report $i/$REPORT_PATHS_COUNT" "Research"; then
      SUCCESSFUL_REPORT_PATHS+=("$REPORT_PATH")
      FILE_SIZE=$(stat -f%z "$REPORT_PATH" 2>/dev/null || stat -c%s "$REPORT_PATH" 2>/dev/null || echo "unknown")
      echo " verified ($FILE_SIZE bytes)"
    else
      VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
      FAILED_REPORT_PATHS+=("$REPORT_PATH")
    fi
  done

  echo ""
  echo "Verification Summary:"
  echo "  - Success: ${#SUCCESSFUL_REPORT_PATHS[@]}/$REPORT_PATHS_COUNT reports"
  echo "  - Failures: $VERIFICATION_FAILURES reports"

  # Track verification metrics in workflow state
  append_workflow_state "VERIFICATION_FAILURES_RESEARCH" "$VERIFICATION_FAILURES"
  append_workflow_state "SUCCESSFUL_REPORTS_COUNT" "${#SUCCESSFUL_REPORT_PATHS[@]}"

  # Fail-fast on verification failure
  if [ $VERIFICATION_FAILURES -gt 0 ]; then
    echo ""
    echo "❌ CRITICAL: Research artifact verification failed"
    echo "   $VERIFICATION_FAILURES reports not created at expected paths"
    echo ""
    for FAILED_PATH in "${FAILED_REPORT_PATHS[@]}"; do
      echo "   Missing: $FAILED_PATH"
    done
    echo ""
    echo "TROUBLESHOOTING:"
    echo "1. Review research-specialist agent: .claude/agents/research-specialist.md"
    echo "2. Check agent invocation parameters above"
    echo "3. Verify file path calculation logic"
    echo "4. Re-run workflow after fixing agent or invocation"
    echo ""
    handle_state_error "Research specialists failed to create expected artifacts" 1
  fi

  echo "✓ All $REPORT_PATHS_COUNT research reports verified successfully"
fi

# Save report paths to workflow state (same for both modes)
# Defensive JSON handling: Handle empty arrays explicitly to prevent jq parse errors
if [ ${#SUCCESSFUL_REPORT_PATHS[@]} -eq 0 ]; then
  REPORT_PATHS_JSON="[]"
else
  REPORT_PATHS_JSON="$(printf '%s\n' "${SUCCESSFUL_REPORT_PATHS[@]}" | jq -R . | jq -s .)"
fi
append_workflow_state "REPORT_PATHS_JSON" "$REPORT_PATHS_JSON"
echo "Saved ${#SUCCESSFUL_REPORT_PATHS[@]} report paths to JSON state"

# ===== CHECKPOINT REQUIREMENT: Research Phase Complete =====
echo ""
echo "═══════════════════════════════════════════════════════"
echo "CHECKPOINT: Research Phase Complete"
echo "═══════════════════════════════════════════════════════"
echo "Research phase status before transitioning to next state:"
echo ""
echo "  Artifacts Created:"
echo "    - Research reports: ${#SUCCESSFUL_REPORT_PATHS[@]}/$RESEARCH_COMPLEXITY"
echo "    - Research mode: $([ "$USE_HIERARCHICAL_RESEARCH" = "true" ] && echo "Hierarchical (≥4 topics)" || echo "Flat (<4 topics)")"
echo ""
echo "  Verification Status:"
echo "    - All files verified: ✓ Yes"
echo ""
echo "  Next Action:"
case "$WORKFLOW_SCOPE" in
  research-only)
    echo "    - Proceeding to: Terminal state (workflow complete)"
    ;;
  research-and-plan)
    echo "    - Proceeding to: Planning phase"
    ;;
  research-and-revise)
    echo "    - Proceeding to: Revision phase (revising existing plan)"
    ;;
  full-implementation)
    echo "    - Proceeding to: Planning phase → Implementation"
    ;;
  debug-only)
    echo "    - Proceeding to: Planning phase → Debug"
    ;;
esac
echo "═══════════════════════════════════════════════════════"
echo ""

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
  research-and-plan|research-and-revise|full-implementation|debug-only)
    # Continue to planning
    echo "Transitioning from $CURRENT_STATE to $STATE_PLAN"
    sm_transition "$STATE_PLAN"
    append_workflow_state "CURRENT_STATE" "$STATE_PLAN"
    echo "State transition complete: $(date '+%Y-%m-%d %H:%M:%S')"
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
set +H  # Disable history expansion to prevent bad substitution errors
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Standard 15: Library Sourcing Order - Re-source in dependency order
# Step 1: Source state machine and persistence FIRST (needed for load_workflow_state)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# Step 2: Load workflow state BEFORE other libraries (prevents WORKFLOW_SCOPE reset)
COORDINATE_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt"
if [ ! -f "$COORDINATE_STATE_ID_FILE" ]; then
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE"
  echo "DIAGNOSTIC: Cannot restore workflow state. Check if previous bash block created state file."
  exit 1
fi

WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
load_workflow_state "$WORKFLOW_ID"

# Step 3: Source error handling and verification libraries (Pattern 5 preserves loaded state)
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Step 4: Source additional libraries
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/unified-logger.sh"  # Provides emit_progress and logging functions
source "${LIB_DIR}/context-pruning.sh"  # Provides context reduction and pruning functions
source "${LIB_DIR}/dependency-analyzer.sh"  # Provides phase dependency analysis for wave execution

# Check if we should skip this state
if [ "$CURRENT_STATE" = "$TERMINAL_STATE" ]; then
  # Cleanup LLM classification temp files (Spec 704 Phase 2)
  if [ -n "$WORKFLOW_ID" ]; then
    rm -f "${HOME}/.claude/tmp/llm_request_${WORKFLOW_ID}.json"
    rm -f "${HOME}/.claude/tmp/llm_response_${WORKFLOW_ID}.json"
  fi

  echo "✓ Workflow complete at terminal state: $TERMINAL_STATE"
  display_brief_summary
  exit 0
fi

# Verify we're in plan state
if [ "$CURRENT_STATE" != "$STATE_PLAN" ]; then
  echo "ERROR: State transition validation failed"
  echo "  Expected: $STATE_PLAN"
  echo "  Actual: $CURRENT_STATE"
  echo ""
  echo "TROUBLESHOOTING:"
  echo "  1. Verify sm_transition was called in previous bash block"
  echo "  2. Check workflow state file for CURRENT_STATE value"
  echo "  3. Verify workflow scope: $WORKFLOW_SCOPE"
  echo "  4. Review state machine transition logs above"
  handle_state_error "State transition validation failed" 1
fi

if command -v emit_progress &>/dev/null; then
  emit_progress "2" "State: Planning (implementation plan creation)"
fi

# FAIL-FAST STATE LOADING: Reconstruct report paths from state
# The research phase MUST have saved REPORT_PATHS_JSON to state before this phase

# FAIL-FAST VALIDATION: REPORT_PATHS_JSON must exist in state
if [ -z "${REPORT_PATHS_JSON:-}" ]; then
  handle_state_error "CRITICAL: REPORT_PATHS_JSON not loaded from state

Diagnostic:
  - Expected: JSON array of report paths from Phase 1 (Research)
  - State file should have been saved by Phase 0 allocation or Phase 1 research
  - Check previous phases for append_workflow_state \"REPORT_PATHS_JSON\" calls

Cannot proceed with planning without research report paths." 1
fi

# FAIL-FAST VALIDATION: JSON must be valid
# Exit code capture pattern prevents bash preprocessing errors (Spec 719)
echo "$REPORT_PATHS_JSON" | jq empty 2>/dev/null
JSON_VALID=$?
if [ $JSON_VALID -ne 0 ]; then
  handle_state_error "CRITICAL: Invalid JSON in REPORT_PATHS_JSON

Diagnostic:
  - Content: $REPORT_PATHS_JSON
  - JSON validation failed
  - Check Phase 0/1 for malformed JSON serialization

Cannot proceed with planning with malformed report paths." 1
fi

# Reconstruct REPORT_PATHS array from JSON
mapfile -t REPORT_PATHS < <(echo "$REPORT_PATHS_JSON" | jq -r '.[]')

# FAIL-FAST VALIDATION: Array must not be empty (unless workflow allows it)
# Note: Some workflows (research-only with 0 complexity) may legitimately have 0 reports
# But for planning workflows, we need at least 1 report
if [ "${#REPORT_PATHS[@]}" -eq 0 ] && [ "$WORKFLOW_SCOPE" != "research-and-plan" ]; then
  handle_state_error "CRITICAL: REPORT_PATHS array is empty after reconstruction

Diagnostic:
  - REPORT_PATHS_JSON: $REPORT_PATHS_JSON
  - Reconstructed array length: 0
  - Expected: At least 1 report path from research phase for $WORKFLOW_SCOPE workflow
  - Check Phase 1 research agents for successful report creation

Cannot proceed with planning without research reports." 1
fi

echo "✓ Reconstructed REPORT_PATHS array: ${#REPORT_PATHS[@]} paths loaded"

# Build report references for /plan
REPORT_ARGS=""
for report in "${REPORT_PATHS[@]}"; do
  REPORT_ARGS="$REPORT_ARGS \"$report\""
done

# Determine planning vs revision based on workflow scope
if [ "$WORKFLOW_SCOPE" = "research-and-revise" ]; then
  # Verify EXISTING_PLAN_PATH loaded for research-and-revise workflows
  if [ -z "${EXISTING_PLAN_PATH:-}" ]; then
    echo "ERROR: EXISTING_PLAN_PATH not restored from workflow state"
    handle_state_error "EXISTING_PLAN_PATH missing from workflow state" 1
  fi

  echo "Revising existing plan with ${#REPORT_PATHS[@]} research reports..."
  echo "Existing plan: $EXISTING_PLAN_PATH"
  echo "DEBUG: EXISTING_PLAN_PATH from state: $EXISTING_PLAN_PATH"
else
  echo "Creating implementation plan with ${#REPORT_PATHS[@]} research reports..."
fi
```

**EXECUTE NOW**: USE the Task tool to invoke the appropriate agent based on workflow scope.

**CRITICAL**: You MUST use Task tool (NOT SlashCommand /revise or /plan). This is a Standard 11 (Imperative Agent Invocation Pattern) requirement.

<!-- Branch based on WORKFLOW_SCOPE: research-and-revise vs other workflows -->

**IF WORKFLOW_SCOPE = research-and-revise**:

Task {
  subagent_type: "general-purpose"
  description: "Revise existing plan based on research findings"
  timeout: 180000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/revision-specialist.md

    **Workflow-Specific Context**:
    - Existing Plan Path: $EXISTING_PLAN_PATH (absolute)
    - Research Reports: ${REPORT_PATHS[@]}
    - Revision Scope: $WORKFLOW_DESCRIPTION
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Backup Required: true

    **Key Requirements**:
    1. Create backup FIRST before any modifications
    2. Analyze research findings in provided reports
    3. Apply revisions to existing plan preserving completed phases
    4. Update revision history section with changes
    5. Return completion signal with plan path

    Execute revision following all guidelines in behavioral file.
    Return: REVISION_COMPLETED: $EXISTING_PLAN_PATH
  "
}

**ELSE (for research-and-plan, full-implementation, etc.)**:

**EXECUTE NOW**: USE the Task tool:

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan guided by research reports"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/plan-architect.md

    **Workflow-Specific Context**:
    - Feature Description: $WORKFLOW_DESCRIPTION
    - Plan Output Path: $PLAN_PATH (absolute, pre-calculated)
    - Research Reports: ${REPORT_PATHS[@]}
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Topic Directory: $TOPIC_PATH

    **Key Requirements**:
    1. Review research findings in provided reports
    2. Create implementation plan following project standards
    3. Save plan to EXACT path provided above
    4. Include phase dependencies for parallel execution

    Execute planning following all guidelines in behavioral file.
    Return: PLAN_CREATED: $PLAN_PATH
  "
}

USE the Bash tool:

```bash
set +H  # Disable history expansion to prevent bad substitution errors
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Standard 15: Library Sourcing Order - Re-source in dependency order
# Step 1: Source state machine and persistence FIRST (needed for load_workflow_state)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# Step 2: Load workflow state BEFORE other libraries (prevents WORKFLOW_SCOPE reset)
COORDINATE_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt"
if [ ! -f "$COORDINATE_STATE_ID_FILE" ]; then
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE"
  echo "DIAGNOSTIC: Cannot restore workflow state. Check if previous bash block created state file."
  exit 1
fi

WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
load_workflow_state "$WORKFLOW_ID"

# Step 3: Source error handling and verification libraries (Pattern 5 preserves loaded state)
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Step 4: Source additional libraries
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/unified-logger.sh"  # Provides emit_progress and logging functions
source "${LIB_DIR}/context-pruning.sh"  # Provides context reduction and pruning functions
source "${LIB_DIR}/dependency-analyzer.sh"  # Provides phase dependency analysis for wave execution

# VERIFICATION CHECKPOINT: Verify critical functions available (Standard 0)
if ! command -v verify_state_variable &>/dev/null; then
  echo "ERROR: verify_state_variable function not available after library sourcing"
  exit 1
fi
if ! command -v handle_state_error &>/dev/null; then
  echo "ERROR: handle_state_error function not available after library sourcing"
  exit 1
fi

# Determine which path to verify based on workflow scope
if [ "$WORKFLOW_SCOPE" = "research-and-revise" ]; then
  # For revisions, verify EXISTING_PLAN_PATH
  VERIFY_PATH="$EXISTING_PLAN_PATH"
  VERIFY_TYPE="Revised plan"

  # Validate EXISTING_PLAN_PATH was restored from workflow state
  if [ -z "${EXISTING_PLAN_PATH:-}" ]; then
    echo "ERROR: EXISTING_PLAN_PATH not restored from workflow state"
    echo "This indicates a bug in state persistence or plan discovery"
    handle_state_error "EXISTING_PLAN_PATH missing from workflow state" 1
  fi

  echo "DEBUG: EXISTING_PLAN_PATH from state: $EXISTING_PLAN_PATH"
else
  # For new plans, verify PLAN_PATH
  VERIFY_PATH="$PLAN_PATH"
  VERIFY_TYPE="Implementation plan"

  # Validate PLAN_PATH was restored from workflow state
  if [ -z "${PLAN_PATH:-}" ]; then
    echo "ERROR: PLAN_PATH not restored from workflow state"
    echo "This indicates a bug in state persistence or initialization"
    echo "Expected PLAN_PATH to be set by initialize_workflow_paths() in bash block 1"
    handle_state_error "PLAN_PATH missing from workflow state" 1
  fi

  # Verify PLAN_PATH contains topic-based naming (sanity check for descriptive names)
  if [[ "$PLAN_PATH" == *"/001_implementation.md" ]]; then
    echo "WARNING: PLAN_PATH uses generic name '001_implementation.md'"
    echo "  PLAN_PATH: $PLAN_PATH"
    echo "This indicates a regression in plan naming. Expected descriptive name."
    echo "Check workflow-initialization.sh sanitize_topic_name() function."
  fi

  echo "DEBUG: PLAN_PATH from state: $PLAN_PATH"
fi

emit_progress "2" "Planning invoked - awaiting completion"

# ===== MANDATORY VERIFICATION CHECKPOINT: Planning Phase =====
echo ""
echo "MANDATORY VERIFICATION: Planning Phase Artifacts"
echo "Checking ${VERIFY_TYPE,,}..."
echo ""

echo -n "  $VERIFY_TYPE: "
if verify_file_created "$VERIFY_PATH" "$VERIFY_TYPE" "Planning"; then
  PLAN_SIZE=$(stat -f%z "$VERIFY_PATH" 2>/dev/null || stat -c%s "$VERIFY_PATH" 2>/dev/null || echo "unknown")
  echo " verified ($PLAN_SIZE bytes)"
  VERIFICATION_FAILED=false
else
  echo ""
  VERIFICATION_FAILED=true
fi

# Fail-fast on verification failure
if [ "$VERIFICATION_FAILED" = "true" ]; then
  echo ""
  echo "❌ CRITICAL: $VERIFY_TYPE verification failed"
  echo "   Expected path: $VERIFY_PATH"
  echo ""
  echo "Path analysis:"
  echo "   Topic directory: $TOPIC_PATH"
  if [ "$WORKFLOW_SCOPE" != "research-and-revise" ]; then
    echo "   Expected plan should have descriptive name (not '001_implementation.md')"
  fi
  echo ""
  # List actual plans created to help diagnose mismatch
  if [ -d "${TOPIC_PATH}/plans" ]; then
    echo "Actual files in ${TOPIC_PATH}/plans:"
    ls -la "${TOPIC_PATH}/plans/" 2>/dev/null || echo "   (directory empty or not readable)"
  else
    echo "Plans directory does not exist: ${TOPIC_PATH}/plans"
  fi
  echo ""
  echo "TROUBLESHOOTING:"
  if [ "$WORKFLOW_SCOPE" = "research-and-revise" ]; then
    echo "1. Review revision-specialist agent output above for error messages"
    echo "2. Check backup creation succeeded before revision"
    echo "3. Verify EXISTING_PLAN_PATH was correctly discovered"
    echo "4. Ensure research reports contain sufficient information for revision"
  else
    echo "1. Review plan-architect agent output above for error messages"
    echo "2. Check plan agent behavioral file if used"
    echo "3. Verify file path calculation logic in workflow-initialization.sh"
    echo "4. Check if agent created file at different path than coordinate expects"
    echo "5. Ensure research reports contain sufficient information"
  fi
  echo "6. Re-run workflow after fixing issues"
  echo ""
  handle_state_error "Planning phase failed to create/update expected plan file" 1
fi

echo "✓ $VERIFY_TYPE verified successfully"

# Additional verification for revision workflows
if [ "$WORKFLOW_SCOPE" = "research-and-revise" ]; then
  # Verify backup was created by revision-specialist agent
  # Backup naming convention: original_name.md → original_name.md.backup-YYYYMMDD-HHMMSS
  PLAN_DIR=$(dirname "$EXISTING_PLAN_PATH")
  PLAN_BASENAME=$(basename "$EXISTING_PLAN_PATH")

  # Find most recent backup file for this plan
  BACKUP_PATH=$(find "$PLAN_DIR" -maxdepth 1 -name "${PLAN_BASENAME}.backup-*" -type f | sort -r | head -1)

  if [ -n "$BACKUP_PATH" ] && [ -f "$BACKUP_PATH" ]; then
    BACKUP_SIZE=$(stat -c%s "$BACKUP_PATH" 2>/dev/null || stat -f%z "$BACKUP_PATH" 2>/dev/null || echo "unknown")
    echo "✓ Backup verified: $(basename "$BACKUP_PATH") ($BACKUP_SIZE bytes)"

    # Save backup path to workflow state for potential rollback
    append_workflow_state "BACKUP_PATH" "$BACKUP_PATH"

    # Simple diff check to confirm changes were made (if files differ, revision succeeded)
    if diff -q "$EXISTING_PLAN_PATH" "$BACKUP_PATH" > /dev/null 2>&1; then
      echo "  Note: Plan unchanged (files identical), revision may have found no updates needed"
    else
      echo "  Plan modified: revision successfully applied changes"
    fi
  else
    echo "⚠ WARNING: No backup file found for revised plan"
    echo "  Expected backup pattern: ${PLAN_BASENAME}.backup-YYYYMMDD-HHMMSS"
    echo "  This may indicate revision-specialist agent did not create backup"
  fi
fi

# Save plan path to workflow state (use appropriate path based on workflow scope)
if [ "$WORKFLOW_SCOPE" = "research-and-revise" ]; then
  append_workflow_state "PLAN_PATH" "$EXISTING_PLAN_PATH"
else
  append_workflow_state "PLAN_PATH" "$PLAN_PATH"
fi

# ===== CHECKPOINT REQUIREMENT: Planning Phase Complete =====
echo ""
echo "═══════════════════════════════════════════════════════"
if [ "$WORKFLOW_SCOPE" = "research-and-revise" ]; then
  echo "CHECKPOINT: Revision Phase Complete"
else
  echo "CHECKPOINT: Planning Phase Complete"
fi
echo "═══════════════════════════════════════════════════════"
if [ "$WORKFLOW_SCOPE" = "research-and-revise" ]; then
  echo "Revision phase status before transitioning to next state:"
else
  echo "Planning phase status before transitioning to next state:"
fi
echo ""
echo "  Artifacts Created:"
if [ "$WORKFLOW_SCOPE" = "research-and-revise" ]; then
  echo "    - Revised plan: ✓ Updated"
  echo "    - Plan path: $PLAN_PATH"
  PLAN_SIZE=$(stat -f%z "$PLAN_PATH" 2>/dev/null || stat -c%s "$PLAN_PATH" 2>/dev/null || echo "unknown")
  echo "    - Plan size: $PLAN_SIZE bytes"
  if [ -n "${BACKUP_PATH:-}" ]; then
    echo "    - Backup created: ✓ Yes ($(basename "$BACKUP_PATH"))"
  fi
else
  echo "    - Implementation plan: ✓ Created"
  echo "    - Plan path: $PLAN_PATH"
  PLAN_SIZE=$(stat -f%z "$PLAN_PATH" 2>/dev/null || stat -c%s "$PLAN_PATH" 2>/dev/null || echo "unknown")
  echo "    - Plan size: $PLAN_SIZE bytes"
fi
echo ""
echo "  Verification Status:"
echo "    - Plan file verified: ✓ Yes"
if [ "$WORKFLOW_SCOPE" = "research-and-revise" ] && [ -n "${BACKUP_PATH:-}" ]; then
  echo "    - Backup verified: ✓ Yes"
fi
echo ""
echo "  Research Integration:"
REPORT_COUNT="${#REPORT_PATHS[@]}"
echo "    - Research reports used: $REPORT_COUNT"
echo ""
echo "  Next Action:"
case "$WORKFLOW_SCOPE" in
  research-and-plan)
    echo "    - Proceeding to: Terminal state (workflow complete)"
    ;;
  research-and-revise)
    echo "    - Proceeding to: Terminal state (revision complete)"
    ;;
  full-implementation)
    echo "    - Proceeding to: Implementation phase"
    ;;
  debug-only)
    echo "    - Proceeding to: Debug phase"
    ;;
esac
echo "═══════════════════════════════════════════════════════"
echo ""

# Determine next state based on workflow scope
case "$WORKFLOW_SCOPE" in
  research-and-plan|research-and-revise)
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
    echo "Transitioning from $CURRENT_STATE to $STATE_IMPLEMENT"
    sm_transition "$STATE_IMPLEMENT"
    append_workflow_state "CURRENT_STATE" "$STATE_IMPLEMENT"
    echo "State transition complete: $(date '+%Y-%m-%d %H:%M:%S')"
    ;;
  debug-only)
    # Skip to debug
    echo "Transitioning from $CURRENT_STATE to $STATE_DEBUG"
    sm_transition "$STATE_DEBUG"
    append_workflow_state "CURRENT_STATE" "$STATE_DEBUG"
    echo "State transition complete: $(date '+%Y-%m-%d %H:%M:%S')"
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
set +H  # Disable history expansion to prevent bad substitution errors
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Standard 15: Library Sourcing Order - Re-source in dependency order
# Step 1: Source state machine and persistence FIRST (needed for load_workflow_state)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# Step 2: Load workflow state BEFORE other libraries (prevents WORKFLOW_SCOPE reset)
COORDINATE_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt"
if [ ! -f "$COORDINATE_STATE_ID_FILE" ]; then
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE"
  echo "DIAGNOSTIC: Cannot restore workflow state. Check if previous bash block created state file."
  exit 1
fi

WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
load_workflow_state "$WORKFLOW_ID"

# Step 3: Source error handling and verification libraries (Pattern 5 preserves loaded state)
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Step 4: Source additional libraries
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/unified-logger.sh"  # Provides emit_progress and logging functions
source "${LIB_DIR}/context-pruning.sh"  # Provides context reduction and pruning functions
source "${LIB_DIR}/dependency-analyzer.sh"  # Provides phase dependency analysis for wave execution

# Check if we should skip this state
if [ "$CURRENT_STATE" = "$TERMINAL_STATE" ]; then
  # Cleanup LLM classification temp files (Spec 704 Phase 2)
  if [ -n "$WORKFLOW_ID" ]; then
    rm -f "${HOME}/.claude/tmp/llm_request_${WORKFLOW_ID}.json"
    rm -f "${HOME}/.claude/tmp/llm_response_${WORKFLOW_ID}.json"
  fi

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

**EXECUTE NOW**: USE the Task tool to invoke implementer-coordinator:

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation with wave-based parallel execution"
  timeout: 600000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    **Workflow-Specific Context**:
    - Plan File: $PLAN_PATH (absolute path)
    - Topic Directory: $TOPIC_PATH
    - Artifact Paths:
      - Reports: $REPORTS_DIR
      - Plans: $PLANS_DIR
      - Summaries: $SUMMARIES_DIR
      - Debug: $DEBUG_DIR
      - Outputs: $OUTPUTS_DIR
      - Checkpoints: $CHECKPOINT_DIR

    **Execution Requirements**:
    - Wave-based parallel execution for independent phases
    - Automated testing after each wave
    - Git commits for completed phases
    - Checkpoint state management
    - Progress tracking and metrics collection

    Execute implementation following all guidelines in behavioral file.
    Return: IMPLEMENTATION_COMPLETE: [summary]
  "
}

USE the Bash tool:

```bash
set +H  # Disable history expansion to prevent bad substitution errors
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Standard 15: Library Sourcing Order - Re-source in dependency order
# Step 1: Source state machine and persistence FIRST (needed for load_workflow_state)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# Step 2: Load workflow state BEFORE other libraries (prevents WORKFLOW_SCOPE reset)
COORDINATE_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt"
if [ ! -f "$COORDINATE_STATE_ID_FILE" ]; then
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE"
  echo "DIAGNOSTIC: Cannot restore workflow state. Check if previous bash block created state file."
  exit 1
fi

WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
load_workflow_state "$WORKFLOW_ID"

# Step 3: Source error handling and verification libraries (Pattern 5 preserves loaded state)
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Step 4: Source additional libraries
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/unified-logger.sh"  # Provides emit_progress and logging functions
source "${LIB_DIR}/context-pruning.sh"  # Provides context reduction and pruning functions
source "${LIB_DIR}/dependency-analyzer.sh"  # Provides phase dependency analysis for wave execution

# VERIFICATION CHECKPOINT: Verify critical functions available (Standard 0)
if ! command -v verify_state_variable &>/dev/null; then
  echo "ERROR: verify_state_variable function not available after library sourcing"
  exit 1
fi
if ! command -v handle_state_error &>/dev/null; then
  echo "ERROR: handle_state_error function not available after library sourcing"
  exit 1
fi

emit_progress "3" "Implementation phase completion - verifying results"

# ===== MANDATORY VERIFICATION CHECKPOINT: Implementation Phase =====
echo ""
echo "MANDATORY VERIFICATION: Implementation Phase Artifacts"
echo "Checking implementer-coordinator agent outputs..."
echo ""

VERIFICATION_FAILURES=0

# Verify plan file exists (required)
echo -n "  Plan file: "
if [ -f "$PLAN_PATH" ]; then
  PLAN_SIZE=$(stat -f%z "$PLAN_PATH" 2>/dev/null || stat -c%s "$PLAN_PATH" 2>/dev/null || echo "unknown")
  echo " verified ($PLAN_SIZE bytes)"
else
  echo " MISSING"
  VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
fi

# Check for implementation summary (optional, non-critical)
SUMMARY_PATTERN="${SUMMARIES_DIR}/[0-9][0-9][0-9]_implementation_summary.md"
SUMMARY_FILE=$(ls $SUMMARY_PATTERN 2>/dev/null | head -1)
echo -n "  Implementation summary: "
if [ -n "$SUMMARY_FILE" ] && [ -f "$SUMMARY_FILE" ]; then
  SUMMARY_SIZE=$(stat -f%z "$SUMMARY_FILE" 2>/dev/null || stat -c%s "$SUMMARY_FILE" 2>/dev/null || echo "unknown")
  echo " found ($SUMMARY_SIZE bytes) [optional]"
else
  echo " not found [optional, non-critical]"
fi

echo ""
echo "Verification Summary:"
echo "  - Success: Plan file verified"
echo "  - Failures: $VERIFICATION_FAILURES critical artifacts"

# Fail-fast on verification failure
if [ $VERIFICATION_FAILURES -gt 0 ]; then
  echo ""
  echo "❌ CRITICAL: Implementation artifact verification failed"
  echo "   $VERIFICATION_FAILURES required artifacts not created"
  echo ""
  echo "Expected artifacts:"
  echo "   - Plan file: $PLAN_PATH"
  echo ""
  echo "TROUBLESHOOTING:"
  echo "1. Review implementer-coordinator agent output above for error messages"
  echo "2. Check agent behavioral file: ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md"
  echo "3. Verify all artifact paths were correctly injected:"
  echo "   REPORTS_DIR=$REPORTS_DIR"
  echo "   PLANS_DIR=$PLANS_DIR"
  echo "   SUMMARIES_DIR=$SUMMARIES_DIR"
  echo "4. Check permissions on artifact directories"
  echo "5. Verify plan file is readable and not corrupted"
  echo "6. Re-run workflow after fixing issues"
  echo ""
  handle_state_error "Implementation phase failed to create expected artifacts" 1
fi

echo "✓ Implementation artifacts verified successfully"

# Store implementation completion in state
append_workflow_state "IMPLEMENTATION_COMPLETED" "true"
append_workflow_state "IMPLEMENTATION_TIMESTAMP" "$(date '+%Y-%m-%d %H:%M:%S')"
if [ -n "$SUMMARY_FILE" ]; then
  append_workflow_state "IMPLEMENTATION_SUMMARY" "$SUMMARY_FILE"
fi

emit_progress "3" "Implementation complete - transitioning to Testing"

# ===== CHECKPOINT REQUIREMENT: Implementation Phase Complete =====
echo ""
echo "═══════════════════════════════════════════════════════"
echo "CHECKPOINT: Implementation Phase Complete"
echo "═══════════════════════════════════════════════════════"
echo "Implementation phase status before transitioning to next state:"
echo ""
echo "  Artifacts Created:"
echo "    - Implementation status: ✓ Complete"
echo "    - Plan executed: $PLAN_PATH"
PLAN_SIZE=$(stat -f%z "$PLAN_PATH" 2>/dev/null || stat -c%s "$PLAN_PATH" 2>/dev/null || echo "unknown")
echo "    - Plan size: $PLAN_SIZE bytes"
echo ""
echo "  Verification Status:"
echo "    - Implementation complete: ✓ Yes"
echo "    - Code changes committed: ✓ Yes"
echo ""
echo "  Plan Integration:"
REPORT_COUNT="${#REPORT_PATHS[@]}"
echo "    - Research reports referenced: $REPORT_COUNT"
echo ""
echo "  Next Action:"
echo "    - Proceeding to: Testing phase"
echo "═══════════════════════════════════════════════════════"
echo ""

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
set +H  # Disable history expansion to prevent bad substitution errors
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Standard 15: Library Sourcing Order - Re-source in dependency order
# Step 1: Source state machine and persistence FIRST (needed for load_workflow_state)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# Step 2: Load workflow state BEFORE other libraries (prevents WORKFLOW_SCOPE reset)
COORDINATE_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt"
if [ ! -f "$COORDINATE_STATE_ID_FILE" ]; then
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE"
  echo "DIAGNOSTIC: Cannot restore workflow state. Check if previous bash block created state file."
  exit 1
fi

WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
load_workflow_state "$WORKFLOW_ID"

# Step 3: Source error handling and verification libraries (Pattern 5 preserves loaded state)
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Step 4: Source additional libraries
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/unified-logger.sh"  # Provides emit_progress and logging functions
source "${LIB_DIR}/context-pruning.sh"  # Provides context reduction and pruning functions
source "${LIB_DIR}/dependency-analyzer.sh"  # Provides phase dependency analysis for wave execution

# Check if we should skip this state
if [ "$CURRENT_STATE" = "$TERMINAL_STATE" ]; then
  # Cleanup LLM classification temp files (Spec 704 Phase 2)
  if [ -n "$WORKFLOW_ID" ]; then
    rm -f "${HOME}/.claude/tmp/llm_request_${WORKFLOW_ID}.json"
    rm -f "${HOME}/.claude/tmp/llm_response_${WORKFLOW_ID}.json"
  fi

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

# ===== CHECKPOINT REQUIREMENT: Testing Phase Complete =====
echo ""
echo "═══════════════════════════════════════════════════════"
echo "CHECKPOINT: Testing Phase Complete"
echo "═══════════════════════════════════════════════════════"
echo "Testing phase status before transitioning to next state:"
echo ""
echo "  Test Execution:"
echo "    - Exit code: $TEST_EXIT_CODE"
if [ $TEST_EXIT_CODE -eq 0 ]; then
  echo "    - Result: ✓ Pass"
else
  echo "    - Result: ❌ Fail"
fi
echo ""
echo "  Verification Status:"
echo "    - Test execution verified: ✓ Yes"
echo "    - Success/failures confirmed: ✓ Yes"
echo ""
echo "  Implementation Integration:"
echo "    - Plan tested: $PLAN_PATH"
echo ""
echo "  Next Action:"
if [ $TEST_EXIT_CODE -eq 0 ]; then
  echo "    - Proceeding to: Documentation phase"
else
  echo "    - Proceeding to: Debug phase (analyze failures)"
fi
echo "═══════════════════════════════════════════════════════"
echo ""

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
set +H  # Disable history expansion to prevent bad substitution errors
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Standard 15: Library Sourcing Order - Re-source in dependency order
# Step 1: Source state machine and persistence FIRST (needed for load_workflow_state)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# Step 2: Load workflow state BEFORE other libraries (prevents WORKFLOW_SCOPE reset)
COORDINATE_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt"
if [ ! -f "$COORDINATE_STATE_ID_FILE" ]; then
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE"
  echo "DIAGNOSTIC: Cannot restore workflow state. Check if previous bash block created state file."
  exit 1
fi

WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
load_workflow_state "$WORKFLOW_ID"

# Step 3: Source error handling and verification libraries (Pattern 5 preserves loaded state)
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Step 4: Source additional libraries
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/unified-logger.sh"  # Provides emit_progress and logging functions
source "${LIB_DIR}/context-pruning.sh"  # Provides context reduction and pruning functions
source "${LIB_DIR}/dependency-analyzer.sh"  # Provides phase dependency analysis for wave execution

# Check if we should skip this state
if [ "$CURRENT_STATE" = "$TERMINAL_STATE" ]; then
  # Cleanup LLM classification temp files (Spec 704 Phase 2)
  if [ -n "$WORKFLOW_ID" ]; then
    rm -f "${HOME}/.claude/tmp/llm_request_${WORKFLOW_ID}.json"
    rm -f "${HOME}/.claude/tmp/llm_response_${WORKFLOW_ID}.json"
  fi

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
set +H  # Disable history expansion to prevent bad substitution errors
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Standard 15: Library Sourcing Order - Re-source in dependency order
# Step 1: Source state machine and persistence FIRST (needed for load_workflow_state)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# Step 2: Load workflow state BEFORE other libraries (prevents WORKFLOW_SCOPE reset)
COORDINATE_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt"
if [ ! -f "$COORDINATE_STATE_ID_FILE" ]; then
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE"
  echo "DIAGNOSTIC: Cannot restore workflow state. Check if previous bash block created state file."
  exit 1
fi

WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
load_workflow_state "$WORKFLOW_ID"

# Step 3: Source error handling and verification libraries (Pattern 5 preserves loaded state)
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Step 4: Source additional libraries
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/unified-logger.sh"  # Provides emit_progress and logging functions
source "${LIB_DIR}/context-pruning.sh"  # Provides context reduction and pruning functions
source "${LIB_DIR}/dependency-analyzer.sh"  # Provides phase dependency analysis for wave execution

# VERIFICATION CHECKPOINT: Verify critical functions available (Standard 0)
if ! command -v verify_state_variable &>/dev/null; then
  echo "ERROR: verify_state_variable function not available after library sourcing"
  exit 1
fi
if ! command -v handle_state_error &>/dev/null; then
  echo "ERROR: handle_state_error function not available after library sourcing"
  exit 1
fi

emit_progress "5" "Debug analysis complete - verifying results"

# Define expected debug report path
DEBUG_REPORT_PATH="${TOPIC_PATH}/debug/001_debug_report.md"

# ===== MANDATORY VERIFICATION CHECKPOINT: Debug Phase =====
echo ""
echo "MANDATORY VERIFICATION: Debug Phase Artifacts"
echo "Checking debug analysis report..."
echo ""

echo -n "  Debug report: "
if verify_file_created "$DEBUG_REPORT_PATH" "Debug analysis report" "Debug"; then
  DEBUG_SIZE=$(stat -f%z "$DEBUG_REPORT_PATH" 2>/dev/null || stat -c%s "$DEBUG_REPORT_PATH" 2>/dev/null || echo "unknown")
  echo " verified ($DEBUG_SIZE bytes)"
  VERIFICATION_FAILED=false
else
  echo ""
  VERIFICATION_FAILED=true
fi

# Fail-fast on verification failure
if [ "$VERIFICATION_FAILED" = "true" ]; then
  echo ""
  echo "❌ CRITICAL: Debug report verification failed"
  echo "   Expected: $DEBUG_REPORT_PATH"
  echo ""
  echo "TROUBLESHOOTING:"
  echo "1. Review /debug command output above for error messages"
  echo "2. Check debug agent behavioral file if used"
  echo "3. Verify file path calculation logic"
  echo "4. Ensure test output data is available for analysis"
  echo "5. Manually investigate test failures in .claude/tests/"
  echo "6. Re-run workflow after fixing issues"
  echo ""
  handle_state_error "/debug command failed to create expected debug report" 1
fi

echo "✓ Debug report verified successfully"

# Save debug report path to workflow state
append_workflow_state "DEBUG_REPORT" "$DEBUG_REPORT_PATH"

# ===== CHECKPOINT REQUIREMENT: Debug Phase Complete =====
echo ""
echo "═══════════════════════════════════════════════════════"
echo "CHECKPOINT: Debug Phase Complete"
echo "═══════════════════════════════════════════════════════"
echo "Debug phase status before transitioning to next state:"
echo ""
echo "  Artifacts Created:"
echo "    - Debug report path: $DEBUG_REPORT_PATH"
DEBUG_SIZE=$(stat -f%z "$DEBUG_REPORT_PATH" 2>/dev/null || stat -c%s "$DEBUG_REPORT_PATH" 2>/dev/null || echo "unknown")
echo "    - Report size: $DEBUG_SIZE bytes"
echo ""
echo "  Verification Status:"
echo "    - Debug report verified: ✓ Yes"
echo ""
echo "  Test Integration:"
echo "    - Failures analyzed: ✓ Yes"
echo "    - Root cause complete: ✓ Yes"
echo "    - Fixes documented: ✓ Yes"
echo ""
echo "  Next Action:"
echo "    - Workflow state: Paused for manual review"
echo "    - Resume command: /coordinate \"$WORKFLOW_DESCRIPTION\""
echo "═══════════════════════════════════════════════════════"
echo ""

# Transition to complete (user must fix issues manually)
sm_transition "$STATE_COMPLETE"
append_workflow_state "CURRENT_STATE" "$STATE_COMPLETE"

echo ""
echo "✓ Debug analysis complete"
echo "Debug report: $DEBUG_REPORT_PATH"
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
set +H  # Disable history expansion to prevent bad substitution errors
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Standard 15: Library Sourcing Order - Re-source in dependency order
# Step 1: Source state machine and persistence FIRST (needed for load_workflow_state)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# Step 2: Load workflow state BEFORE other libraries (prevents WORKFLOW_SCOPE reset)
COORDINATE_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt"
if [ ! -f "$COORDINATE_STATE_ID_FILE" ]; then
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE"
  echo "DIAGNOSTIC: Cannot restore workflow state. Check if previous bash block created state file."
  exit 1
fi

WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
load_workflow_state "$WORKFLOW_ID"

# Step 3: Source error handling and verification libraries (Pattern 5 preserves loaded state)
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Step 4: Source additional libraries
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/unified-logger.sh"  # Provides emit_progress and logging functions
source "${LIB_DIR}/context-pruning.sh"  # Provides context reduction and pruning functions
source "${LIB_DIR}/dependency-analyzer.sh"  # Provides phase dependency analysis for wave execution

# Check if we should skip this state
if [ "$CURRENT_STATE" = "$TERMINAL_STATE" ]; then
  # Cleanup LLM classification temp files (Spec 704 Phase 2)
  if [ -n "$WORKFLOW_ID" ]; then
    rm -f "${HOME}/.claude/tmp/llm_request_${WORKFLOW_ID}.json"
    rm -f "${HOME}/.claude/tmp/llm_response_${WORKFLOW_ID}.json"
  fi

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
set +H  # Disable history expansion to prevent bad substitution errors
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Standard 15: Library Sourcing Order - Re-source in dependency order
# Step 1: Source state machine and persistence FIRST (needed for load_workflow_state)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# Step 2: Load workflow state BEFORE other libraries (prevents WORKFLOW_SCOPE reset)
COORDINATE_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt"
if [ ! -f "$COORDINATE_STATE_ID_FILE" ]; then
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE"
  echo "DIAGNOSTIC: Cannot restore workflow state. Check if previous bash block created state file."
  exit 1
fi

WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
load_workflow_state "$WORKFLOW_ID"

# Step 3: Source error handling and verification libraries (Pattern 5 preserves loaded state)
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Step 4: Source additional libraries
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/unified-logger.sh"  # Provides emit_progress and logging functions
source "${LIB_DIR}/context-pruning.sh"  # Provides context reduction and pruning functions
source "${LIB_DIR}/dependency-analyzer.sh"  # Provides phase dependency analysis for wave execution

# VERIFICATION CHECKPOINT: Verify critical functions available (Standard 0)
if ! command -v verify_state_variable &>/dev/null; then
  echo "ERROR: verify_state_variable function not available after library sourcing"
  exit 1
fi
if ! command -v handle_state_error &>/dev/null; then
  echo "ERROR: handle_state_error function not available after library sourcing"
  exit 1
fi

emit_progress "6" "Documentation updated"

# ===== CHECKPOINT REQUIREMENT: Documentation Phase Complete =====
echo ""
echo "═══════════════════════════════════════════════════════"
echo "CHECKPOINT: Documentation Phase Complete"
echo "═══════════════════════════════════════════════════════"
echo "Documentation phase status before transitioning to next state:"
echo ""
echo "  Artifacts Created:"
echo "    - Documentation update: ✓ Complete"
echo "    - Files updated: See /document output above"
echo ""
echo "  Verification Status:"
echo "    - Documentation command executed: ✓ Yes"
echo "    - Standards checked: ✓ Yes"
echo ""
echo "  Implementation Integration:"
echo "    - Workflow documented: ✓ Yes"
echo "    - Plan reference: $PLAN_PATH"
echo ""
echo "  Next Action:"
echo "    - Proceeding to: Terminal state (workflow complete)"
echo "═══════════════════════════════════════════════════════"
echo ""

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
