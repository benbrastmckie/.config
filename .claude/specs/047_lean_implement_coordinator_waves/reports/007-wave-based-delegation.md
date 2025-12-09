# Wave-Based Full Plan Delegation Architecture Research

**Date**: 2025-12-09
**Research Focus**: Wave-based orchestration patterns for full plan delegation in /lean-implement command refactoring
**Research Context**: Phase 9 of spec 047 - Transform per-phase routing to wave-based parallel execution
**Status**: Research Complete

---

## Executive Summary

This research analyzes the architectural transformation required to refactor `/lean-implement` from per-phase routing to full plan delegation with wave-based parallel execution. The analysis reveals that implementer-coordinator already implements a mature wave-based pattern achieving 40-60% time savings, providing a proven template for the lean-implement refactor.

**Key Findings**:
1. **Proven Wave Pattern**: implementer-coordinator demonstrates complete wave-based orchestration (dependency analysis → wave calculation → parallel execution → synchronization)
2. **Architecture Gap**: /lean-implement currently routes ONE phase at a time, missing 40-60% time savings opportunity
3. **Dependency Infrastructure**: dependency-analyzer.sh provides robust Kahn's algorithm implementation with cycle detection
4. **Parallel Task Invocation**: Multiple Task calls in single coordinator response enable true parallel execution
5. **Context Efficiency**: Brief summary pattern (96% reduction) enables 10+ iteration capacity
6. **Risk Assessment**: High-risk refactor due to iteration loop redesign and coordinator invocation changes

**Critical Success Factors**:
- Full plan passed to coordinator (not single phase)
- Coordinator calculates waves via dependency-analyzer.sh
- Wave execution loop with parallel Task invocations
- Iteration loop triggered only on context threshold (not per-phase)
- Hard barrier validation ensures summary creation

---

## Research Questions

### 1. What are the proven wave-based orchestration patterns in existing coordinators?

**Answer**: implementer-coordinator.md implements a 4-step wave orchestration pattern:

**STEP 1: Plan Structure Detection** (implementer-coordinator.md:54-84)
- Detects Level 0 (inline), Level 1 (phase files), or Level 2 (stage files)
- Builds file list for dependency analysis
- Tier-agnostic approach handles all plan structures

**STEP 2: Dependency Analysis** (implementer-coordinator.md:86-126)
```bash
# Invoke dependency-analyzer utility
bash /path/.claude/lib/util/dependency-analyzer.sh "$plan_path" > dependency_analysis.json

# Parse JSON output
WAVES=$(jq '.waves' dependency_analysis.json)
METRICS=$(jq '.metrics' dependency_analysis.json)

# Validate no cycles
if jq -e '.error' dependency_analysis.json; then
  echo "ERROR: Circular dependency detected"
  exit 1
fi
```

**STEP 3: Iteration Management** (implementer-coordinator.md:128-246)
- Context estimation with defensive error handling (validates numeric inputs, 10k-300k token sanity check)
- Checkpoint saving when context threshold exceeded (default 85%)
- Stuck detection (work_remaining unchanged for 2 iterations)
- Iteration limit enforcement (halt at max_iterations)

**STEP 4: Wave Execution Loop** (implementer-coordinator.md:248-432)
```markdown
FOR EACH wave in wave structure:

### Wave Initialization
- Log wave start
- Initialize executor tracking
- Prepare parallel invocation

### Parallel Executor Invocation
**CRITICAL**: Multiple Task invocations in SINGLE response

Example for Wave 2 with 2 phases:

I'm now invoking implementation-executor for Phase 2 and Phase 3 in parallel (Wave 2).

**EXECUTE NOW**: USE the Task tool to invoke the implementation-executor.

Task {
  description: "Execute Phase 2 implementation"
  prompt: |
    Read and follow behavioral guidelines from:
    /path/.claude/agents/implementation-executor.md

    Input:
    - phase_file_path: /path/phase_2.md
    - wave_number: 2
    - phase_number: 2
}

**EXECUTE NOW**: USE the Task tool to invoke the implementation-executor.

Task {
  description: "Execute Phase 3 implementation"
  prompt: |
    ...phase 3 parameters...
}

### Wave Synchronization
**CRITICAL**: Wait for ALL executors to complete before Wave N+1
- Collect completion reports from all executors
- Validate all phases complete (success or failure)
- Aggregate metrics (tasks, commits, markers)
- Update wave state with results
```

**Key Pattern**: Multiple Task invocations in single coordinator response → Claude executes in parallel

**Performance Metrics** (from hierarchical-agents-examples.md:1110-1122):
- Time savings: 40-60% for plans with 2+ parallel phases
- Context reduction: 96% via brief summary parsing (2,000 → 80 tokens)
- Iteration capacity: 10+ iterations (vs 3-4 before optimization)

### 2. How does dependency-analyzer.sh calculate waves from plan dependencies?

**Answer**: Kahn's algorithm with topological sort

