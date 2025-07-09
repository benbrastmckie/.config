-- Himalaya Command System
-- Bridge to maintain backward compatibility while using new modular command system
-- TODO: REMOVE BACKWARDS COMPATIBILITY - This compatibility bridge should be removed, use modular commands directly

local commands = require('neotex.plugins.tools.himalaya.core.commands.init')

-- Setup the command system
commands.setup()

-- Export the module for backward compatibility
-- TODO: REMOVE BACKWARDS COMPATIBILITY - Direct import of modular commands instead
return commands