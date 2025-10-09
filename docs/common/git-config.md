# Git Configuration Guide

This guide covers Git configuration for working with the Neovim configuration repository.

## Overview

Proper Git configuration enables:
- Forking and customizing the configuration
- Tracking your changes separately
- Syncing with upstream updates
- Contributing improvements back

## Basic Git Configuration

### Set Username and Email

Configure your Git identity:

```bash
git config --global user.name "YOUR-USERNAME"
git config --global user.email "YOUR-EMAIL"
```

This information appears in your commits.

### Verify Configuration

Check your settings:
```bash
git config --list
```

## SSH Key Setup

SSH keys provide secure authentication without passwords.

### Generate SSH Key

Create a new SSH key:

```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

**Prompts**:
- **File location**: Press Enter for default (`~/.ssh/id_rsa`)
- **Passphrase**: Optional but recommended for security

### Start SSH Agent

**Linux/macOS**:
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
```

**Windows** (Git Bash):
```bash
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_rsa
```

### Copy SSH Public Key

**Linux**:
```bash
# Arch
sudo pacman -S xclip
xclip -sel clip < ~/.ssh/id_rsa.pub

# Debian/Ubuntu
sudo apt install xclip
xclip -sel clip < ~/.ssh/id_rsa.pub
```

**macOS**:
```bash
pbcopy < ~/.ssh/id_rsa.pub
```

**Windows** (Git Bash):
```bash
clip < ~/.ssh/id_rsa.pub
```

**Manual copy** (any platform):
```bash
cat ~/.ssh/id_rsa.pub
# Copy the output manually
```

### Add SSH Key to GitHub

