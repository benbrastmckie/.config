-- Set filetype for Jupyter Notebook files
vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
  pattern = {"*.ipynb"},
  callback = function()
    vim.bo.filetype = "ipynb"
    
    -- Apply Jupyter notebook styling immediately
    vim.defer_fn(function()
      local ok, styling = pcall(require, "neotex.plugins.tools.jupyter.styling")
      if ok and type(styling) == "table" and styling.setup then
        styling.setup()
      end
    end, 100)
  end
})