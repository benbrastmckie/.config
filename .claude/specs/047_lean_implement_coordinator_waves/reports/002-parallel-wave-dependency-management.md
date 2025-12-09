# Parallel Wave Orchestration and Dependency Resolution Analysis

**Date**: 2025-12-09
**Research Focus**: Wave-based execution patterns, dependency calculation, parallel implementer invocation
**Status**: Research Complete

---

## Executive Summary

This research analyzes the existing wave-based implementation orchestration patterns in the codebase, focusing on dependency resolution, parallel Task invocation, and wave recalculation mechanisms. The implementer-coordinator agent demonstrates a mature wave-based architecture achieving 40-60% time savings through parallel phase execution.

**Key Findings**:
1. **Dependency Analysis Infrastructure**: The dependency-analyzer.sh utility provides robust dependency parsing, topological sorting (Kahn's algorithm), and wave identification
2. **Wave-Based Orchestration Pattern**: implementer-coordinator implements STEP 4 wave execution loop with parallel Task invocations per wave
3. **Hard Barrier Pattern**: Wave synchronization enforces dependency correctness with mandatory completion verification before Wave N+1 execution
4. **Recalculation Opportunities**: Current implementation has no dynamic wave recalculation after failures - all waves calculated upfront in STEP 2
5. **Context Efficiency**: Brief summary pattern (96% reduction) enables 10+ iteration capacity vs 3-4 iterations before optimization

**Architecture Gap**: The `/lean-implement` command currently lacks wave-based orchestration entirely - it routes phases sequentially via implementer-coordinator without leveraging dependency metadata for parallel execution. This represents a significant optimization opportunity.

---

## Findings

### 1. Dependency Specification in Plans

Plans use frontmatter-style dependency metadata at the phase level:

**Format** (from dependency-analyzer.sh analysis):
```markdown
### Phase 2: Backend Implementation [NOT STARTED]

**Dependencies**: depends_on: [phase_1]
**Blocks**: blocks: [phase_4, phase_5]

Tasks:
- [ ] Implement authentication module
- [ ] Create database schema
```

**Dependency Metadata Fields**:
- `depends_on: [phase_1, phase_2]` - This phase requires listed phases to complete first
- `blocks: [phase_4, phase_5]` - This phase blocks listed phases from starting until complete

**Multi-Word Phase Names Supported**:
- Format: `depends_on: [Setup Infrastructure, Create Database]`
- Parser handles spaces, commas, and normalization (dependency-analyzer.sh:88-92)

**Three Structure Levels** (dependency-analyzer.sh:29-58):
- **Level 0**: Inline plan (all phases in single file)
- **Level 1**: Phase files (plan_dir/phase_N.md)
- **Level 2**: Stage files (plan_dir/phase_N/stage_M.md)

For Level 2 (deepest), analyzer processes phase-level dependencies only - stages within a phase are sequential.

### 2. Wave Calculation from Dependency Information

**Algorithm**: Topological Sort (Kahn's Algorithm)

**Implementation** (dependency-analyzer.sh:296-392):
```bash
identify_waves() {
  local dependency_graph="$1"

  # Build in-degree map (count incoming edges per node)
  declare -A in_degree
  for phase in $all_phases; do
    in_degree[$phase]=0
  done

  # Count incoming edges from dependency graph
  while IFS= read -r edge; do
    local to_phase=$(echo "$edge" | jq -r '.to')
    ((in_degree[$to_phase]++))
  done < <(echo "$dependency_graph" | jq -c '.edges[]')

  # Wave identification loop
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

    # Create wave object with can_parallel flag
    wave=$(jq -n \
      --argjson wave_num "$wave_number" \
      --argjson phases "$wave_phases_json" \
      '{wave_number: $wave_num, phases: $phases, can_parallel: ($phases | length > 1)}')

    # Reduce in-degree for dependent phases
    for wave_phase in "${wave_phases[@]}"; do
      # For each edge FROM this phase, decrement TO phase in-degree
      ((in_degree[$to_phase]--))
    done

    ((wave_number++))
  done
}
```

**Wave Structure Output** (JSON):
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
    },
    {
      "wave_number": 3,
      "phases": ["phase_4", "phase_5"],
      "can_parallel": true
    }
  ],
  "metrics": {
    "total_phases": 5,
    "parallel_phases": 4,
    "sequential_estimated_time": "15 hours",
    "parallel_estimated_time": "9 hours",
    "time_savings_percentage": "40%"
  }
}
```

**Cycle Detection**: DFS-based cycle detection (dependency-analyzer.sh:401-474) runs before wave identification to ensure acyclic graph.

### 3. Current Parallel Implementer Invocation Pattern

**Implementer-Coordinator Agent** (implementer-coordinator.md:248-330):

```markdown
## STEP 4: Wave Execution Loop

