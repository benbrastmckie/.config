-- Himalaya Email Commands
-- Consolidated module for all email-related operations including drafts, templates, and search

local M = {}

function M.setup(registry)
  local commands = {}
  
  -- Core dependencies
  local state = require('neotex.plugins.tools.himalaya.core.state')
  local logger = require('neotex.plugins.tools.himalaya.core.logger')
  local config = require('neotex.plugins.tools.himalaya.core.config')
  local utils = require('neotex.plugins.tools.himalaya.utils')
  local draft_manager = require("neotex.plugins.tools.himalaya.data.drafts")
  local scheduler = require("neotex.plugins.tools.himalaya.data.scheduler")
  local persistence = require('neotex.plugins.tools.himalaya.core.persistence')
  local search = require("neotex.plugins.tools.himalaya.data.search")
  local templates = require("neotex.plugins.tools.himalaya.data.templates")
  
  -- ======================
  -- Core Email Operations
  -- ======================
  
  commands.HimalayaWrite = {
    fn = function(opts)
      local main = require('neotex.plugins.tools.himalaya.ui.main')
      local email_composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
      local notify = require('neotex.util.notifications')

      -- Check if already composing an email
      if email_composer.is_composing() then
        notify.himalaya('Already composing an email', notify.categories.INFO)
        return
      end

      -- Get account override from args (used to switch account before composing)
      if opts.args and opts.args ~= '' then
        -- If account specified, switch to that account first
        local account_name = opts.args
        local accounts_config = require('neotex.plugins.tools.himalaya.config.accounts')
        if accounts_config.has_account(account_name) then
          local success = main.switch_account(account_name)
          if not success then
            notify.himalaya('Failed to switch to account: ' .. account_name, notify.categories.ERROR)
            return
          end
        else
          notify.himalaya('Account not found: ' .. account_name, notify.categories.ERROR)
          return
        end
      end

      -- Compose new email (same as 'e' key in sidebar)
      main.compose_email()
    end,
    opts = {
      nargs = '?',
      desc = 'Compose new email (optional: specify account)'
    }
  }
  
  commands.HimalayaSend = {
    fn = function()
      local main = require('neotex.plugins.tools.himalaya.ui.main')
      local composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
      local notify = require('neotex.util.notifications')
      
      if not composer.is_composing() then
        notify.himalaya('No email is being composed', notify.categories.ERROR)
        return
      end
      
      main.send_current_email()
    end,
    opts = {
      desc = 'Send the current email'
    }
  }
  
  commands.HimalayaSaveDraft = {
    fn = function()
      local composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
      local notify = require('neotex.util.notifications')
      
      if not composer.is_composing() then
        notify.himalaya('No email is being composed', notify.categories.ERROR)
        return
      end
      
      composer.save_draft(vim.api.nvim_get_current_buf(), 'manual')
    end,
    opts = {
      desc = 'Save current email as draft'
    }
  }
  
  commands.HimalayaDiscard = {
    fn = function()
      local composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
      local notify = require('neotex.util.notifications')
      
      if not composer.is_composing() then
        notify.himalaya('No email is being composed', notify.categories.ERROR)
        return
      end
      
      main.close_without_saving()
    end,
    opts = {
      desc = 'Discard the current email'
    }
  }
  
  -- ======================
  -- Draft Operations
  -- ======================
  
  commands.HimalayaDraftNew = {
    fn = function()
      local email_composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
      email_composer.compose({})
    end,
    opts = {
      desc = 'Create a new draft'
    }
  }
  
  commands.HimalayaDraftSave = {
    fn = function()
      local email_composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
      local notify = require('neotex.util.notifications')
      
      if not email_composer.is_composing() then
        notify.himalaya('No draft is being composed', notify.categories.ERROR)
        return
      end
      
      email_composer.save_draft(vim.api.nvim_get_current_buf(), 'manual')
    end,
    opts = {
      desc = 'Save current draft'
    }
  }
  
  commands.HimalayaDraftSync = {
    fn = function(opts)
      local draft_id = opts.args
      if not draft_id or draft_id == '' then
        print('Error: Draft ID required')
        return
      end
      
      local result, error = draft_manager.sync_draft(draft_id)
      if result then
        print('Draft synced successfully')
      else
        print('Error syncing draft: ' .. (error or 'unknown error'))
      end
    end,
    opts = {
      nargs = 1,
      desc = 'Sync a specific draft to maildir'
    }
  }
  
  commands.HimalayaDraftSyncAll = {
    fn = function()
      local results = draft_manager.sync_all_drafts()
      print(string.format('Synced %d drafts, %d errors', results.synced, results.errors))
      if results.error_details and #results.error_details > 0 then
        print('Errors:')
        for _, err in ipairs(results.error_details) do
          print('  - ' .. err)
        end
      end
    end,
    opts = {
      desc = 'Sync all drafts to maildir'
    }
  }
  
  commands.HimalayaDraftList = {
    fn = function()
      local email_list = require('neotex.plugins.tools.himalaya.ui.email_list')
      local drafts = draft_manager.list_drafts()
      
      if not drafts or #drafts == 0 then
        print('No drafts found')
        return
      end
      
      -- Show drafts in email list
      email_list.show_drafts(drafts)
    end,
    opts = {
      desc = 'List all drafts'
    }
  }
  
  commands.HimalayaDraftDelete = {
    fn = function(opts)
      local draft_id = opts.args
      if not draft_id or draft_id == '' then
        print('Error: Draft ID required')
        return
      end
      
      local success, error = draft_manager.delete_draft(draft_id)
      if success then
        print('Draft deleted successfully')
      else
        print('Error deleting draft: ' .. (error or 'unknown error'))
      end
    end,
    opts = {
      nargs = 1,
      desc = 'Delete a draft'
    }
  }
  
  commands.HimalayaDraftSend = {
    fn = function(opts)
      local draft_id = opts.args
      if not draft_id or draft_id == '' then
        print('Error: Draft ID required')
        return
      end
      
      -- Load draft
      local draft = draft_manager.get_draft(draft_id)
      if not draft then
        print('Error: Draft not found')
        return
      end
      
      -- Use scheduler to send
      local email_data = {
        from = draft.from,
        to = draft.to,
        cc = draft.cc,
        bcc = draft.bcc,
        subject = draft.subject,
        body = draft.content,
        account = config.get_current_account_name()
      }
      
      local scheduled_id = scheduler.schedule_email(email_data, {
        delay = 60,
        draft_id = draft_id
      })
      
      if scheduled_id then
        print('Draft scheduled for sending in 60 seconds')
      else
        print('Error scheduling draft')
      end
    end,
    opts = {
      nargs = 1,
      desc = 'Send a draft'
    }
  }
  
  commands.HimalayaDraftStatus = {
    fn = function()
      local stats = draft_manager.get_stats()
      print(string.format('Total drafts: %d', stats.total))
      print(string.format('Synced: %d', stats.synced))
      print(string.format('Unsynced: %d', stats.unsynced))
      print(string.format('With errors: %d', stats.errors))
    end,
    opts = {
      desc = 'Show draft statistics'
    }
  }
  
  commands.HimalayaDraftInfo = {
    fn = function(opts)
      local draft_id = opts.args
      if not draft_id or draft_id == '' then
        print('Error: Draft ID required')
        return
      end
      
      local draft = draft_manager.get_draft(draft_id)
      if not draft then
        print('Error: Draft not found')
        return
      end
      
      print('Draft ID: ' .. draft_id)
      print('Subject: ' .. (draft.subject or '(no subject)'))
      print('From: ' .. (draft.from or ''))
      print('To: ' .. (draft.to or ''))
      print('Created: ' .. os.date('%Y-%m-%d %H:%M:%S', draft.created_at))
      print('Modified: ' .. os.date('%Y-%m-%d %H:%M:%S', draft.modified_at))
      print('Synced: ' .. (draft.synced and 'Yes' or 'No'))
    end,
    opts = {
      nargs = 1,
      desc = 'Show draft information'
    }
  }
  
  commands.HimalayaDraftAutosaveEnable = {
    fn = function()
      state.set('draft.autosave_enabled', true)
      print('Draft autosave enabled')
    end,
    opts = {
      desc = 'Enable draft autosave'
    }
  }
  
  commands.HimalayaDraftAutosaveDisable = {
    fn = function()
      state.set('draft.autosave_enabled', false)
      print('Draft autosave disabled')
    end,
    opts = {
      desc = 'Disable draft autosave'
    }
  }
  
  -- ======================
  -- Recovery Operations
  -- ======================
  
  commands.HimalayaRecoverDrafts = {
    fn = function()
      local recovery = require('neotex.plugins.tools.himalaya.core.recovery')
      local notify = require('neotex.util.notifications')
      
      local recovered = recovery.recover_all_drafts()
      notify.himalaya(
        string.format('Recovered %d draft(s)', recovered),
        recovered > 0 and notify.categories.SUCCESS or notify.categories.INFO
      )
    end,
    opts = {
      desc = 'Recover unsaved drafts from swap files'
    }
  }
  
  commands.HimalayaListRecoveredDrafts = {
    fn = function()
      local recovery = require('neotex.plugins.tools.himalaya.core.recovery')
      local ui = require('neotex.plugins.tools.himalaya.ui.recovery_ui')
      
      local drafts = recovery.list_recoverable_drafts()
      if #drafts == 0 then
        local notify = require('neotex.util.notifications')
        notify.himalaya('No recoverable drafts found', notify.categories.INFO)
        return
      end
      
      ui.show_recovery_list(drafts)
    end,
    opts = {
      desc = 'List recoverable drafts'
    }
  }
  
  commands.HimalayaOpenRecoveredDraft = {
    fn = function(opts)
      local recovery = require('neotex.plugins.tools.himalaya.core.recovery')
      local notify = require('neotex.util.notifications')
      
      local swap_file = opts.args
      if not swap_file or swap_file == '' then
        notify.himalaya('Please provide a swap file path', notify.categories.ERROR)
        return
      end
      
      local success = recovery.open_recovered_draft(swap_file)
      if not success then
        notify.himalaya('Failed to open recovered draft', notify.categories.ERROR)
      end
    end,
    opts = {
      nargs = 1,
      desc = 'Open a specific recovered draft'
    }
  }
  
  -- ======================
  -- Schedule Operations
  -- ======================
  
  commands.HimalayaSchedule = {
    fn = function(opts)
      local composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
      local notify = require('neotex.util.notifications')
      
      if not composer.is_composing() then
        notify.himalaya('No email is being composed', notify.categories.ERROR)
        return
      end
      
      -- Parse delay from args (default 60 seconds)
      local delay = 60
      if opts.args and opts.args ~= '' then
        delay = tonumber(opts.args) or 60
      end
      
      -- Validate delay
      if delay < scheduler.config.min_delay then
        notify.himalaya(
          string.format('Minimum delay is %d seconds', scheduler.config.min_delay),
          notify.categories.ERROR
        )
        return
      end
      
      -- Schedule the email
      composer.schedule_send(delay)
    end,
    opts = {
      nargs = '?',
      desc = 'Schedule email to send later (optional: delay in seconds, default 60)'
    }
  }
  
  commands.HimalayaScheduleCancel = {
    fn = function(opts)
      local notify = require('neotex.util.notifications')
      
      local email_id = opts.args
      if not email_id or email_id == '' then
        notify.himalaya('Please provide the scheduled email ID', notify.categories.ERROR)
        return
      end
      
      local success = scheduler.cancel_scheduled_email(email_id)
      if success then
        notify.himalaya('Scheduled send cancelled', notify.categories.SUCCESS)
      else
        notify.himalaya('Failed to cancel scheduled email', notify.categories.ERROR)
      end
    end,
    opts = {
      nargs = 1,
      desc = 'Cancel a scheduled email'
    }
  }
  
  commands.HimalayaScheduleEdit = {
    fn = function(opts)
      local notify = require('neotex.util.notifications')
      local composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
      
      local email_id = opts.args
      if not email_id or email_id == '' then
        notify.himalaya('Please provide the scheduled email ID', notify.categories.ERROR)
        return
      end
      
      local email = scheduler.get_scheduled_email(email_id)
      if not email then
        notify.himalaya('Scheduled email not found', notify.categories.ERROR)
        return
      end
      
      -- Cancel the scheduled send
      scheduler.cancel_scheduled_email(email_id)
      
      -- Open in composer for editing
      composer.compose({
        to = email.to,
        cc = email.cc,
        bcc = email.bcc,
        subject = email.subject,
        body = email.body,
        from = email.from
      })
      
      notify.himalaya('Scheduled email opened for editing', notify.categories.INFO)
    end,
    opts = {
      nargs = 1,
      desc = 'Edit a scheduled email'
    }
  }
  
  -- ======================
  -- Search Operations
  -- ======================
  
  commands.HimalayaSearch = {
    fn = function(opts)
      local query = opts.args
      if not query or query == '' then
        -- Show search UI
        search.show_search_ui()
      else
        -- Direct search
        search.search_emails(query)
      end
    end,
    opts = {
      nargs = '?',
      desc = 'Search emails (no args = show UI, with args = direct search)'
    }
  }
  
  commands.HimalayaSearchClear = {
    fn = function()
      search.clear_search()
      local notify = require('neotex.util.notifications')
      notify.himalaya('Search cleared', notify.categories.INFO)
    end,
    opts = {
      desc = 'Clear current search'
    }
  }
  
  -- ======================
  -- Template Operations
  -- ======================
  
  commands.HimalayaTemplates = {
    fn = function()
      templates.show_templates_list()
    end,
    opts = {
      desc = 'Show email templates'
    }
  }
  
  commands.HimalayaTemplateNew = {
    fn = function(opts)
      local name = opts.args
      if not name or name == '' then
        vim.ui.input({ prompt = 'Template name: ' }, function(input)
          if input and input ~= '' then
            templates.create_template(input)
          end
        end)
      else
        templates.create_template(name)
      end
    end,
    opts = {
      nargs = '?',
      desc = 'Create new email template'
    }
  }
  
  commands.HimalayaTemplateEdit = {
    fn = function(opts)
      local name = opts.args
      if not name or name == '' then
        templates.show_template_picker('edit')
      else
        templates.edit_template(name)
      end
    end,
    opts = {
      nargs = '?',
      desc = 'Edit email template'
    }
  }
  
  commands.HimalayaTemplateDelete = {
    fn = function(opts)
      local name = opts.args
      if not name or name == '' then
        templates.show_template_picker('delete')
      else
        templates.delete_template(name)
      end
    end,
    opts = {
      nargs = '?',
      desc = 'Delete email template'
    }
  }
  
  commands.HimalayaTemplateUse = {
    fn = function(opts)
      local name = opts.args
      if not name or name == '' then
        templates.show_template_picker('use')
      else
        templates.use_template(name)
      end
    end,
    opts = {
      nargs = '?',
      desc = 'Use email template for new email'
    }
  }
  
  -- ======================
  -- Trash Operations
  -- ======================
  
  commands.HimalayaTrash = {
    fn = function()
      local main = require('neotex.plugins.tools.himalaya.ui.main')
      main.delete_email()
    end,
    opts = {
      desc = 'Move current email to trash'
    }
  }
  
  commands.HimalayaTrashStats = {
    fn = function()
      local account = config.get_current_account_name()
      local count = utils.fetch_folder_count(account, 'Trash')
      local notify = require('neotex.util.notifications')
      
      if count then
        notify.himalaya(
          string.format('Trash contains %d email(s)', count),
          notify.categories.INFO
        )
      else
        notify.himalaya('Failed to get trash count', notify.categories.ERROR)
      end
    end,
    opts = {
      desc = 'Show trash statistics'
    }
  }
  
  -- Register all commands
  registry.register_batch(commands)
end

return M