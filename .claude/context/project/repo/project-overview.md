# Neovim Configuration Project

## Project Overview

This is a Neovim configuration project using Lua and lazy.nvim for plugin management. The configuration provides a modern, efficient development environment with LSP support, treesitter integration, and extensive customization.

**Purpose**: Maintain a productive Neovim development environment with organized, modular configuration.

## Technology Stack

**Primary Language:** Lua
**Plugin Manager:** lazy.nvim
**LSP:** nvim-lspconfig + mason.nvim
**Treesitter:** nvim-treesitter
**Version:** Neovim 0.9+

## Project Structure

```
nvim/
├── init.lua                 # Entry point
├── lua/
│   ├── config/             # Core configuration
│   │   ├── options.lua     # vim.opt settings
│   │   ├── keymaps.lua     # Key bindings
│   │   ├── autocmds.lua    # Autocommands
│   │   └── lazy.lua        # Plugin manager setup
│   ├── plugins/            # Plugin specifications
│   │   ├── init.lua        # Main plugin list
│   │   ├── ui.lua          # UI plugins
│   │   ├── editor.lua      # Editor enhancements
│   │   ├── lsp.lua         # LSP configuration
│   │   ├── treesitter.lua  # Treesitter setup
│   │   └── git.lua         # Git integration
│   └── utils/              # Utility functions
│       └── init.lua
├── after/
│   └── ftplugin/           # Filetype-specific settings
│       ├── lua.lua
│       ├── python.lua
│       └── markdown.lua
├── plugin/                  # Auto-loaded plugins
└── lazy-lock.json          # Plugin lockfile

specs/                       # Task management
├── TODO.md                 # Task list
├── state.json              # Task state
└── {NNN}_{SLUG}/             # Task artifacts
    ├── reports/
    ├── plans/
    └── summaries/

.claude/                     # Claude Code configuration
├── CLAUDE.md               # Main reference
├── commands/               # Slash commands
├── skills/                 # Skill definitions
├── agents/                 # Agent definitions
├── rules/                  # Auto-applied rules
└── context/                # Domain knowledge
```

## Core Configuration

### Plugin Manager: lazy.nvim

The configuration uses lazy.nvim for plugin management with:
- Automatic lazy loading by event, command, or filetype
- Lockfile for reproducibility
- Built-in profiler for performance analysis

### LSP Integration

Language Server Protocol support via:
- nvim-lspconfig for server configuration
- mason.nvim for automatic server installation
- Built-in vim.lsp.* API

### Treesitter

Native tree-sitter support providing:
- Syntax highlighting
- Code folding
- Incremental selection
- Text objects

## Development Workflow

### Standard Workflow

1. **Identify Need**: Plugin to add, keymap to change, feature to implement
2. **Research**: Look up plugin docs, check existing patterns
3. **Implement**: Create/modify Lua files
4. **Test**: Restart Neovim, verify behavior
5. **Commit**: Track changes

### AI-Assisted Workflow

1. **Research**: `/research` - Gather plugin docs, patterns
2. **Planning**: `/plan` - Create implementation plan
3. **Implementation**: `/implement` - Execute the plan
4. **Review**: `/review` - Analyze configuration

## Common Tasks

### Adding a Plugin

1. Create spec file in `lua/plugins/` or add to existing
2. Define lazy loading conditions (event, cmd, ft, keys)
3. Configure plugin options
4. Add keymaps if needed

### Modifying Keymaps

1. Edit `lua/config/keymaps.lua` for global mappings
2. Use buffer-local mappings for filetype-specific
3. Always include descriptions for which-key

### Adding Filetype Settings

1. Create `after/ftplugin/{filetype}.lua`
2. Use `vim.opt_local` for buffer settings
3. Add buffer-local keymaps as needed

## Verification Commands

```bash
# Test Neovim starts without errors
nvim --headless -c "echo 'OK'" -c "q"

# Test module loading
nvim --headless -c "lua require('plugins')" -c "q"

# Check plugin health
nvim --headless -c "checkhealth" -c "q"

# Profile startup
nvim --startuptime /tmp/startup.log
```

## Related Documentation

- `.claude/context/project/neovim/` - Neovim domain knowledge
- `.claude/rules/neovim-lua.md` - Lua coding standards
- `nvim/CLAUDE.md` - Configuration-specific guidelines
