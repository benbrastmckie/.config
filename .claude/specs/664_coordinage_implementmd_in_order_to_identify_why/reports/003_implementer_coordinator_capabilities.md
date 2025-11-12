# Implementer-Coordinator Agent Capabilities and Invocation Research Report

## Metadata
- **Date**: 2025-11-11
- **Agent**: research-specialist
- **Topic**: Implementer-coordinator agent capabilities and invocation patterns
- **Report Type**: Codebase analysis and integration patterns

## Executive Summary

The implementer-coordinator agent is a specialized Haiku-tier agent designed for deterministic wave-based parallel phase execution. It orchestrates multiple implementation-executor subagents using dependency analysis from the dependency-analyzer.sh utility, achieving 40-60% time savings through parallel execution. The agent operates as a pure orchestrator with no direct code modification responsibilities, delegating all implementation work to specialized implementation-executor subagents.

## Findings

### 1. Agent Role and Architecture

**Agent Definition**: `/home/benjamin/.config/.claude/agents/implementer-coordinator.md`

**Core Characteristics**:
- **Model Tier**: Haiku 4.5 (cost-optimized for mechanical orchestration)
- **Model Justification**: "Deterministic wave orchestration and state tracking, mechanical subagent coordination following explicit algorithm" (line 5)
- **Allowed Tools**: Read, Bash, Task (line 2)
- **Scope**: Wave-based implementation orchestration only (no direct code writing)

**Key Responsibilities** (lines 11-22):
1. Dependency Analysis: Invoke dependency-analyzer utility to build execution structure
2. Wave Orchestration: Execute phases wave-by-wave with parallel executors
3. Progress Monitoring: Collect updates from all executors in real-time
4. State Management: Maintain implementation state across waves
5. Failure Handling: Detect failures, mark phases, continue independent work
6. Result Aggregation: Collect completion reports and metrics

### 2. Input Format and Context Requirements

**Required Inputs** (lines 27-44):
The agent expects pre-calculated paths (Phase 0 optimization pattern) from the coordinate command:

```yaml
plan_path: /path/to/specs/027_auth/plans/027_auth_implementation.md
topic_path: /path/to/specs/027_auth
artifact_paths:
  reports: /path/to/specs/027_auth/reports/
  plans: /path/to/specs/027_auth/plans/
  summaries: /path/to/specs/027_auth/summaries/
  debug: /path/to/specs/027_auth/debug/
  outputs: /path/to/specs/027_auth/outputs/
  checkpoints: /home/user/.claude/data/checkpoints/
```

**Critical Design**: The coordinate command must pre-calculate all artifact paths using unified-location-detection.sh BEFORE invoking the agent. This is the Phase 0 optimization pattern that provides 85% token reduction and 25x speedup.

### 3. Workflow Execution Steps

#### STEP 1: Plan Structure Detection (lines 46-76)

The agent auto-detects three plan hierarchy levels:
- **Level 0**: All phases inline in single file
- **Level 1**: Phases in separate files (plan_dir/phase_N.md)
- **Level 2**: Stages in separate files (plan_dir/phase_N/stage_M.md)

Detection uses filesystem checks (lines 59-76):
```bash
plan_dir=$(dirname "$plan_path")/$(basename "$plan_path" .md)
if [ -d "$plan_dir" ]; then
  if ls "$plan_dir"/phase_*.md >/dev/null 2>&1; then
    if ls "$plan_dir"/phase_*/ >/dev/null 2>&1; then
      STRUCTURE_LEVEL=2  # Stage files exist
    else
      STRUCTURE_LEVEL=1  # Phase files only
    fi
  fi
else
  STRUCTURE_LEVEL=0  # Inline plan
fi
```

#### STEP 2: Dependency Analysis (lines 78-118)

The agent invokes the dependency-analyzer utility to build execution waves:

```bash
bash /home/user/.config/.claude/lib/dependency-analyzer.sh "$plan_path" > dependency_analysis.json
```

**Dependency-Analyzer Utility** (`/home/benjamin/.config/.claude/lib/dependency-analyzer.sh`):
- Parses phase dependency metadata (depends_on: [...], blocks: [...])
- Builds dependency graph with topological sorting
- Identifies execution waves (groups of independent phases)
- Detects circular dependencies (fail-fast validation)
- Calculates parallelization metrics (time savings estimates)

**Output Structure** (lines 609-618):
```json
{
  "dependency_graph": {
    "nodes": [...],
    "edges": [...]
  },
  "waves": [
    {"wave_number": 1, "phases": ["phase_1"], "can_parallel": false},
    {"wave_number": 2, "phases": ["phase_2", "phase_3"], "can_parallel": true}
  ],
  "metrics": {
    "total_phases": 5,
    "parallel_phases": 2,
    "sequential_estimated_time": "15 hours",
    "parallel_estimated_time": "9 hours",
    "time_savings_percentage": "40%"
  }
}
```

