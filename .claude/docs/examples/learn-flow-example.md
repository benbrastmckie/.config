# Integration Example: Learn Flow

This example traces a complete `/learn` command execution through the ProofChecker agent system, showing how the command scans for tags, presents findings interactively, and creates user-selected tasks.

---

## Scenario

A user runs `/learn Logos/` to scan the Logos directory for embedded tags. The system displays findings, then prompts the user to select which task types to create.

---

## Tag Types and Task Generation

The `/learn` command recognizes three tag types in source code comments:

| Tag | Task Type | Behavior |
|-----|-----------|----------|
| `FIX:` | fix-it-task | All FIX: and NOTE: tags grouped into single task |
| `NOTE:` | fix-it-task + learn-it-task | Creates two task types (with dependency when both selected) |
| `TODO:` | todo-task | User selects which TODO: tags become tasks (with optional topic grouping) |

**Dependency behavior**: When NOTE: tags exist and both fix-it and learn-it tasks are selected, the learn-it task is created first and the fix-it task depends on it. This ensures proper workflow: learn-it extracts knowledge to context files (NOTE: tags remain in source), then fix-it addresses the code changes and removes both NOTE: and FIX: tags.

---

## Complete Flow Diagram

```
User Input: /learn Logos/
       |
       v
[Layer 1: Command] .claude/commands/learn.md
       |
       | Frontmatter specifies: allowed-tools: Skill
       v
[Layer 2: Skill] skill-learn/SKILL.md (DIRECT EXECUTION)
       |
       | 1. Parse arguments -> paths = ["Logos/"]
       | 2. Generate session ID
       | 3. Execute tag extraction (grep patterns)
       | 4. Display tag summary to user
       | 5. AskUserQuestion: Select task types
       | 6. AskUserQuestion: Select TODO items (if applicable)
       | 7. Analyze TODO topics and cluster (if 2+ items)
       | 8. AskUserQuestion: Confirm topic grouping (if groups found)
       | 9. Create selected tasks
       | 8. Git commit postflight
       v
Output: Created N tasks from M tags
```

**Key difference from old pattern**: No subagent delegation. Everything executes directly in skill-learn using AskUserQuestion for interactivity.

---

## Step-by-Step Walkthrough

### Step 1: User Invokes Command

```bash
/learn Logos/
```

Claude Code reads `.claude/commands/learn.md` and sees:

```yaml
---
description: Scan files for FIX:, NOTE:, TODO: tags and create structured tasks interactively
allowed-tools: Skill
argument-hint: [PATH...]
---
```

### Step 2: Skill Executes Tag Extraction

The skill (`skill-learn/SKILL.md`) executes directly (no subagent).

**Skill Step 1: Parse Arguments**

```bash
paths="Logos/"
session_id="sess_1768940708_a1b2c3"
```

**Skill Step 2: Scan for Tags**

Execute grep patterns for each file type:

```bash
# Lean files
grep -rn --include="*.lean" "-- FIX:" Logos/ 2>/dev/null
grep -rn --include="*.lean" "-- NOTE:" Logos/ 2>/dev/null
grep -rn --include="*.lean" "-- TODO:" Logos/ 2>/dev/null

# Example output:
Logos/Layer1/Modal.lean:67:-- TODO: Add completeness theorem for S5
Logos/Layer1/Modal.lean:89:-- FIX: Handle edge case in frame validation
Logos/Layer2/Temporal.lean:45:-- NOTE: This pattern should be documented
Logos/Shared/Utils.lean:23:-- TODO: Optimize this function
```

**Skill Step 3: Parse and Categorize**

```
fix_tags = [
  {file: "Logos/Layer1/Modal.lean", line: 89, content: "Handle edge case in frame validation"}
]
note_tags = [
  {file: "Logos/Layer2/Temporal.lean", line: 45, content: "This pattern should be documented"}
]
todo_tags = [
  {file: "Logos/Layer1/Modal.lean", line: 67, content: "Add completeness theorem for S5"},
  {file: "Logos/Shared/Utils.lean", line: 23, content: "Optimize this function"}
]
```

### Step 3: Display Tag Summary

User sees:

```
## Tag Scan Results

**Files Scanned**: Logos/
**Tags Found**: 4

### FIX: Tags (1)
- `Logos/Layer1/Modal.lean:89` - Handle edge case in frame validation

### NOTE: Tags (1)
- `Logos/Layer2/Temporal.lean:45` - This pattern should be documented

### TODO: Tags (2)
- `Logos/Layer1/Modal.lean:67` - Add completeness theorem for S5
- `Logos/Shared/Utils.lean:23` - Optimize this function
```

