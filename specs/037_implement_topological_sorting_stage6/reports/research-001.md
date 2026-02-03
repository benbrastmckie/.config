# Research Report: Task #37

**Task**: Implement topological sorting in Stage 6 CreateTasks
**Date**: 2026-02-03
**Focus**: Analyze meta-builder-agent.md Stage 6 CreateTasks to understand task creation flow, research topological sorting algorithms for dependency graphs, and identify where to insert sorting logic so foundational tasks get lower numbers

## Summary

Stage 6 (CreateTasks) in meta-builder-agent.md currently assigns task numbers sequentially based on input order (task_list index), ignoring the dependency_map captured in Stage 3. This means if a user lists "Task B" before "Task A" but declares "Task B depends on Task A", Task B incorrectly gets a lower number than Task A. Topological sorting using Kahn's algorithm will reorder tasks so foundational tasks (those with no dependencies or only external dependencies) receive lower numbers, ensuring proper execution order.

## Findings

### Current Stage 6 Number Assignment (Lines 439-449)

The current implementation assigns numbers sequentially:

```
# Task index -> assigned task number
task_number_map = {}
base_num = next_project_number from state.json

for idx in 1..len(task_list):
  task_number_map[idx] = base_num + idx - 1
```

**Problem**: This assigns numbers based on user input order, not dependency order. If user lists tasks as:
1. "Implement topological sorting" (depends on task 2)
2. "Add dependencies field schema"

Then task 1 gets number 37 and task 2 gets number 38, but task 37 depends on task 38 - an inverted numbering.

### Dependency Data Structures (from Task 36)

Stage 3 captures:
- `task_list[]`: Array of task titles/descriptions (1-indexed for user clarity)
- `dependency_map{}`: Map of task index -> [dependency indices] (internal dependencies)
- `external_dependencies{}`: Map of task index -> [existing task numbers] (external dependencies)

**Example**:
```
task_list = ["Sort tasks", "Capture dependencies", "Add schema"]
dependency_map = {1: [2], 2: [3]}  # Task 1 depends on 2, Task 2 depends on 3
external_dependencies = {3: [35]}  # Task 3 depends on existing task #35
```

**Desired output**: Task 3 gets number 37, Task 2 gets 38, Task 1 gets 39.

### Topological Sorting with Kahn's Algorithm

Kahn's algorithm is the ideal choice for this problem because:
1. It naturally produces tasks in dependency order (foundational first)
2. It inherently detects cycles (if not all tasks are processed, a cycle exists)
3. It has O(V+E) time complexity, which is optimal
4. It is easy to understand and implement in pseudocode

**Algorithm Steps**:

1. **Build in-degree map**: For each task, count how many internal dependencies it has
2. **Initialize queue**: Add all tasks with in-degree 0 (no internal dependencies) to a queue
3. **Process queue**: Remove a task from queue, add to sorted output, decrease in-degree of tasks that depend on it
4. **Repeat**: Continue until queue is empty
5. **Detect cycle**: If sorted output has fewer tasks than task_list, a cycle exists

### Pseudocode for Stage 6

```python
def topological_sort(task_list, dependency_map):
    """
    Sort tasks so foundational tasks come first.

    Args:
        task_list: Array of task descriptions (1-indexed conceptually)
        dependency_map: {task_idx: [dep_idx, ...]} where dep_idx are indices this task depends on

    Returns:
        sorted_indices: List of task indices in topological order (foundational first)

    Raises:
        CycleError: If circular dependency detected
    """
    n = len(task_list)

    # Build reverse dependency graph: who depends on whom
    # dependents[i] = list of task indices that depend on task i
    dependents = {i: [] for i in range(1, n + 1)}
    for task_idx, deps in dependency_map.items():
        for dep_idx in deps:
            dependents[dep_idx].append(task_idx)

    # Calculate in-degree (number of internal dependencies) for each task
    in_degree = {}
    for idx in range(1, n + 1):
        in_degree[idx] = len(dependency_map.get(idx, []))

    # Initialize queue with tasks having no internal dependencies (in-degree = 0)
    queue = []
    for idx in range(1, n + 1):
        if in_degree[idx] == 0:
            queue.append(idx)

    # Process queue
    sorted_indices = []
    while queue:
        # Remove task from queue (FIFO for stability)
        current = queue.pop(0)
        sorted_indices.append(current)

        # Decrease in-degree of tasks that depend on this one
        for dependent_idx in dependents[current]:
            in_degree[dependent_idx] -= 1
            if in_degree[dependent_idx] == 0:
                queue.append(dependent_idx)

    # Cycle detection
    if len(sorted_indices) != n:
        raise CycleError("Circular dependency detected - not all tasks could be ordered")

    return sorted_indices
```

### Integration into Stage 6

**Current flow** (lines 439-465):
1. Build task_number_map sequentially
2. Merge dependencies
3. Create tasks one by one

**Proposed flow**:
1. **NEW**: Apply topological sort to get sorted_indices
2. Build task_number_map using sorted order
3. Merge dependencies (no change)
4. Create tasks in sorted order (foundational first)

**Specific insertion point**: Before line 442 (before the `for idx in 1..len(task_list):` loop)

### Example Walkthrough

**Input**:
```
task_list = ["Implement sorting", "Capture dependencies", "Add schema"]
dependency_map = {1: [2], 2: [3]}  # 1 depends on 2, 2 depends on 3
external_dependencies = {}
next_project_number = 37
```

