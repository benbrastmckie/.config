-- Utility functions for interacting with claude-code.nvim plugin
local M = {}

--- Open Claude Code with a specific command using improved API integration
--- @param command string The full command to run (e.g., "claude --resume <id>")
--- @return boolean success Whether the command was executed successfully
--- @return string? error_details Error details if failed
function M.open_with_command(command)
  local notify = require("neotex.util.notifications")
  local session_manager = require("neotex.ai-claude.core.session-manager")

  -- Get the claude-code plugin module
  local ok, claude_code = pcall(require, "claude-code")
  if not ok then
    local error_msg = "claude-code plugin not found"
    notify.notify(
      error_msg,
      notify.categories.ERROR,
      {
        module = "ai-claude",
        details = "The claude-code.nvim plugin could not be loaded"
      }
    )
    return false, error_msg
  end

  -- Verify command execution with session manager's error capture
  local success, result = session_manager.capture_errors(function()
    -- Store the original command for restoration
    local original_command = claude_code.config and claude_code.config.command or "claude"

    -- Set the new command
    if claude_code.config then
      claude_code.config.command = command
    else
      error("claude-code config not initialized")
    end

    -- Execute the toggle
    local toggle_success = claude_code.toggle()

    -- Restore original command
    claude_code.config.command = original_command

    -- Verify the command actually worked by checking for Claude buffers
    vim.defer_fn(function()
      local buffers = session_manager.detect_claude_buffers()
      if #buffers == 0 then
        notify.notify(
          "Warning: Claude buffer not detected after command",
          notify.categories.WARNING,
          { module = "ai-claude", command = command }
        )
      end
    end, 500) -- Check after 500ms to allow buffer creation

    return toggle_success
  end, "open_with_command")

  if not success then
    local error_details = type(result) == "table" and result.error or tostring(result)
    notify.notify(
      "Failed to open Claude Code",
      notify.categories.ERROR,
      {
        module = "ai-claude",
        details = string.format("Failed with command: %s\nError: %s", command, error_details),
        command = command
      }
    )
    return false, error_details
  end

  return true
end

--- Resume a specific Claude session by ID with validation
--- @param session_id string The session ID to resume
--- @return boolean success Whether the session was resumed successfully
function M.resume_session(session_id)
  local notify = require("neotex.util.notifications")
  local session_manager = require("neotex.ai-claude.core.session-manager")

  -- Use session manager's resume function with full validation
  return session_manager.resume_session(session_id)
end

--- Open Claude Code with continue mode using improved execution
--- @return boolean success Whether Claude was opened in continue mode
function M.continue()
  local notify = require("neotex.util.notifications")
  local session_manager = require("neotex.ai-claude.core.session-manager")

  -- Get the claude-code plugin module
  local ok, claude_code = pcall(require, "claude-code")
  if not ok then
    notify.notify(
      "claude-code plugin not found",
      notify.categories.ERROR,
      {
        module = "ai-claude",
        details = "The claude-code.nvim plugin could not be loaded"
      }
    )
    return false
  end

  -- Enhanced variant detection with fallback
  local success, result = session_manager.capture_errors(function()
    -- Try variant system first if available
    if claude_code.config and
       claude_code.config.command_variants and
       claude_code.config.command_variants.continue and
       claude_code.toggle_with_variant then
      -- Use the variant method
      return claude_code.toggle_with_variant("continue")
    else
      -- Fall back to command approach
      return M.open_with_command("claude --continue")
    end
  end, "continue_session")

  if success then
    notify.notify(
      "Continuing previous Claude session",
      notify.categories.USER_ACTION,
      { module = "ai-claude", action = "continue" }
    )
  end

  return success
end

--- Open Claude Code normally
--- @return boolean success Whether Claude was opened successfully
function M.open()
  local ok, claude_code = pcall(require, "claude-code")
  if not ok then
    return false
  end

  local success = pcall(claude_code.toggle)
  return success
end

return M