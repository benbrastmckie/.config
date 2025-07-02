# Core Modules

Core functionality for the Himalaya email plugin. These modules provide the foundation layer that other components depend on.

## Purpose

The core layer contains essential functionality that doesn't depend on other layers:
- Configuration management and validation
- Centralized command registry 
- State management and persistence
- Structured logging system

## Modules

### commands.lua
Centralized command registry containing all Himalaya plugin commands:
- Command definitions with functions and options
- Auto-completion support for command arguments
- Main UI commands (Himalaya, HimalayaToggle, HimalayaWrite)
- Email operations (send, draft, discard)
- Sync commands (inbox, full, cancel)
- Setup and maintenance commands

Key functions:
- `register_all()` - Register all commands with Neovim
- `command_registry` - Table containing all command definitions

<!-- TODO: Consider splitting large command registry by functionality (UI, email, sync, setup) -->

### config.lua
Plugin configuration management with account and UI settings:
- Default configuration with user overrides
- Account configurations for multiple email providers
- Buffer and window keymap definitions
- UI layout preferences and behavior settings

Key functions:
- `setup(opts)` - Initialize configuration with user options
- `get_current_account()` - Get active email account
- `switch_account(name)` - Change active account
- `setup_buffer_keymaps(buf)` - Configure buffer-specific keymaps

<!-- TODO: Add validation for account configurations -->
<!-- TODO: Support for account-specific keymap overrides -->

### logger.lua
Structured logging integrated with the unified notification system:
- Multiple log levels (error, warn, info, debug)
- Automatic integration with notify.himalaya()
- Context-aware error formatting
- Development vs production logging modes

Key functions:
- `error(msg, context)` - Log error with notification and context
- `warn(msg, context)` - Log warning with context
- `info(msg, context)` - Log informational message
- `debug(msg, context)` - Log debug information (development only)

<!-- TODO: Add log rotation and persistence for debugging -->
<!-- TODO: Add performance timing helpers -->

### state.lua
Unified state management for all plugin components:
- Sync operation status and progress tracking
- OAuth token storage and refresh state
- UI state (current folder, selections, pagination)
- Session persistence across Neovim restarts

Key functions:
- `get(path, default)` - Retrieve state value by path
- `set(path, value)` - Update state value
- `save()` - Persist state to disk
- `load()` - Load state from disk
- UI helpers: `get_current_folder()`, `set_current_folder()`
- Selection helpers: `toggle_email_selection()`, `get_selected_emails()`

<!-- TODO: Add state migration for config format changes -->
<!-- TODO: Implement state cleanup for old/stale entries -->

## Architecture Notes

The core layer follows these principles:
- **No dependencies** on UI or service layers
- **Immutable interfaces** - breaking changes require major version bump
- **Error-first design** - all operations can fail gracefully
- **State persistence** - critical state survives Neovim restarts

## Usage Examples

```lua
-- Register all commands
local commands = require("neotex.plugins.tools.himalaya.core.commands")
commands.register_all()

-- Configure the plugin
local config = require("neotex.plugins.tools.himalaya.core.config")
config.setup({
  accounts = {
    gmail = { 
      name = "Gmail", 
      email = "user@gmail.com",
      maildir_path = "~/Mail/gmail" 
    }
  }
})

-- Log with context
local logger = require("neotex.plugins.tools.himalaya.core.logger")
logger.error("Sync failed", { account = "gmail", folder = "INBOX" })

-- Manage state
local state = require("neotex.plugins.tools.himalaya.core.state")
state.set_current_folder("Sent")
state.toggle_email_selection("email-123", { subject = "Test" })
state.save()
```

## Navigation
- [← Himalaya Plugin](../README.md)