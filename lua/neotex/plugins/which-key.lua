--[[ WHICH-KEY MAPPINGS - QUICK REFERENCE

NOTE: These mappings are also documented in ~/.config/nvim/README.md
Please maintain consistency between both documents when making changes.

----------------------------------------------------------------------------------
TOP-LEVEL MAPPINGS (<leader>)                   | DESCRIPTION
----------------------------------------------------------------------------------
<leader>b - VimtexCompile                       | Compile LaTeX document
<leader>c - Create vertical split               | Split window vertically
<leader>d - Save and delete buffer              | Save file and close buffer
<leader>e - Toggle NvimTree explorer            | Open/close file explorer
<leader>j - Jupyter notebook functions          | Jupyter notebook operations
<leader>i - Open VimtexToc                      | Show LaTeX table of contents
<leader>k - Maximize split                      | Make current window full screen
<leader>q - Save all and quit                   | Save all files and exit Neovim
<leader>u - Open Telescope undo                 | Show undo history with preview
<leader>v - VimtexView                          | View compiled LaTeX document
<leader>w - Write all files                     | Save all open files

----------------------------------------------------------------------------------
ACTIONS (<leader>a)                             | DESCRIPTION
----------------------------------------------------------------------------------
<leader>aa - PDF annotations                    | Work with PDF annotations
<leader>ab - Export bibliography                | Export BibTeX to separate file
<leader>ac - Clear VimTex cache                 | Clear LaTeX compilation cache
<leader>ae - Show VimTex errors                 | Display LaTeX error messages
<leader>af - Format buffer                      | Format current buffer via LSP
<leader>ag - Edit glossary                      | Open LaTeX glossary template
<leader>ah - Toggle local highlight             | Highlight current word occurrences
<leader>ak - Clean VimTex aux files             | Remove LaTeX auxiliary files
<leader>al - Toggle Lean info view              | Show/hide Lean information panel
<leader>am - Run model checker                  | Execute model checker on file
<leader>ap - Run Python file                    | Execute current Python file
<leader>ar - Recalculate autolist               | Fix numbering in lists
<leader>at - Format tex file                    | Format LaTeX using latexindent
<leader>au - Update CWD                         | Change to file's directory
<leader>av - VimTex context menu                | Show VimTeX context actions
<leader>aw - Count words                        | Count words in LaTeX document
<leader>as - Edit snippets                      | Open snippets directory
<leader>aS - SSH connect                        | Connect to MIT server via SSH

----------------------------------------------------------------------------------
FIND (<leader>f)                                | DESCRIPTION
----------------------------------------------------------------------------------
<leader>fa - Find all files                     | Search all files, including hidden
<leader>fb - Find buffers                       | Switch between open buffers
<leader>fc - Find citations                     | Search BibTeX citations
<leader>ff - Find in project                    | Search text in project files
<leader>fl - Resume last search                 | Continue previous search
<leader>fq - Find in quickfix                   | Search within quickfix list
<leader>fg - Git commit history                 | Browse git commit history
<leader>fh - Help tags                          | Search Neovim help documentation
<leader>fk - Keymaps                            | Show all keybindings
<leader>fr - Registers                          | Show clipboard registers
<leader>ft - Colorschemes                       | Browse and change themes
<leader>fs - Search string                      | Search for string in project
<leader>fw - Search word under cursor           | Find current word in project
<leader>fy - Yank history                       | Browse clipboard history

----------------------------------------------------------------------------------
GIT (<leader>g)                                 | DESCRIPTION
----------------------------------------------------------------------------------
<leader>gb - Checkout branch                    | Switch to another git branch
<leader>gc - View commits                       | Show commit history
<leader>gd - View diff                          | Show changes against HEAD
<leader>gg - Open lazygit                       | Launch terminal git interface
<leader>gk - Previous hunk                      | Jump to previous change
<leader>gj - Next hunk                          | Jump to next change
<leader>gl - Line blame                         | Show git blame for current line
<leader>gp - Preview hunk                       | Preview current change
<leader>gs - Git status                         | Show files with changes
<leader>gt - Toggle blame                       | Toggle line blame display

----------------------------------------------------------------------------------
JUPYTER (<leader>j)                             | DESCRIPTION
----------------------------------------------------------------------------------
<leader>ja - Activate notebook mode             | Enable notebook navigation mode
<leader>jc - Show jupytext config               | Display current Jupytext config
<leader>je - Execute cell                       | Run current notebook cell
<leader>ji - Start IPython REPL                 | Start Python interactive shell
<leader>jj - Next cell                          | Navigate to next cell
<leader>jk - Previous cell                      | Navigate to previous cell
<leader>jn - Execute and next                   | Run cell and move to next
<leader>jo - Insert cell below                  | Add new cell below current
<leader>jO - Insert cell above                  | Add new cell above current
<leader>jp - Convert py to ipynb                | Convert Python to notebook
<leader>jm - Convert md to ipynb                | Convert Markdown to notebook
<leader>jP - Convert ipynb to py                | Convert notebook to Python
<leader>jM - Convert ipynb to md                | Convert notebook to Markdown
<leader>js - Send motion to REPL                | Send text via motion to REPL
<leader>jl - Send line to REPL                  | Send current line to REPL
<leader>jf - Send file to REPL                  | Send entire file to REPL
<leader>jq - Exit REPL                          | Close the REPL
<leader>jr - Clear REPL                         | Clear the REPL screen
<leader>jv - Send visual selection to REPL      | Send selected text to REPL

----------------------------------------------------------------------------------
AI HELP (<leader>h)                             | DESCRIPTION
----------------------------------------------------------------------------------
<leader>ha - Ask                                | Ask Avante AI a question
<leader>hb - Build dependencies                 | Build deps for Avante project
<leader>hc - Chat                               | Start chat with Avante AI
<leader>hd - Set model & provider               | Change AI model with defaults
<leader>he - Edit prompts                       | Open system prompt manager
<leader>hi - Stop generation                    | Interrupt AI generation
<leader>hk - Clear                              | Clear Avante chat/content
<leader>hm - Select model                       | Choose AI model for current provider
<leader>hM - Map repo                           | Create repo map for AI context
<leader>hp - Select prompt                      | Choose a different system prompt
<leader>hs - Selected edit                      | Edit selected text with AI
<leader>hr - Refresh assistant                  | Reload AI assistant
<leader>ht - Toggle assistant                   | Show/hide Avante interface

----------------------------------------------------------------------------------
LIST (<leader>L)                                | DESCRIPTION
----------------------------------------------------------------------------------
<leader>Lc - Toggle checkbox                    | Check/uncheck a checkbox
<leader>Ln - Next list item                     | Move to next item in list
<leader>Lp - Previous list item                 | Move to previous item in list
<leader>Lr - Reorder list                       | Fix list numbering

----------------------------------------------------------------------------------
LSP (<leader>l)                                 | DESCRIPTION
----------------------------------------------------------------------------------
<leader>lb - Buffer diagnostics                 | Show all errors in current file
<leader>lc - Code action                        | Show available code actions
<leader>ld - Go to definition                   | Jump to symbol definition
<leader>lD - Go to declaration                  | Jump to symbol declaration
<leader>lh - Hover help                         | Show documentation under cursor
<leader>li - Implementations                    | Find implementations of symbol
<leader>lk - Kill LSP                           | Stop language server
<leader>ll - Line diagnostics                   | Show errors for current line
<leader>ln - Next diagnostic                    | Go to next error/warning
<leader>lp - Previous diagnostic                | Go to previous error/warning
<leader>lr - References                         | Find all references to symbol
<leader>ls - Restart LSP                        | Restart language server
<leader>lt - Start LSP                          | Start language server
<leader>ly - Copy diagnostics                   | Copy diagnostics to clipboard
<leader>lR - Rename                             | Rename symbol under cursor

----------------------------------------------------------------------------------
MARKDOWN (<leader>m)                            | DESCRIPTION
----------------------------------------------------------------------------------
<leader>ml - Run Lectic                         | Run Lectic on current file
<leader>mn - New Lectic file                    | Create new Lectic file with template
<leader>ms - Submit selection                   | Submit visual selection with user message
<leader>mp - Markdown preview                   | Toggle markdown preview
<leader>mu - Open URL                           | Open URL under cursor
<leader>ma - Toggle all folds                   | Toggle all folds open/closed
<leader>mf - Toggle fold                        | Toggle fold under cursor
<leader>mt - Toggle folding method              | Switch between manual/smart folding

----------------------------------------------------------------------------------
SESSIONS (<leader>S)                            | DESCRIPTION
----------------------------------------------------------------------------------
<leader>Ss - Save session                       | Save current session
<leader>Sd - Delete session                     | Delete a saved session
<leader>Sl - Load session                       | Load a saved session

----------------------------------------------------------------------------------
NIXOS (<leader>n)                               | DESCRIPTION
----------------------------------------------------------------------------------
<leader>nd - Nix develop                        | Enter nix development shell
<leader>ng - Garbage collection                 | Clean up old nix packages
<leader>np - Browse packages                    | Open nixOS packages website
<leader>nm - MyNixOS                            | Open MyNixOS website
<leader>nr - Rebuild flake                      | Rebuild system from flake
<leader>nh - Home-manager switch                | Apply home-manager changes
<leader>nu - Update flake                       | Update flake dependencies

----------------------------------------------------------------------------------
PANDOC (<leader>p)                              | DESCRIPTION
----------------------------------------------------------------------------------
<leader>pw - Convert to Word                    | Convert to .docx format
<leader>pm - Convert to Markdown                | Convert to .md format
<leader>ph - Convert to HTML                    | Convert to .html format
<leader>pl - Convert to LaTeX                   | Convert to .tex format
<leader>pp - Convert to PDF                     | Convert to .pdf format
<leader>pv - View PDF                           | Open PDF in document viewer

----------------------------------------------------------------------------------
RUN (<leader>r)                                 | DESCRIPTION
----------------------------------------------------------------------------------
<leader>rc - Clear plugin cache                 | Clear Neovim plugin cache
<leader>re - Show linter errors                 | Display all errors in floating window
<leader>rk - Wipe plugin files                  | Remove all plugin files
<leader>rn - Next error                         | Go to next diagnostic/error
<leader>rp - Previous error                     | Go to previous diagnostic/error
<leader>rr - Reload configs                     | Reload Neovim configuration
<leader>rm - Show messages                      | Display notification history

----------------------------------------------------------------------------------
SURROUND (<leader>s)                            | DESCRIPTION
----------------------------------------------------------------------------------
<leader>ss - Surround                           | Surround with characters
<leader>sd - Delete surround                    | Remove surrounding characters
<leader>sc - Change surround                    | Change surrounding characters

----------------------------------------------------------------------------------
TEMPLATES (<leader>t)                           | DESCRIPTION
----------------------------------------------------------------------------------
<leader>tp - PhilPaper.tex                      | Insert philosophy paper template
<leader>tl - Letter.tex                         | Insert letter template
<leader>tg - Glossary.tex                       | Insert glossary template
<leader>th - HandOut.tex                        | Insert handout template
<leader>tb - PhilBeamer.tex                     | Insert beamer presentation
<leader>ts - SubFile.tex                        | Insert subfile template
<leader>tr - Root.tex                           | Insert root document template
<leader>tm - MultipleAnswer.tex                 | Insert multiple answer template
]]

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
        t = { "<cmd>Telescope colorscheme<CR>", "theme" },
        s = { "<cmd>Telescope grep_string<CR>", "string" },
        w = { "<cmd>lua SearchWordUnderCursor()<CR>", "word" },
        y = { "<cmd>YankyRingHistory<CR>", "yanks" },
        -- m = { "<cmd>Telescope man_pages<CR>", "man pages" },
        -- c = { "<cmd>Telescope commands<CR>", "commands" },
        -- r = { "<cmd>Telescope oldfiles<CR>", "recent" },
      },
      g = {
        name = "GIT",
        -- { '<leader>g', group = ' Git' },
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
        y = { "<cmd>lua CopyDiagnosticsToClipboard()<CR>", "copy diagnostics to clipboard" },
        R = { "<cmd>lua vim.lsp.buf.rename()<CR>", "rename" },
        -- T = { "<cmd>Telescope lsp_type_definitions<CR>", "type definition" },
      },
      -- MARKDOWN MAPPINGS
      m = {
        name = "MARKDOWN",
        -- LECTIC COMMANDS
        l = { "<cmd>Lectic<CR>", "run lectic on file" },
        n = { "<cmd>lua CreateNewLecticFile()<CR>", "new lectic file" },
        s = { "<cmd>lua SubmitLecticSelection()<CR>", "submit selection with message" },

        -- MARKDOWN/PREVIEW
        p = { "<cmd>MarkdownPreviewToggle <CR>", "markdown preview" },
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
        c = { "<cmd>TermExec cmd='rm -rf ~/.cache/nvim' open=0<CR>", "clear plugin cache" },
        e = { "<cmd>lua require('neotex.utils.diagnostics').show_all_errors()<CR>", "show linter errors" },
        -- h = { "<cmd>Hardtime toggle<cr>", "hardtime" }, -- Hardtime plugin has been deprecated
        k = { "<cmd>TermExec cmd='rm -rf ~/.local/share/nvim/lazy &' open=0<CR>", "wipe plugin files" },
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
    },
  },
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts.setup)
    wk.register(opts.defaults)
  end,
}
