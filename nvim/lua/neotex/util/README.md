# Utility Functions

This directory contains utility functions that provide common functionality throughout the NeoVim configuration.

## File Structure

```
util/
├── README.md           # This documentation
├── init.lua           # Main loader and utilities
├── notifications.lua  # Unified notification system
├── buffer.lua         # Buffer management utilities
├── fold.lua           # Code folding utilities
├── url.lua            # URL detection and handling
├── diagnostics.lua    # LSP diagnostic utilities
├── misc.lua           # Miscellaneous helper functions
├── optimize.lua       # Performance optimization utilities
├── lectic_extras.lua  # Lectic AI integration helpers
├── neotree-width.lua  # Neo-tree width management
└── notifications.lua  # Unified notification system
```

## Module Structure

- **init.lua**: Main loader that initializes all utility modules
- **notifications.lua**: Unified notification system for entire configuration
- **buffer.lua**: Buffer management utilities
- **fold.lua**: Code folding utilities
- **url.lua**: URL detection and handling
- **diagnostics.lua**: LSP diagnostic utilities
- **misc.lua**: Miscellaneous helper functions
- **optimize.lua**: Performance optimization utilities
- **notifications.lua**: Unified notification system for entire configuration

## Usage

To use these utilities in your configuration:

```lua
-- Load the entire util module
local utils = require("neotex.util")

-- Access a utility function directly
utils.toggle_line_numbers()

-- Or load a specific module
local buffer = require("neotex.util.buffer")
buffer.reload_config()

-- Use the notification system
local notify = require("neotex.util.notifications")
notify.editor('File saved', notify.categories.USER_ACTION)
```

## Notification System

The unified notification system provides consistent notification management across all modules. It features intelligent filtering, category-based organization, and module-specific controls.

### Key Features

- **Smart Filtering**: Shows only relevant notifications based on context and user preferences
- **Category-based**: Five notification categories (ERROR, WARNING, USER_ACTION, STATUS, BACKGROUND)
- **Module Control**: Per-module configuration for Himalaya, AI, LSP, editor, and startup
- **Debug Mode**: Toggle detailed notifications for troubleshooting
- **Batching**: Prevents notification spam during bulk operations

### Quick Usage

```lua
local notify = require('neotex.util.notifications')

-- User actions (always shown)
notify.editor('File saved', notify.categories.USER_ACTION)

-- Background operations (debug mode only)
notify.editor('Cache updated', notify.categories.BACKGROUND)

-- Module-specific notifications
notify.himalaya('Email sent', notify.categories.USER_ACTION)
notify.ai('Model switched', notify.categories.USER_ACTION)
notify.lsp('Formatting complete', notify.categories.USER_ACTION)
```

### Notification Commands

| Command | Description |
|---------|-------------|
| `:Notifications` | Show notification management menu |
| `:Notifications history` | Display recent notification history |
| `:Notifications config` | Show current configuration |
| `:NotifyDebug [module]` | Toggle debug mode for module or globally |

See the [full notification documentation](../../docs/NOTIFICATIONS.md) for complete usage examples and configuration options.

## UI Selection and Confirmation System

The configuration uses a sophisticated UI selection system with telescope-ui-select.nvim for consistent, modern dialogs.

### Confirmation Dialog Features

- **Context-Aware Sizing**: Different themes based on selection type
- **Smart Positioning**: Centered for file operations, cursor-relative for sidebar operations
- **Consistent UX**: All confirmations use the same Yes/No pattern with icons

### Selection Types

1. **File Deletion Confirmations** (`<leader>ak`):
   - **Centered dropdown theme** for visibility
   - **Kind**: `"file_deletion"`
   - **Icons**: ✓ Yes,  No

2. **Email/Sidebar Confirmations** (`gD`, neo-tree):
   - **Cursor-relative theme** for proximity
   - **Kind**: `"confirmation"`
   - **Fast updates** for responsive selection

3. **Session Restoration**:
   - **Large dropdown theme** for many options
   - **Default telescope-ui-select** behavior

