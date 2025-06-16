-- Minimal mini.nvim configuration
return {
  'echasnovski/mini.nvim',
  version = false,
  event = { "VeryLazy" },
  dependencies = {
    "hrsh7th/nvim-cmp",
  },
  config = function()
    -- Configure mini.cursorword
    require('mini.cursorword').setup({
      delay = 100,
      min_word_length = 1,
      disable_in_insert = true,
      excluded_filetypes = { 'NvimTree', 'TelescopePrompt' },
      excluded_buftypes = { 'help', 'terminal', 'nofile', 'quickfix', 'prompt' },
      disallowed_words = nil,
    })

    -- Configure mini.comment
    require('mini.comment').setup({
      options = {
        ignore_blank_line = false,
        start_of_line = false,
        pad_comment_parts = true,
      },
      mappings = {
        -- Use default mappings
        comment = 'gc',
        comment_line = 'gcc',
        comment_visual = 'gc',
        textobject = 'gc',
      },
    })

    -- mini.pairs removed - now using nvim-autopairs for comprehensive pairing
    -- This provides better LaTeX and Lean support with treesitter integration

    -- Configure mini.ai
    require('mini.ai').setup({
      custom_textobjects = {
        o = require('mini.ai').gen_spec.treesitter({
          a = { "@block.outer", "@conditional.outer", "@loop.outer" },
          i = { "@block.inner", "@conditional.inner", "@loop.inner" },
        }, {}),
        f = require('mini.ai').gen_spec.treesitter({
          a = "@function.outer",
          i = "@function.inner"
        }, {}),
        c = require('mini.ai').gen_spec.treesitter({
          a = "@class.outer",
          i = "@class.inner"
        }, {}),
      },
      search_method = 'cover_or_nearest',
      silent = false,
    })

    -- -- Configure mini.splitjoin
    -- require('mini.splitjoin').setup({
    --   mappings = {
    --     toggle = 'gS',
    --     split = '',
    --     join = '',
    --   },
    -- })

    -- -- Configure mini.align
    -- require('mini.align').setup({
    --   mappings = {
    --     start = 'ga',
    --     start_with_preview = 'gA',
    --   },
    -- })

    -- Configure highlighting
    vim.api.nvim_set_hl(0, 'MiniCursorword', { link = 'Pmenu' })

    -- Toggle function
    _G.LocalHighlightToggle = function()
      if vim.b.minicursorword_disable then
        vim.b.minicursorword_disable = false
        vim.notify("Word highlighting enabled", vim.log.levels.INFO)
      else
        vim.b.minicursorword_disable = true
        vim.notify("Word highlighting disabled", vim.log.levels.INFO)
      end
    end
  end,
}
