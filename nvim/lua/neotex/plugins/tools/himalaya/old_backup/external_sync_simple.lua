-- Simplified External Sync Detection Module
-- Only detects external sync, no takeover functionality

local M = {}

local streamlined_sync = require('neotex.plugins.tools.himalaya.streamlined_sync')

-- Detection functions
function M.detect_external_sync()
  local status = streamlined_sync.get_status()
  
  -- Check if external sync is running (using the external_sync_running field)
  return status.external_sync_running
end

-- Check if we should show external sync status
function M.should_show_external_status()
  return M.detect_external_sync()
end

-- No setup needed for simplified version
function M.setup()
  -- Nothing to set up
end

return M