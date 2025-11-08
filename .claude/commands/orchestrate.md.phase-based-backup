---
allowed-tools: Task, TodoWrite, Read, Bash
argument-hint: <workflow-description> [--parallel] [--sequential] [--create-pr] [--dry-run]
description: Coordinate subagents through end-to-end development workflows
command-type: primary
dependent-commands: research, plan, implement, debug, test, document, github-specialist
---

<!-- ═══════════════════════════════════════════════════════════════ -->
<!-- CRITICAL ARCHITECTURAL PATTERN - DO NOT VIOLATE                 -->
<!-- ═══════════════════════════════════════════════════════════════ -->
<!-- /orchestrate MUST NEVER invoke other slash commands             -->
<!-- FORBIDDEN TOOLS: SlashCommand                                   -->
<!-- REQUIRED PATTERN: Task tool → Specialized agents                -->
<!-- ═══════════════════════════════════════════════════════════════ -->

# Multi-Agent Workflow Orchestration

YOU MUST orchestrate a 7-phase development workflow by delegating to specialized subagents.

**Documentation**: See `.claude/docs/guides/orchestrate-command-guide.md`

**YOUR ROLE**: Workflow orchestrator (NOT executor)
- Use ONLY Task tool to invoke specialized agents
- Coordinate agents, verify outputs, manage checkpoints
- Forward agent results without re-summarization

**EXECUTION MODEL**: Pure orchestration (Phases 0-6)
- Phase 0: Location detection (unified library)
- Phase 1: Research (2-4 parallel agents)
- Phase 2: Planning (plan-architect agent)
- Phase 3: Implementation (implementer-coordinator with waves)
- Phase 4: Testing (test-specialist)
- Phase 5: Debugging (conditional, max 3 iterations)
- Phase 6: Documentation (doc-writer + summary)

---

## Phase 0: Location Determination

USE the Bash tool:

```bash
# Source unified location detection library
source "${CLAUDE_CONFIG:-${HOME}/.config}/.claude/lib/unified-location-detection.sh"

# Perform location detection
WORKFLOW_DESCRIPTION="$1"
LOCATION_JSON=$(perform_location_detection "$WORKFLOW_DESCRIPTION" "false")

# Extract topic directory paths
if command -v jq &>/dev/null; then
  TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
  TOPIC_NUMBER=$(echo "$LOCATION_JSON" | jq -r '.topic_number')
  TOPIC_NAME=$(echo "$LOCATION_JSON" | jq -r '.topic_name')
  ARTIFACT_REPORTS=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')
  ARTIFACT_PLANS=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.plans')
  ARTIFACT_SUMMARIES=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.summaries')
  ARTIFACT_DEBUG=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.debug')
  ARTIFACT_SCRIPTS=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.scripts')
  ARTIFACT_OUTPUTS=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.outputs')
else
  TOPIC_PATH=$(echo "$LOCATION_JSON" | grep -o '"topic_path": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  TOPIC_NUMBER=$(echo "$LOCATION_JSON" | grep -o '"topic_number": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  TOPIC_NAME=$(echo "$LOCATION_JSON" | grep -o '"topic_name": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  ARTIFACT_REPORTS="${TOPIC_PATH}/reports"
  ARTIFACT_PLANS="${TOPIC_PATH}/plans"
  ARTIFACT_SUMMARIES="${TOPIC_PATH}/summaries"
  ARTIFACT_DEBUG="${TOPIC_PATH}/debug"
  ARTIFACT_SCRIPTS="${TOPIC_PATH}/scripts"
  ARTIFACT_OUTPUTS="${TOPIC_PATH}/outputs"
fi

# Store in workflow state
export WORKFLOW_TOPIC_DIR="$TOPIC_PATH"
export WORKFLOW_TOPIC_NUMBER="$TOPIC_NUMBER"
export WORKFLOW_TOPIC_NAME="$TOPIC_NAME"
export ARTIFACT_REPORTS ARTIFACT_PLANS ARTIFACT_SUMMARIES ARTIFACT_DEBUG ARTIFACT_SCRIPTS ARTIFACT_OUTPUTS

echo "✓ Phase 0 Complete: $TOPIC_PATH"
```

**Verify**: Topic directory structure created at `$TOPIC_PATH`

---

## Phase 1: Research Coordination

USE the Bash tool:

```bash
# Determine research complexity (1-4 topics)
RESEARCH_COMPLEXITY=2

if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "^(fix|update|modify).*(one|single|small)"; then
  RESEARCH_COMPLEXITY=1
fi

if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "integrate|migration|refactor|architecture"; then
  RESEARCH_COMPLEXITY=3
fi

if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "multi-.*system|cross-.*platform|distributed|microservices"; then
  RESEARCH_COMPLEXITY=4
fi

echo "Research Complexity: $RESEARCH_COMPLEXITY agents"
```

