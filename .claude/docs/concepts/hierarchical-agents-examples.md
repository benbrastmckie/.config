# Hierarchical Agent Architecture: Examples

**Related Documents**:
- [Overview](hierarchical-agents-overview.md) - Architecture fundamentals
- [Patterns](hierarchical-agents-patterns.md) - Design patterns
- [Troubleshooting](hierarchical-agents-troubleshooting.md) - Common issues

---

## Example 1: Research Workflow

### Scenario

Research 3 topics in parallel, then create implementation plan.

### Hierarchy

```
/orchestrate command
    |
    +-- Research Phase (Wave 1)
    |       +-- Research Agent: Authentication
    |       +-- Research Agent: Error Handling
    |       +-- Research Agent: Logging
    |
    +-- Planning Phase (Wave 2)
            +-- Plan Architect
```

### Implementation

```markdown
## Phase 0: Pre-Calculate Paths

```bash
TOPIC_DIR=$(get_or_create_topic_dir "$WORKFLOW" ".claude/specs")

declare -A REPORT_PATHS
REPORT_PATHS["auth"]="${TOPIC_DIR}/reports/001_authentication.md"
REPORT_PATHS["errors"]="${TOPIC_DIR}/reports/002_error_handling.md"
REPORT_PATHS["logging"]="${TOPIC_DIR}/reports/003_logging.md"

PLAN_PATH="${TOPIC_DIR}/plans/001_implementation.md"
```

## Phase 1: Research (Parallel)

**EXECUTE NOW**: Invoke research agents

Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md
    Topic: Authentication patterns in Lua
    Output: ${REPORT_PATHS["auth"]}
}

Task {
  subagent_type: "general-purpose"
  description: "Research error handling"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md
    Topic: Error handling best practices
    Output: ${REPORT_PATHS["errors"]}
}

Task {
  subagent_type: "general-purpose"
  description: "Research logging"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md
    Topic: Structured logging patterns
    Output: ${REPORT_PATHS["logging"]}
}

## Phase 2: Planning (Sequential)

**EXECUTE NOW**: Create implementation plan

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: |
    Read and follow: .claude/agents/plan-architect.md

    Research Reports:
    - ${REPORT_PATHS["auth"]}
    - ${REPORT_PATHS["errors"]}
    - ${REPORT_PATHS["logging"]}

    Output: ${PLAN_PATH}
}
```

### Expected Output

```
.claude/specs/042_feature/
    reports/
        001_authentication.md
        002_error_handling.md
        003_logging.md
    plans/
        001_implementation.md
```

---

## Example 2: Supervisor Pattern

### Scenario

Use a supervisor to coordinate workers and aggregate metadata.

### Supervisor Agent File

```markdown
# Research Supervisor Agent

**Location**: .claude/agents/research-supervisor.md

## PURPOSE

Coordinate parallel research workers and aggregate their outputs.

## STEP 1: Parse Worker Assignments

Extract topics and paths from orchestrator context.

## STEP 2: Invoke Workers (Parallel)

**EXECUTE NOW**: Invoke research-specialist for each topic

```yaml
Task {
  subagent_type: "general-purpose"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md
    Topic: ${topic}
    Output: ${path}
}
```

## STEP 3: Verify Completions

Check all expected files exist.

## STEP 4: Extract Metadata

For each worker output:
- TITLE: First heading
- SUMMARY: First 200 chars of overview
- PATH: File path

## STEP 5: Return Aggregation

```json
{
  "status": "complete",
  "reports": [
    {"title": "...", "path": "...", "summary": "..."},
    ...
  ]
}
```
```

### Orchestrator Invocation

```markdown
**EXECUTE NOW**: Invoke research supervisor

Task {
  subagent_type: "general-purpose"
  description: "Coordinate research phase"
  prompt: |
    Read and follow: .claude/agents/research-supervisor.md

    Topics:
    - topic: "auth", path: "${PATHS['auth']}"
    - topic: "errors", path: "${PATHS['errors']}"
    - topic: "logging", path: "${PATHS['logging']}"
}
```

### Metadata Flow

