-- Himalaya Command Registry
-- Centralized command definitions for the Himalaya email plugin

local M = {}

-- Command registry containing all command definitions
M.command_registry = {}

-- Main UI Commands
M.command_registry.Himalaya = {
  fn = function(opts)
    local ui = require('neotex.plugins.tools.himalaya.ui')
    ui.show_email_list(vim.split(opts.args or '', ' '))
  end,
  opts = {
    nargs = '*',
    desc = 'Open Himalaya email list',
    complete = function()
      local utils = require('neotex.plugins.tools.himalaya.utils')
      return utils.get_folders() or {}
    end
  }
}

M.command_registry.HimalayaToggle = {
  fn = function()
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
      notify.himalaya('Himalaya closed', notify.categories.USER_ACTION)
    else
      -- Open the sidebar
      local ui = require('neotex.plugins.tools.himalaya.ui')
      ui.show_email_list({})
    end
  end,
  opts = {
    desc = 'Toggle Himalaya sidebar'
  }
}

M.command_registry.HimalayaWrite = {
  fn = function(opts)
    local ui = require('neotex.plugins.tools.himalaya.ui')
    ui.compose_email(opts.args)
  end,
  opts = {
    nargs = '?',
    desc = 'Compose new email'
  }
}

M.command_registry.HimalayaRefresh = {
  fn = function()
    local ui = require('neotex.plugins.tools.himalaya.ui')
    if ui.is_email_buffer_open() then
      ui.refresh_email_list()
      local notify = require('neotex.util.notifications')
      notify.himalaya('Email list refreshed', notify.categories.USER_ACTION)
    else
      local notify = require('neotex.util.notifications')
      notify.himalaya('No email sidebar open to refresh', notify.categories.STATUS)
    end
  end,
  opts = {
    desc = 'Refresh email sidebar'
  }
}

M.command_registry.HimalayaRestore = {
  fn = function()
    local ui = require('neotex.plugins.tools.himalaya.ui')
    ui.prompt_session_restore()
  end,
  opts = {
    desc = 'Restore previous session'
  }
}

M.command_registry.HimalayaFolder = {
  fn = function()
    local main = require('neotex.plugins.tools.himalaya.ui.main')
    main.pick_folder()
  end,
  opts = {
    desc = 'Change folder'
  }
}

M.command_registry.HimalayaAccounts = {
  fn = function()
    local notify = require('neotex.util.notifications')
    notify.himalaya('Account switcher not implemented yet', notify.categories.USER_ACTION)
    -- TODO: Implement account switcher
  end,
  opts = {
    desc = 'Switch account'
  }
}

M.command_registry.HimalayaTrash = {
  fn = function()
    local notify = require('neotex.util.notifications')
    notify.himalaya('Trash viewer not implemented yet', notify.categories.USER_ACTION)
    -- TODO: Implement trash viewer
  end,
  opts = {
    desc = 'View trash'
  }
}

M.command_registry.HimalayaTrashStats = {
  fn = function()
    local notify = require('neotex.util.notifications')
    notify.himalaya('Trash stats not implemented yet', notify.categories.USER_ACTION)
    -- TODO: Implement trash stats
  end,
  opts = {
    desc = 'Show trash statistics'
  }
}

-- Email Actions
M.command_registry.HimalayaSend = {
  fn = function()
    local buf = vim.api.nvim_get_current_buf()
    local composer_v2 = require('neotex.plugins.tools.himalaya.ui.email_composer_v2')
    
    -- Check if this is a compose buffer
    if composer_v2.is_compose_buffer(buf) then
      -- send_email already has its own confirmation dialog
      composer_v2.send_email(buf)
    else
      -- Not a compose buffer
      local notify = require('neotex.util.notifications')
      notify.himalaya('Not in an email compose buffer', notify.categories.ERROR)
    end
  end,
  opts = {
    desc = 'Send current email from compose buffer'
  }
}

M.command_registry.HimalayaSaveDraft = {
  fn = function()
    local buf = vim.api.nvim_get_current_buf()
    local composer_v2 = require('neotex.plugins.tools.himalaya.ui.email_composer_v2')
    
    -- Check if this is a compose buffer
    if composer_v2.is_compose_buffer(buf) then
      composer_v2.save_draft(buf)
      -- Don't close the buffer - let user continue editing
      local notify = require('neotex.util.notifications')
      notify.himalaya('Draft saved', notify.categories.USER_ACTION)
    else
      -- Not a compose buffer
      local notify = require('neotex.util.notifications')
      notify.himalaya('Not in an email compose buffer', notify.categories.ERROR)
    end
  end,
  opts = {
    desc = 'Save current email as draft'
  }
}

