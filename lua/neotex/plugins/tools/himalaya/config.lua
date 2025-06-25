-- Himalaya Email Client Configuration
-- Configuration management for email workflow

local M = {}

-- Default configuration
M.config = {
  executable = 'himalaya',
  default_account = 'gmail',
  accounts = {
    gmail = { name = 'Benjamin Brast-McKie', email = 'benbrastmckie@gmail.com' },
  },
  ui = {
    email_list = {
      width = 0.8,
      height = 0.8,
    },
  },
  -- Basic keymaps (used for buffer-specific keybindings)
  keymaps = {
    read_email = '<CR>',
    write_email = 'gw',
    reply = 'gr',
    reply_all = 'gR',
    forward = 'gf',
    delete = 'gD',
    change_folder = 'gm',
    change_account = 'ga',
    refresh = 'gR',
  },
  -- Sync settings
  auto_sync = false, -- Disabled - using startup sync only to prevent conflicts
  sync_interval = 300, -- 5 minutes in seconds
  
  -- Local trash configuration
  trash = {
    enabled = true,
    directory = "~/Mail/Gmail/.trash",
    retention_days = 30,
    max_size_mb = 1000,
    organization = "daily", -- "daily", "monthly", "flat"
    metadata_storage = "json", -- "sqlite", "json"
    auto_cleanup = true,
    cleanup_interval_hours = 24
  },
  
  -- Debug and notification settings (using unified notification system)
  notification_levels = {
    -- Define which notification types are considered "important"
    important = { "error", "warn", "email_sent", "email_deleted" },
    debug_only = { "cache", "fetch", "init", "cleanup", "page_load" }
  }
}

-- Current state
M.state = {
  current_account = nil,
  current_folder = 'INBOX',
  current_page = 1,
  page_size = 30,
}

-- Setup function
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
  
  -- Set default account
  M.state.current_account = M.config.default_account
  
  -- Initialize commands
  require('neotex.plugins.tools.himalaya.commands').setup()
  
  -- Set up keymaps
  M.setup_keymaps()
  
  -- Set up autocmds
  M.setup_autocmds()
end

-- Set up global keymaps (currently unused)
function M.setup_keymaps()
  -- Reserved for future global keymaps if needed
end

-- Set up autocommands
function M.setup_autocmds()
  local augroup = vim.api.nvim_create_augroup('Himalaya', { clear = true })
  
  -- Auto-refresh email list after sync
  vim.api.nvim_create_autocmd('User', {
    pattern = 'HimalayaSyncComplete',
    group = augroup,
    callback = function()
      -- Refresh current email view if open
      local ui = require('neotex.plugins.tools.himalaya.ui')
      if ui.is_email_buffer_open() then
        ui.refresh_current_view()
      end
    end,
  })
  
  -- Auto-refresh email list after email operations
  local refresh_events = {
    'HimalayaEmailMoved',
    'HimalayaEmailCopied', 
    'HimalayaEmailSent',
    'HimalayaEmailDeleted',
    'HimalayaFlagChanged',
    'HimalayaTagChanged',
    'HimalayaExpunged',
    'HimalayaFolderCreated'
  }
  
  for _, event in ipairs(refresh_events) do
    vim.api.nvim_create_autocmd('User', {
      pattern = event,
      group = augroup,
      callback = function()
        local ui = require('neotex.plugins.tools.himalaya.ui')
        if ui.is_email_buffer_open() then
          ui.refresh_email_list()
        end
      end,
    })
  end
  
  -- Set up email-specific keymaps for email buffers
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'himalaya-*',
    group = augroup,
    callback = function(args)
      M.setup_buffer_keymaps(args.buf)
    end,
  })
end

