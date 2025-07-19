-- Himalaya Command System
-- Modular command registry with orchestration layer

local M = {}

-- Command registry containing all command definitions
M.command_registry = {}

-- Register a command in the registry
function M.register(name, definition)
  M.command_registry[name] = definition
end

-- Register multiple commands at once
function M.register_batch(commands)
  for name, definition in pairs(commands) do
    M.register(name, definition)
  end
end

-- Setup function to load all command modules
function M.setup()
  -- Load consolidated command modules
  require('neotex.plugins.tools.himalaya.commands.email').setup(M)
  require('neotex.plugins.tools.himalaya.commands.ui').setup(M)
  require('neotex.plugins.tools.himalaya.commands.sync').setup(M)
  require('neotex.plugins.tools.himalaya.commands.utility').setup(M)
  
  -- Initialize Phase 8 features
  local features_ok, _ = pcall(function()
    require('neotex.plugins.tools.himalaya.features.attachments').setup()
    -- Trash system removed - using standard IMAP trash folder
    require('neotex.plugins.tools.himalaya.features.contacts').setup()
  end)
  
  if not features_ok then
    local logger = require('neotex.plugins.tools.himalaya.core.logger')
    logger.warn("Some Phase 8 features failed to initialize")
  end
  
  -- Register test validation commands
  local validation_ok, validation_cmds = pcall(require, 'neotex.plugins.tools.himalaya.commands.test_validation')
  if validation_ok then
    local test_completions = function()
      local test_runner = require('neotex.plugins.tools.himalaya.test.test_runner')
      return test_runner.get_test_completions()
    end
    
    vim.api.nvim_create_user_command('HimalayaTestValidate', function()
      validation_cmds.validate_test_counts()
    end, {
      desc = 'Validate test counts across all categories'
    })
    
    vim.api.nvim_create_user_command('HimalayaTestDebug', function(opts)
      validation_cmds.debug_test_mismatch(opts.args)
    end, {
      nargs = 1,
      complete = test_completions,
      desc = 'Debug test count mismatch for a specific test'
    })
    
    vim.api.nvim_create_user_command('HimalayaTestDetails', function(opts)
      validation_cmds.show_test_details(opts.args)
    end, {
      nargs = 1,
      complete = test_completions,
      desc = 'Show detailed test information'
    })
  end
  
  -- Register test registry commands
  local registry_ok, registry_cmds = pcall(require, 'neotex.plugins.tools.himalaya.commands.test_registry_debug')
  if registry_ok then
    vim.api.nvim_create_user_command('HimalayaTestRegistry', registry_cmds.show_validation_report, {
      desc = 'Show test registry validation report'
    })
    
    vim.api.nvim_create_user_command('HimalayaTestExecution', registry_cmds.show_execution_summary, {
      desc = 'Show test execution summary with count validation'
    })
  end
  
  -- Register all commands with vim
  M.register_all()
end

-- Function to register all commands
function M.register_all()
  local cmd = vim.api.nvim_create_user_command
  
  for name, def in pairs(M.command_registry) do
    if def.fn and def.opts then
      cmd(name, def.fn, def.opts)
    end
  end
end

-- Get a command definition
function M.get_command(name)
  return M.command_registry[name]
end

-- Check if a command exists
function M.has_command(name)
  return M.command_registry[name] ~= nil
end

-- List all registered commands
function M.list_commands()
  local commands = {}
  for name, _ in pairs(M.command_registry) do
    table.insert(commands, name)
  end
  table.sort(commands)
  return commands
end

return M