M.command_registry.HimalayaDiscard = {
  fn = function()
    local buf = vim.api.nvim_get_current_buf()
    local composer_v2 = require('neotex.plugins.tools.himalaya.ui.email_composer_v2')
    
    -- Check if this is a compose buffer
    if composer_v2.is_compose_buffer(buf) then
      -- Call discard_email directly which will show the modern confirmation prompt
      composer_v2.discard_email(buf)
    else
      -- Not a compose buffer
      local notify = require('neotex.util.notifications')
      notify.himalaya('Not in an email compose buffer', notify.categories.ERROR)
    end
  end,
  opts = {
    desc = 'Discard current email without saving'
  }
}

-- Sync Commands

M.command_registry.HimalayaSyncInbox = {
  fn = function()
    local config = require('neotex.plugins.tools.himalaya.core.config')
    local notify = require('neotex.util.notifications')
    local main = require('neotex.plugins.tools.himalaya.ui.main')
    
    -- Check if config is initialized
    if not config.is_initialized() then
      notify.himalaya('Himalaya not configured. Run :HimalayaSetup', notify.categories.ERROR)
      return
    end
    
    -- Use the shared sync_inbox function from main UI module
    main.sync_inbox()
  end,
  opts = {
    desc = 'Sync inbox only'
  }
}

M.command_registry.HimalayaSyncFull = {
  fn = function()
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
    
    -- Use sync manager for consistent state management
    local sync_manager = require('neotex.plugins.tools.himalaya.sync.manager')
    local account_name = config.get_current_account_name()
    
    -- Start sync through manager
    sync_manager.start_sync('full', {
      channel = channel,
      account = account_name
    })
    
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
        -- Update progress through manager
        sync_manager.update_progress(progress)
        
        if ui.notifications and ui.notifications.show_sync_progress then
          ui.notifications.show_sync_progress(progress)
        end
      end,
      callback = function(success, error)
        -- Stop the refresh timer
        if refresh_timer then
          vim.fn.timer_stop(refresh_timer)
        end
        
        -- Complete sync through manager
        sync_manager.complete_sync('full', {
          success = success,
          error = error
        })
        
        if not success then
          ui.notifications.handle_sync_error(error)
          -- Log error details in debug mode
          local notify = require('neotex.util.notifications')
          if (notify.config.debug_mode or notify.config.modules.himalaya.debug_mode) and error then
            notify.himalaya('Sync error details: ' .. error, notify.categories.BACKGROUND)
          end
        else
          local utils = require('neotex.plugins.tools.himalaya.utils')
          utils.clear_email_cache()
          
          notify.himalaya('Sync completed successfully!', notify.categories.USER_ACTION)
          
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
  end,
  opts = {
    desc = 'Sync all folders'
  }
}

M.command_registry.HimalayaCancelSync = {
  fn = function()
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
        notify.himalaya('Cleaned ' .. cleaned_locks .. ' stale lock(s)', notify.categories.BACKGROUND)
      end
    end, 500)  -- Wait a bit for processes to fully terminate
    
    if killed_count > 0 then
      notify.himalaya('Cancelled ' .. killed_count .. ' sync process(es)', notify.categories.USER_ACTION)
    else
      notify.himalaya('No sync processes to cancel', notify.categories.STATUS)
    end
    
    -- Stop sync status timer and refresh UI to clear sync status
    local ui = require('neotex.plugins.tools.himalaya.ui')
    ui.stop_sync_status_updates()  -- Make sure timer is stopped
    
    if ui.is_email_buffer_open() then
      vim.defer_fn(function()
        ui.refresh_email_list()
      end, 100)
    end
  end,
  opts = {
    desc = 'Cancel all sync processes'
  }
}

M.command_registry.HimalayaSyncStatus = {
  fn = function()
    local mbsync = require('neotex.plugins.tools.himalaya.sync.mbsync')
    local status = mbsync.get_status()
    local notify = require('neotex.util.notifications')
    
    if status.running then
      notify.himalaya('Sync is running...', notify.categories.STATUS)
    else
      notify.himalaya('No sync in progress', notify.categories.STATUS)
    end
  end,
  opts = {
    desc = 'Show sync status'
  }
}

