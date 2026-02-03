# Implementation Plan: Task #37

- **Task**: 37 - implement_topological_sorting_stage6
- **Status**: [COMPLETED]
- **Effort**: 1.5-2 hours
- **Dependencies**: Task #36 (dependency_map capture in Stage 3)
- **Research Inputs**: specs/037_implement_topological_sorting_stage6/reports/research-001.md
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: meta
- **Lean Intent**: false

## Overview

Update meta-builder-agent.md Stage 6 (CreateTasks) to implement Kahn's algorithm for topological sorting of tasks before number assignment. This ensures foundational tasks (those with no or fewer internal dependencies) receive lower task numbers and are created first. The implementation integrates with the dependency_map captured in Stage 3 (Task #36).

### Research Integration

Key findings from research-001.md:
- Current Stage 6 assigns numbers sequentially (lines 447-449), ignoring dependency order
- Kahn's algorithm provides O(V+E) topological sort with built-in cycle detection
- Cycle detection in Stage 6 serves as defense-in-depth (Stage 3 already validates)
- External dependencies do not affect sort order (only internal dependency_map)

## Goals & Non-Goals

**Goals**:
- Implement Kahn's algorithm to sort tasks by dependency order
- Modify task_number_map assignment to use sorted order
- Update task creation loop to iterate in sorted order
- Update DeliverSummary to display tasks in sorted order
- Provide safety cycle detection as defense-in-depth

