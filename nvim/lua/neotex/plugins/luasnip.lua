return {
  "L3MON4D3/LuaSnip",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local ls = require("luasnip")

    require("luasnip.loaders.from_snipmate").load({ paths = "~/.config/nvim/snippets/" })
  end
}
