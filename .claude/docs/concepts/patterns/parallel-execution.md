# Parallel Execution Pattern

**Path**: docs → concepts → patterns → parallel-execution.md

[Used by: /orchestrate, /implement, multi-agent workflows with independent tasks]

Wave-based and concurrent agent execution achieves 40-60% time savings through parallel processing of independent tasks.

## Definition

Parallel Execution is a pattern where independent tasks execute concurrently using wave-based scheduling, phase dependency analysis, and parallel agent invocation. This transforms sequential workflows (task 1 → task 2 → task 3) into parallel workflows (tasks 1,2,3 execute simultaneously), reducing total execution time by 40-60%.

Key concepts:
- **Wave**: Group of tasks that can execute in parallel (no dependencies between tasks in same wave)
- **Phase Dependencies**: Explicit declaration of which phases depend on which other phases
- **Topological Sort**: Kahn's algorithm for wave scheduling from dependency graph

## Rationale

### Why This Pattern Matters

Sequential execution wastes time when tasks are independent:
- 4 research topics sequentially: 40 minutes (4 × 10 min each)
- 4 research topics in parallel: 10 minutes (max of all parallel tasks)
- Time savings: 75% (30 minutes saved)

Without parallel execution:
- Multi-agent workflows bottlenecked by sequential invocation
- Total workflow time = sum of all task durations
- Coordination overhead (waiting for previous task to complete)

## Implementation

### Technique 1: Phase Dependency Syntax

Declare dependencies in plan metadata:

```markdown
## Phase Metadata - Dependencies

### Phase 1: Research (Wave 1 - No dependencies)
Dependencies: none
Can execute: immediately (Wave 1)

### Phase 2: Planning (Wave 2)
Dependencies: Phase 1
Can execute: after Wave 1 completes

### Phase 3: Frontend Implementation (Wave 3)
Dependencies: Phase 2
Can execute: after Wave 2 completes

### Phase 4: Backend Implementation (Wave 3)
Dependencies: Phase 2
Can execute: after Wave 2 completes (parallel with Phase 3)

### Phase 5: Integration Testing (Wave 4)
Dependencies: Phase 3, Phase 4
Can execute: after both Phase 3 AND Phase 4 complete

Waves:
- Wave 1: [Phase 1]
- Wave 2: [Phase 2]
- Wave 3: [Phase 3, Phase 4] <- parallel execution
- Wave 4: [Phase 5]
```

### Technique 2: Dependency Graph Parsing

Use Kahn's algorithm for topological sort:

```bash
# .claude/lib/parallel-execution.sh

parse_phase_dependencies() {
  local plan_file="$1"

  # Extract dependency declarations
  # Format: "Dependencies: Phase 1, Phase 3"

  # Build adjacency list
  # Phase 2 -> [Phase 1]
  # Phase 5 -> [Phase 3, Phase 4]

  # Calculate in-degree for each phase
  # Phase 1: 0 (no dependencies)
  # Phase 2: 1 (depends on Phase 1)
  # Phase 5: 2 (depends on Phase 3, Phase 4)

  # Kahn's algorithm:
  # Wave 1 = all phases with in-degree 0
  # Execute Wave 1, remove from graph
  # Recalculate in-degrees
  # Wave 2 = phases now with in-degree 0
  # Repeat until all phases scheduled
}

execute_waves() {
  local waves_file="$1"

  # For each wave:
  #   Invoke all phases in wave concurrently (Task tool parallel invocations)
  #   Wait for all phases in wave to complete
  #   Proceed to next wave
}
```

### Technique 3: Concurrent Agent Invocation

Invoke multiple agents simultaneously:

```markdown
## Wave Execution - Parallel Agent Invocation

WAVE 1: Research Phase (4 parallel agents)

INVOKE ALL AGENTS CONCURRENTLY (do not wait between invocations):

Agent 1:
Task tool: {
  "agent": "research-specialist",
  "task": "Research OAuth patterns",
  ...
}

Agent 2 (invoke immediately, do not wait for Agent 1):
Task tool: {
  "agent": "research-specialist",
  "task": "Research security best practices",
  ...
}

Agent 3 (invoke immediately):
Task tool: { ... }

Agent 4 (invoke immediately):
Task tool: { ... }

ALL 4 AGENTS NOW EXECUTING IN PARALLEL.

WAIT for all 4 agents to complete before proceeding to Wave 2.

Time: 10 minutes (max of all 4 parallel tasks)
vs 40 minutes sequential (4 × 10 min each)
Savings: 75% (30 minutes saved)
```

### Code Example

Real implementation from Plan 080 - /orchestrate with wave-based implementation:

