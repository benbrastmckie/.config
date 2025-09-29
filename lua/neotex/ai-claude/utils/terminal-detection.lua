-----------------------------------------------------------
-- Terminal Detection Utility
--
-- Detects terminal emulator type for tab management
-- Part of the Claude AI worktree integration
-----------------------------------------------------------

local M = {}

-- Module state
local detected_terminal = nil  -- Cache detection result

--- Detect terminal type from environment
--- @return string|nil Terminal type ('kitty', 'wezterm') or nil if unsupported
function M.detect()
  -- Return cached result if available
  if detected_terminal ~= false then
    return detected_terminal
  end

  -- Check for Kitty
  if vim.env.KITTY_LISTEN_ON or vim.env.KITTY_PID or vim.env.KITTY_WINDOW_ID then
    detected_terminal = 'kitty'
    return detected_terminal
  end

  -- Check for WezTerm
  if vim.env.WEZTERM_EXECUTABLE or vim.env.WEZTERM_PANE then
    detected_terminal = 'wezterm'
    return detected_terminal
  end

  -- Check TERM_PROGRAM as fallback
  local term_program = vim.env.TERM_PROGRAM
  if term_program then
    if term_program:lower():match('kitty') then
      detected_terminal = 'kitty'
      return detected_terminal
    elseif term_program:lower():match('wezterm') then
      detected_terminal = 'wezterm'
      return detected_terminal
    end
  end

  detected_terminal = false  -- Mark as checked but unsupported
  return nil
end

--- Check if terminal supports tab management
--- @return boolean True if terminal supports remote control
function M.supports_tabs()
  local terminal = M.detect()
  return terminal == 'kitty' or terminal == 'wezterm'
end

--- Get terminal display name
--- @return string Terminal name for user display
function M.get_display_name()
  local terminal = M.detect()
  if terminal == 'kitty' then
    return 'Kitty'
  elseif terminal == 'wezterm' then
    return 'WezTerm'
  else
    return vim.env.TERM_PROGRAM or vim.env.TERM or 'unknown'
  end
end

return M