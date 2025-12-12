# Choosing Agent Architecture: Flat vs Hierarchical

**Purpose**: Decision framework for choosing between flat (direct invocation) and hierarchical (coordinator-based) agent architectures in .claude/ workflows.

**Audience**: Command authors, workflow designers, system architects

**Related Documentation**:
- [Hierarchical Agents Overview](../../concepts/hierarchical-agents-overview.md) - Architecture fundamentals
- [Three-Tier Coordination Pattern](../../concepts/three-tier-coordination-pattern.md) - Coordination model details
- [Coordinator Patterns Standard](../../reference/standards/coordinator-patterns-standard.md) - Coordinator implementation patterns

---

## Decision Tree

```
┌─────────────────────────────────────────────────┐
│ How many parallel agents does workflow require? │
└─────────────────┬───────────────────────────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
    1-3 agents          4+ agents
        │                   │
        v                   v
┌──────────────┐    ┌────────────────┐
│ Flat         │    │ Hierarchical   │
│ (Direct)     │    │ (Coordinator)  │
└──────────────┘    └────────────────┘
                            │
                    ┌───────┴───────┐
                    │               │
                    v               v
            Sequential      Parallel with
            dependencies    independence
                    │               │
                    v               v
            ┌──────────────┐ ┌──────────────┐
            │ Implementer- │ │ Research-    │
            │ Coordinator  │ │ Coordinator  │
            │ (wave-based) │ │ (planning)   │
            └──────────────┘ └──────────────┘
```

---

## Architecture Comparison

### Overview

| Aspect | Flat Agent Model | Hierarchical Model |
|--------|------------------|-------------------|
| **Structure** | Command → Specialists directly | Command → Coordinator → Specialists |
| **Agent Count** | 1-3 agents | 4+ agents |
| **Parallelization** | Sequential execution | Parallel execution possible |
| **Context Consumption** | <5,000 tokens/iteration | >10,000 tokens → reduced to <500 |
| **Workflow Phases** | Single phase | Multiple dependent phases |
| **Worker Output Size** | <500 tokens | >1,000 tokens |
| **Context Reduction** | N/A | 95-96% via metadata passing |
| **Time Savings** | Baseline | 40-60% via parallel waves |
| **Iteration Capacity** | 3-4 iterations | 10-20+ iterations |
| **Delegation Enforcement** | Manual (unreliable) | Automatic (hard barriers) |
| **Responsibility Boundaries** | Informal | Formal three-tier model |

### Quantitative Thresholds

Use hierarchical architecture when **any** of these conditions apply:

1. **Agent Count**: Workflow requires 4+ parallel agents performing similar tasks
2. **Context Per Iteration**: Agent outputs total >10,000 tokens per iteration
3. **Worker Output Size**: Individual agent outputs exceed 1,000 tokens
4. **Parallel Opportunities**: 2+ independent tasks can run simultaneously
5. **Workflow Complexity**: Multiple phases with dependencies between them

### Performance Metrics

**Context Reduction** (Hierarchical Advantage):
```
Traditional Approach:
  4 Specialists x 2,500 tokens = 10,000 tokens → orchestrator

Hierarchical Approach:
  4 Specialists x 2,500 tokens → coordinator
  Coordinator extracts 110 tokens/specialist = 440 tokens → orchestrator

Reduction: 95.6%
```

**Time Savings** (Hierarchical Advantage):
```
Sequential Execution:
  Phase 1: 120s
  Phase 2: 120s
  Phase 3: 120s
  Total: 360s

Parallel Wave Execution:
  Wave 1 (Phase 1, 2 parallel): 120s
  Wave 2 (Phase 3): 120s
  Total: 240s

Time Savings: 33%

With 5 phases (2-2-1 waves): 50% time savings
```

**Iteration Capacity** (Hierarchical Advantage):
```
Flat Model:
  10,000 tokens/iteration x 3 iterations = 30,000 tokens consumed
  Context limit reached: 3-4 iterations

Hierarchical Model:
  440 tokens/iteration x 20 iterations = 8,800 tokens consumed
  Context limit reached: 20+ iterations
```

