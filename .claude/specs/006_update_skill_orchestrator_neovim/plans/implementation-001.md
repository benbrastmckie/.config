# Implementation Plan: Update skill-orchestrator for Neovim Routing

- **Task**: 006 - Update skill-orchestrator for Neovim/Lua language routing
- **Status**: [NOT STARTED]
- **Effort**: 1 hour
- **Priority**: High
- **Dependencies**: 004, 005 (Neovim skills must exist before routing to them)
- **Research Inputs**: skill-orchestrator/SKILL.md (current), skill-neovim-research, skill-neovim-implementation
- **Artifacts**: .claude/skills/skill-orchestrator/SKILL.md (updated)
- **Standards**: plan-format.md; status-markers.md; routing.md
- **Type**: meta
- **Lean Intent**: false

## Overview

The orchestrator skill handles language-based routing. Currently routes python tasks to Python/Z3 skills. This task updates routing to support lua language and route to the new Neovim skills.

## Goals & Non-Goals

**Goals**:
- Add lua language routing:
  - lua -> skill-neovim-research (research)
  - lua -> skill-neovim-implementation (implementation)
- Update language detection keywords:
  - lua, neovim, nvim, plugin, lazy -> lua
- Remove python/lean language detection
- Preserve general/meta routing (unchanged)

**Non-Goals**:
- Changing orchestration architecture
- Modifying delegation patterns
- Creating new commands

## Risks & Mitigations

- Risk: Breaking existing routing. Mitigation: Only modify language-specific sections, preserve core logic.
- Risk: Skills not existing when routing. Mitigation: Dependency on tasks 004, 005 ensures skills exist.

## Implementation Phases

### Phase 1: Audit Current Orchestrator [COMPLETED]

- **Goal:** Understand current routing configuration
- **Tasks:**
  - [ ] Read skill-orchestrator/SKILL.md
  - [ ] Identify language routing table
  - [ ] Identify language detection logic
  - [ ] Note sections that remain unchanged
- **Timing:** 15 minutes

### Phase 2: Update Language Routing Table [COMPLETED]

- **Goal:** Replace Python/Lean routing with Lua routing
- **Tasks:**
  - [ ] Update routing table to:
    | Language | Research Skill | Implementation Skill |
    |----------|---------------|---------------------|
    | lua | skill-neovim-research | skill-neovim-implementation |
    | general | skill-researcher | skill-implementer |
    | meta | skill-researcher | skill-implementer |
  - [ ] Remove python/lean rows
- **Timing:** 15 minutes

### Phase 3: Update Language Detection [COMPLETED]

- **Goal:** Update keyword-based language detection
- **Tasks:**
  - [ ] Update detection keywords:
    | Keywords | Language |
    |----------|----------|
    | lua, neovim, nvim, plugin, lazy, config | lua |
    | agent, command, skill, meta | meta |
    | (default) | general |
  - [ ] Remove python, Z3, pytest, theory, semantic, lean, mathlib keywords
- **Timing:** 15 minutes

### Phase 4: Validate Routing [COMPLETED]

- **Goal:** Ensure routing configuration is correct
- **Tasks:**
  - [ ] Verify all referenced skills exist or will exist
  - [ ] Verify routing table is complete
  - [ ] Verify detection keywords are comprehensive
  - [ ] Test routing logic mentally with sample tasks
- **Timing:** 15 minutes

## Testing & Validation

- [ ] skill-orchestrator routes lua tasks to skill-neovim-research
- [ ] skill-orchestrator routes lua tasks to skill-neovim-implementation
- [ ] No references to python/lean routing remain
- [ ] general/meta routing preserved
- [ ] Language detection keywords updated

## Artifacts & Outputs

- .claude/skills/skill-orchestrator/SKILL.md (updated)

## Rollback/Contingency

- Git preserves original orchestrator
- `git checkout HEAD~1 -- .claude/skills/skill-orchestrator/SKILL.md`
