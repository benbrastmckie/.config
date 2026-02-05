# Implementation Plan: Task #46

- **Task**: 46 - Migrate LogosWebsite to padded directory convention
- **Status**: [NOT STARTED]
- **Effort**: 3-5 hours
- **Dependencies**: None
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: meta
- **Date**: 2026-02-05

## Overview

Migrate the LogosWebsite repository from unpadded `{N}` task directory numbering to zero-padded `{NNN}` format for lexicographic sorting consistency with the nvim repo. The migration involves renaming 11 physical directories (4 active + 7 archived), updating 142 bash variable patterns across 19 files, changing 138 documentation placeholders across 44 files, updating 46 literal path references in state/TODO files, and revising convention documentation. All changes target `/home/benjamin/Projects/Logos/LogosWebsite/.claude/` and its `specs/` directory.

### Research Integration

Research report (research-001.md) provides a complete inventory of all files, patterns, and occurrence counts. The existing `migrate-directory-padding.sh` script from the nvim repo handles physical directory renames and can be reused directly. Key risk: directory renames and state file path updates must happen atomically to prevent broken references.

## Goals & Non-Goals

**Goals**:
- Rename all 11 task directories to use 3-digit zero-padded prefixes
- Update all bash variable patterns to use `${padded_num}_` with `printf "%03d"` conversion
- Update all documentation placeholders from `{N}_{SLUG}` to `{NNN}_{SLUG}`
- Update all literal path references in state.json, archive/state.json, and TODO.md
- Update convention documentation in CLAUDE.md and artifact-formats.md
- Validate no unpadded patterns remain after migration

**Non-Goals**:
- Modifying the migration script itself (it works as-is)
- Updating cross-repo references in the nvim repo (historical documentation)
- Changing task number formatting in prose text (commit messages, TODO.md entries keep `{N}` unpadded)
- Adding padding to artifact version numbers (already `{NNN}` format in LogosWebsite)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Broken path references if renames and state updates are not atomic | H | M | Phase 1 renames directories, Phase 2 immediately updates all path references before any commands are run |
| Git history discontinuity from directory renames | L | H | Accept discontinuity; `mv` is sufficient for this use case |
| Missing a pattern occurrence in a file | M | L | Phase 6 validation grep catches any remaining unpadded patterns |
| Active task references break during migration | M | L | No tasks are mid-implementation; safe to migrate all at once |

## Implementation Phases

### Phase 1: Rename physical directories [NOT STARTED]

**Goal:** Rename all 11 unpadded task directories to 3-digit padded format using the existing migration script.

**Tasks:**
- [ ] Copy `migrate-directory-padding.sh` from nvim repo to LogosWebsite (or run it with `--project-root`)
- [ ] Run script with `--dry-run` on `specs/` to verify 4 active directories will be renamed
- [ ] Run script with `--dry-run` on `specs/archive/` to verify 7 archived directories will be renamed
- [ ] Execute script on `specs/` (rename 4 active directories)
- [ ] Execute script on `specs/archive/` (rename 7 archived directories)
- [ ] Verify all 11 directories are renamed correctly with `ls specs/ specs/archive/`

**Timing:** 20 minutes

**Files to modify:**
- `specs/1_build_logos_laboratories_website/` -> `specs/001_build_logos_laboratories_website/`
- `specs/8_update_claude_md_for_web_development/` -> `specs/008_update_claude_md_for_web_development/`
- `specs/11_design_website_layout_and_architecture/` -> `specs/011_design_website_layout_and_architecture/`
- `specs/12_create_mcp_server_setup_guide/` -> `specs/012_create_mcp_server_setup_guide/`
- 7 archive directories (see research report for full list)

**Verification:**
- All directories in `specs/` and `specs/archive/` have 3-digit padded prefixes
- No unpadded directory names remain: `ls specs/ specs/archive/ | grep -E '^[0-9]{1,2}_'` returns nothing

---

### Phase 2: Update state files and TODO.md path references [NOT STARTED]

**Goal:** Update all 46 literal path references in state.json, archive/state.json, and TODO.md to use padded directory names. This must happen immediately after Phase 1 to maintain state consistency.

**Tasks:**
- [ ] Update `specs/state.json`: replace 23 unpadded artifact path references (e.g., `specs/12_` -> `specs/012_`, `specs/1_` -> `specs/001_`, `specs/8_` -> `specs/008_`, `specs/11_` -> `specs/011_`)
- [ ] Update `specs/archive/state.json`: replace 14 unpadded artifact path references (e.g., `specs/2_` -> `specs/002_`, `specs/3_` -> `specs/003_`, etc.)
- [ ] Update `specs/TODO.md`: replace 9 unpadded link paths (e.g., `12_create_mcp` -> `012_create_mcp`, `1_build_logos` -> `001_build_logos`)
- [ ] Validate JSON syntax in both state files with `jq . specs/state.json` and `jq . specs/archive/state.json`
- [ ] Validate all TODO.md links resolve to existing directories

