-- Test Runner for Himalaya Plugin
-- Central test management with picker interface
--
-- This is the core test engine that:
-- - Discovers and organizes all test files
-- - Executes tests and collects results
-- - Provides interactive UI (for :HimalayaTest command)
-- - Can be used both interactively and in headless mode
--
-- For command-line usage, see run_tests.lua which wraps this module

local M = {}

-- Test infrastructure
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local notify = require('neotex.util.notifications')
local float = require('neotex.plugins.tools.himalaya.ui.float')
local isolation = require('neotex.plugins.tools.himalaya.test.utils.test_isolation')

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
  local ok, himalaya = pcall(require, 'neotex.plugins.tools.himalaya.init')
  if ok and himalaya.get_config and himalaya.get_config().config and himalaya.get_config().config.debug then
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

-- Format test name for display
function M.format_test_display_name(name)
  -- Remove test_ prefix
  local display = name:gsub('^test_', '')
  
  -- Special case formatting
  local special_names = {
    ['basic_commands'] = 'Basic Commands',
    ['email_commands'] = 'Email Commands',
    ['sync_commands'] = 'Sync Commands',
    ['draft_commands_config'] = 'Draft Commands & Config',
    ['draft_manager_maildir'] = 'Draft Manager (Maildir)',
    ['draft_saving'] = 'Draft Saving',
    ['email_composer'] = 'Email Composer',
    ['maildir_foundation'] = 'Maildir Foundation',
    ['maildir_integration'] = 'Maildir Integration',
    ['scheduler'] = 'Email Scheduler',
    ['full_workflow'] = 'Full Email Workflow',
    ['search_speed'] = 'Search Performance',
    ['email_operations_simple'] = 'Email Operations (Simple)',
    ['sync_simple'] = 'Sync Operations (Simple)',
    ['draft_simple'] = 'Draft System (Simple)'
  }
  
  -- Check for special name
  if special_names[display] then
    return special_names[display]
  end
  
  -- General formatting: replace underscores and capitalize words
  display = display:gsub('_', ' ')
  
  -- Capitalize first letter of each word
  display = display:gsub("(%a)([%w_']*)", function(first, rest)
    return first:upper() .. rest:lower()
  end)
  
  return display
end

