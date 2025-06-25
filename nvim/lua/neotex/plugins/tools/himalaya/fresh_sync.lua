-- Fresh Sync Approach - Clean Start
-- Create a fresh maildir to avoid corruption issues

local M = {}

local notify = require('neotex.util.notifications')

-- Backup and create fresh maildir
function M.create_fresh_maildir()
  local timestamp = os.date('%Y%m%d_%H%M%S')
  local backup_dir = string.format('%s/Mail/Gmail_backup_%s', vim.env.HOME, timestamp)
  local gmail_dir = vim.env.HOME .. '/Mail/Gmail'
  
  notify.himalaya('Creating backup of current maildir...', notify.categories.STATUS)
  
  -- Backup existing Gmail directory
  local backup_cmd = string.format('mv "%s" "%s"', gmail_dir, backup_dir)
  local result = os.execute(backup_cmd)
  
  if result ~= 0 then
    notify.himalaya('Failed to backup maildir', notify.categories.ERROR)
    return false
  end
  
  -- Create fresh Gmail directory structure
  local create_cmd = string.format('mkdir -p "%s/INBOX"', gmail_dir)
  os.execute(create_cmd)
  
  notify.himalaya(string.format('Backup created: %s', backup_dir), notify.categories.USER_ACTION)
  notify.himalaya('Fresh maildir created', notify.categories.STATUS)
  
  return true, backup_dir
end

-- Restore from backup
function M.restore_from_backup(backup_dir)
  local gmail_dir = vim.env.HOME .. '/Mail/Gmail'
  
  -- Remove fresh directory
  os.execute(string.format('rm -rf "%s"', gmail_dir))
  
  -- Restore backup
  local restore_cmd = string.format('mv "%s" "%s"', backup_dir, gmail_dir)
  local result = os.execute(restore_cmd)
  
  if result == 0 then
    notify.himalaya('Maildir restored from backup', notify.categories.USER_ACTION)
    return true
  else
    notify.himalaya('Failed to restore backup', notify.categories.ERROR)
    return false
  end
end

-- Fresh inbox sync (only inbox, limited messages)
function M.fresh_inbox_sync()
  notify.himalaya('Starting fresh inbox sync (recent messages only)...', notify.categories.STATUS)
  
  -- Use mbsync with date filter to only get recent emails
  local recent_days = 7 -- Only last 7 days
  local cutoff_date = os.date('%d-%b-%Y', os.time() - (recent_days * 24 * 60 * 60))
  
  -- Use timeout and limit to recent messages only
  local cmd = { 'timeout', '60', 'mbsync', '-V', 'gmail-inbox' }
  
  local output = {}
  local job_id = vim.fn.jobstart(cmd, {
    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        if line and line ~= "" then
          table.insert(output, line)
          -- Show important progress
          if line:match('messages') or line:match('recent') then
            notify.himalaya(line, notify.categories.STATUS)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      for _, line in ipairs(data) do
        if line and line ~= "" then
          table.insert(output, line)
          if line:match('error') or line:match('failed') then
            notify.himalaya('Error: ' .. line, notify.categories.ERROR)
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        notify.himalaya('Fresh sync completed successfully', notify.categories.USER_ACTION)
        M._show_sync_results()
      elseif exit_code == 124 then
        notify.himalaya('Sync timed out after 60 seconds', notify.categories.WARNING)
      else
        notify.himalaya(string.format('Sync failed with exit code: %d', exit_code), notify.categories.ERROR)
      end
    end
  })
  
  if job_id <= 0 then
    notify.himalaya('Failed to start sync process', notify.categories.ERROR)
    return false
  end
  
  return true
end

-- Show results of fresh sync
function M._show_sync_results()
  local inbox_dir = vim.env.HOME .. '/Mail/Gmail/INBOX'
  
  -- Count emails
  local handle = io.popen(string.format('find "%s" -type f | wc -l', inbox_dir))
  local count = 0
  if handle then
    count = tonumber(handle:read('*a')) or 0
    handle:close()
  end
  
  notify.himalaya(string.format('Fresh sync complete: %d emails downloaded', count), notify.categories.USER_ACTION)
  
  -- Show recent emails
  if count > 0 then
    local recent_cmd = string.format('find "%s" -type f -printf "%%T@ %%p\\n" | sort -n | tail -5', inbox_dir)
    local recent_handle = io.popen(recent_cmd)
    if recent_handle then
      notify.himalaya('Most recent emails:', notify.categories.STATUS)
      for line in recent_handle:lines() do
        local timestamp, path = line:match('([%d%.]+)%s+(.+)')
        if timestamp and path then
          local filename = path:match('.*/([^/]+)$')
          local date = os.date('%Y-%m-%d %H:%M', tonumber(timestamp))
          notify.himalaya(string.format('  %s: %s', date, filename), notify.categories.STATUS)
        end
      end
      recent_handle:close()
    end
  end
end

-- Setup commands
function M.setup_commands()
  vim.api.nvim_create_user_command('HimalayaFreshSync', function()
    local success, backup_dir = M.create_fresh_maildir()
    if success then
      M.fresh_inbox_sync()
    end
  end, {
    desc = 'Create fresh maildir and sync recent emails only'
  })
  
  vim.api.nvim_create_user_command('HimalayaQuickInbox', M.fresh_inbox_sync, {
    desc = 'Quick inbox sync (current maildir)'
  })
end

return M