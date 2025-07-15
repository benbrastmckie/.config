-- Test Performance Monitoring
-- Utilities for measuring and reporting test performance metrics

local M = {}

-- Performance tracking state
M.metrics = {
  test_durations = {},
  memory_usage = {},
  assertions_count = {},
  performance_thresholds = {
    fast = 50,    -- < 50ms
    medium = 200, -- 50-200ms
    slow = 500,   -- 200-500ms
    -- > 500ms is considered very slow
  }
}

-- Start performance monitoring for a test
function M.start_monitoring(test_name)
  return {
    test_name = test_name,
    start_time = vim.loop.hrtime(),
    start_memory = collectgarbage('count'),
    assertion_count = 0
  }
end

-- End performance monitoring and record results
function M.end_monitoring(monitor)
  local end_time = vim.loop.hrtime()
  local end_memory = collectgarbage('count')
  local duration = (end_time - monitor.start_time) / 1e6 -- Convert to ms
  
  local result = {
    test_name = monitor.test_name,
    duration_ms = duration,
    memory_delta_kb = end_memory - monitor.start_memory,
    assertion_count = monitor.assertion_count,
    performance_category = M.categorize_performance(duration),
    timestamp = os.date('%Y-%m-%d %H:%M:%S')
  }
  
  -- Store in metrics
  M.metrics.test_durations[monitor.test_name] = duration
  M.metrics.memory_usage[monitor.test_name] = result.memory_delta_kb
  M.metrics.assertions_count[monitor.test_name] = result.assertion_count
  
  return result
end

-- Categorize performance based on duration
function M.categorize_performance(duration_ms)
  local thresholds = M.metrics.performance_thresholds
  
  if duration_ms < thresholds.fast then
    return 'fast'
  elseif duration_ms < thresholds.medium then
    return 'medium'
  elseif duration_ms < thresholds.slow then
    return 'slow'
  else
    return 'very_slow'
  end
end

-- Increment assertion count for a test
function M.record_assertion(monitor)
  if monitor then
    monitor.assertion_count = monitor.assertion_count + 1
  end
end

