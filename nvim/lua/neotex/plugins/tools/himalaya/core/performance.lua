-- Performance Optimization Module for Himalaya
-- Provides caching, lazy loading, and performance monitoring

local M = {}

-- Dependencies
local logger = require('neotex.plugins.tools.himalaya.core.logger')

-- Performance metrics storage
M.metrics = {
  operations = {},
  cache_hits = 0,
  cache_misses = 0,
  average_times = {}
}

-- Start timing an operation
function M.start_timer(operation_name)
  local timer = {
    name = operation_name,
    start = vim.loop.hrtime()
  }
  return timer
end

-- End timing and record metrics
function M.end_timer(timer)
  if not timer or not timer.start then return end
  
  local duration = (vim.loop.hrtime() - timer.start) / 1e6 -- Convert to ms
  
  -- Store in operations list
  if not M.metrics.operations[timer.name] then
    M.metrics.operations[timer.name] = {
      count = 0,
      total_time = 0,
      min_time = math.huge,
      max_time = 0
    }
  end
  
  local op = M.metrics.operations[timer.name]
  op.count = op.count + 1
  op.total_time = op.total_time + duration
  op.min_time = math.min(op.min_time, duration)
  op.max_time = math.max(op.max_time, duration)
  
  -- Update average
  M.metrics.average_times[timer.name] = op.total_time / op.count
  
  -- Log slow operations
  if duration > 1000 then -- Over 1 second
    logger.warn('Slow operation detected', {
      operation = timer.name,
      duration_ms = duration
    })
  end
  
  return duration
end

-- Lazy loading wrapper
function M.lazy_require(module_name)
  local module = nil
  return setmetatable({}, {
    __index = function(_, key)
      if not module then
        logger.debug('Lazy loading module', { module = module_name })
        module = require(module_name)
      end
      return module[key]
    end
  })
end

-- Memoization helper
function M.memoize(fn, cache_key_fn)
  local cache = {}
  cache_key_fn = cache_key_fn or function(...) 
    return table.concat({...}, '|')
  end
  
  return function(...)
    local key = cache_key_fn(...)
    if cache[key] ~= nil then
      M.metrics.cache_hits = M.metrics.cache_hits + 1
      return cache[key]
    end
    
    M.metrics.cache_misses = M.metrics.cache_misses + 1
    local result = fn(...)
    cache[key] = result
    return result
  end
end

-- Batch operations helper
function M.batch_operations(operations, batch_size)
  batch_size = batch_size or 10
  local results = {}
  
  for i = 1, #operations, batch_size do
    local batch = {}
    for j = i, math.min(i + batch_size - 1, #operations) do
      table.insert(batch, operations[j])
    end
    
    -- Process batch
    for _, op in ipairs(batch) do
      local ok, result = pcall(op)
      if ok then
        table.insert(results, result)
      else
        logger.error('Batch operation failed', { error = result })
      end
    end
    
    -- Yield to prevent blocking
    if i + batch_size <= #operations then
      vim.wait(0)
    end
  end
  
  return results
end

-- Debounce function calls
function M.debounce(fn, delay_ms)
  local timer = nil
  return function(...)
    local args = {...}
    if timer then
      timer:stop()
    end
    timer = vim.loop.new_timer()
    timer:start(delay_ms, 0, vim.schedule_wrap(function()
      timer:stop()
      timer:close()
      timer = nil
      fn(unpack(args))
    end))
  end
end

-- Throttle function calls
function M.throttle(fn, interval_ms)
  local last_call = 0
  local scheduled = false
  
  return function(...)
    local now = vim.loop.hrtime() / 1e6
    local args = {...}
    
    if now - last_call >= interval_ms then
      last_call = now
      fn(unpack(args))
      scheduled = false
    elseif not scheduled then
      scheduled = true
      vim.defer_fn(function()
        last_call = vim.loop.hrtime() / 1e6
        fn(unpack(args))
        scheduled = false
      end, interval_ms - (now - last_call))
    end
  end
end

-- Cache with TTL
function M.create_ttl_cache(ttl_ms)
  local cache = {}
  
  return {
    get = function(key)
      local entry = cache[key]
      if entry then
        if vim.loop.hrtime() / 1e6 - entry.time < ttl_ms then
          M.metrics.cache_hits = M.metrics.cache_hits + 1
          return entry.value
        else
          cache[key] = nil
        end
      end
      M.metrics.cache_misses = M.metrics.cache_misses + 1
      return nil
    end,
    
    set = function(key, value)
      cache[key] = {
        value = value,
        time = vim.loop.hrtime() / 1e6
      }
    end,
    
    clear = function()
      cache = {}
    end,
    
    cleanup = function()
      local now = vim.loop.hrtime() / 1e6
      for key, entry in pairs(cache) do
        if now - entry.time >= ttl_ms then
          cache[key] = nil
        end
      end
    end
  }
end

-- Get performance report
function M.get_report()
  local lines = {
    '# Himalaya Performance Report',
    '',
    '## Cache Performance',
    string.format('Cache Hits: %d', M.metrics.cache_hits),
    string.format('Cache Misses: %d', M.metrics.cache_misses),
    string.format('Hit Rate: %.1f%%', 
      M.metrics.cache_hits / math.max(1, M.metrics.cache_hits + M.metrics.cache_misses) * 100),
    '',
    '## Operation Timings',
    ''
  }
  
  -- Sort operations by average time
  local sorted_ops = {}
  for name, data in pairs(M.metrics.operations) do
    table.insert(sorted_ops, {
      name = name,
      data = data,
      avg = data.total_time / data.count
    })
  end
  table.sort(sorted_ops, function(a, b) return a.avg > b.avg end)
  
  -- Add operation details
  for _, op in ipairs(sorted_ops) do
    table.insert(lines, string.format('### %s', op.name))
    table.insert(lines, string.format('- Count: %d', op.data.count))
    table.insert(lines, string.format('- Average: %.2f ms', op.avg))
    table.insert(lines, string.format('- Min: %.2f ms', op.data.min_time))
    table.insert(lines, string.format('- Max: %.2f ms', op.data.max_time))
    table.insert(lines, string.format('- Total: %.2f ms', op.data.total_time))
    table.insert(lines, '')
  end
  
  return lines
end

-- Reset metrics
function M.reset_metrics()
  M.metrics = {
    operations = {},
    cache_hits = 0,
    cache_misses = 0,
    average_times = {}
  }
end

-- Show performance report in float
function M.show_report()
  local float = require('neotex.plugins.tools.himalaya.ui.float')
  float.show('Performance Report', M.get_report())
end

-- Setup performance monitoring
function M.setup()
  -- Add performance command
  vim.api.nvim_create_user_command('HimalayaPerformance', function(opts)
    if opts.args == 'reset' then
      M.reset_metrics()
      vim.notify('Performance metrics reset')
    else
      M.show_report()
    end
  end, {
    nargs = '?',
    complete = function()
      return { 'reset' }
    end,
    desc = 'Show Himalaya performance report'
  })
end

return M