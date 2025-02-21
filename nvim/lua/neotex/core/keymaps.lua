--[[
Keybindings Documentation:

Terminal Mode:
  <esc>       -> Exit terminal mode
  <C-t>       -> Toggle terminal
  <C-h/j/k/l> -> Navigate windows
  <C-a>       -> Avante Ask (non-lazygit only)
  <C-c>       -> Avante Chat (non-lazygit only)

General:
  <Space>     -> Leader key
  <C-z>       -> Disabled
  <C-t>       -> Toggle terminal
  <C-s>       -> Show spelling suggestions (Telescope)
  <CR>        -> Clear search highlights
  <C-p>       -> Find files (Telescope)
  <C-;>       -> Toggle comments (line/visual)
  <S-m>       -> Show help for word under cursor

Navigation:
  Y           -> Yank to end of line
  E           -> Go to end of previous word
  m           -> Center cursor at top of screen
  <C-h/j/k/l> -> Window navigation
  <A-Left/Right> -> Resize window horizontally
  <A-h/l>     -> Resize window horizontally
  <TAB>       -> Next buffer by modified time
  <S-TAB>     -> Previous buffer by modified time
  <BS>        -> Next buffer
  <S-BS>      -> Previous buffer
  <C-u/d>     -> Scroll up/down (centered)
  <S-h/l>     -> Go to start/end of line
  J/K         -> Navigate display lines

Text Manipulation:
  <A-j/k>     -> Move line(s) up/down
  </>>        -> Decrease/Increase indentation
  
Markdown Specific:
  <CR>        -> New bullet point
  o           -> New bullet point below
  O           -> New bullet point above
  <tab>       -> Indent bullet
  <S-tab>     -> Unindent bullet
  dd          -> Delete line and recalculate
  <C-n>       -> Toggle checkbox
--]]

local opts = { noremap = true, silent = true }

-- local term_opts = { silent = true }

-- Shorten function name
local keymap = vim.api.nvim_set_keymap

-- Terminal mappings setup function triggered by an auto-command
function _G.set_terminal_keymaps()
  -- Set the terminal window as fixed
  vim.wo.winfixbuf = true
  -- NOTE: use vim.api.nvim_buf_set_keymap to keep these mappings local to a buffer
  vim.api.nvim_buf_set_keymap(0, "t", "<esc>", "<C-\\><C-n>", {})
  -- Only set Avante mappings for non-lazygit buffers
  if vim.bo.filetype ~= "lazygit" then
    vim.api.nvim_buf_set_keymap(0, "t", "<C-a>", "<Cmd>AvanteAsk<CR>", {})
    -- vim.api.nvim_buf_set_keymap(0, "t", "<C-c>", "<Cmd>AvanteChat<CR>", {})
    vim.api.nvim_buf_set_keymap(0, "n", "<C-a>", "<Cmd>AvanteAsk<CR>", {})
    -- vim.api.nvim_buf_set_keymap(0, "n", "<C-c>", "<Cmd>AvanteChat<CR>", {})
    vim.api.nvim_buf_set_keymap(0, "v", "<C-a>", "<Cmd>AvanteAsk<CR>", {})
    -- vim.api.nvim_buf_set_keymap(0, "v", "<C-c>", "<Cmd>AvanteChat<CR>", {})
  end
  vim.api.nvim_buf_set_keymap(0, "t", "<M-Right>", "<Cmd>vertical resize -2<CR>", {})
  vim.api.nvim_buf_set_keymap(0, "t", "<M-Left>", "<Cmd>vertical resize +2<CR>", {})
  vim.api.nvim_buf_set_keymap(0, "t", "<M-l>", "<Cmd>vertical resize -2<CR>", {})
  vim.api.nvim_buf_set_keymap(0, "t", "<M-h>", "<Cmd>vertical resize +2<CR>", {})

  vim.api.nvim_buf_set_keymap(0, "t", "<C-h>", "<Cmd>wincmd h<CR>", {})
  vim.api.nvim_buf_set_keymap(0, "t", "<C-j>", "<Cmd>wincmd j<CR>", {})
  vim.api.nvim_buf_set_keymap(0, "t", "<C-k>", "<Cmd>wincmd k<CR>", {})
  vim.api.nvim_buf_set_keymap(0, "t", "<C-l>", "<Cmd>wincmd l<CR>", {})
  -- vim.api.nvim_buf_set_keymap(0, "t", "<C-w>", "<C-\\><C-n><C-w>", {})
end

-- Markdown mappings setup function triggered by an auto-command
function _G.set_markdown_keymaps()
  -- NOTE: use vim.api.nvim_buf_set_keymap to keep these mappings local to a buffer
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
-- local map = vim.keymap.set -- for conciseness

--Remap space as leader key
vim.g.mapleader = " "
-- vim.g.maplocalleader = " "


-------------------- General Keymaps --------------------

-- delete single character without copying into register
-- keymap("n", "x", '"_x', opts)
-- keymap("v", "p", '"_p', opts)

