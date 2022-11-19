local config = require("nvim-surround.config")
require("nvim-surround").buffer_setup({
  surrounds = {
    ["e"] = {
      add = function()
        local env = require("nvim-surround.config").get_input "Environment: "
        return { { "\\begin{" .. env .. "}" }, { "\\end{" .. env .. "}" } }
      end,
    },
    ["Q"] = {
      add = { "``", "''" },
      find = "%b``''",
      delete = "^(``)().-('')()$",
    },
    ["q"] = {
      add = { "`", "'" },
      find = "%b`'",
      delete = "^(`)().-(')()$",
    },
    ["b"] = {
      add = { "\\textbf{", "}" },
      find = "\\textbf%b{}",
      delete = "^(\\textbf{)().-(})()$",
    },
    ["i"] = {
      add = { "\\textit{", "}" },
      find = "\\textit%b{}",
      delete = "^(\\textit{)().-(})()$",
    },
    ["s"] = {
      add = { "\\textsc{", "}" },
      find = "\\textsc%b{}",
      delete = "^(\\textsc{)().-(})()$",
    },
    ["t"] = {
      add = { "\\texttt{", "}" },
      find = "\\texttt%b{}",
      delete = "^(\\texttt{)().-(})()$",
    },
    ["$"] = {
        add = { "$", "$" },
        find = function()
            return M.get_selection({ motion = "a$" })
        end,
        delete = "^($)().-($)()$",
    },
  },
})

