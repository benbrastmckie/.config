# Himalaya UI Components

This directory contains all UI-related modules for the Himalaya email plugin.

## Modules

### init.lua
Main UI module that serves as the central hub for all UI components. It loads and re-exports functions from submodules for a clean API.

### email_list.lua
Handles the display and interaction with email lists:
- Shows emails from selected folders
- Provides keybindings for email navigation
- Manages email list buffer and window
- Supports refresh functionality

### compose.lua
Email composition functionality:
- Creates composition windows
- Handles email templates
- Manages send/cancel/draft operations
- Supports reply and forward (placeholder)

### sidebar.lua
Provides sidebar display functionality:
- Shows sync status
- Formats email entries
- Displays folder information
- Manages periodic status updates

### notifications.lua
Smart notification system with context-aware error handling:
- Pattern-based error detection
- Automatic error recovery actions
- OAuth token refresh on authentication failures
- User-friendly error messages

## Usage

The UI system is initialized in the main plugin setup:

```lua
local ui = require('neotex.plugins.tools.himalaya.ui')
ui.setup()

-- Show email list
ui.show_email_list()

-- Compose new email
ui.compose_email()
```

## Navigation
- [← Parent Directory](../README.md)