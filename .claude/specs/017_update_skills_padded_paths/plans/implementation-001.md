# Implementation Plan: Task #17

**Task**: Update skills to use padded directory paths
**Version**: 001
**Created**: 2026-02-02
**Language**: meta

## Overview

Update all skill files that reference task directory paths to use the 3-digit padded format `{NNN}_{SLUG}`.

## Phases

### Phase 1: Update research skills

**Estimated effort**: 20 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update skill-neovim-research path patterns
2. Update skill-researcher path patterns

**Files to modify**:
- `.claude/skills/skill-neovim-research/SKILL.md`
- `.claude/skills/skill-researcher/SKILL.md`

**Steps**:
1. Search for patterns like `specs/{N}_{SLUG}` or `{N}_{SLUG}`
2. Replace directory path patterns with `{NNN}_{SLUG}` format
3. Update example paths in documentation sections
4. Add note about padding for directory names

**Verification**:
- All directory references use padded format
- Example paths show 3-digit padding

---

### Phase 2: Update planning skill

**Estimated effort**: 10 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update skill-planner path patterns

**Files to modify**:
- `.claude/skills/skill-planner/SKILL.md`

**Steps**:
1. Update plan output path patterns to `{NNN}_{SLUG}`
2. Update any research input path references
3. Update example paths

**Verification**:
- Plan paths use padded format

---

### Phase 3: Update implementation skills

**Estimated effort**: 20 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update skill-implementer path patterns
2. Update skill-neovim-implementation path patterns

**Files to modify**:
- `.claude/skills/skill-implementer/SKILL.md`
- `.claude/skills/skill-neovim-implementation/SKILL.md`

**Steps**:
1. Update all directory path references to `{NNN}_{SLUG}`
2. Update plan input path references
3. Update summary output path references
4. Update example paths in documentation

**Verification**:
- All implementation paths use padded format

---

### Phase 4: Update git-workflow skill

**Estimated effort**: 10 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update skill-git-workflow path patterns in commit message examples

**Files to modify**:
- `.claude/skills/skill-git-workflow/SKILL.md`

**Steps**:
1. Update example commit messages that reference paths
2. Ensure commit messages still use unpadded task numbers in text
3. Only pad the directory portion of paths

**Verification**:
- Commit message text uses unpadded numbers (e.g., "task 14:")
- File paths in commits use padded directories

---

## Dependencies

- Task #14 (rules update) - establishes the standard

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Inconsistent updates | Medium | Use grep to find all occurrences |
| Missing skill files | Low | Glob for all SKILL.md files |

## Success Criteria

- [ ] All skill files use `{NNN}_{SLUG}` for directory paths
- [ ] Example paths show 3-digit padding (e.g., `014_task_name`)
- [ ] Text references to task numbers remain unpadded
