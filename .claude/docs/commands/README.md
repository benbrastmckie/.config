# Command Reference

[Back to Docs](../README.md) | [Skills](../skills/README.md) | [Workflows](../workflows/README.md)

Commands are user-invocable operations triggered by `/command` syntax. Each command has a definition file in `.claude/commands/` with frontmatter specifying its behavior.

---

## Command Index

| Command | Purpose | Arguments |
|---------|---------|-----------|
| [/task](#task) | Create, manage, sync tasks | `"description"` or flags |
| [/research](#research) | Conduct research | `TASK_NUMBER [focus]` |
| [/plan](#plan) | Create implementation plans | `TASK_NUMBER` |
| [/implement](#implement) | Execute implementation | `TASK_NUMBER` |
| [/revise](#revise) | Revise plan version | `TASK_NUMBER` |
| [/review](#review) | Code review | `[scope]` |
| [/errors](#errors) | Analyze errors | (reads errors.json) |
| [/todo](#todo) | Archive completed tasks | (no args) |
| [/meta](#meta) | System builder | `[domain]` or flags |

---

## Task Management Commands

### /task

Create, recover, divide, sync, or abandon tasks.

**Definition**: [.claude/commands/task.md](../../commands/task.md)

**Usage**:
```bash
/task "Description"          # Create new task
/task --recover 343-345      # Recover from archive
/task --divide 326           # Split into subtasks
/task --sync                 # Sync TODO.md with state.json
/task --abandon 343-345      # Archive tasks
```

**What it does**:
1. Parses arguments to determine operation mode
2. Creates task entry in TODO.md and state.json
3. Auto-detects language from keywords (python, meta, general)
4. Assigns next available task number
5. Creates git commit

**Language Detection**:
| Keywords | Language |
|----------|----------|
| Z3, pytest, theory, semantic, Python | python |
| agent, command, skill, meta | meta |
| (default) | general |

---

### /todo

Archive completed and abandoned tasks.

**Definition**: [.claude/commands/todo.md](../../commands/todo.md)

**Usage**:
```bash
/todo                        # Archive completed tasks
```

**What it does**:
1. Reads TODO.md and state.json
2. Identifies tasks with [COMPLETED] or [ABANDONED] status
3. Moves to `.claude/specs/archive/`
4. Updates state.json to remove archived tasks
5. Creates git commit

---

## Development Workflow Commands

### /research

Conduct research on a task and create research reports.

**Definition**: [.claude/commands/research.md](../../commands/research.md)

**Usage**:
```bash
/research TASK_NUMBER              # Research task
/research 350 "Z3 bitvector ops"   # With specific focus
```

**What it does**:
1. Validates task exists and status allows research
2. Updates status to [RESEARCHING]
3. Routes to skill based on task language:
   - `python` → skill-python-research
   - `general`/`meta` → skill-researcher
4. Creates research report in `.claude/specs/{N}_{SLUG}/reports/`
5. Updates status to [RESEARCHED]
6. Creates git commit

**Allowed From Statuses**: `not_started`, `planned`, `partial`, `blocked`

**Produces**: `reports/research-{NNN}.md`

---

### /plan

Create phased implementation plans from research findings.

**Definition**: [.claude/commands/plan.md](../../commands/plan.md)

**Usage**:
```bash
/plan TASK_NUMBER            # Create implementation plan
/plan 350                    # Example
```

**What it does**:
1. Validates task exists and status allows planning
2. Updates status to [PLANNING]
3. Loads research report if available
4. Routes to skill-planner
5. Creates phased implementation plan
6. Updates status to [PLANNED]
7. Creates git commit

**Allowed From Statuses**: `not_started`, `researched`, `partial`

**Produces**: `plans/implementation-{NNN}.md`

---

### /implement

Execute implementation with resume support.

**Definition**: [.claude/commands/implement.md](../../commands/implement.md)

**Usage**:
```bash
/implement TASK_NUMBER       # Execute implementation
/implement 350               # Example (resumes if interrupted)
```

**What it does**:
1. Validates task exists and has plan
2. Updates status to [IMPLEMENTING]
3. Loads implementation plan
4. Detects resume point (phases marked [PARTIAL])
5. Routes to skill based on language:
   - `python` → skill-theory-implementation (TDD workflow)
   - `general`/`meta` → skill-implementer
6. Executes phases sequentially
7. Creates git commit after each phase
8. Updates status to [COMPLETED] or [PARTIAL]
9. Creates implementation summary

**Allowed From Statuses**: `planned`, `implementing`, `partial`, `researched`

**Produces**: `summaries/implementation-summary-{DATE}.md`

**Resume Behavior**:
- Scans plan for phase status markers
- `[COMPLETED]` phases are skipped
- `[PARTIAL]` or `[IN PROGRESS]` phase is resumed
- `[NOT STARTED]` phases execute normally

---

### /revise

Create new version of implementation plan.

**Definition**: [.claude/commands/revise.md](../../commands/revise.md)

**Usage**:
```bash
/revise TASK_NUMBER          # Create new plan version
/revise 350                  # Creates implementation-002.md
```

**What it does**:
1. Validates task has existing plan
2. Finds highest plan version number
3. Creates new plan version (implementation-{N+1}.md)
4. Updates TODO.md with new plan link
5. Creates git commit

**Allowed From Statuses**: `planned`, `implementing`, `partial`, `blocked`

**Produces**: `plans/implementation-{NNN}.md` (incremented version)

---

## Maintenance Commands

### /review

Review code and create analysis reports.

**Definition**: [.claude/commands/review.md](../../commands/review.md)

**Usage**:
```bash
/review                      # Review recent changes
/review "src/model_checker"  # Review specific scope
```

**What it does**:
1. Analyzes codebase or specified scope
2. Identifies issues and improvement opportunities
3. Creates review report
4. Optionally creates follow-up tasks

---

### /errors

Analyze errors and create fix plans.

**Definition**: [.claude/commands/errors.md](../../commands/errors.md)

**Usage**:
```bash
/errors                      # Analyze errors.json
```

**What it does**:
1. Reads `.claude/specs/errors.json`
2. Analyzes error patterns and frequency
3. Groups related errors
4. Creates fix plan with prioritization
5. Optionally creates tasks for fixes

**Error Categories**:
- `tool_failure` - External tool failed
- `status_sync_failure` - TODO.md/state.json desync
- `test_failure` - Tests failed
- `import_error` - Python import failed
- `z3_timeout` - Z3 solver timed out
- `git_commit_failure` - Git operation failed

---

### /meta

Interactive system builder for agent architectures.

**Definition**: [.claude/commands/meta.md](../../commands/meta.md)

**Usage**:
```bash
/meta                        # Start interactive interview
/meta "Python/Z3 development"  # Direct domain specification
/meta --analyze              # Analyze existing .claude/ structure
/meta --generate             # Generate from previous interview
```

**What it does**:
1. Conducts multi-stage interview about domain and use cases
2. Designs command and skill architecture
3. Creates tasks with implementation plans for each component
4. Does NOT directly implement (creates tasks only)

**Modes**:
- **Interactive**: Multi-stage interview process
- **Direct**: Skip to architecture design with domain
- **Analyze**: Examine existing structure
- **Generate**: Re-run from last interview

---

## Command Structure

### Frontmatter

All commands have YAML frontmatter defining their behavior:

```yaml
---
description: Brief command description
allowed-tools: Read, Write, Edit, Bash(git:*)
argument-hint: TASK_NUMBER [focus]
model: claude-opus-4-5-20251101
---
```

### Common Fields

| Field | Purpose | Example |
|-------|---------|---------|
| `description` | Brief description for help | "Conduct research" |
| `allowed-tools` | Tools the command can use | `Read, Write, Bash(git:*)` |
| `argument-hint` | Argument syntax hint | `TASK_NUMBER [focus]` |
| `model` | Model to use | `claude-opus-4-5-20251101` |

---

## Command Lifecycle

All task-based commands follow this pattern:

```
┌──────────────────────────────────────────┐
│ 1. Parse Arguments                        │
│    Extract task number and options        │
├──────────────────────────────────────────┤
│ 2. Preflight                              │
│    Validate task exists and status allows │
│    Update status to "in progress" variant │
├──────────────────────────────────────────┤
│ 3. Check Language                         │
│    Read task language from state.json     │
│    Determine target skill                 │
├──────────────────────────────────────────┤
│ 4. Invoke Skill                           │
│    Delegate to skill with context         │
│    Wait for result (with timeout)         │
├──────────────────────────────────────────┤
│ 5. Process Results                        │
│    Validate return format                 │
│    Extract artifacts                      │
├──────────────────────────────────────────┤
│ 6. Postflight                             │
│    Update status atomically               │
│    Create git commit                      │
├──────────────────────────────────────────┤
│ 7. Return                                 │
│    Report summary to user                 │
└──────────────────────────────────────────┘
```

---

## Creating New Commands

See [guides/creating-commands.md](../guides/creating-commands.md) for detailed instructions.

**Quick checklist**:
1. Create `.claude/commands/{name}.md`
2. Add frontmatter with `description`, `allowed-tools`, `argument-hint`
3. Document usage, workflow, and artifacts
4. Test with valid and invalid inputs
5. Update this documentation

---

## Related Documentation

- [Skills Reference](../skills/README.md) - Skills that commands invoke
- [Workflows](../workflows/README.md) - Task lifecycle and state transitions
- [Command Template](../templates/command-template.md) - Template for new commands
- [ARCHITECTURE.md](../../ARCHITECTURE.md) - System architecture

---

[Back to Docs](../README.md) | [Skills](../skills/README.md) | [Workflows](../workflows/README.md)
