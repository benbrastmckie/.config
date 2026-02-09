-- Account Configuration Module
-- Manages email account settings and credentials

local M = {}

-- Dependencies
local logger = require('neotex.plugins.tools.himalaya.core.logger')

-- Module state
local module_state = {
  current_account = 'gmail',
  accounts = {}
}

-- Default account configuration
M.defaults = {
  gmail = {
    -- Email address
    email = nil, -- Will be auto-detected from himalaya config

    -- Display name for the account
    display_name = nil, -- Will be auto-detected from himalaya config

    -- mbsync channel names
    mbsync = {
      inbox_channel = "gmail-inbox",
      all_channel = "gmail",
    }
  },
  logos = {
    -- Email address
    email = nil, -- Will be auto-detected from himalaya config

    -- Display name for the account
    display_name = nil, -- Will be auto-detected from himalaya config

    -- mbsync channel names (via Protonmail Bridge)
    mbsync = {
      inbox_channel = "logos-inbox",
      all_channel = "logos",
    }
  }
}

-- Initialize module with configuration
function M.init(config)
  module_state.accounts = config.accounts or M.defaults
  module_state.current_account = config.current_account or 'gmail'
  
  logger.debug('Accounts module initialized', {
    account_count = vim.tbl_count(module_state.accounts),
    current = module_state.current_account
  })
end

-- Get current account name
function M.get_current_account_name()
  return module_state.current_account
end

-- Get current account configuration
function M.get_current_account()
  return module_state.accounts[module_state.current_account]
end

-- Get specific account configuration
function M.get_account(name)
  return module_state.accounts[name]
end

-- Switch to a different account
function M.switch_account(name)
  if module_state.accounts[name] then
    module_state.current_account = name
    logger.info('Switched account', { account = name })
    return true
  end
  return false, "Account not found: " .. name
end

-- Get account email address
function M.get_account_email(account_name)
  local account = module_state.accounts[account_name]
  if not account then
    -- Fallback: if account name looks like an email, use it
    if account_name and account_name:match("@") then
      return account_name
    end
    return nil
  end
  
  -- If email is already configured, return it
  if account.email then
    return account.email
  end
  
  -- Try to read email from himalaya config file
  local himalaya_config_path = vim.fn.expand('~/.config/himalaya/config.toml')
  if vim.fn.filereadable(himalaya_config_path) == 1 then
    local content = vim.fn.readfile(himalaya_config_path)
    local in_account_section = false
    
    for _, line in ipairs(content) do
      -- Check if we're entering the correct account section
      if line:match("^%[accounts%." .. account_name .. "%]") then
        in_account_section = true
      elseif line:match("^%[") then
        -- We've entered a different section
        in_account_section = false
      elseif in_account_section then
        -- Look for email field
        local email = line:match("^%s*email%s*=%s*['\"]([^'\"]+)['\"]")
        if email then
          -- Cache it for future use
          account.email = email
          return email
        end
      end
    end
  end
  
  -- Fallback: if account name looks like an email, use it
  if account_name:match("@") then
    return account_name
  end
  
  return nil
end

-- Get account display name
function M.get_account_display_name(account_name)
  local account = module_state.accounts[account_name]
  if not account then
    return account_name
  end
  
  -- If display_name is already configured, return it
  if account.display_name then
    return account.display_name
  end
  
  -- Try to read display-name from himalaya config file
  local himalaya_config_path = vim.fn.expand('~/.config/himalaya/config.toml')
  if vim.fn.filereadable(himalaya_config_path) == 1 then
    local content = vim.fn.readfile(himalaya_config_path)
    local in_account_section = false
    
    for _, line in ipairs(content) do
      -- Check if we're entering the correct account section
      if line:match("^%[accounts%." .. account_name .. "%]") then
        in_account_section = true
      elseif line:match("^%[") then
        -- We've entered a different section
        in_account_section = false
      elseif in_account_section then
        -- Look for display-name field
        local display_name = line:match("^%s*display%-name%s*=%s*['\"]([^'\"]+)['\"]")
        if display_name then
          -- Cache it for future use
          account.display_name = display_name
          return display_name
        end
      end
    end
  end
  
  -- No display name found
  return nil
end

-- Get formatted from header for an account
function M.get_formatted_from(account_name)
  local email = M.get_account_email(account_name)
  if not email then
    return nil
  end
  
  local display_name = M.get_account_display_name(account_name)
  if display_name then
    return string.format('%s <%s>', display_name, email)
  else
    return email
  end
end

-- Get all configured accounts
function M.get_all_accounts()
  local accounts = {}
  for name, _ in pairs(module_state.accounts) do
    table.insert(accounts, name)
  end
  return accounts
end

-- Check if an account exists
function M.has_account(name)
  return module_state.accounts[name] ~= nil
end

-- Update account configuration
function M.update_account(name, updates)
  if not module_state.accounts[name] then
    return false, "Account not found: " .. name
  end
  
  module_state.accounts[name] = vim.tbl_deep_extend('force', module_state.accounts[name], updates)
  logger.info('Account updated', { account = name })
  return true
end

-- Get mbsync configuration for account
function M.get_mbsync_config(account_name)
  local account = module_state.accounts[account_name]
  if not account then
    return nil
  end
  
  return account.mbsync or {}
end

return M