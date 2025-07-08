local M = {}
local persistence = require('neotex.plugins.tools.himalaya.core.persistence')
local state = require('neotex.plugins.tools.himalaya.core.state')
local notify = require('neotex.util.notifications')

-- Coordination configuration
M.config = {
  coordination_file = vim.fn.expand('~/.config/himalaya/sync_coordinator.json'),
  heartbeat_interval = 30,      -- 30 seconds
  takeover_threshold = 60,      -- Consider primary dead after 60 seconds
  sync_cooldown = 300,          -- Minimum 5 minutes between syncs
}

-- Instance state
M.instance_id = nil
M.is_primary = false
M.heartbeat_timer = nil

-- Initialize coordination
function M.init()
  M.instance_id = persistence.get_instance_id()
  M.ensure_coordination_file()
  M.check_primary_status()
  M.start_heartbeat()
end

-- Check if this instance should be primary
function M.check_primary_status()
  local coord_data = M.read_coordination_file()
  local now = os.time()
  
  -- Check if current primary is alive
  if coord_data.primary then
    local last_heartbeat = coord_data.primary.last_heartbeat or 0
    local is_stale = (now - last_heartbeat) > M.config.takeover_threshold
    
    if not is_stale and coord_data.primary.instance_id ~= M.instance_id then
      -- Another instance is primary and alive
      M.is_primary = false
      return false
    end
  end
  
  -- Become primary
  M.become_primary()
  return true
end

-- Become the primary sync coordinator
function M.become_primary()
  local coord_data = M.read_coordination_file()
  
  coord_data.primary = {
    instance_id = M.instance_id,
    last_heartbeat = os.time(),
    pid = vim.fn.getpid(),
    nvim_version = vim.version().major .. '.' .. vim.version().minor
  }
  
  M.write_coordination_file(coord_data)
  M.is_primary = true
  
  -- Only show notification in debug mode
  if notify.config.modules.himalaya.debug_mode then
    notify.himalaya('This instance is now the primary sync coordinator', 
                   notify.categories.BACKGROUND)
  end
end

-- Send heartbeat if primary
function M.send_heartbeat()
  if not M.is_primary then
    -- Check if we should take over
    M.check_primary_status()
    return
  end
  
  local coord_data = M.read_coordination_file()
  
  -- Update our heartbeat
  if coord_data.primary and coord_data.primary.instance_id == M.instance_id then
    coord_data.primary.last_heartbeat = os.time()
    M.write_coordination_file(coord_data)
  else
    -- We lost primary status
    M.is_primary = false
  end
end

-- Check if a sync should be allowed
function M.should_allow_sync()
  local coord_data = M.read_coordination_file()
  local now = os.time()
  
  -- Check last sync time across all instances
  local last_sync = coord_data.last_sync_time or 0
  local time_since_sync = now - last_sync
  
  -- Enforce cooldown period
  if time_since_sync < M.config.sync_cooldown then
    local remaining = M.config.sync_cooldown - time_since_sync
    
    if notify.config.modules.himalaya.debug_mode then
      notify.himalaya(string.format('Sync cooldown active: %d seconds remaining', remaining),
                     notify.categories.BACKGROUND)
    end
    
    return false
  end
  
  -- Only primary instance should initiate auto-sync
  return M.is_primary
end

-- Record sync completion
function M.record_sync_completion()
  local coord_data = M.read_coordination_file()
  coord_data.last_sync_time = os.time()
  coord_data.last_sync_instance = M.instance_id
  M.write_coordination_file(coord_data)
end

-- Clean up on exit
function M.cleanup()
  if M.heartbeat_timer then
    M.heartbeat_timer:stop()
    M.heartbeat_timer:close()
  end
  
  -- If we're primary, clear our status
  if M.is_primary then
    local coord_data = M.read_coordination_file()
    if coord_data.primary and coord_data.primary.instance_id == M.instance_id then
      coord_data.primary = nil
      M.write_coordination_file(coord_data)
    end
  end
end

-- Helper functions
function M.ensure_coordination_file()
  local dir = vim.fn.fnamemodify(M.config.coordination_file, ':h')
  vim.fn.mkdir(dir, 'p')
  
  if vim.fn.filereadable(M.config.coordination_file) == 0 then
    M.write_coordination_file({
      version = "1.0",
      created = os.time(),
      primary = nil,
      last_sync_time = 0
    })
  end
end

function M.read_coordination_file()
  local content = vim.fn.readfile(M.config.coordination_file)
  if #content > 0 then
    local ok, data = pcall(vim.fn.json_decode, content[1])
    if ok then return data end
  end
  return { last_sync_time = 0 }
end

function M.write_coordination_file(data)
  data.last_modified = os.time()
  local encoded = vim.fn.json_encode(data)
  vim.fn.writefile({encoded}, M.config.coordination_file)
end

function M.start_heartbeat()
  M.heartbeat_timer = vim.loop.new_timer()
  M.heartbeat_timer:start(0, M.config.heartbeat_interval * 1000, vim.schedule_wrap(function()
    M.send_heartbeat()
  end))
end

return M