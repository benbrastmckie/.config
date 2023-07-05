local options = {
  spell = true,
  spelllang = { 'en_gb' },
  backup = false,                          -- creates a backup file
  clipboard = "unnamedplus",               -- allows neovim to access the system clipboard
  cmdheight = 2,                           -- more space in the neovim command line for displaying messages
  completeopt = { "menuone", "noselect" }, -- mostly just for cmp
  conceallevel = 0,                        -- so that `` is visible in markdown files
  fileencoding = "utf-8",                  -- the encoding written to a file
  hlsearch = true,                         -- highlight all matches on previous search pattern
  ignorecase = true,                       -- ignore case in search patterns
  mouse = "a",                             -- allow the mouse to be used in neovim
  pumheight = 10,                          -- pop up menu height
  showmode = false,                        -- we don't need to see things like -- INSERT -- anymore
  showtabline = 2,                         -- always show tabs
  smartcase = true,                        -- smart case
  smartindent = false,                     -- make indenting smarter again
  autoindent = false,                     -- make indenting smarter again
  splitbelow = true,                       -- force all horizontal splits to go below current window
  splitright = true,                       -- force all vertical splits to go to the right of current window
  swapfile = false,                        -- creates a swapfile
  termguicolors = true,                    -- set term gui colors (most terminals support this)
  timeoutlen = 100,                        -- time to wait for a mapped sequence to complete (in milliseconds)
  undofile = true,                         -- enable persistent undo
  updatetime = 300,                        -- faster completion (4000ms default)
  writebackup = false,                     -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
  tabstop = 2,                             -- insert 2 spaces for a tab
  shiftwidth = 2,                          -- the number of spaces inserted for each indentation
  softtabstop = 2,                         -- insert 2 spaces for a tab
  expandtab = true,                        -- convert tabs to spaces
  cursorline = true,                       -- highlight the current line
  number = true,                           -- set numbered lines
  relativenumber = true,                   -- set relative numbered lines
  numberwidth = 4,                         -- set number column width to 2 {default 4}

  signcolumn = "yes",                      -- always show the sign column, otherwise it would shift the text each time
  wrap = true,                             -- display lines as one long line
  breakindent = true,                      -- tab wrapped lines
  linebreak = true,                        -- companion to wrap, don't split words
  showbreak = "  ",                        -- set indent of wrapped lines
  scrolloff = 7,                           -- minimal number of screen lines to keep above and below the cursor
  sidescrolloff = 7,                       -- minimal number of screen columns either side of cursor if wrap is `false`
  guifont = "monospace:h17",               -- the font used in graphical neovim applications
}

-- INDENT -- (see also vimtex.lua)
vim.g['tex_flavor'] = 'latex'
vim.g['tex_indent_items'] = 0              -- turn off enumerate indent
vim.g['tex_indent_brace'] = 0              -- turn off brace indent
-- vim.g['tex_indent_and'] = 0             -- whether to align with &
-- vim.g['latex_indent_enabled'] = 0
-- vim.g['vimtex_indent_enabled'] = 0
-- vim.g['did_indent'] = 1

vim.opt.shortmess:append "c"

for k, v in pairs(options) do
  vim.opt[k] = v
end

vim.cmd "set whichwrap+=<,>,[,],h,l"
-- vim.cmd [[set iskeyword+=-]]            -- unites dashed words

-- CLIPBOARD -- (for yanky)
-- Mac users delete to avoid "target string not available" error
vim.g.clipboard = {
  name = "xsel_override",
  copy = {
    ["+"] = "xsel --input --clipboard",
    ["*"] = "xsel --input --primary",
  },
  paste = {
    ["+"] = "xsel --output --clipboard",
    ["*"] = "xsel --output --primary",
  },
  cache_enabled = 1,
}

