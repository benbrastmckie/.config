# Research Report: .opencode/ Directory Structure Analysis

**Date**: 2025-12-15
**Topic**: .opencode/ Utilities Structure and Organization
**Research Phase**: Domain Analysis

---

## Executive Summary

The `.opencode/` directory implements a NeoVim-focused configuration management system using a research-driven development workflow. It features a hierarchical agent architecture with orchestrator, primary agents, and specialized subagents for research, planning, implementation, and maintenance.

---

## Directory Structure

```
.opencode/
├── agent/
│   ├── neovim-orchestrator.md      # Main orchestrator
│   └── subagents/
│       ├── researcher.md
│       ├── planner.md
│       ├── reviser.md
│       ├── implementer.md
│       ├── code-generator.md
│       ├── code-modifier.md
│       ├── tester.md
│       ├── documenter.md
│       ├── codebase-analyzer.md
│       ├── docs-fetcher.md
│       ├── best-practices-researcher.md
│       ├── dependency-analyzer.md
│       ├── refactor-finder.md
│       ├── plugin-analyzer.md
│       ├── lsp-configurator.md
│       ├── keybinding-optimizer.md
│       ├── performance-profiler.md
│       ├── health-checker.md
│       └── cruft-finder.md
├── command/
│   ├── research.md
│   ├── plan.md
│   ├── revise.md
│   ├── implement.md
│   ├── test.md
│   ├── todo.md
│   ├── health-check.md
│   ├── optimize-performance.md
│   ├── remove-cruft.md
│   ├── update-docs.md
│   ├── empty-archive.md
│   ├── show-state.md
│   └── help.md
├── context/
│   ├── domain/
│   │   ├── neovim-architecture.md
│   │   ├── neotex-structure.md
│   │   ├── plugin-ecosystem.md
│   │   ├── lsp-system.md
│   │   ├── ai-integrations.md
│   │   ├── typesetting.md
│   │   ├── formal-verification.md
│   │   ├── email-integration.md
│   │   ├── git-integration.md
│   │   └── nixos-basics.md
│   ├── processes/
│   │   ├── research-workflow.md
│   │   ├── planning-workflow.md
│   │   ├── implementation-workflow.md
│   │   ├── revision-workflow.md
│   │   └── git-integration.md
│   ├── standards/
│   │   ├── lua-coding-standards.md
│   │   ├── plugin-standards.md
│   │   ├── documentation-standards.md
│   │   ├── testing-standards.md
│   │   └── validation-rules.md
│   └── templates/
│       ├── plan-template.md
│       ├── report-template.md
│       ├── plugin-config-template.md
│       └── commit-message-template.md
├── workflows/
│   ├── research-workflow.md
│   ├── planning-workflow.md
│   ├── implementation-workflow.md
│   └── revision-workflow.md
├── specs/
│   ├── README.md
│   ├── TODO.md
│   ├── .counter
│   └── archive/
│       └── .gitkeep
├── state/
│   ├── README.md
│   └── global.json
├── ARCHITECTURE.md
├── BUILD_COMPLETE.md
├── QUICK_START.md
└── README.md
```

---

## Artifact Categories

### 1. **Commands** (`command/`)

Primary workflow commands:

| Command | Purpose | Agent Used |
|---------|---------|------------|
| `/research` | Research a topic | researcher |
| `/plan` | Create implementation plan | planner |
| `/revise` | Revise existing plan | reviser |
| `/implement` | Execute implementation plan | implementer |
| `/test` | Run configuration tests | tester |
| `/todo` | Show project status | (none) |
| `/health-check` | Run :checkhealth | health-checker |
| `/optimize-performance` | Analyze performance | performance-profiler |
| `/remove-cruft` | Find unused code | cruft-finder |
| `/update-docs` | Update documentation | documenter |
| `/empty-archive` | Clean archived projects | (none) |
| `/show-state` | Display system state | (none) |
| `/help` | Show help information | (none) |

**Format**: Markdown files with command definitions
**No frontmatter**: Different structure from Claude Code commands

### 2. **Agents** (`agent/`)

#### Orchestrator
- `neovim-orchestrator.md` - Routes requests to primary agents

#### Primary Agents
- `researcher` - Multi-faceted research
- `planner` - Implementation plan creation
- `reviser` - Plan revision
- `implementer` - Plan execution

#### Research Subagents
- `codebase-analyzer` - Analyze codebase structure
- `docs-fetcher` - Fetch external documentation
- `best-practices-researcher` - Research best practices
- `dependency-analyzer` - Analyze dependencies
- `refactor-finder` - Identify refactoring opportunities

#### Implementation Subagents
- `code-generator` - Generate new code
- `code-modifier` - Modify existing code
- `tester` - Run tests
- `documenter` - Update documentation

