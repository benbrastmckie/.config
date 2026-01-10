# Neovim Plugin Ecosystem

## Package Manager: lazy.nvim

lazy.nvim is the modern standard for Neovim plugin management, providing:
- Lazy loading for fast startup
- Automatic dependency resolution
- Lock file for reproducible builds
- UI for plugin management

### Installation
```lua
-- Bootstrap in init.lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
```

## Plugin Categories

### AI Integrations
| Plugin | Purpose | Usage |
|--------|---------|-------|
| avante.nvim | AI pair programming | Chat, code generation |
| copilot.vim | GitHub Copilot | Inline suggestions |
| codecompanion.nvim | AI adapter framework | Multiple backends |

### Editor Enhancements
| Plugin | Purpose | Usage |
|--------|---------|-------|
| telescope.nvim | Fuzzy finder | Files, grep, buffers |
| which-key.nvim | Keymap hints | Leader key menus |
| nvim-treesitter | Syntax parsing | Highlighting, folding |
| flash.nvim | Navigation | Jump to any location |
| mini.surround | Text objects | Surround operations |

### LSP & Completion
| Plugin | Purpose | Usage |
|--------|---------|-------|
| nvim-lspconfig | LSP configuration | Server setup |
| mason.nvim | LSP installer | Server management |
| blink.cmp | Completion | Fast completions |
| nvim-cmp | Completion | Extensible completions |
| luasnip | Snippets | Snippet engine |

### UI Components
| Plugin | Purpose | Usage |
|--------|---------|-------|
| neo-tree.nvim | File explorer | Tree sidebar |
| lualine.nvim | Statusline | Status display |
| bufferline.nvim | Bufferline | Tab-like buffers |
| noice.nvim | UI overhaul | Messages, cmdline |
| dressing.nvim | UI hooks | Input, select |

### Git Integration
| Plugin | Purpose | Usage |
|--------|---------|-------|
| gitsigns.nvim | Git decorations | Signs, hunks |
| diffview.nvim | Diff viewer | Git diffs |
| neogit | Git interface | Magit-like |

### Text & Markdown
| Plugin | Purpose | Usage |
|--------|---------|-------|
| vimtex | LaTeX | Compilation, preview |
| render-markdown.nvim | Markdown | In-editor rendering |
| markview.nvim | Markdown | Preview in buffer |

### Development Tools
| Plugin | Purpose | Usage |
|--------|---------|-------|
| neotest | Testing | Test runner |
| trouble.nvim | Diagnostics | Error list |
| dap | Debugging | Debug adapter |
| todo-comments.nvim | Todo tracking | Highlight todos |

## Plugin Selection Criteria

### Quality Indicators
1. **Active maintenance** - Recent commits, responsive issues
2. **Documentation** - Clear README, help files
3. **Test coverage** - Automated tests
4. **Stars/Usage** - Community adoption
5. **Dependencies** - Minimal, well-maintained

### Performance Considerations
1. **Startup time** - Lazy loading support
2. **Memory usage** - Reasonable footprint
3. **Event handling** - Efficient autocommands
4. **Async operations** - Non-blocking where possible

### Compatibility
1. **Neovim version** - Supports current stable
2. **Integration** - Works with other plugins
3. **Configuration** - Lua-native setup
4. **Breaking changes** - Reasonable update cycle

## Common Plugin Patterns

### Lazy Loading Events
```lua
-- Load on specific event
event = "VeryLazy"        -- After UI ready
event = "BufReadPost"     -- After buffer read
event = { "BufReadPre", "BufNewFile" }

-- Load on command
cmd = "Telescope"

-- Load on keymap
keys = { "<leader>f", desc = "Find" }

-- Load on filetype
ft = { "lua", "python" }
```

### Conditional Loading
```lua
-- Only on certain OS
cond = vim.fn.has("mac") == 1

-- Only if executable exists
cond = vim.fn.executable("rg") == 1

-- Disable in certain contexts
enabled = not vim.g.vscode
```

### Priority
```lua
-- Load before others (colorschemes)
priority = 1000

-- Load after dependencies resolved
dependencies = { "nvim-lua/plenary.nvim" }
```

## Plugin Directory Structure

### Standard Layout
```
plugin-name/
├── lua/
│   └── plugin-name/
│       ├── init.lua      -- Main entry point
│       ├── config.lua    -- Configuration handling
│       ├── commands.lua  -- User commands
│       └── utils.lua     -- Utility functions
├── plugin/
│   └── plugin-name.lua   -- Auto-loaded on startup
├── doc/
│   └── plugin-name.txt   -- Help documentation
├── tests/
│   └── plugin_spec.lua   -- Test files
└── README.md
```

### Minimal Plugin
```lua
-- lua/my-plugin/init.lua
local M = {}

M.setup = function(opts)
  opts = vim.tbl_extend("force", {
    enabled = true,
  }, opts or {})

  if opts.enabled then
    -- Initialize plugin
  end
end

return M
```
