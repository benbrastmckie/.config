-- Multiple Account Support
-- Manages multiple email accounts with switching and unified views

local M = {}

local state = require('neotex.plugins.tools.himalaya.core.state')
local config = require('neotex.plugins.tools.himalaya.core.config')
local events = require('neotex.plugins.tools.himalaya.orchestration.events')
local event_constants = require('neotex.plugins.tools.himalaya.core.events')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local api = require('neotex.plugins.tools.himalaya.core.api')

-- Account schema
local account_schema = {
  name = "",              -- Account identifier
  email = "",             -- Email address
  display_name = "",      -- Display name
  type = "",              -- gmail, imap, etc.
  active = false,         -- Currently active account
  last_sync = 0,          -- Last sync timestamp
  unread_count = 0,       -- Unread email count
  folders = {}            -- Folder list cache
}

-- Get all configured accounts
function M.get_all_accounts()
  -- Get accounts from both config and state
  local config_accounts = config.config.accounts or {}
  local state_accounts = state.get('accounts', {})
  
  -- Merge accounts (state takes precedence for dynamic accounts)
  local all_accounts = vim.tbl_deep_extend("force", config_accounts, state_accounts)
  
  -- Add state information
  for name, account in pairs(all_accounts) do
    local account_state = state.get('accounts.' .. name, {})
    account.last_sync = account_state.last_sync or 0
    account.unread_count = account_state.unread_count or 0
    account.active = name == config.get_current_account_name()
  end
  
  return all_accounts
end

-- Get specific account
function M.get_account(name)
  local accounts = M.get_all_accounts()
  return accounts[name]
end

-- Switch to a different account
function M.switch_account(account_name)
  local account = M.get_account(account_name)
  
  if not account then
    return api.error("Account not found: " .. account_name, "ACCOUNT_NOT_FOUND")
  end
  
  -- Store current account in state (config is read-only)
  state.set('current_account', account_name)
  
  -- Also update runtime config
  config.current_account = account_name
  
  -- Emit event
  events.emit(event_constants.ACCOUNT_SWITCHED, {
    from = config.get_current_account_name(),
    to = account_name,
    account = account
  })
  
  logger.info("Switched to account: " .. account_name)
  
  return api.success(account)
end

-- Add a new account
function M.add_account(account_config)
  -- Validate account config
  local valid, err = api.validate_params(account_config, {
    name = { required = true, type = "string" },
    email = { required = true, type = "string" },
    type = { required = true, type = "string", enum = {"gmail", "imap", "smtp"} }
  })
  
  if not valid then
    return api.error(err, "INVALID_ARGUMENTS")
  end
  
  -- Check if account already exists
  if M.get_account(account_config.name) then
    return api.error("Account already exists: " .. account_config.name, "ACCOUNT_EXISTS")
  end
  
  -- Add to state instead of config (config is read-only after setup)
  local accounts = state.get('accounts', {})
  accounts[account_config.name] = account_config
  state.set('accounts', accounts)
  
  -- Also store in runtime config for immediate access
  if not config.config.accounts then
    config.config.accounts = {}
  end
  config.config.accounts[account_config.name] = account_config
  
  -- Initialize state
  state.set('accounts.' .. account_config.name, {
    last_sync = 0,
    unread_count = 0,
    folders = {}
  })
  
  -- Emit event
  events.emit(event_constants.ACCOUNT_ADDED, {
    account = account_config
  })
  
  logger.info("Added account: " .. account_config.name)
  
  return api.success(account_config)
end

-- Remove an account
function M.remove_account(account_name)
  local account = M.get_account(account_name)
  
  if not account then
    return api.error("Account not found: " .. account_name, "ACCOUNT_NOT_FOUND")
  end
  
  -- Cannot remove active account
  if account.active then
    return api.error("Cannot remove active account", "ACCOUNT_ACTIVE")
  end
  
  -- Remove from state
  local accounts = state.get('accounts', {})
  accounts[account_name] = nil
  state.set('accounts', accounts)
  
  -- Also remove from runtime config if present
  if config.config.accounts and config.config.accounts[account_name] then
    config.config.accounts[account_name] = nil
  end
  
  -- Remove state
  state.set('accounts.' .. account_name, nil)
  
  -- Emit event
  events.emit(event_constants.ACCOUNT_REMOVED, {
    account_name = account_name
  })
  
  logger.info("Removed account: " .. account_name)
  
  return api.success({ removed = account_name })
end

-- Get unified inbox across all accounts
function M.get_unified_inbox(options)
  options = options or {}
  local emails = {}
  local errors = {}
  
  -- Get emails from each account
  for name, account in pairs(M.get_all_accounts()) do
    local utils = require('neotex.plugins.tools.himalaya.utils')
    local result = utils.execute_himalaya(
      {'envelope', 'list', '--page', '1', '--page-size', options.limit or 50},
      { account = name, folder = 'INBOX' }
    )
    
    if result.success then
      local account_emails = result.data or {}
      -- Add account info to each email
      for _, email in ipairs(account_emails) do
        email.account = name
        email.account_display = account.display_name or name
        table.insert(emails, email)
      end
    else
      table.insert(errors, {
        account = name,
        error = result.error
      })
    end
  end
  
  -- Sort by date
  table.sort(emails, function(a, b)
    return (a.date or 0) > (b.date or 0)
  end)
  
  return api.success({
    emails = emails,
    errors = errors,
    total_accounts = vim.tbl_count(M.get_all_accounts()),
    failed_accounts = #errors
  })
end

-- Update account folders
function M.update_account_folders(account_name)
  local account = M.get_account(account_name)
  
  if not account then
    return api.error("Account not found: " .. account_name, "ACCOUNT_NOT_FOUND")
  end
  
  local utils = require('neotex.plugins.tools.himalaya.utils')
  local result = utils.execute_himalaya(
    {'folder', 'list'},
    { account = account_name }
  )
  
  if result.success then
    -- Update state with folder list
    state.set('accounts.' .. account_name .. '.folders', result.data)
    
    return api.success(result.data)
  else
    return api.error("Failed to get folders: " .. result.error, "FOLDER_LIST_FAILED")
  end
end

-- Get account statistics
function M.get_account_stats(account_name)
  local account = M.get_account(account_name)
  
  if not account then
    return api.error("Account not found: " .. account_name, "ACCOUNT_NOT_FOUND")
  end
  
  local account_state = state.get('accounts.' .. account_name, {})
  
  return api.success({
    name = account_name,
    email = account.email,
    type = account.type,
    last_sync = account_state.last_sync,
    unread_count = account_state.unread_count,
    folder_count = vim.tbl_count(account_state.folders or {}),
    active = account.active
  })
end

-- Refresh all accounts
function M.refresh_all_accounts()
  local results = {}
  
  for name, account in pairs(M.get_all_accounts()) do
    local folder_result = M.update_account_folders(name)
    
    -- Update unread count
    local utils = require('neotex.plugins.tools.himalaya.utils')
    local count_result = utils.fetch_folder_count(name, 'INBOX')
    
    if count_result then
      state.set('accounts.' .. name .. '.unread_count', count_result.unread or 0)
    end
    
    results[name] = {
      folders = folder_result.success,
      unread_updated = count_result ~= nil
    }
  end
  
  return api.success(results)
end

return M