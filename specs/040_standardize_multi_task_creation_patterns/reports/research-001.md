# Research Report: Task #40

**Task**: Standardize multi-task creation patterns
**Date**: 2026-02-03
**Focus**: Analyze all commands/skills/agents that create multiple tasks, document patterns, and create unified standard

## Summary

This research identifies five distinct multi-task creation patterns across the codebase: /learn (interactive checkbox selection with topic grouping), /meta (7-stage interview with dependency declaration and topological sorting), /review (issue grouping with tier-based selection), /errors (fix task creation from error patterns), and /task --review (phase follow-up suggestions). Each implements sophisticated patterns that could be standardized into a common best practice.

## Inventory of Multi-Task Creators

### 1. /learn Command

**Location**: `.claude/commands/learn.md`, `.claude/skills/skill-learn/SKILL.md`

**Purpose**: Scan codebase for FIX:/NOTE:/TODO: tags and create structured tasks

**Multi-Task Pattern**:
- **Interactive checkbox selection**: AskUserQuestion with multiSelect for task type selection
- **Topic grouping algorithm**: Clusters TODOs by shared terms (2+ significant terms) or file section + action type
- **Effort scaling**: Base 1 hour + 30min per additional item in grouped tasks
- **Dependency handling**: Creates learn-it task FIRST, then fix-it with dependency when both selected

**Key Features**:
- Tag-based discovery (FIX:, NOTE:, TODO:)
- Three-tier selection: task types -> individual items -> grouping mode
- Grouping modes: "grouped" | "separate" | "combined"

### 2. /meta Command and meta-builder-agent

**Location**: `.claude/commands/meta.md`, `.claude/agents/meta-builder-agent.md`

**Purpose**: Interactive system builder for .claude/ architecture changes

**Multi-Task Pattern**:
- **7-stage interview workflow**: DetectExisting -> Initiate -> GatherDomain -> IdentifyUseCases -> AssessComplexity -> ReviewAndConfirm -> CreateTasks
- **Dependency declaration**: Internal (between new tasks) and external (to existing tasks)
- **Topological sorting**: Kahn's algorithm for task ordering
- **Batch insertion**: All tasks inserted in sorted order (foundational first)
- **Dependency visualization**: Linear chain vs layered DAG with box-drawing characters

**Key Features**:
- User confirmation REQUIRED before any task creation
- Circular dependency detection with DFS
- External dependency validation against state.json
- Graph generation with complexity detection

### 3. /review Command

**Location**: `.claude/commands/review.md`

**Purpose**: Analyze codebase, identify issues, create tasks for fixes

**Multi-Task Pattern**:
- **Issue grouping algorithm**: Groups by file_section + issue_type (primary) or 2+ shared key_terms + priority (secondary)
- **Tier-1 selection**: Interactive group selection via AskUserQuestion
- **Tier-2 granularity**: "Keep as grouped" | "Expand into individual" | "Show issues and select manually"
- **Scoring algorithm**: Critical (+10), High (+5), priority levels (+2-8), item count (capped at 5)

**Key Features**:
- Combines review findings with roadmap items
- Auto-create mode (`--create-tasks`) for Critical/High issues
- Size limits: <2 items merged, max 10 groups
- Duplicate prevention via slug matching

### 4. /errors Command

**Location**: `.claude/commands/errors.md`

**Purpose**: Analyze errors.json and create fix plans

**Multi-Task Pattern**:
- **Pattern grouping**: Groups errors by type, severity, recurrence, context
- **Automatic task creation**: Creates tasks for "significant error patterns"
- **Priority-based**: Quick wins, critical first

**Key Features**:
- Simpler than other creators (no complex interactive selection)
- Analysis-driven task creation
- Links tasks to errors via fix_task field

### 5. /task --review Mode

**Location**: `.claude/commands/task.md` (--review section)

**Purpose**: Review task completion status and suggest follow-up tasks

**Multi-Task Pattern**:
- **Phase-based analysis**: Parses plan file for incomplete phases
- **Interactive selection**: Present numbered options, user selects which to create
- **Follow-up task format**: "Complete phase {P} of task {N}: {phase_name}"

**Key Features**:
- READ-ONLY until user confirms
- Parent task linking via parent_task field
- Inherits language from parent task

## Pattern Comparison Matrix

