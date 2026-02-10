# Implementation Plan: Task #47

- **Task**: 47 - Fix leader-ac sync source path
- **Date**: 2026-02-05
- **Feature**: Add output/ and systemd/ directory scanning to sync mechanism and fix hardcoded help text
- **Status**: [COMPLETED]
- **Estimated Hours**: 1-2 hours
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Research Reports**: [research-001.md](../reports/research-001.md)
- **Version**: 001
- **Language**: neovim

## Overview

Task 44 corrected the `global_source_dir` from `~/.config` to `~/.config/nvim`, but left three gaps: (1) the `output/` and `systemd/` directories are not scanned by the sync mechanism, (2) the previewer help text and Load All preview hardcode paths instead of using the configured value, and (3) the `update_artifact_from_global` subdir map lacks entries for the new artifact types. This plan addresses all three with targeted edits to sync.lua, previewer.lua, and the `init.lua` warning message.

### Research Integration

Research report 001 confirmed the core path is already fixed. The remaining work is additive: extending `scan_all_artifacts()` and `execute_sync()` to include `output/` (6 `.md` files) and `systemd/` (2 files: `.service` + `.timer`), updating `preview_load_all()` to display counts for these new categories, making the previewer help text dynamic, and adding the new types to `update_artifact_from_global()`'s subdir map. The `init.lua` warning message also hardcodes `~/.config/.claude/commands/` which should use the configured global dir.

## Goals & Non-Goals

**Goals**:
- Add `output/` and `systemd/` directory scanning to `scan_all_artifacts()` in sync.lua
- Add sync execution for these new categories in `execute_sync()`
- Update the notification format string to include output and systemd counts
- Add `output` and `systemd` entries to the `update_artifact_from_global()` subdir map
- Update `preview_load_all()` in previewer.lua to show counts for output/ and systemd/
- Replace hardcoded path strings in previewer.lua help text with dynamic values
- Fix the hardcoded path in picker/init.lua warning message (line 33)

**Non-Goals**:
- Adding output/ and systemd/ as browsable categories in the picker entries (this would require new entry types, preview functions, and edit handlers -- a separate enhancement)
- Cleaning up or removing the stale `~/.config/.claude/` directory (separate housekeeping task)
- Adding reverse-sync (local-to-global) for the new directories

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| output/ files have no executable permission needs | L | L | Use `preserve_perms = false` for output (markdown files) |
| systemd files need specific permissions | M | L | Use `preserve_perms = false` -- systemd units don't need execute bit |
| Dynamic help text adds require() call | L | L | scan module is already loaded elsewhere in previewer.lua |
| New artifact types not handled by Ctrl-u update | M | M | Add entries to subdir_map in update_artifact_from_global() |

## Implementation Phases

### Phase 1: Extend sync scanner and executor [COMPLETED]

**Goal**: Add output/ and systemd/ scanning to `scan_all_artifacts()` and syncing to `execute_sync()` in sync.lua, plus update the subdir map for individual artifact updates.

**Tasks**:
- [ ] In `scan_all_artifacts()` (line 148-218 of sync.lua), add scanning for `output/*.md` after the skills block
- [ ] In `scan_all_artifacts()`, add scanning for `systemd/*.service` and `systemd/*.timer` with multi-extension merge (same pattern as context and skills)
- [ ] In `execute_sync()` (line 88-142 of sync.lua), add `counts.output` and `counts.systemd` sync calls
- [ ] Update the notification format string in `execute_sync()` (lines 124-135) to include output and systemd counts
- [ ] In `update_artifact_from_global()` (line 334-346 of sync.lua), add `output` and `systemd` entries to `subdir_map`

**Timing**: 0.5 hours

**Files to modify**:
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua` - Add output/systemd scanning, syncing, notification, and subdir_map entries

**Verification**:
- Open Neovim and run `:ClaudeCommands`, navigate to Load All, verify the preview shows output and systemd counts
- Test sync from a different project directory to confirm output/ and systemd/ files are copied
- Test Ctrl-u update on an output or systemd artifact

---

### Phase 2: Update previewer for new categories and dynamic paths [COMPLETED]

**Goal**: Update `preview_load_all()` to display counts for output/ and systemd/, and replace hardcoded path strings in `preview_help()` with dynamic values from config.

**Tasks**:
- [ ] In `preview_load_all()` (line 178-248 of previewer.lua), add scanning for output/ and systemd/ directories
- [ ] Add count variables and display lines for output and systemd in the preview
- [ ] Include output and systemd in the total_copy and total_replace calculations
- [ ] In `preview_help()` (line 116-173 of previewer.lua), replace the hardcoded `~/.config/nvim/.claude/` on line 159 with a dynamic value from `scan.get_global_dir()`
- [ ] Replace the hardcoded `~/.config/nvim/` on line 172 with the dynamic value
- [ ] Fix the hardcoded path in picker/init.lua line 33 warning message

**Timing**: 0.5 hours

**Files to modify**:
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/display/previewer.lua` - Add output/systemd counts to Load All preview, make help text dynamic
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/init.lua` - Fix hardcoded path in warning message

**Verification**:
- Open Neovim, run `:ClaudeCommands`, check the Load All preview includes output and systemd lines
- Check the help preview shows the configured global directory path (not hardcoded)
- Verify the totals in the Load All preview correctly include the new categories

---

### Phase 3: Functional verification [COMPLETED]

**Goal**: End-to-end verification that the sync mechanism correctly handles all artifact types including the new ones.

**Tasks**:
- [ ] Run `nvim --headless -c "lua require('neotex.plugins.ai.claude.commands.picker.operations.sync')" -c "q"` to verify module loads without errors
- [ ] Run `nvim --headless -c "lua require('neotex.plugins.ai.claude.commands.picker.display.previewer')" -c "q"` to verify previewer module loads
- [ ] Run `nvim --headless -c "lua local s = require('neotex.plugins.ai.claude.commands.picker.utils.scan'); print(s.get_global_dir())" -c "q"` to verify config accessor works
- [ ] Run `nvim --headless -c "lua local s = require('neotex.plugins.ai.claude.commands.picker.utils.scan'); local files = s.scan_directory_for_sync(s.get_global_dir(), '/tmp/test_project', 'output', '*.md'); print(#files)" -c "q"` to verify output scanning works
- [ ] Run existing scan_spec.lua tests if available: check `scan_spec.lua` for relevant tests

**Timing**: 0.25 hours

**Files to modify**:
- None (verification only)

**Verification**:
- All headless tests pass without errors
- Module load tests return exit code 0
- Output directory scan returns expected file count (6 files)

## Testing & Validation

- [ ] Module loads: sync.lua, previewer.lua load without errors in headless Neovim
- [ ] Scan coverage: `scan_all_artifacts()` returns entries for output/ and systemd/ directories
- [ ] Sync execution: `execute_sync()` includes output and systemd in sync counts
- [ ] Preview display: Load All preview shows output and systemd line items
- [ ] Help text: Help preview shows dynamic path from config, not hardcoded string
- [ ] Individual update: `update_artifact_from_global()` handles `output` and `systemd` types
- [ ] No regressions: Existing artifact types (commands, hooks, skills, etc.) continue to sync correctly

## Artifacts & Outputs

- Modified `sync.lua` with extended scanning, syncing, and subdir_map
- Modified `previewer.lua` with new category counts and dynamic help text
- Modified `init.lua` with dynamic path in warning message

## Rollback/Contingency

All changes are additive. If the new scanning causes issues, revert the three files to their pre-change state using `git checkout`. No data migration or state changes are involved.
