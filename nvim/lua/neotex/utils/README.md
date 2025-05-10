# Utility Functions

This directory contains utility functions that provide common functionality throughout the NeoVim configuration.

## Module Structure

- **init.lua**: Main loader that initializes all utility modules
- **buffer.lua**: Buffer management utilities
- **fold.lua**: Code folding utilities
- **url.lua**: URL detection and handling
- **diagnostics.lua**: LSP diagnostic utilities
- **misc.lua**: Miscellaneous helper functions

## Usage

To use these utilities in your configuration:

```lua
-- Load the entire utils module
local utils = require("neotex.utils")

-- Access a utility function directly
utils.toggle_line_numbers()

-- Or load a specific module
local buffer = require("neotex.utils.buffer")
buffer.reload_config()
```

## Available Commands

Many of the utility functions are exposed as commands:

| Command | Description |
|---------|-------------|
| `:ReloadConfig` | Reload NeoVim configuration |
| `:BufCloseOthers` | Close all buffers except current one |
| `:BufCloseUnused [minutes]` | Close buffers inactive for specified time |
| `:BufSaveAll` | Save all modified buffers |
| `:ToggleLineNumbers` | Toggle between relative and absolute line numbers |
| `:TrimWhitespace` | Remove trailing whitespace in current buffer |
| `:SelectionInfo` | Display information about visual selection |

## Global Functions

For backward compatibility, some functions are also exposed globally:

- `GotoBuffer(count, direction)`: Navigate between buffers
- `DisplayMessages()`: Show vim messages in quickfix window 
- `ToggleAllFolds()`: Toggle between fully open and fully closed folds
- `ToggleFoldingMethod()`: Toggle between different folding methods
- `OpenUrlUnderCursor()`: Open URL under cursor in browser