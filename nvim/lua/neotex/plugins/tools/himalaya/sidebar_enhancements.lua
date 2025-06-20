-- Sidebar Performance Enhancements
-- Optimizations specifically for sidebar operations

local M = {}

local sidebar = require('neotex.plugins.tools.himalaya.sidebar')

-- Cache for sidebar state to avoid rebuilds
M.sidebar_cache = {
  last_content_hash = nil,
  last_cursor_pos = nil,
  last_email_count = nil
}

-- Smart sidebar update that only changes what's necessary
function M.smart_sidebar_update(new_lines)
  local buf = sidebar.get_buf()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  
  -- Get current content
  local current_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  
  -- Calculate content hash to detect changes
  local new_hash = vim.fn.sha256(table.concat(new_lines, '\n'))
  local current_hash = vim.fn.sha256(table.concat(current_lines, '\n'))
  
  -- Only update if content actually changed
  if new_hash ~= current_hash then
    -- Save current cursor position
    local win = sidebar.get_win()
    local cursor_pos = win and vim.api.nvim_win_get_cursor(win) or {1, 0}
    
    -- Update content
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    
    -- Restore cursor position if sidebar window is still valid
    if win and vim.api.nvim_win_is_valid(win) then
      -- Ensure cursor position is within bounds
      local max_line = math.max(1, #new_lines)
      local safe_line = math.min(cursor_pos[1], max_line)
      pcall(vim.api.nvim_win_set_cursor, win, {safe_line, cursor_pos[2]})
    end
    
    -- Update cache
    M.sidebar_cache.last_content_hash = new_hash
    M.sidebar_cache.last_cursor_pos = cursor_pos
    M.sidebar_cache.last_email_count = #new_lines - 4 -- Subtract header lines
    
    return true
  end
  
  return false -- No update needed
end

-- Enhanced email removal with visual feedback
function M.remove_email_with_animation(email_index)
  local buf = sidebar.get_buf()
  local win = sidebar.get_win()
  
  if not buf or not win or not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then
    return false
  end
  
  local line_num = email_index + 4 -- Account for header lines
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  
  if line_num > #lines then
    return false
  end
  
  -- Add visual indicator temporarily
  local original_line = lines[line_num]
  local dimmed_line = '  [DELETING] ' .. original_line:gsub('^%s*', '')
  
  -- Update the line to show deletion status
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf, line_num - 1, line_num, false, {dimmed_line})
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  -- After a short delay, remove the line completely
  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_set_option(buf, 'modifiable', true)
      vim.api.nvim_buf_set_lines(buf, line_num - 1, line_num, false, {})
      vim.api.nvim_buf_set_option(buf, 'modifiable', false)
      
      -- Adjust cursor if needed
      local current_cursor = vim.api.nvim_win_get_cursor(win)
      if current_cursor[1] >= line_num then
        local new_line = math.max(5, current_cursor[1] - 1) -- Don't go above header
        pcall(vim.api.nvim_win_set_cursor, win, {new_line, current_cursor[2]})
      end
    end
  end, 200) -- 200ms animation delay
  
  return true
end

-- Optimized email list formatting with caching
function M.format_email_list_cached(emails)
  local ui = require('neotex.plugins.tools.himalaya.ui')
  
  -- Use original formatting but cache results
  local email_hash = vim.fn.sha256(vim.json.encode(emails))
  
  if M.sidebar_cache.last_format_hash == email_hash and M.sidebar_cache.last_formatted_lines then
    return M.sidebar_cache.last_formatted_lines
  end
  
  local lines = ui.format_email_list(emails)
  
  -- Cache the result
  M.sidebar_cache.last_format_hash = email_hash
  M.sidebar_cache.last_formatted_lines = lines
  
  return lines
end

-- Keyboard navigation enhancements
function M.setup_enhanced_navigation()
  local buf = sidebar.get_buf()
  if not buf then
    return
  end
  
  -- Add quick navigation keys
  local keymap_opts = { buffer = buf, silent = true, nowait = true }
  
  -- Fast scroll navigation
  vim.keymap.set('n', 'J', function()
    local current_line = vim.fn.line('.')
    local new_line = math.min(vim.fn.line('$'), current_line + 5)
    vim.api.nvim_win_set_cursor(0, {new_line, 0})
  end, vim.tbl_extend('force', keymap_opts, { desc = 'Jump down 5 emails' }))
  
  vim.keymap.set('n', 'K', function()
    local current_line = vim.fn.line('.')
    local new_line = math.max(5, current_line - 5) -- Don't go above email list start
    vim.api.nvim_win_set_cursor(0, {new_line, 0})
  end, vim.tbl_extend('force', keymap_opts, { desc = 'Jump up 5 emails' }))
  
  -- Quick top/bottom navigation
  vim.keymap.set('n', 'gg', function()
    vim.api.nvim_win_set_cursor(0, {5, 0}) -- First email line
  end, vim.tbl_extend('force', keymap_opts, { desc = 'Go to first email' }))
  
  vim.keymap.set('n', 'G', function()
    vim.api.nvim_win_set_cursor(0, {vim.fn.line('$'), 0}) -- Last line
  end, vim.tbl_extend('force', keymap_opts, { desc = 'Go to last email' }))
end

-- Visual improvements for better UX
function M.setup_visual_enhancements()
  local buf = sidebar.get_buf()
  if not buf then
    return
  end
  
  -- Set up highlights for better visual feedback
  vim.api.nvim_buf_set_option(buf, 'cursorline', true)
  
  -- Create highlight groups for email states
  vim.api.nvim_set_hl(0, 'HimalayaEmailUnread', { bold = true, fg = '#ffffff' })
  vim.api.nvim_set_hl(0, 'HimalayaEmailRead', { fg = '#888888' })
  vim.api.nvim_set_hl(0, 'HimalayaEmailHeader', { bold = true, fg = '#61afef' })
  vim.api.nvim_set_hl(0, 'HimalayaEmailDeleting', { strikethrough = true, fg = '#ff6b6b' })
  
  -- Apply syntax highlighting to buffer
  vim.api.nvim_buf_set_option(buf, 'syntax', 'himalaya')
end

-- Status line integration for email count
function M.get_email_status()
  local buf = sidebar.get_buf()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return ''
  end
  
  local emails = vim.b[buf].himalaya_emails
  local account = vim.b[buf].himalaya_account
  local folder = vim.b[buf].himalaya_folder
  
  if emails and account and folder then
    local total = #emails
    local current_line = vim.fn.line('.')
    local email_line = math.max(0, current_line - 4)
    
    if email_line > 0 and email_line <= total then
      return string.format('📧 %s/%s [%d/%d]', account, folder, email_line, total)
    else
      return string.format('📧 %s/%s [%d emails]', account, folder, total)
    end
  end
  
  return '📧 Himalaya'
end

-- Apply all sidebar enhancements
function M.apply_enhancements()
  -- Override sidebar update function
  local original_update = sidebar.update_content
  sidebar.update_content = M.smart_sidebar_update
  
  -- Setup enhanced navigation and visuals
  M.setup_enhanced_navigation()
  M.setup_visual_enhancements()
  
  vim.notify('Sidebar enhancements applied', vim.log.levels.INFO)
end

-- Create commands
function M.setup_commands()
  vim.api.nvim_create_user_command('HimalayaSidebarEnhance', M.apply_enhancements, {
    desc = 'Apply sidebar performance enhancements'
  })
  
  vim.api.nvim_create_user_command('HimalayaEmailStatus', function()
    local status = M.get_email_status()
    vim.notify(status, vim.log.levels.INFO)
  end, {
    desc = 'Show current email status'
  })
end

return M