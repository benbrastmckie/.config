# Implementation Plan: Create skill-neovim-research

- **Task**: 004 - Create skill-neovim-research for Neovim/Lua API research
- **Status**: [IN PROGRESS]
- **Effort**: 2 hours
- **Priority**: Medium
- **Dependencies**: 003 (neovim-lua.md rule should exist for standards reference)
- **Research Inputs**: skill-python-research/SKILL.md (template), skill-researcher/SKILL.md
- **Artifacts**: .claude/skills/skill-neovim-research/SKILL.md (new)
- **Standards**: plan-format.md; status-markers.md; subagent-return.md
- **Type**: meta
- **Lean Intent**: false

## Overview

Skills are specialized agents for domain-specific tasks. This task creates skill-neovim-research to replace skill-python-research, providing Neovim-specific research capabilities including Neovim API documentation, plugin ecosystem research, Lua patterns, and lazy.nvim configuration.

## Goals & Non-Goals

**Goals**:
- Create skill-neovim-research with appropriate tools (WebSearch, WebFetch, Read, Grep, Glob)
- Document research targets: Neovim API, plugin docs, Lua patterns
- Include key resources: neovim.io docs, lazy.nvim wiki, luarocks
- Integrate with neovim-lua.md rule standards
- Follow standardized return format

**Non-Goals**:
- Removing skill-python-research (separate cleanup task)
- Modifying orchestrator routing (separate task)
- Creating context files (separate task)

## Risks & Mitigations

- Risk: Missing key research sources. Mitigation: Comprehensive resource list from Neovim ecosystem.
- Risk: Incorrect skill structure. Mitigation: Use skill-python-research as structural template.

## Implementation Phases

### Phase 1: Analyze Existing Research Skill [COMPLETED]

- **Goal:** Understand skill structure and required components
- **Tasks:**
  - [ ] Read skill-python-research/SKILL.md for structure
  - [ ] Read skill-researcher/SKILL.md for generic patterns
  - [ ] Note frontmatter requirements
  - [ ] Note return format requirements
- **Timing:** 20 minutes

### Phase 2: Create skill-neovim-research Directory [COMPLETED]

- **Goal:** Set up skill directory structure
- **Tasks:**
  - [ ] Create .claude/skills/skill-neovim-research/ directory
  - [ ] Prepare SKILL.md file structure
- **Timing:** 5 minutes

### Phase 3: Write SKILL.md [COMPLETED]

- **Goal:** Create comprehensive Neovim research skill
- **Tasks:**
  - [ ] Write frontmatter:
    ```yaml
    ---
    name: skill-neovim-research
    description: "Research Neovim APIs, plugin patterns, and Lua development"
    allowed-tools: WebSearch, WebFetch, Read, Grep, Glob
    context: fork
    ---
    ```
  - [ ] Write skill description section
  - [ ] Write research targets section:
    - Neovim API (vim.api, vim.fn, vim.opt)
    - Plugin APIs (lazy.nvim, telescope, treesitter)
    - Lua patterns and idioms
    - LSP configuration
    - Keymapping patterns
  - [ ] Write key resources section:
    - https://neovim.io/doc/user/lua.html
    - https://lazy.folke.io/
    - https://github.com/nvim-telescope/telescope.nvim
    - https://github.com/nvim-treesitter/nvim-treesitter
    - https://luals.github.io/ (Lua language server)
  - [ ] Write workflow section:
    1. Parse research request
    2. Search Neovim documentation
    3. Search plugin repositories
    4. Search codebase for existing patterns
    5. Synthesize findings
    6. Create research report
  - [ ] Write return format section (standard JSON structure)
- **Timing:** 60 minutes

### Phase 4: Validate Skill [IN PROGRESS]

- **Goal:** Ensure skill is correctly formatted
- **Tasks:**
  - [ ] Verify frontmatter is valid YAML
  - [ ] Verify all sections are present
  - [ ] Verify tool list is appropriate
  - [ ] Check internal consistency
- **Timing:** 15 minutes

## Testing & Validation

- [ ] skill-neovim-research/SKILL.md exists
- [ ] Frontmatter is valid
- [ ] Description accurately describes capability
- [ ] Tools are appropriate for research tasks
- [ ] Return format matches standard

## Artifacts & Outputs

- .claude/skills/skill-neovim-research/SKILL.md (created)

## Rollback/Contingency

- Simply delete directory if issues arise
- No dependencies on this skill until orchestrator is updated
