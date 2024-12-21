return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  dependencies = {
    'echasnovski/mini.nvim',
  },
  opts = {
    setup = {
      show_help = false,
      show_keys = false,        -- show the currently pressed key and its label as a message in the command line
      notify = false,           -- prevent which-key from automatically setting up fields for defined mappings
      triggers = {
        { "<leader>", mode = { "n", "v" } },
      },
      plugins = {
        presets = {
          marks = false,        -- shows a list of your marks on ' and `
          registers = false,    -- shows your registers on " in NORMAL or <C-r> in INSERT mode
          spelling = {
            enabled = false,    -- enabling this will show WhichKey when pressing z= to select spelling suggestions
            suggestions = 10,   -- how many suggestions should be shown in the list?
          },
          operators = false,    -- adds help for operators like d, y, ... and registers them for motion / text object completion
          motions = false,      -- adds help for motions
          text_objects = false, -- help for text objects triggered after entering an operator
          windows = false,      -- default bindings on <c-w>
          nav = false,          -- misc bindings to work with windows
          z = false,            -- bindings for folds, spelling and others prefixed with z
          g = false,            -- bindings for prefixed with g
        },
      },
      win = {
        no_overlap = true,
        -- width = 1,
        -- height = { min = 4, max = 25 },
        -- col = 0,
        -- row = math.huge,
        border = "rounded", -- can be 'none', 'single', 'double', 'shadow', etc.
        padding = { 1, 2 }, -- extra window padding [top/bottom, right/left]
        title = false,
        title_pos = "center",
        zindex = 1000,
        -- Additional vim.wo and vim.bo options
        bo = {},
        wo = {
          winblend = 10, -- value between 0-100 0 for fully opaque and 100 for fully transparent
        },
      },
      -- add operators that will trigger motion and text object completion
      -- to enable native operators, set the preset / operators plugin above
      -- operators = { gc = "Comments" },
      icons = {
        breadcrumb = "»", -- symbol used in the command line area that shows your active key combo
        separator = "➜", -- symbol used between a key and it's label
        group = "+",      -- symbol prepended to a group
      },
      layout = {
        width = { min = 20, max = 50 },                                             -- min and max width of the columns
        height = { min = 4, max = 25 },                                             -- min and max height of the columns
        spacing = 3,                                                                -- spacing between columns
        align = "left",                                                             -- align columns left, center or right
      },
      keys = {
        scroll_down = "<c-d>", -- binding to scroll down inside the popup
        scroll_up = "<c-u>",   -- binding to scroll up inside the popup
      },
      sort = { "local", "order", "group", "alphanum", "mod" },
      -- disable the WhichKey popup for certain buf types and file types.
      -- Disabled by default for Telescope
      disable = {
        bt = { "help", "quickfix", "terminal", "prompt" }, -- for example
        ft = { "NvimTree" } -- add your explorer's filetype here
      }
    },
    defaults = {
      buffer = nil,   -- Global mappings. Specify a buffer number for buffer local mappings
      silent = true,  -- use `silent` when creating keymaps
      noremap = true, -- use `noremap` when creating keymaps
      nowait = true,  -- use `nowait` when creating keymaps
      prefix = "<leader>",
      mode = { "n", "v" },
      b = { "<cmd>VimtexCompile<CR>", "build" },
      c = { "<cmd>vert sb<CR>", "create split" },
      -- k = { "<cmd>clo<CR>", "kill split" },
      d = { "<cmd>update! | bdelete!<CR>", "delete buffer" },
      -- d = { ":lua CloseBuffer()<CR>", "delete buffer" },
      e = { "<cmd>NvimTreeToggle<CR>", "explorer" },
      j = { "<cmd>clo<CR>", "drop split" },
      -- h = { "<cmd>Alpha<CR>", "home" },
      i = { "<cmd>VimtexTocOpen<CR>", "index" },
      k = { "<cmd>on<CR>", "max split" },
      q = { "<cmd>wa! | qa!<CR>", "quit" },
      u = { "<cmd>Telescope undo<CR>", "undo" },
      v = { "<cmd>VimtexView<CR>", "view" },
      w = { "<cmd>wa!<CR>", "write" },
      -- z = { "<cmd>ZenMode<CR>", "zen" },
      a = {
        name = "ACTIONS",
        a = { "<cmd>lua PdfAnnots()<CR>", "annotate" },
        b = { "<cmd>terminal bibexport -o %:p:r.bib %:p:r.aux<CR>", "bib export" },
        c = { "<cmd>:VimtexClearCache All<CR>", "clear vimtex" },
        e = { "<cmd>VimtexErrors<CR>", "error report" },
        f = { "<cmd>lua vim.lsp.buf.format()<CR>", "format" },
        g = { "<cmd>e ~/.config/nvim/templates/Glossary.tex<CR>", "edit glossary" },
        -- h = { "<cmd>lua _HTOP_TOGGLE()<CR>", "htop" },
        h = { "<cmd>LocalHighlightToggle<CR>", "highlight" },
        k = { "<cmd>VimtexClean<CR>", "kill aux" },
        l = { "<cmd>LeanInfoviewToggle<CR>", "lean info" },
        -- l = { "<cmd>lua vim.g.cmptoggle = not vim.g.cmptoggle<CR>", "LSP" },
        -- m = { "<cmd>MarkdownPreview<CR>", "markdown preview" },

        m = { "<cmd>TermExec cmd='python3 /home/benjamin/Documents/Philosophy/Projects/ModelChecker/Code/src/model_checker %:p:r.py'<CR>", "model checker" },
        p = { "<cmd>TermExec cmd='python %:p:r.py'<CR>", "python" },
        r = { "<cmd>AutolistRecalculate<CR>", "reorder list" },
        t = { "<cmd>terminal latexindent -w %:p:r.tex<CR>", "tex format" },
        u = { "<cmd>cd %:p:h<CR>", "update cwd" },
        v = { "<plug>(vimtex-context-menu)", "vimtex menu" },
        w = { "<cmd>VimtexCountWords!<CR>", "word count" },
        -- w = { "<cmd>TermExec cmd='pandoc %:p -o %:p:r.docx'<CR>" , "word"},
        -- s = { "<cmd>lua function() require('cmp_vimtex.search').search_menu() end<CR>"           , "search citations" },
        s = { "<cmd>e ~/.config/nvim/snippets/tex.snippets<CR>", "snippets edit" },
        S = { "<cmd>TermExec cmd='ssh brastmck@eofe10.mit.edu'<CR>", "ssh" },
      },
      f = {
        name = "FIND",
        b = {
          "<cmd>lua require('telescope.builtin').buffers(require('telescope.themes').get_dropdown{previewer = false})<CR>",
          "buffers",
        },
        c = { "<cmd>Telescope bibtex format_string=\\citet{%s}<CR>", "citations" },
        f = { "<cmd>Telescope live_grep theme=ivy<CR>", "project" },
        g = { "<cmd>Telescope git_commits<CR>", "git history" },
        -- g = { "<cmd>Telescope git_branches<CR>", "branches" },
        h = { "<cmd>Telescope help_tags<CR>", "help" },
        k = { "<cmd>Telescope keymaps<CR>", "keymaps" },
        -- m = { "<cmd>Telescope man_pages<CR>", "man pages" },
        r = { "<cmd>Telescope registers<CR>", "registers" },
        t = { "<cmd>Telescope colorscheme<CR>", "theme" },
        w = { "<cmd>lua SearchWordUnderCursor()<CR>", "word" },
        y = { "<cmd>YankyRingHistory<CR>", "yanks" },
        -- c = { "<cmd>Telescope commands<CR>", "commands" },
        -- r = { "<cmd>Telescope oldfiles<CR>", "recent" },
      },
      g = {
        name = "GIT",
        b = { "<cmd>Telescope git_branches<CR>", "checkout branch" },
        -- c = { "<cmd>Telescope git_commits<CR>", "commits" },
        d = { "<cmd>Gitsigns diffthis HEAD<CR>", "diff" },
        g = { "<cmd>LazyGit<CR>", "lazygit" },
        -- h = { "<cmd>Gitsigns hunk_history<CR>", "hunk history" },
        k = { "<cmd>Gitsigns prev_hunk<CR>", "prev hunk" },
        j = { "<cmd>Gitsigns next_hunk<CR>", "next hunk" },
        l = { "<cmd>Gitsigns blame_line<CR>", "line blame" },
        p = { "<cmd>Gitsigns preview_hunk<CR>", "preview hunk" },
        t = { "<cmd>Gitsigns toggle_current_line_blame<CR>", "toggle blame" },
        -- o = { "<cmd>Telescope git_status<CR>", "open changed file" },
        -- r = { "<cmd>lua require 'gitsigns'.reset_hunk()<CR>", "reset hunk" },
        -- s = { "<cmd>lua require 'gitsigns'.stage_hunk()<CR>", "stage hunk" },
        -- u = { "<cmd>lua require 'gitsigns'.undo_stage_hunk()<CR>", "unstage hunk" },
      },
      -- h = {
      --   name = "HARPOON",
      --   m = { "<cmd>lua require('harpoon.mark').add_file()<cr>", "mark" },
      --   n = { "<cmd>lua require('harpoon.ui').nav_next()<cr>", "next" },
      --   p = { "<cmd>lua require('harpoon.ui').nav_prev()<cr>", "previous" },
      -- (?) },
      -- LIST MAPPINGS
      L = {
        name = "LIST",
        c = { "<cmd>lua HandleCheckbox()<CR>", "checkbox" },
        -- c = { "<cmd>lua require('autolist').invert()<CR>", "checkbox" },
        -- x = { "<cmd>lua handle_checkbox()<CR>", "checkbox" },
        -- c = { "<cmd>AutolistToggleCheckbox<CR>", "checkmark" },
        n = { "<cmd>AutolistCycleNext<CR>", "next" },
        p = { "<cmd>AutolistCyclePrev<CR>", "previous" },
        r = { "<cmd>AutolistRecalculate<CR>", "reorder" },
      },
      l = {
        name = "LSP",
        b = { "<cmd>Telescope diagnostics bufnr=0<CR>", "buffer diagnostics" },
        c = { "<cmd>lua vim.lsp.buf.code_action()<CR>", "code action" },
        d = { "<cmd>Telescope lsp_definitions<CR>", "definition" },
        D = { "<cmd>lua vim.lsp.buf.declaration()<CR>", "declaration" },
        h = { "<cmd>lua vim.lsp.buf.hover()<CR>", "help" },
        i = { "<cmd>Telescope lsp_implementations<CR>", "implementations" },
        k = { "<cmd>LspStop<CR>", "kill lsp" },
        l = { "<cmd>lua vim.diagnostic.open_float()<CR>", "line diagnostics" },
        n = { "<cmd>lua vim.diagnostic.goto_next()<CR>", "next diagnostic" },
        p = { "<cmd>lua vim.diagnostic.goto_prev()<CR>", "previous diagnostic" },
        r = { "<cmd>Telescope lsp_references<CR>", "references" },
        s = { "<cmd>LspRestart<CR>", "restart lsp" },
        t = { "<cmd>LspStart<CR>", "start lsp" },
        R = { "<cmd>lua vim.lsp.buf.rename()<CR>", "rename" },
        -- T = { "<cmd>Telescope lsp_type_definitions<CR>", "type definition" },
      },
      -- MARKDOWN MAPPINGS
      m = {
        name = "MARKDOWN",
        v = { "<cmd>Slides<CR>", "view slides" },
      },
      S = {
        name = "SESSIONS",
        s = { "<cmd>SessionManager save_current_session<CR>", "save" },
        d = { "<cmd>SessionManager delete_session<CR>", "delete" },
        l = { "<cmd>SessionManager load_session<CR>", "load" },
      },
      n = {
        name = "NIXOS",
        d = { "<cmd>TermExec cmd='nix develop'<CR><C-w>j", "develop" },
        -- f = { "<cmd>TermExec cmd='sudo nixos-rebuild switch --flake ~/.config/nixos/'<CR><C-w>j", "flake" },
        g = { "<cmd>TermExec cmd='nix-collect-garbage --delete-older-than 15d'<CR><C-w>j", "garbage" },
        -- g = { "<cmd>TermExec cmd='nix-collect-garbage -d'<CR><C-w>j", "garbage" },
        p = { "<cmd>TermExec cmd='brave https://search.nixos.org/packages' open=0<CR>", "packages" },
        m = { "<cmd>TermExec cmd='brave https://mynixos.com' open=0<CR>", "my-nixos" },
        r = { "<cmd>TermExec cmd='sudo nixos-rebuild switch --flake ~/.dotfiles/'<CR><C-w>l", "rebuild flake" },
        h = { "<cmd>TermExec cmd='home-manager switch --flake ~/.dotfiles/'<CR><C-w>l", "home-manager" },
        -- r = { "<cmd>TermExec cmd='home-manager switch'<CR><C-w>j", "home rebuild" },
        -- r = { "<cmd>TermExec cmd='sudo nixos-rebuild switch --flake ~/.config/home-manager/#nandi'<CR><C-w>j", "home rebuild" },
        -- r = { "<cmd>TermExec cmd='home-manager switch --flake ~/.config/home-manager/'<CR><C-w>j", "rebuild" },
        u = { "<cmd>TermExec cmd='nix flake update'<CR><C-w>j", "update" },
      },
      p = {
        name = "PANDOC",
        w = { "<cmd>TermExec cmd='pandoc %:p -o %:p:r.docx'<CR>", "word" },
        m = { "<cmd>TermExec cmd='pandoc %:p -o %:p:r.md'<CR>", "markdown" },
        h = { "<cmd>TermExec cmd='pandoc %:p -o %:p:r.html'<CR>", "html" },
        l = { "<cmd>TermExec cmd='pandoc %:p -o %:p:r.tex'<CR>", "latex" },
        p = { "<cmd>TermExec cmd='pandoc %:p -o %:p:r.pdf' open=0<CR>", "pdf" },
        v = { "<cmd>TermExec cmd='zathura %:p:r.pdf &' open=0<CR>", "view" },
        -- x = { "<cmd>echo "run: unoconv -f pdf path-to.docx""  , "word to pdf"},
      },
      r = {
        name = "RUN",
        d = { "function() vim.diagnostic.open_float(0, { scope = 'line', header = false, focus = false }) end", "diagnostics" },
        l = { "vim.diagnostics.setloclist", "locate errors" },
        n = { "function() vim.diagnostic.goto_next{popup_opts = {show_header = false}} end", "next" },
        p = { "function() vim.diagnostic.goto_prev{popup_opts = {show_header = false}} end", "prev" },
    -- map('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>')
    -- map('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>')
    -- map('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>')
    -- map('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>')
    -- map('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>')
    -- map('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>')
    -- map('n', '<space>f', '<cmd>lua vim.lsp.buf.formatting()<CR>')prev{popup_opts = {show_header = false}} end", "previous" },
      },
      s = {
        name = "SURROUND",
        s = { "<Plug>(nvim-surround-normal)", "surround" },
        d = { "<Plug>(nvim-surround-delete)", "delete" },
        c = { "<Plug>(nvim-surround-change)", "change" },
      },
      t = {
        name = "TEMPLATES",
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
    local wk = require("which-key")
    wk.setup(opts.setup)
    wk.register(opts.defaults)
  end,
}