**Timing:** 30 minutes

**Files to modify:**
- `specs/state.json` - 23 path reference updates
- `specs/archive/state.json` - 14 path reference updates
- `specs/TODO.md` - 9 link path updates

**Verification:**
- `jq . specs/state.json` parses without errors
- `jq . specs/archive/state.json` parses without errors
- No unpadded task directory references remain in state files: `grep -E 'specs/[0-9]{1,2}_' specs/state.json specs/archive/state.json` returns nothing

---

### Phase 3: Update bash variable patterns in skills and commands [NOT STARTED]

**Goal:** Add `padded_num=$(printf "%03d" "$task_number")` conversion and replace all `${task_number}_${project_name}` path constructions with `${padded_num}_${project_name}` across 19 files (142 occurrences).

**Tasks:**
- [ ] Update 9 skill files (76 occurrences): For each skill SKILL.md, add `padded_num=$(printf "%03d" "$task_number")` after `task_number` is set, then replace all `${task_number}_${project_name}` with `${padded_num}_${project_name}` in path constructions
  - `skill-typst-implementation/SKILL.md` (11)
  - `skill-neovim-implementation/SKILL.md` (11)
  - `skill-latex-implementation/SKILL.md` (11)
  - `skill-implementer/SKILL.md` (11)
  - `skill-web-implementation/SKILL.md` (9)
  - `skill-planner/SKILL.md` (6)
  - `skill-researcher/SKILL.md` (6)
  - `skill-web-research/SKILL.md` (6)
  - `skill-neovim-research/SKILL.md` (5)
- [ ] Update 2 command files (8 occurrences):
  - `commands/task.md` (7) - uses `${task_number}_${slug}` pattern
  - `commands/implement.md` (1)
- [ ] Update 6 context/pattern files (37 occurrences): Update code blocks in documentation to use padded patterns
  - `context/core/patterns/file-metadata-exchange.md` (14)
  - `context/core/patterns/postflight-control.md` (11)
  - `context/core/troubleshooting/workflow-interruptions.md` (4)
  - `context/core/patterns/metadata-file-return.md` (4)
  - `context/core/formats/return-metadata-file.md` (3)
  - `context/core/orchestration/routing.md` (1)
- [ ] Use the nvim repo's corresponding files as reference templates where applicable

**Timing:** 1.5 hours

**Files to modify:**
- 9 files in `.claude/skills/*/SKILL.md` - bash variable pattern updates
- 2 files in `.claude/commands/*.md` - bash variable pattern updates
- 6 files in `.claude/context/core/` - code block pattern updates

**Verification:**
- `grep -rn 'task_number}_' .claude/skills/ .claude/commands/ .claude/context/` returns zero matches for path construction patterns (note: `$task_number` used in non-path contexts like state.json field access should remain)
- Each modified file still has valid bash syntax in its code blocks

---

### Phase 4: Update documentation placeholders [NOT STARTED]

**Goal:** Replace all 138 documentation placeholders from `{N}_{SLUG}` to `{NNN}_{SLUG}` across 44 files (agents, skills, rules, docs, context, commands).

**Tasks:**
- [ ] Update 10 agent files (56 occurrences): Replace `{N}_{SLUG}` with `{NNN}_{SLUG}` and `{N}_{slug}` with `{NNN}_{slug}`
  - 9 agents with 6 occurrences each + meta-builder-agent with 2
- [ ] Update 10 skill files (29 occurrences): Replace documentation placeholders
- [ ] Update 7 rules/docs files (20 occurrences): Replace in artifact-formats.md, state-management.md, user-guide.md, creating-agents.md, adding-domains.md, creating-skills.md, system-overview.md
- [ ] Update 12 context files (25 occurrences): Replace in inline-status-update.md, return-metadata-file.md, generation-guidelines.md, subagent-return.md, file-metadata-exchange.md, metadata-file-return.md, component-checklist.md, postflight-control.md, early-metadata-pattern.md, workflow-interruptions.md, validation.md, project-overview.md
- [ ] Update 5 command files (7 occurrences): Replace in plan.md, revise.md, implement.md, todo.md, meta.md
- [ ] Handle variant patterns: `{N}_*` -> `{NNN}_*` in validation.md (3 occurrences)

**Timing:** 1 hour

**Files to modify:**
- 10 files in `.claude/agents/` - placeholder updates
- 10 files in `.claude/skills/*/SKILL.md` - placeholder updates
- 7 files in `.claude/rules/` and `.claude/docs/` - placeholder updates
- 12 files in `.claude/context/` - placeholder updates
- 5 files in `.claude/commands/` - placeholder updates

**Verification:**
- `grep -rn '{N}_' .claude/` returns zero matches for `{N}_{SLUG}` pattern (note: `{N}` alone in non-path contexts like "Task #{N}" or "task {N}:" should remain unchanged)
- `grep -rn '{N}_\*' .claude/` returns zero matches