---

## Use Cases and Examples

### When to Use Flat Architecture

**Use Case 1: Single Specialist Workflow**
- **Example**: `/debug` command (simple investigation)
- **Agent Count**: 1 debug specialist
- **Context**: <2,000 tokens
- **Rationale**: No parallelization benefits, minimal context overhead

**Use Case 2: Sequential Two-Agent Workflow**
- **Example**: Research → Plan (2 steps)
- **Agent Count**: 1 research specialist → 1 plan architect
- **Context**: 2,500 + 3,000 = 5,500 tokens
- **Rationale**: Sequential dependency, manageable context

**Use Case 3: Small Parallel Workflow**
- **Example**: 2-3 research topics (low complexity)
- **Agent Count**: 2-3 research specialists
- **Context**: 3 x 2,500 = 7,500 tokens
- **Rationale**: Below 10,000 token threshold, simple aggregation

**Implementation Pattern**:
```markdown
## Block 1: Pre-Calculate Paths
```bash
REPORT_PATH_1="${TOPIC_DIR}/reports/001_topic1.md"
REPORT_PATH_2="${TOPIC_DIR}/reports/002_topic2.md"
```

## Block 2: Invoke Specialists (Parallel)
**EXECUTE NOW**: Invoke research specialists

Task {
  subagent_type: "general-purpose"
  prompt: |
    Read and follow: .claude/agentsresearch-mode-specialist.md
    Topic: Topic 1
    Output: ${REPORT_PATH_1}
}

Task {
  subagent_type: "general-purpose"
  prompt: |
    Read and follow: .claude/agentsresearch-mode-specialist.md
    Topic: Topic 2
    Output: ${REPORT_PATH_2}
}

## Block 3: Verify Artifacts
```bash
for path in "$REPORT_PATH_1" "$REPORT_PATH_2"; do
  [ ! -f "$path" ] && { echo "Report missing: $path"; exit 1; }
done
```
```

---

### When to Use Hierarchical Architecture

**Use Case 1: Multi-Topic Research** (IMPLEMENTED)
- **Example**: `/create-plan` with complexity ≥3
- **Agent Count**: 4+ research specialists (Mathlib, Proofs, Structure, Style)
- **Context Without Coordinator**: 4 x 2,500 = 10,000 tokens
- **Context With Coordinator**: 4 x 110 = 440 tokens (95.6% reduction)
- **Commands**: `research-mode`, `/create-plan`, `/lean-plan`
- **Coordinator**: research-coordinator (planning-only mode)

**Use Case 2: Wave-Based Implementation** (IMPLEMENTED)
- **Example**: `/implement` with 8 phases (dependencies: Phase 1 → [Phase 2,3,4] → [Phase 5,6] → Phase 7 → Phase 8)
- **Agent Count**: 8 implementation-executor invocations across 4 waves
- **Context Without Coordinator**: 8 x 2,000 = 16,000 tokens (context exhaustion after 2 iterations)
- **Context With Coordinator**: 8 x 80 = 640 tokens brief summaries (20+ iterations possible)
- **Commands**: `/implement`, `/lean-implement`
- **Coordinator**: implementer-coordinator (wave-based supervisor)
- **Time Savings**: 40-60% via parallel execution (Wave 2: Phase 2,3,4 run simultaneously)

**Use Case 3: Hybrid Routing** (IMPLEMENTED)
- **Example**: `/lean-implement` with mixed Lean/software phases
- **Agent Count**: Variable (5-12 phases depending on complexity)
- **Context Management**: Dual coordinators (lean-coordinator for Lean phases, implementer-coordinator for software)
- **Commands**: `/lean-implement`
- **Routing Logic**: Phase type detection → coordinator selection → specialist delegation
- **Benefits**: Specialized coordinators for domain-specific patterns

