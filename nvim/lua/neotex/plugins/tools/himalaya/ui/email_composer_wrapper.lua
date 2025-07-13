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
  
  -- Since drafts are now regular emails in Maildir, we need to find the actual file
  -- The best approach is to directly open the draft using the Maildir path
  
  -- Get the maildir path for drafts
  local config = require('neotex.plugins.tools.himalaya.core.config').config
  local maildir_root = config.sync.maildir_root or vim.fn.expand('~/Mail')
  local account_folder = account == 'gmail' and 'Gmail' or account
  local drafts_path = maildir_root .. '/' .. account_folder .. '/.Drafts'
  
  -- Read the draft content from himalaya to get unique identifiers
  local state = require('neotex.plugins.tools.himalaya.core.state')
  local folder = state.get_current_folder()
  
  -- Get email from cache first
  local email_cache = require('neotex.plugins.tools.himalaya.core.email_cache')
  local cached_email = email_cache.get_email(account, folder, email_id)
  
  if not cached_email then
    notify.himalaya('Draft not in cache, please refresh the email list', notify.categories.ERROR)
    return nil
  end
  
  local subject = cached_email.subject or ''
  local from = cached_email.from or ''
  local date = cached_email.date
  
  logger.debug('Looking for draft', { 
    email_id = email_id,
    subject = subject,
    from = from,
    date = date
  })
  
  -- List all draft files in Maildir
  local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2_maildir')
  local drafts = draft_manager.list_drafts(account)
  
  -- Try to match by subject first (most reliable)
  if subject and subject ~= '' then
    for _, draft in ipairs(drafts) do
      if draft.subject == subject then
        logger.info('Found draft by subject match', { 
          email_id = email_id, 
          filepath = draft.filepath,
          subject = subject
        })
        return maildir_composer.open_draft(draft.filepath)
      end
    end
  end
  
  -- Try fuzzy subject match (in case of encoding differences)
  if subject and subject ~= '' and subject ~= '(No subject)' then
    local subject_lower = subject:lower():gsub('^%s+', ''):gsub('%s+$', '') -- trim whitespace
    for _, draft in ipairs(drafts) do
      if draft.subject then
        local draft_subject_lower = draft.subject:lower():gsub('^%s+', ''):gsub('%s+$', '')
        if draft_subject_lower:find(subject_lower, 1, true) then
          logger.info('Found draft by fuzzy subject match', { 
            email_id = email_id, 
            filepath = draft.filepath,
            subject = subject,
            draft_subject = draft.subject
          })
          return maildir_composer.open_draft(draft.filepath)
        end
      end
    end
  end
  
  -- If we have exactly one draft and no subject, open it
  if #drafts == 1 and (not subject or subject == '' or subject == '(No subject)') then
    logger.info('Only one draft without subject, opening it', { 
      email_id = email_id, 
      filepath = drafts[1].filepath 
    })
    return maildir_composer.open_draft(drafts[1].filepath)
  end
  
  -- Not found - provide helpful error messages
  logger.warn('Cannot match draft to file', {
    email_id = email_id,
    subject = subject,
    drafts_found = #drafts,
    draft_subjects = vim.tbl_map(function(d) return d.subject or 'none' end, drafts)
  })
  
  notify.himalaya('Cannot match draft to file.', notify.categories.ERROR)
  
  if #drafts == 0 then
    notify.himalaya('No draft files found. Try refreshing the email list.', notify.categories.ERROR)
  else
    notify.himalaya(string.format('Found %d drafts but none match subject "%s"', #drafts, subject or 'none'), notify.categories.ERROR)
    -- Show available subjects for debugging
    local subjects = {}
    for _, draft in ipairs(drafts) do
      table.insert(subjects, draft.subject or '(no subject)')
    end
    logger.debug('Available draft subjects', { subjects = subjects })
  end
  
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