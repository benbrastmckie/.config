# lazy.nvim Package Manager

## Overview
lazy.nvim is the modern standard Neovim plugin manager, providing lazy loading, dependency management, and a UI for plugin management.

## Installation

### Bootstrap in init.lua
```lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { import = "neotex.plugins" },
  },
  defaults = {
    lazy = true,
  },
})
```

## Configuration

### Setup Options
```lua
require("lazy").setup({
  spec = {
    { import = "neotex.plugins" },
  },
  defaults = {
    lazy = true,            -- Lazy load by default
    version = false,        -- Use latest commits
  },
  install = {
    colorscheme = { "catppuccin", "habamax" },
  },
  checker = {
    enabled = true,         -- Check for updates
    frequency = 86400,      -- Check daily
  },
  change_detection = {
    enabled = true,         -- Reload on config change
    notify = false,         -- Don't notify
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
```

### Plugin Spec Loading
```lua
-- Import all files in directory
{ import = "neotex.plugins" }

-- Import specific subdirectories
{ import = "neotex.plugins.editor" }
{ import = "neotex.plugins.lsp" }

-- Direct plugin specs
{ "author/plugin-name", opts = {} }
```

## Plugin Spec Format

### Full Spec Reference
```lua
{
  "author/plugin-name",       -- Plugin repository

  -- Loading
  lazy = true,                -- Don't load on startup
  priority = 50,              -- Load order (higher = earlier)
  event = "VeryLazy",         -- Load on event
  cmd = "Command",            -- Load on command
  ft = "lua",                 -- Load on filetype
  keys = {},                  -- Load on keymap

  -- Dependencies
  dependencies = {},          -- Required plugins

  -- Configuration
  init = function() end,      -- Before plugin loads
  opts = {},                  -- Plugin options (passed to config)
  config = function() end,    -- After plugin loads

  -- Build/Install
  build = "make",             -- Build command
  version = "*",              -- Version constraint

  -- Conditions
  cond = true,                -- Load condition
  enabled = true,             -- Enable/disable
}
```

## Lock Files

### lazy-lock.json
Located at `~/.config/nvim/lazy-lock.json`, tracks exact commits:

```json
{
  "telescope.nvim": {
    "branch": "master",
    "commit": "abc123..."
  }
}
```

### Commands
```vim
:Lazy restore        " Restore to lock file versions
:Lazy update         " Update plugins (and lock file)
:Lazy sync          " Install, update, and clean
```

## UI Commands

### Main Commands
| Command | Description |
|---------|-------------|
| `:Lazy` | Open lazy.nvim UI |
| `:Lazy install` | Install missing plugins |
| `:Lazy update` | Update plugins |
| `:Lazy sync` | Install, clean, update |
| `:Lazy clean` | Remove unused plugins |
| `:Lazy restore` | Restore to lock file |
| `:Lazy profile` | Show load times |
| `:Lazy health` | Health check |

### UI Navigation
| Key | Action |
|-----|--------|
| `<CR>` | Show details |
| `i` | Install |
| `u` | Update |
| `x` | Clean |
| `r` | Restore |
| `p` | Profile |
| `q` | Close |

## Lazy Loading Triggers

### Events
```lua
-- Most common
event = "VeryLazy"                    -- After UI ready
event = "BufReadPost"                 -- After buffer read
event = { "BufReadPre", "BufNewFile" } -- Before read or new

-- Insert mode
event = "InsertEnter"

-- Command line
event = "CmdlineEnter"

-- Any event
event = "User MyEvent"                -- Custom user event
```

### Commands
```lua
-- Single command
cmd = "Telescope"

-- Multiple commands
cmd = { "Telescope", "TelescopeLiveGrep" }
```

### Keys
```lua
-- Simple
keys = { "<leader>f" }

-- With config
keys = {
  { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
  { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
}
```

### Filetypes
```lua
ft = "lua"
ft = { "lua", "vim" }
```

## Performance Optimization

### Disable Built-in Plugins
```lua
performance = {
  rtp = {
    disabled_plugins = {
      "2html_plugin",
      "getscript",
      "getscriptPlugin",
      "gzip",
      "logipat",
      "matchit",
      "netrw",
      "netrwPlugin",
      "netrwSettings",
      "netrwFileHandlers",
      "tar",
      "tarPlugin",
      "tohtml",
      "tutor",
      "vimball",
      "vimballPlugin",
      "zip",
      "zipPlugin",
    },
  },
},
```

### Profiling
```vim
:Lazy profile
```

Shows:
- Load time per plugin
- Load order
- Event triggers

### Reducing Startup
1. Use `event = "VeryLazy"` for UI plugins
2. Use `cmd = "..."` for infrequent commands
3. Use `keys = {}` for keymapped plugins
4. Use `ft = "..."` for filetype plugins
5. Avoid `lazy = false` unless necessary

## Troubleshooting

### Force Reinstall
```vim
:Lazy clean
:Lazy install
```

### Check Plugin Status
```vim
:Lazy
```
Look for plugins with issues (marked with warning icons).

### Debug Loading
```lua
-- Add to plugin spec
config = function()
  print("Plugin loaded!")
  require("plugin").setup()
end
```

### Health Check
```vim
:Lazy health
:checkhealth lazy
```

## Directory Structure
```
~/.local/share/nvim/lazy/      -- Plugin installations
~/.config/nvim/lazy-lock.json  -- Lock file
~/.cache/nvim/                 -- Cache directory
```
