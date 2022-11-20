require("nvim-surround").buffer_setup({
  surrounds = {
    ["e"] = {
      add = function()
        local env = require("nvim-surround.config").get_input("Environment: ")
        return { { "\\begin{" .. env .. "}" }, { "\\end{" .. env .. "}" } }
      end,
    },
    ["Q"] = {
      add = { "``", "''" },
      find = "``.-''",
      delete = "^(``)().-('')()$",
    },
    ["q"] = {
      add = { "`", "'" },
      find = "`.-'",
      delete = "^(`)().-(')()$",
    },
    ["b"] = {
      add = function()
        if vim.fn["vimtex#syntax#in_mathzone"]() == 1 then
          return { { "\\mathbf{" }, { "}" } }
        end
        return { { "\\textbf{" }, { "}" } }
      end,
      find = "\\%a-bf%b{}",
      delete = "^(\\%a-bf{)().-(})()$",
    },
    ["i"] = {
      add = function()
        if vim.fn["vimtex#syntax#in_mathzone"]() == 1 then
          return { { "\\mathit{" }, { "}" } }
        end
        return { { "\\textit{" }, { "}" } }
      end,
      find = "\\%a-it%b{}",
      delete = "^(\\%a-it{)().-(})()$",
    },
    ["s"] = {
      add = { "\\textsc{", "}" },
      find = "\\textsc%b{}",
      delete = "^(\\textsc{)().-(})()$",
    },
    ["t"] = {
      add = function()
        if vim.fn["vimtex#syntax#in_mathzone"]() == 1 then
          return { { "\\mathtt{" }, { "}" } }
        end
        return { { "\\texttt{" }, { "}" } }
      end,
      find = "\\%a-tt%b{}",
      delete = "^(\\%a-tt{)().-(})()$",
    },
    ["$"] = {
      add = { "$ ", " $" },
    },
  },
})
