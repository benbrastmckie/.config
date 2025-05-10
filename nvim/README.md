# NeoVim Configuration and CheatSheet

A feature-rich Neovim configuration optimized for LaTeX, Markdown, AI integration, and NixOS.
This setup provides a streamlined environment for academic writing, code development, and system management.
The AI integration makes it easy to learn and configure for your specific needs.

## Features Overview

This Neovim configuration includes specialized support for:

- **LaTeX Editing**: Comprehensive LaTeX support through VimTeX with custom templates, PDF viewing, citation management, and more
- **Markdown Writing**: Enhanced Markdown editing with smart list handling, checkboxes, and live preview
- **AI Assistance**: AI integration for code completion and editing suggestions with Avante and knowledge assistance with Lectic
- **Jupyter Notebooks**: Interactive notebook support with cell execution, navigation, and conversion between formats
- **NixOS Management**: Convenient commands for managing NixOS configurations, packages, and updates
- **Development Tools**: LSP configuration, syntax highlighting, Git integration, and diagnostics
- **Session Management**: Save and restore editing sessions with persistent workspaces
- **File Navigation**: Telescope integration for fuzzy finding, project navigation, and more
- **Code Operations**: LSP-powered code actions, diagnostics, and reference exploration

## Making Configuration Changes

1. **Check for Conflicts**: Before adding new keybindings, check for conflicts with:
   ```
   :verbose map <key-combo>
   ```
   This shows if the key is already mapped and in which file.

2. **Test Changes Incrementally**: Make small changes and test them before proceeding to more complex modifications.

3. **Update Documentation**: Always update docstrings in the corresponding files when making changes:
   - For keymappings: Update comments in `keymaps.lua`
   - For which-key entries: Update the reference at the top of `which-key.lua`
   - For new features: Add documentation to this README.md

4. **Organize Related Functions**: Keep related functionality together in appropriate files:
   - Core settings: `lua/neotex/core/`
   - Plugin configurations: `lua/neotex/plugins/`
   - Filetype-specific settings: `after/ftplugin/`

## Using Avante AI

The Avante AI integration provides intelligent assistance directly within Neovim.
It supports multiple AI providers including Claude (Anthropic), GPT (OpenAI), and Gemini (Google).

### Basic Usage

> [Info] The `leader` key is set to `space`.

- **Access the AI**: Press `<leader>ha` to ask a question or `<leader>ht` to toggle the AI interface
- **Chat Mode**: Use `<leader>hc` to start a chat session with the AI
- **Quick Access**: In terminal mode, use `<C-a>` to ask a question

### Managing AI Settings

- **Switch Models**: Press `<leader>hm` to select a model for the current provider
- **Change Provider**: Use `<leader>hd` to set a different AI provider (Claude, OpenAI, Gemini)
- **System Prompts**: Manage system prompts with `<leader>hp` (select) or `<leader>he` (edit)
- **Stop Generation**: If the AI is taking too long, press `<leader>hi` to interrupt the generation

