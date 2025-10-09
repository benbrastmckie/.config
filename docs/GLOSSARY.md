# Technical Glossary

This glossary defines technical terms used throughout the installation and configuration documentation.

## Core Concepts

### Health Check
**Command**: `:checkhealth`

Neovim's built-in diagnostic command that verifies:
- Core Neovim functionality
- Plugin dependencies
- External tool integration
- Language provider status

Run this after installation to identify any missing dependencies or configuration issues.

### Lazy.nvim
**Purpose**: Plugin manager for Neovim

A modern, high-performance plugin manager that:
- Automatically downloads and installs plugins
- Lazy-loads plugins for faster startup
- Manages plugin updates and dependencies
- Provides a clean interface for plugin management

### LSP (Language Server Protocol)
**Purpose**: Code intelligence system

A protocol that provides:
- Code completion and suggestions
- Error detection and diagnostics
- Go-to-definition and find-references
- Hover documentation
- Code formatting and refactoring

LSP servers are language-specific programs that provide these features for different programming languages.

### Mason
**Purpose**: LSP server, formatter, and linter manager

A plugin that:
- Installs language servers automatically
- Manages formatters (code beautifiers)
- Manages linters (code quality checkers)
- Provides a clean UI for installation (`:Mason`)

Mason handles the installation of external tools needed for code intelligence.

### Nerd Font
**Purpose**: Programming-optimized font with icons

A font family that includes:
- Programming ligatures (combined character symbols)
- File type icons
- Git status symbols
- UI element icons

Required for proper icon display in file explorers, status lines, and other UI components.

### Provider
**Purpose**: External program integration

Neovim providers enable integration with external programs:
- **Python Provider**: Required for Python-based plugins
- **Node.js Provider**: Required for JavaScript/TypeScript plugins and LSP servers
- **Ruby Provider**: Required for Ruby-based plugins (optional)

Install providers using:
```bash
# Python
pip3 install --user pynvim

# Node.js
npm install -g neovim
```

## Plugin-Specific Terms

### Telescope
**Purpose**: Fuzzy finder and picker

An extensible fuzzy finder for:
- Finding files by name
- Searching text across project
- Browsing git commits
- Selecting colorschemes
- Much more via extensions

### VimTeX
**Purpose**: LaTeX editing support

Provides comprehensive LaTeX features:
- Compilation and error handling
- PDF viewer integration
- Citation management
- Syntax highlighting and completion

### Treesitter
**Purpose**: Advanced syntax parsing

Provides:
- Accurate syntax highlighting
- Code structure understanding
- Intelligent code folding
- Better text objects for editing

## Configuration Terms

### Fork
**Git Operation**: Creating your own copy of a repository

Forking allows you to:
- Customize the configuration without losing update ability
- Track your changes separately
- Contribute improvements back upstream
- Sync with original repository for updates

### Plugin Specification
**Format**: Lua table defining a plugin

Example structure:
```lua
{
  "plugin/name",           -- GitHub repository
  dependencies = {...},    -- Other plugins this requires
  config = function() ... end,  -- Setup function
  lazy = true,            -- Load only when needed
}
```

## Installation Terms

### Backup
**Purpose**: Preserving existing configuration

Before installation, backup existing files:
```bash
mv ~/.config/nvim ~/.config/nvim.backup
```

This prevents data loss and allows reverting if needed.

### Clone
**Git Operation**: Downloading a repository

Downloads the entire configuration:
```bash
git clone https://github.com/username/repo.git ~/.config/nvim
```

### Prerequisites
**Definition**: Required software before installation

Software that must be installed first:
- **Required**: Must have for basic functionality
- **Recommended**: Should have for full features
- **Optional**: Nice to have for specific workflows

See [Prerequisites Reference](../../docs/common/prerequisites.md) for complete list.

## Advanced Terms

### OAuth2
**Purpose**: Secure authentication protocol

Used for email integration and other authenticated services. Requires:
- Client ID from service provider
- Environment variables configuration
- SASL library for authentication

### SASL (Simple Authentication and Security Layer)
**Purpose**: Authentication framework

Used for email OAuth2 authentication. Requires:
- `cyrus-sasl-xoauth2` library
- `SASL_PATH` environment variable
- Proper configuration before starting Neovim

### Session Variables
**Purpose**: Environment configuration

Shell variables loaded at login:
```bash
export SASL_PATH="/path/to/sasl"
export GMAIL_CLIENT_ID="your-id"
```

Must be set before launching Neovim for certain features.

## Navigation

- [Back to Installation Guide](INSTALLATION.md)
- [Advanced Setup Guide](ADVANCED_SETUP.md)
- [Installation Documentation Index](../../docs/README.md)
