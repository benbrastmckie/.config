-- Himalaya Email Client Commands
-- Command definitions for email operations

local M = {}

-- Setup function to create all commands
function M.setup()
  -- Main email list command
  vim.api.nvim_create_user_command('Himalaya', function(opts)
    local args = {}
    if opts.args and opts.args ~= '' then
      args = vim.split(opts.args, ' ')
    end
    require('neotex.plugins.tools.himalaya.ui').show_email_list(args)
  end, {
    nargs = '*',
    desc = 'Show Himalaya email list',
    complete = function(arglead, cmdline, cursorpos)
      -- Tab completion for folder names
      local utils = require('neotex.plugins.tools.himalaya.utils')
      local folders = utils.get_folders()
      return vim.tbl_filter(function(folder)
        return folder:lower():match(arglead:lower())
      end, folders or {})
    end,
  })
  
  -- Email composition command
  vim.api.nvim_create_user_command('HimalayaWrite', function(opts)
    local to = opts.args and opts.args ~= '' and opts.args or nil
    require('neotex.plugins.tools.himalaya.ui').compose_email(to)
  end, {
    nargs = '?',
    desc = 'Compose new email',
    complete = function(arglead, cmdline, cursorpos)
      -- Tab completion for email addresses (could be enhanced with contacts)
      return {}
    end,
  })
  
  -- Folder selector command
  vim.api.nvim_create_user_command('HimalayaFolders', function()
    require('neotex.plugins.tools.himalaya.picker').show_folders()
  end, {
    desc = 'Show folder picker',
  })
  
  -- Account selector command
  vim.api.nvim_create_user_command('HimalayaAccounts', function()
    require('neotex.plugins.tools.himalaya.picker').show_accounts()
  end, {
    desc = 'Show account picker',
  })
  
  -- Manual sync command
  vim.api.nvim_create_user_command('HimalayaSync', function(opts)
    local force = opts.bang
    require('neotex.plugins.tools.himalaya.utils').sync_mail(force)
  end, {
    bang = true,
    desc = 'Manually sync emails (use ! to force)',
  })

  -- Close Himalaya and cleanup buffers
  vim.api.nvim_create_user_command('HimalayaClose', function(opts)
    require('neotex.plugins.tools.himalaya.ui').close_himalaya()
  end, {
    desc = 'Close Himalaya and cleanup all related buffers',
  })

  -- Debug Himalaya buffers
  vim.api.nvim_create_user_command('HimalayaDebug', function(opts)
    require('neotex.plugins.tools.himalaya.ui').debug_buffers()
  end, {
    desc = 'Debug Himalaya buffer state',
  })

  -- Create folder command
  vim.api.nvim_create_user_command('HimalayaCreateFolder', function(opts)
    if not opts.args or opts.args == '' then
      vim.notify('Folder name required', vim.log.levels.ERROR)
      return
    end
    require('neotex.plugins.tools.himalaya.utils').create_folder(opts.args)
  end, {
    nargs = 1,
    desc = 'Create a new email folder',
  })
  
  -- Configuration validation command
  vim.api.nvim_create_user_command('HimalayaConfigValidate', function(opts)
    local utils = require('neotex.plugins.tools.himalaya.utils')
    local valid, message, issues = utils.validate_mbsync_config()
    if valid then
      vim.notify('✓ ' .. message, vim.log.levels.INFO)
    else
      if issues then
        utils.handle_mbsync_config_issues(issues)
      else
        vim.notify('✗ ' .. message, vim.log.levels.ERROR)
      end
    end
  end, {
    desc = 'Validate mbsync configuration',
  })

  -- Alternative sync command
  vim.api.nvim_create_user_command('HimalayaAlternativeSync', function(opts)
    require('neotex.plugins.tools.himalaya.utils').alternative_sync()
  end, {
    desc = 'Try alternative sync method when mbsync fails',
  })

  -- Configuration help command
  vim.api.nvim_create_user_command('HimalayaConfigHelp', function(opts)
    require('neotex.plugins.tools.himalaya.utils').show_config_help()
  end, {
    desc = 'Show configuration help and troubleshooting guide',
  })

  -- Session restoration command
  vim.api.nvim_create_user_command('HimalayaRestore', function(opts)
    if opts.bang then
      -- Force restore without prompt
      require('neotex.plugins.tools.himalaya.ui').restore_session()
    else
      -- Show prompt for restore
      require('neotex.plugins.tools.himalaya.ui').prompt_session_restore()
    end
  end, {
    bang = true,
    desc = 'Restore previous email session (use ! to restore without prompt)',
  })

  -- Read specific email command
  vim.api.nvim_create_user_command('HimalayaRead', function(opts)
    if not opts.args or opts.args == '' then
      vim.notify('Email ID required', vim.log.levels.ERROR)
      return
    end
    require('neotex.plugins.tools.himalaya.ui').read_email(opts.args)
  end, {
    nargs = 1,
    desc = 'Read specific email by ID',
  })
  
  -- Reply to email command
  vim.api.nvim_create_user_command('HimalayaReply', function(opts)
    if not opts.args or opts.args == '' then
      vim.notify('Email ID required', vim.log.levels.ERROR)
      return
    end
    local all = opts.bang
    require('neotex.plugins.tools.himalaya.ui').reply_email(opts.args, all)
  end, {
    nargs = 1,
    bang = true,
    desc = 'Reply to email (use ! for reply all)',
  })
  
  -- Forward email command
  vim.api.nvim_create_user_command('HimalayaForward', function(opts)
    if not opts.args or opts.args == '' then
      vim.notify('Email ID required', vim.log.levels.ERROR)
      return
    end
    require('neotex.plugins.tools.himalaya.ui').forward_email(opts.args)
  end, {
    nargs = 1,
    desc = 'Forward email',
  })
  
  -- Delete email command
  vim.api.nvim_create_user_command('HimalayaDelete', function(opts)
    if not opts.args or opts.args == '' then
      vim.notify('Email ID required', vim.log.levels.ERROR)
      return
    end
    require('neotex.plugins.tools.himalaya.ui').delete_email(opts.args)
  end, {
    nargs = 1,
    desc = 'Delete email',
  })
  
  -- Move email command
  vim.api.nvim_create_user_command('HimalayaMove', function(opts)
    local args = vim.split(opts.args, ' ')
    if #args < 2 then
      vim.notify('Usage: HimalayaMove <email_id> <folder>', vim.log.levels.ERROR)
      return
    end
    require('neotex.plugins.tools.himalaya.utils').move_email(args[1], args[2])
  end, {
    nargs = '+',
    desc = 'Move email to folder',
    complete = function(arglead, cmdline, cursorpos)
      local args = vim.split(cmdline, ' ')
      if #args >= 3 then -- Completing folder name
        local utils = require('neotex.plugins.tools.himalaya.utils')
        local folders = utils.get_folders()
        return vim.tbl_filter(function(folder)
          return folder:lower():match(arglead:lower())
        end, folders or {})
      end
      return {}
    end,
  })
  
  -- Copy email command
  vim.api.nvim_create_user_command('HimalayaCopy', function(opts)
    local args = vim.split(opts.args, ' ')
    if #args < 2 then
      vim.notify('Usage: HimalayaCopy <email_id> <folder>', vim.log.levels.ERROR)
      return
    end
    require('neotex.plugins.tools.himalaya.utils').copy_email(args[1], args[2])
  end, {
    nargs = '+',
    desc = 'Copy email to folder',
    complete = function(arglead, cmdline, cursorpos)
      local args = vim.split(cmdline, ' ')
      if #args >= 3 then -- Completing folder name
        local utils = require('neotex.plugins.tools.himalaya.utils')
        local folders = utils.get_folders()
        return vim.tbl_filter(function(folder)
          return folder:lower():match(arglead:lower())
        end, folders or {})
      end
      return {}
    end,
  })
  
  -- Search emails command
  vim.api.nvim_create_user_command('HimalayaSearch', function(opts)
    if not opts.args or opts.args == '' then
      vim.notify('Search query required', vim.log.levels.ERROR)
      return
    end
    require('neotex.plugins.tools.himalaya.ui').search_emails(opts.args)
  end, {
    nargs = 1,
    desc = 'Search emails',
  })
  
  -- Flag management commands
  vim.api.nvim_create_user_command('HimalayaFlag', function(opts)
    local args = vim.split(opts.args, ' ')
    if #args < 2 then
      vim.notify('Usage: HimalayaFlag <email_id> <flag>', vim.log.levels.ERROR)
      return
    end
    local action = opts.bang and 'remove' or 'add'
    require('neotex.plugins.tools.himalaya.utils').manage_flag(args[1], args[2], action)
  end, {
    nargs = '+',
    bang = true,
    desc = 'Add flag to email (use ! to remove)',
    complete = function(arglead, cmdline, cursorpos)
      local args = vim.split(cmdline, ' ')
      if #args >= 3 then -- Completing flag name
        local flags = { 'seen', 'answered', 'flagged', 'deleted', 'draft' }
        return vim.tbl_filter(function(flag)
          return flag:lower():match(arglead:lower())
        end, flags)
      end
      return {}
    end,
  })
  
  -- Attachment management
  vim.api.nvim_create_user_command('HimalayaAttachments', function(opts)
    if not opts.args or opts.args == '' then
      vim.notify('Email ID required', vim.log.levels.ERROR)
      return
    end
    require('neotex.plugins.tools.himalaya.ui').show_attachments(opts.args)
  end, {
    nargs = 1,
    desc = 'Show email attachments',
  })
  
  -- Download attachment command
  vim.api.nvim_create_user_command('HimalayaDownload', function(opts)
    local args = vim.split(opts.args, ' ')
    if #args < 2 then
      vim.notify('Usage: HimalayaDownload <email_id> <attachment_name>', vim.log.levels.ERROR)
      return
    end
    require('neotex.plugins.tools.himalaya.utils').download_attachment(args[1], args[2])
  end, {
    nargs = '+',
    desc = 'Download email attachment',
  })
  
  -- Account configuration command
  vim.api.nvim_create_user_command('HimalayaConfigure', function(opts)
    local account = opts.args and opts.args ~= '' and opts.args or nil
    require('neotex.plugins.tools.himalaya.utils').configure_account(account)
  end, {
    nargs = '?',
    desc = 'Configure Himalaya account',
    complete = function(arglead, cmdline, cursorpos)
      local config = require('neotex.plugins.tools.himalaya.config')
      local accounts = vim.tbl_keys(config.config.accounts)
      return vim.tbl_filter(function(account)
        return account:lower():match(arglead:lower())
      end, accounts)
    end,
  })
  
  -- Send command for email composition buffers
  vim.api.nvim_create_user_command('HimalaySend', function()
    require('neotex.plugins.tools.himalaya.ui').send_current_email()
  end, {
    desc = 'Send current email (use in composition buffer)',
  })
  
  -- Additional commands for which-key mappings
  vim.api.nvim_create_user_command('HimalayaList', function(opts)
    require('neotex.plugins.tools.himalaya.ui').show_email_list({})
  end, {
    desc = 'List emails in current folder',
  })
  
  vim.api.nvim_create_user_command('HimalayaRead', function(opts)
    require('neotex.plugins.tools.himalaya.ui').read_current_email()
  end, {
    desc = 'Read selected email',
  })
  
  vim.api.nvim_create_user_command('HimalayaAttach', function(opts)
    require('neotex.plugins.tools.himalaya.ui').attach_file()
  end, {
    desc = 'Attach file to email',
  })
  
  vim.api.nvim_create_user_command('HimalayaSwitch', function(opts)
    require('neotex.plugins.tools.himalaya.picker').pick_account()
  end, {
    desc = 'Switch email account',
  })
  
  vim.api.nvim_create_user_command('HimalayaFolder', function(opts)
    require('neotex.plugins.tools.himalaya.picker').pick_folder()
  end, {
    desc = 'Change email folder',
  })
  
  vim.api.nvim_create_user_command('HimalayaCompose', function(opts)
    require('neotex.plugins.tools.himalaya.ui').compose_draft()
  end, {
    desc = 'Compose email as draft',
  })
  
  vim.api.nvim_create_user_command('HimalayaExpunge', function(opts)
    require('neotex.plugins.tools.himalaya.utils').expunge_deleted()
  end, {
    desc = 'Permanently remove deleted emails',
  })
  
  vim.api.nvim_create_user_command('HimalayaTags', function(opts)
    require('neotex.plugins.tools.himalaya.ui').manage_tags()
  end, {
    desc = 'Manage email tags',
  })
  
  vim.api.nvim_create_user_command('HimalayaInfo', function(opts)
    require('neotex.plugins.tools.himalaya.ui').show_email_info()
  end, {
    desc = 'Show email info',
  })
end

return M