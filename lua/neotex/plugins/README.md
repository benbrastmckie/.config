# NeoVim Plugin Organization

This directory contains plugin specifications and configurations managed by lazy.nvim.

## File Structure

```
plugins/
├── README.md           # This documentation
├── init.lua           # Plugin system entry point
├── editor/            # Core editor capabilities
│   ├── formatting.lua # Code formatting
│   ├── linting.lua    # Code linting
│   ├── telescope.lua  # Fuzzy finder
│   └── ...           # Other editor plugins
├── lsp/              # Language server integration
│   ├── blink-cmp.lua # Completion engine
│   ├── lspconfig.lua # LSP configuration
│   └── mason.lua     # LSP server management
├── text/             # Text processing plugins
│   ├── vimtex.lua    # LaTeX support
│   ├── lean.lua      # Lean theorem prover
│   └── jupyter/      # Jupyter integration
├── tools/            # Development tools
│   ├── gitsigns.lua  # Git integration
│   ├── autolist/     # List management
│   └── snacks/       # UI enhancements
├── ui/               # User interface components
│   ├── neo-tree.lua  # File explorer
│   ├── lualine.lua   # Status line
│   └── ...           # Other UI plugins
└── ai/               # AI integration
    ├── avante.lua    # AI assistant
    ├── claude-code.lua # Claude Code integration
    └── util/         # AI utilities
```

## Organization Structure

Plugins are organized into the following categories with dedicated directories:

- **editor/**: Core editor capabilities
  - telescope.lua: Fuzzy finder and navigation
  - treesitter.lua: Syntax highlighting and code navigation
  - toggleterm.lua: Terminal integration
  - formatting.lua: Code formatting with conform.nvim
  - linting.lua: Code linting with nvim-lint
  - which-key.lua: Keybinding help popup

- **tools/**: External tool integration and text manipulation
  - gitsigns.lua: Git integration
  - firenvim.lua: Browser integration
  - vimtex.lua: LaTeX integration
  - lean.lua: Lean theorem prover integration
  - markdown-preview.lua: Markdown preview
  - autolist.lua: Smart list handling for markdown
  - mini.lua: Mini plugins collection (pairs, comments, etc.)
  - surround.lua: Text surrounding functionality
  - todo-comments.lua: Highlight and search TODO comments
  - yanky.lua: Enhanced yank and paste functionality

- **lsp/**: Language server integration ([detailed documentation](lsp/README.md))
  - blink-cmp.lua: Modern high-performance completion engine
  - lspconfig.lua: Base LSP server configuration
  - mason.lua: LSP server and tool management

- **ui/**: User interface components ([detailed documentation](ui/README.md))
  - neo-tree.lua: Modern file explorer with custom delete confirmation
  - lualine.lua: Configurable status line with sections and themes
  - bufferline.lua: Tab-like buffer navigation with visual indicators
  - colorscheme.lua: Theme configuration and color scheme management
  - nvim-web-devicons.lua: File type icons for better visual distinction
  - sessions.lua: Session management for workspace persistence

- **ai/**: AI tooling and integration ([detailed documentation](ai/README.md))
  - avante.lua: AI assistants integration with 44+ MCP tools
  - claude-code.lua: Official Claude Code integration (coder/claudecode.nvim)
  - lectic.lua: AI-assisted writing
  - mcp-hub.lua: Model Context Protocol hub for external AI tools

## Unified Notification System

All plugins integrate with the unified notification system located in `/lua/neotex/util/notifications.lua`. This provides consistent user feedback across all modules while preventing notification spam.

### Key Features
- **Category-based filtering**: ERROR, WARNING, USER_ACTION, STATUS, BACKGROUND
- **Module-specific control**: Configure notifications per plugin category
- **Debug mode**: Toggle detailed notifications for troubleshooting
- **Smart batching**: Prevents notification spam during bulk operations

### Usage in Plugins
```lua
local notify = require('neotex.util.notifications')

-- User action feedback (always shown)
notify.editor('File formatted', notify.categories.USER_ACTION)

-- Background operation (debug mode only)
notify.lsp('Language server connected', notify.categories.BACKGROUND)
```

### Configuration
Control notification behavior per module:
```lua
-- In plugin configurations
local config = require('neotex.config.notifications')
config.modules.lsp.server_status = false  -- Hide LSP connection messages
config.modules.ai.processing = false      -- Hide AI background operations
```

See [complete notification documentation](../docs/NOTIFICATIONS.md) for detailed configuration and usage examples.

## Plugin Structure

Each plugin has its own configuration file in the appropriate category directory. A typical plugin specification follows this pattern:

```lua
-- Example plugin configuration
return {
  "author/plugin-name",
  dependencies = {
    -- Dependencies listed here
  },
  config = function()
    -- Configuration code
  end,
  -- Additional options
}
```

## Plugin Loading

Each category has its own `init.lua` file that:

1. Loads all plugin specifications in that category
2. Handles errors during plugin loading
3. Returns a table of plugin specifications

The main bootstrap.lua file then imports all categories using lazy.nvim's import mechanism.

## Special Subdirectories

- **lsp/**: Language server protocol related plugins
- **jupyter/**: Jupyter notebook integration

## Adding New Plugins

To add a new plugin:

1. Identify the appropriate category for the plugin
2. Create a new file named after the plugin in that category's directory
3. Write the plugin specification following the pattern above
4. Add it to the category's `init.lua` file

## Plugin Documentation

For detailed information about specific plugins, refer to their individual files or visit their GitHub repositories.

## Plugin Analysis and Maintenance

Use the plugin analysis script to verify your configuration and diagnose issues:

```vim
:luafile scripts/check_plugins.lua
```

This script provides:
- **Total plugin count**: Shows how many plugins are currently loaded
- **Category breakdown**: Lists plugins organized by category (editor, lsp, tools, ui, ai)
- **Plugin organization verification**: Ensures plugins are properly categorized
- **Configuration audit**: Helps identify plugin loading issues

**Example output**:
```
Total plugins loaded: 45

Plugins by Category:

EDITOR (8):
  - conform.nvim
  - nvim-lint
  - telescope.nvim
  - nvim-treesitter
  - toggleterm.nvim
  - which-key.nvim

LSP (3):
  - blink.cmp
  - nvim-lspconfig
  - mason.nvim

[... other categories ...]
```

The script is particularly useful:
- **After configuration changes**: Verify plugins load correctly
- **During troubleshooting**: Identify missing or misconfigured plugins
- **For documentation**: Generate current plugin lists
- **Before updates**: Record current plugin state

See [`scripts/README.md`](../../../scripts/README.md) for complete script documentation.

## Navigation

- [Tools Plugins →](tools/README.md)
- [Editor Plugins →](editor/README.md)
- [LSP Configuration →](lsp/README.md)
- [UI Plugins →](ui/README.md)
- [AI Plugins →](ai/README.md)
- [Text Plugins →](text/README.md)
- [Config Documentation →](../config/README.md)
- [← Main Configuration](../../README.md)