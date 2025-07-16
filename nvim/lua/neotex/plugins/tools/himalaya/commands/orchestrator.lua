-- Unified Command and Event Orchestration Layer
-- Combines command execution, error handling, logging, and event emission

local M = {}

local errors = require('neotex.plugins.tools.himalaya.core.errors')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local event_constants = require('neotex.plugins.tools.himalaya.core.events')

-- ========================================
-- Event Bus (from orchestration/events.lua)
-- ========================================

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

-- ========================================
-- Command Execution (original orchestrator)
-- ========================================

-- Command execution context
local CommandContext = {}
CommandContext.__index = CommandContext

function CommandContext:new(command_name, args)
  local ctx = {
    command = command_name,
    args = args or {},
    start_time = os.time(),
    metadata = {}
  }
  setmetatable(ctx, self)
  return ctx
end

function CommandContext:set(key, value)
  self.metadata[key] = value
end

function CommandContext:get(key)
  return self.metadata[key]
end

function CommandContext:duration()
  return os.time() - self.start_time
end

-- Main orchestration functions
function M.execute(command_name, handler, args)
  -- Create execution context
  local context = CommandContext:new(command_name, args)
  
  -- Emit command start event
  M.emit(event_constants.COMMAND_STARTED, {
    command = command_name,
    args = args,
    timestamp = context.start_time
  })
  
  -- Log command execution
  logger.debug("Executing command: " .. command_name, { args = args })
  
  -- Execute with error handling
  local success, result = pcall(handler, args)
  
  if success then
    -- Command succeeded
    M.emit(event_constants.COMMAND_COMPLETED, {
      command = command_name,
      duration = context:duration(),
      success = true
    })
    
    logger.debug("Command completed: " .. command_name, {
      duration = context:duration()
    })
    
    return true, result
  else
    -- Command failed
    local error_obj = errors.create_error(
      errors.types.COMMAND_FAILED,
      "Command " .. command_name .. " failed: " .. tostring(result),
      {
        command = command_name,
        error = result,
        severity = errors.severity.ERROR
      }
    )
    
    -- Handle the error
    errors.handle_error(error_obj)
    
    -- Emit failure event
    M.emit(event_constants.COMMAND_FAILED, {
      command = command_name,
      error = tostring(result),
      duration = context:duration()
    })
    
    return false, error_obj
  end
end

-- Wrap a command handler with orchestration
function M.wrap(command_name, handler)
  return function(args)
    return M.execute(command_name, handler, args)
  end
end

-- Create a command definition with orchestration
function M.create_command(name, handler, opts)
  return {
    fn = M.wrap(name, handler),
    opts = opts
  }
end

-- Batch execute commands
function M.execute_batch(commands)
  local results = {}
  
  for _, cmd in ipairs(commands) do
    local success, result = M.execute(cmd.name, cmd.handler, cmd.args)
    table.insert(results, {
      command = cmd.name,
      success = success,
      result = result
    })
  end
  
  return results
end

-- Execute command with pre/post hooks
function M.execute_with_hooks(command_name, handler, args, hooks)
  hooks = hooks or {}
  
  -- Pre-execution hook
  if hooks.before then
    local ok, err = pcall(hooks.before, args)
    if not ok then
      logger.error("Pre-hook failed for " .. command_name .. ": " .. tostring(err))
      return false, err
    end
  end
  
  -- Execute command
  local success, result = M.execute(command_name, handler, args)
  
  -- Post-execution hook
  if hooks.after then
    local ok, err = pcall(hooks.after, success, result)
    if not ok then
      logger.error("Post-hook failed for " .. command_name .. ": " .. tostring(err))
    end
  end
  
  return success, result
end

-- Execute command with retry logic
function M.execute_with_retry(command_name, handler, args, options)
  options = options or {}
  local max_retries = options.max_retries or 3
  local retry_delay = options.retry_delay or 1000 -- milliseconds
  
  for attempt = 1, max_retries do
    local success, result = M.execute(command_name, handler, args)
    
    if success then
      return true, result
    end
    
    -- Check if error is retryable
    if result and result.recoverable and attempt < max_retries then
      logger.info("Retrying command " .. command_name .. " (attempt " .. attempt .. "/" .. max_retries .. ")")
      vim.wait(retry_delay)
    else
      return false, result
    end
  end
  
  return false, "Max retries exceeded"
