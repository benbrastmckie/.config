-- We're now using nvim-surround instead of mini.surround
-- LaTeX-specific surround configurations are in lua/neotex/plugins/coding/surround.lua

-- This file includes buffer-specific surround configuration
require("nvim-surround").buffer_setup({
  surrounds = {
    -- LaTeX environments
    ["e"] = {
      add = function()
        local env = vim.fn.input("Environment: ")
        return { { "\\begin{" .. env .. "}" }, { "\\end{" .. env .. "}" } }
      end,
    },
    -- LaTeX quotes
    ["Q"] = {
      add = { "``", "''" },
      find = "%b``.-''",
      delete = "^(``)().-('')()$",
    },
    -- LaTeX single quotes
    ["q"] = {
      add = { "`", "'" },
      find = "`.-'",
      delete = "^(`)().-(')()$",
    },
    -- LaTeX text formatting
    ["b"] = {
      add = { "\\textbf{", "}" },
      find = "\\%a-bf%b{}",
      delete = "^(\\%a-bf{)().-(})()$",
    },
    ["i"] = {
      add = { "\\textit{", "}" },
      find = "\\%a-it%b{}",
      delete = "^(\\%a-it{)().-(})()$",
    },
    ["t"] = {
      add = { "\\texttt{", "}" },
      find = "\\%a-tt%b{}",
      delete = "^(\\%a-tt{)().-(})()$",
    },
    ["$"] = {
      add = { "$", "$" },
    },
  },
})

-- PdfAnnots
function PdfAnnots()
  local ok, pdf = pcall(vim.api.nvim_eval,
    "vimtex#context#get().handler.get_actions().entry.file")
  if not ok then
    vim.notify "No file found"
    return
  end

  local cwd = vim.fn.getcwd()
  vim.fn.chdir(vim.b.vimtex.root)

  if vim.fn.isdirectory('Annotations') == 0 then
    vim.fn.mkdir('Annotations')
  end

  local md = vim.fn.printf("Annotations/%s.md", vim.fn.fnamemodify(pdf, ":t:r"))
  -- vim.fn.system(vim.fn.printf('pdfannots -o "%s" "%s"', md, pdf))
  vim.fn.system(string.format('pdfannots -o "%s" "%s"', md, pdf))
  vim.cmd.split(vim.fn.fnameescape(md))

  vim.fn.chdir(cwd)
end

-- Enable full-line syntax highlighting for LaTeX files
-- Override the global synmaxcol=200 setting for better LaTeX support
vim.opt_local.synmaxcol = 0  -- 0 means no limit

-- -- LSP menu to preserve vimtex citation data
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
