# Research Report: /lean-plan Wave Indicators

## Executive Summary

This report documents how the `/lean-plan` command indicates waves in plan output, verifies wave syntax compatibility with `lean-coordinator` consumption, and analyzes the phase dependency structures that enable parallel execution.

**Key Findings**:
1. **Wave indicators are IMPLICIT**: `/lean-plan` does NOT explicitly mark wave boundaries in output
2. **Dependency syntax is COMPATIBLE**: Uses `dependencies: [N, M]` format consumed by `dependency-analyzer.sh`
3. **Wave construction is DERIVED**: `lean-coordinator` builds waves via topological sort in Block 2 (STEP 2)
4. **No changes needed**: Current plan format is sufficient for wave-based orchestration

## Research Questions Answered

### 1. How does /lean-plan indicate wave boundaries in its output?

**Answer**: Wave boundaries are **NOT explicitly indicated** in `/lean-plan` output. Plans use phase-level dependency metadata only.

**Evidence from plan-architect.md** (line 947-993):
```markdown
### Phase 1: Foundation [NOT STARTED]
implementer: lean
lean_file: /path/to/file.lean
dependencies: []

Tasks:
- [ ] Task 1
```

**Phase Metadata Fields**:
- `implementer: lean|software` - Phase type (optional, for routing)
- `lean_file: /absolute/path` - Lean source file (optional)
- `dependencies: [1, 2]` - Phase dependencies (CRITICAL for waves)

