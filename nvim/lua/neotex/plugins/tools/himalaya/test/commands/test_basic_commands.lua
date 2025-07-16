-- Basic Command Tests for Himalaya Plugin
-- Simple tests to verify test infrastructure

local framework = require('neotex.plugins.tools.himalaya.test.utils.test_framework')
local assert = framework.assert

-- Test suite
local tests = {}

-- Test that plugin is loaded
table.insert(tests, framework.create_test('plugin_loaded', function()
  -- The himalaya module returns a plugin spec, not the module itself
  -- Check that core modules are available instead
  local config = require('neotex.plugins.tools.himalaya.core.config')
  local utils = require('neotex.plugins.tools.himalaya.utils')
  assert.truthy(config, "Config module should be loaded")
  assert.truthy(utils, "Utils module should be loaded")
end))

-- Test config module
table.insert(tests, framework.create_test('config_module', function()
  local config = require('neotex.plugins.tools.himalaya.core.config')
  -- Always setup config for this test to ensure it has binaries
  config.setup({
    binaries = {
      himalaya = 'himalaya'
    }
  })
  assert.truthy(config, "Config module should exist")
  assert.truthy(config.config, "Should have config table")
  assert.truthy(config.config.binaries, "Should have binaries config")
  assert.truthy(config.config.binaries.himalaya, "Should have himalaya binary configured")
end))

-- Test state module
table.insert(tests, framework.create_test('state_module', function()
  local state = require('neotex.plugins.tools.himalaya.core.state')
  assert.truthy(state, "State module should exist")
  assert.truthy(state.get, "Should have get function")
  assert.truthy(state.set, "Should have set function")
  
  -- Test basic state operation
  state.set('test.value', 'hello')
  local value = state.get('test.value')
  assert.equals(value, 'hello', "State should store and retrieve values")
  
  -- Clean up
  state.set('test.value', nil)
end))

-- Test command registry
table.insert(tests, framework.create_test('command_registry', function()
  local commands = require('neotex.plugins.tools.himalaya.core.commands.init')
  assert.truthy(commands, "Commands module should exist")
  assert.truthy(commands.command_registry, "Should have command registry")
  
  -- Check some basic commands exist
  assert.truthy(commands.has_command('Himalaya'), "Should have Himalaya command")
  assert.truthy(commands.has_command('HimalayaHealth'), "Should have HimalayaHealth command")
end))

-- Test notification integration
table.insert(tests, framework.create_test('notification_system', function()
  local notify = require('neotex.util.notifications')
  assert.truthy(notify, "Notification system should exist")
  assert.truthy(notify.himalaya, "Should have himalaya notification function")
  assert.truthy(notify.categories, "Should have notification categories")
  
  -- Test notification categories
  assert.truthy(notify.categories.STATUS, "Should have STATUS category")
  assert.truthy(notify.categories.WARNING, "Should have WARNING category")
end))

-- Export test suite
_G.himalaya_test = framework.create_suite('Basic Commands', tests)

return _G.himalaya_test
