-- Process locking utilities using flock
-- Ensures only one sync process runs at a time

local M = {}

-- Lock file paths
M.LOCK_DIR = '/tmp'
M.LOCK_PREFIX = 'himalaya-mbsync-'

-- Get lock file path for a channel
function M.get_lock_path(channel)
  return M.LOCK_DIR .. '/' .. M.LOCK_PREFIX .. channel .. '.lock'
end

-- Wrap a command with flock
function M.wrap_command(cmd, channel)
  if type(cmd) == 'string' then
    cmd = {cmd}
  end
  
  local lock_file = channel and M.get_lock_path(channel) or M.LOCK_DIR .. '/mbsync-global.lock'
  
  -- Build flock command
  -- -n: non-blocking, fail if can't acquire lock
  -- -x: exclusive lock
  local flock_cmd = {
    'flock',
    '-n',  -- non-blocking
    '-x',  -- exclusive
    lock_file
  }
  
  -- Append the actual command
  for _, arg in ipairs(cmd) do
    table.insert(flock_cmd, arg)
  end
  
  return flock_cmd
end

-- Check if a lock is held
function M.is_locked(channel)
  local lock_file = channel and M.get_lock_path(channel) or M.LOCK_DIR .. '/mbsync-global.lock'
  
  -- Try to acquire lock non-blocking
  local cmd = string.format('flock -n %s -c "echo unlocked" 2>/dev/null', vim.fn.shellescape(lock_file))
  local result = os.execute(cmd)
  
  -- If we can acquire the lock, it wasn't locked
  return result ~= 0
end

-- Clean up stale locks
function M.cleanup_locks()
  local cleaned = 0
  
  -- Find all lock files
  local handle = io.popen('ls ' .. M.LOCK_DIR .. '/' .. M.LOCK_PREFIX .. '*.lock 2>/dev/null')
  if handle then
    local files = handle:read('*a')
    handle:close()
    
    for file in files:gmatch('[^\n]+') do
      -- Check if lock is stale by trying to acquire it
      local cmd = string.format('flock -n %s -c "echo cleaned" 2>/dev/null', vim.fn.shellescape(file))
      if os.execute(cmd) == 0 then
        -- Lock was acquired, so it was stale
        os.remove(file)
        cleaned = cleaned + 1
      end
    end
  end
  
  return cleaned
end

-- Get list of active locks
function M.get_active_locks()
  local locks = {}
  
  -- Check global lock
  if M.is_locked() then
    table.insert(locks, 'global')
  end
  
  -- Find channel-specific locks
  local handle = io.popen('ls ' .. M.LOCK_DIR .. '/' .. M.LOCK_PREFIX .. '*.lock 2>/dev/null')
  if handle then
    local files = handle:read('*a')
    handle:close()
    
    for file in files:gmatch('[^\n]+') do
      if M.is_locked(file:match(M.LOCK_PREFIX .. '(.+)%.lock$')) then
        local channel = file:match(M.LOCK_PREFIX .. '(.+)%.lock$')
        if channel then
          table.insert(locks, channel)
        end
      end
    end
  end
  
  return locks
end

-- Create a lock file manually (for testing)
function M.create_lock(channel)
  local lock_file = M.get_lock_path(channel)
  local handle = io.open(lock_file, 'w')
  if handle then
    handle:write(tostring(vim.fn.getpid()))
    handle:close()
    return true
  end
  return false
end

-- Remove a lock file manually (for cleanup)
function M.remove_lock(channel)
  local lock_file = M.get_lock_path(channel)
  return os.remove(lock_file) ~= nil
end

return M