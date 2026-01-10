# Implementation Plan: Create Neovim Context Directory

- **Task**: 007 - Create neovim/ context directory with domain knowledge
- **Status**: [NOT STARTED]
- **Effort**: 3 hours
- **Priority**: Medium
- **Dependencies**: None (can be done in parallel with other tasks)
- **Research Inputs**: context/project/lean4/ (structure template), nvim/CLAUDE.md, nvim/docs/, .old_claude/ research artifacts
- **Artifacts**: .claude/context/project/neovim/ directory with subdirectories
- **Standards**: plan-format.md; status-markers.md; documentation.md
- **Type**: meta
- **Lean Intent**: false

## Overview

Context directories provide domain knowledge for skills and commands. This task creates a neovim/ context directory structure parallel to the existing lean4/ structure, containing Neovim-specific domain knowledge, standards, patterns, tools, and processes.

## Goals & Non-Goals

**Goals**:
- Create context/project/neovim/ directory structure
- Create domain/ subdirectory with Neovim/Lua concepts
- Create standards/ subdirectory with coding standards
- Create patterns/ subdirectory with common patterns
- Create tools/ subdirectory with tool documentation
- Create processes/ subdirectory with workflow documentation
- Migrate valuable content from .old_claude/ research

**Non-Goals**:
- Removing lean4/modelchecker/math/physics context (cleanup task)
- Creating exhaustive documentation (can be expanded later)
- Duplicating nvim/CLAUDE.md content (reference it instead)

## Risks & Mitigations

- Risk: Too much content. Mitigation: Focus on essential patterns, reference nvim/ docs for details.
- Risk: Missing key topics. Mitigation: Use lean4/ structure as template, adapt for Neovim.

## Implementation Phases

### Phase 1: Create Directory Structure [COMPLETED]

- **Goal:** Set up neovim/ context directory hierarchy
- **Tasks:**
  - [ ] Create .claude/context/project/neovim/
  - [ ] Create subdirectories:
    - domain/
    - standards/
    - patterns/
    - tools/
    - processes/
    - templates/
  - [ ] Create README.md for neovim/ directory
- **Timing:** 15 minutes

### Phase 2: Create Domain Context Files [NOT STARTED]

- **Goal:** Document Neovim/Lua domain concepts
- **Tasks:**
  - [ ] Create domain/neovim-api.md:
    - vim.api functions
    - vim.fn Vimscript functions
    - vim.opt options
    - vim.keymap mappings
  - [ ] Create domain/lua-patterns.md:
    - Module patterns
    - Metatable usage
    - Iterator patterns
    - Error handling idioms
  - [ ] Create domain/plugin-ecosystem.md:
    - lazy.nvim package manager
    - Key plugin categories
    - Plugin selection criteria
  - [ ] Create domain/lsp-integration.md:
    - nvim-lspconfig
    - mason.nvim
    - Completion engines (blink, nvim-cmp)
- **Timing:** 45 minutes

### Phase 3: Create Standards Context Files [NOT STARTED]

- **Goal:** Document coding and documentation standards
- **Tasks:**
  - [ ] Create standards/lua-style-guide.md:
    - Indentation (2 spaces)
    - Line length (~100)
    - Naming conventions
    - Module structure
  - [ ] Create standards/documentation-requirements.md:
    - README per directory
    - Function documentation
    - No emojis rule
    - Box-drawing characters
  - [ ] Create standards/testing-standards.md:
    - busted framework
    - plenary.nvim
    - Assertion patterns
    - Test organization
- **Timing:** 30 minutes

### Phase 4: Create Patterns Context Files [NOT STARTED]

- **Goal:** Document common Neovim configuration patterns
- **Tasks:**
  - [ ] Create patterns/plugin-definition.md:
    - lazy.nvim spec format
    - Lazy loading strategies
    - Dependency declaration
    - Configuration patterns
  - [ ] Create patterns/keymapping.md:
    - vim.keymap.set usage
    - Which-key integration
    - Leader key patterns
    - Mode-specific maps
  - [ ] Create patterns/autocommand.md:
    - vim.api.nvim_create_autocmd
    - Autocommand groups
    - Common events
    - Buffer-local autocmds
- **Timing:** 30 minutes

### Phase 5: Create Tools Context Files [NOT STARTED]

- **Goal:** Document tool integrations
- **Tasks:**
  - [ ] Create tools/lazy-nvim.md:
    - Installation
    - Plugin spec format
    - Lazy loading
    - Lock files
  - [ ] Create tools/telescope.md:
    - Picker creation
    - Extension development
    - Finder/previewer/sorter
  - [ ] Create tools/treesitter.md:
    - Parser installation
    - Query patterns
    - Highlighting
    - Text objects
- **Timing:** 30 minutes

### Phase 6: Create Processes Context Files [NOT STARTED]

- **Goal:** Document development workflows
- **Tasks:**
  - [ ] Create processes/plugin-development.md:
    - Plugin structure
    - Testing workflow
    - Documentation
    - Publishing
  - [ ] Create processes/debugging.md:
    - :messages
    - print debugging
    - DAP integration
    - Startup profiling
  - [ ] Create processes/maintenance.md:
    - Plugin updates
    - Breaking changes
    - Performance monitoring
- **Timing:** 30 minutes

## Testing & Validation

- [ ] neovim/ directory exists with all subdirectories
- [ ] README.md exists and documents structure
- [ ] All planned context files created
- [ ] Content is accurate and useful
- [ ] No references to Python/Z3/Lean

## Artifacts & Outputs

- .claude/context/project/neovim/README.md
- .claude/context/project/neovim/domain/*.md (4 files)
- .claude/context/project/neovim/standards/*.md (3 files)
- .claude/context/project/neovim/patterns/*.md (3 files)
- .claude/context/project/neovim/tools/*.md (3 files)
- .claude/context/project/neovim/processes/*.md (3 files)

## Rollback/Contingency

- Delete directory if issues arise
- No other components depend on this until referenced
