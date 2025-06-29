-- Email list UI module
-- Handles displaying and interacting with email lists

local M = {}

local config = require('neotex.plugins.tools.himalaya.core.config')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local state = require('neotex.plugins.tools.himalaya.core.state')
local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
local notifications = require('neotex.plugins.tools.himalaya.ui.notifications')

-- Buffer tracking
local email_list_buf = nil
local email_list_win = nil

-- Show email list
function M.show(args)
  args = args or {}
  
  -- Get account and folder
  local account = config.get_current_account()
  local folder = args[1] or 'INBOX'
  
  -- Create a buffer for emails
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_name(buf, 'Himalaya Emails')
  
  -- Track buffer
  email_list_buf = buf
  
  -- Set initial content
  local lines = {
    'Himalaya Email List',
    '==================',
    '',
    'Account: ' .. (account.email or 'unknown'),
    'Folder: ' .. folder,
    '',
    'Loading emails...',
    '',
    'Use :HimalayaSyncInbox to sync your emails',
    'Use :HimalayaHealth to check system status'
  }
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Open in a window
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' Himalaya Email ',
    title_pos = 'center'
  }
  
  local win = vim.api.nvim_open_win(buf, true, win_opts)
  email_list_win = win
  
  -- Set buffer keymaps
  M.setup_keymaps(buf)
  
  -- Load emails asynchronously
  M.load_emails(buf, account, folder)
  
  logger.info('Email list opened')
end

-- Setup keymaps for email list buffer
function M.setup_keymaps(buf)
  local opts = { noremap = true, silent = true }
  
  -- Navigation
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':close<CR>', opts)
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':close<CR>', opts)
  
  -- Actions
  vim.api.nvim_buf_set_keymap(buf, 'n', 'r', ':lua require("neotex.plugins.tools.himalaya.ui.email_list").refresh()<CR>', opts)
  vim.api.nvim_buf_set_keymap(buf, 'n', 's', ':HimalayaSyncInbox<CR>', opts)
  vim.api.nvim_buf_set_keymap(buf, 'n', 'c', ':lua require("neotex.plugins.tools.himalaya.ui.compose").new()<CR>', opts)
  
  -- Email actions (placeholder for now)
  vim.api.nvim_buf_set_keymap(buf, 'n', '<CR>', ':lua require("neotex.plugins.tools.himalaya.ui.email_list").read_email()<CR>', opts)
  vim.api.nvim_buf_set_keymap(buf, 'n', 'd', ':lua require("neotex.plugins.tools.himalaya.ui.email_list").delete_email()<CR>', opts)
end

-- Load emails from himalaya CLI
function M.load_emails(buf, account, folder)
  vim.defer_fn(function()
    -- Build himalaya command with correct syntax
    local account_name = account.name or 'gmail'
    local cmd = string.format('himalaya envelope list --account %s --folder %s', 
      vim.fn.shellescape(account_name), 
      vim.fn.shellescape(folder))
    
    logger.debug('Running command: ' .. cmd)
    
    vim.fn.jobstart(cmd, {
      stdout_buffered = true,
      on_stdout = function(_, data)
        if data and #data > 0 then
          -- Update buffer with email list
          local new_lines = {
            'Himalaya Email List',
            '==================',
            '',
            'Account: ' .. (account.email or 'unknown'),
            'Folder: ' .. folder,
            '',
            '---'
          }
          
          for _, line in ipairs(data) do
            if line ~= '' then
              table.insert(new_lines, line)
            end
          end
          
          if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)
          end
        end
      end,
      on_stderr = function(_, data)
        if data and #data > 0 and data[1] ~= '' then
          local error_msg = table.concat(data, '\n')
          logger.error('Failed to fetch emails: ' .. error_msg)
          
          local error_lines = {
            'Himalaya Email List',
            '==================',
            '',
            'Error fetching emails:',
            ''
          }
          
          for _, line in ipairs(data) do
            if line ~= '' then
              table.insert(error_lines, '  ' .. line)
            end
          end
          
          table.insert(error_lines, '')
          table.insert(error_lines, 'Try running :HimalayaSyncInbox first')
          table.insert(error_lines, 'Or check :HimalayaHealth for issues')
          
          if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, error_lines)
          end
        end
      end
    })
  end, 100)
end

-- Check if email buffer is open
function M.is_buffer_open()
  if email_list_buf and vim.api.nvim_buf_is_valid(email_list_buf) then
    -- Check if buffer is displayed in any window
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == email_list_buf then
        return true
      end
    end
  end
  return false
end

-- Refresh email list
function M.refresh()
  if M.is_buffer_open() then
    logger.info('Refreshing email list...')
    -- Get current account and folder from buffer name or state
    local account = config.get_current_account()
    local folder = state.get('current_folder') or 'INBOX'
    M.load_emails(email_list_buf, account, folder)
  end
end

-- Read selected email (placeholder)
function M.read_email()
  notifications.show('Email reading not yet implemented in v2.0', 'info')
  logger.info('read_email called')
end

-- Delete selected email (placeholder)
function M.delete_email()
  notifications.show('Email deletion not yet implemented in v2.0', 'info')
  logger.info('delete_email called')
end

return M