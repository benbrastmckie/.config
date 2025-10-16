# Which-Key Configuration Overview

## Icon Alternatives

### Current Icons
| Category | Current Icon | Description |
|----------|--------------|-------------|
| Create Split | `󰁪` | Current split icon |
| LSP | `󰒕` | Current language server icon |
| Markdown | `󱀈` | Current markdown icon |
| LaTeX | `󰐺` | Current LaTeX icon |
| Jupyter | `󰌠` | Current Jupyter icon |
| Text | `󰊪` | Current text icon |

### Desired Icons
| Category | Current Icon | Description |
|----------|--------------|-------------|
| Create Split | `󰯌` | Current split icon |
| LSP | `󰅴` | Current language server icon |
| Markdown | `` | Current markdown icon |
| LaTeX | `󰙩` | Current LaTeX icon |
| Jupyter | `󰌠` | Current Jupyter icon |
| Text | `󰤌` | Current text icon |


## Current State Analysis

### Top-Level Mappings (`<leader>`)
| Key | Command | Description |
|-----|---------|-------------|
| `b` | `VimtexCompile` | Compile LaTeX document |
| `c` | `vert sb` | Create vertical split |
| `d` | `update! \| lua Snacks.bufdelete()` | Save and delete buffer |
| `e` | `Neotree toggle` | Toggle NvimTree explorer |
| `i` | `VimtexTocOpen` | Open LaTeX table of contents |
| `k` | `on` | Maximize split |
| `q` | `wa! \| qa!` | Save all and quit |
| `u` | `Telescope undo` | Open Telescope undo |
| `v` | `VimtexView` | View compiled LaTeX document |
| `w` | `wa!` | Write all files |

### Current Groups

#### ACTIONS (`<leader>a`)
| Key | Command | Description |
|-----|---------|-------------|
| `aa` | `lua PdfAnnots()` | PDF annotations |
| `ab` | `terminal bibexport -o %:p:r.bib %:p:r.aux` | Export bibliography |
| `ac` | `VimtexClearCache All` | Clear VimTeX cache |
| `ae` | `VimtexErrors` | Show VimTeX errors |
| `af` | `lua vim.lsp.buf.format()` | Format buffer |
| `ag` | `e ~/.config/nvim/templates/Glossary.tex` | Edit glossary |
| `ah` | `LocalHighlightToggle` | Toggle local highlight |
| `ak` | `VimtexClean` | Clean VimTeX aux files |
| `al` | `LeanInfoviewToggle` | Toggle Lean info view |
| `am` | `TermExec cmd='./Code/dev_cli.py %:p:r.py'` | Run model checker |
| `ap` | `TermExec cmd='python %:p:r.py'` | Run Python file |
| `ar` | `AutolistRecalculate` | Recalculate autolist |
| `at` | `terminal latexindent -w %:p:r.tex` | Format tex file |
| `au` | `cd %:p:h \| Neotree reveal` | Update CWD |
| `av` | `<plug>(vimtex-context-menu)` | VimTeX context menu |
| `aw` | `VimtexCountWords!` | Count words |
| `as` | `Neotree ~/.config/nvim/snippets/` | Edit snippets |
| `aS` | `TermExec cmd='ssh brastmck@eofe10.mit.edu'` | SSH connect |

#### FIND (`<leader>f`)
| Key | Command | Description |
|-----|---------|-------------|
| `fa` | `telescope find_files (all)` | Find all files |
| `fb` | `telescope buffers` | Find buffers |
| `fc` | `Telescope bibtex` | Find citations |
| `ff` | `Telescope live_grep` | Find in project |
| `fl` | `Telescope resume` | Resume last search |
| `fp` | `copy_buffer_path()` | Copy buffer path |
| `fq` | `Telescope quickfix` | Find in quickfix |
| `fg` | `Telescope git_commits` | Git commit history |
| `fh` | `Telescope help_tags` | Help tags |
| `fk` | `Telescope keymaps` | Keymaps |
| `fr` | `Telescope registers` | Registers |
| `ft` | `TodoTelescope` | Find todos |
| `fs` | `Telescope grep_string` | Search string |
| `fw` | `SearchWordUnderCursor()` | Search word under cursor |
| `fy` | `telescope yank_history` | Yank history |

