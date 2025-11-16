# Avante MCP Integration

Model Context Protocol (MCP) integration modules for Avante AI functionality.

## Purpose

This directory contains MCP server management, tool registry, and Avante-specific utilities that were previously located under `ai/claude/util/`. These modules handle Avante's integration with the Model Context Protocol, providing tool selection, system prompts, and server lifecycle management.

## Modules

### avante-support.lua
Central Avante management and configuration module.

**Key Features:**
- Model selection (Claude, OpenAI, Gemini)
- Provider management with persistence
- System prompt integration
- Generation control
- Settings persistence

**Commands:** `:AvanteModel`, `:AvanteProvider`, `:AvanteStop`, `:AvantePrompt`, `:AvantePromptManager`

### system-prompts.lua
System prompt management system with JSON-based storage.

**Key Features:**
- Prompt storage with default prompts (Expert, Tutor, Coder)
- CRUD operations for prompts
- Interactive management UI
- Default prompt handling

**Storage Location:** `system-prompts.json`

### avante-highlights.lua
Enhanced visual highlighting for Avante UI.

**Key Features:**
- Theme integration (adapts to colorscheme)
- Diff highlighting (additions, deletions, changes)
- Gutter markers for code changes
- Smart fallbacks with robust color detection

**Highlight Groups:** `AvanteAddition`, `AvanteDeletion`, `AvanteModification`, `AvanteGutter*`, `AvanteSuggestion*`

### avante_mcp.lua
Avante and MCPHub integration coordinator.

**Key Features:**
- Automatic MCPHub loading
- Event integration (AvantePreLoad)
- Graceful fallback
- MCP-aware command wrapping

**Commands:** `:AvanteAskWithMCP`, `:AvanteChatWithMCP`, `:MCPAvante`, `:MCPHubOpen`

### mcp_server.lua
MCPHub server lifecycle management.

**Key Features:**
- Server state tracking (loading, running, ready)
- Cross-platform executable detection
- HTTP-based connection testing
- Auto-start capabilities

**Commands:** `:MCPHubStatus`, `:MCPHubStart`, `:MCPHub`

### tool_registry.lua
MCP tool registry with context-aware tool selection.

**Key Features:**
- Tool discovery and registration
- Context-aware tool filtering
- Tool availability tracking
- Integration with MCP server

## Configuration Files

### system-prompts.json
Persistent storage for system prompts with user-defined and default prompts.

```json
{
  "default": "coder",
  "prompts": {
    "expert": { "name": "Expert", "description": "...", "prompt": "..." },
    "coder": { "name": "Coder", "description": "...", "prompt": "..." },
    "tutor": { "name": "Tutor", "description": "...", "prompt": "..." }
  }
}
```

## Usage Examples

### Basic System Prompt Management
```lua
local prompts = require("neotex.plugins.ai.avante.mcp.system-prompts")

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
local support = require("neotex.plugins.ai.avante.mcp.avante-support")

-- Initialize with saved settings
support.init()

-- Programmatically change model
support.apply_settings("claude", "claude-3-5-sonnet-20241022", 1, true)
```

### MCPHub Integration
```lua
local mcp = require("neotex.plugins.ai.avante.mcp.avante_mcp")

-- Setup integration
mcp.setup()

-- Use Avante with MCPHub
mcp.with_mcp("AvanteAsk What's the weather?")
```

## Architecture Notes

### State Management
- Global state: `_G.avante_cycle_state` tracks current provider/model
- Persistent storage: Settings saved to `~/.local/share/nvim/avante/settings.lua`
- Prompt storage: System prompts in `system-prompts.json`

### Event System
- AvantePreLoad: Triggers MCPHub loading before Avante starts
- ColorScheme: Updates highlights when theme changes
- FileType: Applies buffer-specific configurations

### Cross-Platform Support
- Environment detection (NixOS vs standard systems)
- Smart executable detection
- Supports global npm, bundled, and custom installations

## Architectural Separation

[IMPORTANT] This directory contains Avante-specific functionality. It was moved from `ai/claude/util/` to establish proper architectural boundaries. Avante and Claude Code are separate integrations:

- **ai/avante/mcp/** - Avante-MCP integration (this directory)
- **ai/claude/claude-session/** - Claude Code session management

These should not be confused or intermixed.

## Navigation

- [← Avante Integration](../README.md)
- [← AI Plugins](../../README.md)