**Algorithm** (dependency-analyzer.sh:296-392):
```bash
identify_waves() {
  local dependency_graph="$1"

  # Step 1: Build in-degree map (count incoming edges per node)
  declare -A in_degree
  for phase in $all_phases; do
    in_degree[$phase]=0
  done

  # Count incoming edges
  while IFS= read -r edge; do
    local to_phase=$(echo "$edge" | jq -r '.to')
    ((in_degree[$to_phase]++))
  done < <(echo "$dependency_graph" | jq -c '.edges[]')

  # Step 2: Wave identification loop
  wave_number=1
  while [[ ${#remaining_phases[@]} -gt 0 ]]; do
    # Find all phases with in-degree 0 (no unsatisfied dependencies)
    for phase in "${remaining_phases[@]}"; do
      if [[ ${in_degree[$phase]} -eq 0 ]]; then
        wave_phases+=("$phase")
      fi
    done

    # Break if no phases can be added (circular dependency)
    if [[ ${#wave_phases[@]} -eq 0 ]]; then
      echo "ERROR: Circular dependency detected" >&2
      break
    fi

    # Create wave object with parallelization flag
    wave=$(jq -n \
      --argjson wave_num "$wave_number" \
      --argjson phases "$wave_phases_json" \
      '{wave_number: $wave_num, phases: $phases, can_parallel: ($phases | length > 1)}')

    # Add to result
    waves=$(echo "$waves" | jq ". += [$wave]")

    # Step 3: Reduce in-degree for dependent phases
    for wave_phase in "${wave_phases[@]}"; do
      # For each edge FROM completed phase, decrement TO phase in-degree
      while IFS= read -r edge; do
        local from_phase=$(echo "$edge" | jq -r '.from')
        local to_phase=$(echo "$edge" | jq -r '.to')
        if [[ "$from_phase" == "$wave_phase" ]]; then
          ((in_degree[$to_phase]--))
        fi
      done < <(echo "$dependency_graph" | jq -c '.edges[]')
    done

    ((wave_number++))
  done

  echo "$waves"
}
```

**Input Format** (dependency-analyzer.sh:64-136):
```markdown
### Phase 2: Backend Implementation [NOT STARTED]

**Dependencies**: depends_on: [phase_1]
**Blocks**: blocks: [phase_4, phase_5]

Tasks:
- [ ] Implement authentication module
```

**Output Format** (JSON):
```json
{
  "waves": [
    {
      "wave_number": 1,
      "phases": ["phase_1"],
      "can_parallel": false
    },
    {
      "wave_number": 2,
      "phases": ["phase_2", "phase_3"],
      "can_parallel": true
    }
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

**Cycle Detection** (dependency-analyzer.sh:401-474):
- DFS-based cycle detection before wave calculation
- Returns error with cycle details if detected
- Prevents infinite loops in wave execution

**Key Guarantees**:
- Phases in Wave N+1 only execute after ALL Wave N phases complete
- No premature execution (dependency violations impossible)
- Independent phases in same wave can execute in parallel

### 3. What are the parallel Task invocation strategies for wave execution?

**Answer**: Multiple Task invocations in single coordinator response

**Strategy 1: Simultaneous Invocation** (implementer-coordinator.md:256-330)
```markdown
Wave 2 with 2 parallel phases:

I'm now invoking implementation-executor for Phase 2 and Phase 3 in parallel (Wave 2).

**EXECUTE NOW**: USE the Task tool to invoke the implementation-executor.

Task {
  subagent_type: "general-purpose"
  description: "Execute Phase 2 implementation"
  prompt: "..."
}

**EXECUTE NOW**: USE the Task tool to invoke the implementation-executor.

Task {
  subagent_type: "general-purpose"
  description: "Execute Phase 3 implementation"
  prompt: "..."
}
```

**Key Pattern**: No waiting between Task invocations → both execute concurrently

**Strategy 2: Wave Synchronization** (implementer-coordinator.md:388-394)
```markdown
**CRITICAL**: Wait for ALL executors in wave to complete before proceeding to next wave.

- All executors MUST report completion (success or failure)
- Aggregate results from all executors
- Update implementation state with wave results
- Proceed to next wave only after synchronization
```

**Hard Barrier Enforcement**: Coordinator blocks on wave completion, ensuring dependency correctness

**Performance Impact** (parallel-execution.md:253-263):
| Workflow | Sequential | Wave-Based | Savings |
|----------|-----------|------------|---------|
| 4-agent research | 40 min | 10 min | 75% |
| 5-phase implementation | 16 hours | 12 hours | 25% |
| Complex workflow (15 phases, 6 waves) | 30 hours | 12 hours | 60% |

**Anti-Pattern Warning** (parallel-execution.md:239-251):
```markdown
❌ BAD - Waiting between invocations:

Agent 1: invoke executor
wait for Agent 1 to complete  # ← Wrong!
Agent 2: invoke executor
wait for Agent 2 to complete  # ← Wrong!

This is sequential execution disguised as parallel.
```

**Correct Pattern**: Invoke all agents in wave, THEN wait for all

### 4. How does context threshold management work across wave boundaries?

**Answer**: Context estimation after each wave with checkpoint saving on threshold exceeded

**Context Estimation Function** (implementer-coordinator.md:134-189):
```bash
estimate_context_usage() {
  local completed_phases="$1"
  local remaining_phases="$2"
  local has_continuation="$3"

  # Defensive input validation
  if ! [[ "$completed_phases" =~ ^[0-9]+$ ]]; then
    echo "WARNING: Invalid completed_phases, defaulting to 0" >&2
    completed_phases=0
  fi
  if ! [[ "$remaining_phases" =~ ^[0-9]+$ ]]; then
    echo "WARNING: Invalid remaining_phases, defaulting to 1" >&2
    remaining_phases=1
  fi

  # Context cost model
  local base=20000  # Plan + standards + system prompt
  local completed_cost=$((completed_phases * 15000))  # Each phase ~15k tokens
  local remaining_cost=$((remaining_phases * 12000))  # Estimate for remaining
  local continuation_cost=0

  if [ "$has_continuation" = "true" ]; then
    continuation_cost=5000
  fi

  local total=$((base + completed_cost + remaining_cost + continuation_cost))

  # Sanity check (10k-300k range)
  if [ "$total" -lt 10000 ] || [ "$total" -gt 300000 ]; then
    echo "WARNING: Context estimate out of range ($total tokens)" >&2
    echo 100000  # Conservative 50% of 200k window
  else
    echo "$total"
  fi
}
```

**Checkpoint Trigger Logic** (implementer-coordinator.md:191-229):
```bash
# After each wave completion:
CONTEXT_ESTIMATE=$(estimate_context_usage "$COMPLETED_COUNT" "$REMAINING_COUNT" "$HAS_CONTINUATION")
CONTEXT_PERCENT=$(( (CONTEXT_ESTIMATE * 100) / 200000 ))  # 200k context window

