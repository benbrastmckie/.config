-- Fix mbsync configuration and corrupted maildir
-- This addresses the UIDVALIDITY and duplicate UID errors

local M = {}

local notify = require('neotex.util.notifications')

-- Backup and reset corrupted maildir
function M.reset_maildir()
  notify.himalaya('Backing up current maildir...', notify.categories.STATUS)
  
  local backup_dir = os.date('~/Mail/Gmail.backup.%Y%m%d_%H%M%S')
  local commands = {
    string.format('mv ~/Mail/Gmail %s', backup_dir),
    'mkdir -p ~/Mail/Gmail',
    'mkdir -p ~/Mail/Gmail/INBOX',
    'mkdir -p ~/Mail/Gmail/Sent',
    'mkdir -p ~/Mail/Gmail/Drafts',
    'mkdir -p ~/Mail/Gmail/Trash',
    'mkdir -p ~/Mail/Gmail/"All Mail"',
    'mkdir -p ~/Mail/Gmail/Spam'
  }
  
  for _, cmd in ipairs(commands) do
    local result = os.execute(cmd)
    if result ~= 0 then
      notify.himalaya('Failed to execute: ' .. cmd, notify.categories.ERROR)
      return false
    end
  end
  
  notify.himalaya('Maildir reset complete. Backup at: ' .. backup_dir, notify.categories.USER_ACTION)
  return true
end

-- Apply fixed mbsync configuration
function M.apply_fixed_config()
  notify.himalaya('Applying fixed mbsync configuration...', notify.categories.STATUS)
  
  -- Backup current config
  local backup_cmd = 'cp ~/.mbsyncrc ~/.mbsyncrc.backup.' .. os.date('%Y%m%d_%H%M%S')
  os.execute(backup_cmd)
  
  -- Apply fixed config
  local apply_cmd = 'cp ~/.mbsyncrc.fixed ~/.mbsyncrc'
  local result = os.execute(apply_cmd)
  
  if result == 0 then
    notify.himalaya('Fixed mbsync configuration applied', notify.categories.USER_ACTION)
    return true
  else
    notify.himalaya('Failed to apply fixed configuration', notify.categories.ERROR)
    return false
  end
end

-- Test mbsync with the new configuration
function M.test_sync()
  notify.himalaya('Testing mbsync with fixed configuration...', notify.categories.STATUS)
  
  -- Test INBOX first
  vim.fn.jobstart('mbsync gmail-inbox', {
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if exit_code == 0 then
          notify.himalaya('INBOX sync test successful', notify.categories.USER_ACTION)
          
          -- Now test full sync
          vim.defer_fn(function()
            M.full_sync()
          end, 2000)
        else
          notify.himalaya('INBOX sync test failed - check configuration', notify.categories.ERROR)
        end
      end)
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        local error_msg = table.concat(data, '\n')
        vim.schedule(function()
          notify.himalaya('mbsync error: ' .. error_msg, notify.categories.WARNING)
        end)
      end
    end
  })
end

-- Run full sync after test
function M.full_sync()
  notify.himalaya('Running full sync...', notify.categories.STATUS)
  
  vim.fn.jobstart('mbsync gmail', {
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if exit_code == 0 then
          notify.himalaya('Full sync completed successfully', notify.categories.USER_ACTION)
          
          -- Clear Himalaya cache
          local utils = require('neotex.plugins.tools.himalaya.utils')
          utils.clear_email_cache()
          
          -- Refresh view
          vim.defer_fn(function()
            pcall(vim.cmd, 'HimalayaRefresh')
          end, 1000)
        else
          notify.himalaya('Full sync failed - manual intervention may be needed', notify.categories.ERROR)
        end
      end)
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        local error_msg = table.concat(data, '\n')
        vim.schedule(function()
          notify.himalaya('mbsync: ' .. error_msg, notify.categories.WARNING)
        end)
      end
    end
  })
end

-- Complete fix process
function M.fix_all()
  notify.himalaya('Starting mbsync repair process...', notify.categories.STATUS)
  
  -- Step 1: Reset corrupted maildir
  if not M.reset_maildir() then
    return false
  end
  
  -- Step 2: Apply fixed configuration
  vim.defer_fn(function()
    if M.apply_fixed_config() then
      -- Step 3: Test sync
      vim.defer_fn(function()
        M.test_sync()
      end, 1000)
    end
  end, 2000)
  
  return true
end

-- Manual steps if automatic fix fails
function M.show_manual_steps()
  local steps = {
    "Manual mbsync fix steps:",
    "",
    "1. Stop any running mbsync processes:",
    "   pkill mbsync",
    "",
    "2. Backup and reset maildir:",
    "   mv ~/Mail/Gmail ~/Mail/Gmail.backup.$(date +%Y%m%d_%H%M%S)",
    "   mkdir -p ~/Mail/Gmail",
    "",
    "3. Apply fixed configuration:",
    "   cp ~/.mbsyncrc.fixed ~/.mbsyncrc",
    "",
    "4. Test sync:",
    "   mbsync gmail-inbox",
    "",
    "5. If successful, run full sync:",
    "   mbsync gmail",
    "",
    "6. Refresh Himalaya:",
    "   :HimalayaRefresh"
  }
  
  -- Create help window
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, steps)
  vim.bo[buf].filetype = 'text'
  vim.bo[buf].readonly = true
  
  local width = 80
  local height = math.min(25, #steps + 2)
  
  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = 'minimal',
    border = 'rounded',
    title = ' mbsync Manual Fix Steps ',
    title_pos = 'center'
  }
  
  local winid = vim.api.nvim_open_win(buf, true, win_opts)
  
  -- Close with q or Esc
  local opts = { buffer = buf, silent = true }
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(winid, true)
  end, opts)
  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(winid, true)
  end, opts)
end

return M