-- Himalaya Email Client Commands (Simplified)
-- Essential command definitions for email operations

local M = {}

-- Setup function to create essential commands
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
  
  -- Folder selector command
  vim.api.nvim_create_user_command('HimalayaFolder', function()
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
  
  -- Sync commands (using streamlined sync)
  vim.api.nvim_create_user_command('HimalayaSyncInbox', function()
    require('neotex.plugins.tools.himalaya.streamlined_sync').sync_inbox(true)
  end, {
    desc = 'Quick inbox sync',
  })
  
  vim.api.nvim_create_user_command('HimalayaSyncFull', function()
    require('neotex.plugins.tools.himalaya.streamlined_sync').sync_full(true)
  end, {
    desc = 'Full account sync',
  })
  
  -- Cancel sync command
  vim.api.nvim_create_user_command('HimalayaCancelSync', function()
    require('neotex.plugins.tools.himalaya.streamlined_sync').cancel_sync()
  end, {
    desc = 'Cancel ongoing sync',
  })
  
  -- Sync status command
  vim.api.nvim_create_user_command('HimalayaSyncStatus', function()
    require('neotex.plugins.tools.himalaya.streamlined_sync').show_sync_status()
  end, {
    desc = 'Show sync status',
  })
  
  -- Cleanup command
  vim.api.nvim_create_user_command('HimalayaCleanup', function()
    local sync = require('neotex.plugins.tools.himalaya.streamlined_sync')
    local notify = require('neotex.util.notifications')
    
    notify.himalaya('🧹 Starting cleanup...', notify.categories.USER_ACTION)
    
    -- Kill all mbsync processes
    sync.kill_existing_processes()
    
    -- Clean up sync state
    sync.clean_sync_state(false) -- false = not silent, show notifications
    
    -- Remove lock file
    os.remove('/tmp/himalaya-sync.lock')
    
    notify.himalaya('✅ Cleanup complete - all sync processes killed', notify.categories.USER_ACTION)
  end, {
    desc = 'Clean up - kill processes and reset state',
  })
  
  -- Session restoration command
  vim.api.nvim_create_user_command('HimalayaRestore', function(opts)
    if opts.bang then
      require('neotex.plugins.tools.himalaya.ui').restore_session()
    else
      require('neotex.plugins.tools.himalaya.ui').prompt_session_restore()
    end
  end, {
    bang = true,
    desc = 'Restore previous email session (use ! to restore without prompt)',
  })
  
  -- Maildir setup command
  vim.api.nvim_create_user_command('HimalayaSetupMaildir', function()
    require('neotex.plugins.tools.himalaya.maildir_setup').setup_maildir_if_needed()
  end, {
    desc = 'Set up maildir++ structure for email account',
  })
  
  -- Backup and fresh start command
  vim.api.nvim_create_user_command('HimalayaBackupAndFresh', function()
    require('neotex.plugins.tools.himalaya.maildir_setup').backup_and_start_fresh()
  end, {
    desc = 'Backup existing mail and start fresh',
  })
  
  -- OAuth refresh command
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
      detach = false,  -- Ensure proper parent-child relationship to avoid zombies
      on_exit = function(_, exit_code)
        if exit_code == 0 then
          notify.himalaya('OAuth token refreshed successfully', notify.categories.USER_ACTION)
          notify.himalaya('Try syncing again with :HimalayaSyncInbox', notify.categories.STATUS)
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
  
  -- OAuth diagnostics command
  vim.api.nvim_create_user_command('HimalayaOAuthDiagnostics', function()
    require('neotex.plugins.tools.himalaya.oauth_diagnostics').run_diagnostics()
  end, {
    desc = 'Diagnose OAuth2 authentication issues',
  })
end

return M