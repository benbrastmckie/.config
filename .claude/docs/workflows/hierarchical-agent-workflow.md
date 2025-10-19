# Hierarchical Agent Workflow System

## Purpose

This guide explains how Claude Code commands orchestrate hierarchical agent workflows, where a primary agent invokes specialized subagents that create artifacts organized in topic-based directories, while preserving context through metadata-only passing and aggressive pruning.

**Quick Overview**: For a concise summary of the hierarchical agent workflow system, see [README: Hierarchical Agent Workflow System](../README.md#hierarchical-agent-workflow-system).

## Navigation

- [← Workflows Index](README.md)
- [Documentation Index](../README.md)
- [Hierarchical Agent Architecture](../concepts/hierarchical_agents.md) - Technical architecture and utilities
- [Using Agents](../guides/using-agents.md) - Agent invocation patterns
- [Development Workflow](../concepts/development-workflow.md) - Spec updater and artifact lifecycle
- [Orchestration Guide](orchestration-guide.md) - Multi-agent coordination tutorial

## Overview

The hierarchical agent system implements a **supervisor-worker pattern** where:

1. **Primary Agent** (supervisor): Coordinates workflow execution, manages state, preserves context
2. **Subagents** (workers): Perform specialized tasks, create artifacts, return metadata summaries
3. **Artifacts**: Organized in numbered topic directories with type-specific subdirectories
4. **Context Preservation**: Metadata-only passing achieves 92-97% context reduction

**Key Principle**: Subagents pass back **summary + reference** (not full content) to preserve context.

## Command-Agent Workflow Chains

### /report Command

**Purpose**: Research topics and create comprehensive reports

**Agent Workflow**:
```
Primary Agent
    ↓
    ├─→ research-specialist (Agent 1) → Report 1 + summary
    ├─→ research-specialist (Agent 2) → Report 2 + summary
    ├─→ research-specialist (Agent 3) → Report 3 + summary
    └─→ research-specialist (Agent 4) → Report 4 + summary
    ↓
Primary Agent receives: 4 summaries (250 tokens each) + file paths
Primary Agent reads reports: Only as needed for synthesis
```

**Parallel Execution**: All research-specialist agents run concurrently (2-4 agents typical)

**Artifact Creation**:
- **Location**: `specs/{NNN_topic}/reports/`
- **Format**: `NNN_topic_description.md`
- **Gitignore**: YES (local research artifacts)

**Summary Format** (returned to primary agent):
```yaml
report_path: "specs/027_auth/reports/027_auth_security_analysis.md"
summary: "[50-word summary of findings]"
key_findings:
  - "Finding 1"
  - "Finding 2"
  - "Finding 3"
recommendations:
  - "Recommendation 1"
  - "Recommendation 2"
```

**Context Reduction**: 5000 tokens (full report) → 250 tokens (summary) = **95% reduction**

---

### /plan Command

**Purpose**: Create structured implementation plans with automatic complexity-based expansion

**Agent Workflow**:
```
Primary Agent
    ↓
1. plan-architect Agent
    ↓ Creates Level 0 plan
    ↓
2. complexity-evaluator Agent
    ↓ Analyzes plan complexity
    ↓ Determines expansion threshold (8.0 default)
    ↓
3. expander Agent (if phase complexity >8.0)
    ↓ Expands high-complexity phases to separate files
    ↓ Creates Level 1 plan structure
    ↓
Primary Agent receives: Plan path + metadata (phases, complexity, expansion status)
```

**Phase Expansion Logic**:
```yaml
complexity_thresholds:
  expansion_threshold: 8.0
  task_count_threshold: 10
  file_reference_threshold: 10

complexity_calculation:
  base_score: 1.0
  per_task: +0.3
  per_file_reference: +0.1
  per_phase_dependency: +0.5

expansion_decision:
  if complexity_score > 8.0:
    action: expand_to_level_1
    create: "specs/{NNN_topic}/plans/phase_{N}_name.md"
  elif task_count > 10:
    action: expand_to_level_1
  else:
    action: keep_inline
```

**Artifact Creation**:
- **Level 0** (single file): `specs/{NNN_topic}/plans/NNN_feature.md`
- **Level 1** (expanded): `specs/{NNN_topic}/plans/` with `phase_{N}_*.md` files
- **Level 2** (stages): `specs/{NNN_topic}/plans/phase_{N}/stage_{M}_*.md`
- **Gitignore**: YES (working plan artifacts)

**Metadata Returned** (to primary agent):
```yaml
plan_path: "specs/027_auth/plans/027_auth_implementation/027_auth_implementation.md"
summary: "[50-word plan overview]"
complexity: 12.5
phases: 6
expanded_phases: [2, 4, 5]
time_estimate: "12-16 hours"
phase_dependencies:
  - phase: 3
    depends_on: [1, 2]
  - phase: 5
    depends_on: [3, 4]
```

**Context Reduction**: 8000 tokens (full plan) → 350 tokens (metadata) = **96% reduction**

---

### /implement Command

**Purpose**: Execute implementation plans phase-by-phase with testing, debugging, and spec updates

**Agent Workflow**:
```
Primary Agent
    ↓
1. FOR EACH PHASE in plan:
    ↓
    ├─→ implementation-researcher (if complexity ≥8)
    │   ↓ Explores codebase for phase context
    │   ↓ Returns: patterns found, utility functions, integration points
    │   ↓ Summary: 200 tokens
    │
    ├─→ code-writer Agent
    │   ↓ Implements phase tasks
    │   ↓ Writes/modifies code files
    │   ↓ Returns: files modified, implementation status
    │
    ├─→ test-specialist Agent
    │   ↓ Runs tests for phase
    │   ↓ Returns: test results (pass/fail)
    │
    └─→ IF tests fail repeatedly (2+ times):
        ├─→ debug-specialist Agent (max 3 iterations)
        │   ↓ Analyzes failures
        │   ↓ Creates debug report: specs/{NNN}/debug/
        │   ↓ Returns: root cause + fix proposals
        │
        └─→ code-writer Agent (apply fixes)
            ↓ Applies proposed fixes
            ↓ Re-runs tests
    ↓
2. After phase completion OR context low (<20% free):
    ↓
    └─→ spec-updater Agent
        ↓ Updates plan hierarchy checkboxes
        ↓ Updates cross-references
        ↓ Creates partial summary if context low
        ↓ Returns: update status
    ↓
3. After ALL phases complete:
    ↓
    └─→ spec-updater Agent (final)
        ↓ Creates implementation summary
        ↓ Updates all cross-references
        ↓ Marks plan as complete
        ↓ Returns: summary path
```

**Parallel Execution**: Phases execute in waves based on dependencies (Kahn's algorithm)

**Testing Strategy**:
```yaml
test_after_each_phase: true
test_failure_handling:
  max_consecutive_failures: 2
  action_on_failure: invoke_debug_specialist
  debug_iteration_limit: 3
  escalate_after: 3_failed_debug_attempts
```

**Debug Loop**:
```yaml
debug_loop:
  iteration: 1|2|3
  max_iterations: 3

  for_each_iteration:
    1. debug-specialist investigates
       ↓ Creates: specs/{NNN}/debug/NNN_issue_description.md
       ↓ Returns: root_cause + fix_proposals (100 tokens)

    2. code-writer applies fixes
       ↓ Modifies files per proposals
       ↓ Returns: fix_status

    3. test-specialist re-runs tests
       ↓ Returns: test_results

    4. IF tests_passing:
         break  # Exit loop
       ELIF iteration < 3:
         continue  # Next iteration
       ELSE:
         escalate_to_user  # Manual intervention
```

**Spec Updater Triggers**:
```yaml
invoke_spec_updater:
  - after_phase_complete: true
  - context_window_low: <20% free
  - all_phases_complete: true

spec_updater_actions:
  1. Update plan hierarchy checkboxes (Level 2 → Level 1 → Level 0)
  2. Update cross-references between artifacts
  3. Create/update implementation summary
  4. Verify gitignore compliance
  5. Return: summary_path + update_status (150 tokens)
```

**Artifact Creation**:
- **Debug Reports**: `specs/{NNN}/debug/NNN_issue.md` (COMMITTED - not gitignored!)
- **Implementation Summary**: `specs/{NNN}/summaries/NNN_implementation.md` (gitignored)
- **Test Outputs**: `specs/{NNN}/outputs/` (gitignored, auto-cleaned)

**Context Preservation** (during implementation):
```yaml
primary_agent_context:
  plan_path: "[path only, not content]"
  current_phase: N
  completed_phases: [1, 2, 3, ...]
  files_modified: ["file1.lua", "file2.lua"]
  phase_summaries:
    - phase: 1
      summary: "[100 words max]"
      files: ["file1.lua"]
    - phase: 2
      summary: "[100 words max]"
      files: ["file2.lua"]

context_pruning:
  after_each_phase:
    - clear_implementation_details: true
    - keep_only: phase_summary + files_modified

  when_context_low:
    - invoke_spec_updater: create_partial_summary
    - prune_completed_phases: aggressive
    - keep_only: current_phase + plan_path
```

**Metadata Returned** (after all phases):
```yaml
implementation_complete: true
phases_completed: "6/6"
tests_passing: true
files_modified: ["auth.lua", "session.lua", "test_auth.lua"]
debug_reports: ["specs/027_auth/debug/027_jwt_decode_issue.md"]
summary_path: "specs/027_auth/summaries/027_implementation.md"
summary: "[200-word implementation summary]"
```

**Context Reduction**: Ongoing pruning maintains <30% context usage throughout implementation

---

### /document Command

**Purpose**: Update documentation to reflect code changes

**Agent Workflow**:
```
Primary Agent
    ↓
doc-writer Agent
    ↓ Identifies affected documentation (READMEs, guides)
    ↓ Updates documentation files
    ↓ Ensures cross-reference consistency
    ↓ Returns: updated file paths + summary
    ↓
Primary Agent receives: List of updated docs + 100-word summary
```

**Documentation Updates**:
```yaml
doc_writer_actions:
  1. Identify affected documentation:
     - READMEs in modified directories
     - User guides referencing changed features
     - API documentation for modified functions
     - Spec files needing cross-reference updates

  2. Update each document:
     - Reflect new/changed functionality
     - Update code examples
     - Fix broken cross-references
     - Maintain documentation standards

  3. Verify consistency:
     - Cross-references resolve correctly
     - Examples are accurate
     - Modification dates updated
```

**Metadata Returned**:
```yaml
documentation_updated: true
files_modified:
  - "nvim/lua/auth/README.md"
  - "nvim/docs/USER_GUIDE.md"
  - "specs/027_auth/README.md"
summary: "[100-word summary of documentation updates]"
cross_references_updated: 5
```

**Context Reduction**: 3000 tokens (all updated docs) → 150 tokens (summary) = **95% reduction**

---

### /orchestrate Command

**Purpose**: Coordinate complete end-to-end workflows through all phases

**Agent Workflow** (7-phase pipeline):
```
Primary Agent (Orchestrator)
    ↓
Phase 1: Research (Parallel)
    ├─→ research-specialist (Agent 1)
    ├─→ research-specialist (Agent 2)
    ├─→ research-specialist (Agent 3)
    └─→ research-specialist (Agent 4)
    ↓
    Receives: 4 summaries (250 tokens each)
    Synthesizes: 200-word unified summary
    ↓
Phase 2: Planning (Sequential)
    └─→ Invokes: /plan [feature] [report-paths]
    ↓
    Receives: plan_path + metadata (350 tokens)
    Stores: ONLY plan_path, NOT plan content
    ↓
Phase 3: Complexity Evaluation (Conditional)
    └─→ complexity-evaluator Agent (if needed)
    ↓
    Receives: complexity_score + expansion_recommendation
    Decides: proceed | expand_plan | replan
    ↓
Phase 4: Implementation (Adaptive)
    └─→ Invokes: /implement [plan-path]
    ↓
    Receives: implementation_summary + files_modified + tests_status
    Stores: Summary only (200 tokens)
    ↓
Phase 5: Testing & Debugging (Conditional Loop)
    IF tests_failing:
        └─→ Invokes: /implement debugging loop
            └─→ debug-specialist → code-writer → test-specialist
        ↓
        Receives: debug_summary + fix_status
        Repeats: max 3 iterations
    ↓
Phase 6: Documentation (Sequential)
    └─→ Invokes: /document [change-description]
    ↓
    Receives: updated_docs + summary (150 tokens)
    ↓
Phase 7: Workflow Summary (Sequential)
    └─→ spec-updater Agent
    ↓
    Creates: specs/{NNN}/summaries/NNN_workflow.md
    Updates: All cross-references
    Returns: summary_path + final_summary (200 tokens)
```

**Master Plan as Context Anchor**:
```yaml
orchestrator_state:
  workflow_description: "[User's original request]"
  current_phase: "research|planning|implementation|debugging|documentation"

  master_plan:
    todos:
      - [ ] Research phase
      - [ ] Planning phase
      - [ ] Implementation phase
      - [ ] Debugging (if needed)
      - [ ] Documentation phase

  completed_checkpoints:
    research_complete:
      summary: "[200 words]"
      reports: ["path1", "path2"]
    plan_ready:
      plan_path: "specs/NNN/plans/NNN_feature.md"
      metadata: { phases: 6, complexity: 12.5 }
    implementation_complete:
      summary: "[200 words]"
      files_modified: [...]

  context_preservation:
    total_context_usage: <30%
    active_data: "current phase + master plan"
    archived_data: "summaries of completed phases"
    full_artifacts: "read only when needed for next phase"
```

**Context Reading Strategy**:
```yaml
read_full_artifacts_when:
  - planning_phase: read research summaries (not full reports)
  - implementation_phase: read plan path (not full plan content, unless needed for specific phase)
  - debugging_phase: read debug reports only for current issue
  - documentation_phase: read implementation summary, not all implementation details

do_not_read_unless_needed:
  - full_research_reports: use summaries only
  - full_plan_content: use metadata + plan path
  - completed_phase_details: use phase summaries
  - debug_report_archives: only read current iteration
```

**Aggressive Context Pruning**:
```yaml
context_pruning_policy:
  after_each_phase:
    - clear_subagent_outputs: true
    - keep_only: phase_summary (200 tokens)
    - prune_intermediate_data: aggressive

  when_context_usage >25%:
    - compress_summaries: 200 words → 100 words
    - offload_to_files: checkpoint data
    - keep_only: master_plan + current_phase

  target_context_usage: <30% throughout workflow
```

**Performance Metrics**:
```yaml
parallel_effectiveness:
  research_phase: 40-60% time savings (vs sequential)
  implementation_phase: 40-60% time savings (wave-based execution)

context_reduction:
  research_phase: 95% (full reports → summaries)
  planning_phase: 96% (full plan → metadata)
  implementation_phase: 97% (phase details → summaries)
  overall: 92-97% context reduction maintained
```

**Artifact Creation**:
- **Research Reports**: `specs/{NNN}/reports/` (gitignored)
- **Implementation Plan**: `specs/{NNN}/plans/` (gitignored)
- **Debug Reports**: `specs/{NNN}/debug/` (COMMITTED)
- **Workflow Summary**: `specs/{NNN}/summaries/NNN_workflow.md` (gitignored)

**Final Output** (to user):
```yaml
workflow_complete: true
duration: "45 minutes"
artifacts:
  research_reports: 3
  implementation_plan: "specs/027_auth/plans/027_implementation.md"
  debug_reports: 1
  documentation_updates: 4
  workflow_summary: "specs/027_auth/summaries/027_workflow.md"

performance:
  time_saved: "60% (vs manual sequential)"
  context_usage: "28% peak"
  parallel_phases: "research + implementation waves"
  error_recovery: "1 debug loop, resolved"

summary: "[200-word workflow summary]"
```

---

## Artifact Organization

### Topic-Based Directory Structure

**Core Pattern**: `specs/{NNN_topic}/`

All artifacts for a single feature/topic are co-located in one numbered directory:

```
specs/
├── 027_authentication/
│   ├── reports/                Research reports (gitignored)
│   │   ├── 027_research/              # Multiple reports from one task
│   │   │   ├── 027_auth_security.md
│   │   │   ├── 027_auth_frameworks.md
│   │   │   └── 027_auth_patterns.md
│   │   └── 028_single_analysis.md     # Single report (no subdirectory)
│   ├── plans/                  Implementation plans (gitignored)
│   │   ├── 027_auth_implementation/   # Structured plan subdirectory
│   │   │   ├── 027_auth_implementation.md  # Level 0 (main plan)
│   │   │   ├── phase_2_backend.md          # Level 1 (expanded phase)
│   │   │   ├── phase_4_integration.md      # Level 1 (expanded phase)
│   │   │   └── phase_2/                    # Level 2 (stages)
│   │   │       ├── stage_1_database.md
│   │   │       └── stage_2_api.md
│   │   └── 028_simple_fix.md          # Simple plan (no subdirectory)
│   ├── summaries/              Implementation summaries (gitignored)
│   │   ├── 027_implementation.md
│   │   └── 027_workflow.md
│   ├── debug/                  Debug reports (COMMITTED!)
│   │   ├── 027_jwt_decode.md
│   │   └── 027_session_leak.md
│   ├── scripts/                Investigation scripts (gitignored, temp)
│   │   └── test_auth_flow.sh
│   ├── outputs/                Test outputs (gitignored, temp)
│   │   └── auth_test_results.txt
│   └── README.md               Topic overview
└── 028_feature_x/
    └── ...
```

### Artifact Type Descriptions

| Type | Purpose | Gitignore | Lifecycle | Created By |
|------|---------|-----------|-----------|------------|
| **reports/** | Research findings | YES | Preserved | /report, /orchestrate |
| **plans/** | Implementation plans | YES | Preserved | /plan, /expand |
| **summaries/** | Workflow summaries | YES | Preserved | /implement, /orchestrate |
| **debug/** | Bug investigations | **NO** | Permanent | /debug, /implement |
| **scripts/** | Investigation scripts | YES | Temporary | /debug |
| **outputs/** | Test outputs | YES | Temporary | /implement, /test |

**Critical Distinction**: Debug reports are COMMITTED (not gitignored) to preserve project issue history. All other artifacts are gitignored as local working data.

### Plan Hierarchy (Level 0 → Level 1 → Level 2)

**Level 0** (Single File):
```
specs/027_auth/plans/027_simple_feature.md

Contains:
- All phases inline
- Basic task lists
- Simple dependencies
- No subdirectory needed (simple, non-structured plan)
```

**Level 1** (Phase Expansion - Structured Plan):
```
specs/027_auth/plans/027_auth_implementation/     # Structured plan subdirectory
├── 027_auth_implementation.md                    # Main plan (references phases)
├── phase_1_research.md                           # Expanded phase
├── phase_2_backend.md                            # Expanded phase (high complexity)
├── phase_3_frontend.md
├── phase_4_integration.md                        # Expanded phase (high complexity)
└── phase_5_documentation.md

Main plan contains:
- Phase references: @see phase_2_backend.md
- Checkboxes that auto-update from child phases
```

**Level 2** (Stage Expansion - Structured Plan):
```
specs/027_auth/plans/027_auth_implementation/     # Structured plan subdirectory
├── 027_auth_implementation.md                    # Main plan
├── phase_2_backend.md                            # Phase file (references stages)
├── phase_2/                                      # Stage subdirectory
│   ├── stage_1_database.md
│   ├── stage_2_api.md
│   └── stage_3_validation.md
└── phase_4_integration.md

Phase file contains:
- Stage references: @see phase_2/stage_1_database.md
- Auto-updating checkboxes
```

**Checkbox Propagation**:
```yaml
hierarchy_update_flow:
  Stage (Level 2):
    Task completed → Update stage checkbox
    ↓
  Phase (Level 1):
    All stage tasks done → Update phase checkbox
    ↓
  Main Plan (Level 0):
    All phase tasks done → Update main checkbox

automation:
  utility: ".claude/lib/checkbox-utils.sh"
  functions:
    - update_checkbox()
    - propagate_checkbox_update()
    - verify_checkbox_consistency()
```

---

## Context Preservation Patterns

### Metadata-Only Passing

**Principle**: Pass **summary + reference**, never full content

**Implementation**:
```yaml
metadata_extraction:
  utility: ".claude/lib/metadata-extraction.sh"

  extract_report_metadata(report_path):
    output:
      title: "Report Title"
      summary: "[50-word summary]"
      key_findings: ["Finding 1", "Finding 2", "Finding 3"]
      recommendations: ["Rec 1", "Rec 2"]
      file_path: "[absolute path]"

    context_reduction: 5000 tokens → 250 tokens (95%)

  extract_plan_metadata(plan_path):
    output:
      title: "Plan Title"
      summary: "[50-word overview]"
      complexity: 12.5
      phases: 6
      expanded_phases: [2, 4]
      time_estimate: "12-16 hours"
      dependencies: [...]
      file_path: "[absolute path]"

    context_reduction: 8000 tokens → 350 tokens (96%)
```

**Usage Example**:
```bash
# /orchestrate research phase
research_specialist creates: specs/027_auth/reports/027_security.md

# Subagent returns (NOT full 5000-token report):
{
  "report_path": "specs/027_auth/reports/027_security.md",
  "summary": "Security analysis recommends bcrypt for passwords, JWT for sessions, and 2FA for sensitive operations. Industry standards favor token-based auth over sessions due to scalability.",
  "key_findings": [
    "Bcrypt provides best password hashing (2025 standard)",
    "JWT tokens enable stateless authentication",
    "Rate limiting essential for auth endpoints"
  ],
  "recommendations": [
    "Implement bcrypt with cost factor 12",
    "Use short-lived JWTs (15min) + refresh tokens"
  ]
}

# Primary agent stores: 250 tokens, not 5000
# Reads full report: ONLY when needed for planning phase
```

### Forward Message Pattern

**Principle**: Pass subagent responses directly without re-summarization

**Anti-Pattern** (adds paraphrasing errors):
```yaml
# BAD - Supervisor re-summarizes subagent output
subagent_output: "[Detailed findings about authentication patterns]"
supervisor_summary: "The agent found that authentication uses JWT tokens"
# Information loss! Original nuance removed.
```

**Correct Pattern** (forward directly):
```yaml
# GOOD - Supervisor forwards exact subagent output
subagent_output:
  report_path: "specs/027_auth/reports/027_patterns.md"
  summary: "Codebase uses session-based auth in user.lua; no JWT implementation found. Recommend adding JWT module for token-based auth following existing session patterns."

supervisor_action: forward_to_next_phase
# No paraphrasing, no information loss
```

**Implementation**:
```bash
# .claude/lib/metadata-extraction.sh

forward_message() {
  local subagent_output="$1"

  # Extract artifact paths and metadata
  local artifact_paths=$(echo "$subagent_output" | grep -o 'specs/[^"]*')
  local summary=$(echo "$subagent_output" | jq -r '.summary')

  # Forward to next phase with minimal wrapper
  cat <<EOF
Subagent completed. Artifact created:
Path: $artifact_paths
Summary: $summary

Use this information for the next phase.
EOF
}
```

### Five-Layer Context Architecture

**Layer 1: Full Artifact Content**
- **Location**: Filesystem (`specs/` directories)
- **Usage**: Read only when absolutely necessary
- **Example**: Full implementation plan read when starting specific phase

**Layer 2: Metadata Summaries**
- **Location**: Subagent responses (250-350 tokens)
- **Usage**: Default context passed between agents
- **Example**: Plan metadata (phases, complexity, dependencies)

**Layer 3: Checkpoint State**
- **Location**: Orchestrator memory (100-200 tokens per phase)
- **Usage**: Workflow state tracking
- **Example**: Completed phases, test status, files modified

**Layer 4: Master Plan / Todo List**
- **Location**: Orchestrator active memory (500-800 tokens)
- **Usage**: Primary context anchor
- **Example**: Overall workflow structure and current phase

**Layer 5: Minimal Workflow State**
- **Location**: Orchestrator core state (200-300 tokens)
- **Usage**: Essential workflow control
- **Example**: Current phase, workflow type, escalation status

**Context Flow**:
```
Layer 1 (Full Artifacts) →
  Metadata extraction → Layer 2 (Summaries) →
    Checkpoint creation → Layer 3 (State) →
      Todo update → Layer 4 (Master Plan) →
        Core tracking → Layer 5 (Minimal State)

Reading flow (reverse):
  Layer 5 guides workflow
    ↓
  Layer 4 tracks todos
    ↓
  Layer 3 manages checkpoints
    ↓
  Layer 2 provides summaries
    ↓
  Layer 1 read only when Layer 2 insufficient
```

**Target Context Usage**: <30% throughout workflow

---

## Parallel Execution with Dependencies

### Phase Dependencies Syntax

**Format**: `depends_on: [phase_ids]`

```yaml
# In implementation plan:

Phase 1: Database Setup
  depends_on: []

Phase 2: Backend API
  depends_on: [1]

Phase 3: Frontend Components
  depends_on: [1]

Phase 4: Integration
  depends_on: [2, 3]

Phase 5: Testing
  depends_on: [4]
```

**Dependency Graph**:
```
Phase 1 (Database)
  ├─→ Phase 2 (Backend)
  │     └─→ Phase 4 (Integration)
  │           └─→ Phase 5 (Testing)
  └─→ Phase 3 (Frontend)
        └─→ Phase 4 (Integration)
            └─→ Phase 5 (Testing)
```

### Wave-Based Execution

**Algorithm**: Kahn's algorithm for topological sorting

**Wave Calculation**:
```yaml
Wave 1: Phases with no dependencies
  - Phase 1

Wave 2: Phases whose dependencies are in Wave 1
  - Phase 2 (depends on [1])
  - Phase 3 (depends on [1])

Wave 3: Phases whose dependencies are in Waves 1-2
  - Phase 4 (depends on [2, 3])

Wave 4: Phases whose dependencies are in Waves 1-3
  - Phase 5 (depends on [4])
```

**Parallel Execution**:
```yaml
execute_waves:
  Wave 1:
    - Execute Phase 1 (sequential, only 1 phase)

  Wave 2:
    - Execute Phase 2 | Phase 3 (parallel)
    - Time savings: 50% (both run simultaneously)

  Wave 3:
    - Execute Phase 4 (sequential, only 1 phase)

  Wave 4:
    - Execute Phase 5 (sequential, only 1 phase)
```

**Performance Gains**:
```yaml
sequential_execution_time:
  Phase 1: 30 min
  Phase 2: 45 min
  Phase 3: 40 min
  Phase 4: 35 min
  Phase 5: 20 min
  Total: 170 min

parallel_execution_time:
  Wave 1: 30 min (Phase 1)
  Wave 2: 45 min (max of Phase 2, 3)
  Wave 3: 35 min (Phase 4)
  Wave 4: 20 min (Phase 5)
  Total: 130 min

time_saved: 40 min (23.5% reduction)
```

**Utility**: `.claude/lib/dependency-analysis.sh`

```bash
calculate_waves() {
  local plan_file="$1"

  # Parse dependencies from plan
  # Build dependency graph
  # Apply Kahn's algorithm
  # Output: Wave 1: [phases], Wave 2: [phases], ...
}
```

---

## Spec Updater Agent

### Purpose

Manages artifacts in topic-based directory structure and maintains cross-references between artifacts throughout the workflow lifecycle.

### Invocation Points

**Automatic Triggers**:
```yaml
invoke_spec_updater_when:
  - phase_complete: true
  - context_window_low: <20% free
  - all_phases_complete: true
  - plan_expansion_complete: true
  - workflow_complete: true
```

**Commands That Use Spec Updater**:
- `/plan`: Creates plans in topic directories
- `/expand`: Expands phases while preserving structure
- `/implement`: Updates checkboxes, creates summaries
- `/orchestrate`: Manages all artifacts throughout workflow

### Spec Updater Actions

**1. Artifact Creation**:
```yaml
create_artifact:
  input:
    topic: "027_authentication"
    type: "reports|plans|summaries|debug|scripts|outputs"
    name: "security_analysis"
    content: "[artifact content]"

  actions:
    - ensure_topic_directory_exists: "specs/027_authentication/"
    - ensure_type_subdirectory_exists: "specs/027_authentication/reports/"
    - create_artifact_file: "specs/027_authentication/reports/027_security_analysis.md"
    - update_gitignore: if type != "debug"

  output:
    artifact_path: "specs/027_authentication/reports/027_security_analysis.md"
```

**2. Cross-Reference Updates**:
```yaml
update_cross_references:
  actions:
    - find_all_references_to_artifact
    - update_relative_links
    - verify_references_resolve
    - update_modification_dates

  example:
    plan_references_reports:
      - "See research findings: [Security Analysis](../reports/027_security_analysis.md)"

    summary_references_plan:
      - "Implementation followed: [027 Auth Plan](../plans/027_implementation.md)"
```

**3. Checkbox Hierarchy Updates**:
```yaml
update_hierarchy_checkboxes:
  levels:
    Level_2_Stage:
      - Mark task complete in stage file
      - Propagate to Level 1 phase

    Level_1_Phase:
      - Calculate completion % from stages
      - Update phase checkbox if all stages done
      - Propagate to Level 0 main plan

    Level_0_Main:
      - Calculate completion % from phases
      - Update main plan checkbox if all phases done

  utility: ".claude/lib/checkbox-utils.sh"
```

**4. Implementation Summary Creation**:
```yaml
create_implementation_summary:
  trigger: all_phases_complete OR context_window_low

  content:
    - Implementation overview
    - Files modified/created
    - Testing results
    - Debug issues resolved
    - Cross-references to plan and reports

  location: "specs/{NNN}/summaries/NNN_implementation.md"
  gitignore: YES
```

**5. Gitignore Compliance**:
```yaml
verify_gitignore:
  committed_types:
    - "debug/" # Bug reports committed for history

  gitignored_types:
    - "reports/" # Research artifacts
    - "plans/" # Working plans
    - "summaries/" # Implementation summaries
    - "scripts/" # Investigation scripts
    - "outputs/" # Test outputs

  action:
    - verify_gitignore_rules_exist
    - warn_if_committed_artifacts_in_gitignored_types
```

### Spec Updater Checklist

Included in all plan templates:

```markdown
## Spec Updater Checklist

- [ ] Ensure plan is in topic-based directory structure (`specs/{NNN_topic}/plans/`)
- [ ] Create standard subdirectories if needed (reports/, summaries/, debug/)
- [ ] Update cross-references if artifacts moved
- [ ] Create implementation summary when complete
- [ ] Verify gitignore compliance (debug/ committed, others ignored)
- [ ] Update plan hierarchy checkboxes (Level 2 → Level 1 → Level 0)
```

---

## Best Practices

### For Command Developers

**1. Always Pass Metadata, Not Full Content**:
```yaml
# GOOD
subagent_output = invoke_subagent(task)
metadata = extract_metadata(subagent_output)
return metadata  # 250 tokens

# BAD
subagent_output = invoke_subagent(task)
return subagent_output  # 5000 tokens
```

**2. Use Forward Message Pattern**:
```yaml
# GOOD
subagent_summary = subagent.complete()
next_phase_prompt = f"Use these findings: {subagent_summary}"

# BAD
subagent_summary = subagent.complete()
my_summary = paraphrase(subagent_summary)  # Information loss!
next_phase_prompt = f"The agent found: {my_summary}"
```

**3. Prune Aggressively After Each Phase**:
```yaml
after_phase_complete:
  - clear_subagent_full_outputs: true
  - keep_only: metadata_summary
  - target_context: <30% usage
```

**4. Use Topic-Based Organization**:
```yaml
# GOOD
create_artifact(
  topic="027_auth",
  type="reports",
  name="security_analysis"
)
# Result: specs/027_auth/reports/027_security_analysis.md

# BAD
create_artifact(
  path="specs/reports/027_security_analysis.md"
)
# Result: Breaks co-location, harder to find related artifacts
```

### For Agent Developers

**1. Return Structured Metadata**:
```yaml
# GOOD agent output
{
  "artifact_path": "specs/027_auth/reports/027_security.md",
  "summary": "[50-word summary]",
  "key_findings": ["Finding 1", "Finding 2"],
  "recommendations": ["Rec 1", "Rec 2"]
}

# BAD agent output
"I created a report at specs/027_auth/reports/027_security.md which discusses security patterns and recommends using bcrypt..."
```

**2. Don't Include Routing Logic**:
```yaml
# GOOD agent prompt
"Research authentication security best practices and create a report.
Return: report path + summary."

# BAD agent prompt
"Research auth security. When done, the orchestrator will call the planning agent next, so make sure your summary helps with planning."
```

**3. Keep Summaries Concise**:
```yaml
summary_guidelines:
  max_length: 50 words
  focus: key findings and actionable insights
  avoid: implementation details, exhaustive lists
```

### For Workflow Orchestrators

**1. Maintain Master Plan as Context Anchor**:
```yaml
orchestrator_state:
  master_plan:
    - [ ] Research
    - [ ] Planning
    - [x] Implementation  # Current phase
    - [ ] Debugging
    - [ ] Documentation

  active_context: "master_plan + current_phase_summary"
  archived_context: "completed_phase_summaries"
```

**2. Read Full Artifacts Only When Needed**:
```yaml
read_full_artifact_when:
  - planning_phase_needs_research_details: read research reports
  - implementation_phase_needs_plan_details: read current phase from plan
  - debugging_phase_needs_error_context: read debug reports

avoid_reading_when:
  - summary_is_sufficient: use metadata instead
  - phase_already_complete: use phase summary
```

**3. Monitor Context Usage**:
```yaml
context_monitoring:
  target: <30% usage
  warning_threshold: 25%
  action_threshold: 20% (invoke spec updater)

  actions_when_high:
    - compress_summaries: 200 words → 100 words
    - prune_completed_phases: aggressive
    - create_partial_summary: offload details to file
```

**4. Use Checkpoints for Recovery**:
```yaml
checkpoint_after_each_phase:
  phase_name: "implementation"
  outputs:
    summary: "[200 words]"
    artifacts: ["path1", "path2"]
  next_phase: "documentation"

recovery_on_interruption:
  - identify_last_successful_checkpoint
  - restore_workflow_state
  - resume_from_next_phase
```

---

## Performance Metrics

### Context Reduction Achievements

**Research Phase**:
- Full reports: 5000 tokens each × 4 = 20,000 tokens
- Metadata summaries: 250 tokens each × 4 = 1,000 tokens
- **Reduction**: 95%

**Planning Phase**:
- Full plan: 8,000 tokens
- Plan metadata: 350 tokens
- **Reduction**: 96%

**Implementation Phase**:
- All phase details: 30,000 tokens (6 phases × 5,000 each)
- Phase summaries: 600 tokens (6 phases × 100 each)
- **Reduction**: 98%

**Overall Workflow**:
- Full context (all artifacts): 60,000 tokens
- Orchestrator context (metadata + summaries): 2,500 tokens
- **Reduction**: 96%

**Context Usage Target**: <30% (60,000 tokens max / 200,000 limit)

### Time Savings with Parallelization

**Sequential Execution**:
```yaml
research: 20 min (4 agents × 5 min)
planning: 5 min
implementation: 60 min (6 phases × 10 min)
testing: 10 min
documentation: 5 min
Total: 100 min
```

**Parallel Execution**:
```yaml
research: 5 min (4 agents in parallel)
planning: 5 min
implementation: 40 min (wave-based, 2-3 phases per wave)
testing: 10 min
documentation: 5 min
Total: 65 min
Savings: 35 min (35%)
```

**Best-Case Parallelization** (highly independent phases):
```yaml
implementation_waves:
  Wave 1: 10 min (1 phase)
  Wave 2: 10 min (3 phases in parallel)
  Wave 3: 10 min (2 phases in parallel)
Total: 30 min
Savings: 50%
```

---

## Related Documentation

### Concepts
- [Hierarchical Agent Architecture](../concepts/hierarchical_agents.md) - Technical architecture details
- [Development Workflow](../concepts/development-workflow.md) - Spec updater and artifact lifecycle
- [Directory Protocols](../concepts/directory-protocols.md) - Topic-based directory structure

### Workflows
- [Orchestration Guide](orchestration-guide.md) - Multi-agent workflow coordination
- [Adaptive Planning Guide](adaptive-planning-guide.md) - Plan expansion and complexity evaluation
- [Spec Updater Guide](spec_updater_guide.md) - Artifact management details

### Guides
- [Using Agents](../guides/using-agents.md) - Agent invocation patterns
- [Command Patterns](../guides/command-patterns.md) - Command implementation patterns
- [Data Management](../guides/data-management.md) - Data directory and logging

### Reference
- [Command Reference](../reference/command-reference.md) - All command syntax
- [Agent Reference](../reference/agent-reference.md) - All agent capabilities
- [Phase Dependencies](../reference/phase_dependencies.md) - Dependency syntax reference
