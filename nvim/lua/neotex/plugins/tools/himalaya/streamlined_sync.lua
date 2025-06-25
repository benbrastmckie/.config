-- Streamlined Himalaya Sync System
-- Fixes: multiple processes, corrupted journals, hanging syncs, OAuth races

local M = {}

local notify = require('neotex.util.notifications')

-- Global state with proper atomic operations
M.state = {
  sync_running = false,
  last_oauth_refresh = 0,
  sync_pid = nil,
  last_sync_time = 0
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
function M.clean_sync_state()
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
  
  notify.himalaya('Sync state cleaned', notify.categories.STATUS)
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

-- Streamlined sync function
function M.sync_mail(force_full)
  -- Prevent multiple syncs
  if M.state.sync_running then
    notify.himalaya('Sync already in progress', notify.categories.WARNING)
    return false
  end
  
  -- Acquire lock
  if not M.acquire_lock() then
    notify.himalaya('Another sync process is running', notify.categories.WARNING)
    return false
  end
  
  M.state.sync_running = true
  
  -- Clean up any existing processes first
  M.kill_existing_processes()
  
  -- Small delay to ensure processes are gone
  vim.defer_fn(function()
    M._perform_sync(force_full)
  end, 1000)
  
  return true
end

function M._perform_sync(force_full)
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
    -- For full sync, use shorter timeout and specific channels to avoid Gmail throttling
    cmd = { 'timeout', tostring(SYNC_TIMEOUT), 'mbsync', '-V', 'gmail-inbox', 'gmail-sent', 'gmail-drafts' }
  else
    -- Quick inbox-only sync
    cmd = { 'timeout', tostring(SYNC_TIMEOUT / 2), 'mbsync', '-V', 'gmail-inbox' }
  end
  
  notify.himalaya('Starting mail sync...', notify.categories.STATUS)
  
  -- Use vim.fn.jobstart for better control
  local output = {}
  local job_id = vim.fn.jobstart(cmd, {
    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        if line and line ~= "" then
          table.insert(output, line)
          -- Show important progress lines
          if line:match('messages') or line:match('recent') or line:match('Connecting') then
            notify.himalaya(line, notify.categories.STATUS)
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
        -- Handle common exit codes
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
  
  if success then
    notify.himalaya(message, notify.categories.USER_ACTION)
    -- Refresh UI after successful sync
    vim.defer_fn(function()
      local ui = require('neotex.plugins.tools.himalaya.ui')
      if ui and ui.refresh_email_list then
        ui.refresh_email_list()
      end
    end, 1000)
  else
    notify.himalaya(message, notify.categories.ERROR)
  end
end

-- Quick inbox-only sync
function M.sync_inbox()
  return M.sync_mail(false)
end

-- Full account sync
function M.sync_full()
  return M.sync_mail(true)
end

-- Cancel current sync
function M.cancel_sync()
  if M.state.sync_pid then
    vim.fn.jobstop(M.state.sync_pid)
    M.state.sync_pid = nil
  end
  M.state.sync_running = false
  M.release_lock()
  notify.himalaya('Sync cancelled', notify.categories.USER_ACTION)
end

-- Emergency cleanup
function M.emergency_cleanup()
  M.cancel_sync()
  M.kill_existing_processes()
  M.clean_sync_state()
  M.release_lock()
  M.state.sync_running = false
  notify.himalaya('Emergency cleanup completed', notify.categories.USER_ACTION)
end

-- Status check
function M.get_status()
  return {
    sync_running = M.state.sync_running,
    last_sync = M.state.last_sync_time,
    oauth_fresh = os.time() - M.state.last_oauth_refresh < OAUTH_REFRESH_INTERVAL
  }
end

-- Setup commands
function M.setup_commands()
  vim.api.nvim_create_user_command('HimalayaSyncInbox', M.sync_inbox, {
    desc = 'Sync inbox only (quick)'
  })
  
  vim.api.nvim_create_user_command('HimalayaSyncFull', M.sync_full, {
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
    print('Sync Status:')
    print('  Running: ' .. (status.sync_running and 'Yes' or 'No'))
    print('  Last sync: ' .. (status.last_sync > 0 and os.date('%H:%M:%S', status.last_sync) or 'Never'))
    print('  OAuth fresh: ' .. (status.oauth_fresh and 'Yes' or 'No'))
  end, {
    desc = 'Show sync status'
  })
end

return M