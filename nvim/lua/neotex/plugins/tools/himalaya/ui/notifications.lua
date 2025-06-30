-- Smart notification system for Himalaya
-- Provides context-aware error messages and automatic actions

local M = {}

-- Dependencies
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local config = require('neotex.plugins.tools.himalaya.core.config')
local state = require('neotex.plugins.tools.himalaya.core.state')
local notify = require('neotex.util.notifications')

-- Error patterns and handlers
M.error_map = {
  -- UIDVALIDITY errors
  {
    pattern = 'UIDVALIDITY',
    message = 'Maildir structure issue detected',
    action = 'Run :HimalayaHealth for details',
    level = vim.log.levels.WARN,
    auto_action = function()
      -- Show health check after a delay
      vim.defer_fn(function()
        require('neotex.plugins.tools.himalaya.setup.health').show_report(true)
      end, 2000)
    end
  },
  
  -- Authentication failures
  {
    pattern = 'Authentication failed',
    message = 'OAuth token expired',
    action = 'Refreshing automatically...',
    level = vim.log.levels.INFO,
    auto_action = function()
      local oauth = require('neotex.plugins.tools.himalaya.sync.oauth')
      oauth.refresh()
    end
  },
  
  -- Socket timeout (often OAuth related)
  {
    pattern = 'Socket timeout',
    message = 'Connection timeout',
    action = 'This often means OAuth token expired',
    level = vim.log.levels.WARN,
    auto_action = function()
      local oauth = require('neotex.plugins.tools.himalaya.sync.oauth')
      if not oauth.is_valid() then
        oauth.refresh()
      end
    end
  },
  
  -- XOAUTH2 specific
  {
    pattern = 'XOAUTH2.*failed',
    message = 'OAuth authentication failed',
    action = 'Attempting token refresh...',
    level = vim.log.levels.WARN,
    auto_action = function()
      local oauth = require('neotex.plugins.tools.himalaya.sync.oauth')
      oauth.refresh()
    end
  },
  
  -- Lock failures
  {
    pattern = 'locked',
    message = 'Another sync is already running',
    action = 'Wait for it to complete or run :HimalayaCleanup',
    level = vim.log.levels.INFO
  },
  
  -- Network issues
  {
    pattern = 'Connection refused',
    message = 'Cannot connect to mail server',
    action = 'Check network connection',
    level = vim.log.levels.ERROR
  },
  
  -- Maildir issues
  {
    pattern = 'No such file or directory.*Mail',
    message = 'Mail directory not found',
    action = 'Run :HimalayaSetup to create maildir',
    level = vim.log.levels.ERROR
  },
  
  -- Missing credentials
  {
    pattern = 'Missing OAuth2 credentials',
    message = 'OAuth not configured',
    action = 'Run: himalaya account configure gmail',
    level = vim.log.levels.ERROR
  }
}

-- Success patterns
M.success_patterns = {
  {
    pattern = 'Sync completed successfully',
    message = 'Email synced',
    level = vim.log.levels.INFO
  },
  {
    pattern = 'OAuth token refreshed',
    message = 'Authentication updated',
    level = vim.log.levels.INFO
  },
  {
    pattern = 'messages, %d+ recent',
    transform = function(text)
      local total, recent = text:match('(%d+) messages, (%d+) recent')
      if total and recent then
        return string.format('Found %s emails (%s new)', total, recent)
      end
      return text
    end,
    level = vim.log.levels.INFO
  }
}

-- Handle sync errors intelligently
function M.handle_sync_error(error_text)
  if not error_text then return end
  
  -- Check error patterns
  for _, handler in ipairs(M.error_map) do
    if error_text:match(handler.pattern) then
      -- Show user-friendly message
      local msg = handler.message
      if handler.action then
        msg = msg .. '. ' .. handler.action
      end
      
      if handler.level == vim.log.levels.ERROR then
        logger.error(msg)
      elseif handler.level == vim.log.levels.WARN then
        logger.warn(msg)
      else
        logger.info(msg)
      end
      
      -- Run automatic action if available
      if handler.auto_action then
        handler.auto_action()
      end
      
      return true -- Handled
    end
  end
  
  -- Generic error
  logger.error('Sync error: ' .. error_text)
  return false
end

-- Handle success messages
function M.handle_success(text)
  if not text then return end
  
  for _, handler in ipairs(M.success_patterns) do
    if text:match(handler.pattern) then
      local msg = text
      
      -- Transform message if function provided
      if handler.transform then
        msg = handler.transform(text)
      elseif handler.message then
        msg = handler.message
      end
      
      logger.info(msg)
      return true
    end
  end
  
  return false
end

-- Wrap notifications with smart handling and unified system integration
function M.notify(text, level)
  -- Try to handle as error
  if level == 'error' then
    if M.handle_sync_error(text) then
      return
    end
  end
  
  -- Try to handle as success
  if level == 'info' then
    if M.handle_success(text) then
      return
    end
  end
  
  -- Use unified notification system
  if level == 'error' then
    notify.himalaya(text, notify.categories.ERROR)
  elseif level == 'warn' then
    notify.himalaya(text, notify.categories.WARNING)
  else
    notify.himalaya(text, notify.categories.STATUS)
  end
end

-- Show notification with proper categorization
function M.show(message, level, context)
  context = context or {}
  
  -- Map string levels to categories
  local category = notify.categories.STATUS
  
  if level == 'error' then
    category = notify.categories.ERROR
  elseif level == 'warn' then
    category = notify.categories.WARNING
  elseif level == 'info' then
    -- Check if it's a user action
    if context.user_action or message:match('sent') or message:match('deleted') or message:match('moved') then
      category = notify.categories.USER_ACTION
    else
      category = notify.categories.STATUS
    end
  elseif level == 'debug' then
    category = notify.categories.BACKGROUND
  end
  
  -- Use the himalaya-specific notification function
  notify.himalaya(message, category, context)
end

-- Show sync progress in a simple way
function M.show_sync_progress(progress)
  -- Disable sync progress messages - they're too repetitive
  -- Progress is shown in the sidebar header instead
  return
end

-- Show setup hints based on current issues
function M.show_setup_hints()
  local health = require('neotex.plugins.tools.himalaya.setup.health')
  local result = health.check()
  
  if result.ok then
    return -- Everything is fine
  end
  
  -- Find the most important issue
  local priority_order = {
    'Binaries',
    'OAuth Tokens',
    'Maildir Structure',
    'UIDVALIDITY Files',
    'Sync Processes',
    'Folder Mappings'
  }
  
  for _, check_name in ipairs(priority_order) do
    for _, check in ipairs(result.report) do
      if check.name == check_name and not check.ok then
        logger.warn(string.format('⚠️  %s issue detected. %s', check.name, check.fix or 'Run :HimalayaHealth'))
        return -- Show only the most important issue
      end
    end
  end
end

-- Initialize notification system
function M.setup()
  -- Nothing needed for now, using logger directly
end

-- Simple notification show function
function M.show(text, level)
  level = level or 'info'
  M.notify(text, level)
end

return M