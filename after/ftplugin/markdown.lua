-- local config = require("nvim-surround.config")

require("nvim-surround").buffer_setup({
  surrounds = {
    -- ["e"] = {
    --   add = function()
    --     local env = require("nvim-surround.config").get_input ("Environment: ")
    --     return { { "\\begin{" .. env .. "}" }, { "\\end{" .. env .. "}" } }
    --   end,
    -- },
    ["b"] = {
      add = { "**", "**" },
      find = "**.-**",
      delete = "^(**)().-(**)()$",
    },
    ["i"] = {
      add = { "*", "*" },
      find = "*.-*",
      delete = "^(*)().-(*)()$",
    },
  },
})


-- vim.cmd [[
--   function Check()
--     let l:line=getline('.')
--     let l:curs=winsaveview()
--     if l:line=~?'\s*-\s*\[\s*\].*'
--       s/\[\s*\]/[.]/
--     elseif l:line=~?'\s*-\s*\[\.\].*'
--       s/\[.\]/[x]/
--     elseif l:line=~?'\s*-\s*\[x\].*'
--       s/\[x\]/[ ]/
--     endif
--     call winrestview(l:curs)
--   endfunction
--
--   autocmd FileType markdown nnoremap <Leader>c :call Check()<CR>
-- ]]
--
-- vim.cmd [[
--   function! ToggleCheckbox()
--     let line = getline('.')
--
--     if line =~ '- \[ \]'
--       call setline('.', substitute(line, '- \[ \]', '- \[x\]', ''))
--     elseif line =~ '- \[x\]'
--       call setline('.', substitute(line, '- \[x\]', '- \[ \]', ''))
--     elseif line =~ '- '
--       call setline('.', substitute(line, '- ', '- \[ \] ', ''))
--     endif
--   endfunction
--
--   autocmd FileType markdown nnoremap <Leader>c :call ToggleCheckbox()<CR>
-- ]]


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

-- vim.g.mkdp_browser = '/run/current-system/sw/bit/vivaldi'

-- -- Autolist markdown mappings
--
-- -- vim.keymap.set("i", "<tab>", "<cmd>AutolistTab<cr>")
-- -- vim.keymap.set("i", "<s-tab>", "<cmd>AutolistShiftTab<cr>")
-- vim.keymap.set("i", "<CR>", "<CR><cmd>AutolistNewBullet<cr>")
-- vim.keymap.set("n", "o", "o<cmd>AutolistNewBullet<cr>")
-- vim.keymap.set("n", "O", "O<cmd>AutolistNewBulletBefore<cr>")
--
-- -- functions to recalculate list on edit
-- vim.keymap.set("i", "<tab>", "<Esc>>lla<cmd>AutolistRecalculate<cr>")
-- vim.keymap.set("i", "<s-tab>", "<Esc><<cmd>AutolistRecalculate<cr>a")
-- vim.keymap.set("n", "dd", "dd<cmd>AutolistRecalculate<cr>")
-- vim.keymap.set("v", "d", "d<cmd>AutolistRecalculate<cr>")
-- vim.keymap.set("n", ">", "><cmd>AutolistRecalculate<cr>")
-- vim.keymap.set("n", "<", "<<cmd>AutolistRecalculate<cr>")
-- vim.keymap.set("n", "<C-c>", "<cmd>AutolistRecalculate<cr>")
--
-- -- toggle checkbox
-- -- vim.keymap.set({ "n", "i", "v", "x" }, "<C-x>", "<cmd>lua handle_checkbox()<CR>")
-- -- vim.keymap.set({ "n", "i", "v", "x" }, "<C-x>", "<cmd>AutolistToggleCheckbox<cr>")
--
-- -- cycle list types with dot-repeat
-- -- vim.keymap.set("n", "<leader>cn", require("autolist").cycle_next_dr, { expr = true })
-- -- vim.keymap.set("n", "<leader>cp", require("autolist").cycle_prev_dr, { expr = true })
