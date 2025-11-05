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

## Navigation

- **Parent Guide**: [Main README](../README.md)
- **Related Documentation**:
  - [Manual Installation Guide](INSTALLATION.md)
  - [Advanced Setup](ADVANCED_SETUP.md)
  - [Platform Guides](./platform/)
  - [Glossary](GLOSSARY.md)