#### GIT (`<leader>g`)
| Key | Command | Description |
|-----|---------|-------------|
| `gb` | `Telescope git_branches` | Checkout branch |
| `gc` | `Telescope git_commits` | View commits |
| `gd` | `Gitsigns diffthis HEAD` | View diff |
| `gg` | `safe_lazygit()` | Open lazygit |
| `gk` | `Gitsigns prev_hunk` | Previous hunk |
| `gj` | `Gitsigns next_hunk` | Next hunk |
| `gl` | `Gitsigns blame_line` | Line blame |
| `gp` | `Gitsigns preview_hunk` | Preview hunk |
| `gs` | `Telescope git_status` | Git status |
| `gt` | `Gitsigns toggle_current_line_blame` | Toggle blame |

#### AI HELP (`<leader>h`)
| Key | Command | Description |
|-----|---------|-------------|
| `ha` | `avante_mcp AvanteAsk` | Ask |
| `hc` | `avante_mcp AvanteChat` | Chat |
| `ht` | `avante_mcp AvanteToggle` | Toggle avante |
| `hs` | `avante_mcp AvanteEdit` | Selected edit |
| `ho` | `ClaudeCode` | Open claude code |
| `hb` | `ClaudeCodeAddBuffer` | Add buffer to claude |
| `hr` | `ClaudeCodeAddDir` | Add directory to claude |
| `hx` | `MCPHubOpen` | Open mcp hub |
| `hd` | `AvanteProvider` | Set model & provider |
| `he` | `AvantePromptManager` | Edit prompts |
| `hi` | `AvanteStop` | Interrupt |
| `hk` | `AvanteClear` | Clear |
| `hm` | `AvanteModel` | Select model |
| `hp` | `AvantePrompt` | Select prompt |
| `hf` | `AvanteRefresh` | Refresh |

#### JUPYTER (`<leader>j`)
| Key | Command | Description |
|-----|---------|-------------|
| `je` | `notebook-navigator run_cell` | Execute cell |
| `jj` | `notebook-navigator move_cell('d')` | Next cell |
| `jk` | `notebook-navigator move_cell('u')` | Previous cell |
| `jn` | `notebook-navigator run_and_move` | Execute and next |
| `jo` | `add_jupyter_cell_with_closing` | Insert cell below |
| `jO` | `notebook-navigator add_cell_above` | Insert cell above |
| `js` | `notebook-navigator split_cell` | Split cell |
| `jc` | `notebook-navigator comment_cell` | Comment cell |
| `ja` | `notebook-navigator run_all_cells` | Run all cells |
| `jb` | `notebook-navigator run_cells_below` | Run cells below |
| `ju` | `notebook-navigator merge_cell('u')` | Merge with cell above |
| `jd` | `notebook-navigator merge_cell('d')` | Merge with cell below |
| `ji` | `iron repl_for('python')` | Start IPython REPL |
| `jt` | `iron run_motion('send_motion')` | Send motion to REPL |
| `jl` | `iron send_line` | Send line to REPL |
| `jf` | `iron send file` | Send file to REPL |
| `jq` | `iron close_repl` | Exit REPL |
| `jr` | `iron send clear` | Clear REPL |
| `jv` | `iron visual_send` | Send visual selection to REPL |

#### LIST (`<leader>L`) - COMMENTED OUT
| Key | Command | Description |
|-----|---------|-------------|
| `Lc` | `IncrementCheckbox()` | Increment checkbox |
| `Ld` | `DecrementCheckbox()` | Decrement checkbox |
| `Ln` | `AutolistCycleNext` | Next |
| `Lp` | `AutolistCyclePrev` | Previous |
| `Lr` | `AutolistRecalculate` | Reorder |

#### LSP & LINT (`<leader>l`)
| Key | Command | Description |
|-----|---------|-------------|
| `lb` | `Telescope diagnostics bufnr=0` | Buffer diagnostics |
| `lc` | `vim.lsp.buf.code_action` | Code action |
| `ld` | `Telescope lsp_definitions` | Definition |
| `lD` | `vim.lsp.buf.declaration` | Declaration |
| `lh` | `vim.lsp.buf.hover` | Help |
| `li` | `Telescope lsp_implementations` | Implementations |
| `lk` | `LspStop` | Kill LSP |
| `ll` | `vim.diagnostic.open_float` | Line diagnostics |
| `ln` | `vim.diagnostic.goto_next` | Next diagnostic |
| `lp` | `vim.diagnostic.goto_prev` | Previous diagnostic |
| `lr` | `Telescope lsp_references` | References |
| `ls` | `LspRestart` | Restart LSP |
| `lt` | `LspStart` | Start LSP |
| `ly` | `CopyDiagnosticsToClipboard()` | Copy diagnostics |
| `lR` | `vim.lsp.buf.rename` | Rename |
| `lL` | `require("lint").try_lint` | Lint file |
| `lg` | `LintToggle` | Toggle global linting |
| `lB` | `LintToggle buffer` | Toggle buffer linting |

