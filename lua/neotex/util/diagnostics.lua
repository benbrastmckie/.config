-----------------------------------------------------------
-- Diagnostic and LSP Integration Utilities
-- 
-- This module provides functions for working with diagnostics:
-- - Viewing and navigating errors (show_all_errors, jump_to_error)
-- - Diagnostic management (copy_diagnostics_to_clipboard)
-- - Jupyter notebook integration (add_jupyter_cell_with_closing)
--
-- The utilities enhance the built-in LSP diagnostic capabilities
-- with more user-friendly interfaces and additional functionality.
-----------------------------------------------------------

local M = {}
local notify = require('neotex.util.notifications')

-- Function to show all linter errors in a floating window
function M.show_all_errors()
  local diagnostics = vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })

  if #diagnostics == 0 then
    notify.editor('No linter errors found', notify.categories.STATUS)
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
  vim.api.nvim_set_option_value("winblend", 0, { win = win })
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

  -- Add syntax highlighting
  vim.api.nvim_set_option_value("filetype", "diagnostics", { buf = buf })
  vim.api.nvim_buf_add_highlight(buf, -1, "ErrorMsg", 0, 0, -1)

  -- Set buffer keymaps
  vim.api.nvim_buf_set_keymap(buf, "n", "q", ":q<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":q<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, "n", "<CR>",
    [[<cmd>lua require('neotex.util.diagnostics').jump_to_error()<CR>]],
    { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, "n", "j", "j", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, "n", "k", "k", { noremap = true, silent = true })
end

-- Function to jump to error location from the floating window
function M.jump_to_error()
  local line = vim.api.nvim_get_current_line()
  local line_num = tonumber(line:match("(%d+):"))
  if line_num then
    vim.cmd("q")                -- Close the floating window
    vim.api.nvim_win_set_cursor(0, { line_num, 0 }) -- Move to line
    vim.cmd("normal! zz")       -- Center the view
    vim.diagnostic.open_float() -- Show the diagnostic at current position
  end
end

-- Enhanced function to add a Jupyter cell with both opening and closing markers
function M.add_jupyter_cell_with_closing()
  local ok, nn = pcall(require, "notebook-navigator")
  if not ok then
    notify.editor('NotebookNavigator plugin not found', notify.categories.ERROR)
    return
  end
  
  -- Get the current buffer
  local bufnr = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  
  -- Only for ipynb files
  if bufname:match("%.ipynb$") then
    -- Get cursor position
    local pos = vim.api.nvim_win_get_cursor(0)
    local row = pos[1]
    
    -- Insert Python markdown cell
    vim.api.nvim_buf_set_lines(bufnr, row, row, false, 
      { "```python", "", "```" })
    
    -- Move cursor to the empty line between markers
    vim.api.nvim_win_set_cursor(0, { row + 2, 0 })
  else
    -- For other files, use the default behavior
    nn.add_cell_below()
  end
end

-- Function to copy diagnostics to clipboard
function M.copy_diagnostics_to_clipboard()
  local diagnostics = vim.diagnostic.get(0)  -- Get diagnostics for current buffer
  if #diagnostics == 0 then
    notify.editor('No diagnostics found', notify.categories.STATUS)
    return
  end
  
  local lines = {}
  for _, diagnostic in ipairs(diagnostics) do
    local severity = diagnostic.severity
    local severity_names = {"ERROR", "WARN", "INFO", "HINT"}
    local severity_name = severity_names[severity] or "UNKNOWN"
    local line = string.format("%s:%d:%d: %s: %s", 
      vim.fn.bufname(diagnostic.bufnr) or "[No Name]",
      diagnostic.lnum + 1,
      diagnostic.col + 1,
      severity_name,
      diagnostic.message)
    table.insert(lines, line)
  end
  
  local formatted = table.concat(lines, "\n")
  vim.fn.setreg('+', formatted)
  notify.editor('Diagnostics copied to clipboard', notify.categories.USER_ACTION, { count = #diagnostics })
end

-- Setup function for diagnostic utilities
function M.setup()
  -- Setup global function for backward compatibility
  _G.CopyDiagnosticsToClipboard = function()
    M.copy_diagnostics_to_clipboard()
  end
  
  return true
end

return M