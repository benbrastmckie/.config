-- Himalaya Sync Commands
-- Commands for email synchronization and OAuth management

local M = {}

function M.setup(registry)
  local commands = {}
  
  -- Core dependencies
  local state = require('neotex.plugins.tools.himalaya.core.state')
  local logger = require('neotex.plugins.tools.himalaya.core.logger')
  local config = require('neotex.plugins.tools.himalaya.core.config')
  local mbsync = require('neotex.plugins.tools.himalaya.sync.mbsync')
  local oauth = require('neotex.plugins.tools.himalaya.sync.oauth')
  local manager = require('neotex.plugins.tools.himalaya.sync.manager')
  
  -- ======================
  -- Sync Operations
  -- ======================
  
  commands.HimalayaSyncInbox = {
    fn = function()
      local main = require('neotex.plugins.tools.himalaya.ui.main')
      main.sync_inbox()
    end,
    opts = {
      desc = 'Sync inbox folder only'
    }
  }
  
  commands.HimalayaSyncFull = {
    fn = function()
      local main = require('neotex.plugins.tools.himalaya.ui.main')
      main.sync_all()
    end,
    opts = {
      desc = 'Full sync of all folders'
    }
  }
  
  commands.HimalayaCancelSync = {
    fn = function()
      local notify = require('neotex.util.notifications')
      
      if manager.can_cancel_sync() then
        local cancelled = manager.cancel_sync()
        if cancelled then
          notify.himalaya('Sync cancelled', notify.categories.USER_ACTION)
        else
          notify.himalaya('Failed to cancel sync', notify.categories.ERROR)
        end
      else
        notify.himalaya('No sync is running', notify.categories.INFO)
      end
    end,
    opts = {
      desc = 'Cancel running sync operation'
    }
  }
  
  commands.HimalayaSyncStatus = {
    fn = function()
      local status = mbsync.get_status()
      local float = require('neotex.plugins.tools.himalaya.ui.float')
      
      local lines = {
        '# Sync Status',
        '',
        string.format('Status: %s', status.running and 'Running' or 'Idle'),
      }
      
      if status.last_sync then
        local time_ago = os.time() - status.last_sync
        local time_str = string.format('%d minutes ago', math.floor(time_ago / 60))
        table.insert(lines, string.format('Last sync: %s', time_str))
      else
        table.insert(lines, 'Last sync: Never')
      end
      
      if status.last_error then
        table.insert(lines, '')
        table.insert(lines, 'Last error:')
        table.insert(lines, '  ' .. status.last_error)
      end
      
      if status.progress then
        table.insert(lines, '')
        table.insert(lines, '## Progress')
        table.insert(lines, string.format('Operation: %s', status.progress.current_operation or 'Unknown'))
        
        if status.progress.current_folder then
          table.insert(lines, string.format('Folder: %s', status.progress.current_folder))
        end
        
        if status.progress.folders_total > 0 then
          table.insert(lines, string.format('Folders: %d/%d', 
            status.progress.folders_done, status.progress.folders_total))
        end
        
        if status.progress.messages_total > 0 then
          table.insert(lines, string.format('Messages: %d/%d', 
            status.progress.messages_processed, status.progress.messages_total))
        end
      end
      
      float.show('Sync Status', lines)
    end,
    opts = {
      desc = 'Show sync status'
    }
  }
  
  commands.HimalayaSyncInfo = {
    fn = function()
      local info = manager.get_sync_info()
      local history = manager.get_history()
      local float = require('neotex.plugins.tools.himalaya.ui.float')
      
      local lines = {
        '# Sync Information',
        '',
        string.format('Current status: %s', info.status),
      }
      
      if info.type then
        table.insert(lines, string.format('Sync type: %s', info.type))
      end
      
      if info.start_time then
        local duration = (info.end_time or os.time()) - info.start_time
        table.insert(lines, string.format('Duration: %d seconds', duration))
      end
      
      -- History
      table.insert(lines, '')
      table.insert(lines, '## History')
      
      if history.last_full_sync then
        local time_ago = os.time() - history.last_full_sync
        table.insert(lines, string.format('Last full sync: %d minutes ago', 
          math.floor(time_ago / 60)))
      end
      
      table.insert(lines, string.format('Syncs today: %d', 
        history.total_syncs_today or 0))
      
      if history.last_error then
        table.insert(lines, '')
        table.insert(lines, '## Last Error')
        table.insert(lines, history.last_error)
        if history.last_error_time then
          local time_ago = os.time() - history.last_error_time
          table.insert(lines, string.format('(%d minutes ago)', 
            math.floor(time_ago / 60)))
        end
      end
      
      float.show('Sync Information', lines)
    end,
    opts = {
      desc = 'Show detailed sync information'
    }
  }
  
  -- ======================
  -- Auto-sync Operations
  -- ======================
  
  commands.HimalayaAutoSyncToggle = {
    fn = function()
      local notify = require('neotex.util.notifications')
      
      if manager.is_auto_sync_running() then
        manager.stop_auto_sync()
        state.set('ui.auto_sync_enabled', false)
        notify.himalaya('Auto-sync disabled', notify.categories.USER_ACTION)
      else
        manager.start_auto_sync()
        state.set('ui.auto_sync_enabled', true)
        notify.himalaya('Auto-sync enabled', notify.categories.USER_ACTION)
      end
    end,
    opts = {
      desc = 'Toggle automatic inbox syncing'
    }
  }
  
  -- ======================
  -- OAuth Operations
  -- ======================
  
  commands.HimalayaOAuthRefresh = {
    fn = function()
      local notify = require('neotex.util.notifications')
      
      notify.himalaya('Refreshing OAuth token...', notify.categories.STATUS)
      
      oauth.refresh(nil, function(success, error_msg)
        if success then
          notify.himalaya('OAuth token refreshed successfully', notify.categories.SUCCESS)
        else
          notify.himalaya(
            'Failed to refresh OAuth token: ' .. (error_msg or 'unknown error'),
            notify.categories.ERROR
          )
        end
      end)
    end,
    opts = {
      desc = 'Manually refresh OAuth token'
    }
  }
  
  -- Alias for backward compatibility
  commands.HimalayaRefreshOAuth = commands.HimalayaOAuthRefresh
  
  -- Register all commands
  registry.register_batch(commands)
end

return M