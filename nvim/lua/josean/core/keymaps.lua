local opts = { noremap = true, silent = true }

local term_opts = { silent = true }

-- Shorten function name
local keymap = vim.api.nvim_set_keymap
local map = vim.keymap.set -- for conciseness

--Remap space as leader key
vim.g.mapleader = " "
-- vim.g.maplocalleader = " "


-------------------- General Keymaps --------------------

-- delete single character without copying into register
-- keymap("n", "x", '"_x', opts)
-- keymap("v", "p", '"_p', opts)

-- Unmappings
keymap("n", "<C-z>", "<nop>", opts)


-- Surround 
-- vim.keymap.set("v", '<C-s>', 'S', { remap = true }) -- see surround.lua


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
keymap('n', '<C-Bslash>', '<Plug>(comment_toggle_linewise_current)', opts)
keymap('x', '<C-Bslash>', '<Plug>(comment_toggle_linewise_visual)', opts)

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
keymap("n", "<TAB>", ":bnext<CR>", opts)
keymap("n", "<S-TAB>", ":bprevious<CR>", opts)


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

-- NOTE: All leader driven keymaps are now in which-key.lua
-- -- WhichKey general mappings
-- map("n", "<leader>b", "<cmd>VimtexCompile<CR>",   { desc = "build" })
-- map("n", "<leader>d", "<cmd>bdelete!<CR>",        { desc = "delete buffer" })
-- map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>",  { desc = "explorer" })
-- map("n", "<leader>i", "<cmd>VimtexTocOpen<CR>",   { desc = "index" })
-- map("n", "<leader>q", "<cmd>wqa!<CR>",            { desc = "quit" })
-- map("n", "<leader>u", "<cmd>Telescope undo<CR>",  { desc = "undo" })
-- map("n", "<leader>v", "<cmd>VimtexView<CR>",      { desc = "view" })
-- map("n", "<leader>w", "<cmd>wa!<CR>",             { desc = "write" })
--
--
-- -- WhichKey actions
-- map("n", "<leader>aa", "<cmd>lua PdfAnnots()<CR>", { desc = "annotate"})
-- map("n", "<leader>ab", "<cmd>terminal bibexport -o %:p:r.bib %:p:r.aux<CR>", { desc = "bib export"})
-- map("n", "<leader>ac", "<cmd>VimtexCountWords!<CR>", { desc = "count" })
-- map("n", "<leader>ag", "<cmd>e ~/.config/nvim/templates/Glossary.tex<CR>", { desc = "edit glossary"})
-- map("n", "<leader>ah", "<cmd>lua _HTOP_TOGGLE()<CR>", { desc = "htop" })
-- map("n", "<leader>ai", "<cmd>IlluminateToggle<CR>", { desc = "illuminate" })
-- map("n", "<leader>ak", "<cmd>VimtexClean<CR>", { desc = "kill aux" })
-- map("n", "<leader>al", "<cmd>lua vim.g.cmptoggle = not vim.g.cmptoggle<CR>", { desc = "LSP"})
-- map("n", "<leader>ap", "<cmd>lua require('nabla').popup()<CR>", { desc = "preview symbols"})
-- map("n", "<leader>ar", "<cmd>VimtexErrors<CR>", { desc = "report errors" })
-- map("n", "<leader>as", "<cmd>e ~/.config/nvim/snippets/tex.snippets<CR>", { desc = "edit snippets"})
-- map("n", "<leader>au", "<cmd>cd %:p:h<CR>", { desc = "update cwd" })
-- map("n", "<leader>av", "<plug>(vimtex-context-menu)"            , { desc = "vimtex menu" })
-- -- map("n", "<leader>aw", "<cmd>TermExec cmd='pandoc %:p -o %:p:r.docx'<CR>" , { desc = "word"})
--
--
-- -- WhichKey citations
-- map("n", "<leader>ct", "<cmd>Telescope bibtex format_string=\\citet{%s}<CR>"       , { desc = "\\citet" })
-- map("n", "<leader>cp", "<cmd>Telescope bibtex format_string=\\citep{%s}<CR>"       , { desc = "\\citep" })
-- map("n", "<leader>cs", "<cmd>Telescope bibtex format_string=\\citepos{%s}<CR>"       , { desc = "\\citepos" })
--
--
-- -- WhichKey find
-- map("n", "<leader>fb", "<cmd>lua require('telescope.builtin').buffers(require('telescope.themes').get_dropdown{previewer = false})<CR>", { desc = "buffers" })
-- map("n", "<leader>ff", "<cmd>Telescope live_grep theme=ivy<CR>", { desc = "project" })
-- map("n", "<leader>fg", "<cmd>Telescope git_branches<CR>", { desc = "branches" })
-- map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "help" })
-- map("n", "<leader>fk", "<cmd>Telescope keymaps<CR>", { desc = "keymaps" })
-- map("n", "<leader>fr", "<cmd>Telescope registers<CR>", { desc = "registers" })
-- map("n", "<leader>ft", "<cmd>Telescope colorscheme<CR>", { desc = "theme" })
-- map("n", "<leader>fy", "<cmd>YankyRingHistory<CR>"       , { desc = "yanks" })
-- -- map("n", "<leader>fm", "<cmd>Telescope man_pages<CR>", { desc = "man pages" })
-- -- map("n", "<leader>fc", "<cmd>Telescope bibtex format_string=\\citet{%s}<CR>"       , { desc = "citations" })
-- -- map("n", "<leader>fc", "<cmd>Telescope commands<CR>", { desc = "commands" })
-- -- map("n", "<leader>fr", "<cmd>Telescope oldfiles<CR>", { desc = "recent" })
--
--
-- -- WhichKey git
-- map("n", "<leader>gg", "<cmd>lua _LAZYGIT_TOGGLE()<CR>", { desc = "lazygit" })
-- map("n", "<leader>gj", "<cmd>lua require 'gitsigns'.next_hunk()<CR>", { desc = "next hunk" })
-- map("n", "<leader>gk", "<cmd>lua require 'gitsigns'.prev_hunk()<CR>", { desc = "prev hunk" })
-- map("n", "<leader>gl", "<cmd>lua require 'gitsigns'.blame_line()<CR>", { desc = "blame" })
-- map("n", "<leader>gp", "<cmd>lua require 'gitsigns'.preview_hunk()<CR>", { desc = "preview hunk" })
-- map("n", "<leader>gr", "<cmd>lua require 'gitsigns'.reset_hunk()<CR>", { desc = "reset hunk" })
-- map("n", "<leader>gs", "<cmd>lua require 'gitsigns'.stage_hunk()<CR>", { desc = "stage hunk" })
-- map("n", "<leader>gu", "<cmd>lua require 'gitsigns'.undo_stage_hunk()<CR>", { desc = "unstage hunk" })
-- map("n", "<leader>go", "<cmd>Telescope git_status<CR>", { desc = "open changed file" })
-- map("n", "<leader>gb", "<cmd>Telescope git_branches<CR>", { desc = "checkout branch" })
-- map("n", "<leader>gc", "<cmd>Telescope git_commits<CR>", { desc = "checkout commit" })
-- map("n", "<leader>gd", "<cmd>Gitsigns diffthis HEAD<CR>", { desc = "diff" })
--
--
-- -- WhichKey list
-- map("n", "<leader>lc", "<cmd>lua handle_checkbox()<CR>", { desc = "checkbox" })
-- map("n", "<leader>ln", "<cmd>AutolistCycleNext<CR>", { desc = "next" })
-- map("n", "<leader>lp", "<cmd>AutolistCyclePrev<CR>", { desc = "previous" })
-- map("n", "<leader>lr", "<cmd>AutolistRecalculate<CR>", { desc = "reorder" })
-- -- map("n", "<leader>lx", "<cmd>AutolistToggleCheckbox<cr><CR>", { desc = "checkmark" })
--
--
-- -- WhichKey sessions
-- map("n", "<leader>ss", "<cmd>SessionManager save_current_session<CR>", { desc = "save" })
-- map("n", "<leader>sd", "<cmd>SessionManager delete_session<CR>", { desc = "delete" })
-- map("n", "<leader>sl", "<cmd>SessionManager load_session<CR>", { desc = "load" })
--
--
-- -- WhichKey pandoc
-- map("n", "<leader>pw", "<cmd>TermExec cmd='pandoc %:p -o %:p:r.docx'<CR>" , { desc = "word"})
-- map("n", "<leader>pm", "<cmd>TermExec cmd='pandoc %:p -o %:p:r.md'<CR>"   , { desc = "markdown"})
-- map("n", "<leader>ph", "<cmd>TermExec cmd='pandoc %:p -o %:p:r.html'<CR>" , { desc = "html"})
-- map("n", "<leader>pl", "<cmd>TermExec cmd='pandoc %:p -o %:p:r.tex'<CR>"  , { desc = "latex"})
-- map("n", "<leader>pp", "<cmd>TermExec cmd='pandoc %:p -o %:p:r.pdf'<CR>"  , { desc = "pdf"})
-- -- map("n", "<leader>px", "<cmd>echo "run: unoconv -f pdf path-to.docx""  , { desc = "word to pdf"})
--
--
-- -- WhichKey surround
-- map("n", "<leader>ss", "<Plug>(nvim-surround-normal)", { desc = "surround" })
-- map("n", "<leader>sd", "<Plug>(nvim-surround-delete)", { desc = "delete" })
-- map("n", "<leader>sc", "<Plug>(nvim-surround-change)", { desc = "change" })
--
--
-- -- WhichKey templates
-- map("n", "<leader>tc", "<cmd>PackerCompile<CR>", { desc = "Compile" })
-- map("n", "<leader>tp", "<cmd>read ~/.config/nvim/templates/PhilPaper.tex<CR>", { desc = "PhilPaper.tex" })
-- map("n", "<leader>tl", "<cmd>read ~/.config/nvim/templates/Letter.tex<CR>", { desc = "Letter.tex" })
-- map("n", "<leader>tg", "<cmd>read ~/.config/nvim/templates/Glossary.tex<CR>", { desc = "Glossary.tex" })
-- map("n", "<leader>th", "<cmd>read ~/.config/nvim/templates/HandOut.tex<CR>", { desc = "HandOut.tex" })
-- map("n", "<leader>tb", "<cmd>read ~/.config/nvim/templates/PhilBeamer.tex<CR>", { desc =  "PhilBeamer.tex" })
-- map("n", "<leader>ts", "<cmd>read ~/.config/nvim/templates/SubFile.tex<CR>", { desc = "SubFile.tex" })
-- map("n", "<leader>tr", "<cmd>read ~/.config/nvim/templates/Root.tex<CR>", { desc = "Root.tex" })
-- map("n", "<leader>tm", "<cmd>read ~/.config/nvim/templates/MultipleAnswer.tex<CR>", { desc = "MultipleAnswer.tex" })
