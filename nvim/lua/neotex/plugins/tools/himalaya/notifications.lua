-- Himalaya Notifications Module
-- Centralized notification handling for the email client

local M = {}

-- Notification functions
function M.notify(message, level)
  vim.notify(message, level)
end

-- Status notification (can be suppressed)
function M.notify_status(message, level)
  vim.notify(message, level)
end

-- Force notification (always shown)
function M.notify_force(message, level)
  vim.notify(message, level)
end

-- Setup notification override (for performance optimization)
function M.setup_notification_override()
  -- Can be extended to filter notifications
end

-- Restore notification override
function M.restore_notification_override()
  -- Can be extended to restore original behavior
end

return M