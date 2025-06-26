-- Full Mailbox Cleanup Module
-- Complete reset of email system

local M = {}

local notify = require('neotex.util.notifications')

-- Show current mailbox status
function M.mailbox_status()
  notify.himalaya('=== MAILBOX STATUS ===', notify.categories.USER_ACTION)
  
  -- Count files in INBOX
  local inbox_cmd = 'find ~/Mail/Gmail/INBOX -type f | grep -E "/cur/|/new/" | wc -l'
  local handle = io.popen(inbox_cmd)
  local inbox_count = 0
  if handle then
    inbox_count = tonumber(handle:read('*a')) or 0
    handle:close()
  end
  
  -- Count ALL files
  local all_cmd = 'find ~/Mail/Gmail -type f | grep -E "/cur/|/new/" | wc -l'
  handle = io.popen(all_cmd)
  local all_count = 0
  if handle then
    all_count = tonumber(handle:read('*a')) or 0
    handle:close()
  end
  
  -- List folders with counts
  local folders_cmd = [[find ~/Mail/Gmail -type d -name "cur" | sed 's|/cur||' | while read folder; do count=$(find "$folder" -type f | grep -E "/cur/|/new/" | wc -l); if [ $count -gt 0 ]; then echo "$count emails in: $folder"; fi; done | sort -rn | head -10]]
  
  notify.himalaya(string.format('INBOX emails: %d', inbox_count), notify.categories.STATUS)
  notify.himalaya(string.format('Total emails across all folders: %d', all_count), notify.categories.STATUS)
  notify.himalaya('', notify.categories.STATUS)
  notify.himalaya('Top folders by email count:', notify.categories.STATUS)
  
  handle = io.popen(folders_cmd)
  if handle then
    local output = handle:read('*a')
    handle:close()
    for line in output:gmatch('[^\n]+') do
      notify.himalaya('  ' .. line, notify.categories.STATUS)
    end
  end
end

-- Nuclear option - delete everything and start fresh
function M.nuclear_reset()
  notify.himalaya('⚠️  NUCLEAR RESET - This will:', notify.categories.WARNING)
  notify.himalaya('  1. Kill all sync processes', notify.categories.WARNING)
  notify.himalaya('  2. Delete ALL local emails (94k+ files!)', notify.categories.WARNING)
  notify.himalaya('  3. Clear all databases and caches', notify.categories.WARNING)
  notify.himalaya('  4. Require complete resync from server', notify.categories.WARNING)
  notify.himalaya('', notify.categories.WARNING)
  notify.himalaya('To proceed, run: :HimalayaConfirmNuclearReset', notify.categories.USER_ACTION)
end

function M.confirm_nuclear_reset()
  notify.himalaya('🔥 NUCLEAR RESET INITIATED 🔥', notify.categories.USER_ACTION)
  
  -- 1. Kill all processes
  notify.himalaya('1. Killing all sync processes...', notify.categories.STATUS)
  os.execute('pkill -9 mbsync 2>/dev/null')
  os.execute('pkill -9 himalaya 2>/dev/null')
  
  -- 2. Backup current state
  notify.himalaya('2. Creating final backup...', notify.categories.STATUS)
  local backup_name = 'Gmail-nuclear-backup-' .. os.date('%Y%m%d-%H%M%S')
  os.execute('mkdir -p ~/Mail/' .. backup_name)
  os.execute('cp -r ~/Mail/Gmail ~/Mail/' .. backup_name .. '/')
  
  -- 3. Remove Gmail folder completely
  notify.himalaya('3. Removing Gmail folder...', notify.categories.STATUS)
  os.execute('rm -rf ~/Mail/Gmail')
  
  -- 4. Clear Himalaya database
  notify.himalaya('4. Clearing Himalaya database...', notify.categories.STATUS)
  os.execute('rm -rf ~/.local/share/himalaya/.id-mappers')
  
  -- 5. Clear any caches
  notify.himalaya('5. Clearing all caches...', notify.categories.STATUS)
  os.execute('rm -rf ~/.cache/himalaya 2>/dev/null')
  
  -- 6. Recreate clean structure
  notify.himalaya('6. Creating clean Gmail structure...', notify.categories.STATUS)
  os.execute('mkdir -p ~/Mail/Gmail/INBOX/{cur,new,tmp}')
  
  notify.himalaya('', notify.categories.USER_ACTION)
  notify.himalaya('✅ NUCLEAR RESET COMPLETE', notify.categories.USER_ACTION)
  notify.himalaya('', notify.categories.STATUS)
  notify.himalaya('Next steps:', notify.categories.STATUS)
  notify.himalaya('1. Exit and restart Neovim', notify.categories.STATUS)
  notify.himalaya('2. Run :HimalayaSyncFull to sync from server', notify.categories.STATUS)
  notify.himalaya('3. You should get exactly 2,067 emails', notify.categories.STATUS)
  notify.himalaya('', notify.categories.STATUS)
  notify.himalaya('Backup saved to: ~/Mail/' .. backup_name, notify.categories.STATUS)
end

-- Setup commands
function M.setup_commands()
  vim.api.nvim_create_user_command('HimalayaMailboxStatus', M.mailbox_status, {
    desc = 'Show detailed mailbox status'
  })
  
  vim.api.nvim_create_user_command('HimalayaNuclearReset', M.nuclear_reset, {
    desc = 'Complete reset - delete ALL local emails'
  })
  
  vim.api.nvim_create_user_command('HimalayaConfirmNuclearReset', M.confirm_nuclear_reset, {
    desc = 'Confirm nuclear reset'
  })
end

return M