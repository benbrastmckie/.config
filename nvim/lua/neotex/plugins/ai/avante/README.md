# Avante Integration

Avante-specific functionality for Neotex AI plugins, providing MCP (Model Context Protocol) integration and tool registry management.

## Purpose

This directory contains Avante AI integration separated from Claude Code. Previously misplaced under `ai/claude/util/`, Avante now has its own namespace to reflect proper architectural boundaries between distinct AI integrations.

## Modules

No modules at this level - all functionality is in subdirectories.

## Subdirectories

- [mcp/](mcp/README.md) - Model Context Protocol integration modules

## Architectural Note

[IMPORTANT] Avante and Claude Code are separate integrations. This directory handles Avante-specific concerns, while `../claude/` handles Claude Code session management. They should not be confused or intermixed.

## Navigation

- [← AI Plugins](../README.md)
- [MCP Integration →](mcp/README.md)
