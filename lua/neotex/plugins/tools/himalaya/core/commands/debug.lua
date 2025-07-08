-- Himalaya Debug Commands
-- Commands for debugging and diagnostics

local M = {}

function M.setup(registry)
  local commands = {}
  
  -- Debug commands
  commands.HimalayaDebug = {
    fn = function()
      local config = require('neotex.plugins.tools.himalaya.core.config')
      local state = require('neotex.plugins.tools.himalaya.core.state')
      local float = require('neotex.plugins.tools.himalaya.ui.float')
      
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
      local state = require('neotex.plugins.tools.himalaya.core.state')
      local float = require('neotex.plugins.tools.himalaya.ui.float')
      
      -- Get full state as JSON
      local state_data = state._state or {}
      local json = vim.fn.json_encode(state_data)
      
      -- Pretty print JSON
      local lines = {}
      local formatted = vim.fn.system('echo ' .. vim.fn.shellescape(json) .. ' | jq . 2>/dev/null')
      
      if vim.v.shell_error == 0 and formatted ~= '' then
        lines = vim.split(formatted, '\n')
      else
        -- Fallback to raw JSON if jq not available
        lines = vim.split(json, '\n')
      end
      
      float.show('State JSON', lines)
    end,
    opts = {
      desc = 'Show state as JSON'
    }
  }
  
  commands.HimalayaDebugSyncState = {
    fn = function()
      local state = require('neotex.plugins.tools.himalaya.core.state')
      local sync_manager = require('neotex.plugins.tools.himalaya.sync.manager')
      local lock = require('neotex.plugins.tools.himalaya.sync.lock')
      local float = require('neotex.plugins.tools.himalaya.ui.float')
      
      local lines = {'# Sync Debug Information', ''}
      
      -- Sync manager status
      local status = sync_manager.get_status()
      table.insert(lines, '## Sync Manager Status')
      table.insert(lines, string.format('  Is syncing: %s', status.is_syncing and 'Yes' or 'No'))
      if status.sync_type then
        table.insert(lines, string.format('  Sync type: %s', status.sync_type))
      end
      if status.account then
        table.insert(lines, string.format('  Account: %s', status.account))
      end
      
      -- State info
      table.insert(lines, '')
      table.insert(lines, '## State Information')
      table.insert(lines, string.format('  sync.is_syncing: %s', tostring(state.get('sync.is_syncing'))))
      table.insert(lines, string.format('  sync.current_channel: %s', state.get('sync.current_channel') or 'none'))
      
      local last_sync = state.get('sync.last_sync')
      if last_sync then
        local ago = os.time() - last_sync
        table.insert(lines, string.format('  Last sync: %d seconds ago', ago))
      end
      
      -- Lock files
      table.insert(lines, '')
      table.insert(lines, '## Lock Files')
      local active_locks = lock.get_active_locks()
      if #active_locks > 0 then
        for _, lock_info in ipairs(active_locks) do
          table.insert(lines, '  - ' .. lock_info)
        end
      else
        table.insert(lines, '  No active locks')
      end
      
      -- Running processes
      table.insert(lines, '')
      table.insert(lines, '## Running Processes')
      local handle = io.popen('pgrep -f mbsync 2>/dev/null')
      if handle then
        local pids = handle:read('*a')
        handle:close()
        if pids and pids ~= '' then
          for pid in pids:gmatch('%d+') do
            table.insert(lines, '  - PID: ' .. pid)
          end
        else
          table.insert(lines, '  No mbsync processes running')
        end
      end
      
      float.show('Sync Debug Information', lines)
    end,
    opts = {
      desc = 'Debug sync state'
    }
  }
  
  commands.HimalayaDebugCount = {
    fn = function()
      local config = require('neotex.plugins.tools.himalaya.core.config')
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
      desc = 'Debug email counts'
    }
  }
  
  commands.HimalayaLogs = {
    fn = function()
      -- Create a new buffer for logs
      vim.cmd('new')
      local buf = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
      vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
      vim.api.nvim_buf_set_option(buf, 'filetype', 'log')
      vim.api.nvim_buf_set_name(buf, 'Himalaya Logs')
      
      -- Capture messages
      local messages = vim.fn.execute('messages')
      local lines = vim.split(messages, '\n')
      
      -- Filter for Himalaya and STARTUP DEBUG messages
      local filtered_lines = {}
      for _, line in ipairs(lines) do
        if line:match('Himalaya') or line:match('STARTUP DEBUG') then
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
  
  -- Register all debug commands
  registry.register_batch(commands)
end

return M