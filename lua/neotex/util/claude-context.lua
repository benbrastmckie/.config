-- Claude Code Context Reader Module
-- Reads context usage data from /tmp/claude-context.json pushed by Claude hook
local M = {}

-- Configuration
local CONTEXT_FILE = "/tmp/claude-context.json"
local CACHE_TTL_MS = 500 -- Cache validity in milliseconds

-- State
local cache = {
  data = nil,
  timestamp = 0,
}
local watcher = nil
local initialized = false

--- Parse the context JSON file
--- @return table|nil Parsed context data or nil on error
local function parse_context_file()
  local file = io.open(CONTEXT_FILE, "r")
  if not file then
    return nil
  end

  local content = file:read("*all")
  file:close()

  if not content or content == "" then
    return nil
  end

  local ok, data = pcall(vim.json.decode, content)
  if not ok or type(data) ~= "table" then
    return nil
  end

  return data
end

--- Invalidate the cache (called by file watcher)
function M.invalidate_cache()
  cache.timestamp = 0
end

--- Get current context data (with caching)
--- @return table|nil Context data with fields: context_used, context_limit, percentage, model, cost
function M.get_context()
  local now = vim.uv.now()

  -- Return cached data if still valid
  if cache.data and (now - cache.timestamp) < CACHE_TTL_MS then
    return cache.data
  end

  -- Parse and cache
  local data = parse_context_file()
  if data then
    cache.data = data
    cache.timestamp = now
  end

  return cache.data
end

--- Get formatted percentage string
--- @return string Percentage string like "42%" or empty string
function M.get_percentage_str()
  local ctx = M.get_context()
  if not ctx or not ctx.percentage then
    return ""
  end
  return string.format("%d%%", math.floor(ctx.percentage))
end

--- Get formatted token count string
--- @return string Token string like "85k/200k" or empty string
function M.get_tokens_str()
  local ctx = M.get_context()
  if not ctx or not ctx.context_used or not ctx.context_limit then
    return ""
  end
  local used_k = math.floor(ctx.context_used / 1000)
  local limit_k = math.floor(ctx.context_limit / 1000)
  return string.format("%dk/%dk", used_k, limit_k)
end

--- Get model name (cleaned up)
--- @return string Model name or empty string
function M.get_model()
  local ctx = M.get_context()
  if not ctx or not ctx.model then
    return ""
  end
  -- Capitalize first letter for display
  local model = ctx.model
  if model and #model > 0 then
    return model:sub(1, 1):upper() .. model:sub(2)
  end
  return model
end

--- Get formatted cost string
--- @return string Cost string like "$0.31" or empty string
function M.get_cost_str()
  local ctx = M.get_context()
  if not ctx or not ctx.cost then
    return ""
  end
  return string.format("$%.2f", ctx.cost)
end

--- Get usage level based on percentage thresholds
--- @return string "low" (<50%), "medium" (50-80%), "high" (>80%), or "unknown"
function M.get_usage_level()
  local ctx = M.get_context()
  if not ctx or not ctx.percentage then
    return "unknown"
  end

  local pct = ctx.percentage
  if pct < 50 then
    return "low"
  elseif pct < 80 then
    return "medium"
  else
    return "high"
  end
end

--- Create a progress bar string
--- @param width number Width of the bar in characters (default 10)
--- @return string Progress bar like "████░░░░░░"
function M.get_progress_bar(width)
  width = width or 10
  local ctx = M.get_context()
  if not ctx or not ctx.percentage then
    return string.rep("░", width)
  end

  local filled = math.floor(ctx.percentage * width / 100)
  filled = math.min(filled, width) -- Cap at width
  local empty = width - filled

  return string.rep("█", filled) .. string.rep("░", empty)
end

--- Setup file watcher for context file
function M.setup()
  if initialized then
    return
  end
  initialized = true

  -- Create file watcher using vim.uv (libuv)
  local function start_watcher()
    -- Stop existing watcher if any
    if watcher then
      watcher:stop()
      watcher = nil
    end

    -- Check if file exists
    local stat = vim.uv.fs_stat(CONTEXT_FILE)
    if not stat then
      -- File doesn't exist yet, try again later
      vim.defer_fn(start_watcher, 5000)
      return
    end

    -- Create new watcher
    watcher = vim.uv.new_fs_event()
    if not watcher then
      return
    end

    local ok, err = watcher:start(CONTEXT_FILE, {}, function(err, filename, events)
      if err then
        return
      end
      -- Invalidate cache on any file change
      vim.schedule(function()
        M.invalidate_cache()
      end)
    end)

    if not ok then
      -- Watcher failed, will rely on FocusGained fallback
      watcher = nil
    end
  end

  -- Start watcher (with retry for file not existing yet)
  start_watcher()

  -- FocusGained fallback autocommand
  local group = vim.api.nvim_create_augroup("ClaudeContextWatcher", { clear = true })
  vim.api.nvim_create_autocmd("FocusGained", {
    group = group,
    callback = function()
      M.invalidate_cache()
    end,
  })

  -- Also invalidate on BufEnter for Claude terminals
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    pattern = "*",
    callback = function()
      if vim.bo.buftype == "terminal" then
        local bufname = vim.api.nvim_buf_get_name(0)
        if bufname:match("claude") or bufname:match("ClaudeCode") then
          M.invalidate_cache()
        end
      end
    end,
  })
end

--- Check if context data is available
--- @return boolean True if context data exists
function M.has_context()
  return M.get_context() ~= nil
end

return M
