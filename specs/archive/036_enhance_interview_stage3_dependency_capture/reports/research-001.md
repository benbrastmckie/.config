# Research Report: Task #36

**Task**: Enhance interview Stage 3 dependency capture
**Date**: 2026-02-03
**Focus**: Analyze meta-builder-agent.md Stage 3 IdentifyUseCases to understand current interview flow, identify where dependency capture should be added, and document validation requirements

## Summary

The meta-builder-agent.md Interview Stage 3 (IdentifyUseCases) currently asks about task breakdown but lacks explicit dependency capture questions. The dependencies field schema is now documented in state-management.md (task 35), but the interview process needs enhancement to actively capture dependency relationships with proper validation. This research identifies specific insertion points and validation requirements.

## Findings

### Current Stage 3 Structure (meta-builder-agent.md, lines 239-261)

```markdown
### Interview Stage 3: IdentifyUseCases

**Question 3** (via AskUserQuestion):
{
  "question": "Can this be broken into smaller, independent tasks?",
  "header": "Task Breakdown",
  "options": [
    {"label": "Yes, there are multiple steps", "description": "3+ distinct tasks needed"},
    {"label": "No, it's a single focused change", "description": "1-2 tasks at most"},
    {"label": "Help me break it down", "description": "I'm not sure how to divide it"}
  ]
}

**Question 4** (if breakdown needed):
- Ask user to list discrete tasks in dependency order
- Capture: task_list[], dependency_order[]

**Context Loading Trigger**:
- If "Help me break it down" selected -> Load component-selection.md decision tree
- If discussing template-based components -> Load relevant template file
```

### Current Dependency Handling

1. **Implicit Capture**: Question 4 mentions "dependency order" but:
   - No explicit prompt for dependency relationships
   - No AskUserQuestion JSON specification for capturing dependencies
   - No validation guidance

2. **Downstream Display**: Stage 5 (ReviewAndConfirm) displays dependencies in table:
   ```
   | # | Title | Language | Effort | Dependencies |
   |---|-------|----------|--------|--------------|
   | {N} | {title} | {lang} | {hrs} | None |
   | {N} | {title} | {lang} | {hrs} | #{N} |
   ```

3. **State Updates**: Stage 6 (CreateTasks) mentions TODO.md format with dependencies but no state.json guidance for the `dependencies` array field.

### Dependencies Field Schema (from state-management.md, task 35)

The schema documented in state-management.md specifies:

```json
{
  "dependencies": [332, 333]
}
```

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `dependencies` | array of integers | No | `[]` | Task numbers that must complete before this task can start |

**Validation Requirements**:
- **Valid References**: All task numbers in `dependencies` must exist in `active_projects`
- **No Circular Dependencies**: A task cannot create dependency cycles (A depends on B, B depends on A)
- **No Self-Reference**: A task cannot include its own `project_number` in `dependencies`

**Format Conversion**:
| state.json | TODO.md |
|------------|---------|
| `[]` | `None` |
| `[35]` | `Task #35` |
| `[35, 36]` | `Task #35, Task #36` |

### Interview Patterns (from interview-patterns.md)

Relevant patterns for dependency capture:

1. **Progressive Disclosure**: Start broad, drill into specifics
   - Stage 3 should capture task list first
   - Then explicitly ask about dependencies between those tasks

2. **Validation Checkpoint**: Present summary at Stage 5
   - Dependencies should be validated before presentation
   - User can revise if incorrect

3. **Example-Driven Questioning**: Provide concrete examples
   - Show what a dependency relationship looks like
   - Give examples from current context (other tasks in system)

### Gap Analysis

**What's Missing from Stage 3**:

1. **No explicit dependency question**: After capturing task_list[], need a follow-up question asking "Which tasks depend on others?"

2. **No AskUserQuestion JSON for dependencies**: Need structured prompt for capturing relationships

3. **No validation logic description**: Stage 3 should mention that dependencies will be validated

4. **No guidance on capturing internal vs external dependencies**:
   - Internal: Dependencies between tasks being created in this interview
   - External: Dependencies on existing tasks already in state.json

5. **No handling for new tasks that don't have numbers yet**: When creating 3 tasks with dependencies between them, task numbers aren't assigned until Stage 6. The interview needs to capture "Task B depends on Task A" using temporary identifiers.

### Proposed Question 5: Dependency Capture

After Question 4 (task list capture), add Question 5:

```json
{
  "question": "Do any of these tasks depend on others? (A task can't start until its dependencies are complete)",
  "header": "Task Dependencies",
  "options": [
    {"label": "No dependencies", "description": "All tasks can be done in any order"},
    {"label": "Linear chain", "description": "Each task depends on the previous one"},
    {"label": "Custom dependencies", "description": "I'll specify which tasks depend on which"}
  ],
  "context": "For example: 'Task 2 depends on Task 1' means Task 1 must complete before Task 2 can start."
}
```

If "Custom dependencies" selected, follow up with:

```json
{
  "question": "For each task that has dependencies, tell me which tasks it depends on:",
  "header": "Specify Dependencies",
  "format": "Task {N}: depends on Task {M}, Task {P}",
  "examples": [
    "Task 2: depends on Task 1",
    "Task 3: depends on Task 1, Task 2"
  ]
}
```

**Capture Output**:
- `task_dependencies`: Map of task index to list of dependency task indices
  - Example: `{2: [1], 3: [1, 2]}`
- Use 1-based indexing matching the task_list order for user clarity

### Validation Requirements

**During Stage 3 (Capture-Time Validation)**:

1. **Self-Reference Check**: Task cannot depend on itself
   ```
   if dependency_idx == task_idx:
     error("Task cannot depend on itself")
   ```