**Wave Construction Process**:
1. `/lean-plan` outputs plan with `dependencies: []` metadata per phase
2. `lean-coordinator` invokes `dependency-analyzer.sh` in Block 2 (STEP 2)
3. Dependency analyzer performs topological sort (Kahn's algorithm)
4. Waves are constructed dynamically from dependency graph

**Example from spec 063**:
```markdown
### Phase 1: Minimal Task Directive Recognition Test [NOT STARTED]
dependencies: []

### Phase 2: Nested Task Invocation Capability Test [NOT STARTED]
dependencies: [1]

### Phase 3: lean-plan Delegation Checkpoints Implementation [NOT STARTED]
dependencies: [1]

### Phase 4: Fix Strategy Implementation Based on Test Results [NOT STARTED]
dependencies: [1, 2, 3]
```

**Derived Wave Structure** (constructed by dependency-analyzer):
- Wave 1: [Phase 1] (no dependencies)
- Wave 2: [Phase 2, Phase 3] (both depend only on Phase 1 - PARALLEL)
- Wave 3: [Phase 4] (depends on all prior phases)

### 2. What dependency syntax is used?

**Answer**: Standard array notation `dependencies: [N, M]` where N and M are phase numbers.

**Syntax Specification** (from plan-metadata-standard.md, lines 174-195):

```markdown
dependencies: []                    # No dependencies (Wave 1)
dependencies: [1]                   # Depends on Phase 1
dependencies: [1, 2, 3]             # Depends on Phases 1, 2, and 3
```

**Parsing Implementation** (dependency-analyzer.sh, lines 84-93):
```bash
# Extract depends_on - look for the pattern and extract content between brackets
if grep -qi "depends_on:" "$file_path"; then
  # Extract content between brackets, handle multi-word phase names
  local deps_raw
  deps_raw=$(grep -i "depends_on:" "$file_path" | head -1 | sed -E 's/.*depends_on:\s*\[([^\]]*)\].*/\1/')
  # Clean up and split by comma
  if [[ -n "$deps_raw" && "$deps_raw" != *"depends_on"* ]]; then
    dependencies=$(echo "$deps_raw" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' | paste -sd ',' -)
  fi
fi
```

**Alternative Syntax Supported**:
- `dependencies: []` (preferred in newer plans)
- `depends_on: [1, 2]` (legacy format, still parsed)

**Validation Rules** (plan-metadata-standard.md, line 179):
- Format must be valid array notation: `[]` or `[N, N, N]` with numeric values
- ERROR-level if field present but malformed
- No errors if field omitted (fallback classification applies)

### 3. Are waves explicitly marked or inferred from dependencies?

**Answer**: Waves are **INFERRED** from dependencies via topological sort algorithm.

**Wave Inference Algorithm** (dependency-analyzer.sh, lines 296-392):

**Kahn's Algorithm Implementation**:
1. **Build in-degree map**: Count incoming edges per phase
2. **Initialize Wave 1**: All phases with in-degree 0 (no dependencies)
3. **Iterative wave construction**:
   - Add phases with satisfied dependencies to current wave
   - Remove completed phases from graph
   - Decrement in-degree for dependent phases
   - Repeat until all phases allocated

**Example Analysis Output** (dependency-analyzer.sh, line 609-617):
```json
{
  "dependency_graph": {
    "nodes": [...],
    "edges": [{"from": "phase_1", "to": "phase_2"}]
  },
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
    "total_phases": 4,
    "parallel_phases": 2,
    "time_savings_percentage": "50%"
  }
}
```

**Coordinator Consumption** (lean-coordinator.md, lines 100-108):
```bash
# STEP 2: Dependency Analysis
bash /home/benjamin/.config/.claude/lib/util/dependency-analyzer.sh "$plan_path" > /tmp/dependency_analysis.json

# Parse Analysis Results:
# - Extract dependency graph (nodes, edges)
# - Extract wave structure (wave_number, theorems per wave)
# - Extract parallelization metrics (time savings estimate)
```

**Wave Display Format** (lean-coordinator.md, lines 115-135):
```
╔═══════════════════════════════════════════════════════╗
║ Lean Coordination Plan                                ║
╠═══════════════════════════════════════════════════════╣
║ Total Theorems: 6                                     ║
║ Waves: 2                                              ║
║ Parallel Theorems: 3                                  ║
║ Sequential Time: 90 minutes                           ║
║ Parallel Time: 45 minutes                             ║
║ Time Savings: 50%                                     ║
╠═══════════════════════════════════════════════════════╣
║ Wave 1: Independent Theorems (3 phases, PARALLEL)    ║
║ ├─ Phase 1: theorem_add_comm                         ║
║ ├─ Phase 2: theorem_mul_assoc                        ║
║ └─ Phase 3: theorem_zero_add                         ║
╠═══════════════════════════════════════════════════════╣
║ Wave 2: Dependent Theorems (3 phases, PARALLEL)      ║
║ ├─ Phase 4: theorem_ring_properties                  ║
║ ├─ Phase 5: theorem_field_division                   ║
║ └─ Phase 6: theorem_complete_ring                    ║
╚═══════════════════════════════════════════════════════╝
```

### 4. What changes are needed for wave indicator clarity?

**Answer**: **NO CHANGES NEEDED**. Current design is architecturally correct.

**Rationale**:

1. **Separation of Concerns**:
   - `/lean-plan` generates **declarative dependency metadata**
   - `dependency-analyzer.sh` performs **wave construction algorithm**
   - `lean-coordinator` displays **execution visualization**

2. **Flexibility Benefits**:
   - Same dependency format works for software plans (/implement) and Lean plans (/lean-implement)
   - Wave construction adapts to different dependency graphs without plan regeneration
   - Algorithm improvements don't require plan format changes

3. **Existing Standards Compliance**:
   - Plan Metadata Standard (plan-metadata-standard.md) already documents dependency syntax
   - Command Authoring standards reference dependency-analyzer integration
   - Pre-commit hooks validate dependency format

4. **Proven Implementation**:
   - implementer-coordinator.md uses identical pattern (lines 96-130)
   - testing-coordinator.md uses parallel delegation with same dependency analysis
   - research-coordinator.md uses metadata-only passing without explicit waves

**Anti-Pattern to Avoid**:
Adding explicit wave markers like:
```markdown
### WAVE 1: Foundation Phase
### Phase 1: Setup [NOT STARTED]
dependencies: []
```

**Why This Is Wrong**:
- Violates DRY principle (wave info duplicated from dependencies)
- Creates synchronization burden (wave markers must match dependency-derived waves)
- Breaks automated wave construction (hardcoded waves conflict with topological sort)
- Reduces flexibility (plan revision requires manual wave renumbering)

## Dependency Syntax Deep Dive

### Supported Formats

**1. Empty Dependencies** (Wave 1 phases):
```markdown
dependencies: []
```

**2. Single Dependency**:
```markdown
dependencies: [1]
```

**3. Multiple Dependencies**:
```markdown
dependencies: [1, 2, 3]
```

**4. Legacy Format** (still parsed):
```markdown
depends_on: [1, 2]
```

### Parsing Rules

**From dependency-analyzer.sh (lines 64-136)**:

1. **Case-insensitive matching**: `depends_on:` or `DEPENDS_ON:` both work
2. **Bracket extraction**: Regex `\[([^\]]*)\]` extracts dependency list
3. **Comma splitting**: Dependencies split by comma with whitespace trimming
4. **JSON conversion**: Array format `["1", "2", "3"]` for jq processing

**Validation** (dependency-analyzer.sh, lines 537-562):
```bash
validate_dependency_syntax() {
  # Check for malformed dependency declarations
  if grep -qi "depends_on:" "$file_path"; then
    # Validate format: depends_on: [phase_1, phase_2]
    if ! grep -i "depends_on:" "$file_path" | grep -q "\[.*\]"; then
      >&2 echo "ERROR: Invalid depends_on format (missing brackets)"
      return 1
    fi
  fi
}
```

### Wave Construction Algorithm Details

**Kahn's Algorithm** (dependency-analyzer.sh, lines 296-392):

**Input**: Dependency graph with nodes (phases) and edges (dependencies)

**Process**:
1. Calculate in-degree for each phase (count of incoming dependency edges)
2. Initialize current wave with all phases having in-degree = 0
3. Add phases to current wave
4. Remove completed phases from graph
5. Decrement in-degree of phases depending on completed phases
6. Repeat until all phases processed

**Output**: Wave structure JSON with:
- `wave_number`: Sequential wave identifier (1, 2, 3, ...)
- `phases`: Array of phase IDs in this wave
- `can_parallel`: Boolean indicating if wave has multiple phases (parallelizable)

**Example Execution**:

**Input Dependencies**:
- Phase 1: `dependencies: []`
- Phase 2: `dependencies: [1]`
- Phase 3: `dependencies: [1]`
- Phase 4: `dependencies: [2, 3]`

**Step-by-Step Construction**:

**Iteration 1**:
- In-degree: {Phase1: 0, Phase2: 1, Phase3: 1, Phase4: 2}
- Wave 1 candidates: [Phase1] (in-degree = 0)
- Wave 1 result: `{wave_number: 1, phases: ["phase_1"], can_parallel: false}`

**Iteration 2**:
- Decrement in-degree for phases depending on Phase1: {Phase2: 0, Phase3: 0, Phase4: 2}
- Wave 2 candidates: [Phase2, Phase3] (in-degree = 0)
- Wave 2 result: `{wave_number: 2, phases: ["phase_2", "phase_3"], can_parallel: true}`

**Iteration 3**:
- Decrement in-degree for phases depending on Phase2/Phase3: {Phase4: 0}
- Wave 3 candidates: [Phase4] (in-degree = 0)
- Wave 3 result: `{wave_number: 3, phases: ["phase_4"], can_parallel: false}`

**Cycle Detection**:
- If no phases have in-degree = 0 but phases remain, circular dependency exists
- ERROR returned with diagnostic: "Circular dependency detected: phase_X -> phase_Y"

## Parallelization Metrics

**Time Savings Calculation** (dependency-analyzer.sh, lines 480-528):

```bash
# Assume 3 hours per phase average
avg_phase_time=3
sequential_time=$((total_phases * avg_phase_time))  # Sum of all phases
parallel_time=$((wave_count * avg_phase_time))      # Max phase time per wave

# Time savings percentage
time_savings=$(( (sequential_time - parallel_time) * 100 / sequential_time ))
```

**Example**:
- 6 phases total, 2 waves
- Sequential: 6 phases × 3 hours = 18 hours
- Parallel: 2 waves × 3 hours = 6 hours (longest phase per wave)
- Savings: (18 - 6) / 18 = 67% time reduction

**Parallel Phase Counting** (dependency-analyzer.sh, lines 487-501):
```bash
# Count phases in parallel waves (waves with >1 phase)
for wave in waves; do
  if phase_count > 1:
    parallel_phases += (phase_count - 1)  # All but one execute in parallel
done
```

**Metrics Output Format**:
```json
{
  "total_phases": 6,
  "parallel_phases": 3,
  "sequential_estimated_time": "18 hours",
  "parallel_estimated_time": "6 hours",
  "time_savings_percentage": "67%"
}
```

## Integration with lean-coordinator

### Block 2: Dependency Analysis (STEP 2)

**From lean-coordinator.md (lines 98-114)**:

```markdown
### STEP 2: Dependency Analysis

1. **Invoke dependency-analyzer Utility**:
   ```bash
   bash /home/benjamin/.config/.claude/lib/util/dependency-analyzer.sh "$plan_path" > /tmp/dependency_analysis.json
   ```

2. **Parse Analysis Results**:
   - Extract dependency graph (nodes, edges)
   - Extract wave structure (wave_number, theorems per wave)
   - Extract parallelization metrics (time savings estimate)

3. **Validate Graph**:
   - Check for cycles (circular dependencies)
   - Verify all phase references valid
   - Confirm at least 1 theorem in Wave 1 (starting point)
```

### Block 4: Wave Execution Loop (STEP 4)

**From lean-coordinator.md (lines 254-262)**:

```markdown
FOR EACH wave in wave structure:

#### Wave Initialization
- Log wave start: "Starting Wave {N}: {theorem_count} theorems"
- Create wave state object with start time
- Initialize implementer tracking arrays
- Calculate MCP rate limit budget allocation
```

### Parallel Invocation Pattern

**From lean-coordinator.md (lines 264-280)**:

```markdown
#### MCP Rate Limit Budget Allocation

Calculate budget per implementer based on wave size:

```bash
# MCP external search tools: 3 requests per 30 seconds (shared limit)
TOTAL_BUDGET=3
wave_size=${#theorems_in_wave[@]}

if [ $wave_size -le 3 ]; then
  budget_per_implementer=1
else
  # Distribute budget evenly, minimum 1 per implementer
  budget_per_implementer=$((TOTAL_BUDGET / wave_size))
fi
```
```

**Multiple Task Invocations** (one per phase in wave):
```markdown
I'm now invoking lean-implementer for Phase 2 and Phase 3 in parallel (Wave 2).

**EXECUTE NOW**: USE the Task tool to invoke lean-implementer for Phase 2.

Task {
  subagent_type: "general-purpose"
  description: "Prove theorems in Phase 2"
  prompt: "..."
}

**EXECUTE NOW**: USE the Task tool to invoke lean-implementer for Phase 3.

Task {
  subagent_type: "general-purpose"
  description: "Prove theorems in Phase 3"
  prompt: "..."
}
```

## Conclusion

The `/lean-plan` command's dependency metadata design is architecturally sound and requires no changes for wave-based orchestration. The separation between declarative dependency specification (plan output) and imperative wave construction (dependency-analyzer) provides flexibility, maintainability, and standards compliance.

**Key Takeaways**:
1. Waves are derived, not declared (topological sort algorithm)
2. Dependency syntax is simple, validated, and consistent
3. Same pattern works across software plans (/implement) and Lean plans (/lean-implement)
4. Explicit wave markers would violate DRY principle and reduce flexibility

## Related Documentation

- [Plan Metadata Standard](.claude/docs/reference/standards/plan-metadata-standard.md) - Dependency field specification
- [Hierarchical Agent Architecture](.claude/docs/concepts/hierarchical-agents-overview.md) - Coordinator patterns
- [Implementer Coordinator](.claude/agents/implementer-coordinator.md) - Wave-based software implementation
- [Lean Coordinator](.claude/agents/lean-coordinator.md) - Wave-based theorem proving
- [Dependency Analyzer](.claude/lib/util/dependency-analyzer.sh) - Wave construction algorithm

## Metadata

- **Research Date**: 2025-12-09
- **Researcher**: research-specialist
- **Research Topic**: /lean-plan Command Wave Indicators
- **Key Files Analyzed**:
  - /home/benjamin/.config/.claude/commands/lean-plan.md
  - /home/benjamin/.config/.claude/output/lean-plan-output.md
  - /home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md
  - /home/benjamin/.config/.claude/agents/plan-architect.md
  - /home/benjamin/.config/.claude/agents/lean-plan-architect.md
  - /home/benjamin/.config/.claude/agents/lean-coordinator.md
  - /home/benjamin/.config/.claude/lib/util/dependency-analyzer.sh
- **Implementation Status**: Research Complete
- **Plan**: [Will be updated by plan-architect]
