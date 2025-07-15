-- Asynchronous Command Execution Module
-- Provides non-blocking command execution for Himalaya operations

local M = {}

-- Dependencies
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local config = require('neotex.plugins.tools.himalaya.core.config')

-- State management
M.command_queue = {}
M.running_jobs = {}
M.job_counter = 0
M.config = {
  max_concurrent = 1,       -- Reduced to 1 to prevent ID mapper conflicts  
  default_timeout = 60000,  -- 60 seconds (increased for lock waiting)
  retry_attempts = 3,       -- Increased retries for lock conflicts
  retry_delay = 2000,       -- 2 seconds
}

-- Job priorities
M.priorities = {
  user = 1,         -- User-initiated actions (highest priority)
  ui = 2,           -- UI updates
  background = 3,   -- Auto-sync, maintenance (lowest priority)
}

-- Generate unique job ID
local function generate_job_id()
  M.job_counter = M.job_counter + 1
  return string.format("himalaya_job_%d_%d", os.time(), M.job_counter)
end

-- Check if we can start a new job
local function can_start_job()
  local running_count = 0
  for _ in pairs(M.running_jobs) do
    running_count = running_count + 1
  end
  return running_count < M.config.max_concurrent
end

-- Get next job from queue
local function get_next_job()
  if #M.command_queue == 0 then
    return nil
  end
  
  -- Sort by priority (lower number = higher priority)
  table.sort(M.command_queue, function(a, b)
    return a.priority < b.priority
  end)
  
  return table.remove(M.command_queue, 1)
end

-- Process job queue
local function process_queue()
  while can_start_job() do
    local job = get_next_job()
    if not job then
      break
    end
    
    M.execute_job_now(job)
  end
end

-- Build Himalaya command with locking
local function build_command(args, opts)
  opts = opts or {}
  
  -- Get the executable path
  local executable = 'himalaya'
  if config and config.config and config.config.binaries and config.config.binaries.himalaya then
    executable = config.config.binaries.himalaya
  end
  
  -- Use flock to prevent concurrent Himalaya CLI access to ID mapper database
  local lock = require('neotex.plugins.tools.himalaya.sync.lock')
  local lock_file = '/tmp/himalaya-cli-global.lock'
  
  local cmd = {
    'flock',
    '-w', '30',  -- Wait up to 30 seconds for lock
    '-x',        -- Exclusive lock
    lock_file,
    executable
  }
  
  -- Separate query from other args
  local query = nil
  local clean_args = {}
  
  for i, arg in ipairs(args) do
    if arg:match('^order by') then
      query = arg
    else
      table.insert(clean_args, arg)
    end
  end
  
  -- Add the main arguments first
  vim.list_extend(cmd, clean_args)
  
  -- Add account specification if provided
  if opts.account then
    table.insert(cmd, '-a')
    table.insert(cmd, opts.account)
  end
  
  -- Add folder specification if provided
  if opts.folder and opts.folder ~= '' then
    table.insert(cmd, '-f')
    table.insert(cmd, opts.folder)
  end
  
  -- Add output format
  table.insert(cmd, '-o')
  table.insert(cmd, 'json')
  
  -- Add query last if present
  if query then
    table.insert(cmd, query)
  end
  
  return cmd
end

