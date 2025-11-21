-- neotex.plugins.ai.claude.commands.picker
-- Facade for Claude artifacts picker - delegates to modular implementation

local M = {}

-- Internal implementation
local internal = require("neotex.plugins.ai.claude.commands.picker.init")

--- Show the Claude artifacts picker
--- This is the public API that external code calls
--- Delegates to the modular implementation in picker/init.lua
--- @param opts table Telescope options (optional)
function M.show_commands_picker(opts)
  return internal.show_commands_picker(opts)
end

return M
