# Configuration Maintenance

## Plugin Updates

### lazy.nvim Update Commands
```vim
:Lazy update        " Update all plugins
:Lazy sync          " Install, update, and clean
:Lazy restore       " Restore to lock file versions
:Lazy clean         " Remove unused plugins
```

### Update Strategy
1. **Check for breaking changes** before updating
2. **Update lock file** after testing changes
3. **Commit lock file** to preserve reproducible state

### Checking for Updates
```vim
:Lazy check         " Check for available updates
```

### Handling Breaking Changes

#### Before Updating
```bash
# Check plugin changelog
gh release list -R author/plugin-name --limit 10
```

#### After Breaking Change
```lua
-- Version-specific configuration
local version = require("plugin").version
if version and version >= "2.0.0" then
  -- New configuration
else
  -- Legacy configuration
end
```

## Lock File Management

### lazy-lock.json
```json
{
  "telescope.nvim": {
    "branch": "master",
    "commit": "abc123def456"
  }
}
```

### Commands
```vim
:Lazy restore       " Restore to lock file
:Lazy lock          " Create/update lock file
```

### Lock File Workflow
1. Update plugins: `:Lazy update`
2. Test configuration works
3. Commit lock file: `git add lazy-lock.json`

## Performance Monitoring

### Startup Time Analysis
```bash
# Measure startup time
nvim --startuptime /tmp/nvim-startup.log +q

# View results
cat /tmp/nvim-startup.log | sort -k2 -rn | head -20
```

### Lazy.nvim Profile
```vim
:Lazy profile
```

Shows:
- Load time per plugin
- Load triggers
- Total startup time

### Identify Slow Plugins
```lua
-- Add timing to plugin config
config = function()
  local start = vim.loop.hrtime()
  require("plugin").setup({})
  local elapsed = (vim.loop.hrtime() - start) / 1e6
  if elapsed > 10 then  -- More than 10ms
    vim.notify(string.format("plugin loaded in %.2fms", elapsed))
  end
end
```

### Optimize Loading

#### Convert to Lazy Loading
```lua
-- Before: loads on startup
return { "author/plugin", lazy = false }

-- After: loads on command
return { "author/plugin", cmd = "PluginCommand" }

-- After: loads on keymap
return { "author/plugin", keys = { "<leader>p" } }

-- After: loads on filetype
return { "author/plugin", ft = "lua" }
```

#### Disable Unused Features
```lua
opts = {
  -- Disable features you don't use
  feature_x = false,
  feature_y = false,
}
```

## Health Checks

### Run All Health Checks
```vim
:checkhealth
```

### Check Specific Plugins
```vim
:checkhealth lazy
:checkhealth nvim-treesitter
:checkhealth mason
```

### Common Health Issues
| Issue | Solution |
|-------|----------|
| Missing executable | Install with system package manager |
| Outdated Neovim | Update Neovim |
| Missing providers | `:help provider` for installation |
| Deprecated settings | Update to new API |

## Configuration Cleanup

### Remove Unused Plugins
1. Comment out or delete plugin spec
2. Run `:Lazy clean`
3. Verify nothing broke

### Consolidate Configuration
```lua
-- Before: scattered keymaps
vim.keymap.set("n", "<leader>a", ...)
vim.keymap.set("n", "<leader>b", ...)
-- ... in different files

-- After: centralized keymaps
-- lua/neotex/config/keymaps.lua
local function setup_keymaps()
  vim.keymap.set("n", "<leader>a", ...)
  vim.keymap.set("n", "<leader>b", ...)
end
```

### Clean Deprecated Code
```lua
-- Check for deprecated APIs
if vim.fn.has("nvim-0.10") == 1 then
  -- Use new API
else
  -- Keep old code for compatibility
end
```

## Backup and Recovery

### Backup Strategy
```bash
# Backup entire config
cp -r ~/.config/nvim ~/.config/nvim.backup.$(date +%Y%m%d)

# Or use git
cd ~/.config/nvim
git add -A
git commit -m "Config backup before update"
```

### Recovery
```bash
# From backup
rm -rf ~/.config/nvim
cp -r ~/.config/nvim.backup.20260110 ~/.config/nvim

# From git
git reset --hard HEAD~1

# Plugin state
rm -rf ~/.local/share/nvim/lazy
nvim  # Will reinstall plugins
```

### Fresh Start
```bash
# Remove all Neovim data
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.cache/nvim

# Keep config, reinstall plugins
nvim  # lazy.nvim will reinstall everything
```

## Dependency Management

### Check Dependencies
```vim
" In lazy.nvim UI
:Lazy

" Look for plugins with ! (has dependencies)
```

### Orphaned Dependencies
After removing a plugin, check if its dependencies are still needed:
```vim
:Lazy clean    " Shows what will be removed
```

### Version Constraints
```lua
return {
  "plugin",
  version = "^1.0",    -- 1.x compatible
  version = "~1.2.3",  -- 1.2.x compatible
  version = "*",       -- Any version
  version = false,     -- Latest commit (recommended)
}
```

## Troubleshooting Common Issues

### Plugin Not Loading
1. Check `:Lazy` for errors
2. Verify event/cmd/keys triggers
3. Check if `enabled = false`
4. Look for error in `:messages`

### Keymaps Not Working
```vim
:verbose map <leader>f  " Check who set the mapping
:map                    " List all mappings
```

### LSP Issues
```vim
:LspInfo               " Check attached clients
:LspLog                " View LSP log
:Mason                 " Check server installation
```

### Treesitter Issues
```vim
:TSInstallInfo         " Check parser status
:TSUpdate              " Update parsers
:checkhealth nvim-treesitter
```

### Slow Performance
1. `:Lazy profile` for plugin load times
2. `nvim --startuptime` for startup analysis
3. Check autocommands with `:autocmd`
4. Profile specific operations

## Regular Maintenance Schedule

### Weekly
- Check for plugin updates: `:Lazy check`
- Review any deprecation warnings

### Monthly
- Full update and test: `:Lazy update`
- Run health checks: `:checkhealth`
- Review unused plugins

### Quarterly
- Audit configuration for dead code
- Update Neovim if new stable release
- Review and update documentation