-- Execute job immediately
function M.execute_job_now(job)
  local job_id = job.id
  local cmd = build_command(job.args, job.opts)
  
  logger.debug('Starting async job: ' .. job_id .. ' with command: ' .. table.concat(cmd, ' '))
  
  -- Store job info
  M.running_jobs[job_id] = {
    job = job,
    start_time = os.time(),
    vim_job_id = nil,
    output_lines = {},
    error_lines = {},
  }
  
  -- Set timeout if specified
  local timeout_timer = nil
  if job.timeout and job.timeout > 0 then
    timeout_timer = vim.fn.timer_start(job.timeout, function()
      logger.warn('Job timeout: ' .. job_id)
      M.cancel_job(job_id, 'timeout')
    end)
  end
  
  -- Start the job
  local vim_job_id = vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    detach = false,  -- Keep job attached to Neovim
    
    on_stdout = function(_, data)
      if M.running_jobs[job_id] then
        -- Filter out empty lines that jobstart sometimes adds
        local filtered_data = {}
        for _, line in ipairs(data) do
          if line and line ~= '' then
            table.insert(filtered_data, line)
          end
        end
        vim.list_extend(M.running_jobs[job_id].output_lines, filtered_data)
      end
    end,
    
    on_stderr = function(_, data)
      if M.running_jobs[job_id] then
        -- Filter out empty lines
        local filtered_data = {}
        for _, line in ipairs(data) do
          if line and line ~= '' then
            table.insert(filtered_data, line)
          end
        end
        vim.list_extend(M.running_jobs[job_id].error_lines, filtered_data)
      end
    end,
    
    on_exit = function(_, exit_code)
      if timeout_timer then
        vim.fn.timer_stop(timeout_timer)
      end
      
      vim.schedule(function()
        M.handle_job_completion(job_id, exit_code)
      end)
    end,
  })
  
  if vim_job_id <= 0 then
    -- Job failed to start
    logger.error('Failed to start job: ' .. job_id)
    if timeout_timer then
      vim.fn.timer_stop(timeout_timer)
    end
    M.handle_job_completion(job_id, -1)
    return false
  end
  
  -- Store vim job ID for cancellation
  M.running_jobs[job_id].vim_job_id = vim_job_id
  
  return true
end

-- Handle job completion
function M.handle_job_completion(job_id, exit_code)
  local job_info = M.running_jobs[job_id]
  if not job_info then
    logger.warn('Completion for unknown job: ' .. job_id)
    return
  end
  
  local job = job_info.job
  local duration = os.time() - job_info.start_time
  
  logger.debug(string.format('Job completed: %s (exit: %d, duration: %ds)', 
    job_id, exit_code, duration))
  
  -- Clean up
  M.running_jobs[job_id] = nil
  
  -- Process results
  local success = exit_code == 0
  local result = nil
  local error_msg = nil
  
  if success then
    -- Parse JSON output
    local output = table.concat(job_info.output_lines, '\n')
    if output and output ~= '' then
      local parse_success, data = pcall(vim.json.decode, output)
      if parse_success then
        result = data
      else
        -- For some commands (like move, delete), success is indicated by exit code 0
        if job.args[1] == 'message' and (job.args[2] == 'move' or job.args[2] == 'delete') then
          result = true
        else
          success = false
          error_msg = 'Failed to parse JSON output: ' .. tostring(data)
        end
      end
    else
      -- Handle commands that don't return output
      if job.args[1] == 'message' and (job.args[2] == 'move' or job.args[2] == 'delete') then
        result = true
      else
        result = {}
      end
    end
  else
    -- Handle errors
    local error_output = table.concat(job_info.error_lines, '\n')
    
    -- Check for specific error conditions
    if error_output:match('cannot list maildir entries') then
      -- Empty maildir - not really an error
      success = true
      result = {}
    elseif error_output:match('out of bounds') then
      -- Pagination out of bounds - expected during binary search
      success = false
      result = nil
    elseif error_output:match('cannot open id mapper database') or 
           error_output:match('could not acquire lock') or
           error_output:match('Resource temporarily unavailable') then
      -- ID mapper database lock conflict - should retry
      error_msg = 'Database lock conflict - will retry'
      logger.warn('ID mapper lock conflict detected for job: ' .. job_id)
    else
      error_msg = error_output and error_output ~= '' and error_output or 'Command failed'
    end
  end
  
  -- Call the callback
  if job.callback then
    if success then
      job.callback(result, nil)
    else
      -- Check if we should retry (especially for lock conflicts)
      local should_retry = job.retry_count and job.retry_count < M.config.retry_attempts
      local is_lock_error = error_msg and error_msg:match('Database lock conflict')
      
      if should_retry and (is_lock_error or not error_msg:match('Database lock conflict')) then
        local retry_delay = is_lock_error and (M.config.retry_delay * (job.retry_count + 1)) or M.config.retry_delay
        logger.debug('Retrying job: ' .. job_id .. ' (attempt ' .. (job.retry_count + 1) .. ') after ' .. retry_delay .. 'ms')
        
        -- Create retry job
        local retry_job = vim.deepcopy(job)
        retry_job.id = generate_job_id()
        retry_job.retry_count = (job.retry_count or 0) + 1
        
        -- Add delay before retry
        vim.defer_fn(function()
          M.queue_command(retry_job.args, retry_job.opts, retry_job.callback, retry_job.priority, retry_job.timeout)
        end, retry_delay)
      else
        job.callback(nil, error_msg)
      end
    end
  end
  
  -- Process next job in queue
  process_queue()
