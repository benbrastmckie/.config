# NeoVim Configuration Optimization Recommendations

Based on the analysis of your current configuration, here are recommendations to improve startup and performance.

## Key Optimization Areas

### 1. Slow Plugins at Startup

Based on the startup analysis, these plugins are taking the most time to load:

1. `nvim-ts-context-commentstring` (2.17ms)
2. `LuaSnip` (2.03ms)
3. `yanky.nvim` (1.20ms)
4. `nvim-treesitter` (0.94ms)
5. `cmp_luasnip` (0.62ms)

### 2. Error with LuaSnip

There's an error in the LuaSnip configuration that should be addressed:
```
Error executing lua callback: ...re/nvim/lazy/LuaSnip/lua/luasnip/loaders/from_vscode.lua:16: attempt to index a number value
```

## Optimization Recommendations

### 1. Lazy-load Context Commentstring

The ts-context-commentstring plugin is only needed when using comments in specific languages.

```lua
-- In lua/neotex/plugins/tools/treesitter.lua
return {
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    lazy = true,
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },
}
```

### 2. Fix and Lazy-load LuaSnip

LuaSnip should only be loaded when entering insert mode or when explicitly using snippets:

```lua
-- In lua/neotex/plugins/tools/luasnip.lua
return {
  {
    "L3MON4D3/LuaSnip",
    lazy = true,
    event = "InsertEnter",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    build = "make install_jsregexp", -- This is important for NixOS
    config = function()
      -- Configuration here
    end,
  },
  {
    "saadparwaiz1/cmp_luasnip",
    lazy = true,
    event = "InsertEnter",
    dependencies = { "L3MON4D3/LuaSnip" },
  },
}
```

### 3. Lazy-load Yanky.nvim

Yanky.nvim can be lazy-loaded when you start yanking text:

```lua
-- In lua/neotex/plugins/editor/yanky.lua
return {
  {
    "gbprod/yanky.nvim",
    lazy = true, 
    event = { "TextYankPost", "CursorMoved" },
    config = function()
      -- Configuration here
    end,
  },
}
```

### 4. Optimize Treesitter

Treesitter is core functionality, but some of its extensions could be lazy-loaded:

```lua
-- In lua/neotex/plugins/tools/treesitter.lua
return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        -- Core modules
        highlight = { enable = true },
        indent = { enable = true },
        
        -- Lazy-loaded modules (through other plugins)
        -- context_commentstring = { enable = true },
        -- autotag = { enable = true },
      })
    end,
  },
  {
    "windwp/nvim-ts-autotag",
    lazy = true,
    ft = { "html", "xml", "jsx", "tsx", "vue", "svelte", "php", "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },
}
```

### 5. Disable Unused Built-in Plugins

Add this to init.lua or core/options.lua to disable built-in plugins you don't use:

```lua
-- Disable built-in plugins you don't use
vim.g.loaded_matchit = 1        -- If you don't use enhanced % matching
vim.g.loaded_tutor_mode_plugin = 1
vim.g.loaded_2html_plugin = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_gzip = 1
```

### 6. Pre-compile Lua Modules

Consider using the lua-language-server to pre-compile frequently used Lua modules:

```lua
-- Add this to your utils/optimize.lua
function M.precompile_modules()
  local modules = {
    "neotex.bootstrap",
    "neotex.utils",
    "neotex.utils.buffer",
    "neotex.utils.fold",
    -- Add other frequently used modules
  }
  
  for _, module in ipairs(modules) do
    -- Force load the module once
    require(module)
  end
end
```

## Implementation Steps

1. First, fix the LuaSnip error - this may simply require ensuring proper dependencies
2. Implement lazy loading for the top slow plugins
3. Test startup time after each change
4. Disable unused built-in plugins
5. Consider structuring more plugins to be loaded on events or commands

Use your new optimization tools to measure the impact of each change:

```
:AnalyzeStartup
:ProfilePlugins
:OptimizationReport
:SuggestLazyLoading
```