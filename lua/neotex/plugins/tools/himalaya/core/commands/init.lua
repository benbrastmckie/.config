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
  require('neotex.plugins.tools.himalaya.core.commands.email_commands').setup(M)
  require('neotex.plugins.tools.himalaya.core.commands.ui_commands').setup(M)
  require('neotex.plugins.tools.himalaya.core.commands.sync_commands').setup(M)
  require('neotex.plugins.tools.himalaya.core.commands.utility_commands').setup(M)
  
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