-- Set up buffer-specific keymaps
function M.setup_buffer_keymaps(bufnr)
  local keymap = vim.keymap.set
  local opts = { buffer = bufnr, silent = true }
  
  -- Email list keymaps
  if vim.bo[bufnr].filetype == 'himalaya-list' then
    keymap('n', M.config.keymaps.read_email, function()
      require('neotex.plugins.tools.himalaya.ui').read_current_email()
    end, vim.tbl_extend('force', opts, { desc = 'Read email' }))
    
    keymap('n', M.config.keymaps.write_email, function()
      require('neotex.plugins.tools.himalaya.ui').compose_email()
    end, vim.tbl_extend('force', opts, { desc = 'Write email' }))
    
    keymap('n', M.config.keymaps.reply, function()
      require('neotex.plugins.tools.himalaya.ui').reply_current_email()
    end, vim.tbl_extend('force', opts, { desc = 'Reply' }))
    
    keymap('n', M.config.keymaps.reply_all, function()
      require('neotex.plugins.tools.himalaya.ui').reply_all_current_email()
    end, vim.tbl_extend('force', opts, { desc = 'Reply all' }))
    
    keymap('n', M.config.keymaps.forward, function()
      require('neotex.plugins.tools.himalaya.ui').forward_current_email()
    end, vim.tbl_extend('force', opts, { desc = 'Forward' }))
    
    keymap('n', M.config.keymaps.delete, function()
      require('neotex.plugins.tools.himalaya.ui').delete_current_email()
    end, vim.tbl_extend('force', opts, { desc = 'Delete' }))
    
    keymap('n', M.config.keymaps.change_folder, function()
      require('neotex.plugins.tools.himalaya.picker').show_folders()
    end, vim.tbl_extend('force', opts, { desc = 'Change folder' }))
    
    keymap('n', M.config.keymaps.change_account, function()
      require('neotex.plugins.tools.himalaya.picker').show_accounts()
    end, vim.tbl_extend('force', opts, { desc = 'Change account' }))
    
    keymap('n', M.config.keymaps.refresh, function()
      require('neotex.plugins.tools.himalaya.ui').refresh_email_list()
    end, vim.tbl_extend('force', opts, { desc = 'Refresh' }))
    
    -- Add single 'r' for refresh as well
    keymap('n', 'r', function()
      require('neotex.plugins.tools.himalaya.ui').refresh_email_list()
    end, vim.tbl_extend('force', opts, { desc = 'Refresh email list' }))
    
    -- Override 'g' to handle our custom g-commands immediately
    keymap('n', 'g', function()
      local char = vim.fn.getchar()
      local key = vim.fn.nr2char(char)
      
      if key == 'n' then
        require('neotex.plugins.tools.himalaya.ui').next_page()
      elseif key == 'p' then
        require('neotex.plugins.tools.himalaya.ui').prev_page()
      elseif key == 'm' then
        require('neotex.plugins.tools.himalaya.picker').show_folders()
      elseif key == 'a' then
        require('neotex.plugins.tools.himalaya.picker').show_accounts()
      elseif key == 'w' then
        require('neotex.plugins.tools.himalaya.ui').compose_email()
      elseif key == 'r' then
        require('neotex.plugins.tools.himalaya.ui').reply_current_email()
      elseif key == 'R' then
        require('neotex.plugins.tools.himalaya.ui').reply_all_current_email()
      elseif key == 'f' then
        require('neotex.plugins.tools.himalaya.ui').forward_current_email()
      elseif key == 'D' then
        require('neotex.plugins.tools.himalaya.ui').delete_current_email()
      elseif key == 'A' then
        require('neotex.plugins.tools.himalaya.ui').archive_current_email()
      elseif key == 'S' then
        require('neotex.plugins.tools.himalaya.ui').spam_current_email()
      else
        -- Pass through to built-in g commands
        vim.api.nvim_feedkeys('g' .. key, 'n', false)
      end
    end, vim.tbl_extend('force', opts, { desc = 'Himalaya g-commands' }))
    
    -- Add q to close Himalaya entirely from email list
    keymap('n', 'q', function()
      require('neotex.plugins.tools.himalaya.ui').close_himalaya()
    end, vim.tbl_extend('force', opts, { desc = 'Close Himalaya' }))
  end
  
  -- Email reading keymaps
  if vim.bo[bufnr].filetype == 'himalaya-email' then
    -- Override 'g' to handle our custom g-commands immediately
    keymap('n', 'g', function()
      local char = vim.fn.getchar()
      local key = vim.fn.nr2char(char)
      
      if key == 'r' then
        require('neotex.plugins.tools.himalaya.ui').reply_current_email()
      elseif key == 'R' then
        require('neotex.plugins.tools.himalaya.ui').reply_all_current_email()
      elseif key == 'f' then
        require('neotex.plugins.tools.himalaya.ui').forward_current_email()
      elseif key == 'D' then
        require('neotex.plugins.tools.himalaya.ui').delete_current_email()
      elseif key == 'l' then
        require('neotex.plugins.tools.himalaya.ui').open_link_under_cursor()
      else
        -- Pass through to built-in g commands
        vim.api.nvim_feedkeys('g' .. key, 'n', false)
      end
    end, vim.tbl_extend('force', opts, { desc = 'Himalaya g-commands' }))
    
    keymap('n', 'q', function()
      require('neotex.plugins.tools.himalaya.ui').close_current_view()
    end, vim.tbl_extend('force', opts, { desc = 'Close' }))
    
    keymap('n', 'L', function()
      require('neotex.plugins.tools.himalaya.ui').open_link_under_cursor()
    end, vim.tbl_extend('force', opts, { desc = 'Go to link under cursor' }))
  end
  
  -- Email compose keymaps
  if vim.bo[bufnr].filetype == 'himalaya-compose' then
    keymap('n', 'Q', function()
      require('neotex.plugins.tools.himalaya.ui').close_without_saving()
    end, vim.tbl_extend('force', opts, { desc = 'Close without saving' }))
    
    keymap('n', 'q', function()
      require('neotex.plugins.tools.himalaya.ui').close_and_save_draft()
    end, vim.tbl_extend('force', opts, { desc = 'Close and save as draft' }))
    
    -- Add direct 's' key for send (override vim's substitute)
    keymap('n', 's', function()
      vim.notify('Send key pressed!', vim.log.levels.INFO)
      require('neotex.plugins.tools.himalaya.ui').send_current_email()
    end, vim.tbl_extend('force', opts, { desc = 'Send email' }))
    
    -- Override 'g' to handle g-commands for compose buffers
    keymap('n', 'g', function()
      local char = vim.fn.getchar()
      local key = vim.fn.nr2char(char)
      
      if key == 's' then
        vim.notify('gs pressed!', vim.log.levels.INFO)
        require('neotex.plugins.tools.himalaya.ui').send_current_email()
      else
        -- Pass through to built-in g commands
        vim.api.nvim_feedkeys('g' .. key, 'n', false)
      end
    end, vim.tbl_extend('force', opts, { desc = 'Compose g-commands' }))
    
  end
end

-- Get current account configuration
function M.get_current_account()
  return M.config.accounts[M.state.current_account]
end

-- Switch to different account
function M.switch_account(account_name)
  if M.config.accounts[account_name] then
    M.state.current_account = account_name
    M.state.current_folder = 'INBOX'
    M.state.current_page = 1
    return true
  end
  return false
end

-- Switch to different folder
function M.switch_folder(folder_name)
  M.state.current_folder = folder_name
  M.state.current_page = 1
end

return M