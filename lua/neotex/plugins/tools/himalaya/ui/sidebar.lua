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
    vim.opt_local.mouse = 'a'  -- Ensure mouse is enabled
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
    -- Save cursor position before closing
    local cursor_pos = vim.api.nvim_win_get_cursor(M.state.win)
    local state = require('neotex.plugins.tools.himalaya.core.state')
    state.set('sidebar.cursor_line', cursor_pos[1])
    
    -- Get the window's buffer before closing
    local buf = vim.api.nvim_win_get_buf(M.state.win)
    
    -- Close the window
    vim.api.nvim_win_close(M.state.win, true)
    
    -- Also delete the buffer to ensure clean state
    if buf and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
  
  -- Reset state
  M.state.is_open = false
  M.state.win = nil
  M.state.buf = nil
end

-- Close sidebar and clean up buffer completely
function M.close_and_cleanup()
  -- Close the window first
  M.close()
  
  -- Delete the buffer to prevent it from lingering
  if M.state.buf and vim.api.nvim_buf_is_valid(M.state.buf) then
    vim.api.nvim_buf_delete(M.state.buf, { force = true })
  end
  M.state.buf = nil
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
  local ok, state = pcall(require, 'neotex.plugins.tools.himalaya.core.state')
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
  local ok, state = pcall(require, 'neotex.plugins.tools.himalaya.core.state')
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

-- Update sidebar content with optimized rendering to prevent flicker
function M.update_content(lines)
  if not M.state.buf or not vim.api.nvim_buf_is_valid(M.state.buf) then
    return false
  end
  
  -- Extract metadata if present
  local metadata = nil
  local line_data = {}
  
  if type(lines) == 'table' then
    if lines.metadata then
      metadata = lines.metadata
      -- Extract array elements when metadata exists
      local i = 1
      while lines[i] ~= nil do
        local line = lines[i]
        -- Ensure each element is a string
        if type(line) == 'string' then
          table.insert(line_data, line)
        elseif type(line) == 'number' then
          table.insert(line_data, tostring(line))
        else
          -- Convert any other type to string
          table.insert(line_data, tostring(line or ''))
        end
        i = i + 1
      end
    else
      -- Simple array without metadata
      for i, line in ipairs(lines) do
        if type(line) == 'string' then
          table.insert(line_data, line)
        elseif type(line) == 'number' then
          table.insert(line_data, tostring(line))
        else
          table.insert(line_data, tostring(line or ''))
        end
      end
    end
  end
  
  -- Ensure we have at least an empty array
  if #line_data == 0 then
    line_data = {''}  -- nvim_buf_set_lines needs at least one element
  end
  
  -- Save cursor position
  local cursor_pos = nil
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    cursor_pos = vim.api.nvim_win_get_cursor(M.state.win)
  end
  
  -- Disable syntax and other expensive features during update
  local eventignore = vim.o.eventignore
  vim.o.eventignore = 'all'
  
  -- Make buffer modifiable
  vim.api.nvim_buf_set_option(M.state.buf, 'modifiable', true)
  
  -- Get current lines for comparison
  local current_lines = vim.api.nvim_buf_get_lines(M.state.buf, 0, -1, false)
  
  -- Only update if content has actually changed
  local content_changed = false
  if #current_lines ~= #line_data then
    content_changed = true
  else
    for i = 1, #line_data do
      if current_lines[i] ~= line_data[i] then
        content_changed = true
        break
      end
    end
  end
  
  if content_changed then
    -- Ensure line_data is a valid array
    if type(line_data) ~= 'table' then
      line_data = {}
    end
    
    -- Set buffer lines
    local ok, err = pcall(vim.api.nvim_buf_set_lines, M.state.buf, 0, -1, false, line_data)
    if not ok then
      -- Silently fail - don't notify user about internal errors
      return false
    end
  end
  
  -- Make buffer read-only again
  vim.api.nvim_buf_set_option(M.state.buf, 'modifiable', false)
  
  -- Restore eventignore
  vim.o.eventignore = eventignore
  
  -- Apply highlighting if metadata is provided
  if metadata then
    M.apply_email_highlighting(metadata)
  end
  
  -- Restore cursor position if it was saved and is still valid
  if cursor_pos and M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    local line_count = vim.api.nvim_buf_line_count(M.state.buf)
    if cursor_pos[1] <= line_count then
      vim.api.nvim_win_set_cursor(M.state.win, cursor_pos)
    end
  end
  
  return true
end

