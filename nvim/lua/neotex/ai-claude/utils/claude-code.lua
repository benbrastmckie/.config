-- Utility functions for interacting with claude-code.nvim plugin
local M = {}

--- Open Claude Code with a specific command using the proper claude-code.nvim API
--- @param command string The full command to run (e.g., "claude --resume <id>")
--- @return boolean success Whether the command was executed successfully
function M.open_with_command(command)
  local notify = require("neotex.util.notifications")

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

  -- Store the original command
  local original_command = claude_code.config.command

  -- Temporarily set the new command
  claude_code.config.command = command

  -- Open Claude with the custom command
  local success = pcall(claude_code.toggle)

  -- Always restore the original command, even if toggle fails
  claude_code.config.command = original_command

  if not success then
    notify.notify(
      "Failed to open Claude Code",
      notify.categories.ERROR,
      {
        module = "ai-claude",
        details = string.format("Failed to open Claude with command: %s", command),
        command = command
      }
    )
    return false
  end

  return true
end

--- Resume a specific Claude session by ID
--- @param session_id string The session ID to resume
--- @return boolean success Whether the session was resumed successfully
function M.resume_session(session_id)
  local notify = require("neotex.util.notifications")

  notify.notify(
    string.format("Resuming session: %s...", session_id:sub(1, 8)),
    notify.categories.USER_ACTION,
    { module = "ai-claude", action = "resume_session" }
  )

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

  -- Use the full command approach since there might not be a resume variant
  return M.open_with_command("claude --resume " .. session_id)
end

--- Open Claude Code with continue mode
--- @return boolean success Whether Claude was opened in continue mode
function M.continue()
  local notify = require("neotex.util.notifications")

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

  -- Try to use the variant system if continue variant exists
  if claude_code.config and claude_code.config.command_variants and claude_code.config.command_variants.continue then
    local success = pcall(claude_code.toggle_with_variant, "continue")
    return success
  else
    -- Fall back to full command approach
    return M.open_with_command("claude --continue")
  end
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