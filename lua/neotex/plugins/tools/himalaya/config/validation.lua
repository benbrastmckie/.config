-- Configuration Validation Module
-- Validates and migrates configuration settings

local M = {}

-- Dependencies
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local notify = require('neotex.util.notifications')

-- Validation functions
local validators = {}

-- Validate account settings
function validators.validate_accounts(config)
  local errors = {}
  
  if not config.accounts or vim.tbl_isempty(config.accounts) then
    table.insert(errors, "No accounts configured")
    return errors
  end
  
  for name, account in pairs(config.accounts) do
    -- Account name validation
    if name:match("[^%w_-]") then
      table.insert(errors, string.format("Account name '%s' contains invalid characters", name))
    end
    
    -- Maildir path validation (if specified)
    if account.maildir_path then
      local path = vim.fn.expand(account.maildir_path)
      if not path:match("/$") then
        table.insert(errors, string.format("Account '%s': maildir_path must end with trailing slash", name))
      end
    end
  end
  
  return errors
end

-- Validate binary paths
function validators.validate_binaries(config)
  local errors = {}
  local binaries = config.binaries or {}
  
  -- Check himalaya binary
  local himalaya_bin = binaries.himalaya or 'himalaya'
  if vim.fn.executable(himalaya_bin) ~= 1 then
    table.insert(errors, string.format("Himalaya binary not found: %s", himalaya_bin))
  end
  
  -- Check mbsync binary (optional but recommended)
  local mbsync_bin = binaries.mbsync or 'mbsync'
  if vim.fn.executable(mbsync_bin) ~= 1 then
    logger.warn("mbsync binary not found", { binary = mbsync_bin })
  end
  
  return errors
end

-- Validate draft configuration
function validators.validate_draft_config(config)
  local errors = {}
  
  if not config.drafts then
    return errors  -- Drafts config is optional
  end
  
  local drafts = config.drafts
  
  -- Validate storage settings
  if drafts.storage then
    local storage = drafts.storage
    
    if storage.type and storage.type ~= 'maildir' and storage.type ~= 'local' then
      table.insert(errors, "Invalid draft storage type: " .. storage.type)
    end
    
    if storage.base_dir and type(storage.base_dir) ~= 'string' then
      table.insert(errors, "Draft storage base_dir must be a string")
    end
    
    if storage.format and storage.format ~= 'json' and storage.format ~= 'eml' then
      table.insert(errors, "Draft storage format must be 'json' or 'eml'")
    end
    
    if storage.local_dir then
      local dir = vim.fn.expand(storage.local_dir)
      if vim.fn.isdirectory(dir) ~= 1 then
        logger.warn("Draft local directory does not exist", { dir = dir })
      end
    end
  end
  
  -- Validate sync settings
  if drafts.sync then
    local sync = drafts.sync
    
    if sync.interval and (type(sync.interval) ~= 'number' or sync.interval < 0) then
      table.insert(errors, "Invalid draft sync interval: " .. tostring(sync.interval))
    end
    
    if sync.sync_interval and (type(sync.sync_interval) ~= 'number' or sync.sync_interval < 0) then
      table.insert(errors, "Draft sync sync_interval must be a positive number")
    end
    
    if sync.retry_attempts and type(sync.retry_attempts) ~= 'number' then
      table.insert(errors, "Draft sync retry_attempts must be a number")
    end
    
    if sync.on_save ~= nil and type(sync.on_save) ~= 'boolean' then
      table.insert(errors, "Invalid draft sync.on_save setting: must be boolean")
    end
  end
  
  -- Validate recovery settings
  if drafts.recovery then
    local recovery = drafts.recovery
    
    if recovery.backup_count and (type(recovery.backup_count) ~= 'number' or recovery.backup_count < 0) then
      table.insert(errors, "Invalid draft recovery.backup_count: " .. tostring(recovery.backup_count))
    end
    
    if recovery.auto_recover ~= nil and type(recovery.auto_recover) ~= 'boolean' then
      table.insert(errors, "Invalid draft recovery.auto_recover: must be boolean")
    end
  end
  
  -- Validate UI settings
  if drafts.ui then
    local ui = drafts.ui
    
    if ui.auto_save_interval and (type(ui.auto_save_interval) ~= 'number' or ui.auto_save_interval < 0) then
      table.insert(errors, "Invalid draft ui.auto_save_interval: " .. tostring(ui.auto_save_interval))
    end
  end
  
  return errors
end

-- Validate sync settings
function validators.validate_sync(config)
  local errors = {}
  
  if not config.sync then
    return errors
  end
  
  local sync = config.sync
  
  -- Validate lock timeout
  if sync.lock_timeout and (type(sync.lock_timeout) ~= 'number' or sync.lock_timeout < 0) then
    table.insert(errors, "Invalid sync.lock_timeout: " .. tostring(sync.lock_timeout))
  end
  
  -- Validate OAuth refresh cooldown
  if sync.oauth_refresh_cooldown and (type(sync.oauth_refresh_cooldown) ~= 'number' or sync.oauth_refresh_cooldown < 0) then
    table.insert(errors, "Invalid sync.oauth_refresh_cooldown: " .. tostring(sync.oauth_refresh_cooldown))
  end
  
  -- Validate coordination settings
  if sync.coordination then
    local coord = sync.coordination
    
    if coord.heartbeat_interval and (type(coord.heartbeat_interval) ~= 'number' or coord.heartbeat_interval < 0) then
      table.insert(errors, "Invalid sync.coordination.heartbeat_interval: " .. tostring(coord.heartbeat_interval))
    end
    
    if coord.takeover_threshold and (type(coord.takeover_threshold) ~= 'number' or coord.takeover_threshold < 0) then
      table.insert(errors, "Invalid sync.coordination.takeover_threshold: " .. tostring(coord.takeover_threshold))
    end
    
    if coord.sync_cooldown and (type(coord.sync_cooldown) ~= 'number' or coord.sync_cooldown < 0) then
      table.insert(errors, "Invalid sync.coordination.sync_cooldown: " .. tostring(coord.sync_cooldown))
    end
  end
  
  return errors
