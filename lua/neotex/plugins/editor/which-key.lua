return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  dependencies = {
    'echasnovski/mini.nvim',
  },
  opts = {
    setup = {
      show_help = false,
      show_keys = false, -- show the currently pressed key and its label as a message in the command line
      notify = false,    -- prevent which-key from automatically setting up fields for defined mappings
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
        group = "+", -- symbol prepended to a group
      },
      layout = {
        width = { min = 20, max = 50 }, -- min and max width of the columns
        height = { min = 4, max = 25 }, -- min and max height of the columns
        spacing = 3,                    -- spacing between columns
        align = "left",                 -- align columns left, center or right
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
        ft = { "NvimTree" }                                -- add your explorer's filetype here
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
      d = { "<cmd>update! | lua Snacks.bufdelete()<CR>", "delete buffer" },
      -- d = { "<cmd>update! | bdelete!<CR>", "delete buffer" },
      e = { "<cmd>NvimTreeToggle<CR>", "explorer" },
      -- j = { "<cmd>clo<CR>", "drop split" },
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
        m = { "<cmd>TermExec cmd='./Code/dev_cli.py %:p:r.py'<CR>", "model checker" },
        -- m = { "<cmd>TermExec cmd='python3 -m src.model_checker.cli %:p:r.py'<CR>", "model checker" },
        -- m = { "<cmd>TermExec cmd='cd /home/benjamin/Documents/Philosophy/Projects/ModelChecker/Code && python3 -m src.model_checker.cli %:p:r.py'<CR>", "model checker" },
        p = { "<cmd>TermExec cmd='python %:p:r.py'<CR>", "python" },
        r = { "<cmd>AutolistRecalculate<CR>", "reorder list" },
        t = { "<cmd>terminal latexindent -w %:p:r.tex<CR>", "tex format" },
        u = { "<cmd>cd %:p:h | NvimTreeRefresh | NvimTreeFindFile<CR>", "update cwd" },
        v = { "<plug>(vimtex-context-menu)", "vimtex menu" },
        w = { "<cmd>VimtexCountWords!<CR>", "word count" },
        -- w = { "<cmd>TermExec cmd='pandoc %:p -o %:p:r.docx'<CR>" , "word"},
        -- s = { "<cmd>lua function() require('cmp_vimtex.search').search_menu() end<CR>"           , "search citations" },
        s = { "<cmd>NvimTreeOpen ~/.config/nvim/snippets/<CR>", "snippets edit" },
        S = { "<cmd>TermExec cmd='ssh brastmck@eofe10.mit.edu'<CR>", "ssh" },
      },
      f = {
        name = "FIND",
        a = { "<cmd>lua require('telescope.builtin').find_files({ no_ignore = true, hidden = true, search_dirs = { '~/' } })<CR>", "all files" },
        b = {
          "<cmd>lua require('telescope.builtin').buffers(require('telescope.themes').get_dropdown{previewer = false})<CR>",
          "buffers",
        },
        c = { "<cmd>Telescope bibtex format_string=\\citet{%s}<CR>", "citations" },
        f = { "<cmd>Telescope live_grep theme=ivy<CR>", "project" },
        l = { "<cmd>Telescope resume<CR>", "last search" },
        q = { "<cmd>Telescope quickfix<CR>", "quickfix" },
        g = { "<cmd>Telescope git_commits<CR>", "git history" },
        h = { "<cmd>Telescope help_tags<CR>", "help" },
        k = { "<cmd>Telescope keymaps<CR>", "keymaps" },
        r = { "<cmd>Telescope registers<CR>", "registers" },
        t = { "<cmd>TodoTelescope<CR>", "todos" },
        s = { "<cmd>Telescope grep_string<CR>", "string" },
        w = { "<cmd>lua SearchWordUnderCursor()<CR>", "word" },
        y = { "<cmd>Telescope yank_history<CR>", "yanks" },
        -- m = { "<cmd>Telescope man_pages<CR>", "man pages" },
        -- c = { "<cmd>Telescope commands<CR>", "commands" },
        -- r = { "<cmd>Telescope oldfiles<CR>", "recent" },
      },
      g = {
        name = "GIT",
        -- { '<leader>g', group = ' Git' },
        b = { "<cmd>Telescope git_branches<CR>", "checkout branch" },
        c = { "<cmd>Telescope git_commits<CR>", "git commits" },
        d = { "<cmd>Gitsigns diffthis HEAD<CR>", "diff" },
        g = { "<cmd>lua vim.schedule(function() Snacks.lazygit() end)<cr>", "lazygit" },
        k = { "<cmd>Gitsigns prev_hunk<CR>", "prev hunk" },
        j = { "<cmd>Gitsigns next_hunk<CR>", "next hunk" },
        l = { "<cmd>Gitsigns blame_line<CR>", "line blame" }, -- TODO: use snacks?
        p = { "<cmd>Gitsigns preview_hunk<CR>", "preview hunk" },
        s = { "<cmd>Telescope git_status<CR>", "git status" },
        t = { "<cmd>Gitsigns toggle_current_line_blame<CR>", "toggle blame" },
        -- t = { "<cmd>Gitsigns toggle_word_diff<CR>", "toggle word diff" },
      },
      h = {
        name = "AI HELP",
        a = { "<cmd>AvanteAsk<CR>", "ask" },
        b = { "<cmd>AvanteBuild<CR>", "build dependencies" },
        c = { "<cmd>AvanteChat<CR>", "chat" },
        d = { "<cmd>AvanteProvider<CR>", "set model & provider" },
        e = { "<cmd>AvantePromptManager<CR>", "edit prompts" },
        i = { "<cmd>AvanteStop<CR>", "interupt avante" },
        k = { "<cmd>AvanteClear<CR>", "clear" },
        m = { "<cmd>AvanteModel<CR>", "select model" },
        M = { "<cmd>AvanteShowRepoMap<CR>", "map repo" },
        p = { "<cmd>AvantePrompt<CR>", "select prompt" },
        s = { "<cmd>AvanteEdit<CR>", "selected edit" },
        -- s = { "<cmd>AvanteSwitchProvider<CR>", "quick provider switch" },
        r = { "<cmd>AvanteRefresh<CR>", "refresh assistant" },
        t = { "<cmd>AvanteToggle<CR>", "toggle assistant" },
      },
      --   HARPOON
      --   a = { "<cmd>lua require('harpoon.mark').add_file()<cr>", "mark" },
      --   n = { "<cmd>lua require('harpoon.ui').nav_next()<cr>", "next" },
      --   p = { "<cmd>lua require('harpoon.ui').nav_prev()<cr>", "previous" },
      -- LIST MAPPINGS
      j = {
        name = "JUPYTER",
        -- NotebookNavigator commands
        e = { "<cmd>lua require('notebook-navigator').run_cell()<CR>", "execute cell" },
        j = { "<cmd>lua require('notebook-navigator').move_cell('d')<CR>", "next cell" },
        k = { "<cmd>lua require('notebook-navigator').move_cell('u')<CR>", "previous cell" },
        n = { "<cmd>lua require('notebook-navigator').run_and_move()<CR>", "execute and next" },
        o = { "<cmd>lua require('neotex.utils.diagnostics').add_jupyter_cell_with_closing()<CR>", "insert cell below" },
        O = { "<cmd>lua require('notebook-navigator').add_cell_above()<CR>", "insert cell above" },
        s = { "<cmd>lua require('notebook-navigator').split_cell()<CR>", "split cell" },
        c = { "<cmd>lua require('notebook-navigator').comment_cell()<CR>", "comment cell" },

        -- Additional NotebookNavigator features
        a = { "<cmd>lua require('notebook-navigator').run_all_cells()<CR>", "run all cells" },
        b = { "<cmd>lua require('notebook-navigator').run_cells_below()<CR>", "run cells below" },
        u = { "<cmd>lua require('notebook-navigator').merge_cell('u')<CR>", "merge with cell above" },
        d = { "<cmd>lua require('notebook-navigator').merge_cell('d')<CR>", "merge with cell below" },

        -- Iron.nvim REPL integration
        i = { "<cmd>lua require('iron.core').repl_for('python')<CR>", "start IPython REPL" },
        t = { "<cmd>lua require('iron.core').run_motion('send_motion')<CR>", "send motion to REPL" },
        l = { "<cmd>lua require('iron.core').send_line()<CR>", "send line to REPL" },
        f = { "<cmd>lua require('iron.core').send(nil, vim.fn.readfile(vim.fn.expand('%')))<CR>", "send file to REPL" },
        q = { "<cmd>lua require('iron.core').close_repl()<CR>", "exit REPL" },
        r = { "<cmd>lua require('iron.core').send(nil, string.char(12))<CR>", "clear REPL" },
        v = { "<cmd>lua require('iron.core').visual_send()<CR>", "send visual selection to REPL" },
      },
      L = {
        name = "LIST",
        c = { "<cmd>lua HandleCheckbox()<CR>", "checkbox" },
        n = { "<cmd>AutolistCycleNext<CR>", "next" },
        p = { "<cmd>AutolistCyclePrev<CR>", "previous" },
        r = { "<cmd>AutolistRecalculate<CR>", "reorder" },
      },
      l = {
        name = "LSP & LINT",
        -- LSP operations
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
        y = { "<cmd>lua CopyDiagnosticsToClipboard()<CR>", "copy diagnostics to clipboard" },
        R = { "<cmd>lua vim.lsp.buf.rename()<CR>", "rename" },
        -- T = { "<cmd>Telescope lsp_type_definitions<CR>", "type definition" },
        
        -- Linting operations
        L = { function() require("lint").try_lint() end, "lint file" },
        g = { "<cmd>LintToggle<CR>", "toggle global linting" },
        B = { "<cmd>LintToggle buffer<CR>", "toggle buffer linting" },
      },
      -- MARKDOWN MAPPINGS
      m = {
        name = "MARKDOWN",
        -- LECTIC COMMANDS
        l = { "<cmd>Lectic<CR>", "run lectic on file" },
        n = { "<cmd>lua CreateNewLecticFile()<CR>", "new lectic file" },
        s = { "<cmd>lua SubmitLecticSelection()<CR>", "submit selection with message" },

        -- MARKDOWN/PREVIEW & FORMATTING
        p = { function() require("conform").format({ async = true, lsp_fallback = true }) end, "format buffer" },
        u = { "<cmd>lua OpenUrlUnderCursor()<CR>", "open URL under cursor" },

        -- FOLDING
        a = { "<cmd>lua ToggleAllFolds()<CR>", "toggle all folds" },
        f = { "za", "toggle fold under cursor" },
        t = { "<cmd>lua ToggleFoldingMethod()<CR>", "toggle folding method" },
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
        f = { "<cmd>TermExec cmd='sudo nixos-rebuild switch --flake ~/.dotfiles/'<CR><C-w>l", "rebuild flake" },
        g = { "<cmd>TermExec cmd='nix-collect-garbage --delete-older-than 15d'<CR><C-w>j", "garbage" },
        -- g = { "<cmd>TermExec cmd='nix-collect-garbage -d'<CR><C-w>j", "garbage" },
        p = { "<cmd>TermExec cmd='brave https://search.nixos.org/packages' open=0<CR>", "packages" },
        m = { "<cmd>TermExec cmd='brave https://mynixos.com' open=0<CR>", "my-nixos" },
        h = { "<cmd>TermExec cmd='home-manager switch --flake ~/.dotfiles/'<CR><C-w>l", "home-manager" },
        r = { "<cmd>TermExec cmd='./~/.dotfiles/update.sh'<CR><C-w>l", "rebuild nix" },
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
        c = { "<cmd>TermExec cmd='rm -rf ~/.cache/nvim' open=0<CR>", "clear plugin cache" },
        e = { "<cmd>lua require('neotex.utils.diagnostics').show_all_errors()<CR>", "show linter errors" },
        -- h = { "<cmd>Hardtime toggle<cr>", "hardtime" }, -- Hardtime plugin has been deprecated
        k = { "<cmd>TermExec cmd='rm -rf ~/.local/share/nvim/lazy && rm -f ~/.config/nvim/lazy-lock.json' open=0<CR>", "wipe plugins and lock file" },
        -- m = { "<cmd>MCPHub<cr>", "mcp-hub" }, -- MCP-Hub plugin has been deprecated
        n = { "function() vim.diagnostic.goto_next{popup_opts = {show_header = false}} end", "next" },
        p = { "function() vim.diagnostic.goto_prev{popup_opts = {show_header = false}} end", "prev" },
        r = { "<cmd>ReloadConfig<cr>", "reload configs" },
        m = { "<cmd>lua Snacks.notifier.show_history()<cr>", "show messages" },
        -- d = { "function() vim.diagnostic.open_float(0, { scope = 'line', header = false, focus = false }) end", "diagnostics" },
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
      x = {
        name = "TEXT OPERATIONS",
        a = { "ga", "align" },
        A = { "gA", "align with preview" },
        s = { "gS", "split/join toggle" },
        d = { function() require('mini.diff').toggle_overlay() end, "toggle diff overlay" },
        w = { function() require('mini.diff').toggle_word_diff() end, "toggle word diff" },
      },
      y = {
        name = "YANK",
        h = { "<cmd>Telescope yank_history<CR>", "history" },
        c = { "<cmd>YankyClearHistory<CR>", "clear history" },
      },
    },
  },
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts.setup)
    wk.register(opts.defaults)
  end,
}