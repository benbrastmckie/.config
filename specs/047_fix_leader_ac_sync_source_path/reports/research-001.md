# Research Report: Task #47

**Task**: Fix leader-ac sync source path
**Date**: 2026-02-05
**Focus**: Fix the `<leader>ac` sync source path to ensure the agent management tool reads from the correct source directory

## Summary

The `<leader>ac` keymap opens a Telescope picker (`ClaudeCommands`) that provides artifact browsing and a "Load All Artifacts" sync operation. Task 44 already changed the `global_source_dir` from the stale `~/.config` to `~/.config/nvim` (the actively-developed repo). However, three issues remain: (1) two directories (`output/` and `systemd/`) are not scanned by the sync mechanism, (2) the help text in the previewer still hardcodes `~/.config/nvim/.claude/` rather than using the config value, and (3) the stale `~/.config/.claude/` directory still exists and may confuse future maintenance. The core path fix is already in place; this task should address the remaining scanning gaps and cleanup.

## Findings

### 1. Keybinding Chain

The `<leader>ac` keymap is defined in two modes:

| Mode | Location | Action |
|------|----------|--------|
| Normal | `which-key.lua:248` | `<cmd>ClaudeCommands<CR>` -- Opens Telescope picker |
| Visual | `which-key.lua:249-254` | Calls `visual.send_visual_to_claude_with_prompt()` |

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua`

The `ClaudeCommands` user command is registered at `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/init.lua:146` and calls `commands_picker.show_commands_picker()`.

### 2. Current global_source_dir Configuration

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/config.lua:41`
```lua
global_source_dir = vim.fn.expand("~/.config/nvim"),
```

**Accessor**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/utils/scan.lua:8-17`
```lua
function M.get_global_dir()
  local ok, config = pcall(require, "neotex.plugins.ai.claude.config")
  if ok and config.options and config.options.global_source_dir then
    return config.options.global_source_dir
  end
  if ok and config.defaults and config.defaults.global_source_dir then
    return config.defaults.global_source_dir
  end
  return vim.fn.expand("~/.config/nvim")
end
```

This was fixed by task 44. The path `~/.config/nvim` is correct because:
- `~/.config/nvim/.claude/` is the git-tracked, actively-developed master copy
- `~/.config/.claude/` is a stale copy that was the old (incorrect) source
- Claude Code's actual global user config lives at `~/.claude/` (not `~/.config/.claude/`)

### 3. Remaining Issue: Unscanned Directories

Task 44's research report 2 identified that `output/` and `systemd/` directories are not scanned by `scan_all_artifacts()`. This was NOT fixed by task 44.

**Current scanned directories** (in sync.lua `scan_all_artifacts`):

| Directory | Extension | Status |
|-----------|-----------|--------|
| commands | `*.md` | Scanned |
| hooks | `*.sh` | Scanned |
| templates | `*.yaml` | Scanned |
| lib | `*.sh` | Scanned |
| docs | `*.md` | Scanned |
| scripts | `*.sh` | Scanned |
| tests | `test_*.sh` | Scanned |
| agents | `*.md` | Scanned |
| rules | `*.md` | Scanned |
| context | `*.md`, `*.json`, `*.yaml` | Scanned (fixed by task 44) |
| skills | `*.md`, `*.yaml` | Scanned |
| settings | `settings.json` | Scanned |
| root_files | specific filenames | Scanned |

**Missing directories**:

| Directory | Contents | Extension |
|-----------|----------|-----------|
| `output/` | 5 `.md` files (command output templates) | `*.md` |
| `systemd/` | 2 files (`.service` + `.timer`) | `*.service`, `*.timer` |
| `logs/` | Log files | (should NOT sync) |

**Files in output/**:
- `output/learn.md`
- `output/plan.md`
- `output/research.md`
- `output/revise.md`
- `output/todo.md`

**Files in systemd/**:
- `systemd/claude-refresh.service`
- `systemd/claude-refresh.timer`

### 4. Remaining Issue: Hardcoded Help Text

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/display/previewer.lua:159`
```lua
"            Otherwise a global artifact from ~/.config/nvim/.claude/",
```

And line 172:
```lua
"       Local artifacts override global ones from ~/.config/nvim/"
```

These hardcoded strings should ideally reference the actual configured value, though they are currently correct after task 44's fix.

