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
      -- "prettier", -- prettier formatter
      "stylua",   -- lua formatter
      "isort",    -- python formatter
      "black",    -- python formatter
      "pylint",   -- python linter
      -- "eslint_d", -- js linter
    })

    -- for conciseness
    local null_ls = require("null-ls")
    local null_ls_utils = require("null-ls.utils")
    local formatting = null_ls.builtins.formatting   -- to setup formatters
    local diagnostics = null_ls.builtins.diagnostics -- to setup linters

    -- to setup format on save
    -- local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

    -- configure null_ls
    null_ls.setup({
      -- add package.json as identifier for root (for typescript monorepos)
      root_dir = null_ls_utils.root_pattern(".null-ls-root", "Makefile", ".git", "package.json"),
      -- setup formatters & linters
      sources = {
        --  to disable file types use
        --  "formatting.prettier.with({disabled_filetypes: {}})" (see null-ls docs)
        -- formatting.prettier.with({ TURN ON FOR JAVA SCRIPT
        --   extra_filetypes = { "svelte" },
        --   disabled_filetypes = { "txt" },
        -- }),                -- js/ts formatter
        formatting.stylua, -- lua formatter
        formatting.isort,
        formatting.black,
        diagnostics.pylint,
        -- .with({
        --   extra_args = { "--config-path", vim.fn.expand("~/.nix-profile/bit/z3") },
        -- }),
        -- diagnostics.eslint_d.with({ -- TURN ON FOR JAVA SCRIPT
        --   -- js/ts linter
        --   condition = function(utils)
        --     return utils.root_has_file({ ".eslintrc.js", ".eslintrc.cjs" }) -- only enable if root has .eslintrc.js or .eslintrc.cjs
        --   end,
        -- }),
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
