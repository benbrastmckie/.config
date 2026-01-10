# Implementation Plan: Task #10

**Task**: Replace 'context: fork' with explicit context file references in SKILL.md files
**Version**: 001
**Created**: 2026-01-10
**Language**: meta

## Overview

Replace the placeholder `context: fork` in all 8 SKILL.md files with explicit arrays of context file paths from `.claude/context/`. Each skill will reference only the context files relevant to its responsibilities, following the three-tier loading strategy (orchestrator < 5%, commands 10-20%, skills 60-80% context window). Documentation will be updated to reflect the new format.

## Phases

### Phase 1: Update Core Workflow Skills

**Estimated effort**: 30 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update skill-orchestrator with routing/delegation context
2. Update skill-status-sync with state management context
3. Update skill-git-workflow with git standards context

**Files to modify**:
- `.claude/skills/skill-orchestrator/SKILL.md` - Add routing, delegation, state-lookup context
- `.claude/skills/skill-status-sync/SKILL.md` - Add state-management, status-markers context
- `.claude/skills/skill-git-workflow/SKILL.md` - Add git-safety, git-integration context

**Steps**:
1. Edit skill-orchestrator/SKILL.md frontmatter:
   - Replace `context: fork` with:
   ```yaml
   context:
     - core/orchestration/routing.md
     - core/orchestration/delegation.md
     - core/orchestration/state-lookup.md
   ```

2. Edit skill-status-sync/SKILL.md frontmatter:
   - Replace `context: fork` with:
   ```yaml
   context:
     - core/orchestration/state-management.md
     - core/standards/status-markers.md
   ```

3. Edit skill-git-workflow/SKILL.md frontmatter:
   - Replace `context: fork` with:
   ```yaml
   context:
     - core/standards/git-safety.md
     - core/standards/git-integration.md
   ```

**Verification**:
- Each file has valid YAML frontmatter
- Context paths reference existing files in .claude/context/
- No syntax errors in frontmatter

---

### Phase 2: Update General Research and Planning Skills

**Estimated effort**: 30 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update skill-researcher with research-related context
2. Update skill-planner with planning-related context
3. Update skill-implementer with implementation-related context

**Files to modify**:
- `.claude/skills/skill-researcher/SKILL.md` - Add report format, documentation, status transitions
- `.claude/skills/skill-planner/SKILL.md` - Add plan format, task management, status transitions
- `.claude/skills/skill-implementer/SKILL.md` - Add code patterns, summary format, git integration

**Steps**:
1. Edit skill-researcher/SKILL.md frontmatter:
   - Replace `context: fork` with:
   ```yaml
   context:
     - core/formats/report-format.md
     - core/standards/documentation.md
     - core/workflows/status-transitions.md
   ```

2. Edit skill-planner/SKILL.md frontmatter:
   - Replace `context: fork` with:
   ```yaml
   context:
     - core/formats/plan-format.md
     - core/standards/task-management.md
     - core/workflows/status-transitions.md
   ```

3. Edit skill-implementer/SKILL.md frontmatter:
   - Replace `context: fork` with:
   ```yaml
   context:
     - core/standards/code-patterns.md
     - core/formats/summary-format.md
     - core/standards/git-integration.md
   ```

**Verification**:
- Each file has valid YAML frontmatter
- Context paths reference existing files
- Context is minimal and relevant to skill purpose

---

### Phase 3: Update Neovim-Specific Skills

**Estimated effort**: 30 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update skill-neovim-research with Neovim domain context
2. Update skill-neovim-implementation with Neovim standards context

**Files to modify**:
- `.claude/skills/skill-neovim-research/SKILL.md` - Add neovim-api, lua-patterns, plugin-ecosystem
- `.claude/skills/skill-neovim-implementation/SKILL.md` - Add lua-style-guide, testing-standards, plugin-definition

**Steps**:
1. Edit skill-neovim-research/SKILL.md frontmatter:
   - Replace `context: fork` with:
   ```yaml
   context:
     - project/neovim/domain/neovim-api.md
     - project/neovim/domain/lua-patterns.md
     - project/neovim/domain/plugin-ecosystem.md
   ```

2. Edit skill-neovim-implementation/SKILL.md frontmatter:
   - Replace `context: fork` with:
   ```yaml
   context:
     - project/neovim/standards/lua-style-guide.md
     - project/neovim/standards/testing-standards.md
     - project/neovim/patterns/plugin-definition.md
   ```

**Verification**:
- Each file has valid YAML frontmatter
- Context paths reference existing Neovim-specific files
- Context covers domain knowledge needed for each skill

---

### Phase 4: Update Documentation and Templates

**Estimated effort**: 45 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update skill-template.md with new context format
2. Update creating-skills.md guide with examples
3. Update any other documentation referencing `context: fork`

**Files to modify**:
- `.claude/docs/templates/skill-template.md` - Update template and field reference
- `.claude/docs/guides/creating-skills.md` - Update examples
- `.claude/ARCHITECTURE.md` - Update if contains `context: fork` examples

**Steps**:
1. Edit skill-template.md:
   - Update template frontmatter to show array format
   - Update Field Reference table (line 118) to explain array format
   - Add examples showing context selection criteria

2. Edit creating-skills.md:
   - Replace all `context: fork` examples with explicit arrays
   - Add guidance on selecting appropriate context files
   - Reference .claude/context/index.md for context discovery

3. Check and update ARCHITECTURE.md:
   - Search for `context: fork` and replace with updated format
   - Ensure consistency with new pattern

**Verification**:
- All documentation shows new array format
- No remaining `context: fork` references in updated docs
- Examples are consistent across documentation

---

## Dependencies

- All context files referenced must exist in `.claude/context/`
- No external dependencies

## Risks and Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Context file path typos | Low | Medium | Verify each path exists before committing |
| YAML syntax errors | Medium | Low | Validate frontmatter parsing after each edit |
| Missing essential context | Medium | Low | Review each skill's responsibilities against selected context |

## Success Criteria

- [ ] All 8 SKILL.md files have explicit context arrays (no `context: fork`)
- [ ] All referenced context paths exist in `.claude/context/`
- [ ] Documentation templates updated with new format
- [ ] No YAML parsing errors in any SKILL.md file

## Rollback Plan

Git revert to previous commit if:
- Skills fail to load due to context format issues
- YAML parsing errors cause failures
