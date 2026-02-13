# Research Report: Task #65

**Task**: 65 - Fix task 64 move and send regressions
**Started**: 2026-02-11T00:00:00Z
**Completed**: 2026-02-11T00:05:00Z
**Effort**: 0.5-1 hours
**Dependencies**: None
**Sources/Inputs**: Local codebase analysis
**Artifacts**: This report
**Standards**: report-format.md

## Executive Summary

- Move command shows "table: 0x..." because `utils.get_folders()` returns table objects `{ name = "INBOX", path = "/" }`, but the format_item function tries to call `tostring()` on these tables
- The `<C-s>` send mapping in compose keymaps conflicts with spelling operations and should be changed to `<leader>mcs` (compose send)
- Both fixes are straightforward: extract `.name` property from folder objects and change keymap

## Context & Scope

Task 64 added defensive type checking to the move command that inadvertently broke functionality. This research identifies the exact code changes needed to fix two regressions:

1. Move command picker showing memory addresses instead of folder names
2. `<C-s>` keymap conflict with spelling operations

## Findings

### Issue 1: Move Command Folder Display

#### Root Cause

The `utils.get_folders()` function at `lua/neotex/plugins/tools/himalaya/utils.lua:53-92` returns an array of table objects:

```lua
-- utils.lua lines 83-88
local folders = {}
for _, folder in ipairs(result) do
  table.insert(folders, {
    name = folder.name or folder,
    path = folder.path or '/'
  })
end
return folders
```

Each folder object has structure: `{ name = "INBOX", path = "/" }`

In `main.lua` at lines 1498-1521, the `format_item` function checks if the folder is a string:

```lua
format_item = function(folder)
  -- Add defensive nil/type check
  if not folder or type(folder) ~= "string" then
    return folder and tostring(folder) or "(invalid)"
  end
  -- ... icon formatting ...
end
```

Since folders are tables (not strings), this returns `tostring(table)` which produces "table: 0x7f8d45be2908".

#### Additional Problems

1. **Folder comparison at line 1492**: `folder ~= current_folder` compares a table object to a string
2. **Move call at line 1524**: `utils.move_email(line_data.email_id, choice)` passes the full table object, but `move_email()` expects a string folder name for the CLI command

#### Solution

Extract the `name` property at each usage point:

**File**: `lua/neotex/plugins/tools/himalaya/ui/main.lua`

**Fix 1 - Line 1492** (folder comparison):
```lua
-- Before:
if folder ~= current_folder then

-- After:
if folder.name ~= current_folder then
```

**Fix 2 - Lines 1500-1520** (format_item function):
```lua
format_item = function(folder)
  local name = type(folder) == "table" and folder.name or folder
  if not name or type(name) ~= "string" then
    return "(invalid)"
  end
  -- Add icon for special folders
  if name:lower():match('inbox') then
    return '📥 ' .. name
  elseif name:lower():match('sent') then
    return '📤 ' .. name
  elseif name:lower():match('draft') then
    return '📝 ' .. name
  elseif name:lower():match('trash') then
    return '🗑️ ' .. name
  elseif name:lower():match('spam') or name:lower():match('junk') then
    return '⚠️ ' .. name
  elseif name:lower():match('archive') or name:lower():match('all.mail') then
    return '📦 ' .. name
  else
    return '📁 ' .. name
  end
end
```

**Fix 3 - Line 1524** (move call):
```lua
-- Before:
local success = utils.move_email(line_data.email_id or line_data.id, choice)

-- After:
local target_folder = type(choice) == "table" and choice.name or choice
local success = utils.move_email(line_data.email_id or line_data.id, target_folder)
```

**Fix 4 - Line 1526** (notification):
```lua
-- Before:
notify.himalaya(string.format('Email moved to %s', choice), notify.categories.USER_ACTION)

-- After:
notify.himalaya(string.format('Email moved to %s', target_folder), notify.categories.USER_ACTION)
```

