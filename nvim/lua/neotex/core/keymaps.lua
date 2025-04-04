--[[ KEYBINDINGS REFERENCE

This file defines global keybindings, with special handling for terminal, markdown,
and Avante AI buffers. Functions like `set_terminal_keymaps()`, `set_markdown_keymaps()`,
and `set_avante_keymaps()` are called by autocmds when specific filetypes are detected.

----------------------------------------------------------------------------------
TERMINAL MODE KEYBINDINGS                      | DESCRIPTION
----------------------------------------------------------------------------------
<Esc>                                          | Exit terminal mode to normal mode
<C-t>                                          | Toggle terminal window
<C-h>, <C-j>, <C-k>, <C-l>                     | Navigate between windows
<C-a>                                          | Ask Avante AI a question (non-lazygit only)
<M-h>, <M-l>, <M-Left>, <M-Right>              | Resize terminal window horizontally

----------------------------------------------------------------------------------
GENERAL KEYBINDINGS                            | DESCRIPTION
----------------------------------------------------------------------------------
<Space>                                        | Leader key for command sequences
<C-z>                                          | Disabled (prevents accidental suspension)
<C-t>                                          | Toggle terminal window
<C-s>                                          | Show spelling suggestions with Telescope
<CR> (Enter)                                   | Clear search highlighting
<C-p>                                          | Find files with Telescope
<C-;>                                          | Toggle comments for current line/selection
<S-m>                                          | Show help for word under cursor
<C-m>                                          | Search man pages with Telescope

----------------------------------------------------------------------------------
TEXT NAVIGATION                                | DESCRIPTION
----------------------------------------------------------------------------------
Y                                              | Yank (copy) from cursor to end of line
E                                              | Go to end of previous word
m                                              | Center cursor at top of screen
<C-h>, <C-j>, <C-k>, <C-l>                    | Navigate between windows
<A-Left>, <A-Right>, <A-h>, <A-l>             | Resize window horizontally
<Tab>                                          | Go to next buffer (by modified time)
<S-Tab>                                        | Go to previous buffer (by modified time)
<C-u>, <C-d>                                   | Scroll half-page up/down (with centering)
<S-h>, <S-l>                                   | Go to start/end of line
J, K                                           | Navigate display lines (respects wrapping)

----------------------------------------------------------------------------------
TEXT MANIPULATION                              | DESCRIPTION
----------------------------------------------------------------------------------
<A-j>, <A-k>                                   | Move current line or selection up/down
<, >                                           | Decrease/increase indentation

----------------------------------------------------------------------------------
MARKDOWN-SPECIFIC KEYBINDINGS                  | DESCRIPTION
----------------------------------------------------------------------------------
<CR> (Enter)                                   | Create new bullet point
o                                              | Create new bullet point below
O                                              | Create new bullet point above
<Tab>                                          | Indent bullet and recalculate numbers
<S-Tab>                                        | Unindent bullet and recalculate numbers
dd                                             | Delete line and recalculate list numbers
d (visual mode)                                | Delete selection and recalculate numbers
<C-n>                                          | Toggle checkbox status ([ ] ↔ [x])

----------------------------------------------------------------------------------
AVANTE AI BUFFER KEYBINDINGS                   | DESCRIPTION
----------------------------------------------------------------------------------
<C-t>                                          | Toggle Avante interface
q                                              | Toggle Avante interface
<C-c>                                          | Reset/clear Avante content
<C-m>                                          | Select model for current provider
<C-p>                                          | Select provider and model
<C-s>                                          | Stop AI generation
<C-d>                                          | Select provider/model with default option
<CR> (Enter)                                   | Create new line (prevents submission)
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
    vim.api.nvim_buf_set_keymap(0, "n", "<C-a>", "<Cmd>AvanteAsk<CR>", {})
    vim.api.nvim_buf_set_keymap(0, "v", "<C-a>", "<Cmd>AvanteAsk<CR>", {})
    -- More Avante mappings are included in Avante.lua
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

-- Avante AI buffer mappings setup function triggered by an auto-command
function _G.set_avante_keymaps()
  local function map(mode, key, cmd, desc)
    vim.api.nvim_buf_set_keymap(0, mode, key, cmd,
      { noremap = true, silent = true, desc = desc })
  end
  
  -- Toggle Avante interface
  map("n", "<C-t>", "<cmd>AvanteToggle<CR>", "Toggle Avante interface")
  map("i", "<C-t>", "<cmd>AvanteToggle<CR>", "Toggle Avante interface")
  map("n", "q", "<cmd>AvanteToggle<CR>", "Toggle Avante interface")
  
  -- Reset/clear Avante content
  map("n", "<C-c>", "<cmd>AvanteReset<CR>", "Reset Avante content")
  map("i", "<C-c>", "<cmd>AvanteReset<CR>", "Reset Avante content")
  
  -- Cycle AI models and providers
  map("n", "<C-m>", "<cmd>AvanteModel<CR>", "Select model for current provider")
  map("i", "<C-m>", "<cmd>AvanteModel<CR>", "Select model for current provider")
  map("n", "<C-p>", "<cmd>AvanteProvider<CR>", "Select provider and model")
  map("i", "<C-p>", "<cmd>AvanteProvider<CR>", "Select provider and model")
  
  -- Stop generation and provider selection
  map("n", "<C-s>", "<cmd>AvanteStop<CR>", "Stop Avante generation")
  map("i", "<C-s>", "<cmd>AvanteStop<CR>", "Stop Avante generation")
  map("n", "<C-d>", "<cmd>AvanteProvider<CR>", "Select provider/model with default option")
  map("i", "<C-d>", "<cmd>AvanteProvider<CR>", "Select provider/model with default option")
  
  -- Explicitly map <CR> in insert mode to just create a new line
  map("i", "<CR>", "<CR>", "Create new line (prevent submit)")
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

-- Terminal - ToggleTerm handles <C-t> via its own mapping
-- These are kept as fallbacks in case the plugin isn't loaded
vim.keymap.set("n", "<C-t>", "<cmd>ToggleTerm<CR>", { remap = true })
vim.keymap.set("t", "<C-t>", "<cmd>ToggleTerm<CR>", { remap = true })

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
-- Simple buffer navigation - using custom GotoBuffer function instead for smarter navigation
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

