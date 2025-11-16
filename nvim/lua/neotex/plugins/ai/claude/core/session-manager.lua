-- Session Manager for Claude AI integration
-- Provides robust session validation, state management, and error handling
-- Consolidates session logic into single authoritative module

local M = {}
local Path = require("plenary.path")
local notify = require("neotex.util.notifications")

-- Session validation patterns
local UUID_PATTERN = "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$"
local SESSION_ID_PATTERN = "^[a-zA-Z0-9-_]+$"

-- State file location
local state_dir = vim.fn.stdpath("data") .. "/claude"
local state_file = state_dir .. "/last_session.json"

-- Debug logging
local DEBUG = false
local function log_debug(...)
  if DEBUG then
    local msg = string.format(...)
    vim.notify("[Session Manager Debug] " .. msg, vim.log.levels.DEBUG)
  end
end

-- Ensure state directory exists
local function ensure_state_dir()
  local dir = Path:new(state_dir)
  if not dir:exists() then
    dir:mkdir({ parents = true })
  end
end

--- Validate session ID format
--- @param session_id string The session ID to validate
--- @return boolean valid Whether the session ID is valid
--- @return string? error_message Error message if invalid
function M.validate_session_id(session_id)
  if not session_id or session_id == "" then
    return false, "Session ID is empty"
  end

  -- Check if it's a valid UUID
  if session_id:match(UUID_PATTERN) then
    log_debug("Session ID is valid UUID: %s", session_id)
    return true
  end

  -- Check if it matches general session ID pattern
  if session_id:match(SESSION_ID_PATTERN) then
    log_debug("Session ID matches general pattern: %s", session_id)
    return true
  end

  return false, string.format("Invalid session ID format: %s", session_id)
end

--- Check if session file exists and is readable
--- @param session_id string The session ID to check
--- @return boolean exists Whether the session file exists
--- @return string? error_message Error message if not found
function M.validate_session_file(session_id)
  -- Get project folder for session files
  local native_sessions = require("neotex.plugins.ai.claude.ui.native-sessions")
  local project_folder = native_sessions.get_project_folder()

  if not project_folder then
    return false, "Could not determine project folder"
  end

  local session_file = project_folder .. "/" .. session_id .. ".jsonl"
  local file_exists = vim.fn.filereadable(session_file) == 1

  if file_exists then
    log_debug("Session file exists: %s", session_file)
    return true
  else
    return false, string.format("Session file not found: %s", session_file)
  end
end

--- Test Claude CLI compatibility with session resumption
--- @param session_id string The session ID to test
--- @return boolean compatible Whether CLI can handle the session ID
--- @return string? error_message Error message if incompatible
function M.validate_cli_compatibility(session_id)
  -- First validate the ID format
  local valid, err = M.validate_session_id(session_id)
  if not valid then
    return false, err
  end

  -- Test if claude CLI is available
  local cli_test = vim.fn.system("claude --version 2>&1")
  if vim.v.shell_error ~= 0 then
    return false, "Claude CLI not found or not functional"
  end

  -- We can't actually test resume without side effects, but we've validated:
  -- 1. Session ID format is valid
  -- 2. Claude CLI is available
  log_debug("CLI compatibility check passed for session: %s", session_id)
  return true
end

--- Comprehensive session validation
--- @param session_id string The session ID to validate
--- @return boolean valid Whether the session is valid for resumption
--- @return table? errors Table of error messages if invalid
function M.validate_session(session_id)
  local errors = {}
  local has_errors = false

  -- Validate ID format
  local valid, err = M.validate_session_id(session_id)
  if not valid then
    table.insert(errors, err)
    has_errors = true
  end

  -- Validate file existence
  valid, err = M.validate_session_file(session_id)
  if not valid then
    table.insert(errors, err)
    has_errors = true
  end

  -- Validate CLI compatibility
  valid, err = M.validate_cli_compatibility(session_id)
  if not valid then
    table.insert(errors, err)
    has_errors = true
  end

  if has_errors then
    return false, errors
  end

  log_debug("Session validation successful: %s", session_id)
  return true
end

