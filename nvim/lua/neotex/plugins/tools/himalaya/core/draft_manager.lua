-- Draft State Management Layer
-- Maintains consistency between local buffers, draft files, and himalaya maildir
--
-- This module solves the core problem of draft state synchronization by providing
-- a single source of truth for all draft-related operations.

local M = {}

-- Dependencies
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local notify = require('neotex.util.notifications')

-- Module state
M.drafts = {} -- Map of buffer_id -> draft_state

-- Draft state structure
local function create_draft_state(buffer_id, account, folder)
  return {
    buffer_id = buffer_id,
    draft_id = nil,              -- Himalaya ID (nil until synced)
    local_id = M.generate_local_id(), -- Temporary ID for tracking
    file_path = nil,             -- Local draft file path
    account = account,
    folder = folder,
    content = {
      from = '',
      to = '',
      cc = '',
      bcc = '',
      subject = '',
      body = '',
      headers = {}
    },
    state = 'new',               -- 'new'|'syncing'|'synced'|'sending'|'sent'
    last_saved = nil,
    last_synced = nil,
    created_at = os.time(),
    last_modified = nil,         -- NEW: when user last edited content
    is_empty = true,             -- NEW: track if draft is still empty
    user_touched = false,        -- NEW: track if user has made any edits
    error = nil                  -- Last error if any
  }
end

-- Generate temporary local ID
function M.generate_local_id()
  return string.format('draft_%s_%s', os.time(), math.random(1000, 9999))
end

-- Register a new draft
function M.register_draft(buffer_id, account, folder)
  if M.drafts[buffer_id] then
    logger.warn('Draft already registered for buffer', { buffer_id = buffer_id })
    return M.drafts[buffer_id]
  end
  
  local draft_state = create_draft_state(buffer_id, account, folder)
  M.drafts[buffer_id] = draft_state
  
  logger.info('Draft registered', {
    buffer_id = buffer_id,
    local_id = draft_state.local_id,
    account = account,
    folder = folder
  })
  
  return draft_state
end

-- Update draft content
function M.update_content(buffer_id, content)
  local draft_state = M.drafts[buffer_id]
  if not draft_state then
    logger.error('Draft not found for buffer', { buffer_id = buffer_id })
    return false
  end
  
  -- Merge content, preserving existing values
  draft_state.content = vim.tbl_extend('force', draft_state.content, content)
  draft_state.last_saved = os.time()
  
  logger.debug('Draft content updated', {
    buffer_id = buffer_id,
    local_id = draft_state.local_id,
    has_subject = (content.subject ~= nil and content.subject ~= ''),
    has_to = (content.to ~= nil and content.to ~= ''),
    body_length = content.body and #content.body or 0
  })
  
  return true
end

-- Update draft ID after sync with himalaya
function M.set_draft_id(buffer_id, draft_id)
  local draft_state = M.drafts[buffer_id]
  if not draft_state then
    logger.error('Draft not found for buffer', { buffer_id = buffer_id })
    return false
  end
  
  draft_state.draft_id = draft_id
  draft_state.state = 'synced'
  draft_state.last_synced = os.time()
  
  logger.info('Draft ID set', {
    buffer_id = buffer_id,
    local_id = draft_state.local_id,
    draft_id = draft_id
  })
  
  return true
end

-- Update draft state
function M.set_state(buffer_id, state)
  local draft_state = M.drafts[buffer_id]
  if not draft_state then
    logger.error('Draft not found for buffer', { buffer_id = buffer_id })
    return false
  end
  
  local old_state = draft_state.state
  draft_state.state = state
  
  logger.debug('Draft state changed', {
    buffer_id = buffer_id,
    local_id = draft_state.local_id,
    old_state = old_state,
    new_state = state
  })
  
  return true
end

-- Get draft by buffer ID
function M.get_draft(buffer_id)
  return M.drafts[buffer_id]
end

-- Get draft by himalaya ID
function M.get_draft_by_id(draft_id)
  for buffer_id, draft_state in pairs(M.drafts) do
    if draft_state.draft_id == draft_id then
      return draft_state
    end
  end
  return nil
end

-- Get draft by local ID
function M.get_draft_by_local_id(local_id)
  for buffer_id, draft_state in pairs(M.drafts) do
    if draft_state.local_id == local_id then
      return draft_state
    end
  end
  return nil
end

-- Find buffer for a draft ID
function M.find_buffer_for_draft(draft_id)
  for buffer_id, draft_state in pairs(M.drafts) do
    if draft_state.draft_id == draft_id then
      return buffer_id
    end
  end
  return nil
end