M.command_registry.HimalayaSyncInfo = {
  fn = function()
    local sync_manager = require('neotex.plugins.tools.himalaya.sync.manager')
    local mbsync = require('neotex.plugins.tools.himalaya.sync.mbsync')
    local lock = require('neotex.plugins.tools.himalaya.sync.lock')
    local state = require('neotex.plugins.tools.himalaya.core.state')
    
    -- Helper function to format time ago
    local function format_time_ago(timestamp)
      if not timestamp then return 'Never' end
      local now = os.time()
      local diff = now - timestamp
      
      if diff < 60 then
        return diff .. 's ago'
      elseif diff < 3600 then
        return math.floor(diff / 60) .. 'm ago'
      elseif diff < 86400 then
        return math.floor(diff / 3600) .. 'h ago'
      else
        return os.date('%Y-%m-%d %H:%M', timestamp)
      end
    end
    
    -- Get current sync info from unified manager
    local sync_info = sync_manager.get_sync_info()
    local history = sync_manager.get_history()
    
    -- Get old status for process detection
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
    }
    
    -- Current sync status
    if sync_info.type then
      table.insert(lines, ' Current Sync:')
      table.insert(lines, '  • Type: ' .. sync_info.type)
      table.insert(lines, '  • Status: ' .. sync_info.status)
      table.insert(lines, '  • Message: ' .. (sync_info.message or 'N/A'))
      
      if sync_info.start_time then
        local elapsed = os.time() - sync_info.start_time
        table.insert(lines, '  • Elapsed: ' .. elapsed .. 's')
      end
      
      -- Type-specific info
      if sync_info.type == 'full' and sync_info.channel then
        table.insert(lines, '  • Channel: ' .. sync_info.channel)
      elseif sync_info.type == 'fast_check' and sync_info.account then
        table.insert(lines, '  • Account: ' .. sync_info.account)
      end
      
      table.insert(lines, '')
    end
    
    -- Sync history
    table.insert(lines, ' Sync History:')
    table.insert(lines, '  • Last full sync: ' .. format_time_ago(history.last_full_sync))
    table.insert(lines, '  • Last fast check: ' .. format_time_ago(history.last_fast_check))
    table.insert(lines, '  • Full syncs today: ' .. (history.total_syncs_today or 0))
    table.insert(lines, '  • Fast checks today: ' .. (history.total_checks_today or 0))
    
    if history.last_error then
      table.insert(lines, '')
      table.insert(lines, ' Last Error:')
      table.insert(lines, '  • Type: ' .. (history.last_error_type or 'unknown'))
      table.insert(lines, '  • Time: ' .. format_time_ago(history.last_error_time))
      local error_msg = history.last_error
      if #error_msg > 50 then
        error_msg = error_msg:sub(1, 50) .. '...'
      end
      table.insert(lines, '  • Message: ' .. error_msg)
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
    
    -- External sync detection
    local external_sync = #mbsync_processes > (status.running and 1 or 0)
    if external_sync then
      table.insert(lines, '  • External sync: DETECTED')
    else
      table.insert(lines, '  • External sync: None')
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
  end,
  opts = {
    desc = 'Show detailed sync status'
  }
}

-- Setup/Maintenance Commands
M.command_registry.HimalayaSetup = {
  fn = function()
    local wizard = require('neotex.plugins.tools.himalaya.setup.wizard')
    wizard.run()
  end,
  opts = {
    desc = 'Run setup wizard'
  }
}

M.command_registry.HimalayaHealth = {
  fn = function()
    local health = require('neotex.plugins.tools.himalaya.setup.health')
    health.show_report()
  end,
  opts = {
    desc = 'Show health check report'
  }
}

M.command_registry.HimalayaFixCommon = {
  fn = function()
    local health = require('neotex.plugins.tools.himalaya.setup.health')
    health.fix_common_issues()
  end,
  opts = {
    desc = 'Fix common issues automatically'
  }
}

M.command_registry.HimalayaFixMaildir = {
  fn = function()
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
  end,
  opts = {
    desc = 'Fix UIDVALIDITY files in maildir'
  }
}

M.command_registry.HimalayaMigrate = {
  fn = function()
    local migration = require('neotex.plugins.tools.himalaya.setup.migration')
    migration.migrate_from_old()
  end,
  opts = {
    desc = 'Migrate from old plugin version'
  }
}

M.command_registry.HimalayaCleanup = {
  fn = function()
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
  end,
  opts = {
    desc = 'Clean up processes and locks'
  }
}

