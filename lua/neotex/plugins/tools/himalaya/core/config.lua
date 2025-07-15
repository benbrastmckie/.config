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
        ["INBOX"] = "INBOX",
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
    
    -- Multi-instance coordination
    coordination = {
      enabled = true,              -- Enable cross-instance coordination
      heartbeat_interval = 30,     -- Seconds between heartbeats
      takeover_threshold = 60,     -- Seconds before considering primary dead
      sync_cooldown = 300,         -- Minimum seconds between syncs (5 minutes)
    },
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
    
    -- Auto-sync settings
    auto_sync_enabled = true, -- Enable automatic inbox syncing
    auto_sync_interval = 15 * 60, -- 15 minutes in seconds
    auto_sync_startup_delay = 2, -- 2 seconds delay after startup
    
    -- Multi-account view settings
    multi_account = {
      default_mode = 'focused', -- 'focused', 'unified', 'split', 'tabbed'
      unified_sort = 'date', -- 'date', 'account', 'subject'
      show_account_colors = true,
      account_abbreviation_length = 3,
    },
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
  
  -- Debug mode is now controlled by the notification system
  -- Use <leader>ad to toggle debug mode
  
  -- Email preview settings
  preview = {
    enabled = true,
    delay_ms = 500,
    width = 40,
    position = 'right', -- 'right' or 'bottom'
    show_headers = true,
    max_lines = 50,
  },
  
  -- Email composition settings
  compose = {
    use_tab = true,  -- Open in current window (false = vsplit)
    auto_save_interval = 30,
    delete_draft_on_send = true,
    syntax_highlighting = true,
    draft_dir = vim.fn.expand('~/.local/share/himalaya/drafts/'),
    save_sent_copy = false,  -- Disable manual saving to Sent (providers usually do this automatically)
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
    auto_scan = false, -- Disabled by default to avoid startup errors
    scan_folders = {'INBOX'}, -- Only scan INBOX by default
  },
  
  -- Draft system configuration (Phase 5)
  draft = {
    -- Storage settings
    storage = {
      base_dir = vim.fn.stdpath('data') .. '/himalaya/drafts',
      format = 'json', -- 'json' or 'eml'
      compression = false,
    },
    
    -- Sync settings
    sync = {
      auto_sync = true,
      sync_interval = 300, -- 5 minutes (in seconds)
      sync_on_save = true,
      retry_attempts = 3,
      retry_delay = 5000, -- milliseconds
    },
    
    -- Recovery settings
    recovery = {
      enabled = true,
      check_on_startup = true,
      max_age_days = 7,
      backup_unsaved = true,
    },
    
    -- UI settings
    ui = {
      show_status_line = true,
      confirm_delete = true,
      auto_save_delay = 30000, -- 30 seconds (in milliseconds)
    },
    
    -- Integration settings
    integration = {
      use_window_stack = true,
      emit_events = true,
      use_notifications = true,
    }
  },
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
  
  -- Validate draft configuration (Phase 5)
  if M.config.draft then
    local draft = M.config.draft
    
    -- Validate storage settings
    if draft.storage then
      if type(draft.storage.base_dir) ~= 'string' then
        table.insert(issues, {
          level = 'error',
          message = 'draft.storage.base_dir must be a string',
          fix = 'Set draft.storage.base_dir to a valid directory path'
        })
      end
      
      if draft.storage.format and draft.storage.format ~= 'json' and draft.storage.format ~= 'eml' then
        table.insert(issues, {
          level = 'error',
          message = "draft.storage.format must be 'json' or 'eml'",
          fix = "Set draft.storage.format to 'json' or 'eml'"
        })
      end
    end
    
    -- Validate sync settings
    if draft.sync then
      if type(draft.sync.sync_interval) ~= 'number' or draft.sync.sync_interval <= 0 then
        table.insert(issues, {
          level = 'error',
          message = 'draft.sync.sync_interval must be a positive number',
          fix = 'Set draft.sync.sync_interval to a positive number (seconds)'
        })
      end
      
      if type(draft.sync.retry_attempts) ~= 'number' or draft.sync.retry_attempts < 0 then
        table.insert(issues, {
          level = 'warning',
          message = 'draft.sync.retry_attempts should be a non-negative number',
          fix = 'Set draft.sync.retry_attempts to 0 or higher'
        })
      end
    end
    
    -- Validate recovery settings
    if draft.recovery then
      if type(draft.recovery.max_age_days) ~= 'number' or draft.recovery.max_age_days <= 0 then
        table.insert(issues, {
          level = 'warning',
          message = 'draft.recovery.max_age_days should be a positive number',
          fix = 'Set draft.recovery.max_age_days to a positive number'
        })
      end
    end
    
    -- Validate UI settings
    if draft.ui then
      if type(draft.ui.auto_save_delay) ~= 'number' or draft.ui.auto_save_delay < 0 then
        table.insert(issues, {
          level = 'warning',
          message = 'draft.ui.auto_save_delay should be a non-negative number',
          fix = 'Set draft.ui.auto_save_delay to 0 or higher (milliseconds)'
        })
      end
    end
  end
  
  return issues