end

-- Validate UI settings
function validators.validate_ui(config)
  local errors = {}
  
  if not config.ui then
    return errors
  end
  
  local ui = config.ui
  
  -- Validate sidebar settings
  if ui.sidebar then
    if ui.sidebar.width and (type(ui.sidebar.width) ~= 'number' or ui.sidebar.width < 10) then
      table.insert(errors, "Invalid ui.sidebar.width: " .. tostring(ui.sidebar.width))
    end
    
    if ui.sidebar.position and ui.sidebar.position ~= 'left' and ui.sidebar.position ~= 'right' then
      table.insert(errors, "Invalid ui.sidebar.position: " .. ui.sidebar.position)
    end
  end
  
  -- Validate email list settings
  if ui.email_list then
    if ui.email_list.page_size and (type(ui.email_list.page_size) ~= 'number' or ui.email_list.page_size < 1) then
      table.insert(errors, "Invalid ui.email_list.page_size: " .. tostring(ui.email_list.page_size))
    end
    
    if ui.email_list.preview_lines and (type(ui.email_list.preview_lines) ~= 'number' or ui.email_list.preview_lines < 0) then
      table.insert(errors, "Invalid ui.email_list.preview_lines: " .. tostring(ui.email_list.preview_lines))
    end
  end
  
  -- Validate preview settings
  if ui.preview then
    if ui.preview.position and not vim.tbl_contains({'right', 'bottom', 'float'}, ui.preview.position) then
      table.insert(errors, "Invalid ui.preview.position: " .. ui.preview.position)
    end
    
    if ui.preview.width and (type(ui.preview.width) ~= 'number' or ui.preview.width < 10) then
      table.insert(errors, "Invalid ui.preview.width: " .. tostring(ui.preview.width))
    end
    
    if ui.preview.height and (type(ui.preview.height) ~= 'number' or ui.preview.height < 5) then
      table.insert(errors, "Invalid ui.preview.height: " .. tostring(ui.preview.height))
    end
  end
  
  return errors
end

-- Main validation function
function M.validate(config)
  local all_errors = {}
  
  -- Run all validators
  local validation_results = {
    accounts = validators.validate_accounts(config),
    binaries = validators.validate_binaries(config),
    drafts = validators.validate_draft_config(config),
    sync = validators.validate_sync(config),
    ui = validators.validate_ui(config)
  }
  
  -- Collect all errors
  for category, errors in pairs(validation_results) do
    for _, error in ipairs(errors) do
      table.insert(all_errors, error)
    end
  end
  
  -- Log validation results
  if #all_errors > 0 then
    logger.error('Configuration validation failed', { 
      error_count = #all_errors,
      errors = all_errors
    })
    
    -- Show user notification for critical errors (not in test mode)
    if not _G.HIMALAYA_TEST_MODE then
      notify.himalaya(
        string.format('Configuration errors: %d issues found', #all_errors),
        notify.categories.ERROR
      )
    end
  else
    logger.info('Configuration validation passed')
  end
  
  return #all_errors == 0, all_errors
end

-- Migrate old configuration format to new format
function M.migrate(old_config)
  local new_config = vim.deepcopy(old_config)
  local migrations_applied = {}
  
  -- Migration: Move OAuth settings from accounts to oauth module format
  if new_config.accounts then
    for name, account in pairs(new_config.accounts) do
      if account.oauth_client_id_env then
        -- Old format detected
        if not account.oauth then
          account.oauth = {}
        end
        account.oauth.client_id_env = account.oauth_client_id_env
        account.oauth_client_id_env = nil
        table.insert(migrations_applied, "Migrated oauth_client_id_env for " .. name)
      end
      
      if account.oauth_client_secret_env then
        if not account.oauth then
          account.oauth = {}
        end
        account.oauth.client_secret_env = account.oauth_client_secret_env
        account.oauth_client_secret_env = nil
        table.insert(migrations_applied, "Migrated oauth_client_secret_env for " .. name)
      end
    end
  end
  
  -- Migration: Ensure maildir paths have trailing slash
  if new_config.accounts then
    for name, account in pairs(new_config.accounts) do
      if account.maildir_path and not account.maildir_path:match("/$") then
        account.maildir_path = account.maildir_path .. "/"
        table.insert(migrations_applied, "Added trailing slash to maildir_path for " .. name)
      end
    end
  end
  
  -- Log migrations
  if #migrations_applied > 0 then
    logger.info('Configuration migrations applied', {
      count = #migrations_applied,
      migrations = migrations_applied
    })
  end
  
  return new_config, migrations_applied
end

-- Check if configuration needs migration
function M.needs_migration(config)
  -- Check for old OAuth format
  if config.accounts then
    for _, account in pairs(config.accounts) do
      if account.oauth_client_id_env or account.oauth_client_secret_env then
        return true
      end
      
      -- Check for missing trailing slash
      if account.maildir_path and not account.maildir_path:match("/$") then
        return true
      end
    end
  end
  
  return false
end

-- Export validators for internal use
M._internal_validators = validators

return M