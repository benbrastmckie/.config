-- Structured logging module
-- Provides consistent logging with levels and formatting

local M = {}

-- Log levels
M.levels = {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
}

-- Current log level (can be configured)
M.current_level = M.levels.INFO

-- Log prefix
M.prefix = "[Himalaya]"

-- Get config for notification levels
local function get_notify_config()
  local config = require("neotex.plugins.tools.himalaya.core.config")
  return config.get("ui.notifications", { enabled = true, level = "info" })
end

-- Convert log level to vim.log.levels
local function to_vim_level(level)
  if level == M.levels.ERROR then
    return vim.log.levels.ERROR
  elseif level == M.levels.WARN then
    return vim.log.levels.WARN
  elseif level == M.levels.INFO then
    return vim.log.levels.INFO
  else
    return vim.log.levels.DEBUG
  end
end

-- Format log message
local function format_message(msg, context)
  local formatted = M.prefix .. " " .. msg
  
  if context then
    if type(context) == "table" then
      formatted = formatted .. " " .. vim.inspect(context)
    else
      formatted = formatted .. " " .. tostring(context)
    end
  end
  
  return formatted
end

-- Core log function
function M.log(level, msg, context)
  -- Check if we should log this level
  if level < M.current_level then
    return
  end
  
  local formatted = format_message(msg, context)
  local vim_level = to_vim_level(level)
  
  -- Check if notifications are enabled (but never notify debug messages)
  local notify_config = get_notify_config()
  if notify_config.enabled and level > M.levels.DEBUG then
    -- Only show notifications for configured level and above (excluding debug)
    local config_level = M.levels[notify_config.level:upper()] or M.levels.INFO
    if level >= config_level then
      vim.notify(formatted, vim_level)
    end
  end
  
  -- Always log to messages
  if level == M.levels.ERROR then
    vim.api.nvim_err_writeln(formatted)
  elseif level == M.levels.WARN then
    vim.api.nvim_echo({{formatted, "WarningMsg"}}, true, {})
  elseif level == M.levels.DEBUG then
    -- Debug messages go only to :messages, not as notifications
    vim.api.nvim_echo({{formatted, "Comment"}}, true, {})
  else
    vim.api.nvim_echo({{formatted, "Normal"}}, true, {})
  end
end

-- Convenience functions
function M.debug(msg, context)
  M.log(M.levels.DEBUG, msg, context)
end

function M.info(msg, context)
  M.log(M.levels.INFO, msg, context)
end

function M.warn(msg, context)
  M.log(M.levels.WARN, msg, context)
end

function M.error(msg, context)
  M.log(M.levels.ERROR, msg, context)
end

-- Set log level
function M.set_level(level)
  if type(level) == "string" then
    level = M.levels[level:upper()]
  end
  
  if level and level >= M.levels.DEBUG and level <= M.levels.ERROR then
    M.current_level = level
    M.info("Log level set to " .. M.get_level_name(level))
  end
end

-- Get current log level name
function M.get_level_name(level)
  level = level or M.current_level
  for name, value in pairs(M.levels) do
    if value == level then
      return name
    end
  end
  return "UNKNOWN"
end

-- Log with timing
function M.time(label, fn)
  local start = vim.loop.hrtime()
  local result = fn()
  local duration = (vim.loop.hrtime() - start) / 1000000 -- Convert to ms
  M.debug(string.format("%s took %.2fms", label, duration))
  return result
end

-- Setup logger
function M.setup(opts)
  opts = opts or {}
  
  if opts.level then
    M.set_level(opts.level)
  end
  
  if opts.prefix then
    M.prefix = opts.prefix
  end
end

-- Enable debug logging
function M.set_debug(enabled)
  if enabled then
    M.current_level = M.levels.DEBUG
  else
    M.current_level = M.levels.INFO
  end
end

-- Check if debug logging is enabled
function M.is_debug()
  return M.current_level == M.levels.DEBUG
end

return M