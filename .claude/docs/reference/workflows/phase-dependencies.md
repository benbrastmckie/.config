# Phase Dependencies Guide

## Overview

Phase dependencies enable wave-based parallel execution during implementation workflows. By declaring which phases depend on others, the orchestration system can automatically calculate execution waves and run independent phases in parallel, significantly reducing total implementation time.

This guide documents dependency syntax, wave calculation algorithms, and best practices for using dependencies in implementation plans.

## Table of Contents

1. [Dependency Syntax](#dependency-syntax)
2. [Dependency Rules and Validation](#dependency-rules-and-validation)
3. [Wave Calculation](#wave-calculation)
4. [Usage in Implementation Plans](#usage-in-implementation-plans)
5. [Parallel Execution Patterns](#parallel-execution-patterns)
6. [Performance Optimization](#performance-optimization)
7. [Common Dependency Patterns](#common-dependency-patterns)
8. [Error Handling](#error-handling)
9. [Testing and Verification](#testing-and-verification)

---

## Dependency Syntax

Phase dependencies are declared in phase metadata using the `Dependencies` field:

### Basic Syntax

```markdown
### Phase N: [Phase Name]

**Objective**: [What this phase accomplishes]
**Dependencies**: [] or [1, 2, 3]
**Complexity**: Low|Medium|High
**Risk**: Low|Medium|High
**Estimated Time**: X-Y hours
```

### Dependency Formats

#### No Dependencies (Independent Phase)

```markdown
### Phase 1: Foundation Setup
**Dependencies**: []
```

The phase has no dependencies and can execute in the first wave.

#### Single Dependency

```markdown
### Phase 2: Database Schema
**Dependencies**: [1]
```

The phase depends on Phase 1 completing before it can start.

#### Multiple Dependencies

```markdown
### Phase 4: Integration Testing
**Dependencies**: [2, 3]
```

The phase depends on both Phase 2 and Phase 3 completing before it can start.

#### Non-Consecutive Dependencies

```markdown
### Phase 7: Deployment
**Dependencies**: [1, 4, 6]
```

The phase can depend on any earlier phases, not just consecutive ones.

---

## Dependency Rules and Validation

### Valid Dependency Rules

1. **Phase Numbers**: Dependencies must be valid phase numbers (integers)
2. **Earlier Phases Only**: A phase can only depend on earlier phases (no forward dependencies)
3. **No Self-Dependencies**: A phase cannot depend on itself
4. **No Circular Dependencies**: Dependency graph must be acyclic (DAG)

### Invalid Dependencies

#### Forward Dependency (Invalid)

```markdown
### Phase 2: Core Implementation
**Dependencies**: [3]  # ✗ INVALID - Phase 3 doesn't exist yet
```

#### Self-Dependency (Invalid)

```markdown
### Phase 3: API Layer
**Dependencies**: [3]  # ✗ INVALID - Cannot depend on itself
```

#### Circular Dependency (Invalid)

```markdown
### Phase 2: Backend
**Dependencies**: [3]  # ✗ INVALID - Circular: 2→3, 3→2

### Phase 3: Frontend
**Dependencies**: [2]
```

### Validation Process

The dependency analysis utilities perform automatic validation:

```bash
# Validate all dependencies in plan
validate_dependencies "$PLAN_PATH"

# Returns:
# 0 - All dependencies valid
# 1 - Invalid dependencies found (errors logged)
```

**Validation Checks**:
1. All dependency numbers are valid integers
2. All dependency numbers are in valid range (1 to phase_count)
3. No forward dependencies
4. No self-dependencies
5. No circular dependencies

---

## Wave Calculation

### Topological Sorting (Kahn's Algorithm)

The system uses Kahn's algorithm to calculate execution waves:

**Algorithm Steps**:
1. Build dependency graph (adjacency list and in-degree map)
2. Find all phases with in-degree = 0 (no dependencies)
3. These phases form Wave 1
4. Remove Wave 1 phases from graph, decrement dependent phases' in-degrees
5. Repeat until all phases assigned to waves
6. If any phases remain, circular dependency detected

### Wave Calculation Example

**Plan with Dependencies**:

```markdown
### Phase 1: Database Setup
**Dependencies**: []

### Phase 2: API Layer
**Dependencies**: [1]

### Phase 3: Frontend Components
**Dependencies**: [1]

### Phase 4: Authentication
**Dependencies**: [2]

### Phase 5: User Interface
**Dependencies**: [3]

### Phase 6: Integration Tests
**Dependencies**: [4, 5]
```

**Dependency Graph**:

```
Phase 1 (in-degree: 0)
  ├─→ Phase 2 (in-degree: 1)
  │     └─→ Phase 4 (in-degree: 1)
  │           └─→ Phase 6 (in-degree: 2)
  └─→ Phase 3 (in-degree: 1)
        └─→ Phase 5 (in-degree: 1)
              └─→ Phase 6
```

**Calculated Waves**:

```json
[
  [1],       // Wave 1: Phase 1
  [2, 3],    // Wave 2: Phases 2, 3 (parallel)
  [4, 5],    // Wave 3: Phases 4, 5 (parallel)
  [6]        // Wave 4: Phase 6
]
```

**Execution Timeline**:

```
┌────────┬────────┬────────┬────────┐
│ Wave 1 │ Wave 2 │ Wave 3 │ Wave 4 │
├────────┼────────┼────────┼────────┤
│        │ Phase2 │ Phase4 │        │
│ Phase1 ├────────┼────────┤ Phase6 │
│        │ Phase3 │ Phase5 │        │
└────────┴────────┴────────┴────────┘
```

### Wave Calculation API

```bash
# Calculate execution waves for plan
WAVES_JSON=$(calculate_execution_waves "$PLAN_PATH")

# Returns JSON array of waves
# Example: [[1],[2,3],[4,5],[6]]

# Parse wave structure
WAVE_COUNT=$(echo "$WAVES_JSON" | jq 'length')

# Get phases in specific wave
WAVE_2_PHASES=$(echo "$WAVES_JSON" | jq -r '.[1][]')
# Returns: "2 3"
```

---

## Usage in Implementation Plans

### Declaring Dependencies in Plans

When creating implementation plans, declare dependencies based on phase relationships:

**Foundation Phases** (Wave 1):
```markdown
### Phase 1: Project Setup
**Dependencies**: []
```

**Dependent Phases** (Wave 2+):
```markdown
### Phase 2: Core Library
**Dependencies**: [1]

### Phase 3: Configuration System
**Dependencies**: [1]
```

**Integration Phases** (Later Waves):
```markdown
### Phase 4: Integration Layer
**Dependencies**: [2, 3]
```

### Default Dependency Behavior

If no `Dependencies` field is specified:
- **Default**: `[]` (no dependencies)
- **Implication**: Phase can execute in Wave 1
- **Best Practice**: Always explicitly declare `Dependencies: []` for clarity

### Template Integration

Plan templates (`.claude/templates/*.yaml`) include dependency fields:

```yaml
phases:
  - name: "Foundation"
    dependencies: []
    tasks: [...]

  - name: "Core Implementation"
    dependencies: [1]
    tasks: [...]

  - name: "Testing"
    dependencies: [1, 2]
    tasks: [...]
```

---

## Parallel Execution Patterns

### Pattern 1: Independent Modules

**Scenario**: Multiple independent modules can be developed in parallel

```markdown
### Phase 1: Project Setup
**Dependencies**: []

### Phase 2: Authentication Module
**Dependencies**: [1]

### Phase 3: Payment Module
**Dependencies**: [1]

### Phase 4: Notification Module
**Dependencies**: [1]

### Phase 5: Integration Tests
**Dependencies**: [2, 3, 4]
```

**Waves**:
- Wave 1: Phase 1
- Wave 2: Phases 2, 3, 4 (parallel)
- Wave 3: Phase 5

**Time Savings**: ~50-60% if modules are equal complexity

### Pattern 2: Frontend/Backend Split

**Scenario**: Frontend and backend can be developed in parallel after schema design

```markdown
### Phase 1: Database Schema
**Dependencies**: []

### Phase 2: Backend API
**Dependencies**: [1]

### Phase 3: Frontend UI
**Dependencies**: [1]

### Phase 4: End-to-End Tests
**Dependencies**: [2, 3]
```

**Waves**:
- Wave 1: Phase 1
- Wave 2: Phases 2, 3 (parallel)
- Wave 3: Phase 4

**Time Savings**: ~40-50%

### Pattern 3: Layered Architecture

**Scenario**: Multiple layers depend on foundation

```markdown
### Phase 1: Data Layer
**Dependencies**: []

### Phase 2: Business Logic Layer
**Dependencies**: [1]

### Phase 3: API Layer
**Dependencies**: [2]

### Phase 4: UI Layer
**Dependencies**: [3]

### Phase 5: Testing
**Dependencies**: [4]
```

**Waves**:
- Wave 1: Phase 1
- Wave 2: Phase 2
- Wave 3: Phase 3
- Wave 4: Phase 4
- Wave 5: Phase 5

**Time Savings**: Minimal (sequential architecture)

**Optimization**: Consider parallel development of business logic components

---

## Performance Optimization

### Maximizing Parallelization

**Goal**: Maximize phases per wave while respecting dependencies

**Strategies**:

1. **Minimize Dependencies**: Only declare truly necessary dependencies
2. **Decouple Phases**: Break monolithic phases into independent units
3. **Foundation First**: Complete shared foundations early (Wave 1)
4. **Parallel Domains**: Separate feature domains for parallel development

### Performance Metrics

**Parallelization Effectiveness**:

```
effectiveness = (sequential_time - parallel_time) / sequential_time

Target: > 0.40 (40% time savings)
Good: > 0.50 (50% time savings)
Excellent: > 0.60 (60% time savings)
```

**Example Calculation**:

```
Sequential: 6 phases × 60 minutes = 360 minutes
Parallel (3 waves): 180 minutes
Effectiveness: (360 - 180) / 360 = 0.50 (50% savings)
```

### Optimal Wave Structure

**Balanced Waves** (Good):
```
Wave 1: [1]       (1 phase,  60 min)
Wave 2: [2, 3, 4] (3 phases, 60 min)
Wave 3: [5, 6]    (2 phases, 60 min)
Total: 180 minutes (50% savings)
```

**Unbalanced Waves** (Suboptimal):
```
Wave 1: [1]    (1 phase,  60 min)
Wave 2: [2]    (1 phase,  60 min)
Wave 3: [3]    (1 phase,  60 min)
Wave 4: [4, 5, 6] (3 phases, 60 min)
Total: 240 minutes (33% savings)
```

**Optimization**: Reduce dependencies for earlier phases to enable more parallelization

---

## Common Dependency Patterns

### Pattern: Linear Pipeline

**Use Case**: Each phase builds on previous

```markdown
Phase 1 → Phase 2 → Phase 3 → Phase 4
```

**Dependencies**:
```
Phase 1: []
Phase 2: [1]
Phase 3: [2]
Phase 4: [3]
```

**Waves**: 4 waves (no parallelization)

### Pattern: Fan-Out

**Use Case**: One foundation, multiple independent branches

```markdown
        ┌→ Phase 2
Phase 1 ├→ Phase 3
        └→ Phase 4
```

**Dependencies**:
```
Phase 1: []
Phase 2: [1]
Phase 3: [1]
Phase 4: [1]
```

**Waves**: 2 waves (3 phases parallel in Wave 2)

### Pattern: Fan-In

**Use Case**: Multiple independent phases converge to integration

```markdown
Phase 1 ┐
Phase 2 ├→ Phase 4
Phase 3 ┘
```

**Dependencies**:
```
Phase 1: []
Phase 2: []
Phase 3: []
Phase 4: [1, 2, 3]
```

**Waves**: 2 waves (3 phases parallel in Wave 1)

### Pattern: Diamond

**Use Case**: Split, parallel work, then merge

```markdown
        ┌→ Phase 2 ┐
Phase 1 ┤          ├→ Phase 4
        └→ Phase 3 ┘
```

**Dependencies**:
```
Phase 1: []
Phase 2: [1]
Phase 3: [1]
Phase 4: [2, 3]
```

**Waves**: 3 waves (2 phases parallel in Wave 2)

### Pattern: Hybrid (Most Common)

**Use Case**: Mix of sequential and parallel

```markdown
Phase 1 → Phase 2 ┬→ Phase 4 ┐
          Phase 3 ┘          ├→ Phase 6
                   Phase 5 ──┘
```

**Dependencies**:
```
Phase 1: []
Phase 2: [1]
Phase 3: []
Phase 4: [2, 3]
Phase 5: []
Phase 6: [4, 5]
```

**Waves**: 4 waves (mixed parallelization)

---

## Error Handling

### Validation Errors

**Invalid Dependency Number**:

```bash
ERROR: Phase 3: Invalid dependency 'abc' (not a number)
```

**Fix**: Use valid phase numbers (integers)

**Out of Range Dependency**:

```bash
ERROR: Phase 2: Invalid dependency 5 (out of range 1-4)
```

**Fix**: Ensure dependency references existing phase

**Self-Dependency**:

```bash
ERROR: Phase 3: Cannot depend on itself
```

**Fix**: Remove self-dependency from Dependencies list

### Circular Dependency Detection

**Error Message**:

```bash
ERROR: Circular dependency detected in plan: plan.md
Phases involved in cycle: 2 3 4
```

**Debugging**:

1. Review Dependencies fields for phases 2, 3, 4
2. Identify the cycle (e.g., 2→3→4→2)
3. Break the cycle by removing one dependency

**Example Cycle**:

```markdown
Phase 2: Dependencies: [4]  # ✗
Phase 3: Dependencies: [2]
Phase 4: Dependencies: [3]
```

**Fix**: Remove the dependency that completes the cycle

```markdown
Phase 2: Dependencies: []   # ✓ Cycle broken
Phase 3: Dependencies: [2]
Phase 4: Dependencies: [3]
```

### Runtime Execution Errors

**Phase Failure in Wave**:

```bash
ERROR: Phase 3 failed in Wave 2
Phase 2: SUCCESS
Phase 3: FAILED
Phase 4: SUCCESS
```

**Behavior**:
- Abort current wave
- Save checkpoint with partial progress
- Enter debugging loop for failed phase
- Resume from failed phase after fix

---

## Testing and Verification

### Test Dependency Parsing

```bash
# Test dependency parsing for single phase
# Use lib/util/dependency-analyzer.sh instead
deps=$(parse_dependencies "plan.md" 3)
echo "Phase 3 dependencies: $deps"
```

### Test Wave Calculation

```bash
# Test wave calculation for entire plan
waves=$(calculate_execution_waves "plan.md")
echo "Execution waves: $waves"

# Pretty-print waves
echo "$waves" | jq '.'
```

### Test Dependency Validation

```bash
# Test validation
if validate_dependencies "plan.md"; then
  echo "All dependencies valid ✓"
else
  echo "Invalid dependencies found ✗"
fi
```

### Test Circular Dependency Detection

```bash
# Test circular dependency detection
if detect_circular_dependencies "plan.md"; then
  echo "No circular dependencies ✓"
else
  echo "Circular dependencies detected ✗"
fi
```

### Integration Tests

Test wave-based execution with test plans:

```bash
# Run wave execution tests
.claude/tests/test_wave_execution.sh

# Run dependency analysis tests
.claude/tests/test_dependency_analysis.sh
```

---

## API Reference

### Shell Functions

#### parse_dependencies()

Parse dependencies from phase metadata.

```bash
parse_dependencies <plan_file> <phase_number>

# Returns: Space-separated list of phase numbers
# Example: "1 2 3"
```

#### calculate_execution_waves()

Calculate execution waves using Kahn's algorithm.

```bash
calculate_execution_waves <plan_file>

# Returns: JSON array of waves
# Example: [[1],[2,3],[4,5],[6]]
```

#### validate_dependencies()

Validate all dependency references.

```bash
validate_dependencies <plan_file>

# Returns: 0 if valid, 1 if invalid
```

#### detect_circular_dependencies()

Detect circular dependencies in plan.

```bash
detect_circular_dependencies <plan_file>

# Returns: 0 if no cycles, 1 if cycles detected
```

---

## Best Practices

### Planning Phase Dependencies

1. **Explicit is Better**: Always declare `Dependencies: []` even for independent phases
2. **Minimal Dependencies**: Only declare true dependencies, not "nice to have" ordering
3. **Document Reasoning**: Add comments explaining why dependencies exist
4. **Review for Optimization**: Periodically review if dependencies can be removed

### During Implementation

1. **Validate Early**: Run `validate_dependencies` before starting implementation
2. **Visualize Waves**: Review wave structure before execution
3. **Monitor Progress**: Track wave completion in real-time
4. **Adjust If Needed**: Use `/revise` to adjust dependencies if initial plan suboptimal

### Performance Tuning

1. **Profile Wave Distribution**: Aim for balanced waves
2. **Measure Savings**: Track parallelization effectiveness
3. **Iterate**: Refine dependency structure based on actual execution
4. **Document Patterns**: Record effective patterns for future plans

---

## Related Documentation

- **Dependency Analysis Library**: `lib/util/dependency-analyzer.sh`
- **Wave Execution Tests**: `.claude/tests/test_wave_execution.sh`
- **Plan Template**: `.claude/commands/plan.md`
- **Orchestration Patterns**: `orchestration-reference.md`
- **Adaptive Planning**: CLAUDE.md (Adaptive Planning Configuration section)

---

## Examples

### Example 1: CRUD Feature

```markdown
### Phase 1: Database Schema
**Dependencies**: []

### Phase 2: Backend API
**Dependencies**: [1]

### Phase 3: Frontend Components
**Dependencies**: [1]

### Phase 4: Testing
**Dependencies**: [2, 3]
```

**Waves**: `[[1],[2,3],[4]]`
**Parallelization**: 50% (3 waves instead of 4)

### Example 2: Microservices

```markdown
### Phase 1: Shared Infrastructure
**Dependencies**: []

### Phase 2: Auth Service
**Dependencies**: [1]

### Phase 3: User Service
**Dependencies**: [1]

### Phase 4: Product Service
**Dependencies**: [1]

### Phase 5: Order Service
**Dependencies**: [1]

### Phase 6: API Gateway
**Dependencies**: [2, 3, 4, 5]

### Phase 7: Integration Tests
**Dependencies**: [6]
```

**Waves**: `[[1],[2,3,4,5],[6],[7]]`
**Parallelization**: 43% (4 waves instead of 7)

### Example 3: Refactoring

```markdown
### Phase 1: Analysis and Planning
**Dependencies**: []

### Phase 2: Extract Utilities
**Dependencies**: [1]

### Phase 3: Refactor Module A
**Dependencies**: [2]

### Phase 4: Refactor Module B
**Dependencies**: [2]

### Phase 5: Refactor Module C
**Dependencies**: [2]

### Phase 6: Integration Testing
**Dependencies**: [3, 4, 5]
```

**Waves**: `[[1],[2],[3,4,5],[6]]`
**Parallelization**: 33% (4 waves instead of 6)

---

**Last Updated**: 2025-10-16
**Used By**: /orchestrate, /plan, /implement
**Utilities**: # dependency-analysis.sh (removed)
**Tests**: test_wave_execution.sh, test_dependency_analysis.sh
