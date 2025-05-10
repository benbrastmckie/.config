# NeoVim Configuration - New Structure

This document outlines the new structure of the NeoVim configuration after refactoring.

## Directory Structure

```
nvim/
├── init.lua                  # Main entry point - minimal bootstrapping
├── lua/
│   └── neotex/
│       ├── config/           # Configuration modules
│       │   ├── autocmds.lua  # Auto-commands definition
│       │   ├── keymaps.lua   # Key mappings definition
│       │   ├── options.lua   # Vim/Neovim options
│       │   └── init.lua      # Config loader
│       ├── utils/            # Utility functions and helpers
│       │   ├── init.lua      # Main utility loader
│       │   ├── buffer.lua    # Buffer utilities
│       │   ├── fold.lua      # Folding utilities
│       │   ├── misc.lua      # Miscellaneous utilities
│       │   ├── diagnostics.lua # Diagnostic utilities
│       │   └── url.lua       # URL handling utilities
│       ├── plugins/          # Plugin specifications
│       │   ├── init.lua      # Plugin loader
│       │   └── [plugin].lua  # Individual plugin configurations
│       └── bootstrap.lua     # Bootstrapping logic
```

## Core Components

### bootstrap.lua

This module handles the initialization of the NeoVim configuration with robust error handling:

- Validates and fixes the lockfile if needed
- Ensures lazy.nvim is installed
- Loads plugins with graceful fallback mechanisms
- Initializes utility functions
- Sets up Jupyter styling with proper sequencing

### config/

Configuration modules for core NeoVim behavior:

- **init.lua**: Coordination of configuration loading
- **options.lua**: Core Vim/NeoVim settings
- **keymaps.lua**: Key mappings for different modes
- **autocmds.lua**: Auto-commands for different events

### utils/

Utility functions organized by category:

- **buffer.lua**: Buffer management functions
- **fold.lua**: Code folding utilities
- **url.lua**: URL detection and handling
- **diagnostics.lua**: LSP diagnostic utilities
- **misc.lua**: Miscellaneous helper functions

### plugins/

Plugin specifications with category-based organization:

- **init.lua**: Centralized plugin loader
- Individual plugin configuration files

## Usage

Each module follows a consistent pattern:

```lua
-- Require a module
local config = require("neotex.config")
local utils = require("neotex.utils")

-- Use a specific utility function
local buffer = require("neotex.utils.buffer")
buffer.reload_config()

-- Use utility functions from the main utils module
utils.toggle_line_numbers()
```

## Available Commands

Many utility functions are exposed as user commands:

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