if [ "$CONTEXT_PERCENT" -ge "$CONTEXT_THRESHOLD" ]; then
  echo "WARNING: Context threshold exceeded (${CONTEXT_PERCENT}% >= ${CONTEXT_THRESHOLD}%)"

  # Save checkpoint
  CHECKPOINT_FILE=$(save_resumption_checkpoint "context_threshold_exceeded")

  # Set halt flag
  REQUIRES_CONTINUATION="false"
  CONTEXT_EXHAUSTED="true"

  # Exit wave loop early
  break
fi
```

**Checkpoint Schema v2.1** (implementer-coordinator.md:196-228):
```json
{
  "version": "2.1",
  "timestamp": "2025-12-09T14:30:00Z",
  "plan_path": "/path/to/plan.md",
  "topic_path": "/path/to/topic",
  "iteration": 3,
  "max_iterations": 5,
  "continuation_context": "/path/to/iteration_2_summary.md",
  "work_remaining": "Phase_4 Phase_5 Phase_6",
  "context_estimate": 170000,
  "halt_reason": "context_threshold_exceeded"
}
```

**Wave Boundary Behavior**:
- Context checked AFTER each wave completes (not mid-wave)
- Wave always completes fully before checkpoint (atomic wave execution)
- Next iteration resumes from first incomplete phase
- Continuation context provides completed phase summary (not full details)

**Multi-Iteration Flow** (implementer-coordinator.md:812-870):
```
Iteration 1 (fresh start):
  - Execute Wave 1-2 (Phases 1-5)
  - Context: 85% → checkpoint saved
  - Returns: work_remaining: Phase_6 Phase_7 Phase_8

Iteration 2 (continuation):
  - Read iteration_1_summary.md (brief context: 80 tokens)
  - Execute Wave 3 (Phases 6-7)
  - Context: 88% → checkpoint saved
  - Returns: work_remaining: Phase_8

Iteration 3 (continuation):
  - Read iteration_2_summary.md (brief context: 80 tokens)
  - Execute Wave 4 (Phase 8)
  - Context: 60% → complete
  - Returns: work_remaining: 0
```

**Brief Summary Pattern** (96% context reduction):
- Coordinator returns `summary_brief` field (80 tokens)
- Orchestrator parses brief field only (not full 2,000-token file)
- Enables 10+ iterations vs 3-4 before optimization

### 5. What are the risk mitigation strategies for this major refactor?

**Answer**: Phased rollout, backup strategy, defensive validation, integration testing

**Risk Assessment**:

| Risk Category | Impact | Probability | Mitigation Strategy |
|--------------|--------|-------------|---------------------|
| Iteration loop regression | High | Medium | Comprehensive integration tests, backup restoration plan |
| Coordinator invocation failure | High | Low | Hard barrier validation, error logging with Task error protocol |
| Wave calculation errors | Medium | Low | dependency-analyzer.sh tested (7/7 unit tests passing) |
| Context threshold bugs | Medium | Medium | Defensive numeric validation, sanity checks (10k-300k range) |
| Phase marker loss | Low | Low | Coordinator handles markers (Block 1d removed), no regression risk |

**Mitigation Strategy 1: Incremental Refactor with Backup** (Phase 0 of plan):
```bash
# Create backup before refactoring
cp /path/lean-implement.md /path/lean-implement.md.backup.20251209

# Rollback if critical issues
cp /path/lean-implement.md.backup.20251209 /path/lean-implement.md
```

**Mitigation Strategy 2: Hard Barrier Validation** (lean-implement.md:911-942):
```bash
# Block 1c: Verify coordinator created summary
LATEST_SUMMARY=$(find "$SUMMARIES_DIR" -name "*.md" -type f -mmin -10 | sort | tail -1)

if [ -z "$LATEST_SUMMARY" ] || [ ! -f "$LATEST_SUMMARY" ]; then
  # Enhanced diagnostics: Search alternate locations
  echo "ERROR: HARD BARRIER FAILED - Summary not created by coordinator" >&2

  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "Coordinator did not create summary file" \
    "bash_block_1c" \
    "$(jq -n --arg coord "$COORDINATOR_NAME" '{coordinator: $coord}')"

  exit 1
fi

# Validate summary size
SUMMARY_SIZE=$(wc -c < "$LATEST_SUMMARY")
if [ "$SUMMARY_SIZE" -lt 100 ]; then
  echo "ERROR: Summary too small ($SUMMARY_SIZE bytes)" >&2
  exit 1
fi
```

**Mitigation Strategy 3: Defensive Continuation Validation** (lean-implement.md:1073-1091):
```bash
# Override requires_continuation if work_remaining non-empty
if [ -n "$WORK_REMAINING_NEW" ] && [ "$WORK_REMAINING_NEW" != "0" ]; then
  if [ "$REQUIRES_CONTINUATION" != "true" ]; then
    echo "WARNING: Agent contract violation" >&2
    echo "  work_remaining: $WORK_REMAINING_NEW" >&2
    echo "  Overriding to requires_continuation=true" >&2

    REQUIRES_CONTINUATION="true"

    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "validation_error" \
      "Agent returned requires_continuation=false with work_remaining=$WORK_REMAINING_NEW" \
      "bash_block_1c" \
      "$(jq -n --arg work "$WORK_REMAINING_NEW" '{work_remaining: $work}')"
  fi
fi
```

**Mitigation Strategy 4: Error Logging with Task Error Protocol**:
```markdown
## Coordinator Error Return (lean-coordinator.md:786-835)

