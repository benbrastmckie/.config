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
    config = function()
      -- Pre-load core modules for responsiveness
      local config = require('neotex.plugins.tools.himalaya.config')
      local utils = require('neotex.plugins.tools.himalaya.utils')
      local ui = require('neotex.plugins.tools.himalaya.ui')
      local streamlined_sync = require('neotex.plugins.tools.himalaya.streamlined_sync')
      local sidebar = require('neotex.plugins.tools.himalaya.sidebar')
      local state = require('neotex.plugins.tools.himalaya.state')
      -- Initialize utilities first
      if not utils.init() then
        return
      end
      
      -- Initialize UI components
      ui.init()
      
      -- Setup configuration
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
      
      -- Initialize streamlined sync system
      streamlined_sync.setup_commands()
      
      -- Emergency cleanup on startup to prevent stuck processes
      streamlined_sync.emergency_cleanup()
      
      -- Auto-sync on startup if no sync is running
      vim.defer_fn(function()
        streamlined_sync.auto_sync_on_startup()
      end, 2000) -- 2 second delay to let startup complete
      
      -- Initialize trash system
      local trash_manager = require('neotex.plugins.tools.himalaya.trash_manager')
      local trash_operations = require('neotex.plugins.tools.himalaya.trash_operations')
      local trash_ui = require('neotex.plugins.tools.himalaya.trash_ui')
      
      trash_manager.setup_commands()
      trash_operations.setup_commands()
      trash_ui.setup_commands()
      trash_manager.init()
      
      -- Setup cleanup on exit
      vim.api.nvim_create_autocmd('VimLeavePre', {
        callback = function()
          utils.cleanup()
          streamlined_sync.cleanup()
        end,
      })
    end,
    lazy = false, -- Load immediately
  },
}