```
Worker Output (each): 2,500 tokens
    |
    v
Supervisor extracts: 110 tokens per worker
    |
    v
Orchestrator receives: 330 tokens total

Context Reduction: 87%
```

---

## Example 3: Wave-Based Implementation

### Scenario

Implement features in waves based on dependencies.

### Wave Structure

```yaml
phases:
  - name: "Setup Core Infrastructure"
    dependencies: []
  - name: "Implement Authentication"
    dependencies: ["Setup Core Infrastructure"]
  - name: "Implement Logging"
    dependencies: ["Setup Core Infrastructure"]
  - name: "Implement Error Handling"
    dependencies: ["Implement Authentication", "Implement Logging"]
  - name: "Integration Testing"
    dependencies: ["Implement Error Handling"]
```

### Execution

```markdown
## Wave 1: Core Infrastructure

**EXECUTE NOW**: Setup core infrastructure

Task {
  description: "Setup core infrastructure"
  prompt: |
    Read and follow: .claude/agents/implementation-agent.md
    Phase: Setup Core Infrastructure
    Plan: ${PLAN_PATH}
}

**VERIFICATION**: Core infrastructure complete

## Wave 2: Auth + Logging (Parallel)

**EXECUTE NOW**: Implement in parallel

Task {
  description: "Implement authentication"
  prompt: |
    Read and follow: .claude/agents/implementation-agent.md
    Phase: Implement Authentication
}

Task {
  description: "Implement logging"
  prompt: |
    Read and follow: .claude/agents/implementation-agent.md
    Phase: Implement Logging
}

## Wave 3: Error Handling

**EXECUTE NOW**: Implement error handling

Task {
  description: "Implement error handling"
  prompt: |
    Read and follow: .claude/agents/implementation-agent.md
    Phase: Implement Error Handling
}

## Wave 4: Testing

**EXECUTE NOW**: Run integration tests

Task {
  description: "Integration testing"
  prompt: |
    Read and follow: .claude/agents/test-specialist.md
    Phase: Integration Testing
}
```

---

## Example 4: Error Recovery

### Scenario

Handle worker failure gracefully.

### Implementation

```bash
# Invoke worker with verification
invoke_with_recovery() {
  local topic="$1"
  local path="$2"
  local max_retries=2

  for attempt in $(seq 1 $max_retries); do
    # Invoke agent
    invoke_research_agent "$topic" "$path"

    # Verify output
    if [ -f "$path" ]; then
      echo "SUCCESS: $topic completed"
      return 0
    fi

    echo "RETRY $attempt: $topic failed, retrying..."
    sleep 2
  done

  # All retries failed
  echo "ERROR: $topic failed after $max_retries attempts"
  return 1
}

# Use in workflow
for topic in "${TOPICS[@]}"; do
  if ! invoke_with_recovery "$topic" "${PATHS[$topic]}"; then
    echo "CRITICAL: Cannot proceed without $topic"
    exit 1
  fi
done
```

---

## Example 5: Context Injection

### Scenario

Inject workflow-specific context into generic agent.

### Generic Agent

```markdown
# Research Specialist Agent

## STEP 1: Read Context
Parse workflow context from prompt.

## STEP 2: Execute Research
Use context to guide research.

## STEP 3: Create Output
Create file at specified path.
```

### Context Injection

```yaml
Task {
  prompt: |
    Read and follow: .claude/agents/research-specialist.md

    **Workflow Context**:
    - Topic: OAuth 2.0 patterns
    - Focus Areas: Security, performance, maintainability
    - Codebase: Lua/Neovim configuration
    - Output: /path/to/report.md

    **Research Requirements**:
    - Analyze existing auth in codebase
    - Research 2025 best practices
    - Provide actionable recommendations

    **Quality Bar**:
    - Minimum 5 recommendations
    - Include code examples
    - Reference specific codebase files
}
```

### Benefits

1. Generic agent, specific context
2. Single behavioral source
3. Easy to customize per workflow
4. Clear separation of concerns

---

## Example 6: Hard Barrier Pattern (/revise Command)

### Scenario

Enforce subagent delegation using hard context barriers to prevent bypass.

### Problem

Without barriers, orchestrators may bypass Task invocation and perform work directly due to permissive tool access (Read, Edit, Grep, Glob).

