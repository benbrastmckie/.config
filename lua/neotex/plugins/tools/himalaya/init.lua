-- Himalaya Email Plugin - Simplified and Robust
-- Main entry point for the refactored plugin

local M = {}

-- Plugin state
M.loaded = false

-- Setup function
function M.setup(opts)
  if M.loaded then
    return
  end

  -- Initialize core configuration
  local config = require('neotex.plugins.tools.himalaya.core.config')
  config.setup(opts)

  -- Initialize state with migration support (Phase 6)
  local state = require('neotex.plugins.tools.himalaya.core.state')
  state.init() -- Will handle migration and validation

  -- Initialize email cache
  local email_cache = require('neotex.plugins.tools.himalaya.core.email_cache')
  email_cache.init(config.config.cache)

  -- Initialize OAuth module
  local oauth = require('neotex.plugins.tools.himalaya.sync.oauth')
  oauth.setup()

  -- Initialize UI system
  local ui = require('neotex.plugins.tools.himalaya.ui')
  ui.setup()

  -- Initialize event system (Phase 6) - after UI to ensure notifications work properly
  local integration = require('neotex.plugins.tools.himalaya.orchestration.integration')
  integration.setup_default_handlers()
  integration.setup()

  -- Initialize Phase 9 features
  -- Initialize unified email scheduler
  local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
  scheduler.setup()

  -- Set up commands
  M.setup_commands()

  -- Start auto-sync timer
  local manager = require('neotex.plugins.tools.himalaya.sync.manager')
  manager.start_auto_sync()

  -- Run health check on startup if configured
  if config.config.setup.check_health_on_startup then
    vim.defer_fn(function()
      local health = require('neotex.plugins.tools.himalaya.setup.health')
      local result = health.check()
      if not result.ok then
        local notifications = require('neotex.plugins.tools.himalaya.ui.notifications')
        notifications.show_setup_hints()
      end
    end, 1000)
  end

  -- Check if setup wizard should run
  if config.config.setup.auto_run then
    local wizard = require('neotex.plugins.tools.himalaya.setup.wizard')
    if not wizard.is_setup_complete() then
      vim.defer_fn(function()
        local notify = require('neotex.util.notifications')
        notify.himalaya('Himalaya not configured. Run :HimalayaSetup to begin.', notify.categories.USER_ACTION)
      end, 2000)
    end
  end

  M.loaded = true
end

-- Setup user commands
function M.setup_commands()
  local commands = require('neotex.plugins.tools.himalaya.core.commands')
  commands.register_all()
end

-- Keymaps helper for which-key
function M.get_keymaps()
  -- Keymaps are now handled entirely in which-key.lua
  -- This function is maintained for backward compatibility
  return {}
end

-- Return plugin specification for lazy.nvim
return {
  {
    -- Virtual plugin for Himalaya setup
    dir = vim.fn.stdpath('config') .. '/lua/neotex/plugins/tools/himalaya',
    name = 'himalaya-email',
    event = { 'VeryLazy' }, -- Load after startup
    config = function(_, opts)
      M.setup(opts)
    end,
  },
  -- Dependencies
  {
    'nvim-telescope/telescope.nvim',
    optional = true,
  },
}
