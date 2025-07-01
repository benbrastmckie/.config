-- Floating window utilities for Himalaya
local M = {}

-- Show content in a floating window
function M.show(title, lines)
  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  
  -- Calculate window size
  local width = math.min(80, math.floor(vim.o.columns * 0.8))
  local height = math.min(#lines + 2, math.floor(vim.o.lines * 0.8))
  
  -- Calculate position (centered)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  -- Create window
  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' ' .. title .. ' ',
    title_pos = 'center',
  }
  
  local win = vim.api.nvim_open_win(buf, true, win_opts)
  
  -- Set up keymaps to close
  local close_keys = {'q', '<Esc>', '<CR>'}
  for _, key in ipairs(close_keys) do
    vim.api.nvim_buf_set_keymap(buf, 'n', key, ':close<CR>', {
      noremap = true,
      silent = true,
      nowait = true
    })
  end
  
  -- Make it easy to scroll
  vim.api.nvim_win_set_option(win, 'cursorline', true)
  
  return buf, win
end

return M