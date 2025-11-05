# Claude Code-Assisted Installation Guide

## Table of Contents

- [Introduction](#introduction)
  - [What is Claude Code](#what-is-claude-code)
  - [Why Use Claude Code for Setup](#why-use-claude-code-for-setup)
  - [Overview of Installation Process](#overview-of-installation-process)
- [Phase 1: Install Claude Code](#phase-1-install-claude-code)
- [Phase 2: Fork and Clone Repository](#phase-2-fork-and-clone-repository)
- [Phase 3: Install Dependencies](#phase-3-install-dependencies)
- [Phase 4: Launch Neovim and Bootstrap](#phase-4-launch-neovim-and-bootstrap)
- [Phase 5: Customization and Configuration](#phase-5-customization-and-configuration)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)

## Introduction

### What is Claude Code

Claude Code is an AI-powered command-line interface tool developed by Anthropic that provides intelligent assistance for software development tasks. It acts as an AI pair programmer that can:

- Read and understand your codebase
- Execute commands and scripts with your approval
- Help troubleshoot issues and suggest solutions
- Automate repetitive configuration tasks
- Guide you through complex setup processes

Claude Code is particularly valuable for Neovim configuration because it can automatically detect missing dependencies, validate configurations, parse health check output, and provide context-aware troubleshooting assistance throughout the entire setup process.

### Why Use Claude Code for Setup

Setting up a comprehensive Neovim configuration like this one involves multiple steps across different systems:

- Installing numerous dependencies (Neovim, Git, Node.js, Python, language servers, tools)
- Configuring plugin managers and bootstrapping plugins
- Platform-specific installation variations (Arch, Debian/Ubuntu, macOS, Windows/WSL)
- Troubleshooting common issues (missing fonts, LSP errors, plugin failures)
- Managing personal customizations while staying synchronized with upstream updates

Claude Code can assist with each of these steps by:

1. **Automated Dependency Checking**: Scan your system and identify which dependencies are missing
2. **Platform Detection**: Automatically detect your platform and suggest appropriate installation commands
3. **Configuration Validation**: Verify that configuration files are properly set up before first launch
4. **Health Check Analysis**: Parse Neovim's `:checkhealth` output and suggest specific fixes
5. **Interactive Troubleshooting**: Diagnose issues in real-time and provide actionable solutions
6. **Guided Customization**: Help you create personal modifications following best practices

Using Claude Code for setup reduces installation time, prevents common mistakes, and provides a learning experience as you see how each component works together.

### Overview of Installation Process

The complete installation process follows this workflow:

```
┌─────────────────────────────────────────────────────────────┐
│                  Installation Workflow                      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────┐
        │  Phase 1: Install Claude Code     │
        │  • Platform-specific installation │
        │  • OAuth authentication           │
        │  • Verification testing           │
        └───────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────┐
        │  Phase 2: Fork and Clone Repo     │
        │  • GitHub fork (gh CLI or web)    │
        │  • Clone to ~/.config/nvim        │
        │  • Configure upstream remote      │
        └───────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────┐
        │  Phase 3: Install Dependencies    │
        │  • Core: Neovim, Git, Node, Python│
        │  • Tools: ripgrep, fd, lazygit    │
        │  • Fonts: Nerd Font patched       │
        │  • Claude Code validates all      │
        └───────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────┐
        │  Phase 4: First Launch Bootstrap  │
        │  • Launch Neovim (nvim)           │
        │  • lazy.nvim auto-install         │
        │  • Plugin downloads and setup     │
        │  • Health check (:checkhealth)    │
        └───────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────┐
        │  Phase 5: Customize and Sync      │
        │  • Create feature branch          │
        │  • Add personal modifications     │
        │  • Sync with upstream updates     │
        └───────────────────────────────────┘
                            │
                            ▼
                     ✓ Complete!
```

**Estimated Time**:
- Quick installation (all dependencies present): 15-20 minutes
- Standard installation (some dependencies needed): 30-45 minutes
- Complete installation with customization: 1-2 hours

**Prerequisites**:
- Active internet connection
- Administrator/sudo access for installing system packages
- GitHub account (for forking repository)
- Basic familiarity with terminal commands

**Alternative Paths**:
- **Manual Installation**: If you prefer not to use Claude Code, see [INSTALLATION.md](INSTALLATION.md) for traditional setup instructions
- **Platform-Specific Guides**: See [docs/platform/](./platform/) for detailed platform-specific installation procedures

## Phase 1: Install Claude Code

### System Requirements

Before installing Claude Code, verify your system meets these requirements:

**Operating System:**
- macOS 10.15 or higher
- Ubuntu 20.04+ or Debian 10+
- Windows 10+ (with WSL 1, WSL 2, or Git for Windows)

**Hardware:**
- Minimum 4GB RAM (16GB recommended for optimal performance)
- Minimum 500MB disk space available
- Active internet connection

**Software:**
- Node.js 18.0 or higher (only required for npm installation method)
- Recommended shells: Bash, Zsh, or Fish

**Additional Notes:**
- Access must be from an Anthropic-supported country
- Some features require active Claude Console billing or Claude Pro/Max subscription

### Installation Methods

Claude Code offers multiple installation methods. The native installation is recommended for most users as it provides better stability and automatic updates.

#### Method 1: Native Installation (Recommended)

The native installation provides a self-contained executable without Node.js dependency and improved auto-updater stability.

**macOS/Linux/WSL:**
```bash
curl -fsSL https://claude.ai/install.sh | bash
```

**Windows PowerShell:**
```powershell
irm https://claude.ai/install.ps1 | iex
```

#### Method 2: Homebrew (macOS/Linux)

If you use Homebrew package manager:
```bash
brew install --cask claude-code
```

#### Method 3: NPM Installation (Legacy)

This method is no longer recommended but is still supported:
```bash
npm install -g @anthropic-ai/claude-code
```

**IMPORTANT:** Never use `sudo npm install -g` as this leads to permission issues and security risks. If you need global npm packages without sudo, configure npm to use a user-owned directory.

**Migrating from npm to Native:**

If you previously installed via npm, you should migrate to the native installer:
```bash
claude migrate-installer
which claude  # Verify new installation location
claude doctor # Check installation health
```

### Authentication Setup

After installation, you need to authenticate Claude Code. There are several authentication options:

#### Option 1: Claude Console (Default)

This is the recommended authentication method for most users:

1. Launch Claude Code for the first time:
   ```bash
   claude
   ```

2. Claude Code will automatically initiate OAuth authentication

3. Your browser will open to console.anthropic.com

4. Sign in to the Claude Console

5. Grant permission for Claude Code to access your account

6. Claude Code will automatically create a dedicated "Claude Code" workspace for usage tracking

**Requirements:**
- Active billing setup in Claude Console
- No API key creation needed (handled automatically)

#### Option 2: Claude App Subscription

If you have a Claude Pro or Max subscription:

1. Launch Claude Code:
   ```bash
   claude
   ```

2. Select "Sign in with Claude App" during authentication

3. Complete the authentication process

This provides a unified subscription covering both Claude Code and the web interface.

#### Option 3: Environment Variable

For automation or CI/CD environments:
```bash
export ANTHROPIC_API_KEY="your-api-key"
```

Create an API key at console.anthropic.com and add the export command to your shell profile (`.bashrc`, `.zshrc`, etc.).

#### Option 4: Enterprise Platforms

For enterprise users with Amazon Bedrock or Google Vertex AI:
- Follow platform-specific configuration documentation
- Requires additional setup beyond standard authentication

### Verification and Testing

After installation and authentication, verify everything is working:

1. **Check Version:**
   ```bash
   claude --version
   ```
   This should display the current Claude Code version number.

2. **Run Diagnostic Tool:**
   ```bash
   claude doctor
   ```
   This command checks:
   - Installation type (native vs npm)
   - Version information
   - Authentication status
   - System compatibility
   - Available features

3. **Test Basic Functionality:**
   ```bash
   cd ~
   claude
   ```
   At the Claude Code prompt, try:
   ```
   Hello! Can you check if you're working correctly?
   ```
   Claude Code should respond with a friendly confirmation.

4. **Exit Claude Code:**
   Type `/quit` or press Ctrl+D to exit.

### Configuration Management

Claude Code handles most configuration automatically, but here are some useful settings:

**Auto-Updates (Default Behavior):**
- Claude Code automatically downloads and installs updates in the background
- Updates take effect on next startup
- No user intervention required

**Disable Auto-Updates (if needed):**
```bash
export DISABLE_AUTOUPDATER=1
```
Add this to your shell profile to make it permanent.

**Manual Update:**
```bash
claude update
```

**Credentials Storage:**
- Credentials are securely stored locally
- Default location: `~/.config/claude-code/auth.json`
- File permissions are automatically set to be user-readable only

**Permission Management:**
Within Claude Code, use the `/permissions` command to allow specific tools without repeated approval prompts. This is useful when you trust certain operations (like reading files in your project directory).

### Common Installation Issues

This section covers the most common installation problems and their solutions.

#### Windows WSL Issues

**Problem: OS/platform detection errors**

If you see errors about unsupported operating systems:
```bash
# Solution 1: Configure npm for Linux (if using npm method)
npm config set os linux

# Solution 2: Force installation (npm method)
npm install -g @anthropic-ai/claude-code --force --no-os-check
```

**Better Solution:** Use the native installation method instead:
```bash
curl -fsSL https://claude.ai/install.sh | bash
```

**Problem: Node not found errors in WSL**

Verify Node and npm are using Linux paths, not Windows paths:
```bash
which npm  # Should return /usr/... not /mnt/c/...
which node # Should also return a Linux path
```

If they return Windows paths (`/mnt/c/...`), install Node via a Linux package manager or nvm:
```bash
# Using nvm (recommended)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 18
nvm use 18
```

**Problem: nvm version conflicts in WSL**

Add nvm initialization to your shell config (`~/.bashrc` or `~/.zshrc`):
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

**Problem: JetBrains IDEs not detected on WSL2**

Option 1 - Configure Windows Firewall:
```powershell
# Get WSL2 IP address
wsl hostname -I

# Create firewall rule (adjust IP range to match your WSL network)
New-NetFirewallRule -DisplayName "Allow WSL2 Internal Traffic" -Direction Inbound -Protocol TCP -Action Allow -RemoteAddress 172.21.0.0/16 -LocalAddress 172.21.0.0/16
```

Option 2 - Use mirrored networking mode in `.wslconfig`:
```
[wsl2]
networkingMode=mirrored
```

**Problem: Slow search performance in WSL**

Solutions:
- Move projects from Windows filesystem (`/mnt/c/`) to Linux filesystem (`/home/`)
- Install system ripgrep: `sudo apt install ripgrep`
- Submit searches with specific directory/file type filters

#### npm Permission Issues

**Problem: Permission denied or EACCES errors**

**DO NOT** use `sudo npm install -g` (security risk)

**Solution 1 (Recommended):** Use native installation method:
```bash
curl -fsSL https://claude.ai/install.sh | bash
```

**Solution 2:** Configure npm to use user-owned directory for global packages:
```bash
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

#### Authentication Issues

**Problem: Repeated authentication failures**

Complete sign-out and clean login:
```bash
# Within Claude Code, sign out completely
/logout

# Or force clean login by removing auth file
rm -rf ~/.config/claude-code/auth.json

# Restart and re-authenticate
claude
```

**Problem: Billing/subscription errors**

- Verify you have an active Claude Console billing setup or Claude Pro/Max subscription
- Check your subscription status at console.anthropic.com or claude.ai/settings
- Ensure your payment method is current

#### Search/Discovery Issues

**Problem: Search functionality not working**

Install system ripgrep:

**macOS:**
```bash
brew install ripgrep
```

**Ubuntu/Debian:**
```bash
sudo apt install ripgrep
```

**Arch Linux:**
```bash
sudo pacman -S ripgrep
```

**Windows:**
```powershell
winget install BurntSushi.ripgrep.MSVC
```

#### Performance Issues

**Problem: High CPU/memory usage**

- Use `/compact` command regularly to trim context
- Close and restart Claude Code between major tasks
- Add large directories to `.gitignore` to exclude from indexing
- Ensure you have adequate RAM (16GB recommended)

**Problem: Commands hang or become unresponsive**

- Press Ctrl+C to cancel long-running operations
- Use `/clear` command to reset session context
- Restart Claude Code: exit with `/quit` and launch again
- Check `claude doctor` for system issues

### Getting Help

If you encounter issues not covered here:

1. **Built-in Help:**
   ```bash
   claude --help
   ```

2. **Diagnostic Tool:**
   ```bash
   claude doctor
   ```

3. **Bug Reports:**
   Within Claude Code, use the `/bug` command to generate a detailed bug report

4. **Official Documentation:**
   Visit https://docs.anthropic.com/claude-code for complete documentation

5. **Community Support:**
   GitHub Issues: https://github.com/anthropics/claude-code/issues

### Next: Fork and Clone Repository

Once Claude Code is installed and working, proceed to [Phase 2: Fork and Clone Repository](#phase-2-fork-and-clone-repository) to set up your Neovim configuration.

## Phase 2: Fork and Clone Repository

Now that Claude Code is installed, you will fork this Neovim configuration repository to your GitHub account and clone it to your local machine.

### Why Fork Instead of Clone Directly

Forking creates your own copy of the repository on GitHub, which allows you to:

- Make personal customizations without affecting the original repository
- Keep your modifications under version control
- Stay synchronized with upstream updates from the original repository
- Contribute improvements back to the upstream project if desired
- Maintain your configuration across multiple machines

**Important**: For configuration repositories, you should keep your main branch clean (tracking upstream) and make all personal customizations in feature branches.

### Option 1: GitHub CLI Method (Recommended)

The GitHub CLI provides the most streamlined workflow for forking and cloning in a single command.

#### Prerequisites

Install GitHub CLI if you haven't already:

**macOS:**
```bash
brew install gh
```

**Linux (Debian/Ubuntu):**
```bash
# Add GitHub CLI repository
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh
```

**Arch Linux:**
```bash
sudo pacman -S github-cli
```

**Windows:**
```powershell
winget install GitHub.cli
```

#### Authenticate with GitHub

```bash
gh auth login
```

Follow the prompts to authenticate via browser.

#### Fork and Clone with One Command

Replace `ORIGINAL-OWNER/neovim-config` with the actual repository you're forking:

```bash
# Fork and clone to ~/.config/nvim
gh repo fork ORIGINAL-OWNER/neovim-config --clone ~/.config/nvim
```

This single command:
1. Creates a fork in your GitHub account
2. Clones your fork to `~/.config/nvim`
3. Sets your fork as the `origin` remote
4. Automatically adds the original repository as the `upstream` remote

**Verify the remotes:**
```bash
cd ~/.config/nvim
git remote -v
```

You should see:
```
origin    https://github.com/YOUR-USERNAME/neovim-config.git (fetch)
origin    https://github.com/YOUR-USERNAME/neovim-config.git (push)
upstream  https://github.com/ORIGINAL-OWNER/neovim-config.git (fetch)
upstream  https://github.com/ORIGINAL-OWNER/neovim-config.git (push)
```

### Option 2: Manual Fork and Clone

If you prefer not to use GitHub CLI or need more control over the process:

#### Step 1: Fork via Web UI

1. Navigate to the repository on GitHub
2. Click the "Fork" button in the upper-right corner
3. Select your account as the destination
4. Click "Create fork"

#### Step 2: Clone Your Fork

```bash
# Clone to ~/.config/nvim
git clone https://github.com/YOUR-USERNAME/neovim-config.git ~/.config/nvim
cd ~/.config/nvim
```

#### Step 3: Add Upstream Remote

```bash
# Add the original repository as upstream
git remote add upstream https://github.com/ORIGINAL-OWNER/neovim-config.git

# Verify remotes
git remote -v
```

### Configure Main Branch to Track Upstream

This is a critical step that keeps your main branch synchronized with the original project:

```bash
# Switch to main branch (if not already there)
git checkout main

# Set upstream/main as the tracking branch
git branch -u upstream/main

# Verify tracking
git branch -vv
```

**Result**: Now `git pull` will pull from upstream (the original repository), not your fork. This keeps your main branch clean and synchronized with the source project.

### Workflow Diagram

Here's how the fork, clone, and upstream relationship works:

```
┌─────────────────────────────────────────────────────────────┐
│              GitHub: Original Repository                    │
│         (ORIGINAL-OWNER/neovim-config)                      │
│                    [upstream]                               │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ (fork via web or gh CLI)
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│             GitHub: Your Fork                               │
│          (YOUR-USERNAME/neovim-config)                      │
│                    [origin]                                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ (clone)
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│         Local Machine: ~/.config/nvim                       │
│                                                             │
│  • main branch tracks upstream/main                         │
│  • Feature branches for personal customizations            │
│  • Fetch from upstream, push to origin                     │
└─────────────────────────────────────────────────────────────┘
```

### Verify the Setup

Let's confirm everything is configured correctly:

1. **Check current directory:**
   ```bash
   pwd
   # Should output: /home/YOUR-USERNAME/.config/nvim
   ```

2. **Verify remotes:**
   ```bash
   git remote -v
   # Should show both origin (your fork) and upstream (original repo)
   ```

3. **Check branch tracking:**
   ```bash
   git branch -vv
   # Main branch should show it tracks upstream/main
   ```

4. **Test fetching from upstream:**
   ```bash
   git fetch upstream
   # Should successfully fetch from the original repository
   ```

### Security Best Practices

Before making any commits to your fork, set up `.gitignore` to prevent accidentally committing sensitive information:

1. **Verify `.gitignore` exists:**
   ```bash
   cat ~/.config/nvim/.gitignore
   ```

2. **Ensure these patterns are included:**
   ```gitignore
   # Secrets and credentials
   .ssh/
   *.key
   *.pem
   *_token
   credentials.json
   secrets/

   # Personal configuration
   local_config.lua
   personal_settings.lua

   # System files
   .DS_Store
   Thumbs.db

   # Editor artifacts
   *.swp
   *.swo
   *~
   ```

3. **If you need to add patterns, edit .gitignore:**
   ```bash
   # You can ask Claude Code to help with this!
   claude
   ```
   Then in Claude Code:
   ```
   Can you help me review and update my .gitignore file to ensure no sensitive files are tracked?
   ```

### Common Issues and Solutions

**Problem: Target directory already exists**

If `~/.config/nvim` already contains files:
```bash
# Backup existing configuration
mv ~/.config/nvim ~/.config/nvim.backup

# Then proceed with fork and clone
gh repo fork ORIGINAL-OWNER/neovim-config --clone ~/.config/nvim
```

**Problem: Permission denied (publickey)**

Your SSH keys may not be configured:
```bash
# Check for existing SSH keys
ls -la ~/.ssh

# If no keys exist, generate new SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Add to SSH agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Add public key to GitHub
gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)"
```

**Problem: Upstream remote already exists**

If you get an error that upstream already exists:
```bash
# Remove existing upstream
git remote remove upstream

# Re-add with correct URL
git remote add upstream https://github.com/ORIGINAL-OWNER/neovim-config.git
```

### Next: Install Dependencies

With your repository forked and cloned, proceed to [Phase 3: Install Dependencies](#phase-3-install-dependencies) to set up all required software.

## Phase 3: Install Dependencies

This Neovim configuration requires several dependencies to function properly. Claude Code can help automate the dependency checking and provide platform-specific installation commands.

### Automated Dependency Checking with Claude Code

The repository includes a dependency checking script that Claude Code can execute for you:

**Option 1: Let Claude Code run the check**

Launch Claude Code in your Neovim configuration directory:
```bash
cd ~/.config/nvim
claude
```

Then ask:
```
Can you run the dependency checking script (scripts/check-dependencies.sh) and help me install any missing dependencies for my platform?
```

Claude Code will:
1. Execute the dependency checking script
2. Identify missing dependencies
3. Detect your platform (Arch, Debian/Ubuntu, macOS, Windows)
4. Provide exact installation commands for your system
5. Verify successful installation

**Option 2: Run the script manually**

```bash
cd ~/.config/nvim
bash scripts/check-dependencies.sh
```

The script will show which dependencies are installed and which are missing.

### Core Dependencies

These dependencies are required for basic Neovim functionality:

#### Neovim >= 0.9.0

**Purpose**: Modern text editor with LSP and plugin support

**Check version:**
```bash
nvim --version
```

**Installation:**

**Arch Linux:**
```bash
sudo pacman -S neovim
```

**Debian/Ubuntu:**
```bash
# Ubuntu 22.04+ has recent Neovim
sudo apt update
sudo apt install neovim

# For older versions, use PPA or AppImage
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo apt update
sudo apt install neovim
```

**macOS:**
```bash
brew install neovim
```

**Windows:**
```powershell
winget install Neovim.Neovim
# Or via Scoop
scoop install neovim
```

#### Git

**Purpose**: Version control for configuration management

**Check version:**
```bash
git --version
```

**Installation:**

**Arch Linux:**
```bash
sudo pacman -S git
```

**Debian/Ubuntu:**
```bash
sudo apt install git
```

**macOS:**
```bash
brew install git
```

**Windows:**
```powershell
winget install Git.Git
```

#### Node.js >= 18.0

**Purpose**: Required by many LSP servers and plugins

**Check version:**
```bash
node --version
```

**Installation:**

**Arch Linux:**
```bash
sudo pacman -S nodejs npm
```

**Debian/Ubuntu:**
```bash
# Using NodeSource repository for recent versions
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

**macOS:**
```bash
brew install node
```

**Windows:**
```powershell
winget install OpenJS.NodeJS.LTS
```

#### Python 3 and pip3

**Purpose**: Required for Python-based plugins and tools

**Check version:**
```bash
python3 --version
pip3 --version
```

**Installation:**

**Arch Linux:**
```bash
sudo pacman -S python python-pip
```

**Debian/Ubuntu:**
```bash
sudo apt install python3 python3-pip
```

**macOS:**
```bash
brew install python3
```

**Windows:**
```powershell
winget install Python.Python.3.12
```

#### Nerd Font

**Purpose**: Display icons and glyphs in Neovim UI

**Recommended**: RobotoMono Nerd Font

**Installation:**

**Arch Linux:**
```bash
sudo pacman -S ttf-roboto-mono-nerd
```

**Debian/Ubuntu:**
```bash
# Manual installation
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/RobotoMono.zip
unzip RobotoMono.zip
rm RobotoMono.zip
fc-cache -fv
```

**macOS:**
```bash
brew tap homebrew/cask-fonts
brew install --cask font-roboto-mono-nerd-font
```

**Windows:**
```powershell
# Download from https://www.nerdfonts.com/font-downloads
# Install RobotoMono NF and configure terminal to use it
```

After installation, configure your terminal to use the Nerd Font.

### Recommended Tools

These tools enhance the Neovim experience but are not strictly required:

#### ripgrep (rg)

**Purpose**: Extremely fast text search (used by Telescope and grep)

**Installation:**

**Arch Linux:**
```bash
sudo pacman -S ripgrep
```

**Debian/Ubuntu:**
```bash
sudo apt install ripgrep
```

**macOS:**
```bash
brew install ripgrep
```

**Windows:**
```powershell
winget install BurntSushi.ripgrep.MSVC
```

#### fd

**Purpose**: Fast file finding (alternative to `find`)

**Installation:**

**Arch Linux:**
```bash
sudo pacman -S fd
```

**Debian/Ubuntu:**
```bash
sudo apt install fd-find
# On Ubuntu, create symlink
sudo ln -s $(which fdfind) /usr/local/bin/fd
```

**macOS:**
```bash
brew install fd
```

**Windows:**
```powershell
winget install sharkdp.fd
```

#### lazygit

**Purpose**: Terminal UI for Git operations

**Installation:**

**Arch Linux:**
```bash
sudo pacman -S lazygit
```

**Debian/Ubuntu:**
```bash
# Add PPA
sudo add-apt-repository ppa:lazygit-team/release
sudo apt update
sudo apt install lazygit
```

**macOS:**
```bash
brew install lazygit
```

**Windows:**
```powershell
winget install JesseDuffield.lazygit
```

#### fzf

**Purpose**: Fuzzy finder for files and text

**Installation:**

**Arch Linux:**
```bash
sudo pacman -S fzf
```

**Debian/Ubuntu:**
```bash
sudo apt install fzf
```

**macOS:**
```bash
brew install fzf
```

**Windows:**
```powershell
winget install junegunn.fzf
```

### Using Claude Code for Installation

Instead of running individual commands, you can ask Claude Code to install everything:

```bash
cd ~/.config/nvim
claude
```

**Example prompts:**

**For Arch Linux:**
```
I'm on Arch Linux. Can you help me install all required and recommended dependencies for this Neovim configuration? Run the dependency checker first, then install what's missing.
```

**For Debian/Ubuntu:**
```
I'm on Ubuntu 22.04. Please check my dependencies and install any missing packages needed for this Neovim setup.
```

**For macOS:**
```
I'm on macOS. Can you verify I have Homebrew, then install all dependencies for this Neovim configuration?
```

Claude Code will:
1. Detect your platform
2. Run the dependency checker
3. Show you what's missing
4. Provide and execute installation commands (with your approval)
5. Verify each installation succeeded

### Verification

After installing dependencies, verify everything is ready:

**Run the dependency checker:**
```bash
bash ~/.config/nvim/scripts/check-dependencies.sh
```

**Expected output (all dependencies met):**
```
Checking Neovim Configuration Dependencies...
==============================================

Core Dependencies:
------------------
✓ Neovim >= 0.9.0: 0.10.0
✓ Git: 2.43.0
✓ Node.js >= 18.0: 20.11.0
✓ Python 3: 3.11.6
✓ pip3 (Python package manager): 23.3.1

Recommended Tools:
------------------
✓ ripgrep (fast search): installed (recommended)
✓ fd (fast file finding): installed (recommended)
✓ lazygit (Git UI): installed (recommended)
✓ fzf (fuzzy finder): installed (recommended)

Font Check:
-----------
✓ Nerd Font detected

==============================================
Summary:
✓ All core dependencies met
✓ All recommended tools installed

Ready to proceed with Neovim installation!
```

### Optional Dependencies (Advanced Features)

For specialized features, you may need additional dependencies. See [Advanced Setup](ADVANCED_SETUP.md) for:

- **LaTeX Support**: TeX Live, latexmk, PDF viewers
- **Lean 4 Support**: Lean theorem prover, elan version manager
- **Jupyter Support**: Jupyter notebook, ipykernel
- **Email Integration**: mbsync, cyrus-sasl-xoauth2

### Troubleshooting Dependency Issues

**Problem: Python not found or wrong version**

Make sure Python 3 is installed and aliased correctly:
```bash
# Check if python3 works
python3 --version

# On some systems, add alias to shell config
echo 'alias python=python3' >> ~/.bashrc
echo 'alias pip=pip3' >> ~/.bashrc
source ~/.bashrc
```

**Problem: Node.js version too old**

Use nvm (Node Version Manager) to install a newer version:
```bash
# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc

# Install and use Node 20
nvm install 20
nvm use 20
nvm alias default 20
```

**Problem: Nerd Font icons not displaying**

1. Verify font is installed: `fc-list | grep -i nerd`
2. Configure terminal to use the Nerd Font
3. Restart terminal
4. Test in Neovim: `:echo ""` (should show a folder icon)

**Problem: Command not found after installation**

The PATH may need updating:
```bash
# Check where the command was installed
which <command>

# Add to PATH if needed (example for user-local binaries)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Next: Launch Neovim and Bootstrap

With all dependencies installed, proceed to [Phase 4: Launch Neovim and Bootstrap](#phase-4-launch-neovim-and-bootstrap) for first-time setup.

## Phase 4: Launch Neovim and Bootstrap

With dependencies installed and the repository cloned, you're ready to launch Neovim for the first time. The configuration includes an automatic bootstrap process that will install and configure all plugins.

### First Launch

Simply launch Neovim:

```bash
cd ~/.config/nvim
nvim
```

### What Happens During Bootstrap

The bootstrap process (defined in `lua/neotex/bootstrap.lua`) automatically:

1. **Cleans Up**: Removes any temporary tree-sitter build directories
2. **Installs lazy.nvim**: Downloads the plugin manager if not present
3. **Validates Lock File**: Checks and fixes `lazy-lock.json` if corrupted
4. **Sets Up Plugins**: Initializes lazy.nvim with all plugin specifications
5. **Downloads Plugins**: Fetches and installs all configured plugins (2-5 minutes)
6. **Configures LSP Servers**: Sets up Mason for language server management

**Expected Timeline**:
- Initial lazy.nvim install: 5-10 seconds
- Plugin downloads: 2-5 minutes (depends on internet speed)
- First complete launch: 3-6 minutes total

**What You'll See**:
- A popup window showing plugin installation progress
- Download progress bars for each plugin
- Status messages as plugins are compiled and configured
- Some plugins may show brief notifications during first load

**Tip**: Don't close Neovim until all plugins show as installed in the lazy.nvim UI.

### Health Check and Validation

After the first successful launch and all plugins are installed:

1. **Run Health Check**:
   ```vim
   :checkhealth
   ```

2. **What to Look For**:

   **Green (OK)** - Everything is working:
   ```
   - OK: Neovim version 0.10.0
   - OK: Node.js version v20.11.0
   - OK: Python 3.11.6
   - OK: Git version 2.43.0
   ```

   **Yellow (WARNING)** - Recommended features missing:
   ```
   - WARNING: ripgrep not found (fast search will be unavailable)
   - WARNING: fd not found (fast file finding unavailable)
   ```
   These are non-critical; install them later if desired.

   **Red (ERROR)** - Critical issues:
   ```
   - ERROR: Node.js not found (LSP servers will not work)
   - ERROR: Python provider not found
   ```
   These must be fixed. See troubleshooting below.

### Common First-Launch Issues

**Issue: "Error executing vim.schedule lua callback"**

**Cause**: Plugin dependency issues or corrupted lockfile

**Solution**:
```vim
:Lazy clear
:Lazy sync
```

Then restart Neovim.

**Issue: LSP servers not starting**

**Cause**: Mason hasn't installed language servers yet

**Solution**:
1. Open Mason: `:Mason`
2. Press `i` on desired language servers to install
3. Wait for installation to complete
4. Restart Neovim

**Issue: Tree-sitter parser errors**

**Cause**: Parser compilation issues

**Solution**:
```vim
:TSUpdate
```

Wait for parsers to rebuild, then restart Neovim.

**Issue: Icons showing as boxes or question marks**

**Cause**: Nerd Font not configured in terminal

**Solution**:
1. Verify font installed: `fc-list | grep -i nerd`
2. Configure terminal emulator to use Nerd Font
3. Restart terminal
4. Restart Neovim

**Issue: Slow startup or high CPU usage**

**Cause**: Plugin indexing on first launch

**Solution**: This is normal for first launch. Subsequent starts will be much faster (typically under 100ms).

### Using Claude Code for Troubleshooting

If you encounter errors during first launch, Claude Code can help diagnose and fix issues:

```bash
# In a separate terminal (keep Neovim running or save the error)
cd ~/.config/nvim
claude
```

**Example prompts**:

**For health check issues:**
```
I ran :checkhealth in Neovim and got these errors: [paste output]
Can you help me fix them?
```

**For LSP errors:**
```
I'm getting "LSP[X] client has shut down" errors. Can you check my LSP configuration and help me fix it?
```

**For plugin errors:**
```
Plugin installation failed with: [paste error]
Can you help me troubleshoot and fix this?
```

Claude Code will:
- Parse the error messages
- Identify the root cause
- Suggest specific fixes
- Execute commands to resolve issues (with your approval)

### Testing Core Functionality

After successful launch and health check, test core features:

**1. File Navigation:**
```vim
" Open file finder
<Space>ff

" Should show Telescope file picker with fuzzy search
```

**2. LSP (if in a code file):**
```vim
" Open a code file, e.g., init.lua
:e lua/neotex/init.lua

" Trigger completion
i (insert mode) + <Ctrl-Space>

" Should show completion suggestions
```

**3. Git Integration:**
```vim
" Open lazy git UI (if lazygit installed)
<Space>gg

" Should show lazygit terminal UI
```

**4. Tree-sitter Syntax:**
- Open any source file
- Syntax highlighting should be accurate and colorful
- Code folding should work with `za`

### Next: Customization and Configuration

With Neovim successfully installed and validated, proceed to [Phase 5: Customization and Configuration](#phase-5-customization-and-configuration) to learn how to personalize your setup.

## Phase 5: Customization and Configuration

Now that your Neovim configuration is working, you can add personal customizations while maintaining the ability to pull updates from upstream.

### Feature Branch Strategy

**Golden Rule**: Never commit personal customizations directly to the main branch.

Create feature branches for all personal changes:

```bash
cd ~/.config/nvim

# Ensure main is up-to-date
git checkout main
git pull upstream main

# Create feature branch for your customization
git checkout -b feature-my-custom-theme

# Make changes, then commit
git add .
git commit -m "Add personal theme customization"

# Push to your fork
git push origin feature-my-custom-theme
```

### Recommended Branch Naming Conventions

- `feature-<description>`: New features or additions
  - Example: `feature-custom-keybindings`
  - Example: `feature-golang-setup`
- `config-<description>`: Configuration changes
  - Example: `config-theme-nord`
  - Example: `config-lsp-settings`
- `fix-<description>`: Bug fixes
  - Example: `fix-telescope-lag`

### Types of Customizations

#### 1. Personal Keybindings

Create a personal keymap file:

```bash
# Create personal config file
nvim lua/neotex/personal_keymaps.lua
```

Add your keymaps:

```lua
local map = vim.keymap.set

-- Personal keybindings
map("n", "<leader>p", ":MyCustomCommand<CR>", { desc = "My custom command" })
map("n", "<C-s>", ":w<CR>", { desc = "Quick save" })

-- Override defaults if needed
map("n", "<leader>ff", ":Telescope find_files hidden=true<CR>", { desc = "Find files including hidden" })
```

Load it in `init.lua`:

```lua
-- Add to lua/neotex/init.lua
require("neotex.personal_keymaps")
```

#### 2. Theme Customization

Create personal theme overrides:

```bash
nvim lua/neotex/personal_theme.lua
```

```lua
-- Personal theme customization
vim.cmd([[
  highlight Normal guibg=#1a1a1a
  highlight Comment gui=italic
  highlight Function gui=bold
]])
```

#### 3. Plugin Additions

To add new plugins, create a personal plugin file:

```bash
nvim lua/neotex/plugins/personal.lua
```

```lua
return {
  {
    "your-username/your-plugin",
    config = function()
      require("your-plugin").setup({
        -- plugin configuration
      })
    end,
  },
}
```

Lazy.nvim automatically loads all files in the `plugins/` directory.

#### 4. LSP Server Additions

To add language servers for your specific languages:

```vim
:Mason
```

Press `i` on the server you want to install. The configuration will be automatically loaded via Mason's integration.

### Staying Synchronized with Upstream

Regularly pull updates from the original repository:

```bash
# Fetch latest changes from upstream
git fetch upstream

# Switch to main branch
git checkout main

# Merge upstream changes
git merge upstream/main

# Push updated main to your fork
git push origin main
```

**Best Practice**: Do this weekly or monthly to stay current with improvements and bug fixes.

### Merging Upstream Updates into Feature Branches

When upstream has updates and you have feature branches:

```bash
# Update main first
git checkout main
git pull upstream main
git push origin main

# Update your feature branch
git checkout feature-my-custom-theme
git merge main

# If conflicts occur, resolve them
# Git will mark conflict areas in files
nvim <conflicted-file>

# After resolving
git add <resolved-files>
git commit -m "Merge upstream updates"
git push origin feature-my-custom-theme
```

### Using Claude Code for Merge Conflicts

Claude Code can help resolve merge conflicts:

```bash
cd ~/.config/nvim
claude
```

**Prompt**:
```
I have merge conflicts after pulling upstream updates. The conflicts are in [file names]. Can you help me understand the conflicts and resolve them while preserving my customizations?
```

Claude Code will:
- Read the conflicted files
- Explain what each side changed
- Suggest resolution strategies
- Help you merge changes appropriately

### Contributing Back to Upstream

If you create a useful improvement that others might benefit from:

1. **Create a clean feature branch from main:**
   ```bash
   git checkout main
   git pull upstream main
   git checkout -b feature-useful-improvement
   ```

2. **Make focused changes** (one feature per branch)

3. **Commit with clear messages**

4. **Push to your fork:**
   ```bash
   git push origin feature-useful-improvement
   ```

5. **Create pull request:**
   ```bash
   gh pr create --base main --head feature-useful-improvement
   ```
   Or use GitHub web UI to create PR from your fork

### Backup and Recovery

**Backup your customizations:**

```bash
# Your personal changes are in your fork on GitHub
# To backup locally as well:
git bundle create nvim-config-backup.bundle --all

# Store nvim-config-backup.bundle somewhere safe
```

**Restore from backup:**

```bash
# Clone from bundle
git clone nvim-config-backup.bundle ~/.config/nvim

# Re-add remotes
cd ~/.config/nvim
git remote add origin https://github.com/YOUR-USERNAME/neovim-config.git
git remote add upstream https://github.com/ORIGINAL-OWNER/neovim-config.git
```

### Next Steps

You now have a fully functional, personalized Neovim configuration! To learn more:

- Explore [Keybindings Reference](../README.md#keybindings)
- Set up advanced features in [Advanced Setup](ADVANCED_SETUP.md)
- Read about the [Architecture](ARCHITECTURE.md)
- Check the [Glossary](GLOSSARY.md) for technical terms

## Navigation

- **Parent Guide**: [Main README](../README.md)
- **Related Documentation**:
  - [Manual Installation Guide](INSTALLATION.md)
  - [Advanced Setup](ADVANCED_SETUP.md)
  - [Platform Guides](./platform/)
  - [Glossary](GLOSSARY.md)
