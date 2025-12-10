# Research Report: Three-Tier Agent Coordination Pattern

**Date**: 2025-12-10
**Status**: Complete
**Research Topic**: Three-tier agent coordination model in .claude/ system

## Executive Summary

The .claude/ system implements a three-tier hierarchical agent architecture with distinct responsibility boundaries: commands (orchestrators) invoke coordinator agents (supervisors) which invoke specialist agents (workers). This pattern achieves 95-96% context reduction through metadata-only passing between tiers, enables wave-based parallel execution with 40-60% time savings, and enforces strict delegation contracts via hard barrier patterns. The architecture is production-ready with implementation examples in /research, /create-plan, /lean-plan, and /lean-implement commands.

## Research Objectives

1. Examine how commands invoke agents via Task tool
2. Analyze coordinator agents (research-coordinator.md, implementer-coordinator.md)
3. Study specialist agent patterns (research-specialist.md, plan-architect.md)
4. Document delegation flow: command -> orchestrator -> coordinator -> specialist
5. Identify responsibility boundaries at each tier
6. Find communication protocols (completion signals, error signals)

## Findings

### 1. Command-to-Orchestrator Tier (Tier 1: Primary Commands)

**Role**: Commands act as orchestrators coordinating entire workflows through state machine transitions and agent delegation.

**Examples**: /research, /create-plan, /lean-plan, /implement, /lean-implement

**Key Responsibilities**:
- Argument capture and validation
- State machine initialization and transitions (via workflow-state-machine.sh)
- Topic directory creation and artifact path pre-calculation (hard barrier pattern)
- Agent invocation via Task tool with pre-calculated context
- Hard barrier validation after agent completion
- Console summary generation and terminal state management

**Delegation Pattern** (Command -> Coordinator):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-coordinator.

Task {
  subagent_type: "general-purpose"
  description: "Coordinate parallel research execution"
  prompt: |
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-coordinator.md

    **Input Contract (Hard Barrier Pattern)**:
    - research_request: "${WORKFLOW_DESCRIPTION}"
    - research_complexity: ${RESEARCH_COMPLEXITY}
    - report_dir: ${REPORT_DIR}
    - topic_path: ${TOPIC_PATH}
    - topics: ["${TOPICS[@]}"]
    - report_paths: ["${REPORT_PATHS[@]}"]

    Execute research coordination according to behavioral guidelines.
}
```

**Communication Protocol** (Command receives from Coordinator):
```yaml
RESEARCH_COORDINATOR_COMPLETE: SUCCESS
topics_planned: 3
invocation_plan_path: /path/to/.invocation-plan.txt
context_usage_percent: 8

INVOCATION_PLAN_READY: 3
invocations: [
  {"topic": "Topic 1", "report_path": "/path/1.md"},
  {"topic": "Topic 2", "report_path": "/path/2.md"},
  {"topic": "Topic 3", "report_path": "/path/3.md"}
]
```

**Hard Barrier Validation**:
```bash
# Commands validate coordinator outputs before proceeding
for REPORT_PATH in "${REPORT_PATHS[@]}"; do
  if [ ! -f "$REPORT_PATH" ]; then
    log_command_error "validation_error" \
      "Report missing after coordinator completion" \
      "$(jq -n --arg path "$REPORT_PATH" '{missing_report: $path}')"
    exit 1
  fi
done
```

**Evidence**: /research command (lines 1-400), /create-plan command (lines 1-400), research-coordinator.md invocation examples

---

### 2. Orchestrator-to-Coordinator Tier (Tier 2: Coordination Agents)

**Role**: Coordinators decompose complex workflows into parallel tasks, manage worker invocations, and aggregate results with metadata-only passing to orchestrators.

**Examples**: research-coordinator.md, implementer-coordinator.md, lean-coordinator.md

**Key Responsibilities**:
- Topic/phase decomposition (Mode 1: automated, Mode 2: pre-decomposed)
- Report/artifact path pre-calculation (before worker invocation)
- Invocation plan file creation (hard barrier enforcement)
- Parallel worker invocation (all tasks in single message)
- Metadata extraction from worker outputs (95% context reduction)
- Brief summary generation (80 tokens vs 2,000+ tokens full content)

**Delegation Pattern** (Coordinator -> Specialist):

**research-coordinator Example** (DOES NOT invoke specialists directly):
```markdown
### STEP 3: Generate Invocation Plan Metadata

