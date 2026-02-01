# Copy .claude/ Directory Guide

[Back to Docs](../README.md) | [User Installation](user-installation.md) | [Commands Reference](../commands/README.md)

Instructions for copying the `.claude/` agent system directory from the ProofChecker repository into your project.

---

## What is the .claude/ System?

The `.claude/` directory provides an agent system for Claude Code that enhances your development workflow with:

- **Task Management Commands**: `/task`, `/research`, `/plan`, `/implement` - structured workflow for development tasks
- **Specialized Skills**: Language-specific agents for Lean 4 theorem proving
- **Context Files**: Domain knowledge for logic, semantics, and formal verification
- **State Tracking**: TODO.md and state.json for persistent task tracking across sessions
- **Lean MCP Integration**: Tools for proof state inspection, lemma search, and diagnostics

Once installed, you can create numbered tasks, conduct research, create implementation plans, and execute them with automatic progress tracking.

---

## Prerequisites

Before proceeding, ensure you have:

1. **Git installed**
   ```bash
   git --version
   ```
   If not installed, see [Git Installation Guide](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

2. **Claude Code installed and authenticated**
   ```bash
   claude --version
   claude auth status
   ```

3. **A target project directory**
   - This should be the root directory where you run Claude Code
   - The `.claude/` directory will be placed here

---

## Installation Instructions

### macOS / Linux

#### Method 1: Full Clone (Recommended)

The simplest approach - clone the full repository and copy the directory:

```bash
# Navigate to a temporary location
cd /tmp

# Clone the ProofChecker repository
git clone https://github.com/benbrastmckie/ProofChecker.git

# Copy .claude/ to your project (replace YOUR_PROJECT_PATH)
cp -r ProofChecker/.claude YOUR_PROJECT_PATH/

# Clean up
rm -rf ProofChecker
```

**Example** - if your project is at `~/Documents/Projects/my-project`:
```bash
cd /tmp
git clone https://github.com/benbrastmckie/ProofChecker.git
cp -r ProofChecker/.claude ~/Documents/Projects/my-project/
rm -rf ProofChecker
```

#### Method 2: Sparse Checkout (Minimal Download)

For users who want to minimize download size:

```bash
# Navigate to a temporary location
cd /tmp

# Clone with sparse checkout (downloads minimal data)
git clone --filter=blob:none --sparse https://github.com/benbrastmckie/ProofChecker.git

# Set sparse checkout to only include .claude/
cd ProofChecker
git sparse-checkout set .claude

# Copy to your project
cp -r .claude YOUR_PROJECT_PATH/

# Clean up
cd /tmp
rm -rf ProofChecker
```

---

### Windows (PowerShell)

#### Method 1: Full Clone (Recommended)

```powershell
# Navigate to a temporary location
cd $env:TEMP

# Clone the ProofChecker repository
git clone https://github.com/benbrastmckie/ProofChecker.git

# Copy .claude/ to your project (replace YOUR_PROJECT_PATH)
Copy-Item -Recurse ProofChecker\.claude YOUR_PROJECT_PATH\

# Clean up
Remove-Item -Recurse -Force ProofChecker
```

**Example** - if your project is at `C:\Users\YourName\Projects\my-project`:
```powershell
cd $env:TEMP
git clone https://github.com/benbrastmckie/ProofChecker.git
Copy-Item -Recurse ProofChecker\.claude C:\Users\YourName\Projects\my-project\
Remove-Item -Recurse -Force ProofChecker
```

#### Method 2: Sparse Checkout (Minimal Download)

```powershell
# Navigate to a temporary location
cd $env:TEMP

# Clone with sparse checkout
git clone --filter=blob:none --sparse https://github.com/benbrastmckie/ProofChecker.git

# Set sparse checkout
cd ProofChecker
git sparse-checkout set .claude

# Copy to your project
Copy-Item -Recurse .claude YOUR_PROJECT_PATH\

# Clean up
cd $env:TEMP
Remove-Item -Recurse -Force ProofChecker
```

---

## Using Claude Code to Install

You can ask Claude Code to perform the installation for you. Paste this prompt into Claude Code:

```
Please clone the ProofChecker repository from https://github.com/benbrastmckie/ProofChecker.git
to a temporary location, then copy the .claude/ directory to the current working directory.
After copying, remove the cloned repository to clean up.
```

Claude will execute the appropriate commands for your platform.

---

## Verification

After copying, verify the installation:

### 1. Check Directory Structure

```bash
# macOS/Linux
ls -la .claude/

# Windows PowerShell
Get-ChildItem .claude\
```

You should see directories including:
- `commands/` - Slash command definitions
- `skills/` - Specialized agent skills
- `rules/` - Automatic behavior rules
- `context/` - Domain knowledge
- `specs/` - Task artifacts and state
- `docs/` - Documentation

### 2. Check Key Files Exist

```bash
# macOS/Linux
ls specs/TODO.md specs/state.json

# Windows PowerShell
Test-Path .claude\specs\TODO.md, .claude\specs\state.json
```

### 3. Restart Claude Code

**Important**: After copying the `.claude/` directory, you must restart Claude Code for the commands to be available.

Exit Claude Code:
```
/exit
```

Then start it again:
```bash
claude
```

### 4. Test Commands

After restarting, test that commands work:

```
/task "Test task creation"
```

If successful, you'll see a confirmation that a new task was created. You can then delete the test task:

```
/task --abandon 1
```

---

## Troubleshooting

### "Permission denied" errors

**macOS/Linux:**
```bash
# Check current directory permissions
ls -la

# If needed, ensure you own the directory
sudo chown -R $(whoami) .
```

**Windows (Run PowerShell as Administrator):**
```powershell
# Take ownership if needed
takeown /f .claude /r
```

### "git: command not found"

Git is not installed. Install it:

- **macOS**: `brew install git` or download from [git-scm.com](https://git-scm.com)
- **Linux**: `sudo apt install git` (Debian/Ubuntu) or `sudo dnf install git` (Fedora)
- **Windows**: Download from [git-scm.com](https://git-scm.com/download/win)

### ".claude/ directory already exists"

If you already have a `.claude/` directory and want to replace it:

```bash
# macOS/Linux - backup existing
mv .claude .claude.backup

# Windows PowerShell - backup existing
Rename-Item .claude .claude.backup
```

Then proceed with the installation. After verifying the new installation works, you can delete the backup:

```bash
# macOS/Linux
rm -rf .claude.backup

# Windows PowerShell
Remove-Item -Recurse -Force .claude.backup
```

### Commands not available after copying

1. Ensure you restarted Claude Code after copying
2. Verify you're in the correct directory (where `.claude/` was copied)
3. Check that `.claude/commands/` contains `.md` files

---

## Customization Notes

### Adapting for Non-Lean Projects

The ProofChecker `.claude/` system is optimized for Lean 4 theorem proving. If you're using it for other projects:

1. **Language routing**: The system routes Lean tasks to specialized Lean agents. Update `state.json` task language field for your needs.

2. **Context files**: The `context/project/lean4/` directory contains Lean-specific knowledge. You may want to add context for your domain.

3. **MCP tools**: Lean MCP tools (`lean_goal`, `lean_leansearch`, etc.) require the lean-lsp MCP server. For non-Lean projects, these tools won't be available.

### Key Configuration Files

| File | Purpose |
|------|---------|
| `.claude/CLAUDE.md` | Main entry point, quick reference |
| `specs/state.json` | Machine-readable task state |
| `specs/TODO.md` | Human-readable task list |
| `.claude/settings.json` | Claude Code settings |

---

## Next Steps

After installation, explore the available commands:

- **[Commands Reference](../commands/README.md)** - Full documentation of all commands
- **[User Installation Guide](user-installation.md)** - Complete setup guide
- **[Documentation Hub](../README.md)** - All documentation

### Quick Start with Commands

```
/task "My first task"     # Create a task
/research 1               # Research the task
/plan 1                   # Create implementation plan
/implement 1              # Execute the plan
/todo                     # Archive completed tasks
```

---

[Back to Docs](../README.md) | [User Installation](user-installation.md) | [Commands Reference](../commands/README.md)