--- Enhanced error capture and propagation
--- @param func function The function to execute with error capture
--- @param context string Context for error reporting
--- @return boolean success Whether the function executed successfully
--- @return any result The function result or error details
function M.capture_errors(func, context)
  -- Use xpcall for detailed error capture
  local success, result = xpcall(func, function(err)
    -- Capture full stack trace
    local trace = debug.traceback(err, 2)
    return {
      error = err,
      context = context,
      traceback = trace
    }
  end)

  if not success then
    -- Log detailed error information
    log_debug("Error in %s: %s", context, vim.inspect(result))

    -- Create user-friendly error message
    local error_msg = result.error
    if type(error_msg) == "table" then
      error_msg = vim.inspect(error_msg)
    end

    notify.notify(
      string.format("Session operation failed: %s", error_msg),
      notify.categories.ERROR,
      {
        module = "ai-claude",
        context = context,
        details = result.traceback
      }
    )

    return false, result
  end

  return true, result
end

--- Detect Claude terminal buffers with precision
--- @return table buffers List of Claude buffer numbers
function M.detect_claude_buffers()
  local claude_buffers = {}

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local bufname = vim.api.nvim_buf_get_name(bufnr)
      local buftype = vim.api.nvim_buf_get_option(bufnr, 'buftype')

      -- Check if it's a terminal buffer
      if buftype == 'terminal' then
        -- Check if the buffer name contains claude-related patterns
        -- But be more specific than just matching "claude"
        if bufname:match('term://.*claude') or
           bufname:match('ClaudeCode') or
           bufname:match('claude%-code') then
          -- Additional verification: check if terminal is still active
          local channel = vim.api.nvim_buf_get_option(bufnr, 'channel')
          if channel and channel > 0 then
            table.insert(claude_buffers, bufnr)
            log_debug("Found Claude buffer: %d (%s)", bufnr, bufname)
          end
        end
      end
    end
  end

  return claude_buffers
end

--- Check if a specific buffer is a Claude buffer
--- @param bufnr number Buffer number to check
--- @return boolean is_claude Whether this is a Claude buffer
function M.is_claude_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local buftype = vim.api.nvim_buf_get_option(bufnr, 'buftype')

  -- Must be a terminal buffer
  if buftype ~= 'terminal' then
    return false
  end

  -- Check for Claude-specific patterns
  if not (bufname:match('term://.*claude') or
          bufname:match('ClaudeCode') or
          bufname:match('claude%-code')) then
    return false
  end

  -- Verify terminal is active
  local channel = vim.api.nvim_buf_get_option(bufnr, 'channel')
  return channel and channel > 0
end

--- Validate state file integrity
--- @return boolean valid Whether the state file is valid
--- @return table? state The state data if valid
function M.validate_state_file()
  local file = io.open(state_file, "r")
  if not file then
    log_debug("No state file found")
    return false, nil
  end

  local content = file:read("*all")
  file:close()

  if content == "" then
    log_debug("State file is empty")
    return false, nil
  end

  -- Try to decode JSON
  local ok, state = pcall(vim.fn.json_decode, content)
  if not ok then
    log_debug("State file is corrupted: %s", state)
    -- Attempt to clean up corrupted file
    M.cleanup_state_file()
    return false, nil
  end

  -- Validate state structure
  if not state.timestamp or not state.cwd then
    log_debug("State file missing required fields")
    return false, nil
  end

  -- Check if state is too old (>7 days)
  local age_days = (os.time() - state.timestamp) / 86400
  if age_days > 7 then
    log_debug("State file is too old: %.1f days", age_days)
    M.cleanup_state_file()
    return false, nil
  end

  return true, state
end

--- Clean up corrupted or stale state files
function M.cleanup_state_file()
  local file = io.open(state_file, "r")
  if file then
    file:close()
    -- Backup the corrupted file
    local backup_file = state_file .. ".backup." .. os.time()
    vim.fn.rename(state_file, backup_file)
    log_debug("Backed up corrupted state file to: %s", backup_file)
  end
end