**Design**: This coordinator does NOT invoke research-specialist directly.
Instead, it returns invocation metadata for the primary agent to execute
Task tool invocations.

**Returns to Orchestrator**:
INVOCATION_PLAN_READY: 3
invocations: [
  {"topic": "Mathlib theorems", "report_path": "/path/001-mathlib.md"},
  {"topic": "Proof automation", "report_path": "/path/002-proof-automation.md"},
  {"topic": "Project structure", "report_path": "/path/003-project-structure.md"}
]
```

**implementer-coordinator Example** (DOES invoke specialists directly):
```markdown
### STEP 4: Wave Execution Loop - Parallel Executor Invocation

**EXECUTE NOW**: USE the Task tool to invoke the implementation-executor.

Task {
  subagent_type: "general-purpose"
  description: "Execute Phase 2 implementation"
  prompt: |
    Read and follow behavioral guidelines from:
    /home/user/.config/.claude/agents/implementation-executor.md

    Input:
    - phase_file_path: /path/to/phase_2_backend.md
    - topic_path: /path/to/specs/027_auth
    - artifact_paths: {...}
    - wave_number: 2
    - phase_number: 2

    Execute all tasks, update plan, run tests, create git commit.
    Return PHASE_COMPLETE report with status and metadata.
}

Task {
  subagent_type: "general-purpose"
  description: "Execute Phase 3 implementation"
  prompt: "..."  # Same pattern for Phase 3
}
```

**Communication Protocol** (Coordinator receives from Specialists):

From research-specialist:
```
REPORT_CREATED: /absolute/path/to/report.md
```

From implementation-executor:
```yaml
PHASE_COMPLETE: SUCCESS
status: completed
tasks_completed: 15
tests_passing: true
commit_hash: abc123
context_exhausted: false
work_remaining: 0
```

**Context Reduction Pattern**:
```markdown
### STEP 5: Prepare Invocation Metadata

**Build Brief Summary** (80 tokens vs 2,000 tokens full file):
- coordinator_type: software
- summary_brief: "Completed Wave 1 (Phase 3,4) with 25 tasks. Context: 65%. Next: Continue Wave 2."
- phases_completed: [3, 4]
- phase_count: 2
- git_commits: [hash1, hash2]
- work_remaining: Phase_5 Phase_6
- context_exhausted: false
```

**Evidence**: research-coordinator.md (lines 330-390), implementer-coordinator.md (lines 250-330, 459-570)

---

### 3. Coordinator-to-Specialist Tier (Tier 3: Worker Agents)

**Role**: Specialists execute focused tasks (research, planning, implementation) and return completion signals with file paths or brief status.

**Examples**: research-specialist.md, plan-architect.md, implementation-executor.md, lean-implementer.md

**Key Responsibilities**:
- File creation at pre-calculated paths (hard barrier contract)
- Self-contained task execution (research, planning, code writing)
- Metadata-compliant output (YAML frontmatter with counts)
- Progress streaming (PROGRESS: markers for visibility)
- Error return protocol (TASK_ERROR: signals for orchestrator logging)

**Specialist Workflow Pattern** (research-specialist.md):
```markdown
### STEP 1: Receive and Verify Report Path
**MANDATORY INPUT VERIFICATION**: Absolute path provided by coordinator

### STEP 2: Create Report File FIRST
**EXECUTE NOW**: Use Write tool at EXACT path (before research)

