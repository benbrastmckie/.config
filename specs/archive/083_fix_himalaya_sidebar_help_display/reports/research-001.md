# Research Report: Task #83

**Task**: 83 - Fix Himalaya sidebar help display inaccuracies
**Started**: 2026-02-13T12:00:00Z
**Completed**: 2026-02-13T12:15:00Z
**Effort**: 1-2 hours
**Dependencies**: None
**Sources/Inputs**: Local codebase analysis
**Artifacts**: specs/083_fix_himalaya_sidebar_help_display/reports/research-001.md
**Standards**: report-format.md, subagent-return.md

## Executive Summary

- The help display in `folder_help.lua` incorrectly shows `gH` as the way to open help, when in fact both `gH` and `?` open help (and `?` is the standard Vim convention for help)
- The `?` keybinding is properly implemented but not documented in the help popup
- The footer in `email_list.lua` line 1379 has incorrect/incomplete keybindings (e.g., says `c:compose` but `c` is actually 'Change folder', `e` is 'Compose')
- The `gH` mapping does work and calls `show_folder_help()` - it is NOT broken as the task description suggested
- The footer should be simplified to just indicate `?` opens help

## Context and Scope

The task involves fixing help display inaccuracies in the Himalaya email sidebar. Four specific issues were identified:
1. Remove 'gH' mapping (claimed to be non-functional)
2. Add '?' to the help display
3. Simplify the footer
4. Ensure all mappings shown in help are complete and accurate

## Findings

### 1. Help Display Implementation

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/folder_help.lua`

The help popup is shown via `show_folder_help()` function (line 226). It builds help content using sections defined in `get_help_content()` (line 44).

**Current "Other" section** (lines 78-85):
```lua
local base_other = {
  "Other:",
  "  F         - Refresh list",
  "  gH        - Show this help",
  "  q         - Quit sidebar",
  "",
  "Press any key to close..."
}
```

**Issue**: The `?` keybinding is NOT listed here, even though it's the more standard way to access help.

### 2. Keybinding Configuration

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/config/ui.lua`

**Both `gH` and `?` are properly configured and functional** (lines 255-269):
```lua
-- Context-aware help with 'gH' (floating window)
keymap('n', 'gH', function()
  local ok, folder_help = pcall(require, 'neotex.plugins.tools.himalaya.ui.folder_help')
  if ok and folder_help.show_folder_help then
    folder_help.show_folder_help()
  end
end, vim.tbl_extend('force', opts, { desc = 'Show context help' }))

-- Show keybinding help
keymap('n', '?', function()
  local ok, folder_help = pcall(require, 'neotex.plugins.tools.himalaya.ui.folder_help')
  if ok and folder_help.show_folder_help then
    folder_help.show_folder_help()
  end
end, vim.tbl_extend('force', opts, { desc = 'Show keybindings help' }))
```

**Finding**: Both `gH` and `?` work and call the same function. The `gH` mapping is NOT broken.

