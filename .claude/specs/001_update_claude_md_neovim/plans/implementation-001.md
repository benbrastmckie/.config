# Implementation Plan: Update CLAUDE.md for Neovim Configuration Focus

- **Task**: 001 - Update CLAUDE.md for Neovim configuration focus
- **Status**: [COMPLETED]
- **Effort**: 2 hours
- **Priority**: High
- **Dependencies**: None
- **Research Inputs**: nvim/CLAUDE.md (existing standards), .old_claude/ documentation
- **Artifacts**: .claude/CLAUDE.md (updated)
- **Standards**: plan-format.md; status-markers.md; artifact-formats.md
- **Type**: meta
- **Lean Intent**: false

## Overview

The current CLAUDE.md is configured for ModelChecker (Python/Z3 semantic theory development). This task refactors it for Neovim configuration maintenance, specializing in Lua development, plugin management, and editor customization. The existing nvim/CLAUDE.md provides established standards that should be consolidated.

## Goals & Non-Goals

**Goals**:
- Remove all Python/Z3/ModelChecker references
- Add Neovim/Lua specific development workflow
- Integrate standards from nvim/CLAUDE.md
- Update test commands for Lua (busted, plenary.nvim)
- Update language routing to support `lua` language type
- Document Neovim-specific project structure

**Non-Goals**:
- Creating new commands (separate tasks)
- Modifying skill implementations (separate tasks)
- Changing core orchestration patterns (those are generic)

## Risks & Mitigations

- Risk: Breaking existing task management. Mitigation: Only modify domain-specific sections, preserve core workflow documentation.
- Risk: Missing important Neovim standards. Mitigation: Reference nvim/CLAUDE.md and old system for completeness.

## Implementation Phases

### Phase 1: Audit Current Content [COMPLETED]

- **Goal:** Identify all sections requiring modification
- **Tasks:**
  - [ ] Read current CLAUDE.md and catalog all Python/Z3/ModelChecker references
  - [ ] Read nvim/CLAUDE.md and catalog all Neovim/Lua standards
  - [ ] Identify sections that can remain unchanged (core orchestration)
  - [ ] Create checklist of required changes
- **Timing:** 30 minutes

### Phase 2: Update Domain References [COMPLETED]

- **Goal:** Replace ModelChecker domain with Neovim configuration domain
- **Tasks:**
  - [ ] Update system description (ModelChecker -> Neovim configuration)
  - [ ] Update project structure section with nvim/ layout
  - [ ] Replace Python/Z3 testing commands with Lua/busted commands
  - [ ] Update import patterns section with Lua module patterns
  - [ ] Update language routing table (python/lean -> lua/general)
- **Timing:** 45 minutes

### Phase 3: Integrate Neovim Standards [COMPLETED]

- **Goal:** Add Neovim-specific development standards from nvim/CLAUDE.md
- **Tasks:**
  - [ ] Add Lua code style section (2-space indent, ~100 char lines)
  - [ ] Add module structure conventions (neotex.core, neotex.plugins)
  - [ ] Add lazy.nvim plugin definition patterns
  - [ ] Add error handling patterns (pcall for fallible operations)
  - [ ] Add documentation requirements (README.md per directory)
  - [ ] Add testing patterns (busted assertions, plenary.nvim)
- **Timing:** 30 minutes

### Phase 4: Update Context References [COMPLETED]

- **Goal:** Update context file references to point to new Neovim context
- **Tasks:**
  - [ ] Replace context/project/modelchecker/ references
  - [ ] Replace context/project/lean4/ references
  - [ ] Add references to new neovim/ context (created in Task 007)
  - [ ] Update Rules References section
- **Timing:** 15 minutes

## Testing & Validation

- [ ] CLAUDE.md contains no Python/Z3/ModelChecker references
- [ ] CLAUDE.md contains Lua/Neovim development workflow
- [ ] All internal links are valid
- [ ] Task management sections preserved and functional
- [ ] Language routing table includes `lua` type

## Artifacts & Outputs

- .claude/CLAUDE.md (updated)

## Rollback/Contingency

- Git history preserves original CLAUDE.md
- If issues arise, `git checkout HEAD~1 -- .claude/CLAUDE.md`
