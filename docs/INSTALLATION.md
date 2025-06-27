# Installation Guide

This guide provides step-by-step instructions for installing and setting up this Neovim configuration.

## Prerequisites

Before installing this configuration, ensure you have the following:

### Required Software
- **Neovim** (e 0.9.0) - The latest stable version is recommended
- **Git** - For cloning and managing the repository
- **Node.js** and **npm** - Required for some plugins (LSP servers, etc.)
- **Python 3** with **pip** - Required for Python-based plugins
- **uv** package manager - Required for MCP-Hub AI integration

### Recommended Tools
- **ripgrep** (`rg`) - For fast text searching with Telescope
- **fd** - For fast file finding with Telescope
- **lazygit** - For terminal-based git interface
- **A Nerd Font** - For proper icon display (FiraCode Nerd Font recommended)

### Language-Specific Dependencies
- **LaTeX distribution** (TeXLive or MiKTeX) - For LaTeX editing support
- **Lean 4** - For theorem proving support
- **Jupyter** - For notebook integration

### Email Integration Dependencies (Optional)
For Himalaya email integration with OAuth2 authentication:
- **mbsync** (isync) - For IMAP synchronization
- **cyrus-sasl-xoauth2** - For OAuth2 authentication
- **SASL_PATH environment variable** - Must be set before starting Neovim

## Installation Steps

### Step 1: Fork the Repository

1. Visit the repository on GitHub
2. Click the "Fork" button to create your own copy
3. This allows you to customize the configuration while keeping track of updates

### Step 2: Backup Existing Configuration

**Important**: If you have an existing Neovim configuration, back it up first:

```bash
# Backup existing Neovim configuration
mv ~/.config/nvim ~/.config/nvim.backup

# Backup existing Neovim data (optional, contains plugin data)
mv ~/.local/share/nvim ~/.local/share/nvim.backup
```

### Step 3: Clone Your Fork

Replace `YOUR_USERNAME` with your GitHub username:

```bash
# Clone your fork to the correct location
git clone https://github.com/YOUR_USERNAME/nvim-config.git ~/.config/nvim

# Navigate to the configuration directory
cd ~/.config/nvim
```

### Step 4: Preserve Existing .config Files

If you have other applications configured in `~/.config/` that you want to preserve:

```bash
# Check what's currently in .config
ls -la ~/.config/

# The nvim directory should now be present alongside your other configs
# No additional steps needed - other configurations remain untouched
```

**Note**: This installation only affects the `~/.config/nvim/` directory. All other configuration files in `~/.config/` (for other applications) remain completely untouched.

### Step 5: Install Required Package Manager

Install the `uv` package manager for Python (required for MCP-Hub):

```bash
# On macOS/Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# On NixOS (if using nix-env)
nix-env -iA nixpkgs.uv

# On Ubuntu/Debian
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Alternatively, see [docs/UV_SETUP.md](UV_SETUP.md) for detailed installation instructions.

### Step 6: First Launch and Setup

1. **Launch Neovim**:
   ```bash
   nvim
   ```

2. **Initial Plugin Installation**:
   - Neovim will automatically start downloading and installing plugins
   - This process may take several minutes depending on your internet connection
   - You'll see progress messages as plugins are installed

3. **Wait for Completion**:
   - Let the initial setup complete fully
   - Some plugins may display warnings initially - this is normal
   - The dashboard should appear once installation is complete

### Step 7: Health Check

Run Neovim's health check to verify everything is working correctly:

```vim
:checkhealth
```

This command will check:
- **Core Neovim functionality**
- **Plugin dependencies**
- **LSP server availability**
- **External tool integration**
- **Python and Node.js providers**

### Step 8: Address Health Check Issues

Common issues and solutions:

#### Missing External Dependencies
```bash
# Install ripgrep (for Telescope)
# On Ubuntu/Debian:
sudo apt install ripgrep

# On macOS:
brew install ripgrep

# On NixOS:
nix-env -iA nixpkgs.ripgrep
```

```bash
# Install fd (for Telescope)
# On Ubuntu/Debian:
sudo apt install fd-find

# On macOS:
brew install fd

# On NixOS:
nix-env -iA nixpkgs.fd
```

#### Python Provider Issues
```bash
# Install Python provider
pip3 install --user pynvim

