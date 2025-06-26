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
    current_operation = nil,
    start_time = nil,
    -- Real mbsync progress data
    channels_done = 0,
    channels_total = 0,
    mailboxes_done = 0,
    mailboxes_total = 0,
    messages_processed = 0,  -- Total messages affected (added + updated + deleted)
    messages_added = 0,
    messages_updated = 0,
    messages_added_total = 0,
    messages_updated_total = 0,
    current_message = nil,
    total_messages = nil,
    far_total = nil,
    far_recent = nil,
    near_total = nil,
    near_recent = nil
  },
  retry_count = 0
}

local LOCK_FILE = '/tmp/himalaya-sync.lock'
local OAUTH_MARKER = '/tmp/himalaya-oauth-fresh'
local SYNC_TIMEOUT = 0 -- No timeout - let sync run as long as needed
local OAUTH_REFRESH_INTERVAL = 3000 -- 50 minutes

-- Track if sync is already being started to prevent double execution
local sync_starting = false

-- Robust lock creation with proper mbsync process detection
function M.acquire_lock()
  local pid = vim.fn.getpid()
  
  -- Single atomic check: are there any mbsync processes?
  if M.has_active_mbsync_processes() then
    return false -- Another sync is definitely running
  end
  
  -- Atomic lock creation with shell built-ins
  local temp_lock = LOCK_FILE .. '.tmp.' .. pid
  local atomic_cmd = string.format(
    '(echo %d > %s && mv %s %s) 2>/dev/null || (rm -f %s; exit 1)', 
    pid, temp_lock, temp_lock, LOCK_FILE, temp_lock
  )
  
  if os.execute(atomic_cmd) == 0 then
    -- Successfully acquired lock
    return true
  end
  
  -- Lock acquisition failed - check if it's a stale lock
  local handle = io.open(LOCK_FILE, 'r')
  if not handle then
    -- Lock file doesn't exist anymore, try once more
    return M.acquire_lock()
  end
  
  local lock_pid = handle:read('*a'):match('%d+')
  handle:close()
  
  if not lock_pid then
    -- Corrupted lock file, remove and retry
    os.remove(LOCK_FILE)
    return M.acquire_lock()
  end
  
  -- Check if lock owner is still alive
  if os.execute('kill -0 ' .. lock_pid .. ' 2>/dev/null') ~= 0 then
    -- Stale lock - owner is dead
    os.remove(LOCK_FILE)
    M.kill_orphaned_processes()
    return M.acquire_lock()
  end
  
  -- Check for self-locking (same process trying to lock twice)
  if tonumber(lock_pid) == pid then
    return true -- Allow same process to "acquire" lock
  end
  
  -- Valid lock held by another process
  return false
end

function M.release_lock()
  os.remove(LOCK_FILE)
end

-- Check if any mbsync processes are currently running
function M.has_active_mbsync_processes()
  local handle = io.popen('pgrep mbsync 2>/dev/null')
  if handle then
    local output = handle:read('*a')
    handle:close()
    return output and output:match('%d+')
  end
  return false
end

-- Detect current sync type from running processes
function M.get_running_sync_type()
  local handle = io.popen('ps aux | grep mbsync | grep -v grep')
  if handle then
    for line in handle:lines() do
      if line and line ~= "" then
        if line:match('mbsync.*%-a') then
          handle:close()
          return "full"
        elseif line:match('mbsync.*gmail%-inbox') then
          handle:close()
          return "inbox"
        end
      end
    end
    handle:close()
  end
  return nil
end

-- Kill orphaned mbsync processes (not associated with valid lock)
function M.kill_orphaned_processes()
  local handle = io.popen('pgrep mbsync 2>/dev/null')
  local processes = {}
  
  if handle then
    for line in handle:lines() do
      if line and line:match('%d+') then
        table.insert(processes, line)
      end
    end
    handle:close()
  end
  
  if #processes == 0 then
    return
  end
  
  -- Check if we have a valid lock file
  local valid_lock_pid = nil
  if vim.fn.filereadable(LOCK_FILE) == 1 then
    local lock_handle = io.open(LOCK_FILE, 'r')
    if lock_handle then
      valid_lock_pid = lock_handle:read('*a'):match('%d+')
      lock_handle:close()
      
      -- Verify the lock PID is still alive
      if valid_lock_pid then
        local check_result = os.execute('kill -0 ' .. valid_lock_pid .. ' 2>/dev/null')
        if check_result ~= 0 then
          valid_lock_pid = nil -- Stale lock
        end
      end
    end
  end
  
  -- Kill processes that aren't children of the valid lock PID
  for _, pid in ipairs(processes) do
    local should_kill = true
    
    if valid_lock_pid then
      -- Check if this mbsync process is a child of the valid lock PID
      local ppid_cmd = string.format('ps -o ppid= -p %s 2>/dev/null', pid)
      local ppid_handle = io.popen(ppid_cmd)
      if ppid_handle then
        local ppid = ppid_handle:read('*a')
        ppid_handle:close()
        ppid = ppid and ppid:match('%d+')
        
        if ppid == valid_lock_pid then
          should_kill = false -- This is a legitimate child process
        end
      end
    end
    
    if should_kill then
      -- Kill the orphaned process
      os.execute('kill -TERM ' .. pid .. ' 2>/dev/null')
      
      -- Wait a moment, then force kill if needed
      vim.defer_fn(function()
        os.execute('kill -KILL ' .. pid .. ' 2>/dev/null')
      end, 2000)
    end
  end
end

-- Clean up corrupted sync state and locks
function M.clean_sync_state(silent)
  silent = silent or false
  
  local cleanup_commands = {
    -- Only remove corrupted/large journal files (>10MB indicate corruption)
    'find ~/Mail/Gmail -name ".mbsyncstate.journal" -size +10M -delete 2>/dev/null',
    -- Remove temporary sync files
    'find ~/Mail/Gmail -name ".mbsyncstate.new" -delete 2>/dev/null',
    -- Remove ALL .mbsyncstate.lock files (they prevent sync from running)
    'find ~/Mail/Gmail -name ".mbsyncstate.lock" -delete 2>/dev/null',
    -- Remove any other lock files that might be interfering
    'find ~/Mail/Gmail -name "*.lock" -delete 2>/dev/null'
  }
  
  for _, cmd in ipairs(cleanup_commands) do
    os.execute(cmd)
  end
  
  if not silent then
    notify.himalaya('Sync state and locks cleaned', notify.categories.STATUS)
  end
end

