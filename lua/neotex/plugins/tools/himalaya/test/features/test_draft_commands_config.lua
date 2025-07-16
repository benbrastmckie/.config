-- Test for Draft Commands and Configuration (Phase 5)
-- Tests command registration and configuration validation

local Test = require('neotex.plugins.tools.himalaya.test.utils.test_framework')
local config = require('neotex.plugins.tools.himalaya.core.config')
local commands = require('neotex.plugins.tools.himalaya.commands.init')

local M = {}

-- Test suite definition
M.tests = {
  {
    name = "Draft Configuration - Default Values",
    fn = function()
      -- Check draft config exists in defaults
      Test.assert.truthy(config.defaults.draft, "Draft config should exist in defaults")
      
      local draft_config = config.defaults.draft
      
      -- Check storage settings
      Test.assert.truthy(draft_config.storage, "Storage config should exist")
      Test.assert.truthy(draft_config.storage.base_dir:match('/himalaya/drafts$'), 
        "Base dir should end with /himalaya/drafts")
      Test.assert.equals(draft_config.storage.format, 'json', "Default format should be json")
      Test.assert.equals(draft_config.storage.compression, false, "Compression should be disabled by default")
      
      -- Check sync settings
      Test.assert.truthy(draft_config.sync, "Sync config should exist")
      Test.assert.equals(draft_config.sync.auto_sync, true, "Auto sync should be enabled")
      Test.assert.equals(draft_config.sync.sync_interval, 300, "Sync interval should be 5 minutes")
      Test.assert.equals(draft_config.sync.retry_attempts, 3, "Should have 3 retry attempts")
      
      -- Check recovery settings
      Test.assert.truthy(draft_config.recovery, "Recovery config should exist")
      Test.assert.equals(draft_config.recovery.enabled, true, "Recovery should be enabled")
      Test.assert.equals(draft_config.recovery.check_on_startup, true, "Should check on startup")
      Test.assert.equals(draft_config.recovery.max_age_days, 7, "Max age should be 7 days")
      
      -- Check UI settings
      Test.assert.truthy(draft_config.ui, "UI config should exist")
      Test.assert.equals(draft_config.ui.confirm_delete, true, "Should confirm delete")
      Test.assert.equals(draft_config.ui.auto_save_delay, 30000, "Auto save delay should be 30 seconds")
      
      return true
    end
  },
  
  {
    name = "Draft Configuration Validation - Valid Config",
    fn = function()
      local valid_config = {
        draft = {
          storage = {
            base_dir = "/tmp/drafts",
            format = "json"
          },
          sync = {
            sync_interval = 600,
            retry_attempts = 5
          }
        }
      }
      
      local ok, err = config.validate_draft_config(valid_config)
      Test.assert.truthy(ok, "Valid config should pass validation")
      Test.assert.falsy(err, "Should have no error message")
      
      return true
    end
  },
  
  {
    name = "Draft Configuration Validation - Invalid Storage",
    fn = function()
      local invalid_config = {
        draft = {
          storage = {
            base_dir = 123, -- Should be string
            format = "invalid" -- Should be json or eml
          }
        }
      }
      
      local ok, err = config.validate_draft_config(invalid_config)
      Test.assert.falsy(ok, "Invalid config should fail validation")
      Test.assert.truthy(err:match("base_dir must be a string"), "Should have base_dir error")
      
      -- Test invalid format
      invalid_config.draft.storage.base_dir = "/tmp/drafts"
      ok, err = config.validate_draft_config(invalid_config)
      Test.assert.falsy(ok, "Invalid format should fail")
      Test.assert.truthy(err:match("format must be 'json' or 'eml'"), "Should have format error")
      
      return true
    end
  },
  
  {
    name = "Draft Configuration Validation - Invalid Sync",
    fn = function()
      local invalid_config = {
        draft = {
          sync = {
            sync_interval = -5, -- Should be positive
            retry_attempts = "three" -- Should be number
          }
        }
      }
      
      local ok, err = config.validate_draft_config(invalid_config)
      Test.assert.falsy(ok, "Invalid sync config should fail")
      Test.assert.truthy(err:match("sync_interval must be a positive number"), 
        "Should have sync_interval error")
      
      return true
    end
  },
  
  {
    name = "Draft Commands Registration",
    fn = function()
      -- Setup commands (this would normally happen during plugin init)
      commands.setup()
      
      -- Check draft commands are registered
      local draft_commands = {
        'HimalayaDraftNew',
        'HimalayaDraftSave',
        'HimalayaDraftSync',
        'HimalayaDraftSyncAll',
        'HimalayaDraftList',
        'HimalayaDraftDelete',
        'HimalayaDraftSend',
        'HimalayaDraftStatus',
        'HimalayaDraftInfo',
        'HimalayaDraftAutosaveEnable',
        'HimalayaDraftAutosaveDisable'
      }
      
      for _, cmd_name in ipairs(draft_commands) do
        Test.assert.truthy(commands.has_command(cmd_name), 
          string.format("Command %s should be registered", cmd_name))
        
        local cmd = commands.get_command(cmd_name)
        Test.assert.truthy(cmd.fn, string.format("%s should have fn", cmd_name))
        Test.assert.truthy(cmd.opts, string.format("%s should have opts", cmd_name))
        Test.assert.truthy(cmd.opts.desc, string.format("%s should have description", cmd_name))
      end
      
      return true
    end
  },
  
  {
    name = "Draft Command Options",
    fn = function()
      -- Check specific command options
      local new_cmd = commands.get_command('HimalayaDraftNew')
      Test.assert.falsy(new_cmd.opts.nargs, "DraftNew should not have nargs")
      
      local info_cmd = commands.get_command('HimalayaDraftInfo')
      Test.assert.equals(info_cmd.opts.nargs, 1, "DraftInfo should require 1 argument")
      
      return true
    end
  },
  
  {
    name = "Configuration Integration in Commands",
    fn = function()
      -- Test that commands use configuration
      local config_module = require('neotex.plugins.tools.himalaya.core.config')
      
      -- Set a test configuration
      config_module.config.draft.ui.confirm_delete = false
      
      -- The delete command should check this config
      local delete_cmd = commands.get_command('HimalayaDraftDelete')
      Test.assert.truthy(delete_cmd, "Delete command should exist")
      
      -- Note: We can't easily test the actual behavior without creating drafts,
      -- but we've verified the command exists and config is accessible
      
      return true
    end
  },
  
  {
    name = "Draft Status Command Output",
    fn = function()
      -- Test that status command can access state
      local state = require('neotex.plugins.tools.himalaya.core.state')
      
      -- Initialize state if needed
      if not state._initialized then
        state.init()
      end
      
      -- The status command should be able to get draft count
      local status_cmd = commands.get_command('HimalayaDraftStatus')
      Test.assert.truthy(status_cmd, "Status command should exist")
      
      -- Verify it has the right structure
      Test.assert.truthy(status_cmd.fn, "Status command should have function")
      Test.assert.equals(status_cmd.opts.desc, "Show draft statistics", 
        "Status command should have correct description")
      
      return true
    end
  }
}

-- Create test instances
local tests = {}
for _, test_def in ipairs(M.tests) do
  table.insert(tests, Test.create_test(test_def.name, test_def.fn))
end

-- Export test suite
_G.draft_commands_config_test = Test.create_suite('Draft Commands & Configuration', tests)

return _G.draft_commands_config_test
