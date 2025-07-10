# Preview Window Size and Auto-close Fix

## Issues Fixed

### 1. Preview Window Too Small
**Issue**: The preview window was too small, making it difficult to read email content.

**Root Cause**: The window size calculation was not optimal and the default dimensions were conservative.

**Fix**: 
- Increased default width from 80 to 100 characters
- Increased default max_height from 30 to 40 lines
- Improved size calculation to better utilize available screen space:
  ```lua
  -- Use more width when space is available
  width = math.min(width, screen_width - win_width - 4)
  height = math.min(height, win_height - 2)
  ```

### 2. Preview Not Auto-closing When Leaving Sidebar
**Issue**: When clicking or moving cursor to a normal buffer, the preview window remained open.

**Root Cause**: The auto-close functionality was missing from the refactored version.

**Fix**: Added WinLeave autocmd that:
- Detects when leaving the sidebar buffer
- Checks if the destination is a non-Himalaya buffer
- Hides the preview window while keeping preview mode enabled
- Properly cleans up autocmds to avoid memory leaks

## Implementation Details

### Window Size Improvements
```lua
-- Smart positioning with better size calculation
if win_width > 100 then  -- Changed from 120
  -- Wide screen: show on right with more space
  width = math.min(width, screen_width - win_width - 4)
  height = math.min(height, win_height - 2)
else
  -- Narrow screen: show at bottom
  width = math.min(width, win_width - 2)
  height = math.min(height, screen_height - win_height - 6)
end
```

### Auto-close Behavior
```lua
-- Setup auto-close when leaving sidebar
preview_state.autocmd_id = vim.api.nvim_create_autocmd('WinLeave', {
  buffer = sidebar_buf,
  callback = function()
    vim.schedule(function()
      -- Check if we moved to a non-himalaya buffer
      if current_buf ~= preview_state.buf and current_buf ~= sidebar_buf then
        M.hide_preview()  -- Hide but keep preview mode on
      end
    end)
  end
})
```

## Behavior Summary
1. **Preview appears**: When hovering over emails in the sidebar
2. **Preview is larger**: Better utilizes available screen space
3. **Preview auto-hides**: When clicking/moving to normal buffers
4. **Preview mode persists**: Remains enabled after auto-hide
5. **Preview reappears**: When returning to sidebar and hovering

## Testing
1. Open sidebar with `<leader>mo`
2. Enable preview mode with `<CR>`
3. Hover over emails - preview should be adequately sized
4. Click on a normal buffer - preview should auto-hide
5. Return to sidebar - preview should work again