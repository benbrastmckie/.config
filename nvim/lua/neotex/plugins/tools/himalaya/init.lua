-- Himalaya Email Plugin - Simplified and Robust
-- Main entry point for the refactored plugin

local M = {}

-- Plugin state
M.loaded = false

-- Setup function
function M.setup(opts)
  if M.loaded then
    return
  end
  
  -- Initialize core configuration
  local config = require('neotex.plugins.tools.himalaya.core.config')
  config.setup(opts)
  
  -- Initialize OAuth module
  local oauth = require('neotex.plugins.tools.himalaya.sync.oauth')
  oauth.setup()
  
  -- Initialize UI system
  local ui = require('neotex.plugins.tools.himalaya.ui')
  ui.setup()
  
  -- Set up commands
  M.setup_commands()
  
  -- Run health check on startup if configured
  if config.config.setup.check_health_on_startup then
    vim.defer_fn(function()
      local health = require('neotex.plugins.tools.himalaya.setup.health')
      local result = health.check()
      if not result.ok then
        ui.notifications.show_setup_hints()
      end
    end, 1000)
  end
  
  -- Check if setup wizard should run
  if config.config.setup.auto_run then
    local wizard = require('neotex.plugins.tools.himalaya.setup.wizard')
    if not wizard.is_setup_complete() then
      vim.defer_fn(function()
        local notify = require('neotex.util.notifications')
        notify.himalaya('Himalaya not configured. Run :HimalayaSetup to begin.', notify.categories.USER_ACTION)
      end, 2000)
    end
  end
  
  M.loaded = true
end

