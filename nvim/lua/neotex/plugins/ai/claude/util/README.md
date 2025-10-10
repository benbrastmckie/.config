# AI Utility Modules

This directory contains utility modules and support files that enhance the functionality of AI integrations in NeoVim. These modules provide essential functionality for Avante, MCPHub, and system prompt management.

## Files Overview

### Core Utility Modules

#### `avante-support.lua`
**Central Avante management and configuration module**

- **Model Selection**: Switch between Claude, OpenAI, and Gemini models
- **Provider Management**: Manage AI provider configurations with persistence
- **System Prompt Integration**: Seamless integration with system prompts
- **Generation Control**: Stop ongoing AI generation processes
- **Settings Persistence**: Save/load user preferences between sessions

**Key Functions:**
- `model_select()` - Interactive model selection for current provider
- `provider_select()` - Provider and model selection with default setting option
- `stop_generation()` - Halt active AI generation
- `init()` - Initialize Avante settings from persistent storage
- `setup_commands()` - Register all Avante-related commands

**Commands Created:**
- `:AvanteModel` - Select model for current provider
- `:AvanteProvider` - Choose provider and model with default option
- `:AvanteStop` - Stop ongoing generation
- `:AvantePrompt` - Select system prompt
- `:AvantePromptManager` - Manage system prompts

#### `system-prompts.lua`
**System prompt management system**

- **Prompt Storage**: JSON-based persistent prompt storage
- **Default Prompts**: Expert, Tutor, and Coder personalities included
- **CRUD Operations**: Create, read, update, delete prompts
- **Interactive Management**: Full UI for prompt management
- **Default Handling**: Set and manage default prompts

**Key Functions:**
- `load_prompts()` / `save_prompts()` - Persistent storage operations
- `get_prompt(id)` / `get_default()` - Prompt retrieval
- `apply_prompt(id)` - Apply prompt to Avante configuration
- `show_prompt_selection()` - Interactive prompt selection UI
- `show_prompt_manager()` - Complete prompt management interface
- `create_prompt()` / `edit_prompt()` / `delete_prompt()` - CRUD operations

**Storage Location:** `system-prompts.json`

#### `avante-highlights.lua`
**Enhanced visual highlighting for Avante UI**

- **Theme Integration**: Automatically adapts to current colorscheme
- **Diff Highlighting**: Visual indicators for additions, deletions, changes
- **Gutter Markers**: Left-side indicators for code changes
- **Smart Fallbacks**: Robust color detection with alternatives
- **Performance Optimized**: Efficient highlight management

**Key Functions:**
- `setup()` - Initialize highlight system with theme detection
- `get_theme_colors()` - Extract colors from current theme
- `apply_theme_aware_highlights()` - Update highlights for theme changes
- `update_avante_highlights()` - Refresh Avante's highlight configuration

**Highlight Groups Created:**
- `AvanteAddition` / `AvanteDeletion` / `AvanteModification` - Diff highlights
- `AvanteGutterAdd` / `AvanteGutterDelete` / `AvanteGutterChange` - Gutter markers
- `AvanteSuggestion` / `AvanteSuggestionActive` - Suggestion highlighting

### Integration Modules

#### `avante_mcp.lua`
**Avante and MCPHub integration layer**

- **Automatic Loading**: Ensures MCPHub is available when Avante starts
- **Event Integration**: Uses `AvantePreLoad` event for lazy loading
- **Graceful Fallback**: Continues without MCPHub if unavailable
- **Command Wrapping**: Creates MCP-aware versions of Avante commands

**Key Functions:**
- `with_mcp(command)` - Execute Avante command with MCPHub integration
- `register_commands()` - Create MCP-aware command variants
- `setup_autocmds()` - Auto-integration for Avante buffers
- `open_mcphub()` - Direct MCPHub interface launcher

**Commands Created:**
- `:AvanteAskWithMCP` / `:AvanteChatWithMCP` - MCP-enhanced Avante commands
- `:MCPAvante` - Quick Avante with MCPHub integration
- `:MCPHubOpen` - Open MCPHub interface with auto-start

#### `mcp_server.lua`
**MCPHub server management and state tracking**

- **Server State Management**: Track loading, running, and ready states
- **Cross-Platform Detection**: Smart executable detection for different environments
- **Connection Testing**: HTTP-based server status verification
- **Auto-Start Capabilities**: Automatic server startup when needed
- **Command Integration**: Proxy commands for seamless MCPHub access

