# Implementation Plan: Task #19

- **Task**: 19 - adapt_claude_system_for_stock_neovim
- **Status**: [NOT STARTED]
- **Effort**: 14-21 hours
- **Dependencies**: None
- **Research Inputs**: [specs/19_adapt_claude_system_for_stock_neovim/reports/research-001.md]
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: meta
- **Lean Intent**: false

## Overview

This plan adapts the current Lean-focused .claude/ agent system into a stock configuration for Neovim maintenance. The research identified that ~70% of the system is reusable core infrastructure, while ~30% is Lean-specific and must be replaced with Neovim-specific components. The approach uses a layered extraction model: keep the domain-agnostic core, remove theorem-proving artifacts, create a Neovim domain layer, and document the extension process for future domain additions.

### Research Integration

Key findings from research-001.md integrated into this plan:
- Component categorization (12/13 commands reusable, 11/15 skills reusable, 6/9 agents reusable)
- Three-layer architecture pattern (Commands -> Skills -> Agents)
- Neovim domain requirements (plugin management, LSP, keymaps, autocmds, treesitter)
- Proposed project/neovim/ context structure with domain/, patterns/, standards/, tools/, templates/
- Extensibility design via domain contexts, language routing, and path-based rules

## Goals & Non-Goals

**Goals**:
- Extract a clean, Lean-free core .claude/ system
- Create comprehensive Neovim domain context layer
- Build neovim-research-agent and neovim-implementation-agent
- Update routing in skill-orchestrator for neovim language
- Document extension process for adding new domains
- Maintain existing core functionality (task management, status sync, git workflow)

**Non-Goals**:
- Supporting multiple Neovim configuration frameworks (focus on lazy.nvim)
- Creating MCP tools for Neovim (rely on Read/Write/Edit/Bash)
- Automating Neovim plugin updates (manual workflow)
- Testing across multiple Neovim versions (target stable)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Incomplete Lean removal | High | Medium | Systematic grep/search for lean, theorem, proof references |
| Neovim API instability | Medium | Low | Focus on stable APIs, document version requirements |
| Plugin ecosystem fragmentation | Medium | Medium | Document common patterns for popular plugins only |
| Users have varied setups | High | High | Design for modularity, avoid assuming specific structure |
| Missing core dependencies | High | Low | Test commands after extraction before adding Neovim layer |

## Implementation Phases

### Phase 1: Core Extraction and Cleanup [NOT STARTED]

**Goal**: Remove all Lean-specific components and verify core commands still function

**Tasks**:
- [ ] Create backup of current .claude/ state
- [ ] Remove Lean-specific commands: /lake
- [ ] Remove Lean-specific skills: skill-lean-research, skill-lean-implementation, skill-lake-repair
- [ ] Remove Lean-specific agents: lean-research-agent, lean-implementation-agent
- [ ] Remove Lean-specific rules: lean4.md
- [ ] Remove Lean-specific context: project/lean4/, project/logic/, project/math/, project/physics/
- [ ] Update CLAUDE.md to remove all Lean references
- [ ] Update skill-orchestrator to remove lean language routing
- [ ] Grep for remaining lean/theorem/proof references and remove

**Timing**: 2-3 hours

**Files to modify**:
- `.claude/commands/lake.md` - Delete
- `.claude/skills/skill-lean-research/` - Delete directory
- `.claude/skills/skill-lean-implementation/` - Delete directory
- `.claude/skills/skill-lake-repair/` - Delete directory
- `.claude/agents/lean-research-agent.md` - Delete
- `.claude/agents/lean-implementation-agent.md` - Delete
- `.claude/rules/lean4.md` - Delete
- `.claude/context/project/lean4/` - Delete directory
- `.claude/context/project/logic/` - Delete directory
- `.claude/context/project/math/` - Delete directory
- `.claude/context/project/physics/` - Delete directory
- `.claude/CLAUDE.md` - Remove Lean sections
- `.claude/skills/skill-orchestrator/SKILL.md` - Remove lean routing

