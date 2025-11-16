-----------------------------------------------------------
-- Terminal Command Abstraction
--
-- Provides terminal-agnostic command generation for
-- tab management across different terminal emulators
-----------------------------------------------------------

local M = {}

-- Dependencies
local detect = require('neotex.plugins.ai.claude.claude-session.terminal-detection')

--- Generate spawn command for new tab
--- @param worktree_path string Path to worktree directory
--- @param command string|nil Command to run in new tab (default: 'nvim CLAUDE.md')
--- @return string|nil Shell command or nil if terminal unsupported
function M.spawn_tab(worktree_path, command)
  local terminal = detect.detect()

  if terminal == 'wezterm' then
    return string.format(
      "wezterm cli spawn --cwd '%s' -- %s",
      worktree_path,
      command or 'nvim CLAUDE.md'
    )
  elseif terminal == 'kitty' then
    return string.format(
      "kitten @ launch --type=tab --cwd='%s' --title='%s' %s",
      worktree_path,
      vim.fn.fnamemodify(worktree_path, ':t'),
      command or 'nvim CLAUDE.md'
    )
  end

  return nil
end

--- Generate activate tab command
--- @param tab_id string Tab/pane identifier
--- @param terminal_type string|nil Override terminal detection
--- @return string|nil Shell command or nil if terminal unsupported
function M.activate_tab(tab_id, terminal_type)
  local terminal = terminal_type or detect.detect()

  if terminal == 'wezterm' then
    return string.format("wezterm cli activate-pane --pane-id %s", tab_id)
  elseif terminal == 'kitty' then
    -- NOTE: Kitty uses window focusing instead of direct tab activation
    return string.format("kitten @ focus-tab --match id:%s", tab_id)
  end

  return nil
end

--- Parse spawn result to extract tab/pane ID
--- @param result string Command output from spawn
--- @param terminal_type string|nil Override terminal detection
--- @return string|nil Tab/pane ID or nil if parsing failed
function M.parse_spawn_result(result, terminal_type)
  local terminal = terminal_type or detect.detect()

  if terminal == 'wezterm' then
    -- WezTerm returns pane ID directly
    return result:match("(%d+)")
  elseif terminal == 'kitty' then
    -- Kitty returns window ID in JSON format
    -- Parse: {"id": 12345, ...}
    local id = result:match('"id"%s*:%s*(%d+)')
    return id
  end

  return nil
end

--- Get set tab title command
--- @param tab_id string Tab/pane identifier
--- @param title string Tab title
--- @param terminal_type string|nil Override terminal detection
--- @return string|nil Shell command or nil if terminal unsupported
function M.set_tab_title(tab_id, title, terminal_type)
  local terminal = terminal_type or detect.detect()

  if terminal == 'wezterm' then
    return string.format(
      "wezterm cli set-tab-title --pane-id %s '%s'",
      tab_id, title
    )
  elseif terminal == 'kitty' then
    -- Kitty sets title via the launch command
    -- No separate title command available
    return nil
  end

  return nil
end

return M