# Research Report: Task #39

**Task**: Enhance Stage 7 DeliverSummary dependency visualization
**Date**: 2026-02-03
**Focus**: Analyze meta-builder-agent.md Stage 7 DeliverSummary and identify how to enhance it with dependency graph visualization and execution order based on actual assigned task numbers from topological sort.

## Summary

The current Stage 7 DeliverSummary in meta-builder-agent.md provides a basic list of created tasks with a "Suggested Order" section, but it lacks visual dependency graph representation. Task 37 implemented topological sorting (Kahn's algorithm) which assigns task numbers in dependency order, and Task 38 implemented batch insertion to preserve this order in TODO.md. This task enhances the DeliverSummary output to include ASCII dependency graph visualization showing the relationships between tasks and their actual assigned numbers.

## Findings

### Current DeliverSummary Output (Lines 583-610)

The current Stage 7 DeliverSummary produces:

```
## Tasks Created

Created {N} task(s) for {domain}:

- Task #{N}: {title}
  Path: specs/{NNN}_{slug}/
- Task #{N}: {title} (depends on #{N})
  Path: specs/{NNN}_{slug}/

---

**Next Steps**:
1. Review tasks in TODO.md
2. Run `/research {N}` to begin research on first task
3. Progress through /research -> /plan -> /implement cycle

**Suggested Order** (tasks numbered in dependency order):
1. Task #{N} (no dependencies) - foundational
2. Task #{N} (depends on #{M}) - builds on above

Note: Tasks appear in TODO.md in dependency order (foundational tasks at top).
Lower task numbers indicate foundational tasks that should be completed first.
Work through tasks from top to bottom in the TODO.md file.
```

**Limitations**:
1. No visual representation of the dependency DAG
2. "Suggested Order" uses generic placeholders rather than actual task numbers
3. Dependency relationships are mentioned inline but not visualized
4. Complex dependency patterns (diamond, parallel) are not clearly communicated

### Data Available After Task Creation

After Stage 6 CreateTasks completes, the following data structures are available:

| Variable | Content | Example |
|----------|---------|---------|
| `task_list[]` | Original task descriptions | `["Sort tasks", "Capture deps", "Add schema"]` |
| `sorted_indices[]` | Topologically sorted task indices | `[3, 2, 1]` |
| `task_number_map{}` | Index -> assigned task number | `{3: 37, 2: 38, 1: 39}` |
| `dependency_map{}` | Index -> internal dependency indices | `{1: [2], 2: [3]}` |
| `external_dependencies{}` | Index -> external task numbers | `{3: [35]}` |

This data is sufficient to generate a dependency graph visualization.

### ASCII Dependency Graph Patterns

Research into CLI dependency visualization reveals several established patterns:

#### 1. Linear Chain Pattern

For simple linear dependencies (A -> B -> C):
```
#37: Add schema (foundational)
  |
  v
#38: Capture deps
  |
  v
#39: Sort tasks
```

#### 2. Tree/Branch Pattern

For tasks with multiple dependents:
```
#37: Schema
  |
  +---> #38: Capture
  |       |
  |       v
  |     #40: Validate
  |
  +---> #39: Sort
```

#### 3. Diamond Pattern

For converging dependencies:
```
    #37: Schema
      |
  +---+---+
  |       |
  v       v
#38     #39
  |       |
  +---+---+
      |
      v
    #40: Integrate
```

#### 4. Topological Order List with Arrows

For clear execution order (recommended for this use case):
```
Execution Order:
  #37 ─────┐
           │──> #39
  #38 ─────┘
           │
           v
         #40
```

### Codebase Box-Drawing Standards

From `/home/benjamin/.config/nvim/CLAUDE.md` (lines 77-121) and `/home/benjamin/.config/nvim/.claude/rules/workflows.md`, the project uses Unicode box-drawing characters:

| Character | Unicode | Usage |
|-----------|---------|-------|
| `┌` | U+250C | Top left corner |
| `┐` | U+2510 | Top right corner |
| `└` | U+2514 | Bottom left corner |
| `┘` | U+2518 | Bottom right corner |
| `─` | U+2500 | Horizontal line |
| `│` | U+2502 | Vertical line |
| `├` | U+251C | Vertical with right branch |
| `┤` | U+2524 | Vertical with left branch |
| `┬` | U+252C | Horizontal with down branch |
| `┴` | U+2534 | Horizontal with up branch |
| `┼` | U+253C | Four-way intersection |
| `▼` or `v` | - | Downward arrow (flow direction) |

### Best Practices from Research

From [ASCII DAG](https://github.com/AshutoshMahala/ascii-dag) and [Spack CLI Visualization](https://arxiv.org/abs/1908.07544):

1. **Left-to-right or top-to-bottom flow**: Foundational items at top/left, dependent items at bottom/right
2. **Numbered nodes**: Use actual assigned task numbers for clarity
3. **Edge labels optional**: For small graphs, edge labels add clutter
4. **Colored edges**: ANSI colors can distinguish different dependency chains (optional)
5. **Compact representation**: For CLI output, vertical compactness is preferred

### Recommended Visualization Format

Given the constraints (CLI output, variable number of tasks, Unicode box-drawing preference), the recommended format combines:

1. **Numbered list with execution order** (always present)
2. **ASCII DAG for complex dependencies** (when >2 tasks with non-linear dependencies)
3. **Simple list for linear/no dependencies** (when dependencies are trivial)

#### Proposed DeliverSummary Enhancement

**For simple cases (linear or no dependencies)**:
```
## Tasks Created

Created 3 task(s) for meta changes:

| # | Task | Depends On | Path |
|---|------|------------|------|
| 37 | Add schema | None | specs/037_add_schema/ |
| 38 | Capture deps | #37 | specs/038_capture_deps/ |
| 39 | Sort tasks | #38 | specs/039_sort_tasks/ |

**Execution Order** (foundational first):
  [37] Add schema
    |
    v
  [38] Capture deps
    |
    v
  [39] Sort tasks

**Next Steps**:
1. Run `/research 37` to begin research on first task
2. Progress: #37 -> #38 -> #39
```

**For complex cases (diamond, parallel branches)**:
```
## Tasks Created

Created 4 task(s) for feature X:

| # | Task | Depends On | Path |
|---|------|------------|------|
| 37 | Schema | None | specs/037_schema/ |
| 38 | Parser | #37 | specs/038_parser/ |
| 39 | Validator | #37 | specs/039_validator/ |
| 40 | Integrate | #38, #39 | specs/040_integrate/ |

**Dependency Graph**:
```
         [37] Schema
              |
        +-----+-----+
        |           |
        v           v
  [38] Parser  [39] Validator
        |           |
        +-----+-----+
              |
              v
        [40] Integrate
```

**Execution Order**:
1. #37: Schema (no dependencies)
2. #38: Parser (after #37)  \
                              > can run in parallel
3. #39: Validator (after #37)/
4. #40: Integrate (after #38 and #39)

**Next Steps**:
1. Run `/research 37` to begin research
2. Tasks #38 and #39 can be researched in parallel after #37 completes
```

### Complexity Detection

To determine whether to show simple or complex visualization:

```python
def is_complex_dag(dependency_map, n):
    """
    Returns True if the DAG has complex structure requiring full visualization.
    Complex = diamond patterns, parallel branches, or >3 tasks with non-linear deps.
    """
    # Count tasks with multiple dependencies
    multi_dep_count = sum(1 for deps in dependency_map.values() if len(deps) > 1)

    # Count tasks that are depended on by multiple tasks
    dep_counts = {}
    for task_idx, deps in dependency_map.items():
        for dep in deps:
            dep_counts[dep] = dep_counts.get(dep, 0) + 1
    multi_dependent_count = sum(1 for count in dep_counts.values() if count > 1)

    # Complex if: diamond pattern, multiple branches, or many tasks
    return multi_dep_count > 0 or multi_dependent_count > 0 or n > 3
```

### Graph Generation Algorithm

For generating the ASCII dependency graph:

```python
def generate_dependency_graph(task_list, sorted_indices, task_number_map, dependency_map):
    """
    Generate ASCII dependency graph visualization.

    Returns string suitable for markdown code block.
    """
    n = len(task_list)

    # Build reverse map: task_idx -> dependents (tasks that depend on it)
    dependents = {i: [] for i in range(1, n + 1)}
    for task_idx, deps in dependency_map.items():
        for dep_idx in deps:
            dependents[dep_idx].append(task_idx)

    # For simple linear chains, use vertical format
    if is_linear_chain(dependency_map, n):
        return generate_linear_graph(task_list, sorted_indices, task_number_map)

    # For complex DAGs, use layered format
    return generate_layered_graph(task_list, sorted_indices, task_number_map, dependency_map, dependents)


def is_linear_chain(dependency_map, n):
    """Check if DAG is a simple linear chain (each task has at most 1 dependency)."""
    for deps in dependency_map.values():
        if len(deps) > 1:
            return False
    return True


def generate_linear_graph(task_list, sorted_indices, task_number_map):
    """Generate simple vertical chain visualization."""
    lines = []
    for i, task_idx in enumerate(sorted_indices):
        task_num = task_number_map[task_idx]
        task = task_list[task_idx - 1]
        title = task['title'][:30]  # Truncate for display

        lines.append(f"  [{task_num}] {title}")
        if i < len(sorted_indices) - 1:
            lines.append("    |")
            lines.append("    v")

    return "\n".join(lines)
```

### External Dependencies Handling

External dependencies (on existing tasks like #35, #36) should be displayed differently:

```
**Dependency Graph**:
```
  External: #35, #36
              |
              v
         [37] Schema
              |
              v
         [38] Parser
```

### Integration Points in meta-builder-agent.md

The enhancement requires modifications to:

| Location | Current | Proposed Change |
|----------|---------|-----------------|
| Lines 583-610 | Stage 7 DeliverSummary template | Add dependency graph section |
| After line 581 | Batch insertion explanation | Add graph generation pseudocode |
| Lines 700-703 | Output format description | Reference graph generation |

## Recommendations

### 1. Add Dependency Graph Generation Section

Insert after line 581 (before DeliverSummary):

```markdown
**Dependency Graph Generation** (for DeliverSummary output):

After batch insertion, generate ASCII visualization of the dependency DAG:

```python
def generate_execution_summary(task_list, sorted_indices, task_number_map, dependency_map, external_deps):
    """
    Generate execution order and dependency graph for DeliverSummary.

    Args:
        task_list: Original task list
        sorted_indices: Topologically sorted indices
        task_number_map: Index -> assigned task number
        dependency_map: Index -> internal dependency indices
        external_deps: Index -> external task numbers

    Returns:
        (table_str, graph_str, order_str): Tuple of formatted strings
    """
    # 1. Build task table with actual numbers
    table_lines = ["| # | Task | Depends On | Path |", "|---|------|------------|------|"]
    for task_idx in sorted_indices:
        task_num = task_number_map[task_idx]
        task = task_list[task_idx - 1]

        # Format dependencies (internal + external)
        all_deps = []
        for dep_idx in dependency_map.get(task_idx, []):
            all_deps.append(f"#{task_number_map[dep_idx]}")
        for ext_num in external_deps.get(task_idx, []):
            all_deps.append(f"#{ext_num}")
        dep_str = ", ".join(all_deps) if all_deps else "None"

        padded = f"{task_num:03d}"
        table_lines.append(f"| {task_num} | {task['title']} | {dep_str} | specs/{padded}_{task['slug']}/ |")

    # 2. Generate graph visualization
    # (See complexity detection and graph generation algorithms)

    # 3. Generate execution order
    order_lines = ["**Execution Order**:"]
    for position, task_idx in enumerate(sorted_indices):
        task_num = task_number_map[task_idx]
        deps = dependency_map.get(task_idx, [])
        if not deps:
            order_lines.append(f"{position + 1}. #{task_num}: {task_list[task_idx - 1]['title']} (foundational)")
        else:
            dep_nums = [task_number_map[d] for d in deps]
            order_lines.append(f"{position + 1}. #{task_num}: {task_list[task_idx - 1]['title']} (after #{', #'.join(map(str, dep_nums))})")

    return "\n".join(table_lines), graph_str, "\n".join(order_lines)
```
```

### 2. Update DeliverSummary Template

Replace lines 585-610 with enhanced format:

```markdown
**Output**:
```
## Tasks Created

Created {N} task(s) for {domain}:

{task_table}

{dependency_graph}

{execution_order}

---

**Next Steps**:
1. Run `/research {first_task_num}` to begin research on foundational task
2. Work through tasks in order shown above
3. Progress through /research -> /plan -> /implement cycle for each task

Note: Tasks are numbered and ordered by dependency. Complete foundational tasks first.
Parallel execution is possible for tasks with the same dependencies.
```

Where:
- `{task_table}` = Markdown table with columns: #, Task, Depends On, Path
- `{dependency_graph}` = ASCII DAG visualization (for complex deps) or omitted (for simple linear)
- `{execution_order}` = Numbered list with dependency annotations
- `{first_task_num}` = Lowest assigned task number (first in sorted_indices)
```

### 3. Add Example Outputs

Include concrete examples in the agent documentation:

**Example 1: Linear Chain (3 tasks)**
```
## Tasks Created

Created 3 task(s) for dependency visualization:

| # | Task | Depends On | Path |
|---|------|------------|------|
| 37 | Implement sorting | #38 | specs/037_implement_sorting/ |
| 38 | Update insertion | #39 | specs/038_update_insertion/ |
| 39 | Add visualization | None | specs/039_add_visualization/ |

**Execution Order**:
  [39] Add visualization
    |
    v
  [38] Update insertion
    |
    v
  [37] Implement sorting

---

**Next Steps**:
1. Run `/research 39` to begin research on foundational task
```

**Example 2: Diamond Pattern (4 tasks)**
```
## Tasks Created

Created 4 task(s) for feature implementation:

| # | Task | Depends On | Path |
|---|------|------------|------|
| 37 | Core API | None | specs/037_core_api/ |
| 38 | Parser | #37 | specs/038_parser/ |
| 39 | Validator | #37 | specs/039_validator/ |
| 40 | Integration | #38, #39 | specs/040_integration/ |

**Dependency Graph**:
```
         [37] Core API
              |
        +-----+-----+
        |           |
        v           v
  [38] Parser  [39] Validator
        |           |
        +-----+-----+
              |
              v
       [40] Integration
```

**Execution Order**:
1. #37: Core API (foundational)
2. #38: Parser (after #37)     \_ can run in parallel
3. #39: Validator (after #37)  /
4. #40: Integration (after #38 and #39)

---

**Next Steps**:
1. Run `/research 37` to begin research on foundational task
2. After #37, tasks #38 and #39 can be researched in parallel
```

## Implementation Scope

**In scope for task 39**:
1. Add dependency graph generation algorithm to meta-builder-agent.md
2. Update DeliverSummary template with graph visualization section
3. Add complexity detection to choose simple vs complex visualization
4. Include example outputs for linear and diamond patterns
5. Handle external dependencies display

**Out of scope**:
- Interactive graph manipulation
- Color coding (requires ANSI terminal support detection)
- Graphviz/DOT output format
- Real-time graph updates

## References

- `.claude/agents/meta-builder-agent.md` - Lines 439-471 (topological sorting), 541-581 (batch insertion), 583-610 (DeliverSummary)
- `specs/037_implement_topological_sorting_stage6/reports/research-001.md` - Topological sorting design
- `specs/038_update_todomd_insertion_dependency_order/reports/research-001.md` - Batch insertion pattern
- `/home/benjamin/.config/nvim/CLAUDE.md` - Lines 77-121 (Unicode box-drawing standards)
- `.claude/rules/workflows.md` - Workflow diagram examples
- [ASCII DAG - GitHub](https://github.com/AshutoshMahala/ascii-dag) - Lightweight DAG renderer patterns
- [Spack CLI Visualization Paper](https://arxiv.org/abs/1908.07544) - ASCII DAG visualization best practices
- [oo-ascii-tree - npm](https://www.npmjs.com/package/oo-ascii-tree) - Tree rendering patterns

## Next Steps

1. Proceed to planning phase with `/plan 39`
2. Plan should modify meta-builder-agent.md Stage 7 in these locations:
   - After line 581: Insert dependency graph generation algorithm
   - Lines 585-610: Replace DeliverSummary template with enhanced format
   - After line 610: Add example outputs section
