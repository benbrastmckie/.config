local M = {}

-- Lifecycle Events
M.INIT_STARTED = "himalaya:init:started"
M.INIT_COMPLETED = "himalaya:init:completed"

-- Account Management Events
M.ACCOUNT_ADDED = "account:added"
M.ACCOUNT_REMOVED = "account:removed"
M.ACCOUNT_SWITCHED = "account:switched"

-- Email Operation Events
M.EMAIL_LIST_REQUESTED = "email:list:requested"
M.EMAIL_LIST_LOADED = "email:list:loaded"
M.EMAIL_SELECTED = "email:selected"
M.EMAIL_OPENED = "email:opened"
M.EMAIL_SENT = "email:sent"
M.EMAIL_DELETED = "email:deleted"
M.EMAIL_MOVED = "email:moved"
M.EMAIL_SCHEDULED = "email:scheduled"
M.EMAIL_RESCHEDULED = "email:rescheduled"
M.EMAIL_CANCELLED = "email:cancelled"
M.EMAIL_SENDING = "email:sending"
M.EMAIL_SEND_FAILED = "email:send_failed"

-- Sync Operation Events
M.SYNC_REQUESTED = "sync:requested"
M.SYNC_STARTED = "sync:started"
M.SYNC_PROGRESS = "sync:progress"
M.SYNC_COMPLETED = "sync:completed"
M.SYNC_FAILED = "sync:failed"

-- UI Events
M.UI_REFRESH_REQUESTED = "ui:refresh:requested"
M.UI_WINDOW_OPENED = "ui:window:opened"
M.UI_WINDOW_CLOSED = "ui:window:closed"

-- Feature Events (for future phases)
M.SEARCH_REQUESTED = "search:requested"
M.SEARCH_COMPLETED = "search:completed"
M.TEMPLATE_APPLIED = "template:applied"
M.RULE_TRIGGERED = "rule:triggered"

-- Error events
M.ERROR_OCCURRED = "error:occurred"
M.ERROR_RECOVERED = "error:recovered"

-- Command events
M.COMMAND_STARTED = "command:started"
M.COMMAND_COMPLETED = "command:completed"
M.COMMAND_FAILED = "command:failed"

return M