#### MARKDOWN (`<leader>m`)
| Key | Command | Description |
|-----|---------|-------------|
| `ml` | `Lectic` | Run lectic on file |
| `mn` | `LecticCreateFile` | New lectic file |
| `ms` | `LecticSubmitSelection` | Submit selection with message |
| `mp` | `conform.format` | Format buffer |
| `mu` | `OpenUrlUnderCursor()` | Open URL under cursor |
| `ma` | `ToggleAllFolds()` | Toggle all folds |
| `mf` | `za` | Toggle fold under cursor |
| `mt` | `ToggleFoldingMethod()` | Toggle folding method |

#### SESSIONS (`<leader>S`)
| Key | Command | Description |
|-----|---------|-------------|
| `Ss` | `SessionManager save_current_session` | Save |
| `Sd` | `SessionManager delete_session` | Delete |
| `Sl` | `SessionManager load_session` | Load |

#### NIXOS (`<leader>n`)
| Key | Command | Description |
|-----|---------|-------------|
| `nd` | `TermExec cmd='nix develop'` | Develop |
| `nf` | `TermExec cmd='sudo nixos-rebuild switch --flake ~/.dotfiles/'` | Rebuild flake |
| `ng` | `TermExec cmd='nix-collect-garbage --delete-older-than 15d'` | Garbage |
| `np` | `TermExec cmd='brave https://search.nixos.org/packages'` | Packages |
| `nm` | `TermExec cmd='brave https://mynixos.com'` | My-nixos |
| `nh` | `TermExec cmd='home-manager switch --flake ~/.dotfiles/'` | Home-manager |
| `nr` | `TermExec cmd='~/.dotfiles/update.sh'` | Rebuild nix |
| `nu` | `TermExec cmd='nix flake update'` | Update |

#### PANDOC (`<leader>p`)
| Key | Command | Description |
|-----|---------|-------------|
| `pw` | `TermExec cmd='pandoc %:p -o %:p:r.docx'` | Word |
| `pm` | `TermExec cmd='pandoc %:p -o %:p:r.md'` | Markdown |
| `ph` | `TermExec cmd='pandoc %:p -o %:p:r.html'` | HTML |
| `pl` | `TermExec cmd='pandoc %:p -o %:p:r.tex'` | LaTeX |
| `pp` | `TermExec cmd='pandoc %:p -o %:p:r.pdf'` | PDF |
| `pv` | `TermExec cmd='sioyek %:p:r.pdf &'` | View |

#### RUN (`<leader>r`)
| Key | Command | Description |
|-----|---------|-------------|
| `rc` | `TermExec cmd='rm -rf ~/.cache/nvim'` | Clear plugin cache |
| `re` | `show_all_errors()` | Show linter errors |
| `rk` | `TermExec cmd='rm -rf ~/.local/share/nvim/lazy && rm -f ~/.config/nvim/lazy-lock.json'` | Wipe plugins and lock file |
| `rn` | `vim.diagnostic.goto_next` | Next |
| `rp` | `vim.diagnostic.goto_prev` | Prev |
| `rr` | `ReloadConfig` | Reload configs |
| `rm` | `Snacks.notifier.show_history()` | Show messages |

#### SURROUND (`<leader>s`)
| Key | Command | Description |
|-----|---------|-------------|
| `ss` | `<Plug>(nvim-surround-normal)` | Surround |
| `sd` | `<Plug>(nvim-surround-delete)` | Delete |
| `sc` | `<Plug>(nvim-surround-change)` | Change |

