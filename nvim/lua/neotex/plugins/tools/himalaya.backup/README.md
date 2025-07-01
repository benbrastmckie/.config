# Himalaya Email Plugin

A comprehensive email client integration for Neovim using the Himalaya CLI tool.

## Purpose

This plugin provides a full-featured email interface within Neovim, supporting:
- Email reading, composing, and sending
- Gmail integration via OAuth2
- Synchronization with mbsync
- Smart notifications and UI

## Directory Structure

### Core Modules
- **init.lua** - Main entry point, command definitions, and setup
- **utils.lua** - CLI integration and email operation utilities

### Subdirectories

- [core/](core/README.md) - Core functionality (config, logging, state)
- [sync/](sync/README.md) - Email synchronization system
- [ui/](ui/README.md) - User interface components
- [setup/](setup/README.md) - Setup wizard and health checks
- [scripts/](scripts/README.md) - OAuth and utility scripts
- **docs/** - Additional documentation (SYNC_STAT.md, DEPENDENCIES.md)
- [spec/](spec/README.md) - Specification documents

## Usage

The plugin is configured through lazy.nvim and provides numerous commands:
- `:Himalaya` - Open email sidebar
- `:HimalayaCompose` - Compose new email
- `:HimalayaSync` - Synchronize emails

See individual module documentation for detailed usage.

## Requirements

- Himalaya CLI tool
- mbsync (for full synchronization)
- Gmail OAuth2 credentials (for Gmail accounts)

## Navigation
- [← Neovim Tools](../README.md)