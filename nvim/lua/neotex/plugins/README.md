# NeoVim Plugin Organization

This directory contains plugin specifications and configurations managed by lazy.nvim.

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

- **ui/**: User interface components
  - colorscheme.lua: Theme configuration
  - lualine.lua: Status line
  - bufferline.lua: Buffer line
  - nvim-tree.lua: File explorer
  - nvim-web-devicons.lua: File icons
  - sessions.lua: Session management

- **ai/**: AI tooling and integration ([detailed documentation](ai/README.md))
  - avante.lua: AI assistants integration with 44+ MCP tools
  - claude-code.lua: Official Claude Code integration (coder/claudecode.nvim)
  - lectic.lua: AI-assisted writing
  - mcp-hub.lua: Model Context Protocol hub for external AI tools

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