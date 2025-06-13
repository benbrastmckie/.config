# Editor Enhancement Plugins

This directory contains plugins that improve the core editing experience:

## Core Editor Enhancements
- Navigation plugins (telescope, treesitter)
- Visual enhancements (which-key)
- Terminal integration (toggleterm)
- Text formatting and linting
- Code formatting utilities

## Plugin Organization

The editor plugins are organized by core editing functionality:

- **Navigation and Search**: telescope, treesitter
- **Terminal Integration**: toggleterm  
- **Code Quality**: formatting, linting
- **User Interface**: which-key for keybinding help

Related tools are organized in other categories:
- Text manipulation utilities → tools
- UI components → ui  
- Language-specific tools → text

## Plugin Analysis

To verify editor plugins are properly loaded and organized:

```vim
:luafile scripts/check_plugins.lua
```

This will show the EDITOR category with plugins like telescope.nvim, nvim-treesitter, toggleterm.nvim, and others. See [`scripts/README.md`](../../../scripts/README.md) for complete script documentation and the main [plugins README](../README.md#plugin-analysis-and-maintenance) for more details.