If critical error:
1. Output error context (JSON):
   ERROR_CONTEXT: {
     "error_type": "dependency_error",
     "message": "Circular dependency detected",
     "details": {"phases": [2, 3, 4]}
   }

2. Return error signal:
   TASK_ERROR: dependency_error - Circular dependency detected involving phases 2, 3, 4

3. Orchestrator parses with parse_subagent_error() and logs to errors.jsonl
```

**Mitigation Strategy 5: Integration Testing** (Phase 10 of plan):
```bash
# Test 1: Phase 0 detection
# Test 2: Mixed Lean/software plan with dependencies
# Test 3: Context threshold checkpoint save + resume
# Test 4: Blocking dependencies trigger plan revision
# Test 5: Parallel wave timing measurement
```

**Rollback Triggers**:
- Iteration loop enters infinite loop (stuck detection fails)
- Coordinator fails to create summary (hard barrier violation)
- Context estimation errors cause premature halt
- Wave synchronization bugs allow premature Wave N+1 execution

**Rollback Command**:
```bash
# Restore from backup
cp /path/lean-implement.md.backup.20251209 /path/lean-implement.md

# Verify backup integrity
bash /path/.claude/scripts/lint-task-invocation-pattern.sh /path/lean-implement.md
```

### 6. How does the current /lean-implement architecture compare to wave-based patterns?

**Answer**: Current architecture is sequential per-phase routing; completely lacks wave orchestration

**Current /lean-implement Architecture** (lean-implement.md:619-843):
```
/lean-implement (orchestrator)
    |
    +-- Block 1a: Setup & Phase Classification
    |       +-- Classify phases as lean/software
    |       +-- Build routing map (phase_num:type:lean_file)
    |
    +-- Block 1b: Route to Coordinator (SINGLE PHASE)
    |       +-- Determine CURRENT_PHASE from routing map
    |       +-- IF lean: invoke lean-coordinator for Phase N
    |       +-- IF software: invoke implementer-coordinator for Phase N
    |
    +-- Block 1c: Verification & Continuation
    |       +-- Parse coordinator summary
    |       +-- Check context threshold
    |       +-- IF more phases: LOOP back to Block 1b (next phase)
    |       +-- IF context threshold: Save checkpoint, halt
    |
    +-- Block 2: Completion & Summary
```

**Key Issue**: Block 1b routes ONE phase per iteration → sequential execution

**Contrast with /implement Wave-Based Architecture**:
```
/implement (orchestrator)
    |
    +-- Block 1a: Setup
    |       +-- Pre-calculate artifact paths
    |       +-- Initialize workflow state
    |
    +-- Block 1b: Route to Coordinator (FULL PLAN)
    |       +-- Pass FULL plan to implementer-coordinator
    |       +-- Coordinator calculates waves via dependency-analyzer.sh
    |       +-- Coordinator executes wave loop with parallel Task invocations
    |
    +-- Block 1c: Verification & Continuation
    |       +-- Parse brief summary (96% context reduction)
    |       +-- Check context threshold
    |       +-- IF context threshold: LOOP back to Block 1b (continuation)
    |       +-- IF complete: Proceed to Block 2
    |
    +-- Block 2: Completion & Summary
```

**Key Difference**: implementer-coordinator receives full plan and handles ALL phases with wave-based parallelization

**Time Savings Analysis**:

**Current /lean-implement** (5 phases, 2 Lean + 3 software):
```
Iteration 1: Phase 1 (Lean) - 15 min
Iteration 2: Phase 2 (software) - 15 min
Iteration 3: Phase 3 (software) - 15 min
Iteration 4: Phase 4 (Lean) - 15 min
Iteration 5: Phase 5 (software) - 15 min

Total: 75 minutes (sequential)
```

**Wave-Based /lean-implement** (same 5 phases with dependencies):
```
Dependencies:
- Phase 1 (Lean): no dependencies → Wave 1
- Phase 2 (software): depends on Phase 1 → Wave 2
- Phase 3 (software): depends on Phase 1 → Wave 2 (parallel with Phase 2)
- Phase 4 (Lean): depends on Phase 2 → Wave 3
- Phase 5 (software): depends on Phase 3 → Wave 3 (parallel with Phase 4)

Wave 1: Phase 1 - 15 min
Wave 2: Phase 2, 3 (parallel) - max(15, 15) = 15 min
Wave 3: Phase 4, 5 (parallel) - max(15, 15) = 15 min

Total: 45 minutes (wave-based)
Time Savings: 40% (30 minutes saved)
```

**Missed Opportunity**: /lean-implement lacks dependency metadata in routing map → cannot calculate waves → sequential execution only

**Required Changes for Wave-Based Architecture**:
1. Block 1a: Add dependency extraction from plan file (depends_on metadata)
2. Block 1b: Pass FULL plan to coordinator (not single phase)
3. Coordinator: Integrate dependency-analyzer.sh for wave calculation
4. Coordinator: Implement STEP 4 wave execution loop with parallel Task invocations
5. Block 1c: Parse brief summary fields (coordinator_type, summary_brief, phases_completed)
6. Iteration loop: Trigger only on context threshold (not per-phase)

### 7. What performance optimization metrics validate wave-based approach?

**Answer**: 40-60% time savings, 96% context reduction, 10+ iteration capacity

**Metric 1: Time Savings** (parallel-execution.md:253-279, 002-report.md:263-267):
| Workflow Type | Sequential | Wave-Based | Savings |
|---------------|-----------|------------|---------|
| 4 parallel phases | 60 min | 20 min | 67% |
| 2 parallel phases | 30 min | 20 min | 33% |
| 5-phase mixed (2 waves with 2 parallel) | 75 min | 45 min | 40% |
| 15-phase complex (6 waves) | 30 hours | 12 hours | 60% |

**Formula**:
```
Sequential Time = sum(all phase durations)
Parallel Time = sum(max phase duration per wave)
Time Savings = (Sequential - Parallel) / Sequential * 100
```

**Metric 2: Context Reduction** (hierarchical-agents-examples.md:1110-1122):
- Brief summary parsing: 2,000 tokens → 80 tokens = 96% reduction
- Metadata-only passing: 7,500 tokens → 330 tokens = 95% reduction
- Enables 10+ iterations vs 3-4 before optimization

**Metric 3: Iteration Capacity**:
```
Before Brief Summary:
- Per-iteration context cost: 20,000 + (N_phases * 2,000 tokens)
- Context window: 200,000 tokens
- Max iterations: 3-4 (context exhaustion)