-- Discover test files
function M.discover_tests()
  local test_dirs = {
    'commands',
    'features', 
    'integration',
    'performance',
    'unit'
  }
  
  local test_path = vim.fn.stdpath('config') .. '/lua/neotex/plugins/tools/himalaya/test/'
  
  for _, dir in ipairs(test_dirs) do
    M.tests[dir] = {}
    local dir_path = test_path .. dir .. '/'
    
    -- Check if directory exists
    if vim.fn.isdirectory(dir_path) == 1 then
      -- Find all test files in directory
      local files = vim.fn.glob(dir_path .. 'test_*.lua', false, true)
      
      -- For unit tests, also check subdirectories
      if dir == 'unit' then
        local subdirs = vim.fn.glob(dir_path .. '*/', false, true)
        for _, subdir in ipairs(subdirs) do
          local subdir_files = vim.fn.glob(subdir .. 'test_*.lua', false, true)
          vim.list_extend(files, subdir_files)
        end
      end
      
      for _, file in ipairs(files) do
        local name = vim.fn.fnamemodify(file, ':t:r')
        local display_name = M.format_test_display_name(name)
        
        -- Determine module path based on file location
        local relative_path = file:gsub(test_path, '')
        local module_parts = vim.split(relative_path, '/')
        -- Remove .lua extension from last part
        module_parts[#module_parts] = module_parts[#module_parts]:gsub('%.lua$', '')
        local module_path = 'neotex.plugins.tools.himalaya.test.' .. table.concat(module_parts, '.')
        
        table.insert(M.tests[dir], {
          name = name,
          display_name = display_name,
          path = file,
          category = dir,
          module_path = module_path
        })
      end
    end
  end
end

-- Test picker interface
function M.run_with_picker(filter)
  -- Ensure we start from a clean state
  vim.cmd('stopinsert')
  
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
  
  -- Create cleaner menu structure
  local items = {}
  
  -- Count total tests with validation
  local total_tests, validation_info = M.count_all_tests_with_validation()
  
  -- Add main options with validation indicators
  local all_tests_text = string.format('Run All Tests (%d tests)', total_tests)
  if validation_info.has_missing_metadata then
    all_tests_text = all_tests_text .. ' ⚠️'
  end
  
  table.insert(items, { 
    text = all_tests_text, 
    value = 'all', 
    icon = '🚀',
    metadata = validation_info
  })
  
  -- Add validation summary if there are issues
  if validation_info.has_missing_metadata then
    table.insert(items, { 
      text = string.format('  ⚠️  %d files missing metadata', validation_info.missing_metadata_count), 
      value = nil, 
      icon = ''
    })
  end
  
  table.insert(items, { text = '─────────────────────────', value = nil, icon = '' })
  
  -- Create meaningful test categories
  local categories = {
    {
      name = 'Core Data & Storage',
      icon = '💾',
      desc = 'Cache, drafts, maildir, search, templates',
      tests = {
        { category = 'unit', pattern = 'test_cache' },
        { category = 'unit', pattern = 'test_drafts' },
        { category = 'unit', pattern = 'test_maildir' },
        { category = 'unit', pattern = 'test_search' },
        { category = 'unit', pattern = 'test_templates' },
        { category = 'features', pattern = 'test_maildir_foundation' },
        { category = 'features', pattern = 'test_maildir_integration' },
      }
    },
    {
      name = 'Email Operations',
      icon = '📧',
      desc = 'Composer, scheduler, commands',
      tests = {
        { category = 'unit', pattern = 'test_scheduler' },
        { category = 'features', pattern = 'test_email_composer' },
        { category = 'features', pattern = 'test_scheduler' },
        { category = 'features', pattern = 'test_draft_manager_maildir' },
        { category = 'commands', pattern = 'test_email_commands' },
        { category = 'commands', pattern = 'test_basic_commands' },
      }
    },
    {
      name = 'UI & Interface',
      icon = '🖥️',
      desc = 'UI components, session management',
      tests = {
        { category = 'unit', pattern = 'test_coordinator' },
        { category = 'unit', pattern = 'test_session' },
        { category = 'features', pattern = 'test_draft_commands_config' },
        { category = 'features', pattern = 'test_async_timing' },
      }
    },
    {
      name = 'Workflows & Integration',
      icon = '🔗',
      desc = 'End-to-end workflows and integration tests',
      tests = {
        { category = 'integration', pattern = 'test_draft_simple' },
        { category = 'integration', pattern = 'test_full_workflow' },
        { category = 'integration', pattern = 'test_email_operations_simple' },
        { category = 'integration', pattern = 'test_sync_simple' },
        { category = 'features', pattern = 'test_draft_saving' },
      }
    }
  }
  
  -- Add meaningful categories with enhanced metadata
  for _, cat in ipairs(categories) do
    local total_count = 0
    local missing_metadata = 0
    for _, test_spec in ipairs(cat.tests) do
      if M.tests[test_spec.category] then
        for _, test_info in ipairs(M.tests[test_spec.category]) do
          if test_info.name:match(test_spec.pattern) then
            local success, test_module = pcall(require, test_info.module_path)
            if success then
              if test_module.test_metadata and test_module.test_metadata.count then
                total_count = total_count + test_module.test_metadata.count
              else
                missing_metadata = missing_metadata + 1
                if test_module.tests and type(test_module.tests) == 'table' then
                  for _, _ in pairs(test_module.tests) do
                    total_count = total_count + 1
                  end
                else
                  total_count = total_count + 1
                end
              end
            else
              total_count = total_count + 1
              missing_metadata = missing_metadata + 1
            end
          end
        end
      end
    end
    
    if total_count > 0 then
      local display_text = string.format('%s (%d tests) • %s', cat.name, total_count, cat.desc)
      -- Add indicator if any tests are missing metadata
      if missing_metadata > 0 then
        display_text = display_text .. ' ⚠️'
      end
      table.insert(items, {
        text = display_text,
        value = cat,
        icon = cat.icon
      })
    end
  end
  
  -- Add original categories for fallback
  table.insert(items, { text = '─────────────────────────', value = nil, icon = '' })
  table.insert(items, { text = 'Original Categories:', value = nil, icon = '' })
  
  local original_suites = {
    { category = 'commands', name = 'Commands', icon = '📝' },
    { category = 'features', name = 'Features', icon = '✨' },
    { category = 'integration', name = 'Integration', icon = '🔗' },
    { category = 'performance', name = 'Performance', icon = '⚡' },
    { category = 'unit', name = 'Unit', icon = '🧪' },
  }
  
  for _, suite in ipairs(original_suites) do
    if M.tests[suite.category] and #M.tests[suite.category] > 0 then
      local count_info = M.get_category_count_info(suite.category)
      local display_text = string.format('%s (%d tests)', suite.name, count_info.total)
      
      -- Add metadata indicators
      if count_info.missing_metadata > 0 then
        display_text = display_text .. string.format(' [%d missing metadata]', count_info.missing_metadata)
      end
      
      table.insert(items, {
        text = display_text,
        value = suite.category,
        icon = suite.icon
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
    prompt_title = 'Select Test Suite',
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
  
  -- Don't show picker in test mode
  if _G.HIMALAYA_TEST_MODE then
    return
  end
  
  vim.ui.select(choices, {
    prompt = 'Select Test Suite:',
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
  -- Reset results before isolation
  M.reset_results()
  
  -- Show start notification
  if not _G.HIMALAYA_TEST_MODE then
    notify.himalaya('Starting tests...', notify.categories.STATUS)
  end
  
  -- Set flag to suppress print output from unit tests
  _G.HIMALAYA_TEST_RUNNER_ACTIVE = true
  
  -- Run test execution in isolation
  isolation.run_isolated(function()
    local start_time = vim.loop.hrtime()
    
    if selection == 'all' then
      M.run_all_tests()
    elseif type(selection) == 'string' then
      M.run_category_tests(selection)
    elseif type(selection) == 'table' and selection.tests then
      -- Running a custom category
      M.run_custom_category(selection)
    else
      M.run_single_test(selection)
    end
    
    -- Calculate duration
    M.results.duration = (vim.loop.hrtime() - start_time) / 1e6
  end)
  
  -- Clear the flag
  _G.HIMALAYA_TEST_RUNNER_ACTIVE = false
  
  -- Show results after isolation is complete
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

-- Run tests for a custom category
function M.run_custom_category(category_def)
  for _, test_spec in ipairs(category_def.tests) do
    if M.tests[test_spec.category] then
      for _, test_info in ipairs(M.tests[test_spec.category]) do
        if test_info.name:match(test_spec.pattern) then
          M.run_test(test_info)
        end
      end
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
  -- Clear module cache to ensure fresh version
  package.loaded[test_info.module_path] = nil
  
  -- Load and execute test
  local ok, test_module = pcall(require, test_info.module_path)
  
  if not ok then
    -- Try loading by path if module loading fails
    ok, test_module = pcall(dofile, test_info.path)
  end
  
  if ok and test_module then
    -- Direct metadata validation - no adapters
    if not test_module.test_metadata then
      -- TODO: Remove this warning after migration complete
      local notify = require('neotex.util.notifications')
      notify.himalaya(
        string.format("Test %s missing metadata - needs migration", test_info.name),
        notify.categories.WARNING
      )
    end
    
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
        local expected_count = test_module.test_metadata and test_module.test_metadata.count or test_count
        local total = result.total or expected_count
        local passed = result.passed or test_passed
        local failed = result.failed or test_failed
        
        -- Validate counts match metadata
        if test_module.test_metadata and total ~= expected_count then
          if not _G.HIMALAYA_TEST_MODE then
            local notify = require('neotex.util.notifications')
            notify.himalaya(
              string.format("Test count mismatch in %s: metadata says %d, execution says %d",
                test_info.name, expected_count, total),
              notify.categories.ERROR
            )
          end
        end
        
        -- Update results
        M.results.total = M.results.total + total
        M.results.passed = M.results.passed + passed
        M.results.failed = M.results.failed + failed
        
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
        -- Simple pass/fail result or boolean
        M.results.total = M.results.total + 1
        if result == true or (result ~= false and result ~= nil) then
          M.results.passed = M.results.passed + 1
        else
          M.results.failed = M.results.failed + 1
          
          -- Try to get more details if test module has test_results
          local details = 'Test returned false'
          if test_module.test_results and #test_module.test_results > 0 then
            local failures = {}
            for _, tr in ipairs(test_module.test_results) do
              if not tr.success then
                table.insert(failures, tr.name .. ': ' .. (tr.error or 'Failed'))
              end
            end
            if #failures > 0 then
              details = table.concat(failures, '; ')
            end
          end
          
          table.insert(M.results.errors, {
            test = test_info.name,
            category = test_info.category,
            type = 'failed',
            message = details
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
  local category = M.results.failed > 0 and notify.categories.ERROR or notify.categories.STATUS
  if not _G.HIMALAYA_TEST_MODE then
    notify.himalaya(string.format('Tests complete: %d/%d passed', M.results.passed, M.results.total), category)
  end
  
  -- Debug: Check if there are any background processes still running
  if M.results.passed == M.results.total then
    if not _G.HIMALAYA_TEST_MODE then
      notify.himalaya('All tests passed! (' .. M.results.passed .. '/' .. M.results.total .. ')', notify.categories.USER_ACTION)
    end
  end
  
  -- Show detailed results in floating window
  local buf, win = float.show('Test Results', lines)
  
  -- Ensure the float window has focus
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
    -- Ensure we're in normal mode in the results window
    vim.cmd('stopinsert')
  end
  
  -- Final cleanup: ensure all test buffers are cleaned up
  vim.defer_fn(function()
    M.cleanup_test_buffers()
    
    if M.results.passed == M.results.total then
      if not _G.HIMALAYA_TEST_MODE then
        notify.himalaya('Test execution completed - no background processes should be running', notify.categories.STATUS)
      end
    end
  end, 1000)
end

-- Global cleanup function for test buffers
function M.cleanup_test_buffers()
  local cleaned_buffers = 0
  
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      local lines = vim.api.nvim_buf_get_lines(buf, 0, 5, false)
      
      -- Check if this looks like a test buffer
      local is_test_buffer = false
      
      -- Check for test patterns
      if name and (name:match('compose') or name:match('test')) then
        is_test_buffer = true
      end
      
      -- Check for email headers in unnamed buffers
      if not name or name == '' then
        local content = table.concat(lines, '\n')
        if content:match('X%-Himalaya%-Account: TestAccount') or 
           content:match('Subject: Save Test') or 
           content:match('Subject: Test') or
           content:match('Subject: Existing Draft') or
           content:match('Draft to reopen') or
           content:match('From: Test User <test@example%.com>') or
           content:match('Subject: Draft Test Email') or
           content:match('From: test@example%.com') or
           content:match('To: recipient@example%.com') then
          is_test_buffer = true
        end
      end
      
      if is_test_buffer then
        -- Try to delete the buffer directly (this will work even if it's displayed)
        local ok, err = pcall(vim.api.nvim_buf_delete, buf, { force = true })
        if ok then
          cleaned_buffers = cleaned_buffers + 1
        else
          -- If deletion fails, try to switch to a different buffer first
          local current_buf = vim.api.nvim_get_current_buf()
          if current_buf == buf then
            -- Create a new empty buffer and switch to it
            local new_buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_set_current_buf(new_buf)
            
            -- Now try to delete the test buffer again
            local ok2, err2 = pcall(vim.api.nvim_buf_delete, buf, { force = true })
            if ok2 then
              cleaned_buffers = cleaned_buffers + 1
            end
          end
        end
      end
    end
  end
  
  if cleaned_buffers > 0 and not _G.HIMALAYA_TEST_MODE then
    notify.himalaya(string.format('Cleaned up %d test buffers', cleaned_buffers), notify.categories.STATUS)
  end
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
  
  -- Performance summary
  local framework = require('neotex.plugins.tools.himalaya.test.utils.test_framework')
  local perf_metrics = framework.performance.metrics
  
  if next(perf_metrics.test_durations) then
    table.insert(lines, '## Performance Summary')
    
    local total_duration = 0
    local perf_categories = { fast = 0, medium = 0, slow = 0, very_slow = 0 }
    
    for test_name, duration in pairs(perf_metrics.test_durations) do
      total_duration = total_duration + duration
      local category = framework.performance.categorize_performance(duration)
      perf_categories[category] = perf_categories[category] + 1
    end
    
    table.insert(lines, string.format('Total Test Duration: %.2f ms', total_duration))
    table.insert(lines, string.format('Average Test Duration: %.2f ms', total_duration / M.results.total))
    table.insert(lines, '')
    
    table.insert(lines, '### Performance Distribution')
    for category, count in pairs(perf_categories) do
      if count > 0 then
        local percentage = (count / M.results.total) * 100
        table.insert(lines, string.format('- %s: %d tests (%.1f%%)', 
          category, count, percentage))
      end
    end
    table.insert(lines, '')
  end
  
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

-- Count test functions in a specific category
function M.count_test_functions_in_category(category)
  local count = 0
  
  if not M.tests[category] then
    return 0
  end
  
  for _, test_info in ipairs(M.tests[category]) do
    local success, test_module = pcall(require, test_info.module_path)
    if success then
      -- Direct metadata access - no adapters
      if test_module.test_metadata and test_module.test_metadata.count then
        count = count + test_module.test_metadata.count
      else
        -- Temporary fallback during migration
        -- TODO: Remove after all tests have metadata
        if test_module.tests and type(test_module.tests) == 'table' then
          for _, _ in pairs(test_module.tests) do
            count = count + 1
          end
        else
          count = count + 1
        end
      end
    else
      -- Module loading failed
      count = count + 1
    end
  end
  
  return count
end

-- Remove the estimate_test_count function (no longer needed)

-- Get detailed count information for a category
function M.get_category_count_info(category)
  local total = 0
  local explicit = 0
  local missing_metadata = 0
  local has_mismatches = false
  
  if not M.tests[category] then
    return {
      total = 0,
      explicit = 0,
      missing_metadata = 0,
      has_mismatches = false
    }
  end
  
  for _, test_info in ipairs(M.tests[category]) do
    local success, test_module = pcall(require, test_info.module_path)
    if success then
      if test_module.test_metadata and test_module.test_metadata.count then
        total = total + test_module.test_metadata.count
        explicit = explicit + test_module.test_metadata.count
      else
        -- Test missing metadata
        missing_metadata = missing_metadata + 1
        if test_module.tests and type(test_module.tests) == 'table' then
          local actual = 0
          for _, _ in pairs(test_module.tests) do
            actual = actual + 1
          end
          total = total + actual
        else
          total = total + 1
        end
      end
    else
      -- Module loading failed
      total = total + 1
      missing_metadata = missing_metadata + 1
    end
  end
  
  return {
    total = total,
    explicit = explicit,
    missing_metadata = missing_metadata,
    has_mismatches = has_mismatches
  }
end

-- Count all tests with validation information
function M.count_all_tests_with_validation()
  local total = 0
  local validation_info = {
    has_missing_metadata = false,
    missing_metadata_count = 0,
    categories_with_issues = {}
  }
  
  for category, _ in pairs(M.tests) do
    local count_info = M.get_category_count_info(category)
    total = total + count_info.total
    
    if count_info.missing_metadata > 0 then
      validation_info.has_missing_metadata = true
      validation_info.missing_metadata_count = validation_info.missing_metadata_count + count_info.missing_metadata
      table.insert(validation_info.categories_with_issues, category)
    end
  end
  
  return total, validation_info
end

-- Enhanced count_all_test_functions with validation
function M.count_all_test_functions()
  local total = 0
  local validation_errors = {}
  
  for category, _ in pairs(M.tests) do
    local category_count = M.count_test_functions_in_category(category)
    total = total + category_count
    
    -- Optional: Add validation to catch discrepancies
    if M.config.validate_counts then
      local actual_count = M.validate_category_count(category)
      if actual_count ~= category_count then
        table.insert(validation_errors, {
          category = category,
          expected = category_count,
          actual = actual_count
        })
      end
    end
  end
  
  -- Report validation errors if any
  if #validation_errors > 0 and not _G.HIMALAYA_TEST_MODE then
    local notify = require('neotex.util.notifications')
    notify.himalaya("Test count validation failed", notify.categories.ERROR)
  end
  
  return total
end

return M