#### STEP 3: Wave Execution Loop (lines 120-269)

For each wave, the agent:

1. **Wave Initialization**: Log wave start, create wave state object
2. **Parallel Executor Invocation**: Invoke implementation-executor subagent for each phase via Task tool
3. **Progress Monitoring**: Collect completion reports from all executors
4. **Wave Synchronization**: Wait for ALL executors to complete before proceeding
5. **Failure Handling**: Mark failed phases, check dependency impact, continue independent work
6. **Wave Completion**: Log wave end, update plan hierarchy

**Critical Pattern - Parallel Invocation** (lines 136-185):
The agent invokes multiple implementation-executor subagents in a SINGLE response using multiple Task tool calls:

```markdown
Task {
  subagent_type: "general-purpose"
  description: "Execute Phase 2 implementation"
  prompt: |
    Read and follow behavioral guidelines from:
    /home/user/.config/.claude/agents/implementation-executor.md

    You are executing Phase 2: Backend Implementation

    Input:
    - phase_file_path: /path/to/specs/027_auth/plans/027_auth_implementation/phase_2_backend.md
    - topic_path: /path/to/specs/027_auth
    - artifact_paths: {...}
    - wave_number: 2
    - phase_number: 2

    Execute all tasks in this phase, update plan file with progress,
    run tests, create git commit, report completion.
}

Task {
  subagent_type: "general-purpose"
  description: "Execute Phase 3 implementation"
  prompt: |
    Read and follow behavioral guidelines from:
    /home/user/.config/.claude/agents/implementation-executor.md

    You are executing Phase 3: Frontend Implementation

    Input:
    - phase_file_path: /path/to/specs/027_auth/plans/027_auth_implementation/phase_3_frontend.md
    - topic_path: /path/to/specs/027_auth
    - artifact_paths: {...}
    - wave_number: 2
    - phase_number: 3

    Execute all tasks in this phase, update plan file with progress,
    run tests, create git commit, report completion.
}
```

**Synchronization Guarantee** (lines 222-228):
All executors in a wave MUST report completion (success or failure) before proceeding to the next wave. This ensures dependency correctness and isolates failures.

#### STEP 4: Result Aggregation (lines 271-310)

After all waves complete, the agent:

1. Collects implementation metrics (phases executed, success/failure counts, elapsed time)
2. Calculates time savings: `(sequential_time - parallel_time) / sequential_time * 100`
3. Generates implementation report with status, git commits, checkpoints, and failure details
4. Returns ONLY the implementation report (not full implementation details)

**Output Format** (lines 352-390):
```
═══════════════════════════════════════════════════════
WAVE-BASED IMPLEMENTATION REPORT
═══════════════════════════════════════════════════════
Status: {completed|partial|failed}
Waves Executed: {N}
Total Phases: {N}
Successful: {N}
Failed: {N}
Elapsed Time: {X hours}
Estimated Sequential Time: {Y hours}
Time Savings: {Z%}
Git Commits: {count}
Checkpoints: {count if any}
═══════════════════════════════════════════════════════
```

### 4. Invocation Pattern from /coordinate Command