**EXECUTE NOW**: USE the Task tool to invoke research-specialist agent for EACH research topic (1 to $RESEARCH_COMPLEXITY):

Task {
  subagent_type: "general-purpose"
  description: "Research [topic_name] for workflow implementation"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: [actual topic name]
    - Report Path: ${ARTIFACT_REPORTS}/[topic_number]_[topic_name].md
    - Project Standards: ${CLAUDE_PROJECT_DIR}/CLAUDE.md
    - Complexity Level: ${RESEARCH_COMPLEXITY}

    **CRITICAL**: Create report file at EXACT path provided above.

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [exact absolute path to report file]
  "
}

USE the Bash tool:

```bash
# Verify all research reports created
echo -n "Verifying research reports ($RESEARCH_COMPLEXITY): "

VERIFICATION_FAILURES=0
SUCCESSFUL_REPORT_PATHS=()

for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  # Extract report path from agent output
  REPORT_PATH=$(echo "$AGENT_OUTPUT" | grep "REPORT_CREATED:" | sed -n "${i}p" | cut -d: -f2- | xargs)

  if [ ! -f "$REPORT_PATH" ]; then
    echo ""
    echo "❌ ERROR: Research report $i not created"
    echo "   Expected pattern: ${ARTIFACT_REPORTS}/00${i}_*.md"
    VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
  else
    SUCCESSFUL_REPORT_PATHS+=("$REPORT_PATH")
  fi
done

if [ $VERIFICATION_FAILURES -eq 0 ]; then
  echo "✓ (${#SUCCESSFUL_REPORT_PATHS[@]}/${RESEARCH_COMPLEXITY} reports)"
else
  echo ""
  echo "Workflow TERMINATED: Fix research report creation and retry"
  exit 1
fi

echo "Research complete: ${#SUCCESSFUL_REPORT_PATHS[@]} reports created"
```

---

## Phase 2: Planning

USE the Bash tool:

```bash
# Build research reports list
RESEARCH_REPORTS_LIST=""
for report in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
  RESEARCH_REPORTS_LIST+="- $report\n"
done

# Discover standards file
STANDARDS_FILE="${CLAUDE_PROJECT_DIR}/CLAUDE.md"
if [ ! -f "$STANDARDS_FILE" ]; then
  STANDARDS_FILE="${CLAUDE_PROJECT_DIR}/.claude/CLAUDE.md"
fi
if [ ! -f "$STANDARDS_FILE" ]; then
  STANDARDS_FILE="(none found)"
fi

echo "Planning context: ${#SUCCESSFUL_REPORT_PATHS[@]} reports, standards: $STANDARDS_FILE"
```

**EXECUTE NOW**: USE the Task tool to invoke plan-architect:

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan from research findings"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    **Workflow-Specific Context**:
    - Workflow Description: ${WORKFLOW_DESCRIPTION}
    - Plan File Path: ${ARTIFACT_PLANS}/001_implementation.md
    - Project Standards: ${STANDARDS_FILE}
    - Research Reports: ${RESEARCH_REPORTS_LIST}
    - Research Report Count: ${#SUCCESSFUL_REPORT_PATHS[@]}

    **CRITICAL**: Create plan file at EXACT path provided above.

    Execute planning following all guidelines in behavioral file.
    Return: PLAN_CREATED: [exact absolute path to plan file]
  "
}

USE the Bash tool:

```bash
echo -n "Verifying implementation plan: "

PLAN_FILE="${ARTIFACT_PLANS}/001_implementation.md"

if [ ! -f "$PLAN_FILE" ]; then
  echo ""
  echo "❌ ERROR: Implementation plan not created"
  echo "   Expected: $PLAN_FILE"
  exit 1
fi

PHASE_COUNT=$(grep -c "^### Phase [0-9]" "$PLAN_FILE" || echo "0")
if [ "$PHASE_COUNT" -lt 3 ]; then
  echo " (structure warnings)"
  echo "⚠️  Plan has $PHASE_COUNT phases (expected ≥3)"
else
  echo " ($PHASE_COUNT phases)"
fi

PLAN_COMPLEXITY=$(grep "Complexity:" "$PLAN_FILE" | head -1 | cut -d: -f2 | xargs || echo "unknown")
PLAN_EST_TIME=$(grep "Estimated Total Time:" "$PLAN_FILE" | cut -d: -f2 | xargs || echo "unknown")

echo "Plan: $PHASE_COUNT phases, complexity: $PLAN_COMPLEXITY, est. time: $PLAN_EST_TIME"
```

---

## Phase 3: Implementation

USE the Bash tool:

