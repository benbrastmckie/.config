# Draft Window Management API Documentation (Phase 6)

This document describes the window management integration for the draft system implemented in Phase 6.

## Overview

The draft system now integrates with Himalaya's window stack manager to:
- Track draft windows in the window hierarchy
- Ensure proper focus restoration when closing nested windows
- Provide draft-specific window management functions
- Enable bulk operations on draft windows

## Window Stack Integration

### Configuration

Window stack integration is controlled by the configuration:

```lua
{
  draft = {
    integration = {
      use_window_stack = true  -- Enable/disable window stack tracking
    }
  }
}
```

### Automatic Tracking

When enabled, draft windows are automatically tracked when:
- Creating a new draft (`email_composer.create_compose_buffer`)
- Opening an existing draft (`email_composer.open_draft`)

## Window Stack API Extensions

### Draft-Specific Functions

#### `window_stack.push_draft(win_id, draft_id, parent_win)`

Push a draft window onto the stack with draft-specific metadata.

**Parameters:**
- `win_id` (number): Window ID to track
- `draft_id` (string): Local draft ID
- `parent_win` (number?): Parent window ID (defaults to current window)

**Returns:**
- `boolean`: Success status

**Example:**
```lua
local win_id = vim.api.nvim_get_current_win()
window_stack.push_draft(win_id, draft.local_id, parent_win)
```

#### `window_stack.get_draft_windows()`

Get all draft windows currently in the stack.

**Returns:**
- `table[]`: Array of draft window entries

**Entry Structure:**
```lua
{
  window = 1001,           -- Window ID
  parent = 1000,           -- Parent window ID
  buffer = 10,             -- Buffer ID
  type = 'draft',          -- Window type
  draft_id = 'draft_123',  -- Local draft ID
  timestamp = 12345678     -- Creation timestamp
}
```

#### `window_stack.get_draft_window(draft_id)`

Get a specific draft window by draft ID.

**Parameters:**
- `draft_id` (string): Local draft ID to find

**Returns:**
- `table?`: Window entry or nil if not found

#### `window_stack.has_draft_window(draft_id)`

Check if a draft window is open.

**Parameters:**
- `draft_id` (string): Local draft ID to check

**Returns:**
- `boolean`: True if draft window exists

#### `window_stack.close_all_drafts()`

Close all draft windows in the stack.

**Returns:**
- `number`: Count of windows closed

**Example:**
```lua
-- Close all draft windows before performing bulk operation
local closed = window_stack.close_all_drafts()
print(string.format("Closed %d draft windows", closed))
```

## Email Composer Integration

### Window Creation

The email composer automatically tracks windows when creating drafts:

```lua
-- In create_compose_buffer
local win_id = vim.api.nvim_get_current_win()
window_stack.push_draft(win_id, draft.local_id, parent_win)
```

### Window Cleanup

Windows are automatically removed from the stack on close:

```lua
-- BufWinLeave autocmd
vim.api.nvim_create_autocmd('BufWinLeave', {
  buffer = buf,
  once = true,
  callback = function()
    if config.draft.integration.use_window_stack then
      window_stack.close_current()
    end
  end
})
```

## Window Types

The window stack now tracks window types:

- `'generic'`: Regular windows (default)
- `'draft'`: Draft composition windows

This enables type-specific operations and filtering.

## Debug Support

Enhanced debug output shows window types and draft IDs:

```lua
window_stack.debug()
-- Output:
-- Window Stack (depth: 3):
--   1: win=1000(valid) parent=0(valid) type=generic
--   2: win=1001(valid) parent=1000(valid) type=draft[draft_123]
--   3: win=1002(valid) parent=1001(valid) type=generic
```

## Usage Examples

### Opening Multiple Drafts

```lua
-- Open first draft
email_composer.create_compose_buffer({ account = 'gmail' })
-- Window automatically tracked as draft

-- Open second draft from first
email_composer.create_compose_buffer({ account = 'work' })
-- Parent-child relationship maintained

-- Check open drafts
local drafts = window_stack.get_draft_windows()
print(string.format("%d draft windows open", #drafts))
```

### Finding a Draft Window

```lua
-- Check if specific draft is open
if window_stack.has_draft_window(draft_id) then
  local entry = window_stack.get_draft_window(draft_id)
  -- Focus the window
  vim.api.nvim_set_current_win(entry.window)
else
  -- Open the draft
  email_composer.open_draft(draft_id, account)
end
```

### Closing All Drafts

```lua
-- Save all drafts before closing
local drafts = window_stack.get_draft_windows()
for _, entry in ipairs(drafts) do
  if vim.api.nvim_buf_is_valid(entry.buffer) then
    draft_manager.save(entry.buffer)
  end
end

-- Close all draft windows
window_stack.close_all_drafts()
```

## Best Practices

1. **Always check configuration** before using window stack features
2. **Use draft-specific functions** for draft windows (not generic `push`)
3. **Handle window cleanup** properly with autocmds
4. **Check window validity** before operations
5. **Maintain parent-child relationships** for proper focus restoration

## Testing

### Manual Testing

```vim
" Open draft
:HimalayaDraftNew

" Open another draft
:HimalayaDraftNew

" Check window stack
:lua require('neotex.plugins.tools.himalaya.ui.window_stack').debug()

" Close current draft
:close

" Focus should return to previous draft
```

### Programmatic Testing

```lua
-- Run window management tests
dofile('lua/neotex/plugins/tools/himalaya/scripts/features/test_draft_window_management.lua')
_G.draft_window_management_test:run()
```

## Migration Notes

- Existing code using generic `window_stack.push()` continues to work
- Draft windows are automatically tracked when configuration is enabled
- No changes required to existing window management code

## Future Enhancements

1. **Window Layouts**: Save and restore draft window layouts
2. **Tab Support**: Track drafts across tabs
3. **Quick Switch**: Keybindings to switch between draft windows
4. **Window Groups**: Group related draft windows
5. **Session Persistence**: Restore draft windows on session load