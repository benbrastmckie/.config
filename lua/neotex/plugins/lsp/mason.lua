return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason", -- Only load when the Mason command is run
    event = "VeryLazy", -- Load after startup is complete
    dependencies = {},
    config = function()
      -- Minimal setup for initial loading
      require("mason").setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      })
    end
  },
  {
    "williamboman/mason-lspconfig.nvim",
    event = "VeryLazy", -- Load after startup is complete
    dependencies = { "mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        -- Only list essential servers to install via mason
        ensure_installed = {
          "pyright",
        },
        -- Only install on-demand when needed
        automatic_installation = false,
      })
    end
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    event = "VeryLazy",
    dependencies = { "mason.nvim" },
    config = function() 
      require("mason-tool-installer").setup({
        ensure_installed = {
          "stylua",  -- lua formatter
          "isort",   -- python formatter
          "black",   -- python formatter
          "pylint",  -- python linter
        },
        -- Install tools when needed, not at startup
        auto_update = false,
        run_on_start = false, 
      })
      
      -- Create command to manually trigger installation
      vim.api.nvim_create_user_command("MasonToolsInstall", function()
        require("mason-tool-installer").run_on_start = true
        require("mason-tool-installer").check_install()
      end, {})
    end,
  }
}