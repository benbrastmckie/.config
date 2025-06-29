-- OAuth management module
-- Handles token validation and refresh

local M = {}

-- Dependencies
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local state = require('neotex.plugins.tools.himalaya.core.state')
local config = require('neotex.plugins.tools.himalaya.core.config')

-- Constants
local REFRESH_COOLDOWN = 300 -- 5 minutes
local REFRESH_RETRY_COOLDOWN = 60 -- 1 minute

-- Load environment variables (NixOS systemd support)
function M.load_environment()
  local env_vars = {}
  
  -- Try systemd environment first
  local handle = io.popen('systemctl --user show-environment 2>/dev/null')
  if handle then
    local output = handle:read('*a')
    handle:close()
    
    for line in output:gmatch('[^\n]+') do
      local key, value = line:match('^([^=]+)=(.+)$')
      if key and value then
        env_vars[key] = value
      end
    end
  end
  
  -- Specific OAuth-related variables we need
  local oauth_vars = {
    'GMAIL_CLIENT_ID',
    'GMAIL_CLIENT_SECRET',
    'SASL_PATH',
    'GOOGLE_APPLICATION_CREDENTIALS'
  }
  
  for _, var in ipairs(oauth_vars) do
    if env_vars[var] then
      vim.fn.setenv(var, env_vars[var])
    end
  end
  
  return env_vars
end

-- Check if OAuth token exists
function M.has_token(account)
  account = account or 'gmail'
  
  -- Check using secret-tool (GNOME keyring)
  local cmd = string.format(
    'secret-tool lookup account %s 2>/dev/null | grep -q "access-token"',
    vim.fn.shellescape(account)
  )
  
  return os.execute(cmd) == 0
end

-- Check if OAuth token is valid (not expired)
function M.is_valid(account)
  account = account or 'gmail'
  
  -- If we recently refreshed, assume it's valid
  local last_refresh = state.get("oauth.last_refresh", 0)
  if os.time() - last_refresh < REFRESH_COOLDOWN then
    return true
  end
  
  -- Check if token exists
  if not M.has_token(account) then
    return false
  end
  
  -- We can't easily check expiration without parsing the token
  -- So we'll rely on mbsync failing and triggering a refresh
  return true
end

-- Refresh OAuth token
function M.refresh(account, callback)
  account = account or 'gmail'
  
  -- Check if refresh is already in progress
  if state.get("oauth.refresh_in_progress", false) then
    logger.info('OAuth refresh already in progress')
    if callback then
      callback(false, "refresh in progress")
    end
    return
  end
  
  -- Check cooldown
  local last_refresh = state.get("oauth.last_refresh", 0)
  if os.time() - last_refresh < REFRESH_RETRY_COOLDOWN then
    logger.info('OAuth refresh on cooldown')
    if callback then
      callback(false, "cooldown")
    end
    return
  end
  
  state.set("oauth.refresh_in_progress", true)
  logger.info('Refreshing OAuth token...')
  
  -- Load environment
  M.load_environment()
  
  -- Try to find refresh script
  local refresh_script = nil
  local possible_paths = {
    '/home/benjamin/.nix-profile/bin/refresh-gmail-oauth2',
    vim.fn.expand('~/.local/bin/refresh-oauth'),
    '/usr/local/bin/oauth2-refresh'
  }
  
  for _, path in ipairs(possible_paths) do
    if vim.fn.filereadable(path) == 1 then
      refresh_script = path
      break
    end
  end
  
  if not refresh_script then
    state.set("oauth.refresh_in_progress", false)
    logger.error('OAuth refresh script not found')
    logger.info('Run: himalaya account configure ' .. account)
    if callback then
      callback(false, "no refresh script")
    end
    return
  end
  
  -- Run refresh script
  vim.fn.jobstart({refresh_script}, {
    detach = false,
    on_exit = function(_, code)
      state.set("oauth.refresh_in_progress", false)
      
      if code == 0 then
        state.set("oauth.last_refresh", os.time())
        logger.info('OAuth token refreshed successfully')
        if callback then
          callback(true)
        end
      else
        logger.error('OAuth refresh failed (exit code: ' .. code .. ')')
        logger.info('You may need to reconfigure: himalaya account configure ' .. account)
        if callback then
          callback(false, "exit code " .. code)
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line ~= '' and not line:match('Missing OAuth2 credentials') then
            logger.debug('OAuth: ' .. line)
          end
        end
      end
    end
  })
end

-- Refresh and retry a function
function M.refresh_and_retry(fn, account)
  M.refresh(account, function(success)
    if success then
      -- Give it a moment for the token to propagate
      vim.defer_fn(function()
        fn()
      end, 1000)
    else
      logger.error('Failed to refresh OAuth token')
    end
  end)
end

-- Get OAuth status information
function M.get_status(account)
  account = account or 'gmail'
  
  local status = {
    has_token = M.has_token(account),
    last_refresh = state.get("oauth.last_refresh", 0),
    refresh_in_progress = state.get("oauth.refresh_in_progress", false),
    environment_loaded = false
  }
  
  -- Check environment
  local env = M.load_environment()
  status.environment_loaded = env.GMAIL_CLIENT_ID ~= nil
  
  return status
end

-- Initialize OAuth module
function M.setup()
  -- Load environment on startup
  M.load_environment()
end

return M