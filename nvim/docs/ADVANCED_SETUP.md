# Advanced Setup Guide

This guide covers optional features and customization beyond basic installation.

## Prerequisites

Before proceeding with advanced setup:
- Complete the [basic installation](INSTALLATION.md)
- Verify core functionality with `:checkhealth`
- Familiarize yourself with the [technical glossary](GLOSSARY.md)

## Table of Contents

1. [Email Integration](#email-integration)
2. [Language-Specific Setup](#language-specific-setup)
3. [Terminal Customization](#terminal-customization)
4. [Workflow Customization](#workflow-customization)
5. [Performance Optimization](#performance-optimization)

## Email Integration

Optional Himalaya email integration with OAuth2 authentication.

### Overview

This configuration supports email management directly within Neovim using:
- Himalaya email client
- OAuth2 authentication (Gmail, others)
- IMAP synchronization via mbsync

### Prerequisites

Install required packages:

**Arch Linux**:
```bash
sudo pacman -S isync cyrus-sasl
yay -S cyrus-sasl-xoauth2  # AUR package
```

**Debian/Ubuntu**:
```bash
sudo apt install isync sasl2-bin
# Install cyrus-sasl-xoauth2 from source
```

**macOS**:
```bash
brew install isync cyrus-sasl
# Install cyrus-sasl-xoauth2 from source
```

### Environment Configuration

**Critical**: Set environment variables before starting Neovim.

#### For NixOS Users

Using home-manager with `sessionVariables`:
```nix
home.sessionVariables = {
  SASL_PATH = "/path/to/cyrus-sasl-xoauth2/lib/sasl2:/path/to/cyrus-sasl/lib/sasl2";
  GMAIL_CLIENT_ID = "your-oauth2-client-id";
};
```

**Important**: Launch Neovim from a terminal that has loaded these variables, not from a desktop launcher.

#### For Other Systems

Add to shell configuration (`~/.bashrc`, `~/.zshrc`, etc.):
```bash
export SASL_PATH="/usr/lib/sasl2:/usr/lib64/sasl2:/usr/local/lib/sasl2"
export GMAIL_CLIENT_ID="your-oauth2-client-id"
```

Reload shell:
```bash
source ~/.bashrc  # or ~/.zshrc
```

### Verification

Before using email features:
```bash
# Check SASL_PATH is set
echo $SASL_PATH

# Check GMAIL_CLIENT_ID is set
echo $GMAIL_CLIENT_ID

# Test mbsync can find XOAUTH2
mbsync --help | grep SASL
```

### Troubleshooting

**Issue**: Email sync fails with authentication errors
- **Cause**: Environment variables not set when Neovim started
- **Solution**: Restart Neovim from terminal with variables loaded

**Issue**: OAuth token refresh reports "Missing OAuth2 credentials"
- **Cause**: GMAIL_CLIENT_ID not set
- **Solution**: Configure environment variables and restart

## Language-Specific Setup

### LaTeX

Additional LaTeX support beyond basic installation.

#### Prerequisites

Full LaTeX distribution (see [Prerequisites](../../docs/common/prerequisites.md)):
- TeX Live (Linux)
- MacTeX (macOS)
- MiKTeX (Windows)

#### PDF Viewer Configuration

Already covered in platform guides. See:
- [Arch Linux PDF Setup](../../docs/platform/arch.md#pdf-viewer-setup)
- [Debian PDF Setup](../../docs/platform/debian.md#pdf-viewer-setup)

#### Bibliography Management

See [Zotero Setup](../../docs/common/zotero-setup.md) for complete configuration.

### Lean 4

Theorem proving support.

#### Installation

```bash
# Install Lean 4
curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh

# Verify installation
lean --version
```

#### Configuration

LSP server installed automatically by Mason when opening `.lean` files.

### Jupyter

Notebook integration for data science workflows.

#### Prerequisites

```bash
# Install Jupyter
pip install jupyter notebook

# Install kernel
python -m ipykernel install --user
```

#### Usage

Open `.ipynb` files in Neovim for full notebook support.

## Terminal Customization

Optional terminal enhancements for improved workflow.

See [Terminal Setup Guide](../../docs/common/terminal-setup.md) for:
- Kitty terminal configuration
- Alacritty with tmux
- Fish shell customization

## Workflow Customization

### Personal Information

Update templates and git integration:

1. **Git Configuration**:
   See [Git Config Guide](../../docs/common/git-config.md)

2. **Template Variables**:
   Edit template files to include your information:
   - `lua/neotex/config/templates.lua` (if exists)
   - Project-specific templates in various directories

### AI Configuration

Configure AI providers for enhanced features:

1. **Claude Integration**:
   - Set up Anthropic API key
   - Configure Claude-specific features

2. **OpenAI Integration**:
   - Set up OpenAI API key
   - Configure GPT model preferences

3. **Avante AI**:
   - Configure AI assistant keybindings
   - Customize AI behavior

### Keybinding Customization

Customize keybindings in:
- `lua/neotex/config/keymaps.lua` (global keymaps)
- Plugin-specific configuration files

### Theme Customization

Adjust colorscheme in:
- `lua/neotex/plugins/ui/colorscheme.lua`

Available themes accessible via Telescope:
```vim
:Telescope colorscheme
```

## Performance Optimization

### Startup Time Analysis

Analyze what's slowing down startup:
```vim
:AnalyzeStartup    " Analyze startup time
:ProfilePlugins    " Profile plugin load times
```

### Plugin Optimization

1. **Lazy Loading**: Configure plugins to load only when needed
2. **Disable Unused**: Comment out plugins you don't use
3. **Reduce Dependencies**: Remove unnecessary plugin dependencies

### LSP Performance

For large projects:
```vim
" Disable LSP for specific file types
:LspStop

" Restart LSP when needed
:LspStart
```

## Advanced Features

### Custom Commands

Create custom commands in `lua/neotex/config/commands.lua`.

### Custom Autocommands

Add automation in `lua/neotex/config/autocmds.lua`.

### Plugin Development

Structure for custom plugins:
```
lua/neotex/custom/
├── your-plugin/
│   ├── init.lua
│   └── config.lua
```

## Troubleshooting Advanced Features

### Email Integration Issues

See [Email Integration](#email-integration) verification section.

### LaTeX Compilation Issues

```vim
:VimtexInfo           " Check VimTeX status
:VimtexClearCache     " Clear compilation cache
```

### Performance Issues

```vim
:checkhealth          " General health check
:LspInfo             " Check LSP status
:Lazy health         " Check plugin health
```

## Next Steps

- Return to [Main Installation](INSTALLATION.md)
- Review [Technical Glossary](GLOSSARY.md)
- Explore [Platform Guides](../../docs/README.md)

## Navigation

- [Back to Installation Guide](INSTALLATION.md)
- [Technical Glossary](GLOSSARY.md)
- [Installation Documentation Index](../../docs/README.md)
