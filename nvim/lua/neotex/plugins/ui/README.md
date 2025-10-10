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
- **Enhanced visibility management**: Tabs remain visible when switching to terminals/sidebars
- Smart context awareness: Hides on alpha dashboard, shows with multiple buffers
- Event-driven visibility updates for seamless navigation
- **Session restore timing fix**: Autocmds registered immediately before defer_fn to eliminate timing gaps during session restoration

#### Bufferline Visibility Behavior
The bufferline implements intelligent tab visibility management:

**When tabs are visible:**
- Multiple buffers open (2 or more)
- Switching to Claude Code terminal (`<C-c>`)
- Opening Neo-tree sidebar
- Navigating between windows with unlisted buffers
- Git-ignored files in buffers

**When tabs are hidden:**
- Single buffer in session (minimal startup aesthetic)
- Alpha dashboard is active
- No listed buffers exist

**Technical Implementation:**
- Event-driven updates via BufEnter, WinEnter, SessionLoadPost, TermLeave, and BufDelete autocmds
- Centralized visibility logic in `ensure_tabline_visible()` function
- **Critical timing fix**: Autocmds registered BEFORE defer_fn to catch session restore events
- 10ms deferred updates on terminal/buffer events for smooth transitions
- No performance impact from event handlers

See [bufferline.lua:60-173](bufferline.lua) for implementation details and [specs/reports/038_buffer_persistence_root_cause.md](../../../specs/reports/038_buffer_persistence_root_cause.md) for timing race condition analysis.

### Session Management
- Automatic workspace persistence
- Quick session switching
- Integration with file explorer state
- **Root cause fixes implemented**: Pattern matching and timing issues resolved (see below)
- **Simplified defensive protection**: Minimal autocmd coverage guards against unknown async operations

#### Session Buffer Persistence
**Root Cause Fixed (2025-10-03)**: Buffer persistence issues were caused by two primary bugs:
1. **claudecode.lua pattern matching bug**: Overly broad pattern unlisted .claude/ directory files
2. **bufferline.lua timing race condition**: Autocmd registration delay created session restore gap

Both bugs have been fixed at their source. See:
- [specs/reports/038_buffer_persistence_root_cause.md](../../../specs/reports/038_buffer_persistence_root_cause.md) - Complete root cause analysis
- [specs/plans/030_fix_buffer_persistence_root_cause.md](../../../specs/plans/030_fix_buffer_persistence_root_cause.md) - Implementation plan
- [specs/summaries/030_buffer_persistence_root_cause_summary.md](../../../specs/summaries/030_buffer_persistence_root_cause_summary.md) - Implementation workflow

**Defensive mechanism** (sessions.lua:64-84):
- **Currently commented out** (commit 8366c70) to test if root cause fixes are sufficient
- If buffer disappearance issues occur, uncomment the defensive autocmd in sessions.lua
- When active: Uses BufEnter and BufWinEnter to enforce `buflisted = true` for normal file buffers
- Simplified design: 2 events (removed BufAdd, SessionLoadPost after root cause fixes)
- Path-agnostic protection for all normal files

See implementation details in [sessions.lua:64-84](sessions.lua) and historical investigation in [specs/reports/037_debug_gitignored_buffer_disappearance.md](../../../specs/reports/037_debug_gitignored_buffer_disappearance.md).

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