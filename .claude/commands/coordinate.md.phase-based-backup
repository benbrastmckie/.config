---
allowed-tools: Task, TodoWrite, Bash, Read
argument-hint: <workflow-description>
description: Coordinate multi-agent workflows with wave-based parallel implementation
command-type: primary
dependent-commands: research, plan, implement, debug, test, document
---

# /coordinate - Multi-Agent Workflow Orchestration

YOU ARE EXECUTING AS the /coordinate command.

**Documentation**: See `.claude/docs/guides/coordinate-command-guide.md` for architecture, usage patterns, troubleshooting, and examples.

---

## Phase 0: Initialization

[EXECUTION-CRITICAL: Library sourcing and path pre-calculation]

USE the Bash tool to execute Phase 0 (Step 1 of 3):

```bash
echo "Phase 0: Initialization started"

# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
export LIB_DIR

# Parse workflow description
WORKFLOW_DESCRIPTION="$1"

if [ -z "$WORKFLOW_DESCRIPTION" ]; then
  echo "ERROR: Workflow description required"
  echo "Usage: /coordinate \"<workflow description>\""
  exit 1
fi

export WORKFLOW_DESCRIPTION

# Source and detect workflow scope
if [ -f "${LIB_DIR}/workflow-scope-detection.sh" ]; then
  source "${LIB_DIR}/workflow-scope-detection.sh"
else
  echo "ERROR: Required library not found: workflow-scope-detection.sh"
  exit 1
fi

WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")

if [ -z "${WORKFLOW_SCOPE:-}" ]; then
  echo "ERROR: detect_workflow_scope returned empty result"
  exit 1
fi

# Map scope to phase execution list
case "$WORKFLOW_SCOPE" in
  research-only)
    PHASES_TO_EXECUTE="0,1"
    SKIP_PHASES="2,3,4,5,6"
    ;;
  research-and-plan)
    PHASES_TO_EXECUTE="0,1,2"
    SKIP_PHASES="3,4,5,6"
    ;;
  full-implementation)
    PHASES_TO_EXECUTE="0,1,2,3,4,6"
    SKIP_PHASES=""
    ;;
  debug-only)
    PHASES_TO_EXECUTE="0,1,5"
    SKIP_PHASES="2,3,4,6"
    ;;
esac

export WORKFLOW_SCOPE PHASES_TO_EXECUTE SKIP_PHASES

# Source library-sourcing.sh
if [ ! -f "$LIB_DIR/library-sourcing.sh" ]; then
  echo "ERROR: Required library not found: library-sourcing.sh"
  exit 1
fi
source "$LIB_DIR/library-sourcing.sh"

# Define required libraries based on scope
case "$WORKFLOW_SCOPE" in
  research-only)
    REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh")
    ;;
  research-and-plan)
    REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "metadata-extraction.sh" "checkpoint-utils.sh")
    ;;
  full-implementation)
    REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "metadata-extraction.sh" "checkpoint-utils.sh" "dependency-analyzer.sh" "context-pruning.sh" "error-handling.sh")
    ;;
  debug-only)
    REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "metadata-extraction.sh" "checkpoint-utils.sh" "error-handling.sh")
    ;;
esac

# Source required libraries
if ! source_required_libraries "${REQUIRED_LIBS[@]}"; then
  echo "ERROR: Failed to source required libraries"
  exit 1
fi

echo "  ✓ Libraries loaded (${#REQUIRED_LIBS[@]} for $WORKFLOW_SCOPE)"
```

USE the Bash tool to execute Phase 0 (Step 2 of 3):

