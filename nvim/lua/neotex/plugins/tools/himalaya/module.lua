-- Himalaya Module Interface for Tests
-- This file provides the module interface that tests can use

local init = require('neotex.plugins.tools.himalaya.init')

-- Since init.lua returns a plugin spec, we need to get the actual module
-- The module functions are defined on M in init.lua before the return statement
-- We'll create a module that properly exposes the needed functions

local M = {}

-- Get the actual init module by loading it in a way that captures M
local function get_init_module()
  -- Clear the module from cache to ensure fresh load
  package.loaded['neotex.plugins.tools.himalaya.init'] = nil
  
  -- Load the file and capture its environment
  local env = {}
  setmetatable(env, {__index = _G})
  
  local path = vim.fn.stdpath('config') .. '/lua/neotex/plugins/tools/himalaya/init.lua'
  local chunk = loadfile(path, 't', env)
  chunk()
  
  return env.M
end

-- Get the module
local himalaya = get_init_module()

-- Export what tests need
M.setup = himalaya and himalaya.setup
M.utils = require('neotex.plugins.tools.himalaya.utils')
M.config = require('neotex.plugins.tools.himalaya.core.config')

return M