-- Maildir++ Setup Module
-- Automatically creates maildir++ structure for new users based on their IMAP folders

local M = {}

local notify = require('neotex.util.notifications')

-- Check if mail directory exists and has proper structure
function M.check_maildir_exists()
  local config = require('neotex.plugins.tools.himalaya.config')
  local account = config.get_current_account_name() or 'gmail'
  local mail_dir = vim.fn.expand('~/Mail/' .. account:gsub("^%l", string.upper))
  
  -- Check if base mail directory exists
  if vim.fn.isdirectory(mail_dir) == 0 then
    return false, mail_dir
  end
  
  -- Check for basic maildir++ structure (cur, new, tmp in root for INBOX)
  local has_cur = vim.fn.isdirectory(mail_dir .. '/cur') == 1
  local has_new = vim.fn.isdirectory(mail_dir .. '/new') == 1
  local has_tmp = vim.fn.isdirectory(mail_dir .. '/tmp') == 1
  
  return has_cur and has_new and has_tmp, mail_dir
end

-- Get IMAP folders from himalaya CLI
function M.get_imap_folders()
  local config = require('neotex.plugins.tools.himalaya.config')
  local account = config.get_current_account_name() or 'gmail'
  
  notify.himalaya('🔍 Discovering IMAP folders...', notify.categories.STATUS)
  
  -- Use himalaya to list folders from IMAP server
  -- Note: himalaya folder list shows LOCAL folders, not IMAP folders
  -- For initial setup, we need to use default Gmail IMAP folder structure
  local cmd = 'echo "Using default Gmail folder structure"'
  local output = nil
  
  if vim.v.shell_error ~= 0 or not output then
    -- Always use Gmail IMAP folder structure for initial setup
    notify.himalaya('📋 Using standard Gmail folder structure', notify.categories.STATUS)
    return {
      { name = 'INBOX', delim = '/' },
      { name = '[Gmail]/Sent Mail', delim = '/' },
      { name = '[Gmail]/Drafts', delim = '/' },
      { name = '[Gmail]/All Mail', delim = '/' },
      { name = '[Gmail]/Spam', delim = '/' },
      { name = '[Gmail]/Trash', delim = '/' },
      { name = '[Gmail]/Starred', delim = '/' },
      { name = '[Gmail]/Important', delim = '/' },
    }
  end
  
  -- Parse JSON output
  local ok, folders = pcall(vim.json.decode, output)
  if not ok or not folders then
    notify.himalaya('⚠️  Could not parse folder list, using defaults', notify.categories.WARNING)
    return M.get_default_folders()
  end
  
  return folders
end

-- Get default folder structure (fallback)
function M.get_default_folders()
  return {
    { name = 'INBOX', delim = '/' },
    { name = 'Sent', delim = '/' },
    { name = 'Drafts', delim = '/' },
    { name = 'Trash', delim = '/' },
    { name = 'Spam', delim = '/' },
    { name = 'Archive', delim = '/' },
  }
end

-- Convert IMAP folder name to maildir++ format
function M.imap_to_maildir_name(folder_name)
  -- INBOX is special - it goes in the root directory
  if folder_name == 'INBOX' or folder_name == '' then
    return ''
  end
  
  -- Handle Gmail special folders according to mbsync configuration
  -- Map [Gmail]/Folder to simple .Folder names as configured in mbsyncrc
  local gmail_mappings = {
    ['[Gmail]/Sent Mail'] = '.Sent',
    ['[Gmail]/Drafts'] = '.Drafts',
    ['[Gmail]/Trash'] = '.Trash',
    ['[Gmail]/All Mail'] = '.All_Mail',
    ['[Gmail]/Spam'] = '.Spam',
    ['[Gmail]/Starred'] = '.Starred',
    ['[Gmail]/Important'] = '.Important',
  }
  
  -- Check if this is a mapped Gmail folder
  if gmail_mappings[folder_name] then
    return gmail_mappings[folder_name]
  end
  
  -- For other folders, just add a dot prefix
  -- EuroTrip -> .EuroTrip
  return '.' .. folder_name
