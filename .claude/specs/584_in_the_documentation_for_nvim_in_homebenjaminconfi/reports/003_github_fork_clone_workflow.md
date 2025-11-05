# GitHub Fork, Clone, and Setup Workflow for Configuration Repositories

## Metadata
- **Date**: 2025-11-04
- **Agent**: research-specialist
- **Topic**: GitHub Fork, Clone, and Setup Workflow for Configuration Repositories
- **Report Type**: best practices
- **Complexity Level**: 3

## Executive Summary

This report provides a comprehensive guide to forking, cloning, and setting up configuration repositories (dotfiles) using GitHub workflows. It covers both web UI and CLI methods, upstream remote configuration, branch management strategies for personal customizations, and common pitfalls specific to configuration repositories. The report emphasizes best practices for maintaining forks of dotfiles while preserving the ability to pull updates from upstream sources. Key findings include the advantages of GitHub CLI for streamlined fork-and-clone operations, the importance of proper symlink management, and strategies for organizing personal customizations in separate branches.

## Findings

### 1. GitHub Fork Workflow

#### Web UI Method
The traditional GitHub web interface provides a straightforward forking process:

1. **Navigate to the target repository** on GitHub
2. **Click the "Fork" button** in the upper-right corner of the page
3. **Click "Create fork"** to create a copy in your GitHub account
4. The fork shares code and visibility settings with the original "upstream" repository

**Use Cases**: Forks are commonly used to iterate on ideas or changes before proposing them back to upstream, particularly in open source projects or when users lack write access to the upstream repository.

**Source**: GitHub Docs - Fork a repository (docs.github.com/articles/fork-a-repo)

#### GitHub CLI Method (Recommended for Automation)
The GitHub CLI (`gh`) provides powerful command-line forking capabilities with several advantages:

**Basic fork command**:
```bash
gh repo fork username/repo-name
```

**Fork with automatic cloning**:
```bash
gh repo fork username/repo-name --clone
```

**Fork without cloning** (skip prompts):
```bash
gh repo fork username/repo-name --clone=false
```

**Advanced options** (as of 2025):
- `--default-branch-only`: Only include the default branch in the fork
- `--fork-name <string>`: Rename the forked repository
- `--org <string>`: Create the fork in an organization instead of personal account
- `--remote`: Add a git remote for the fork
- `--remote-name <string>`: Specify custom name for the new remote (default: "origin")

**Default behavior**: The new fork is automatically set as your `origin` remote, and any existing `origin` remote is renamed to `upstream`. The upstream remote is set as the default remote repository.

**Sources**:
- GitHub CLI Manual (cli.github.com/manual/gh_repo_fork)
- CodeWalnut Tutorial - How to Use GitHub CLI to Fork Repositories

### 2. Cloning Forked Repositories to Correct Locations

#### Standard Clone to Home Directory
For configuration repositories that need to reside in `~/.config/`:

```bash
# Clone to specific directory
git clone https://github.com/YOUR-USERNAME/repo-name.git ~/.config/repo-name

# Or using GitHub CLI
gh repo clone YOUR-USERNAME/repo-name ~/.config/repo-name
```

#### Clone with Specific Branch
```bash
# Using GitHub CLI
gh repo clone username/repo-name ~/.config/repo-name -- -b branch-name

# Using standard git
git clone -b branch-name https://github.com/username/repo-name.git ~/.config/repo-name
```

#### Common Clone Locations for Dotfiles
- **Neovim config**: `~/.config/nvim/`
- **General dotfiles**: `~/.dotfiles/` (then symlinked to appropriate locations)
- **Direct home placement**: `~/.bashrc`, `~/.zshrc`, etc.

**Source**: Atlassian Git Tutorial - How to Store Dotfiles

### 3. Setting Up Upstream Remotes for Pulling Updates

#### Adding Upstream Remote
After cloning your fork, add the original repository as the upstream remote to track updates:

```bash
# Add upstream remote
git remote add upstream https://github.com/ORIGINAL-OWNER/REPO.git

# Verify remotes
git remote -v
```

**Expected output**:
```
origin    https://github.com/YOUR-USERNAME/REPO.git (fetch)
origin    https://github.com/YOUR-USERNAME/REPO.git (push)
upstream  https://github.com/ORIGINAL-OWNER/REPO.git (fetch)
upstream  https://github.com/ORIGINAL-OWNER/REPO.git (push)
```

