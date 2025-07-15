-- Comprehensive Test Runner for All Draft System Components (Phase 7)
-- Runs all draft-related tests and provides consolidated results

local M = {}

-- Load all draft test modules
local test_modules = {
  'test_draft_state_integration',
  'test_draft_recovery', 
  'test_draft_events',
  'test_draft_notifications',
  'test_draft_commands_config',
  'test_draft_window_management',
  'test_draft_integration'
}

-- Color codes for output
local colors = {
  green = '\27[32m',
  red = '\27[31m', 
  yellow = '\27[33m',
  blue = '\27[34m',
  reset = '\27[0m',
  bold = '\27[1m'
}

-- Format test results with colors
local function format_result(passed, total, module_name)
  local color = passed == total and colors.green or (passed > 0 and colors.yellow or colors.red)
  return string.format('%s%s: %d/%d passed%s', color, module_name, passed, total, colors.reset)
end

-- Run individual test module
local function run_test_module(module_name)
  print(string.format('%s%s Running %s tests...%s', colors.blue, colors.bold, module_name, colors.reset))
  
  local ok, test_suite = pcall(require, 'neotex.plugins.tools.himalaya.scripts.features.' .. module_name)
  if not ok then
    print(string.format('%s  Error loading test module: %s%s', colors.red, test_suite, colors.reset))
    return { passed = 0, total = 0, errors = { 'Failed to load module: ' .. test_suite } }
  end
  
  if not test_suite or not test_suite.run then
    print(string.format('%s  Test module has no run function%s', colors.red, colors.reset))
    return { passed = 0, total = 0, errors = { 'Module has no run function' } }
  end
  
  -- Capture test output
  local result = test_suite:run()
  
  print(string.format('  %s', format_result(result.passed, result.total, module_name)))
  
  if result.errors and #result.errors > 0 then
    for _, error in ipairs(result.errors) do
      local error_msg = error
      if type(error) == 'table' then
        error_msg = string.format('%s: %s', error.test or 'Unknown test', error.error or 'Unknown error')
      end
      print(string.format('    %s✗ %s%s', colors.red, error_msg, colors.reset))
    end
  end
  
  return result
end

-- Run all draft tests
function M.run_all()
  print(string.format('%s%s═══ Draft System Test Suite ═══%s', colors.bold, colors.blue, colors.reset))
  print()
  
  local total_passed = 0
  local total_tests = 0
  local total_errors = {}
  local module_results = {}
  
  for _, module_name in ipairs(test_modules) do
    local result = run_test_module(module_name)
    
    total_passed = total_passed + result.passed
    total_tests = total_tests + result.total
    
    if result.errors then
      vim.list_extend(total_errors, result.errors)
    end
    
    table.insert(module_results, {
      name = module_name,
      passed = result.passed,
      total = result.total,
      success_rate = result.total > 0 and (result.passed / result.total * 100) or 0
    })
    
    print() -- Space between modules
  end
  
  -- Summary
  print(string.format('%s%s═══ Test Summary ═══%s', colors.bold, colors.blue, colors.reset))
  print()
  
  -- Overall result
  local overall_color = total_passed == total_tests and colors.green or 
                       (total_passed > total_tests * 0.8 and colors.yellow or colors.red)
  print(string.format('%s%sOverall: %d/%d tests passed (%.1f%%)%s', 
    colors.bold, overall_color, total_passed, total_tests, 
    total_tests > 0 and (total_passed / total_tests * 100) or 0, colors.reset))
  print()
  
  -- Module breakdown
  print('Module Results:')
  for _, result in ipairs(module_results) do
    local module_color = result.success_rate == 100 and colors.green or 
                        (result.success_rate > 80 and colors.yellow or colors.red)
    print(string.format('  %s%-25s %d/%d (%.1f%%)%s', 
      module_color, result.name .. ':', result.passed, result.total, result.success_rate, colors.reset))
  end
  print()
  
  -- Detailed errors if any
  if #total_errors > 0 then
    print(string.format('%s%sErrors:%s', colors.bold, colors.red, colors.reset))
    for i, error in ipairs(total_errors) do
      print(string.format('  %d. %s', i, error))
    end
    print()
  end
  
  -- Recommendations
  if total_passed == total_tests then
    print(string.format('%s%s✓ All tests passed! Draft system is ready for production.%s', 
      colors.bold, colors.green, colors.reset))
  elseif total_passed > total_tests * 0.9 then
    print(string.format('%s%s⚠ Most tests passed. Review failing tests before deployment.%s', 
      colors.bold, colors.yellow, colors.reset))
  else
    print(string.format('%s%s✗ Significant test failures. Address issues before proceeding.%s', 
      colors.bold, colors.red, colors.reset))
  end
  
  print()
  
  return {
    passed = total_passed,
    total = total_tests,
    success_rate = total_tests > 0 and (total_passed / total_tests * 100) or 0,
    errors = total_errors,
    module_results = module_results
  }
