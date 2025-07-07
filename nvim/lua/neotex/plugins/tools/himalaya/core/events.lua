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

return M