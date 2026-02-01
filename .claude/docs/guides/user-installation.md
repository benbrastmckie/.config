# User Installation Guide

[Back to Docs](../README.md) | [Detailed Installation](../../../docs/installation/README.md)

A quick-start guide for installing Claude Code and using it to work with ProofChecker.

---

## What This Guide Covers

This guide helps you:
1. Install Claude Code (Anthropic's AI CLI)
2. Clone and set up ProofChecker
3. Set up Claude agent commands (optional)
4. Work with Lean 4 proofs
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

## Setting Up ProofChecker with Claude Code

### Step 1: Clone the Repository

```bash
mkdir -p ~/Documents/Projects
cd ~/Documents/Projects
git clone https://github.com/benbrastmckie/ProofChecker.git
cd ProofChecker
```

### Step 2: Install Lean 4 and Mathlib

ProofChecker requires Lean 4 and Mathlib. Install elan (Lean version manager):

```bash
# macOS/Linux
curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh

# Windows - download from https://github.com/leanprover/elan/releases
```

After installation, restart your terminal and verify:

```bash
elan --version
lake --version
```

### Step 3: Build the Project

```bash
cd ~/Documents/Projects/ProofChecker
lake build
```

This may take several minutes on first build as it downloads Mathlib cache.

### Step 4: Start Claude Code

```bash
claude
```

### Step 5: Verify Setup

Ask Claude:

```
Please verify the ProofChecker setup by:
1. Checking that lake build succeeds
2. Running lean_goal on a proof in Theories/Bimodal/Soundness.lean
3. Confirming the Lean LSP tools are available
```

---

## Setting Up Claude Agent Commands (Optional)

The ProofChecker repository includes a `.claude/` agent system that provides enhanced task management and workflow commands for Claude Code.

### What the Agent System Provides

- **Task Management**: Create, track, and archive development tasks
- **Structured Workflow**: `/research` -> `/plan` -> `/implement` cycle
- **Specialized Skills**: Language-specific agents for Lean 4 development
- **Context Files**: Domain knowledge for logic, semantics, and theorem proving
- **State Persistence**: Track progress across Claude Code sessions
- **Lean MCP Tools**: Integration with lean-lsp for proof assistance

### Installation

To install the agent system, paste this URL into Claude Code:

```
https://raw.githubusercontent.com/benbrastmckie/ProofChecker/main/.claude/docs/guides/copy-claude-directory.md
```

Then give Claude this prompt:

```
Please read the instructions at the URL above and follow them to copy
the .claude/ directory into my current working directory.
```

**Alternative**: Follow the instructions in the guide manually.

### After Installation

1. **Restart Claude Code** - Exit and restart for commands to be available
2. **Test the setup** - Try creating a test task:
   ```
   /task "Test task"
   ```
3. **Learn the commands** - Read the full command reference:
   ```
   https://raw.githubusercontent.com/benbrastmckie/ProofChecker/main/.claude/docs/commands/README.md
   ```

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

## Working with Lean 4 Proofs

Once ProofChecker is set up, use Claude Code to assist with theorem proving.

### Explore the Codebase

In Claude Code, ask:

```
Show me the structure of the Logos/ directory and explain
the layered logic system.
```

Claude will:
1. Navigate the Layer0/Layer1/Layer2 structure
2. Explain the propositional, modal, and temporal logic layers
3. Show how proofs are organized

### Working on Proofs

Ask Claude to help with specific proofs:

```
Help me understand the proof of Deduction Theorem in
Logos/Layer0/Propositional.lean
```

Or:

```
I'm trying to prove a modal logic theorem. Can you help me
find relevant lemmas in Mathlib using leansearch?
```

### Using Lean MCP Tools

Claude has access to specialized Lean tools:

| Tool | Purpose |
|------|---------|
| `lean_goal` | See proof state at a position |
| `lean_hover_info` | Get type signatures |
| `lean_leansearch` | Search Mathlib by natural language |
| `lean_loogle` | Search by type signature |
| `lake build` | Check for compiler errors (via Bash) |

**Note**: Some MCP tools are blocked due to known bugs. See `.claude/context/core/patterns/blocked-mcp-tools.md` for details.

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

## Opening Issues on ProofChecker

When you encounter bugs or have suggestions, Claude Code can help create issues.

### Using Claude Code

```
I'm getting an error when building the project.
Help me create an issue on the ProofChecker repository
with the error details.
```

Claude will:
1. Gather error information
2. Format a clear issue report
3. Create the issue via `gh issue create`

### Manual Issue Creation

```bash
gh issue create --repo benbrastmckie/ProofChecker \
  --title "Brief description" \
  --body "Detailed description of the issue"
```

### What to Include in Issues

- Lean version (`lean --version`)
- Lake version (`lake --version`)
- Operating system
- Steps to reproduce
- Expected vs actual behavior
- Error messages (if any)

---

## Example Workflows

### Complete First-Time Setup

```bash
# Install Claude Code (see platform commands above)
claude --version

# Authenticate
claude auth login

# Clone and set up project
mkdir -p ~/Documents/Projects && cd ~/Documents/Projects
git clone https://github.com/benbrastmckie/ProofChecker.git
cd ProofChecker

# Build (first time takes a while)
lake build

# Start Claude
claude
```

In Claude Code:
```
Please help me:
1. Verify the Lean 4 setup is working
2. Explore the Logos/ directory structure
3. Run diagnostics on a sample proof file
```

### Working with Existing Proofs

```bash
cd ~/Documents/Projects/ProofChecker
claude
```

Ask Claude:
```
Review Logos/Layer1/Modal.lean and explain the key theorems
and how they relate to Kripke semantics.
```

### Debugging Build Issues

```bash
cd ~/Documents/Projects/ProofChecker
claude
```

```
I ran lake build and got an error.
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

### Lean/Lake Issues

**"lake: command not found":**
- Ensure elan is installed
- Restart terminal after elan installation
- Check: `elan show` to see installed toolchains

**Build errors:**
- Run `lake clean` then `lake build`
- Ensure you're using the correct Lean version (check `lean-toolchain`)
- Download Mathlib cache: `lake exe cache get`

**Slow builds:**
- First builds are slow due to Mathlib compilation
- Use `lake exe cache get` to download prebuilt cache

### Lean LSP Issues

**MCP tools not working:**
- Ensure the lean-lsp MCP server is configured
- Check Claude Code settings for MCP configuration
- Verify Lean project builds successfully first

---

## Next Steps

### Documentation

- **[Architecture](../../README.md)** - System architecture overview
- **[CLAUDE.md](../../CLAUDE.md)** - Quick reference for the agent system
- **[Commands Reference](../commands/README.md)** - Full command documentation

### Project Documentation

- **[docs/](../../../docs/)** - Project documentation
- **[Logos/](../../../Logos/)** - Lean 4 source code

### Contributing

- **[GitHub Setup](https://docs.github.com/en/get-started)** - Git and GitHub basics
- Open issues for bugs or feature requests

---

[Back to Docs](../README.md) | [Copy .claude/ Directory](copy-claude-directory.md)
