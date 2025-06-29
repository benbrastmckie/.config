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
  
  -- Initialize notification system
  local notifications = require('neotex.plugins.tools.himalaya.ui.notifications')
  notifications.setup()
  
  -- Set up commands
  M.setup_commands()
  
  -- Run health check on startup if configured
  if config.config.setup.check_health_on_startup then
    vim.defer_fn(function()
      local health = require('neotex.plugins.tools.himalaya.setup.health')
      local result = health.check()
      if not result.ok then
        notifications.show_setup_hints()
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
    require('neotex.plugins.tools.himalaya.ui').show_email_list(vim.split(opts.args or '', ' '))
  end, {
    nargs = '*',
    desc = 'Open Himalaya email list',
    complete = function()
      local utils = require('neotex.plugins.tools.himalaya.utils')
      return utils.get_folders() or {}
    end
  })
  
  cmd('HimalayaWrite', function(opts)
    require('neotex.plugins.tools.himalaya.ui').compose_email(opts.args)
  end, {
    nargs = '?',
    desc = 'Compose new email'
  })
  
  -- Sync commands
  cmd('HimalayaSyncInbox', function()
    local mbsync = require('neotex.plugins.tools.himalaya.sync.mbsync')
    local notifications = require('neotex.plugins.tools.himalaya.ui.notifications')
    
    mbsync.sync_inbox({
      on_progress = notifications.show_sync_progress,
      callback = function(success, error)
        if not success then
          notifications.handle_sync_error(error)
        else
          -- Clear cache and refresh UI
          local utils = require('neotex.plugins.tools.himalaya.utils')
          utils.clear_email_cache()
          
          local ui = require('neotex.plugins.tools.himalaya.ui')
          if ui.is_email_buffer_open() then
            ui.refresh_email_list()
          end
        end
      end
    })
  end, {
    desc = 'Sync inbox only'
  })
  
  cmd('HimalayaSyncAll', function()
    local mbsync = require('neotex.plugins.tools.himalaya.sync.mbsync')
    local notifications = require('neotex.plugins.tools.himalaya.ui.notifications')
    
    mbsync.sync_all({
      on_progress = notifications.show_sync_progress,
      callback = function(success, error)
        if not success then
          notifications.handle_sync_error(error)
        else
          local utils = require('neotex.plugins.tools.himalaya.utils')
          utils.clear_email_cache()
          
          local ui = require('neotex.plugins.tools.himalaya.ui')
          if ui.is_email_buffer_open() then
            ui.refresh_email_list()
          end
        end
      end
    })
  end, {
    desc = 'Sync all folders'
  })
  
  cmd('HimalayaCancelSync', function()
    local mbsync = require('neotex.plugins.tools.himalaya.sync.mbsync')
    mbsync.stop_sync()
    
    local notify = require('neotex.util.notifications')
    notify.himalaya('Sync cancelled', notify.categories.USER_ACTION)
  end, {
    desc = 'Cancel ongoing sync'
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
  cmd('HimalayaOAuthRefresh', function()
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
    mbsync.stop_sync()
    
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
    local account = config.get_account()
    
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
end

-- Keymaps helper for which-key
function M.get_keymaps()
  return {
    ['<leader>m'] = {
      name = '+mail',
      l = { ':Himalaya<CR>', 'Email list' },
      s = { ':HimalayaSyncInbox<CR>', 'Sync inbox' },
      S = { ':HimalayaSyncAll<CR>', 'Sync all' },
      c = { ':HimalayaWrite<CR>', 'Compose' },
      h = { ':HimalayaHealth<CR>', 'Health check' },
      x = { ':HimalayaCancelSync<CR>', 'Cancel sync' },
    }
  }
end

return M