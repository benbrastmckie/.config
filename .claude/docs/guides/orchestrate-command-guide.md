# /orchestrate Command - Complete Guide

**Executable**: `.claude/commands/orchestrate.md`

**Quick Start**: Run `/orchestrate "<workflow-description>" [--parallel] [--sequential] [--create-pr] [--dry-run]`

**IMPORTANT**: This is the DOCUMENTATION file. For execution, Claude loads `.claude/commands/orchestrate.md`. This guide provides architectural context, detailed patterns, and troubleshooting.

---

## Table of Contents

1. [Overview](#overview)
2. [Command Syntax](#command-syntax)
3. [Architecture](#architecture)
4. [Workflow Infrastructure](#workflow-infrastructure)
5. [Phase 0: Location Determination](#phase-0-location-determination)
6. [Phase 1: Research Coordination](#phase-1-research-coordination)
7. [Phase 2: Planning](#phase-2-planning)
8. [Phase 3: Implementation](#phase-3-implementation)
9. [Phase 4: Comprehensive Testing](#phase-4-comprehensive-testing)
10. [Phase 5: Debugging Loop](#phase-5-debugging-loop)
11. [Phase 6: Documentation](#phase-6-documentation)
12. [Advanced Topics](#advanced-topics)
13. [Troubleshooting](#troubleshooting)

---

## Overview

### Purpose

The `/orchestrate` command coordinates multi-agent workflows through a 7-phase development lifecycle: location determination → research → planning → implementation → testing → debugging → documentation.

### When to Use

- **Complete feature development**: From research through implementation and testing
- **Complex multi-phase workflows**: Requiring coordination of multiple specialized agents
- **Automated development pipelines**: Research-backed implementation with test verification
- **Pull request workflows**: With automatic PR creation (--create-pr flag)

### When NOT to Use

- Single-phase tasks (use specific commands: /research, /plan, /implement, /test, /debug)
- Simple file edits (use Edit/Write tools directly)
- Exploratory research without implementation (/research or /coordinate for research-only)

### Key Features

✅ **7-phase lifecycle**: Structured workflow from location to documentation
✅ **Multi-agent coordination**: Specialized agents for each phase
✅ **Wave-based parallel execution**: 40-60% time savings in implementation phase
✅ **Checkpoint recovery**: Auto-resume from last completed phase
✅ **Context optimization**: <30% context usage through metadata passing
✅ **Progress tracking**: TodoWrite integration and progress markers
✅ **Pull request automation**: Optional PR creation with --create-pr flag
✅ **Dry-run mode**: Preview workflow without execution (--dry-run flag)

---

## Command Syntax

```bash
/orchestrate <workflow-description> [flags]
```

**Arguments**:
- `<workflow-description>`: Natural language description of the workflow (required)

**Flags**:
- `--parallel`: Enable parallel research agent execution (default behavior)
- `--sequential`: Force sequential agent execution
- `--create-pr`: Create GitHub pull request after successful implementation
- `--dry-run`: Preview workflow analysis without executing agents

**Examples**:
- `/orchestrate "add rate limiting middleware to API endpoints with tests"`
- `/orchestrate "refactor authentication module for OAuth2 support" --create-pr`
- `/orchestrate "implement user profile page with avatar upload" --dry-run`

---

## Architecture

### Role: Workflow Orchestrator

**YOU ARE THE ORCHESTRATOR** for this multi-agent workflow.

**YOUR RESPONSIBILITIES**:
1. Invoke specialized agents via Task tool for each phase
2. Verify agent outputs at mandatory checkpoints
3. Aggregate metadata from agent results (forward message pattern)
4. Manage checkpoints and workflow state
5. Report final workflow status and artifact locations

**YOU MUST NEVER**:
1. Execute research/planning/implementation tasks yourself using Read/Write/Grep/Bash
2. Invoke other commands via SlashCommand tool (/plan, /implement, /debug, /document)
3. Skip verification checkpoints after agent invocations
4. Continue workflow after verification failure
5. Create artifact files directly (agents create files)

### Architectural Pattern

```
Phase 0: Location detection → Create topic directory structure
  ↓
Phase 1-6: Invoke agents with pre-calculated paths → Verify → Aggregate metadata
  ↓
Completion: Report success + artifact locations
```

### Critical Architectural Warnings

**ANTI-PATTERN: SlashCommand Invocation**

❌ **WRONG** - Do NOT do this:
```
SlashCommand with command: "/plan create implementation plan"
```

**Problems with command chaining**:
1. **Context Bloat**: Entire /plan command prompt injected (~3000 tokens)
2. **Broken Behavioral Injection**: Cannot customize agent behavior or inject paths
3. **Lost Artifact Control**: Cannot ensure artifacts in correct topic directory
4. **Anti-Pattern Propagation**: Sets bad example for future commands

✅ **CORRECT** - Do this instead:
```
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/plan-architect.md

    **Workflow-Specific Context**:
    - Plan Path: [pre-calculated path in topic directory]
    - Research Reports: [list of report paths]

    Execute planning following all guidelines in behavioral file.
    Return: PLAN_CREATED: [absolute path]
  "
}
```

**Benefits of direct agent invocation**:
1. Lean context (only agent guidelines, ~200 lines vs ~3000)
2. Behavioral control (can inject custom instructions)
3. Structured output (metadata, not full summaries)
4. Verification points (verify file creation before continuing)
5. Path control (orchestrator pre-calculates all artifact paths)

### Tools

**ALLOWED**:
- Task: ONLY tool for agent invocations
- TodoWrite: Track phase progress
- Bash: Verification checkpoints (ls, test -f, grep -c)
- Read: Parse agent output files for metadata extraction (not for task execution)

**PROHIBITED**:
- SlashCommand: NEVER invoke other commands
- Write/Edit: NEVER create artifact files (agents do this)
- Grep/Glob: NEVER search codebase directly for execution (agents do this)

---

## Workflow Infrastructure

### TodoWrite Initialization

All orchestration workflows use TodoWrite for progress tracking:

**Initialization Pattern** (Phase 0):
```
TodoWrite {
  todos: [
    {content: "Phase 0: Location detection", status: "in_progress", activeForm: "Detecting location"},
    {content: "Phase 1: Research", status: "pending", activeForm: "Researching"},
    {content: "Phase 2: Planning", status: "pending", activeForm: "Planning"},
    {content: "Phase 3: Implementation", status: "pending", activeForm: "Implementing"},
    {content: "Phase 4: Testing", status: "pending", activeForm: "Testing"},
    {content: "Phase 5: Debugging (conditional)", status: "pending", activeForm: "Debugging"},
    {content: "Phase 6: Documentation", status: "pending", activeForm: "Documenting"}
  ]
}
```

**Update Pattern** (Each phase completion):
```
TodoWrite {
  todos: [
    ...previous phases marked "completed"...,
    {content: "Phase N", status: "in_progress", activeForm: "..."},
    ...remaining phases marked "pending"...
  ]
}
```

### Workflow State Structure

**State Variables** (exported across phases):
```bash
# Topic Organization
WORKFLOW_TOPIC_DIR="/path/to/specs/NNN_topic_name"
WORKFLOW_TOPIC_NUMBER="NNN"
WORKFLOW_TOPIC_NAME="topic_name"

# Artifact Paths (pre-calculated in Phase 0)
ARTIFACT_REPORTS="${WORKFLOW_TOPIC_DIR}/reports"
ARTIFACT_PLANS="${WORKFLOW_TOPIC_DIR}/plans"
ARTIFACT_SUMMARIES="${WORKFLOW_TOPIC_DIR}/summaries"
ARTIFACT_DEBUG="${WORKFLOW_TOPIC_DIR}/debug"
ARTIFACT_SCRIPTS="${WORKFLOW_TOPIC_DIR}/scripts"
ARTIFACT_OUTPUTS="${WORKFLOW_TOPIC_DIR}/outputs"

# Phase Outputs
RESEARCH_REPORT_PATHS=() # Array of report file paths
PLAN_FILE_PATH=""        # Path to implementation plan
TEST_RESULTS_PATH=""     # Path to test results file
SUMMARY_FILE_PATH=""     # Path to workflow summary

# Phase Status Flags
TESTS_PASSING="false"    # Updated after Phase 4
DEBUGGING_INVOKED="false" # Set if Phase 5 executes
```

### Shared Utilities Integration

**Required Libraries** (sourced in Phase 0):
```bash
# Location detection
source "${CLAUDE_CONFIG}/.claude/lib/unified-location-detection.sh"

# Metadata extraction
source "${CLAUDE_CONFIG}/.claude/lib/metadata-extraction.sh"

# Checkpoint management
source "${CLAUDE_CONFIG}/.claude/lib/checkpoint-utils.sh"

# Error handling
source "${CLAUDE_CONFIG}/.claude/lib/error-handling.sh"

# Progress streaming
source "${CLAUDE_CONFIG}/.claude/lib/unified-logger.sh"
```

**Library Functions Used**:
- `perform_location_detection()` - Phase 0
- `extract_report_metadata()` - Phase 1
- `extract_plan_metadata()` - Phase 2
- `save_checkpoint()` - All phases
- `restore_checkpoint()` - Phase 0 (resume detection)
- `emit_progress()` - All phases
- `classify_error()` - Error handling throughout

### Error Handling Strategy

**Fail-Fast Philosophy**:
- **NO retries**: Single execution attempt per agent invocation
- **NO fallbacks**: If agent fails to create file, workflow terminates with diagnostic information
- **Clear diagnostics**: Every error shows what failed, why, and how to fix
- **Debugging guidance**: Error messages include commands to investigate issues

**Error Message Structure**:
```
❌ ERROR: [What failed]
   Expected: [What was supposed to happen]
   Found: [What actually happened]

DIAGNOSTIC INFORMATION:
  - [Specific check that failed]
  - [File system state or error details]

What to check next:
  1. [First debugging step with example command]
  2. [Second debugging step]
  3. [Third debugging step]
```

**Example Error (Agent failed to create file)**:
```
❌ ERROR: Plan-architect agent failed to create plan file
   Expected: File exists at /path/to/specs/042_topic/plans/001_implementation.md
   Found: Directory exists but file not created

DIAGNOSTIC INFORMATION:
  - Agent invocation completed without errors
  - Directory exists: /path/to/specs/042_topic/plans/
  - No plan file found in directory
  - Agent may have created file with different name

What to check next:
  1. List directory contents: ls -la /path/to/specs/042_topic/plans/
  2. Check agent output for PLAN_CREATED signal
  3. Verify agent behavioral file: cat .claude/agents/plan-architect.md
```

### Progress Streaming

**Format**: Silent PROGRESS: markers emitted at phase boundaries

**Example**:
```
PROGRESS: [Phase 0] - Location detection complete
PROGRESS: [Phase 1] - Invoking 3 research agents in parallel
PROGRESS: [Phase 1] - All research agents completed
PROGRESS: [Phase 2] - Planning phase started
PROGRESS: [Phase 2] - Plan created with 7 phases
PROGRESS: [Phase 3] - Implementation started (3 waves identified)
PROGRESS: [Phase 3] - Wave 1 complete (2/2 phases)
PROGRESS: [Phase 3] - All waves complete
PROGRESS: [Phase 4] - Testing started
PROGRESS: [Phase 4] - Tests complete (23/23 passing)
PROGRESS: [Phase 6] - Documentation complete
PROGRESS: [Complete] - Workflow finished successfully
```

**Use Case**: Enables external monitoring tools to track workflow progress without verbose output.

**Documentation**: See [Orchestration Best Practices → Standardized Progress Markers](./orchestration-best-practices.md#standardized-progress-markers) for complete format specification.

---

## Phase 0: Location Determination

### Objective

Use unified location detection library to create topic directory structure and pre-calculate all artifact paths.

### Pattern

```
Source unified-location-detection.sh
  ↓
Call perform_location_detection()
  ↓
Parse JSON output for paths
  ↓
Create topic directory structure
  ↓
Export paths to workflow state
```

### Implementation

**Bash Execution Block**:
```bash
# Source unified location detection library
source "${CLAUDE_CONFIG:-${HOME}/.config}/.claude/lib/unified-location-detection.sh"

# Perform location detection
LOCATION_JSON=$(perform_location_detection "$WORKFLOW_DESCRIPTION" "false")

# Extract topic directory paths (with jq)
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
  # Fallback parsing without jq
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

### Verification

**Mandatory Checkpoint**: Verify topic directory structure created

```bash
# Verify directory exists
if [ ! -d "$WORKFLOW_TOPIC_DIR" ]; then
  echo "❌ ERROR: Topic directory not created"
  echo "   Expected: $WORKFLOW_TOPIC_DIR"
  exit 1
fi

# Verify subdirectories exist
for subdir in reports plans summaries debug scripts outputs; do
  if [ ! -d "${WORKFLOW_TOPIC_DIR}/${subdir}" ]; then
    echo "❌ ERROR: Subdirectory not created: ${subdir}"
    exit 1
  fi
done

echo "✓ Verification passed: Topic directory structure complete"
```

### Context Optimization

**Phase 0 Token Usage**: <100 tokens
- Minimal output (path confirmation only)
- No agent invocation overhead
- Library handles all complexity

---

## Phase 1: Research Coordination

### Objective

Invoke 2-4 research-specialist agents in parallel to conduct focused research on workflow topics.

### Complexity Scoring

**Research complexity determines number of agents** (1-4):

```bash
RESEARCH_COMPLEXITY=2  # Default: 2 agents

# Simple workflows → 1 agent
if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "^(fix|update|modify).*(one|single|small)"; then
  RESEARCH_COMPLEXITY=1
fi

# Moderate complexity → 3 agents
if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "integrate|migration|refactor|architecture"; then
  RESEARCH_COMPLEXITY=3
fi

# High complexity → 4 agents
if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "multi-.*system|cross-.*platform|distributed|microservices"; then
  RESEARCH_COMPLEXITY=4
fi
```

### Parallel Agent Invocation

**Pattern**: Invoke N research-specialist agents in parallel (single message, multiple Task calls)

**Agent Invocation Template**:
```
Task {
  subagent_type: "general-purpose"
  description: "Research [topic_name] for workflow implementation"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: [topic_name]
    - Report Path: ${ARTIFACT_REPORTS}/[topic_number]_[topic_name].md
    - Project Standards: ${CLAUDE_PROJECT_DIR}/CLAUDE.md
    - Complexity Level: ${RESEARCH_COMPLEXITY}

    **CRITICAL**: Create report file at EXACT path provided above.

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [exact absolute path to report file]
  "
}
```

**Research Topics by Complexity**:

- **Complexity 1** (simple fix):
  - Topic 1: Current implementation analysis

- **Complexity 2** (standard feature):
  - Topic 1: Architecture patterns
  - Topic 2: Implementation examples

- **Complexity 3** (integration/refactor):
  - Topic 1: Architecture patterns
  - Topic 2: Integration strategies
  - Topic 3: Testing approaches

- **Complexity 4** (distributed/multi-system):
  - Topic 1: System architecture
  - Topic 2: Cross-platform integration
  - Topic 3: Data flow and synchronization
  - Topic 4: Testing and deployment strategies

### Verification

**Mandatory Checkpoint**: All research report files must exist

```bash
echo -n "Verifying research reports ($RESEARCH_COMPLEXITY): "

VERIFICATION_FAILURES=0
SUCCESSFUL_REPORT_PATHS=()

for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  REPORT_PATH="${ARTIFACT_REPORTS}/00${i}_[topic].md"

  if [ ! -f "$REPORT_PATH" ]; then
    echo ""
    echo "❌ ERROR: Research report $i not created"
    echo "   Expected: $REPORT_PATH"
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
```

### Context Optimization

**Metadata Extraction Pattern** (80-90% reduction):

```bash
# Extract metadata from each report (NOT full content)
for report in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
  METADATA=$(extract_report_metadata "$report")
  # Store only: title, 50-word summary, key findings (3-5 bullets)
done

# Prune full report content from context after metadata extraction
# Agent outputs cleared, only metadata retained
```

**Phase 1 Token Usage**: <2000 tokens total
- Metadata only (not full reports)
- Report paths + summaries
- ~400 tokens per report metadata

---

## Phase 2: Planning

### Objective

Invoke plan-architect agent to create implementation plan using research report metadata.

### Context Preparation

**Build Research Reports List**:
```bash
RESEARCH_REPORTS_LIST=""
for report in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
  RESEARCH_REPORTS_LIST+="- $report\n"
done
```

**Discover Standards File**:
```bash
STANDARDS_FILE="${CLAUDE_PROJECT_DIR}/CLAUDE.md"
if [ ! -f "$STANDARDS_FILE" ]; then
  STANDARDS_FILE="${CLAUDE_PROJECT_DIR}/.claude/CLAUDE.md"
fi
if [ ! -f "$STANDARDS_FILE" ]; then
  STANDARDS_FILE="(none found)"
fi
```

### Agent Invocation

**Plan-Architect Agent Template**:
```
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
```

### Verification

**Mandatory Checkpoint**: Plan file must exist with minimum structure

```bash
echo -n "Verifying implementation plan: "

PLAN_FILE="${ARTIFACT_PLANS}/001_implementation.md"

if [ ! -f "$PLAN_FILE" ]; then
  echo ""
  echo "❌ ERROR: Implementation plan not created"
  echo "   Expected: $PLAN_FILE"
  exit 1
fi

# Verify plan structure
PHASE_COUNT=$(grep -c "^### Phase [0-9]" "$PLAN_FILE" || echo "0")
if [ "$PHASE_COUNT" -lt 3 ]; then
  echo " (structure warnings)"
  echo "⚠️  Plan has $PHASE_COUNT phases (expected ≥3)"
else
  echo " ($PHASE_COUNT phases)"
fi

# Extract plan metadata
PLAN_COMPLEXITY=$(grep "Complexity:" "$PLAN_FILE" | head -1 | cut -d: -f2 | xargs || echo "unknown")
PLAN_EST_TIME=$(grep "Estimated Total Time:" "$PLAN_FILE" | cut -d: -f2 | xargs || echo "unknown")

echo "Plan: $PHASE_COUNT phases, complexity: $PLAN_COMPLEXITY, est. time: $PLAN_EST_TIME"
```

### Context Optimization

**Plan Metadata Only** (not full plan content):
```bash
# Extract and store metadata only
PLAN_METADATA=$(extract_plan_metadata "$PLAN_FILE")
# Metadata includes: phase count, complexity score, time estimate, dependency graph

# Prune research report metadata after planning complete
# Planning phase consumed research, no longer needed in context
```

**Phase 2 Token Usage**: <500 tokens
- Plan metadata only (not full plan)
- Research metadata pruned after plan creation

---

## Phase 3: Implementation

### Objective

Invoke implementer-coordinator agent to execute implementation plan with wave-based parallel execution.

### Dependency Analysis

**Wave Calculation** (uses dependency-analyzer.sh library):

```bash
# Analyze plan dependencies
DEPENDENCY_ANALYSIS=$(analyze_dependencies "$PLAN_FILE")

# Extract wave structure
WAVES=$(echo "$DEPENDENCY_ANALYSIS" | jq '.waves')
WAVE_COUNT=$(echo "$WAVES" | jq 'length')
TOTAL_PHASES=$(echo "$DEPENDENCY_ANALYSIS" | jq '.dependency_graph.nodes | length')

# Display wave execution plan
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
```

**Example Wave Structure**:
```
Plan with 7 phases:
  Phase 1: dependencies: []
  Phase 2: dependencies: []
  Phase 3: dependencies: [1]
  Phase 4: dependencies: [1]
  Phase 5: dependencies: [2]
  Phase 6: dependencies: [3, 4]
  Phase 7: dependencies: [5, 6]

Wave Calculation Result:
  Wave 1: [Phase 1, Phase 2]          ← 2 phases in parallel
  Wave 2: [Phase 3, Phase 4, Phase 5] ← 3 phases in parallel
  Wave 3: [Phase 6]                   ← 1 phase (depends on Wave 2)
  Wave 4: [Phase 7]                   ← 1 phase (depends on Wave 3)

Time Savings: 43% (4 waves vs 7 sequential phases)
```

### Agent Invocation

**Implementer-Coordinator Agent Template**:
```
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
    - Total Waves: ${WAVE_COUNT}
    - Wave Structure: ${WAVES}
    - Dependency Graph: ${DEPENDENCY_ANALYSIS}

    **CRITICAL**: Execute phases wave-by-wave, parallel within waves when possible.

    Execute wave-based implementation following all guidelines in behavioral file.
    Return: IMPLEMENTATION_STATUS: {complete|partial|failed}
    Return: WAVES_COMPLETED: [number]
    Return: PHASES_COMPLETED: [number]
  "
}
```

### Debugging Loop Integration

**Conditional Debugging** (if tests fail during implementation):

The implementer-coordinator agent includes an integrated debugging loop (max 3 iterations):

```
For each wave:
  Execute phases in parallel
  ↓
  Run tests for completed phases
  ↓
  If tests fail:
    Iteration 1-3:
      Invoke debug-analyst
      Apply fixes
      Re-run tests
    If tests pass: Continue to next wave
    If max iterations reached: Report partial completion
  ↓
  If tests pass: Continue to next wave
```

### Verification

**Mandatory Checkpoint**: Implementation artifacts directory must exist

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

# Parse implementation status from agent output
IMPL_STATUS=$(echo "$AGENT_OUTPUT" | grep "IMPLEMENTATION_STATUS:" | cut -d: -f2 | xargs)
WAVES_COMPLETED=$(echo "$AGENT_OUTPUT" | grep "WAVES_COMPLETED:" | cut -d: -f2 | xargs)
PHASES_COMPLETED=$(echo "$AGENT_OUTPUT" | grep "PHASES_COMPLETED:" | cut -d: -f2 | xargs)

echo "Implementation Status: $IMPL_STATUS ($PHASES_COMPLETED phases across $WAVES_COMPLETED waves)"
```

### Context Optimization

**Aggressive Pruning After Implementation**:
```bash
# Store minimal phase metadata (implementation status only)
store_phase_metadata "phase_3" "complete" "implementation_metrics"

# Prune research and planning artifacts (no longer needed)
apply_pruning_policy "implementation" "orchestrate"

# Context reduction: 80-90% (wave details removed, keeping summary only)
```

**Phase 3 Token Usage**: <1000 tokens
- Implementation status metadata
- Wave completion summary
- Research/planning metadata pruned

---

## Phase 4: Comprehensive Testing

### Objective

Invoke test-specialist agent to execute comprehensive test suite and report results.

### Agent Invocation

**Test-Specialist Agent Template**:
```
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
```

### Verification

**Mandatory Checkpoint**: Test results file must exist

```bash
echo -n "Verifying test results: "

TEST_RESULTS_FILE="${ARTIFACT_OUTPUTS}/test_results.txt"

if [ ! -f "$TEST_RESULTS_FILE" ]; then
  echo ""
  echo "❌ ERROR: Test results file not created"
  echo "   Expected: $TEST_RESULTS_FILE"
  exit 1
fi

# Parse test status from agent output
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

### Context Optimization

**Test Metadata Only** (not full test output):
```bash
# Store minimal test metadata (pass/fail status only)
store_phase_metadata "phase_4" "complete" "test_status:$TEST_STATUS"

# Keep test output temporarily (needed for potential Phase 5 debugging)
# Will be pruned after Phase 5 or if Phase 5 skipped
```

**Phase 4 Token Usage**: <300 tokens
- Test status metadata (pass/fail counts)
- Full test output retained for potential debugging

---

## Phase 5: Debugging Loop

### Objective

Conditionally invoke debug-analyst agent if Phase 4 tests failed (max 3 iterations).

### Execution Condition

**Phase 5 ONLY executes if**:
- Tests failed in Phase 4 (`TEST_STATUS == "failing"`)
- OR workflow explicitly requests debugging (`WORKFLOW_SCOPE == "debug-only"`)

Otherwise, Phase 5 is skipped entirely.

### Debug Iteration Loop

**Pattern**: Up to 3 debug cycles

```
For iteration 1 to 3:
  Invoke debug-analyst
  ↓
  Parse debug report for proposed fixes
  ↓
  Invoke code-writer to apply fixes
  ↓
  Invoke test-specialist to re-run tests
  ↓
  If tests pass: Break loop (success)
  If tests fail: Continue to next iteration
```

### Agent Invocations

**Debug-Analyst Template** (per iteration):
```
Task {
  subagent_type: "general-purpose"
  description: "Analyze test failures - iteration [N] of 3"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md

    **Workflow-Specific Context**:
    - Debug Report Path: ${ARTIFACT_DEBUG}/debug_iteration_[N].md
    - Test Results: ${TEST_RESULTS_FILE}
    - Project Standards: ${STANDARDS_FILE}
    - Iteration Number: [N]

    Execute debug analysis following all guidelines in behavioral file.
    Return: DEBUG_ANALYSIS_COMPLETE: [exact absolute path to debug report]
  "
}
```

**Code-Writer Template** (apply fixes):
```
Task {
  subagent_type: "general-purpose"
  description: "Apply debug fixes - iteration [N]"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/code-writer.md

    **Workflow-Specific Context**:
    - Debug Analysis: ${DEBUG_REPORT}
    - Project Standards: ${STANDARDS_FILE}
    - Iteration Number: [N]
    - Task Type: Apply debug fixes

    Execute fix application following all guidelines in behavioral file.
    Return: FIXES_APPLIED: [number]
    Return: FILES_MODIFIED: [comma-separated list]
  "
}
```

**Test-Specialist Template** (re-test):
```
Task {
  subagent_type: "general-purpose"
  description: "Re-run tests after fixes - iteration [N]"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/test-specialist.md

    **Workflow-Specific Context**:
    - Test Results Path: ${TEST_RESULTS_FILE} (append results)
    - Project Standards: ${STANDARDS_FILE}
    - Iteration Number: [N]
    - Task Type: Re-run tests after fixes

    Execute tests following all guidelines in behavioral file.
    Return: TEST_STATUS: {passing|failing}
    Return: TESTS_TOTAL: [number]
    Return: TESTS_PASSED: [number]
  "
}
```

### Iteration Control

```bash
for iteration in 1 2 3; do
  # Invoke debug-analyst
  # Invoke code-writer
  # Invoke test-specialist

  # Parse updated test status
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
```

### Context Optimization

**Debug Metadata Only**:
```bash
# Store minimal phase metadata (debug status and final test status)
store_phase_metadata "phase_5" "complete" "tests_passing:$TESTS_PASSING"

# Prune test output now that debugging is complete
```

**Phase 5 Token Usage**: <500 tokens per iteration
- Debug status metadata
- Final test status
- Test output pruned after completion

---

## Phase 6: Documentation

### Objective

Invoke doc-writer agent to create workflow summary linking plan, research, and implementation.

### Agent Invocation

**Doc-Writer Agent Template**:
```
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
```

### Verification

**Mandatory Checkpoint**: Summary file must exist

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
```

### Summary Structure

**Expected Content**:
```markdown
# Implementation Summary: [Feature Name]

## Metadata
- Date Completed: [YYYY-MM-DD]
- Workflow Description: [original description]
- Topic Directory: [path]
- Plan Executed: [link to plan file]
- Research Reports: [links to reports]

## Implementation Overview
[Brief description of what was implemented]

## Key Changes
- [Major change 1 with file references]
- [Major change 2 with file references]

## Test Results
- Total Tests: [N]
- Passing: [N]
- Failing: [N]
- Test Coverage: [percentage]

## Wave Execution Metrics
- Total Waves: [N]
- Total Phases: [N]
- Parallel Phases: [N]
- Time Savings: [percentage]

## Debugging Summary
[Only if Phase 5 executed]
- Iterations Required: [1-3]
- Issues Fixed: [list]
- Final Test Status: [passing|failing]

## Lessons Learned
[Insights from implementation]
```

### Context Optimization

**Final Context Cleanup**:
```bash
# Store summary path only
store_phase_metadata "phase_6" "complete" "$SUMMARY_FILE"

# Prune all workflow metadata (keeping artifacts intact)
prune_workflow_metadata "orchestrate_workflow" "true"  # keep_artifacts=true
```

**Phase 6 Token Usage**: <200 tokens
- Summary path only
- All phase metadata pruned
- Context usage <30% achieved

---

## Advanced Topics

### Checkpoint Detection and Resume

**Checkpoint Schema** (`.claude/data/checkpoints/orchestrate_latest.json`):
```json
{
  "command": "orchestrate",
  "timestamp": "2025-11-07T12:00:00Z",
  "current_phase": "phase_3",
  "workflow_description": "implement user authentication",
  "topic_directory": "/path/to/specs/042_user_authentication",
  "artifact_paths": {
    "research_reports": [
      "/path/to/specs/042_user_authentication/reports/001_auth_patterns.md",
      "/path/to/specs/042_user_authentication/reports/002_security_best_practices.md"
    ],
    "plan_path": "/path/to/specs/042_user_authentication/plans/001_implementation.md",
    "test_status": "failing"
  },
  "phase_status": {
    "phase_0": "complete",
    "phase_1": "complete",
    "phase_2": "complete",
    "phase_3": "in_progress",
    "phase_4": "pending",
    "phase_5": "pending",
    "phase_6": "pending"
  }
}
```

**Resume Behavior**:
```bash
# Check for checkpoint on startup
if command -v restore_checkpoint &>/dev/null; then
  CHECKPOINT_DATA=$(restore_checkpoint "orchestrate" 2>/dev/null || echo "")

  if [ -n "$CHECKPOINT_DATA" ]; then
    # Restore workflow state
    WORKFLOW_TOPIC_DIR=$(echo "$CHECKPOINT_DATA" | jq -r '.topic_directory')
    CURRENT_PHASE=$(echo "$CHECKPOINT_DATA" | jq -r '.current_phase')

    echo "✓ Checkpoint detected - resuming from $CURRENT_PHASE"

    # Skip completed phases, continue from current phase
  fi
fi
```

**Checkpoint Save Points** (after each phase completion):
```bash
# Save checkpoint after Phase N
CHECKPOINT_JSON=$(cat <<EOF
{
  "command": "orchestrate",
  "current_phase": "phase_N",
  "artifact_paths": {...}
}
EOF
)
save_checkpoint "orchestrate" "phase_N" "$CHECKPOINT_JSON"
```

### Dry-Run Mode Implementation

**Flag Detection**:
```bash
# Parse command-line flags
DRY_RUN="false"
PARALLEL_MODE="true"  # Default
CREATE_PR="false"

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    --sequential)
      PARALLEL_MODE="false"
      shift
      ;;
    --parallel)
      PARALLEL_MODE="true"
      shift
      ;;
    --create-pr)
      CREATE_PR="true"
      shift
      ;;
    *)
      WORKFLOW_DESCRIPTION="$1"
      shift
      ;;
  esac
done
```

**Dry-Run Behavior**:
```
If --dry-run:
  Phase 0: Location detection (execute - no side effects)
  ↓
  Phase 1: Research analysis (preview topics, NO agent invocation)
  ↓
  Phase 2: Planning preview (show what would be planned, NO agent invocation)
  ↓
  Phase 3-6: Skip entirely (preview message: "Would execute Phase N")
  ↓
  Display workflow summary:
    - Research topics identified: [list]
    - Estimated research agents: [N]
    - Estimated plan complexity: [score]
    - Estimated implementation time: [duration]
    - Files that would be created: [paths]
    - NO actual agent invocations
    - NO file creation
```

**Example Dry-Run Output**:
```
Workflow Preview (--dry-run):

Phase 0: Location Detection
  ✓ Topic directory: specs/042_user_authentication
  ✓ Artifact paths calculated

Phase 1: Research (preview)
  Would invoke 3 research agents:
    1. Authentication patterns research
    2. Security best practices research
    3. Session management research
  Would create 3 reports in: specs/042_user_authentication/reports/

Phase 2: Planning (preview)
  Would invoke plan-architect agent
  Would create plan: specs/042_user_authentication/plans/001_implementation.md
  Estimated complexity: Medium (6/10)
  Estimated time: 3-4 hours

Phase 3: Implementation (preview)
  Would invoke implementer-coordinator agent
  Would execute wave-based parallel implementation
  Estimated phases: 7
  Estimated waves: 3

Phase 4-6: Testing, Debugging, Documentation (preview)
  Would execute if implementation phase runs
  Test suite: specs/042_user_authentication/outputs/test_results.txt
  Summary: specs/042_user_authentication/summaries/001_implementation_summary.md

Total estimated workflow duration: 4-5 hours
```

### Reference Files Integration

**Orchestration Patterns Reference** (`.claude/docs/reference/orchestration-patterns.md`):

Contains complete agent prompt templates for:
- research-specialist
- plan-architect
- implementer-coordinator
- test-specialist
- debug-analyst
- code-writer
- doc-writer

**Usage in Command**:
```bash
# Reference patterns file for template lookup
PATTERNS_FILE="${CLAUDE_PROJECT_DIR}/.claude/docs/reference/orchestration-patterns.md"

# Extract specific agent template
AGENT_TEMPLATE=$(sed -n '/## research-specialist/,/## [^#]/p' "$PATTERNS_FILE")
```

**Benefits**:
- Centralized agent prompt management
- Consistent agent invocation across commands
- Easy template updates (single source of truth)
- Reduced command file size

---

## Troubleshooting

### Common Issues

#### Issue 1: Meta-Confusion Loops

**Symptoms**:
- Command attempts to "invoke /orchestrate"
- Recursive invocation before first bash block executes
- "Now let me use the /orchestrate command..." in output

**Cause**:
- Mixed documentation and executable content
- Extensive prose before first executable instruction

**Solution**:
- **RESOLVED**: Executable/documentation separation eliminates this issue
- Executable file (`orchestrate.md`) contains only bash blocks and agent templates
- All documentation moved to this guide file

**Verification**:
```bash
# Check executable file size (should be <300 lines)
wc -l .claude/commands/orchestrate.md

# Verify no extensive prose before first bash block
head -50 .claude/commands/orchestrate.md
```

#### Issue 2: Agent Failed to Create Expected File

**Symptoms**:
- Error message: "Agent failed to create expected file"
- Verification checkpoint fails
- Workflow terminates

**Cause**:
- Agent behavioral file missing or incorrect
- Agent misinterpreted path instructions
- File system permissions issue
- Path calculation error in Phase 0

**Solution**:
```bash
# 1. Verify agent behavioral file exists
ls -la .claude/agents/[agent-name].md

# 2. Check topic directory permissions
ls -la specs/

# 3. Verify path calculation from Phase 0
echo $WORKFLOW_TOPIC_DIR
echo $ARTIFACT_REPORTS

# 4. Check agent output for error messages
# (agent output shown before verification checkpoint)

# 5. List directory contents to see what was created
ls -la $WORKFLOW_TOPIC_DIR/reports/
```

**Diagnostic Information**:
```bash
# Check if agent completed without errors
# If yes: Agent completed but created file with wrong name/path
# If no: Agent encountered execution error

# Check for partial file creation
find $WORKFLOW_TOPIC_DIR -type f -mmin -10
# Shows files created in last 10 minutes

# Verify agent behavioral file matches expected template
diff .claude/agents/research-specialist.md .claude/agents/_template-agent.md
```

#### Issue 3: Checkpoint Resume Failure

**Symptoms**:
- Checkpoint detected but resume fails
- State variables not restored correctly
- Phases re-execute from beginning

**Cause**:
- Checkpoint file corrupted or incomplete
- JSON parsing error in checkpoint data
- Missing jq dependency

**Solution**:
```bash
# 1. Check checkpoint file exists and is valid JSON
cat .claude/data/checkpoints/orchestrate_latest.json | jq .

# 2. Verify checkpoint age (stale checkpoints ignored)
ls -lh .claude/data/checkpoints/orchestrate_latest.json

# 3. Manually inspect checkpoint content
cat .claude/data/checkpoints/orchestrate_latest.json

# 4. Delete corrupted checkpoint and restart
rm .claude/data/checkpoints/orchestrate_latest.json
/orchestrate "your workflow description"

# 5. Install jq if missing
sudo apt-get install jq  # Debian/Ubuntu
brew install jq          # macOS
```

#### Issue 4: Parallel Research Agents Not Executing

**Symptoms**:
- Only 1 research agent invoked despite complexity score >1
- Sequential execution instead of parallel
- Research phase takes longer than expected

**Cause**:
- `--sequential` flag provided
- Parallel execution disabled in configuration
- Agent invocation error (first agent failed, others skipped)

**Solution**:
```bash
# 1. Check command-line flags
# Ensure --sequential flag NOT provided

# 2. Verify RESEARCH_COMPLEXITY calculation
echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "integrate|migration|refactor|architecture"
echo $?  # Should be 0 if matched

# 3. Check agent invocation count
# Look for multiple "Task {" invocations in execution output

# 4. Force parallel mode explicitly
/orchestrate "your workflow" --parallel

# 5. Check for agent failures
# Look for error messages before "Verifying research reports" checkpoint
```

#### Issue 5: Tests Passing But Debugging Invoked

**Symptoms**:
- Phase 4 reports "All tests passing"
- Phase 5 (Debugging) executes anyway
- Unnecessary debug iterations

**Cause**:
- `TESTS_PASSING` flag not set correctly
- Test status parsing error
- Agent returned incorrect TEST_STATUS signal

**Solution**:
```bash
# 1. Verify TEST_STATUS parsing
echo "$AGENT_OUTPUT" | grep "TEST_STATUS:"
# Should show: TEST_STATUS: passing

# 2. Check TESTS_PASSING flag
echo $TESTS_PASSING
# Should be: true

# 3. Verify Phase 5 execution condition
if [ "$TESTS_PASSING" == "false" ]; then
  echo "Phase 5 will execute (tests failing)"
else
  echo "Phase 5 will be skipped (tests passing)"
fi

# 4. Check test results file content
cat $TEST_RESULTS_FILE | grep -i "fail\|error"
# If no failures found, TEST_STATUS should be "passing"
```

### Debug Mode

**Enable verbose logging**:
```bash
export ORCHESTRATE_DEBUG=1
/orchestrate "your workflow"
```

**Output**: Detailed logging of:
- Library function calls
- Agent invocations with full prompts
- Verification checkpoints
- Context pruning operations
- Checkpoint saves/restores

### Getting Help

- Check [Orchestration Best Practices Guide](./orchestration-best-practices.md) for patterns
- Review [Checkpoint Recovery Pattern](../concepts/patterns/checkpoint-recovery.md)
- See [Hierarchical Agent Architecture](../concepts/hierarchical_agents.md)
- Consult [Command Reference](../reference/command-reference.md) for quick syntax
- Review [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) for agent invocation details

---

## See Also

- [Orchestration Best Practices Guide](./orchestration-best-practices.md) - Unified framework for all orchestration commands
- [Orchestration Troubleshooting Guide](./orchestration-troubleshooting.md) - Debugging procedures
- [Checkpoint Recovery Pattern](../concepts/patterns/checkpoint-recovery.md) - State preservation
- [Parallel Execution Pattern](../concepts/patterns/parallel-execution.md) - Wave-based execution details
- [Metadata Extraction Pattern](../concepts/patterns/metadata-extraction.md) - Context optimization
- [Context Management Pattern](../concepts/patterns/context-management.md) - Pruning techniques
- [Command Reference](../reference/command-reference.md) - Quick syntax reference
- [/coordinate Command Guide](./coordinate-command-guide.md) - Related orchestration command with workflow scope detection
