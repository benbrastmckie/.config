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
  local native_sessions = require("neotex.ai-claude.ui.native-sessions")
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
  -- Validate session before attempting resume
  local valid, errors = M.validate_session(session_id)
  if not valid then
    local error_msg = "Session validation failed:\n" .. table.concat(errors or {}, "\n")
    notify.notify(
      error_msg,
      notify.categories.ERROR,
      { module = "ai-claude", action = "resume_session" }
    )
    return false, error_msg
  end

  -- Attempt to resume using claude-code utility
  local claude_util = require("neotex.ai-claude.utils.claude-code")

  local success, result = M.capture_errors(function()
    return claude_util.resume_session(session_id)
  end, "resume_session")

  if success and result then
    notify.notify(
      string.format("Successfully resumed session: %s", session_id:sub(1, 8)),
      notify.categories.USER_ACTION,
      { module = "ai-claude", action = "resume_session" }
    )
    return true
  else
    return false, "Failed to resume session"
  end
end

--- Enable or disable debug logging
--- @param enabled boolean Whether to enable debug logging
function M.set_debug(enabled)
  DEBUG = enabled
  log_debug("Debug logging %s", enabled and "enabled" or "disabled")
end

--- Initialize the session manager
function M.setup()
  ensure_state_dir()

  -- Validate and clean up state file on startup
  M.validate_state_file()

  log_debug("Session manager initialized")
end

return M