local status_ok, which_key = pcall(require, "which-key")
if not status_ok then
  return
end

local setup = {
  plugins = {
    marks = false, -- shows a list of your marks on ' and `
    registers = true, -- shows your registers on " in NORMAL or <C-r> in INSERT mode
    spelling = {
      enabled = true, -- enabling this will show WhichKey when pressing z= to select spelling suggestions
      suggestions = 10, -- how many suggestions should be shown in the list?
    },
    -- the presets plugin, adds help for a bunch of default keybindings in Neovim
    -- No actual key bindings are created
    presets = {
      operators = false, -- adds help for operators like d, y, ... and registers them for motion / text object completion
      motions = false, -- adds help for motions
      text_objects = false, -- help for text objects triggered after entering an operator
      windows = false, -- default bindings on <c-w>
      nav = false, -- misc bindings to work with windows
      z = false, -- bindings for folds, spelling and others prefixed with z
      g = false, -- bindings for prefixed with g
    },
  },
  -- add operators that will trigger motion and text object completion
  -- to enable all native operators, set the preset / operators plugin above
  -- operators = { gc = "Comments" },
  key_labels = {
    -- override the label used to display some keys. It doesn't effect WK in any other way.
    -- For example:
    -- ["<space>"] = "SPC",
    -- ["<cr>"] = "RET",
    -- ["<tab>"] = "TAB",
  },
  icons = {
    breadcrumb = "»", -- symbol used in the command line area that shows your active key combo
    separator = "➜", -- symbol used between a key and it's label
    group = "+", -- symbol prepended to a group
  },
  popup_mappings = {
    scroll_down = "<c-d>", -- binding to scroll down inside the popup
    scroll_up = "<c-u>", -- binding to scroll up inside the popup
  },
  window = {
    border = "rounded", -- none, single, double, shadow
    position = "bottom", -- bottom, top
    margin = { 1, 0, 1, 0 }, -- extra window margin [top, right, bottom, left]
    padding = { 2, 2, 2, 2 }, -- extra window padding [top, right, bottom, left]
    winblend = 0,
  },
  layout = {
    height = { min = 4, max = 25 }, -- min and max height of the columns
    width = { min = 20, max = 50 }, -- min and max width of the columns
    spacing = 3, -- spacing between columns
    align = "left", -- align columns left, center or right
  },
  ignore_missing = true, -- enable this to hide mappings for which you didn't specify a label
  hidden = { "<silent>", "<cmd>", "<Cmd>", "<CR>", "call", "lua", "^:", "^ " }, -- hide mapping boilerplate
  show_help = true, -- show help message on the command line when the popup is visible
  triggers = "auto", -- automatically setup triggers
  -- triggers = {"<leader>"} -- or specify a list manually
  triggers_blacklist = {
    -- list of mode / prefixes that should never be hooked by WhichKey
    -- this is mostly relevant for key maps that start with a native binding
    -- most people should not need to change this
    i = { "j", "k" },
    v = { "j", "k" },
  },
}

local opts = {
  mode = "n", -- NORMAL mode
  prefix = "<leader>",
  buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
  silent = true, -- use `silent` when creating keymaps
  noremap = true, -- use `noremap` when creating keymaps
  nowait = true, -- use `nowait` when creating keymaps
}

-- GENERAL MAPPINGS

