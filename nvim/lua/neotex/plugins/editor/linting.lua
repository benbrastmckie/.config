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
    
    -- Helper function to check if a command is available
    local function is_executable(command)
      return vim.fn.executable(command) == 1
    end
    
    -- Initialize linters by filetype
    lint.linters_by_ft = {}
    
    -- Only configure linters that are actually available on the system
    -- Web development
    if is_executable("eslint") then
      lint.linters_by_ft.javascript = { "eslint" }
      lint.linters_by_ft.typescript = { "eslint" }
      lint.linters_by_ft.javascriptreact = { "eslint" }
      lint.linters_by_ft.typescriptreact = { "eslint" }
      lint.linters_by_ft.vue = { "eslint" }
    end
    
    if is_executable("stylelint") then
      lint.linters_by_ft.css = { "stylelint" }
    end
    
    if is_executable("tidy") then
      lint.linters_by_ft.html = { "tidy" }
    end
    
    if is_executable("jsonlint") then
      lint.linters_by_ft.json = { "jsonlint" }
    end
    
    if is_executable("yamllint") then
      lint.linters_by_ft.yaml = { "yamllint" }
    end
    
    -- Python
    if is_executable("pylint") then
      lint.linters_by_ft.python = { "pylint" }
    end
    
    -- Lua
    if is_executable("luacheck") then
      lint.linters_by_ft.lua = { "luacheck" }
    end
    
    -- Shell scripting
    if is_executable("shellcheck") then
      lint.linters_by_ft.sh = { "shellcheck" }
      lint.linters_by_ft.bash = { "shellcheck" }
    end
    
    -- Markdown
    if is_executable("markdownlint") then
      lint.linters_by_ft.markdown = { "markdownlint" }
    end
    
    -- LaTeX
    if is_executable("chktex") then
      lint.linters_by_ft.tex = { "chktex" }
    end
    
    -- C/C++
    if is_executable("cppcheck") then
      lint.linters_by_ft.c = { "cppcheck" }
      lint.linters_by_ft.cpp = { "cppcheck" }
    end
    
    -- Configure linter options only for available linters
    if is_executable("flake8") then
      lint.linters.flake8 = lint.linters.flake8 or {}
      lint.linters.flake8.args = {
        "--max-line-length=88",
        "--extend-ignore=E203",
      }
    end
    
    if is_executable("pylint") then
      lint.linters.pylint = lint.linters.pylint or {}
      lint.linters.pylint.args = {
        "--disable=C0111",
      }
      
      -- Only add pylintrc if it exists
      local pylintrc_path = vim.fn.expand("$HOME/.pylintrc")
      if vim.fn.filereadable(pylintrc_path) == 1 then
        table.insert(lint.linters.pylint.args, "--rcfile=" .. pylintrc_path)
      end
    end
    
    if is_executable("luacheck") then
      lint.linters.luacheck = lint.linters.luacheck or {}
      lint.linters.luacheck.args = {
        "--globals=vim",
        "--no-max-line-length",
      }
    end
    
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