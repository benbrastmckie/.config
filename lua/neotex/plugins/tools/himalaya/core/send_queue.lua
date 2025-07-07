-- Himalaya Delayed Send Queue System
-- Implements 60-second undo send functionality
-- Provides reliable queuing, retry, and cancellation capabilities

local M = {}

local state = require('neotex.plugins.tools.himalaya.core.state')
local notify = require('neotex.util.notifications') 
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local utils = require('neotex.plugins.tools.himalaya.utils')
local config = require('neotex.plugins.tools.himalaya.core.config')

-- Queue configuration
M.config = {
  delay_seconds = 60,     -- 1 minute default delay
  check_interval = 5,     -- Check queue every 5 seconds
  max_retries = 3,        -- Maximum retry attempts
  retry_backoff = 60      -- Base retry delay in seconds
}

-- Queue state
M.queue = {}
M.timer = nil
M.is_initialized = false

-- Queue item structure
local queue_item_schema = {
  id = "",
  email_data = {},
  account_id = "",
  queued_at = 0,
  send_at = 0,
  status = "pending", -- pending, sending, sent, cancelled, failed
  retries = 0,
  error = nil,
  undo_window = nil
}

-- Get queue status for testing and monitoring
function M.get_status()
  return {
    initialized = M.is_initialized,
    active_count = vim.tbl_count(M.queue),
    timer_running = M.timer ~= nil,
    config = M.config
  }
end

-- Initialize queue system
function M.init()
  if M.is_initialized then
    return
  end
  
  -- Load queue from state
  M.queue = state.get('send_queue', {})
  
  -- Clean up any orphaned undo windows
  M.cleanup_orphaned_windows()
  
  -- Start queue processor
  M.start_processor()
  
  -- Clean old items
  M.cleanup_old_items()
  
  M.is_initialized = true
  
  logger.info("Send queue initialized with " .. vim.tbl_count(M.queue) .. " items")
end

-- Add email to delayed send queue
function M.queue_email(email_data, account_id, delay_override)
  M.init() -- Ensure initialized
  
  local delay = delay_override or M.config.delay_seconds
  local id = vim.fn.tempname():match("([^/]+)$") .. "_" .. os.time()
  local now = os.time()
  
  local item = {
    id = id,
    email_data = vim.deepcopy(email_data),
    account_id = account_id,
    queued_at = now,
    send_at = now + delay,
    status = "pending",
    retries = 0,
    error = nil
  }
  
  M.queue[id] = item
  M.save_queue()
  
  -- Show immediate feedback
  notify.himalaya(
    string.format("📨 Email queued. Will send in %d seconds", delay),
    notify.categories.USER_ACTION,
    { 
      id = id,
      subject = email_data.subject or "No subject",
      can_undo = true
    }
  )
  
  -- Show undo notification window
  M.show_undo_notification(id)
  
  logger.info("Email queued for delayed send", {
    id = id,
    delay = delay,
    subject = email_data.subject,
    to = email_data.to
  })
  
  return id
end

-- Cancel queued email
function M.cancel_send(id)
  local item = M.queue[id]
  
  if not item then
    notify.himalaya(
      "❌ Email not found in queue",
      notify.categories.ERROR
    )
    return false
  end
  
  if item.status ~= "pending" then
    notify.himalaya(
      string.format("⚠️ Cannot cancel - email is %s", item.status),
      notify.categories.WARNING
    )
    return false
  end
  
  -- Update status
  item.status = "cancelled"
  M.save_queue()
  
  -- Close undo window if open
  if item.undo_window and vim.api.nvim_win_is_valid(item.undo_window) then
    vim.api.nvim_win_close(item.undo_window, true)
    item.undo_window = nil
  end
  
  notify.himalaya(
    "✅ Email send cancelled",
    notify.categories.USER_ACTION,
    { subject = item.email_data.subject or "No subject" }
  )
  
  logger.info("Email send cancelled", {
    id = id,
    subject = item.email_data.subject
  })
  
  return true
end

