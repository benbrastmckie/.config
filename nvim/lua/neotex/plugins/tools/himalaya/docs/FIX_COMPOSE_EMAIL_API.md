# Compose Email API Fix

## Issue
When attempting to create a new draft with `<leader>mw`, the following error occurred:
```
Error executing Lua callback: ...himalaya/ui/main.lua:96: attempt to call field 'compose_email' (a nil value)
```

## Root Cause Analysis
The `email_composer.lua` module was refactored as part of the v2 draft system, and several function names were changed:
- `compose_email` → `create_compose_buffer`
- `send_email` → `send_and_close`

However, the calling code in `main.lua` and `commands/email.lua` was not updated to use the new function names.

## Solution
Updated all references to use the new API:

1. In `ui/main.lua`:
```lua
-- Old
return email_composer.compose_email({ to = to_address })
-- New
return email_composer.create_compose_buffer({ to = to_address })
```

2. In `core/commands/email.lua`:
```lua
-- Old
composer.send_email(buf)
-- New
composer.send_and_close(buf)

-- Also updated template usage
composer.compose_email({...})  →  composer.create_compose_buffer({...})
```

## Design Principles Applied
1. **API Consistency**: When refactoring modules, ensure all calling code is updated
2. **Clear Naming**: The new names better reflect what the functions do:
   - `create_compose_buffer` creates a buffer for composing
   - `send_and_close` sends the email and closes the buffer

## Prevention
To prevent similar issues:
1. When renaming functions, use grep to find all references
2. Consider keeping deprecated aliases during transition periods
3. Document API changes in migration guides
4. Add integration tests that exercise command paths