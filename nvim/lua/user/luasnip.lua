local ls = require("luasnip")

require("luasnip.loaders.from_snipmate").load({ paths = "~/.config/nvim/snippets/" })

-- Key Mapping --{{{

-- vim.keymap.set({ "i", "s" }, "<c-s>", "<Esc>:w<cr>")
-- vim.keymap.set({ "i", "s" }, "<c-u>", '<cmd>lua require("luasnip.extras.select_choice")()<cr><C-c><C-c>')

-- vim.keymap.set({ "i", "s" }, "<CR>", function()
-- 	if ls.expand_or_jumpable() then
-- 		ls.expand()
-- 	end
-- end, { silent = true })
-- vim.keymap.set({ "i", "s" }, "<C-l>", function()
-- 	if ls.expand_or_jumpable() then
-- 		ls.expand_or_jump()
-- 	end
-- end, { silent = true })
-- vim.keymap.set({ "i", "s" }, "<C-h>", function()
-- 	if ls.jumpable() then
-- 		ls.jump(-1)
-- 	end
-- end, { silent = true })

-- vim.keymap.set({ "i", "s" }, "<A-y>", "<Esc>o", { silent = true })

-- vim.keymap.set({ "i", "s" }, "<a-k>", function()
-- 	if ls.jumpable(1) then
-- 		ls.jump(1)
-- 	end
-- end, { silent = true })
-- vim.keymap.set({ "i", "s" }, "<a-j>", function()
-- 	if ls.jumpable(-1) then
-- 		ls.jump(-1)
-- 	end
-- end, { silent = true })

-- vim.keymap.set({ "i", "s" }, "<a-l>", function()
-- 	if ls.choice_active() then
-- 		ls.change_choice(1)
-- 	else
-- 		-- print current time
-- 		local t = os.date("*t")
-- 		local time = string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
-- 		print(time)
-- 	end
-- end)
-- vim.keymap.set({ "i", "s" }, "<a-h>", function()
-- 	if ls.choice_active() then
-- 		ls.change_choice(-1)
-- 	end
-- end) --}}}

-- More Settings --

-- vim.keymap.set("n", "<Leader><CR>", "<cmd>LuaSnipEdit<cr>", { silent = true, noremap = true })
-- vim.cmd([[autocmd BufEnter */snippets/*.lua nnoremap <silent> <buffer> <CR> /-- End Refactoring --<CR>O<Esc>O]])
