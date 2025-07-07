local M = {}

-- Event handlers storage
-- Structure: { event_name = { {handler = fn, priority = num, module = str}, ... } }
local handlers = {}

-- Register an event handler
-- @param event string: Event name to listen for
-- @param handler function: Function to call when event is emitted
-- @param options table?: Optional table with priority (default 50) and module name
function M.on(event, handler, options)
  options = options or {}
  local priority = options.priority or 50
  local module_name = options.module or "unknown"
  
  -- Initialize event handlers list if needed
  if not handlers[event] then
    handlers[event] = {}
  end
  
  -- Add handler with metadata
  table.insert(handlers[event], {
    handler = handler,
    priority = priority,
    module = module_name
  })
  
  -- Sort handlers by priority (higher priority runs first)
  table.sort(handlers[event], function(a, b)
    return a.priority > b.priority
  end)
end

-- Emit an event to all registered handlers
-- @param event string: Event name to emit
-- @param data any: Data to pass to handlers
function M.emit(event, data)
  local event_handlers = handlers[event]
  if not event_handlers then
    return
  end
  
  -- Execute each handler in priority order
  for _, handler_info in ipairs(event_handlers) do
    local ok, err = pcall(handler_info.handler, data)
    if not ok then
      -- Report error without breaking the event chain
      local notifications = require("neotex.plugins.tools.himalaya.ui.notifications")
      notifications.error(string.format(
        "Event handler error in %s for event '%s': %s",
        handler_info.module,
        event,
        err
      ))
    end
  end
end

-- Remove all handlers for a specific event (useful for testing)
-- @param event string: Event name to clear handlers for
function M.off(event)
  handlers[event] = nil
end

-- Remove all event handlers (useful for testing)
function M.clear()
  handlers = {}
end

-- Get handler count for an event (useful for debugging)
-- @param event string: Event name to check
-- @return number: Number of registered handlers
function M.handler_count(event)
  return handlers[event] and #handlers[event] or 0
end

return M