end

-- Validate draft configuration (Phase 5)
function M.validate_draft_config(config)
  local draft = config.draft or {}
  local issues = {}
  
  -- Validate storage settings
  if draft.storage then
    if type(draft.storage.base_dir) ~= 'string' then
      return false, "draft.storage.base_dir must be a string"
    end
    
    if draft.storage.format ~= nil and draft.storage.format ~= 'json' and draft.storage.format ~= 'eml' then
      return false, "draft.storage.format must be 'json' or 'eml'"
    end
  end
  
  -- Validate sync settings
  if draft.sync then
    if type(draft.sync.sync_interval) ~= 'number' or draft.sync.sync_interval <= 0 then
      return false, "draft.sync.sync_interval must be a positive number"
    end
    
    if draft.sync.retry_attempts ~= nil and (type(draft.sync.retry_attempts) ~= 'number' or draft.sync.retry_attempts < 0) then
      return false, "draft.sync.retry_attempts must be a non-negative number"
    end
    
    if draft.sync.retry_delay ~= nil and (type(draft.sync.retry_delay) ~= 'number' or draft.sync.retry_delay < 0) then
      return false, "draft.sync.retry_delay must be a non-negative number"
    end
  end
  
  -- Validate recovery settings
  if draft.recovery then
    if draft.recovery.max_age_days ~= nil and (type(draft.recovery.max_age_days) ~= 'number' or draft.recovery.max_age_days <= 0) then
      return false, "draft.recovery.max_age_days must be a positive number"
    end
  end
  
  -- Validate UI settings
  if draft.ui then
    if draft.ui.auto_save_delay ~= nil and (type(draft.ui.auto_save_delay) ~= 'number' or draft.ui.auto_save_delay < 0) then
      return false, "draft.ui.auto_save_delay must be a non-negative number"
    end
  end
  
  return true
end

-- Get current account configuration
function M.get_current_account()
  return M.config.accounts[M.current_account]
end

-- Auto-detect email address from himalaya config
function M.get_account_email(account_name)
  account_name = account_name or M.current_account
  local account = M.config.accounts[account_name]
  
  -- If email is already configured, return it
  if account and account.email then
    return account.email
  end
  
  -- Try to read email from himalaya config file
  local config_file = vim.fn.expand('~/.config/himalaya/config.toml')
  if vim.fn.filereadable(config_file) == 1 then
    local handle = io.open(config_file, 'r')
    if handle then
      local content = handle:read('*a')
      handle:close()
      
      -- Look for the account section and email field
      local pattern = '%[accounts%.' .. account_name .. '%].-email%s*=%s*["\']([^"\']+)["\']'
      local email = content:match(pattern)
      
      if email then
        -- Cache the email in the config
        if account then
          account.email = email
        end
        return email
      end
    end
  end
  
  -- Fallback: if account name looks like an email, use it
  if account_name and account_name:match('@') then
    if account then
      account.email = account_name
    end
    return account_name
  end
  
  return nil
end

