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

-- Create a buffer with content
function M.create_buffer(lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  return buf
end

-- Show a buffer in a floating window
function M.show_buffer(buf, opts)
  opts = opts or {}
  
  -- Get buffer line count if height not specified
  if not opts.height then
    opts.height = vim.api.nvim_buf_line_count(buf) + 2
  end
  
  -- Default width
  if not opts.width then
    opts.width = 80
  end
  
  -- Constrain to screen size
  opts.width = math.min(opts.width, math.floor(vim.o.columns * 0.9))
  opts.height = math.min(opts.height, math.floor(vim.o.lines * 0.9))
  
  -- Calculate position (centered by default)
  local row = opts.row or math.floor((vim.o.lines - opts.height) / 2)
  local col = opts.col or math.floor((vim.o.columns - opts.width) / 2)
  
  -- Create window
  local win_opts = {
    relative = opts.relative or 'editor',
    width = opts.width,
    height = opts.height,
    row = row,
    col = col,
    style = 'minimal',
    border = opts.border or 'rounded',
  }
  
  if opts.title then
    win_opts.title = ' ' .. opts.title .. ' '
    win_opts.title_pos = 'center'
  end
  
  local win = vim.api.nvim_open_win(buf, true, win_opts)
  
  -- Set default close keymaps unless disabled
  if opts.close_keys ~= false then
    local close_keys = opts.close_keys or {'q', '<Esc>'}
    for _, key in ipairs(close_keys) do
      vim.api.nvim_buf_set_keymap(buf, 'n', key, ':close<CR>', {
        noremap = true,
        silent = true,
        nowait = true
      })
    end
  end
  
  -- Enable cursorline for better visibility
  vim.api.nvim_win_set_option(win, 'cursorline', true)
  
  return win
end

return M