#### Key Concepts
- **origin**: Your fork (read/write access) - where you push and pull your changes
- **upstream**: Original repository (read-only in most cases) - where you fetch updates from the source project
- **Purpose**: Upstream allows fetching changes from the original repository without pushing updates back, serving as a read-only path to the source project

**Source**: GitHub Docs - Configuring a remote repository for a fork

#### Fetching and Syncing Updates
Regular synchronization workflow:

```bash
# Fetch latest changes from upstream
git fetch upstream

# Switch to your main branch
git checkout main

# Merge upstream changes
git merge upstream/main

# Push updated main to your fork
git push origin main
```

**Best Practice**: Repeat this process every time you want to get updates from the original project.

**Sources**:
- Graphite Dev Guide - Adding an upstream remote to a forked Git repo
- DEV Community - Keep Your Fork In Sync: Understanding git remote upstream

### 4. Branch Management Strategies for Personal Customizations

#### Keep Main Branch Clean
**Primary principle**: Keep your local main branch as a close mirror of upstream main, and execute all work in feature branches. This approach:
- Maintains a clean reference point
- Simplifies pulling upstream changes
- Enables easy creation of pull requests
- Prevents conflicts between personal customizations and upstream updates

**Source**: Happy Git and GitHub for the useR - Chapter 31: Fork and clone

#### Set Upstream Tracking for Main Branch
Configure your local main branch to track upstream (not origin):

```bash
# Set upstream/main as the tracking branch for local main
git branch -u upstream/main

# Now 'git pull' will pull from upstream, not your fork
```

**Rationale**: This configuration ensures a simple `git pull` pulls from the source repository rather than your fork, keeping main synchronized with the original project.

**Source**: Happy Git and GitHub for the useR - Chapter 32: Get upstream changes for a fork

#### Feature Branch Strategy
Create descriptive branches for all personal customizations:

```bash
# Create feature branch from main
git checkout -b feature-custom-theme

# Make changes, commit
git add .
git commit -m "Add custom theme configuration"

# Push to your fork
git push origin feature-custom-theme
```

**Naming conventions**:
- `feature-<description>`: New features or customizations
- `fix-<description>`: Bug fixes
- `config-<description>`: Configuration changes
- Example: `feature-role-based-auth`, `config-custom-keybindings`

**Source**: Medium - Git Fork Development Workflow and best practices

#### Vendor Branch Strategy (Advanced)
For maintaining long-term forks with extensive customizations:

1. **vendor branch**: Contains changes from the original project (mirrors upstream)
2. **main/development branch**: Merges both vendor and feature branches
3. **feature branches**: Individual customizations

**Workflow**:
```bash
# Update vendor branch from upstream
git checkout vendor
git pull upstream main

# Merge vendor into development
git checkout development
git merge vendor

# Merge feature branches
git merge feature-custom-theme
```

**Use case**: Particularly useful for managing "friendly forks" that maintain compatibility with upstream while adding significant customizations.

**Source**: GitHub Blog - Being friendly: Strategies for friendly fork management

#### Contributing Back to Upstream
As a fork manager, best practices include:
- **Stay involved**: Participate in the upstream community and review changes
- **Be aware**: Monitor upstream changes that might conflict with your customizations
- **Contribute reviews**: Helps improve awareness about changes you'll consume in future merges
- **Submit PRs**: Contribute generally useful customizations back to upstream

**Source**: GitHub Blog - Being friendly: Strategies for friendly fork management

### 5. Common Pitfalls When Cloning Config Repos

#### Symlink-Related Issues

**Issue 1: Symlink Direction Errors**
- **Problem**: Creating symlinks with incorrect relative paths
- **Common mistake**: `ln -s bashrc ~/.bashrc` (relative to current directory, not target)
- **Solution**: Use absolute paths or ensure relative paths are correct relative to the link location
  ```bash
  # Correct approach - absolute paths
  ln -s /home/user/.dotfiles/bashrc ~/.bashrc

  # Correct approach - relative from ~/.bashrc location
  ln -s .dotfiles/bashrc ~/.bashrc
  ```

**Source**: Stack Overflow - Symlink dotfiles

**Issue 2: Overwriting Existing Files**
- **Problem**: `ln` refuses to overwrite existing files
- **Solution**: Either delete existing files or use `-f` flag to force overwrite
  ```bash
  # Force overwrite
  ln -sf ~/.dotfiles/bashrc ~/.bashrc
  ```

**Source**: Super User - How to properly store dotfiles in a centralized git repository

