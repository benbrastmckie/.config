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
source "${CLAUDE_CONFIG}/.claude/lib/core/unified-location-detection.sh"

# Metadata extraction
source "${CLAUDE_CONFIG}/.claude/lib/workflow/metadata-extraction.sh"

# Checkpoint management
source "${CLAUDE_CONFIG}/.claude/lib/workflow/checkpoint-utils.sh"

# Error handling
source "${CLAUDE_CONFIG}/.claude/lib/core/error-handling.sh"

# Progress streaming
source "${CLAUDE_CONFIG}/.claude/lib/core/unified-logger.sh"
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
source "${CLAUDE_CONFIG:-${HOME}/.config}/.claude/lib/core/unified-location-detection.sh"

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
