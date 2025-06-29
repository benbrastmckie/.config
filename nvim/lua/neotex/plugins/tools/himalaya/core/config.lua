-- Unified configuration module
-- Single source of truth for all Himalaya settings

local M = {}

-- Default configuration
M.defaults = {
  -- Account settings
  accounts = {
    gmail = {
      -- Email address
      email = nil, -- Will be auto-detected from himalaya config
      
      -- Maildir settings (discovered requirements)
      maildir_path = "~/Mail/Gmail/", -- Trailing slash REQUIRED for Maildir++
      
      -- Folder name mapping (IMAP -> Local)
      folder_map = {
        ["INBOX"] = "INBOX",
        ["[Gmail]/All Mail"] = "All_Mail",
        ["[Gmail]/Sent Mail"] = "Sent", 
        ["[Gmail]/Drafts"] = "Drafts",
        ["[Gmail]/Trash"] = "Trash",
        ["[Gmail]/Spam"] = "Spam",
        ["[Gmail]/Starred"] = "Starred",
        ["[Gmail]/Important"] = "Important",
      },
      
      -- Reverse mapping for operations (Local -> IMAP)
      local_to_imap = {
        ["All_Mail"] = "[Gmail]/All Mail",
        ["Sent"] = "[Gmail]/Sent Mail",
        ["Drafts"] = "[Gmail]/Drafts",
        ["Trash"] = "[Gmail]/Trash",
        ["Spam"] = "[Gmail]/Spam",
        ["Starred"] = "[Gmail]/Starred",
        ["Important"] = "[Gmail]/Important",
      },
      
      -- OAuth settings
      oauth = {
        client_id_env = "GMAIL_CLIENT_ID",
        client_secret_env = "GMAIL_CLIENT_SECRET",
        refresh_command = "refresh-gmail-oauth2",
        configure_command = "himalaya account configure gmail",
      },
      
      -- mbsync channel names
      mbsync = {
        inbox_channel = "gmail-inbox",
        all_channel = "gmail",
      }
    }
  },
  
  -- Sync settings
  sync = {
    -- Process locking
    lock_timeout = 300, -- 5 minutes
    lock_directory = "/tmp",
    
    -- OAuth behavior
    auto_refresh_oauth = true,
    oauth_refresh_cooldown = 300, -- 5 minutes
    
    -- Sync behavior
    auto_sync_on_open = false, -- Prevent race conditions
    sync_on_folder_change = false,
    
    -- Notifications
    show_progress = true,
    notify_on_complete = true,
    notify_on_error = true,
  },
  
  -- UI settings
  ui = {
    -- Sidebar
    sidebar = {
      width = 40,
      position = 'left',
      show_icons = true,
      relative_dates = true,
    },
    
    -- Email list
    email_list = {
      page_size = 30,
      preview_lines = 2,
      date_format = '%Y-%m-%d %H:%M',
    },
    
    -- Progress display
    show_simple_progress = true, -- Just "Syncing..." instead of complex progress
    
    -- Auto-refresh
    auto_refresh_interval = 0, -- Disabled to prevent issues
  },
  
  -- Binary paths
  binaries = {
    himalaya = "himalaya",
    mbsync = "mbsync", 
    flock = "flock",
  },
  
  -- Setup wizard
  setup = {
    auto_run = true, -- Run setup wizard on first use
    check_health_on_startup = true,
  },
  
  -- Debug settings
  debug = {
    verbose_sync = false,
    log_oauth = false,
  }
}

-- Current configuration (merged with defaults)
M.config = vim.deepcopy(M.defaults)

-- Current state
M.current_account = 'gmail'
M.initialized = false

-- Setup function
function M.setup(opts)
  -- Merge user options with defaults
  M.config = vim.tbl_deep_extend('force', M.defaults, opts or {})
  
  -- Validate configuration
  local issues = M.validate()
  if #issues > 0 then
    local logger = require('neotex.plugins.tools.himalaya.core.logger')
    logger.warn('Configuration issues detected:')
    for _, issue in ipairs(issues) do
      logger.warn('  - ' .. issue.message)
    end
  end
  
  M.initialized = true
  return M.config
end

-- Validate configuration
function M.validate()
  local issues = {}
  
  -- Check account settings
  for name, account in pairs(M.config.accounts) do
    -- Check maildir path has trailing slash
    if account.maildir_path and not account.maildir_path:match('/$') then
      table.insert(issues, {
        level = 'error',
        message = name .. ': maildir_path must end with trailing slash for Maildir++ format',
        fix = 'Add trailing slash to maildir_path'
      })
    end
    
    -- Check folder mappings are consistent
    for imap, local_name in pairs(account.folder_map or {}) do
      if account.local_to_imap and account.local_to_imap[local_name] ~= imap then
        table.insert(issues, {
          level = 'warning',
          message = name .. ': inconsistent folder mapping for ' .. imap,
          fix = 'Check folder_map and local_to_imap consistency'
        })
      end
    end
  end
  
  -- Check binary paths
  for name, path in pairs(M.config.binaries) do
    if vim.fn.executable(path) == 0 then
      table.insert(issues, {
        level = 'error',
        message = 'Binary not found: ' .. name .. ' (' .. path .. ')',
        fix = 'Install ' .. name .. ' or update binaries config'
      })
    end
  end
  
  return issues
end

-- Get current account configuration
function M.get_current_account()
  return M.config.accounts[M.current_account]
end

-- Get current account name
function M.get_current_account_name()
  return M.current_account
end

-- Get account by name
function M.get_account(name)
  return M.config.accounts[name]
end

-- Switch account
function M.switch_account(name)
  if M.config.accounts[name] then
    M.current_account = name
    return true
  end
  return false
end

-- Get folder mapping (IMAP -> Local)
function M.get_local_folder_name(imap_name, account_name)
  local account = M.get_account(account_name)
  if account and account.folder_map then
    return account.folder_map[imap_name] or imap_name
  end
  return imap_name
end

-- Get reverse folder mapping (Local -> IMAP)
function M.get_imap_folder_name(local_name, account_name)
  local account = M.get_account(account_name)
  if account and account.local_to_imap then
    return account.local_to_imap[local_name] or local_name
  end
  return local_name
end

-- Get maildir path for current account
function M.get_maildir_path(account_name)
  local account = M.get_account(account_name)
  if account then
    return vim.fn.expand(account.maildir_path)
  end
  return nil
end

-- Check if configuration is initialized
function M.is_initialized()
  return M.initialized
end

-- Get config value by path (e.g., "sync.auto_refresh_oauth")
function M.get(path, default)
  local value = M.config
  for part in path:gmatch("[^.]+") do
    if type(value) ~= "table" then
      return default
    end
    value = value[part]
  end
  return value ~= nil and value or default
end

return M