---

### Phase 5: Update convention documentation [NOT STARTED]

**Goal:** Update CLAUDE.md and artifact-formats.md to document the `{NNN}` directory convention, matching the nvim repo's established wording and distinctions.

**Tasks:**
- [ ] Update `.claude/CLAUDE.md` line 39: Change `specs/{N}_{SLUG}/` to `specs/{NNN}_{SLUG}/`
- [ ] Update `.claude/CLAUDE.md` line 44: Add the key distinction note from nvim repo: "Task numbers remain unpadded ({N}) in TODO.md entries, state.json values, and commit messages. Only directory names and artifact version numbers use zero-padding for lexicographic sorting."
- [ ] Update `.claude/rules/artifact-formats.md`: Modify the placeholder table to remove `{N}_{SLUG}` from the `{N}` row and add `{NNN}_{SLUG}` to the `{NNN}` row examples
- [ ] Update `.claude/rules/artifact-formats.md`: Add key distinction note matching nvim repo version
- [ ] Update `.claude/rules/state-management.md`: Ensure lazy directory creation examples use `{NNN}` padding

**Timing:** 30 minutes

**Files to modify:**
- `.claude/CLAUDE.md` - Convention documentation and artifact path template
- `.claude/rules/artifact-formats.md` - Placeholder table and convention notes
- `.claude/rules/state-management.md` - Directory creation examples

**Verification:**
- CLAUDE.md artifact path template shows `{NNN}_{SLUG}` not `{N}_{SLUG}`
- artifact-formats.md placeholder table correctly separates `{N}` (text) from `{NNN}` (directories)
- Key distinction note is present in both files

---

### Phase 6: Validation and cleanup [NOT STARTED]

**Goal:** Verify no unpadded patterns remain anywhere in the LogosWebsite .claude/ directory or specs/ state files, and confirm all references are consistent.

**Tasks:**
- [ ] Run comprehensive grep for remaining `{N}_` documentation patterns: `grep -rn '{N}_' .claude/` (should return zero results for path patterns)
- [ ] Run comprehensive grep for remaining bash variable patterns: `grep -rn 'task_number}_' .claude/` in path construction contexts
- [ ] Run comprehensive grep for unpadded directory references in state files: `grep -E 'specs/[0-9]{1,2}_' specs/state.json specs/archive/state.json specs/TODO.md`
- [ ] Verify all TODO.md artifact links resolve: check each markdown link points to an existing file
- [ ] Verify state.json artifact paths are valid: extract paths with jq and verify each exists on disk
- [ ] Verify archive/state.json artifact paths are valid
- [ ] Run a spot-check: pick 3 skill files at random, confirm `padded_num` is defined and used in path construction

**Timing:** 30 minutes

**Files to modify:**
- None (read-only validation phase)

**Verification:**
- All grep checks return zero unpadded-path matches
- All artifact links in TODO.md resolve
- All artifact paths in state.json and archive/state.json point to existing files
- Spot-check confirms correct pattern in sampled files

## Testing & Validation

- [ ] `ls specs/ | grep -E '^[0-9]{1,2}_'` returns no results (all directories padded)
- [ ] `ls specs/archive/ | grep -E '^[0-9]{1,2}_'` returns no results
- [ ] `jq . specs/state.json` parses successfully
- [ ] `jq . specs/archive/state.json` parses successfully
- [ ] `grep -rn '{N}_{SLUG}' .claude/` returns no results
- [ ] `grep -rn '{N}_{slug}' .claude/` returns no results
- [ ] `grep -rn 'specs/[0-9]{1,2}_' specs/state.json specs/archive/state.json specs/TODO.md` returns no results
- [ ] All TODO.md markdown links resolve to existing files
- [ ] Spot-check 3 random skill files for correct `padded_num` pattern

## Artifacts & Outputs

- `specs/046_migrate_logosweb_to_padded_directory_conv/plans/implementation-001.md` (this file)
- `specs/046_migrate_logosweb_to_padded_directory_conv/summaries/implementation-summary-20260205.md` (on completion)
- 11 renamed directories in LogosWebsite `specs/` and `specs/archive/`
- Updated files across LogosWebsite `.claude/` directory (skills, agents, commands, context, rules, docs)
- Updated state files (`specs/state.json`, `specs/archive/state.json`, `specs/TODO.md`)

## Rollback/Contingency

If migration fails partway through:

1. **Directory renames**: `git checkout -- specs/` to restore original directory structure
2. **State file updates**: `git checkout -- specs/state.json specs/archive/state.json specs/TODO.md`
3. **Code/documentation changes**: `git checkout -- .claude/` to restore all .claude/ files

Since this is a meta task with no runtime dependencies, a full `git checkout` of the LogosWebsite repository restores the pre-migration state completely. The migration should be committed atomically (all phases in a single commit or phase-by-phase commits) to enable clean rollback.