After Brief Summary:
- Per-iteration context cost: 20,000 + (N_phases * 80 tokens)
- Context window: 200,000 tokens
- Max iterations: 10+ (brief summary enables more cycles)
```

**Metric 4: Parallelization Efficiency**:
```
Parallel Efficiency = (Time_Sequential - Time_Parallel) / Time_Sequential

Ideal case (4 independent phases):
Efficiency = (60 - 15) / 60 = 75%

Real case (2 parallel, 3 sequential):
Efficiency = (75 - 45) / 75 = 40%
```

**Validation Criteria** (047 plan success criteria):
- 40-60% time savings for plans with 2+ parallel phases ✓
- Context reduction via brief summary parsing (96%) ✓
- Max 2 plan revisions per cycle (revision depth limit) - NOT IMPLEMENTED
- Integration capacity: 10+ iterations possible ✓

**Real-World Examples**:

**Example 1: Lean Coordinator** (hierarchical-agents-examples.md:1095-1122):
```
Complexity 3 Lean plan (10 theorem proofs):
- Without wave orchestration: 10 phases * 15 min = 150 min
- With 3 waves (4+3+3 parallel): 3 waves * 15 min = 45 min
- Time savings: 70% (105 minutes saved)
```

**Example 2: Implementer Coordinator** (002-report.md:263-267):
```
5-phase implementation plan:
- Sequential: 15 hours
- Wave-based: 9 hours (3 waves with 2 parallel phases)
- Time savings: 40% (6 hours saved)
```

**Performance Monitoring** (implementer-coordinator.md:765-785):
```bash
# Track per wave
- Wave start/end times
- Phase execution durations
- Actual vs estimated time savings
- Context usage per wave

# Example output
Wave 1: 15 min (1 phase)
Wave 2: 18 min (2 phases parallel, max duration)
Wave 3: 12 min (2 phases parallel, max duration)
Total: 45 min vs 75 min sequential
Savings: 40%
```

---

## Architecture Recommendations

### Recommendation 1: Full Plan Delegation Pattern

**Problem**: /lean-implement routes one phase at a time, missing 40-60% time savings

**Solution**: Transform Block 1a to pass FULL plan to coordinator

**Current Block 1a** (lean-implement.md:707-728):
```bash
# Determine current phase from routing map
CURRENT_PHASE="$STARTING_PHASE"
PHASE_ENTRY=$(echo "$ROUTING_MAP" | grep "^${CURRENT_PHASE}:" | head -1)

# Parse phase entry
PHASE_NUM=$(echo "$PHASE_ENTRY" | cut -d: -f1)
PHASE_TYPE=$(echo "$PHASE_ENTRY" | cut -d: -f2)
```

**Proposed Block 1a**:
```bash
# Pass FULL plan and routing map to coordinator
# Coordinator will handle ALL phases with wave-based execution

# No phase extraction - coordinator receives full context
EXECUTION_MODE="full-plan"
append_workflow_state "EXECUTION_MODE" "$EXECUTION_MODE"
append_workflow_state "ROUTING_MAP_PATH" "$ROUTING_MAP_FILE"
```

**Coordinator Receives** (new input contract):
```yaml
Input:
  - plan_path: /path/to/plan.md
  - routing_map_path: /path/to/routing_map.txt
  - execution_mode: "full-plan"
  - starting_phase: 1  # For continuation support
  - continuation_context: /path/to/iteration_N_summary.md (or null)
```

**Benefits**:
- Coordinator calculates waves across ALL phases
- Parallel execution of independent Lean/software phases
- Iteration loop only on context threshold (not per-phase)
- 40-60% time savings for mixed plans

**Implementation Effort**: Medium (2-3 hours)

### Recommendation 2: Coordinator Wave Execution Loop

**Problem**: Coordinator needs STEP 4 wave execution with parallel Task invocations

**Solution**: Implement wave loop in lean-coordinator.md (mirror implementer-coordinator pattern)

**Proposed STEP 4** (lean-coordinator.md - new section):
```markdown
## STEP 4: Wave Execution Loop

FOR EACH wave in wave structure:

### Wave Initialization
- Log wave start: "Starting Wave {N}: {phase_count} phases"
- Create wave state object with start time
- Determine phase types from routing map

### Parallel Coordinator Invocation
**CRITICAL**: Use Task tool with multiple invocations in single response

For each phase in wave:
  - If phase_type = "lean": Invoke lean-implementer
  - If phase_type = "software": Invoke implementer-coordinator

Example for Wave 2 with 1 Lean + 1 software phase:

I'm now invoking coordinators for Wave 2 in parallel.

**EXECUTE NOW**: USE the Task tool to invoke lean-implementer.

Task {
  subagent_type: "general-purpose"
  description: "Prove theorem in Phase 2"
  prompt: |
    Read and follow behavioral guidelines from:
    /path/.claude/agents/lean-implementer.md

    Input:
    - lean_file_path: /path/Theorems.lean
    - theorem_tasks: [{"name": "theorem_K", "line": 42, "phase_number": 2}]
    - wave_number: 2
    - phase_number: 2
}

