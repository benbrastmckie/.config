-- Autolist plugin integrations module
local M = {}
local utils = require("neotex.plugins.tools.autolist.util.utils")

function M.setup()
  -- Set up nvim-cmp integration to respect autolist flags and behavior
  local cmp_ok, cmp = pcall(require, 'cmp')
  if cmp_ok then
    -- CMP event listener to prevent automatic opening after indentation
    cmp.event:on('menu_opened', function()
      if vim.bo.filetype == "markdown" and _G._prevent_cmp_menu then
        cmp.close()
      end
    end)
  end
  
  -- Prevent completion menu triggering with Tab in list items
  vim.api.nvim_create_autocmd("InsertCharPre", {
    pattern = {"*.md", "*.markdown", "*.norg"},
    callback = function()
      if vim.v.char == "\t" then
        -- Only handle list items
        if utils.is_list_item(vim.fn.getline(".")) then
          pcall(function()
            local cmp = require('cmp')
            if cmp then
              cmp.close()
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