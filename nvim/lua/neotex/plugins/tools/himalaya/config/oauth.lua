-- OAuth Configuration Module
-- Manages OAuth settings for email accounts

local M = {}

-- Dependencies
local logger = require('neotex.plugins.tools.himalaya.core.logger')

-- Module state
local module_state = {
  oauth_configs = {},
  sync_settings = {}
}

-- Default OAuth configurations
M.defaults = {
  gmail = {
    client_id_env = "GMAIL_CLIENT_ID",
    client_secret_env = "GMAIL_CLIENT_SECRET", 
    refresh_command = "refresh-gmail-oauth2",
    configure_command = "himalaya account configure gmail",
  }
}

-- Initialize module with configuration
function M.init(config)
  -- Extract OAuth configurations from accounts
  module_state.oauth_configs = {}
  
  if config.accounts then
    for account_name, account_config in pairs(config.accounts) do
      if account_config.oauth then
        module_state.oauth_configs[account_name] = account_config.oauth
      elseif M.defaults[account_name] then
        -- Use defaults if not specified
        module_state.oauth_configs[account_name] = M.defaults[account_name]
      end
    end
  end
  
  -- Extract sync settings related to OAuth
  if config.sync then
    module_state.sync_settings = {
      auto_refresh_oauth = config.sync.auto_refresh_oauth,
      oauth_refresh_cooldown = config.sync.oauth_refresh_cooldown
    }
  end
  
  logger.debug('OAuth module initialized', {
    account_count = vim.tbl_count(module_state.oauth_configs),
    auto_refresh = module_state.sync_settings.auto_refresh_oauth
  })
end

-- Get OAuth configuration for an account
function M.get_oauth_config(account_name)
  return module_state.oauth_configs[account_name]
end

-- Check if account uses OAuth
function M.uses_oauth(account_name)
  return module_state.oauth_configs[account_name] ~= nil
end

-- Get OAuth client ID from environment
function M.get_client_id(account_name)
  local oauth_config = module_state.oauth_configs[account_name]
  if not oauth_config or not oauth_config.client_id_env then
    return nil
  end
  
  local value = vim.fn.getenv(oauth_config.client_id_env)
  if value == vim.NIL then
    return nil
  end
  return value
end

-- Get OAuth client secret from environment
function M.get_client_secret(account_name)
  local oauth_config = module_state.oauth_configs[account_name]
  if not oauth_config or not oauth_config.client_secret_env then
    return nil
  end
  
  local value = vim.fn.getenv(oauth_config.client_secret_env)
  if value == vim.NIL then
    return nil
  end
  return value
end

-- Get OAuth refresh command for an account
function M.get_refresh_command(account_name)
  local oauth_config = module_state.oauth_configs[account_name]
  if not oauth_config then
    return nil
  end
  
  return oauth_config.refresh_command
end

-- Get OAuth configure command for an account
function M.get_configure_command(account_name)
  local oauth_config = module_state.oauth_configs[account_name]
  if not oauth_config then
    return nil
  end
  
  return oauth_config.configure_command
end

-- Check if OAuth auto-refresh is enabled
function M.is_auto_refresh_enabled()
  return module_state.sync_settings.auto_refresh_oauth ~= false
end

-- Get OAuth refresh cooldown period
function M.get_refresh_cooldown()
  return module_state.sync_settings.oauth_refresh_cooldown or 300 -- 5 minutes default
end

-- Update OAuth configuration for an account
function M.update_oauth_config(account_name, updates)
  if not module_state.oauth_configs[account_name] then
    module_state.oauth_configs[account_name] = {}
  end
  
  module_state.oauth_configs[account_name] = vim.tbl_deep_extend(
    'force',
    module_state.oauth_configs[account_name],
    updates
  )
  
  logger.info('OAuth config updated', { account = account_name })
end

-- Check if OAuth credentials are configured
function M.has_credentials(account_name)
  local client_id = M.get_client_id(account_name)
  local client_secret = M.get_client_secret(account_name)
  
  return client_id ~= nil and client_id ~= '' and
         client_secret ~= nil and client_secret ~= ''
end

-- Get all accounts with OAuth configured
function M.get_oauth_accounts()
  local accounts = {}
  for account_name, _ in pairs(module_state.oauth_configs) do
    table.insert(accounts, account_name)
  end
  return accounts
end

-- Validate OAuth configuration for an account
function M.validate(account_name)
  local oauth_config = module_state.oauth_configs[account_name]
  if not oauth_config then
    return true -- No OAuth configured is valid
  end
  
  local errors = {}
  
  -- Check required fields
  if not oauth_config.refresh_command then
    table.insert(errors, account_name .. ": OAuth refresh_command not configured")
  end
  
  if not oauth_config.client_id_env then
    table.insert(errors, account_name .. ": OAuth client_id_env not configured")
  end
  
  if not oauth_config.client_secret_env then
    table.insert(errors, account_name .. ": OAuth client_secret_env not configured")
  end
  
  -- Check if environment variables are set
  if oauth_config.client_id_env and not M.get_client_id(account_name) then
    table.insert(errors, account_name .. ": OAuth client ID environment variable '" .. 
                        oauth_config.client_id_env .. "' not set")
  end
  
  if oauth_config.client_secret_env and not M.get_client_secret(account_name) then
    table.insert(errors, account_name .. ": OAuth client secret environment variable '" .. 
                        oauth_config.client_secret_env .. "' not set")
  end
  
  return #errors == 0, errors
end

return M