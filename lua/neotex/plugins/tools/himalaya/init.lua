-- Himalaya Email Client Integration
-- Main plugin interface for NeoVim

return {
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
    config = function()
      -- Load modules only when needed (lazy loading for startup performance)
      local config = require('neotex.plugins.tools.himalaya.config')
      local utils = require('neotex.plugins.tools.himalaya.utils')
      local ui = require('neotex.plugins.tools.himalaya.ui')
      local streamlined_sync = require('neotex.plugins.tools.himalaya.streamlined_sync')
      
      -- Initialize utilities first
      if not utils.init() then
        return
      end
      
      -- Initialize UI components
      ui.init()
      
      -- Initialize simplified external sync detection
      local external_sync = require('neotex.plugins.tools.himalaya.external_sync_simple')
      external_sync.setup()
      
      -- External sync detection is now simplified and automatic
      
      -- Setup configuration (this also sets up commands)
      config.setup({
        -- Override default configuration here if needed
        default_account = 'gmail',
        accounts = {
          gmail = { 
            name = 'Benjamin Brast-McKie', 
            email = 'benbrastmckie@gmail.com' 
          },
        },
      })
      
      -- Emergency cleanup on startup to prevent stuck processes (defer to not block startup)
      vim.defer_fn(function()
        streamlined_sync.emergency_cleanup()
        -- Auto-sync now happens when sidebar is first opened, not on startup
      end, 100) -- Small delay to not block startup
      
      -- Initialize trash system (defer to improve startup time)
      vim.defer_fn(function()
        local trash_manager = require('neotex.plugins.tools.himalaya.trash_manager')
        local trash_operations = require('neotex.plugins.tools.himalaya.trash_operations')
        local trash_ui = require('neotex.plugins.tools.himalaya.trash_ui')
        
        trash_manager.setup_commands()
        trash_operations.setup_commands()
        trash_ui.setup_commands()
        trash_manager.init()
        
        -- Trash system initialization complete
      end, 50)
      
      -- Setup cleanup on exit
      vim.api.nvim_create_autocmd('VimLeavePre', {
        callback = function()
          utils.cleanup()
          streamlined_sync.cleanup()
        end,
      })
    end,
  },
}