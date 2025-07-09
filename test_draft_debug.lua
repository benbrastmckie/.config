-- Debug script for draft saving test
local logger = require('neotex.plugins.tools.himalaya.core.logger')

-- Enable debug logging temporarily
logger.set_level('debug')

-- Run the draft saving test
local test_runner = require('neotex.plugins.tools.himalaya.scripts.test_runner')
test_runner.setup()

-- Get the draft saving test
local draft_test = nil
for _, test in ipairs(test_runner.tests.features) do
  if test.name == 'test_draft_saving' then
    draft_test = test
    break
  end
end

if draft_test then
  print("Running draft saving test with debug logging...")
  test_runner.execute_test_selection(draft_test)
else
  print("Draft saving test not found!")
end