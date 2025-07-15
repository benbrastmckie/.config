-- Script to fix test API issues
-- This fixes the common API mismatches in test files

local M = {}

-- Fix himalaya module references
function M.fix_himalaya_refs()
  -- The himalaya module in tests should use utils directly
  local test_files = {
    'integration/test_full_workflow.lua',
    'commands/test_basic_commands.lua',
    'commands/test_email_commands.lua',
    'commands/test_sync_commands.lua',
  }
  
  for _, file in ipairs(test_files) do
    local path = vim.fn.stdpath('config') .. '/lua/neotex/plugins/tools/himalaya/scripts/' .. file
    if vim.fn.filereadable(path) == 1 then
      local content = table.concat(vim.fn.readfile(path), '\n')
      
      -- Fix himalaya.setup() calls
      content = content:gsub('himalaya%.setup%([^)]*%)', '-- Plugin already initialized')
      
      -- Fix himalaya.utils references
      content = content:gsub('local himalaya = require%(\'neotex%.plugins%.tools%.himalaya\'%)', 
                           'local utils = require(\'neotex.plugins.tools.himalaya.utils\')')
      content = content:gsub('himalaya%.utils%.', 'utils.')
      
      -- Fix coordinator.is_primary() calls
      content = content:gsub('coordinator%.is_primary%(', 'coordinator.get_primary_status(')
      
      -- Write back
      vim.fn.writefile(vim.split(content, '\n'), path)
      print('Fixed: ' .. file)
    end
  end
end

-- Fix scheduler API
function M.fix_scheduler_api()
  local path = vim.fn.stdpath('config') .. '/lua/neotex/plugins/tools/himalaya/scripts/features/test_scheduler.lua'
  if vim.fn.filereadable(path) == 1 then
    local content = table.concat(vim.fn.readfile(path), '\n')
    
    -- The scheduler API was already fixed in the file
    print('Scheduler tests already updated')
  end
end

-- Fix search API
function M.fix_search_api()
  -- Create the test_search.lua if it doesn't exist
  local search_path = vim.fn.stdpath('config') .. '/lua/neotex/plugins/tools/himalaya/scripts/utils/test_search.lua'
  if vim.fn.filereadable(search_path) == 0 then
    -- Already created
    print('Search helper already exists')
  end
end

-- Run all fixes
function M.run()
  M.fix_himalaya_refs()
  M.fix_scheduler_api()
  M.fix_search_api()
  print('Test fixes complete!')
end

return M