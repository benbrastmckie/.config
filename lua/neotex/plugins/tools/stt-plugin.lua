-- STT (Speech-to-Text) Plugin Specification
-- This file exports the plugin spec for lazy.nvim

return {
  -- Virtual plugin for STT setup
  dir = vim.fn.stdpath('config') .. '/lua/neotex/plugins/tools/stt',
  name = 'stt',
  event = { 'VeryLazy' }, -- Load after startup
  config = function(_, opts)
    -- Defer loading to avoid static analysis issues
    local module_path = 'neotex.plugins.tools.stt.init'
    local stt = require(module_path)
    stt.setup(opts)
  end,
}
