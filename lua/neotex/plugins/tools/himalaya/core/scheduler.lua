-- Himalaya Unified Email Scheduling System
-- Manages all outgoing emails with configurable delays
-- Default 60-second delay provides undo capability for all sends

local M = {}

-- Dependencies
local state = require('neotex.plugins.tools.himalaya.core.state')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local utils = require('neotex.plugins.tools.himalaya.utils')
local events = require('neotex.plugins.tools.himalaya.core.events')

-- Enhanced configuration
M.config = {
  default_delay = 60,          -- 60 seconds for undo capability
  min_delay = 5,               -- Minimum 5 seconds (prevents accidental immediate send)
  check_interval = 5,          -- Check queue every 5 seconds
  max_retries = 3,             -- Maximum retry attempts
  retry_backoff = 60,          -- Base retry delay in seconds
  allow_immediate = false      -- No bypass allowed (safety feature)
}

-- Module state
M.queue = {}
M.timer = nil
M.running = false

-- Enhanced queue item structure
local function create_queue_item(email_data, account_id, options)
  options = options or {}
  local delay = options.delay or M.config.default_delay
  
  -- Enforce minimum delay for safety
  if delay < M.config.min_delay then
    delay = M.config.min_delay
  end
  
  local id = M.generate_id()
  local now = os.time()
  
  return {
    id = id,
    email_data = vim.deepcopy(email_data),
    account_id = account_id,
    created_at = now,
    scheduled_for = now + delay,
    original_delay = delay,
    status = "scheduled",         -- scheduled, sending, sent, cancelled, failed
    retries = 0,
    error = nil,
    modified = false,             -- Track if user modified the time
    recurring = nil,              -- For future: recurring schedule info
    notification_window = nil,
    metadata = options.metadata or {}
  }
end

-- Generate unique ID for queue items
function M.generate_id()
  return string.format("%s_%s", os.time(), math.random(1000, 9999))
end

-- Initialize scheduler
function M.setup(config)
  if config then
    M.config = vim.tbl_extend('force', M.config, config)
  end
  
  -- Load persisted queue
  M.load_queue()
  
  -- Start processing timer
  M.start_processing()
  
  logger.info('Unified email scheduler initialized', {
    config = M.config,
    queue_size = vim.tbl_count(M.queue)
  })
end

-- Schedule email with flexible timing
function M.schedule_email(email_data, account_id, options)
  local item = create_queue_item(email_data, account_id, options)
  
  M.queue[item.id] = item
  M.save_queue()
  
  -- Show appropriate notification based on delay
  if item.original_delay <= 300 then -- 5 minutes or less
    M.show_undo_notification(item.id)
  else
    M.show_scheduled_notification(item.id)
  end
  
  -- Use existing notification system
  local notify = require('neotex.util.notifications')
  
  -- User action notification for scheduling
  notify.himalaya(
    string.format(" Email scheduled for %s", 
      item.original_delay <= 300 and M.format_duration(item.original_delay) or os.date("%Y-%m-%d %H:%M", item.scheduled_for)),
    notify.categories.USER_ACTION,
    {
      id = item.id,
      delay = item.original_delay,
      scheduled_for = item.scheduled_for,
      subject = email_data.subject,
      can_undo = true
    }
  )
  
  -- Emit event for other components
  events.emit(events.EMAIL_SCHEDULED, {
    id = item.id,
    account_id = account_id,
    email_data = email_data,
    scheduled_for = item.scheduled_for
  })
  
  -- Log to system (debug mode only)
  logger.info("Email scheduled", {
    id = item.id,
    delay = item.original_delay,
    scheduled_for = os.date("%Y-%m-%d %H:%M", item.scheduled_for),
    subject = email_data.subject
  })
  
  return item.id
end