**Implementation Pattern** (Supervisor-Based):
```markdown
## Block 1a: Pre-Calculate Paths
```bash
# Topic directory and artifact paths
TOPIC_DIR=$(get_or_create_topic_dir "$WORKFLOW" ".claude/specs")
REPORT_DIR="${TOPIC_DIR}/reports"
declare -a REPORT_PATHS=(
  "${REPORT_DIR}/001_topic1.md"
  "${REPORT_DIR}/002_topic2.md"
  "${REPORT_DIR}/003_topic3.md"
  "${REPORT_DIR}/004_topic4.md"
)

# Persist for coordinator
save_workflow_state "REPORT_PATHS" "${REPORT_PATHS[@]}"
```

## Block 1b: Invoke Coordinator (Supervisor)
**EXECUTE NOW**: USE the Task tool to invoke the research-coordinator

Task {
  subagent_type: "general-purpose"
  description: "Coordinate parallel research execution"
  prompt: |
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agentsresearch-mode-coordinator.md

    **Input Contract (Hard Barrier Pattern)**:
    - research_request: "${WORKFLOW_DESCRIPTION}"
    - research_complexity: ${RESEARCH_COMPLEXITY}
    - report_dir: ${REPORT_DIR}
    - topic_path: ${TOPIC_PATH}
    - topics: ["Topic 1", "Topic 2", "Topic 3", "Topic 4"]
    - report_paths: ["${REPORT_PATHS[@]}"]

    Execute research coordination according to behavioral guidelines.
}

## Block 1c: Execute Specialist Invocations
**EXECUTE NOW**: Parse invocation plan and invoke specialists

```bash
# Parse invocation plan from coordinator output
INVOCATION_PLAN_PATH=$(extract_signal_field "$COORDINATOR_OUTPUT" "invocation_plan_path")

# Execute specialist invocations (coordinator returned metadata only)
while IFS='|' read -r topic report_path; do
  Task {
    subagent_type: "general-purpose"
    description: "Research: $topic"
    prompt: |
      Read and follow: .claude/agentsresearch-mode-specialist.md
      Topic: $topic
      Output: $report_path
  }
done < "$INVOCATION_PLAN_PATH"
```

## Block 1d: Hard Barrier Validation
```bash
# Validate all artifacts created
for path in "${REPORT_PATHS[@]}"; do
  if [ ! -f "$path" ]; then
    log_command_error "validation_error" \
      "Report missing after coordinator completion" \
      "$(jq -n --arg p "$path" '{missing_report: $p}')"
    exit 1
  fi
done
```

## Block 1e: Extract Metadata (Context Reduction)
```bash
# Coordinator already extracted metadata - use it instead of reading files
AGGREGATED_METADATA=$(extract_coordinator_metadata "$COORDINATOR_OUTPUT")
# 440 tokens instead of 10,000 tokens
```
```

**Implementation Pattern** (Planning-Only Coordinator):
```markdown
## Block 1b: Invoke Coordinator (Planning Only)
**EXECUTE NOW**: USE the Task tool to invoke the research-coordinator

Task {
  subagent_type: "general-purpose"
  prompt: |
    Read and follow: .claude/agentsresearch-mode-coordinator.md

    [Same input contract as supervisor mode]
}

## Block 1c: Parse Invocation Plan
```bash
# Coordinator returns invocation plan WITHOUT executing Task tools
INVOCATION_PLAN=$(parse_signal "INVOCATION_PLAN_READY" "$OUTPUT")
```

## Block 1d: Execute Invocations (Primary Agent)
**EXECUTE NOW**: Invoke specialists based on plan

[Loop through invocation plan and invoke Task tools]

## Block 1e: Hard Barrier Validation
[Same validation as supervisor mode]
```

---

## Decision Factors Deep Dive

### Factor 1: Agent Count

**Flat Model Threshold**: 1-3 agents
- Direct invocation manageable
- Output aggregation straightforward
- No delegation complexity

**Hierarchical Model Threshold**: 4+ agents
- Coordinator provides clear orchestration
- Metadata aggregation essential (95% context reduction)
- Parallel execution benefits compound

