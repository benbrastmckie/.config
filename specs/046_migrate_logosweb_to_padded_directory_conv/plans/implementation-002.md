# Implementation Plan: Task #46 (Revised)

- **Task**: 46 - Migrate LogosWebsite to padded directory convention
- **Status**: [NOT STARTED]
- **Effort**: 2-3 hours
- **Dependencies**: None
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Previous Plan**: [implementation-001.md](implementation-001.md) - Superseded (scope over-broad)
- **Artifacts**: plans/implementation-002.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md
- **Type**: meta
- **Date**: 2026-02-05 (Revised)
- **Feature**: Pad LogosWebsite task directory names for lexicographic sorting
- **Estimated Hours**: 2-3 hours
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md

## Overview

Pad all LogosWebsite task directory prefixes from unpadded (`1_slug/`, `8_slug/`) to zero-padded (`001_slug/`, `008_slug/`) so directories display in correct numerical order in file explorers and `ls` output. The scope is **directory display order only** -- task numbers in prose text, JSON field values, and commit messages remain unpadded.

The work covers: (1) renaming 11 physical directories, (2) updating all references that contain directory paths (state.json artifact paths, TODO.md links, bash path constructions in skills/commands/context, documentation path templates), and (3) updating convention docs.

### Revision Rationale

Plan v001 was over-broad. The user clarified: "It is only important that the directories be padded, since the task number elsewhere in TODO.md and state.json don't need to be padded to display in the correct order." This revision focuses strictly on directory naming and references to directory paths, with systematic coverage of documentation that describes the directory convention.

### Research Integration

Research report (research-001.md) provides a complete inventory. The existing `migrate-directory-padding.sh` script handles physical renames. All 11 directories (4 active, 7 archived) need renaming, plus path references across ~60 files.

## Goals & Non-Goals

**Goals**:
- Rename all 11 task directories to 3-digit zero-padded prefixes
- Update all references containing directory paths (state.json, TODO.md, bash path constructions)
- Update documentation placeholders that describe directory naming (`{N}_{SLUG}` -> `{NNN}_{SLUG}`)
- Update convention documentation in CLAUDE.md and artifact-formats.md

**Non-Goals**:
- Padding task numbers in prose text ("Task #1", "task 8:" stay as-is)
- Padding task numbers in state.json `project_number` fields (remain integers)
- Modifying the migration script itself
- Updating cross-repo references in the nvim repo
- Changing artifact version numbering (already `{NNN}` format)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Broken paths if renames and state updates are out of sync | H | M | Phase 1 does renames, Phase 2 immediately updates all path references |
| Git history discontinuity | L | H | Acceptable; use `mv` via existing script |
| Missing a path occurrence | M | L | Phase 5 validation catches remaining unpadded paths |
| Over-replacement (padding non-path task numbers) | M | L | Careful pattern matching; non-path `{N}` contexts left alone |

## Implementation Phases

### Phase 1: Rename physical directories [NOT STARTED]

**Goal:** Rename all 11 unpadded task directories to 3-digit padded format.

**Tasks:**
- [ ] Run migration script with `--dry-run` on `specs/` to verify 4 active directories
- [ ] Run migration script with `--dry-run` on `specs/archive/` to verify 7 archived directories
- [ ] Execute script on `specs/` (rename 4 active directories)
- [ ] Execute script on `specs/archive/` (rename 7 archived directories)
- [ ] Verify with `ls specs/ specs/archive/`

**Timing:** 15 minutes

**Files to modify:**
- `specs/1_build_logos_laboratories_website/` -> `specs/001_build_logos_laboratories_website/`
- `specs/8_update_claude_md_for_web_development/` -> `specs/008_update_claude_md_for_web_development/`
- `specs/11_design_website_layout_and_architecture/` -> `specs/011_design_website_layout_and_architecture/`
- `specs/12_create_mcp_server_setup_guide/` -> `specs/012_create_mcp_server_setup_guide/`
- 7 archive directories (see research report for full list)

**Verification:**
- `ls specs/ | grep -E '^[0-9]{1,2}_'` returns nothing
- `ls specs/archive/ | grep -E '^[0-9]{1,2}_'` returns nothing

---

### Phase 2: Update path references in state files [NOT STARTED]

**Goal:** Update all literal directory path references in state.json, archive/state.json, and TODO.md to use padded directory names.

**Tasks:**
- [ ] Update `specs/state.json`: pad directory prefixes in 23 artifact path strings (e.g., `"specs/12_create_mcp` -> `"specs/012_create_mcp`)
- [ ] Update `specs/archive/state.json`: pad directory prefixes in 14 artifact path strings
- [ ] Update `specs/TODO.md`: pad directory prefixes in 9 link paths (e.g., `12_create_mcp` -> `012_create_mcp`)
- [ ] Validate JSON: `jq . specs/state.json` and `jq . specs/archive/state.json`

**Timing:** 20 minutes

**Files to modify:**
- `specs/state.json` - 23 path updates
- `specs/archive/state.json` - 14 path updates
- `specs/TODO.md` - 9 link path updates

**Verification:**
- Both state files parse with `jq .`
- `grep -E '"specs/[0-9]{1,2}_' specs/state.json specs/archive/state.json` returns nothing
- All TODO.md links resolve to existing files

---

### Phase 3: Update bash path constructions in skills, commands, and context [NOT STARTED]

**Goal:** Add `padded_num=$(printf "%03d" "$task_number")` and replace `${task_number}_` with `${padded_num}_` in directory path constructions across 19 files.