### Issue 2: Send Mapping Conflict

#### Current State

The `<C-s>` mapping is defined at `lua/neotex/plugins/tools/himalaya/config/ui.lua:395-401`:

```lua
keymap('n', '<C-s>', function()
  local ok, composer = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_composer')
  local buf = vim.api.nvim_get_current_buf()
  if ok and composer.send_email then
    composer.send_email(buf)
  end
end, vim.tbl_extend('force', opts, { desc = 'Send email' }))
```

#### Existing which-key Mappings

From `lua/neotex/plugins/editor/which-key.lua:553-558`, compose-specific mappings already exist under `<leader>mc`:

```lua
{ "<leader>mc", group = "compose", icon = "󰝒", cond = is_compose_buffer },
{ "<leader>mcd", "<cmd>HimalayaSaveDraft<CR>", desc = "save draft", icon = "󰉊", cond = is_compose_buffer },
{ "<leader>mcD", "<cmd>HimalayaDiscard<CR>", desc = "discard email", icon = "󰩺", cond = is_compose_buffer },
{ "<leader>mce", "<cmd>HimalayaSend<CR>", desc = "send email", icon = "󰊠", cond = is_compose_buffer },
{ "<leader>mcq", "<cmd>HimalayaDiscard<CR>", desc = "quit (discard)", icon = "󰆴", cond = is_compose_buffer },
```

Note: `<leader>mce` already exists for send email in which-key, but `<C-s>` is redundant.

#### Solution

Remove the `<C-s>` mapping from `ui.lua` and optionally add `<leader>mcs` as an alternative.

**File**: `lua/neotex/plugins/tools/himalaya/config/ui.lua`

**Remove lines 394-401** (the `<C-s>` send mapping):
```lua
-- Remove this block entirely:
-- Send email
keymap('n', '<C-s>', function()
  local ok, composer = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_composer')
  local buf = vim.api.nvim_get_current_buf()
  if ok and composer.send_email then
    composer.send_email(buf)
  end
end, vim.tbl_extend('force', opts, { desc = 'Send email' }))
```

The existing `<leader>mce` mapping in which-key already handles send functionality.

**Optional**: Add `<leader>mcs` to which-key for "mail compose send" consistency:
```lua
{ "<leader>mcs", "<cmd>HimalayaSend<CR>", desc = "send email", icon = "󰊠", cond = is_compose_buffer },
```

## Decisions

1. **Folder handling**: Extract `.name` property from folder tables rather than changing `get_folders()` return format (maintains backward compatibility with any code expecting table objects)
2. **Send mapping**: Remove `<C-s>` entirely since `<leader>mce` already exists (no need for redundant mapping)

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Other code expecting folder tables | Search for all uses of `get_folders()` to ensure consistent handling |
| Missing send shortcut | `<leader>mce` is already defined and discoverable via which-key |

## Implementation Checklist

- [ ] Fix folder comparison at line 1492 in main.lua
- [ ] Fix format_item function at lines 1500-1520 in main.lua
- [ ] Fix move_email call at line 1524 in main.lua
- [ ] Fix notification at line 1526 in main.lua
- [ ] Remove `<C-s>` mapping from ui.lua lines 394-401
- [ ] Verify move_selected_emails function has same fixes if needed
- [ ] Test move command with folder picker
- [ ] Test compose buffer keymaps

## Appendix

### Files Modified

1. `lua/neotex/plugins/tools/himalaya/ui/main.lua` - Lines 1492, 1500-1526
2. `lua/neotex/plugins/tools/himalaya/config/ui.lua` - Lines 394-401

### Related Functions

- `utils.get_folders()` - Returns `{ { name = "INBOX", path = "/" }, ... }`
- `utils.move_email(email_id, target_folder)` - Expects string folder name
- `state.get_current_folder()` - Returns string folder name ("INBOX")
