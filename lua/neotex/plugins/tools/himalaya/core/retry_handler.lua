-- Retry Handler for Failed Operations
-- Provides exponential backoff and retry logic for network operations
--
-- This module ensures operations are retried intelligently when they fail
-- due to transient issues like network failures or temporary locks.

local M = {}

-- Dependencies
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local notify = require('neotex.util.notifications')

-- Configuration
M.config = {
  max_retries = 3,
  base_delay = 1000,      -- 1 second
  max_delay = 30000,      -- 30 seconds
  exponential_base = 2,
  jitter = true           -- Add random jitter to prevent thundering herd
}

-- Calculate delay with exponential backoff
local function calculate_delay(attempt)
  local delay = M.config.base_delay * math.pow(M.config.exponential_base, attempt - 1)
  delay = math.min(delay, M.config.max_delay)
  
  -- Add jitter (±25%)
  if M.config.jitter then
    local jitter = delay * 0.25
    delay = delay + (math.random() * jitter * 2 - jitter)
  end
  
  return math.floor(delay)
end

-- Check if error is retryable
local function is_retryable_error(error_msg)
  if not error_msg then return false end
  
  local retryable_patterns = {
    -- Network errors
    'network', 'connection', 'timeout', 'unreachable',
    -- Lock errors
    'lock', 'locked', 'Resource temporarily unavailable',
    'cannot acquire lock', 'database is locked',
    -- Temporary failures
    'temporary', 'try again', 'retry',
    -- ID mapper conflicts
    'cannot open id mapper database',
    -- Mail server errors
    'IMAP', 'SMTP', 'authentication'
  }
  
  local error_lower = error_msg:lower()
  for _, pattern in ipairs(retryable_patterns) do
    if error_lower:match(pattern:lower()) then
      return true
    end
  end
  
  return false
end

-- Retry a function with exponential backoff
function M.retry(fn, options)
  options = options or {}
  local max_retries = options.max_retries or M.config.max_retries
  local operation_name = options.name or 'operation'
  local on_retry = options.on_retry
  local check_retryable = options.check_retryable or is_retryable_error
  
  local attempt = 0
  local last_error = nil
  
  while attempt < max_retries do
    attempt = attempt + 1
    
    logger.debug('Attempting ' .. operation_name, {
      attempt = attempt,
      max_retries = max_retries
    })
    
    -- Try the operation
    local ok, result = pcall(fn)
    
    if ok and result ~= nil and result ~= false then
      -- Success!
      if attempt > 1 then
        logger.info(operation_name .. ' succeeded after retry', {
          attempt = attempt
        })
      end
      return true, result
    end
    
    -- Operation failed
    last_error = not ok and tostring(result) or 'Operation returned false/nil'
    
    -- Check if error is retryable
    if not check_retryable(last_error) then
      logger.debug('Non-retryable error for ' .. operation_name, {
        error = last_error
      })
      break
    end
    
    -- Don't retry if we've exhausted attempts
    if attempt >= max_retries then
      break
    end
    
    -- Calculate delay
    local delay = calculate_delay(attempt)
    
    logger.warn(operation_name .. ' failed, will retry', {
      attempt = attempt,
      max_retries = max_retries,
      delay_ms = delay,
      error = last_error
    })
    
    -- Call retry callback if provided
    if on_retry then
      on_retry(attempt, delay, last_error)
    end
    
    -- Wait before retry
    vim.wait(delay)
  end
  
  -- All retries exhausted
  logger.error(operation_name .. ' failed after all retries', {
    attempts = attempt,
    last_error = last_error
  })
  
  return false, last_error
end

-- Retry async operation with vim.defer_fn
function M.retry_async(fn, options, callback)
  options = options or {}
  local max_retries = options.max_retries or M.config.max_retries
  local operation_name = options.name or 'async operation'
  local check_retryable = options.check_retryable or is_retryable_error
  
  local attempt = 0
  
  local function try_once()
    attempt = attempt + 1
    
    logger.debug('Attempting ' .. operation_name, {
      attempt = attempt,
      max_retries = max_retries
    })
    
    -- Try the operation
    local ok, result = pcall(fn)
    
    if ok and result ~= nil and result ~= false then
      -- Success!
      if attempt > 1 then
        logger.info(operation_name .. ' succeeded after retry', {
          attempt = attempt
        })
      end
      if callback then
        callback(true, result)
      end
      return
    end
    
    -- Operation failed
    local error_msg = not ok and tostring(result) or 'Operation returned false/nil'
    
    -- Check if error is retryable and we have attempts left
    if attempt < max_retries and check_retryable(error_msg) then
      local delay = calculate_delay(attempt)
      
      logger.warn(operation_name .. ' failed, scheduling retry', {
        attempt = attempt,
        max_retries = max_retries,
        delay_ms = delay,
        error = error_msg
      })
      
      -- Schedule retry
      vim.defer_fn(try_once, delay)
    else
      -- No more retries
      logger.error(operation_name .. ' failed after all retries', {
        attempts = attempt,
        error = error_msg
      })
      
      if callback then
        callback(false, error_msg)
      end
    end
  end
  
  -- Start first attempt
  try_once()
end

-- Convenience function for retrying himalaya operations
function M.retry_himalaya(fn, operation_name)
  return M.retry(fn, {
    name = operation_name or 'himalaya operation',
    check_retryable = function(error_msg)
      -- Always retry himalaya operations that might have lock conflicts
      if error_msg:match('cannot open id mapper database') or
         error_msg:match('Resource temporarily unavailable') then
        return true
      end
      return is_retryable_error(error_msg)
    end,
    on_retry = function(attempt, delay, error_msg)
      -- Show user notification on retry
      if attempt == 2 then  -- Only show on second attempt
        notify.himalaya(
          string.format('Retrying %s...', operation_name or 'operation'),
          notify.categories.STATUS
        )
      end
    end
  })
end

-- Test retry functionality
function M.test_retry()
  local attempts = 0
  
  -- Test successful retry
  local ok, result = M.retry(function()
    attempts = attempts + 1
    if attempts < 3 then
      error("Network timeout")
    end
    return "Success!"
  end, { name = "test operation" })
  
  print(string.format("Test 1: ok=%s, result=%s, attempts=%d", 
    tostring(ok), tostring(result), attempts))
  
  -- Test non-retryable error
  attempts = 0
  ok, result = M.retry(function()
    attempts = attempts + 1
    error("Permission denied")
  end, { name = "test operation 2" })
  
  print(string.format("Test 2: ok=%s, attempts=%d (should be 1)", 
    tostring(ok), attempts))
end

return M