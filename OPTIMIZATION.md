# NeoVim Configuration Optimization

This document consolidates the results of our optimization efforts and provides additional recommendations for further improving your NeoVim configuration.

## Latest Analysis

**Startup Analysis (May 2025):**
- **Current startup time:** 105.90 ms
- **Main bottlenecks:**
  - matchit.vim: Previously consuming significant startup time (91.32 ms)
  - LSP-related plugins (nvim-lspconfig, mason-lspconfig, cmp-nvim-lsp): ~458 ms combined
  - UI components (lualine, bufferline): ~103 ms combined
  - Treesitter: ~77 ms

## Optimizations Implemented

| Status | Task |
|--------|------|
| ✅ COMPLETED | Fix matchit.vim loading issue by disabling at top of init.lua |
| ✅ COMPLETED | Optimize LuaSnip lazy loading |
| ✅ COMPLETED | Improve bufferline lazy loading |
| ✅ COMPLETED | Disable unused built-in plugins |
| ✅ COMPLETED | Add general performance settings |

## New Optimization Priorities

Based on the plugin profiling analysis, these are the highest-priority optimizations to implement next:

### 1. Optimize LSP Loading (~458ms total)

The LSP configuration is the single biggest contributor to startup time, consuming nearly 460ms combined. Implement the following optimizations:

```lua
-- In lua/neotex/plugins/lsp/lspconfig.lua
return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" }, -- Only load when a file is opened
  dependencies = {
    "mason.nvim",
    "mason-lspconfig.nvim"
  },
  config = function()
    -- Minimal initial configuration
    local lspconfig = require("lspconfig")
    
    -- Define LSP capabilities
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
    
    -- Define on_attach function to set up keymaps only when an LSP attaches
    local on_attach = function(client, bufnr)
      -- Set up buffer-local keymaps, etc.
      -- (your existing on_attach code)
    end
    
    -- Only set up commonly used LSPs immediately
    -- Other servers will be set up on demand when their filetypes are loaded
    local common_servers = { "lua_ls" }
    
    for _, server in ipairs(common_servers) do
      lspconfig[server].setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })
    end
    
    -- Defer less common servers setup to reduce startup time
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "python", "javascript", "typescript", "rust", "go" },
      callback = function()
        local ft = vim.bo.filetype
        -- Map filetype to server name if needed
        local server_map = {
          -- Add mappings as needed
        }
        local server = server_map[ft] or ft
        
        -- Skip if already set up or not available
        if not lspconfig[server] then return end
        
        -- Set up the server
        lspconfig[server].setup({
          capabilities = capabilities,
          on_attach = on_attach,
        })
      end,
      once = true, -- Only set up each server once
    })
  end
}

-- In lua/neotex/plugins/lsp/mason.lua
return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason", -- Only load when the Mason command is run
    event = "VeryLazy", -- Load after startup is complete
    config = function()
      require("mason").setup()
    end
  },
  {
    "williamboman/mason-lspconfig.nvim",
    event = "VeryLazy", -- Load after startup is complete
    dependencies = { "mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        -- Your existing configuration
      })
    end
  }
}

-- In lua/neotex/plugins/lsp/nvim-cmp.lua
return {
  "hrsh7th/nvim-cmp",
  event = { "InsertEnter", "CmdlineEnter" }, -- Only load when entering insert mode
  dependencies = {
    { "hrsh7th/cmp-buffer", event = "InsertEnter" },
    { "hrsh7th/cmp-path", event = "InsertEnter" },
    { "hrsh7th/cmp-cmdline", event = "CmdlineEnter" },
    { "hrsh7th/cmp-nvim-lsp", event = "InsertEnter" },
    { "saadparwaiz1/cmp_luasnip", event = "InsertEnter" },
    -- Other sources
  },
  config = function()
    -- Minimal initial setup
    local cmp = require("cmp")
    
    cmp.setup({
      -- Minimal configuration for initial load
      preselect = cmp.PreselectMode.None,
      -- Your essential settings
    })
    
    -- Defer full configuration
    vim.defer_fn(function()
      cmp.setup({
        -- Your full configuration
      })
    end, 50)
  end
}
```

### 2. Optimize Treesitter (~77ms)

Treesitter can be lazy-loaded for better startup performance:

