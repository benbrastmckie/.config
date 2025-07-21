-- Test Maildir Integration Suite
-- Orchestrates all maildir-related tests

local suite = require('neotex.plugins.tools.himalaya.test.utils.test_suite')

local M = suite.create_suite("Maildir Test Suite", {
  description = "Orchestrates all maildir-related tests",
  runs_tests = {
    "test_maildir_foundation",
    "test_draft_manager_maildir",
    "test_email_composer",
    "test_maildir_integration_cases"  -- New file with the 4 tests
  },
  category = "features",
  tags = {"maildir", "suite", "orchestration"}
})

-- Add test metadata to mark this as a suite (count = 0)
M.test_metadata = {
  name = "Maildir Test Suite",
  description = "Orchestrates all maildir-related tests",
  count = 0,  -- Suites contribute 0 to test count
  category = "features",
  tags = {"maildir", "suite", "orchestration"}
}

-- Dependencies
local notify = require('neotex.util.notifications')
local logger = require('neotex.plugins.tools.himalaya.core.logger')

-- Test results tracking
M.test_results = {
  foundation = {},
  draft_manager = {},
  composer = {},
  integration = {}
}

-- Run all maildir-related tests
function M.run()
  if not _G.HIMALAYA_TEST_MODE then
    notify.himalaya('Running Maildir Test Suite...', notify.categories.STATUS)
  end
  
  local start_time = vim.loop.hrtime()
  
  -- Run each test module
  local all_passed = true
  local total_tests = 0
  local passed_tests = 0
  local error_list = {}
  
  -- Test modules to run
  local test_modules = {
    {
      name = 'foundation',
      module = 'neotex.plugins.tools.himalaya.test.features.test_maildir_foundation'
    },
    {
      name = 'draft_manager',
      module = 'neotex.plugins.tools.himalaya.test.features.test_draft_manager_maildir'
    },
    {
      name = 'composer',
      module = 'neotex.plugins.tools.himalaya.test.features.test_email_composer'
    },
    {
      name = 'integration',
      module = 'neotex.plugins.tools.himalaya.test.features.test_maildir_integration_cases'
    }
  }
  
  -- Run each module
  for _, test_info in ipairs(test_modules) do
    local ok, test_module = pcall(require, test_info.module)
    if ok and test_module and test_module.run then
      local result = test_module.run()
      
      if type(result) == 'table' then
        total_tests = total_tests + (result.total or 0)
        passed_tests = passed_tests + (result.passed or 0)
        
        -- Store results
        M.test_results[test_info.name] = {
          success = result.success,
          total = result.total,
          passed = result.passed,
          failed = result.failed
        }
        
        -- Collect errors
        if result.errors then
          for _, error in ipairs(result.errors) do
            table.insert(error_list, {
              test = string.format('[%s] %s', test_info.name, error.test),
              error = error.error or error.message
            })
          end
        end
        
        if not result.success then
          all_passed = false
        end
      else
        -- Simple boolean result
        all_passed = all_passed and result
      end
    else
      logger.error('Failed to load test module', { module = test_info.module })
      all_passed = false
    end
  end
  
  local elapsed = (vim.loop.hrtime() - start_time) / 1e9
  
  -- Return aggregated results
  return {
    total = total_tests,
    passed = passed_tests,
    failed = total_tests - passed_tests,
    errors = error_list,
    success = all_passed,
    duration = elapsed
  }
end

return M