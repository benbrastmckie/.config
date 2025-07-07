-- Enhanced Structured Logging Module
-- Provides structured logging with context, filtering, and handlers

local M = {}

-- Log levels
M.levels = {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
}

-- Current configuration
M.config = {
  level = M.levels.INFO,
  prefix = "[Himalaya]",
  structured = true,
  handlers = {},
  filters = {},
  buffer_size = 1000,
  persist = false
}

-- Log buffer for recent messages
M.buffer = {}

-- Log entry structure
local LogEntry = {}
LogEntry.__index = LogEntry

function LogEntry:new(level, module, message, context)
  local entry = {
    timestamp = os.time(),
    level = level,
    module = module or "core",
    message = message,
    context = context or {},
    id = vim.loop.hrtime()
  }
  setmetatable(entry, self)
  return entry
end

function LogEntry:format(format_type)
  format_type = format_type or "default"
  
  if format_type == "json" then
    return vim.fn.json_encode({
      timestamp = self.timestamp,
      level = M.get_level_name(self.level),
      module = self.module,
      message = self.message,
      context = self.context
    })
  elseif format_type == "compact" then
    return string.format("[%s] %s: %s",
      M.get_level_name(self.level),
      self.module,
      self.message
    )
  else -- default
    local time_str = os.date("%H:%M:%S", self.timestamp)
    return string.format("%s [%s] %s - %s",
      time_str,
      M.get_level_name(self.level),
      self.module,
      self.message
    )
  end
end

-- Log handlers
M.handlers = {
  -- Console handler (vim.notify)
  console = function(entry)
    local notify = require('neotex.util.notifications')
    
    -- Map log levels to notification categories
    local category_map = {
      [M.levels.ERROR] = notify.categories.ERROR,
      [M.levels.WARN] = notify.categories.WARNING,
      [M.levels.INFO] = notify.categories.STATUS,
      [M.levels.DEBUG] = notify.categories.BACKGROUND
    }
    
    local category = category_map[entry.level] or notify.categories.STATUS
    
    -- Only show in appropriate modes
    if entry.level >= M.levels.ERROR or
       (entry.level >= M.levels.WARN and notify.config.modules.himalaya.debug_mode) or
       (entry.level < M.levels.WARN and notify.config.modules.himalaya.debug_mode) then
      notify.himalaya(entry.message, category)
    end
  end,
  
  -- Buffer handler (stores in memory)
  buffer = function(entry)
    table.insert(M.buffer, entry)
    
    -- Trim buffer if too large
    if #M.buffer > M.config.buffer_size then
      table.remove(M.buffer, 1)
    end
  end,
  
  -- File handler (append to log file)
  file = function(entry)
    if M.config.persist then
      local log_file = vim.fn.stdpath('data') .. '/himalaya.log'
      local file = io.open(log_file, 'a')
      if file then
        file:write(entry:format('json') .. '\n')
        file:close()
      end
    end
  end
}

-- Add custom handler
function M.add_handler(name, handler)
  M.handlers[name] = handler
end

-- Remove handler
function M.remove_handler(name)
  M.handlers[name] = nil
end

-- Log filters
M.filters = {
  -- Module filter
  module = function(entry, allowed_modules)
    for _, module in ipairs(allowed_modules) do
      if entry.module == module or entry.module:match("^" .. module) then
        return true
      end
    end
    return false
  end,
  
  -- Level filter
  level = function(entry, min_level)
    return entry.level >= min_level
  end,
  
  -- Time range filter
  time_range = function(entry, start_time, end_time)
    return entry.timestamp >= start_time and entry.timestamp <= end_time
  end
}

-- Core logging function
function M.log(level, module, message, context)
  -- Check global level filter
  if level < M.config.level then
    return
  end
  
  -- Create log entry
  local entry = LogEntry:new(level, module, message, context)
  
  -- Apply filters
  for name, filter in pairs(M.config.filters) do
    if not filter(entry) then
      return
    end
  end
  
  -- Send to handlers
  for name, handler in pairs(M.handlers) do
    local ok, err = pcall(handler, entry)
    if not ok then
      vim.notify("Logger handler " .. name .. " failed: " .. tostring(err), vim.log.levels.ERROR)
    end
  end
