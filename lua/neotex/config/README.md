# Core Configuration

This directory contains the core configuration modules for NeoVim.

## File Structure

```
config/
├── README.md           # This documentation
├── init.lua           # Main loader and initialization
├── options.lua        # Core Vim/NeoVim options
├── notifications.lua  # Unified notification system configuration
├── keymaps.lua        # Key mappings for different modes
└── autocmds.lua       # Autocommands for different events
```

## Module Structure

- **init.lua**: Main loader that initializes all configuration modules
- **options.lua**: Core Vim/NeoVim options (tab settings, line numbers, etc.)
- **notifications.lua**: Unified notification system with intelligent filtering and module-specific controls
- **keymaps.lua**: Key mappings for different modes
- **autocmds.lua**: Autocommands for different events

## Options (options.lua)

The options module sets up various Vim and NeoVim options to create a better editing experience:

- UI options (line numbers, cursor, colors)
- Editing behavior (tab settings, indentation)
- Search behavior
- Clipboard integration
- Split behavior
- Backup and file handling

## Notifications (notifications.lua)

The notifications module configures the unified notification system that provides consistent feedback across all plugins and modules:

### Key Features
- **Smart Filtering**: Category-based filtering (ERROR, WARNING, USER_ACTION, STATUS, BACKGROUND)
- **Module Control**: Per-module notification preferences (Himalaya, AI, LSP, Editor, Startup)
- **Debug Mode**: Toggle detailed notifications for troubleshooting
- **Performance**: Rate limiting and batching to prevent notification spam

### Configuration
```lua
-- Example: Disable background notifications for Himalaya
local notify_config = require('neotex.config.notifications')
notify_config.config.modules.himalaya.background_sync = false
```

### Commands
- `:Notifications` - Show notification management interface
- `:NotifyDebug [module]` - Toggle debug mode globally or per module  
- `:NotificationConfig` - Manage notification preferences

See [NOTIFICATIONS.md](../../docs/NOTIFICATIONS.md) for complete documentation.

## Keymaps (keymaps.lua)

The keymaps module defines key mappings for various operations:

- Navigation (buffer switching, window movement)
- Editing operations (format, search/replace)
- Plugin-specific mappings
- Custom command shortcuts

## Autocommands (autocmds.lua)

The autocommands module sets up automatic behaviors for different events:

- Filetype-specific settings
- Terminal behavior
- Cursor position restoration
- Auto-formatting on save
- Auto-reload files changed outside Vim

## Usage

These configuration modules are loaded automatically during startup. You can also manually reload them:

```lua
-- Reload all configuration
require("neotex.config").setup()

-- Or reload a specific module
require("neotex.config.options").setup()
```

## Navigation

- [Plugins Overview →](../plugins/README.md)
- [Tools Plugins →](../plugins/tools/README.md)
- [Editor Plugins →](../plugins/editor/README.md)
- [LSP Configuration →](../plugins/lsp/README.md)
- [← Main Configuration](../README.md)