local mappings = {

["d"] = { "<cmd>Bdelete!<CR>"               , "delete buffer" },
["e"] = { "<cmd>NvimTreeToggle<cr>"         , "explorer" },
["q"] = { "<cmd>wqa!<CR>"                   , "quit" },
["w"] = { "<cmd>wa!<CR>"                    , "write" },
["b"] = { "<cmd>VimtexCompile<CR>"          , "build" },
["o"] = { "<cmd>VimtexView<CR>"             , "open" },
["i"] = { "<cmd>VimtexTocOpen<CR>"          , "index" },
["r"] = { "<cmd>VimtexErrors<CR>"           , "report errors" },
["c"] = { "<cmd>VimtexCountWords!<CR>"      , "count" },
["u"] = { "<cmd>UndotreeToggle<CR>"         , "undo" },
["m"] = { "^<cmd>lua require('markdown-togglecheck').toggle()<CR>" , "markdown toggle" },

-- ["r"] = { "<cmd>source $MYVIMRC<cr>"      , "reload config" },
-- ["h"] = { "<cmd>nohlsearch<CR>", "No Highlight" },
-- ["p"] = { "<cmd>lua require('telescope').extensions.projects.projects()<cr>", "projects" },


-- PANDOC --

  -- p = {
  --   name = "PANDOC",
  --   -- w = { "<cmd>ToggleTerm direction=float <bar> pandoc %:p -o %:p:r.docx <cr>" , "word"},
  --   -- m = { "<cmd>FloatermNew! --disposable pandoc %:p -o %:p:r.md"   , "markdown"},
  --   -- h = { "<cmd>FloatermNew! --disposable pandoc %:p -o %:p:r.html" , "html"},
  --   -- l = { "<cmd>FloatermNew! --disposable pandoc %:p -o %:p:r.tex"  , "latex"},
  --   -- p = { "<cmd>FloatermNew! --disposable pandoc %:p -o %:p:r.pdf"  , "pdf"},
  --   -- x = { "<cmd>FloatermNew! echo "run: unoconv -f pdf path-to.docx""  , "word to pdf"},
  -- },


-- TEMPLATES

  t = {
    name = "TEMPLATES",
    c = { "<cmd>PackerCompile<cr>", "Compile" },
    p = { "<cmd>read ~/.config/nvim/templates/PhilPaper.tex<CR>" , "PhilPaper.tex"},
    l = { "<cmd>read ~/.config/nvim/templates/Letter.tex<CR>"    , "Letter.tex"},
    g = { "<cmd>read ~/.config/nvim/templates/Glossary.tex<CR>"  , "Glossary.tex"},
    h = { "<cmd>read ~/.config/nvim/templates/HandOut.tex<CR>"   , "HandOut.tex"},
    b = { "<cmd>read ~/.config/nvim/templates/PhilBeamer.tex<CR>", "PhilBeamer.tex"},
    s = { "<cmd>read ~/.config/nvim/templates/SubFile.tex<CR>"   , "SubFile.tex"},
    r = { "<cmd>read ~/.config/nvim/templates/Root.tex<CR>"      , "Root.tex"},
    m = { "<cmd>read ~/.config/nvim/templates/MultipleAnswer.tex<CR>"           , "MultipleAnswer.tex"},
  },


-- GIT

  g = {
    name = "GIT",
    g = { "<cmd>lua _LAZYGIT_TOGGLE()<CR>", "lazygit" },
    j = { "<cmd>lua require 'gitsigns'.next_hunk()<cr>", "next hunk" },
    k = { "<cmd>lua require 'gitsigns'.prev_hunk()<cr>", "prev hunk" },
    l = { "<cmd>lua require 'gitsigns'.blame_line()<cr>", "blame" },
    p = { "<cmd>lua require 'gitsigns'.preview_hunk()<cr>", "preview hunk" },
    r = { "<cmd>lua require 'gitsigns'.reset_hunk()<cr>", "reset hunk" },
    -- R = { "<cmd>lua require 'gitsigns'.reset_buffer()<cr>", "Reset Buffer" },
    s = { "<cmd>lua require 'gitsigns'.stage_hunk()<cr>", "stage hunk" },
    u = {
      "<cmd>lua require 'gitsigns'.undo_stage_hunk()<cr>", "unstage hunk" },
    o = { "<cmd>Telescope git_status<cr>", "open changed file" },
    b = { "<cmd>Telescope git_branches<cr>", "checkout branch" },
    c = { "<cmd>Telescope git_commits<cr>", "checkout commit" },
    d = { "<cmd>Gitsigns diffthis HEAD<cr>", "diff" },
  },
    -- \ 'c' : [':FloatermNew! --disposable gh issue create', 'create issue'],
    -- \ 'l' : [':FloatermNew! --disposable gh issue list'  , 'list issues'],
    -- \ 'r' : [':FloatermNew! --disposable gh reference'   , 'reference'],
    -- \ 'v' : [':FloatermNew! --disposable gh repo view -w', 'view repo'],
  

-- LSP

  l = {
    name = "LSP",
    a = { "<cmd>lua vim.lsp.buf.code_action()<cr>", "Code Action" },
    d = {
      "<cmd>Telescope diagnostics bufnr=0<cr>",
      "Document Diagnostics",
    },
    w = {
      "<cmd>Telescope diagnostics<cr>",
      "Workspace Diagnostics",
    },
    f = { "<cmd>lua vim.lsp.buf.format{async=true}<cr>", "Format" },
    i = { "<cmd>LspInfo<cr>", "Info" },
    I = { "<cmd>LspInstallInfo<cr>", "Installer Info" },
    j = {
      "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>",
      "Next Diagnostic",
    },
    k = {
      "<cmd>lua vim.lsp.diagnostic.goto_prev()<cr>",
      "Prev Diagnostic",
    },
    l = { "<cmd>lua vim.lsp.codelens.run()<cr>", "CodeLens Action" },
    q = { "<cmd>lua vim.lsp.diagnostic.set_loclist()<cr>", "Quickfix" },
    r = { "<cmd>lua vim.lsp.buf.rename()<cr>", "Rename" },
    s = { "<cmd>Telescope lsp_document_symbols<cr>", "Document Symbols" },
    S = {
      "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>",
      "Workspace Symbols",
    },
  },


-- FIND

  f = {
    name = "FIND",
    g = { "<cmd>Telescope git_branches<cr>", "git branches" },
    f = { "<cmd>Telescope live_grep theme=ivy<cr>", "find in project" },
    -- a = { "<cmd>lua require('telescope.builtin').find_files(require('telescope.themes').get_dropdown{previewer = false})<cr>", "all" },
    t = { "<cmd>Telescope colorscheme<cr>", "theme" },
    h = { "<cmd>Telescope help_tags<cr>", "help" },
    m = { "<cmd>Telescope man_pages<cr>", "man pages" },
    -- r = { "<cmd>Telescope oldfiles<cr>", "recent" },
    r = { "<cmd>Telescope registers<cr>", "registers" },
    k = { "<cmd>Telescope keymaps<cr>", "keymaps" },
    c = { "<cmd>Telescope commands<cr>", "commands" },
    b = {
      "<cmd>lua require('telescope.builtin').buffers(require('telescope.themes').get_dropdown{previewer = false})<cr>",
      "buffers",
    },
  },

  -- TODO: outstanding find bindings
    -- \ 'h' : [':Files ~'                          , 'files in home'],
    -- \ 'p' : [':GGrep'                            , 'in project'],

-- PROJECTS
  p = {
    name = "PROJECTS",
    s = { "<cmd>SessionManager save_current_session<CR>", "save" },
    d = { "<cmd>SessionManager delete_session<CR>", "delete" },
    l = { "<cmd>SessionManager load_session<CR>", "load" },
  },

-- ACTIONS

  a = {
    name = "ACTIONS",
    -- y = { "<cmd>CocList -A --normal yank", "yanks"},
    b = { "<cmd>terminal bibexport -o %:p:r.bib %:p:r.aux<cr>", "bib export"},
    g = { "<cmd>e ~/.config/nvim/templates/Glossary.tex<cr>", "glossary"},
    e = { "<cmd>e ~/.config/nvim/snippets/tex.snippets<cr>", "snippets"},
    k = { "<cmd>VimtexClean<CR>"            , "kill aux" },
    v = { "<plug>(vimtex-context-menu)"            , "vimtex menu" },
    p = { '<cmd>lua require("nabla").popup()<CR>', "preview symbols"},
    n = { "<cmd>lua _NODE_TOGGLE()<cr>", "Node" },
    -- u = { "<cmd>lua _NCDU_TOGGLE()<cr>", "NCDU" },
    h = { "<cmd>lua _HTOP_TOGGLE()<cr>", "Htop" },
    y = { "<cmd>lua _PYTHON_TOGGLE()<cr>", "Python" },
  },

    -- p = { "<cmd>silent w<bar>lua require('pandoc.render').init()<cr>", "pandoc" },
    -- p = { '<cmd>silent w<bar>lua require("auto-pandoc").run_pandoc()<cr>', "pandoc" },
  --   v = { "<cmd>FloatermNew! --disposable vifm", 'vifm'},
    -- t = { "<cmd>FloatermKill!", "kill terminals"},
    -- v = { "<cmd>FloatermNew! --disposable cd ~/.local/share/nvim/swap && ls -a", "view swap"},
    -- k = { "<cmd>FloatermNew! --disposable cd ~/.local/share/nvim/swap && rm *.swp", "kill swap"},


  -- SURROUND
  s = {
    name = "SURROUND",
    s = { "<Plug>(nvim-surround-normal)", "surround" },
    d = { "<Plug>(nvim-surround-delete)", "delete" },
    c = { "<Plug>(nvim-surround-change)", "change" },
  },


  -- TODO: markdown
  -- m = {
  --   name = "MARKDOWN",
  --   b = { "<cmd>Telescope git_branches<cr>", "Checkout branch" },
  -- },
    -- \ 'a' : [':call PdfAnnots()<CR>'               , 'annotate'],
    -- \ 'k' : ['<Plug>MarkdownPreviewStop'           , 'kill preview'],
    -- \ 'p' : ['<Plug>MarkdownPreview'               , 'preview'],
    -- \ 's' : [':call markdown#SwitchStatus()<CR>'   , 'select item'],


  -- TODO: terminal
  -- t = {
  --   name = "TERMINAL",
  --   u = { "<cmd>lua _NCDU_TOGGLE()<cr>", "NCDU" },
  --   f = { "<cmd>ToggleTerm direction=float<cr>", "Float" },
  --   h = { "<cmd>ToggleTerm size=10 direction=horizontal<cr>", "Horizontal" },
  --   v = { "<cmd>ToggleTerm size=80 direction=vertical<cr>", "Vertical" },
  -- },

}

which_key.setup(setup)
which_key.register(mappings, opts)
