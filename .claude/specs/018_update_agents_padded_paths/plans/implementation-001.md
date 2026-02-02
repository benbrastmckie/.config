# Implementation Plan: Task #18

**Task**: Update agents to use padded directory paths
**Version**: 001
**Created**: 2026-02-02
**Language**: meta

## Overview

Update all agent files that reference task directory paths to use the 3-digit padded format `{NNN}_{SLUG}`.

## Phases

### Phase 1: Update research agents

**Estimated effort**: 20 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update general-research-agent path patterns
2. Update neovim-research-agent path patterns

**Files to modify**:
- `.claude/agents/general-research-agent.md`
- `.claude/agents/neovim-research-agent.md`

**Steps**:
1. Search for patterns like `specs/{N}_{SLUG}` or directory references
2. Replace with `specs/{NNN}_{SLUG}` format
3. Update mkdir commands to include padding logic:
   ```bash
   PADDED_NUM=$(printf "%03d" "$N")
   mkdir -p "specs/${PADDED_NUM}_{SLUG}"
   ```
4. Update .return-meta.json path examples

**Verification**:
- All directory creation uses padded format
- Example paths show 3-digit padding

---

### Phase 2: Update implementation agents

**Estimated effort**: 25 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update general-implementation-agent path patterns
2. Update neovim-implementation-agent path patterns
3. Update latex-implementation-agent path patterns
4. Update typst-implementation-agent path patterns

**Files to modify**:
- `.claude/agents/general-implementation-agent.md`
- `.claude/agents/neovim-implementation-agent.md`
- `.claude/agents/latex-implementation-agent.md`
- `.claude/agents/typst-implementation-agent.md`

**Steps**:
1. Update all directory path references to `{NNN}_{SLUG}`
2. Update mkdir commands with padding logic
3. Update summary output paths
4. Update .return-meta.json path examples

**Verification**:
- All implementation agents use padded directory paths

---

### Phase 3: Update planner agent

**Estimated effort**: 10 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update planner-agent path patterns

**Files to modify**:
- `.claude/agents/planner-agent.md`

**Steps**:
1. Update plan output directory paths to `{NNN}_{SLUG}`
2. Update research input path references (with both-format checking)
3. Update example paths

**Verification**:
- Planner creates plans in padded directories

---

### Phase 4: Update meta-builder agent

**Estimated effort**: 10 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update meta-builder-agent path patterns

**Files to modify**:
- `.claude/agents/meta-builder-agent.md`

**Steps**:
1. Update task directory creation to use padding
2. Update plan path references
3. Update example paths

**Verification**:
- Meta-builder creates padded directories

---

## Dependencies

- Task #14 (rules update) - establishes the standard

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Missing agent files | Low | Glob for all agent .md files |
| Inconsistent bash patterns | Medium | Standard printf pattern everywhere |

## Success Criteria

- [ ] All agent files use `{NNN}_{SLUG}` for directory paths
- [ ] mkdir commands include printf padding
- [ ] Example paths show 3-digit padding
- [ ] .return-meta.json paths use padded format