**Step 1: Build dependents map** (reverse graph):
```
dependents = {
  1: [],      # Nothing depends on task 1
  2: [1],     # Task 1 depends on task 2
  3: [2]      # Task 2 depends on task 3
}
```

**Step 2: Calculate in-degrees**:
```
in_degree = {
  1: 1,  # Task 1 has 1 internal dependency (task 2)
  2: 1,  # Task 2 has 1 internal dependency (task 3)
  3: 0   # Task 3 has 0 internal dependencies
}
```

**Step 3: Initialize queue** with in-degree 0:
```
queue = [3]
```

**Step 4: Process queue**:
- Pop 3, sorted = [3], decrease in_degree[2] to 0, enqueue 2
- Pop 2, sorted = [3, 2], decrease in_degree[1] to 0, enqueue 1
- Pop 1, sorted = [3, 2, 1]

**Step 5: Build task_number_map using sorted order**:
```
sorted_indices = [3, 2, 1]
task_number_map = {
  3: 37,  # "Add schema" gets number 37 (first)
  2: 38,  # "Capture dependencies" gets number 38 (second)
  1: 39   # "Implement sorting" gets number 39 (last)
}
```

**Result**: Tasks are numbered correctly - foundational tasks get lower numbers.

### Cycle Detection Already Exists in Stage 3

Task 36 added cycle detection validation in Stage 3 (lines 310-326). This means:
- Cycles should already be caught during dependency capture
- Stage 6 cycle detection is a safety net (defense in depth)
- If Stage 6 detects a cycle, it indicates a bug in Stage 3 validation

### External Dependencies Handling

External dependencies (on existing tasks like #35, #36) do not affect topological sort because:
- They reference tasks that already have numbers assigned
- They are added during the "merge dependencies" step (lines 451-465)
- Only internal dependencies (dependency_map) determine sort order

### Edge Cases

1. **No dependencies**: All tasks have in-degree 0, any order is valid. Use original order for stability.

2. **Linear chain**: 1 -> 2 -> 3. Result: [3, 2, 1] (reversed order).

3. **Diamond pattern**: 1 -> 2, 1 -> 3, 2 -> 4, 3 -> 4. Result: [4, 2, 3, 1] or [4, 3, 2, 1] (both valid).

4. **Single task**: Returns [1].

5. **All tasks depend on external task #35**: All have in-degree 0 (internal), any order valid.

## Recommendations

### 1. Insert Topological Sort Section Before Number Assignment

Add new subsection **Topological Sorting** at line 439, before "Before creating tasks, build a mapping":

```markdown
**Topological Sorting** (required before number assignment):

Sort tasks so foundational tasks (those with no or fewer internal dependencies) receive lower numbers:

```python
# Kahn's Algorithm implementation
n = len(task_list)

# Build reverse dependency graph
dependents = {i: [] for i in range(1, n + 1)}
for task_idx, deps in dependency_map.items():
    for dep_idx in deps:
        dependents[dep_idx].append(task_idx)

# Calculate in-degrees
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

### 2. Modify Number Assignment to Use Sorted Order

Change lines 447-449 from:

```
for idx in 1..len(task_list):
  task_number_map[idx] = base_num + idx - 1
```

To:

```
for position, task_idx in enumerate(sorted_indices):
  task_number_map[task_idx] = base_num + position
```

### 3. Create Tasks in Sorted Order

Change the "For each task" section (line 467) to iterate over sorted_indices:

```
for position, task_idx in enumerate(sorted_indices):
  task = task_list[task_idx - 1]  # Adjust for 1-based indexing
  task_num = task_number_map[task_idx]
  # ... rest of task creation
```

### 4. Update Stage 7 DeliverSummary

The "Suggested Order" section at line 524 should be updated to list tasks in the sorted order (which now matches the assigned number order).

## Implementation Scope

**In scope for task 37**:
1. Add topological sorting pseudocode/algorithm section
2. Modify task_number_map assignment to use sorted order
3. Ensure task creation loop uses sorted order
4. Update DeliverSummary if needed

**Out of scope**:
- TODO.md insertion ordering (task 38)
- Dependency graph visualization (task 39)

## References

- [Topological Sorting using BFS - Kahn's Algorithm (GeeksforGeeks)](https://www.geeksforgeeks.org/dsa/topological-sorting-indegree-based-solution/)
- [Topological sorting - Wikipedia](https://en.wikipedia.org/wiki/Topological_sorting)
- [Topological Sorting Explained: A Step-by-Step Guide for Dependency Resolution (Medium)](https://medium.com/@amit.anjani89/topological-sorting-explained-a-step-by-step-guide-for-dependency-resolution-1a6af382b065)
- `/home/benjamin/.config/nvim/.claude/agents/meta-builder-agent.md` - Lines 437-503 (Stage 6 CreateTasks)
- `/home/benjamin/.config/nvim/specs/036_enhance_interview_stage3_dependency_capture/reports/research-001.md` - Dependency capture design

## Next Steps

1. Proceed to planning phase with `/plan 37`
2. Plan should modify meta-builder-agent.md Stage 6 in these locations:
   - Line ~439: Insert topological sorting algorithm before number assignment
   - Lines 447-449: Modify number assignment to use sorted order
   - Line ~467: Modify task creation loop to iterate sorted order
   - Lines 524-527: Update DeliverSummary suggested order section
