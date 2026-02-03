# Research Report: Task #35

**Task**: Add dependencies field to state.json schema
**Date**: 2026-02-03
**Focus**: Schema modification for machine-readable dependency tracking

## Summary

The dependencies field has already been implemented in state.json for tasks 35-39 but is not yet documented in state-management.md. This research documents the current implementation and identifies the remaining documentation work needed to make this a formal part of the schema.

## Findings

### Current state.json Schema (Documented in state-management.md)

The documented schema in state-management.md (lines 78-98) shows the following task entry structure:

```json
{
  "project_number": 334,
  "project_name": "task_slug_here",
  "status": "planned",
  "language": "neovim",
  "effort": "4 hours",
  "created": "2026-01-08T10:00:00Z",
  "last_updated": "2026-01-08T14:30:00Z",
  "artifacts": [...],
  "completion_summary": "...",
  "roadmap_items": [...]
}
```

Notable fields documented:
- `project_number` (integer, required)
- `project_name` (string, required)
- `status` (string enum, required)
- `language` (string enum, required)
- `effort` (string, optional)
- `created` (ISO8601 timestamp)
- `last_updated` (ISO8601 timestamp)
- `artifacts` (array of artifact objects)
- `completion_summary` (string, required when completed)
- `roadmap_items` (array of strings, optional)
- `claudemd_suggestions` (string, meta tasks only)

### Current Implementation (Already in state.json)

Tasks 35-39 already have the `dependencies` field implemented:

```json
{
  "project_number": 35,
  "project_name": "add_dependencies_field_to_state_schema",
  "dependencies": [],
  ...
}

{
  "project_number": 36,
  "project_name": "enhance_interview_stage3_dependency_capture",
  "dependencies": [35],
  ...
}

{
  "project_number": 37,
  "project_name": "implement_topological_sorting_stage6",
  "dependencies": [35, 36],
  ...
}
```

### Current TODO.md Format (Already in Use)

The TODO.md entries for tasks 35-39 show the human-readable format:

```markdown
### 35. Add dependencies field to state.json schema
- **Effort**: 1-2 hours
- **Status**: [RESEARCHING]
- **Language**: meta
- **Dependencies**: None

### 36. Enhance interview Stage 3 dependency capture
- **Dependencies**: Task #35

### 37. Implement topological sorting in Stage 6
- **Dependencies**: Task #35, Task #36
```

### meta-builder-agent.md Documentation

The meta-builder-agent.md already shows dependencies in:

1. **Interview Stage 5 (ReviewAndConfirm)** - Table with Dependencies column:
   ```markdown
   | # | Title | Language | Effort | Dependencies |
   |---|-------|----------|--------|--------------|
   | {N} | {title} | {lang} | {hrs} | None |
   | {N} | {title} | {lang} | {hrs} | #{N} |
   ```

2. **Interview Stage 6 (CreateTasks)** - TODO.md entry format:
   ```markdown
   ### {N}. {Title}
   - **Effort**: {estimate}
   - **Status**: [NOT STARTED]
   - **Language**: {language}
   - **Dependencies**: Task #{N}, Task #{N}
   ```

3. **Interview Stage 7 (DeliverSummary)** - Output format:
   ```markdown
   - Task #{N}: {title} (depends on #{N})
   ```

However, the agent does NOT show the state.json format for the dependencies array.

## Gap Analysis

### What's Missing from state-management.md

1. **Field Definition**: The `dependencies` field needs to be added to the state.json Entry schema (around line 78-98)

2. **Field Specification Table Entry**: Should be added to the documented fields with:
   - Field name: `dependencies`
   - Type: `array of integers`
   - Required: No (defaults to empty array `[]`)
   - Description: Task numbers that must be completed before this task can start

3. **Validation Requirements**: Document that:
   - Array elements must be valid task numbers (existing in active_projects)
   - No circular dependencies allowed
   - Empty array `[]` means no dependencies (same as "None" in TODO.md)

4. **TODO.md Format Specification**: The current entry format (lines 63-76) should include the Dependencies line:
   ```markdown
   - **Dependencies**: Task #{N}, Task #{N}  OR  None
   ```

## Recommendations

### 1. Update state.json Entry Schema

Add to line ~87 of state-management.md (after `artifacts` array):

```json
{
  "project_number": 334,
  "project_name": "task_slug_here",
  "status": "planned",
  "language": "neovim",
  "effort": "4 hours",
  "created": "2026-01-08T10:00:00Z",
  "last_updated": "2026-01-08T14:30:00Z",
  "dependencies": [332, 333],
  "artifacts": [...],
  ...
}
```

### 2. Add Field Documentation Table

Create a new section or extend existing documentation:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `dependencies` | array of int | No | Task numbers that must complete before this task can start. Empty array `[]` if no dependencies. |

### 3. Add Validation Requirements Section

```markdown
### Dependency Validation

When creating or updating task dependencies:

1. **Valid References**: All task numbers in the array must exist in `active_projects`
2. **No Circular Dependencies**: A task cannot depend on itself or create cycles (A->B->A)
3. **No Completed Dependencies**: Dependencies should reference incomplete tasks (completed tasks are already satisfied)

**Validation Pattern**:
```bash
# Check for circular dependency (task A depending on task B depending on A)
# Implementation responsibility: meta-builder-agent during task creation
```
```

### 4. Update TODO.md Entry Format

Update lines 63-76 to include:

```markdown
### {NUMBER}. {TITLE}
- **Effort**: {estimate}
- **Status**: [{STATUS}]
- **Language**: {neovim|general|meta|markdown|latex|typst}
- **Dependencies**: Task #{N}, Task #{N} OR None
- **Started**: {ISO timestamp}
...
```

## Dependency Format Specification

### state.json Format
- Field: `dependencies`
- Type: Array of integers
- Empty: `[]` (no dependencies)
- With dependencies: `[35, 36]` (depends on tasks 35 and 36)

### TODO.md Format
- Line: `- **Dependencies**: {format}`
- No dependencies: `None`
- Single dependency: `Task #35`
- Multiple dependencies: `Task #35, Task #36`

### Conversion Rules
- state.json `[]` <-> TODO.md `None`
- state.json `[35]` <-> TODO.md `Task #35`
- state.json `[35, 36]` <-> TODO.md `Task #35, Task #36`

## Implementation Scope

This task (35) should:
1. Add `dependencies` field to state.json schema in state-management.md
2. Add field specification with type, default, and description
3. Add validation requirements documentation
4. Update TODO.md entry format to include Dependencies line
5. Document the conversion between state.json array and TODO.md string format

**Out of scope** (handled by later tasks 36-39):
- Interview capture logic (task 36)
- Topological sorting (task 37)
- TODO.md insertion ordering (task 38)
- Dependency visualization (task 39)

## References

- `/home/benjamin/.config/nvim/.claude/rules/state-management.md` - Current schema documentation
- `/home/benjamin/.config/nvim/specs/state.json` - Live state file with implemented dependencies
- `/home/benjamin/.config/nvim/.claude/agents/meta-builder-agent.md` - Task creation agent (references but doesn't document schema)
- `/home/benjamin/.config/nvim/specs/TODO.md` - Human-readable task format

## Next Steps

1. Proceed to planning phase to create implementation plan
2. Plan should modify state-management.md in 4 locations:
   - state.json Entry schema example (add dependencies field)
   - New field documentation table entry
   - New validation requirements section
   - TODO.md Entry format (add Dependencies line)
