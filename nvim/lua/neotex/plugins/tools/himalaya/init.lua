-- Himalaya Email Plugin for Neovim - Version 2.0
-- Main entry point for the refactored plugin

local M = {}

-- Plugin version
M.version = "2.0.0"

-- The plugin configuration for lazy.nvim
M.plugin_spec = {
  {
    'nvim-telescope/telescope.nvim',
    optional = true,
    opts = function()
      require('neotex.plugins.tools.himalaya.picker').setup_telescope()
    end,
  },
  {
    'williamboman/mason.nvim',
    optional = true,
    opts = {
      ensure_installed = { 'vale' }, -- Email linting
    },
  },
  {
    -- Virtual plugin for Himalaya setup
    dir = vim.fn.stdpath('config') .. '/lua/neotex/plugins/tools/himalaya',
    name = 'himalaya-email',
    event = { 'VeryLazy' }, -- Load after startup is complete
    config = function(opts)
      M.setup(opts)
    end,
  },
}

-- Setup function
function M.setup(opts)
  opts = opts or {}
  
  -- Initialize core modules
  local config = require("neotex.plugins.tools.himalaya.core.config")
  local logger = require("neotex.plugins.tools.himalaya.core.logger")
  local state = require("neotex.plugins.tools.himalaya.core.state")
  
  -- Setup configuration
  config.setup(opts)
  
  -- Setup logger
  logger.setup({
    level = opts.log_level or "info",
    prefix = "[Himalaya]"
  })
  
  -- Initialize OAuth environment
  local oauth = require("neotex.plugins.tools.himalaya.sync.oauth")
  oauth.setup()
  
  -- Check if setup is needed
  local wizard = require("neotex.plugins.tools.himalaya.setup.wizard")
  if config.get("setup.auto_run", true) and not wizard.is_setup_complete() then
    vim.defer_fn(function()
      logger.info("First-time setup needed. Run :HimalayaSetup to configure.")
    end, 1000)
  end
  
  -- Check if migration is needed
  local migration = require("neotex.plugins.tools.himalaya.setup.migration")
  if migration.needs_migration() then
    vim.defer_fn(function()
      logger.info("Migration available from old version. Run :HimalayaMigrate to update.")
    end, 2000)
  end
  
  -- Run health check if configured
  if config.get("setup.check_health_on_startup", true) then
    vim.defer_fn(function()
      local health = require("neotex.plugins.tools.himalaya.setup.health")
      local result = health.check()
      if not result.ok then
        logger.warn("Health check found issues. Run :HimalayaHealth for details.")
      end
    end, 3000)
  end
  
  -- Setup commands
  M.setup_commands()
  
  -- Setup autocommands
  M.setup_autocommands()
  
  logger.info("Himalaya email plugin loaded (v" .. M.version .. ")")
end