**Example Calculation**:
```
3 agents x 2,500 tokens = 7,500 tokens → Flat model acceptable
4 agents x 2,500 tokens = 10,000 tokens → Hierarchical model recommended
5+ agents → Hierarchical model strongly recommended
```

### Factor 2: Context Consumption

**Flat Model Threshold**: <10,000 tokens per iteration
- Manageable context overhead
- 3-4 iterations possible
- No metadata extraction needed

**Hierarchical Model Threshold**: >10,000 tokens per iteration
- Context exhaustion risk without coordination
- Metadata extraction critical (95-96% reduction)
- 10-20+ iterations possible

**Example Scenario**:
```
Workflow: Multi-phase implementation (8 phases)
Without Coordinator: 8 x 2,000 = 16,000 tokens/iteration
  - Context limit: 200,000 tokens
  - Iterations possible: 200,000 / 16,000 = 12 iterations
  - Risk: Context exhaustion before completion

With Coordinator: 8 x 80 = 640 tokens/iteration (brief summaries)
  - Context limit: 200,000 tokens
  - Iterations possible: 200,000 / 640 = 312 iterations
  - Benefit: 20+ iterations with comfortable margin
```

### Factor 3: Parallelization Opportunities

**Flat Model**: Sequential execution
- No dependency analysis
- Linear time complexity
- Simple but slower

**Hierarchical Model**: Parallel wave execution
- Dependency-based wave calculation
- 40-60% time savings
- Complex but faster

**Wave Execution Example**:
```
Plan Dependencies:
  Phase 1: [] (no dependencies)
  Phase 2: [Phase 1]
  Phase 3: [Phase 1]
  Phase 4: [Phase 1]
  Phase 5: [Phase 2, Phase 3]
  Phase 6: [Phase 4]

Wave Calculation:
  Wave 1: Phase 1 (sequential start)
  Wave 2: Phase 2, 3, 4 (parallel - all depend only on Phase 1)
  Wave 3: Phase 5, 6 (parallel - dependencies satisfied)

Sequential Time: 6 x 120s = 720s
Wave Time: 3 x 120s = 360s
Time Savings: 50%
```

### Factor 4: Workflow Phases

**Flat Model**: Single phase workflows
- Research only
- Planning only
- Simple debugging

**Hierarchical Model**: Multi-phase workflows
- Research → Plan → Implement → Test
- Wave-based execution within phases
- Cross-phase dependency management

**Multi-Phase Example**:
```
Workflow: /create-plan (complexity ≥3)
  Phase 1: Multi-topic research (research-coordinator)
    → 4 research specialists invoked in parallel
    → Metadata aggregation (95% context reduction)
  Phase 2: Plan creation (plan-architect)
    → Receives metadata-only context from Phase 1
    → Creates implementation plan
  Phase 3: Plan validation
    → Validates plan structure
    → Checks metadata compliance
```

### Factor 5: Worker Output Size

**Flat Model Threshold**: <500 tokens per worker
- Aggregation overhead minimal
- Direct context passing acceptable

**Hierarchical Model Threshold**: >1,000 tokens per worker
- Metadata extraction essential
- Brief summaries enable context efficiency

**Output Size Impact**:
```
Small Outputs (300 tokens/worker):
  4 workers x 300 = 1,200 tokens → Flat model acceptable

Medium Outputs (1,500 tokens/worker):
  4 workers x 1,500 = 6,000 tokens → Hierarchical model beneficial

Large Outputs (2,500 tokens/worker):
  4 workers x 2,500 = 10,000 tokens → Hierarchical model essential
```

---

## Anti-Patterns

### Anti-Pattern 1: Premature Optimization

**Symptom**: Using hierarchical architecture for 2-agent workflow

**Problem**:
- Coordinator overhead unnecessary
- Added complexity without benefits
- Metadata extraction overkill

**Example** (INCORRECT):
```markdown
## Use coordinator for 2 research topics
Task {
  prompt: |
    Read and follow: .claude/agentsresearch-mode-coordinator.md
    Topics: ["Topic 1", "Topic 2"]
}
```

