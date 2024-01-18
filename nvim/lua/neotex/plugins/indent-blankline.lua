return {
  "lukas-reineke/indent-blankline.nvim",
  -- dependencies = {},
  version = "*",
  event = { "BufReadPre", "BufNewFile" },
  -- highlight = { "Function", "Label" },
  opts = {
    indent = {
      char = "│",
      tab_char = "│",
      -- highlight = highlight,
    },
    show_trailing_blankline_indent = false,
    scope = { enabled = true },
    exclude = {
      filetypes = {
        "help",
        "alpha",
        "dashboard",
        "NvimTree",
        -- "Trouble",
        -- "trouble",
        "lazy",
        "mason",
        -- "notify",
        "toggleterm",
      },
    },
  },
  main = "ibl",
   -- local hooks = require "ibl.hooks"
   -- hooks.register(
   --   hooks.type.ACTIVE,
   --   function(bufnr)
   --     return vim.api.nvim_buf_line_count(bufnr) < 5000
   --   end
   -- )
}