**Issue 3: Git Saves Links, Not Contents**
- **Problem**: Git commits the symlink itself, not the content it points to
- **Expected behavior**: This is by design - Git tracks symlinks as symlinks
- **Implication**: When cloning, you must ensure both the symlink and its target are present

**Source**: Managing your dotfiles the right way - Marcos Placona's Blog

#### Permission Issues

**Git Does Not Store Permissions**
- **Problem**: Git does not preserve file permissions beyond executable bit
- **Impact**: Sensitive files like SSH keys may have incorrect permissions after clone
- **Solution**: Use post-clone scripts to set permissions
  ```bash
  # Example: Fix SSH permissions
  chmod 700 ~/.ssh
  chmod 600 ~/.ssh/id_rsa
  chmod 644 ~/.ssh/id_rsa.pub
  ```

**Source**: ArchWiki - Dotfiles

#### Path-Related Issues

**Issue 1: Checkout Conflicts**
- **Problem**: Error "untracked working tree files would be overwritten by checkout"
- **Cause**: Stock dotfiles already exist in the target location
- **Solution**: Back up existing files before cloning
  ```bash
  # Backup existing dotfiles
  mv ~/.bashrc ~/.bashrc.backup
  mv ~/.vimrc ~/.vimrc.backup

  # Then clone
  git clone https://github.com/username/dotfiles.git ~/.dotfiles
  ```

**Source**: Manage Dotfiles With a Bare Git Repository

**Issue 2: Absolute vs Relative Paths**
- **Problem**: Dotfiles cloned to different locations than expected
- **Best practice**: Use `$HOME` variable for portability
  ```bash
  # Good - portable
  ln -s $HOME/.dotfiles/bashrc $HOME/.bashrc

  # Avoid - hardcoded user
  ln -s /home/john/.dotfiles/bashrc /home/john/.bashrc
  ```

#### Security Pitfalls

**Issue 1: Committing Secrets**
- **Problem**: API tokens, SSH keys, or sensitive credentials committed to repository
- **Prevention**:
  - Never add files from `~/.ssh/` to shared dotfile repositories
  - Use aggressive `.gitignore` patterns
  - Review configuration files before publishing
  ```gitignore
  # .gitignore for dotfiles
  .ssh/
  **/secrets/
  **/*.key
  **/*.pem
  *_token
  credentials.json
  ```

**Source**: Daytona.io - The Ultimate Guide to Mastering Dotfiles

**Issue 2: Trusting Unknown Dotfiles**
- **Problem**: Blindly using someone else's dotfiles without review
- **Risk**: Malicious code execution, unwanted configurations
- **Best practice**:
  1. Fork the repository
  2. Review ALL code before using
  3. Remove components you don't understand or need
  4. Test in isolated environment first

**Source**: GitHub - thoughtbot/dotfiles README

#### Hard Links vs Symlinks (macOS-Specific)

**Issue**: Many macOS programs (e.g., TextEdit) save files in a way that breaks hard links
- **Problem**: Changes made in editor don't propagate to repository
- **Solution**: Use symlinks instead of hard links for dotfiles on macOS
  ```bash
  # Use symlinks (ln -s), not hard links (ln)
  ln -s ~/.dotfiles/vimrc ~/.vimrc
  ```

**Source**: Jake Wiesler Blog - Manage Your Dotfiles Like a Superhero

### 6. How Claude Code Can Assist With Each Step

#### Fork and Clone Assistance

**Task automation**:
Claude Code can execute GitHub CLI commands through the Bash tool to automate fork and clone operations:

```bash
# Fork repository
gh repo fork OWNER/REPO --clone

# Or clone to specific location
gh repo clone OWNER/REPO ~/.config/TARGET-DIR
```

**Configuration verification**:
- Verify correct clone location
- Check remote configuration
- Validate directory structure

#### Upstream Remote Setup

**Automated setup**:
```bash
# Add upstream remote
git remote add upstream https://github.com/ORIGINAL-OWNER/REPO.git

# Verify configuration
git remote -v

# Set tracking branch
git branch -u upstream/main
```

**Validation**:
- Verify upstream URL is correct
- Confirm remote naming conventions
- Test fetch connectivity

#### Branch Management Guidance

**Branch creation**:
Claude Code can help create and manage feature branches with proper naming:

```bash
# Create feature branch
git checkout -b feature-custom-keybindings

# Push to fork
git push -u origin feature-custom-keybindings
```

**Workflow automation**:
- Create branches following project conventions
- Set up tracking relationships
- Automate merge workflows