**Non-Goals**:
- TODO.md insertion ordering (Task #38)
- Dependency graph visualization (Task #39)
- Modifying Stage 3 dependency capture (Task #36)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Algorithm implementation error | High | Low | Include example walkthrough and clear pseudocode |
| Cycle detection false positives | Medium | Low | Cycle should be caught in Stage 3; Stage 6 is safety net only |
| Index off-by-one errors | Medium | Medium | Document 1-indexed task list clearly, test with examples |

## Implementation Phases

### Phase 1: Add Topological Sorting Algorithm [COMPLETED]

**Goal**: Insert Kahn's algorithm pseudocode section before the number assignment loop.

**Tasks**:
- [ ] Read current meta-builder-agent.md Stage 6 section (lines 437-503)
- [ ] Insert new "Topological Sorting" subsection at line 439, before "Dependency Resolution"
- [ ] Add Kahn's algorithm pseudocode with comments explaining each step
- [ ] Include cycle detection as safety check

**Timing**: 30-45 minutes

**Files to modify**:
- `.claude/agents/meta-builder-agent.md` - Insert topological sort section

**Insertion Content**:
```
**Topological Sorting** (required before number assignment):

Sort tasks so foundational tasks receive lower numbers using Kahn's algorithm:

```python
n = len(task_list)

# Build reverse dependency graph: dependents[i] = tasks that depend on i
dependents = {i: [] for i in range(1, n + 1)}
for task_idx, deps in dependency_map.items():
    for dep_idx in deps:
        dependents[dep_idx].append(task_idx)

# Calculate in-degree (number of internal dependencies) for each task
in_degree = {idx: len(dependency_map.get(idx, [])) for idx in range(1, n + 1)}

# Initialize queue with tasks having no internal dependencies
queue = [idx for idx in range(1, n + 1) if in_degree[idx] == 0]

# Process queue (BFS)
sorted_indices = []
while queue:
    current = queue.pop(0)
    sorted_indices.append(current)
    for dependent in dependents[current]:
        in_degree[dependent] -= 1
        if in_degree[dependent] == 0:
            queue.append(dependent)

# Safety check (cycle should have been caught in Stage 3)
if len(sorted_indices) != n:
    ERROR("Internal error: circular dependency detected in Stage 6")
```
```

**Verification**:
- [ ] Topological sort section appears before "Dependency Resolution" heading
- [ ] Pseudocode syntax is correct and readable
- [ ] Comments explain the algorithm clearly

---

### Phase 2: Modify Number Assignment [COMPLETED]

**Goal**: Update the task_number_map loop to use sorted_indices instead of sequential order.

**Tasks**:
- [ ] Locate current number assignment loop (lines 447-449)
- [ ] Replace sequential iteration with sorted_indices iteration
- [ ] Ensure position-based number assignment (first in sorted list gets base_num)

**Timing**: 15-20 minutes

**Files to modify**:
- `.claude/agents/meta-builder-agent.md` - Modify number assignment

**Change From**:
```
for idx in 1..len(task_list):
  task_number_map[idx] = base_num + idx - 1
```

**Change To**:
```
for position, task_idx in enumerate(sorted_indices):
  task_number_map[task_idx] = base_num + position
```

**Verification**:
- [ ] Number assignment uses sorted_indices
- [ ] Position is 0-indexed for correct base_num offset
- [ ] task_idx maps to correct assigned number

---

### Phase 3: Update Task Creation Loop [COMPLETED]

**Goal**: Modify the "For each task" section to iterate over sorted_indices instead of task_list order.

**Tasks**:
- [ ] Locate task creation loop (line 467)
- [ ] Add comment explaining sorted order iteration
- [ ] Modify loop to use sorted_indices with proper index adjustment

**Timing**: 15-20 minutes

**Files to modify**:
- `.claude/agents/meta-builder-agent.md` - Modify task creation loop

**Expected Pattern**:
```
**For each task** (iterate in sorted order, foundational tasks first):

```bash
for position, task_idx in enumerate(sorted_indices):
  task = task_list[task_idx - 1]  # Adjust for 1-based indexing
  task_num = task_number_map[task_idx]
  # ... rest of task creation
```

**Verification**:
- [ ] Loop iterates over sorted_indices
- [ ] Index adjustment handles 1-based task_list
- [ ] task_num is fetched from task_number_map correctly

---

### Phase 4: Update DeliverSummary Section [COMPLETED]

**Goal**: Update Stage 7 to display tasks in their sorted (assigned number) order.

**Tasks**:
- [ ] Locate DeliverSummary "Suggested Order" section (lines 524-527)
- [ ] Update description to reflect tasks are now created in dependency order
- [ ] Ensure output lists tasks by assigned number (which is now sorted order)

**Timing**: 10-15 minutes

**Files to modify**:
- `.claude/agents/meta-builder-agent.md` - Update DeliverSummary

**Expected Content**:
```
**Suggested Order** (tasks numbered in dependency order):
1. Task #{N} (no dependencies) - foundational
2. Task #{N} (depends on #{M}) - builds on above
```

**Verification**:
- [ ] Suggested order reflects dependency-aware numbering
- [ ] Description clarifies tasks are now numbered in correct order

---

### Phase 5: Verify and Test [COMPLETED]

**Goal**: Validate the complete implementation against research examples.

**Tasks**:
- [ ] Read the modified meta-builder-agent.md
- [ ] Trace through the research report example manually:
  - Input: task_list=["Sorting", "Capture", "Schema"], dependency_map={1:[2], 2:[3]}
  - Expected: sorted_indices=[3,2,1], numbers: Schema=37, Capture=38, Sorting=39
- [ ] Verify no syntax errors in pseudocode blocks
- [ ] Check all section references are correct

**Timing**: 20-30 minutes

**Verification**:
- [ ] Example walkthrough produces correct sorted_indices
- [ ] Number assignment follows sorted order
- [ ] File has no markdown formatting errors

## Testing & Validation

- [ ] Manual trace of research report example produces expected output
- [ ] Pseudocode sections have correct markdown code block fencing
- [ ] All line number references in research report are still valid after edits
- [ ] No broken internal references in meta-builder-agent.md

## Artifacts & Outputs

- `.claude/agents/meta-builder-agent.md` - Updated with topological sorting in Stage 6
- `specs/037_implement_topological_sorting_stage6/plans/implementation-001.md` - This plan
- `specs/037_implement_topological_sorting_stage6/summaries/implementation-summary-YYYYMMDD.md` - Post-implementation summary

## Rollback/Contingency

If implementation causes issues:
1. Revert meta-builder-agent.md to previous commit
2. The sequential number assignment (pre-task-36/37) still works for tasks without dependencies
3. Topological sort can be disabled by making sorted_indices = [1, 2, ..., n] (original order)
