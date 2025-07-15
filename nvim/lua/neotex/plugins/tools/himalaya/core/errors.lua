local M = {}

-- Error type definitions
M.types = {
  -- Network errors
  NETWORK_ERROR = "network_error",
  CONNECTION_TIMEOUT = "connection_timeout",
  DNS_RESOLUTION_FAILED = "dns_resolution_failed",
  
  -- Authentication errors  
  AUTH_FAILED = "auth_failed",
  OAUTH_EXPIRED = "oauth_expired",
  OAUTH_REFRESH_FAILED = "oauth_refresh_failed",
  INVALID_CREDENTIALS = "invalid_credentials",
  TWO_FACTOR_REQUIRED = "two_factor_required",
  
  -- Command execution errors
  COMMAND_NOT_FOUND = "command_not_found",
  COMMAND_FAILED = "command_failed",
  INVALID_ARGUMENTS = "invalid_arguments",
  
  -- Email operation errors
  EMAIL_NOT_FOUND = "email_not_found",
  EMAIL_SEND_FAILED = "email_send_failed",
  EMAIL_PARSE_ERROR = "email_parse_error",
  ATTACHMENT_TOO_LARGE = "attachment_too_large",
  
  -- Sync errors
  SYNC_FAILED = "sync_failed",
  SYNC_CONFLICT = "sync_conflict",
  SYNC_IN_PROGRESS = "sync_in_progress",
  
  -- UI errors
  WINDOW_CREATION_FAILED = "window_creation_failed",
  INVALID_BUFFER = "invalid_buffer",
  UI_RENDER_ERROR = "ui_render_error",
  
  -- Configuration errors
  CONFIG_INVALID = "config_invalid",
  CONFIG_MISSING = "config_missing",
  ACCOUNT_NOT_FOUND = "account_not_found",
  
  -- State errors
  STATE_CORRUPTED = "state_corrupted",
  
  -- System errors
  PERMISSION_DENIED = "permission_denied",
  DISK_FULL = "disk_full",
  OUT_OF_MEMORY = "out_of_memory"
}

-- Error severity levels
M.severity = {
  FATAL = "fatal",      -- Unrecoverable, requires restart
  ERROR = "error",      -- Recoverable with user intervention  
  WARNING = "warning",  -- Degraded functionality
  INFO = "info"         -- Informational only
}

-- Create standardized error
function M.create_error(error_type, message, context)
  context = context or {}
  local error_info = {
    type = error_type,
    message = message,
    details = context.details or "",
    severity = context.severity or M.severity.ERROR,
    context = context,
    timestamp = os.time(),
    stack = debug.traceback("", 2),
    recoverable = context.recoverable ~= false,
    retry_count = context.retry_count or 0,
    suggestions = context.suggestions or {}
  }
  
  -- Add default suggestions based on error type
  if #error_info.suggestions == 0 then
    error_info.suggestions = M.get_default_suggestions(error_type)
  end
  
  return error_info
end

-- Get default suggestions for error types
function M.get_default_suggestions(error_type)
  local suggestions = {
    [M.types.OAUTH_EXPIRED] = {
      "Run :HimalayaSetup to refresh OAuth token",
      "Check if refresh token is still valid"
    },
    [M.types.CONNECTION_TIMEOUT] = {
      "Check your internet connection",
      "Verify firewall settings",
      "Try again in a few moments"
    },
    [M.types.CONFIG_INVALID] = {
      "Run :HimalayaSetup to reconfigure",
      "Check ~/.config/himalaya/config.toml"
    },
    [M.types.COMMAND_NOT_FOUND] = {
      "Install himalaya: cargo install himalaya",
      "Check if himalaya is in your PATH"
    },
    [M.types.AUTH_FAILED] = {
      "Check your email credentials",
      "Run :HimalayaSetup to update configuration"
    },
    [M.types.STATE_CORRUPTED] = {
      "State will be reset automatically",
      "Your emails will be re-synced"
    }
  }
  
  return suggestions[error_type] or {}
end

-- Recovery strategies
local recovery_strategies = {
  [M.types.OAUTH_EXPIRED] = function(error)
    local logger = require("neotex.plugins.tools.himalaya.core.logger")
    logger.info("Attempting OAuth token refresh")
    local oauth = require("neotex.plugins.tools.himalaya.sync.oauth")
    local success = oauth.refresh_token()
    
    if success then
      local notifications = require("neotex.plugins.tools.himalaya.ui.notifications")
      notifications.info("OAuth token refreshed successfully")
      return true
    end
    return false
  end,
  
  [M.types.CONNECTION_TIMEOUT] = function(error)
    if error.retry_count < 3 then
      local logger = require("neotex.plugins.tools.himalaya.core.logger")
      local delay = math.pow(2, error.retry_count) * 1000
      logger.info(string.format("Retrying after %dms", delay))
      
      vim.defer_fn(function()
        if error.context.retry_callback then
          error.context.retry_callback()
        end
      end, delay)
      return true
    end
    return false
  end,
  
  [M.types.STATE_CORRUPTED] = function(error)
    local logger = require("neotex.plugins.tools.himalaya.core.logger")
    logger.warn("Attempting to recover from corrupted state")
    local state = require("neotex.plugins.tools.himalaya.core.state")
    return state.reset_to_defaults()
  end
}

-- Handle error with recovery
function M.handle_error(error, custom_recovery)
  local logger = require("neotex.plugins.tools.himalaya.core.logger")
  local notifications = require("neotex.plugins.tools.himalaya.ui.notifications")
  
  -- Log error at debug level with technical details
  logger.debug(
    string.format("Error [%s]: %s", error.type, error.message),
    {
      details = error.details,
      stack = error.stack,
      recoverable = error.recoverable
    }
  )
  
  -- Try recovery strategy
  if error.recoverable then
    local recovery_fn = custom_recovery or recovery_strategies[error.type]
    if recovery_fn then
      local success = recovery_fn(error)
      if success then
        logger.info("Error recovery successful")
        return true
      end
    end
  end
  
  -- Only notify user for severe errors that they need to act on
  if error.severity == M.severity.FATAL or error.severity == M.severity.ERROR then
    local notify_msg = error.message
    if #error.suggestions > 0 then
      notify_msg = notify_msg .. "\n\nSuggestions:\n• " .. 
        table.concat(error.suggestions, "\n• ")
    end
    
    notifications.notify(notify_msg, "error")
  elseif error.severity == M.severity.WARNING then
    -- For warnings, only show in debug mode or when user explicitly requests
    logger.warn(string.format("Warning [%s]: %s", error.type, error.message))
  end
  -- INFO level errors are logged only (not shown to user)
  
  -- Return false to indicate error was not recovered
  return false
end

-- Wrap function with error handling
function M.wrap(fn, error_type, message)
  return function(...)
    local args = {...}
    local ok, result = pcall(fn, unpack(args))
    
    if not ok then
      local error = M.create_error(
        error_type or M.types.COMMAND_FAILED,
        message or "Operation failed",
        {
          details = tostring(result),
          recoverable = true
        }
      )
      M.handle_error(error)
      return nil, error
    end
    
    return result
  end
end

-- Assert with custom error
function M.assert(condition, error_type, message, context)
  if not condition then
    local error = M.create_error(error_type, message, context)
    M.handle_error(error)
    error(message)
  end
end

return M