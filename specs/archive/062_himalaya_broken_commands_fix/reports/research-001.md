# Research Report: Task #62

**Task**: 62 - Fix broken himalaya commands (d, a, ?, r)
**Started**: 2026-02-10T00:00:00Z
**Completed**: 2026-02-10T00:15:00Z
**Effort**: 2-4 hours
**Dependencies**: Task 56 (keymap reorganization), Task 60 (show_help implementation)
**Sources/Inputs**: Local configuration analysis, plugin architecture review
**Artifacts**: - /home/benjamin/.config/nvim/specs/062_himalaya_broken_commands_fix/reports/research-001.md
**Standards**: report-format.md

## Executive Summary

- **Root cause identified**: which-key calls non-existent functions in `commands.email` module
- The `<leader>me` prefix mappings try to call `commands.reply`, `commands.delete_selected`, etc. but the email.lua module only exports `setup(registry)`
- Actual implementations exist in `ui.main` module with different function names
- Fix requires updating which-key mappings to call correct module and function names

## Context and Scope

Task 56 moved single-letter keys (d, a, r, etc.) from buffer-local mappings to a which-key prefix (`<leader>me`). However, the which-key configuration references functions that don't exist in the expected module, causing all email actions under `<leader>me` to fail silently.

## Findings

### 1. Current Which-Key Configuration (Broken)

File: `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua`
Lines: 566-600

```lua
-- These mappings call functions that don't exist
{ "<leader>mer", function()
  local ok, commands = pcall(require, 'neotex.plugins.tools.himalaya.commands.email')
  if ok and commands.reply then commands.reply() end  -- commands.reply is nil!
end, desc = "reply", icon = "", cond = is_himalaya_buffer },

{ "<leader>med", function()
  local ok, commands = pcall(require, 'neotex.plugins.tools.himalaya.commands.email')
  if ok and commands.delete_selected then commands.delete_selected() end  -- nil!
end, desc = "delete", icon = "", cond = is_himalaya_buffer },
```

### 2. The email.lua Module Structure

File: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/commands/email.lua`

The module only exports:
```lua
local M = {}
function M.setup(registry)
  -- Registers vim commands like :HimalayaWrite, :HimalayaSend, etc.
  -- Does NOT export callable functions
end
return M
```

This means:
- `commands.reply` = nil
- `commands.delete_selected` = nil
- `commands.archive_selected` = nil
- All which-key mappings fail silently

### 3. Actual Implementation Location

File: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/main.lua`

The actual functions exist here with these names:

| Which-key expects | Actual function in ui.main |
|-------------------|---------------------------|
| `commands.reply` | `M.reply_current_email()` |
| `commands.reply_all` | `M.reply_all_current_email()` |
| `commands.forward` | `M.forward_current_email()` |
| `commands.delete_selected` | `M.delete_selected_emails()` |
| `commands.archive_selected` | `M.archive_selected_emails()` |
| `commands.move_selected` | `M.move_selected_emails()` |
| `commands.compose` | (via email_composer.compose) |
| `commands.search` | (via search module) |

### 4. Buffer-Local Keymaps (Task 56)

File: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/config/ui.lua`
Function: `M.setup_email_list_keymaps(bufnr)`

Current buffer-local keymaps only include:
- `<CR>` - Enter/3-state preview model
- `<Esc>` - Exit preview mode
- `q` - Close sidebar
- `<Space>` - Toggle selection
- `n` - Select email
- `p` - Deselect email
- `<C-d>` - Next page
- `<C-u>` - Previous page
- `F` - Refresh
- `gH` - Show full help
- `?` - Show help hint (points to `<leader>me`)

**Removed per Task 56**: d, a, r, R, f, m, c, / (moved to which-key prefix)

### 5. The `?` Key Behavior (Task 60)

The `?` key currently shows a notification hint:
```lua
keymap('n', '?', function()
  local notify = require('neotex.util.notifications')
  notify.himalaya('Email Actions under <leader>me: d=delete a=archive r=reply R=reply-all | Press gH for full keybindings', notify.categories.STATUS)
end, vim.tbl_extend('force', opts, { desc = 'Show help hint' }))
```

This works correctly - it displays the help message pointing users to `<leader>me`.

### 6. The `gH` Key (Context Help)

File: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/folder_help.lua`

