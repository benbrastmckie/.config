-- Migration module for updating from old Himalaya plugin version
-- Handles configuration updates, file cleanup, and state migration
-- TODO: REMOVE BACKWARDS COMPATIBILITY - This entire migration system should be removed to focus on clean, maintainable code

local M = {}

-- Dependencies  
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local config = require('neotex.plugins.tools.himalaya.core.config')
local state = require('neotex.plugins.tools.himalaya.core.state')

-- Files to remove from old version
M.deprecated_files = {
  'streamlined_sync.lua',
  'external_sync.lua',
  'mbsync.lua', -- Old version, different from new sync/mbsync.lua
  'test_oauth_refresh.lua',
  'oauth_diagnostics.lua', -- Moved to sync/oauth.lua
  'duplicate_investigation.lua',
  'FINDINGS.md',
  'FOLDER_MAPPING_ANALYSIS.md',
  'FINAL_FIX.md',
  'SYNC_HANDOFF.md',
  'sync_refactor_plan.md',
}

-- Configuration migrations
M.config_migrations = {
  -- Old config paths to new ones
  ['config.accounts.gmail.folder_aliases'] = 'accounts.gmail.folder_map',
  ['config.sync.auto_sync'] = 'sync.auto_sync_on_open',
  ['config.ui.progress_style'] = 'ui.show_simple_progress',
}

-- Fix UIDVALIDITY files
function M.fix_uidvalidity_files()
  local account = config.get_current_account()
  local maildir = vim.fn.expand(account.maildir_path)
  
  local fixed = 0
  
  -- Find all UIDVALIDITY files
  local cmd = string.format('find %s -name ".uidvalidity" 2>/dev/null', vim.fn.shellescape(maildir))
  local handle = io.popen(cmd)
  if handle then
    local files = handle:read('*a')
    handle:close()
    
    for file in files:gmatch('[^\n]+') do
      -- Read content
      local content_handle = io.open(file, 'r')
      if content_handle then
        local content = content_handle:read('*a')
        content_handle:close()
        
        -- Check if it needs fixing (single number less than 5 digits)
        if content:match('^%d+$') and #content < 5 then
          -- Empty the file
          local fix_handle = io.open(file, 'w')
          if fix_handle then
            fix_handle:write('')
            fix_handle:close()
            fixed = fixed + 1
          end
        end
      end
    end
  end
  
  return fixed
end

-- Migrate configuration
function M.migrate_config()
  local old_config_path = vim.fn.expand('~/.config/nvim/lua/neotex/plugins/tools/himalaya/config.lua')
  if vim.fn.filereadable(old_config_path) == 0 then
    return false -- No old config to migrate
  end
  
  -- Try to load old config
  local ok, old_config = pcall(require, 'neotex.plugins.tools.himalaya.config')
  if not ok then
    return false
  end
  
  local changes = {}
  
  -- Check for old configuration patterns
  if old_config.config and old_config.config.accounts then
    -- Migrate folder aliases to folder map
    for account_name, account in pairs(old_config.config.accounts) do
      if account.folder_aliases and not account.folder_map then
        changes.folder_map = true
      end
    end
  end
  
  if #vim.tbl_keys(changes) > 0 then
    logger.warn('Configuration changes detected. Please update your config:')
    if changes.folder_map then
      logger.info('  - Rename folder_aliases to folder_map')
    end
    return true
  end
  
  return false
end

-- Clear old state files
function M.clear_old_state()
  local state_files = {
    '/tmp/himalaya-sync.lock',
    '/tmp/himalaya-sync.state',
    '/tmp/mbsync-global.lock',
  }
  
  local cleared = 0
  for _, file in ipairs(state_files) do
    if vim.fn.filereadable(file) == 1 then
      os.remove(file)
      cleared = cleared + 1
    end
  end
  
  -- Clear old lock files
  local lock_pattern = '/tmp/himalaya-mbsync-*.lock'
  os.execute('rm -f ' .. lock_pattern .. ' 2>/dev/null')
  
  return cleared > 0
end

