# Claude Code Installation and Setup Process

## Metadata
- **Date**: 2025-11-04
- **Agent**: research-specialist
- **Topic**: Claude Code Installation and Setup Process
- **Report Type**: best practices
- **Complexity Level**: 3

## Executive Summary

Claude Code is an agentic terminal-based coding tool from Anthropic that requires Node.js 18+ (for npm installation) or can be installed as a native binary (recommended). Installation is straightforward via curl script, Homebrew, or npm, followed by OAuth authentication through the Claude Console with active billing. The native installation method provides improved auto-updater stability and eliminates Node.js dependency. Common issues include Windows WSL configuration errors, permission problems with npm global installs, and IDE integration challenges on WSL2.

## Findings

### 1. System Requirements

**Operating System Support:**
- macOS 10.15 or higher
- Ubuntu 20.04+/Debian 10+
- Windows 10+ (with WSL 1, WSL 2, or Git for Windows)

**Hardware & Software Requirements:**
- Minimum 4GB RAM (16GB recommended for optimal performance)
- Node.js 18.0 or higher (required only for npm installation method)
- Internet connection for authentication and AI processing
- Recommended shells: Bash, Zsh, or Fish
- Minimum 500MB disk space available
- Access from Anthropic-supported countries

**Additional Dependencies:**
- `ripgrep` for search functionality (typically included; can be installed separately if search fails)
- Alpine Linux requires `libgcc`, `libstdc++`, and `ripgrep` installation

### 2. Installation Methods

**Native Installation (Recommended)**

The native installation provides a self-contained executable without Node.js dependency and improved auto-updater stability.

**macOS/Linux/WSL:**
```bash
curl -fsSL https://claude.ai/install.sh | bash
```

**Windows PowerShell:**
```powershell
irm https://claude.ai/install.ps1 | iex
```

**Homebrew (macOS/Linux):**
```bash
brew install --cask claude-code
```

**NPM Installation (Legacy Method)**
```bash
npm install -g @anthropic-ai/claude-code
```

**CRITICAL:** Avoid using `sudo npm install -g` as this leads to permission issues and security risks.

**Migration from npm to Native:**
If previously installed via npm, migrate to native installer:
```bash
claude migrate-installer
which claude  # Verify installation location
claude doctor # Check installation health
```

### 3. Authentication Options

**Option 1: Claude Console (Default)**
- OAuth authentication through console.anthropic.com
- Requires active billing
- Creates dedicated "Claude Code" workspace automatically for usage tracking
- No API key creation needed for Claude Code workspace

**Option 2: Claude App Subscription**
- Claude Pro or Max plan subscription
- Provides unified subscription covering both Claude Code and web interface

**Option 3: Enterprise Platforms**
- Amazon Bedrock integration
- Google Vertex AI integration
- Requires platform-specific configuration (reference third-party integration documentation)

**Environment Variable Method:**
```bash
export ANTHROPIC_API_KEY="your-api-key"
```

### 4. Initial Setup Workflow

**Step 1: Install Claude Code**
Use one of the installation methods above (native installation recommended).

**Step 2: Navigate to Project Directory**
```bash
cd your-awesome-project
```

**Step 3: Launch Claude Code**
```bash
claude
```

**Step 4: Complete Authentication**
The OAuth process will launch automatically. Complete authentication through your selected method (Console, App subscription, or Enterprise platform).

**Step 5: Verify Installation**
```bash
claude --version  # Check version
claude doctor     # Verify installation health
```

**Installation Type Check:**
```bash
claude doctor
```
This command checks installation type (native vs npm) and version information.

### 5. Configuration and Management

**Auto-Updates (Default Behavior):**
- Claude Code automatically downloads and installs updates in the background
- Updates take effect on next startup
- No user intervention required

**Disable Auto-Updates:**
```bash
export DISABLE_AUTOUPDATER=1
```

**Manual Update:**
```bash
claude update
```

**Credentials Storage:**
- Credentials are securely stored locally
- Default location: `~/.config/claude-code/auth.json`

**Permission Management:**
Use the `/permissions` command within Claude Code to allow specific tools without repeated approval prompts.

### 6. Common Installation Issues and Troubleshooting

**Windows WSL Issues**

**Problem: OS/platform detection errors**
```bash
# Solution 1: Configure npm for Linux
npm config set os linux

# Solution 2: Force installation with OS check bypass
npm install -g @anthropic-ai/claude-code --force --no-os-check
```

**Problem: Node not found errors in WSL**
```bash
# Verify Node/npm are using Linux paths
which npm  # Should return /usr/... not /mnt/c/...
which node

# If using Windows paths, install Node via package manager or nvm
```

**Problem: nvm version conflicts in WSL**
Add nvm initialization to shell config (`~/.bashrc` or `~/.zshrc`):
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

**Note:** Avoid disabling Windows PATH importing as it breaks calling Windows executables.

**Problem: JetBrains IDEs not detected on WSL2**

