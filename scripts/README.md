# Scripts Directory


## Available Scripts

### 📊 check_plugins.lua

**Purpose**: Analyzes and reports on the **entire plugin configuration**, showing all plugins organized by category across the full Neovim setup.

**Usage**:
```bash
# Run from command line
nvim --headless -c "luafile scripts/check_plugins.lua" -c "qa!"

# Or from within Neovim
:luafile scripts/check_plugins.lua
```

**What it does**:
- Counts total loaded plugins across all categories
- Categorizes **all** plugins by type:
  - **EDITOR**: Telescope, Treesitter, formatting, linting, which-key
  - **LSP**: Language servers, completion, Mason
  - **TOOLS**: Git, text manipulation, utilities, browser integration  
  - **UI**: Themes, status line, file explorer, buffers
  - **TEXT**: LaTeX, Markdown, Jupyter notebooks
- Shows plugin loading structure and organization
- Useful for comprehensive configuration auditing and plugin management

**When to use**:
- After making changes to **any** plugin configuration
- To verify plugin loading and organization across all categories
- For debugging plugin-related issues in any part of the config
- When documenting your configuration
- Before/after major updates to assess plugin changes

**Scope**: This script analyzes the **complete plugin ecosystem**, not just AI tools. It's the primary tool for understanding your entire Neovim plugin configuration.

---

## Script Categories

### 🔍 Diagnostic Scripts
- `check_plugins.lua` - **Complete plugin configuration analysis** (all categories)
## Integration with Main Configuration

These scripts are referenced and used by the main configuration:

### Commands Available in Neovim

The following commands are available after loading the AI configuration:

```vim
## Best Practices

1. **Run diagnostic scripts first** when troubleshooting issues
## When Scripts Fail

If scripts report errors:

1. **Check Prerequisites**:
   - Avante is properly configured (`lua/neotex/plugins/ai/avante.lua`)

2. **Try in Order**:
## Script Development

When adding new scripts to this directory:

1. **Follow naming convention**: `action_target.lua` (e.g., `test_mcp_tools.lua`)
2. **Add documentation** to this README
3. **Include usage examples** and expected output
4. **Reference from main configuration** when appropriate
5. **Use consistent error handling** and user feedback