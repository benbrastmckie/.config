# Research Report: Task #19

**Task**: 19 - adapt_claude_system_for_stock_neovim
**Started**: 2026-02-01T12:00:00Z
**Completed**: 2026-02-01T12:30:00Z
**Effort**: 2-4 hours for research, 8-16 hours for full implementation
**Dependencies**: None
**Sources/Inputs**: Codebase analysis (.claude/), existing documentation, Neovim configuration
**Artifacts**: specs/19_adapt_claude_system_for_stock_neovim/reports/research-001.md
**Standards**: report-format.md, subagent-return.md

## Executive Summary

- The current .claude/ system has a clear separation between **core** (domain-agnostic) and **project** (domain-specific) components
- Approximately 70% of the system is reusable; 30% is Lean/theorem-proving specific
- A stock Neovim configuration system requires: a new `project/neovim/` context layer, 1-2 Neovim-specific agents, and adaptation of existing commands/skills
- The recommended approach is a **layered extraction** model: Core Base -> Domain Layer -> Project-Specific Layer
- Existing Neovim integration documentation already exists (neovim-integration.md) and can serve as a starting point

## Context & Scope

This research analyzes the current .claude/ agent system to:
1. Categorize components as core/general-purpose vs Lean-specific vs adaptable
2. Document the agent architecture patterns
3. Understand Neovim configuration maintenance requirements
4. Design an approach for creating a stock .claude/ system for Neovim configurations

The goal is to produce a reusable agent system that can help maintain Neovim configurations with the same rigor as the current Lean theorem-proving system.

## Findings

### 1. Current .claude/ Directory Structure Analysis

```
.claude/
├── agents/              # 9 agents (3 Lean-specific)
├── commands/            # 13 commands (1 Lean-specific: /lake)
├── context/
│   ├── core/           # Domain-agnostic patterns, formats, orchestration
│   └── project/        # Domain-specific knowledge
│       ├── latex/      # LaTeX domain
│       ├── lean4/      # Lean 4 domain (REMOVE for stock)
│       ├── logic/      # Modal logic domain (REMOVE for stock)
│       ├── math/       # Math domain (REMOVE for stock)
│       ├── meta/       # Meta-system knowledge (KEEP)
│       ├── physics/    # Physics domain (REMOVE for stock)
│       ├── repo/       # Project-specific (ADAPT)
│       └── typst/      # Typst domain
├── docs/               # Documentation and guides
├── hooks/              # Session hooks (includes Neovim integration)
├── output/             # Command output templates
├── rules/              # Auto-applied rules (1 Lean-specific)
├── scripts/            # Utility scripts
├── skills/             # 15 skills (4 Lean-specific)
└── templates/          # Component templates
```

### 2. Component Categorization

#### Core/General-Purpose (Reusable - 70%)

**Commands** (12 of 13):
- `/task`, `/research`, `/plan`, `/implement`, `/revise`, `/review`
- `/todo`, `/errors`, `/meta`, `/learn`, `/refresh`, `/convert`
- These are domain-agnostic workflow commands

**Skills** (11 of 15):
- `skill-orchestrator` - Central routing (general)
- `skill-researcher` - General web/codebase research
- `skill-planner` - Implementation plan creation
- `skill-implementer` - General file implementation
- `skill-status-sync` - Atomic status updates
- `skill-git-workflow` - Git commit conventions
- `skill-meta` - System building
- `skill-refresh` - Process/file cleanup
- `skill-document-converter` - Document conversion
- `skill-latex-implementation` - LaTeX implementation
- `skill-typst-implementation` - Typst implementation

**Agents** (6 of 9):
- `general-research-agent` - Web/codebase research
- `general-implementation-agent` - File implementation
- `planner-agent` - Implementation planning
- `meta-builder-agent` - System building
- `latex-implementation-agent` - LaTeX implementation
- `typst-implementation-agent` - Typst implementation
- `document-converter-agent` - Document conversion

**Context** (core/):
- All of `core/` is reusable: orchestration, formats, patterns, standards, templates, workflows
- ~50 files of domain-agnostic patterns

**Rules** (6 of 7):
- `state-management.md` - Task state patterns
- `git-workflow.md` - Commit conventions
- `error-handling.md` - Error recovery
- `artifact-formats.md` - Report/plan formats
- `workflows.md` - Command lifecycle
- `latex.md` - LaTeX development

#### Lean-Specific (Remove for Stock - 30%)

**Commands** (1 of 13):
- `/lake` - Lean build with error repair

**Skills** (4 of 15):
- `skill-lean-research` - Lean/Mathlib research
- `skill-lean-implementation` - Lean proof implementation
- `skill-lake-repair` - Build with error repair
- `skill-learn` - FIX:/NOTE:/TODO: tag scanning (could be adapted)

**Agents** (3 of 9):
- `lean-research-agent` - Lean 4/Mathlib research
- `lean-implementation-agent` - Lean proof implementation