#### TEMPLATES (`<leader>t`)
| Key | Command | Description |
|-----|---------|-------------|
| `ta` | `read ~/.config/nvim/templates/article.tex` | Article.tex |
| `tb` | `read ~/.config/nvim/templates/beamer_slides.tex` | Beamer_slides.tex |
| `tg` | `read ~/.config/nvim/templates/glossary.tex` | Glossary.tex |
| `th` | `read ~/.config/nvim/templates/handout.tex` | Handout.tex |
| `tl` | `read ~/.config/nvim/templates/letter.tex` | Letter.tex |
| `tm` | `read ~/.config/nvim/templates/MultipleAnswer.tex` | MultipleAnswer.tex |
| `tr` | `copy report/ directory` | Copy report/ directory |
| `ts` | `copy springer/ directory` | Copy springer/ directory |

#### TODO (`<leader>T`)
| Key | Command | Description |
|-----|---------|-------------|
| `Tt` | `TodoTelescope` | Find all TODOs in project |
| `Tn` | `todo-comments jump_next` | Jump to next TODO comment |
| `Tp` | `todo-comments jump_prev` | Jump to previous TODO comment |
| `Tl` | `TodoLocList` | Show TODOs in location list |
| `Tq` | `TodoQuickFix` | Show TODOs in quickfix list |

#### TEXT (`<leader>x`)
| Key | Command | Description |
|-----|---------|-------------|
| `xa` | Text alignment | Align |
| `xA` | Text alignment with preview | Align with preview |
| `xs` | Split/join toggle | Split/join toggle |
| `xd` | Toggle diff overlay | Toggle diff overlay |
| `xw` | Toggle word diff | Toggle word diff |

#### YANK (`<leader>y`)
| Key | Command | Description |
|-----|---------|-------------|
| `yh` | `telescope yank_history` | Yank history |
| `yc` | Clear yank history | Clear history |

---

## Proposed Refactor Plan

### Key Changes

1. **Move LSP & LINT group from `<leader>l` to `<leader>i`** (intellisense/IDE features)
2. **Create new LATEX group under `<leader>l`** (consolidate all VimTeX commands)
3. **Remove VimTeX commands from top-level and ACTIONS group**
4. **Clean up ACTIONS group** (keep non-LaTeX commands)

### New LATEX Group (`<leader>l`)

| Key | Command | Description | Source |
|-----|---------|-------------|---------|
| `la` | `lua PdfAnnots()` | PDF annotations | From `aa` |
| `lb` | `terminal bibexport -o %:p:r.bib %:p:r.aux` | Export bibliography | From `ab` |
| `lc` | `VimtexCompile` | Compile LaTeX document | From top-level `b` |
| `le` | `VimtexErrors` | Show VimTeX errors | From `ae` |
| `lf` | `terminal latexindent -w %:p:r.tex` | Format tex file | From `at` |
| `lg` | `e ~/.config/nvim/templates/glossary.tex` | Edit glossary | From `ag` |
| `li` | `VimtexTocOpen` | Open LaTeX table of contents | From top-level `i` |
| `lk` | `VimtexClean` | Clean VimTeX aux files | From `ak` |
| `lm` | `<plug>(vimtex-context-menu)` | VimTeX context menu | From `av` |
| `lv` | `VimtexView` | View compiled LaTeX document | From top-level `v` |
| `lw` | `VimtexCountWords!` | Count words | From `aw` |
| `lx` | `VimtexClearCache All` | Clear VimTeX cache | From `ac` |

### New LSP & LINT Group (`<leader>i`)

All current `<leader>l` mappings move to `<leader>i` with same sub-keys:

| Key | Command | Description |
|-----|---------|-------------|
| `ib` | `Telescope diagnostics bufnr=0` | Buffer diagnostics |
| `ic` | `vim.lsp.buf.code_action` | Code action |
| `id` | `Telescope lsp_definitions` | Definition |
| `iD` | `vim.lsp.buf.declaration` | Declaration |
| `ih` | `vim.lsp.buf.hover` | Help |
| `ii` | `Telescope lsp_implementations` | Implementations |
| `ik` | `LspStop` | Kill LSP |
| `il` | `vim.diagnostic.open_float` | Line diagnostics |
| `in` | `vim.diagnostic.goto_next` | Next diagnostic |
| `ip` | `vim.diagnostic.goto_prev` | Previous diagnostic |
| `ir` | `Telescope lsp_references` | References |
| `is` | `LspRestart` | Restart LSP |
| `it` | `LspStart` | Start LSP |
| `iy` | `CopyDiagnosticsToClipboard()` | Copy diagnostics |
| `iR` | `vim.lsp.buf.rename` | Rename |
| `iL` | `require("lint").try_lint` | Lint file |
| `ig` | `LintToggle` | Toggle global linting |
| `iB` | `LintToggle buffer` | Toggle buffer linting |

