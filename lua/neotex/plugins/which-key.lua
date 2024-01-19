return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,
  event = "VeryLazy",
  opts = {
    setup = {
      show_help = true,
      plugins = {
        presets = {
          operators = false, -- adds help for operators like d, y, ... and registers them for motion / text object completion
          motions = false, -- adds help for motions
          text_objects = false, -- help for text objects triggered after entering an operator
          windows = false, -- default bindings on <c-w>
          nav = false, -- misc bindings to work with windows
          z = false, -- bindings for folds, spelling and others prefixed with z
          g = false, -- bindings for prefixed with g
        marks = false, -- shows a list of your marks on ' and `
        registers = false, -- shows your registers on " in NORMAL or <C-r> in INSERT mode
        spelling = {
          enabled = false, -- enabling this will show WhichKey when pressing z= to select spelling suggestions
          suggestions = 10, -- how many suggestions should be shown in the list?
        },
        -- the presets plugin, adds help for a bunch of default keybindings in Neovim
        -- No actual key bindings are created
        },
      },
      key_labels = {
        -- override the label used to display some keys. It doesn't effect WK in any other way.
        -- For example:
        -- ["<space>"] = "SPC",
        -- ["<CR>"] = "RET",
        -- ["<tab>"] = "TAB",
      },
      -- triggers = "auto", -- automatically setup triggers
      triggers = { "<leader>" }, -- or specify a list manually
      -- add operators that will trigger motion and text object completion
      -- to enable native operators, set the preset / operators plugin above
      -- operators = { gc = "Comments" },
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
        zindex = 1000, -- positive value to position WhichKey above other floating windows.
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
      triggers_nowait = {
        -- -- marks
        -- "`",
        -- "'",
        -- "g`",
        -- "g'",
        -- -- registers
        -- '"',
        -- "<c-r>",
        -- -- spelling
        -- "z=",
      },
      triggers_blacklist = {
        -- list of mode / prefixes that should never be hooked by WhichKey
        -- this is mostly relevant for key maps that start with a native binding
        -- most people should not need to change this
        i = { "j", "k" },
        v = { "j", "k" },
      },
      -- disable the WhichKey popup for certain buf types and file types.
      -- Disabled by default for Telescope
      disable = {
        buftypes = {},
        filetypes = {},
      },
    },
    defaults = {
      buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
      silent = true, -- use `silent` when creating keymaps
      noremap = true, -- use `noremap` when creating keymaps
      nowait = true, -- use `nowait` when creating keymaps
      prefix = "<leader>",
      mode = { "n", "v" },
      b = { "<cmd>VimtexCompile<CR>"            , "build" },
      d = { "<cmd>update! | bdelete!<CR>"                 , "delete buffer" },
      e = { "<cmd>NvimTreeToggle<CR>"                  , "explorer" },
      i = { "<cmd>VimtexTocOpen<CR>"            , "index" },
      q = { "<cmd>wa! | qa!<CR>"                     , "quit" },
      u = { "<cmd>Telescope undo<CR>"           , "undo" },
      v = { "<cmd>VimtexView<CR>"               , "view" },
      w = { "<cmd>wa!<CR>"                  , "write" },
      a = {
        name = "ACTIONS",
        a = { "<cmd>lua PdfAnnots()<CR>"                              , "annotate"},
        b = { "<cmd>terminal bibexport -o %:p:r.bib %:p:r.aux<CR>"    , "bib export"},
        c = { "<cmd>VimtexCountWords!<CR>"                            , "count" },
        g = { "<cmd>e ~/.config/nvim/templates/Glossary.tex<CR>"      , "edit glossary"},
        h = { "<cmd>lua _HTOP_TOGGLE()<CR>", "htop" },
        i = { "<cmd>IlluminateToggle<CR>"            , "illuminate" },
        k = { "<cmd>VimtexClean<CR>"            , "kill aux" },
        l = { "<cmd>lua vim.g.cmptoggle = not vim.g.cmptoggle<CR>", "LSP"},
        p = { '<cmd>lua require("nabla").popup()<CR>', "preview symbols"},
        r = { "<cmd>VimtexErrors<CR>"           , "report errors" },
        s = { "<cmd>e ~/.config/nvim/snippets/tex.snippets<CR>", "edit snippets"},
        u = { "<cmd>cd %:p:h<CR>"           , "update cwd" },
        -- w = { "<cmd>TermExec cmd='pandoc %:p -o %:p:r.docx'<CR>" , "word"},
        v = { "<plug>(vimtex-context-menu)"            , "vimtex menu" },
      },
      c = { 
        name = "CITATION",
          t = { "<cmd>Telescope bibtex format_string=\\citet{%s}<CR>"       , "\\citet" },
          p = { "<cmd>Telescope bibtex format_string=\\citep{%s}<CR>"       , "\\citep" },
          s = { "<cmd>Telescope bibtex format_string=\\citepos{%s}<CR>"       , "\\citepos" },
      },
      f = {
        name = "FIND",
          b = {
            "<cmd>lua require('telescope.builtin').buffers(require('telescope.themes').get_dropdown{previewer = false})<CR>",
            "buffers",
          },
          -- c = { "<cmd>Telescope bibtex format_string=\\citet{%s}<CR>"       , "citations" },
          f = { "<cmd>Telescope live_grep theme=ivy<CR>", "project" },
          g = { "<cmd>Telescope git_branches<CR>", "branches" },
          h = { "<cmd>Telescope help_tags<CR>", "help" },
          k = { "<cmd>Telescope keymaps<CR>", "keymaps" },
          -- m = { "<cmd>Telescope man_pages<CR>", "man pages" },
          r = { "<cmd>Telescope registers<CR>", "registers" },
          t = { "<cmd>Telescope colorscheme<CR>", "theme" },
          y = { "<cmd>YankyRingHistory<CR>"       , "yanks" },
          -- c = { "<cmd>Telescope commands<CR>", "commands" },
          -- r = { "<cmd>Telescope oldfiles<CR>", "recent" },
      },
      g = {
        name = "GIT",
        g = { "<cmd>LazyGit<CR>", "lazygit" },
        j = { "<cmd>lua require 'gitsigns'.next_hunk()<CR>", "next hunk" },
        k = { "<cmd>lua require 'gitsigns'.prev_hunk()<CR>", "prev hunk" },
        l = { "<cmd>lua require 'gitsigns'.blame_line()<CR>", "blame" },
        p = { "<cmd>lua require 'gitsigns'.preview_hunk()<CR>", "preview hunk" },
        r = { "<cmd>lua require 'gitsigns'.reset_hunk()<CR>", "reset hunk" },
        s = { "<cmd>lua require 'gitsigns'.stage_hunk()<CR>", "stage hunk" },
        u = { "<cmd>lua require 'gitsigns'.undo_stage_hunk()<CR>", "unstage hunk" },
        o = { "<cmd>Telescope git_status<CR>", "open changed file" },
        b = { "<cmd>Telescope git_branches<CR>", "checkout branch" },
        c = { "<cmd>Telescope git_commits<CR>", "checkout commit" },
        d = { "<cmd>Gitsigns diffthis HEAD<CR>", "diff" },
      },
      h = {
        name = "HARPOON",
        m = { "<cmd>lua require('harpoon.mark').add_file()<cr>", "mark" },
        n = { "<cmd>lua require('harpoon.ui').nav_next()<cr>", "next" },
        p = { "<cmd>lua require('harpoon.ui').nav_prev()<cr>", "previous" },
      },
      l = {
        name = "LIST",
        c = { "<cmd>lua handle_checkbox()<CR>", "checkbox" },
        n = { "<cmd>AutolistCycleNext<CR>", "next" },
        p = { "<cmd>AutolistCyclePrev<CR>", "previous" },
        r = { "<cmd>AutolistRecalculate<CR>", "reorder" },
        -- x = { "<cmd>AutolistToggleCheckbox<cr><CR>", "checkmark" },
      },
      m = {
        name = "MANAGE SESSIONS",
        s = { "<cmd>SessionManager save_current_session<CR>", "save" },
        d = { "<cmd>SessionManager delete_session<CR>", "delete" },
        l = { "<cmd>SessionManager load_session<CR>", "load" },
      },
      p = {
        name = "PANDOC",
        w = { "<cmd>TermExec cmd='pandoc %:p -o %:p:r.docx'<CR>" , "word"},
        m = { "<cmd>TermExec cmd='pandoc %:p -o %:p:r.md'<CR>"   , "markdown"},
        h = { "<cmd>TermExec cmd='pandoc %:p -o %:p:r.html'<CR>" , "html"},
        l = { "<cmd>TermExec cmd='pandoc %:p -o %:p:r.tex'<CR>"  , "latex"},
        p = { "<cmd>TermExec cmd='pandoc %:p -o %:p:r.pdf'<CR>"  , "pdf"},
        -- x = { "<cmd>echo "run: unoconv -f pdf path-to.docx""  , "word to pdf"},
      },
      s = {
        name = "SURROUND",
        s = { "<Plug>(nvim-surround-normal)", "surround" },
        d = { "<Plug>(nvim-surround-delete)", "delete" },
        c = { "<Plug>(nvim-surround-change)", "change" },
      },
      t = {
        name = "TEMPLATES",
        c = { "<cmd>PackerCompile<CR>", "Compile" },
        p = { 
          "<cmd>read ~/.config/nvim/templates/PhilPaper.tex<CR>", 
          "PhilPaper.tex",
        },
        l = { 
          "<cmd>read ~/.config/nvim/templates/Letter.tex<CR>",
          "Letter.tex",
        },
        g = { 
          "<cmd>read ~/.config/nvim/templates/Glossary.tex<CR>", 
          "Glossary.tex",
        },
        h = { 
          "<cmd>read ~/.config/nvim/templates/HandOut.tex<CR>", 
          "HandOut.tex",
        },
        b = { 
          "<cmd>read ~/.config/nvim/templates/PhilBeamer.tex<CR>", 
          "PhilBeamer.tex",
        },
        s = { 
          "<cmd>read ~/.config/nvim/templates/SubFile.tex<CR>", 
          "SubFile.tex",
        },
        r = { 
          "<cmd>read ~/.config/nvim/templates/Root.tex<CR>", 
          "Root.tex",
        },
        m = { 
          "<cmd>read ~/.config/nvim/templates/MultipleAnswer.tex<CR>", 
          "MultipleAnswer.tex",
        },
      },
    },
  },
  config = function(_, opts)
    local wk = require "which-key"
    wk.setup(opts.setup)
    wk.register(opts.defaults)
  end,
}

-- Note: old way of getting prefixes to work
-- return {
--   "folke/which-key.nvim",
--   event = "VeryLazy",
--   config = function(_, opts)
--     require("which-key").setup(opts)
--     local present, wk = pcall(require, "which-key")
--     if not present then
--       return
--     end
--     wk.register({
--       -- add groups
--       ["<leader>"] = {
--         a = { name = "+ACTION" },
--         c = { name = "+CITE" },
--         f = { name = "+FIND" },
--         l = { name = "+LIST" },
--         g = { name = "+GIT" },
--         m = { name = "+MANAGE SESSIONS" },
--         p = { name = "+PANDOC" },
--         s = { name = "+SURROUND" },
--         t = { name = "+TEMPLATES" },
--       },
--     })
--   end,
-- }