```bash
# Analyze plan dependencies for wave execution
if command -v analyze_dependencies &>/dev/null; then
  DEPENDENCY_ANALYSIS=$(analyze_dependencies "$PLAN_FILE")

  if [ $? -eq 0 ]; then
    WAVES=$(echo "$DEPENDENCY_ANALYSIS" | jq '.waves')
    WAVE_COUNT=$(echo "$WAVES" | jq 'length')
    TOTAL_PHASES=$(echo "$DEPENDENCY_ANALYSIS" | jq '.dependency_graph.nodes | length')

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
  else
    echo "⚠️  Dependency analysis unavailable, using sequential execution"
    DEPENDENCY_ANALYSIS="{}"
  fi
else
  echo "⚠️  Dependency analyzer not found, using sequential execution"
  DEPENDENCY_ANALYSIS="{}"
fi
```

**EXECUTE NOW**: USE the Task tool to invoke implementer-coordinator:

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with wave-based parallel execution"
  timeout: 900000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    **Workflow-Specific Context**:
    - Implementation Plan: ${PLAN_FILE}
    - Topic Directory: ${WORKFLOW_TOPIC_DIR}
    - Project Standards: ${STANDARDS_FILE}

    **Wave Execution Context**:
    - Dependency Analysis: ${DEPENDENCY_ANALYSIS}

    **CRITICAL**: Execute phases wave-by-wave, parallel within waves when possible.

    Execute wave-based implementation following all guidelines in behavioral file.
    Return: IMPLEMENTATION_STATUS: {complete|partial|failed}
    Return: WAVES_COMPLETED: [number]
    Return: PHASES_COMPLETED: [number]
  "
}

USE the Bash tool:

```bash
echo -n "Verifying implementation artifacts: "

IMPL_ARTIFACTS="${WORKFLOW_TOPIC_DIR}/artifacts"

if [ ! -d "$IMPL_ARTIFACTS" ]; then
  echo ""
  echo "❌ ERROR: Implementation artifacts directory not created"
  echo "   Expected: $IMPL_ARTIFACTS"
  exit 1
fi

ARTIFACT_COUNT=$(find "$IMPL_ARTIFACTS" -type f 2>/dev/null | wc -l)
echo "✓ ($ARTIFACT_COUNT files)"

IMPL_STATUS=$(echo "$AGENT_OUTPUT" | grep "IMPLEMENTATION_STATUS:" | cut -d: -f2 | xargs)
WAVES_COMPLETED=$(echo "$AGENT_OUTPUT" | grep "WAVES_COMPLETED:" | cut -d: -f2 | xargs)
PHASES_COMPLETED=$(echo "$AGENT_OUTPUT" | grep "PHASES_COMPLETED:" | cut -d: -f2 | xargs)

echo "Implementation: $IMPL_STATUS ($PHASES_COMPLETED phases across $WAVES_COMPLETED waves)"

if [ "$IMPL_STATUS" == "complete" ] || [ "$IMPL_STATUS" == "partial" ]; then
  IMPLEMENTATION_OCCURRED="true"
fi
```

---

## Phase 4: Comprehensive Testing

**EXECUTE NOW**: USE the Task tool to invoke test-specialist:

Task {
  subagent_type: "general-purpose"
  description: "Execute comprehensive tests with mandatory results file"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/test-specialist.md

    **Workflow-Specific Context**:
    - Test Results Path: ${ARTIFACT_OUTPUTS}/test_results.txt
    - Project Standards: ${STANDARDS_FILE}
    - Plan File: ${PLAN_FILE}
    - Implementation Artifacts: ${IMPL_ARTIFACTS}

    **CRITICAL**: Create test results file at path provided above.

    Execute testing following all guidelines in behavioral file.
    Return: TEST_STATUS: {passing|failing}
    Return: TESTS_TOTAL: [number]
    Return: TESTS_PASSED: [number]
    Return: TESTS_FAILED: [number]
  "
}

USE the Bash tool:

```bash
echo -n "Verifying test results: "

TEST_RESULTS_FILE="${ARTIFACT_OUTPUTS}/test_results.txt"

if [ ! -f "$TEST_RESULTS_FILE" ]; then
  echo ""
  echo "❌ ERROR: Test results file not created"
  echo "   Expected: $TEST_RESULTS_FILE"
  exit 1
fi

TEST_STATUS=$(echo "$AGENT_OUTPUT" | grep "TEST_STATUS:" | cut -d: -f2 | xargs)
TESTS_TOTAL=$(echo "$AGENT_OUTPUT" | grep "TESTS_TOTAL:" | cut -d: -f2 | xargs)
TESTS_PASSED=$(echo "$AGENT_OUTPUT" | grep "TESTS_PASSED:" | cut -d: -f2 | xargs)
TESTS_FAILED=$(echo "$AGENT_OUTPUT" | grep "TESTS_FAILED:" | cut -d: -f2 | xargs)

echo "✓ ($TESTS_PASSED/$TESTS_TOTAL passed)"

if [ "$TEST_STATUS" == "passing" ]; then
  TESTS_PASSING="true"
  echo "✅ All tests passing - no debugging needed"
else
  TESTS_PASSING="false"
  echo "❌ Tests failing - debugging required (Phase 5)"
fi
```

