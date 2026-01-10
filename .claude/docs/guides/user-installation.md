# User Installation Guide

[Back to Docs](../README.md) | [Detailed Installation](../../../Docs/installation/README.md)

A quick-start guide for installing Claude Code and using it to set up ModelChecker.

---

## What This Guide Covers

This guide helps you:
1. Install Claude Code (Anthropic's AI CLI)
2. Use Claude Code to install ModelChecker
3. Create and modify Logos projects
4. Set up GitHub CLI for issue reporting

**New to the terminal?** See [Getting Started: Using the Terminal](../../../Docs/installation/GETTING_STARTED.md) first.

---

## Installing Claude Code

Claude Code is Anthropic's command-line interface for AI-assisted development.

**Official Documentation**: [Claude Code on GitHub](https://github.com/anthropics/claude-code)

### Quick Installation

**macOS:**

First, ensure you have Homebrew installed. If not, install it:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Then install Claude Code:
```bash
brew install anthropics/claude/claude-code
```

**Windows (PowerShell as Administrator):**

The `irm` (Invoke-RestMethod) command is built into PowerShell 3.0+, which comes pre-installed on Windows 10 and later. Open PowerShell as Administrator and run:
```powershell
irm https://raw.githubusercontent.com/anthropics/claude-code/main/install.ps1 | iex
```

If you're on an older Windows version, first [install PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows).

**Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/anthropics/claude-code/main/install.sh | sh
```

### Verify Installation

```bash
claude --version
```

You should see a version number. If not, see [Troubleshooting](../../../Docs/installation/TROUBLESHOOTING.md).

**For detailed platform-specific instructions**, see the full [Claude Code Installation Guide](../../../Docs/installation/CLAUDE_CODE.md#installation).

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

## Installing ModelChecker with Claude Code

Instead of running installation commands manually, let Claude do it for you.

### Step 1: Navigate to Your Workspace

```bash
mkdir -p ~/Documents/Projects
cd ~/Documents/Projects
```

### Step 2: Start Claude Code

```bash
claude
```

### Step 3: Request Installation

Paste this prompt to Claude:

```
Please follow the installation instructions at
Docs/installation/BASIC_INSTALLATION.md to install ModelChecker.
After installation, verify it works by running model-checker --version.
```

**What Claude Will Do:**
- Check your Python version (requires 3.8+)
- Install ModelChecker via pip
- Verify the installation works

### Alternative: Direct Installation

If you prefer to install manually:

```bash
pip install model-checker
```

Or with Jupyter support:

```bash
pip install model-checker[jupyter]
```

**Verify:**
```bash
model-checker --version
```

---

## Creating Logos Projects

Once ModelChecker is installed, create projects with Claude Code's help.

### Create a New Project

In Claude Code, ask:

```
Create a new ModelChecker project using the logos theory to test
whether contraposition is valid.
```

Claude will:
1. Run `model-checker` to generate a project
2. Navigate to the project directory
3. Modify the example file for your test
4. Run the model checker
5. Explain the results

### Manual Project Creation

```bash
# Create a logos project
model-checker

# Or specify a theory
model-checker -l imposition
```

This creates a project directory with:
- `examples.py` - Your main working file
- `semantic.py` - Theory definitions
- `operators.py` - Logical operators
- `README.md` - Theory documentation

### Modifying Examples

Ask Claude to help:

```
Help me add a validity check for modus ponens to my examples.py file.
```

Or:

```
I'm getting unexpected results. Can you review my premises and
conclusions and help debug?
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

## Opening Issues on ModelChecker

When you encounter bugs or have suggestions, Claude Code can help create issues.

### Using Claude Code

```
I'm getting an error when running model-checker with N=5.
Help me create an issue on the ModelChecker repository
with the error details.
```

Claude will:
1. Gather error information
2. Format a clear issue report
3. Create the issue via `gh issue create`

### Manual Issue Creation

```bash
gh issue create --repo benbrastmckie/ModelChecker \
  --title "Brief description" \
  --body "Detailed description of the issue"
```

### What to Include in Issues

- ModelChecker version (`model-checker --version`)
- Python version (`python --version`)
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

# Create workspace and start Claude
mkdir -p ~/Documents/Projects && cd ~/Documents/Projects
claude
```

In Claude Code:
```
Please help me:
1. Install ModelChecker
2. Create a project testing the validity of disjunctive syllogism
3. Run the model checker and explain the results
```

### Working with Existing Projects

```bash
cd ~/Documents/Projects/my_project
claude
```

Ask Claude:
```
Review my examples.py and suggest additional test cases
for my modal logic formulas.
```

### Debugging Issues

```bash
cd ~/Documents/Projects/my_project
claude
```

```
I ran model-checker examples.py and got unexpected results.
Please review my configuration and help diagnose the issue.
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

### ModelChecker Issues

**"model-checker: command not found":**
- Ensure Python scripts are in PATH
- Try: `python -m model_checker --version`
- Use virtual environment

**Import errors:**
- Check Python version: `python --version` (requires 3.8+)
- Reinstall: `pip install --upgrade model-checker`

For more solutions, see [Troubleshooting Guide](../../../Docs/installation/TROUBLESHOOTING.md).

### When to Open an Issue

Open an issue on GitHub if:
- You've followed all troubleshooting steps
- The error appears to be a bug in ModelChecker
- You have a feature request
- Documentation is unclear or incorrect

---

## Next Steps

### Documentation

- **[Full Claude Code Guide](../../../Docs/installation/CLAUDE_CODE.md)** - Complete feature reference
- **[Getting Started](../../../Docs/installation/GETTING_STARTED.md)** - Terminal and editor basics
- **[Usage Guide](../../../Docs/usage/README.md)** - Using ModelChecker features

### Theory Documentation

- **[Theory Library](../../../Code/src/model_checker/theory_lib/README.md)** - Available theories
- **[Logos Theory](../../../Code/src/model_checker/theory_lib/logos/README.md)** - Hyperintensional semantics
- **[Examples Guide](../../../Docs/usage/EXAMPLES.md)** - Creating test cases

### Contributing

- **[GitHub Setup](../../../Docs/installation/GIT_GOING.md)** - Git and GitHub basics
- **[Developer Setup](../../../Docs/installation/DEVELOPER_SETUP.md)** - Contributing to ModelChecker

---

[Back to Docs](../README.md) | [Detailed Installation](../../../Docs/installation/README.md)