2. **Valid Task Index**: Referenced task must exist in task_list
   ```
   if dependency_idx > len(task_list) or dependency_idx < 1:
     error("Task {dependency_idx} does not exist")
   ```

3. **Circular Dependency Detection**: Check for cycles in dependency graph
   ```
   # Build directed graph
   # Use topological sort to detect cycles
   # If cycle detected, report which tasks form the cycle
   ```

**During Stage 6 (Creation-Time Validation)**:

When external dependencies (on existing tasks) are captured:

1. **Existence Check**: Dependency task number must exist in state.json `active_projects`
   ```bash
   jq --arg num "$dep_num" '.active_projects[] | select(.project_number == ($num | tonumber))' specs/state.json
   ```

2. **Status Check** (optional enhancement): Warn if depending on completed tasks
   - Completed dependencies are already satisfied (may indicate user error)

### Stage 3 Enhancement Checklist

1. [ ] Add Question 5 (dependency capture) after Question 4
2. [ ] Add AskUserQuestion JSON specification for dependency capture
3. [ ] Add capture variables: `task_dependencies: {}` map
4. [ ] Add validation logic references (self-reference, circular, valid index)
5. [ ] Add guidance for temporary task identifiers vs final task numbers
6. [ ] Add context loading trigger for state.json when external dependencies needed

### Integration Points with Other Stages

**Stage 5 (ReviewAndConfirm)**:
- Already displays Dependencies column in summary table
- Needs validation to have been completed by this point
- May need error message if validation failed at Stage 3

**Stage 6 (CreateTasks)**:
- Must convert `task_dependencies` map to actual task numbers
- Tasks are assigned numbers in topological order (task 37 will implement this)
- Current behavior: Sequential number assignment regardless of dependencies

**Stage 7 (DeliverSummary)**:
- Already shows dependencies in output format
- Task 39 will enhance visualization

## Recommendations

### 1. Add Question 5 for Dependency Capture

Insert after line 257 (after Question 4 capture):

```markdown
**Question 5** (if multiple tasks):
{
  "question": "Do any of these tasks depend on others?",
  "header": "Task Dependencies",
  "options": [
    {"label": "No dependencies", "description": "All tasks can start independently"},
    {"label": "Linear chain", "description": "Each task depends on the previous"},
    {"label": "Custom", "description": "I'll specify the relationships"}
  ]
}

If "Custom" selected:
- Present task list with indices (e.g., "1. Create schema, 2. Add validation, 3. Update docs")
- Ask: "For each dependent task, list what it depends on (e.g., '2: 1' means task 2 depends on task 1)"
- Capture: dependency_map{task_idx: [dep_idx, ...]}
```

### 2. Add Validation Logic Description

Insert after dependency capture:

```markdown
**Dependency Validation** (immediate):
1. Self-reference check: task_idx cannot appear in its own dependency list
2. Valid index check: all referenced indices must be valid task indices
3. Circular dependency check: build dependency graph and verify acyclic
   - If cycle detected: "Tasks {A}, {B}, {C} form a circular dependency. Please revise."
```

### 3. Add External Dependency Handling

Add guidance for referencing existing tasks:

```markdown
**External Dependencies** (optional follow-up):
{
  "question": "Should any tasks depend on existing tasks in your TODO?",
  "header": "External Dependencies",
  "options": [
    {"label": "No", "description": "Only dependencies between new tasks"},
    {"label": "Yes", "description": "I'll specify existing task numbers"}
  ]
}

If "Yes": User provides existing task numbers (validated against state.json)
```

### 4. Update Capture Variables

Update the capture section to include:

```markdown
**Capture**:
- task_list[]: Array of task titles/descriptions
- task_dependencies{}: Map of task index -> [dependency indices]
- external_dependencies{}: Map of task index -> [existing task numbers]
```

### 5. Add Validation Function Pseudocode

```markdown
**Validation Pseudocode**:

function validate_dependencies(task_list, dependency_map):
  # Check self-reference
  for task_idx, deps in dependency_map:
    if task_idx in deps:
      return error("Task {task_idx} cannot depend on itself")

  # Check valid indices
  for task_idx, deps in dependency_map:
    for dep in deps:
      if dep < 1 or dep > len(task_list):
        return error("Task {dep} does not exist")

  # Check for cycles (topological sort)
  visited = set()
  in_progress = set()
  for task_idx in range(1, len(task_list) + 1):
    if has_cycle(task_idx, dependency_map, visited, in_progress):
      return error("Circular dependency detected")

  return success
```

## Implementation Scope

This task (36) should:
1. Add Question 5 for explicit dependency capture with AskUserQuestion JSON
2. Add validation logic description (self-reference, valid index, circular check)
3. Add external dependency handling option
4. Update capture variables documentation
5. Add validation pseudocode/guidance

**Out of scope** (handled by later tasks):
- Topological sorting for task number assignment (task 37)
- TODO.md insertion ordering (task 38)
- Dependency graph visualization (task 39)

## References

- `/home/benjamin/.config/nvim/.claude/agents/meta-builder-agent.md` - Main file to modify
- `/home/benjamin/.config/nvim/.claude/rules/state-management.md` - Dependencies field schema (lines 177-196)
- `/home/benjamin/.config/nvim/.claude/context/project/meta/interview-patterns.md` - Interview patterns guide
- `/home/benjamin/.config/nvim/specs/035_add_dependencies_field_to_state_schema/reports/research-001.md` - Task 35 research
- `/home/benjamin/.config/nvim/specs/state.json` - Live state with example dependencies

## Next Steps

1. Proceed to planning phase
2. Plan should modify meta-builder-agent.md in these locations:
   - Line ~257: Add Question 5 for dependency capture
   - Line ~260: Add validation logic description
   - Line ~260: Add external dependency handling
   - Update capture variables section
   - Add validation pseudocode (can be separate subsection)
