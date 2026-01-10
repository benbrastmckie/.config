# Implementation Plan: Create skill-neovim-implementation

- **Task**: 005 - Create skill-neovim-implementation for Neovim plugin and config development
- **Status**: [NOT STARTED]
- **Effort**: 2 hours
- **Priority**: Medium
- **Dependencies**: 003 (neovim-lua.md rule), 004 (skill-neovim-research)
- **Research Inputs**: skill-theory-implementation/SKILL.md (template), skill-implementer/SKILL.md
- **Artifacts**: .claude/skills/skill-neovim-implementation/SKILL.md (new)
- **Standards**: plan-format.md; status-markers.md; subagent-return.md
- **Type**: meta
- **Lean Intent**: false

## Overview

This task creates skill-neovim-implementation to replace skill-theory-implementation. The new skill provides Neovim-specific implementation capabilities including plugin configuration, Lua module development, and test-driven development with busted/plenary.nvim.

## Goals & Non-Goals

**Goals**:
- Create skill-neovim-implementation with implementation tools (Read, Write, Edit, Bash)
- Document TDD workflow with busted framework
- Include lazy.nvim plugin definition patterns
- Include Lua module structure patterns
- Follow standardized return format

**Non-Goals**:
- Removing skill-theory-implementation (cleanup task)
- Modifying orchestrator routing (separate task)
- Creating actual plugin implementations

## Risks & Mitigations

- Risk: Missing key implementation patterns. Mitigation: Reference nvim/CLAUDE.md and CODE_STANDARDS.md.
- Risk: Test commands incorrect. Mitigation: Use verified patterns from existing test files.

## Implementation Phases

### Phase 1: Analyze Existing Implementation Skill [COMPLETED]

- **Goal:** Understand skill structure and TDD patterns
- **Tasks:**
  - [ ] Read skill-theory-implementation/SKILL.md
  - [ ] Read skill-implementer/SKILL.md
  - [ ] Note TDD workflow structure
  - [ ] Note tool requirements
- **Timing:** 20 minutes

### Phase 2: Create skill-neovim-implementation Directory [COMPLETED]

- **Goal:** Set up skill directory structure
- **Tasks:**
  - [ ] Create .claude/skills/skill-neovim-implementation/ directory
  - [ ] Prepare SKILL.md file structure
- **Timing:** 5 minutes

### Phase 3: Write SKILL.md [COMPLETED]

- **Goal:** Create comprehensive Neovim implementation skill
- **Tasks:**
  - [ ] Write frontmatter:
    ```yaml
    ---
    name: skill-neovim-implementation
    description: "Implement Neovim plugins and configurations with TDD"
    allowed-tools: Read, Write, Edit, Bash(nvim:*, cd)
    context: fork
    ---
    ```
  - [ ] Write skill description section
  - [ ] Write TDD workflow section:
    1. Load implementation plan
    2. Write failing test first (busted)
    3. Implement minimal code to pass
    4. Refactor while tests pass
    5. Verify with full test suite
  - [ ] Write testing commands section:
    ```bash
    # Run all tests
    nvim --headless -c "PlenaryBustedDirectory tests/"

    # Run specific test
    nvim --headless -c "PlenaryBustedFile tests/path/to/spec.lua"

    # With verbose output
    nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"
    ```
  - [ ] Write module structure section:
    - Core utilities: lua/neotex/core/
    - Plugin configs: lua/neotex/plugins/{category}/
    - Utilities: lua/neotex/util/
    - After configs: after/ftplugin/
  - [ ] Write plugin definition pattern section:
    ```lua
    return {
      "author/plugin-name",
      event = "VeryLazy",  -- or specific events
      dependencies = { "dep/plugin" },
      opts = {
        -- configuration
      },
      config = function(_, opts)
        require("plugin").setup(opts)
      end,
    }
    ```
  - [ ] Write error handling section:
    - Use pcall for plugin loading
    - Graceful fallbacks on missing dependencies
    - Clear error messages via vim.notify
  - [ ] Write return format section (standard JSON)
- **Timing:** 60 minutes

### Phase 4: Validate Skill [COMPLETED]

- **Goal:** Ensure skill is correctly formatted
- **Tasks:**
  - [ ] Verify frontmatter is valid YAML
  - [ ] Verify all sections are present
  - [ ] Verify test commands are correct
  - [ ] Check internal consistency
- **Timing:** 15 minutes

## Testing & Validation

- [ ] skill-neovim-implementation/SKILL.md exists
- [ ] Frontmatter is valid
- [ ] TDD workflow is documented
- [ ] Test commands are valid
- [ ] Return format matches standard

## Artifacts & Outputs

- .claude/skills/skill-neovim-implementation/SKILL.md (created)

## Rollback/Contingency

- Delete directory if issues arise
- No dependencies until orchestrator updated
