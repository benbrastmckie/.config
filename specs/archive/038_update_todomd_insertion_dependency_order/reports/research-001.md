# Research Report: Task #38

**Task**: Update TODO.md insertion for dependency order
**Date**: 2026-02-03
**Focus**: Analyze current TODO.md insertion logic in meta-builder-agent.md Stage 6 and identify how to modify insertion order so foundational tasks (those with no dependencies) appear higher in the file.

## Summary

The current TODO.md insertion logic in meta-builder-agent.md Stage 6 always prepends new task entries to the `## Tasks` section, placing them at the top of the file. Task 37 implemented topological sorting for task number assignment (foundational tasks get lower numbers), but the insertion order into TODO.md still prepends all tasks - meaning the last task created (highest number, most dependencies) appears at the top of TODO.md rather than the foundational tasks (lowest numbers). This task needs to modify the insertion logic so tasks are inserted in topological order (foundational tasks higher/earlier in the file).

## Findings

### Current TODO.md Insertion Mechanism (Stage 6 CreateTasks)

**Location**: `.claude/agents/meta-builder-agent.md` lines 747-757 (Stage 6: Status Updates)

The current documentation states:

```markdown
## Stage 6: Status Updates (Interactive/Prompt Only)

For each created task:

1. **Update TODO.md**:
   - Prepend task entry to `## Tasks` section
   - Include all required fields
```

**Problem**: After Task 37's topological sorting implementation, tasks are now numbered correctly (foundational tasks get lower numbers), and the task creation loop iterates in sorted order. However, the instruction to "prepend to `## Tasks` section" means:

1. Task 37 (foundational) is created first, prepended to top
2. Task 38 is created second, prepended to top (now above 37)
3. Task 39 is created third, prepended to top (now above 38 and 37)

**Result**: The most dependent task ends up at the top of TODO.md, and foundational tasks sink to the bottom - the opposite of the intended dependency ordering.

### Task 37's Topological Sorting Implementation

**Location**: `.claude/agents/meta-builder-agent.md` lines 439-471 (Topological Sorting section)

Task 37 implemented Kahn's algorithm to sort tasks before number assignment:

```python
# sorted_indices = [3, 2, 1] for tasks where 1 depends on 2, 2 depends on 3
# Task 3 (foundational) gets lowest number
# Task 1 (most dependencies) gets highest number
```

The task creation loop (lines 502-515) iterates in sorted order:

```
for position, task_idx in enumerate(sorted_indices):
  task = task_list[task_idx - 1]
  task_num = task_number_map[task_idx]
  # ... create task
```

**Key insight**: Tasks are already being CREATED in the correct order (foundational first). The issue is purely in the TODO.md INSERTION strategy.

### Current Prepend Pattern in Codebase

Multiple files reference the prepend pattern:

| File | Line | Current Instruction |
|------|------|---------------------|
| meta-builder-agent.md | 752 | `Prepend task entry to \`## Tasks\` section` |
| task.md | 146 | `Part B - Add task entry by prepending to \`## Tasks\` section` |
| task.md | 156 | `Insertion: Use sed or Edit to insert the new task entry immediately after the \`## Tasks\` line` |
| task.md | 222 | `Update TODO.md: Prepend recovered task entry to \`## Tasks\` section` |
| skill-learn/SKILL.md | 561 | `Prepend new task entry to \`## Tasks\` section (new tasks at top)` |
| state-management.md | 20 | `Single \`## Tasks\` section (new tasks prepended at top)` |
| task-management.md | 81 | `Prepend new tasks to the \`## Tasks\` section (new tasks at top, older tasks sink down)` |

**Note**: These references are for SINGLE task creation (e.g., `/task` command). The meta-builder-agent is the only component that creates MULTIPLE tasks in a batch with dependencies.

### Proposed Solution: Reverse Iteration for Insertion

For multi-task batch creation with dependencies, the insertion order should be reversed:

**Current flow** (problematic):
```
sorted_indices = [3, 2, 1]  # foundational first
for task_idx in sorted_indices:  # iterate 3, 2, 1
  prepend_to_todo(task)          # 3 added, then 2 above, then 1 above
# Result: 1 at top, 3 at bottom (wrong!)
```

**Proposed flow** (correct):
```
sorted_indices = [3, 2, 1]  # foundational first
for task_idx in reversed(sorted_indices):  # iterate 1, 2, 3
  prepend_to_todo(task)          # 1 added, then 2 above, then 3 above
# Result: 3 at top, 1 at bottom (correct!)
```

**Alternative approach** (append instead of prepend):
```
sorted_indices = [3, 2, 1]  # foundational first
# Find insertion point after existing tasks or at start of section
for task_idx in sorted_indices:  # iterate 3, 2, 1
  append_after_previous(task)    # 3 added, then 2 below, then 1 below
# Result: 3 at top of new batch, 1 at bottom (correct!)
```

### Analysis of Both Approaches

**Approach 1: Reverse iteration with prepend**

Pros:
- Minimal change to existing prepend logic
- Each task is still prepended individually
- Works with existing sed/Edit patterns

Cons:
- Counterintuitive: iterate in reverse of sorted order
- Documentation must explain why we reverse
- Confuses the "foundational first" narrative from Stage 6

**Approach 2: Batch insertion with append semantics** (RECOMMENDED)

Pros:
- Aligns with "foundational first" narrative
- Tasks are inserted in creation order
- Clearer mental model: create in order, insert in order
- Future-proof for visualization improvements (Task 39)

Cons:
- Requires more complex insertion logic
- Must track insertion point (after last inserted task)
- May need different sed pattern

### Recommended Implementation

**Approach 2** is recommended because it maintains the logical flow where foundational tasks are processed first AND end up first in the file.

**Implementation steps**:

1. **Find insertion anchor** - locate `## Tasks` heading
2. **Insert batch as a unit** - instead of prepending each task individually:
   - Build the complete markdown block for all tasks (in sorted order)
   - Insert the entire block after `## Tasks` heading
3. **Prepend semantic preserved** - the batch as a whole is "prepended" to existing tasks

**Pseudocode**:
```python
# Stage 6: CreateTasks (modified)

# Build all task entries in sorted order
task_entries = []
for position, task_idx in enumerate(sorted_indices):
  task = task_list[task_idx - 1]
  task_num = task_number_map[task_idx]
  entry = format_todo_entry(task, task_num)
  task_entries.append(entry)

# Join all entries with newlines
batch_markdown = "\n\n---\n\n".join(task_entries)

# Insert entire batch after ## Tasks heading
# This preserves: new batch at top, existing tasks below
insert_after_heading("## Tasks", batch_markdown)
```

### Edge Cases

#### 1. Tasks with no dependencies (all foundational)

When `dependency_map = {}`, all tasks have in-degree 0, and Kahn's algorithm returns them in original input order (stable sort). Insertion should work the same way - preserve original order.

**Behavior**: Tasks appear in the order the user listed them, which is intuitive.

#### 2. Single task (no batch)

When only one task is created, both approaches are equivalent. Prepend the single task.

**Behavior**: No change from current behavior.

#### 3. External dependencies only