### Solution: Setup → Execute → Verify Pattern

```
Block N: Phase Name
├── Block Na: Setup
│   ├── State transition (fail-fast)
│   ├── Variable persistence
│   └── Checkpoint reporting
├── Block Nb: Execute [CRITICAL BARRIER]
│   └── Task invocation (MANDATORY)
└── Block Nc: Verify
    ├── Artifact existence check
    ├── Fail-fast on missing outputs
    └── Error logging with recovery hints
```

### Implementation: /revise Command

```markdown
## Block 4a: Research Setup

```bash
# State transition blocks progression until complete
sm_transition "RESEARCH" || {
  log_command_error "state_error" "Failed to transition to RESEARCH" "..."
  exit 1
}

# Pre-calculate paths for subagent
RESEARCH_DIR="${TOPIC_PATH}/reports"
mkdir -p "$RESEARCH_DIR"

# Persist for next block
append_workflow_state "RESEARCH_DIR" "$RESEARCH_DIR"

echo "[CHECKPOINT] Ready for research-specialist invocation"
```

## Block 4b: Research Execution

**CRITICAL BARRIER**: This block MUST invoke research-specialist via Task tool.
Verification block (4c) will FAIL if reports not created.

**EXECUTE NOW**: Invoke research-specialist

Task {
  subagent_type: "general-purpose"
  description: "Research revision insights"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md

    Revision Details: ${REVISION_DETAILS}
    Output Directory: ${RESEARCH_DIR}

    Create research reports analyzing:
    - Impact of proposed changes
    - Dependencies affected
    - Recommended implementation approach
}

## Block 4c: Research Verification

```bash
# Fail-fast if directory missing
if [[ ! -d "$RESEARCH_DIR" ]]; then
  log_command_error "verification_error" \
    "Research directory not found: $RESEARCH_DIR" \
    "research-specialist should have created this directory"
  echo "ERROR: Research verification failed"
  exit 1
fi

# Fail-fast if no reports created
REPORT_COUNT=$(find "$RESEARCH_DIR" -name "*.md" -type f | wc -l)
if [[ "$REPORT_COUNT" -eq 0 ]]; then
  log_command_error "verification_error" \
    "No research reports found in $RESEARCH_DIR" \
    "research-specialist should have created at least one report"
  echo "ERROR: Research verification failed"
  exit 1
fi

# Persist report count for next phase
append_workflow_state "REPORT_COUNT" "$REPORT_COUNT"

echo "[CHECKPOINT] Research verified: $REPORT_COUNT reports created"
```
```

### Key Design Features

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

### Results

**Before Hard Barriers** (Phases 1-4 baseline):
- 40-60% context usage in orchestrator performing subagent work directly
- Inconsistent delegation (sometimes bypassed)
- No reusability of inline work

**After Hard Barriers** (Phases 2-4 implementation):
- Context reduction: orchestrator only coordinates
- 100% delegation success (bypass impossible)
- Modular architecture with focused agent responsibilities
- Predictable workflow execution

### When to Use

Apply hard barrier pattern when:
- Orchestrator has permissive tool access (Read, Edit, Write, Grep, Glob)
- Subagent work must be isolated and reusable
- Delegation enforcement is critical
- Error recovery needs explicit checkpoints

### Anti-Patterns

**Don't**:
- Merge bash + Task in single block (bypass possible)
- Use soft verification (warnings instead of exit 1)
- Skip checkpoint reporting
- Omit error logging

**Do**:
- Split into 3 sub-blocks (Setup → Execute → Verify)
- Use fail-fast verification (exit 1 on failure)
- Log errors with recovery instructions
- Add [CHECKPOINT] markers for debugging

---

## Example 7: Research Coordinator with Parallel Multi-Topic Research

**Status**: IMPLEMENTED (as of 2025-12-08)

**Command Integration Status**:
- `/create-plan`: ✓ Integrated (Phase 1, Phase 2 - automated topic detection)
- `/research`: ✓ Integrated (Phase 3)
- `/lean-plan`: ✗ Not Integrated (uses lean-research-specialist directly - correct for domain-specific research)
- `/repair`: Planned (Phase 10)
- `/debug`: Planned (Phase 11)
- `/revise`: Planned (Phase 12)

