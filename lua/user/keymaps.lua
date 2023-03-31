local opts = { noremap = true, silent = true }

local term_opts = { silent = true }

-- Shorten function name
local keymap = vim.api.nvim_set_keymap

--Remap space as leader key
-- keymap("", "<Space>", "<Nop>", opts) -- caused conflict with WhichKey
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",


-- NOTE Check mapping with :verbose map ____

-- Unmappings
keymap("n", "<C-z>", "<nop>", opts)


-- Surround
-- vim.keymap.set("v", '<C-s>', 'S', { remap = true })


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
keymap("n", "<CR>", ":noh<CR>", opts)


-- Find project files
vim.keymap.set("n", "<C-p>", function ()
  require('telescope.builtin').find_files(require('telescope.themes').get_dropdown({previewer = false})
  )
end, { remap = true })


-- Toggle comments
  vim.keymap.set('n', '<C-Bslash>', '<Plug>(comment_toggle_linewise_current)')
  vim.keymap.set('x', '<C-Bslash>', '<Plug>(comment_toggle_linewise_visual)')

-- Open help on word
keymap("n", "<S-m>", ':execute "help " . expand("<cword>")<cr>', opts)


-- Fix 'Y', 'E'
keymap("n", "Y", "y$", opts)
keymap("n", "E", "ge", opts)
keymap("v", "Y", "y$", opts)
keymap("v", "E", "ge", opts)


-- Avoid cutting text pasted over
keymap("v", "p", '"_dP', opts)


-- Center cursor
keymap("n", "m", "zz", opts)
keymap("v", "m", "zz", opts)


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
keymap("n", "<BS>", ":bnext<CR>", opts)
keymap("n", "<S-TAB>", ":bprevious<CR>", opts)


-- Drag lines
keymap("n", "<A-j>", "<Esc>:m .+1<CR>==", opts)
keymap("n", "<A-k>", "<Esc>:m .-2<CR>==", opts)
keymap("x", "<A-j>", ":move '>+1<CR>gv-gv", opts)
keymap("x", "<A-k>", ":move '<-2<CR>gv-gv", opts)
keymap("v", "<A-j>", ":m'>+<CR>gv", opts)
keymap("v", "<A-k>", ":m-2<CR>gv", opts)


-- Horizontal lime movments --
keymap("n", "<c-u>", "<c-u>zz", opts)
keymap("n", "<c-d>", "<c-d>zz", opts)


-- Horizontal lime movments --
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


-- Terminal --
-- Better terminal navigation
-- keymap("t", "<C-h>", "<C-\\><C-N><C-w>h", term_opts)
-- keymap("t", "<C-j>", "<C-\\><C-N><C-w>j", term_opts)
-- keymap("t", "<C-k>", "<C-\\><C-N><C-w>k", term_opts)
-- keymap("t", "<C-l>", "<C-\\><C-N><C-w>l", term_opts)