More details are provided in [Making Configuration Changes](#making-configuration-changes) below.

## Feature Overview

NeoVim will open with the dashboard which includes the following options:

| Key | Description                                           |
|-----|-------------------------------------------------------|
| `s` | Restore Session - Load a previously saved session     |
| `r` | Recent Files - Browse and open recently edited files  |
| `e` | Explorer - Toggle the NvimTree file explorer          |
| `f` | Find File - Search for files in your project          |
| `g` | Find Text - Search for text content across files      |
| `n` | New File - Create and start editing a new file        |
| `c` | Config - Browse Neovim configuration files            |
| `i` | Info - Open the CheatSheet with quick references      |
| `m` | Manage Plugins - Open the Lazy plugin manager         |
| `h` | Checkhealth - Run Neovim's health diagnostics         |
| `q` | Quit - Exit Neovim                                    |

The dashboard provides quick access to common actions and makes it easy to start working on your projects such as:
- Resume previous work in a session
- Navigate recent files
- Start new projects
- Access configuration
- Manage your Neovim setup

Press the corresponding key to activate any option, or use your mouse to click on the desired action.

### Special Keybindings in Avante Buffers

When in an Avante buffer (AI interface):

| Key       | Action                            |
|-----------|-----------------------------------|
| `q`       | Quit Avante                       |
| `<C-t>`   | Toggle Avante interface           |
| `<C-c>`   | Reset/clear Avante content        |
| `<C-m>`   | Select model for current provider |
| `<C-p>`   | Select provider and model         |
| `<C-s>`   | Stop AI generation                |
| `<C-d>`   | Select provider/model with default|
| `<CR>`    | Create new line (not submission)  |
| `<C-j>`   | Move up between panes             |
| `<C-k>`   | Move down between panes           |
| `<C-l>`   | Accept suggestion (insert mode)   |
| `<C-h>`   | Dismiss suggestion                |
| `o`       | Select 'ours' in diff             |
| `t`       | Select 'theirs' in diff           |
| `a`       | Select all 'theirs' in diff       |
| `b`       | Select both in diff               |
| `c`       | Select at cursor in diff          |
| `n`       | Jump to next                      |
| `N`       | Jump to previous                  |
| `A`       | Apply all in sidebar              |
| `a`       | Apply at cursor in sidebar        |
| `<Tab>`   | Switch windows in sidebar         |
| `<S-Tab>` | Reverse switch windows in sidebar |

### Using Avante to Work with this Configuration

Avante is particularly useful for understanding and modifying this Neovim configuration:

1. **Explore Features**: Ask Avante about specific features, e.g., "How do I use VimTeX in this configuration?"
2. **Get Help with Keymappings**: Ask "What are the keybindings for this [feature]?"
3. **Customize Settings**: Ask "How can I change [setting]?" or "Help me add a new keybinding for [action]"
4. **Troubleshoot Issues**: Describe any problems you encounter for guided troubleshooting
5. **Add New Features**: Get assistance with integrating new plugins or features and understanding documentation

Example prompts:
- "I want to add a new LaTeX template. How should I do that?"
- "Help me understand the Markdown list handling in this setup"
- "Show me how to create a custom system prompt for Avante"

## Keybinding Reference

Here is an exhaustive list of the keybindings which this configuration adds to vanilla NeoVim.
It is easy to change these keybindings one at a time, but harder to come up with a coherent set of conventions as a whole.
Details will be included below for how to go about adapting this configuration for your specific needs.

### General Key Mappings

| Key             | Action                            |
|-----------------|-----------------------------------|
| `<Space>`       | Leader key for command sequences  |
| `<C-t>`         | Toggle terminal window            |
| `<C-s>`         | Show spelling suggestions         |
| `<CR>` (Enter)  | Clear search highlighting         |
| `<C-p>`         | Find files with Telescope         |
| `<C-;>`         | Toggle comments for line/selection|
| `<S-m>`         | Show help for word under cursor   |
| `<C-m>`         | Search man pages with Telescope   |
| `gx`            | Open URL under cursor             |
| `<C-LeftMouse>` | Open URL at mouse click position  |

### Navigation Keys

| Key                                  | Action                              |
|--------------------------------------|-------------------------------------|
| `Y`                                  | Yank to end of line                 |
| `E`                                  | Go to end of previous word          |
| `m`                                  | Center cursor at top of screen      |
| `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>`   | Navigate between windows            |
| `<A-h>`, `<A-l>`                     | Resize window horizontally          |
| `<Tab>`                              | Go to next buffer (by modified time)|
| `<S-Tab>`                            | Go to prev buffer (by modified time)|
| `<C-u>`, `<C-d>`                     | Scroll half-page with centering     |
| `<S-h>`, `<S-l>`                     | Go to start/end of display line     |
| `J`, `K`                             | Navigate display lines (with wrap)  |

### Folding Keys

| Key           | Action                                     |
|---------------|--------------------------------------------|
| `<leader>mt`  | Toggle folding method (manual/smart)       |
| `<leader>mf`  | Toggle fold under cursor                   |
| `<leader>ma`  | Toggle all folds open/closed               |

### Lectic Keys (AI-assisted markdown)

| Key           | Action                             |
|---------------|------------------------------------|
| `<leader>mn`  | Create new Lectic file             |
| `<leader>ml`  | Run Lectic on entire file          |
| `<leader>ms`  | Submit selection with user message |

### Text Manipulation Keys

| Key             | Action                            |
|-----------------|-----------------------------------|
| `<A-j>`, `<A-k>`| Move line or selection up/down    |
| `<`, `>`        | Decrease/increase indentation     |

### Terminal Mode Keys

| Key                                 | Action                         |
|-------------------------------------|--------------------------------|
| `<Esc>`                             | Exit terminal mode             |
| `<C-t>`                             | Toggle terminal window         |
| `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>`  | Navigate between windows       |
| `<C-a>`                             | Ask Avante AI (non-lazygit)    |
| `<M-h>`, `<M-l>`, etc.              | Resize terminal window         |

### Markdown-Specific Keys

| Key                  | Action                               |
|----------------------|--------------------------------------|
| `<CR>` (Enter)       | Create new bullet point              |
| `o`                  | Create new bullet point below        |
| `O`                  | Create new bullet point above        |
| `<Tab>`              | Indent bullet and recalculate        |
| `<S-Tab>`            | Unindent bullet and recalculate      |
| `dd`                 | Delete line and recalculate          |
| `d` (visual mode)    | Delete selection and recalculate     |
| `<C-n>`              | Toggle checkbox status ([ ] -> [x])  |
| `<C-c>`              | Recalculate list numbering           |

### Leader Key Mappings

These mappings are provided by the `which-key` plugin with a pop up menu to make them easy to remember and learn.

#### Top-Level Leader Mappings (`<leader>`)

| Key           | Action                         |
|---------------|--------------------------------|
| `<leader>b`   | Compile LaTeX document         |
| `<leader>c`   | Create vertical split          |
| `<leader>d`   | Save and delete buffer         |
| `<leader>e`   | Toggle NvimTree explorer       |
| `<leader>j`   | Jupyter notebook functions     |
| `<leader>i`   | Open VimtexToc                 |
| `<leader>k`   | Maximize split                 |
| `<leader>q`   | Save all and quit              |
| `<leader>u`   | Open Telescope undo            |
| `<leader>v`   | View compiled LaTeX document   |
| `<leader>w`   | Write all files                |
| `<leader>x`   | Text operations menu           |

#### Actions (`<leader>a`)

| Key              | Action                        |
|------------------|-------------------------------|
| `<leader>aa`     | Work with PDF annotations     |
| `<leader>ab`     | Export BibTeX to separate file|
| `<leader>ac`     | Clear LaTeX compilation cache |
| `<leader>ae`     | Display LaTeX error messages  |
| `<leader>af`     | Format current buffer via LSP |
| `<leader>ag`     | Open LaTeX glossary template  |
| `<leader>ah`     | Highlight word occurrences    |
| `<leader>ak`     | Remove LaTeX auxiliary files  |
| `<leader>al`     | Show/hide Lean information    |
| `<leader>am`     | Execute model checker         |
| `<leader>ap`     | Execute current Python file   |
| `<leader>ar`     | Fix numbering in lists        |
| `<leader>at`     | Format LaTeX using latexindent|
| `<leader>au`     | Change to file's directory    |
| `<leader>av`     | Show VimTeX context actions   |
| `<leader>aw`     | Count words in document       |
| `<leader>as`     | Open snippets directory       |
| `<leader>aS`     | Connect to MIT server via SSH |

#### Find (`<leader>f`)

| Key              | Action                        |
|------------------|-------------------------------|
| `<leader>fa`     | Search all files (inc. hidden)|
| `<leader>fb`     | Switch between open buffers   |
| `<leader>fc`     | Search BibTeX citations       |
| `<leader>ff`     | Search text in project files  |
| `<leader>fl`     | Continue previous search      |
| `<leader>fq`     | Search within quickfix list   |
| `<leader>fg`     | Browse git commit history     |
| `<leader>fh`     | Search Neovim help docs       |
| `<leader>fk`     | Show all keybindings          |
| `<leader>fr`     | Show clipboard registers      |
| `<leader>ft`     | Find TODOs in project         |
| `<leader>fs`     | Search for string in project  |
| `<leader>fw`     | Find current word in project  |
| `<leader>fy`     | Browse clipboard history      |

#### Git (`<leader>g`)

| Key              | Action                         |
|------------------|--------------------------------|
| `<leader>gb`     | Switch to another git branch   |
| `<leader>gc`     | Show commit history            |
| `<leader>gd`     | Show changes against HEAD      |
| `<leader>gg`     | Launch terminal git interface  |
| `<leader>gk`     | Jump to previous change        |
| `<leader>gj`     | Jump to next change            |
| `<leader>gl`     | Show git blame for current line|
| `<leader>gp`     | Preview current change         |
| `<leader>gs`     | Show files with changes        |
| `<leader>gt`     | Toggle line blame display      |

#### Jupyter (`<leader>j`)

| Key              | Action                        |
|------------------|-------------------------------|
| `<leader>je`     | Execute cell                  |
| `<leader>jj`     | Next cell                     |
| `<leader>jk`     | Previous cell                 |
| `<leader>jn`     | Execute and next              |
| `<leader>jo`     | Insert cell below             |
| `<leader>jO`     | Insert cell above             |
| `<leader>js`     | Split cell at cursor          |
| `<leader>jc`     | Comment current cell          |
| `<leader>ja`     | Run all cells                 |
| `<leader>jb`     | Run cells below               |
| `<leader>ju`     | Merge with cell above         |
| `<leader>jd`     | Merge with cell below         |
| `<leader>ji`     | Start IPython REPL            |
| `<leader>jt`     | Send motion to REPL           |
| `<leader>jl`     | Send line to REPL             |
| `<leader>jf`     | Send file to REPL             |
| `<leader>jq`     | Exit REPL                     |
| `<leader>jr`     | Clear REPL                    |
| `<leader>jv`     | Send visual selection to REPL |

#### AI Help (`<leader>h`)

| Key              | Action                          |
|------------------|---------------------------------|
| `<leader>ha`     | Ask Avante AI a question        |
| `<leader>hb`     | Build deps for Avante project   |
| `<leader>hc`     | Start chat with Avante AI       |
| `<leader>hk`     | Clear Avante chat/content       |
| `<leader>hd`     | Change AI model with defaults   |
| `<leader>he`     | Open system prompt manager      |
| `<leader>hm`     | Choose AI model for provider    |
| `<leader>hM`     | Create repo map for AI context  |
| `<leader>hp`     | Choose a different system prompt|
| `<leader>hs`     | Switch AI provider              |
| `<leader>hr`     | Reload AI assistant             |
| `<leader>hi`     | Interrupt AI generation         |
| `<leader>ht`     | Show/hide Avante interface      |

#### List (`<leader>L`)

| Key              | Action                        |
|------------------|-------------------------------|
| `<leader>Lc`     | Check/uncheck a checkbox      |
| `<leader>Ln`     | Move to next item in list     |
| `<leader>Lp`     | Move to previous item in list |
| `<leader>Lr`     | Fix list numbering            |

#### LSP & Linting (`<leader>l`)

| Key              | Action                        |
|------------------|-------------------------------|
| `<leader>lb`     | Show errors in current file   |
| `<leader>lc`     | Show available code actions   |
| `<leader>ld`     | Jump to symbol definition     |
| `<leader>lD`     | Jump to symbol declaration    |
| `<leader>lh`     | Show documentation under cursor|
| `<leader>li`     | Find implementations of symbol|
| `<leader>lk`     | Stop language server          |
| `<leader>ll`     | Show errors for current line  |
| `<leader>ln`     | Go to next error/warning      |
| `<leader>lp`     | Go to previous error/warning  |
| `<leader>lr`     | Find all references to symbol |
| `<leader>ls`     | Restart language server       |
| `<leader>lt`     | Start language server         |
| `<leader>ly`     | Copy diagnostics to clipboard |
| `<leader>lR`     | Rename symbol under cursor    |
| `<leader>lL`     | Run linters on current file   |
| `<leader>lg`     | Toggle linting globally       |
| `<leader>lB`     | Toggle linting for buffer     |

#### Markdown (`<leader>m`)

| Key              | Action                              |
|------------------|-------------------------------------|
| `<leader>ml`     | Run Lectic on current file          |
| `<leader>mn`     | Create new Lectic file with template|
| `<leader>ms`     | Submit selection with user message  |
| `<leader>mp`     | Format buffer with conform.nvim     |
| `<leader>mu`     | Open URL under cursor               |
| `<leader>mf`     | Toggle fold under cursor            |
| `<leader>ma`     | Toggle all folds open/closed        |
| `<leader>mt`     | Toggle folding method               |

#### Sessions (`<leader>S`)

| Key              | Action                        |
|------------------|-------------------------------|
| `<leader>Ss`     | Save current session          |
| `<leader>Sd`     | Delete a saved session        |
| `<leader>Sl`     | Load a saved session          |

#### NixOS (`<leader>n`)

| Key              | Action                        |
|------------------|-------------------------------|
| `<leader>nd`     | Enter nix development shell   |
| `<leader>ng`     | Clean up old nix packages     |
| `<leader>np`     | Open nixOS packages website   |
| `<leader>nm`     | Open MyNixOS website          |
| `<leader>nr`     | Rebuild system from flake     |
| `<leader>nh`     | Apply home-manager changes    |
| `<leader>nu`     | Update flake dependencies     |

#### Pandoc (`<leader>p`)

| Key              | Action                        |
|------------------|-------------------------------|
| `<leader>pw`     | Convert to .docx format       |
| `<leader>pm`     | Convert to .md format         |
| `<leader>ph`     | Convert to .html format       |
| `<leader>pl`     | Convert to .tex format        |
| `<leader>pp`     | Convert to .pdf format        |
| `<leader>pv`     | Open PDF in document viewer   |

#### Run (`<leader>r`)

| Key              | Action                         |
|------------------|------------------------------- |
| `<leader>rc`     | Clear Neovim plugin cache      |
| `<leader>re`     | Show errors in location list   |
| `<leader>rk`     | Remove all plugin files        |
| `<leader>rn`     | Go to next diagnostic/error    |
| `<leader>rp`     | Go to previous diagnostic/error|
| `<leader>rr`     | Reload Neovim configuration    |
| `<leader>rm`     | Display notification history   |

#### Surround (`<leader>s`)

| Key              | Action                        |
|------------------|-------------------------------|
| `<leader>ss`     | Surround with characters      |
| `<leader>sd`     | Remove surrounding characters |
| `<leader>sc`     | Change surrounding characters |

#### Yank (`<leader>y`)

| Key              | Action                        |
|------------------|-------------------------------|
| `<leader>yh`     | Browse yank/clipboard history |
| `<leader>yc`     | Clear yank history            |
| `<C-n>`          | Cycle forward through yanks   |
| `<C-p>`          | Cycle backward through yanks  |

#### Templates (`<leader>t`)

| Key              | Action                         |
|------------------|--------------------------------|
| `<leader>tp`     | Insert paper template          |
| `<leader>tl`     | Insert letter template         |
| `<leader>tg`     | Insert glossary template       |
| `<leader>th`     | Insert handout template        |
| `<leader>tb`     | Insert beamer presentation     |
| `<leader>ts`     | Insert subfile template        |
| `<leader>tr`     | Insert root document template  |
| `<leader>tm`     | Insert multiple answer template|

#### Text Operations (`<leader>x`)

| Key              | Action                              |
|------------------|-------------------------------------|
| `<leader>xa`     | Start text alignment                |
| `<leader>xA`     | Start alignment with preview        |
| `<leader>xs`     | Toggle between single/multi-line    |
| `<leader>xd`     | Show diff overlay with clipboard    |
| `<leader>xw`     | Toggle word-level diff display      |

#### TODO Navigation (`<leader>t`)

| Key              | Action                              |
|------------------|-------------------------------------|
| `<leader>tt`     | Find all TODOs with Telescope       |
| `<leader>tn`     | Jump to next TODO comment           |
| `<leader>tp`     | Jump to previous TODO comment       |
| `<leader>tl`     | Show TODOs in location list         |
| `<leader>tq`     | Show TODOs in quickfix list         |
| `[t`             | Go to previous TODO comment         |
| `]t`             | Go to next TODO comment             |

## Features and Workflows

When modifying this Neovim configuration, follow these guidelines to ensure consistency and prevent conflicts.

### Using Avante for Configuration Help

Avante AI can be an invaluable tool when modifying this configuration:

1. **Ask for Documentation**: Use Avante to generate detailed docstrings by asking:
   ```
   Help me create a comprehensive docstring for this function: [paste function]
   ```

2. **Understand Existing Code**: Ask Avante to explain complex parts of the configuration:
   ```
   Explain how this (LaTeX) code works: [paste code]
   ```

3. **Find Keybinding Conflicts**: Ask Avante to help identify conflicts:
   ```
   Check if these keybindings might conflict with existing ones: [list keys]
   ```

4. **Generate Configuration Snippets**: Get help creating new configuration:
   ```
   Help me create a configuration for [plugin/feature] that works with my existing setup/needs
   ```

5. **Troubleshoot Issues**: When something isn't working, ask Avante:
   ```
   I'm having an issue with [feature]. Here's the relevant configuration and error...
   ```

### Folding System

This configuration includes a smart folding system with the following features:

1. **Performance-Focused**: Default folding method is `manual` for better performance
2. **Smart Toggling**: Press `<leader>mf` to toggle between:
   - Manual folding (better performance)
   - Smart folding (expr for markdown, indent for other filetypes)
3. **Persistent Settings**: Your folding preference persists between Neovim sessions
4. **Markdown-Aware**: When smart folding is enabled for markdown files, folds will be created at headers
5. **Comprehensive Mappings**:
   - `<leader>ma` - Toggle all folds open/closed
   - `<leader>mf` - Toggle fold under cursor
   - `<leader>mt` - Toggle folding method (manual/smart)
   - All standard Vim folding keys (za, zo, zc, zR, zM) also work

The system is integrated throughout the configuration to provide a consistent experience
across all file types while prioritizing performance.

### URL Handling System

This configuration includes a comprehensive URL handling system for all file types:

1. **Universal Functionality**: Works in any file type, not just markdown
2. **Multiple URL Types**: Recognizes various URL formats:
   - Standard URLs (https://, http://, file://)
   - Markdown links ([text](url))
   - HTML links (<a href="url">text</a>)
   - Email addresses (user@example.com)
3. **Convenient Access**:
   - Press `gx` to open URL under cursor
   - `Ctrl+Click` to open URL at mouse position
   - `<leader>mu` to open URL under cursor via keybinding
4. **Cross-Platform**: Works on Linux, macOS, and Windows

### Lectic Integration

Lectic provides AI-assisted writing for markdown files with these features:

1. **Quick File Creation**: `<leader>mn` creates a new Lectic file with a template
2. **Full-File Processing**: `<leader>ml` runs Lectic on the entire file
3. **Visual Selection Processing**: 
   - Select text in visual mode (`v`, `V`, or `<C-v>`)
   - Press `<Esc>` to exit visual mode
   - Press `<leader>ms` to process the previously selected text
   - You'll be prompted to add a message/question about the selection in a multi-line input box
   - Both the selected text and your message will be added to the end of the file with appropriate formatting
   - Lectic will then process the entire file

Use Lectic for AI-assisted writing, brainstorming, or refining your markdown documents.

### Jupyter Notebook Integration

This configuration provides comprehensive support for working with Jupyter notebooks through three integrated plugins:

1. **Jupytext**: Converts between Jupyter notebooks (.ipynb) and text formats (.md, .py)
2. **NotebookNavigator**: Enables cell-based navigation and execution
3. **Iron.nvim**: Provides REPL integration for Python, Julia, R, and Lua

#### Key Features

- **Notebook Mode**: Work with notebook-style cells in markdown or Python files
- **Format Conversion**: Convert between .ipynb, .md, and .py formats
- **Cell Navigation**: Move between code/markdown cells with keyboard shortcuts
- **Cell Execution**: Run cells directly and see output in a REPL
- **Interactive REPL**: Send code snippets, lines, or files to the REPL
- **Smooth Workflow**: Integrated keybindings for all notebook operations

#### Jupyter Keybindings (`<leader>j`)

| Key           | Action                          |
|---------------|----------------------------------|
| `<leader>je`  | Execute current cell             |
| `<leader>jj`  | Navigate to next cell            |
| `<leader>jk`  | Navigate to previous cell        |
| `<leader>jn`  | Execute cell and move to next    |
| `<leader>jo`  | Insert new cell below            |
| `<leader>jO`  | Insert cell above                |
| `<leader>js`  | Split cell at cursor position    |
| `<leader>jc`  | Comment current cell             |
| `<leader>ja`  | Run all cells in file            |
| `<leader>jb`  | Run current and all cells below  |
| `<leader>ju`  | Merge with cell above            |
| `<leader>jd`  | Merge with cell below            |
| `<leader>ji`  | Start IPython REPL               |
| `<leader>jt`  | Send motion to REPL              |
| `<leader>jl`  | Send current line to REPL        |
| `<leader>jf`  | Send entire file to REPL         |
| `<leader>jv`  | Send visual selection to REPL    |
| `<leader>jq`  | Exit REPL                        |
| `<leader>jr`  | Clear REPL screen                |
| `<leader>jc`  | Show jupytext config             |

#### Cell Markers

The system recognizes cells based on these markers:
- **Python**: Cells are delimited by `# %%` or `#%%` comments
- **Markdown**: Cells are delimited by code blocks starting/ending with ``` (triple backticks)

#### Workflow Example

1. Create a Python or Markdown file with cell markers
2. Navigate between cells with `<leader>jj` and `<leader>jk`
3. Execute cells with `<leader>je` or execute and move to next with `<leader>jn`
4. Add new cells with `<leader>jo` (below) or `<leader>jO` (above)
5. Use additional features like `<leader>js` (split cell), `<leader>jc` (comment cell), or `<leader>ja` (run all cells)

This integration provides a seamless experience for data analysis, scientific computing, and literate programming without leaving Neovim.

### Performance Optimization Tools

This configuration includes built-in tools for analyzing and improving performance:

1. **Startup Analysis**: Run `:AnalyzeStartup` to identify bottlenecks in your NeoVim startup process
2. **Plugin Profiling**: Use `:ProfilePlugins` to measure load times for all plugins
3. **Optimization Reports**: Generate comprehensive reports with `:OptimizationReport`
4. **Lazy-Loading Suggestions**: Get plugin-specific recommendations with `:SuggestLazyLoading`

These tools provide actionable insights to help you maintain a fast and responsive editing environment. See the comprehensive documentation in `lua/neotex/utils/README.md` for more details on the optimization workflow.

### Testing Your Changes

After making changes:

1. Source the modified file with `<leader>rr` or (better) restart Neovim
2. Test the functionality in realistic scenarios
3. Check for any error messages in `<leader>rs`
4. Use `:checkhealth` to verify plugin health (also linked in the dashboard `<leader>rd`)
5. If issues occur, use `:verbose` commands to debug

Remember that a well-documented configuration is easier to maintain and extend.
Take the time to add clear comments and keep this README updated as the configuration evolves.

### Troubleshooting and Debugging

#### Viewing Debug Messages

By default, debug messages are hidden to keep your Neovim experience clean. If you need to see these messages for troubleshooting:

1. **View all notification levels**: 
   ```lua
   :lua vim.notify_level = vim.log.levels.DEBUG
   ```

2. **View even more verbose messages** (including trace level):
   ```lua
   :lua vim.notify_level = vim.log.levels.TRACE
   ```

3. **Check notification history**:
   Press `<leader>rm` to view the notification history, which includes all past messages.

4. **Return to normal notifications** (hide debug messages again):
   ```lua
   :lua vim.notify_level = vim.log.levels.INFO
   ```

These debug messages can be helpful when diagnosing plugin loading issues, performance problems, or other configuration concerns.
