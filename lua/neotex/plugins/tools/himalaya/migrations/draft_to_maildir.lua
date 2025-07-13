-- Draft to Maildir Migration Script
-- Migrates existing JSON/EML drafts to Maildir format

local M = {}

-- Dependencies
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local notify = require('neotex.util.notifications')
local maildir = require('neotex.plugins.tools.himalaya.core.maildir')
-- local_storage removed - migration reads directly from filesystem

-- Migration state
M.state = {
  backup_dir = nil,
  migrated_count = 0,
  failed_count = 0,
  errors = {}
}

-- Create backup directory
local function create_backup_dir()
  local backup_path = vim.fn.stdpath('data') .. '/himalaya/drafts_backup_' .. os.date('%Y%m%d_%H%M%S')
  vim.fn.mkdir(backup_path, 'p')
  return backup_path
end

-- Backup a file
local function backup_file(filepath, backup_dir)
  local filename = vim.fn.fnamemodify(filepath, ':t')
  local backup_path = backup_dir .. '/' .. filename
  
  local ok = vim.fn.writefile(vim.fn.readfile(filepath, 'b'), backup_path, 'b')
  return ok == 0
end

-- Convert EML content to Maildir format with draft flag
local function convert_to_maildir(draft_data, eml_content)
  -- Add X-Himalaya headers to preserve metadata
  local headers = {}
  local body_start = 1
  
  -- Parse existing headers from EML content
  local lines = vim.split(eml_content, '\n', { plain = true })
  for i, line in ipairs(lines) do
    if line == '' then
      body_start = i + 1
      break
    end
    table.insert(headers, line)
  end
  
  -- Add our metadata headers
  table.insert(headers, string.format('X-Himalaya-Account: %s', draft_data.account or 'default'))
  if draft_data.remote_id then
    table.insert(headers, string.format('X-Himalaya-Remote-ID: %s', draft_data.remote_id))
  end
  table.insert(headers, string.format('X-Himalaya-Created: %d', draft_data.created_at or os.time()))
  table.insert(headers, string.format('X-Himalaya-Modified: %d', draft_data.updated_at or os.time()))
  
  -- Reconstruct content
  local new_content = table.concat(headers, '\n') .. '\n'
  if body_start <= #lines then
    local body_lines = {}
    for i = body_start, #lines do
      table.insert(body_lines, lines[i])
    end
    new_content = new_content .. '\n' .. table.concat(body_lines, '\n')
  end
  
  return new_content
end

-- Get the Maildir path for an account
local function get_maildir_path(account)
  local config = require('neotex.plugins.tools.himalaya.core.config').get()
  
  -- Use configured maildir path or default
  local base_path = config.sync.maildir_root or (vim.fn.expand('~') .. '/Mail')
  
  -- Map account to maildir folder
  -- This assumes the standard structure: ~/Mail/AccountName/.Drafts
  local account_name = account
  if account == 'default' or not account then
    -- Try to get default account from config
    if config.accounts and #config.accounts > 0 then
      account_name = config.accounts[1].name
    else
      account_name = 'Gmail' -- Fallback
    end
  end
  
  return base_path .. '/' .. account_name .. '/.Drafts'
end

-- Migrate a single draft
local function migrate_draft(draft_data, backup_dir)
  local draft_id = draft_data.local_id
  
  logger.info('Migrating draft', { id = draft_id, subject = draft_data.metadata.subject })
  
  -- Read EML file
  local eml_path = vim.fn.stdpath('data') .. '/himalaya/drafts/' .. draft_id .. '.eml'
  if vim.fn.filereadable(eml_path) ~= 1 then
    logger.error('EML file not found', { path = eml_path })
    return false, 'EML file not found'
  end
  
  -- Backup files
  local json_path = vim.fn.stdpath('data') .. '/himalaya/drafts/' .. draft_id .. '.json'
  backup_file(eml_path, backup_dir)
  if vim.fn.filereadable(json_path) == 1 then
    backup_file(json_path, backup_dir)
  end
  
  -- Read EML content
  local eml_content = table.concat(vim.fn.readfile(eml_path, 'b'), '\n')
  
  -- Convert to Maildir format
  local maildir_content = convert_to_maildir(draft_data, eml_content)
  
  -- Get target Maildir path
  local maildir_path = get_maildir_path(draft_data.account)
  
  -- Ensure Maildir exists
  if not maildir.is_maildir(maildir_path) then
    local ok, err = maildir.create_maildir(maildir_path)
    if not ok then
      return false, 'Failed to create Maildir: ' .. err
    end
  end
  
  -- Generate Maildir filename with Draft flag
  local filename = maildir.generate_filename({'D'})
  local target_path = maildir_path .. '/cur/' .. filename
  
  -- Write to Maildir
  local tmp_path = maildir_path .. '/tmp'
  local ok, err = maildir.atomic_write(tmp_path, target_path, maildir_content)
  if not ok then
    return false, 'Failed to write Maildir: ' .. err
  end
  
  -- Update size in filename
  maildir.update_size(target_path)
  
  -- Delete original files after successful migration
  vim.fn.delete(eml_path)
  if vim.fn.filereadable(json_path) == 1 then
    vim.fn.delete(json_path)
  end
  
  logger.info('Successfully migrated draft', {
    id = draft_id,
    target = target_path
  })
  
  return true
end