FOR EACH wave in wave structure:

### Parallel Executor Invocation

For each phase in wave, invoke implementation-executor subagent via Task tool.

**CRITICAL**: Use Task tool with multiple invocations in single response for parallel execution.

Example for Wave 2 with 2 phases:

I'm now invoking implementation-executor for Phase 2 and Phase 3 in parallel (Wave 2).

**EXECUTE NOW**: USE the Task tool to invoke the implementation-executor.

Task {
  subagent_type: "general-purpose"
  description: "Execute Phase 2 implementation"
  prompt: |
    Read and follow behavioral guidelines from:
    /path/.claude/agents/implementation-executor.md

    You are executing Phase 2: Backend Implementation

    Input:
    - phase_file_path: /path/to/phase_2_backend.md
    - topic_path: /path/to/specs/027_auth
    - wave_number: 2
    - phase_number: 2
    - continuation_context: $CONTINUATION_CONTEXT
}

**EXECUTE NOW**: USE the Task tool to invoke the implementation-executor.

Task {
  subagent_type: "general-purpose"
  description: "Execute Phase 3 implementation"
  prompt: |
    Read and follow behavioral guidelines from:
    /path/.claude/agents/implementation-executor.md

    You are executing Phase 3: Frontend Implementation

    Input:
    - phase_file_path: /path/to/phase_3_frontend.md
    - wave_number: 2
    - phase_number: 3
}
```

**Key Pattern**: Multiple Task invocations in SINGLE response message → Claude executes in parallel

### 4. Wave Synchronization and Hard Barrier

**Wave Synchronization** (implementer-coordinator.md:388-394):
```markdown
**CRITICAL**: Wait for ALL executors in wave to complete before proceeding to next wave.

- All executors MUST report completion (success or failure)
- Aggregate results from all executors
- Update implementation state with wave results
- Proceed to next wave only after synchronization
```

**Hard Barrier Validation** (hierarchical-agents-examples.md:410-481):
```bash
## Block 4c: Verify

# Fail-fast if directory missing
if [[ ! -d "$RESEARCH_DIR" ]]; then
  log_command_error "verification_error" \
    "Research directory not found: $RESEARCH_DIR"
  exit 1
fi

# Fail-fast if no reports created
REPORT_COUNT=$(find "$RESEARCH_DIR" -name "*.md" -type f | wc -l)
if [[ "$REPORT_COUNT" -eq 0 ]]; then
  log_command_error "verification_error" \
    "No research reports found in $RESEARCH_DIR"
  exit 1
fi
```

**Wave Execution Cannot Skip Dependencies**: Kahn's algorithm guarantees phases in Wave N+1 only execute after ALL phases in Wave N complete.

### 5. Existing Wave Orchestration Commands

**Current Implementation**: `/implement` command

**Architecture** (from implement.md and implementer-coordinator.md):
```
/implement (orchestrator)
    |
    +-- Block 1b: Route to Coordinator [HARD BARRIER]
            +-- implementer-coordinator (supervisor)
                    |
                    +-- STEP 2: Dependency Analysis
                    |       +-- invoke dependency-analyzer.sh
                    |       +-- parse wave structure JSON
                    |
                    +-- STEP 4: Wave Execution Loop
                            +-- Wave 1: [implementation-executor 1]
                            +-- Wave 2: [implementation-executor 2, 3] (PARALLEL)
                            +-- Wave 3: [implementation-executor 4, 5] (PARALLEL)