end

-- Command validation
function M.validate_args(command_name, args, schema)
  -- Simple validation for now
  if schema.required and #args == 0 then
    return false, "Command " .. command_name .. " requires arguments"
  end
  
  if schema.nargs then
    if schema.nargs == "0" and #args > 0 then
      return false, "Command " .. command_name .. " takes no arguments"
    elseif schema.nargs == "1" and #args ~= 1 then
      return false, "Command " .. command_name .. " requires exactly one argument"
    end
  end
  
  return true
end

-- ========================================
-- Event Integration (from integration.lua)
-- ========================================

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
      M.emit(before_event, data)
    end
    
    -- Execute original function
    local results = {fn(...)}
    
    -- Emit after event if successful
    if after_event and results[1] ~= false then -- Assuming first result indicates success
      local success_data = get_data and get_data(args, results) or data
      M.emit(after_event, success_data)
    end
    
    return unpack(results)
  end
end

-- Initialize event integration for main UI functions
function M.setup_integration()
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
  M.emit(event_constants.INIT_STARTED, {
    timestamp = os.time(),
    version = "Phase 4"
  })
  
  -- Set up completion event for later
  vim.defer_fn(function()
    M.emit(event_constants.INIT_COMPLETED, {
      timestamp = os.time(),
      version = "Phase 4"
    })
  end, 100) -- Small delay to ensure all initialization is complete
end

-- Register default event handlers for logging
function M.setup_default_handlers()
  -- Only log important events that users care about
  local user_events = {
    event_constants.EMAIL_SENT,
    event_constants.EMAIL_DELETED,
    event_constants.EMAIL_MOVED,
  }
  
  -- Log user-facing events at debug level
  for _, event_name in ipairs(user_events) do
    M.on(event_name, function(data)
      logger.debug(string.format("Event: %s", event_name), data)
    end, {
      priority = 10, -- Low priority for logging
      module = "event_integration"
    })
  end
  
  -- Add draft events logging (Phase 3)
  local draft_events = {
    event_constants.DRAFT_CREATED,
    event_constants.DRAFT_SAVED,
    event_constants.DRAFT_DELETED,
    event_constants.DRAFT_SYNCED,
    event_constants.DRAFT_SYNC_FAILED,
  }
  
  for _, event_name in ipairs(draft_events) do
    M.on(event_name, function(data)
      logger.debug(string.format("Draft Event: %s", event_name), data)
    end, {
      priority = 10,
      module = "draft_event_logger"
    })
  end
  
  -- Log sync events only for troubleshooting
  local sync_events = {
    event_constants.SYNC_REQUESTED,
    event_constants.SYNC_COMPLETED,
  }
  
  for _, event_name in ipairs(sync_events) do
    M.on(event_name, function(data)
      -- Only log sync events when they fail or when debug mode is on
      if data.success == false or logger.current_level <= logger.levels.DEBUG then
        logger.debug(string.format("Sync event: %s", event_name), data)
      end
    end, {
      priority = 10,
      module = "event_integration"
    })
  end
  
  -- Add handler to refresh email list when draft is saved
  M.on(event_constants.DRAFT_SAVED, function(data)
    local state = require('neotex.plugins.tools.himalaya.core.state')
    local current_folder = state.get_current_folder()
    
    -- Only refresh if we're currently viewing the drafts folder
    if current_folder and (current_folder == 'Drafts' or current_folder:lower():match('draft')) then
      -- Check if sidebar is actually open
      local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
      if sidebar.is_open() then
        -- Small delay to ensure filesystem changes are visible
        vim.defer_fn(function()
          local main = require('neotex.plugins.tools.himalaya.ui.main')
          main.refresh_email_list({ restore_insert_mode = false })
        end, 100)
      end
    end
  end, {
    priority = 50,
    module = "draft_ui_refresh"
  })
  
  -- Don't log init events - they're not useful to users
end

-- Combined setup function
function M.setup()
  M.setup_default_handlers()
  M.setup_integration()
end

return M