Option 1 - Configure Windows Firewall:
```powershell
# Get WSL2 IP address
wsl hostname -I

# Create firewall rule (adjust IP range as needed)
New-NetFirewallRule -DisplayName "Allow WSL2 Internal Traffic" -Direction Inbound -Protocol TCP -Action Allow -RemoteAddress 172.21.0.0/16 -LocalAddress 172.21.0.0/16
```

Option 2 - Use mirrored networking mode in `.wslconfig`:
```
[wsl2]
networkingMode=mirrored
```

**Problem: Slow search performance in WSL**
- Submit searches with specific directory/file type filters
- Move projects from Windows filesystem (`/mnt/c/`) to Linux filesystem (`/home/`)
- Install system ripgrep if not available

**npm Permission Issues**

**Problem: Permission denied or EACCES errors**
- DO NOT use `sudo npm install -g` (security risk)
- Use native installation method instead
- Or configure npm to use user-owned directory for global packages

**Authentication Issues**

**Problem: Repeated authentication failures**
```bash
# Sign out completely
/logout

# Force clean login by removing auth file
rm -rf ~/.config/claude-code/auth.json

# Restart and re-authenticate
claude
```

**Performance Issues**

**Problem: High CPU/memory usage**
- Use `/compact` command regularly to trim context
- Close and restart Claude Code between major tasks
- Add large directories to `.gitignore` to exclude from indexing

**Problem: Commands hang or become unresponsive**
- Press Ctrl+C to cancel operations
- Use `/clear` command to reset session context
- Restart Claude Code

**Search/Discovery Issues**

**Problem: Search functionality not working**
Install system ripgrep:
```bash
# macOS
brew install ripgrep

# Ubuntu/Debian
sudo apt install ripgrep

# Windows
winget install BurntSushi.ripgrep.MSVC
```

Set environment variable to use system ripgrep:
```bash
export USE_BUILTIN_RIPGREP=0
```

**IDE Integration Issues**

**Problem: ESC key not working in JetBrains terminals**
- Settings → Tools → Terminal
- Uncheck "Move focus to the editor with Escape"

**Problem: Git Bash on Windows shows "Raw mode is not supported"**
- Specify bash path if using portable Git installation
- Consider using WSL2 or native Windows installation instead

**Installation Corruption**

**Problem: Segmentation faults or unpredictable behavior**
- Indicates mixed or outdated installation
- Solution: Complete reinstall

```bash
# Remove existing installation
npm uninstall -g @anthropic-ai/claude-code  # If installed via npm

# Fresh install using native method
curl -fsSL https://claude.ai/install.sh | bash

# Verify installation
claude doctor
```

**Note:** Up to 40% of crashes and unexpected behaviors stem from corrupted installations or permission errors that a fresh reinstall can resolve.

### 7. Diagnostic Tools

**Built-in Diagnostic Commands:**

```bash
# Check installation health
claude doctor

# Report bugs with diagnostic information
/bug

# Verbose logging for troubleshooting
claude --verbose

# Model Context Protocol debugging
claude --mcp-debug
```

**Session Management Commands:**

```bash
# Reset context to prevent confused outputs
/clear

# Compact context to reduce memory usage
/compact

# Sign out of current session
/logout
```

### 8. First-Time User Workflow

**Recommended First Steps:**

1. **Install using native method** (best stability)
2. **Verify installation** with `claude doctor`
3. **Navigate to a test project** (start with a small codebase)
4. **Launch Claude Code** with `claude` command
5. **Complete OAuth authentication**
6. **Test basic functionality:**
   - Ask Claude to explain a file
   - Request simple code changes
   - Test git workflow commands
7. **Configure permissions** using `/permissions` for frequently used tools
8. **Learn keyboard shortcuts** and built-in commands
9. **Join Claude Developers Discord** for community support

**Getting Help:**

- Use `/bug` command within Claude Code to report issues
- Run `/doctor` to check installation health
- Check GitHub repository: https://github.com/anthropics/claude-code
- Join Claude Developers Discord for community support
- Consult official documentation: https://docs.claude.com/en/docs/claude-code

### 9. Platform-Specific Recommendations

**macOS Users:**
- Homebrew installation is cleanest method
- Native installation provides best auto-update experience

**Windows Users:**
- Native Windows installation (PowerShell/CMD) now preferred over WSL2
- WSL2 remains available for Linux-based workflows
- Git Bash can work but may have limitations

**Linux Users:**
- Native installation recommended over npm
- Ensure ripgrep is installed via package manager
- Check shell configuration for proper PATH setup

**WSL Users:**
- WSL2 recommended over WSL1
- Use Linux filesystem (`/home/`) for best performance
- Configure firewall rules for IDE integration
- Ensure Node/npm use Linux paths, not Windows paths

### 10. Model Selection Considerations

**Claude 3.5 Sonnet (Recommended):**
- Full reasoning capabilities
- Deep context understanding
- Comprehensive code analysis
- Suitable for serious development work

**Claude 3.5 Haiku (Limited Use):**
- Reduced reasoning capabilities
- Limited context understanding
- Simplified code analysis
- Suitable only for basic single-file edits
- NOT recommended for complex development tasks