### Updated ACTIONS Group (`<leader>a`)

Remove all VimTeX-related commands, keep:

| Key | Command | Description |
|-----|---------|-------------|
| `af` | `lua vim.lsp.buf.format()` | Format buffer |
| `ah` | `LocalHighlightToggle` | Toggle local highlight |
| `al` | `LeanInfoviewToggle` | Toggle Lean info view |
| `am` | `TermExec cmd='./Code/dev_cli.py %:p:r.py'` | Run model checker |
| `ap` | `TermExec cmd='python %:p:r.py'` | Run Python file |
| `ar` | `AutolistRecalculate` | Recalculate autolist |
| `au` | `cd %:p:h \| Neotree reveal` | Update CWD |
| `as` | `Neotree ~/.config/nvim/snippets/` | Edit snippets |
| `aS` | `TermExec cmd='ssh brastmck@eofe10.mit.edu'` | SSH connect |

### Free Top-Level Keys

The following top-level keys become available:
- `<leader>b` (was VimtexCompile)
- `<leader>i` (was VimtexTocOpen) 
- `<leader>v` (was VimtexView)

### Benefits

1. **Logical grouping**: All LaTeX functionality under one intuitive key (`<leader>l`)
2. **Consistency**: LSP/IDE features grouped under `<leader>i` (intellisense)
3. **Muscle memory**: Common LaTeX operations have memorable keys (`lc` = compile, `lv` = view, `li` = index)
4. **Reduced cognitive load**: No need to remember whether a LaTeX command is top-level or in ACTIONS
5. **Available keys**: Frees up top-level keys for other common operations

---

## Modernization Plan

### Current Configuration Issues

The existing configuration uses which-key.nvim's older v2 API with several problematic approaches:
1. **Outdated API**: Uses `wk.register()` instead of modern `wk.add()`
2. **Icon Monkey-patching**: Complex custom icon system that overrides internal functions
3. **Maintenance burden**: Hard-to-read nested configuration structure
4. **Future compatibility**: Uses deprecated patterns that may break in future updates

### Which-Key v3 Modern API

#### Key Features:
- **Simplified syntax**: `wk.add()` with inline group definitions
- **Built-in icon support**: Proper icon configuration without hacks
- **Better maintainability**: Cleaner, more readable configuration
- **Future-proof**: Uses current API that will be maintained

#### Modern Configuration Structure:
```lua
local wk = require("which-key")

-- Setup with modern options
wk.setup({
  preset = "classic",
  delay = 200,
  win = {
    border = "rounded",
    padding = { 1, 2 }
  },
  icons = {
    breadcrumb = "»",
    separator = "➜", 
    group = "+"
  }
})

-- Add mappings with groups and icons
wk.add({
  -- LaTeX group
  { "<leader>l", group = "latex", icon = "󰐺" },
  { "<leader>lc", "<cmd>VimtexCompile<CR>", desc = "compile", icon = "󰖷" },
  { "<leader>lv", "<cmd>VimtexView<CR>", desc = "view", icon = "󰛓" },
  
  -- LSP group
  { "<leader>i", group = "lsp", icon = "󰒕" },
  { "<leader>ic", vim.lsp.buf.code_action, desc = "code action", icon = "󰌵" },
  { "<leader>id", "<cmd>Telescope lsp_definitions<CR>", desc = "definition", icon = "󰳦" },
})
```

### Proposed Icon Strategy

#### Group Icons:
```lua
local group_icons = {
  -- Primary groups
  latex = "󰐺",       -- LaTeX document
  lsp = "󰒕",         -- Language server
  find = "󰍉",        -- Search/telescope
  git = "󰊢",         -- Git branch
  jupyter = "󰌠",      -- Jupyter logo
  markdown = "󱀈",     -- Markdown
  nixos = "󱄅",       -- NixOS logo
  pandoc = "󰈙",      -- Document conversion
  sessions = "󰆔",     -- Session/project
  surround = "󰅪",     -- Surround text
  templates = "󰈭",    -- Template files
  text = "󰊪",        -- Text operations
  yank = "󰆏",        -- Clipboard
  actions = "󰌵",     -- General actions
  run = "󰐊",         -- Execute/run
  ai = "󰚩",          -- AI assistance
}
```

