-- Himalaya UI Commands
-- Consolidated module for UI operations, folder navigation, account management, and views

local M = {}

--- Show context-aware help for himalaya buffers
--- @param context string 'sidebar'|'compose'|'list'
function M.show_help(context)
  local notify = require('neotex.util.notifications')
  local messages = {
    sidebar = 'Sidebar: <CR> select | c change folder | e compose | r refresh | a switch acct | q close | ? full help',
    compose = 'Compose: <leader>me send | <leader>md draft | <leader>mq discard | <C-a> attach | ? full help',
    list = 'Actions: d=delete a=archive r=reply R=all f=fwd m=move c=folder e=compose | ? for full keybindings',
  }
  local msg = messages[context] or messages.list
  notify.himalaya(msg, notify.categories.STATUS)
end

function M.setup(registry)
  local commands = {}
  
  -- Core dependencies
  local state = require('neotex.plugins.tools.himalaya.core.state')
  local logger = require('neotex.plugins.tools.himalaya.core.logger')
  local config = require('neotex.plugins.tools.himalaya.core.config')
  local utils = require('neotex.plugins.tools.himalaya.utils')
  
  -- ======================
  -- Main UI Operations
  -- ======================
  
  commands.Himalaya = {
    fn = function()
      local main = require('neotex.plugins.tools.himalaya.ui.main')
      main.show_email_list({})
    end,
    opts = {
      desc = 'Open Himalaya email client'
    }
  }
  
  commands.HimalayaToggle = {
    fn = function()
      local main = require('neotex.plugins.tools.himalaya.ui.main')
      main.toggle_email_sidebar()
    end,
    opts = {
      desc = 'Toggle Himalaya email client'
    }
  }
  
  commands.HimalayaRefresh = {
    fn = function()
      local main = require('neotex.plugins.tools.himalaya.ui.main')
      main.refresh_email_list()
    end,
    opts = {
      desc = 'Refresh current email list'
    }
  }
  
  commands.HimalayaRestore = {
    fn = function()
      local main = require('neotex.plugins.tools.himalaya.ui.main')
      main.restore_state()
    end,
    opts = {
      desc = 'Restore Himalaya UI to previous state'
    }
  }
  
  -- ======================
  -- Folder Operations
  -- ======================
  
  commands.HimalayaFolder = {
    fn = function(opts)
      local folder = opts.args
      local main = require('neotex.plugins.tools.himalaya.ui.main')
      
      if folder and folder ~= '' then
        -- Switch to specific folder
        main.change_folder(folder)
      else
        -- Show folder picker
        main.show_folder_picker()
      end
    end,
    opts = {
      nargs = '?',
      complete = function()
        return {'INBOX', 'Sent', 'Drafts', 'Trash', 'Spam'}
      end,
      desc = 'Switch email folder (no args = show picker)'
    }
  }
  
  commands.HimalayaUpdateCounts = {
    fn = function()
      local notify = require('neotex.util.notifications')
      
      -- Start count update
      notify.himalaya('Updating folder counts...', notify.categories.INFO)
      
      -- Get current account
      local account = config.get_current_account_name()
      if not account then
        notify.himalaya('No account selected', notify.categories.ERROR)
        return
      end
      
      -- Update counts for all folders
      local folders = {'INBOX', 'Sent', 'Drafts', 'Trash', 'Spam'}
      local updated = 0
      
      for _, folder in ipairs(folders) do
        local count = utils.fetch_folder_count(account, folder)
        if count then
          state.set_folder_count(account, folder, count)
          updated = updated + 1
        end
      end
      
      notify.himalaya(
        string.format('Updated %d folder counts', updated),
        notify.categories.SUCCESS
      )
      
      -- Refresh UI
      local main = require('neotex.plugins.tools.himalaya.ui.main')
      main.refresh_sidebar_header()
    end,
    opts = {
      desc = 'Update all folder counts'
    }
  }
  
  commands.HimalayaFolderCounts = {
    fn = function()
      local float = require('neotex.plugins.tools.himalaya.ui.float')
      local account = config.get_current_account_name()
      
      if not account then
        local notify = require('neotex.util.notifications')
        notify.himalaya('No account selected', notify.categories.ERROR)
        return
      end
      
      local lines = {'# Folder Counts', '', 'Account: ' .. account, ''}
      
      local folders = {'INBOX', 'Sent', 'Drafts', 'Trash', 'Spam'}
      for _, folder in ipairs(folders) do
        local count = state.get_folder_count(account, folder)
        local age = state.get_folder_count_age(account, folder)
        
        if count then
          local age_str = age and string.format(' (updated %d seconds ago)', age) or ' (never updated)'
          table.insert(lines, string.format('%s: %d emails%s', folder, count, age_str))
        else
          table.insert(lines, string.format('%s: not loaded', folder))
        end
      end
      
      float.show('Folder Counts', lines)
    end,
    opts = {
      desc = 'Show folder email counts'
    }
  }
  
  -- ======================
  -- Account Management
  -- ======================
  
  commands.HimalayaAccounts = {
    fn = function()
      local main = require('neotex.plugins.tools.himalaya.ui.main')
      main.show_account_picker()
    end,
    opts = {
      desc = 'Show account switcher'
    }
  }
  
  commands.HimalayaAccountSwitch = {
    fn = function(opts)
      local main = require('neotex.plugins.tools.himalaya.ui.main')
      local account_name = opts.args
      
      if account_name and account_name ~= '' then
        main.switch_account(account_name)
      else
        main.show_account_picker()
      end
    end,
    opts = {
      nargs = '?',
      complete = function()
        local accounts = config.get_accounts()
        local names = {}
        for _, account in ipairs(accounts) do
          table.insert(names, account.name)
        end
        return names
      end,
      desc = 'Switch to a different account'
    }
  }
  
  commands.HimalayaAccountList = {
    fn = function()
      local accounts = config.get_accounts()
      local current = config.get_current_account_name()
      local float = require('neotex.plugins.tools.himalaya.ui.float')
      
      local lines = {'# Email Accounts', ''}
      
      for _, account in ipairs(accounts) do
        local marker = account.name == current and '* ' or '  '
        local line = marker .. account.name
        if account.email then
          line = line .. ' (' .. account.email .. ')'
        end
        table.insert(lines, line)
      end
      
      float.show('Accounts', lines)
    end,
    opts = {
      desc = 'List all configured accounts'
    }
  }
  
  commands.HimalayaNextAccount = {
    fn = function()
      local accounts = config.get_accounts()
      local current = config.get_current_account_name()
      local main = require('neotex.plugins.tools.himalaya.ui.main')
      
      -- Find current index
      local current_idx = 1
      for i, account in ipairs(accounts) do
        if account.name == current then
          current_idx = i
          break
        end
      end
      
      -- Get next account (wrap around)
      local next_idx = current_idx % #accounts + 1
      main.switch_account(accounts[next_idx].name)
    end,
    opts = {
      desc = 'Switch to next account'
    }
  }
  
  commands.HimalayaPreviousAccount = {
    fn = function()
      local accounts = config.get_accounts()
      local current = config.get_current_account_name()
      local main = require('neotex.plugins.tools.himalaya.ui.main')
      
      -- Find current index
      local current_idx = 1
      for i, account in ipairs(accounts) do
        if account.name == current then
          current_idx = i
          break
        end
      end
      
      -- Get previous account (wrap around)
      local prev_idx = current_idx - 1
      if prev_idx < 1 then
        prev_idx = #accounts
      end
      main.switch_account(accounts[prev_idx].name)
    end,
    opts = {
      desc = 'Switch to previous account'
    }
  }
  
  commands.HimalayaRefreshAccounts = {
    fn = function()
      local notify = require('neotex.util.notifications')
      
      -- Reload configuration
      config.reload()
      
      -- Refresh UI
      local main = require('neotex.plugins.tools.himalaya.ui.main')
      main.refresh_sidebar_header()
      
      notify.himalaya('Accounts refreshed', notify.categories.SUCCESS)
    end,
    opts = {
      desc = 'Refresh account list from config'
    }
  }
  
  commands.HimalayaAccountStatus = {
    fn = function()
      local float = require('neotex.plugins.tools.himalaya.ui.float')
      local account = config.get_current_account()
      
      if not account then
        local notify = require('neotex.util.notifications')
        notify.himalaya('No account selected', notify.categories.ERROR)
        return
      end
      
      local lines = {
        '# Account Status',
        '',
        'Name: ' .. (account.name or 'default'),
        'Email: ' .. (account.email or 'not set'),
        'Backend: ' .. (account.backend or 'unknown'),
        ''
      }
      
      -- Add maildir info if available
      if account.maildir_path then
        table.insert(lines, '## Maildir Configuration')
        table.insert(lines, 'Path: ' .. account.maildir_path)
        
        -- Check if maildir exists
        if vim.fn.isdirectory(vim.fn.expand(account.maildir_path)) == 1 then
          table.insert(lines, 'Status: ✓ Directory exists')
        else
          table.insert(lines, 'Status: ✗ Directory not found')
        end
      end
      
      -- Add IMAP info if available
      if account.imap_host then
        table.insert(lines, '')
        table.insert(lines, '## IMAP Configuration')
        table.insert(lines, 'Host: ' .. account.imap_host)
        table.insert(lines, 'Port: ' .. (account.imap_port or '993'))
        table.insert(lines, 'SSL: ' .. (account.imap_ssl and 'Yes' or 'No'))
      end
      
      -- Add SMTP info if available
      if account.smtp_host then
        table.insert(lines, '')
        table.insert(lines, '## SMTP Configuration')
        table.insert(lines, 'Host: ' .. account.smtp_host)
        table.insert(lines, 'Port: ' .. (account.smtp_port or '587'))
        table.insert(lines, 'SSL: ' .. (account.smtp_ssl and 'Yes' or 'No'))
      end
      
      float.show('Account Status', lines)
    end,
    opts = {
      desc = 'Show current account status and configuration'
    }
  }
  
  -- ======================
  -- View Modes
  -- ======================
  
  commands.HimalayaUnifiedInbox = {
    fn = function()
      local views = require('neotex.plugins.tools.himalaya.features.views')
      views.show_unified_inbox()
    end,
    opts = {
      desc = 'Show unified inbox across all accounts'
    }
  }
  
  commands.HimalayaSplitView = {
    fn = function()
      local views = require('neotex.plugins.tools.himalaya.features.views')
      views.show_split_view()
    end,
    opts = {
      desc = 'Show split view with multiple accounts'
    }
  }
  
  commands.HimalayaTabbedView = {
    fn = function()
      local views = require('neotex.plugins.tools.himalaya.features.views')
      views.show_tabbed_view()
    end,
    opts = {
      desc = 'Show tabbed view with account tabs'
    }
  }
  
  commands.HimalayaFocusedView = {
    fn = function()
      local views = require('neotex.plugins.tools.himalaya.features.views')
      views.show_focused_view()
    end,
    opts = {
      desc = 'Show focused view (single account)'
    }
  }
  
  commands.HimalayaToggleView = {
    fn = function()
      local views = require('neotex.plugins.tools.himalaya.features.views')
      views.toggle_view_mode()
    end,
    opts = {
      desc = 'Toggle between view modes'
    }
  }
  
  -- ======================
  -- Attachment Operations
  -- ======================
  
  commands.HimalayaAttachments = {
    fn = function()
      local attachments = require('neotex.plugins.tools.himalaya.features.attachments')
      attachments.show_attachments()
    end,
    opts = {
      desc = 'Show attachments for current email'
    }
  }
  
  commands.HimalayaAttachmentView = {
    fn = function(opts)
      local attachments = require('neotex.plugins.tools.himalaya.features.attachments')
      local index = tonumber(opts.args)
      
      if index then
        attachments.view_attachment(index)
      else
        attachments.show_attachment_picker('view')
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
      local index = tonumber(opts.args)
      
      if index then
        attachments.save_attachment(index)
      else
        attachments.show_attachment_picker('save')
      end
    end,
    opts = {
      nargs = '?',
      desc = 'Save an attachment'
    }
  }
  
  -- ======================
  -- Image Operations
  -- ======================
  
  commands.HimalayaImageView = {
    fn = function()
      local images = require('neotex.plugins.tools.himalaya.features.images')
      images.view_images_in_email()
    end,
    opts = {
      desc = 'View images in current email'
    }
  }
  
  -- ======================
  -- Contact Operations
  -- ======================
  
  commands.HimalayaContacts = {
    fn = function()
      local contacts = require('neotex.plugins.tools.himalaya.features.contacts')
      contacts.show_contacts()
    end,
    opts = {
      desc = 'Show contact list'
    }
  }
  
  commands.HimalayaContactAdd = {
    fn = function(opts)
      local contacts = require('neotex.plugins.tools.himalaya.features.contacts')
      
      if opts.args and opts.args ~= '' then
        contacts.add_contact_from_string(opts.args)
      else
        contacts.add_contact_interactive()
      end
    end,
    opts = {
      nargs = '?',
      desc = 'Add a new contact'
    }
  }
  
  commands.HimalayaContactScan = {
    fn = function()
      local contacts = require('neotex.plugins.tools.himalaya.features.contacts')
      contacts.scan_and_add_contacts()
    end,
    opts = {
      desc = 'Scan emails for new contacts'
    }
  }
  
  -- ======================
  -- Header Operations
  -- ======================
  
  commands.HimalayaHeaders = {
    fn = function()
      local headers = require('neotex.plugins.tools.himalaya.features.headers')
      headers.show_headers()
    end,
    opts = {
      desc = 'Show full email headers'
    }
  }
  
  -- ======================
  -- Trash Operations
  -- ======================
  
  commands.HimalayaTrashList = {
    fn = function()
      local main = require('neotex.plugins.tools.himalaya.ui.main')
      -- Switch to trash folder
      main.change_folder('Trash')
    end,
    opts = {
      desc = 'Show trash folder'
    }
  }
  
  commands.HimalayaTrashRecover = {
    fn = function()
      local main = require('neotex.plugins.tools.himalaya.ui.main')
      local notify = require('neotex.util.notifications')
      
      -- Check if we're in trash folder
      local current_folder = state.get('ui.current_folder')
      if current_folder ~= 'Trash' then
        notify.himalaya('Please switch to Trash folder first', notify.categories.ERROR)
        return
      end
      
      -- Move current email back to inbox
      main.move_email('INBOX')
    end,
    opts = {
      desc = 'Recover email from trash'
    }
  }
  
  commands.HimalayaTrashEmpty = {
    fn = function()
      local notify = require('neotex.util.notifications')
      local async_commands = require('neotex.plugins.tools.himalaya.core.async_commands')
      
      vim.ui.select({'Yes', 'No'}, {
        prompt = 'Empty trash folder? This cannot be undone.'
      }, function(choice)
        if choice == 'Yes' then
          local account = config.get_current_account_name()
          
          -- Use himalaya CLI to empty trash
          async_commands.execute_async(
            {'folder', 'expunge', 'Trash'},
            { account = account },
            function(result, error)
              if error then
                notify.himalaya('Failed to empty trash: ' .. error, notify.categories.ERROR)
              else
                notify.himalaya('Trash emptied successfully', notify.categories.SUCCESS)
                
                -- Update count
                state.set_folder_count(account, 'Trash', 0)
                
                -- Refresh UI
                local main = require('neotex.plugins.tools.himalaya.ui.main')
                main.refresh_email_list()
              end
            end
          )
        end
      end)
    end,
    opts = {
      desc = 'Empty trash folder'
    }
  }
  
  -- ======================
  -- Threading Operations (Task #81)
  -- ======================

  commands.HimalayaThreadingToggle = {
    fn = function()
      local notify = require('neotex.util.notifications')
      local email_list = require('neotex.plugins.tools.himalaya.ui.email_list')

      local enabled = email_list.toggle_threading()
      notify.himalaya('Email threading ' .. (enabled and 'enabled' or 'disabled'), notify.categories.SUCCESS)

      -- Refresh the display
      email_list.refresh_email_list()
    end,
    opts = {
      desc = 'Toggle email thread grouping'
    }
  }

  commands.HimalayaExpandAllThreads = {
    fn = function()
      local notify = require('neotex.util.notifications')
      local email_list = require('neotex.plugins.tools.himalaya.ui.email_list')

      email_list.expand_all_threads()
      email_list.refresh_email_list()
      notify.himalaya('All threads expanded', notify.categories.STATUS)
    end,
    opts = {
      desc = 'Expand all email threads'
    }
  }

  commands.HimalayaCollapseAllThreads = {
    fn = function()
      local notify = require('neotex.util.notifications')
      local email_list = require('neotex.plugins.tools.himalaya.ui.email_list')

      email_list.collapse_all_threads()
      email_list.refresh_email_list()
      notify.himalaya('All threads collapsed', notify.categories.STATUS)
    end,
    opts = {
      desc = 'Collapse all email threads'
    }
  }

  -- Register all commands
  registry.register_batch(commands)
end

return M