```lua
-- In lua/neotex/plugins/editor/treesitter.lua
return {
  {
    "nvim-treesitter/nvim-treesitter", 
    event = { "BufReadPost", "BufNewFile" }, -- Load when a buffer is read
    build = ":TSUpdate",
    config = function() 
      -- Load only essential modules initially
      require("nvim-treesitter.configs").setup({
        ensure_installed = {}, -- Don't install any at startup
        auto_install = true,  -- Install on-demand when needed
        highlight = {
          enable = true,
          disable = {}, -- Languages to disable highlighting for
          additional_vim_regex_highlighting = false,
        },
        -- Defer loading other modules
      })
      
      -- Install commonly used parsers after startup completes
      vim.defer_fn(function()
        vim.cmd("TSInstall lua vim")
      end, 500)
    end,
  },
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    event = { "BufReadPost" }, -- Load after treesitter
    dependencies = { "nvim-treesitter" },
  }
}
```

### 3. Optimize UI Components (~103ms)

UI components like Lualine and Bufferline can be loaded after startup:

```lua
-- In lua/neotex/plugins/ui/lualine.lua
return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy", -- Load after startup is complete
  dependencies = { "nvim-web-devicons" },
  config = function()
    -- Minimal initial configuration
    require("lualine").setup({
      options = {
        icons_enabled = false, -- Disable icons initially for faster load
        component_separators = "",
        section_separators = "",
      }
    })
    
    -- Set full configuration after short delay
    vim.defer_fn(function()
      require("lualine").setup({
        -- Your full configuration
      })
    end, 200)
  end
}

-- In lua/neotex/plugins/ui/bufferline.lua (already optimized)
return {
  "akinsho/bufferline.nvim",
  lazy = true,
  event = "VeryLazy", -- Load after startup is complete
  dependencies = { "nvim-web-devicons" },
  config = function()
    -- Minimal initial configuration
    require("bufferline").setup({
      options = {
        always_show_bufferline = false,
        -- Minimal options
      },
    })
    
    -- Full configuration after delay
    vim.defer_fn(function() 
      require("bufferline").setup({
        -- Your full configuration
      })
    end, 200)
  end
}
```

## Additional Optimizations ⏳

These optimizations provide smaller improvements but are still worth implementing:

### 1. Add Filetype-Based Loading for Heavy Plugins

Some plugins should only load for specific filetypes:

```lua
-- For plugins that are only used with specific filetypes
{
  "lervag/vimtex",
  ft = { "tex", "latex" },
},
{
  "nvim-neorg/neorg",
  ft = "norg",
},
```

### 2. Use Command-Based Loading for Utility Plugins

For plugins that are only used when a specific command is run:

```lua
-- For utility plugins
{
  "nvim-telescope/telescope.nvim",
  cmd = "Telescope",
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
    { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Find Text" },
  },
},
{
  "folke/trouble.nvim",
  cmd = { "Trouble", "TroubleToggle" },
},
```

### 3. Add Module Preloading for Essentials

To reduce latency while preserving fast startup:

```lua
-- In lua/neotex/config/init.lua
local M = {}

function M.setup()
  -- Load essential modules normally
  
  -- Preload key modules after startup completion
  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
      vim.defer_fn(function()
        -- Preload commonly used modules
        require("nvim-treesitter")
        require("telescope._extensions")
        -- Other frequently used modules
      end, 500)
    end
  })
end

return M
```

## Implementation Plan

1. **Immediate Actions:**
   - Optimize LSP configuration (highest impact)
   - Optimize Treesitter (second highest impact)
   - Ensure UI components are properly lazy-loaded

2. **Second Phase:**
   - Add filetype-specific loading for specialized plugins
   - Implement command-based loading for utility plugins
   - Fine-tune lazy-loading triggers for remaining plugins

3. **Monitoring:**
   - Run `:AnalyzeStartup` after each change to measure impact
   - Run `:ProfilePlugins` to validate plugin load times
   - Adjust lazy-loading strategies for any plugins still loading at startup

## Best Practices for Ongoing Maintenance

1. Use event-based loading for plugins needed shortly after startup
2. Use key-based loading for plugins triggered by specific key mappings
3. Use command-based loading for plugins with commands you run manually
4. Use filetype-based loading for language-specific plugins
5. Regularly check startup time to catch performance regressions

With these optimizations, startup time should decrease significantly, potentially below 50ms, while maintaining all functionality.