# Prerequisites Reference

This document lists all dependencies for the Neovim configuration with explanations of their purpose.

## Core Dependencies Table

| Dependency | Required | Purpose | Platform Guides |
|------------|----------|---------|----------------|
| Neovim (>= 0.9.0) | Yes | Modern Neovim text editor | [Arch](../platform/arch.md) [Debian](../platform/debian.md) [macOS](../platform/macos.md) [Windows](../platform/windows.md) |
| Git | Yes | Version control and configuration management | [Arch](../platform/arch.md) [Debian](../platform/debian.md) [macOS](../platform/macos.md) [Windows](../platform/windows.md) |
| Node.js | Yes | LSP servers and JavaScript-based plugins | [Arch](../platform/arch.md) [Debian](../platform/debian.md) [macOS](../platform/macos.md) [Windows](../platform/windows.md) |
| Python 3 | Yes | Python-based plugins and providers | [Arch](../platform/arch.md) [Debian](../platform/debian.md) [macOS](../platform/macos.md) [Windows](../platform/windows.md) |
| pip3 | Yes | Python package manager for pynvim | [Arch](../platform/arch.md) [Debian](../platform/debian.md) [macOS](../platform/macos.md) [Windows](../platform/windows.md) |

## Recommended Tools

| Dependency | Purpose | Platform Guides |
|------------|---------|----------------|
| ripgrep (rg) | Fast text searching with Telescope | [Arch](../platform/arch.md) [Debian](../platform/debian.md) [macOS](../platform/macos.md) [Windows](../platform/windows.md) |
| fd | Fast file finding with Telescope | [Arch](../platform/arch.md) [Debian](../platform/debian.md) [macOS](../platform/macos.md) [Windows](../platform/windows.md) |
| lazygit | Terminal-based git interface | [Arch](../platform/arch.md) [Debian](../platform/debian.md) [macOS](../platform/macos.md) [Windows](../platform/windows.md) |
| fzf | Fuzzy finder for various operations | [Arch](../platform/arch.md) [Debian](../platform/debian.md) [macOS](../platform/macos.md) [Windows](../platform/windows.md) |
| Nerd Font | Font with programming icons | [Arch](../platform/arch.md) [Debian](../platform/debian.md) [macOS](../platform/macos.md) [Windows](../platform/windows.md) |

## Language-Specific Dependencies

### LaTeX Support

| Dependency | Purpose | Platform Guides |
|------------|---------|----------------|
| TeX Live / MacTeX / MiKTeX | LaTeX distribution for document compilation | [Arch](../platform/arch.md) [Debian](../platform/debian.md) [macOS](../platform/macos.md) [Windows](../platform/windows.md) |
| latexmk | LaTeX build automation | Included with TeX distributions |
| Zathura / Okular / Skim / SumatraPDF | PDF viewer with forward/inverse search | [Arch](../platform/arch.md) [Debian](../platform/debian.md) [macOS](../platform/macos.md) [Windows](../platform/windows.md) |

See [Advanced Setup](../../nvim/docs/ADVANCED_SETUP.md#latex) for complete LaTeX configuration.

### Lean 4 Support

| Dependency | Purpose | Platform Guides |
|------------|---------|----------------|
| Lean 4 | Theorem proving language | [Advanced Setup](../../nvim/docs/ADVANCED_SETUP.md#lean-4) |
| Elan | Lean version manager | [Advanced Setup](../../nvim/docs/ADVANCED_SETUP.md#lean-4) |

### Jupyter Support

| Dependency | Purpose | Platform Guides |
|------------|---------|----------------|
| Jupyter | Notebook interface | [Advanced Setup](../../nvim/docs/ADVANCED_SETUP.md#jupyter) |
| ipykernel | Python kernel for Jupyter | [Advanced Setup](../../nvim/docs/ADVANCED_SETUP.md#jupyter) |

## Optional Tools

### Email Integration

| Dependency | Purpose | Platform Guides |
|------------|---------|----------------|
| mbsync (isync) | IMAP synchronization | [Advanced Setup](../../nvim/docs/ADVANCED_SETUP.md#email-integration) |
| cyrus-sasl-xoauth2 | OAuth2 authentication for email | [Advanced Setup](../../nvim/docs/ADVANCED_SETUP.md#email-integration) |

### Development Tools

| Dependency | Purpose | Platform Guides |
|------------|---------|----------------|
| stylua | Lua code formatter | [Arch](../platform/arch.md) [Debian](../platform/debian.md) [macOS](../platform/macos.md) |
| lua-language-server | Lua LSP server | [Arch](../platform/arch.md) [Debian](../platform/debian.md) [macOS](../platform/macos.md) |
| pandoc | Document converter | [Arch](../platform/arch.md) [Debian](../platform/debian.md) [macOS](../platform/macos.md) |

## Dependency Explanation

### Why Neovim >= 0.9.0?
This configuration uses modern Neovim features:
- Built-in LSP client
- TreeSitter integration
- Lua configuration API
- Modern plugin management

### Why Node.js?
Required for:
- Language servers (TypeScript, JavaScript, JSON, etc.)
- Plugin ecosystem compatibility
- npm-based tool installation

### Why Python 3?
Required for:
- Python provider (pynvim)
- Python-based plugins
- Python LSP servers via Mason

### Why ripgrep and fd?
These tools provide:
- Fast project-wide text search
- Fast file finding
- Better performance than traditional grep/find
- Integration with Telescope fuzzy finder

## Verification

After installing dependencies, verify with:

```vim
:checkhealth
```

This command checks:
- Neovim core functionality
- Python and Node.js providers
- External tool availability
- Plugin health status

See [Installation Guide](../../nvim/docs/INSTALLATION.md#health-check) for interpreting results.

## Navigation

- [Back to Installation Documentation Index](../README.md)
- [Platform Installation Guides](../README.md#platform-installation-guides)
- [Main Installation Guide](../../nvim/docs/INSTALLATION.md)
- [Technical Glossary](../../nvim/docs/GLOSSARY.md)