end

-- Create maildir++ structure for a single folder
function M.create_maildir_folder(base_dir, folder_name)
  local maildir_name = M.imap_to_maildir_name(folder_name)
  local folder_path = base_dir
  
  if maildir_name ~= '' then
    folder_path = base_dir .. '/' .. maildir_name
  end
  
  -- Create the folder with cur, new, tmp subdirectories
  local dirs = { folder_path, folder_path .. '/cur', folder_path .. '/new', folder_path .. '/tmp' }
  
  for _, dir in ipairs(dirs) do
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, 'p')
    end
  end
  
  -- Create UIDVALIDITY file for this folder
  -- This is required by IMAP/Maildir++ specification for proper synchronization
  -- For INBOX (empty maildir_name), the file is .uidvalidity in the base directory
  local uidvalidity_file
  if maildir_name == '' then
    uidvalidity_file = base_dir .. '/.uidvalidity'
  else
    uidvalidity_file = folder_path .. '/.uidvalidity'
  end
  
  if vim.fn.filereadable(uidvalidity_file) == 0 then
    -- Create empty file - mbsync will populate it with correct UIDVALIDITY
    vim.fn.writefile({}, uidvalidity_file)
  end
  
  return true
end

-- Setup maildir++ structure for all IMAP folders
function M.setup_maildir_structure(mail_dir, folders)
  notify.himalaya('📁 Creating maildir++ structure...', notify.categories.STATUS)
  
  -- Create base mail directory
  if vim.fn.isdirectory(mail_dir) == 0 then
    vim.fn.mkdir(mail_dir, 'p')
  end
  
  -- Create maildir++ structure for each folder
  local created_count = 0
  for _, folder in ipairs(folders) do
    if M.create_maildir_folder(mail_dir, folder.name) then
      created_count = created_count + 1
    end
  end
  
  notify.himalaya(string.format('✅ Created %d folders in maildir++ format', created_count), notify.categories.USER_ACTION)
  
  return true
end

-- Create mbsyncrc configuration for the account
function M.create_mbsync_config(account, mail_dir)
  local config = require('neotex.plugins.tools.himalaya.config')
  local account_info = config.get_current_account()
  
  notify.himalaya('🔧 Checking mbsync configuration...', notify.categories.STATUS)
  
  -- Check if .mbsyncrc exists
  local mbsyncrc = vim.fn.expand('~/.mbsyncrc')
  if vim.fn.filereadable(mbsyncrc) == 0 then
    notify.himalaya('⚠️  No .mbsyncrc found - please configure mbsync manually', notify.categories.WARNING)
    notify.himalaya('See: https://wiki.archlinux.org/title/Isync', notify.categories.STATUS)
    return false
  end
  
  -- Check if account is already configured
  local content = vim.fn.readfile(mbsyncrc)
  local has_account = false
  for _, line in ipairs(content) do
    if line:match('^IMAPAccount%s+' .. account) then
      has_account = true
      break
    end
  end
  
  if has_account then
    notify.himalaya('✅ mbsync already configured for ' .. account, notify.categories.STATUS)
    return true
  else
    notify.himalaya('⚠️  Account not found in .mbsyncrc - please add configuration', notify.categories.WARNING)
    notify.himalaya('Account: ' .. account .. ', Email: ' .. account_info.email, notify.categories.STATUS)
    return false
  end
end