```bash
# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Verify critical functions
case "$WORKFLOW_SCOPE" in
  research-only)
    REQUIRED_FUNCTIONS=("detect_workflow_scope" "emit_progress")
    ;;
  research-and-plan|debug-only|full-implementation)
    REQUIRED_FUNCTIONS=("detect_workflow_scope" "should_run_phase" "emit_progress" "save_checkpoint" "restore_checkpoint")
    ;;
esac

MISSING_FUNCTIONS=()
for func in "${REQUIRED_FUNCTIONS[@]}"; do
  if ! command -v "$func" >/dev/null 2>&1; then
    MISSING_FUNCTIONS+=("$func")
  fi
done

if [ ${#MISSING_FUNCTIONS[@]} -gt 0 ]; then
  echo "ERROR: Required functions not defined after library sourcing:"
  for func in "${MISSING_FUNCTIONS[@]}"; do
    echo "  - $func()"
  done
  exit 1
fi

# Define inline helper functions
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

transition_to_phase() {
  local from_phase="$1"
  local to_phase="$2"
  local artifacts_json="${3:-{}}"

  if command -v emit_progress >/dev/null 2>&1; then
    emit_progress "$from_phase" "Phase $from_phase complete, transitioning to Phase $to_phase"
  fi

  if command -v save_checkpoint >/dev/null 2>&1; then
    save_checkpoint "coordinate" "phase_${from_phase}" "$artifacts_json" &
    local checkpoint_pid=$!
  fi

  if command -v store_phase_metadata >/dev/null 2>&1; then
    store_phase_metadata "phase_${from_phase}" "complete" "$artifacts_json"
  fi

  if command -v apply_pruning_policy >/dev/null 2>&1; then
    apply_pruning_policy "phase_${from_phase}" "$WORKFLOW_SCOPE"
  fi

  [ -n "${checkpoint_pid:-}" ] && wait $checkpoint_pid 2>/dev/null || true

  if command -v emit_progress >/dev/null 2>&1; then
    emit_progress "$to_phase" "Phase $to_phase starting"
  fi
}
export -f transition_to_phase

# Check for checkpoint resume
if command -v restore_checkpoint >/dev/null 2>&1; then
  RESUME_DATA=$(restore_checkpoint "coordinate" 2>/dev/null || echo "")
  if [ -n "$RESUME_DATA" ]; then
    RESUME_PHASE=$(echo "$RESUME_DATA" | jq -r '.current_phase // empty')
  else
    RESUME_PHASE=""
  fi

  if [ -n "$RESUME_PHASE" ]; then
    emit_progress "Resume" "Checkpoint detected - resuming from Phase $RESUME_PHASE"
  fi
else
  RESUME_PHASE=""
fi
export RESUME_PHASE

echo "  ✓ Workflow scope detected: $WORKFLOW_SCOPE"
```

USE the Bash tool to execute Phase 0 (Step 3 of 3):

```bash
# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Re-initialize workflow variables
WORKFLOW_DESCRIPTION="$1"

if [ -z "${WORKFLOW_DESCRIPTION:-}" ]; then
  echo "ERROR: WORKFLOW_DESCRIPTION not set"
  exit 1
fi

# Detect workflow scope using library
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
if [ -f "${LIB_DIR}/workflow-scope-detection.sh" ]; then
  source "${LIB_DIR}/workflow-scope-detection.sh"
else
  echo "ERROR: Required library not found: workflow-scope-detection.sh"
  exit 1
fi

WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")

if [ -z "${WORKFLOW_SCOPE:-}" ]; then
  echo "ERROR: detect_workflow_scope returned empty result"
  exit 1
fi

# Re-calculate PHASES_TO_EXECUTE
case "$WORKFLOW_SCOPE" in
  research-only) PHASES_TO_EXECUTE="0,1"; SKIP_PHASES="2,3,4,5,6" ;;
  research-and-plan) PHASES_TO_EXECUTE="0,1,2"; SKIP_PHASES="3,4,5,6" ;;
  full-implementation) PHASES_TO_EXECUTE="0,1,2,3,4,6"; SKIP_PHASES="" ;;
  debug-only) PHASES_TO_EXECUTE="0,1,5"; SKIP_PHASES="2,3,4,6" ;;
esac

export PHASES_TO_EXECUTE SKIP_PHASES

if [ -z "${PHASES_TO_EXECUTE:-}" ]; then
  echo "ERROR: PHASES_TO_EXECUTE not set after scope detection"
  exit 1
fi

# Source workflow initialization
if [ ! -f "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-initialization.sh" ]; then
  echo "ERROR: workflow-initialization.sh not found"
  exit 1
fi
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-initialization.sh"

# Source unified-logger
if [ -f "${CLAUDE_PROJECT_DIR}/.claude/lib/unified-logger.sh" ]; then
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/unified-logger.sh"
fi

# Initialize workflow paths
if ! initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE"; then
  echo "ERROR: Workflow initialization failed"
  exit 1
fi

echo "  ✓ Paths pre-calculated"
echo ""
echo "Workflow Scope: $WORKFLOW_SCOPE"
echo "Topic: $TOPIC_PATH"
echo ""

# Reconstruct REPORT_PATHS array
reconstruct_report_paths_array

# Emit progress
if command -v emit_progress &>/dev/null; then
  emit_progress "0" "Phase 0 complete (topic: $TOPIC_PATH)"
else
  echo "PROGRESS: [Phase 0] - Phase 0 complete (topic: $TOPIC_PATH)"
fi
echo ""
```

