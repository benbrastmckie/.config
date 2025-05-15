-----------------------------------------------------
-- DEPRECATED: mini.surround configuration
-- 
-- This file contains the mini.surround configuration that was previously
-- part of the mini.lua file in neotex/plugins/coding/mini.lua. It has been
-- deprecated in favor of nvim-surround by kylechui/nvim-surround.
--
-- The mini.surround implementation had issues with key binding conflicts
-- and inconsistent behavior.
-----------------------------------------------------

-- This setup function was part of the main mini.nvim setup in mini.lua
local function setup_mini_surround()
  -- Configure mini.surround for surrounding text
  local MiniSurround = require('mini.surround')
  -- Make MiniSurround available globally
  _G.MiniSurround = MiniSurround
  
  MiniSurround.setup({
    -- Module mappings. Use `''` (empty string) to disable one.
    mappings = {
      add = '',              -- Disable default mapping for add surrounding
      delete = '',           -- Disable default mapping for delete surrounding
      find = '',             -- Disable default mapping for find surrounding
      find_left = '',        -- Disable default mapping for find surrounding (left)
      highlight = '',        -- Disable default mapping for highlight surrounding
      replace = '',          -- Disable default mapping for replace surrounding
      update_n_lines = '',   -- Keep update `n_lines` functionality

      -- Disable visual mode mapping as well
      suffix_last = 'l',     -- Suffix to search with "prev" method
      suffix_next = 'n',     -- Suffix to search with "next" method
    },

    -- How to search for surrounding (first inside current line, then inside
    -- neighborhood). Each element of search path should be one of 'cover', 'prev',
    -- 'next', 'nearest'.
    search_method = 'cover_or_next',

    -- Number of lines within which surrounding is searched
    n_lines = 20,

    -- Whether to respect selection type (character/line/block)
    respect_selection_type = true,

    -- Duration (in ms) of highlight when calling `MiniSurround.highlight()`
    highlight_duration = 500,

    -- Custom surrounding patterns
    custom_surroundings = {
      -- LaTeX-specific surroundings
      ['$'] = { output = { left = '$', right = '$' } },
      ['\\'] = { output = { left = '\\(', right = '\\)' } },

      -- LaTeX environments
      -- ['E'] = { output = { left = '\\begin{equation}', right = '\\end{equation}' } },
      -- ['A'] = { output = { left = '\\begin{align}', right = '\\end{align}' } },
      -- ['M'] = { output = { left = '\\begin{matrix}', right = '\\end{matrix}' } },
      -- ['P'] = { output = { left = '\\begin{pmatrix}', right = '\\end{pmatrix}' } },
      -- ['C'] = { output = { left = '\\begin{cases}', right = '\\end{cases}' } },
      -- ['F'] = { output = { left = '\\begin{figure}', right = '\\end{figure}' } },
      -- ['D'] = { output = { left = '\\begin{document}', right = '\\end{document}' } },
      -- ['S'] = { output = { left = '\\begin{split}', right = '\\end{split}' } },

      -- LaTeX text formatting
      ['i'] = { output = { left = '\\textit{', right = '}' } },
      ['b'] = { output = { left = '\\textbf{', right = '}' } },
      ['t'] = { output = { left = '\\texttt{', right = '}' } },
      ['s'] = { output = { left = '\\textsc{', right = '}' } },

      ['u'] = { output = { left = '\\underline{', right = '}' } },
      ['o'] = { output = { left = '\\overline{', right = '}' } },
      ['B'] = { output = { left = '\\mathbf{', right = '}' } },
      ['I'] = { output = { left = '\\mathit{', right = '}' } },
      ['T'] = { output = { left = '\\mathtt{', right = '}' } },
      -- ['c'] = { output = { left = '\\mathcal{', right = '}' } },
      -- ['f'] = { output = { left = '\\mathfrak{', right = '}' } },
      -- ['s'] = { output = { left = '\\mathscr{', right = '}' } },

      -- Special LaTeX surroundings
      ['q'] = { output = { left = '``', right = '\'\'' } }, -- LaTeX quotes
      ['Q'] = { output = { left = '`', right = '\'' } },    -- LaTeX single quotes

      -- Markdown surroundings
      ['*'] = { output = { left = '*', right = '*' } },
      ['_'] = { output = { left = '_', right = '_' } },
      ['`'] = { output = { left = '`', right = '`' } },
      ['~'] = { output = { left = '~~', right = '~~' } },
      ['c'] = { output = { left = '```', right = '```' } },
    },
  })

  -- The mappings below were part of neotex/plugins/editor/which-key.lua
  -- s = {
  --   name = "SURROUND",
  --   s = { "<cmd>lua require('mini.surround').add()<cr>", "add surrounding" },
  --   d = { "<cmd>lua require('mini.surround').delete()<cr>", "delete surrounding" },
  --   c = { "<cmd>lua require('mini.surround').replace()<cr>", "change surrounding" },
  --   f = { "<cmd>lua require('mini.surround').find()<cr>", "find surrounding" },
  --   h = { "<cmd>lua require('mini.surround').highlight()<cr>", "highlight surrounding" },
  -- },

  -- Visual mode mappings for surround operations
  -- ["<leader>s"] = {
  --   name = "SURROUND",
  --   s = { "<cmd>lua require('mini.surround').add('visual')<cr>", "add surrounding to selection" },
  -- }
end

-- This function is not called; it's kept for reference
return {
  setup = setup_mini_surround
}