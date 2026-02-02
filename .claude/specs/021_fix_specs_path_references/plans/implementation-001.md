# Implementation Plan: Task #21

**Task**: Update all .claude/ files to use specs/ instead of .claude/specs/
**Version**: 001
**Created**: 2026-02-02
**Language**: meta

## Overview

Update all path references in the nvim/.claude/ agent system from `.claude/specs/` to `specs/` (project root). This ensures the specs directory is portable and follows the parent system's correct design.

## Rationale

The parent .claude/ system at ~/.config/.claude/ correctly uses `specs/` relative to project root. When copied to nvim/.claude/, paths were incorrectly changed to `.claude/specs/`, nesting specs inside the agent configuration directory.

**Correct structure**:
```
{PROJECT_ROOT}/
├── specs/           # Task artifacts at root
├── .claude/         # Agent system (no specs inside!)
└── {project files}
```

## Phases

### Phase 1: Update CLAUDE.md and core configuration

**Estimated effort**: 15 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update CLAUDE.md Quick Reference paths
2. Update Project Structure diagram
3. Update Artifact Paths section

**Files to modify**:
- `.claude/CLAUDE.md`

**Steps**:
1. Change `@.claude/specs/TODO.md` to `@specs/TODO.md`
2. Change `@.claude/specs/state.json` to `@specs/state.json`
3. Change `@.claude/specs/errors.json` to `@specs/errors.json`
4. Update Project Structure to show `specs/` at root level (sibling to .claude/)
5. Update Task Artifact Paths from `.claude/specs/{NUMBER}_{SLUG}/` to `specs/{NUMBER}_{SLUG}/`

**Verification**:
- All `@.claude/specs/` references replaced
- Project structure diagram shows correct layout

---

### Phase 2: Update rules files

**Estimated effort**: 15 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update artifact-formats.md path patterns
2. Update state-management.md path patterns
3. Update git-workflow.md example paths

**Files to modify**:
- `.claude/rules/artifact-formats.md`
- `.claude/rules/state-management.md`
- `.claude/rules/git-workflow.md`

**Steps**:
1. Global find/replace `.claude/specs/` with `specs/` in each file
2. Update any directory structure diagrams
3. Verify examples show correct paths

**Verification**:
- `grep -r "\.claude/specs/" .claude/rules/` returns nothing

---

### Phase 3: Update command files

**Estimated effort**: 30 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update allowed-tools paths in frontmatter
2. Update all path references in command bodies

**Files to modify**:
- `.claude/commands/task.md`
- `.claude/commands/research.md`
- `.claude/commands/plan.md`
- `.claude/commands/implement.md`
- `.claude/commands/revise.md`
- `.claude/commands/todo.md`
- `.claude/commands/errors.md`
- `.claude/commands/meta.md`
- `.claude/commands/review.md`

**Steps**:
1. For each command file:
   - Update `allowed-tools:` paths (e.g., `Read(.claude/specs/*)` to `Read(specs/*)`)
   - Replace all `.claude/specs/` with `specs/` in body
2. Special attention to jq commands and bash scripts

**Verification**:
- `grep -r "\.claude/specs/" .claude/commands/` returns nothing
- Commands still reference correct paths

---

### Phase 4: Update skill files

**Estimated effort**: 20 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update all skill path references

**Files to modify**:
- `.claude/skills/skill-orchestrator/SKILL.md`
- `.claude/skills/skill-status-sync/SKILL.md`
- `.claude/skills/skill-git-workflow/SKILL.md`
- `.claude/skills/skill-neovim-research/SKILL.md`
- `.claude/skills/skill-neovim-implementation/SKILL.md`
- `.claude/skills/skill-researcher/SKILL.md`
- `.claude/skills/skill-planner/SKILL.md`
- `.claude/skills/skill-implementer/SKILL.md`

**Steps**:
1. Global find/replace `.claude/specs/` with `specs/` in each file
2. Update any jq command paths
3. Update artifact path patterns

**Verification**:
- `grep -r "\.claude/specs/" .claude/skills/` returns nothing

---

### Phase 5: Update context files

**Estimated effort**: 30 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update all context file path references

**Files to modify**:
- `.claude/context/project/processes/*.md`
- `.claude/context/project/repo/*.md`
- `.claude/context/core/orchestration/*.md`
- `.claude/context/core/workflows/*.md`
- `.claude/context/core/standards/*.md`
- `.claude/context/core/templates/*.md`
- `.claude/context/core/formats/*.md`
- `.claude/context/index.md`

**Steps**:
1. Find all context files with specs references:
   ```bash
   grep -rl "\.claude/specs/" .claude/context/
   ```
2. For each file, replace `.claude/specs/` with `specs/`
3. Update any bash script examples
4. Update grep/jq command patterns

**Verification**:
- `grep -r "\.claude/specs/" .claude/context/` returns nothing

---

### Phase 6: Update documentation and templates

**Estimated effort**: 20 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update documentation files
2. Update templates

**Files to modify**:
- `.claude/docs/templates/command-template.md`
- `.claude/docs/templates/skill-template.md`
- `.claude/docs/guides/*.md`
- `.claude/docs/commands/README.md`
- `.claude/docs/skills/README.md`
- `.claude/docs/reference/quick-reference.md`
- `.claude/docs/workflows/README.md`
- `.claude/docs/README.md`

**Steps**:
1. Find all docs with specs references
2. Replace `.claude/specs/` with `specs/`
3. Update any example paths

**Verification**:
- `grep -r "\.claude/specs/" .claude/docs/` returns nothing

---

### Phase 7: Update hooks and settings

**Estimated effort**: 10 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update hook scripts
2. Update settings.json

**Files to modify**:
- `.claude/hooks/validate-state-sync.sh`
- `.claude/settings.json`

**Steps**:
1. Update validate-state-sync.sh:
   - `STATE_FILE=".claude/specs/state.json"` → `STATE_FILE="specs/state.json"`
   - `TODO_FILE=".claude/specs/TODO.md"` → `TODO_FILE="specs/TODO.md"`
2. Update settings.json hook paths

**Verification**:
- `grep "\.claude/specs/" .claude/hooks/*` returns nothing
- `grep "\.claude/specs/" .claude/settings.json` returns nothing

---

### Phase 8: Update state.json internal references

**Estimated effort**: 5 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update state_references path in state.json

**Files to modify**:
- Current specs state.json (wherever it ends up after migration)

**Steps**:
1. Update `archive_state_path` from `.claude/specs/archive/state.json` to `specs/archive/state.json`
2. Update any artifact paths in active_projects

**Verification**:
- state.json contains no `.claude/specs/` references

---

## Dependencies

- Should be done BEFORE Task #22 (migration) to ensure new location has correct paths

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Missing a file | High | Use grep to verify all updated |
| Breaking relative paths | Medium | Test commands after update |
| Inconsistent updates | Medium | Use find/replace consistently |

## Success Criteria

- [ ] `grep -r "\.claude/specs/" .claude/` returns only task artifact files (plans, reports, summaries)
- [ ] All commands, skills, rules reference `specs/` at root
- [ ] CLAUDE.md shows correct project structure
- [ ] Hook scripts use correct paths
