# Neovim Keybindings Reference

This document provides a comprehensive overview of all keybindings configured in this Neovim setup, organized by context and functionality.

## 🎯 Filetype-Dependent Mappings

**Important Note**: Many of the leader-based mappings listed below are **filetype-dependent** and only appear when working with relevant file types. This configuration uses a hybrid approach in which-key.nvim to provide context-aware keybindings:

- **LaTeX** (`<leader>l*`): Only available in `.tex`, `.latex`, `.bib`, `.cls`, `.sty` files
- **Jupyter** (`<leader>j*`): Only available in `.ipynb` files  
- **Markdown** (`<leader>m*`): Only available in `.md`, `.markdown` files
- **Pandoc** (`<leader>p*`): Available in convertible formats (markdown, tex, org, rst, html, docx)
- **Templates** (`<leader>T*`): Only available in LaTeX files
- **Python Actions** (`<leader>ap`, `<leader>am`): Only available in `.py` files
- **Lean Actions** (`<leader>al`): Only available in `.lean` files
- **Markdown Actions** (`<leader>ar`): Only available in markdown files

This means you'll only see relevant mappings for your current file type, providing a cleaner and more focused interface.

## Table of Contents

1. [Global Keybindings](#global-keybindings)
2. [Leader-Based Mappings](#leader-based-mappings)
3. [Buffer-Specific Mappings](#buffer-specific-mappings)
4. [Plugin-Specific Mappings](#plugin-specific-mappings)

---

## Global Keybindings

These keybindings are available in all contexts and override default Vim behavior for improved workflow.

### Navigation and Movement

| Key(s) | Mode | Action | Description |
|--------|------|--------|-------------|
| `<Space>` | n | Leader key | Main leader key for command sequences |
| `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>` | n | Window navigation | Navigate between windows |
| `<Tab>` | n | Next buffer | Go to next buffer (by modified time) |
| `<S-Tab>` | n | Previous buffer | Go to previous buffer (by modified time) |
| `<C-u>`, `<C-d>` | n | Scroll with centering | Scroll half-page up/down with cursor centering |
| `<S-h>`, `<S-l>` | n,v | Line navigation | Go to start/end of display line |
| `J`, `K` | n,v | Display line navigation | Navigate display lines (respects wrapping) |
| `<A-Left>`, `<A-Right>`, `<A-h>`, `<A-l>` | n | Window resizing | Resize window horizontally |

### Text Manipulation

| Key(s) | Mode | Action | Description |
|--------|------|--------|-------------|
| `Y` | n,v | Yank to end | Yank from cursor to end of line |
| `E` | n | Previous word end | Go to end of previous word |
| `m` | n,v | Center cursor | Center cursor at top of screen |
| `<A-j>`, `<A-k>` | n,x,v | Move lines | Move current line or selection up/down |
| `<`, `>` | n,v | Indentation | Decrease/increase indentation (preserves selection) |

### Search and File Operations

| Key(s) | Mode | Action | Description |
|--------|------|--------|-------------|
| `<CR>` | n | Clear search | Clear search highlighting |
| `<C-p>` | n | Find files | Find files with Telescope |
| `<C-s>` | n | Spelling suggestions | Show spelling suggestions with Telescope |
| `<S-m>` | n | Help lookup | Show help for word under cursor |
| `<C-m>` | n | Man pages | Search man pages with Telescope |

### Comments and Editing

| Key(s) | Mode | Action | Description |
|--------|------|--------|-------------|
| `<C-;>` | n | Toggle comment | Toggle comments for current line |
| `<C-;>` | v | Toggle comment | Toggle comments for selection |

### Terminal Integration

| Key(s) | Mode | Action | Description |
|--------|------|--------|-------------|
| `<C-t>` | n,t | Toggle terminal | Toggle terminal window |

### Disabled Keys

| Key(s) | Mode | Action | Description |
|--------|------|--------|-------------|
| `<C-z>` | n | Disabled | Prevents accidental suspension |
| `gc`, `gcc` | n | Disabled | Prevents conflict with mini.comment |

---

## Leader-Based Mappings

All leader-based mappings use `<Space>` as the leader key and are organized into logical groups.

### Top-Level Mappings

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>c` | Create vertical split | Split window vertically |
| `<leader>d` | Save and delete buffer | Save file and close buffer |
| `<leader>e` | Toggle NvimTree explorer | Open/close file explorer |
| `<leader>k` | Maximize split | Make current window full screen |
| `<leader>q` | Save all and quit | Save all files and exit Neovim |
| `<leader>u` | Open Telescope undo | Show undo history with preview |
| `<leader>w` | Write all files | Save all open files |

### ACTIONS (`<leader>a`)

**Note**: Some actions are filetype-specific and only appear for relevant files.

| Key | Action | Description | Availability |
|-----|--------|-------------|--------------|
| `<leader>af` | Format buffer | Format current buffer via LSP | All files |
| `<leader>ah` | Toggle local highlight | Highlight current word occurrences | All files |
| `<leader>al` | Toggle Lean info view | Show/hide Lean information panel | `.lean` files only |
| `<leader>am` | Run model checker | Execute model checker on file | `.py` files only |
| `<leader>ap` | Run Python file | Execute current Python file | `.py` files only |
| `<leader>ar` | Recalculate autolist | Fix numbering in lists | `.md` files only |
| `<leader>au` | Update CWD | Change to file's directory | All files |
| `<leader>as` | Edit snippets | Open snippets directory | All files |
| `<leader>aS` | SSH connect | Connect to MIT server via SSH | All files |

### FIND (`<leader>f`)

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>fa` | Find all files | Search all files, including hidden |
| `<leader>fb` | Find buffers | Switch between open buffers |
| `<leader>fc` | Find citations | Search BibTeX citations |
| `<leader>ff` | Find in project | Search text in project files |
| `<leader>fl` | Resume last search | Continue previous search |
| `<leader>fp` | Copy buffer path | Copy current file path to clipboard |
| `<leader>fq` | Find in quickfix | Search within quickfix list |
| `<leader>fg` | Git commit history | Browse git commit history |
| `<leader>fh` | Help tags | Search Neovim help documentation |
| `<leader>fk` | Keymaps | Show all keybindings |
| `<leader>fr` | Registers | Show clipboard registers |
| `<leader>fs` | Search string | Search for string in project |
| `<leader>ft` | Find todos | Search for TODO comments |
| `<leader>fw` | Search word under cursor | Find current word in project |
| `<leader>fy` | Yank history | Browse clipboard history |

### GIT (`<leader>g`)

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>gb` | Checkout branch | Switch to another git branch |
| `<leader>gc` | View commits | Show commit history |
| `<leader>gd` | View diff | Show changes against HEAD |
| `<leader>gg` | Open lazygit | Launch terminal git interface |
| `<leader>gj` | Next hunk | Jump to next change |
| `<leader>gk` | Previous hunk | Jump to previous change |
| `<leader>gl` | Line blame | Show git blame for current line |
| `<leader>gp` | Preview hunk | Preview current change |
| `<leader>gs` | Git status | Show files with changes |
| `<leader>gt` | Toggle blame | Toggle line blame display |

### AI HELP (`<leader>h`)

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>ha` | Ask | Ask Avante AI a question |
| `<leader>hc` | Chat | Start chat with Avante AI |
| `<leader>ht` | Toggle Avante | Show/hide Avante interface |
| `<leader>hs` | Selected edit | Edit selected text with AI |
| `<leader>ho` | Open Claude Code | Toggle Claude Code terminal |
| `<leader>hb` | Add buffer to Claude | Add current file to Claude context |
| `<leader>hr` | Add directory to Claude | Add current directory to Claude context |
| `<leader>hx` | Open MCP Hub | Access MCP Hub interface |
| `<leader>hd` | Set model & provider | Change AI model with defaults |
| `<leader>he` | Edit prompts | Open system prompt manager |
| `<leader>hi` | Interrupt | Stop AI generation |
| `<leader>hk` | Clear | Clear Avante chat/content |
| `<leader>hm` | Select model | Choose AI model for current provider |
| `<leader>hp` | Select prompt | Choose system prompt |
| `<leader>hf` | Refresh | Reload AI assistant |

### LSP & LINT (`<leader>i`)

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>ib` | Buffer diagnostics | Show all errors in current file |
| `<leader>ic` | Code action | Show available code actions |
| `<leader>id` | Go to definition | Jump to symbol definition |
| `<leader>iD` | Go to declaration | Jump to symbol declaration |
| `<leader>ih` | Hover help | Show documentation under cursor |
| `<leader>ii` | Implementations | Find implementations of symbol |
| `<leader>il` | Line diagnostics | Show errors for current line |
| `<leader>in` | Next diagnostic | Go to next error/warning |
| `<leader>ip` | Previous diagnostic | Go to previous error/warning |
| `<leader>ir` | References | Find all references to symbol |
| `<leader>is` | Restart LSP | Restart language server |
| `<leader>it` | Toggle LSP | Start/stop language server |
| `<leader>iy` | Copy diagnostics | Copy diagnostics to clipboard |
| `<leader>iR` | Rename | Rename symbol under cursor |
| `<leader>iL` | Lint file | Run linters on current file |
| `<leader>ig` | Toggle global linting | Enable/disable linting globally |
| `<leader>iB` | Toggle buffer linting | Enable/disable linting for buffer |

### JUPYTER (`<leader>j`)

**Availability**: Only available in `.ipynb` files.

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>je` | Execute cell | Run current notebook cell |
| `<leader>jj` | Next cell | Navigate to next cell |
| `<leader>jk` | Previous cell | Navigate to previous cell |
| `<leader>jn` | Execute and next | Run cell and move to next |
| `<leader>jo` | Insert cell below | Add new cell below current |
| `<leader>jO` | Insert cell above | Add new cell above current |
| `<leader>js` | Split cell | Split current cell at cursor |
| `<leader>jc` | Comment cell | Comment out current cell |
| `<leader>ja` | Run all cells | Execute all notebook cells |
| `<leader>jb` | Run cells below | Run notebook cells below cursor |
| `<leader>ju` | Merge with cell above | Join current cell with cell above |
| `<leader>jd` | Merge with cell below | Join current cell with cell below |
| `<leader>ji` | Start IPython REPL | Start Python interactive shell |
| `<leader>jt` | Send motion to REPL | Send text via motion to REPL |
| `<leader>jl` | Send line to REPL | Send current line to REPL |
| `<leader>jf` | Send file to REPL | Send entire file to REPL |
| `<leader>jq` | Exit REPL | Close the REPL |
| `<leader>jr` | Clear REPL | Clear the REPL screen |
| `<leader>jv` | Send visual selection to REPL | Send selected text to REPL |

### LATEX (`<leader>l`)

**Availability**: Only available in `.tex`, `.latex`, `.bib`, `.cls`, `.sty` files.

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>la` | PDF annotations | Work with PDF annotations |
| `<leader>lb` | Export bibliography | Export BibTeX to separate file |
| `<leader>lc` | Compile LaTeX document | Build/compile current document |
| `<leader>le` | Show VimTeX errors | Display LaTeX error messages |
| `<leader>lf` | Format tex file | Format LaTeX using latexindent |
| `<leader>lg` | Edit glossary | Open LaTeX glossary template |
| `<leader>li` | Open LaTeX table of contents | Show document structure |
| `<leader>lk` | Clean VimTeX aux files | Remove LaTeX auxiliary files |
| `<leader>lm` | VimTeX context menu | Show VimTeX context actions |
| `<leader>lv` | View compiled LaTeX document | Preview PDF output |
| `<leader>lw` | Count words | Count words in LaTeX document |
| `<leader>lx` | Clear VimTeX cache | Clear LaTeX compilation cache |

### MARKDOWN (`<leader>m`)

**Availability**: Only available in `.md`, `.markdown` files.

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>ml` | Run Lectic | Run Lectic on current file |
| `<leader>mn` | New Lectic file | Create new Lectic file with template |
| `<leader>ms` | Submit selection | Submit visual selection with user message |
| `<leader>mp` | Format buffer | Format code with conform.nvim |
| `<leader>mu` | Open URL | Open URL under cursor |
| `<leader>ma` | Toggle all folds | Toggle all folds open/closed |
| `<leader>mf` | Toggle fold | Toggle fold under cursor |
| `<leader>mt` | Toggle folding method | Switch between manual/smart folding |

### NIXOS (`<leader>n`)

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>nd` | Nix develop | Enter nix development shell |
| `<leader>nf` | Rebuild flake | Rebuild system from flake |
| `<leader>ng` | Garbage collection | Clean up old nix packages (15d) |
| `<leader>np` | Browse packages | Open nixOS packages website |
| `<leader>nm` | MyNixOS | Open MyNixOS website |
| `<leader>nh` | Home-manager switch | Apply home-manager changes |
| `<leader>nr` | Rebuild nix | Run update.sh script |
| `<leader>nu` | Update flake | Update flake dependencies |

### PANDOC (`<leader>p`)

**Availability**: Available in convertible formats (`.md`, `.markdown`, `.tex`, `.latex`, `.org`, `.rst`, `.html`, `.docx`).

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>pw` | Convert to Word | Convert to .docx format |
| `<leader>pm` | Convert to Markdown | Convert to .md format |
| `<leader>ph` | Convert to HTML | Convert to .html format |
| `<leader>pl` | Convert to LaTeX | Convert to .tex format |
| `<leader>pp` | Convert to PDF | Convert to .pdf format |
| `<leader>pv` | View PDF | Open PDF in document viewer |

### RUN (`<leader>r`)

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>rc` | Clear plugin cache | Clear Neovim plugin cache |
| `<leader>re` | Show linter errors | Display all errors in floating window |
| `<leader>rk` | Wipe plugins and lock file | Remove all plugin files AND lazy-lock.json |
| `<leader>rn` | Next error | Go to next diagnostic/error |
| `<leader>rp` | Previous error | Go to previous diagnostic/error |
| `<leader>rr` | Reload configs | Reload Neovim configuration |
| `<leader>rm` | Show messages | Display notification history |

### SESSIONS (`<leader>S`)

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>Ss` | Save session | Save current session |
| `<leader>Sd` | Delete session | Delete a saved session |
| `<leader>Sl` | Load session | Load a saved session |

### SURROUND (`<leader>s`)

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>ss` | Add surrounding | Add surrounding to text (requires motion) |
| `<leader>sd` | Delete surrounding | Remove surrounding characters |
| `<leader>sc` | Change surrounding | Replace surrounding characters |

### TODO (`<leader>t`)

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>tt` | Todo telescope | Find all TODOs in project |
| `<leader>tn` | Next todo | Jump to next TODO comment |
| `<leader>tp` | Previous todo | Jump to previous TODO comment |
| `<leader>tl` | Todo location list | Show TODOs in location list |
| `<leader>tq` | Todo quickfix | Show TODOs in quickfix list |

### TEMPLATES (`<leader>T`)

**Availability**: Only available in `.tex`, `.latex` files.

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>Ta` | Article.tex | Insert article template |
| `<leader>Tb` | Beamer_slides.tex | Insert beamer presentation template |
| `<leader>Tg` | Glossary.tex | Insert glossary template |
| `<leader>Th` | Handout.tex | Insert handout template |
| `<leader>Tl` | Letter.tex | Insert letter template |
| `<leader>Tm` | MultipleAnswer.tex | Insert multiple answer template |
| `<leader>Tr` | Copy report/ directory | Copy report template directory |
| `<leader>Ts` | Copy springer/ directory | Copy springer template directory |

### TEXT (`<leader>x`)

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>xa` | Align | Start text alignment |
| `<leader>xA` | Align with preview | Start alignment with preview |
| `<leader>xs` | Split/join toggle | Toggle between single/multi-line |
| `<leader>xd` | Toggle diff overlay | Show diff between buffer and clipboard |
| `<leader>xw` | Toggle word diff | Show word-level diffs |

### YANK (`<leader>y`)

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>yh` | Yank history | Browse clipboard history with Telescope |
| `<leader>yc` | Clear history | Clear the yank history |

### Visual Mode Mappings

| Key | Mode | Action | Description |
|-----|------|--------|-------------|
| `<leader>ss` | v | Add surrounding to selection | Surround selected text |

---

## Buffer-Specific Mappings

These keybindings are automatically applied when specific buffer types are detected.

### Terminal Mode

Active in terminal buffers (`:terminal` command or toggleterm).

| Key | Action | Description |
|-----|--------|-------------|
| `<Esc>` | Exit terminal mode | Switch from terminal to normal mode |
| `<C-t>` | Toggle terminal | Close/open terminal window |
| `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>` | Navigate windows | Move between terminal and other windows |
| `<C-a>` | Ask Avante | Ask Avante AI a question (non-lazygit only) |
| `<M-h>`, `<M-l>`, `<M-Left>`, `<M-Right>` | Resize terminal | Adjust terminal window width |

### Markdown Buffers

Active in markdown files (`.md`, `.markdown` extensions).

| Key | Mode | Action | Description |
|-----|------|--------|-------------|
| `<CR>` | i | Smart bullet creation | Create new bullet point |
| `o` | n | New bullet below | Create bullet point below cursor |
| `O` | n | New bullet above | Create bullet point above cursor |
| `<Tab>` | i | Smart indent | Indent bullet and recalculate numbers |
| `<S-Tab>` | i | Smart unindent | Unindent bullet and recalculate numbers |
| `dd` | n | Delete and recalculate | Delete line and fix list numbering |
| `d` | v | Delete and recalculate | Delete selection and fix numbering |
| `<C-n>` | n | Toggle checkbox | Cycle checkbox status ([ ] � [x]) |
| `<C-c>` | n | Recalculate list | Fix all list numbering |
| `>`, `<` | n | Indent/unindent | Adjust bullet indentation with recalculation |

### Avante AI Buffers

Active in Avante AI interface buffers.

| Key | Mode | Action | Description |
|-----|------|--------|-------------|
| `<C-t>` | n,i | Toggle Avante | Show/hide Avante interface |
| `q` | n | Toggle Avante | Quick exit from Avante |
| `<C-c>` | n,i | Clear chat | Reset/clear Avante content |
| `<C-m>` | n,i | Select model | Choose model for current provider |
| `<C-s>` | n,i | Select provider | Choose provider and model |
| `<C-x>` | n,i | Stop generation | Interrupt AI generation |
| `<CR>` | i | New line | Prevent accidental submission |

---

## Plugin-Specific Mappings

### Yanky (Clipboard Management)

| Key | Mode | Action | Description |
|-----|------|--------|-------------|
| `y` | n,x | Enhanced yank | Yank with history tracking |
| `p` | n | Enhanced paste after | Paste after cursor with formatting |
| `P` | n | Enhanced paste before | Paste before cursor with formatting |
| `gp` | n | Paste and position | Paste after and leave cursor after text |
| `gP` | n | Paste and position | Paste before and leave cursor after text |

### TODO Comments

| Key | Mode | Action | Description |
|-----|------|--------|-------------|
| `]t` | n | Next todo | Jump to next TODO comment |
| `[t` | n | Previous todo | Jump to previous TODO comment |

---

## Notes

1. **Leader Key**: The leader key is set to `<Space>` (spacebar) for easy access.

2. **Mode Abbreviations**:
   - `n` = Normal mode
   - `i` = Insert mode  
   - `v` = Visual mode
   - `x` = Visual block mode
   - `t` = Terminal mode

3. **Buffer-Specific Mappings**: Many mappings are automatically applied based on file type or buffer context. These are managed by autocmds in the configuration.

4. **Plugin Dependencies**: Some mappings require specific plugins to be loaded. If a plugin fails to load, fallback mappings may be used.

5. **Customization**: All mappings can be customized by editing the corresponding configuration files:
   - Global mappings: `lua/neotex/config/keymaps.lua`
   - Leader mappings: `lua/neotex/plugins/editor/which-key.lua`
   - Plugin-specific mappings: Individual plugin configuration files

## Navigation

- [Main Configuration ←](../README.md)
- [Installation Guide ←](INSTALLATION.md)

For more information about the overall configuration structure, see the main [README](../README.md).