# Quick Reference

[Back to Docs](../README.md)

Essential commands, paths, and patterns for the Neovim configuration `.claude/` agent system.

---

## Commands

### Task Management

```bash
/task "Description"          # Create new task
/task --recover 343-345      # Recover from archive
/task --divide 326           # Split into subtasks
/task --sync                 # Sync TODO.md with state.json
/task --abandon 343-345      # Abandon tasks
```

### Development Workflow

```bash
/research 350                # Research task
/research 350 "focus"        # Research with focus
/plan 350                    # Create implementation plan
/implement 350               # Execute implementation (resumes if interrupted)
/revise 350                  # Create new plan version
```

### Maintenance

```bash
/review                      # Code review
/review "scope"              # Review specific area
/errors                      # Analyze errors.json
/todo                        # Archive completed tasks
/meta                        # System builder
```

---

## Key Paths

| Path | Description |
|------|-------------|
| `.claude/specs/TODO.md` | Task list (user-facing) |
| `.claude/specs/state.json` | Machine state |
| `.claude/specs/errors.json` | Error tracking |
| `.claude/specs/{N}_{SLUG}/` | Task artifacts |
| `.claude/commands/` | Command definitions |
| `.claude/skills/` | Skill definitions |
| `.claude/rules/` | Behavior rules |
| `.claude/context/` | Domain knowledge |

---

## Status Markers

### Task Status

| Marker | Meaning |
|--------|---------|
| `[NOT STARTED]` | No work begun |
| `[RESEARCHING]` | Research in progress |
| `[RESEARCHED]` | Research complete |
| `[PLANNING]` | Plan in progress |
| `[PLANNED]` | Plan complete |
| `[IMPLEMENTING]` | Implementation in progress |
| `[COMPLETED]` | Task finished |
| `[PARTIAL]` | Interrupted, resumable |
| `[BLOCKED]` | Cannot proceed |
| `[ABANDONED]` | Task cancelled |

### Phase Status

| Marker | Meaning |
|--------|---------|
| `[NOT STARTED]` | Phase not begun |
| `[IN PROGRESS]` | Currently executing |
| `[COMPLETED]` | Phase finished |
| `[PARTIAL]` | Interrupted |
| `[BLOCKED]` | Cannot proceed |

---

## Language Routing

| Language | Research Skill | Implementation Skill |
|----------|---------------|---------------------|
| `lua` | skill-neovim-research | skill-neovim-implementation |
| `general` | skill-researcher | skill-implementer |
| `meta` | skill-researcher | skill-implementer |

### Language Detection (for /task)

| Keywords | Language |
|----------|----------|
| neovim, lua, plugin, telescope, lazy | lua |
| agent, command, skill, meta | meta |
| (default) | general |

---

## Artifact Locations

```
.claude/specs/{N}_{SLUG}/
├── reports/
│   └── research-001.md
├── plans/
│   └── implementation-001.md
└── summaries/
    └── implementation-summary-{DATE}.md
```

---

## Git Commits

### Format

```
task {N}: {action} {description}

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

### Actions

| Operation | Commit |
|-----------|--------|
| Create task | `task {N}: create {title}` |
| Complete research | `task {N}: complete research` |
| Create plan | `task {N}: create implementation plan` |
| Complete phase | `task {N} phase {P}: {phase_name}` |
| Complete task | `task {N}: complete implementation` |
| Archive | `todo: archive {N} completed tasks` |

---

## Testing (Neovim/Lua)

```bash
# Run all tests with plenary
nvim --headless -c "PlenaryBustedDirectory tests/"

# Run specific test file
nvim --headless -c "PlenaryBustedFile tests/picker/scan_recursive_spec.lua"

# Run tests with verbose output
nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

# Check for Lua syntax errors
luacheck lua/
```

---

## Plugin Structure

```
lua/neotex/plugins/{category}/
├── init.lua         # Category loader
├── plugin-name.lua  # Plugin configuration
└── utils.lua        # Category-specific utilities
```

---

## Skills

### Core

| Skill | Purpose |
|-------|---------|
| skill-orchestrator | Central routing |
| skill-status-sync | Status updates |
| skill-git-workflow | Git commits |

### Research

| Skill | Purpose |
|-------|---------|
| skill-researcher | General research |
| skill-neovim-research | Neovim/Lua research |

### Implementation

| Skill | Purpose |
|-------|---------|
| skill-planner | Create plans |
| skill-implementer | General implementation |
| skill-neovim-implementation | Neovim/Lua TDD |

---

## Rules

| Rule | Scope |
|------|-------|
| state-management.md | `.claude/specs/**` |
| git-workflow.md | All |
| neovim-lua.md | `**/*.lua` |
| error-handling.md | `.claude/**` |
| artifact-formats.md | `.claude/specs/**` |
| workflows.md | `.claude/**` |

---

## Return Format

```json
{
  "status": "completed|partial|failed|blocked",
  "summary": "Brief summary",
  "artifacts": [{"type": "...", "path": "...", "summary": "..."}],
  "metadata": {"session_id": "...", "duration_seconds": 123, "agent_type": "..."},
  "errors": [],
  "next_steps": "..."
}
```

---

## Documentation

| Document | Purpose |
|----------|---------|
| [CLAUDE.md](../../CLAUDE.md) | Entry point |
| [ARCHITECTURE.md](../../ARCHITECTURE.md) | System design |
| [docs/README.md](../README.md) | Documentation hub |
| [commands/README.md](../commands/README.md) | Command reference |
| [skills/README.md](../skills/README.md) | Skill reference |
| [workflows/README.md](../workflows/README.md) | Workflow reference |

---

[Back to Docs](../README.md)
