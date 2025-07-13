-- Draft Cleanup Module
-- Provides utilities to clean up old test drafts

local M = {}

-- Dependencies
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local notify = require('neotex.util.notifications')

-- Clean up all local drafts (with confirmation)
function M.cleanup_all_drafts()
  local local_storage = require('neotex.plugins.tools.himalaya.core.local_storage')
  local_storage.setup()
  
  local drafts = local_storage.list()
  local draft_count = #drafts
  
  if draft_count == 0 then
    notify.himalaya('No drafts to clean up', notify.categories.STATUS)
    return 0
  end
  
  -- Delete all drafts
  local deleted_count = 0
  for _, draft in ipairs(drafts) do
    if local_storage.delete(draft.local_id) then
      deleted_count = deleted_count + 1
      -- Also delete the EML file if it exists
      local eml_file = vim.fn.stdpath('data') .. '/himalaya/drafts/' .. draft.local_id .. '.eml'
      if vim.fn.filereadable(eml_file) == 1 then
        vim.fn.delete(eml_file)
      end
    end
  end
  
  logger.info('Cleaned up drafts', {
    total = draft_count,
    deleted = deleted_count
  })
  
  notify.himalaya(
    string.format('Deleted %d/%d drafts', deleted_count, draft_count),
    notify.categories.USER_ACTION
  )
  
  return deleted_count
end

-- Clean up old test drafts (older than N days)
function M.cleanup_old_drafts(days)
  days = days or 7
  local cutoff_time = os.time() - (days * 24 * 60 * 60)
  
  local local_storage = require('neotex.plugins.tools.himalaya.core.local_storage')
  local_storage.setup()
  
  local drafts = local_storage.list()
  local old_drafts = {}
  
  for _, draft in ipairs(drafts) do
    if draft.modified and draft.modified < cutoff_time then
      table.insert(old_drafts, draft)
    end
  end
  
  if #old_drafts == 0 then
    notify.himalaya(string.format('No drafts older than %d days', days), notify.categories.STATUS)
    return 0
  end
  
  -- Delete old drafts
  local deleted_count = 0
  for _, draft in ipairs(old_drafts) do
    if local_storage.delete(draft.local_id) then
      deleted_count = deleted_count + 1
      -- Also delete the EML file if it exists
      local eml_file = vim.fn.stdpath('data') .. '/himalaya/drafts/' .. draft.local_id .. '.eml'
      if vim.fn.filereadable(eml_file) == 1 then
        vim.fn.delete(eml_file)
      end
    end
  end
  
  logger.info('Cleaned up old drafts', {
    total = #old_drafts,
    deleted = deleted_count,
    days = days
  })
  
  notify.himalaya(
    string.format('Deleted %d drafts older than %d days', deleted_count, days),
    notify.categories.USER_ACTION
  )
  
  return deleted_count
end

-- Clean up empty drafts (no subject and no body)
function M.cleanup_empty_drafts()
  local local_storage = require('neotex.plugins.tools.himalaya.core.local_storage')
  local_storage.setup()
  
  local drafts = local_storage.list()
  local empty_drafts = {}
  
  for _, draft in ipairs(drafts) do
    -- Check if draft is empty
    if (not draft.subject or draft.subject == '') then
      -- Load full draft to check body
      local full_draft = local_storage.load(draft.local_id)
      if full_draft and full_draft.content then
        -- Parse content to check if body is empty
        local has_body = false
        local in_body = false
        for line in full_draft.content:gmatch('[^\n]+') do
          if in_body and line:match('%S') then
            has_body = true
            break
          elseif line == '' then
            in_body = true
          end
        end
        
        if not has_body then
          table.insert(empty_drafts, draft)
        end
      end
    end
  end
  
  if #empty_drafts == 0 then
    notify.himalaya('No empty drafts to clean up', notify.categories.STATUS)
    return 0
  end
  
  -- Delete empty drafts
  local deleted_count = 0
  for _, draft in ipairs(empty_drafts) do
    if local_storage.delete(draft.local_id) then
      deleted_count = deleted_count + 1
      -- Also delete the EML file if it exists
      local eml_file = vim.fn.stdpath('data') .. '/himalaya/drafts/' .. draft.local_id .. '.eml'
      if vim.fn.filereadable(eml_file) == 1 then
        vim.fn.delete(eml_file)
      end
    end
  end
  
  logger.info('Cleaned up empty drafts', {
    total = #empty_drafts,
    deleted = deleted_count
  })
  
  notify.himalaya(
    string.format('Deleted %d empty drafts', deleted_count),
    notify.categories.USER_ACTION
  )
  
  return deleted_count
end

return M