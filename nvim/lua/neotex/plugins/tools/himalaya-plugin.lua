-- Himalaya Email Plugin Specification
-- This file exports the plugin spec for lazy.nvim

return {
  -- Virtual plugin for Himalaya setup
  dir = vim.fn.stdpath('config') .. '/lua/neotex/plugins/tools/himalaya',
  name = 'himalaya-email',
  event = { 'VeryLazy' }, -- Load after startup
  config = function(_, opts)
    -- Defer loading to avoid static analysis issues
    local module_path = 'neotex.plugins.tools.himalaya.init'
    local himalaya = require(module_path)
    himalaya.setup(opts)
  end,
  dependencies = {
    {
      'nvim-telescope/telescope.nvim',
      optional = true,
    },
  },
}