-- Get account display name from himalaya config
function M.get_account_display_name(account_name)
  account_name = account_name or M.current_account
  local account = M.config.accounts[account_name]
  
  -- If display_name is already configured, return it
  if account and account.display_name then
    return account.display_name
  end
  
  -- Try to read display-name from himalaya config file
  local config_file = vim.fn.expand('~/.config/himalaya/config.toml')
  if vim.fn.filereadable(config_file) == 1 then
    local handle = io.open(config_file, 'r')
    if handle then
      local content = handle:read('*a')
      handle:close()
      
      -- Look for the account section and display-name field
      local pattern = '%[accounts%.' .. account_name .. '%].-display%-name%s*=%s*["\']([^"\']+)["\']'
      local display_name = content:match(pattern)
      
      if display_name then
        -- Cache the display name in the config
        if account then
          account.display_name = display_name
        end
        return display_name
      end
    end
  end
  
  -- No display name found
  return nil
end

-- Get formatted From header (with display name if available)
function M.get_formatted_from(account_name)
  account_name = account_name or M.current_account
  local email = M.get_account_email(account_name)
  if not email then
    return ''
  end
  
  local display_name = M.get_account_display_name(account_name)
  if display_name then
    return string.format('%s <%s>', display_name, email)
  else
    return email
  end
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

