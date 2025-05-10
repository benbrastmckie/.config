-----------------------------------------------------------
-- Nvim-lint Integration
-- 
-- This module configures nvim-lint for code linting:
-- - Provides filetype-specific linters
-- - Configures key mappings for linting
-- - Supports lint-on-save functionality
-- - Integrates with quickfix and diagnostics
--
-- Nvim-lint is an asynchronous linter plugin for Neovim that works
-- with a variety of linters to maintain code quality.
-----------------------------------------------------------

return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  keys = {
    { "<leader>l", function() require("lint").try_lint() end, desc = "Lint current file" },
  },
  config = function()
    local lint = require("lint")
    
    -- Configure linters for different file types
    lint.linters_by_ft = {
      -- Web development
      javascript = { "eslint" },
      typescript = { "eslint" },
      javascriptreact = { "eslint" },
      typescriptreact = { "eslint" },
      vue = { "eslint" },
      css = { "stylelint" },
      html = { "tidy" },
      json = { "jsonlint" },
      yaml = { "yamllint" },
      
      -- Python
      python = { "flake8", "pylint" },
      
      -- Lua
      lua = { "luacheck" },
      
      -- Shell scripting
      sh = { "shellcheck" },
      bash = { "shellcheck" },
      
      -- Markdown
      markdown = { "markdownlint" },
      
      -- LaTeX
      tex = { "chktex" },
      
      -- C/C++
      c = { "cppcheck" },
      cpp = { "cppcheck" },
    }
    
    -- Configure linter options
    lint.linters.flake8.args = {
      "--max-line-length=88",
      "--extend-ignore=E203",
    }
    
    lint.linters.pylint.args = {
      "--rcfile=" .. vim.fn.expand("$HOME/.pylintrc"),
      "--disable=C0111",
    }
    
    lint.linters.luacheck.args = {
      "--globals=vim",
      "--no-max-line-length",
    }
    
    -- Helper function to run linters
    _G.lint_try_lint = function()
      -- Try to detect if we're in a Git repository with ESLint configuration
      local is_git_repo = vim.fn.system("git rev-parse --is-inside-work-tree 2>/dev/null"):match("true")
      
      if is_git_repo and vim.fn.glob(".eslintrc*") ~= "" then
        -- Use ESLint for all JavaScript-like files in this repository
        if vim.bo.filetype:match("javascript") or vim.bo.filetype:match("typescript") then
          lint.try_lint("eslint")
          return
        end
      end
      
      -- Otherwise, use the regular linting logic
      lint.try_lint()
    end
    
    -- Set up autocommands for running linters
    vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter" }, {
      callback = function()
        -- Get a list of filetypes that should be automatically linted
        local auto_lint_filetypes = {
          "python",
          "lua",
          "javascript",
          "typescript",
          "javascriptreact",
          "typescriptreact",
        }
        
        -- Check if auto-linting is disabled
        if vim.g.disable_autolint == true then
          return
        end
        
        -- Check if auto-linting is disabled for this buffer
        if vim.b.disable_autolint == true then
          return
        end
        
        -- Check if the current buffer's filetype should be auto-linted
        local filetype = vim.bo.filetype
        if vim.tbl_contains(auto_lint_filetypes, filetype) then
          _G.lint_try_lint()
        end
      end,
    })
    
    -- Add user commands for controlling linting
    vim.api.nvim_create_user_command("LintToggle", function(args)
      local is_enabled = false
      if args.args == "buffer" then
        -- Toggle for current buffer
        if vim.b.disable_autolint == true then
          vim.b.disable_autolint = false
          is_enabled = true
        else
          vim.b.disable_autolint = true
          is_enabled = false
        end
        
        vim.notify(
          string.format("Auto-linting %s for this buffer", is_enabled and "enabled" or "disabled"),
          vim.log.levels.INFO
        )
      else
        -- Toggle globally
        if vim.g.disable_autolint == true then
          vim.g.disable_autolint = false
          is_enabled = true
        else
          vim.g.disable_autolint = true
          is_enabled = false
        end
        
        vim.notify(
          string.format("Auto-linting %s globally", is_enabled and "enabled" or "disabled"),
          vim.log.levels.INFO
        )
      end
    end, {
      nargs = "?",
      complete = function()
        return { "buffer" }
      end,
      desc = "Toggle auto-linting",
    })
    
    -- LSP diagnostics integration
    vim.diagnostic.config({
      virtual_text = true,
      signs = true,
      underline = true,
      update_in_insert = false,
      severity_sort = true,
    })
  end,
}