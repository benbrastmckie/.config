-- Configuration Module (Backward Compatibility Layer)
-- This module now delegates to the new modular configuration system in config/
-- Maintaining the same API for backward compatibility

local config = require('neotex.plugins.tools.himalaya.config')

-- Re-export the config module's interface
return config