-- Setup without prompting (for use after backup)
function M.setup_maildir_no_prompt()
  local exists, mail_dir = M.check_maildir_exists()
  
  if exists then
    return true
  end
  
  local config = require('neotex.plugins.tools.himalaya.config')
  local account = config.get_current_account_name() or 'gmail'
  
  notify.himalaya('📁 Creating fresh maildir++ structure...', notify.categories.STATUS)
  
  -- Get IMAP folders
  local folders = M.get_imap_folders()
  
  if #folders == 0 then
    notify.himalaya('❌ No folders found - please check your account configuration', notify.categories.ERROR)
    return false
  end
  
  -- Show discovered folders
  local folder_names = vim.tbl_map(function(f) return f.name end, folders)
  notify.himalaya('📋 Found folders: ' .. table.concat(folder_names, ', '), notify.categories.STATUS)
  
  -- Create maildir structure
  if M.setup_maildir_structure(mail_dir, folders) then
    -- Check/create mbsync config
    M.create_mbsync_config(account, mail_dir)
    
    notify.himalaya('🎉 Maildir setup complete! You can now sync your email.', notify.categories.USER_ACTION)
    notify.himalaya('Run :HimalayaSyncFull to perform initial sync', notify.categories.STATUS)
    
    -- Refresh UI if open
    local ui = require('neotex.plugins.tools.himalaya.ui')
    if ui.is_email_buffer_open and ui.is_email_buffer_open() then
      vim.defer_fn(function()
        ui.refresh_email_list()
      end, 1000)
    end
    
    return true
  else
    notify.himalaya('❌ Failed to create maildir structure', notify.categories.ERROR)
    return false
  end
end

-- Main setup function with user confirmation
function M.setup_maildir_if_needed()
  local exists, mail_dir = M.check_maildir_exists()
  
  if exists then
    -- Mail directory already exists and has proper structure
    return true
  end
  
  -- Prompt user for confirmation
  local config = require('neotex.plugins.tools.himalaya.config')
  local account = config.get_current_account_name() or 'gmail'
  
  local prompt = 'Create new maildir++ structure? (y/n): '
  
  vim.ui.input({ prompt = prompt }, function(input)
    if not input or input:lower() ~= 'y' then
      notify.himalaya('❌ Maildir setup cancelled', notify.categories.USER_ACTION)
      return
    end
    
    -- Proceed with setup
    vim.schedule(function()
      -- Get IMAP folders
      local folders = M.get_imap_folders()
      
      if #folders == 0 then
        notify.himalaya('❌ No folders found - please check your account configuration', notify.categories.ERROR)
        return
      end
      
      -- Show discovered folders
      local folder_names = vim.tbl_map(function(f) return f.name end, folders)
      notify.himalaya('📋 Found folders: ' .. table.concat(folder_names, ', '), notify.categories.STATUS)
      
      -- Create maildir structure
      if M.setup_maildir_structure(mail_dir, folders) then
        -- Check/create mbsync config
        M.create_mbsync_config(account, mail_dir)
        
        notify.himalaya('🎉 Maildir setup complete! You can now sync your email.', notify.categories.USER_ACTION)
        notify.himalaya('Run :HimalayaSyncFull to perform initial sync', notify.categories.STATUS)
        
        -- Refresh UI if open
        local ui = require('neotex.plugins.tools.himalaya.ui')
        if ui.is_email_buffer_open and ui.is_email_buffer_open() then
          vim.defer_fn(function()
            ui.refresh_email_list()
          end, 1000)
        end
      else
        notify.himalaya('❌ Failed to create maildir structure', notify.categories.ERROR)
      end
    end)
  end)
end

-- Check and setup on first Himalaya open
function M.ensure_maildir_exists()
  -- Don't trigger maildir setup if sync is running to avoid state interference
  local sync = require('neotex.plugins.tools.himalaya.streamlined_sync')
  if sync.is_sync_running_globally() then
    return true -- Assume maildir exists during sync
  end
  
  local exists, mail_dir = M.check_maildir_exists()
  
  if not exists then
    -- Defer the setup prompt slightly to let UI initialize
    vim.defer_fn(function()
      M.setup_maildir_if_needed()
    end, 100)
    
    return false
  end
  
  return true
end

