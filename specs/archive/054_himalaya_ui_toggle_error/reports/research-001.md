# Research Report: Task #54

**Task**: 54 - himalaya_ui_toggle_error
**Started**: 2026-02-10T12:00:00Z
**Completed**: 2026-02-10T12:30:00Z
**Effort**: 0.5 hours
**Dependencies**: None
**Sources/Inputs**: Local codebase analysis, himalaya plugin documentation
**Artifacts**: specs/054_himalaya_ui_toggle_error/reports/research-001.md
**Standards**: report-format.md

## Executive Summary

- The `toggle` nil error at ui.lua:32 is caused by `commands/ui.lua` calling `main.toggle()` which does not exist in `ui/main.lua`
- The `ui/main.lua` module has `toggle_email_sidebar()` but no `toggle()` method
- The `ui/sidebar.lua` module does have a `toggle()` method that should be used instead
- The fix is straightforward: change `main.toggle()` to either `main.toggle_email_sidebar()` or use `sidebar.toggle()` directly
- Current keybindings are well-organized under `<leader>m` prefix with comprehensive coverage

## Context and Scope

This research investigates an error that occurs when pressing `<leader>mo` to toggle the Himalaya email sidebar:

```
Error executing Lua callback: ...g/nvim/lua/neotex/plugins/tools/himalaya/commands/ui.lua:32: attempt to call field 'toggle' (a nil value)
stack traceback:
        ...g/nvim/lua/neotex/plugins/tools/himalaya/commands/ui.lua:32: in function <...g/nvim/lua/neotex/plugins/tools/himalaya/commands/ui.lua:30>
```

The scope includes:
1. Finding the root cause of the nil error
2. Documenting existing himalaya keybindings
3. Identifying potential improvements to mappings

## Findings