Tasks may only have external dependencies (on existing tasks like #35, #36). These do not affect topological sort order (only internal dependencies do).

**Behavior**: Tasks with only external dependencies are treated as foundational (in-degree 0 for internal deps).

#### 4. Mixed internal and external dependencies

A task may depend on both internal (new) and external (existing) tasks. The topological sort only considers internal dependencies for ordering. External dependencies are recorded in the TODO.md entry but don't affect insertion position.

**Behavior**: Correctly handled by current topological sort. Insertion follows internal dependency order.

### Files Requiring Modification

| File | Change |
|------|--------|
| `.claude/agents/meta-builder-agent.md` | Stage 6 CreateTasks - change TODO.md insertion to batch insert in sorted order |

### Files NOT Requiring Modification

| File | Reason |
|------|--------|
| `task.md` | Creates single tasks only, prepend is correct |
| `skill-learn/SKILL.md` | Creates single tasks only, prepend is correct |
| `state-management.md` | General rule for single-task prepend is correct |
| `task-management.md` | General guidance, not implementation detail |

### Consistency with Existing Standards

The change is **additive** and **scoped**:

- **Single task creation** continues to prepend (no change to `/task`, `/learn`, etc.)
- **Multi-task batch creation** with dependencies uses batch insertion (meta-builder-agent only)
- **state.json** ordering is unaffected (uses `active_projects` array, new tasks prepended)
- **Documentation standards** remain valid (state-management.md describes general principle)

## Recommendations

### 1. Modify Stage 6 CreateTasks in meta-builder-agent.md

Update lines 751-753 to specify batch insertion semantics:

**From**:
```markdown
1. **Update TODO.md**:
   - Prepend task entry to `## Tasks` section
   - Include all required fields
```

**To**:
```markdown
1. **Update TODO.md** (batch insertion in sorted order):
   - Build all task entries as a markdown block, ordered by sorted_indices (foundational first)
   - Insert the entire batch after `## Tasks` heading (before existing tasks)
   - This ensures foundational tasks appear higher in the file
   - Each entry uses standard TODO.md entry format (see below)
```

### 2. Update Task Creation Loop Description

Update lines 502-515 to clarify the batch building:

**Add after "For each task (iterate in sorted order)"**:
```markdown
**Building the batch**: Each task entry is formatted and collected in order.
The complete batch is then inserted into TODO.md as a single operation.

**Single insertion**: Rather than prepending each task individually (which would
reverse the order), the entire batch is inserted at once, preserving the sorted
order where foundational tasks appear first.
```

### 3. Add Implementation Guidance

Add concrete implementation pattern:

```markdown
**TODO.md Batch Insertion Pattern**:

```bash
# Build batch markdown (foundational tasks first in string)
batch=""
for position, task_idx in enumerate(sorted_indices):
  task = task_list[task_idx - 1]
  task_num = task_number_map[task_idx]

  entry="### ${task_num}. ${task[title]}
- **Effort**: ${task[effort]}
- **Status**: [NOT STARTED]
- **Language**: ${task[language]}
- **Dependencies**: $(format_deps task_idx)

**Description**: ${task[description]}

---"

  batch="${batch}${entry}\n\n"
done

# Insert batch after ## Tasks heading (sed or Edit tool)
# The batch as a whole is prepended to existing tasks
```
```

## Implementation Scope

**In scope for task 38**:
1. Modify Stage 6 TODO.md insertion logic to batch insert in sorted order
2. Update associated documentation in meta-builder-agent.md
3. Ensure DeliverSummary (Stage 7) output reflects correct file order

**Out of scope**:
- Single-task commands (`/task`, `/learn`, etc.) - these correctly prepend
- state.json ordering - unaffected by TODO.md changes
- Dependency visualization (Task 39)

## References

- `.claude/agents/meta-builder-agent.md` - Lines 502-515 (CreateTasks loop), 747-757 (Status Updates)
- `specs/037_implement_topological_sorting_stage6/reports/research-001.md` - Topological sorting design
- `specs/037_implement_topological_sorting_stage6/summaries/implementation-summary-20260203.md` - Task 37 implementation details
- `.claude/rules/state-management.md` - Lines 17-20 (TODO.md canonical source)
- `.claude/commands/task.md` - Lines 146-156 (single task prepend pattern)

## Next Steps

1. Proceed to planning phase with `/plan 38`
2. Plan should modify meta-builder-agent.md Stage 6 in these locations:
   - Lines 751-753: Update TODO.md update description for batch semantics
   - Lines 502-515: Add batch building and insertion logic
   - Lines 541-567 (DeliverSummary): Verify output reflects correct order