#### NeoVim-Specific Subagents
- `plugin-analyzer` - Analyze plugin configurations
- `lsp-configurator` - Configure LSP servers
- `keybinding-optimizer` - Optimize keybindings
- `performance-profiler` - Profile performance
- `health-checker` - Run health checks
- `cruft-finder` - Find unused code

**Format**: Markdown files with agent definitions
**Hierarchy**: 
1. Orchestrator (routes)
2. Primary agents (coordinate)
3. Subagents (execute)

### 3. **Context Files** (`context/`)

#### Domain Knowledge (`context/domain/`)
Technical documentation about NeoVim ecosystem:
- Architecture
- Plugin systems
- LSP integration
- AI tools
- Typesetting (LaTeX)
- Formal verification (Lean)
- Email integration
- Git workflows
- NixOS basics

#### Process Workflows (`context/processes/`)
Workflow documentation:
- Research workflow
- Planning workflow
- Implementation workflow
- Revision workflow
- Git integration

#### Standards (`context/standards/`)
Coding and documentation standards:
- Lua coding conventions
- Plugin standards
- Documentation standards
- Testing standards
- Validation rules

#### Templates (`context/templates/`)
File templates:
- Plan template
- Report template
- Plugin config template
- Commit message template

### 4. **Workflows** (`workflows/`)

Detailed workflow definitions (may overlap with `context/processes/`):
- Research workflow
- Planning workflow
- Implementation workflow
- Revision workflow

### 5. **Specs** (`specs/`)

Project tracking and specifications:
- `README.md` - Overview
- `TODO.md` - Project status
- `.counter` - Project numbering
- Individual project directories: `NNN_project_name/`
  - `reports/` - Research reports
  - `plans/` - Implementation plans
  - `state.json` - Project state

### 6. **State** (`state/`)

System state tracking:
- `global.json` - Global state
- `README.md` - State documentation

### 7. **Root Documentation**

- `ARCHITECTURE.md` - System architecture
- `BUILD_COMPLETE.md` - Build completion status
- `QUICK_START.md` - Quick start guide
- `README.md` - Main README

---

## Key Differences from .claude/

| Aspect | .claude/ | .opencode/ |
|--------|----------|-----------|
| Command directory | `commands/` | `command/` |
| Agent directory | `agents/` | `agent/` |
| Hooks | ✅ Yes | ❌ No |
| TTS files | ✅ Yes | ❌ No |
| Context files | ❌ No | ✅ Yes |
| Workflows | ❌ No | ✅ Yes |
| Specs tracking | ❌ No | ✅ Yes |
| State management | `state/global.json` | `state/global.json` |
| Documentation | `docs/` (extensive) | Root files + context/ |
| Local/Global | ✅ Yes | ❌ No (single location) |

---

## Entry Types for .opencode/ Picker

Based on the structure, the picker should display:

### Primary Sections
1. **Commands** - 13 commands in `command/`
2. **Agents** - Orchestrator + 19 subagents
3. **Context - Domain** - 10 domain knowledge files
4. **Context - Processes** - 5 process workflow files
5. **Context - Standards** - 5 standards files
6. **Context - Templates** - 4 template files
7. **Workflows** - 4 workflow files
8. **Specs** - Projects (dynamic list from `specs/`)
9. **State** - State files
10. **Documentation** - Root markdown files

### Hierarchical Display

```
[Commands]                           Workflow commands
  ├─ /research                      Research a topic
  │  └─ researcher                  Research specialist
  ├─ /plan                          Create implementation plan
  │  └─ planner                     Plan generation
  ├─ /implement                     Execute plan
  │  └─ implementer                 Implementation agent
  └─ /health-check                  Run health checks
     └─ health-checker              Health check agent

[Agents]                            Subagents (standalone)
  ├─ neovim-orchestrator            Main orchestrator
  ├─ code-generator                 Generate code
  └─ documenter                     Update docs

[Context - Domain]                  Domain knowledge
  ├─ neovim-architecture            NeoVim core concepts
  ├─ plugin-ecosystem               Plugin system
  └─ lsp-system                     LSP integration

[Context - Standards]               Coding standards
  ├─ lua-coding-standards           Lua conventions
  └─ plugin-standards               Plugin patterns

[Workflows]                         Process workflows
  ├─ research-workflow              Research process
  └─ implementation-workflow        Implementation process

[Specs]                             Active projects
  ├─ TODO.md                        Project status
  └─ [Dynamic project list]

[Documentation]                     System docs
  ├─ ARCHITECTURE.md                System design
  ├─ QUICK_START.md                 Getting started
  └─ README.md                      Overview
```

---

## Agent-Command Relationships

Unlike `.claude/`, `.opencode/` has a clear 1:1 or 1:many mapping:

