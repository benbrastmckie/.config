# AI Utilities

Utility modules supporting AI plugin functionality.

## Purpose

This directory contains supporting files for AI-powered tooling, including system prompts and configuration data used by AI assistant integrations.

## Module Documentation

### system-prompts.json

JSON configuration file defining specialized AI assistant personas for different tasks.

**Prompts Available**:
- **researcher** - Comprehensive information gathering with automatic Context7 and Tavily search
- **coder** - Expert software engineer focused on efficient code solutions
- **tutor** - Patient educational assistant with step-by-step explanations
- **expert** - Mathematician and computer scientist specializing in Neovim/Lua (default)

**Structure**:
```json
{
  "prompts": {
    "prompt_name": {
      "description": "Brief description",
      "name": "Display Name",
      "prompt": "Full system prompt text"
    }
  },
  "default": "expert"
}
```

**MCP Tools Integration**:
Each prompt includes `{MCP_TOOLS_PLACEHOLDER}` for runtime injection of available MCP tools, ensuring prompts stay current with tool availability.

**Workflow Patterns**:
- Library/framework queries → Auto-use Context7 documentation search
- Current events/news → Auto-use MCP tools for real-time search
- Cross-referencing from multiple authoritative sources

## Usage

The system-prompts.json file is loaded by AI plugin modules to configure assistant behavior based on task type. Users can switch between personas depending on whether they need code generation, research, or educational support.

## Related Documentation

- [AI Tooling](../../../../docs/AI_TOOLING.md) - AI plugin configuration and usage
- [AI Plugins](../README.md) - Parent directory for AI integrations

## Navigation

- **Parent**: [nvim/lua/neotex/plugins/ai/](../README.md)
- **Grandparent**: [nvim/lua/neotex/plugins/](../../README.md)
