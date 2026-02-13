# Research Report: Task #75

**Task**: 75 - fix_himalaya_send_email_nil_error
**Started**: 2026-02-13T12:00:00Z
**Completed**: 2026-02-13T12:15:00Z
**Effort**: 0.5-1 hours
**Dependencies**: None
**Sources/Inputs**: Local codebase analysis
**Artifacts**: - specs/075_fix_himalaya_send_email_nil_error/reports/research-001.md
**Standards**: report-format.md

## Executive Summary
- The error occurs because `main.send_email()` is called in `commands/email.lua:62` but this function does not exist in `ui/main.lua`
- The correct function is `main.send_current_email()` (defined at line 115 of main.lua)
- Similar issue exists for `HimalayaDiscard` command which calls `composer.close()` but should call `composer.close_compose_buffer()` or use `main.close_without_saving()`

## Context & Scope

The user encountered an error when pressing `<leader>me` in a Himalaya email compose buffer:

```
Error executing Lua callback: ...vim/lua/neotex/plugins/tools/himalaya/commands/email.lua:62: attempt to call field 'send_email' (a nil value)
```

The error occurs after creating an email by pressing 'e' in the himalaya sidebar.

## Findings

### Root Cause Analysis

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/commands/email.lua`

**Line 51-67 (HimalayaSend command)**:
```lua
commands.HimalayaSend = {
  fn = function()
    local main = require('neotex.plugins.tools.himalaya.ui.main')
    local composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
    local notify = require('neotex.util.notifications')

    if not composer.is_composing() then
      notify.himalaya('No email is being composed', notify.categories.ERROR)
      return
    end

    main.send_email()  -- <-- ERROR: This function does not exist!
  end,
  ...
}
```

**Problem**: The code calls `main.send_email()` but this function does not exist in `ui/main.lua`.

### Available Functions in main.lua

The `ui/main.lua` module has these relevant functions:

| Function Name | Line | Description |
|--------------|------|-------------|
| `M.send_current_email()` | 115 | Sends email from current compose buffer - checks if current buffer is compose buffer, then calls `email_composer.send_email(buf)` |
| `M.close_without_saving()` | 129 | Closes compose buffer without saving (discard) |
| `M.close_and_save_draft()` | 168 | Saves draft then closes |

### Available Functions in email_composer.lua

| Function Name | Line | Description |
|--------------|------|-------------|
| `M.send_email(buf)` | 213 | Sends email from specified buffer |
| `M.close_compose_buffer(buf)` | 318 | Closes compose buffer |
| `M.is_compose_buffer(buf)` | 634 | Checks if buffer is a compose buffer |
| `M.is_composing()` | 640 | Checks if current buffer is a compose buffer |

### Secondary Issue: HimalayaDiscard Command

**Line 86-101 (HimalayaDiscard command)**:
```lua
commands.HimalayaDiscard = {
  fn = function()
    local composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
    local notify = require('neotex.util.notifications')

    if not composer.is_composing() then
      notify.himalaya('No email is being composed', notify.categories.ERROR)
      return
    end

    composer.close()  -- <-- ERROR: This function does not exist!
  end,
  ...
}
```

**Problem**: Calls `composer.close()` but this function does not exist. The correct function is either:
- `composer.close_compose_buffer(vim.api.nvim_get_current_buf())`
- Or use `main.close_without_saving()` for consistency with other patterns

### Existing Pattern Analysis

Looking at line 53-54 of the HimalayaSend command, the `main` and `composer` modules are already both imported. The pattern used elsewhere in the codebase prefers calling through `main` for UI-level operations.

**Example from main.lua line 115-121**:
```lua
function M.send_current_email()
  local buf = vim.api.nvim_get_current_buf()
  if email_composer.is_compose_buffer(buf) then
    return email_composer.send_email(buf)
  end
  notify.himalaya('Not in a compose buffer', notify.categories.ERROR)
end
```

This function already includes the buffer check and proper error handling.

## Recommendations

### Fix 1: HimalayaSend Command (Line 62)

**Change**:
```lua
main.send_email()
```

**To**:
```lua
main.send_current_email()
```

**Rationale**: `send_current_email()` is the correct public API in main.lua that:
1. Gets the current buffer
2. Verifies it's a compose buffer
3. Calls `email_composer.send_email(buf)`

### Fix 2: HimalayaDiscard Command (Line 96)

**Change**:
```lua
composer.close()
```

**To**:
```lua
main.close_without_saving()
```

**Rationale**: `close_without_saving()` is the correct public API in main.lua that:
1. Handles both compose buffers and other himalaya buffers
2. Properly cleans up windows and restores focus
3. Shows appropriate notification

### Alternative Fix 2 (if staying with composer module)

**Change**:
```lua
composer.close()
```

**To**:
```lua
local buf = vim.api.nvim_get_current_buf()
composer.close_compose_buffer(buf)
```

## Decisions
- Use existing main.lua functions rather than adding new aliases
- The `is_composing()` check in commands is redundant since both `send_current_email()` and `close_without_saving()` already handle non-compose buffers gracefully, but keeping it provides better error messages to users

## Risks & Mitigations
- **Risk**: Functions may have been renamed during refactoring and old references not updated
- **Mitigation**: After fix, run comprehensive test of all HimalayaSend, HimalayaSaveDraft, and HimalayaDiscard commands
- **Risk**: Keybindings in which-key may still reference old patterns
- **Mitigation**: Verified that keybindings use command names (:HimalayaSend) not direct function calls

## Appendix

### Files Analyzed
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/commands/email.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/main.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/email_composer.lua`

### Related Files
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/init.lua` - Re-exports main functions
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/commands/init.lua` - Command registration
