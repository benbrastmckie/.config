-- Session Management Module
-- Handles session state persistence and restoration

local M = {}

-- Dependencies
local state = require('neotex.plugins.tools.himalaya.core.state')
local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
local email_list = require('neotex.plugins.tools.himalaya.ui.email_list')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local notify = require('neotex.util.notifications')

-- Module state
local module_state = {
  initialized = false,
  session_file = nil,  -- Will be set during init
  auto_restore_enabled = false,  -- Disabled by default per current implementation
}

-- Initialize session module
function M.init(config)
  if module_state.initialized then
    return
  end
  
  -- Set default session file
  module_state.session_file = vim.fn.stdpath('data') .. '/himalaya_session.json'
  
  -- Apply configuration if provided
  if config and config.session then
    if config.session.auto_restore ~= nil then
      module_state.auto_restore_enabled = config.session.auto_restore
    end
    if config.session.file then
      module_state.session_file = config.session.file
    end
  end
  
  module_state.initialized = true
  logger.info('Session module initialized')
end

-- Save current session state
function M.save_session()
  local session_data = {
    version = "1.0",
    timestamp = os.time(),
    state = {
      current_account = state.get_current_account(),
      current_folder = state.get_current_folder(),
      current_page = state.get_current_page(),
      -- Only include selection_mode if the function exists
      selection_mode = state.get_selection_mode and state.get_selection_mode() or false,
      -- Add any other session-relevant state
    },
    ui = {
      sidebar_open = _G.HIMALAYA_TEST_MODE and false or sidebar.is_open(),
      sidebar_width = _G.HIMALAYA_TEST_MODE and 40 or (sidebar.get_width and sidebar.get_width() or 40),
      -- Add other UI state as needed
    },
  }
  
  -- Write session data to file
  local ok, err = pcall(function()
    local json = vim.fn.json_encode(session_data)
    local file = io.open(module_state.session_file, 'w')
    if file then
      file:write(json)
      file:close()
      logger.debug('Session saved', { file = module_state.session_file })
    else
      error('Failed to open session file for writing')
    end
  end)
  
  if not ok then
    logger.error('Failed to save session', { error = err })
    return false
  end
  
  return true
end

-- Restore session state
function M.restore_session()
  -- Check if auto-restore is enabled
  if not module_state.auto_restore_enabled then
    logger.debug('Session auto-restore is disabled')
    return false
  end
  
  -- Check if session file exists
  if vim.fn.filereadable(module_state.session_file) == 0 then
    logger.debug('No session file found')
    return false
  end
  
  local ok, session_data = pcall(function()
    local file = io.open(module_state.session_file, 'r')
    if not file then
      error('Failed to open session file')
    end
    
    local content = file:read('*all')
    file:close()
    
    return vim.fn.json_decode(content)
  end)
  
  if not ok or not session_data then
    logger.error('Failed to load session', { error = session_data })
    return false
  end
  
  -- Validate session data
  if not session_data.version or not session_data.state then
    logger.warn('Invalid session data format')
    return false
  end
  
  -- Check session age (optional - skip old sessions)
  local age_hours = (os.time() - (session_data.timestamp or 0)) / 3600
  if age_hours > 24 then
    logger.info('Session too old, skipping restore', { age_hours = age_hours })
    return false
  end
  
  -- Restore state
  local restored = false
  
  if session_data.state.current_account then
    state.set_current_account(session_data.state.current_account)
    restored = true
  end
  
  if session_data.state.current_folder then
    state.set_current_folder(session_data.state.current_folder)
    restored = true
  end
  
  if session_data.state.current_page then
    state.set_current_page(session_data.state.current_page)
  end
  
  -- Restore UI state if sidebar should be open
  if session_data.ui and session_data.ui.sidebar_open then
    vim.defer_fn(function()
      -- Open sidebar and restore folder
      email_list.toggle_email_sidebar()
      
      -- If we restored a folder, refresh its contents
      if session_data.state.current_folder then
        email_list.refresh_email_list()
      end
    end, 100)
  end
  
  if restored then
    logger.info('Session restored', {
      account = session_data.state.current_account,
      folder = session_data.state.current_folder,
    })
    
    if notify.config.modules.himalaya.debug_mode then
      notify.himalaya('Session restored', notify.categories.BACKGROUND)
    end
  end
  
  return restored
end

-- Clear session file
function M.clear_session()
  if vim.fn.filereadable(module_state.session_file) == 1 then
    local ok = vim.fn.delete(module_state.session_file) == 0
    if ok then
      logger.info('Session cleared')
    else
      logger.error('Failed to delete session file')
    end
    return ok
  end
  return true
end

-- Get session info
function M.get_session_info()
  if vim.fn.filereadable(module_state.session_file) == 0 then
    return nil
  end
  
  local ok, session_data = pcall(function()
    local file = io.open(module_state.session_file, 'r')
    if not file then
      return nil
    end
    
    local content = file:read('*all')
    file:close()
    
    return vim.fn.json_decode(content)
  end)
  
  if ok and session_data then
    return {
      exists = true,
      timestamp = session_data.timestamp,
      age_hours = (os.time() - (session_data.timestamp or 0)) / 3600,
      account = session_data.state and session_data.state.current_account,
      folder = session_data.state and session_data.state.current_folder,
    }
  end
  
  return { exists = false }
end

-- Enable/disable auto-restore
function M.set_auto_restore(enabled)
  module_state.auto_restore_enabled = enabled
  logger.info('Session auto-restore', { enabled = enabled })
end

-- Check if auto-restore is enabled
function M.is_auto_restore_enabled()
  return module_state.auto_restore_enabled
end

return M