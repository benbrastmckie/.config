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
      local config = require('neotex.plugins.tools.himalaya.config')
      local utils = require('neotex.plugins.tools.himalaya.utils')
      local ui = require('neotex.plugins.tools.himalaya.ui')
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
      local streamlined_sync = require('neotex.plugins.tools.himalaya.streamlined_sync')
      local fresh_sync = require('neotex.plugins.tools.himalaya.fresh_sync')
      streamlined_sync.setup_commands()
      fresh_sync.setup_commands()
      
      -- Emergency cleanup on startup to prevent stuck processes
      streamlined_sync.emergency_cleanup()
      
      -- Wait longer for cleanup and let manual sync take precedence
      -- No automatic sync on startup - let user control when to sync
      
      -- Setup debug tools and fixes
      local debug_tools = require('neotex.plugins.tools.himalaya.debug_tools')
      local fixes = require('neotex.plugins.tools.himalaya.fixes')
      local performance = require('neotex.plugins.tools.himalaya.performance')
      local sidebar_enhancements = require('neotex.plugins.tools.himalaya.sidebar_enhancements')
      local delete_fix = require('neotex.plugins.tools.himalaya.delete_fix')
      local folder_check = require('neotex.plugins.tools.himalaya.folder_check')
      local gmail_fix = require('neotex.plugins.tools.himalaya.gmail_fix')
      local util = require('neotex.plugins.tools.himalaya.util')
      local trash_manager = require('neotex.plugins.tools.himalaya.trash_manager')
      local trash_operations = require('neotex.plugins.tools.himalaya.trash_operations')
      local trash_ui = require('neotex.plugins.tools.himalaya.trash_ui')
      local delete_diagnostics = require('neotex.plugins.tools.himalaya.delete_diagnostics')
      local native_sync = require('neotex.plugins.tools.himalaya.native_sync')
      local auto_updates = require('neotex.plugins.tools.himalaya.auto_updates')
      local fix_mbsync = require('neotex.plugins.tools.himalaya.fix_mbsync')
      
      debug_tools.setup_commands()
      fixes.setup_commands()
      performance.setup_commands()
      sidebar_enhancements.setup_commands()
      delete_fix.setup_commands()
      folder_check.setup_commands()
      gmail_fix.setup_commands()
      util.setup_commands()
      trash_manager.setup_commands()
      trash_operations.setup_commands()
      trash_ui.setup_commands()
      delete_diagnostics.setup_commands()
      
      -- Auto-apply fixes and optimizations
      fixes.apply_fixes()
      performance.apply_optimizations()
      sidebar_enhancements.apply_enhancements()
      delete_fix.apply_fixes()
      folder_check.fix_delete_for_gmail()
      gmail_fix.apply_gmail_delete_fix()
      
      -- Initialize local trash system
      trash_manager.init()
      
      -- Initialize automatic updates system
      -- TEMPORARILY DISABLED: auto_updates.setup() to test manual sync
      -- auto_updates.setup()
      
      -- Setup cleanup on exit
      vim.api.nvim_create_autocmd('VimLeavePre', {
        callback = function()
          utils.cleanup()
          native_sync.cleanup()
        end,
      })
    end,
    lazy = false, -- Load immediately
  },
}