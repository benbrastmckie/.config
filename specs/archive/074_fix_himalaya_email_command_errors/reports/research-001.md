# Research Report: Task #74

**Task**: 74 - Fix Multiple Himalaya Email Command Errors
**Started**: 2026-02-12T00:00:00Z
**Completed**: 2026-02-12T00:30:00Z
**Effort**: 2-3 hours
**Dependencies**: None
**Sources/Inputs**: email.lua, email_composer.lua, main.lua, utils.lua, drafts.lua, email_list.lua
**Artifacts**: - specs/074_fix_himalaya_email_command_errors/reports/research-074.md
**Standards**: report-format.md, neovim-lua.md

## Executive Summary

- **Error 1**: `is_composing` function does not exist in `email_composer.lua` - calls to `composer.is_composing()` fail with nil error
- **Error 2**: `utils.get_folders()` returns tables `{name, path}` but code in `main.lua:do_archive_current_email()` treats them as strings
- **Error 3**: Reply/forward "No email" error likely caused by `line_map` or `emails` not being populated in state when keymaps are triggered

## Context and Scope

This research addresses three related errors in the Himalaya email plugin:

1. `<leader>me` in compose buffer fails with "attempt to call field 'is_composing' (a nil value)" at email.lua:57
2. 'a' (archive) in sidebar fails with "attempt to call method 'lower' (a nil value)" at main.lua:887
3. 'r', 'R', 'f' (reply/forward) fail with "No email to reply to" / "No email to forward" despite having email selected

## Findings

### Error 1: is_composing Nil Error (email.lua:57)

**Root Cause**: The function `is_composing()` does not exist in `email_composer.lua`.

**Location**: `commands/email.lua` lines 57, 74, 91, 122, 384

**Code Pattern** (broken):
```lua
local composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
if not composer.is_composing() then  -- ERROR: is_composing is nil
  notify.himalaya('No email is being composed', notify.categories.ERROR)
  return
end
```

**Available Function in email_composer.lua**:
```lua
-- Line 634-636
function M.is_compose_buffer(buf)
  return draft_manager.is_draft(buf)
end
```

**Fix Required**: Replace all `composer.is_composing()` calls with `composer.is_compose_buffer(vim.api.nvim_get_current_buf())`

**Affected Commands**:
- `HimalayaSend` (line 57)
- `HimalayaSaveDraft` (line 74)
- `HimalayaDiscard` (line 91)
- `HimalayaDraftSave` (line 122)
- `HimalayaSchedule` (line 384)

### Error 2: lower Nil Error (main.lua:887)

**Root Cause**: `utils.get_folders()` returns an array of tables with structure `{name = "...", path = "/"}`, but the code at line 887 treats `folder` as a string.

**Location**: `ui/main.lua` lines 879-893 in `do_archive_current_email()`

**Code Pattern** (broken):
```lua
local folders = utils.get_folders(state.get_current_account())
-- ...
for _, folder in ipairs(folders) do
  for _, archive_name in ipairs(archive_folders) do
    if folder == archive_name or folder:lower() == archive_name:lower() then
      -- folder is a TABLE, not a string!
```

**Evidence from utils.lua**:
```lua
-- utils.lua:53-92
function M.get_folders(account)
  -- Returns format:
  return {
    { name = "INBOX", path = "/" },
    { name = "Sent", path = "/" },
    -- ...
  }
end
```

**Fix Required**: Extract the `name` field from the folder table:
```lua
for _, folder in ipairs(folders) do
  local folder_name = type(folder) == "table" and folder.name or folder
  for _, archive_name in ipairs(archive_folders) do
    if folder_name == archive_name or folder_name:lower() == archive_name:lower() then
      archive_folder = folder_name
```

**Same Pattern Exists In**:
- `do_spam_current_email()` (lines 988-1004)
- Both batch operations `archive_selected_emails()` (lines 1326-1335) and `spam_selected_emails()` (lines 1401-1415)

### Error 3: Reply/Forward "No Email" Error

**Root Cause**: The `get_current_email_id()` function at lines 197-341 in `main.lua` returns nil when it cannot find the email.

**Analysis of get_current_email_id()**:
1. First checks `state.get('preview_email_id')` - typically nil
2. Then checks if filetype is `himalaya-email` (preview window)
3. Then checks if filetype is `himalaya-list` (sidebar)
4. Returns nil if not in sidebar
5. Uses `state.get('email_list.line_map')` to find email metadata by line number
6. Falls back to `state.get('email_list.emails')` with calculated index

