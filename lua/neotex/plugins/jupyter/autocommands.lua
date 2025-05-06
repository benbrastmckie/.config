-- Explicit autocommands to ensure Jupyter styling is applied
-- This file is loaded on startup to set up the necessary autocommands

local M = {}

function M.setup()
  -- Create an autocommand group for Jupyter notebook styling
  local augroup = vim.api.nvim_create_augroup("JupyterNotebookAutocommands", { clear = true })
  
  -- Autocommand to load styling when entering an ipynb file
  vim.api.nvim_create_autocmd({"FileType"}, {
    pattern = {"ipynb"},
    group = augroup,
    callback = function()
      -- Apply Jupyter notebook styling safely
      vim.defer_fn(function()
        pcall(function()
          local styling = require("neotex.plugins.jupyter.styling")
          styling.setup()
        end)
        
        -- Set other ipynb-specific options
        vim.opt_local.signcolumn = "yes:1"
        vim.opt_local.conceallevel = 0
        vim.opt_local.list = false
      end, 50)
    end
  })
  
  -- Create autocommand for buffer write to refresh styling
  vim.api.nvim_create_autocmd({"BufWritePost"}, {
    pattern = {"*.ipynb", "*.md"},
    group = augroup,
    callback = function()
      -- Delay styling slightly to ensure file is fully written
      vim.defer_fn(function()
        -- Try to apply styling
        pcall(function()
          local styling = require("neotex.plugins.jupyter.styling")
          styling.setup()
        end)
      end, 100)
    end
  })

  -- Force apply styling after colorscheme changes
  vim.api.nvim_create_autocmd({"ColorScheme"}, {
    group = augroup,
    callback = function()
      -- Re-setup all highlights
      pcall(function()
        local styling = require("neotex.plugins.jupyter.styling")
        styling.setup()
      end)
    end
  })
end

return M