-- Helper to fix UIDVALIDITY files after fresh creation
function M.fix_uidvalidity_files(mail_dir)
  -- Find all .uidvalidity files and empty them
  -- mbsync will populate them with correct format
  local cmd = string.format('find %s -name ".uidvalidity" -exec sh -c \'echo -n > "{}"\' \\; 2>/dev/null', vim.fn.shellescape(mail_dir))
  os.execute(cmd)
  notify.himalaya('✅ Reset UIDVALIDITY files for mbsync', notify.categories.STATUS)
end

-- Backup existing mail directory and start fresh
function M.backup_and_start_fresh()
  local config = require('neotex.plugins.tools.himalaya.config')
  local account = config.get_current_account_name() or 'gmail'
  local mail_dir = vim.fn.expand('~/Mail/' .. account:gsub("^%l", string.upper))
  
  -- Kill any mbsync processes first
  local sync = require('neotex.plugins.tools.himalaya.streamlined_sync')
  sync.kill_existing_processes()
  notify.himalaya('🛑 Stopped all sync processes', notify.categories.STATUS)
  
  -- Check if mail directory exists
  if vim.fn.isdirectory(mail_dir) == 0 then
    notify.himalaya('No existing mail directory', notify.categories.STATUS)
    -- Ask about creating fresh and syncing
    vim.ui.input({ prompt = 'Create fresh maildir and sync all emails? (y/n): ' }, function(input)
      if input and (input:lower() == 'y' or input:lower() == 'yes') then
        vim.schedule(function()
          M.create_fresh_maildir()
          -- Fix UIDVALIDITY files for mbsync
          M.fix_uidvalidity_files(mail_dir)
          -- Ask about syncing
          vim.ui.input({ prompt = 'Sync all emails now? (y/n): ' }, function(sync_input)
            if sync_input and (sync_input:lower() == 'y' or sync_input:lower() == 'yes') then
              vim.defer_fn(function()
                sync.sync_full(true)
              end, 500)
            end
          end)
        end)
      else
        notify.himalaya('❌ Cancelled', notify.categories.USER_ACTION)
      end
    end)
    return
  end
  
  -- Calculate directory info
  local size_cmd = string.format('du -sh %s 2>/dev/null | cut -f1', vim.fn.shellescape(mail_dir))
  local dir_size = vim.fn.system(size_cmd):gsub('\n', '')
  
  local count_cmd = string.format('find %s -type f -name "*" | grep -E "/cur/|/new/" | wc -l', vim.fn.shellescape(mail_dir))
  local email_count = vim.fn.system(count_cmd):gsub('\n', '')
  
  -- Question 1: Backup?
  local backup_prompt = string.format('Backup %s emails (%s)? (y/n): ', email_count, dir_size)
  
  vim.ui.input({ prompt = backup_prompt }, function(backup_input)
    local should_backup = backup_input and (backup_input:lower() == 'y' or backup_input:lower() == 'yes')
    
    -- Question 2: Delete current mail?
    vim.ui.input({ prompt = 'Delete current mail directory? (y/n): ' }, function(delete_input)
      if not delete_input or (delete_input:lower() ~= 'y' and delete_input:lower() ~= 'yes') then
        notify.himalaya('❌ Cancelled - no changes made', notify.categories.USER_ACTION)
        return
      end
      
      vim.schedule(function()
        if should_backup then
          -- Create backup with unique name
          local backup_name = os.date('%Y%m%d_%H%M%S')
          local backup_dir = mail_dir .. '.backup.' .. backup_name
          
          -- Check if backup already exists and make unique if needed
          local attempt = 0
          local final_backup_dir = backup_dir
          while vim.fn.isdirectory(final_backup_dir) == 1 do
            attempt = attempt + 1
            final_backup_dir = backup_dir .. '-' .. attempt
          end
          
          notify.himalaya('📦 Creating backup at: ' .. final_backup_dir, notify.categories.STATUS)
          
          local backup_cmd = string.format('mv %s %s', vim.fn.shellescape(mail_dir), vim.fn.shellescape(final_backup_dir))
          local result = os.execute(backup_cmd)
          
          if result ~= 0 then
            notify.himalaya('❌ Failed to create backup', notify.categories.ERROR)
            return
          end
          
          notify.himalaya('✅ Backup created successfully', notify.categories.USER_ACTION)
        else
          -- No backup - just delete
          notify.himalaya('🗑️  Deleting mail directory without backup...', notify.categories.STATUS)
          local delete_cmd = string.format('rm -rf %s', vim.fn.shellescape(mail_dir))
          local result = os.execute(delete_cmd)
          
          if result ~= 0 then
            notify.himalaya('❌ Failed to delete mail directory', notify.categories.ERROR)
            return
          end
          
          notify.himalaya('✅ Mail directory deleted', notify.categories.USER_ACTION)
        end
        
        -- Clear any cached state
        local state = require('neotex.plugins.tools.himalaya.state')
        state.reset()
        
        -- Clear sync state only if no sync is currently running
        if not sync.is_sync_running_globally() then
          sync.clean_sync_state(true) -- silent
        else
          -- Preserve sync ownership during backup
          notify.himalaya('⏳ Preserving active sync state during backup', notify.categories.STATUS)
        end
        
        -- Remove lock file
        os.remove('/tmp/himalaya-sync.lock')
        
        -- Now set up fresh maildir without prompting (user already confirmed)
        vim.defer_fn(function()
          if M.setup_maildir_no_prompt() then
            -- Fix UIDVALIDITY files for mbsync
            M.fix_uidvalidity_files(mail_dir)
            
            -- Question 3: Sync all mail?
            vim.defer_fn(function()
              vim.ui.input({ prompt = 'Sync all mail now? (y/n): ' }, function(sync_input)
                if sync_input and (sync_input:lower() == 'y' or sync_input:lower() == 'yes') then
                  notify.himalaya('🔄 Starting full mail sync...', notify.categories.USER_ACTION)
                  require('neotex.plugins.tools.himalaya.streamlined_sync').sync_full(true)
                else
                  notify.himalaya('✅ Fresh maildir ready. Run :HimalayaSyncFull when ready to sync.', notify.categories.USER_ACTION)
                end
              end)
            end, 500)
          end
        end, 500)
      end) -- end of vim.schedule
    end) -- end of delete_input callback
  end) -- end of backup_input callback