```

**Key Flow**:
1. `/implement` orchestrator pre-calculates artifact paths (Block 1a)
2. Orchestrator invokes implementer-coordinator via Task tool (Block 1b - hard barrier)
3. implementer-coordinator invokes dependency-analyzer.sh utility to build wave structure
4. implementer-coordinator executes wave loop with parallel Task invocations per wave
5. Orchestrator validates summary exists, parses brief summary fields (Block 1c - 96% context reduction)

**Performance Metrics** (hierarchical-agents-examples.md:1110-1122):
- Context reduction: 96% (2,000 → 80 tokens via brief summary parsing)
- Time savings: 40-60% for plans with 2+ parallel phases
- Iteration capacity: 10+ iterations possible (vs 3-4 before optimization)

### 6. Recalculation Mechanism

**Current State**: NO dynamic wave recalculation after failures

**Upfront Calculation Pattern** (implementer-coordinator.md:86-126):
```markdown
## STEP 2: Dependency Analysis

1. **Invoke dependency-analyzer Utility**:
   bash /path/.claude/lib/util/dependency-analyzer.sh "$plan_path" > dependency_analysis.json

2. **Parse Analysis Results**:
   - Extract dependency graph (nodes, edges)
   - Extract wave structure (wave_number, phases per wave)
   - Extract parallelization metrics (time savings estimate)
```

**One-Time Calculation**: Waves calculated ONCE in STEP 2, then used throughout STEP 4 execution. No recalculation logic exists.

**Failure Handling** (implementer-coordinator.md:396-428):
```markdown
### Failure Handling

If any executor fails:

1. **Mark Phase as Failed** in state
2. **Check Dependency Impact**:
   - If failed phase blocks future phases: Mark dependent phases as blocked
   - If failed phase is independent: Continue with Wave N+1
3. **Continue with Independent Phases**
4. **Report Failure** to orchestrator
```

**Implication**: Failed phases are NOT removed from wave structure. Dependent phases are marked "blocked" but waves are not recalculated to identify newly independent work.

**Recalculation Opportunity**: After a phase failure in Wave N, recalculate waves for remaining phases to identify if any blocked phases became independent (e.g., if Phase 2 fails but Phase 3 only depended on Phase 1, Phase 3 could move to earlier wave).

### 7. Lean-Implement Architecture Gap

**Current `/lean-implement` Flow** (lean-implement.md:619-843):
```markdown
## Block 1b: Route to Coordinator [HARD BARRIER]

# Determine coordinator based on phase type
if [ "$PHASE_TYPE" = "lean" ]; then
  COORDINATOR_NAME="lean-coordinator"
else
  COORDINATOR_NAME="implementer-coordinator"
fi

# Invoke coordinator for SINGLE phase
Task {
  subagent_type: "general-purpose"
  description: "Wave-based Lean theorem proving for phase ${CURRENT_PHASE}"
  prompt: |
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-coordinator.md

    Input:
    - starting_phase: ${CURRENT_PHASE}
    - max_iterations: ${MAX_ITERATIONS}

    Execute theorem proving for Phase ${CURRENT_PHASE}.
}
```

**Architecture Issue**: `/lean-implement` routes ONE phase at a time to coordinator, then loops back to Block 1c for continuation decision. This is SEQUENTIAL execution - no wave-based parallelism.

**Contrast with `/implement`**:
- `/implement` passes ENTIRE plan to implementer-coordinator
- implementer-coordinator calculates waves and executes parallel phases
- `/lean-implement` passes ONE phase per iteration
- No dependency-based wave calculation
- No parallel phase execution across independent Lean/software phases

**Optimization Opportunity**: Refactor `/lean-implement` to:
1. Pre-calculate ALL phases and dependencies in Block 1a
2. Invoke implementer-coordinator ONCE with full plan (not per-phase)
3. Let implementer-coordinator handle wave calculation and parallel execution
4. Iterate only when context threshold exceeded (not per-phase)

---

## Recommendations

### 1. Wave Recalculation on Failure (High Priority)

**Problem**: Failed phases remain in wave structure, potentially blocking independent work that could proceed.

**Recommendation**: Add STEP 4.5 to implementer-coordinator between waves:

```bash
## STEP 4.5: Dynamic Wave Recalculation (on failure)