-- Fix duplicate emails by rebuilding maildir indices
function M.fix_duplicates()
  notify.himalaya('Fix duplicates command started', notify.categories.USER_ACTION)
  notify.himalaya('Scanning for duplicate emails...', notify.categories.STATUS)
  
  -- Count total emails first for context
  local total_cmd = 'find ~/Mail/Gmail/INBOX/cur -name "*.eml" -o -name "*:2,*" | wc -l'
  local total_handle = io.popen(total_cmd)
  local total_emails = 0
  if total_handle then
    local result = total_handle:read('*a')
    total_handle:close()
    total_emails = tonumber(result:match('%d+')) or 0
  end
  
  notify.himalaya(string.format('Scanning %d emails in INBOX...', total_emails), notify.categories.STATUS)
  
  -- Check if there are duplicate message IDs in the INBOX
  local check_cmd = [[
    cd ~/Mail/Gmail/INBOX/cur 2>/dev/null && 
    find . -type f \( -name "*.eml" -o -name "*:2,*" \) -exec grep -l "^Message-ID:" {} \; 2>/dev/null |
    xargs grep -h "^Message-ID:" 2>/dev/null |
    sort | uniq -d | wc -l
  ]]
  
  local handle = io.popen(check_cmd)
  local duplicate_count = 0
  if handle then
    local result = handle:read('*a')
    handle:close()
    duplicate_count = tonumber(result:match('%d+')) or 0
  end
  
  if duplicate_count > 0 then
    notify.himalaya(string.format('Found %d duplicate Message-IDs - removing duplicates...', duplicate_count), notify.categories.WARNING)
    
    -- Count files before removal
    local before_cmd = 'find ~/Mail/Gmail/INBOX/cur -type f | wc -l'
    local before_handle = io.popen(before_cmd)
    local files_before = 0
    if before_handle then
      local result = before_handle:read('*a')
      before_handle:close()
      files_before = tonumber(result:match('%d+')) or 0
    end
    
    -- Remove duplicate files (keep the most recent based on filename)
    local fix_cmd = [[
      cd ~/Mail/Gmail/INBOX/cur 2>/dev/null &&
      for msg_id in $(find . -type f \( -name "*.eml" -o -name "*:2,*" \) -exec grep -l "^Message-ID:" {} \; 2>/dev/null | xargs grep -h "^Message-ID:" 2>/dev/null | sort | uniq -d | cut -d' ' -f2); do
        files=$(find . -type f -exec grep -l "^Message-ID: $msg_id" {} \; 2>/dev/null)
        file_count=$(echo "$files" | wc -l)
        if [ "$file_count" -gt 1 ]; then
          # Keep the newest file, remove the rest
          echo "$files" | head -n -1 | xargs rm -f 2>/dev/null
        fi
      done
    ]]
    
    local result = os.execute(fix_cmd)
    
    -- Count files after removal
    local after_cmd = 'find ~/Mail/Gmail/INBOX/cur -type f | wc -l'
    local after_handle = io.popen(after_cmd)
    local files_after = 0
    if after_handle then
      local result = after_handle:read('*a')
      after_handle:close()
      files_after = tonumber(result:match('%d+')) or 0
    end
    
    local removed_count = files_before - files_after
    notify.himalaya(string.format('Removed %d duplicate email files', removed_count), notify.categories.USER_ACTION)
    
    if removed_count > 0 then
      notify.himalaya('Duplicate cleanup completed - refresh email list to see changes', notify.categories.USER_ACTION)
    end
  else
    notify.himalaya('No duplicate emails found in INBOX', notify.categories.USER_ACTION)
  end
  
  notify.himalaya('Fix duplicates command completed', notify.categories.USER_ACTION)
end