end

-- Diagnostic function to check maildir structure
function M.diagnose_maildir()
  local config = require('neotex.plugins.tools.himalaya.config')
  local account = config.get_current_account_name() or 'gmail'
  local mail_dir = vim.fn.expand('~/Mail/' .. account:gsub("^%l", string.upper))
  
  notify.himalaya('🔍 Diagnosing maildir structure...', notify.categories.STATUS)
  
  -- Check for problematic files
  local problems = {}
  
  -- Check for .INBOX.uidvalidity
  if vim.fn.filereadable(mail_dir .. '/.INBOX.uidvalidity') == 1 then
    table.insert(problems, '❌ Found .INBOX.uidvalidity - this should not exist')
  end
  
  -- Check INBOX structure
  local has_inbox_cur = vim.fn.isdirectory(mail_dir .. '/cur') == 1
  local has_inbox_new = vim.fn.isdirectory(mail_dir .. '/new') == 1
  local has_inbox_tmp = vim.fn.isdirectory(mail_dir .. '/tmp') == 1
  local has_inbox_uidvalidity = vim.fn.filereadable(mail_dir .. '/.uidvalidity') == 1
  
  if not (has_inbox_cur and has_inbox_new and has_inbox_tmp) then
    table.insert(problems, '❌ INBOX is missing cur/new/tmp directories')
  else
    notify.himalaya('✅ INBOX structure is correct', notify.categories.STATUS)
  end
  
  if not has_inbox_uidvalidity then
    table.insert(problems, '⚠️  INBOX is missing .uidvalidity file')
  else
    -- Check if UIDVALIDITY has proper format
    local uidvalidity_content = vim.fn.readfile(mail_dir .. '/.uidvalidity')
    if #uidvalidity_content == 1 and not uidvalidity_content[1]:match('^%d+$') then
      table.insert(problems, '❌ INBOX .uidvalidity has invalid format (should be empty or mbsync format)')
    elseif #uidvalidity_content == 1 and #uidvalidity_content[1] < 5 then
      table.insert(problems, '❌ INBOX .uidvalidity contains single digit - mbsync needs empty file')
    end
  end
  
  -- Check himalaya config
  local himalaya_config = vim.fn.expand('~/.config/himalaya/config.toml')
  if vim.fn.filereadable(himalaya_config) == 1 then
    local content = vim.fn.readfile(himalaya_config)
    for _, line in ipairs(content) do
      if line:match('folder%.alias%.sent.*=.*"%[Gmail%]') then
        table.insert(problems, '❌ Himalaya config uses IMAP folder names instead of local names')
        table.insert(problems, '   Should be: folder.alias.sent = "Sent"')
        table.insert(problems, '   Not: folder.alias.sent = "[Gmail].Sent Mail"')
        break
      end
    end
  end
  
  -- Report findings
  if #problems > 0 then
    notify.himalaya('🚨 Found issues with maildir structure:', notify.categories.ERROR)
    for _, problem in ipairs(problems) do
      notify.himalaya(problem, notify.categories.WARNING)
    end
    notify.himalaya('💡 Run :HimalayaBackupAndFresh to fix these issues', notify.categories.STATUS)
  else
    notify.himalaya('✅ Maildir structure looks correct!', notify.categories.USER_ACTION)
  end
  
  -- Show current folder mapping
  notify.himalaya('📁 Current folder structure:', notify.categories.STATUS)
  local folders = vim.fn.systemlist('find ' .. vim.fn.shellescape(mail_dir) .. ' -maxdepth 1 -type d -name ".*" | sort')
  for _, folder in ipairs(folders) do
    local basename = vim.fn.fnamemodify(folder, ':t')
    notify.himalaya('   ' .. basename, notify.categories.STATUS)
  end