### Scenario

Coordinate parallel research across multiple topics with metadata aggregation for context reduction.

### Problem

Traditional research workflows consume significant context:
- Primary agent performs inline research (13+ tool calls)
- Research reports passed as full content (2,500 tokens per report)
- No parallelization of multi-topic research

### Solution: Research Coordinator Pattern

The research-coordinator agent orchestrates parallel research-specialist invocations, validates artifacts via hard barrier pattern, and returns metadata summaries (95% context reduction).

### Architecture

```
/lean-plan Primary Agent
    |
    +-- research-coordinator (Supervisor)
            +-- research-specialist 1 (Mathlib Theorems)
            +-- research-specialist 2 (Proof Automation)
            +-- research-specialist 3 (Project Structure)
```

### Implementation

```markdown
## Block 1d: Research Topics Classification

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

## Block 1d-calc: Report Path Pre-Calculation

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

## Block 1d-exec: Research Coordinator Invocation

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

## Block 1e: Research Validation (Hard Barrier)

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

# Parse coordinator output (simplified - actual implementation would use jq or awk)
REPORT_METADATA_JSON="[...]"  # Extracted from coordinator return signal

# Persist metadata for planning phase
append_workflow_state "REPORT_METADATA" "$REPORT_METADATA_JSON"
append_workflow_state "VERIFIED_REPORT_COUNT" "${#REPORT_PATHS[@]}"

echo "[CHECKPOINT] Research verified: ${#REPORT_PATHS[@]} reports created"
echo "             Metadata extracted for planning phase"
```
```

### Context Reduction Metrics

**Traditional Approach** (primary agent reads all reports):
```
3 reports x 2,500 tokens = 7,500 tokens consumed
```

**Coordinator Approach** (metadata-only):
```
3 reports x 110 tokens metadata = 330 tokens consumed
Context reduction: 95.6%
```

### Metadata Format

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

### Downstream Consumer Integration

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

### Benefits

1. **Parallel Execution**: 3 research-specialist agents run simultaneously (40-60% time savings)
2. **Context Reduction**: 95% reduction via metadata-only passing
3. **Hard Barrier Enforcement**: Mandatory delegation prevents bypass
4. **Modular Architecture**: research-coordinator reusable across commands
5. **Graceful Degradation**: Partial success mode if ≥50% reports created

### Integration Points

Commands using research-coordinator:
- `/lean-plan` - Lean theorem research phase
- `/create-plan` - Software feature research phase (future)
- `/repair` - Error pattern research phase (future)
- `/debug` - Issue investigation research phase (future)
- `/revise` - Context research before plan revision (future)

### Success Criteria

Research coordination is successful if:
- All research topics decomposed correctly (2-5 topics)
- All report paths pre-calculated before agent invocation
- All research-specialist agents invoked in parallel
- All reports exist at pre-calculated paths (hard barrier validation)
- Metadata extracted for all reports (110 tokens per report)
- Aggregated metadata returned to primary agent
- Context reduction 95%+ vs full report content

---

## Example 8: Lean Command Coordinator Optimization

**Status**: IMPLEMENTED (as of 2025-12-08)

**Command Integration Status**:
- `/lean-plan`: ✓ Integrated (research-coordinator for parallel multi-topic Lean research)
- `/lean-implement`: ✓ Integrated (implementer-coordinator for wave-based orchestration)

### Scenario

Optimize Lean-specific commands (/lean-plan, /lean-implement) to leverage hierarchical agent architecture for parallel research execution and context reduction.

### Problem

Lean commands operated with inefficient patterns:
- `/lean-plan`: Direct lean-research-specialist invocation (no coordinator delegation)
  - Missing 95% context reduction from metadata-only passing
  - Missing 40-60% time savings from parallel execution
- `/lean-implement`: Primary agent performing implementation work (bypassing coordinators)
  - Missing 96% context reduction from brief summary parsing
  - Missing wave-based parallel execution

### Solution: Dual Coordinator Integration

Integrate research-coordinator into /lean-plan for parallel multi-topic Lean research with metadata-only passing, and enforce hard barrier pattern in /lean-implement with implementer-coordinator delegation.

### Architecture

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

/lean-implement Command Flow:
┌─────────────────────────────────────────────────────────────┐
│ Block 1a: Pre-calculate Artifact Paths                      │
│ - SUMMARIES_DIR, DEBUG_DIR, OUTPUTS_DIR, CHECKPOINTS_DIR   │
└────────────────┬────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────┐
│ Block 1b: Route to Coordinator [HARD BARRIER]               │
│ - MANDATORY delegation (no conditionals)                    │
│ - implementer-coordinator invocation                        │
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

### Implementation: /lean-plan

**Block 1d-topics: Research Topics Classification**

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

**Block 1f: Partial Success Mode Validation**

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

### Implementation: /lean-implement

**Block 1b: Hard Barrier Enforcement**

```bash
# [HARD BARRIER] Coordinator delegation is MANDATORY (no conditionals, no bypass)
# The orchestrator MUST NOT perform implementation work directly