1. Go to [GitHub](https://github.com)
2. Click your profile → Settings
3. Navigate to "SSH and GPG Keys"
4. Click "New SSH Key"
5. Paste your public key
6. Give it a descriptive title (e.g., "Personal Laptop")
7. Click "Add SSH Key"

### Verify SSH Connection

Test your GitHub SSH connection:
```bash
ssh -T git@github.com
```

Expected output:
```
Hi username! You've successfully authenticated, but GitHub does not provide shell access.
```

### SSH Key Persistence

If your SSH key stops working after reboot:

```bash
ssh-add ~/.ssh/id_rsa
```

**Make persistent** (Linux/macOS):

Add to `~/.bashrc` or `~/.zshrc`:
```bash
# Start SSH agent and add key
if [ -z "$SSH_AUTH_SOCK" ]; then
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/id_rsa
fi
```

## Personal Access Token (PAT)

PATs provide HTTPS authentication for Git operations.

### When to Use PAT vs SSH

**Use SSH** (recommended):
- More secure
- No password prompts
- Better for automated operations

**Use PAT**:
- HTTPS required by network
- Simpler initial setup
- Fine-grained permissions

### Create Personal Access Token

1. Go to [GitHub](https://github.com)
2. Click profile → Settings → Developer settings
3. Click "Personal Access Tokens" → "Tokens (classic)"
4. Click "Generate new token (classic)"
5. Configure token:
   - **Note**: Descriptive name (e.g., "Neovim Config")
   - **Expiration**: Choose duration (no expiration or custom)
   - **Scopes**: Check "repo" (full repository access)
6. Click "Generate token"
7. **Copy token immediately** (you won't see it again)

### Configure Git to Use PAT

**Option 1: Credential Cache** (temporary):
```bash
git config --global credential.helper cache
# Caches credentials for 15 minutes
```

**Option 2: Credential Store** (permanent):
```bash
git config --global credential.helper store
# Stores credentials in plain text at ~/.git-credentials
# Use with caution!
```

On next git operation requiring authentication:
- Username: Your GitHub username
- Password: Your PAT (not your GitHub password)

**Option 3: Git Credential Manager** (recommended):

Install for automatic secure credential management:

**Linux**:
```bash
# Arch
yay -S git-credential-manager-core

# Debian/Ubuntu
# Download from https://github.com/GitCredentialManager/git-credential-manager/releases
```

**macOS**:
```bash
brew install git-credential-manager
```

**Windows**:
Included with Git for Windows.

## Forking Workflow

### Fork the Repository

1. Visit the repository on GitHub
2. Click the "Fork" button (top right)
3. Select yourself as the owner
4. Click "Create fork"

Your fork: `https://github.com/YOUR-USERNAME/REPO-NAME`

### Clone Your Fork

**Using SSH** (recommended):
```bash
git clone git@github.com:YOUR-USERNAME/REPO-NAME.git ~/.config/nvim
cd ~/.config/nvim
```

**Using HTTPS**:
```bash
git clone https://github.com/YOUR-USERNAME/REPO-NAME.git ~/.config/nvim
cd ~/.config/nvim
```

### Add Upstream Remote

Track the original repository for updates:

```bash
cd ~/.config/nvim
git remote add upstream git@github.com:ORIGINAL-AUTHOR/REPO-NAME.git
# OR for HTTPS:
git remote add upstream https://github.com/ORIGINAL-AUTHOR/REPO-NAME.git
```

Verify remotes:
```bash
git remote -v
```

Expected output:
```
origin    git@github.com:YOUR-USERNAME/REPO-NAME.git (fetch)
origin    git@github.com:YOUR-USERNAME/REPO-NAME.git (push)
upstream  git@github.com:ORIGINAL-AUTHOR/REPO-NAME.git (fetch)
upstream  git@github.com:ORIGINAL-AUTHOR/REPO-NAME.git (push)
```

## Syncing with Upstream

### Fetch Upstream Changes

Get latest changes from original repository:

```bash
git fetch upstream
```

### Merge Upstream Changes

**Option 1: Merge** (preserves history):
```bash
git checkout main  # Or master
git merge upstream/main
```

**Option 2: Rebase** (cleaner history):
```bash
git checkout main
git rebase upstream/main
```

### Push to Your Fork

```bash
git push origin main
```

If rebase was used:
```bash
git push origin main --force-with-lease  # Safer than --force
```

## Common Git Operations

### Check Status

```bash
git status
```

### View Changes

```bash
git diff              # Unstaged changes
git diff --staged     # Staged changes
```

### Stage Changes

```bash
git add file.lua                # Stage specific file
git add .                       # Stage all changes
git add -p                      # Stage interactively
```

### Commit Changes

```bash
git commit -m "Brief description of changes"
```

### View Commit History

```bash
git log                         # Full history
git log --oneline               # Compact history
git log --graph --oneline       # Visual graph
```

### Undo Changes

```bash
git restore file.lua            # Discard unstaged changes
git restore --staged file.lua   # Unstage file
git reset --soft HEAD~1         # Undo last commit, keep changes
git reset --hard HEAD~1         # Undo last commit, discard changes (destructive!)
```

## Troubleshooting

### Permission Denied (SSH)

**Issue**: `Permission denied (publickey)`

**Solutions**:
1. Verify SSH key added to agent:
   ```bash
   ssh-add -l
   ```
2. Add key if missing:
   ```bash
   ssh-add ~/.ssh/id_rsa
   ```
3. Verify key on GitHub (Settings → SSH Keys)
4. Test connection:
   ```bash
   ssh -T git@github.com
   ```

### Authentication Failed (HTTPS)

**Issue**: Authentication failures when using HTTPS

**Solutions**:
1. Verify credentials:
   - Username: GitHub username
   - Password: Personal Access Token (not GitHub password)
2. Clear credential cache:
   ```bash
   git credential-cache exit
   ```
3. Try operation again to re-enter credentials

### Merge Conflicts

**Issue**: Conflicts when merging upstream changes

**Solution**:
1. Open conflicted files
2. Look for conflict markers:
   ```
   <<<<<<< HEAD
   Your changes
   =======
   Upstream changes
   >>>>>>> upstream/main
   ```
3. Resolve by choosing one version or combining both
4. Remove conflict markers
5. Stage resolved files:
   ```bash
   git add resolved-file.lua
   ```
6. Complete merge:
   ```bash
   git commit
   ```

### Detached HEAD

**Issue**: "You are in 'detached HEAD' state"

**Solution**:
```bash
git checkout main  # Return to main branch
# OR create branch from current state:
git checkout -b new-branch-name
```

## Best Practices

### Commit Messages

Good commit messages:
```
feat: add telescope keybinding for LSP references

- Added <leader>lr for finding references
- Integrated with Trouble for better navigation
- Updated keybindings documentation
```

### Branch Strategy

For customizations:
```bash
git checkout -b custom/my-feature
# Make changes
git add .
git commit -m "custom: add my feature"
git push origin custom/my-feature
```

Keeps main branch clean for upstream merges.

### Before Pulling Upstream

1. Commit or stash local changes:
   ```bash
   git status
   git stash  # If you have uncommitted changes
   ```
2. Pull upstream:
   ```bash
   git fetch upstream
   git merge upstream/main
   ```
3. Restore stashed changes:
   ```bash
   git stash pop
   ```

## Navigation

- [Back to Installation Documentation Index](../README.md)
- [Prerequisites Reference](prerequisites.md)
- [Main Installation Guide](../../nvim/docs/INSTALLATION.md)
- [Platform Installation Guides](../README.md#platform-installation-guides)
