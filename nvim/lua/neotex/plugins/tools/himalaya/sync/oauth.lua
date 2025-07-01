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
  
  -- Build the correct token name based on account
  local token_name = account .. '-smtp-oauth2-access-token'
  if account:match('-imap$') then
    -- For IMAP accounts, the pattern is account-imap-oauth2
    -- e.g., gmail-imap becomes gmail-imap-imap-oauth2-access-token
    token_name = account .. '-imap-oauth2-access-token'
  end
  
  -- Check using secret-tool (GNOME keyring) with himalaya's specific format
  local cmd = string.format('secret-tool lookup service himalaya-cli username %s 2>/dev/null | grep -q .', token_name)
  
  local result = os.execute(cmd)
  return result == 0
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
  
  -- Check cooldown only if we've tried recently and failed
  local last_refresh = state.get("oauth.last_refresh", 0)
  local last_refresh_failed = state.get("oauth.last_refresh_failed", false)
  if last_refresh_failed and os.time() - last_refresh < REFRESH_RETRY_COOLDOWN then
    logger.info('OAuth refresh on cooldown')
    if callback then
      callback(false, "cooldown")
    end
    return
  end
  
  state.set("oauth.refresh_in_progress", true)
  logger.debug('Refreshing OAuth token...')
  
  -- Load environment
  M.load_environment()
  
  -- Try to find refresh script
  local refresh_script = nil
  local possible_paths = {}
  
  -- For IMAP accounts, prefer our wrapper script
  if account and account:match('-imap$') then
    -- Get the himalaya plugin directory path
    local current_file = debug.getinfo(1).source:sub(2)  -- Remove the @ prefix
    local sync_dir = vim.fn.fnamemodify(current_file, ':h')  -- sync directory
    local himalaya_dir = vim.fn.fnamemodify(sync_dir, ':h')  -- himalaya directory
    local script_path = himalaya_dir .. '/scripts/refresh-himalaya-oauth2'
    
    logger.debug('Looking for refresh script at: ' .. script_path)
    table.insert(possible_paths, script_path)
  end
  
  -- Get the himalaya scripts directory
  local current_file = debug.getinfo(1).source:sub(2)
  local sync_dir = vim.fn.fnamemodify(current_file, ':h')
  local himalaya_dir = vim.fn.fnamemodify(sync_dir, ':h')
  local scripts_dir = himalaya_dir .. '/scripts'
  
  -- Add standard paths
  local standard_paths = {
    scripts_dir .. '/refresh-gmail-oauth2',  -- Check himalaya scripts first
    'refresh-gmail-oauth2',  -- Try PATH
    '/home/benjamin/.nix-profile/bin/refresh-gmail-oauth2',
    vim.fn.expand('~/.local/bin/refresh-gmail-oauth2'),
    vim.fn.expand('~/.local/bin/refresh-oauth'),
    '/usr/local/bin/oauth2-refresh',
    '/usr/local/bin/refresh-gmail-oauth2'
  }
  
  for _, path in ipairs(standard_paths) do
    table.insert(possible_paths, path)
  end
  
  for _, path in ipairs(possible_paths) do
    -- Check if it's a command in PATH (no slashes)
    if not path:match('/') then
      if vim.fn.executable(path) == 1 then
        refresh_script = path
        break
      end
    else
      -- It's a full path, check if file exists
      if vim.fn.filereadable(path) == 1 then
        refresh_script = path
        logger.debug('Found refresh script at: ' .. path)
        break
      elseif vim.fn.executable(path) == 1 then
        -- Sometimes filereadable fails but executable works
        refresh_script = path
        logger.debug('Found executable refresh script at: ' .. path)
        break
      end
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
  
  -- Build refresh command
  local cmd = {refresh_script}
  
  -- If using our wrapper script, pass the account name
  if refresh_script:match('refresh-himalaya-oauth2') and account then
    table.insert(cmd, account)
    logger.debug('Using wrapper script with account: ' .. account)
  elseif account and account:match('-imap$') then
    logger.info('Warning: Standard refresh script may not work for IMAP account: ' .. account)
  end
  
  logger.debug('Running OAuth refresh command: ' .. table.concat(cmd, ' '))
  
  -- Run refresh script
  vim.fn.jobstart(cmd, {
    detach = false,
    on_exit = function(_, code)
      state.set("oauth.refresh_in_progress", false)
      
      if code == 0 then
        state.set("oauth.last_refresh", os.time())
        state.set("oauth.last_refresh_failed", false)
        logger.info('OAuth token refreshed successfully for ' .. account)
        
        -- Debug notification
        local notify = require('neotex.util.notifications')
        if notify.config.modules.himalaya.debug_mode then
          notify.himalaya('OAuth token refreshed successfully for ' .. account, notify.categories.DEBUG)
          
          -- Verify token exists after refresh
          vim.defer_fn(function()
            if M.has_token(account) then
              notify.himalaya('Token verified after refresh for ' .. account, notify.categories.DEBUG)
            else
              notify.himalaya('WARNING: Token still missing after refresh for ' .. account, notify.categories.DEBUG)
            end
          end, 500)
        end
        
        if callback then
          callback(true)
        end
      else
        state.set("oauth.last_refresh", os.time())
        state.set("oauth.last_refresh_failed", true)
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

-- Get detailed token information
function M.get_token_info(account)
  account = account or 'gmail'
  local info = {}
  
  -- Determine token suffix based on account type
  local token_suffix = account:match('-imap$') and '-imap-oauth2' or '-smtp-oauth2'
  
  -- Check access token
  local handle = io.popen(string.format('secret-tool lookup service himalaya-cli username %s%s-access-token 2>/dev/null', account, token_suffix))
  if handle then
    local token = handle:read('*a')
    handle:close()
    info.has_access_token = token and token ~= ''
    info.access_token_preview = token and token:sub(1, 10) .. '...' or nil
  end
  
  -- Check refresh token
  handle = io.popen(string.format('secret-tool lookup service himalaya-cli username %s%s-refresh-token 2>/dev/null', account, token_suffix))
  if handle then
    local token = handle:read('*a')
    handle:close()
    info.has_refresh_token = token and token ~= ''
  end
  
  -- Check client secret
  handle = io.popen(string.format('secret-tool lookup service himalaya-cli username %s%s-client-secret 2>/dev/null', account, token_suffix))
  if handle then
    local token = handle:read('*a')
    handle:close()
    info.has_client_secret = token and token ~= ''
  end
  
  return info
end

-- Get OAuth status information
function M.get_status(account)
  account = account or 'gmail'
  
  local status = {
    has_token = M.has_token(account),
    last_refresh = state.get("oauth.last_refresh", 0),
    refresh_in_progress = state.get("oauth.refresh_in_progress", false),
    environment_loaded = false,
    token_info = M.get_token_info(account)
  }
  
  -- Check environment
  local env = M.load_environment()
  status.environment_loaded = env.GMAIL_CLIENT_ID ~= nil
  
  return status
end

-- Ensure OAuth token exists, refreshing if necessary
function M.ensure_token(account, callback)
  account = account or 'gmail'
  
  -- First check if token exists
  if M.has_token(account) then
    logger.debug('OAuth token found')
    if callback then
      callback(true)
    end
    return
  end
  
  -- No token found, try to refresh
  logger.info('No OAuth token found, attempting automatic refresh...')
  M.refresh(account, function(success, error)
    if success then
      -- Double check that token now exists
      if M.has_token(account) then
        logger.info('OAuth token successfully obtained')
        if callback then
          callback(true)
        end
      else
        logger.error('OAuth refresh succeeded but token still not found')
        if callback then
          callback(false, "token not found after refresh")
        end
      end
    else
      -- Refresh failed, but let's check one more time in case
      -- the token was created by another process
      vim.defer_fn(function()
        if M.has_token(account) then
          logger.info('OAuth token found after retry')
          if callback then
            callback(true)
          end
        else
          logger.debug('OAuth token still not found after refresh attempt')
          if callback then
            callback(false, error or "no token")
          end
        end
      end, 1000)
    end
  end)
end

-- Initialize OAuth module
function M.setup()
  -- Load environment on startup
  M.load_environment()
end

return M