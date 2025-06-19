# LSP (Language Server Protocol) Configuration

This directory contains all Language Server Protocol related plugins and configurations for NeoVim.

## File Structure

```
lsp/
├── README.md           # This documentation
├── blink-cmp.lua      # Modern completion engine
├── lspconfig.lua      # Base LSP server configuration
└── mason.lua          # LSP server management
```

## Overview

The LSP configuration provides intelligent code editing features including:
- Code completion with context-aware suggestions
- Syntax highlighting and error detection
- Go-to-definition and find references
- Code formatting and linting
- Symbol search and workspace navigation

## Core Components

### `blink-cmp.lua`
**Primary completion engine** using blink.cmp for high-performance autocompletion.

**Features:**
- LSP-based intelligent completion
- Path and command-line completion
- LaTeX citation and reference completion via VimTeX integration
- Snippet support with LuaSnip
- Custom appearance with enhanced icons and layout
- Context-aware source providers

**Key Configuration:**
- Enhanced kind icons for better visual distinction
- Custom component layout with proper spacing
- Automatic cmdline completion (`auto_show = true`)
- LaTeX-specific completion contexts (citations vs references)

### `lspconfig.lua`
**Base LSP server configuration** using nvim-lspconfig.

**Features:**
- Language server setup and initialization
- Client capabilities configuration
- Custom keybindings for LSP functions
- File operations integration

**Supported Languages:**
- Python, JavaScript/TypeScript, Lua, and more
- Automatic server detection and configuration

### `mason.lua`
**LSP server management** using Mason for automatic installation.

**Features:**
- Automatic LSP server installation and updates
- Package management for formatters and linters
- UI for browsing and managing language tools
- Integration with other LSP components


## Configuration Structure

```
lsp/
├── README.md         # This documentation
├── blink-cmp.lua    # Primary completion engine
├── lspconfig.lua    # Base LSP configuration
└── mason.lua        # LSP server management
```

## LaTeX Integration

Special attention has been given to LaTeX support through VimTeX integration:

- **Citation completion**: Works in `\cite{}` commands with bibliography parsing
- **Reference completion**: Works in `\ref{}` commands with label detection
- **Context-aware sources**: Different completion sources based on cursor context
- **Duplicate prevention**: Smart source management to avoid conflicting completions

## Key Features

### Completion Sources
- **LSP**: Language server completion
- **Path**: File and directory path completion
- **Snippets**: Code snippet expansion
- **Buffer**: Text from current and other buffers
- **Omni**: VimTeX omnifunc for LaTeX
- **Cmdline**: Command and path completion in command mode

### Performance Optimizations
- Lazy loading based on file types and events
- Context-aware source enabling/disabling
- Efficient fuzzy matching with typo resistance
- Minimal startup impact with deferred initialization

## Keybindings

Standard completion keybindings:
- `<C-j>`: Select next item
- `<C-k>`: Select previous item
- `<Tab>`: Accept completion or expand snippet
- `<C-e>`: Hide completion menu
- `<CR>`: Accept completion

## Dependencies

All LSP functionality depends on:
- `lazy.nvim`: Plugin manager
- `nvim-lspconfig`: Base LSP support
- `blink.cmp`: Modern completion engine
- `mason.nvim`: LSP server management
- `LuaSnip`: Snippet engine

## Implementation Notes

- Uses blink.cmp as the modern completion engine for high performance
- VimTeX completion integrated directly into blink.cmp configuration
- Configuration follows modern lazy loading patterns for optimal startup performance

## Plugin Analysis

To verify LSP plugins are properly loaded and organized:

```vim
:luafile scripts/check_plugins.lua
```

This will show the LSP category with plugins like blink.cmp, nvim-lspconfig, mason.nvim, and related tools. See [`scripts/README.md`](../../../scripts/README.md) for complete script documentation and the main [plugins README](../README.md#plugin-analysis-and-maintenance) for more details.

## Navigation

- [Tools Plugins →](../tools/README.md)
- [Editor Plugins →](../editor/README.md)
- [UI Plugins →](../ui/README.md)
- [AI Plugins →](../ai/README.md)
- [Text Plugins →](../text/README.md)
- [← Plugins Overview](../README.md)