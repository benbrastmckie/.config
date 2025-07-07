-- Command Orchestration Layer
-- Provides centralized command execution with error handling, logging, and event emission

local M = {}

local events = require('neotex.plugins.tools.himalaya.orchestration.events')
local errors = require('neotex.plugins.tools.himalaya.core.errors')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local event_constants = require('neotex.plugins.tools.himalaya.core.events')

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
  events.emit(event_constants.COMMAND_STARTED, {
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
    events.emit(event_constants.COMMAND_COMPLETED, {
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
    events.emit(event_constants.COMMAND_FAILED, {
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

return M