--- Resume a session with comprehensive validation and error handling
--- @param session_id string The session ID to resume
--- @return boolean success Whether the session was resumed successfully
--- @return string? error_message Error message if failed
function M.resume_session(session_id)
  log_debug("Attempting to resume session: %s", session_id)

  -- Validate session before attempting resume
  local valid, errors = M.validate_session(session_id)
  if not valid then
    local error_msg = "Session validation failed:\n" .. table.concat(errors or {}, "\n")
    log_debug("Validation failed: %s", error_msg)
    notify.notify(
      error_msg,
      notify.categories.ERROR,
      { module = "ai-claude", action = "resume_session" }
    )
    return false, error_msg
  end

  log_debug("Session validation passed, executing resume command")
  notify.notify(
    string.format("Resuming session: %s...", session_id:sub(1, 8)),
    notify.categories.USER_ACTION,
    { module = "ai-claude", action = "resume_session" }
  )

  -- Direct command execution with fallback
  local command = "claude --resume " .. session_id
  local success = false

  -- Check if Claude Code is already open and close it first to ensure clean session switch
  local claude_buffers = M.detect_claude_buffers()
  if #claude_buffers > 0 then
    log_debug("Closing existing Claude buffers before session switch")
    -- Close all Claude buffers
    for _, bufnr in ipairs(claude_buffers) do
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_delete(bufnr, { force = true })
      end
    end
    -- Wait a moment for buffers to close
    vim.wait(100)
  end

  -- First try using open_with_command from claude-code utils
  local claude_util_ok, claude_util = pcall(require, "neotex.plugins.ai.claude.claude-session.claude-code")
  if claude_util_ok and claude_util.open_with_command then
    success = claude_util.open_with_command(command)
  end

  -- Fallback: try direct plugin API if available
  if not success then
    log_debug("Primary method failed, trying fallback")
    local claude_code_ok, claude_code = pcall(require, "claude-code")
    if claude_code_ok and claude_code.config then
      local original_cmd = claude_code.config.command
      claude_code.config.command = command
      local toggle_ok = pcall(claude_code.toggle)
      claude_code.config.command = original_cmd
      success = toggle_ok
    end
  end

  if success then
    log_debug("Session resume successful")
    notify.notify(
      string.format("Successfully resumed session: %s", session_id:sub(1, 8)),
      notify.categories.USER_ACTION,
      { module = "ai-claude", action = "resume_session" }
    )

    -- Save state after successful resume
    M.save_state({
      last_resumed_session = session_id,
      timestamp = os.time()
    })

    return true
  else
    log_debug("Session resume failed")
    return false, "Failed to resume session - command execution failed"
  end
end

--- Enable or disable debug logging
--- @param enabled boolean Whether to enable debug logging
function M.set_debug(enabled)
  DEBUG = enabled
  log_debug("Debug logging %s", enabled and "enabled" or "disabled")
end

--- Save session state with validation
--- @param state table State data to save
--- @return boolean success Whether state was saved successfully
function M.save_state(state)
  ensure_state_dir()

  -- Add metadata to state
  state.timestamp = state.timestamp or os.time()
  state.version = 1  -- State file version for future migration

  -- Validate state before saving
  if not state.cwd then
    state.cwd = vim.fn.getcwd()
  end

  -- Add git information if available
  state.git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
  state.branch = vim.fn.system("git branch --show-current 2>/dev/null"):gsub("\n", "")

  local success, err = M.capture_errors(function()
    local file = io.open(state_file, "w")
    if file then
      file:write(vim.fn.json_encode(state))
      file:close()
      return true
    end
    error("Could not write state file")
  end, "save_state")

  if success then
    log_debug("State saved successfully")
  end

  return success
end

--- Synchronize state with actual Claude processes
--- @return boolean synced Whether synchronization was successful
function M.sync_state_with_processes()
  -- Get current Claude buffers
  local claude_buffers = M.detect_claude_buffers()

  if #claude_buffers == 0 then
    -- No Claude processes, clean up state if exists
    local valid, state = M.validate_state_file()
    if valid and state then
      -- Check if state is recent (within last hour)
      local age_hours = (os.time() - state.timestamp) / 3600
      if age_hours > 1 then
        log_debug("Cleaning up stale state (%.1f hours old)", age_hours)
        M.cleanup_state_file()
      end
    end
    return true
  end

  -- Claude processes exist, ensure state is current
  local state = {
    active_buffers = claude_buffers,
    timestamp = os.time(),
    cwd = vim.fn.getcwd()
  }

  return M.save_state(state)
end

--- Initialize the session manager
function M.setup()
  ensure_state_dir()

  -- Validate and clean up state file on startup
  M.validate_state_file()

  -- Set up periodic state synchronization
  vim.defer_fn(function()
    local timer = vim.loop.new_timer()
    timer:start(5000, 5000, vim.schedule_wrap(function()
      M.sync_state_with_processes()
    end))
  end, 1000)

  log_debug("Session manager initialized")
end

return M