COORDINATOR_NAME="implementer-coordinator"

# Persist coordinator name for Block 1c validation
append_workflow_state "COORDINATOR_NAME" "$COORDINATOR_NAME"

**EXECUTE NOW**: USE the Task tool to invoke implementer-coordinator.

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation phases via implementer-coordinator"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    **Input Contract (Hard Barrier Pattern)**:
    - plan_path: ${PLAN_FILE}
    - topic_path: ${TOPIC_PATH}
    - summaries_dir: ${SUMMARIES_DIR}
    - artifact_paths:
      - summaries: ${SUMMARIES_DIR}
      - debug: ${DEBUG_DIR}
      - outputs: ${OUTPUTS_DIR}
      - checkpoints: ${CHECKPOINTS_DIR}

    Execute implementation according to behavioral guidelines.
  "
  model: "sonnet-4.5"
}

echo "[CHECKPOINT] Coordinator invoked: $COORDINATOR_NAME"
```

**Block 1c: Brief Summary Parsing**

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

### Key Benefits Realized

**Context Reduction**:
1. `/lean-plan` research phase: 95% reduction (7,500 → 330 tokens)
2. `/lean-implement` iteration phase: 96% reduction (2,000 → 80 tokens)

**Time Savings**:
1. Parallel multi-topic research: 40-60% time reduction
2. Wave-based phase execution: 40-60% time reduction for independent phases

**Iteration Capacity**:
- Before: 3-4 iterations possible (context exhaustion)
- After: 10+ iterations possible (reduced context per iteration)

### Validation Results

**Integration Tests**:
- `test_lean_plan_coordinator.sh`: 21 tests (100% pass rate)
- `test_lean_implement_coordinator.sh`: 27 tests (100% pass rate)
- Total: 48 tests, 0 failures

**Pre-commit Validation**:
- Sourcing standards: PASS
- Error logging integration: PASS
- Three-tier sourcing pattern: PASS

### Expected Behavior

**Successful /lean-plan Execution**:
- Research topics classified based on complexity (2-4 topics)
- research-coordinator invoked with TOPICS and REPORT_PATHS arrays
- Parallel research execution (3 specialists running concurrently)
- Metadata extraction (110 tokens per report)
- Partial success mode handles 1-2 failed reports gracefully (≥50% threshold)
- Plan-architect receives metadata-only context (330 tokens vs 7,500)

**Successful /lean-implement Execution**:
- Artifact paths pre-calculated in Block 1a (SUMMARIES_DIR, DEBUG_DIR, OUTPUTS_DIR, CHECKPOINTS_DIR)
- implementer-coordinator invoked with complete artifact paths
- Summary validated in Block 1c (delegation bypass detection)
- Brief summary parsed from return signal (80 tokens vs 2,000 full file)
- Iteration continuation via coordinator signals (REQUIRES_CONTINUATION, WORK_REMAINING)

---

## Related Documentation

- [Overview](hierarchical-agents-overview.md)
- [Coordination](hierarchical-agents-coordination.md)
- [Patterns](hierarchical-agents-patterns.md)
- [Troubleshooting](hierarchical-agents-troubleshooting.md)