### 5. Stale ~/.config/.claude/ Directory

The `~/.config/.claude/` directory is a stale copy of the agent system from Feb 1. It has:
- 63 files with outdated content compared to `~/.config/nvim/.claude/`
- Missing files added after Feb 1 (multi-task creation standard, migration script)

This directory is NOT used by:
- Claude Code (which uses `~/.claude/` for global config)
- The `<leader>ac` sync tool (which now reads from `~/.config/nvim`)

It exists as part of the user's `~/.config` dotfiles but serves no active purpose. It could be cleaned up or a reverse-sync mechanism could keep it updated.

### 6. Sync Behavior When in Source Directory

When the user is in `~/.config/nvim` (the source directory), `project_dir == global_dir`, and `load_all_globally()` correctly returns early with "Already in the global directory" message. This is correct behavior -- you should not sync from yourself to yourself.

### 7. Sync Mechanism Code Locations

| Component | File | Lines |
|-----------|------|-------|
| Config default | `config.lua` | 41 |
| Global dir accessor | `scan.lua` | 8-17 |
| Sync entry point | `sync.lua` | 223-307 |
| Artifact scanner | `sync.lua` | 148-218 |
| File sync executor | `sync.lua` | 49-81 |
| Picker integration | `picker/init.lua` | 86-93 |
| Help text | `previewer.lua` | 131-173 |
| Entries builder | `entries.lua` | (multiple references) |

All files under: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/`

## Recommendations

### Fix 1: Add output/ and systemd/ to Sync Scanner (Required)

In `sync.lua`, add these to `scan_all_artifacts()`:

```lua
-- Output templates
artifacts.output = scan.scan_directory_for_sync(global_dir, project_dir, "output", "*.md")

-- Systemd units (multiple extensions)
local systemd_service = scan.scan_directory_for_sync(global_dir, project_dir, "systemd", "*.service")
local systemd_timer = scan.scan_directory_for_sync(global_dir, project_dir, "systemd", "*.timer")
artifacts.systemd = {}
for _, file in ipairs(systemd_service) do
  table.insert(artifacts.systemd, file)
end
for _, file in ipairs(systemd_timer) do
  table.insert(artifacts.systemd, file)
end
```

And in `execute_sync()`, add:
```lua
counts.output = sync_files(all_artifacts.output or {}, false, merge_only)
counts.systemd = sync_files(all_artifacts.systemd or {}, false, merge_only)
```

Also update the notification format string to include output and systemd counts.

### Fix 2: Dynamic Help Text (Optional)

Replace hardcoded `~/.config/nvim/.claude/` in previewer.lua with the actual config value:
```lua
local scan = require("neotex.plugins.ai.claude.commands.picker.utils.scan")
local global_dir = scan.get_global_dir()
-- Use global_dir in help text instead of hardcoded path
```

### Fix 3: Cleanup or Document Stale ~/.config/.claude/ (Optional)

Options:
- **Option A**: Delete `~/.config/.claude/` since it is unused and stale
- **Option B**: Add a post-sync hook that also copies to `~/.config/.claude/` for backup
- **Option C**: Document in CLAUDE.md that `~/.config/.claude/` is not the active source

### Fix 4: Add Previewer Sync Counts for New Directories (Required with Fix 1)

Update `preview_load_all()` in previewer.lua to scan and display counts for `output/` and `systemd/`.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Adding output/systemd scanning changes sync behavior | Low | These are additive -- new directories appear in sync dialog |
| Removing ~/.config/.claude/ breaks something | Low | Verify nothing references it (nothing does) |
| Help text with dynamic path increases complexity | Low | Simple change, use existing get_global_dir() |

## References

- Task 44 research report 2: `specs/044_complete_logosweb_task_9_equivalent/reports/research-002.md`
- Task 44 implementation summary: `specs/044_complete_logosweb_task_9_equivalent/summaries/implementation-summary-20260205.md`
- Task 45 plan (non-goals section): `specs/045_fix_logosweb_agent_gaps_from_task_44/plans/implementation-001.md:31`

## Next Steps

Create an implementation plan to add output/ and systemd/ directory scanning to the sync mechanism, optionally update hardcoded help text, and document or clean up the stale ~/.config/.claude/ directory.