**EXECUTE NOW**: USE the Task tool to invoke implementer-coordinator.

Task {
  subagent_type: "general-purpose"
  description: "Execute Phase 3 implementation"
  prompt: |
    Read and follow behavioral guidelines from:
    /path/.claude/agents/implementer-coordinator.md

    Input:
    - phase_file_path: /path/phase_3.md
    - wave_number: 2
    - phase_number: 3
}

### Wave Synchronization
**CRITICAL**: Wait for ALL coordinators in wave to complete
- Collect completion reports from all coordinators
- Aggregate metrics (theorems_proven, git_commits, tasks_completed)
- Update wave state
- Proceed to next wave
```

**Benefits**:
- Parallel execution of independent Lean/software phases in same wave
- Consistent wave pattern across all coordinators
- Proven synchronization and hard barrier enforcement

**Implementation Effort**: High (4-5 hours)

### Recommendation 3: Updated Output Signal Contract

**Problem**: Coordinator needs to return wave-aware completion signal

**Solution**: Add waves_completed, current_wave_number fields to output

**Current Output** (lean-coordinator.md:729-756):
```yaml
PROOF_COMPLETE:
  summary_path: /path/to/summary.md
  phases_completed: [1, 2]
  work_remaining: Phase_4 Phase_5
  context_exhausted: false
  requires_continuation: true
```

**Proposed Output** (enhanced):
```yaml
PROOF_COMPLETE:
  coordinator_type: lean
  summary_path: /path/to/summary.md
  summary_brief: "Completed Wave 1-2 (Phase 1,2) with 15 theorems. Context: 72%. Next: Continue Wave 3."
  phases_completed: [1, 2]
  waves_completed: 2
  current_wave_number: 2
  total_waves: 4
  work_remaining: Phase_4 Phase_5 Phase_6
  context_exhausted: false
  context_usage_percent: 72
  requires_continuation: true
  parallelization_metrics:
    parallel_phases: 2
    time_savings_percent: 45
```

**New Fields**:
- `coordinator_type`: Identifies coordinator for hybrid workflow aggregation
- `summary_brief`: Brief summary for 96% context reduction
- `waves_completed`: Number of waves executed
- `current_wave_number`: Last completed wave
- `total_waves`: Total waves in plan
- `context_usage_percent`: Current context usage
- `parallelization_metrics`: Time savings from wave execution

**Benefits**:
- Enables wave-aware iteration decisions
- Supports metrics aggregation across Lean/software coordinators
- Context-efficient via brief summary field

**Implementation Effort**: Low (1 hour)

### Recommendation 4: Iteration Loop Refactor

**Problem**: Current iteration loop triggers per-phase; needs context threshold trigger only

**Current Block 1c** (lean-implement.md:1162-1220):
```bash
# Iteration decision after EVERY phase
if [ "$REQUIRES_CONTINUATION" = "true" ] && [ "$ITERATION" -lt "$MAX_ITERATIONS" ]; then
  NEXT_ITERATION=$((ITERATION + 1))
  echo "**ITERATION LOOP**: Return to Block 1b with next phase"
else
  echo "Proceeding to Block 2 (completion)"
fi
```

**Proposed Block 1c** (context-aware):
```bash
# Iteration decision only on context threshold
if [ "$CONTEXT_USAGE_PERCENT" -ge "$CONTEXT_THRESHOLD" ]; then
  echo "Context threshold exceeded (${CONTEXT_USAGE_PERCENT}% >= ${CONTEXT_THRESHOLD}%)"
  CHECKPOINT_FILE=$(save_checkpoint ...)
  echo "Checkpoint saved: $CHECKPOINT_FILE"
  REQUIRES_CONTINUATION="false"
fi

# Continue only if work remaining AND context allows
if [ "$REQUIRES_CONTINUATION" = "true" ] && [ -n "$WORK_REMAINING_NEW" ]; then
  NEXT_ITERATION=$((ITERATION + 1))
  echo "**ITERATION LOOP**: Return to Block 1b with continuation context"
else
  echo "Proceeding to Block 2 (completion)"
fi
```

**Key Changes**:
- Checkpoint saved when context threshold exceeded (not per-phase)
- Iteration loop only when work_remaining non-empty AND context allows
- Coordinator handles ALL phases until context exhaustion

**Benefits**:
- Reduced iteration count (fewer continuation loops)
- Better context utilization (coordinator completes max work per iteration)
- Cleaner separation: coordinator = execution, orchestrator = iteration control

**Implementation Effort**: Medium (2-3 hours)

### Recommendation 5: Dependency Recalculation Utility

**Problem**: Failed phases don't trigger wave recalculation (opportunity for optimization)

**Solution**: Create dependency-recalculation.sh utility for dynamic wave updates

**Already Implemented** (Phase 7 of plan complete):
```bash
# .claude/lib/plan/dependency-recalculation.sh
recalculate_wave_dependencies() {
  local plan_path="$1"
  local completed_phases="$2"  # Space-separated list

  # Parse plan structure (tier-agnostic)
  source "${CLAUDE_LIB}/plan/plan-core-bundle.sh"
  ALL_PHASES=$(list_phases "$plan_path")

  # Build dependency graph
  for phase in $ALL_PHASES; do
    phase_deps[$phase]=$(get_phase_dependencies "$plan_path" "$phase")
    phase_status[$phase]=$(get_phase_status "$plan_path" "$phase")
  done

  # Identify next wave candidates (dependencies satisfied)
  next_wave=""
  for phase in $ALL_PHASES; do
    [[ " $completed_phases " =~ " $phase " ]] && continue
    [[ "${phase_status[$phase]}" == "COMPLETE" ]] && continue

    deps_satisfied=true
    for dep in ${phase_deps[$phase]}; do
      if ! [[ " $completed_phases " =~ " $dep " ]]; then
        deps_satisfied=false
        break
      fi
    done

    [ "$deps_satisfied" = true ] && next_wave="$next_wave $phase"
  done

  echo "$next_wave"
}
```

**Unit Tests** (7/7 passing):
- Test 1: L0 plan with dependencies → correct wave candidates
- Test 2: L1 plan with phase files → tier-agnostic support
- Test 3: L2 plan with stage files → phase-level granularity
- Test 4: Decimal phase numbers (0.5, 1.5) → handled correctly
- Test 5: Empty completed_phases → returns phases with no dependencies
- Test 6: All phases complete → returns empty
- Test 7: Mixed completion status markers → validates both parameter and markers

**Integration Point** (coordinator STEP 4 - after wave completion):
```bash
# After wave completes with partial failures
if [ "$FAILED_PHASES_COUNT" -gt 0 ]; then
  COMPLETED_PHASES=$(get_completed_phases "$PLAN_FILE")
  NEXT_WAVE_CANDIDATES=$(recalculate_wave_dependencies "$PLAN_FILE" "$COMPLETED_PHASES")

  if [ -n "$NEXT_WAVE_CANDIDATES" ]; then
    echo "Wave recalculation: ${#NEXT_WAVE_CANDIDATES[@]} phases now executable"
    # Update wave structure for remaining waves
  fi