---

## Verification Helpers

[EXECUTION-CRITICAL: Define verification functions]

USE the Bash tool:

```bash
# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Source verification helpers
if [ -f "${CLAUDE_PROJECT_DIR}/.claude/lib/verification-helpers.sh" ]; then
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/verification-helpers.sh"
else
  echo "ERROR: verification-helpers.sh not found"
  exit 1
fi
```

---

## Phase 1: Research

[EXECUTION-CRITICAL: Parallel research agent invocation]

USE the Bash tool:

```bash
should_run_phase 1 || {
  echo "⏭️  Skipping Phase 1 (Research)"
  display_brief_summary
  exit 0
}

if command -v emit_progress &>/dev/null; then
  emit_progress "1" "Phase 1: Research (parallel agent invocation)"
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

# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

source "${CLAUDE_PROJECT_DIR}/.claude/lib/library-sourcing.sh"
source_required_libraries || exit 1

emit_progress "1" "Invoking $RESEARCH_COMPLEXITY research agents in parallel"
```

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
emit_progress "1" "All research agents invoked - awaiting completion"

# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Source verification helpers
if [ -f "${CLAUDE_PROJECT_DIR}/.claude/lib/verification-helpers.sh" ]; then
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/verification-helpers.sh"
else
  echo "ERROR: verification-helpers.sh not found"
  exit 1
fi

# Verify all research reports created
echo -n "Verifying research reports ($RESEARCH_COMPLEXITY): "

VERIFICATION_FAILURES=0
SUCCESSFUL_REPORT_PATHS=()

for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  REPORT_PATH="${REPORT_PATHS[$i-1]}"
  if ! verify_file_created "$REPORT_PATH" "Research report $i/$RESEARCH_COMPLEXITY" "Phase 1"; then
    VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
  else
    SUCCESSFUL_REPORT_PATHS+=("$REPORT_PATH")
  fi
done