| Command | Primary Agent | Additional Subagents |
|---------|---------------|---------------------|
| /research | researcher | codebase-analyzer, docs-fetcher, best-practices-researcher |
| /plan | planner | - |
| /revise | reviser | - |
| /implement | implementer | code-generator, code-modifier, tester, documenter |
| /health-check | health-checker | - |
| /optimize-performance | performance-profiler | - |
| /remove-cruft | cruft-finder | - |
| /update-docs | documenter | - |

**Note**: Orchestrator routes to primary agents, which then delegate to subagents.

---

## Keybinding Needs

Unlike `.claude/` picker, `.opencode/` picker doesn't need:
- ❌ `Ctrl-l` (Load locally) - No local/global distinction
- ❌ `Ctrl-u` (Update from global) - No sync operations
- ❌ `Ctrl-s` (Save to global) - No sync operations

Should have:
- ✅ `Enter` - Context-aware action (run command or open file)
- ✅ `Ctrl-e` - Edit file
- ✅ `Ctrl-r` - Run command (if command entry)
- ✅ `Esc` - Close picker
- ✅ Preview scrolling (`Ctrl-u`, `Ctrl-d`, `Ctrl-f`, `Ctrl-b`)

---

## Metadata Extraction

Commands don't have frontmatter, but agents do:

```markdown
<!-- Example from agent file -->
# Researcher Agent

**Purpose**: Conduct multi-faceted research on NeoVim topics

## Capabilities
- Codebase analysis
- Documentation fetching
- Best practices research
```

Extraction strategy:
1. Commands: Parse `# /command` heading + description paragraph
2. Agents: Parse purpose/description from header
3. Context files: Parse `# Title` heading
4. Specs: Parse project directory names

---

## File Scanning Requirements

### Commands
```lua
vim.fn.glob("/home/benjamin/.config/.opencode/command/*.md")
```

### Agents
```lua
vim.fn.glob("/home/benjamin/.config/.opencode/agent/*.md")  -- Orchestrator
vim.fn.glob("/home/benjamin/.config/.opencode/agent/subagents/*.md")  -- Subagents
```

### Context Files
```lua
vim.fn.glob("/home/benjamin/.config/.opencode/context/domain/*.md")
vim.fn.glob("/home/benjamin/.config/.opencode/context/processes/*.md")
vim.fn.glob("/home/benjamin/.config/.opencode/context/standards/*.md")
vim.fn.glob("/home/benjamin/.config/.opencode/context/templates/*.md")
```

### Workflows
```lua
vim.fn.glob("/home/benjamin/.config/.opencode/workflows/*.md")
```

### Specs
```lua
vim.fn.glob("/home/benjamin/.config/.opencode/specs/*/*.md")  -- Projects
"/home/benjamin/.config/.opencode/specs/TODO.md"
```

---

## State Files

```lua
"/home/benjamin/.config/.opencode/state/global.json"
```

---

## Display Considerations

### No Local/Global Distinction
- No asterisk prefix needed
- Simpler display format

### Hierarchical Grouping
- Group context files by subdirectory
- Group agents by role (orchestrator, primary, subagents)
- Group commands by workflow type

### Sorting
- Commands: Workflow order (research → plan → implement → maintenance)
- Agents: Alphabetical within groups
- Context: Alphabetical within categories
- Specs: By project number (001, 002, etc.)

---

## Recommendations

### 1. Entry Type System

```lua
entry_types = {
  "command",           -- /research, /plan, etc.
  "agent_orchestrator", -- neovim-orchestrator
  "agent_primary",     -- researcher, planner, etc.
  "agent_subagent",    -- code-generator, tester, etc.
  "context_domain",    -- Domain knowledge files
  "context_process",   -- Process workflow files
  "context_standard",  -- Standards files
  "context_template",  -- Template files
  "workflow",          -- Workflow definition files
  "spec_todo",         -- TODO.md
  "spec_project",      -- Project directories
  "state",             -- State files
  "doc_root",          -- Root documentation
}
```

### 2. Section Ordering (descending sort)

1. Documentation (root)
2. State
3. Specs
4. Workflows
5. Context - Templates
6. Context - Standards
7. Context - Processes
8. Context - Domain
9. Agents
10. Commands

### 3. Keybinding Scheme

| Key | Action |
|-----|--------|
| `<Enter>` | Run command or open file |
| `<Ctrl-e>` | Edit file in buffer |
| `<Ctrl-r>` | Run command with arguments |
| `<Esc>` | Close picker |
| `<Ctrl-u/d/f/b>` | Preview scrolling |

### 4. Preview Content

- Commands: Full file content
- Agents: Full agent definition
- Context files: Full content
- Specs: Project structure summary
- State: JSON formatted

---

## Next Steps

1. Design picker module structure (reuse .claude/ patterns)
2. Create parser for .opencode/ artifacts
3. Create entry formatters for each entry type
4. Implement keybindings
5. Create command registration
6. Add to which-key configuration
