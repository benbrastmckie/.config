-- Himalaya Feature Commands
-- Commands for Phase 8 features (accounts, attachments, trash, etc.)

local M = {}

function M.setup(registry)
  local commands = {}
  
  -- Multiple Account Commands
  commands.HimalayaAccountList = {
    fn = function()
      local accounts = require('neotex.plugins.tools.himalaya.features.accounts')
      local config = require('neotex.plugins.tools.himalaya.core.config')
      local float = require('neotex.plugins.tools.himalaya.ui.float')
      
      local all_accounts = accounts.get_all_accounts()
      local lines = { '# Email Accounts', '' }
      
      for name, account in pairs(all_accounts) do
        local status = account.active and ' (active)' or ''
        local unread = account.unread_count > 0 and ' [' .. account.unread_count .. ' unread]' or ''
        local email = account.email or config.get_account_email(name) or 'No email configured'
        table.insert(lines, string.format('• %s - %s%s%s', 
          name, email, status, unread))
      end
      
      float.show('Email Accounts', lines)
    end,
    opts = {
      desc = 'List all email accounts'
    }
  }
  
  commands.HimalayaAccountSwitch = {
    fn = function(opts)
      local accounts = require('neotex.plugins.tools.himalaya.features.accounts')
      local notify = require('neotex.util.notifications')
      
      if opts.args == '' then
        notify.himalaya('Usage: :HimalayaAccountSwitch <account-name>', notify.categories.ERROR)
        return
      end
      
      local result = accounts.switch_account(opts.args)
      
      if result.success then
        notify.himalaya('Switched to account: ' .. opts.args, notify.categories.USER_ACTION)
        
        -- Refresh UI if open
        local ui = require('neotex.plugins.tools.himalaya.ui')
        if ui.is_email_buffer_open() then
          ui.refresh_email_list()
        end
      else
        notify.himalaya(result.error.message, notify.categories.ERROR)
      end
    end,
    opts = {
      nargs = 1,
      desc = 'Switch to a different email account',
      complete = function()
        local accounts = require('neotex.plugins.tools.himalaya.features.accounts')
        local names = {}
        for name, _ in pairs(accounts.get_all_accounts()) do
          table.insert(names, name)
        end
        return names
      end
    }
  }
  
  commands.HimalayaUnifiedInbox = {
    fn = function()
      local accounts = require('neotex.plugins.tools.himalaya.features.accounts')
      local ui = require('neotex.plugins.tools.himalaya.ui')
      
      -- Get unified inbox
      local result = accounts.get_unified_inbox({ limit = 100 })
      
      if result.success then
        -- Display in UI
        ui.show_unified_inbox(result.data.emails)
      else
        local notify = require('neotex.util.notifications')
        notify.himalaya('Failed to get unified inbox', notify.categories.ERROR)
      end
    end,
    opts = {
      desc = 'Show unified inbox across all accounts'
    }
  }
  
  -- Attachment Commands
  commands.HimalayaAttachments = {
    fn = function()
      local ui = require('neotex.plugins.tools.himalaya.ui')
      local email_id = ui.get_current_email_id()
      
      if not email_id then
        local notify = require('neotex.util.notifications')
        notify.himalaya('No email selected', notify.categories.ERROR)
        return
      end
      
      local attachments = require('neotex.plugins.tools.himalaya.features.attachments')
      local result = attachments.get_attachments(email_id)
      
      if result.success and #result.data > 0 then
        ui.show_attachments_list(email_id, result.data)
      else
        local notify = require('neotex.util.notifications')
        notify.himalaya('No attachments in this email', notify.categories.STATUS)
      end
    end,
    opts = {
      desc = 'List attachments in current email'
    }
  }
  
  commands.HimalayaAttachmentView = {
    fn = function(opts)
      local attachments = require('neotex.plugins.tools.himalaya.features.attachments')
      local ui = require('neotex.plugins.tools.himalaya.ui')
      
      local email_id = ui.get_current_email_id()
      if not email_id then
        local notify = require('neotex.util.notifications')
        notify.himalaya('No email selected', notify.categories.ERROR)
        return
      end
      
      local attachment_id = opts.args
      if attachment_id == '' then
        -- Show picker
        local result = attachments.get_attachments(email_id)
        if result.success and #result.data > 0 then
          ui.pick_attachment(email_id, result.data, function(selected)
            attachments.view(email_id, selected.id, selected)
          end)
        end
      else
        attachments.view(email_id, attachment_id)
      end
    end,
    opts = {
      nargs = '?',
      desc = 'View an attachment'
    }
  }
  
  commands.HimalayaAttachmentSave = {
    fn = function(opts)
      local attachments = require('neotex.plugins.tools.himalaya.features.attachments')
      local ui = require('neotex.plugins.tools.himalaya.ui')
      
      local email_id = ui.get_current_email_id()
      if not email_id then
        local notify = require('neotex.util.notifications')
        notify.himalaya('No email selected', notify.categories.ERROR)
        return
      end
      
      -- Parse args: attachment_id [save_path]
      local parts = vim.split(opts.args, ' ', { trimempty = true })
      local attachment_id = parts[1]
      local save_path = parts[2] or vim.fn.expand('~/Downloads')
      
      if not attachment_id then
        local notify = require('neotex.util.notifications')
        notify.himalaya('Usage: :HimalayaAttachmentSave <attachment-id> [path]', notify.categories.ERROR)
        return
      end
      
      local result = attachments.save(email_id, attachment_id, save_path)
      
      if result.success then
        local notify = require('neotex.util.notifications')
        notify.himalaya('Saved to: ' .. result.data.path, notify.categories.USER_ACTION)
      end
    end,
    opts = {
      nargs = '+',
      desc = 'Save attachment to disk'
    }
  }
  
  -- Trash Commands  
  commands.HimalayaTrashList = {
    fn = function()
      local trash = require('neotex.plugins.tools.himalaya.features.trash')
      local ui = require('neotex.plugins.tools.himalaya.ui')
      
      local result = trash.list_trash({ limit = 50 })
      
      if result.success then
        ui.show_trash_list(result.data.items)
      end
    end,
    opts = {
      desc = 'Show trash folder'
    }
  }
  
  commands.HimalayaTrashRecover = {
    fn = function(opts)
      local trash = require('neotex.plugins.tools.himalaya.features.trash')
      local notify = require('neotex.util.notifications')
      
      if opts.args == '' then
        notify.himalaya('Usage: :HimalayaTrashRecover <trash-id>', notify.categories.ERROR)
        return
      end
      
      local result = trash.recover_email(opts.args)
      
      if result.success then
        notify.himalaya('Email recovered to ' .. result.data.folder, notify.categories.USER_ACTION)
      else
        notify.himalaya(result.error.message, notify.categories.ERROR)
      end
    end,
    opts = {
      nargs = 1,
      desc = 'Recover email from trash'
    }
  }
  
  commands.HimalayaTrashEmpty = {
    fn = function()
      local trash = require('neotex.plugins.tools.himalaya.features.trash')
      local notify = require('neotex.util.notifications')
      
      -- Confirm
      local confirm = vim.fn.input('Empty trash? This cannot be undone. (y/N): ')
      if confirm:lower() ~= 'y' then
        return
      end
      
      local result = trash.empty_trash()
      
      if result.success then
        notify.himalaya('Emptied trash: ' .. result.data.deleted_count .. ' items deleted', 
          notify.categories.USER_ACTION)
      end
    end,
    opts = {
      desc = 'Empty trash permanently'
    }
  }
  
  -- Image Display Commands
  commands.HimalayaImageView = {
    fn = function()
      local images = require('neotex.plugins.tools.himalaya.features.images')
      local attachments = require('neotex.plugins.tools.himalaya.features.attachments')
      local ui = require('neotex.plugins.tools.himalaya.ui')
      
      local email_id = ui.get_current_email_id()
      if not email_id then
        local notify = require('neotex.util.notifications')
        notify.himalaya('No email selected', notify.categories.ERROR)
        return
      end
      
      -- Get image attachments
      local result = attachments.get_attachments(email_id)
      
      if result.success then
        local image_attachments = vim.tbl_filter(function(att)
          return images.is_image(att.content_type)
        end, result.data)
        
        if #image_attachments > 0 then
          -- Show first image or picker if multiple
          if #image_attachments == 1 then
            images.display_attachment(email_id, image_attachments[1].id, image_attachments[1])
          else
            ui.pick_attachment(email_id, image_attachments, function(selected)
              images.display_attachment(email_id, selected.id, selected)
            end)
          end
        else
          local notify = require('neotex.util.notifications')
          notify.himalaya('No images in this email', notify.categories.STATUS)
        end
      end
    end,
    opts = {
      desc = 'View images in current email'
    }
  }
  
  -- Contact/Autocomplete Commands
  commands.HimalayaContacts = {
    fn = function(opts)
      local contacts = require('neotex.plugins.tools.himalaya.features.contacts')
      local float = require('neotex.plugins.tools.himalaya.ui.float')
      
      local results
      if opts.args ~= '' then
        results = contacts.search(opts.args)
      else
        results = contacts.get_frequent(20)
      end
      
      local lines = { '# Contacts', '' }
      
      for _, contact in ipairs(results) do
        local freq = contact.frequency and ' (' .. contact.frequency .. ')' or ''
        local org = contact.organization and ' - ' .. contact.organization or ''
        table.insert(lines, string.format('• %s <%s>%s%s', 
          contact.name or contact.email, contact.email, org, freq))
      end
      
      float.show('Contacts', lines)
    end,
    opts = {
      nargs = '?',
      desc = 'Search or list contacts'
    }
  }
  
  commands.HimalayaContactAdd = {
    fn = function(opts)
      local contacts = require('neotex.plugins.tools.himalaya.features.contacts')
      local notify = require('neotex.util.notifications')
      
      -- Parse: email [name]
      local parts = vim.split(opts.args, ' ', { trimempty = true })
      local email = parts[1]
      local name = table.concat(vim.list_slice(parts, 2), ' ')
      
      if not email then
        notify.himalaya('Usage: :HimalayaContactAdd <email> [name]', notify.categories.ERROR)
        return
      end
      
      local result = contacts.add_contact({
        email = email,
        name = name ~= '' and name or nil,
        source = 'manual'
      })
      
      if result.success then
        notify.himalaya('Contact added: ' .. email, notify.categories.USER_ACTION)
      else
        notify.himalaya(result.error.message, notify.categories.ERROR)
      end
    end,
    opts = {
      nargs = '+',
      desc = 'Add a contact'
    }
  }
  
  commands.HimalayaContactScan = {
    fn = function()
      local contacts = require('neotex.plugins.tools.himalaya.features.contacts')
      local notify = require('neotex.util.notifications')
      
      notify.himalaya('Scanning emails for contacts...', notify.categories.STATUS)
      
      vim.schedule(function()
        contacts.scan_emails_for_contacts()
        notify.himalaya('Contact scan complete', notify.categories.USER_ACTION)
      end)
    end,
    opts = {
      desc = 'Scan emails to extract contacts'
    }
  }
  
  -- Header Commands
  commands.HimalayaHeaders = {
    fn = function()
      local headers = require('neotex.plugins.tools.himalaya.features.headers')
      local ui = require('neotex.plugins.tools.himalaya.ui')
      
      local email_id = ui.get_current_email_id()
      if not email_id then
        local notify = require('neotex.util.notifications')
        notify.himalaya('No email selected', notify.categories.ERROR)
        return
      end
      
      local result = headers.get_headers(email_id)
      
      if result.success then
        ui.show_headers(result.data)
      end
    end,
    opts = {
      desc = 'Show all headers for current email'
    }
  }
  
  -- Register all feature commands
  registry.register_batch(commands)
end

return M