-- Simplified mbsync integration module
-- Maximum 200 lines as per REVISE.md specification

local M = {}

-- Dependencies
local lock = require("neotex.plugins.tools.himalaya.sync.lock")
local oauth = require("neotex.plugins.tools.himalaya.sync.oauth")
local logger = require("neotex.plugins.tools.himalaya.core.logger")
local state = require("neotex.plugins.tools.himalaya.core.state")

-- Constants
-- No timeout - let syncs run as long as needed
-- local MBSYNC_TIMEOUT = 300000 -- 5 minutes

-- State
M.current_job = nil
M.current_job_id = nil

-- Check if mbsync is available
function M.check_mbsync()
  local handle = io.popen('which mbsync 2>/dev/null')
  if handle then
    local result = handle:read('*a')
    handle:close()
    return result ~= ''
  end
  return false
end

-- Parse enhanced progress from mbsync output
function M.parse_progress(data)
  if not data then return nil end
  
  -- Always get existing progress to preserve state
  local existing_progress = state.get("sync.progress")
  local progress = existing_progress or {
    status = 'syncing',
    -- Simplified progress tracking
    current_folder = state.get("sync.target_folder"),  -- Use target folder if known
    folders_done = 0,
    folders_total = 0,
    current_operation = 'Initializing',
    -- Message counts for current folder
    messages_processed = 0,
    messages_total = 0,
    -- Overall statistics
    total_new = 0,
    total_updated = 0,
    total_deleted = 0,
    -- Timing
    start_time = state.get("sync.start_time"),
  }
  
  -- Track folders we've seen
  if not progress.seen_folders then
    progress.seen_folders = {}
  end
  
  local logger = require('neotex.plugins.tools.himalaya.core.logger')
  local found_any_progress = false
  
  for _, line in ipairs(data) do
    if line and line ~= '' then
      -- Strip ANSI escape sequences and carriage returns from PTY output
      line = line:gsub('\027%[[^m]*m', '')  -- Remove color codes
      line = line:gsub('\r', '')  -- Remove carriage returns
      line = line:gsub('\027%[[^A-Za-z]*[A-Za-z]', '')  -- Remove other escape sequences
      
      -- Debug: Log any line that contains progress-like patterns
      if line:match('%d+/%d+') or line:match('[BC]:') then
        logger.debug(string.format('Progress line: %s', line))
      end
      
      -- Track sync start time
      if not progress.start_time and (line:match('Connecting') or line:match('Synchronizing')) then
        progress.start_time = os.time()
      end
      
      -- Parse mbsync progress counters: C: 1/2 B: 3/4 F: +13/13 *23/42 #0/0 N: +0/7 *0/0 #0/0
      -- Focus on folder progress as primary indicator
      
      -- Debug: Log any line containing B: or C: to see exact format
      if line:match('[BC]:') then
        logger.debug(string.format('Progress line with B/C: "%s"', line))
      end
      
      local mailboxes_done, mailboxes_total = line:match('B:%s*(%d+)/(%d+)')
      if mailboxes_done and mailboxes_total then
        progress.folders_done = tonumber(mailboxes_done)
        progress.folders_total = tonumber(mailboxes_total)
        found_any_progress = true
        logger.debug(string.format('Parsed folder progress: %d/%d', progress.folders_done, progress.folders_total))
      end
      
      -- Also try to parse channel progress as fallback
      local channels_done, channels_total = line:match('C:%s*(%d+)/(%d+)')
      if channels_done and channels_total and not mailboxes_done then
        -- Use channel progress if mailbox progress not available
        progress.folders_done = tonumber(channels_done)
        progress.folders_total = tonumber(channels_total)
        found_any_progress = true
        logger.debug(string.format('Using channel progress as folder progress: %d/%d', progress.folders_done, progress.folders_total))
      end
      
      -- Parse F: and N: counters from progress line
      -- N: is Near side (local) - shows downloads TO local from server
      -- F: is Far side (server) - shows uploads FROM local to server
      if line:match('[FN]:') then
        -- Parse Near side for downloads (messages coming to local)
        local n_added_current, n_added_total = line:match('N:%s*%+(%d+)/(%d+)')
        if n_added_current and n_added_total and progress.current_folder then
          local current = tonumber(n_added_current)
          local total = tonumber(n_added_total)
          if total > 0 then
            progress.messages_processed = current
            progress.messages_total = total
            progress.current_operation = "Downloading"
            found_any_progress = true
            logger.debug(string.format('Download progress for %s: %d/%d', 
              progress.current_folder, current, total))
          end
        end
        
        -- Parse Far side for uploads (messages going to server)
        local f_added_current, f_added_total = line:match('F:%s*%+(%d+)/(%d+)')
        if f_added_current and f_added_total and progress.current_folder and not n_added_current then
          local current = tonumber(f_added_current)
          local total = tonumber(f_added_total)
          if total > 0 then
            progress.messages_processed = current
            progress.messages_total = total
            progress.current_operation = "Uploading"
            found_any_progress = true
            logger.debug(string.format('Upload progress for %s: %d/%d', 
              progress.current_folder, current, total))
          end
        end
        
        -- Also track flag updates
        local n_updated = line:match('N:.*%*(%d+)/%d+')
        local f_updated = line:match('F:.*%*(%d+)/%d+')
        if (n_updated or f_updated) and not n_added_current and not f_added_current then
          progress.current_operation = "Updating flags"
        end
        
        -- Track totals for statistics
        if n_added_current then progress.total_new = progress.total_new + tonumber(n_added_current) end
        if f_added_current then progress.total_new = progress.total_new + tonumber(f_added_current) end
      end
      
      -- Detect current folder being synced
      -- Make pattern more permissive to catch various folder name formats
      local opening_box = line:match('Opening master box (.+)') or
                         line:match('Opening slave box (.+)') or
                         line:match('Opening far side box (.+)') or
                         line:match('Opening near side box (.+)') or
                         line:match('Mailbox (.+)') or  -- Some versions just say "Mailbox"
                         line:match('Selecting (.+)') or  -- IMAP selecting
                         line:match('Processing mailbox (.+)')  -- Alternative format
      if opening_box then
        -- Clean up the captured string
        opening_box = opening_box:gsub('%s+$', '')  -- Remove trailing whitespace
        opening_box = opening_box:gsub('"', '')  -- Remove quotes
        
        -- Extract folder name from path
        -- Handle paths like "INBOX///" or "/path/to/INBOX..."
        local folder_name = opening_box:match('([^/]+)[/%.]*$')
        if not folder_name or folder_name == '' then
          -- Try without the ending pattern
          folder_name = opening_box:match('([^/]+)$')
          if not folder_name or folder_name == '' then
            folder_name = opening_box
          end
        end
        
        -- Clean up folder name
        folder_name = folder_name:gsub('^/', '')     -- Remove leading slashes
        folder_name = folder_name:gsub('[/%.]+$', '') -- Remove trailing slashes and dots
        folder_name = folder_name:gsub('/+', '/')    -- Collapse multiple slashes
        
        -- Map common folder names to cleaner versions
        if folder_name == 'INBOX' then
          folder_name = 'INBOX'
        elseif folder_name:match('Sent') then
          folder_name = 'Sent'
        elseif folder_name:match('Drafts') then
          folder_name = 'Drafts'
        elseif folder_name:match('Trash') then
          folder_name = 'Trash'
        elseif folder_name:match('Spam') or folder_name:match('Junk') then
          folder_name = 'Spam'
        elseif folder_name:match('All_Mail') or folder_name:match('All Mail') then
          folder_name = 'All Mail'
        end
        
        -- Update current folder if it's different
        if progress.current_folder ~= folder_name then
          progress.current_folder = folder_name
          progress.messages_processed = 0
          progress.messages_total = 0
          -- Mark this folder as seen
          progress.seen_folders[folder_name] = true
          logger.debug(string.format('Detected folder change: %s (from: %s)', folder_name, opening_box))
        end
        found_any_progress = true
      end
      
      -- Note: We no longer try to capture counts from mbsync output
      -- as it's unreliable. Counts are updated after sync completes.
      
      -- Simplify operation tracking to most meaningful states
      if line:match('Connecting') then
        progress.current_operation = 'Connecting'
      elseif line:match('Authenticating') then
        progress.current_operation = 'Authenticating'
      elseif line:match('Opening') then
        progress.current_operation = 'Opening folders'
      elseif line:match('Fetching') or line:match('Downloading') then
        progress.current_operation = 'Downloading'
      elseif line:match('Storing') or line:match('Uploading') then
        progress.current_operation = 'Uploading'
      elseif line:match('Synchronizing') then
        progress.current_operation = 'Synchronizing'
      elseif line:match('Expunging') then
        progress.current_operation = 'Cleaning up'
      end
      
      
      -- Look for completion messages
      if line:match('channel.*complete') or line:match('mailbox.*complete') then
        -- Current folder is done
        if progress.current_folder and not progress.completed_folders then
          progress.completed_folders = {}
        end
        if progress.current_folder then
          progress.completed_folders[progress.current_folder] = true
          logger.debug(string.format('Folder sync complete: %s', progress.current_folder))
        end
      end
      
      -- Fallback: Try to parse any X/Y pattern and use context to determine what it is
      if not found_any_progress then
        local num1, num2 = line:match('(%d+)/(%d+)')
        if num1 and num2 then
          -- Look for context clues
          if line:match('[Mm]ailbox') or line:match('[Bb]ox') then
            progress.folders_done = tonumber(num1)
            progress.folders_total = tonumber(num2)
            found_any_progress = true
            logger.debug(string.format('Fallback folder progress from context: %d/%d', progress.folders_done, progress.folders_total))
          end
        end
      end
    end
  end
  
  -- Only return progress if we found something useful
  if found_any_progress then
    return progress
  else
    return nil
  end