end

-- Module-specific logger
function M.get_logger(module_name)
  local logger = {}
  
  function logger.debug(msg, context)
    M.log(M.levels.DEBUG, module_name, msg, context)
  end
  
  function logger.info(msg, context)
    M.log(M.levels.INFO, module_name, msg, context)
  end
  
  function logger.warn(msg, context)
    M.log(M.levels.WARN, module_name, msg, context)
  end
  
  function logger.error(msg, context)
    M.log(M.levels.ERROR, module_name, msg, context)
  end
  
  function logger.time(label, fn)
    local start = vim.loop.hrtime()
    local result = fn()
    local duration = (vim.loop.hrtime() - start) / 1000000
    logger.debug(string.format("%s took %.2fms", label, duration), { duration_ms = duration })
    return result
  end
  
  return logger
end

-- Convenience functions for backward compatibility
function M.debug(msg, context)
  M.log(M.levels.DEBUG, "core", msg, context)
end

function M.info(msg, context)
  M.log(M.levels.INFO, "core", msg, context)
end

function M.warn(msg, context)
  M.log(M.levels.WARN, "core", msg, context)
end

function M.error(msg, context)
  M.log(M.levels.ERROR, "core", msg, context)
end

-- Get level name
function M.get_level_name(level)
  for name, value in pairs(M.levels) do
    if value == level then
      return name
    end
  end
  return "UNKNOWN"
end

-- Set log level
function M.set_level(level)
  if type(level) == "string" then
    level = M.levels[level:upper()]
  end
  
  if level and level >= M.levels.DEBUG and level <= M.levels.ERROR then
    M.config.level = level
  end
end

-- Query log buffer
function M.query(filter_fn)
  if not filter_fn then
    return M.buffer
  end
  
  local results = {}
  for _, entry in ipairs(M.buffer) do
    if filter_fn(entry) then
      table.insert(results, entry)
    end
  end
  return results
end

-- Clear log buffer
function M.clear_buffer()
  M.buffer = {}
end

-- Export logs
function M.export(format, filter_fn)
  local entries = M.query(filter_fn)
  local lines = {}
  
  for _, entry in ipairs(entries) do
    table.insert(lines, entry:format(format))
  end
  
  return table.concat(lines, "\n")
end

-- Show logs in floating window
function M.show_logs(filter_fn)
  local float = require('neotex.plugins.tools.himalaya.ui.float')
  local entries = M.query(filter_fn)
  local lines = {}
  
  for _, entry in ipairs(entries) do
    table.insert(lines, entry:format("default"))
  end
  
  float.show('Himalaya Logs', lines)
end

-- Setup
function M.setup(opts)
  opts = opts or {}
  
  -- Merge configuration
  M.config = vim.tbl_deep_extend("force", M.config, opts)
  
  -- Setup default handlers
  M.handlers.console = M.handlers.console
  M.handlers.buffer = M.handlers.buffer
  
  if M.config.persist then
    M.handlers.file = M.handlers.file
  end
end

-- Timing helper
function M.time(label, fn)
  local start = vim.loop.hrtime()
  local result = fn()
  local duration = (vim.loop.hrtime() - start) / 1000000
  M.debug(string.format("%s took %.2fms", label, duration), { duration_ms = duration })
  return result
end

-- Enable/disable debug mode
function M.set_debug(enabled)
  M.config.level = enabled and M.levels.DEBUG or M.levels.INFO
end

-- Check if debug is enabled
function M.is_debug()
  return M.config.level == M.levels.DEBUG
end

-- Add backward compatibility
M.prefix = "[Himalaya]"
M.level = M.config.level
M.current_level = M.config.level

return M