M.command_registry.HimalayaBackupAndFresh = {
  fn = function()
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
              notify.himalaya('[OK] Fresh maildir ready. Run :HimalayaSetup when ready to configure.', notify.categories.USER_ACTION)
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
        notify.himalaya('[CANCELLED] Cancelled - no changes made', notify.categories.USER_ACTION)
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
          notify.himalaya('[OK] Backup created: ' .. backup_dir, notify.categories.USER_ACTION)
          backup_made = true
        else
          notify.himalaya('[CANCELLED] Backup failed!', notify.categories.ERROR)
          return
        end
      end
      
      -- Question 2: Delete current mail?
      vim.ui.input({ prompt = 'Delete current mail directory? (y/n): ' }, function(delete_input)
        if not delete_input or delete_input:lower() ~= 'y' then
          notify.himalaya('[CANCELLED] Cancelled - no changes made', notify.categories.USER_ACTION)
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
          notify.himalaya('[CANCELLED] Failed to delete mail directory', notify.categories.ERROR)
          return
        end
        
        notify.himalaya('[OK] Mail directory deleted', notify.categories.USER_ACTION)
        
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
        
        local ui_state = require('neotex.plugins.tools.himalaya.core.state')
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
        
        notify.himalaya('[OK] Fresh maildir structure created', notify.categories.USER_ACTION)
        
        -- Question 3: Run setup wizard?
        vim.schedule(function()
          vim.ui.input({ prompt = 'Run setup wizard? (y/n): ' }, function(wizard_input)
            if wizard_input and wizard_input:lower() == 'y' then
              local wizard = require('neotex.plugins.tools.himalaya.setup.wizard')
              wizard.run()
            else
              notify.himalaya('[OK] Fresh maildir ready. Run :HimalayaSetup when ready to configure.', notify.categories.USER_ACTION)
            end
          end)
        end)
      end)
    end)
  end,
  opts = {
    desc = 'Backup and fresh start'
  }
}

-- OAuth Commands
M.command_registry.HimalayaRefreshOAuth = {
  fn = function()
    local oauth = require('neotex.plugins.tools.himalaya.sync.oauth')
    oauth.refresh()
  end,
  opts = {
    desc = 'Refresh OAuth token'
  }
}

M.command_registry.HimalayaOAuthRefresh = {
  fn = function()
    local oauth = require('neotex.plugins.tools.himalaya.sync.oauth')
    local notify = require('neotex.util.notifications')
    
    notify.himalaya('Refreshing OAuth token...', notify.categories.STATUS)
    
    oauth.refresh(nil, function(success, error_msg)
      if success then
        notify.himalaya('OAuth token refreshed successfully!', notify.categories.USER_ACTION)
      else
        notify.himalaya('Failed to refresh OAuth token: ' .. (error_msg or 'unknown error'), notify.categories.ERROR)
        notify.himalaya('You may need to run: himalaya account configure gmail', notify.categories.USER_ACTION)
      end
    end)
  end,
  opts = {
    desc = 'Manually refresh OAuth token'
  }
}

