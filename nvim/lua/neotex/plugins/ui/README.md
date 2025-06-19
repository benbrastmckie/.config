# UI Enhancement Plugins

This directory contains plugins that improve the user interface and visual experience.

## File Structure

```
ui/
├── README.md           # This documentation
├── init.lua           # UI plugins loader
├── neo-tree.lua       # Modern file explorer
├── lualine.lua        # Configurable status line
├── bufferline.lua     # Tab-like buffer navigation
├── colorscheme.lua    # Theme configuration
├── nvim-web-devicons.lua # File type icons
└── sessions.lua       # Session management
```

## Current Plugins

- **neo-tree.lua**: Modern file explorer with custom delete confirmation
- **lualine.lua**: Configurable status line with sections and themes
- **bufferline.lua**: Tab-like buffer navigation with visual indicators
- **colorscheme.lua**: Theme configuration and color scheme management
- **nvim-web-devicons.lua**: File type icons for better visual distinction
- **sessions.lua**: Session management for workspace persistence

## Key Features

### Neo-tree File Explorer
- **Modern popup styling**: Rounded borders and sleek appearance
- **Custom delete confirmation**: Command-line prompt with Enter-to-confirm behavior
- **Enhanced visual components**: Modern icons, improved git status symbols, and clean indentation markers
- **Width persistence**: Automatically saves and restores sidebar width
- **Vim-style navigation**: Consistent keymaps with h/l for expand/collapse
- **Integrated color scheme**: Matches bufferline and overall theme

#### Neo-tree Key Mappings
- `l` / `<CR>`: Open file/expand directory
- `h`: Close/collapse directory
- `d`: Delete with confirmation (Enter confirms, any text cancels)
- `a`: Add new file/directory
- `r`: Rename file/directory
- `R`: Refresh tree
- `H`: Toggle hidden files
- `v`: Open in vertical split
- `-`: Navigate up one directory

#### Neo-tree Configuration Highlights
- **Popup borders**: Rounded borders for modern appearance
- **Component styling**: Enhanced icons, git symbols, and tree markers
- **Auto-close behavior**: Closes when opening files (mimics nvim-tree)
- **Color integration**: Coordinates with bufferline and theme colors
- **Width management**: Persistent width tracking across sessions

### Status Line (Lualine)
- Modular sections for file info, git status, diagnostics
- Theme integration with color schemes
- Performance optimized updates

### Buffer Line (Bufferline)
- Tab-like interface for open buffers
- Visual indicators for modified files
- Mouse support for buffer switching

### Session Management
- Automatic workspace persistence
- Quick session switching
- Integration with file explorer state

## Plugin Analysis

To verify UI plugins are properly loaded and organized:

```vim
:luafile scripts/check_plugins.lua
```

This will show the UI category with plugins like neo-tree.lua, lualine.lua, bufferline.lua, colorscheme.lua, and others. See [`scripts/README.md`](../../../scripts/README.md) for complete script documentation and the main [plugins README](../README.md#plugin-analysis-and-maintenance) for more details.

## Customization

All UI plugins follow the project's coding standards:
- 2-space indentation
- Descriptive function names
- Error handling with pcall
- Integration with existing color schemes
- Consistent keymapping patterns

## Navigation

- [Tools Plugins →](../tools/README.md)
- [Editor Plugins →](../editor/README.md)
- [LSP Configuration →](../lsp/README.md)
- [AI Plugins →](../ai/README.md)
- [Text Plugins →](../text/README.md)
- [← Plugins Overview](../README.md)