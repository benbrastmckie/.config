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
    use_v2 = true,  -- Use new buffer-based composer
    use_tab = true,  -- Open in current window (false = vsplit)
    auto_save_interval = 30,
    delete_draft_on_send = true,
    syntax_highlighting = true,
    draft_dir = vim.fn.expand('~/.local/share/himalaya/drafts/'),
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
      local preview = require('neotex.plugins.tools.himalaya.ui.email_preview_v2')
      local line = vim.api.nvim_win_get_cursor(0)[1]
      local email_list = require('neotex.plugins.tools.himalaya.ui.email_list')
      local email_id = email_list.get_email_id_from_line(line)
      
      if not email_id then
        return
      end
      
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
    end, vim.tbl_extend('force', opts, { desc = 'Toggle preview mode / Focus preview' }))
    
    -- ESC to exit preview mode
    keymap('n', '<Esc>', function()
      local preview = require('neotex.plugins.tools.himalaya.ui.email_preview_v2')
      if preview.is_preview_mode() then
        preview.disable_preview_mode()
      end
    end, vim.tbl_extend('force', opts, { desc = 'Exit preview mode' }))
    
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
      elseif key == 'w' then
        require('neotex.plugins.tools.himalaya.ui.main').compose_email()
      elseif key == 'r' then
        require('neotex.plugins.tools.himalaya.ui.main').reply_current_email()
      elseif key == 'R' then
        require('neotex.plugins.tools.himalaya.ui.main').reply_all_current_email()
      elseif key == 'f' then
        require('neotex.plugins.tools.himalaya.ui.main').forward_current_email()
      elseif key == 's' then
        require('neotex.plugins.tools.himalaya.ui.main').sync_current_folder()
      elseif key == 'D' then
        if has_selection then
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
    keymap('n', '<LeftMouse>', function()
      -- Get mouse position
      local mouse_pos = vim.fn.getmousepos()
      
      -- Move cursor to clicked position
      if mouse_pos.line > 0 then
        vim.api.nvim_win_set_cursor(0, {mouse_pos.line, mouse_pos.column - 1})
      end
      
      -- Update preview immediately for mouse clicks
      vim.schedule(function()
        local preview = require('neotex.plugins.tools.himalaya.ui.email_preview_v2')
        if preview.is_preview_mode() then
          local main = require('neotex.plugins.tools.himalaya.ui.main')
          local email_id = main.get_current_email_id()
          local current_preview_id = preview.get_current_preview_id()
          
          if email_id and email_id ~= current_preview_id then
            preview.show_preview(email_id, vim.api.nvim_get_current_win())
          end
        end
      end)
    end, vim.tbl_extend('force', opts, { desc = 'Click to select email' }))
    
    -- Debounced cursor movement handler for smooth j/k navigation
    local preview_timer = nil
    vim.api.nvim_create_autocmd('CursorMoved', {
      buffer = buf,
      callback = function()
        local preview = require('neotex.plugins.tools.himalaya.ui.email_preview_v2')
        if not preview.is_preview_mode() then
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
            preview.show_preview(email_id, vim.api.nvim_get_current_win())
          end
          preview_timer = nil
        end)
      end
    })
    
    -- Select email and move down
    keymap('n', 'n', function()
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
          
          -- Refresh to show the selection change
          main.refresh_email_list()
          
          -- Move cursor down after selection
          vim.schedule(function()
            vim.cmd('normal! j')
          end)
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
          
          -- Refresh to show the selection change
          main.refresh_email_list()
          
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
        '  <Esc>     - Exit preview mode',
        '  q         - Close Himalaya',
        '  gs        - Sync current folder',
        '  gn/gp     - Next/previous page',
        '',
        'Selection:',
        '  n         - Select/deselect email and move down',
        '  N         - Select/deselect email and move up',
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