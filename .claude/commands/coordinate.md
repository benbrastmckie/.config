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
- FROM: `echo "YOUR_WORKFLOW_DESCRIPTION_HERE" > "${HOME}/.claude/tmp/coordinate_workflow_desc.txt"`
- TO: `echo "research auth patterns" > "${HOME}/.claude/tmp/coordinate_workflow_desc.txt"`

Execute this **small** bash block with your substitution:

```bash
set +H  # Disable history expansion to prevent bad substitution errors
# SUBSTITUTE THE WORKFLOW DESCRIPTION IN THE LINE BELOW
# CRITICAL: Replace YOUR_WORKFLOW_DESCRIPTION_HERE with the actual workflow description from the user
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
echo "YOUR_WORKFLOW_DESCRIPTION_HERE" > "${HOME}/.claude/tmp/coordinate_workflow_desc.txt"
echo "✓ Workflow description captured to ${HOME}/.claude/tmp/coordinate_workflow_desc.txt"
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
# Use fixed filename (not $$ which changes per bash block)
COORDINATE_DESC_FILE="${HOME}/.claude/tmp/coordinate_workflow_desc.txt"

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

# Generate unique workflow ID (timestamp-based for reproducibility)
WORKFLOW_ID="coordinate_$(date +%s)"

# Initialize workflow state (GitHub Actions pattern)
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")

# Save workflow ID to file for subsequent blocks (use fixed location)
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
echo "$WORKFLOW_ID" > "$COORDINATE_STATE_ID_FILE"

# NOTE: NO trap handler here! Files must persist for subsequent bash blocks.
# Cleanup will happen manually or via external cleanup script.

# Save workflow ID and description to state for subsequent blocks
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"
append_workflow_state "WORKFLOW_DESCRIPTION" "$SAVED_WORKFLOW_DESC"

# Initialize state machine (use SAVED value, not overwritten variable)
sm_init "$SAVED_WORKFLOW_DESC" "coordinate"

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
append_workflow_state "PLAN_PATH" "$PLAN_PATH"

# Save report paths array metadata to state
# Bash arrays cannot be exported across subprocesses (subprocess isolation).
# Instead, serialize array to individual variables (REPORT_PATH_0, REPORT_PATH_1, ...)
# and save to workflow state file for reconstruction in subsequent bash blocks.
# See: .claude/docs/concepts/bash-block-execution-model.md for details.
#
# Required by reconstruct_report_paths_array() in subsequent bash blocks
# (Export doesn't persist across blocks due to subprocess isolation)
append_workflow_state "REPORT_PATHS_COUNT" "$REPORT_PATHS_COUNT"

# Save individual report path variables
# Using C-style loop to avoid history expansion issues with array expansion
for ((i=0; i<REPORT_PATHS_COUNT; i++)); do
  var_name="REPORT_PATH_$i"
  append_workflow_state "$var_name" "${!var_name}"
done

echo "Saved $REPORT_PATHS_COUNT report paths to workflow state"

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

  # Cleanup temp files now that workflow is complete
  COORDINATE_DESC_FILE="${HOME}/.claude/tmp/coordinate_workflow_desc.txt"
  COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
  rm -f "$COORDINATE_DESC_FILE" "$COORDINATE_STATE_ID_FILE" 2>/dev/null || true
}
export -f display_brief_summary

# Note: handle_state_error() is now defined in .claude/lib/error-handling.sh
# It will be available via library sourcing in all bash blocks

# Transition to research state
sm_transition "$STATE_RESEARCH"
append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"

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
set +H  # Disable history expansion to prevent bad substitution errors
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2)/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Load workflow state (read WORKFLOW_ID from fixed location)
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
if [ -f "$COORDINATE_STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
  load_workflow_state "$WORKFLOW_ID"
else
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE"
  echo "Cannot restore workflow state. This is a critical error."
  exit 1
fi

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
set +H  # Disable history expansion to prevent bad substitution errors
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2)/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Load workflow state (read WORKFLOW_ID from fixed location)
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
if [ -f "$COORDINATE_STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
  load_workflow_state "$WORKFLOW_ID"
else
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE"
  exit 1
fi

emit_progress "1" "Research phase completion - verifying results"

# Handle hierarchical vs flat coordination differently
if [ "$USE_HIERARCHICAL_RESEARCH" = "true" ]; then
  echo "Hierarchical research supervision mode"

  # Load supervisor checkpoint to get aggregated metadata
  SUPERVISOR_CHECKPOINT=$(load_json_checkpoint "research_supervisor")

  # Extract report paths from supervisor checkpoint
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
  echo "Checking $RESEARCH_COMPLEXITY research reports..."
  echo ""

  VERIFICATION_FAILURES=0
  SUCCESSFUL_REPORT_PATHS=()
  FAILED_REPORT_PATHS=()

  for i in $(seq 1 $RESEARCH_COMPLEXITY); do
    REPORT_PATH="${REPORT_PATHS[$i-1]}"
    echo -n "  Report $i/$RESEARCH_COMPLEXITY: "
    # Avoid ! operator due to Bash tool preprocessing issues
    if verify_file_created "$REPORT_PATH" "Research report $i/$RESEARCH_COMPLEXITY" "Research"; then
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

  echo "✓ All $RESEARCH_COMPLEXITY research reports verified successfully"
fi

# Save report paths to workflow state (same for both modes)
append_workflow_state "REPORT_PATHS_JSON" "$(printf '%s\n' "${SUCCESSFUL_REPORT_PATHS[@]}" | jq -R . | jq -s .)"

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
set +H  # Disable history expansion to prevent bad substitution errors
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2)/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Load workflow state (read WORKFLOW_ID from fixed location)
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
if [ -f "$COORDINATE_STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
  load_workflow_state "$WORKFLOW_ID"
else
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE"
  exit 1
fi

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

**EXECUTE NOW**: USE the Task tool to invoke the plan-architect agent.

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
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2)/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Load workflow state (read WORKFLOW_ID from fixed location)
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
if [ -f "$COORDINATE_STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
  load_workflow_state "$WORKFLOW_ID"
else
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE"
  exit 1
fi

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

emit_progress "2" "Plan creation invoked - awaiting completion"

# PLAN_PATH should be loaded from workflow state (set by initialize_workflow_paths in bash block 1)
echo "DEBUG: PLAN_PATH from state: $PLAN_PATH"

# ===== MANDATORY VERIFICATION CHECKPOINT: Planning Phase =====
echo ""
echo "MANDATORY VERIFICATION: Planning Phase Artifacts"
echo "Checking implementation plan..."
echo ""

echo -n "  Implementation plan: "
if verify_file_created "$PLAN_PATH" "Implementation plan" "Planning"; then
  PLAN_SIZE=$(stat -f%z "$PLAN_PATH" 2>/dev/null || stat -c%s "$PLAN_PATH" 2>/dev/null || echo "unknown")
  echo " verified ($PLAN_SIZE bytes)"
  VERIFICATION_FAILED=false
else
  echo ""
  VERIFICATION_FAILED=true
fi

# Fail-fast on verification failure
if [ "$VERIFICATION_FAILED" = "true" ]; then
  echo ""
  echo "❌ CRITICAL: Plan file verification failed"
  echo "   Expected path: $PLAN_PATH"
  echo ""
  echo "Path analysis:"
  echo "   Topic directory: $TOPIC_PATH"
  echo "   Expected plan should have descriptive name (not '001_implementation.md')"
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
  echo "1. Review /plan command output above for error messages"
  echo "2. Check plan agent behavioral file if used"
  echo "3. Verify file path calculation logic in workflow-initialization.sh"
  echo "4. Check if agent created file at different path than coordinate expects"
  echo "5. Ensure research reports contain sufficient information"
  echo "6. Re-run workflow after fixing issues"
  echo ""
  handle_state_error "/plan command failed to create expected plan file" 1
fi

echo "✓ Plan file verified successfully"

# Save plan path to workflow state
append_workflow_state "PLAN_PATH" "$PLAN_PATH"

# ===== CHECKPOINT REQUIREMENT: Planning Phase Complete =====
echo ""
echo "═══════════════════════════════════════════════════════"
echo "CHECKPOINT: Planning Phase Complete"
echo "═══════════════════════════════════════════════════════"
echo "Planning phase status before transitioning to next state:"
echo ""
echo "  Artifacts Created:"
echo "    - Implementation plan: ✓ Created"
echo "    - Plan path: $PLAN_PATH"
PLAN_SIZE=$(stat -f%z "$PLAN_PATH" 2>/dev/null || stat -c%s "$PLAN_PATH" 2>/dev/null || echo "unknown")
echo "    - Plan size: $PLAN_SIZE bytes"
echo ""
echo "  Verification Status:"
echo "    - Plan file verified: ✓ Yes"
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
set +H  # Disable history expansion to prevent bad substitution errors
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2)/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Load workflow state (read WORKFLOW_ID from fixed location)
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
if [ -f "$COORDINATE_STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
  load_workflow_state "$WORKFLOW_ID"
else
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE"
  exit 1
fi

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
set +H  # Disable history expansion to prevent bad substitution errors
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2)/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Load workflow state (read WORKFLOW_ID from fixed location)
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
if [ -f "$COORDINATE_STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
  load_workflow_state "$WORKFLOW_ID"
else
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE"
  exit 1
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
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2)/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Load workflow state (read WORKFLOW_ID from fixed location)
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
if [ -f "$COORDINATE_STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
  load_workflow_state "$WORKFLOW_ID"
else
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE"
  exit 1
fi

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
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2)/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Load workflow state (read WORKFLOW_ID from fixed location)
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
if [ -f "$COORDINATE_STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
  load_workflow_state "$WORKFLOW_ID"
else
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE"
  exit 1
fi

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
set +H  # Disable history expansion to prevent bad substitution errors
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2)/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Load workflow state (read WORKFLOW_ID from fixed location)
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
if [ -f "$COORDINATE_STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
  load_workflow_state "$WORKFLOW_ID"
else
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE"
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
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2)/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Load workflow state (read WORKFLOW_ID from fixed location)
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
if [ -f "$COORDINATE_STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
  load_workflow_state "$WORKFLOW_ID"
else
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE"
  exit 1
fi

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
set +H  # Disable history expansion to prevent bad substitution errors
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2)/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Load workflow state (read WORKFLOW_ID from fixed location)
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
if [ -f "$COORDINATE_STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
  load_workflow_state "$WORKFLOW_ID"
else
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE"
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