end

-- Run specific test module
function M.run_module(module_name)
  if not vim.tbl_contains(test_modules, module_name) then
    print(string.format('%sError: Unknown test module "%s"%s', colors.red, module_name, colors.reset))
    print('Available modules:')
    for _, name in ipairs(test_modules) do
      print(string.format('  - %s', name))
    end
    return
  end
  
  print(string.format('%s%s═══ %s Tests ═══%s', colors.bold, colors.blue, module_name, colors.reset))
  print()
  
  local result = run_test_module(module_name)
  
  print()
  print(string.format('%s%s═══ Module Summary ═══%s', colors.bold, colors.blue, colors.reset))
  print(string.format('Result: %s', format_result(result.passed, result.total, module_name)))
  
  if result.errors and #result.errors > 0 then
    print(string.format('%sErrors:%s', colors.red, colors.reset))
    for i, error in ipairs(result.errors) do
      print(string.format('  %d. %s', i, error))
    end
  end
  
  return result
end

-- Quick health check using tests
function M.health_check()
  print(string.format('%s%s═══ Draft System Health Check ═══%s', colors.bold, colors.blue, colors.reset))
  print()
  
  -- Run a subset of critical tests
  local critical_modules = {
    'test_draft_state_integration',
    'test_draft_health'
  }
  
  local health_passed = 0
  local health_total = 0
  
  for _, module_name in ipairs(critical_modules) do
    local result = run_test_module(module_name)
    health_passed = health_passed + result.passed
    health_total = health_total + result.total
  end
  
  print()
  print(string.format('%s%s═══ Health Summary ═══%s', colors.bold, colors.blue, colors.reset))
  
  local health_rate = health_total > 0 and (health_passed / health_total * 100) or 0
  local health_color = health_rate == 100 and colors.green or 
                      (health_rate > 90 and colors.yellow or colors.red)
  
  print(string.format('%s%sHealth Score: %.1f%% (%d/%d critical tests passed)%s', 
    colors.bold, health_color, health_rate, health_passed, health_total, colors.reset))
  
  if health_rate == 100 then
    print(string.format('%s✓ Draft system is healthy%s', colors.green, colors.reset))
  elseif health_rate > 90 then
    print(string.format('%s⚠ Draft system has minor issues%s', colors.yellow, colors.reset))
  else
    print(string.format('%s✗ Draft system has serious issues%s', colors.red, colors.reset))
  end
  
  return {
    passed = health_passed,
    total = health_total,
    health_rate = health_rate,
    status = health_rate == 100 and 'healthy' or (health_rate > 90 and 'warning' or 'critical')
  }
end

-- List available test modules
function M.list_modules()
  print('Available draft test modules:')
  for i, module_name in ipairs(test_modules) do
    print(string.format('  %d. %s', i, module_name))
  end
end

-- Export global functions for easy access
_G.run_all_draft_tests = M.run_all
_G.run_draft_test = M.run_module
_G.draft_health_check = M.health_check

return M