**Location**: `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 1169-1189)

The coordinate command invokes the implementer-coordinator in the STATE_IMPLEMENT handler:

```markdown
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
```

**Key Pattern Elements**:
1. **Imperative Invocation**: Direct reference to agent behavioral file (not documentation-only YAML)
2. **Pre-calculated Paths**: All artifact paths provided from Phase 0 optimization (85% token reduction)
3. **Absolute Paths**: All paths are absolute (not relative)
4. **Timeout**: 600000ms (10 minutes) for wave-based execution
5. **Context Injection**: Workflow-specific context passed as structured input

**Phase 0 Optimization Integration** (lines 199-219):

The coordinate command calculates artifact paths BEFORE agent invocation:

```bash
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
```

### 5. Implementation-Executor Subagent Relationship

**Implementation-Executor Agent**: `/home/benjamin/.config/.claude/agents/implementation-executor.md`

**Core Characteristics**:
- **Model Tier**: Sonnet 4.5 (quality-optimized for task execution)
- **Model Justification**: "Task execution, plan hierarchy updates, checkpoint management, git commits" (line 5)
- **Allowed Tools**: Read, Write, Edit, Bash, TodoWrite (line 2)
- **Scope**: Single phase/stage execution with progress tracking

**Key Responsibilities** (lines 19-24):
1. Task Execution: Implement all tasks in assigned phase/stage sequentially
2. Plan Updates: Mark tasks complete and update plan hierarchy
3. Progress Reporting: Send brief updates to coordinator
4. Checkpoint Creation: Save checkpoints if context constrained
5. Git Commits: Create commit after phase completion

**Important Behavioral Change** (line 15):
"This agent NO LONGER runs tests. Testing has been separated into dedicated Phase 6 (Comprehensive Testing) in the /orchestrate workflow."

**Coordinator → Executor Flow**:
1. Coordinator analyzes dependencies and identifies waves
2. Coordinator invokes N executors in parallel (one per phase in wave)
3. Each executor reads its phase file, implements tasks, updates plan hierarchy
4. Each executor creates git commit and reports completion
5. Coordinator collects completion reports and proceeds to next wave

### 6. Phase 0 Optimization Pattern

**Documentation**: `/home/benjamin/.config/.claude/docs/guides/phase-0-optimization.md`

**Historical Problem** (lines 19-76):
Agent-based location detection consumed 75,600 tokens (302% of budget) and took 25.2 seconds, polluting repositories with 400-500 empty directories.

**Current Solution** (lines 78-113):
Unified-location-detection.sh library reduces to 11,000 tokens (12.4% of budget) and <1 second execution:

```bash
source "${CLAUDE_CONFIG}/.claude/lib/unified-location-detection.sh"
LOCATION_JSON=$(perform_location_detection "implement JWT authentication")
TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
REPORTS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')
```

**Benefits**:
- **Token Reduction**: 85% (75,600 → 11,000 tokens)
- **Speed Improvement**: 25x faster (25.2s → <1s)
- **Directory Pollution**: Eliminated (lazy creation pattern)
- **Context Before Research**: Zero tokens (paths calculated, not created)

**Integration Requirement**:
All orchestration commands (coordinate, orchestrate, supervise) MUST use unified-location-detection.sh for Phase 0. Agent-based detection is an anti-pattern.

### 7. Error Handling and Failure Isolation

**Context Window Constraints** (lines 314-327):
If an executor reports context pressure, it creates a checkpoint:
```
⚠ Phase 2 checkpointed due to context pressure
  Checkpoint: /home/user/.claude/data/checkpoints/027_auth_phase_2_20251022_153045.json
  Progress: 6/15 tasks complete
  Resume: /resume-implement <checkpoint-path>
