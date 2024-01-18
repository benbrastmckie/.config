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
    },
    scope = { enabled = true },
    exclude = {
      filetypes = {
        "help",
        "alpha",
        "dashboard",
        "nvim-tree",
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
}