-- Read drafts directly from filesystem
local function read_legacy_drafts()
  local drafts_dir = vim.fn.stdpath('data') .. '/himalaya/drafts'
  local drafts = {}
  
  -- Check if directory exists
  if vim.fn.isdirectory(drafts_dir) ~= 1 then
    return drafts
  end
  
  -- Read .index.json if it exists
  local index_file = drafts_dir .. '/.index.json'
  if vim.fn.filereadable(index_file) == 1 then
    local content = table.concat(vim.fn.readfile(index_file), '\n')
    local ok, index_data = pcall(vim.json.decode, content)
    if ok and index_data then
      drafts = index_data
    end
  else
    -- Scan for .eml files
    local files = vim.fn.glob(drafts_dir .. '/*.eml', false, true)
    for _, file in ipairs(files) do
      local filename = vim.fn.fnamemodify(file, ':t:r')
      table.insert(drafts, {
        local_id = filename,
        account = 'default',
        metadata = { subject = 'Unknown' }
      })
    end
  end
  
  return drafts
end

-- Main migration function
function M.migrate(opts)
  opts = opts or {}
  local dry_run = opts.dry_run or false
  
  -- Get all drafts from filesystem
  local drafts = read_legacy_drafts()
  if #drafts == 0 then
    notify.himalaya('No drafts to migrate', notify.categories.USER_ACTION)
    return {
      total = 0,
      migrated = 0,
      failed = 0,
      dry_run = dry_run
    }
  end
  
  notify.himalaya(
    string.format('Found %d draft(s) to migrate', #drafts),
    notify.categories.STATUS
  )
  
  if dry_run then
    -- Just report what would be migrated
    for _, draft in ipairs(drafts) do
      local account = draft.account or 'default'
      local maildir_path = get_maildir_path(account)
      print(string.format(
        'Would migrate: %s -> %s/.Drafts/',
        draft.metadata.subject or 'Untitled',
        maildir_path
      ))
    end
    
    return {
      total = #drafts,
      migrated = #drafts,
      failed = 0,
      dry_run = true
    }
  end
  
  -- Create backup directory
  M.state.backup_dir = create_backup_dir()
  notify.himalaya(
    'Creating backup at: ' .. M.state.backup_dir,
    notify.categories.STATUS
  )
  
  -- Migrate each draft
  local progress_shown = false
  for i, draft in ipairs(drafts) do
    -- Show progress for large migrations
    if #drafts > 5 and not progress_shown then
      notify.himalaya(
        string.format('Migrating %d/%d drafts...', i, #drafts),
        notify.categories.STATUS
      )
      progress_shown = true
    end
    
    local ok, err = migrate_draft(draft, M.state.backup_dir)
    if ok then
      M.state.migrated_count = M.state.migrated_count + 1
    else
      M.state.failed_count = M.state.failed_count + 1
      table.insert(M.state.errors, {
        draft = draft,
        error = err
      })
      logger.error('Failed to migrate draft', {
        id = draft.local_id,
        error = err
      })
    end
  end
  
  -- Clean up index file if all successful
  if M.state.failed_count == 0 then
    local index_path = vim.fn.stdpath('data') .. '/himalaya/drafts/.index.json'
    if vim.fn.filereadable(index_path) == 1 then
      backup_file(index_path, M.state.backup_dir)
      vim.fn.delete(index_path)
    end
  end
  
  -- Report results
  local msg = string.format(
    'Migration complete: %d/%d drafts migrated successfully',
    M.state.migrated_count,
    #drafts
  )
  
  if M.state.failed_count > 0 then
    msg = msg .. string.format(' (%d failed)', M.state.failed_count)
    notify.himalaya(msg, notify.categories.ERROR)
  else
    msg = msg .. '. Backup saved at: ' .. M.state.backup_dir
    notify.himalaya(msg, notify.categories.USER_ACTION)
  end
  
  return {
    total = #drafts,
    migrated = M.state.migrated_count,
    failed = M.state.failed_count,
    backup_dir = M.state.backup_dir,
    errors = M.state.errors,
    dry_run = false
  }
end

-- Rollback migration using backup
function M.rollback(backup_dir)
  backup_dir = backup_dir or M.state.backup_dir
  
  if not backup_dir or vim.fn.isdirectory(backup_dir) ~= 1 then
    notify.himalaya(
      'No backup directory found for rollback',
      notify.categories.ERROR
    )
    return false
  end
  
  local drafts_dir = vim.fn.stdpath('data') .. '/himalaya/drafts'
  vim.fn.mkdir(drafts_dir, 'p')
  
  -- Copy all files from backup
  local files = vim.fn.readdir(backup_dir)
  local restored_count = 0
  
  for _, filename in ipairs(files) do
    local src = backup_dir .. '/' .. filename
    local dst = drafts_dir .. '/' .. filename
    
    local ok = vim.fn.writefile(vim.fn.readfile(src, 'b'), dst, 'b')
    if ok == 0 then
      restored_count = restored_count + 1
    end
  end
  
  notify.himalaya(
    string.format('Rollback complete: %d files restored', restored_count),
    notify.categories.USER_ACTION
  )
  
  return true
end

-- Verify migration success
function M.verify()
  local drafts_dir = vim.fn.stdpath('data') .. '/himalaya/drafts'
  local old_files = vim.fn.glob(drafts_dir .. '/*.{json,eml}', false, true)
  
  if #old_files > 0 then
    notify.himalaya(
      string.format('Found %d old draft files remaining', #old_files),
      notify.categories.WARNING
    )
    return false
  end
  
  -- Check Maildir for drafts
  local config = require('neotex.plugins.tools.himalaya.core.config').get()
  local draft_count = 0
  
  if config.accounts then
    for _, account in ipairs(config.accounts) do
      local maildir_path = get_maildir_path(account.name)
      if maildir.is_maildir(maildir_path) then
        local messages = maildir.list_messages(maildir_path, {D = true})
        draft_count = draft_count + #messages
      end
    end
  end
  
  notify.himalaya(
    string.format('Verification complete: %d drafts in Maildir format', draft_count),
    notify.categories.USER_ACTION
  )
  
  return true
end

return M