-- Show undo notification with countdown
function M.show_undo_notification(id)
  local item = M.queue[id]
  if not item then 
    return 
  end
  
  -- Create floating window for undo interface
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'filetype', 'himalaya-undo')
  
  local width = 55
  local height = 5
  local win = vim.api.nvim_open_win(buf, false, {
    relative = 'editor',
    width = width,
    height = height,
    col = vim.o.columns - width - 2,
    row = vim.o.lines - height - 3,
    style = 'minimal',
    border = 'rounded',
    title = ' Undo Send ',
    title_pos = 'center'
  })
  
  -- Store window reference
  item.undo_window = win
  
  -- Update countdown timer
  local update_timer
  update_timer = vim.loop.new_timer()
  
  local function update_display()
    -- Check if item still exists and is pending
    if not M.queue[id] or M.queue[id].status ~= "pending" then
      update_timer:stop()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
      return
    end
    
    local now = os.time()
    local remaining = item.send_at - now
    
    if remaining <= 0 then
      update_timer:stop()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
      return
    end
    
    local subject = item.email_data.subject or "No subject"
    if #subject > 35 then
      subject = subject:sub(1, 32) .. "..."
    end
    
    local lines = {
      string.format("📨 Sending in %d seconds", remaining),
      string.format("Subject: %s", subject),
      string.format("To: %s", vim.inspect(item.email_data.to):gsub("[{}\"']", "")),
      "",
      "Press 'u' to undo, 'ESC' to dismiss"
    }
    
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end
  
  -- Start countdown
  update_display()
  update_timer:start(0, 1000, vim.schedule_wrap(update_display))
  
  -- Set up keymaps
  vim.api.nvim_buf_set_keymap(buf, 'n', 'u', '', {
    callback = function()
      update_timer:stop()
      vim.api.nvim_win_close(win, true)
      M.cancel_send(id)
    end,
    desc = "Undo email send"
  })
  
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', '', {
    callback = function()
      update_timer:stop()
      vim.api.nvim_win_close(win, true)
    end,
    desc = "Dismiss undo window"
  })
  
  -- Auto-close after send
  vim.defer_fn(function()
    if update_timer then
      update_timer:stop()
    end
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, (item.send_at - os.time() + 1) * 1000)
end

-- Start the queue processor
function M.start_processor()
  if M.timer then
    M.timer:stop()
  end
  
  M.timer = vim.loop.new_timer()
  M.timer:start(
    M.config.check_interval * 1000,
    M.config.check_interval * 1000,
    vim.schedule_wrap(function()
      M.process_queue()
    end)
  )
  
  logger.debug("Queue processor started")
end

-- Process pending emails in queue
function M.process_queue()
  local now = os.time()
  local processed = 0
  
  for id, item in pairs(M.queue) do
    if item.status == "pending" and now >= item.send_at then
      M.send_queued_email(id)
      processed = processed + 1
    end
  end
  
  if processed > 0 then
    logger.debug("Processed " .. processed .. " queued emails")
  end
end

-- Send a queued email
function M.send_queued_email(id)
  local item = M.queue[id]
  if not item then 
    return 
  end
  
  logger.info("Sending queued email", {
    id = id,
    subject = item.email_data.subject,
    account = item.account_id
  })
  
  -- Update status
  item.status = "sending"
  M.save_queue()
  
  -- Close undo window if still open
  if item.undo_window and vim.api.nvim_win_is_valid(item.undo_window) then
    vim.api.nvim_win_close(item.undo_window, true)
    item.undo_window = nil
  end
  
  -- Get account configuration
  local account_config = config.get_account(item.account_id) 
  if not account_config then
    item.status = "failed"
    item.error = "Account not found: " .. item.account_id
    M.save_queue()
    
    notify.himalaya(
      "❌ Failed to send email: Account not found",
      notify.categories.ERROR,
      { subject = item.email_data.subject }
    )
    return
  end
  
  -- Send the email using the himalaya utils
  local success = utils.send_email(item.account_id, item.email_data)
  
  if success then
    item.status = "sent"
    notify.himalaya(
      "✅ Email sent successfully",
      notify.categories.USER_ACTION,
      { subject = item.email_data.subject or "No subject" }
    )
    
    logger.info("Email sent successfully", {
      id = id,
      subject = item.email_data.subject
    })
    
    -- Trigger refresh after successful send
    vim.defer_fn(function()
      vim.api.nvim_exec_autocmds('User', { pattern = 'HimalayaEmailSent' })
    end, 100)
    
  else
    -- Handle send failure with retry logic
    item.retries = item.retries + 1
    
    if item.retries < M.config.max_retries then
      item.status = "pending"
      item.send_at = os.time() + (M.config.retry_backoff * item.retries) -- Exponential backoff
      
      notify.himalaya(
        string.format("⚠️ Send failed, will retry in %d seconds (attempt %d/%d)", 
          M.config.retry_backoff * item.retries,
          item.retries + 1, 
          M.config.max_retries),
        notify.categories.WARNING,
        { 
          subject = item.email_data.subject,
          retry_in = M.config.retry_backoff * item.retries
        }
      )
      
      logger.warn("Email send failed, retrying", {
        id = id,
        retry_attempt = item.retries,
        next_retry = item.send_at
      })
    else
      item.status = "failed"
      item.error = "Max retries exceeded"
      
      notify.himalaya(
        "❌ Email send failed permanently after " .. M.config.max_retries .. " attempts",
        notify.categories.ERROR,
        { subject = item.email_data.subject }
      )
      
      logger.error("Email send failed permanently", {
        id = id,
        subject = item.email_data.subject,
        retries = item.retries
      })
    end
  end
  
  M.save_queue()
end

