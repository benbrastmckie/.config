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
    current_folder = nil,
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
  
  -- Track folders we've seen to avoid double counting
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
      
      -- Look for message counts in verbose output
      -- mbsync shows summary lines like "master: 358 messages, 11 recent"
      local master_total, master_recent = line:match('master:%s*(%d+)%s*messages?,%s*(%d+)%s*recent')
      local slave_total, slave_recent = line:match('slave:%s*(%d+)%s*messages?,%s*(%d+)%s*recent')
      
      if master_total and slave_total and progress.current_folder then
        local server_count = tonumber(master_total)
        local local_count = tonumber(slave_total)
        local to_download = math.max(0, server_count - local_count)
        
        -- If we're downloading messages, set up the total
        if to_download > 0 and progress.current_operation == "Synchronizing" then
          progress.messages_total = to_download
          -- messages_processed will be updated by the N: counter
          logger.debug(string.format('Messages to download for %s: %d', 
            progress.current_folder, to_download))
        end
      end
      
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
  
  -- Update state
  state.set("sync.status", "running")
  state.set("sync.start_time", os.time())
  state.set("sync.error_lines", nil)  -- Clear any previous error lines
  
  -- Start job with pty to get progress output
  M.current_job = vim.fn.jobstart(cmd, {
    detach = false,
    stdout_buffered = false,
    pty = true,  -- Use pseudo-terminal to get progress counters
    on_stdout = function(_, data)
      -- Also check stdout for authentication errors
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
                      if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
                notify.himalaya('OAuth token refreshed! Retrying sync...', notify.categories.SUCCESS)
              end
                    end
                    vim.defer_fn(function()
                      M.sync(channel, opts)
                    end, 2000)
                  else
                    logger.error("Failed to refresh OAuth token: " .. (error_msg or "unknown error"))
                    -- Always show errors, but less intrusive
                    logger.error("OAuth refresh failed - sync will fail")
                    if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
                      if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
                notify.himalaya('Failed to refresh OAuth token. Run :HimalayaOAuthRefresh manually.', notify.categories.ERROR)
              end
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
  
  if M.current_job <= 0 then
    M.current_job = nil
    state.set("sync.status", "idle")
    return false, "Failed to start sync job"
  end
  
  -- No timeout - let syncs run as long as needed
  -- Removed timeout to prevent "Sync timed out" errors
  
  logger.info("Started sync job: " .. M.current_job)
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

-- Fast check using Himalaya's direct IMAP access
function M.himalaya_fast_check(opts)
  opts = opts or {}
  
  -- Import notify early for debug output
  local notify = require('neotex.util.notifications')
  
  local config = require('neotex.plugins.tools.himalaya.core.config')
  local utils = require('neotex.plugins.tools.himalaya.utils')
  
  local account_name = opts.account or config.get_current_account_name()
  local folder = opts.folder or 'INBOX'
  local callback = opts.callback
  
  if not callback then
    return nil, "Callback required for async operation"
  end
  
  -- Import notify for debug messages
  local notify = require('neotex.util.notifications')
  
  -- Use fastcheck account variant for direct server access
  local check_account = account_name .. '-fastcheck'
  
  -- Check if we can refresh OAuth for Himalaya IMAP
  -- Note: Himalaya uses different OAuth storage than mbsync
  -- If the account hasn't been authenticated, we need to inform the user
  
  -- Skip the pre-flight check - it's causing the hang
  -- Let the actual envelope list command fail if there's an auth issue
  -- This way we can show the checking status immediately
  
  -- Build Himalaya command
  local cmd = {
    config.config.binaries.himalaya or 'himalaya',
    'envelope', 'list',
    '-a', check_account,
    '-f', folder,
    '-s', '50',  -- Get first 50 emails to compare
    '-o', 'json'
  }
  
  if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
    notify.himalaya('Himalaya fast check - Using account: ' .. check_account .. ', Folder: ' .. folder, notify.categories.BACKGROUND)
    notify.himalaya('Himalaya fast check command: ' .. table.concat(cmd, ' '), notify.categories.BACKGROUND)
  end
  
  local output = {}
  local stderr_output = {}
  
  
  if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
    notify.himalaya('Starting himalaya envelope list command...', notify.categories.STATUS)
  end
  
  local job_id = vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(output, line)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(stderr_output, line)
          end
        end
        if #stderr_output > 0 then
          local error_str = table.concat(stderr_output, '\n')
          -- Always show stderr in debug mode
          if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
            -- Clean up ANSI escape codes for readability
            local clean_str = error_str:gsub('\27%[[0-9;]*m', '')
            notify.himalaya('Himalaya stderr: ' .. clean_str:sub(1, 500), notify.categories.BACKGROUND)
          end
          
          -- Check if the error is about missing account or auth issues
          if error_str:match('account.*not found') and error_str:match('gmail%-imap') then
            notify.himalaya('IMAP account not configured. Add gmail-imap account to Himalaya config for fast checks.', notify.categories.WARNING)
          elseif error_str:match('AUTHENTICATIONFAILED') or error_str:match('auth') or error_str:match('OAuth.*failed') then
            -- Store the auth error for handling in on_exit
            stderr_output.has_auth_error = true
          end
        end
      end
    end,
    on_exit = function(_, code)
      
      -- Check if we had an authentication error
      if code ~= 0 and stderr_output.has_auth_error and opts.auto_refresh ~= false then
        -- Don't retry infinitely
        opts.retry_count = (opts.retry_count or 0) + 1
        if opts.retry_count > 2 then
          callback(nil, "OAuth authentication failed after retries")
          return
        end
        
        if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
          notify.himalaya('OAuth authentication failed, attempting refresh...', notify.categories.STATUS)
        end
        
        -- Debug: log which account we're refreshing
        if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
          notify.himalaya('Refreshing OAuth for account: ' .. check_account, notify.categories.BACKGROUND)
          
          -- Check current token status before refresh
          local oauth = require('neotex.plugins.tools.himalaya.sync.oauth')
          local status = oauth.get_status(check_account)
          notify.himalaya('Token exists before refresh: ' .. tostring(status.has_token), notify.categories.BACKGROUND)
        end
        
        -- Try to refresh OAuth token for the IMAP account
        local oauth = require('neotex.plugins.tools.himalaya.sync.oauth')
        oauth.refresh(check_account, function(success)
          if success then
            if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
              notify.himalaya('OAuth token refreshed, retrying check...', notify.categories.STATUS)
            end
            -- Retry the fast check after a short delay
            vim.defer_fn(function()
              opts.retry_count = opts.retry_count or 0
              M.himalaya_fast_check(opts)
            end, 2000)
          else
            -- Special handling for gmail-imap configuration issue
            if check_account == 'gmail-imap' then
              callback(nil, "Gmail IMAP requires manual OAuth setup due to token naming issue")
            else
              callback(nil, "OAuth authentication failed - refresh failed")
            end
          end
        end)
        return
      end
      
      if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
        notify.himalaya('Himalaya fast check exited with code: ' .. code, notify.categories.BACKGROUND)
      end
      if code == 0 then
        -- Parse the output
        local result_str = table.concat(output, '\n')
        
        if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
          notify.himalaya('Himalaya output length: ' .. #result_str .. ' bytes', notify.categories.BACKGROUND)
          
        end
        
        local success, emails = pcall(vim.json.decode, result_str)
        
        if success and type(emails) == 'table' then
          if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
            notify.himalaya('Successfully parsed JSON, email count from IMAP: ' .. #emails, notify.categories.BACKGROUND)
          end
          
          -- Handle empty mailbox case
          if #emails == 0 then
            if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
              notify.himalaya('Remote mailbox is empty', notify.categories.BACKGROUND)
            end
            callback({
              has_new = false,
              local_count = 0,
              remote_count = 0,
              new_count = 0
            })
            return
          end
          
          -- Get local emails to compare (always use the maildir account, not IMAP)
          local maildir_account = account_name:gsub('%-imap$', '')  -- Remove -imap suffix if present
          local local_emails = utils.get_email_list(maildir_account, folder, 1, 50)
          local local_count = local_emails and #local_emails or 0
          
          -- Since maildir and IMAP use completely different ID systems, we cannot compare IDs
          -- Instead, we'll use a simpler approach based on counts and subjects
          local has_new = false
          local new_count = 0
          
          -- Get total count from maildir (not just first 50)
          local all_local_emails, total_local_count = utils.get_email_list(maildir_account, folder, 1, 1000)
          local actual_local_count = total_local_count or (all_local_emails and #all_local_emails) or 0
          
          -- For IMAP, we need to get the total count, not just what we fetched
          -- Since we only fetched 50, we'll need to make another request or estimate
          -- For now, assume if we got 50 emails, there might be more
          local remote_count_estimate = #emails
          if #emails == 50 and (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
            -- We hit the limit, so there are likely more emails on the server
            notify.himalaya('Remote mailbox has 50+ emails (exact count unknown)', notify.categories.BACKGROUND)
          end
          
          -- Simple heuristic: if local count is significantly different from remote sample, we're out of sync
          -- This isn't perfect but avoids the ID comparison problem
          if actual_local_count == 0 and #emails > 0 then
            -- Empty local, emails on remote
            has_new = true
            new_count = #emails
            if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
              notify.himalaya(string.format('Local maildir empty, remote has %d+ emails', #emails), notify.categories.BACKGROUND)
            end
          elseif #emails == 0 and actual_local_count > 0 then
            -- Remote empty (or inaccessible), local has emails
            has_new = false
            new_count = 0
            if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
              notify.himalaya(string.format('Remote appears empty, local has %d emails', actual_local_count), notify.categories.BACKGROUND)
            end
          else
            -- Both have emails - check if the most recent subjects match
            -- This is a heuristic that works well in practice
            local local_latest_subject = local_emails and local_emails[1] and local_emails[1].subject
            local remote_latest_subject = emails[1] and emails[1].subject
            
            if local_latest_subject ~= remote_latest_subject then
              -- Different latest emails suggests new mail
              has_new = true
              -- We can't know exact count without comparing all emails
              new_count = 1 -- Conservative estimate
              if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
                notify.himalaya('Latest email subjects differ - new mail likely', notify.categories.BACKGROUND)
                notify.himalaya('Local latest: ' .. (local_latest_subject or 'none'), notify.categories.BACKGROUND)
                notify.himalaya('Remote latest: ' .. (remote_latest_subject or 'none'), notify.categories.BACKGROUND)
              end
            else
              -- Same latest email, probably in sync
              has_new = false
              new_count = 0
              if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
                notify.himalaya('Latest emails match - maildir appears in sync', notify.categories.BACKGROUND)
              end
            end
          end
          
          if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
            notify.himalaya(string.format('Local count: %d, Remote sample: %d, Has new: %s', 
                          actual_local_count, #emails, tostring(has_new)), notify.categories.BACKGROUND)
          end
          
          callback({
            has_new = has_new,
            local_count = local_count,
            remote_count = #emails,  -- This is actually just the first page
            new_count = new_count
          })
        else
          if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
            notify.himalaya('Failed to parse JSON: ' .. tostring(emails), notify.categories.BACKGROUND)
          end
          callback(nil, "Failed to parse Himalaya output")
        end
      else
        -- Return error with stderr output
        local error_msg = table.concat(stderr_output, '\n')
        if error_msg == "" then
          error_msg = "Himalaya check failed with exit code: " .. code
        end
        
        -- Check for specific error types
        if error_msg:match('account.*not found') and error_msg:match(check_account) then
          -- Missing account
          callback(nil, "IMAP account '" .. check_account .. "' not found in Himalaya config")
        elseif error_msg:match('AUTHENTICATIONFAILED') or error_msg:match('Invalid credentials') or 
               error_msg:match('authentication') or error_msg:match('AUTH') then
          -- Authentication failure
          local auth_error = 'OAuth authentication failed for ' .. check_account .. '\n' ..
                            'Himalaya uses separate OAuth tokens from mbsync.\n' ..
                            'To authenticate, run: himalaya account configure ' .. check_account
          callback(nil, auth_error)
        elseif error_msg == "" and code ~= 0 then
          -- Generic failure with no stderr - likely hanging on auth
          callback(nil, 'Himalaya command failed. If it hung, the ' .. check_account .. 
                       ' account may need authentication.\nRun: himalaya account configure ' .. check_account)
        else
          callback(nil, error_msg)
        end
      end
    end
  })
  
  if job_id <= 0 then
    notify.himalaya('Failed to start himalaya job, job_id: ' .. tostring(job_id), notify.categories.ERROR)
  elseif (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) then
    notify.himalaya('Started himalaya job with ID: ' .. tostring(job_id), notify.categories.BACKGROUND)
  end
  
  return job_id
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

return M