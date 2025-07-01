# Core Modules

Core functionality for the Himalaya email plugin.

## Modules

### config.lua
Manages plugin configuration including:
- Default settings and user overrides
- Account configurations
- Keymaps and command mappings
- UI preferences

Key functions:
- `setup(opts)` - Initialize configuration with user options
- `get_accounts()` - Retrieve configured email accounts
- `get_keymaps()` - Get keymap configurations

### logger.lua
Provides structured logging integrated with Neovim's notification system:
- Error, warning, info, and debug logging levels
- Smart error pattern matching
- Integration with ui/notifications.lua

Key functions:
- `error(msg)` - Log error with notification
- `warn(msg)` - Log warning
- `info(msg)` - Log informational message
- `debug(msg)` - Log debug information

### state.lua
Runtime state management for:
- Sync status tracking
- OAuth token storage
- Active account selection
- UI state persistence

Key functions:
- `get()` - Retrieve current state
- `set(key, value)` - Update state value
- `save()` - Persist state to disk

## Usage Examples

```lua
-- Configure the plugin
local config = require("neotex.plugins.tools.himalaya.core.config")
config.setup({
  accounts = {
    personal = { name = "Personal", email = "user@gmail.com" }
  }
})

-- Log an error
local logger = require("neotex.plugins.tools.himalaya.core.logger")
logger.error("Failed to sync emails")

-- Update state
local state = require("neotex.plugins.tools.himalaya.core.state")
state.set("active_account", "personal")
```

## Navigation
- [← Himalaya Plugin](../README.md)