**Context** (project/):
- `project/lean4/` - 26 files of Lean-specific knowledge
- `project/logic/` - Modal/temporal logic domain
- `project/math/` - Mathematical domains
- `project/physics/` - Physics domains

**Rules** (1 of 7):
- `lean4.md` - Lean development rules

### 3. Architecture Patterns (Domain-Agnostic)

The system uses a **three-layer architecture**:

```
Commands (user interface)
    |
    v
Skills (thin wrappers, routing)
    |
    v
Agents (full execution, domain-specific)
```

**Key Patterns**:

1. **Thin Wrapper Skill Pattern**: Skills validate inputs and delegate to agents via Task tool
2. **Forked Subagent Pattern**: Context loaded only in agent conversation (token efficiency)
3. **Checkpoint-Based Execution**: GATE IN -> DELEGATE -> GATE OUT -> COMMIT
4. **Metadata File Return**: Agents write JSON to file, skills read for postflight
5. **Status Synchronization**: TODO.md (user-facing) + state.json (machine truth)
6. **Language-Based Routing**: Task language determines which skill/agent handles it

### 4. Neovim Configuration Maintenance Requirements

Based on the existing nvim/ directory analysis, a Neovim configuration system needs:

**Core Configuration Areas**:
- Plugin management (lazy.nvim patterns, plugin specs, lazy-lock.json)
- LSP configuration (lspconfig, mason, blink-cmp)
- Keymap management (keymaps, which-key integration)
- Autocmd patterns (ftplugin, autocommands)
- Treesitter configuration (parsers, queries, injections)
- UI plugins (bufferline, telescope, toggleterm)
- Custom Lua modules (neotex/lib/, plugin helpers)

**Typical Maintenance Tasks**:
- Add/remove/configure plugins
- Update keybindings
- Fix LSP issues
- Create ftplugin configurations
- Debug plugin conflicts
- Optimize startup time
- Create/modify autocommands

**Existing Neovim Resources**:
- `.claude/docs/guides/neovim-integration.md` - Claude Code integration with Neovim
- `nvim/CLAUDE.md` - Neovim configuration guidelines (referenced in main CLAUDE.md)
- `nvim/docs/CODE_STANDARDS.md` - Lua coding standards
- `nvim/docs/DOCUMENTATION_STANDARDS.md` - Documentation standards

### 5. Proposed Stock Neovim System Architecture

#### Layer 1: Core Base (Unchanged)

Keep all `core/` context files unchanged:
- Orchestration patterns
- Standard formats (report, plan, summary)
- Checkpoint workflow
- Delegation safety
- Error handling patterns

#### Layer 2: Neovim Domain Context

Create `project/neovim/` with:

```
project/neovim/
├── README.md                    # Overview and loading strategy
├── domain/
│   ├── lua-patterns.md         # Lua idioms for Neovim
│   ├── plugin-ecosystem.md     # lazy.nvim, common plugins
│   ├── lsp-overview.md         # LSP concepts, mason, nvim-lspconfig
│   └── neovim-api.md           # vim.api, vim.fn, vim.opt patterns
├── patterns/
│   ├── plugin-spec.md          # lazy.nvim plugin specification
│   ├── keymap-patterns.md      # vim.keymap.set, which-key
│   ├── autocommand-patterns.md # vim.api.nvim_create_autocmd
│   └── ftplugin-patterns.md    # after/ftplugin structure
├── standards/
│   ├── lua-style-guide.md      # Lua conventions
│   └── testing-patterns.md     # plenary.nvim testing
├── tools/
│   ├── lazy-nvim-guide.md      # lazy.nvim usage
│   ├── treesitter-guide.md     # Tree-sitter configuration
│   └── telescope-guide.md      # Telescope patterns
└── templates/
    ├── plugin-template.md      # New plugin spec template
    └── ftplugin-template.md    # New ftplugin template
```

#### Layer 3: Neovim-Specific Components

**New Agents** (2):
- `neovim-research-agent` - Research Neovim APIs, plugins, patterns
- `neovim-implementation-agent` - Implement Neovim configuration changes

**New Skills** (2):
- `skill-neovim-research` - Thin wrapper for neovim-research-agent
- `skill-neovim-implementation` - Thin wrapper for neovim-implementation-agent

