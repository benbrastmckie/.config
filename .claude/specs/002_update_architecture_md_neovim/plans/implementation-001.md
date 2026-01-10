# Implementation Plan: Update ARCHITECTURE.md for Neovim Configuration System

- **Task**: 002 - Update ARCHITECTURE.md for Neovim configuration system
- **Status**: [NOT STARTED]
- **Effort**: 2 hours
- **Priority**: High
- **Dependencies**: 001 (CLAUDE.md should be updated first for consistency)
- **Research Inputs**: nvim/docs/ARCHITECTURE.md, nvim/CLAUDE.md
- **Artifacts**: .claude/ARCHITECTURE.md (updated)
- **Standards**: plan-format.md; status-markers.md; artifact-formats.md
- **Type**: meta
- **Lean Intent**: false

## Overview

ARCHITECTURE.md documents the agent system's structure and capabilities. Currently describes Python/Z3 semantic theory development. This task updates it to describe Neovim configuration maintenance with Lua-focused skills and context.

## Goals & Non-Goals

**Goals**:
- Update overview to describe Neovim configuration system
- Replace Python/Z3 skill descriptions with Neovim/Lua equivalents
- Update directory structure to reflect Neovim context
- Update language-based routing for lua/general
- Update testing commands section for Lua
- Remove Z3 Best Practices section

**Non-Goals**:
- Changing core orchestration architecture (remains the same)
- Modifying command list (same commands, different domain)
- Creating actual skills (separate tasks)

## Risks & Mitigations

- Risk: Architecture changes affecting core workflow. Mitigation: Core patterns remain unchanged; only domain-specific sections modified.
- Risk: Documentation becoming inconsistent with skills. Mitigation: Coordinate with skill creation tasks (003-006).

## Implementation Phases

### Phase 1: Audit Current Architecture Documentation [NOT STARTED]

- **Goal:** Identify all sections requiring domain-specific updates
- **Tasks:**
  - [ ] Read ARCHITECTURE.md and catalog Python/Z3/ModelChecker references
  - [ ] Identify skill descriptions that need replacement
  - [ ] Identify context directory references that need updating
  - [ ] Note which sections describe core patterns (no changes needed)
- **Timing:** 20 minutes

### Phase 2: Update Overview and Directory Structure [NOT STARTED]

- **Goal:** Replace ModelChecker overview with Neovim configuration overview
- **Tasks:**
  - [ ] Update overview section description
  - [ ] Update key capabilities list for Neovim focus
  - [ ] Update directory structure diagram to show neovim/ context
  - [ ] Update context file counts
- **Timing:** 30 minutes

### Phase 3: Update Skill Documentation [NOT STARTED]

- **Goal:** Replace Python/Z3 skill references with Neovim/Lua skills
- **Tasks:**
  - [ ] Update skill table to show new skills:
    - skill-neovim-research (replaces skill-python-research)
    - skill-neovim-implementation (replaces skill-theory-implementation)
  - [ ] Update skill-python-research section -> skill-neovim-research
  - [ ] Update skill-theory-implementation section -> skill-neovim-implementation
  - [ ] Update skill descriptions with Neovim-specific workflows
- **Timing:** 30 minutes

### Phase 4: Update Language Routing Section [NOT STARTED]

- **Goal:** Document lua language routing
- **Tasks:**
  - [ ] Update language routing table:
    - lua -> skill-neovim-research, skill-neovim-implementation
    - general -> skill-researcher, skill-implementer
    - meta -> skill-researcher, skill-implementer
  - [ ] Update language detection keywords:
    - lua, neovim, nvim, plugin, lazy.nvim -> lua
  - [ ] Remove python/lean detection keywords
- **Timing:** 20 minutes

### Phase 5: Update Testing and Integration Sections [NOT STARTED]

- **Goal:** Replace Python/Z3 testing with Neovim/Lua testing
- **Tasks:**
  - [ ] Replace Python/Z3 testing commands section with Lua testing:
    ```bash
    # Run all tests
    cd nvim && nvim --headless -c "PlenaryBustedDirectory tests/"

    # Run specific test file
    nvim --headless -c "PlenaryBustedFile tests/picker/scan_recursive_spec.lua"
    ```
  - [ ] Remove "Theory Development Pattern" section
  - [ ] Remove "Z3 Best Practices" section
  - [ ] Add "Plugin Development Pattern" section with lazy.nvim patterns
  - [ ] Add "Lua Best Practices" section
- **Timing:** 20 minutes

## Testing & Validation

- [ ] ARCHITECTURE.md contains no Python/Z3/ModelChecker references
- [ ] All skill references point to valid skills (or planned skills)
- [ ] Language routing table includes lua type
- [ ] Testing commands are valid Neovim/Lua commands
- [ ] Internal links are valid

## Artifacts & Outputs

- .claude/ARCHITECTURE.md (updated)

## Rollback/Contingency

- Git history preserves original
- `git checkout HEAD~1 -- .claude/ARCHITECTURE.md` if needed