**Potential Failure Points**:
1. **Buffer filetype not set**: If the sidebar buffer doesn't have `filetype = 'himalaya-list'`, function returns nil at line 216
2. **Line map not populated**: If `email_list.line_map` is empty or doesn't have the current line, no email found
3. **Emails not stored in state**: If `email_list.emails` is nil or empty after folder switch
4. **Line calculation mismatch**: The fallback calculation uses `email_start_line` which might not match actual email positions

**Key Code Paths**:
```lua
-- Line 237-252: Primary lookup via line_map
local line_map = state.get('email_list.line_map')
if line_map and line_map[line_num] then
  local id = line_map[line_num].email_id or line_map[line_num].id
  return id
end

-- Line 254-267: Fallback lookup via emails array
local emails = state.get('email_list.emails')
-- Can fail if emails not in state
```

**How line_map is set** (email_list.lua):
```lua
-- Line 615, 1524, 1602, 1650, 1657, 1721, 1832, 1890
state.set('email_list.line_map', lines.metadata or {})
```

The `metadata` table is created during `format_email_list()` and keyed by line number. If there's a mismatch between when the metadata is set and when the user presses r/R/f, the lookup fails.

**Recommended Debugging**: Add logging to verify:
1. Is the buffer filetype correct?
2. Is line_map populated when keybind is pressed?
3. Does the line number in line_map match cursor position?

## Decisions

1. **Fix is_composing**: Add `is_composing()` wrapper function to email_composer.lua that calls `is_compose_buffer()` for the current buffer
2. **Fix folder iteration**: Update all folder comparison loops to extract `.name` from folder tables
3. **Debug reply/forward**: Add defensive nil checks and better error messages to diagnose the state issue

## Recommendations

### Phase 1: Fix is_composing (Required)

Add wrapper function to `email_composer.lua`:
```lua
-- Check if any compose buffer is active (wrapper for backwards compatibility)
function M.is_composing()
  local current_buf = vim.api.nvim_get_current_buf()
  return M.is_compose_buffer(current_buf)
end
```

### Phase 2: Fix folder:lower() Error (Required)

Update `do_archive_current_email()` in main.lua:
```lua
for _, folder in ipairs(folders) do
  local folder_name = type(folder) == "table" and folder.name or folder
  for _, archive_name in ipairs(archive_folders) do
    if folder_name == archive_name or (type(folder_name) == "string" and folder_name:lower() == archive_name:lower()) then
      archive_folder = folder_name
      break
    end
  end
  if archive_folder then break end
end
```

Same fix needed in:
- `do_spam_current_email()`
- `archive_selected_emails()`
- `spam_selected_emails()`

### Phase 3: Debug Reply/Forward (Diagnostic)

Add defensive checks to `reply_current_email()`:
```lua
function M.reply_current_email()
  local email_id = M.get_current_email_id()

  -- Debug logging
  logger.debug('reply_current_email called', {
    email_id = email_id,
    filetype = vim.bo.filetype,
    line_num = vim.fn.line('.'),
    has_line_map = state.get('email_list.line_map') ~= nil,
    has_emails = state.get('email_list.emails') ~= nil
  })

  if not email_id then
    -- Provide more helpful error
    if vim.bo.filetype ~= 'himalaya-list' then
      notify.himalaya('Not in email list - focus sidebar first', notify.categories.ERROR)
    else
      notify.himalaya('No email selected on current line', notify.categories.ERROR)
    end
    return
  end
  -- ... rest of function
end
```

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| is_composing fix might break edge cases | Low | Use current buffer check matching existing is_compose_buffer pattern |
| Folder type change might affect other code | Medium | Use defensive `type(folder) == "table"` check |
| Reply/forward issue might have deeper cause | Medium | Add logging first, then fix based on diagnostic output |

## Appendix

### Files Analyzed
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/commands/email.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/email_composer.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/main.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/utils.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/data/drafts.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/email_list.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/config/ui.lua`

### Search Patterns Used
- `is_composing` - Found in commands/email.lua only
- `folder:lower` - Found in main.lua archive/spam functions
- `get_current_email_id` - Found in main.lua
- `email_list.line_map` - Found in email_list.lua (setter) and main.lua (getter)
