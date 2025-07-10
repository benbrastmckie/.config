# Compose Status Timer Fix

## Issue
When attempting to create a new draft with `<leader>mw`, the following error occurred:
```
Error executing Lua callback: ...compose_status.lua:105: Invalid 'value': Cannot convert userdata
stack traceback:
        [C]: in function 'nvim_buf_set_var'
        ...compose_status.lua:105: in function 'setup_statusline'
```

## Root Cause Analysis
The `compose_status.lua` module was trying to store a uv_timer_t (userdata) in a buffer variable using `nvim_buf_set_var`. Neovim buffer variables cannot store userdata types - they can only store simple Lua types (strings, numbers, tables, booleans).

The problematic code:
```lua
local timer = vim.loop.new_timer()
-- ... timer setup ...
vim.api.nvim_buf_set_var(buf, 'himalaya_status_timer', timer)  -- ERROR: Cannot store userdata
```

## Solution
Store timers in a module-local table indexed by buffer number instead of trying to store them as buffer variables:

```lua
-- Store timers indexed by buffer number
local timers = {}

-- In setup_statusline:
timers[buf] = timer

-- In cleanup:
if timers[buf] then
  timers[buf]:stop()
  timers[buf] = nil
end
```

## Design Principles Applied
1. **Type Safety**: Understand what types can be stored in Neovim's various storage mechanisms
2. **Resource Management**: Properly track and clean up timers to prevent memory leaks
3. **Module State**: Use module-local tables for managing complex state like userdata

## Prevention
To prevent similar issues:
1. Remember that buffer/window/tabpage variables can only store simple Lua types
2. Use module-local tables for managing userdata and complex objects
3. Always clean up timers and other resources when buffers are unloaded
4. Test compose functionality after refactoring to catch runtime errors

## Note
If the error persists after this fix, it may be due to stale module caching. Restart Neovim to ensure all modules are reloaded with the latest changes.