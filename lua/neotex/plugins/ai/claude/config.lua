-- Configuration module for Claude AI integration
local M = {}

M.defaults = {
  -- Picker settings
  simple_picker_max = 3,          -- Max sessions shown in simple picker
  show_preview = true,             -- Show preview in pickers

  -- Session management
  auto_restore_session = true,    -- Auto-restore on startup
  auto_save_session = true,        -- Save session state automatically
  session_timeout_hours = 24,      -- Consider sessions old after this time

  -- Worktree settings
  worktree = {
    max_sessions = 4,
    auto_switch_tab = true,
    create_context_file = true,
    types = { "feature", "bugfix", "refactor", "experiment", "hotfix" },
    default_type = "feature",
  },

  -- Terminal settings
  auto_insert_mode = true,         -- Auto-enter insert mode in Claude terminal
  terminal_height = 15,            -- Height of Claude terminal split

  -- Visual selection
  visual = {
    include_filename = true,       -- Include filename when sending visual selection
    include_line_numbers = true,   -- Include line numbers in selection
  },

  -- Commands picker
  commands = {
    show_dependencies = true,      -- Show dependent commands in hierarchy
    show_help_entry = true,        -- Show keyboard shortcuts help entry
    cache_timeout = 300,           -- Cache parsed commands for 5 minutes (seconds)
  },

  -- Global source directory for artifact syncing
  global_source_dir = vim.fn.expand("~/.config/nvim"),
}

M.options = {}

-- Setup configuration
M.setup = function(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})

  -- Update sub-module configs
  local pickers = require("neotex.plugins.ai.claude.ui.pickers")
  if pickers.config then
    pickers.config.simple_picker_max = M.options.simple_picker_max
  end

  return M.options
end

-- Get a configuration value
M.get = function(key)
  local keys = vim.split(key, ".", { plain = true })
  local value = M.options

  for _, k in ipairs(keys) do
    value = value[k]
    if value == nil then
      return nil
    end
  end

  return value
end

return M