### STEP 3: Conduct Research and Update Report
- Search codebase (Glob/Grep)
- Analyze implementations
- Web research (WebSearch/WebFetch)
- Update file incrementally (Edit tool)

### STEP 4: Pre-Return Section Structure Validation
**HARD BARRIER**: Validate all required sections present

### STEP 5: Verify and Return Confirmation
**RETURN ONLY**: REPORT_CREATED: /absolute/path/to/report.md
```

**Communication Protocol** (Specialist returns to Coordinator):

research-specialist:
```
REPORT_CREATED: /home/user/.claude/specs/028_lean/reports/001-mathlib-theorems.md
```

plan-architect:
```
PLAN_CREATED: /home/user/.claude/specs/027_auth/plans/027_implementation.md

Metadata:
- Phases: 6
- Complexity: High
- Estimated Hours: 16
```

**Metadata-Compliant Output** (research-specialist report file):
```yaml
---
report_type: lean_research
topic: "Mathlib theorems for group homomorphism"
findings_count: 5
recommendations_count: 4
---

# Report content...
```

**Error Return Protocol**:
```markdown
ERROR_CONTEXT: {
  "error_type": "file_error",
  "message": "Cannot access codebase directory",
  "details": {"path": "/invalid/path"}
}

TASK_ERROR: file_error - Cannot access codebase directory: /invalid/path
```

**Evidence**: research-specialist.md (lines 1-100, 260-340, 896-908), plan-architect.md (lines 1-60, 240-280)

---

### 4. Delegation Patterns and Workflows

**Pattern 1: Planning-Only Coordinator** (research-coordinator)
```
Command (/research, /create-plan)
    |
    +-- research-coordinator (planning only)
            |
            +-- Returns invocation metadata to command
                    |
                    Command invokes research-specialist directly (3-4x in parallel)
                            |
                            +-- Each specialist creates report at pre-calculated path
```

**Pattern 2: Supervisor-Based Coordinator** (implementer-coordinator)
```
Command (/implement, /lean-implement)
    |
    +-- implementer-coordinator (supervisor)
            |
            +-- Wave 1: Phase 1 (sequential)
            |       +-- implementation-executor
            |
            +-- Wave 2: Phase 2, Phase 3 (parallel)
            |       +-- implementation-executor
            |       +-- implementation-executor
            |
            +-- Wave 3: Phase 4 (sequential)
                    +-- implementation-executor
```

**Pattern 3: Hybrid Routing** (lean-implement)
```
Command (/lean-implement)
    |
    +-- Phase type detection
            |
            +-- Lean phases -> lean-coordinator
            |                       +-- lean-implementer
            |
            +-- Software phases -> implementer-coordinator
                                        +-- implementation-executor
