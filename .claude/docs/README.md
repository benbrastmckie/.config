# Claude Agent System Documentation

[Back to Config](../../README.md) | [Architecture](../ARCHITECTURE.md) | [CLAUDE.md](../CLAUDE.md)

This documentation provides comprehensive coverage of the `.claude/` agent system for Neovim configuration development.

---

## Documentation Map

```
.claude/docs/
├── README.md                    # This file - documentation hub
├── commands/                    # Command reference documentation
│   ├── README.md               # Commands overview
│   └── command-reference.md    # Complete command reference
├── skills/                      # Skill documentation
│   ├── README.md               # Skills overview
│   └── skill-reference.md      # Complete skill reference
├── workflows/                   # Workflow documentation
│   ├── README.md               # Workflows overview
│   ├── task-lifecycle.md       # Task state machine
│   └── implementation-cycle.md # Research → Plan → Implement
├── guides/                      # How-to guides
│   ├── user-installation.md    # Quick-start for new users
│   ├── copy-claude-directory.md # Copy .claude/ to other projects
│   ├── creating-commands.md    # How to create commands
│   ├── creating-skills.md      # How to create skills
│   └── context-management.md   # Context loading patterns
├── templates/                   # Reusable templates
│   ├── README.md               # Template overview
│   ├── command-template.md     # Command template
│   └── skill-template.md       # Skill template
└── reference/                   # Quick reference guides
    ├── quick-reference.md      # Essential commands and paths
    └── status-markers.md       # Status marker reference
```

---

## Quick Start

### Essential Commands

```bash
# Task Management
/task "Add new feature"          # Create new task
/task --sync                     # Sync TODO.md with state.json
/task --abandon 123              # Abandon task

# Development Workflow
/research 123                    # Research task
/plan 123                        # Create implementation plan
/implement 123                   # Execute implementation
/revise 123                      # Revise plan

# Maintenance
/review                          # Code review
/errors                          # Analyze errors
/todo                            # Archive completed tasks
/meta                            # System builder
```

### Key Paths

| Path | Description |
|------|-------------|
| `.claude/specs/TODO.md` | User-facing task list |
| `.claude/specs/state.json` | Machine-readable state |
| `.claude/specs/errors.json` | Error tracking |
| `.claude/specs/{N}_{SLUG}/` | Task artifacts |
| `.claude/commands/` | Slash command definitions |
| `.claude/skills/` | Specialized agent skills |
| `.claude/rules/` | Automatic behavior rules |
| `.claude/context/` | Domain knowledge and standards |

---

## System Overview

The `.claude/` directory implements a task management and automation system for Neovim configuration development with Lua.

### Core Components

| Component | Location | Purpose |
|-----------|----------|---------|
| Commands | `commands/` | User-invocable operations via `/command` |
| Skills | `skills/` | Specialized execution agents |
| Rules | `rules/` | Automatic behaviors based on paths |
| Context | `context/` | Domain knowledge and standards |
| Specs | `specs/` | Task artifacts and state |

### Architecture Principles

1. **Task-Based Workflow**: All work is tracked as numbered tasks
2. **Language-Based Routing**: Tasks route to specialized skills by language
3. **Atomic State Sync**: TODO.md and state.json stay synchronized
4. **Resume Support**: Interrupted work continues from checkpoint
5. **Git Integration**: Scoped commits after each operation

---

## Commands (9)

Commands are user-invocable operations triggered by `/command` syntax.

