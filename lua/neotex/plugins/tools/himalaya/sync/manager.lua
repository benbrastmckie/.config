-- Unified sync manager for all sync operations
-- Handles both full sync (mbsync) and fast check (himalaya)

-- TODO: Add sync queue for managing multiple sync requests
-- TODO: Implement sync retry logic with exponential backoff
-- TODO: Add sync operation cancellation support
-- TODO: Implement sync scheduling and automatic sync intervals

local M = {}

-- Dependencies
local state = require('neotex.plugins.tools.himalaya.core.state')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local coordinator = require('neotex.plugins.tools.himalaya.sync.coordinator')

-- Start any sync operation
function M.start_sync(sync_type, options)
  options = options or {}
  
  logger.debug('Starting sync: ' .. sync_type)
  
  local notify = require('neotex.util.notifications')
  
  
  -- Set common state
  state.set('sync.type', sync_type)
  state.set('sync.status', 'running')
  state.set('sync.start_time', os.time())
  state.set('sync.message', M.get_status_message(sync_type))
  
  -- Set type-specific state
  if sync_type == 'full' then
    state.set('sync.full.channel', options.channel)
  end
  
  -- Notify UI to update
  M.notify_ui_update()
  
end

-- Update sync progress (for full sync)
function M.update_progress(progress)
  if state.get('sync.type') == 'full' then
    state.set('sync.full.progress', progress)
    M.notify_ui_update()
  end
end

-- Complete any sync operation
function M.complete_sync(sync_type, result)
  result = result or {}
  
  logger.debug('Completing sync: ' .. sync_type .. ', success: ' .. tostring(result.success))
  
  local notify = require('neotex.util.notifications')
  
  
  -- Only update if this is the current sync
  local current_sync_type = state.get('sync.type')
  
  if current_sync_type ~= sync_type then
    logger.warn('Sync type mismatch on completion: current=' .. tostring(current_sync_type) .. ', completing=' .. sync_type)
    -- Don't return - continue with completion even if type doesn't match
    -- This handles race conditions where sync.type gets cleared prematurely
  end
  
  -- Set completion state
  state.set('sync.status', result.success and 'completed' or 'error')
  state.set('sync.end_time', os.time())
  
  -- Store type-specific results
  
  -- Update history
  M.update_history(sync_type, result)
  
  -- Update folder counts if sync was successful
  if result.success then
    logger.debug('Sync completed successfully, updating folder counts')
    M.update_folder_counts()
  end
  
  -- Notify UI immediately
  M.notify_ui_update()
  
  -- Clear sync state after a delay
  vim.defer_fn(function()
    -- Only clear if we're still in the same sync and it's completed
    if state.get('sync.type') == sync_type and state.get('sync.status') ~= 'running' then
      state.set('sync.type', nil)
      state.set('sync.status', 'idle')
      state.set('sync.message', nil)
      M.notify_ui_update()
    end
  end, 5000)
end

-- Get human-readable status message
function M.get_status_message(sync_type)
  if sync_type == 'full' then
    return '⟳ Sync'
  end
  return nil
end

-- Update sync history
function M.update_history(sync_type, result)
  local history = state.get('sync.history', {})
  
  -- Update last sync times
  if sync_type == 'full' then
    history.last_full_sync = os.time()
    history.total_syncs_today = (history.total_syncs_today or 0) + 1
  end
  
  -- Store last error
  if not result.success and result.error then
    history.last_error = result.error
    history.last_error_time = os.time()
    history.last_error_type = sync_type
  end
  
  -- Reset daily counters if needed
  local today = os.date('%Y-%m-%d')
  if history.last_count_date ~= today then
    history.total_syncs_today = (sync_type == 'full') and 1 or 0
    history.total_checks_today = 0
    history.last_count_date = today
  end
  
  state.set('sync.history', history)
end

-- Notify UI components to update
function M.notify_ui_update()
  -- Import here to avoid circular dependencies
  local ok, sidebar = pcall(require, 'neotex.plugins.tools.himalaya.ui.sidebar')
  if not ok then return end
  
  local ok2, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
  if not ok2 then return end
  
  if sidebar.is_open() then
    main.refresh_sidebar_header()
  end
end

-- Get current sync info for display
function M.get_sync_info()
  local info = {
    type = state.get('sync.type'),
    status = state.get('sync.status', 'idle'),
    message = state.get('sync.message'),
    start_time = state.get('sync.start_time'),
    end_time = state.get('sync.end_time'),
  }
  
  -- Add type-specific info
  if info.type == 'full' then
    info.channel = state.get('sync.full.channel')
    info.progress = state.get('sync.full.progress')
  end
  
  return info