```markdown
## Phase 3: Implementation (Wave-Based Execution)

DEPENDENCY ANALYSIS:

Plan phases with dependencies:
- Phase 1 (Database schema): No dependencies -> Wave 1
- Phase 2 (Auth module): Depends on Phase 1 -> Wave 2
- Phase 3 (API routes): Depends on Phase 2 -> Wave 3
- Phase 4 (Frontend UI): Depends on Phase 2 -> Wave 3 (parallel with Phase 3)
- Phase 5 (Integration): Depends on Phase 3, Phase 4 -> Wave 4

Dependency graph:
Phase 1
  ↓
Phase 2
  ├→ Phase 3 ─┐
  └→ Phase 4 ─┘
       ↓
    Phase 5

Waves:
- Wave 1: [Phase 1] (1 phase)
- Wave 2: [Phase 2] (1 phase)
- Wave 3: [Phase 3, Phase 4] (2 phases in parallel)
- Wave 4: [Phase 5] (1 phase)

EXECUTE WAVE 1:
Task tool: {"agent": "implementer", "phase": 1, ...}
Wait for completion.

EXECUTE WAVE 2:
Task tool: {"agent": "implementer", "phase": 2, ...}
Wait for completion.

EXECUTE WAVE 3 (PARALLEL):
Task tool (Phase 3): {"agent": "implementer", "phase": 3, "task": "API routes", ...}
Task tool (Phase 4): {"agent": "implementer", "phase": 4, "task": "Frontend UI", ...}
# Do NOT wait between invocations - both execute concurrently
Wait for BOTH Phase 3 AND Phase 4 to complete.

EXECUTE WAVE 4:
Task tool: {"agent": "implementer", "phase": 5, ...}
Wait for completion.

TIME ANALYSIS:
Sequential: Phase 1 (2h) + Phase 2 (3h) + Phase 3 (4h) + Phase 4 (5h) + Phase 5 (2h) = 16 hours
Wave-based: Wave 1 (2h) + Wave 2 (3h) + Wave 3 (max(4h, 5h) = 5h) + Wave 4 (2h) = 12 hours
Time savings: 25% (4 hours saved)
```

## Anti-Patterns

### Violation 1: Sequential Execution of Independent Tasks

```markdown
❌ BAD - Sequential invocation when parallel possible:

Phase 3: API implementation
invoke implementer for API routes
wait for completion

Phase 4: Frontend implementation
invoke implementer for Frontend UI
wait for completion

[Phases 3 and 4 are independent but executed sequentially]
Time: 4h + 5h = 9 hours
vs Parallel: max(4h, 5h) = 5 hours
Wasted: 4 hours (44%)
```

### Violation 2: Ignoring Dependencies

```markdown
❌ BAD - Parallel execution with unresolved dependencies:

Wave 1: [Phase 1, Phase 2, Phase 3] all in parallel
But Phase 2 depends on Phase 1
But Phase 3 depends on Phase 2

Result: Phase 2 fails (Phase 1 not complete)
        Phase 3 fails (Phase 2 not complete)
        Must re-execute in correct order
```

### Violation 3: Waiting Between Concurrent Invocations

```markdown
❌ BAD - Serial invocation of parallel tasks:

Agent 1: invoke research-specialist
wait for Agent 1 to complete  # ← Wrong! Don't wait
Agent 2: invoke research-specialist
wait for Agent 2 to complete  # ← Wrong! Don't wait
...

This is sequential execution disguised as parallel.
Must invoke all agents first, then wait for all.
```

## Performance Impact

**Time Savings (Real Metrics):**

| Workflow | Sequential | Wave-Based | Savings |
|----------|-----------|------------|---------|
| 4-agent research | 40 min (4×10min) | 10 min (max) | 75% |
| 5-phase implementation | 16 hours | 12 hours | 25% |
| /orchestrate (7 phases) | 8 hours | 4.8 hours | 40% |
| Complex workflow (15 phases, 6 waves) | 30 hours | 12 hours | 60% |

**Scalability:**
- More independent tasks → greater savings
- Ideal ratio: 2-4 tasks per wave (diminishing returns beyond 4)
- Maximum savings: ~75% (when most tasks are independent)

**Real-World Example (Plan 080):**
```
/orchestrate workflow:
- Phase 1: Research (4 parallel agents) - 10 min vs 40 min sequential
- Phase 2: Planning (1 agent) - 15 min
- Phase 3: Implementation (wave-based, 3 waves) - 12h vs 16h sequential
- Phases 4-7: Mixed parallel/sequential - 2h vs 3h

Total: 14.6 hours vs 21 hours sequential
Savings: 30% (6.4 hours saved)
```

## Related Patterns

- [Hierarchical Supervision](./hierarchical-supervision.md) - Sub-supervisors execute in parallel
- [Metadata Extraction](./metadata-extraction.md) - Enables parallel coordination at scale
- [Behavioral Injection](./behavioral-injection.md) - Injects independent contexts for parallel agents
- [Context Management](./context-management.md) - Manages parallel agent results efficiently

## See Also

- [Orchestration Guide](../../workflows/orchestration-guide.md) - Wave-based workflow patterns
- [Performance Measurement Guide](../../guides/patterns/performance-optimization.md) - Measuring time savings
- `.claude/docs/reference/workflows/phase-dependencies.md` - Dependency syntax reference
- `.claude/lib/parallel-execution.sh` - Wave scheduling utilities