---

## Phase 5: Debugging (Conditional)

USE the Bash tool:

```bash
if [ "$TESTS_PASSING" == "false" ]; then
  echo "Phase 5: Debugging (tests failed)"

  # Debug iteration loop (max 3 iterations)
  for iteration in 1 2 3; do
    echo "Debug iteration $iteration/3"
```

**EXECUTE NOW** (if tests failed, for each iteration): USE Task tool to invoke debug-analyst:

Task {
  subagent_type: "general-purpose"
  description: "Analyze test failures - iteration [iteration] of 3"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md

    **Workflow-Specific Context**:
    - Debug Report Path: ${ARTIFACT_DEBUG}/debug_iteration_[iteration].md
    - Test Results: ${TEST_RESULTS_FILE}
    - Project Standards: ${STANDARDS_FILE}
    - Iteration Number: [iteration]

    Execute debug analysis following all guidelines in behavioral file.
    Return: DEBUG_ANALYSIS_COMPLETE: [exact absolute path to debug report]
  "
}

**EXECUTE NOW** (for each iteration): USE Task tool to invoke code-writer for fixes:

Task {
  subagent_type: "general-purpose"
  description: "Apply debug fixes - iteration [iteration]"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/code-writer.md

    **Workflow-Specific Context**:
    - Debug Analysis: ${DEBUG_REPORT}
    - Project Standards: ${STANDARDS_FILE}
    - Iteration Number: [iteration]

    Execute fix application following all guidelines in behavioral file.
    Return: FIXES_APPLIED: [number]
  "
}

**EXECUTE NOW** (for each iteration): USE Task tool to invoke test-specialist for re-test:

Task {
  subagent_type: "general-purpose"
  description: "Re-run tests after fixes - iteration [iteration]"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/test-specialist.md

    **Workflow-Specific Context**:
    - Test Results Path: ${TEST_RESULTS_FILE} (append results)
    - Project Standards: ${STANDARDS_FILE}
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

    if [ "$TEST_STATUS" == "passing" ]; then
      TESTS_PASSING="true"
      echo "✅ Tests passing after $iteration debug iteration(s)"
      break
    fi

    if [ $iteration -eq 3 ]; then
      echo "⚠️  WARNING: Tests still failing after 3 iterations (manual intervention required)"
      TESTS_PASSING="false"
    fi
  done
else
  echo "⏭️  Skipping Phase 5 (tests passing)"
fi
```

---

## Phase 6: Documentation

**EXECUTE NOW**: USE the Task tool to invoke doc-writer:

Task {
  subagent_type: "general-purpose"
  description: "Generate documentation and workflow summary"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/doc-writer.md

    **Workflow-Specific Context**:
    - Summary Path: ${ARTIFACT_SUMMARIES}/001_implementation_summary.md
    - Plan File: ${PLAN_FILE}
    - Research Reports: ${RESEARCH_REPORTS_LIST}
    - Implementation Artifacts: ${IMPL_ARTIFACTS}
    - Test Status: ${TEST_STATUS}
    - Workflow Description: ${WORKFLOW_DESCRIPTION}

    **CRITICAL**: Create summary file at path provided above.

    Execute documentation following all guidelines in behavioral file.
    Return: SUMMARY_CREATED: [exact absolute path to summary file]
  "
}

USE the Bash tool:

```bash
echo -n "Verifying workflow summary: "

SUMMARY_FILE="${ARTIFACT_SUMMARIES}/001_implementation_summary.md"

if [ ! -f "$SUMMARY_FILE" ]; then
  echo ""
  echo "❌ ERROR: Workflow summary not created"
  echo "   Expected: $SUMMARY_FILE"
  exit 1
fi

FILE_SIZE=$(wc -c < "$SUMMARY_FILE")
echo "✓ (${FILE_SIZE} bytes)"

echo ""
echo "✅ Workflow Complete"
echo ""
echo "Artifacts created in: ${WORKFLOW_TOPIC_DIR}"
echo "  Research Reports: ${#SUCCESSFUL_REPORT_PATHS[@]}"
echo "  Implementation Plan: $PLAN_FILE"
echo "  Test Results: $TEST_RESULTS_FILE"
echo "  Workflow Summary: $SUMMARY_FILE"
echo ""

exit 0
```

---

**Troubleshooting**: See `.claude/docs/guides/orchestrate-command-guide.md` for common issues and solutions.