#### Symlink Creation and Validation

**Safe symlink creation**:
Claude Code can create symlinks with absolute paths and verify targets exist:

```bash
# Verify source file exists
test -f ~/.config/nvim/init.lua || echo "Source file missing"

# Create symlink with absolute path
ln -sf "$HOME/.config/nvim/init.lua" "$HOME/.vimrc"

# Verify symlink
ls -la ~/.vimrc
```

**Validation checks**:
- Confirm source files exist before creating symlinks
- Verify symlink targets are correct
- Detect and warn about broken symlinks

#### Permission Management

**Security hardening**:
```bash
# Set SSH directory permissions
chmod 700 ~/.ssh

# Set key permissions
find ~/.ssh -type f -name "id_*" ! -name "*.pub" -exec chmod 600 {} \;
find ~/.ssh -type f -name "*.pub" -exec chmod 644 {} \;

# Verify permissions
ls -la ~/.ssh
```

#### Gitignore Configuration

**Security-focused gitignore generation**:
Claude Code can create comprehensive `.gitignore` files for dotfiles repositories:

```gitignore
# Secrets and credentials
.ssh/
*.key
*.pem
*_token
credentials.json
secrets/

# OS-specific
.DS_Store
Thumbs.db

# Editor artifacts
*.swp
*.swo
*~
```

#### Sync Workflow Automation

**Update from upstream**:
```bash
# Fetch and merge upstream changes
git fetch upstream
git checkout main
git merge upstream/main

# Update feature branch
git checkout feature-custom-theme
git rebase main

# Push updates
git push origin main
git push origin feature-custom-theme --force-with-lease
```

**Conflict resolution assistance**:
- Detect merge conflicts
- Suggest resolution strategies
- Validate post-merge state

#### Documentation Generation

Claude Code can generate:
- **README files**: Documenting installation process, dependencies, features
- **Setup scripts**: Automated installation and configuration
- **Troubleshooting guides**: Common issues and solutions
- **Change logs**: Track customizations and why they were made

#### Quality Assurance

**Pre-commit validation**:
- Check for hardcoded paths
- Verify no secrets in commit
- Validate symlink targets
- Ensure proper permissions on sensitive files

**Testing automation**:
- Test configuration in isolated environment
- Verify dotfiles work on fresh system
- Check for missing dependencies

## Recommendations

### Recommendation 1: Use GitHub CLI for Streamlined Fork-and-Clone Workflow

**Action**: Install and configure GitHub CLI (`gh`) for all fork and clone operations.

**Implementation**:
```bash
# Install gh (if not already installed)
# macOS
brew install gh

# Linux (Debian/Ubuntu)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# Authenticate
gh auth login

# Fork and clone in one command
gh repo fork OWNER/REPO --clone --remote
```

**Benefits**:
- Automatic upstream remote configuration (no manual `git remote add` needed)
- One-command fork and clone operation
- Simplified workflow for contributing back to upstream
- Built-in support for creating pull requests

**When to use**: Always prefer GitHub CLI for new forks of configuration repositories, especially when planning to stay synchronized with upstream.

### Recommendation 2: Adopt Feature Branch Strategy with Clean Main Branch

**Action**: Maintain local `main` branch as mirror of upstream, perform all customizations in feature branches.

**Implementation**:
```bash
# Initial setup - track upstream main
git branch -u upstream/main

# Create feature branches for customizations
git checkout -b feature-custom-theme
git checkout -b config-personal-keybindings
git checkout -b feature-lsp-settings

# Keep main synchronized
git checkout main
git pull  # Pulls from upstream due to tracking configuration

# Rebase feature branches on updated main
git checkout feature-custom-theme
git rebase main
```

**Naming conventions**:
- `feature-*`: New functionality or major customizations
- `config-*`: Configuration adjustments
- `fix-*`: Bug fixes or corrections
- `docs-*`: Documentation updates

**Benefits**:
- Clean separation between upstream code and personal customizations
- Easy to pull upstream updates without conflicts
- Simplified pull request creation for contributing back
- Clear organization of different customization categories

**When to use**: Essential for any fork where you plan to maintain synchronization with upstream while adding personal customizations.

### Recommendation 3: Implement Automated Setup Script with Claude Code Assistance

**Action**: Create comprehensive setup script that handles cloning, symlink creation, permission setting, and dependency installation.