end

-- Core async command executor
function M.execute_async(args, opts, callback)
  opts = opts or {}
  
  -- In test mode, return early to avoid CLI calls that will fail
  if _G.HIMALAYA_TEST_MODE then
    if type(callback) == 'function' then
      callback(nil, "Test mode: CLI calls disabled")
    end
    return nil
  end
  
  if type(callback) ~= 'function' then
    logger.error('execute_async requires a callback function')
    return nil
  end
  
  local job_id = generate_job_id()
  local priority = opts.priority or M.priorities.ui
  local timeout = opts.timeout or M.config.default_timeout
  
  local job = {
    id = job_id,
    args = args,
    opts = opts,
    callback = callback,
    priority = priority,
    timeout = timeout,
    retry_count = 0,
  }
  
  if can_start_job() then
    -- Execute immediately
    return M.execute_job_now(job)
  else
    -- Add to queue
    table.insert(M.command_queue, job)
    logger.debug('Queued job: ' .. job_id .. ' (queue size: ' .. #M.command_queue .. ')')
    return job_id
  end
end

-- Queue command with priority
function M.queue_command(args, opts, callback, priority, timeout)
  opts = opts or {}
  opts.priority = priority or M.priorities.ui
  opts.timeout = timeout
  
  return M.execute_async(args, opts, callback)
end

-- Cancel a job
function M.cancel_job(job_id, reason)
  local job_info = M.running_jobs[job_id]
  if not job_info then
    -- Maybe it's in the queue
    for i, queued_job in ipairs(M.command_queue) do
      if queued_job.id == job_id then
        table.remove(M.command_queue, i)
        logger.debug('Cancelled queued job: ' .. job_id .. ' (' .. (reason or 'user') .. ')')
        if queued_job.callback then
          queued_job.callback(nil, 'cancelled: ' .. (reason or 'user'))
        end
        return true
      end
    end
    return false
  end
  
  -- Stop the vim job
  if job_info.vim_job_id then
    vim.fn.jobstop(job_info.vim_job_id)
  end
  
  -- Clean up
  M.running_jobs[job_id] = nil
  
  logger.debug('Cancelled running job: ' .. job_id .. ' (' .. (reason or 'user') .. ')')
  
  -- Call callback with cancellation
  if job_info.job.callback then
    job_info.job.callback(nil, 'cancelled: ' .. (reason or 'user'))
  end
  
  -- Process next job
  process_queue()
  
  return true
end

-- Cancel all jobs
function M.cancel_all_jobs(reason)
  local cancelled_count = 0
  
  -- Cancel running jobs
  for job_id in pairs(M.running_jobs) do
    if M.cancel_job(job_id, reason) then
      cancelled_count = cancelled_count + 1
    end
  end
  
  -- Cancel queued jobs
  for _, job in ipairs(M.command_queue) do
    if job.callback then
      job.callback(nil, 'cancelled: ' .. (reason or 'shutdown'))
    end
    cancelled_count = cancelled_count + 1
  end
  M.command_queue = {}
  
  logger.debug('Cancelled ' .. cancelled_count .. ' jobs (' .. (reason or 'shutdown') .. ')')
  return cancelled_count
end

-- Get status information
function M.get_status()
  local running_count = 0
  for _ in pairs(M.running_jobs) do
    running_count = running_count + 1
  end
  
  return {
    running_jobs = running_count,
    queued_jobs = #M.command_queue,
    max_concurrent = M.config.max_concurrent,
    can_start_new = can_start_job(),
  }
end

-- Batch operations
function M.execute_batch(commands, callback)
  if not commands or #commands == 0 then
    if callback then callback({}, nil) end
    return
  end
  
  local results = {}
  local completed = 0
  local total = #commands
  local has_error = false
  
  local function check_completion()
    if completed == total then
      if callback then
        callback(has_error and nil or results, has_error and "One or more commands failed" or nil)
      end
    end
  end
  
  for i, cmd in ipairs(commands) do
    M.execute_async(cmd.args, cmd.opts, function(result, error)
      completed = completed + 1
      if error then
        has_error = true
        results[i] = { error = error }
      else
        results[i] = { result = result }
      end
      check_completion()
    end)
  end
end

return M