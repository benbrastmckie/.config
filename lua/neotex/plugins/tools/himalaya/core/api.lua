-- API Consistency Layer
-- Provides standardized API patterns and response formats

local M = {}

local logger = require('neotex.plugins.tools.himalaya.core.logger')
local errors = require('neotex.plugins.tools.himalaya.core.errors')

-- Standard API response format
local ApiResponse = {}
ApiResponse.__index = ApiResponse

function ApiResponse:new()
  local response = {
    success = false,
    data = nil,
    error = nil,
    metadata = {}
  }
  setmetatable(response, self)
  return response
end

function ApiResponse:ok(data, metadata)
  self.success = true
  self.data = data
  self.metadata = metadata or {}
  return self
end

function ApiResponse:fail(error, metadata)
  self.success = false
  self.error = error
  self.metadata = metadata or {}
  return self
end

-- Create standard responses
function M.success(data, metadata)
  return ApiResponse:new():ok(data, metadata)
end

function M.error(error_msg, error_type, metadata)
  local error_obj = {
    message = error_msg,
    type = error_type or errors.types.UNKNOWN_ERROR,
    timestamp = os.time()
  }
  return ApiResponse:new():fail(error_obj, metadata)
end

-- Standard API wrapper for consistent error handling
function M.wrap(fn, options)
  options = options or {}
  
  return function(...)
    local args = {...}
    
    -- Log API call
    if options.log_calls then
      logger.debug("API call: " .. (options.name or "unknown"), { args = args })
    end
    
    -- Execute with error handling
    local ok, result = pcall(fn, ...)
    
    if ok then
      -- Function succeeded
      if type(result) == "table" and result.success ~= nil then
        -- Already an API response
        return result
      else
        -- Wrap in standard response
        return M.success(result)
      end
    else
      -- Function failed
      local error_type = options.error_type or errors.types.UNKNOWN_ERROR
      local error_msg = tostring(result)
      
      -- Log error
      logger.error("API error in " .. (options.name or "unknown") .. ": " .. error_msg)
      
      -- Return standard error response
      return M.error(error_msg, error_type)
    end
  end
end

-- Validate API parameters
function M.validate_params(params, schema)
  for field, rules in pairs(schema) do
    local value = params[field]
    
    -- Check required fields
    if rules.required and value == nil then
      return false, "Missing required field: " .. field
    end
    
    -- Check type
    if value ~= nil and rules.type then
      local value_type = type(value)
      if value_type ~= rules.type then
        return false, string.format("Invalid type for %s: expected %s, got %s", 
          field, rules.type, value_type)
      end
    end
    
    -- Check enum values
    if value ~= nil and rules.enum then
      local valid = false
      for _, allowed in ipairs(rules.enum) do
        if value == allowed then
          valid = true
          break
        end
      end
      if not valid then
        return false, string.format("Invalid value for %s: %s", field, tostring(value))
      end
    end
    
    -- Custom validation
    if value ~= nil and rules.validate then
      local ok, err = rules.validate(value)
      if not ok then
        return false, string.format("Validation failed for %s: %s", field, err)
      end
    end
  end
  
  return true
end

-- Create API endpoint with validation
function M.create_endpoint(name, handler, schema)
  return M.wrap(function(params)
    -- Validate parameters if schema provided
    if schema then
      local valid, err = M.validate_params(params, schema)
      if not valid then
        return M.error(err, errors.types.INVALID_ARGUMENTS)
      end
    end
    
    -- Execute handler
    return handler(params)
  end, { name = name, log_calls = true })
end

-- Batch API operations
function M.batch(operations)
  local results = {}
  local all_success = true
  
  for i, op in ipairs(operations) do
    local result = op()
    results[i] = result
    
    if not result.success then
      all_success = false
    end
  end
  
  return {
    success = all_success,
    results = results,
    metadata = {
      total = #operations,
      succeeded = vim.tbl_count(vim.tbl_filter(function(r) return r.success end, results)),
      failed = vim.tbl_count(vim.tbl_filter(function(r) return not r.success end, results))
    }
  }
end

-- Async API wrapper
function M.async(fn, callback)
  return function(...)
    local args = {...}
    
    vim.schedule(function()
      local result = fn(unpack(args))
      if callback then
        callback(result)
      end
    end)
  end
end

-- Rate limiting wrapper
local rate_limiters = {}

function M.rate_limit(fn, options)
  options = options or {}
  local key = options.key or tostring(fn)
  local limit = options.limit or 10
  local window = options.window or 60000 -- 1 minute default
  
  -- Initialize rate limiter
  if not rate_limiters[key] then
    rate_limiters[key] = {
      calls = {},
      limit = limit,
      window = window
    }
  end
  
  return function(...)
    local limiter = rate_limiters[key]
    local now = vim.loop.now()
    
    -- Clean old calls
    limiter.calls = vim.tbl_filter(function(timestamp)
      return now - timestamp < limiter.window
    end, limiter.calls)
    
    -- Check rate limit
    if #limiter.calls >= limiter.limit then
      return M.error("Rate limit exceeded", "RATE_LIMIT_EXCEEDED", {
        limit = limiter.limit,
        window = limiter.window,
        retry_after = limiter.window - (now - limiter.calls[1])
      })
    end
    
    -- Record call and execute
    table.insert(limiter.calls, now)
    return fn(...)
  end
end

-- Cache wrapper
local cache = {}

function M.cached(fn, options)
  options = options or {}
  local key_fn = options.key_fn or function(...) return vim.inspect({...}) end
  local ttl = options.ttl or 300000 -- 5 minutes default
  
  return function(...)
    local key = key_fn(...)
    local now = vim.loop.now()
    
    -- Check cache
    if cache[key] and now - cache[key].timestamp < ttl then
      return cache[key].value
    end
    
    -- Execute and cache
    local result = fn(...)
    cache[key] = {
      value = result,
      timestamp = now
    }
    
    return result
  end
end

-- Clear cache
function M.clear_cache(pattern)
  if pattern then
    for key in pairs(cache) do
      if key:match(pattern) then
        cache[key] = nil
      end
    end
  else
    cache = {}
  end
end

return M