## Recommendations

### 1. Installation Best Practices

**Use Native Installation Method**
- Eliminates Node.js dependency
- Provides improved auto-updater stability
- Reduces permission issues
- Recommended by Anthropic as the default installation method

**Migration Path:**
If currently using npm installation:
1. Run `claude migrate-installer` to switch to native
2. Verify with `which claude` (should point to native binary)
3. Run `claude doctor` to confirm successful migration

**Avoid Common Pitfalls:**
- Never use `sudo npm install -g` (causes permission issues)
- Don't mix installation methods (leads to conflicts)
- Keep auto-updates enabled unless specific reason to disable

### 2. WSL Configuration for Windows Users

**Optimal WSL Setup:**
- Use WSL2 for best performance
- Store projects in Linux filesystem (`/home/username/projects`) not Windows filesystem (`/mnt/c/`)
- Configure nvm in shell config for consistent Node.js access
- Install ripgrep via apt for reliable search functionality

**IDE Integration:**
- Configure Windows Firewall rules for WSL2 networking
- Or use mirrored networking mode in `.wslconfig`
- Test IDE detection with `claude doctor`

### 3. Troubleshooting Strategy

**First Steps for Any Issue:**
1. Run `claude doctor` to check installation health
2. Try `claude --verbose` for detailed logging
3. Use `/clear` to reset context if behavior seems confused
4. Check GitHub issues for known problems

**For Persistent Issues:**
1. Complete fresh reinstall (uninstall → reinstall with native method)
2. Remove authentication file: `rm -rf ~/.config/claude-code/auth.json`
3. Verify system requirements (Node.js 18+, 4GB+ RAM)
4. Use `/bug` command to report with diagnostic information

**Performance Optimization:**
- Use `/compact` regularly during long sessions
- Restart between major tasks
- Add large directories to `.gitignore`
- Filter searches with specific directory/file type parameters

### 4. Security and Permission Management

**Authentication Security:**
- Credentials stored locally in `~/.config/claude-code/auth.json`
- Use `/logout` before switching accounts
- Never share authentication files

**Permission Best Practices:**
- Use `/permissions` command to grant tool access
- Review and revoke permissions periodically
- Understand what each permission allows before granting

### 5. First-Time User Onboarding

**Recommended Learning Path:**
1. Start with small, familiar project
2. Use Claude for simple explanations before code changes
3. Test git workflow commands in safe branch
4. Gradually increase complexity of requests
5. Learn built-in commands (`/help`, `/permissions`, `/compact`)
6. Join Discord community for tips and support

**Best Practices:**
- Ask Claude about its capabilities (has built-in documentation access)
- Use specific, focused requests initially
- Review changes before accepting them
- Keep context manageable with `/clear` and `/compact`

### 6. Model Selection Strategy

**For Production Work:**
- Use Claude 3.5 Sonnet (default and recommended)
- Provides full reasoning and context understanding
- Suitable for complex multi-file changes

**For Simple Tasks:**
- Claude 3.5 Haiku acceptable for basic single-file edits only
- Not recommended for refactoring or architectural decisions
- Use Sonnet when in doubt

### 7. Update Management

**Recommended Configuration:**
- Keep auto-updates enabled (default)
- Updates install in background, take effect on next launch
- Monitor release notes for breaking changes

**Manual Control:**
- Set `DISABLE_AUTOUPDATER=1` only if needed for specific environment
- Use `claude update` for immediate manual updates
- Run `claude doctor` after updates to verify health

## References

### Official Documentation
- Claude Code Setup Guide: https://docs.claude.com/en/docs/claude-code/setup
- Claude Code Troubleshooting: https://docs.claude.com/en/docs/claude-code/troubleshooting
- GitHub Repository: https://github.com/anthropics/claude-code
- Claude Console: https://console.anthropic.com

### Installation Scripts
- macOS/Linux/WSL Install Script: https://claude.ai/install.sh
- Windows PowerShell Install Script: https://claude.ai/install.ps1

### Community Resources
- Claude Developers Discord: (referenced in documentation)
- Bug Reporting: Use `/bug` command within Claude Code

### Third-Party Guides
- ClaudeLog Installation Guide: https://claudelog.com/install-claude-code/
- ClaudeLog Troubleshooting: https://claudelog.com/troubleshooting/
- ITECS Windows Guide: https://itecsonline.com/post/how-to-install-claude-code-on-windows
- ITECS Ubuntu Guide: https://itecsonline.com/post/how-to-install-claude-code-on-ubuntu-linux-complete-guide-2025

### Installation Commands Referenced
- Native Installation (Line references to curl command: macOS/Linux/WSL section)
- PowerShell Installation (Line references to irm command: Windows section)
- Homebrew Installation (Line references to brew command: Alternative methods)
- npm Installation (Line references to npm install: Legacy method section)
- Migration Command (Line references to migrate-installer: Migration section)
- Diagnostic Commands (Line references throughout troubleshooting sections)
