# ModelChecker Installation Context

Agent reference for installation assistance. Load when helping users install or troubleshoot ModelChecker.

## Key Installation Commands

### Claude Code Installation

```bash
# macOS
brew install anthropics/claude/claude-code

# Windows (PowerShell as Admin)
irm https://raw.githubusercontent.com/anthropics/claude-code/main/install.ps1 | iex

# Linux
curl -fsSL https://raw.githubusercontent.com/anthropics/claude-code/main/install.sh | sh

# Verify
claude --version
```

### Claude Code Authentication

```bash
claude auth login      # Opens browser for authentication
claude auth status     # Verify authentication
```

### ModelChecker Installation

```bash
# Basic installation
pip install model-checker

# With Jupyter support
pip install model-checker[jupyter]

# All extras
pip install model-checker[all]

# Upgrade
pip install --upgrade model-checker

# Verify
model-checker --version
```

### GitHub CLI Installation

```bash
# macOS
brew install gh

# Windows
winget install GitHub.cli

# Linux (Debian/Ubuntu)
sudo apt install gh

# Authenticate
gh auth login
gh auth status
```

## Documentation Paths

### User-Facing Installation Docs (Docs/installation/)

| Document | Purpose |
|----------|---------|
| `CLAUDE_CODE.md` | Complete Claude Code guide with GitHub integration |
| `BASIC_INSTALLATION.md` | Standard pip installation |
| `GETTING_STARTED.md` | Terminal basics, first project |
| `GIT_GOING.md` | Git and GitHub setup |
| `TROUBLESHOOTING.md` | Platform-specific issues |
| `VIRTUAL_ENVIRONMENTS.md` | venv setup |
| `JUPYTER_SETUP.md` | Jupyter notebook configuration |
| `DEVELOPER_SETUP.md` | Development environment |
| `CLAUDE_TEMPLATE.md` | Template for user CLAUDE.md |

### Agent System Docs (.claude/docs/)

| Document | Purpose |
|----------|---------|
| `guides/user-installation.md` | Quick-start for new users |
| `guides/context-management.md` | Context loading patterns |

## Project Creation

### Create New Project

```bash
# Default (Logos theory)
model-checker

# Specific theory
model-checker -l logos
model-checker -l imposition
model-checker -l exclusion
model-checker -l bimodal

# With subtheory
model-checker -l logos --subtheory modal
model-checker -l logos --subtheory counterfactual
```

### Project Structure

```
project_name/
├── examples.py     # Main working file
├── semantic.py     # Theory definitions
├── operators.py    # Logical operators
├── README.md       # Theory documentation
└── __init__.py     # Package initialization
```

### Running Examples

```bash
# Basic run
model-checker examples.py

# With options
model-checker examples.py --contingent
model-checker examples.py --save json
model-checker examples.py --maximize
```

## GitHub Integration

### ModelChecker Repository

- **URL**: https://github.com/benbrastmckie/ModelChecker
- **Issues**: https://github.com/benbrastmckie/ModelChecker/issues

### Creating Issues

```bash
# With gh CLI
gh issue create --repo benbrastmckie/ModelChecker \
  --title "Brief description" \
  --body "Detailed description"

# View issues
gh issue list --repo benbrastmckie/ModelChecker
```

### Issue Template

When helping users create issues, include:
- ModelChecker version (`model-checker --version`)
- Python version (`python --version`)
- Operating system
- Steps to reproduce
- Expected vs actual behavior
- Error messages

## Common Issues and Solutions

### Installation Issues

**"command not found: model-checker"**
- Python scripts not in PATH
- Try: `python -m model_checker --version`
- Solution: Add Python bin to PATH or use venv

**"ModuleNotFoundError: model_checker"**
- Not installed in current environment
- Solution: `pip install model-checker` or activate venv

**"Python version too old"**
- Requires Python 3.8+
- Check: `python --version`
- Solution: Upgrade Python or use pyenv

### Claude Code Issues

**"claude: command not found"**
- Not installed or not in PATH
- Solution: Reinstall using platform commands

**Authentication failures**
```bash
claude auth logout
claude auth login
```

### GitHub CLI Issues

**"gh: command not found"**
- Not installed
- Solution: Install via platform package manager

**Authentication issues**
```bash
gh auth logout
gh auth login
```

## When to Reference Detailed Docs

| User Need | Reference Document |
|-----------|-------------------|
| Terminal basics | `Docs/installation/GETTING_STARTED.md` |
| Python installation | `Docs/installation/BASIC_INSTALLATION.md` |
| Virtual environments | `Docs/installation/VIRTUAL_ENVIRONMENTS.md` |
| Git/GitHub setup | `Docs/installation/GIT_GOING.md` |
| Claude Code features | `Docs/installation/CLAUDE_CODE.md` |
| Platform issues | `Docs/installation/TROUBLESHOOTING.md` |
| Jupyter setup | `Docs/installation/JUPYTER_SETUP.md` |
| Contributing | `Docs/installation/DEVELOPER_SETUP.md` |

## Quick Prompts for Users

Suggest these prompts to users for Claude Code:

**Installation:**
```
Follow the instructions in Docs/installation/BASIC_INSTALLATION.md
to install ModelChecker and verify it works.
```

**Project creation:**
```
Create a new ModelChecker project using the logos theory
to test whether modus ponens is valid.
```

**Troubleshooting:**
```
I'm getting an error when running model-checker. Please help
diagnose based on Docs/installation/TROUBLESHOOTING.md.
```

**Issue creation:**
```
Help me create a GitHub issue on the ModelChecker repository
with this error information: [paste error]
```
