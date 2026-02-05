# Research Report: Task #46

**Task**: Migrate LogosWebsite to padded directory convention
**Date**: 2026-02-05
**Focus**: Analyze scope of {N} to {NNN} padding migration for LogosWebsite

## Summary

The LogosWebsite repository currently uses unpadded task directory numbers (`1_slug/`, `8_slug/`, `12_slug/`) while the nvim repo has already migrated to zero-padded `{NNN}` format (`001_slug/`, `008_slug/`). This migration requires: (1) renaming 11 physical directories (4 active + 7 archived), (2) updating 121 `${task_number}_` bash variable references across 17 files to use `${padded_num}_` with a `printf "%03d"` conversion, (3) changing 135 `{N}_{SLUG}` documentation placeholders across 44 files to `{NNN}_{SLUG}`, (4) updating artifact paths in state.json (23 unpadded path references), archive/state.json (14 unpadded path references), and TODO.md (9 unpadded link paths), and (5) updating convention documentation in CLAUDE.md and artifact-formats.md.

## Current State

### Existing Active Directories (4 directories to rename)

| Current Name | Padded Name |
|-------------|-------------|
| `specs/1_build_logos_laboratories_website/` | `specs/001_build_logos_laboratories_website/` |
| `specs/8_update_claude_md_for_web_development/` | `specs/008_update_claude_md_for_web_development/` |
| `specs/11_design_website_layout_and_architecture/` | `specs/011_design_website_layout_and_architecture/` |
| `specs/12_create_mcp_server_setup_guide/` | `specs/012_create_mcp_server_setup_guide/` |

### Archive Directories (7 directories to rename)

| Current Name | Padded Name |
|-------------|-------------|
| `specs/archive/2_fix_specs_prefix_in_todo_artifact_links/` | `specs/archive/002_fix_specs_prefix_in_todo_artifact_links/` |
| `specs/archive/3_add_web_language_routing/` | `specs/archive/003_add_web_language_routing/` |
| `specs/archive/4_create_web_research_agent_and_skill/` | `specs/archive/004_create_web_research_agent_and_skill/` |
| `specs/archive/5_create_web_implementation_agent_and_skill/` | `specs/archive/005_create_web_implementation_agent_and_skill/` |
| `specs/archive/6_create_web_context_files/` | `specs/archive/006_create_web_context_files/` |
| `specs/archive/7_create_web_development_rule_file/` | `specs/archive/007_create_web_development_rule_file/` |
| `specs/archive/10_integrate_tools_into_web_subagents/` | `specs/archive/010_integrate_tools_into_web_subagents/` |

### Artifact Files Inside Directories

30 artifact files across all directories will be implicitly moved when directories are renamed. No internal content changes needed within these files (they reference task numbers in text, not directory paths).

## Files Requiring Changes

### Category 1: Skills (bash variable patterns - `${task_number}_` to `${padded_num}_`)

Each of these files needs:
1. Add `padded_num=$(printf "%03d" "$task_number")` after task_number is set
2. Replace all `${task_number}_${project_name}` with `${padded_num}_${project_name}` in path constructions

| File | Occurrences |
|------|------------|
| `.claude/skills/skill-typst-implementation/SKILL.md` | 11 |
| `.claude/skills/skill-neovim-implementation/SKILL.md` | 11 |
| `.claude/skills/skill-latex-implementation/SKILL.md` | 11 |
| `.claude/skills/skill-implementer/SKILL.md` | 11 |
| `.claude/skills/skill-web-implementation/SKILL.md` | 9 |
| `.claude/skills/skill-planner/SKILL.md` | 6 |
| `.claude/skills/skill-researcher/SKILL.md` | 6 |
| `.claude/skills/skill-web-research/SKILL.md` | 6 |
| `.claude/skills/skill-neovim-research/SKILL.md` | 5 |
| **Subtotal** | **76** |

### Category 2: Commands (bash variable patterns)

| File | Occurrences |
|------|------------|
| `.claude/commands/task.md` | 7 |
| `.claude/commands/implement.md` | 1 |
| **Subtotal** | **8** |

### Category 3: Context/Patterns (bash variable patterns in documentation code blocks)

| File | Occurrences |
|------|------------|
| `.claude/context/core/patterns/file-metadata-exchange.md` | 14 |
| `.claude/context/core/patterns/postflight-control.md` | 11 |
| `.claude/context/core/troubleshooting/workflow-interruptions.md` | 4 |
| `.claude/context/core/patterns/metadata-file-return.md` | 4 |
| `.claude/context/core/formats/return-metadata-file.md` | 3 |
| `.claude/context/core/orchestration/routing.md` | 1 |
| **Subtotal** | **37** |

### Category 4: Agents (documentation placeholders - `{N}_{SLUG}` to `{NNN}_{SLUG}`)

