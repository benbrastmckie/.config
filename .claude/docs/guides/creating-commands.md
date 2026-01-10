# Creating Commands Guide

[Back to Docs](../README.md) | [Command Template](../templates/command-template.md)

How to create new slash commands for the ModelChecker `.claude/` agent system.

---

## Overview

Commands are user-facing operations invoked with `/command` syntax. They delegate to skills for execution.

### Key Principles

1. **Commands delegate, skills execute**: Commands route to skills, don't execute directly
2. **Keep commands simple**: Under 300 lines, focused on documentation
3. **Language-based routing**: Route to appropriate skill based on task language
4. **Consistent structure**: Follow the standard template

---

## Step-by-Step Process

### Step 1: Plan the Command

Before creating the command file, answer:

1. **What does this command do?**
   - Clear, single purpose
   - Fits the task lifecycle

2. **What arguments does it need?**
   - Task number? Options? Flags?
   - Required vs optional

3. **Which skills will it use?**
   - Different skills for different languages?
   - New skill needed?

4. **What artifacts does it create?**
   - Reports, plans, summaries?
   - Where in `.claude/specs/`?

### Step 2: Create Command File

Create `.claude/commands/{command-name}.md`:

```markdown
---
description: Brief description of command
allowed-tools: Read, Write, Edit, Bash(git:*)
argument-hint: TASK_NUMBER [options]
model: claude-opus-4-5-20251101
---

# /{command-name} Command

{Description of what this command does.}

## Usage

```bash
/{command-name} TASK_NUMBER
/{command-name} TASK_NUMBER "optional focus"
```

## What This Does

1. Validates task exists and status allows operation
2. Updates status to {in-progress variant}
3. Routes to skill based on task language
4. Creates artifacts
5. Updates status to {completed variant}
6. Creates git commit

## Language-Based Routing

| Language | Skill |
|----------|-------|
| `python` | skill-{python-variant} |
| `general` | skill-{general-variant} |

## Artifacts

| Type | Location |
|------|----------|
| {Type} | `.claude/specs/{N}_{SLUG}/{path}` |

## Prerequisites

- Task must exist in TODO.md/state.json
- Task status must be: {allowed statuses}
```

### Step 3: Define Frontmatter

The frontmatter controls command behavior:

```yaml
---
description: Brief description for help text
allowed-tools: Read, Write, Edit, Bash(git:*)
argument-hint: TASK_NUMBER [focus]
model: claude-opus-4-5-20251101
---
```

**Fields**:
| Field | Purpose | Example |
|-------|---------|---------|
| `description` | Shown in help | "Conduct research on a task" |
| `allowed-tools` | Tools available | `Read, Write, Bash(git:*)` |
| `argument-hint` | Usage syntax | `TASK_NUMBER [focus]` |
| `model` | Model to use | `claude-opus-4-5-20251101` |

### Step 4: Document Workflow

Explain the command workflow clearly:

```markdown
## What This Does

1. **Validate**: Check task exists and status allows operation
2. **Preflight**: Update status to [RESEARCHING]
3. **Route**: Determine skill based on task language
4. **Execute**: Invoke skill with task context
5. **Postflight**: Update status to [RESEARCHED]
6. **Commit**: Create git commit with artifacts
```

### Step 5: Add Examples

Include practical examples:

```markdown
## Examples

### Basic Usage

```bash
/research 350
```

Creates research report at `.claude/specs/350_task_name/reports/research-001.md`

### With Focus

```bash
/research 350 "Z3 bitvector operations"
```

Creates research report focused on Z3 bitvector patterns.
```

### Step 6: Test the Command

Test with both valid and invalid inputs:

```bash
# Test with valid task
/command 350

# Test with non-existent task
/command 999

# Test with wrong status
# (e.g., /implement on NOT STARTED task)

# Verify artifacts created
ls .claude/specs/350_*/

# Verify status updated
grep "350" .claude/specs/TODO.md
```

---

## Command Patterns

### Task-Based Command

Most commands operate on tasks:

```yaml
argument-hint: TASK_NUMBER [options]
```

**Workflow**:
1. Parse task number from arguments
2. Look up task in state.json
3. Validate status allows operation
4. Route to skill by language
5. Update status and commit

**Example**: `/research`, `/plan`, `/implement`

### Flag-Based Command

Commands with mode flags:

```yaml
argument-hint: --flag [value]
```

**Example**: `/task`
- `/task "description"` - Create new task
- `/task --sync` - Sync TODO.md with state.json
- `/task --abandon 123` - Abandon task

### No-Argument Command

Simple utility commands:

