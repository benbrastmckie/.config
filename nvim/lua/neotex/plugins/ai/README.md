# AI Plugins

This directory contains all AI-related plugin configurations and integrations for the Neovim setup.

## Purpose

The AI plugins directory organizes artificial intelligence tools and assistants, providing a centralized location for AI-powered development assistance, code generation, and intelligent editing capabilities.

## Modules

### init.lua
Main entry point that loads and returns all AI plugin specifications. Includes error handling for safe module loading and validates plugin specs before returning them to lazy.nvim.

### avante.lua
Configuration for the Avante AI assistant plugin (`yetone/avante.nvim`). Provides multiple AI provider support (Claude, GPT, Gemini), MCP-Hub integration, system prompt management, and UI enhancements with inline suggestions.

### claudecode.lua
External plugin configuration wrapper for `greggh/claude-code.nvim`. Manages window settings, file refresh detection, git integration, shell configuration, and terminal behavior. Bridges the external plugin with the internal Claude system.

### mcp-hub.lua
MCP-Hub integration plugin configuration (`mcp-hub`) with cross-platform compatibility. Provides automatic installation method detection, clean Avante integration with lazy loading, and fallback to bundled installation when needed.

### lectic.lua
Configuration for the Lectic plugin (`gleachkr/lectic`) for markdown editing and management. Handles markdown and lectic.markdown filetypes with dependency installation and runtime path configuration.

## Subdirectories

- [claude/](claude/README.md) - Comprehensive internal Claude AI integration system (9,626+ lines across 20 files)

## Key Features

### AI Assistant Integration
- **Multiple AI providers** - Claude, GPT, Gemini support through Avante
- **Visual selection prompting** - Send selected code to Claude with custom prompts (`<leader>ac` in visual mode)
- **Smart session management** - Context-aware Claude sessions with persistence
- **MCP protocol support** - Tool communication and custom prompt systems

### Development Workflow
- **Git worktree integration** - Isolated development environments with AI context
- **Terminal detection** - Multi-terminal support (Kitty, WezTerm, Alacritty)
- **File change detection** - Automatic refresh and context updates
- **Session persistence** - Save and restore AI conversation state

### User Interface
- **Which-key integration** - Organized keybindings under `<leader>a` namespace
- **Telescope pickers** - Session browsing and command selection
- **Progress notifications** - User feedback during AI operations
- **Error handling** - Comprehensive validation and user-friendly messages

## Usage Examples

### Visual Selection with Claude
```vim
" Select code in visual mode
v}
" Send to Claude with custom prompt
<leader>ac
" Enter prompt: "Please explain this function"
```

### AI Assistant Commands
```vim
:AvanteAsk           " Ask Avante AI assistant
:ClaudeCommands      " Browse Claude command hierarchy
:ClaudeSessions      " Open Claude session browser
:MCPHub              " Launch MCP-Hub interface
```

### Session Management
```lua
local ai = require("neotex.plugins.ai.claude")
ai.smart_toggle()                    -- Smart Claude toggle
ai.create_worktree_with_claude(opts) -- Create isolated dev environment
ai.send_visual_to_claude_with_prompt() -- Visual selection with prompt
```

## Configuration

### Keybindings (in which-key.lua)
- `<leader>a` - AI tools group
- `<leader>ac` - Send selection to Claude (visual) / Claude commands (normal)
- `<leader>aa` - Avante ask
- `<leader>ae` - Avante edit (visual mode)
- `<leader>as` - Claude sessions
- `<leader>av` - View worktrees
- `<leader>aw` - Create worktree
- `<leader>ar` - Restore worktree

### Plugin Dependencies
- `nvim-lua/plenary.nvim` - Lua utilities
- `nvim-telescope/telescope.nvim` - UI pickers
- `folke/which-key.nvim` - Keybinding management
- External AI services (Claude API, OpenAI, etc.)

## Architecture

### Separation of Concerns
```
External Plugin Configs (ai/*.lua) ──→ Internal Systems (ai/claude/)
         │                                    │
         ├─ Plugin management                 ├─ Business logic
         ├─ Configuration bridging            ├─ Session management
         └─ Initialization orchestration      └─ Feature implementation
```

### Integration Flow
1. **Plugin Loading** - lazy.nvim loads plugin specifications from ai/*.lua
2. **Configuration** - External plugins configured with options and keymaps
3. **Internal System** - Advanced features implemented in ai/claude/ directory
4. **User Interface** - Which-key provides organized command access

## Troubleshooting

### Plugin Loading Issues
- Check `:lazy` for plugin status and errors
- Verify dependencies are installed: `:checkhealth`
- Test individual plugins: `:lua require('neotex.plugins.ai.avante')`

### AI Service Connectivity
- Verify API keys and authentication
- Check network connectivity for external services
- Test with `:ClaudeCommands` or `:AvanteAsk`

### Keybinding Conflicts
- Verify which-key configuration: `:lua print(require('which-key'))`
- Check for duplicate mappings in visual vs normal mode
- Test mappings with `:map <leader>a`

## Navigation
- [← Parent Directory](../README.md) - Plugins overview
- [Claude System](claude/README.md) - Comprehensive Claude AI integration
- [Plugin Configurations](../../../README.md) - Main configuration documentation