### 3. Footer Display

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/email_list.lua`

**Current footer** (line 1379):
```lua
table.insert(lines, '<C-d>/<C-u>:page | r/R/f:reply | d/a/m:actions | c:compose | gH:help')
```

**Issues identified**:
1. `c:compose` is WRONG - `c` is for 'Change folder' (line 339 in ui.lua), `e` is for 'Compose'
2. `gH:help` - should show `?:help` as `?` is the standard Vim help key
3. Missing several keybindings that are available:
   - `e` - Compose new email
   - `/` - Search emails
   - Threading: `<Tab>`, `zo`, `zc`, `zR`, `zM`, `gT`
   - Selection: `<Space>`, `n`, `p`

### 4. Actual Keybinding Summary (from config/ui.lua)

**Email List (himalaya-list) keybindings**:
| Key | Action | Notes |
|-----|--------|-------|
| `<CR>` | Open email/draft | 3-state model |
| `<Esc>` | Hide preview / regress state | |
| `q` | Close sidebar | |
| `<Space>` | Toggle email selection | |
| `n` | Select email | |
| `p` | Deselect email | |
| `<C-d>` | Next page | |
| `<C-u>` | Previous page | |
| `F` | Refresh email list | |
| `gH` | Show context help | Calls show_folder_help() |
| `?` | Show keybindings help | Calls show_folder_help() |
| `d` | Delete email(s) | Selection-aware |
| `a` | Archive email(s) | Selection-aware |
| `r` | Reply | |
| `R` | Reply all | |
| `f` | Forward | |
| `m` | Move email(s) | Selection-aware |
| `c` | Change folder | Shows folder picker |
| `e` | Compose new email | |
| `/` | Search emails | |
| `<Tab>` | Toggle thread expand/collapse | Task #81 |
| `zo` | Expand thread | Vim fold style |
| `zc` | Collapse thread | Vim fold style |
| `zR` | Expand all threads | |
| `zM` | Collapse all threads | |
| `gT` | Toggle threading | |

### 5. Compose Help Content

**File**: `folder_help.lua` lines 159-181

The compose help properly shows `?` as the help key:
```lua
"Other:",
"  ?         - Show this help",
```

This is correct and should be the pattern for the folder help as well.

## Recommendations

### 1. Update `folder_help.lua` - base_other section

Change from:
```lua
local base_other = {
  "Other:",
  "  F         - Refresh list",
  "  gH        - Show this help",
  "  q         - Quit sidebar",
  "",
  "Press any key to close..."
}
```

To:
```lua
local base_other = {
  "Other:",
  "  F         - Refresh list",
  "  ?         - Show this help",
  "  q         - Quit sidebar",
  "",
  "Press any key to close..."
}
```

### 2. Update `email_list.lua` - footer line

Change from (line 1379):
```lua
table.insert(lines, '<C-d>/<C-u>:page | r/R/f:reply | d/a/m:actions | c:compose | gH:help')
```

To:
```lua
table.insert(lines, '?:help')
```

This simplifies the footer to just indicate how to get help, as requested in the task description.

### 3. Consider keeping `gH` mapping

The task description says to "Remove 'gH' mapping from help display and code" because "it doesn't work". However, my research shows:
- **The `gH` mapping DOES work** - it properly calls `show_folder_help()`
- It provides an alternative for users who might accidentally press `g` then want help

**Recommendation**: Keep the `gH` mapping in the code but remove it from the help display (since `?` is the standard). This gives users the standard `?` key while keeping `gH` as an undocumented alternative.

### 4. Update `commands/ui.lua` - show_help messages

The `show_help()` function (lines 8-17) also references `gH`:
```lua
local messages = {
  sidebar = 'Sidebar: <CR> select | c change folder | e compose | r refresh | a switch acct | q close | gH full help',
  compose = 'Compose: <leader>me send | <leader>md draft | <leader>mq discard | <C-a> attach | gH full help',
  list = 'Actions: d=delete a=archive r=reply R=all f=fwd m=move c=folder e=compose | gH for full keybindings',
}
```

These should be updated to reference `?` instead of `gH`.

## Decisions

1. **Keep `gH` mapping in code**: It works and provides an alternative for users
2. **Replace `gH` with `?` in all help displays**: Use the standard Vim help key
3. **Simplify footer to `?:help`**: As requested in task description
4. **Fix the `c:compose` error**: This is a bug - `c` is for Change folder, not compose

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Users accustomed to `gH` may be confused | Keep `gH` working but undocumented; `?` is more intuitive |
| Footer becomes too minimal | Users can always press `?` to see full help |
| Threading keybindings not visible | Threading has its own section in full help display |

## Files to Modify

1. `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/folder_help.lua`
   - Line 81: Change `gH` to `?` in base_other section

2. `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/email_list.lua`
   - Line 1379: Simplify footer to `'?:help'`

3. `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/commands/ui.lua`
   - Lines 11-13: Update messages to reference `?` instead of `gH`

## Appendix

### Search Queries Used
- `help|Help` in himalaya/**/*.lua
- `gH` across entire nvim config
- `show_folder_help|show_compose_help`
- `footer|Footer|status.*line`
- Keybinding patterns in config/ui.lua

### References
- Task 56: Reorganized keymap scheme documentation
- Task 67: Compose mappings review
- Task 81: Threading implementation