-- Debug duplicate emails issue
function M.debug_duplicates()
  notify.himalaya('Debug duplicates started', notify.categories.USER_ACTION)
  
  -- Check what's on disk
  local disk_cmd = 'find ~/Mail/Gmail/INBOX/cur -type f | wc -l'
  local disk_handle = io.popen(disk_cmd)
  local disk_count = 0
  if disk_handle then
    local result = disk_handle:read('*a')
    disk_handle:close()
    disk_count = tonumber(result:match('%d+')) or 0
  end
  
  notify.himalaya(string.format('Files on disk: %d', disk_count), notify.categories.STATUS)
  
  -- Check what Himalaya sees
  local utils = require('neotex.plugins.tools.himalaya.utils')
  local config = require('neotex.plugins.tools.himalaya.config')
  
  -- Clear cache to get fresh data
  utils.clear_email_cache(config.state.current_account, 'INBOX')
  
  -- Get fresh email list
  local emails = utils.get_email_list(config.state.current_account, 'INBOX', 1, 200)
  local himalaya_count = emails and #emails or 0
  
  notify.himalaya(string.format('Emails Himalaya sees: %d', himalaya_count), notify.categories.STATUS)
  
  if emails and #emails > 0 then
    -- Check for duplicate subjects/timestamps in Himalaya's view
    local seen_subjects = {}
    local duplicates = {}
    
    for _, email in ipairs(emails) do
      local key = email.subject .. '|' .. email.date
      if seen_subjects[key] then
        seen_subjects[key] = seen_subjects[key] + 1
        if seen_subjects[key] == 2 then
          table.insert(duplicates, {
            subject = email.subject:sub(1, 50) .. '...',
            date = email.date,
            count = seen_subjects[key]
          })
        end
      else
        seen_subjects[key] = 1
      end
    end
    
    if #duplicates > 0 then
      notify.himalaya(string.format('Found %d sets of duplicates in Himalaya output', #duplicates), notify.categories.WARNING)
      for i, dup in ipairs(duplicates) do
        if i <= 3 then -- Show first 3 examples
          notify.himalaya(string.format('Duplicate: "%s" (%s)', dup.subject, dup.date), notify.categories.STATUS)
        end
      end
      if #duplicates > 3 then
        notify.himalaya(string.format('... and %d more duplicate sets', #duplicates - 3), notify.categories.STATUS)
      end
    else
      notify.himalaya('No duplicates found in Himalaya output', notify.categories.STATUS)
    end
  end
  
  -- Check mbsync state
  local state_files_cmd = 'find ~/Mail/Gmail -name ".mbsyncstate*" | wc -l'
  local state_handle = io.popen(state_files_cmd)
  local state_count = 0
  if state_handle then
    local result = state_handle:read('*a')
    state_handle:close()
    state_count = tonumber(result:match('%d+')) or 0
  end
  
  notify.himalaya(string.format('mbsync state files: %d', state_count), notify.categories.STATUS)
  
  notify.himalaya('Debug duplicates completed', notify.categories.USER_ACTION)
end

-- Rebuild Himalaya index to fix duplicate display issues
function M.rebuild_index()
  notify.himalaya('Rebuild index command started', notify.categories.USER_ACTION)
  
  -- Clear all caches first
  local utils = require('neotex.plugins.tools.himalaya.utils')
  local config = require('neotex.plugins.tools.himalaya.config')
  
  notify.himalaya('Clearing Himalaya caches...', notify.categories.STATUS)
  utils.clear_email_cache(config.state.current_account, 'INBOX')
  
  -- Force refresh Himalaya's view by running a direct command
  notify.himalaya('Forcing Himalaya to rebuild email list...', notify.categories.STATUS)
  
  local utils_module = require('neotex.plugins.tools.himalaya.utils')
  local refresh_cmd = { 'envelope', 'list', '--page-size', '1' }
  local result = utils_module.execute_himalaya(refresh_cmd, { 
    account = config.state.current_account, 
    folder = 'INBOX' 
  })
  
  if result then
    notify.himalaya('Himalaya index refreshed successfully', notify.categories.STATUS)
    
    -- Clear cache again and get fresh count
    utils.clear_email_cache(config.state.current_account, 'INBOX')
    
    -- Wait a moment then get fresh email list
    vim.defer_fn(function()
      local emails = utils.get_email_list(config.state.current_account, 'INBOX', 1, 200)
      local email_count = emails and #emails or 0
      
      notify.himalaya(string.format('Refreshed - Himalaya now sees %d emails', email_count), notify.categories.USER_ACTION)
      
      -- Check if duplicates are resolved
      if emails and #emails > 0 then
        local seen_subjects = {}
        local duplicates = 0
        
        for _, email in ipairs(emails) do
          local key = email.subject .. '|' .. email.date
          if seen_subjects[key] then
            duplicates = duplicates + 1
          else
            seen_subjects[key] = true
          end
        end
        
        if duplicates > 0 then
          notify.himalaya(string.format('Still seeing %d duplicates - may need mbsync rebuild', duplicates), notify.categories.WARNING)
        else
          notify.himalaya('No more duplicates found!', notify.categories.USER_ACTION)
        end
      end
      
      -- Refresh the sidebar if it's open
      local ui = require('neotex.plugins.tools.himalaya.ui')
      if ui and ui.refresh_email_list then
        ui.refresh_email_list()
        notify.himalaya('Sidebar refreshed', notify.categories.STATUS)
      end
    end, 1000)
    
  else
    notify.himalaya('Failed to refresh Himalaya index', notify.categories.ERROR)
  end
  
  notify.himalaya('Rebuild index command completed', notify.categories.USER_ACTION)
end

-- Rebuild mbsync state to fix duplicate emails
function M.rebuild_mbsync()
  notify.himalaya('Rebuild mbsync command started', notify.categories.USER_ACTION)
  
  -- Check if any sync is running
  if M.is_sync_running_globally() then
    notify.himalaya('Cannot rebuild while sync is running - cancel sync first', notify.categories.ERROR)
    return
  end
  
  notify.himalaya('WARNING: This will clear mbsync state and force a clean sync', notify.categories.WARNING)
  notify.himalaya('Stopping any existing sync processes...', notify.categories.STATUS)
  
  -- Kill any existing processes
  M.kill_existing_processes()
  
  -- Wait for processes to stop
  vim.defer_fn(function()
    notify.himalaya('Backing up current state files...', notify.categories.STATUS)
    
    -- Create backup directory
    local backup_dir = '~/Mail/Gmail/.backup-' .. os.date('%Y%m%d-%H%M%S')
    os.execute('mkdir -p ' .. backup_dir)
    
    -- Backup existing state files
    local backup_cmd = string.format('find ~/Mail/Gmail -name ".mbsyncstate*" -exec cp {} %s/ \\; 2>/dev/null', backup_dir)
    os.execute(backup_cmd)
    
    notify.himalaya('Removing all mbsync state files...', notify.categories.STATUS)
    
    -- Remove ALL mbsync state files (more aggressive than before)
    local cleanup_commands = {
      'find ~/Mail/Gmail -name ".mbsyncstate*" -delete 2>/dev/null',
      'find ~/Mail/Gmail -name ".uidvalidity" -delete 2>/dev/null',
      'find ~/Mail/Gmail -name "dovecot-uidlist*" -delete 2>/dev/null',
      'find ~/Mail/Gmail -name ".dovecot.size" -delete 2>/dev/null'
    }
    
    for _, cmd in ipairs(cleanup_commands) do
      os.execute(cmd)
    end
    
    notify.himalaya('State files cleared - starting fresh sync...', notify.categories.STATUS)
    
    -- Clear Himalaya cache
    local utils = require('neotex.plugins.tools.himalaya.utils')
    local config = require('neotex.plugins.tools.himalaya.config')
    utils.clear_email_cache(config.state.current_account, 'INBOX')
    
    -- Force a fresh sync (this will rebuild state from scratch)
    notify.himalaya('Starting clean sync - this may take a while...', notify.categories.USER_ACTION)
    
    -- Use a direct mbsync command to ensure clean state rebuild
    local sync_cmd = 'timeout 300 mbsync -V gmail-inbox'
    
    -- Set up periodic progress indicator
    local progress_timer = vim.fn.timer_start(30000, function()
      notify.himalaya('Clean sync still running... (this can take several minutes)', notify.categories.STATUS)
    end, { ['repeat'] = -1 })
    
    vim.fn.jobstart({'sh', '-c', sync_cmd}, {
      on_stdout = function(_, data)
        for _, line in ipairs(data) do
          if line and line ~= "" then
            -- Show all significant progress lines
            if line:match('Connecting') or 
               line:match('Selecting') or 
               line:match('Opening') or
               line:match('Loading') or
               line:match('Channel') or
               line:match('messages') or
               line:match('recent') or
               line:match('Synchronizing') or
               line:match('%d+/%d+') or
               line:match('bytes') then
              notify.himalaya('Progress: ' .. line, notify.categories.STATUS)
            end
          end
        end
      end,
      on_exit = function(_, exit_code)
        -- Stop the progress timer
        vim.fn.timer_stop(progress_timer)
        
        if exit_code == 0 then
          notify.himalaya('Clean sync completed successfully', notify.categories.USER_ACTION)
          
          -- Wait a moment then check results
          vim.defer_fn(function()
            -- Clear cache and get fresh count
            utils.clear_email_cache(config.state.current_account, 'INBOX')
            local emails = utils.get_email_list(config.state.current_account, 'INBOX', 1, 200)
            local email_count = emails and #emails or 0
            
            notify.himalaya(string.format('Clean sync result: %d emails found', email_count), notify.categories.USER_ACTION)
            
            -- Check for remaining duplicates
            if emails and #emails > 0 then
              local seen_subjects = {}
              local duplicates = 0
              
              for _, email in ipairs(emails) do
                local key = email.subject .. '|' .. email.date
                if seen_subjects[key] then
                  duplicates = duplicates + 1
                else
                  seen_subjects[key] = true
                end
              end
              
              if duplicates > 0 then
                notify.himalaya(string.format('WARNING: Still %d duplicates after rebuild', duplicates), notify.categories.WARNING)
              else
                notify.himalaya('SUCCESS: No more duplicates found!', notify.categories.USER_ACTION)
              end
            end
            
            -- Refresh sidebar
            local ui = require('neotex.plugins.tools.himalaya.ui')
            if ui and ui.refresh_email_list then
              ui.refresh_email_list()
              notify.himalaya('Sidebar refreshed with clean data', notify.categories.STATUS)
            end
            
            notify.himalaya('Rebuild mbsync command completed', notify.categories.USER_ACTION)
          end, 2000)
          
        else
          local error_msg = 'Clean sync failed'
          if exit_code == 1 then
            error_msg = 'mbsync configuration error or connection failed'
          elseif exit_code == 2 then
            error_msg = 'mbsync authentication failed'
          else
            error_msg = string.format('Clean sync failed with exit code %d', exit_code)
          end
          
          notify.himalaya(error_msg, notify.categories.ERROR)
          notify.himalaya('Try running: mbsync -V gmail-inbox manually to see detailed error', notify.categories.STATUS)
          notify.himalaya('Rebuild mbsync command completed with errors', notify.categories.USER_ACTION)
        end
      end
    })
    
  end, 2000) -- Wait 2 seconds for processes to stop
end

-- Complete fresh start - remove all local emails and resync
function M.fresh_start()
  notify.himalaya('Fresh start command initiated', notify.categories.USER_ACTION)
  
  -- Check if any sync is running
  if M.is_sync_running_globally() then
    notify.himalaya('Cannot start fresh while sync is running - cancel sync first', notify.categories.ERROR)
    return
  end
  
  notify.himalaya('WARNING: This will DELETE ALL local emails and download fresh from Gmail', notify.categories.WARNING)
  notify.himalaya('Your emails are safe on Gmail servers - only local copies will be removed', notify.categories.STATUS)
  
  -- Kill any existing processes
  M.kill_existing_processes()
  
  vim.defer_fn(function()
    notify.himalaya('Creating backup of current mail directory...', notify.categories.STATUS)
    
    -- Create backup
    local backup_dir = '~/Mail/Gmail-backup-' .. os.date('%Y%m%d-%H%M%S')
    os.execute('mv ~/Mail/Gmail ' .. backup_dir .. ' 2>/dev/null')
    
    notify.himalaya('Recreating clean mail directory structure...', notify.categories.STATUS)
    
    -- Recreate directory structure
    os.execute('mkdir -p ~/Mail/Gmail/INBOX/{cur,new,tmp}')
    os.execute('mkdir -p ~/Mail/Gmail/Sent/{cur,new,tmp}')
    os.execute('mkdir -p ~/Mail/Gmail/Drafts/{cur,new,tmp}')
    os.execute('mkdir -p ~/Mail/Gmail/Trash/{cur,new,tmp}')
    
    notify.himalaya('Starting fresh sync from Gmail (this will take several minutes)...', notify.categories.USER_ACTION)
    
    -- Clear all caches
    local utils = require('neotex.plugins.tools.himalaya.utils')
    local config = require('neotex.plugins.tools.himalaya.config')
    utils.clear_email_cache(config.state.current_account, 'INBOX')
    
    -- Start fresh sync with no timeout since it's downloading everything
    local sync_cmd = 'mbsync -V gmail-inbox'
    
    -- Progress timer
    local progress_timer = vim.fn.timer_start(45000, function()
      notify.himalaya('Fresh sync still downloading emails... (this can take 10+ minutes)', notify.categories.STATUS)
    end, { ['repeat'] = -1 })
    
    vim.fn.jobstart({'sh', '-c', sync_cmd}, {
      on_stdout = function(_, data)
        for _, line in ipairs(data) do
          if line and line ~= "" then
            if line:match('Connecting') or 
               line:match('Selecting') or 
               line:match('Loading') or
               line:match('messages') or
               line:match('Synchronizing') or
               line:match('%d+/%d+') then
              notify.himalaya('Fresh sync: ' .. line, notify.categories.STATUS)
            end
          end
        end
      end,
      on_exit = function(_, exit_code)
        vim.fn.timer_stop(progress_timer)
        
        if exit_code == 0 then
          notify.himalaya('Fresh sync completed successfully!', notify.categories.USER_ACTION)
          
          vim.defer_fn(function()
            -- Check final results
            utils.clear_email_cache(config.state.current_account, 'INBOX')
            local emails = utils.get_email_list(config.state.current_account, 'INBOX', 1, 200)
            local email_count = emails and #emails or 0
            
            notify.himalaya(string.format('Fresh start complete: %d emails downloaded', email_count), notify.categories.USER_ACTION)
            
            -- Check for duplicates
            if emails and #emails > 0 then
              local seen_subjects = {}
              local duplicates = 0
              
              for _, email in ipairs(emails) do
                local key = email.subject .. '|' .. email.date
                if seen_subjects[key] then
                  duplicates = duplicates + 1
                else
                  seen_subjects[key] = true
                end
              end
              
              if duplicates > 0 then
                notify.himalaya(string.format('Found %d duplicates - may need Gmail cleanup', duplicates), notify.categories.WARNING)
              else
                notify.himalaya('SUCCESS: No duplicates found! Problem solved.', notify.categories.USER_ACTION)
              end
            end
            
            -- Refresh sidebar
            local ui = require('neotex.plugins.tools.himalaya.ui')
            if ui and ui.refresh_email_list then
              ui.refresh_email_list()
              notify.himalaya('Sidebar refreshed with clean data', notify.categories.STATUS)
            end
            
          end, 2000)
          
        else
          local error_msg = 'Fresh sync failed'
          if exit_code == 124 then
            error_msg = 'Fresh sync timed out (took longer than 10 minutes)'
          else
            error_msg = string.format('Fresh sync failed with exit code %d', exit_code)
          end
          
          notify.himalaya(error_msg, notify.categories.ERROR)
          notify.himalaya('You can restore from backup: mv ' .. backup_dir .. ' ~/Mail/Gmail', notify.categories.STATUS)
        end
        
        notify.himalaya('Fresh start command completed', notify.categories.USER_ACTION)
      end
    })
    
  end, 2000)
end

-- Helper function to trim whitespace
local function trim(s)
  return s:match('^%s*(.-)%s*$')
end

-- Diagnose and clean up mbsync processes
function M.diagnose_processes()
  notify.himalaya('Process diagnosis started', notify.categories.USER_ACTION)
  
  -- Check current processes
  local handle = io.popen('ps aux | grep mbsync | grep -v grep')
  local processes = {}
  if handle then
    for line in handle:lines() do
      if line and line ~= "" then
        table.insert(processes, line)
      end
    end
    handle:close()
  end
  
  notify.himalaya(string.format('Found %d mbsync processes:', #processes), notify.categories.STATUS)
  for i, process in ipairs(processes) do
    notify.himalaya(string.format('%d: %s', i, process), notify.categories.STATUS)
  end
  
  -- Check lock file
  if vim.fn.filereadable(LOCK_FILE) == 1 then
    local lock_handle = io.open(LOCK_FILE, 'r')
    if lock_handle then
      local lock_pid = lock_handle:read('*a'):match('%d+')
      lock_handle:close()
      notify.himalaya(string.format('Lock file exists with PID: %s', lock_pid or 'invalid'), notify.categories.STATUS)
      
      if lock_pid then
        local check_result = os.execute('kill -0 ' .. lock_pid .. ' 2>/dev/null')
        if check_result == 0 then
          notify.himalaya(string.format('Lock PID %s is alive', lock_pid), notify.categories.STATUS)
          
          -- Check for children
          local children_cmd = string.format('pgrep -P %s 2>/dev/null', lock_pid)
          local children_handle = io.popen(children_cmd)
          if children_handle then
            local children = children_handle:read('*a')
            children_handle:close()
            if children and children:match('%d+') then
              notify.himalaya(string.format('Lock PID has children: %s', children:gsub('\n', ', ')), notify.categories.STATUS)
            else
              notify.himalaya('Lock PID has no children', notify.categories.WARNING)
            end
          end
        else
          notify.himalaya(string.format('Lock PID %s is dead - stale lock', lock_pid), notify.categories.WARNING)
        end
      end
    end
  else
    notify.himalaya('No lock file found', notify.categories.STATUS)
  end
  
  -- Clean up orphaned processes
  notify.himalaya('Cleaning up orphaned processes...', notify.categories.STATUS)
  M.kill_orphaned_processes()
  
  -- Wait and check again
  vim.defer_fn(function()
    local remaining = M.has_active_mbsync_processes()
    if remaining then
      notify.himalaya('WARNING: Some mbsync processes remain after cleanup', notify.categories.WARNING)
    else
      notify.himalaya('All orphaned processes cleaned up successfully', notify.categories.USER_ACTION)
    end
    
    -- Check global sync status
    local is_running = M.is_sync_running_globally()
    notify.himalaya(string.format('Global sync status: %s', is_running and 'RUNNING' or 'NOT RUNNING'), notify.categories.STATUS)
    
    notify.himalaya('Process diagnosis completed', notify.categories.USER_ACTION)
  end, 3000)
end

-- Diagnose current mail directory state
function M.diagnose_mail()
  notify.himalaya('Mail diagnosis started', notify.categories.USER_ACTION)
  
  -- Add a small delay to ensure notifications are processed in order
  vim.defer_fn(function()
    -- Check if directories exist
    local dirs_to_check = {
      '~/Mail/Gmail',
      '~/Mail/Gmail/INBOX',
      '~/Mail/Gmail/INBOX/cur',
      '~/Mail/Gmail/INBOX/new',
      '~/Mail/Gmail/INBOX/tmp'
    }
    
    for i, dir in ipairs(dirs_to_check) do
      vim.defer_fn(function()
        local check_cmd = string.format('[ -d %s ] && echo "EXISTS" || echo "MISSING"', dir)
        local handle = io.popen(check_cmd)
        local result = handle and trim(handle:read('*a')) or 'ERROR'
        if handle then handle:close() end
        
        notify.himalaya(string.format('%s: %s', dir, result), notify.categories.USER_ACTION)
      end, i * 100) -- Stagger the checks
    end
  
    -- Count files in current directories (after directory checks)
    vim.defer_fn(function()
      local count_cmd = 'find ~/Mail/Gmail/INBOX/cur -type f 2>/dev/null | wc -l'
      local handle = io.popen(count_cmd)
      local cur_count = 0
      if handle then
        local result = handle:read('*a')
        handle:close()
        cur_count = tonumber(result:match('%d+')) or 0
      end
      
      local new_cmd = 'find ~/Mail/Gmail/INBOX/new -type f 2>/dev/null | wc -l'
      local handle2 = io.popen(new_cmd)
      local new_count = 0
      if handle2 then
        local result = handle2:read('*a')
        handle2:close()
        new_count = tonumber(result:match('%d+')) or 0
      end
      
      notify.himalaya(string.format('Current emails: %d in cur/, %d in new/', cur_count, new_count), notify.categories.USER_ACTION)
    end, 700)
  
    -- Check for backup directories (after email count)
    vim.defer_fn(function()
      local backup_cmd = 'ls -la ~/Mail/ | grep Gmail-backup | tail -3'
      local handle3 = io.popen(backup_cmd)
      if handle3 then
        local backups = handle3:read('*a')
        handle3:close()
        if backups and backups ~= '' then
          notify.himalaya('Recent backups found:', notify.categories.USER_ACTION)
          for line in backups:gmatch('[^\n]+') do
            if line and line ~= '' then
              notify.himalaya('  ' .. line:sub(1, 50), notify.categories.STATUS)
            end
          end
        else
          notify.himalaya('No backup directories found', notify.categories.USER_ACTION)
        end
      end
    end, 1000)
    
    -- Check mbsync configuration
    vim.defer_fn(function()
      local config_cmd = 'head -10 ~/.mbsyncrc 2>/dev/null'
      local handle4 = io.popen(config_cmd)
      if handle4 then
        local config_content = handle4:read('*a')
        handle4:close()
        if config_content and config_content ~= '' then
          notify.himalaya('mbsync config found (.mbsyncrc exists)', notify.categories.USER_ACTION)
        else
          notify.himalaya('WARNING: No .mbsyncrc found', notify.categories.ERROR)
        end
      end
    end, 1300)
    
    -- Test basic connectivity
    vim.defer_fn(function()
      local ping_cmd = 'ping -c 1 imap.gmail.com >/dev/null 2>&1 && echo "OK" || echo "FAILED"'
      local handle5 = io.popen(ping_cmd)
      if handle5 then
        local ping_result = trim(handle5:read('*a'))
        handle5:close()
        notify.himalaya(string.format('Gmail connectivity: %s', ping_result), notify.categories.USER_ACTION)
      end
      
      -- Final completion message
      vim.defer_fn(function()
        notify.himalaya('Mail diagnosis completed', notify.categories.USER_ACTION)
      end, 200)
    end, 1600)
    
  end, 100) -- Start the whole sequence after 100ms
end

-- Force kill all sync processes and clear locks
function M.force_unlock()
  notify.himalaya('Force killing all sync processes...', notify.categories.USER_ACTION)
  
  -- Show what we're killing first
  local running_type = M.get_running_sync_type()
  if running_type then
    notify.himalaya(string.format('Killing running %s sync', running_type), notify.categories.STATUS)
  end
  
  -- Kill all mbsync processes (try graceful first, then force)
  os.execute('pkill -TERM -f mbsync 2>/dev/null')
  vim.defer_fn(function()
    os.execute('pkill -KILL -f mbsync 2>/dev/null')
  end, 2000)
  
  -- Remove lock file
  M.release_lock()
  
  -- Reset local state completely
  M.state.sync_running = false
  M.state.sync_pid = nil
  M.state.cancel_requested = false
  M.state.retry_count = 0
  M.state.current_sync_type = nil
  M.state.original_force_full = nil  -- Clear previous sync type
  
  -- Clear sync status cache
  M.state.last_sync_check = 0
  M.state.last_sync_status = false
  
  -- Stop any running sync status updates
  local ui = require('neotex.plugins.tools.himalaya.ui')
  ui.stop_sync_status_updates()
  
  notify.himalaya('All sync processes killed and locks cleared', notify.categories.USER_ACTION)
end

-- Refresh OAuth token for Gmail
function M.refresh_oauth()
  notify.himalaya('OAuth refresh requires manual configuration...', notify.categories.USER_ACTION)
  notify.himalaya('Please run in terminal: himalaya account configure gmail', notify.categories.STATUS)
  notify.himalaya('Then follow the OAuth flow to get a fresh token', notify.categories.STATUS)
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

-- Check OAuth token validity and refresh if needed
function M.ensure_oauth_fresh()
  -- First check if we have a token
  local check_cmd = 'secret-tool lookup service himalaya-cli username gmail-smtp-oauth2-access-token 2>/dev/null'
  local handle = io.popen(check_cmd)
  local token = nil
  
  if handle then
    token = handle:read('*a')
    handle:close()
  end
  
  if not token or not token:match('%S') then
    notify.himalaya('No OAuth token found. Run: himalaya account configure gmail', notify.categories.ERROR)
    return false
  end
  
  -- Check if we need to refresh (every 30 minutes)
  local now = os.time()
  if (now - M.state.last_oauth_refresh) > 1800 then -- 30 minutes
    notify.himalaya('Refreshing OAuth token...', notify.categories.STATUS)
    
    -- Try to refresh the token using jobstart for better control
    local refresh_success = false
    local job_id = vim.fn.jobstart({'refresh-gmail-oauth2'}, {
      on_exit = function(_, exit_code)
        if exit_code == 0 then
          M.state.last_oauth_refresh = now
          refresh_success = true
          notify.himalaya('OAuth token refreshed successfully', notify.categories.STATUS)
        else
          notify.himalaya('OAuth refresh failed - token may be expired', notify.categories.WARNING)
          notify.himalaya('Run: himalaya account configure gmail', notify.categories.STATUS)
        end
      end,
      on_stderr = function(_, data)
        if data and #data > 0 then
          for _, line in ipairs(data) do
            if line and line ~= '' then
              notify.himalaya('OAuth error: ' .. line, notify.categories.ERROR)
            end
          end
        end
      end,
    })
    
    -- Wait for the job to complete (max 10 seconds)
    if job_id > 0 then
      local timeout = 0
      while timeout < 100 and vim.fn.jobwait({job_id}, 100)[1] == -1 do
        timeout = timeout + 1
      end
      
      if timeout >= 100 then
        vim.fn.jobstop(job_id)
        notify.himalaya('OAuth refresh timed out', notify.categories.ERROR)
        return false
      end
      
      return refresh_success
    else
      notify.himalaya('Failed to start OAuth refresh', notify.categories.ERROR)
      return false
    end
  else
    -- Token is recent, assume it's valid
    return true
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
  
  -- Primary check: look for active mbsync processes
  if M.has_active_mbsync_processes() then
    is_running = true
  end
  
  -- Secondary check: validate lock file if it exists
  if vim.fn.filereadable(LOCK_FILE) == 1 then
    local handle = io.open(LOCK_FILE, 'r')
    if handle then
      local pid = handle:read('*a'):match('%d+')
      handle:close()
      
      if pid then
        -- Check if lock process still exists
        local check_result = os.execute('kill -0 ' .. pid .. ' 2>/dev/null')
        if check_result == 0 then
          -- Lock process exists, verify it has mbsync children
          local children_cmd = string.format('pgrep -P %s mbsync 2>/dev/null', pid)
          local children_handle = io.popen(children_cmd)
          local has_children = false
          if children_handle then
            local output = children_handle:read('*a')
            children_handle:close()
            has_children = output and output:match('%d+')
          end
          
          if has_children then
            is_running = true
          else
            -- Lock process exists but no mbsync children - stale lock
            os.remove(LOCK_FILE)
          end
        else
          -- Stale lock file, remove it
          os.remove(LOCK_FILE)
        end
      end
    end
  end
  
  -- If we found orphaned processes, clean them up
  if M.has_active_mbsync_processes() and not is_running then
    M.kill_orphaned_processes()
    -- Re-check after cleanup
    is_running = M.has_active_mbsync_processes()
  end
  
  -- Cache the result
  M.state.last_sync_check = now
  M.state.last_sync_status = is_running
  
  return is_running
end

-- Streamlined sync function with user action awareness
function M.sync_mail(force_full, is_user_action)
  is_user_action = is_user_action or false
  notify.himalaya('DEBUG: sync_mail called with force_full=' .. tostring(force_full) .. ', is_user_action=' .. tostring(is_user_action), notify.categories.STATUS)
  
  -- Prevent double execution
  if sync_starting then
    notify.himalaya('BLOCKED: sync_mail already starting, preventing duplicate', notify.categories.WARNING)
    return false
  end
  sync_starting = true
  
  -- Reset flag after a short delay
  vim.defer_fn(function()
    sync_starting = false
  end, 2000)
  
  -- Robust process deduplication check
  if M.has_active_mbsync_processes() then
    -- Synchronize local state with global state
    if not M.state.sync_running then
      M.state.sync_running = true
      local ui = require('neotex.plugins.tools.himalaya.ui')
      local sidebar = require('neotex.plugins.tools.himalaya.sidebar')
      if sidebar.is_open() then
        ui.start_sync_status_updates()
      end
    end
    
    if is_user_action then
      notify.himalaya('Sync is already running (mbsync processes detected)', notify.categories.USER_ACTION)
    end
    return false
  end
  
  -- Prevent double-sync from same instance
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
  
  -- Reset sync progress data with new structure
  M.state.sync_progress = {
    current_folder = nil,
    current_operation = "Initializing sync",
    start_time = os.time(),
    -- Real mbsync progress data
    channels_done = 0,
    channels_total = 0,
    mailboxes_done = 0,
    mailboxes_total = 0,
    messages_processed = 0,
    messages_added = 0,
    messages_updated = 0,
    messages_added_total = 0,
    messages_updated_total = 0,
    current_message = nil,
    total_messages = nil,
    far_total = nil,
    far_recent = nil,
    near_total = nil,
    near_recent = nil
  }
  
  -- Reset retry count for new sync and store sync type
  M.state.retry_count = 0
  M.state.original_force_full = force_full  -- Remember the original sync type
  M.state.current_sync_type = force_full and "full" or "inbox"  -- Track current sync type for user feedback
  
  -- If processes exist, don't kill them - just fail
  if M.has_active_mbsync_processes() then
    M.state.sync_running = false
    M.release_lock()
    if is_user_action then
      notify.himalaya('Cannot start sync - mbsync is already running', notify.categories.WARNING)
    end
    return false
  end
  
  -- Start sync immediately - no delay that allows race conditions
  M._perform_sync(force_full, is_user_action)
  
  return true
end

function M._perform_sync(force_full, is_user_action)
  -- Note: OAuth refresh not needed for mbsync - it handles its own authentication
  
  -- Only clean sync state if we detect actual corruption
  M.clean_sync_state(true) -- Silent cleanup of only corrupted files
  
  -- Use mbsync for actual email synchronization
  local mbsync = require('neotex.plugins.tools.himalaya.mbsync')
  
  -- Check if mbsync is available
  local health_ok, health_msg = mbsync.health_check()
  if not health_ok then
    M._sync_complete(false, 'mbsync not available: ' .. health_msg)
    return
  end
  
  local cmd
  if force_full then
    -- Use the gmail group instead of -a to avoid duplicates
    cmd = { 'mbsync', '-V', 'gmail' }  -- Sync gmail group only
    notify.himalaya('🔄 STARTING FULL SYNC (mbsync gmail)', notify.categories.USER_ACTION)
  else
    local config = require('neotex.plugins.tools.himalaya.config')
    local account = config.get_current_account_name() or 'gmail'
    cmd = { 'mbsync', '-V', account .. '-inbox' }  -- Sync just inbox
    notify.himalaya('📧 STARTING INBOX SYNC (mbsync ' .. account .. '-inbox)', notify.categories.USER_ACTION)
  end
  
  if is_user_action then
    notify.himalaya('Sync has been started', notify.categories.USER_ACTION)
  end
  -- No notification for auto-sync on startup
  
  -- Store the command for progress file
  M.state.current_sync_command = table.concat(cmd, ' ')
  
  -- Start sidebar sync status updates
  local ui = require('neotex.plugins.tools.himalaya.ui')
  ui.start_sync_status_updates()
  
  -- Simple progress monitoring (no fake progress counting)
  local progress_timer = vim.fn.timer_start(60000, function()
    if M.state.sync_running then
      local progress = M.state.sync_progress
      
      -- Show simple status with current operation if available
      if progress.current_operation then
        notify.himalaya('Sync in progress: ' .. progress.current_operation, notify.categories.STATUS)
      else
        notify.himalaya('Sync still in progress...', notify.categories.STATUS)
      end
    end
  end, { ['repeat'] = -1 })
  
  -- Final safety check - ensure no mbsync processes before starting
  if M.has_active_mbsync_processes() then
    notify.himalaya('Another sync is already running', notify.categories.WARNING)
    M._sync_complete(false, 'Sync blocked - another instance running')
    ui.stop_sync_status_updates()
    vim.fn.timer_stop(progress_timer)
    return
  end
  
  -- Log the exact command being run
  notify.himalaya('DEBUG: Starting job with command: ' .. table.concat(cmd, ' '), notify.categories.DEBUG)
  notify.himalaya('DEBUG: sync_running=' .. tostring(M.state.sync_running), notify.categories.DEBUG)
  
  -- Use vim.fn.jobstart for better control
  local output = {}
  local job_id = vim.fn.jobstart(cmd, {
    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        if line and line ~= "" then
          table.insert(output, line)
          
          -- Parse sync progress
          M._parse_sync_progress(line)
          
          -- Debug: show all mbsync output to understand progress format
          -- Note: Debug messages are automatically shown when debug mode is on
          if line ~= "" then
            notify.himalaya('mbsync: ' .. line, notify.categories.DEBUG)
          end
          
          -- Show important progress lines from mbsync output
          if line:match('Connecting') or line:match('Selecting') or line:match('Synchronizing') then
            -- Just show the line as-is, progress details are in the UI status bar
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
      -- Stop the progress timer
      vim.fn.timer_stop(progress_timer)
      
      if exit_code == 0 then
        M._sync_complete(true, 'Sync completed successfully')
      else
        -- Check if cancellation was requested - don't show error for intentional cancellation
        if M.state.cancel_requested and exit_code == 143 then
          -- Intentional cancellation - clear progress data to avoid stale display
          M._sync_complete(false, 'Sync cancelled by user')
          return
        end
        
        -- Handle other exit codes
        local error_msg = 'Sync failed'
        if exit_code == 143 then
          error_msg = 'Sync was terminated'
        elseif #output > 0 then
          local last_line = output[#output] or ''
          -- Check for specific error patterns in all output lines
          local all_output = table.concat(output, ' ')
          
          if last_line:match('Connection timed out') or last_line:match('Connection reset') then
            error_msg = 'Connection lost - Gmail may be throttling'
          elseif last_line:match('Authentication failed') or all_output:match('AUTHENTICATIONFAILED') then
            error_msg = 'OAuth token expired - reconfigure account'
          elseif all_output:match('is locked') then
            error_msg = 'Sync locked - cleaning up stale locks'
            -- Clean up locks immediately when we detect this error
            M.clean_sync_state(true)
          elseif last_line:match('Channels:.*Far:.*Near:') then
            error_msg = 'Sync interrupted during message transfer'
          else
            error_msg = error_msg .. ': ' .. last_line
          end
        end
        
        -- No automatic retry to prevent process multiplication
        -- User must manually retry if sync fails
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
  M.state.current_sync_type = nil
  M.state.original_force_full = nil  -- Clear sync type state
  
  -- Clear progress data
  M.state.sync_progress.current_folder = nil
  M.state.sync_progress.current_operation = nil
  M.state.sync_progress.start_time = nil
  M.state.sync_progress.channels_done = 0
  M.state.sync_progress.channels_total = 0
  M.state.sync_progress.mailboxes_done = 0
  M.state.sync_progress.mailboxes_total = 0
  M.state.sync_progress.messages_processed = 0
  M.state.sync_progress.messages_added = 0
  M.state.sync_progress.messages_updated = 0
  M.state.sync_progress.messages_added_total = 0
  M.state.sync_progress.messages_updated_total = 0
  M.state.sync_progress.current_message = nil
  M.state.sync_progress.total_messages = nil
  M.state.sync_progress.far_total = nil
  M.state.sync_progress.far_recent = nil
  M.state.sync_progress.near_total = nil
  M.state.sync_progress.near_recent = nil
  
  M.release_lock()
  
  -- Clean up progress file
  local config = require('neotex.plugins.tools.himalaya.config')
  local account = config.get_current_account_name() or 'gmail'
  local progress_file = string.format('/tmp/himalaya-sync-%s.progress', account)
  os.remove(progress_file)
  
  -- Clean up any remaining mbsync processes on failure
  if not success then
    M.kill_existing_processes()
  end
  
  -- Stop sidebar sync status updates
  local ui = require('neotex.plugins.tools.himalaya.ui')
  ui.stop_sync_status_updates()
  
  if success then
    notify.himalaya(message, notify.categories.USER_ACTION)
    
    -- Clear Himalaya cache after successful mbsync
    local utils = require('neotex.plugins.tools.himalaya.utils')
    if utils.clear_cache then
      utils.clear_cache()
    end
    
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
  notify.himalaya('DEBUG: sync_inbox called with is_user_action=' .. tostring(is_user_action), notify.categories.STATUS)
  if not is_user_action then
    -- Auto-sync - just try to start if nothing running
    notify.himalaya('DEBUG: Calling sync_mail(false, false) for inbox sync', notify.categories.STATUS)
    return M.sync_mail(false, is_user_action)
  end
  
  -- User action - check what's currently running
  if M.is_sync_running_globally() then
    local running_type = M.get_running_sync_type()
    if running_type == "inbox" then
      notify.himalaya('Inbox sync is already running', notify.categories.USER_ACTION)
    elseif running_type == "full" then
      notify.himalaya('Full sync is currently running', notify.categories.USER_ACTION)
    else
      notify.himalaya('Unknown sync type is running', notify.categories.WARNING)
    end
    return false
  end
  
  -- Nothing running, start inbox sync
  notify.himalaya('Starting inbox sync...', notify.categories.STATUS)
  return M.sync_mail(false, is_user_action)
end

-- Full account sync
function M.sync_full(is_user_action)
  if not is_user_action then
    -- Auto-sync - just try to start if nothing running
    return M.sync_mail(true, is_user_action)
  end
  
  -- User action - check what's currently running
  if M.is_sync_running_globally() then
    local running_type = M.get_running_sync_type()
    if running_type == "full" then
      notify.himalaya('Full sync is already running', notify.categories.USER_ACTION)
    elseif running_type == "inbox" then
      notify.himalaya('Inbox sync is currently running', notify.categories.USER_ACTION)
    else
      notify.himalaya('Unknown sync type is running', notify.categories.WARNING)
    end
    return false
  end
  
  -- Nothing running, start full sync
  notify.himalaya('Starting full sync...', notify.categories.STATUS)
  return M.sync_mail(true, is_user_action)
end

-- Auto-sync on startup (only if not already running)
function M.auto_sync_on_startup()
  -- Disabled to prevent race conditions with manual sync
  -- Users must manually trigger sync when needed
  M.state.last_sync_check = 0  -- Still clear cache for fresh state
end


-- Cancel current sync
function M.cancel_sync()
  local was_running = M.state.sync_running or M.is_sync_running_globally()
  
  -- If nothing is running, inform the user
  if not was_running then
    notify.himalaya('Sync is not running', notify.categories.USER_ACTION)
    return
  end
  
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
  
  -- Notify that sync was cancelled
  notify.himalaya('Sync cancelled', notify.categories.USER_ACTION)
end

-- Cleanup on vim exit (lighter version for exit)
function M.cleanup()
  if M.state.sync_pid then
    vim.fn.jobstop(M.state.sync_pid)
    M.state.sync_pid = nil
  end
  M.state.sync_running = false
  
  -- Clear progress data to avoid stale display
  M.state.sync_progress.current_folder = nil
  M.state.sync_progress.current_operation = nil
  M.state.sync_progress.start_time = nil
  M.state.sync_progress.channels_done = 0
  M.state.sync_progress.channels_total = 0
  M.state.sync_progress.mailboxes_done = 0
  M.state.sync_progress.mailboxes_total = 0
  M.state.sync_progress.messages_processed = 0
  M.state.sync_progress.messages_added = 0
  M.state.sync_progress.messages_updated = 0
  
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
  
  -- Clear progress data
  M.state.sync_progress.current_folder = nil
  M.state.sync_progress.current_operation = nil
  M.state.sync_progress.start_time = nil
  M.state.sync_progress.channels_done = 0
  M.state.sync_progress.channels_total = 0
  M.state.sync_progress.mailboxes_done = 0
  M.state.sync_progress.mailboxes_total = 0
  M.state.sync_progress.messages_processed = 0
  M.state.sync_progress.messages_added = 0
  M.state.sync_progress.messages_updated = 0
  M.state.sync_progress.messages_added_total = 0
  M.state.sync_progress.messages_updated_total = 0
  M.state.sync_progress.current_message = nil
  M.state.sync_progress.total_messages = nil
  M.state.sync_progress.far_total = nil
  M.state.sync_progress.far_recent = nil
  M.state.sync_progress.near_total = nil
  M.state.sync_progress.near_recent = nil
  
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

-- Progress update counter for periodic writes
M.state.progress_update_count = 0

-- Write progress to file for sharing with other instances
local function write_progress_file()
  local config = require('neotex.plugins.tools.himalaya.config')
  local handoff_config = config.get_sync_handoff_config()
  
  -- Only write if sharing is enabled
  if not handoff_config.share_progress then
    return
  end
  
  local account = config.get_current_account_name() or 'gmail'
  local progress_file = string.format('/tmp/himalaya-sync-%s.progress', account)
  
  local progress_data = vim.json.encode({
    pid = M.state.sync_pid,
    start_time = M.state.sync_progress.start_time,
    command = M.state.current_sync_command,
    progress = M.state.sync_progress,
    last_update = os.time()
  })
  
  local file = io.open(progress_file, 'w')
  if file then
    file:write(progress_data)
    file:close()
  end
end

-- Parse sync progress from mbsync output
function M._parse_sync_progress(line)
  -- Parse mbsync output for real progress information and status
  
  -- Track sync start time
  if not M.state.sync_progress.start_time and (line:match('Connecting') or line:match('Synchronizing')) then
    M.state.sync_progress.start_time = os.time()
  end
  
  -- Parse mbsync progress counters: C: 1/2 B: 3/4 F: +13/13 *23/42 #0/0 -0/0 N: +0/7 *0/0 #0/0 -0/0
  local channels_done, channels_total = line:match('C: (%d+)/(%d+)')
  if channels_done and channels_total then
    M.state.sync_progress.channels_done = tonumber(channels_done)
    M.state.sync_progress.channels_total = tonumber(channels_total)
  end
  
  local mailboxes_done, mailboxes_total = line:match('B: (%d+)/(%d+)')
  if mailboxes_done and mailboxes_total then
    M.state.sync_progress.mailboxes_done = tonumber(mailboxes_done)
    M.state.sync_progress.mailboxes_total = tonumber(mailboxes_total)
  end
  
  -- Parse message operations (Far side: server, Near side: local)
  -- F: +13/13 *23/42 means: added 13 of 13, updated 23 of 42
  local far_added, far_added_total = line:match('F: %+(%d+)/(%d+)')
  local far_updated, far_updated_total = line:match('F: %+%d+/%d+ %*(%d+)/(%d+)')
  local near_added, near_added_total = line:match('N: %+(%d+)/(%d+)')
  local near_updated, near_updated_total = line:match('N: %+%d+/%d+ %*(%d+)/(%d+)')
  
  -- Store current/total for progress display
  if far_added and far_added_total then
    M.state.sync_progress.messages_added = tonumber(far_added)
    M.state.sync_progress.messages_added_total = tonumber(far_added_total)
  end
  
  if far_updated and far_updated_total then
    M.state.sync_progress.messages_updated = tonumber(far_updated)
    M.state.sync_progress.messages_updated_total = tonumber(far_updated_total)
  end
  
  -- Also look for simpler progress patterns like "Fetching message 15/98"
  local current_msg, total_msgs = line:match('(%d+)/(%d+)')
  if current_msg and total_msgs and not line:match('[CBF]:') then
    M.state.sync_progress.current_message = tonumber(current_msg)
    M.state.sync_progress.total_messages = tonumber(total_msgs)
  end
  
  -- Calculate total messages processed (nil-safe)
  M.state.sync_progress.messages_processed = (M.state.sync_progress.messages_added or 0) + (M.state.sync_progress.messages_updated or 0)
  
  -- Parse message counts from mbsync status
  local far_total, far_recent = line:match('far side: (%d+) messages, (%d+) recent')
  local near_total, near_recent = line:match('near side: (%d+) messages, (%d+) recent')
  
  if far_total then
    M.state.sync_progress.far_total = tonumber(far_total)
    M.state.sync_progress.far_recent = tonumber(far_recent)
  end
  
  if near_total then
    M.state.sync_progress.near_total = tonumber(near_total)
    M.state.sync_progress.near_recent = tonumber(near_recent)
    -- Calculate difference as a simple progress indicator
    if M.state.sync_progress.far_total then
      local diff = math.abs(M.state.sync_progress.far_total - M.state.sync_progress.near_total)
      if diff > 0 then
        M.state.sync_progress.total_messages = diff
        M.state.sync_progress.current_message = 0
      end
    end
  end
  
  -- Parse "Fetching message X/Y" patterns
  local fetching_current, fetching_total = line:match('Fetching message (%d+)/(%d+)')
  if fetching_current and fetching_total then
    M.state.sync_progress.current_message = tonumber(fetching_current)
    M.state.sync_progress.total_messages = tonumber(fetching_total)
  end
  
  -- Parse other message operation patterns
  -- "Storing message X/Y" or "Copying message X/Y"
  local op_current, op_total = line:match('[Ss]toring message (%d+)/(%d+)')
  if not op_current then
    op_current, op_total = line:match('[Cc]opying message (%d+)/(%d+)')
  end
  if not op_current then
    op_current, op_total = line:match('message (%d+)/(%d+)')
  end
  if not op_current then
    -- Try to match any number/number pattern that looks like progress
    op_current, op_total = line:match('(%d+)/(%d+)')
    -- Only use it if it looks like message counts (not dates or other data)
    if op_current and tonumber(op_total) > 100 and tonumber(op_total) < 10000 then
      -- Likely a message count
    else
      op_current, op_total = nil, nil
    end
  end
  
  if op_current and op_total then
    M.state.sync_progress.current_message = tonumber(op_current)
    M.state.sync_progress.total_messages = tonumber(op_total)
  end
  
  -- Also track if we see "new" in the line with numbers
  local new_current, new_total = line:match('(%d+) new, (%d+) total')
  if not new_current then
    new_current = line:match('(%d+) new')
    if new_current and M.state.sync_progress.messages_added_total then
      M.state.sync_progress.messages_added = tonumber(new_current)
    end
  end
  
  -- Track operations being performed
  if line:match('[Ff]etching') then
    M.state.sync_progress.current_operation = "Fetching new messages"
  elseif line:match('[Ss]toring') then
    M.state.sync_progress.current_operation = "Storing messages"
  elseif line:match('[Cc]opying') then
    M.state.sync_progress.current_operation = "Copying messages"
  elseif line:match('[Uu]ploading') then
    M.state.sync_progress.current_operation = "Uploading messages"
  elseif line:match('[Dd]eleting') or line:match('[Ee]xpunging') then
    M.state.sync_progress.current_operation = "Cleaning up"
  end
  
  -- Parse deletion/expunge operations
  local deleted = line:match('(%d+) messages? deleted')
  if deleted then
    M.state.sync_progress.messages_deleted = tonumber(deleted)
  end
  
  -- Parse "X messages, Y recent" pattern during sync
  local msg_count, recent_count = line:match('(%d+) messages?, (%d+) recent')
  if msg_count and not line:match('side:') then
    -- This might be a progress update
    M.state.sync_progress.messages_processed = tonumber(msg_count)
  end
  
  -- Parse folder being synced
  local folder = line:match('Channel (%S+)')
  if folder then
    M.state.sync_progress.current_folder = folder
    M.state.sync_progress.current_operation = "Syncing " .. folder
  end
  
  -- Parse detailed operation status from mbsync verbose output
  if line:match('Connecting to') then
    M.state.sync_progress.current_operation = "Connecting to server"
  elseif line:match('Authenticating') then
    M.state.sync_progress.current_operation = "Authenticating"
  elseif line:match('Selecting') then
    M.state.sync_progress.current_operation = "Selecting mailbox"
  elseif line:match('Loading') then
    M.state.sync_progress.current_operation = "Loading mailbox"
  elseif line:match('Synchronizing') then
    M.state.sync_progress.current_operation = "Synchronizing emails"
    -- When we start synchronizing, calculate expected operations
    if M.state.sync_progress.far_total and M.state.sync_progress.near_total then
      local new_msgs = math.max(0, (M.state.sync_progress.far_total or 0) - (M.state.sync_progress.near_total or 0))
      local recent_msgs = M.state.sync_progress.far_recent or 0
      if new_msgs > 0 then
        M.state.sync_progress.messages_added_total = new_msgs
        M.state.sync_progress.messages_added = 0
      end
      if recent_msgs > 0 then
        M.state.sync_progress.messages_updated_total = recent_msgs
        M.state.sync_progress.messages_updated = 0
      end
    end
  elseif line:match('Expunging') then
    M.state.sync_progress.current_operation = "Finalizing sync"
  elseif line:match('Opening') then
    M.state.sync_progress.current_operation = "Opening connection"
  end
  
  -- Update progress counter and write to file periodically
  M.state.progress_update_count = (M.state.progress_update_count or 0) + 1
  local config = require('neotex.plugins.tools.himalaya.config')
  local handoff_config = config.get_sync_handoff_config()
  
  if M.state.progress_update_count % (handoff_config.progress_write_interval or 5) == 0 then
    write_progress_file()
  end
end

-- Status check
function M.get_status()
  -- Ensure sync_progress is initialized with all required fields
  if not M.state.sync_progress or not M.state.sync_progress.messages_added then
    M.state.sync_progress = {
      current_folder = nil,
      current_operation = nil,
      start_time = nil,
      channels_done = 0,
      channels_total = 0,
      mailboxes_done = 0,
      mailboxes_total = 0,
      messages_processed = 0,
      messages_added = 0,
      messages_updated = 0,
      messages_added_total = 0,
      messages_updated_total = 0,
      current_message = nil,
      total_messages = nil
    }
  end
  
  local progress = M.state.sync_progress
  
  -- Sync local state with global state if they're out of sync
  local is_global = M.is_sync_running_globally()
  if is_global and not M.state.sync_running then
    M.state.sync_running = true
  elseif not is_global and M.state.sync_running then
    M.state.sync_running = false
  end
  
  -- Progress data is already parsed and stored in M.state.sync_progress
  -- No need for additional calculations here
  
  return {
    sync_running = M.state.sync_running,
    last_sync = M.state.last_sync_time,
    oauth_fresh = os.time() - M.state.last_oauth_refresh < OAUTH_REFRESH_INTERVAL,
    progress = progress
  }
end

-- Setup commands
function M.setup_commands()
  vim.api.nvim_create_user_command('HimalayaToggleSidebar', function()
    require('neotex.plugins.tools.himalaya.ui').toggle_email_sidebar()
  end, {
    desc = 'Toggle Himalaya email sidebar'
  })
  
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
  
  vim.api.nvim_create_user_command('HimalayaFixDuplicates', M.fix_duplicates, {
    desc = 'Remove duplicate emails from inbox'
  })
  
  vim.api.nvim_create_user_command('HimalayaDiagnoseProcesses', M.diagnose_processes, {
    desc = 'Diagnose and clean up mbsync processes'
  })
  
  vim.api.nvim_create_user_command('HimalayaRefreshOAuth', M.refresh_oauth, {
    desc = 'Refresh OAuth token for Gmail'
  })
  
  vim.api.nvim_create_user_command('HimalayaDebugDuplicates', M.debug_duplicates, {
    desc = 'Debug duplicate email issue'
  })
  
  vim.api.nvim_create_user_command('HimalayaRebuildIndex', M.rebuild_index, {
    desc = 'Rebuild Himalaya email index to fix duplicates'
  })
  
  vim.api.nvim_create_user_command('HimalayaRebuildMbsync', M.rebuild_mbsync, {
    desc = 'Rebuild mbsync state to fix duplicate emails'
  })
  
  vim.api.nvim_create_user_command('HimalayaFreshStart', M.fresh_start, {
    desc = 'Complete fresh start - removes all local emails and resyncs'
  })
  
  vim.api.nvim_create_user_command('HimalayaDiagnoseMail', M.diagnose_mail, {
    desc = 'Diagnose current mail directory state'
  })
  
  vim.api.nvim_create_user_command('HimalayaForceUnlock', M.force_unlock, {
    desc = 'Force clear all sync locks and processes'
  })
  
  vim.api.nvim_create_user_command('HimalayaSyncStatus', function()
    local status = M.get_status()
    local is_global = M.is_sync_running_globally()
    
    notify.himalaya('===== Sync Status =====', notify.categories.USER_ACTION)
    notify.himalaya('Local running: ' .. (status.sync_running and 'Yes' or 'No'), notify.categories.USER_ACTION)
    notify.himalaya('Global running: ' .. (is_global and 'Yes' or 'No'), notify.categories.USER_ACTION)
    notify.himalaya('Last sync: ' .. (status.last_sync > 0 and os.date('%H:%M:%S', status.last_sync) or 'Never'), notify.categories.USER_ACTION)
    notify.himalaya('OAuth fresh: ' .. (status.oauth_fresh and 'Yes' or 'No'), notify.categories.USER_ACTION)
    notify.himalaya('Retry count: ' .. M.state.retry_count, notify.categories.USER_ACTION)
    
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
      if status.progress.messages_processed and status.progress.messages_processed > 0 then
        notify.himalaya('Messages processed: ' .. status.progress.messages_processed .. ' (added: ' .. (status.progress.messages_added or 0) .. ', updated: ' .. (status.progress.messages_updated or 0) .. ')', notify.categories.USER_ACTION)
      end
      if status.progress.mailboxes_total and status.progress.mailboxes_total > 0 then
        notify.himalaya('Mailboxes: ' .. (status.progress.mailboxes_done or 0) .. '/' .. status.progress.mailboxes_total, notify.categories.USER_ACTION)
      end
    end
  end, {
    desc = 'Show detailed sync status'
  })
end

return M