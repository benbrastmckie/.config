# NeoTeX Namespace

The `neotex` namespace contains the complete NeoVim configuration, providing a comprehensive development environment with specialized support for academic writing, research workflows, and software development.

## Purpose

This directory serves as the root namespace for all configuration modules. The bootstrap system initializes the environment through a robust sequence that ensures proper plugin installation, error handling, and graceful degradation when components fail to load.

## Architecture

### Initialization Flow

```
┌─────────────────────────────────────────┐
│          bootstrap.lua                   │
│  ┌───────────────────────────────────┐  │
│  │ 1. Cleanup tmp directories        │  │
│  │ 2. Ensure lazy.nvim installed     │  │
│  │ 3. Validate lazy-lock.json        │  │
│  │ 4. Setup plugins                  │  │
│  │ 5. Initialize utilities           │  │
│  │ 6. Configure Jupyter styling      │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
           │
           ├──> plugins/  (Lazy.nvim specs)
           ├──> config/   (Core settings)
           ├──> core/     (Fundamental utilities)
           └──> util/     (Helper functions)
```

## Module Documentation

### bootstrap.lua

Handles NeoVim configuration initialization with robust error handling at each step.

**Key Functions**:
- `M.init()` - Main entry point for configuration bootstrap
- Error-wrapped setup steps for each initialization phase
- Fallback to legacy plugin system when new system fails
- Deferred Jupyter notebook styling setup

**Plugin Loading Strategy**:
- Primary: Direct plugin specs via `neotex.plugins`
- Explicit loading for tools and AI plugins (avoids auto-discovery issues)
- Phase-based imports for editor, text, and UI plugins
- Legacy LSP imports for backward compatibility

**Error Handling**:
All initialization steps use `with_error_handling()` wrapper to provide clear error messages and graceful degradation.

## Subdirectories

### [config/](config/README.md)
Core NeoVim settings including options, keymaps, and autocmds.

### [core/](core/README.md)
Fundamental utilities and base functionality used throughout the configuration.

### [plugins/](plugins/README.md)
Lazy.nvim plugin specifications organized by category (AI, editor, LSP, text, tools, UI).

### [util/](util/README.md)
Helper functions and utility modules for notifications, logging, and common operations.

### [deprecated/](deprecated/README.md)
Legacy code preserved for reference or potential future use.

## Plugin Organization

Plugins are organized into categorical subdirectories:

- **ai/** - AI integration with multiple assistant options
  - claude/ - Claude Code with session management and worktree integration
  - avante/ - AI assistant with MCP protocol and inline suggestions
- **editor/** - Editor enhancements (coding utilities, formatting)
- **lsp/** - Language Server Protocol configurations
- **text/** - Text format-specific tools (LaTeX, Markdown, Jupyter)
- **tools/** - External tool integrations (email, terminal, file management)
- **ui/** - User interface enhancements (colorscheme, statusline, notifications)

Each category uses Lazy.nvim's import system for modular plugin loading.

## Bootstrap Sequence

The initialization process follows these steps:

1. **Cleanup**: Remove conflicting tree-sitter temporary directories
2. **Package Manager**: Install lazy.nvim if not present
3. **Validation**: Check and fix corrupted lazy-lock.json
4. **Plugin Setup**: Load plugin specifications (explicit + imports)
5. **Utilities**: Initialize helper functions and utilities
6. **Styling**: Configure Jupyter notebook styling (deferred, conditional)

Each step includes error handling that logs failures but continues initialization to maximize usability even with partial failures.

## Error Handling Philosophy

The bootstrap system prioritizes robustness over perfection:

- Each step wrapped in pcall with clear error messages
- Failures logged via vim.notify with appropriate severity
- Initialization continues after non-critical failures
- Legacy fallbacks ensure basic functionality

## Related Documentation

- [Code Standards](../../docs/CODE_STANDARDS.md) - Lua coding conventions
- [Architecture](../../docs/ARCHITECTURE.md) - System-wide design patterns
- [Documentation Standards](../../docs/DOCUMENTATION_STANDARDS.md) - Documentation requirements

## Navigation

- **Parent**: [nvim/lua/](../README.md)
- **Subdirectories**: [config](config/README.md), [core](core/README.md), [plugins](plugins/README.md), [util](util/README.md), [deprecated](deprecated/README.md)
