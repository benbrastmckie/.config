-- [null-ls] failed to run generator: ...y/none-ls.nvim/lua/null-ls/helpers generator_factory.lua:73: failed to decode json: Expected value but found inva lid token at character 1  

return {
  "nvimtools/none-ls.nvim",               -- configure formatters & linters
  lazy = true,
  ft ={ "py", "html", "js", "ts", "lua" },
  event = { "BufReadPre", "BufNewFile" }, -- to enable uncomment this
  dependencies = {
    "jay-babu/mason-null-ls.nvim",
    "williamboman/mason.nvim",
    -- "MunifTanjim/prettier.nvim",
  },
  config = function()
    local mason_null_ls = require("mason-null-ls")
    mason_null_ls.setup({
      ensure_installed = {
        "stylua",   -- lua formatter
        "isort",    -- python formatter
        "black",    -- python formatter
        "pylint",   -- python linter
      },
      automatic_installation = true,
      handlers = {},
    })

    -- for conciseness
    local null_ls = require("null-ls")
    local null_ls_utils = require("null-ls.utils")
    local formatting = null_ls.builtins.formatting   -- to setup formatters
    local diagnostics = null_ls.builtins.diagnostics -- to setup linters

    -- to setup format on save
    -- local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

    -- configure null_ls
    -- Add debug logging
    null_ls.setup({
      debug = true,
      log = {
        enable = true,
        level = "trace",
        use_console = false,
      },
      root_dir = null_ls_utils.root_pattern(".null-ls-root", "Makefile", ".git", "package.json"),
      sources = {
        -- Lua
        -- formatting.stylua, -- instead of below
        formatting.stylua.with({
          extra_args = {
            "--quote-style", "AutoPreferDouble",
            "--indent-type", "Spaces",
            "--indent-width", "2",
          },
        }),
        -- Python
        -- formatting.isort, -- instead of below
        formatting.isort.with({
          extra_args = { "--profile", "black" },
        }),
        -- formatting.black, -- instead of below
        formatting.black.with({
          extra_args = { "--fast", "--line-length", "88" },
        }),
        -- diagnostics.pylint, -- instead of below
        diagnostics.pylint.with({
          extra_args = {
            "--output-format=text",
            "--msg-template={line}:{column}:{category}:{msg}",
            "--score=no",
          },
          diagnostics_format = "#{m} (#{c})",
        }),
      },
      -- -- configure format on save: uncomment augroup above
      -- on_attach = function(current_client, bufnr)
      --   if current_client.supports_method("textDocument/formatting") then
      --     vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
      --     vim.api.nvim_create_autocmd("BufWritePre", {
      --       group = augroup,
      --       buffer = bufnr,
      --       callback = function()
      --         vim.lsp.buf.format({
      --            -- only use null-ls for formatting instead of lsp server
      --           filter = function(client)
      --             return client.name == "null-ls"
      --           end,
      --           async = false
      --         })
      --       end,
      --     })
      --   end
      -- end,
    })
  end,
}
