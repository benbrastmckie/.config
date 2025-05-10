-----------------------------------------------------------
-- DEPRECATED: This module is deprecated and will be removed in a future version.
-- Please use the new modules in neotex/config/ and neotex/utils/ instead.
-- See NEW_STRUCTURE.md for details on the new organization.
-----------------------------------------------------------

vim.notify("Loading deprecated neotex.core module - this will be removed in a future version", vim.log.levels.WARN)

require("neotex.core.autocmds")
require("neotex.core.functions")
require("neotex.core.keymaps")
require("neotex.core.options")

-- Load Avante support module
require("neotex.plugins.ai.avante-support")
