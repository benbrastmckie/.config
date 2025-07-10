# Config Get Usage Fix

## Issue
When attempting to create a new draft with `<leader>mw`, the following error occurred:
```
Error executing Lua callback: ...config.lua:550: attempt to index local 'path' (a nil value)
stack traceback:
        ...config.lua:550: in function 'get'
        ...email_composer.lua:253: in function 'compose_email'
```

## Root Cause Analysis
The `email_composer.lua` module was calling `config.get()` without any arguments, but the `get` function in `config.lua` expects a `path` parameter:

```lua
-- Incorrect usage
local current_config = config.get()

-- Function signature expects a path
function M.get(path, default)
  for part in path:gmatch("[^.]+") do  -- ERROR: path is nil
```

## Solution
Changed all occurrences to use the proper API with a path string:

```lua
-- Old (incorrect)
local current_config = config.get()
if current_config.draft and current_config.draft.integration and 
   current_config.draft.integration.use_window_stack then

-- New (correct)
if config.get('draft.integration.use_window_stack', false) then
```

This change:
1. Provides the required path parameter
2. Simplifies the code by avoiding deep property checks
3. Provides a default value (false) if the config doesn't exist

## Design Principles Applied
1. **API Consistency**: Always use functions according to their documented signatures
2. **Defensive Programming**: Provide sensible defaults for optional configurations
3. **Code Simplification**: Use the config.get() path syntax to avoid deep property checking

## Prevention
To prevent similar issues:
1. When refactoring config access, ensure all callers are updated
2. Consider adding a separate method for getting the entire config if needed
3. Use type annotations or documentation to clarify function parameters
4. Test all code paths after API changes