| Command | Purpose | Arguments |
|---------|---------|-----------|
| [/task](commands/README.md#task) | Create, manage, sync tasks | `"description"` or flags |
| [/research](commands/README.md#research) | Conduct research | `TASK_NUMBER [focus]` |
| [/plan](commands/README.md#plan) | Create implementation plans | `TASK_NUMBER` |
| [/implement](commands/README.md#implement) | Execute implementation | `TASK_NUMBER` |
| [/revise](commands/README.md#revise) | Revise plan | `TASK_NUMBER` |
| [/review](commands/README.md#review) | Code review | `[scope]` |
| [/errors](commands/README.md#errors) | Analyze errors | (reads errors.json) |
| [/todo](commands/README.md#todo) | Archive completed tasks | (no args) |
| [/meta](commands/README.md#meta) | System builder | `[domain]` or flags |

See [commands/README.md](commands/README.md) for complete documentation.

---

## Skills (8)

Skills are specialized agents invoked by commands or the orchestrator.

### Core Skills

| Skill | Purpose |
|-------|---------|
| [skill-orchestrator](skills/README.md#skill-orchestrator) | Central routing and coordination |
| [skill-status-sync](skills/README.md#skill-status-sync) | Atomic multi-file status updates |
| [skill-git-workflow](skills/README.md#skill-git-workflow) | Scoped git commits |

### Research Skills

| Skill | Purpose |
|-------|---------|
| [skill-researcher](skills/README.md#skill-researcher) | General web and codebase research |
| [skill-neovim-research](skills/README.md#skill-neovim-research) | Neovim API and Lua pattern research |

### Implementation Skills

| Skill | Purpose |
|-------|---------|
| [skill-planner](skills/README.md#skill-planner) | Create phased implementation plans |
| [skill-implementer](skills/README.md#skill-implementer) | General implementation |
| [skill-neovim-implementation](skills/README.md#skill-neovim-implementation) | TDD workflow for Neovim plugins |

See [skills/README.md](skills/README.md) for complete documentation.

---

## Rules (6)

Rules define automatic behaviors applied based on file paths.

| Rule | Scope | Purpose |
|------|-------|---------|
| [state-management.md](../rules/state-management.md) | `.claude/specs/**` | Task state patterns |
| [git-workflow.md](../rules/git-workflow.md) | All | Commit conventions |
| [neovim-lua.md](../rules/neovim-lua.md) | `**/*.lua` | Neovim/Lua patterns |
| [error-handling.md](../rules/error-handling.md) | `.claude/**` | Error recovery |
| [artifact-formats.md](../rules/artifact-formats.md) | `.claude/specs/**` | Artifact formats |
| [workflows.md](../rules/workflows.md) | `.claude/**` | Command lifecycle |

---

## Workflows

### Task Lifecycle

```
[NOT STARTED] → [RESEARCHING] → [RESEARCHED]
                                      │
                                      ▼
                            [PLANNING] → [PLANNED]
                                            │
                                            ▼
                                [IMPLEMENTING] → [COMPLETED]
                                       │
                                       ▼
                                  [PARTIAL] (enables resume)

Any state → [BLOCKED] (with reason)
Any state → [ABANDONED] (moves to archive)
```

### Typical Development Cycle

```bash
# 1. Create task
/task "Add new modal operator"     # Creates task #350

# 2. Research
/research 350                       # Creates research report
/research 350 "Z3 bitvector"       # With specific focus

# 3. Plan
/plan 350                           # Creates implementation plan

# 4. Implement
/implement 350                      # Executes with TDD
# If interrupted: /implement 350    # Resumes from checkpoint

# 5. Archive when done
/todo                               # Archives completed tasks
```

See [workflows/README.md](workflows/README.md) for complete documentation.

---

## Language-Based Routing

Tasks route to specialized skills based on their `language` field:

| Language | Research Skill | Implementation Skill |
|----------|---------------|---------------------|
| `lua` | skill-neovim-research | skill-neovim-implementation |
| `general` | skill-researcher | skill-implementer |
| `meta` | skill-researcher | skill-implementer |

### Language Detection (for /task)

| Keywords in Description | Detected Language |
|------------------------|-------------------|
| neovim, lua, plugin, lazy, telescope, lsp | lua |
| agent, command, skill, meta | meta |
| (default) | general |

---

## Artifacts

Tasks produce artifacts stored in `.claude/specs/{N}_{SLUG}/`:

### Directory Structure

```
.claude/specs/{N}_{SLUG}/
├── reports/
│   └── research-001.md         # Research report
├── plans/
│   └── implementation-001.md   # Implementation plan
└── summaries/
    └── implementation-summary-{DATE}.md
```

### Artifact Formats

| Type | Location | Purpose |
|------|----------|---------|
| Research Report | `reports/research-{NNN}.md` | Research findings |
| Implementation Plan | `plans/implementation-{NNN}.md` | Phased plan |
| Summary | `summaries/implementation-summary-{DATE}.md` | Completion summary |

---

## State Management

### Dual-File System

| File | Purpose | Format |
|------|---------|--------|
| `TODO.md` | User-facing task list | Markdown |
| `state.json` | Machine-readable state | JSON |

### Synchronization

Both files MUST stay synchronized. Updates use two-phase commit:

1. Read both files
2. Prepare updates in memory
3. Write state.json first (machine state)
4. Write TODO.md second (user-facing)
5. Rollback all on any failure

---

## Git Integration

### Commit Message Format

```
task {N}: {action} {description}

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

### Commit Actions

| Operation | Commit Message |
|-----------|----------------|
| Create task | `task {N}: create {title}` |
| Complete research | `task {N}: complete research` |
| Create plan | `task {N}: create implementation plan` |
| Complete phase | `task {N} phase {P}: {phase_name}` |
| Complete implementation | `task {N}: complete implementation` |
| Archive tasks | `todo: archive {N} completed tasks` |

---

## Neovim/Lua Development

### Testing Commands

```bash
# Run all tests with plenary
nvim --headless -c "PlenaryBustedDirectory tests/"

# Run specific test file
nvim --headless -c "PlenaryBustedFile tests/picker/scan_recursive_spec.lua"

# Run tests with minimal init
nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

# Check for Lua syntax errors
luacheck lua/
```

### Plugin Structure

```
lua/neotex/plugins/{category}/
├── init.lua         # Category loader
├── plugin-name.lua  # Plugin configuration
└── tests/           # Plugin-specific tests
```

---

## Related Documentation

### For New Users
- [User Installation Guide](guides/user-installation.md) - Quick-start for Claude Code
- [Copy .claude/ Directory](guides/copy-claude-directory.md) - Copy agent system to other projects

### System Architecture
- [ARCHITECTURE.md](../ARCHITECTURE.md) - Detailed system architecture
- [CLAUDE.md](../CLAUDE.md) - Quick reference entry point

### Context Organization
- [context/README.md](../context/README.md) - Context file organization
- `context/core/` - Reusable patterns
- `context/project/` - Project-specific context

### Neovim Configuration
- [nvim/CLAUDE.md](../../nvim/CLAUDE.md) - Neovim configuration guidelines
- [nvim/docs/](../../nvim/docs/) - Neovim documentation

---

[Back to Config](../../README.md) | [Architecture](../ARCHITECTURE.md) | [CLAUDE.md](../CLAUDE.md)
