-- Unit tests for async utilities

local test_framework = require('neotex.plugins.tools.himalaya.test.utils.test_framework')
local assert = test_framework.assert
local async_utils = require('neotex.plugins.tools.himalaya.utils.async')

local M = {}

function M.test_debounce()
  local call_count = 0
  local last_value = nil
  
  local debounced = async_utils.debounce(function(value)
    call_count = call_count + 1
    last_value = value
  end, 50)
  
  -- Call multiple times quickly
  debounced(1)
  debounced(2)
  debounced(3)
  
  -- Should not have been called yet
  assert.equals(call_count, 0, 'Should not call immediately')
  
  -- Wait for debounce (increased timeout for reliability)
  vim.wait(200, function() return call_count > 0 end, 10)
  
  -- Should have been called once with last value
  assert.equals(call_count, 1, 'Should call once after delay')
  assert.equals(last_value, 3, 'Should use last value')
end

function M.test_throttle()
  local call_count = 0
  local values = {}
  
  local throttled = async_utils.throttle(function(value)
    call_count = call_count + 1
    table.insert(values, value)
  end, 50)
  
  -- First call should go through immediately
  throttled(1)
  assert.equals(call_count, 1, 'First call should execute immediately')
  
  -- Subsequent calls should be throttled
  throttled(2)
  throttled(3)
  assert.equals(call_count, 1, 'Should throttle subsequent calls')
  
  -- Wait for throttle period
  vim.wait(100, function() return call_count > 1 end)
  
  -- Should have executed the last throttled call
  assert.equals(call_count, 2, 'Should execute throttled call')
  assert.equals(values[2], 3, 'Should use last throttled value')
end

function M.test_defer()
  local executed = false
  
  async_utils.defer(function()
    executed = true
  end, 10)
  
  -- Should not execute immediately
  assert.falsy(executed, 'Should not execute immediately')
  
  -- Wait for deferred execution
  vim.wait(50, function() return executed end)
  assert.truthy(executed, 'Should execute after delay')
end

function M.test_schedule()
  local executed = false
  
  async_utils.schedule(function()
    executed = true
  end)
  
  -- Should execute in next event loop
  vim.wait(10, function() return executed end)
  assert.truthy(executed, 'Should execute in next loop')
end

function M.test_parallel()
  local results = {}
  local start_time = vim.loop.hrtime()
  
  async_utils.parallel({
    function(callback)
      vim.defer_fn(function()
        callback('result1')
      end, 20)
    end,
    function(callback)
      vim.defer_fn(function()
        callback('result2')
      end, 10)
    end,
    function(callback)
      vim.defer_fn(function()
        callback('result3')
      end, 30)
    end
  }, function(all_results)
    results = all_results
  end)
  
  -- Wait for all to complete
  vim.wait(50, function() return #results == 3 end)
  
  -- Should have all results in order
  assert.equals(results[1], 'result1', 'First result')
  assert.equals(results[2], 'result2', 'Second result')
  assert.equals(results[3], 'result3', 'Third result')
  
  -- Should complete in parallel (roughly 30ms, not 60ms)
  local duration = (vim.loop.hrtime() - start_time) / 1000000
  assert.truthy(duration < 40, 'Should run in parallel')
end

function M.test_series()
  local results = {}
  local call_order = {}
  
  async_utils.series({
    function(callback)
      vim.defer_fn(function()
        table.insert(call_order, 1)
        callback('result1')
      end, 20)
    end,
    function(callback)
      vim.defer_fn(function()
        table.insert(call_order, 2)
        callback('result2')
      end, 10)
    end,
    function(callback)
      vim.defer_fn(function()
        table.insert(call_order, 3)
        callback('result3')
      end, 10)
    end
  }, function(all_results)
    results = all_results
  end)
  
  -- Wait for all to complete
  vim.wait(100, function() return #results == 3 end)
  
  -- Should have results and correct order
  assert.equals(#call_order, 3, 'All should execute')
  assert.equals(call_order[1], 1, 'First executes first')
  assert.equals(call_order[2], 2, 'Second executes second')
  assert.equals(call_order[3], 3, 'Third executes third')
end

function M.test_rate_limit()
  local call_count = 0
  local rate_limited = async_utils.rate_limit(function()
    call_count = call_count + 1
    return true
  end, 2, 100) -- 2 calls per 100ms
  
  -- First two calls should succeed
  assert.truthy(rate_limited(), 'First call should succeed')
  assert.truthy(rate_limited(), 'Second call should succeed')
  
  -- Third call should be rate limited
  local result, err = rate_limited()
  if result ~= nil then error('Third call should be limited') end
  assert.equals(err, 'Rate limited', 'Should return rate limit error')
  assert.equals(call_count, 2, 'Only two calls should execute')
  
  -- Wait for window to pass
  vim.wait(150)
  
  -- Should be able to call again
  assert.truthy(rate_limited(), 'Should allow call after window')
  assert.equals(call_count, 3, 'Should execute after window')
end

function M.test_batch()
  local batches = {}
  local batch_fn = async_utils.batch(function(items)
    table.insert(batches, items)
  end, 3, 20) -- batch size 3, 20ms delay
  
  -- Add items
  for i = 1, 7 do
    batch_fn(i)
  end
  
  -- Wait for batches to process
  vim.wait(100, function() return #batches >= 3 end, 10)
  
  -- Should have processed in batches
  assert.equals(#batches[1], 3, 'First batch should have 3 items')
  assert.equals(#batches[2], 3, 'Second batch should have 3 items')
  assert.equals(#batches[3], 1, 'Third batch should have 1 item')
end

function M.test_worker_pool()
  local processed = {}
  local pool = async_utils.worker_pool(function(task, callback)
    vim.defer_fn(function()
      table.insert(processed, task.data)
      callback(task.data * 2)
    end, 10)
  end, 2) -- pool size 2
  
  -- Add tasks
  local results = {}
  for i = 1, 5 do
    pool.add(i, function(result)
      results[i] = result
    end)
  end
  
  -- Check initial state
  assert.truthy(pool.size() > 0, 'Should have queued items')
  assert.truthy(pool.busy() <= 2, 'Should not exceed pool size')
  
  -- Wait for completion (increased timeout for reliability)
  vim.wait(500, function() return #processed == 5 end, 10)
  
  -- Check results
  assert.equals(#processed, 5, 'All items should be processed')
  for i = 1, 5 do
    assert.equals(results[i], i * 2, 'Should have correct result')
  end
end

return M