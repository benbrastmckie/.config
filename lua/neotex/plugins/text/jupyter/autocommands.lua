-- Autocommands to ensure Jupyter styling is applied only to ipynb files
-- This file is loaded on startup to set up the necessary autocommands

local M = {}

function M.setup()
  -- Create an autocommand group for Jupyter notebook styling
  local augroup = vim.api.nvim_create_augroup("JupyterNotebookAutocommands", { clear = true })
  
  -- Autocommand to load styling when entering an ipynb file (only)
  vim.api.nvim_create_autocmd({"FileType"}, {
    pattern = {"ipynb"},
    group = augroup,
    callback = function()
      -- Set ipynb-specific options
      vim.opt_local.signcolumn = "yes:1"
      vim.opt_local.conceallevel = 0
      vim.opt_local.list = false
      
      -- Apply Jupyter notebook styling safely
      vim.defer_fn(function()
        pcall(function()
          local styling = require("neotex.plugins.text.jupyter.styling")
          styling.setup()
        end)
      end, 50)
    end
  })
  
  -- Detect when an ipynb file is created through external means (e.g., Jupytext conversion)
  vim.api.nvim_create_autocmd({"BufNewFile"}, {
    pattern = {"*.ipynb"},
    group = augroup,
    callback = function()
      -- Set filetype to ipynb to trigger the FileType autocmd
      vim.cmd("setfiletype ipynb")
    end
  })
end

return M