-- Remove draft
function M.remove_draft(buffer_id)
  local draft_state = M.drafts[buffer_id]
  if not draft_state then
    return false
  end
  
  logger.info('Draft removed', {
    buffer_id = buffer_id,
    local_id = draft_state.local_id,
    draft_id = draft_state.draft_id
  })
  
  M.drafts[buffer_id] = nil
  return true
end

-- Update draft state tracking (NEW for Phase 6)
function M.update_draft_state(buffer_id, updates)
  local draft_state = M.drafts[buffer_id]
  if not draft_state then
    return false
  end
  
  -- Apply updates
  for key, value in pairs(updates) do
    draft_state[key] = value
  end
  
  logger.debug('Draft state updated', {
    buffer_id = buffer_id,
    local_id = draft_state.local_id,
    updates = updates
  })
  
  return true
end

-- Check if draft is effectively empty (NEW for Phase 6)
function M.is_draft_empty(buffer_id)
  local draft_state = M.drafts[buffer_id]
  if not draft_state then
    return true
  end
  
  local content = draft_state.content
  return (
    (not content.to or content.to == '') and
    (not content.subject or content.subject == '') and
    (not content.body or content.body:match('^%s*$'))
  )
end

-- Clean up drafts for closed buffers
function M.cleanup_orphaned_drafts()
  local removed_count = 0
  
  for buffer_id, draft_state in pairs(M.drafts) do
    if not vim.api.nvim_buf_is_valid(buffer_id) then
      logger.debug('Removing orphaned draft', {
        buffer_id = buffer_id,
        local_id = draft_state.local_id
      })
      M.drafts[buffer_id] = nil
      removed_count = removed_count + 1
    end
  end
  
  if removed_count > 0 then
    logger.info('Cleaned up orphaned drafts', { count = removed_count })
  end
  
  return removed_count
end

-- Get all drafts for an account
function M.get_account_drafts(account)
  local drafts = {}
  
  for buffer_id, draft_state in pairs(M.drafts) do
    if draft_state.account == account then
      table.insert(drafts, draft_state)
    end
  end
  
  return drafts
end

-- Get draft statistics
function M.get_stats()
  local stats = {
    total = 0,
    new = 0,
    syncing = 0,
    synced = 0,
    sending = 0,
    sent = 0,
    with_errors = 0
  }
  
  for _, draft_state in pairs(M.drafts) do
    stats.total = stats.total + 1
    stats[draft_state.state] = (stats[draft_state.state] or 0) + 1
    if draft_state.error then
      stats.with_errors = stats.with_errors + 1
    end
  end
  
  return stats
end

-- Export draft state for persistence
function M.export_state(buffer_id)
  local draft_state = M.drafts[buffer_id]
  if not draft_state then
    return nil
  end
  
  -- Create a copy without the buffer_id reference
  return {
    draft_id = draft_state.draft_id,
    local_id = draft_state.local_id,
    file_path = draft_state.file_path,
    account = draft_state.account,
    folder = draft_state.folder,
    content = vim.deepcopy(draft_state.content),
    state = draft_state.state,
    last_saved = draft_state.last_saved,
    last_synced = draft_state.last_synced,
    created_at = draft_state.created_at
  }
end

-- Import draft state
function M.import_state(buffer_id, exported_state)
  if not exported_state then
    return false
  end
  
  local draft_state = vim.tbl_extend('force', 
    create_draft_state(buffer_id, exported_state.account, exported_state.folder),
    exported_state
  )
  draft_state.buffer_id = buffer_id
  
  M.drafts[buffer_id] = draft_state
  
  logger.info('Draft state imported', {
    buffer_id = buffer_id,
    local_id = draft_state.local_id,
    draft_id = draft_state.draft_id
  })
  
  return true
end

-- Debug: Print all draft states
function M.debug_print_states()
  print("=== Draft Manager State ===")
  print(string.format("Total drafts: %d", vim.tbl_count(M.drafts)))
  print("")
  
  for buffer_id, draft_state in pairs(M.drafts) do
    print(string.format("Buffer %d:", buffer_id))
    print(string.format("  Local ID: %s", draft_state.local_id))
    print(string.format("  Draft ID: %s", draft_state.draft_id or "nil"))
    print(string.format("  State: %s", draft_state.state))
    print(string.format("  Account: %s", draft_state.account))
    print(string.format("  Subject: %s", draft_state.content.subject or "(no subject)"))
    print(string.format("  To: %s", draft_state.content.to or "(no recipient)"))
    print(string.format("  Body length: %d", draft_state.content.body and #draft_state.content.body or 0))
    if draft_state.error then
      print(string.format("  Error: %s", draft_state.error))
    end
    print("")
  end
end

-- Register debug command
vim.api.nvim_create_user_command('DebugDraftManager', M.debug_print_states, {})

return M