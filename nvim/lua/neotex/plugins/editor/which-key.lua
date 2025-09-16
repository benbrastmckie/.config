-- neotex.plugins.editor.which-key
-- Keybinding configuration and display using which-key.nvim v3 API

--[[ WHICH-KEY MAPPINGS - COMPLETE REFERENCE
-----------------------------------------------------------

This module configures which-key.nvim using the modern v3 API with icon support 
and logical grouping by application domain. The configuration uses a hybrid approach:
- Static groups for always-available functionality  
- Dynamic groups with cond functions for filetype-specific features
- Autocmds for individual keymaps in filetype-specific groups

All LaTeX commands are consolidated under <leader>l, LSP commands under <leader>i,
and TODO commands use <leader>t with TEMPLATES under <leader>T.

----------------------------------------------------------------------------------
TOP-LEVEL MAPPINGS (<leader>)                   | DESCRIPTION
----------------------------------------------------------------------------------
<leader>c - Create vertical split               | Split window vertically
<leader>d - Save and delete buffer              | Save file and close buffer
<leader>e - Toggle NvimTree explorer            | Open/close file explorer
<leader>k - Kill/close split                    | Close current split window
<leader>q - Save all and quit                   | Save all files and exit Neovim
<leader>u - Open Telescope undo                 | Show undo history with preview
<leader>w - Write all files                     | Save all open files

----------------------------------------------------------------------------------
ACTIONS (<leader>a)                             | DESCRIPTION
----------------------------------------------------------------------------------
<leader>ad - Toggle debug mode                  | Enable/disable debug mode
<leader>af - Format buffer                      | Format current buffer using conform.nvim
<leader>ah - Toggle local highlight             | Highlight current word occurrences
<leader>al - Toggle Lean info view              | Show/hide Lean information panel
<leader>am - Run model checker                  | Execute model checker on file
<leader>ap - Run Python file                    | Execute current Python file
<leader>ar - Recalculate autolist               | Fix numbering in lists
<leader>au - Update CWD                         | Change to file's directory
<leader>as - Edit snippets                      | Open snippets directory
<leader>aS - SSH connect                        | Connect to MIT server via SSH
<leader>aU - Open URL                           | Open URL under cursor
<leader>aF - Toggle all folds                   | Toggle all folds open/closed
<leader>ao - Toggle fold                        | Toggle fold under cursor
<leader>aT - Toggle folding method              | Switch between manual/smart folding

----------------------------------------------------------------------------------
FIND (<leader>f)                                | DESCRIPTION
----------------------------------------------------------------------------------
<leader>fa - Find all files                     | Search all files, including hidden
<leader>fb - Find buffers                       | Switch between open buffers
<leader>fc - Find citations                     | Search BibTeX citations
<leader>ff - Find in project                    | Search text in project files
<leader>fl - Resume last search                 | Continue previous search
<leader>fp - Copy buffer path                   | Copy current file path to clipboard
<leader>fq - Find in quickfix                   | Search within quickfix list
<leader>fg - Git commit history                 | Browse git commit history
<leader>fh - Help tags                          | Search Neovim help documentation
<leader>fk - Keymaps                            | Show all keybindings
<leader>fr - Registers                          | Show clipboard registers
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
<leader>gj - Next hunk                          | Jump to next change
<leader>gk - Previous hunk                      | Jump to previous change
<leader>gl - Line blame                         | Show git blame for current line
<leader>gp - Preview hunk                       | Preview current change
<leader>gs - Git status                         | Show files with changes
<leader>gt - Toggle blame                       | Toggle line blame display

----------------------------------------------------------------------------------
AI HELP (<leader>h)                             | DESCRIPTION
----------------------------------------------------------------------------------
<leader>ha - Ask                                | Ask Avante AI a question
<leader>hc - Chat                               | Start chat with Avante AI
<leader>ht - Toggle Avante                      | Show/hide Avante interface
<leader>hs - Selected edit                      | Edit selected text with AI
<leader>ho - Open Claude Code                   | Toggle Claude Code terminal
<leader>hb - Add buffer to Claude               | Add current file to Claude context
<leader>hr - Add directory to Claude            | Add current directory to Claude context
<leader>hx - Open MCP Hub                       | Access MCP Hub interface
<leader>hd - Set model & provider               | Change AI model with defaults
<leader>he - Edit prompts                       | Open system prompt manager
<leader>hi - Interrupt                          | Stop AI generation
<leader>hk - Clear                              | Clear Avante chat/content
<leader>hm - Select model                       | Choose AI model for current provider
<leader>hp - Select prompt                      | Choose system prompt
<leader>hf - Refresh                            | Reload AI assistant
<leader>hl - Run Lectic                         | Execute Lectic AI on current file
<leader>hn - New Lectic file                    | Create a new file for Lectic processing
<leader>hL - Submit selection                   | Submit selected text to Lectic with message

----------------------------------------------------------------------------------
LSP & LINT (<leader>i)                          | DESCRIPTION
----------------------------------------------------------------------------------
<leader>ib - Buffer diagnostics                 | Show all errors in current file
<leader>ic - Code action                        | Show available code actions
<leader>id - Go to definition                   | Jump to symbol definition
<leader>iD - Go to declaration                  | Jump to symbol declaration
<leader>ih - Hover help                         | Show documentation under cursor
<leader>ii - Implementations                    | Find implementations of symbol
<leader>il - Line diagnostics                   | Show errors for current line
<leader>in - Next diagnostic                    | Go to next error/warning
<leader>ip - Previous diagnostic                | Go to previous error/warning
<leader>ir - References                         | Find all references to symbol
<leader>is - Restart LSP                        | Restart language server
<leader>it - Toggle LSP                         | Start/stop language server
<leader>iy - Copy diagnostics                   | Copy diagnostics to clipboard
<leader>iR - Rename                             | Rename symbol under cursor
<leader>iL - Lint file                          | Run linters on current file
<leader>ig - Toggle global linting              | Enable/disable linting globally
<leader>iB - Toggle buffer linting              | Enable/disable linting for buffer

----------------------------------------------------------------------------------
JUPYTER (<leader>j)                             | DESCRIPTION
----------------------------------------------------------------------------------
<leader>je - Execute cell                       | Run current notebook cell
<leader>jj - Next cell                          | Navigate to next cell
<leader>jk - Previous cell                      | Navigate to previous cell
<leader>jn - Execute and next                   | Run cell and move to next
<leader>jo - Insert cell below                  | Add new cell below current
<leader>jO - Insert cell above                  | Add new cell above current
<leader>js - Split cell                         | Split current cell at cursor
<leader>jc - Comment cell                       | Comment out current cell
<leader>ja - Run all cells                      | Execute all notebook cells
<leader>jb - Run cells below                    | Run notebook cells below cursor
<leader>ju - Merge with cell above              | Join current cell with cell above
<leader>jd - Merge with cell below              | Join current cell with cell below
<leader>ji - Start IPython REPL                 | Start Python interactive shell
<leader>jt - Send motion to REPL                | Send text via motion to REPL
<leader>jl - Send line to REPL                  | Send current line to REPL
<leader>jf - Send file to REPL                  | Send entire file to REPL
<leader>jq - Exit REPL                          | Close the REPL
<leader>jr - Clear REPL                         | Clear the REPL screen
<leader>jv - Send visual selection to REPL      | Send selected text to REPL

----------------------------------------------------------------------------------
LATEX (<leader>l)                               | DESCRIPTION
----------------------------------------------------------------------------------
<leader>la - PDF annotations                    | Work with PDF annotations
<leader>lb - Export bibliography                | Export BibTeX to separate file
<leader>lc - Compile LaTeX document             | Build/compile current document
<leader>le - Show VimTeX errors                 | Display LaTeX error messages
<leader>lf - Format tex file                    | Format LaTeX using latexindent
<leader>lg - Edit glossary                      | Open LaTeX glossary template
<leader>li - Open LaTeX table of contents       | Show document structure
<leader>lk - Clean VimTeX aux files             | Remove LaTeX auxiliary files
<leader>lm - VimTeX context menu                | Show VimTeX context actions
<leader>lv - View compiled LaTeX document       | Preview PDF output
<leader>lw - Count words                        | Count words in LaTeX document
<leader>lx - Clear VimTeX cache                 | Clear LaTeX compilation cache

----------------------------------------------------------------------------------
MAIL (<leader>m)                                | DESCRIPTION
----------------------------------------------------------------------------------
<leader>mo - Toggle sidebar                     | Open/close Himalaya email sidebar
<leader>ms - Sync inbox                         | Sync inbox with server (from any context)
<leader>mS - Full sync                          | Sync all email folders
<leader>mw - Write email                        | Compose a new email
<leader>me - Send email                         | Send current compose buffer (with scheduling)
<leader>md - Save draft                         | Save email as draft and close
<leader>mD - Discard email                      | Discard compose buffer without saving
<leader>mW - Setup wizard                       | Run Himalaya setup wizard
<leader>mx - Cancel all syncs                   | Stop all running sync processes
<leader>mh - Health check                       | Show Himalaya health status
<leader>mi - Sync status                        | Show detailed sync & auto-sync information
<leader>mf - Change folder                      | Switch to different email folder
<leader>ma - Switch account                     | Change email account
<leader>mt - Toggle auto-sync                   | Enable/disable automatic inbox syncing (15min)

----------------------------------------------------------------------------------
NIXOS (<leader>n)                               | DESCRIPTION
----------------------------------------------------------------------------------
<leader>nd - Nix develop                        | Enter nix development shell
<leader>nf - Rebuild flake                      | Rebuild system from flake
<leader>ng - Garbage collection                 | Clean up old nix packages (15d)
<leader>np - Browse packages                    | Open nixOS packages website
<leader>nm - MyNixOS                            | Open MyNixOS website
<leader>nh - Home-manager switch                | Apply home-manager changes
<leader>nr - Rebuild nix                        | Run update.sh script
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
<leader>rk - Wipe plugins and lock file         | Remove all plugin files AND lazy-lock.json
<leader>rn - Next error                         | Go to next diagnostic/error
<leader>rp - Previous error                     | Go to previous diagnostic/error
<leader>rr - Reload configs                     | Reload Neovim configuration
<leader>rm - Show messages                      | Display notification history
<leader>rt - Test Himalaya                      | Run Himalaya email client tests

----------------------------------------------------------------------------------
SESSIONS (<leader>S)                            | DESCRIPTION
----------------------------------------------------------------------------------
<leader>Ss - Save session                       | Save current session
<leader>Sd - Delete session                     | Delete a saved session
<leader>Sl - Load session                       | Load a saved session

----------------------------------------------------------------------------------
SURROUND (<leader>s)                            | DESCRIPTION
----------------------------------------------------------------------------------
<leader>ss - Add surrounding                    | Add surrounding to text (requires motion)
<leader>sd - Delete surrounding                 | Remove surrounding characters
<leader>sc - Change surrounding                 | Replace surrounding characters

----------------------------------------------------------------------------------
TODO (<leader>t)                               | DESCRIPTION
----------------------------------------------------------------------------------
<leader>tt - Todo telescope                     | Find all TODOs in project
<leader>tn - Next todo                          | Jump to next TODO comment
<leader>tp - Previous todo                      | Jump to previous TODO comment
<leader>tl - Todo location list                 | Show TODOs in location list
<leader>tq - Todo quickfix                      | Show TODOs in quickfix list

----------------------------------------------------------------------------------
TEMPLATES (<leader>T)                           | DESCRIPTION
----------------------------------------------------------------------------------
<leader>Ta - Article.tex                        | Insert article template
<leader>Tb - Beamer_slides.tex                  | Insert beamer presentation template
<leader>Tg - Glossary.tex                       | Insert glossary template
<leader>Th - Handout.tex                        | Insert handout template
<leader>Tl - Letter.tex                         | Insert letter template
<leader>Tm - MultipleAnswer.tex                 | Insert multiple answer template
<leader>Tr - Copy report/ directory             | Copy report template directory
<leader>Ts - Copy springer/ directory           | Copy springer template directory

----------------------------------------------------------------------------------
TEXT (<leader>x)                                | DESCRIPTION
----------------------------------------------------------------------------------
<leader>xa - Align                              | Start text alignment
<leader>xA - Align with preview                 | Start alignment with preview
<leader>xs - Split/join toggle                  | Toggle between single/multi-line
<leader>xd - Toggle diff overlay                | Show diff between buffer and clipboard
<leader>xw - Toggle word diff                   | Show word-level diffs

----------------------------------------------------------------------------------
YANK (<leader>y)                                | DESCRIPTION
----------------------------------------------------------------------------------
<leader>yh - Yank history                       | Browse clipboard history with Telescope
<leader>yc - Clear history                      | Clear the yank history

----------------------------------------------------------------------------------
VISUAL MODE MAPPINGS                            | DESCRIPTION
----------------------------------------------------------------------------------
<leader>ss - Add surrounding to selection       | Surround selected text (visual mode)
]]

