-- Himalaya Sidebar Module
-- Neo-tree style persistent sidebar for email list navigation

local M = {}

-- Configuration
M.config = {
  width = 50,
  position = 'left',
  border = 'rounded'
}

-- State tracking
M.state = {
  buf = nil,
  win = nil,
  is_open = false
}

-- Create or get existing buffer for sidebar
function M.create_buffer()
  if M.state.buf and vim.api.nvim_buf_is_valid(M.state.buf) then
    return M.state.buf
  end
  
  M.state.buf = vim.api.nvim_create_buf(false, true)
  
  -- Buffer configuration
  vim.api.nvim_buf_set_option(M.state.buf, 'filetype', 'himalaya-list')
  vim.api.nvim_buf_set_option(M.state.buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(M.state.buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(M.state.buf, 'bufhidden', 'hide')
  vim.api.nvim_buf_set_option(M.state.buf, 'buflisted', false)
  
  -- Buffer-local settings
  vim.api.nvim_buf_call(M.state.buf, function()
    vim.opt_local.wrap = false
    vim.opt_local.cursorline = true
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = 'no'
    vim.opt_local.foldcolumn = '0'
  end)
  
  return M.state.buf
end

-- Open sidebar window
function M.open()
  if M.state.is_open and M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    -- Already open, just focus it
    vim.api.nvim_set_current_win(M.state.win)
    return M.state.win
  end
  
  local buf = M.create_buffer()
  
  -- Store original window to restore focus if needed
  local original_win = vim.api.nvim_get_current_win()
  
  -- Use neo-tree style window splitting instead of floating
  -- This creates a real sidebar that shifts content instead of overlapping
  if M.config.position == 'left' then
    vim.cmd('topleft ' .. M.config.width .. 'vsplit')
  else
    vim.cmd('botright ' .. M.config.width .. 'vsplit')
  end
  
  M.state.win = vim.api.nvim_get_current_win()
  
  -- Set the buffer in the new window
  vim.api.nvim_win_set_buf(M.state.win, buf)
  
  M.state.is_open = true
  
  -- Window configuration for sidebar appearance
  vim.api.nvim_win_set_option(M.state.win, 'wrap', false)
  vim.api.nvim_win_set_option(M.state.win, 'cursorline', true)
  vim.api.nvim_win_set_option(M.state.win, 'number', false)
  vim.api.nvim_win_set_option(M.state.win, 'relativenumber', false)
  vim.api.nvim_win_set_option(M.state.win, 'signcolumn', 'no')
  vim.api.nvim_win_set_option(M.state.win, 'foldcolumn', '0')
  vim.api.nvim_win_set_option(M.state.win, 'winfixwidth', true)  -- Fixed width like neo-tree
  vim.api.nvim_win_set_option(M.state.win, 'winhl', 'Normal:NeoTreeNormal,FloatBorder:NeoTreeFloatBorder')
  
  return M.state.win
end

-- Close sidebar window
function M.close()
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    vim.api.nvim_win_close(M.state.win, true)
  end
  M.state.is_open = false
  M.state.win = nil
end

-- Toggle sidebar visibility
function M.toggle()
  if M.state.is_open then
    M.close()
  else
    M.open()
  end
end

-- Check if sidebar is currently open
function M.is_open()
  return M.state.is_open and M.state.win and vim.api.nvim_win_is_valid(M.state.win)
end

-- Get sidebar window ID (if open)
function M.get_win()
  return M.is_open() and M.state.win or nil
end

-- Get sidebar window ID even if closed (for window stack tracking)
function M.get_win_id()
  return M.state.win
end

-- Get sidebar buffer ID
function M.get_buf()
  return M.state.buf
end

-- Focus the sidebar
function M.focus()
  if M.is_open() then
    vim.api.nvim_set_current_win(M.state.win)
    return true
  end
  return false
end

-- Update sidebar width
function M.set_width(new_width)
  M.config.width = new_width
  
  -- If sidebar is open, resize it
  if M.is_open() then
    vim.api.nvim_win_set_width(M.state.win, new_width)
  end
  
  -- Update state if available
  local ok, state = pcall(require, 'neotex.plugins.tools.himalaya.state')
  if ok then
    state.set_sidebar_width(new_width)
  end
end

-- Get current width
function M.get_width()
  return M.config.width
end

-- Set sidebar position (left/right)
function M.set_position(position)
  if position ~= 'left' and position ~= 'right' then
    error("Position must be 'left' or 'right'")
  end
  
  M.config.position = position
  
  -- Update state if available
  local ok, state = pcall(require, 'neotex.plugins.tools.himalaya.state')
  if ok then
    state.set_sidebar_position(position)
  end
  
  -- If sidebar is open, we need to recreate it
  if M.is_open() then
    local was_focused = vim.api.nvim_get_current_win() == M.state.win
    local content = nil
    
    -- Preserve content before closing
    if vim.api.nvim_buf_is_valid(M.state.buf) then
      content = vim.api.nvim_buf_get_lines(M.state.buf, 0, -1, false)
    end
    
    M.close()
    M.open()
    
    -- Restore content if we had any
    if content then
      M.update_content(content)
    end
    
    if not was_focused then
      -- Return focus to a main window (not sidebar)
      local wins = vim.api.nvim_list_wins()
      for _, win in ipairs(wins) do
        if win ~= M.state.win then
          vim.api.nvim_set_current_win(win)
          break
        end
      end
    end
  end
end

-- Check if current window is the sidebar
function M.is_current_window()
  return M.is_open() and vim.api.nvim_get_current_win() == M.state.win
end

-- Auto-resize handler for VimResized event
function M.handle_resize()
  if M.is_open() then
    local height = vim.o.lines - 2
    vim.api.nvim_win_set_height(M.state.win, height)
  end
end

-- Update sidebar content
function M.update_content(lines)
  if not M.state.buf or not vim.api.nvim_buf_is_valid(M.state.buf) then
    return false
  end
  
  -- Make buffer modifiable
  vim.api.nvim_buf_set_option(M.state.buf, 'modifiable', true)
  
  -- Set content
  vim.api.nvim_buf_set_lines(M.state.buf, 0, -1, false, lines)
  
  -- Make buffer read-only again
  vim.api.nvim_buf_set_option(M.state.buf, 'modifiable', false)
  
  return true
end

-- Setup autocommands for sidebar management
function M.setup_autocmds()
  local group = vim.api.nvim_create_augroup('HimalayaSidebar', { clear = true })
  
  -- Handle window resize
  vim.api.nvim_create_autocmd('VimResized', {
    group = group,
    callback = M.handle_resize,
    desc = 'Resize Himalaya sidebar on Vim resize'
  })
  
  -- Handle sidebar buffer events
  vim.api.nvim_create_autocmd({'BufWinEnter', 'WinEnter'}, {
    group = group,
    callback = function(args)
      if args.buf == M.state.buf then
        -- Ensure correct window options when entering sidebar
        vim.opt_local.wrap = false
        vim.opt_local.cursorline = true
      end
    end,
    desc = 'Configure Himalaya sidebar window options'
  })
end

-- Initialize sidebar (call once)
function M.init()
  M.setup_autocmds()
end

return M