These are functional code blocks in skills/commands/context that construct file paths like `specs/${task_number}_${project_name}/`. The `${task_number}` variable is used in two contexts: (a) path construction (must be padded) and (b) non-path uses like jq field access or commit messages (must NOT be padded). Only path constructions change.

**Tasks:**
- [ ] Update 9 skill SKILL.md files (76 path construction occurrences):
  - Add `padded_num=$(printf "%03d" "$task_number")` after task_number is set
  - Replace `${task_number}_${project_name}` with `${padded_num}_${project_name}` in path contexts
  - Use nvim repo's corresponding files as reference templates
- [ ] Update 2 command files (8 occurrences):
  - `commands/task.md` (7 - uses `${task_number}_${slug}`)
  - `commands/implement.md` (1)
- [ ] Update 6 context/pattern files (37 occurrences in code blocks):
  - `context/core/patterns/file-metadata-exchange.md` (14)
  - `context/core/patterns/postflight-control.md` (11)
  - `context/core/troubleshooting/workflow-interruptions.md` (4)
  - `context/core/patterns/metadata-file-return.md` (4)
  - `context/core/formats/return-metadata-file.md` (3)
  - `context/core/orchestration/routing.md` (1)

**Timing:** 45 minutes

**Files to modify:**
- 9 files in `.claude/skills/*/SKILL.md`
- 2 files in `.claude/commands/`
- 6 files in `.claude/context/core/`

**Verification:**
- `grep -rn 'task_number}_${project_name}' .claude/skills/ .claude/commands/` returns zero matches in path construction lines
- `grep -rn 'padded_num' .claude/skills/` confirms padded_num is defined in each skill

---

### Phase 4: Update documentation path templates and placeholders [NOT STARTED]

**Goal:** Replace `{N}_{SLUG}` (and variants) with `{NNN}_{SLUG}` in documentation that describes directory path templates. Also update convention docs.

These are documentation placeholders in agent definitions, skill docs, rules, guides, and context files that describe the directory naming convention. The pattern `{N}` alone in non-path contexts (like "Task #{N}" or "task {N}:") is NOT changed.

**Tasks:**
- [ ] Update 10 agent files (56 occurrences): `{N}_{SLUG}` -> `{NNN}_{SLUG}`, `{N}_{slug}` -> `{NNN}_{slug}`
- [ ] Update 10 skill files (29 occurrences): documentation placeholders in path templates
- [ ] Update 5 command files (7 occurrences): path templates in plan.md, revise.md, implement.md, todo.md, meta.md
- [ ] Update 7 rules/docs files (20 occurrences): artifact-formats.md, state-management.md, user-guide.md, creating-agents.md, adding-domains.md, creating-skills.md, system-overview.md
- [ ] Update 12 context files (25 occurrences): path templates and directory references
- [ ] Handle variant: `{N}_*` -> `{NNN}_*` in validation.md (3 occurrences)
- [ ] Update `.claude/CLAUDE.md`: Change `specs/{N}_{SLUG}/` to `specs/{NNN}_{SLUG}/` in artifact paths section; add key distinction note
- [ ] Update `.claude/rules/artifact-formats.md`: Update placeholder table, add key distinction note

**Timing:** 45 minutes

**Files to modify:**
- 10 agent files, 10 skill files, 5 command files, 7 rules/docs files, 12 context files
- `.claude/CLAUDE.md`, `.claude/rules/artifact-formats.md`

**Verification:**
- `grep -rn '{N}_{SLUG}' .claude/` returns zero matches
- `grep -rn '{N}_{slug}' .claude/` returns zero matches
- `grep -rn '{N}_\*' .claude/` returns zero matches
- CLAUDE.md and artifact-formats.md contain key distinction note

---

### Phase 5: Validation [NOT STARTED]

**Goal:** Verify no unpadded directory path patterns remain. Confirm all references are consistent.

**Tasks:**
- [ ] Grep for remaining unpadded directory references in state files: `grep -E 'specs/[0-9]{1,2}_' specs/state.json specs/archive/state.json specs/TODO.md`
- [ ] Grep for remaining `{N}_{SLUG}` documentation patterns: `grep -rn '{N}_' .claude/`
- [ ] Grep for remaining `${task_number}_` path constructions: `grep -rn 'task_number}_' .claude/` (check only path contexts)
- [ ] Verify all TODO.md artifact links resolve to existing files
- [ ] Verify all state.json artifact paths point to existing directories
- [ ] Spot-check 3 skill files for correct `padded_num` pattern

**Timing:** 15 minutes

**Files to modify:**
- None (read-only validation)

**Verification:**
- All grep checks return zero unpadded-path matches
- All artifact links resolve
- Spot-checks pass

## Testing & Validation

- [ ] `ls specs/ | grep -E '^[0-9]{1,2}_'` returns no results
- [ ] `ls specs/archive/ | grep -E '^[0-9]{1,2}_'` returns no results
- [ ] `jq . specs/state.json` parses successfully
- [ ] `jq . specs/archive/state.json` parses successfully
- [ ] `grep -rn '{N}_{SLUG}' .claude/` returns no results
- [ ] `grep -E 'specs/[0-9]{1,2}_' specs/state.json specs/archive/state.json specs/TODO.md` returns no results
- [ ] All TODO.md markdown links resolve to existing files

## Artifacts & Outputs

- `specs/046_migrate_logosweb_to_padded_directory_conv/plans/implementation-002.md` (this file)
- 11 renamed directories in LogosWebsite `specs/` and `specs/archive/`
- Updated path references across LogosWebsite `.claude/` and `specs/` files

## Rollback/Contingency

Full `git checkout` of LogosWebsite repository restores pre-migration state. No runtime dependencies are affected since this is a meta task.