end

-- Create fresh maildir without backing up
function M.create_fresh_maildir()
  local config = require('neotex.plugins.tools.himalaya.config')
  local account = config.get_current_account_name() or 'gmail'
  local mail_dir = vim.fn.expand('~/Mail/' .. account:gsub("^%l", string.upper))
  
  notify.himalaya('📧 Creating fresh maildir structure...', notify.categories.STATUS)
  
  -- Get IMAP folders
  local folders = M.get_imap_folders()
  
  if #folders == 0 then
    notify.himalaya('❌ No folders found - please check your account configuration', notify.categories.ERROR)
    return false
  end
  
  -- Show discovered folders
  local folder_names = vim.tbl_map(function(f) return f.name end, folders)
  notify.himalaya('📋 Found folders: ' .. table.concat(folder_names, ', '), notify.categories.STATUS)
  
  -- Create maildir structure
  if M.setup_maildir_structure(mail_dir, folders) then
    -- Check/create mbsync config
    M.create_mbsync_config(account, mail_dir)
    
    notify.himalaya('🎉 Fresh maildir created successfully!', notify.categories.USER_ACTION)
    
    -- Refresh UI if open
    local ui = require('neotex.plugins.tools.himalaya.ui')
    if ui.is_email_buffer_open and ui.is_email_buffer_open() then
      vim.defer_fn(function()
        ui.refresh_email_list()
      end, 1000)
    end
    
    return true
  else
    notify.himalaya('❌ Failed to create maildir structure', notify.categories.ERROR)
    return false
  end
end

return M