# Or using uv
uv pip install pynvim
```

#### Node.js Provider Issues
```bash
# Install Node.js provider
npm install -g neovim
```

#### LSP Server Installation
Most LSP servers will be automatically installed by Mason when you first open relevant file types. You can also manually install them:

```vim
:Mason
```

This opens the Mason interface where you can install language servers, formatters, and linters.

### Step 9: Email Integration Setup (Optional)

If you want to use the Himalaya email integration with OAuth2:

#### Environment Variable Setup

**Critical**: The `SASL_PATH` environment variable must be set before starting Neovim for OAuth2 authentication to work.

##### For NixOS Users
If using home-manager with `sessionVariables`:
```nix
home.sessionVariables = {
  SASL_PATH = "/path/to/cyrus-sasl-xoauth2/lib/sasl2:/path/to/cyrus-sasl/lib/sasl2";
  GMAIL_CLIENT_ID = "your-oauth2-client-id";
};
```

**Important**: Start Neovim from a terminal that has loaded these session variables, not from a desktop launcher.

##### For Non-NixOS Users
Add to your shell configuration file (`~/.bashrc`, `~/.zshrc`, etc.):
```bash
export SASL_PATH="/usr/lib/sasl2:/usr/lib64/sasl2:/usr/local/lib/sasl2"
export GMAIL_CLIENT_ID="your-oauth2-client-id"
```

#### Verify Setup
Before using email features, verify the environment:
```bash
# Check SASL_PATH is set
echo $SASL_PATH

# Check GMAIL_CLIENT_ID is set
echo $GMAIL_CLIENT_ID

# Test mbsync can find XOAUTH2
mbsync --help | grep SASL
```

If these variables are not set when Neovim starts:
- Email sync will fail with authentication errors
- OAuth token refresh will report "Missing OAuth2 credentials"

## Post-Installation Configuration

### Step 10: Customize Settings

1. **Personal Information**: Update templates and git integration with your information
2. **AI Configuration**: Set up AI providers (Claude, OpenAI, etc.) if desired
3. **Keybindings**: Customize keybindings in `lua/neotex/config/keymaps.lua`
4. **Theme**: Adjust colorscheme in `lua/neotex/plugins/ui/colorscheme.lua`

### Step 11: Test Core Features

Test essential functionality:

1. **File Navigation**:
   ```vim
   <C-p>          " Open file finder
   <leader>ff     " Search files with Telescope
   <leader>e      " Toggle file explorer
   ```

2. **Text Search**:
   ```vim
   <leader>fs     " Search in project
   <leader>fw     " Find word under cursor
   ```

3. **AI Integration** (if configured):
   ```vim
   <leader>ha     " Ask Avante AI
   <leader>ht     " Toggle AI interface
   ```

4. **LaTeX Support** (open a .tex file):
   ```vim
   <leader>b      " Compile document
   <leader>v      " View PDF
   ```

## Troubleshooting

### Plugin Issues
If plugins fail to load:
```vim
:Lazy sync          " Sync all plugins
:Lazy health        " Check plugin health
:Lazy clean         " Clean unused plugins
```

### LSP Issues
If language servers aren't working:
```vim
:LspInfo           " Check LSP status
:Mason             " Manage LSP servers
:checkhealth lsp   " Detailed LSP health check
```

### Performance Issues
If Neovim is slow to start:
```vim
:AnalyzeStartup    " Analyze startup time
:ProfilePlugins    " Profile plugin load times
```

### Reset Configuration
If you need to start fresh:
```bash
# Remove plugin data
rm -rf ~/.local/share/nvim

# Remove plugin state
rm -rf ~/.local/state/nvim

# Restart Neovim - plugins will reinstall
nvim
```

## Updating the Configuration

To update your configuration with upstream changes:

```bash
# Add the original repository as a remote
git remote add upstream https://github.com/ORIGINAL_AUTHOR/nvim-config.git

# Fetch upstream changes
git fetch upstream

# Merge or rebase upstream changes
git merge upstream/main
# OR
git rebase upstream/main

# Sync plugins after updates
nvim -c "Lazy sync" -c "qa"
```

## Getting Help

If you encounter issues:

1. **Check Health**: Run `:checkhealth` for diagnostic information
2. **Review Logs**: Check `~/.local/state/nvim/log/` for error logs
3. **Ask AI**: Use `<leader>ha` to ask Avante about configuration issues
4. **Documentation**: Refer to the comprehensive README files in each directory
5. **Scripts**: Use diagnostic scripts in the `scripts/` directory

## Next Steps

After successful installation:

1. **Read the Documentation**: Start with [README.md](../README.md)
2. **Learn Keybindings**: Review [MAPPINGS.md](MAPPINGS.md)
3. **Explore Features**: Try the dashboard options and various workflows
4. **Customize**: Adapt the configuration to your specific needs

## Navigation

- [Main Configuration ←](../README.md)
- [Keybinding Reference →](MAPPINGS.md)

Welcome to your new Neovim configuration! <