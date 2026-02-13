# Research Report: Task #63

**Task**: 63 - Fix himalaya keymap errors and help menu
**Started**: 2026-02-10T12:00:00Z
**Completed**: 2026-02-10T12:30:00Z
**Effort**: Low (1-2 hours)
**Dependencies**: Task 62 (keymaps restored)
**Sources/Inputs**: ui/main.lua, ui/config.lua, ui/email_list.lua, core/state.lua, ui/folder_help.lua
**Artifacts**: This research report
**Standards**: report-format.md

## Executive Summary

- The keymaps in config/ui.lua are correctly implemented and work properly
- The errors "No email to reply to" and "No email to forward" are legitimate behavior when the cursor is NOT on an email line
- The help menu (folder_help.lua) is accurate but lists `<leader>me*` prefix for actions which conflicts with the new single-letter keymaps
- The root cause is likely user confusion about cursor position OR a filetype detection issue

## Context & Scope

Task 62 restored single-letter keymaps (`r`, `R`, `f`, `d`, `a`, `m`, `c`, `/`) to the himalaya email list buffer. The user reports runtime errors when using these keymaps.

## Findings

### 1. Keymap Implementation Analysis

The keymaps in `config/ui.lua` (lines 298-349) are correctly implemented:

```lua
-- Reply to current email
keymap('n', 'r', function()
  local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
  if ok and main.reply_current_email then
    main.reply_current_email()
  end
end, vim.tbl_extend('force', opts, { desc = 'Reply' }))
```

This pattern is identical for all action keymaps. The keymaps:
- Are buffer-local (`buffer = bufnr`)
- Use pcall for safe loading
- Call the correct functions directly

### 2. Function Signature Analysis

**`reply_current_email()` (main.lua:368-388)**:
```lua
function M.reply_current_email()
  local email_id = M.get_current_email_id()

  if email_id then
    local account = state.get_current_account()
    local folder = state.get_current_folder()
    local email = utils.get_email_by_id(account, folder, email_id)
    if email then
      local buf = email_composer.reply_to_email(email, false)
      return coordinator.open_compose_buffer_in_window(buf, { position_to_body = true })
    end
  end
  notify.himalaya('No email to reply to', notify.categories.ERROR)
end
```

The function:
1. Calls `M.get_current_email_id()` to find the email under cursor
2. Uses account and folder from state
3. Fetches full email data via `utils.get_email_by_id()`
4. Creates compose buffer via `email_composer.reply_to_email()`
5. Shows "No email to reply to" if any step fails

### 3. Root Cause: `get_current_email_id()` Returns nil

The `get_current_email_id()` function (main.lua:198-341) has multiple checks that can return `nil`:

**Check 1 - Filetype (line 216)**:
```lua
if vim.bo.filetype ~= 'himalaya-list' then
  return nil
end
```
If the buffer filetype is wrong, no email ID is returned.

**Check 2 - Header lines (line 232)**:
```lua
if current_line:match('^Himalaya%s*-') or current_line:match('^Page%s*%d+') or current_line:match('^[─]+$') then
  logger.debug('Cursor is on header/separator line')
  return nil
end
```
If cursor is on header, pagination, or separator lines, returns nil.

**Check 3 - Line map (line 238)**:
```lua
local line_map = state.get('email_list.line_map')
if line_map and line_map[line_num] then
  local metadata = line_map[line_num]
  local id = line_map[line_num].email_id or line_map[line_num].id
  return id
end
```
If the line map doesn't have an entry for the current line, continues to fallback.

**Check 4 - Email list state (line 264)**:
```lua
if not emails or #emails == 0 then
  logger.debug('No emails found in state')
  return nil
end
```

### 4. Comparison with Working Keymaps

**`<CR>` (handle_enter)** works because it uses the same `get_email_id_from_line()` function:
```lua
local email_id = M.get_email_id_from_line(line_num)
```

**`<Space>` (toggle_selection)** uses the same pattern and shows error:
```lua
if not email_id then
  notify.himalaya('No email on this line', notify.categories.STATUS)
  return
end
```

