-- Test Suite Infrastructure
-- Provides clear distinction between test files and test suites

local M = {}

-- Marker for test suites
M.SUITE_MARKER = "TEST_SUITE"

-- Create a test suite definition
function M.create_suite(name, config)
  return {
    [M.SUITE_MARKER] = true,
    name = name,
    description = config.description,
    runs_tests = config.runs_tests or {},
    category = config.category or "suites",
    tags = config.tags or {"suite"}
  }
end

-- Check if a module is a test suite
function M.is_suite(module)
  return module and module[M.SUITE_MARKER] == true
end

return M