| File | Occurrences |
|------|------------|
| `.claude/agents/general-implementation-agent.md` | 6 |
| `.claude/agents/general-research-agent.md` | 6 |
| `.claude/agents/web-implementation-agent.md` | 6 |
| `.claude/agents/planner-agent.md` | 6 |
| `.claude/agents/typst-implementation-agent.md` | 6 |
| `.claude/agents/latex-implementation-agent.md` | 6 |
| `.claude/agents/neovim-implementation-agent.md` | 6 |
| `.claude/agents/web-research-agent.md` | 6 |
| `.claude/agents/neovim-research-agent.md` | 6 |
| `.claude/agents/meta-builder-agent.md` | 2 (uses `{N}_{slug}`) |
| **Subtotal** | **56** |

### Category 5: Skills (documentation placeholders - `{N}_{SLUG}` to `{NNN}_{SLUG}`)

| File | Occurrences |
|------|------------|
| `.claude/skills/skill-planner/SKILL.md` | 4 |
| `.claude/skills/skill-implementer/SKILL.md` | 4 |
| `.claude/skills/skill-researcher/SKILL.md` | 4 |
| `.claude/skills/skill-typst-implementation/SKILL.md` | 3 |
| `.claude/skills/skill-neovim-implementation/SKILL.md` | 3 |
| `.claude/skills/skill-latex-implementation/SKILL.md` | 3 |
| `.claude/skills/skill-web-implementation/SKILL.md` | 3 |
| `.claude/skills/skill-neovim-research/SKILL.md` | 2 |
| `.claude/skills/skill-web-research/SKILL.md` | 2 |
| `.claude/skills/skill-git-workflow/SKILL.md` | 1 |
| **Subtotal** | **29** |

### Category 6: Rules and Documentation (placeholders)

| File | Occurrences |
|------|------------|
| `.claude/rules/artifact-formats.md` | 5 (includes convention definition) |
| `.claude/rules/state-management.md` | 3 |
| `.claude/docs/guides/user-guide.md` | 5 |
| `.claude/docs/guides/creating-agents.md` | 3 |
| `.claude/docs/guides/adding-domains.md` | 2 |
| `.claude/docs/guides/creating-skills.md` | 1 |
| `.claude/docs/architecture/system-overview.md` | 1 |
| **Subtotal** | **20** |

### Category 7: Context files (placeholders)

| File | Occurrences |
|------|------------|
| `.claude/context/core/patterns/inline-status-update.md` | 3 |
| `.claude/context/core/formats/return-metadata-file.md` | 3 |
| `.claude/context/core/architecture/generation-guidelines.md` | 3 |
| `.claude/context/core/formats/subagent-return.md` | 2 |
| `.claude/context/core/patterns/file-metadata-exchange.md` | 2 |
| `.claude/context/core/patterns/metadata-file-return.md` | 2 |
| `.claude/context/core/architecture/component-checklist.md` | 2 |
| `.claude/context/core/patterns/postflight-control.md` | 2 |
| `.claude/context/core/patterns/early-metadata-pattern.md` | 1 |
| `.claude/context/core/troubleshooting/workflow-interruptions.md` | 1 |
| `.claude/context/core/validation.md` | 3 (uses `{N}_*`) |
| `.claude/context/project/repo/project-overview.md` | 1 |
| **Subtotal** | **25** |

### Category 8: CLAUDE.md (convention documentation)

| File | Occurrences | Change |
|------|------------|--------|
| `.claude/CLAUDE.md` | 1 (`{N}_{SLUG}`) + convention text | Update path template and description |
| **Subtotal** | **1 + text** |

### Category 9: Commands (documentation placeholders)

| File | Occurrences |
|------|------------|
| `.claude/commands/plan.md` | 2 |
| `.claude/commands/revise.md` | 2 |
| `.claude/commands/implement.md` | 1 |
| `.claude/commands/todo.md` | 1 |
| `.claude/commands/meta.md` | 1 (uses `{N}_{slug}`) |
| **Subtotal** | **7** |

### Category 10: State files (artifact paths with literal unpadded numbers)

| File | Change Needed |
|------|--------------|
| `specs/state.json` | Update 23 artifact path references (e.g., `specs/12_create_mcp_server_setup_guide/` to `specs/012_create_mcp_server_setup_guide/`) |
| `specs/archive/state.json` | Update 14 artifact path references (e.g., `specs/3_add_web_language_routing/` to `specs/003_add_web_language_routing/`) |
| `specs/TODO.md` | Update 9 link paths (e.g., `12_create_mcp_server_setup_guide/` to `012_create_mcp_server_setup_guide/`) |

## Migration Script Analysis

### Existing Script: `/home/benjamin/.config/nvim/.claude/scripts/migrate-directory-padding.sh`

The nvim repo's migration script handles **directory renaming only**. It:
- Scans `specs/` for directories matching `[0-9]*_*/`
- Extracts numeric prefix and checks if already 3-digit padded
- Renames unpadded directories to padded format using `printf "%03d"`
- Supports `--dry-run` mode
- Supports `--specs-dir` to override the default specs directory
- Reports statistics (found, already padded, migrated, errors)