SUCCESSFUL_REPORT_COUNT=${#SUCCESSFUL_REPORT_PATHS[@]}

if [ $VERIFICATION_FAILURES -eq 0 ]; then
  echo " (all passed)"
  emit_progress "1" "Verified: $SUCCESSFUL_REPORT_COUNT/$RESEARCH_COMPLEXITY research reports"
else
  echo ""
  echo "Workflow TERMINATED: Fix verification failures and retry"
  exit 1
fi

echo "Verification checkpoint passed - proceeding to research overview"
echo ""

# Conditionally create overview (research-only workflows only)
if should_synthesize_overview "$WORKFLOW_SCOPE" "$SUCCESSFUL_REPORT_COUNT"; then
  OVERVIEW_PATH=$(calculate_overview_path "$RESEARCH_SUBDIR")

  echo "Creating research overview to synthesize findings..."
  echo "  Path: $OVERVIEW_PATH"

  REPORT_LIST=""
  for report in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
    REPORT_LIST+="- $report\n"
  done

  echo "Invoking research synthesizer agent..."
```

**EXECUTE NOW** (if overview synthesis needed): USE the Task tool to invoke research-synthesizer:

Task {
  subagent_type: "general-purpose"
  description: "Synthesize research findings into comprehensive overview"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-synthesizer.md

    **Workflow-Specific Context**:
    - Overview Path: [OVERVIEW_PATH value]
    - Research Reports to Synthesize: [report list from SUCCESSFUL_REPORT_PATHS]
    - Total Reports: [SUCCESSFUL_REPORT_COUNT value]
    - Project Standards: /home/benjamin/.config/CLAUDE.md

    **CRITICAL**: Create overview file at EXACT path provided above.

    Execute synthesis following all guidelines in behavioral file.
    Return: OVERVIEW_CREATED: [exact absolute path to overview file]
  "
}

USE the Bash tool:

```bash
  verify_file_created "$OVERVIEW_PATH" "Research Overview" "Phase 1"
else
  SKIP_REASON=$(get_synthesis_skip_reason "$WORKFLOW_SCOPE" "$SUCCESSFUL_REPORT_COUNT")
  echo "⏭️  Skipping overview synthesis"
  echo "  Reason: $SKIP_REASON"
  echo ""
fi

emit_progress "1" "Research complete: $SUCCESSFUL_REPORT_COUNT reports verified"
echo ""

# Save checkpoint
ARTIFACT_PATHS_JSON=$(cat <<EOF
{
  "research_reports": [$(printf '"%s",' "${SUCCESSFUL_REPORT_PATHS[@]}" | sed 's/,$//')]
  $([ -n "$OVERVIEW_PATH" ] && [ -f "$OVERVIEW_PATH" ] && echo ', "overview_path": "'$OVERVIEW_PATH'"' || echo '')
}
EOF
)
save_checkpoint "coordinate" "phase_1" "$ARTIFACT_PATHS_JSON"

# Store phase metadata
PHASE_1_ARTIFACTS="${SUCCESSFUL_REPORT_PATHS[@]}"
store_phase_metadata "phase_1" "complete" "$PHASE_1_ARTIFACTS"

echo "Phase 1 metadata stored (context reduction: 80-90%)"
emit_progress "1" "Research complete ($SUCCESSFUL_REPORT_COUNT reports created)"
```

---

## Phase 2: Planning

[EXECUTION-CRITICAL: Plan-architect agent invocation]

USE the Bash tool:

```bash
should_run_phase 2 || {
  echo "⏭️  Skipping Phase 2 (Planning)"
  display_brief_summary
  exit 0
}

if command -v emit_progress &>/dev/null; then
  emit_progress "2" "Phase 2: Planning (plan-architect invocation)"
fi

echo "Preparing planning context..."

# Build research reports list
RESEARCH_REPORTS_LIST=""
for report in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
  RESEARCH_REPORTS_LIST+="- $report\n"
done

if [ -n "$OVERVIEW_PATH" ] && [ -f "$OVERVIEW_PATH" ]; then
  RESEARCH_REPORTS_LIST+="- $OVERVIEW_PATH (synthesis)\n"
fi

# Discover standards file
STANDARDS_FILE="${LOCATION}/CLAUDE.md"
if [ ! -f "$STANDARDS_FILE" ]; then
  STANDARDS_FILE="${LOCATION}/.claude/CLAUDE.md"
fi
if [ ! -f "$STANDARDS_FILE" ]; then
  STANDARDS_FILE="(none found)"
fi

echo "Planning Context: $SUCCESSFUL_REPORT_COUNT reports, standards: $STANDARDS_FILE"
```

**EXECUTE NOW**: USE the Task tool to invoke plan-architect:

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan with mandatory file creation"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/plan-architect.md

    **Workflow-Specific Context**:
    - Workflow Description: [WORKFLOW_DESCRIPTION value]
    - Plan File Path: [PLAN_PATH - absolute path pre-calculated]
    - Project Standards: [STANDARDS_FILE path]
    - Research Reports: [RESEARCH_REPORTS_LIST - formatted list]
    - Research Report Count: [SUCCESSFUL_REPORT_COUNT value]

    **CRITICAL**: Create plan file at EXACT path provided above.

    Execute planning following all guidelines in behavioral file.
    Return: PLAN_CREATED: [exact absolute path to plan file]
  "
}

USE the Bash tool:

```bash
echo -n "Verifying implementation plan: "

if verify_file_created "$PLAN_PATH" "Implementation plan" "Phase 2"; then
  PHASE_COUNT=$(grep -c "^### Phase [0-9]" "$PLAN_PATH" || echo "0")
  if [ "$PHASE_COUNT" -lt 3 ] || ! grep -q "^## Metadata" "$PLAN_PATH"; then
    echo " (structure warnings)"
    echo "⚠️  Plan: $PHASE_COUNT phases (expected ≥3)"
  else
    echo " ($PHASE_COUNT phases)"
  fi
  emit_progress "2" "Verified: Implementation plan ($PHASE_COUNT phases)"
else
  echo ""
  echo "Workflow TERMINATED: Fix plan creation and retry"
  exit 1
fi

# Extract plan metadata
PLAN_COMPLEXITY=$(grep "Complexity:" "$PLAN_PATH" | head -1 | cut -d: -f2 | xargs || echo "unknown")
PLAN_EST_TIME=$(grep "Estimated Total Time:" "$PLAN_PATH" | cut -d: -f2 | xargs || echo "unknown")

echo "Plan: $PHASE_COUNT phases, complexity: $PLAN_COMPLEXITY, est. time: $PLAN_EST_TIME"
emit_progress "2" "Planning complete: $PHASE_COUNT phases, $PLAN_EST_TIME estimated"
echo ""

# Save checkpoint
ARTIFACT_PATHS_JSON=$(cat <<EOF
{
  "research_reports": [$(printf '"%s",' "${SUCCESSFUL_REPORT_PATHS[@]}" | sed 's/,$//')]
  $([ -n "$OVERVIEW_PATH" ] && [ -f "$OVERVIEW_PATH" ] && echo ', "overview_path": "'$OVERVIEW_PATH'",' || echo '')
  "plan_path": "$PLAN_PATH"
}
EOF
)
save_checkpoint "coordinate" "phase_2" "$ARTIFACT_PATHS_JSON"

# Store phase metadata
store_phase_metadata "phase_2" "complete" "$PLAN_PATH"
apply_pruning_policy "planning" "$WORKFLOW_SCOPE"
echo "Phase 2 metadata stored (context reduction: 80-90%)"
emit_progress "2" "Planning complete (plan created with $PHASE_COUNT phases)"

# Check if workflow should continue to implementation
should_run_phase 3 || {
  emit_progress "Complete" "/coordinate workflow complete"
  echo ""
  echo "Workflow complete: $WORKFLOW_SCOPE"
  echo ""
  echo "Artifacts:"
  echo "  ✓ $SUCCESSFUL_REPORT_COUNT research reports"
  if [ -n "$PLAN_PATH" ] && [ -f "$PLAN_PATH" ]; then
    echo "  ✓ 1 implementation plan ($PHASE_COUNT phases, $PLAN_EST_TIME estimated)"
  fi
  echo ""
  echo "Next: /implement $PLAN_PATH"
  echo ""
  exit 0
}
```

---

## Phase 3: Wave-Based Implementation

[EXECUTION-CRITICAL: Dependency analysis and parallel wave execution]

USE the Bash tool:

```bash
should_run_phase 3 || {
  echo "⏭️  Skipping Phase 3 (Implementation)"
  echo ""
}

if command -v emit_progress &>/dev/null; then
  emit_progress "3" "Phase 3: Wave-based implementation"
fi

IMPL_START_TIME=$(date +%s)

echo "Analyzing plan dependencies for wave execution..."
DEPENDENCY_ANALYSIS=$(analyze_dependencies "$PLAN_PATH")

if [[ $? -ne 0 ]]; then
  echo "❌ ERROR: Dependency analysis failed"
  exit 1
fi

WAVES=$(echo "$DEPENDENCY_ANALYSIS" | jq '.waves')
WAVE_COUNT=$(echo "$WAVES" | jq 'length')
TOTAL_PHASES=$(echo "$DEPENDENCY_ANALYSIS" | jq '.dependency_graph.nodes | length')

echo "✅ Dependency analysis complete"
echo "   Total phases: $TOTAL_PHASES"
echo "   Execution waves: $WAVE_COUNT"
echo ""

echo "Wave execution plan:"
for ((wave_num=1; wave_num<=WAVE_COUNT; wave_num++)); do
  WAVE=$(echo "$WAVES" | jq ".[$((wave_num-1))]")
  WAVE_PHASES=$(echo "$WAVE" | jq -r '.phases[]')
  PHASE_COUNT=$(echo "$WAVE" | jq '.phases | length')
  CAN_PARALLEL=$(echo "$WAVE" | jq -r '.can_parallel')

  echo "  Wave $wave_num: $PHASE_COUNT phase(s) $([ "$CAN_PARALLEL" == "true" ] && echo "[PARALLEL]" || echo "[SEQUENTIAL]")"
  for phase in $WAVE_PHASES; do
    echo "    - Phase $phase"
  done
done
echo ""
```

**EXECUTE NOW**: USE the Task tool to invoke implementer-coordinator:

Task {
  subagent_type: "general-purpose"
  description: "Orchestrate wave-based implementation with parallel execution"
  timeout: 600000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/implementer-coordinator.md

    **Workflow-Specific Context**:
    - Plan File Path: [PLAN_PATH value]
    - Implementation Artifacts Directory: [IMPL_ARTIFACTS path]
    - Project Standards: [STANDARDS_FILE path]
    - Workflow Type: [WORKFLOW_SCOPE value]

    **Wave Execution Context**:
    - Total Waves: [WAVE_COUNT value]
    - Wave Structure: [WAVES JSON structure]
    - Dependency Graph: [dependency_graph from DEPENDENCY_ANALYSIS]

    **CRITICAL**: Execute phases wave-by-wave, parallel within waves when possible.

    Execute wave-based implementation following all guidelines in behavioral file.
    Return: IMPLEMENTATION_STATUS: {complete|partial|failed}
    Return: WAVES_COMPLETED: [number]
    Return: PHASES_COMPLETED: [number]
  "
}

USE the Bash tool:

```bash
# Parse implementation status
IMPL_STATUS=$(echo "$AGENT_OUTPUT" | grep "IMPLEMENTATION_STATUS:" | cut -d: -f2 | xargs)
WAVES_COMPLETED=$(echo "$AGENT_OUTPUT" | grep "WAVES_COMPLETED:" | cut -d: -f2 | xargs)
PHASES_COMPLETED=$(echo "$AGENT_OUTPUT" | grep "PHASES_COMPLETED:" | cut -d: -f2 | xargs)

IMPL_END_TIME=$(date +%s)
IMPL_DURATION=$((IMPL_END_TIME - IMPL_START_TIME))

echo -n "Verifying implementation artifacts: "

if [ -d "$IMPL_ARTIFACTS" ]; then
  ARTIFACT_COUNT=$(find "$IMPL_ARTIFACTS" -type f 2>/dev/null | wc -l)
  echo "✓ ($ARTIFACT_COUNT files)"
  emit_progress "3" "Verified: Implementation artifacts ($ARTIFACT_COUNT files)"
else
  echo ""
  echo "✗ ERROR [Phase 3]: Implementation artifacts directory not created"
  exit 1
fi

if [ "$IMPL_STATUS" == "complete" ] || [ "$IMPL_STATUS" == "partial" ]; then
  IMPLEMENTATION_OCCURRED="true"
fi

# Save checkpoint
ARTIFACT_PATHS_JSON=$(cat <<EOF
{
  "research_reports": [$(printf '"%s",' "${SUCCESSFUL_REPORT_PATHS[@]}" | sed 's/,$//')]
  $([ -n "$OVERVIEW_PATH" ] && [ -f "$OVERVIEW_PATH" ] && echo ', "overview_path": "'$OVERVIEW_PATH'",' || echo '')
  "plan_path": "$PLAN_PATH",
  "impl_artifacts": "$IMPL_ARTIFACTS",
  "wave_execution": {
    "waves_completed": $WAVES_COMPLETED,
    "duration_seconds": $IMPL_DURATION
  }
}
EOF
)
save_checkpoint "coordinate" "phase_3" "$ARTIFACT_PATHS_JSON"

store_phase_metadata "phase_3" "complete" "implementation_metrics"
apply_pruning_policy "implementation" "orchestrate"

echo "Phase 3 metadata pruned (context reduction: 80-90%)"
emit_progress "3" "Implementation complete"
```

---

## Phase 4: Testing

[EXECUTION-CRITICAL: Test execution and result verification]

USE the Bash tool:

```bash
should_run_phase 4 || {
  echo "⏭️  Skipping Phase 4 (Testing)"
  echo ""
}

if command -v emit_progress &>/dev/null; then
  emit_progress "4" "Phase 4: Testing (test-specialist invocation)"
fi
```

**EXECUTE NOW**: USE the Task tool to invoke test-specialist:

Task {
  subagent_type: "general-purpose"
  description: "Execute comprehensive tests with mandatory results file"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/test-specialist.md

    **Workflow-Specific Context**:
    - Test Results Path: [TOPIC_PATH/outputs/test_results.md]
    - Project Standards: [STANDARDS_FILE path]
    - Plan File: [PLAN_PATH value]
    - Implementation Artifacts: [IMPL_ARTIFACTS path]

    **CRITICAL**: Create test results file at path provided above.

    Execute testing following all guidelines in behavioral file.
    Return: TEST_STATUS: {passing|failing}
    Return: TESTS_TOTAL: [number]
    Return: TESTS_PASSED: [number]
  "
}

USE the Bash tool:

```bash
# Parse test status
TEST_STATUS=$(echo "$AGENT_OUTPUT" | grep "TEST_STATUS:" | cut -d: -f2 | xargs)
TESTS_TOTAL=$(echo "$AGENT_OUTPUT" | grep "TESTS_TOTAL:" | cut -d: -f2 | xargs)
TESTS_PASSED=$(echo "$AGENT_OUTPUT" | grep "TESTS_PASSED:" | cut -d: -f2 | xargs)

emit_progress "4" "Test results: $TESTS_PASSED/$TESTS_TOTAL passed"
echo "Test Status: $TEST_STATUS ($TESTS_PASSED/$TESTS_TOTAL passed)"

if [ "$TEST_STATUS" == "passing" ]; then
  TESTS_PASSING="true"
  echo "✅ All tests passing - no debugging needed"
else
  TESTS_PASSING="false"
  echo "❌ Tests failing - debugging required (Phase 5)"
fi

emit_progress "4" "Testing complete: $TESTS_PASSING"
echo ""

# Save checkpoint
ARTIFACT_PATHS_JSON=$(cat <<EOF
{
  "research_reports": [$(printf '"%s",' "${SUCCESSFUL_REPORT_PATHS[@]}" | sed 's/,$//')]
  $([ -n "$OVERVIEW_PATH" ] && [ -f "$OVERVIEW_PATH" ] && echo ', "overview_path": "'$OVERVIEW_PATH'",' || echo '')
  "plan_path": "$PLAN_PATH",
  "impl_artifacts": "$IMPL_ARTIFACTS",
  "test_status": "$TEST_STATUS"
}
EOF
)
save_checkpoint "coordinate" "phase_4" "$ARTIFACT_PATHS_JSON"

store_phase_metadata "phase_4" "complete" "test_status:$TEST_STATUS"
echo "Phase 4 metadata stored"
emit_progress "4" "Testing complete (status: $TEST_STATUS)"
```

---

## Phase 5: Debug (Conditional)

[EXECUTION-CRITICAL: Debug analysis - only runs if tests failed]

USE the Bash tool:

```bash
if [ "$TESTS_PASSING" == "false" ] || [ "$WORKFLOW_SCOPE" == "debug-only" ]; then
  emit_progress "5" "Phase 5: Debug (conditional execution)"
else
  echo "⏭️  Skipping Phase 5 (Debug)"
  echo "  Reason: Tests passing"
  echo ""
fi

# Debug iteration loop (max 3 iterations)
for iteration in 1 2 3; do
  emit_progress "5" "Debug iteration $iteration/3"
```

**EXECUTE NOW** (for each debug iteration): USE Task tool to invoke debug-analyst:

Task {
  subagent_type: "general-purpose"
  description: "Analyze test failures - iteration [iteration value]"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/debug-analyst.md

    **Workflow-Specific Context**:
    - Debug Report Path: [DEBUG_REPORT path for iteration]
    - Test Results: [TOPIC_PATH/outputs/test_results.md]
    - Project Standards: [STANDARDS_FILE path]
    - Iteration Number: [iteration value]

    Execute debug analysis following all guidelines in behavioral file.
    Return: DEBUG_ANALYSIS_COMPLETE: [exact absolute path to debug report]
  "
}

USE the Bash tool:

```bash
  echo -n "Verifying debug report (iteration $iteration): "

  if verify_file_created "$DEBUG_REPORT" "Debug report" "Phase 5"; then
    echo ""
  else
    echo ""
    echo "Workflow TERMINATED: Fix debug report creation and retry"
    exit 1
  fi
```

**EXECUTE NOW** (for each iteration): USE Task tool to invoke code-writer for fixes:

Task {
  subagent_type: "general-purpose"
  description: "Apply debug fixes - iteration [iteration]"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/code-writer.md

    **Workflow-Specific Context**:
    - Debug Analysis: [DEBUG_REPORT path]
    - Project Standards: [STANDARDS_FILE path]
    - Iteration Number: [iteration]

    Execute fix application following all guidelines in behavioral file.
    Return: FIXES_APPLIED: [number]
  "
}

USE the Bash tool:

```bash
  FIXES_APPLIED=$(echo "$AGENT_OUTPUT" | grep "FIXES_APPLIED:" | cut -d: -f2 | xargs)
  echo "Fixes Applied: $FIXES_APPLIED"
  echo "Re-running tests..."
```

**EXECUTE NOW** (for each iteration): USE Task tool to invoke test-specialist for re-test:

Task {
  subagent_type: "general-purpose"
  description: "Re-run tests after fixes - iteration [iteration]"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/test-specialist.md

    **Workflow-Specific Context**:
    - Test Results Path: [TOPIC_PATH/outputs/test_results.md]
    - Project Standards: [STANDARDS_FILE path]
    - Iteration Number: [iteration]

    Execute tests following all guidelines in behavioral file.
    Return: TEST_STATUS: {passing|failing}
    Return: TESTS_TOTAL: [number]
    Return: TESTS_PASSED: [number]
  "
}

USE the Bash tool:

```bash
  TEST_STATUS=$(echo "$AGENT_OUTPUT" | grep "TEST_STATUS:" | cut -d: -f2 | xargs)
  TESTS_TOTAL=$(echo "$AGENT_OUTPUT" | grep "TESTS_TOTAL:" | cut -d: -f2 | xargs)
  TESTS_PASSED=$(echo "$AGENT_OUTPUT" | grep "TESTS_PASSED:" | cut -d: -f2 | xargs)

  if [ "$TEST_STATUS" == "passing" ]; then
    TESTS_PASSING="true"
  else
    TESTS_PASSING="false"
  fi

  echo "Updated Test Status: $TEST_STATUS ($TESTS_PASSED/$TESTS_TOTAL passed)"

  if [ "$TESTS_PASSING" == "true" ]; then
    echo "✅ Tests passing after $iteration debug iteration(s)"
    break
  fi

  echo "Tests still failing, continuing..."
done

[ "$TESTS_PASSING" == "false" ] && echo "⚠️  WARNING: Tests still failing after 3 iterations"

emit_progress "5" "Debug complete: tests=$TESTS_PASSING"
echo ""

store_phase_metadata "phase_5" "complete" "tests_passing:$TESTS_PASSING"
echo "Phase 5 metadata stored"
emit_progress "5" "Debug complete (final test status: $TESTS_PASSING)"
```

---

## Phase 6: Documentation (Conditional)

[EXECUTION-CRITICAL: Summary creation - only after implementation]

USE the Bash tool:

```bash
if [ "$IMPLEMENTATION_OCCURRED" == "true" ]; then
  emit_progress "6" "Phase 6: Documentation (summary creation)"
else
  echo "⏭️  Skipping Phase 6 (Documentation)"
  echo "  Reason: No implementation to document"
  echo ""
  display_brief_summary
  exit 0
fi
```

**EXECUTE NOW**: USE Task tool to invoke doc-writer:

Task {
  subagent_type: "general-purpose"
  description: "Create workflow summary with mandatory file creation"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/doc-writer.md

    **Workflow-Specific Context**:
    - Summary Path: [SUMMARY_PATH value]
    - Plan File: [PLAN_PATH value]
    - Research Reports: [RESEARCH_REPORTS_LIST]
    - Implementation Artifacts: [IMPL_ARTIFACTS path]
    - Test Status: [TEST_STATUS value]
    - Workflow Description: [WORKFLOW_DESCRIPTION value]

    **CRITICAL**: Create summary file at path provided above.

    Execute documentation following all guidelines in behavioral file.
    Return: SUMMARY_CREATED: [exact absolute path to summary file]
  "
}

USE the Bash tool:

```bash
echo -n "Verifying workflow summary: "

if verify_file_created "$SUMMARY_PATH" "Workflow summary" "Phase 6"; then
  FILE_SIZE=$(wc -c < "$SUMMARY_PATH")
  echo " (${FILE_SIZE} bytes)"
  emit_progress "6" "Verified: Workflow summary created"
else
  echo ""
  echo "Workflow TERMINATED: Fix summary creation and retry"
  exit 1
fi

store_phase_metadata "phase_6" "complete" "$SUMMARY_PATH"
prune_workflow_metadata "coordinate_workflow" "true"
emit_progress "6" "Documentation complete (summary created)"

# Clean up checkpoint on successful completion
CHECKPOINT_FILE=".claude/data/checkpoints/coordinate_latest.json"
[ -f "$CHECKPOINT_FILE" ] && rm -f "$CHECKPOINT_FILE"

display_brief_summary
exit 0
```

---

**Troubleshooting**: See `.claude/docs/guides/coordinate-command-guide.md` for common issues and solutions.