end

-- Core sync function
function M.sync(channel, opts)
  opts = opts or {}
  
  -- Check if already syncing
  if M.current_job then
    logger.warn("Sync already in progress")
    return false, "Sync already in progress"
  end
  
  -- Check if mbsync is available
  if not M.check_mbsync() then
    logger.error("mbsync not found")
    return false, "mbsync not found"
  end
  
  -- Ensure OAuth token exists and is valid
  if not oauth.is_valid() then
    if opts.auto_refresh ~= false then  -- Default to true
      logger.info("OAuth token may be invalid, ensuring token...")
      oauth.ensure_token(nil, function(success)
        if success then
          -- Retry sync after token is ready
          vim.defer_fn(function()
            M.sync(channel, opts)
          end, 500)
        else
          logger.error("Could not obtain valid OAuth token")
          if opts.callback then
            opts.callback(false, "OAuth token invalid")
          end
        end
      end)
      return false, "refreshing OAuth"
    else
      logger.error("OAuth token invalid")
      return false, "OAuth token invalid"
    end
  end
  
  -- Build command with lock
  -- Note: mbsync doesn't provide detailed X/Y progress, only cumulative stats
  -- Using -V for verbose mode to get operation status
  local cmd = lock.wrap_command({'mbsync', '-V', channel})
  
  -- Determine which folder we're syncing based on channel name
  local sync_folder = nil
  if channel:match('inbox') then
    sync_folder = 'INBOX'
  elseif channel:match('drafts') then
    sync_folder = 'Drafts'
  elseif channel:match('sent') then
    sync_folder = 'Sent'
  elseif channel:match('trash') then
    sync_folder = 'Trash'
  elseif channel:match('spam') then
    sync_folder = 'Spam'
  end
  
  -- Update state
  state.set("sync.status", "running")
  state.set("sync.start_time", os.time())
  state.set("sync.error_lines", nil)  -- Clear any previous error lines
  state.set("sync.target_folder", sync_folder)  -- Store which folder we're syncing
  
  -- Start job with pty to get progress output
  M.current_job_id = vim.fn.jobstart(cmd, {
    detach = false,
    stdout_buffered = false,
    pty = true,  -- Use pseudo-terminal to get progress counters
    on_stdout = function(_, data)
      -- Check stdout for authentication errors
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line ~= '' then
            -- Check for authentication errors in stdout too
            if line:match('AUTHENTICATIONFAILED') or 
               line:match('Invalid credentials') or
               line:match('Authentication failed') or
               line:match('AUTHENTICATE.*error') then
              logger.info("Auth error detected in stdout: " .. line)
              -- Trigger the same auth error handling as stderr
              local auth_error = true
              if auth_error and opts.auto_refresh ~= false and not state.get("sync.auth_retry") then
                state.set("sync.auth_retry", true)
                logger.info("Authentication error detected, attempting automatic OAuth refresh...")
                
                -- Stop the current job
                if M.current_job then
                  vim.fn.jobstop(M.current_job)
                  M.current_job = nil
                end
                
                -- Show notification only in debug mode
                local notify = require('neotex.util.notifications')
                if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
                  notify.himalaya('OAuth token expired, refreshing automatically...', notify.categories.STATUS)
                end
                
                -- Attempt OAuth refresh
                oauth.refresh(nil, function(success, error_msg)
                  state.set("sync.auth_retry", false)
                  if success then
                    logger.info("OAuth token refreshed successfully, retrying sync...")
                    if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
                      notify.himalaya('OAuth token refreshed! Retrying sync...', notify.categories.SUCCESS)
                    end
                    vim.defer_fn(function()
                      M.sync(channel, opts)
                    end, 2000)
                  else
                    logger.error("Failed to refresh OAuth token: " .. (error_msg or "unknown error"))
                    -- Always show errors, but less intrusive
                    logger.error("OAuth refresh failed - sync will fail")
                    if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
                      notify.himalaya('Failed to refresh OAuth token. Run :HimalayaOAuthRefresh manually.', notify.categories.ERROR)
                    end
                    state.set("sync.last_error", "Authentication failed - OAuth refresh failed")
                    if opts.callback then
                      opts.callback(false, "Authentication failed - OAuth refresh failed")
                    end
                  end
                end)
                return -- Don't process more lines
              end
            end
          end
        end
      end
      -- Original stdout handling
      -- Log raw output for debugging
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line ~= '' then
            logger.debug('mbsync stdout: ' .. line)
          end
        end
      end
      
      local progress = M.parse_progress(data)
      if progress then
        -- Store progress in state
        state.set("sync.progress", progress)
        
        -- Call progress callback if provided
        if opts.on_progress then
          opts.on_progress(progress)
        end
      end
    end,
    on_stderr = function(_, data)
      -- Log errors and check for auth failures
      if data and #data > 0 then
        local auth_error = false
        local error_lines = {}
        for _, line in ipairs(data) do
          if line ~= '' then
            logger.debug('mbsync stderr: ' .. line)  -- Back to debug
            -- Collect error lines for later display
            table.insert(error_lines, line)
            -- Check for authentication errors
            if line:match('AUTHENTICATIONFAILED') or 
               line:match('Invalid credentials') or
               line:match('Authentication failed') or
               line:match('AUTHENTICATE.*error') or
               line:match('LOGIN.*failed') or
               line:match('AUTH.*denied') or
               line:match('XOAUTH2.*error') then
              auth_error = true
              logger.info("Detected authentication failure: " .. line)
            end
          end
        end
        -- Store error lines in state for later use
        if #error_lines > 0 then
          local existing_errors = state.get("sync.error_lines") or {}
          for _, line in ipairs(error_lines) do
            table.insert(existing_errors, line)
          end
          state.set("sync.error_lines", existing_errors)
          -- Also store the auth error flag
          if auth_error then
            state.set("sync.auth_error_detected", true)
          end
        end
        
        -- If auth error and auto_refresh enabled, try to refresh token
        logger.debug("Auth error check: " .. tostring(auth_error) .. ", auto_refresh: " .. tostring(opts.auto_refresh ~= false) .. ", auth_retry: " .. tostring(state.get("sync.auth_retry")))
        if auth_error and opts.auto_refresh ~= false and not state.get("sync.auth_retry") then
          state.set("sync.auth_retry", true)
          logger.info("Authentication error detected, attempting automatic OAuth refresh...")
          
          -- Stop the current job to prevent further errors
          if M.current_job then
            vim.fn.jobstop(M.current_job)
            M.current_job = nil
          end
          
          -- Clear the error lines since we're handling it
          state.set("sync.error_lines", {})
          
          -- Show notification only in debug mode
          local notify = require('neotex.util.notifications')
          local config = require('neotex.plugins.tools.himalaya.core.config')
          if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
            notify.himalaya('OAuth token expired, refreshing automatically...', notify.categories.STATUS)
          end
          
          -- Attempt OAuth refresh
          oauth.refresh(nil, function(success, error_msg)
            state.set("sync.auth_retry", false)
            if success then
              logger.info("OAuth token refreshed successfully, retrying sync...")
              if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
                notify.himalaya('OAuth token refreshed! Retrying sync...', notify.categories.SUCCESS)
              end
              
              -- Wait a moment for token to propagate
              vim.defer_fn(function()
                -- Retry the sync with the same options
                M.sync(channel, opts)
              end, 2000)
            else
              logger.error("Failed to refresh OAuth token: " .. (error_msg or "unknown error"))
              if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
                notify.himalaya('Failed to refresh OAuth token. Run :HimalayaOAuthRefresh manually.', notify.categories.ERROR)
              end
              
              state.set("sync.last_error", "Authentication failed - OAuth refresh failed: " .. (error_msg or "unknown error"))
              if opts.callback then
                opts.callback(false, "Authentication failed - OAuth refresh failed")
              end
            end
          end)
        end
      end
    end,
    on_exit = function(_, code)
      M.current_job = nil
      state.set("sync.status", "idle")
      state.set("sync.last_sync", os.time())
      state.set("sync.auth_retry", false)
      state.set("sync.running", false)  -- Clear immediate sync status
      
      -- Get captured error lines
      local error_lines = state.get("sync.error_lines")
      
      if code == 0 then
        logger.info("Sync completed successfully")
        state.set("sync.last_error", nil)
        state.set("sync.error_lines", nil)  -- Clear error lines on success
      elseif code == 143 or code == 129 or code == 130 then
        -- 143 = SIGTERM, 129 = SIGHUP, 130 = SIGINT - all mean sync was cancelled
        logger.info("Sync cancelled by user")
        state.set("sync.last_error", nil)
        state.set("sync.error_lines", nil)
      else
        logger.error("Sync failed with code: " .. code)
        
        -- Check if we detected an auth error but didn't handle it yet
        if state.get("sync.auth_error_detected") and opts.auto_refresh ~= false and not state.get("sync.auth_retry") then
          state.set("sync.auth_error_detected", false)
          state.set("sync.auth_retry", true)
          logger.info("Authentication error detected in exit handler, attempting OAuth refresh...")
          
          local notify = require('neotex.util.notifications')
          local config = require('neotex.plugins.tools.himalaya.core.config')
          if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
            notify.himalaya('OAuth token expired, refreshing automatically...', notify.categories.STATUS)
          end
          
          oauth.refresh(nil, function(success, error_msg)
            state.set("sync.auth_retry", false)
            if success then
              logger.info("OAuth token refreshed successfully, retrying sync...")
              if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
                notify.himalaya('OAuth token refreshed! Retrying sync...', notify.categories.SUCCESS)
              end
              vim.defer_fn(function()
                M.sync(channel, opts)
              end, 2000)
            else
              logger.error("Failed to refresh OAuth token: " .. (error_msg or "unknown error"))
              if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
                notify.himalaya('Failed to refresh OAuth token. Run :HimalayaOAuthRefresh manually.', notify.categories.ERROR)
              end
              if opts.callback then
                opts.callback(false, "Authentication failed - OAuth refresh failed")
              end
            end
          end)
          return -- Don't call the normal callback
        end
        
        -- Build a more informative error message
        local error_msg = "Sync failed with code: " .. code
        if error_lines and #error_lines > 0 then
          -- Find the most relevant error line
          local relevant_error = nil
          for _, line in ipairs(error_lines) do
            -- Look for specific error patterns
            if line:match('Error:') or line:match('ERROR:') or 
               line:match('failed') or line:match('Failed') or
               line:match('Cannot') or line:match('cannot') or
               line:match('Unable') or line:match('unable') or
               line:match('Connection') or line:match('Authentication') or
               line:match('IMAP') or line:match('SSL') then
              relevant_error = line
              break
            end
          end
          -- If no specific pattern found, use the last error line
          if not relevant_error and #error_lines > 0 then
            relevant_error = error_lines[#error_lines]
          end
          if relevant_error then
            error_msg = error_msg .. ": " .. relevant_error
          end
        end
        state.set("sync.last_error", error_msg)
        state.set("sync.error_lines", nil)  -- Clear after using
      end
      
      if opts.callback then
        -- Pass error message string for consistency
        local error_msg = nil
        if code ~= 0 and code ~= 143 and code ~= 129 and code ~= 130 then
          error_msg = state.get("sync.last_error", "Sync failed with code: " .. code)
        end
        opts.callback(code == 0 or code == 143 or code == 129 or code == 130, error_msg)
      end
    end
  })
  
  -- Store job ID for cancellation
  M.current_job = M.current_job_id
  
  if M.current_job_id <= 0 then
    M.current_job = nil
    M.current_job_id = nil
    state.set("sync.status", "idle")
    return false, "Failed to start sync job"
  end
  
  -- No timeout - let syncs run as long as needed
  -- Removed timeout to prevent "Sync timed out" errors
  
  logger.info("Started sync job: " .. M.current_job_id)
  return M.current_job
end

-- Stop sync
function M.stop()
  if M.current_job then
    vim.fn.jobstop(M.current_job)
    M.current_job = nil
    state.set("sync.status", "idle")
    logger.info("Sync job stopped")
    return true
  end
  return false
end

-- Check if sync is running
function M.is_running()
  return M.current_job ~= nil
end

-- Check for new emails without syncing
function M.check_new_emails(opts)
  opts = opts or {}
  local config = require("neotex.plugins.tools.himalaya.core.config")
  local utils = require("neotex.plugins.tools.himalaya.utils")
  local account = opts.account or config.get_current_account_name()
  local folder = opts.folder or 'INBOX'
  
  -- Since Himalaya reads from local Maildir when it exists, we need a different approach
  -- We'll use mbsync in dry-run mode to check if there are new messages
  
  -- Get current local count first
  local local_emails, total_count = utils.get_email_list(account, folder, 1, 200)
  local local_count = total_count or (local_emails and #local_emails) or 0
  
  -- If no callback provided, run synchronously
  if not opts.callback then
    -- Use mbsync in dry-run mode to check for new messages
    local account_config = config.get_current_account()
    local channel = account_config.mbsync and account_config.mbsync.inbox_channel or 'gmail-inbox'
    
    -- Run mbsync in dry-run mode
    local cmd = {'mbsync', '--dry-run', '--verbose', channel}
    local result = vim.fn.system(cmd)
    local exit_code = vim.v.shell_error
    
    if exit_code ~= 0 then
      logger.error("Failed to check remote emails: exit code " .. exit_code)
      return nil, "Failed to check remote emails"
    end
    
    -- Parse mbsync dry-run output to check for new messages
    local new_messages = 0
    local near_count = 0
    local far_count = 0
    
    for line in result:gmatch("[^\r\n]+") do
      -- Check message counts first
      local near_msgs = line:match("near side:%s*(%d+)%s*messages")
      local far_msgs = line:match("far side:%s*(%d+)%s*messages")
      
      if near_msgs then
        near_count = tonumber(near_msgs) or 0
      end
      if far_msgs then
        far_count = tonumber(far_msgs) or 0
      end
      
      -- Also check the summary line for new messages
      local far_new = line:match("Far:%s+%+(%d+)")
      if far_new then
        new_messages = tonumber(far_new) or 0
      end
    end
    
    -- If message counts differ, we have new/deleted messages
    if far_count > near_count then
      new_messages = far_count - near_count
    end
    
    -- Store the remote count for INBOX
    if far_count > 0 then
      state.set_folder_count(account, folder, far_count)
    end
    
    return {
      has_new = new_messages > 0,
      local_count = local_count,
      remote_count = local_count + new_messages,
      new_count = new_messages
    }
  end
  
  -- Asynchronous version
  local account_config = config.get_current_account()
  local channel = account_config.mbsync and account_config.mbsync.inbox_channel or 'gmail-inbox'
  
  local new_messages = 0
  local near_count = 0
  local far_count = 0
  local job_id = vim.fn.jobstart({
    'mbsync', '--dry-run', '--verbose', channel
  }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 then
        -- Parse mbsync dry-run output to check for new messages
        for _, line in ipairs(data) do
          if line and line ~= '' then
            -- Check message counts
            local near_msgs = line:match("near side:%s*(%d+)%s*messages")
            local far_msgs = line:match("far side:%s*(%d+)%s*messages")
            
            if near_msgs then
              near_count = tonumber(near_msgs) or 0
            end
            if far_msgs then
              far_count = tonumber(far_msgs) or 0
            end
            
            -- Also check the summary line
            local far_new = line:match("Far:%s+%+(%d+)")
            if far_new then
              new_messages = tonumber(far_new) or 0
            end
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        local error_msg = table.concat(data, '\n')
        if error_msg and error_msg ~= '' then
          logger.error("mbsync dry-run stderr: " .. error_msg)
          
          -- Check for auth errors
          if error_msg:match('AUTHENTICATIONFAILED') or 
             error_msg:match('Invalid credentials') or
             error_msg:match('Authentication failed') then
            -- Try to refresh OAuth if configured
            if opts.auto_refresh ~= false then
              logger.info("Authentication error during check, attempting OAuth refresh...")
              oauth.ensure_token(nil, function(success)
                if success then
                  -- Retry the check
                  vim.defer_fn(function()
                    M.check_new_emails(opts)
                  end, 1000)
                else
                  opts.callback(nil, "Authentication failed - OAuth refresh failed")
                end
              end)
              return
            end
          end
          
          -- Don't treat stderr as fatal for dry-run, mbsync often outputs info there
        end
      end
    end,
    on_exit = function(_, code)
      if code ~= 0 then
        logger.error("mbsync dry-run failed with exit code: " .. code)
        opts.callback(nil, "Failed to check remote emails")
      else
        -- Success - return the results
        local local_emails, total_count = utils.get_email_list(account, folder, 1, 200)
        local local_count = total_count or (local_emails and #local_emails) or 0
        
        -- If message counts differ, we have new/deleted messages
        if far_count > near_count then
          new_messages = far_count - near_count
        end
        
        logger.debug(string.format("Check complete - near: %d, far: %d, new: %d", 
                                  near_count, far_count, new_messages))
        
        -- Store the remote count for the folder if we have it
        if far_count > 0 then
          state.set_folder_count(account, folder, far_count)
        end
        
        opts.callback({
          has_new = new_messages > 0,
          local_count = local_count,
          remote_count = local_count + new_messages,
          new_count = new_messages
        })
      end
    end
  })
  
  if job_id <= 0 then
    logger.error("Failed to start mbsync dry-run job")
    opts.callback(nil, "Failed to start check job")
  else
    logger.debug("Started email check job: " .. job_id)
  end
end

-- Get sync status
function M.get_status()
  local progress_data = state.get("sync.progress")
  local last_sync = state.get("sync.last_sync")
  local last_error = state.get("sync.last_error")
  local status_val = state.get("sync.status", "idle")
  
  -- Check for external sync processes (from other nvim instances)
  local external_sync_running = false
  if not M.current_job then  -- Only check for external if we're not running our own sync
    -- More precise check for mbsync processes
    local handle = io.popen('pgrep -x mbsync 2>/dev/null')  -- -x for exact match
    if handle then
      local pids = handle:read('*a')
      handle:close()
      -- Check if we got valid PIDs (non-empty after trimming)
      if pids then
        pids = pids:gsub('^%s+', ''):gsub('%s+$', ''):gsub('\n', ' ')
        if pids ~= '' then
          -- Double-check these are real mbsync processes
          local verify_handle = io.popen('ps -p ' .. pids:gsub(' ', ',') .. ' -o comm= 2>/dev/null | grep -c "^mbsync$"')
          if verify_handle then
            local count = verify_handle:read('*a')
            verify_handle:close()
            count = tonumber(count) or 0
            external_sync_running = count > 0
          end
        end
      end
    end
  end
  
  return {
    running = M.current_job ~= nil,
    sync_running = M.current_job ~= nil or external_sync_running,  -- For UI compatibility
    external_sync_running = external_sync_running,
    last_sync = last_sync,
    last_error = last_error,
    status = status_val,
    progress = progress_data,
  }
end

-- Helper function to get highest email ID from a list
function M.get_highest_email_id(emails)
  if not emails or #emails == 0 then
    return 0
  end
  
  local highest_id = 0
  for _, email in ipairs(emails) do
    local id_num = tonumber(email.id) or 0
    if id_num > highest_id then
      highest_id = id_num
    end
  end
  
  return highest_id
end

-- Cancel current sync operation
function M.cancel_current_sync(reason)
  reason = reason or 'cancelled'
  
  if not M.current_job_id or M.current_job_id <= 0 then
    logger.debug('No sync job running to cancel')
    return false
  end
  
  logger.info('Cancelling sync job: ' .. M.current_job_id .. ' (' .. reason .. ')')
  
  -- Stop the job gracefully first with SIGTERM
  vim.fn.jobstop(M.current_job_id)
  
  -- Clean up state
  M.current_job = nil
  M.current_job_id = nil
  
  -- Update state
  state.set("sync.status", "cancelled")
  state.set("sync.end_time", os.time())
  
  logger.debug('Sync job cancelled successfully')
  return true
end

-- Check if sync is currently running
function M.is_sync_running()
  return M.current_job_id and M.current_job_id > 0
end

return M