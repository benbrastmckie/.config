-----------------------------------------------------------
-- Todo Comments Plugin
-- 
-- This module configures todo-comments.nvim for enhanced TODO highlighting
-- and navigation. It provides:
-- - Syntax highlighting for TODO, HACK, NOTE, FIX, WARNING etc.
-- - Integration with Telescope for searching TODOs
-- - Keymappings for navigating between TODOs
-- - Custom colors for different comment types
--
-- The plugin uses treesitter for accurate comment detection across
-- many languages and formats.
-----------------------------------------------------------

return {
  'folke/todo-comments.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
  },
  event = { 'BufReadPost', 'BufNewFile' },
  cmd = { 'TodoTelescope', 'TodoQuickFix', 'TodoLocList', 'TodoTrouble' },
  keys = {
    { "]t", function() require("todo-comments").jump_next() end, desc = "Next todo comment" },
    { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous todo comment" },
  },
  config = function()
    require('todo-comments').setup({
      signs = true, -- Show icons in the signs column
      sign_priority = 8, -- Sign priority
      
      -- Keywords recognized as todo comments
      keywords = {
        FIX = {
          icon = " ", -- Icon used for the sign
          color = "error", -- Can be a hex color, or a named color
          alt = { "FIXME", "BUG", "FIXIT", "ISSUE" }, -- Alternative keywords for the same group
        },
        TODO = { icon = " ", color = "info" },
        HACK = { icon = " ", color = "warning" },
        WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
        PERF = { icon = " ", color = "default", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
        NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
        TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
      },
      
      -- Highlight groups (colors)
      colors = {
        error = { "DiagnosticError", "ErrorMsg", "#DC2626" },
        warning = { "DiagnosticWarning", "WarningMsg", "#FBBF24" },
        info = { "DiagnosticInfo", "#2563EB" },
        hint = { "DiagnosticHint", "#10B981" },
        default = { "Identifier", "#7C3AED" },
        test = { "Identifier", "#FF00FF" },
      },
      
      -- Patterns used to match comments
      patterns = {
        { pattern = [[(KEYWORDS)\s*:]], }, -- TODO: make this work
        { pattern = [[(KEYWORDS)\s*]], }, -- TODO make this work
        { pattern = [[^\s*(KEYWORDS):]], }, -- At the beginning of line
        { pattern = [[^\s*(KEYWORDS)\s]], }, -- At the beginning of line
      },
      
      -- How comments are displayed in the list
      format = {
        -- Set to nil to use default
        -- FIX = { icon = icon, color = "error" },
        -- TODO = { icon = icon, color = "info" },
        -- HACK = { icon = icon, color = "warning" },
        -- WARN = { icon = icon, color = "warning" },
        -- PERF = { icon = icon, color = "default" },
        -- NOTE = { icon = icon, color = "hint" },
        -- TEST = { icon = icon, color = "test" },
      },
      
      -- LSP integration
      lsp_client_names = { 
        "null-ls", 
      },
      
      -- Merge keywords from LSP diagnostics sources
      merge_keywords = true,
      
      -- Highlighting of the line containing the todo comment
      highlight = {
        multiline = true, -- Enable multine todo comments
        multiline_pattern = "^.", -- Start the pattern for the multiline match
        multiline_context = 10, -- Extra lines that will be re-evaluated
        
        -- Pattern to match within the comment
        pattern = [[.*<(KEYWORDS)\s*:]], -- []:
        
        -- Boolean or virtual text provider to use
        comments_only = true, -- Only apply to comments
      },
      
      -- List of named colors
      colors = {
        error = { "DiagnosticError", "ErrorMsg", "#DC2626" },
        warning = { "DiagnosticWarn", "WarningMsg", "#FBBF24" },
        info = { "DiagnosticInfo", "#2563EB" },
        hint = { "DiagnosticHint", "#10B981" },
        default = { "Identifier", "#7C3AED" },
        test = { "Identifier", "#FF00FF" }
      },
      
      -- Use built-in search
      search = {
        command = "rg",
        args = {
          "--color=never",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
        },
        -- Regex that will be used to match keywords.
        pattern = [[\b(KEYWORDS):]], -- ripgrep regex
      },
    })
    
    -- Add Telescope integration
    local has_telescope, telescope = pcall(require, "telescope")
    if has_telescope then
      telescope.load_extension("todo-comments")
    end
    
    -- Add which-key mappings
    local has_which_key, which_key = pcall(require, "which-key")
    if has_which_key then
      which_key.register({
        ["<leader>ft"] = { "<cmd>TodoTelescope<CR>", "Find TODOs" },
      })
      
      which_key.register({
        t = {
          name = "TODO",
          t = { "<cmd>TodoTelescope<CR>", "Find TODOs" },
          n = { function() require("todo-comments").jump_next() end, "Next TODO" },
          p = { function() require("todo-comments").jump_prev() end, "Previous TODO" },
          l = { "<cmd>TodoLocList<CR>", "TODOs in location list" },
          q = { "<cmd>TodoQuickFix<CR>", "TODOs in quickfix list" },
        },
      }, { prefix = "<leader>" })
    end
  end,
}