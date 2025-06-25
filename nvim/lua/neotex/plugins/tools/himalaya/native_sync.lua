-- Enhanced Sync Module for Himalaya + mbsync integration
-- Provides true bidirectional sync between Gmail and local maildir

local M = {}

local notify = require('neotex.util.notifications')
local config = require('neotex.plugins.tools.himalaya.config')

-- Global sync lock to prevent multiple processes
M.sync_lock = false
-- Current sync job tracking  
M.current_sync_job = nil
-- Progress timer tracking
M.progress_timer = nil
-- Global flag to stop all progress updates
M.stop_all_progress = false
-- OAuth failure flag
M.oauth_failed = false

-- Check OAuth token freshness and refresh if needed
function M.ensure_oauth_fresh()
  -- Check if refresh command exists
  local refresh_cmd = '/home/benjamin/.nix-profile/bin/refresh-gmail-oauth2'
  if vim.fn.executable(refresh_cmd) == 0 then
    notify.himalaya('OAuth refresh script not found', notify.categories.WARNING)
    return
  end
  
  -- Since tokens are stored via secret-tool (not files), we'll check the last refresh time
  -- using a marker file that we create after each refresh
  local refresh_marker = '/tmp/himalaya-oauth-last-refresh'
  local need_refresh = true
  
  if vim.fn.filereadable(refresh_marker) == 1 then
    local mtime = vim.fn.getftime(refresh_marker)
    local current_time = os.time()
    local age_minutes = (current_time - mtime) / 60
    
    if age_minutes < 50 then
      notify.himalaya(string.format('OAuth token is fresh (%.1f minutes since last refresh)', age_minutes), notify.categories.STATUS)
      need_refresh = false
    else
      notify.himalaya(string.format('OAuth token is %.1f minutes old - refreshing', age_minutes), notify.categories.USER_ACTION)
    end
  else
    notify.himalaya('No refresh marker found - refreshing OAuth', notify.categories.USER_ACTION)
  end
  
  if need_refresh then
    -- Refresh the token synchronously
    notify.himalaya('Refreshing OAuth token...', notify.categories.STATUS)
    local result = os.execute(refresh_cmd)
    
    if result == 0 then
      -- Create marker file to track refresh time
      os.execute('touch ' .. refresh_marker)
      notify.himalaya('OAuth token refreshed successfully', notify.categories.USER_ACTION)
    else
      notify.himalaya('OAuth refresh failed - sync may fail', notify.categories.WARNING)
    end
  end
end

-- Reset stuck locks (call during initialization)
function M.reset_locks()
  M.sync_lock = false
  M.current_sync_job = nil
  M.stop_all_progress = false
  if M.progress_timer then
    M.progress_timer:stop()
    M.progress_timer:close()
    M.progress_timer = nil
  end
  
  -- Clean up any stale lock files (both system and mailbox locks)
  local lock_file = '/tmp/himalaya-sync.lock'
  if vim.fn.filereadable(lock_file) == 1 then
    vim.fn.delete(lock_file)
  end
  
  -- Clean up mbsync mailbox locks and corrupted journal files
  os.execute('find ~/Mail/Gmail -name "*.lock" -delete 2>/dev/null')
  os.execute('find ~/Mail/Gmail -name ".mbsyncstate.lock" -delete 2>/dev/null')
  -- Remove large journal files (>1MB indicates corruption)
  os.execute('find ~/Mail/Gmail -name ".mbsyncstate.journal" -size +1M -delete 2>/dev/null')
end

-- Enhanced sync using mbsync for true bidirectional sync
function M.enhanced_sync(force)
  local timestamp = os.date('%H:%M:%S')
  notify.himalaya(string.format('Enhanced sync called at %s', timestamp), notify.categories.STATUS)
  notify.himalaya('Starting mbsync...', notify.categories.STATUS)
  
  local account = config.state.current_account
  if not account then
    notify.himalaya('No account configured', notify.categories.ERROR)
    return false
  end
  
  -- Use mbsync for true bidirectional sync
  local mbsync_available = vim.fn.executable('mbsync') == 1
  if mbsync_available then
    -- Check and refresh OAuth token if needed before sync
    M.ensure_oauth_fresh()
    return M.mbsync_sync(force)
  else
    notify.himalaya('mbsync not found - install isync package', notify.categories.ERROR)
    return false
  end
end


