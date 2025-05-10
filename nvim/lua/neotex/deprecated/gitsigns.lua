return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("gitsigns").setup({
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "▎" },
        topdelete = { text = "▎" },
        changedelete = { text = "▎" },
        -- untracked    = { text = "┆" },
        -- OR THIS BLOCK
        -- add = { hl = "Title", text = "▎", numhl = "GitSignsAddNr", linehl = "GitSignsAddLn" },
        -- change = { hl = "Question", text = "▎", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn" },
        -- delete = { hl = "Warning", text = "▎", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
        -- topdelete = { hl = "Warning", text = "▎", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
        -- changedelete = { hl = "Question", text = "▎", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn" },
        -- OR THIS BLOCK
        -- add = { hl = "DiagnosticSignOK", text = "▎", numhl = "GitSignsAddNr", linehl = "GitSignsAddLn" },
        -- change = { hl = "DiagnosticSignHint", text = "▎", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn" },
        -- delete = { hl = "DiagnosticSignError", text = "▎", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
        -- -- delete = { hl = "DiagnosticSignError", text = "", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
        -- topdelete = { hl = "DiagnosticSignError", text = "▎", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
        -- -- topdelete = { hl = "DiagnosticSignError", text = "", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
        -- changedelete = { hl = "DiagnosticSignHint", text = "▎", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn" },
        -- END
      },
      signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
      numhl = false, -- Toggle with `:Gitsigns toggle_numhl`
      linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
      word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
      watch_gitdir = {
        interval = 1000,
        follow_files = true,
      },
      attach_to_untracked = true,
      current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
        delay = 1000,
        ignore_whitespace = false,
      },
      -- current_line_blame_formatter_opts = {
      --   relative_time = false,
      -- },
      sign_priority = 6,
      update_debounce = 100,
      status_formatter = nil, -- Use default
      max_file_length = 40000,
      preview_config = {
        -- Options passed to nvim_open_win
        border = "single",
        style = "minimal",
        relative = "cursor",
        row = 0,
        col = 1,
      },
      -- yadm = {
      --   enable = false,
      -- },
    })
  end
}