-- Generate performance report
function M.generate_report()
  local report = {
    '# Test Performance Report',
    '',
    string.format('Generated: %s', os.date('%Y-%m-%d %H:%M:%S')),
    ''
  }
  
  -- Summary statistics
  local total_tests = vim.tbl_count(M.metrics.test_durations)
  local total_duration = 0
  local performance_counts = { fast = 0, medium = 0, slow = 0, very_slow = 0 }
  
  for test_name, duration in pairs(M.metrics.test_durations) do
    total_duration = total_duration + duration
    local category = M.categorize_performance(duration)
    performance_counts[category] = performance_counts[category] + 1
  end
  
  table.insert(report, '## Summary')
  table.insert(report, string.format('Total Tests: %d', total_tests))
  table.insert(report, string.format('Total Duration: %.2f ms', total_duration))
  table.insert(report, string.format('Average Duration: %.2f ms', total_duration / total_tests))
  table.insert(report, '')
  
  -- Performance distribution
  table.insert(report, '## Performance Distribution')
  for category, count in pairs(performance_counts) do
    local percentage = (count / total_tests) * 100
    table.insert(report, string.format('- %s: %d tests (%.1f%%)', category, count, percentage))
  end
  table.insert(report, '')
  
  -- Slowest tests
  table.insert(report, '## Slowest Tests')
  local sorted_tests = {}
  for test_name, duration in pairs(M.metrics.test_durations) do
    table.insert(sorted_tests, {name = test_name, duration = duration})
  end
  table.sort(sorted_tests, function(a, b) return a.duration > b.duration end)
  
  for i = 1, math.min(10, #sorted_tests) do
    local test = sorted_tests[i]
    local category = M.categorize_performance(test.duration)
    table.insert(report, string.format('%d. %s: %.2f ms (%s)', 
      i, test.name, test.duration, category))
  end
  table.insert(report, '')
  
  -- Memory usage
  local total_memory = 0
  local memory_count = 0
  for test_name, memory in pairs(M.metrics.memory_usage) do
    total_memory = total_memory + memory
    memory_count = memory_count + 1
  end
  
  if memory_count > 0 then
    table.insert(report, '## Memory Usage')
    table.insert(report, string.format('Total Memory Delta: %.2f KB', total_memory))
    table.insert(report, string.format('Average Memory Delta: %.2f KB', total_memory / memory_count))
    table.insert(report, '')
  end
  
  return table.concat(report, '\n')
end

-- Get performance metrics for a specific test
function M.get_test_metrics(test_name)
  return {
    duration_ms = M.metrics.test_durations[test_name],
    memory_delta_kb = M.metrics.memory_usage[test_name],
    assertion_count = M.metrics.assertions_count[test_name],
    performance_category = M.categorize_performance(M.metrics.test_durations[test_name] or 0)
  }
end

-- Clear all metrics
function M.clear_metrics()
  M.metrics.test_durations = {}
  M.metrics.memory_usage = {}
  M.metrics.assertions_count = {}
end

-- Set performance thresholds
function M.set_thresholds(thresholds)
  M.metrics.performance_thresholds = vim.tbl_extend('force', 
    M.metrics.performance_thresholds, thresholds)
end

-- Check if a test meets performance requirements
function M.validate_performance(test_name, max_duration_ms, max_memory_kb)
  local duration = M.metrics.test_durations[test_name]
  local memory = M.metrics.memory_usage[test_name]
  
  local issues = {}
  
  if duration and max_duration_ms and duration > max_duration_ms then
    table.insert(issues, string.format('Duration %.2fms exceeds limit %dms', 
      duration, max_duration_ms))
  end
  
  if memory and max_memory_kb and memory > max_memory_kb then
    table.insert(issues, string.format('Memory usage %.2fKB exceeds limit %dKB', 
      memory, max_memory_kb))
  end
  
  return #issues == 0, issues
end

-- Performance-aware test wrapper
function M.performance_test(test_name, test_fn, options)
  options = options or {}
  local monitor = M.start_monitoring(test_name)
  
  local start_time = vim.loop.hrtime()
  local success, result = pcall(test_fn)
  local end_time = vim.loop.hrtime()
  
  local perf_result = M.end_monitoring(monitor)
  
  -- Check performance requirements
  if options.max_duration_ms then
    local valid, issues = M.validate_performance(test_name, options.max_duration_ms, options.max_memory_kb)
    if not valid then
      return false, {
        error = 'Performance requirements not met',
        issues = issues,
        performance = perf_result
      }
    end
  end
  
  if success then
    return true, {
      result = result,
      performance = perf_result
    }
  else
    return false, {
      error = result,
      performance = perf_result
    }
  end
end

-- Batch performance analysis
function M.analyze_test_suite(test_results)
  local analysis = {
    total_tests = #test_results,
    total_duration = 0,
    performance_issues = {},
    memory_issues = {},
    recommendations = {}
  }
  
  for _, test_result in ipairs(test_results) do
    if test_result.performance then
      local perf = test_result.performance
      analysis.total_duration = analysis.total_duration + perf.duration_ms
      
      -- Flag performance issues
      if perf.performance_category == 'very_slow' then
        table.insert(analysis.performance_issues, {
          test = perf.test_name,
          duration = perf.duration_ms,
          severity = 'high'
        })
      elseif perf.performance_category == 'slow' then
        table.insert(analysis.performance_issues, {
          test = perf.test_name,
          duration = perf.duration_ms,
          severity = 'medium'
        })
      end
      
      -- Flag memory issues
      if perf.memory_delta_kb > 100 then -- 100KB threshold
        table.insert(analysis.memory_issues, {
          test = perf.test_name,
          memory_delta = perf.memory_delta_kb,
          severity = perf.memory_delta_kb > 500 and 'high' or 'medium'
        })
      end
    end
  end
  
  -- Generate recommendations
  if #analysis.performance_issues > 0 then
    table.insert(analysis.recommendations, 
      string.format('Consider optimizing %d slow tests', #analysis.performance_issues))
  end
  
  if #analysis.memory_issues > 0 then
    table.insert(analysis.recommendations, 
      string.format('Review memory usage in %d tests', #analysis.memory_issues))
  end
  
  if analysis.total_duration > 5000 then -- 5 seconds
    table.insert(analysis.recommendations, 
      'Consider parallelizing tests to reduce total run time')
  end
  
  return analysis
end

return M