-- Setup buffer-specific keymaps
function M.setup_buffer_keymaps(bufnr)
  local keymap = vim.keymap.set
  local opts = { buffer = bufnr, silent = true }
  
  -- Disable tab cycling in all Himalaya buffers
  keymap('n', '<Tab>', '<Nop>', opts)
  keymap('n', '<S-Tab>', '<Nop>', opts)
  keymap('i', '<Tab>', '<Tab>', opts)  -- Keep normal tab in insert mode
  keymap('i', '<S-Tab>', '<S-Tab>', opts)  -- Keep shift-tab in insert mode
  
  -- Email list keymaps
  if vim.bo[bufnr].filetype == 'himalaya-list' then
    keymap('n', '<CR>', function()
      local line = vim.api.nvim_win_get_cursor(0)[1]
      local state = require('neotex.plugins.tools.himalaya.core.state')
      local line_map = state.get('email_list.line_map')
      
      -- Check if this is a scheduled email
      local metadata = line_map and line_map[line]
      if metadata and metadata.type == 'scheduled' then
        -- For scheduled emails, open reschedule picker
        local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
        scheduler.show_reschedule_picker(metadata.id)
        return
      end
      
      -- Check if current email is a draft
      local email_list = require('neotex.plugins.tools.himalaya.ui.email_list')
      local email_id = email_list.get_email_id_from_line(line)
      
      if not email_id then
        -- No email on this line (could be header, separator, etc.)
        return
      end
      
      -- Validate email_id is not a folder name
      local state = require('neotex.plugins.tools.himalaya.core.state')
      if type(email_id) == 'string' and email_id == state.get_current_folder() then
        local notify = require('neotex.util.notifications')
        notify.himalaya('Cannot open header line as email', notify.categories.ERROR)
        return
      end
      
      -- Get email metadata to check if it's a draft
      local lines_obj = email_list.get_current_lines()
      local email_metadata = lines_obj and lines_obj.metadata and lines_obj.metadata[line]
      
      -- Handle vim.NIL case
      if email_metadata == vim.NIL then
        email_metadata = nil
      end
      
      if email_metadata and type(email_metadata) == 'table' and email_metadata.is_draft then
        -- Draft-specific handling
        local preview = require('neotex.plugins.tools.himalaya.ui.email_preview')
        
        -- Check if this is a local-only draft
        local emails = state.get('email_list.emails')
        local email = emails and emails[email_metadata.email_index]
        local is_local_draft = email_metadata.is_local or (email and email.is_local)
        
        if not preview.is_preview_mode() then
          -- First return: show preview
          preview.enable_preview_mode()
          preview.show_preview(email_id, vim.api.nvim_get_current_win(), 'draft', is_local_draft and email.local_id or nil)
        else
          -- Second return: open for editing
          local composer = require('neotex.plugins.tools.himalaya.ui.email_composer_wrapper')
          -- Debug log before calling reopen_draft
          local logger = require('neotex.plugins.tools.himalaya.core.logger')
          logger.debug('About to call open_draft', {
            email_id = email_id,
            is_local = is_local_draft,
            local_id = is_local_draft and email.local_id or nil,
            type = type(email_id),
            line = line,
            current_line = vim.fn.getline('.')
          })
          
          -- Disable preview mode when opening draft for editing
          preview.disable_preview_mode()
          
          if is_local_draft then
            -- Get local_id from email or from the email_id if it's already a local ID
            local local_id = nil
            if email and email.local_id then
              local_id = email.local_id
            elseif email_id and tostring(email_id):match('^draft_%d+_') then
              local_id = email_id
            end
            
            if local_id then
              logger.debug('Opening local draft', { local_id = local_id })
              composer.open_local_draft(local_id, state.get_current_account())
            else
              logger.error('Local draft missing local_id', { email_id = email_id })
              local notify = require('neotex.util.notifications')
              notify.himalaya('Failed to open local draft - missing ID', notify.categories.ERROR)
            end
          else
            -- Open remote draft
            composer.open_draft(email_id, state.get_current_account())
          end
        end
      else
        -- Regular email handling
        local preview = require('neotex.plugins.tools.himalaya.ui.email_preview')
        
        -- First CR: Enable preview mode and show preview for current email
        if not preview.is_preview_mode() then
          preview.enable_preview_mode()
          -- Show preview for current email immediately
          preview.show_preview(email_id, vim.api.nvim_get_current_win())
        -- Second CR: Focus the preview if it's showing
        elseif preview.is_preview_shown() then
          local focused = preview.focus_preview()
          if not focused then
            -- If focus failed, try showing the preview again
            preview.show_preview(email_id, vim.api.nvim_get_current_win())
          end
        else
          -- Preview mode is on but no preview shown, show it
          preview.show_preview(email_id, vim.api.nvim_get_current_win())
        end
      end
    end, vim.tbl_extend('force', opts, { desc = 'Toggle preview mode / Focus preview / Reschedule / Open draft' }))
    
    -- ESC to exit preview mode
    keymap('n', '<Esc>', function()
      local state = require('neotex.plugins.tools.himalaya.core.state')
      local preview = require('neotex.plugins.tools.himalaya.ui.email_preview')
      local notify = require('neotex.util.notifications')
      
      -- Check if we have selections first
      local selection_count = state.get_selection_count()
      if selection_count > 0 then
        -- Clear all selections
        state.clear_selection()
        
        -- Fast update display to show cleared selections
        local email_list = require('neotex.plugins.tools.himalaya.ui.email_list')
        email_list.update_selection_display()
        
        -- Show feedback
        notify.himalaya(string.format('Cleared %d selections', selection_count), notify.categories.STATUS)
      elseif preview.is_preview_mode() then
        -- No selections, handle preview mode
        preview.disable_preview_mode()
      end
    end, vim.tbl_extend('force', opts, { desc = 'Clear selections / Exit preview mode' }))
    
    -- Removed 'c' mapping - use 'gw' to compose/write email
    -- Removed 'r' mapping - use 'gs' for sync which includes refresh
    
    -- Override 'g' to handle our custom g-commands immediately
    keymap('n', 'g', function()
      local state = require('neotex.plugins.tools.himalaya.core.state')
      local char = vim.fn.getchar()
      local key = vim.fn.nr2char(char)
      
      -- Check if we have selections for batch operations
      local selected_count = state.get_selection_count()
      local has_selection = selected_count > 0
      
      if key == 'n' then
        require('neotex.plugins.tools.himalaya.ui.main').next_page()
      elseif key == 'p' then
        require('neotex.plugins.tools.himalaya.ui.main').prev_page()
      elseif key == 'm' then
        require('neotex.plugins.tools.himalaya.ui.main').pick_folder()
      elseif key == 'a' then
        require('neotex.plugins.tools.himalaya.ui.main').pick_account()
      elseif key == 'r' then
        require('neotex.plugins.tools.himalaya.ui.main').reply_current_email()
      elseif key == 'R' then
        require('neotex.plugins.tools.himalaya.ui.main').reply_all_current_email()
      elseif key == 'f' then
        require('neotex.plugins.tools.himalaya.ui.main').forward_current_email()
      elseif key == 's' then
        require('neotex.plugins.tools.himalaya.ui.main').sync_current_folder()
      elseif key == 'D' then
        -- Check if current line is a scheduled email
        local line = vim.api.nvim_win_get_cursor(0)[1]
        local metadata = require('neotex.plugins.tools.himalaya.core.state').get('email_list.line_map') or {}
        local line_data = metadata[line]
        
        if line_data and line_data.type == 'scheduled' then
          -- Cancel/delete scheduled email
          local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
          local queue_item = scheduler.get_queue_item(line_data.id)
          
          if queue_item and (queue_item.status == 'scheduled' or queue_item.status == 'paused') then
            -- For both scheduled and paused emails, remove them
            scheduler.remove_from_queue(line_data.id)
          else
            -- Fallback to cancel_send for backwards compatibility
            scheduler.cancel_send(line_data.id)
          end
        elseif has_selection then
          require('neotex.plugins.tools.himalaya.ui.main').delete_selected_emails()
        else
          require('neotex.plugins.tools.himalaya.ui.main').delete_current_email()
        end
      elseif key == 'A' then
        if has_selection then
          require('neotex.plugins.tools.himalaya.ui.main').archive_selected_emails()
        else
          require('neotex.plugins.tools.himalaya.ui.main').archive_current_email()
        end
      elseif key == 'S' then
        if has_selection then
          require('neotex.plugins.tools.himalaya.ui.main').spam_selected_emails()
        else
          require('neotex.plugins.tools.himalaya.ui.main').spam_current_email()
        end
      elseif key == 'M' then
        -- Move email to another folder
        if has_selection then
          require('neotex.plugins.tools.himalaya.ui.main').move_selected_emails()
        else
          require('neotex.plugins.tools.himalaya.ui.main').move_current_email()
        end
      elseif key == 'H' then
        -- Check if we're in drafts folder
        local current_folder = state.get_current_folder()
        local notify = require('neotex.util.notifications')
        
        -- Debug logging
        if notify.config.modules.himalaya.debug_mode then
          notify.himalaya('gH pressed, current folder: ' .. tostring(current_folder), notify.categories.BACKGROUND)
        end
        
        -- Show context-aware help based on current folder type
        local folder_help = require('neotex.plugins.tools.himalaya.ui.folder_help')
        folder_help.show_folder_help()
      else
        -- Pass through to built-in g commands
        vim.api.nvim_feedkeys('g' .. key, 'n', false)
      end
    end, vim.tbl_extend('force', opts, { desc = 'Himalaya g-commands' }))
    
    -- Add q to close Himalaya entirely from email list
    keymap('n', 'q', function()
      require('neotex.plugins.tools.himalaya.ui.main').close_himalaya()
    end, vim.tbl_extend('force', opts, { desc = 'Close Himalaya' }))
    
    
    -- Mouse click handler for sidebar
    vim.keymap.set('n', '<LeftMouse>', function()
      local mouse_pos = vim.fn.getmousepos()
      local preview = require('neotex.plugins.tools.himalaya.ui.email_preview')
      
      -- Handle clicks on preview window
      if preview.is_preview_shown() then
        local preview_win = preview.ensure_preview_window()
        if preview_win and mouse_pos.winid == preview_win then
          -- Focus preview window
          vim.g.himalaya_focusing_preview = true
          local preview_state = preview.get_preview_state()
          preview_state.is_focusing = true
          
          vim.schedule(function()
            if vim.api.nvim_win_is_valid(preview_win) then
              vim.api.nvim_set_current_win(preview_win)
              if mouse_pos.line > 0 and mouse_pos.column > 0 then
                pcall(vim.api.nvim_win_set_cursor, preview_win, {mouse_pos.line, math.max(0, mouse_pos.column - 1)})
              end
            end
          end)
          
          -- Clear flags
          vim.defer_fn(function()
            vim.g.himalaya_focusing_preview = false
            local preview_state = preview.get_preview_state()
            preview_state.is_focusing = false
          end, 200)
          
          return ''
        end
      end
      
      -- Handle clicks on sidebar
      local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
      local sidebar_win = sidebar.get_win()
      if mouse_pos.winid ~= sidebar_win then
        return '<LeftMouse>'
      end
      
      -- Update preview if in preview mode
      vim.schedule(function()
        if vim.g.himalaya_focusing_preview then
          return
        end
        
        if preview.is_preview_mode() then
          local main = require('neotex.plugins.tools.himalaya.ui.main')
          local email_id = main.get_current_email_id()
          local current_preview_id = preview.get_current_preview_id()
          
          if email_id and email_id ~= current_preview_id then
            -- Check if we're in drafts folder to determine email type
            local state = require('neotex.plugins.tools.himalaya.core.state')
            local folder = state.get_current_folder()
            local email_type = nil
            if folder and folder:lower():match('draft') then
              email_type = 'draft'
            end
            preview.show_preview(email_id, vim.api.nvim_get_current_win(), email_type)
          end
        end
      end)
      
      return '<LeftMouse>'
    end, vim.tbl_extend('force', opts, { desc = 'Handle mouse clicks', expr = true }))
    
    -- Debounced cursor movement handler for smooth j/k navigation
    local preview_timer = nil
    vim.api.nvim_create_autocmd('CursorMoved', {
      buffer = buf,
      callback = function()
        local preview = require('neotex.plugins.tools.himalaya.ui.email_preview')
        if not preview.is_preview_mode() then
          return
        end
        
        -- Don't update preview if we're focusing it
        if vim.g.himalaya_focusing_preview then
          return
        end
        
        -- Cancel previous timer
        if preview_timer then
          vim.fn.timer_stop(preview_timer)
        end
        
        -- Set new timer with minimal debounce for snappy response
        preview_timer = vim.fn.timer_start(50, function()
          local main = require('neotex.plugins.tools.himalaya.ui.main')
          local email_id = main.get_current_email_id()
          local current_preview_id = preview.get_current_preview_id()
          
          if email_id and email_id ~= current_preview_id then
            -- Check if we're in drafts folder to determine email type
            local state = require('neotex.plugins.tools.himalaya.core.state')
            local folder = state.get_current_folder()
            local email_type = nil
            if folder and folder:lower():match('draft') then
              email_type = 'draft'
            end
            preview.show_preview(email_id, vim.api.nvim_get_current_win(), email_type)
          end
          preview_timer = nil
        end)
      end
    })
    
    -- Select email and move down
    keymap('n', 'n', function()
      local state = require('neotex.plugins.tools.himalaya.core.state')
      local main = require('neotex.plugins.tools.himalaya.ui.main')
      local notify = require('neotex.util.notifications')
      
      local current_pos = vim.api.nvim_win_get_cursor(0)
      local current_line = current_pos[1]
      
      -- Use the line map for accurate email selection
      local line_map = state.get('email_list.line_map')
      local email_data = state.get('email_list.emails')
      
      -- Debug logging
      if notify.config.modules.himalaya.debug_mode then
        notify.himalaya('n key pressed on line ' .. current_line, notify.categories.BACKGROUND)
        local has_line_map = line_map ~= nil
        local has_line_info = line_map and line_map[current_line] ~= nil
        notify.himalaya('Line map exists: ' .. tostring(has_line_map) .. ', Line info exists: ' .. tostring(has_line_info), notify.categories.BACKGROUND)
      end
      
      if line_map and line_map[current_line] then
        local line_info = line_map[current_line]
        local email_idx = line_info.email_index
        local email = email_data and email_data[email_idx]
        
        if email then
          local email_id = email.id or tostring(email_idx)
          
          -- Debug logging
          if notify.config.modules.himalaya.debug_mode then
            notify.himalaya('Toggling selection for email ID: ' .. tostring(email_id), notify.categories.BACKGROUND)
          end
          
          -- Toggle selection on current line
          state.toggle_email_selection(email_id, email)
          
          -- Fast update display (no server calls)
          local email_list = require('neotex.plugins.tools.himalaya.ui.email_list')
          email_list.update_selection_display()
          
          -- Move cursor down after selection
          vim.schedule(function()
            vim.cmd('normal! j')
          end)
        else
          if notify.config.modules.himalaya.debug_mode then
            notify.himalaya('No email found at index ' .. tostring(email_idx), notify.categories.BACKGROUND)
          end
        end
      else
        -- If not on an email line, just move down
        vim.cmd('normal! j')
      end
    end, vim.tbl_extend('force', opts, { desc = 'Select/deselect email and move down' }))
    
    -- Select email and move up
    keymap('n', 'N', function()
      local state = require('neotex.plugins.tools.himalaya.core.state')
      local main = require('neotex.plugins.tools.himalaya.ui.main')
      
      local current_pos = vim.api.nvim_win_get_cursor(0)
      local current_line = current_pos[1]
      
      -- Use the line map for accurate email selection
      local line_map = state.get('email_list.line_map')
      local email_data = state.get('email_list.emails')
      
      if line_map and line_map[current_line] then
        local line_info = line_map[current_line]
        local email_idx = line_info.email_index
        local email = email_data and email_data[email_idx]
        
        if email then
          local email_id = email.id or tostring(email_idx)
          
          -- Toggle selection on current line
          state.toggle_email_selection(email_id, email)
          
          -- Fast update display (no server calls)
          local email_list = require('neotex.plugins.tools.himalaya.ui.email_list')
          email_list.update_selection_display()
          
          -- Move cursor up after selection
          vim.schedule(function()
            vim.cmd('normal! k')
          end)
        end
      else
        -- If not on an email line, just move up
        vim.cmd('normal! k')
      end
    end, vim.tbl_extend('force', opts, { desc = 'Select/deselect email and move up' }))
    
    -- Show help
    keymap('n', '?', function()
      local help_lines = {
        'Himalaya Email Client - Key Mappings',
        '',
        'Navigation:',
        '  j/k       - Move up/down',
        '  <CR>      - Enable preview mode / Focus preview',
        '  <Esc>     - Clear selections / Exit preview mode',
        '  q         - Close Himalaya',
        '  gs        - Sync current folder',
        '  gn/gp     - Next/previous page',
        '',
        'Selection:',
        '  n         - Select/deselect email and move down',
        '  N         - Select/deselect email and move up',
        '  <Esc>     - Clear all selections (or exit preview mode)',
        '',
        'Email Actions:',
        '  gw        - Write new email',
        '  gr        - Reply to current email',
        '  gR        - Reply all to current email',
        '  gf        - Forward current email',
        '  gD        - Delete (batch if selected)',
        '  gA        - Archive (batch if selected)',
        '  gS        - Spam (batch if selected)',
        '',
        'Folders & Accounts:',
        '  gm        - Change folder',
        '  ga        - Change account',
        '',
        'Colors:',
        '  Blue      - Unread emails',
        '  Orange    - Starred emails',
        '',
        'Checkboxes:',
        '  [ ]       - Not selected',
        '  [x]       - Selected for batch operations',
        '',
        'Preview Mode:',
        '  First <CR>  - Enable preview mode (hover shows previews)',
        '  Second <CR> - Focus the preview window',
        '  <Esc>       - Return to sidebar (keep preview mode)',
        '  q           - Close preview and exit preview mode',
        '',
        'Press any key to close help'
      }
      
      -- Create floating window for help
      local width = 50
      local height = #help_lines
      local buf = vim.api.nvim_create_buf(false, true)
      
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, help_lines)
      vim.api.nvim_buf_set_option(buf, 'modifiable', false)
      vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
      
      local win_opts = {
        relative = 'editor',
        width = width,
        height = height,
        col = math.floor((vim.o.columns - width) / 2),
        row = math.floor((vim.o.lines - height) / 2),
        style = 'minimal',
        border = 'rounded',
        title = ' Himalaya Help ',
        title_pos = 'center',
      }
      
      local win = vim.api.nvim_open_win(buf, true, win_opts)
      
      -- Close on any key press
      vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':close<CR>', { silent = true })
      vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':close<CR>', { silent = true })
      vim.api.nvim_create_autocmd('BufLeave', {
        buffer = buf,
        once = true,
        callback = function()
          if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
          end
        end
      })
    end, vim.tbl_extend('force', opts, { desc = 'Show help' }))
    
    
  end
  
  -- Email reading keymaps
  if vim.bo[bufnr].filetype == 'himalaya-email' then
    -- Add Return handler for drafts
    keymap('n', '<CR>', function()
      -- Check if this is a draft preview
      local preview = require('neotex.plugins.tools.himalaya.ui.email_preview')
      local preview_state = preview.get_preview_state()
      if preview_state and preview_state.email_id then
        -- Check if the current email is a draft
        local state = require('neotex.plugins.tools.himalaya.core.state')
        local email_cache = require('neotex.plugins.tools.himalaya.core.email_cache')
        local account = state.get_current_account()
        local folder = state.get_current_folder()
        local email = email_cache.get_email(account, folder, preview_state.email_id)
        
        if email and email._is_draft then
          -- Open draft for editing
          local composer = require('neotex.plugins.tools.himalaya.ui.email_composer_wrapper')
          logger.debug('Opening draft from preview', {
            email_id = preview_state.email_id,
            has_email = email ~= nil,
            is_draft = email._is_draft
          })
          composer.reopen_draft(preview_state.email_id)
        end
      end
    end, vim.tbl_extend('force', opts, { desc = 'Edit draft' }))
    
    -- Override 'g' to handle our custom g-commands immediately
    keymap('n', 'g', function()
      local char = vim.fn.getchar()
      local key = vim.fn.nr2char(char)
      
      if key == 'r' then
        require('neotex.plugins.tools.himalaya.ui.main').reply_current_email()
      elseif key == 'R' then
        require('neotex.plugins.tools.himalaya.ui.main').reply_all_current_email()
      elseif key == 'f' then
        require('neotex.plugins.tools.himalaya.ui.main').forward_current_email()
      elseif key == 'D' then
        require('neotex.plugins.tools.himalaya.ui.main').delete_current_email()
      elseif key == 'l' then
        require('neotex.plugins.tools.himalaya.ui.main').open_link_under_cursor()
      else
        -- Pass through to built-in g commands
        vim.api.nvim_feedkeys('g' .. key, 'n', false)
      end
    end, vim.tbl_extend('force', opts, { desc = 'Himalaya g-commands' }))
    
    keymap('n', 'q', function()
      require('neotex.plugins.tools.himalaya.ui.main').close_current_view()
    end, vim.tbl_extend('force', opts, { desc = 'Close' }))
    
    keymap('n', 'L', function()
      require('neotex.plugins.tools.himalaya.ui.main').open_link_under_cursor()
    end, vim.tbl_extend('force', opts, { desc = 'Go to link under cursor' }))
    
  end
  
  -- Email compose keymaps
  if vim.bo[bufnr].filetype == 'himalaya-compose' then
    keymap('n', 'Q', function()
      require('neotex.plugins.tools.himalaya.ui.main').close_without_saving()
    end, vim.tbl_extend('force', opts, { desc = 'Close without saving' }))
    
    keymap('n', 'q', function()
      require('neotex.plugins.tools.himalaya.ui.main').close_and_save_draft()
    end, vim.tbl_extend('force', opts, { desc = 'Close and save as draft' }))
    
    -- Add direct 's' key for send (override vim's substitute)
    keymap('n', 's', function()
      require('neotex.plugins.tools.himalaya.ui.main').send_current_email()
    end, vim.tbl_extend('force', opts, { desc = 'Send email' }))
    
    -- Override 'g' to handle g-commands for compose buffers
    keymap('n', 'g', function()
      local char = vim.fn.getchar()
      local key = vim.fn.nr2char(char)
      
      if key == 's' then
        require('neotex.plugins.tools.himalaya.ui.main').send_current_email()
      else
        -- Pass through to built-in g commands
        vim.api.nvim_feedkeys('g' .. key, 'n', false)
      end
    end, vim.tbl_extend('force', opts, { desc = 'Compose g-commands' }))
    
    -- Tab navigation for compose fields
    keymap('n', '<Tab>', function()
      require('neotex.plugins.tools.himalaya.ui.main').compose_next_field()
    end, vim.tbl_extend('force', opts, { desc = 'Next compose field' }))
    
    keymap('n', '<S-Tab>', function()
      require('neotex.plugins.tools.himalaya.ui.main').compose_prev_field()
    end, vim.tbl_extend('force', opts, { desc = 'Previous compose field' }))
    
    keymap('i', '<Tab>', function()
      require('neotex.plugins.tools.himalaya.ui.main').compose_next_field()
    end, vim.tbl_extend('force', opts, { desc = 'Next compose field' }))
    
    keymap('i', '<S-Tab>', function()
      require('neotex.plugins.tools.himalaya.ui.main').compose_prev_field()
    end, vim.tbl_extend('force', opts, { desc = 'Previous compose field' }))
  end
end

return M