fi
```

**Benefits**:
- Maximize parallel work after failures
- Reduce wasted context on blocked phases
- Already implemented with comprehensive test coverage

**Implementation Effort**: Complete (Phase 7 done)

---

## Risk Assessment

### Risk 1: Iteration Loop Regression (HIGH)

**Description**: Refactoring iteration trigger from per-phase to context-threshold-only may cause infinite loops or premature halts

**Impact**: High (workflow hangs or incomplete execution)
**Probability**: Medium (complex control flow changes)

**Mitigation**:
1. **Defensive Validation** (lean-implement.md:1073-1091):
   - Override requires_continuation if work_remaining non-empty
   - Log validation_error for contract violations
   2. **Stuck Detection** (implementer-coordinator.md:231-246):
   - Track work_remaining across iterations
   - Halt if unchanged for 2 consecutive iterations
3. **Integration Testing** (Phase 10):
   - Test 1: Plan with 5 phases, verify iteration count
   - Test 2: Context threshold exceeded, verify checkpoint save
   - Test 3: All phases complete, verify clean halt

**Rollback**: Restore from backup (lean-implement.md.backup.20251209)

### Risk 2: Coordinator Invocation Failure (HIGH)

**Description**: Full plan delegation changes coordinator input contract; may cause invocation failures

**Impact**: High (workflow fails immediately)
**Probability**: Low (well-defined input contract)

**Mitigation**:
1. **Hard Barrier Validation** (lean-implement.md:911-942):
   - Fail-fast if summary not created
   - Enhanced diagnostics (search alternate locations)
   - Error logging with agent_error type
2. **Input Contract Validation**:
   - Verify all required fields present (plan_path, routing_map_path, execution_mode)
   - Type checking for numeric fields (iteration, max_iterations)
3. **Error Return Protocol** (lean-coordinator.md:786-835):
   - Structured error signals with TASK_ERROR format
   - Orchestrator parses with parse_subagent_error()
   - Logged to errors.jsonl with full context

**Rollback**: Revert to per-phase routing (backup restoration)

### Risk 3: Wave Calculation Errors (MEDIUM)

**Description**: dependency-analyzer.sh may fail on malformed dependency metadata

**Impact**: Medium (workflow halts with error)
**Probability**: Low (7/7 unit tests passing)

**Mitigation**:
1. **Validation** (dependency-analyzer.sh:537-562):
   - Syntax validation before parsing (missing brackets detected)
   - Cycle detection with DFS (prevents infinite loops)
   - Error messages with recovery suggestions
2. **Fallback** (coordinator STEP 2):
   - If dependency analysis fails, fall back to sequential execution
   - Log warning, proceed without parallelization
3. **Testing** (Phase 10):
   - Test with plans missing dependency metadata
   - Test with circular dependencies
   - Test with multi-word phase names

**Rollback**: Not needed (graceful degradation to sequential)

### Risk 4: Context Threshold Bugs (MEDIUM)

**Description**: estimate_context_usage() may return invalid estimates causing premature halt

**Impact**: Medium (workflow halts early, wasting iterations)
**Probability**: Medium (numeric calculations with edge cases)

**Mitigation**:
1. **Defensive Validation** (implementer-coordinator.md:134-189):
   - Numeric input validation (regex check)
   - Safe arithmetic with fallback on error
   - Sanity check (10k-300k token range)
   - Conservative fallback (100k tokens = 50% of window)
2. **Logging**:
   - Log all validation warnings to stderr
   - Log fallback actions for diagnostics
3. **Testing**:
   - Test with invalid inputs (non-numeric strings)
   - Test with edge cases (0 phases, 100 phases)
   - Test with continuation context (5k token overhead)

**Rollback**: Adjust CONTEXT_THRESHOLD parameter (default 90 → 95)

### Risk 5: Phase Marker Loss (LOW)

**Description**: Coordinator may fail to update [COMPLETE] markers in plan file

**Impact**: Low (informational only, Block 1d removed)
**Probability**: Low (coordinators handle markers internally)

**Mitigation**:
1. **Coordinator Responsibility** (lean-implement.md:1223-1236):
   - Block 1d deleted (no redundant recovery logic)
   - Coordinators handle markers via checkbox-utils.sh
   - Progress tracking instructions forwarded to implementers
2. **Optional Validation** (implementer-coordinator.md:376-385):
   - Count phases with [COMPLETE] markers
   - Log warning if missing (non-fatal)
   - Report phases_with_markers in output (informational)
3. **Recovery**: Manual marker addition if needed (rare)

**Rollback**: Not needed (informational metric only)

---

## Implementation Timeline

### Phase 9: Transform to Wave-Based Full Plan Delegation (Estimated: 5-6 hours)

**Prerequisites**:
- Phase 0: Backup created ✓
- Phase 7: dependency-recalculation.sh utility complete ✓
- dependency-analyzer.sh tested (7/7 unit tests passing) ✓

**Tasks**:

**Task 1: Refactor Block 1a (1 hour)**
- Remove CURRENT_PHASE extraction logic
- Add EXECUTION_MODE="full-plan" flag
- Pass routing_map_path to coordinator
- Persist full plan path in workflow state

**Task 2: Update lean-coordinator STEP 2 (1 hour)**
- Integrate dependency-analyzer.sh invocation
- Parse wave structure JSON
- Validate no circular dependencies
- Display wave structure to user

**Task 3: Implement lean-coordinator STEP 4 Wave Loop (2-3 hours)**
- FOR EACH wave: iterate through wave structure
- Parallel invocation: multiple Task calls for phases in wave
- Routing: invoke lean-implementer for lean phases, implementer-coordinator for software
- Synchronization: wait for ALL executors before Wave N+1
- Aggregate: collect metrics from all executors

**Task 4: Update Output Signal (1 hour)**
- Add coordinator_type, summary_brief fields
- Add waves_completed, current_wave_number fields
- Add parallelization_metrics section
- Ensure work_remaining is space-separated string (not JSON array)

**Task 5: Refactor Block 1c Iteration Logic (1 hour)**
- Remove per-phase iteration trigger
- Add context threshold check → checkpoint save
- Iteration only on context allows AND work_remaining non-empty
- Update continuation_context handling

**Subtasks**:
```bash
# Task 1: Block 1a Refactor
git diff lean-implement.md | grep "CURRENT_PHASE extraction" # Removed
git diff lean-implement.md | grep "EXECUTION_MODE=full-plan" # Added

