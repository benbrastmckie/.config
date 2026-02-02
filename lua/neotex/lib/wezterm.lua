-- neotex.lib.wezterm
-- WezTerm OSC escape sequence integration for Neovim
--
-- Provides functions to emit OSC 1337 SetUserVar sequences directly to WezTerm,
-- bypassing inner PTY routing issues when running in embedded terminals.
--
-- Related: Task 790 established OSC 7 pattern in neotex/config/autocmds.lua
-- Related: Task 789 wezterm-task-number.sh hook for shell-level integration

local M = {}

-- Check if we're running inside WezTerm by examining WEZTERM_PANE env var
-- This is set by WezTerm for all panes and inherited by child processes
local function is_wezterm()
  return vim.env.WEZTERM_PANE ~= nil
end

-- Base64 encode a string for OSC 1337 SetUserVar
-- Note: Lua 5.1 doesn't have native base64, so we implement it
local function base64_encode(data)
  local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  return ((data:gsub('.', function(x)
    local r, b = '', x:byte()
    for i = 8, 1, -1 do r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0') end
    return r
  end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
    if #x < 6 then return '' end
    local c = 0
    for i = 1, 6 do c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0) end
    return b:sub(c + 1, c + 1)
  end) .. ({ '', '==', '=' })[#data % 3 + 1])
end

--- Emit a user variable to WezTerm via OSC 1337 SetUserVar
-- OSC 1337 format: ESC ] 1337 ; SetUserVar=name=base64_value BEL
-- @param name string The name of the user variable
-- @param value string|nil The value to set (nil or empty to clear)
-- @return boolean success Whether the emission succeeded
function M.emit_user_var(name, value)
  if not is_wezterm() then
    return false
  end

  -- Validate name
  if not name or name == '' then
    return false
  end

  local osc
  if value and value ~= '' then
    -- Set the variable with base64-encoded value
    local encoded = base64_encode(value)
    -- ESC ] 1337 ; SetUserVar=name=base64value BEL
    -- Use \027 for ESC (Lua 5.1 compatible) and \007 for BEL
    osc = string.format('\027]1337;SetUserVar=%s=%s\007', name, encoded)
  else
    -- Clear the variable by setting empty value
    osc = string.format('\027]1337;SetUserVar=%s=\007', name)
  end

  -- Write directly to stdout (which goes to WezTerm)
  local ok, err = pcall(function()
    io.write(osc)
    io.flush()
  end)

  if not ok then
    vim.notify(
      string.format('[wezterm] Failed to emit user var %s: %s', name, err),
      vim.log.levels.DEBUG
    )
    return false
  end

  return true
end

--- Clear a user variable in WezTerm
-- Convenience wrapper around emit_user_var with nil value
-- @param name string The name of the user variable to clear
-- @return boolean success Whether the emission succeeded
function M.clear_user_var(name)
  return M.emit_user_var(name, nil)
end

--- Set the TASK_NUMBER user variable for WezTerm tab title
-- This integrates with wezterm.lua format-tab-title handler
-- @param task_number string|number The task number to display
-- @return boolean success Whether the emission succeeded
function M.set_task_number(task_number)
  local num = tostring(task_number)
  return M.emit_user_var('TASK_NUMBER', num)
end

--- Clear the TASK_NUMBER user variable
-- @return boolean success Whether the emission succeeded
function M.clear_task_number()
  return M.clear_user_var('TASK_NUMBER')
end

--- Check if WezTerm integration is available
-- @return boolean Whether we're running inside WezTerm
function M.is_available()
  return is_wezterm()
end

return M