```

**Invocation Modes**:

**Mode 1 - Automated Decomposition** (research-coordinator):
- Coordinator receives broad research request
- Decomposes into 2-5 focused topics
- Calculates report paths
- Returns invocation metadata

**Mode 2 - Manual Pre-Decomposition** (research-coordinator):
- Command pre-decomposes topics via topic-detection-agent
- Command pre-calculates report paths
- Coordinator receives topics + paths arrays
- Validates and returns invocation plan

**Evidence**: research-coordinator.md (lines 56-96), implementer-coordinator.md (lines 248-330), lean-implement.md (grep results lines 22, 559, 628)

---

### 5. Responsibility Boundaries

**Tier 1 (Commands) Responsibilities**:
- Workflow state machine management
- Argument capture and validation
- Topic directory creation (lazy via unified-location-detection.sh)
- Artifact path pre-calculation (hard barrier pattern enforcement)
- Agent invocation contracts (pre-calculated paths passed explicitly)
- Hard barrier validation (file existence after agent return)
- Console summary generation
- Error logging (errors.jsonl integration)
- Terminal state transitions (complete, abandoned)

**Tier 1 Does NOT**:
- Invoke specialist agents directly (delegates to coordinators)
- Create report/plan content (delegates to specialists)
- Manage parallel execution waves (delegates to coordinators)

**Tier 2 (Coordinators) Responsibilities**:
- Topic/phase decomposition (if Mode 1)
- Report/artifact path pre-calculation (if not provided)
- Invocation plan file creation (hard barrier proof)
- Parallel worker invocation (all in single message)
- Worker output aggregation (metadata extraction)
- Brief summary generation (context reduction)
- Wave synchronization (implementer-coordinator only)
- Dependency analysis (implementer-coordinator only)

**Tier 2 Does NOT**:
- Create research reports or plans (delegates to specialists)
- Manage workflow state (delegates to orchestrators)
- Validate hard barriers (delegates to orchestrators)

**Tier 3 (Specialists) Responsibilities**:
- File creation at pre-calculated paths (hard barrier contract)
- Content generation (research findings, implementation plans, code)
- Self-contained task execution (research, planning, implementation)
- Metadata-compliant output (YAML frontmatter)
- Progress streaming (PROGRESS: markers)
- Error return protocol (TASK_ERROR: signals)
- Self-validation (verify file exists before return)

**Tier 3 Does NOT**:
- Calculate output paths (receives from coordinator/orchestrator)
- Coordinate parallel workers (delegates to coordinators)
- Manage workflow state (single-task focus)

**Evidence**: research-coordinator.md (lines 28-38, 709-734), implementer-coordinator.md (lines 10-22, 732-765), research-specialist.md (lines 449-469)

---

### 6. Communication Protocols

**Completion Signals**:

**research-coordinator** (planning-only):
```
RESEARCH_COORDINATOR_COMPLETE: SUCCESS
topics_planned: 3
invocation_plan_path: /path/to/.invocation-plan.txt
context_usage_percent: 8

INVOCATION_PLAN_READY: 3
invocations: [...]
```

**research-specialist**:
```
REPORT_CREATED: /absolute/path/to/report.md
```

**plan-architect**:
```
PLAN_CREATED: /absolute/path/to/plan.md

Metadata:
- Phases: 6
- Complexity: High
- Estimated Hours: 16
```

OR (for revisions):
```
PLAN_REVISED: /absolute/path/to/plan.md

Metadata:
- Phases: 8 (increased from 6)
- Completed Phases: 3
- Estimated Hours: 22
```

**implementer-coordinator**:
```yaml
IMPLEMENTATION_COMPLETE: SUCCESS
coordinator_type: software
summary_path: /path/to/summaries/001_summary.md
summary_brief: "Completed Wave 1 (Phase 3,4) with 25 tasks. Context: 65%. Next: Continue."
phases_completed: [3, 4]
phase_count: 2
git_commits: [hash1, hash2]
plan_file: /path/to/plan.md
work_remaining: Phase_5 Phase_6
context_exhausted: false
requires_continuation: true
```

**Error Signals** (all tiers):
```
ERROR_CONTEXT: {
  "error_type": "validation_error",
  "message": "3 research reports missing after agent invocation",
  "details": {"missing_reports": ["/path/1.md", "/path/2.md", "/path/3.md"]}
}

