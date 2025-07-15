-- Test Mocks for Himalaya Plugin
-- Provides mock implementations to prevent real command execution during tests

local M = {}

-- Store original functions
M.originals = {}

-- Mock execute_himalaya to prevent real CLI calls
function M.mock_execute_himalaya()
  local utils = require('neotex.plugins.tools.himalaya.utils')
  
  -- Store original if not already stored
  if not M.originals.execute_himalaya then
    M.originals.execute_himalaya = utils.execute_himalaya
  end
  
  -- Replace with mock
  utils.execute_himalaya = function(args, opts)
    local cmd = args[1]
    local subcmd = args[2]
    
    -- Return appropriate mock data based on command
    if cmd == 'envelope' and subcmd == 'list' then
      -- Return empty email list
      return {}
    elseif cmd == 'folder' and subcmd == 'list' then
      -- Return basic folder list
      return { 'INBOX', 'Sent', 'Drafts', 'Trash' }
    elseif cmd == 'account' and subcmd == 'list' then
      -- Return test account
      return { { name = 'test', email = 'test@example.com' } }
    else
      -- Return empty result for other commands
      return {}
    end
  end
end

-- Mock execute_himalaya_async to prevent real CLI calls
function M.mock_execute_himalaya_async()
  local utils = require('neotex.plugins.tools.himalaya.utils')
  
  -- Store original if not already stored
  if not M.originals.execute_himalaya_async then
    M.originals.execute_himalaya_async = utils.execute_himalaya_async
  end
  
  -- Replace with mock
  utils.execute_himalaya_async = function(args, opts, callback)
    -- Simulate async callback with mock data
    vim.defer_fn(function()
      local result = utils.execute_himalaya(args, opts)
      if callback then
        callback(result)
      end
    end, 10)
  end
end

-- Mock scheduler to prevent timer interference
function M.mock_scheduler()
  local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
  
  -- Store original state
  if not M.originals.scheduler then
    M.originals.scheduler = {
      timer = scheduler.timer,
      queue = vim.deepcopy(scheduler.queue),
      start_processing = scheduler.start_processing,
      stop_processing = scheduler.stop_processing
    }
  end
  
  -- Stop any running timer
  if scheduler.timer then
    scheduler.stop_processing()
  end
  
  -- Clear queue
  scheduler.queue = {}
  
  -- Replace with no-op functions
  scheduler.start_processing = function() end
  scheduler.stop_processing = function() end
end

-- Setup all mocks
function M.setup()
  M.mock_execute_himalaya()
  M.mock_execute_himalaya_async()
  M.mock_scheduler()
end

-- Restore all original functions
function M.teardown()
  local utils = require('neotex.plugins.tools.himalaya.utils')
  
  if M.originals.execute_himalaya then
    utils.execute_himalaya = M.originals.execute_himalaya
  end
  
  if M.originals.execute_himalaya_async then
    utils.execute_himalaya_async = M.originals.execute_himalaya_async
  end
  
  -- Restore scheduler
  if M.originals.scheduler then
    local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
    scheduler.timer = M.originals.scheduler.timer
    scheduler.queue = M.originals.scheduler.queue
    scheduler.start_processing = M.originals.scheduler.start_processing
    scheduler.stop_processing = M.originals.scheduler.stop_processing
    
    -- Restart if it was running
    if M.originals.scheduler.timer then
      scheduler.start_processing()
    end
  end
  
  -- Clear stored originals
  M.originals = {}
end

return M