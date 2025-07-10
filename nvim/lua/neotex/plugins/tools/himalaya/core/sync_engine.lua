-- Sync Engine for Draft Management
-- Handles remote synchronization with retry logic and error recovery

local M = {}

-- Dependencies
local draft_notifications = require('neotex.plugins.tools.himalaya.core.draft_notifications')
local utils = require('neotex.plugins.tools.himalaya.utils')
local notify = require('neotex.util.notifications')
local events_bus = require('neotex.plugins.tools.himalaya.orchestration.events')
local event_types = require('neotex.plugins.tools.himalaya.core.events')

-- Sync queue for pending operations
M.sync_queue = {}
M.sync_timer = nil
M.retry_counts = {}

-- Configuration
M.config = {
  sync_interval = 5000, -- 5 seconds
  max_retries = 3,
  retry_delay = 2000,   -- 2 seconds
  backoff_multiplier = 2
}

-- Sync states
M.sync_states = {
  PENDING = 'pending',
  IN_PROGRESS = 'in_progress',
  COMPLETED = 'completed',
  FAILED = 'failed'
}

-- Initialize sync engine
function M.setup(config)
  if config then
    M.config = vim.tbl_extend('force', M.config, config)
  end
  
  -- Start sync processing
  M.start_processing()
end

-- Add draft to sync queue
function M.queue_sync(draft_info)
  local key = draft_info.local_id
  
  -- Check if already in queue
  if M.sync_queue[key] then
    -- Update with latest info
    M.sync_queue[key].draft_info = draft_info
    M.sync_queue[key].updated_at = os.time()
  else
    -- Add new entry
    M.sync_queue[key] = {
      draft_info = draft_info,
      state = M.sync_states.PENDING,
      added_at = os.time(),
      updated_at = os.time(),
      attempts = 0
    }
  end
  
  -- Debug notification
  draft_notifications.debug_sync('queued', draft_info.local_id, {
    queue_size = vim.tbl_count(M.sync_queue)
  })
end

-- Process sync queue
function M.process_queue()
  for key, item in pairs(M.sync_queue) do
    if item.state == M.sync_states.PENDING then
      M.sync_item(key, item)
    end
  end
end

-- Sync individual item
function M.sync_item(key, item)
  -- Mark as in progress
  item.state = M.sync_states.IN_PROGRESS
  item.attempts = item.attempts + 1
  
  local draft_info = item.draft_info
  
  -- Emit sync started event (only on first attempt)
  if item.attempts == 1 then
    events_bus.emit(event_types.DRAFT_SYNC_STARTED, {
      draft_id = draft_info.local_id,
      account = draft_info.account
    })
  end
  
  -- Emit sync progress event
  events_bus.emit(event_types.DRAFT_SYNC_PROGRESS, {
    draft_id = draft_info.local_id,
    attempt = item.attempts,
    max_retries = M.config.max_retries
  })
  
  -- Debug notification
  draft_notifications.debug_sync('processing', draft_info.local_id, {
    attempt = item.attempts,
    has_remote_id = draft_info.remote_id ~= nil
  })
  
  -- Prepare email data
  local email = {
    subject = draft_info.metadata.subject,
    to = draft_info.metadata.to,
    from = draft_info.metadata.from,
    cc = draft_info.metadata.cc,
    bcc = draft_info.metadata.bcc,
    body = draft_info.content or ''
  }
  
  -- Try to sync
  local ok, result = pcall(function()
    if draft_info.remote_id then
      -- Update existing draft
      return M.update_remote_draft(draft_info.account, draft_info.remote_id, email)
    else
      -- Create new draft
      return M.create_remote_draft(draft_info.account, email)
    end
  end)
  
  if ok and result then
    -- Success
    item.state = M.sync_states.COMPLETED
    M.sync_queue[key] = nil -- Remove from queue
    M.retry_counts[key] = nil
    
    -- Notify success
    draft_notifications.debug_sync('completed', draft_info.local_id, {
      remote_id = result.id,
      attempts = item.attempts
    })
    
    -- Emit sync completed event
    events_bus.emit(event_types.DRAFT_SYNC_COMPLETED, {
      draft_id = draft_info.local_id,
      duration = os.time() - (item.added_at or os.time()),
      queue_remaining = vim.tbl_count(M.sync_queue) - 1
    })
    
    -- Call draft manager completion handler
    local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
    draft_manager.handle_sync_completion(draft_info.local_id, result.id, true, nil)
    
    -- Return the remote ID for the draft manager
    return result.id
  else
    -- Failed
    local error_msg = tostring(result)
    
    -- Check if we should retry
    if item.attempts < M.config.max_retries then
      -- Schedule retry
      item.state = M.sync_states.PENDING
      local delay = M.config.retry_delay * math.pow(M.config.backoff_multiplier, item.attempts - 1)
      
      vim.defer_fn(function()
        if M.sync_queue[key] and M.sync_queue[key].state == M.sync_states.PENDING then
          M.sync_item(key, M.sync_queue[key])
        end
      end, delay)
      
      draft_notifications.debug_sync('retry_scheduled', draft_info.local_id, {
        attempt = item.attempts,
        delay = delay,
        error = error_msg
      })
    else
      -- Max retries reached
      item.state = M.sync_states.FAILED
      M.sync_queue[key] = nil
      
      draft_notifications.draft_sync_failed(draft_info.local_id, error_msg)
      
      -- Call draft manager completion handler
      local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
      draft_manager.handle_sync_completion(draft_info.local_id, nil, false, error_msg)
    end
  end
