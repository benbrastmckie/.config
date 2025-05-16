-----------------------------------------------------------
-- Git Signs Plugin Configuration
--
-- This module configures gitsigns.nvim to show git status indicators
-- in the sign column. Features:
-- - Minimalistic vertical lines for added/changed/deleted lines
-- - Consistent sign appearance across different change types
-- - Clear distinction for different types of changes
-- - Integration with git commands via keybindings
-----------------------------------------------------------

return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("gitsigns").setup({
      signs = {
        -- Using minimal vertical bar for most changes
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "▎" },
        topdelete = { text = "▎" },
        changedelete = { text = "▎" },
      },

      -- Core settings
      signcolumn = true, -- Show signs in the sign column
      numhl = false,     -- Don't highlight line numbers
      linehl = false,    -- Don't highlight the whole line
      word_diff = false, -- Don't show word diff inline

      -- Git monitoring
      watch_gitdir = {
        interval = 1000,
        follow_files = true,
      },
      attach_to_untracked = true,

      -- Blame functionality
      current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
        delay = 1000,
        ignore_whitespace = false,
      },

      -- Performance settings
      sign_priority = 6,
      update_debounce = 100,
      max_file_length = 40000,

      -- Preview window config
      preview_config = {
        border = "single",
        style = "minimal",
        relative = "cursor",
        row = 0,
        col = 1,
      },
    })

    -- Define custom highlights to override any colorscheme settings
    -- that might be causing the thick double bars
    vim.api.nvim_create_autocmd("ColorScheme", {
      pattern = "*",
      callback = function()
        -- Reset sign column background to match normal text background
        vim.cmd [[highlight! link SignColumn Normal]]

        -- Set consistent colors for git signs
        -- Light blue for new/added items
        local add_color = "#4fa6ed"      -- Light blue
        -- Soft rust orange for modified items
        local change_color = "#e78a4e"   -- Soft rust orange
        -- Error red for deleted items
        local delete_color = "#fb4934"   -- Red
        
        -- Create highlight groups that can be referenced elsewhere
        vim.api.nvim_set_hl(0, "GitSignsAddColor", { fg = add_color })
        vim.api.nvim_set_hl(0, "GitSignsChangeColor", { fg = change_color })
        vim.api.nvim_set_hl(0, "GitSignsDeleteColor", { fg = delete_color })
        
        -- Apply these colors to GitSigns
        vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = add_color, bg = "NONE" })
        vim.api.nvim_set_hl(0, "GitSignsChange", { fg = change_color, bg = "NONE" })
        vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = delete_color, bg = "NONE" })
        
        -- Make the colors available as global variables for other plugins to use
        _G.GitColors = _G.GitColors or {}
        _G.GitColors.add = add_color
        _G.GitColors.change = change_color
        _G.GitColors.delete = delete_color
      end,
      group = vim.api.nvim_create_augroup("GitSignsHighlight", { clear = true }),
    })
  end
}

