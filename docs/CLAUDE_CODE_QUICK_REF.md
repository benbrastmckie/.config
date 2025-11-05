# Claude Code Quick Reference for Neovim Setup

Quick reference for common Claude Code prompts during Neovim configuration installation and maintenance.

## Migration Prompts

### Inventory Current Configuration
```
I want to migrate to a new Neovim configuration while preserving my customizations.
Please analyze my current configuration and create a comprehensive inventory report.
```

### Extract Keybindings
```
Extract all my custom keybindings from [backup path] and create a personal_keymaps.lua file using vim.keymap.set() format.
```

### Extract Functions
```
Extract my custom functions from the old configuration at [path] and create a personal_functions.lua file with documentation.
```

### Identify Conflicts
```
Based on my inventory, identify potential conflicts with the new configuration. Suggest resolution strategies for keybinding conflicts and incompatible settings.
```

### Test Migration
```
Generate a testing checklist for all my personal keybindings and functions to verify the migration was successful.
```

## Installation Phase Prompts

### Phase 1: Claude Code Installation
```
I need to install Claude Code on [platform]. Can you guide me through the installation and authentication process?
```

### Phase 2: Repository Setup
```
Help me fork [repository URL] and clone it to ~/.config/nvim with proper upstream configuration.
```

### Phase 3: Dependency Checking
```
Run the dependency checking script (scripts/check-dependencies.sh) and help me install any missing dependencies for my platform.
```

or simply:

```
I'm on [platform]. Check my dependencies and install any missing packages for this Neovim configuration.
```

### Phase 4: First Launch Troubleshooting
```
I ran :checkhealth in Neovim and got these errors:
[paste output]
Can you help me fix them?
```

## Customization Prompts

### Adding Personal Keybindings
```
I want to add a personal keybinding for [action]. Can you help me create a personal_keymaps.lua file and show me how to load it?
```

### Theme Customization
```
I want to customize the color scheme. Can you help me create a personal theme file that won't conflict with upstream updates?
```

### Adding Plugins
```
I want to add the [plugin-name] plugin. Can you help me add it to a personal plugin file following the lazy.nvim pattern?
```

## Maintenance Prompts

### Merging Upstream Updates
```
I need to pull upstream updates. Can you help me fetch from upstream, merge into main, and update my feature branches?
```

### Merge Conflict Resolution
```
I have merge conflicts after pulling upstream updates. The conflicts are in [file names]. Can you help me understand and resolve them while preserving my customizations?
```

### Health Check Diagnostics
```
My LSP isn't working. Can you check my LSP configuration and health check output to diagnose the issue?
```

## Common Debugging Prompts

### Plugin Issues
```
Plugin [name] isn't loading. Can you check its configuration and help me troubleshoot?
```

### LSP Configuration
```
Language server for [language] isn't starting. Can you check Mason configuration and help me install/configure it?
```

### Tree-sitter Errors
```
I'm getting tree-sitter parser errors for [language]. Can you help me rebuild the parsers?
```

### Performance Issues
```
Neovim is starting slowly. Can you analyze my configuration and suggest performance improvements?
```

## Platform-Specific Prompts

### Arch Linux
```
I'm on Arch Linux. Install all required and recommended dependencies for this Neovim configuration using pacman.
```

### Debian/Ubuntu
```
I'm on Ubuntu [version]. Install all dependencies using apt and add any necessary PPAs.
```

### macOS
```
I'm on macOS. Verify I have Homebrew, then install all dependencies for this Neovim configuration.
```

### Windows/WSL
```
I'm on Windows with WSL2. Help me configure WSL properly and install all dependencies for this Neovim setup.
```

## Workflow Automation Prompts

### Complete Setup
```
I want to set up this Neovim configuration. Can you:
1. Check my dependencies
2. Install anything missing
3. Verify my repository is properly configured
4. Run health checks
5. Help me fix any issues found
```

### Update Workflow
```
I haven't updated in a while. Can you:
1. Fetch upstream changes
2. Show me what's changed
3. Help me merge updates
4. Test that everything still works
```

### Backup Creation
```
Help me create a complete backup of my Neovim configuration including all my customizations.
```

## Tips for Effective Claude Code Use

1. **Be Specific**: Include error messages, file names, and context
2. **Paste Output**: Share command output, error messages, and health check results
3. **State Your Platform**: Mention your OS and version for accurate commands
4. **Ask for Explanations**: Request explanations to learn while fixing issues
5. **Test Incrementally**: Ask Claude to verify changes after each step

## Common Workflows

### Fresh Install
1. Install Claude Code
2. Fork and clone repository
3. Run dependency checker
4. Install missing dependencies
5. Launch Neovim
6. Run :checkhealth
7. Fix any issues with Claude Code's help

### Adding Custom Feature
1. Create feature branch
2. Ask Claude Code for implementation guidance
3. Make changes
4. Test changes
5. Commit and push to your fork

### Syncing with Upstream
1. Ask Claude to fetch upstream
2. Review changes
3. Merge into main
4. Update feature branches
5. Resolve conflicts with Claude Code's help

## Navigation

- **Main Installation Guide**: [CLAUDE_CODE_INSTALL.md](CLAUDE_CODE_INSTALL.md)
- **Manual Installation**: [INSTALLATION.md](INSTALLATION.md)
- **Advanced Setup**: [ADVANCED_SETUP.md](ADVANCED_SETUP.md)
- **Main README**: [../README.md](../README.md)