| Feature | /learn | /meta | /review | /errors | /task --review |
|---------|--------|-------|---------|---------|----------------|
| **Interactive Selection** | Checkbox (multiSelect) | Interview (7-stage) | Tier-based (group->granularity) | Automatic | Numbered list |
| **Topic/Issue Grouping** | Key terms + file section | User-defined | file_section + issue_type | Error type + severity | Phase-based |
| **Dependency Support** | learn-it -> fix-it | Full DAG (internal + external) | None | None | parent_task reference |
| **Topological Sorting** | No | Kahn's algorithm | No | No | No |
| **Visualization** | None | Linear chain / Layered DAG | None | None | None |
| **Batch Insertion** | Sequential | Sorted batch | Sequential | Sequential | Sequential |
| **User Confirmation** | Implicit (selection) | Explicit (mandatory) | Implicit (selection) | Automatic | Explicit (selection) |
| **Effort Scaling** | Base + 30min/item | User-provided | From severity | From analysis | From parent |

## Best Practices Identified

### 1. Interactive Selection Pattern (/learn, /review)

**AskUserQuestion with multiSelect**:
```json
{
  "question": "Which items should be created as tasks?",
  "header": "Task Selection",
  "multiSelect": true,
  "options": [
    {"label": "{item}", "description": "{context}"}
  ]
}
```

**Best Practice**: Use multiSelect for item selection, single-select for mode/granularity choices.

### 2. Dependency Declaration Pattern (/meta)

**Interview Questions**:
1. "Do any tasks depend on others?" (No dependencies / Linear chain / Custom)
2. For custom: "For each dependent task, list dependencies" (format: "Task {N}: depends on Task {M}")
3. "Should any tasks depend on existing tasks?" (external dependencies)

**Validation**:
- Self-reference check
- Valid index check
- Circular dependency check (DFS)

**Best Practice**: Ask about dependencies explicitly, validate immediately, provide clear error messages.

### 3. Topological Sorting Pattern (/meta)

**Kahn's Algorithm Implementation**:
```python
# Build in-degree map
in_degree = {idx: len(deps) for idx, deps in dependency_map.items()}

# Start with no-dependency tasks
queue = [idx for idx in range(1, n+1) if in_degree[idx] == 0]

# Process in BFS order
sorted_indices = []
while queue:
    current = queue.pop(0)
    sorted_indices.append(current)
    for dependent in dependents[current]:
        in_degree[dependent] -= 1
        if in_degree[dependent] == 0:
            queue.append(dependent)
```

**Best Practice**: Sort tasks topologically so foundational tasks get lower numbers and appear first in TODO.md.

### 4. Batch Insertion Pattern (/meta)

**Why**: Individual prepends reverse order (last task at top). Batch insertion preserves topological order.

```python
# Build all entries in sorted order
batch_entries = []
for position, task_idx in enumerate(sorted_indices):
    batch_entries.append(format_entry(task_idx))

# Insert entire batch after ## Tasks heading
batch_markdown = "\n\n".join(batch_entries)
insert_after_heading("## Tasks", batch_markdown)
```

**Best Practice**: When creating multiple tasks, build all entries in memory, then insert as a batch.

### 5. Dependency Visualization Pattern (/meta)

**Linear Chain** (simple):
```
  [37] Add topological sorting
    |
    v
  [38] Update TODO insertion
```

**Layered DAG** (complex):
```
       [37] Core API
         |
    +----+----+
    |         |
    v         v
[38] Parser  [39] Validator
    |         |
    +----+----+
         |
         v
   [40] Integration
```

**Best Practice**: Detect DAG complexity, use simple vertical for linear chains, layered box-drawing for complex graphs.

### 6. Topic Grouping Pattern (/learn, /review)

**Clustering Algorithm**:
1. Extract indicators: key_terms, file_section, action_type, priority
2. Primary match: same file_section AND same issue_type
3. Secondary match: 2+ shared key_terms AND same priority
4. Generate label from common terms
5. Combine small groups (<2 items)
6. Cap total groups (max 10)

**Best Practice**: Use semantic clustering for related items, offer grouping as an option, scale effort by item count.

### 7. User Confirmation Pattern (/meta)

**Mandatory Confirmation**:
```json
{
  "question": "Proceed with creating these tasks?",
  "header": "Confirm",
  "options": [
    {"label": "Yes, create tasks", "description": "Create {N} tasks"},
    {"label": "Revise", "description": "Go back and adjust"},
    {"label": "Cancel", "description": "Exit without creating"}
  ]
}
```