-- Modify scheduled time for an email
function M.reschedule_email(id, new_time)
  local item = M.queue[id]
  
  if not item then
    return false, "Email not found"
  end
  
  if item.status ~= "scheduled" then
    return false, "Can only reschedule pending emails"
  end
  
  -- Validate new time
  local now = os.time()
  if new_time <= now then
    return false, "Scheduled time must be in the future"
  end
  
  -- Update schedule
  item.scheduled_for = new_time
  item.modified = true
  M.save_queue()
  
  -- Update notification if visible
  if item.notification_window then
    M.refresh_notification(id)
  end
  
  -- Use unified notification system
  local notify = require('neotex.util.notifications')
  notify.himalaya(
    string.format(" Email rescheduled for %s", 
      os.date("%Y-%m-%d %H:%M", new_time)),
    notify.categories.USER_ACTION,
    {
      id = id,
      old_time = item.scheduled_for,
      new_time = new_time,
      subject = item.email_data.subject
    }
  )
  
  -- Emit event
  events.emit(events.EMAIL_RESCHEDULED, {
    id = id,
    old_time = item.scheduled_for,
    new_time = new_time
  })
  
  return true
end

-- Cancel scheduled email
function M.cancel_send(id)
  local item = M.queue[id]
  
  if not item then
    return false, "Email not found"
  end
  
  if item.status ~= "scheduled" then
    return false, "Can only cancel scheduled emails"
  end
  
  -- Update status
  item.status = "cancelled"
  M.save_queue()
  
  -- Close notification if open
  if item.notification_window and vim.api.nvim_win_is_valid(item.notification_window) then
    vim.api.nvim_win_close(item.notification_window, true)
  end
  
  -- Notify user
  local notify = require('neotex.util.notifications')
  notify.himalaya(
    string.format(" Email cancelled: %s", 
      item.email_data.subject or "No subject"),
    notify.categories.USER_ACTION,
    {
      id = id,
      subject = item.email_data.subject
    }
  )
  
  -- Emit event
  events.emit(events.EMAIL_CANCELLED, {
    id = id,
    email_data = item.email_data
  })
  
  -- Remove from queue after a delay (for history)
  vim.defer_fn(function()
    M.queue[id] = nil
    M.save_queue()
  end, 10000) -- Keep for 10 seconds
  
  return true
end

-- Start processing scheduled emails
function M.start_processing()
  if M.running then
    return
  end
  
  M.running = true
  M.timer = vim.loop.new_timer()
  
  M.timer:start(0, M.config.check_interval * 1000, function()
    vim.schedule(function()
      M.process_queue()
    end)
  end)
  
  logger.debug("Scheduler processing started")
end

-- Stop processing
function M.stop_processing()
  if M.timer then
    M.timer:stop()
    M.timer:close()
    M.timer = nil
  end
  M.running = false
  
  logger.debug("Scheduler processing stopped")
end

-- Process the queue for emails ready to send
function M.process_queue()
  local now = os.time()
  local sent_count = 0
  
  for id, item in pairs(M.queue) do
    if item.status == "scheduled" and item.scheduled_for <= now then
      M.send_email_now(id)
      sent_count = sent_count + 1
    end
  end
  
  if sent_count > 0 then
    logger.debug("Processed queue", {
      sent_count = sent_count,
      total_queue_size = vim.tbl_count(M.queue)
    })
  end
end

-- Send email immediately (internal function)
function M.send_email_now(id)
  local item = M.queue[id]
  if not item or item.status ~= "scheduled" then
    return false
  end
  
  -- Update status
  item.status = "sending"
  M.save_queue()
  
  -- Close notification if open
  if item.notification_window and vim.api.nvim_win_is_valid(item.notification_window) then
    vim.api.nvim_win_close(item.notification_window, true)
  end
  
  -- Emit event
  events.emit(events.EMAIL_SENDING, {
    id = id,
    email_data = item.email_data,
    account_id = item.account_id
  })
  
  -- Send email
  local ok, result = pcall(utils.send_email, item.account_id, item.email_data)
  
  if ok and result then
    item.status = "sent"
    
    local notify = require('neotex.util.notifications')
    notify.himalaya(
      string.format(" Email sent: %s", 
        item.email_data.subject or "No subject"),
      notify.categories.USER_ACTION,
      {
        id = id,
        subject = item.email_data.subject
      }
    )
    
    -- Emit success event
    events.emit(events.EMAIL_SENT, {
      id = id,
      email_data = item.email_data,
      account_id = item.account_id
    })
    
    -- Handle composer cleanup if available
    if item.metadata and item.metadata.composer_cleanup then
      M.handle_composer_cleanup(item.metadata.composer_cleanup)
    end
    
  else
    -- Handle failure
    item.status = "failed"
    item.error = tostring(result)
    item.retries = item.retries + 1
    
    local notify = require('neotex.util.notifications')
    
    if item.retries < M.config.max_retries then
      -- Schedule retry
      item.scheduled_for = os.time() + (M.config.retry_backoff * item.retries)
      item.status = "scheduled"
      
      notify.himalaya(
        string.format(" Email send failed, retrying in %ds (attempt %d/%d)", 
          M.config.retry_backoff * item.retries,
          item.retries + 1,
          M.config.max_retries),
        notify.categories.ERROR,
        {
          id = id,
          error = item.error,
          retry_count = item.retries
        }
      )
    else
      -- Max retries reached
      notify.himalaya(
        string.format(" Email send failed permanently: %s", 
          item.error),
        notify.categories.ERROR,
        {
          id = id,
          error = item.error,
          max_retries_reached = true
        }
      )
    end
    
    -- Emit failure event
    events.emit(events.EMAIL_SEND_FAILED, {
      id = id,
      email_data = item.email_data,
      error = item.error,
      retries = item.retries
    })
  end
  
  M.save_queue()
  return ok and result
