local M = {}

-- Function to show all linter errors in a floating window
M.show_all_errors = function()
  local diagnostics = vim.diagnostic.get(0, {severity = vim.diagnostic.severity.ERROR})
  
  if #diagnostics == 0 then
    vim.notify("No linter errors found", vim.log.levels.INFO)
    return
  end
  
  -- Format diagnostics
  local formatted = {}
  for _, diag in ipairs(diagnostics) do
    local line = diag.lnum + 1
    local col = diag.col + 1
    local msg = diag.message
    local source = diag.source or "unknown"
    table.insert(formatted, string.format("%d:%d - [%s] %s", line, col, source, msg))
  end
  
  -- Create buffer and window
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, formatted)
  
  -- Get window dimensions
  local max_width = 0
  for _, line in ipairs(formatted) do
    max_width = math.max(max_width, #line)
  end
  
  local width = math.min(max_width + 2, 80)
  local height = math.min(#formatted, 10)
  
  -- Configure window
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    row = (vim.o.lines - height) / 2,
    col = (vim.o.columns - width) / 2,
    style = "minimal",
    border = "rounded",
    title = " Linter Errors ",
    title_pos = "center"
  }
  
  local win = vim.api.nvim_open_win(buf, true, opts)
  
  -- Set window options
  vim.api.nvim_win_set_option(win, "winblend", 0)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  
  -- Add syntax highlighting
  vim.api.nvim_buf_set_option(buf, "filetype", "diagnostics")
  vim.api.nvim_buf_add_highlight(buf, -1, "ErrorMsg", 0, 0, -1)
  
  -- Set buffer keymaps
  vim.api.nvim_buf_set_keymap(buf, "n", "q", ":q<CR>", {noremap = true, silent = true})
  vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":q<CR>", {noremap = true, silent = true})
  vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", 
    [[<cmd>lua require('neotex.utils.diagnostics').jump_to_error()<CR>]], 
    {noremap = true, silent = true})
  vim.api.nvim_buf_set_keymap(buf, "n", "j", "j", {noremap = true, silent = true})
  vim.api.nvim_buf_set_keymap(buf, "n", "k", "k", {noremap = true, silent = true})
end

-- Function to jump to error location from the floating window
M.jump_to_error = function()
  local line = vim.api.nvim_get_current_line()
  local line_num = tonumber(line:match("(%d+):"))
  if line_num then
    vim.cmd("q") -- Close the floating window
    vim.api.nvim_win_set_cursor(0, {line_num, 0})
    vim.cmd("normal! zz") -- Center the view
    vim.diagnostic.open_float() -- Show the diagnostic at current position
  end
end

return M