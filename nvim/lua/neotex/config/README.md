# Core Configuration

This directory contains the core configuration modules for NeoVim.

## File Structure

```
config/
├── README.md           # This documentation
├── init.lua           # Main loader and initialization
├── options.lua        # Core Vim/NeoVim options
├── keymaps.lua        # Key mappings for different modes
└── autocmds.lua       # Autocommands for different events
```

## Module Structure

- **init.lua**: Main loader that initializes all configuration modules
- **options.lua**: Core Vim/NeoVim options (tab settings, line numbers, etc.)
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