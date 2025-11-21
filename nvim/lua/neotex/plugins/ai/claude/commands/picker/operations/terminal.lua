-- neotex.plugins.ai.claude.commands.picker.operations.terminal
-- Terminal integration for sending commands and running scripts

local M = {}

-- Dependencies
local helpers = require("neotex.plugins.ai.claude.commands.picker.utils.helpers")

--- Send command to Claude Code terminal (event-driven, no timers)
--- @param command table Command data
function M.send_command_to_terminal(command)
  -- Get base command string with trailing space for arguments
  local command_text = "/" .. command.name .. " "

  -- Check if Claude Code plugin is available
  local has_claude_code = pcall(require, "claude-code")
  if not has_claude_code then
    helpers.notify(
      "Claude Code plugin not found. Please install claude-code.nvim",
      "ERROR"
    )
    return
  end

  -- Get terminal state module
  local success, terminal_state = pcall(require, "neotex.plugins.ai.claude.claude-session.terminal-state")
  if not success then
    helpers.notify(
      "Failed to load terminal state module",
      "ERROR"
    )
    return
  end

  -- Queue command - terminal_state.queue_command handles all timing logic
  terminal_state.queue_command(command_text, {
    ensure_open = true,
  })
end

--- Create new command by opening Claude Code with prompt
function M.create_new_command()
  -- Check if Claude Code plugin is available
  local has_claude_code = pcall(require, "claude-code")
  if not has_claude_code then
    helpers.notify(
      "Claude Code plugin not found. Please install claude-code.nvim",
      "ERROR"
    )
    return
  end

  -- Get terminal state module
  local success, terminal_state = pcall(require, "neotex.plugins.ai.claude.claude-session.terminal-state")
  if not success then
    helpers.notify(
      "Failed to load terminal state module",
      "ERROR"
    )
    return
  end

  -- Prompt for command name
  local command_name = vim.fn.input("New command name (without /): ")
  if command_name == "" then
    return
  end

  -- Queue command creation request
  local create_prompt = string.format(
    "/plan Create a new command called /%s that ",
    command_name
  )

  terminal_state.queue_command(create_prompt, {
    ensure_open = true,
  })
end

--- Run script with arguments (for scripts/ and tests/ artifacts)
--- @param script_path string Path to script file
--- @param script_name string Name of script
function M.run_script_with_args(script_path, script_name)
  if not helpers.is_file_readable(script_path) then
    helpers.notify(
      string.format("Script not found: %s", script_name),
      "ERROR"
    )
    return
  end

  -- Prompt for arguments
  local args = vim.fn.input(string.format("Arguments for %s: ", script_name))

  -- Build command
  local cmd
  if args ~= "" then
    cmd = string.format("bash %s %s", vim.fn.fnameescape(script_path), args)
  else
    cmd = string.format("bash %s", vim.fn.fnameescape(script_path))
  end

  -- Execute in terminal
  vim.cmd("belowright split | terminal " .. cmd)

  helpers.notify(
    string.format("Running %s", script_name),
    "INFO"
  )
end

--- Run test script (for tests/ artifacts)
--- @param test_path string Path to test file
--- @param test_name string Name of test
function M.run_test(test_path, test_name)
  if not helpers.is_file_readable(test_path) then
    helpers.notify(
      string.format("Test not found: %s", test_name),
      "ERROR"
    )
    return
  end

  -- Build command
  local cmd = string.format("bash %s", vim.fn.fnameescape(test_path))

  -- Execute in terminal
  vim.cmd("belowright split | terminal " .. cmd)

  helpers.notify(
    string.format("Running test: %s", test_name),
    "INFO"
  )
end

return M