**Reuse Assessment**: The script can be reused directly for physical directory renaming. It needs to be run twice:
1. `./migrate-directory-padding.sh --project-root /home/benjamin/Projects/Logos/LogosWebsite --specs-dir specs`
2. `./migrate-directory-padding.sh --project-root /home/benjamin/Projects/Logos/LogosWebsite --specs-dir specs/archive`

**Limitations**: The script does NOT handle:
- Updating `${task_number}_` bash patterns in skill/command files
- Updating `{N}_{SLUG}` documentation placeholders
- Updating artifact paths in state.json / archive/state.json / TODO.md
- Updating convention documentation in CLAUDE.md / artifact-formats.md

These require separate implementation phases.

## Pattern Inventory

### Bash Variable Patterns (in code blocks, functional)

| Pattern | Count | Files | Change Needed |
|---------|-------|-------|---------------|
| `${task_number}_${project_name}` | 114 | 15 skill/command files | Add `padded_num=$(printf "%03d" "$task_number")` and use `${padded_num}_${project_name}` |
| `${task_number}_${slug}` | 7 | 1 file (task.md) | Same pattern with `${padded_num}_${slug}` |
| `${task_number}_${task_slug}` | 14+4+3 = 21 | 3 context files | Same pattern with `${padded_num}_${task_slug}` |
| **Total bash patterns** | **121+21 = 142** | **19 files** | |

### Documentation Placeholders (in prose/templates)

| Pattern | Count | Files | Change Needed |
|---------|-------|-------|---------------|
| `{N}_{SLUG}` | 132 | 42 files | Change to `{NNN}_{SLUG}` |
| `{N}_{slug}` | 3 | 2 files | Change to `{NNN}_{slug}` |
| `{N}_*` | 3 | 1 file | Change to `{NNN}_*` |
| **Total placeholder patterns** | **138** | **44 files** (some overlap) | |

### Literal Path References (in data files)

| File | Pattern | Count | Change Needed |
|------|---------|-------|---------------|
| `specs/state.json` | `specs/N_slug/` | 23 | Pad N to NNN in paths |
| `specs/archive/state.json` | `specs/N_slug/` | 14 | Pad N to NNN in paths |
| `specs/TODO.md` | `N_slug/` | 9 | Pad N to NNN in link paths |
| **Total literal paths** | | **46** | |

### Convention Documentation

| File | Change Needed |
|------|---------------|
| `.claude/CLAUDE.md` line 39 | `specs/{N}_{SLUG}/` -> `specs/{NNN}_{SLUG}/` |
| `.claude/CLAUDE.md` line 44 | Update description to match nvim convention |
| `.claude/rules/artifact-formats.md` line 13 | Update `{N}` row to remove `{N}_{SLUG}` usage |
| `.claude/rules/artifact-formats.md` line 14 | Add `{NNN}_{SLUG}` to `{NNN}` row examples |
| `.claude/rules/artifact-formats.md` lines 20+ | Add key distinction note (from nvim version) |

## Recommendations

1. **Phase 1 - Physical directory renaming**: Use the existing migration script from the nvim repo. Run it for both `specs/` and `specs/archive/`. This is the most critical step and should be done first.

2. **Phase 2 - State file updates**: Update `state.json`, `archive/state.json`, and `TODO.md` with padded paths. This can be done with targeted sed/jq commands or manual edits.

3. **Phase 3 - Bash variable patterns**: For each of the 19 files with `${task_number}_` patterns, add a `padded_num=$(printf "%03d" "$task_number")` line and replace path references. The nvim repo's corresponding files serve as exact templates.

4. **Phase 4 - Documentation placeholders**: Bulk replace `{N}_{SLUG}` with `{NNN}_{SLUG}` across 44 files. This is a straightforward text substitution.

5. **Phase 5 - Convention documentation**: Update CLAUDE.md and artifact-formats.md to document the new convention, matching the nvim repo's wording.

6. **Phase 6 - Validation**: Run `grep -r '{N}_' .claude/` and `grep -r '${task_number}_' .claude/` to verify no unpadded patterns remain. Also verify all TODO.md links resolve correctly.

## Risks

1. **Git history**: Directory renames will show as delete+add in git history. Use `git mv` through the migration script (it currently uses `mv`) or accept the history discontinuity.

2. **Active task references**: Task 9 (not started) and task 11 (planned) have directory references that will change. Task 1 (researched) also has references. No tasks are mid-implementation, so this is safe.

3. **Cross-repo references**: The nvim repo's task 44 research report references LogosWebsite paths. These are historical documentation and do not need updating.

4. **state.json artifact paths**: These are read by commands during workflow execution. If paths are updated in state.json but directories are not yet renamed (or vice versa), commands will fail. The rename + state update must be atomic.

5. **TODO.md relative links**: The links in TODO.md are relative to the specs/ directory. After renaming, links like `12_create_mcp_server_setup_guide/reports/research-001.md` must become `012_create_mcp_server_setup_guide/reports/research-001.md`.

## Next Steps

Run `/plan 46` to create an implementation plan based on this research. The plan should organize changes into phases that maintain atomicity (directories and their references updated together) and include a validation phase.
