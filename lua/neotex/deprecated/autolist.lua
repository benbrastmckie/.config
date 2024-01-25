return {
  "gaoDean/autolist.nvim",
  ft = {
    "markdown",
    -- "text",
    -- "tex",
    -- "plaintex",
    "norg",
  },
  config = function()
    require("autolist").setup()

    -- function handle_checkbox()
    --   local config = require("autolist.config")
    --   local auto = require("autolist.auto")
    --
    --   local checkbox_pattern = " [ ]"
    --
    --   local filetype_lists = config.lists[vim.bo.filetype]
    --   local line = vim.fn.getline(".")
    --
    --   for i, list_pattern in ipairs(filetype_lists) do
    --     local list_item = line:match("^%s*" .. list_pattern .. "%s*")  -- only bullet, no checkbox
    --     list_item = list_item:gsub("%s+", "")
    --     local is_list_item = list_item ~= nil -- only bullet, no checkbox
    --     local is_checkbox_item = line:match("^%s*" .. list_pattern .. "%s*" .. "%[.%]" .. "%s*") ~= nil -- bullet and checkbox  
    --
    --     if is_list_item == true and is_checkbox_item == false then
    --       vim.fn.setline(".", (line:gsub(list_item, list_item .. checkbox_pattern, 1)))
    --       local cursor_pos = vim.api.nvim_win_get_cursor(0)
    --       vim.api.nvim_win_set_cursor(0, {cursor_pos[1], cursor_pos[2] + checkbox_pattern:len()})
    --       goto continue
    --     else
    --       auto.toggle_checkbox()
    --       goto continue
    --     end
    --   end
    --   ::continue::
    -- end
  end,
}
