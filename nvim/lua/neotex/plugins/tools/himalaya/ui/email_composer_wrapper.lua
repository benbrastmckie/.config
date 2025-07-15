-- Email Composer Wrapper
-- Redirects old email_composer calls to the new Maildir-based implementation
-- This allows gradual migration without breaking existing code

local M = {}

-- Import the Maildir-based composer
local maildir_composer = require('neotex.plugins.tools.himalaya.ui.email_composer_maildir')

-- Re-export all functions from the new composer
for k, v in pairs(maildir_composer) do
  M[k] = v
end

-- Compatibility shims for old API if needed

-- Old API: open_draft(email_id, account)
-- New API: open_draft(filepath)
-- This wrapper finds the filepath from email_id
function M.open_draft(email_id, account)
  local logger = require('neotex.plugins.tools.himalaya.core.logger')
  local notify = require('neotex.util.notifications')
  logger.debug('open_draft called', { email_id = email_id, account = account })
  
  -- First, check if we already have the filepath in the email list
  local state = require('neotex.plugins.tools.himalaya.core.state')
  local emails = state.get('email_list.emails')
  
  if emails then
    -- Look for the email with matching ID
    for _, email in ipairs(emails) do
      if email.id == email_id and email.draft_filepath then
        logger.info('Found draft filepath directly from email list', {
          email_id = email_id,
          filepath = email.draft_filepath
        })
        return maildir_composer.open_draft(email.draft_filepath)
      end
    end
  end
  
  -- Fallback: If email_id is actually a filename (for drafts), use it to find the file
  if type(email_id) == 'string' and email_id:match('%.') then
    -- This looks like a maildir filename
    local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_maildir')
    local drafts = draft_manager.list(account)
    
    for _, draft in ipairs(drafts) do
      if draft.filename == email_id then
        logger.info('Found draft by filename match', {
          email_id = email_id,
          filepath = draft.filepath
        })
        return maildir_composer.open_draft(draft.filepath)
      end
    end
  end
  
  -- If we couldn't find it, show an error
  logger.warn('Cannot find draft filepath', {
    email_id = email_id,
    account = account
  })
  
  notify.himalaya('Cannot open draft. Please refresh the email list and try again.', notify.categories.ERROR)
  return nil
end

-- Old API: open_local_draft(local_id, account)
-- This is just an alias for open_draft since all drafts are local now
M.open_local_draft = M.open_draft

-- Old API: save_draft(buffer, trigger)
-- New API: save_draft(buffer, trigger) - same signature
-- No change needed

-- Old API: sync_draft_to_remote(draft, content) 
-- New API: Not needed - mbsync handles it
M.sync_draft_to_remote = function(draft, content)
  -- No-op - mbsync handles remote sync automatically
  return true
end

-- Old API: update_ui_after_save(draft)
-- New API: Not needed - UI updates handled in save_draft
M.update_ui_after_save = function(draft)
  -- No-op for compatibility
end

-- Old API: parse_headers_for_display(lines)
-- New API: Not used, but provide for compatibility
M.parse_headers_for_display = function(lines)
  local headers = {}
  local in_body = false
  
  for _, line in ipairs(lines) do
    if in_body then
      break
    elseif line == '' then
      in_body = true
    else
      local header, value = line:match('^([^:]+):%s*(.*)$')
      if header then
        headers[header:lower()] = value
      end
    end
  end
  
  return headers
end

return M