The `gH` mapping correctly shows a floating window with context-aware keybinding help. This works properly.

## Recommendations

### Option A: Fix which-key to call correct functions (Recommended)

Update the which-key mappings to call the correct module and functions:

```lua
{ "<leader>mer", function()
  local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
  if ok and main.reply_current_email then main.reply_current_email() end
end, desc = "reply", icon = "", cond = is_himalaya_buffer },

{ "<leader>meR", function()
  local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
  if ok and main.reply_all_current_email then main.reply_all_current_email() end
end, desc = "reply all", icon = "", cond = is_himalaya_buffer },

{ "<leader>mef", function()
  local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
  if ok and main.forward_current_email then main.forward_current_email() end
end, desc = "forward", icon = "", cond = is_himalaya_buffer },

{ "<leader>med", function()
  local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
  if ok and main.delete_selected_emails then main.delete_selected_emails() end
end, desc = "delete", icon = "", cond = is_himalaya_buffer },

{ "<leader>mem", function()
  local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
  if ok and main.move_selected_emails then main.move_selected_emails() end
end, desc = "move", icon = "", cond = is_himalaya_buffer },

{ "<leader>mea", function()
  local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
  if ok and main.archive_selected_emails then main.archive_selected_emails() end
end, desc = "archive", icon = "", cond = is_himalaya_buffer },

{ "<leader>men", function()
  local ok, composer = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_composer')
  if ok and composer.compose then composer.compose({}) end
end, desc = "new email", icon = "", cond = is_himalaya_buffer },

{ "<leader>me/", function()
  local ok, search = pcall(require, 'neotex.plugins.tools.himalaya.data.search')
  if ok and search.show_search_ui then search.show_search_ui() end
end, desc = "search", icon = "", cond = is_himalaya_buffer },
```

### Option B: Add exports to commands/email.lua (Alternative)

Could add wrapper functions to `commands/email.lua`:

```lua
function M.reply()
  require('neotex.plugins.tools.himalaya.ui.main').reply_current_email()
end

function M.delete_selected()
  require('neotex.plugins.tools.himalaya.ui.main').delete_selected_emails()
end
-- etc.
```

This approach maintains the current which-key structure but adds indirection.

### Recommendation

**Option A is preferred** because:
1. Direct calls are cleaner and faster
2. No need to modify the email.lua module structure
3. Makes the dependency explicit in which-key config
4. Follows the pattern already established in the codebase

## Decisions

1. Single-letter keys (d, a, r) will remain removed from email list buffer - users access via `<leader>me` prefix (per Task 56 design)
2. The `?` key shows a helpful notification pointing to `<leader>me` (correctly implemented)
3. The `gH` key shows full contextual help (correctly implemented)
4. Fix focuses on making `<leader>me` submenu functional

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Breaking change to key behavior | Users already adapted to `<leader>me` from Task 56 |
| Function names might change | Use pcall pattern for safe calling |
| Selection state issues | delete_selected and archive_selected already handle empty selection |

## Appendix

### Search Queries Used
- Local file search for himalaya configuration
- Grep for function definitions in commands/email.lua and ui/main.lua
- Pattern search for which-key mappings

### References
- Task 56: Keymap reorganization (moved single-letter keys to `<leader>me`)
- Task 60: show_help function implementation
- `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua` lines 526-600
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/commands/email.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/main.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/config/ui.lua`

### Files to Modify
1. `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua` - Update `<leader>me` mappings to call correct functions
