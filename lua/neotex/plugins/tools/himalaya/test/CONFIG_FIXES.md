# Config Initialization Fixes

## Issue Identified
The config module stores configuration in `M.config` after initialization, which means:
- From inside config.lua: `M.config.binaries`
- From outside: `config.config.binaries`

Many tests were failing because config wasn't initialized, so `config.config` was nil.

## Fixes Applied

### 1. Config Initialization (3 test files)
Added config initialization to ensure `config.config` exists:
```lua
local config = require('neotex.plugins.tools.himalaya.core.config')
if not config.initialized then
  config.setup({})
end
```

**Fixed in:**
- `test_draft_saving.lua`
- `test_sync_commands.lua`
- `test_basic_commands.lua`

### 2. Consistent Config Access
Fixed inconsistent access patterns:
- `test_sync_commands.lua`: Changed `config.ui` to `config.config.ui` for consistency
- `test_basic_commands.lua`: Changed assertions to check `config.config.binaries`

### 3. Reverted Previous Fix
- `utils.lua`: Reverted to `config.config.binaries.himalaya` (was correct)

## Expected Results
These fixes should resolve:
- ✅ binaries nil error in save_draft_function
- ✅ config.ui error in auto_sync_toggle
- ✅ config_module assertion in test_basic_commands

## Remaining Issues
- Draft count mismatch (test cleanup needed)
- Maildir parsing issues
- Draft folder detection
- Integration test failures