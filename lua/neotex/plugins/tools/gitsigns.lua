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
        add = { text = "┃" },
        change = { text = "┃" },
        -- Different symbols for deleted lines
        delete = { text = "▁" },
        topdelete = { text = "▔" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
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

        -- Set minimal highlighting for git signs
        vim.cmd [[highlight! GitSignsAdd ctermfg=Green guifg=#b8bb26 ctermbg=NONE guibg=NONE]]
        vim.cmd [[highlight! GitSignsChange ctermfg=Blue guifg=#83a598 ctermbg=NONE guibg=NONE]]
        vim.cmd [[highlight! GitSignsDelete ctermfg=Red guifg=#fb4934 ctermbg=NONE guibg=NONE]]
      end,
      group = vim.api.nvim_create_augroup("GitSignsHighlight", { clear = true }),
    })
  end
}

