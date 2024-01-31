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
      local emptybox_pattern = " [ ]"
      local progbox_pattern = " [.]"
      local closebox_pattern = " [:]"
      local donebox_pattern = " [x]"
      local filetype_list = config.lists[vim.bo.filetype]
      local line = vim.fn.getline(".")

      for i, list_pattern in ipairs(filetype_list) do
        local list_item = line:match("^%s*" .. list_pattern .. "%s*")
        -- only bullet, no checkbox

        if list_item == nil then goto continue_for_loop end
        list_item = list_item:gsub("%s+", "")

        local is_list_item = list_item ~= nil
        -- only bullet, no checkbox
        local is_checkbox_item = line:match("^%s*" .. list_pattern .. "%s*" .. "%[.%]" .. "%s*") ~= nil
        -- bullet and checkbox
        local is_emptybox_item = line:match("^%s*" .. list_pattern .. "%s*" .. "%[%s%]" .. "%s*") ~= nil
        -- bullet and emptybox
        local is_progbox_item = line:match("^%s*" .. list_pattern .. "%s*" .. "%[%.%]" .. "%s*") ~= nil
        -- bullet and progbox
        local is_closebox_item = line:match("^%s*" .. list_pattern .. "%s*" .. "%[%:%]" .. "%s*") ~= nil
        -- bullet and closebox
        local is_donebox_item = line:match("^%s*" .. list_pattern .. "%s*" .. "%[x%]" .. "%s*") ~= nil
        -- bullet and closebox

        if is_list_item == true and is_checkbox_item == false then
          list_item = list_item:gsub('%)', '%%)')
          vim.fn.setline(".", (line:gsub(list_item, list_item .. emptybox_pattern, 1)))

          local cursor_pos = vim.api.nvim_win_get_cursor(0)
          if cursor_pos[2] > 0 then
            vim.api.nvim_win_set_cursor(0, { cursor_pos[1], cursor_pos[2] + emptybox_pattern:len() })
          end
          goto continue
        elseif is_list_item == true and is_emptybox_item == true then
          list_item = list_item:gsub('%)', '%%)')
          vim.fn.setline(".", (line:gsub(" %[%s%]", progbox_pattern, 1)))
          goto continue
        elseif is_list_item == true and is_progbox_item == true then
          list_item = list_item:gsub('%)', '%%)')
          vim.fn.setline(".", (line:gsub(" %[%.%]", closebox_pattern, 1)))
          goto continue
        elseif is_list_item == true and is_closebox_item == true then
          list_item = list_item:gsub('%)', '%%)')
          vim.fn.setline(".", (line:gsub(" %[%:%]", donebox_pattern, 1)))
          goto continue
        elseif is_list_item == true and is_donebox_item == true then
          list_item = list_item:gsub('%)', '%%)')
          vim.fn.setline(".", (line:gsub(" %[x%]", "", 1)))

          local cursor_pos = vim.api.nvim_win_get_cursor(0)
          -- vim.cmd("norm! 0 | f]")
          if cursor_pos[2] > donebox_pattern:len() then
            vim.api.nvim_win_set_cursor(0, { cursor_pos[1], cursor_pos[2] - donebox_pattern:len() })
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
