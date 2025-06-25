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
  
  -- Enhanced sync using mbsync for true bidirectional sync
  vim.api.nvim_create_user_command('HimalayaEnhancedSync', function(opts)
    require('neotex.plugins.tools.himalaya.native_sync').enhanced_sync(opts.bang)
  end, {
    bang = true,
    desc = 'Enhanced mail sync with mbsync (use ! to force)',
  })
  
  -- Quick sync for current folder
  vim.api.nvim_create_user_command('HimalayaQuickSync', function(opts)
    require('neotex.plugins.tools.himalaya.native_sync').quick_sync(opts.args)
  end, {
    nargs = '?',
    desc = 'Quick sync for specific folder',
  })
  
  -- Force sync with --force flag
  vim.api.nvim_create_user_command('HimalayaForceSync', function(opts)
    require('neotex.plugins.tools.himalaya.native_sync').enhanced_sync(true)
  end, {
    desc = 'Force sync with mbsync --force flag',
  })
  
  -- Cancel ongoing sync
  vim.api.nvim_create_user_command('HimalayaCancelSync', function(opts)
    require('neotex.plugins.tools.himalaya.native_sync').cancel_sync()
  end, {
    desc = 'Cancel ongoing sync operation',
  })
  
  -- Fix mbsync configuration and corrupted maildir
  vim.api.nvim_create_user_command('HimalayaFixMbsync', function(opts)
    require('neotex.plugins.tools.himalaya.fix_mbsync').fix_all()
  end, {
    desc = 'Fix corrupted mbsync configuration and maildir',
  })
  
  -- Show manual fix steps
  vim.api.nvim_create_user_command('HimalayaMbsyncHelp', function(opts)
    require('neotex.plugins.tools.himalaya.fix_mbsync').show_manual_steps()
  end, {
    desc = 'Show manual steps to fix mbsync issues',
  })
  
  -- Auto-refresh management
  vim.api.nvim_create_user_command('HimalayaAutoRefresh', function(opts)
    local auto_updates = require('neotex.plugins.tools.himalaya.auto_updates')
    if opts.args == 'toggle' or opts.args == '' then
      auto_updates.toggle()
    elseif opts.args == 'start' then
      auto_updates.start_auto_refresh()
    elseif opts.args == 'stop' then
      auto_updates.stop_auto_refresh()
    elseif tonumber(opts.args) then
      auto_updates.set_interval(tonumber(opts.args))
    end
  end, {
    nargs = '?',
    complete = function() return {'toggle', 'start', 'stop', '30', '60', '120', '300'} end,
    desc = 'Manage automatic refresh: toggle/start/stop or set interval (seconds)',
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
  
  -- Debug mode toggle command (uses unified notification system)
  vim.api.nvim_create_user_command('HimalayaDebug', function()
    local notify = require('neotex.util.notifications')
    notify.toggle_debug_mode()
  end, {
    desc = 'Toggle debug mode (unified)',
  })
  
  -- OAuth token refresh command
  vim.api.nvim_create_user_command('HimalayaRefreshOAuth', function()
    local notify = require('neotex.util.notifications')
    
    -- Check if the refresh script exists
    local refresh_script = '/home/benjamin/.nix-profile/bin/refresh-gmail-oauth2'
    if vim.fn.filereadable(refresh_script) == 0 then
      notify.himalaya('OAuth refresh script not found', notify.categories.ERROR)
      notify.himalaya('Please ensure gmail OAuth is configured in your Nix setup', notify.categories.STATUS)
      return
    end
    
    notify.himalaya('Refreshing OAuth token...', notify.categories.STATUS)
    
    -- Run the refresh script
    vim.fn.jobstart({refresh_script}, {
      on_exit = function(_, exit_code)
        if exit_code == 0 then
          notify.himalaya('OAuth token refreshed successfully', notify.categories.USER_ACTION)
          notify.himalaya('Try syncing again with :HimalayaSync', notify.categories.STATUS)
        else
          notify.himalaya('OAuth token refresh failed', notify.categories.ERROR)
          notify.himalaya('You may need to reconfigure: himalaya account configure gmail', notify.categories.STATUS)
        end
      end,
      on_stderr = function(_, data)
        if data and #data > 0 then
          for _, line in ipairs(data) do
            if line and line ~= '' then
              notify.himalaya('OAuth refresh error: ' .. line, notify.categories.ERROR)
            end
          end
        end
      end,
    })
  end, {
    desc = 'Refresh Gmail OAuth2 token',
  })
  
  -- OAuth status check command
  vim.api.nvim_create_user_command('HimalayaOAuthStatus', function()
    local notify = require('neotex.util.notifications')
    
    -- Check systemd timer status
    local timer_status = vim.fn.system('systemctl --user is-active gmail-oauth2-refresh.timer')
    local service_status = vim.fn.system('systemctl --user status gmail-oauth2-refresh.service --no-pager -n 5')
    
    notify.himalaya('OAuth Timer Status: ' .. timer_status:gsub('%s+$', ''), notify.categories.STATUS)
    
    -- Check for stored credentials
    local has_refresh_token = vim.fn.system('secret-tool lookup service himalaya-cli username gmail-smtp-oauth2-refresh-token 2>/dev/null')
    if has_refresh_token and has_refresh_token ~= '' then
      notify.himalaya('OAuth refresh token found in keyring', notify.categories.STATUS)
    else
      notify.himalaya('No OAuth refresh token found', notify.categories.ERROR)
      notify.himalaya('Run: himalaya account configure gmail', notify.categories.STATUS)
    end
    
    -- Show recent service logs
    notify.himalaya('Recent OAuth refresh attempts:', notify.categories.STATUS)
    local logs = vim.fn.system('journalctl --user -u gmail-oauth2-refresh.service -n 5 --no-pager --output=cat')
    for line in logs:gmatch('[^\n]+') do
      if line:match('error') or line:match('failed') then
        notify.himalaya(line, notify.categories.ERROR)
      else
        notify.himalaya(line, notify.categories.STATUS)
      end
    end
  end, {
    desc = 'Check Gmail OAuth2 status',
  })
  
  -- Reconfigure account command (wrapper for himalaya account configure)
  vim.api.nvim_create_user_command('HimalayaReconfigureGmail', function()
    local notify = require('neotex.util.notifications')
    notify.himalaya('Opening terminal for Gmail reconfiguration...', notify.categories.STATUS)
    notify.himalaya('Follow the OAuth flow to get new tokens', notify.categories.STATUS)
    
    -- Open in a new terminal split
    vim.cmd('split | terminal himalaya account configure gmail')
    vim.cmd('startinsert')
  end, {
    desc = 'Reconfigure Gmail account with OAuth',
  })
  
  -- OAuth troubleshooting command
  vim.api.nvim_create_user_command('HimalayaOAuthTroubleshoot', function()
    local utils = require('neotex.plugins.tools.himalaya.utils')
    local notify = require('neotex.util.notifications')
    
    notify.himalaya('Diagnosing OAuth authentication issues...', notify.categories.STATUS)
    
    local issues, suggestions = utils.diagnose_oauth_auth()
    
    -- Display issues
    notify.himalaya('=== OAuth Diagnostic Results ===', notify.categories.STATUS)
    for _, issue in ipairs(issues) do
      local level = issue:match('✓') and notify.categories.STATUS or notify.categories.WARNING
      notify.himalaya(issue, level)
    end
    
    -- Display suggestions if any
    if #suggestions > 0 then
      notify.himalaya('', notify.categories.STATUS)
      notify.himalaya('=== Suggested Actions ===', notify.categories.STATUS)
      for i, suggestion in ipairs(suggestions) do
        notify.himalaya(i .. '. ' .. suggestion, notify.categories.STATUS)
      end
    end
    
    -- Quick actions menu
    if #suggestions > 0 then
      vim.defer_fn(function()
        vim.ui.select({
          'Try manual OAuth refresh',
          'Reconfigure Gmail account', 
          'Check mbsync configuration',
          'Open OAuth setup documentation',
          'Cancel'
        }, {
          prompt = 'OAuth Action:',
        }, function(choice)
          if choice == 'Try manual OAuth refresh' then
            vim.cmd('HimalayaRefreshOAuth')
          elseif choice == 'Reconfigure Gmail account' then
            vim.cmd('HimalayaReconfigureGmail')
          elseif choice == 'Check mbsync configuration' then
            vim.cmd('HimalayaAnalyzeMbsync')
          elseif choice == 'Open OAuth setup documentation' then
            M.show_oauth_help()
          end
        end)
      end, 100)
    end
  end, {
    desc = 'Troubleshoot Gmail OAuth authentication issues',
  })
  
  -- Cancel sync command
  vim.api.nvim_create_user_command('HimalayaCancelSync', function()
    require('neotex.plugins.tools.himalaya.native_sync').cancel_sync()
  end, {
    desc = 'Cancel ongoing mail sync',
  })
  
  -- Force sync command (with mbsync --force flag)
  vim.api.nvim_create_user_command('HimalayaForceSync', function()
    require('neotex.plugins.tools.himalaya.native_sync').enhanced_sync(true)
  end, {
    desc = 'Force mail sync with mbsync --force',
  })
end

-- Show OAuth setup help
function M.show_oauth_help()
  local help_content = {
    '# Gmail OAuth2 Setup Guide',
    '',
    '## Common Issues and Solutions',
    '',
    '### 1. AUTHENTICATIONFAILED Error',
    'This usually means your OAuth token has expired or is invalid.',
    '',
    '**Quick Fix:**',
    '- Run `:HimalayaRefreshOAuth` to refresh the token',
    '- If that fails, run `:HimalayaReconfigureGmail`',
    '',
    '### 2. "invalid_client" Error',
    'Your OAuth client ID is not recognized by Google.',
    '',
    '**Solutions:**',
    '- Check GMAIL_CLIENT_ID environment variable is set correctly',
    '- Verify the OAuth app in Google Cloud Console is active',
    '- Ensure the client ID matches your OAuth app',
    '',
    '### 3. Missing Refresh Token',
    'The OAuth refresh token is not stored in the keyring.',
    '',
    '**Solution:**',
    '- Run: `himalaya account configure gmail`',
    '- Complete the OAuth flow in your browser',
    '',
    '## Manual Token Refresh',
    '',
    'If automatic refresh fails, you can:',
    '1. Run the refresh script manually:',
    '   `/home/benjamin/.nix-profile/bin/refresh-gmail-oauth2`',
    '',
    '2. Check the systemd timer:',
    '   `systemctl --user status gmail-oauth2-refresh.timer`',
    '',
    '3. View recent logs:',
    '   `journalctl --user -u gmail-oauth2-refresh.service -f`',
    '',
    '## OAuth Configuration in mbsync',
    '',
    'Ensure your ~/.mbsyncrc has:',
    '```',
    'IMAPAccount gmail',
    'Host imap.gmail.com',
    'User your-email@gmail.com',
    'AuthMechs XOAUTH2',
    'PassCmd "secret-tool lookup service himalaya-cli username gmail-smtp-oauth2-access-token"',
    '```',
    '',
    '## Available Commands',
    '',
    '- `:HimalayaOAuthStatus` - Check OAuth status',
    '- `:HimalayaRefreshOAuth` - Manually refresh token',
    '- `:HimalayaReconfigureGmail` - Reconfigure Gmail account',
    '- `:HimalayaOAuthTroubleshoot` - Run full diagnostics',
  }
  
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, help_content)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  local ui = require('neotex.plugins.tools.himalaya.ui')
  ui.open_email_window(buf, 'Gmail OAuth2 Help')
end

return M