end

-- Create new remote draft
function M.create_remote_draft(account, email)
  local result = utils.save_draft(account, 'Drafts', email)
  if result and result.id then
    return { id = tostring(result.id) }
  else
    error("Failed to create draft")
  end
end

-- Update existing remote draft
function M.update_remote_draft(account, draft_id, email)
  -- Himalaya doesn't have a direct update command, so we:
  -- 1. Delete the old draft
  -- 2. Create a new one
  
  -- Delete old draft
  local delete_ok = pcall(utils.execute_himalaya,
    { 'message', 'delete', tostring(draft_id) },
    { account = account, folder = 'Drafts' }
  )
  
  if not delete_ok then
    -- Log but continue - the draft might already be deleted
    draft_notifications.debug_sync('delete_failed', draft_id, {
      error = "Could not delete old draft"
    })
  end
  
  -- Create new draft
  return M.create_remote_draft(account, email)
end

-- Handle himalaya draft body bug
function M.handle_himalaya_bug(draft_info)
  -- When himalaya returns empty body for drafts, try fallbacks:
  
  -- 1. Check local storage
  local storage = require('neotex.plugins.tools.himalaya.core.local_storage')
  local cached = storage.find_by_remote_id(draft_info.remote_id, draft_info.account)
  if cached and cached.content then
    draft_notifications.draft_himalaya_bug_detected(draft_info.remote_id)
    return cached.content
  end
  
  -- 2. Try to read from maildir (if available)
  -- This would require maildir access which might not be available
  
  return nil
end

-- Start sync processing timer
function M.start_processing()
  if M.sync_timer then
    vim.loop.timer_stop(M.sync_timer)
  end
  
  M.sync_timer = vim.loop.new_timer()
  M.sync_timer:start(
    M.config.sync_interval,
    M.config.sync_interval,
    vim.schedule_wrap(function()
      M.process_queue()
    end)
  )
end

-- Stop sync processing
function M.stop_processing()
  if M.sync_timer then
    vim.loop.timer_stop(M.sync_timer)
    M.sync_timer = nil
  end
end

-- Get sync status
function M.get_status()
  local pending = 0
  local in_progress = 0
  local failed = 0
  
  for _, item in pairs(M.sync_queue) do
    if item.state == M.sync_states.PENDING then
      pending = pending + 1
    elseif item.state == M.sync_states.IN_PROGRESS then
      in_progress = in_progress + 1
    elseif item.state == M.sync_states.FAILED then
      failed = failed + 1
    end
  end
  
  return {
    queue_size = vim.tbl_count(M.sync_queue),
    pending = pending,
    in_progress = in_progress,
    failed = failed,
    timer_active = M.sync_timer ~= nil
  }
end

return M