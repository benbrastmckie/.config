-- Himalaya Setup Commands
-- Commands related to configuration, setup, and maintenance

local M = {}

function M.setup(registry)
  local commands = {}
  
  -- Setup and configuration
  commands.HimalayaSetup = {
    fn = function()
      local wizard = require('neotex.plugins.tools.himalaya.setup.wizard')
      wizard.run()
    end,
    opts = {
      desc = 'Run Himalaya setup wizard'
    }
  }
  
  commands.HimalayaHealth = {
    fn = function()
      local health = require('neotex.plugins.tools.himalaya.setup.health')
      health.show_report()
    end,
    opts = {
      desc = 'Check Himalaya health'
    }
  }
  
  commands.HimalayaMigrate = {
    fn = function()
      local migrate = require('neotex.plugins.tools.himalaya.setup.migrate')
      migrate.run()
    end,
    opts = {
      desc = 'Run state migrations'
    }
  }
  
  -- Maintenance commands
  commands.HimalayaCleanup = {
    fn = function()
      local mbsync = require('neotex.plugins.tools.himalaya.sync.mbsync')
      local lock = require('neotex.plugins.tools.himalaya.sync.lock')
      local notify = require('neotex.util.notifications')
      
      -- Kill all mbsync processes
      mbsync.kill_all()
      
      -- Clean up lock files
      local cleaned = lock.cleanup_locks()
      
      -- Clear stale state
      local state = require('neotex.plugins.tools.himalaya.core.state')
      state.set('sync.is_syncing', false)
      state.set('sync.current_channel', nil)
      
      notify.himalaya(string.format('Cleanup complete. Removed %d lock(s)', cleaned), notify.categories.USER_ACTION)
    end,
    opts = {
      desc = 'Clean up locks and processes'
    }
  }
  
  commands.HimalayaBackupAndFresh = {
    fn = function()
      local utils = require('neotex.plugins.tools.himalaya.utils')
      local config = require('neotex.plugins.tools.himalaya.core.config')
      local notify = require('neotex.util.notifications')
      
      -- Get maildir path
      local account = config.get_current_account()
      local maildir = vim.fn.expand(account.maildir_path)
      
      -- Create backup
      local backup_name = 'maildir_backup_' .. os.date('%Y%m%d_%H%M%S')
      local backup_path = vim.fn.expand('~/') .. backup_name
      
      local cmd = string.format('cp -r %s %s', vim.fn.shellescape(maildir), vim.fn.shellescape(backup_path))
      local result = vim.fn.system(cmd)
      
      if vim.v.shell_error == 0 then
        notify.himalaya('Backup created at: ' .. backup_path, notify.categories.USER_ACTION)
        
        -- Clear cache
        utils.clear_email_cache()
        
        -- Refresh UI if open
        local ui = require('neotex.plugins.tools.himalaya.ui')
        if ui.is_email_buffer_open() then
          ui.refresh_email_list()
        end
        
        notify.himalaya('Fresh start complete!', notify.categories.USER_ACTION)
      else
        notify.himalaya('Backup failed: ' .. result, notify.categories.ERROR)
      end
    end,
    opts = {
      desc = 'Backup maildir and start fresh'
    }
  }
  
  commands.HimalayaFixCommon = {
    fn = function()
      local health = require('neotex.plugins.tools.himalaya.setup.health')
      health.fix_common_issues()
    end,
    opts = {
      desc = 'Fix common issues automatically'
    }
  }
  
  commands.HimalayaFixMaildir = {
    fn = function()
      local wizard = require('neotex.plugins.tools.himalaya.setup.wizard')
      local config = require('neotex.plugins.tools.himalaya.core.config')
      local account = config.get_current_account()
      wizard.fix_uidvalidity_files(vim.fn.expand(account.maildir_path))
    end,
    opts = {
      desc = 'Fix maildir UIDVALIDITY files'
    }
  }
  
  -- Test commands
  commands.HimalayaTestCommands = {
    fn = function()
      -- Force reload to ensure we get the latest version
      package.loaded['neotex.plugins.tools.himalaya.scripts.test_commands'] = nil
      local test_suite = require('neotex.plugins.tools.himalaya.scripts.test_commands')
      test_suite.run_all_tests()
    end,
    opts = {
      desc = 'Run comprehensive command test suite'
    }
  }
  
  commands.HimalayaTestNotify = {
    fn = function()
      local notify = require('neotex.util.notifications')
      notify.himalaya('Test notification: INFO', notify.categories.STATUS)
      vim.defer_fn(function()
        notify.himalaya('Test notification: USER_ACTION', notify.categories.USER_ACTION)
      end, 1000)
      vim.defer_fn(function()
        notify.himalaya('Test notification: ERROR', notify.categories.ERROR)
      end, 2000)
      vim.defer_fn(function()
        notify.himalaya('Test notification: BACKGROUND', notify.categories.BACKGROUND)
      end, 3000)
    end,
    opts = {
      desc = 'Test notification system'
    }
  }
  
  commands.HimalayaRawTest = {
    fn = function(opts)
      local account = require('neotex.plugins.tools.himalaya.core.config').get_current_account()
      local cmd = string.format('%s %s', 
        require('neotex.plugins.tools.himalaya.core.config').config.binaries.himalaya,
        opts.args or 'envelope list --account ' .. (account.name or 'gmail') .. ' --folder INBOX'
      )
      
      local result = vim.fn.system(cmd)
      local float = require('neotex.plugins.tools.himalaya.ui.float')
      
      local lines = vim.split(result, '\n')
      float.show('Raw Himalaya Output', lines)
    end,
    opts = {
      nargs = '*',
      desc = 'Test raw Himalaya command output'
    }
  }
  
  -- Register all setup commands
  registry.register_batch(commands)
end

return M