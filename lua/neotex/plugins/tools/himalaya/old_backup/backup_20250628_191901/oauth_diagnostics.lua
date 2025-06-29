-- OAuth2 Diagnostics Module
-- Helps diagnose and resolve OAuth authentication issues

local M = {}

local notify = require('neotex.util.notifications')

-- Check OAuth token status
function M.check_oauth_status()
  notify.himalaya('Checking OAuth2 status...', notify.categories.INFO)
  
  -- Check for all required tokens
  local tokens = {
    ['access-token'] = 'OAuth2 Access Token',
    ['refresh-token'] = 'OAuth2 Refresh Token', 
    ['client-secret'] = 'OAuth2 Client Secret'
  }
  
  local missing = {}
  local found = {}
  
  for key, name in pairs(tokens) do
    local cmd = string.format(
      'secret-tool lookup service himalaya-cli username gmail-smtp-oauth2-%s 2>/dev/null',
      key
    )
    local result = vim.fn.system(cmd)
    
    if vim.v.shell_error == 0 and result and result ~= '' then
      found[key] = true
      -- For access token, check if it's expired
      if key == 'access-token' then
        -- Try to decode JWT to check expiration
        local decode_cmd = string.format(
          'echo "%s" | cut -d. -f2 | base64 -d 2>/dev/null | jq -r .exp 2>/dev/null',
          vim.trim(result)
        )
        local exp_time = vim.fn.system(decode_cmd)
        if vim.v.shell_error == 0 and exp_time and exp_time ~= '' then
          local exp = tonumber(vim.trim(exp_time))
          local now = os.time()
          if exp and exp < now then
            notify.himalaya('Access token is EXPIRED', notify.categories.ERROR)
          else
            local remaining = exp - now
            notify.himalaya(string.format('Access token expires in %d minutes', math.floor(remaining / 60)), notify.categories.INFO)
          end
        end
      end
    else
      table.insert(missing, name)
    end
  end
  
  -- Report findings
  if #missing == 0 then
    notify.himalaya('All OAuth2 tokens found!', notify.categories.SUCCESS)
  else
    notify.himalaya('Missing tokens: ' .. table.concat(missing, ', '), notify.categories.ERROR)
  end
  
  -- Check environment variables
  local env_vars = {
    GMAIL_CLIENT_ID = vim.env.GMAIL_CLIENT_ID,
    SASL_PATH = vim.env.SASL_PATH
  }
  
  for var, value in pairs(env_vars) do
    if value and value ~= '' then
      notify.himalaya(string.format('%s is set', var), notify.categories.INFO)
    else
      notify.himalaya(string.format('%s is NOT set', var), notify.categories.ERROR)
    end
  end
  
  -- Provide guidance
  if #missing > 0 then
    notify.himalaya('\nTo fix OAuth authentication:', notify.categories.INFO)
    notify.himalaya('1. Open a terminal (outside Neovim)', notify.categories.INFO)
    notify.himalaya('2. Run: himalaya account configure gmail', notify.categories.INFO)
    notify.himalaya('3. Follow the OAuth2 setup in your browser', notify.categories.INFO)
    notify.himalaya('4. This will store all required tokens', notify.categories.INFO)
    
    if not found['client-secret'] then
      notify.himalaya('\nNote: Client secret is required for token refresh', notify.categories.WARNING)
      notify.himalaya('You\'ll need your OAuth2 client secret from Google Cloud Console', notify.categories.WARNING)
    end
  end
  
  return found, missing
end

-- Test mbsync authentication
function M.test_mbsync_auth()
  notify.himalaya('Testing mbsync authentication...', notify.categories.INFO)
  
  -- First check if we have an access token
  local token_cmd = 'secret-tool lookup service himalaya-cli username gmail-smtp-oauth2-access-token 2>/dev/null'
  local token = vim.fn.system(token_cmd)
  
  if vim.v.shell_error ~= 0 or not token or token == '' then
    notify.himalaya('No access token found', notify.categories.ERROR)
    return false
  end
  
  -- Try a quick mbsync test (--list to check connection)
  local test_cmd = 'timeout 10 mbsync --list gmail-inbox 2>&1'
  local result = vim.fn.system(test_cmd)
  
  if result:match('Authenticating with SASL mechanism XOAUTH2') then
    if result:match('OK Success') or result:match('Logging in...OK') then
      notify.himalaya('mbsync authentication SUCCESSFUL', notify.categories.SUCCESS)
      return true
    elseif result:match('NO') or result:match('Authentication failed') then
      notify.himalaya('mbsync authentication FAILED', notify.categories.ERROR)
      notify.himalaya('Access token may be expired or invalid', notify.categories.ERROR)
      return false
    elseif result:match('timeout') then
      notify.himalaya('mbsync authentication TIMED OUT', notify.categories.ERROR)
      notify.himalaya('This often means the token is expired', notify.categories.ERROR)
      return false
    end
  else
    notify.himalaya('mbsync test output:', notify.categories.DEBUG)
    for line in result:gmatch('[^\r\n]+') do
      notify.himalaya(line, notify.categories.DEBUG)
    end
  end
  
  return false
end

-- Full diagnostic command
function M.run_diagnostics()
  notify.himalaya('=== OAuth2 Diagnostics ===', notify.categories.INFO)
  
  -- Check OAuth status
  local found, missing = M.check_oauth_status()
  
  -- Test mbsync if we have tokens
  if found['access-token'] then
    vim.defer_fn(function()
      M.test_mbsync_auth()
    end, 100)
  end
end

return M