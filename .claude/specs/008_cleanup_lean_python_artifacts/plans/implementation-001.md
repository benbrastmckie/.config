# Implementation Plan: Cleanup Lean/Python/Z3 Artifacts

- **Task**: 008 - Remove Lean4, ModelChecker, Python/Z3 specific artifacts
- **Status**: [NOT STARTED]
- **Effort**: 1 hour
- **Priority**: Low
- **Dependencies**: 001-007 (all other tasks should complete first)
- **Research Inputs**: None
- **Artifacts**: Multiple directories and files removed
- **Standards**: plan-format.md; status-markers.md
- **Type**: meta
- **Lean Intent**: false

## Overview

Final cleanup task to remove all Lean4, ModelChecker, Python/Z3, and other domain-specific artifacts that are no longer relevant to the Neovim configuration repository. This should be done last to ensure no accidental removal of content that might be useful during other task implementations.

## Goals & Non-Goals

**Goals**:
- Remove skill-python-research directory
- Remove skill-theory-implementation directory
- Remove context/project/lean4/ directory
- Remove context/project/modelchecker/ directory
- Remove context/project/math/ directory
- Remove context/project/physics/ directory
- Remove context/project/logic/ directory (or assess if generally useful)
- Clean up any remaining Python/Z3 references

**Non-Goals**:
- Removing core infrastructure (orchestration, formats, standards)
- Removing generic skills (researcher, implementer, planner)
- Removing generic rules (state-management, workflows, etc.)

## Risks & Mitigations

- Risk: Accidentally removing useful content. Mitigation: Run last, git preserves everything.
- Risk: Breaking references. Mitigation: Search for references before removal.

## Implementation Phases

### Phase 1: Audit Dependencies [NOT STARTED]

- **Goal:** Ensure nothing references artifacts to be removed
- **Tasks:**
  - [ ] Search for references to skill-python-research
  - [ ] Search for references to skill-theory-implementation
  - [ ] Search for references to context/project/lean4/
  - [ ] Search for references to context/project/modelchecker/
  - [ ] Search for references to context/project/math/
  - [ ] Search for references to context/project/physics/
  - [ ] Document any remaining references
- **Timing:** 15 minutes

### Phase 2: Remove Python/Z3 Skills [NOT STARTED]

- **Goal:** Remove obsolete Python-specific skills
- **Tasks:**
  - [ ] Remove .claude/skills/skill-python-research/ directory
  - [ ] Remove .claude/skills/skill-theory-implementation/ directory
  - [ ] Verify orchestrator no longer references them
- **Timing:** 10 minutes

### Phase 3: Remove Domain Context Directories [NOT STARTED]

- **Goal:** Remove Lean/ModelChecker/Math/Physics context
- **Tasks:**
  - [ ] Remove .claude/context/project/lean4/ directory
  - [ ] Remove .claude/context/project/modelchecker/ directory
  - [ ] Remove .claude/context/project/math/ directory
  - [ ] Remove .claude/context/project/physics/ directory
  - [ ] Assess context/project/logic/ - may have some general utility for formal reasoning; remove if not applicable
  - [ ] Update context/project/README.md if it exists
- **Timing:** 15 minutes

### Phase 4: Update Context Index [NOT STARTED]

- **Goal:** Update context index to reflect changes
- **Tasks:**
  - [ ] Update .claude/context/index.md to remove references to deleted directories
  - [ ] Update .claude/context/README.md to reflect new structure
  - [ ] Ensure neovim/ context is properly indexed
- **Timing:** 10 minutes

### Phase 5: Final Verification [NOT STARTED]

- **Goal:** Ensure no broken references remain
- **Tasks:**
  - [ ] Search codebase for "lean4", "modelchecker", "python-research", "theory-implementation"
  - [ ] Fix or document any remaining references
  - [ ] Verify directory structure is clean
- **Timing:** 10 minutes

## Testing & Validation

- [ ] No skill-python-research directory exists
- [ ] No skill-theory-implementation directory exists
- [ ] No context/project/lean4/ directory exists
- [ ] No context/project/modelchecker/ directory exists
- [ ] No context/project/math/ directory exists
- [ ] No context/project/physics/ directory exists
- [ ] No broken references in remaining files
- [ ] Context index is updated

## Artifacts & Outputs

Files/directories removed:
- .claude/skills/skill-python-research/
- .claude/skills/skill-theory-implementation/
- .claude/context/project/lean4/
- .claude/context/project/modelchecker/
- .claude/context/project/math/
- .claude/context/project/physics/
- .claude/context/project/logic/ (conditional)

Files updated:
- .claude/context/index.md
- .claude/context/README.md

## Rollback/Contingency

- All removed content preserved in git history
- `git checkout HEAD~1 -- <path>` to restore any file/directory
