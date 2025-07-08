-- Test Runner for Himalaya Plugin
-- Central test management with picker interface

local M = {}

-- Test infrastructure
local notify = require('neotex.util.notifications')
local float = require('neotex.plugins.tools.himalaya.ui.float')

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
  
  -- Create test command
  vim.api.nvim_create_user_command('HimalayaTest', function(opts)
    M.run_with_picker(opts.args)
  end, {
    nargs = '?',
    complete = M.get_test_completions,
    desc = 'Run Himalaya tests with picker'
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
  
  local script_path = vim.fn.expand('~/.config/nvim/lua/neotex/plugins/tools/himalaya/scripts/')
  
  for _, dir in ipairs(test_dirs) do
    M.tests[dir] = {}
    local dir_path = script_path .. dir .. '/'
    
    -- Find all test files in directory
    local files = vim.fn.glob(dir_path .. 'test_*.lua', false, true)
    
    for _, file in ipairs(files) do
      local name = vim.fn.fnamemodify(file, ':t:r')
      local display_name = name:gsub('test_', ''):gsub('_', ' ')
      
      table.insert(M.tests[dir], {
        name = name,
        display_name = display_name,
        path = file,
        category = dir
      })
    end
  end
end

-- Test picker interface
function M.run_with_picker(filter)
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
  local lines = { '# Himalaya Test Runner', '', 'Select tests to run:' }
  local choices = {}
  
  for i, item in ipairs(items) do
    if item.value then
      table.insert(lines, string.format('%d. %s %s', #choices + 1, item.icon, item.text))
      table.insert(choices, item)
    else
      table.insert(lines, item.text)
    end
  end
  
  table.insert(lines, '')
  table.insert(lines, 'Enter number (or q to quit): ')
  
  -- Show in float
  local buf = float.create_float_buffer(lines)
  local win = float.create_float_window(buf, {
    title = 'Test Runner',
    width = 60,
    height = #lines + 2
  })
  
  -- Get user input
  vim.api.nvim_set_current_win(win)
  vim.cmd('startinsert!')
  
  -- Handle input
  vim.api.nvim_buf_set_keymap(buf, 'i', '<CR>', '', {
    callback = function()
      local line = vim.api.nvim_get_current_line()
      local num = tonumber(line:match('%d+'))
      
      vim.api.nvim_win_close(win, true)
      
      if num and choices[num] then
        M.execute_test_selection(choices[num].value)
      end
    end
  })
  
  vim.api.nvim_buf_set_keymap(buf, 'i', 'q', '', {
    callback = function()
      vim.api.nvim_win_close(win, true)
    end
  })
end

-- Execute selected tests
function M.execute_test_selection(selection)
  -- Reset results
  M.reset_results()
  
  -- Show start notification
  if not M.config.debug_notifications then
    notify.himalaya('Starting tests...', notify.categories.STATUS)
  end
  
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
function M.run_test(test)
  M.results.total = M.results.total + 1
  
  -- Debug notification
  if M.config.debug_notifications then
    notify.himalaya(
      string.format('Running %s: %s', test.category, test.display_name),
      notify.categories.BACKGROUND
    )
  end
  
  -- Load and execute test
  local ok, result = pcall(function()
    -- Clear any existing test state
    if _G.himalaya_test then
      _G.himalaya_test = nil
    end
    
    -- Load test file
    dofile(test.path)
    
    -- Execute test if it exported a run function
    if _G.himalaya_test and _G.himalaya_test.run then
      return _G.himalaya_test.run()
    else
      error('Test file must export himalaya_test.run function')
    end
  end)
  
  if ok then
    if result and result.passed then
      M.results.passed = M.results.passed + 1
    elseif result and result.skipped then
      M.results.skipped = M.results.skipped + 1
      table.insert(M.results.errors, {
        test = test.name,
        category = test.category,
        type = 'skipped',
        message = result.reason or 'Test skipped'
      })
    else
      M.results.failed = M.results.failed + 1
      table.insert(M.results.errors, {
        test = test.name,
        category = test.category,
        type = 'failed',
        message = result and result.error or 'Unknown failure'
      })
    end
  else
    M.results.failed = M.results.failed + 1
    table.insert(M.results.errors, {
      test = test.name,
      category = test.category,
      type = 'error',
      message = tostring(result)
    })
  end
end

-- Show test results
function M.show_results()
  -- Stop notification
  if not M.config.debug_notifications then
    notify.himalaya(
      string.format('Tests complete: %d/%d passed', M.results.passed, M.results.total),
      M.results.failed > 0 and notify.categories.WARNING or notify.categories.STATUS
    )
  end
  
  -- Build report
  local lines = M.build_report()
  
  -- Show in float window
  float.show('Test Results', lines)
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
  local completions = { 'all', 'commands', 'features', 'integration', 'performance' }
  
  for _, tests in pairs(M.tests) do
    for _, test in ipairs(tests) do
      table.insert(completions, test.name)
    end
  end
  
  return completions
end

return M