**Best Practice**: Always show task summary and require explicit confirmation before creating tasks.

## Recommended Unified Standard

### Core Components for Multi-Task Creation

1. **Item Discovery**: Identify items that could become tasks (tags, issues, phases, patterns)

2. **Interactive Selection**:
   - Use AskUserQuestion with multiSelect for item selection
   - Support "Select all" for large lists (>20 items)
   - Empty selection = graceful exit, no tasks created

3. **Topic Grouping** (when 2+ items selected):
   - Cluster by semantic similarity (key terms, file section, action type)
   - Present grouping options: "Accept groups" | "Keep separate" | "Combine all"
   - Scale effort: base + increment per item

4. **Dependency Declaration** (when multiple tasks):
   - Ask: "Do any tasks depend on others?"
   - Options: "No dependencies" | "Linear chain" | "Custom"
   - Validate: no self-reference, no cycles, valid indices
   - Support external dependencies to existing tasks

5. **Task Ordering**:
   - Apply topological sort (Kahn's algorithm)
   - Foundational tasks get lower numbers
   - Batch insert to preserve order

6. **Visualization** (for complex dependencies):
   - Detect if linear chain or complex DAG
   - Display dependency graph in summary
   - Show execution order with annotations

7. **User Confirmation** (MANDATORY):
   - Show task summary table: #, title, depends on, path
   - Show total effort estimate
   - Require explicit "Yes, create tasks" selection

8. **State Updates**:
   - Update state.json with dependencies array
   - Update TODO.md with Dependencies line
   - Batch insert in topological order
   - Git commit with task count

### Implementation Checklist

For any command/skill/agent that creates multiple tasks:

- [ ] **Discovery**: Clear criteria for identifying potential tasks
- [ ] **Selection UI**: AskUserQuestion with multiSelect, "Select all" for >20 items
- [ ] **Grouping** (optional): Semantic clustering when 2+ items selected
- [ ] **Dependency Interview**: Ask about internal and external dependencies
- [ ] **Validation**: Self-reference, cycle detection, valid indices
- [ ] **Topological Sort**: Kahn's algorithm for task ordering
- [ ] **Batch Insertion**: Build all entries, insert as batch
- [ ] **Confirmation**: Summary table + explicit confirmation required
- [ ] **Visualization** (optional): Linear chain or layered DAG display
- [ ] **Git Commit**: Include task count in commit message

## Gaps and Recommendations

### Current Gaps

1. **/review**: No dependency support between created tasks
2. **/errors**: No interactive selection, no dependency support
3. **/task --review**: No topological sorting for follow-up tasks
4. **/learn**: No external dependency support (only internal learn-it -> fix-it)

### Recommendations

1. **Create shared utility functions** for:
   - Dependency interview workflow
   - Topological sorting (Kahn's algorithm)
   - Batch insertion pattern
   - Dependency visualization

2. **Standardize state.json schema** for dependencies:
   ```json
   {
     "dependencies": [35, 36],  // Always array of task numbers
     "blocks": [38, 39]         // Optional: tasks this blocks
   }
   ```

3. **Add dependency support to /review and /errors**:
   - Allow grouping issues into dependent chains
   - "This group should be done before that group"

4. **Document the standard** in a new file:
   - `.claude/docs/reference/standards/multi-task-creation-standard.md`
   - Reference from all multi-task creator docs

## References

- `.claude/commands/learn.md` - Interactive tag scanning
- `.claude/commands/meta.md` - System builder command
- `.claude/agents/meta-builder-agent.md` - Full 7-stage interview with dependency patterns
- `.claude/commands/review.md` - Issue grouping and task creation
- `.claude/commands/errors.md` - Error analysis and fix tasks
- `.claude/commands/task.md` - Task lifecycle including --review mode
- `.claude/skills/skill-learn/SKILL.md` - Topic grouping implementation
- `.claude/context/core/workflows/task-breakdown.md` - Task breakdown guidelines

## Next Steps

1. Run `/plan 40` to create implementation plan for standardizing the patterns
2. Consider prioritizing:
   - Phase 1: Create shared utility functions (lib/workflow/multi-task-utils.sh)
   - Phase 2: Create standard documentation
   - Phase 3: Update existing multi-task creators to use shared functions
   - Phase 4: Add dependency support to /review and /errors
