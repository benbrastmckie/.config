# Installation Guide

Get up and running with this Neovim configuration in under 15 minutes.

## Introduction

This guide will help you install a modern, feature-rich Neovim configuration with:
- Code intelligence via LSP (Language Server Protocol)
- Fuzzy finding and project navigation
- Git integration and version control
- LaTeX support for academic writing
- AI-powered assistance and more

See the [Technical Glossary](GLOSSARY.md) for definitions of unfamiliar terms.

## Quick Start

New users start here for the fastest installation path.

### Step 1: Install Prerequisites

Ensure you have the basics installed. See [Platform Guides](../../docs/README.md#platform-installation-guides) for OS-specific commands.

**Required**:
- Neovim (>= 0.9.0)
- Git
- A [Nerd Font](GLOSSARY.md#nerd-font) (RobotoMono recommended)

**Check if installed**:
```bash
nvim --version  # Should show 0.9.0 or higher
git --version
```

### Step 2: Backup Existing Configuration

If you have an existing Neovim setup:

```bash
mv ~/.config/nvim ~/.config/nvim.backup
mv ~/.local/share/nvim ~/.local/share/nvim.backup
```

### Step 3: Clone Configuration

```bash
git clone https://github.com/REPOSITORY_URL ~/.config/nvim
cd ~/.config/nvim
```

Replace `REPOSITORY_URL` with the actual repository (or your fork).

### Step 4: Launch Neovim

```bash
nvim
```

Neovim will automatically install plugins. This takes 2-5 minutes.
Wait for completion, then restart Neovim.

### Step 5: Verify Installation

Run the health check:

```vim
:checkhealth
```

Fix any warnings by installing missing dependencies. See [Platform Guides](../../docs/README.md) for installation commands.

**Common fixes**:
```bash
# Python provider
pip3 install --user pynvim

# Node.js provider
npm install -g neovim
```

### Quick Start Complete!

You now have a working Neovim configuration. Try:
- `<C-p>` - Find files
- `<leader>ff` - Search files (leader key is Space)
- `<leader>e` - File explorer

**Next steps**:
- Review [detailed installation](#detailed-installation) for optional features
- Read [GLOSSARY.md](GLOSSARY.md) for technical terms
- Explore [ADVANCED_SETUP.md](ADVANCED_SETUP.md) for customization

## Prerequisites

Complete prerequisites information for understanding what's needed and why.

### Required Dependencies

These must be installed for basic functionality.

| Dependency | Purpose | Install Guide |
|------------|---------|---------------|
| **Neovim** (>= 0.9.0) | Modern text editor | [Platform Guides](../../docs/README.md) |
| **Git** | Version control | [Platform Guides](../../docs/README.md) |
| **Nerd Font** | Icon display | [Platform Guides](../../docs/README.md) |

See [Prerequisites Reference](../../docs/common/prerequisites.md) for detailed dependency explanations.

### Recommended Tools

These significantly enhance the experience but aren't strictly required.

| Tool | Purpose | Install Guide |
|------|---------|---------------|
| **ripgrep** (rg) | Fast text search | [Platform Guides](../../docs/README.md) |
| **fd** | Fast file finding | [Platform Guides](../../docs/README.md) |
| **lazygit** | Git interface | [Platform Guides](../../docs/README.md) |
| **Node.js** | LSP servers | [Platform Guides](../../docs/README.md) |
| **Python 3** | Python plugins | [Platform Guides](../../docs/README.md) |

### Optional Dependencies

For specific workflows. Can be installed later.

- **LaTeX**: Academic writing support - see [Advanced Setup](ADVANCED_SETUP.md#latex)
- **Lean 4**: Theorem proving - see [Advanced Setup](ADVANCED_SETUP.md#lean-4)
- **Jupyter**: Notebook support - see [Advanced Setup](ADVANCED_SETUP.md#jupyter)

### Installation by Platform

For detailed, OS-specific installation commands:
- [Arch Linux](../../docs/platform/arch.md)
- [Debian/Ubuntu](../../docs/platform/debian.md)
- [macOS](../../docs/platform/macos.md)
- [Windows](../../docs/platform/windows.md)

## Detailed Installation

Comprehensive installation with customization options.

### Forking for Customization

If you want to customize and track your changes:

1. Visit the repository on GitHub
2. Click "Fork" to create your own copy
3. Clone your fork instead:
   ```bash
   git clone https://github.com/YOUR_USERNAME/REPO_NAME.git ~/.config/nvim
   ```

This allows:
- Tracking personal customizations
- Syncing with upstream updates
- Contributing improvements back

See [Git Configuration Guide](../../docs/common/git-config.md) for complete forking workflow.

### Plugin Installation

On first launch, [Lazy.nvim](GLOSSARY.md#lazynvim) automatically:
- Downloads all plugins
- Installs dependencies
- Compiles native modules

**What you'll see**:
- Progress bars for each plugin
- Possible warnings (normal during first install)
- Dashboard appears when complete

**If installation fails**:
```vim
:Lazy sync     " Retry installation
:Lazy health   " Check for issues
```

### Health Check Deep Dive

The `:checkhealth` command verifies your installation. Understanding the output:

**Core Neovim**:
- Checks Neovim version and build
- Verifies runtime paths

**Providers**:
- Python: Required for Python-based plugins
- Node.js: Required for LSP servers and JavaScript plugins
- Ruby: Optional, rarely needed

**Plugins**:
- Each plugin reports its health
- Red errors need fixing
- Yellow warnings are often optional

**Fixing Common Issues**:

**Missing Python provider**:
```bash
pip3 install --user pynvim
```

**Missing Node.js provider**:
```bash
npm install -g neovim
```

**Missing LSP servers**:
```vim
:Mason  " Opens LSP server installer
```

LSP servers install automatically when you open relevant file types, or install manually via [Mason](GLOSSARY.md#mason).

### Advanced Dependencies

**UV Package Manager** (optional, for MCP-Hub AI):
```bash
# macOS/Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# NixOS
nix-env -iA nixpkgs.uv
```

See docs/UV_SETUP.md for details.

## Verification

Test core functionality after installation.

### File Navigation

```vim
<C-p>          " File finder (Telescope)
<leader>ff     " Find files by name
<leader>e      " File explorer (neo-tree)
```

### Text Search

```vim
<leader>fs     " Search text in project (ripgrep)
<leader>fw     " Find word under cursor
<leader>fh     " Search help documentation
```

### LSP Features

Open any code file:
```vim
gd             " Go to definition
K              " Hover documentation
<leader>ca     " Code actions
<leader>rn     " Rename symbol
```

### Git Integration

```vim
<leader>gs     " Git status (lazygit)
<leader>gc     " Git commits
<leader>gb     " Git blame
```

## Troubleshooting

Common issues and their solutions.

### Plugins Not Loading

**Symptoms**: Commands don't work, features missing

**Solutions**:
```vim
:Lazy sync          " Re-sync plugins
:Lazy health        " Check plugin status
:Lazy clean         " Remove unused plugins
```

### LSP Not Working

**Symptoms**: No code completion, no go-to-definition

**Solutions**:
```vim
:LspInfo            " Check LSP status
:Mason              " Install LSP servers
:checkhealth lsp    " Detailed LSP diagnostics
```

Common cause: LSP server not installed for your file type.
Fix: Open `:Mason` and install relevant server (e.g., `lua_ls` for Lua).

### Icons Show as Boxes

**Symptom**: File explorer shows squares instead of icons

**Solution**: Install a Nerd Font and configure your terminal to use it.

See [Platform Guides](../../docs/README.md) for Nerd Font installation.

### Slow Startup

**Solutions**:
```vim
:AnalyzeStartup    " See what's slow
:ProfilePlugins    " Profile plugin load times
```

Consider:
- Disabling unused plugins
- Lazy-loading more plugins
- Reducing auto-commands

### Complete Reset

If things are broken beyond repair:

```bash
# Remove all plugin data
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim

# Restart Neovim (will reinstall everything)
nvim
```

## Updating Configuration

Keep your configuration current with upstream changes.

### First-Time Setup

Add the original repository as upstream:

```bash
cd ~/.config/nvim
git remote add upstream https://github.com/ORIGINAL_AUTHOR/REPO_NAME.git
```

### Pulling Updates

```bash
# Fetch latest changes
git fetch upstream

# Merge into your configuration
git merge upstream/main

# Update plugins
nvim -c "Lazy sync" -c "qa"
```

**If you have local changes**:
```bash
git stash              # Save local changes
git merge upstream/main
git stash pop          # Restore local changes
```

See [Git Configuration Guide](../../docs/common/git-config.md) for complete workflow.

## Next Steps

After successful installation, explore these resources:

### Essential Reading

1. **[Technical Glossary](GLOSSARY.md)**: Understand LSP, Mason, providers, and other concepts
2. **[Keybindings](MAPPINGS.md)**: Learn keyboard shortcuts (if file exists)
3. **[Main README](../README.md)**: Feature overview and usage guide

### Optional Features

- **[Advanced Setup](ADVANCED_SETUP.md)**: LaTeX, email integration, terminal customization
- **[Platform Guides](../../docs/README.md)**: OS-specific installation details
- **[Zotero Integration](../../docs/common/zotero-setup.md)**: Bibliography management
- **[Terminal Setup](../../docs/common/terminal-setup.md)**: Enhanced terminal experience

### Customization

Start customizing your configuration:
- `lua/neotex/config/keymaps.lua` - Key bindings
- `lua/neotex/plugins/ui/colorscheme.lua` - Color scheme
- `lua/neotex/config/options.lua` - Editor options

## Getting Help

If you encounter issues:

1. **Health Check**: `:checkhealth` provides diagnostic information
2. **Logs**: Check `~/.local/state/nvim/log/` for error messages
3. **Documentation**: This guide and linked resources
4. **AI Assistant**: `<leader>ai` for configuration questions (if configured)
5. **GitHub Issues**: Report bugs or ask questions on GitHub

## Additional Resources

- **[Installation Documentation Index](../../docs/README.md)**: All installation guides
- **[Prerequisites Reference](../../docs/common/prerequisites.md)**: Detailed dependency info
- **[Git Configuration](../../docs/common/git-config.md)**: Git workflow and setup
- **[Technical Glossary](GLOSSARY.md)**: Term definitions

## Navigation

- [← Main Configuration](../README.md)
- [Technical Glossary →](GLOSSARY.md)
- [Advanced Setup →](ADVANCED_SETUP.md)
- [Platform Guides →](../../docs/README.md)

Welcome to your new Neovim configuration! <�
## Related Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - System design and bootstrap process
- [NIX_WORKFLOWS.md](NIX_WORKFLOWS.md) - NixOS-specific installation and configuration
- [AI_TOOLING.md](AI_TOOLING.md) - OpenCode and MCP setup
- [CODE_STANDARDS.md](CODE_STANDARDS.md) - Development standards