-- Backup old files
function M.backup_old_files()
  local himalaya_dir = vim.fn.expand('~/.config/nvim/lua/neotex/plugins/tools/himalaya')
  local backup_dir = himalaya_dir .. '/backup_' .. os.date('%Y%m%d_%H%M%S')
  
  -- Create backup directory
  vim.fn.mkdir(backup_dir, 'p')
  
  local backed_up = {}
  
  -- Backup deprecated files
  for _, file in ipairs(M.deprecated_files) do
    local source = himalaya_dir .. '/' .. file
    if vim.fn.filereadable(source) == 1 then
      local dest = backup_dir .. '/' .. file
      vim.fn.system({'cp', source, dest})
      table.insert(backed_up, file)
    end
  end
  
  if #backed_up > 0 then
    logger.info('Backed up ' .. #backed_up .. ' files to: ' .. backup_dir)
  end
  
  return backup_dir, backed_up
end

-- Main migration function
function M.migrate_from_old()
  logger.info(' Starting migration from old Himalaya plugin...')
  
  local changes = {}
  
  -- Step 1: Backup old files
  logger.info(' Backing up old files...')
  local backup_dir, backed_up = M.backup_old_files()
  if #backed_up > 0 then
    table.insert(changes, string.format('Backed up %d files to %s', #backed_up, backup_dir))
  end
  
  -- Step 2: Fix UIDVALIDITY files
  logger.info(' Fixing UIDVALIDITY files...')
  local fixed = M.fix_uidvalidity_files()
  if fixed > 0 then
    table.insert(changes, string.format('Fixed %d UIDVALIDITY files', fixed))
  end
  
  -- Step 3: Migrate configuration
  logger.info('  Checking configuration...')
  if M.migrate_config() then
    table.insert(changes, 'Configuration updates needed (see above)')
  end
  
  -- Step 4: Clear old state
  logger.info(' Clearing old state files...')
  if M.clear_old_state() then
    table.insert(changes, 'Cleared obsolete state files')
  end
  
  -- Step 5: Stop any running syncs
  logger.info(' Stopping old sync processes...')
  os.execute('pkill -f "mbsync" 2>/dev/null')
  
  -- Step 6: Run health check
  logger.info(' Running health check...')
  vim.defer_fn(function()
    local health = require('neotex.plugins.tools.himalaya.setup.health')
    health.show_report()
  end, 1000)
  
  -- Report results
  if #changes > 0 then
    logger.info('\n Migration complete:')
    for _, change in ipairs(changes) do
      logger.info('  - ' .. change)
    end
    
    logger.info('\n Next steps:')
    logger.info('1. Review the health check results above')
    logger.info('2. Update your configuration if needed')
    logger.info('3. Run :HimalayaSetup if any issues')
    logger.info('4. Delete backup directory when satisfied: ' .. backup_dir)
  else
    logger.info(' No migration needed - already up to date!')
  end
  
  -- Save migration completion
  state.set('migration.completed', true)
  state.set('migration.version', '2.0')
  state.set('migration.date', os.date('%Y-%m-%d %H:%M:%S'))
  state.set('migration.changes', changes)
end

-- Check if migration is needed
function M.needs_migration()
  -- Check for old files
  local himalaya_dir = vim.fn.expand('~/.config/nvim/lua/neotex/plugins/tools/himalaya')
  
  for _, file in ipairs(M.deprecated_files) do
    if vim.fn.filereadable(himalaya_dir .. '/' .. file) == 1 then
      return true
    end
  end
  
  -- Check state
  local version = state.get('migration.version')
  
  return not version or version ~= '2.0'
end

-- Clean up after successful migration
function M.cleanup_backup(backup_dir)
  if not backup_dir or vim.fn.isdirectory(backup_dir) == 0 then
    logger.info('No backup directory to clean up')
    return
  end
  
  vim.ui.input({
    prompt = string.format('Delete backup directory %s? (y/n): ', backup_dir)
  }, function(input)
    if input and input:lower() == 'y' then
      vim.fn.system({'rm', '-rf', backup_dir})
      logger.info('Backup directory deleted')
    end
  end)
end

return M