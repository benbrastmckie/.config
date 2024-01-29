return {
  "gaoDean/autolist.nvim",
  filetype = {
    "markdown",
    -- "text",
    -- "tex",
    -- "plaintex",
    "norg",
  },
  config = function()
    require('autolist').setup()

    function HandleCheckbox()
      local config = require("autolist.config")
      local auto = require("autolist.auto")

      local checkbox_pattern = " [ ]"

      local filetype_list = config.lists[vim.bo.filetype]
      local line = vim.fn.getline(".")

      for index, list_pattern in ipairs(filetype_list) do
        local list_item = line:match("^%s*" .. list_pattern .. "%s*")
        -- only bullet, no checkbox
        if list_item == nil then goto continue_for_loop end
        list_item = list_item:gsub("%s+", "")
        local is_list_item = list_item ~= nil
        -- only bullet, no checkbox
        local is_checkbox_item = line:match("^%s*" .. list_pattern .. "%s*" .. "%[.%]" .. "%s*") ~= nil
        -- bullet and checkbox

        if is_list_item == true and is_checkbox_item == false then
          list_item = list_item:gsub('%)', '%%)')
          vim.fn.setline(".", (line:gsub(list_item, list_item .. checkbox_pattern, 1)))

          local cursor_pos = vim.api.nvim_win_get_cursor(0)
          if cursor_pos[2] > 0 then
            vim.api.nvim_win_set_cursor(0, { cursor_pos[1], cursor_pos[2] + checkbox_pattern:len() })
          end
          goto continue
        else
          auto.toggle_checkbox()
          goto continue
        end
        ::continue_for_loop::
      end
      ::continue::
    end
  end,
}


-- -- NOTE: started trying to extend this but got stuck.
-- -- everything works the same as is.
-- function HandleCheckbox()
--   local config = require("autolist.config")
--   local auto = require("autolist.auto")
--
--   local empty_box = " [ ]"
--   local prog_box = " [.]"
--   -- local close_box = " [:]"
--   -- local done_box = " [x]"
--
--   local filetype_lists = config.lists[vim.bo.filetype]
--   local line = vim.fn.getline(".")
--
--   for index, list_pattern in ipairs(filetype_lists) do
--     local list_item = line:match("^%s*" .. list_pattern .. "%s*")
--     list_item = list_item:gsub("%s+", "")
--     local is_list_item = list_item ~= nil
--     local is_box_item = line:match("^%s*" .. list_pattern .. "%s*" .. "%[.%]" .. "%s*") ~= nil
--
--     local is_empty_item = line:match("^%s*" .. list_pattern .. "%s*" .. "%[%s%]" .. "%s*") ~= nil
--     -- local is_prog_item = line:match("^%s*" .. list_pattern .. "%s*" .. "%[%.%]" .. "%s*") == true
--     -- local is_close_item = line:match("^%s*" .. list_pattern .. "%s*" .. "%[%:%]" .. "%s*") == true
--     -- local is_done_item = line:match("^%s*" .. list_pattern .. "%s*" .. "%[x%]" .. "%s*") == true
--
--     if is_list_item == true and is_box_item == false then
--       vim.fn.setline(".", (line:gsub(list_item, list_item .. empty_box, 1)))
--       local cursor_pos = vim.api.nvim_win_get_cursor(0)
--       vim.api.nvim_win_set_cursor(0, { cursor_pos[1], cursor_pos[2] + empty_box:len() })
--       goto continue
--
--       -- elseif is_list_item == true and is_empty_item == true then
--       --   vim.fn.setline(".", (line:gsub(empty_box, prog_box, 1)))
--       --   goto continue
--
--       -- elseif is_list_item == true and is_prog_item == false then
--       --   vim.fn.setline(".", (line:gsub(prog_box, close_box, 1)))
--       --   -- local cursor_pos = vim.api.nvim_win_get_cursor(0)
--       --   -- vim.api.nvim_win_set_cursor(0, { cursor_pos[1], cursor_pos[2] + close_box:len() })
--       --   goto continue
--       -- elseif is_list_item == true and is_close_item == false then
--       --   vim.fn.setline(".", (line:gsub(close_box, done_box, 1)))
--       --   -- local cursor_pos = vim.api.nvim_win_get_cursor(0)
--       --   -- vim.api.nvim_win_set_cursor(0, { cursor_pos[1], cursor_pos[2] + done_box:len() })
--       --   goto continue
--       -- elseif is_list_item == true and is_done_item == false then
--       --   vim.fn.setline(".", (line:gsub(done_box, list_item, 1)))
--       --   local cursor_pos = vim.api.nvim_win_get_cursor(0)
--       --   vim.api.nvim_win_set_cursor(0, { cursor_pos[1], cursor_pos[2] - done_box:len() })
--       --   goto continue
--     else
--       auto.toggle_checkbox()
--       goto continue
--     end
--     -- ::continue_for_loop::
--   end
--   ::continue::
-- end
