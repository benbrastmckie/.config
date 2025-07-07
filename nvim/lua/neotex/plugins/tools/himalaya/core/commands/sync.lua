-- Himalaya Sync Commands
-- Commands related to email synchronization

local M = {}

function M.setup(registry)
  local commands = {}
  
  -- Sync operations
  commands.HimalayaSyncInbox = {
    fn = function()
      local main = require('neotex.plugins.tools.himalaya.ui.main')
      local config = require('neotex.plugins.tools.himalaya.core.config')
      local notify = require('neotex.util.notifications')
      
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
  
  commands.HimalayaSyncFull = {
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
  
  commands.HimalayaCancelSync = {
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
        ui.refresh_email_list()
      end
    end,
    opts = {
      desc = 'Cancel running sync'
    }
  }
  
  commands.HimalayaSyncStatus = {
    fn = function()
      local sync_manager = require('neotex.plugins.tools.himalaya.sync.manager')
      local state = require('neotex.plugins.tools.himalaya.core.state')
      local lock = require('neotex.plugins.tools.himalaya.sync.lock')
      local float = require('neotex.plugins.tools.himalaya.ui.float')
      
      local status = sync_manager.get_status()
      local lines = {}
      
      table.insert(lines, '# Sync Status')
      table.insert(lines, '')
      
      -- Current sync status
      if status.is_syncing then
        table.insert(lines, '🔄 **Sync in progress**')
        table.insert(lines, string.format('  Type: %s', status.sync_type))
        table.insert(lines, string.format('  Account: %s', status.account))
        if status.progress then
          table.insert(lines, string.format('  Progress: %s', status.progress))
        end
      else
        table.insert(lines, '✅ No sync currently running')
      end
      
      -- Active locks
      local active_locks = lock.get_active_locks()
      if #active_locks > 0 then
        table.insert(lines, '')
        table.insert(lines, '## Active Locks')
        for _, lock_info in ipairs(active_locks) do
          table.insert(lines, string.format('  - %s', lock_info))
        end
      end
      
      -- Last sync info
      local last_sync = state.get('sync.last_sync')
      if last_sync then
        table.insert(lines, '')
        table.insert(lines, '## Last Sync')
        local ago = os.time() - last_sync
        local minutes = math.floor(ago / 60)
        table.insert(lines, string.format('  Completed: %d minutes ago', minutes))
      end
      
      -- Last error
      local last_error = state.get('sync.last_error')
      if last_error then
        table.insert(lines, '')
        table.insert(lines, '## Last Error')
        table.insert(lines, '  ' .. last_error)
      end
      
      float.show('Sync Status', lines)
    end,
    opts = {
      desc = 'Show sync status'
    }
  }
  
  commands.HimalayaSyncInfo = {
    fn = function()
      local config = require('neotex.plugins.tools.himalaya.core.config')
      local oauth = require('neotex.plugins.tools.himalaya.sync.oauth')
      local float = require('neotex.plugins.tools.himalaya.ui.float')
      
      local account = config.get_current_account()
      local lines = {}
      
      table.insert(lines, '# Sync Configuration')
      table.insert(lines, '')
      table.insert(lines, '## Account')
      table.insert(lines, string.format('  Name: %s', account.name or 'default'))
      table.insert(lines, string.format('  Email: %s', account.email or 'not set'))
      table.insert(lines, string.format('  Maildir: %s', account.maildir_path or 'not set'))
      
      -- OAuth status
      local oauth_status = oauth.get_status(account.name or 'gmail')
      table.insert(lines, '')
      table.insert(lines, '## OAuth Status')
      table.insert(lines, string.format('  Token exists: %s', oauth_status.has_token and 'Yes' or 'No'))
      if oauth_status.last_refresh > 0 then
        local ago = os.time() - oauth_status.last_refresh
        local minutes = math.floor(ago / 60)
        table.insert(lines, string.format('  Last refresh: %d minutes ago', minutes))
      end
      
      -- Mbsync channels
      if account.mbsync then
        table.insert(lines, '')
        table.insert(lines, '## Mbsync Channels')
        table.insert(lines, string.format('  Inbox: %s', account.mbsync.inbox_channel or 'not set'))
        table.insert(lines, string.format('  All: %s', account.mbsync.all_channel or 'not set'))
      end
      
      float.show('Sync Information', lines)
    end,
    opts = {
      desc = 'Show sync configuration'
    }
  }
  
  commands.HimalayaAutoSyncToggle = {
    fn = function()
      local config = require('neotex.plugins.tools.himalaya.core.config')
      local notify = require('neotex.util.notifications')
      
      -- Toggle auto-sync setting
      local current = config.get('auto_sync', false)
      config.set('auto_sync', not current)
      
      if not current then
        notify.himalaya('Auto-sync enabled', notify.categories.STATUS)
      else
        notify.himalaya('Auto-sync disabled', notify.categories.STATUS)
      end
    end,
    opts = {
      desc = 'Toggle auto-sync on/off'
    }
  }
  
  commands.HimalayaOAuthRefresh = {
    fn = function()
      local oauth = require('neotex.plugins.tools.himalaya.sync.oauth')
      local config = require('neotex.plugins.tools.himalaya.core.config')
      local notify = require('neotex.util.notifications')
      
      local account = config.get_current_account()
      local account_name = account.name or 'gmail'
      
      notify.himalaya('Refreshing OAuth token for ' .. account_name .. '...', notify.categories.STATUS)
      
      oauth.refresh_token(account_name, function(success, error)
        if success then
          notify.himalaya('OAuth token refreshed successfully', notify.categories.USER_ACTION)
        else
          notify.himalaya('Failed to refresh OAuth token: ' .. (error or 'unknown error'), notify.categories.ERROR)
        end
      end)
    end,
    opts = {
      desc = 'Refresh OAuth token'
    }
  }
  
  commands.HimalayaRefreshOAuth = {
    fn = function()
      -- Just alias to HimalayaOAuthRefresh for backward compatibility
      vim.cmd('HimalayaOAuthRefresh')
    end,
    opts = {
      desc = 'Refresh OAuth token (alias)'
    }
  }
  
  -- Register all sync commands
  registry.register_batch(commands)
end

return M