### Root Cause of the `toggle` Nil Error

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/commands/ui.lua`

Lines 29-37 define the `HimalayaToggle` command:

```lua
commands.HimalayaToggle = {
  fn = function()
    local main = require('neotex.plugins.tools.himalaya.ui.main')
    main.toggle()  -- ERROR: main.toggle() does not exist!
  end,
  opts = {
    desc = 'Toggle Himalaya email client'
  }
}
```

**Problem**: The code calls `main.toggle()` but the `ui/main.lua` module does NOT have a `toggle()` function.

**Evidence from `ui/main.lua`**:
- Line 43-45 defines `M.toggle_email_sidebar()` (correct function name)
- No `M.toggle()` function exists

**Evidence from `ui/sidebar.lua`**:
- Line 142-149 defines `M.toggle()` function which correctly toggles the sidebar

### API Mismatch Analysis

| Module | Function Available | Status |
|--------|-------------------|--------|
| `ui/main.lua` | `toggle_email_sidebar()` | Exists but not called |
| `ui/main.lua` | `toggle()` | DOES NOT EXIST |
| `ui/sidebar.lua` | `toggle()` | Exists and works |
| `ui/init.lua` | Re-exports from `main` | Has `toggle_email_sidebar` |

The `ui/init.lua` module re-exports `main` functions but also does not add a `toggle()` wrapper.

### Existing Himalaya Keybindings

All keybindings are defined in `lua/neotex/plugins/editor/which-key.lua` under the `<leader>m` prefix:

#### Global Keybindings (`<leader>m`)

| Keybinding | Command | Description | Icon |
|------------|---------|-------------|------|
| `<leader>ma` | `HimalayaAccounts` | Switch account | |
| `<leader>md` | `HimalayaSaveDraft` | Save draft | |
| `<leader>mD` | `HimalayaDiscard` | Discard email | |
| `<leader>me` | `HimalayaSend` | Send email | |
| `<leader>mf` | `HimalayaFolder` | Change folder | |
| `<leader>mF` | `HimalayaRecreateFolders` | Recreate folders | |
| `<leader>mh` | `HimalayaHealth` | Health check | |
| `<leader>mi` | `HimalayaSyncInfo` | Sync status | |
| `<leader>mo` | `HimalayaToggle` | Toggle sidebar | (BROKEN) |
| `<leader>mq` | `HimalayaDiscard` | Quit (discard) | (conditional) |
| `<leader>ms` | `HimalayaSyncInbox` | Sync inbox | |
| `<leader>mS` | `HimalayaSyncFull` | Full sync | |
| `<leader>mt` | `HimalayaAutoSyncToggle` | Toggle auto-sync | |
| `<leader>mw` | `HimalayaWrite` | Write email | |
| `<leader>mW` | `HimalayaSetup` | Setup wizard | |
| `<leader>mx` | `HimalayaCancelSync` | Cancel all syncs | |
| `<leader>mX` | `HimalayaBackupAndFresh` | Backup and fresh | |

#### Buffer-Local Keybindings (Email List)

The email list buffer (`himalaya-list` filetype) has additional keybindings defined in `ui/email_list.lua`:

- `<CR>` / `l` - Preview email
- `r` - Reply
- `R` - Reply all
- `f` - Forward
- `d` - Delete
- `a` - Archive
- `s` - Mark as spam
- `m` - Move to folder
- `c` - Compose new
- `/` - Search
- `gs` - Sync current folder
- `gf` - Change folder
- `ga` - Switch account
- `n` / `p` - Next/previous page
- `v` - Enter selection mode
- `x` - Toggle selection
- `q` - Close sidebar

### Other Issues Found

1. **Inconsistent Function Naming**: The codebase uses both `toggle_email_sidebar()` and `toggle()` patterns inconsistently.

2. **Missing `open` Function**: The `commands/ui.lua` also has a `Himalaya` command (line 19-27) that calls `main.open()` but `ui/main.lua` does not have an `open()` function. The sidebar module has `open()`. This could be another bug.

3. **Deprecated Command Patterns**: Some commands in the README reference patterns that may not match the actual implementation (e.g., `<leader>ml` mentioned in wizard but not in which-key.lua).

## Recommendations

### Fix the Toggle Error

**Option 1 (Recommended)**: Change the call in `commands/ui.lua` to use the correct function name:

```lua
commands.HimalayaToggle = {
  fn = function()
    local main = require('neotex.plugins.tools.himalaya.ui.main')
    main.toggle_email_sidebar()  -- Use the correct function name
  end,
  -- ...
}
```

**Option 2**: Use the sidebar module directly:

```lua
commands.HimalayaToggle = {
  fn = function()
    local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
    sidebar.toggle()
  end,
  -- ...
}
```

**Option 3**: Add a `toggle()` alias in `ui/main.lua`:

```lua
M.toggle = M.toggle_email_sidebar
```

### Fix the Himalaya Command (Potential Bug)

The `Himalaya` command calls `main.open()` which does not exist. Check if this is also broken:

```lua
commands.Himalaya = {
  fn = function()
    local main = require('neotex.plugins.tools.himalaya.ui.main')
    main.open()  -- Potentially broken - verify this works
  end,
  -- ...
}
```

If broken, change to `main.show_email_list({})` or use the sidebar directly.

### Keybinding Improvements

1. **Add missing keybinding for open (without toggle)**: Consider `<leader>ml` for "list" to just open without toggle behavior.

2. **Consistency with which-key group**: The mail group is well-organized. Consider adding a subgroup for compose-specific actions when in compose buffer.

3. **Help/documentation key**: Consider adding `<leader>m?` to show keybinding help.

## Decisions

1. The fix should use Option 1 (correct function name) as it maintains the existing module structure.
2. The `Himalaya` command should also be verified and fixed if broken.
3. No keybinding changes are required beyond fixing the broken toggle command.

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Other commands may have similar issues | Audit all commands in `commands/ui.lua` |
| Tests may not cover this code path | Add integration test for toggle command |
| Function renames could break other callers | Search for all callers of toggle patterns |

## Appendix

### Files Analyzed

- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/commands/ui.lua` (error source)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/main.lua` (no toggle function)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/init.lua` (re-exports)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/sidebar.lua` (has toggle)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/email_list.lua` (has toggle_email_sidebar)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua` (keybindings)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/README.md` (documentation)

### Search Queries Used

- `toggle` in ui/main.lua
- `himalaya` in which-key.lua
- `<leader>m` in himalaya directory

### References

- Himalaya README: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/README.md`
- Commands init: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/commands/init.lua`
