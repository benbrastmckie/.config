local list_patterns = {
    neorg_1 = "%-",
    neorg_2 = "%-%-",
    neorg_3 = "%-%-%-",
    neorg_4 = "%-%-%-%-",
    neorg_5 = "%-%-%-%-%-",
    unordered = "[-+*]", -- - + *
    digit = "%d+[.)]", -- 1. 2. 3.
    ascii = "%a[.)]", -- a) b) c)
    roman = "%u*[.)]", -- I. II. III.
    latex_item = "\\item",
}

local default_config = {
  enabled = false,
  colon = { -- if a line ends in a colon
    indent = false, -- if in list and line ends in `:` then create list
    indent_raw = false, -- above, but doesn't need to be in a list to work
    preferred = "-", -- what the new list starts with (can be `1.` etc)
  },
  cycle = { -- Cycles the list type in order
      "-",   -- whatever you put here will match the first item in your list
      "*",   -- for example if your list started with a `-` it would go to `*`
      "1.",  -- this says that if your list starts with a `*` it would go to `1.`
      "1)",  -- this all leverages the power of recalculate.
      "a)",  -- i spent many hours on that function
      "I.",  -- try it, change the first bullet in a list to `a)`, and press recalculate
  },
  lists = { -- configures list behaviours
    -- Each key in lists represents a filetype.
    -- The value is a table of all the list patterns that the filetype implements.
    -- See how to define your custom list below in the readme.
    -- You must put the file name for the filetype, not the file extension
    -- To get the "file name", it is just =:set filetype?= or =:se ft?=.
    markdown = {
      list_patterns.unordered,
      list_patterns.digit,
      list_patterns.ascii, -- for example this specifies activate the ascii list
      list_patterns.roman, -- type for markdown files.
    },
    text = {
      list_patterns.unordered,
      list_patterns.digit,
      list_patterns.ascii,
      list_patterns.roman,
    },
    norg = {
        list_patterns.neorg_1,
        list_patterns.neorg_2,
        list_patterns.neorg_3,
        list_patterns.neorg_4,
        list_patterns.neorg_5,
    },
    tex = { list_patterns.latex_item },
    plaintex = { list_patterns.latex_item },
  },
  checkbox = {
    left = "%[", -- the left checkbox delimiter (you could change to "%(" for brackets)
    right = "%]", -- the right checkbox delim (same customisation as above)
    fill = "x", -- if you do the above two customisations, your checkbox could be (x) instead of [x]
  },

  -- this is all based on lua patterns, see "Defining custom lists" for a nice article to learn them
}

function handle_checkbox()
  local config = require("autolist.config")
  local auto = require("autolist.auto")

  local checkbox_pattern = " [ ]"

  local filetype_lists = config.lists[vim.bo.filetype]
  local line = vim.fn.getline(".")

  for i, list_pattern in ipairs(filetype_lists) do
    local list_item = line:match("^%s*" .. list_pattern .. "%s*")  -- only bullet, no checkbox
    list_item = list_item:gsub("%s+", "")
    local is_list_item = list_item ~= nil -- only bullet, no checkbox
    local is_checkbox_item = line:match("^%s*" .. list_pattern .. "%s*" .. "%[.%]" .. "%s*") ~= nil -- bullet and checkbox  

    if is_list_item == true and is_checkbox_item == false then
      vim.fn.setline(".", (line:gsub(list_item, list_item .. checkbox_pattern, 1)))
      local cursor_pos = vim.api.nvim_win_get_cursor(0)
      vim.api.nvim_win_set_cursor(0, {cursor_pos[1], cursor_pos[2] + checkbox_pattern:len()})
      goto continue
    else
      auto.toggle_checkbox()
      goto continue
    end

  end
  ::continue::
end

-- function handle_checkbox()
--   local config = require("autolist.config")
--   local auto = require("autolist.auto")
--
--   local checkbox_pattern = " [ ]"
--
--   local filetype_list = config.lists[vim.bo.filetype]
--   local line = vim.fn.getline(".")
--
--   for i, list_pattern in ipairs(filetype_list) do
--     local list_item = line:match("^%s*" .. list_pattern .. "%s*")  -- only bullet, no checkbox
--     if list_item == nil then goto continue_for_loop end
--     list_item = list_item:gsub("%s+", "")
--     local is_list_item = list_item ~= nil -- only bullet, no checkbox
--     local is_checkbox_item = line:match("^%s*" .. list_pattern .. "%s*" .. "%[.%]" .. "%s*") ~= nil -- bullet and checkbox
--
--     if is_list_item == true and is_checkbox_item == false then
--       list_item = list_item:gsub('%)', '%%)')
--       vim.fn.setline(".", (line:gsub(list_item, list_item .. checkbox_pattern, 1)))
--
--       local cursor_pos = vim.api.nvim_win_get_cursor(0)
--       if cursor_pos[2] > 0 then
--         vim.api.nvim_win_set_cursor(0, {cursor_pos[1], cursor_pos[2] + checkbox_pattern:len()})
--       end
--       goto continue
--     else
--       auto.toggle_checkbox()
--       goto continue
--     end
--
--     ::continue_for_loop::
--   end
--   ::continue::
-- end
