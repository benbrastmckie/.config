# Tool Integration Plugins

This directory contains plugins that enhance the editing experience with additional tools and functionality:

## External Tool Integration
- Git integration (gitsigns)
- Browser integration (firenvim)
- UI and UX enhancements (snacks)

## Text Manipulation Tools
- Enhanced yank and paste functionality (yanky)
- Text surrounding and brackets (surround)
- Mini plugins collection (pairs, comments, etc.)
- Smart list handling for markdown (autolist)
- TODO comments highlighting and navigation (todo-comments)

## UI Enhancement Tools
- Dashboard and startup screen (snacks)
- Git blame and lazygit integration (snacks)
- Status column with enhanced information (snacks)
- Terminal integration (snacks)
- Window management utilities (snacks)
- Notification system (snacks)

These tools provide specialized functionality that extends the core editor capabilities with focused, purpose-built features.

## Plugin Analysis

To verify tools plugins are properly loaded and organized:

```vim
:luafile scripts/check_plugins.lua
```

This will show the TOOLS category with plugins like gitsigns.lua, mini.lua, yanky.lua, surround.lua, and others. See [`scripts/README.md`](../../../scripts/README.md) for complete script documentation and the main [plugins README](../README.md#plugin-analysis-and-maintenance) for more details.