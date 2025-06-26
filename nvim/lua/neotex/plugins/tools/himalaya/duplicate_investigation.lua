-- Duplicate Email Investigation Module
-- Comprehensive analysis of email duplication issues

local M = {}

local notify = require('neotex.util.notifications')

-- Investigate the root cause of email duplication
function M.investigate_duplicates()
  notify.himalaya('=== DUPLICATE INVESTIGATION STARTED ===', notify.categories.USER_ACTION)
  
  local report = {}
  
  -- 1. Check Maildir structure
  notify.himalaya('1. Checking Maildir structure...', notify.categories.STATUS)
  
  -- Count actual files in INBOX
  local inbox_files_cmd = 'find ~/Mail/Gmail/INBOX -type f -name "*" | grep -v "^\\." | wc -l'
  local handle = io.popen(inbox_files_cmd)
  local inbox_file_count = 0
  if handle then
    local result = handle:read('*a')
    handle:close()
    inbox_file_count = tonumber(result:match('%d+')) or 0
  end
  
  table.insert(report, string.format('Physical files in INBOX: %d', inbox_file_count))
  
  -- Check for duplicate filenames
  local dup_files_cmd = 'find ~/Mail/Gmail/INBOX -type f -name "*" | grep -v "^\\." | sort | uniq -d | wc -l'
  handle = io.popen(dup_files_cmd)
  local dup_file_count = 0
  if handle then
    local result = handle:read('*a')
    handle:close()
    dup_file_count = tonumber(result:match('%d+')) or 0
  end
  
  table.insert(report, string.format('Duplicate filenames: %d', dup_file_count))
  
  -- 2. Check mbsync database
  notify.himalaya('2. Checking mbsync state...', notify.categories.STATUS)
  
  -- Check .mbsyncstate file
  local mbsync_state_cmd = 'cat ~/Mail/Gmail/INBOX/.mbsyncstate 2>/dev/null | head -5'
  handle = io.popen(mbsync_state_cmd)
  if handle then
    local state_content = handle:read('*a')
    handle:close()
    if state_content and state_content ~= "" then
      table.insert(report, 'mbsync state file exists')
    else
      table.insert(report, 'mbsync state file missing or empty')
    end
  end
  
  -- 3. Check Himalaya's view
  notify.himalaya('3. Checking Himalaya output...', notify.categories.STATUS)
  
  local config = require('neotex.plugins.tools.himalaya.config')
  local utils = require('neotex.plugins.tools.himalaya.utils')
  
  -- Get emails from Himalaya
  local emails = utils.get_email_list(config.state.current_account, 'INBOX', 1, 200)
  local himalaya_count = emails and #emails or 0
  
  table.insert(report, string.format('Emails in Himalaya view: %d', himalaya_count))
  
  -- Analyze duplicates by Message-ID
  if emails and #emails > 0 then
    local message_ids = {}
    local duplicate_msgs = {}
    
    for _, email in ipairs(emails) do
      local msg_id = email.id or email.message_id or 'unknown'
      if message_ids[msg_id] then
        message_ids[msg_id] = message_ids[msg_id] + 1
        if message_ids[msg_id] == 2 then
          table.insert(duplicate_msgs, {
            id = msg_id,
            subject = email.subject,
            count = 2
          })
        elseif message_ids[msg_id] > 2 then
          -- Update count
          for _, dup in ipairs(duplicate_msgs) do
            if dup.id == msg_id then
              dup.count = message_ids[msg_id]
              break
            end
          end
        end
      else
        message_ids[msg_id] = 1
      end
    end
    
    if #duplicate_msgs > 0 then
      table.insert(report, string.format('Duplicate Message-IDs: %d unique messages duplicated', #duplicate_msgs))
      
      -- Show worst offenders
      table.sort(duplicate_msgs, function(a, b) return a.count > b.count end)
      for i = 1, math.min(3, #duplicate_msgs) do
        local dup = duplicate_msgs[i]
        table.insert(report, string.format('  - "%s" appears %d times', 
          dup.subject:sub(1, 40), dup.count))
      end
    else
      table.insert(report, 'No duplicate Message-IDs found')
    end
  end
  
  -- 4. Check folder structure
  notify.himalaya('4. Checking folder structure...', notify.categories.STATUS)
  
  -- List all folders
  local folders_cmd = 'find ~/Mail/Gmail -type d -name "INBOX*" | sort'
  handle = io.popen(folders_cmd)
  if handle then
    local folders = handle:read('*a')
    handle:close()
    local folder_count = 0
    for folder in folders:gmatch('[^\n]+') do
      folder_count = folder_count + 1
      if folder_count <= 5 then
        table.insert(report, string.format('Folder: %s', folder))
      end
    end
    if folder_count > 5 then
      table.insert(report, string.format('... and %d more INBOX folders', folder_count - 5))
    end
  end
  
  -- 5. Compare with server
  notify.himalaya('5. Server comparison...', notify.categories.STATUS)
  
  -- Get mbsync status from last sync
  local sync = require('neotex.plugins.tools.himalaya.streamlined_sync')
  local sync_status = sync.get_status()
  
  if sync_status.progress.far_total and sync_status.progress.near_total then
    table.insert(report, string.format('Server messages: %d', sync_status.progress.far_total))
    table.insert(report, string.format('Local messages: %d', sync_status.progress.near_total))
    table.insert(report, string.format('Difference: %d extra local messages', 
      sync_status.progress.near_total - sync_status.progress.far_total))
  end
  
  -- Print report
  notify.himalaya('=== INVESTIGATION REPORT ===', notify.categories.USER_ACTION)
  for _, line in ipairs(report) do
    notify.himalaya(line, notify.categories.STATUS)
  end
  
  -- Recommendations
  notify.himalaya('=== RECOMMENDATIONS ===', notify.categories.USER_ACTION)
  
  if himalaya_count > inbox_file_count then
    notify.himalaya('⚠️  Himalaya sees more emails than exist in Maildir', notify.categories.WARNING)
    notify.himalaya('   → Try: :HimalayaRebuildIndex', notify.categories.STATUS)
  end
  
  if inbox_file_count > 10000 then
    notify.himalaya('⚠️  Very large local mailbox detected', notify.categories.WARNING)
    notify.himalaya('   → Consider full reset: delete ~/Mail/Gmail/INBOX and resync', notify.categories.STATUS)
  end
  
  if dup_file_count > 0 then
    notify.himalaya('⚠️  Duplicate files in Maildir', notify.categories.WARNING)
    notify.himalaya('   → Try: :HimalayaFixDuplicates', notify.categories.STATUS)
  end
  
  notify.himalaya('=== INVESTIGATION COMPLETE ===', notify.categories.USER_ACTION)
end

-- Clear Himalaya's database cache
function M.clear_himalaya_database()
  notify.himalaya('Clearing Himalaya database cache...', notify.categories.USER_ACTION)
  
  -- Clear the ID mapper database
  local db_path = vim.fn.expand('~/.local/share/himalaya/.id-mappers')
  if vim.fn.isdirectory(db_path) == 1 then
    notify.himalaya('Removing Himalaya ID mapper database...', notify.categories.STATUS)
    os.execute('rm -rf ' .. db_path)
    notify.himalaya('Himalaya database cleared', notify.categories.STATUS)
  else
    notify.himalaya('No Himalaya database found', notify.categories.STATUS)
  end
  
  -- Clear in-memory cache
  local utils = require('neotex.plugins.tools.himalaya.utils')
  local config = require('neotex.plugins.tools.himalaya.config')
  
  -- Clear cache for current account and all common folders
  local account = config.state.current_account or 'gmail'
  local folders = {'INBOX', 'Sent', 'Drafts', 'Trash', 'All Mail'}
  
  for _, folder in ipairs(folders) do
    utils.clear_email_cache(account, folder)
  end
  
  -- Force sidebar refresh if open
  local sidebar = require('neotex.plugins.tools.himalaya.sidebar')
  if sidebar.is_open() then
    notify.himalaya('Refreshing sidebar...', notify.categories.STATUS)
    local ui = require('neotex.plugins.tools.himalaya.ui')
    ui.refresh_sidebar()
  end
  
  notify.himalaya('All Himalaya caches cleared!', notify.categories.USER_ACTION)
  notify.himalaya('Close and reopen sidebar to see fresh emails', notify.categories.STATUS)
end

-- Safe mailbox reset
function M.reset_mailbox()
  notify.himalaya('⚠️  MAILBOX RESET - This will delete all local emails!', notify.categories.WARNING)
  notify.himalaya('To confirm, run: :HimalayaConfirmReset', notify.categories.USER_ACTION)
end

function M.confirm_reset()
  notify.himalaya('Starting mailbox reset...', notify.categories.USER_ACTION)
  
  -- Kill any running sync
  local sync = require('neotex.plugins.tools.himalaya.streamlined_sync')
  sync.emergency_cleanup()
  
  -- Clear Himalaya cache
  local utils = require('neotex.plugins.tools.himalaya.utils')
  utils.clear_cache()
  
  -- Backup current state
  notify.himalaya('Creating backup...', notify.categories.STATUS)
  os.execute('mkdir -p ~/Mail/Gmail-backup')
  os.execute('cp -r ~/Mail/Gmail/INBOX ~/Mail/Gmail-backup/INBOX-' .. os.date('%Y%m%d-%H%M%S'))
  
  -- Remove INBOX
  notify.himalaya('Removing INBOX directory...', notify.categories.STATUS)
  os.execute('rm -rf ~/Mail/Gmail/INBOX')
  os.execute('rm -f ~/Mail/Gmail/.mbsyncstate*')
  
  -- Recreate clean structure
  notify.himalaya('Creating clean INBOX...', notify.categories.STATUS)
  os.execute('mkdir -p ~/Mail/Gmail/INBOX/{cur,new,tmp}')
  
  notify.himalaya('Mailbox reset complete!', notify.categories.USER_ACTION)
  notify.himalaya('Run :HimalayaSyncFull to download fresh emails from server', notify.categories.STATUS)
end

-- Setup commands
function M.setup_commands()
  vim.api.nvim_create_user_command('HimalayaInvestigateDuplicates', M.investigate_duplicates, {
    desc = 'Comprehensive duplicate investigation'
  })
  
  vim.api.nvim_create_user_command('HimalayaClearDatabase', M.clear_himalaya_database, {
    desc = 'Clear Himalaya database cache'
  })
  
  vim.api.nvim_create_user_command('HimalayaResetMailbox', M.reset_mailbox, {
    desc = 'Reset local mailbox (delete all local emails)'
  })
  
  vim.api.nvim_create_user_command('HimalayaConfirmReset', M.confirm_reset, {
    desc = 'Confirm mailbox reset'
  })
end

return M