**Key Functions:**
- `load()` - Ensure MCPHub plugin is loaded
- `start()` - Start MCPHub server with status monitoring
- `check_status()` - Test server connectivity
- `find_executable()` - Locate MCPHub binary across platforms
- `setup_commands()` - Register server management commands

**Commands Created:**
- `:MCPHubStatus` - Display server status and diagnostics
- `:MCPHubStart` - Start MCPHub server
- `:MCPHub` - Proxy command with auto-loading

### Configuration File

#### `system-prompts.json`
**Persistent storage for system prompts**

Contains user-defined and default system prompts with metadata:

```json
{
  "default": "coder",
  "prompts": {
    "expert": {
      "name": "Expert",
      "description": "Expert mathematician and programmer", 
      "prompt": "You are an expert mathematician, logician and computer scientist..."
    },
    "coder": {
      "name": "Coder",
      "description": "Focused on code and implementation",
      "prompt": "You are an expert software engineer..."
    },
    "tutor": {
      "name": "Tutor", 
      "description": "Educational assistant",
      "prompt": "You are a patient and knowledgeable tutor..."
    }
  }
}
```

## Module Dependencies

```
avante-support.lua
├── system-prompts.lua (for prompt management)
└── avante.config (Avante plugin)

avante_mcp.lua
├── mcp_server.lua (for server management)
└── mcphub (MCPHub plugin)

avante-highlights.lua
└── avante.config (for highlight integration)

mcp_server.lua
└── mcphub (MCPHub plugin)

system-prompts.lua
└── avante.config (for prompt application)
```

## Usage Examples

### Basic System Prompt Management
```lua
local prompts = require("neotex.plugins.ai.util.system-prompts")

-- Load and apply default prompt
local default_prompt, default_id = prompts.get_default()
prompts.apply_prompt(default_id)

-- Create new prompt
prompts.create_prompt({
  id = "assistant",
  name = "Assistant", 
  description = "Helpful assistant",
  prompt = "You are a helpful assistant..."
})
```

### Avante Model Management
```lua
local support = require("neotex.plugins.ai.util.avante-support")

-- Initialize with saved settings
support.init()

-- Programmatically change model
support.apply_settings("claude", "claude-3-5-sonnet-20241022", 1, true)
```

### MCPHub Integration
```lua
local mcp = require("neotex.plugins.ai.util.avante_mcp")

-- Setup integration
mcp.setup()

-- Use Avante with MCPHub
mcp.with_mcp("AvanteAsk What's the weather?")
```

### Theme-Aware Highlighting
```lua
local highlights = require("neotex.plugins.ai.util.avante-highlights")

-- Setup with current theme
highlights.setup()

-- Update for theme changes
highlights.apply_theme_aware_highlights()
```

## Architecture Notes

### State Management
- **Global State**: `_G.avante_cycle_state` tracks current provider/model
- **Persistent Storage**: Settings saved to `~/.local/share/nvim/avante/settings.lua`
- **Prompt Storage**: System prompts in `system-prompts.json`

### Event System
- **AvantePreLoad**: Triggers MCPHub loading before Avante starts
- **ColorScheme**: Updates highlights when theme changes
- **FileType**: Applies buffer-specific configurations

### Error Handling
- **Graceful Degradation**: Continues operation when optional components fail
- **Silent Fallbacks**: Minimal noise when non-critical features unavailable
- **User Feedback**: Clear notifications for important state changes

### Cross-Platform Support
- **Environment Detection**: Automatically adapts to NixOS vs standard systems
- **Path Resolution**: Smart executable detection across different environments
- **Installation Methods**: Supports global npm, bundled, and custom installations

## Integration Points

### With Main AI Plugins
- **avante.lua**: Uses support module for model management and highlights
- **mcp-hub.lua**: Integrates with server management for reliable operation
- **lectic.lua**: Shares system prompt infrastructure

### With NeoVim Core
- **Commands**: All modules register user commands for interactive use
- **Autocommands**: Event-driven integration with buffer and theme changes
- **Keymaps**: Support for buffer-specific key bindings
- **UI**: Uses `vim.ui.select` and `vim.ui.input` for consistent interface

This utility system provides a robust foundation for AI integration while maintaining modularity and cross-platform compatibility.

## Navigation

- [← AI Plugins](../README.md)
- [← Plugins Overview](../../README.md)