**Solution**: Use flat model directly
```markdown
## Invoke specialists directly
Task { prompt: "Research Topic 1" }
Task { prompt: "Research Topic 2" }
```

**Rule**: Don't use coordinator unless 4+ agents or >10,000 tokens/iteration

---

### Anti-Pattern 2: Over-Architecting Simple Workflows

**Symptom**: Three-tier hierarchy for single-phase task

**Problem**:
- Unnecessary abstraction layers
- Delegation overhead > execution time
- Debugging complexity increased

**Example** (INCORRECT):
```
Command → Orchestrator → Coordinator → Supervisor → Specialist
(5 layers for simple research task)
```

**Solution**: Direct invocation
```
Command → Specialist
(2 layers)
```

**Rule**: Maximum 3 tiers (Command → Coordinator → Specialist) unless proven need

---

### Anti-Pattern 3: Flat Model for High Context Workflows

**Symptom**: 8-agent workflow with direct invocation

**Problem**:
- Context exhaustion after 2-3 iterations
- No metadata extraction
- Sequential execution (slow)

**Example** (INCORRECT):
```markdown
## Invoke 8 specialists sequentially
Task { prompt: "Phase 1" }
Task { prompt: "Phase 2" }
Task { prompt: "Phase 3" }
Task { prompt: "Phase 4" }
Task { prompt: "Phase 5" }
Task { prompt: "Phase 6" }
Task { prompt: "Phase 7" }
Task { prompt: "Phase 8" }
# 8 x 2,000 = 16,000 tokens/iteration → context exhaustion
```

**Solution**: Use implementer-coordinator
```markdown
Task {
  prompt: |
    Read and follow: .claude/agents/implementer-coordinator.md
    Plan: /path/to/plan.md
    # Coordinator handles wave-based execution, metadata extraction
}
# 8 x 80 = 640 tokens/iteration → 20+ iterations possible
```

**Rule**: Use hierarchical model when agent outputs total >10,000 tokens

---

### Anti-Pattern 4: Mixing Flat and Hierarchical Without Routing Logic

**Symptom**: Inconsistent delegation patterns within same workflow

**Problem**:
- Some phases use coordinator, others don't (no clear logic)
- Maintenance confusion
- Inconsistent error handling

**Example** (INCORRECT):
```markdown
## Phase 1: Use coordinator
Task { prompt: "research-coordinator" }

## Phase 2: Direct invocation (no clear reason)
Task { prompt: "specialist 1" }
Task { prompt: "specialist 2" }

## Phase 3: Use coordinator again
Task { prompt: "implementer-coordinator" }
```

**Solution**: Document routing logic explicitly
```markdown
## Routing Logic:
# - Lean phases (complexity ≥3) → lean-coordinator
# - Software phases (all) → implementer-coordinator
# - Single research task → research-specialist (direct)

if [ "$PHASE_TYPE" = "lean" ] && [ "$COMPLEXITY" -ge 3 ]; then
  COORDINATOR="lean-coordinator"
elif [ "$PHASE_TYPE" = "software" ]; then
  COORDINATOR="implementer-coordinator"
else
  # Direct invocation for simple tasks
fi
```

**Rule**: Document routing criteria when mixing patterns

---

## Performance Metrics Reference

### Context Reduction Measurements

**Research Coordinator** (Example 7 in hierarchical-agents-examples.md):
```
Baseline (Flat Model):
  4 research reports x 2,500 tokens = 10,000 tokens → orchestrator

Hierarchical Model:
  4 research reports x 2,500 tokens → coordinator
  Coordinator extracts metadata: 4 x 82 tokens = 330 tokens → orchestrator

Context Reduction: 96.7% (10,000 → 330 tokens)
```

**Implementer Coordinator** (Example 8 in hierarchical-agents-examples.md):
```
Baseline (Flat Model):
  Full phase summary: 2,000 tokens → orchestrator

Hierarchical Model:
  Brief summary format: 80 tokens → orchestrator

Context Reduction: 96% (2,000 → 80 tokens)
```