#### Individual Command Icons:
```lua
local command_icons = {
  -- LaTeX commands
  compile = "󰖷",     -- Build/compile
  view = "󰛓",       -- Preview/view
  clean = "󰩺",      -- Clean/delete
  format = "󰉣",     -- Format code
  errors = "󰅚",     -- Error list
  index = "󰋽",      -- Table of contents
  annotate = "󰏪",   -- Annotations
  export = "󰈝",     -- Export file
  glossary = "󰈚",   -- Glossary/dictionary
  
  -- LSP commands  
  definition = "󰳦", -- Go to definition
  references = "󰌹", -- Find references
  hover = "󰞋",      -- Documentation
  rename = "󰑕",     -- Rename symbol
  diagnostic = "󰒓", -- Diagnostics
  
  -- Common actions
  save = "󰆓",       -- Save file
  quit = "󰗼",       -- Exit
  split = "󰁪",      -- Split window
  explorer = "󰙅",   -- File explorer
  undo = "󰕌",       -- Undo history
}
```

### Implementation Plan

#### Phase 1: Update Configuration Structure
1. **Replace wk.register() with wk.add()**
2. **Remove custom icon monkey-patching**
3. **Simplify setup configuration**
4. **Use inline group definitions**

#### Phase 2: Implement Refactor with Modern API
1. **Create new LATEX group** (`<leader>l`) with LaTeX icon
2. **Move LSP group** (`<leader>l` → `<leader>i`) with LSP icon
3. **Clean up ACTIONS group** (remove LaTeX commands)
4. **Add appropriate icons** for all groups and commands

#### Phase 3: Verify and Test
1. **Test all key bindings** work correctly
2. **Verify icons display** properly
3. **Ensure no regressions** in functionality
4. **Update documentation** comments

### Benefits of Modernization

1. **Cleaner Codebase**: Remove complex icon monkey-patching
2. **Better Performance**: Use optimized modern API
3. **Easier Maintenance**: Clear, readable configuration structure  
4. **Proper Icon Support**: Built-in icon system instead of hacks
5. **Future-Proof**: Uses current API with ongoing support
6. **Enhanced UX**: Better visual distinction with semantic icons
7. **Reduced Complexity**: Simpler mental model for configuration

### Modern Configuration Preview

The final configuration will look like:

```lua
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "classic",
    delay = 200,
    win = {
      border = "rounded", 
      padding = { 1, 2 }
    }
  },
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)
    
    -- Top-level mappings
    wk.add({
      { "<leader>c", "<cmd>vert sb<CR>", desc = "create split", icon = "󰁪" },
      { "<leader>d", "<cmd>update! | lua Snacks.bufdelete()<CR>", desc = "delete buffer", icon = "󰩺" },
      { "<leader>e", "<cmd>Neotree toggle<CR>", desc = "explorer", icon = "󰙅" },
      -- ... etc
    })
    
    -- Groups with reorganized structure
    wk.add({
      -- LaTeX group (NEW)
      { "<leader>l", group = "latex", icon = "󰐺" },
      { "<leader>lc", "<cmd>VimtexCompile<CR>", desc = "compile", icon = "󰖷" },
      { "<leader>lv", "<cmd>VimtexView<CR>", desc = "view", icon = "󰛓" },
      -- ... all LaTeX commands
      
      -- LSP group (MOVED from <leader>l)
      { "<leader>i", group = "lsp", icon = "󰒕" },
      { "<leader>ic", vim.lsp.buf.code_action, desc = "code action", icon = "󰌵" },
      { "<leader>id", "<cmd>Telescope lsp_definitions<CR>", desc = "definition", icon = "󰳦" },
      -- ... all LSP commands
      
      -- Cleaned ACTIONS group
      { "<leader>a", group = "actions", icon = "󰌵" },
      { "<leader>af", vim.lsp.buf.format, desc = "format", icon = "󰉣" },
      { "<leader>ah", "<cmd>LocalHighlightToggle<CR>", desc = "highlight", icon = "󰠷" },
      -- ... remaining non-LaTeX actions
    })
  end
}
```

This approach provides a clean, maintainable, and future-proof configuration that takes full advantage of which-key.nvim's modern capabilities.
