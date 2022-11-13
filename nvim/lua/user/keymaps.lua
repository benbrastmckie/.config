local opts = { noremap = true, silent = true }

local term_opts = { silent = true }

-- Shorten function name
local keymap = vim.api.nvim_set_keymap

--Remap space as leader key
keymap("", "<Space>", "<Nop>", opts)
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

-- Spelling
vim.keymap.set("n", "<C-s>", "z=", { remap = true})

-- Kill search highlights
keymap("n", "<CR>", ":noh<CR>", opts)

-- Find project files
keymap("n", "<C-p>", "<cmd>lua require('telescope.builtin').find_files(require('telescope.themes').get_dropdown{previewer = false})<cr>", opts)

-- Comment
vim.keymap.set('n', '<C-Bslash>', "gcc", { remap = true})
vim.keymap.set("v", "<C-Bslash>", "gc", { remap = true})

-- Open help on word
keymap("n", "<S-m>", ':execute "help " . expand("<cword>")<cr>', opts)

-- Fix 'Y', 'E'
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
keymap("v", "<A-j>", ":m .+1<CR>==", opts)
keymap("v", "<A-k>", ":m .-2<CR>==", opts)

-- Horizontal lime movments --
keymap("v", "<S-h>", "^", opts)
keymap("v", "<S-l>", "$", opts)
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