TASK_ERROR: validation_error - 3 research reports missing (hard barrier failure)
```

**Error Types** (standardized across tiers):
- `state_error` - Workflow state persistence issues
- `validation_error` - Input validation or output verification failures
- `agent_error` - Subagent execution failures
- `parse_error` - Output parsing failures
- `file_error` - File system operation failures
- `timeout_error` - Operation timeout errors
- `execution_error` - General execution failures
- `dependency_error` - Missing or invalid dependencies

**Progress Streaming** (specialists only):
```
PROGRESS: Creating report file at path
PROGRESS: Starting research on topic
PROGRESS: Searching codebase for patterns
PROGRESS: Analyzing 15 files found
PROGRESS: Updating report with findings
PROGRESS: Research complete, report verified
```

**Evidence**: research-coordinator.md (lines 568-599, 663-683), research-specialist.md (lines 390-408, 896-908), implementer-coordinator.md (lines 610-665, 899-965), plan-architect.md (lines 253-285)

---

## Conclusions

### Architecture Maturity

The three-tier hierarchical agent architecture is **production-ready** with complete implementations in 4+ commands (/research, /create-plan, /lean-plan, /lean-implement). The pattern has evolved through multiple iterations with defensive error handling, hard barrier enforcement, and comprehensive validation.

### Context Efficiency

The architecture achieves **95-96% context reduction** through:
1. Metadata-only passing between tiers (80-110 tokens vs 2,000-2,500 tokens)
2. Brief summary pattern (coordinator returns summaries, not full content)
3. Invocation plan pattern (coordinator plans, orchestrator executes)

**Example**: 4 research reports (4 x 2,500 = 10,000 tokens) → coordinator extracts metadata (4 x 110 = 440 tokens) → 95.6% reduction

### Execution Performance

Wave-based parallel execution via implementer-coordinator achieves **40-60% time savings**:
- Dependency analysis enables parallel phase execution
- Independent phases run concurrently (Wave 2: Phase 2, 3 in parallel)
- Synchronization guarantees (Wave N+1 waits for Wave N completion)

### Hard Barrier Pattern Enforcement

All three tiers enforce hard barrier contracts:
1. **Tier 1** (Commands): Pre-calculates paths BEFORE coordinator invocation
2. **Tier 2** (Coordinators): Pre-calculates paths BEFORE specialist invocation OR returns invocation metadata
3. **Tier 3** (Specialists): Creates files at EXACT paths, validates before return

**Validation Flow**:
```
Command pre-calculates path → Pass to coordinator → Coordinator validates/passes to specialist
→ Specialist creates file → Specialist verifies file exists → Specialist returns path
→ Coordinator validates file exists → Coordinator returns metadata → Command validates file exists
```

### Error Handling Robustness

Comprehensive error handling at all tiers:
- **Tier 1**: Bash error traps (setup_bash_error_trap), error logging (log_command_error), hard barrier validation
- **Tier 2**: Error trap handlers (handle_coordinator_error), partial success modes (≥50% threshold)
- **Tier 3**: TASK_ERROR: signals, ERROR_CONTEXT JSON, self-validation checkpoints

**Error propagation**: Specialist error → Coordinator catches → Coordinator returns TASK_ERROR → Command logs to errors.jsonl

### Responsibility Clarity

Clear responsibility boundaries prevent duplication:
- **Commands**: State management, orchestration, validation
- **Coordinators**: Decomposition, planning, aggregation
- **Specialists**: Execution, content creation, file generation

**Anti-Pattern Prevention**: No tier performs responsibilities of another tier (enforced via behavioral guidelines)

---

## Recommendations

### 1. Standardize Coordinator Invocation Mode Selection

**Rationale**: research-coordinator supports two modes (automated decomposition, manual pre-decomposition) but selection logic is command-specific.

**Recommendation**: Create decision matrix in coordinator behavioral file:
```markdown
## Mode Selection Guidelines

**Use Mode 1 (Automated)** when:
- Complexity < 3
- Single broad research request
- No pre-existing topic structure

**Use Mode 2 (Pre-Decomposed)** when:
- Complexity >= 3
- Multiple distinct topics identified
- Topic-detection-agent available
```

**Benefit**: Reduces command-level logic duplication, improves coordinator reusability

---

### 2. Extract Coordinator Invocation Patterns to Reusable Templates

**Rationale**: /research, /create-plan, and /lean-plan duplicate similar research-coordinator invocation logic (100+ lines).

**Recommendation**: Create `.claude/commands/templates/coordinator-invocation-patterns.md`:
```markdown
## Research Coordinator Invocation Template

### Mode 1 (Automated Decomposition)
[Copy-paste template with ${VARIABLE} placeholders]