return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  dependencies = {
    'echasnovski/mini.nvim',
  },
  opts = {
    preset = "classic",
    delay = function(ctx)
      return ctx.plugin and 0 or 200
    end,
    show_help = false,    -- Remove bottom help/status bar
    show_keys = false,    -- Remove key hints
    win = {
      border = "rounded",
      padding = { 1, 2 },
      title = false,
      title_pos = "center",
      zindex = 1000,
      wo = {
        winblend = 10,
      },
      bo = {
        filetype = "which_key",
        buftype = "nofile",
      },
    },
    icons = {
      breadcrumb = "»",
      separator = "➜",
      group = "+",
    },
    layout = {
      width = { min = 20, max = 50 },
      height = { min = 4, max = 25 },
      spacing = 3,
      align = "left",
    },
    keys = {
      scroll_down = "<c-d>",
      scroll_up = "<c-u>",
    },
    sort = { "local", "order", "group", "alphanum", "mod" },
    disable = {
      bt = { "help", "quickfix", "terminal", "prompt" },
      ft = { "neo-tree" }
    },
    triggers = {
      { "<leader>", mode = { "n", "v" } }
    }
  },
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)

    -- Top-level mappings
    wk.add({
      { "<leader>c", "<cmd>vert sb<CR>", desc = "create split", icon = "󰯌" },
      { "<leader>d", "<cmd>update! | lua Snacks.bufdelete()<CR>", desc = "delete buffer", icon = "󰩺" },
      { "<leader>e", "<cmd>Neotree toggle<CR>", desc = "explorer", icon = "󰙅" },
      { "<leader>k", "<cmd>close<CR>", desc = "kill split", icon = "󰆴" },
      { "<leader>q", "<cmd>wa! | qa!<CR>", desc = "quit", icon = "󰗼" },
      { "<leader>u", "<cmd>Telescope undo<CR>", desc = "undo", icon = "󰕌" },
      { "<leader>w", "<cmd>wa!<CR>", desc = "write", icon = "󰆓" },
    })

    -- FILETYPE-DEPENDENT GROUPS
    -- Uses hybrid approach: dynamic group headers with cond, individual mappings via autocmds
    
    -- LaTeX group (dynamic group header)
    wk.add({
      {
        "<leader>l",
        group = function()
          local ft = vim.bo.filetype
          return vim.tbl_contains({ "tex", "latex", "bib", "cls", "sty" }, ft) and "latex" or nil
        end,
        icon = "󰙩",
        cond = function()
          return vim.tbl_contains({ "tex", "latex", "bib", "cls", "sty" }, vim.bo.filetype)
        end
      },
    })
    
    -- LaTeX individual mappings (autocmd approach)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "tex", "latex", "bib", "cls", "sty" },
      callback = function()
        wk.add({
          { "<leader>la", "<cmd>lua PdfAnnots()<CR>", desc = "annotate", icon = "󰏪", buffer = 0 },
          { "<leader>lb", "<cmd>terminal bibexport -o %:p:r.bib %:p:r.aux<CR>", desc = "bib export", icon = "󰈝", buffer = 0 },
          { "<leader>lc", "<cmd>VimtexCompile<CR>", desc = "compile", icon = "󰖷", buffer = 0 },
          { "<leader>le", "<cmd>VimtexErrors<CR>", desc = "errors", icon = "󰅚", buffer = 0 },
          { "<leader>lf", "<cmd>terminal latexindent -w %:p:r.tex<CR>", desc = "format", icon = "󰉣", buffer = 0 },
          { "<leader>lg", "<cmd>e ~/.config/nvim/templates/Glossary.tex<CR>", desc = "glossary", icon = "󰈚", buffer = 0 },
          { "<leader>li", "<cmd>VimtexTocOpen<CR>", desc = "index", icon = "󰋽", buffer = 0 },
          { "<leader>lk", "<cmd>VimtexClean<CR>", desc = "kill aux", icon = "󰩺", buffer = 0 },
          { "<leader>lm", "<plug>(vimtex-context-menu)", desc = "menu", icon = "󰍉", buffer = 0 },
          { "<leader>lv", "<cmd>VimtexView<CR>", desc = "view", icon = "󰛓", buffer = 0 },
          { "<leader>lw", "<cmd>VimtexCountWords!<CR>", desc = "word count", icon = "󰆿", buffer = 0 },
          { "<leader>lx", "<cmd>:VimtexClearCache All<CR>", desc = "clear cache", icon = "󰃢", buffer = 0 },
        })
      end,
    })

    -- LSP & LINT group
    wk.add({
      { "<leader>i", group = "lsp", icon = "󰅴" },
      { "<leader>ib", "<cmd>Telescope diagnostics bufnr=0<CR>", desc = "buffer diagnostics", icon = "󰒓" },
      { "<leader>ic", "<cmd>lua vim.lsp.buf.code_action()<CR>", desc = "code action", icon = "󰌵" },
      { "<leader>id", "<cmd>Telescope lsp_definitions<CR>", desc = "definition", icon = "󰳦" },
      { "<leader>iD", "<cmd>lua vim.lsp.buf.declaration()<CR>", desc = "declaration", icon = "󰳦" },
      { "<leader>ih", "<cmd>lua vim.lsp.buf.hover()<CR>", desc = "help", icon = "󰞋" },
      { "<leader>ii", "<cmd>Telescope lsp_implementations<CR>", desc = "implementations", icon = "󰡱" },
      { "<leader>il", "<cmd>lua vim.diagnostic.open_float()<CR>", desc = "line diagnostics", icon = "󰒓" },
      { "<leader>in", "<cmd>lua vim.diagnostic.goto_next()<CR>", desc = "next diagnostic", icon = "󰮰" },
      { "<leader>ip", "<cmd>lua vim.diagnostic.goto_prev()<CR>", desc = "previous diagnostic", icon = "󰮲" },
      { "<leader>ir", "<cmd>Telescope lsp_references<CR>", desc = "references", icon = "󰌹" },
      { "<leader>is", "<cmd>LspRestart<CR>", desc = "restart lsp", icon = "󰜉" },
      { "<leader>it", function()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if #clients > 0 then
          vim.cmd('LspStop')
          require('neotex.util.notifications').lsp('LSP stopped', require('neotex.util.notifications').categories.USER_ACTION)
        else
          vim.cmd('LspStart')
          require('neotex.util.notifications').lsp('LSP started', require('neotex.util.notifications').categories.USER_ACTION)
        end
      end, desc = "toggle lsp", icon = "󰔡" },
      { "<leader>iy", "<cmd>lua CopyDiagnosticsToClipboard()<CR>", desc = "copy diagnostics", icon = "󰆏" },
      { "<leader>iR", "<cmd>lua vim.lsp.buf.rename()<CR>", desc = "rename", icon = "󰑕" },
      { "<leader>iL", function() require("lint").try_lint() end, desc = "lint file", icon = "󰁨" },
      { "<leader>ig", "<cmd>LintToggle<CR>", desc = "toggle global linting", icon = "󰔡" },
      { "<leader>iB", "<cmd>LintToggle buffer<CR>", desc = "toggle buffer linting", icon = "󰔡" },
    })

    -- ACTIONS group
    wk.add({
      { "<leader>a", group = "actions", icon = "󰌵" },
      { "<leader>af", function() require("conform").format({ async = true, lsp_fallback = true }) end, desc = "format", icon = "󰉣" },
      { "<leader>ah", "<cmd>LocalHighlightToggle<CR>", desc = "highlight", icon = "󰠷" },
      { "<leader>ak", "<cmd>BufDeleteFile<CR>", desc = "kill file and buffer", icon = "󰆴" },
      { "<leader>au", "<cmd>cd %:p:h | Neotree reveal<CR>", desc = "update cwd", icon = "󰉖" },
      { "<leader>as", "<cmd>Neotree ~/.config/nvim/snippets/<CR>", desc = "snippets edit", icon = "󰩫" },
      { "<leader>aS", "<cmd>TermExec cmd='ssh brastmck@eofe10.mit.edu'<CR>", desc = "ssh", icon = "󰣀" },
      { "<leader>aU", "<cmd>lua OpenUrlUnderCursor()<CR>", desc = "open URL under cursor", icon = "󰖟" },
      { "<leader>ad", function()
          local notify = require('neotex.util.notifications')
          notify.toggle_debug_mode()
        end, desc = "toggle debug mode", icon = "󰃤" },
      { "<leader>aF", "<cmd>lua ToggleAllFolds()<CR>", desc = "toggle all folds", icon = "󰘖" },
      { "<leader>ao", "za", desc = "toggle fold under cursor", icon = "󰘖" },
      { "<leader>aT", "<cmd>lua ToggleFoldingMethod()<CR>", desc = "toggle folding method", icon = "󰘖" },
    })
    
    -- Filetype-specific actions (autocmd approach)
    -- Lean actions (only for .lean files)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "lean" },
      callback = function()
        wk.add({
          { "<leader>al", "<cmd>LeanInfoviewToggle<CR>", desc = "lean info", icon = "󰊕", buffer = 0 },
        })
      end,
    })
    
    -- Python actions (only for .py files)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "python" },
      callback = function()
        wk.add({
          { "<leader>ap", "<cmd>TermExec cmd='python %:p:r.py'<CR>", desc = "python", icon = "󰌠", buffer = 0 },
          { "<leader>am", "<cmd>TermExec cmd='./Code/dev_cli.py %:p:r.py'<CR>", desc = "model checker", icon = "󰐊", buffer = 0 },
        })
      end,
    })
    
    -- Markdown actions (only for markdown files)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "markdown", "md" },
      callback = function()
        wk.add({
          { "<leader>ar", "<cmd>AutolistRecalculate<CR>", desc = "reorder list", icon = "󰔢", buffer = 0 },
        })
      end,
    })
    -- FIND group
    wk.add({
      { "<leader>f", group = "find", icon = "󰍉" },
      { "<leader>fa", "<cmd>lua require('telescope.builtin').find_files({ no_ignore = true, hidden = true, search_dirs = { '~/' } })<CR>", desc = "all files", icon = "󰈙" },
      { "<leader>fb", "<cmd>lua require('telescope.builtin').buffers(require('telescope.themes').get_dropdown{previewer = false})<CR>", desc = "buffers", icon = "󰓩" },
      { "<leader>fc", "<cmd>Telescope bibtex format_string=\\citet{%s}<CR>", desc = "citations", icon = "󰈙" },
      { "<leader>ff", "<cmd>Telescope live_grep theme=ivy<CR>", desc = "project", icon = "󰊄" },
      { "<leader>fl", "<cmd>Telescope resume<CR>", desc = "last search", icon = "󰺄" },
      { "<leader>fp", "<cmd>lua require('neotex.util.misc').copy_buffer_path()<CR>", desc = "copy buffer path", icon = "󰆏" },
      { "<leader>fq", "<cmd>Telescope quickfix<CR>", desc = "quickfix", icon = "󰁨" },
      { "<leader>fg", "<cmd>Telescope git_commits<CR>", desc = "git history", icon = "󰊢" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "help", icon = "󰞋" },
      { "<leader>fk", "<cmd>Telescope keymaps<CR>", desc = "keymaps", icon = "󰌌" },
      { "<leader>fr", "<cmd>Telescope registers<CR>", desc = "registers", icon = "󰊄" },
      { "<leader>fs", "<cmd>Telescope grep_string<CR>", desc = "string", icon = "󰊄" },
      { "<leader>fw", "<cmd>lua SearchWordUnderCursor()<CR>", desc = "word", icon = "󰊄" },
      { "<leader>fy", function() _G.YankyTelescopeHistory() end, desc = "yanks", icon = "󰆏" },
    })

    -- GIT group
    wk.add({
      { "<leader>g", group = "git", icon = "󰊢" },
      { "<leader>gb", "<cmd>Telescope git_branches<CR>", desc = "checkout branch", icon = "󰘬" },
      { "<leader>gc", "<cmd>Telescope git_commits<CR>", desc = "git commits", icon = "󰜘" },
      { "<leader>gd", "<cmd>Gitsigns diffthis HEAD<CR>", desc = "diff", icon = "󰦓" },
      { "<leader>gg", function() require("snacks").lazygit() end, desc = "lazygit", icon = "󰊢" },
      { "<leader>gk", "<cmd>Gitsigns prev_hunk<CR>", desc = "prev hunk", icon = "󰮲" },
      { "<leader>gj", "<cmd>Gitsigns next_hunk<CR>", desc = "next hunk", icon = "󰮰" },
      { "<leader>gl", "<cmd>Gitsigns blame_line<CR>", desc = "line blame", icon = "󰊢" },
      { "<leader>gp", "<cmd>Gitsigns preview_hunk<CR>", desc = "preview hunk", icon = "󰆈" },
      { "<leader>gs", "<cmd>Telescope git_status<CR>", desc = "git status", icon = "󰊢" },
      { "<leader>gt", "<cmd>Gitsigns toggle_current_line_blame<CR>", desc = "toggle blame", icon = "󰔡" },
    })

    -- AI HELP group
    wk.add({
      { "<leader>h", group = "ai help", icon = "󰚩" },
      { "<leader>ha", function() require("neotex.plugins.ai.util.avante_mcp").with_mcp("AvanteAsk") end, desc = "ask", icon = "󰞋" },
      { "<leader>hc", function() require("neotex.plugins.ai.util.avante_mcp").with_mcp("AvanteChat") end, desc = "chat", icon = "󰻞" },
      { "<leader>ht", function() require("neotex.plugins.ai.util.avante_mcp").with_mcp("AvanteToggle") end, desc = "toggle avante", icon = "󰔡" },
      { "<leader>hs", function() require("neotex.plugins.ai.util.avante_mcp").with_mcp("AvanteEdit") end, desc = "selected edit", icon = "󰏫" },
      { "<leader>ho", "<cmd>ClaudeCodeFocus<CR>", desc = "toggle claude code", icon = "󰚩" },
      { "<leader>hb", "<cmd>ClaudeCodeAddBuffer<CR>", desc = "add buffer to claude", icon = "󰈙" },
      { "<leader>hr", "<cmd>ClaudeCodeAddDir<CR>", desc = "add directory to claude", icon = "󰉖" },
      { "<leader>hx", "<cmd>MCPHubOpen<CR>", desc = "open mcp hub", icon = "󰚩" },
      { "<leader>hd", "<cmd>AvanteProvider<CR>", desc = "set model & provider", icon = "󰒕" },
      { "<leader>he", "<cmd>AvantePromptManager<CR>", desc = "edit prompts", icon = "󰏫" },
      { "<leader>hi", "<cmd>AvanteStop<CR>", desc = "interrupt", icon = "󰚌" },
      { "<leader>hk", "<cmd>AvanteClear<CR>", desc = "clear", icon = "󰃢" },
      { "<leader>hm", "<cmd>AvanteModel<CR>", desc = "select model", icon = "󰒕" },
      { "<leader>hp", "<cmd>AvantePrompt<CR>", desc = "select prompt", icon = "󰞋" },
      { "<leader>hf", "<cmd>AvanteRefresh<CR>", desc = "refresh", icon = "󰜉" },
      { "<leader>hl", "<cmd>Lectic<CR>", desc = "run lectic on file", icon = "󰊠" },
      { "<leader>hn", "<cmd>LecticCreateFile<CR>", desc = "new lectic file", icon = "󰈙" },
      { "<leader>hL", "<cmd>LecticSubmitSelection<CR>", desc = "submit selection with message", icon = "󰚟" },
    })

    -- Jupyter group (dynamic group header)
    wk.add({
      {
        "<leader>j",
        group = function()
          return vim.bo.filetype == "ipynb" and "jupyter" or nil
        end,
        icon = "󰌠",
        cond = function()
          return vim.bo.filetype == "ipynb"
        end
      },
    })
    
    -- Jupyter individual mappings (autocmd approach)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "ipynb" },
      callback = function()
        wk.add({
          { "<leader>je", "<cmd>lua require('notebook-navigator').run_cell()<CR>", desc = "execute cell", icon = "󰐊", buffer = 0 },
          { "<leader>jj", "<cmd>lua require('notebook-navigator').move_cell('d')<CR>", desc = "next cell", icon = "󰮰", buffer = 0 },
          { "<leader>jk", "<cmd>lua require('notebook-navigator').move_cell('u')<CR>", desc = "previous cell", icon = "󰮲", buffer = 0 },
          { "<leader>jn", "<cmd>lua require('notebook-navigator').run_and_move()<CR>", desc = "execute and next", icon = "󰒭", buffer = 0 },
          { "<leader>jo", "<cmd>lua require('neotex.util.diagnostics').add_jupyter_cell_with_closing()<CR>", desc = "insert cell below", icon = "󰐕", buffer = 0 },
          { "<leader>jO", "<cmd>lua require('notebook-navigator').add_cell_above()<CR>", desc = "insert cell above", icon = "󰐖", buffer = 0 },
          { "<leader>js", "<cmd>lua require('notebook-navigator').split_cell()<CR>", desc = "split cell", icon = "󰤋", buffer = 0 },
          { "<leader>jc", "<cmd>lua require('notebook-navigator').comment_cell()<CR>", desc = "comment cell", icon = "󰆈", buffer = 0 },
          { "<leader>ja", "<cmd>lua require('notebook-navigator').run_all_cells()<CR>", desc = "run all cells", icon = "󰐊", buffer = 0 },
          { "<leader>jb", "<cmd>lua require('notebook-navigator').run_cells_below()<CR>", desc = "run cells below", icon = "󰐊", buffer = 0 },
          { "<leader>ju", "<cmd>lua require('notebook-navigator').merge_cell('u')<CR>", desc = "merge with cell above", icon = "󰅂", buffer = 0 },
          { "<leader>jd", "<cmd>lua require('notebook-navigator').merge_cell('d')<CR>", desc = "merge with cell below", icon = "󰅀", buffer = 0 },
          { "<leader>ji", "<cmd>lua require('iron.core').repl_for('python')<CR>", desc = "start IPython REPL", icon = "󰌠", buffer = 0 },
          { "<leader>jt", "<cmd>lua require('iron.core').run_motion('send_motion')<CR>", desc = "send motion to REPL", icon = "󰊠", buffer = 0 },
          { "<leader>jl", "<cmd>lua require('iron.core').send_line()<CR>", desc = "send line to REPL", icon = "󰊠", buffer = 0 },
          { "<leader>jf", "<cmd>lua require('iron.core').send(nil, vim.fn.readfile(vim.fn.expand('%')))<CR>", desc = "send file to REPL", icon = "󰊠", buffer = 0 },
          { "<leader>jq", "<cmd>lua require('iron.core').close_repl()<CR>", desc = "exit REPL", icon = "󰚌", buffer = 0 },
          { "<leader>jr", "<cmd>lua require('iron.core').send(nil, string.char(12))<CR>", desc = "clear REPL", icon = "󰃢", buffer = 0 },
          { "<leader>jv", "<cmd>lua require('iron.core').visual_send()<CR>", desc = "send visual selection to REPL", icon = "󰊠", buffer = 0 },
        })
      end,
    })

    -- MAIL group
    wk.add({
      { "<leader>m", group = "mail", icon = "󰇮" },
      { "<leader>mo", "<cmd>HimalayaToggle<CR>", desc = "toggle sidebar", icon = "󰊫" },
      { "<leader>ms", "<cmd>HimalayaSyncInbox<CR>", desc = "sync inbox", icon = "󰜉" },
      { "<leader>mS", "<cmd>HimalayaSyncFull<CR>", desc = "full sync", icon = "󰜉" },
      { "<leader>mw", "<cmd>HimalayaWrite<CR>", desc = "write email", icon = "󰝒" },
      { "<leader>me", "<cmd>HimalayaSend<CR>", desc = "send email", icon = "󰊠" },
      { "<leader>md", "<cmd>HimalayaSaveDraft<CR>", desc = "save draft", icon = "󰉊" },
      { "<leader>mD", "<cmd>HimalayaDiscard<CR>", desc = "discard email", icon = "󰩺" },
      { "<leader>mW", "<cmd>HimalayaSetup<CR>", desc = "setup wizard", icon = "󰗀" },
      { "<leader>mx", "<cmd>HimalayaCancelSync<CR>", desc = "cancel all syncs", icon = "󰚌" },
      { "<leader>mh", "<cmd>HimalayaHealth<CR>", desc = "health check", icon = "󰸉" },
      { "<leader>mi", "<cmd>HimalayaSyncInfo<CR>", desc = "sync status", icon = "󰋼" },
      { "<leader>mf", "<cmd>HimalayaFolder<CR>", desc = "change folder", icon = "󰉋" },
      { "<leader>ma", "<cmd>HimalayaAccounts<CR>", desc = "switch account", icon = "󰌏" },
      { "<leader>mt", "<cmd>HimalayaAutoSyncToggle<CR>", desc = "toggle auto-sync", icon = "󰑖" },
      { "<leader>mX", "<cmd>HimalayaBackupAndFresh<CR>", desc = "backup & fresh", icon = "󰁯" },
      { "<leader>mF", "<cmd>HimalayaRecreateFolders<CR>", desc = "recreate folders", icon = "󰝰" },
    })

    -- MAIL LIST BUFFER specific keymaps (himalaya-list filetype)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "himalaya-list",
      callback = function()
        wk.add({
          -- Buffer-specific keymaps are defined in himalaya config
        }, { buffer = 0 })
      end,
    })

    -- EMAIL READING BUFFER specific keymaps (himalaya-email filetype)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "himalaya-email",
      callback = function()
        wk.add({
          -- Buffer-specific keymaps are defined in himalaya config
        }, { buffer = 0 })
      end,
    })

    -- EMAIL COMPOSE BUFFER specific keymaps (mail filetype)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "mail",
      callback = function()
        -- Only add these mappings if it's a Himalaya compose buffer
        local composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
        if composer.is_compose_buffer(vim.api.nvim_get_current_buf()) then
          wk.add({
            -- Additional compose buffer mapping
            { "<leader>mq", "<cmd>HimalayaDiscard<CR>", desc = "quit (discard)", icon = "󰆴", buffer = 0 },
          }, { buffer = 0 })
        end
      end,
    })
    
    -- SESSIONS group
    wk.add({
      { "<leader>S", group = "sessions", icon = "󰆔" },
      { "<leader>Ss", "<cmd>SessionManager save_current_session<CR>", desc = "save", icon = "󰆓" },
      { "<leader>Sd", "<cmd>SessionManager delete_session<CR>", desc = "delete", icon = "󰚌" },
      { "<leader>Sl", "<cmd>SessionManager load_session<CR>", desc = "load", icon = "󰉖" },
    })

    -- NIXOS group
    wk.add({
      { "<leader>n", group = "nixos", icon = "󱄅" },
      { "<leader>nd", "<cmd>TermExec cmd='nix develop'<CR><C-w>j", desc = "develop", icon = "󰐊" },
      { "<leader>nf", "<cmd>TermExec cmd='sudo nixos-rebuild switch --flake ~/.dotfiles/'<CR><C-w>l", desc = "rebuild flake", icon = "󰜉" },
      { "<leader>ng", "<cmd>TermExec cmd='nix-collect-garbage --delete-older-than 15d'<CR><C-w>j", desc = "garbage", icon = "󰩺" },
      { "<leader>np", "<cmd>TermExec cmd='brave https://search.nixos.org/packages' open=0<CR>", desc = "packages", icon = "󰏖" },
      { "<leader>nm", "<cmd>TermExec cmd='brave https://mynixos.com' open=0<CR>", desc = "my-nixos", icon = "󰖟" },
      { "<leader>nh", "<cmd>TermExec cmd='home-manager switch --flake ~/.dotfiles/'<CR><C-w>l", desc = "home-manager", icon = "󰋜" },
      { "<leader>nr", "<cmd>TermExec cmd='~/.dotfiles/update.sh'<CR><C-w>l", desc = "rebuild nix", icon = "󰜉" },
      { "<leader>nu", "<cmd>TermExec cmd='nix flake update'<CR><C-w>j", desc = "update", icon = "󰚰" },
    })

    -- Pandoc group (dynamic group header)
    wk.add({
      {
        "<leader>p",
        group = function()
          return vim.tbl_contains({ "markdown", "md", "tex", "latex", "org", "rst", "html", "docx" }, vim.bo.filetype) and "pandoc" or nil
        end,
        icon = "󰈙",
        cond = function()
          return vim.tbl_contains({ "markdown", "md", "tex", "latex", "org", "rst", "html", "docx" }, vim.bo.filetype)
        end
      },
    })
    
    -- Pandoc individual mappings (autocmd approach)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "markdown", "md", "tex", "latex", "org", "rst", "html", "docx" },
      callback = function()
        wk.add({
          { "<leader>pw", "<cmd>TermExec cmd='pandoc %:p -o %:p:r.docx'<CR>", desc = "word", icon = "󰈭", buffer = 0 },
          { "<leader>pm", "<cmd>TermExec cmd='pandoc %:p -o %:p:r.md'<CR>", desc = "markdown", icon = "󱀈", buffer = 0 },
          { "<leader>ph", "<cmd>TermExec cmd='pandoc %:p -o %:p:r.html'<CR>", desc = "html", icon = "󰌝", buffer = 0 },
          { "<leader>pl", "<cmd>TermExec cmd='pandoc %:p -o %:p:r.tex'<CR>", desc = "latex", icon = "󰐺", buffer = 0 },
          { "<leader>pp", "<cmd>TermExec cmd='pandoc %:p -o %:p:r.pdf' open=0<CR>", desc = "pdf", icon = "󰈙", buffer = 0 },
          { "<leader>pv", "<cmd>TermExec cmd='sioyek %:p:r.pdf &' open=0<CR>", desc = "view", icon = "󰛓", buffer = 0 },
        })
      end,
    })
    -- RUN group
    wk.add({
      { "<leader>r", group = "run", icon = "󰐊" },
      { "<leader>rc", "<cmd>TermExec cmd='rm -rf ~/.cache/nvim' open=0<CR>", desc = "clear plugin cache", icon = "󰃢" },
      { "<leader>re", "<cmd>lua require('neotex.util.diagnostics').show_all_errors()<CR>", desc = "show linter errors", icon = "󰅚" },
      { "<leader>rk", "<cmd>TermExec cmd='rm -rf ~/.local/share/nvim/lazy && rm -f ~/.config/nvim/lazy-lock.json' open=0<CR>", desc = "wipe plugins and lock file", icon = "󰩺" },
      { "<leader>rn", "function() vim.diagnostic.goto_next{popup_opts = {show_header = false}} end", desc = "next", icon = "󰮰" },
      { "<leader>rp", "function() vim.diagnostic.goto_prev{popup_opts = {show_header = false}} end", desc = "prev", icon = "󰮲" },
      { "<leader>rr", "<cmd>ReloadConfig<cr>", desc = "reload configs", icon = "󰜉" },
      { "<leader>rt", "<cmd>HimalayaTest<cr>", desc = "test himalaya", icon = "󰙨" },
      { "<leader>rm", "<cmd>lua Snacks.notifier.show_history()<cr>", desc = "show messages", icon = "󰍡" },
    })

    -- SURROUND group
    wk.add({
      { "<leader>s", group = "surround", icon = "󰅪" },
      { "<leader>ss", "<Plug>(nvim-surround-normal)", desc = "surround", icon = "󰅪" },
      { "<leader>sd", "<Plug>(nvim-surround-delete)", desc = "delete", icon = "󰚌" },
      { "<leader>sc", "<Plug>(nvim-surround-change)", desc = "change", icon = "󰏫" },
    })

    -- TODO group
    wk.add({
      { "<leader>t", group = "todo", icon = "󰄬" },
      { "<leader>tt", "<cmd>TodoTelescope<CR>", desc = "todo telescope", icon = "󰄬" },
      { "<leader>tn", function() require("todo-comments").jump_next() end, desc = "next todo", icon = "󰮰" },
      { "<leader>tp", function() require("todo-comments").jump_prev() end, desc = "previous todo", icon = "󰮲" },
      { "<leader>tl", "<cmd>TodoLocList<CR>", desc = "todo location list", icon = "󰈙" },
      { "<leader>tq", "<cmd>TodoQuickFix<CR>", desc = "todo quickfix", icon = "󰁨" },
    })

    -- LaTeX Templates group (dynamic group header)
    wk.add({
      {
        "<leader>T",
        group = function()
          return vim.tbl_contains({ "tex", "latex" }, vim.bo.filetype) and "templates" or nil
        end,
        icon = "󰈭",
        cond = function()
          return vim.tbl_contains({ "tex", "latex" }, vim.bo.filetype)
        end
      },
    })
    
    -- LaTeX Templates individual mappings (autocmd approach)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "tex", "latex" },
      callback = function()
        wk.add({
          { "<leader>Ta", "<cmd>read ~/.config/nvim/templates/article.tex<CR>", desc = "article.tex", icon = "󰈙", buffer = 0 },
          { "<leader>Tb", "<cmd>read ~/.config/nvim/templates/beamer_slides.tex<CR>", desc = "beamer_slides.tex", icon = "󰈙", buffer = 0 },
          { "<leader>Tg", "<cmd>read ~/.config/nvim/templates/glossary.tex<CR>", desc = "glossary.tex", icon = "󰈙", buffer = 0 },
          { "<leader>Th", "<cmd>read ~/.config/nvim/templates/handout.tex<CR>", desc = "handout.tex", icon = "󰈙", buffer = 0 },
          { "<leader>Tl", "<cmd>read ~/.config/nvim/templates/letter.tex<CR>", desc = "letter.tex", icon = "󰈙", buffer = 0 },
          { "<leader>Tm", "<cmd>read ~/.config/nvim/templates/MultipleAnswer.tex<CR>", desc = "MultipleAnswer.tex", icon = "󰈙", buffer = 0 },
          { "<leader>Tr", function()
            local template_dir = vim.fn.expand("~/.config/nvim/templates/report")
            local current_dir = vim.fn.getcwd()
            vim.fn.system("cp -r " .. vim.fn.shellescape(template_dir) .. " " .. vim.fn.shellescape(current_dir))
            require('neotex.util.notifications').editor('Template copied', require('neotex.util.notifications').categories.USER_ACTION, { template = 'report', directory = current_dir })
          end, desc = "Copy report/ directory", icon = "󰉖", buffer = 0 },
          { "<leader>Ts", function()
            local template_dir = vim.fn.expand("~/.config/nvim/templates/springer")
            local current_dir = vim.fn.getcwd()
            vim.fn.system("cp -r " .. vim.fn.shellescape(template_dir) .. " " .. vim.fn.shellescape(current_dir))
            require('neotex.util.notifications').editor('Template copied', require('neotex.util.notifications').categories.USER_ACTION, { template = 'springer', directory = current_dir })
          end, desc = "Copy springer/ directory", icon = "󰉖", buffer = 0 },
        })
      end,
    })

    -- TEXT group
    wk.add({
      { "<leader>x", group = "text", icon = "󰤌" },
      { "<leader>xa", desc = "align", icon = "󰉞" },
      { "<leader>xA", desc = "align with preview", icon = "󰉞" },
      { "<leader>xs", desc = "split/join toggle", icon = "󰤋" },
      { "<leader>xd", desc = "toggle diff overlay", icon = "󰦓" },
      { "<leader>xw", desc = "toggle word diff", icon = "󰦓" },
    })

    -- YANK group
    wk.add({
      { "<leader>y", group = "yank", icon = "󰆏" },
      { "<leader>yh", function() _G.YankyTelescopeHistory() end, desc = "yank history", icon = "󰞋" },
      { "<leader>yc", function() require("yanky").clear_history() end, desc = "clear history", icon = "󰃢" },
    })

    -- Visual mode mappings
    wk.add({
      -- Surround operations
      { "<leader>s", group = "surround", icon = "󰅪", mode = "v" },
      { "<leader>ss", "<Plug>(nvim-surround-visual)", desc = "add surrounding to selection", icon = "󰅪", mode = "v" },
      
      -- AI Help operations that work on selected text
      { "<leader>h", group = "ai help", icon = "󰚩", mode = "v" },
      { "<leader>ha", function() require("neotex.plugins.ai.util.avante_mcp").with_mcp("AvanteAsk") end, desc = "ask about selection", icon = "󰞋", mode = "v" },
      { "<leader>hs", function() require("neotex.plugins.ai.util.avante_mcp").with_mcp("AvanteEdit") end, desc = "edit selection", icon = "󰏫", mode = "v" },
      { "<leader>hc", function() require("neotex.plugins.ai.util.avante_mcp").with_mcp("AvanteChat") end, desc = "chat about selection", icon = "󰻞", mode = "v" },
      { "<leader>hL", "<cmd>LecticSubmitSelection<CR>", desc = "submit selection with message", icon = "󰚟", mode = "v" },
      
      -- Format selected text
      { "<leader>a", group = "actions", icon = "󰌵", mode = "v" },
      { "<leader>af", function() require("conform").format({ async = true, lsp_fallback = true }) end, desc = "format selection", icon = "󰉣", mode = "v" },
      
      -- LSP operations on selection
      { "<leader>i", group = "lsp", icon = "󰅴", mode = "v" },
      { "<leader>ic", "<cmd>lua vim.lsp.buf.code_action()<CR>", desc = "code action", icon = "󰌵", mode = "v" },
      
      -- Git operations on selection
      { "<leader>g", group = "git", icon = "󰊢", mode = "v" },
      { "<leader>gl", "<cmd>Gitsigns blame_line<CR>", desc = "blame selected lines", icon = "󰊢", mode = "v" },
      
      -- Text operations
      { "<leader>x", group = "text", icon = "󰤌", mode = "v" },
      { "<leader>xa", desc = "align selection", icon = "󰉞", mode = "v" },
      { "<leader>xA", desc = "align selection with preview", icon = "󰉞", mode = "v" },
      { "<leader>xs", desc = "split/join selection", icon = "󰤋", mode = "v" },
      
      -- Search operations on selection
      { "<leader>f", group = "find", icon = "󰍉", mode = "v" },
      { "<leader>fs", "<cmd>Telescope grep_string<CR>", desc = "search selection", icon = "󰊄", mode = "v" },
      { "<leader>fw", "<cmd>lua SearchWordUnderCursor()<CR>", desc = "search selection", icon = "󰊄", mode = "v" },
      
      -- Yank operations
      { "<leader>y", group = "yank", icon = "󰆏", mode = "v" },
      { "<leader>yh", function() _G.YankyTelescopeHistory() end, desc = "yank history", icon = "󰞋", mode = "v" },
      
    })
    
    -- Jupyter visual mode mapping (for sending selected text to REPL)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "ipynb", "python" },
      callback = function()
        wk.add({
          { "<leader>jv", "<cmd>lua require('iron.core').visual_send()<CR>", desc = "send selection to REPL", icon = "󰊠", mode = "v", buffer = 0 },
        })
      end,
    })
  end,
}