```

**Executor Failures** (lines 329-336):
- Mark phase as failed in state
- Check if failure blocks subsequent waves (dependency check)
- If blocks: Halt remaining waves, return partial completion
- If independent: Continue with remaining work

**Dependency Violations** (lines 338-343):
- Log dependency violation error
- Re-run dependency analysis to debug
- Halt execution and return error

**Circular Dependencies** (lines 345-350):
- Dependency-analyzer detects cycles using DFS (lines 401-474)
- Returns error immediately (cannot proceed)
- User MUST fix plan dependencies

### 8. Performance Characteristics

**Parallelization Strategy** (lines 394-398):
- **Maximize parallelism**: All independent phases in same wave run concurrently
- **Preserve correctness**: Dependent phases always run after their dependencies
- **Target**: 40-60% time savings for typical workflows with 2-4 parallel phases

**Context Efficiency** (lines 406-410):
- **Receive**: Phase file paths + dependency graph (not full plan content)
- **Executors return**: Brief progress summaries (not full implementation details)
- **Target**: <20% context usage for entire implementation phase

**Example Wave Structures** (lines 432-461):

**Sequential Plan** (no parallelism):
```
Wave 1: [Phase 1] → Wave 2: [Phase 2] → Wave 3: [Phase 3]
Time: 3 hours + 3 hours + 3 hours = 9 hours
Savings: 0%
```

**Parallel Plan** (2 parallel phases):
```
Wave 1: [Phase 1]
Wave 2: [Phase 2, Phase 3] (PARALLEL)
Wave 3: [Phase 4]
Time: 3 hours + 3 hours + 3 hours = 9 hours
Sequential equivalent: 12 hours
Savings: 25%
```

**Highly Parallel Plan** (3 parallel phases):
```
Wave 1: [Phase 1]
Wave 2: [Phase 2, Phase 3, Phase 4] (PARALLEL)
Wave 3: [Phase 5]
Time: 9 hours
Sequential equivalent: 15 hours
Savings: 40%
```

### 9. Limits and Constraints

**Agent Constraints** (lines 464-468):
- **Maximum Wave Size**: 4 phases per wave (context management)
- **Maximum Waves**: No limit (depends on plan structure)
- **Checkpoint Threshold**: 70% context usage
- **Retry Logic**: No automatic retries (orchestrator handles via debugging phase)

**Success Criteria** (lines 470-479):
- ✓ All waves executed in correct dependency order
- ✓ All phases completed successfully OR failures isolated
- ✓ Time savings 40-60% for plans with 2+ parallel phases
- ✓ Context usage <20% for coordination overhead
- ✓ Git commits created for all completed phases
- ✓ Plan hierarchy updated with completion status

## Recommendations

### 1. Ensure Phase 0 Optimization in Coordinate Command

**Action**: Verify coordinate command pre-calculates all artifact paths using unified-location-detection.sh BEFORE invoking implementer-coordinator agent.

**Rationale**: Phase 0 optimization provides 85% token reduction and 25x speedup. Without it, the implementer-coordinator cannot operate within context budget.

**Implementation**: Lines 199-219 in coordinate.md show correct pattern. Verify this code exists and executes before STATE_IMPLEMENT handler.

### 2. Use Imperative Invocation Pattern

**Action**: Ensure coordinate command uses imperative Task invocation with direct reference to agent behavioral file, not documentation-only YAML blocks.

**Rationale**: Standard 11 (Imperative Agent Invocation Pattern) requires imperative instructions to ensure reliable agent execution.

**Verification**: Lines 1169-1189 in coordinate.md show correct pattern: "Read and follow ALL behavioral guidelines from: ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md"

### 3. Inject Pre-Calculated Artifact Paths

**Action**: Pass all artifact paths (REPORTS_DIR, PLANS_DIR, SUMMARIES_DIR, DEBUG_DIR, OUTPUTS_DIR, CHECKPOINT_DIR) as structured context in agent prompt.

**Rationale**: Implementer-coordinator expects pre-calculated paths and delegates path information to implementation-executor subagents. This follows Phase 0 optimization pattern.

**Implementation**: Lines 1180-1189 show correct pattern with all 6 artifact paths provided.

### 4. Provide Absolute Paths Only

**Action**: Ensure PLAN_PATH and TOPIC_PATH are absolute paths, not relative.

**Rationale**: Agents operate in different bash subprocesses with potentially different working directories. Absolute paths ensure reliability.

**Verification**: Use `realpath` or full path resolution before passing to agent.

### 5. Set Appropriate Timeout

**Action**: Use timeout: 600000 (10 minutes) for wave-based execution.

**Rationale**: Parallel execution with multiple phases requires longer timeout than single-phase operations. 10 minutes allows for 3-4 phases executing in parallel.

**Implementation**: Line 1174 shows correct timeout value.

### 6. Handle Implementation Report Response

**Action**: Parse implementation report returned by implementer-coordinator to extract status, success/failure counts, git commits, and checkpoints.

**Rationale**: Coordinate command needs this information to determine whether to proceed to testing phase or debugging phase.

**Expected Format**: Lines 352-390 define the report structure. Parse for "Status: completed|partial|failed" to make control flow decisions.

### 7. Verify State Transitions

**Action**: Ensure coordinate command transitions from STATE_PLAN to STATE_IMPLEMENT correctly, and from STATE_IMPLEMENT to STATE_TEST (success) or STATE_DEBUG (failures).

**Rationale**: State machine validation prevents invalid state transitions and ensures workflow integrity.

**Implementation**: Lines 1090-1093 show transition to STATE_IMPLEMENT. Add similar transitions after implementation phase completion.

## References

### Agent Files
- `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` - Primary agent behavioral guidelines (479 lines)
- `/home/benjamin/.config/.claude/agents/implementation-executor.md` - Subagent behavioral guidelines (200+ lines analyzed)

### Library Files
- `/home/benjamin/.config/.claude/lib/dependency-analyzer.sh` - Dependency analysis and wave identification (639 lines)
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` - Phase 0 optimization library (referenced in phase-0-optimization.md)

### Command Files
- `/home/benjamin/.config/.claude/commands/coordinate.md:1169-1189` - Implementer-coordinator invocation pattern
- `/home/benjamin/.config/.claude/commands/coordinate.md:199-219` - Phase 0 artifact path calculation

### Documentation Files
- `/home/benjamin/.config/.claude/docs/guides/phase-0-optimization.md` - Complete Phase 0 pattern documentation (625 lines)
- `/home/benjamin/.config/CLAUDE.md:199-218` - Phase 0 optimization section in project standards

### Related Patterns
- Imperative Agent Invocation Pattern (Standard 11)
- Phase 0 Optimization Pattern (85% token reduction, 25x speedup)
- Wave-Based Parallel Execution Pattern (40-60% time savings)
- Lazy Directory Creation Pattern (zero empty directory pollution)
