-- Enhanced Jupyter styling for Markdown files (.md)
if vim.fn.expand("%:e") == "md" then
  -- Check if this is a Jupyter-converted markdown file
  local lines = vim.api.nvim_buf_get_lines(0, 0, 20, false)
  local is_jupyter = false

  for _, line in ipairs(lines) do
    if line:match("^```python") then
      is_jupyter = true
      break
    end
  end

  if is_jupyter then
    -- Apply Jupyter notebook styling
    vim.opt_local.signcolumn = "yes:1"

    -- Ensure our styling module is loaded
    vim.defer_fn(function()
      local ok, styling = pcall(require, "neotex.plugins.tools.jupyter.styling")
      if ok and type(styling) == "table" and styling.setup then
        styling.setup()
      end
    end, 100)
  end
end

