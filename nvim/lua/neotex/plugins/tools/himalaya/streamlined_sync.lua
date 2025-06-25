-- Streamlined Himalaya Sync System
-- Fixes: multiple processes, corrupted journals, hanging syncs, OAuth races

local M = {}

local notify = require('neotex.util.notifications')

-- Global state with proper atomic operations
M.state = {
  sync_running = false,
  last_oauth_refresh = 0,
  sync_pid = nil,
  last_sync_time = 0,
  cancel_requested = false,
  -- Cache sync status briefly to avoid repeated system calls
  last_sync_check = 0,
  last_sync_status = false,
  sync_progress = {
    current_folder = nil,
    messages_total = 0,
    messages_synced = 0,
    current_operation = nil
  }
}

local LOCK_FILE = '/tmp/himalaya-sync.lock'
local OAUTH_MARKER = '/tmp/himalaya-oauth-fresh'
local SYNC_TIMEOUT = 120 -- 2 minutes
local OAUTH_REFRESH_INTERVAL = 3000 -- 50 minutes

-- Atomic lock creation using shell built-in 'set -C'
function M.acquire_lock()
  local cmd = string.format('(set -C; echo $$ > %s) 2>/dev/null', LOCK_FILE)
  local result = os.execute(cmd)
  
  if result == 0 then
    return true
  end
  
  -- Check if existing lock is stale
  local handle = io.open(LOCK_FILE, 'r')
  if handle then
    local pid = handle:read('*a'):match('%d+')
    handle:close()
    
    if pid then
      -- Check if process still exists
      local check_result = os.execute('kill -0 ' .. pid .. ' 2>/dev/null')
      if check_result ~= 0 then
        -- Stale lock, remove it
        os.remove(LOCK_FILE)
        return M.acquire_lock() -- Retry once
      end
    end
  end
  
  return false
end

function M.release_lock()
  os.remove(LOCK_FILE)
end

-- Clean up corrupted sync state
function M.clean_sync_state(silent)
  silent = silent or false
  
  local cleanup_commands = {
    -- Remove corrupted journal files (all sizes)
    'find ~/Mail/Gmail -name ".mbsyncstate.journal" -delete 2>/dev/null',
    -- Remove temporary sync files
    'find ~/Mail/Gmail -name ".mbsyncstate.new" -delete 2>/dev/null',
    -- Remove any lock files
    'find ~/Mail/Gmail -name ".mbsyncstate.lock" -delete 2>/dev/null'
  }
  
  for _, cmd in ipairs(cleanup_commands) do
    os.execute(cmd)
  end
  
  if not silent then
    notify.himalaya('Sync state cleaned', notify.categories.STATUS)
  end
end

