return {
  "gaoDean/autolist.nvim",
  filetype = {
    "markdown",
    "norg",
  },
  config = function()
    -- Initialize autolist with minimal configuration
    local autolist = require('autolist')
    
    autolist.setup({
      lists = {
        -- Disable roman numerals and use simple numbered lists
        markdown = {
          "1.", -- Numbered lists (1., 2., 3., etc)
          "-",  -- Unordered lists with dash
          "*",  -- Unordered lists with asterisk
          "+",  -- Unordered lists with plus
        },
        norg = {
          "1.", -- Numbered lists
          "-",  -- Unordered lists
          "*",  -- Unordered lists
          "+",  -- Unordered lists
        }
      },
      enabled = true,
      cycle = {"1.", "-", "*", "+"},  -- Cycle between these list types
      
      -- VERY IMPORTANT: Disable smart indentation to prevent Tab key interference
      smart_indent = false,
      
      -- Disable automatic list continuation after colon
      colon = {
        indent = false,      -- Do NOT create a list item after lines ending with ':'
        indent_raw = false,  -- Do NOT indent raw colon lines
        preferred = "-"      -- Default bullet if needed
      },
      
      -- IMPORTANT: Disable all built-in keymaps to prevent Tab/Shift-Tab issues
      custom_keys = false
    })
    
    -- Load our custom autolist modules
    local commands = require("neotex.plugins.tools.autolist.util.commands")
    local integration = require("neotex.plugins.tools.autolist.util.integration")
    
    if commands and commands.setup then
      commands.setup()
    end
    
    if integration and integration.setup then
      integration.setup()
    end
    
    -- Set up global flags for tracking state
    _G._last_tab_was_indent = false
    _G._prevent_cmp_menu = false
    
    -- Setup autocomds for markdown files
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "markdown", "norg" },
      callback = function()
        if type(_G.set_markdown_keymaps) == "function" then
          _G.set_markdown_keymaps()
        end
      end
    })
  end,
}