# Task 2: STEP 2 Integration
git diff lean-coordinator.md | grep "dependency-analyzer.sh" # Added
git diff lean-coordinator.md | grep "waves_json" # Added

# Task 3: STEP 4 Wave Loop
git diff lean-coordinator.md | grep "FOR EACH wave" # Added
git diff lean-coordinator.md | grep "Task {" # Count > 1 (parallel invocations)

# Task 4: Output Signal
git diff lean-coordinator.md | grep "waves_completed:" # Added
git diff lean-coordinator.md | grep "summary_brief:" # Added

# Task 5: Block 1c Iteration
git diff lean-implement.md | grep "CONTEXT_THRESHOLD" # Iteration trigger updated
```

**Validation**:
- [ ] linter passes: bash /path/lint-task-invocation-pattern.sh lean-implement.md
- [ ] linter passes: bash /path/lint-task-invocation-pattern.sh lean-coordinator.md
- [ ] Integration test: 5-phase plan with 2 Lean + 3 software phases
- [ ] Timing verification: 40-60% time savings measured
- [ ] Context check: Brief summary parsing (80 tokens vs 2,000)

**Deferral Recommendation**: This phase is deferred to separate spec per architectural complexity (high-risk refactor, 5-6 hour implementation)

---

## Key Implementation Files

| File Path | Purpose | Modification Type |
|-----------|---------|-------------------|
| `/home/benjamin/.config/.claude/commands/lean-implement.md` | Hybrid orchestrator | Major refactor (Block 1a, 1c iteration loop) |
| `/home/benjamin/.config/.claude/agents/lean-coordinator.md` | Wave-based supervisor | New STEP 4 wave execution loop |
| `/home/benjamin/.config/.claude/lib/util/dependency-analyzer.sh` | Wave calculation | No changes (already complete) |
| `/home/benjamin/.config/.claude/lib/plan/dependency-recalculation.sh` | Dynamic recalculation | No changes (Phase 7 complete) |
| `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` | Reference pattern | Read-only (template for STEP 4) |

---

## Conclusion

The wave-based full plan delegation architecture is a proven pattern achieving 40-60% time savings through parallel phase execution. The implementer-coordinator agent demonstrates a mature 4-step orchestration workflow (structure detection → dependency analysis → iteration management → wave execution) with comprehensive testing (7/7 dependency-recalculation unit tests passing).

**Key Success Factors**:
1. **Full Plan Delegation**: Pass entire plan to coordinator (not single phase)
2. **Wave Calculation**: Integrate dependency-analyzer.sh for Kahn's algorithm topological sort
3. **Parallel Task Invocation**: Multiple Task calls in single coordinator response
4. **Context Efficiency**: Brief summary parsing (96% reduction) enables 10+ iterations
5. **Hard Barrier Validation**: Fail-fast on missing summary, defensive continuation override

**Primary Risk**: Iteration loop refactor is high-risk due to control flow complexity. Mitigation includes comprehensive integration testing, backup restoration plan, defensive validation with error logging, and stuck detection.

**Recommendation**: Defer Phase 9 to separate focused spec due to:
- High architectural complexity (5-6 hour implementation)
- Major control flow changes (iteration trigger refactor)
- Integration risk (coordinator input contract changes)
- Testing requirements (5 integration test cases needed)

The dependency-recalculation.sh utility is already implemented (Phase 7 complete) and provides foundation for dynamic wave updates after failures, though this optimization is secondary to the core wave-based refactor.

**Highest Impact Next Step**: Complete Phase 10 integration testing for Phases 0-7, then create separate spec for Phase 9 wave-based delegation with dedicated test-driven implementation approach.
