-- Lazy.nvim plugin specification for Himalaya
-- This file provides the plugin spec for lazy.nvim users

return {
  {
    -- Virtual plugin for Himalaya setup
    dir = vim.fn.stdpath('config') .. '/lua/neotex/plugins/tools/himalaya',
    name = 'himalaya-email',
    event = { 'VeryLazy' }, -- Load after startup
    config = function(_, opts)
      require('neotex.plugins.tools.himalaya').setup(opts)
    end,
  },
  -- Dependencies
  {
    'nvim-telescope/telescope.nvim',
    optional = true,
  },
}