if [ "$FAILED_PHASES_COUNT" -gt 0 ]; then
  # Remove failed phases from dependency graph
  UPDATED_GRAPH=$(remove_failed_phases "$DEPENDENCY_GRAPH" "${FAILED_PHASES[@]}")

  # Recalculate waves for remaining phases
  UPDATED_WAVES=$(identify_waves "$UPDATED_GRAPH")

  # Check if previously blocked phases now independent
  UNBLOCKED_PHASES=$(compare_waves "$ORIGINAL_WAVES" "$UPDATED_WAVES")

  if [ -n "$UNBLOCKED_PHASES" ]; then
    echo "Wave recalculation: ${#UNBLOCKED_PHASES[@]} phases unblocked"
    # Continue with updated wave structure
    WAVES="$UPDATED_WAVES"
  fi
fi
```

**Benefits**:
- Maximize parallel work after failures
- Reduce wasted context on blocked phases
- Improve iteration efficiency

**Implementation Effort**: Medium (2-3 hours)
- Add `remove_failed_phases()` function to dependency-analyzer.sh
- Add wave comparison logic to identify unblocked phases
- Integrate into implementer-coordinator STEP 4 loop

### 2. Lean-Implement Wave-Based Refactor (Critical Priority)

**Problem**: `/lean-implement` bypasses wave orchestration, executing phases sequentially.

**Recommendation**: Refactor `/lean-implement` to delegate full plan to implementer-coordinator:

**Current Architecture**:
```
/lean-implement
  |
  +-- Block 1a-classify: Classify phases as lean/software
  +-- Block 1b: Route SINGLE phase to coordinator (sequential)
  +-- Block 1c: Parse summary, check continuation
  +-- LOOP: Return to Block 1b for next phase
```

**Proposed Architecture**:
```
/lean-implement
  |
  +-- Block 1a-classify: Classify phases as lean/software
  +-- Block 1b: Route FULL PLAN to hybrid-implementer-coordinator (wave-based)
  |       +-- hybrid-implementer-coordinator
  |               +-- STEP 2: Calculate waves (dependency-analyzer.sh)
  |               +-- STEP 4: Execute waves with parallel Task invocations
  |                       +-- Wave 1: [lean-coordinator, implementer-coordinator]
  |                       +-- Wave 2: [implementer-coordinator, implementer-coordinator]
  +-- Block 1c: Parse summary, check continuation
  +-- LOOP: Only if context threshold exceeded (not per-phase)
```

**Key Changes**:
1. Create `hybrid-implementer-coordinator.md` agent (extends implementer-coordinator.md)
2. Add phase type routing in STEP 4: invoke `lean-coordinator` for lean phases, `implementer-coordinator` for software phases
3. Remove per-phase iteration loop from `/lean-implement`
4. Add dependency metadata to Lean plans (currently missing)

**Benefits**:
- 40-60% time savings on mixed Lean/software plans with independent phases
- Consistent wave orchestration across all implementation commands
- Reduced iteration count (fewer continuation loops)

**Implementation Effort**: High (8-10 hours)
- Create hybrid coordinator agent (~3 hours)
- Refactor /lean-implement command (~3 hours)
- Add dependency metadata to Lean plan templates (~1 hour)
- Integration testing (~3 hours)

### 3. Add Dependency Metadata to Lean Plans (Medium Priority)

**Problem**: Lean plans generated by lean-plan-architect.md lack `depends_on:` and `blocks:` metadata.

**Recommendation**: Update lean-plan-architect agent to inject dependency metadata based on theorem dependencies.

**Example**:
```markdown
### Phase 1: Prove Axiom K [NOT STARTED]

**Dependencies**: depends_on: []
**Blocks**: blocks: [phase_2, phase_3]

lean_file: /path/Modal.lean
implementer: lean

