# Research Report: Task #62 - Fix Broken Himalaya Commands

**Task**: 62 - himalaya_broken_commands_fix
**Started**: 2026-02-10T00:00:00Z
**Completed**: 2026-02-10T00:30:00Z
**Effort**: 1-2 hours
**Dependencies**: None
**Sources/Inputs**: Local codebase analysis
**Artifacts**: specs/062_himalaya_broken_commands_fix/reports/research-002.md
**Standards**: report-format.md

## Executive Summary

- Single-letter action keys (d, a, r, R, f, m, c, /) were intentionally removed from `setup_email_list_keymaps()` per task 56, redirecting actions to `<leader>me` which-key menu
- The `<leader>me` prefix CANNOT work in himalaya buffers because `<Space>` is used for toggle selection, creating a conflict
- Solution: Restore single-letter buffer-local keymaps in `setup_email_list_keymaps()` function in `config/ui.lua`
- All required functions exist in `ui/main.lua` and are ready to be mapped

## Context & Scope

The user reports that email action keys (d, a, ?, etc.) are broken in the himalaya email list buffer. Investigation reveals this is by design per task 56 which removed single-letter keys in favor of which-key access via `<leader>me`. However, this approach is fundamentally broken because:

1. `<Space>` is the leader key
2. `<Space>` is also the toggle selection key in the email list buffer
3. When pressing `<Space>` in the email list, it triggers toggle_selection, not which-key

## Findings

### Current Keymaps in Email List Buffer (himalaya-list)

From `lua/neotex/plugins/tools/himalaya/config/ui.lua` lines 169-268:

| Key | Function | Status |
|-----|----------|--------|
| `<Esc>` | Hide preview / regress state | Working |
| `<CR>` | Open email or draft (3-state model) | Working |
| `q` | Close sidebar | Working |
| `<Space>` | Toggle email selection | Working |
| `n` | Select email | Working |
| `p` | Deselect email | Working |
| `<C-d>` | Next page | Working |
| `<C-u>` | Previous page | Working |
| `F` | Refresh email list | Working |
| `gH` | Show context help (floating window) | Working |
| `?` | Show which-key hint (notification) | Broken (refers to `<leader>me` which doesn't work) |

### Missing Single-Letter Action Keys

These keys need to be added back to `setup_email_list_keymaps()`:

| Key | Action | Function to Call |
|-----|--------|-----------------|
| `d` | Delete selected/current emails | `main.delete_selected_emails()` or `main.delete_current_email()` |
| `a` | Archive selected/current emails | `main.archive_selected_emails()` or `main.archive_current_email()` |
| `r` | Reply to current email | `main.reply_current_email()` |
| `R` | Reply all to current email | `main.reply_all_current_email()` |
| `f` | Forward current email | `main.forward_current_email()` |
| `m` | Move selected/current emails | `main.move_selected_emails()` or `main.move_current_email()` |
| `c` | Compose new email | `email_composer.compose()` |
| `/` | Search emails | `search.show_search_ui()` or `email_list.search_emails()` |

### Function Locations (All Verified to Exist)

From `lua/neotex/plugins/tools/himalaya/ui/main.lua`:

- `M.delete_current_email()` - Line 641 (single email)
- `M.delete_selected_emails()` - Line 1218 (batch)
- `M.archive_current_email()` - Line 841 (single email)
- `M.archive_selected_emails()` - Line 1297 (batch)
- `M.reply_current_email()` - Line 368
- `M.reply_all_current_email()` - Line 391
- `M.forward_current_email()` - Line 431
- `M.move_current_email()` - Line 1455 (single email)
- `M.move_selected_emails()` - Line 1535 (batch)
- `M.compose_email(to_address)` - Line 86

From `lua/neotex/plugins/tools/himalaya/data/search.lua`:
- `M.show_search_ui()` - Line 717

### Conflict Analysis

| Key | Existing Use | Conflict Resolution |
|-----|--------------|---------------------|
| `q` | Close sidebar | Keep as-is |
| `n` | Select email | Keep as-is (NOT search next) |
| `p` | Deselect email | Keep as-is |
| `<Space>` | Toggle selection | Keep as-is (MUST keep!) |
| `<CR>` | Enter/preview | Keep as-is |
| `?` | Help hint | Change to show folder_help (gH behavior) |
| `d` | None | Add delete |
| `a` | None (sidebar has account switch) | Add archive (different buffer) |
| `r` | None | Add reply |
| `R` | None | Add reply all |
| `f` | None | Add forward |
| `m` | None | Add move |
| `c` | None | Add compose |
| `/` | None | Add search |

### Selection Mode Awareness

The delete, archive, and move functions already handle both selection modes:

1. If emails are selected (selection mode active), they use batch operations on all selected emails
2. If no selection, they operate on the current email under cursor

This means the keymaps can call the `*_selected_*` functions which internally check selection state and fall back to current email operations.

### which-key `<leader>me` Section

Located in `lua/neotex/plugins/editor/which-key.lua` lines 560-600:

The `<leader>me` group calls functions from `neotex.plugins.tools.himalaya.commands.email` module. These functions DO NOT exist - the module at `commands/email.lua` only contains Vim command setup, not the functions being called.

**Recommendation**: The `<leader>me` section should be:
1. Kept for non-himalaya buffers where users might want email actions
2. Modified to call the correct functions from `ui/main.lua`
3. Or disabled entirely for himalaya buffers since single-letter keys are more efficient

## Implementation Code Changes

### Change 1: Add keymaps to `setup_email_list_keymaps()` in config/ui.lua

Add the following keymaps after line 267 (before the closing `end` of the function):

```lua
  -- Email action keymaps (restored for single-key access)
  -- Delete emails (selection-aware)
  keymap('n', 'd', function()
    local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
    if ok then
      local state = require('neotex.plugins.tools.himalaya.core.state')
      if state.is_selection_mode() and #state.get_selected_emails() > 0 then
        main.delete_selected_emails()
      else
        main.delete_current_email()
      end
    end
  end, vim.tbl_extend('force', opts, { desc = 'Delete email(s)' }))

  -- Archive emails (selection-aware)
  keymap('n', 'a', function()
    local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
    if ok then
      local state = require('neotex.plugins.tools.himalaya.core.state')
      if state.is_selection_mode() and #state.get_selected_emails() > 0 then
        main.archive_selected_emails()
      else
        main.archive_current_email()
      end
    end
  end, vim.tbl_extend('force', opts, { desc = 'Archive email(s)' }))

  -- Reply to current email
  keymap('n', 'r', function()
    local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
    if ok and main.reply_current_email then
      main.reply_current_email()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Reply' }))

  -- Reply all to current email
  keymap('n', 'R', function()
    local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
    if ok and main.reply_all_current_email then
      main.reply_all_current_email()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Reply all' }))

  -- Forward current email
  keymap('n', 'f', function()
    local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
    if ok and main.forward_current_email then
      main.forward_current_email()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Forward' }))

  -- Move emails (selection-aware)
  keymap('n', 'm', function()
    local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
    if ok then
      local state = require('neotex.plugins.tools.himalaya.core.state')
      if state.is_selection_mode() and #state.get_selected_emails() > 0 then
        main.move_selected_emails()
      else
        main.move_current_email()
      end
    end
  end, vim.tbl_extend('force', opts, { desc = 'Move email(s)' }))

  -- Compose new email
  keymap('n', 'c', function()
    local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
    if ok and main.compose_email then
      main.compose_email()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Compose new email' }))

  -- Search emails
  keymap('n', '/', function()
    local ok, search = pcall(require, 'neotex.plugins.tools.himalaya.data.search')
    if ok and search.show_search_ui then
      search.show_search_ui()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Search emails' }))
```

### Change 2: Update the `?` keymap

Replace the current `?` mapping (lines 264-267) with a more useful help display:

```lua
  -- Show keybinding help
  keymap('n', '?', function()
    local ok, folder_help = pcall(require, 'neotex.plugins.tools.himalaya.ui.folder_help')
    if ok and folder_help.show_folder_help then
      folder_help.show_folder_help()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Show keybindings help' }))
```

### Change 3: Update get_keybinding table

Update the `keybindings` table in `M.get_keybinding()` function (around line 403) to include the new keys:

```lua
    ['himalaya-list'] = {
      open = '<CR>',
      toggle_select = '<Space>',
      select = 'n',
      deselect = 'p',
      next_page = '<C-d>',
      prev_page = '<C-u>',
      refresh = 'F',
      close = 'q',
      help = '?',
      -- Action keys (restored)
      delete = 'd',
      archive = 'a',
      reply = 'r',
      reply_all = 'R',
      forward = 'f',
      move = 'm',
      compose = 'c',
      search = '/'
    },
```

### Change 4: (Optional) Fix which-key section

The `<leader>me` section in which-key.lua calls non-existent functions. Options:

**Option A**: Keep it but fix the function calls to use ui/main.lua:
```lua
{ "<leader>mer", function()
  local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
  if ok and main.reply_current_email then main.reply_current_email() end
end, desc = "reply", icon = "...", cond = is_himalaya_buffer },
```

**Option B**: Remove the section entirely since single-letter keys are now available.

**Recommendation**: Keep but fix it for users who prefer which-key discovery.

## Decisions

1. Restore single-letter keymaps as buffer-local mappings in the himalaya-list filetype
2. Use selection-aware functions that check `state.is_selection_mode()` before choosing batch vs single operations
3. Keep the `?` key but change behavior to show the full help window (`gH` behavior) instead of a notification
4. Keep the `<leader>me` which-key section but fix it to call the correct functions

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Key conflicts with vim motions | All chosen keys (d, a, r, R, f, m, c, /) don't conflict with standard vim motions in a non-editable buffer |
| `a` conflicts with sidebar account switch | Different filetypes (himalaya-list vs himalaya-sidebar) so no conflict |
| Breaking existing muscle memory | These keys are being restored, not changed |

## Appendix

### Files Modified

1. `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/config/ui.lua`
   - Add keymaps to `setup_email_list_keymaps()` function
   - Update `get_keybinding()` table

2. `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua` (optional)
   - Fix `<leader>me` function calls or remove section

### Verification Commands

```bash
# Test that keymaps are set correctly
nvim --headless -c "lua require('neotex.plugins.tools.himalaya').setup({})" -c "set ft=himalaya-list" -c "lua print(vim.inspect(vim.api.nvim_buf_get_keymap(0, 'n')))" -c "q"
```
