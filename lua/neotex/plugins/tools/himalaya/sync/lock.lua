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
  local cmd = string.format('flock -n %s -c "exit 0" 2>/dev/null', vim.fn.shellescape(lock_file))
  local result = os.execute(cmd)
  
  -- If we can acquire the lock, it wasn't locked
  return result ~= 0
end

-- Clean up stale locks
function M.cleanup_locks()
  local cleaned = 0
  
  -- Find all himalaya lock files
  local handle = io.popen('ls ' .. M.LOCK_DIR .. '/' .. M.LOCK_PREFIX .. '*.lock 2>/dev/null')
  if handle then
    local files = handle:read('*a')
    handle:close()
    
    for file in files:gmatch('[^\n]+') do
      -- Try to acquire the lock to check if it's stale
      local test_cmd = string.format('flock -n -x %s -c "exit 0" 2>/dev/null', vim.fn.shellescape(file))
      if os.execute(test_cmd) == 0 then
        -- Lock was successfully acquired, so it's not held by any process
        -- This means it's a stale lock file that can be removed
        os.remove(file)
        cleaned = cleaned + 1
      end
    end
  end
  
  -- Also check the global mbsync lock
  local global_lock = M.LOCK_DIR .. '/mbsync-global.lock'
  if vim.fn.filereadable(global_lock) == 1 then
    local test_cmd = string.format('flock -n -x %s -c "exit 0" 2>/dev/null', vim.fn.shellescape(global_lock))
    if os.execute(test_cmd) == 0 then
      os.remove(global_lock)
      cleaned = cleaned + 1
    end
  end
  
  return cleaned
end

-- Get list of active locks
function M.get_active_locks()
  local locks = {}
  
  -- Find all lock files
  local handle = io.popen('ls ' .. M.LOCK_DIR .. '/' .. M.LOCK_PREFIX .. '*.lock 2>/dev/null')
  if handle then
    local files = handle:read('*a')
    handle:close()
    
    for file in files:gmatch('[^\n]+') do
      -- Extract channel name from filename
      local channel = file:match(M.LOCK_PREFIX .. '(.+)%.lock$')
      if channel then
        -- Check if this specific lock is actually held by a process
        if M.is_locked(channel) then
          table.insert(locks, channel)
        end
      end
    end
  end
  
  -- Also check the global lock
  local global_lock = M.LOCK_DIR .. '/mbsync-global.lock'
  if vim.fn.filereadable(global_lock) == 1 then
    -- Try to acquire it to see if it's stale
    local cmd = string.format('flock -n %s -c "exit 0" 2>/dev/null', vim.fn.shellescape(global_lock))
    if os.execute(cmd) ~= 0 then
      -- Lock is held
      table.insert(locks, 'global')
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