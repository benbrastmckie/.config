-- Himalaya Unified Email Scheduling System
-- Manages all outgoing emails with configurable delays
-- Default 60-second delay provides undo capability for all sends

local M = {}

-- Dependencies
local state = require('neotex.plugins.tools.himalaya.core.state')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local utils = require('neotex.plugins.tools.himalaya.utils')
local events_bus = require('neotex.plugins.tools.himalaya.commands.orchestrator')
local event_types = require('neotex.plugins.tools.himalaya.core.events')
local persistence = require('neotex.plugins.tools.himalaya.core.persistence')
local draft_manager = require("neotex.plugins.tools.himalaya.data.drafts")
local retry_handler = require('neotex.plugins.tools.himalaya.core.retry_handler')

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
M.initialized = false
M.draft_cleanup_map = {} -- Maps scheduled_id to draft filepath for cleanup

-- Initialize scheduler with persistent queue
function M.init()
  if M.initialized then
    return
  end
  
  logger.debug('Initializing scheduler with persistence')
  
  -- Load existing queue from disk
  M.queue = persistence.load_queue() or {}
  
  -- Clean up any expired entries
  M.queue = persistence.cleanup_expired_emails(M.queue)
  
  -- Start the scheduler if we have pending emails
  if vim.tbl_count(M.queue) > 0 then
    M.start_processing()
  end
  
  M.initialized = true
  logger.info('Scheduler initialized with ' .. vim.tbl_count(M.queue) .. ' emails')
end

-- Persist queue to disk
function M.persist_queue()
  local success = persistence.save_queue(M.queue)
  if not success then
    logger.error('Failed to persist email queue')
  end
  return success
end

-- Sync queue with external changes (from other instances)
function M.sync_from_disk()
  if not M.initialized then
    return false
  end
  
  -- Check if file has been modified since our last load
  local last_load_time = persistence._last_load_time or 0
  local file_mtime = persistence.get_queue_file_mtime()
  
  logger.debug(string.format('Sync check: last_load=%d, file_mtime=%d', last_load_time, file_mtime))
  
  if not persistence.is_queue_file_newer(last_load_time) then
    logger.debug('No external changes detected')
    return false -- No changes
  end
  
  logger.debug('External changes detected, syncing from disk')
  
  -- Load the current disk state
  local disk_queue = persistence.load_queue()
  if not disk_queue then
    logger.debug('Failed to load disk queue')
    return false
  end
  
  -- Merge external changes with our current queue
  local merged_queue, changes_detected = persistence.merge_queue_changes(M.queue, disk_queue)
  
  if changes_detected then
    M.queue = merged_queue
    logger.info('Synced external changes: ' .. vim.tbl_count(M.queue) .. ' total emails')
    return true
  else
    logger.debug('No meaningful changes detected after merge')
  end
  
  return false
