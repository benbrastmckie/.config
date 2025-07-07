-- Event integration layer
-- Adds event emission alongside existing function calls without breaking changes

local M = {}

local events = require("neotex.plugins.tools.himalaya.orchestration.events")
local event_constants = require("neotex.plugins.tools.himalaya.core.events")

-- Wrap a function to emit events before and after execution
-- @param fn function: The original function to wrap
-- @param before_event string: Event to emit before function execution
-- @param after_event string: Event to emit after function execution (if successful)
-- @param get_data function?: Function to extract data from function arguments/results
function M.wrap_with_events(fn, before_event, after_event, get_data)
  return function(...)
    local args = {...}
    local data = get_data and get_data(args) or {}
    
    -- Emit before event
    if before_event then
      events.emit(before_event, data)
    end
    
    -- Execute original function
    local results = {fn(...)}
    
    -- Emit after event if successful
    if after_event and results[1] ~= false then -- Assuming first result indicates success
      local success_data = get_data and get_data(args, results) or data
      events.emit(after_event, success_data)
    end
    
    return unpack(results)
  end
end

-- Initialize event integration for main UI functions
function M.setup()
  local ui_main = require("neotex.plugins.tools.himalaya.ui.main")
  local sync_manager = require("neotex.plugins.tools.himalaya.sync.manager")
  
  -- Wrap key UI functions
  if ui_main.show_email_list then
    ui_main.show_email_list = M.wrap_with_events(
      ui_main.show_email_list,
      event_constants.UI_WINDOW_OPENED,
      event_constants.EMAIL_LIST_LOADED,
      function(args, results)
        return {
          folder = args[1] and args[1][1] or "INBOX",
          timestamp = os.time()
        }
      end
    )
  end
  
  if ui_main.compose_email then
    ui_main.compose_email = M.wrap_with_events(
      ui_main.compose_email,
      event_constants.UI_WINDOW_OPENED,
      nil, -- No after event for compose (sent separately)
      function(args)
        return {
          action = "compose",
          timestamp = os.time()
        }
      end
    )
  end
  
  if ui_main.send_current_email then
    ui_main.send_current_email = M.wrap_with_events(
      ui_main.send_current_email,
      nil, -- No before event
      event_constants.EMAIL_SENT,
      function(args, results)
        return {
          timestamp = os.time(),
          success = results and results[1] ~= false
        }
      end
    )
  end
  
  if ui_main.delete_current_email then
    ui_main.delete_current_email = M.wrap_with_events(
      ui_main.delete_current_email,
      nil,
      event_constants.EMAIL_DELETED,
      function(args, results)
        return {
          timestamp = os.time(),
          permanent = false -- Moved to trash
        }
      end
    )
  end
  
  if ui_main.move_email_to_folder then
    ui_main.move_email_to_folder = M.wrap_with_events(
      ui_main.move_email_to_folder,
      nil,
      event_constants.EMAIL_MOVED,
      function(args, results)
        return {
          folder = args[2], -- Second argument is usually the folder
          timestamp = os.time()
        }
      end
    )
  end
  
  -- Wrap sync functions
  if sync_manager.sync_all then
    sync_manager.sync_all = M.wrap_with_events(
      sync_manager.sync_all,
      event_constants.SYNC_REQUESTED,
      event_constants.SYNC_COMPLETED,
      function(args, results)
        return {
          timestamp = os.time(),
          success = results and results[1] ~= false
        }
      end
    )
  end
  
  -- Initialize lifecycle events (silent - no logging by default)
  events.emit(event_constants.INIT_STARTED, {
    timestamp = os.time(),
    version = "Phase 6"
  })
  
  -- Set up completion event for later
  vim.defer_fn(function()
    events.emit(event_constants.INIT_COMPLETED, {
      timestamp = os.time(),
      version = "Phase 6"
    })
  end, 100) -- Small delay to ensure all initialization is complete
end

-- Register some basic event handlers for logging
function M.setup_default_handlers()
  local logger = require("neotex.plugins.tools.himalaya.core.logger")
  
  -- Only log important events that users care about
  local user_events = {
    event_constants.EMAIL_SENT,
    event_constants.EMAIL_DELETED,
    event_constants.EMAIL_MOVED,
  }
  
  -- Log user-facing events at debug level
  for _, event_name in ipairs(user_events) do
    events.on(event_name, function(data)
      logger.debug(string.format("Event: %s", event_name), data)
    end, {
      priority = 10, -- Low priority for logging
      module = "event_integration"
    })
  end
  
  -- Log sync events only for troubleshooting
  local sync_events = {
    event_constants.SYNC_REQUESTED,
    event_constants.SYNC_COMPLETED,
  }
  
  for _, event_name in ipairs(sync_events) do
    events.on(event_name, function(data)
      -- Only log sync events when they fail or when debug mode is on
      if data.success == false or logger.current_level <= logger.levels.DEBUG then
        logger.debug(string.format("Sync event: %s", event_name), data)
      end
    end, {
      priority = 10,
      module = "event_integration"
    })
  end
  
  -- Don't log init events - they're not useful to users
end

return M