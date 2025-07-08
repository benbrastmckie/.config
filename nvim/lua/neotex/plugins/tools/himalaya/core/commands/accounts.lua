-- Himalaya Account Commands
-- Commands for multi-account management and views

local M = {}

function M.setup(registry)
  local commands = {}
  
  -- Switch to unified inbox view
  commands.HimalayaUnifiedInbox = {
    fn = function()
      local multi_account = require('neotex.plugins.tools.himalaya.ui.multi_account')
      multi_account.setup()
      multi_account.create_view(multi_account.modes.UNIFIED)
    end,
    opts = {
      desc = 'Show unified inbox for all accounts'
    }
  }
  
  -- Switch to split view
  commands.HimalayaSplitView = {
    fn = function()
      local multi_account = require('neotex.plugins.tools.himalaya.ui.multi_account')
      multi_account.setup()
      multi_account.create_view(multi_account.modes.SPLIT)
    end,
    opts = {
      desc = 'Show accounts in split windows'
    }
  }
  
  -- Switch to tabbed view
  commands.HimalayaTabbedView = {
    fn = function()
      local multi_account = require('neotex.plugins.tools.himalaya.ui.multi_account')
      multi_account.setup()
      multi_account.create_view(multi_account.modes.TABBED)
    end,
    opts = {
      desc = 'Show accounts in tabs'
    }
  }
  
  -- Switch to focused view (single account)
  commands.HimalayaFocusedView = {
    fn = function()
      local multi_account = require('neotex.plugins.tools.himalaya.ui.multi_account')
      multi_account.setup()
      multi_account.create_view(multi_account.modes.FOCUSED)
    end,
    opts = {
      desc = 'Show single account view'
    }
  }
  
  -- Toggle between view modes
  commands.HimalayaToggleView = {
    fn = function()
      local multi_account = require('neotex.plugins.tools.himalaya.ui.multi_account')
      multi_account.setup()
      multi_account.toggle_mode()
    end,
    opts = {
      desc = 'Toggle between account view modes'
    }
  }
  
  -- Switch to next account
  commands.HimalayaNextAccount = {
    fn = function()
      local multi_account = require('neotex.plugins.tools.himalaya.ui.multi_account')
      multi_account.next_account()
    end,
    opts = {
      desc = 'Switch to next account'
    }
  }
  
  -- Switch to previous account
  commands.HimalayaPreviousAccount = {
    fn = function()
      local multi_account = require('neotex.plugins.tools.himalaya.ui.multi_account')
      multi_account.previous_account()
    end,
    opts = {
      desc = 'Switch to previous account'
    }
  }
  
  -- Refresh all account views
  commands.HimalayaRefreshAccounts = {
    fn = function()
      local multi_account = require('neotex.plugins.tools.himalaya.ui.multi_account')
      multi_account.refresh_all()
    end,
    opts = {
      desc = 'Refresh all account views'
    }
  }
  
  -- Show account status
  commands.HimalayaAccountStatus = {
    fn = function()
      local config = require('neotex.plugins.tools.himalaya.core.config')
      local float = require('neotex.plugins.tools.himalaya.ui.float')
      local multi_account = require('neotex.plugins.tools.himalaya.ui.multi_account')
      
      multi_account.setup()
      
      local lines = {
        '# Himalaya Account Status',
        '',
        '## Configured Accounts'
      }
      
      local accounts = config.get('accounts', {})
      local i = 1
      for name, account in pairs(accounts) do
        table.insert(lines, string.format('%d. **%s** - %s', i, name, account.email or 'No email'))
        i = i + 1
      end
      
      table.insert(lines, '')
      table.insert(lines, '## Current View Mode')
      table.insert(lines, '  Mode: ' .. multi_account.get_current_mode())
      table.insert(lines, '  Active Accounts: ' .. vim.tbl_count(multi_account.state.active_accounts))
      
      float.show('Account Status', lines)
    end,
    opts = {
      desc = 'Show account configuration status'
    }
  }
  
  -- Register all account commands
  registry.register_batch(commands)
end

return M