**Implementation**:
```bash
#!/usr/bin/env bash
# setup.sh - Automated dotfiles installation

set -e  # Exit on error

# Configuration
DOTFILES_DIR="$HOME/.config/nvim"
REPO_URL="https://github.com/YOUR-USERNAME/nvim-config.git"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

# Backup existing configuration
echo "Backing up existing configuration to $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
[ -f ~/.vimrc ] && mv ~/.vimrc "$BACKUP_DIR/"
[ -d ~/.config/nvim ] && mv ~/.config/nvim "$BACKUP_DIR/"

# Clone repository
echo "Cloning repository to $DOTFILES_DIR"
git clone "$REPO_URL" "$DOTFILES_DIR"

# Add upstream remote
cd "$DOTFILES_DIR"
git remote add upstream https://github.com/ORIGINAL-OWNER/nvim-config.git
git fetch upstream

# Set main branch to track upstream
git branch -u upstream/main main

# Create necessary directories
mkdir -p ~/.local/share/nvim/site/pack

# Set permissions for sensitive files
echo "Setting permissions"
chmod 700 ~/.config/nvim
[ -d ~/.ssh ] && chmod 700 ~/.ssh
find ~/.ssh -type f -name "id_*" ! -name "*.pub" -exec chmod 600 {} \; 2>/dev/null || true

# Install dependencies (example for Neovim)
echo "Installing dependencies"
# Add package manager commands here

echo "Setup complete! Backup saved to: $BACKUP_DIR"
echo "Next steps:"
echo "  1. Review configuration in $DOTFILES_DIR"
echo "  2. Create feature branches for customizations"
echo "  3. Run tests: cd $DOTFILES_DIR && ./run_tests.sh"
```

**Claude Code integration**:
- Generate setup script based on repository analysis
- Detect dependencies automatically
- Create appropriate `.gitignore` files
- Generate documentation

**Benefits**:
- Reproducible setup process
- Safe backups before making changes
- Automated permission configuration
- Reduced manual errors

**When to use**: For any configuration repository that will be deployed to multiple machines or shared with others.

### Recommendation 4: Implement Security-First Gitignore Strategy

**Action**: Create comprehensive `.gitignore` before first commit to prevent accidental secret exposure.

**Implementation**:
```gitignore
# .gitignore for configuration repositories

# ========================================
# Secrets and Credentials
# ========================================
.ssh/
*.key
*.pem
*_token
*_secret
credentials.json
secrets/
.env
.env.*
!.env.example

# ========================================
# API Keys and Authentication
# ========================================
auth_token
github_token
*.credentials

# ========================================
# System Files
# ========================================
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
desktop.ini

# ========================================
# Editor and IDE
# ========================================
*.swp
*.swo
*~
.vscode/settings.json
.idea/
*.sublime-project
*.sublime-workspace

# ========================================
# Build Artifacts and Caches
# ========================================
*.log
*.cache
node_modules/
.cache/
dist/
build/

# ========================================
# Backup Files
# ========================================
*.backup
*.bak
*.old
*-backup-*
```

**Verification script**:
```bash
#!/usr/bin/env bash
# verify-no-secrets.sh - Pre-commit hook to detect secrets

# Check for common secret patterns
if git diff --cached | grep -E "(password|secret|token|api[_-]?key)" -i; then
    echo "ERROR: Potential secret detected in staged files"
    echo "Please review changes and use .gitignore if needed"
    exit 1
fi

# Check for SSH keys
if git diff --cached --name-only | grep -E "\.ssh/|id_rsa|id_ed25519"; then
    echo "ERROR: SSH key files should not be committed"
    exit 1
fi

echo "No secrets detected"
exit 0
```

**Benefits**:
- Prevent accidental credential exposure
- Protect sensitive configuration
- Enable safe public repository sharing
- Automated validation

**When to use**: Mandatory for all configuration repositories, especially those that may be made public or shared.

### Recommendation 5: Create Comprehensive Documentation with Installation Guide

**Action**: Generate detailed README with step-by-step fork, clone, and setup instructions.

