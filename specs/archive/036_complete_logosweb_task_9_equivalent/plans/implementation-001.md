# Implementation Plan: Task #44

- **Task**: 44 - Complete LogosWebsite Task 9 Equivalent
- **Status**: [IMPLEMENTING]
- **Effort**: 2-3 hours
- **Dependencies**: None
- **Research Inputs**: [research-002.md](../reports/research-002.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: /home/benjamin/.config/nvim/CLAUDE.md
- **Type**: meta
- **Date**: 2026-02-05

## Overview

Fix the Claude agent management system's `<leader>ac` sync mechanism to correctly source files from `~/.config/nvim` instead of `~/.config`, add multi-extension scanning for JSON/YAML files in the context directory, handle project-root CLAUDE.md syncing, and centralize the global directory path to eliminate 13 hardcoded references across 6 files. This plan does NOT add `output/` or `systemd/` directory scanning per user scoping.

### Research Integration

Research report identified three root causes: (1) stale global source path reading from `~/.config` instead of `~/.config/nvim`, (2) context directory scanner only matching `*.md` missing 3 JSON/YAML files, and (3) no project-root CLAUDE.md handling. The path issue affects 13 locations across 6 files. The `docs/reference/standards/` directory is already covered by the recursive `**/*.md` glob pattern in the docs scanner.

## Goals & Non-Goals

**Goals**:
- Fix global_dir from `~/.config` to `~/.config/nvim` across all 13 locations in 6 files
- Centralize the global directory path in `config.lua` to prevent future drift
- Add `.json` and `.yaml` extension scanning for the `context` directory
- Add project-root `CLAUDE.md` syncing (the file at `nvim/CLAUDE.md`, outside `.claude/`)
- Verify `docs/reference/standards/` is correctly covered by recursive glob

**Non-Goals**:
- Adding `output/` directory scanning (user excluded)
- Adding `systemd/` directory scanning (user excluded)
- Implementing a full wildcard/catch-all scan mode (future improvement)
- Reverse-sync capability (pushing local changes back to global)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Changing global_dir breaks picker display for projects using old path | Medium | Low | All 13 references updated atomically; old path was incorrect anyway |
| Config module not loaded before scan/sync modules | Medium | Low | Use lazy require pattern; fall back to hardcoded default |
| Multi-extension context scan produces duplicates | Low | Low | Scan functions already use dedup via `seen` table |
| Project-root CLAUDE.md overwrites project-specific customizations | Medium | Medium | Existing "Sync all" vs "New only" dialog handles this |

## Implementation Phases

### Phase 1: Centralize Global Directory in Config [COMPLETED]

**Goal**: Add a `global_source_dir` configuration option to `config.lua` and create a helper function that all modules can use, eliminating 13 hardcoded `~/.config` references.

**Tasks**:
- [ ] Add `global_source_dir` to `config.lua` defaults with value `vim.fn.expand("~/.config/nvim")`
- [ ] Create a helper function in `scan.lua` (`M.get_global_dir()`) that reads from config with fallback
- [ ] Update `scan.lua:139` (`get_directories` function) to use config value
- [ ] Update `sync.lua:203` (`load_all_globally`) to use config value
- [ ] Update `sync.lua:301` (`update_artifact_from_global`) to use config value
- [ ] Update `entries.lua` -- 5 locations (lines ~83, ~129, ~175, ~221, ~267) to use config value
- [ ] Update `previewer.lua:179` to use config value
- [ ] Update `edit.lua:33` and `edit.lua:116` to use config value
- [ ] Update `parser.lua:677` and `parser.lua:733` to use config value
- [ ] Update the "no artifacts found" warning message in `sync.lua:227` from `~/.config/.claude/` to reference the actual configured path

**Timing**: 1 hour

**Files to modify**:
- `lua/neotex/plugins/ai/claude/config.lua` - Add `global_source_dir` default
- `lua/neotex/plugins/ai/claude/commands/picker/utils/scan.lua` - Add `get_global_dir()` helper, update `get_directories()`
- `lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua` - Update 2 `global_dir` references + warning message
- `lua/neotex/plugins/ai/claude/commands/picker/display/entries.lua` - Update 5 `global_dir` references
- `lua/neotex/plugins/ai/claude/commands/picker/display/previewer.lua` - Update 1 `global_dir` reference
- `lua/neotex/plugins/ai/claude/commands/picker/operations/edit.lua` - Update 2 `global_dir` references
- `lua/neotex/plugins/ai/claude/commands/parser.lua` - Update 2 `global_dir` references

**Verification**:
- All 13 occurrences of `vim.fn.expand("~/.config")` removed from picker/operations/display modules
- Only `config.lua` and `scan.lua` (helper) contain the path definition
- `nvim --headless -c "lua require('neotex.plugins.ai.claude.config')" -c "q"` loads without error
- `grep -r 'expand.*~/.config"' lua/neotex/plugins/ai/claude/` returns only config.lua

---

### Phase 2: Add Multi-Extension Context Scanning [COMPLETED]

**Goal**: Extend the `scan_all_artifacts` function to scan `.json` and `.yaml` files in the context directory, capturing the 3 missing schema/template files.

**Tasks**:
- [ ] In `sync.lua` `scan_all_artifacts` function (line ~161), replace single `context` scan with multi-extension scan
- [ ] Scan `context` for `*.md`, `*.json`, and `*.yaml` extensions
- [ ] Merge results into single `artifacts.context` array (same pattern used by `skills` scanning on lines 163-172)
- [ ] Verify no duplicates across extension scans

**Timing**: 20 minutes

**Files to modify**:
- `lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua` - Replace line 161 with multi-extension scanning block

**Code change** (sync.lua, replacing line 161):
```lua
-- Current:
artifacts.context = scan.scan_directory_for_sync(global_dir, project_dir, "context", "*.md")

-- New (following the skills pattern from lines 163-172):
local ctx_md = scan.scan_directory_for_sync(global_dir, project_dir, "context", "*.md")
local ctx_json = scan.scan_directory_for_sync(global_dir, project_dir, "context", "*.json")
local ctx_yaml = scan.scan_directory_for_sync(global_dir, project_dir, "context", "*.yaml")
artifacts.context = {}
for _, files in ipairs({ ctx_md, ctx_json, ctx_yaml }) do
  for _, file in ipairs(files) do
    table.insert(artifacts.context, file)
  end
end
```

**Verification**:
- Run sync against a test project and confirm context count includes JSON/YAML files
- Specifically verify these 3 files appear in scan results:
  - `context/core/schemas/frontmatter-schema.json`
  - `context/core/schemas/subagent-frontmatter.yaml`
  - `context/core/templates/state-template.json`
- No duplicate entries in `artifacts.context`

---

### Phase 3: Add Project-Root CLAUDE.md Syncing [COMPLETED]

**Goal**: Extend the sync mechanism to copy the project-root `CLAUDE.md` (the file at `~/.config/nvim/CLAUDE.md` that sits outside `.claude/`) to the target project root.

**Tasks**:
- [ ] In `scan_all_artifacts` function, after the `root_files` section (after line 193), add scanning for the project-root `CLAUDE.md`
- [ ] The project-root CLAUDE.md lives at `global_dir .. "/CLAUDE.md"` (outside `.claude/`)
- [ ] The destination is `project_dir .. "/CLAUDE.md"` (project root, outside `.claude/`)
- [ ] Add it to `root_files` array with appropriate naming to distinguish from `.claude/CLAUDE.md`
- [ ] Update the sync notification message in `execute_sync` to show project-root CLAUDE.md separately or as part of root files count

**Timing**: 20 minutes

**Files to modify**:
- `lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua` - Add project-root CLAUDE.md to `scan_all_artifacts`

**Code change** (sync.lua, after line 193 in `scan_all_artifacts`):
```lua
-- Project-root CLAUDE.md (outside .claude/ directory)
local project_claude_global = global_dir .. "/CLAUDE.md"
local project_claude_local = project_dir .. "/CLAUDE.md"
if vim.fn.filereadable(project_claude_global) == 1 then
  table.insert(artifacts.root_files, {
    name = "CLAUDE.md (project root)",
    global_path = project_claude_global,
    local_path = project_claude_local,
    action = vim.fn.filereadable(project_claude_local) == 1 and "replace" or "copy",
    is_subdir = false,
  })
end
```

**Verification**:
- Sync from a test project shows the project-root CLAUDE.md in the artifact count
- The file is written to `<project>/CLAUDE.md` (not `<project>/.claude/CLAUDE.md`)
- The `.claude/CLAUDE.md` (internal) still syncs separately via the existing `root_file_names` list
- "New only" mode correctly skips existing project-root CLAUDE.md

---

### Phase 4: Verify docs/reference/standards/ Coverage [COMPLETED]

**Goal**: Confirm that the recursive glob pattern in the docs scanner correctly picks up all files in `docs/reference/standards/` and its subdirectories. If any gap exists, fix it.

**Tasks**:
- [ ] Verify the `scan_directory_for_sync` recursive glob picks up `docs/reference/standards/*.md`
- [ ] Test with `vim.fn.glob("~/.config/nvim/.claude/docs/**/\*.md", false, true)` to confirm it includes deeply nested files
- [ ] If the glob misses files, investigate and fix the recursive scanning logic
- [ ] Confirm that the only file currently in `docs/reference/standards/` (`multi-task-creation-standard.md`) appears in docs scan results

**Timing**: 15 minutes

**Files to modify**:
- None expected (the recursive glob should already work)
- If fix needed: `lua/neotex/plugins/ai/claude/commands/picker/utils/scan.lua`

**Verification**:
- Run `vim.fn.glob("~/.config/nvim/.claude/docs/**/\*.md", false, true)` in nvim and confirm `docs/reference/standards/multi-task-creation-standard.md` appears in output
- Run the full sync and verify docs count includes the standards file

---

### Phase 5: Integration Testing and Cleanup [COMPLETED]

**Goal**: End-to-end verification that all changes work correctly together. Test the full sync flow.

**Tasks**:
- [ ] Run `nvim --headless -c "lua require('neotex.plugins.ai.claude.config')" -c "q"` to verify config loads
- [ ] Run `nvim --headless -c "lua require('neotex.plugins.ai.claude.commands.picker.utils.scan')" -c "q"` to verify scan loads
- [ ] Run `nvim --headless -c "lua require('neotex.plugins.ai.claude.commands.picker.operations.sync')" -c "q"` to verify sync loads
- [ ] Verify no remaining hardcoded `~/.config"` paths in picker/operations/display modules (only in config.lua)
- [ ] Test `<leader>ac` picker opens without errors
- [ ] Test "Load All Artifacts" scan from a non-nvim project directory
- [ ] Verify the notification message shows correct source path
- [ ] Verify context scan includes JSON/YAML file counts
- [ ] Verify project-root CLAUDE.md appears in root files

**Timing**: 30 minutes

**Files to modify**: None (testing only)

**Verification**:
- All module require() calls succeed without errors
- `grep -rn 'expand.*"~/.config"' lua/neotex/plugins/ai/claude/commands/` returns 0 results (all moved to config)
- Full sync completes with updated counts reflecting JSON/YAML context files and project-root CLAUDE.md

## Testing & Validation

- [ ] All 6 modified Lua files load without errors via `nvim --headless`
- [ ] No hardcoded `~/.config"` remains in picker/operations/display modules
- [ ] Context scan finds 3 additional JSON/YAML files
- [ ] Project-root CLAUDE.md included in sync
- [ ] docs/reference/standards/ files included in docs scan
- [ ] Sync dialog shows correct counts (new + existing)
- [ ] "New only" mode skips existing files correctly
- [ ] "Sync all" mode replaces files correctly

## Artifacts & Outputs

- Modified `config.lua` with `global_source_dir` setting
- Modified `scan.lua` with `get_global_dir()` helper
- Modified `sync.lua` with multi-extension context scanning and project-root CLAUDE.md
- Updated 6 files to use centralized global directory path
- All changes confined to `lua/neotex/plugins/ai/claude/` directory tree

## Rollback/Contingency

All changes are in Lua configuration files under version control. If any phase introduces issues:
1. `git checkout -- lua/neotex/plugins/ai/claude/` reverts all changes
2. Each phase modifies independent concerns so partial rollback is possible
3. The `config.lua` change (Phase 1) is the foundation -- if it fails, skip Phases 2-4 and fix the 13 paths directly to `~/.config/nvim` as a simpler fallback
