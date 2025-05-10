# NeoVim Plugin Organization

This directory contains plugin specifications and configurations managed by lazy.nvim.

## Organization Structure

Plugins are now organized into the following categories with dedicated directories:

- **coding/**: Code editing enhancements
  - mini.nvim modules (pairs, surround, comment, cursorword, ai, splitjoin, align, diff)
  - More coding enhancement plugins to be added

- **editor/**: Core editor capabilities
  - yanky.nvim: Enhanced clipboard functionality
  - More editing plugins to be added

- **extras/**: Optional functionality
  - todo-comments.nvim: Enhanced TODO comment management
  - conform.nvim: Code formatting
  - nvim-lint: Code linting
  - More extra plugins to be added

- **lsp/**: Language server integration
  - nvim-lspconfig: Base LSP configuration
  - mason.nvim: LSP server management
  - null-ls: Additional LSP functionality
  - nvim-cmp: Completion engine
  - Various completion sources

- **tools/**: External tool integration
  - toggleterm.lua: Terminal integration
  - gitsigns.lua: Git integration
  - telescope.lua: Fuzzy finder
  - treesitter.lua: Syntax highlighting and code navigation
  - firenvim.lua: Browser integration
  - vimtex.lua: LaTeX integration
  - lean.lua: Lean theorem prover integration
  - avante.lua: AI integration
  - lectic.lua: AI-assisted writing
  - More tool integrations

- **ui/**: User interface components
  - colorscheme.lua: Theme configuration
  - lualine.lua: Status line
  - bufferline.lua: Buffer line
  - nvim-tree.lua: File explorer
  - nvim-web-devicons.lua: File icons
  - More UI enhancements

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