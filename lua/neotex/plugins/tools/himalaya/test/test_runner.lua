-- Test Runner for Himalaya Plugin
-- Central test management with picker interface

local M = {}

-- Test infrastructure
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local notify = require('neotex.util.notifications')

-- Test registry
M.tests = {
  commands = {},
  features = {},
  integration = {},
  performance = {}
}

-- Test results
M.results = {
  total = 0,
  passed = 0,
  failed = 0,
  skipped = 0,
  errors = {},
  duration = 0,
  performance = {}
}

-- Configuration
M.config = {
  show_progress = true,
  debug_notifications = false,
  timeout_ms = 30000,
  report_format = 'detailed' -- 'detailed', 'summary', 'minimal'
}

-- Initialize test runner
function M.setup()
  -- Check if debug mode is enabled
  local ok, himalaya = pcall(require, 'neotex.plugins.tools.himalaya')
  if ok and himalaya.config and himalaya.config.debug then
    M.config.debug_notifications = true
  end
  
  -- Discover all test files
  M.discover_tests()
  
  logger.info('Test runner initialized', { 
    features = #M.tests.features,
    commands = #M.tests.commands,
    integration = #M.tests.integration,
    performance = #M.tests.performance
  })
end

-- Discover test files
function M.discover_tests()
  local test_dirs = {
    'commands',
    'features', 
    'integration',
    'performance'
  }
  
  local test_path = vim.fn.stdpath('config') .. '/lua/neotex/plugins/tools/himalaya/test/'
  
  for _, dir in ipairs(test_dirs) do
    M.tests[dir] = {}
    local dir_path = test_path .. dir .. '/'
    
    -- Check if directory exists
    if vim.fn.isdirectory(dir_path) == 1 then
      -- Find all test files in directory
      local files = vim.fn.glob(dir_path .. 'test_*.lua', false, true)
      
      for _, file in ipairs(files) do
        local name = vim.fn.fnamemodify(file, ':t:r')
        local display_name = name:gsub('test_', ''):gsub('_', ' ')
        
        table.insert(M.tests[dir], {
          name = name,
          display_name = display_name,
          path = file,
          category = dir,
          module_path = 'neotex.plugins.tools.himalaya.test.' .. dir .. '.' .. name
        })
      end
    end
  end
end

-- Test picker interface
function M.run_with_picker(filter)
  -- Handle direct test name argument
  if filter and filter ~= '' then
    -- Try to run specific test by name
    for category, tests in pairs(M.tests) do
      for _, test in ipairs(tests) do
        if test.name == filter or test.display_name == filter then
          M.execute_test_selection(test)
          return
        end
      end
    end
    
    -- Try category
    if M.tests[filter] then
      M.execute_test_selection(filter)
      return
    end
    
    notify.error('Test not found: ' .. filter)
    return
  end
  
  local items = {
    { text = '── Run All Tests ──', value = 'all', icon = '🚀' },
    { text = '── Run All Command Tests ──', value = 'commands', icon = '📝' },
    { text = '── Run All Feature Tests ──', value = 'features', icon = '✨' },
    { text = '── Run All Integration Tests ──', value = 'integration', icon = '🔗' },
    { text = '── Run All Performance Tests ──', value = 'performance', icon = '⚡' },
    { text = '────────────────', value = nil, icon = '─' }
  }
  
  -- Add individual tests
  for category, tests in pairs(M.tests) do
    for _, test in ipairs(tests) do
      table.insert(items, {
        text = string.format('[%s] %s', category:sub(1,3):upper(), test.display_name),
        value = test,
        icon = M.get_test_icon(category)
      })
    end
  end
  
  -- Use telescope if available, otherwise simple picker
  if pcall(require, 'telescope') then
    M.telescope_picker(items)
  else
    M.simple_picker(items)
  end
end

-- Telescope picker implementation
function M.telescope_picker(items)
  local telescope = require('telescope')
  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  
  local picker_items = {}
  for _, item in ipairs(items) do
    if item.value then
      table.insert(picker_items, {
        display = string.format('%s %s', item.icon, item.text),
        value = item.value,
        ordinal = item.text
      })
    end
  end
  
  pickers.new({}, {
    prompt_title = 'Himalaya Test Runner',
    finder = finders.new_table {
      results = picker_items,
      entry_maker = function(entry)
        return {
          value = entry.value,
          display = entry.display,
          ordinal = entry.ordinal
        }
      end
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          M.execute_test_selection(selection.value)
        end
      end)
      return true
    end,
  }):find()