**New Rules** (1):
- `neovim-lua.md` - Neovim Lua development rules (path: **/*.lua in nvim/)

**Updated Routing** (skill-orchestrator):
```
| Language | Research Skill | Implementation Skill |
|----------|---------------|---------------------|
| neovim | skill-neovim-research | skill-neovim-implementation |
```

#### Layer 4: Project-Specific Adaptation

Update `project/repo/project-overview.md` for the specific Neovim configuration:
- Directory structure
- Plugin organization
- Custom modules

### 6. Extensibility Design

The stock system should be designed for extension:

**Extension Points**:
1. **New Domain Contexts**: Add `project/{domain}/` directory
2. **New Language Routing**: Add to skill-orchestrator routing table
3. **New Agents**: Follow agent-template.md pattern
4. **New Rules**: Add path-based rules in `rules/`

**Configuration File** (proposed):
```yaml
# .claude/project.yaml or in CLAUDE.md frontmatter
domains:
  - neovim    # Enables project/neovim/ context
  - latex     # Enables project/latex/ context
default_language: neovim
```

### 7. Migration Path

**Phase 1: Extract Core**
1. Copy entire .claude/ directory
2. Remove Lean-specific components (lean4/, logic/, math/, physics/ contexts; lean-*.md agents/skills; /lake command; lean4.md rule)
3. Update CLAUDE.md to remove Lean references
4. Verify core commands work without Lean components

**Phase 2: Create Neovim Layer**
1. Create project/neovim/ context structure
2. Create neovim-research-agent and neovim-implementation-agent
3. Create skill-neovim-research and skill-neovim-implementation
4. Create neovim-lua.md rule
5. Update skill-orchestrator routing

**Phase 3: Adapt for Stock**
1. Generalize CLAUDE.md as template
2. Create project-overview.md template
3. Document extension process
4. Create copy-claude-guide.md (already exists, may need updates)

## Decisions

1. **Keep LaTeX and Typst support**: These are general document preparation languages that Neovim users commonly work with
2. **Remove all theorem-proving context**: Lean, logic, math, physics are too specialized for stock system
3. **Create dedicated Neovim agents**: Rather than adapting general agents, create specialized neovim-research-agent and neovim-implementation-agent for better domain-specific tool access
4. **Maintain thin wrapper pattern**: Skills remain thin wrappers; agents do the heavy lifting
5. **Use existing neovim-integration.md as starting point**: The Claude Code Neovim integration docs provide foundation

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Neovim API changes frequently | Medium | Document version requirements, create update workflow |
| Plugin ecosystem fragmentation | Medium | Focus on popular, stable plugins (lazy.nvim, telescope, etc.) |
| Lua patterns differ from other languages | Low | Create comprehensive lua-patterns.md context |
| Users have varied Neovim setups | High | Design for modularity, don't assume specific structure |
| MCP tools not available for Neovim | Medium | Rely on Read/Write/Edit/Bash tools; document nvim commands |

## Implementation Recommendations

### Recommended Task Breakdown

1. **Task: Extract core .claude/ system** (2-3 hours)
   - Copy .claude/, remove Lean-specific components
   - Update CLAUDE.md, test core commands

2. **Task: Create project/neovim/ context** (4-6 hours)
   - Create domain/, patterns/, standards/, tools/, templates/ subdirectories
   - Write initial context files for Lua/Neovim patterns

3. **Task: Create neovim-research-agent** (2-3 hours)
   - Follow general-research-agent pattern
   - Add Neovim-specific search strategies

4. **Task: Create neovim-implementation-agent** (2-3 hours)
   - Follow general-implementation-agent pattern
   - Add Neovim-specific verification (`:checkhealth`, require() testing)

5. **Task: Create Neovim skills** (1-2 hours)
   - skill-neovim-research (thin wrapper)
   - skill-neovim-implementation (thin wrapper)

6. **Task: Create neovim-lua.md rule** (1 hour)
   - Lua coding standards
   - Neovim API patterns

7. **Task: Update routing and documentation** (2-3 hours)
   - Update skill-orchestrator
   - Update CLAUDE.md
   - Create/update copy-claude-guide.md

### Total Estimated Effort: 14-21 hours

## Appendix

### Search Queries Used
- Glob: `.claude/**/*.md` - All markdown files in .claude/
- Glob: `.claude/agents/**/*.md` - All agent files
- Glob: `.claude/skills/**/*.md` - All skill files
- Glob: `.claude/commands/*.md` - All command files
- Glob: `.claude/context/**/*.md` - All context files
- Grep: `neovim|nvim` in .claude/ - Existing Neovim references

### Key Files Analyzed
- `.claude/README.md` - System architecture documentation
- `.claude/CLAUDE.md` - Project configuration
- `.claude/context/index.md` - Context loading index
- `.claude/agents/general-research-agent.md` - Agent pattern
- `.claude/agents/lean-research-agent.md` - Domain-specific agent pattern
- `.claude/skills/skill-orchestrator/SKILL.md` - Routing logic
- `.claude/docs/guides/creating-agents.md` - Agent creation guide
- `.claude/docs/guides/creating-skills.md` - Skill creation guide
- `.claude/docs/guides/neovim-integration.md` - Existing Neovim docs

### References
- lazy.nvim documentation: https://github.com/folke/lazy.nvim
- nvim-lspconfig documentation: https://github.com/neovim/nvim-lspconfig
- Neovim Lua guide: https://neovim.io/doc/user/lua-guide.html
