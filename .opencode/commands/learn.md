---
description: Scan files for FIX:, NOTE:, TODO: tags and create structured tasks interactively
allowed-tools: Skill
argument-hint: [PATH...]
---

# /learn Command

Scans codebase files for embedded tags (`FIX:`, `NOTE:`, `TODO:`) and creates structured tasks based on user selection. This command helps capture work items embedded in source code comments.

## Arguments

- No args: Scan entire project for tags
- `PATH...` - Scan specific files or directories

## Interactive Flow

The command always runs interactively:
1. Scan files for tags
2. Display tag summary to user
3. Prompt for task type selection
4. Optionally prompt for individual TODO selection
5. **Optionally prompt for TODO topic grouping** (if 2+ TODOs selected)
6. Create selected tasks

This design ensures users always see what was found before any tasks are created.

## Tag Types and Task Generation

| Tag | Task Type | Description |
|-----|-----------|-------------|
| `FIX:` | fix-it-task | Grouped into single task for small changes |
| `NOTE:` | fix-it-task + learn-it-task | Creates both task types (with dependency) |
| `TODO:` | todo-task | Individual task per selected tag |

### Task Type Details

**fix-it-task**: Combines all FIX: and NOTE: tags into a single task describing fixes needed. Includes file paths and line references. Only offered if FIX: or NOTE: tags exist.

**learn-it-task**: Groups NOTE: tags by target context directory. Creates tasks to update `.opencode/context/` files based on the learnings. Only offered if NOTE: tags exist.

**todo-task**: One task per selected TODO: tag (or grouped by topic). Preserves original text as task description. Language detected from source file type.

### TODO Topic Grouping

When multiple TODO items are selected, the command analyzes them for semantic topics and offers grouping options:

1. **Accept suggested topic groups** - Creates grouped tasks based on shared terms, file sections, and action types
2. **Keep as separate tasks** - Traditional behavior (one task per TODO item)
3. **Create single combined task** - All TODO items in one task

**Topic detection uses**:
- Shared key terms (2+ significant terms in common)
- File section proximity (same directory)
- Action type similarity (implement, fix, document, test, refactor)

**Example topic groups**:
```
Group: "S5 Theorems" (2 items)
  - Add LSP configuration for S5
  - Add soundness theorem for S5

Group: "Utility Optimization" (1 item)
  - Optimize helper function
```

**Effort scaling for grouped tasks**:
- Base: 1 hour
- +30 minutes per additional item
- Example: 3 items = 2 hours

### Dependency Workflow for NOTE: Tags

When NOTE: tags exist and you select **both** fix-it and learn-it task types:

1. **Learn-it task is created first** - Updates context files based on learnings (NOTE: tags remain in source files)
2. **Fix-it task is created second with dependency** - Has `dependencies: [learn_it_task_num]` pointing to the learn-it task

This ensures proper workflow ordering:
- Learn-it task handles knowledge extraction to context files only
- Fix-it task handles file-local code changes and removes both NOTE: and FIX: tags (TODO: tags are left for separate tasks)

This dependency is only added when both task types are selected for NOTE: tags. If you select only one task type, no dependency is created.

## Supported Comment Styles

| File Type | Comment Prefix | Example |
|-----------|----------------|---------|
| Lua (`.lua`) | `--` | `-- FIX: Handle edge case` |
| LaTeX (`.tex`) | `%` | `% NOTE: Document this pattern` |
| Markdown (`.md`) | `<!--` | `<!-- TODO: Add section -->` |
| Python/Shell/YAML | `#` | `# FIX: Optimize loop` |

## Execution

### 1. Scan and Display

The skill scans specified paths and displays findings:

```
## Tag Scan Results

**Files Scanned**: nvim/lua/, docs/
**Tags Found**: 15

### FIX: Tags (5)
- `src/module.lua:23` - Handle edge case in parser
- `src/module.lua:45` - Fix off-by-one error
...

### NOTE: Tags (3)
- `docs/guide.tex:89` - Document this pattern
...

### TODO: Tags (7)
- `nvim/lua/Layer1/Modal.lua:67` - Add LSP configuration
...
```

### 2. Task Type Selection

User selects which task types to create:

```
[Task Types]
Which task types should be created?

[ ] fix-it task (Combine 8 FIX:/NOTE: tags into single task)
[ ] learn-it task (Update context from 3 NOTE: tags)
[ ] TODO tasks (Create tasks for 7 TODO: items)
```

### 3. TODO Item Selection

If "TODO tasks" is selected, user picks individual items:

```
[TODO Selection]
Select TODO items to create as tasks:

[ ] Add LSP configuration (nvim/lua/Layer1/Modal.lua:67)
[ ] Implement helper function (utils/helpers.lua:23)
...
```

For >20 TODO items, a "Select all" option is added.

### 4. Topic Grouping (if 2+ TODOs)

When multiple TODOs are selected, the command analyzes them for topics:

```
[TODO Topic Grouping]
How should TODO items be grouped into tasks?

( ) Accept suggested topic groups (Creates 2 grouped tasks: S5 Theorems (2 items), Utility Optimization (1 item))
( ) Keep as separate tasks (Creates 3 individual tasks)
( ) Create single combined task (Creates 1 task containing all 3 items)
```

### 5. Task Creation

Selected tasks are created in TODO.md and state.json.

## Output Examples

### Tags Found - Interactive Selection

```
## Tag Scan Results

**Files Scanned**: .
**Tags Found**: 15

### FIX: Tags (5)
- `src/module.lua:23` - Handle edge case in parser
- `src/module.lua:45` - Fix off-by-one error
- `docs/guide.tex:56` - Update outdated reference

### NOTE: Tags (3)
- `docs/guide.tex:89` - Document this pattern
- `.opencode/agents/foo.md:12` - Update context routing

### TODO: Tags (7)
- `nvim/lua/Layer1/Modal.lua:67` - Add LSP configuration
- `nvim/lua/utils/helpers.lua:23` - Implement helper function
...

---

[User selects task types and TODO items]

---

## Tasks Created from Tags

**Tags Processed**: 15

### Created Tasks

| # | Type | Title | Priority | Language |
|---|------|-------|----------|----------|
| 650 | fix-it | Fix issues from FIX:/NOTE: tags | High | neovim |
| 651 | learn-it | Update context files from NOTE: tags | Medium | meta |
| 652 | todo | Add LSP configuration | Medium | neovim |
| 653 | todo | Implement helper function | Medium | neovim |

---

**Next Steps**:
1. Review tasks in TODO.md
2. Run `/research 650` to begin
3. Progress through /research -> /plan -> /implement cycle
```

### No Tags Found

```
## No Tags Found

Scanned files in: nvim/lua/
No FIX:, NOTE:, or TODO: tags detected.

Nothing to create.
```

### No Selection Made

```
## Tag Scan Results
...

---

No task types selected. No tasks created.
```

## Examples

```bash
# Scan entire project interactively
/learn

# Scan specific directory
/learn nvim/lua/Layer1/

# Scan specific file
/learn docs/04-Metalogic.tex

# Scan multiple paths
/learn nvim/lua/ .opencode/agents/
```

## Notes

- The `--dry-run` flag is no longer supported. The interactive flow is inherently "preview first" - users always see findings before any tasks are created.
- Git commit is performed automatically after tasks are created.
- Task numbers are assigned sequentially from state.json.
