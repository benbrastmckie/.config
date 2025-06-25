-- Automatic Sidebar Updates for Seamless Email Experience
-- Keeps email sidebar refreshed and up-to-date automatically

local M = {}

local native_sync = require('neotex.plugins.tools.himalaya.native_sync')
local notify = require('neotex.util.notifications')

-- Configuration
M.config = {
  auto_refresh_interval = 60000, -- 60 seconds
  enabled = true,
  refresh_after_operations = true
}

-- State tracking
M.state = {
  refresh_timer = nil,
  sidebar_open = false,
  last_refresh = 0
}

-- Start automatic refresh timer
function M.start_auto_refresh()
  if not M.config.enabled then return end
  
  -- Stop existing timer
  M.stop_auto_refresh()
  
  M.state.refresh_timer = vim.loop.new_timer()
  M.state.refresh_timer:start(M.config.auto_refresh_interval, M.config.auto_refresh_interval, function()
    vim.schedule(function()
      if M.should_auto_refresh() then
        native_sync.background_sync()
        M.state.last_refresh = vim.loop.now()
      end
    end)
  end)
  
  notify.himalaya('Auto-refresh enabled (60s intervals)', notify.categories.BACKGROUND)
end

-- Stop automatic refresh timer
function M.stop_auto_refresh()
  if M.state.refresh_timer then
    M.state.refresh_timer:stop()
    M.state.refresh_timer:close()
    M.state.refresh_timer = nil
  end
end

-- Check if we should auto-refresh
function M.should_auto_refresh()
  -- Only refresh if sidebar is open
  if not M.is_sidebar_open() then
    return false
  end
  
  -- Don't refresh too frequently
  local now = vim.loop.now()
  if now - M.state.last_refresh < 30000 then -- Minimum 30 seconds between refreshes
    return false
  end
  
  return true
end

-- Check if Himalaya sidebar is currently open
function M.is_sidebar_open()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == 'himalaya-list' then
      M.state.sidebar_open = true
      return true
    end
  end
  M.state.sidebar_open = false
  return false
end

-- Refresh after user operations (send, delete, move, etc.)
function M.refresh_after_operation(operation_name)
  if not M.config.refresh_after_operations then return end
  
  vim.defer_fn(function()
    if M.is_sidebar_open() then
      native_sync.quick_sync()
      notify.himalaya('Refreshed after ' .. operation_name, notify.categories.BACKGROUND)
    end
  end, 2000) -- Wait 2 seconds after operation
end

-- Setup automatic updates system
function M.setup()
  -- Auto-start refresh when opening Himalaya
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'himalaya-list',
    callback = function()
      M.start_auto_refresh()
    end,
    desc = 'Start auto-refresh when opening Himalaya sidebar'
  })
  
  -- Stop refresh when closing all Himalaya windows
  vim.api.nvim_create_autocmd('BufWinLeave', {
    pattern = '*',
    callback = function()
      vim.defer_fn(function()
        if not M.is_sidebar_open() then
          M.stop_auto_refresh()
        end
      end, 100) -- Small delay to check if sidebar is really closed
    end,
    desc = 'Stop auto-refresh when closing Himalaya sidebar'
  })
  
  -- Refresh after common operations
  local operation_commands = {
    'HimalayaSend',
    'HimalayaDelete', 
    'HimalayaMove',
    'HimalayaFlag',
    'HimalayaCopy'
  }
  
  for _, cmd in ipairs(operation_commands) do
    vim.api.nvim_create_autocmd('User', {
      pattern = cmd .. 'Complete',
      callback = function()
        M.refresh_after_operation(cmd:gsub('Himalaya', ''):lower())
      end,
      desc = 'Auto-refresh after ' .. cmd
    })
  end
  
  notify.himalaya('Automatic updates system initialized', notify.categories.BACKGROUND)
end

-- Toggle auto-refresh
function M.toggle()
  M.config.enabled = not M.config.enabled
  
  if M.config.enabled then
    if M.is_sidebar_open() then
      M.start_auto_refresh()
    end
    notify.himalaya('Auto-refresh enabled', notify.categories.USER_ACTION)
  else
    M.stop_auto_refresh()
    notify.himalaya('Auto-refresh disabled', notify.categories.USER_ACTION)
  end
end

-- Manual refresh trigger
function M.manual_refresh()
  if M.is_sidebar_open() then
    native_sync.enhanced_sync()
  else
    notify.himalaya('Open Himalaya sidebar first', notify.categories.WARNING)
  end
end

-- Configuration commands
function M.set_interval(seconds)
  M.config.auto_refresh_interval = seconds * 1000
  
  -- Restart timer with new interval if running
  if M.state.refresh_timer then
    M.start_auto_refresh()
  end
  
  notify.himalaya('Auto-refresh interval set to ' .. seconds .. 's', notify.categories.USER_ACTION)
end

return M