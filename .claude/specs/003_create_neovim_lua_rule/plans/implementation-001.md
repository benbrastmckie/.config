# Implementation Plan: Create neovim-lua.md Rule

- **Task**: 003 - Create neovim-lua.md rule for Neovim/Lua development patterns
- **Status**: [COMPLETED]
- **Effort**: 1.5 hours
- **Priority**: Medium
- **Dependencies**: None
- **Research Inputs**: nvim/CLAUDE.md, nvim/docs/CODE_STANDARDS.md, python-z3.md (template)
- **Artifacts**: .claude/rules/neovim-lua.md (new), .claude/rules/python-z3.md (deleted)
- **Standards**: plan-format.md; status-markers.md; artifact-formats.md
- **Type**: meta
- **Lean Intent**: false

## Overview

Rules are path-scoped automatic behaviors. The current python-z3.md rule provides Python/Z3 development patterns. This task creates a replacement neovim-lua.md rule with Neovim/Lua development patterns and removes the Python-specific rule.

## Goals & Non-Goals

**Goals**:
- Create neovim-lua.md with path scope `**/*.lua`
- Document Lua code style (2-space indent, ~100 chars)
- Document module structure (neotex.core, neotex.plugins)
- Document lazy.nvim plugin definition patterns
- Document testing patterns (busted, plenary.nvim)
- Document error handling (pcall usage)
- Remove python-z3.md rule

**Non-Goals**:
- Modifying other rules (they are generic)
- Creating context files (separate task)
- Implementing skill changes

## Risks & Mitigations

- Risk: Missing important Neovim patterns. Mitigation: Reference nvim/CLAUDE.md and CODE_STANDARDS.md comprehensively.
- Risk: Rule scope too broad/narrow. Mitigation: Use `**/*.lua` for all Lua files in repo.

## Implementation Phases

### Phase 1: Analyze Existing Standards [COMPLETED]

- **Goal:** Gather all Neovim/Lua standards from existing documentation
- **Tasks:**
  - [ ] Read nvim/CLAUDE.md Lua Code Style section
  - [ ] Read nvim/docs/CODE_STANDARDS.md for comprehensive patterns
  - [ ] Read python-z3.md for rule structure template
  - [ ] Compile list of all patterns to document
- **Timing:** 20 minutes

### Phase 2: Create neovim-lua.md Rule [COMPLETED]

- **Goal:** Create comprehensive Neovim/Lua development rule
- **Tasks:**
  - [ ] Create .claude/rules/neovim-lua.md with frontmatter:
    ```yaml
    ---
    paths: ["**/*.lua"]
    ---
    ```
  - [ ] Add Lua Code Style section:
    - 2-space indentation with expandtab
    - ~100 character line length
    - Descriptive lowercase names with underscores
    - Module return pattern
  - [ ] Add Module Structure section:
    - neotex.core namespace for utilities
    - neotex.plugins namespace for plugin configs
    - after/ftplugin for filetype-specific settings
  - [ ] Add Plugin Definition Pattern section:
    - lazy.nvim table format
    - event/keys/cmd lazy loading
    - opts table for configuration
    - config function patterns
  - [ ] Add Testing section:
    - busted framework usage
    - plenary.nvim test utilities
    - Assertion patterns (is_not_nil for match results)
    - Test file naming (*_spec.lua)
  - [ ] Add Error Handling section:
    - pcall for fallible operations
    - Graceful degradation patterns
    - Error message formatting
  - [ ] Add Documentation Requirements section:
    - README.md per directory
    - Function documentation patterns
    - No emojis in file content
- **Timing:** 45 minutes

### Phase 3: Remove Python Rule [COMPLETED]

- **Goal:** Remove obsolete python-z3.md rule
- **Tasks:**
  - [ ] Delete .claude/rules/python-z3.md
  - [ ] Verify no other files reference it
- **Timing:** 5 minutes

### Phase 4: Validate Rule [COMPLETED]

- **Goal:** Ensure rule is correctly formatted and scoped
- **Tasks:**
  - [ ] Verify YAML frontmatter is valid
  - [ ] Verify paths pattern matches intended files
  - [ ] Test that rule content is comprehensive
- **Timing:** 10 minutes

## Testing & Validation

- [ ] neovim-lua.md exists at .claude/rules/neovim-lua.md
- [ ] neovim-lua.md has valid paths frontmatter
- [ ] python-z3.md is removed
- [ ] Rule covers all key Neovim/Lua patterns
- [ ] No broken references to removed python-z3.md

## Artifacts & Outputs

- .claude/rules/neovim-lua.md (created)
- .claude/rules/python-z3.md (deleted)

## Rollback/Contingency

- Git preserves deleted python-z3.md
- `git checkout HEAD~1 -- .claude/rules/python-z3.md` to restore