-- Unmappings
keymap("n", "<C-z>", "<nop>", opts)
keymap("n", "gc", "<nop>", opts)
keymap("n", "gcc", "<nop>", opts)

-- NOTE: not sure I will uses these cmp-vimtex commands
-- Search from hovering over cmp-vimtex citation completion
-- vim.keymap.set("i", "<C-z>", function() 
--   require('cmp_vimtex.search').search_menu()
-- end)
-- vim.keymap.set("i", "<C-z>", function() 
--   require('cmp_vimtex.search').perform_search({ engine = "arxiv" })
-- end)

-- NOTE: prefer to use whichkey
-- Surround 
-- vim.keymap.set("v", '<C-s>', 'S', { remap = true }) -- see surround.lua

-- Terminal
vim.keymap.set("n", "<C-t>", "<cmd>lua Snacks.terminal.toggle()<CR>", { remap = true })
vim.keymap.set("t", "<C-t>", "<cmd>lua Snacks.terminal.toggle()<CR>", { remap = true })

-- Spelling
vim.keymap.set("n", "<C-s>", function()
  require("telescope.builtin").spell_suggest(require("telescope.themes").get_cursor({
      previewer = false,
      layout_config = {
        width = 50,
        height = 15,
      }
    })
  )
end, { remap = true })
-- vim.keymap.set("n", "<C-s>", "z=", { remap = true}) 
-- keymap("n", "<C-s>", "<cmd>Telescope spell_suggest<cr>", { remap = true})

-- Kill search highlights
keymap("n", "<CR>", "<cmd>noh<CR>", opts)


-- Find project files
vim.keymap.set("n", "<C-p>", "<cmd>Telescope find_files<CR>", { remap = true })
  -- function ()
  --   require('telescope.builtin').find_files(require('telescope.themes').get_dropdown({previewer = false}))
  -- end, 


-- Toggle comments
keymap('n', "<C-;>", '<Plug>(comment_toggle_linewise_current)', opts)
keymap('x', "<C-;>", '<Plug>(comment_toggle_linewise_visual)', opts)


-- Open help on word
keymap("n", "<S-m>", '<cmd>Telescope help_tags cword=true<cr>', opts)
-- keymap("n", "<S-m>", "<cmd>Telescope help_tags default_text=<C-r><C-w><cr>", opts)
-- keymap("n", "<S-m>", ':execute "help " . expand("<cword>")<cr>', opts)
keymap("n", "<C-m>", '<cmd>Telescope man_pages<cr>', opts)


-- Fix 'Y', 'E'
keymap("n", "Y", "y$", opts)
keymap("n", "E", "ge", opts)
keymap("v", "Y", "y$", opts)
-- keymap("v", "E", "ge", opts) -- causes errors with luasnip autocmp


-- Avoid cutting text pasted over
-- keymap("v", "p", '"_dP', opts)


-- Center cursor
keymap("n", "m", "zt", opts)
keymap("v", "m", "zt", opts)


-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)


-- Resize with arrows
-- keymap("n", "<C-Up>", ":resize -2<CR>", opts)
-- keymap("n", "<C-Down>", ":resize +2<CR>", opts)
keymap("n", "<A-Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<A-Right>", ":vertical resize +2<CR>", opts)
keymap("n", "<A-h>", ":vertical resize -2<CR>", opts)
keymap("n", "<A-l>", ":vertical resize +2<CR>", opts)


-- Navigate buffers
keymap("n", "<TAB>", "", {callback = function() GotoBuffer(1, 1) end, desc = 'Next buffer by modified time'})
keymap("n", "<S-TAB>", "", {callback = function() GotoBuffer(1, -1) end, desc = 'Previous buffer by modified time'})
-- keymap("n", "<BS>", "<CMD>bnext<CR>", opts)
-- keymap("n", "<S-BS>", "<CMD>bprevious<CR>", opts)


-- Drag lines
keymap("n", "<A-j>", "<Esc>:m .+1<CR>==", opts)
keymap("n", "<A-k>", "<Esc>:m .-2<CR>==", opts)
keymap("x", "<A-j>", ":move '>+1<CR>gv-gv", opts)
keymap("x", "<A-k>", ":move '<-2<CR>gv-gv", opts)
keymap("v", "<A-j>", ":m'>+<CR>gv", opts)
keymap("v", "<A-k>", ":m-2<CR>gv", opts)


-- Horizontal line movments --
keymap("n", "<c-u>", "<c-u>zz", opts)
keymap("n", "<c-d>", "<c-d>zz", opts)


-- Horizontal line movments --
keymap("v", "<S-h>", "g^", opts)
keymap("v", "<S-l>", "g$", opts)
keymap("n", "<S-h>", "g^", opts)
keymap("n", "<S-l>", "g$", opts)


-- Indentation
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)
keymap("n", "<", "<S-v><<esc>", opts)
keymap("n", ">", "<S-v>><esc>", opts)


-- Navigate display lines
keymap("n", "J", "gj", opts)
keymap("n", "K", "gk", opts)
keymap("v", "J", "gj", opts)
keymap("v", "K", "gk", opts)

