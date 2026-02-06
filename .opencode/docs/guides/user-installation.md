# User Installation Guide

[Back to Docs](../README.md) | [Detailed Installation](../../../docs/installation/README.md)

A quick-start guide for installing Claude Code and using it to work with Neovim configuration projects.

---

## What This Guide Covers

This guide helps you:
1. Install Claude Code (Anthropic's AI CLI)
2. Set up a Neovim configuration project
3. Set up Claude agent commands (optional)
4. Work with Neovim configuration files
5. Set up GitHub CLI for issue reporting

**New to the terminal?** See your operating system's documentation for terminal basics.

---

## Installing Claude Code

Claude Code is Anthropic's command-line interface for AI-assisted development.

### Quick Installation

**macOS:**
```bash
brew install anthropics/claude/claude-code
```

**Windows (PowerShell as Administrator):**
```powershell
irm https://raw.githubusercontent.com/anthropics/claude-code/main/install.ps1 | iex
```

**Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/anthropics/claude-code/main/install.sh | sh
```

### Verify Installation

```bash
claude --version
```

You should see a version number.

---

## Authentication

Before using Claude Code, authenticate with your Anthropic account:

```bash
claude auth login
```

This opens a browser window. Log in with your Anthropic account and authorize Claude Code.

**Verify authentication:**
```bash
claude auth status
```

---

## Setting Up a Neovim Configuration Project with Claude Code

### Step 1: Navigate to Your Configuration

```bash
cd ~/.config/nvim
# Or wherever your Neovim configuration lives
```

### Step 2: Initialize Git (if not already done)

```bash
git init
git add .
git commit -m "Initial commit"
```

### Step 3: Start Claude Code

```bash
claude
```

### Step 4: Verify Setup

Ask Claude:

```
Please verify my Neovim configuration by:
1. Checking the overall structure of the configuration
2. Identifying the plugin manager in use
3. Confirming the Lua modules are properly organized
```

---

## Setting Up Claude Agent Commands (Optional)

The repository includes a `.opencode/` agent system that provides enhanced task management and workflow commands for Claude Code.

### What the Agent System Provides

- **Task Management**: Create, track, and archive development tasks
- **Structured Workflow**: `/research` -> `/plan` -> `/implement` cycle
- **Specialized Skills**: Language-specific agents for Neovim development
- **Context Files**: Domain knowledge for Neovim, plugins, and Lua
- **State Persistence**: Track progress across Claude Code sessions

### After Installation

1. **Restart Claude Code** - Exit and restart for commands to be available
2. **Test the setup** - Try creating a test task:
   ```
   /task "Test task"
   ```
3. **Learn the commands** - See the Commands Reference

### Available Commands

| Command | Purpose |
|---------|---------|
| `/task` | Create and manage tasks |
| `/research` | Conduct research on a task |
| `/plan` | Create implementation plan |
| `/implement` | Execute implementation |
| `/todo` | Archive completed tasks |

For complete documentation, see the [Commands Reference](../commands/README.md).

---

## Working with Neovim Configuration

Once your configuration is set up, use Claude Code to assist with Neovim development.

### Explore the Codebase

In Claude Code, ask:

```
Show me the structure of my Neovim configuration and explain
how the modules are organized.
```

Claude will:
1. Navigate the lua/ directory structure
2. Explain the plugin specifications
3. Show how keymaps and options are configured

### Working on Configuration

Ask Claude to help with specific configurations:

```
Help me understand how the LSP is configured in my
nvim/lua/plugins/lsp.lua file
```

Or:

```
I want to add a new plugin for git integration. Can you help me
find popular options and configure one?
```

---

## GitHub CLI Setup

The GitHub CLI (`gh`) allows Claude Code to create issues and pull requests. This is helpful for reporting bugs or contributing.

### Installing GitHub CLI

Ask Claude:

```
Please install the GitHub CLI (gh) for my system and help me
authenticate with GitHub.
```

**Or manually:**

**macOS:**
```bash
brew install gh
```

**Windows:**
```powershell
winget install GitHub.cli
```

**Linux (Debian/Ubuntu):**
```bash
sudo apt install gh
```

### Authenticate with GitHub

```bash
gh auth login
```

Follow the prompts to authenticate via browser.

**Verify:**
```bash
gh auth status
```

---

## Example Workflows

### Complete First-Time Setup

```bash
# Install Claude Code (see platform commands above)
claude --version

# Authenticate
claude auth login

# Navigate to your configuration
cd ~/.config/nvim

# Start Claude
claude
```

In Claude Code:
```
Please help me:
1. Verify my Neovim configuration is properly structured
2. Explore the lua/ directory and identify plugins
3. Check for any common issues or improvements
```

### Adding a New Plugin

```bash
cd ~/.config/nvim
claude
```

Ask Claude:
```
Help me add telescope.nvim to my configuration with
proper keybindings for file finding and live grep.
```

### Debugging Configuration Issues

```bash
cd ~/.config/nvim
claude
```

```
I'm getting an error when Neovim starts.
Please diagnose the issue and suggest fixes.
```

---

## Troubleshooting

### Claude Code Issues

**"Command not found":**
- Restart your terminal
- Check installation: `which claude`
- Reinstall using platform instructions

**Authentication failed:**
```bash
claude auth logout
claude auth login
```

### Neovim Issues

**Plugins not loading:**
- Run `:Lazy sync` to update plugins
- Check for errors: `:messages`
- Verify plugin specifications are correct

**LSP not working:**
- Check LSP is installed: `:LspInfo`
- Ensure language servers are installed via Mason
- Check for errors: `:LspLog`

**Configuration errors:**
- Run `nvim --headless -c 'checkhealth' -c 'qa'` to check health
- Look for syntax errors in lua files

---

## Next Steps

### Documentation

- **[Architecture](../../README.md)** - System architecture overview
- **[CLAUDE.md](../../CLAUDE.md)** - Quick reference for the agent system
- **[Commands Reference](../commands/README.md)** - Full command documentation

### Project Documentation

- **[nvim/](../../../nvim/)** - Neovim configuration source

### Contributing

- **[GitHub Setup](https://docs.github.com/en/get-started)** - Git and GitHub basics
- Open issues for bugs or feature requests

---

[Back to Docs](../README.md) | [Copy .opencode/ Directory](copy-claude-directory.md)
