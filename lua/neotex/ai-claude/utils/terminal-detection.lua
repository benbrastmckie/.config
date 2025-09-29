-----------------------------------------------------------
-- Terminal Detection Utility
--
-- Detects terminal emulator type for tab management
-- Part of the Claude AI worktree integration
-----------------------------------------------------------

local M = {}

-- Module state
local detected_terminal = nil  -- Cache detection result
local remote_control_capability = nil  -- Cache remote control capability

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

--- Check if terminal has remote control capability
--- @return boolean True if terminal has remote control enabled
function M.has_remote_control()
  -- Return cached result if available
  if remote_control_capability ~= nil then
    return remote_control_capability
  end

  local terminal = M.detect()

  if terminal == 'kitty' then
    -- For Kitty, check if KITTY_LISTEN_ON is set (indicates remote control enabled)
    remote_control_capability = vim.env.KITTY_LISTEN_ON and vim.env.KITTY_LISTEN_ON ~= ''
  elseif terminal == 'wezterm' then
    -- WezTerm doesn't require special configuration for remote control
    remote_control_capability = true
  else
    remote_control_capability = false
  end

  return remote_control_capability
end

--- Check if terminal supports tab management
--- @return boolean True if terminal supports remote control
function M.supports_tabs()
  return M.has_remote_control()
end

--- Get terminal display name
--- @return string Terminal name for user display
function M.get_display_name()
  local terminal = M.detect()
  if terminal == 'kitty' then
    if M.has_remote_control() then
      return 'Kitty'
    else
      return 'Kitty (remote control disabled)'
    end
  elseif terminal == 'wezterm' then
    return 'WezTerm'
  else
    return vim.env.TERM_PROGRAM or vim.env.TERM or 'unknown'
  end
end

--- Validate terminal capability by testing actual command
--- @return boolean True if kitten @ commands work
function M.validate_capability()
  local terminal = M.detect()

  if terminal == 'kitty' then
    -- Test if kitten @ ls command works
    local result = vim.fn.system('kitten @ ls 2>/dev/null')
    return vim.v.shell_error == 0 and result:match('^%s*%[') ~= nil
  elseif terminal == 'wezterm' then
    -- Test if wezterm cli list works
    local result = vim.fn.system('wezterm cli list 2>/dev/null')
    return vim.v.shell_error == 0
  end

  return false
end

--- Check Kitty configuration for remote control setting
--- @return boolean|nil True if enabled, false if disabled, nil if config not found
function M.check_kitty_config()
  local terminal = M.detect()
  if terminal ~= 'kitty' then
    return nil
  end

  -- Common Kitty config locations
  local config_paths = {
    vim.fn.expand('~/.config/kitty/kitty.conf'),
    vim.fn.expand('~/.kitty.conf'),
    vim.fn.expand('~/Library/Preferences/kitty/kitty.conf')  -- macOS
  }

  for _, config_path in ipairs(config_paths) do
    if vim.fn.filereadable(config_path) == 1 then
      local content = vim.fn.readfile(config_path)
      for _, line in ipairs(content) do
        -- Check for allow_remote_control setting
        local trimmed = vim.trim(line)
        if not trimmed:match('^#') and trimmed:match('allow_remote_control%s+yes') then
          return true
        elseif not trimmed:match('^#') and trimmed:match('allow_remote_control%s+no') then
          return false
        end
      end
      -- Config exists but no explicit setting found (defaults to no)
      return false
    end
  end

  -- No config file found
  return nil
end

--- Get Kitty configuration file path
--- @return string|nil Path to kitty.conf or nil if not found
function M.get_kitty_config_path()
  local config_paths = {
    vim.fn.expand('~/.config/kitty/kitty.conf'),
    vim.fn.expand('~/.kitty.conf'),
    vim.fn.expand('~/Library/Preferences/kitty/kitty.conf')  -- macOS
  }

  for _, config_path in ipairs(config_paths) do
    if vim.fn.filereadable(config_path) == 1 then
      return config_path
    end
  end

  -- Return default location if none exist
  return vim.fn.expand('~/.config/kitty/kitty.conf')
end

return M