**Combined Workflow** (/lean-plan complexity 3):
```
Research Phase:
  Metadata-only: 330 tokens (vs 7,500 baseline)
  Reduction: 95.6%

Implementation Phase:
  Brief summaries: 640 tokens for 8 phases (vs 16,000 baseline)
  Reduction: 96%

Overall:
  Hierarchical: 970 tokens
  Flat: 23,500 tokens
  Total Reduction: 95.9%
```

### Time Savings Measurements

**Wave-Based Execution** (implementer-coordinator):
```
8-Phase Plan with Dependencies:
  Wave 1: Phase 1 (120s)
  Wave 2: Phase 2, 3, 4 in parallel (120s)
  Wave 3: Phase 5, 6 in parallel (120s)
  Wave 4: Phase 7 (120s)
  Wave 5: Phase 8 (120s)

Sequential Time: 8 x 120s = 960s (16 minutes)
Wave Time: 5 x 120s = 600s (10 minutes)
Time Savings: 37.5%

With optimal dependency structure (3 waves for 8 phases):
Wave Time: 3 x 120s = 360s (6 minutes)
Time Savings: 62.5%
```

### Iteration Capacity Measurements

**Context Limit Impact**:
```
Context Budget: 200,000 tokens
Agent Output: 2,000 tokens/agent
Agents per Iteration: 8 agents

Flat Model:
  Tokens/Iteration: 8 x 2,000 = 16,000 tokens
  Iterations: 200,000 / 16,000 = 12 iterations

Hierarchical Model (Brief Summaries):
  Tokens/Iteration: 8 x 80 = 640 tokens
  Iterations: 200,000 / 640 = 312 iterations

Iteration Capacity Increase: 26x (312 / 12)
```

---

## Migration Guide: Flat to Hierarchical

### Step 1: Identify Conversion Candidates

**Criteria**:
- [ ] Workflow has 4+ parallel agents
- [ ] Agent outputs total >10,000 tokens/iteration
- [ ] Workflow experiences context exhaustion
- [ ] Parallel execution opportunities exist

**Audit Commands**:
```bash
# Find commands with multiple Task invocations
grep -c "Task {" .claude/commands/*.md | awk -F: '$2 >= 4'

# Find commands with research/implementation phases
grep -l "research-specialist\|implementation-executor" .claude/commands/*.md
```

### Step 2: Choose Coordinator Type

**Decision Matrix**:

| Workflow Type | Coordinator | Pattern |
|--------------|-------------|---------|
| Multi-topic research | research-coordinator | Planning-only |
| Wave-based implementation | implementer-coordinator | Supervisor |
| Parallel testing | testing-coordinator | Supervisor |
| Multi-vector debugging | debug-coordinator | Supervisor |
| Error pattern analysis | repair-coordinator | Supervisor |

### Step 3: Refactor Command Structure

**Before** (Flat Model):
```markdown
## Block 1: Research Phase
**EXECUTE NOW**: Invoke specialists

Task { prompt: "Research Topic 1" }
Task { prompt: "Research Topic 2" }
Task { prompt: "Research Topic 3" }
Task { prompt: "Research Topic 4" }

## Block 2: Aggregate Results
```bash
# Read all 4 reports (10,000 tokens consumed)
```
```

**After** (Hierarchical Model):
```markdown
## Block 1a: Pre-Calculate Paths
```bash
# Hard barrier pattern enforcement
declare -a REPORT_PATHS=(...)
```

## Block 1b: Invoke Coordinator
**EXECUTE NOW**: USE the Task tool

Task {
  prompt: |
    Read and follow: .claude/agentsresearch-mode-coordinator.md
    topics: [...]
    report_paths: [...]
}

## Block 1c: Execute Invocation Plan
[Parse coordinator output and invoke specialists]

## Block 1d: Extract Metadata
```bash
# Use coordinator's metadata extraction (440 tokens vs 10,000)
METADATA=$(extract_coordinator_metadata "$OUTPUT")
```
```