-- Show queue status
function M.show_queue()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, "Himalaya Send Queue")
  vim.api.nvim_buf_set_option(buf, 'filetype', 'himalaya-queue')
  
  local lines = {"📨 Email Send Queue", ""}
  
  local pending = 0
  local sent = 0
  local failed = 0
  local cancelled = 0
  
  -- Sort items by send time
  local sorted_items = {}
  for id, item in pairs(M.queue) do
    table.insert(sorted_items, {id = id, item = item})
  end
  
  table.sort(sorted_items, function(a, b)
    return a.item.send_at < b.item.send_at
  end)
  
  -- Display items by status
  for _, entry in ipairs(sorted_items) do
    local id, item = entry.id, entry.item
    local subject = item.email_data.subject or "No subject"
    local status_icon = {
      pending = "⏱️",
      sending = "📤", 
      sent = "✅",
      failed = "❌",
      cancelled = "🚫"
    }
    
    if item.status == "pending" then
      pending = pending + 1
      local remaining = math.max(0, item.send_at - os.time())
      table.insert(lines, string.format(
        "%s %s - sends in %ds",
        status_icon[item.status],
        subject,
        remaining
      ))
    elseif item.status == "sent" then
      sent = sent + 1
      table.insert(lines, string.format(
        "%s %s - sent at %s",
        status_icon[item.status],
        subject,
        os.date("%H:%M:%S", item.send_at)
      ))
    elseif item.status == "failed" then
      failed = failed + 1
      table.insert(lines, string.format(
        "%s %s - %s",
        status_icon[item.status],
        subject,
        item.error or "Send failed"
      ))
    elseif item.status == "cancelled" then
      cancelled = cancelled + 1
      table.insert(lines, string.format(
        "%s %s - cancelled",
        status_icon[item.status],
        subject
      ))
    end
  end
  
  -- Insert summary at the top
  table.insert(lines, 3, string.format(
    "Pending: %d | Sent: %d | Failed: %d | Cancelled: %d",
    pending, sent, failed, cancelled
  ))
  table.insert(lines, 4, string.rep("─", 60))
  
  if #sorted_items == 0 then
    table.insert(lines, "")
    table.insert(lines, "No emails in queue")
  end
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Open in split window
  vim.cmd('split')
  vim.api.nvim_win_set_buf(0, buf)
  
  -- Set up keymaps for queue management
  vim.api.nvim_buf_set_keymap(buf, 'n', 'r', '', {
    callback = function()
      -- Refresh queue display
      vim.cmd('bdelete')
      M.show_queue()
    end,
    desc = "Refresh queue"
  })
  
  vim.api.nvim_buf_set_keymap(buf, 'n', 'c', '', {
    callback = function()
      -- Clear completed items
      M.cleanup_old_items()
      vim.cmd('bdelete')
      M.show_queue()
    end,
    desc = "Clear completed items"
  })
end

-- Get queue statistics
function M.get_stats()
  local stats = {
    pending = 0,
    sending = 0,
    sent = 0,
    failed = 0,
    cancelled = 0,
    total = 0
  }
  
  for _, item in pairs(M.queue) do
    stats[item.status] = stats[item.status] + 1
    stats.total = stats.total + 1
  end
  
  return stats
end

-- Save queue state to persistent storage
function M.save_queue()
  -- Remove window references before saving (they can't be serialized)
  local clean_queue = {}
  for id, item in pairs(M.queue) do
    clean_queue[id] = vim.deepcopy(item)
    clean_queue[id].undo_window = nil
  end
  
  state.set('send_queue', clean_queue)
end

-- Clean up old completed items
function M.cleanup_old_items()
  local cutoff = os.time() - (24 * 60 * 60) -- 24 hours
  local cleaned = 0
  
  for id, item in pairs(M.queue) do
    if (item.status == "sent" or item.status == "cancelled") and item.queued_at < cutoff then
      M.queue[id] = nil
      cleaned = cleaned + 1
    end
  end
  
  if cleaned > 0 then
    M.save_queue()
    logger.info("Cleaned " .. cleaned .. " old queue items")
  end
  
  return cleaned
end

-- Clean up any orphaned floating windows
function M.cleanup_orphaned_windows()
  -- This helps when the plugin is reloaded
  for _, item in pairs(M.queue) do
    if item.undo_window and not vim.api.nvim_win_is_valid(item.undo_window) then
      item.undo_window = nil
    end
  end
end

-- Stop the queue processor (for cleanup)
function M.stop()
  if M.timer then
    M.timer:stop()
    M.timer = nil
  end
  
  -- Close any open undo windows
  for _, item in pairs(M.queue) do
    if item.undo_window and vim.api.nvim_win_is_valid(item.undo_window) then
      vim.api.nvim_win_close(item.undo_window, true)
    end
  end
  
  M.is_initialized = false
  logger.info("Send queue stopped")
end

-- Get queue item by ID (for external access)
function M.get_item(id)
  return M.queue[id]
end

-- Update queue configuration
function M.configure(new_config)
  M.config = vim.tbl_extend('force', M.config, new_config)
  logger.info("Send queue configuration updated", new_config)
end

return M