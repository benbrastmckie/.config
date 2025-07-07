-- Himalaya Command System
-- Bridge to maintain backward compatibility while using new modular command system

local commands = require('neotex.plugins.tools.himalaya.core.commands.init')

-- Setup the command system
commands.setup()

-- Export the module for backward compatibility
return commands