-----------------------------------------------------------
-- WezTerm Integration Plugin
--
-- Provides programmatic control of WezTerm tabs and panes
-- for managing multiple Claude Code sessions
-----------------------------------------------------------

return {
  "willothy/wezterm.nvim",
  config = function()
    require("wezterm").setup({
      create_commands = false,  -- We'll create our own commands
    })
  end,
}