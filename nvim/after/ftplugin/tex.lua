local config = require("nvim-surround.config")

require("nvim-surround").buffer_setup({
  surrounds = {
    -- ["e"] = {
    --   add = function()
    --     local env = require("nvim-surround.config").get_input ("Environment: ")
    --     return { { "\\begin{" .. env .. "}" }, { "\\end{" .. env .. "}" } }
    --   end,
    -- },
    ["Q"] = {
      add = { "``", "''" },
      find = "%b``.-''",
      delete = "^(``)().-('')()$",
    },
    ["q"] = {
      add = { "`", "'" },
      find = "`.-'",
      delete = "^(`)().-(')()$",
    },
    ["b"] = {
      add = { "\\textbf{", "}" },
      -- add = function()
      --   if vim.fn["vimtex#syntax#in_mathzone"]() == 1 then
      --     return { { "\\mathbf{" }, { "}" } }
      --   end
      --   return { { "\\textbf{" }, { "}" } }
      -- end,
      find = "\\%a-bf%b{}",
      delete = "^(\\%a-bf{)().-(})()$",
    },
    ["i"] = {
      add = { "\\textit{", "}" },
      -- add = function()
      --   if vim.fn["vimtex#syntax#in_mathzone"]() == 1 then
      --     return { { "\\mathit{" }, { "}" } }
      --   end
      --   return { { "\\textit{" }, { "}" } }
      -- end,
      find = "\\%a-it%b{}",
      delete = "^(\\%a-it{)().-(})()$",
    },
    ["s"] = {
      add = { "\\textsc{", "}" },
      find = "\\textsc%b{}",
      delete = "^(\\textsc{)().-(})()$",
    },
    ["t"] = {
      add = { "\\texttt{", "}" },
      -- add = function()
      --   if vim.fn["vimtex#syntax#in_mathzone"]() == 1 then
      --     return { { "\\mathtt{" }, { "}" } }
      --   end
      --   return { { "\\texttt{" }, { "}" } }
      -- end,
      find = "\\%a-tt%b{}",
      delete = "^(\\%a-tt{)().-(})()$",
    },
    ["$"] = {
      add = { "$", "$" },
      -- find = "%b$.-$",
      -- delete = "^($)().-($)()$",
    },
  },
})

-- vim.g['tex_indent_items'] = false
-- vim.g['tex_indent_and'] = false
-- vim.g['tex_indent_brace'] = false

-- -- makes lsp menu preserve vimtex
-- require('cmp').setup.buffer {
--   formatting = {
--     format = function(entry, vim_item)
--         vim_item.menu = ({
--           omni = (vim.inspect(vim_item.menu):gsub('%"', "")),
--           buffer = "[Buffer]",
--           -- formatting for other sources
--           })[entry.source.name]
--         return vim_item
--       end,
--   },
--   sources = {
--     { name = 'omni' },
--     { name = 'buffer' },
--     -- other sources
--   },
-- }
