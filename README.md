# NeoTex: AI-Powered NeoVim for Research, Development, and System Management

A modern NeoVim configuration built for **AI-assisted coding**, **LaTeX typesetting**, **formal verification with Lean**, **NixOS system management**, and **multi-language development** with comprehensive LSP support and Git workflow integration.

## Core Focus Areas

### 1. AI-Assisted Development

**Multi-Provider AI Integration** for intelligent coding assistance:

- **Avante** - AI-powered code completion, refactoring, and inline suggestions with Claude, GPT, and Gemini support
- **Claude Code** - Advanced coding assistant with multi-provider support and custom system prompts
- **MCP Hub** - Model Context Protocol integration for extended AI capabilities
- **Lectic** - Persistent AI conversations for research and knowledge management
- **Git Worktrees + OpenCode** - Parallel AI-assisted development across multiple branches

**Quick Access**: `<leader>aa` (Avante), `<C-c>` (Claude Code), `<leader>ml` (Lectic)

### 2. Professional LaTeX Typesetting

**Comprehensive Academic Writing Environment**:

- **VimTeX** - Full-featured LaTeX editing with live compilation and PDF viewing
- **Custom Templates** - Article, book, beamer presentations, and publisher-specific templates
- **Citation Management** - Zotero integration with BibTeX synchronization
- **Math Support** - LaTeX-specific surrounds, snippets, and intelligent text objects
- **PDF Integration** - Synchronized forward/inverse search with PDF viewers
- **Multi-file Projects** - Chapter management, bibliography handling, and cross-referencing

**See**: [Research Tooling Documentation](nvim/docs/RESEARCH_TOOLING.md)

### 3. NixOS System Management

**Integrated System Configuration**:

- **Flake Management** - Rebuild system configurations from within NeoVim
- **Home Manager** - Apply user-specific configuration changes
- **Package Operations** - Update dependencies and clean old generations
- **Development Shells** - Enter nix-shell environments for project dependencies
- **Quick Resources** - Direct access to NixOS package search and configuration tools

**Quick Access**: `<leader>n` prefix for all NixOS operations

**See**: [NIX Workflows Documentation](nvim/docs/NIX_WORKFLOWS.md)

### 4. Formal Verification with Lean

**Interactive Theorem Proving Environment**:

- **Lean 4 Language Server** - Full LSP support with intelligent completion and diagnostics
- **Infoview Integration** - Live goal state display and tactic feedback
- **Proof Navigation** - Jump to definitions, find references, hover documentation
- **Unicode Input** - LaTeX-style abbreviations for mathematical symbols
- **Project Management** - Support for Lean projects with dependencies and imports

**See**: [Formal Verification Documentation](nvim/docs/FORMAL_VERIFICATION.md)

### 5. Modern Language Development

**Comprehensive LSP Support** with intelligent code assistance for:

- **Programming**: Python, Rust, Go, TypeScript/JavaScript, Lua, Nix, C/C++, Java, Shell
- **Markup**: LaTeX, Markdown, HTML/CSS
- **Data**: JSON, YAML, TOML
- **Specialized**: Jupyter notebooks, Lean 4 theorem proving

**Features**: Auto-completion, diagnostics, go-to-definition, references, refactoring, formatting

**See**: [LSP Configuration](nvim/lua/neotex/plugins/lsp/README.md)

### 6. Git Workflow Integration

**Professional Version Control**:

- **Neogit** - Comprehensive Git interface with Magit-style workflows
- **Gitsigns** - Inline git blame, hunk operations, and diff viewing
- **Diffview** - Side-by-side diff viewing and merge conflict resolution
- **Telescope Git** - Search commits, branches, and file history
- **Git Worktrees** - Multi-branch parallel development support

**Quick Access**: `<leader>g` prefix for all Git operations

## Key Features

![Screenshot of the configuration](images/screenshot_cite.png)

### Advanced AI Capabilities

- **Multi-Provider Support** - Switch between Claude, GPT, and Gemini on-the-fly
- **Custom System Prompts** - Create task-specific AI behaviors
- **Context-Aware Assistance** - AI understands project structure and file relationships
- **Inline Editing** - Visual selection editing with AI suggestions
- **Parallel Development** - Multiple AI sessions across git worktrees

### Academic Writing Excellence

- **Template System** - Pre-configured templates for articles, books, presentations, and publishers
- **Live Preview** - Synchronized PDF viewing with forward/inverse search
- **Citation Tools** - Zotero integration with smart bibliography management
- **Collaborative Workflows** - Git-based version control for academic papers
- **Markdown Support** - Pandoc integration for format conversion

### Formal Verification Tools

