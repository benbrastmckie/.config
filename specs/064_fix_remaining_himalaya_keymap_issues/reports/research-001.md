# Research Report: Task #64

**Task**: 64 - Fix remaining himalaya keymap issues
**Started**: 2026-02-11T12:00:00Z
**Completed**: 2026-02-11T12:45:00Z
**Effort**: Low-Medium (2-4 hours)
**Dependencies**: Task 63 (keymap errors and help menu)
**Sources/Inputs**: main.lua, search.lua, email_composer.lua, config/ui.lua, folder_help.lua, which-key.lua
**Artifacts**: This research report
**Standards**: report-format.md

## Executive Summary

- Issue 1 (move 'm' error): The `move_current_email()` function at line 1502 calls `folder:lower()` without validating the folder is a string, causing nil error when an invalid folder is in the list
- Issue 2 (d/r/R errors): These errors are NOT bugs - they are correct behavior when cursor is not on an email line (already documented in task 63)
- Issue 3 (search '/' error): The keymap at line 781 in search.lua incorrectly passes `buffer = buf` instead of `{ buffer = buf }` to `vim.api.nvim_buf_set_keymap`
- Issue 4 (compose send): The `c` key works correctly; sending is done via `<C-s>` in the compose buffer or via `<leader>mce` command
- Issue 5 (help menu): The help menu in folder_help.lua correctly shows single-letter keymaps now, but the footer in email_list.lua shows `<leader>me:email actions` which is misleading since `<Space>` is used for selection toggle

## Context & Scope

Task 63 fixed keymap errors and updated the help menu. However, several additional issues remain that need investigation.

## Findings

### Issue 1: Move Command Error ('m' key)

**Location**: `ui/main.lua` line 1498-1517

**Root Cause**: The `format_item` function in `vim.ui.select` attempts to call `folder:lower()` without validating that `folder` is a string. If the folders list contains a nil value, this causes the error.

**Code Analysis**:
```lua
-- Line 1498-1517
vim.ui.select(available_folders, {
  prompt = ' Move email to folder:',
  format_item = function(folder)
    -- Add icon for special folders
    if folder:lower():match('inbox') then  -- Line 1502 - CRASHES if folder is nil
      return '[inbox] ' .. folder
```

**Evidence**: The error "attempt to call method 'lower' (a nil value)" indicates `folder` is nil.

**Cause**: The `utils.get_folders()` function may return a list with nil entries, or the folder filtering logic at lines 1489-1495 may leave nil entries:

```lua
-- Line 1488-1495
local available_folders = {}
for _, folder in ipairs(folders) do
  if folder ~= current_folder then
    table.insert(available_folders, folder)
  end
end
```

If `folders` contains nil values, they pass the `~= current_folder` check (nil is not equal to any string) and get inserted into `available_folders`.

**Fix Required**: Add nil check before calling `:lower()`:
```lua
format_item = function(folder)
  if not folder or folder == "" then
    return folder or "(empty)"
  end
  if folder:lower():match('inbox') then
```

### Issue 2: Delete/Reply/Reply-All Errors ('d', 'r', 'R')

**Status**: NOT A BUG

**Analysis**: Task 63 research confirmed these are correct behaviors. The keymaps work correctly when the cursor is positioned on an email line. The errors appear when:
- Cursor is on header lines (lines 1-5)
- Cursor is on scheduled email section
- Cursor is on footer line

**Verification**: The error messages "No email to reply to", "No email to delete" etc. are the intended UX for cursor-position-aware actions.

**Action**: Potentially improve error messages to be more instructive (e.g., "Position cursor on an email line first").

### Issue 3: Search Error ('/' key)

**Location**: `data/search.lua` line 781

**Root Cause**: Invalid keymap syntax in `vim.api.nvim_buf_set_keymap()` call.

**Code Analysis**:
```lua
-- Line 781
vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':close<CR>', { buffer = buf })
```

**Problem**: The fourth argument to `nvim_buf_set_keymap` should be the rhs (string), and the fifth should be an options table. The `{ buffer = buf }` is incorrect - for `nvim_buf_set_keymap`, you don't pass `buffer` because the buffer is already the first argument.

**Correct Syntax**:
```lua
vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':close<CR>', { silent = true, noremap = true })
```

OR use `vim.keymap.set` which does accept `{ buffer = buf }`:
```lua
vim.keymap.set('n', '<Esc>', ':close<CR>', { buffer = buf, silent = true })
```

**Note**: The actual search functionality uses this incorrect pattern in multiple places (lines 763-785).

### Issue 4: Compose Send Missing Mapping

**Status**: NOT MISSING - Working as Designed

**Analysis**: The compose flow works as follows:

1. Press `c` in email list to compose new email
2. A draft buffer opens with filetype `mail`
3. Compose keymaps are set via `email_composer.setup_compose_keymaps(buf)`
4. Send is available via:
   - `<C-s>` (Ctrl+S) - set in `config/ui.lua:395-400`
   - `<leader>mce` - set in `which-key.lua:556` (requires compose buffer)
   - `:HimalayaSend` command - defined in `commands/email.lua:51-67`

**The Send Workflow**:
```lua
-- config/ui.lua line 395-400
keymap('n', '<C-s>', function()
  local ok, composer = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_composer')
  if ok and composer.send then
    composer.send()
  end
end, vim.tbl_extend('force', opts, { desc = 'Send email' }))
```