**Verification**:
- grep -r "lean\|theorem\|proof" .claude/ returns no results (excluding this plan)
- Core commands (/task, /research, /plan, /implement, /todo) remain functional
- state.json and TODO.md structure unchanged

---

### Phase 2: Create Neovim Domain Context [NOT STARTED]

**Goal**: Build comprehensive Neovim knowledge base for agents

**Tasks**:
- [ ] Create project/neovim/ directory structure
- [ ] Create domain/lua-patterns.md - Lua idioms for Neovim
- [ ] Create domain/plugin-ecosystem.md - lazy.nvim, common plugins
- [ ] Create domain/lsp-overview.md - LSP concepts, mason, nvim-lspconfig
- [ ] Create domain/neovim-api.md - vim.api, vim.fn, vim.opt patterns
- [ ] Create patterns/plugin-spec.md - lazy.nvim plugin specification
- [ ] Create patterns/keymap-patterns.md - vim.keymap.set, which-key
- [ ] Create patterns/autocommand-patterns.md - vim.api.nvim_create_autocmd
- [ ] Create patterns/ftplugin-patterns.md - after/ftplugin structure
- [ ] Create standards/lua-style-guide.md - Lua conventions
- [ ] Create standards/testing-patterns.md - plenary.nvim testing
- [ ] Create tools/lazy-nvim-guide.md - lazy.nvim usage
- [ ] Create tools/treesitter-guide.md - Tree-sitter configuration
- [ ] Create tools/telescope-guide.md - Telescope patterns
- [ ] Create templates/plugin-template.md - New plugin spec template
- [ ] Create templates/ftplugin-template.md - New ftplugin template
- [ ] Create project/neovim/README.md - Overview and loading strategy

**Timing**: 4-6 hours

**Files to modify**:
- `.claude/context/project/neovim/` - Create entire directory structure
- `.claude/context/index.md` - Add neovim context references

**Verification**:
- All 17 context files created with meaningful content
- README.md provides clear loading guidance
- Context files cross-reference each other appropriately

---

### Phase 3: Create Neovim Agents [NOT STARTED]

**Goal**: Build specialized agents for Neovim research and implementation

**Tasks**:
- [ ] Create neovim-research-agent.md following general-research-agent pattern
  - Add Neovim-specific search strategies (plugin docs, Neovim API, lua patterns)
  - Include lazy-loading of project/neovim/ context files
  - Define research output format for Neovim findings
- [ ] Create neovim-implementation-agent.md following general-implementation-agent pattern
  - Add Neovim-specific verification (checkhealth, require() testing)
  - Include lazy-loading of project/neovim/ context files
  - Define implementation patterns for plugins, keymaps, autocmds

**Timing**: 2-3 hours

**Files to modify**:
- `.claude/agents/neovim-research-agent.md` - Create
- `.claude/agents/neovim-implementation-agent.md` - Create

**Verification**:
- Agents follow existing agent-template.md pattern
- Context loading uses @-references for lazy loading
- Both agents define clear input/output contracts

---

### Phase 4: Create Neovim Skills [NOT STARTED]

**Goal**: Build thin wrapper skills for Neovim agents

**Tasks**:
- [ ] Create skill-neovim-research following thin wrapper pattern
  - Validate inputs (task number, optional focus)
  - Delegate to neovim-research-agent via Task tool
  - Handle metadata file return
- [ ] Create skill-neovim-implementation following thin wrapper pattern
  - Validate inputs (task number, plan file)
  - Delegate to neovim-implementation-agent via Task tool
  - Handle metadata file return

**Timing**: 1-2 hours

**Files to modify**:
- `.claude/skills/skill-neovim-research/SKILL.md` - Create
- `.claude/skills/skill-neovim-implementation/SKILL.md` - Create

**Verification**:
- Skills follow existing skill patterns
- Delegation to agents uses correct Task tool invocation
- Metadata file path passed to agents

---

### Phase 5: Create Neovim Rule [NOT STARTED]

**Goal**: Define auto-applied rules for Neovim Lua development