-- Kill any existing mbsync processes
function M.kill_existing_processes()
  local handle = io.popen('pgrep mbsync 2>/dev/null')
  local processes = {}
  
  if handle then
    for line in handle:lines() do
      if line and line ~= "" then
        table.insert(processes, line)
      end
    end
    handle:close()
  end
  
  if #processes > 0 then
    for _, pid in ipairs(processes) do
      os.execute('kill -TERM ' .. pid .. ' 2>/dev/null')
    end
    
    -- Wait a moment, then force kill if needed
    vim.defer_fn(function()
      for _, pid in ipairs(processes) do
        os.execute('kill -KILL ' .. pid .. ' 2>/dev/null')
      end
    end, 2000)
    
    notify.himalaya(string.format('Killed %d mbsync processes', #processes), notify.categories.STATUS)
  end
end

-- Check OAuth token validity - mbsync handles refresh automatically
function M.ensure_oauth_fresh()
  -- For mbsync with secret-tool, we don't need manual refresh
  -- The token is automatically refreshed by Himalaya's OAuth flow
  -- Just check if we have a token stored
  
  local check_cmd = 'secret-tool lookup service himalaya-cli username gmail-smtp-oauth2-access-token 2>/dev/null'
  local handle = io.popen(check_cmd)
  local token = nil
  
  if handle then
    token = handle:read('*a')
    handle:close()
  end
  
  if token and token:match('%S') then
    -- We have a token, assume it's valid (mbsync will handle refresh if needed)
    M.state.last_oauth_refresh = os.time()
    return true
  else
    notify.himalaya('No OAuth token found. Run: himalaya account configure gmail', notify.categories.ERROR)
    return false
  end
end

-- Check if sync is running globally (across all nvim instances)
function M.is_sync_running_globally()
  local now = os.time()
  
  -- Use cached result if checked within last 2 seconds (for responsiveness)
  if (now - M.state.last_sync_check) < 2 then
    return M.state.last_sync_status
  end
  
  local is_running = false
  
  -- Check for lock file first
  if vim.fn.filereadable(LOCK_FILE) == 1 then
    local handle = io.open(LOCK_FILE, 'r')
    if handle then
      local pid = handle:read('*a'):match('%d+')
      handle:close()
      
      if pid then
        -- Check if process still exists
        local check_result = os.execute('kill -0 ' .. pid .. ' 2>/dev/null')
        if check_result == 0 then
          is_running = true
        else
          -- Stale lock file, remove it
          os.remove(LOCK_FILE)
        end
      end
    end
  end
  
  -- Also check for any mbsync processes (only if lock file check didn't find anything)
  if not is_running then
    local handle = io.popen('pgrep mbsync 2>/dev/null')
    if handle then
      local output = handle:read('*a')
      handle:close()
      if output and output:match('%d+') then
        is_running = true
      end
    end
  end
  
  -- Cache the result
  M.state.last_sync_check = now
  M.state.last_sync_status = is_running
  
  return is_running
end

-- Streamlined sync function with user action awareness
function M.sync_mail(force_full, is_user_action)
  is_user_action = is_user_action or false
  
  -- Check if sync is already running globally
  if M.is_sync_running_globally() then
    if is_user_action then
      notify.himalaya('Sync is already in progress', notify.categories.USER_ACTION)
    end
    return false
  end
  
  -- Prevent multiple syncs from this instance
  if M.state.sync_running then
    if is_user_action then
      notify.himalaya('Sync already in progress in this instance', notify.categories.WARNING)
    end
    return false
  end
  
  -- Acquire lock
  if not M.acquire_lock() then
    if is_user_action then
      notify.himalaya('Another sync process is running', notify.categories.USER_ACTION)
    end
    return false
  end
  
  M.state.sync_running = true
  
  -- Clean up any existing processes first
  M.kill_existing_processes()
  
  -- Small delay to ensure processes are gone
  vim.defer_fn(function()
    M._perform_sync(force_full, is_user_action)
  end, 1000)
  
  return true
end

function M._perform_sync(force_full, is_user_action)
  -- Ensure OAuth is fresh
  if not M.ensure_oauth_fresh() then
    M._sync_complete(false, 'OAuth refresh failed')
    return
  end
  
  -- Always clean sync state to prevent corruption
  M.clean_sync_state()
  
  -- Build mbsync command - use specific channel for inbox, avoid full sync
  local cmd
  if force_full then
    -- For full sync, sync all configured channels
    cmd = { 'timeout', tostring(SYNC_TIMEOUT), 'mbsync', '-V', '-a' } -- -a syncs all channels
  else
    -- Quick inbox-only sync
    cmd = { 'timeout', tostring(SYNC_TIMEOUT / 2), 'mbsync', '-V', 'gmail-inbox' }
  end
  
  if is_user_action then
    notify.himalaya('Sync has been started', notify.categories.USER_ACTION)
  end
  -- No notification for auto-sync on startup
  
  -- Start sidebar sync status updates
  local ui = require('neotex.plugins.tools.himalaya.ui')
  ui.start_sync_status_updates()
  
  -- Use vim.fn.jobstart for better control
  local output = {}
  local job_id = vim.fn.jobstart(cmd, {
    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        if line and line ~= "" then
          table.insert(output, line)
          
          -- Parse sync progress
          M._parse_sync_progress(line)
          
          -- Show important progress lines with enhanced info
          if line:match('messages') or line:match('recent') or line:match('Connecting') then
            local progress_info = ""
            if M.state.sync_progress.messages_total > 0 then
              progress_info = string.format(" (%d/%d)", M.state.sync_progress.messages_synced, M.state.sync_progress.messages_total)
            end
            notify.himalaya(line .. progress_info, notify.categories.STATUS)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      for _, line in ipairs(data) do
        if line and line ~= "" then
          table.insert(output, line)
        end
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        M._sync_complete(true, 'Sync completed successfully')
      else
        -- Check if cancellation was requested - don't show error for intentional cancellation
        if M.state.cancel_requested and exit_code == 143 then
          -- Intentional cancellation, don't show error message
          M.state.sync_running = false
          M.state.sync_pid = nil
          M.state.cancel_requested = false
          M.release_lock()
          
          -- Stop sidebar updates
          local ui = require('neotex.plugins.tools.himalaya.ui')
          ui.stop_sync_status_updates()
          return
        end
        
        -- Handle other exit codes
        local error_msg = 'Sync failed'
        if exit_code == 124 then
          error_msg = 'Sync timed out - Gmail may be slow'
        elseif exit_code == 143 then
          error_msg = 'Sync was terminated'
        elseif #output > 0 then
          local last_line = output[#output] or ''
          if last_line:match('Connection timed out') then
            error_msg = 'Connection timeout - try again later'
          elseif last_line:match('Authentication failed') then
            error_msg = 'OAuth token expired - reconfigure account'
          else
            error_msg = error_msg .. ': ' .. last_line
          end
        end
        M._sync_complete(false, error_msg)
      end
    end
  })
  
  if job_id <= 0 then
    M._sync_complete(false, 'Failed to start sync process')
  else
    M.state.sync_pid = job_id
  end
end

function M._sync_complete(success, message)
  M.state.sync_running = false
  M.state.sync_pid = nil
  M.state.last_sync_time = os.time()
  M.release_lock()
  
  -- Stop sidebar sync status updates
  local ui = require('neotex.plugins.tools.himalaya.ui')
  ui.stop_sync_status_updates()
  
  if success then
    notify.himalaya(message, notify.categories.USER_ACTION)
    -- Refresh UI after successful sync
    vim.defer_fn(function()
      if ui and ui.refresh_email_list then
        ui.refresh_email_list()
      end
    end, 1000)
  else
    notify.himalaya(message, notify.categories.ERROR)
  end
end

-- Quick inbox-only sync
function M.sync_inbox(is_user_action)
  -- Provide immediate feedback for user actions
  if is_user_action then
    notify.himalaya('Checking sync status...', notify.categories.STATUS)
  end
  return M.sync_mail(false, is_user_action)
end

-- Full account sync
function M.sync_full(is_user_action)
  -- Provide immediate feedback for user actions
  if is_user_action then
    notify.himalaya('Checking sync status...', notify.categories.STATUS)
  end
  return M.sync_mail(true, is_user_action)
end

-- Auto-sync on startup (only if not already running)
function M.auto_sync_on_startup()
  if not M.is_sync_running_globally() then
    M.sync_inbox(false) -- Not a user action, so no notifications about already running
  end
end

-- Cancel current sync
function M.cancel_sync()
  local was_running = M.state.sync_running or M.is_sync_running_globally()
  
  -- Set cancellation flag to prevent "Sync was terminated" message
  M.state.cancel_requested = true
  
  -- Stop the job if we have a PID
  if M.state.sync_pid then
    vim.fn.jobstop(M.state.sync_pid)
    M.state.sync_pid = nil
  end
  
  -- Kill any mbsync processes
  M.kill_existing_processes()
  
  -- Reset state
  M.state.sync_running = false
  M.release_lock()
  
  -- Reset cancel flag after a short delay to allow on_exit callback to see it
  vim.defer_fn(function()
    M.state.cancel_requested = false
  end, 100)
  
  -- Stop sidebar updates
  local ui = require('neotex.plugins.tools.himalaya.ui')
  ui.stop_sync_status_updates()
  
  -- Only notify if there was actually a sync to cancel
  if was_running then
    notify.himalaya('Sync cancelled', notify.categories.USER_ACTION)
  end
end

-- Cleanup on vim exit (lighter version for exit)
function M.cleanup()
  if M.state.sync_pid then
    vim.fn.jobstop(M.state.sync_pid)
    M.state.sync_pid = nil
  end
  M.state.sync_running = false
  M.release_lock()
end

-- Emergency cleanup (silent version for startup)
function M.emergency_cleanup()
  -- Only clean up this instance's state, don't interfere with other instances
  if M.state.sync_pid then
    vim.fn.jobstop(M.state.sync_pid)
    M.state.sync_pid = nil
  end
  
  -- Reset local state only
  M.state.sync_running = false
  M.state.cancel_requested = false
  
  -- Only clean lock file if it's stale (process doesn't exist)
  if vim.fn.filereadable(LOCK_FILE) == 1 then
    local handle = io.open(LOCK_FILE, 'r')
    if handle then
      local pid = handle:read('*a'):match('%d+')
      handle:close()
      
      if pid then
        -- Check if process still exists
        local check_result = os.execute('kill -0 ' .. pid .. ' 2>/dev/null')
        if check_result ~= 0 then
          -- Stale lock file, safe to remove
          M.release_lock()
        end
        -- If process exists, leave it alone - another instance is using it
      else
        -- Invalid lock file, safe to remove
        M.release_lock()
      end
    end
  end
  
  -- Clean sync state (silently during startup) - this only removes corrupted files
  M.clean_sync_state(true)
end

-- Parse sync progress from mbsync output
function M._parse_sync_progress(line)
  -- Parse lines like "C: 1/1  N: 1/1  E: 0/0  F: +0/1/0  T: +1/2/0"
  local new_count = line:match('N: (%d+)/')
  local total_new = line:match('N: %d+/(%d+)')
  
  if new_count and total_new then
    M.state.sync_progress.messages_synced = tonumber(new_count) or 0
    M.state.sync_progress.messages_total = tonumber(total_new) or 0
  end
  
  -- Parse folder being synced
  local folder = line:match('Channel (%S+)')
  if folder then
    M.state.sync_progress.current_folder = folder
    M.state.sync_progress.current_operation = "Syncing " .. folder
  end
  
  -- Parse connection status
  if line:match('Connecting') then
    M.state.sync_progress.current_operation = "Connecting to server"
  elseif line:match('Selecting') then
    M.state.sync_progress.current_operation = "Selecting mailbox"
  end
end

-- Status check
function M.get_status()
  return {
    sync_running = M.state.sync_running,
    last_sync = M.state.last_sync_time,
    oauth_fresh = os.time() - M.state.last_oauth_refresh < OAUTH_REFRESH_INTERVAL,
    progress = M.state.sync_progress
  }
end

-- Setup commands
function M.setup_commands()
  vim.api.nvim_create_user_command('HimalayaSyncInbox', function()
    M.sync_inbox(true) -- User action
  end, {
    desc = 'Sync inbox only (quick)'
  })
  
  vim.api.nvim_create_user_command('HimalayaSyncFull', function()
    M.sync_full(true) -- User action
  end, {
    desc = 'Full account sync'
  })
  
  vim.api.nvim_create_user_command('HimalayaCleanup', M.emergency_cleanup, {
    desc = 'Emergency cleanup - kill processes and reset state'
  })
  
  vim.api.nvim_create_user_command('HimalayaCancelSync', M.cancel_sync, {
    desc = 'Cancel current sync operation'
  })
  
  vim.api.nvim_create_user_command('HimalayaSyncStatus', function()
    local status = M.get_status()
    local is_global = M.is_sync_running_globally()
    
    notify.himalaya('===== Sync Status =====', notify.categories.USER_ACTION)
    notify.himalaya('Local running: ' .. (status.sync_running and 'Yes' or 'No'), notify.categories.USER_ACTION)
    notify.himalaya('Global running: ' .. (is_global and 'Yes' or 'No'), notify.categories.USER_ACTION)
    notify.himalaya('Last sync: ' .. (status.last_sync > 0 and os.date('%H:%M:%S', status.last_sync) or 'Never'), notify.categories.USER_ACTION)
    notify.himalaya('OAuth fresh: ' .. (status.oauth_fresh and 'Yes' or 'No'), notify.categories.USER_ACTION)
    
    -- Check for processes
    local handle = io.popen('pgrep mbsync 2>/dev/null')
    if handle then
      local output = handle:read('*a')
      handle:close()
      if output and output:match('%d+') then
        notify.himalaya('mbsync processes: ' .. output:gsub('\n', ', '), notify.categories.USER_ACTION)
      else
        notify.himalaya('mbsync processes: None', notify.categories.USER_ACTION)
      end
    end
    
    -- Check for lock file
    if vim.fn.filereadable(LOCK_FILE) == 1 then
      local handle = io.open(LOCK_FILE, 'r')
      if handle then
        local pid = handle:read('*a'):match('%d+')
        handle:close()
        notify.himalaya('Lock file PID: ' .. (pid or 'invalid'), notify.categories.USER_ACTION)
      end
    else
      notify.himalaya('Lock file: None', notify.categories.USER_ACTION)
    end
    
    if status.sync_running and status.progress then
      notify.himalaya('Current operation: ' .. (status.progress.current_operation or 'Unknown'), notify.categories.USER_ACTION)
      if status.progress.current_folder then
        notify.himalaya('Current folder: ' .. status.progress.current_folder, notify.categories.USER_ACTION)
      end
      if status.progress.messages_total > 0 then
        notify.himalaya('Progress: ' .. status.progress.messages_synced .. '/' .. status.progress.messages_total .. ' messages', notify.categories.USER_ACTION)
      end
    end
  end, {
    desc = 'Show detailed sync status'
  })
end

return M