end

-- Get sync history
function M.get_history()
  return state.get('sync.history', {})
end

-- Update folder counts after successful sync
-- Cancel current sync operation
function M.cancel_sync()
  local current_type = state.get('sync.type')
  local current_status = state.get('sync.status')
  
  if not current_type or current_status ~= 'running' then
    logger.debug('No sync running to cancel')
    return false
  end
  
  logger.info('Cancelling sync: ' .. current_type)
  
  -- Cancel MBSync if it's running
  if current_type == 'full' then
    local mbsync = require('neotex.plugins.tools.himalaya.sync.mbsync')
    mbsync.cancel_current_sync('user_cancelled')
  end
  
  -- Cancel any async commands related to sync
  local async_commands = require('neotex.plugins.tools.himalaya.core.async_commands')
  local cancelled_count = async_commands.cancel_all_jobs('sync_cancelled')
  
  -- Update state
  state.set('sync.status', 'cancelled')
  state.set('sync.end_time', os.time())
  
  -- Notify user
  local notify = require('neotex.util.notifications')
  notify.himalaya('Sync cancelled by user', notify.categories.USER_ACTION)
  
  -- Clean up state after a delay
  vim.defer_fn(function()
    if state.get('sync.status') == 'cancelled' then
      M.clear_sync_state()
    end
  end, 2000)
  
  -- Notify UI update
  M.notify_ui_update()
  
  logger.debug('Cancelled sync and ' .. cancelled_count .. ' async commands')
  return true
end

-- Check if sync can be cancelled
function M.can_cancel_sync()
  local current_status = state.get('sync.status')
  return current_status == 'running'
end

-- Update folder counts after sync completion
-- This is the single source of truth for updating counts automatically
function M.update_folder_counts()
  local config = require('neotex.plugins.tools.himalaya.core.config')
  local notify = require('neotex.util.notifications')
  
  
  -- Check if folder count update is disabled
  if config.get('sync.skip_folder_count_update', false) then
    logger.debug('Skipping folder count update after sync (disabled in config)')
    return
  end
  
  -- Update counts immediately for responsiveness
  local current_account = state.get('ui.current_account')
  local current_folder = state.get('ui.current_folder')
  
  
  -- If we captured counts during sync, save them immediately
  local progress = state.get('sync.progress')
  if progress and progress.folder_counts then
    local config = require('neotex.plugins.tools.himalaya.core.config')
    local account = config.get_current_account_name()
    
    if account then
      for folder, count in pairs(progress.folder_counts) do
        if count > 0 then
          state.set_folder_count(account, folder, count)
          logger.debug(string.format('Stored sync-captured count: %s/%s = %d', 
            account, folder, count))
        end
      end
    end
  end
  
  -- Fetch the actual count with a minimal delay for file operations to complete
  vim.defer_fn(function()
    local notify = require('neotex.util.notifications')
    
    if current_account and current_folder then
      logger.debug(string.format('Starting folder count update for %s/%s', current_account, current_folder))
      notify.himalaya(string.format('Updating count for %s/%s...', current_account, current_folder), notify.categories.BACKGROUND)
      
      local utils = require('neotex.plugins.tools.himalaya.utils')
      local count = utils.fetch_folder_count(current_account, current_folder)
      
      if count then
        -- Always update the count and timestamp, regardless of value
        state.set_folder_count(current_account, current_folder, count)
        logger.debug(string.format('Updated folder count after sync: %s/%s = %s',
          current_account, current_folder, tostring(count)))
        notify.himalaya(string.format('Updated count: %s/%s = %s', current_account, current_folder, tostring(count)), notify.categories.BACKGROUND)
        
        -- Trigger UI update immediately
        M.notify_ui_update()
      else
        logger.warn(string.format('Failed to get folder count for %s/%s', current_account, current_folder))
        notify.himalaya(string.format('Failed to get count for %s/%s', current_account, current_folder), notify.categories.ERROR)
      end
    else
      logger.warn('Cannot update folder count: missing account or folder')
      notify.himalaya('Cannot update count: missing account/folder', notify.categories.ERROR)
    end
  end, 100)  -- Minimal 100ms delay just for file operations
end

-- Clear sync state (for testing/debugging)
function M.clear_sync_state()
  state.set('sync.type', nil)
  state.set('sync.status', 'idle')
  state.set('sync.message', nil)
  state.set('sync.start_time', nil)
  state.set('sync.end_time', nil)
  state.set('sync.full', {})
  M.notify_ui_update()
end

-- Auto-sync functionality
local auto_sync_timer = nil
local startup_time = nil