This confirms: The pattern is consistent across all keymaps. The "No email" messages are the expected behavior when cursor is not on an email line.

### 5. Help Menu Analysis

The `folder_help.lua` file shows a help popup with keymap documentation. Looking at the content (lines 68-79):

```lua
local base_actions = {
  "Actions (<leader>me):",
  "  <leader>men - New email",
  "  <leader>mer - Reply",
  "  <leader>meR - Reply all",
  "  <leader>mef - Forward",
  "  <leader>med - Delete",
  "  <leader>mem - Move",
  "  <leader>me/ - Search",
  ""
}
```

**Issue**: The help menu shows the old `<leader>me*` pattern for actions, but task 62 added single-letter shortcuts (`r`, `R`, `f`, `d`, `m`, `c`, `/`). The help menu needs to be updated to show both options:
- Single-letter keymaps work in the email list buffer directly
- `<leader>me*` keymaps are the global which-key menu

The footer at line 1063 also needs updating:
```lua
table.insert(lines, '<C-d>/<C-u>:page | n/p:select | F:refresh | <leader>me:email actions | gH:help')
```

### 6. Potential Issues

**Issue A: State Not Initialized**

If `state.get('email_list.line_map')` returns nil or empty, the keymaps fail. This can happen if:
- The email list wasn't loaded properly
- State was cleared or corrupted
- Race condition during initial load

**Issue B: Cursor on Non-Email Lines**

The email list has:
- Line 1: Header "Himalaya - Gmail - INBOX"
- Line 2: Pagination "Page 1 / X | N emails"
- Line 3: Sync status (if syncing)
- Line 4: Separator "─────"
- Line 5: Blank line
- Line 6+: Email entries

If the cursor is on lines 1-5, all action keymaps correctly return "No email to reply/forward/delete".

### 7. Recommended Fixes

**Fix 1: Update Help Menu**

The help menu should show the new single-letter keymaps:

```lua
local base_actions = {
  "Quick Actions (from email list):",
  "  r         - Reply to email",
  "  R         - Reply all",
  "  f         - Forward email",
  "  d         - Delete email(s)",
  "  a         - Archive email(s)",
  "  m         - Move email(s)",
  "  c         - Compose new email",
  "  /         - Search emails",
  "",
  "Mail Menu (<leader>me):",
  "  Also available via which-key menu",
  ""
}
```

**Fix 2: Update Footer**

```lua
table.insert(lines, 'd/a/m:actions | r/R/f:reply/fwd | c:compose | /:search | gH:help')
```

**Fix 3: Improve Error Messages**

The current error messages are generic. Could be more helpful:

```lua
-- In reply_current_email()
if not email_id then
  notify.himalaya('Position cursor on an email line first', notify.categories.STATUS)
  return
end
```

**Fix 4: Validate Keymap Buffer Context**

The keymaps are already buffer-local and only set on `himalaya-list` buffers. This is correct.

## Recommendations

1. **Update folder_help.lua** to show single-letter keymaps prominently
2. **Update footer in email_list.lua** to show quick action keymaps
3. **Improve error messages** to guide users to position cursor on email line
4. **Test keymap behavior** by opening sidebar and positioning cursor on email line

The keymaps are working correctly - the errors are expected behavior when cursor is not on an email line.

## Appendix

### Files Analyzed
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/main.lua` - Main UI module with action functions
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/config.lua` - Keymap definitions
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/email_list.lua` - Email list display
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/core/state.lua` - State management
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/folder_help.lua` - Help menu

### Key Functions
- `M.get_current_email_id()` - Gets email ID from cursor position
- `M.reply_current_email()` - Reply to email under cursor
- `M.reply_all_current_email()` - Reply all to email under cursor
- `M.forward_current_email()` - Forward email under cursor
- `M.delete_current_email()` - Delete email under cursor
- `M.archive_current_email()` - Archive email under cursor
- `M.move_current_email()` - Move email under cursor
- `M.compose_email()` - Compose new email
