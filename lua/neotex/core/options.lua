local options = {

  -- GENERAL
  timeoutlen = 100,               -- time to wait for a mapped sequence to complete (in milliseconds)
  updatetime = 200,               -- faster completion (4000ms default)
  swapfile = false,               -- creates a swapfile
  undofile = true,                -- enable persistent undo
  writebackup = false,            -- if a file is being edited by another program, it is not allowed to be edited

  -- APPEARANCE
  fileencoding = "utf-8",         -- the encoding written to a file
  guifont = "monospace:h17",      -- the font used in graphical neovim applications
  background = "dark",            -- colorschemes that can be light or dark will be made dark
  termguicolors = true,           -- set term gui colors (most terminals support this)
  conceallevel = 0,               -- so that `` is visible in markdown files
  number = true,                  -- set numbered lines
  relativenumber = true,          -- set relative numbered lines
  numberwidth = 2,                -- set number column width to 2 {default 4}
  signcolumn = "yes",             -- always show the sign column, otherwise it would shift the text each time
  cursorline = true,              -- highlight the current line
  wrap = true,                    -- display lines as one long line
  showbreak = "  ",               -- set indent of wrapped lines
  cmdheight = 1,                  -- space in the neovim command line for displaying messages
  pumheight = 7,                 -- pop up menu height
  showmode = false,               -- we don't need to see things like -- INSERT -- anymore
  splitbelow = true,              -- force all horizontal splits to go below current window
  splitright = true,              -- force all vertical splits to go to the right of current window
  scrolloff = 7,                  -- minimal number of screen lines to keep above and below the cursor
  sidescrolloff = 7,              -- minimal number of screen columns either side of cursor if wrap is `false`
  shortmess = "filnxtToOFc",      -- which errors to suppress
  mousemoveevent = true,

  -- INDENT
  tabstop = 2,                    -- insert 2 spaces for a tab
  shiftwidth = 2,                 -- the number of spaces inserted for each indentation
  softtabstop = 2,                -- insert 2 spaces for a tab
  expandtab = true,               -- convert tabs to spaces
  breakindent = true,             -- tab wrapped lines
  linebreak = true,               -- companion to wrap, don't split words
  backspace = "indent,eol,start", -- allow backspace on indent, end of line or insert mode start position

  -- EDIT
  spell = true,                   -- turns on spellchecker
  spelllang = { 'en_us' },        -- sets spelling dictionary
  clipboard = "unnamedplus",      -- allows neovim to access the system clipboard
  mouse = "a",                    -- allow the mouse to be used in neovim
  mousescroll = "ver:2,hor:4",    -- change the speed of the scroll wheel
  ignorecase = true,              -- ignore case in search patterns
  smartcase = true,               -- smart case
  virtualedit = "block",          -- vitualblock mode doesn't get stuck at the end of line
  inccommand = "split",           -- shows all inline replacements in split
  autoread = true,

}

-- turns on all values in options table above
for k, v in pairs(options) do
  vim.opt[k] = v
end

-- CLIPBOARD -- (for yanky)
-- May help Arch/Debian Linux users
-- vim.g.clipboard = {
--   name = "xsel_override",
--   copy = {
--     ["+"] = "xsel --input --clipboard",
--     ["*"] = "xsel --input --primary",
--   },
--   paste = {
--     ["+"] = "xsel --output --clipboard",
--     ["*"] = "xsel --output --primary",
--   },
--   cache_enabled = 1,
-- }