```yaml
argument-hint: (no arguments)
```

**Example**: `/todo`, `/errors`

---

## Language-Based Routing

Commands that operate on tasks should route to appropriate skills:

```markdown
## Language-Based Routing

| Language | Skill |
|----------|-------|
| `python` | skill-python-research |
| `general` | skill-researcher |
| `meta` | skill-researcher |
```

The orchestrator handles routing based on the task's `language` field in state.json.

---

## Integration with Skills

### Creating a New Skill

If your command needs a new skill:

1. Create skill at `.claude/skills/skill-{name}/SKILL.md`
2. Define trigger conditions
3. Implement workflow
4. Add to orchestrator routing

See [Creating Skills Guide](creating-skills.md).

### Using Existing Skills

For task-based commands, the orchestrator routes automatically:

| Language | Research | Implementation |
|----------|----------|----------------|
| `python` | skill-python-research | skill-theory-implementation |
| `general` | skill-researcher | skill-implementer |
| `meta` | skill-researcher | skill-implementer |

---

## Common Mistakes

### Mistake 1: Embedding Execution Logic

**Wrong**:
```markdown
## What This Does

1. Read the file at {path}
2. Parse the content
3. Extract patterns using grep...
```

**Right**:
```markdown
## What This Does

1. Validates task exists
2. Routes to skill-analyzer
3. Skill creates analysis report
```

Commands delegate to skills; they don't execute.

### Mistake 2: Missing Status Transitions

**Wrong**: No mention of status changes

**Right**:
```markdown
## Status Transitions

| From | To |
|------|-----|
| `not_started` | `researching` |
| `researching` | `researched` |
```

### Mistake 3: No Error Handling Documentation

**Wrong**: Only happy path documented

**Right**:
```markdown
## Error Handling

| Error | Response |
|-------|----------|
| Task not found | Error with suggestion to check task number |
| Wrong status | Error with current status and allowed operations |
```

---

## Validation Checklist

Before committing:

### Frontmatter
- [ ] `description` is clear and concise
- [ ] `allowed-tools` lists all needed tools
- [ ] `argument-hint` shows proper syntax

### Documentation
- [ ] Purpose clearly stated
- [ ] Usage with examples
- [ ] All arguments documented
- [ ] Workflow steps listed
- [ ] Artifacts documented
- [ ] Status transitions shown
- [ ] Prerequisites listed
- [ ] Error handling documented

### Quality
- [ ] Under 300 lines
- [ ] No embedded execution logic
- [ ] Delegates to skills
- [ ] Consistent with other commands

### Testing
- [ ] Works with valid arguments
- [ ] Handles invalid arguments gracefully
- [ ] Creates expected artifacts
- [ ] Status updates correctly
- [ ] Git commits created

---

## Example: Complete Command

```markdown
---
description: Analyze code patterns and quality
allowed-tools: Read, Grep, Glob, Write
argument-hint: TASK_NUMBER [scope]
model: claude-opus-4-5-20251101
---

# /analyze Command

Analyze code patterns and quality for a task.

## Usage

```bash
/analyze 350                    # Analyze task scope
/analyze 350 "theory_lib"       # Focus on area
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `TASK_NUMBER` | Yes | Task to analyze for |
| `scope` | No | Limit to path (default: full) |

## What This Does

1. Validates task exists
2. Routes to skill-code-analyzer
3. Skill scans code for patterns
4. Creates analysis report
5. Creates git commit

## Language-Based Routing

| Language | Skill |
|----------|-------|
| `python` | skill-python-analyzer |
| `general` | skill-analyzer |

## Artifacts

| Type | Location |
|------|----------|
| Analysis Report | `.claude/specs/{N}_{SLUG}/reports/analysis-001.md` |

## Prerequisites

- Task must exist

## Examples

### Full Analysis

```bash
/analyze 350
```

Analyzes full task scope.

### Focused Analysis

```bash
/analyze 350 "model_checker/theory_lib"
```

Analyzes only theory_lib directory.

## Related Commands

- `/review` - Broader code review
- `/research` - Research before analysis

## See Also

- [skill-analyzer](../../skills/skill-analyzer/SKILL.md)
- [Commands Reference](../docs/commands/README.md)
```

---

## Related Documentation

- [Command Template](../templates/command-template.md)
- [Creating Skills Guide](creating-skills.md)
- [Commands Reference](../commands/README.md)
- [Skills Reference](../skills/README.md)
- [ARCHITECTURE.md](../../ARCHITECTURE.md)

---

[Back to Docs](../README.md) | [Command Template](../templates/command-template.md)
