# Migration Guide: Moving to This Configuration with Claude Code

## Table of Contents

- [Introduction](#introduction)
- [Before You Begin](#before-you-begin)
- [Migration Overview](#migration-overview)
- [Phase 1: Inventory Your Current Configuration](#phase-1-inventory-your-current-configuration)
- [Phase 2: Install New Configuration](#phase-2-install-new-configuration)
- [Phase 3: Extract and Preserve Customizations](#phase-3-extract-and-preserve-customizations)
- [Phase 4: Integrate Your Customizations](#phase-4-integrate-your-customizations)
- [Phase 5: Validate and Test](#phase-5-validate-and-test)
- [Rollback Procedures](#rollback-procedures)
- [Troubleshooting](#troubleshooting)

## Introduction

This guide helps you migrate from your existing Neovim configuration to this one while preserving your personal customizations, keybindings, and preferences.

**Key Difference from Fresh Install**: This guide assumes you have an existing, working Neovim setup that you want to transition from, rather than starting from scratch.

### Who This Guide Is For

- Users with existing Neovim configurations who want to adopt this setup
- Users who have custom keybindings they want to preserve
- Users with plugin configurations they want to maintain
- Users who want a systematic, AI-assisted migration process

### What You'll Preserve

Claude Code will help you identify and preserve:
- Custom keybindings and mappings
- Personal color scheme preferences
- Plugin choices and configurations
- LSP server customizations
- Filetype-specific settings
- Snippets and templates
- Personal utility functions
- Workflow-specific configurations

## Before You Begin

### Prerequisites

1. **Install Claude Code** if you haven't already
   - See [Claude Code Installation Guide](CLAUDE_CODE_INSTALL.md#phase-1-install-claude-code)

2. **Verify Current Configuration Works**
   ```bash
   # Launch your current Neovim to ensure it's working
   nvim
   # Check health
   :checkhealth
   ```

3. **Know Your Configuration Location**
   ```bash
   # Most users have configuration here
   ls -la ~/.config/nvim
   ```

### Estimated Time

- **Quick Migration** (minimal customizations): 30-45 minutes
- **Standard Migration** (moderate customizations): 1-2 hours
- **Complex Migration** (heavily customized): 2-4 hours

### Safety First

This guide emphasizes **non-destructive migration**:
- Your original configuration is backed up
- Changes are made incrementally
- Rollback procedures are provided
- Testing happens at each phase

## Migration Overview

The migration process follows these phases:

```
┌─────────────────────────────────────────────────────────────┐
│                    Migration Workflow                       │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────┐
        │  Phase 1: Inventory Current      │
        │  • Claude analyzes your config    │
        │  • Extracts customizations        │
        │  • Creates inventory report       │
        └───────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────┐
        │  Phase 2: Install New Config     │
        │  • Backup old configuration       │
        │  • Install new configuration      │
        │  • Verify new config works        │
        └───────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────┐
        │  Phase 3: Extract Customizations │
        │  • Export keybindings             │
        │  • Export plugin configs          │
        │  • Export personal functions      │
        └───────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────┐
        │  Phase 4: Integrate              │
        │  • Add keybindings to new config  │
        │  • Port plugin configurations     │
        │  • Migrate personal settings      │
        └───────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────┐
        │  Phase 5: Validate and Test      │
        │  • Test all keybindings           │
        │  • Verify plugins work            │
        │  • Run health checks              │
        └───────────────────────────────────┘
                            │
                            ▼
                     ✓ Migration Complete!
```

## Phase 1: Inventory Your Current Configuration

Before making any changes, let Claude Code analyze your existing configuration and create an inventory of your customizations.

### Step 1: Launch Claude Code in Your Current Config Directory

```bash
cd ~/.config/nvim
claude
```

### Step 2: Request Configuration Inventory

**Prompt for Claude Code:**
```
I want to migrate to a new Neovim configuration while preserving my customizations.
Please analyze my current configuration and create a comprehensive inventory report that includes:

1. All custom keybindings and mappings (not from plugins)
2. Personal plugin configurations and settings
3. Custom color scheme and UI preferences
4. LSP server configurations and customizations
5. Filetype-specific settings and autocmds
6. Custom functions and utility code
7. Personal snippets and templates
8. Any workflow-specific configurations

Create a detailed report saved as migration-inventory.md that categorizes these items
and notes which are essential vs nice-to-have.
```

Claude Code will:
1. Read your configuration files (`init.lua`, `init.vim`, or structured configs)
2. Identify customizations vs standard plugin code
3. Extract your personal keybindings
4. Document plugin configurations
5. Note color scheme and UI preferences
6. Create a categorized inventory report

### Step 3: Review the Inventory Report

```bash
# Claude Code will create this file
cat migration-inventory.md
```

**Review the report and mark items:**
- **MUST HAVE**: Essential keybindings and workflows
- **NICE TO HAVE**: Preferences you'd like to keep
- **OPTIONAL**: Things you can live without

### Step 4: Identify Conflicts

**Prompt for Claude Code:**
```
Based on my inventory, please identify potential conflicts with the new configuration at [repository URL or local path]. Specifically:

1. Keybindings that might conflict with the new config's defaults
2. Plugins I use that aren't in the new configuration
3. Settings that might be incompatible
4. Any deprecated features I'm using

Create a conflicts report and suggest resolution strategies.
```

### Example Inventory Report Structure

Claude Code will generate something like:

```markdown
# Neovim Configuration Migration Inventory

## Custom Keybindings (15 total)

### Essential (MUST HAVE)
- `<leader>p`: Personal project switcher
- `<C-s>`: Quick save (conflicting: new config uses <leader>w)
- `<leader>gg`: Custom git workflow

### Nice to Have
- `<leader>t`: Toggle terminal
- `jk`: Exit insert mode

## Plugin Configurations (8 plugins)

### Plugins in New Config (keep settings)
- telescope.nvim: Custom file ignore patterns
- nvim-tree: Personal directory structure

### Plugins NOT in New Config (port or replace)
- vim-easymotion: Not in new config (replace with leap.nvim?)
- personal-plugin: Custom plugin (needs manual integration)

## Color Scheme
- Current: gruvbox with custom highlights
- New config uses: catppuccin (consider keeping custom highlights)

## LSP Customizations
- Custom key mappings for LSP actions
- Specific server settings for [language]

## Personal Functions (5 functions)
- `ToggleQuickfix()`: Custom quickfix toggle
- `SmartTab()`: Custom tab behavior
[...]
```

## Phase 2: Install New Configuration

Now that you have an inventory, install the new configuration alongside your backup.

### Step 1: Backup Your Current Configuration

```bash
# Create timestamped backup
BACKUP_DIR="$HOME/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)"
mv ~/.config/nvim "$BACKUP_DIR"
echo "Backup created at: $BACKUP_DIR"

# Also backup Neovim data directory
mv ~/.local/share/nvim ~/.local/share/nvim.backup.$(date +%Y%m%d_%H%M%S)
```

**Important**: Keep this backup until migration is complete and validated.

### Step 2: Install New Configuration

Follow the [Claude Code-Assisted Installation Guide](CLAUDE_CODE_INSTALL.md) to install the new configuration:

```bash
# Quick reference - see full guide for details
cd ~/.config
gh repo fork [ORIGINAL-REPO] --clone nvim
cd nvim
git remote add upstream [ORIGINAL-REPO-URL]
git branch -u upstream/main
```

### Step 3: Verify New Configuration Works

```bash
# Launch Neovim with new configuration
nvim

# Wait for plugins to install (2-5 minutes)
# Then run health check
:checkhealth
```

**Do not proceed until the new configuration is working properly.**

### Step 4: Create Migration Branch

```bash
cd ~/.config/nvim
git checkout -b migration-from-old-config
```

This keeps your migration changes separate from the main branch.

## Phase 3: Extract and Preserve Customizations

Now extract your customizations from the backup into portable files.

### Step 1: Extract Keybindings

**Prompt for Claude Code:**
```
I have my old configuration backed up at [backup path]. Please extract all my custom keybindings from the backup and create a file called personal_keymaps.lua that I can use with the new configuration.

The file should:
1. Only include MY custom keybindings (not plugin defaults)
2. Use the new config's keymap format: vim.keymap.set()
3. Group keybindings by category (editing, navigation, git, etc.)
4. Include descriptions for each binding
5. Note any conflicts with the new config's defaults

Old config location: $HOME/.config/nvim.backup.[timestamp]
```

Claude Code will create `personal_keymaps.lua`:

```lua
-- Personal Keybindings
-- Extracted from old configuration on [date]
--
-- CONFLICTS RESOLVED:
-- - Changed <C-s> to <leader>ss (was conflicting with new default)
-- - Removed <leader>ff (now using new config's Telescope binding)

local map = vim.keymap.set

-- === Editing ===
map("n", "jk", "<Esc>", { desc = "Exit insert mode" })
map("n", "<leader>ss", ":w<CR>", { desc = "Quick save (was <C-s>)" })

-- === Navigation ===
map("n", "<leader>p", ":lua require('personal.project_switcher')()<CR>",
    { desc = "Personal project switcher" })

-- === Git ===
map("n", "<leader>gg", ":lua require('personal.git_workflow')()<CR>",
    { desc = "Custom git workflow" })

-- === Terminal ===
map("n", "<leader>tt", ":ToggleTerm<CR>", { desc = "Toggle terminal" })
```

### Step 2: Extract Personal Functions

**Prompt for Claude Code:**
```
Extract my custom functions from the old configuration and create a personal_functions.lua file. Include:
1. All custom Lua functions I wrote
2. Vimscript functions converted to Lua if possible
3. Any utility functions I use regularly
4. Documentation for each function

Old config location: $HOME/.config/nvim.backup.[timestamp]
```

### Step 3: Extract Plugin Configurations

**Prompt for Claude Code:**
```
Compare my old plugin configurations with the new configuration's plugin setup. For each plugin:

1. If the plugin exists in both configs, extract my custom settings
2. If the plugin only exists in my old config, note it for potential addition
3. Create a personal_plugin_configs.lua with my customizations

Old config: $HOME/.config/nvim.backup.[timestamp]
New config: $HOME/.config/nvim
```

### Step 4: Extract Color Scheme Customizations

**Prompt for Claude Code:**
```
Extract my color scheme customizations from the old config and create a personal_theme.lua file that applies my custom highlights on top of the new configuration's theme.

Old config location: $HOME/.config/nvim.backup.[timestamp]
```

### Step 5: Extract Snippets and Templates

```bash
# Copy snippets if you have custom ones
cp -r $HOME/.config/nvim.backup.[timestamp]/snippets ~/.config/nvim/snippets-personal

# Copy templates
cp -r $HOME/.config/nvim.backup.[timestamp]/templates ~/.config/nvim/templates-personal
```

**Prompt for Claude Code:**
```
Review the snippets I copied to snippets-personal/ and help me integrate them with the new configuration's snippet system.
```

## Phase 4: Integrate Your Customizations

Now integrate your extracted customizations into the new configuration.

### Step 1: Create Personal Configuration Directory

```bash
cd ~/.config/nvim
mkdir -p lua/neotex/personal
```

### Step 2: Add Your Personal Files

Move your extracted files into the configuration:

```bash
# Move files created by Claude Code
mv personal_keymaps.lua lua/neotex/personal/
mv personal_functions.lua lua/neotex/personal/
mv personal_plugin_configs.lua lua/neotex/personal/
mv personal_theme.lua lua/neotex/personal/
```

### Step 3: Create Personal Module Loader

**Prompt for Claude Code:**
```
Create a file lua/neotex/personal/init.lua that loads all my personal modules in the correct order. Make sure it handles errors gracefully if any file is missing.
```

Claude Code will create something like:

```lua
-- Personal Configuration Loader
-- This file loads all personal customizations

local M = {}

-- Load personal modules in order
local modules = {
  "neotex.personal.functions",      -- Load functions first (others may need them)
  "neotex.personal.plugin_configs", -- Plugin configs second
  "neotex.personal.keymaps",        -- Keymaps third (may depend on plugins)
  "neotex.personal.theme",          -- Theme overrides last
}

function M.setup()
  for _, module in ipairs(modules) do
    local ok, err = pcall(require, module)
    if not ok then
      vim.notify(
        string.format("Failed to load personal module '%s': %s", module, err),
        vim.log.levels.WARN
      )
    end
  end
end

return M
```

### Step 4: Load Personal Configuration

Add this to `lua/neotex/init.lua`:

```bash
nvim lua/neotex/init.lua
```

**Prompt for Claude Code:**
```
Add a line to load my personal configuration in lua/neotex/init.lua.
It should be loaded after the core configuration but before plugins are fully initialized.
Show me exactly where to add it.
```

Typically you'll add:

```lua
-- Near the end of lua/neotex/init.lua
-- Load personal configuration
local personal_ok, personal = pcall(require, "neotex.personal")
if personal_ok then
  personal.setup()
else
  vim.notify("Personal configuration not loaded", vim.log.levels.INFO)
end
```

### Step 5: Integrate Plugin Additions

If you have plugins from your old config that you want to add:

**Prompt for Claude Code:**
```
I want to add these plugins from my old configuration:
- [plugin-name-1]: [brief description of what you use it for]
- [plugin-name-2]: [brief description]

Please create a lua/neotex/plugins/personal.lua file that adds these plugins using lazy.nvim's format, including my custom configurations from personal_plugin_configs.lua.
```

### Step 6: Handle Conflicts

**Prompt for Claude Code:**
```
Review my personal keybindings in personal_keymaps.lua and check for conflicts with the new configuration's default keybindings. For any conflicts, suggest:

1. Whether to keep the new default or use my custom binding
2. Alternative keybindings if there's a conflict
3. Which bindings are redundant (already provided by new config)

Generate a conflicts-resolution.md report.
```

Review the conflicts and resolve them:

```bash
# Edit your personal keymaps based on recommendations
nvim lua/neotex/personal/keymaps.lua
```

## Phase 5: Validate and Test

Thoroughly test your migrated configuration.

### Step 1: Restart Neovim

```bash
# Quit any running Neovim instances
# Start fresh
nvim
```

Watch for errors during startup. Check messages:

```vim
:messages
```

### Step 2: Test Your Keybindings

**Prompt for Claude Code:**
```
Generate a testing checklist for all my personal keybindings. For each keybinding, provide:
1. The key combination
2. Expected behavior
3. How to verify it worked

Save as keybinding-test-checklist.md
```

Work through the checklist:

```bash
nvim keybinding-test-checklist.md
```

Test each keybinding and mark as working or broken.

### Step 3: Test Personal Functions

```vim
" Test each personal function
:lua require('neotex.personal.functions').test_function_name()
```

### Step 4: Test Plugin Integrations

**Prompt for Claude Code:**
```
Create a test plan for all plugins I've configured or added. Include:
1. How to launch each plugin
2. What to test
3. Common issues to watch for
```

### Step 5: Run Health Checks

```vim
:checkhealth
```

**Prompt for Claude Code:**
```
I got these health check results: [paste output]

Please identify:
1. Any issues related to my personal configurations
2. Issues unrelated to my customizations (can ignore)
3. Recommended fixes for any problems
```

### Step 6: Test LSP Functionality

Open files in languages you use and verify:

```vim
" Open a source file
:e path/to/source/file

" Test LSP features
gd    " Go to definition
K     " Hover documentation
<leader>ca  " Code actions (if you have this binding)
```

### Step 7: Validate Color Scheme

Check that your color scheme customizations are applied:

```vim
:hi Normal  " Check normal highlight
:hi Comment " Check comment highlight
```

### Step 8: Performance Check

```vim
" Check startup time
:lua print(vim.fn.printf("%.2f ms", vim.fn.reltimefloat(vim.fn.reltime(vim.g.start_time))))

" If slow, profile startup
nvim --startuptime startup.log
```

**Prompt for Claude Code:**
```
I'm getting slow startup times. Can you analyze my personal configuration and identify potential performance issues?

My personal config is in lua/neotex/personal/
```

## Rollback Procedures

If migration isn't working, you can rollback to your original configuration.

### Complete Rollback

```bash
# Remove new configuration
rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim

# Restore backup
mv $HOME/.config/nvim.backup.[timestamp] ~/.config/nvim
mv $HOME/.local/share/nvim.backup.[timestamp] ~/.local/share/nvim

# Verify
nvim
```

### Partial Rollback (Disable Personal Config)

If the new config works but your personal customizations cause issues:

```lua
-- Comment out in lua/neotex/init.lua
-- local personal_ok, personal = pcall(require, "neotex.personal")
-- if personal_ok then
--   personal.setup()
-- end
```

### Selective Rollback (Disable Specific Modules)

Edit `lua/neotex/personal/init.lua` and comment out problematic modules:

```lua
local modules = {
  "neotex.personal.functions",
  -- "neotex.personal.plugin_configs",  -- Disabled: causing issues
  "neotex.personal.keymaps",
  "neotex.personal.theme",
}
```

## Troubleshooting

### Common Issues

**Issue: Keybindings Not Working**

**Prompt for Claude Code:**
```
My personal keybindings in lua/neotex/personal/keymaps.lua aren't working. Can you:
1. Check if the file is being loaded
2. Verify the keymap syntax is correct
3. Check for conflicts with plugins or other keymaps
4. Suggest fixes
```

**Issue: Plugins Not Loading**

```vim
" Check lazy.nvim status
:Lazy

" Check for errors
:messages
```

**Prompt for Claude Code:**
```
My personal plugins aren't loading. Here's my personal.lua file: [paste file]
And here's the error from :Lazy: [paste error]

Please help me fix this.
```

**Issue: Functions Returning Errors**

```vim
:messages  " Check error messages
```

**Prompt for Claude Code:**
```
I'm getting this error from my personal functions: [paste error]

The function is in lua/neotex/personal/functions.lua
Can you help debug and fix it?
```

**Issue: Color Scheme Not Applied**

**Prompt for Claude Code:**
```
My personal theme customizations aren't being applied.
File: lua/neotex/personal/theme.lua
New config's default theme: [theme name]

Please check:
1. If the file is loaded after the default theme
2. If highlight commands are correct for the theme
3. If there are any conflicts
```

**Issue: Slow Startup After Migration**

```bash
nvim --startuptime startup.log
cat startup.log | tail -20
```

**Prompt for Claude Code:**
```
After migration, Neovim startup is slow. Here's the startup log: [paste relevant sections]

My personal configs are in lua/neotex/personal/

Please identify:
1. Which personal configs are slowing startup
2. How to optimize them (lazy loading, etc.)
3. What can be deferred to after startup
```

### Getting Help

If you're stuck, Claude Code can help:

```bash
cd ~/.config/nvim
claude
```

**Comprehensive troubleshooting prompt:**
```
I'm having issues with my Neovim migration. Here's the situation:

1. Old config backup location: [path]
2. New config location: ~/.config/nvim
3. Personal configs location: ~/.config/nvim/lua/neotex/personal/
4. Issue: [describe the problem]
5. Error messages: [paste any errors]
6. What I've tried: [list troubleshooting steps]

Please help me diagnose and fix this issue.
```

## Best Practices for Migration

### 1. Migrate Incrementally

Don't try to port everything at once:
- Start with essential keybindings
- Add one plugin at a time
- Test after each addition

### 2. Embrace New Defaults

Before porting a keybinding, check if the new config has better defaults:

**Prompt for Claude Code:**
```
Before I port my keybinding for [action], does the new configuration have a built-in way to do this? If so, what is it and should I use it instead?
```

### 3. Document Your Changes

Keep a migration log:

```bash
nvim ~/migration-log.md
```

Document:
- What you ported
- What you decided not to port (and why)
- Issues you encountered and solutions
- Keybindings you changed

### 4. Use Feature Branches

```bash
# Separate branches for different aspects
git checkout -b migration-keymaps
# Port keymaps
git commit -am "Port personal keymaps"

git checkout migration-from-old-config
git checkout -b migration-plugins
# Port plugins
git commit -am "Add personal plugins"
```

### 5. Stay Synchronized with Upstream

```bash
# Regularly pull updates
git checkout main
git pull upstream main

# Merge into your migration branch
git checkout migration-from-old-config
git merge main
```

## Post-Migration

### Clean Up

Once migration is complete and validated (after 1-2 weeks):

```bash
# Remove backup (ONLY WHEN CONFIDENT)
rm -rf ~/.config/nvim.backup.*
rm -rf ~/.local/share/nvim.backup.*

# Remove temporary files
rm -f migration-inventory.md
rm -f conflicts-resolution.md
rm -f keybinding-test-checklist.md
```

### Commit Your Changes

```bash
cd ~/.config/nvim
git add lua/neotex/personal/
git commit -m "Add personal configuration from migration

Migrated from previous Neovim setup:
- Personal keybindings
- Custom functions
- Plugin configurations
- Theme customizations

Migration completed: $(date +%Y-%m-%d)
"

git push origin migration-from-old-config
```

### Create Documentation for Your Customizations

```bash
nvim lua/neotex/personal/README.md
```

Document:
- What each personal module does
- Why you added specific customizations
- How to modify or extend them

**Prompt for Claude Code:**
```
Generate a README.md for my personal configuration directory (lua/neotex/personal/) that documents:
1. What each file does
2. How to modify my customizations
3. Dependencies between files
4. Any special considerations
```

## Next Steps

After successful migration:

1. **Learn New Features**: Explore features in the new configuration you didn't have before
   - See [Main README](../README.md) for feature overview

2. **Optimize Workflow**: Use Claude Code to improve your workflow
   ```
   Analyze my personal keybindings and suggest optimizations based on the new configuration's features
   ```

3. **Contribute Back**: If you made useful improvements, consider contributing
   - See [CLAUDE_CODE_INSTALL.md Phase 5](CLAUDE_CODE_INSTALL.md#contributing-back-to-upstream)

4. **Stay Updated**: Regular sync with upstream
   ```bash
   # Weekly or monthly
   git fetch upstream
   git checkout main
   git merge upstream/main
   git checkout migration-from-old-config
   git merge main
   ```

## Additional Resources

- **Fresh Install Guide**: [CLAUDE_CODE_INSTALL.md](CLAUDE_CODE_INSTALL.md) - Full installation guide
- **Quick Reference**: [CLAUDE_CODE_QUICK_REF.md](CLAUDE_CODE_QUICK_REF.md) - Common Claude Code prompts
- **Manual Installation**: [INSTALLATION.md](INSTALLATION.md) - Traditional setup without Claude Code
- **Advanced Features**: [ADVANCED_SETUP.md](ADVANCED_SETUP.md) - Optional features
- **Architecture**: [ARCHITECTURE.md](ARCHITECTURE.md) - How the configuration is organized

## Navigation

- **Parent Guide**: [Main README](../README.md)
- **Related Documentation**:
  - [Claude Code Installation Guide](CLAUDE_CODE_INSTALL.md)
  - [Manual Installation Guide](INSTALLATION.md)
  - [Advanced Setup](ADVANCED_SETUP.md)
  - [Glossary](GLOSSARY.md)