-- Debug Commands
M.command_registry.HimalayaDebug = {
  fn = function()
    local state = require('neotex.plugins.tools.himalaya.core.state')
    local config = require('neotex.plugins.tools.himalaya.core.config')
    local mbsync = require('neotex.plugins.tools.himalaya.sync.mbsync')
    local notify = require('neotex.util.notifications')
    
    -- Collect debug information
    local lines = {
      '=== Himalaya Debug Information ===',
      '',
      'System Info:',
      '  • Platform: ' .. vim.loop.os_uname().sysname,
      '  • Neovim version: ' .. vim.version().major .. '.' .. vim.version().minor .. '.' .. vim.version().patch,
      '  • Debug mode: ' .. (notify.config.debug_mode and 'ON' or 'OFF'),
      '',
      'Configuration:',
      '  • Current account: ' .. (config.get_current_account_name() or 'none'),
      '  • Config initialized: ' .. tostring(config.is_initialized()),
      '',
      'Sync State:',
      '  • Type: ' .. tostring(state.get('sync.type')),
      '  • Status: ' .. tostring(state.get('sync.status')),
      '  • Running: ' .. tostring(state.get('sync.running')),
      '  • Last sync: ' .. (state.get('sync.last_sync') and os.date('%Y-%m-%d %H:%M:%S', state.get('sync.last_sync')) or 'never'),
      '',
      'Mbsync Status:',
    }
    
    -- Get mbsync status
    local status = mbsync.get_status()
    table.insert(lines, '  • Running: ' .. tostring(status.running))
    table.insert(lines, '  • External sync: ' .. tostring(status.external_sync_running))
    table.insert(lines, '  • Last error: ' .. (status.last_error or 'none'))
    
    -- Check for mbsync binary
    table.insert(lines, '')
    table.insert(lines, 'Binaries:')
    local mbsync_path = vim.fn.system('which mbsync 2>/dev/null'):gsub('\n', '')
    table.insert(lines, '  • mbsync: ' .. (mbsync_path ~= '' and mbsync_path or 'NOT FOUND'))
    local himalaya_path = vim.fn.system('which himalaya 2>/dev/null'):gsub('\n', '')
    table.insert(lines, '  • himalaya: ' .. (himalaya_path ~= '' and himalaya_path or 'NOT FOUND'))
    
    -- OAuth status
    table.insert(lines, '')
    table.insert(lines, 'OAuth Status:')
    local oauth = require('neotex.plugins.tools.himalaya.sync.oauth')
    local oauth_status = oauth.get_status()
    table.insert(lines, '  • Has token: ' .. tostring(oauth_status.has_token))
    table.insert(lines, '  • Token valid: ' .. tostring(oauth_status.is_valid))
    table.insert(lines, '  • Last refresh: ' .. (oauth_status.last_refresh and os.date('%Y-%m-%d %H:%M:%S', oauth_status.last_refresh) or 'never'))
    
    -- Create floating window
    local width = math.floor(vim.o.columns * 0.6)
    local height = math.min(#lines + 4, math.floor(vim.o.lines * 0.8))
    local buf = vim.api.nvim_create_buf(false, true)
    
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    
    -- Calculate position
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    
    -- Create window
    local win = vim.api.nvim_open_win(buf, true, {
      relative = 'editor',
      row = row,
      col = col,
      width = width,
      height = height,
      style = 'minimal',
      border = 'rounded',
      title = ' Himalaya Debug ',
      title_pos = 'center'
    })
    
    -- Set keymaps
    vim.keymap.set('n', 'q', function()
      vim.api.nvim_win_close(win, true)
    end, { buffer = buf, silent = true })
    
    vim.keymap.set('n', '<Esc>', function()
      vim.api.nvim_win_close(win, true)
    end, { buffer = buf, silent = true })
  end,
  opts = {
    desc = 'Show debug information'
  }
}

M.command_registry.HimalayaDebugSyncState = {
  fn = function()
    local state = require('neotex.plugins.tools.himalaya.core.state')
    local notify = require('neotex.util.notifications')
    
    notify.himalaya('=== Sync State Debug ===', notify.categories.STATUS)
    notify.himalaya('sync.running: ' .. tostring(state.get('sync.running')), notify.categories.STATUS)
    notify.himalaya('sync.checking: ' .. tostring(state.get('sync.checking')), notify.categories.STATUS)
    notify.himalaya('sync.status: ' .. tostring(state.get('sync.status')), notify.categories.STATUS)
    notify.himalaya('sync.start_time: ' .. tostring(state.get('sync.start_time')), notify.categories.STATUS)
    notify.himalaya('sync.check_start_time: ' .. tostring(state.get('sync.check_start_time')), notify.categories.STATUS)
    
    -- Also check mbsync status
    local mbsync = require('neotex.plugins.tools.himalaya.sync.mbsync')
    local mbsync_status = mbsync.get_status()
    notify.himalaya('mbsync.running: ' .. tostring(mbsync_status.running), notify.categories.STATUS)
    notify.himalaya('mbsync.sync_running: ' .. tostring(mbsync_status.sync_running), notify.categories.STATUS)
    
    -- Check sidebar status
    local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
    notify.himalaya('sidebar.is_open(): ' .. tostring(sidebar.is_open()), notify.categories.STATUS)
    
    -- Try to get sync status line
    local main = require('neotex.plugins.tools.himalaya.ui.main')
    local sync_line = main.get_sync_status_line()
    notify.himalaya('get_sync_status_line(): ' .. tostring(sync_line), notify.categories.STATUS)
  end,
  opts = {
    desc = 'Debug sync state values'
  }
}

M.command_registry.HimalayaTestNotify = {
  fn = function()
    local notify = require('neotex.util.notifications')
    notify.himalaya('Test STATUS notification', notify.categories.STATUS)
    notify.himalaya('Test INFO notification', notify.categories.STATUS)
    notify.himalaya('Test SUCCESS notification', notify.categories.USER_ACTION)
    notify.himalaya('Test ERROR notification', notify.categories.ERROR)
    notify.himalaya('Test DEBUG notification', notify.categories.BACKGROUND)
  end,
  opts = {
    desc = 'Test notifications'
  }
}

M.command_registry.HimalayaDebugJson = {
  fn = function()
    local utils = require('neotex.plugins.tools.himalaya.utils')
    local config = require('neotex.plugins.tools.himalaya.core.config')
    local logger = require('neotex.plugins.tools.himalaya.core.logger')
    local notify = require('neotex.util.notifications')
    
    -- Enable debug logging temporarily
    local old_level = logger.current_level
    logger.set_debug(true)
    
    notify.himalaya('Testing Himalaya JSON output...', notify.categories.STATUS)
    
    -- Test basic command
    local account = config.get_current_account_name()
    if not account then
      notify.himalaya('No account configured', notify.categories.ERROR)
      return
    end
    
    -- Test folder list (simple command)
    notify.himalaya('Testing folder list...', notify.categories.STATUS)
    local folders = utils.get_folders(account)
    if folders then
      notify.himalaya('Folder list successful: ' .. #folders .. ' folders', notify.categories.STATUS)
    else
      notify.himalaya('Folder list failed - check :messages', notify.categories.ERROR)
    end
    
    -- Test email list (more complex)
    notify.himalaya('Testing email list...', notify.categories.STATUS)
    local emails, count = utils.get_email_list(account, 'INBOX', 1, 5)
    if emails then
      notify.himalaya('Email list successful: ' .. (count or #emails) .. ' total emails', notify.categories.STATUS)
    else
      notify.himalaya('Email list failed - check :messages', notify.categories.ERROR)
    end
    
    -- Restore log level
    logger.current_level = old_level
    notify.himalaya('Debug test complete - check :messages for details', notify.categories.STATUS)
  end,
  opts = {
    desc = 'Debug Himalaya JSON parsing'
  }
}

M.command_registry.HimalayaRawTest = {
  fn = function(opts)
    local args = vim.split(opts.args or 'envelope list', ' ')
    local config = require('neotex.plugins.tools.himalaya.core.config')
    local notify = require('neotex.util.notifications')
    
    local account = config.get_current_account_name()
    if not account then
      notify.himalaya('No account configured', notify.categories.ERROR)
      return
    end
    
    -- Build command
    local cmd = { config.config.binaries.himalaya or 'himalaya' }
    vim.list_extend(cmd, args)
    table.insert(cmd, '-a')
    table.insert(cmd, account)
    table.insert(cmd, '-o')
    table.insert(cmd, 'json')
    
    notify.himalaya('Running: ' .. table.concat(cmd, ' '), notify.categories.STATUS)
    
    -- Execute command
    local result = vim.fn.system(cmd)
    local exit_code = vim.v.shell_error
    
    -- Create output buffer
    local buf = vim.api.nvim_create_buf(false, true)
    local lines = {
      'Command: ' .. table.concat(cmd, ' '),
      'Exit code: ' .. exit_code,
      '',
      '--- Raw Output ---',
    }
    
    -- Add raw output
    local output_lines = vim.split(result or '', '\n')
    vim.list_extend(lines, output_lines)
    
    lines[#lines + 1] = ''
    lines[#lines + 1] = '--- JSON Parse Test ---'
    
    -- Try to parse JSON
    local success, data = pcall(vim.json.decode, result)
    if success then
      lines[#lines + 1] = 'JSON parsing: SUCCESS'
      lines[#lines + 1] = 'Data type: ' .. type(data)
      if type(data) == 'table' then
        lines[#lines + 1] = 'Number of items: ' .. #data
        lines[#lines + 1] = ''
        lines[#lines + 1] = '--- Parsed Data (pretty) ---'
        lines[#lines + 1] = vim.inspect(data)
      end
    else
      lines[#lines + 1] = 'JSON parsing: FAILED'
      lines[#lines + 1] = 'Error: ' .. tostring(data)
    end
    
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    vim.api.nvim_buf_set_option(buf, 'filetype', 'json')
    
    -- Open in split
    vim.cmd('split')
    vim.api.nvim_win_set_buf(0, buf)
  end,
  opts = {
    nargs = '*',
    desc = 'Test raw Himalaya command output'
  }
}

-- Function to register all commands
function M.register_all()
  local cmd = vim.api.nvim_create_user_command
  
  for name, def in pairs(M.command_registry) do
    cmd(name, def.fn, def.opts)
  end
  
  -- Register preview commands
  local preview_commands = require('neotex.plugins.tools.himalaya.core.commands_preview')
  preview_commands.register()
end

return M