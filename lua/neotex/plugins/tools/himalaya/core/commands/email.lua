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

  -- Scheduler Commands (Phase 9 - Unified Email Scheduling System)
  commands.HimalayaSchedule = {
    fn = function()
      local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
      scheduler.show_queue()
    end,
    opts = { desc = 'Show scheduled emails' }
  }

  commands.HimalayaScheduleCancel = {
    fn = function(opts)
      local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
      if opts.args and opts.args ~= '' then
        scheduler.cancel_send(opts.args)
      else
        scheduler.cancel_from_queue_view()
      end
    end,
    opts = { 
      nargs = '?',
      desc = 'Cancel scheduled email' 
    }
  }

  commands.HimalayaScheduleEdit = {
    fn = function(opts)
      local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
      if opts.args and opts.args ~= '' then
        scheduler.edit_scheduled_time(opts.args)
      else
        scheduler.edit_from_queue_view()
      end
    end,
    opts = {
      nargs = '?',
      desc = 'Edit scheduled time'
    }
  }

  -- Advanced Search Commands (Phase 9)
  commands.HimalayaSearch = {
    fn = function(opts)
      local search = require('neotex.plugins.tools.himalaya.core.search')
      
      if opts.args == '' then
        -- Show interactive search UI
        search.show_search_ui()
      else
        -- Execute search with provided query
        search.execute_search(opts.args)
      end
    end,
    opts = {
      nargs = '?',
      desc = 'Advanced email search with operators'
    }
  }

  commands.HimalayaSearchClear = {
    fn = function()
      local search = require('neotex.plugins.tools.himalaya.core.search')
      search.clear_cache()
      require('neotex.util.notifications').himalaya(
        "Search cache cleared",
        require('neotex.util.notifications').categories.USER_ACTION
      )
    end,
    opts = {
      desc = 'Clear search result cache'
    }
  }

  -- Email Templates Commands (Phase 9)
  commands.HimalayaTemplates = {
    fn = function()
      local templates = require('neotex.plugins.tools.himalaya.core.templates')
      templates.show_templates()
    end,
    opts = {
      desc = 'Manage email templates'
    }
  }

  commands.HimalayaTemplateNew = {
    fn = function()
      local templates = require('neotex.plugins.tools.himalaya.core.templates')
      templates.edit_template(nil)
    end,
    opts = {
      desc = 'Create new email template'
    }
  }

  commands.HimalayaTemplateEdit = {
    fn = function(opts)
      local templates = require('neotex.plugins.tools.himalaya.core.templates')
      
      if opts.args == '' then
        templates.pick_template(function(template_id)
          templates.edit_template(template_id)
        end)
      else
        templates.edit_template(opts.args)
      end
    end,
    opts = {
      nargs = '?',
      desc = 'Edit email template'
    }
  }

  commands.HimalayaTemplateDelete = {
    fn = function(opts)
      local templates = require('neotex.plugins.tools.himalaya.core.templates')
      local notify = require('neotex.util.notifications')
      
      if opts.args == '' then
        templates.pick_template(function(template_id)
          local template = templates.get_template(template_id)
          if template then
            vim.ui.select({"No", "Yes"}, {
              prompt = string.format("Delete template '%s'?", template.name)
            }, function(choice)
              if choice == "Yes" then
                local success, error_msg = templates.delete_template(template_id)
                if not success then
                  notify.himalaya("Failed to delete template: " .. error_msg, notify.categories.ERROR)
                end
              end
            end)
          end
        end)
      else
        local template = templates.get_template(opts.args)
        if template then
          vim.ui.select({"No", "Yes"}, {
            prompt = string.format("Delete template '%s'?", template.name)
          }, function(choice)
            if choice == "Yes" then
              local success, error_msg = templates.delete_template(opts.args)
              if not success then
                notify.himalaya("Failed to delete template: " .. error_msg, notify.categories.ERROR)
              end
            end
          end)
        else
          notify.himalaya("Template not found: " .. opts.args, notify.categories.ERROR)
        end
      end
    end,
    opts = {
      nargs = '?',
      desc = 'Delete email template'
    }
  }

  commands.HimalayaTemplateUse = {
    fn = function(opts)
      local templates = require('neotex.plugins.tools.himalaya.core.templates')
      local composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
      
      if opts.args == '' then
        templates.pick_template(function(template_id, variables)
          local result = templates.apply_template(template_id, variables)
          if result then
            composer.compose_email({
              to = result.to,
              cc = result.cc,
              bcc = result.bcc,
              subject = result.subject,
              body = result.body,
              template_id = template_id
            })
          end
        end)
      else
        local template = templates.get_template(opts.args)
        if template then
          if #template.variables > 0 then
            templates.get_template_variables(template, function(variables)
              if variables then
                local result = templates.apply_template(opts.args, variables)
                if result then
                  composer.compose_email({
                    to = result.to,
                    cc = result.cc,
                    bcc = result.bcc,
                    subject = result.subject,
                    body = result.body,
                    template_id = opts.args
                  })
                end
              end
            end)
          else
            local result = templates.apply_template(opts.args, {})
            if result then
              composer.compose_email({
                to = result.to,
                cc = result.cc,
                bcc = result.bcc,
                subject = result.subject,
                body = result.body,
                template_id = opts.args
              })
            end
          end
        else
          require('neotex.util.notifications').himalaya(
            "Template not found: " .. opts.args,
            require('neotex.util.notifications').categories.ERROR
          )
        end
      end
    end,
    opts = {
      nargs = '?',
      desc = 'Use email template to compose new email'
    }
  }

  -- Phase 9 Test Command
  commands.HimalayaTestPhase9 = {
    fn = function()
      local test_script = require('neotex.plugins.tools.himalaya.scripts.test_phase9')
      test_script.interactive_test()
    end,
    opts = {
      desc = 'Run interactive Phase 9 feature tests'
    }
  }

  -- Phase 9 Demo Command
  commands.HimalayaDemoPhase9 = {
    fn = function()
      local demo_script = require('neotex.plugins.tools.himalaya.scripts.demo_phase9')
      demo_script.interactive_demo()
    end,
    opts = {
      desc = 'Interactive Phase 9 feature demonstrations'
    }
  }
  
  -- Register all email commands
  registry.register_batch(commands)
end

return M