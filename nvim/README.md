# NeoVim Configuration and CheatSheet

A feature-rich Neovim configuration with AI integration optimized for LaTeX, Markdown, Jupyter Notebooks, and managing NixOS.

This setup provides a streamlined environment for academic writing, code development, and system management.
The AI integration makes it easy to learn and configure this setup for your specific needs.
Every subdirectory includes a `README.md` file which documents the modules contained in that directory.

## Installation

**New to this configuration?** See the [Installation Guide](docs/INSTALLATION.md) for step-by-step setup instructions, including how to fork the repository, install dependencies, and run health checks.

**Want to customize notifications?** See the [Notification System Documentation](docs/NOTIFICATIONS.md) for configuring notification behavior across all modules and plugins.

## File Structure

```
nvim/
├── init.lua              # Main configuration entry point
├── lazy-lock.json        # Plugin version lockfile
├── CLAUDE.md             # Project guidelines and policies
├── after/                # Post-load configurations
│   ├── ftdetect/         # File type detection rules
│   └── ftplugin/         # File type specific settings
├── lua/neotex/           # Main configuration modules
│   ├── bootstrap.lua     # Plugin system initialization
│   ├── config/           # Core Neovim settings
│   ├── plugins/          # Plugin configurations
│   └── util/             # Utility functions
├── templates/            # Document templates
│   ├── *.tex             # LaTeX templates
│   ├── report/           # Multi-chapter documents
│   └── springer/         # Publisher templates
├── snippets/             # Code snippet collections
├── scripts/              # Maintenance utilities
├── sessions/             # Saved editor sessions
└── spell/                # Custom spell check dictionaries
```

## Features Overview

This Neovim configuration includes specialized support for:

- **LaTeX Editing**: Comprehensive LaTeX support through VimTeX with custom templates, PDF viewing, citation management, and more
- **Markdown Writing**: Enhanced Markdown editing with smart list handling, checkboxes, and live preview
- **AI Assistance**: AI integration for code completion and editing suggestions with Avante, MCP-Hub tools, and knowledge assistance with Lectic
- **Jupyter Notebooks**: Interactive notebook support with cell execution, navigation, and conversion between formats
- **NixOS Management**: Convenient commands for managing NixOS configurations, packages, and updates
- **Development Tools**: LSP configuration, syntax highlighting, Git integration, and diagnostics
- **Session Management**: Save and restore editing sessions with persistent workspaces
- **File Navigation**: Telescope integration for fuzzy finding, project navigation, and more
- **Code Operations**: LSP-powered code actions, diagnostics, and reference exploration
- **Unified Notifications**: Intelligent notification system with category-based filtering and module-specific controls

### Dashboard Overview

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

### Prerequisites

This configuration requires several dependencies including Neovim (≥ 0.9.0), Git, Node.js, Python 3, and the `uv` package manager for MCP-Hub AI integration. 

**For complete installation requirements and step-by-step setup instructions, see the [Installation Guide](docs/INSTALLATION.md).**

## Documentation Structure

This configuration features comprehensive documentation throughout the directory structure. Each subdirectory contains a README.md file with detailed information about its purpose, components, and usage.

### Core Documentation Areas

- **[Configuration Core](lua/neotex/config/README.md)** - Essential Neovim settings (options, keymaps, autocommands)
- **[Plugin System](lua/neotex/plugins/README.md)** - Plugin organization and management
  - [Editor Enhancements](lua/neotex/plugins/editor/README.md) - Navigation, formatting, and terminal integration
  - [LSP Configuration](lua/neotex/plugins/lsp/README.md) - Language server setup and completion
  - [Text Processing](lua/neotex/plugins/text/README.md) - LaTeX, Markdown, Jupyter, and Lean support
  - [Development Tools](lua/neotex/plugins/tools/README.md) - Git, snippets, and productivity enhancements
  - [UI Components](lua/neotex/plugins/ui/README.md) - File explorer, status line, and visual elements
  - [AI Integration](lua/neotex/plugins/ai/README.md) - Avante, Claude Code, and MCP Hub
- **[Utility Functions](lua/neotex/util/README.md)** - Helper functions and performance optimization tools
- **[File Type Support](after/README.md)** - Language-specific configurations and detection
- **[Templates](templates/README.md)** - Document templates for LaTeX, presentations, and academic writing
- **[Code Snippets](snippets/README.md)** - Custom snippet collections for rapid development
- **[Scripts](scripts/README.md)** - Maintenance and diagnostic utilities

### Navigation

Each README file includes:
- Detailed module documentation
- Usage examples and configuration options
- Integration points with other system components
- Navigation links to related documentation
- Parent/child directory relationships

