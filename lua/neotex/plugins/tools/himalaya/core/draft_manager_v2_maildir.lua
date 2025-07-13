-- Draft Manager v2 Maildir Wrapper
-- Redirects existing draft_manager_v2 API to the new Maildir-based implementation

local M = {}

-- Import the Maildir-based manager
local maildir_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_maildir')

-- Re-export states for compatibility
M.states = maildir_manager.states

-- Re-export drafts table (now buffer->filepath mapping)
M.drafts = maildir_manager.buffer_drafts

-- Setup function
function M.setup(config)
  maildir_manager.setup()
end

-- Create a new draft (compatibility wrapper)
-- @param account string Account name
-- @param initial_content string|nil Initial content (ignored, use metadata.body)
-- @param metadata table|nil Metadata with from, to, subject, body
-- @return table|nil Draft object or nil on error
-- @return string|nil error Error message if failed
function M.create_draft(account, initial_content, metadata)
  -- Handle old API where content was passed separately
  if initial_content and not metadata then
    metadata = { body = initial_content }
  elseif initial_content and metadata and not metadata.body then
    metadata.body = initial_content
  end
  
  local buffer, err = maildir_manager.create(account, metadata)
  if not buffer then
    return nil, err
  end
  
  -- Return draft object for compatibility
  local draft = maildir_manager.get_by_buffer(buffer)
  if draft then
    -- Add compatibility fields
    draft.local_id = draft.filename
    draft.metadata = {
      subject = draft.subject,
      from = draft.from,
      to = draft.to,
      cc = draft.cc,
      bcc = draft.bcc
    }
    draft.created_at = draft.timestamp
    draft.modified_at = draft.timestamp
    draft.modified = false
    draft.synced = true  -- Always true with mbsync
  end
  
  return draft, nil
end

-- Register a draft with a buffer (compatibility)
-- In Maildir version, this happens automatically
function M.register_draft(buffer, draft)
  -- No-op for compatibility
  return true
end

-- Save draft locally (compatibility wrapper)
function M.save_local(buffer)
  local ok, err = maildir_manager.save(buffer)
  return ok, err
end

-- Save draft (main save function)
function M.save(buffer)
  return maildir_manager.save(buffer)
end

-- Sync draft to remote (compatibility - mbsync handles this)
function M.sync_remote(buffer)
  -- With Maildir, mbsync handles syncing automatically
  -- Just ensure the draft is saved
  return maildir_manager.save(buffer)
end

-- Handle sync completion (compatibility - not needed with mbsync)
function M.handle_sync_completion(local_id, remote_id, success, error)
  -- No-op - mbsync handles all syncing
end

-- Delete a draft
function M.delete(buffer)
  return maildir_manager.delete(buffer)
end

-- Send a draft
function M.send(buffer)
  return maildir_manager.send(buffer)
end

-- Get draft by buffer
function M.get_by_buffer(buffer)
  local draft = maildir_manager.get_by_buffer(buffer)
  if not draft then
    return nil
  end
  
  -- Add compatibility fields
  draft.local_id = draft.filename
  draft.metadata = {
    subject = draft.subject,
    from = draft.from,
    to = draft.to,
    cc = draft.cc,
    bcc = draft.bcc
  }
  draft.created_at = draft.timestamp
  draft.modified_at = draft.timestamp
  draft.modified = vim.api.nvim_buf_get_option(draft.buffer, 'modified')
  draft.synced = not draft.modified
  
  return draft
end

-- Get all drafts
function M.get_all()
  local drafts = maildir_manager.get_all()
  
  -- Add compatibility fields
  for _, draft in ipairs(drafts) do
    draft.local_id = draft.filename
    draft.metadata = {
      subject = draft.subject,
      from = draft.from,
      to = draft.to,
      cc = draft.cc,
      bcc = draft.bcc
    }
    draft.created_at = draft.timestamp
    draft.modified_at = draft.timestamp
    draft.modified = vim.api.nvim_buf_get_option(draft.buffer, 'modified')
    draft.synced = not draft.modified
  end
  
  return drafts
end

-- Check if buffer has a draft
function M.is_draft(buffer)
  return maildir_manager.is_draft(buffer)
end

-- Cleanup draft
function M.cleanup_draft(buffer)
  maildir_manager.cleanup_draft(buffer)
end

-- Recover session
function M.recover_session()
  maildir_manager.recover_session()
end

-- List drafts (new API)
function M.list_drafts(account)
  return maildir_manager.list(account)
end

-- Load draft by ID (compatibility)
function M.load(draft_id, account)
  -- Try to find draft by ID
  local drafts = M.list_drafts(account)
  for _, draft in ipairs(drafts) do
    if draft.filename == draft_id or tostring(draft.timestamp) == draft_id then
      -- Read file content
      local file = io.open(draft.filepath, 'r')
      if file then
        local content = file:read('*a')
        file:close()
        return {
          content = content,
          metadata = {
            subject = draft.subject,
            from = draft.from,
            to = draft.to,
            cc = draft.cc,
            bcc = draft.bcc
          }
        }
      end
    end
  end
  return nil, "Draft not found"
end

-- Compatibility functions that are no longer needed
function M.update_remote_id(buffer, remote_id)
  -- No-op - Maildir doesn't track remote IDs
end

function M.mark_synced(buffer)
  -- No-op - mbsync handles sync status
end

function M.mark_modified(buffer)
  -- No-op - Vim tracks modification status
end

function M.get_draft_count()
  return #M.get_all()
end

function M.cleanup_orphaned_drafts()
  -- No-op - Maildir doesn't have orphaned drafts
end

return M