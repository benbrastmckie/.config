local api = vim.api

-- close help, man, qf, lspinfo with 'q'
api.nvim_create_autocmd(
  "FileType",
  {
    pattern = { "man", "help", "qf", "lspinfo" }, -- "startuptime",
    command = "nnoremap <buffer><silent> q :close<CR>",
  }
)


-- Terminal mappings
function _G.set_terminal_keymaps()
  local opts = { buffer = 0 }
  vim.keymap.set('t', '<esc>', [[<C-c>]], opts)
  vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
  vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
  vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
  vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
  -- vim.keymap.set('t', '<C-w>', [[<C-\><C-n><C-w>]], opts)
end

vim.api.nvim_create_autocmd({ "TermOpen" }, {
  pattern = { "term://*" }, -- use term://*toggleterm#* for only ToggleTerm
  command = "lua set_terminal_keymaps()",
})

-- Autolist markdown mappings
function _G.set_markdown_keymaps()
  vim.api.nvim_buf_set_keymap(0, "i", "<CR>", "<CR><cmd>AutolistNewBullet<cr>", {})
  vim.api.nvim_buf_set_keymap(0, "n", "o", "o<cmd>AutolistNewBullet<cr>", {})
  vim.api.nvim_buf_set_keymap(0, "n", "O", "O<cmd>AutolistNewBulletBefore<cr>", {})
  vim.api.nvim_buf_set_keymap(0, "i", "<tab>", "<Esc>><cmd>AutolistRecalculate<cr>a<space>", {})
  vim.api.nvim_buf_set_keymap(0, "i", "<S-tab>", "<Esc><<cmd>AutolistRecalculate<cr>a", {})
  vim.api.nvim_buf_set_keymap(0, "n", "dd", "dd<cmd>AutolistRecalculate<cr>", {})
  vim.api.nvim_buf_set_keymap(0, "v", "d", "d<cmd>AutolistRecalculate<cr>", {})
  vim.api.nvim_buf_set_keymap(0, "n", ">", "><cmd>AutolistRecalculate<cr>", {})
  vim.api.nvim_buf_set_keymap(0, "n", "<", "<<cmd>AutolistRecalculate<cr>", {})
  vim.api.nvim_buf_set_keymap(0, "n", "<C-c>", "<cmd>AutolistRecalculate<cr>", {})
  vim.api.nvim_buf_set_keymap(0, "n", "<C-n>", "<cmd>lua HandleCheckbox()<CR>", {})
  vim.opt.tabstop = 2
  vim.opt.shiftwidth = 2
  vim.opt.softtabstop = 2
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufReadPre", "BufNewFile" }, {
  pattern = { "*.md" },
  command = "lua set_markdown_keymaps()",
})

-- Firenvim

-- vim.api.nvim_create_autocmd({'UIEnter'}, {
--     callback = function(event)
--         local client = vim.api.nvim_get_chan_info(vim.v.event.chan).client
--         if client ~= nil and client.name == "Firenvim" then
--             -- vim.o.laststatus = 0
--             cmd = "LspStop"
--         end
--     end
-- })

-- -- Neorg mappings
-- function _G.set_neorg_keymaps()
--   vim.api.nvim_buf_set_keymap(0, "i", "<C-CR>", "<cmd>Neorg keybind norg core.itero.next-iteration<CR>", {})
--   vim.api.nvim_buf_set_keymap(0, "n", "<C-CR>", "<cmd>Neorg keybind norg core.itero.next-iteration<CR>a", {})
--   vim.api.nvim_buf_set_keymap(0, "v", "<C-CR>", "<cmd>Neorg keybind norg core.itero.next-iteration<CR><Esc>a", {})
--   -- vim.api.nvim_buf_set_keymap(0, "i", "<Tab>", "<cmd>Neorg keybind norg core.promo.promote<CR>", {})
--   -- vim.api.nvim_buf_set_keymap(0, "i", "<S-Tab>", "<cmd>Neorg keybind norg core.promo.demote<CR>", {})
--   -- vim.api.nvim_buf_set_keymap(0, "n", ">", "<cmd>Neorg keybind norg core.promo.promote<CR>", {})
--   -- vim.api.nvim_buf_set_keymap(0, "n", "<", "<cmd>Neorg keybind norg core.promo.demote<CR>", {})
-- end
--
-- -- runs neorg keymaps in both .neorg and .md files
-- vim.api.nvim_create_autocmd({"BufEnter", "BufReadPre", "BufNewFile" }, {
--   pattern = {"*.norg"},
--   command = "lua set_neorg_keymaps()",
-- })
--
-- -- -- Make markdown read like Neorg
-- -- vim.api.nvim_create_autocmd({"BufEnter", "BufReadPre", "BufNewFile" }, {
-- --   pattern = {"*.md"},
-- --   command = "set filetype=norg",
-- -- })
