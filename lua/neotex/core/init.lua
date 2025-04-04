require("neotex.core.autocmds")
require("neotex.core.functions")
require("neotex.core.keymaps")
require("neotex.core.options")

-- Set up Avante commands
local avante_commands = require("neotex.core.avante_commands")
avante_commands.setup_stop_command()