**Note**: The `composer.send()` function doesn't exist directly. The actual function is `composer.send_email(buf)`. This is a bug in the keymap handler - it calls a non-existent function.

**Actual Send Function** (`email_composer.lua:208-309`):
```lua
function M.send_email(buf)
  -- Stops autosave, saves draft, parses headers
  -- Schedules email via scheduler with 60s delay
  -- Closes compose buffer
end
```

**Fix Required**: The keymap should call `email_composer.send_email(vim.api.nvim_get_current_buf())` instead of `composer.send()`.

### Issue 5: Help Menu Accuracy

**Analysis**: The help menu in `folder_help.lua` was updated in task 63 to show single-letter keymaps. Reviewing the current content:

```lua
-- folder_help.lua lines 68-82
local base_actions = {
  "Quick Actions (on email line):",
  "  r         - Reply",
  "  R         - Reply all",
  "  f         - Forward",
  "  d         - Delete",
  "  a         - Archive",
  "  m         - Move",
  "  c         - Compose new",
  "  /         - Search",
  "",
  "Mail Menu (<leader>me):",
  "  Also available via which-key",
  ""
}
```

This is CORRECT. The help menu accurately shows the single-letter keymaps.

**However**, the email_list.lua footer at line 1063 says:
```lua
table.insert(lines, '<C-d>/<C-u>:page | r/R/f:reply | d/a/m:actions | c:compose | gH:help')
```

This footer is also accurate.

**Potential Confusion**: The `<Space>` key is used for selection toggle in the email list, but users might expect `<Space>` to work like Leader in normal buffers. The help menu should clarify that `<Space>` toggles selection in the email list.

The help menu already has a Selection section showing `<Space>` for toggle, which is correct.

## Recommendations

### Fix 1: Move Command Nil Check (HIGH PRIORITY)

In `ui/main.lua` around line 1502, add nil validation:

```lua
format_item = function(folder)
  if not folder or type(folder) ~= "string" then
    return folder and tostring(folder) or "(invalid)"
  end
  if folder:lower():match('inbox') then
    -- rest of function
```

### Fix 2: Search Keymap Syntax (MEDIUM PRIORITY)

In `data/search.lua`, change lines 763-785 to use `vim.keymap.set` with proper options:

```lua
-- Replace
vim.api.nvim_buf_set_keymap(buf, 'n', '<CR>', '', { callback = ... })
vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':close<CR>', { buffer = buf })

-- With
local opts = { buffer = buf, silent = true, noremap = true }
vim.keymap.set('n', '<CR>', function() ... end, opts)
vim.keymap.set('n', '<Esc>', ':close<CR>', opts)
```

### Fix 3: Compose Send Keymap (MEDIUM PRIORITY)

In `config/ui.lua` line 395-400, fix the send function call:

```lua
keymap('n', '<C-s>', function()
  local ok, composer = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_composer')
  local buf = vim.api.nvim_get_current_buf()
  if ok and composer.send_email then
    composer.send_email(buf)
  end
end, vim.tbl_extend('force', opts, { desc = 'Send email' }))
```

### Fix 4: Error Message Improvement (LOW PRIORITY)

Improve error messages in action functions to guide users:

```lua
-- In reply_current_email(), delete_current_email(), etc.
if not email_id then
  notify.himalaya('Position cursor on an email line (below header)', notify.categories.STATUS)
  return
end
```

### Fix 5: Help Menu Clarity (OPTIONAL)

Add a note about `<Space>` being different from Leader:

```lua
"Selection:",
"  <Space>   - Toggle selection (not <leader>)",
```

## Summary of Bugs Found

| Issue | Severity | Type | File | Line | Status |
|-------|----------|------|------|------|--------|
| Move nil error | High | Bug | ui/main.lua | 1502 | Fix Required |
| Search keymap | Medium | Bug | data/search.lua | 781 | Fix Required |
| Send function call | Medium | Bug | config/ui.lua | 398 | Fix Required |
| d/r/R errors | N/A | Not Bug | - | - | Working as designed |
| Help menu | N/A | Not Bug | - | - | Accurate |

## Implementation Approach

A single refactoring pass should address all issues:

1. **Add defensive nil checks** in main.lua for folder operations
2. **Fix search.lua keymap syntax** using `vim.keymap.set` API
3. **Fix compose send handler** to call correct function name
4. **Improve error messages** for cursor-position-aware actions
5. **Run verification tests** using `:checkhealth` and manual testing

## Appendix

### Files Analyzed

- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/main.lua` - Main UI module (lines 1454-1532)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/data/search.lua` - Search functionality (lines 717-913)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/email_composer.lua` - Compose functionality (lines 1-633)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/config/ui.lua` - Keymap definitions (lines 1-532)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/folder_help.lua` - Help menu (lines 1-209)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/email_list.lua` - Email list display (lines 1-2397)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua` - Global keymaps (himalaya section)

### Key Functions

- `M.move_current_email()` - Move email to folder (line 1454)
- `M.show_search_ui()` - Show search interface (search.lua:717)
- `M.send_email(buf)` - Send composed email (email_composer.lua:208)
- `M.setup_compose_keymaps(buf)` - Setup compose buffer keymaps (ui.lua:391)