- **Lean 4 Integration** - Interactive theorem proving with live feedback
- **Infoview** - Real-time proof state visualization and goal tracking
- **Unicode Math** - LaTeX-style input for mathematical notation
- **Proof Navigation** - Seamless jumping between definitions and theorems
- **Project Support** - Full support for Lean projects with dependencies

### Development Productivity

- **Treesitter** - Advanced syntax highlighting and code understanding
- **Telescope** - Fuzzy finding for files, text, commands, and symbols
- **Which-Key** - Discoverable keybindings with contextual menus
- **Session Management** - Persistent workspaces with project-specific layouts
- **Terminal Integration** - Built-in terminal with seamless window navigation
- **Debugging** - DAP integration for multi-language debugging

### System Integration

- **NixOS Native** - Deep integration with Nix package management
- **Clipboard Sync** - System clipboard integration across SSH
- **File Watching** - Automatic buffer reload on external changes
- **Notifications** - Unified notification system with intelligent filtering
- **Performance** - Optimized startup and lazy-loading for fast responsiveness

## Installation Guides

Select your operating system for detailed setup instructions:

- [MacOS Installation Guide](https://github.com/benbrastmckie/.config/blob/master/docs/MacOS-Install.md)
- [Arch Linux Installation Guide](https://github.com/benbrastmckie/.config/blob/master/docs/Arch-Install.md)
- [Debian/Ubuntu Installation Guide](https://github.com/benbrastmckie/.config/blob/master/docs/Debian-Install.md)
- [Windows Installation Guide](https://github.com/benbrastmckie/.config/blob/master/docs/Windows-Install.md)

**Quick Start**: See [Installation Guide](nvim/docs/INSTALLATION.md) for prerequisites and setup steps.

## Configuration Structure

```
~/.config/nvim/
├── init.lua                 # Main entry point
├── lua/neotex/              # Core configuration
│   ├── bootstrap.lua        # Plugin manager setup
│   ├── config/              # Core settings
│   │   ├── autocmds.lua     # Automatic commands
│   │   ├── keymaps.lua      # Key mappings
│   │   └── options.lua      # Neovim options
│   ├── plugins/             # Plugin configurations (by category)
│   │   ├── ai/              # AI integration (Avante, Claude Code, MCP)
│   │   ├── editor/          # Editor enhancements (which-key, telescope)
│   │   ├── lsp/             # Language server configurations
│   │   ├── text/            # Text processing (LaTeX, Markdown, Jupyter)
│   │   ├── tools/           # Development tools (git, snippets, REPL)
│   │   └── ui/              # UI components (statusline, explorer)
│   ├── core/                # Core functionality
│   └── util/                # Utility functions
├── docs/                    # Comprehensive documentation
│   ├── INSTALLATION.md      # Setup guide
│   ├── ARCHITECTURE.md      # System design
│   ├── MAPPINGS.md          # Complete keybinding reference
│   ├── AI_TOOLING.md        # AI workflows and git worktrees
│   ├── RESEARCH_TOOLING.md  # LaTeX and academic writing
│   ├── NIX_WORKFLOWS.md     # NixOS integration
│   └── ...                  # Additional documentation
├── templates/               # LaTeX document templates
├── snippets/                # Code snippet collections
└── after/ftplugin/          # Language-specific configurations
```

## Documentation

This configuration features comprehensive documentation for all systems:

### Essential Guides

- **[Complete Reference](nvim/README.md)** - Full feature guide and keybinding cheatsheet
- **[Installation Guide](nvim/docs/INSTALLATION.md)** - Step-by-step setup with prerequisites
- **[Architecture](nvim/docs/ARCHITECTURE.md)** - System design and plugin organization
- **[Mappings](nvim/docs/MAPPINGS.md)** - Complete keybinding reference

### Specialized Documentation

- **[AI Tooling](nvim/docs/AI_TOOLING.md)** - AI-assisted development with git worktrees and OpenCode
- **[Research Tooling](nvim/docs/RESEARCH_TOOLING.md)** - LaTeX, Markdown, and academic workflows
- **[NIX Workflows](nvim/docs/NIX_WORKFLOWS.md)** - NixOS system management integration
- **[Formal Verification](nvim/docs/FORMAL_VERIFICATION.md)** - Lean 4 theorem proving
- **[Notifications](nvim/docs/NOTIFICATIONS.md)** - Notification system configuration

### Module Documentation

Every directory includes a README with detailed module documentation:
- **[Plugin System](nvim/lua/neotex/plugins/README.md)** - Plugin organization and configuration
- **[Core Configuration](nvim/lua/neotex/config/README.md)** - Settings, keymaps, autocommands
- **[Utilities](nvim/lua/neotex/util/README.md)** - Helper functions and optimization tools

## Quick Start

### First Time Setup

1. **Install Prerequisites** - Follow platform-specific installation guide
2. **Clone Configuration** - Place in `~/.config/nvim/`
3. **Run Health Check** - Open NeoVim and run `:checkhealth`
4. **Configure AI** - Set API keys for Claude/GPT (see [AI Tooling](nvim/docs/AI_TOOLING.md))
5. **Customize** - Adjust keymaps and settings to your workflow

### Essential Keybindings

**Leader Key**: `<space>`

| Category | Key | Action |
|----------|-----|--------|
| **AI** | `<leader>aa` | Open Avante AI chat |
| | `<C-c>` | Toggle Claude Code |
| | `<leader>ml` | Lectic markdown AI |
| **Files** | `<C-p>` | Find files (Telescope) |
| | `<leader>sg` | Search text in project |
| | `<leader>e` | Toggle file explorer |
| **Git** | `<leader>gg` | Open Neogit |
| | `<leader>gb` | Git blame |
| | `<leader>gd` | Diff view |
| **LSP** | `gd` | Go to definition |
| | `gr` | Find references |
| | `<leader>ca` | Code actions |
| **LaTeX** | `<leader>ll` | Compile LaTeX |
| | `<leader>lv` | View PDF |
| | `<leader>lt` | Toggle table of contents |
| **NixOS** | `<leader>nr` | Rebuild system |
| | `<leader>nu` | Update flake |
| | `<leader>nh` | Home manager |

**See**: [Complete Mappings](nvim/docs/MAPPINGS.md) for full keybinding reference

## AI-Assisted Workflows

### Parallel Development with Git Worktrees

Use multiple AI sessions across different branches simultaneously:

```bash
# Create feature worktrees
git worktree add ../project-feature-a feature/authentication
git worktree add ../project-feature-b feature/api-endpoints

# Start AI sessions in each worktree
cd ../project-feature-a && nvim  # Avante session 1
cd ../project-feature-b && nvim  # Avante session 2
```

**See**: [AI Tooling Guide](nvim/docs/AI_TOOLING.md) for complete workflow documentation

### Multi-Provider AI Support

Switch AI providers and models on-the-fly:

- `<leader>ap` - Select provider (Claude, GPT, Gemini)
- `<leader>am` - Select model for current provider
- `<leader>ar` - Resume previous AI session

## Customization

The configuration is designed for easy customization:

1. **Add Plugins**: Edit `lua/neotex/plugins/*.lua` files using lazy.nvim format
2. **Modify Keymaps**: Update `lua/neotex/config/keymaps.lua`
3. **Configure LSP**: Add language servers in `lua/neotex/plugins/lsp/`
4. **Create Templates**: Add LaTeX templates to `templates/` directory
5. **Extend AI**: Customize system prompts in AI plugin configurations

**See**: [Configuration Guide](nvim/README.md) for detailed customization instructions

## System Requirements

- **Neovim** 0.10.0 or newer
- **Git** 2.23 or newer (for worktree support)
- **Node.js** 16 or newer (for LSP and AI integrations)
- **Python** 3.7 or newer (for debugger and tools)
- **LaTeX** distribution (TeX Live or MiKTeX) for LaTeX support
- **NixOS** (optional) - for Nix-specific features

**Additional Tools**: ripgrep, fd, fzf, tree-sitter CLI (see [Installation Guide](nvim/docs/INSTALLATION.md))

## Learning Resources

- **[NeoVim CheatSheet](nvim/README.md)** - Complete feature and keybinding reference
- **[Git Workflow Guide](https://github.com/benbrastmckie/.config/blob/master/docs/LearningGit.md)** - Git best practices (under construction)
- **[Video Tutorials](https://www.youtube.com/watch?v=_Ct2S65kpjQ&list=PLBYZ1xfnKeDRhCoaM4bTFrjCl3NKDBvqk)** - Feature demonstrations

## NixOS Integration

For NixOS users, this configuration integrates seamlessly with system management:

- Dedicated keybindings for system rebuilds and package management
- Nix language server support with intelligent completion
- Integration with home-manager for user configuration
- Access to NixOS package search and documentation

**See**: [.dotfiles Repository](https://github.com/benbrastmckie/.dotfiles) for complete NixOS configuration

## Community & Support

- **Issues & Features**: [GitHub Issues](https://github.com/benbrastmckie/.config/issues)
- **Pull Requests**: Contributions welcome! See contribution guidelines
- **Questions**: Check existing issues or open a new discussion

## License

This configuration is available under the [MIT License](LICENSE).
