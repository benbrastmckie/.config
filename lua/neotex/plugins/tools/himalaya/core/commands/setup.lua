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
      local wizard = require('neotex.plugins.tools.himalaya.setup.wizard')
      wizard.delete_all_mailboxes()
    end,
    opts = {
      desc = 'Delete all mailboxes (with optional backup)'
    }
  }
  
  commands.HimalayaRecreateFolders = {
    fn = function()
      local wizard = require('neotex.plugins.tools.himalaya.setup.wizard')
      wizard.recreate_folders()
    end,
    opts = {
      desc = 'Recreate empty folder structure'
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
  
  commands.HimalayaTestPhase8 = {
    fn = function()
      -- Force reload to ensure we get the latest version
      package.loaded['neotex.plugins.tools.himalaya.scripts.test_phase8'] = nil
      local test_phase8 = require('neotex.plugins.tools.himalaya.scripts.test_phase8')
      test_phase8.interactive_test()
    end,
    opts = {
      desc = 'Interactive Phase 8 feature testing'
    }
  }
  
  commands.HimalayaDemoPhase8 = {
    fn = function()
      package.loaded['neotex.plugins.tools.himalaya.scripts.demo_phase8'] = nil
      local demo = require('neotex.plugins.tools.himalaya.scripts.demo_phase8')
      demo.demo()
    end,
    opts = {
      desc = 'Show Phase 8 feature demo and usage'
    }
  }
  
  commands.HimalayaTestPhase9 = {
    fn = function()
      -- Force reload to ensure we get the latest version
      package.loaded['neotex.plugins.tools.himalaya.scripts.test_phase9'] = nil
      local test_phase9 = require('neotex.plugins.tools.himalaya.scripts.test_phase9')
      test_phase9.run_all_tests()
    end,
    opts = {
      desc = 'Test Phase 9 features (advanced functionality)'
    }
  }
  
  commands.HimalayaDemoPhase9 = {
    fn = function()
      package.loaded['neotex.plugins.tools.himalaya.scripts.demo_phase9'] = nil
      local demo = require('neotex.plugins.tools.himalaya.scripts.demo_phase9')
      demo.demo()
    end,
    opts = {
      desc = 'Show Phase 9 feature demo and usage'
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
  
  -- Old draft migration removed - use HimalayaMigrateDraftsToMaildir instead
  --[[
  commands.HimalayaMigrateDrafts = {
    fn = function()
      local migration = require('neotex.plugins.tools.himalaya.core.draft_migration')
      local notify = require('neotex.util.notifications')
      if migration.needs_migration() then
        local count = migration.migrate_eml_to_json()
        notify.himalaya(
          string.format('Migrated %d drafts to JSON format', count),
          notify.categories.USER_ACTION
        )
      else
        notify.himalaya('All drafts already in JSON format', notify.categories.STATUS)
      end
    end,
    opts = {
      desc = 'Migrate EML drafts to JSON format'
    }
  }
  --]]
  
  -- Draft account fix removed - Maildir drafts use standard account handling
  --[[
  commands.HimalayaFixDraftAccounts = {
    fn = function()
      local fix = require('neotex.plugins.tools.himalaya.core.draft_account_fix')
      fix.fix_draft_accounts()
    end,
    opts = {
      desc = 'Fix draft accounts (update default to current account)'
    }
  }
  --]]
  
  -- Draft cleanup command removed - use standard file management for Maildir drafts
  --[[
  commands.HimalayaCleanupDrafts = {
    fn = function()
      local cleanup = require('neotex.plugins.tools.himalaya.core.draft_cleanup')
      vim.ui.select({
        'Clean up ALL drafts',
        'Clean up empty drafts only',
        'Clean up drafts older than 7 days',
        'NUCLEAR cleanup (remove everything)',
        'Cancel'
      }, {
        prompt = 'Choose cleanup option:',
        format_item = function(item)
          if item:match('ALL') then
            return '🗑️  ' .. item
          elseif item:match('empty') then
            return '📭 ' .. item
          elseif item:match('older') then
            return '📅 ' .. item
          elseif item:match('NUCLEAR') then
            return '☢️  ' .. item
          else
            return '❌ ' .. item
          end
        end
      }, function(choice)
        if choice == 'Clean up ALL drafts' then
          vim.ui.select({'Yes', 'No'}, {
            prompt = 'Are you sure you want to delete ALL drafts?',
            kind = 'confirmation'
          }, function(confirm)
            if confirm == 'Yes' then
              cleanup.cleanup_all_drafts()
            end
          end)
        elseif choice == 'Clean up empty drafts only' then
          cleanup.cleanup_empty_drafts()
        elseif choice == 'Clean up drafts older than 7 days' then
          cleanup.cleanup_old_drafts(7)
        elseif choice == 'NUCLEAR cleanup (remove everything)' then
          vim.ui.select({'Yes, DELETE EVERYTHING', 'No'}, {
            prompt = '⚠️  WARNING: This will delete ALL draft files. Are you SURE?',
            kind = 'confirmation'
          }, function(confirm)
            if confirm == 'Yes, DELETE EVERYTHING' then
              local nuclear = require('neotex.plugins.tools.himalaya.core.draft_nuclear')
              nuclear.nuclear_cleanup()
            end
          end)
        end
      end)
    end,
    opts = {
      desc = 'Clean up local drafts'
    }
  }
  --]]
  
  -- Register all setup commands
  registry.register_batch(commands)
end

return M