### Step 4: Interactive Task Type Selection

**Skill Step 4: AskUserQuestion for Task Types**

The skill invokes AskUserQuestion with multi-select enabled:

```json
{
  "questions": [
    {
      "question": "Which task types would you like to create from these tags?",
      "header": "Task Types",
      "multiSelect": true,
      "options": [
        {
          "label": "Fix-it task (groups all FIX: and NOTE: tags)",
          "description": "Creates 1 task to address 2 items from FIX:/NOTE: tags"
        },
        {
          "label": "Learn-it task (documents insights from NOTE: tags)",
          "description": "Creates 1 task to update context files based on 1 NOTE: tag"
        },
        {
          "label": "TODO tasks (individual tasks from TODO: tags)",
          "description": "Select which of the 2 TODO: items should become tasks"
        }
      ]
    }
  ]
}
```

User selects:
- ✓ Fix-it task
- ✗ Learn-it task
- ✓ TODO tasks

### Step 5: Interactive TODO Item Selection

**Skill Step 5: AskUserQuestion for TODO Items**

Since "TODO tasks" was selected, the skill prompts for individual TODO item selection:

```json
{
  "questions": [
    {
      "question": "Select which TODO: items should become individual tasks:",
      "header": "TODO Items",
      "multiSelect": true,
      "options": [
        {
          "label": "Add completeness theorem for S5",
          "description": "From Logos/Layer1/Modal.lean:67"
        },
        {
          "label": "Optimize this function",
          "description": "From Logos/Shared/Utils.lean:23"
        }
      ]
    }
  ]
}
```

User selects:
- ✓ Add completeness theorem for S5
- ✓ Add soundness theorem for S5
- ✓ Optimize this function

### Step 5.5: Topic Grouping (New Feature)

**Skill Step 5.5: Analyze TODO Topics**

Since multiple TODOs were selected (3 items), the skill analyzes them for topic grouping:

```
TODO analysis:
  "Add completeness theorem for S5" at Logos/Layer1/Modal.lean:67
    → key_terms: ["completeness", "theorem", "S5"]
    → file_section: "Logos/Layer1/"
    → action_type: "implementation"

  "Add soundness theorem for S5" at Logos/Layer1/Modal.lean:89
    → key_terms: ["soundness", "theorem", "S5"]
    → file_section: "Logos/Layer1/"
    → action_type: "implementation"

  "Optimize this function" at Logos/Shared/Utils.lean:23
    → key_terms: ["optimize", "function"]
    → file_section: "Logos/Shared/"
    → action_type: "improvement"

Clustering result:
  Group 1: "S5 Theorems" - 2 items (shared: S5, theorem, implementation)
  Group 2: "Utility Optimization" - 1 item
```

**Skill Step 5.6: AskUserQuestion for Topic Grouping**

Since there's at least one group with 2+ items, the skill presents grouping options:

```json
{
  "questions": [
    {
      "question": "How should TODO items be grouped into tasks?",
      "header": "TODO Topic Grouping",
      "multiSelect": false,
      "options": [
        {
          "label": "Accept suggested topic groups",
          "description": "Creates 2 grouped tasks: S5 Theorems (2 items), Utility Optimization (1 item)"
        },
        {
          "label": "Keep as separate tasks",
          "description": "Creates 3 individual tasks (one per TODO item)"
        },
        {
          "label": "Create single combined task",
          "description": "Creates 1 task containing all 3 TODO items"
        }
      ]
    }
  ]
}
```

User selects: **Accept suggested topic groups**

### Step 6: Task Creation

**Skill Step 6: Create Selected Tasks**

Based on user selections, create tasks. **Note**: When NOTE: tags exist and both fix-it and learn-it are selected, learn-it is created first with the fix-it task depending on it.

**Example A: Both fix-it and learn-it selected (with dependency)**

If user selected both "Fix-it task" and "Learn-it task" for NOTE: tags:

**Learn-It Task (Task #650, created FIRST)**:
```json
{
  "project_number": 650,
  "project_name": "update_context_from_note_tags",
  "status": "not_started",
  "language": "meta",
  "priority": "medium",
  "description": "Update 1 context files based on learnings:\n\n- Logos/Layer2/Temporal.lean:45 - This pattern should be documented"
}
```

**Fix-It Task (Task #651, with dependency)**:
```json
{
  "project_number": 651,
  "project_name": "fix_issues_from_tags",
  "status": "not_started",
  "language": "lean",
  "priority": "high",
  "dependencies": [650],
  "description": "Address 2 items from embedded tags:\n\n- Logos/Layer1/Modal.lean:89 - Handle edge case in frame validation\n- Logos/Layer2/Temporal.lean:45 - This pattern should be documented"
}
```

The TODO.md entry for the fix-it task includes:
```markdown
- **Dependencies**: 650
```

**Example B: Topic-grouped TODO tasks (new feature)**

When user selects "Accept suggested topic groups" in Step 5.6:

**Grouped TODO Task #1 (Task #650)**:
```json
{
  "project_number": 650,
  "project_name": "s5_theorems_2_todo_items",
  "status": "not_started",
  "language": "lean",
  "priority": "medium",
  "effort": "1.5 hours",
  "description": "Address TODO items related to S5 Theorems:\n\n- [ ] Add completeness theorem for S5 (`Logos/Layer1/Modal.lean:67`)\n- [ ] Add soundness theorem for S5 (`Logos/Layer1/Modal.lean:89`)\n\n---\n\nShared context: Related to S5 modal logic theorems"
}
```

**Grouped TODO Task #2 (Task #651)**:
```json
{
  "project_number": 651,
  "project_name": "utility_optimization_1_todo_item",
  "status": "not_started",
  "language": "lean",
  "priority": "medium",
  "effort": "1 hour",
  "description": "Address TODO items related to Utility Optimization:\n\n- [ ] Optimize this function (`Logos/Shared/Utils.lean:23`)\n\n---\n\nShared context: Performance improvement in shared utilities"
}
```

**Effort scaling applied**:
- S5 Theorems: 2 items = 1h + 30min = 1.5 hours
- Utility Optimization: 1 item = 1 hour (base)

**Example C: Separate TODO tasks (original behavior)**

When user selects "Keep as separate tasks":

**TODO Task (Task #650)**:
```json
{
  "project_number": 650,
  "project_name": "add_completeness_theorem_s5",
  "status": "not_started",
  "language": "lean",
  "priority": "medium",
  "description": "Add completeness theorem for S5\n\nSource: Logos/Layer1/Modal.lean:67"
}
```

(Plus 2 more individual tasks for soundness theorem and utility optimization)

### Step 7: Postflight Git Commit

```bash
git add specs/TODO.md specs/state.json
git commit -m "learn: create 2 tasks from 4 tags

Session: sess_1768940708_a1b2c3

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

### Step 8: User Sees Results

**Example output when both fix-it and learn-it selected (with dependency)**:

```
## Tasks Created from Tags

**Tags Processed**: 4 tags scanned, 3 tasks created

### Created Tasks

| # | Type | Title | Priority | Language | Dependencies |
|---|------|-------|----------|----------|--------------|
| 650 | learn-it | Update context files from NOTE: tags | Medium | meta | - |
| 651 | fix-it | Fix issues from FIX:/NOTE: tags | High | lean | 650 |
| 652 | todo | Add completeness theorem for S5 | Medium | lean | - |
```

**Example output with topic-grouped TODO tasks (new feature)**:

```
## Tasks Created from Tags

**Tags Processed**: 4 tags scanned, 3 tasks created

### Created Tasks

| # | Type | Title | Priority | Language | Effort |
|---|------|-------|----------|----------|--------|
| 650 | fix-it | Fix issues from FIX:/NOTE: tags | High | lean | 2-4h |
| 651 | todo (grouped) | S5 Theorems: 2 TODO items | Medium | lean | 1.5h |
| 652 | todo (grouped) | Utility Optimization: 1 TODO item | Medium | lean | 1h |

---

**Next Steps**:
1. Review tasks in TODO.md
2. Run `/research 650` to begin
3. Progress through /research -> /plan -> /implement cycle
```

**Example output with separate TODO tasks (original behavior)**:

```
## Tasks Created from Tags

**Tags Processed**: 4 tags scanned, 4 tasks created

### Created Tasks

| # | Type | Title | Priority | Language |
|---|------|-------|----------|----------|
| 650 | fix-it | Fix issues from FIX:/NOTE: tags | High | lean |
| 651 | todo | Add completeness theorem for S5 | Medium | lean |
| 652 | todo | Add soundness theorem for S5 | Medium | lean |
| 653 | todo | Optimize this function | Medium | lean |
```

---

## Tag Detection Examples

### Lean Files (.lean)

```lean
-- FIX: This needs to handle the empty frame case
-- NOTE: The S5 axiom pattern could be generalized
-- TODO: Add reflexivity lemma
```

### LaTeX Files (.tex)

```latex
% FIX: Correct the citation format
% NOTE: This theorem should be referenced in the appendix
% TODO: Add proof sketch for completeness
```

### Markdown Files (.md)

```markdown
<!-- FIX: Update outdated section -->
<!-- NOTE: Consider reorganizing these examples -->
<!-- TODO: Add code examples -->
```

### Python/Shell Files

```python
# FIX: Handle edge case when input is empty
# NOTE: This algorithm could be optimized
# TODO: Add unit tests
```

---

## Context Routing for NOTE: Tags

NOTE: tags are special because they can create both fix-it and learn-it tasks. The learn-it task routes to appropriate context directories:

| Source File Pattern | Target Context Directory |
|--------------------|-------------------------|
| `.claude/agents/*.md` | `.claude/context/core/agents/` |
| `.claude/skills/*/SKILL.md` | `.claude/context/core/skills/` |
| `.claude/commands/*.md` | `.claude/context/core/commands/` |
| `Logos/**/*.lean` | `.claude/context/project/lean4/` |
| `docs/*.tex` | `.claude/context/project/logic/` |

---

## Edge Case Scenarios

### Scenario A: No Tags Found

If user runs `/learn Logos/` but no tags exist:

```
## No Tags Found

Scanned files in: Logos/
No FIX:, NOTE:, or TODO: tags detected.

Nothing to create.
```

Exits gracefully without prompts.

### Scenario B: Only FIX: Tags

If only FIX: tags are found:

- Display tag summary with only FIX: tags section
- AskUserQuestion offers only "Fix-it task" option (no NOTE:/TODO: options)
- User can choose to create or skip

### Scenario C: Large Number of TODO Items

If more than 20 TODO: tags are found:

The AskUserQuestion prompt includes an option:

```json
{
  "options": [
    {
      "label": "Select all TODO items",
      "description": "Create tasks for all 23 TODO: tags"
    },
    ...individual items...
  ]
}
```

This prevents overwhelming the UI with too many checkboxes.

### Scenario D: User Selects Nothing

If user deselects all task types:

```
## No Tasks Created

You chose not to create any tasks from the 4 tags found.

Run /learn again if you change your mind.
```

Exits gracefully without creating tasks or git commits.

---

## Comparison: Old vs New Flow

### Old Pattern (Deprecated)

```
User runs: /learn Logos/ --dry-run
  → skill-learn (thin wrapper)
    → learn-agent (subagent via Task tool)
      → Returns JSON metadata to skill
    → skill reads metadata, displays preview
User reviews preview
User runs: /learn Logos/ (without --dry-run)
  → Same delegation flow, but creates tasks automatically
```

**Issues**:
- Required two commands (dry-run, then execute)
- Background subagent process
- No granular control (all or nothing)

### New Pattern (Current)

```
User runs: /learn Logos/
  → skill-learn (direct execution)
    → Scans tags inline
    → Displays findings
    → AskUserQuestion: task types
    → AskUserQuestion: TODO items (if applicable)
    → Creates selected tasks
```

**Benefits**:
- Single command, interactive flow
- Synchronous execution, no background process
- Granular control over which tasks to create
- Always preview before creation

---

## Summary

This example demonstrated:

1. **Direct Execution**: No subagent delegation, all logic in skill-learn
2. **Interactive Selection**: AskUserQuestion for task type and TODO item choices
3. **Tag Extraction**: Using grep patterns for multiple file types
4. **Task Grouping**: FIX:/NOTE: grouped into fix-it task, TODO: individual or topic-grouped tasks
5. **Topic Analysis**: Automatic clustering of related TODO items by shared terms and context
6. **User Control**: Granular selection of what to create and how to group
7. **Edge Case Handling**: Graceful handling of no tags, user cancelation, large TODO lists

The `/learn` command provides:
- Automated task discovery from embedded source comments
- Interactive preview-then-select workflow
- **Smart topic grouping for related TODO items**
- Structured task creation following project standards
- User control over which tasks are created and grouping approach

---

## Related Documentation

- [Research Flow Example](research-flow-example.md) - End-to-end research flow
- [Creating Commands](../guides/creating-commands.md) - Command creation guide
- [Creating Skills](../guides/creating-skills.md) - Skill creation guide (direct execution pattern)
- `.claude/commands/learn.md` - Command definition
- `.claude/skills/skill-learn/SKILL.md` - Skill definition (direct execution, no agent)

---

**Document Version**: 2.0 (Updated 2026-01-20)
**Created**: 2026-01-20
**Maintained By**: ProofChecker Development Team