This documentation structure ensures that information about any component is easily accessible and maintains consistency across the entire configuration.

## Maintenance and Troubleshooting

The [`scripts/`](scripts/README.md) directory contains utility scripts for maintaining and troubleshooting the configuration:

- **Plugin Analysis**: `scripts/check_plugins.lua` - Verify plugin loading and organization
- **MCP Integration**: Scripts for testing and repairing AI tool integration
- **Diagnostics**: Comprehensive tests for configuration components

See [`scripts/README.md`](scripts/README.md) for detailed script documentation and usage instructions.

### Making Configuration Changes

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

Avante provides AI-powered code assistance directly within Neovim, offering intelligent code completion, explanations, refactoring suggestions, and conversational help. It supports multiple AI providers including Claude (Anthropic), GPT (OpenAI), and Gemini (Google).

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


### Using Avante for Configuration Help

Avante AI can be an invaluable tool when modifying this configuration.
When modifying this Neovim configuration, follow these guidelines to ensure consistency and prevent conflicts.

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

## Keybinding Reference

This configuration provides extensive keybinding customizations to enhance productivity and provide a cohesive editing experience. The keybindings are organized through two main systems:

### Keybinding Documentation

For complete keybinding reference, see:
- **[Complete Mappings Documentation](docs/MAPPINGS.md)** - Comprehensive reference of all keybindings organized by context and functionality
- **[Which-Key Configuration](lua/neotex/plugins/editor/README.md#which-key-whichkeylua)** - Interactive keybinding discovery system with contextual menus
- **[Core Keymaps Configuration](lua/neotex/config/README.md#keymaps-keymapslua)** - Base keybinding definitions and customizations

### Key Configuration Files

#### Core Keybindings (`lua/neotex/config/keymaps.lua`)
Defines the fundamental key mappings including:
- **Navigation**: Window movement, buffer switching, and cursor positioning
- **Editing**: Text manipulation, folding, and basic operations
- **Terminal**: Terminal mode bindings and window management
- **File operations**: Basic file handling and URL opening

#### Interactive Keybinding Discovery (`lua/neotex/plugins/editor/which-key.lua`)
Provides the which-key system for:
- **Leader-based mappings**: Organized hierarchical command structure under `<space>`
- **Contextual help**: On-screen menus showing available key combinations
- **Filetype-specific bindings**: Dynamic keybindings that appear based on current file type
- **Plugin integration**: Unified access to plugin functionality

### Quick Access

- **Leader key**: `<space>` - Access to all major functionality through organized menus
- **Help system**: Press `<leader>` and wait to see available commands
- **Complete reference**: See [docs/MAPPINGS.md](docs/MAPPINGS.md) for full details
- **Avante AI integration**: Ask Avante about specific keybindings with `<leader>ha`

## Further Features

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

### NixOS Management

This configuration includes convenient keybindings for managing NixOS systems directly from Neovim, streamlining system administration tasks:

#### System Management (`<leader>n`)

| Key              | Action                        |
|------------------|-------------------------------|
| `<leader>nr`     | Rebuild system from flake     |
| `<leader>nh`     | Apply home-manager changes    |
| `<leader>nu`     | Update flake dependencies     |
| `<leader>ng`     | Clean up old nix packages     |
| `<leader>nd`     | Enter nix development shell   |

#### Quick Access Resources

| Key              | Action                        |
|------------------|-------------------------------|
| `<leader>np`     | Open NixOS packages website   |
| `<leader>nm`     | Open MyNixOS website          |

#### Key Features

1. **System Rebuilding**: Quickly rebuild your NixOS configuration from flakes
2. **Home Manager**: Apply user-specific configuration changes
3. **Package Management**: Update dependencies and clean up old generations
4. **Development Environment**: Enter development shells for project-specific dependencies
5. **Resource Access**: Quick links to NixOS package search and configuration tools

These commands integrate NixOS system management into your development workflow, allowing you to manage system configuration, packages, and environments without leaving your editor.

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

## Navigation

### Core Configuration Areas
- [Configuration →](lua/neotex/config/README.md) - Options, keymaps, and autocommands
- [Plugins →](lua/neotex/plugins/README.md) - Plugin system and organization
- [Utilities →](lua/neotex/util/README.md) - Helper functions and optimization tools

### Specialized Documentation
- [Templates →](templates/README.md) - LaTeX document templates
- [Snippets →](snippets/README.md) - Code snippet collections
- [Scripts →](scripts/README.md) - Maintenance and diagnostic utilities
- [File Types →](after/README.md) - Language-specific configurations

### Additional Resources
- [Installation Guide →](docs/INSTALLATION.md) - Setup instructions
- [Keybinding Reference →](docs/MAPPINGS.md) - Complete keymap documentation

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
