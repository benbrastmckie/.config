-- Himalaya Email Commands
-- Commands related to email operations (compose, send, trash, etc.)

local M = {}

function M.setup(registry)
  local commands = {}
  
  -- Email composition commands
  commands.HimalayaWrite = {
    fn = function(opts)
      local ui = require('neotex.plugins.tools.himalaya.ui')
      ui.compose_email(opts.args)
    end,
    opts = {
      nargs = '?',
      desc = 'Compose new email'
    }
  }
  
  commands.HimalayaSend = {
    fn = function()
      local send = require('neotex.plugins.tools.himalaya.email.send')
      send.send_email()
    end,
    opts = {
      desc = 'Send current email'
    }
  }
  
  commands.HimalayaSaveDraft = {
    fn = function()
      local compose = require('neotex.plugins.tools.himalaya.ui.compose')
      compose.save_draft()
    end,
    opts = {
      desc = 'Save current email as draft'
    }
  }
  
  commands.HimalayaDiscard = {
    fn = function()
      local compose = require('neotex.plugins.tools.himalaya.ui.compose')
      compose.discard_draft()
    end,
    opts = {
      desc = 'Discard current draft'
    }
  }
  
  -- Email management commands
  commands.HimalayaTrash = {
    fn = function()
      local ui = require('neotex.plugins.tools.himalaya.ui')
      ui.trash_email()
    end,
    opts = {
      desc = 'Move selected email to trash'
    }
  }
  
  commands.HimalayaTrashStats = {
    fn = function()
      local trash = require('neotex.plugins.tools.himalaya.email.trash')
      local float = require('neotex.plugins.tools.himalaya.ui.float')
      
      local stats = trash.get_stats()
      
      local lines = {
        "# Trash Statistics",
        "",
        string.format("Total emails in trash: %d", stats.total),
        string.format("Recoverable emails: %d", stats.recoverable),
        string.format("Permanently deleted: %d", stats.deleted),
        "",
        "## By Account",
        ""
      }
      
      for account, count in pairs(stats.by_account) do
        table.insert(lines, string.format("  %s: %d", account, count))
      end
      
      if stats.oldest_date then
        table.insert(lines, "")
        table.insert(lines, string.format("Oldest email: %s", os.date("%Y-%m-%d", stats.oldest_date)))
      end
      
      float.show('Trash Statistics', lines)
    end,
    opts = {
      desc = 'Show trash statistics'
    }
  }
  
  -- Register all email commands
  registry.register_batch(commands)
end

return M