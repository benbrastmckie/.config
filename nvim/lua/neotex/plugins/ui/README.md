# UI Enhancement Plugins

This directory contains plugins that improve the user interface:

- Status line configuration (lualine)
- Tab and buffer line enhancements (bufferline)
- UI components and notifications
- Visual themes and styling (colorscheme)
- File explorer and navigation (nvim-tree)
- File icons (nvim-web-devicons)
- Session management (sessions)

## Plugin Analysis

To verify UI plugins are properly loaded and organized:

```vim
:luafile scripts/check_plugins.lua
```

This will show the UI category with plugins like lualine.lua, bufferline.lua, colorscheme.lua, nvim-tree.lua, and others. See [`scripts/README.md`](../../../scripts/README.md) for complete script documentation and the main [plugins README](../README.md#plugin-analysis-and-maintenance) for more details.