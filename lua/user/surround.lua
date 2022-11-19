require("nvim-surround").setup({
  keymaps = {
      insert = false,
      insert_line = false,
      normal = false,
      normal_cur = false,
      normal_line = false,
      normal_cur_line = false,
      visual = "<S-s>",
      visual_line = false,
      delete = false,
      change = false,
  },
  aliases = {
      ["a"] = false,
      ["b"] = false,
      ["B"] = false,
      ["r"] = false,
      ["q"] = false,
      ["s"] = false,
  },
})
