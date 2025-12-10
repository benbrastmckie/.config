# Standards and Design Patterns Audit: Architectural Patterns and Context Efficiency

**Research Assignment**: Standards and Design Patterns Audit
**Date**: 2025-12-10
**Researcher**: Claude Opus 4.5

---

## Executive Summary

This report documents a comprehensive audit of .claude/docs/ standards documentation, identifying proven architectural patterns, coordination mechanisms, and context efficiency strategies for optimizing orchestrator commands. The audit reveals a mature hierarchical agent architecture with **95-96% context reduction** capabilities, hard barrier enforcement patterns, and standardized coordination protocols.

**Key Findings**:
- Metadata-only passing achieves 95% context reduction (7,500 → 330 tokens for 3 reports)
- Brief summary parsing achieves 96% context reduction (2,000 → 80 tokens per iteration)
- Wave-based parallel execution yields 40-60% time savings
- Hard barrier pattern enforces 100% delegation success rate
- Research-coordinator pattern enables 10+ iterations (vs 3-4 before optimization)

**Recommended Application**: The lean-plan orchestrator optimization should leverage the research-coordinator pattern (Example 7), hard barrier enforcement (Example 6), and metadata-only context passing to achieve equivalent context reduction and parallelization benefits.

---

## Table of Contents

