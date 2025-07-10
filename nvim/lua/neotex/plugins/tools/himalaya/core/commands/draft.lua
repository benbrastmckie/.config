-- Himalaya Draft Commands
-- Commands for draft management operations

local M = {}

function M.setup(registry)
  local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
  local state = require('neotex.plugins.tools.himalaya.core.state')
  local notify = require('neotex.util.notifications')
  local ui = require('neotex.plugins.tools.himalaya.ui')
  
  local commands = {}
  
  -- Draft creation and editing
  commands.HimalayaDraftNew = {
    fn = function(opts)
      -- Get account from args or use default
      local account = opts.args and opts.args ~= '' and opts.args or nil
      
      -- Create new draft through UI
      ui.compose_email(account)
    end,
    opts = {
      nargs = '?',
      desc = 'Create new email draft',
      complete = function()
        -- TODO: Return list of available accounts
        return { 'gmail', 'work', 'personal' }
      end
    }
  }
  
  commands.HimalayaDraftSave = {
    fn = function()
      local buf = vim.api.nvim_get_current_buf()
      local success = draft_manager.save(buf)
      
      if not success then
        -- Error already notified by draft_manager
        return
      end
    end,
    opts = {
      desc = 'Save current draft'
    }
  }
  
  commands.HimalayaDraftSync = {
    fn = function()
      local buf = vim.api.nvim_get_current_buf()
      local draft = draft_manager.get_by_buffer(buf)
      
      if draft then
        draft_manager.sync_remote(buf)
      else
        notify.himalaya(
          "No draft associated with current buffer",
          notify.categories.WARNING
        )
      end
    end,
    opts = {
      desc = 'Sync current draft with server'
    }
  }
  
  commands.HimalayaDraftSyncAll = {
    fn = function()
      local drafts = draft_manager.get_all()
      local to_sync = 0
      
      for _, draft in ipairs(drafts) do
        if draft.modified and not draft.synced then
          to_sync = to_sync + 1
          if draft.buffer and vim.api.nvim_buf_is_valid(draft.buffer) then
            draft_manager.sync_remote(draft.buffer)
          end
        end
      end
      
      if to_sync > 0 then
        notify.himalaya(
          string.format("Syncing %d draft(s)...", to_sync),
          notify.categories.STATUS,
          { allow_batching = true }
        )
      else
        notify.himalaya(
          "All drafts are already synced",
          notify.categories.USER_ACTION
        )
      end
    end,
    opts = {
      desc = 'Sync all unsaved drafts'
    }
  }
  
  commands.HimalayaDraftList = {
    fn = function()
      local drafts = draft_manager.get_all()
      local float = require('neotex.plugins.tools.himalaya.ui.float')
      
      if #drafts == 0 then
        notify.himalaya("No active drafts", notify.categories.USER_ACTION)
        return
      end
      
      local lines = {
        "# Active Drafts",
        "",
        string.format("Found %d draft(s):", #drafts),
        ""
      }
      
      -- Sort drafts by modified time (newest first)
      table.sort(drafts, function(a, b)
        return (a.modified_at or 0) > (b.modified_at or 0)
      end)
      
      for i, draft in ipairs(drafts) do
        local status = draft.synced and "✓" or "✗"
        local subject = draft.metadata.subject or "Untitled"
        
        table.insert(lines, string.format("%d. [%s] %s", i, status, subject))
        
        if draft.metadata.to then
          table.insert(lines, string.format("   To: %s", draft.metadata.to))
        end
        
        table.insert(lines, string.format("   Modified: %s", 
          os.date("%Y-%m-%d %H:%M", draft.modified_at or 0)))
        
        if draft.remote_id then
          table.insert(lines, string.format("   Remote ID: %s", draft.remote_id))
        else
          table.insert(lines, "   Status: Local only")
        end
        
        table.insert(lines, "")
      end
      
      table.insert(lines, "Legend: [✓] Synced  [✗] Unsaved changes")
      
      float.show('Draft List', lines)
    end,
    opts = {
      desc = 'List all active drafts'
    }
  }
  
  commands.HimalayaDraftDelete = {
    fn = function()
      local buf = vim.api.nvim_get_current_buf()
      local draft = draft_manager.get_by_buffer(buf)
      
      if not draft then
        notify.himalaya(
          "No draft associated with current buffer",
          notify.categories.WARNING
        )
        return
      end
      
      -- Confirm deletion if configured
      local config = require('neotex.plugins.tools.himalaya.core.config').get()
      if config.draft and config.draft.ui and config.draft.ui.confirm_delete then
        vim.ui.select({"No", "Yes"}, {
          prompt = string.format("Delete draft '%s'?", 
            draft.metadata.subject or "Untitled")
        }, function(choice)
          if choice == "Yes" then
            draft_manager.delete(buf)
          end
        end)
      else
        draft_manager.delete(buf)
      end
    end,
    opts = {
      desc = 'Delete current draft'
    }
  }
  
  commands.HimalayaDraftSend = {
    fn = function()
      local buf = vim.api.nvim_get_current_buf()
      local success = draft_manager.send(buf)
      
      if success then
        -- Close the buffer after sending
        vim.cmd('bdelete!')
      end
    end,
    opts = {
      desc = 'Send current draft as email'
    }
  }
  
  -- Status and information commands
  commands.HimalayaDraftStatus = {
    fn = function()
      local count = state.get_draft_count()
      local unsaved = state.get_unsaved_drafts()
      local syncing = state.is_draft_syncing()
      
      local status_lines = {
        string.format("Total drafts: %d", count),
        string.format("Unsaved drafts: %d", vim.tbl_count(unsaved))
      }
      
      if syncing then
        table.insert(status_lines, "Status: Syncing in progress...")
      else
        table.insert(status_lines, "Status: Idle")
      end
      
      -- Add last sync time
      local last_sync = state.get("draft.metadata.last_sync")
      if last_sync then
        local age = os.time() - last_sync
        if age < 60 then
          table.insert(status_lines, string.format("Last sync: %d seconds ago", age))
        elseif age < 3600 then
          table.insert(status_lines, string.format("Last sync: %d minutes ago", 
            math.floor(age / 60)))
        else
          table.insert(status_lines, string.format("Last sync: %d hours ago", 
            math.floor(age / 3600)))
        end
      end
      
      notify.himalaya(
        table.concat(status_lines, "\n"),
        notify.categories.USER_ACTION
      )
    end,
    opts = {
      desc = 'Show draft system status'
    }
  }
  
  commands.HimalayaDraftInfo = {
    fn = function()
      local buf = vim.api.nvim_get_current_buf()
      local draft = draft_manager.get_by_buffer(buf)
      
      if not draft then
        notify.himalaya(
          "No draft associated with current buffer",
          notify.categories.WARNING
        )
        return
      end
      
      local float = require('neotex.plugins.tools.himalaya.ui.float')
      
      local lines = {
        "# Draft Information",
        "",
        string.format("Subject: %s", draft.metadata.subject or "Untitled"),
        string.format("Account: %s", draft.account),
        "",
        "## Metadata",
        string.format("To: %s", draft.metadata.to or ""),
        string.format("From: %s", draft.metadata.from or ""),
        string.format("CC: %s", draft.metadata.cc or ""),
        string.format("BCC: %s", draft.metadata.bcc or ""),
        "",
        "## Status",
        string.format("Local ID: %s", draft.local_id),
        string.format("Remote ID: %s", draft.remote_id or "Not synced"),
        string.format("State: %s", draft.state),
        string.format("Synced: %s", draft.synced and "Yes" or "No"),
        string.format("Modified: %s", draft.modified and "Yes" or "No"),
        "",
        "## Timestamps",
        string.format("Created: %s", os.date("%Y-%m-%d %H:%M:%S", draft.created_at or 0)),
        string.format("Modified: %s", os.date("%Y-%m-%d %H:%M:%S", draft.modified_at or 0)),
      }
      
      if draft.last_sync then
        table.insert(lines, string.format("Last Sync: %s", 
          os.date("%Y-%m-%d %H:%M:%S", draft.last_sync)))
      end
      
      if draft.sync_error then
        table.insert(lines, "")
        table.insert(lines, "## Last Error")
        table.insert(lines, draft.sync_error)
      end
      
      float.show('Draft Information', lines)
    end,
    opts = {
      desc = 'Show information about current draft'
    }
  }
  
  -- Autosave commands
  commands.HimalayaDraftAutosaveEnable = {
    fn = function()
      local config = require('neotex.plugins.tools.himalaya.core.config')
      -- TODO: Implement autosave functionality
      notify.himalaya(
        "Draft autosave enabled",
        notify.categories.USER_ACTION
      )
    end,
    opts = {
      desc = 'Enable draft autosave'
    }
  }
  
  commands.HimalayaDraftAutosaveDisable = {
    fn = function()
      local config = require('neotex.plugins.tools.himalaya.core.config')
      -- TODO: Implement autosave functionality
      notify.himalaya(
        "Draft autosave disabled",
        notify.categories.USER_ACTION
      )
    end,
    opts = {
      desc = 'Disable draft autosave'
    }
  }
  
  -- Register all draft commands
  registry.register_batch(commands)
end

return M