end

-- Simple picker implementation
function M.simple_picker(items)
  local lines = {}
  local choices = {}
  
  for i, item in ipairs(items) do
    if item.value then
      table.insert(choices, item)
      table.insert(lines, string.format('%d. %s %s', #choices, item.icon, item.text))
    else
      table.insert(lines, '')
    end
  end
  
  vim.ui.select(choices, {
    prompt = 'Select test to run:',
    format_item = function(item)
      return string.format('%s %s', item.icon, item.text)
    end
  }, function(choice)
    if choice then
      M.execute_test_selection(choice.value)
    end
  end)
end

-- Execute selected tests
function M.execute_test_selection(selection)
  -- Reset results
  M.reset_results()
  
  -- Show start notification
  notify.info('Starting tests...')
  
  local start_time = vim.loop.hrtime()
  
  if selection == 'all' then
    M.run_all_tests()
  elseif type(selection) == 'string' then
    M.run_category_tests(selection)
  else
    M.run_single_test(selection)
  end
  
  -- Calculate duration
  M.results.duration = (vim.loop.hrtime() - start_time) / 1e6
  
  -- Show results
  M.show_results()
end

-- Run all tests
function M.run_all_tests()
  for category, tests in pairs(M.tests) do
    for _, test in ipairs(tests) do
      M.run_test(test)
    end
  end
end

-- Run category tests
function M.run_category_tests(category)
  local tests = M.tests[category] or {}
  for _, test in ipairs(tests) do
    M.run_test(test)
  end
end

-- Run single test
function M.run_single_test(test)
  M.run_test(test)
end

-- Execute individual test
function M.run_test(test_info)
  -- Load and execute test
  local ok, test_module = pcall(require, test_info.module_path)
  
  if not ok then
    -- Try loading by path if module loading fails
    ok, test_module = pcall(dofile, test_info.path)
  end
  
  if ok and test_module then
    -- Setup test environment
    if test_module.setup then
      pcall(test_module.setup)
    end
    
    -- Count individual tests
    local test_count = 0
    local test_passed = 0
    local test_failed = 0
    local test_errors = {}
    
    -- Run all test functions
    for name, func in pairs(test_module) do
      if type(func) == 'function' and name:match('^test_') then
        test_count = test_count + 1
        
        local success, result = pcall(func)
        
        if success and result ~= false then
          test_passed = test_passed + 1
        else
          test_failed = test_failed + 1
          table.insert(test_errors, {
            test = name,
            error = not success and tostring(result) or 'Test returned false'
          })
        end
      end
    end
    
    -- Run module's run function if it exists
    if test_module.run and type(test_module.run) == 'function' then
      local success, result = pcall(test_module.run)
      
      if success and type(result) == 'table' then
        -- Module returned aggregate results
        M.results.total = M.results.total + (result.total or test_count)
        M.results.passed = M.results.passed + (result.passed or test_passed)
        M.results.failed = M.results.failed + (result.failed or test_failed)
        
        -- Add errors
        if result.errors then
          for _, error in ipairs(result.errors) do
            table.insert(M.results.errors, {
              test = test_info.name .. ':' .. error.test,
              category = test_info.category,
              type = 'failed',
              message = error.error or error.message
            })
          end
        elseif #test_errors > 0 then
          for _, error in ipairs(test_errors) do
            table.insert(M.results.errors, {
              test = test_info.name .. ':' .. error.test,
              category = test_info.category,
              type = 'failed',
              message = error.error
            })
          end
        end
      elseif success then
        -- Simple pass/fail result
        M.results.total = M.results.total + 1
        if result ~= false then
          M.results.passed = M.results.passed + 1
        else
          M.results.failed = M.results.failed + 1
          table.insert(M.results.errors, {
            test = test_info.name,
            category = test_info.category,
            type = 'failed',
            message = 'Test returned false'
          })
        end
      else
        -- Test execution failed
        M.results.total = M.results.total + 1
        M.results.failed = M.results.failed + 1
        table.insert(M.results.errors, {
          test = test_info.name,
          category = test_info.category,
          type = 'error',
          message = tostring(result)
        })
      end
    elseif test_count > 0 then
      -- No run function but individual tests were found
      M.results.total = M.results.total + test_count
      M.results.passed = M.results.passed + test_passed
      M.results.failed = M.results.failed + test_failed
      
      for _, error in ipairs(test_errors) do
        table.insert(M.results.errors, {
          test = test_info.name .. ':' .. error.test,
          category = test_info.category,
          type = 'failed',
          message = error.error
        })
      end
    else
      -- No tests found
      M.results.total = M.results.total + 1
      M.results.failed = M.results.failed + 1
      table.insert(M.results.errors, {
        test = test_info.name,
        category = test_info.category,
        type = 'error',
        message = 'No test functions found'
      })
    end
    
    -- Teardown
    if test_module.teardown then
      pcall(test_module.teardown)
    end
  else
    -- Error loading test file
    M.results.total = M.results.total + 1
    M.results.failed = M.results.failed + 1
    table.insert(M.results.errors, {
      test = test_info.name,
      category = test_info.category,
      type = 'error',
      message = tostring(test_module)
    })
  end
end

-- Show test results
function M.show_results()
  -- Build report
  local lines = M.build_report()
  
  -- Notification
  local status = M.results.failed > 0 and 'error' or 'info'
  notify[status](string.format('Tests complete: %d/%d passed', M.results.passed, M.results.total))
  
  -- Show detailed results in buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  -- Open in split
  vim.cmd('botright split')
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_win_set_height(0, math.min(#lines, 20))
end

-- Build test report
function M.build_report()
  local lines = {}
  
  -- Header
  table.insert(lines, '# Himalaya Test Results')
  table.insert(lines, '')
  table.insert(lines, string.format('Date: %s', os.date('%Y-%m-%d %H:%M:%S')))
  table.insert(lines, string.format('Duration: %.2f ms', M.results.duration))
  table.insert(lines, '')
  
  -- Summary
  table.insert(lines, '## Summary')
  table.insert(lines, string.format('Total Tests: %d', M.results.total))
  table.insert(lines, string.format('✅ Passed: %d', M.results.passed))
  table.insert(lines, string.format('❌ Failed: %d', M.results.failed))
  table.insert(lines, string.format('⏭️  Skipped: %d', M.results.skipped))
  table.insert(lines, '')
  
  -- Success rate
  local success_rate = M.results.total > 0 
    and (M.results.passed / M.results.total * 100) or 0
  table.insert(lines, string.format('Success Rate: %.1f%%', success_rate))
  table.insert(lines, '')
  
  -- Errors if any
  if #M.results.errors > 0 then
    table.insert(lines, '## Failed Tests')
    table.insert(lines, '')
    
    for _, error in ipairs(M.results.errors) do
      local icon = error.type == 'skipped' and '⏭️' or '❌'
      table.insert(lines, string.format('%s [%s] %s', 
        icon, error.category:upper(), error.test))
      table.insert(lines, '  ' .. error.message)
      table.insert(lines, '')
    end
  end
  
  -- Performance metrics if available
  if M.results.performance and next(M.results.performance) then
    table.insert(lines, '## Performance Metrics')
    table.insert(lines, '')
    for metric, value in pairs(M.results.performance) do
      table.insert(lines, string.format('- %s: %s', metric, value))
    end
  end
  
  return lines
end

-- Helper functions
function M.get_test_icon(category)
  local icons = {
    commands = '📝',
    features = '✨',
    integration = '🔗',
    performance = '⚡'
  }
  return icons[category] or '🧪'
end

function M.reset_results()
  M.results = {
    total = 0,
    passed = 0,
    failed = 0,
    skipped = 0,
    errors = {},
    duration = 0,
    performance = {}
  }
end

function M.get_test_completions()
  if #M.tests.commands == 0 then
    M.discover_tests()
  end
  
  local completions = { 'all', 'commands', 'features', 'integration', 'performance' }
  
  for _, tests in pairs(M.tests) do
    for _, test in ipairs(tests) do
      table.insert(completions, test.name)
    end
  end
  
  return completions
end

return M