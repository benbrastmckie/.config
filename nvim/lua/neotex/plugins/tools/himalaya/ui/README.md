# User Interface Components

UI modules for the Himalaya email plugin.

## Modules

### main.lua (2548 lines)
Core UI functionality containing all email interface operations:
- Email list display and navigation
- Email reading and viewing
- Compose, reply, and forward functionality
- Email actions (delete, archive, move)
- Keybinding management
- Buffer and window management

This is currently a monolithic module that will be reorganized in the refactor.

### sidebar.lua
Neo-tree style sidebar for email display:
- Email list rendering
- Folder navigation
- Sync status display
- Account switching
- Periodic updates

Key functions:
- `show()` - Display the sidebar
- `update()` - Refresh sidebar content
- `set_status(status)` - Update sync status

### notifications.lua
Smart notification system with pattern-based error handling:
- Context-aware error messages
- Automatic recovery suggestions
- OAuth refresh triggers
- User-friendly translations of technical errors

Key functions:
- `handle_error(error, context)` - Process and display errors
- `suggest_recovery(error_type)` - Provide recovery actions

### state.lua
Persistent UI state management:
- Last selected folder per account
- Sidebar width preferences
- View mode settings
- Session restoration

### window_stack.lua
Window focus and navigation management:
- Tracks window hierarchy
- Restores focus after operations
- Manages floating windows

### float.lua (unused)
Floating window utilities - currently not in use.

### init.lua
Simple re-export module that exposes functions from main.lua.

## Usage Examples

```lua
-- Open email interface
local ui = require("neotex.plugins.tools.himalaya.ui")
ui.open()

-- Update sidebar status
local sidebar = require("neotex.plugins.tools.himalaya.ui.sidebar")
sidebar.set_status("Syncing...")

-- Handle an error
local notifications = require("neotex.plugins.tools.himalaya.ui.notifications")
notifications.handle_error("OAuth token expired", "sync")
```

## Navigation
- [← Himalaya Plugin](../README.md)