1. [Hierarchical Agent Architecture Overview](#hierarchical-agent-architecture-overview)
2. [Context Reduction Strategies](#context-reduction-strategies)
3. [Coordination Mechanisms](#coordination-mechanisms)
4. [Hard Barrier Subagent Delegation Pattern](#hard-barrier-subagent-delegation-pattern)
5. [Research Coordinator Integration Pattern](#research-coordinator-integration-pattern)
6. [Lean Command Coordinator Optimization](#lean-command-coordinator-optimization)
7. [Behavioral Injection Pattern](#behavioral-injection-pattern)
8. [Task Tool Invocation Standards](#task-tool-invocation-standards)
9. [Command Authoring Standards](#command-authoring-standards)
10. [Performance Metrics and Validation](#performance-metrics-and-validation)
11. [Recommendations for Lean-Plan Optimization](#recommendations-for-lean-plan-optimization)
12. [References](#references)

---

## 1. Hierarchical Agent Architecture Overview

### 1.1 Core Principles

The hierarchical agent architecture provides a structured approach to coordinating multiple specialized agents while maintaining context efficiency and clear responsibility boundaries.

**Fundamental Principles** (from hierarchical-agents-overview.md):

1. **Hierarchical Supervision**: Agents organized in supervisor → worker pattern
2. **Behavioral Injection**: Runtime behavior injection via file references (not hardcoded)
3. **Metadata-Only Context Passing**: Pass summaries (110 tokens) instead of full content (2,500 tokens)
4. **Single Source of Truth**: Agent behaviors exist in ONE location (`.claude/agents/*.md`)

**Architecture Structure**:
```
Orchestrator Command
    |
    +-- Supervisor Agent (research-coordinator, implementer-coordinator)
    |       +-- Worker Agent 1 (research-specialist)
    |       +-- Worker Agent 2 (research-specialist)
    |       +-- Worker Agent 3 (research-specialist)
    |
    +-- Planning Agent (plan-architect)
            +-- Uses metadata from supervisor, not full reports
```

### 1.2 Agent Roles and Responsibilities

| Role | Purpose | Tools | Invoked By | Context Scope |
|------|---------|-------|------------|---------------|
| **Orchestrator** | Coordinates workflow phases | All | User command | Full workflow state |
| **Supervisor** | Coordinates parallel workers | Task | Orchestrator | Aggregated metadata only |
| **Specialist** | Executes specific tasks | Domain-specific | Supervisor | Single task context |

### 1.3 Communication Flow

**Traditional Approach** (Context Explosion):
```
4 Workers x 2,500 tokens = 10,000 tokens to orchestrator
```

**Hierarchical Approach** (95.6% Reduction):
```
4 Workers x 2,500 tokens → Supervisor
Supervisor extracts 110 tokens/worker = 440 tokens to orchestrator
```

### 1.4 When to Use Hierarchical Architecture

**Use When**:
- Workflow has 4+ parallel agents
- Context reduction is critical
- Workers produce large outputs (>1,000 tokens each)
- Need clear responsibility boundaries
- Workflow has distinct phases (research, plan, implement)

**Don't Use When**:
- Single agent workflow
- Simple sequential operations
- Minimal context management needs
- No parallel execution benefits

---

## 2. Context Reduction Strategies

### 2.1 Metadata-Only Passing Pattern

**Core Strategy**: Supervisors extract metadata summaries from worker outputs and pass only essential information to orchestrator, achieving 95%+ context reduction.

**Metadata Format** (110 tokens per report):
```json
{
  "path": "/abs/path/to/001-report.md",
  "title": "Report Title",
  "findings_count": 12,
  "recommendations_count": 5,
  "summary": "50-word summary of key findings"
}
```

**Full Report** (2,500 tokens):
- Complete research findings
- Code examples
- References
- Detailed analysis

**Context Reduction Calculation**:
```
3 reports x 2,500 tokens = 7,500 tokens (traditional)
3 reports x 110 tokens = 330 tokens (metadata-only)
Reduction: (7,500 - 330) / 7,500 = 95.6%
```

### 2.2 Brief Summary Parsing Pattern

**Application**: Used in `/lean-implement` for iteration coordination between orchestrator and implementer-coordinator.

**Brief Summary Fields** (80 tokens):
- `summary_brief`: One-line iteration status
- `phases_completed`: Array of completed phase names
- `context_usage_percent`: Numeric percentage
- `work_remaining`: Boolean or phase count

**Full Summary File** (2,000 tokens):
- Detailed phase execution logs
- Error diagnostics
- Checkpoint markers
- Complete context usage analysis

**Context Reduction Calculation**:
```
1 summary x 2,000 tokens = 2,000 tokens (traditional)
1 summary x 80 tokens = 80 tokens (brief parsing)
Reduction: (2,000 - 80) / 2,000 = 96%
```

### 2.3 Pre-Calculation Pattern

**Purpose**: Calculate all paths and assignments BEFORE invoking agents to enable metadata-only passing.

**Pattern Structure**:
```bash
# Phase 0: Pre-calculate all paths
source "${LIB_DIR}/artifact-creation.sh"

TOPIC_DIR=$(get_or_create_topic_dir "$WORKFLOW_DESC" ".claude/specs")

declare -A REPORT_PATHS
for topic in "${TOPICS[@]}"; do
  REPORT_PATHS["$topic"]=$(create_topic_artifact "$TOPIC_DIR" "reports" "$topic" "")
done

export TOPIC_DIR REPORT_PATHS
```

**Context Injection** (into agent prompts):
```yaml
Task {
  subagent_type: "general-purpose"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md

    **Pre-Calculated Context**:
    - Output Path: ${REPORT_PATHS[$topic]}
    - Topic Directory: ${TOPIC_DIR}
    - Project Standards: ${CLAUDE_PROJECT_DIR}/CLAUDE.md
}
```

**Benefits**:
1. **Enables Verification**: Orchestrator knows expected paths before agent runs
2. **Reduces Agent Context**: Agent doesn't calculate paths, just uses provided
3. **Enables Hard Barriers**: Verification block validates exact pre-calculated paths
4. **Supports Parallel Execution**: Independent path assignments per agent

### 2.4 Metadata Extraction Functions

**Bash Pattern**:
```bash
extract_worker_metadata() {
  local worker_output="$1"

  # Extract key fields
  TITLE=$(echo "$worker_output" | grep -oP 'TITLE:\s*\K.+')
  PATH=$(echo "$worker_output" | grep -oP 'CREATED:\s*\K.+')
  SUMMARY=$(echo "$worker_output" | grep -oP 'SUMMARY:\s*\K.+' | head -c 200)

  # Return metadata object
  cat <<EOF
{
  "title": "$TITLE",
  "path": "$PATH",
  "summary": "$SUMMARY"
}
EOF
}
```

**Agent Integration** (in supervisor behavioral file):
```markdown
## STEP 5: Extract Metadata

For each worker output:
- TITLE: First heading
- SUMMARY: First 200 chars of overview
- PATH: File path
- FINDINGS_COUNT: Count of items in "## Findings" section
- RECOMMENDATIONS_COUNT: Count of items in "## Recommendations" section

Return aggregated metadata to orchestrator.
```

---

## 3. Coordination Mechanisms

### 3.1 Wave-Based Parallel Execution

**Pattern Definition**: Organize agents into waves based on dependencies, enabling parallel execution within waves and sequential execution between waves.

**Dependency Declaration**:
```yaml
phases:
  - name: "Research Authentication"
    dependencies: []
  - name: "Research Logging"
    dependencies: []
  - name: "Create Plan"
    dependencies: ["Research Authentication", "Research Logging"]
  - name: "Implement Auth"
    dependencies: ["Create Plan"]
  - name: "Implement Logging"
    dependencies: ["Create Plan"]
```

**Wave Execution**:
```
Wave 1 (Parallel):
  - Research Agent: Authentication patterns
  - Research Agent: Logging patterns

Wave 2 (After Wave 1):
  - Plan Architect: Create implementation plan

Wave 3 (Parallel):
  - Implementation Agent: Module A
  - Implementation Agent: Module B
```

**Time Savings Calculation**:
```
Sequential: 4 tasks x T = 4T
Parallel (2 waves): 2T + overhead
Savings: 50% (assuming 2 tasks per wave)
```

### 3.2 Supervisor Coordination Protocol

**Standardized Protocol** (from hierarchical-agents-coordination.md):

```markdown
## Coordination Protocol

### STEP 1: Parse Assignments
Extract worker tasks from orchestrator context.

### STEP 2: Pre-Calculate Paths
Calculate output paths for all workers BEFORE invocation.

### STEP 3: Invoke Workers (Parallel)
**CRITICAL**: Send ALL Task invocations in SINGLE message.

### STEP 4: Verify Completions
Check all workers completed successfully.

### STEP 5: Extract Metadata
Extract summary from each worker output.

### STEP 6: Return Aggregation
Return combined metadata to orchestrator.
```

### 3.3 All-At-Once Invocation Pattern

**Critical Requirement**: For independent tasks, invoke all agents in a single message to enable parallel execution.

**Correct Pattern**:
```markdown
**EXECUTE NOW**: Invoke all research agents in parallel

Task {
  subagent_type: "general-purpose"
  description: "Research topic 1"
  prompt: "..."
}

Task {
  subagent_type: "general-purpose"
  description: "Research topic 2"
  prompt: "..."
}

Task {
  subagent_type: "general-purpose"
  description: "Research topic 3"
  prompt: "..."
}
```

**Anti-Pattern** (Sequential):
```markdown
**EXECUTE NOW**: Research topic 1
Task { ... }

[wait for completion]

**EXECUTE NOW**: Research topic 2
Task { ... }
```

**Impact**: Sequential pattern prevents parallelization, losing 40-60% time savings.

### 3.4 Verification Checkpoints

**Pattern**: Verify agent outputs at each hierarchy level with fail-fast error handling.

**Orchestrator Verification**:
```bash
for topic in "${!EXPECTED_PATHS[@]}"; do
  EXPECTED="${EXPECTED_PATHS[$topic]}"

  if [ ! -f "$EXPECTED" ]; then
    echo "CRITICAL: Missing report at $EXPECTED"
    exit 1
  fi

  # Verify required sections
  if ! grep -q "## Findings" "$EXPECTED"; then
    echo "WARNING: Missing Findings section in $EXPECTED"
  fi
done
```

**Supervisor Verification** (in behavioral file):
```markdown
## STEP 4: Verify Completions

For each expected report path:
1. Check file exists at exact pre-calculated path
2. Verify file size > 500 bytes (not empty/stub)
3. Validate required sections present
4. Log errors with recovery instructions

If verification fails: Exit with TASK_ERROR signal
```

### 3.5 Context Budget Allocation

**Recommended Allocation** (from hierarchical-agents-coordination.md):
```
Total Context Budget: 100,000 tokens

Allocation:
- Command/Orchestrator: 30,000 tokens
- Per-Supervisor: 20,000 tokens
- Per-Worker: 10,000 tokens

With 4 workers per supervisor:
- Orchestrator: 30,000
- Supervisor: 20,000
- 4 Workers: 40,000
- Reserve: 10,000
```

**Thinking Mode Selection**:
| Complexity | Mode | Tokens | Use Case |
|------------|------|--------|----------|
| Simple | standard | +0 | Deterministic coordination |
| Moderate | think | +1,000 | Standard implementation |
| High | think hard | +2,000 | Complex reasoning |
| Critical | think harder | +4,000 | Proof search, delegation |

---

## 4. Hard Barrier Subagent Delegation Pattern

### 4.1 Pattern Overview

**Definition**: The Hard Barrier Pattern enforces mandatory subagent delegation in orchestrator commands by using bash verification blocks as context barriers that prevent bypass.

**Problem Solved**: Orchestrators with permissive tool access (Read, Edit, Write, Grep, Glob) can bypass Task invocation and perform subagent work directly, causing:
- 40-60% higher context usage in orchestrator
- No reusability of logic across workflows
- Architectural inconsistency
- Difficult to test

### 4.2 Pattern Structure: Setup → Execute → Verify

**Block Structure**:
```
Block N: Phase Name
├── Block Na: Setup
│   ├── State transition (fail-fast gate)
│   ├── Variable persistence (paths, metadata)
│   └── Checkpoint reporting
├── Block Nb: Execute [CRITICAL BARRIER]
│   └── Task invocation (MANDATORY)
└── Block Nc: Verify
    ├── Artifact existence check
    ├── Fail-fast on missing outputs
    └── Error logging with recovery hints
```

**Key Principle**: Bash blocks between Task invocations make bypass impossible. Claude cannot skip a bash verification block.

### 4.3 Implementation Template: Research Phase

**Block 1d: Report Path Pre-Calculation**:
```bash
set +H  # Disable history expansion

# Calculate report number (001, 002, 003...)
EXISTING_REPORTS=$(find "$RESEARCH_DIR" -name '[0-9][0-9][0-9]-*.md' 2>/dev/null | wc -l)
REPORT_NUMBER=$(printf "%03d" $((EXISTING_REPORTS + 1)))

# Generate report slug from workflow description
REPORT_SLUG=$(echo "${WORKFLOW_DESCRIPTION:-research}" | head -c 40 | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')

# Construct absolute report path
REPORT_PATH="${RESEARCH_DIR}/${REPORT_NUMBER}-${REPORT_SLUG}.md"

# Validate path is absolute
if [[ ! "$REPORT_PATH" =~ ^/ ]]; then
  log_command_error "validation_error" "Calculated REPORT_PATH is not absolute" "$REPORT_PATH"
  exit 1
fi

# Persist for Block 1e validation
append_workflow_state "REPORT_PATH" "$REPORT_PATH"

echo "Report Path: $REPORT_PATH"
```

**Block 1d-exec: Research Specialist Invocation**:
```markdown
**HARD BARRIER**: This block MUST invoke research-specialist via Task tool.
Block 1e will FAIL if report not created at the pre-calculated path.

**EXECUTE NOW**: Invoke research-specialist subagent

Task {
  subagent_type: "general-purpose"
  description: "Research ${WORKFLOW_DESCRIPTION} with mandatory file creation"
  prompt: |
    Read and follow ALL instructions in: .claude/agents/research-specialist.md

    **Input Contract (Hard Barrier Pattern)**:
    - Report Path: ${REPORT_PATH}
    - Output Directory: ${RESEARCH_DIR}
    - Research Topic: ${WORKFLOW_DESCRIPTION}

    **CRITICAL**: You MUST create the report file at the EXACT path specified above.
    The orchestrator has pre-calculated this path and will validate it exists.

    Return completion signal: REPORT_CREATED: ${REPORT_PATH}
}
```

**Block 1e: Agent Output Validation (Hard Barrier)**:
```bash
set +H

# Restore REPORT_PATH from state
source "$STATE_FILE"

echo "Expected report path: $REPORT_PATH"

# HARD BARRIER: Report file MUST exist
if [ ! -f "$REPORT_PATH" ]; then
  log_command_error "agent_error" \
    "research-specialist failed to create report file" \
    "Expected: $REPORT_PATH"
  echo "ERROR: HARD BARRIER FAILED - Report file not found"
  exit 1
fi

# Validate report is not empty or too small
REPORT_SIZE=$(wc -c < "$REPORT_PATH" 2>/dev/null || echo 0)
if [ "$REPORT_SIZE" -lt 100 ]; then
  log_command_error "validation_error" \
    "Report file too small ($REPORT_SIZE bytes)" \
    "Agent may have failed during write"
  exit 1
fi

# Validate report contains required sections
if ! grep -q "## Findings" "$REPORT_PATH" 2>/dev/null; then
  echo "WARNING: Report may be incomplete - missing Findings section"
fi

echo "Agent output validated: Report file exists ($REPORT_SIZE bytes)"
echo "Hard barrier passed - proceeding to Block 2"
```

### 4.4 Key Design Features

1. **Bash Blocks Between Task Invocations**: Makes bypass impossible
   - Claude cannot skip bash verification block
   - Fail-fast errors prevent progression without artifacts

2. **State Transitions as Gates**: Explicit state changes prevent phase skipping
   - `sm_transition` returns exit code
   - Non-zero exit code triggers error logging and exits

3. **Mandatory Task Invocation**: CRITICAL BARRIER label emphasizes requirement
   - Verification block depends on Task execution
   - No alternative path available

4. **Fail-Fast Verification**: Exits immediately on missing artifacts
   - Directory existence check
   - File count check (>= 1 required)
   - Timestamp checks (for modifications)

5. **Error Logging with Recovery**: All failures logged for debugging
   - `log_command_error` with error type
   - Recovery hints in error details
   - Queryable via `/errors` command

### 4.5 Results: Before vs After Hard Barriers

**Before Hard Barriers**:
- 40-60% context usage in orchestrator performing subagent work directly
- Inconsistent delegation (sometimes bypassed)
- No reusability of inline work

**After Hard Barriers**:
- Context reduction: orchestrator only coordinates
- 100% delegation success (bypass impossible)
- Modular architecture with focused agent responsibilities
- Predictable workflow execution

### 4.6 Enhanced Diagnostics

**Diagnostic Strategy** (from hard-barrier-subagent-delegation.md lines 573-602):

When verification blocks detect missing artifacts, enhanced diagnostics distinguish between:
1. **File at wrong location** - Agent created artifact but in unexpected directory
2. **File not created** - Agent failed to create artifact at all
3. **Silent failure** - Agent executed but produced no output

**Search Pattern**:
```bash
if [[ ! -f "$expected_artifact_path" ]]; then
  echo "❌ Hard barrier verification failed: Artifact file not found"
  echo "Expected: $expected_artifact_path"

  # Search for file in parent and topic directories
  local artifact_name=$(basename "$expected_artifact_path")
  local topic_dir=$(dirname "$(dirname "$expected_artifact_path")")
  local found_files=$(find "$topic_dir" -name "$artifact_name" 2>/dev/null || true)

  if [[ -n "$found_files" ]]; then
    echo "📍 Found at alternate location(s):"
    echo "$found_files" | while read -r file; do
      echo "  - $file"
    done
    log_command_error "agent_error" "Agent created file at wrong location" \
      "expected=$expected_artifact_path, found=$found_files"
  else
    echo "❌ Not found anywhere in topic directory: $topic_dir"
    log_command_error "agent_error" "Agent failed to create artifact file" \
      "expected=$expected_artifact_path, topic_dir=$topic_dir"
  fi

  exit 1
fi
```

---

## 5. Research Coordinator Integration Pattern

### 5.1 Pattern Overview

**Status**: IMPLEMENTED (as of 2025-12-08)

**Purpose**: Coordinate parallel research across multiple topics with metadata aggregation for context reduction.

**Problem Solved**:
- Traditional research workflows consume significant context (13+ tool calls inline)
- Research reports passed as full content (2,500 tokens per report)
- No parallelization of multi-topic research

**Solution**: research-coordinator agent orchestrates parallel research-specialist invocations, validates artifacts via hard barrier pattern, and returns metadata summaries (95% context reduction).

### 5.2 Architecture

```
/lean-plan Primary Agent
    |
    +-- research-coordinator (Supervisor)
            +-- research-specialist 1 (Mathlib Theorems)
            +-- research-specialist 2 (Proof Automation)
            +-- research-specialist 3 (Project Structure)
```

### 5.3 Implementation: Block 1d-topics

**Research Topics Classification**:
```bash
# Analyze feature description to identify 2-5 research topics
FEATURE_DESCRIPTION="Formalize group homomorphism theorems with automated proof tactics and proper project organization"

# Classify topics based on complexity
COMPLEXITY=3
case $COMPLEXITY in
  1|2) TOPIC_COUNT=2 ;;
  3) TOPIC_COUNT=3 ;;
  4) TOPIC_COUNT=4 ;;
esac

# Persist topics for coordinator
TOPICS=(
  "Mathlib Theorems for Group Homomorphism"
  "Proof Automation Strategies"
  "Lean 4 Project Structure Patterns"
)

append_workflow_state "TOPICS" "${TOPICS[*]}"
append_workflow_state "TOPIC_COUNT" "$TOPIC_COUNT"

echo "[CHECKPOINT] Research topics identified: $TOPIC_COUNT topics"
```

### 5.4 Implementation: Block 1d-calc

**Report Path Pre-Calculation**:
```bash
# Pre-calculate report paths BEFORE coordinator invocation (hard barrier pattern)
RESEARCH_DIR="${TOPIC_PATH}/reports"
mkdir -p "$RESEARCH_DIR"

# Find existing reports to determine starting number
EXISTING_REPORTS=$(ls "$RESEARCH_DIR"/[0-9][0-9][0-9]-*.md 2>/dev/null | wc -l)
START_NUM=$((EXISTING_REPORTS + 1))

# Calculate paths for each topic
REPORT_PATHS=()
for i in "${!TOPICS[@]}"; do
  REPORT_NUM=$(printf "%03d" $((START_NUM + i)))
  TOPIC_SLUG=$(echo "${TOPICS[$i]}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
  REPORT_PATHS+=("${RESEARCH_DIR}/${REPORT_NUM}-${TOPIC_SLUG}.md")
done

# Persist for coordinator and verification
append_workflow_state "REPORT_PATHS" "${REPORT_PATHS[*]}"
append_workflow_state "RESEARCH_DIR" "$RESEARCH_DIR"

echo "[CHECKPOINT] Report paths pre-calculated: ${#REPORT_PATHS[@]} paths"
```

### 5.5 Implementation: Block 1d-exec

**Research Coordinator Invocation**:
```markdown
**CRITICAL BARRIER**: This block MUST invoke research-coordinator via Task tool.
Verification block (1e) will FAIL if reports not created.

**EXECUTE NOW**: Invoke research-coordinator

Task {
  subagent_type: "general-purpose"
  description: "Coordinate parallel research across multiple topics"
  prompt: |
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-coordinator.md

    You are acting as a Research Coordinator Agent with the tools and constraints
    defined in that file.

    **Input Contract**:
    research_request: "Research for Lean formalization: ${FEATURE_DESCRIPTION}"
    research_complexity: ${COMPLEXITY}
    report_dir: ${RESEARCH_DIR}
    topic_path: ${TOPIC_PATH}
    context:
      feature_description: "${FEATURE_DESCRIPTION}"
      lean_project_path: "${LEAN_PROJECT_PATH}"
      topics: [${TOPICS[@]}]
      report_paths: [${REPORT_PATHS[@]}]

    Follow all steps in research-coordinator.md:
    1. STEP 1: Parse research request and verify reports directory
    2. STEP 2: Pre-calculate report paths (already provided above)
    3. STEP 3: Invoke parallel research-specialist workers
    4. STEP 4: Validate research artifacts (hard barrier)
    5. STEP 5: Extract metadata from reports
    6. STEP 6: Return aggregated metadata

    Expected return signal:
    RESEARCH_COMPLETE: {REPORT_COUNT}
    reports: [JSON array of report metadata]
    total_findings: {N}
    total_recommendations: {N}
}
```

### 5.6 Implementation: Block 1e

**Research Validation (Hard Barrier)**:
```bash
# Fail-fast if research directory missing
if [[ ! -d "$RESEARCH_DIR" ]]; then
  log_command_error "validation_error" \
    "Research directory not found: $RESEARCH_DIR" \
    "research-coordinator should have created this directory"
  echo "ERROR: Research validation failed"
  exit 1
fi

# Fail-fast if any pre-calculated report path missing
MISSING_REPORTS=()
for REPORT_PATH in "${REPORT_PATHS[@]}"; do
  if [[ ! -f "$REPORT_PATH" ]]; then
    MISSING_REPORTS+=("$REPORT_PATH")
  fi
done

if [[ ${#MISSING_REPORTS[@]} -gt 0 ]]; then
  log_command_error "validation_error" \
    "${#MISSING_REPORTS[@]} research reports missing after coordinator invocation" \
    "Missing reports: ${MISSING_REPORTS[*]}"
  echo "ERROR: Hard barrier validation failed"
  exit 1
fi

# Extract metadata from coordinator response
# Expected format: RESEARCH_COMPLETE: 3
#                  reports: [{"path": "...", "title": "...", "findings_count": 12, "recommendations_count": 5}, ...]

# Parse coordinator output
REPORT_METADATA_JSON="[...]"  # Extracted from coordinator return signal

# Persist metadata for planning phase
append_workflow_state "REPORT_METADATA" "$REPORT_METADATA_JSON"
append_workflow_state "VERIFIED_REPORT_COUNT" "${#REPORT_PATHS[@]}"

echo "[CHECKPOINT] Research verified: ${#REPORT_PATHS[@]} reports created"
echo "             Metadata extracted for planning phase"
```

### 5.7 Context Reduction Metrics

**Traditional Approach** (primary agent reads all reports):
```
3 reports x 2,500 tokens = 7,500 tokens consumed
```

**Coordinator Approach** (metadata-only):
```
3 reports x 110 tokens metadata = 330 tokens consumed
Context reduction: 95.6%
```

### 5.8 Metadata Format

Research-coordinator returns aggregated metadata instead of full content:

```json
{
  "reports": [
    {
      "path": "/abs/path/to/001-mathlib-group-homomorphism.md",
      "title": "Mathlib Theorems for Group Homomorphism",
      "findings_count": 12,
      "recommendations_count": 5
    },
    {
      "path": "/abs/path/to/002-proof-automation-strategies.md",
      "title": "Proof Automation Strategies",
      "findings_count": 8,
      "recommendations_count": 4
    },
    {
      "path": "/abs/path/to/003-lean-project-structure.md",
      "title": "Lean 4 Project Structure Patterns",
      "findings_count": 10,
      "recommendations_count": 6
    }
  ],
  "total_reports": 3,
  "total_findings": 30,
  "total_recommendations": 15
}
```

### 5.9 Downstream Consumer Integration

The plan-architect receives report paths and metadata (not full content):

```markdown
**EXECUTE NOW**: Invoke plan-architect

Task {
  subagent_type: "general-purpose"
  description: "Create Lean implementation plan"
  prompt: |
    Read and follow: .claude/agents/lean-plan-architect.md

    **Research Context**:
    Research Reports: ${#REPORT_PATHS[@]} reports created
    - ${REPORT_PATHS[0]} (12 findings, 5 recommendations)
    - ${REPORT_PATHS[1]} (8 findings, 4 recommendations)
    - ${REPORT_PATHS[2]} (10 findings, 6 recommendations)

    **CRITICAL**: You have access to these report paths via Read tool.
    DO NOT expect full report content in this prompt.
    Use Read tool to access specific sections as needed.

    Output: ${PLAN_PATH}
}
```

### 5.10 Benefits

1. **Parallel Execution**: 3 research-specialist agents run simultaneously (40-60% time savings)
2. **Context Reduction**: 95% reduction via metadata-only passing
3. **Hard Barrier Enforcement**: Mandatory delegation prevents bypass
4. **Modular Architecture**: research-coordinator reusable across commands
5. **Graceful Degradation**: Partial success mode if ≥50% reports created

### 5.11 Integration Points

Commands using research-coordinator:
- `/lean-plan` - Lean theorem research phase (IMPLEMENTED)
- `/create-plan` - Software feature research phase (INTEGRATED, automated topic detection)
- `/research` - Direct research command (INTEGRATED)
- `/repair` - Error pattern research phase (PLANNED)
- `/debug` - Issue investigation research phase (PLANNED)
- `/revise` - Context research before plan revision (PLANNED)

### 5.12 Success Criteria

Research coordination is successful if:
- All research topics decomposed correctly (2-5 topics)
- All report paths pre-calculated before agent invocation
- All research-specialist agents invoked in parallel
- All reports exist at pre-calculated paths (hard barrier validation)
- Metadata extracted for all reports (110 tokens per report)
- Aggregated metadata returned to primary agent
- Context reduction 95%+ vs full report content

### 5.13 Reliability Improvements (2025-12-09)

The research-coordinator agent has been significantly hardened against Task invocation skipping:

1. **STEP 2.5 Pre-Execution Barrier**: Mandatory invocation plan file creation prevents silent skipping
2. **Bash-Generated Task Invocations**: STEP 3 uses concrete for-loop pattern (no placeholders)
3. **Multi-Layer Validation**: STEP 4 validates plan file → trace file → reports
4. **Error Trap Handler**: Mandatory TASK_ERROR signal on any failure
5. **100% Invocation Rate**: All topics processed, no partial failures

### 5.14 Common Pitfalls (RESOLVED)

**Pitfall 1: Empty Reports Directory** (RESOLVED 2025-12-09)

**Status**: This pitfall was resolved with STEP 3 refactor and multi-layer validation.

**Previous Symptom**: research-coordinator completes but reports directory is empty
**Root Cause**: Task invocations in agent behavioral file use pseudo-code patterns
**Fix Applied**: Standards-compliant Task invocation patterns with multi-layer validation

---

## 6. Lean Command Coordinator Optimization

### 6.1 Pattern Overview

**Status**: IMPLEMENTED (as of 2025-12-08)

**Commands Affected**:
- `/lean-plan`: research-coordinator for parallel multi-topic Lean research
- `/lean-implement`: implementer-coordinator for wave-based orchestration

**Problem**: Lean commands operated with inefficient patterns:
- `/lean-plan`: Direct lean-research-specialist invocation (no coordinator delegation)
  - Missing 95% context reduction from metadata-only passing
  - Missing 40-60% time savings from parallel execution
- `/lean-implement`: Primary agent performing implementation work (bypassing coordinators)
  - Missing 96% context reduction from brief summary parsing
  - Missing wave-based parallel execution

**Solution**: Dual coordinator integration achieves 95-96% context reduction and 40-60% time savings.

### 6.2 Architecture: /lean-plan Command Flow

```
/lean-plan Command Flow:
┌─────────────────────────────────────────────────────────────┐
│ Block 1d-topics: Research Topics Classification             │
│ - Complexity-based topic count (C1-2→2, C3→3, C4→4)        │
│ - Lean-specific topics: Mathlib, Proofs, Structure, Style  │
└────────────────┬────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────┐
│ Block 1e-exec: research-coordinator (Supervisor)            │
│   ├─> research-specialist 1 (Mathlib Theorems)             │
│   ├─> research-specialist 2 (Proof Strategies)             │
│   └─> research-specialist 3 (Project Structure)            │
│ Returns: aggregated metadata (330 tokens vs 7,500)         │
└────────────────┬────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────┐
│ Block 1f: Hard Barrier Validation (Partial Success)         │
│ - ≥50% threshold (fails if <50%, warns if 50-99%)          │
└────────────────┬────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────┐
│ Block 1f-metadata: Extract Report Metadata                  │
│ - 95% context reduction (110 tokens/report)                │
└────────────────┬────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────┐
│ Block 2: lean-plan-architect (metadata-only context)        │
│ - Receives FORMATTED_METADATA (330 tokens)                 │
│ - Uses Read tool for full reports (delegated read)         │
└─────────────────────────────────────────────────────────────┘
```

### 6.3 Implementation: Block 1d-topics

**Research Topics Classification**:
```bash
# Complexity-based topic count for Lean research
case "$RESEARCH_COMPLEXITY" in
  1|2) TOPIC_COUNT=2 ;;
  3)   TOPIC_COUNT=3 ;;
  4)   TOPIC_COUNT=4 ;;
  *)   TOPIC_COUNT=3 ;;
esac

# Lean-specific research topics
LEAN_TOPICS=(
  "Mathlib Theorems"
  "Proof Strategies"
  "Project Structure"
  "Style Guide"
)

# Select topics based on count
TOPICS=()
for i in $(seq 0 $((TOPIC_COUNT - 1))); do
  if [ $i -lt ${#LEAN_TOPICS[@]} ]; then
    TOPICS+=("${LEAN_TOPICS[$i]}")
  fi
done

# Calculate report paths (hard barrier pattern)
REPORT_PATHS=()
for TOPIC in "${TOPICS[@]}"; do
  SLUG=$(echo "$TOPIC" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
  REPORT_FILE="${RESEARCH_DIR}/${PADDED_INDEX}-${SLUG}.md"
  REPORT_PATHS+=("$REPORT_FILE")
done

# Persist for coordinator invocation
append_workflow_state_bulk <<EOF
TOPICS=(${TOPICS[@]})
REPORT_PATHS=(${REPORT_PATHS[@]})
EOF

echo "[CHECKPOINT] Research topics: $TOPIC_COUNT topics classified"
```

### 6.4 Implementation: Block 1f

**Partial Success Mode Validation**:
```bash
# Validate each report
SUCCESSFUL_REPORTS=0
FAILED_REPORTS=()

for REPORT_PATH in "${REPORT_PATHS[@]}"; do
  if validate_agent_artifact "$REPORT_PATH" 500 "research report"; then
    SUCCESSFUL_REPORTS=$((SUCCESSFUL_REPORTS + 1))
  else
    FAILED_REPORTS+=("$REPORT_PATH")
  fi
done

# Calculate success percentage
SUCCESS_PERCENTAGE=$((SUCCESSFUL_REPORTS * 100 / TOTAL_REPORTS))

# Fail if <50% success
if [ $SUCCESS_PERCENTAGE -lt 50 ]; then
  log_command_error "validation_error" \
    "Research validation failed: <50% success rate" \
    "Only $SUCCESSFUL_REPORTS/$TOTAL_REPORTS reports created"
  exit 1
fi

# Warn if 50-99% success
if [ $SUCCESS_PERCENTAGE -lt 100 ]; then
  echo "WARNING: Partial research success (${SUCCESS_PERCENTAGE}%)" >&2
  echo "Proceeding with $SUCCESSFUL_REPORTS/$TOTAL_REPORTS reports..."
fi

echo "[CHECKPOINT] Validation: $SUCCESS_PERCENTAGE% success rate"
```

### 6.5 Architecture: /lean-implement Command Flow

```
/lean-implement Command Flow (Plan-Driven Mode):
┌─────────────────────────────────────────────────────────────┐
│ Block 1a: Pre-calculate Artifact Paths                      │
│ - SUMMARIES_DIR, DEBUG_DIR, OUTPUTS_DIR, CHECKPOINTS_DIR   │
└────────────────┬────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────┐
│ Block 1b: Route to Coordinator [HARD BARRIER]               │
│ - MANDATORY delegation (no conditionals)                    │
│ - lean-coordinator invocation (execution_mode: plan-based) │
│   └─> Wave-based parallel phase execution                  │
└────────────────┬────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────┐
│ Block 1c: Hard Barrier Validation + Brief Summary Parsing   │
│ - Validates summary exists (delegation bypass detection)    │
│ - Parses return signal fields (96% context reduction)      │
│   - summary_brief: 80 tokens vs 2,000 full file            │
│   - phases_completed, context_usage_percent                │
└─────────────────────────────────────────────────────────────┘
```

### 6.6 Implementation: Block 1b

**Plan-Driven Mode**: The /lean-implement command uses plan-driven mode for wave-based orchestration with lean-coordinator. This mode eliminates dependency analysis overhead by reading wave structure directly from plan metadata.

**execution_mode Parameter**: The lean-coordinator supports two modes:
1. **file-based**: Legacy mode for /lean-build (single wave, all theorems)
2. **plan-based**: Optimized mode for /lean-implement (wave extraction from plan metadata)

The /lean-implement command passes `execution_mode: plan-based` to lean-coordinator, enabling:
- Wave structure extracted from plan's `dependencies:` fields
- Sequential execution by default (one phase per wave)
- Parallel waves when `parallel_wave: true` + `wave_id` indicators present
- Brief summary format (80 tokens vs 2,000 tokens = 96% context reduction)
- NO dependency-analyzer.sh invocation (reads plan metadata directly)

**Hard Barrier Enforcement**:
```bash
# [HARD BARRIER] Coordinator delegation is MANDATORY (no conditionals, no bypass)
# The orchestrator MUST NOT perform implementation work directly

COORDINATOR_NAME="lean-coordinator"

# Persist coordinator name for Block 1c validation
append_workflow_state "COORDINATOR_NAME" "$COORDINATOR_NAME"

**EXECUTE NOW**: USE the Task tool to invoke lean-coordinator.

Task {
  subagent_type: "general-purpose"
  description: "Execute Lean theorem proving via lean-coordinator"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-coordinator.md

    **Input Contract (Hard Barrier Pattern)**:
    - plan_path: ${PLAN_FILE}
    - topic_path: ${TOPIC_PATH}
    - execution_mode: plan-based
    - summaries_dir: ${SUMMARIES_DIR}
    - artifact_paths:
      - summaries: ${SUMMARIES_DIR}
      - debug: ${DEBUG_DIR}
      - outputs: ${OUTPUTS_DIR}
      - checkpoints: ${CHECKPOINTS_DIR}

    Execute implementation according to behavioral guidelines.
  "
  model: "sonnet"
}

echo "[CHECKPOINT] Coordinator invoked: $COORDINATOR_NAME"
```

### 6.7 Implementation: Block 1c

**Brief Summary Parsing**:
```bash
# Validate summary exists (hard barrier validation)
LATEST_SUMMARY=$(find "$SUMMARIES_DIR" -name "*.md" -type f -mmin -10 | sort | tail -1)

if [ -z "$LATEST_SUMMARY" ]; then
  echo "ERROR: HARD BARRIER FAILED - Summary not created by $COORDINATOR_NAME" >&2
  log_command_error "agent_error" \
    "Coordinator $COORDINATOR_NAME did not create summary file"
  exit 1
fi

# Parse brief summary fields (96% context reduction)
SUMMARY_BRIEF=$(grep "^summary_brief:" "$LATEST_SUMMARY" | sed 's/^summary_brief:[[:space:]]*//')
PHASES_COMPLETED=$(grep "^phases_completed:" "$LATEST_SUMMARY" | sed 's/^phases_completed:[[:space:]]*//' | tr -d '[],"')
CONTEXT_USAGE_PERCENT=$(grep "^context_usage_percent:" "$LATEST_SUMMARY" | sed 's/^context_usage_percent:[[:space:]]*//' | sed 's/%//')
WORK_REMAINING=$(grep "^work_remaining:" "$LATEST_SUMMARY" | sed 's/^work_remaining:[[:space:]]*//')

# Display brief summary (no full file read required)
echo "Summary: $SUMMARY_BRIEF"
echo "Phases completed: ${PHASES_COMPLETED:-none}"
echo "Context usage: ${CONTEXT_USAGE_PERCENT}%"
echo "Full report: $LATEST_SUMMARY"

# Context reduction: 80 tokens parsed vs 2,000 tokens read = 96% reduction
```

### 6.8 Key Benefits Realized

**Context Reduction**:
1. `/lean-plan` research phase: 95% reduction (7,500 → 330 tokens)
2. `/lean-implement` iteration phase: 96% reduction (2,000 → 80 tokens)

**Time Savings**:
1. Parallel multi-topic research: 40-60% time reduction
2. Wave-based phase execution: 40-60% time reduction for independent phases

**Iteration Capacity**:
- Before: 3-4 iterations possible (context exhaustion)
- After: 10+ iterations possible (reduced context per iteration)

### 6.9 Validation Results

**Integration Tests**:
- `test_lean_plan_coordinator.sh`: 21 tests (100% pass rate)
- `test_lean_implement_coordinator.sh`: 27 tests (100% pass rate)
- `test_lean_coordinator_plan_mode.sh`: 7 tests PASS, 1 test SKIP (optional)
- Total: 55 tests (48 core + 7 plan-driven), 0 failures

**Pre-commit Validation**:
- Sourcing standards: PASS
- Error logging integration: PASS
- Three-tier sourcing pattern: PASS

### 6.10 Expected Behavior

**Successful /lean-plan Execution**:
- Research topics classified based on complexity (2-4 topics)
- research-coordinator invoked with TOPICS and REPORT_PATHS arrays
- Parallel research execution (3 specialists running concurrently)
- Metadata extraction (110 tokens per report)
- Partial success mode handles 1-2 failed reports gracefully (≥50% threshold)
- Plan-architect receives metadata-only context (330 tokens vs 7,500)

**Successful /lean-implement Execution**:
- Artifact paths pre-calculated in Block 1a (SUMMARIES_DIR, DEBUG_DIR, OUTPUTS_DIR, CHECKPOINTS_DIR)
- lean-coordinator invoked with complete artifact paths and execution_mode: plan-based
- Summary validated in Block 1c (delegation bypass detection)
- Brief summary parsed from return signal (80 tokens vs 2,000 full file)
- Iteration continuation via coordinator signals (REQUIRES_CONTINUATION, WORK_REMAINING)

---

## 7. Behavioral Injection Pattern

### 7.1 Pattern Definition

**Definition**: Behavioral Injection is a pattern where orchestrating commands inject execution context, artifact paths, and role clarifications into agent prompts through file content rather than tool invocations.

**Purpose**: Transform agents from autonomous executors into orchestrated workers that follow injected specifications.

The pattern separates:
- **Command role**: Orchestrator that calculates paths, manages state, delegates work
- **Agent role**: Executor that receives context via file reads and produces artifacts

### 7.2 Problems Solved

Commands that invoke other commands using the SlashCommand tool create two critical problems:

1. **Role Ambiguity**: When a command says "I'll research the topic", Claude interprets this as "I should execute research directly using Read/Grep/Write tools" instead of "I should orchestrate agents to research". This prevents hierarchical multi-agent patterns.

2. **Context Bloat**: Command-to-command invocations nest full command prompts within parent prompts, causing exponential context growth and breaking metadata-based context reduction.

Behavioral Injection solves both problems by:
- Making the orchestrator role explicit: "YOU ARE THE ORCHESTRATOR. DO NOT execute yourself."
- Injecting all necessary context into agent files: paths, constraints, specifications
- Enabling agents to read context and self-configure without tool invocations

### 7.3 Core Mechanism

**Phase 0: Role Clarification**

Every orchestrating command begins with explicit role declaration:

```markdown
## YOUR ROLE

You are the ORCHESTRATOR for this workflow. Your responsibilities:

1. Calculate artifact paths and workspace structure
2. Invoke specialized subagents via Task tool
3. Aggregate and forward subagent results
4. DO NOT execute implementation work yourself using Read/Grep/Write/Edit tools

YOU MUST NOT:
- Execute research directly (use research-specialist agent)
- Create plans directly (use planner-specialist agent)
- Implement code directly (use implementer agent)
- Write documentation directly (use doc-writer agent)
```

**Path Pre-Calculation**:

Before invoking any agent, calculate and validate all paths:

```bash
# Example from /orchestrate Phase 0
EXECUTE NOW - Calculate Paths:

1. Determine project root: /home/benjamin/.config
2. Find deepest directory encompassing workflow scope
3. Calculate next topic number: specs/NNN_topic/
4. Create topic directory structure:
   mkdir -p specs/027_authentication/{reports,plans,summaries,debug}
5. Assign artifact paths:
   REPORTS_DIR="specs/027_authentication/reports/"
   PLANS_DIR="specs/027_authentication/plans/"
   SUMMARIES_DIR="specs/027_authentication/summaries/"
```

**Context Injection via File Content**:

Inject context into agent prompts through structured data:

```yaml
# Injected into research-specialist agent prompt
research_context:
  topic: "OAuth 2.0 authentication patterns"
  scope: "Focus on implementation patterns for Node.js APIs"
  constraints:
    - "Must support refresh tokens"
    - "Must integrate with existing session management"
  output_path: "specs/027_authentication/reports/001_oauth_patterns.md"
  output_format:
    sections:
      - "OAuth 2.0 Flow Overview"
      - "Implementation Patterns"
      - "Security Considerations"
      - "Integration Strategy"
```

### 7.4 Structural Templates vs Behavioral Content

**IMPORTANT CLARIFICATION**: The behavioral injection pattern applies to agent behavioral guidelines, NOT to structural templates.

**Structural Templates (MUST remain inline)**:
- Task invocation syntax: `Task { subagent_type, description, prompt }`
- Bash execution blocks: `**EXECUTE NOW**: bash commands`
- JSON schemas: Data structure definitions
- Verification checkpoints: `**MANDATORY VERIFICATION**: file checks`
- Critical warnings: `**CRITICAL**: error conditions`

These are command execution structures, NOT agent behavioral content. They must remain inline for immediate execution and parsing.

**Behavioral Content (MUST be referenced, not duplicated)**:
- Agent STEP sequences: `STEP 1/2/3` procedural instructions
- File creation workflows: `PRIMARY OBLIGATION` blocks
- Agent verification steps: Agent-internal quality checks
- Output format specifications: Templates for agent responses

### 7.5 Valid Inline Templates

The following inline templates are correct and required:

```markdown
✓ CORRECT - Task invocation structure (structural template):

Task {
  subagent_type: "research-specialist"
  description: "Research authentication patterns"
  prompt: "
    Read and follow: .claude/agents/research-specialist.md

    CONTEXT (inject parameters, not procedures):
    - Topic: OAuth 2.0 authentication
    - Report path: specs/027_auth/reports/001_oauth_patterns.md

    (No STEP sequences here - those are in research-specialist.md)
  "
}
```

```markdown
✓ CORRECT - Bash execution blocks (structural template):

**EXECUTE NOW**: Run the following commands to prepare environment:

bash
mkdir -p specs/027_auth/{reports,plans,summaries}
export REPORT_PATH="specs/027_auth/reports/001_oauth_patterns.md"
```

```markdown
✓ CORRECT - Verification checkpoints (structural template):

**MANDATORY VERIFICATION**: After agent completes, verify:
- Report file exists at $REPORT_PATH
- Report contains all required sections
- File is properly formatted markdown

If verification fails, retry agent invocation with corrected path.
```

### 7.6 Anti-Pattern: Inline Template Duplication

**Example Violation 0: Duplicating Agent Behavioral Guidelines**

```markdown
❌ BAD - Duplicating agent behavioral guidelines inline:

Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: "
    Read and follow: .claude/agents/research-specialist.md

    **ABSOLUTE REQUIREMENT**: Creating the report file is your PRIMARY task.

    **STEP 1 (REQUIRED BEFORE STEP 2)**: Use Write tool to create file at ${REPORT_PATH}
    [... 30 lines of detailed instructions ...]

    **STEP 2 (REQUIRED BEFORE STEP 3)**: Conduct research
    [... 40 lines of detailed instructions ...]

    **STEP 3 (REQUIRED BEFORE STEP 4)**: Populate Report File
    [... 30 lines of detailed instructions ...]

    **STEP 4 (MANDATORY VERIFICATION)**: Verify and Return
    [... 20 lines of verification instructions ...]
  "
}
```

**Why This Fails**:
1. Duplicates 646 lines of research-specialist.md behavioral guidelines (~150 lines per invocation)
2. Creates maintenance burden: must manually sync template with behavioral file
3. Violates "single source of truth" principle: two locations for agent guidelines
4. Adds unnecessary bloat: 800+ lines across command file

**Correct Pattern** - Reference Behavioral File, Inject Context Only:
```markdown
✅ GOOD - Reference behavioral file with context injection:

Task {
  subagent_type: "general-purpose"
  description: "Research topic with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${RESEARCH_TOPIC}
    - Output Path: ${REPORT_PATH} (absolute path, pre-calculated)
    - Project Standards: ${STANDARDS_FILE}

    Execute research per behavioral guidelines.
    Return: REPORT_CREATED: ${REPORT_PATH}
  "
}
```

**Benefits**:
- 90% reduction: 150 lines → 15 lines per invocation
- Single source of truth: behavioral file is authoritative
- No synchronization needed: updates to behavioral file automatically apply
- Cleaner commands: focus on orchestration, not behavioral details

### 7.7 Performance Impact

**Measurable Improvements**:

**File Creation Rate:**
- Before: 60-80% (commands creating files in wrong locations)
- After: 100% (explicit path injection ensures correct locations)

**Context Reduction:**
- Before: 80-100% context usage (nested command prompts)
- After: <30% context usage (metadata-only passing between agents)

**Parallelization:**
- Before: Impossible (sequential command chaining)
- After: 40-60% time savings (independent agents run in parallel)

**Hierarchical Coordination:**
- Before: Flat command chaining (max 4 agents)
- After: Recursive supervision (10+ agents across 3 levels)

---

## 8. Task Tool Invocation Standards

### 8.1 Mandatory Imperative Directives

All Task tool invocations MUST be preceded by an explicit imperative directive. Pseudo-code syntax or instructional text patterns are PROHIBITED.

**Required Pattern**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the [AGENT_NAME] agent.

Task {
  subagent_type: "general-purpose"
  description: "Brief description"
  prompt: "..."
}
```

**Key Requirements**:
1. **Imperative instruction**: "**EXECUTE NOW**: USE the Task tool..." (explicit command to Claude)
2. **No code block wrapper**: Remove ` ```yaml ` fences around Task block
3. **No instructional text**: Don't use "# Use the Task tool to invoke..." comments without actual Task invocation
4. **Completion signal**: Agent must return explicit signal (e.g., `REPORT_CREATED: ${PATH}`)

### 8.2 Anti-Pattern: Pseudo-Code Syntax

**❌ PROHIBITED** (pseudo-code - will be skipped):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: |
    Read and follow ALL instructions in: agent.md
}
```

**Problem**: No imperative directive tells Claude to USE the Task tool. Claude interprets this as documentation, not executable code.

**✅ CORRECT** (imperative directive):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research topic with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${TOPIC}
    - Output Path: ${REPORT_PATH}

    Execute research per behavioral guidelines.
    Return: REPORT_CREATED: ${REPORT_PATH}
  "
}
```

### 8.3 Anti-Pattern: Instructional Text Without Task Invocation

**❌ PROHIBITED** (instructional text without actual invocation):
```markdown
## Phase 3: Agent Delegation

This phase invokes the research-specialist agent.
Use the Task tool to invoke the agent with the calculated paths.
```

**Problem**: Instructional text describes what SHOULD happen but doesn't actually invoke the Task tool. Claude reads the instruction but performs no action.

**✅ CORRECT** (actual Task invocation):
```markdown
## Phase 3: Agent Delegation

**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: "..."
}
```

### 8.4 Edge Case: Iteration Loop Invocations

When Task invocations occur inside iteration loops, the SAME invocation must have an imperative directive EACH time it appears in the control flow.

**Example** (from `/implement` command):
```markdown
## Block 5: Initial Implementation Attempt

**EXECUTE NOW**: USE the Task tool to invoke implementer-coordinator.

Task {
  subagent_type: "general-purpose"
  description: "Implement phase ${STARTING_PHASE}"
  prompt: "..."
}

## Block 7: Iteration Loop (if work remains)

```bash
if [ "$WORK_REMAINING" != "0" ]; then
  ITERATION=$((ITERATION + 1))
  echo "Iteration $ITERATION required"
fi
```

**EXECUTE NOW**: USE the Task tool to re-invoke implementer-coordinator for next iteration.

Task {
  subagent_type: "general-purpose"
  description: "Continue implementation (iteration ${ITERATION})"
  prompt: "..."
}
```

**Key Point**: Both Task blocks (initial and loop) require imperative directives, even though they invoke the same agent.

### 8.5 Edge Case: Agent Behavioral File Task Patterns

When agent behavioral files (e.g., research-coordinator.md) contain Task invocations that the agent should execute, use the same standards-compliant pattern as commands:

**CRITICAL REQUIREMENTS**:
1. **No code block wrappers**: Task invocations must NOT be wrapped in ``` fences
2. **Imperative directives**: Each Task invocation requires "**EXECUTE NOW**: USE the Task tool..." prefix
3. **Concrete values**: Use actual topic strings and paths, not bash variable placeholders like `${TOPICS[0]}`
4. **Checkpoint verification**: Add explicit "Did you just USE the Task tool?" checkpoints after invocations

**Example** (from research-coordinator.md STEP 3):

```markdown
**CHECKPOINT AFTER TOPIC 0**: Did you just USE the Task tool for topic at index 0?

**EXECUTE NOW**: USE the Task tool to invoke research-specialist for topic at index 0.

Task {
  subagent_type: "general-purpose"
  description: "Research topic at index 0 with mandatory file creation"
  prompt: "
    Read and follow behavioral guidelines from:
    (use CLAUDE_PROJECT_DIR)/.claude/agents/research-specialist.md

    **CRITICAL - Hard Barrier Pattern**:
    REPORT_PATH=(use REPORT_PATHS[0] - exact absolute path from array)

    **Research Topic**: (use TOPICS[0] - exact topic string from array)

    Execute research per behavioral guidelines.
    Return: REPORT_CREATED: (REPORT_PATHS[0])
  "
}
```

**Anti-Patterns** (DO NOT USE):
- ❌ Wrapping Task invocations in code blocks: ` ```Task { }``` `
- ❌ Using bash variable syntax: `${TOPICS[0]}` (looks like documentation)
- ❌ Separate logging code blocks: ` ```bash echo "..."``` ` before Task invocation
- ❌ Pseudo-code notation without imperative directive

**Why This Matters**:
- Agents interpret code-fenced Task blocks as documentation examples
- Bash variable syntax suggests shell interpolation, not actual execution
- Missing imperative directives = agent skips invocation = empty output directories
- Result: Coordinator completes with 0 Task invocations, workflow fails

---

## 9. Command Authoring Standards

### 9.1 Execution Directive Requirements

**Why Directives Are Necessary**: The LLM interprets bare code blocks in markdown files as **documentation or examples**, not executable code. Without explicit execution directives, bash blocks will be read but not executed, causing silent failures.

**Required Directive Phrases**:

Every bash code block in a command file MUST be preceded by an explicit execution directive using one of these phrases:

**Primary (Preferred)**:
- `**EXECUTE NOW**:` - Standard imperative directive

**Alternatives**:
- `Execute this bash block:` - Explicit block reference
- `Run the following:` - Clear action instruction
- `**STEP N**:` followed by action verb - Sequential numbering pattern

**Correct Pattern**:
```markdown
**EXECUTE NOW**: Initialize the state machine and validate configuration:

```bash
set +H  # Disable history expansion
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh"
# ... execution code
```
```

**Anti-Pattern** (Causes Silent Failure):
```markdown
## Part 1: Initialize State Machine

```bash
set +H
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh"
# ... code that will NOT be executed
```
```

### 9.2 Subprocess Isolation Requirements

**Core Principle**: Each bash code block runs in a **separate subprocess** (not subshell). All environment variables, bash functions, and process state are lost between blocks.

**Mandatory Patterns**:

#### Pattern 1: set +H at Start of Every Block

Disable bash history expansion to prevent `!` character issues:

```bash
set +H  # CRITICAL: Disable history expansion
# ... rest of code
```

**Why**: Bash history expansion corrupts indirect variable expansion (`${!var_name}`), causing "bad substitution" errors.

#### Pattern 2: Library Re-sourcing in Every Block

Libraries MUST be re-sourced in every bash block:

```bash
set +H  # CRITICAL: First line
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-logger.sh"
```

**Why**: Functions from libraries don't persist across subprocess boundaries.

#### Pattern 3: Return Code Verification

Critical functions MUST have explicit return code checks:

```bash
# CORRECT: Explicit check with error handling
if ! sm_init "$DESCRIPTION" "$COMMAND_NAME" "$WORKFLOW_TYPE" 2>&1; then
  echo "ERROR: State machine initialization failed" >&2
  exit 1
fi

# ALTERNATIVE: Simple check
sm_init "$DESCRIPTION" "$COMMAND_NAME" "$WORKFLOW_TYPE" || exit 1
```

**Why**: `set -euo pipefail` does NOT exit on function failures.

### 9.3 Bash Block Size Limits

**Size Thresholds**:

| Zone | Line Count | Status | Action Required |
|------|-----------|--------|----------------|
| **Safe Zone** | <300 lines | ✅ Recommended | None - ideal for complex logic |
| **Caution Zone** | 300-400 lines | ⚠️ Monitor | Review for split opportunities |
| **Prohibited** | >400 lines | ❌ Error | **MUST SPLIT** - causes preprocessing bugs |

**Technical Root Cause**: Claude's bash preprocessing applies transformations before execution (variable interpolation, command substitution, array expansion). These transformations are lossy and introduce subtle bugs when blocks exceed ~400 lines.

**Common Symptoms** (>400 line threshold):
- "bad substitution" errors during array operations
- Conditional expression failures (`if [[ ... ]]` breaks)
- Array expansion issues (unbound variable errors)
- Variable interpolation corruption

**Prevention Pattern**: Split at logical boundaries, use 2-3 consolidated blocks based on workflow phases:

```markdown
## Block 1: Setup and Initialization (Target: <300 lines)
**EXECUTE NOW**: Capture arguments, initialize state machine, persist state

## Block 2: Agent Invocation (Task tool - no bash block)
**EXECUTE NOW**: USE the Task tool to invoke subagent

## Block 3: Validation and Completion (Target: <250 lines)
**EXECUTE NOW**: Validate outputs, transition state, generate summary
```

### 9.4 State Persistence Patterns

**File-Based Communication**: Variables MUST be persisted to files using the state persistence library:

```bash
# In Block 1: Save state
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
append_workflow_state "VARIABLE_NAME" "$VARIABLE_VALUE"

# In Block 2: Load state
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
load_workflow_state "${WORKFLOW_ID:-$$}"
# $VARIABLE_NAME is now available
```

**Defensive Variable Initialization**: After sourcing a state file, initialize potentially unbound variables with defensive defaults to prevent unbound variable errors:

```bash
# Restore workflow state
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE"
else
  echo "ERROR: State file not found: $STATE_FILE" >&2
  exit 1
fi

# === DEFENSIVE VARIABLE INITIALIZATION ===
# Initialize potentially unbound variables with defaults
ORIGINAL_PROMPT_FILE_PATH="${ORIGINAL_PROMPT_FILE_PATH:-}"
RESEARCH_COMPLEXITY="${RESEARCH_COMPLEXITY:-3}"
FEATURE_DESCRIPTION="${FEATURE_DESCRIPTION:-}"
```

### 9.5 Output Suppression Requirements

Commands MUST suppress verbose output to maintain clean Claude Code display. Each bash block should produce minimal output focused on actionable results.

**Mandatory Suppression Patterns**:

#### Library Sourcing Suppression

All library sourcing MUST suppress output while preserving error handling:

```bash
source "${LIB_DIR}/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
```

#### Directory Operations Suppression

Directory operations MUST suppress non-critical output:

```bash
mkdir -p "$OUTPUT_DIR" 2>/dev/null || true
```

#### Single Summary Line per Block

Each block SHOULD output a single summary line instead of multiple progress messages:

```bash
# ✓ CORRECT: Single summary
# Perform all operations silently
source "$LIB" 2>/dev/null || exit 1
validate_config || exit 1
mkdir -p "$DIR" 2>/dev/null

echo "Setup complete: $WORKFLOW_ID"
```

### 9.6 Block Consolidation Strategy

Commands should balance clarity with execution efficiency by consolidating related operations into fewer bash blocks.

**Target Block Count**: Commands SHOULD use 2-3 bash blocks maximum to minimize display noise:

| Block | Purpose |
|-------|---------|
| **Setup** | Capture, validate, source, init, allocate |
| **Execute** | Main workflow logic |
| **Cleanup** | Verify, complete, summary |

**When to Consolidate vs. Separate**:

**Consolidate blocks when**:
- Operations are sequential dependencies (A must complete before B)
- No intermediate user visibility needed
- Operations share same error handling strategy
- Workflow is linear (<5 phases)

**Separate blocks when**:
- Operations need explicit checkpoints (user progress visibility)
- Different error handling strategies required
- Agent invocations needed (Task tool requires visible response)
- Complex workflows (>5 phases) benefit from phase boundaries

### 9.7 Directory Creation

Commands MUST follow the lazy directory creation pattern to prevent empty artifact directories.

**Required Pattern**:
- **DO**: Create only the topic root directory (`specs/NNN_topic/`)
- **DO NOT**: Create artifact subdirectories (`reports/`, `plans/`, `debug/`, `summaries/`, `outputs/`)
- **DELEGATE**: Let agents create subdirectories via `ensure_artifact_directory()` at write-time

```bash
# ✓ CORRECT: Command creates topic root only
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh"
TOPIC_DIR=$(create_topic_structure "feature_name")  # Creates ONLY topic root

# Agent handles subdirectory creation when writing files:
# ensure_artifact_directory "${TOPIC_DIR}/reports/001_analysis.md"
```

---

## 10. Performance Metrics and Validation

### 10.1 Context Reduction Metrics

**Metadata-Only Passing (Research Phase)**:
```
Traditional: 3 reports x 2,500 tokens = 7,500 tokens
Coordinator: 3 reports x 110 tokens = 330 tokens
Reduction: 95.6%
```

**Brief Summary Parsing (Implementation Phase)**:
```
Traditional: 1 summary x 2,000 tokens = 2,000 tokens
Coordinator: 1 summary x 80 tokens = 80 tokens
Reduction: 96%
```

### 10.2 Time Savings Metrics

**Parallel Execution**:
```
Sequential: 4 workers x T = 4T
Parallel (2 waves): 2T + overhead
Savings: 40-60%
```

**Wave-Based Execution**:
```
Before: 10 phases sequential = 10T
After: 3 waves (4+3+3 phases) = 4T + overhead
Savings: 55-60%
```

### 10.3 Iteration Capacity

**Context Exhaustion Analysis**:
```
Before Optimization:
- Context per iteration: 7,500 tokens (research) + 2,000 tokens (summary)
- Total per iteration: 9,500 tokens
- Maximum iterations: 100,000 / 9,500 ≈ 10 iterations (theoretical)
- Practical limit: 3-4 iterations (context fragmentation)

After Optimization:
- Context per iteration: 330 tokens (research) + 80 tokens (summary)
- Total per iteration: 410 tokens
- Maximum iterations: 100,000 / 410 ≈ 244 iterations (theoretical)
- Practical limit: 10+ iterations (reduced fragmentation)
```

### 10.4 Delegation Success Rate

**Hard Barrier Pattern**:
```
Before: 60-80% delegation success (bypass possible)
After: 100% delegation success (bypass structurally impossible)
```

### 10.5 Validation Test Results

**Lean Command Coordinator Optimization**:
- `test_lean_plan_coordinator.sh`: 21 tests (100% pass rate)
- `test_lean_implement_coordinator.sh`: 27 tests (100% pass rate)
- `test_lean_coordinator_plan_mode.sh`: 7 tests PASS, 1 test SKIP (optional)
- Total: 55 tests (48 core + 7 plan-driven), 0 failures

**Research Coordinator Pattern**:
- Integration tests: 100% pass rate
- Hard barrier validation: 100% success rate
- Partial success mode: Handles 50-99% report completion gracefully
- Error recovery: `/errors` command queryable logs

### 10.6 Performance Impact Summary

**File Creation Rate:**
- Before: 60-80% (commands creating files in wrong locations)
- After: 100% (explicit path injection ensures correct locations)

**Context Reduction:**
- Before: 80-100% context usage (nested command prompts, full content passing)
- After: <30% context usage (metadata-only passing between agents)

**Parallelization:**
- Before: Impossible (sequential command chaining)
- After: 40-60% time savings (independent agents run in parallel)

**Hierarchical Coordination:**
- Before: Flat command chaining (max 4 agents)
- After: Recursive supervision (10+ agents across 3 levels)

---

## 11. Recommendations for Lean-Plan Optimization

### 11.1 Apply Research Coordinator Pattern

**Recommendation**: Integrate research-coordinator into /lean-plan command for parallel multi-topic Lean research with metadata-only passing.

**Implementation Steps**:
1. **Topic Decomposition** (Block 1d-topics): Classify Lean research topics based on complexity (2-4 topics)
   - Complexity 1-2: 2 topics (Mathlib + Proofs)
   - Complexity 3: 3 topics (Mathlib + Proofs + Structure)
   - Complexity 4: 4 topics (Mathlib + Proofs + Structure + Style)

2. **Path Pre-Calculation** (Block 1d-calc): Calculate report paths BEFORE coordinator invocation
   - Use sequential numbering (001, 002, 003)
   - Generate slugs from topic names
   - Persist REPORT_PATHS array to state

3. **Coordinator Invocation** (Block 1e-exec): Invoke research-coordinator with pre-calculated context
   - Pass TOPICS and REPORT_PATHS arrays
   - Use hard barrier pattern (CRITICAL BARRIER label)
   - Expect RESEARCH_COMPLETE signal with metadata

4. **Hard Barrier Validation** (Block 1f): Validate all reports exist at pre-calculated paths
   - Fail if <50% reports created (partial success mode)
   - Warn if 50-99% reports created
   - Proceed to metadata extraction

5. **Metadata Extraction** (Block 1f-metadata): Parse coordinator response for aggregated metadata
   - Extract findings_count and recommendations_count per report
   - Calculate total_findings and total_recommendations
   - Persist FORMATTED_METADATA for plan-architect

6. **Plan-Architect Integration** (Block 2): Pass metadata-only context to plan-architect
   - Inject FORMATTED_METADATA (330 tokens vs 7,500 tokens)
   - Document that agent has Read tool access for full reports
   - Expect PLAN_CREATED signal

**Expected Results**:
- Context reduction: 95% (7,500 → 330 tokens)
- Time savings: 40-60% (parallel vs sequential research)
- Iteration capacity: 10+ iterations (vs 3-4 before)
- Delegation success: 100% (hard barrier enforcement)

### 11.2 Apply Hard Barrier Pattern

**Recommendation**: Enforce mandatory subagent delegation using Setup → Execute → Verify pattern.

**Implementation Steps**:
1. **Block Structure**: Split each delegation phase into 3 sub-blocks (Na/Nb/Nc)
2. **Setup Block (Na)**: State transition, variable persistence, checkpoint reporting
3. **Execute Block (Nb)**: Task invocation ONLY (no bash code)
4. **Verify Block (Nc)**: Artifact validation, fail-fast, error logging

**Expected Results**:
- Delegation success: 100% (bypass structurally impossible)
- Context efficiency: 40-60% reduction in orchestrator token usage
- Error recovery: Explicit checkpoints enable resume from failure
- Debuggability: Checkpoint markers trace execution flow

### 11.3 Apply Behavioral Injection Pattern

**Recommendation**: Reference agent behavioral files instead of duplicating guidelines inline.

**Implementation Steps**:
1. **Role Clarification**: Add "YOU ARE THE ORCHESTRATOR" section in command
2. **Path Pre-Calculation**: Calculate all paths BEFORE agent invocation
3. **Context Injection**: Inject paths and constraints into agent prompts (not procedures)
4. **Single Source of Truth**: Reference `.claude/agents/*.md` files, don't duplicate

**Expected Results**:
- 90% reduction in command file size (150 lines → 15 lines per invocation)
- Maintenance burden eliminated (single source of truth)
- File creation rate: 100% (explicit path injection)

### 11.4 Apply Task Tool Invocation Standards

**Recommendation**: Use imperative directives for all Task invocations, avoid pseudo-code patterns.

**Implementation Steps**:
1. **Imperative Directives**: Prefix all Task blocks with "**EXECUTE NOW**: USE the Task tool..."
2. **No Code Block Wrappers**: Remove ` ```yaml ` fences around Task invocations
3. **Inline Prompts**: Use inline prompts with variable interpolation (not code blocks)
4. **Completion Signals**: Require agents to return explicit signals (e.g., `REPORT_CREATED:`)
5. **Checkpoint Verification**: Add "Did you just USE the Task tool?" checkpoints in agent behavioral files

**Expected Results**:
- Delegation rate: 100% (all Task invocations execute)
- Error visibility: Silent failures eliminated
- Diagnostic ease: Clear execution traces

### 11.5 Apply Command Authoring Standards

**Recommendation**: Follow execution directive requirements, subprocess isolation patterns, and block consolidation strategies.

**Implementation Steps**:
1. **Execution Directives**: Prefix all bash blocks with "**EXECUTE NOW**:"
2. **Subprocess Isolation**: Add `set +H` to every block, re-source libraries
3. **Block Size Limits**: Keep blocks <400 lines (target 2-3 blocks per command)
4. **State Persistence**: Use `append_workflow_state` for cross-block communication
5. **Output Suppression**: Suppress library sourcing with `2>/dev/null`, single summary per block
6. **Directory Creation**: Create topic root only, delegate subdirectories to agents

**Expected Results**:
- Execution reliability: 100% (directives prevent silent failures)
- Preprocessing stability: Zero "bad substitution" errors
- Context clarity: 67% reduction in display noise (6 → 2 blocks)

### 11.6 Integration Checklist

**Phase 0: Setup**
- [ ] Add role clarification ("YOU ARE THE ORCHESTRATOR")
- [ ] Source unified-location-detection.sh for topic allocation
- [ ] Calculate topic directory with `create_topic_structure()`
- [ ] Initialize state machine with `sm_init()`
- [ ] Persist WORKFLOW_ID and TOPIC_DIR to state

**Phase 1d: Research Topics Classification**
- [ ] Determine topic count based on RESEARCH_COMPLEXITY (1-2→2, 3→3, 4→4)
- [ ] Define Lean-specific topics array (Mathlib, Proofs, Structure, Style)
- [ ] Select topics based on count
- [ ] Persist TOPICS array to state
- [ ] Output checkpoint: "[CHECKPOINT] Research topics: N topics classified"

**Phase 1d-calc: Report Path Pre-Calculation**
- [ ] Create RESEARCH_DIR (topic root only, not reports/)
- [ ] Find existing reports count for sequential numbering
- [ ] Calculate REPORT_PATHS array (one per topic)
- [ ] Validate all paths are absolute (regex check)
- [ ] Persist REPORT_PATHS array to state
- [ ] Output checkpoint: "[CHECKPOINT] Report paths pre-calculated: N paths"

**Phase 1e-exec: Research Coordinator Invocation**
- [ ] Add CRITICAL BARRIER label
- [ ] Use imperative directive: "**EXECUTE NOW**: USE the Task tool..."
- [ ] Invoke research-coordinator with Task tool
- [ ] Pass TOPICS and REPORT_PATHS arrays in prompt
- [ ] Document expected return signal (RESEARCH_COMPLETE)
- [ ] No bash code in execute block

**Phase 1f: Hard Barrier Validation**
- [ ] Re-source state-persistence.sh (subprocess isolation)
- [ ] Restore REPORT_PATHS from state
- [ ] Validate RESEARCH_DIR exists
- [ ] Validate all REPORT_PATHS exist (fail-fast)
- [ ] Calculate success percentage (≥50% threshold)
- [ ] Log errors with recovery instructions
- [ ] Output checkpoint: "[CHECKPOINT] Validation: N% success rate"

**Phase 1f-metadata: Metadata Extraction**
- [ ] Parse coordinator response for report metadata
- [ ] Extract findings_count and recommendations_count per report
- [ ] Calculate total_findings and total_recommendations
- [ ] Format metadata for plan-architect (110 tokens per report)
- [ ] Persist FORMATTED_METADATA to state
- [ ] Output checkpoint: "[CHECKPOINT] Metadata extracted for planning phase"

**Phase 2: Plan-Architect Integration**
- [ ] Add CRITICAL BARRIER label
- [ ] Use imperative directive: "**EXECUTE NOW**: USE the Task tool..."
- [ ] Invoke lean-plan-architect with Task tool
- [ ] Pass FORMATTED_METADATA in prompt (not full reports)
- [ ] Document Read tool access for full reports
- [ ] Expect PLAN_CREATED signal
- [ ] No bash code in execute block

**Phase 2-verify: Plan Validation**
- [ ] Re-source error-handling.sh (subprocess isolation)
- [ ] Restore PLAN_PATH from state
- [ ] Validate PLAN_PATH exists (fail-fast)
- [ ] Validate file size > 500 bytes
- [ ] Validate required sections present
- [ ] Log errors with recovery instructions
- [ ] Output checkpoint: "[CHECKPOINT] Plan validation passed"

**Phase 3: Completion**
- [ ] Transition state to COMPLETE
- [ ] Generate console summary (4-section format)
- [ ] Output artifacts created (plan path, report paths)
- [ ] Output next steps (e.g., "Run /lean-implement [PLAN_PATH]")

### 11.7 Expected Outcomes

**Context Reduction**:
- Research phase: 95% reduction (7,500 → 330 tokens)
- Planning phase: Delegated read pattern (plan-architect uses Read tool, not inline content)
- Total workflow: <30% context usage (vs 80-100% before)

**Time Savings**:
- Parallel research: 40-60% time reduction (3 specialists running concurrently)
- No sequential bottlenecks (all research in Wave 1)

**Iteration Capacity**:
- Before: 3-4 iterations possible (context exhaustion)
- After: 10+ iterations possible (reduced context per iteration)

**Reliability**:
- Delegation success: 100% (hard barrier enforcement)
- File creation rate: 100% (path pre-calculation + validation)
- Error visibility: 100% (queryable logs via `/errors` command)

**Maintainability**:
- Command file size: 90% reduction (behavioral injection)
- Single source of truth: Agent behavioral files authoritative
- Clear block structure: Setup → Execute → Verify pattern

---

## 12. References

### 12.1 Primary Documentation Sources

**Hierarchical Agent Architecture**:
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-overview.md` - Architecture fundamentals and core principles
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-coordination.md` - Multi-agent coordination patterns and context management
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-examples.md` - Example 6 (Hard Barrier), Example 7 (Research Coordinator), Example 8 (Lean Coordinator)
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-patterns.md` - Design patterns and anti-patterns
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-communication.md` - Agent communication protocols and signal formats

**Patterns Documentation**:
- `/home/benjamin/.config/.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md` - Complete hard barrier pattern documentation
- `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md` - Behavioral injection pattern with case studies
- `/home/benjamin/.config/.claude/docs/concepts/patterns/metadata-extraction.md` - Context reduction via metadata extraction

**Command Authoring Standards**:
- `/home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md` - Complete command development standards including Task invocation, subprocess isolation, and block consolidation

**Integration Guides**:
- `/home/benjamin/.config/.claude/docs/guides/development/research-coordinator-migration-guide.md` - Step-by-step migration guide for research-coordinator integration
- `/home/benjamin/.config/.claude/docs/reference/standards/research-invocation-standards.md` - Decision matrix for coordinator vs specialist invocation

### 12.2 Performance Metrics Sources

**Context Reduction**:
- hierarchical-agents-overview.md lines 52-93: Metadata-only passing achieves 95% reduction
- hierarchical-agents-examples.md lines 731-770: Research coordinator metadata format (110 tokens per report)
- hierarchical-agents-examples.md lines 1139-1183: Brief summary parsing achieves 96% reduction

**Time Savings**:
- hierarchical-agents-coordination.md lines 13-47: Wave-based parallel execution yields 40-60% time savings
- hierarchical-agents-examples.md lines 1143-1185: Lean command coordinator optimization results

**Validation**:
- hierarchical-agents-examples.md lines 1158-1161: Integration test results (55 tests, 100% pass rate)
- hierarchical-agents-examples.md lines 1163-1166: Pre-commit validation (PASS)

### 12.3 Implementation Reference Commands

**Implemented Patterns**:
- `/lean-plan` - research-coordinator integration (Example 8)
- `/lean-implement` - implementer-coordinator integration (Example 8)
- `/create-plan` - research-coordinator integration with automated topic detection
- `/research` - research-coordinator integration (direct research command)
- `/revise` - Hard barrier pattern (Example 6)

**Agent Behavioral Files**:
- `.claude/agents/research-coordinator.md` - Research supervisor agent with STEP 3 Bash-generated Task invocations
- `.claude/agents/research-specialist.md` - Research worker agent
- `.claude/agents/lean-coordinator.md` - Lean implementation coordinator (plan-driven mode)
- `.claude/agents/lean-plan-architect.md` - Lean planning agent with metadata-only context

### 12.4 Validation and Testing

**Test Suites**:
- `.claude/tests/test_lean_plan_coordinator.sh` - 21 tests (100% pass rate)
- `.claude/tests/test_lean_implement_coordinator.sh` - 27 tests (100% pass rate)
- `.claude/tests/test_lean_coordinator_plan_mode.sh` - 7 tests PASS, 1 test SKIP (optional)

**Validation Scripts**:
- `.claude/scripts/lint-task-invocation-pattern.sh` - Task invocation pattern linter
- `.claude/scripts/validate-all-standards.sh` - Unified standards validator

**Error Management**:
- `/errors` command - Query logged errors with filters (--command, --type, --since)
- `/repair` command - Analyze error patterns and create fix plans
- `.claude/lib/core/error-handling.sh` - Centralized error logging library

---

## Conclusion

This audit reveals a mature hierarchical agent architecture with proven patterns for achieving 95-96% context reduction and 40-60% time savings through metadata-only passing, wave-based parallel execution, and hard barrier enforcement. The research-coordinator pattern (Example 7) and lean-command coordinator optimization (Example 8) demonstrate successful application of these patterns with comprehensive validation (55 tests, 100% pass rate).

**Key Takeaways for Lean-Plan Optimization**:
1. **Apply Research Coordinator Pattern**: Parallel multi-topic research with metadata aggregation
2. **Enforce Hard Barriers**: Setup → Execute → Verify pattern prevents delegation bypass
3. **Use Behavioral Injection**: Reference agent files instead of duplicating guidelines
4. **Follow Task Invocation Standards**: Imperative directives prevent silent failures
5. **Consolidate Bash Blocks**: Target 2-3 blocks per command, keep <400 lines per block

**Recommended Next Steps**:
1. Review hierarchical-agents-examples.md Example 7 for research-coordinator integration details
2. Review hierarchical-agents-examples.md Example 8 for lean-command coordinator optimization
3. Review research-coordinator-migration-guide.md for step-by-step integration instructions
4. Apply integration checklist (Section 11.6) to /lean-plan command
5. Validate with test suite and pre-commit hooks

**Expected Results**: 95% context reduction, 40-60% time savings, 10+ iteration capacity, 100% delegation success rate.
