# Implementation Plan: Task #65

- **Task**: 65 - Fix task 64 move and send regressions
- **Status**: [NOT STARTED]
- **Effort**: 0.5-1 hours
- **Dependencies**: None
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim
- **Lean Intent**: false

## Overview

Fix two regressions introduced in task 64: (1) move command showing "table: 0x..." instead of folder names because `utils.get_folders()` returns table objects but the picker expects strings, and (2) remove the `<C-s>` send mapping that conflicts with spelling operations.

### Research Integration

- `utils.get_folders()` returns `{ name = "INBOX", path = "/" }` table objects
- The picker's `format_item` function and folder comparison need to extract `.name` property
- `<leader>mce` already exists in which-key for send email, so `<C-s>` is redundant

## Goals & Non-Goals

**Goals**:
- Fix move command folder picker to display folder names correctly
- Fix move command to pass folder name (not table) to `utils.move_email()`
- Remove conflicting `<C-s>` keymap from compose buffers

**Non-Goals**:
- Change the `utils.get_folders()` return format (maintain backward compatibility)
- Add new keymaps beyond removing the conflict

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Other code depends on folder table structure | M | L | Only extract `.name` at picker usage points, not at source |
| Missing send shortcut confuses users | L | L | `<leader>mce` already exists and is discoverable via which-key |

## Implementation Phases

### Phase 1: Fix Folder Table Handling and Remove Send Mapping [NOT STARTED]

**Goal**: Fix both move commands to handle folder table objects correctly and remove `<C-s>` keymap

**Tasks**:
- [ ] Fix `move_email_to_folder()` folder comparison (line 1492)
- [ ] Fix `move_email_to_folder()` format_item function (lines 1500-1521)
- [ ] Fix `move_email_to_folder()` move call and notification (lines 1524-1526)
- [ ] Fix `move_selected_emails()` folder comparison (line 1564)
- [ ] Fix `move_selected_emails()` format_item function (lines 1572-1588)
- [ ] Fix `move_selected_emails()` move calls and notifications (lines 1597, 1608, 1616, 1630-1631)
- [ ] Remove `<C-s>` mapping from ui.lua (lines 394-401)
- [ ] Test module loads without errors

**Timing**: 0.5-1 hours

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/main.lua` - Fix folder table handling in both move functions
- `lua/neotex/plugins/tools/himalaya/config/ui.lua` - Remove `<C-s>` mapping

**Detailed Changes**:

#### main.lua - move_email_to_folder() (lines 1492-1526)

**Line 1492** - Folder comparison:
```lua
-- Before:
if folder ~= current_folder then

-- After:
if folder.name ~= current_folder then
```

**Lines 1500-1521** - format_item function:
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

**Lines 1523-1526** - Extract folder name and use in move call:
```lua
}, function(choice)
  if choice then
    local target_folder = type(choice) == "table" and choice.name or choice
    local success = utils.move_email(line_data.email_id or line_data.id, target_folder)
    if success then
      notify.himalaya(string.format('Email moved to %s', target_folder), notify.categories.USER_ACTION)
```

#### main.lua - move_selected_emails() (lines 1564-1631)

**Line 1564** - Folder comparison:
```lua
-- Before:
if folder ~= current_folder then

-- After:
if folder.name ~= current_folder then
```

**Lines 1572-1588** - format_item function (same pattern as above):
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

**Lines 1590-1631** - Extract folder name and use throughout:
```lua
}, function(choice)
  if choice then
    local target_folder = type(choice) == "table" and choice.name or choice
    local success_count = 0
    local error_count = 0

    -- Show progress notification for large batches
    if #selected > 5 then
      notify.himalaya(string.format('Moving %d emails to %s...', #selected, target_folder), notify.categories.STATUS)
    end

    for i, email in ipairs(selected) do
      -- Debug logging
      local logger = require('neotex.plugins.tools.himalaya.core.logger')
      logger.debug('Processing selected email for move', {
        index = i,
        email_id = email.id,
        email_id_type = type(email.id),
        email_subject = email.subject,
        target_folder = target_folder,
        email_keys = vim.tbl_keys(email)
      })

      if not email.id then
        notify.himalaya(string.format('Email missing ID: %s', vim.inspect(email)), notify.categories.ERROR)
        error_count = error_count + 1
      else
        local success = utils.move_email(email.id, target_folder)
        if success then
          success_count = success_count + 1
        else
          error_count = error_count + 1
          notify.himalaya(string.format('Failed to move email %s (ID: %s)',
            email.subject or 'unknown', tostring(email.id)), notify.categories.BACKGROUND)
        end
      end
    end

    -- Clear selection mode
    state.toggle_selection_mode() -- Exit selection mode

    notify.himalaya(string.format('Moved %d emails to %s (%d errors)',
      success_count, target_folder, error_count),
      error_count > 0 and notify.categories.WARNING or notify.categories.USER_ACTION
    )

    M.refresh_email_list({ restore_insert_mode = false })
  end
end)
```

#### ui.lua - Remove <C-s> mapping (lines 394-401)

Remove these 8 lines entirely:
```lua
-- Send email
keymap('n', '<C-s>', function()
  local ok, composer = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_composer')
  local buf = vim.api.nvim_get_current_buf()
  if ok and composer.send_email then
    composer.send_email(buf)
  end
end, vim.tbl_extend('force', opts, { desc = 'Send email' }))
```

**Verification**:
- [ ] `nvim --headless -c "lua require('neotex.plugins.tools.himalaya.ui.main')" -c "q"` - Module loads without errors
- [ ] `nvim --headless -c "lua require('neotex.plugins.tools.himalaya.config.ui')" -c "q"` - Module loads without errors
- [ ] Manual test: Open email list, press `m` to move, verify folder names display correctly
- [ ] Manual test: Select multiple emails, move them, verify folder names display correctly
- [ ] Manual test: Open compose buffer, verify `<C-s>` does nothing (no conflict with spelling)
- [ ] Manual test: In compose buffer, `<leader>mce` sends email

---

## Testing & Validation

- [ ] All himalaya modules load without errors
- [ ] Move single email shows proper folder names in picker
- [ ] Move selected emails shows proper folder names in picker
- [ ] Move operation completes successfully and notification shows folder name
- [ ] `<C-s>` is no longer mapped in compose buffers
- [ ] `<leader>mce` correctly sends email in compose buffers

## Artifacts & Outputs

- Modified `lua/neotex/plugins/tools/himalaya/ui/main.lua`
- Modified `lua/neotex/plugins/tools/himalaya/config/ui.lua`

## Rollback/Contingency

If the implementation fails, revert changes to both files using git:
```bash
git checkout HEAD -- lua/neotex/plugins/tools/himalaya/ui/main.lua
git checkout HEAD -- lua/neotex/plugins/tools/himalaya/config/ui.lua
```
