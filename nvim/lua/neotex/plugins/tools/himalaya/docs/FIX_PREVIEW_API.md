# Email Preview API Fix

## Issue
When opening the Himalaya sidebar with `<leader>mo`, the following error occurred:
```
Error executing lua callback: ...config.lua:829: attempt to call field 'is_preview_mode' (a nil value)
```

## Root Cause Analysis
The `email_preview.lua` module had an incomplete API. Several functions were being called from `config.lua` but were not implemented in the preview module:

1. `is_preview_mode()` - Check if preview mode is enabled
2. `enable_preview_mode()` - Enable preview mode
3. `disable_preview_mode()` - Disable preview mode and cleanup
4. `is_preview_shown()` - Check if preview window is visible
5. `ensure_preview_window()` - Get preview window if valid
6. `focus_preview()` - Focus the preview window
7. `get_current_preview_id()` - Get the ID of currently previewed email
8. `get_preview_state()` - Get the preview state object

## Solution
Added all missing functions to `email_preview.lua` to complete the API:

```lua
-- Check if preview mode is enabled
function M.is_preview_mode()
  return preview_state.preview_mode
end

-- Enable preview mode
function M.enable_preview_mode()
  preview_state.preview_mode = true
  return true
end

-- Disable preview mode
function M.disable_preview_mode()
  preview_state.preview_mode = false
  if preview_state.win and vim.api.nvim_win_is_valid(preview_state.win) then
    vim.api.nvim_win_close(preview_state.win, true)
  end
  preview_state.win = nil
  preview_state.email_id = nil
  return true
end

-- Additional accessor and utility functions...
```

## Design Principles Applied
1. **Complete API Surface**: Rather than patching the calling code, we completed the module's API
2. **Consistent Naming**: Functions follow the existing naming pattern in the module
3. **State Encapsulation**: All functions properly manage the internal `preview_state`
4. **Defensive Programming**: Functions check validity before operations (e.g., window validity)
5. **Clear Return Values**: Functions return boolean success indicators where appropriate

## Testing
Created `test_preview_api.lua` to verify:
- All expected functions are present
- Basic functionality works correctly
- State transitions are handled properly

## Prevention
To prevent similar issues in the future:
1. When creating modules with internal state, ensure all necessary accessor functions are provided
2. Use consistent API patterns across similar modules
3. Consider creating interface documentation or type annotations for module APIs
4. Test module APIs independently before integration