end

-- Handle composer cleanup after successful send
function M.handle_composer_cleanup(cleanup_info)
  if not cleanup_info then
    return
  end
  
  local composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
  if composer.cleanup_after_queue then
    composer.cleanup_after_queue(cleanup_info.buf, cleanup_info.draft_info)
  end
end

-- Format duration for display
function M.format_duration(seconds)
  if seconds < 60 then
    return string.format("%ds", seconds)
  elseif seconds < 3600 then
    return string.format("%dm", math.floor(seconds / 60))
  else
    return string.format("%dh %dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
  end
end

-- Show undo notification for near-term emails
function M.show_undo_notification(id)
  -- This will be implemented in Phase 2
  logger.debug("Undo notification for " .. id)
end

-- Show scheduled notification for future emails  
function M.show_scheduled_notification(id)
  -- This will be implemented in Phase 2
  logger.debug("Scheduled notification for " .. id)
end

-- Refresh notification display
function M.refresh_notification(id)
  -- This will be implemented in Phase 2
  logger.debug("Refresh notification for " .. id)
end

-- Save queue to persistent storage
function M.save_queue()
  state.set('scheduler_queue', M.queue)
end

-- Load queue from persistent storage
function M.load_queue()
  M.queue = state.get('scheduler_queue', {})
  
  -- Clean up old completed items
  local now = os.time()
  local cleaned = false
  
  for id, item in pairs(M.queue) do
    -- Remove items older than 24 hours that are sent/cancelled/failed
    if (item.status == "sent" or item.status == "cancelled" or item.status == "failed") and 
       (now - item.created_at) > 86400 then
      M.queue[id] = nil
      cleaned = true
    end
  end
  
  if cleaned then
    M.save_queue()
  end
end

-- Get queue status
function M.get_queue_status()
  local status = {
    total = 0,
    scheduled = 0,
    sending = 0,
    sent = 0,
    cancelled = 0,
    failed = 0
  }
  
  for _, item in pairs(M.queue) do
    status.total = status.total + 1
    status[item.status] = (status[item.status] or 0) + 1
  end
  
  return status
end

-- Show queue (placeholder for Phase 3)
function M.show_queue()
  local notify = require('neotex.util.notifications')
  local status = M.get_queue_status()
  
  notify.himalaya(
    string.format(" Scheduled emails: %d total, %d pending", 
      status.total, status.scheduled),
    notify.categories.USER_ACTION,
    status
  )
  
  -- This will be enhanced in Phase 3 with full UI
end

-- Cancel from queue view (placeholder for Phase 3)
function M.cancel_from_queue_view()
  local notify = require('neotex.util.notifications')
  notify.himalaya(
    " Queue view will be implemented in Phase 3",
    notify.categories.STATUS
  )
end

-- Edit from queue view (placeholder for Phase 3)
function M.edit_from_queue_view()
  local notify = require('neotex.util.notifications')
  notify.himalaya(
    " Schedule editing will be implemented in Phase 2",
    notify.categories.STATUS
  )
end

-- Edit scheduled time (placeholder for Phase 2)
function M.edit_scheduled_time(id)
  local notify = require('neotex.util.notifications')
  notify.himalaya(
    " Schedule editing will be implemented in Phase 2",
    notify.categories.STATUS
  )
end

return M