-- Himalaya Utility Commands
-- Consolidated module for setup, debug, maintenance, and testing operations

local M = {}

function M.setup(registry)
  local commands = {}
  
  -- Core dependencies
  local state = require('neotex.plugins.tools.himalaya.core.state')
  local logger = require('neotex.plugins.tools.himalaya.core.logger')
  local config = require('neotex.plugins.tools.himalaya.core.config')
  local async_commands = require('neotex.plugins.tools.himalaya.core.async_commands')
  
  -- ======================
  -- Setup & Configuration
  -- ======================
  
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
      health.check()
    end,
    opts = {
      desc = 'Check Himalaya health status'
    }
  }
  
  commands.HimalayaMigrate = {
    fn = function()
      local migration = require('neotex.plugins.tools.himalaya.setup.migration')
      migration.run()
    end,
    opts = {
      desc = 'Run Himalaya data migration'
    }
  }
  
  commands.HimalayaCleanup = {
    fn = function()
      local cleanup = require('neotex.plugins.tools.himalaya.setup.cleanup')
      cleanup.run()
    end,
    opts = {
      desc = 'Clean up Himalaya temporary files'
    }
  }
  
  commands.HimalayaBackupAndFresh = {
    fn = function()
      local notify = require('neotex.util.notifications')
      
      vim.ui.select({'Yes', 'No'}, {
        prompt = 'Backup current state and start fresh? This will reset all Himalaya data.'
      }, function(choice)
        if choice == 'Yes' then
          local backup_dir = vim.fn.stdpath('data') .. '/himalaya_backup_' .. os.time()
          local data_dir = vim.fn.stdpath('data') .. '/himalaya'
          
          -- Create backup
          vim.fn.system('cp -r ' .. vim.fn.shellescape(data_dir) .. ' ' .. vim.fn.shellescape(backup_dir))
          
          -- Remove current data
          vim.fn.system('rm -rf ' .. vim.fn.shellescape(data_dir))
          
          -- Reset state
          state.reset()
          
          notify.himalaya(
            string.format('Backup created at: %s', backup_dir),
            notify.categories.SUCCESS
          )
        end
      end)
    end,
    opts = {
      desc = 'Backup current data and start fresh'
    }
  }
  
  -- ======================
  -- Debug Operations
  -- ======================
  
  commands.HimalayaDebug = {
    fn = function()
      local float = require('neotex.plugins.tools.himalaya.ui.float')
      
      -- Get async status and metrics
      local async_status = async_commands.get_status()
      local async_metrics = async_commands.get_metrics()
      
      local lines = {
        '# Himalaya Debug Information',
        '',
        '## Configuration',
        string.format('  Config initialized: %s', config.is_initialized() and 'Yes' or 'No'),
        string.format('  Current account: %s', config.get_current_account_name() or 'none'),
        '',
        '## State',
        string.format('  State file: %s', vim.fn.stdpath('data') .. '/himalaya_state.json'),
        string.format('  Current folder: %s', state.get('current_folder') or 'INBOX'),
        string.format('  Is syncing: %s', state.get('sync.is_syncing') and 'Yes' or 'No'),
        '',
        '## Async Commands',
        string.format('  Debug mode: %s', async_commands.debug_mode and 'On' or 'Off'),
        string.format('  Running jobs: %d', async_status.running_jobs),
        string.format('  Queued jobs: %d', async_status.queued_jobs),
        string.format('  Max concurrent: %d', async_status.max_concurrent),
        '',
        '## Async Metrics',
        string.format('  Total jobs: %d', async_metrics.total_jobs),
        string.format('  Success rate: %d%%', async_metrics.success_rate),
        string.format('  Lock conflicts: %d', async_metrics.lock_conflicts),
        string.format('  Retries: %d', async_metrics.retry_count),
        string.format('  Avg duration: %ds', async_metrics.average_duration),
        '',
        '## Paths',
        string.format('  Himalaya binary: %s', config.config.binaries.himalaya),
        string.format('  Mbsync binary: %s', config.config.binaries.mbsync),
      }
      
      local account = config.get_current_account()
      if account then
        table.insert(lines, '')
        table.insert(lines, '## Account Details')
        table.insert(lines, string.format('  Name: %s', account.name or 'default'))
        table.insert(lines, string.format('  Email: %s', account.email or 'not set'))
        table.insert(lines, string.format('  Maildir: %s', account.maildir_path or 'not set'))
      end
      
      float.show('Debug Information', lines)
    end,
    opts = {
      desc = 'Show debug information'
    }
  }
  
  commands.HimalayaDebugJson = {
    fn = function()
      local data = {
        config = {
          initialized = config.is_initialized(),
          current_account = config.get_current_account_name(),
          accounts = vim.tbl_map(function(acc) return acc.name end, config.get_accounts() or {})
        },
        state = {
          current_folder = state.get('current_folder'),
          is_syncing = state.get('sync.is_syncing'),
          last_sync = state.get('sync.last_sync')
        },
        paths = {
          himalaya = config.config.binaries.himalaya,
          mbsync = config.config.binaries.mbsync,
          state_file = vim.fn.stdpath('data') .. '/himalaya_state.json'
        }
      }
      
      -- Create a new buffer with JSON
      local buf = vim.api.nvim_create_buf(false, true)
      local json_str = vim.fn.json_encode(data)
      local lines = vim.split(json_str, '\n')
      
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(buf, 'filetype', 'json')
      vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
      vim.api.nvim_buf_set_name(buf, 'Himalaya Debug JSON')
      
      -- Open in new window
      vim.cmd('split')
      vim.api.nvim_win_set_buf(0, buf)
    end,
    opts = {
      desc = 'Show debug information as JSON'
    }
  }
  
  commands.HimalayaLogs = {
    fn = function()
      -- Create new buffer for logs
      local buf = vim.api.nvim_create_buf(false, true)
      
      vim.cmd('split')
      vim.api.nvim_win_set_buf(0, buf)
      vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
      vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
      vim.api.nvim_buf_set_option(buf, 'filetype', 'log')
      vim.api.nvim_buf_set_name(buf, 'Himalaya Logs')
      
      -- Capture messages
      local messages = vim.fn.execute('messages')
      local lines = vim.split(messages, '\n')
      
      -- Filter for Himalaya messages
      local filtered_lines = {}
      for _, line in ipairs(lines) do
        if line:match('Himalaya') or line:match('STARTUP DEBUG') or line:match('ASYNC') then
          table.insert(filtered_lines, line)
        end
      end
      
      -- Set content
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, filtered_lines)
      
      -- Set readonly
      vim.api.nvim_buf_set_option(buf, 'modifiable', false)
      
      -- Add keymaps
      vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':bd<CR>', { noremap = true, silent = true })
      vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':bd<CR>', { noremap = true, silent = true })
    end,
    opts = {
      desc = 'Show Himalaya logs'
    }
  }
  
  -- ======================
  -- Async Debug Commands
  -- ======================
  
  commands.HimalayaAsyncDebugOn = {
    fn = function()
      local notify = require('neotex.util.notifications')
      async_commands.set_debug_mode(true)
      notify.himalaya('Async debug mode enabled', notify.categories.STATUS)
    end,
    opts = {
      desc = 'Enable async commands debug mode'
    }
  }
  
  commands.HimalayaAsyncDebugOff = {
    fn = function()
      local notify = require('neotex.util.notifications')
      async_commands.set_debug_mode(false)
      notify.himalaya('Async debug mode disabled', notify.categories.STATUS)
    end,
    opts = {
      desc = 'Disable async commands debug mode'
    }
  }
  
  commands.HimalayaAsyncStatus = {
    fn = function()
      local float = require('neotex.plugins.tools.himalaya.ui.float')
      
      local status = async_commands.get_status()
      local metrics = async_commands.get_metrics()
      
      local lines = {
        '# Async Commands Status',
        '',
        '## Current Status',
        string.format('  Running jobs: %d', status.running_jobs),
        string.format('  Queued jobs: %d', status.queued_jobs),
        string.format('  Max concurrent: %d', status.max_concurrent),
        string.format('  Can start new: %s', status.can_start_new and 'Yes' or 'No'),
        '',
        '## Metrics',
        string.format('  Total jobs: %d', metrics.total_jobs),
        string.format('  Successful: %d', metrics.successful_jobs),
        string.format('  Failed: %d', metrics.failed_jobs),
        string.format('  Success rate: %d%%', metrics.success_rate),
        string.format('  Lock conflicts: %d', metrics.lock_conflicts),
        string.format('  Retries: %d', metrics.retry_count),
        string.format('  Average duration: %ds', metrics.average_duration),
      }
      
      -- Add running job details if in debug mode
      if #status.running_details > 0 then
        table.insert(lines, '')
        table.insert(lines, '## Running Jobs')
        for _, job in ipairs(status.running_details) do
          table.insert(lines, string.format('  [%s] %s (running for %ds)', 
            job.id, job.command, job.duration))
        end
      end
      
      float.show('Async Commands Status', lines)
    end,
    opts = {
      desc = 'Show async commands status and metrics'
    }
  }
  
  commands.HimalayaAsyncResetMetrics = {
    fn = function()
      local notify = require('neotex.util.notifications')
      async_commands.reset_metrics()
      notify.himalaya('Async metrics reset', notify.categories.STATUS)
    end,
    opts = {
      desc = 'Reset async commands metrics'
    }
  }
  
  -- ======================
  -- Test Commands
  -- ======================
  
  commands.HimalayaTest = {
    fn = function(opts)
      -- Initialize test runner if not already done
      local test_runner = require('neotex.plugins.tools.himalaya.test.test_runner')
      if not test_runner.tests.commands or #test_runner.tests.commands == 0 then
        test_runner.setup()
      end
      
      -- Run with picker or specific test
      test_runner.run_with_picker(opts.args)
    end,
    opts = {
      nargs = '?',
      complete = function()
        local test_runner = require('neotex.plugins.tools.himalaya.test.test_runner')
        return test_runner.get_test_completions()
      end,
      desc = 'Run Himalaya tests with picker interface'
    }
  }
  
  commands.HimalayaTestCommands = {
    fn = function()
      local notify = require('neotex.util.notifications')
      
      -- Test basic commands
      local test_cmds = {
        'HimalayaDebug',
        'HimalayaAsyncStatus',
        'HimalayaFolderCounts'
      }
      
      local failed = {}
      for _, cmd in ipairs(test_cmds) do
        local ok = pcall(vim.cmd, cmd)
        if not ok then
          table.insert(failed, cmd)
        end
      end
      
      if #failed == 0 then
        notify.himalaya('All basic commands working', notify.categories.SUCCESS)
      else
        notify.himalaya(
          string.format('%d commands failed: %s', #failed, table.concat(failed, ', ')),
          notify.categories.ERROR
        )
      end
    end,
    opts = {
      desc = 'Test basic Himalaya commands'
    }
  }
  
  commands.HimalayaTestNotify = {
    fn = function()
      local notify = require('neotex.util.notifications')
      
      -- Test all notification types
      notify.himalaya('Test info notification', notify.categories.INFO)
      vim.defer_fn(function()
        notify.himalaya('Test success notification', notify.categories.SUCCESS)
      end, 500)
      vim.defer_fn(function()
        notify.himalaya('Test warning notification', notify.categories.WARNING)
      end, 1000)
      vim.defer_fn(function()
        notify.himalaya('Test error notification', notify.categories.ERROR)
      end, 1500)
    end,
    opts = {
      desc = 'Test notification system'
    }
  }
  
  -- ======================
  -- Maintenance Commands
  -- ======================
  
  commands.HimalayaClearScheduled = {
    fn = function()
      local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
      local persistence = require('neotex.plugins.tools.himalaya.core.persistence')
      local notify = require('neotex.util.notifications')
      
      -- Stop scheduler
      if scheduler.timer then
        scheduler.stop_processing()
      end
      
      -- Count emails before clearing
      local count = vim.tbl_count(scheduler.queue)
      
      -- Clear queue
      scheduler.queue = {}
      
      -- Save empty queue to disk
      persistence.save_queue({})
      
      notify.himalaya(
        string.format('Cleared %d scheduled emails', count),
        notify.categories.STATUS
      )
    end,
    opts = {
      desc = 'Clear all scheduled emails'
    }
  }
  
  commands.HimalayaRecreateFolders = {
    fn = function()
      local notify = require('neotex.util.notifications')
      local account = config.get_current_account()
      
      if not account or not account.maildir_path then
        notify.himalaya('No maildir account configured', notify.categories.ERROR)
        return
      end
      
      local maildir = vim.fn.expand(account.maildir_path)
      local folders = {
        { name = 'INBOX', path = maildir },
        { name = 'Sent', path = maildir .. '.Sent' },
        { name = 'Drafts', path = maildir .. '.Drafts' },
        { name = 'Trash', path = maildir .. '.Trash' },
      }
      
      local created = 0
      for _, folder in ipairs(folders) do
        -- Create cur, new, tmp subdirectories
        for _, subdir in ipairs({'cur', 'new', 'tmp'}) do
          local path = folder.path .. '/' .. subdir
          if vim.fn.isdirectory(path) == 0 then
            vim.fn.mkdir(path, 'p')
            created = created + 1
          end
        end
      end
      
      notify.himalaya(
        string.format('Created %d missing directories', created),
        notify.categories.SUCCESS
      )
    end,
    opts = {
      desc = 'Recreate missing maildir folders'
    }
  }
  
  commands.HimalayaFixCommon = {
    fn = function()
      local fixes = require('neotex.plugins.tools.himalaya.setup.fixes')
      fixes.run_common_fixes()
    end,
    opts = {
      desc = 'Run common fixes for known issues'
    }
  }
  
  -- ======================
  -- Migration Commands
  -- ======================
  
  commands.HimalayaMigrateDrafts = {
    fn = function()
      local migration = require('neotex.plugins.tools.himalaya.commands.migrate_drafts')
      migration.migrate_drafts()
    end,
    opts = {
      desc = 'Migrate drafts to maildir format'
    }
  }
  
  commands.HimalayaMigrateDraftsToMaildir = {
    fn = function()
      local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_maildir')
      local notify = require('neotex.util.notifications')
      
      notify.himalaya('Starting draft migration...', notify.categories.STATUS)
      
      local results = draft_manager.sync_all_drafts()
      
      notify.himalaya(
        string.format('Migration complete: %d synced, %d errors', 
          results.synced, results.errors),
        results.errors == 0 and notify.categories.SUCCESS or notify.categories.WARNING
      )
      
      if results.error_details and #results.error_details > 0 then
        for _, err in ipairs(results.error_details) do
          logger.error('Migration error: ' .. err)
        end
      end
    end,
    opts = {
      desc = 'Migrate all drafts to maildir format'
    }
  }
  
  commands.HimalayaDraftMigrationVerify = {
    fn = function()
      local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_maildir')
      local float = require('neotex.plugins.tools.himalaya.ui.float')
      
      local stats = draft_manager.get_stats()
      local lines = {
        '# Draft Migration Status',
        '',
        string.format('Total drafts: %d', stats.total),
        string.format('Synced to maildir: %d', stats.synced),
        string.format('Not synced: %d', stats.unsynced),
        string.format('With errors: %d', stats.errors),
        '',
        '## Verification',
        stats.unsynced == 0 and '✓ All drafts migrated' or '✗ Some drafts not migrated',
      }
      
      if stats.unsynced > 0 then
        table.insert(lines, '')
        table.insert(lines, 'Run :HimalayaMigrateDraftsToMaildir to complete migration')
      end
      
      float.show('Migration Verification', lines)
    end,
    opts = {
      desc = 'Verify draft migration status'
    }
  }
  
  -- ======================
  -- Email Count Debug
  -- ======================
  
  commands.HimalayaDebugCount = {
    fn = function()
      local account = config.get_current_account()
      local float = require('neotex.plugins.tools.himalaya.ui.float')
      
      local lines = {'# Email Count Debug', ''}
      
      -- Get folder counts using find
      local maildir = vim.fn.expand(account.maildir_path)
      
      local folders = {
        { name = 'INBOX', path = maildir },
        { name = 'Sent', path = maildir .. '.Sent' },
        { name = 'Drafts', path = maildir .. '.Drafts' },
        { name = 'Trash', path = maildir .. '.Trash' },
      }
      
      for _, folder in ipairs(folders) do
        if vim.fn.isdirectory(folder.path .. '/cur') == 1 then
          local count_cmd = string.format('find %s -type f -name "*" | wc -l', 
            vim.fn.shellescape(folder.path .. '/cur'))
          local count = vim.fn.system(count_cmd):gsub('%s+', '')
          table.insert(lines, string.format('%s: %s emails', folder.name, count))
        else
          table.insert(lines, string.format('%s: directory not found', folder.name))
        end
      end
      
      -- Get himalaya counts for comparison
      table.insert(lines, '')
      table.insert(lines, '## Himalaya Reported Counts')
      
      local cmd = string.format('%s folder list --account %s',
        config.config.binaries.himalaya,
        account.name or 'gmail'
      )
      
      local result = vim.fn.system(cmd)
      if vim.v.shell_error == 0 then
        local himalaya_lines = vim.split(result, '\n')
        for _, line in ipairs(himalaya_lines) do
          if line:match('%d+') then
            table.insert(lines, '  ' .. line)
          end
        end
      else
        table.insert(lines, '  Error getting Himalaya counts')
      end
      
      float.show('Email Count Debug', lines)
    end,
    opts = {
      desc = 'Debug email count discrepancies'
    }
  }
  
  commands.HimalayaRefreshCount = {
    fn = function()
      local utils = require('neotex.plugins.tools.himalaya.utils')
      local notify = require('neotex.util.notifications')
      
      local account = state.get('ui.current_account')
      local folder = state.get('ui.current_folder')
      
      if not account or not folder then
        notify.himalaya('No account/folder selected', notify.categories.ERROR)
        return
      end
      
      notify.himalaya(string.format('Refreshing count for %s/%s...', account, folder), 
        notify.categories.STATUS)
      
      -- Fetch count
      utils.fetch_folder_count_async(account, folder, function(count, error)
        if error then
          notify.himalaya('Failed to fetch count: ' .. tostring(error), notify.categories.ERROR)
          return
        end
        
        if count then
          -- Force update
          state.set_folder_count(account, folder, count)
          notify.himalaya(string.format('Updated count: %d emails', count), notify.categories.STATUS)
          
          -- Trigger UI update
          local ok, manager = pcall(require, 'neotex.plugins.tools.himalaya.sync.manager')
          if ok and manager.notify_ui_update then
            manager.notify_ui_update()
          end
        end
      end)
    end,
    opts = {
      desc = 'Manually refresh current folder email count'
    }
  }
  
  -- Register all commands
  registry.register_batch(commands)
end

return M