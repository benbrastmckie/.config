require("nvim-surround").buffer_setup({
  surrounds = {
    ["e"] = {
      add = function()
        local env = require("nvim-surround.config").get_input ("Environment: ")
        return { { "\\begin{" .. env .. "}" }, { "\\end{" .. env .. "}" } }
      end,
    },
    ["b"] = {
      add = { "**", "**" },
      find = "**.-**",
      delete = "^(**)().-(**)()$",
    },
    ["i"] = {
      add = { "*", "*" },
      find = "*.-*",
      delete = "^(*)().-(*)()$",
    },
  },
})
