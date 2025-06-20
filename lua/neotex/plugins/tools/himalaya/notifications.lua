-- Himalaya Notification Manager
-- Reduces notification spam and manages user feedback

local M = {}

-- Track recent notifications to avoid spam
M.recent_notifications = {}
M.notification_cooldown = 1000 -- 1 second cooldown for similar messages

-- Debounce similar notifications
function M.notify(message, level, opts)
  opts = opts or {}
  level = level or vim.log.levels.INFO
  
  local now = vim.loop.now()
  local msg_key = message:gsub('%d+', 'N') -- Replace numbers to group similar messages
  
  -- Check if we recently sent a similar notification
  local last_time = M.recent_notifications[msg_key]
  if last_time and (now - last_time) < M.notification_cooldown then
    -- Skip notification to avoid spam
    return
  end
  
  -- Record this notification
  M.recent_notifications[msg_key] = now
  
  -- Clean up old entries
  for key, time in pairs(M.recent_notifications) do
    if (now - time) > (M.notification_cooldown * 5) then
      M.recent_notifications[key] = nil
    end
  end
  
  -- Send the notification
  if opts.force or not opts.quiet then
    vim.notify(message, level)
  end
end

-- Silent notification (for debugging or verbose operations)
function M.notify_silent(message, level)
  M.notify(message, level, { quiet = true })
end

-- Force notification (bypasses cooldown)
function M.notify_force(message, level)
  M.notify(message, level, { force = true })
end

-- Quick status updates (very short cooldown)
function M.notify_status(message, level)
  local old_cooldown = M.notification_cooldown
  M.notification_cooldown = 300 -- 300ms for status updates
  M.notify(message, level)
  M.notification_cooldown = old_cooldown
end

-- Email operation feedback with context
function M.notify_email_operation(operation, success, details)
  local level = success and vim.log.levels.INFO or vim.log.levels.ERROR
  local status = success and 'completed' or 'failed'
  local message = string.format('Email %s %s', operation, status)
  
  if details then
    message = message .. ': ' .. details
  end
  
  M.notify(message, level)
end

-- Batch operation summary
function M.notify_batch_summary(operations)
  if #operations == 0 then
    return
  end
  
  local summary = {}
  local total = #operations
  local success_count = 0
  
  for _, op in ipairs(operations) do
    if op.success then
      success_count = success_count + 1
    end
  end
  
  if success_count == total then
    M.notify(string.format('%d email operations completed', total), vim.log.levels.INFO)
  elseif success_count == 0 then
    M.notify(string.format('%d email operations failed', total), vim.log.levels.ERROR)
  else
    M.notify(string.format('%d/%d email operations completed', success_count, total), vim.log.levels.WARN)
  end
end

-- Override vim.notify for Himalaya operations
function M.setup_notification_override()
  -- Store original notify function
  M.original_notify = vim.notify
  
  -- Override with our debounced version
  vim.notify = function(message, level, opts)
    -- Check if this is a Himalaya-related notification
    if message:match('[Hh]imalaya') or message:match('[Ee]mail') or message:match('[Ii]nbox') then
      M.notify(message, level, opts)
    else
      -- Use original notify for non-Himalaya messages
      M.original_notify(message, level, opts)
    end
  end
end

-- Restore original notify function
function M.restore_notification_override()
  if M.original_notify then
    vim.notify = M.original_notify
  end
end

return M