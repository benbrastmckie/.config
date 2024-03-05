return {
  "williamboman/mason.nvim",
  ft ={ "py", "html", "js", "ts", "lua" },
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
  },

  config = function()
    -- import mason
    local mason = require("mason")

    -- import mason-lspconfig
    local mason_lspconfig = require("mason-lspconfig")

    -- import mason-tool-installer
    local mason_tool_installer = require("mason-tool-installer")

    -- enable mason and configure icons
    mason.setup({
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    })

    mason_lspconfig.setup({
      -- list of servers for mason to install
      ensure_installed = {
        -- "html",
        -- "emmet_ls",
        "pyright",
        -- "tsserver",
        -- "lua_ls",   -- seems to cause trouble
        -- "cssls",
        -- "tailwindcss",
        -- "svelte"
        -- "graphql",
        -- "prismals",
      },
      -- auto-install configured servers (with lspconfig)
      automatic_installation = true, -- not the same as ensure_installed
    })

    mason_tool_installer.setup({
      ensure_installed = {
        -- "prettier", -- prettier formatter seems to be required
        "stylua",   -- lua formatter
        "isort",    -- python formatter
        "black",    -- python formatter
        "pylint",   -- python linter
        -- "eslint_d", -- js linter
      },
    })
  end,
}