-- Enhanced sync using mbsync for true bidirectional sync
function M.mbsync_sync(force)
  -- Debug: Check initial state
  notify.himalaya(string.format('Sync state: lock=%s, job=%s', tostring(M.sync_lock), tostring(M.current_sync_job)), notify.categories.STATUS)
  
  -- Check if any sync already running (internal lock)
  if M.sync_lock then
    notify.himalaya('Sync already running - cancel sync to stop', notify.categories.WARNING)
    return false
  end
  
  -- Check if tracked job is running
  if M.current_sync_job then
    notify.himalaya('Sync job tracked - cancel sync to stop', notify.categories.WARNING)
    return false
  end
  
  -- Check for system mbsync processes (enhanced detection)
  local handle = io.popen('pgrep mbsync 2>/dev/null')
  local processes = {}
  if handle then
    for line in handle:lines() do
      if line and line ~= "" then
        table.insert(processes, line)
      end
    end
    handle:close()
    
    if #processes > 0 then
      notify.himalaya(string.format('Found %d mbsync process(es): %s - cancel sync to clean up', 
        #processes, table.concat(processes, ",")), notify.categories.WARNING)
      return false
    end
  end
  
  -- Debug: Show function entry
  notify.himalaya(string.format('Enhanced sync with force=%s', tostring(force)), notify.categories.STATUS)
  
  -- Atomic lock creation using shell command (prevents race conditions)
  local lock_file = '/tmp/himalaya-sync.lock'
  local pid = vim.fn.getpid()
  local lock_cmd = string.format('(set -C; echo %d > %s) 2>/dev/null', pid, lock_file)
  local lock_result = os.execute(lock_cmd)
  
  notify.himalaya(string.format('Lock attempt result: %s', tostring(lock_result)), notify.categories.STATUS)
  
  if lock_result ~= 0 then
    -- Lock file already exists (another process got there first)
    local existing_pid = ""
    local handle = io.open(lock_file, 'r')
    if handle then
      existing_pid = handle:read("*line") or ""
      handle:close()
    end
    notify.himalaya(string.format('System sync lock exists (PID: %s) - another instance syncing', existing_pid), notify.categories.WARNING)
    return false
  end
  
  -- Stop any existing progress timer
  if M.progress_timer then
    M.progress_timer:stop()
    M.progress_timer:close()
    M.progress_timer = nil
  end
  
  -- Set lock before starting and reset flags
  M.sync_lock = true
  M.stop_all_progress = false
  M.oauth_failed = false
  M.oauth_retry_attempted = false
  
  -- Default to syncing just INBOX for faster updates
  -- Use force flag to sync all folders
  -- Add Gmail-specific optimizations based on research
  local mbsync_cmd
  if force then
    -- For full sync, use timeout and verbose mode for debugging
    mbsync_cmd = 'timeout 600 mbsync -V -a'  -- 10 minute timeout
  else
    -- For inbox-only sync, use shorter timeout
    mbsync_cmd = 'timeout 300 mbsync -V gmail-inbox'  -- 5 minute timeout
  end
  
  -- Get initial email count (all Gmail folders, both cur and new directories)
  local initial_count = 0
  local handle = io.popen('find ~/Mail/Gmail -type f \\( -path "*/cur/*" -o -path "*/new/*" \\) 2>/dev/null | wc -l')
  if handle then
    local count_str = handle:read("*a")
    initial_count = tonumber(count_str:match("%d+")) or 0
    handle:close()
  end
  
  -- Show more detailed initial state
  local new_count = 0
  local new_handle = io.popen('find ~/Mail/Gmail -name "new" -exec sh -c \'ls {} 2>/dev/null | wc -l\' \\; | awk \'{sum+=$1} END {print sum}\'')
  if new_handle then
    local new_str = new_handle:read("*a")
    new_count = tonumber(new_str:match("%d+")) or 0
    new_handle:close()
  end
  
  -- Immediate notification that sync has started
  notify.himalaya(string.format('Mail sync started... (total: %d emails, %d unread)', initial_count, new_count), notify.categories.USER_ACTION)
  
  notify.himalaya(string.format('Starting jobstart with cmd: %s', mbsync_cmd), notify.categories.STATUS)
  
  local job_id = vim.fn.jobstart(mbsync_cmd, {
    on_exit = function(_, exit_code)
      vim.schedule(function()
        notify.himalaya(string.format('Job exit code: %d', exit_code), notify.categories.STATUS)
        
        -- Set global stop flag and stop timer
        M.stop_all_progress = true
        if M.progress_timer then
          M.progress_timer:stop()
          M.progress_timer:close()
          M.progress_timer = nil
        end
        
        -- Clear job tracking BEFORE showing completion message
        local completed_job = M.current_sync_job
        M.current_sync_job = nil
        M.sync_lock = false -- Clear global lock
        
        -- Clean up system-wide lock
        local lock_file = '/tmp/himalaya-sync.lock'
        if vim.fn.filereadable(lock_file) == 1 then
          vim.fn.delete(lock_file)
        end
        
        if exit_code == 0 then
          -- Get final counts to show what changed
          local final_handle = io.popen('find ~/Mail/Gmail -type f \\( -path "*/cur/*" -o -path "*/new/*" \\) 2>/dev/null | wc -l')
          local final_count = initial_count
          if final_handle then
            local count_str = final_handle:read("*a")
            final_count = tonumber(count_str:match("%d+")) or initial_count
            final_handle:close()
          end
          
          local emails_changed = final_count - initial_count
          if emails_changed > 0 then
            notify.himalaya(string.format('Mail sync completed! Downloaded %d new emails (total: %d)', emails_changed, final_count), notify.categories.USER_ACTION)
          else
            notify.himalaya(string.format('Mail sync completed! No new emails (total: %d, %d unread)', final_count, new_count), notify.categories.USER_ACTION)
          end
          
          -- Clear Himalaya's cache since files have changed
          local utils = require('neotex.plugins.tools.himalaya.utils')
          utils.clear_email_cache()
          
          -- Refresh sidebar if it's open
          M.refresh_current_view()
        elseif exit_code == 124 then
          notify.himalaya('Mail sync timed out - Gmail server may be under load', notify.categories.WARNING)
          notify.himalaya('Try again later or use <leader>mk to cancel if needed', notify.categories.STATUS)
        elseif exit_code == 143 then
          notify.himalaya('Mail sync was cancelled (SIGTERM)', notify.categories.STATUS)
        else
          notify.himalaya('Mail sync failed (exit code: ' .. exit_code .. ')', notify.categories.ERROR)
          
          -- If OAuth failed, try once more with fresh token
          if M.oauth_failed and not M.oauth_retry_attempted then
            M.oauth_retry_attempted = true
            notify.himalaya('Authentication failed - refreshing OAuth and retrying...', notify.categories.USER_ACTION)
            
            -- Force OAuth refresh
            M.ensure_oauth_fresh()
            
            -- Retry sync after a short delay
            vim.defer_fn(function()
              M.oauth_failed = false
              M.mbsync_sync(force)
            end, 1000)
          end
        end
      end)
    end,
    on_stdout = function(_, data)
      if data and #data > 0 then
        notify.himalaya(string.format('mbsync stdout: %d lines', #data), notify.categories.STATUS)
        for _, line in ipairs(data) do
          if line and line ~= '' then
            notify.himalaya(string.format('mbsync: %s', line), notify.categories.STATUS)
            vim.schedule(function()
              -- Show different types of progress
              if line:match('[FN]:%s*%+?%d+') then
                -- F: far side (server), N: near side (local)
                notify.himalaya(line, notify.categories.USER_ACTION)
              elseif line:match('Synchronizing') then
                notify.himalaya(line, notify.categories.USER_ACTION)
              elseif line:match('%d+ messages') or line:match('%d+ new') then
                notify.himalaya(line, notify.categories.USER_ACTION)
              elseif line:match('Opening') or line:match('Connecting') then
                notify.himalaya(line, notify.categories.USER_ACTION)
              elseif line:match('Flagging') or line:match('Expunging') then
                notify.himalaya(line, notify.categories.USER_ACTION)
              end
            end)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        notify.himalaya(string.format('mbsync stderr: %d lines', #data), notify.categories.STATUS)
        for _, line in ipairs(data) do
          if line and line ~= '' then
            notify.himalaya(string.format('mbsync error: %s', line), notify.categories.WARNING)
            
            -- Check for authentication failure
            if line:match('AUTHENTICATIONFAILED') or line:match('Invalid credentials') then
              M.oauth_failed = true
            end
            
            vim.schedule(function()
              notify.himalaya('mbsync: ' .. line, notify.categories.WARNING)
            end)
          end
        end
      end
    end,
    stdout_buffered = false,
    stderr_buffered = false
  })
  
  -- Store job ID for potential cancellation
  M.current_sync_job = job_id
  
  notify.himalaya(string.format('Job started with ID: %s', tostring(job_id)), notify.categories.STATUS)
  
  -- Check if job started successfully
  if job_id <= 0 then
    notify.himalaya(string.format('Job failed to start! ID: %s', tostring(job_id)), notify.categories.ERROR)
    M.sync_lock = false
    M.current_sync_job = nil
    return false
  end
  
  -- Create single progress timer (replaces recursive scheduling)
  local check_count = 0
  
  -- Function to check progress and update count
  local function check_progress()
    -- Check global stop flag first
    if M.stop_all_progress then
      if M.progress_timer then
        M.progress_timer:stop()
        M.progress_timer:close()
        M.progress_timer = nil
      end
      return
    end
    
    -- Check if job is still running using jobwait (more reliable)
    local job_status = vim.fn.jobwait({job_id}, 0)[1]
    if job_status ~= -1 or M.current_sync_job ~= job_id then
      -- Job has ended, stop timer
      M.stop_all_progress = true
      if M.progress_timer then
        M.progress_timer:stop()
        M.progress_timer:close()
        M.progress_timer = nil
      end
      return
    end
    
    check_count = check_count + 1
    local time_str
    if check_count == 1 then
      time_str = '30s'
    else
      time_str = string.format('%.1f min', check_count * 0.5)
    end
    
    -- Count current emails in all Gmail folders (both cur and new directories)
    local handle = io.popen('find ~/Mail/Gmail -type f \\( -path "*/cur/*" -o -path "*/new/*" \\) 2>/dev/null | wc -l')
    if handle then
      local count_str = handle:read("*a")
      local current_count = tonumber(count_str:match("%d+")) or 0
      handle:close()
      local new_emails = current_count - initial_count
      if new_emails > 0 then
        notify.himalaya(string.format('Mail sync running (%s) - %d emails (+%d new)', time_str, current_count, new_emails), notify.categories.USER_ACTION)
      else
        notify.himalaya(string.format('Mail sync running (%s) - %d emails', time_str, current_count), notify.categories.USER_ACTION)
      end
    else
      notify.himalaya(string.format('Mail sync still running (%s)...', time_str), notify.categories.USER_ACTION)
    end
    
    -- Refresh sidebar to show any new emails
    M.refresh_current_view()
  end
  
  -- TEMPORARY: Disable progress updates to test if this fixes the issue
  -- TODO: Re-enable once we figure out why timer won't stop
  -- Progress updates disabled until timer stopping issue is resolved
  
  return true
end

-- Refresh current Himalaya view if open
function M.refresh_current_view()
  local current_buf = vim.api.nvim_get_current_buf()
  if vim.bo[current_buf].filetype == 'himalaya-list' then
    vim.defer_fn(function()
      -- Refresh the email list by re-running the list command
      local ui = require('neotex.plugins.tools.himalaya.ui')
      ui.show_email_list()
    end, 1000)
  end
end

-- Quick sync for specific folder
function M.quick_sync(folder)
  -- Check locks first
  if M.sync_lock or M.current_sync_job then
    notify.himalaya('Sync already running - cancel sync to stop', notify.categories.WARNING)
    return false
  end
  
  -- Check for existing processes
  local handle = io.popen('pgrep mbsync 2>/dev/null')
  if handle then
    local has_processes = false
    for line in handle:lines() do
      if line and line ~= "" then
        has_processes = true
        break
      end
    end
    handle:close()
    if has_processes then
      notify.himalaya('Found mbsync process(es) - cancel sync to clean up', notify.categories.WARNING)
      return false
    end
  end
  
  notify.himalaya('Quick sync...', notify.categories.STATUS)
  
  local account = config.state.current_account
  if not account or not vim.fn.executable('mbsync') then
    M.refresh_current_view()
    return false
  end
  
  -- Set lock for quick sync too
  M.sync_lock = true
  
  -- Sync specific folder if mbsync supports it
  folder = folder or config.state.current_folder or 'INBOX'
  local mbsync_cmd = string.format('mbsync %s:%s', account, folder)
  
  local job_id = vim.fn.jobstart(mbsync_cmd, {
    on_exit = function(_, exit_code)
      vim.schedule(function()
        M.sync_lock = false -- Clear lock
        if exit_code == 0 then
          -- Clear cache for this specific folder
          local utils = require('neotex.plugins.tools.himalaya.utils')
          utils.clear_email_cache(account, folder)
          notify.himalaya('Quick sync completed', notify.categories.USER_ACTION)
        else
          notify.himalaya('Quick sync failed', notify.categories.ERROR)
        end
        M.refresh_current_view()
      end)
    end,
    stdout_buffered = true,
    stderr_buffered = true
  })
  
  return true
end

-- Background sync with mbsync
function M.background_sync()
  -- Delegate to enhanced_sync for consistent locking and process management
  -- But run silently (no user notifications)
  notify.himalaya('Background sync delegating to enhanced_sync', notify.categories.STATUS)
  
  -- Use enhanced_sync with inbox-only mode for faster background updates
  return M.enhanced_sync(false)
end

-- Sync after delete operation
function M.sync_after_delete()
  -- Run a quick sync to push the deletion to Gmail
  if vim.fn.executable('mbsync') == 1 then
    local account = config.state.current_account
    local folder = config.state.current_folder or 'INBOX'
    
    notify.himalaya('Syncing deletion to Gmail...', notify.categories.STATUS)
    
    -- Use mbsync with push flag to ensure deletion syncs to server
    local cmd = string.format('mbsync -H %s:%s', account, folder)
    
    vim.fn.jobstart(cmd, {
      on_exit = function(_, exit_code)
        vim.schedule(function()
          if exit_code == 0 then
            notify.himalaya('Deletion synced to Gmail', notify.categories.USER_ACTION)
          else
            notify.himalaya('Failed to sync deletion to Gmail', notify.categories.WARNING)
          end
        end)
      end,
      stdout_buffered = true,
      stderr_buffered = true
    })
  end
end

-- Cancel ongoing sync
function M.cancel_sync()
  -- Set global stop flag and stop timer
  M.stop_all_progress = true
  if M.progress_timer then
    M.progress_timer:stop()
    M.progress_timer:close()
    M.progress_timer = nil
  end
  
  -- First stop the tracked job if any
  if M.current_sync_job then
    vim.fn.jobstop(M.current_sync_job)
    M.current_sync_job = nil
  end
  
  -- Clear global lock
  M.sync_lock = false
  
  -- Clean up system-wide lock
  local lock_file = '/tmp/himalaya-sync.lock'
  if vim.fn.filereadable(lock_file) == 1 then
    vim.fn.delete(lock_file)
  end
  
  -- Kill all mbsync processes system-wide
  local killed_count = 0
  local handle = io.popen('pgrep mbsync | wc -l')
  if handle then
    killed_count = tonumber(handle:read("*a"):match("%d+")) or 0
    handle:close()
  end
  
  if killed_count > 0 then
    os.execute('pkill -9 mbsync')
  end
  
  -- Clean up any stale lock files (both mbsync locks and our system lock)
  os.execute('find ~/Mail/Gmail -name "*.lock" -delete 2>/dev/null')
  os.execute('find ~/Mail/Gmail -name ".mbsyncstate.lock" -delete 2>/dev/null')
  -- Remove large journal files (>1MB indicates corruption)
  os.execute('find ~/Mail/Gmail -name ".mbsyncstate.journal" -size +1M -delete 2>/dev/null')
  
  if killed_count > 0 then
    notify.himalaya(string.format('Killed %d mbsync process%s and cleaned up locks', killed_count, killed_count > 1 and 'es' or ''), notify.categories.USER_ACTION)
  else
    notify.himalaya('No mbsync processes running - cleaned up locks', notify.categories.USER_ACTION)
  end
end


-- Cleanup function for module shutdown
function M.cleanup()
  -- Stop progress timer
  if M.progress_timer then
    M.progress_timer:stop()
    M.progress_timer:close()
    M.progress_timer = nil
  end
  
  -- Stop sync job
  if M.current_sync_job then
    vim.fn.jobstop(M.current_sync_job)
    M.current_sync_job = nil
  end
  
  -- Clear locks
  M.sync_lock = false
  
  -- Clean up system-wide lock
  local lock_file = '/tmp/himalaya-sync.lock'
  if vim.fn.filereadable(lock_file) == 1 then
    vim.fn.delete(lock_file)
  end
end

return M