**Template structure**:
```markdown
# [Project Name] Configuration

## Overview
[Brief description of configuration purpose]

## Prerequisites
- Git 2.0+
- GitHub CLI (optional but recommended)
- [Other dependencies]

## Installation

### Option 1: GitHub CLI (Recommended)
# Fork and clone
gh repo fork ORIGINAL-OWNER/REPO --clone

# Navigate to directory
cd REPO

# Run setup script
./setup.sh


### Option 2: Manual Fork and Clone
1. Fork repository on GitHub (click "Fork" button)
2. Clone your fork:

   git clone https://github.com/YOUR-USERNAME/REPO.git ~/.config/REPO

3. Add upstream remote:

   cd ~/.config/REPO
   git remote add upstream https://github.com/ORIGINAL-OWNER/REPO.git

4. Set tracking branch:

   git branch -u upstream/main main


## Updating from Upstream

# Fetch upstream changes
git fetch upstream

# Merge into main
git checkout main
git merge upstream/main

# Rebase feature branches
git checkout feature-custom-theme
git rebase main


## Creating Personal Customizations

# Create feature branch
git checkout -b feature-my-customization

# Make changes, commit
git add .
git commit -m "Add my customization"

# Push to your fork
git push origin feature-my-customization


## Project Structure
[Directory layout and purpose of key files]

## Troubleshooting
[Common issues and solutions]

## Contributing
[Guidelines for contributing back to upstream]
```

**Claude Code assistance**:
- Generate README based on repository analysis
- Create quickstart guides
- Generate troubleshooting sections based on common pitfalls
- Maintain documentation as configuration evolves

**Benefits**:
- Reduces onboarding friction
- Documents setup process
- Provides reference for future installations
- Helps others fork and customize

**When to use**: Essential for any configuration repository that will be shared or forked by others, or deployed to multiple machines.

## References

### Web Sources
- GitHub Docs - Fork a repository: https://docs.github.com/articles/fork-a-repo
- GitHub Docs - Configuring a remote repository for a fork: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/configuring-a-remote-repository-for-a-fork
- GitHub CLI Manual - gh repo fork: https://cli.github.com/manual/gh_repo_fork
- GitHub Blog - Being friendly: Strategies for friendly fork management: https://github.blog/developer-skills/github/friend-zone-strategies-friendly-fork-management/
- Atlassian Git Tutorial - What Is a Git Fork?: https://www.atlassian.com/git/tutorials/comparing-workflows/forking-workflow
- Atlassian Git Tutorial - Git Upstreams and Forks: https://www.atlassian.com/git/tutorials/git-forks-and-upstreams
- Atlassian Git Tutorial - How to Store Dotfiles: https://www.atlassian.com/git/tutorials/dotfiles
- Graphite Dev Guide - Adding an upstream remote to a forked Git repo: https://graphite.dev/guides/upstream-remote
- DEV Community - Keep Your Fork In Sync: Understanding git remote upstream: https://dev.to/untilyou58/keep-your-fork-in-sync-understanding-git-remote-upstream-366l
- Happy Git and GitHub for the useR - Chapter 31: Fork and clone: https://happygitwithr.com/fork-and-clone
- Happy Git and GitHub for the useR - Chapter 32: Get upstream changes for a fork: https://happygitwithr.com/upstream-changes.html
- Medium - Git Fork Development Workflow and best practices: https://medium.com/@abhijit838/git-fork-development-workflow-and-best-practices-fb5b3573ab74
- CodeWalnut Tutorial - How to Use GitHub CLI to Fork Repositories: https://www.codewalnut.com/tutorials/how-to-use-github-cli-to-fork-repositories
- Daytona.io - The Ultimate Guide to Mastering Dotfiles: https://www.daytona.io/dotfiles/ultimate-guide-to-dotfiles
- ArchWiki - Dotfiles: https://wiki.archlinux.org/title/Dotfiles
- Jake Wiesler Blog - Manage Your Dotfiles Like a Superhero: https://www.jakewiesler.com/blog/managing-dotfiles
- Marcos Placona Blog - Managing your dotfiles the right way: https://placona.co.uk/managing-your-dotfiles-the-right-way/
- Harfangk Blog - Manage Dotfiles With a Bare Git Repository: https://harfangk.github.io/2016/09/18/manage-dotfiles-with-a-git-bare-repository.html
- Stack Overflow - Symlink dotfiles: https://stackoverflow.com/questions/46534290/symlink-dotfiles
- Stack Overflow - How to clone, then sync/update/push a fork with upstream master: https://stackoverflow.com/questions/51089820/how-to-clone-then-sync-update-push-a-fork-with-the-upstream-master
- Super User - How to properly store dotfiles in a centralized git repository: https://superuser.com/questions/302312/how-to-properly-store-dotfiles-in-a-centralized-git-repository

### Project Sources
- CLAUDE.md:1-50 - Project configuration and standards
- Research conducted via WebSearch tool (2025-11-04)
