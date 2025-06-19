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
      
      -- Initialize utilities first
      if not utils.init() then
        return
      end
      
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
      
      -- Start auto-sync if enabled
      if config.config.auto_sync then
        utils.start_auto_sync()
      end
      
      -- Setup cleanup on exit
      vim.api.nvim_create_autocmd('VimLeavePre', {
        callback = function()
          utils.cleanup()
        end,
      })
    end,
    lazy = false, -- Load immediately
  },
}