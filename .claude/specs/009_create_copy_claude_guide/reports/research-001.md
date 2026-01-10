# Research Report: Task #9

**Task**: Create copy-claude-directory.md Guide
**Date**: 2026-01-10
**Focus**: Integration patterns and project-specific adaptations

## Summary

The ModelChecker `.claude/docs/guides/copy-claude-directory.md` provides comprehensive instructions for copying the `.claude/` agent system to other projects. This project needs an adapted version that references the correct GitHub repository (`benbrastmckie/.config`) and replaces Python/Z3-specific context with Neovim/Lua development context.

## Findings

### 1. ModelChecker Guide Structure

The source guide follows a well-organized structure:

1. **Introduction** - Explains what the `.claude/` system provides
2. **Prerequisites** - Git and Claude Code requirements
3. **Installation Instructions** - Platform-specific commands
   - macOS/Linux: Full clone and sparse checkout methods
   - Windows PowerShell: Full clone and sparse checkout methods
4. **Claude-Assisted Installation** - Prompt for Claude to perform setup
5. **Verification** - Directory structure and file checks
6. **Troubleshooting** - Common issues and solutions
7. **Next Steps** - Links to related documentation

### 2. Integration Points in ModelChecker

The guide integrates with the documentation system through:

| Integration Point | Location | Purpose |
|-------------------|----------|---------|
| Navigation header | Line 3 | Links to README.md, user-installation.md, commands |
| user-installation.md | Lines 143-156 | References copy-claude-directory.md for agent setup |
| docs/README.md | Guides section | Should list copy-claude-directory.md |

**Key observation**: The user-installation.md references the guide via raw GitHub URL for external access:
```
https://raw.githubusercontent.com/benbrastmckie/ModelChecker/master/.claude/docs/guides/copy-claude-directory.md
```

### 3. Project-Specific Adaptations Required

| ModelChecker Reference | Neovim Config Adaptation |
|------------------------|--------------------------|
| `benbrastmckie/ModelChecker` | `benbrastmckie/.config` |
| Python/Z3 development | Neovim/Lua plugin development |
| `/research 350` examples | Same - generic examples work |
| `model-checker --version` | `nvim --version` |
| "semantic theories" | "Neovim configuration/plugins" |
| `skill-python-research` | `skill-neovim-research` |
| `skill-theory-implementation` | `skill-neovim-implementation` |

### 4. Documentation Structure Differences

**Current docs/guides/ in this project:**
- `context-management.md` - Exists
- `creating-commands.md` - Exists
- `creating-skills.md` - Exists
- `user-installation.md` - Exists (needs update for Neovim context)

**Missing:**
- `copy-claude-directory.md` - To be created

**docs/README.md concerns:**
- Currently still references ModelChecker/Python/Z3
- The guides section needs updating to include the new guide

### 5. GitHub Repository Context

**Source repository**: `https://github.com/benbrastmckie/ModelChecker.git`
**Target repository**: `https://github.com/benbrastmckie/.config.git`

The guide should reference:
- Clone URL: `https://github.com/benbrastmckie/.config.git`
- Raw content URL: `https://raw.githubusercontent.com/benbrastmckie/.config/master/.claude/docs/guides/copy-claude-directory.md`
- Branch: `master` (default) or `main` - verify branch name

### 6. Content to Preserve vs Adapt

**Preserve (universal patterns):**
- Prerequisites section (Git + Claude Code)
- Platform-specific commands (macOS/Linux/Windows)
- Sparse checkout instructions
- Verification steps (directory structure)
- Troubleshooting patterns

**Adapt (project-specific):**
- Introduction explaining Neovim config context
- What the system provides (Lua development, plugin management)
- GitHub repository URLs
- Example commands showing Neovim context
- Next steps linking to Neovim documentation

## Recommendations

1. **Create copy-claude-directory.md** in `.claude/docs/guides/` adapted for this project
   - Replace all ModelChecker references with .config references
   - Update "What is the .claude/ System?" to describe Neovim development focus
   - Update example commands to show Neovim-relevant tasks

2. **Update docs/README.md** to include the new guide in the guides section
   - Add entry: `copy-claude-directory.md - Instructions for copying .claude/ to your projects`

3. **Update user-installation.md** to remove/replace ModelChecker-specific content
   - This is a larger task (may be separate task)
   - For now, ensure copy-claude-directory.md can stand alone

4. **Use navigation pattern** consistent with existing guides:
   ```markdown
   [Back to Docs](../README.md) | [User Installation](user-installation.md) | [Commands Reference](../commands/README.md)
   ```

## References

- Source guide: `/home/benjamin/Projects/ModelChecker/.claude/docs/guides/copy-claude-directory.md`
- ModelChecker docs README: `/home/benjamin/Projects/ModelChecker/.claude/docs/README.md`
- This project's docs README: `.claude/docs/README.md`
- This project's GitHub remote: `git@github.com:benbrastmckie/.config.git`

## Next Steps

1. Create `.claude/docs/guides/copy-claude-directory.md` with adapted content
2. Update `.claude/docs/README.md` documentation map to include new guide
3. Test instructions by verifying GitHub URLs work
4. Consider separate task to fully update user-installation.md for Neovim context