**Tasks**:
- [ ] Create neovim-lua.md rule with path pattern matching nvim/**/*.lua
  - Lua coding standards (indentation, naming, modules)
  - Neovim API patterns (vim.api, vim.fn, vim.opt)
  - Plugin specification requirements
  - Error handling patterns
  - Testing requirements

**Timing**: 1 hour

**Files to modify**:
- `.claude/rules/neovim-lua.md` - Create

**Verification**:
- Rule has correct path pattern for nvim/ directory
- Standards align with existing nvim/CLAUDE.md
- References project/neovim/ context where appropriate

---

### Phase 6: Update Routing and Integration [NOT STARTED]

**Goal**: Connect Neovim components into the orchestration system

**Tasks**:
- [ ] Update skill-orchestrator SKILL.md
  - Add neovim language to routing table
  - Map neovim research to skill-neovim-research
  - Map neovim implementation to skill-neovim-implementation
- [ ] Update CLAUDE.md
  - Add Neovim section to Language-Based Routing table
  - Add Neovim skills to Skill-to-Agent Mapping
  - Add neovim-lua.md to Rules References
  - Update Context Imports with Neovim references
- [ ] Update state.json schema documentation for neovim language

**Timing**: 1-2 hours

**Files to modify**:
- `.claude/skills/skill-orchestrator/SKILL.md` - Add neovim routing
- `.claude/CLAUDE.md` - Add Neovim sections
- `.claude/rules/state-management.md` - Add neovim to language enum if needed

**Verification**:
- Routing table includes neovim language
- CLAUDE.md accurately reflects new components
- Creating a task with language: neovim routes correctly

---

### Phase 7: Documentation and Extension Guide [NOT STARTED]

**Goal**: Document the system and how to extend it for new domains

**Tasks**:
- [ ] Update docs/guides/copy-claude-guide.md for stock Neovim system
  - Document what to copy
  - Document what to customize
  - Document extension points
- [ ] Create docs/guides/adding-domains.md
  - Step-by-step guide for adding new domain contexts
  - Template for domain agents and skills
  - Routing table update process
- [ ] Update project/repo/project-overview.md as template
  - Generalize content for any Neovim configuration
  - Document common customization points
- [ ] Final review and cleanup of all documentation

**Timing**: 2-3 hours

**Files to modify**:
- `.claude/docs/guides/copy-claude-guide.md` - Update
- `.claude/docs/guides/adding-domains.md` - Create
- `.claude/context/project/repo/project-overview.md` - Update as template

**Verification**:
- Documentation is clear and actionable
- Extension guide enables adding new domains without deep knowledge
- All internal links valid

## Testing & Validation

- [ ] Core commands work without Lean components (/task, /research, /plan, /implement, /todo)
- [ ] neovim language routing functions in orchestrator
- [ ] Neovim research agent produces valid research reports
- [ ] Neovim implementation agent modifies nvim/ files correctly
- [ ] state.json and TODO.md synchronization unchanged
- [ ] Git commit workflow unchanged
- [ ] All documentation links valid
- [ ] grep -r "lean\|theorem\|proof" .claude/ returns no false positives

## Artifacts & Outputs

- Cleaned core .claude/ system (Lean-free)
- `.claude/context/project/neovim/` - 17 context files
- `.claude/agents/neovim-research-agent.md`
- `.claude/agents/neovim-implementation-agent.md`
- `.claude/skills/skill-neovim-research/SKILL.md`
- `.claude/skills/skill-neovim-implementation/SKILL.md`
- `.claude/rules/neovim-lua.md`
- Updated skill-orchestrator with neovim routing
- Updated CLAUDE.md with Neovim integration
- `.claude/docs/guides/adding-domains.md`
- Updated copy-claude-guide.md

## Rollback/Contingency

If implementation fails:
1. Restore from git history (git checkout HEAD~N -- .claude/)
2. Verify state.json and TODO.md consistency
3. Document failure point for analysis

For partial success:
- Each phase is independently committable
- System remains functional after each phase
- Can pause after any phase and resume later
