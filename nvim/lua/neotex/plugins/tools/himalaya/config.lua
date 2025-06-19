-- Himalaya Email Client Configuration
-- Configuration management for email workflow

local M = {}

-- Default configuration
M.config = {
  executable = 'himalaya',
  default_account = 'gmail',
  accounts = {
    gmail = { name = 'Gmail', email = 'benbrastmckie@gmail.com' },
    work = { name = 'Work', email = 'work@company.com' },
  },
  folder_picker = 'telescope', -- 'telescope', 'fzf', 'native'
  ui = {
    email_list = {
      width = 0.8,
      height = 0.8,
      preview = true,
    },
    compose = {
      width = 0.9,
      height = 0.9,
    },
    folder_picker = {
      width = 0.6,
      height = 0.4,
    },
  },
  keymaps = {
    -- Email list navigation
    read_email = '<CR>',
    write_email = 'gw',
    reply = 'gr',
    reply_all = 'gR',
    forward = 'gf',
    delete = 'gD',
    change_folder = 'gm',
    next_page = 'gn',
    prev_page = 'gp',
    -- Folder/account management
    change_account = 'ga',
    refresh = 'gr',
    -- Email operations
    copy = 'gC',
    move = 'gM',
    attachments = 'gA',
    flag = 'gF',
    search = '/',
  },
  -- Email content settings
  html_viewer = 'w3m',
  editor = vim.env.EDITOR or 'nvim',
  -- Sync settings
  auto_sync = false, -- Disabled due to mbsync configuration conflict
  sync_interval = 300, -- 5 minutes in seconds
}

-- Current state
M.state = {
  current_account = nil,
  current_folder = 'INBOX',
  current_page = 1,
  email_list = {},
  folders = {},
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

-- Set up global keymaps
function M.setup_keymaps()
  local keymap = vim.keymap.set
  
  -- Note: These keymaps are not used directly since we're using which-key
  -- They're kept here for reference and backup
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
    
    keymap('n', 'ZZ', function()
      require('neotex.plugins.tools.himalaya.ui').send_current_email()
    end, vim.tbl_extend('force', opts, { desc = 'Send email' }))
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