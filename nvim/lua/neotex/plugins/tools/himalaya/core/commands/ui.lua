-- Himalaya UI Commands
-- Commands related to user interface and display

local M = {}

function M.setup(registry)
  local commands = {}
  
  -- Main UI Commands
  commands.Himalaya = {
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
  
  commands.HimalayaToggle = {
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
  
  commands.HimalayaRefresh = {
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
  
  commands.HimalayaRestore = {
    fn = function()
      local ui = require('neotex.plugins.tools.himalaya.ui')
      ui.prompt_session_restore()
    end,
    opts = {
      desc = 'Restore previous session'
    }
  }
  
  commands.HimalayaFolder = {
    fn = function()
      local main = require('neotex.plugins.tools.himalaya.ui.main')
      main.pick_folder()
    end,
    opts = {
      desc = 'Change folder'
    }
  }
  
  commands.HimalayaAccounts = {
    fn = function()
      local accounts = require('neotex.plugins.tools.himalaya.ui.accounts')
      accounts.show_account_picker()
    end,
    opts = {
      desc = 'Switch between email accounts'
    }
  }
  
  commands.HimalayaUpdateCounts = {
    fn = function()
      local counts = require('neotex.plugins.tools.himalaya.ui.counts')
      counts.update_all_folder_counts()
    end,
    opts = {
      desc = 'Update folder message counts'
    }
  }
  
  commands.HimalayaFolderCounts = {
    fn = function()
      local ui = require('neotex.plugins.tools.himalaya.ui')
      local float = require('neotex.plugins.tools.himalaya.ui.float')
      local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
      
      -- Get folder counts
      local accounts = sidebar.get_accounts()
      local lines = {}
      
      for _, account in ipairs(accounts) do
        table.insert(lines, string.format("# %s", account.display_name))
        table.insert(lines, "")
        
        for _, folder in ipairs(account.folders) do
          local count_str = ""
          if folder.count then
            count_str = string.format(" (%d)", folder.count)
          end
          table.insert(lines, string.format("  %s%s", folder.display_name, count_str))
        end
        table.insert(lines, "")
      end
      
      float.show('Folder Counts', lines)
    end,
    opts = {
      desc = 'Display folder message counts'
    }
  }
  
  -- Register all UI commands
  registry.register_batch(commands)
end

return M