Tasks:
- [ ] Prove theorem_K using tactic automation
```

**Benefits**:
- Enable wave-based orchestration for Lean plans
- Automatic parallelization of independent theorem proofs
- Better utilization of lean-lsp-mcp parallel proof capabilities

**Implementation Effort**: Medium (3-4 hours)
- Add dependency inference to lean-plan-architect.md
- Update Lean plan templates
- Validation testing on existing Lean plans

### 4. Enhance dependency-analyzer.sh Diagnostics (Low Priority)

**Problem**: Circular dependency errors lack actionable recovery steps.

**Recommendation**: Add detailed cycle path reporting:

```bash
detect_dependency_cycles() {
  # ... existing DFS logic ...

  if dfs_cycle_detect "$phase"; then
    # Reconstruct cycle path for error message
    CYCLE_PATH=$(reconstruct_cycle_path "$phase" "${rec_stack[@]}")

    echo "ERROR: Circular dependency detected" >&2
    echo "  Cycle path: $CYCLE_PATH" >&2
    echo "  Recovery: Remove one dependency in the cycle" >&2
    return 1
  fi
}
```

**Benefits**:
- Faster debugging of dependency errors
- Clearer error messages for users

**Implementation Effort**: Low (1-2 hours)

### 5. Add Wave Visualization to Implementer-Coordinator (Low Priority)

**Problem**: Wave structure output is text-only (implementer-coordinator.md:104-126).

**Recommendation**: Add ASCII diagram generation using Unicode box-drawing:

```
╔═══════════════════════════════════════════════════════╗
║ WAVE-BASED IMPLEMENTATION PLAN                        ║
╠═══════════════════════════════════════════════════════╣
║ Wave 1: Setup (1 phase)                               ║
║ ├─ Phase 1: Project Setup                            ║
╠═══════════════════════════════════════════════════════╣
║ Wave 2: Implementation (2 phases, PARALLEL)           ║
║ ├─ Phase 2: Backend Implementation                    ║
║ └─ Phase 3: Frontend Implementation                   ║
╠═══════════════════════════════════════════════════════╣
║ Wave 3: Integration (2 phases, PARALLEL)              ║
║ ├─ Phase 4: API Integration                          ║
║ └─ Phase 5: Testing                                   ║
╚═══════════════════════════════════════════════════════╝
```

**Benefits**:
- Better user understanding of parallelization strategy
- Easier debugging of wave structure

**Implementation Effort**: Low (1 hour)

---

## Key Implementation Files

| File Path | Purpose | Lines of Interest |
|-----------|---------|-------------------|
| `/home/benjamin/.config/.claude/lib/util/dependency-analyzer.sh` | Dependency parsing, topological sort, wave identification | 296-392 (wave calculation), 401-474 (cycle detection) |
| `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` | Wave-based orchestration supervisor | 248-394 (STEP 4 wave execution), 86-126 (STEP 2 dependency analysis) |
| `/home/benjamin/.config/.claude/commands/lean-implement.md` | Hybrid Lean/software implementation | 619-843 (sequential routing - needs refactor) |
| `/home/benjamin/.config/.claude/commands/implement.md` | Software implementation orchestrator | Block 1b (coordinator delegation pattern) |
| `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-coordination.md` | Wave-based patterns documentation | 13-48 (wave coordination patterns) |
| `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-examples.md` | Example 8 - Lean coordinator optimization | 879-1161 (dual coordinator integration) |

---

## Conclusion

The codebase demonstrates a mature wave-based orchestration architecture with robust dependency resolution via dependency-analyzer.sh and parallel execution via implementer-coordinator. The primary gaps are:

1. **No dynamic wave recalculation** after failures (opportunity for optimization)
2. **Lean-implement bypasses wave orchestration** entirely (critical refactor needed for 40-60% time savings)
3. **Missing dependency metadata in Lean plans** (prerequisite for wave-based Lean orchestration)

The hard barrier pattern and brief summary parsing provide strong foundations for context-efficient multi-iteration workflows. The Kahn's algorithm implementation correctly handles topological sorting with cycle detection. Parallel Task invocation patterns are well-established via implementer-coordinator's STEP 4 wave execution loop.

**Highest Impact Recommendation**: Refactor `/lean-implement` to delegate full plan to hybrid-implementer-coordinator for wave-based parallel execution (estimated 40-60% time savings on mixed plans with independent phases).
