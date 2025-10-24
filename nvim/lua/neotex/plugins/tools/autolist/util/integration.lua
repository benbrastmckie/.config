-- Autolist plugin integrations module
local M = {}
local utils = require("neotex.plugins.tools.autolist.util.utils")

function M.setup()
  -- Note: blink.cmp does not expose event system in the same way as nvim-cmp
  -- The InsertCharPre autocmd below handles menu closing when needed
  
  -- Prevent completion menu triggering with Tab in list items
  vim.api.nvim_create_autocmd("InsertCharPre", {
    pattern = {"*.md", "*.markdown", "*.norg"},
    callback = function()
      if vim.v.char == "\t" then
        -- Only handle list items
        if utils.is_list_item(vim.fn.getline(".")) then
          pcall(function()
            local blink = require('blink.cmp')
            if blink then
              blink.hide()
              _G._prevent_cmp_menu = true

              vim.defer_fn(function()
                _G._prevent_cmp_menu = false
              end, 1500)
            end
          end)
        end
      end
    end
  })
end

return M