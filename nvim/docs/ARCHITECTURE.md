# NeoVim Configuration Architecture

## Purpose

This document describes the system architecture of the NeoVim configuration, including initialization flow, component organization, plugin loading sequence, and data flow patterns.

## System Overview

The configuration follows a layered architecture with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│ User Interface Layer                                        │
│ • Plugin UI components (telescope, nvim-tree, etc.)        │
│ • Notification system                                       │
│ • Status line and visual elements                          │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ Feature Layer                                               │
│ • AI integration (Avante, Claude Code, MCP Hub)            │
│ • LSP and completion                                        │
│ • Text editing (LaTeX, Markdown, Jupyter)                  │
│ • Development tools (Git, snippets, debugging)             │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ Configuration Layer                                         │
│ • Options and settings (config/options.lua)                │
│ • Keymaps (config/keymaps.lua)                            │
│ • Autocommands (config/autocmds.lua)                       │
│ • Notifications (config/notifications.lua)                 │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ Core Layer                                                  │
│ • Bootstrap system (neotex.bootstrap)                      │
│ • Plugin management (lazy.nvim)                            │
│ • Utility functions (neotex.util)                          │
└─────────────────────────────────────────────────────────────┘
```

## Initialization Flow

The configuration initializes through a carefully orchestrated sequence:

```
┌─────────────────────────────────────────────────────────────┐
│ Step 1: init.lua                                            │
│ • Disable matchit and matchparen plugins                   │
│ • Set notification level to INFO                           │
│ • Suppress known harmless errors                           │
│ • Set leader key to <Space>                                │
│ • Set MCP Hub path from environment                        │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 2: neotex.bootstrap.init()                            │
│ ├─ Cleanup temporary tree-sitter directories               │
│ ├─ Ensure lazy.nvim is installed                           │
│ ├─ Validate lazy-lock.json integrity                       │
│ ├─ Setup plugins via lazy.nvim                             │
│ ├─ Initialize utility functions                            │
│ └─ Configure Jupyter styling (deferred)                    │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 3: neotex.config.setup()                              │
│ ├─ Load options (config/options.lua)                       │
│ ├─ Initialize notifications (config/notifications.lua)     │
│ ├─ Setup keymaps (config/keymaps.lua)                      │
│ └─ Configure autocmds (config/autocmds.lua)                │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 4: Lazy Plugin Loading                                │
│ • Plugins load based on events and conditions              │
│ • VeryLazy event triggers deferred plugins                 │
│ • FileType events trigger language-specific plugins        │
│ • User events (e.g., AvantePreLoad) trigger AI plugins     │
└─────────────────────────────────────────────────────────────┘
```

### Error Handling Strategy

Each initialization step uses protected calls (`pcall`) with fallback mechanisms:

- **Bootstrap failure**: Falls back to minimal lazy.nvim setup
- **Config failure**: Falls back to basic vim.opt settings
- **Plugin failure**: Individual plugin errors don't prevent NeoVim startup

## Plugin Organization

Plugins are organized by category in `lua/neotex/plugins/`:

```
plugins/
├── ai/              # AI integration plugins
│   ├── avante.lua       # Multi-provider AI assistant
│   ├── claudecode.lua   # Claude Code integration
│   ├── claude/          # Claude internal system
│   └── mcphub.lua       # MCP Hub server
├── editor/          # Editor enhancement plugins
│   ├── autopairs.lua    # Automatic bracket pairing
│   ├── surround.lua     # Text surrounding operations
│   ├── telescope.lua    # Fuzzy finder
│   └── which-key.lua    # Keybinding help
├── lsp/             # Language server plugins
│   ├── blink.lua        # Completion engine
│   ├── lspconfig.lua    # LSP server configurations
│   └── trouble.lua      # Diagnostic display
├── text/            # Text format-specific plugins
│   ├── jupytext.lua     # Jupyter notebook support
│   ├── markdown.lua     # Markdown editing
│   ├── vimtex.lua       # LaTeX support
│   └── lean.lua         # Lean theorem prover
├── tools/           # Development tools
│   ├── gitsigns.lua     # Git integration
│   ├── himalaya/        # Email client plugin
│   ├── snippets.lua     # Code snippets
│   └── todo.lua         # TODO management
└── ui/              # UI enhancement plugins
    ├── alpha.lua        # Dashboard
    ├── gruvbox.lua      # Color scheme
    └── nvim-tree.lua    # File explorer