-- Start automatic inbox syncing
function M.start_auto_sync()
  -- Initialize coordination
  coordinator.init()
  
  -- Record startup time
  startup_time = os.time()
  
  local config = require('neotex.plugins.tools.himalaya.core.config')
  local notify = require('neotex.util.notifications')
  
  -- Debug notification
  if not _G.HIMALAYA_TEST_MODE then
    notify.himalaya('Starting auto-sync initialization...', notify.categories.BACKGROUND)
  end
  
  -- Check if auto-sync is enabled
  if not config.get('ui.auto_sync_enabled', true) then
    logger.debug('Auto-sync disabled in configuration')
    if not _G.HIMALAYA_TEST_MODE then
      notify.himalaya('Auto-sync disabled in config', notify.categories.BACKGROUND)
    end
    return
  end
  
  -- Get sync interval and startup delay from config
  local sync_interval = config.get('ui.auto_sync_interval', 15 * 60) -- Default 15 minutes
  local startup_delay = config.get('ui.auto_sync_startup_delay', 2) -- Default 2 seconds for testing
  
  logger.debug('Starting auto-sync with interval: ' .. sync_interval .. 's, startup delay: ' .. startup_delay .. 's')
  if not _G.HIMALAYA_TEST_MODE then
    notify.himalaya(string.format('Auto-sync: delay=%ds, interval=%dm', startup_delay, math.floor(sync_interval/60)), notify.categories.BACKGROUND)
  end
  
  -- Clear any existing timer
  M.stop_auto_sync()
  
  -- Start timer with initial delay
  auto_sync_timer = vim.loop.new_timer()
  
  if not auto_sync_timer then
    logger.error('Failed to create auto-sync timer')
    notify.himalaya('Failed to create auto-sync timer', notify.categories.ERROR)
    return
  end
  
  -- Start recurring timer after startup delay
  auto_sync_timer:start(startup_delay * 1000, sync_interval * 1000, vim.schedule_wrap(function()
    if not _G.HIMALAYA_TEST_MODE then
      notify.himalaya('Auto-sync timer triggered', notify.categories.BACKGROUND)
    end
    
    -- Check coordination before syncing
    if not coordinator.should_allow_sync() then
      logger.debug('Auto-sync skipped by coordinator')
      if not _G.HIMALAYA_TEST_MODE then
        notify.himalaya('Auto-sync skipped by coordinator', notify.categories.BACKGROUND)
      end
      return
    end
    
    -- Safety check: ensure we've waited the full startup delay
    if startup_time and (os.time() - startup_time) < startup_delay then
      logger.debug('Sync triggered too early, skipping. Time since startup: ' .. (os.time() - startup_time) .. 's')
      return
    end
    
    -- Only sync if not already syncing
    local current_status = state.get('sync.status', 'idle')
    if current_status ~= 'idle' then
      logger.debug('Skipping auto-sync: sync already in progress (' .. current_status .. ')')
      if not _G.HIMALAYA_TEST_MODE then
        notify.himalaya('Skipping auto-sync: already ' .. current_status, notify.categories.BACKGROUND)
      end
      return
    end
    
    -- Check if config is initialized
    if not config.is_initialized() then
      logger.debug('Skipping auto-sync: config not initialized')
      return
    end
    
    -- Perform inbox sync
    logger.debug('Starting coordinated auto-sync')
    
    -- Show notification in debug mode only
    if notify.config.modules.himalaya.debug_mode then
      notify.himalaya('Auto-syncing inbox (primary coordinator)...', 
                     notify.categories.BACKGROUND)
    end
    
    -- Use the sync_inbox function from main UI module
    local main = require('neotex.plugins.tools.himalaya.ui.main')
    main.sync_inbox()
    
    -- Record sync completion for coordination
    coordinator.record_sync_completion()
  end))
  
  logger.debug('Auto-sync timer started')
  
  -- Show startup notification in debug mode
  if notify.config.modules.himalaya.debug_mode then
    local role = coordinator.is_primary and 'primary coordinator' or 'secondary instance'
    notify.himalaya(string.format('Auto-sync enabled (%s): every %d minutes', 
                                 role, math.floor(sync_interval / 60)), 
                   notify.categories.BACKGROUND)
  end
end

-- Stop automatic syncing
function M.stop_auto_sync()
  if auto_sync_timer then
    auto_sync_timer:stop()
    auto_sync_timer:close()
    auto_sync_timer = nil
    logger.debug('Auto-sync timer stopped')
  end
  
  -- Clean up coordination
  coordinator.cleanup()
end

-- Check if auto-sync is running
function M.is_auto_sync_running()
  return auto_sync_timer ~= nil
end

return M