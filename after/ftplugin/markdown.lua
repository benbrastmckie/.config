local M = {}

local config = require("nvim-surround.config")

require("nvim-surround").buffer_setup({
  surrounds = {
    ["e"] = {
      add = function()
        local env = require("nvim-surround.config").get_input "Environment: "
        return { { "\\begin{" .. env .. "}" }, { "\\end{" .. env .. "}" } }
      end,
    },
    ["b"] = {
      add = { "**", "**" },
      find = function()
          return M.get_selection({ motion = "a**" })
      end,
      delete = "^(**)().-(**)()$",
    },
    ["i"] = {
      add = { "*", "*" },
      find = function()
          return M.get_selection({ motion = "a*" })
      end,
      delete = "^(*)().-(*)()$",
    },
  },
})

return M
