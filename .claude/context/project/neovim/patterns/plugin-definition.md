# Plugin Definition Patterns

## lazy.nvim Plugin Spec

### Basic Spec Structure
```lua
return {
  "author/plugin-name",           -- Required: plugin repo
  dependencies = {},              -- Optional: plugin dependencies
  event = nil,                    -- Optional: lazy loading event
  cmd = nil,                      -- Optional: lazy loading command
  ft = nil,                       -- Optional: filetype trigger
  keys = nil,                     -- Optional: keymap trigger
  opts = {},                      -- Optional: plugin options
  config = function(_, opts) end, -- Optional: configuration function
}
```

### Complete Spec Example
```lua
return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  cmd = "Telescope",
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
    { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
  },
  opts = {
    defaults = {
      sorting_strategy = "ascending",
      layout_config = {
        horizontal = { prompt_position = "top" },
      },
    },
  },
  config = function(_, opts)
    require("telescope").setup(opts)
    require("telescope").load_extension("fzf")
  end,
}
```

## Lazy Loading Strategies

### Event-Based Loading
```lua
-- Load after UI is ready
event = "VeryLazy"

-- Load when reading a buffer
event = "BufReadPost"

-- Load before reading (for file operations)
event = "BufReadPre"

-- Multiple events
event = { "BufReadPost", "BufNewFile" }

-- Load on insert mode
event = "InsertEnter"
```

### Command-Based Loading
```lua
-- Single command
cmd = "Telescope"

-- Multiple commands
cmd = { "Telescope", "TelescopePrompt" }
```

### Keymap-Based Loading
```lua
-- Simple keymap
keys = { "<leader>f" }

-- Keymap with description
keys = {
  { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
}

-- Mode-specific keymap
keys = {
  { "<leader>y", '"+y', mode = { "n", "v" }, desc = "Yank to clipboard" },
}

-- Keymap with callback
keys = {
  {
    "<leader>fb",
    function()
      require("telescope.builtin").buffers()
    end,
    desc = "Find Buffers",
  },
}
```

### Filetype-Based Loading
```lua
-- Single filetype
ft = "lua"

-- Multiple filetypes
ft = { "lua", "vim" }
```

## Dependency Declaration

### Simple Dependencies
```lua
dependencies = { "nvim-lua/plenary.nvim" }
```

### Dependencies with Config
```lua
dependencies = {
  {
    "nvim-tree/nvim-web-devicons",
    opts = { default = true },
  },
}
```

### Optional Dependencies
```lua
dependencies = {
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
    cond = vim.fn.executable("make") == 1,
  },
}
```

## Configuration Patterns

### opts Only (Simple)
```lua
return {
  "author/plugin-name",
  opts = {
    option = "value",
  },
  -- lazy.nvim calls require("plugin-name").setup(opts) automatically
}
```

### opts with config (Custom Setup)
```lua
return {
  "author/plugin-name",
  opts = {
    option = "value",
  },
  config = function(_, opts)
    -- Custom configuration before setup
    opts.extra = "added"

    require("plugin-name").setup(opts)

    -- Post-setup configuration
    vim.keymap.set("n", "<leader>x", "<cmd>PluginCommand<cr>")
  end,
}
```

### config Only (Full Control)
```lua
return {
  "author/plugin-name",
  config = function()
    -- Complete custom configuration
    local plugin = require("plugin-name")

    plugin.setup({
      -- options
    })

    -- Additional setup
  end,
}
```

### init (Pre-Load)
```lua
return {
  "author/plugin-name",
  init = function()
    -- Runs BEFORE plugin is loaded
    -- Use for global variables, etc.
    vim.g.plugin_setting = "value"
  end,
}
```

## Priority and Order

### High Priority (Colorschemes)
```lua
return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,  -- Load before other plugins
  config = function()
    vim.cmd.colorscheme("catppuccin")
  end,
}
```

### Conditional Loading
```lua
return {
  "author/plugin-name",
  cond = function()
    return vim.fn.executable("required_tool") == 1
  end,
  -- or simply
  cond = not vim.g.vscode,
  enabled = vim.fn.has("nvim-0.10") == 1,
}
```

## Build Commands

### Shell Command
```lua
build = "make"
build = "npm install"
```

### Lua Function
```lua
build = function()
  require("plugin-name").build()
end
```

### Neovim Command
```lua
build = ":TSUpdate"
```

## Multi-File Plugin Specs

### Category init.lua
```lua
-- lua/neotex/plugins/editor/init.lua
return {
  require("neotex.plugins.editor.telescope"),
  require("neotex.plugins.editor.which-key"),
  require("neotex.plugins.editor.flash"),
}
```

### Alternative: Glob Pattern
```lua
-- In lazy.nvim setup
require("lazy").setup({
  spec = {
    { import = "neotex.plugins.editor" },
    { import = "neotex.plugins.ui" },
  },
})
```

## Common Patterns

### Colorscheme with Lazy Loading
```lua
return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false,     -- Load immediately
  priority = 1000,  -- Before other plugins
  config = function()
    require("catppuccin").setup({
      flavour = "mocha",
    })
    vim.cmd.colorscheme("catppuccin")
  end,
}
```

### LSP with Mason
```lua
return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
  },
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("mason").setup()
    require("mason-lspconfig").setup({
      ensure_installed = { "lua_ls", "pyright" },
    })
    -- Configure servers...
  end,
}
```