-- Setup commands
function M.setup_commands()
  local cmd = vim.api.nvim_create_user_command
  
  -- Main commands
  cmd("Himalaya", function(opts)
    require("neotex.plugins.tools.himalaya.ui").show_email_list(opts.fargs)
  end, {
    nargs = "*",
    desc = "Open email list",
    complete = function()
      return {"INBOX", "Sent", "Drafts", "Trash", "All_Mail"}
    end
  })
  
  cmd("HimalayaWrite", function(opts)
    require("neotex.plugins.tools.himalaya.ui").compose_email(opts.args)
  end, {
    nargs = "?",
    desc = "Compose new email"
  })
  
  -- Sync commands
  cmd("HimalayaSyncInbox", function()
    local mbsync = require("neotex.plugins.tools.himalaya.sync.mbsync")
    local config = require("neotex.plugins.tools.himalaya.core.config")
    local account = config.get_current_account()
    
    mbsync.sync(account.mbsync.inbox_channel, {
      auto_refresh = true,
      callback = function(success)
        if success then
          vim.cmd("doautocmd User HimalayaSyncComplete")
        end
      end
    })
  end, { desc = "Sync inbox only" })
  
  cmd("HimalayaSyncAll", function()
    local mbsync = require("neotex.plugins.tools.himalaya.sync.mbsync")
    local config = require("neotex.plugins.tools.himalaya.core.config")
    local account = config.get_current_account()
    
    mbsync.sync(account.mbsync.all_channel or config.get_current_account_name(), {
      auto_refresh = true,
      callback = function(success)
        if success then
          vim.cmd("doautocmd User HimalayaSyncComplete")
        end
      end
    })
  end, { desc = "Sync all folders" })
  
  cmd("HimalayaCancelSync", function()
    local mbsync = require("neotex.plugins.tools.himalaya.sync.mbsync")
    if mbsync.stop() then
      require("neotex.plugins.tools.himalaya.core.logger").info("Sync cancelled")
    end
  end, { desc = "Cancel ongoing sync" })
  
  -- Setup & maintenance
  cmd("HimalayaSetup", function()
    require("neotex.plugins.tools.himalaya.setup.wizard").run()
  end, { desc = "Run setup wizard" })
  
  cmd("HimalayaHealth", function()
    require("neotex.plugins.tools.himalaya.setup.health").show_report()
  end, { desc = "Show health check" })
  
  cmd("HimalayaFixCommon", function()
    require("neotex.plugins.tools.himalaya.setup.health").fix_common_issues()
  end, { desc = "Fix common issues automatically" })
  
  cmd("HimalayaCleanup", function()
    local lock = require("neotex.plugins.tools.himalaya.sync.lock")
    local cleaned = lock.cleanup_locks()
    require("neotex.plugins.tools.himalaya.core.logger").info(
      string.format("Cleaned %d stale locks", cleaned)
    )
  end, { desc = "Clean up stale locks" })
  
  cmd("HimalayaMigrate", function()
    require("neotex.plugins.tools.himalaya.setup.migration").migrate_from_old()
  end, { desc = "Migrate from old version" })
  
  -- OAuth commands
  cmd("HimalayaOAuthRefresh", function()
    local oauth = require("neotex.plugins.tools.himalaya.sync.oauth")
    oauth.refresh()
  end, { desc = "Refresh OAuth token" })
  
  cmd("HimalayaOAuthStatus", function()
    local oauth = require("neotex.plugins.tools.himalaya.sync.oauth")
    local logger = require("neotex.plugins.tools.himalaya.core.logger")
    local status = oauth.get_status()
    
    logger.info("OAuth Status:")
    logger.info("  Has token: " .. tostring(status.has_token))
    logger.info("  Last refresh: " .. (status.last_refresh > 0 and os.date("%Y-%m-%d %H:%M:%S", status.last_refresh) or "never"))
    logger.info("  Environment loaded: " .. tostring(status.environment_loaded))
  end, { desc = "Show OAuth status" })
end

-- Setup autocommands
function M.setup_autocommands()
  local group = vim.api.nvim_create_augroup("HimalayaEmail", { clear = true })
  
  -- Auto-refresh email list after sync
  vim.api.nvim_create_autocmd("User", {
    pattern = "HimalayaSyncComplete",
    group = group,
    callback = function()
      -- Refresh email list if it's open
      local ui = require("neotex.plugins.tools.himalaya.ui")
      if ui.is_sidebar_open and ui.is_sidebar_open() then
        ui.refresh_email_list()
      end
    end
  })
  
  -- Update sidebar status
  vim.api.nvim_create_autocmd("User", {
    pattern = "HimalayaStatusUpdate",
    group = group,
    callback = function()
      -- Update sidebar header if it's open
      local sidebar = require("neotex.plugins.tools.himalaya.ui.sidebar")
      if sidebar.is_open and sidebar.is_open() then
        sidebar.refresh_header()
      end
    end
  })
end

return M.plugin_spec