-- Setup user commands
function M.setup_commands()
  local cmd = vim.api.nvim_create_user_command
  
  -- Main commands
  cmd('Himalaya', function(opts)
    local ui = require('neotex.plugins.tools.himalaya.ui')
    ui.show_email_list(vim.split(opts.args or '', ' '))
  end, {
    nargs = '*',
    desc = 'Open Himalaya email list',
    complete = function()
      local utils = require('neotex.plugins.tools.himalaya.utils')
      return utils.get_folders() or {}
    end
  })
  
  cmd('HimalayaToggle', function()
    -- Check if any window has himalaya-list filetype
    local himalaya_win = nil
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == 'himalaya-list' then
        himalaya_win = win
        break
      end
    end
    
    if himalaya_win then
      -- Close the window
      vim.api.nvim_win_close(himalaya_win, true)
      local notify = require('neotex.util.notifications')
      notify.himalaya('Himalaya closed', notify.categories.INFO)
    else
      -- Open the sidebar
      local ui = require('neotex.plugins.tools.himalaya.ui')
      ui.show_email_list({})
    end
  end, {
    desc = 'Toggle Himalaya sidebar'
  })
  
  cmd('HimalayaWrite', function(opts)
    local ui = require('neotex.plugins.tools.himalaya.ui')
    ui.compose_email(opts.args)
  end, {
    nargs = '?',
    desc = 'Compose new email'
  })
  
  -- Sync commands
  cmd('HimalayaSyncInbox', function()
    local mbsync = require('neotex.plugins.tools.himalaya.sync.mbsync')
    local ui = require('neotex.plugins.tools.himalaya.ui')
    local config = require('neotex.plugins.tools.himalaya.core.config')
    local notify = require('neotex.util.notifications')
    
    -- Check if config is initialized
    if not config.is_initialized() then
      notify.himalaya('Himalaya not configured. Run :HimalayaSetup', notify.categories.ERROR)
      return
    end
    
    local account = config.get_current_account()
    if not account then
      notify.himalaya('No email account configured', notify.categories.ERROR)
      return
    end
    
    local channel = account.mbsync and account.mbsync.inbox_channel or 'gmail-inbox'
    notify.himalaya('Starting inbox sync...', notify.categories.STATUS)
    
    -- Start sidebar refresh timer
    local refresh_timer = nil
    if ui.is_email_buffer_open() then
      refresh_timer = vim.fn.timer_start(5000, function()
        -- Refresh the entire sidebar to show updated sync progress
        local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
        if sidebar.is_open() then
          ui.refresh_email_list()
        end
      end, { ['repeat'] = -1 })
    end
    
    mbsync.sync(channel, {
      on_progress = function(progress)
        if ui.notifications and ui.notifications.show_sync_progress then
          ui.notifications.show_sync_progress(progress)
        end
      end,
      callback = function(success, error)
        -- Stop the refresh timer
        if refresh_timer then
          vim.fn.timer_stop(refresh_timer)
        end
        
        if not success then
          ui.notifications.handle_sync_error(error)
        else
          -- Clear cache and refresh UI
          local utils = require('neotex.plugins.tools.himalaya.utils')
          utils.clear_email_cache()
          
          local notify = require('neotex.util.notifications')
          notify.himalaya('Sync completed successfully!', notify.categories.SUCCESS)
          
          if ui.is_email_buffer_open() then
            ui.refresh_email_list()
          end
        end
        
        -- Final sidebar refresh
        if ui.is_email_buffer_open() then
          ui.refresh_email_list()
        end
      end
    })
  end, {
    desc = 'Sync inbox only'
  })
  
  cmd('HimalayaSyncFull', function()
    local mbsync = require('neotex.plugins.tools.himalaya.sync.mbsync')
    local ui = require('neotex.plugins.tools.himalaya.ui')
    local config = require('neotex.plugins.tools.himalaya.core.config')
    local notify = require('neotex.util.notifications')
    
    -- Check if config is initialized
    if not config.is_initialized() then
      notify.himalaya('Himalaya not configured. Run :HimalayaSetup', notify.categories.ERROR)
      return
    end
    
    local account = config.get_current_account()
    if not account then
      notify.himalaya('No email account configured', notify.categories.ERROR)
      return
    end
    
    local channel = account.mbsync and account.mbsync.all_channel or 'gmail'
    notify.himalaya('Starting full sync...', notify.categories.STATUS)
    
    -- Start sidebar refresh timer
    local refresh_timer = nil
    if ui.is_email_buffer_open() then
      refresh_timer = vim.fn.timer_start(5000, function()
        -- Refresh the entire sidebar to show updated sync progress
        local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
        if sidebar.is_open() then
          ui.refresh_email_list()
        end
      end, { ['repeat'] = -1 })
    end
    
    mbsync.sync(channel, {
      on_progress = function(progress)
        if ui.notifications and ui.notifications.show_sync_progress then
          ui.notifications.show_sync_progress(progress)
        end
      end,
      callback = function(success, error)
        -- Stop the refresh timer
        if refresh_timer then
          vim.fn.timer_stop(refresh_timer)
        end
        
        if not success then
          ui.notifications.handle_sync_error(error)
        else
          local utils = require('neotex.plugins.tools.himalaya.utils')
          utils.clear_email_cache()
          
          notify.himalaya('Sync completed successfully!', notify.categories.SUCCESS)
          
          if ui.is_email_buffer_open() then
            ui.refresh_email_list()
          end
        end
        
        -- Final sidebar refresh
        if ui.is_email_buffer_open() then
          ui.refresh_email_list()
        end
      end
    })
  end, {
    desc = 'Sync all folders'
  })
  
  cmd('HimalayaCancelSync', function()
    local mbsync = require('neotex.plugins.tools.himalaya.sync.mbsync')
    local lock = require('neotex.plugins.tools.himalaya.sync.lock')
    local notify = require('neotex.util.notifications')
    
    -- First stop our own sync if running
    mbsync.stop()
    
    -- Then kill ALL mbsync processes (including external ones)
    local killed_count = 0
    local handle = io.popen('pgrep -f mbsync 2>/dev/null')
    if handle then
      local pids = handle:read('*a')
      handle:close()
      if pids and pids ~= '' then
        for pid in pids:gmatch('%d+') do
          os.execute('kill -TERM ' .. pid .. ' 2>/dev/null')
          killed_count = killed_count + 1
        end
      end
    end
    
    -- Clean up any stale locks after killing processes
    vim.defer_fn(function()
      local cleaned_locks = lock.cleanup_locks()
      if cleaned_locks > 0 then
        notify.himalaya('Cleaned ' .. cleaned_locks .. ' stale lock(s)', notify.categories.DEBUG)
      end
    end, 500)  -- Wait a bit for processes to fully terminate
    
    if killed_count > 0 then
      notify.himalaya('Cancelled ' .. killed_count .. ' sync process(es)', notify.categories.USER_ACTION)
    else
      notify.himalaya('No sync processes to cancel', notify.categories.INFO)
    end
    
    -- Stop sync status timer and refresh UI to clear sync status
    local ui = require('neotex.plugins.tools.himalaya.ui')
    ui.stop_sync_status_updates()  -- Make sure timer is stopped
    
    if ui.is_email_buffer_open() then
      vim.defer_fn(function()
        ui.refresh_email_list()
      end, 100)
    end
  end, {
    desc = 'Cancel all sync processes'
  })
  
  -- Debug command to enable/disable debug logging
  cmd('HimalayaDebug', function(opts)
    local logger = require('neotex.plugins.tools.himalaya.core.logger')
    local notify = require('neotex.util.notifications')
    
    if opts.args == 'on' or opts.args == '1' or opts.args == 'true' then
      logger.set_level('DEBUG')
      notify.himalaya('Debug logging enabled', notify.categories.SUCCESS)
    elseif opts.args == 'off' or opts.args == '0' or opts.args == 'false' then
      logger.set_level('INFO')
      notify.himalaya('Debug logging disabled', notify.categories.SUCCESS)
    else
      local current = logger.get_level_name()
      notify.himalaya('Debug logging is currently: ' .. (current == 'DEBUG' and 'ON' or 'OFF'), notify.categories.INFO)
      notify.himalaya('Use :HimalayaDebug on/off to change', notify.categories.INFO)
    end
  end, {
    nargs = '?',
    desc = 'Toggle debug logging (on/off)',
    complete = function()
      return {'on', 'off'}
    end
  })
  
  -- Setup commands
  cmd('HimalayaSetup', function()
    local wizard = require('neotex.plugins.tools.himalaya.setup.wizard')
    wizard.run()
  end, {
    desc = 'Run setup wizard'
  })
  
  cmd('HimalayaHealth', function()
    local health = require('neotex.plugins.tools.himalaya.setup.health')
    health.show_report()
  end, {
    desc = 'Show health check report'
  })
  
  cmd('HimalayaFixCommon', function()
    local health = require('neotex.plugins.tools.himalaya.setup.health')
    health.fix_common_issues()
  end, {
    desc = 'Fix common issues automatically'
  })
  
  -- OAuth commands
  cmd('HimalayaRefreshOAuth', function()
    local oauth = require('neotex.plugins.tools.himalaya.sync.oauth')
    oauth.refresh()
  end, {
    desc = 'Refresh OAuth token'
  })
  
  cmd('HimalayaOAuthStatus', function()
    local oauth = require('neotex.plugins.tools.himalaya.sync.oauth')
    local status = oauth.get_status()
    
    local notify = require('neotex.util.notifications')
    notify.himalaya('OAuth Status:', notify.categories.STATUS)
    notify.himalaya('  Token exists: ' .. tostring(status.has_token), notify.categories.STATUS)
    notify.himalaya('  Environment loaded: ' .. tostring(status.environment_loaded), notify.categories.STATUS)
    if status.last_refresh > 0 then
      local ago = os.time() - status.last_refresh
      notify.himalaya('  Last refresh: ' .. ago .. ' seconds ago', notify.categories.STATUS)
    end
  end, {
    desc = 'Show OAuth status'
  })
  
  -- Maintenance commands
  cmd('HimalayaCleanup', function()
    local notify = require('neotex.util.notifications')
    
    -- Stop all syncs
    local mbsync = require('neotex.plugins.tools.himalaya.sync.mbsync')
    mbsync.stop()
    
    -- Clean up locks
    local lock = require('neotex.plugins.tools.himalaya.sync.lock')
    local cleaned = lock.cleanup_locks()
    
    notify.himalaya('Cleanup complete:', notify.categories.USER_ACTION)
    notify.himalaya('  Stopped all syncs', notify.categories.STATUS)
    notify.himalaya('  Cleaned ' .. cleaned .. ' lock files', notify.categories.STATUS)
  end, {
    desc = 'Clean up processes and locks'
  })
  
  -- Maildir commands
  cmd('HimalayaFixMaildir', function()
    local wizard = require('neotex.plugins.tools.himalaya.setup.wizard')
    local config = require('neotex.plugins.tools.himalaya.core.config')
    local account = config.get_current_account()
    
    if not account then
      local notify = require('neotex.util.notifications')
      notify.himalaya('No account configured', notify.categories.ERROR)
      return
    end
    
    wizard.fix_uidvalidity_files(vim.fn.expand(account.maildir_path))
    
    local notify = require('neotex.util.notifications')
    notify.himalaya('Maildir structure fixed', notify.categories.USER_ACTION)
  end, {
    desc = 'Fix UIDVALIDITY files in maildir'
  })
  
  -- Migration command (for existing users)
  cmd('HimalayaMigrate', function()
    local migration = require('neotex.plugins.tools.himalaya.setup.migration')
    migration.migrate_from_old()
  end, {
    desc = 'Migrate from old plugin version'
  })
  
  -- Debug command
  cmd('HimalayaDebug', function(opts)
    local logger = require('neotex.plugins.tools.himalaya.core.logger')
    local notify = require('neotex.util.notifications')
    
    if opts.args == 'on' then
      logger.set_debug(true)
      notify.himalaya('Debug logging enabled', notify.categories.STATUS)
    elseif opts.args == 'off' then
      logger.set_debug(false)
      notify.himalaya('Debug logging disabled', notify.categories.STATUS)
    else
      local status = logger.is_debug() and 'on' or 'off'
      notify.himalaya('Debug logging is ' .. status, notify.categories.STATUS)
    end
  end, {
    nargs = '?',
    complete = function()
      return {'on', 'off'}
    end,
    desc = 'Toggle debug logging'
  })
  
  -- Additional commands for which-key mappings
  cmd('HimalayaRestore', function()
    local ui = require('neotex.plugins.tools.himalaya.ui')
    ui.prompt_session_restore()
  end, {
    desc = 'Restore previous session'
  })
  
  cmd('HimalayaSyncStatus', function()
    local mbsync = require('neotex.plugins.tools.himalaya.sync.mbsync')
    local status = mbsync.get_status()
    local notify = require('neotex.util.notifications')
    
    if status.running then
      notify.himalaya('Sync is running...', notify.categories.STATUS)
    else
      notify.himalaya('No sync in progress', notify.categories.STATUS)
    end
  end, {
    desc = 'Show sync status'
  })
  
  cmd('HimalayaFolder', function()
    local notify = require('neotex.util.notifications')
    notify.himalaya('Folder picker not implemented yet', notify.categories.USER_ACTION)
    -- TODO: Implement folder picker
  end, {
    desc = 'Change folder'
  })
  
  cmd('HimalayaAccounts', function()
    local notify = require('neotex.util.notifications')
    notify.himalaya('Account switcher not implemented yet', notify.categories.USER_ACTION)
    -- TODO: Implement account switcher
  end, {
    desc = 'Switch account'
  })
  
  cmd('HimalayaTrash', function()
    local notify = require('neotex.util.notifications')
    notify.himalaya('Trash viewer not implemented yet', notify.categories.USER_ACTION)
    -- TODO: Implement trash viewer
  end, {
    desc = 'View trash'
  })
  
  cmd('HimalayaTrashStats', function()
    local notify = require('neotex.util.notifications')
    notify.himalaya('Trash stats not implemented yet', notify.categories.USER_ACTION)
    -- TODO: Implement trash stats
  end, {
    desc = 'Show trash statistics'
  })
  
  cmd('HimalayaSyncInfo', function()
    local mbsync = require('neotex.plugins.tools.himalaya.sync.mbsync')
    local lock = require('neotex.plugins.tools.himalaya.sync.lock')
    local state = require('neotex.plugins.tools.himalaya.core.state')
    
    -- Get sync status
    local status = mbsync.get_status()
    local active_locks = lock.get_active_locks()
    
    -- Get running mbsync processes
    local mbsync_processes = {}
    local handle = io.popen('pgrep -f mbsync 2>/dev/null')
    if handle then
      local pids = handle:read('*a')
      handle:close()
      if pids and pids ~= '' then
        for pid in pids:gmatch('%d+') do
          -- Get command for this PID
          local cmd_handle = io.popen('ps -o cmd= ' .. pid .. ' 2>/dev/null')
          if cmd_handle then
            local cmd = cmd_handle:read('*a')
            cmd_handle:close()
            if cmd and cmd ~= '' then
              table.insert(mbsync_processes, {
                pid = tonumber(pid),
                cmd = cmd:gsub('\n', '')
              })
            end
          end
        end
      end
    end
    
    -- Create detailed status report
    local lines = {
      '=== Himalaya Sync Status ===',
      '',
      ' Sync Status:',
    }
    
    -- Local sync status
    if status.running then
      table.insert(lines, '  • Local sync: RUNNING')
      local start_time = state.get('sync.start_time')
      if start_time then
        local elapsed = os.time() - start_time
        table.insert(lines, '    Elapsed: ' .. elapsed .. 's')
      end
    else
      table.insert(lines, '  • Local sync: IDLE')
    end
    
    -- External sync detection
    local external_sync = #mbsync_processes > (status.running and 1 or 0)
    if external_sync then
      table.insert(lines, '  • External sync: DETECTED')
    else
      table.insert(lines, '  • External sync: None')
    end
    
    table.insert(lines, '')
    table.insert(lines, ' Process Information:')
    
    -- Process count and details
    if #mbsync_processes > 0 then
      table.insert(lines, '  • mbsync processes: ' .. #mbsync_processes)
      for _, proc in ipairs(mbsync_processes) do
        local proc_type = 'unknown'
        if proc.cmd:match('gmail%-inbox') then
          proc_type = 'inbox'
        elseif proc.cmd:match('gmail%s*$') or proc.cmd:match('%-a') then
          proc_type = 'full'
        end
        table.insert(lines, '    [' .. proc.pid .. '] ' .. proc_type .. ' sync')
      end
    else
      table.insert(lines, '  • mbsync processes: 0')
    end
    
    table.insert(lines, '')
    table.insert(lines, ' Lock Status:')
    
    -- Lock information
    local global_locked = lock.is_locked()
    if global_locked then
      table.insert(lines, '  • Global lock: ACTIVE')
    else
      table.insert(lines, '  • Global lock: Available')
    end
    
    if #active_locks > 0 then
      table.insert(lines, '  • Active locks:')
      for _, lock_name in ipairs(active_locks) do
        table.insert(lines, '    - ' .. lock_name)
      end
    end
    
    -- State information
    table.insert(lines, '')
    table.insert(lines, ' State Information:')
    if status.last_sync then
      table.insert(lines, '  • Last sync: ' .. os.date('%H:%M:%S', status.last_sync))
    else
      table.insert(lines, '  • Last sync: Never')
    end
    
    if status.last_error then
      local error_msg = status.last_error
      if #error_msg > 50 then
        error_msg = error_msg:sub(1, 50) .. '...'
      end
      table.insert(lines, '  • Last error: ' .. error_msg)
    else
      table.insert(lines, '  • Last error: None')
    end
    
    table.insert(lines, '  • Status: ' .. (status.status or 'unknown'))
    
    -- Create floating window
    local width = math.floor(vim.o.columns * 0.6)
    local height = math.min(#lines + 4, math.floor(vim.o.lines * 0.8))
    local buf = vim.api.nvim_create_buf(false, true)
    
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    
    local win_opts = {
      relative = 'editor',
      width = width,
      height = height,
      col = math.floor((vim.o.columns - width) / 2),
      row = math.floor((vim.o.lines - height) / 2),
      style = 'minimal',
      border = 'rounded',
      title = ' Sync Status ',
      title_pos = 'center',
    }
    
    local win = vim.api.nvim_open_win(buf, true, win_opts)
    
    vim.keymap.set('n', 'q', function()
      vim.api.nvim_win_close(win, true)
    end, { buffer = buf, silent = true })
    
    vim.keymap.set('n', '<Esc>', function()
      vim.api.nvim_win_close(win, true)
    end, { buffer = buf, silent = true })
    
    vim.keymap.set('n', 'r', function()
      vim.api.nvim_win_close(win, true)
      vim.cmd('HimalayaSyncInfo')  -- Refresh
    end, { buffer = buf, silent = true })
  end, {
    desc = 'Show detailed sync status'
  })
  
  cmd('HimalayaRefresh', function()
    local ui = require('neotex.plugins.tools.himalaya.ui')
    if ui.is_email_buffer_open() then
      ui.refresh_email_list()
      local notify = require('neotex.util.notifications')
      notify.himalaya('Email list refreshed', notify.categories.INFO)
    else
      local notify = require('neotex.util.notifications')
      notify.himalaya('No email sidebar open to refresh', notify.categories.INFO)
    end
  end, {
    desc = 'Refresh email sidebar'
  })
  
  cmd('HimalayaBackupAndFresh', function()
    local notify = require('neotex.util.notifications')
    local config = require('neotex.plugins.tools.himalaya.core.config')
    local state = require('neotex.plugins.tools.himalaya.core.state')
    local utils = require('neotex.plugins.tools.himalaya.utils')
    local ui = require('neotex.plugins.tools.himalaya.ui')
    local mbsync = require('neotex.plugins.tools.himalaya.sync.mbsync')
    local lock = require('neotex.plugins.tools.himalaya.sync.lock')
    
    -- Kill all sync processes first
    mbsync.stop()
    notify.himalaya(' Stopped all sync processes', notify.categories.STATUS)
    
    -- Get current maildir path
    local account = config.get_current_account()
    if not account then
      notify.himalaya('No account configured', notify.categories.ERROR)
      return
    end
    
    local mail_dir = vim.fn.expand(account.maildir_path)
    local mail_exists = vim.fn.isdirectory(mail_dir) == 1
    
    if not mail_exists then
      -- No mail directory exists - offer to create fresh
      vim.ui.input({ prompt = 'Create fresh maildir and sync all emails? (y/n): ' }, function(input)
        if input and input:lower() == 'y' then
          -- Create fresh maildir
          notify.himalaya(' Creating fresh maildir structure...', notify.categories.STATUS)
          vim.fn.mkdir(mail_dir, 'p')
          
          -- Create maildir subdirectories
          local folders = {'INBOX', 'Sent', 'Drafts', 'Trash', 'All_Mail', 'Spam', 'Starred', 'Important'}
          for _, folder in ipairs(folders) do
            local folder_path = mail_dir .. '/' .. folder
            vim.fn.mkdir(folder_path .. '/cur', 'p')
            vim.fn.mkdir(folder_path .. '/new', 'p')
            vim.fn.mkdir(folder_path .. '/tmp', 'p')
          end
          
          -- Fix UIDVALIDITY files
          local wizard = require('neotex.plugins.tools.himalaya.setup.wizard')
          wizard.fix_uidvalidity_files(mail_dir)
          
          -- Ask about running setup wizard
          vim.ui.input({ prompt = 'Run setup wizard? (y/n): ' }, function(wizard_input)
            if wizard_input and wizard_input:lower() == 'y' then
              local wizard = require('neotex.plugins.tools.himalaya.setup.wizard')
              wizard.run()
            else
              notify.himalaya('✅ Fresh maildir ready. Run :HimalayaSetup when ready to configure.', notify.categories.USER_ACTION)
            end
          end)
        end
      end)
      return
    end
    
    -- Mail directory exists - calculate stats
    local count_cmd = string.format('find %s -type f -name "*" | grep -E "/cur/|/new/" | wc -l', vim.fn.shellescape(mail_dir))
    local email_count = vim.fn.system(count_cmd):gsub('\n', '')
    
    local size_cmd = string.format('du -sh %s 2>/dev/null | cut -f1', vim.fn.shellescape(mail_dir))
    local dir_size = vim.fn.system(size_cmd):gsub('\n', '')
    
    -- Start the 3-question wizard
    -- Question 1: Backup?
    local backup_prompt = string.format('Backup %s emails (%s)? (y/n): ', email_count, dir_size)
    vim.ui.input({ prompt = backup_prompt }, function(backup_input)
      if not backup_input then
        notify.himalaya('❌ Cancelled - no changes made', notify.categories.USER_ACTION)
        return
      end
      
      local backup_made = false
      local backup_dir = nil
      
      if backup_input:lower() == 'y' then
        -- Create backup with timestamp
        local timestamp = os.date('%Y%m%d_%H%M%S')
        backup_dir = mail_dir .. '.backup.' .. timestamp
        
        -- Check if backup already exists and add suffix if needed
        local suffix = 0
        while vim.fn.isdirectory(backup_dir) == 1 do
          suffix = suffix + 1
          backup_dir = mail_dir .. '.backup.' .. timestamp .. '_' .. suffix
        end
        
        notify.himalaya(' Creating backup...', notify.categories.STATUS)
        local cp_cmd = string.format('cp -r %s %s', vim.fn.shellescape(mail_dir), vim.fn.shellescape(backup_dir))
        local result = os.execute(cp_cmd)
        
        if result == 0 then
          notify.himalaya('✅ Backup created: ' .. backup_dir, notify.categories.SUCCESS)
          backup_made = true
        else
          notify.himalaya('❌ Backup failed!', notify.categories.ERROR)
          return
        end
      end
      
      -- Question 2: Delete current mail?
      vim.ui.input({ prompt = 'Delete current mail directory? (y/n): ' }, function(delete_input)
        if not delete_input or delete_input:lower() ~= 'y' then
          notify.himalaya('❌ Cancelled - no changes made', notify.categories.USER_ACTION)
          return
        end
        
        -- Close any open Himalaya windows first
        if ui.close_himalaya then
          ui.close_himalaya()
        end
        
        notify.himalaya('  Deleting mail directory...', notify.categories.STATUS)
        
        local rm_cmd = string.format('rm -rf %s', vim.fn.shellescape(mail_dir))
        local result = os.execute(rm_cmd)
        
        if result ~= 0 then
          notify.himalaya('❌ Failed to delete mail directory', notify.categories.ERROR)
          return
        end
        
        notify.himalaya('✅ Mail directory deleted', notify.categories.SUCCESS)
        
        -- Clear all state
        state.reset()
        utils.clear_email_cache()
        state.set('setup.completed', false)
        
        -- Clean up lock files
        lock.cleanup_locks()
        
        -- Reset UI
        local ui_main = require('neotex.plugins.tools.himalaya.ui.main')
        ui_main.buffers = {
          email_list = nil,
          email_read = nil,
          email_compose = nil,
        }
        
        local ui_state = require('neotex.plugins.tools.himalaya.ui.state')
        ui_state.reset()
        
        local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
        sidebar.state = {
          is_open = false,
          width = 40,
          position = 'left',
          win = nil,
          buf = nil,
        }
        
        local window_stack = require('neotex.plugins.tools.himalaya.ui.window_stack')
        window_stack.clear()
        
        M.loaded = false
        
        -- Create fresh maildir structure
        notify.himalaya(' Creating fresh maildir structure...', notify.categories.STATUS)
        vim.fn.mkdir(mail_dir, 'p')
        
        -- Create maildir subdirectories
        local folders = {'INBOX', 'Sent', 'Drafts', 'Trash', 'All_Mail', 'Spam', 'Starred', 'Important'}
        for _, folder in ipairs(folders) do
          local folder_path = mail_dir .. '/' .. folder
          vim.fn.mkdir(folder_path .. '/cur', 'p')
          vim.fn.mkdir(folder_path .. '/new', 'p')
          vim.fn.mkdir(folder_path .. '/tmp', 'p')
        end
        
        -- Fix UIDVALIDITY files
        local wizard = require('neotex.plugins.tools.himalaya.setup.wizard')
        wizard.fix_uidvalidity_files(mail_dir)
        
        notify.himalaya('✅ Fresh maildir structure created', notify.categories.SUCCESS)
        
        -- Question 3: Run setup wizard?
        vim.schedule(function()
          vim.ui.input({ prompt = 'Run setup wizard? (y/n): ' }, function(wizard_input)
            if wizard_input and wizard_input:lower() == 'y' then
              local wizard = require('neotex.plugins.tools.himalaya.setup.wizard')
              wizard.run()
            else
              notify.himalaya('✅ Fresh maildir ready. Run :HimalayaSetup when ready to configure.', notify.categories.USER_ACTION)
            end
          end)
        end)
      end)
    end)
  end, {
    desc = 'Backup and fresh start'
  })
end

-- Keymaps helper for which-key
function M.get_keymaps()
  return {
    ['<leader>m'] = {
      name = '+mail',
      o = { ':HimalayaToggle<CR>', 'Toggle sidebar' },
      l = { ':Himalaya<CR>', 'Email list' },
      s = { ':HimalayaSyncInbox<CR>', 'Sync inbox' },
      S = { ':HimalayaSyncFull<CR>', 'Sync all' },
      c = { ':HimalayaWrite<CR>', 'Compose' },
      h = { ':HimalayaHealth<CR>', 'Health check' },
      x = { ':HimalayaCancelSync<CR>', 'Cancel sync' },
      U = { ':HimalayaCancelSync<CR>', 'Cancel all syncs' },
    }
  }
end

-- Return plugin specification for lazy.nvim
return {
  {
    -- Virtual plugin for Himalaya setup
    dir = vim.fn.stdpath('config') .. '/lua/neotex/plugins/tools/himalaya',
    name = 'himalaya-email',
    event = { 'VeryLazy' }, -- Load after startup
    config = function(_, opts)
      M.setup(opts)
    end,
    keys = {
      { '<leader>mo', ':HimalayaToggle<CR>', desc = 'Toggle email sidebar' },
      { '<leader>ms', ':HimalayaSyncInbox<CR>', desc = 'Sync inbox' },
      { '<leader>mS', ':HimalayaSyncFull<CR>', desc = 'Sync all folders' },
      { '<leader>mc', ':HimalayaWrite<CR>', desc = 'Compose email' },
      { '<leader>mW', ':HimalayaSetup<CR>', desc = 'Setup wizard' },
      { '<leader>mU', ':HimalayaCancelSync<CR>', desc = 'Cancel all syncs' },
    },
  },
  -- Dependencies
  {
    'nvim-telescope/telescope.nvim',
    optional = true,
  },
}