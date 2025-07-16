-- Async Utilities for Himalaya
-- Asynchronous operations, debouncing, and coordination

local M = {}

local logger = require('neotex.plugins.tools.himalaya.core.logger')

-- Debounce function
function M.debounce(fn, delay)
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
function M.throttle(fn, delay)
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

-- Defer function execution
function M.defer(fn, delay)
  delay = delay or 0
  vim.defer_fn(fn, delay)
end

-- Schedule function execution
function M.schedule(fn)
  vim.schedule(fn)
end

-- Create a promise-like async function
function M.async(fn)
  return function(...)
    local args = {...}
    local co = coroutine.create(fn)
    
    local function step(...)
      local ok, result = coroutine.resume(co, ...)
      
      if not ok then
        logger.error('Async function error', { error = result })
      elseif coroutine.status(co) ~= 'dead' then
        -- Continue execution
        if type(result) == 'function' then
          result(step)
        else
          step(result)
        end
      end
    end
    
    step(unpack(args))
  end
end

-- Await async operation
function M.await(async_fn)
  return coroutine.yield(async_fn)
end

-- Run multiple async operations in parallel
function M.parallel(tasks, callback)
  local results = {}
  local completed = 0
  local total = #tasks
  
  if total == 0 then
    callback(results)
    return
  end
  
  for i, task in ipairs(tasks) do
    task(function(result)
      results[i] = result
      completed = completed + 1
      
      if completed == total then
        callback(results)
      end
    end)
  end
end

-- Run async operations in sequence
function M.series(tasks, callback)
  local results = {}
  local index = 1
  
  local function next()
    if index > #tasks then
      callback(results)
      return
    end
    
    local task = tasks[index]
    task(function(result)
      results[index] = result
      index = index + 1
      next()
    end)
  end
  
  next()
end

-- Create a rate limiter
function M.rate_limit(fn, limit, window)
  local calls = {}
  window = window or 1000 -- Default 1 second window
  
  return function(...)
    local now = vim.loop.now()
    local args = {...}
    
    -- Remove old calls outside window
    local valid_calls = {}
    for _, timestamp in ipairs(calls) do
      if now - timestamp < window then
        table.insert(valid_calls, timestamp)
      end
    end
    calls = valid_calls
    
    -- Check if we can make a call
    if #calls < limit then
      table.insert(calls, now)
      return fn(unpack(args))
    else
      -- Rate limited
      logger.debug('Rate limited', { 
        calls = #calls, 
        limit = limit,
        window = window 
      })
      return nil, 'Rate limited'
    end
  end
end

-- Retry function with exponential backoff
function M.retry(fn, options)
  options = options or {}
  local max_retries = options.max_retries or 3
  local initial_delay = options.initial_delay or 1000
  local max_delay = options.max_delay or 30000
  local multiplier = options.multiplier or 2
  
  return function(...)
    local args = {...}
    local attempt = 0
    local delay = initial_delay
    
    local function try()
      attempt = attempt + 1
      
      local ok, result = pcall(fn, unpack(args))
      
      if ok then
        return result
      elseif attempt < max_retries then
        logger.debug('Retrying after error', {
          attempt = attempt,
          max_retries = max_retries,
          delay = delay,
          error = result
        })
        
        vim.defer_fn(try, delay)
        
        -- Exponential backoff
        delay = math.min(delay * multiplier, max_delay)
      else
        logger.error('Max retries exceeded', {
          attempts = attempt,
          error = result
        })
        error(result)
      end
    end
    
    return try()
  end
end

-- Create a timeout wrapper
function M.timeout(fn, ms)
  return function(...)
    local args = {...}
    local completed = false
    local timer = nil
    
    -- Set timeout
    timer = vim.fn.timer_start(ms, function()
      if not completed then
        completed = true
        error('Operation timed out after ' .. ms .. 'ms')
      end
    end)
    
    -- Execute function
    local results = {pcall(fn, unpack(args))}
    completed = true
    
    -- Cancel timer
    if timer then
      vim.fn.timer_stop(timer)
    end
    
    -- Return results
    if results[1] then
      return unpack(results, 2)
    else
      error(results[2])
    end
  end
end

-- Batch operations
function M.batch(fn, batch_size, delay)
  local queue = {}
  local timer = nil
  
  local function process_batch()
    if #queue == 0 then return end
    
    local batch = {}
    for i = 1, math.min(batch_size, #queue) do
      table.insert(batch, table.remove(queue, 1))
    end
    
    fn(batch)
    
    -- Schedule next batch if needed
    if #queue > 0 then
      timer = vim.fn.timer_start(delay or 0, process_batch)
    else
      timer = nil
    end
  end
  
  return function(item)
    table.insert(queue, item)
    
    if not timer then
      timer = vim.fn.timer_start(delay or 0, process_batch)
    end
  end
end

-- Create a worker pool
function M.worker_pool(worker_fn, pool_size)
  local queue = {}
  local workers = {}
  local busy_count = 0
  
  pool_size = pool_size or 4
  
  local function process_next()
    if #queue == 0 or busy_count >= pool_size then
      return
    end
    
    local task = table.remove(queue, 1)
    busy_count = busy_count + 1
    
    worker_fn(task, function(...)
      busy_count = busy_count - 1
      
      if task.callback then
        task.callback(...)
      end
      
      -- Process next item
      process_next()
    end)
  end
  
  return {
    add = function(data, callback)
      table.insert(queue, {
        data = data,
        callback = callback
      })
      process_next()
    end,
    
    size = function()
      return #queue
    end,
    
    busy = function()
      return busy_count
    end
  }
end

return M