```

## Plugin Loading Patterns

### Immediate Loading

Plugins that load on startup:
- Color schemes (gruvbox)
- Core UI (status line, tree)
- Essential editor features (autopairs, surround)

### Lazy Loading by Event

```
Event                 → Plugins Triggered
─────────────────────────────────────────────────────────
VeryLazy             → Session manager, nvim-tree
BufReadPost          → LSP operations, surround
FileType tex         → VimTeX and LaTeX tools
FileType markdown    → Markdown rendering
FileType python      → Jupyter notebook support
User AvantePreLoad   → MCP Hub and AI tools
InsertEnter          → Completion engine
```

### Command-Based Loading

Plugins load when their commands are first executed:
- `:Telescope` → telescope.nvim
- `:Git` → fugitive
- `:Himalaya` → himalaya email plugin

## Configuration Module Structure

The `config/` directory contains core NeoVim settings:

```
config/
├── init.lua              # Module loader
├── options.lua           # vim.opt settings
├── keymaps.lua           # Global keybindings
├── autocmds.lua          # Autocommands
└── notifications.lua     # Notification system
```

### Configuration Loading Order

1. **options.lua**: Sets vim.opt values (line numbers, tabs, etc.)
2. **notifications.lua**: Initializes notification system
3. **keymaps.lua**: Registers global keybindings
4. **autocmds.lua**: Sets up autocommands for file operations

## Data Flow Patterns

### LSP Data Flow

```
┌─────────────┐
│ Source File │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────┐
│ LSP Client (lspconfig)              │
│ • Manages connection to LSP server  │
│ • Handles protocol communication    │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ Completion Engine (blink.cmp)       │
│ • Receives completion items         │
│ • Ranks and displays suggestions    │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ User Interface                      │
│ • Completion popup                  │
│ • Diagnostic virtual text           │
│ • Code action prompts               │
└─────────────────────────────────────┘
```

### AI Integration Data Flow

```
┌─────────────┐
│ User Input  │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────┐
│ Claude Code / Avante                │
│ • Captures context                  │
│ • Formats prompt                    │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ MCP Hub (if enabled)                │
│ • Tool registry                     │
│ • Function calling                  │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ AI Provider API                     │
│ • Claude / GPT / Gemini             │
│ • Processes request                 │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ Response Handler                    │
│ • Applies suggestions               │
│ • Updates buffer                    │
│ • Displays results                  │
└─────────────────────────────────────┘
```

### Notification System Flow

```
┌─────────────────────┐
│ Plugin Event        │
│ (email sent, etc.)  │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ Notification Module                 │
│ • Categorizes (ERROR/USER_ACTION)   │
│ • Checks debug mode                 │
│ • Applies filtering rules           │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ Snacks.nvim Backend                 │
│ • Renders popup                     │
│ • Applies styling                   │
│ • Manages timeout                   │
└─────────────────────────────────────┘
```

## Module Dependencies

### Core Dependencies

```
init.lua
  └── neotex.bootstrap
        ├── lazy.nvim (plugin manager)
        └── neotex.plugins (plugin specs)
              └── Individual plugin configurations

init.lua
  └── neotex.config
        ├── neotex.config.options
        ├── neotex.config.notifications
        ├── neotex.config.keymaps
        └── neotex.config.autocmds
```

### Plugin Category Dependencies

```
neotex.plugins.ai
  ├── avante → plenary, telescope, which-key
  ├── claudecode → plenary, telescope
  └── mcphub → avante (optional)

neotex.plugins.lsp
  ├── lspconfig → mason, mason-lspconfig
  └── blink → None (standalone)

neotex.plugins.text
  ├── vimtex → zathura (external)
  ├── markdown → browser (external)
  └── jupytext → jupyter (external)
```

## Performance Optimizations

### Lazy Loading Strategy

The configuration uses aggressive lazy loading to minimize startup time:

1. **Deferred initialization**: Heavy plugins load after VimEnter
2. **Event-based loading**: Plugins load when needed (FileType, InsertEnter)
3. **Command-based loading**: UI-heavy plugins load on first command use

### Optimization Techniques

- **Disabled matchit/matchparen**: Plugins disabled at startup
- **Autocommand grouping**: Related autocmds grouped to reduce overhead
- **Notification filtering**: Debug notifications hidden by default
- **Tree-sitter cleanup**: Temporary directories removed at startup

## Session and State Management

### Session Persistence

```
~/.local/share/nvim/
├── claude/                 # Claude Code sessions
│   └── [session-uuid].json
├── himalaya/              # Email drafts and state
│   └── drafts/
└── sessions/              # NeoVim sessions
    └── [session-name].vim
```

### State Components

- **Claude sessions**: UUID-based session files with metadata
- **Email drafts**: JSON files with email content and headers
- **NeoVim sessions**: Window layouts, buffer lists, working directories

## Extension Points

### Adding New Plugins

1. Create plugin spec file in appropriate `plugins/` subdirectory
2. Follow lazy.nvim spec format with event/cmd/ft triggers
3. Add configuration in plugin spec or separate config function
4. Update relevant README.md files

### Adding New Keybindings

1. Add global keybindings in `config/keymaps.lua`
2. Add plugin-specific bindings in plugin spec
3. Register with which-key for discovery
4. Document in MAPPINGS.md

### Adding New File Type Support

1. Create ftplugin file in `after/ftplugin/[filetype].lua`
2. Add filetype detection in `after/ftdetect/` if needed
3. Configure relevant plugins for the filetype
4. Add language server in LSP configuration

## Related Documentation

- [CODE_STANDARDS.md](CODE_STANDARDS.md) - Lua coding conventions
- [INSTALLATION.md](INSTALLATION.md) - Setup and installation procedures
- [MAPPINGS.md](MAPPINGS.md) - Complete keybinding reference
- [AI_TOOLING.md](AI_TOOLING.md) - AI integration details
- [Plugin README](../lua/neotex/plugins/README.md) - Plugin organization

## Notes

This architecture prioritizes:
- **Fast startup**: Aggressive lazy loading and optimization
- **Error resilience**: Fallback mechanisms at each initialization step
- **Modularity**: Clear separation between core, config, and plugins
- **Extensibility**: Well-defined extension points for adding functionality

The architecture continues to evolve as plugins are added and performance optimizations are discovered.