-- Update only specific lines (for header updates)
function M.update_header_lines(header_lines)
  local notify = require('neotex.util.notifications')
  if notify.config.modules.himalaya.debug_mode then
    notify.himalaya('sidebar.update_header_lines called with ' .. #header_lines .. ' lines', notify.categories.BACKGROUND)
    for i, line in ipairs(header_lines) do
      notify.himalaya('  Line ' .. i .. ': ' .. line, notify.categories.BACKGROUND)
    end
  end
  
  if not M.state.buf or not vim.api.nvim_buf_is_valid(M.state.buf) then
    return false
  end
  
  local current_lines = vim.api.nvim_buf_get_lines(M.state.buf, 0, -1, false)
  if #current_lines < #header_lines then
    return false -- Not enough lines, do full update instead
  end
  
  -- Check if header actually changed
  local header_changed = false
  for i = 1, #header_lines do
    if current_lines[i] ~= header_lines[i] then
      header_changed = true
      break
    end
  end
  
  if not header_changed then
    return true -- No update needed
  end
  
  -- Update only the header lines
  vim.api.nvim_buf_set_option(M.state.buf, 'modifiable', true)
  
  for i = 1, #header_lines do
    vim.api.nvim_buf_set_lines(M.state.buf, i-1, i, false, {header_lines[i]})
  end
  
  vim.api.nvim_buf_set_option(M.state.buf, 'modifiable', false)
  
  return true
end

-- Apply email highlighting based on status
function M.apply_email_highlighting(metadata)
  if not M.state.win or not vim.api.nvim_win_is_valid(M.state.win) then
    return
  end
  
  -- Clear existing matches for this window
  vim.api.nvim_win_call(M.state.win, function()
    vim.fn.clearmatches()
  end)
  
  if not metadata then return end
  
  -- Apply highlighting based on email metadata
  vim.api.nvim_win_call(M.state.win, function()
    local state = require('neotex.plugins.tools.himalaya.core.state')
    
    for line_num, data in pairs(metadata) do
      -- Apply checkbox highlighting for selected emails
      if data.selected then
        -- Highlight selected checkbox
        vim.fn.matchaddpos('HimalayaCheckboxSelected', {{line_num, 1, 3}})
        -- Also highlight the whole line for selected emails
        vim.fn.matchaddpos('HimalayaSelected', {{line_num}})
      else
        -- Highlight unselected checkbox
        vim.fn.matchaddpos('HimalayaCheckbox', {{line_num, 1, 3}})
      end
      
      -- Apply status highlighting (starred/unread) first with lower priority
      if data.starred then
        -- Starred emails get orange highlighting
        vim.fn.matchaddpos('HimalayaStarred', {{line_num}}, 10)
      elseif not data.seen then
        -- Unread emails get blue highlighting
        vim.fn.matchaddpos('HimalayaUnread', {{line_num}}, 10)
      end
      
      -- Apply author highlighting (bold) with higher priority so it overrides line highlights
      if data.from_start and data.from_end then
        if data.starred then
          -- Starred emails get bold orange author
          vim.fn.matchaddpos('HimalayaAuthorStarred', {{line_num, data.from_start, data.from_end - data.from_start + 1}}, 20)
        elseif not data.seen then
          -- Unread emails get bold blue author
          vim.fn.matchaddpos('HimalayaAuthorUnread', {{line_num, data.from_start, data.from_end - data.from_start + 1}}, 20)
        else
          -- Read emails get just bold author
          vim.fn.matchaddpos('HimalayaAuthor', {{line_num, data.from_start, data.from_end - data.from_start + 1}}, 20)
        end
      end
    end
  end)
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

-- Setup highlight groups for email status
function M.setup_highlights()
  -- Unread emails (light blue, not bold)
  vim.api.nvim_set_hl(0, 'HimalayaUnread', { fg = '#87CEEB' })
  
  -- Starred emails (light orange, not bold) 
  vim.api.nvim_set_hl(0, 'HimalayaStarred', { fg = '#FFA07A' })
  
  -- Selected emails (for multi-select)
  vim.api.nvim_set_hl(0, 'HimalayaSelected', { bg = '#444444', fg = '#FFFFFF' })
  
  -- Checkbox indicators
  vim.api.nvim_set_hl(0, 'HimalayaCheckbox', { fg = '#888888' })
  vim.api.nvim_set_hl(0, 'HimalayaCheckboxSelected', { fg = '#00FF00', bold = true })
  
  -- Author field (bold only)
  vim.api.nvim_set_hl(0, 'HimalayaAuthor', { bold = true })
  
  -- Author field for unread emails (bold and blue)
  vim.api.nvim_set_hl(0, 'HimalayaAuthorUnread', { fg = '#87CEEB', bold = true })
  
  -- Author field for starred emails (bold and orange)
  vim.api.nvim_set_hl(0, 'HimalayaAuthorStarred', { fg = '#FFA07A', bold = true })
end

-- Initialize sidebar (call once)
function M.init()
  M.setup_autocmds()
  M.setup_highlights()
end

-- Export state for debugging
M.get_state = function()
  return M.state
end

return M