-- Unified Configuration Module
-- Facade that provides backward compatibility while delegating to specialized modules

local M = {}

-- Sub-modules
local accounts = require('neotex.plugins.tools.himalaya.config.accounts')
local folders = require('neotex.plugins.tools.himalaya.config.folders')
local oauth = require('neotex.plugins.tools.himalaya.config.oauth')
local ui = require('neotex.plugins.tools.himalaya.config.ui')
local validation = require('neotex.plugins.tools.himalaya.config.validation')

-- Logger
local logger = require('neotex.plugins.tools.himalaya.core.logger')

-- Default configuration that doesn't fit into sub-modules
M.defaults = {
  -- Account settings (merged from sub-modules)
  accounts = accounts.defaults,
  
  -- Sync settings (for backward compatibility)
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
    
    -- Multi-instance coordination
    coordination = {
      enabled = true,              -- Enable cross-instance coordination
      heartbeat_interval = 30,     -- Seconds between heartbeats
      takeover_threshold = 60,     -- Seconds before considering primary dead
      sync_cooldown = 300,         -- Minimum seconds between syncs (5 minutes)
    },
    
    -- Maildir root (if not specified per-account)
    maildir_root = nil,
  },
  
  -- UI settings (merged from ui module)
  ui = ui.defaults,
  
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
  
  -- Email preview settings (kept here for backward compatibility)
  preview = {
    enabled = true,
    delay_ms = 500,
    width = 40,
    position = 'right', -- 'right' or 'bottom'
    show_headers = true,
    max_lines = 50,
  },
  
  -- Email composition settings (kept here for backward compatibility)
  compose = {
    use_tab = true,  -- Open in current window (false = vsplit)
    auto_save_interval = 30,
    delete_draft_on_send = true,
    syntax_highlighting = true,
    draft_dir = vim.fn.expand('~/.local/share/himalaya/drafts/'),
    save_sent_copy = false,  -- Disable manual saving to Sent
  },
  
  -- Confirmation dialog settings
  confirmations = {
    style = 'modern', -- 'modern' or 'classic'
    default_to_cancel = true,
  },
  
  -- Notification settings
  notifications = {
    show_routine_operations = false,
  },
  
  -- Contacts settings
  contacts = {
    enabled = false,
    cache_ttl = 86400, -- 24 hours
    min_interactions = 3,
  },

  -- Threading settings (Task #81)
  threading = {
    enabled = true,           -- Enable thread grouping by default
    default_collapsed = true, -- Start with threads collapsed
    show_count = true,        -- Show thread count indicator [N]
  },

  -- Draft system configuration (Phase 5)
  drafts = {
    storage = {
      type = 'maildir',  -- 'maildir' or 'local'
      base_dir = vim.fn.expand('~/.local/share/nvim/himalaya/drafts'),
      local_dir = vim.fn.expand('~/.local/share/nvim/himalaya/drafts/'),
      format = 'json',
      compression = false,
    },
    sync = {
      enabled = true,
      auto_sync = true,
      sync_interval = 300,    -- Sync interval in seconds (5 minutes)
      interval = 300,         -- Alias for backward compatibility
      on_save = true,         -- Sync immediately when saving
      on_open = true,         -- Sync when opening draft manager
      retry_attempts = 3,
    },
    recovery = {
      enabled = true,
      check_on_startup = true,
      max_age_days = 7,
      backup_count = 5,
      auto_recover = true,
    },
    ui = {
      show_status_line = true,
      confirm_delete = true,
      auto_save_delay = 30000, -- 30 seconds (in milliseconds)
    },
    integration = {
      use_window_stack = true,
      emit_events = true,
      use_notifications = true,
    }
  },
}

-- Current configuration (merged with defaults)
M.config = vim.deepcopy(M.defaults)

-- Module state
M.initialized = false

-- Setup function
function M.setup(opts)
  -- Apply any migrations if needed
  if opts and validation.needs_migration(opts) then
    opts = validation.migrate(opts)
  end
  
  -- Merge user options with defaults
  M.config = vim.tbl_deep_extend('force', M.defaults, opts or {})
  
  -- Initialize sub-modules
  accounts.init(M.config)
  folders.init(M.config)
  oauth.init(M.config)
  ui.init(M.config)
  
  -- Validate configuration with test mode check
  local valid, errors = validation.validate(M.config, { test_validation = _G.HIMALAYA_TEST_MODE })
  if not valid then
    logger.warn('Configuration validation failed', { errors = errors })
  end
  
  M.initialized = true
  logger.info('Configuration initialized')
  
  return M.config
end

-- Validate configuration (delegate to validation module)
function M.validate()
  return validation.validate(M.config, { test_validation = _G.HIMALAYA_TEST_MODE })
end

-- Validate draft configuration (backward compatibility)
function M.validate_draft_config(config)
  if not config.drafts then
    return true, {}
  end
  
  -- Use the validators from validation module directly
  local validators = validation._internal_validators or {}
  if validators.validate_draft_config then
    local errors = validators.validate_draft_config(config)
    return #errors == 0, errors
  end
  
  -- Fallback: validate the whole config with test flag if in test mode
  local valid, all_errors = validation.validate(config, { test_validation = _G.HIMALAYA_TEST_MODE })
  
  -- Filter for draft-related errors
  local draft_errors = {}
  for _, err in ipairs(all_errors) do
    if err:match('draft') or err:match('Draft') then
      table.insert(draft_errors, err)
    end
  end
  
  return #draft_errors == 0, draft_errors
end

-- Account management functions (delegate to accounts module)
function M.get_current_account()
  return accounts.get_current_account()
end

function M.get_account_email(account_name)
  return accounts.get_account_email(account_name)
end

function M.get_account_display_name(account_name)
  return accounts.get_account_display_name(account_name)
end

function M.get_formatted_from(account_name)
  return accounts.get_formatted_from(account_name)
end

function M.get_current_account_name()
  return accounts.get_current_account_name()
end

function M.get_account(name)
  return accounts.get_account(name)
end

function M.switch_account(name)
  return accounts.switch_account(name)
end

-- Folder management functions (delegate to folders module)
function M.get_local_folder_name(imap_name, account_name)
  return folders.get_local_folder_name(imap_name, account_name)
end

function M.get_imap_folder_name(local_name, account_name)
  return folders.get_imap_folder_name(local_name, account_name)
end

function M.get_maildir_path(account_name)
  return folders.get_maildir_path(account_name)
end

-- Check if initialized
function M.is_initialized()
  return M.initialized
end

-- Get configuration value by path
function M.get(path, default)
  local value = M.config
  for segment in path:gmatch('[^.]+') do
    if type(value) ~= 'table' then
      return default
    end
    value = value[segment]
  end
  return value ~= nil and value or default
end

-- Setup buffer keymaps (delegate to ui module)
function M.setup_buffer_keymaps(bufnr)
  return ui.setup_buffer_keymaps(bufnr)
end

-- Export sub-modules for direct access if needed
M.accounts = accounts
M.folders = folders
M.oauth = oauth
M.ui = ui
M.validation = validation

-- For backward compatibility, also expose current_account directly
M.current_account = function()
  return accounts.get_current_account_name()
end

return M