### Step 4: Validate Performance Gains

**Metrics to Measure**:
1. **Context Reduction**: Compare tokens consumed before/after
2. **Time Savings**: Measure execution time with parallel waves
3. **Iteration Capacity**: Test workflow with longer phase sequences

**Validation Script**:
```bash
# Before migration
BASELINE_TOKENS=$(measure_context_usage "/command-flat")
BASELINE_TIME=$(measure_execution_time "/command-flat")

# After migration
HIERARCHICAL_TOKENS=$(measure_context_usage "/command-hierarchical")
HIERARCHICAL_TIME=$(measure_execution_time "/command-hierarchical")

# Calculate improvements
CONTEXT_REDUCTION=$(( (BASELINE_TOKENS - HIERARCHICAL_TOKENS) * 100 / BASELINE_TOKENS ))
TIME_SAVINGS=$(( (BASELINE_TIME - HIERARCHICAL_TIME) * 100 / BASELINE_TIME ))

echo "Context Reduction: ${CONTEXT_REDUCTION}%"
echo "Time Savings: ${TIME_SAVINGS}%"
```

---

## Summary: Quick Reference

### Use Flat Architecture When:
- ✓ 1-3 agents total
- ✓ <10,000 tokens per iteration
- ✓ Single workflow phase
- ✓ Sequential execution acceptable
- ✓ <500 tokens per agent output

### Use Hierarchical Architecture When:
- ✓ 4+ parallel agents
- ✓ >10,000 tokens per iteration
- ✓ Multi-phase workflow
- ✓ Parallel execution opportunities
- ✓ >1,000 tokens per agent output

### Performance Targets (Hierarchical):
- **Context Reduction**: 95-96%
- **Time Savings**: 40-60%
- **Iteration Capacity**: 10-20+ iterations

### Coordinator Types:
- **research-coordinator**: Multi-topic research (planning-only)
- **implementer-coordinator**: Wave-based implementation (supervisor)
- **testing-coordinator**: Parallel test execution (supervisor)
- **debug-coordinator**: Multi-vector debugging (supervisor)
- **repair-coordinator**: Error pattern analysis (supervisor)

---

## References

### Architecture Documentation
- [Hierarchical Agents Overview](../../concepts/hierarchical-agents-overview.md) - Core architecture concepts
- [Three-Tier Coordination Pattern](../../concepts/three-tier-coordination-pattern.md) - Tier responsibilities
- [Hierarchical Agents Examples](../../concepts/hierarchical-agents-examples.md) - Example 7-8 (research-coordinator, implementer-coordinator)

### Implementation Patterns
- [Coordinator Patterns Standard](../../reference/standards/coordinator-patterns-standard.md) - Five core coordinator patterns
- [Artifact Metadata Standard](../../reference/standards/artifact-metadata-standard.md) - Metadata extraction specifications
- [Brief Summary Format](../../reference/standards/brief-summary-format.md) - 96% context reduction format

### Command Examples
- `research-mode` - research-coordinator integration (4+ topics)
- `/create-plan` - research-coordinator integration (complexity ≥3)
- `/implement` - implementer-coordinator integration (wave-based)
- `/lean-plan` - research-coordinator integration (Lean research)
- `/lean-implement` - Dual coordinator integration (hybrid routing)

### Agent Implementations
- `.claude/agentsresearch-mode-coordinator.md` - Planning-only coordinator reference
- `.claude/agents/implementer-coordinator.md` - Supervisor coordinator reference
- `.claude/agentsresearch-mode-specialist.md` - Specialist reference
- `.claude/agents/implementation-executor.md` - Specialist reference

### Testing Standards
- `.claude/tests/integration/test_lean_plan_coordinator.sh` - 21 tests (100% pass)
- `.claude/tests/integration/test_lean_implement_coordinator.sh` - 27 tests (100% pass)
- `.claude/tests/integration/test_lean_coordinator_plan_mode.sh` - 7 tests, 1 skip