end

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
  -- Ensure scheduler is initialized
  if not M.initialized then
    M.init()
  end
  
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
  
  -- User action notification for scheduling (suppress in test mode)
  if not _G.HIMALAYA_TEST_MODE then
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
  end
  
  -- Emit event for other components
  events_bus.emit(event_types.EMAIL_SCHEDULED, {
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
  if not _G.HIMALAYA_TEST_MODE then
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
  end
  
  -- Emit event
  events_bus.emit(event_types.EMAIL_RESCHEDULED, {
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
  if not _G.HIMALAYA_TEST_MODE then
    notify.himalaya(
      string.format(" Email cancelled: %s", 
        item.email_data.subject or "No subject"),
      notify.categories.USER_ACTION,
      {
        id = id,
        subject = item.email_data.subject
      }
    )
  end
  
  -- Emit event
  events_bus.emit(event_types.EMAIL_CANCELLED, {
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

-- Pause scheduled email (indefinite delay)
function M.pause_email(id)
  local item = M.queue[id]
  
  if not item then
    return false, "Email not found"
  end
  
  if item.status ~= "scheduled" then
    return false, "Can only pause scheduled emails"
  end
  
  -- Update status to paused
  item.status = "paused"
  item.paused_at = os.time()
  item.original_scheduled_for = item.scheduled_for
  M.save_queue()
  
  -- Close notification if open
  if item.notification_window and vim.api.nvim_win_is_valid(item.notification_window) then
    vim.api.nvim_win_close(item.notification_window, true)
  end
  
  -- Notify user
  local notify = require('neotex.util.notifications')
  notify.himalaya(
    string.format(" Email paused: %s", 
      item.email_data.subject or "No subject"),
    notify.categories.USER_ACTION,
    {
      id = id,
      subject = item.email_data.subject
    }
  )
  
  -- Emit event
  events_bus.emit(event_types.EMAIL_PAUSED, {
    id = id,
    email_data = item.email_data
  })
  
  return true
end

-- Resume paused email
function M.resume_email(id, new_time)
  local item = M.queue[id]
  
  if not item then
    return false, "Email not found"
  end
  
  if item.status ~= "paused" then
    return false, "Can only resume paused emails"
  end
  
  -- Set new schedule time or restore original with remaining time
  local now = os.time()
  if new_time then
    item.scheduled_for = new_time
  elseif item.original_scheduled_for then
    -- Calculate how much time was remaining when paused
    local time_remaining_when_paused = item.original_scheduled_for - (item.paused_at or now)
    if time_remaining_when_paused > 0 then
      -- Resume with the remaining time
      item.scheduled_for = now + time_remaining_when_paused
    else
      -- If the original time has passed, use default delay
      item.scheduled_for = now + M.config.default_delay
    end
  else
    -- Fallback to default delay if no original time
    item.scheduled_for = now + M.config.default_delay
  end
  item.status = "scheduled"
  item.paused_at = nil
  M.save_queue()
  
  -- Notify user
  local notify = require('neotex.util.notifications')
  notify.himalaya(
    string.format(" Email resumed for %s", 
      os.date("%Y-%m-%d %H:%M", item.scheduled_for)),
    notify.categories.USER_ACTION,
    {
      id = id,
      subject = item.email_data.subject,
      scheduled_for = item.scheduled_for
    }
  )
  
  -- Emit event
  events_bus.emit(event_types.EMAIL_RESUMED, {
    id = id,
    email_data = item.email_data,
    scheduled_for = item.scheduled_for
  })
  
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
    -- Only process scheduled emails (not paused)
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
  events_bus.emit(event_types.EMAIL_SENDING, {
    id = id,
    email_data = item.email_data,
    account_id = item.account_id
  })
  
  -- Send email
  local ok, result = pcall(utils.send_email, item.account_id, item.email_data)
  
  if ok and result then
    item.status = "sent"
    
    local notify = require('neotex.util.notifications')
    if not _G.HIMALAYA_TEST_MODE then
      notify.himalaya(
        string.format(" Email sent: %s", 
          item.email_data.subject or "No subject"),
        notify.categories.USER_ACTION,
        {
          id = id,
          subject = item.email_data.subject
        }
      )
    end
    
    -- Clean up draft after successful send
    M.cleanup_draft_after_send(id)
    
    -- Emit success event
    events_bus.emit(event_types.EMAIL_SENT, {
      id = id,
      email_data = item.email_data,
      account_id = item.account_id
    })
    
    -- Clean up draft if metadata exists
    if item.metadata and item.metadata.draft_id then
      logger.info('Cleaning up draft after send', {
        draft_id = item.metadata.draft_id,
        draft_file = item.metadata.draft_file,
        draft_account = item.metadata.draft_account or item.account_id
      })
      
      -- Show this for debugging (not in test mode)
      local notify = require('neotex.util.notifications')
      if not _G.HIMALAYA_TEST_MODE then
        notify.himalaya(string.format('Deleting draft ID: %s after send', 
          tostring(item.metadata.draft_id)), notify.categories.INFO)
      end
      
      -- Delete draft from maildir with retry
      local draft_account = item.metadata.draft_account or item.account_id
      local draft_folder = item.metadata.draft_folder or utils.find_draft_folder(draft_account)
      if draft_folder then
        logger.info('Deleting draft from maildir', {
          account = draft_account,
          folder = draft_folder,
          draft_id = item.metadata.draft_id
        })
        
        -- Use retry handler for draft deletion
        local del_ok, del_result = retry_handler.retry_himalaya(function()
          return utils.delete_email(draft_account, draft_folder, item.metadata.draft_id)
        end, 'draft deletion')
        
        if del_ok then
          logger.info('Draft deleted from maildir successfully', {
            draft_id = item.metadata.draft_id
          })
          if not _G.HIMALAYA_TEST_MODE then
            notify.himalaya('Draft cleaned up successfully', notify.categories.INFO)
          end
          
          -- With Maildir, drafts are deleted directly via himalaya
          -- No need to track buffers since the draft file is already deleted
        else
          logger.warn('Failed to delete draft from maildir after retries', {
            error = del_result,
            draft_id = item.metadata.draft_id,
            folder = draft_folder,
            account = draft_account
          })
          if not _G.HIMALAYA_TEST_MODE then
            notify.himalaya(string.format('Failed to delete draft: %s', tostring(del_result)), 
              notify.categories.WARNING)
          end
        end
      else
        logger.warn('Could not find draft folder for account', {
          account = draft_account
        })
      end
      
      -- Delete local draft file
      if item.metadata.draft_file then
        vim.fn.delete(item.metadata.draft_file)
        logger.debug('Local draft file deleted', {
          file = item.metadata.draft_file
        })
      end
    else
      logger.debug('No draft cleanup needed - missing metadata', {
        has_metadata = item.metadata ~= nil,
        has_draft_id = item.metadata and item.metadata.draft_id ~= nil
      })
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
      
      if not _G.HIMALAYA_TEST_MODE then
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
      end
    else
      -- Max retries reached
      if not _G.HIMALAYA_TEST_MODE then
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
    end
    
    -- Emit failure event
    events_bus.emit(event_types.EMAIL_SEND_FAILED, {
      id = id,
      email_data = item.email_data,
      error = item.error,
      retries = item.retries
    })
  end
  
  M.save_queue()
  return ok and result
end


-- Format duration for display
function M.format_duration(seconds)
  if seconds < 60 then
    return string.format("%d seconds", seconds)
  elseif seconds < 3600 then
    local mins = math.floor(seconds / 60 + 0.5)  -- Round to nearest minute
    return string.format("%d minute%s", mins, mins == 1 and "" or "s")
  else
    local hours = math.floor(seconds / 3600)
    return string.format("%d hour%s", hours, hours == 1 and "" or "s")
  end
end

-- Format countdown timer for sidebar display
function M.format_countdown(seconds)
  if seconds <= 0 then
    return " SENDING"
  elseif seconds < 60 then
    return string.format(" %02d:%02d", 0, seconds)
  elseif seconds < 3600 then
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format(" %02d:%02d", mins, secs)
  else
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    return string.format("%3d:%02d", hours, mins)
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
  -- Use new persistent storage
  M.persist_queue()
  -- Also keep in state for backward compatibility
  state.set('scheduler_queue', M.queue)
end

-- Load queue from persistent storage
function M.load_queue()
  -- Initialize if not already done
  if not M.initialized then
    M.init()
    return
  end
  
  -- Load from persistent storage
  M.queue = persistence.load_queue() or {}
  
  -- Clean up old completed items
  M.queue = persistence.cleanup_expired_emails(M.queue)
  
  -- Save cleaned queue back
  M.persist_queue()
  
  -- Also keep in state for backward compatibility
  state.set('scheduler_queue', M.queue)
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

-- Get all scheduled emails (for sidebar display)
function M.get_scheduled_emails()
  -- Ensure scheduler is initialized
  if not M.initialized then
    M.init()
  end
  
  -- Sync with external changes from other instances
  M.sync_from_disk()
  
  local scheduled = {}
  
  for id, item in pairs(M.queue) do
    if item.status == "scheduled" or item.status == "paused" then
      table.insert(scheduled, {
        id = id,
        email_data = item.email_data,
        account_id = item.account_id,
        scheduled_for = item.scheduled_for,
        created_at = item.created_at,
        modified = item.modified,
        metadata = item.metadata,
        status = item.status,
        paused_at = item.paused_at,
        original_scheduled_for = item.original_scheduled_for
      })
    end
  end
  
  -- Sort by scheduled time (earliest first), but put paused emails at the end
  table.sort(scheduled, function(a, b)
    if a.status == "paused" and b.status ~= "paused" then
      return false
    elseif a.status ~= "paused" and b.status == "paused" then
      return true
    else
      return a.scheduled_for < b.scheduled_for
    end
  end)
  
  return scheduled
end

-- Get a specific scheduled email
function M.get_scheduled_email(id)
  -- Sync with external changes before lookup
  M.sync_from_disk()
  
  local item = M.queue[id]
  if item and (item.status == "scheduled" or item.status == "paused") then
    return {
      id = id,
      email_data = item.email_data,
      account_id = item.account_id,
      scheduled_for = item.scheduled_for,
      created_at = item.created_at,
      modified = item.modified,
      metadata = item.metadata,
      status = item.status,
      paused_at = item.paused_at,
      original_scheduled_for = item.original_scheduled_for
    }
  end
  return nil
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

-- Edit scheduled time with telescope picker
function M.edit_scheduled_time(id, new_time)
  -- In test mode, directly update the time without showing picker
  if _G.HIMALAYA_TEST_MODE and new_time then
    local item = M.queue[id]
    if not item then
      return false, "Scheduled email not found"
    end
    
    item.scheduled_time = new_time
    M.persist_queue()
    return true
  end
  
  -- Normal mode: show picker
  M.show_reschedule_picker(id)
end

-- Telescope reschedule picker with presets
function M.show_reschedule_picker(id)
  -- Don't show picker in test mode
  if _G.HIMALAYA_TEST_MODE then
    return
  end
  
  local item = M.queue[id]
  if not item then 
    local notify = require('neotex.util.notifications')
    notify.himalaya("Scheduled email not found", notify.categories.ERROR)
    return 
  end
  
  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local themes = require('telescope.themes')
  
  local options = {}
  
  -- Add PAUSE or RESUME based on current status
  if item.status == "paused" then
    table.insert(options, { text = "RESUME", value = "resume" })
  else
    table.insert(options, { text = "PAUSE", value = "pause" })
  end
  
  -- Add common scheduling options
  table.insert(options, { text = "In 1 minute", value = 60 })
  table.insert(options, { text = "In 5 minutes", value = 300 })
  table.insert(options, { text = "In 30 minutes", value = 1800 })
  table.insert(options, { text = "In 1 hour", value = 3600 })
  table.insert(options, { text = "In 2 hours", value = 7200 })
  table.insert(options, { text = "Tomorrow morning (9 AM)", value = "tomorrow_9am" })
  table.insert(options, { text = "Tomorrow afternoon (2 PM)", value = "tomorrow_2pm" })
  table.insert(options, { text = "Next Monday (9 AM)", value = "next_monday_9am" })
  table.insert(options, { text = "Custom time...", value = "custom" })
  
  -- Use custom theme from telescope config
  local theme_opts = themes.get_dropdown({
    winblend = 10,
    previewer = false,
    layout_config = {
      width = 80,  -- 80 characters wide
      height = 15, -- 15 lines tall
    },
  })
  
  pickers.new(theme_opts, {
    prompt_title = "Reschedule Email",
    finder = finders.new_table {
      results = options,
      entry_maker = function(entry)
        return {
          value = entry.value,
          display = entry.text,
          ordinal = entry.text,
        }
      end
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if not selection then return end
        
        local value = selection.value
        local new_time
        local now = os.time()
        
        if value == "pause" then
          M.pause_email(id)
          return
        elseif value == "resume" then
          M.resume_email(id)
          return
        elseif type(value) == "number" then
          new_time = now + value
        elseif value == "tomorrow_9am" then
          new_time = M.get_next_time(9, 0)
        elseif value == "tomorrow_2pm" then
          new_time = M.get_next_time(14, 0)
        elseif value == "next_monday_9am" then
          new_time = M.get_next_monday(9, 0)
        elseif value == "custom" then
          M.show_custom_time_picker(id)
          return
        end
        
        if new_time then
          M.reschedule_email(id, new_time)
        end
      end)
      return true
    end,
  }):find()
end

-- Helper to get next occurrence of specific time
function M.get_next_time(hour, minute)
  local now = os.time()
  local date = os.date("*t", now)
  
  -- Set target time for today
  date.hour = hour
  date.min = minute
  date.sec = 0
  
  local target_time = os.time(date)
  
  -- If target time has passed today, use tomorrow
  if target_time <= now then
    target_time = target_time + 86400  -- Add 24 hours
  end
  
  return target_time
end

-- Helper to get next Monday at specific time
function M.get_next_monday(hour, minute)
  local now = os.time()
  local date = os.date("*t", now)
  
  -- Calculate days until next Monday (1 = Sunday, 2 = Monday, etc.)
  local days_until_monday = (9 - date.wday) % 7
  if days_until_monday == 0 then
    days_until_monday = 7  -- If today is Monday, use next Monday
  end
  
  -- Set target time
  date.hour = hour
  date.min = minute
  date.sec = 0
  
  local target_time = os.time(date) + (days_until_monday * 86400)
  
  return target_time
end

-- Custom time picker with smart parsing
function M.show_custom_time_picker(id)
  local item = M.queue[id]
  if not item then return end
  
  local current = os.date("%Y-%m-%d %H:%M", item.scheduled_for)
  
  vim.ui.input({
    prompt = " New send time: ",
    default = current,
    completion = "customlist,v:lua.require('neotex.plugins.tools.himalaya.data.scheduler').complete_time"
  }, function(input)
    if not input then return end
    
    -- Parse various time formats
    local new_time = M.parse_time_input(input)
    
    if new_time then
      -- Validate time is in future
      if new_time > os.time() then
        M.reschedule_email(id, new_time)
      else
        local notify = require('neotex.util.notifications')
        notify.himalaya(" Time must be in the future", notify.categories.ERROR)
      end
    else
      local notify = require('neotex.util.notifications')
      notify.himalaya(" Invalid time format. Try: YYYY-MM-DD HH:MM or '2h', 'tomorrow 9am'", 
        notify.categories.ERROR)
    end
  end)
end

-- Parse flexible time inputs
function M.parse_time_input(input)
  -- Support various formats:
  -- "2025-12-25 14:30" - Standard format
  -- "2h" or "2 hours" - Relative time
  -- "tomorrow 9am" - Natural language
  -- "next monday" - Day references
  
  local now = os.time()
  
  -- Standard datetime format
  local year, month, day, hour, min = input:match("(%d+)-(%d+)-(%d+)%s+(%d+):(%d+)")
  if year then
    return os.time({
      year = tonumber(year),
      month = tonumber(month),
      day = tonumber(day),
      hour = tonumber(hour),
      min = tonumber(min),
      sec = 0
    })
  end
  
  -- Relative time (e.g., "2h", "30m", "1d")
  local amount, unit = input:match("^(%d+)%s*([hmd])$")
  if amount then
    amount = tonumber(amount)
    if unit == 'h' then
      return now + (amount * 3600)
    elseif unit == 'm' then
      return now + (amount * 60)
    elseif unit == 'd' then
      return now + (amount * 86400)
    end
  end
  
  -- Natural language parsing
  local lower_input = input:lower()
  
  -- Tomorrow at specific time
  if lower_input:match("tomorrow") then
    local hour_str = lower_input:match("(%d+)%s*[ap]m") or lower_input:match("(%d+)")
    local hour = tonumber(hour_str) or 9
    
    -- Handle PM
    if lower_input:match("pm") and hour < 12 then
      hour = hour + 12
    end
    
    return M.get_next_time(hour, 0)
  end
  
  -- Next weekday
  local weekdays = {
    monday = 2, tuesday = 3, wednesday = 4,
    thursday = 5, friday = 6, saturday = 7, sunday = 1
  }
  
  for day_name, day_num in pairs(weekdays) do
    if lower_input:match("next " .. day_name) then
      local hour_str = lower_input:match("(%d+)%s*[ap]m") or lower_input:match("(%d+)")
      local hour = tonumber(hour_str) or 9
      
      -- Handle PM
      if lower_input:match("pm") and hour < 12 then
        hour = hour + 12
      end
      
      -- Calculate days until target weekday
      local date = os.date("*t", now)
      local days_until = (day_num - date.wday + 7) % 7
      if days_until == 0 then
        days_until = 7  -- Next week if today
      end
      
      date.hour = hour
      date.min = 0
      date.sec = 0
      
      return os.time(date) + (days_until * 86400)
    end
  end
  
  -- Time today (e.g., "3pm", "15:30")
  local hour_str, min_str = lower_input:match("(%d+):(%d+)")
  if hour_str then
    local hour = tonumber(hour_str)
    local min = tonumber(min_str)
    return M.get_next_time(hour, min)
  end
  
  -- Just hour with am/pm
  local hour_match, ampm = lower_input:match("(%d+)%s*([ap]m)")
  if hour_match then
    local hour = tonumber(hour_match)
    if ampm == "pm" and hour < 12 then
      hour = hour + 12
    elseif ampm == "am" and hour == 12 then
      hour = 0  -- 12am is midnight
    end
    return M.get_next_time(hour, 0)
  end
  
  return nil
end

-- Completion function for time input
function M.complete_time(ArgLead, CmdLine, CursorPos)
  local suggestions = {
    os.date("%Y-%m-%d %H:%M", os.time() + 300),     -- 5 minutes
    os.date("%Y-%m-%d %H:%M", os.time() + 3600),    -- 1 hour
    "1h",
    "2h", 
    "30m",
    "tomorrow 9am",
    "tomorrow 2pm",
    "next monday 10am"
  }
  
  local matches = {}
  for _, suggestion in ipairs(suggestions) do
    if suggestion:find(ArgLead, 1, true) == 1 then
      table.insert(matches, suggestion)
    end
  end
  
  return matches
end

-- Register a draft for cleanup after successful send
function M.register_draft_for_cleanup(scheduled_id, draft_filepath)
  if scheduled_id and draft_filepath then
    M.draft_cleanup_map[scheduled_id] = draft_filepath
    logger.debug('Registered draft for cleanup', {
      scheduled_id = scheduled_id,
      draft_filepath = draft_filepath
    })
  end
end

-- Clean up draft after successful send
function M.cleanup_draft_after_send(scheduled_id)
  local draft_filepath = M.draft_cleanup_map[scheduled_id]
  if draft_filepath then
    local success = vim.fn.delete(draft_filepath) == 0
    if success then
      logger.debug('Draft cleaned up after successful send', {
        scheduled_id = scheduled_id,
        draft_filepath = draft_filepath
      })
    else
      logger.error('Failed to cleanup draft after send', {
        scheduled_id = scheduled_id,
        draft_filepath = draft_filepath
      })
    end
    -- Remove from cleanup map regardless of success
    M.draft_cleanup_map[scheduled_id] = nil
  end
end

-- Get a queue item by ID
function M.get_queue_item(id)
  return M.queue[id]
end

-- Remove an item from the queue (for both scheduled and paused emails)
function M.remove_from_queue(id)
  local item = M.queue[id]
  
  if not item then
    return false, "Email not found"
  end
  
  -- Remove from queue
  M.queue[id] = nil
  M.save_queue()
  
  -- Close notification if open
  if item.notification_window and vim.api.nvim_win_is_valid(item.notification_window) then
    vim.api.nvim_win_close(item.notification_window, true)
  end
  
  -- Notify user
  local status_text = item.status == "paused" and "Paused" or "Scheduled"
  vim.notify(status_text .. " email deleted", vim.log.levels.INFO)
  
  -- Refresh the email list
  vim.defer_fn(function()
    local main = require('neotex.plugins.tools.himalaya.ui.main')
    main.refresh_email_list({ restore_insert_mode = false })
  end, 100)
  
  return true
end

return M