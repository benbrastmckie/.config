-- Enhanced Utility Functions
-- Additional utility functions for Phase 7

local M = {}

-- Performance utilities
M.perf = {}

-- Measure function execution time
function M.perf.measure(fn, label)
  local start = vim.loop.hrtime()
  local result = {fn()}
  local duration = (vim.loop.hrtime() - start) / 1000000 -- ms
  
  if label then
    -- Lazy load logger to avoid circular dependencies
    local ok, logger = pcall(require, 'neotex.plugins.tools.himalaya.core.logger')
    if ok then
      logger.debug(string.format("Performance: %s took %.2fms", label, duration))
    end
  end
  
  return duration, unpack(result)
end

-- Benchmark function with multiple runs
function M.perf.benchmark(fn, iterations)
  iterations = iterations or 100
  local times = {}
  
  for i = 1, iterations do
    local duration = M.perf.measure(fn)
    table.insert(times, duration)
  end
  
  -- Calculate statistics
  table.sort(times)
  local sum = 0
  for _, time in ipairs(times) do
    sum = sum + time
  end
  
  return {
    min = times[1],
    max = times[#times],
    avg = sum / iterations,
    median = times[math.floor(#times / 2)],
    iterations = iterations
  }
end

-- String utilities
M.string = {}

-- Template string interpolation
function M.string.template(str, vars)
  return (str:gsub("${([^}]+)}", function(key)
    return tostring(vars[key] or "")
  end))
end

-- Truncate string with ellipsis
function M.string.truncate(str, max_len, ellipsis)
  ellipsis = ellipsis or "..."
  if #str <= max_len then
    return str
  end
  return str:sub(1, max_len - #ellipsis) .. ellipsis
end

-- Convert to human-readable size
function M.string.human_size(bytes)
  local units = {"B", "KB", "MB", "GB", "TB"}
  local unit = 1
  
  while bytes >= 1024 and unit < #units do
    bytes = bytes / 1024
    unit = unit + 1
  end
  
  return string.format("%.2f %s", bytes, units[unit])
end

-- Time ago formatter
function M.string.time_ago(timestamp)
  local now = os.time()
  local diff = now - timestamp
  
  if diff < 60 then
    return "just now"
  elseif diff < 3600 then
    local minutes = math.floor(diff / 60)
    return string.format("%d minute%s ago", minutes, minutes == 1 and "" or "s")
  elseif diff < 86400 then
    local hours = math.floor(diff / 3600)
    return string.format("%d hour%s ago", hours, hours == 1 and "" or "s")
  else
    local days = math.floor(diff / 86400)
    return string.format("%d day%s ago", days, days == 1 and "" or "s")
  end
end

-- Table utilities
M.table = {}

-- Deep merge tables
function M.table.deep_merge(t1, t2)
  local result = vim.deepcopy(t1)
  
  for k, v in pairs(t2) do
    if type(v) == "table" and type(result[k]) == "table" then
      result[k] = M.table.deep_merge(result[k], v)
    else
      result[k] = v
    end
  end
  
  return result
end

-- Filter table by predicate
function M.table.filter(tbl, predicate)
  local result = {}
  
  for k, v in pairs(tbl) do
    if predicate(v, k) then
      result[k] = v
    end
  end
  
  return result
end

-- Map table values
function M.table.map(tbl, mapper)
  local result = {}
  
  for k, v in pairs(tbl) do
    result[k] = mapper(v, k)
  end
  
  return result
end

-- Group by key
function M.table.group_by(tbl, key_fn)
  local result = {}
  
  for _, item in ipairs(tbl) do
    local key = key_fn(item)
    result[key] = result[key] or {}
    table.insert(result[key], item)
  end
  
  return result
end

-- Functional utilities
M.fn = {}

-- Debounce function
function M.fn.debounce(fn, delay)
  local timer = nil
  
  return function(...)
    local args = {...}
    
    if timer then
      vim.fn.timer_stop(timer)
    end
    
    timer = vim.fn.timer_start(delay, function()
      timer = nil
      fn(unpack(args))
    end)
  end
end

-- Throttle function
function M.fn.throttle(fn, delay)
  local last_call = 0
  local timer = nil
  
  return function(...)
    local now = vim.loop.now()
    local args = {...}
    
    if now - last_call >= delay then
      last_call = now
      fn(unpack(args))
    else
      -- Schedule for later
      if timer then
        vim.fn.timer_stop(timer)
      end
      
      local remaining = delay - (now - last_call)
      timer = vim.fn.timer_start(remaining, function()
        timer = nil
        last_call = vim.loop.now()
        fn(unpack(args))
      end)
    end
  end
end

-- Memoize function
function M.fn.memoize(fn)
  local cache = {}
  
  return function(...)
    local key = vim.inspect({...})
    
    if cache[key] == nil then
      cache[key] = {fn(...)}
    end
    
    return unpack(cache[key])
  end
end

-- Retry function with exponential backoff
function M.fn.retry(fn, options)
  options = options or {}
  local max_attempts = options.max_attempts or 3
  local initial_delay = options.initial_delay or 1000
  local max_delay = options.max_delay or 30000
  local multiplier = options.multiplier or 2
  
  return function(...)
    local args = {...}
    local delay = initial_delay
    
    for attempt = 1, max_attempts do
      local ok, result = pcall(fn, unpack(args))
      
      if ok then
        return result
      end
      
      if attempt < max_attempts then
        vim.wait(delay)
        delay = math.min(delay * multiplier, max_delay)
      else
        error(result)
      end
    end
  end
end

-- Async utilities
M.async = {}

-- Run function asynchronously
function M.async.run(fn, callback)
  vim.schedule(function()
    local ok, result = pcall(fn)
    if callback then
      callback(ok, result)
    end
  end)
end

-- Create promise-like object
function M.async.promise(executor)
  local state = "pending"
  local value = nil
  local callbacks = { resolve = {}, reject = {} }
  
  local promise = {}
  
  promise['then'] = function(self, on_resolve, on_reject)
    if state == "resolved" then
      if on_resolve then
        vim.schedule(function() on_resolve(value) end)
      end
    elseif state == "rejected" then
      if on_reject then
        vim.schedule(function() on_reject(value) end)
      end
    else
      if on_resolve then
        table.insert(callbacks.resolve, on_resolve)
      end
      if on_reject then
        table.insert(callbacks.reject, on_reject)
      end
    end
    
    return promise
  end
  
  local function resolve(val)
    if state ~= "pending" then return end
    
    state = "resolved"
    value = val
    
    for _, callback in ipairs(callbacks.resolve) do
      vim.schedule(function() callback(val) end)
    end
  end
  
  local function reject(err)
    if state ~= "pending" then return end
    
    state = "rejected"
    value = err
    
    for _, callback in ipairs(callbacks.reject) do
      vim.schedule(function() callback(err) end)
    end
  end
  
  -- Execute the function
  vim.schedule(function()
    local ok, err = pcall(executor, resolve, reject)
    if not ok then
      reject(err)
    end
  end)
  
  return promise
end

-- Path utilities
M.path = {}

-- Ensure directory exists
function M.path.ensure_dir(path)
  local dir = vim.fn.fnamemodify(path, ":h")
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
end

-- Get relative path
function M.path.relative(path, base)
  base = base or vim.fn.getcwd()
  
  -- Normalize paths
  path = vim.fn.fnamemodify(path, ":p")
  base = vim.fn.fnamemodify(base, ":p")
  
  -- Find common prefix
  local i = 1
  while i <= #path and i <= #base and path:sub(i, i) == base:sub(i, i) do
    i = i + 1
  end
  
  -- Build relative path
  local up_count = select(2, base:sub(i):gsub("/", ""))
  local rel_path = path:sub(i)
  
  if up_count > 0 then
    rel_path = string.rep("../", up_count) .. rel_path
  end
  
  return rel_path == "" and "." or rel_path
end

-- Validation utilities
M.validate = {}

-- Validate email address
function M.validate.email(email)
  return email:match("^[%w._%+-]+@[%w.-]+%.[%w]+$") ~= nil
end

-- Validate configuration
function M.validate.config(config, schema)
  local errors = {}
  
  for key, rules in pairs(schema) do
    local value = config[key]
    
    -- Required check
    if rules.required and value == nil then
      table.insert(errors, string.format("Missing required field: %s", key))
    end
    
    -- Type check
    if value ~= nil and rules.type and type(value) ~= rules.type then
      table.insert(errors, string.format("Invalid type for %s: expected %s, got %s",
        key, rules.type, type(value)))
    end
    
    -- Custom validator
    if value ~= nil and rules.validate then
      local ok, err = rules.validate(value)
      if not ok then
        table.insert(errors, string.format("Validation failed for %s: %s", key, err))
      end
    end
  end
  
  return #errors == 0, errors
end

return M