### Mode 2 (Pre-Decomposed Topics)
[Copy-paste template with ${VARIABLE} placeholders]
```

**Benefit**: Reduces maintenance burden, ensures consistency across commands

---

### 3. Add Coordinator Performance Metrics to Console Summaries

**Rationale**: Commands display final summaries but lack coordinator-specific metrics (context reduction %, parallelization savings).

**Recommendation**: Include coordinator metrics in Block 3 (console summary):
```
=== Research Complete ===
Reports Created: 3
Context Reduction: 95.6% (440 tokens vs 10,000)
Coordinator: research-coordinator (planning-only mode)
Time Savings: 40% (parallel execution)
```

**Benefit**: Visibility into architecture benefits, debugging performance issues

---

### 4. Document Coordinator Return Signal Contracts

**Rationale**: Each coordinator has unique return format (RESEARCH_COORDINATOR_COMPLETE vs IMPLEMENTATION_COMPLETE) but no centralized contract documentation.

**Recommendation**: Create `.claude/docs/reference/standards/coordinator-return-signals.md`:
```markdown
## Coordinator Return Signal Standards

### research-coordinator
**Signal**: RESEARCH_COORDINATOR_COMPLETE: SUCCESS
**Fields**: topics_planned, invocation_plan_path, context_usage_percent

### implementer-coordinator
**Signal**: IMPLEMENTATION_COMPLETE: SUCCESS
**Fields**: coordinator_type, summary_brief, phases_completed, ...
```

**Benefit**: Easier command integration, consistent signal parsing

---

### 5. Enforce Coordinator Type Field in All Coordinators

**Rationale**: implementer-coordinator includes `coordinator_type: software` field for filtering in hybrid workflows, but research-coordinator lacks this.

**Recommendation**: Add `coordinator_type` field to all coordinator return signals:
```yaml
# research-coordinator
coordinator_type: research

# implementer-coordinator
coordinator_type: software

# lean-coordinator
coordinator_type: lean
```

**Benefit**: Enables generic filtering logic in multi-coordinator workflows (e.g., /lean-implement routing)

---

### 6. Create Three-Tier Architecture Decision Tree

**Rationale**: No clear guidance on when to use direct specialist invocation vs coordinator-based delegation.

**Recommendation**: Add decision tree to hierarchical-agents-overview.md:
```
Does workflow require 3+ parallel specialists?
├─ YES → Use coordinator (research-coordinator, implementer-coordinator)
└─ NO → Direct specialist invocation (plan-architect, research-specialist)

Does workflow require wave-based execution?
├─ YES → Use implementer-coordinator
└─ NO → Use planning-only coordinator or direct invocation
```

**Benefit**: Reduces architecture decision complexity for new command authors

---

## References

**Commands Analyzed**:
- `/research` command - /home/benjamin/.config/.claude/commands/research.md (lines 1-400)
- `/create-plan` command - /home/benjamin/.config/.claude/commands/create-plan.md (lines 1-400)
- `/lean-plan` command - /home/benjamin/.config/.claude/commands/lean-plan.md (grep results)
- `/lean-implement` command - /home/benjamin/.config/.claude/commands/lean-implement.md (grep results)

**Coordinator Agents Analyzed**:
- research-coordinator.md - /home/benjamin/.config/.claude/agents/research-coordinator.md (758 lines, complete)
- implementer-coordinator.md - /home/benjamin/.config/.claude/agents/implementer-coordinator.md (975 lines, complete)

**Specialist Agents Analyzed**:
- research-specialist.md - /home/benjamin/.config/.claude/agents/research-specialist.md (908 lines, complete)
- plan-architect.md - /home/benjamin/.config/.claude/agents/plan-architect.md (1,341 lines, complete)

**Architecture Documentation**:
- hierarchical-agents-overview.md - /home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-overview.md (lines 1-177)
- hierarchical-agents-patterns.md - /home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-patterns.md (lines 1-200)
- hierarchical-agents-coordination.md - /home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-coordination.md (lines 1-200)
