# Copy .opencode/ Directory Guide

[Back to Docs](../README.md) | [User Installation](user-installation.md) | [Commands Reference](../commands/README.md)

Instructions for copying the `.opencode/` agent system directory for Neovim configuration maintenance.

---

## What is the .opencode/ System?

The `.opencode/` directory provides an agent system for Claude Code that enhances your development workflow with:

- **Task Management Commands**: `/task`, `/research`, `/plan`, `/implement` - structured workflow for development tasks
- **Specialized Skills**: Language-specific agents for Neovim configuration (neovim), web development, and general tasks
- **Context Files**: Domain knowledge for Neovim, lazy.nvim, LSP, treesitter, and Lua patterns
- **State Tracking**: TODO.md and state.json for persistent task tracking across sessions
- **Extensible Architecture**: Easy to add new domain contexts for additional specializations

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
   - The `.opencode/` directory will be placed here

---

## What to Copy

### Core Files (Always Copy)

These are the essential files for the system to function:

```
.opencode/
├── CLAUDE.md                    # Main configuration
├── commands/                    # Slash commands
├── skills/                      # Skill definitions
├── agents/                      # Agent definitions
├── rules/                       # Auto-applied rules
├── context/
│   ├── core/                   # Core patterns and standards
│   └── project/
│       └── neovim/             # Neovim domain context
├── docs/                        # Documentation
└── settings.json               # Claude settings
```

### Task State Files (Fresh Start)

For a fresh installation, initialize these files:

**specs/state.json**:

```json
{
  "next_project_number": 1,
  "active_projects": [],
  "repository_health": {
    "last_assessed": null,
    "status": "healthy"
  }
}
```

**specs/TODO.md**:

```markdown
# TODO

## Tasks

(No tasks yet)
```

---

## What to Customize

After copying, customize these files for your project:

### 1. CLAUDE.md

Update the project structure section to match your Neovim config:

```markdown
## Project Structure

nvim/
├── lua/
│ ├── config/ # Core configuration
│ ├── plugins/ # Plugin specifications
│ └── utils/ # Utility functions
├── after/ftplugin/ # Filetype plugins
└── init.lua # Entry point
```

### 2. Context Files

The `context/project/neovim/` directory contains:

- Lua patterns and conventions
- Plugin ecosystem overview
- lazy.nvim configuration patterns
- LSP setup guides
- Treesitter integration

Customize or extend based on your specific plugins and setup.

### 3. Rules

The `rules/neovim-lua.md` rule applies to `nvim/**/*.lua` files. Adjust patterns if your config uses different paths.

---

## Extension Points

### Adding New Domain Contexts

To add a new domain (e.g., for a specific framework):

1. Create directory: `.opencode/context/project/your-domain/`
2. Add context files following the existing patterns
3. Create domain-specific agents if needed
4. Update routing in `skill-orchestrator/SKILL.md`

See [Adding Domains Guide](adding-domains.md) for detailed instructions.

### Adding New Languages

To support a new language type:

1. Add entry to routing table in `skill-orchestrator/SKILL.md`
2. Create `skill-{language}-research/SKILL.md`
3. Create `skill-{language}-implementation/SKILL.md`
4. Create corresponding agent files
5. Update `CLAUDE.md` documentation

---

## Installation Instructions

### macOS / Linux

```bash
# Navigate to a temporary location
cd /tmp

# Clone the repository (replace with your source)
git clone https://github.com/your-repo.git source-repo

# Copy .opencode/ to your Neovim config directory
cp -r source-repo/.opencode ~/.config/

# Initialize specs directory
mkdir -p ~/.config/specs
echo '{"next_project_number":1,"active_projects":[]}' > ~/.config/specs/state.json
echo '# TODO\n\n## Tasks\n' > ~/.config/specs/TODO.md

# Clean up
rm -rf source-repo
```

### Windows (PowerShell)

```powershell
cd $env:TEMP

git clone https://github.com/your-repo.git source-repo

Copy-Item -Recurse source-repo\.opencode $env:LOCALAPPDATA\nvim\

# Initialize specs
New-Item -ItemType Directory -Force -Path $env:LOCALAPPDATA\nvim\specs
'{"next_project_number":1,"active_projects":[]}' | Out-File $env:LOCALAPPDATA\nvim\specs\state.json
'# TODO`n`n## Tasks`n' | Out-File $env:LOCALAPPDATA\nvim\specs\TODO.md

Remove-Item -Recurse -Force source-repo
```

---

## Verification

After copying, verify the installation:

### 1. Check Directory Structure

```bash
ls -la .opencode/
```

You should see:

- `commands/` - Slash command definitions
- `skills/` - Specialized agent skills
- `agents/` - Agent definitions
- `rules/` - Automatic behavior rules
- `context/` - Domain knowledge

### 2. Restart Claude Code

```
/exit
```

Then start again:

```bash
claude
```

### 3. Test Commands

```
/task "Test task creation" --language neovim
```

---

## Quick Start

After installation:

```
/task "Configure telescope.nvim"     # Create a task
/research 1                           # Research telescope patterns
/plan 1                               # Create implementation plan
/implement 1                          # Execute the plan
/todo                                 # Archive completed tasks
```

---

## Troubleshooting

### Commands not available

1. Ensure you restarted Claude Code
2. Verify you're in the correct directory
3. Check that `.opencode/commands/` contains `.md` files

### Language routing issues

Verify `skill-orchestrator/SKILL.md` has correct routing for your language.

### Missing context

Ensure `context/project/neovim/` was copied correctly.

---

## Next Steps

- **[Adding Domains Guide](adding-domains.md)** - Extend for new domains
- **[Commands Reference](../commands/README.md)** - Full command documentation
- **[User Installation Guide](user-installation.md)** - Complete setup guide

---

[Back to Docs](../README.md) | [User Installation](user-installation.md) | [Commands Reference](../commands/README.md)