### Performance Optimizations

**Himalaya Email Selection**:
- **Fast visual updates**: `n`/`N` keys use `update_selection_display()` instead of full refresh
- **No server calls**: Selection changes only update UI, not email data
- **Batch clearing**: `Esc` key clears all selections with single update

### Usage Examples

```lua
-- File deletion (centered)
vim.ui.select({"Yes", "No"}, {
  prompt = " Delete file \"filename\"?",
  kind = "file_deletion",
  format_item = function(item)
    return item == "Yes" and " " .. item or " " .. item
  end,
}, callback)

-- Email/sidebar confirmation (cursor-relative)  
vim.ui.select({"Yes", "No"}, {
  prompt = " Delete current email?",
  kind = "confirmation",
  format_item = function(item)
    return item == "Yes" and " " .. item or " " .. item
  end,
}, callback)
```

## Available Commands

Many of the utility functions are exposed as commands:

| Command | Description |
|---------|-------------|
| `:ReloadConfig` | Reload NeoVim configuration |
| `:BufCloseOthers` | Close all buffers except current one |
| `:BufCloseUnused [minutes]` | Close buffers inactive for specified time |
| `:BufSaveAll` | Save all modified buffers |
| `:BufDeleteFile` | Delete current file and close buffer |
| `:ToggleLineNumbers` | Toggle between relative and absolute line numbers |
| `:TrimWhitespace` | Remove trailing whitespace in current buffer |
| `:SelectionInfo` | Display information about visual selection |
| `:AnalyzeStartup` | Analyze Neovim startup time and identify bottlenecks |
| `:ProfilePlugins` | Profile load time for all plugins |
| `:OptimizationReport` | Generate a comprehensive optimization report |
| `:SuggestLazyLoading` | Suggest lazy-loading strategies for plugins |

## Global Functions

For backward compatibility, some functions are also exposed globally:

- `GotoBuffer(count, direction)`: Navigate between buffers
- `DisplayMessages()`: Show vim messages in quickfix window 
- `ToggleAllFolds()`: Toggle between fully open and fully closed folds
- `ToggleFoldingMethod()`: Toggle between different folding methods
- `OpenUrlUnderCursor()`: Open URL under cursor in browser

## Performance Optimization Workflow

The `optimize.lua` module provides tools for analyzing and improving Neovim performance. Follow this workflow to optimize your configuration:

### 1. Analyze Startup Time

Run `:AnalyzeStartup` to identify bottlenecks in your startup process. This will:
- Run Neovim with the `--startuptime` flag
- Parse and analyze the resulting data
- Display the top time consumers during startup
- Provide recommendations based on the analysis

### 2. Profile Plugin Load Times

Run `:ProfilePlugins` to:
- Collect information about all loaded plugins
- Measure the time each plugin takes to load
- Identify plugins that are slow to initialize
- Provide load time statistics and recommendations

### 3. Generate Comprehensive Report

Run `:OptimizationReport` to:
- Combine startup and plugin analysis
- Break down performance by category
- Identify specific optimization opportunities
- Suggest concrete improvements

### 4. Optimize Lazy-Loading

Run `:SuggestLazyLoading` to:
- Get plugin-specific lazy-loading recommendations
- See example configurations for problematic plugins
- Receive suggestions based on plugin type and function
- Learn best practices for lazy-loading different types of plugins

### Implementation Tips

1. **Start with High-Impact Changes**:
   - Focus on plugins that load at startup and have high load times
   - Implement event-based loading for non-essential startup plugins

2. **Use Appropriate Triggers**:
   - `event = "VeryLazy"` for UI components that can load after startup
   - `event = "InsertEnter"` for completion and snippet plugins
   - `cmd = { "CommandName" }` for features activated by specific commands
   - `keys = { "<leader>x" }` for functionality mapped to specific keys
   - `ft = { "filetype" }` for language-specific plugins

3. **Verify Improvements**:
   - After making changes, run `:AnalyzeStartup` again to measure impact
   - Ensure functionality still works as expected
   - Look for unexpected side effects
