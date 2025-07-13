-- Draft Migration Module
-- Migrates existing EML drafts to JSON format for local storage

local M = {}

-- Dependencies
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local notify = require('neotex.util.notifications')

-- Migrate EML drafts to JSON format
function M.migrate_eml_to_json()
  local local_storage = require('neotex.plugins.tools.himalaya.core.local_storage')
  local draft_dir = vim.fn.stdpath('data') .. '/himalaya/drafts/'
  
  -- Ensure local storage is initialized
  local_storage.setup()
  
  -- Get all EML files
  local eml_files = vim.fn.glob(draft_dir .. '*.eml', false, true)
  local migrated_count = 0
  
  logger.info('Starting draft migration', {
    eml_count = #eml_files,
    draft_dir = draft_dir
  })
  
  for _, eml_file in ipairs(eml_files) do
    local filename = vim.fn.fnamemodify(eml_file, ':t:r')
    
    -- Skip if already migrated (exists in index)
    if local_storage.index[filename] then
      logger.debug('Draft already migrated, skipping', { filename = filename })
    else
      -- Read EML content
      local ok, lines = pcall(vim.fn.readfile, eml_file)
      if ok and lines then
        local content = table.concat(lines, '\n')
        
        -- Parse headers
        local headers = {}
        local body_start = 1
        for i, line in ipairs(lines) do
          if line == '' then
            body_start = i + 1
            break
          end
          local key, value = line:match('^([^:]+):%s*(.*)$')
          if key then
            headers[key:lower()] = value
          end
        end
        
        -- Extract account from filename or use current account
        local config = require('neotex.plugins.tools.himalaya.core.config')
        local account = config.get_current_account_name() or 'default'
        
        -- Try to match account from headers if available
        if headers.from then
          local accounts = config.get('accounts', {})
          for acc_name, acc_config in pairs(accounts) do
            if acc_config.email and headers.from:match(acc_config.email) then
              account = acc_name
              break
            end
          end
        end
        
        -- Create storage entry
        local draft_data = {
          content = content,
          account = account,
          remote_id = nil,
          metadata = {
            from = headers.from or '',
            to = headers.to or '',
            subject = headers.subject or '',
            cc = headers.cc or '',
            bcc = headers.bcc or ''
          },
          created_at = vim.fn.getftime(eml_file),
          updated_at = vim.fn.getftime(eml_file)
        }
        
        -- Save to local storage
        local save_ok = local_storage.save(filename, draft_data)
        if save_ok then
          migrated_count = migrated_count + 1
          logger.info('Migrated draft', {
            filename = filename,
            subject = draft_data.metadata.subject
          })
        else
          logger.error('Failed to migrate draft', { filename = filename })
        end
      end
    end
  end
  
  logger.info('Draft migration complete', {
    total_eml = #eml_files,
    migrated = migrated_count,
    already_migrated = #eml_files - migrated_count
  })
  
  notify.himalaya(
    string.format('Migrated %d/%d drafts to JSON format', migrated_count, #eml_files),
    notify.categories.USER_ACTION
  )
  
  return migrated_count
end

-- Check if migration is needed
function M.needs_migration()
  local draft_dir = vim.fn.stdpath('data') .. '/himalaya/drafts/'
  local eml_files = vim.fn.glob(draft_dir .. '*.eml', false, true)
  
  if #eml_files == 0 then
    return false
  end
  
  -- Check if any EML files don't have corresponding JSON files
  local local_storage = require('neotex.plugins.tools.himalaya.core.local_storage')
  local_storage.setup()
  
  for _, eml_file in ipairs(eml_files) do
    local filename = vim.fn.fnamemodify(eml_file, ':t:r')
    local json_file = draft_dir .. filename .. '.json'
    -- Only migrate if JSON file doesn't exist
    if vim.fn.filereadable(json_file) == 0 then
      return true
    end
  end
  
  return false
end

return M