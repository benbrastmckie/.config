-- Simplified mbsync integration module
-- Maximum 200 lines as per REVISE.md specification

local M = {}

-- Dependencies
local lock = require("neotex.plugins.tools.himalaya.sync.lock")
local oauth = require("neotex.plugins.tools.himalaya.sync.oauth")
local logger = require("neotex.plugins.tools.himalaya.core.logger")
local state = require("neotex.plugins.tools.himalaya.core.state")

-- Constants
local MBSYNC_TIMEOUT = 300000 -- 5 minutes

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

-- Parse simple progress from mbsync output
function M.parse_progress(data)
  if not data then return nil end
  
  for _, line in ipairs(data) do
    if line and line ~= '' then
      -- Look for common mbsync patterns
      if line:match('Synchronizing') then
        return { status = 'syncing', message = 'Synchronizing messages...' }
      elseif line:match('(%d+) messages, (%d+) recent') then
        local total, recent = line:match('(%d+) messages, (%d+) recent')
        return { status = 'counting', total = tonumber(total), recent = tonumber(recent) }
      elseif line:match('Expunging') then
        return { status = 'expunging', message = 'Cleaning up deleted messages...' }
      end
    end
  end
  
  return nil
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
  local cmd = lock.wrap_command({'mbsync', channel})
  
  -- Update state
  state.set("sync.status", "running")
  state.set("sync.start_time", os.time())
  
  -- Start job
  M.current_job = vim.fn.jobstart(cmd, {
    detach = false,
    stdout_buffered = false,
    on_stdout = function(_, data)
      if opts.on_progress then
        local progress = M.parse_progress(data)
        if progress then
          opts.on_progress(progress)
        end
      end
    end,
    on_stderr = function(_, data)
      -- Log errors and check for auth failures
      if data and #data > 0 then
        local auth_error = false
        for _, line in ipairs(data) do
          if line ~= '' then
            logger.debug('mbsync: ' .. line)
            -- Check for authentication errors
            if line:match('AUTHENTICATE') or line:match('LOGIN') or 
               line:match('AUTH') or line:match('XOAUTH2') then
              auth_error = true
            end
          end
        end
        
        -- If auth error and auto_refresh enabled, try to refresh token
        if auth_error and opts.auto_refresh ~= false and not state.get("sync.auth_retry") then
          state.set("sync.auth_retry", true)
          logger.info("Authentication error detected, attempting OAuth refresh...")
          vim.fn.jobstop(M.current_job)
          M.current_job = nil
          
          oauth.ensure_token(nil, function(success)
            state.set("sync.auth_retry", false)
            if success then
              logger.info("OAuth refreshed, retrying sync...")
              vim.defer_fn(function()
                M.sync(channel, opts)
              end, 1000)
            else
              logger.error("Failed to refresh OAuth token")
              state.set("sync.last_error", "Authentication failed - OAuth refresh failed")
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
      
      if code == 0 then
        logger.info("Sync completed successfully")
        state.set("sync.last_error", nil)
      else
        logger.error("Sync failed with code: " .. code)
        state.set("sync.last_error", "Sync failed with code: " .. code)
      end
      
      if opts.callback then
        -- Pass error message string for consistency
        local error_msg = nil
        if code ~= 0 then
          if code == 143 then
            error_msg = "Sync cancelled"
          else
            error_msg = state.get("sync.last_error", "Sync failed with code: " .. code)
          end
        end
        opts.callback(code == 0, error_msg)
      end
    end
  })
  
  if M.current_job <= 0 then
    M.current_job = nil
    state.set("sync.status", "idle")
    return false, "Failed to start sync job"
  end
  
  -- Set timeout
  vim.defer_fn(function()
    if M.current_job then
      vim.fn.jobstop(M.current_job)
      M.current_job = nil
      state.set("sync.status", "idle")
      state.set("sync.last_error", "Sync timed out")
      logger.error("Sync timed out after 5 minutes")
      if opts.callback then
        opts.callback(false, "timeout")
      end
    end
  end, MBSYNC_TIMEOUT)
  
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

-- Get sync status
function M.get_status()
  return {
    running = M.current_job ~= nil,
    last_sync = state.get("sync.last_sync"),
    last_error = state.get("sync.last_error"),
    status = state.get("sync.status", "idle"),
  }
end

return M